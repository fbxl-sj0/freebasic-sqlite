/'
    Project: SQLite FreeBASIC port

    File: sqlite3_fts3_write_types.bi

    Purpose:

        Preserve FTS3 table, cursor, and segment-reader layouts used by
        translated helpers.

    Responsibilities:

        - Match FTS3 record field order, widths, and pointer alignment.
        - Expose the layout to C2FB-generated and manually reviewed routines.

    This file intentionally does NOT contain:

        - Segment traversal, allocation, or database access.
        - Segment-writer layouts or runtime logic.
'/

#ifndef SQLITE3_FTS3_WRITE_TYPES_BI
#define SQLITE3_FTS3_WRITE_TYPES_BI

#include once "sqlite3_types.bi"
#include once "sqlite3_vtab_types.bi"
#include once "sqlite3_fts3_hash_types.bi"
#include once "sqlite3_fts3_tokenizer_types.bi"

Type SqliteFts3TableIndex
    nPrefix As SQLITE_C_INT
    hPending As Fts3Hash
End Type

Type SqliteFts3Table
    base As SqliteVtab
    db As Any Ptr
    zDb As Const ZString Ptr
    zName As Const ZString Ptr
    nColumn As SQLITE_C_INT
    azColumn As ZString Ptr Ptr
    abNotindexed As UByte Ptr
    pTokenizer As Fts3Tokenizer Ptr
    zContentTbl As ZString Ptr
    zLanguageid As ZString Ptr
    nAutoincrmerge As SQLITE_C_INT
    nLeafAdd As SQLITE_C_UINT
    bLock As SQLITE_C_INT
    aStmt(0 To 39) As Any Ptr
    pSeekStmt As Any Ptr
    zReadExprlist As ZString Ptr
    zWriteExprlist As ZString Ptr
    nNodeSize As SQLITE_C_INT
    bFts4 As UByte
    bHasStat As UByte
    bHasDocsize As UByte
    bDescIdx As UByte
    bIgnoreSavepoint As UByte
    nPgsz As SQLITE_C_INT
    zSegmentsTbl As ZString Ptr
    pSegments As Any Ptr
    iSavepoint As SQLITE_C_INT
    nIndex As SQLITE_C_INT
    aIndex As SqliteFts3TableIndex Ptr
    nMaxPendingData As SQLITE_C_INT
    nPendingData As SQLITE_C_INT
    iPrevDocid As sqlite3_int64
    iPrevLangid As SQLITE_C_INT
    bPrevDelete As SQLITE_C_INT
#if defined(SQLITE_DEBUG) OrElse defined(SQLITE_COVERAGE_TEST)
    inTransaction As SQLITE_C_INT
    mxSavepoint As SQLITE_C_INT
#endif
#if defined(SQLITE_DEBUG) OrElse defined(SQLITE_TEST)
    bNoIncrDoclist As SQLITE_C_INT
    nMergeCount As SQLITE_C_INT
#endif
End Type

Type SqliteFts3PendingList
    nData As sqlite3_int64
    aData As ZString Ptr
    nSpace As sqlite3_int64
    iLastDocid As sqlite3_int64
    iLastCol As sqlite3_int64
    iLastPos As sqlite3_int64
End Type

Type SqliteFts3SegFilter
    zTerm As Const ZString Ptr
    nTerm As SQLITE_C_INT
    iCol As SQLITE_C_INT
    flags As SQLITE_C_INT
End Type

Type SqliteFts3DeferredToken
    pToken As Any Ptr
    iCol As SQLITE_C_INT
    pNext As SqliteFts3DeferredToken Ptr
    pList As SqliteFts3PendingList Ptr
End Type

Type SqliteFts3Cursor
    base As SqliteVtabCursor
    eSearch As Short
    isEof As UByte
    isRequireSeek As UByte
    bSeekStmt As UByte
    pStmt As Any Ptr
    pExpr As Any Ptr
    iLangid As SQLITE_C_INT
    nPhrase As SQLITE_C_INT
    pDeferred As SqliteFts3DeferredToken Ptr
    iPrevId As sqlite3_int64
    pNextId As ZString Ptr
    aDoclist As ZString Ptr
    nDoclist As SQLITE_C_INT
    bDesc As UByte
    eEvalmode As SQLITE_C_INT
    nRowAvg As SQLITE_C_INT
    nDoc As sqlite3_int64
    iMinDocid As sqlite3_int64
    iMaxDocid As sqlite3_int64
    isMatchinfoNeeded As SQLITE_C_INT
    pMIBuffer As Any Ptr
End Type

Type SqliteFts3SegReader
    iIdx As SQLITE_C_INT
    bLookup As UByte
    rootOnly As UByte
    iStartBlock As sqlite3_int64
    iLeafEndBlock As sqlite3_int64
    iEndBlock As sqlite3_int64
    iCurrentBlock As sqlite3_int64
    aNode As ZString Ptr
    nNode As SQLITE_C_INT
    nPopulate As SQLITE_C_INT
    pBlob As Any Ptr
    ppNextElem As Any Ptr
    nTerm As SQLITE_C_INT
    zTerm As ZString Ptr
    nTermAlloc As SQLITE_C_INT
    aDoclist As ZString Ptr
    nDoclist As SQLITE_C_INT
    pOffsetList As ZString Ptr
    nOffsetList As SQLITE_C_INT
    iDocid As sqlite3_int64
End Type

' Let C2FB reuse this checked layout without replacing the source typedef name.
Type c2fb_Fts3SegReader As SqliteFts3SegReader

Type SqliteFts3MultiSegReader
    apSegment As SqliteFts3SegReader Ptr Ptr
    nSegment As SQLITE_C_INT
    nAdvance As SQLITE_C_INT
    pFilter As Any Ptr
    aBuffer As ZString Ptr
    nBuffer As sqlite3_int64
    iColFilter As SQLITE_C_INT
    bRestart As SQLITE_C_INT
    nCost As SQLITE_C_INT
    bLookup As SQLITE_C_INT
    zTerm As ZString Ptr
    nTerm As SQLITE_C_INT
    aDoclist As ZString Ptr
    nDoclist As SQLITE_C_INT
End Type

#endif

/' end of sqlite3_fts3_write_types.bi '/
