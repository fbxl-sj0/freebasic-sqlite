/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_unix_lockstyle_smoke.c

    Purpose:

        Exercise the optional Unix dot-file and flock VFS callbacks through
        SQLite's public C API.

    Responsibilities:

        - Create and query a small file-backed database.
        - Hold an exclusive transaction while a second connection requests a
          write lock.
        - Report whether both locking styles return SQLITE_BUSY as expected.

    This file intentionally does NOT contain:

        - SQLite engine implementations.
        - Changes to upstream Tcl or C test support.
*/

#include <sqlite3.h>
#include <stdio.h>

static int run_sql(sqlite3 *db, const char *sql){
  char *zError = 0;
  int rc = sqlite3_exec(db, sql, 0, 0, &zError);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "%s: %s (%d)\n", sql,
            zError ? zError : sqlite3_errmsg(db), rc);
  }
  sqlite3_free(zError);
  return rc;
}

int main(int argc, char **argv){
  sqlite3 *db1 = 0;
  sqlite3 *db2 = 0;
  sqlite3_stmt *pStmt = 0;
  int rc;
  int busyRc;
  int rowCount = -1;

  if( argc!=3 ){
    fprintf(stderr, "usage: %s DATABASE VFS\n", argv[0]);
    return 2;
  }

  rc = sqlite3_open_v2(argv[1], &db1,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, argv[2]);
  if( rc!=SQLITE_OK ) goto failed;
  if( run_sql(db1,
      "DROP TABLE IF EXISTS lockstyle_smoke;"
      "CREATE TABLE lockstyle_smoke(value INTEGER);"
      "INSERT INTO lockstyle_smoke VALUES(7);")!=SQLITE_OK ){
    rc = sqlite3_errcode(db1);
    goto failed;
  }
  if( run_sql(db1, "BEGIN EXCLUSIVE")!=SQLITE_OK ){
    rc = sqlite3_errcode(db1);
    goto failed;
  }

  rc = sqlite3_open_v2(argv[1], &db2,
      SQLITE_OPEN_READWRITE, argv[2]);
  if( rc!=SQLITE_OK ) goto failed;
  {
    char *zError = 0;
    busyRc = sqlite3_exec(db2, "BEGIN IMMEDIATE", 0, 0, &zError);
    sqlite3_free(zError);
  }
  if( (busyRc & 0xff)!=SQLITE_BUSY ){
    rc = busyRc==SQLITE_OK ? SQLITE_ERROR : busyRc;
    goto failed;
  }

  if( run_sql(db1, "ROLLBACK")!=SQLITE_OK ){
    rc = sqlite3_errcode(db1);
    goto failed;
  }
  rc = sqlite3_prepare_v2(db2,
      "SELECT count(*) FROM lockstyle_smoke", -1, &pStmt, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_step(pStmt);
  if( rc!=SQLITE_ROW ) goto failed;
  rowCount = sqlite3_column_int(pStmt, 0);
  rc = sqlite3_finalize(pStmt);
  pStmt = 0;
  if( rc!=SQLITE_OK || rowCount!=1 ){
    rc = rc==SQLITE_OK ? SQLITE_CORRUPT : rc;
    goto failed;
  }

  rc = sqlite3_close(db2);
  db2 = 0;
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_close(db1);
  db1 = 0;
  if( rc!=SQLITE_OK ) goto failed;

  printf("vfs=%s busy=%d rows=%d\n", argv[2], busyRc & 0xff, rowCount);
  return 0;

failed:
  if( pStmt ) sqlite3_finalize(pStmt);
  if( db2 ) sqlite3_close(db2);
  if( db1 ) sqlite3_close(db1);
  fprintf(stderr, "lock-style smoke failed: %s (%d)\n",
          sqlite3_errstr(rc), rc);
  return 1;
}

/* end of sqlite_unix_lockstyle_smoke.c */
