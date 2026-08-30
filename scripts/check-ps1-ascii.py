#!/usr/bin/env python3
"""Fail if scripts/*.ps1 would break Windows PowerShell 5.1's ANSI parser.

Windows PowerShell 5.1 reads BOM-less .ps1 files as the system ANSI code page
(CP1252 / CP1258). UTF-8 em dash bytes E2 80 94 become â€ + U+201D, and
PowerShell treats U+201D as a string closer. Keep installer scripts ASCII.
"""
from __future__ import annotations

import sys
from pathlib import Path

SMART_QUOTES = {0x2018, 0x2019, 0x201C, 0x201D}
BOM = b"\xef\xbb\xbf"


def check(path: Path) -> list[str]:
    raw = path.read_bytes()
    if raw.startswith(BOM):
        raw = raw[3:]
    errors: list[str] = []
    if any(b > 127 for b in raw):
        errors.append(f"{path}: contains non-ASCII bytes (keep .ps1 files ASCII)")
    try:
        ansi = raw.decode("cp1252")
    except UnicodeDecodeError as exc:
        errors.append(f"{path}: not decodable as CP1252: {exc}")
        return errors
    if any(ord(ch) in SMART_QUOTES for ch in ansi):
        errors.append(
            f"{path}: CP1252 decode produces a smart quote "
            "(Windows PowerShell will treat it as a string delimiter)"
        )
    return errors


def main() -> int:
    root = Path(__file__).resolve().parent
    paths = sorted(root.glob("*.ps1"))
    if not paths:
        print("error: no .ps1 files next to this checker", file=sys.stderr)
        return 1
    errors: list[str] = []
    for path in paths:
        errors.extend(check(path))
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"ok: {len(paths)} .ps1 file(s) are ASCII-safe under CP1252")
    return 0


if __name__ == "__main__":
    sys.exit(main())
