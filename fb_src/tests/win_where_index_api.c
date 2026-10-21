/*
    Project: SQLite FreeBASIC port verification
    ------------------------------------------

    File: win_where_index_api.c

    Purpose:

        Exercise indexed IN-constraint code through the Windows C ABI.

    Responsibilities:

        - Open an in-memory database and create indexed tables.
        - Check list, subquery, composite-key, reverse-order, and rowid IN scans.
        - Compare each result with a small expected row set.

    This file intentionally does NOT contain:

        - SQLite implementation code.
        - A replacement for the upstream Tcl test suites.
*/
#include "sqlite3.h"

#include <stdio.h>

typedef struct ExpectedRow ExpectedRow;
struct ExpectedRow {
    sqlite3_int64 value[2];
};

static int expectRows(
    sqlite3 *db,
    const char *sql,
    int nColumn,
    const ExpectedRow *expected,
    int nExpected
){
    sqlite3_stmt *stmt = 0;
    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
    int row = 0;

    if( rc!=SQLITE_OK ){
        fprintf(stderr, "prepare failed (%d): %s\nSQL: %s\n",
                rc, sqlite3_errmsg(db), sql);
        return 1;
    }
    while( (rc=sqlite3_step(stmt))==SQLITE_ROW ){
        if( row>=nExpected || sqlite3_column_count(stmt)!=nColumn ){
            fprintf(stderr, "unexpected row or column count\nSQL: %s\n", sql);
            sqlite3_finalize(stmt);
            return 1;
        }
        for(int column=0; column<nColumn; column++){
            sqlite3_int64 value = sqlite3_column_int64(stmt, column);
            if( value!=expected[row].value[column] ){
                fprintf(stderr,
                        "row %d column %d got %lld expected %lld\nSQL: %s\n",
                        row, column, (long long)value,
                        (long long)expected[row].value[column], sql);
                sqlite3_finalize(stmt);
                return 1;
            }
        }
        row++;
    }
    if( rc!=SQLITE_DONE || row!=nExpected ){
        fprintf(stderr, "step failed (%d), rows %d expected %d: %s\nSQL: %s\n",
                rc, row, nExpected, sqlite3_errmsg(db), sql);
        sqlite3_finalize(stmt);
        return 1;
    }
    rc = sqlite3_finalize(stmt);
    if( rc!=SQLITE_OK ){
        fprintf(stderr, "finalize failed (%d): %s\nSQL: %s\n",
                rc, sqlite3_errmsg(db), sql);
        return 1;
    }
    return 0;
}

int main(void){
    static const ExpectedRow leadingIn[] = {
        {{1, 10}}, {{1, 20}}, {{1, 30}}, {{3, 10}}
    };
    static const ExpectedRow prefixIn[] = {
        {{1, 10}}, {{1, 20}}
    };
    static const ExpectedRow multiIn[] = {
        {{1, 10}}, {{1, 20}}, {{2, 10}}, {{2, 20}}
    };
    static const ExpectedRow compositeIn[] = {
        {{1, 20}}, {{3, 10}}
    };
    static const ExpectedRow reverseIn[] = {
        {{1, 30}}, {{1, 10}}
    };
    static const ExpectedRow rowidIn[] = {
        {{2, 20}}, {{5, 50}}
    };
    static const ExpectedRow nullIn[] = {
        {{1, 10}}, {{1, 20}}, {{1, 30}}, {{3, 10}}
    };
    static const char setupSql[] =
        "CREATE TABLE t(a INTEGER NOT NULL,b INTEGER NOT NULL);"
        "CREATE INDEX t_ab ON t(a,b);"
        "INSERT INTO t VALUES"
        "(1,10),(1,20),(1,30),(2,10),(2,20),(3,10),(4,40);"
        "CREATE TABLE filter(x INTEGER);"
        "INSERT INTO filter VALUES(1),(3);"
        "CREATE TABLE pairs(x INTEGER,y INTEGER);"
        "INSERT INTO pairs VALUES(1,20),(3,10);"
        "CREATE TABLE r(id INTEGER PRIMARY KEY,v INTEGER NOT NULL);"
        "INSERT INTO r VALUES(1,10),(2,20),(3,30),(4,40),(5,50);";
    static const struct {
        const char *sql;
        int nColumn;
        const ExpectedRow *rows;
        int nRow;
    } cases[] = {
        {
            "SELECT a,b FROM t INDEXED BY t_ab WHERE a IN (1,3) ORDER BY a,b",
            2, leadingIn, 4
        },
        {
            "SELECT a,b FROM t INDEXED BY t_ab "
            "WHERE a=1 AND b IN (20,10) ORDER BY b",
            2, prefixIn, 2
        },
        {
            "SELECT a,b FROM t INDEXED BY t_ab "
            "WHERE a IN (SELECT x FROM filter) ORDER BY a,b",
            2, leadingIn, 4
        },
        {
            "SELECT a,b FROM t INDEXED BY t_ab "
            "WHERE a IN (1,2) AND b IN (10,20) ORDER BY a,b",
            2, multiIn, 4
        },
        {
            "SELECT a,b FROM t INDEXED BY t_ab "
            "WHERE (a,b) IN (SELECT x,y FROM pairs) ORDER BY a,b",
            2, compositeIn, 2
        },
        {
            "SELECT a,b FROM t INDEXED BY t_ab "
            "WHERE a=1 AND b IN (10,30) ORDER BY b DESC",
            2, reverseIn, 2
        },
        {
            "SELECT id,v FROM r WHERE id IN (2,5) ORDER BY id",
            2, rowidIn, 2
        },
        {
            "SELECT a,b FROM t INDEXED BY t_ab "
            "WHERE a IN (1,NULL,3) ORDER BY a,b",
            2, nullIn, 4
        }
    };
    sqlite3 *db = 0;
    char *error = 0;
    int rc = sqlite3_open(":memory:", &db);

    if( rc!=SQLITE_OK ){
        fprintf(stderr, "open failed (%d)\n", rc);
        if( db ) sqlite3_close(db);
        return 1;
    }
    rc = sqlite3_exec(db, setupSql, 0, 0, &error);
    if( rc!=SQLITE_OK ){
        fprintf(stderr, "setup failed (%d): %s\n",
                rc, error ? error : sqlite3_errmsg(db));
        sqlite3_free(error);
        sqlite3_close(db);
        return 2;
    }
    sqlite3_free(error);

    for(size_t i=0; i<sizeof(cases)/sizeof(cases[0]); i++){
        if( expectRows(db, cases[i].sql, cases[i].nColumn,
                       cases[i].rows, cases[i].nRow)!=0 ){
            sqlite3_close(db);
            return 3;
        }
    }
    rc = sqlite3_close(db);
    if( rc!=SQLITE_OK ){
        fprintf(stderr, "close failed (%d)\n", rc);
        return 4;
    }
    printf("PASS: %u indexed IN-query cases\n",
           (unsigned)(sizeof(cases)/sizeof(cases[0])));
    return 0;
}

/* end of win_where_index_api.c */
