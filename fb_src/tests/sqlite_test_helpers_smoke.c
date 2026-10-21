/*
    Project: SQLite FreeBASIC port
    -----------------------------

    File: sqlite_test_helpers_smoke.c

    Purpose:

        Call selected SQLITE_TEST helpers through the FreeBASIC library ABI.

    Responsibilities:

        - Run SQLite's UTF-8 encode/decode self-test.
        - Confirm sqlite3_initialize() has populated the built-in function table.
        - Configure and initialize the optional memsys5 allocator.
        - Check the page-cache statistics outputs and allocator dump.
        - Confirm the os.c initialization allocation probe reports OOM.

    This file intentionally does NOT contain:

        - Ported upstream Tcl test scripts or SQLite engine implementation.
        - A general test runner or a substitute for SQLite's unchanged suites.
*/

#include "../../sqlite3.h"
#include <stdio.h>

extern void sqlite3UtfSelfTest(void);
extern void *sqlite3FunctionSearch(int, const char *);
extern void sqlite3PcacheStats(int *, int *, int *, int *);
extern void sqlite3Memsys5Dump(const char *);

union TestHeap {
  sqlite3_int64 align;
  unsigned char bytes[2 * 1024 * 1024];
};

union SmallTestHeap {
  sqlite3_int64 align;
  /* Two 32-byte allocator blocks: one fits the pthread init mutex, leaving
  ** no block for sqlite3OsInit()'s 10-byte OOM probe. */
  unsigned char bytes[96];
};

int main(void){
  union TestHeap heap;
  int rc;
  int functionHash;
  int nCurrent = -1;
  int nMaximum = -1;
  int nMinimum = -1;
  int nRecyclable = -1;
  union SmallTestHeap smallHeap;

  sqlite3UtfSelfTest();

  rc = sqlite3_config(SQLITE_CONFIG_HEAP, heap.bytes,
                      (int)sizeof(heap.bytes), 32);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "SQLITE_CONFIG_HEAP failed: %d\n", rc);
    return 1;
  }
  rc = sqlite3_initialize();
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "sqlite3_initialize failed: %d\n", rc);
    return 2;
  }

  /* SQLite's built-in-function hash is (first byte + name length) % 23. */
  functionHash = ((unsigned char)'l' + 6) % 23;
  if( sqlite3FunctionSearch(functionHash, "length")==0 ){
    fprintf(stderr, "sqlite3_initialize did not register built-in length()\n");
    sqlite3_shutdown();
    return 3;
  }

  sqlite3PcacheStats(&nCurrent, &nMaximum, &nMinimum, &nRecyclable);
  if( nCurrent<0 || nMaximum<0 || nMinimum<0 || nRecyclable<0 ){
    fprintf(stderr, "invalid page-cache statistics: %d %d %d %d\n",
            nCurrent, nMaximum, nMinimum, nRecyclable);
    sqlite3_shutdown();
    return 4;
  }

  sqlite3Memsys5Dump(0);
  rc = sqlite3_shutdown();
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "sqlite3_shutdown failed: %d\n", rc);
    return 5;
  }

  rc = sqlite3_config(SQLITE_CONFIG_HEAP, smallHeap.bytes,
                      (int)sizeof(smallHeap.bytes), 32);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "small SQLITE_CONFIG_HEAP failed: %d\n", rc);
    return 6;
  }
  rc = sqlite3_initialize();
  if( rc!=SQLITE_NOMEM ){
    fprintf(stderr, "96-byte heap expected SQLITE_NOMEM, got %d\n", rc);
    sqlite3_shutdown();
    return 7;
  }
  sqlite3_shutdown();

  fprintf(stderr, "SQLITE_TEST helper smoke passed: pcache %d/%d/%d/%d\n",
          nCurrent, nMaximum, nMinimum, nRecyclable);
  return 0;
}

/* end of sqlite_test_helpers_smoke.c */
