"""
Project: SQLite FreeBASIC port
-----------------------------

File: check_function_body_coverage.py

Purpose:

    Check that every indexed upstream C function has a FreeBASIC procedure
    definition in the port source tree.

Responsibilities:

    - Read a selected function index and verify its body and scope status.
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
ALLOWED_ABSENT_STATUSES = {
    "Test support left in C",
    "Disabled upstream",
    "Loadable extension entry point",
    "Optional instrumentation",
}
PENDING_STATUSES = {"Needs debug port", "Needs port"}


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
    if len(sys.argv) > 2:
        print(
            "usage: check_function_body_coverage.py [functions.csv]",
            file=sys.stderr,
        )
        return 2

    if len(sys.argv) == 2:
        inventory_path = Path(sys.argv[1])
        if not inventory_path.is_absolute():
            inventory_path = Path.cwd() / inventory_path
    else:
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
    missing_body = [
        row
        for row in rows
        if row.get("Port status") == "FB body present"
        and (row.get("Function") or "").lower() not in implementation_names
    ]
    pending = [row for row in rows if row.get("Port status") in PENDING_STATUSES]
    invalid_status = [
        row
        for row in rows
        if row.get("Port status") not in {
            "FB body present",
            *PENDING_STATUSES,
            *ALLOWED_ABSENT_STATUSES,
        }
    ]
    exclusions = {
        status: sum(row.get("Port status") == status for row in rows)
        for status in sorted(ALLOWED_ABSENT_STATUSES)
        if any(row.get("Port status") == status for row in rows)
    }

    present_count = sum(row.get("Port status") == "FB body present" for row in rows)
    matched_count = present_count - len(missing_body)
    print(f"Function index: {inventory_path}")
    print(f"Indexed upstream function rows: {len(rows)}")
    print(f"Rows marked FB body present: {present_count}")
    print(f"Rows matched by name or C ABI Alias: {matched_count}")
    print(f"Missing in-scope bodies: {len(pending) + len(missing_body)}")
    for status, count in exclusions.items():
        print(f"Classified absent ({status}): {count}")

    if pending or missing_body:
        print("Missing procedure definitions:", file=sys.stderr)
        for row in pending + missing_body:
            print(
                f"  {row.get('Upstream source')}:{row.get('Start line')} "
                f"{row.get('Function')}: {row.get('Port status')}",
                file=sys.stderr,
            )
    if invalid_status:
        print("Rows with an unrecognized port status:", file=sys.stderr)
        for row in invalid_status:
            print(
                f"  {row.get('Upstream source')}:{row.get('Start line')} "
                f"{row.get('Function')}: {row.get('Port status')}",
                file=sys.stderr,
            )

    return 1 if pending or missing_body or invalid_status else 0


if __name__ == "__main__":
    raise SystemExit(main())

# end of check_function_body_coverage.py
