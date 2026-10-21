/'
** 2006 Oct 10
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
******************************************************************************
**
** This is an SQLite module implementing full-text search.
'/
/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_bulk_fts3_core.bas

    Purpose:

        Preserve C2FB candidates from ext/fts3/fts3.c for dependency repair.

    Responsibilities:

        - Keep translated FTS3 table, query, and storage routines available for review.
        - Use tokenizer ABI maps and local aggregate lowering for candidate generation.

    This file intentionally does NOT contain:

        - The static sqlite3_module initializer for the FTS3 table engine.
        - Unsupported expression and callback bodies not yet translated.
        - Test support.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts3_tokenizer_types.bi"
#include once "sqlite3_vtab_types.bi"

#ifndef __C2FB_BODY_C_ABI_TYPES__
#define __C2FB_BODY_C_ABI_TYPES__

#ifndef __C2FB_ABI_TYPE_C_INT__
#define __C2FB_ABI_TYPE_C_INT__
Type c2fb_c_int As Long
#endif
#ifndef __C2FB_ABI_TYPE_C_UINT__
#define __C2FB_ABI_TYPE_C_UINT__
Type c2fb_c_uint As ULong
#endif
#ifndef __C2FB_ABI_TYPE_C_LONG__
#define __C2FB_ABI_TYPE_C_LONG__
Type c2fb_c_long As CLong
#endif
#ifndef __C2FB_ABI_TYPE_C_ULONG__
#define __C2FB_ABI_TYPE_C_ULONG__
Type c2fb_c_ulong As CULong
#endif
#ifndef __C2FB_ABI_TYPE_INT64__
#define __C2FB_ABI_TYPE_INT64__
Type c2fb_int64 As LongInt
#endif
#ifndef __C2FB_ABI_TYPE_UINT64__
#define __C2FB_ABI_TYPE_UINT64__
Type c2fb_uint64 As ULongInt
#endif
#ifndef __C2FB_ABI_TYPE_SIZE_T__
#define __C2FB_ABI_TYPE_SIZE_T__
Type c2fb_size_t As UInteger
#endif
#endif


Type c2fb_callback_5 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Type c2fb_callback_7 As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_78 As Function CDecl(ByVal arg0 As Fts3Tokenizer Ptr) As c2fb_c_int

Private Type c2fb_source_record_23
    iColumn As c2fb_c_int
    op As UByte
    usable As UByte
    iTermOffset As c2fb_c_int
End Type

Private Type c2fb_source_record_24
    iColumn As c2fb_c_int
    desc As UByte
End Type

Private Type c2fb_source_record_25
    argvIndex As c2fb_c_int
    omit As UByte
End Type

Private Type c2fb_source_record_26
    nConstraint As c2fb_c_int
    aConstraint As c2fb_source_record_23 Ptr
    nOrderBy As c2fb_c_int
    aOrderBy As c2fb_source_record_24 Ptr
    aConstraintUsage As c2fb_source_record_25 Ptr
    idxNum As c2fb_c_int
    idxStr As ZString Ptr
    needToFreeIdxStr As c2fb_c_int
    orderByConsumed As c2fb_c_int
    estimatedCost As Double
    estimatedRows As c2fb_int64
    idxFlags As c2fb_c_int
    colUsed As c2fb_uint64
End Type

Private Type c2fb_source_record_27
    pModule As Const SqliteModuleCallbacks Ptr
    nRef As c2fb_c_int
    zErrMsg As ZString Ptr
End Type

Private Type c2fb_source_record_28
    pVtab As c2fb_source_record_27 Ptr
End Type

Private Type c2fb_source_record_32
    count As c2fb_c_int
    chain As Any Ptr
End Type

Private Type c2fb_source_record_33
    keyClass As Byte
    copyKey As Byte
    count As c2fb_c_int
    first As Any Ptr
    htsize As c2fb_c_int
    ht As c2fb_source_record_32 Ptr
End Type

Private Type c2fb_source_record_35
    nPrefix As c2fb_c_int
    hPending As c2fb_source_record_33
End Type

Private Type c2fb_source_record_36
    base As c2fb_source_record_27
    db As Any Ptr
    zDb As Const ZString Ptr
    zName As Const ZString Ptr
    nColumn As c2fb_c_int
    azColumn As ZString Ptr Ptr
    abNotindexed As UByte Ptr
    pTokenizer As Fts3Tokenizer Ptr
    zContentTbl As ZString Ptr
    zLanguageid As ZString Ptr
    nAutoincrmerge As c2fb_c_int
    nLeafAdd As c2fb_c_uint
    bLock As c2fb_c_int
    aStmt(0 To 39) As Any Ptr
    pSeekStmt As Any Ptr
    zReadExprlist As ZString Ptr
    zWriteExprlist As ZString Ptr
    nNodeSize As c2fb_c_int
    bFts4 As UByte
    bHasStat As UByte
    bHasDocsize As UByte
    bDescIdx As UByte
    bIgnoreSavepoint As UByte
    nPgsz As c2fb_c_int
    zSegmentsTbl As ZString Ptr
    pSegments As Any Ptr
    iSavepoint As c2fb_c_int
    nIndex As c2fb_c_int
    aIndex As c2fb_source_record_35 Ptr
    nMaxPendingData As c2fb_c_int
    nPendingData As c2fb_c_int
    iPrevDocid As c2fb_int64
    iPrevLangid As c2fb_c_int
    bPrevDelete As c2fb_c_int
End Type

Private Type c2fb_source_record_37
    base As c2fb_source_record_28
    eSearch As Short
    isEof As UByte
    isRequireSeek As UByte
    bSeekStmt As UByte
    pStmt As Any Ptr
    pExpr As Any Ptr
    iLangid As c2fb_c_int
    nPhrase As c2fb_c_int
    pDeferred As Any Ptr
    iPrevId As c2fb_int64
    pNextId As ZString Ptr
    aDoclist As ZString Ptr
    nDoclist As c2fb_c_int
    bDesc As UByte
    eEvalmode As c2fb_c_int
    nRowAvg As c2fb_c_int
    nDoc As c2fb_int64
    iMinDocid As c2fb_int64
    iMaxDocid As c2fb_int64
    isMatchinfoNeeded As c2fb_c_int
    pMIBuffer As Any Ptr
End Type

Private Type c2fb_source_record_38
    aAll As ZString Ptr
    nAll As c2fb_c_int
    pNextDocid As ZString Ptr
    iDocid As c2fb_int64
    bFreeList As c2fb_c_int
    pList As ZString Ptr
    nList As c2fb_c_int
End Type

Private Type c2fb_source_record_39
    z As ZString Ptr
    n As c2fb_c_int
    isPrefix As c2fb_c_int
    bFirst As c2fb_c_int
    pDeferred As Any Ptr
    pSegcsr As Any Ptr
End Type

Private Type c2fb_source_record_40
    eType As c2fb_c_int
    nNear As c2fb_c_int
    pParent As c2fb_source_record_40 Ptr
    pLeft As c2fb_source_record_40 Ptr
    pRight As c2fb_source_record_40 Ptr
    pPhrase As Any Ptr
    iDocid As c2fb_int64
    bEof As UByte
    bStart As UByte
    bDeferred As UByte
    iPhrase As c2fb_c_int
    aMI As c2fb_c_uint Ptr
End Type

Private Type c2fb_source_record_41
    zTerm As Const ZString Ptr
    nTerm As c2fb_c_int
    iCol As c2fb_c_int
    flags As c2fb_c_int
End Type

Private Type c2fb_source_record_42
    apSegment As Any Ptr Ptr
    nSegment As c2fb_c_int
    nAdvance As c2fb_c_int
    pFilter As c2fb_source_record_41 Ptr
    aBuffer As ZString Ptr
    nBuffer As c2fb_int64
    iColFilter As c2fb_c_int
    bRestart As c2fb_c_int
    nCost As c2fb_c_int
    bLookup As c2fb_c_int
    zTerm As ZString Ptr
    nTerm As c2fb_c_int
    aDoclist As ZString Ptr
    nDoclist As c2fb_c_int
End Type

Private Type c2fb_source_record_43
    hash As c2fb_source_record_33
    nRef As c2fb_c_int
End Type

Private Type c2fb_source_record_44
    aaOutput(0 To 15) As ZString Ptr
    anOutput(0 To 15) As c2fb_c_int
End Type

Private Type c2fb_local_record_47
    zOpt As Const ZString Ptr
    nOpt As c2fb_c_int
End Type

Declare Function sqlite3Fts3PutVarint CDecl Alias "sqlite3Fts3PutVarint" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts3GetVarintU CDecl Alias "sqlite3Fts3GetVarintU" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_uint64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3GetVarint CDecl Alias "sqlite3Fts3GetVarint" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3GetVarintBounded CDecl Alias "sqlite3Fts3GetVarintBounded" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3GetVarint32 CDecl Alias "sqlite3Fts3GetVarint32" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts3VarintLen CDecl Alias "sqlite3Fts3VarintLen" (ByVal arg0 As c2fb_uint64) As c2fb_c_int
Declare Sub sqlite3Fts3Dequote CDecl Alias "sqlite3Fts3Dequote" (ByVal arg0 As ZString Ptr)
Declare Sub fts3GetDeltaVarint CDecl Alias "fts3GetDeltaVarint" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr)
Declare Sub fts3GetReverseVarint CDecl Alias "fts3GetReverseVarint" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_int64 Ptr)
Declare Function fts3DisconnectMethod CDecl Alias "fts3DisconnectMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Sub sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub fts3DbExec CDecl Alias "fts3DbExec" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr, ...)
Declare Function fts3DestroyMethod CDecl Alias "fts3DestroyMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Sub fts3DeclareVtab CDecl Alias "fts3DeclareVtab" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_source_record_36 Ptr)
Declare Sub sqlite3Fts3CreateStatTable CDecl Alias "sqlite3Fts3CreateStatTable" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_source_record_36 Ptr)
Declare Function fts3CreateTables CDecl Alias "fts3CreateTables" (ByVal arg0 As c2fb_source_record_36 Ptr) As c2fb_c_int
Declare Sub fts3DatabasePageSize CDecl Alias "fts3DatabasePageSize" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_source_record_36 Ptr)
Declare Function fts3IsSpecialColumn CDecl Alias "fts3IsSpecialColumn" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub fts3Appendf CDecl Alias "fts3Appendf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As Const ZString Ptr, ...)
Declare Function fts3QuoteId CDecl Alias "fts3QuoteId" (ByVal arg0 As Const ZString Ptr) As ZString Ptr
Declare Function fts3ReadExprList CDecl Alias "fts3ReadExprList" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr) As ZString Ptr
Declare Function fts3WriteExprList CDecl Alias "fts3WriteExprList" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr) As ZString Ptr
Declare Function sqlite3Fts3ReadInt CDecl Alias "sqlite3Fts3ReadInt" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts3GobbleInt CDecl Alias "fts3GobbleInt" (ByVal arg0 As Const ZString Ptr Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts3PrefixParameter CDecl Alias "fts3PrefixParameter" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_source_record_35 Ptr Ptr) As c2fb_c_int
Declare Function fts3ContentColumns CDecl Alias "fts3ContentColumns" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3InitVtab CDecl Alias "fts3InitVtab" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Any Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As c2fb_source_record_27 Ptr Ptr, ByVal arg6 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3ConnectMethod CDecl Alias "fts3ConnectMethod" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_27 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3CreateMethod CDecl Alias "fts3CreateMethod" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_27 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub fts3SetEstimatedRows CDecl Alias "fts3SetEstimatedRows" (ByVal arg0 As c2fb_source_record_26 Ptr, ByVal arg1 As c2fb_int64)
Declare Sub fts3SetUniqueFlag CDecl Alias "fts3SetUniqueFlag" (ByVal arg0 As c2fb_source_record_26 Ptr)
Declare Function fts3BestIndexMethod CDecl Alias "fts3BestIndexMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_source_record_26 Ptr) As c2fb_c_int
Declare Function fts3OpenMethod CDecl Alias "fts3OpenMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_source_record_28 Ptr Ptr) As c2fb_c_int
Declare Sub fts3CursorFinalizeStmt CDecl Alias "fts3CursorFinalizeStmt" (ByVal arg0 As c2fb_source_record_37 Ptr)
Declare Sub fts3ClearCursor CDecl Alias "fts3ClearCursor" (ByVal arg0 As c2fb_source_record_37 Ptr)
Declare Function fts3CloseMethod CDecl Alias "fts3CloseMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
Declare Function fts3CursorSeekStmt CDecl Alias "fts3CursorSeekStmt" (ByVal arg0 As c2fb_source_record_37 Ptr) As c2fb_c_int
Declare Function fts3CursorSeek CDecl Alias "fts3CursorSeek" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_37 Ptr) As c2fb_c_int
Declare Function fts3ScanInteriorNode CDecl Alias "fts3ScanInteriorNode" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_int64 Ptr, ByVal arg5 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts3SelectLeaf CDecl Alias "fts3SelectLeaf" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_int64 Ptr, ByVal arg6 As c2fb_int64 Ptr) As c2fb_c_int
Declare Sub fts3PutDeltaVarint CDecl Alias "fts3PutDeltaVarint" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64)
Declare Sub fts3PoslistCopy CDecl Alias "fts3PoslistCopy" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr Ptr)
Declare Sub fts3ColumnlistCopy CDecl Alias "fts3ColumnlistCopy" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr Ptr)
Declare Sub fts3ReadNextPos CDecl Alias "fts3ReadNextPos" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr)
Declare Function fts3PutColNumber CDecl Alias "fts3PutColNumber" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3PoslistMerge CDecl Alias "fts3PoslistMerge" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3PoslistPhraseMerge CDecl Alias "fts3PoslistPhraseMerge" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3PoslistNearMerge CDecl Alias "fts3PoslistNearMerge" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub fts3GetDeltaVarint3 CDecl Alias "fts3GetDeltaVarint3" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64 Ptr)
Declare Sub fts3PutDeltaVarint3 CDecl Alias "fts3PutDeltaVarint3" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_int64)
Declare Function fts3DoclistOrMerge CDecl Alias "fts3DoclistOrMerge" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As ZString Ptr Ptr, ByVal arg6 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts3DoclistPhraseMerge CDecl Alias "fts3DoclistPhraseMerge" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts3FirstFilter CDecl Alias "sqlite3Fts3FirstFilter" (ByVal arg0 As c2fb_int64, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr) As c2fb_c_int
Declare Function fts3TermSelectFinishMerge CDecl Alias "fts3TermSelectFinishMerge" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_44 Ptr) As c2fb_c_int
Declare Function fts3TermSelectMerge CDecl Alias "fts3TermSelectMerge" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_44 Ptr, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function fts3SegReaderCursorAppend CDecl Alias "fts3SegReaderCursorAppend" (ByVal arg0 As c2fb_source_record_42 Ptr, ByVal arg1 As Any Ptr) As c2fb_c_int
Declare Function fts3SegReaderCursor CDecl Alias "fts3SegReaderCursor" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_source_record_42 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3SegReaderCursor CDecl Alias "sqlite3Fts3SegReaderCursor" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_source_record_42 Ptr) As c2fb_c_int
Declare Function fts3SegReaderCursorAddZero CDecl Alias "fts3SegReaderCursorAddZero" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_source_record_42 Ptr) As c2fb_c_int
Declare Function fts3TermSegReaderCursor CDecl Alias "fts3TermSegReaderCursor" (ByVal arg0 As c2fb_source_record_37 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_source_record_42 Ptr Ptr) As c2fb_c_int
Declare Sub fts3SegReaderCursorFree CDecl Alias "fts3SegReaderCursorFree" (ByVal arg0 As c2fb_source_record_42 Ptr)
Declare Function fts3TermSelect CDecl Alias "fts3TermSelect" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_39 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3DoclistCountDocids CDecl Alias "fts3DoclistCountDocids" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3DocidRange CDecl Alias "fts3DocidRange" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64) As c2fb_int64
Declare Function fts3EofMethod CDecl Alias "fts3EofMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
Declare Function fts3RowidMethod CDecl Alias "fts3RowidMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts3ColumnMethod CDecl Alias "fts3ColumnMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts3UpdateMethod CDecl Alias "fts3UpdateMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts3SyncMethod CDecl Alias "fts3SyncMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Function fts3SetHasStat CDecl Alias "fts3SetHasStat" (ByVal arg0 As c2fb_source_record_36 Ptr) As c2fb_c_int
Declare Function fts3BeginMethod CDecl Alias "fts3BeginMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Function fts3CommitMethod CDecl Alias "fts3CommitMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Function fts3RollbackMethod CDecl Alias "fts3RollbackMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Sub fts3ReversePoslist CDecl Alias "fts3ReversePoslist" (ByVal arg0 As ZString Ptr, ByVal arg1 As ZString Ptr Ptr)
Declare Function fts3FunctionArg CDecl Alias "fts3FunctionArg" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_source_record_37 Ptr Ptr) As c2fb_c_int
Declare Sub fts3SnippetFunc CDecl Alias "fts3SnippetFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
Declare Sub fts3OffsetsFunc CDecl Alias "fts3OffsetsFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
Declare Sub fts3OptimizeFunc CDecl Alias "fts3OptimizeFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
Declare Sub fts3MatchinfoFunc CDecl Alias "fts3MatchinfoFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
Declare Function fts3RenameMethod CDecl Alias "fts3RenameMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function fts3SavepointMethod CDecl Alias "fts3SavepointMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3ReleaseMethod CDecl Alias "fts3ReleaseMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3RollbackToMethod CDecl Alias "fts3RollbackToMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3ShadowName CDecl Alias "fts3ShadowName" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function fts3IntegrityMethod CDecl Alias "fts3IntegrityMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub hashDestroy CDecl Alias "hashDestroy" (ByVal arg0 As Any Ptr)
Declare Sub sqlite3Fts3DoclistPrev CDecl Alias "sqlite3Fts3DoclistPrev" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As c2fb_int64 Ptr, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As UByte Ptr)
Declare Sub sqlite3Fts3DoclistNext CDecl Alias "sqlite3Fts3DoclistNext" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As c2fb_int64 Ptr, ByVal arg5 As UByte Ptr)
Declare Sub fts3EvalDlPhraseNext CDecl Alias "fts3EvalDlPhraseNext" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_38 Ptr, ByVal arg2 As UByte Ptr)
Declare Function fts3EvalAverageDocsize CDecl Alias "fts3EvalAverageDocsize" (ByVal arg0 As c2fb_source_record_37 Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts3AllocateMSI CDecl Alias "fts3AllocateMSI" (ByVal arg0 As c2fb_source_record_40 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_libversion_number CDecl Alias "sqlite3_libversion_number" () As c2fb_c_int
Declare Function c2fb_external_sqlite3_exec CDecl Alias "sqlite3_exec" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_callback_5, ByVal arg3 As Any Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_last_insert_rowid CDecl Alias "sqlite3_last_insert_rowid" (ByVal arg0 As Any Ptr) As c2fb_int64
Declare Sub c2fb_external_sqlite3_set_last_insert_rowid CDecl Alias "sqlite3_set_last_insert_rowid" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64)
Declare Function c2fb_external_sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc CDecl Alias "sqlite3_malloc" (ByVal arg0 As c2fb_c_int) As Any Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function c2fb_external_sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_errmsg CDecl Alias "sqlite3_errmsg" (ByVal arg0 As Any Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_errstr CDecl Alias "sqlite3_errstr" (ByVal arg0 As c2fb_c_int) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_prepare CDecl Alias "sqlite3_prepare" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_int64 CDecl Alias "sqlite3_bind_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_count CDecl Alias "sqlite3_column_count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_name CDecl Alias "sqlite3_column_name" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_data_count CDecl Alias "sqlite3_data_count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_blob CDecl Alias "sqlite3_column_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function c2fb_external_sqlite3_column_int CDecl Alias "sqlite3_column_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int64 CDecl Alias "sqlite3_column_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function c2fb_external_sqlite3_column_value CDecl Alias "sqlite3_column_value" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Any Ptr
Declare Function c2fb_external_sqlite3_column_bytes CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_reset CDecl Alias "sqlite3_reset" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_int64 CDecl Alias "sqlite3_value_int64" (ByVal arg0 As Any Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_value_pointer CDecl Alias "sqlite3_value_pointer" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As Any Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_numeric_type CDecl Alias "sqlite3_value_numeric_type" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3_result_error CDecl Alias "sqlite3_result_error" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_error_nomem CDecl Alias "sqlite3_result_error_nomem" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3_result_error_code CDecl Alias "sqlite3_result_error_code" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_int CDecl Alias "sqlite3_result_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_int64 CDecl Alias "sqlite3_result_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64)
Declare Sub c2fb_external_sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_callback_7)
Declare Sub c2fb_external_sqlite3_result_value CDecl Alias "sqlite3_result_value" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr)
Declare Sub c2fb_external_sqlite3_result_pointer CDecl Alias "sqlite3_result_pointer" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_callback_7)
Declare Function c2fb_external_sqlite3_table_column_metadata CDecl Alias "sqlite3_table_column_metadata" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr, ByVal arg6 As c2fb_c_int Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_declare_vtab CDecl Alias "sqlite3_declare_vtab" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_strnicmp CDecl Alias "sqlite3_strnicmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vtab_config CDecl Alias "sqlite3_vtab_config" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ...) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3HashInit CDecl Alias "sqlite3Fts3HashInit" (ByVal arg0 As c2fb_source_record_33 Ptr, ByVal arg1 As Byte, ByVal arg2 As Byte)
Declare Sub c2fb_external_sqlite3Fts3HashClear CDecl Alias "sqlite3Fts3HashClear" (ByVal arg0 As c2fb_source_record_33 Ptr)
Declare Function c2fb_external_sqlite3Fts3UpdateMethod CDecl Alias "sqlite3Fts3UpdateMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3PendingTermsFlush CDecl Alias "sqlite3Fts3PendingTermsFlush" (ByVal arg0 As c2fb_source_record_36 Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3PendingTermsClear CDecl Alias "sqlite3Fts3PendingTermsClear" (ByVal arg0 As c2fb_source_record_36 Ptr)
Declare Function c2fb_external_sqlite3Fts3Optimize CDecl Alias "sqlite3Fts3Optimize" (ByVal arg0 As c2fb_source_record_36 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3SegReaderNew CDecl Alias "sqlite3Fts3SegReaderNew" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_int64, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As Any Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3SegReaderPending CDecl Alias "sqlite3Fts3SegReaderPending" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As Any Ptr Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3SegReaderFree CDecl Alias "sqlite3Fts3SegReaderFree" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3Fts3AllSegdirs CDecl Alias "sqlite3Fts3AllSegdirs" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3ReadBlock CDecl Alias "sqlite3Fts3ReadBlock" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3SelectDoctotal CDecl Alias "sqlite3Fts3SelectDoctotal" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As Any Ptr Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3FreeDeferredTokens CDecl Alias "sqlite3Fts3FreeDeferredTokens" (ByVal arg0 As c2fb_source_record_37 Ptr)
Declare Sub c2fb_external_sqlite3Fts3SegmentsClose CDecl Alias "sqlite3Fts3SegmentsClose" (ByVal arg0 As c2fb_source_record_36 Ptr)
Declare Function c2fb_external_sqlite3Fts3MaxLevel CDecl Alias "sqlite3Fts3MaxLevel" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3SegReaderStart CDecl Alias "sqlite3Fts3SegReaderStart" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_42 Ptr, ByVal arg2 As c2fb_source_record_41 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3SegReaderStep CDecl Alias "sqlite3Fts3SegReaderStep" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_42 Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3SegReaderFinish CDecl Alias "sqlite3Fts3SegReaderFinish" (ByVal arg0 As c2fb_source_record_42 Ptr)
Declare Function c2fb_external_sqlite3Fts3Incrmerge CDecl Alias "sqlite3Fts3Incrmerge" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3PrepareStmt CDecl Alias "sqlite3Fts3PrepareStmt" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3NextToken CDecl Alias "sqlite3Fts3NextToken" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3Fts3InitTokenizer CDecl Alias "sqlite3Fts3InitTokenizer" (ByVal arg0 As c2fb_source_record_33 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Fts3Tokenizer Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3IsIdChar CDecl Alias "sqlite3Fts3IsIdChar" (ByVal arg0 As Byte) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3Offsets CDecl Alias "sqlite3Fts3Offsets" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_37 Ptr)
Declare Sub c2fb_external_sqlite3Fts3Snippet CDecl Alias "sqlite3Fts3Snippet" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_37 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3Fts3Matchinfo CDecl Alias "sqlite3Fts3Matchinfo" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_37 Ptr, ByVal arg2 As Const ZString Ptr)
Declare Sub c2fb_external_sqlite3Fts3MIBufferFree CDecl Alias "sqlite3Fts3MIBufferFree" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3Fts3ExprFree CDecl Alias "sqlite3Fts3ExprFree" (ByVal arg0 As c2fb_source_record_40 Ptr)
Declare Function c2fb_external_sqlite3Fts3IntegrityCheck CDecl Alias "sqlite3Fts3IntegrityCheck" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Function sqlite3Fts3PutVarint CDecl Alias "sqlite3Fts3PutVarint" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 337
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_uint64
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As UByte
    Dim c2fb_temp_3 As c2fb_uint64
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte

    local0 = CPtr(UByte Ptr, arg0)
    local1 = arg1
    Do
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = CPtr(UByte Ptr, @((*c2fb_temp_0)))
        c2fb_temp_2 = Cast(UByte, Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7fULL))))) Or Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL)))))))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 Shr Cast(c2fb_c_int, 7ULL))))
        local1 = c2fb_temp_3
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))))))
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(UByte Ptr, @(local0[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))]))
    c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_4)) And Cast(c2fb_c_int, &H7fULL))))
    (*c2fb_temp_4) = c2fb_temp_5
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, ((CPtr(UByte Ptr, local0) - CPtr(UByte Ptr, CPtr(UByte Ptr, arg0)))))
End Function
Function sqlite3Fts3GetVarintU CDecl Alias "sqlite3Fts3GetVarintU" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_uint64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 356
    Dim local0 As Const UByte Ptr
    Dim local1 As Const UByte Ptr
    Dim local2 As c2fb_c_uint
    Dim local3 As c2fb_uint64
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As Const UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_uint64 Ptr
    Dim c2fb_temp_3 As c2fb_uint64
    Dim c2fb_temp_4 As Const UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_uint64 Ptr
    Dim c2fb_temp_8 As c2fb_uint64
    Dim c2fb_temp_9 As Const UByte Ptr
    Dim c2fb_temp_10 As c2fb_c_uint
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim c2fb_temp_12 As c2fb_uint64 Ptr
    Dim c2fb_temp_13 As c2fb_uint64
    Dim c2fb_temp_14 As Const UByte Ptr
    Dim c2fb_temp_15 As c2fb_c_uint
    Dim c2fb_temp_16 As c2fb_c_uint
    Dim c2fb_temp_17 As c2fb_uint64 Ptr
    Dim c2fb_temp_18 As c2fb_uint64
    Dim c2fb_temp_19 As c2fb_uint64
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Const UByte Ptr
    Dim local5 As c2fb_uint64
    Dim c2fb_temp_23 As c2fb_uint64
    Dim c2fb_temp_24 As c2fb_uint64 Ptr
    Dim c2fb_temp_25 As c2fb_uint64

    local0 = CPtr(Const UByte Ptr, arg0)
    local1 = local0
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = local0
    local0 = (c2fb_temp_0 + 1)
    c2fb_temp_1 = Cast(c2fb_c_uint, ((*c2fb_temp_0)))
    local2 = c2fb_temp_1
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_2 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_3 = Cast(c2fb_uint64, local2)
        (*c2fb_temp_2) = c2fb_temp_3
        Return Cast(c2fb_c_int, 1ULL)
    End If
    ' empty C statement
    c2fb_temp_5 = (Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7FULL)))))
    c2fb_temp_4 = local0
    local0 = (c2fb_temp_4 + 1)
    c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_5 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_4))))) Shl Cast(c2fb_c_int, 7ULL))))))))
    local2 = c2fb_temp_6
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H4000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_7 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_8 = Cast(c2fb_uint64, local2)
        (*c2fb_temp_7) = c2fb_temp_8
        Return Cast(c2fb_c_int, 2ULL)
    End If
    ' empty C statement
    c2fb_temp_10 = (Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FFFULL)))))
    c2fb_temp_9 = local0
    local0 = (c2fb_temp_9 + 1)
    c2fb_temp_11 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_10 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_9))))) Shl Cast(c2fb_c_int, 14ULL))))))))
    local2 = c2fb_temp_11
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H200000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_12 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_13 = Cast(c2fb_uint64, local2)
        (*c2fb_temp_12) = c2fb_temp_13
        Return Cast(c2fb_c_int, 3ULL)
    End If
    ' empty C statement
    c2fb_temp_15 = (Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H1FFFFFULL)))))
    c2fb_temp_14 = local0
    local0 = (c2fb_temp_14 + 1)
    c2fb_temp_16 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_15 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_14))))) Shl Cast(c2fb_c_int, 21ULL))))))))
    local2 = c2fb_temp_16
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H10000000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_17 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_18 = Cast(c2fb_uint64, local2)
        (*c2fb_temp_17) = c2fb_temp_18
        Return Cast(c2fb_c_int, 4ULL)
    End If
    ' empty C statement
    c2fb_temp_19 = Cast(c2fb_uint64, (Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H0FFFFFFFULL))))))
    local3 = c2fb_temp_19
    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, 28ULL))
    local4 = c2fb_temp_20
    While (-Cast(c2fb_c_int, ((local4 <= Cast(c2fb_c_int, 63ULL)))))
        c2fb_temp_22 = local0
        local0 = (c2fb_temp_22 + 1)
        local5 = (*c2fb_temp_22)
        c2fb_temp_23 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local3 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local5 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7FULL))))) Shl local4)))))
        local3 = c2fb_temp_23
        If (-Cast(c2fb_c_int, (((Cast(c2fb_uint64, (local5 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL))))) = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 7ULL))))
        local4 = c2fb_temp_21
    Wend
    c2fb_flow_0:
    c2fb_temp_24 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
    c2fb_temp_25 = Cast(c2fb_uint64, local3)
    (*c2fb_temp_24) = c2fb_temp_25
    Return Cast(c2fb_c_int, ((CPtr(UByte Ptr, local0) - CPtr(UByte Ptr, local1))))
