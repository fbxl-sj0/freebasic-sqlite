/'
    Project: SQLite FreeBASIC port
    ------------------------------

    File: rtree_matcharg_layout.bas

    Purpose:

        Emit the FreeBASIC R-Tree match-argument tail offset for comparison
        with SQLite's upstream C structure.

    Responsibilities:

        - Use the production FreeBASIC R-Tree record declaration.
        - Print the offset of its addressable parameter tail.

    This file intentionally does NOT contain:

        - A duplicate FreeBASIC record declaration.
        - SQLite runtime tests.
'/

#include once "sqlite3_rtree_types.bi"

Print Trim(Str(OffsetOf(SqliteRtreeMatchArg, aParam(0))))

/' end of rtree_matcharg_layout.bas '/
