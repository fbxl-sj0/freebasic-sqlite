/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_windows_config_smoke.c

    Purpose:

        Exercise sqlite3_config()'s C varargs ABI through Win32 and Win64
        FreeBASIC SQLite DLLs.

    Responsibilities:

        - Set process-wide mutex, URI, lookaside, memory, PMA, and page-cache
          configuration before initialization.
        - Exercise SQLITE_CONFIG_WIN32_HEAPSIZE when SQLITE_WIN32_MALLOC is
          enabled.
        - Retrieve page-cache methods and the page-cache header size.
        - Check the post-initialization guard and invoke the configured log
          callback with its application context.
        - Return an exact process status without requiring CRT startup code.

    This file intentionally does NOT contain:

        - SQLite implementation code.
        - A port or modification of upstream test scripts.
*/

#include <sqlite3.h>

enum {
  PAGE_CACHE_PAGE_SIZE = 512,
  PAGE_CACHE_PAGE_COUNT = 8,
  PAGE_CACHE_BYTES = PAGE_CACHE_PAGE_SIZE * PAGE_CACHE_PAGE_COUNT,
  WIN_HEAP_SIZE_BYTES = 4 * 1024 * 1024
};

static double pageCacheBuffer[PAGE_CACHE_BYTES / sizeof(double)];
static int logCount;
static int badLogContext;
static int logContext;
static int logMessageMatched;

static int containsText(const char *text, const char *pattern){
  int i;
  int j;
  if( text==0 || pattern==0 ) return 0;
  for(i=0; text[i]; i++){
    for(j=0; pattern[j] && text[i+j]==pattern[j]; j++){}
    if( pattern[j]==0 ) return 1;
  }
  return pattern[0]==0;
}

static int executeSql(sqlite3 *db, const char *sql){
  return sqlite3_exec(db, sql, 0, 0, 0);
}

static void configuredLog(void *context, int errorCode, const char *message){
  if( context!=&logContext ) badLogContext = 1;
  if( errorCode==SQLITE_ERROR && containsText(message, "config callback") ){
    logMessageMatched = 1;
  }
  logCount++;
}

static int entry(void){
  sqlite3_pcache_methods2 pcacheMethods;
  sqlite3 *db = 0;
  int headerSize = 0;
  int rc;

  rc = sqlite3_config(SQLITE_CONFIG_SINGLETHREAD);
  if( rc!=SQLITE_OK ) return 1;
#ifdef SQLITE_WIN32_MALLOC
  /* Bound the private heap while leaving room for SQLite's runtime state. */
  rc = sqlite3_config(SQLITE_CONFIG_WIN32_HEAPSIZE, WIN_HEAP_SIZE_BYTES);
  if( rc!=SQLITE_OK ) return 15;
#endif
  rc = sqlite3_config(SQLITE_CONFIG_URI, 1);
  if( rc!=SQLITE_OK ) return 2;
  rc = sqlite3_config(SQLITE_CONFIG_COVERING_INDEX_SCAN, 0);
  if( rc!=SQLITE_OK ) return 3;
  rc = sqlite3_config(SQLITE_CONFIG_MEMSTATUS, 0);
  if( rc!=SQLITE_OK ) return 4;
  rc = sqlite3_config(SQLITE_CONFIG_LOOKASIDE, 128, 24);
  if( rc!=SQLITE_OK ) return 5;
  rc = sqlite3_config(SQLITE_CONFIG_PMASZ, (unsigned int)4);
  if( rc!=SQLITE_OK ) return 6;
  rc = sqlite3_config(SQLITE_CONFIG_PAGECACHE, (void*)pageCacheBuffer,
                      PAGE_CACHE_PAGE_SIZE, PAGE_CACHE_PAGE_COUNT);
  if( rc!=SQLITE_OK ) return 7;
  rc = sqlite3_config(SQLITE_CONFIG_GETPCACHE2, &pcacheMethods);
  if( rc!=SQLITE_OK || pcacheMethods.xInit==0 || pcacheMethods.xFetch==0 ){
    return 8;
  }
  rc = sqlite3_config(SQLITE_CONFIG_LOG, configuredLog, &logContext);
  if( rc!=SQLITE_OK ) return 9;

  rc = sqlite3_initialize();
  if( rc!=SQLITE_OK ) return 10;

  rc = sqlite3_open(":memory:", &db);
  if( rc!=SQLITE_OK ) return 16;
  rc = executeSql(db,
      "CREATE TABLE heap_smoke(k PRIMARY KEY, value);"
      "INSERT INTO heap_smoke VALUES(1, 'allocated');");
  if( rc!=SQLITE_OK ){
    sqlite3_close(db);
    return 17;
  }
  rc = sqlite3_close(db);
  db = 0;
  if( rc!=SQLITE_OK ) return 18;

  rc = sqlite3_config(SQLITE_CONFIG_PCACHE_HDRSZ, &headerSize);
  if( rc!=SQLITE_OK || headerSize<=0 ) return 11;
  rc = sqlite3_config(SQLITE_CONFIG_URI, 0);
  if( rc!=SQLITE_MISUSE ) return 12;

  sqlite3_log(SQLITE_ERROR, "%s", "config callback test");
  if( logCount!=1 || badLogContext || !logMessageMatched ) return 13;

  rc = sqlite3_shutdown();
  return rc==SQLITE_OK ? 0 : 14;
}

__declspec(dllimport) void __stdcall ExitProcess(unsigned int exitCode);

void start(void){
  ExitProcess((unsigned int)entry());
}

/* end of sqlite_windows_config_smoke.c */