End Function
Function sqlite3Fts3GetVarint CDecl Alias "sqlite3Fts3GetVarint" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 383
    Return sqlite3Fts3GetVarintU(arg0, CPtr(c2fb_uint64 Ptr, arg1))
End Function
Function sqlite3Fts3GetVarintBounded CDecl Alias "sqlite3Fts3GetVarintBounded" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 393
    Dim local0 As Const UByte Ptr
    Dim local1 As Const UByte Ptr
    Dim local2 As Const UByte Ptr
    Dim local3 As c2fb_uint64
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As c2fb_uint64
    Dim c2fb_temp_2 As Const UByte Ptr
    Dim c2fb_temp_3 As c2fb_uint64
    Dim c2fb_temp_4 As c2fb_int64 Ptr
    Dim c2fb_temp_5 As c2fb_int64

    local0 = CPtr(Const UByte Ptr, arg0)
    local1 = local0
    local2 = CPtr(Const UByte Ptr, arg1)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local4 <= Cast(c2fb_c_int, 63ULL)))))
        local5 = IIf((-Cast(c2fb_c_int, ((local0 < local2)))), Cast(c2fb_c_int, (*local0)), Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_2 = local0
        local0 = (c2fb_temp_2 + 1)
        c2fb_temp_3 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local3 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local5 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7FULL))))) Shl local4)))))
        local3 = c2fb_temp_3
        If (-Cast(c2fb_c_int, (((Cast(c2fb_uint64, (local5 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL))))) = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 7ULL))))
        local4 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(c2fb_int64 Ptr, @((*arg2)))
    c2fb_temp_5 = Cast(c2fb_int64, local3)
    (*c2fb_temp_4) = c2fb_temp_5
    Return Cast(c2fb_c_int, ((CPtr(UByte Ptr, local0) - CPtr(UByte Ptr, local1))))
End Function
Function sqlite3Fts3GetVarint32 CDecl Alias "sqlite3Fts3GetVarint32" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 417
    Dim local0 As Const UByte Ptr
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As Const UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As Const UByte Ptr
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Const UByte Ptr
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As c2fb_c_uint
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Const UByte Ptr
    Dim c2fb_temp_13 As c2fb_c_uint
    Dim c2fb_temp_14 As c2fb_c_uint
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_uint
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int

    local0 = CPtr(Const UByte Ptr, arg0)
    ' C automatic storage declaration
    c2fb_temp_0 = local0
    local0 = (c2fb_temp_0 + 1)
    c2fb_temp_1 = Cast(c2fb_c_uint, ((*c2fb_temp_0)))
    local1 = c2fb_temp_1
    ' C unused-parameter annotation
    c2fb_temp_3 = (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7FULL)))))
    c2fb_temp_2 = local0
    local0 = (c2fb_temp_2 + 1)
    c2fb_temp_4 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_3 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_2))))) Shl Cast(c2fb_c_int, 7ULL))))))))
    local1 = c2fb_temp_4
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H4000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_6 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_5) = c2fb_temp_6
        Return Cast(c2fb_c_int, 2ULL)
    End If
    ' empty C statement
    c2fb_temp_8 = (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FFFULL)))))
    c2fb_temp_7 = local0
    local0 = (c2fb_temp_7 + 1)
    c2fb_temp_9 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_8 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_7))))) Shl Cast(c2fb_c_int, 14ULL))))))))
    local1 = c2fb_temp_9
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H200000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_11 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_10) = c2fb_temp_11
        Return Cast(c2fb_c_int, 3ULL)
    End If
    ' empty C statement
    c2fb_temp_13 = (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H1FFFFFULL)))))
    c2fb_temp_12 = local0
    local0 = (c2fb_temp_12 + 1)
    c2fb_temp_14 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_13 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_12))))) Shl Cast(c2fb_c_int, 21ULL))))))))
    local1 = c2fb_temp_14
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H10000000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_16 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_15) = c2fb_temp_16
        Return Cast(c2fb_c_int, 4ULL)
    End If
    ' empty C statement
    c2fb_temp_17 = Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H0FFFFFFFULL))))))
    local1 = c2fb_temp_17
    c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_uint, (local1 Or (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local0)) And Cast(c2fb_c_int, &H07ULL))))) Shl Cast(c2fb_c_int, 28ULL)))))))))
    (*c2fb_temp_18) = c2fb_temp_19
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, 5ULL)
End Function
Function sqlite3Fts3VarintLen CDecl Alias "sqlite3Fts3VarintLen" (ByVal arg0 As c2fb_uint64) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 441
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_uint64

    local0 = Cast(c2fb_c_int, &O0ULL)
    Do
        c2fb_temp_0 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        c2fb_temp_1 = Cast(c2fb_uint64, Cast(c2fb_uint64, (arg0 Shr Cast(c2fb_c_int, 7ULL))))
        arg0 = c2fb_temp_1
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((arg0 <> Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))))))
    c2fb_flow_0:
    Return local0
End Function
Sub sqlite3Fts3Dequote CDecl Alias "sqlite3Fts3Dequote" (ByVal arg0 As ZString Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 464
    Dim local0 As Byte
    Dim c2fb_temp_0 As Byte
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Byte Ptr
    Dim c2fb_temp_4 As Byte
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Byte Ptr
    Dim c2fb_temp_9 As Byte
    Dim c2fb_temp_10 As Byte Ptr
    Dim c2fb_temp_11 As Byte

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(Byte, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)])
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 91))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 39))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 34))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 96))))) <> 0))))) Then
        local1 = Cast(c2fb_c_int, 1ULL)
        local2 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 91))))) Then
            c2fb_temp_1 = Cast(Byte, Cast(c2fb_c_int, 93))
            local0 = c2fb_temp_1
        End If
        While CPtr(Byte Ptr, arg0)[local1]
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[local1]) = Cast(c2fb_c_int, local0))))) Then
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))]) <> Cast(c2fb_c_int, local0))))) Then
                    Goto c2fb_flow_0
                End If
                c2fb_temp_2 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                c2fb_temp_3 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[c2fb_temp_2]))
                c2fb_temp_4 = Cast(Byte, local0)
                (*c2fb_temp_3) = c2fb_temp_4
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 2ULL))))
                local1 = c2fb_temp_5
            Else
                c2fb_temp_6 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
                c2fb_temp_8 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[c2fb_temp_6]))
                c2fb_temp_7 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
                c2fb_temp_9 = Cast(Byte, CPtr(Byte Ptr, arg0)[c2fb_temp_7])
                (*c2fb_temp_8) = c2fb_temp_9
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_10 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[local2]))
        c2fb_temp_11 = Cast(Byte, Cast(c2fb_c_int, 0))
        (*c2fb_temp_10) = c2fb_temp_11
    End If
End Sub
Private Sub fts3GetDeltaVarint CDecl Alias "fts3GetDeltaVarint" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 493
    Dim local0 As c2fb_int64
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_int64 Ptr
    Dim c2fb_temp_3 As c2fb_int64

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_1 = CPtr(ZString Ptr, (CPtr(Byte Ptr, (*c2fb_temp_0)) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, (*arg0)), CPtr(c2fb_int64 Ptr, @(local0)))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_3 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_2) + local0)))
    (*c2fb_temp_2) = c2fb_temp_3
End Sub
Private Sub fts3GetReverseVarint CDecl Alias "fts3GetReverseVarint" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_int64 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 508
    Dim local0 As c2fb_int64
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_int64 Ptr
    Dim c2fb_temp_6 As c2fb_int64

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(ZString Ptr, (CPtr(Byte Ptr, ((*arg0))) - Cast(c2fb_c_int, 2ULL)))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 >= arg1)))) <> 0) AndAlso (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))) And Cast(c2fb_c_int, &H80ULL))) <> 0)))))
        ' empty C statement
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = (c2fb_temp_1 - 1)
    Wend
    c2fb_flow_0:
    c2fb_temp_2 = local1
    local1 = (c2fb_temp_2 + 1)
    c2fb_temp_3 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_4 = local1
    (*c2fb_temp_3) = c2fb_temp_4
    sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local1), CPtr(c2fb_int64 Ptr, @(local0)))
    c2fb_temp_5 = CPtr(c2fb_int64 Ptr, @((*arg2)))
    c2fb_temp_6 = Cast(c2fb_int64, local0)
    (*c2fb_temp_5) = c2fb_temp_6
End Sub
Private Function fts3DisconnectMethod CDecl Alias "fts3DisconnectMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 530
    Dim local0 As c2fb_source_record_36 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_external_sqlite3_finalize(local0->pSeekStmt)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (40ULL * SizeOf(Any Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Any Ptr))))))))))))
        c2fb_external_sqlite3_finalize(local0->aStmt(local1))
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0->zSegmentsTbl))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0->zReadExprlist))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0->zWriteExprlist))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0->zContentTbl))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0->zLanguageid))
    CPtr(c2fb_callback_78, CPtr(Const Fts3TokenizerModule Ptr, local0->pTokenizer->pModule)->xDestroy)(local0->pTokenizer)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Sub sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 558
    Dim local0 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr

    ' C automatic storage declaration
    c2fb_external_sqlite3_free(CPtr(Any Ptr, (*arg0)))
    Cva_Start(local0, arg1)
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local0))
    (*c2fb_temp_0) = c2fb_temp_1
    Cva_End(local0)
End Sub
Private Sub fts3DbExec CDecl Alias "fts3DbExec" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr, ...)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 573
    Dim local0 As Cva_List
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    If (*arg0) Then
        Return
    End If
    Cva_Start(local0, arg2)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg2, local0))
    local1 = c2fb_temp_0
    Cva_End(local0)
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg0)))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        (*c2fb_temp_1) = c2fb_temp_2
    Else
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg0)))
        c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec(arg1, CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
End Sub
Private Function fts3DestroyMethod CDecl Alias "fts3DestroyMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 596
    Dim local0 As c2fb_source_record_36 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim local3 As Any Ptr

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = local0->zDb
    local3 = local0->db
    fts3DbExec(CPtr(c2fb_c_int Ptr, @(local1)), local3, StrPtr(!"DROP TABLE IF EXISTS %Q.'%q_segments';DROP TABLE IF EXISTS %Q.'%q_segdir';DROP TABLE IF EXISTS %Q.'%q_docsize';DROP TABLE IF EXISTS %Q.'%q_stat';%s DROP TABLE IF EXISTS %Q.'%q_content';"), local2, local0->zName, local2, local0->zName, local2, local0->zName, local2, local0->zName, (IIf(local0->zContentTbl, StrPtr(!"--"), StrPtr(!""))), local2, local0->zName)
    Return (IIf((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))), fts3DisconnectMethod(arg0), local1))
End Function
Private Sub fts3DeclareVtab CDecl Alias "fts3DeclareVtab" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_source_record_36 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 633
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = (IIf(arg1->zLanguageid, CPtr(Const ZString Ptr, arg1->zLanguageid), StrPtr(!"__langid")))
        local4 = c2fb_temp_0
        c2fb_external_sqlite3_vtab_config(arg1->db, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, 1ULL))
        c2fb_external_sqlite3_vtab_config(arg1->db, Cast(c2fb_c_int, 2ULL))
        c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%Q, "), arg1->azColumn[Cast(c2fb_c_int, &O0ULL)]))
        local3 = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < arg1->nColumn)))) <> 0)))))
            c2fb_temp_4 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%Q, "), local3, arg1->azColumn[local0]))
            local3 = c2fb_temp_4
        c2fb_flow_1:
            c2fb_temp_3 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_5 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"CREATE TABLE x(%s %Q HIDDEN, docid HIDDEN, %Q HIDDEN)"), local3, arg1->zName, local4))
        local2 = c2fb_temp_5
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local3 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, (local2 = 0))) <> 0))))) Then
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local1 = c2fb_temp_6
        Else
            c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3_declare_vtab(arg1->db, CPtr(Const ZString Ptr, local2)))
            local1 = c2fb_temp_7
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
        c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg0)))
        c2fb_temp_9 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_8) = c2fb_temp_9
    End If
End Sub
Sub sqlite3Fts3CreateStatTable CDecl Alias "sqlite3Fts3CreateStatTable" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_source_record_36 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 671
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte

    fts3DbExec(arg0, arg1->db, StrPtr(!"CREATE TABLE IF NOT EXISTS %Q.'%q_stat'(id INTEGER PRIMARY KEY, value BLOB);"), arg1->zDb, arg1->zName)
    If (-Cast(c2fb_c_int, ((((*arg0)) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(UByte Ptr, @(arg1->bHasStat))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
End Sub
Private Function fts3CreateTables CDecl Alias "fts3CreateTables" (ByVal arg0 As c2fb_source_record_36 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 689
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As Any Ptr
    Dim local3 As Const ZString Ptr
    Dim local4 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local5 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = arg0->db
    If (-Cast(c2fb_c_int, ((arg0->zContentTbl = Cast(c2fb_c_int, &O0ULL))))) Then
        local3 = CPtr(Const ZString Ptr, arg0->zLanguageid)
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"docid INTEGER PRIMARY KEY")))
        local4 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_1
        While (-Cast(c2fb_c_int, (((local4 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < arg0->nColumn)))) <> 0)))))
            local5 = arg0->azColumn[local1]
            c2fb_temp_3 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z, 'c%d%q'"), local4, local1, local5))
            local4 = c2fb_temp_3
        c2fb_flow_1:
            c2fb_temp_2 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, (((local3 <> 0) AndAlso (local4 <> 0))))) Then
            c2fb_temp_4 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z, langid"), local4, local3))
            local4 = c2fb_temp_4
        End If
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_5
        End If
        fts3DbExec(CPtr(c2fb_c_int Ptr, @(local0)), local2, StrPtr(!"CREATE TABLE %Q.'%q_content'(%s)"), arg0->zDb, arg0->zName, local4)
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
    End If
    fts3DbExec(CPtr(c2fb_c_int Ptr, @(local0)), local2, StrPtr(!"CREATE TABLE %Q.'%q_segments'(blockid INTEGER PRIMARY KEY, block BLOB);"), arg0->zDb, arg0->zName)
    fts3DbExec(CPtr(c2fb_c_int Ptr, @(local0)), local2, StrPtr(!"CREATE TABLE %Q.'%q_segdir'(level INTEGER,idx INTEGER,start_block INTEGER,leaves_end_block INTEGER,end_block INTEGER,root BLOB,PRIMARY KEY(level, idx));"), arg0->zDb, arg0->zName)
    If arg0->bHasDocsize Then
        fts3DbExec(CPtr(c2fb_c_int Ptr, @(local0)), local2, StrPtr(!"CREATE TABLE %Q.'%q_docsize'(docid INTEGER PRIMARY KEY, size BLOB);"), arg0->zDb, arg0->zName)
    End If
    ' C unused-parameter annotation
    If arg0->bHasStat Then
        sqlite3Fts3CreateStatTable(CPtr(c2fb_c_int Ptr, @(local0)), arg0)
    End If
    Return local0
End Function
Private Sub fts3DatabasePageSize CDecl Alias "fts3DatabasePageSize" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_source_record_36 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 754
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As Any Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA %Q.page_size"), arg1->zDb))
        local1 = c2fb_temp_0
        If (-Cast(c2fb_c_int, (local1 = 0))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_1
        Else
            c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare(arg1->db, CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Any Ptr Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_2
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_external_sqlite3_step(local2)
                c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg1->nPgsz))
                c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_int(local2, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_3) = c2fb_temp_4
                c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize(local2))
                local0 = c2fb_temp_5
            Else
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 23ULL))))) Then
                    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg1->nPgsz))
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1024ULL))
                    (*c2fb_temp_6) = c2fb_temp_7
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local0 = c2fb_temp_8
                End If
            End If
        End If
        ' C unused-parameter annotation
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg0)))
        c2fb_temp_10 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_9) = c2fb_temp_10
    End If
End Sub
Private Function fts3IsSpecialColumn CDecl Alias "fts3IsSpecialColumn" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 788
    Dim local0 As ZString Ptr
    Dim local1 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr

    ' C automatic storage declaration
    local1 = arg0
    While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local1))) <> Cast(c2fb_c_int, 61)))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local1))) = Cast(c2fb_c_int, 0))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        c2fb_temp_0 = local1
        local1 = (c2fb_temp_0 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Const Byte Ptr, local1)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, arg0))))))
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s"), CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local1)[Cast(c2fb_c_int, 1ULL)]))))
    local0 = c2fb_temp_3
    If local0 Then
        sqlite3Fts3Dequote(local0)
    End If
    c2fb_temp_4 = CPtr(ZString Ptr Ptr, @((*arg2)))
    c2fb_temp_5 = local0
    (*c2fb_temp_4) = c2fb_temp_5
    Return Cast(c2fb_c_int, 1ULL)
End Function
Private Sub fts3Appendf CDecl Alias "fts3Appendf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As Const ZString Ptr, ...)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 813
    Dim local0 As Cva_List
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr

    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        Cva_Start(local0, arg2)
        c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg2, local0))
        local1 = c2fb_temp_0
        Cva_End(local0)
        If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((*arg1) <> 0))))) Then
            local2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s%s"), (*arg1), local1))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
            c2fb_temp_1 = local2
            local1 = c2fb_temp_1
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_2) = c2fb_temp_3
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, (*arg1)))
        c2fb_temp_4 = CPtr(ZString Ptr Ptr, @((*arg1)))
        c2fb_temp_5 = local1
        (*c2fb_temp_4) = c2fb_temp_5
    End If
End Sub
Private Function fts3QuoteId CDecl Alias "fts3QuoteId" (ByVal arg0 As Const ZString Ptr) As ZString Ptr
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 846
    Dim local0 As c2fb_int64
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As Byte Ptr
    Dim c2fb_temp_4 As Byte
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As Byte Ptr
    Dim c2fb_temp_9 As Byte
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As Byte Ptr
    Dim c2fb_temp_12 As Byte
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As Byte Ptr
    Dim c2fb_temp_15 As Byte
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As Byte Ptr
    Dim c2fb_temp_18 As Byte

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_crt_strlen(arg0)) * Cast(c2fb_c_int, 2ULL))))) + Cast(c2fb_c_int, 1ULL))))
    local0 = c2fb_temp_0
    c2fb_temp_1 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local0)))
    local1 = c2fb_temp_1
    If local1 Then
        ' C automatic storage declaration
        local3 = local1
        c2fb_temp_2 = local3
        local3 = (c2fb_temp_2 + 1)
        c2fb_temp_3 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, (c2fb_temp_2)))))
        c2fb_temp_4 = Cast(Byte, Cast(c2fb_c_int, 34))
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_5
        While CPtr(Const Byte Ptr, arg0)[local2]
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local2]) = Cast(c2fb_c_int, 34))))) Then
                c2fb_temp_7 = local3
                local3 = (c2fb_temp_7 + 1)
                c2fb_temp_8 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, (c2fb_temp_7)))))
                c2fb_temp_9 = Cast(Byte, Cast(c2fb_c_int, 34))
                (*c2fb_temp_8) = c2fb_temp_9
            End If
            c2fb_temp_10 = local3
            local3 = (c2fb_temp_10 + 1)
            c2fb_temp_11 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, (c2fb_temp_10)))))
            c2fb_temp_12 = Cast(Byte, CPtr(Const Byte Ptr, arg0)[local2])
            (*c2fb_temp_11) = c2fb_temp_12
        c2fb_flow_1:
            c2fb_temp_6 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_13 = local3
        local3 = (c2fb_temp_13 + 1)
        c2fb_temp_14 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, (c2fb_temp_13)))))
        c2fb_temp_15 = Cast(Byte, Cast(c2fb_c_int, 34))
        (*c2fb_temp_14) = c2fb_temp_15
        c2fb_temp_16 = local3
        local3 = (c2fb_temp_16 + 1)
        c2fb_temp_17 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, (c2fb_temp_16)))))
        c2fb_temp_18 = Cast(Byte, Cast(c2fb_c_int, 0))
        (*c2fb_temp_17) = c2fb_temp_18
    End If
    Return local1
