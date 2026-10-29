/*
 * Project: SQLite FreeBASIC port
 * -----------------------------
 *
 * File: sqlite_omit_wal_api_smoke.c
 *
 * Purpose:
 *
 *     Check ordinary SQL behavior and journal-mode reporting without WAL.
 *
 * Responsibilities:
 *
 *     - Create, write, and query a file-backed database.
 *     - Confirm a WAL request leaves the database in DELETE journal mode.
 *
 * This file intentionally does NOT contain:
 *
 *     - SQLite implementation code.
 *     - Changes to upstream test scripts.
 */

#include <stdio.h>
#include <string.h>
#include <sqlite3.h>

int main(void){
  sqlite3 *db = 0;
  sqlite3_stmt *stmt = 0;
  int logFrames = -1;
  int checkpointedFrames = -1;
  const unsigned char *mode;
  int rc = sqlite3_open_v2("omit-wal.db", &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, 0);
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db,
      "DROP TABLE IF EXISTS t;"
      "CREATE TABLE t(x INTEGER);"
      "INSERT INTO t VALUES(2),(3);",
      0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_prepare_v2(db, "PRAGMA journal_mode=WAL", -1, &stmt, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_ROW ) goto failed;
  mode = sqlite3_column_text(stmt, 0);
  if( mode==0 || strcmp((const char *)mode, "delete")!=0 ){
    rc = SQLITE_ERROR;
    goto failed;
  }
  fprintf(stderr, "journal mode: %s\n", mode);
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_DONE ) goto failed;
  rc = sqlite3_finalize(stmt);
  stmt = 0;
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_prepare_v2(db, "SELECT count(*),sum(x) FROM t", -1, &stmt, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_ROW || sqlite3_column_int(stmt, 0)!=2 ||
      sqlite3_column_int(stmt, 1)!=5 ){
    rc = SQLITE_CORRUPT;
    goto failed;
  }
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_DONE ) goto failed;
  rc = sqlite3_finalize(stmt);
  stmt = 0;
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_wal_checkpoint_v2(db, "main", SQLITE_CHECKPOINT_PASSIVE,
      &logFrames, &checkpointedFrames);
  if( rc!=SQLITE_OK || logFrames!=-1 || checkpointedFrames!=-1 ){
    rc = SQLITE_ERROR;
    goto failed;
  }

  rc = sqlite3_close(db);
  if( rc!=SQLITE_OK ) return 2;
  puts("PASS");
  return 0;

failed:
  fprintf(stderr, "omit-WAL smoke failed: %d: %s\n", rc,
      db ? sqlite3_errmsg(db) : "no database handle");
  if( stmt ) sqlite3_finalize(stmt);
  if( db ) sqlite3_close(db);
  return 1;
}

/* end of sqlite_omit_wal_api_smoke.c */
