"""
    Project: SQLite FreeBASIC port
    ------------------------------

    File: check_win_vfs_callback_abi.py

    Purpose:

        Verify that Windows VFS callbacks use SQLite's C calling convention
        in both FreeBASIC declarations and a linked Windows DLL.

    Responsibilities:

        - Read callback assignments from the Windows VFS implementation.
        - Check their function-pointer types and FreeBASIC definitions.
        - Reject Win32 stdcall-decorated symbols in the linked DLL.

    This file intentionally does NOT contain:

        - SQLite runtime code or compiler-specific ABI fixes.
        - A replacement for executing the Windows VFS under Wine or Windows.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


CALLBACK_ASSIGNMENT = re.compile(
    r"CPtr\(\s*(Sqlite(?:File|Vfs)[A-Za-z0-9_]*Proc)\s*,\s*"
    r"@([A-Za-z_][A-Za-z0-9_]*)\s*\)",
    re.DOTALL,
)
CALLBACK_TYPE = re.compile(
    r"^\s*Type\s+([A-Za-z_][A-Za-z0-9_]*)\s+As\s+"
    r"(?:Function|Sub)\s+(CDecl|StdCall)\b",
    re.IGNORECASE | re.MULTILINE,
)
FUNCTION_HEADER = re.compile(
    r"^\s*(?:(?:Private|Public|Static)\s+)?(?:Function|Sub)\s+"
    r"([A-Za-z_][A-Za-z0-9_]*)([^\r\n]*)$",
    re.IGNORECASE | re.MULTILINE,
)
STDCALL_SUFFIX = re.compile(r"@[0-9]+$")


def callback_types(path: Path) -> dict[str, str]:
    return {name.casefold(): convention.casefold()
            for name, convention in CALLBACK_TYPE.findall(path.read_text())}


def callback_definitions(paths: list[Path]) -> dict[str, list[str]]:
    definitions: dict[str, list[str]] = {}
    for path in paths:
        text = path.read_text()
        for name, tail in FUNCTION_HEADER.findall(text):
            header = tail.split("(", 1)[0]
            convention = "cdecl" if re.search(r"\bCDecl\b", header, re.I) else "default"
            definitions.setdefault(name.casefold(), []).append(convention)
    return definitions


def symbol_base(symbol: str) -> str:
    return symbol.lstrip("_").split("@", 1)[0].casefold()


def linked_symbols(dll: Path, nm_tool: str) -> list[str]:
    result = subprocess.run(
        [nm_tool, "-n", str(dll)],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.split()[-1] for line in result.stdout.splitlines() if line.split()]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dll", required=True, type=Path, help="linked Win32 or Win64 SQLite DLL")
    parser.add_argument("--nm", default="llvm-nm", help="llvm-nm-compatible COFF symbol reader")
    args = parser.parse_args()

    source_root = Path(__file__).resolve().parent.parent
    implementation = source_root / "sqlite3_os_win_helpers.bas"
    syscall_dispatch = source_root / "sqlite3_os_win_syscall_dispatch.bi"
    syscall_table = source_root / "sqlite3_os_win_syscall_table.bi"
    interface_types = source_root / "sqlite3_vfs.bi"

    assignments = sorted(set(CALLBACK_ASSIGNMENT.findall(implementation.read_text())))
    if not assignments:
        print("error: no Windows VFS callback assignments found", file=sys.stderr)
        return 1

    types = callback_types(interface_types)
    definitions = callback_definitions(
        [implementation, syscall_dispatch, syscall_table]
    )
    symbols = linked_symbols(args.dll, args.nm)
    errors: list[str] = []

    for type_name, function_name in assignments:
        if types.get(type_name.casefold()) != "cdecl":
            errors.append(f"{type_name}: callback pointer type is missing CDecl")

        function_conventions = definitions.get(function_name.casefold(), [])
        if not function_conventions:
            errors.append(f"{function_name}: FreeBASIC callback definition was not found")
        elif any(convention != "cdecl" for convention in function_conventions):
            errors.append(f"{function_name}: callback definition is not explicitly CDecl")

        matches = [symbol for symbol in symbols if symbol_base(symbol) == function_name.casefold()]
        if not matches:
            errors.append(f"{function_name}: callback symbol was not found in {args.dll}")
        elif any(STDCALL_SUFFIX.search(symbol) for symbol in matches):
            errors.append(f"{function_name}: Win32 stdcall decoration found: {', '.join(matches)}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"Checked {len(assignments)} Windows VFS callback assignments in {args.dll}")
    print("All callback types and bodies are explicitly CDecl; linked symbols have no stdcall decoration.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# end of check_win_vfs_callback_abi.py
