/'
    Project: SQLite FreeBASIC port
    ------------------------------

    File: walker_layout.bas

    Purpose:

        Emit the production FreeBASIC Walker offsets for comparison with C.

    Responsibilities:

        - Use the port's SqliteWalker declaration.
        - Print callback and extra-state offsets and total size.

    This file intentionally does NOT contain:

        - A duplicate FreeBASIC Walker declaration.
        - SQLite runtime tests.
'/

#include once "sqlite3_walker.bi"

Print Trim(Str(OffsetOf(SqliteWalker, xExprCallback))) & " " & _
      Trim(Str(OffsetOf(SqliteWalker, u))) & " " & _
      Trim(Str(SizeOf(SqliteWalker)))

/' end of walker_layout.bas '/