End Function
Private Function fts3ReadExprList CDecl Alias "fts3ReadExprList" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr) As ZString Ptr
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 888
    Dim local0 As ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg0->zContentTbl = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, (arg1 = 0))) Then
            c2fb_temp_0 = CPtr(ZString Ptr, StrPtr(!""))
            local2 = c2fb_temp_0
        Else
            c2fb_temp_1 = CPtr(ZString Ptr, fts3QuoteId(arg1))
            local2 = c2fb_temp_1
            c2fb_temp_2 = c2fb_temp_1
            local1 = c2fb_temp_2
        End If
        fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!"docid"))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local3 < arg0->nColumn))))
            fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!",%s(x.'c%d%q')"), local2, local3, arg0->azColumn[local3])
        c2fb_flow_1:
            c2fb_temp_4 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_0:
        If arg0->zLanguageid Then
            fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!", x.%Q"), StrPtr(!"langid"))
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    Else
        fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!"rowid"))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_5
        While (-Cast(c2fb_c_int, ((local3 < arg0->nColumn))))
            fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!", x.'%q'"), arg0->azColumn[local3])
        c2fb_flow_3:
            c2fb_temp_6 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        Wend
        c2fb_flow_2:
        If arg0->zLanguageid Then
            fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!", x.%Q"), arg0->zLanguageid)
        End If
    End If
    fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!" FROM '%q'.'%q%s' AS x"), arg0->zDb, (IIf(arg0->zContentTbl, CPtr(Const ZString Ptr, arg0->zContentTbl), arg0->zName)), (IIf(arg0->zContentTbl, StrPtr(!""), StrPtr(!"_content"))))
    Return local0
End Function
Private Function fts3WriteExprList CDecl Alias "fts3WriteExprList" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr) As ZString Ptr
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 945
    Dim local0 As ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, (arg1 = 0))) Then
        c2fb_temp_0 = CPtr(ZString Ptr, StrPtr(!""))
        local2 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(ZString Ptr, fts3QuoteId(arg1))
        local2 = c2fb_temp_1
        c2fb_temp_2 = c2fb_temp_1
        local1 = c2fb_temp_2
    End If
    fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!"?"))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_3
    While (-Cast(c2fb_c_int, ((local3 < arg0->nColumn))))
        fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!",%s(?)"), local2)
    c2fb_flow_1:
        c2fb_temp_4 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    Wend
    c2fb_flow_0:
    If arg0->zLanguageid Then
        fts3Appendf(arg2, CPtr(ZString Ptr Ptr, @(local0)), StrPtr(!", ?"))
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    Return local0
End Function
Function sqlite3Fts3ReadInt CDecl Alias "sqlite3Fts3ReadInt" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 972
    Dim local0 As c2fb_uint64
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_uint64
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local1]) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local1]) <= Cast(c2fb_c_int, 57))))) <> 0)))))
        c2fb_temp_2 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (local0 * Cast(c2fb_uint64, Cast(c2fb_c_int, 10ULL)))) + Cast(c2fb_uint64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local1]) - Cast(c2fb_c_int, 48))))))))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_uint64, Cast(c2fb_c_int, &H7FFFFFFFULL)))))) Then
            Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, local0))
    (*c2fb_temp_3) = c2fb_temp_4
    Return local1
End Function
Private Function fts3GobbleInt CDecl Alias "fts3GobbleInt" (ByVal arg0 As Const ZString Ptr Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 996
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Const ZString Ptr Ptr
    Dim c2fb_temp_5 As Const ZString Ptr

    local0 = Cast(c2fb_c_int, 10000000ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, sqlite3Fts3ReadInt((*arg0), CPtr(c2fb_c_int Ptr, @(local1))))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 > local0)))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_3 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(Const ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_5 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, (*c2fb_temp_4)) + local2))
    (*c2fb_temp_4) = c2fb_temp_5
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3PrefixParameter CDecl Alias "fts3PrefixParameter" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_source_record_35 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1029
    Dim local0 As c2fb_source_record_35 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_source_record_35 Ptr
    Dim c2fb_temp_5 As c2fb_source_record_35 Ptr Ptr
    Dim c2fb_temp_6 As c2fb_source_record_35 Ptr
    Dim c2fb_temp_7 As Any Ptr
    Dim local3 As Const ZString Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, 1ULL)
    If (-Cast(c2fb_c_int, (((arg0 <> 0) AndAlso (CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)] <> 0))))) Then
        ' C automatic storage declaration
        c2fb_temp_0 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        c2fb_temp_1 = arg0
        local2 = c2fb_temp_1
        While (*CPtr(Const Byte Ptr, local2))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local2))) = Cast(c2fb_c_int, 44))))) Then
                c2fb_temp_3 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            End If
        c2fb_flow_1:
            c2fb_temp_2 = local2
            local2 = (c2fb_temp_2 + 1)
        Wend
        c2fb_flow_0:
    End If
    c2fb_temp_4 = CPtr(c2fb_source_record_35 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_35))) * Cast(c2fb_uint64, local1))))))
    local0 = c2fb_temp_4
    c2fb_temp_5 = CPtr(c2fb_source_record_35 Ptr Ptr, @((*arg2)))
    c2fb_temp_6 = local0
    (*c2fb_temp_5) = c2fb_temp_6
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_35))) * Cast(c2fb_uint64, local1)))))
    If arg0 Then
        local3 = arg0
        ' C automatic storage declaration
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local4 = c2fb_temp_8
        While (-Cast(c2fb_c_int, ((local4 < local1))))
            local5 = Cast(c2fb_c_int, &O0ULL)
            If fts3GobbleInt(CPtr(Const ZString Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local5))) Then
                Return Cast(c2fb_c_int, 1ULL)
            End If
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_10 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 - 1)))
                c2fb_temp_11 = local4
                local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 - 1)))
            Else
                c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @(local0[local4].nPrefix))
                c2fb_temp_13 = Cast(c2fb_c_int, local5)
                (*c2fb_temp_12) = c2fb_temp_13
            End If
            c2fb_temp_14 = local3
            local3 = (c2fb_temp_14 + 1)
        c2fb_flow_3:
            c2fb_temp_9 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
        Wend
        c2fb_flow_2:
    End If
    c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_16 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_15) = c2fb_temp_16
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3ContentColumns CDecl Alias "fts3ContentColumns" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1098
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As Any Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local3 As Const ZString Ptr Ptr
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local7 As Const ZString Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As Const ZString Ptr Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local9 As Const ZString Ptr
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As Const ZString Ptr Ptr
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_20 As Const ZString Ptr Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT * FROM %Q.%Q"), arg1, arg2))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local1 = 0))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_1
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare(arg0, CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Any Ptr Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            sqlite3Fts3ErrMsg(arg6, StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(arg0)))
        End If
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        local4 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_count(local2))
        local5 = c2fb_temp_3
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local6 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((local6 < local5))))
            local7 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_column_name(local2, local6))
            ' C unused-parameter annotation
            c2fb_temp_6 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, local4) + Cast(c2fb_uint64, (Cast(c2fb_uint64, c2fb_crt_strlen(local7)) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))))
            local4 = c2fb_temp_6
        c2fb_flow_1:
            c2fb_temp_5 = local6
            local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_7 = CPtr(Const ZString Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))) * Cast(c2fb_uint64, local5))) + Cast(c2fb_uint64, local4))))))
        local3 = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_8
        Else
            local8 = CPtr(ZString Ptr, CPtr(Const ZString Ptr Ptr, @(local3[local5])))
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local6 = c2fb_temp_9
            While (-Cast(c2fb_c_int, ((local6 < local5))))
                local9 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_column_name(local2, local6))
                local10 = Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_crt_strlen(local9)) + Cast(c2fb_c_int, 1ULL)))
                ' C unused-parameter annotation
                c2fb_temp_11 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local8), CPtr(Const Any Ptr, local9), local10))
                c2fb_temp_12 = CPtr(Const ZString Ptr Ptr, @(local3[local6]))
                c2fb_temp_13 = CPtr(Const ZString Ptr, local8)
                (*c2fb_temp_12) = c2fb_temp_13
                c2fb_temp_14 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local8) + local10))
                local8 = c2fb_temp_14
            c2fb_flow_3:
                c2fb_temp_10 = local6
                local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
            Wend
            c2fb_flow_2:
        End If
        c2fb_external_sqlite3_finalize(local2)
        c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_16 = Cast(c2fb_c_int, local5)
        (*c2fb_temp_15) = c2fb_temp_16
        c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @((*arg5)))
        c2fb_temp_18 = Cast(c2fb_c_int, local4)
        (*c2fb_temp_17) = c2fb_temp_18
        c2fb_temp_19 = CPtr(Const ZString Ptr Ptr Ptr, @((*arg3)))
        c2fb_temp_20 = local3
        (*c2fb_temp_19) = c2fb_temp_20
    End If
    Return local0
End Function
Private Function fts3InitVtab CDecl Alias "fts3InitVtab" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Any Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As c2fb_source_record_27 Ptr Ptr, ByVal arg6 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1177
    Dim local0 As c2fb_source_record_33 Ptr
    Dim local1 As c2fb_source_record_36 Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As Const ZString Ptr Ptr
    Dim local13 As Fts3Tokenizer Ptr
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_source_record_35 Ptr
    Dim local16 As c2fb_c_int
    Dim local17 As c2fb_c_int
    Dim local18 As ZString Ptr
    Dim local19 As ZString Ptr
    Dim local20 As ZString Ptr
    Dim local21 As ZString Ptr
    Dim local22 As ZString Ptr
    Dim local23 As ZString Ptr Ptr
    Dim local24 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As Const ZString Ptr Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local25 As Const ZString Ptr
    Dim local26 As c2fb_c_int
    Dim local27 As ZString Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local28(0 To 7) As c2fb_local_record_47
    Dim local29 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local30 As c2fb_local_record_47 Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As ZString Ptr
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As ZString Ptr
    Dim c2fb_temp_25 As ZString Ptr
    Dim c2fb_temp_26 As ZString Ptr
    Dim c2fb_temp_27 As ZString Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As ZString Ptr Ptr
    Dim c2fb_temp_30 As ZString Ptr
    Dim c2fb_temp_31 As ZString Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Const ZString Ptr Ptr
    Dim c2fb_temp_36 As Const ZString Ptr
    Dim c2fb_temp_37 As ZString Ptr
    Dim c2fb_temp_38 As ZString Ptr
    Dim c2fb_temp_39 As Const ZString Ptr Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim local31 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim local32 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As Const ZString Ptr Ptr
    Dim c2fb_temp_46 As Const ZString Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As Const ZString Ptr Ptr
    Dim c2fb_temp_49 As Const ZString Ptr
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As c2fb_c_int
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As c2fb_int64
    Dim c2fb_temp_55 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As Any Ptr
    Dim c2fb_temp_58 As Any Ptr Ptr
    Dim c2fb_temp_59 As Any Ptr
    Dim c2fb_temp_60 As c2fb_c_int Ptr
    Dim c2fb_temp_61 As c2fb_c_int
    Dim c2fb_temp_62 As c2fb_c_int Ptr
    Dim c2fb_temp_63 As c2fb_c_int
    Dim c2fb_temp_64 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_65 As ZString Ptr Ptr
    Dim c2fb_temp_66 As Fts3Tokenizer Ptr Ptr
    Dim c2fb_temp_67 As Fts3Tokenizer Ptr
    Dim c2fb_temp_68 As c2fb_c_int Ptr
    Dim c2fb_temp_69 As c2fb_c_int
    Dim c2fb_temp_70 As UByte Ptr
    Dim c2fb_temp_71 As UByte
    Dim c2fb_temp_72 As UByte Ptr
    Dim c2fb_temp_73 As UByte
    Dim c2fb_temp_74 As UByte Ptr
    Dim c2fb_temp_75 As UByte
    Dim c2fb_temp_76 As UByte Ptr
    Dim c2fb_temp_77 As UByte
    Dim c2fb_temp_78 As c2fb_c_int Ptr
    Dim c2fb_temp_79 As c2fb_c_int
    Dim c2fb_temp_80 As ZString Ptr Ptr
    Dim c2fb_temp_81 As ZString Ptr
    Dim c2fb_temp_82 As ZString Ptr Ptr
    Dim c2fb_temp_83 As ZString Ptr
    Dim c2fb_temp_84 As ZString Ptr
    Dim c2fb_temp_85 As ZString Ptr
    Dim c2fb_temp_86 As c2fb_source_record_35 Ptr Ptr
    Dim c2fb_temp_87 As c2fb_source_record_35 Ptr
    Dim c2fb_temp_88 As Any Ptr
    Dim c2fb_temp_89 As c2fb_c_int Ptr
    Dim c2fb_temp_90 As c2fb_c_int
    Dim c2fb_temp_91 As c2fb_c_int
    Dim c2fb_temp_92 As c2fb_c_int
    Dim c2fb_temp_93 As UByte Ptr Ptr
    Dim c2fb_temp_94 As UByte Ptr
    Dim c2fb_temp_95 As ZString Ptr
    Dim c2fb_temp_96 As Const ZString Ptr Ptr
    Dim c2fb_temp_97 As Const ZString Ptr
    Dim c2fb_temp_98 As Any Ptr
    Dim c2fb_temp_99 As ZString Ptr
    Dim c2fb_temp_100 As Const ZString Ptr Ptr
    Dim c2fb_temp_101 As Const ZString Ptr
    Dim c2fb_temp_102 As Any Ptr
    Dim c2fb_temp_103 As ZString Ptr
    Dim c2fb_temp_104 As c2fb_c_int
    Dim c2fb_temp_105 As c2fb_c_int
    Dim local33 As ZString Ptr
    Dim local34 As c2fb_c_int
    Dim c2fb_temp_106 As ZString Ptr
    Dim c2fb_temp_107 As Any Ptr
    Dim c2fb_temp_108 As Byte Ptr
    Dim c2fb_temp_109 As Byte
    Dim c2fb_temp_110 As ZString Ptr Ptr
    Dim c2fb_temp_111 As ZString Ptr
    Dim c2fb_temp_112 As ZString Ptr
    Dim c2fb_temp_113 As c2fb_c_int
    Dim c2fb_temp_114 As c2fb_c_int
    Dim local35 As c2fb_c_int
    Dim c2fb_temp_115 As c2fb_c_int
    Dim c2fb_temp_116 As c2fb_c_int
    Dim local36 As ZString Ptr
    Dim c2fb_temp_117 As UByte Ptr
    Dim c2fb_temp_118 As UByte
    Dim c2fb_temp_119 As ZString Ptr Ptr
    Dim c2fb_temp_120 As ZString Ptr
    Dim c2fb_temp_121 As c2fb_c_int
    Dim c2fb_temp_122 As c2fb_c_int
    Dim c2fb_temp_123 As c2fb_c_int
    Dim local37 As Const ZString Ptr
    Dim c2fb_temp_124 As c2fb_c_int
    Dim c2fb_temp_125 As ZString Ptr Ptr
    Dim c2fb_temp_126 As ZString Ptr
    Dim c2fb_temp_127 As ZString Ptr Ptr
    Dim c2fb_temp_128 As ZString Ptr
    Dim c2fb_temp_129 As c2fb_c_int
    Dim c2fb_temp_130 As UByte Ptr
    Dim c2fb_temp_131 As UByte
    Dim c2fb_temp_132 As c2fb_c_int Ptr
    Dim c2fb_temp_133 As c2fb_c_int
    Dim c2fb_temp_134 As c2fb_c_int
    Dim c2fb_temp_135 As c2fb_c_int
    Dim c2fb_temp_136 As c2fb_source_record_27 Ptr Ptr
    Dim c2fb_temp_137 As c2fb_source_record_27 Ptr

    local0 = CPtr(c2fb_source_record_33 Ptr, @((CPtr(c2fb_source_record_43 Ptr, arg2))->hash))
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local11 = ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg4[Cast(c2fb_c_int, &O0ULL)])[Cast(c2fb_c_int, 3ULL)]) = Cast(c2fb_c_int, 52))))))
    ' C automatic storage declaration
    local13 = Cast(c2fb_c_int, &O0ULL)
    local14 = Cast(c2fb_c_int, &O0ULL)
    local15 = Cast(c2fb_c_int, &O0ULL)
    local16 = Cast(c2fb_c_int, &O0ULL)
    local17 = Cast(c2fb_c_int, &O0ULL)
    local18 = Cast(c2fb_c_int, &O0ULL)
    local19 = Cast(c2fb_c_int, &O0ULL)
    local20 = Cast(c2fb_c_int, &O0ULL)
    local21 = Cast(c2fb_c_int, &O0ULL)
    local22 = Cast(c2fb_c_int, &O0ULL)
    local23 = Cast(c2fb_c_int, &O0ULL)
    local24 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_crt_strlen(arg4[Cast(c2fb_c_int, 1ULL)])) + Cast(c2fb_c_int, 1ULL))))
    local9 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_crt_strlen(arg4[Cast(c2fb_c_int, 2ULL)])) + Cast(c2fb_c_int, 1ULL))))
    local10 = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Const ZString Ptr))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (arg3 - Cast(c2fb_c_int, 2ULL))))))))
    local4 = c2fb_temp_2
    c2fb_temp_3 = CPtr(Const ZString Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local4)))
    local12 = c2fb_temp_3
    If local12 Then
        c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local12), Cast(c2fb_c_int, &O0ULL), local4))
        c2fb_temp_5 = CPtr(ZString Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local4)))
        local23 = c2fb_temp_5
    End If
    If local23 Then
        c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local23), Cast(c2fb_c_int, &O0ULL), local4))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local12 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, (local23 = 0))) <> 0))))) Then
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_7
        Goto c2fb_label_0
    End If
    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
    local3 = c2fb_temp_8
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 < arg3)))) <> 0)))))
        local25 = arg4[local3]
        ' C automatic storage declaration
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local13 = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_uint64, c2fb_crt_strlen(local25)) > Cast(c2fb_uint64, Cast(c2fb_c_int, 8ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_strnicmp(local25, StrPtr(!"tokenize"), Cast(c2fb_c_int, 8ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3Fts3IsIdChar(CPtr(Const Byte Ptr, local25)[Cast(c2fb_c_int, 8ULL)]))))) <> 0))))) Then
            c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3InitTokenizer(local0, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local25)[Cast(c2fb_c_int, 9ULL)]))), CPtr(Fts3Tokenizer Ptr Ptr, @(local13)), arg6))
            local2 = c2fb_temp_10
        Else
            If (-Cast(c2fb_c_int, (((local11 <> 0) AndAlso (fts3IsSpecialColumn(local25, CPtr(c2fb_c_int Ptr, @(local26)), CPtr(ZString Ptr Ptr, @(local27))) <> 0))))) Then
                Erase local28
                local28(0) = Type<c2fb_local_record_47>( StrPtr(!"matchinfo"), Cast(c2fb_c_int, 9ULL) )
                local28(1) = Type<c2fb_local_record_47>( StrPtr(!"prefix"), Cast(c2fb_c_int, 6ULL) )
                local28(2) = Type<c2fb_local_record_47>( StrPtr(!"compress"), Cast(c2fb_c_int, 8ULL) )
                local28(3) = Type<c2fb_local_record_47>( StrPtr(!"uncompress"), Cast(c2fb_c_int, 10ULL) )
                local28(4) = Type<c2fb_local_record_47>( StrPtr(!"order"), Cast(c2fb_c_int, 5ULL) )
                local28(5) = Type<c2fb_local_record_47>( StrPtr(!"content"), Cast(c2fb_c_int, 7ULL) )
                local28(6) = Type<c2fb_local_record_47>( StrPtr(!"languageid"), Cast(c2fb_c_int, 10ULL) )
                local28(7) = Type<c2fb_local_record_47>( StrPtr(!"notindexed"), Cast(c2fb_c_int, 10ULL) )
                ' C automatic storage declaration
                If (-Cast(c2fb_c_int, (local27 = 0))) Then
                    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    local2 = c2fb_temp_11
                Else
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local29 = c2fb_temp_12
                    While (-Cast(c2fb_c_int, ((local29 < (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (8ULL * SizeOf(c2fb_local_record_47)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_local_record_47))))))))))))
                        local30 = CPtr(c2fb_local_record_47 Ptr, @(local28(local29)))
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local26 = local30->nOpt)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (c2fb_external_sqlite3_strnicmp(local25, local30->zOpt, local30->nOpt) = 0))) <> 0))))) Then
                            Goto c2fb_flow_2
                        End If
                    c2fb_flow_3:
                        c2fb_temp_13 = local29
                        local29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                    Wend
                    c2fb_flow_2:
                    Select Case local29
                        Case Cast(c2fb_c_int, &O0ULL)
                            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_uint64, c2fb_crt_strlen(CPtr(Const ZString Ptr, local27))) <> Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL)))))) <> 0) OrElse (c2fb_external_sqlite3_strnicmp(CPtr(Const ZString Ptr, local27), StrPtr(!"fts3"), Cast(c2fb_c_int, 4ULL)) <> 0))))) Then
                                sqlite3Fts3ErrMsg(arg6, StrPtr(!"unrecognized matchinfo: %s"), local27)
                                c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                local2 = c2fb_temp_14
                            End If
                            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local16 = c2fb_temp_15
                        Case Cast(c2fb_c_int, 1ULL)
                            c2fb_external_sqlite3_free(CPtr(Any Ptr, local18))
                            c2fb_temp_16 = local27
                            local18 = c2fb_temp_16
                            c2fb_temp_17 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local27 = c2fb_temp_17
                        Case Cast(c2fb_c_int, 2ULL)
                            c2fb_external_sqlite3_free(CPtr(Any Ptr, local19))
                            c2fb_temp_18 = local27
                            local19 = c2fb_temp_18
                            c2fb_temp_19 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local27 = c2fb_temp_19
                        Case Cast(c2fb_c_int, 3ULL)
                            c2fb_external_sqlite3_free(CPtr(Any Ptr, local20))
                            c2fb_temp_20 = local27
                            local20 = c2fb_temp_20
                            c2fb_temp_21 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local27 = c2fb_temp_21
                        Case Cast(c2fb_c_int, 4ULL)
                            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_uint64, c2fb_crt_strlen(CPtr(Const ZString Ptr, local27))) <> Cast(c2fb_uint64, Cast(c2fb_c_int, 3ULL)))))) <> 0) OrElse (c2fb_external_sqlite3_strnicmp(CPtr(Const ZString Ptr, local27), StrPtr(!"asc"), Cast(c2fb_c_int, 3ULL)) <> 0)))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_uint64, c2fb_crt_strlen(CPtr(Const ZString Ptr, local27))) <> Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL)))))) <> 0) OrElse (c2fb_external_sqlite3_strnicmp(CPtr(Const ZString Ptr, local27), StrPtr(!"desc"), Cast(c2fb_c_int, 4ULL)) <> 0)))))) <> 0))))) Then
                                sqlite3Fts3ErrMsg(arg6, StrPtr(!"unrecognized order: %s"), local27)
                                c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                local2 = c2fb_temp_22
                            End If
                            c2fb_temp_23 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local27)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 100))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local27)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 68))))) <> 0)))))))
                            local17 = c2fb_temp_23
                        Case Cast(c2fb_c_int, 5ULL)
                            c2fb_external_sqlite3_free(CPtr(Any Ptr, local21))
                            c2fb_temp_24 = local27
                            local21 = c2fb_temp_24
                            c2fb_temp_25 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local27 = c2fb_temp_25
                        Case Cast(c2fb_c_int, 6ULL)
                            ' C unused-parameter annotation
                            c2fb_external_sqlite3_free(CPtr(Any Ptr, local22))
                            c2fb_temp_26 = local27
                            local22 = c2fb_temp_26
                            c2fb_temp_27 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local27 = c2fb_temp_27
                        Case Cast(c2fb_c_int, 7ULL)
                            c2fb_temp_28 = local24
                            local24 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
                            c2fb_temp_29 = CPtr(ZString Ptr Ptr, @(local23[c2fb_temp_28]))
                            c2fb_temp_30 = local27
                            (*c2fb_temp_29) = c2fb_temp_30
                            c2fb_temp_31 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local27 = c2fb_temp_31
                        Case Else
                            ' C unused-parameter annotation
                            sqlite3Fts3ErrMsg(arg6, StrPtr(!"unrecognized parameter: %s"), local25)
                            c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local2 = c2fb_temp_32
                    End Select
                    c2fb_flow_4:
                    c2fb_external_sqlite3_free(CPtr(Any Ptr, local27))
                End If
            Else
                c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, c2fb_crt_strlen(local25)) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))))))
                local6 = c2fb_temp_33
                c2fb_temp_34 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_34 + 1)))
                c2fb_temp_35 = CPtr(Const ZString Ptr Ptr, @(local12[c2fb_temp_34]))
                c2fb_temp_36 = local25
                (*c2fb_temp_35) = c2fb_temp_36
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_9 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local21 <> 0))))) Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local19))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local20))
        c2fb_temp_37 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local19 = c2fb_temp_37
        c2fb_temp_38 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local20 = c2fb_temp_38
        If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local12))
            c2fb_temp_39 = CPtr(Const ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local12 = c2fb_temp_39
            c2fb_temp_40 = Cast(c2fb_c_int, fts3ContentColumns(arg1, arg4[Cast(c2fb_c_int, 1ULL)], CPtr(Const ZString Ptr, local21), CPtr(Const ZString Ptr Ptr Ptr, @(local12)), CPtr(c2fb_c_int Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local6)), arg6))
            local2 = c2fb_temp_40
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local22 <> 0))))) Then
                ' C automatic storage declaration
                c2fb_temp_41 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local31 = c2fb_temp_41
                While (-Cast(c2fb_c_int, ((local31 < local7))))
                    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, local22), local12[local31]) = Cast(c2fb_c_int, &O0ULL))))) Then
                        ' C automatic storage declaration
                        c2fb_temp_43 = Cast(c2fb_c_int, local31)
                        local32 = c2fb_temp_43
                        While (-Cast(c2fb_c_int, ((local32 < local7))))
                            c2fb_temp_45 = CPtr(Const ZString Ptr Ptr, @(local12[local32]))
                            c2fb_temp_46 = local12[Cast(c2fb_c_int, (local32 + Cast(c2fb_c_int, 1ULL)))]
                            (*c2fb_temp_45) = c2fb_temp_46
                        c2fb_flow_8:
                            c2fb_temp_44 = local32
                            local32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_44 + 1)))
                        Wend
                        c2fb_flow_7:
                        c2fb_temp_47 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_47 - 1)))
                        Goto c2fb_flow_5
                    End If
                c2fb_flow_6:
                    c2fb_temp_42 = local31
                    local31 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_42 + 1)))
                Wend
                c2fb_flow_5:
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_48 = CPtr(Const ZString Ptr Ptr, @(local12[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_49 = StrPtr(!"content")
        (*c2fb_temp_48) = c2fb_temp_49
        c2fb_temp_50 = Cast(c2fb_c_int, Cast(c2fb_c_int, 8ULL))
        local6 = c2fb_temp_50
        c2fb_temp_51 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local7 = c2fb_temp_51
    End If
    If (-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_52 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3InitTokenizer(local0, StrPtr(!"simple"), CPtr(Fts3Tokenizer Ptr Ptr, @(local13)), arg6))
        local2 = c2fb_temp_52
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_label_0
        End If
    End If
    ' C unused-parameter annotation
    c2fb_temp_53 = Cast(c2fb_c_int, fts3PrefixParameter(CPtr(Const ZString Ptr, local18), CPtr(c2fb_c_int Ptr, @(local14)), CPtr(c2fb_source_record_35 Ptr Ptr, @(local15))))
    local2 = c2fb_temp_53
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) Then
        ' C unused-parameter annotation
        sqlite3Fts3ErrMsg(arg6, StrPtr(!"error parsing prefix parameter: %s"), local18)
    End If
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    c2fb_temp_54 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_36))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, local7) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))))))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, local14) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_35))))))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, local7) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(UByte))))))) + Cast(c2fb_uint64, local10))) + Cast(c2fb_uint64, local9))) + Cast(c2fb_uint64, local6))))
    local4 = c2fb_temp_54
    c2fb_temp_55 = CPtr(c2fb_source_record_36 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local4)))
    local1 = c2fb_temp_55
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_56 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_56
        Goto c2fb_label_0
    End If
    c2fb_temp_57 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), local4))
    c2fb_temp_58 = CPtr(Any Ptr Ptr, @(local1->db))
    c2fb_temp_59 = arg1
    (*c2fb_temp_58) = c2fb_temp_59
    c2fb_temp_60 = CPtr(c2fb_c_int Ptr, @(local1->nColumn))
    c2fb_temp_61 = Cast(c2fb_c_int, local7)
    (*c2fb_temp_60) = c2fb_temp_61
    c2fb_temp_62 = CPtr(c2fb_c_int Ptr, @(local1->nPendingData))
    c2fb_temp_63 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_62) = c2fb_temp_63
    c2fb_temp_64 = CPtr(ZString Ptr Ptr Ptr, @(local1->azColumn))
    c2fb_temp_65 = CPtr(ZString Ptr Ptr, CPtr(c2fb_source_record_36 Ptr, @(local1[Cast(c2fb_c_int, 1ULL)])))
    (*c2fb_temp_64) = c2fb_temp_65
    c2fb_temp_66 = CPtr(Fts3Tokenizer Ptr Ptr, @(local1->pTokenizer))
    c2fb_temp_67 = local13
    (*c2fb_temp_66) = c2fb_temp_67
    c2fb_temp_68 = CPtr(c2fb_c_int Ptr, @(local1->nMaxPendingData))
    c2fb_temp_69 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) * Cast(c2fb_c_int, 1024ULL))) * Cast(c2fb_c_int, 1024ULL)))))
    (*c2fb_temp_68) = c2fb_temp_69
    c2fb_temp_70 = CPtr(UByte Ptr, @(local1->bHasDocsize))
    c2fb_temp_71 = Cast(UByte, ((-Cast(c2fb_c_int, (((local11 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local16 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))))
    (*c2fb_temp_70) = c2fb_temp_71
    c2fb_temp_72 = CPtr(UByte Ptr, @(local1->bHasStat))
    c2fb_temp_73 = Cast(UByte, Cast(UByte, local11))
    (*c2fb_temp_72) = c2fb_temp_73
    c2fb_temp_74 = CPtr(UByte Ptr, @(local1->bFts4))
    c2fb_temp_75 = Cast(UByte, Cast(UByte, local11))
    (*c2fb_temp_74) = c2fb_temp_75
    c2fb_temp_76 = CPtr(UByte Ptr, @(local1->bDescIdx))
    c2fb_temp_77 = Cast(UByte, Cast(UByte, local17))
    (*c2fb_temp_76) = c2fb_temp_77
    c2fb_temp_78 = CPtr(c2fb_c_int Ptr, @(local1->nAutoincrmerge))
    c2fb_temp_79 = Cast(c2fb_c_int, Cast(c2fb_c_int, &HffULL))
    (*c2fb_temp_78) = c2fb_temp_79
    c2fb_temp_80 = CPtr(ZString Ptr Ptr, @(local1->zContentTbl))
    c2fb_temp_81 = local21
    (*c2fb_temp_80) = c2fb_temp_81
    c2fb_temp_82 = CPtr(ZString Ptr Ptr, @(local1->zLanguageid))
    c2fb_temp_83 = local22
    (*c2fb_temp_82) = c2fb_temp_83
    c2fb_temp_84 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    local21 = c2fb_temp_84
    c2fb_temp_85 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    local22 = c2fb_temp_85
    ' empty C statement
    ' empty C statement
    c2fb_temp_86 = CPtr(c2fb_source_record_35 Ptr Ptr, @(local1->aIndex))
    c2fb_temp_87 = CPtr(c2fb_source_record_35 Ptr, CPtr(ZString Ptr Ptr, @(local1->azColumn[local7])))
    (*c2fb_temp_86) = c2fb_temp_87
    c2fb_temp_88 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->aIndex), CPtr(Const Any Ptr, local15), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_35))) * Cast(c2fb_uint64, local14)))))
    c2fb_temp_89 = CPtr(c2fb_c_int Ptr, @(local1->nIndex))
    c2fb_temp_90 = Cast(c2fb_c_int, local14)
    (*c2fb_temp_89) = c2fb_temp_90
    c2fb_temp_91 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_91
    While (-Cast(c2fb_c_int, ((local3 < local14))))
        c2fb_external_sqlite3Fts3HashInit(CPtr(c2fb_source_record_33 Ptr, @(local1->aIndex[local3].hPending)), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, 1ULL))
    c2fb_flow_10:
        c2fb_temp_92 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_92 + 1)))
    Wend
    c2fb_flow_9:
    c2fb_temp_93 = CPtr(UByte Ptr Ptr, @(local1->abNotindexed))
    c2fb_temp_94 = CPtr(UByte Ptr, CPtr(c2fb_source_record_35 Ptr, @(local1->aIndex[local14])))
    (*c2fb_temp_93) = c2fb_temp_94
    c2fb_temp_95 = CPtr(ZString Ptr, CPtr(UByte Ptr, @(local1->abNotindexed[local7])))
    local8 = c2fb_temp_95
    c2fb_temp_96 = CPtr(Const ZString Ptr Ptr, @(local1->zName))
    c2fb_temp_97 = CPtr(Const ZString Ptr, local8)
    (*c2fb_temp_96) = c2fb_temp_97
    c2fb_temp_98 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local8), CPtr(Const Any Ptr, arg4[Cast(c2fb_c_int, 2ULL)]), local10))
    c2fb_temp_99 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local8) + local10))
    local8 = c2fb_temp_99
    c2fb_temp_100 = CPtr(Const ZString Ptr Ptr, @(local1->zDb))
    c2fb_temp_101 = CPtr(Const ZString Ptr, local8)
    (*c2fb_temp_100) = c2fb_temp_101
    c2fb_temp_102 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local8), CPtr(Const Any Ptr, arg4[Cast(c2fb_c_int, 1ULL)]), local9))
    c2fb_temp_103 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local8) + local9))
    local8 = c2fb_temp_103
    c2fb_temp_104 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local5 = c2fb_temp_104
    While (-Cast(c2fb_c_int, ((local5 < local7))))
        ' C automatic storage declaration
        local34 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_106 = CPtr(ZString Ptr, CPtr(Const ZString Ptr, c2fb_external_sqlite3Fts3NextToken(local12[local5], CPtr(c2fb_c_int Ptr, @(local34)))))
        local33 = c2fb_temp_106
        If (-Cast(c2fb_c_int, ((local34 > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_107 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local8), CPtr(Const Any Ptr, local33), local34))
        End If
        c2fb_temp_108 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local8)[local34]))
        c2fb_temp_109 = Cast(Byte, Cast(c2fb_c_int, 0))
        (*c2fb_temp_108) = c2fb_temp_109
        sqlite3Fts3Dequote(local8)
        c2fb_temp_110 = CPtr(ZString Ptr Ptr, @(local1->azColumn[local5]))
        c2fb_temp_111 = local8
        (*c2fb_temp_110) = c2fb_temp_111
        c2fb_temp_112 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local8) + Cast(c2fb_c_int, (local34 + Cast(c2fb_c_int, 1ULL)))))
        local8 = c2fb_temp_112
        ' C unused-parameter annotation
    c2fb_flow_12:
        c2fb_temp_105 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_105 + 1)))
    Wend
    c2fb_flow_11:
    c2fb_temp_113 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local5 = c2fb_temp_113
    While (-Cast(c2fb_c_int, ((local5 < local7))))
        local35 = Cast(c2fb_c_int, c2fb_crt_strlen(CPtr(Const ZString Ptr, local1->azColumn[local5])))
        c2fb_temp_115 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_115
        While (-Cast(c2fb_c_int, ((local3 < local24))))
            local36 = local23[local3]
            If (-Cast(c2fb_c_int, (((local36 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local35 = Cast(c2fb_c_int, c2fb_crt_strlen(CPtr(Const ZString Ptr, local36))))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_strnicmp(CPtr(Const ZString Ptr, local1->azColumn[local5]), CPtr(Const ZString Ptr, local36), local35))))) <> 0))))) Then
                c2fb_temp_117 = CPtr(UByte Ptr, @(local1->abNotindexed[local5]))
                c2fb_temp_118 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_117) = c2fb_temp_118
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local36))
                c2fb_temp_119 = CPtr(ZString Ptr Ptr, @(local23[local3]))
                c2fb_temp_120 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_119) = c2fb_temp_120
            End If
        c2fb_flow_16:
            c2fb_temp_116 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_116 + 1)))
        Wend
        c2fb_flow_15:
    c2fb_flow_14:
        c2fb_temp_114 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_114 + 1)))
    Wend
    c2fb_flow_13:
    c2fb_temp_121 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_121
    While (-Cast(c2fb_c_int, ((local3 < local24))))
        If local23[local3] Then
            sqlite3Fts3ErrMsg(arg6, StrPtr(!"no such column: %s"), local23[local3])
            c2fb_temp_123 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local2 = c2fb_temp_123
        End If
    c2fb_flow_18:
        c2fb_temp_122 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_122 + 1)))
    Wend
    c2fb_flow_17:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local19 = Cast(c2fb_c_int, &O0ULL)))))) <> ((-Cast(c2fb_c_int, ((local20 = Cast(c2fb_c_int, &O0ULL)))))))))) <> 0))))) Then
        local37 = (IIf((-Cast(c2fb_c_int, ((local19 = Cast(c2fb_c_int, &O0ULL))))), StrPtr(!"compress"), StrPtr(!"uncompress")))
        c2fb_temp_124 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local2 = c2fb_temp_124
        sqlite3Fts3ErrMsg(arg6, StrPtr(!"missing %s parameter in fts4 constructor"), local37)
    End If
    c2fb_temp_125 = CPtr(ZString Ptr Ptr, @(local1->zReadExprlist))
    c2fb_temp_126 = CPtr(ZString Ptr, fts3ReadExprList(local1, CPtr(Const ZString Ptr, local20), CPtr(c2fb_c_int Ptr, @(local2))))
    (*c2fb_temp_125) = c2fb_temp_126
    c2fb_temp_127 = CPtr(ZString Ptr Ptr, @(local1->zWriteExprlist))
    c2fb_temp_128 = CPtr(ZString Ptr, fts3WriteExprList(local1, CPtr(Const ZString Ptr, local19), CPtr(c2fb_c_int Ptr, @(local2))))
    (*c2fb_temp_127) = c2fb_temp_128
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    If arg0 Then
        c2fb_temp_129 = Cast(c2fb_c_int, fts3CreateTables(local1))
        local2 = c2fb_temp_129
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local11 = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (arg0 = 0))) <> 0))))) Then
        c2fb_temp_130 = CPtr(UByte Ptr, @(local1->bHasStat))
        c2fb_temp_131 = Cast(UByte, Cast(c2fb_c_int, 2ULL))
        (*c2fb_temp_130) = c2fb_temp_131
    End If
    fts3DatabasePageSize(CPtr(c2fb_c_int Ptr, @(local2)), local1)
    c2fb_temp_132 = CPtr(c2fb_c_int Ptr, @(local1->nNodeSize))
    c2fb_temp_133 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1->nPgsz - Cast(c2fb_c_int, 35ULL))))
    (*c2fb_temp_132) = c2fb_temp_133
    fts3DeclareVtab(CPtr(c2fb_c_int Ptr, @(local2)), local1)
    c2fb_label_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local18))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local15))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local19))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local20))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local21))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local22))
    c2fb_temp_134 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_134
    While (-Cast(c2fb_c_int, ((local3 < local24))))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local23[local3]))
    c2fb_flow_20:
        c2fb_temp_135 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_135 + 1)))
    Wend
    c2fb_flow_19:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local12))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local23))
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        If local1 Then
            fts3DisconnectMethod(CPtr(c2fb_source_record_27 Ptr, local1))
        Else
            If local13 Then
                CPtr(c2fb_callback_78, CPtr(Const Fts3TokenizerModule Ptr, local13->pModule)->xDestroy)(local13)
            End If
        End If
    Else
        ' C unused-parameter annotation
        c2fb_temp_136 = CPtr(c2fb_source_record_27 Ptr Ptr, @((*arg5)))
        c2fb_temp_137 = CPtr(c2fb_source_record_27 Ptr, @(local1->base))
        (*c2fb_temp_136) = c2fb_temp_137
    End If
    Return local2
