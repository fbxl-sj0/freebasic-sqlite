/*
    Project: SQLite FreeBASIC port
    -----------------------------

    File: sqlite_testfixture_config_sync.c

    Purpose:

        Mirror configuration fields read directly by upstream C test support.

    Responsibilities:

        - Copy mutex, allocator, shared-cache, page-cache, and lookaside state
          from the FreeBASIC engine into the fixture's sqlite3Config record.
        - Keep the upstream Tcl test-support C files unchanged.

    This file intentionally does NOT contain:

        - SQLite configuration storage or configuration command handling.
        - SQLite engine implementation or translated test cases.
*/

#include "../../src/sqliteInt.h"

extern int sqlite3ConfigCoreMutexEnabled(void);
extern int sqlite3ConfigFullMutexEnabled(void);
extern int sqlite3ConfigMemStatusEnabled(void);
extern int sqlite3ConfigSharedCacheEnabled(void);
extern void sqlite3ConfigGetHeap(void **, int *, int *);
extern void sqlite3ConfigGetPageCacheSettings(void **, int *, int *);
extern void sqlite3ConfigGetLookaside(int *, int *);

void sqlite3TestConfigSync(void){
  void *pHeap = 0;
  void *pPage = 0;
  int nHeap = 0;
  int minRequest = 0;
  int pageSize = 0;
  int pageCount = 0;
  int lookasideSize = 0;
  int lookasideCount = 0;

  sqlite3ConfigGetHeap(&pHeap, &nHeap, &minRequest);
  sqlite3ConfigGetPageCacheSettings(&pPage, &pageSize, &pageCount);
  sqlite3ConfigGetLookaside(&lookasideSize, &lookasideCount);

  sqlite3Config.bCoreMutex = sqlite3ConfigCoreMutexEnabled();
  sqlite3Config.bFullMutex = sqlite3ConfigFullMutexEnabled();
  sqlite3Config.bMemstat = sqlite3ConfigMemStatusEnabled();
  sqlite3Config.sharedCacheEnabled = sqlite3ConfigSharedCacheEnabled();
  sqlite3Config.pHeap = pHeap;
  sqlite3Config.nHeap = nHeap;
  sqlite3Config.mnReq = minRequest;
  sqlite3Config.pPage = pPage;
  sqlite3Config.szPage = pageSize;
  sqlite3Config.nPage = pageCount;
  sqlite3Config.szLookaside = lookasideSize;
  sqlite3Config.nLookaside = lookasideCount;
}

/* end of sqlite_testfixture_config_sync.c */
