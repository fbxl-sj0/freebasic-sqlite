/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_prng_fork_smoke.c

    Purpose:

        Check that a child process receives a fresh SQLite PRNG stream after
        opening a database following fork().

    Responsibilities:

        - Seed and advance SQLite's PRNG before fork().
        - Open separate file-backed databases in the parent and child.
        - Confirm that both processes continue with different random streams.

    This file intentionally does NOT contain:

        - SQLite implementation code or changes to upstream Tcl tests.
        - Private SQLite structure access.
*/

#include <sqlite3.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

typedef struct ForkResult ForkResult;
struct ForkResult {
  int rc;
  int closeRc;
  unsigned char bytes[64];
};

static int readAll(int fd, void *buffer, size_t amount){
  unsigned char *p = (unsigned char*)buffer;
  size_t nDone = 0;
  while( nDone<amount ){
    ssize_t n = read(fd, &p[nDone], amount-nDone);
    if( n<0 && errno==EINTR ) continue;
    if( n<=0 ) return -1;
    nDone += (size_t)n;
  }
  return 0;
}

static int writeAll(int fd, const void *buffer, size_t amount){
  const unsigned char *p = (const unsigned char*)buffer;
  size_t nDone = 0;
  while( nDone<amount ){
    ssize_t n = write(fd, &p[nDone], amount-nDone);
    if( n<0 && errno==EINTR ) continue;
    if( n<=0 ) return -1;
    nDone += (size_t)n;
  }
  return 0;
}

int main(void){
  unsigned char warm[64];
  unsigned char parentBytes[64];
  int channel[2];
  int rc;
  int childStatus = 0;
  int parentCloseRc = SQLITE_OK;
  int childReadRc;
  char parentPath[128];
  char childPath[128];
  sqlite3 *db = 0;
  ForkResult childResult;
  pid_t child;

  rc = sqlite3_initialize();
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "sqlite3_initialize failed: %d\n", rc);
    return 1;
  }
  sqlite3_randomness((int)sizeof(warm), warm);

  /* 128 bytes covers the fixed names and a signed long process ID. */
  sprintf(parentPath, "/tmp/sqlite-prng-fork-%ld-parent.db", (long)getpid());
  sprintf(childPath, "/tmp/sqlite-prng-fork-%ld-child.db", (long)getpid());
  unlink(parentPath);
  unlink(childPath);

  if( pipe(channel)!=0 ){
    perror("pipe");
    return 2;
  }
  child = fork();
  if( child<0 ){
    perror("fork");
    close(channel[0]);
    close(channel[1]);
    return 3;
  }

  memset(&childResult, 0, sizeof(childResult));

  if( child==0 ){
    close(channel[0]);
    childResult.rc = sqlite3_open(childPath, &db);
    memset(childResult.bytes, 0, sizeof(childResult.bytes));
    if( childResult.rc==SQLITE_OK ){
      sqlite3_randomness((int)sizeof(childResult.bytes), childResult.bytes);
    }
    childResult.closeRc = db ? sqlite3_close(db) : SQLITE_OK;
    if( writeAll(channel[1], &childResult, sizeof(childResult))!=0 ){
      close(channel[1]);
      _exit(4);
    }
    close(channel[1]);
    _exit(childResult.rc==SQLITE_OK && childResult.closeRc==SQLITE_OK ? 0 : 5);
  }

  close(channel[1]);
  rc = sqlite3_open(parentPath, &db);
  if( rc==SQLITE_OK ) sqlite3_randomness((int)sizeof(parentBytes), parentBytes);
  else memset(parentBytes, 0, sizeof(parentBytes));
  if( db ) parentCloseRc = sqlite3_close(db);

  childReadRc = readAll(channel[0], &childResult, sizeof(childResult));
  close(channel[0]);
  if( waitpid(child, &childStatus, 0)<0 ){
    perror("waitpid");
    unlink(parentPath);
    unlink(childPath);
    return 6;
  }

  unlink(parentPath);
  unlink(childPath);
  if( rc!=SQLITE_OK || parentCloseRc!=SQLITE_OK || childReadRc!=0 ||
      childResult.rc!=SQLITE_OK || childResult.closeRc!=SQLITE_OK ||
      !WIFEXITED(childStatus) || WEXITSTATUS(childStatus)!=0 ){
    fprintf(stderr, "fork PRNG smoke failed: parent=%d/%d child=%d/%d status=%d\n",
        rc, parentCloseRc, childResult.rc, childResult.closeRc, childStatus);
    return 7;
  }
  if( memcmp(parentBytes, childResult.bytes, sizeof(parentBytes))==0 ){
    fprintf(stderr, "parent and child continued with identical PRNG streams\n");
    return 8;
  }
  return 0;
}

/* end of sqlite_prng_fork_smoke.c */
