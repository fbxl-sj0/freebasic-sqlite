/*
    Project: SQLite FreeBASIC port verification
    ------------------------------------------

    File: sqlite_omit_parser_features_api.c

    Purpose:

        Check several parser features omitted in one FreeBASIC build.

    Responsibilities:

        • Confirm basic SELECT and main-table creation remain available.
        • Confirm omitted schema commands and SQL forms are rejected.

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
        expectResult(db, "CREATE TABLE t(x)", SQLITE_OK)!=0 ){
        sqlite3_close(db);
        return 2;
    }

    static const char *omittedSql[] = {
        "PRAGMA user_version",
        "ANALYZE",
        "REINDEX",
        "ATTACH ':memory:' AS other",
        "VACUUM",
        "CREATE TEMP TABLE temp_table(x)",
        "CREATE TABLE generated(a,b GENERATED ALWAYS AS (a+1) VIRTUAL)",
        "CREATE VIEW v AS SELECT 1",
        "DROP VIEW IF EXISTS v",
        "CREATE TRIGGER tr AFTER INSERT ON t BEGIN SELECT 1; END",
        "DROP TRIGGER IF EXISTS tr",
        "EXPLAIN SELECT 1",
        "EXPLAIN QUERY PLAN SELECT 1",
        "SELECT CAST(1 AS TEXT)",
        "SELECT 1 UNION SELECT 2",
        "SELECT * FROM (SELECT 1)",
        "WITH x AS (SELECT 1) SELECT * FROM x"
    };

    for( unsigned int index = 0;
         index < sizeof(omittedSql) / sizeof(omittedSql[0]);
         index++ ){
        if( expectResult(db, omittedSql[index], SQLITE_ERROR)!=0 ){
            sqlite3_close(db);
            return 3;
        }
    }

    rc = sqlite3_close(db);
    if( rc!=SQLITE_OK ){
        fprintf(stderr, "sqlite3_close failed: %d\n", rc);
        return 4;
    }
    puts("PASS: enabled core queries work; omitted parser features are rejected");
    return 0;
}

/* end of sqlite_omit_parser_features_api.c */
