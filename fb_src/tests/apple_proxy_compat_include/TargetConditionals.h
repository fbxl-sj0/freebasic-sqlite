/*
    Project: SQLite FreeBASIC port
    File: TargetConditionals.h
    Purpose: Provide the Apple target macros needed to compile a C reference
             profile on a Linux host.
    This test shim does not describe an actual Apple device.
*/

#ifndef SQLITE_FB_TEST_TARGET_CONDITIONALS_H
#define SQLITE_FB_TEST_TARGET_CONDITIONALS_H

#define TARGET_OS_EMBEDDED 0
#define TARGET_IPHONE_SIMULATOR 0
#define TARGET_OS_MACCATALYST 0
#define TARGET_OS_IPHONE 0
#define TARGET_OS_MAC 1

#endif

/* end of TargetConditionals.h */