End Function
Private Function fts3ConnectMethod CDecl Alias "fts3ConnectMethod" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_27 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1561
    Return fts3InitVtab(Cast(c2fb_c_int, &O0ULL), arg0, arg1, arg2, arg3, arg4, arg5)
End Function
Private Function fts3CreateMethod CDecl Alias "fts3CreateMethod" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_27 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1571
    Return fts3InitVtab(Cast(c2fb_c_int, 1ULL), arg0, arg1, arg2, arg3, arg4, arg5)
End Function
Private Sub fts3SetEstimatedRows CDecl Alias "fts3SetEstimatedRows" (ByVal arg0 As c2fb_source_record_26 Ptr, ByVal arg1 As c2fb_int64)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1587
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_libversion_number() >= Cast(c2fb_c_int, 3008002ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(arg0->estimatedRows))
        c2fb_temp_1 = Cast(c2fb_int64, arg1)
        (*c2fb_temp_0) = c2fb_temp_1
    End If
End Sub
Private Sub fts3SetUniqueFlag CDecl Alias "fts3SetUniqueFlag" (ByVal arg0 As c2fb_source_record_26 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1600
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_libversion_number() >= Cast(c2fb_c_int, 3008012ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->idxFlags))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_0) Or Cast(c2fb_c_int, &H00000001ULL))))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
End Sub
Private Function fts3BestIndexMethod CDecl Alias "fts3BestIndexMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_source_record_26 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1616
    Dim local0 As c2fb_source_record_36 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Double Ptr
    Dim c2fb_temp_3 As Double
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_source_record_23 Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Double Ptr
    Dim c2fb_temp_9 As Double
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Double Ptr
    Dim c2fb_temp_14 As Double
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Double Ptr
    Dim c2fb_temp_19 As Double
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As UByte Ptr
    Dim c2fb_temp_29 As UByte
    Dim c2fb_temp_30 As c2fb_c_int Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int Ptr
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_c_int Ptr
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim local9 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_45 As ZString Ptr Ptr
    Dim c2fb_temp_46 As ZString Ptr
    Dim c2fb_temp_47 As ZString Ptr Ptr
    Dim c2fb_temp_48 As ZString Ptr
    Dim c2fb_temp_49 As c2fb_c_int Ptr
    Dim c2fb_temp_50 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local3 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local4 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local5 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    ' C automatic storage declaration
    If local0->bLock Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(Double Ptr, @(arg1->estimatedCost))
    c2fb_temp_3 = Cast(Double, Cast(c2fb_c_int, 5000000ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local1 < arg1->nConstraint))))
        ' C automatic storage declaration
        local8 = CPtr(c2fb_source_record_23 Ptr, @(arg1->aConstraint[local1]))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local8->usable) = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local8->op) = Cast(c2fb_c_int, 64ULL))))) Then
                c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_6) = c2fb_temp_7
                c2fb_temp_8 = CPtr(Double Ptr, @(arg1->estimatedCost))
                c2fb_temp_9 = Cast(Double, 1e50#)
                (*c2fb_temp_8) = c2fb_temp_9
                fts3SetEstimatedRows(arg1, Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))) Shl Cast(c2fb_c_int, 50ULL))))
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            Goto c2fb_flow_1
        End If
        c2fb_temp_10 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8->iColumn < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local8->iColumn = Cast(c2fb_c_int, (local0->nColumn + Cast(c2fb_c_int, 1ULL))))))) <> 0)))))))
        local7 = c2fb_temp_10
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local8->op) = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso (local7 <> 0))))) Then
            c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_11) = c2fb_temp_12
            c2fb_temp_13 = CPtr(Double Ptr, @(arg1->estimatedCost))
            c2fb_temp_14 = Cast(Double, 1.0#)
            (*c2fb_temp_13) = c2fb_temp_14
            c2fb_temp_15 = Cast(c2fb_c_int, local1)
            local2 = c2fb_temp_15
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local8->op) = Cast(c2fb_c_int, 64ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8->iColumn >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8->iColumn <= local0->nColumn)))) <> 0))))) Then
            c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
            c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + local8->iColumn)))
            (*c2fb_temp_16) = c2fb_temp_17
            c2fb_temp_18 = CPtr(Double Ptr, @(arg1->estimatedCost))
            c2fb_temp_19 = Cast(Double, 2.0#)
            (*c2fb_temp_18) = c2fb_temp_19
            c2fb_temp_20 = Cast(c2fb_c_int, local1)
            local2 = c2fb_temp_20
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local8->op) = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8->iColumn = Cast(c2fb_c_int, (local0->nColumn + Cast(c2fb_c_int, 2ULL))))))) <> 0))))) Then
            c2fb_temp_21 = Cast(c2fb_c_int, local1)
            local3 = c2fb_temp_21
        End If
        If local7 Then
            Select Case local8->op
                Case Cast(c2fb_c_int, 32ULL), Cast(c2fb_c_int, 4ULL)
                    c2fb_temp_22 = Cast(c2fb_c_int, local1)
                    local4 = c2fb_temp_22
                Case Cast(c2fb_c_int, 8ULL), Cast(c2fb_c_int, 16ULL)
                    c2fb_temp_23 = Cast(c2fb_c_int, local1)
                    local5 = c2fb_temp_23
            End Select
            c2fb_flow_2:
        End If
    c2fb_flow_1:
        c2fb_temp_5 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((arg1->idxNum = Cast(c2fb_c_int, 1ULL))))) Then
        fts3SetUniqueFlag(arg1)
    End If
    c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    local6 = c2fb_temp_24
    If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_26 = CPtr(c2fb_c_int Ptr, @(arg1->aConstraintUsage[local2].argvIndex))
        c2fb_temp_25 = local6
        local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_25 + 1)))
        c2fb_temp_27 = Cast(c2fb_c_int, c2fb_temp_25)
        (*c2fb_temp_26) = c2fb_temp_27
        c2fb_temp_28 = CPtr(UByte Ptr, @(arg1->aConstraintUsage[local2].omit))
        c2fb_temp_29 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_28) = c2fb_temp_29
    End If
    If (-Cast(c2fb_c_int, ((local3 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_30 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
        c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_30) Or Cast(c2fb_c_int, &H00010000ULL))))
        (*c2fb_temp_30) = c2fb_temp_31
        c2fb_temp_33 = CPtr(c2fb_c_int Ptr, @(arg1->aConstraintUsage[local3].argvIndex))
        c2fb_temp_32 = local6
        local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_32 + 1)))
        c2fb_temp_34 = Cast(c2fb_c_int, c2fb_temp_32)
        (*c2fb_temp_33) = c2fb_temp_34
    End If
    If (-Cast(c2fb_c_int, ((local4 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_35 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
        c2fb_temp_36 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_35) Or Cast(c2fb_c_int, &H00020000ULL))))
        (*c2fb_temp_35) = c2fb_temp_36
        c2fb_temp_38 = CPtr(c2fb_c_int Ptr, @(arg1->aConstraintUsage[local4].argvIndex))
        c2fb_temp_37 = local6
        local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_37 + 1)))
        c2fb_temp_39 = Cast(c2fb_c_int, c2fb_temp_37)
        (*c2fb_temp_38) = c2fb_temp_39
    End If
    If (-Cast(c2fb_c_int, ((local5 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_40 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
        c2fb_temp_41 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_40) Or Cast(c2fb_c_int, &H00040000ULL))))
        (*c2fb_temp_40) = c2fb_temp_41
        c2fb_temp_43 = CPtr(c2fb_c_int Ptr, @(arg1->aConstraintUsage[local5].argvIndex))
        c2fb_temp_42 = local6
        local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_42 + 1)))
        c2fb_temp_44 = Cast(c2fb_c_int, c2fb_temp_42)
        (*c2fb_temp_43) = c2fb_temp_44
    End If
    If (-Cast(c2fb_c_int, ((arg1->nOrderBy = Cast(c2fb_c_int, 1ULL))))) Then
        local9 = CPtr(c2fb_source_record_24 Ptr, @(arg1->aOrderBy[Cast(c2fb_c_int, &O0ULL)]))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local9->iColumn < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local9->iColumn = Cast(c2fb_c_int, (local0->nColumn + Cast(c2fb_c_int, 1ULL))))))) <> 0))))) Then
            If local9->desc Then
                c2fb_temp_45 = CPtr(ZString Ptr Ptr, @(arg1->idxStr))
                c2fb_temp_46 = CPtr(ZString Ptr, StrPtr(!"DESC"))
                (*c2fb_temp_45) = c2fb_temp_46
            Else
                c2fb_temp_47 = CPtr(ZString Ptr Ptr, @(arg1->idxStr))
                c2fb_temp_48 = CPtr(ZString Ptr, StrPtr(!"ASC"))
                (*c2fb_temp_47) = c2fb_temp_48
            End If
            c2fb_temp_49 = CPtr(c2fb_c_int Ptr, @(arg1->orderByConsumed))
            c2fb_temp_50 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_49) = c2fb_temp_50
        End If
    End If
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3OpenMethod CDecl Alias "fts3OpenMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_source_record_28 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1745
    Dim local0 As c2fb_source_record_28 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_28 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_28 Ptr Ptr
    Dim c2fb_temp_2 As c2fb_source_record_28 Ptr
    Dim c2fb_temp_3 As Any Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_1 = CPtr(c2fb_source_record_28 Ptr Ptr, @((*arg1)))
    c2fb_temp_0 = CPtr(c2fb_source_record_28 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_37)))))
    local0 = c2fb_temp_0
    c2fb_temp_2 = c2fb_temp_0
    (*c2fb_temp_1) = c2fb_temp_2
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_37))))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts3CursorFinalizeStmt CDecl Alias "fts3CursorFinalizeStmt" (ByVal arg0 As c2fb_source_record_37 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1769
    Dim local0 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte

    If arg0->bSeekStmt Then
        local0 = CPtr(c2fb_source_record_36 Ptr, arg0->base.pVtab)
        If (-Cast(c2fb_c_int, ((local0->pSeekStmt = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(Any Ptr Ptr, @(local0->pSeekStmt))
            c2fb_temp_1 = arg0->pStmt
            (*c2fb_temp_0) = c2fb_temp_1
            c2fb_external_sqlite3_reset(arg0->pStmt)
            c2fb_temp_2 = CPtr(Any Ptr Ptr, @(arg0->pStmt))
            c2fb_temp_3 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_2) = c2fb_temp_3
        End If
        c2fb_temp_4 = CPtr(UByte Ptr, @(arg0->bSeekStmt))
        c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_4) = c2fb_temp_5
    End If
    c2fb_external_sqlite3_finalize(arg0->pStmt)
End Sub
Private Sub fts3ClearCursor CDecl Alias "fts3ClearCursor" (ByVal arg0 As c2fb_source_record_37 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1786
    Dim c2fb_temp_0 As Any Ptr

    fts3CursorFinalizeStmt(arg0)
    c2fb_external_sqlite3Fts3FreeDeferredTokens(arg0)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->aDoclist))
    c2fb_external_sqlite3Fts3MIBufferFree(arg0->pMIBuffer)
    c2fb_external_sqlite3Fts3ExprFree(CPtr(c2fb_source_record_40 Ptr, arg0->pExpr))
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_28 Ptr, @((CPtr(c2fb_source_record_28 Ptr, @(arg0->base)))[Cast(c2fb_c_int, 1ULL)]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_37))) - Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_28)))))))
End Sub
Private Function fts3CloseMethod CDecl Alias "fts3CloseMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1799
    Dim local0 As c2fb_source_record_37 Ptr

    local0 = CPtr(c2fb_source_record_37 Ptr, arg0)
    ' C unused-parameter annotation
    fts3ClearCursor(local0)
    ' C unused-parameter annotation
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3CursorSeekStmt CDecl Alias "fts3CursorSeekStmt" (ByVal arg0 As c2fb_source_record_37 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1817
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_36 Ptr
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As UByte

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->pStmt = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = CPtr(c2fb_source_record_36 Ptr, arg0->base.pVtab)
        ' C automatic storage declaration
        If local1->pSeekStmt Then
            c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->pStmt))
            c2fb_temp_1 = local1->pSeekStmt
            (*c2fb_temp_0) = c2fb_temp_1
            c2fb_temp_2 = CPtr(Any Ptr Ptr, @(local1->pSeekStmt))
            c2fb_temp_3 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_2) = c2fb_temp_3
        Else
            c2fb_temp_4 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT %s WHERE rowid = ?"), local1->zReadExprlist))
            local2 = c2fb_temp_4
            If (-Cast(c2fb_c_int, (local2 = 0))) Then
                Return Cast(c2fb_c_int, 7ULL)
            End If
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(local1->bLock))
            c2fb_temp_6 = (*c2fb_temp_5)
            (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
            c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3PrepareStmt(local1, CPtr(Const ZString Ptr, local2), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, 1ULL), CPtr(Any Ptr Ptr, @(arg0->pStmt))))
            local0 = c2fb_temp_7
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(local1->bLock))
            c2fb_temp_9 = (*c2fb_temp_8)
            (*c2fb_temp_8) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 - 1)))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_10 = CPtr(UByte Ptr, @(arg0->bSeekStmt))
            c2fb_temp_11 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_10) = c2fb_temp_11
        End If
    End If
    Return local0
