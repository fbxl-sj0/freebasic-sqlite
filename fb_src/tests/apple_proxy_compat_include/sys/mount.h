/*
    Project: SQLite FreeBASIC port
    File: sys/mount.h
    Purpose: Supply the Darwin statfs layout and mount flags for a simulated
             Apple C reference build on Linux.
    This header is test-only and does not describe the Linux system statfs.
*/

#ifndef SQLITE_FB_TEST_DARWIN_SYS_MOUNT_H
#define SQLITE_FB_TEST_DARWIN_SYS_MOUNT_H

#include <stdint.h>
#include <sys/types.h>

typedef unsigned char uuid_t[16];

#define st_mtimespec st_mtim

#define MNT_RDONLY 0x00000001
#define MNT_LOCAL  0x00001000

struct statfs {
  uint32_t f_bsize;
  int32_t f_iosize;
  uint64_t f_blocks;
  uint64_t f_bfree;
  uint64_t f_bavail;
  uint64_t f_files;
  uint64_t f_ffree;
  int32_t f_fsid[2];
  uint32_t f_owner;
  uint32_t f_type;
  uint32_t f_flags;
  uint32_t f_fssubtype;
  char f_fstypename[16];
  char f_mntonname[1024];
  char f_mntfromname[1024];
  uint32_t f_flags_ext;
  uint32_t f_reserved[7];
};

int fstatfs(int, struct statfs *);
int statfs(const char *, struct statfs *);
int fsctl(const char *, unsigned long, void *, unsigned int);
int *__error(void);
void srandomdev(void);

#endif

/* end of sys/mount.h */
