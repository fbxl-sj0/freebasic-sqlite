/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_windows_optional_api_smoke.c

    Purpose:

        Exercise compile-time optional SQLite APIs through the public C
        interface of a Windows DLL build.

    Responsibilities:

        - Check CARRAY binding, column metadata, normalized SQL, and scan status.
        - Check shared-cache unlock notification and lock reacquisition.
        - Return an exact process status without requiring CRT startup code.

    This file intentionally does NOT contain:

        - SQLite implementation code.
        - A port or modification of upstream test scripts.
*/

#define SQLITE_ENABLE_CARRAY 1
#define SQLITE_ENABLE_COLUMN_METADATA 1
#define SQLITE_ENABLE_NORMALIZE 1
#define SQLITE_ENABLE_STMT_SCANSTATUS 1
#define SQLITE_ENABLE_UNLOCK_NOTIFY 1

#include <sqlite3.h>

static int notificationCount;
static int notificationBadContext;
static int notificationContext;

static int executeSql(sqlite3 *db, const char *sql){
  return sqlite3_exec(db, sql, 0, 0, 0);
}

static int stringEquals(const char *left, const char *right){
  while( *left && *right && *left==*right ){
    left++;
    right++;
  }
  return *left==*right;
}

static void unlockNotify(void **arguments, int count){
  int i;
  for(i=0; i<count; i++){
    if( arguments[i]==&notificationContext ){
      notificationCount++;
    }else{
      notificationBadContext = 1;
    }
  }
}

static int testUnlockNotify(void){
  sqlite3 *blocker = 0;
  sqlite3 *blocked = 0;
  int rc;
  int result = 0;

  rc = sqlite3_enable_shared_cache(1);
  if( rc!=SQLITE_OK ) return 31;

  rc = sqlite3_open_v2(
      "sqlite_windows_optional_api_smoke.db",
      &blocker,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
      0
  );
  if( rc!=SQLITE_OK ){
    result = 32;
    goto cleanup;
  }

  rc = sqlite3_open_v2(
      "sqlite_windows_optional_api_smoke.db",
      &blocked,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
      0
  );
  if( rc!=SQLITE_OK ){
    result = 33;
    goto cleanup;
  }

  sqlite3_extended_result_codes(blocked, 1);
  rc = executeSql(blocker,
      "DROP TABLE IF EXISTS lock_test;"
      "CREATE TABLE lock_test(value);"
      "BEGIN;"
      "INSERT INTO lock_test VALUES(1);");
  if( rc!=SQLITE_OK ){
    result = 34;
    goto cleanup;
  }

  rc = executeSql(blocked, "INSERT INTO lock_test VALUES(2);");
  if( rc!=SQLITE_LOCKED_SHAREDCACHE ){
    result = 35;
    goto cleanup;
  }

  notificationCount = 0;
  notificationBadContext = 0;
  rc = sqlite3_unlock_notify(blocked, unlockNotify, &notificationContext);
  if( rc!=SQLITE_OK ){
    result = 36;
    goto cleanup;
  }

  rc = executeSql(blocker, "COMMIT;");
  if( rc!=SQLITE_OK ){
    result = 37;
    goto cleanup;
  }
  if( notificationCount!=1 || notificationBadContext ){
    result = 38;
    goto cleanup;
  }

  rc = executeSql(blocked, "INSERT INTO lock_test VALUES(2);");
  if( rc!=SQLITE_OK ) result = 39;

cleanup:
  if( blocked!=0 ) sqlite3_close(blocked);
  if( blocker!=0 ) sqlite3_close(blocker);
  sqlite3_enable_shared_cache(0);
  return result;
}