End Function
Private Function fts3CursorSeek CDecl Alias "fts3CursorSeek" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_37 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1843
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local1 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg1->isRequireSeek Then
        c2fb_temp_0 = Cast(c2fb_c_int, fts3CursorSeekStmt(arg1))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            local1 = CPtr(c2fb_source_record_36 Ptr, arg1->base.pVtab)
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @(local1->bLock))
            c2fb_temp_2 = (*c2fb_temp_1)
            (*c2fb_temp_1) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            c2fb_external_sqlite3_bind_int64(arg1->pStmt, Cast(c2fb_c_int, 1ULL), arg1->iPrevId)
            c2fb_temp_3 = CPtr(UByte Ptr, @(arg1->isRequireSeek))
            c2fb_temp_4 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_3) = c2fb_temp_4
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(arg1->pStmt))))) Then
                c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(local1->bLock))
                c2fb_temp_6 = (*c2fb_temp_5)
                (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 - 1)))
                Return Cast(c2fb_c_int, &O0ULL)
            Else
                c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local1->bLock))
                c2fb_temp_8 = (*c2fb_temp_7)
                (*c2fb_temp_7) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 - 1)))
                c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(arg1->pStmt))
                local0 = c2fb_temp_9
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((CPtr(c2fb_source_record_36 Ptr, arg1->base.pVtab))->zContentTbl = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_10 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local0 = c2fb_temp_10
                    c2fb_temp_11 = CPtr(UByte Ptr, @(arg1->isEof))
                    c2fb_temp_12 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_11) = c2fb_temp_12
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg0 <> 0))))) Then
        c2fb_external_sqlite3_result_error_code(arg0, local0)
    End If
    Return local0
End Function
Private Function fts3ScanInteriorNode CDecl Alias "fts3ScanInteriorNode" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_int64 Ptr, ByVal arg5 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 1890
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_uint64
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Const ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local11 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_int64
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As Any Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Const ZString Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_int64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_int64 Ptr
    Dim c2fb_temp_24 As c2fb_int64 Ptr
    Dim c2fb_temp_25 As c2fb_int64
    Dim c2fb_temp_26 As c2fb_int64 Ptr
    Dim c2fb_temp_27 As c2fb_uint64
    Dim c2fb_temp_28 As c2fb_int64 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim c2fb_temp_30 As c2fb_int64 Ptr
    Dim c2fb_temp_31 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = arg2
    local2 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local1)[arg3])))
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, 1ULL)
    ' C automatic storage declaration
    local7 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local1) + sqlite3Fts3GetVarintU(local1, CPtr(c2fb_uint64 Ptr, @(local6)))))
    local1 = c2fb_temp_0
    c2fb_temp_1 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local1) + sqlite3Fts3GetVarintU(local1, CPtr(c2fb_uint64 Ptr, @(local6)))))
    local1 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local1 > local2)))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < local2)))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg4 <> 0) OrElse (arg5 <> 0)))))) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        local10 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, (local5 = 0))) Then
            If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1)))) And Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_4 = sqlite3Fts3GetVarint32(local1, CPtr(c2fb_c_int Ptr, @(local10)))
            Else
                c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local10)))))
                c2fb_temp_3 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1))))
                (*c2fb_temp_2) = c2fb_temp_3
                c2fb_temp_4 = (Cast(c2fb_c_int, 1ULL))
            End If
            c2fb_temp_5 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local1) + (c2fb_temp_4)))
            local1 = c2fb_temp_5
            If (-Cast(c2fb_c_int, ((local10 > local7)))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                local0 = c2fb_temp_6
                Goto c2fb_label_0
            End If
        End If
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local5 = c2fb_temp_7
        If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1)))) And Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_10 = sqlite3Fts3GetVarint32(local1, CPtr(c2fb_c_int Ptr, @(local9)))
        Else
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local9)))))
            c2fb_temp_9 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1))))
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = (Cast(c2fb_c_int, 1ULL))
        End If
        c2fb_temp_11 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local1) + (c2fb_temp_10)))
        local1 = c2fb_temp_11
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_int64, local10) > Cast(c2fb_int64, (CPtr(Byte Ptr, CPtr(Const Byte Ptr, local1)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, arg2)))))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_int64, local9) > Cast(c2fb_int64, (CPtr(Byte Ptr, CPtr(Const Byte Ptr, local2)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local1)))))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_12 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_12
            Goto c2fb_label_0
        End If
        If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (Cast(c2fb_int64, local10) + Cast(c2fb_int64, local9))) > local4)))) Then
            ' C automatic storage declaration
            c2fb_temp_13 = Cast(c2fb_int64, Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, local10) + Cast(c2fb_int64, local9)))) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
            local4 = c2fb_temp_13
            c2fb_temp_14 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, local3), local4)))
            local11 = c2fb_temp_14
            If (-Cast(c2fb_c_int, (local11 = 0))) Then
                c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_15
                Goto c2fb_label_0
            End If
            c2fb_temp_16 = local11
            local3 = c2fb_temp_16
        End If
        ' C unused-parameter annotation
        c2fb_temp_17 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local3)[local10]))), CPtr(Const Any Ptr, local1), local9))
        c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local10 + local9)))
        local7 = c2fb_temp_18
        c2fb_temp_19 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local1) + local9))
        local1 = c2fb_temp_19
        c2fb_temp_20 = Cast(c2fb_c_int, c2fb_crt_memcmp(CPtr(Const Any Ptr, arg0), CPtr(Const Any Ptr, local3), (IIf((-Cast(c2fb_c_int, ((local7 > arg1)))), arg1, local7))))
        local8 = c2fb_temp_20
        If (-Cast(c2fb_c_int, (((arg4 <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 > arg1)))) <> 0)))))) <> 0)))))) <> 0))))) Then
            c2fb_temp_21 = CPtr(c2fb_int64 Ptr, @((*arg4)))
            c2fb_temp_22 = Cast(c2fb_int64, Cast(c2fb_int64, local6))
            (*c2fb_temp_21) = c2fb_temp_22
            c2fb_temp_23 = CPtr(c2fb_int64 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            arg4 = c2fb_temp_23
        End If
        If (-Cast(c2fb_c_int, (((arg5 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_24 = CPtr(c2fb_int64 Ptr, @((*arg5)))
            c2fb_temp_25 = Cast(c2fb_int64, Cast(c2fb_int64, local6))
            (*c2fb_temp_24) = c2fb_temp_25
            c2fb_temp_26 = CPtr(c2fb_int64 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            arg5 = c2fb_temp_26
        End If
        c2fb_temp_27 = local6
        local6 = Cast(c2fb_uint64, Cast(c2fb_uint64, (c2fb_temp_27 + 1)))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    ' empty C statement
    If arg4 Then
        c2fb_temp_28 = CPtr(c2fb_int64 Ptr, @((*arg4)))
        c2fb_temp_29 = Cast(c2fb_int64, Cast(c2fb_int64, local6))
        (*c2fb_temp_28) = c2fb_temp_29
    End If
    If arg5 Then
        c2fb_temp_30 = CPtr(c2fb_int64 Ptr, @((*arg5)))
        c2fb_temp_31 = Cast(c2fb_int64, Cast(c2fb_int64, local6))
        (*c2fb_temp_30) = c2fb_temp_31
    End If
    c2fb_label_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
    Return local0
End Function
Private Function fts3SelectLeaf CDecl Alias "fts3SelectLeaf" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_int64 Ptr, ByVal arg6 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2016
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_int64 Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (arg3)))) And Cast(c2fb_c_int, &H80ULL)))) Then
        c2fb_temp_2 = sqlite3Fts3GetVarint32(arg3, CPtr(c2fb_c_int Ptr, @(local1)))
    Else
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local1)))))
        c2fb_temp_1 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (arg3))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = (Cast(c2fb_c_int, 1ULL))
    End If
    c2fb_temp_3 = (c2fb_temp_2)
    If (-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 48ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
        local0 = c2fb_temp_4
    Else
        c2fb_temp_5 = Cast(c2fb_c_int, fts3ScanInteriorNode(arg1, arg2, arg3, arg4, arg5, arg6))
        local0 = c2fb_temp_5
    End If
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, (((arg5 <> 0) AndAlso (arg6 <> 0) AndAlso (((-Cast(c2fb_c_int, (((*arg5) <> (*arg6)))))) <> 0))))) Then
            c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3ReadBlock(arg0, (*arg5), CPtr(ZString Ptr Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3)), Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_6
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_7 = Cast(c2fb_c_int, fts3SelectLeaf(arg0, arg1, arg2, CPtr(Const ZString Ptr, local2), local3, arg5, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_7
            End If
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
            c2fb_temp_8 = CPtr(c2fb_int64 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            arg5 = c2fb_temp_8
            c2fb_temp_9 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local2 = c2fb_temp_9
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3ReadBlock(arg0, IIf(arg5, (*arg5), (*arg6)), CPtr(ZString Ptr Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3)), Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_10
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            local4 = Cast(c2fb_c_int, &O0ULL)
            If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local2)))) And Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_13 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local2), CPtr(c2fb_c_int Ptr, @(local4)))
            Else
                c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local4)))))
                c2fb_temp_12 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local2))))
                (*c2fb_temp_11) = c2fb_temp_12
                c2fb_temp_13 = (Cast(c2fb_c_int, 1ULL))
            End If
            c2fb_temp_14 = (c2fb_temp_13)
            If (-Cast(c2fb_c_int, ((local4 >= local1)))) Then
                c2fb_temp_15 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                local0 = c2fb_temp_15
            Else
                c2fb_temp_16 = Cast(c2fb_c_int, fts3SelectLeaf(arg0, arg1, arg2, CPtr(Const ZString Ptr, local2), local3, arg5, arg6))
                local0 = c2fb_temp_16
            End If
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    End If
    Return local0
End Function
Private Sub fts3PutDeltaVarint CDecl Alias "fts3PutDeltaVarint" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2074
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_int64 Ptr
    Dim c2fb_temp_3 As c2fb_int64

    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (arg2 - ((*arg1)))) >= Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg0)))
        c2fb_temp_1 = CPtr(ZString Ptr, (CPtr(Byte Ptr, (*c2fb_temp_0)) + sqlite3Fts3PutVarint((*arg0), Cast(c2fb_int64, (arg2 - (*arg1))))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_3 = Cast(c2fb_int64, arg2)
        (*c2fb_temp_2) = c2fb_temp_3
    End If
End Sub
Private Sub fts3PoslistCopy CDecl Alias "fts3PoslistCopy" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2103
    Dim local0 As ZString Ptr
    Dim local1 As Byte
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As ZString Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr

    local0 = (*arg1)
    local1 = Cast(c2fb_c_int, &O0ULL)
    While Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local0))) Or Cast(c2fb_c_int, local1)))
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, c2fb_temp_0))) And Cast(c2fb_c_int, &H80ULL))))
        local1 = c2fb_temp_1
        ' empty C statement
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_2 = local0
    local0 = (c2fb_temp_2 + 1)
    If arg0 Then
        local2 = Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local0)) - CPtr(Byte Ptr, CPtr(Byte Ptr, (*arg1))))))
        local3 = (*arg0)
        c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local3), CPtr(Const Any Ptr, (*arg1)), local2))
        c2fb_temp_4 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + local2))
        local3 = c2fb_temp_4
        c2fb_temp_5 = CPtr(ZString Ptr Ptr, @((*arg0)))
        c2fb_temp_6 = local3
        (*c2fb_temp_5) = c2fb_temp_6
    End If
    c2fb_temp_7 = CPtr(ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_8 = local0
    (*c2fb_temp_7) = c2fb_temp_8
End Sub
Private Sub fts3ColumnlistCopy CDecl Alias "fts3ColumnlistCopy" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2150
    Dim local0 As ZString Ptr
    Dim local1 As Byte
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Byte
    Dim local2 As c2fb_c_int
    Dim local3 As ZString Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr

    local0 = (*arg1)
    local1 = Cast(c2fb_c_int, &O0ULL)
    While Cast(c2fb_c_int, (Cast(c2fb_c_int, &HFEULL) And (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local0))) Or Cast(c2fb_c_int, local1))))))
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, c2fb_temp_0))) And Cast(c2fb_c_int, &H80ULL))))
        local1 = c2fb_temp_1
        ' empty C statement
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If arg0 Then
        local2 = Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local0)) - CPtr(Byte Ptr, CPtr(Byte Ptr, (*arg1))))))
        local3 = (*arg0)
        c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local3), CPtr(Const Any Ptr, (*arg1)), local2))
        c2fb_temp_3 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + local2))
        local3 = c2fb_temp_3
        c2fb_temp_4 = CPtr(ZString Ptr Ptr, @((*arg0)))
        c2fb_temp_5 = local3
        (*c2fb_temp_4) = c2fb_temp_5
    End If
    c2fb_temp_6 = CPtr(ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_7 = local0
    (*c2fb_temp_6) = c2fb_temp_7
End Sub
Private Sub fts3ReadNextPos CDecl Alias "fts3ReadNextPos" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2196
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_int64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_int64 Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_int64 Ptr
    Dim c2fb_temp_10 As c2fb_int64

    If Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Byte Ptr, (*arg0))))) And Cast(c2fb_c_int, &HFEULL))) Then
        ' C automatic storage declaration
        c2fb_temp_3 = CPtr(ZString Ptr Ptr, @((*arg0)))
        If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (((*arg0)))))) And Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_2 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, ((*arg0))), CPtr(c2fb_c_int Ptr, @(local0)))
        Else
            c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local0)))))
            c2fb_temp_1 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (((*arg0))))))
            (*c2fb_temp_0) = c2fb_temp_1
            c2fb_temp_2 = (Cast(c2fb_c_int, 1ULL))
        End If
        c2fb_temp_4 = CPtr(ZString Ptr, (CPtr(Byte Ptr, (*c2fb_temp_3)) + (c2fb_temp_2)))
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_6 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_5) + Cast(c2fb_int64, local0))))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_8 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_7) - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
        (*c2fb_temp_7) = c2fb_temp_8
    Else
        c2fb_temp_9 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_10 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL))))))))
        (*c2fb_temp_9) = c2fb_temp_10
    End If
End Sub
Private Function fts3PutColNumber CDecl Alias "fts3PutColNumber" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2219
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Byte Ptr
    Dim c2fb_temp_2 As Byte
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg1 Then
        local1 = (*arg0)
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, 1ULL)]))), arg1))))
        local0 = c2fb_temp_0
        c2fb_temp_1 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, local1))))
        c2fb_temp_2 = Cast(Byte, Cast(c2fb_c_int, &H01ULL))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(ZString Ptr Ptr, @((*arg0)))
        c2fb_temp_4 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[local0])))
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    Return local0
End Function
Private Function fts3PoslistMerge CDecl Alias "fts3PoslistMerge" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2237
    Dim local0 As ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As ZString Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As Byte Ptr
    Dim c2fb_temp_19 As Byte
    Dim c2fb_temp_20 As ZString Ptr Ptr
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As ZString Ptr Ptr
    Dim c2fb_temp_23 As ZString Ptr
    Dim c2fb_temp_24 As ZString Ptr Ptr
    Dim c2fb_temp_25 As ZString Ptr

    local0 = (*arg0)
    local1 = (*arg1)
    local2 = (*arg2)
    While (-Cast(c2fb_c_int, ((((*CPtr(Byte Ptr, local1)) <> 0) OrElse ((*CPtr(Byte Ptr, local2)) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))) = (Cast(c2fb_c_int, 1ULL)))))) Then
            If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, 1ULL)])))))) And Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_2 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, 1ULL)]))), CPtr(c2fb_c_int Ptr, @(local3)))
            Else
                c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local3)))))
                c2fb_temp_1 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, 1ULL)]))))))
                (*c2fb_temp_0) = c2fb_temp_1
                c2fb_temp_2 = (Cast(c2fb_c_int, 1ULL))
            End If
            c2fb_temp_3 = (c2fb_temp_2)
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
            End If
        Else
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))) = (Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H7fffffffULL))
                local3 = c2fb_temp_4
            Else
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_5
            End If
        End If
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))) = (Cast(c2fb_c_int, 1ULL)))))) Then
            If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[Cast(c2fb_c_int, 1ULL)])))))) And Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_8 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[Cast(c2fb_c_int, 1ULL)]))), CPtr(c2fb_c_int Ptr, @(local4)))
            Else
                c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local4)))))
                c2fb_temp_7 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[Cast(c2fb_c_int, 1ULL)]))))))
                (*c2fb_temp_6) = c2fb_temp_7
                c2fb_temp_8 = (Cast(c2fb_c_int, 1ULL))
            End If
            c2fb_temp_9 = (c2fb_temp_8)
            If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
            End If
        Else
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))) = (Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H7fffffffULL))
                local4 = c2fb_temp_10
            Else
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local4 = c2fb_temp_11
            End If
        End If
        If (-Cast(c2fb_c_int, ((local3 = local4)))) Then
            local5 = Cast(c2fb_c_int, &O0ULL)
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = fts3PutColNumber(CPtr(ZString Ptr Ptr, @(local0)), local3)
            c2fb_temp_12 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + local8))
            local1 = c2fb_temp_12
            c2fb_temp_13 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local2) + local8))
            local2 = c2fb_temp_13
            fts3GetDeltaVarint(CPtr(ZString Ptr Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(local5)))
            fts3GetDeltaVarint(CPtr(ZString Ptr Ptr, @(local2)), CPtr(c2fb_int64 Ptr, @(local6)))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 < Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local6 < Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                Goto c2fb_flow_0
            End If
            Do
                fts3PutDeltaVarint(CPtr(ZString Ptr Ptr, @(local0)), CPtr(c2fb_int64 Ptr, @(local7)), IIf(((-Cast(c2fb_c_int, ((local5 < local6))))), local5, local6))
                c2fb_temp_14 = Cast(c2fb_int64, Cast(c2fb_int64, (local7 - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
                local7 = c2fb_temp_14
                If (-Cast(c2fb_c_int, ((local5 = local6)))) Then
                    fts3ReadNextPos(CPtr(ZString Ptr Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(local5)))
                    fts3ReadNextPos(CPtr(ZString Ptr Ptr, @(local2)), CPtr(c2fb_int64 Ptr, @(local6)))
                Else
                    If (-Cast(c2fb_c_int, ((local5 < local6)))) Then
                        fts3ReadNextPos(CPtr(ZString Ptr Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(local5)))
                    Else
                        fts3ReadNextPos(CPtr(ZString Ptr Ptr, @(local2)), CPtr(c2fb_int64 Ptr, @(local6)))
                    End If
                End If
            c2fb_flow_3:
            Loop While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 <> (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL))))))))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local6 <> (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL))))))))))) <> 0)))))
            c2fb_flow_2:
        Else
            If (-Cast(c2fb_c_int, ((local3 < local4)))) Then
                c2fb_temp_15 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + fts3PutColNumber(CPtr(ZString Ptr Ptr, @(local0)), local3)))
                local1 = c2fb_temp_15
                fts3ColumnlistCopy(CPtr(ZString Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(local1)))
            Else
                c2fb_temp_16 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local2) + fts3PutColNumber(CPtr(ZString Ptr Ptr, @(local0)), local4)))
                local2 = c2fb_temp_16
                fts3ColumnlistCopy(CPtr(ZString Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(local2)))
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_17 = local0
    local0 = (c2fb_temp_17 + 1)
    c2fb_temp_18 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_17))))
    c2fb_temp_19 = Cast(Byte, (Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_18) = c2fb_temp_19
    c2fb_temp_20 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_21 = local0
    (*c2fb_temp_20) = c2fb_temp_21
    c2fb_temp_22 = CPtr(ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_23 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + Cast(c2fb_c_int, 1ULL)))
    (*c2fb_temp_22) = c2fb_temp_23
    c2fb_temp_24 = CPtr(ZString Ptr Ptr, @((*arg2)))
    c2fb_temp_25 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local2) + Cast(c2fb_c_int, 1ULL)))
    (*c2fb_temp_24) = c2fb_temp_25
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3PoslistPhraseMerge CDecl Alias "fts3PoslistPhraseMerge" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2337
    Dim local0 As ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_int64
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As Byte Ptr
    Dim c2fb_temp_12 As Byte
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_int64
    Dim local9 As c2fb_int64
    Dim c2fb_temp_16 As c2fb_int64
    Dim c2fb_temp_17 As c2fb_int64
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As c2fb_int64
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As c2fb_c_int Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As ZString Ptr
    Dim c2fb_temp_27 As ZString Ptr
    Dim c2fb_temp_28 As c2fb_c_int Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As ZString Ptr
    Dim c2fb_temp_32 As ZString Ptr
    Dim c2fb_temp_33 As c2fb_c_int Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As ZString Ptr
    Dim c2fb_temp_37 As ZString Ptr
    Dim c2fb_temp_38 As c2fb_c_int Ptr
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As ZString Ptr
    Dim c2fb_temp_42 As ZString Ptr Ptr
    Dim c2fb_temp_43 As ZString Ptr
    Dim c2fb_temp_44 As ZString Ptr Ptr
    Dim c2fb_temp_45 As ZString Ptr
    Dim c2fb_temp_46 As ZString Ptr
    Dim c2fb_temp_47 As Byte Ptr
    Dim c2fb_temp_48 As Byte
    Dim c2fb_temp_49 As ZString Ptr Ptr
    Dim c2fb_temp_50 As ZString Ptr

    local0 = (*arg0)
    local1 = (*arg4)
    local2 = (*arg5)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))) = (Cast(c2fb_c_int, 1ULL)))))) Then
        c2fb_temp_0 = local1
        local1 = (c2fb_temp_0 + 1)
        If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1)))) And Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_3 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(local3)))
        Else
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local3)))))
            c2fb_temp_2 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1))))
            (*c2fb_temp_1) = c2fb_temp_2
            c2fb_temp_3 = (Cast(c2fb_c_int, 1ULL))
        End If
        c2fb_temp_4 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + (c2fb_temp_3)))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))) = (Cast(c2fb_c_int, 1ULL)))))) Then
        c2fb_temp_5 = local2
        local2 = (c2fb_temp_5 + 1)
        If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local2)))) And Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_8 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local2), CPtr(c2fb_c_int Ptr, @(local4)))
        Else
            c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local4)))))
            c2fb_temp_7 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local2))))
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = (Cast(c2fb_c_int, 1ULL))
        End If
        c2fb_temp_9 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local2) + (c2fb_temp_8)))
        local2 = c2fb_temp_9
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    End If
    While Cast(c2fb_c_int, 1ULL)
        If (-Cast(c2fb_c_int, ((local3 = local4)))) Then
            local5 = local0
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = Cast(c2fb_c_int, &O0ULL)
            If local3 Then
                c2fb_temp_10 = local0
                local0 = (c2fb_temp_10 + 1)
                c2fb_temp_11 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_10))))
                c2fb_temp_12 = Cast(Byte, (Cast(c2fb_c_int, 1ULL)))
                (*c2fb_temp_11) = c2fb_temp_12
                c2fb_temp_13 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local0) + sqlite3Fts3PutVarint(local0, local3)))
                local0 = c2fb_temp_13
            End If
            fts3GetDeltaVarint(CPtr(ZString Ptr Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(local7)))
            c2fb_temp_14 = Cast(c2fb_int64, Cast(c2fb_int64, (local7 - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
            local7 = c2fb_temp_14
            fts3GetDeltaVarint(CPtr(ZString Ptr Ptr, @(local2)), CPtr(c2fb_int64 Ptr, @(local8)))
            c2fb_temp_15 = Cast(c2fb_int64, Cast(c2fb_int64, (local8 - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
            local8 = c2fb_temp_15
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local8 < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
                Goto c2fb_flow_0
            End If
            While Cast(c2fb_c_int, 1ULL)
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 = Cast(c2fb_int64, (local7 + Cast(c2fb_int64, arg1))))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 > local7)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 <= Cast(c2fb_int64, (local7 + Cast(c2fb_int64, arg1))))))) <> 0)))))) <> 0))))) Then
                    ' C automatic storage declaration
                    c2fb_temp_16 = Cast(c2fb_int64, IIf(arg2, local7, local8))
                    local9 = c2fb_temp_16
                    fts3PutDeltaVarint(CPtr(ZString Ptr Ptr, @(local0)), CPtr(c2fb_int64 Ptr, @(local6)), Cast(c2fb_int64, (local9 + Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
                    c2fb_temp_17 = Cast(c2fb_int64, Cast(c2fb_int64, (local6 - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
                    local6 = c2fb_temp_17
                    c2fb_temp_18 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local5 = c2fb_temp_18
                    ' C unused-parameter annotation
                End If
                If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (arg2 = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 <= (Cast(c2fb_int64, (local7 + Cast(c2fb_int64, arg1)))))))) <> 0)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local8 <= local7)))) <> 0))))) Then
                    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))) And Cast(c2fb_c_int, &HFEULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_2
                    End If
                    fts3GetDeltaVarint(CPtr(ZString Ptr Ptr, @(local2)), CPtr(c2fb_int64 Ptr, @(local8)))
                    c2fb_temp_19 = Cast(c2fb_int64, Cast(c2fb_int64, (local8 - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
                    local8 = c2fb_temp_19
                Else
                    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))) And Cast(c2fb_c_int, &HFEULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_2
                    End If
                    fts3GetDeltaVarint(CPtr(ZString Ptr Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(local7)))
                    c2fb_temp_20 = Cast(c2fb_int64, Cast(c2fb_int64, (local7 - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
                    local7 = c2fb_temp_20
                End If
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            If local5 Then
                ' C unused-parameter annotation
                c2fb_temp_21 = local5
                local0 = c2fb_temp_21
            End If
            fts3ColumnlistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local1)))
            fts3ColumnlistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local2)))
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))))))) <> 0))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_22 = local1
            local1 = (c2fb_temp_22 + 1)
            If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1)))) And Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_25 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(local3)))
            Else
                c2fb_temp_23 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local3)))))
                c2fb_temp_24 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1))))
                (*c2fb_temp_23) = c2fb_temp_24
                c2fb_temp_25 = (Cast(c2fb_c_int, 1ULL))
            End If
            c2fb_temp_26 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + (c2fb_temp_25)))
            local1 = c2fb_temp_26
            c2fb_temp_27 = local2
            local2 = (c2fb_temp_27 + 1)
            If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local2)))) And Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_30 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local2), CPtr(c2fb_c_int Ptr, @(local4)))
            Else
                c2fb_temp_28 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local4)))))
                c2fb_temp_29 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local2))))
                (*c2fb_temp_28) = c2fb_temp_29
                c2fb_temp_30 = (Cast(c2fb_c_int, 1ULL))
            End If
            c2fb_temp_31 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local2) + (c2fb_temp_30)))
            local2 = c2fb_temp_31
        Else
            If (-Cast(c2fb_c_int, ((local3 < local4)))) Then
                fts3ColumnlistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local1)))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))))))) Then
                    Goto c2fb_flow_0
                End If
                c2fb_temp_32 = local1
                local1 = (c2fb_temp_32 + 1)
                If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1)))) And Cast(c2fb_c_int, &H80ULL)))) Then
                    c2fb_temp_35 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(local3)))
                Else
                    c2fb_temp_33 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local3)))))
                    c2fb_temp_34 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1))))
                    (*c2fb_temp_33) = c2fb_temp_34
                    c2fb_temp_35 = (Cast(c2fb_c_int, 1ULL))
                End If
                c2fb_temp_36 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + (c2fb_temp_35)))
                local1 = c2fb_temp_36
            Else
                fts3ColumnlistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local2)))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))))))) Then
                    Goto c2fb_flow_0
                End If
                c2fb_temp_37 = local2
                local2 = (c2fb_temp_37 + 1)
                If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local2)))) And Cast(c2fb_c_int, &H80ULL)))) Then
                    c2fb_temp_40 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local2), CPtr(c2fb_c_int Ptr, @(local4)))
                Else
                    c2fb_temp_38 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local4)))))
                    c2fb_temp_39 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local2))))
                    (*c2fb_temp_38) = c2fb_temp_39
                    c2fb_temp_40 = (Cast(c2fb_c_int, 1ULL))
                End If
                c2fb_temp_41 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local2) + (c2fb_temp_40)))
                local2 = c2fb_temp_41
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    fts3PoslistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local2)))
    fts3PoslistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local1)))
    c2fb_temp_42 = CPtr(ZString Ptr Ptr, @((*arg4)))
    c2fb_temp_43 = local1
    (*c2fb_temp_42) = c2fb_temp_43
    c2fb_temp_44 = CPtr(ZString Ptr Ptr, @((*arg5)))
    c2fb_temp_45 = local2
    (*c2fb_temp_44) = c2fb_temp_45
    If (-Cast(c2fb_c_int, (((*arg0) = local0)))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_46 = local0
    local0 = (c2fb_temp_46 + 1)
    c2fb_temp_47 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_46))))
    c2fb_temp_48 = Cast(Byte, Cast(c2fb_c_int, &H00ULL))
    (*c2fb_temp_47) = c2fb_temp_48
    c2fb_temp_49 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_50 = local0
    (*c2fb_temp_49) = c2fb_temp_50
    Return Cast(c2fb_c_int, 1ULL)
