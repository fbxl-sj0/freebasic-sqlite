"""
Project: SQLite FreeBASIC port
-----------------------------

File: check_function_body_coverage.py

Purpose:

    Check that every indexed upstream C function has a FreeBASIC procedure
    definition in the port source tree.

Responsibilities:

    - Read PORTING_FUNCTIONS.csv and verify each row's port status.
    - Match C names to FreeBASIC Function/Sub names or their C ABI Alias.
    - Include procedure bodies kept in .bi files while excluding generated
      build output and unintegrated candidate conversions.

This file intentionally does NOT contain:

    - A semantic-equivalence checker for C and FreeBASIC implementations.
    - Build or runtime tests for the SQLite engine.
"""

from __future__ import annotations

import csv
import re
import sys
from collections import defaultdict
from pathlib import Path


PROCEDURE_RE = re.compile(
    r"^\s*(?:(?:Private|Public|Static|Virtual|Override|Final|Abstract|"
    r"Operator|Constructor|Destructor|Property)\s+)*"
    r"(Function|Sub)\s+([A-Za-z_][A-Za-z_0-9]*)\b(.*)$",
    re.IGNORECASE,
)
ALIAS_RE = re.compile(r"\bAlias\s+[\"']([^\"']+)[\"']", re.IGNORECASE)


def find_procedure_names(root: Path) -> dict[str, list[str]]:
    """Map procedure names and explicit C aliases to defining source files."""
    names: dict[str, list[str]] = defaultdict(list)

    for path in sorted((*root.rglob("*.bas"), *root.rglob("*.bi"))):
        relative_parts = path.relative_to(root).parts
        if "build" in relative_parts or any(
            "candidate" in part.lower() for part in relative_parts[:-1]
        ):
            continue

        try:
            source_lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError as error:
            print(f"cannot read {path}: {error}", file=sys.stderr)
            continue

        for line_number, line in enumerate(source_lines, start=1):
            match = PROCEDURE_RE.match(line)
            if match is None or re.match(r"^\s*Declare\b", line, re.IGNORECASE):
                continue

            location = f"{path.relative_to(root)}:{line_number}"
            procedure_name = match.group(2).lower()
            names[procedure_name].append(location)

            alias_match = ALIAS_RE.search(match.group(3))
            if alias_match is not None:
                names[alias_match.group(1).lower()].append(f"{location} (Alias)")

    return names


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    inventory_path = root / "PORTING_FUNCTIONS.csv"

    try:
        with inventory_path.open(newline="", encoding="utf-8") as inventory_file:
            rows = list(csv.DictReader(inventory_file))
    except OSError as error:
        print(f"cannot read {inventory_path}: {error}", file=sys.stderr)
        return 2

    if not rows:
        print(f"no function rows found in {inventory_path}", file=sys.stderr)
        return 2

    implementation_names = find_procedure_names(root)
    missing = [
        row
        for row in rows
        if (row.get("Function") or "").lower() not in implementation_names
    ]
    incomplete_status = [
        row for row in rows if row.get("Port status") != "FB body present"
    ]

    matched_count = len(rows) - len(missing)
    print(f"Indexed upstream function rows: {len(rows)}")
    print(f"Rows marked FB body present: {len(rows) - len(incomplete_status)}")
    print(f"Rows matched by name or C ABI Alias: {matched_count}")
    print(f"Unmatched rows: {len(missing)}")

    if missing:
        print("Missing procedure definitions:", file=sys.stderr)
        for row in missing:
            print(
                f"  {row.get('Upstream source')}:{row.get('Start line')} "
                f"{row.get('Function')}",
                file=sys.stderr,
            )
    if incomplete_status:
        print("Rows without completed port status:", file=sys.stderr)
        for row in incomplete_status:
            print(
                f"  {row.get('Upstream source')}:{row.get('Start line')} "
                f"{row.get('Function')}: {row.get('Port status')}",
                file=sys.stderr,
            )

    return 1 if missing or incomplete_status else 0


if __name__ == "__main__":
    raise SystemExit(main())

# end of check_function_body_coverage.py
