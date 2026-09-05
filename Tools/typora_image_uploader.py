#!/usr/bin/env python3

"""Typora Custom Command image organizer (fixed destination).

Goal:
- Copy images from Typora's temp folder (often read-only/managed) into a stable
  user-owned directory.
- Then *try* to delete the original.
- If deletion fails, append the original path to a log for later cleanup.

Typora will call this script with one or more image paths as arguments.
This script prints the replacement `file://...` URL(s), one per line.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import sys
import urllib.parse
from datetime import datetime
from pathlib import Path
from shutil import copy2


_CANDIDATE_DEST_ROOTS = [
    Path.home() / "Pictures" / "Typora" / "typora-assets",
    Path.home() / "Documents" / "Typora" / "typora-assets",
    Path("/private/tmp") / "typora-assets",
    Path("/tmp") / "typora-assets",
]


def _as_path(raw: str) -> Path:
    raw = raw.strip()
    if raw.startswith("file://"):
        parsed = urllib.parse.urlparse(raw)
        p = urllib.parse.unquote(parsed.path)
        # Windows file URLs can look like file:///C:/Users/...
        if len(p) >= 3 and p[0] == "/" and p[2] == ":":
            p = p[1:]
        return Path(p)
    return Path(raw)


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _append_delete_failure(log_path: Path, path: Path) -> None:
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as f:
            f.write(f"{path}\n")
    except Exception:
        # Never break Typora because logging failed.
        pass


def _is_under(child: Path, parent: Path) -> bool:
    try:
        child.resolve().relative_to(parent.resolve())
        return True
    except Exception:
        return False


def _read_inputs(argv: list[str]) -> list[str]:
    # Some environments might send via stdin; support it.
    args = [a for a in (x.strip() for x in argv) if a]
    if args:
        return args
    stdin = sys.stdin.read().strip()
    if not stdin:
        return []
    return [line.strip() for line in stdin.splitlines() if line.strip()]


def _pick_dest_root() -> Path:
    for candidate in _CANDIDATE_DEST_ROOTS:
        try:
            candidate.mkdir(parents=True, exist_ok=True)
            probe = candidate / ".typora_uploader_write_test"
            probe.write_text("ok", encoding="utf-8")
            probe.unlink(missing_ok=True)
            return candidate.resolve()
        except Exception:
            continue

    # Last resort: try current directory.
    return Path.cwd().resolve()


def _delete_fail_log_path() -> Path:
    """Choose a stable, user-owned log location (no configuration)."""

    if sys.platform == "darwin":
        return (
            Path.home()
            / "Library"
            / "Logs"
            / "typora-image-uploader"
            / "delete-failures.log"
        )

    if os.name == "nt":
        base = os.environ.get("LOCALAPPDATA")
        if base:
            return Path(base) / "typora-image-uploader" / "delete-failures.log"
        return Path.home() / "AppData" / "Local" / "typora-image-uploader" / "delete-failures.log"

    # Linux / other UNIX: follow XDG state dir when available.
    base = os.environ.get("XDG_STATE_HOME")
    if base:
        return Path(base) / "typora-image-uploader" / "delete-failures.log"
    return Path.home() / ".local" / "state" / "typora-image-uploader" / "delete-failures.log"


def _parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        add_help=True,
        description=(
            "Organize image files into a stable destination and print replacement URLs. "
            "Designed for Typora 'Custom Command' image upload."
        ),
    )
    p.add_argument(
        "paths",
        nargs="*",
        help="Image file paths (or file:// URIs). If omitted, reads from stdin.",
    )
    p.add_argument(
        "--dest",
        help="Destination root directory (default: auto-pick).",
    )
    p.add_argument(
        "--log",
        help="Path to delete-failures log (default: OS-appropriate location).",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Compute outputs without copying or deleting anything.",
    )
    p.add_argument(
        "--global-root",
        help=(
            "If an input path does not exist and is not absolute, try resolving it "
            "relative to this root."
        ),
    )
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = _parse_args(argv)

    inputs = _read_inputs(args.paths)
    if not inputs:
        return 0

    dest_root = Path(args.dest).expanduser().resolve() if args.dest else _pick_dest_root()
    delete_fail_log = (
        Path(args.log).expanduser().resolve() if args.log else _delete_fail_log_path()
    )

    # If the user explicitly chooses a destination, default to a flat layout
    # (no YYYY/MM subfolders). Otherwise, use YYYY/MM to avoid huge folders.
    if args.dest:
        dest_dir = dest_root
    else:
        date_dir = datetime.now().strftime("%Y/%m")
        dest_dir = (dest_root / date_dir).resolve()

    global_root = Path(args.global_root).expanduser().resolve() if args.global_root else None
    try:
        dest_dir.mkdir(parents=True, exist_ok=True)
    except Exception:
        # If we can't create the destination, just echo inputs back.
        sys.stdout.write("\n".join(inputs) + "\n")
        return 0

    outputs: list[str] = []
    for raw in inputs:
        try:
            src = _as_path(raw).expanduser()
            if not src.is_absolute() and global_root is not None:
                # Typora sometimes gives relative paths; allow a user-supplied root.
                alt = (global_root / src).expanduser()
                if alt.exists():
                    src = alt
            src = src.resolve()
            if not src.is_file():
                outputs.append(raw)
                continue

            # If Typora re-feeds a file we've already organized, don't delete it.
            if _is_under(src, dest_root):
                outputs.append(src.as_uri())
                continue

            digest = _sha256_file(src)
            suffix = src.suffix.lower()
            dst = dest_dir / f"{digest}{suffix}"

            # Copy first (never overwrite existing); then try deleting the source.
            if not dst.exists():
                if not args.dry_run:
                    copy2(src, dst)

            outputs.append(dst.resolve().as_uri())

            try:
                if not args.dry_run:
                    src.unlink()
            except Exception as exc:
                _append_delete_failure(delete_fail_log, src)
        except Exception:
            # Don't crash Typora; leave the original as-is.
            outputs.append(raw)

    sys.stdout.write("\n".join(outputs))
    if outputs:
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