End Function
Private Function fts3PoslistNearMerge CDecl Alias "fts3PoslistNearMerge" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2465
    Dim local0 As ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = (*arg4)
    local1 = (*arg5)
    local2 = arg1
    ' C automatic storage declaration
    ' C automatic storage declaration
    local5 = Cast(c2fb_c_int, 1ULL)
    fts3PoslistPhraseMerge(CPtr(ZString Ptr Ptr, @(local2)), arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg4, arg5)
    c2fb_temp_0 = local2
    local3 = c2fb_temp_0
    c2fb_temp_1 = c2fb_temp_0
    local4 = c2fb_temp_1
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @((*arg4)))
    c2fb_temp_3 = local0
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(ZString Ptr Ptr, @((*arg5)))
    c2fb_temp_5 = local1
    (*c2fb_temp_4) = c2fb_temp_5
    fts3PoslistPhraseMerge(CPtr(ZString Ptr Ptr, @(local3)), arg3, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL), arg5, arg4)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 <> arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 <> local4)))) <> 0))))) Then
        fts3PoslistMerge(arg0, CPtr(ZString Ptr Ptr, @(arg1)), CPtr(ZString Ptr Ptr, @(local4)))
    Else
        If (-Cast(c2fb_c_int, ((local2 <> arg1)))) Then
            fts3PoslistCopy(arg0, CPtr(ZString Ptr Ptr, @(arg1)))
        Else
            If (-Cast(c2fb_c_int, ((local3 <> local4)))) Then
                fts3PoslistCopy(arg0, CPtr(ZString Ptr Ptr, @(local4)))
            Else
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local5 = c2fb_temp_6
            End If
        End If
    End If
    Return local5
End Function
Private Sub fts3GetDeltaVarint3 CDecl Alias "fts3GetDeltaVarint3" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2523
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim local0 As c2fb_uint64
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_int64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64

    If (-Cast(c2fb_c_int, (((*arg0) >= arg1)))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg0)))
        c2fb_temp_1 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = c2fb_temp_1
    Else
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(ZString Ptr Ptr, @((*arg0)))
        c2fb_temp_3 = CPtr(ZString Ptr, (CPtr(Byte Ptr, (*c2fb_temp_2)) + sqlite3Fts3GetVarintU(CPtr(Const ZString Ptr, (*arg0)), CPtr(c2fb_uint64 Ptr, @(local0)))))
        (*c2fb_temp_2) = c2fb_temp_3
        If arg2 Then
            c2fb_temp_4 = CPtr(c2fb_int64 Ptr, @((*arg3)))
            c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (*arg3)) - local0)))))
            (*c2fb_temp_4) = c2fb_temp_5
        Else
            c2fb_temp_6 = CPtr(c2fb_int64 Ptr, @((*arg3)))
            c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (*arg3)) + local0)))))
            (*c2fb_temp_6) = c2fb_temp_7
        End If
    End If
End Sub
Private Sub fts3PutDeltaVarint3 CDecl Alias "fts3PutDeltaVarint3" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_int64)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2557
    Dim local0 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_uint64
    Dim c2fb_temp_1 As c2fb_uint64
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_int64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((*arg3) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        ' C unused-parameter annotation
        c2fb_temp_0 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, arg4) - Cast(c2fb_uint64, (*arg2)))))
        local0 = c2fb_temp_0
    Else
        ' C unused-parameter annotation
        c2fb_temp_1 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (*arg2)) - Cast(c2fb_uint64, arg4))))
        local0 = c2fb_temp_1
    End If
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_3 = CPtr(ZString Ptr, (CPtr(Byte Ptr, (*c2fb_temp_2)) + sqlite3Fts3PutVarint((*arg0), local0)))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_int64 Ptr, @((*arg2)))
    c2fb_temp_5 = Cast(c2fb_int64, arg4)
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_6) = c2fb_temp_7
End Sub
Private Function fts3DoclistOrMerge CDecl Alias "fts3DoclistOrMerge" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As ZString Ptr Ptr, ByVal arg6 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2606
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_int64
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim local6 As ZString Ptr
    Dim local7 As ZString Ptr
    Dim local8 As ZString Ptr
    Dim local9 As ZString Ptr
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim local11 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As ZString Ptr Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1)[arg2])))
    local5 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg3)[arg4])))
    local6 = arg1
    local7 = arg3
    ' C automatic storage declaration
    ' C automatic storage declaration
    local10 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg5)))
    c2fb_temp_1 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg6)))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, arg2) + Cast(c2fb_int64, arg4))) + Cast(c2fb_int64, Cast(c2fb_c_int, 10ULL)))) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 8ULL)))))))
    local9 = c2fb_temp_4
    If (-Cast(c2fb_c_int, (local9 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_5 = local9
    local8 = c2fb_temp_5
    fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local6)), local4, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_int64 Ptr, @(local1)))
    fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local7)), local5, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_int64 Ptr, @(local2)))
    While (-Cast(c2fb_c_int, (((local6 <> 0) OrElse (local7 <> 0)))))
        local11 = (Cast(c2fb_c_int, ((IIf(arg0, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL))) * (IIf((-Cast(c2fb_c_int, ((local1 > local2)))), Cast(c2fb_c_int, 1ULL), (IIf(((-Cast(c2fb_c_int, ((local1 = local2))))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))))))
        If (-Cast(c2fb_c_int, (((local7 <> 0) AndAlso (local6 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local11 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
            fts3PutDeltaVarint3(CPtr(ZString Ptr Ptr, @(local8)), arg0, CPtr(c2fb_int64 Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local10)), local1)
            c2fb_temp_6 = Cast(c2fb_c_int, fts3PoslistMerge(CPtr(ZString Ptr Ptr, @(local8)), CPtr(ZString Ptr Ptr, @(local6)), CPtr(ZString Ptr Ptr, @(local7))))
            local0 = c2fb_temp_6
            If local0 Then
                Goto c2fb_flow_0
            End If
            fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local6)), local4, arg0, CPtr(c2fb_int64 Ptr, @(local1)))
            fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local7)), local5, arg0, CPtr(c2fb_int64 Ptr, @(local2)))
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local7 = 0))) <> 0) OrElse (((-Cast(c2fb_c_int, (((local6 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local11 < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0)))))) <> 0))))) Then
                fts3PutDeltaVarint3(CPtr(ZString Ptr Ptr, @(local8)), arg0, CPtr(c2fb_int64 Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local10)), local1)
                fts3PoslistCopy(CPtr(ZString Ptr Ptr, @(local8)), CPtr(ZString Ptr Ptr, @(local6)))
                fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local6)), local4, arg0, CPtr(c2fb_int64 Ptr, @(local1)))
            Else
                fts3PutDeltaVarint3(CPtr(ZString Ptr Ptr, @(local8)), arg0, CPtr(c2fb_int64 Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local10)), local2)
                fts3PoslistCopy(CPtr(ZString Ptr Ptr, @(local8)), CPtr(ZString Ptr Ptr, @(local7)))
                fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local7)), local5, arg0, CPtr(c2fb_int64 Ptr, @(local2)))
            End If
        End If
        ' C unused-parameter annotation
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local9))
        c2fb_temp_7 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local9 = c2fb_temp_7
        c2fb_temp_8 = c2fb_temp_7
        local8 = c2fb_temp_8
    Else
        ' C unused-parameter annotation
        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local9)[((CPtr(Byte Ptr, CPtr(Byte Ptr, local8)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local9))))]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 8ULL)))
    End If
    c2fb_temp_10 = CPtr(ZString Ptr Ptr, @((*arg5)))
    c2fb_temp_11 = local9
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @((*arg6)))
    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local8)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local9))))))
    (*c2fb_temp_12) = c2fb_temp_13
    Return local0
End Function
Private Function fts3DoclistPhraseMerge CDecl Alias "fts3DoclistPhraseMerge" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2708
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_int64
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim local6 As ZString Ptr
    Dim local7 As ZString Ptr
    Dim local8 As ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim local11 As c2fb_int64
    Dim local12 As ZString Ptr
    Dim local13 As c2fb_int64
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = (*arg4)
    local4 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg2)[arg3])))
    local5 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local3)[(*arg5)])))
    local6 = arg2
    local7 = local3
    ' C automatic storage declaration
    local9 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If arg0 Then
        c2fb_temp_0 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, (*arg5)) + Cast(c2fb_int64, Cast(c2fb_c_int, 10ULL)))))))
        local10 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
    Else
        c2fb_temp_1 = local3
        local10 = c2fb_temp_1
    End If
    c2fb_temp_2 = local10
    local8 = c2fb_temp_2
    fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local6)), local4, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_int64 Ptr, @(local0)))
    fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local7)), local5, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_int64 Ptr, @(local1)))
    While (-Cast(c2fb_c_int, (((local6 <> 0) AndAlso (local7 <> 0)))))
        local11 = (Cast(c2fb_c_int, ((IIf(arg0, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL))) * (IIf((-Cast(c2fb_c_int, ((local0 > local1)))), Cast(c2fb_c_int, 1ULL), (IIf(((-Cast(c2fb_c_int, ((local0 = local1))))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))))))
        If (-Cast(c2fb_c_int, ((local11 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
            local12 = local8
            local13 = local2
            local14 = local9
            fts3PutDeltaVarint3(CPtr(ZString Ptr Ptr, @(local8)), arg0, CPtr(c2fb_int64 Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local9)), local0)
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts3PoslistPhraseMerge(CPtr(ZString Ptr Ptr, @(local8)), arg1, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL), CPtr(ZString Ptr Ptr, @(local6)), CPtr(ZString Ptr Ptr, @(local7))))))) Then
                c2fb_temp_3 = local12
                local8 = c2fb_temp_3
                c2fb_temp_4 = Cast(c2fb_int64, local13)
                local2 = c2fb_temp_4
                c2fb_temp_5 = Cast(c2fb_c_int, local14)
                local9 = c2fb_temp_5
            End If
            fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local6)), local4, arg0, CPtr(c2fb_int64 Ptr, @(local0)))
            fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local7)), local5, arg0, CPtr(c2fb_int64 Ptr, @(local1)))
        Else
            If (-Cast(c2fb_c_int, ((local11 < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                fts3PoslistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local6)))
                fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local6)), local4, arg0, CPtr(c2fb_int64 Ptr, @(local0)))
            Else
                fts3PoslistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local7)))
                fts3GetDeltaVarint3(CPtr(ZString Ptr Ptr, @(local7)), local5, arg0, CPtr(c2fb_int64 Ptr, @(local1)))
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg5)))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local8)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local10))))))
    (*c2fb_temp_6) = c2fb_temp_7
    If arg0 Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
        c2fb_temp_8 = CPtr(ZString Ptr Ptr, @((*arg4)))
        c2fb_temp_9 = local10
        (*c2fb_temp_8) = c2fb_temp_9
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts3FirstFilter CDecl Alias "sqlite3Fts3FirstFilter" (ByVal arg0 As c2fb_int64, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2779
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Byte Ptr
    Dim c2fb_temp_3 As Byte
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Byte Ptr
    Dim c2fb_temp_11 As Byte
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Byte Ptr
    Dim c2fb_temp_15 As Byte
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Byte Ptr
    Dim c2fb_temp_18 As Byte

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = arg1
    local3 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1)[arg2])))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))) <> Cast(c2fb_c_int, &H01ULL))))) Then
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))) = Cast(c2fb_c_int, &H02ULL))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg3)[local0]))), arg0))))
            local0 = c2fb_temp_0
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
            c2fb_temp_2 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg3)[c2fb_temp_1]))
            c2fb_temp_3 = Cast(Byte, Cast(c2fb_c_int, &H02ULL))
            (*c2fb_temp_2) = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local1 = c2fb_temp_4
        End If
        fts3ColumnlistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local2)))
    End If
    While (-Cast(c2fb_c_int, ((local2 < local3))))
        ' C automatic storage declaration
        c2fb_temp_5 = local2
        local2 = (c2fb_temp_5 + 1)
        c2fb_temp_6 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local2) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local2), CPtr(c2fb_int64 Ptr, @(local4)))))
        local2 = c2fb_temp_6
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local2))) = Cast(c2fb_c_int, &H02ULL))))) Then
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg3)[local0]))), arg0))))
                local0 = c2fb_temp_7
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local1 = c2fb_temp_8
            End If
            c2fb_temp_9 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
            c2fb_temp_10 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg3)[c2fb_temp_9]))
            c2fb_temp_11 = Cast(Byte, Cast(c2fb_c_int, &H01ULL))
            (*c2fb_temp_10) = c2fb_temp_11
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg3)[local0]))), local4))))
            local0 = c2fb_temp_12
            c2fb_temp_13 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
            c2fb_temp_14 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg3)[c2fb_temp_13]))
            c2fb_temp_15 = Cast(Byte, Cast(c2fb_c_int, &H02ULL))
            (*c2fb_temp_14) = c2fb_temp_15
        End If
        fts3ColumnlistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local2)))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If local1 Then
        c2fb_temp_16 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 + 1)))
        c2fb_temp_17 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg3)[c2fb_temp_16]))
        c2fb_temp_18 = Cast(Byte, Cast(c2fb_c_int, &H00ULL))
        (*c2fb_temp_17) = c2fb_temp_18
    End If
    Return local0
End Function
Private Function fts3TermSelectFinishMerge CDecl Alias "fts3TermSelectFinishMerge" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_44 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2831
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As ZString Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As ZString Ptr Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local2 < (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (16ULL * SizeOf(ZString Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))))))))))))
        If arg1->aaOutput(local2) Then
            If (-Cast(c2fb_c_int, (local0 = 0))) Then
                c2fb_temp_2 = arg1->aaOutput(local2)
                local0 = c2fb_temp_2
                c2fb_temp_3 = Cast(c2fb_c_int, arg1->anOutput(local2))
                local1 = c2fb_temp_3
                c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(arg1->aaOutput(local2)))
                c2fb_temp_5 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_4) = c2fb_temp_5
            Else
                ' C automatic storage declaration
                ' C automatic storage declaration
                local5 = fts3DoclistOrMerge(arg0->bDescIdx, arg1->aaOutput(local2), arg1->anOutput(local2), local0, local1, CPtr(ZString Ptr Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local3)))
                If (-Cast(c2fb_c_int, ((local5 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
                    Return local5
                End If
                c2fb_external_sqlite3_free(CPtr(Any Ptr, arg1->aaOutput(local2)))
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
                c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(arg1->aaOutput(local2)))
                c2fb_temp_7 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_6) = c2fb_temp_7
                c2fb_temp_8 = local4
                local0 = c2fb_temp_8
                c2fb_temp_9 = Cast(c2fb_c_int, local3)
                local1 = c2fb_temp_9
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_10 = CPtr(ZString Ptr Ptr, @(arg1->aaOutput(Cast(c2fb_c_int, &O0ULL))))
    c2fb_temp_11 = local0
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @(arg1->anOutput(Cast(c2fb_c_int, &O0ULL))))
    c2fb_temp_13 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_12) = c2fb_temp_13
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3TermSelectMerge CDecl Alias "fts3TermSelectMerge" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_44 Ptr, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2885
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Any Ptr
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local3 As ZString Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As ZString Ptr Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg1->aaOutput(Cast(c2fb_c_int, &O0ULL)) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @(arg1->aaOutput(Cast(c2fb_c_int, &O0ULL))))
        c2fb_temp_1 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, arg3) + Cast(c2fb_int64, Cast(c2fb_c_int, 10ULL)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg1->anOutput(Cast(c2fb_c_int, &O0ULL))))
        c2fb_temp_3 = Cast(c2fb_c_int, arg3)
        (*c2fb_temp_2) = c2fb_temp_3
        If arg1->aaOutput(Cast(c2fb_c_int, &O0ULL)) Then
            c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg1->aaOutput(Cast(c2fb_c_int, &O0ULL))), CPtr(Const Any Ptr, arg2), arg3))
            c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aaOutput(Cast(c2fb_c_int, &O0ULL)))[arg3]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 10ULL)))
        Else
            Return Cast(c2fb_c_int, 7ULL)
        End If
    Else
        local0 = arg2
        local1 = arg3
        ' C automatic storage declaration
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_6
        While (-Cast(c2fb_c_int, ((local2 < (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (16ULL * SizeOf(ZString Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))))))))))))
            If (-Cast(c2fb_c_int, ((arg1->aaOutput(local2) = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C unused-parameter annotation
                c2fb_temp_8 = CPtr(ZString Ptr Ptr, @(arg1->aaOutput(local2)))
                c2fb_temp_9 = local0
                (*c2fb_temp_8) = c2fb_temp_9
                c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(arg1->anOutput(local2)))
                c2fb_temp_11 = Cast(c2fb_c_int, local1)
                (*c2fb_temp_10) = c2fb_temp_11
                Goto c2fb_flow_0
            Else
                ' C automatic storage declaration
                ' C automatic storage declaration
                local5 = fts3DoclistOrMerge(arg0->bDescIdx, local0, local1, arg1->aaOutput(local2), arg1->anOutput(local2), CPtr(ZString Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local4)))
                If (-Cast(c2fb_c_int, ((local5 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    If (-Cast(c2fb_c_int, ((local0 <> arg2)))) Then
                        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
                    End If
                    Return local5
                End If
                If (-Cast(c2fb_c_int, ((local0 <> arg2)))) Then
                    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
                End If
                c2fb_external_sqlite3_free(CPtr(Any Ptr, arg1->aaOutput(local2)))
                c2fb_temp_12 = CPtr(ZString Ptr Ptr, @(arg1->aaOutput(local2)))
                c2fb_temp_13 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_12) = c2fb_temp_13
                c2fb_temp_14 = local3
                local0 = c2fb_temp_14
                c2fb_temp_15 = Cast(c2fb_c_int, local4)
                local1 = c2fb_temp_15
                If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))) = (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (16ULL * SizeOf(ZString Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr)))))))))))) Then
                    c2fb_temp_16 = CPtr(ZString Ptr Ptr, @(arg1->aaOutput(local2)))
                    c2fb_temp_17 = local0
                    (*c2fb_temp_16) = c2fb_temp_17
                    c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @(arg1->anOutput(local2)))
                    c2fb_temp_19 = Cast(c2fb_c_int, local1)
                    (*c2fb_temp_18) = c2fb_temp_19
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_7 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
        Wend
        c2fb_flow_0:
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3SegReaderCursorAppend CDecl Alias "fts3SegReaderCursorAppend" (ByVal arg0 As c2fb_source_record_42 Ptr, ByVal arg1 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2958
    Dim local0 As Any Ptr Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr Ptr Ptr
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr Ptr
    Dim c2fb_temp_6 As Any Ptr

    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->nSegment Mod Cast(c2fb_c_int, 16ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        local1 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (arg0->nSegment + Cast(c2fb_c_int, 16ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Any Ptr)))))
        c2fb_temp_0 = CPtr(Any Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, arg0->apSegment), local1)))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, (local0 = 0))) Then
            c2fb_external_sqlite3Fts3SegReaderFree(arg1)
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_1 = CPtr(Any Ptr Ptr Ptr, @(arg0->apSegment))
        c2fb_temp_2 = local0
        (*c2fb_temp_1) = c2fb_temp_2
    End If
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg0->nSegment))
    c2fb_temp_4 = (*c2fb_temp_3)
    (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    c2fb_temp_5 = CPtr(Any Ptr Ptr, @(arg0->apSegment[c2fb_temp_4]))
    c2fb_temp_6 = arg1
    (*c2fb_temp_5) = c2fb_temp_6
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3SegReaderCursor CDecl Alias "fts3SegReaderCursor" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_source_record_42 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 2983
    Dim local0 As c2fb_c_int
    Dim local1 As Any Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As Any Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As Any Ptr
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_c_int
    Dim local9 As Const ZString Ptr
    Dim local10 As c2fb_int64 Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 < Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg0->aIndex <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->iPrevLangid = arg1)))) <> 0))))) Then
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SegReaderPending(arg0, arg2, arg4, arg5, (-Cast(c2fb_c_int, (((arg6 <> 0) OrElse (arg7 <> 0))))), CPtr(Any Ptr Ptr, @(local3))))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local3 <> 0))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, fts3SegReaderCursorAppend(arg8, local3))
            local0 = c2fb_temp_1
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg3 <> Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))) Then
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3AllSegdirs(arg0, arg1, arg2, arg3, CPtr(Any Ptr Ptr, @(local1))))
            local0 = c2fb_temp_2
        End If
        Do
            c2fb_temp_5 = 0
            If ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) Then
                c2fb_temp_4 = Cast(c2fb_c_int, 100ULL)
                c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3_step(local1))
                local0 = c2fb_temp_3
                c2fb_temp_5 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_4 = (c2fb_temp_3))))) <> 0))))
            End If
            If (c2fb_temp_5 = 0) Then Goto c2fb_flow_0
            local4 = Cast(c2fb_c_int, &O0ULL)
            local5 = c2fb_external_sqlite3_column_int64(local1, Cast(c2fb_c_int, 1ULL))
            local6 = c2fb_external_sqlite3_column_int64(local1, Cast(c2fb_c_int, 2ULL))
            local7 = c2fb_external_sqlite3_column_int64(local1, Cast(c2fb_c_int, 3ULL))
            local8 = c2fb_external_sqlite3_column_bytes(local1, Cast(c2fb_c_int, 4ULL))
            local9 = CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob(local1, Cast(c2fb_c_int, 4ULL)))
            If (-Cast(c2fb_c_int, (((local5 <> 0) AndAlso (arg4 <> 0) AndAlso (local9 <> 0))))) Then
                local10 = (IIf(arg6, CPtr(c2fb_int64 Ptr, @(local6)), CPtr(c2fb_int64 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
                c2fb_temp_6 = Cast(c2fb_c_int, fts3SelectLeaf(arg0, arg4, arg5, local9, local8, CPtr(c2fb_int64 Ptr, @(local5)), local10))
                local0 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_label_0
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg6 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg7 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_7 = Cast(c2fb_int64, local5)
                    local6 = c2fb_temp_7
                End If
            End If
            c2fb_temp_8 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SegReaderNew(Cast(c2fb_c_int, (arg8->nSegment + Cast(c2fb_c_int, 1ULL))), ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg6 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg7 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))), local5, local6, local7, local9, local8, CPtr(Any Ptr Ptr, @(local4))))
            local0 = c2fb_temp_8
            If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_label_0
            End If
            c2fb_temp_9 = Cast(c2fb_c_int, fts3SegReaderCursorAppend(arg8, local4))
            local0 = c2fb_temp_9
        c2fb_flow_1:
        Loop
        c2fb_flow_0:
    End If
    c2fb_label_0:
    c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local1))
    local2 = c2fb_temp_10
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 101ULL))))) Then
        c2fb_temp_11 = Cast(c2fb_c_int, local2)
        local0 = c2fb_temp_11
    End If
    Return local0
