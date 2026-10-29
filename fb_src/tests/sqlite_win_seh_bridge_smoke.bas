/'
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_win_seh_bridge_smoke.bas

    Purpose:

        Check the Windows SEH adapter's callback ABI independently of the
        SQLite engine.

    Responsibilities:

        - Raise a synthetic in-page exception through the bridge.
        - Verify exception metadata reaches the FreeBASIC filter callback.
        - Verify handled exceptions skip the normal-exit callback.

    This file intentionally does NOT contain:

        - SQLite tests, WAL data structures, or recovery policy.
        - A replacement for native Windows SQLite runtime tests.
'/

#lang "fb"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_win_exception_types.bi"

Type WalSehStep As Sub CDecl (ByVal pWal As Any Ptr)
Type WalSehWork As Function CDecl (ByVal pContext As Any Ptr) As SQLITE_C_INT
Type WalSehFilter As Function CDecl ( _
    ByVal pWal As Any Ptr, _
    ByVal exceptionCode As SQLITE_C_UINT, _
    ByVal pExceptionInformation As Any Ptr _
) As SQLITE_C_INT
Type WalSehCatch As Function CDecl (ByVal pWal As Any Ptr) As SQLITE_C_INT

Declare Function sqlite3WinWalSehRun CDecl Alias "sqlite3WinWalSehRun" ( _
    ByVal pWal As Any Ptr, _
    ByVal pContext As Any Ptr, _
    ByVal xEnter As WalSehStep, _
    ByVal xWork As WalSehWork, _
    ByVal xLeave As WalSehStep, _
    ByVal xFilter As WalSehFilter, _
    ByVal xCatch As WalSehCatch, _
    ByVal invalidResult As SQLITE_C_INT _
) As SQLITE_C_INT

Declare Sub winRaiseException StdCall Lib "kernel32" Alias "RaiseException" ( _
    ByVal exceptionCode As SQLITE_C_UINT, _
    ByVal exceptionFlags As SQLITE_C_UINT, _
    ByVal argumentCount As SQLITE_C_UINT, _
    ByVal pArguments As Const SQLITE_SIZE_T Ptr _
)

Private Const SQLITE_SEH_IN_PAGE_ERROR As SQLITE_C_UINT = &HC0000006UL
Private Const SQLITE_SEH_TEST_STATUS As SQLITE_SIZE_T = &HC0000185ULL
Dim Shared walState As SQLITE_C_INT
Dim Shared exceptionArguments(0 To 2) As SQLITE_SIZE_T

Private Sub enterWal CDecl (ByVal pWal As Any Ptr)
    walState = 1
End Sub

Private Function workWal CDecl (ByVal pContext As Any Ptr) As SQLITE_C_INT
    exceptionArguments(0) = 0
    exceptionArguments(1) = 0
    exceptionArguments(2) = SQLITE_SEH_TEST_STATUS
    walState = 2
    winRaiseException(SQLITE_SEH_IN_PAGE_ERROR, 0, 3, @exceptionArguments(0))
    walState = 9
    Return SQLITE_OK
End Function

Private Sub leaveWal CDecl (ByVal pWal As Any Ptr)
    walState = 4
End Sub

Private Function filterWal CDecl ( _
    ByVal pWal As Any Ptr, _
    ByVal exceptionCode As SQLITE_C_UINT, _
    ByVal pExceptionInformation As Any Ptr _
) As SQLITE_C_INT
    If exceptionCode <> SQLITE_SEH_IN_PAGE_ERROR OrElse _
       pExceptionInformation = 0 Then Return 0

    Dim pInfo As SqliteWinExceptionPointers Ptr = _
        CPtr(SqliteWinExceptionPointers Ptr, pExceptionInformation)
    If pInfo->pExceptionRecord = 0 OrElse _
       pInfo->pExceptionRecord->numberParameters < 3 OrElse _
       pInfo->pExceptionRecord->exceptionInformation(2) <> _
           SQLITE_SEH_TEST_STATUS Then Return 0

    walState = 3
    Return 1
End Function

Private Function catchWal CDecl (ByVal pWal As Any Ptr) As SQLITE_C_INT
    If walState = 3 Then Return 73
    Return 72
End Function

Function entry CDecl Alias "entry" () As SQLITE_C_INT
    walState = 0
    Dim rc As SQLITE_C_INT = sqlite3WinWalSehRun( _
        @walState, @walState, @enterWal, @workWal, @leaveWal, _
        @filterWal, @catchWal, SQLITE_MISUSE)
    If rc = 73 AndAlso walState = 3 Then Return SQLITE_OK
    Return SQLITE_ERROR
End Function

/' end of sqlite_win_seh_bridge_smoke.bas '/
