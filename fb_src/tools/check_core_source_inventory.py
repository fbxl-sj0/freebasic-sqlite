"""
Project: SQLite FreeBASIC port
-----------------------------

File: check_core_source_inventory.py

Purpose:

    Verify that every top-level SQLite C source file is represented in the
    porting inventory and that function-index exclusions are classified.

Responsibilities:

    - Match src/*.c files against PORTING_INVENTORY.csv.
    - Match implementation sources against PORTING_FUNCTIONS.csv.
    - Allow the data-only global.c unit and upstream C test support explicitly.

This file intentionally does NOT contain:

    - A semantic-equivalence check for C and FreeBASIC function bodies.
    - An inventory of loadable extensions outside the core src directory.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "src"
INVENTORY_PATH = ROOT / "fb_src" / "PORTING_INVENTORY.csv"
FUNCTION_INDEX_PATH = ROOT / "fb_src" / "PORTING_FUNCTIONS.csv"
DATA_ONLY_SOURCE = "src/global.c"


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as source:
        return list(csv.DictReader(source))


def main() -> int:
    source_files = {f"src/{path.name}" for path in SOURCE_DIR.glob("*.c")}
    inventory_rows = read_csv(INVENTORY_PATH)
    inventory = {row["Upstream source"]: row for row in inventory_rows}
    inventory_sources = {
        source
        for source in inventory
        if source.startswith("src/") and source.endswith(".c")
    }
    function_rows = read_csv(FUNCTION_INDEX_PATH)
    indexed_sources = {row["Upstream source"] for row in function_rows}

    errors: list[str] = []
    missing_inventory = sorted(source_files - inventory.keys())
    missing_sources = sorted(inventory_sources - source_files)
    unindexed_sources = sorted(source_files - indexed_sources)
    stale_index_sources = sorted(indexed_sources - source_files)

    for source in missing_inventory:
        errors.append(f"Missing inventory row: {source}")
    for source in missing_sources:
        errors.append(f"Inventory source file does not exist: {source}")
    for source in stale_index_sources:
        errors.append(f"Function index source file does not exist: {source}")

    data_only: list[str] = []
    test_support: list[str] = []
    for source in unindexed_sources:
        row = inventory.get(source)
        if source == DATA_ONLY_SOURCE and row and row["Kind"] == "C implementation":
            data_only.append(source)
        elif (
            row
            and row["Status"] == "Out of scope"
            and "test" in (row["Subsystem"] + " " + row["Kind"]).lower()
        ):
            test_support.append(source)
        else:
            errors.append(f"Unclassified source without function index rows: {source}")

    if data_only != [DATA_ONLY_SOURCE]:
        errors.append(f"Expected only {DATA_ONLY_SOURCE} as data-only source")

    print(f"Top-level src C files: {len(source_files)}")
    print(
        "Files represented in the function index: "
        f"{len(source_files & indexed_sources)}"
    )
    print(
        f"Data-only implementation files: {len(data_only)} "
        f"({', '.join(data_only)})"
    )
    print(f"C test-support files left upstream: {len(test_support)}")
    unclassified = sum("Unclassified source" in error for error in errors)
    print(f"Unclassified source files: {unclassified}")
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


# end of check_core_source_inventory.py
