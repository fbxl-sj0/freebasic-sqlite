/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_windows_without_rowid_smoke.c

    Purpose:

        Exercise composite-key WITHOUT ROWID tables through the Windows
        SQLite C API and file VFS.

    Responsibilities:

        - Create, populate, update, close, and reopen WITHOUT ROWID tables.
        - Check composite primary-key lookup, secondary-index lookup, and
          foreign-key enforcement.
        - Run VACUUM and PRAGMA integrity_check on the persisted database.
        - Return an exact process status without requiring CRT startup code.

    This file intentionally does NOT contain:

        - SQLite implementation code.
        - A port or modification of upstream test scripts.
*/

#include <sqlite3.h>

static int executeSql(sqlite3 *db, const char *sql){
  return sqlite3_exec(db, sql, 0, 0, 0);
}

static int textEquals(const unsigned char *actual, const char *expected){
  int i = 0;
  if( actual==0 ) return 0;
  while( actual[i] && expected[i] && actual[i]==(unsigned char)expected[i] ){
    i++;
  }
  return actual[i]==0 && expected[i]==0;
}

static int expectInteger(sqlite3 *db, const char *sql, sqlite3_int64 expected){
  sqlite3_stmt *stmt = 0;
  int rc;

  rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
  if( rc!=SQLITE_OK ) return rc;
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_ROW || sqlite3_column_int64(stmt, 0)!=expected ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_DONE ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  return sqlite3_finalize(stmt);
}

static int expectText(sqlite3 *db, const char *sql, const char *expected){
  sqlite3_stmt *stmt = 0;
  int rc;

  rc = sqlite3_prepare_v2(db, sql, -1, &stmt, 0);
  if( rc!=SQLITE_OK ) return rc;
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_ROW || !textEquals(sqlite3_column_text(stmt, 0), expected) ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_DONE ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  return sqlite3_finalize(stmt);
}

static int entry(void){
  static const char *databasePath = "sqlite_windows_without_rowid_smoke.db";
  sqlite3 *db = 0;
  int rc;

  rc = sqlite3_open_v2(databasePath, &db,
                       SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_extended_result_codes(db, 1);
  if( rc!=SQLITE_OK ) goto failed;

  rc = executeSql(db,
      "PRAGMA foreign_keys=ON;"
      "DROP TABLE IF EXISTS child;"
      "DROP TABLE IF EXISTS parent;"
      "CREATE TABLE parent("
        "key_text TEXT NOT NULL,"
        "key_number INTEGER NOT NULL,"
        "value TEXT NOT NULL,"
        "PRIMARY KEY(key_text,key_number)"
      ") WITHOUT ROWID;"
      "CREATE TABLE child("
        "key_text TEXT NOT NULL,"
        "key_number INTEGER NOT NULL,"
        "payload TEXT NOT NULL,"
        "PRIMARY KEY(key_text,key_number,payload),"
        "FOREIGN KEY(key_text,key_number)"
          " REFERENCES parent(key_text,key_number)"
      ") WITHOUT ROWID;"
      "CREATE INDEX child_payload_idx ON child(payload);"
      "INSERT INTO parent VALUES"
        "('alpha',1,'one'),('alpha',2,'two'),('beta',1,'three');"
      "INSERT INTO child VALUES('alpha',1,'child-one');");
  if( rc!=SQLITE_OK ) goto failed;

  rc = executeSql(db, "INSERT INTO child VALUES('missing',9,'bad');");
  if( rc!=SQLITE_CONSTRAINT_FOREIGNKEY ){
    rc = SQLITE_CORRUPT;
    goto failed;
  }

  rc = executeSql(db,
      "UPDATE parent SET value='revised'"
      " WHERE key_text='alpha' AND key_number=2;");
  if( rc!=SQLITE_OK || sqlite3_changes(db)!=1 ){
    rc = SQLITE_CORRUPT;
    goto failed;
  }
  rc = expectInteger(db, "SELECT count(*) FROM parent;", 3);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectInteger(db, "SELECT sum(key_number) FROM parent;", 4);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectInteger(db,
      "SELECT count(*) FROM child WHERE payload='child-one';", 1);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectText(db,
      "SELECT value FROM parent WHERE key_text='alpha' AND key_number=2;",
      "revised");
  if( rc!=SQLITE_OK ) goto failed;

  rc = executeSql(db, "VACUUM;");
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectText(db, "PRAGMA integrity_check;", "ok");
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  db = 0;
  if( rc!=SQLITE_OK ) return 11;

  rc = sqlite3_open_v2(databasePath, &db, SQLITE_OPEN_READWRITE, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectInteger(db, "SELECT count(*) FROM parent;", 3);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectInteger(db, "SELECT count(*) FROM child;", 1);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectText(db, "PRAGMA integrity_check;", "ok");
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  db = 0;
  return rc==SQLITE_OK ? 0 : 12;

failed:
  if( db!=0 ) sqlite3_close(db);
  return rc==SQLITE_OK ? 13 : rc;
}

__declspec(dllimport) void __stdcall ExitProcess(unsigned int exitCode);

void start(void){
  ExitProcess((unsigned int)entry());
}

/* end of sqlite_windows_without_rowid_smoke.c */
