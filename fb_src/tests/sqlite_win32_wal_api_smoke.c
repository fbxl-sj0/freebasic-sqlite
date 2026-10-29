/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_win32_wal_api_smoke.c

    Purpose:

        Exercise the public SQLite C API against Windows DLL and Linux
        shared-library builds.

    Responsibilities:

        - Open a file-backed database through the Windows VFS.
        - Enable WAL mode and verify writer-lock contention across connections.
        - Commit a batch of rows and read the result through a second connection.
        - Complete a passive checkpoint.
        - Allow repeat runs on the same database and native Linux entrypoint.

    This file intentionally does NOT contain:

        - SQLite implementation code or changes to upstream test scripts.
        - A test of Windows structured exception delivery.
*/

#include <sqlite3.h>

int entry(void){
  sqlite3 *db = 0;
  sqlite3 *dbPeer = 0;
  sqlite3_stmt *pStmt = 0;
  const unsigned char *zMode;
  int rc;
  int peerRc;
  int i;
  int logFrames = -1;
  int checkpointedFrames = -1;

  rc = sqlite3_open_v2(
      "sqlite_win32_wal_smoke.db",
      &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db, "PRAGMA journal_mode=WAL", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_prepare_v2(db, "PRAGMA journal_mode", -1, &pStmt, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_step(pStmt);
  if( rc!=SQLITE_ROW ) goto failed;
  zMode = sqlite3_column_text(pStmt, 0);
  if( zMode==0 || zMode[0]!='w' || zMode[1]!='a' || zMode[2]!='l' ){
    rc = SQLITE_ERROR;
    goto failed;
  }
  rc = sqlite3_finalize(pStmt);
  pStmt = 0;
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db,
      "DROP TABLE IF EXISTS t;"
      "CREATE TABLE t(a INTEGER PRIMARY KEY, b INTEGER); BEGIN IMMEDIATE",
      0, 0, 0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_open_v2(
      "sqlite_win32_wal_smoke.db",
      &dbPeer,
      SQLITE_OPEN_READWRITE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;
  peerRc = sqlite3_exec(dbPeer, "BEGIN IMMEDIATE", 0, 0, 0);
  if( peerRc!=SQLITE_BUSY ){
    rc = SQLITE_CORRUPT;
    goto failed;
  }
  rc = sqlite3_close(dbPeer);
  dbPeer = 0;
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db, "ROLLBACK", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_open_v2(
      "sqlite_win32_wal_smoke.db",
      &dbPeer,
      SQLITE_OPEN_READWRITE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_exec(dbPeer, "BEGIN IMMEDIATE", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_exec(dbPeer, "ROLLBACK", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_close(dbPeer);
  dbPeer = 0;
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_exec(db, "BEGIN IMMEDIATE", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_prepare_v2(db, "INSERT INTO t VALUES(?1,?2)", -1, &pStmt, 0);
  if( rc!=SQLITE_OK ) goto failed;
  for(i=1; i<=100; i++){
    rc = sqlite3_bind_int(pStmt, 1, i);
    if( rc!=SQLITE_OK ) goto failed;
    rc = sqlite3_bind_int(pStmt, 2, i*3);
    if( rc!=SQLITE_OK ) goto failed;
    rc = sqlite3_step(pStmt);
    if( rc!=SQLITE_DONE ) goto failed;
    rc = sqlite3_reset(pStmt);
    if( rc!=SQLITE_OK ) goto failed;
  }
  rc = sqlite3_finalize(pStmt);
  pStmt = 0;
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_exec(db, "COMMIT", 0, 0, 0);
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_open_v2(
      "sqlite_win32_wal_smoke.db",
      &dbPeer,
      SQLITE_OPEN_READWRITE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_prepare_v2(dbPeer, "SELECT count(*),sum(b) FROM t", -1, &pStmt, 0);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_step(pStmt);
  if( rc!=SQLITE_ROW || sqlite3_column_int(pStmt, 0)!=100 ||
      sqlite3_column_int64(pStmt, 1)!=15150 ){
    rc = SQLITE_CORRUPT;
    goto failed;
  }
  rc = sqlite3_finalize(pStmt);
  pStmt = 0;
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_close(dbPeer);
  dbPeer = 0;
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_wal_checkpoint_v2(
      db, "main", SQLITE_CHECKPOINT_PASSIVE, &logFrames, &checkpointedFrames);
  if( rc!=SQLITE_OK || logFrames<0 || checkpointedFrames<0 ||
      checkpointedFrames>logFrames ){
    rc = SQLITE_CORRUPT;
    goto failed;
  }
  rc = sqlite3_close(db);
  db = 0;
  if( rc!=SQLITE_OK ) return 12;
  return 0;

failed:
  if( pStmt!=0 ) sqlite3_finalize(pStmt);
  if( dbPeer!=0 ) sqlite3_close(dbPeer);
  if( db!=0 ) sqlite3_close(db);
  return rc==SQLITE_OK ? 13 : rc;
}

/*
    The smoke executable omits the C runtime startup object, so its PE entry
    point must terminate the process explicitly instead of returning to the
    loader's initial stack frame.
*/
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

/* end of sqlite_win32_wal_api_smoke.c */