End Function
Function sqlite3Fts3SegReaderCursor CDecl Alias "sqlite3Fts3SegReaderCursor" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_source_record_42 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3057
    Dim c2fb_temp_0 As Any Ptr

    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg8), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_42))))
    Return fts3SegReaderCursor(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
End Function
Private Function fts3SegReaderCursorAddZero CDecl Alias "fts3SegReaderCursorAddZero" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_source_record_42 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3089
    Return fts3SegReaderCursor(arg0, arg1, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))), arg2, arg3, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg4)
End Function
Private Function fts3TermSegReaderCursor CDecl Alias "fts3TermSegReaderCursor" (ByVal arg0 As c2fb_source_record_37 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_source_record_42 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3114
    Dim local0 As c2fb_source_record_42 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_source_record_42 Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_source_record_42 Ptr Ptr
    Dim c2fb_temp_16 As c2fb_source_record_42 Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, 7ULL)
    c2fb_temp_0 = CPtr(c2fb_source_record_42 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_42)))))
    local0 = c2fb_temp_0
    If local0 Then
        ' C automatic storage declaration
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = CPtr(c2fb_source_record_36 Ptr, arg0->base.pVtab)
        If arg3 Then
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local2 = c2fb_temp_1
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < local4->nIndex)))) <> 0)))))
                If (-Cast(c2fb_c_int, ((local4->aIndex[local2].nPrefix = arg2)))) Then
                    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local3 = c2fb_temp_3
                    c2fb_temp_4 = Cast(c2fb_c_int, sqlite3Fts3SegReaderCursor(local4, arg0->iLangid, local2, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))), arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), local0))
                    local1 = c2fb_temp_4
                    c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(local0->bLookup))
                    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_5) = c2fb_temp_6
                End If
            c2fb_flow_1:
                c2fb_temp_2 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            Wend
            c2fb_flow_0:
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local2 = c2fb_temp_7
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < local4->nIndex)))) <> 0)))))
                If (-Cast(c2fb_c_int, ((local4->aIndex[local2].nPrefix = Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))))))) Then
                    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local3 = c2fb_temp_9
                    c2fb_temp_10 = Cast(c2fb_c_int, sqlite3Fts3SegReaderCursor(local4, arg0->iLangid, local2, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))), arg1, arg2, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL), local0))
                    local1 = c2fb_temp_10
                    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_11 = Cast(c2fb_c_int, fts3SegReaderCursorAddZero(local4, arg0->iLangid, arg1, arg2, local0))
                        local1 = c2fb_temp_11
                    End If
                End If
            c2fb_flow_3:
                c2fb_temp_8 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
            Wend
            c2fb_flow_2:
        End If
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_12 = Cast(c2fb_c_int, sqlite3Fts3SegReaderCursor(local4, arg0->iLangid, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))), arg1, arg2, arg3, Cast(c2fb_c_int, &O0ULL), local0))
            local1 = c2fb_temp_12
            c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @(local0->bLookup))
            c2fb_temp_14 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, (arg3 = 0))))
            (*c2fb_temp_13) = c2fb_temp_14
        End If
    End If
    c2fb_temp_15 = CPtr(c2fb_source_record_42 Ptr Ptr, @((*arg4)))
    c2fb_temp_16 = local0
    (*c2fb_temp_15) = c2fb_temp_16
    Return local1
End Function
Private Sub fts3SegReaderCursorFree CDecl Alias "fts3SegReaderCursorFree" (ByVal arg0 As c2fb_source_record_42 Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3171
    c2fb_external_sqlite3Fts3SegReaderFinish(arg0)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
End Sub
Private Function fts3TermSelect CDecl Alias "fts3TermSelect" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_39 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3180
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_42 Ptr
    Dim local2 As c2fb_source_record_44
    Dim local3 As c2fb_source_record_41
    Dim c2fb_temp_0 As c2fb_source_record_42 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Const ZString Ptr Ptr
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As ZString Ptr Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Any Ptr Ptr
    Dim c2fb_temp_23 As c2fb_source_record_42 Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_42 Ptr, arg1->pSegcsr)
    local1 = c2fb_temp_0
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_44 Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_44))))
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(local3.flags))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000002ULL) Or Cast(c2fb_c_int, &H00000001ULL))) Or (IIf(arg1->isPrefix, Cast(c2fb_c_int, &H00000008ULL), Cast(c2fb_c_int, &O0ULL))))) Or (IIf(arg1->bFirst, Cast(c2fb_c_int, &H00000020ULL), Cast(c2fb_c_int, &O0ULL))))) Or (IIf((-Cast(c2fb_c_int, ((arg2 < arg0->nColumn)))), Cast(c2fb_c_int, &H00000004ULL), Cast(c2fb_c_int, &O0ULL))))))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(local3.iCol))
    c2fb_temp_5 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(Const ZString Ptr Ptr, @(local3.zTerm))
    c2fb_temp_7 = CPtr(Const ZString Ptr, arg1->z)
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(local3.nTerm))
    c2fb_temp_9 = Cast(c2fb_c_int, arg1->n)
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SegReaderStart(arg0, local1, CPtr(c2fb_source_record_41 Ptr, @(local3))))
    local0 = c2fb_temp_10
    Do
        c2fb_temp_13 = 0
        If ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local0)))) <> 0) Then
            c2fb_temp_12 = Cast(c2fb_c_int, 100ULL)
            c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SegReaderStep(arg0, local1))
            local0 = c2fb_temp_11
            c2fb_temp_13 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_12 = (c2fb_temp_11))))) <> 0))))
        End If
        If (c2fb_temp_13 = 0) Then Goto c2fb_flow_0
        c2fb_temp_14 = Cast(c2fb_c_int, fts3TermSelectMerge(arg0, CPtr(c2fb_source_record_44 Ptr, @(local2)), local1->aDoclist, local1->nDoclist))
        local0 = c2fb_temp_14
    c2fb_flow_1:
    Loop
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_15 = Cast(c2fb_c_int, fts3TermSelectFinishMerge(arg0, CPtr(c2fb_source_record_44 Ptr, @(local2))))
        local0 = c2fb_temp_15
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_16 = CPtr(ZString Ptr Ptr, @((*arg4)))
        c2fb_temp_17 = local2.aaOutput(Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_16) = c2fb_temp_17
        c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_19 = Cast(c2fb_c_int, local2.anOutput(Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_18) = c2fb_temp_19
    Else
        ' C automatic storage declaration
        c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local4 = c2fb_temp_20
        While (-Cast(c2fb_c_int, ((local4 < (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (16ULL * SizeOf(ZString Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))))))))))))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local2.aaOutput(local4)))
        c2fb_flow_3:
            c2fb_temp_21 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
        Wend
        c2fb_flow_2:
    End If
    fts3SegReaderCursorFree(local1)
    c2fb_temp_22 = CPtr(Any Ptr Ptr, @(arg1->pSegcsr))
    c2fb_temp_23 = CPtr(c2fb_source_record_42 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_22) = CPtr(Any Ptr, c2fb_temp_23)
    c2fb_temp_23 = CPtr(c2fb_source_record_42 Ptr, (*c2fb_temp_22))
    Return local0
End Function
Private Function fts3DoclistCountDocids CDecl Alias "fts3DoclistCountDocids" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3237
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0 Then
        local1 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[arg1])))
        local2 = arg0
        While (-Cast(c2fb_c_int, ((local2 < local1))))
            c2fb_temp_0 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
            Do
                c2fb_temp_1 = local2
                local2 = (c2fb_temp_1 + 1)
                If (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Byte Ptr, c2fb_temp_1)))) And Cast(c2fb_c_int, &H80ULL))) = 0) Then Goto c2fb_flow_2
                ' empty C statement
            c2fb_flow_3:
            Loop
            c2fb_flow_2:
            fts3PoslistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local2)))
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
    Return local0
End Function
' c2fb skipped fts3NextMethod: requires unconverted C function fts3EvalNext
Private Function fts3DocidRange CDecl Alias "fts3DocidRange" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64) As c2fb_int64
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3289
    Dim local0 As c2fb_c_int

    If arg0 Then
        local0 = c2fb_external_sqlite3_value_numeric_type(arg0)
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
            Return c2fb_external_sqlite3_value_int64(arg0)
        End If
    End If
    Return arg1
End Function
' c2fb skipped fts3FilterMethod: requires unconverted C function fts3EvalStart
Private Function fts3EofMethod CDecl Alias "fts3EofMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3434
    Dim local0 As c2fb_source_record_37 Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte

    local0 = CPtr(c2fb_source_record_37 Ptr, arg0)
    If local0->isEof Then
        fts3ClearCursor(local0)
        c2fb_temp_0 = CPtr(UByte Ptr, @(local0->isEof))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    Return local0->isEof
End Function
Private Function fts3RowidMethod CDecl Alias "fts3RowidMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3449
    Dim local0 As c2fb_source_record_37 Ptr
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    local0 = CPtr(c2fb_source_record_37 Ptr, arg0)
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_int64, local0->iPrevId)
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3ColumnMethod CDecl Alias "fts3ColumnMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3466
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_37 Ptr
    Dim local2 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_switch_value_2 As c2fb_uint64
    Dim c2fb_switch_state_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(c2fb_source_record_37 Ptr, arg0)
    local2 = CPtr(c2fb_source_record_36 Ptr, arg0->pVtab)
    ' C unused-parameter annotation
    c2fb_switch_value_2 = Cast(c2fb_uint64, Cast(c2fb_c_int, (arg2 - local2->nColumn)))
    c2fb_switch_state_3 = 0
    Select Case c2fb_switch_value_2
        Case Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))
            c2fb_switch_state_3 = 1
        Case Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))
            c2fb_switch_state_3 = 2
        Case Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))
            c2fb_switch_state_3 = 3
        Case Else
            c2fb_switch_state_3 = 4
    End Select
    Do
        Select Case c2fb_switch_state_3
        Case 0
            Exit Do
        Case 1
            c2fb_external_sqlite3_result_pointer(arg1, CPtr(Any Ptr, local1), StrPtr(!"fts3cursor"), Cast(c2fb_c_int, &O0ULL))
            c2fb_switch_state_3 = 0
        Case 2
            c2fb_external_sqlite3_result_int64(arg1, local1->iPrevId)
            c2fb_switch_state_3 = 0
        Case 3
            If CPtr(c2fb_source_record_40 Ptr, local1->pExpr) Then
                c2fb_external_sqlite3_result_int64(arg1, local1->iLangid)
                Goto c2fb_flow_0
            Else
                If (-Cast(c2fb_c_int, ((local2->zLanguageid = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_external_sqlite3_result_int(arg1, Cast(c2fb_c_int, &O0ULL))
                    Goto c2fb_flow_0
                Else
                    c2fb_temp_0 = Cast(c2fb_c_int, local2->nColumn)
                    arg2 = c2fb_temp_0
                    ' C switch fallthrough annotation
                End If
            End If
            c2fb_switch_state_3 = 4
        Case 4
            c2fb_temp_1 = Cast(c2fb_c_int, fts3CursorSeek(Cast(c2fb_c_int, &O0ULL), local1))
            local0 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (c2fb_external_sqlite3_data_count(local1->pStmt) - Cast(c2fb_c_int, 1ULL))) > arg2)))) <> 0))))) Then
                c2fb_external_sqlite3_result_value(arg1, CPtr(Any Ptr, c2fb_external_sqlite3_column_value(local1->pStmt, Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))))))
            End If
            c2fb_switch_state_3 = 0
        End Select
    Loop
    c2fb_flow_0:
    ' C unused-parameter annotation
    Return local0
End Function
Private Function fts3UpdateMethod CDecl Alias "fts3UpdateMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3520
    Return c2fb_external_sqlite3Fts3UpdateMethod(arg0, arg1, arg2, arg3)
End Function
Private Function fts3SyncMethod CDecl Alias "fts3SyncMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3533
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_source_record_36 Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, 64ULL)
    local1 = CPtr(c2fb_source_record_36 Ptr, arg0)
    ' C automatic storage declaration
    local3 = c2fb_external_sqlite3_last_insert_rowid(local1->db)
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3PendingTermsFlush(local1))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->nLeafAdd > (Cast(c2fb_c_uint, (local0 \ Cast(c2fb_c_uint, Cast(c2fb_c_int, 16ULL))))))))) <> 0) AndAlso (local1->nAutoincrmerge <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->nAutoincrmerge <> Cast(c2fb_c_int, &HffULL))))) <> 0))))) Then
        local4 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3MaxLevel(local1, CPtr(c2fb_c_int Ptr, @(local4))))
        local2 = c2fb_temp_1
        ' C unused-parameter annotation
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_uint, (local1->nLeafAdd * Cast(c2fb_c_uint, local4))))
        local5 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local5 + (Cast(c2fb_c_int, (local5 \ Cast(c2fb_c_int, 2ULL)))))))
        local5 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, local0))))) Then
            c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3Incrmerge(local1, local5, local1->nAutoincrmerge))
            local2 = c2fb_temp_4
        End If
    End If
    c2fb_external_sqlite3Fts3SegmentsClose(local1)
    c2fb_external_sqlite3_set_last_insert_rowid(local1->db, local3)
    Return local2
End Function
Private Function fts3SetHasStat CDecl Alias "fts3SetHasStat" (ByVal arg0 As c2fb_source_record_36 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3585
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->bHasStat) = Cast(c2fb_c_int, 2ULL))))) Then
        local1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s_stat"), arg0->zName))
        If local1 Then
            local2 = c2fb_external_sqlite3_table_column_metadata(arg0->db, arg0->zDb, CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
            c2fb_temp_0 = CPtr(UByte Ptr, @(arg0->bHasStat))
            c2fb_temp_1 = Cast(UByte, ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL)))))))
            (*c2fb_temp_0) = c2fb_temp_1
        Else
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_2
        End If
    End If
    Return local0
End Function
Private Function fts3BeginMethod CDecl Alias "fts3BeginMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3603
    Dim local0 As c2fb_source_record_36 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_uint Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_c_uint Ptr, @(local0->nLeafAdd))
    c2fb_temp_1 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, fts3SetHasStat(local0))
    local1 = c2fb_temp_2
    Return local1
End Function
Private Function fts3CommitMethod CDecl Alias "fts3CommitMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3626
    ' empty C statement
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' empty C statement
    ' empty C statement
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3RollbackMethod CDecl Alias "fts3RollbackMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3641
    Dim local0 As c2fb_source_record_36 Ptr

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    c2fb_external_sqlite3Fts3PendingTermsClear(local0)
    ' C unused-parameter annotation
    ' empty C statement
    ' empty C statement
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts3ReversePoslist CDecl Alias "fts3ReversePoslist" (ByVal arg0 As ZString Ptr, ByVal arg1 As ZString Ptr Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3656
    Dim local0 As ZString Ptr
    Dim local1 As Byte
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Byte
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr

    local0 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, ((*arg1)))[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))])))
    local1 = Cast(c2fb_c_int, &O0ULL)
    Do
        c2fb_temp_2 = 0
        If ((-Cast(c2fb_c_int, ((local0 > arg0)))) <> 0) Then
            c2fb_temp_0 = local0
            local0 = (c2fb_temp_0 - 1)
            c2fb_temp_1 = Cast(Byte, (*CPtr(Byte Ptr, c2fb_temp_0)))
            local1 = c2fb_temp_1
            c2fb_temp_2 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (c2fb_temp_1)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))
        End If
        If (c2fb_temp_2 = 0) Then Goto c2fb_flow_0
        ' empty C statement
    c2fb_flow_1:
    Loop
    c2fb_flow_0:
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 > arg0)))) <> 0) AndAlso (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local0))) And Cast(c2fb_c_int, &H80ULL)))) Or Cast(c2fb_c_int, local1))) <> 0)))))
        c2fb_temp_3 = local0
        local0 = (c2fb_temp_3 - 1)
        c2fb_temp_4 = Cast(Byte, (*CPtr(Byte Ptr, c2fb_temp_3)))
        local1 = c2fb_temp_4
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 > arg0)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((*arg1) > CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[Cast(c2fb_c_int, 2ULL)])))))) <> 0)))))) <> 0))))) Then
        c2fb_temp_5 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[Cast(c2fb_c_int, 2ULL)])))
        local0 = c2fb_temp_5
    End If
    Do
        c2fb_temp_6 = local0
        local0 = (c2fb_temp_6 + 1)
        If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, c2fb_temp_6))) And Cast(c2fb_c_int, &H80ULL))) = 0) Then Goto c2fb_flow_4
        ' empty C statement
    c2fb_flow_5:
    Loop
    c2fb_flow_4:
    c2fb_temp_7 = CPtr(ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_8 = local0
    (*c2fb_temp_7) = c2fb_temp_8
End Sub
Private Function fts3FunctionArg CDecl Alias "fts3FunctionArg" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_source_record_37 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3699
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_source_record_37 Ptr Ptr
    Dim c2fb_temp_1 As c2fb_source_record_37 Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_37 Ptr Ptr, @((*arg3)))
    c2fb_temp_1 = CPtr(c2fb_source_record_37 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_value_pointer(arg2, StrPtr(!"fts3cursor"))))
    (*c2fb_temp_0) = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((((*arg3)) <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_2
    Else
        local1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"illegal first argument to %s"), arg1))
        c2fb_external_sqlite3_result_error(arg0, CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_3
    End If
    Return local0
End Function
Private Sub fts3SnippetFunc CDecl Alias "fts3SnippetFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3721
    Dim local0 As c2fb_source_record_36 Ptr
    Dim local1 As c2fb_source_record_37 Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As Const ZString Ptr
    Dim local4 As Const ZString Ptr
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_switch_value_6 As c2fb_uint64
    Dim c2fb_switch_state_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_int64
    Dim c2fb_temp_10 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = StrPtr(!"<b>")
    local3 = StrPtr(!"</b>")
    local4 = StrPtr(!"<b>...</b>")
    local5 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local6 = Cast(c2fb_c_int, 15ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 6ULL))))) Then
        c2fb_external_sqlite3_result_error(arg0, StrPtr(!"wrong number of arguments to function snippet()"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Return
    End If
    If fts3FunctionArg(arg0, StrPtr(!"snippet"), arg2[Cast(c2fb_c_int, &O0ULL)], CPtr(c2fb_source_record_37 Ptr Ptr, @(local1))) Then
        Return
    End If
    c2fb_temp_0 = CPtr(c2fb_source_record_36 Ptr, local1->base.pVtab)
    local0 = c2fb_temp_0
    c2fb_switch_value_6 = Cast(c2fb_uint64, arg1)
    c2fb_switch_state_7 = 0
    Select Case c2fb_switch_value_6
        Case Cast(c2fb_uint64, Cast(c2fb_c_int, 6ULL))
            c2fb_switch_state_7 = 1
        Case Cast(c2fb_uint64, Cast(c2fb_c_int, 5ULL))
            c2fb_switch_state_7 = 2
        Case Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))
            c2fb_switch_state_7 = 3
        Case Cast(c2fb_uint64, Cast(c2fb_c_int, 3ULL))
            c2fb_switch_state_7 = 4
        Case Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))
            c2fb_switch_state_7 = 5
    End Select
    Do
        Select Case c2fb_switch_state_7
        Case 0
            Exit Do
        Case 1
            c2fb_temp_1 = Cast(c2fb_int64, c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, 5ULL)]))
            local6 = c2fb_temp_1
            ' C switch fallthrough annotation
            c2fb_switch_state_7 = 2
        Case 2
            c2fb_temp_2 = Cast(c2fb_int64, c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, 4ULL)]))
            local5 = c2fb_temp_2
            ' C switch fallthrough annotation
            c2fb_switch_state_7 = 3
        Case 3
            c2fb_temp_3 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, 3ULL)])))
            local4 = c2fb_temp_3
            ' C switch fallthrough annotation
            c2fb_switch_state_7 = 4
        Case 4
            c2fb_temp_4 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, 2ULL)])))
            local3 = c2fb_temp_4
            ' C switch fallthrough annotation
            c2fb_switch_state_7 = 5
        Case 5
            c2fb_temp_5 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, 1ULL)])))
            local2 = c2fb_temp_5
            c2fb_switch_state_7 = 0
        End Select
    Loop
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local4 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, (local3 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, (local2 = 0))) <> 0))))) Then
        c2fb_external_sqlite3_result_error_nomem(arg0)
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local5 >= Cast(c2fb_int64, local0->nColumn))))) <> 0))))) Then
            c2fb_external_sqlite3_result_text(arg0, StrPtr(!""), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_callback_7, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        Else
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts3CursorSeek(arg0, local1))))) Then
                If (-Cast(c2fb_c_int, ((local5 < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                    c2fb_temp_8 = Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                    local5 = c2fb_temp_8
                End If
                If (-Cast(c2fb_c_int, ((local6 < Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 64ULL)))))))) Then
                    c2fb_temp_9 = Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 64ULL))))
                    local6 = c2fb_temp_9
                End If
                If (-Cast(c2fb_c_int, ((local6 > Cast(c2fb_int64, Cast(c2fb_c_int, 64ULL)))))) Then
                    c2fb_temp_10 = Cast(c2fb_int64, Cast(c2fb_c_int, 64ULL))
                    local6 = c2fb_temp_10
                End If
                c2fb_external_sqlite3Fts3Snippet(arg0, local1, local2, local3, local4, local5, local6)
            End If
        End If
    End If
