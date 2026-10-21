#!/usr/bin/env python3
"""
Project: SQLite FreeBASIC port
-----------------------------

File: check_public_api_exports.py

Purpose:

    Compare generated public C API declarations with a built shared library's
    exported symbols.

Responsibilities:

    - Read sqlite3_* aliases from sqlite3_api_declarations.bi.
    - Inspect dynamic symbols with nm.
    - Allow profile-specific omissions to be listed explicitly.

This file intentionally does NOT contain:

    - SQLite API implementations.
    - A compile-time feature profile or an implicit omission list.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


ALIAS_PATTERN = re.compile(r'Alias\s+"(sqlite3_[A-Za-z0-9_]+)"')


def read_declared_api(path: Path) -> set[str]:
    source = path.read_text(encoding="utf-8")
    return set(ALIAS_PATTERN.findall(source))


def read_exported_symbols(library: Path, nm: str) -> set[str]:
    result = subprocess.run(
        [nm, "-D", "--defined-only", str(library)],
        check=True,
        capture_output=True,
        text=True,
    )
    symbols: set[str] = set()
    for line in result.stdout.splitlines():
        fields = line.split()
        if fields:
            symbols.add(fields[-1].split("@", 1)[0])
    return symbols


def main() -> int:
    script_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("library", type=Path, help="shared library to inspect")
    parser.add_argument(
        "--declarations",
        type=Path,
        default=script_root / "sqlite3_api_declarations.bi",
        help="generated FreeBASIC declaration file",
    )
    parser.add_argument(
        "--nm",
        default="nm",
        help="nm executable to use",
    )
    parser.add_argument(
        "--allow-missing",
        action="append",
        default=[],
        metavar="SYMBOL",
        help="profile-specific API symbol expected to be absent",
    )
    args = parser.parse_args()

    if not args.library.is_file():
        parser.error(f"library does not exist: {args.library}")
    if not args.declarations.is_file():
        parser.error(f"declaration file does not exist: {args.declarations}")

    try:
        declared = read_declared_api(args.declarations)
        exported = read_exported_symbols(args.library, args.nm)
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"API export inspection failed: {error}", file=sys.stderr)
        return 2

    missing = declared - exported
    allowed = set(args.allow_missing)
    unexpected = sorted(missing - allowed)
    allowed_missing = sorted(missing & allowed)

    print(f"Public API declarations: {len(declared)}")
    print(f"Declared APIs exported: {len(declared & exported)}")
    print(f"Allowed profile omissions: {len(allowed_missing)}")
    if allowed_missing:
        print("Allowed but absent:")
        for name in allowed_missing:
            print(f"  {name}")
    if unexpected:
        print(f"Unexpectedly absent API symbols: {len(unexpected)}")
        for name in unexpected:
            print(f"  {name}")
        return 1

    print("All profile-required public API symbols are exported.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# end of check_public_api_exports.py
