#!/usr/bin/env python3
"""Delete Markdown files after moving referenced local images to Trash.

This is meant for note workflows (Typora/Obsidian/etc.) where a Markdown file
references local image files. It finds referenced image paths and moves those
image files to the OS Trash before removing the Markdown file.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlparse


_MD_IMAGE_RE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")
_OBSIDIAN_IMAGE_RE = re.compile(r"!\[\[([^\]]+)\]\]")
_HTML_IMG_RE = re.compile(
    r"(?is)<img[^>]*\bsrc\s*=\s*(?:\"([^\"]+)\"|'([^']+)'|([^\s>]+))"
)


@dataclass(frozen=True)
class Options:
    yes: bool
    dry_run: bool
    trash_md: bool
    delete_md_permanently: bool
    recursive: bool
    md_suffixes: tuple[str, ...]
    rmdir_empty: bool
    verbose: bool


def _is_remote_src(src: str) -> bool:
    lowered = src.lower()
    return lowered.startswith(("http://", "https://", "data:", "mailto:"))


def _strip_title_from_md_link_target(target: str) -> str:
    """Extract link destination from a Markdown image target.

    Handles:
      - <path with spaces>
      - "path with spaces" "optional title"
      - path "optional title"
    """
    target = target.strip()

    if target.startswith("<") and ">" in target:
        return target[1 : target.index(">")].strip()

    if not target:
        return target

    # Many Markdown renderers allow spaces in the destination even without <...>.
    # So we *don't* split on whitespace blindly. Instead, if there's an explicit
    # title ("..." / '...' / (...)) at the end, strip only that title.
    stripped = target.strip()
    if not stripped:
        return stripped

    # Destination may be quoted.
    quote = stripped[0]
    if quote in ('"', "'"):
        end = stripped.find(quote, 1)
        if end != -1:
            return stripped[1:end].strip()
        return stripped.strip(quote).strip()

    # Strip trailing quoted title:  path "title" / path 'title'
    for quote in ('"', "'"):
        if stripped.endswith(quote):
            start = stripped.rfind(quote, 0, len(stripped) - 1)
            if start != -1 and start > 0 and stripped[start - 1].isspace():
                return stripped[: start - 1].rstrip()

    # Strip trailing paren title: path (title)
    if stripped.endswith(")"):
        open_idx = stripped.rfind("(")
        if open_idx != -1 and open_idx > 0 and stripped[open_idx - 1].isspace():
            return stripped[: open_idx - 1].rstrip()

    return stripped


def _normalize_src(src: str) -> str:
    src = src.strip()
    # Drop querystring / fragment so local paths like "img.png?raw=1" work.
    src = src.split("#", 1)[0].split("?", 1)[0].strip()
    return unquote(src)


def extract_image_srcs(markdown_text: str) -> list[str]:
    srcs: list[str] = []

    for m in _MD_IMAGE_RE.finditer(markdown_text):
        target = _strip_title_from_md_link_target(m.group(1))
        if target:
            srcs.append(target)

    for m in _OBSIDIAN_IMAGE_RE.finditer(markdown_text):
        target = m.group(1).strip()
        if "|" in target:
            target = target.split("|", 1)[0].strip()
        if target:
            srcs.append(target)

    for m in _HTML_IMG_RE.finditer(markdown_text):
        target = m.group(1) or m.group(2) or m.group(3) or ""
        target = target.strip()
        if target:
            srcs.append(target)

    # Normalize, keep order, de-dup.
    seen: set[str] = set()
    out: list[str] = []
    for src in srcs:
        src = _normalize_src(src)
        if not src:
            continue
        if src in seen:
            continue
        seen.add(src)
        out.append(src)
    return out


def _trash_dir() -> Path | None:
    if sys.platform == "darwin":
        return Path.home() / ".Trash"
    if sys.platform.startswith("linux"):
        return Path.home() / ".local/share/Trash/files"
    return None


def _move_to_trash_fallback(path: Path) -> None:
    trash_dir = _trash_dir()
    if trash_dir is None:
        raise RuntimeError(
            "No Trash implementation for this OS without 'send2trash'."
        )
    trash_dir.mkdir(parents=True, exist_ok=True)

    candidate = trash_dir / path.name
    if not candidate.exists():
        shutil.move(str(path), str(candidate))
        return

    stem, suffix = path.stem, path.suffix
    for i in range(1, 10_000):
        candidate = trash_dir / f"{stem}-{i}{suffix}"
        if not candidate.exists():
            shutil.move(str(path), str(candidate))
            return

    raise RuntimeError(f"Failed to generate unique trash filename for: {path}")


def move_to_trash(path: Path) -> None:
    """Move a path to OS trash."""
    try:
        from send2trash import send2trash  # type: ignore

        send2trash(str(path))
        return
    except ModuleNotFoundError:
        _move_to_trash_fallback(path)


def src_to_local_path(md_file: Path, src: str) -> Path | None:
    if _is_remote_src(src):
        return None

    if src.lower().startswith("file://"):
        parsed = urlparse(src)
        candidate = unquote(parsed.path)
        if candidate:
            return Path(candidate)
        return None

    # Drop any surrounding angle brackets that might slip through.
    if src.startswith("<") and src.endswith(">"):
        src = src[1:-1].strip()

    candidate = Path(src)
    if not candidate.is_absolute():
        candidate = (md_file.parent / candidate).resolve()
        if candidate.exists():
            return candidate

        # Heuristics for common note apps:
        # - Typora: note.md + note.assets/<file>
        # - Obsidian: attachments/<file>
        # Only apply when src is a bare filename.
        if ("/" not in src) and ("\\" not in src):
            for folder in (
                md_file.parent / f"{md_file.stem}.assets",
                md_file.parent / "assets",
                md_file.parent / "attachments",
            ):
                alt = (folder / src).resolve()
                if alt.exists():
                    return alt
        return candidate

    return candidate


def iter_markdown_files(inputs: list[Path], *, recursive: bool, suffixes: tuple[str, ...]) -> list[Path]:
    out: list[Path] = []
    for p in inputs:
        if p.is_dir():
            pattern = "**/*" if recursive else "*"
            for child in p.glob(pattern):
                if child.is_file() and child.suffix.lower() in suffixes:
                    out.append(child)
            continue
        if p.is_file() and p.suffix.lower() in suffixes:
            out.append(p)
            continue
        raise FileNotFoundError(f"Not a markdown file or directory: {p}")
    # Stable ordering.
    return sorted({f.resolve() for f in out})


def rmdir_empty_parents(start: Path, stop_at: Path) -> None:
    """Remove empty directories from start upward until stop_at (inclusive).

    Safety:
      - Never removes stop_at itself
      - Never removes beyond stop_at
    """
    start = start.resolve()
    stop_at = stop_at.resolve()
    cur = start
    while True:
        if cur == stop_at:
            return
        try:
            cur.rmdir()
        except OSError:
            return
        cur = cur.parent


def confirm(prompt: str, *, yes: bool) -> None:
    if yes:
        return
    reply = input(f"{prompt} [y/N] ").strip().lower()
    if reply not in {"y", "yes"}:
        raise SystemExit("Aborted.")


def process_markdown_file(md_file: Path, options: Options) -> int:
    md_file = md_file.resolve()
    text = md_file.read_text(encoding="utf-8", errors="replace")
    srcs = extract_image_srcs(text)
    local_paths: list[Path] = []
    for src in srcs:
        p = src_to_local_path(md_file, src)
        if p is None:
            continue
        local_paths.append(p)

        if options.verbose:
            exists = "exists" if p.exists() else "missing"
            print(f"Resolved image src: {src} -> {p} ({exists})")

    existing_images = [p for p in local_paths if p.exists()]
    missing_images = [p for p in local_paths if not p.exists()]

    print(f"\n# {md_file}")
    print(f"Images referenced: {len(srcs)} (local: {len(local_paths)}, existing: {len(existing_images)})")
    if missing_images:
        print(f"Missing local images (skipped): {len(missing_images)}")

    if existing_images:
        confirm("Move referenced existing images to Trash?", yes=options.yes)
        for img in existing_images:
            if options.dry_run:
                print(f"DRY-RUN trash image: {img}")
            else:
                move_to_trash(img)
                print(f"Trashed image: {img}")

            if options.rmdir_empty:
                # If we just removed the last file in an assets folder, clean it up.
                rmdir_empty_parents(img.parent, stop_at=md_file.parent)

    # Delete/trash markdown file itself.
    if options.delete_md_permanently:
        confirm("Permanently delete the markdown file?", yes=options.yes)
        if options.dry_run:
            print(f"DRY-RUN delete markdown: {md_file}")
        else:
            md_file.unlink()
            print(f"Deleted markdown: {md_file}")
        return 0

    if options.trash_md:
        confirm("Move the markdown file to Trash?", yes=options.yes)
        if options.dry_run:
            print(f"DRY-RUN trash markdown: {md_file}")
        else:
            move_to_trash(md_file)
            print(f"Trashed markdown: {md_file}")
        return 0

    # Default: if neither permanent delete nor trash_md, do nothing.
    print("Markdown left untouched (no --trash-md and no --delete-md-permanently).")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Delete markdown files after trashing referenced local images."
    )
    p.add_argument(
        "paths",
        nargs="+",
        help="Markdown files and/or directories containing markdown files.",
    )
    p.add_argument(
        "--yes",
        action="store_true",
        help="Do not prompt for confirmation.",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Print actions without modifying anything.",
    )
    p.add_argument(
        "--recursive",
        action="store_true",
        default=False,
        help="When given a directory, scan recursively for markdown files.",
    )
    p.add_argument(
        "--md-suffix",
        action="append",
        default=[".md"],
        help="Markdown suffix to include (repeatable). Default: .md",
    )
    p.add_argument(
        "--trash-md",
        action="store_true",
        default=True,
        help="Move markdown file to Trash (default).",
    )
    p.add_argument(
        "--keep-md",
        action="store_true",
        help="Do not trash/delete the markdown file.",
    )
    p.add_argument(
        "--delete-md-permanently",
        action="store_true",
        help="Permanently delete markdown file (instead of trash).",
    )
    p.add_argument(
        "--rmdir-empty",
        action="store_true",
        help="Remove empty image directories after trashing images.",
    )
    p.add_argument(
        "--verbose",
        action="store_true",
        help="Print resolved image paths for debugging.",
    )
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    md_suffixes = tuple(s if s.startswith(".") else f".{s}" for s in args.md_suffix)
    inputs = [Path(p) for p in args.paths]

    trash_md = bool(args.trash_md) and not bool(args.keep_md)
    options = Options(
        yes=bool(args.yes),
        dry_run=bool(args.dry_run),
        trash_md=trash_md,
        delete_md_permanently=bool(args.delete_md_permanently),
        recursive=bool(args.recursive),
        md_suffixes=md_suffixes,
        rmdir_empty=bool(args.rmdir_empty),
        verbose=bool(args.verbose),
    )

    # If user asks for permanent delete, that overrides trashing.
    if options.delete_md_permanently and options.trash_md:
        options = Options(
            **{**options.__dict__, "trash_md": False}  # type: ignore[attr-defined]
        )

    files = iter_markdown_files(inputs, recursive=options.recursive, suffixes=options.md_suffixes)
    if not files:
        print("No markdown files found.")
        return 0

    confirm(
        f"About to process {len(files)} markdown file(s). Continue?",
        yes=options.yes,
    )

    failures = 0
    for f in files:
        try:
            process_markdown_file(f, options)
        except Exception as e:  # noqa: BLE001
            failures += 1
            print(f"ERROR processing {f}: {e}", file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
