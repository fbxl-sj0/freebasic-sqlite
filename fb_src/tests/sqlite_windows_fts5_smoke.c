/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_windows_fts5_smoke.c

    Purpose:

        Exercise the FTS5 module through SQLite's public C API on Windows DLL
        and Linux shared-library builds.

    Responsibilities:

        - Create and persist an FTS5 virtual table.
        - Verify boolean, phrase, and prefix MATCH queries after reopen.
        - Use a direct Windows entrypoint or the native C runtime entrypoint.

    This file intentionally does NOT contain:

        - FTS5 or SQLite implementation code.
        - A port or modification of upstream test scripts.
*/

#include <sqlite3.h>

static int expectRowids(
    sqlite3 *db,
    const char *sql,
    const sqlite3_int64 *expected,
    int expectedCount
){
  sqlite3_stmt *stmt = 0;
  int rc;
  int i;

  rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
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
  static const sqlite3_int64 booleanRows[] = {3};
  static const sqlite3_int64 phraseRows[] = {1};
  static const sqlite3_int64 prefixRows[] = {2, 3};
  sqlite3 *db = 0;
  int rc;

  rc = sqlite3_open_v2(
      "sqlite_windows_fts5_smoke.db",
      &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db,
      "DROP TABLE IF EXISTS docs;"
      "CREATE VIRTUAL TABLE docs USING fts5(title, body);"
      "INSERT INTO docs(rowid,title,body) VALUES"
      "(1,'canoe','blue boat by lake'),"
      "(2,'bicycle','red bicycle on road'),"
      "(3,'bike','green bicycle and boat');",
      0, 0, 0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  db = 0;
  if( rc!=SQLITE_OK ) return rc;

  rc = sqlite3_open_v2(
      "sqlite_windows_fts5_smoke.db",
      &db,
      SQLITE_OPEN_READWRITE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = expectRowids(db,
      "SELECT rowid FROM docs WHERE docs MATCH 'bicycle AND boat' ORDER BY rowid",
      booleanRows, 1);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectRowids(db,
      "SELECT rowid FROM docs WHERE docs MATCH '\"blue boat\"' ORDER BY rowid",
      phraseRows, 1);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectRowids(db,
      "SELECT rowid FROM docs WHERE docs MATCH 'bicy*' ORDER BY rowid",
      prefixRows, 2);
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  db = 0;
  return rc;

failed:
  if( db!=0 ) sqlite3_close(db);
  return rc==SQLITE_OK ? SQLITE_ERROR : rc;
}

#ifdef _WIN32
__declspec(dllimport) void __stdcall ExitProcess(unsigned int exitCode);

void start(void){
  ExitProcess((unsigned int)entry());
}
#else
int main(void){
  return entry();
}
#endif

/* end of sqlite_windows_fts5_smoke.c */
