/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_windows_fts3_fts4_smoke.c

    Purpose:

        Exercise FTS3 and FTS4 indexes through SQLite's public C API on a
        Windows DLL build.

    Responsibilities:

        - Create FTS3 and FTS4 tables in a file-backed database.
        - Reopen the database and verify term and phrase MATCH results.
        - Return an exact process status without requiring CRT startup code.

    This file intentionally does NOT contain:

        - Full-text search implementation code.
        - A port or modification of upstream Tcl/C tests.
*/

#include <sqlite3.h>

static int expectDocids(
    sqlite3 *db,
    const char *sql,
    const sqlite3_int64 *expected,
    int expectedCount
){
  sqlite3_stmt *stmt = 0;
  int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
  int i;

  if( rc!=SQLITE_OK ) return rc;
  for(i=0; i<expectedCount; i++){
    rc = sqlite3_step(stmt);
    if( rc!=SQLITE_ROW || sqlite3_column_int64(stmt, 0)!=expected[i] ){
      sqlite3_finalize(stmt);
      return SQLITE_CORRUPT;
    }
  }
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_DONE ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  return sqlite3_finalize(stmt);
}

static int entry(void){
  static const sqlite3_int64 expected[] = {2, 3};
  sqlite3 *db = 0;
  int rc = sqlite3_open_v2(
      "sqlite_windows_fts3_fts4_smoke.db",
      &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db,
      "DROP TABLE IF EXISTS f3;"
      "DROP TABLE IF EXISTS f4;"
      "CREATE VIRTUAL TABLE f3 USING fts3(body);"
      "CREATE VIRTUAL TABLE f4 USING fts4(body);"
      "INSERT INTO f3(rowid,body) VALUES"
      "(1,'freebasic compiler'),(2,'sqlite engine'),"
      "(3,'freebasic sqlite engine');"
      "INSERT INTO f4(rowid,body) VALUES"
      "(1,'freebasic compiler'),(2,'sqlite engine'),"
      "(3,'freebasic sqlite engine');",
      0, 0, 0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  db = 0;
  if( rc!=SQLITE_OK ) return rc;

  rc = sqlite3_open_v2(
      "sqlite_windows_fts3_fts4_smoke.db",
      &db,
      SQLITE_OPEN_READWRITE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = expectDocids(db,
      "SELECT docid FROM f3 WHERE f3 MATCH 'sqlite' ORDER BY docid",
      expected, 2);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectDocids(db,
      "SELECT docid FROM f4 WHERE f4 MATCH '\"sqlite engine\"' ORDER BY docid",
      expected, 2);
  if( rc!=SQLITE_OK ) goto failed;

  return sqlite3_close(db);

failed:
  if( db!=0 ) sqlite3_close(db);
  return rc==SQLITE_OK ? SQLITE_ERROR : rc;
}

__declspec(dllimport) void __stdcall ExitProcess(unsigned int exitCode);

void start(void){
  ExitProcess((unsigned int)entry());
}

/* end of sqlite_windows_fts3_fts4_smoke.c */