End Sub
Private Sub fts3OffsetsFunc CDecl Alias "fts3OffsetsFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3773
    Dim local0 As c2fb_source_record_37 Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If fts3FunctionArg(arg0, StrPtr(!"offsets"), arg2[Cast(c2fb_c_int, &O0ULL)], CPtr(c2fb_source_record_37 Ptr Ptr, @(local0))) Then
        Return
    End If
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts3CursorSeek(arg0, local0))))) Then
        c2fb_external_sqlite3Fts3Offsets(arg0, local0)
    End If
End Sub
Private Sub fts3OptimizeFunc CDecl Alias "fts3OptimizeFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3799
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_36 Ptr
    Dim local2 As c2fb_source_record_37 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If fts3FunctionArg(arg0, StrPtr(!"optimize"), arg2[Cast(c2fb_c_int, &O0ULL)], CPtr(c2fb_source_record_37 Ptr Ptr, @(local2))) Then
        Return
    End If
    c2fb_temp_0 = CPtr(c2fb_source_record_36 Ptr, local2->base.pVtab)
    local1 = c2fb_temp_0
    ' C unused-parameter annotation
    c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3Optimize(local1))
    local0 = c2fb_temp_1
    Select Case local0
        Case Cast(c2fb_c_int, &O0ULL)
            c2fb_external_sqlite3_result_text(arg0, StrPtr(!"Index optimized"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_callback_7, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        Case Cast(c2fb_c_int, 101ULL)
            c2fb_external_sqlite3_result_text(arg0, StrPtr(!"Index already optimal"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_callback_7, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        Case Else
            c2fb_external_sqlite3_result_error_code(arg0, local0)
    End Select
    c2fb_flow_0:
End Sub
Private Sub fts3MatchinfoFunc CDecl Alias "fts3MatchinfoFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3833
    Dim local0 As c2fb_source_record_37 Ptr
    Dim local1 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts3FunctionArg(arg0, StrPtr(!"matchinfo"), arg2[Cast(c2fb_c_int, &O0ULL)], CPtr(c2fb_source_record_37 Ptr Ptr, @(local0))))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_0 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, 1ULL)])))
            local1 = c2fb_temp_0
        End If
        c2fb_external_sqlite3Fts3Matchinfo(arg0, local0, local1)
    End If
End Sub
' c2fb skipped fts3FindFunctionMethod: outside the supported subset
' c2fb body diagnostic [unsupported-parameter-declaration] line 3853: fts3FindFunctionMethod: unsupported parameter declaration
Private Function fts3RenameMethod CDecl Alias "fts3RenameMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3889
    Dim local0 As c2fb_source_record_36 Ptr
    Dim local1 As Any Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    local1 = local0->db
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, fts3SetHasStat(local0))
    local2 = c2fb_temp_0
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3PendingTermsFlush(local0))
        local2 = c2fb_temp_1
    End If
    c2fb_temp_2 = CPtr(UByte Ptr, @(local0->bIgnoreSavepoint))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local0->zContentTbl = Cast(c2fb_c_int, &O0ULL))))) Then
        fts3DbExec(CPtr(c2fb_c_int Ptr, @(local2)), local1, StrPtr(!"ALTER TABLE %Q.'%q_content'  RENAME TO '%q_content';"), local0->zDb, local0->zName, arg1)
    End If
    If local0->bHasDocsize Then
        fts3DbExec(CPtr(c2fb_c_int Ptr, @(local2)), local1, StrPtr(!"ALTER TABLE %Q.'%q_docsize'  RENAME TO '%q_docsize';"), local0->zDb, local0->zName, arg1)
    End If
    If local0->bHasStat Then
        fts3DbExec(CPtr(c2fb_c_int Ptr, @(local2)), local1, StrPtr(!"ALTER TABLE %Q.'%q_stat'  RENAME TO '%q_stat';"), local0->zDb, local0->zName, arg1)
    End If
    fts3DbExec(CPtr(c2fb_c_int Ptr, @(local2)), local1, StrPtr(!"ALTER TABLE %Q.'%q_segments' RENAME TO '%q_segments';"), local0->zDb, local0->zName, arg1)
    fts3DbExec(CPtr(c2fb_c_int Ptr, @(local2)), local1, StrPtr(!"ALTER TABLE %Q.'%q_segdir'   RENAME TO '%q_segdir';"), local0->zDb, local0->zName, arg1)
    c2fb_temp_4 = CPtr(UByte Ptr, @(local0->bIgnoreSavepoint))
    c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_4) = c2fb_temp_5
    Return local2
End Function
Private Function fts3SavepointMethod CDecl Alias "fts3SavepointMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3951
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_36 Ptr
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(c2fb_source_record_36 Ptr, arg0)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' empty C statement
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1->bIgnoreSavepoint) = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((((CPtr(c2fb_source_record_33 Ptr, @(local1->aIndex[Cast(c2fb_c_int, &O0ULL)].hPending)))->count) > Cast(c2fb_c_int, &O0ULL))))) Then
            local2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"INSERT INTO %Q.%Q(%Q) VALUES('flush')"), local1->zDb, local1->zName, local1->zName))
            If local2 Then
                c2fb_temp_0 = CPtr(UByte Ptr, @(local1->bIgnoreSavepoint))
                c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_0) = c2fb_temp_1
                c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec(local1->db, CPtr(Const ZString Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_2
                c2fb_temp_3 = CPtr(UByte Ptr, @(local1->bIgnoreSavepoint))
                c2fb_temp_4 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_3) = c2fb_temp_4
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
            Else
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_5
            End If
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(local1->iSavepoint))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1 + Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_6) = c2fb_temp_7
        End If
    End If
    Return local0
End Function
Private Function fts3ReleaseMethod CDecl Alias "fts3ReleaseMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3984
    Dim local0 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' empty C statement
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(local0->iSavepoint))
    c2fb_temp_1 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3RollbackToMethod CDecl Alias "fts3RollbackToMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 3998
    Dim local0 As c2fb_source_record_36 Ptr

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' empty C statement
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1 + Cast(c2fb_c_int, 1ULL)))) <= local0->iSavepoint)))) Then
        c2fb_external_sqlite3Fts3PendingTermsClear(local0)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3ShadowName CDecl Alias "fts3ShadowName" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 4013
    Static local0(0 To 4) As Const ZString Ptr = {Cast(Const ZString Ptr, StrPtr(!"content")), Cast(Const ZString Ptr, StrPtr(!"docsize")), Cast(Const ZString Ptr, StrPtr(!"segdir")), Cast(Const ZString Ptr, StrPtr(!"segments")), Cast(Const ZString Ptr, StrPtr(!"stat"))}
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint

    ' C static array storage
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((Cast(c2fb_uint64, local1) < Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (5ULL * SizeOf(Const ZString Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Const ZString Ptr)))))))))
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(arg0, local0(local1)) = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3IntegrityMethod CDecl Alias "fts3IntegrityMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 4028
    Dim local0 As c2fb_source_record_36 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_36 Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3IntegrityCheck(local0, CPtr(c2fb_c_int Ptr, @(local2))))
    local1 = c2fb_temp_0
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local1 And Cast(c2fb_c_int, &HFFULL)))) = Cast(c2fb_c_int, 11ULL))))) <> 0))))) Then
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @((*arg4)))
        c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"unable to validate the inverted index for FTS%d table %s.%s: %s"), IIf(local0->bFts4, Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 3ULL)), arg1, arg2, CPtr(Const ZString Ptr, c2fb_external_sqlite3_errstr(local1))))
        (*c2fb_temp_1) = c2fb_temp_2
        If (*arg4) Then
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_3
        End If
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_4 = CPtr(ZString Ptr Ptr, @((*arg4)))
            c2fb_temp_5 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"malformed inverted index for FTS%d table %s.%s"), IIf(local0->bFts4, Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 3ULL)), arg1, arg2))
            (*c2fb_temp_4) = c2fb_temp_5
            If (-Cast(c2fb_c_int, (((*arg4) = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local1 = c2fb_temp_6
            End If
        End If
    End If
    c2fb_external_sqlite3Fts3SegmentsClose(local0)
    Return local1
End Function
Private Sub hashDestroy CDecl Alias "hashDestroy" (ByVal arg0 As Any Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 4092
    Dim local0 As c2fb_source_record_43 Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_43 Ptr, arg0)
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(local0->nRef))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
    If (-Cast(c2fb_c_int, ((local0->nRef <= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3Fts3HashClear(CPtr(c2fb_source_record_33 Ptr, @(local0->hash)))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
' c2fb skipped sqlite3Fts3Init: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 4126: sqlite3Fts3Init: assignment parser stopped at byte 63 (rc = sqlite3_create_module_v2(         db, "fts3", &fts3Module, (void *)pHash, hashDestroy     )): , (void *)pHash, hashDestroy     )
' c2fb skipped fts3EvalAllocateReaders: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4240: fts3EvalAllocateReaders: expression parser stopped at byte 15 in (pExpr->pPhrase->nToken): ->nToken
' c2fb skipped fts3EvalPhraseMergeToken: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 4282: fts3EvalPhraseMergeToken: assignment parser stopped at byte 15 (sqlite3_free(p->doclist.aAll)): ->doclist.aAll)
' c2fb skipped fts3EvalPhraseLoad: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4346: fts3EvalPhraseLoad: expression parser stopped at byte 18 in (rc==0 && iToken<p->nToken): ->nToken
' c2fb skipped fts3EvalDeferredPhrase: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4383: fts3EvalDeferredPhrase: expression parser stopped at byte 9 in ((pPhrase->doclist.bFreeList ? pPhrase->doclist.pList : 0)): ->doclist.bFreeList ? pPhrase->doclist.pList : 0)
' c2fb skipped fts3EvalPhraseStart: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4500: fts3EvalPhraseStart: expression parser stopped at byte 50 in ((bOptOk    && pCsr->bDesc==pTab->bDescIdx    && p->nToken<=4 && p->nToken>0      )): ->nToken<=4 && p->nToken>0      )
Sub sqlite3Fts3DoclistPrev CDecl Alias "sqlite3Fts3DoclistPrev" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As c2fb_int64 Ptr, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As UByte Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 4557
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_int64
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_int64 Ptr
    Dim c2fb_temp_10 As c2fb_int64
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_int64 Ptr
    Dim c2fb_temp_12 As c2fb_int64
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte
    Dim local9 As ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As ZString Ptr Ptr
    Dim c2fb_temp_18 As ZString Ptr

    local0 = (*arg3)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = arg1
        local4 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1)[arg2])))
        local5 = Cast(c2fb_c_int, 1ULL)
        While (-Cast(c2fb_c_int, ((local3 < local4))))
            ' C automatic storage declaration
            c2fb_temp_0 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local3), CPtr(c2fb_int64 Ptr, @(local6)))))
            local3 = c2fb_temp_0
            c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 + (Cast(c2fb_int64, (Cast(c2fb_int64, local5) * local6))))))
            local1 = c2fb_temp_1
            c2fb_temp_2 = local3
            local2 = c2fb_temp_2
            fts3PoslistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local3)))
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < local4)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local3))) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                c2fb_temp_3 = local3
                local3 = (c2fb_temp_3 + 1)
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            c2fb_temp_4 = Cast(c2fb_c_int, (IIf(arg0, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL))))
            local5 = c2fb_temp_4
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg5)))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local4)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local2))))))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(ZString Ptr Ptr, @((*arg3)))
        c2fb_temp_8 = local2
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = CPtr(c2fb_int64 Ptr, @((*arg4)))
        c2fb_temp_10 = Cast(c2fb_int64, local1)
        (*c2fb_temp_9) = c2fb_temp_10
    Else
        local7 = (IIf(arg0, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL)))
        ' C automatic storage declaration
        fts3GetReverseVarint(CPtr(ZString Ptr Ptr, @(local0)), arg1, CPtr(c2fb_int64 Ptr, @(local8)))
        c2fb_temp_11 = CPtr(c2fb_int64 Ptr, @((*arg4)))
        c2fb_temp_12 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_11) - (Cast(c2fb_int64, (Cast(c2fb_int64, local7) * local8))))))
        (*c2fb_temp_11) = c2fb_temp_12
        If (-Cast(c2fb_c_int, ((local0 = arg1)))) Then
            c2fb_temp_13 = CPtr(UByte Ptr, @((*arg6)))
            c2fb_temp_14 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_13) = c2fb_temp_14
        Else
            local9 = local0
            fts3ReversePoslist(arg1, CPtr(ZString Ptr Ptr, @(local0)))
            c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg5)))
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local9)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local0))))))
            (*c2fb_temp_15) = c2fb_temp_16
        End If
        c2fb_temp_17 = CPtr(ZString Ptr Ptr, @((*arg3)))
        c2fb_temp_18 = local0
        (*c2fb_temp_17) = c2fb_temp_18
    End If
End Sub
Sub sqlite3Fts3DoclistNext CDecl Alias "sqlite3Fts3DoclistNext" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As c2fb_int64 Ptr, ByVal arg5 As UByte Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 4613
    Dim local0 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte
    Dim local1 As c2fb_int64
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr

    local0 = (*arg3)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = arg1
        local0 = c2fb_temp_0
        c2fb_temp_1 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local0) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local0), arg4)))
        local0 = c2fb_temp_1
    Else
        fts3PoslistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local0)))
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1)[arg2])))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local0))) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            c2fb_temp_2 = local0
            local0 = (c2fb_temp_2 + 1)
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local0 >= CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1)[arg2])))))) Then
            c2fb_temp_3 = CPtr(UByte Ptr, @((*arg5)))
            c2fb_temp_4 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_3) = c2fb_temp_4
        Else
            ' C automatic storage declaration
            c2fb_temp_5 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local0) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local0), CPtr(c2fb_int64 Ptr, @(local1)))))
            local0 = c2fb_temp_5
            c2fb_temp_6 = CPtr(c2fb_int64 Ptr, @((*arg4)))
            c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_6) + (Cast(c2fb_int64, (Cast(c2fb_int64, (IIf(arg0, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL)))) * local1))))))
            (*c2fb_temp_6) = c2fb_temp_7
        End If
    End If
    c2fb_temp_8 = CPtr(ZString Ptr Ptr, @((*arg3)))
    c2fb_temp_9 = local0
    (*c2fb_temp_8) = c2fb_temp_9
End Sub
Private Sub fts3EvalDlPhraseNext CDecl Alias "fts3EvalDlPhraseNext" (ByVal arg0 As c2fb_source_record_36 Ptr, ByVal arg1 As c2fb_source_record_38 Ptr, ByVal arg2 As UByte Ptr)
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 4650
    Dim local0 As ZString Ptr
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte
    Dim local2 As c2fb_int64
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As c2fb_int64 Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim c2fb_temp_10 As c2fb_int64 Ptr
    Dim c2fb_temp_11 As c2fb_int64
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As UByte Ptr
    Dim c2fb_temp_20 As UByte

    ' C automatic storage declaration
    ' C automatic storage declaration
    If arg1->pNextDocid Then
        c2fb_temp_0 = arg1->pNextDocid
        local0 = c2fb_temp_0
        ' C unused-parameter annotation
    Else
        c2fb_temp_1 = arg1->aAll
        local0 = c2fb_temp_1
    End If
    c2fb_temp_4 = 1
    If (((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) = 0) Then
        c2fb_temp_3 = local0
        c2fb_temp_2 = CPtr(ZString Ptr, (CPtr(Byte Ptr, arg1->aAll) + arg1->nAll))
        local1 = c2fb_temp_2
        c2fb_temp_4 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_3 >= (c2fb_temp_2))))) <> 0))))
    End If
    If c2fb_temp_4 Then
        c2fb_temp_5 = CPtr(UByte Ptr, @((*arg2)))
        c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_5) = c2fb_temp_6
    Else
        ' C automatic storage declaration
        c2fb_temp_7 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local0) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local0), CPtr(c2fb_int64 Ptr, @(local2)))))
        local0 = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->bDescIdx) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->pNextDocid = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_8 = CPtr(c2fb_int64 Ptr, @(arg1->iDocid))
            c2fb_temp_9 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_8) + local2)))
            (*c2fb_temp_8) = c2fb_temp_9
        Else
            c2fb_temp_10 = CPtr(c2fb_int64 Ptr, @(arg1->iDocid))
            c2fb_temp_11 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_10) - local2)))
            (*c2fb_temp_10) = c2fb_temp_11
        End If
        c2fb_temp_12 = CPtr(ZString Ptr Ptr, @(arg1->pList))
        c2fb_temp_13 = local0
        (*c2fb_temp_12) = c2fb_temp_13
        fts3PoslistCopy(Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local0)))
        c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @(arg1->nList))
        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local0)) - CPtr(Byte Ptr, CPtr(Byte Ptr, arg1->pList))))))
        (*c2fb_temp_14) = c2fb_temp_15
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < local1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local0))) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            c2fb_temp_16 = local0
            local0 = (c2fb_temp_16 + 1)
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_17 = CPtr(ZString Ptr Ptr, @(arg1->pNextDocid))
        c2fb_temp_18 = local0
        (*c2fb_temp_17) = c2fb_temp_18
        ' C unused-parameter annotation
        c2fb_temp_19 = CPtr(UByte Ptr, @((*arg2)))
        c2fb_temp_20 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_19) = c2fb_temp_20
    End If
End Sub
' c2fb skipped incrPhraseTokenNext: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4714: incrPhraseTokenNext: expression parser stopped at byte 8 in (pPhrase->iDoclistToken==iToken): ->iDoclistToken==iToken
' c2fb skipped fts3EvalIncrPhraseNext: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4766: fts3EvalIncrPhraseNext: expression parser stopped at byte 3 in (&p->doclist): ->doclist
' c2fb skipped fts3EvalPhraseNext: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4867: fts3EvalPhraseNext: expression parser stopped at byte 3 in (&p->doclist): ->doclist
' c2fb skipped fts3EvalStartReaders: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4906: fts3EvalStartReaders: expression parser stopped at byte 15 in (pExpr->pPhrase->nToken): ->nToken
' c2fb skipped fts3EvalTokenCosts: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 4959: fts3EvalTokenCosts: expression parser stopped at byte 21 in (*pRc==0 && i<pPhrase->nToken): ->nToken
Private Function fts3EvalAverageDocsize CDecl Alias "fts3EvalAverageDocsize" (ByVal arg0 As c2fb_source_record_37 Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 5013
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_36 Ptr
    Dim local2 As Any Ptr
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_int64
    Dim local5 As Const ZString Ptr
    Dim local6 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As c2fb_int64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->nRowAvg = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = CPtr(c2fb_source_record_36 Ptr, arg0->base.pVtab)
        ' C automatic storage declaration
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SelectDoctotal(local1, CPtr(Any Ptr Ptr, @(local2))))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local0
        End If
        c2fb_temp_1 = CPtr(Const ZString Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob(local2, Cast(c2fb_c_int, &O0ULL))))
        local6 = c2fb_temp_1
        ' empty C statement
        If local6 Then
            c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local6)[c2fb_external_sqlite3_column_bytes(local2, Cast(c2fb_c_int, &O0ULL))])))
            local5 = c2fb_temp_2
            c2fb_temp_3 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local6) + sqlite3Fts3GetVarintBounded(local6, local5, CPtr(c2fb_int64 Ptr, @(local3)))))
            local6 = c2fb_temp_3
            While (-Cast(c2fb_c_int, ((local6 < local5))))
                c2fb_temp_4 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local6) + sqlite3Fts3GetVarintBounded(local6, local5, CPtr(c2fb_int64 Ptr, @(local4)))))
                local6 = c2fb_temp_4
            c2fb_flow_1:
            Wend
            c2fb_flow_0:
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
            c2fb_external_sqlite3_reset(local2)
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        c2fb_temp_5 = CPtr(c2fb_int64 Ptr, @(arg0->nDoc))
        c2fb_temp_6 = Cast(c2fb_int64, local3)
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(arg0->nRowAvg))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, ((Cast(c2fb_int64, ((Cast(c2fb_int64, (local4 \ local3))) + Cast(c2fb_int64, local1->nPgsz)))) \ Cast(c2fb_int64, local1->nPgsz))))))
        (*c2fb_temp_7) = c2fb_temp_8
        ' C unused-parameter annotation
        c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local2))
        local0 = c2fb_temp_9
    End If
    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_11 = Cast(c2fb_c_int, arg0->nRowAvg)
    (*c2fb_temp_10) = c2fb_temp_11
    Return local0
End Function
' c2fb skipped fts3EvalSelectDeferred: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 5074: fts3EvalSelectDeferred: expression parser stopped at byte 23 in (ii==0 || (pTC->pPhrase->nToken>1 && ii!=nToken-1)): ->nToken>1 && ii!=nToken-1)
' c2fb skipped fts3EvalStart: requires unconverted C function fts3EvalAllocateReaders
' c2fb skipped fts3EvalInvalidatePoslist: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 5256: fts3EvalInvalidatePoslist: expression parser stopped at byte 8 in (pPhrase->doclist.bFreeList): ->doclist.bFreeList
' c2fb skipped fts3EvalNearTrim: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 5287: fts3EvalNearTrim: expression parser stopped at byte 16 in (nNear + pPhrase->nToken): ->nToken
' c2fb skipped fts3EvalNextRow: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 5363: fts3EvalNextRow: expression parser stopped at byte 16 in (pRight->pPhrase->doclist.aAll): ->doclist.aAll
' c2fb skipped fts3EvalNearTest: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 5505: fts3EvalNearTest: assignment parser stopped at byte 27 (nTmp += p->pRight->pPhrase->doclist.nList): ->doclist.nList
' c2fb skipped fts3EvalTestExpr: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 5587: fts3EvalTestExpr: expression parser stopped at byte 101 in (pCsr->pDeferred && (pExpr->bDeferred || (             pExpr->iDocid==pCsr->iPrevId && pExpr->pPhrase->doclist.pList     ): ->doclist.pList         ))
' c2fb skipped sqlite3Fts3EvalTestDeferred: requires unconverted C function fts3EvalTestExpr
' c2fb skipped fts3EvalNext: requires unconverted C function fts3EvalNextRow
' c2fb skipped fts3EvalRestart: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 5771: fts3EvalRestart: expression parser stopped at byte 8 in (pPhrase->bIncr): ->bIncr
' c2fb skipped sqlite3Fts3MsrCancel: requires unconverted C function fts3EvalRestart
' c2fb skipped fts3EvalUpdateCounts: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 5832: fts3EvalUpdateCounts: expression parser stopped at byte 19 in (pPhrase && pPhrase->doclist.pList): ->doclist.pList
Private Function fts3AllocateMSI CDecl Alias "fts3AllocateMSI" (ByVal arg0 As c2fb_source_record_40 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 5868
    Dim local0 As c2fb_source_record_36 Ptr
    Dim c2fb_temp_0 As c2fb_c_uint Ptr Ptr
    Dim c2fb_temp_1 As c2fb_c_uint Ptr
    Dim c2fb_temp_2 As Any Ptr

    local0 = CPtr(c2fb_source_record_36 Ptr, arg2)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->aMI = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_uint Ptr Ptr, @(arg0->aMI))
        c2fb_temp_1 = CPtr(c2fb_c_uint Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (local0->nColumn * Cast(c2fb_c_int, 3ULL)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint))))))))
        (*c2fb_temp_0) = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((arg0->aMI = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
    End If
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0->aMI), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (local0->nColumn * Cast(c2fb_c_int, 3ULL)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped fts3EvalGatherStats: requires unconverted C function fts3EvalRestart
' c2fb skipped sqlite3Fts3EvalPhraseStats: requires unconverted C function fts3EvalGatherStats
' c2fb skipped sqlite3Fts3EvalPhrasePoslist: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 6045: sqlite3Fts3EvalPhrasePoslist: expression parser stopped at byte 9 in ((pPhrase->iColumn<pTab->nColumn && pPhrase->iColumn!=iCol)): ->iColumn<pTab->nColumn && pPhrase->iColumn!=iCol)
' c2fb skipped sqlite3Fts3EvalPhraseCleanup: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 6188: sqlite3Fts3EvalPhraseCleanup: assignment parser stopped at byte 21 (sqlite3_free(pPhrase->doclist.aAll)): ->doclist.aAll)
/' end of sqlite3_bulk_fts3_core.bas '/

#endif

/' end of sqlite3_bulk_fts3_core.bas '/
