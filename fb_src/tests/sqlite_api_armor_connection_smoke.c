/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_api_armor_connection_smoke.c

    Purpose:

        Check the API Armor behavior of connection accessors on both
        an open connection and a zombie connection.

    Responsibilities:

        - Verify normal connection accessor results.
        - Keep a statement alive while sqlite3_close_v2() makes its
          connection a zombie.
        - Verify API Armor return values and no-op behavior for that
          zombie connection.

    This file intentionally does NOT contain:

        - SQLite implementation code or changes to upstream tests.
        - Calls through private SQLite structures.
*/

#include <sqlite3.h>
#include <stdio.h>
#include <string.h>

static int fail(const char *zOperation, int rc){
  fprintf(stderr, "%s failed: %d (%s)\n", zOperation, rc, sqlite3_errstr(rc));
  return 1;
}

static int failOpen(
    const char *zOperation,
    int rc,
    sqlite3 *db,
    sqlite3_stmt *pStmt
){
  if( pStmt!=0 ) sqlite3_finalize(pStmt);
  if( db!=0 ) sqlite3_close_v2(db);
  return fail(zOperation, rc);
}

static int failZombie(
    const char *zOperation,
    int rc,
    sqlite3_stmt *pStmt
){
  if( pStmt!=0 ) sqlite3_finalize(pStmt);
  return fail(zOperation, rc);
}

static void countDestructor(void *pData){
  ++*(int *)pData;
}

