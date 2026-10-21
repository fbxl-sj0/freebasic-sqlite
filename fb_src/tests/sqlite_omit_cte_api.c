/*
    Project: SQLite FreeBASIC port verification
    ------------------------------------------

    File: sqlite_omit_cte_api.c

    Purpose:

        Check public API behavior in a SQLITE_OMIT_CTE library build.

    Responsibilities:

        • Confirm scalar SELECT remains available.
        • Confirm ordinary and recursive CTE syntax is rejected.

    This file intentionally does NOT contain:

        • SQLite implementation code.
        • A port of upstream test scripts.
*/
#include "sqlite3.h"

#include <stdio.h>

static int expectResult(sqlite3 *db, const char *sql, int expectedRc){
    char *errorMessage = 0;
    int rc = sqlite3_exec(db, sql, 0, 0, &errorMessage);
    if( rc!=expectedRc ){
        fprintf(stderr, "SQL returned %d, expected %d: %s (%s)\n",
                rc, expectedRc, sql, errorMessage ? errorMessage : "");
        sqlite3_free(errorMessage);
        return 1;
    }
    sqlite3_free(errorMessage);
    return 0;
}

int main(void){
    sqlite3 *db = 0;
    int rc = sqlite3_open(":memory:", &db);
    if( rc!=SQLITE_OK ){
        fprintf(stderr, "sqlite3_open failed: %d\n", rc);
        if( db ) sqlite3_close(db);
        return 1;
    }

    if( expectResult(db, "SELECT 1", SQLITE_OK)!=0 ||
        expectResult(db, "WITH x AS (SELECT 1) SELECT * FROM x", SQLITE_ERROR)!=0 ||
        expectResult(db,
            "WITH RECURSIVE x(n) AS (VALUES(1) UNION ALL "
            "SELECT n+1 FROM x WHERE n<3) SELECT sum(n) FROM x",
            SQLITE_ERROR)!=0 ){
        sqlite3_close(db);
        return 2;
    }

    rc = sqlite3_close(db);
    if( rc!=SQLITE_OK ){
        fprintf(stderr, "sqlite3_close failed: %d\n", rc);
        return 3;
    }
    puts("PASS: scalar SELECT works; ordinary and recursive CTEs are omitted");
    return 0;
}

/* end of sqlite_omit_cte_api.c */