static int testCarray(sqlite3 *db){
  static int values[] = {3, 1, 2};
  sqlite3_stmt *stmt = 0;
  int rc;

  rc = sqlite3_prepare_v2(db, "SELECT sum(value) FROM carray(?1);", -1,
                          &stmt, 0);
  if( rc!=SQLITE_OK ) return 41;
  rc = sqlite3_carray_bind(stmt, 1, values, 3, SQLITE_CARRAY_INT32,
                           SQLITE_TRANSIENT);
  if( rc!=SQLITE_OK ){
    sqlite3_finalize(stmt);
    return 42;
  }
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_ROW || sqlite3_column_int(stmt, 0)!=6 ){
    sqlite3_finalize(stmt);
    return 43;
  }
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_DONE ){
    sqlite3_finalize(stmt);
    return 44;
  }
  rc = sqlite3_finalize(stmt);
  return rc==SQLITE_OK ? 0 : 45;
}

static int testColumnMetadataAndNormalize(sqlite3 *db){
  sqlite3_stmt *stmt = 0;
  const char *normalized;
  int rc;

  rc = executeSql(db,
      "CREATE TABLE t1(a, b);"
      "INSERT INTO t1 VALUES(1, 2);");
  if( rc!=SQLITE_OK ) return 51;

  rc = sqlite3_prepare_v2(db,
      "SELECT a, b FROM t1 WHERE b = ? ORDER BY a;", -1, &stmt, 0);
  if( rc!=SQLITE_OK ) return 52;
  if( !stringEquals(sqlite3_column_database_name(stmt, 0), "main")
   || !stringEquals(sqlite3_column_table_name(stmt, 0), "t1")
   || !stringEquals(sqlite3_column_origin_name(stmt, 0), "a") ){
    sqlite3_finalize(stmt);
    return 53;
  }

  normalized = sqlite3_normalized_sql(stmt);
  if( normalized==0
   || !stringEquals(normalized, "SELECT a,b FROM t1 WHERE b=?ORDER BY a;") ){
    sqlite3_finalize(stmt);
    return 54;
  }
  rc = sqlite3_finalize(stmt);
  return rc==SQLITE_OK ? 0 : 55;
}

static int testScanStatus(sqlite3 *db){
  sqlite3_stmt *stmt = 0;
  sqlite3_int64 loops = 0;
  int enabled = 0;
  int rc;

  rc = sqlite3_db_config(db, SQLITE_DBCONFIG_STMT_SCANSTATUS, 1, &enabled);
  if( rc!=SQLITE_OK || enabled!=1 ) return 61;

  rc = sqlite3_prepare_v2(db, "SELECT a FROM t1 WHERE a > 0;", -1, &stmt, 0);
  if( rc!=SQLITE_OK ) return 62;

  rc = sqlite3_db_config(db, SQLITE_DBCONFIG_STMT_SCANSTATUS, 1, &enabled);
  if( rc!=SQLITE_OK || enabled!=1 ){
    sqlite3_finalize(stmt);
    return 63;
  }

  while( (rc = sqlite3_step(stmt))==SQLITE_ROW ){}
  if( rc!=SQLITE_DONE ){
    sqlite3_finalize(stmt);
    return 64;
  }

  rc = sqlite3_stmt_scanstatus_v2(stmt, 0, SQLITE_SCANSTAT_NLOOP, 0, &loops);
  if( rc!=SQLITE_OK || loops<1 ){
    sqlite3_finalize(stmt);
    return 65;
  }
  rc = sqlite3_finalize(stmt);
  return rc==SQLITE_OK ? 0 : 66;
}

static int entry(void){
  sqlite3 *db = 0;
  int rc;

  rc = testUnlockNotify();
  if( rc!=0 ) return rc;

  rc = sqlite3_open_v2(
      ":memory:",
      &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
      0
  );
  if( rc!=SQLITE_OK ) return 70;

  rc = testCarray(db);
  if( rc==0 ) rc = testColumnMetadataAndNormalize(db);
  if( rc==0 ) rc = testScanStatus(db);
  if( sqlite3_close(db)!=SQLITE_OK && rc==0 ) rc = 71;
  return rc;
}

__declspec(dllimport) void __stdcall ExitProcess(unsigned int exitCode);

void start(void){
  ExitProcess((unsigned int)entry());
}

/* end of sqlite_windows_optional_api_smoke.c */
