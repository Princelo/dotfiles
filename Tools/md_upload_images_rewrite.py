#!/usr/bin/env python3

"""Upload local images referenced by a Markdown file and rewrite links.

This script:
  1) Finds image references in a Markdown file.
  2) For each *local* image that exists on disk, calls `typora_image_uploader.py`.
  3) Rewrites the Markdown to use the uploader's returned target (typically a
     `file://...` URI).

Supported image syntaxes:
  - Markdown images: ![alt](path)
  - HTML images: <img src="path">
  - Obsidian embeds: ![[path|optional]]
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
from urllib.parse import unquote, urlparse


_MD_IMAGE_RE = re.compile(r"(!\[[^\]]*\]\()([^)]+)(\))")
_OBSIDIAN_IMAGE_RE = re.compile(r"!\[\[([^\]]+)\]\]")
_HTML_IMG_SRC_RE = re.compile(
    r"(?is)(<img[^>]*\bsrc\s*=\s*)(\"([^\"]+)\"|'([^']+)'|([^\s>]+))"
)


@dataclass(frozen=True)
class Options:
    yes: bool
    dry_run: bool
    verbose: bool
    recursive: bool
    md_suffixes: tuple[str, ...]
    backup_suffix: str
    uploader: Path
    keep_md: bool


def _is_remote_src(src: str) -> bool:
    lowered = src.lower()
    return lowered.startswith(("http://", "https://", "data:", "mailto:"))


def _normalize_src(src: str) -> str:
    src = src.strip()
    src = src.split("#", 1)[0].split("?", 1)[0].strip()
    return unquote(src)


def _strip_title_from_md_link_target(target: str) -> str:
    """Return the image destination portion from a Markdown image target."""
    target = target.strip()

    if target.startswith("<") and ">" in target:
        return target[1 : target.index(">")].strip()

    if not target:
        return target

    stripped = target.strip()

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


def _md_title_suffix(original_inner: str, destination: str) -> str:
    """Preserve any title part that follows the destination."""
    s = original_inner.strip()
    if not s:
        return ""

    # If destination is inside angle brackets, title is after the closing '>'
    if original_inner.strip().startswith("<"):
        idx = original_inner.find(">")
        if idx != -1:
            return original_inner[idx + 1 :]
        return ""

    # Quoted destination: keep everything after the closing quote.
    if original_inner.strip().startswith(('"', "'")):
        q = original_inner.strip()[0]
        # Find first matching quote in the original string (not stripped) after it begins.
        start = original_inner.find(q)
        end = original_inner.find(q, start + 1)
        if start != -1 and end != -1:
            return original_inner[end + 1 :]
        return ""

    # Unquoted destination: title (if any) starts after the destination substring.
    pos = original_inner.find(destination)
    if pos == -1:
        return ""
    return original_inner[pos + len(destination) :]


def src_to_local_path(md_file: Path, src: str) -> Path | None:
    src = _normalize_src(src)
    if not src:
        return None
    if _is_remote_src(src):
        return None

    if src.lower().startswith("file://"):
        parsed = urlparse(src)
        candidate = unquote(parsed.path)
        if candidate:
            return Path(candidate)
        return None

    if src.startswith("<") and src.endswith(">"):
        src = src[1:-1].strip()

    candidate = Path(src)
    if not candidate.is_absolute():
        candidate = (md_file.parent / candidate).resolve()
        if candidate.exists():
            return candidate

        # Common note-app heuristics.
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


def confirm(prompt: str, *, yes: bool) -> None:
    if yes:
        return
    reply = input(f"{prompt} [y/N] ").strip().lower()
    if reply not in {"y", "yes"}:
        raise SystemExit("Aborted.")


def iter_markdown_files(
    inputs: list[Path], *, recursive: bool, suffixes: tuple[str, ...]
) -> list[Path]:
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
    return sorted({f.resolve() for f in out})


def collect_local_images(md_file: Path, markdown_text: str, *, verbose: bool) -> list[Path]:
    candidates: list[Path] = []

    for m in _MD_IMAGE_RE.finditer(markdown_text):
        inner = m.group(2)
        dest = _strip_title_from_md_link_target(inner)
        p = src_to_local_path(md_file, dest)
        if p is None:
            continue
        candidates.append(p)
        if verbose:
            exists = "exists" if p.exists() else "missing"
            print(f"MD image: {dest} -> {p} ({exists})")

    for m in _HTML_IMG_SRC_RE.finditer(markdown_text):
        src = m.group(3) or m.group(4) or m.group(5) or ""
        p = src_to_local_path(md_file, src)
        if p is None:
            continue
        candidates.append(p)
        if verbose:
            exists = "exists" if p.exists() else "missing"
            print(f"HTML img: {src} -> {p} ({exists})")

    for m in _OBSIDIAN_IMAGE_RE.finditer(markdown_text):
        inner = m.group(1).strip()
        left = inner.split("|", 1)[0].strip()
        p = src_to_local_path(md_file, left)
        if p is None:
            continue
        candidates.append(p)
        if verbose:
            exists = "exists" if p.exists() else "missing"
            print(f"Obsidian img: {left} -> {p} ({exists})")

    unique_existing: list[Path] = []
    seen: set[Path] = set()
    for p in candidates:
        rp = p.resolve()
        if rp in seen:
            continue
        seen.add(rp)
        if rp.exists() and rp.is_file():
            unique_existing.append(rp)
    return unique_existing


def upload_images(images: list[Path], options: Options) -> dict[Path, str]:
    if not images:
        return {}

    if options.verbose:
        print(f"Will upload {len(images)} image(s) using {options.uploader}")

    if options.dry_run:
        return {p: p.as_uri() for p in images}

    cmd = [sys.executable, str(options.uploader), *[str(p) for p in images]]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(
            "Uploader failed.\n"
            f"Command: {cmd}\n"
            f"Exit: {proc.returncode}\n"
            f"STDERR: {proc.stderr.strip()}"
        )

    outputs = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
    if len(outputs) != len(images):
        raise RuntimeError(
            "Uploader output count mismatch. "
            f"inputs={len(images)} outputs={len(outputs)}\n"
            f"STDOUT: {proc.stdout.strip()}\n"
            f"STDERR: {proc.stderr.strip()}"
        )

    mapping: dict[Path, str] = {}
    for src, out in zip(images, outputs, strict=True):
        mapping[src.resolve()] = out
    return mapping


def rewrite_markdown(md_file: Path, markdown_text: str, mapping: dict[Path, str], *, verbose: bool) -> str:
    def replace_md(m: re.Match[str]) -> str:
        prefix, inner, suffix = m.group(1), m.group(2), m.group(3)
        dest = _strip_title_from_md_link_target(inner)
        p = src_to_local_path(md_file, dest)
        if p is None:
            return m.group(0)
        new = mapping.get(p.resolve())
        if not new:
            return m.group(0)

        title_suffix = _md_title_suffix(inner, dest)
        new_inner = f"{new}{title_suffix}"
        if verbose and new_inner != inner:
            print(f"Rewrite MD: {dest} -> {new}")
        return f"{prefix}{new_inner}{suffix}"

    def replace_html(m: re.Match[str]) -> str:
        prefix = m.group(1)
        token = m.group(2)
        src = m.group(3) or m.group(4) or m.group(5) or ""
        p = src_to_local_path(md_file, src)
        if p is None:
            return m.group(0)
        new = mapping.get(p.resolve())
        if not new:
            return m.group(0)

        if token.startswith('"'):
            repl = f'"{new}"'
        elif token.startswith("'"):
            repl = f"'{new}'"
        else:
            repl = new

        if verbose and src != new:
            print(f"Rewrite HTML: {src} -> {new}")
        return f"{prefix}{repl}"

    def replace_obsidian(m: re.Match[str]) -> str:
        inner = m.group(1).strip()
        left, rest = (inner.split("|", 1) + [""])[:2]
        left = left.strip()
        rest = rest.strip()
        p = src_to_local_path(md_file, left)
        if p is None:
            return m.group(0)
        new = mapping.get(p.resolve())
        if not new:
            return m.group(0)

        new_inner = new if not rest else f"{new}|{rest}"
        if verbose and left != new:
            print(f"Rewrite Obsidian: {left} -> {new}")
        return f"![[{new_inner}]]"

    out = _MD_IMAGE_RE.sub(replace_md, markdown_text)
    out = _HTML_IMG_SRC_RE.sub(replace_html, out)
    out = _OBSIDIAN_IMAGE_RE.sub(replace_obsidian, out)
    return out


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Upload local images in Markdown via typora_image_uploader.py and rewrite links."
    )
    p.add_argument("paths", nargs="+", help="Markdown file(s) and/or directories")
    p.add_argument("--yes", action="store_true", help="Do not prompt")
    p.add_argument("--dry-run", action="store_true", help="No file changes")
    p.add_argument("--verbose", action="store_true", help="Debug logging")
    p.add_argument("--recursive", action="store_true", help="Scan directories recursively")
    p.add_argument(
        "--md-suffix",
        action="append",
        default=[".md"],
        help="Markdown suffix to include (repeatable). Default: .md",
    )
    p.add_argument(
        "--backup-suffix",
        default=".bak",
        help="Backup suffix for rewritten markdown. Default: .bak",
    )
    p.add_argument(
        "--uploader",
        default=str(Path(__file__).with_name("typora_image_uploader.py")),
        help="Path to typora_image_uploader.py (default: alongside this script)",
    )
    p.add_argument(
        "--keep-md",
        action="store_true",
        help="Only rewrite markdown links; do not move/delete the markdown file.",
    )
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    md_suffixes = tuple(s if s.startswith(".") else f".{s}" for s in args.md_suffix)

    options = Options(
        yes=bool(args.yes),
        dry_run=bool(args.dry_run),
        verbose=bool(args.verbose),
        recursive=bool(args.recursive),
        md_suffixes=md_suffixes,
        backup_suffix=str(args.backup_suffix),
        uploader=Path(args.uploader).resolve(),
        keep_md=bool(args.keep_md),
    )

    if not options.uploader.exists():
        raise SystemExit(f"Uploader not found: {options.uploader}")

    files = iter_markdown_files(
        [Path(p) for p in args.paths],
        recursive=options.recursive,
        suffixes=options.md_suffixes,
    )
    if not files:
        print("No markdown files found.")
        return 0

    confirm(f"About to process {len(files)} markdown file(s). Continue?", yes=options.yes)

    failures = 0
    for md_file in files:
        try:
            md_file = md_file.resolve()
            text = md_file.read_text(encoding="utf-8", errors="replace")

            images = collect_local_images(md_file, text, verbose=options.verbose)
            print(f"\n# {md_file}")
            print(f"Local images found: {len(images)}")
            if not images:
                continue

            confirm("Upload these images and rewrite links?", yes=options.yes)
            mapping = upload_images(images, options)

            new_text = rewrite_markdown(md_file, text, mapping, verbose=options.verbose)
            if new_text == text:
                print("No markdown changes needed.")
                continue

            if options.dry_run:
                print("DRY-RUN would rewrite markdown file.")
                continue

            backup = md_file.with_name(md_file.name + options.backup_suffix)
            if not backup.exists():
                backup.write_text(text, encoding="utf-8")
            md_file.write_text(new_text, encoding="utf-8")
            print(f"Rewrote markdown. Backup: {backup}")
        except Exception as e:  # noqa: BLE001
            failures += 1
            print(f"ERROR processing {md_file}: {e}", file=sys.stderr)

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

