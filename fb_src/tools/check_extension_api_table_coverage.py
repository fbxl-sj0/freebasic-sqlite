"""
Project: SQLite FreeBASIC port
-----------------------------

File: check_extension_api_table_coverage.py

Purpose:

    Verify that the FreeBASIC extension API pointer table represents every
    slot from the upstream sqlite3_api_routines structure.

Responsibilities:

    - Count upstream API fields in source order.
    - Check FreeBASIC slot assignments for duplicates and out-of-range indices.
    - Allow only upstream's intentionally null global_recover slot.

This file intentionally does NOT contain:

    - A runtime ABI or behavioral comparison for extension calls.
    - SQLite API implementations or C2FB generation logic.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


ARRAY_RE = re.compile(
    r"\bsqlite3Apis\s*\(\s*0\s+To\s+(\d+)\s*\)\s+As\s+Any\s+Ptr\b",
    re.IGNORECASE,
)
ASSIGNMENT_RE = re.compile(r"\bsqlite3Apis\s*\(\s*(\d+)\s*\)\s*=")
FIELD_RE = re.compile(r"\(\s*(?:(?:SQLITE_CDECL)\s*)?\*\s*(\w+)\s*\)")


def api_field_names(header: str) -> list[str]:
    """Read top-level function-pointer fields in sqlite3_api_routines."""
    declaration_start = header.find("struct sqlite3_api_routines {")
    if declaration_start < 0:
        raise ValueError("sqlite3_api_routines declaration not found")

    declaration_end = header.find("\n};", declaration_start)
    if declaration_end < 0:
        raise ValueError("sqlite3_api_routines declaration is not terminated")

    fields: list[str] = []
    body = header[declaration_start:declaration_end]
    for line in body.splitlines()[1:]:
        indentation = len(line) - len(line.lstrip(" "))
        if indentation != 2:
            continue
        match = FIELD_RE.search(line)
        if match is not None:
            fields.append(match.group(1))
    return fields


def main() -> int:
    fb_root = Path(__file__).resolve().parents[1]
    repo_root = fb_root.parent
    table_path = fb_root / "sqlite3_extension_api_table.bi"
    header_path = repo_root / "src/sqlite3ext.h"
    loadext_path = repo_root / "src/loadext.c"

    try:
        table_source = table_path.read_text(encoding="utf-8")
        header_source = header_path.read_text(encoding="utf-8")
        loadext_source = loadext_path.read_text(encoding="utf-8")
    except OSError as error:
        print(f"cannot read SQLite API table sources: {error}", file=sys.stderr)
        return 2

    array_match = ARRAY_RE.search(table_source)
    if array_match is None:
        print(f"cannot find sqlite3Apis array declaration in {table_path}", file=sys.stderr)
        return 2

    maximum_index = int(array_match.group(1))
    slot_count = maximum_index + 1
    try:
        fields = api_field_names(header_source)
    except ValueError as error:
        print(error, file=sys.stderr)
        return 2

    assignment_indices = [int(value) for value in ASSIGNMENT_RE.findall(table_source)]
    duplicates = sorted(
        index for index in set(assignment_indices) if assignment_indices.count(index) > 1
    )
    out_of_range = sorted(index for index in assignment_indices if index >= slot_count)
    missing = sorted(set(range(slot_count)) - set(assignment_indices))

    c_array_start = loadext_source.find("static const sqlite3_api_routines sqlite3Apis = {")
    if c_array_start < 0:
        print("upstream sqlite3Apis initializer not found in src/loadext.c", file=sys.stderr)
        return 2
    c_array_end = loadext_source.find("\n};", c_array_start)
    if c_array_end < 0:
        print("upstream sqlite3Apis initializer is not terminated", file=sys.stderr)
        return 2
    c_initializer = loadext_source[c_array_start:c_array_end]
    retired_slot_is_null = re.search(
        r"\b0\s*,\s*/\*\s*Was\s+sqlite3_global_recover\(\).*?\*/",
        c_initializer,
        re.DOTALL,
    ) is not None

    errors: list[str] = []
    if slot_count != len(fields):
        errors.append(
            f"FreeBASIC array has {slot_count} slots but the upstream header has "
            f"{len(fields)} fields"
        )
    if duplicates:
        errors.append(f"duplicate slot assignments: {duplicates}")
    if out_of_range:
        errors.append(f"out-of-range slot assignments: {out_of_range}")
    if missing != [63]:
        errors.append(f"unexpected unassigned slots: {missing}")
    elif len(fields) <= 63 or fields[63] != "global_recover":
        errors.append("unassigned slot 63 does not match the upstream global_recover field")
    if not retired_slot_is_null:
        errors.append("src/loadext.c does not mark global_recover as intentionally null")

    print(f"Upstream extension API slots: {len(fields)}")
    print(f"FreeBASIC pointer assignments: {len(set(assignment_indices))}")
    print("Intentional null slot: 63 (global_recover)")
    print(f"Unexpected missing slots: {len(missing) - (1 if missing == [63] else 0)}")

    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# end of check_extension_api_table_coverage.py
