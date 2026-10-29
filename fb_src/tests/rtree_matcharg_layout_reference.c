/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: rtree_matcharg_layout_reference.c

    Purpose:

        Emit the upstream R-Tree match-argument flexible-array offset for
        comparison with the FreeBASIC record layout.

    Responsibilities:

        - Compile the upstream R-Tree structure definition.
        - Print the offset of its flexible parameter array.

    This file intentionally does NOT contain:

        - SQLite runtime tests.
        - A duplicate definition of RtreeMatchArg.
*/

#define SQLITE_CORE 1
#define SQLITE_ENABLE_RTREE 1

#include "../../ext/rtree/rtree.c"

#include <stddef.h>
#include <stdio.h>

int main(void){
  printf("%zu\n", offsetof(RtreeMatchArg, aParam));
  return 0;
}

/* end of rtree_matcharg_layout_reference.c */
