/*
 * Project: SQLite FreeBASIC port
 * -----------------------------
 *
 * File: sqlite_file_diag_api_smoke.c
 *
 * Purpose:
 *
 *     Capture file and WAL diagnostics through SQLite's public C API.
 *
 * Responsibilities:
 *
 *     - Query sqlite_filestat() before and after switching to WAL mode.
 *     - Query sqlite_walstat() with and without an active WAL file.
 *     - Print stable JSON rows for comparison with the C test fixture.
 *
 * This file intentionally does NOT contain:
 *
 *     - VFS, pager, or diagnostic-function implementation code.
 *     - Changes to upstream test scripts.
 */

#include <stdio.h>
#include <sqlite3.h>

static int printDiagnostic(sqlite3 *db, const char *sql){
  sqlite3_stmt *stmt = 0;
  int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
  const unsigned char *value;
  if( rc!=SQLITE_OK ) return rc;
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_ROW ){
    sqlite3_finalize(stmt);
    return rc;
  }
  value = sqlite3_column_text(stmt, 0);
  if( value==0 ){
    puts("<NULL>");
  }else{
    puts((const char *)value);
  }
  rc = sqlite3_finalize(stmt);
  return rc;
}

int main(void){
  sqlite3 *db = 0;
  sqlite3 *peer = 0;
  int rc = sqlite3_open_v2("diag.db", &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, 0);
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db,
      "PRAGMA journal_mode=DELETE;"
      "DROP TABLE IF EXISTS t;"
      "PRAGMA page_size=1024;"
      "VACUUM;"
      "CREATE TABLE t(x);"
      "INSERT INTO t VALUES(1);", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = printDiagnostic(db, "SELECT sqlite_filestat('main')");
  if( rc!=SQLITE_OK ) goto failed;
  rc = printDiagnostic(db, "SELECT sqlite_walstat('main')");
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db,
      "PRAGMA journal_mode=WAL;"
      "INSERT INTO t VALUES(2);", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = printDiagnostic(db, "SELECT sqlite_filestat('main')");
  if( rc!=SQLITE_OK ) goto failed;
  rc = printDiagnostic(db, "SELECT sqlite_walstat('main')");
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_open_v2("diag.db", &peer,
      SQLITE_OPEN_READWRITE, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_exec(peer, "SELECT count(*) FROM t", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = printDiagnostic(peer, "SELECT sqlite_filestat('main')");
  if( rc!=SQLITE_OK ) goto failed;
  rc = printDiagnostic(peer, "SELECT sqlite_walstat('main')");
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_close(peer);
  peer = 0;
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  if( rc!=SQLITE_OK ) return 2;
  return 0;

failed:
  fprintf(stderr, "file diagnostics failed: %d: %s\n", rc,
      db ? sqlite3_errmsg(db) : "no database handle");
  if( peer ) sqlite3_close(peer);
  if( db ) sqlite3_close(db);
  return 1;
}

/* end of sqlite_file_diag_api_smoke.c */
