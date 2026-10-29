/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite3_win_seh_bridge.h

    Purpose:

        Declare the narrow callback interface between FreeBASIC WAL code and
        the Windows structured-exception frame.

    Responsibilities:

        - Keep callback signatures identical for production and smoke tests.
        - Document the context and exception-filter argument ownership.

    This file intentionally does NOT contain:

        - WAL data structures, error policy, or exception cleanup logic.
        - Windows API declarations used by the FreeBASIC implementation.
*/

#ifndef SQLITE3_WIN_SEH_BRIDGE_H
#define SQLITE3_WIN_SEH_BRIDGE_H

#if !defined(_WIN32)
#error This interface is only for Windows targets.
#endif

typedef void (__cdecl *SqliteWalSehStep)(void *pWal);
typedef int (__cdecl *SqliteWalSehWork)(void *pContext);
typedef int (__cdecl *SqliteWalSehFilter)(
    void *pWal,
    unsigned long exceptionCode,
    void *pExceptionInformation
);
typedef int (__cdecl *SqliteWalSehCatch)(void *pWal);

int __cdecl sqlite3WinWalSehRun(
    void *pWal,
    void *pContext,
    SqliteWalSehStep xEnter,
    SqliteWalSehWork xWork,
    SqliteWalSehStep xLeave,
    SqliteWalSehFilter xFilter,
    SqliteWalSehCatch xCatch,
    int invalidResult
);

#endif

/* end of sqlite3_win_seh_bridge.h */
