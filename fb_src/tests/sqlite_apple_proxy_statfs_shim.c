/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_apple_proxy_statfs_shim.c

    Purpose:

        Supply the small Darwin-specific syscall surface needed to exercise
        the Apple proxy VFS path on a Linux development host.

    Responsibilities:

        - Fill the 2,168-byte Darwin statfs record used by the Unix VFS.
        - Select local or remote mount flags from a test environment variable.
        - Provide the proxy directory selector and unused Apple-only symbols.

    This file intentionally does NOT contain:

        - A replacement for Darwin filesystem or locking behavior.
        - SQLite engine code or upstream test modifications.
*/

#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

enum {
  DARWIN_STATFS_SIZE = 2168,
  DARWIN_MNT_LOCAL = 0x00001000,
  DARWIN_F_FLAGS_OFFSET = 64,
  DARWIN_F_FSTYPENAME_OFFSET = 72,
  DARWIN_CS_USER_TEMP_DIR = 65537
};

static int gFakeFatFilesystem = 0;
static int gFatSeedWriteSeen = 0;

static int fillDarwinStatfs(void *pStat){
  const char *zLocal = getenv("SQLITE3_FB_FAKE_MNT_LOCAL");
  const char *zFsType = getenv("SQLITE3_FB_FAKE_FSTYPE");
  uint32_t flags = zLocal && atoi(zLocal)!=0 ? DARWIN_MNT_LOCAL : 0;
  if( pStat==0 ){
    errno = EFAULT;
    return -1;
  }
  memset(pStat, 0, DARWIN_STATFS_SIZE);
  memcpy((char*)pStat + DARWIN_F_FLAGS_OFFSET, &flags, sizeof(flags));
  if( zFsType==0 ) zFsType = "apfs";
  strncpy((char*)pStat + DARWIN_F_FSTYPENAME_OFFSET, zFsType, 15);
  return 0;
}

int fstatfs(int fd, void *pStat){
  const char *zFsType = getenv("SQLITE3_FB_FAKE_FSTYPE");
  (void)fd;
  gFakeFatFilesystem = zFsType && strcmp(zFsType, "msdos")==0;
  if( getenv("SQLITE3_FB_FAKE_DEBUG") ){
    fprintf(stderr, "fake fstatfs fd=%d type=%s fat=%d\n",
            fd, zFsType ? zFsType : "apfs", gFakeFatFilesystem);
  }
  return fillDarwinStatfs(pStat);
}

int statfs(const char *zPath, void *pStat){
  (void)zPath;
  return fillDarwinStatfs(pStat);
}

size_t confstr(int name, char *zBuffer, size_t nBuffer){
  static size_t (*xConfstr)(int, char*, size_t);
  const char *zPath;
  size_t nPath;
  if( name!=DARWIN_CS_USER_TEMP_DIR ){
    if( xConfstr==0 ) xConfstr = dlsym(RTLD_NEXT, "confstr");
    return xConfstr ? xConfstr(name, zBuffer, nBuffer) : 0;
  }
  zPath = getenv("SQLITE3_FB_FAKE_PROXYDIR");
  if( zPath==0 ) zPath = "/tmp/sqlite-fb-apple-proxy-sim/";
  nPath = strlen(zPath) + 1;
  if( zBuffer && nBuffer>0 ){
    size_t nCopy = nPath<nBuffer ? nPath : nBuffer;
    memcpy(zBuffer, zPath, nCopy);
    zBuffer[nBuffer-1] = 0;
  }
  return nPath;
}

int *__error(void){
  return &errno;
}

ssize_t write(int fd, const void *pBuffer, size_t nByte){
  static ssize_t (*xWrite)(int, const void*, size_t);
  if( xWrite==0 ) xWrite = dlsym(RTLD_NEXT, "write");
  if( xWrite==0 ){
    errno = ENOSYS;
    return -1;
  }
  if( getenv("SQLITE3_FB_FAKE_DEBUG") ){
    fprintf(stderr, "fake write fd=%d size=%zu byte=%02x fat=%d\n",
            fd, nByte, nByte ? ((const unsigned char*)pBuffer)[0] : 0,
            gFakeFatFilesystem);
  }
  if( gFakeFatFilesystem && nByte==1 && *(const char*)pBuffer=='S' ){
    gFatSeedWriteSeen = 1;
  }
  return xWrite(fd, pBuffer, nByte);
}

int sqlite3_apple_proxy_fake_fat_seed_seen(void){
  return gFatSeedWriteSeen;
}

void srandomdev(void){
}

int fsctl(const char *zPath, unsigned long request, void *pArg, unsigned int options){
  (void)zPath;
  (void)request;
  (void)pArg;
  (void)options;
  errno = ENOTSUP;
  return -1;
}

/* end of sqlite_apple_proxy_statfs_shim.c */
