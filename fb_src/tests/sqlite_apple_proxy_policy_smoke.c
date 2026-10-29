/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_apple_proxy_policy_smoke.c

    Purpose:

        Exercise the Apple proxy-selection callback through SQLite's public
        C API when a test shim supplies Darwin's statfs record on Linux.

    Responsibilities:

        - Open a database with SQLITE_OPEN_AUTOPROXY.
        - Check whether the VFS selected proxy locking as requested.
        - Verify a second writer is blocked when proxy locking is active.
        - Confirm the simulated FAT path writes the initial 'S' inode byte.

    This file intentionally does NOT contain:

        - SQLite engine implementations.
        - Upstream test changes or a substitute for native Apple testing.
*/

#include <sqlite3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int sqlite3_apple_proxy_fake_fat_seed_seen(void);

static int execute_sql(sqlite3 *db, const char *sql){
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
  char *zProxyPath = 0;
  int expectedProxy;
  int isProxy;
  int fatSeedSeen = 0;
  int rc;
  int busyRc = SQLITE_OK;

  if( argc!=3 ){
    fprintf(stderr, "usage: %s DATABASE EXPECT_PROXY\n", argv[0]);
    return 2;
  }
  expectedProxy = atoi(argv[2])!=0;
  rc = sqlite3_open_v2(argv[1], &db1,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_AUTOPROXY,
      "unix");
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_file_control(
      db1, "main", SQLITE_FCNTL_GET_LOCKPROXYFILE, &zProxyPath);
  if( rc==SQLITE_NOTFOUND && !expectedProxy ) rc = SQLITE_OK;
  if( rc!=SQLITE_OK ) goto failed;
  isProxy = zProxyPath!=0 && strncmp(zProxyPath, ":auto:", 6)!=0;
  if( isProxy!=expectedProxy ){
    fprintf(stderr, "proxy selection mismatch: expected %d, got %d\n",
            expectedProxy, isProxy);
    rc = SQLITE_ERROR;
    goto failed;
  }

  if( execute_sql(db1,
      "DROP TABLE IF EXISTS proxy_smoke;"
      "CREATE TABLE proxy_smoke(value INTEGER);"
      "INSERT INTO proxy_smoke VALUES(7);")!=SQLITE_OK ){
    rc = sqlite3_errcode(db1);
    goto failed;
  }

  {
    const char *zFsType = getenv("SQLITE3_FB_FAKE_FSTYPE");
    if( zFsType && strcmp(zFsType, "msdos")==0 ){
      fatSeedSeen = sqlite3_apple_proxy_fake_fat_seed_seen();
      if( !fatSeedSeen ){
        fprintf(stderr, "empty FAT database did not receive the seed byte\n");
        rc = SQLITE_CORRUPT;
        goto failed;
      }
    }
  }

  if( isProxy ){
    if( execute_sql(db1, "BEGIN EXCLUSIVE")!=SQLITE_OK ){
      rc = sqlite3_errcode(db1);
      goto failed;
    }
    rc = sqlite3_open_v2(argv[1], &db2,
        SQLITE_OPEN_READWRITE | SQLITE_OPEN_AUTOPROXY, "unix");
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
    if( execute_sql(db1, "ROLLBACK")!=SQLITE_OK ){
      rc = sqlite3_errcode(db1);
      goto failed;
    }
    rc = sqlite3_close(db2);
    db2 = 0;
    if( rc!=SQLITE_OK ) goto failed;
  }

  rc = sqlite3_close(db1);
  db1 = 0;
  if( rc!=SQLITE_OK ) goto failed;
  printf("proxy=%d busy=%d", isProxy, busyRc & 0xff);
  if( fatSeedSeen ) printf(" fat_seed=%d", fatSeedSeen);
  printf("\n");
  return 0;

failed:
  if( db2 ) sqlite3_close(db2);
  if( db1 ) sqlite3_close(db1);
  fprintf(stderr, "Apple proxy policy smoke failed: %s (%d)\n",
          sqlite3_errstr(rc), rc);
  return 1;
}

/* end of sqlite_apple_proxy_policy_smoke.c */
