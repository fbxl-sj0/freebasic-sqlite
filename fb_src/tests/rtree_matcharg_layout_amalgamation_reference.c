/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: rtree_matcharg_layout_amalgamation_reference.c

    Purpose:

        Emit the upstream R-Tree match-argument offset from SQLite's
        amalgamation for a Win32 Wine ABI comparison.

    Responsibilities:

        - Compile SQLite's amalgamated R-Tree structure for i686 Windows.
        - Print the offset of its flexible parameter array.

    This file intentionally does NOT contain:

        - A duplicate definition of RtreeMatchArg.
        - SQLite runtime tests.
*/

#define SQLITE_ENABLE_RTREE 1
#define SQLITE_THREADSAFE 0

#include "../../sqlite3.c"

#include <stddef.h>
#include <stdio.h>

int main(void){
  printf("%zu\n", offsetof(RtreeMatchArg, aParam));
  return 0;
}

/* end of rtree_matcharg_layout_amalgamation_reference.c */