int main(void){
  sqlite3 *db = 0;
  sqlite3_stmt *pStmt = 0;
  sqlite3_blob *pBlob = 0;
  unsigned char *pSerialized = 0;
  sqlite3_int64 serializedBytes = 0;
  const char *zName;
  int rc;
  int destructorCalls = 0;

  rc = sqlite3_open(":memory:", &db);
  if( rc!=SQLITE_OK ) return failOpen("sqlite3_open", rc, db, pStmt);

  zName = sqlite3_db_name(db, 0);
  if( zName==0 || strcmp(zName, "main")!=0 ){
    return failOpen("sqlite3_db_name on open connection", SQLITE_ERROR, db, pStmt);
  }
  if( sqlite3_db_readonly(db, "main")!=0 ){
    return failOpen("sqlite3_db_readonly on open connection", SQLITE_ERROR, db, pStmt);
  }
  rc = sqlite3_enable_load_extension(db, 1);
  if( rc!=SQLITE_OK ){
    return failOpen("sqlite3_enable_load_extension on open connection", rc, db, pStmt);
  }
  rc = sqlite3_enable_load_extension(db, 0);
  if( rc!=SQLITE_OK ){
    return failOpen("sqlite3_disable_load_extension on open connection", rc, db, pStmt);
  }
  if( sqlite3_deserialize(db, "main", 0, -1, -1, 0)!=SQLITE_MISUSE ){
    return failOpen("sqlite3_deserialize API Armor size guard", SQLITE_ERROR, db, pStmt);
  }
  if( sqlite3_db_filename(db, "main")==0 ){
    return failOpen("sqlite3_db_filename on open connection", SQLITE_ERROR, db, pStmt);
  }
  if( sqlite3_set_clientdata(db, "armor", 0, 0)!=SQLITE_OK ||
      sqlite3_get_clientdata(db, "armor")!=0 ){
    return failOpen("clientdata APIs on open connection", SQLITE_ERROR, db, pStmt);
  }
  if( sqlite3_last_insert_rowid(db)!=0 || sqlite3_changes64(db)!=0 ||
      sqlite3_total_changes64(db)!=0 ){
    return failOpen("change counters on open connection", SQLITE_ERROR, db, pStmt);
  }

  rc = sqlite3_prepare_v2(db, "SELECT 1", -1, &pStmt, 0);
  if( rc!=SQLITE_OK ) return failOpen("sqlite3_prepare_v2", rc, db, pStmt);
  if( sqlite3_next_stmt(db, 0)!=pStmt ){
    return failOpen("sqlite3_next_stmt on open connection", SQLITE_ERROR, db, pStmt);
  }
  rc = sqlite3_close_v2(db);
  if( rc!=SQLITE_OK ) return failOpen("sqlite3_close_v2", rc, db, pStmt);

  sqlite3_interrupt(db);
  if( sqlite3_is_interrupted(db)!=1 ){
    return failZombie("sqlite3_interrupt on zombie connection", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_busy_handler(db, 0, 0)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_busy_handler API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_busy_timeout(db, 1)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_busy_timeout API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_db_mutex(db)!=0 ){
    return failZombie("sqlite3_db_mutex API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_db_name(db, 0)!=0 ){
    return failZombie("sqlite3_db_name API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_db_filename(db, "main")!=0 ){
    return failZombie("sqlite3_db_filename API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_db_readonly(db, "main")!=-1 ){
    return failZombie("sqlite3_db_readonly API Armor", SQLITE_ERROR, pStmt);
  }
  serializedBytes = 99;
  pSerialized = sqlite3_serialize(db, "main", &serializedBytes, 0);
  if( pSerialized!=0 || serializedBytes!=99 ){
    return failZombie("sqlite3_serialize API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_deserialize(db, "main", 0, -1, -1, 0)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_deserialize API Armor", SQLITE_ERROR, pStmt);
  }
  rc = sqlite3_blob_open(db, "main", "t", "c", 1, 0, &pBlob);
  if( rc!=SQLITE_MISUSE || pBlob!=0 ){
    return failZombie("sqlite3_blob_open API Armor", rc, pStmt);
  }
  if( sqlite3_enable_load_extension(db, 1)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_enable_load_extension API Armor", SQLITE_ERROR, pStmt);
  }
  rc = sqlite3_table_column_metadata(
      db, "main", "t", "c", 0, 0, 0, 0, 0);
  if( rc!=SQLITE_MISUSE ){
    return failZombie("sqlite3_table_column_metadata API Armor", rc, pStmt);
  }
  rc = sqlite3_create_module(db, "armor", 0, 0);
  if( rc!=SQLITE_MISUSE ){
    return failZombie("sqlite3_create_module API Armor", rc, pStmt);
  }
  rc = sqlite3_create_module_v2(db, "armor", 0, 0, 0);
  if( rc!=SQLITE_MISUSE ){
    return failZombie("sqlite3_create_module_v2 API Armor", rc, pStmt);
  }
  rc = sqlite3_declare_vtab(db, "CREATE TABLE x(a)");
  if( rc!=SQLITE_MISUSE ){
    return failZombie("sqlite3_declare_vtab API Armor", rc, pStmt);
  }
  rc = sqlite3_drop_modules(db, 0);
  if( rc!=SQLITE_MISUSE ){
    return failZombie("sqlite3_drop_modules API Armor", rc, pStmt);
  }
  if( sqlite3_vtab_on_conflict(db)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_vtab_on_conflict API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_get_clientdata(db, "armor")!=0 ){
    return failZombie("sqlite3_get_clientdata API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_set_clientdata(db, "armor", 0, 0)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_set_clientdata API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_next_stmt(db, 0)!=0 ){
    return failZombie("sqlite3_next_stmt API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_set_authorizer(db, 0, 0)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_set_authorizer API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_overload_function(db, "armor", 0)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_overload_function API Armor", SQLITE_ERROR, pStmt);
  }
  rc = sqlite3_autovacuum_pages(db, 0, &destructorCalls, countDestructor);
  if( rc!=SQLITE_MISUSE || destructorCalls!=1 ){
    return failZombie("sqlite3_autovacuum_pages API Armor", rc, pStmt);
  }
  if( sqlite3_wal_autocheckpoint(db, 1000)!=SQLITE_MISUSE ){
    return failZombie("sqlite3_wal_autocheckpoint API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_wal_hook(db, 0, 0)!=0 ){
    return failZombie("sqlite3_wal_hook API Armor", SQLITE_ERROR, pStmt);
  }
  if( sqlite3_last_insert_rowid(db)!=0 || sqlite3_changes64(db)!=0 ||
      sqlite3_total_changes64(db)!=0 ){
    return failZombie("change counters API Armor", SQLITE_ERROR, pStmt);
  }
  sqlite3_set_last_insert_rowid(db, 7);
  rc = sqlite3_file_control(db, "main", SQLITE_FCNTL_LOCKSTATE, 0);
  if( rc!=SQLITE_MISUSE ){
    return failZombie("sqlite3_file_control API Armor", rc, pStmt);
  }

  rc = sqlite3_finalize(pStmt);
  if( rc!=SQLITE_OK ) return fail("sqlite3_finalize zombie statement", rc);
  return 0;
}

/* end of sqlite_api_armor_connection_smoke.c */
