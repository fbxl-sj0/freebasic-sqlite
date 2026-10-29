/*
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: column_metadata16_smoke.c

    Purpose:

        Exercise the UTF-16 column-origin APIs against the FreeBASIC library.

    Responsibilities:

        - Check UTF-16 database, table, and source-column names.
        - Cover direct table, view, and scalar-subquery result columns.
        - Confirm expressions without a column origin return NULL metadata.

    This file intentionally does NOT contain:

        - Changes to upstream tests or the SQLite engine.
        - A replacement for the upstream Tcl C API test suite.
*/
#include <stdio.h>
#include <string.h>
#include "sqlite3.h"

static int eq_ascii16(const void *value, const char *expected){
  const unsigned short *p = (const unsigned short *)value;
  size_t i;
  if( p==0 ) return 0;
  for(i=0; expected[i]; i++){
    if( p[i]!=(unsigned char)expected[i] ) return 0;
  }
  return p[i]==0;
}

static int check_query(sqlite3 *db, const char *sql, const char *column){
  sqlite3_stmt *stmt = 0;
  int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "prepare failed for %s: %s\n", sql, sqlite3_errmsg(db));
    return 1;
  }
  const void *database = sqlite3_column_database_name16(stmt, 0);
  const void *table = sqlite3_column_table_name16(stmt, 0);
  const void *origin = sqlite3_column_origin_name16(stmt, 0);
  int ok = eq_ascii16(database, "main") &&
           eq_ascii16(table, "tab1") &&
           eq_ascii16(origin, column);
  if( !ok ){
    fprintf(stderr, "%s: metadata mismatch (db=%p table=%p col=%p)\n",
            sql, database, table, origin);
  }
  sqlite3_finalize(stmt);
  return !ok;
}

int main(void){
  sqlite3 *db = 0;
  int rc = sqlite3_open(":memory:", &db);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "open failed: %s\n", db ? sqlite3_errmsg(db) : "no handle");
    return 1;
  }
  rc = sqlite3_exec(db,
      "CREATE TABLE tab1(col1, col2);"
      "CREATE VIEW view1 AS SELECT * FROM tab1;",
      0, 0, 0);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "schema setup failed: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    return 1;
  }

  int failed = 0;
  failed |= check_query(db, "SELECT col2 FROM tab1", "col2");
  failed |= check_query(db, "SELECT col1 FROM view1", "col1");
  failed |= check_query(db, "SELECT (SELECT col2 FROM tab1)", "col2");
  failed |= check_query(db, "SELECT (SELECT col1 FROM view1)", "col1");

  sqlite3_stmt *stmt = 0;
  rc = sqlite3_prepare_v2(db, "SELECT 1", -1, &stmt, 0);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "expression prepare failed: %s\n", sqlite3_errmsg(db));
    failed = 1;
  }else{
    if( sqlite3_column_database_name16(stmt, 0)!=0 ||
        sqlite3_column_table_name16(stmt, 0)!=0 ||
        sqlite3_column_origin_name16(stmt, 0)!=0 ){
      fprintf(stderr, "constant expression unexpectedly has origin metadata\n");
      failed = 1;
    }
    sqlite3_finalize(stmt);
  }

  rc = sqlite3_close(db);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "close failed: %d\n", rc);
    failed = 1;
  }
  if( !failed ) puts("UTF-16 column metadata passed for table/view/scalar expressions");
  return failed;
}

/* end of column_metadata16_smoke.c */
