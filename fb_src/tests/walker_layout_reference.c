/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: walker_layout_reference.c

    Purpose:

        Emit selected offsets and the size of SQLite's upstream Walker record.

    Responsibilities:

        - Compile the upstream Walker declaration from the SQLite amalgamation.
        - Print offsets for callback fields and the extra-state union.

    This file intentionally does NOT contain:

        - SQLite runtime tests.
        - A duplicate definition of Walker.
*/

#include "../../sqlite3.c"

#include <stddef.h>
#include <stdio.h>

int main(void){
  printf("%zu %zu %zu\n",
         offsetof(Walker, xExprCallback),
         offsetof(Walker, u),
         sizeof(Walker));
  return 0;
}

/* end of walker_layout_reference.c */
