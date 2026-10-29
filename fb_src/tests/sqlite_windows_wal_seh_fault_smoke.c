/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_windows_wal_seh_fault_smoke.c

    Purpose:

        Exercise the FreeBASIC WAL exception path through SQLite's public
        test-control and database APIs on Win32 and Win64.

    Responsibilities:

        - Inject the upstream WAL shared-memory page-fault point once.
        - Verify the exception becomes SQLITE_IOERR_IN_PAGE.
        - Retry a read to verify WAL locks and connection state recover.

    This file intentionally does NOT contain:

        - SQLite implementation code or changes to upstream test scripts.
        - A substitute for the upstream Windows Tcl fault suite.
*/

#include <sqlite3.h>

static int faultSeen;

static int injectWalPageFault(int testCode){
  if( testCode==650 && faultSeen==0 ){
    faultSeen = 1;
    return (int)0xC0000185u;
  }
  return 0;
}

static int reportFailure(int step, int rc){
  return ((step & 0x0f) << 4) | (rc & 0x0f);
}

static int entry(void){
  const char *zFilename = "sqlite_win32_wal_seh_fault.db";
  sqlite3 *db = 0;
  sqlite3 *dbReader = 0;
  sqlite3_stmt *pStmt = 0;
  int rc;
  int queryRc;
  int result = 0;

  rc = sqlite3_open_v2(zFilename, &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, 0);
  if( rc!=SQLITE_OK ){
    result = reportFailure(1, rc);
    goto cleanup;
  }

  rc = sqlite3_exec(db,
      "PRAGMA journal_mode=WAL;"
      "DROP TABLE IF EXISTS t;"
      "CREATE TABLE t(x INTEGER);"
      "INSERT INTO t VALUES(1),(2);",
      0, 0, 0);
  if( rc!=SQLITE_OK ){
    result = reportFailure(2, rc);
    goto cleanup;
  }

  rc = sqlite3_open_v2(zFilename, &dbReader, SQLITE_OPEN_READWRITE, 0);
  if( rc!=SQLITE_OK ){
    result = reportFailure(3, rc);
    goto cleanup;
  }
  sqlite3_extended_result_codes(dbReader, 1);

  rc = sqlite3_test_control(SQLITE_TESTCTRL_FAULT_INSTALL, injectWalPageFault);
  if( rc!=SQLITE_OK ){
    result = reportFailure(4, rc);
    goto cleanup;
  }

  rc = sqlite3_prepare_v2(dbReader, "SELECT sum(x) FROM t", -1, &pStmt, 0);
  queryRc = rc;
  if( rc==SQLITE_OK ) queryRc = sqlite3_step(pStmt);
  if( pStmt!=0 ){
    int finalRc = sqlite3_finalize(pStmt);
    pStmt = 0;
    if( queryRc==SQLITE_OK && finalRc!=SQLITE_OK ) queryRc = finalRc;
  }

  sqlite3_test_control(SQLITE_TESTCTRL_FAULT_INSTALL, (int (*)(int))0);
  if( faultSeen!=1 ){
    result = reportFailure(5, queryRc);
    goto cleanup;
  }
  if( (queryRc & 0xff)!=SQLITE_IOERR ||
      sqlite3_extended_errcode(dbReader)!=SQLITE_IOERR_IN_PAGE ){
    result = reportFailure(6, queryRc);
    goto cleanup;
  }

  rc = sqlite3_prepare_v2(dbReader, "SELECT sum(x) FROM t", -1, &pStmt, 0);
  if( rc!=SQLITE_OK ){
    result = reportFailure(7, rc);
    goto cleanup;
  }
  rc = sqlite3_step(pStmt);
  if( rc!=SQLITE_ROW || sqlite3_column_int(pStmt, 0)!=3 ){
    result = reportFailure(8, rc);
    goto cleanup;
  }
  rc = sqlite3_finalize(pStmt);
  pStmt = 0;
  if( rc!=SQLITE_OK ){
    result = reportFailure(9, rc);
    goto cleanup;
  }

cleanup:
  sqlite3_test_control(SQLITE_TESTCTRL_FAULT_INSTALL, (int (*)(int))0);
  if( pStmt!=0 ) sqlite3_finalize(pStmt);
  if( dbReader!=0 && sqlite3_close(dbReader)!=SQLITE_OK ) result = 10;
  if( db!=0 && sqlite3_close(db)!=SQLITE_OK ) result = 11;
  return result;
}

#ifdef _WIN32
__declspec(dllimport) void __stdcall ExitProcess(unsigned int exitCode);

void start(void){
  ExitProcess((unsigned int)entry());
}
#endif

int main(void){
  return entry();
}

/* end of sqlite_windows_wal_seh_fault_smoke.c */
