/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite3_win_seh_bridge.c

    Purpose:

        Provide the compiler-specific Windows SEH frame used by the WAL
        implementation while keeping its database work in FreeBASIC.

    Responsibilities:

        - Invoke a FreeBASIC WAL operation inside a Windows __try block.
        - Forward exception metadata to the FreeBASIC filter callback.
        - Run normal-exit and handled-exception callbacks in their proper
          positions relative to Windows stack unwinding.

    This file intentionally does NOT contain:

        - WAL operations, lock policy, or exception recovery logic.
        - SQLite data structures or Windows API imports.
*/

#if !defined(_WIN32)
#error This file is only for Windows targets.
#endif

#if !defined(__clang__) && !defined(_MSC_VER)
#error A compiler with Microsoft-compatible SEH intrinsics is required.
#endif

#include "sqlite3_win_seh_bridge.h"

/* These intrinsics are valid only while evaluating the __except filter. */
extern unsigned long __cdecl __exception_code(void);
extern void *__cdecl __exception_info(void);

__declspec(noinline)
int __cdecl sqlite3WinWalSehRun(
    void *pWal,
    void *pContext,
    SqliteWalSehStep xEnter,
    SqliteWalSehWork xWork,
    SqliteWalSehStep xLeave,
    SqliteWalSehFilter xFilter,
    SqliteWalSehCatch xCatch,
    int invalidResult
){
    int result;

    if( pWal==0 || pContext==0 || xEnter==0 || xWork==0 || xLeave==0
     || xFilter==0 || xCatch==0
    ){
        return invalidResult;
    }

    /* SQLite enters the tracked try state before installing its SEH frame. */
    xEnter(pWal);
    __try {
        result = xWork(pContext);
        xLeave(pWal);
    } __except(
        xFilter(pWal, __exception_code(), __exception_info())
    ) {
        result = xCatch(pWal);
    }

    return result;
}

/* end of sqlite3_win_seh_bridge.c */
