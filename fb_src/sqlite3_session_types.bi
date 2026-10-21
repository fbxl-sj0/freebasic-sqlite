/'
    Project: SQLite FreeBASIC port

    File: sqlite3_session_types.bi

    Purpose:

        Preserve core Session record layouts from ext/session/sqlite3session.c.

    Responsibilities:

        - Keep Session, SessionTable, and SessionChange field order and widths.
        - Describe the changeset input, iterator, apply, and changegroup records.
        - Keep private pointers and callback slots ABI-compatible with SQLite.

    This file intentionally does NOT contain:

        - Session lifecycle or changeset algorithms.
'/

#ifndef SQLITE3_SESSION_TYPES_BI
#define SQLITE3_SESSION_TYPES_BI

#include once "sqlite3_types.bi"
#include once "sqlite3_db_types.bi"

Type SqliteSessionHook
    pCtx As Any Ptr
    xOld As Any Ptr
    xNew As Any Ptr
    xCount As Any Ptr
    xDepth As Any Ptr
End Type

Type SqliteSessionChange
    op As UByte
    bIndirect As UByte
    nRecordField As UShort
    nMaxSize As SQLITE_C_INT
    nRecord As SQLITE_C_INT
    aRecord As UByte Ptr
    pNext As SqliteSessionChange Ptr
End Type

Type SqliteSessionTable
    pNext As SqliteSessionTable Ptr
    zName As ZString Ptr
    nCol As SQLITE_C_INT
    nTotalCol As SQLITE_C_INT
    bStat1 As SQLITE_C_INT
    bRowid As SQLITE_C_INT
    azCol As Const ZString Ptr Ptr
    azDflt As Const ZString Ptr Ptr
    aiIdx As SQLITE_C_INT Ptr
    abPK As UByte Ptr
    nEntry As SQLITE_C_INT
    nChange As SQLITE_C_INT
    apChange As SqliteSessionChange Ptr Ptr
    pDfltStmt As Any Ptr
End Type

Type SqliteSession
    db As sqlite3 Ptr
    zDb As ZString Ptr
    bEnableSize As SQLITE_C_INT
    bEnable As SQLITE_C_INT
    bIndirect As SQLITE_C_INT
    bAutoAttach As SQLITE_C_INT
    bImplicitPK As SQLITE_C_INT
    rc As SQLITE_C_INT
    pFilterCtx As Any Ptr
    xTableFilter As Any Ptr
    nMalloc As sqlite3_int64
    nMaxChangesetSize As sqlite3_int64
    pZeroBlob As Any Ptr
    pNext As SqliteSession Ptr
    pTable As SqliteSessionTable Ptr
    hook As SqliteSessionHook
End Type

Type SqliteSessionBuffer
    aBuf As UByte Ptr
    nBuf As SQLITE_C_INT
    nAlloc As SQLITE_C_INT
End Type

Type SqliteSessionInput
    bNoDiscard As SQLITE_C_INT
    iCurrent As SQLITE_C_INT
    iNext As SQLITE_C_INT
    aData As UByte Ptr
    nData As SQLITE_C_INT
    buf As SqliteSessionBuffer
    xInput As Any Ptr
    pIn As Any Ptr
    bEof As SQLITE_C_INT
End Type

Type SqliteChangesetIter
    in As SqliteSessionInput
    tblhdr As SqliteSessionBuffer
    bPatchset As SQLITE_C_INT
    bInvert As SQLITE_C_INT
    bSkipEmpty As SQLITE_C_INT
    rc As SQLITE_C_INT
    pConflict As Any Ptr
    zTab As ZString Ptr
    nCol As SQLITE_C_INT
    op As SQLITE_C_INT
    bIndirect As SQLITE_C_INT
    abPK As UByte Ptr
    apValue As Any Ptr Ptr
End Type

Type SqliteSessionDiffContext
    pStmt As Any Ptr
    bRowid As SQLITE_C_INT
    nOldOff As SQLITE_C_INT
End Type

Type SqliteSessionUpdate
    pStmt As Any Ptr
    aMask As SQLITE_C_UINT Ptr
    pNext As SqliteSessionUpdate Ptr
End Type

Type SqliteSessionApplyContext
    db As sqlite3 Ptr
    pDelete As Any Ptr
    pInsert As Any Ptr
    pSelect As Any Ptr
    nCol As SQLITE_C_INT
    azCol As Const ZString Ptr Ptr
    abPK As UByte Ptr
    aUpdateMask As SQLITE_C_UINT Ptr
    pUp As SqliteSessionUpdate Ptr
    bStat1 As SQLITE_C_INT
    bDeferConstraints As SQLITE_C_INT
    bInvertConstraints As SQLITE_C_INT
    constraints As SqliteSessionBuffer
    rebase As SqliteSessionBuffer
    bRebaseStarted As UByte
    bRebase As UByte
    bIgnoreNoop As UByte
    bNoUpdateLoop As UByte
    bRowid As SQLITE_C_INT
    zErr As ZString Ptr
End Type

Type SqliteSessionChangeData
    pTab As SqliteSessionTable Ptr
    bIndirect As SQLITE_C_INT
    eOp As SQLITE_C_INT
    nBufAlloc As SQLITE_C_INT
    aBuf As SqliteSessionBuffer Ptr
    record As SqliteSessionBuffer
End Type

Type SqliteChangegroup
    rc As SQLITE_C_INT
    bPatch As SQLITE_C_INT
    pList As SqliteSessionTable Ptr
    rec As SqliteSessionBuffer
    db As sqlite3 Ptr
    zDb As ZString Ptr
    cd As SqliteSessionChangeData
End Type

Type SqliteRebaser
    grp As SqliteChangegroup
End Type

Type SqliteSessionStat1Context
    hook As SqliteSessionHook
    pSession As SqliteSession Ptr
End Type

Type SqliteSessionDiffCtx As SqliteSessionDiffContext
Type SqliteSessionApplyCtx As SqliteSessionApplyContext
Type SqliteChangeData As SqliteSessionChangeData

Const SQLITE_SESSION_OBJCONFIG_SIZE As SQLITE_C_INT = 1
Const SQLITE_SESSION_OBJCONFIG_ROWID As SQLITE_C_INT = 2

#endif

/' end of sqlite3_session_types.bi '/
