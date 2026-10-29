/*
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite_mutex_threadless_api.c

    Purpose:

        Check SQLite's debug no-op mutex callbacks in a THREADSAFE=0 build.

    Responsibilities:

        - Verify fast and recursive mutex state transitions.
        - Check try, held, not-held, static, and NULL mutex behavior.
        - Exhaust and restore the SQLite heap around debug mutex allocation.
        - Leave the upstream Tcl test scripts unchanged.

    This file intentionally does NOT contain:

        - SQLite mutex implementation or a threaded concurrency test.
        - Changes to upstream tests or SQLite engine source.
*/

#include "../../sqlite3.h"
#include <stdio.h>
#include <stdlib.h>

#ifndef SQLITE_EXPECT_THREADSAFE
# define SQLITE_EXPECT_THREADSAFE 0
#endif
#ifndef SQLITE_EXPECT_DEBUG_MUTEX
# define SQLITE_EXPECT_DEBUG_MUTEX 1
#endif

#if SQLITE_EXPECT_DEBUG_MUTEX
union TestHeap {
  sqlite3_int64 align;
  unsigned char bytes[2 * 1024 * 1024];
};
#define MAX_HEAP_BLOCKS 131072
static union TestHeap testHeap;
#endif

static int check_value(const char *name, int actual, int expected){
  if( actual==expected ) return 0;
  fprintf(stderr, "%s: expected %d, got %d\n", name, expected, actual);
  return 1;
}

int main(void){
  sqlite3_mutex *fast = 0;
  sqlite3_mutex *recursive = 0;
  sqlite3_mutex *staticMutex = 0;
  int failed = 0;
  int rc;
#if SQLITE_EXPECT_DEBUG_MUTEX
  void **heapBlocks = 0;
  int nHeapBlocks = 0;
  int iBlock;
  sqlite3_uint64 requestSize;
#endif

  failed |= check_value("sqlite3_threadsafe", sqlite3_threadsafe(),
                        SQLITE_EXPECT_THREADSAFE);
#if SQLITE_EXPECT_DEBUG_MUTEX
  rc = sqlite3_config(SQLITE_CONFIG_HEAP, testHeap.bytes,
                      (int)sizeof(testHeap.bytes), 32);
  failed |= check_value("SQLITE_CONFIG_HEAP", rc, SQLITE_OK);
  if( rc!=SQLITE_OK ) return 1;
#endif
  rc = sqlite3_initialize();
  failed |= check_value("sqlite3_initialize", rc, SQLITE_OK);
  if( rc!=SQLITE_OK ) return 1;

#if SQLITE_EXPECT_DEBUG_MUTEX
  failed |= check_value("NULL mutex held", sqlite3_mutex_held(0), 1);
  failed |= check_value("NULL mutex not-held", sqlite3_mutex_notheld(0), 1);
#endif
  failed |= check_value("NULL mutex try", sqlite3_mutex_try(0), SQLITE_OK);

  fast = sqlite3_mutex_alloc(SQLITE_MUTEX_FAST);
  if( fast==0 ){
    fprintf(stderr, "fast mutex allocation returned NULL\n");
    failed = 1;
  }else{
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("fast initially held", sqlite3_mutex_held(fast), 0);
    failed |= check_value("fast initially not-held", sqlite3_mutex_notheld(fast), 1);
#endif
    sqlite3_mutex_enter(fast);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("fast held after enter", sqlite3_mutex_held(fast), 1);
    failed |= check_value("fast not-held after enter", sqlite3_mutex_notheld(fast), 0);
#endif
    sqlite3_mutex_leave(fast);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("fast held after leave", sqlite3_mutex_held(fast), 0);
#endif
    rc = sqlite3_mutex_try(fast);
    failed |= check_value("fast try", rc, SQLITE_OK);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("fast held after try", sqlite3_mutex_held(fast), 1);
#endif
    sqlite3_mutex_leave(fast);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("fast not-held after try leave", sqlite3_mutex_notheld(fast), 1);
#endif
    sqlite3_mutex_free(fast);
  }

  recursive = sqlite3_mutex_alloc(SQLITE_MUTEX_RECURSIVE);
  if( recursive==0 ){
    fprintf(stderr, "recursive mutex allocation returned NULL\n");
    failed = 1;
  }else{
    sqlite3_mutex_enter(recursive);
    sqlite3_mutex_enter(recursive);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("recursive held twice", sqlite3_mutex_held(recursive), 1);
    failed |= check_value("recursive not-held twice", sqlite3_mutex_notheld(recursive), 0);
#endif
    sqlite3_mutex_leave(recursive);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("recursive held once", sqlite3_mutex_held(recursive), 1);
#endif
    sqlite3_mutex_leave(recursive);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("recursive not-held after leave", sqlite3_mutex_notheld(recursive), 1);
#endif
    sqlite3_mutex_free(recursive);
  }

  staticMutex = sqlite3_mutex_alloc(SQLITE_MUTEX_STATIC_MAIN);
  if( staticMutex==0 ){
    fprintf(stderr, "static mutex allocation returned NULL\n");
    failed = 1;
  }else{
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("static initially not-held", sqlite3_mutex_notheld(staticMutex), 1);
#endif
    sqlite3_mutex_enter(staticMutex);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("static held after enter", sqlite3_mutex_held(staticMutex), 1);
#endif
    sqlite3_mutex_leave(staticMutex);
#if SQLITE_EXPECT_DEBUG_MUTEX
    failed |= check_value("static not-held after leave", sqlite3_mutex_notheld(staticMutex), 1);
#endif
  }

#if SQLITE_EXPECT_DEBUG_MUTEX
  heapBlocks = (void**)malloc(sizeof(void*) * MAX_HEAP_BLOCKS);
  if( heapBlocks==0 ){
    fprintf(stderr, "could not allocate the host-side heap block list\n");
    failed = 1;
  }else{
    for(requestSize=1; requestSize<=sizeof(testHeap.bytes); requestSize*=2){
      while( nHeapBlocks<MAX_HEAP_BLOCKS ){
        void *pBlock = sqlite3_malloc64(requestSize);
        if( pBlock==0 ) break;
        heapBlocks[nHeapBlocks++] = pBlock;
      }
      if( nHeapBlocks==MAX_HEAP_BLOCKS ) break;
    }
    if( nHeapBlocks==0 || nHeapBlocks==MAX_HEAP_BLOCKS ){
      fprintf(stderr, "SQLite heap exhaustion probe did not reach OOM\n");
      failed = 1;
    }else{
      fast = sqlite3_mutex_alloc(SQLITE_MUTEX_FAST);
      if( fast!=0 ){
        fprintf(stderr, "debug fast mutex allocated after SQLite heap exhaustion\n");
        sqlite3_mutex_free(fast);
        failed = 1;
      }
    }
    for(iBlock=nHeapBlocks-1; iBlock>=0; iBlock--){
      sqlite3_free(heapBlocks[iBlock]);
    }
    if( nHeapBlocks>0 && nHeapBlocks<MAX_HEAP_BLOCKS ){
      fast = sqlite3_mutex_alloc(SQLITE_MUTEX_FAST);
      if( fast==0 ){
        fprintf(stderr, "debug fast mutex allocation failed after freeing heap\n");
        failed = 1;
      }else{
        sqlite3_mutex_free(fast);
      }
    }
    free(heapBlocks);
  }
#endif

  rc = sqlite3_shutdown();
  failed |= check_value("sqlite3_shutdown", rc, SQLITE_OK);
  if( !failed ) puts("no-op mutex callback API smoke passed");
  return failed;
}

/* end of sqlite_mutex_threadless_api.c */
