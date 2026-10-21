/'
** 2009 Oct 23
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
** This file is part of the SQLite FTS3 extension module. Specifically,
** this file contains code to insert, update and delete rows from FTS3
** tables. It also contains code to merge FTS3 b-tree segments. Some
** of the sub-routines used to merge segments are also used by the query 
** code in fts3.c.
'/
/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_bulk_fts3_write_candidates.bas

    Purpose:

        Hold translated candidates from ext/fts3/fts3_write.c for dependency repair.

    Responsibilities:

        - Build pending terms and write FTS segments.
        - Preserve the upstream record and varint flow.

    This file intentionally does NOT contain:

        - The FTS3 expression, segment-reader, and hash dependencies.
        - Test support.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
#include once "sqlite3_btree.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_expr_types.bi"
#include once "sqlite3_hash_types.bi"
#include once "sqlite3_pager.bi"
#include once "sqlite3_parser_types.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_vdbe_core.bi"
#include once "sqlite3_vdbe_mem_types.bi"

/' ------------------------------------------------------------------------- '/
/' FTS3 segment-writing candidates                                           '/
/' ------------------------------------------------------------------------- '/

#ifndef __C2FB_BODY_C_ABI_TYPES__
#define __C2FB_BODY_C_ABI_TYPES__

#ifndef __C2FB_ABI_TYPE_C_INT__
#define __C2FB_ABI_TYPE_C_INT__
Type c2fb_c_int As SQLITE_C_INT
#endif
#ifndef __C2FB_ABI_TYPE_C_UINT__
#define __C2FB_ABI_TYPE_C_UINT__
Type c2fb_c_uint As SQLITE_C_UINT
#endif
#ifndef __C2FB_ABI_TYPE_C_LONG__
#define __C2FB_ABI_TYPE_C_LONG__
Type c2fb_c_long As SQLITE_C_LONG
#endif
#ifndef __C2FB_ABI_TYPE_C_ULONG__
#define __C2FB_ABI_TYPE_C_ULONG__
Type c2fb_c_ulong As SQLITE_C_ULONG
#endif
#ifndef __C2FB_ABI_TYPE_INT64__
#define __C2FB_ABI_TYPE_INT64__
Type c2fb_int64 As sqlite3_int64
#endif
#ifndef __C2FB_ABI_TYPE_UINT64__
#define __C2FB_ABI_TYPE_UINT64__
Type c2fb_uint64 As sqlite3_uint64
#endif
#ifndef __C2FB_ABI_TYPE_SIZE_T__
#define __C2FB_ABI_TYPE_SIZE_T__
Type c2fb_size_t As SQLITE_SIZE_T
#endif
#endif

Declare Function sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function sqlite3_blob_reopen CDecl Alias "sqlite3_blob_reopen" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3_blob_close CDecl Alias "sqlite3_blob_close" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_blob_bytes CDecl Alias "sqlite3_blob_bytes" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_blob_read CDecl Alias "sqlite3_blob_read" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int

Type c2fb_callback_2 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As SQLITE_C_INT) As SQLITE_C_INT
Type c2fb_callback_217 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr) As c2fb_c_int

Private Type c2fb_source_record_402
    pModule As Any Ptr
End Type

Private Type c2fb_source_record_404
    count As c2fb_c_int
    chain As Any Ptr
End Type

Private Type c2fb_source_record_405
    keyClass As Byte
    copyKey As Byte
    count As c2fb_c_int
    first As Any Ptr
    htsize As c2fb_c_int
    ht As c2fb_source_record_404 Ptr
End Type

Private Type c2fb_source_record_406
    next As c2fb_source_record_406 Ptr
    prev As c2fb_source_record_406 Ptr
    data As Any Ptr
    pKey As Any Ptr
    nKey As c2fb_c_int
End Type

Private Type c2fb_source_record_407
    nPrefix As c2fb_c_int
    hPending As c2fb_source_record_405
End Type

Private Type c2fb_source_record_408
    base As SqliteVtab
    db As sqlite3 Ptr
    zDb As Const ZString Ptr
    zName As Const ZString Ptr
    nColumn As c2fb_c_int
    azColumn As ZString Ptr Ptr
    abNotindexed As UByte Ptr
    pTokenizer As c2fb_source_record_402 Ptr
    zContentTbl As ZString Ptr
    zLanguageid As ZString Ptr
    nAutoincrmerge As c2fb_c_int
    nLeafAdd As c2fb_c_uint
    bLock As c2fb_c_int
    aStmt(0 To 39) As SqliteVdbe Ptr
    pSeekStmt As SqliteVdbe Ptr
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
    aIndex As c2fb_source_record_407 Ptr
    nMaxPendingData As c2fb_c_int
    nPendingData As c2fb_c_int
    iPrevDocid As c2fb_int64
    iPrevLangid As c2fb_c_int
    bPrevDelete As c2fb_c_int
End Type

Private Type c2fb_source_record_409
    base As SqliteVtabCursor
    eSearch As Short
    isEof As UByte
    isRequireSeek As UByte
    bSeekStmt As UByte
    pStmt As SqliteVdbe Ptr
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

Private Type c2fb_source_record_411
    z As ZString Ptr
    n As c2fb_c_int
    isPrefix As c2fb_c_int
    bFirst As c2fb_c_int
    pDeferred As Any Ptr
    pSegcsr As Any Ptr
End Type

Private Type c2fb_source_record_413
    zTerm As Const ZString Ptr
    nTerm As c2fb_c_int
    iCol As c2fb_c_int
    flags As c2fb_c_int
End Type

Private Type c2fb_source_record_414
    apSegment As Any Ptr Ptr
    nSegment As c2fb_c_int
    nAdvance As c2fb_c_int
    pFilter As c2fb_source_record_413 Ptr
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

Private Type c2fb_source_record_415
    nData As c2fb_int64
    aData As ZString Ptr
    nSpace As c2fb_int64
    iLastDocid As c2fb_int64
    iLastCol As c2fb_int64
    iLastPos As c2fb_int64
End Type

Private Type c2fb_source_record_416
    pToken As c2fb_source_record_411 Ptr
    iCol As c2fb_c_int
    pNext As c2fb_source_record_416 Ptr
    pList As c2fb_source_record_415 Ptr
End Type

Private Type c2fb_source_record_417
    iIdx As c2fb_c_int
    bLookup As UByte
    rootOnly As UByte
    iStartBlock As c2fb_int64
    iLeafEndBlock As c2fb_int64
    iEndBlock As c2fb_int64
    iCurrentBlock As c2fb_int64
    aNode As ZString Ptr
    nNode As c2fb_c_int
    nPopulate As c2fb_c_int
    pBlob As Any Ptr
    ppNextElem As c2fb_source_record_406 Ptr Ptr
    nTerm As c2fb_c_int
    zTerm As ZString Ptr
    nTermAlloc As c2fb_c_int
    aDoclist As ZString Ptr
    nDoclist As c2fb_c_int
    pOffsetList As ZString Ptr
    nOffsetList As c2fb_c_int
    iDocid As c2fb_int64
End Type

Private Type c2fb_source_record_418
    pTree As Any Ptr
    iFirst As c2fb_int64
    iFree As c2fb_int64
    zTerm As ZString Ptr
    nTerm As c2fb_c_int
    nMalloc As c2fb_c_int
    zMalloc As ZString Ptr
    nSize As c2fb_c_int
    nData As c2fb_c_int
    aData As ZString Ptr
    nLeafData As c2fb_int64
End Type

Private Type c2fb_source_record_419
    pParent As c2fb_source_record_419 Ptr
    pRight As c2fb_source_record_419 Ptr
    pLeftmost As c2fb_source_record_419 Ptr
    nEntry As c2fb_c_int
    zTerm As ZString Ptr
    nTerm As c2fb_c_int
    nMalloc As c2fb_c_int
    zMalloc As ZString Ptr
    nData As c2fb_c_int
    aData As ZString Ptr
End Type

Private Type c2fb_source_record_420
    a As ZString Ptr
    n As c2fb_c_int
    nAlloc As c2fb_c_int
End Type

Private Type c2fb_source_record_423
    aNode As Const ZString Ptr
    nNode As c2fb_c_int
    iOff As c2fb_c_int
    iChild As c2fb_int64
    term As c2fb_source_record_420
    aDoclist As Const ZString Ptr
    nDoclist As c2fb_c_int
End Type

Declare Function sqlite3Fts3PrepareStmt CDecl Alias "sqlite3Fts3PrepareStmt" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As SqliteVdbe Ptr Ptr) As c2fb_c_int
Declare Function getAbsoluteLevel CDecl Alias "getAbsoluteLevel" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_int64
Declare Function fts3PendingListAppendVarint CDecl Alias "fts3PendingListAppendVarint" (ByVal arg0 As c2fb_source_record_415 Ptr Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function fts3PendingListAppend CDecl Alias "fts3PendingListAppend" (ByVal arg0 As c2fb_source_record_415 Ptr Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub fts3PendingListDelete CDecl Alias "fts3PendingListDelete" (ByVal arg0 As c2fb_source_record_415 Ptr)
Declare Function fts3PendingTermsAddOne CDecl Alias "fts3PendingTermsAddOne" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_405 Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function fts3PendingTermsDocid CDecl Alias "fts3PendingTermsDocid" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Declare Sub sqlite3Fts3PendingTermsClear CDecl Alias "sqlite3Fts3PendingTermsClear" (ByVal arg0 As c2fb_source_record_408 Ptr)
Declare Function langidFromSelect CDecl Alias "langidFromSelect" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function sqlite3Fts3ReadBlock CDecl Alias "sqlite3Fts3ReadBlock" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub sqlite3Fts3SegmentsClose CDecl Alias "sqlite3Fts3SegmentsClose" (ByVal arg0 As c2fb_source_record_408 Ptr)
Declare Function fts3SegReaderIncrRead CDecl Alias "fts3SegReaderIncrRead" (ByVal arg0 As c2fb_source_record_417 Ptr) As c2fb_c_int
Declare Function fts3SegReaderRequire CDecl Alias "fts3SegReaderRequire" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Sub fts3SegReaderSetEof CDecl Alias "fts3SegReaderSetEof" (ByVal arg0 As c2fb_source_record_417 Ptr)
Declare Function fts3SegReaderNext CDecl Alias "fts3SegReaderNext" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts3SegReaderFirstDocid CDecl Alias "fts3SegReaderFirstDocid" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr) As c2fb_c_int
Declare Function fts3SegReaderNextDocid CDecl Alias "fts3SegReaderNextDocid" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts3MsrOvfl CDecl Alias "sqlite3Fts3MsrOvfl" (ByVal arg0 As c2fb_source_record_409 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub sqlite3Fts3SegReaderFree CDecl Alias "sqlite3Fts3SegReaderFree" (ByVal arg0 As c2fb_source_record_417 Ptr)
Declare Function sqlite3Fts3SegReaderNew CDecl Alias "sqlite3Fts3SegReaderNew" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_int64, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_source_record_417 Ptr Ptr) As c2fb_c_int
Declare Function fts3CompareElemByTerm CDecl Alias "fts3CompareElemByTerm" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr) As c2fb_c_int
Declare Function sqlite3Fts3SegReaderPending CDecl Alias "sqlite3Fts3SegReaderPending" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_source_record_417 Ptr Ptr) As c2fb_c_int
Declare Function fts3SegReaderCmp CDecl Alias "fts3SegReaderCmp" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr) As c2fb_c_int
Declare Function fts3SegReaderDoclistCmp CDecl Alias "fts3SegReaderDoclistCmp" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr) As c2fb_c_int
Declare Function fts3SegReaderDoclistCmpRev CDecl Alias "fts3SegReaderDoclistCmpRev" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr) As c2fb_c_int
Declare Function fts3SegReaderTermCmp CDecl Alias "fts3SegReaderTermCmp" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Sub fts3SegReaderSort CDecl Alias "fts3SegReaderSort" (ByVal arg0 As c2fb_source_record_417 Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_callback_217)
Declare Function fts3PrefixCompress CDecl Alias "fts3PrefixCompress" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function fts3NodeAddTerm CDecl Alias "fts3NodeAddTerm" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_419 Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function fts3TreeFinishNode CDecl Alias "fts3TreeFinishNode" (ByVal arg0 As c2fb_source_record_419 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Sub fts3NodeFree CDecl Alias "fts3NodeFree" (ByVal arg0 As c2fb_source_record_419 Ptr)
Declare Sub fts3SegWriterFree CDecl Alias "fts3SegWriterFree" (ByVal arg0 As c2fb_source_record_418 Ptr)
Declare Sub fts3ColumnFilter CDecl Alias "fts3ColumnFilter" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Function fts3MsrBufferData CDecl Alias "fts3MsrBufferData" (ByVal arg0 As c2fb_source_record_414 Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts3MsrIncrNext CDecl Alias "sqlite3Fts3MsrIncrNext" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts3SegReaderStart CDecl Alias "fts3SegReaderStart" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts3SegReaderStart CDecl Alias "sqlite3Fts3SegReaderStart" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As c2fb_source_record_413 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3MsrIncrStart CDecl Alias "sqlite3Fts3MsrIncrStart" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts3MsrIncrRestart CDecl Alias "sqlite3Fts3MsrIncrRestart" (ByVal arg0 As c2fb_source_record_414 Ptr) As c2fb_c_int
Declare Function fts3GrowSegReaderBuffer CDecl Alias "fts3GrowSegReaderBuffer" (ByVal arg0 As c2fb_source_record_414 Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts3SegReaderStep CDecl Alias "sqlite3Fts3SegReaderStep" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr) As c2fb_c_int
Declare Sub sqlite3Fts3SegReaderFinish CDecl Alias "sqlite3Fts3SegReaderFinish" (ByVal arg0 As c2fb_source_record_414 Ptr)
Declare Sub fts3ReadEndBlockField CDecl Alias "fts3ReadEndBlockField" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As c2fb_int64 Ptr)
Declare Sub fts3EncodeIntArray CDecl Alias "fts3EncodeIntArray" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_uint Ptr, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Sub fts3DecodeIntArray CDecl Alias "fts3DecodeIntArray" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_uint Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub blobGrowBuffer CDecl Alias "blobGrowBuffer" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr)
Declare Function nodeReaderNext CDecl Alias "nodeReaderNext" (ByVal arg0 As c2fb_source_record_423 Ptr) As c2fb_c_int
Declare Sub nodeReaderRelease CDecl Alias "nodeReaderRelease" (ByVal arg0 As c2fb_source_record_423 Ptr)
Declare Function nodeReaderInit CDecl Alias "nodeReaderInit" (ByVal arg0 As c2fb_source_record_423 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts3AppendToNode CDecl Alias "fts3AppendToNode" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_source_record_420 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function fts3TermCmp CDecl Alias "fts3TermCmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Sub fts3StartNode CDecl Alias "fts3StartNode" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64)
Declare Function fts3TruncateNode CDecl Alias "fts3TruncateNode" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_420 Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_int64 Ptr) As c2fb_c_int
Declare Sub fts3IncrmergeHintPush CDecl Alias "fts3IncrmergeHintPush" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
Declare Function fts3IncrmergeHintPop CDecl Alias "fts3IncrmergeHintPop" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts3Getint CDecl Alias "fts3Getint" (ByVal arg0 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3DoIncrmerge CDecl Alias "fts3DoIncrmerge" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function fts3ChecksumEntry CDecl Alias "fts3ChecksumEntry" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_int64, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int) As c2fb_uint64
Declare Function fts3ChecksumIndex CDecl Alias "fts3ChecksumIndex" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr) As c2fb_uint64
Declare Function fts3DoIntegrityCheck CDecl Alias "fts3DoIntegrityCheck" (ByVal arg0 As c2fb_source_record_408 Ptr) As c2fb_c_int
Declare Sub sqlite3Fts3FreeDeferredDoclists CDecl Alias "sqlite3Fts3FreeDeferredDoclists" (ByVal arg0 As c2fb_source_record_409 Ptr)
Declare Sub sqlite3Fts3FreeDeferredTokens CDecl Alias "sqlite3Fts3FreeDeferredTokens" (ByVal arg0 As c2fb_source_record_409 Ptr)
Declare Function sqlite3Fts3DeferredTokenList CDecl Alias "sqlite3Fts3DeferredTokenList" (ByVal arg0 As c2fb_source_record_416 Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts3DeferToken CDecl Alias "sqlite3Fts3DeferToken" (ByVal arg0 As c2fb_source_record_409 Ptr, ByVal arg1 As c2fb_source_record_411 Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_external_sqlite3_prepare_v3_ CDecl Alias "sqlite3_prepare_v3" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_uint, ByVal arg4 As SqliteVdbe Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int_ CDecl Alias "sqlite3_column_int" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_text_ CDecl Alias "sqlite3_column_text" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_blob_open_ CDecl Alias "sqlite3_blob_open" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_int64, ByVal arg5 As c2fb_c_int, ByVal arg6 As Any Ptr Ptr) As c2fb_c_int
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
Function sqlite3Fts3PrepareStmt CDecl Alias "sqlite3Fts3PrepareStmt" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As SqliteVdbe Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H20ULL) Or (IIf(((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL)))))), Cast(c2fb_c_int, &H04ULL), Cast(c2fb_c_int, &O0ULL))))) Or (IIf(arg2, Cast(c2fb_c_int, &H01ULL), Cast(c2fb_c_int, &O0ULL)))))
    Return c2fb_external_sqlite3_prepare_v3_(arg0->db, arg1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), local0, arg4, CPtr(Const ZString Ptr Ptr, (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
End Function
' c2fb skipped fts3SqlStmt: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3SqlStmt: assignment parser stopped at byte 7 (const char *azSql[] = {           "DELETE FROM %Q.'%q_content' WHERE rowid = ?",           "SELECT NOT EXISTS(SELECT doc): char *azSql[] = {           "DELETE FROM %Q.'%q_content' WHERE rowid = ?",
' c2fb skipped fts3SelectDocsize: requires unconverted C function fts3SqlStmt
' c2fb skipped sqlite3Fts3SelectDoctotal: requires unconverted C function fts3SqlStmt
' c2fb skipped sqlite3Fts3SelectDocsize: requires unconverted C function fts3SelectDocsize
' c2fb skipped fts3SqlExec: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3Writelock: requires unconverted C function fts3SqlStmt
Private Function getAbsoluteLevel CDecl Alias "getAbsoluteLevel" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_int64
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64

    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, arg1) * Cast(c2fb_int64, arg0->nIndex))) + Cast(c2fb_int64, arg2)))) * Cast(c2fb_int64, Cast(c2fb_c_int, 1024ULL)))))
    local0 = c2fb_temp_0
    Return Cast(c2fb_int64, (local0 + Cast(c2fb_int64, arg3)))
End Function
' c2fb skipped sqlite3Fts3AllSegdirs: requires unconverted C function fts3SqlStmt
Private Function fts3PendingListAppendVarint CDecl Alias "fts3PendingListAppendVarint" (ByVal arg0 As c2fb_source_record_415 Ptr Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_415 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_415 Ptr
    Dim c2fb_temp_1 As c2fb_int64 Ptr
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_int64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim local1 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_source_record_415 Ptr
    Dim c2fb_temp_8 As c2fb_source_record_415 Ptr Ptr
    Dim c2fb_temp_9 As c2fb_source_record_415 Ptr
    Dim c2fb_temp_10 As c2fb_int64 Ptr
    Dim c2fb_temp_11 As c2fb_int64
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As c2fb_int64 Ptr
    Dim c2fb_temp_15 As c2fb_int64
    Dim c2fb_temp_16 As Byte Ptr
    Dim c2fb_temp_17 As Byte
    Dim c2fb_temp_18 As c2fb_source_record_415 Ptr Ptr
    Dim c2fb_temp_19 As c2fb_source_record_415 Ptr

    local0 = (*arg0)
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        c2fb_temp_0 = CPtr(c2fb_source_record_415 Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_415))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 100ULL)))))))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, (local0 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_1 = CPtr(c2fb_int64 Ptr, @(local0->nSpace))
        c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_c_int, 100ULL))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(ZString Ptr Ptr, @(local0->aData))
        c2fb_temp_4 = CPtr(ZString Ptr, CPtr(c2fb_source_record_415 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = CPtr(c2fb_int64 Ptr, @(local0->nData))
        c2fb_temp_6 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_5) = c2fb_temp_6
    Else
        If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local0->nData + Cast(c2fb_int64, Cast(c2fb_c_int, 10ULL)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))) > local0->nSpace)))) Then
            local1 = Cast(c2fb_int64, (local0->nSpace * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))
            c2fb_temp_7 = CPtr(c2fb_source_record_415 Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local0), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_415))) + Cast(c2fb_uint64, local1))))))
            local0 = c2fb_temp_7
            If (-Cast(c2fb_c_int, (local0 = 0))) Then
                sqlite3_free(CPtr(Any Ptr, (*arg0)))
                c2fb_temp_8 = CPtr(c2fb_source_record_415 Ptr Ptr, @((*arg0)))
                c2fb_temp_9 = CPtr(c2fb_source_record_415 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_8) = c2fb_temp_9
                Return Cast(c2fb_c_int, 7ULL)
            End If
            c2fb_temp_10 = CPtr(c2fb_int64 Ptr, @(local0->nSpace))
            c2fb_temp_11 = Cast(c2fb_int64, Cast(c2fb_c_int, local1))
            (*c2fb_temp_10) = c2fb_temp_11
            c2fb_temp_12 = CPtr(ZString Ptr Ptr, @(local0->aData))
            c2fb_temp_13 = CPtr(ZString Ptr, CPtr(c2fb_source_record_415 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_12) = c2fb_temp_13
        End If
    End If
    c2fb_temp_14 = CPtr(c2fb_int64 Ptr, @(local0->nData))
    c2fb_temp_15 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_14) + Cast(c2fb_int64, sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0->aData)[local0->nData]))), arg1)))))
    (*c2fb_temp_14) = c2fb_temp_15
    c2fb_temp_16 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0->aData)[local0->nData]))
    c2fb_temp_17 = Cast(Byte, Cast(c2fb_c_int, 0))
    (*c2fb_temp_16) = c2fb_temp_17
    c2fb_temp_18 = CPtr(c2fb_source_record_415 Ptr Ptr, @((*arg0)))
    c2fb_temp_19 = local0
    (*c2fb_temp_18) = c2fb_temp_19
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3PendingListAppend CDecl Alias "fts3PendingListAppend" (ByVal arg0 As c2fb_source_record_415 Ptr Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_415 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_int64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_int64 Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_int64 Ptr
    Dim c2fb_temp_16 As c2fb_int64
    Dim c2fb_temp_17 As c2fb_int64 Ptr
    Dim c2fb_temp_18 As c2fb_int64
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_int64 Ptr
    Dim c2fb_temp_21 As c2fb_int64
    Dim c2fb_temp_22 As c2fb_c_int Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_source_record_415 Ptr Ptr
    Dim c2fb_temp_25 As c2fb_source_record_415 Ptr

    local0 = (*arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local0 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->iLastDocid <> arg1)))) <> 0))))) Then
        local2 = Cast(c2fb_uint64, (Cast(c2fb_uint64, arg1) - Cast(c2fb_uint64, (IIf(local0, local0->iLastDocid, Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))))
        If local0 Then
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(local0->nData))
            c2fb_temp_1 = (*c2fb_temp_0)
            (*c2fb_temp_0) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_1 + 1)))
        End If
        c2fb_temp_3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_2 = Cast(c2fb_c_int, fts3PendingListAppendVarint(CPtr(c2fb_source_record_415 Ptr Ptr, @(local0)), local2))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((c2fb_temp_3 <> (c2fb_temp_2))))) Then
            Goto c2fb_label_0
        End If
        c2fb_temp_4 = CPtr(c2fb_int64 Ptr, @(local0->iLastCol))
        c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_4) = c2fb_temp_5
        c2fb_temp_6 = CPtr(c2fb_int64 Ptr, @(local0->iLastPos))
        c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_6) = c2fb_temp_7
        c2fb_temp_8 = CPtr(c2fb_int64 Ptr, @(local0->iLastDocid))
        c2fb_temp_9 = Cast(c2fb_int64, arg1)
        (*c2fb_temp_8) = c2fb_temp_9
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->iLastCol <> arg2)))) <> 0))))) Then
        c2fb_temp_11 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_10 = Cast(c2fb_c_int, fts3PendingListAppendVarint(CPtr(c2fb_source_record_415 Ptr Ptr, @(local0)), Cast(c2fb_c_int, 1ULL)))
        local1 = c2fb_temp_10
        c2fb_temp_14 = 1
        If (((-Cast(c2fb_c_int, ((c2fb_temp_11 <> (c2fb_temp_10))))) <> 0) = 0) Then
            c2fb_temp_13 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_12 = Cast(c2fb_c_int, fts3PendingListAppendVarint(CPtr(c2fb_source_record_415 Ptr Ptr, @(local0)), arg2))
            local1 = c2fb_temp_12
            c2fb_temp_14 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_13 <> (c2fb_temp_12))))) <> 0))))
        End If
        If c2fb_temp_14 Then
            Goto c2fb_label_0
        End If
        c2fb_temp_15 = CPtr(c2fb_int64 Ptr, @(local0->iLastCol))
        c2fb_temp_16 = Cast(c2fb_int64, arg2)
        (*c2fb_temp_15) = c2fb_temp_16
        c2fb_temp_17 = CPtr(c2fb_int64 Ptr, @(local0->iLastPos))
        c2fb_temp_18 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_17) = c2fb_temp_18
    End If
    If (-Cast(c2fb_c_int, ((arg2 >= Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        ' C unused-parameter annotation
        c2fb_temp_19 = Cast(c2fb_c_int, fts3PendingListAppendVarint(CPtr(c2fb_source_record_415 Ptr Ptr, @(local0)), Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)) + arg3)) - local0->iLastPos))))
        local1 = c2fb_temp_19
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_20 = CPtr(c2fb_int64 Ptr, @(local0->iLastPos))
            c2fb_temp_21 = Cast(c2fb_int64, arg3)
            (*c2fb_temp_20) = c2fb_temp_21
        End If
    End If
    c2fb_label_0:
    c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_23 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_22) = c2fb_temp_23
    If (-Cast(c2fb_c_int, ((local0 <> (*arg0))))) Then
        c2fb_temp_24 = CPtr(c2fb_source_record_415 Ptr Ptr, @((*arg0)))
        c2fb_temp_25 = local0
        (*c2fb_temp_24) = c2fb_temp_25
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts3PendingListDelete CDecl Alias "fts3PendingListDelete" (ByVal arg0 As c2fb_source_record_415 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    sqlite3_free(CPtr(Any Ptr, arg0))
End Sub
Private Function fts3PendingTermsAddOne CDecl Alias "fts3PendingTermsAddOne" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_405 Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_415 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_source_record_415 Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_source_record_415 Ptr, CPtr(Any Ptr, sqlite3Fts3HashFind(CPtr(Const c2fb_source_record_405 Ptr, arg3), CPtr(Const Any Ptr, arg4), arg5)))
    local0 = c2fb_temp_0
    If local0 Then
        ' C unused-parameter annotation
        c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @(arg0->nPendingData))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_1) - Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (local0->nData + Cast(c2fb_int64, arg5)))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_406))))))))))
        (*c2fb_temp_1) = c2fb_temp_2
    End If
    If fts3PendingListAppend(CPtr(c2fb_source_record_415 Ptr Ptr, @(local0)), arg0->iPrevDocid, arg1, arg2, CPtr(c2fb_c_int Ptr, @(local1))) Then
        If (-Cast(c2fb_c_int, ((local0 = CPtr(Any Ptr, sqlite3Fts3HashInsert(arg3, CPtr(Const Any Ptr, arg4), arg5, CPtr(Any Ptr, local0))))))) Then
            ' C unused-parameter annotation
            sqlite3_free(CPtr(Any Ptr, local0))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local1 = c2fb_temp_3
        End If
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->nPendingData))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_4) + Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (local0->nData + Cast(c2fb_int64, arg5)))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_406))))))))))
        (*c2fb_temp_4) = c2fb_temp_5
    End If
    Return local1
End Function
' c2fb skipped fts3PendingTermsAdd: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3PendingTermsAdd: assignment parser stopped at byte 16 (xNext = pModule->xNext): ->xNext
Private Function fts3PendingTermsDocid CDecl Alias "fts3PendingTermsDocid" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 < arg0->iPrevDocid)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 = arg0->iPrevDocid)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->bPrevDelete = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->iPrevLangid <> arg2)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->nPendingData > arg0->nMaxPendingData)))) <> 0))))) Then
        local0 = sqlite3Fts3PendingTermsFlush(arg0)
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local0
        End If
    End If
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(arg0->iPrevDocid))
    c2fb_temp_1 = Cast(c2fb_int64, arg3)
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg0->iPrevLangid))
    c2fb_temp_3 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->bPrevDelete))
    c2fb_temp_5 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_4) = c2fb_temp_5
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Sub sqlite3Fts3PendingTermsClear CDecl Alias "sqlite3Fts3PendingTermsClear" (ByVal arg0 As c2fb_source_record_408 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_source_record_406 Ptr
    Dim local2 As c2fb_source_record_405 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_406 Ptr
    Dim c2fb_temp_3 As c2fb_source_record_406 Ptr
    Dim local3 As c2fb_source_record_415 Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0->nIndex))))
        ' C automatic storage declaration
        local2 = CPtr(c2fb_source_record_405 Ptr, @(arg0->aIndex[local0].hPending))
        c2fb_temp_2 = (CPtr(c2fb_source_record_406 Ptr, (local2)->first))
        local1 = c2fb_temp_2
        While local1
            local3 = CPtr(c2fb_source_record_415 Ptr, ((local1)->data))
            fts3PendingListDelete(local3)
        c2fb_flow_3:
            c2fb_temp_3 = ((local1)->next)
            local1 = c2fb_temp_3
        Wend
        c2fb_flow_2:
        sqlite3Fts3HashClear(local2)
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->nPendingData))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_4) = c2fb_temp_5
End Sub
' c2fb skipped fts3InsertTerms: requires unconverted C function fts3PendingTermsAdd
' c2fb skipped fts3InsertData: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3DeleteAll: requires unconverted C function fts3SqlExec
Private Function langidFromSelect CDecl Alias "langidFromSelect" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As SqliteVdbe Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0->zLanguageid Then
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_int_(arg1, Cast(c2fb_c_int, (arg0->nColumn + Cast(c2fb_c_int, 1ULL)))))
        local0 = c2fb_temp_0
    End If
    Return local0
End Function
' c2fb skipped fts3DeleteTerms: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3AllocateSegdirIdx: requires unconverted C function fts3SqlStmt
Function sqlite3Fts3ReadBlock CDecl Alias "sqlite3Fts3ReadBlock" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As ZString Ptr Ptr
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    ' C automatic storage declaration
    ' C unused-parameter annotation
    If arg0->pSegments Then
        c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_blob_reopen(arg0->pSegments, arg1))
        local0 = c2fb_temp_0
    Else
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = arg0->zSegmentsTbl)))) Then
            c2fb_temp_1 = CPtr(ZString Ptr Ptr, @(arg0->zSegmentsTbl))
            c2fb_temp_2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s_segments"), arg0->zName))
            (*c2fb_temp_1) = c2fb_temp_2
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = arg0->zSegmentsTbl)))) Then
                Return Cast(c2fb_c_int, 7ULL)
            End If
        End If
        c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3_blob_open_(arg0->db, arg0->zDb, CPtr(Const ZString Ptr, arg0->zSegmentsTbl), StrPtr(!"block"), arg1, Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr Ptr, @(arg0->pSegments))))
        local0 = c2fb_temp_3
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = sqlite3_blob_bytes(arg0->pSegments)
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_5 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_4) = c2fb_temp_5
        If arg2 Then
            local2 = CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, local1) + Cast(c2fb_int64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL)))))))))
            If (-Cast(c2fb_c_int, (local2 = 0))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_6
            Else
                If (-Cast(c2fb_c_int, (((arg4 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 > ((Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * Cast(c2fb_c_int, 1024ULL)))) * Cast(c2fb_c_int, 4ULL))))))))) <> 0))))) Then
                    c2fb_temp_7 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * Cast(c2fb_c_int, 1024ULL)))))
                    local1 = c2fb_temp_7
                    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg4)))
                    c2fb_temp_9 = Cast(c2fb_c_int, local1)
                    (*c2fb_temp_8) = c2fb_temp_9
                End If
                c2fb_temp_10 = Cast(c2fb_c_int, sqlite3_blob_read(arg0->pSegments, CPtr(Any Ptr, local2), local1, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_10
                c2fb_temp_11 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[local1]))), Cast(c2fb_c_int, &O0ULL), (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL))))))
                If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    sqlite3_free(CPtr(Any Ptr, local2))
                    c2fb_temp_12 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local2 = c2fb_temp_12
                End If
            End If
            c2fb_temp_13 = CPtr(ZString Ptr Ptr, @((*arg2)))
            c2fb_temp_14 = local2
            (*c2fb_temp_13) = c2fb_temp_14
        End If
    Else
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_15 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_15
        End If
    End If
    Return local0
End Function
Sub sqlite3Fts3SegmentsClose CDecl Alias "sqlite3Fts3SegmentsClose" (ByVal arg0 As c2fb_source_record_408 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr

    sqlite3_blob_close(arg0->pSegments)
    c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->pSegments))
    c2fb_temp_1 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
End Sub
Private Function fts3SegReaderIncrRead CDecl Alias "fts3SegReaderIncrRead" (ByVal arg0 As c2fb_source_record_417 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Any Ptr Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->nNode - arg0->nPopulate))) < ((Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * Cast(c2fb_c_int, 1024ULL))))))))), (Cast(c2fb_c_int, (arg0->nNode - arg0->nPopulate))), ((Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * Cast(c2fb_c_int, 1024ULL))))))))
    local0 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_blob_read(arg0->pBlob, CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->aNode)[arg0->nPopulate]))), local0, arg0->nPopulate))
    local1 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg0->nPopulate))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_2) + local0)))
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->aNode)[arg0->nPopulate]))), Cast(c2fb_c_int, &O0ULL), (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL))))))
        If (-Cast(c2fb_c_int, ((arg0->nPopulate = arg0->nNode)))) Then
            sqlite3_blob_close(arg0->pBlob)
            c2fb_temp_5 = CPtr(Any Ptr Ptr, @(arg0->pBlob))
            c2fb_temp_6 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_5) = c2fb_temp_6
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(arg0->nPopulate))
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_7) = c2fb_temp_8
        End If
    End If
    Return local1
End Function
Private Function fts3SegReaderRequire CDecl Alias "fts3SegReaderRequire" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, (((arg0->pBlob <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_int64, (Cast(c2fb_int64, (CPtr(Byte Ptr, CPtr(Byte Ptr, arg1)) - CPtr(Byte Ptr, CPtr(Byte Ptr, arg0->aNode)))) + Cast(c2fb_int64, arg2)))) > Cast(c2fb_int64, arg0->nPopulate))))) <> 0)))))
        c2fb_temp_0 = Cast(c2fb_c_int, fts3SegReaderIncrRead(arg0))
        local0 = c2fb_temp_0
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Sub fts3SegReaderSetEof CDecl Alias "fts3SegReaderSetEof" (ByVal arg0 As c2fb_source_record_417 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr

    If (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0)->rootOnly) <> Cast(c2fb_c_int, &O0ULL)))))) = 0))) Then
        sqlite3_free(CPtr(Any Ptr, arg0->aNode))
        sqlite3_blob_close(arg0->pBlob)
        c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->pBlob))
        c2fb_temp_1 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg0->aNode))
    c2fb_temp_3 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
End Sub
Private Function fts3SegReaderNext CDecl Alias "fts3SegReaderNext" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim local4 As c2fb_source_record_406 Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_source_record_415 Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As Byte Ptr
    Dim c2fb_temp_10 As Byte
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As Any Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As ZString Ptr Ptr
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As ZString Ptr Ptr
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As c2fb_source_record_406 Ptr Ptr Ptr
    Dim c2fb_temp_24 As c2fb_source_record_406 Ptr Ptr
    Dim c2fb_temp_25 As c2fb_int64 Ptr
    Dim c2fb_temp_26 As c2fb_int64
    Dim c2fb_temp_27 As c2fb_int64
    Dim c2fb_temp_28 As c2fb_source_record_408 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim c2fb_temp_30 As ZString Ptr Ptr
    Dim c2fb_temp_31 As c2fb_c_int Ptr
    Dim c2fb_temp_32 As c2fb_c_int Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As Any Ptr Ptr
    Dim c2fb_temp_35 As Any Ptr
    Dim c2fb_temp_36 As Any Ptr Ptr
    Dim c2fb_temp_37 As Any Ptr
    Dim c2fb_temp_38 As ZString Ptr
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_c_int Ptr
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As ZString Ptr
    Dim c2fb_temp_44 As c2fb_c_int Ptr
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As ZString Ptr
    Dim local9 As c2fb_int64
    Dim local10 As ZString Ptr
    Dim c2fb_temp_48 As ZString Ptr Ptr
    Dim c2fb_temp_49 As ZString Ptr
    Dim c2fb_temp_50 As c2fb_c_int Ptr
    Dim c2fb_temp_51 As c2fb_c_int
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As Any Ptr
    Dim c2fb_temp_54 As c2fb_c_int Ptr
    Dim c2fb_temp_55 As c2fb_c_int
    Dim c2fb_temp_56 As ZString Ptr
    Dim c2fb_temp_57 As c2fb_c_int Ptr
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As c2fb_c_int
    Dim c2fb_temp_60 As ZString Ptr
    Dim c2fb_temp_61 As ZString Ptr Ptr
    Dim c2fb_temp_62 As ZString Ptr
    Dim c2fb_temp_63 As ZString Ptr Ptr
    Dim c2fb_temp_64 As ZString Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, (arg1->aDoclist = 0))) Then
        c2fb_temp_0 = arg1->aNode
        local1 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aDoclist)[arg1->nDoclist])))
        local1 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local1 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 >= CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aNode)[arg1->nNode])))))) <> 0))))) Then
        If ((-Cast(c2fb_c_int, (((arg1)->ppNextElem <> Cast(c2fb_c_int, &O0ULL)))))) Then
            local4 = (*(arg1->ppNextElem))
            sqlite3_free(CPtr(Any Ptr, arg1->aNode))
            c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg1->aNode))
            c2fb_temp_3 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_2) = c2fb_temp_3
            If local4 Then
                ' C automatic storage declaration
                local6 = CPtr(c2fb_source_record_415 Ptr, ((local4)->data))
                local7 = Cast(c2fb_int64, (local6->nData + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))
                local8 = ((local4)->nKey)
                If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, 1ULL)))) > arg1->nTermAlloc)))) Then
                    sqlite3_free(CPtr(Any Ptr, arg1->zTerm))
                    c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(arg1->zTerm))
                    c2fb_temp_5 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, local8) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))))
                    (*c2fb_temp_4) = c2fb_temp_5
                    If (-Cast(c2fb_c_int, (arg1->zTerm = 0))) Then
                        Return Cast(c2fb_c_int, 7ULL)
                    End If
                    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg1->nTermAlloc))
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, 1ULL)))) * Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_6) = c2fb_temp_7
                End If
                c2fb_temp_8 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg1->zTerm), CPtr(Const Any Ptr, ((local4)->pKey)), local8))
                c2fb_temp_9 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->zTerm)[local8]))
                c2fb_temp_10 = Cast(Byte, Cast(c2fb_c_int, 0))
                (*c2fb_temp_9) = c2fb_temp_10
                c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @(arg1->nTerm))
                c2fb_temp_12 = Cast(c2fb_c_int, local8)
                (*c2fb_temp_11) = c2fb_temp_12
                c2fb_temp_13 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc64(local7)))
                local5 = c2fb_temp_13
                If (-Cast(c2fb_c_int, (local5 = 0))) Then
                    Return Cast(c2fb_c_int, 7ULL)
                End If
                c2fb_temp_14 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local5), CPtr(Const Any Ptr, local6->aData), local7))
                c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @(arg1->nNode))
                c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @(arg1->nDoclist))
                c2fb_temp_16 = Cast(c2fb_c_int, local7)
                (*c2fb_temp_15) = c2fb_temp_16
                c2fb_temp_18 = Cast(c2fb_c_int, c2fb_temp_16)
                (*c2fb_temp_17) = c2fb_temp_18
                c2fb_temp_21 = CPtr(ZString Ptr Ptr, @(arg1->aNode))
                c2fb_temp_19 = CPtr(ZString Ptr Ptr, @(arg1->aDoclist))
                c2fb_temp_20 = local5
                (*c2fb_temp_19) = c2fb_temp_20
                c2fb_temp_22 = c2fb_temp_20
                (*c2fb_temp_21) = c2fb_temp_22
                c2fb_temp_23 = CPtr(c2fb_source_record_406 Ptr Ptr Ptr, @(arg1->ppNextElem))
                c2fb_temp_24 = (*c2fb_temp_23)
                (*c2fb_temp_23) = (c2fb_temp_24 + 1)
                ' C unused-parameter annotation
            End If
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        fts3SegReaderSetEof(arg1)
        If (-Cast(c2fb_c_int, ((arg1->iCurrentBlock >= arg1->iLeafEndBlock)))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        c2fb_temp_28 = arg0
        c2fb_temp_25 = CPtr(c2fb_int64 Ptr, @(arg1->iCurrentBlock))
        c2fb_temp_26 = (*c2fb_temp_25)
        (*c2fb_temp_25) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_26 + 1)))
        c2fb_temp_27 = (*c2fb_temp_25)
        c2fb_temp_29 = c2fb_temp_27
        c2fb_temp_30 = CPtr(ZString Ptr Ptr, @(arg1->aNode))
        c2fb_temp_31 = CPtr(c2fb_c_int Ptr, @(arg1->nNode))
        c2fb_temp_32 = (IIf(arg2, CPtr(c2fb_c_int Ptr, @(arg1->nPopulate)), CPtr(c2fb_c_int Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        c2fb_temp_33 = Cast(c2fb_c_int, sqlite3Fts3ReadBlock(c2fb_temp_28, c2fb_temp_29, c2fb_temp_30, c2fb_temp_31, c2fb_temp_32))
        local0 = c2fb_temp_33
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local0
        End If
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->nPopulate < arg1->nNode)))) <> 0))))) Then
            c2fb_temp_34 = CPtr(Any Ptr Ptr, @(arg1->pBlob))
            c2fb_temp_35 = arg0->pSegments
            (*c2fb_temp_34) = c2fb_temp_35
            c2fb_temp_36 = CPtr(Any Ptr Ptr, @(arg0->pSegments))
            c2fb_temp_37 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_36) = c2fb_temp_37
        End If
        c2fb_temp_38 = arg1->aNode
        local1 = c2fb_temp_38
    End If
    ' C unused-parameter annotation
    c2fb_temp_39 = Cast(c2fb_c_int, fts3SegReaderRequire(arg1, local1, Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL)))))
    local0 = c2fb_temp_39
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local0
    End If
    If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1)))) And Cast(c2fb_c_int, &H80ULL)))) Then
        c2fb_temp_42 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(local2)))
    Else
        c2fb_temp_40 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local2)))))
        c2fb_temp_41 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1))))
        (*c2fb_temp_40) = c2fb_temp_41
        c2fb_temp_42 = (Cast(c2fb_c_int, 1ULL))
    End If
    c2fb_temp_43 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + (c2fb_temp_42)))
    local1 = c2fb_temp_43
    If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1)))) And Cast(c2fb_c_int, &H80ULL)))) Then
        c2fb_temp_46 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(local3)))
    Else
        c2fb_temp_44 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local3)))))
        c2fb_temp_45 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1))))
        (*c2fb_temp_44) = c2fb_temp_45
        c2fb_temp_46 = (Cast(c2fb_c_int, 1ULL))
    End If
    c2fb_temp_47 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + (c2fb_temp_46)))
    local1 = c2fb_temp_47
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 <= Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_int64, ((CPtr(Byte Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aNode)[arg1->nNode]))) - CPtr(Byte Ptr, CPtr(Byte Ptr, local1))))) < Cast(c2fb_int64, local3))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 > arg1->nTerm)))) <> 0))))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (Cast(c2fb_int64, local2) + Cast(c2fb_int64, local3))) > Cast(c2fb_int64, arg1->nTermAlloc))))) Then
        local9 = Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, local2) + Cast(c2fb_int64, local3)))) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))
        local10 = CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg1->zTerm), local9))
        If (-Cast(c2fb_c_int, (local10 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_48 = CPtr(ZString Ptr Ptr, @(arg1->zTerm))
        c2fb_temp_49 = local10
        (*c2fb_temp_48) = c2fb_temp_49
        c2fb_temp_50 = CPtr(c2fb_c_int Ptr, @(arg1->nTermAlloc))
        c2fb_temp_51 = Cast(c2fb_c_int, local9)
        (*c2fb_temp_50) = c2fb_temp_51
    End If
    c2fb_temp_52 = Cast(c2fb_c_int, fts3SegReaderRequire(arg1, local1, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 10ULL)))))
    local0 = c2fb_temp_52
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local0
    End If
    c2fb_temp_53 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->zTerm)[local2]))), CPtr(Const Any Ptr, local1), local3))
    c2fb_temp_54 = CPtr(c2fb_c_int Ptr, @(arg1->nTerm))
    c2fb_temp_55 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + local3)))
    (*c2fb_temp_54) = c2fb_temp_55
    c2fb_temp_56 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + local3))
    local1 = c2fb_temp_56
    If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1)))) And Cast(c2fb_c_int, &H80ULL)))) Then
        c2fb_temp_59 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(arg1->nDoclist)))
    Else
        c2fb_temp_57 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(arg1->nDoclist)))))
        c2fb_temp_58 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local1))))
        (*c2fb_temp_57) = c2fb_temp_58
        c2fb_temp_59 = (Cast(c2fb_c_int, 1ULL))
    End If
    c2fb_temp_60 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + (c2fb_temp_59)))
    local1 = c2fb_temp_60
    c2fb_temp_61 = CPtr(ZString Ptr Ptr, @(arg1->aDoclist))
    c2fb_temp_62 = local1
    (*c2fb_temp_61) = c2fb_temp_62
    c2fb_temp_63 = CPtr(ZString Ptr Ptr, @(arg1->pOffsetList))
    c2fb_temp_64 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_63) = c2fb_temp_64
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_int64, arg1->nDoclist) > Cast(c2fb_int64, (Cast(c2fb_int64, arg1->nNode) - Cast(c2fb_int64, ((CPtr(Byte Ptr, CPtr(Byte Ptr, arg1->aDoclist)) - CPtr(Byte Ptr, CPtr(Byte Ptr, arg1->aNode))))))))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->nPopulate = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(Byte Ptr, arg1->aDoclist)[Cast(c2fb_c_int, (arg1->nDoclist - Cast(c2fb_c_int, 1ULL)))] <> 0)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->nDoclist = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3SegReaderFirstDocid CDecl Alias "fts3SegReaderFirstDocid" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As UByte
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((arg0->bDescIdx <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg1)->ppNextElem <> Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(arg1->iDocid))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg1->nOffsetList))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = c2fb_temp_3
        sqlite3Fts3DoclistPrev(Cast(c2fb_c_int, &O0ULL), arg1->aDoclist, arg1->nDoclist, CPtr(ZString Ptr Ptr, @(arg1->pOffsetList)), CPtr(c2fb_int64 Ptr, @(arg1->iDocid)), CPtr(c2fb_c_int Ptr, @(arg1->nOffsetList)), CPtr(UByte Ptr, @(local1)))
    Else
        c2fb_temp_4 = Cast(c2fb_c_int, fts3SegReaderRequire(arg1, arg1->aDoclist, Cast(c2fb_c_int, 10ULL)))
        local0 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            local2 = sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, arg1->aDoclist), CPtr(c2fb_int64 Ptr, @(arg1->iDocid)))
            c2fb_temp_5 = CPtr(ZString Ptr Ptr, @(arg1->pOffsetList))
            c2fb_temp_6 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aDoclist)[local2])))
            (*c2fb_temp_5) = c2fb_temp_6
        End If
    End If
    Return local0
End Function
Private Function fts3SegReaderNextDocid CDecl Alias "fts3SegReaderNextDocid" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As Byte
    Dim local3 As UByte
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As Byte
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim local5 As c2fb_uint64
    Dim c2fb_temp_20 As ZString Ptr Ptr
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As c2fb_int64 Ptr
    Dim c2fb_temp_23 As c2fb_int64
    Dim c2fb_temp_24 As c2fb_int64 Ptr
    Dim c2fb_temp_25 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = arg1->pOffsetList
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((arg0->bDescIdx <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg1)->ppNextElem <> Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        local3 = Cast(c2fb_c_int, &O0ULL)
        If arg2 Then
            c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg2)))
            c2fb_temp_1 = arg1->pOffsetList
            (*c2fb_temp_0) = c2fb_temp_1
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->nOffsetList - Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_2) = c2fb_temp_3
        End If
        sqlite3Fts3DoclistPrev(Cast(c2fb_c_int, &O0ULL), arg1->aDoclist, arg1->nDoclist, CPtr(ZString Ptr Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(arg1->iDocid)), CPtr(c2fb_c_int Ptr, @(arg1->nOffsetList)), CPtr(UByte Ptr, @(local3)))
        If local3 Then
            c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(arg1->pOffsetList))
            c2fb_temp_5 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_4) = c2fb_temp_5
        Else
            c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(arg1->pOffsetList))
            c2fb_temp_7 = local1
            (*c2fb_temp_6) = c2fb_temp_7
        End If
    Else
        local4 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aDoclist)[arg1->nDoclist])))
        While Cast(c2fb_c_int, 1ULL)
            While Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))) Or Cast(c2fb_c_int, local2)))
                c2fb_temp_8 = local1
                local1 = (c2fb_temp_8 + 1)
                c2fb_temp_9 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, c2fb_temp_8))) And Cast(c2fb_c_int, &H80ULL))))
                local2 = c2fb_temp_9
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->pBlob = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 < CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aNode)[arg1->nPopulate])))))) <> 0))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_10 = Cast(c2fb_c_int, fts3SegReaderIncrRead(arg1))
            local0 = c2fb_temp_10
            If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return local0
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_11 = local1
        local1 = (c2fb_temp_11 + 1)
        If arg2 Then
            c2fb_temp_12 = CPtr(ZString Ptr Ptr, @((*arg2)))
            c2fb_temp_13 = arg1->pOffsetList
            (*c2fb_temp_12) = c2fb_temp_13
            c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (Cast(c2fb_int64, (CPtr(Byte Ptr, CPtr(Byte Ptr, local1)) - CPtr(Byte Ptr, CPtr(Byte Ptr, arg1->pOffsetList)))) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
            (*c2fb_temp_14) = c2fb_temp_15
        End If
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < local4)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local1))) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            c2fb_temp_16 = local1
            local1 = (c2fb_temp_16 + 1)
        c2fb_flow_5:
        Wend
        c2fb_flow_4:
        If (-Cast(c2fb_c_int, ((local1 >= local4)))) Then
            c2fb_temp_17 = CPtr(ZString Ptr Ptr, @(arg1->pOffsetList))
            c2fb_temp_18 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_17) = c2fb_temp_18
        Else
            c2fb_temp_19 = Cast(c2fb_c_int, fts3SegReaderRequire(arg1, local1, Cast(c2fb_c_int, 10ULL)))
            local0 = c2fb_temp_19
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C automatic storage declaration
                c2fb_temp_20 = CPtr(ZString Ptr Ptr, @(arg1->pOffsetList))
                c2fb_temp_21 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local1) + sqlite3Fts3GetVarintU(CPtr(Const ZString Ptr, local1), CPtr(c2fb_uint64 Ptr, @(local5)))))
                (*c2fb_temp_20) = c2fb_temp_21
                If arg0->bDescIdx Then
                    c2fb_temp_22 = CPtr(c2fb_int64 Ptr, @(arg1->iDocid))
                    c2fb_temp_23 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg1->iDocid) - local5)))))
                    (*c2fb_temp_22) = c2fb_temp_23
                Else
                    c2fb_temp_24 = CPtr(c2fb_int64 Ptr, @(arg1->iDocid))
                    c2fb_temp_25 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg1->iDocid) + local5)))))
                    (*c2fb_temp_24) = c2fb_temp_25
                End If
            End If
        End If
    End If
    Return local0
End Function
Function sqlite3Fts3MsrOvfl CDecl Alias "sqlite3Fts3MsrOvfl" (ByVal arg0 As c2fb_source_record_409 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_408 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As c2fb_source_record_417 Ptr
    Dim local6 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_int64
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_408 Ptr, arg0->base.pVtab)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = local0->nPgsz
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < arg1->nSegment)))) <> 0)))))
        local5 = CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment))[local2]
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((local5)->ppNextElem <> Cast(c2fb_c_int, &O0ULL)))))) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local5)->rootOnly) <> Cast(c2fb_c_int, &O0ULL)))))) = 0))) <> 0))))) Then
            ' C automatic storage declaration
            c2fb_temp_2 = Cast(c2fb_int64, local5->iStartBlock)
            local6 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((local6 <= local5->iLeafEndBlock))))
                ' C automatic storage declaration
                c2fb_temp_4 = Cast(c2fb_c_int, sqlite3Fts3ReadBlock(local0, local6, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_c_int Ptr, @(local7)), Cast(c2fb_c_int, &O0ULL)))
                local3 = c2fb_temp_4
                If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_2
                End If
                If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local7 + Cast(c2fb_c_int, 35ULL)))) > local4)))) Then
                    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local7 + Cast(c2fb_c_int, 34ULL)))) \ local4)))))
                    local1 = c2fb_temp_5
                End If
            c2fb_flow_3:
                c2fb_temp_3 = local6
                local6 = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_3 + 1)))
            Wend
            c2fb_flow_2:
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_7 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_6) = c2fb_temp_7
    Return local3
End Function
Sub sqlite3Fts3SegReaderFree CDecl Alias "sqlite3Fts3SegReaderFree" (ByVal arg0 As c2fb_source_record_417 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    If arg0 Then
        sqlite3_free(CPtr(Any Ptr, arg0->zTerm))
        If (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0)->rootOnly) <> Cast(c2fb_c_int, &O0ULL)))))) = 0))) Then
            sqlite3_free(CPtr(Any Ptr, arg0->aNode))
        End If
        sqlite3_blob_close(arg0->pBlob)
    End If
    sqlite3_free(CPtr(Any Ptr, arg0))
End Sub
Function sqlite3Fts3SegReaderNew CDecl Alias "sqlite3Fts3SegReaderNew" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_int64, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_source_record_417 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_417 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As c2fb_int64 Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_int64 Ptr
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_int64 Ptr
    Dim c2fb_temp_12 As c2fb_int64
    Dim c2fb_temp_13 As ZString Ptr Ptr
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As UByte Ptr
    Dim c2fb_temp_16 As UByte
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Any Ptr
    Dim c2fb_temp_20 As Any Ptr
    Dim c2fb_temp_21 As c2fb_int64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_source_record_417 Ptr Ptr
    Dim c2fb_temp_24 As c2fb_source_record_417 Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        If (-Cast(c2fb_c_int, ((arg3 <> Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg6 + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL)))))))
        local1 = c2fb_temp_0
    End If
    c2fb_temp_1 = CPtr(c2fb_source_record_417 Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_417))) + Cast(c2fb_uint64, local1))))))
    local0 = c2fb_temp_1
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_417))))
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(local0->iIdx))
    c2fb_temp_4 = Cast(c2fb_c_int, arg0)
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(UByte Ptr, @(local0->bLookup))
    c2fb_temp_6 = Cast(UByte, (-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, &O0ULL))))))
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(c2fb_int64 Ptr, @(local0->iStartBlock))
    c2fb_temp_8 = Cast(c2fb_int64, arg2)
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(c2fb_int64 Ptr, @(local0->iLeafEndBlock))
    c2fb_temp_10 = Cast(c2fb_int64, arg3)
    (*c2fb_temp_9) = c2fb_temp_10
    c2fb_temp_11 = CPtr(c2fb_int64 Ptr, @(local0->iEndBlock))
    c2fb_temp_12 = Cast(c2fb_int64, arg4)
    (*c2fb_temp_11) = c2fb_temp_12
    If local1 Then
        c2fb_temp_13 = CPtr(ZString Ptr Ptr, @(local0->aNode))
        c2fb_temp_14 = CPtr(ZString Ptr, CPtr(c2fb_source_record_417 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
        (*c2fb_temp_13) = c2fb_temp_14
        c2fb_temp_15 = CPtr(UByte Ptr, @(local0->rootOnly))
        c2fb_temp_16 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_15) = c2fb_temp_16
        c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @(local0->nNode))
        c2fb_temp_18 = Cast(c2fb_c_int, arg6)
        (*c2fb_temp_17) = c2fb_temp_18
        If arg6 Then
            c2fb_temp_19 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0->aNode), CPtr(Const Any Ptr, arg5), arg6))
        End If
        c2fb_temp_20 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0->aNode)[arg6]))), Cast(c2fb_c_int, &O0ULL), (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL))))))
    Else
        c2fb_temp_21 = CPtr(c2fb_int64 Ptr, @(local0->iCurrentBlock))
        c2fb_temp_22 = Cast(c2fb_int64, Cast(c2fb_int64, (arg2 - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))
        (*c2fb_temp_21) = c2fb_temp_22
    End If
    c2fb_temp_23 = CPtr(c2fb_source_record_417 Ptr Ptr, @((*arg7)))
    c2fb_temp_24 = local0
    (*c2fb_temp_23) = c2fb_temp_24
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3CompareElemByTerm CDecl Alias "fts3CompareElemByTerm" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = (((*CPtr(c2fb_source_record_406 Ptr Ptr, arg0)))->pKey)
    local1 = (((*CPtr(c2fb_source_record_406 Ptr Ptr, arg1)))->pKey)
    local2 = (((*CPtr(c2fb_source_record_406 Ptr Ptr, arg0)))->nKey)
    local3 = (((*CPtr(c2fb_source_record_406 Ptr Ptr, arg1)))->nKey)
    local4 = (IIf((-Cast(c2fb_c_int, ((local2 < local3)))), local2, local3))
    local5 = c2fb_crt_memcmp(CPtr(Const Any Ptr, local0), CPtr(Const Any Ptr, local1), local4)
    If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 - local3)))
        local5 = c2fb_temp_0
    End If
    Return local5
End Function
Function sqlite3Fts3SegReaderPending CDecl Alias "sqlite3Fts3SegReaderPending" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_source_record_417 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_417 Ptr
    Dim local1 As c2fb_source_record_406 Ptr
    Dim local2 As c2fb_source_record_406 Ptr Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_source_record_405 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_405 Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_source_record_406 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_406 Ptr
    Dim local7 As ZString Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_source_record_406 Ptr Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_source_record_406 Ptr Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_source_record_406 Ptr Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_source_record_406 Ptr Ptr
    Dim c2fb_temp_10 As c2fb_source_record_406 Ptr
    Dim c2fb_temp_11 As c2fb_source_record_406 Ptr
    Dim c2fb_temp_12 As c2fb_source_record_406 Ptr Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local10 As c2fb_int64
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Any Ptr
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_source_record_406 Ptr Ptr Ptr
    Dim c2fb_temp_21 As c2fb_source_record_406 Ptr Ptr
    Dim c2fb_temp_22 As Any Ptr
    Dim c2fb_temp_23 As c2fb_source_record_417 Ptr Ptr
    Dim c2fb_temp_24 As c2fb_source_record_417 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_405 Ptr, @(arg0->aIndex[arg1].hPending))
    local5 = c2fb_temp_0
    If arg4 Then
        local6 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_1 = (CPtr(c2fb_source_record_406 Ptr, (local5)->first))
        local1 = c2fb_temp_1
        While local1
            local7 = CPtr(ZString Ptr, ((local1)->pKey))
            local8 = ((local1)->nKey)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 >= arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, local7), CPtr(Const Any Ptr, arg2), arg3))))) <> 0)))))) <> 0))))) Then
                If (-Cast(c2fb_c_int, ((local3 = local6)))) Then
                    ' C automatic storage declaration
                    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 16ULL))))
                    local6 = c2fb_temp_3
                    c2fb_temp_4 = CPtr(c2fb_source_record_406 Ptr Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local2), Cast(c2fb_uint64, (Cast(c2fb_uint64, local6) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_406 Ptr))))))))
                    local9 = c2fb_temp_4
                    If (-Cast(c2fb_c_int, (local9 = 0))) Then
                        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                        local4 = c2fb_temp_5
                        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        local3 = c2fb_temp_6
                        Goto c2fb_flow_0
                    End If
                    c2fb_temp_7 = local9
                    local2 = c2fb_temp_7
                End If
                c2fb_temp_8 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
                c2fb_temp_9 = CPtr(c2fb_source_record_406 Ptr Ptr, @(local2[c2fb_temp_8]))
                c2fb_temp_10 = local1
                (*c2fb_temp_9) = c2fb_temp_10
            End If
        c2fb_flow_1:
            c2fb_temp_2 = ((local1)->next)
            local1 = c2fb_temp_2
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, 1ULL))))) Then
            qsort(CPtr(Any Ptr, local2), local3, Cast(c2fb_size_t, SizeOf(c2fb_source_record_406 Ptr)), ProcPtr(fts3CompareElemByTerm))
        End If
    Else
        c2fb_temp_11 = CPtr(c2fb_source_record_406 Ptr, sqlite3Fts3HashFindElem(CPtr(Const c2fb_source_record_405 Ptr, local5), CPtr(Const Any Ptr, arg2), arg3))
        local1 = c2fb_temp_11
        If local1 Then
            c2fb_temp_12 = CPtr(c2fb_source_record_406 Ptr Ptr, @(local1))
            local2 = c2fb_temp_12
            c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local3 = c2fb_temp_13
        End If
    End If
    If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_temp_14 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_417))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_406 Ptr))))))))
        local10 = c2fb_temp_14
        c2fb_temp_15 = CPtr(c2fb_source_record_417 Ptr, CPtr(Any Ptr, sqlite3_malloc64(local10)))
        local0 = c2fb_temp_15
        If (-Cast(c2fb_c_int, (local0 = 0))) Then
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local4 = c2fb_temp_16
        Else
            c2fb_temp_17 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), local10))
            c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @(local0->iIdx))
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H7FFFFFFFULL))
            (*c2fb_temp_18) = c2fb_temp_19
            c2fb_temp_20 = CPtr(c2fb_source_record_406 Ptr Ptr Ptr, @(local0->ppNextElem))
            c2fb_temp_21 = CPtr(c2fb_source_record_406 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_20) = c2fb_temp_21
            c2fb_temp_22 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0->ppNextElem), CPtr(Const Any Ptr, local2), Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_406 Ptr)))))))
        End If
    End If
    If arg4 Then
        sqlite3_free(CPtr(Any Ptr, local2))
    End If
    c2fb_temp_23 = CPtr(c2fb_source_record_417 Ptr Ptr, @((*arg5)))
    c2fb_temp_24 = local0
    (*c2fb_temp_23) = c2fb_temp_24
    Return local4
End Function
Private Function fts3SegReaderCmp CDecl Alias "fts3SegReaderCmp" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, (((arg0->aNode <> 0) AndAlso (arg1->aNode <> 0))))) Then
        local1 = Cast(c2fb_c_int, (arg0->nTerm - arg1->nTerm))
        If (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, c2fb_crt_memcmp(CPtr(Const Any Ptr, arg0->zTerm), CPtr(Const Any Ptr, arg1->zTerm), arg0->nTerm))
            local0 = c2fb_temp_0
        Else
            c2fb_temp_1 = Cast(c2fb_c_int, c2fb_crt_memcmp(CPtr(Const Any Ptr, arg0->zTerm), CPtr(Const Any Ptr, arg1->zTerm), arg1->nTerm))
            local0 = c2fb_temp_1
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, local1)
            local0 = c2fb_temp_2
        End If
    Else
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->aNode = Cast(c2fb_c_int, &O0ULL)))))) - ((-Cast(c2fb_c_int, ((arg1->aNode = Cast(c2fb_c_int, &O0ULL)))))))))
        local0 = c2fb_temp_3
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->iIdx - arg0->iIdx)))
        local0 = c2fb_temp_4
    End If
    ' C unused-parameter annotation
    Return local0
End Function
Private Function fts3SegReaderDoclistCmp CDecl Alias "fts3SegReaderDoclistCmp" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->pOffsetList = Cast(c2fb_c_int, &O0ULL)))))) - ((-Cast(c2fb_c_int, ((arg1->pOffsetList = Cast(c2fb_c_int, &O0ULL))))))))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg0->iDocid = arg1->iDocid)))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->iIdx - arg0->iIdx)))
            local0 = c2fb_temp_0
        Else
            c2fb_temp_1 = Cast(c2fb_c_int, IIf(((-Cast(c2fb_c_int, ((arg0->iDocid > arg1->iDocid))))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
            local0 = c2fb_temp_1
        End If
    End If
    ' C unused-parameter annotation
    Return local0
End Function
Private Function fts3SegReaderDoclistCmpRev CDecl Alias "fts3SegReaderDoclistCmpRev" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As c2fb_source_record_417 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->pOffsetList = Cast(c2fb_c_int, &O0ULL)))))) - ((-Cast(c2fb_c_int, ((arg1->pOffsetList = Cast(c2fb_c_int, &O0ULL))))))))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg0->iDocid = arg1->iDocid)))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->iIdx - arg0->iIdx)))
            local0 = c2fb_temp_0
        Else
            c2fb_temp_1 = Cast(c2fb_c_int, IIf(((-Cast(c2fb_c_int, ((arg0->iDocid < arg1->iDocid))))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
            local0 = c2fb_temp_1
        End If
    End If
    ' C unused-parameter annotation
    Return local0
End Function
Private Function fts3SegReaderTermCmp CDecl Alias "fts3SegReaderTermCmp" (ByVal arg0 As c2fb_source_record_417 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0->aNode Then
        If (-Cast(c2fb_c_int, ((arg0->nTerm > arg2)))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, c2fb_crt_memcmp(CPtr(Const Any Ptr, arg0->zTerm), CPtr(Const Any Ptr, arg1), arg2))
            local0 = c2fb_temp_0
        Else
            c2fb_temp_1 = Cast(c2fb_c_int, c2fb_crt_memcmp(CPtr(Const Any Ptr, arg0->zTerm), CPtr(Const Any Ptr, arg1), arg0->nTerm))
            local0 = c2fb_temp_1
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg0->nTerm - arg2)))
            local0 = c2fb_temp_2
        End If
    End If
    Return local0
End Function
Private Sub fts3SegReaderSort CDecl Alias "fts3SegReaderSort" (ByVal arg0 As c2fb_source_record_417 Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_callback_217)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local2 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_5 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_6 As c2fb_source_record_417 Ptr Ptr
    Dim c2fb_temp_7 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_8 As c2fb_source_record_417 Ptr Ptr
    Dim c2fb_temp_9 As c2fb_source_record_417 Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg2 = arg1)))) Then
        c2fb_temp_0 = arg2
        arg2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 - 1)))
    End If
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 1ULL))))
    local0 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL)))))
        ' C automatic storage declaration
        c2fb_temp_3 = Cast(c2fb_c_int, local0)
        local1 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local1 < (Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL))))))))
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((arg3(arg0[local1], arg0[Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))]) < Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_2
            End If
            c2fb_temp_5 = arg0[Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))]
            local2 = c2fb_temp_5
            c2fb_temp_6 = CPtr(c2fb_source_record_417 Ptr Ptr, @(arg0[Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))]))
            c2fb_temp_7 = arg0[local1]
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(c2fb_source_record_417 Ptr Ptr, @(arg0[local1]))
            c2fb_temp_9 = local2
            (*c2fb_temp_8) = c2fb_temp_9
        c2fb_flow_3:
            c2fb_temp_4 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 - 1)))
    Wend
    c2fb_flow_0:
End Sub
' c2fb skipped fts3WriteSegment: requires unconverted C function fts3SqlStmt
' c2fb skipped sqlite3Fts3MaxLevel: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3WriteSegdir: requires unconverted C function fts3SqlStmt
Private Function fts3PrefixCompress CDecl Alias "fts3PrefixCompress" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local0]) = Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[local0]))))) <> 0)))))
        ' empty C statement
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    ' C unused-parameter annotation
    Return local0
End Function
Private Function fts3NodeAddTerm CDecl Alias "fts3NodeAddTerm" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_419 Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_419 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_source_record_419 Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local7 As ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As ZString Ptr Ptr
    Dim c2fb_temp_15 As ZString Ptr
    Dim c2fb_temp_16 As ZString Ptr Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As Any Ptr
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As ZString Ptr Ptr
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As c2fb_c_int Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_source_record_419 Ptr
    Dim c2fb_temp_26 As Any Ptr
    Dim c2fb_temp_27 As c2fb_c_int Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As ZString Ptr Ptr
    Dim c2fb_temp_30 As ZString Ptr
    Dim local8 As c2fb_source_record_419 Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_source_record_419 Ptr Ptr
    Dim c2fb_temp_33 As c2fb_source_record_419 Ptr
    Dim c2fb_temp_34 As c2fb_source_record_419 Ptr Ptr
    Dim c2fb_temp_35 As c2fb_source_record_419 Ptr
    Dim c2fb_temp_36 As c2fb_source_record_419 Ptr Ptr
    Dim c2fb_temp_37 As c2fb_source_record_419 Ptr
    Dim c2fb_temp_38 As c2fb_source_record_419 Ptr Ptr
    Dim c2fb_temp_39 As c2fb_source_record_419 Ptr
    Dim c2fb_temp_40 As ZString Ptr Ptr
    Dim c2fb_temp_41 As ZString Ptr
    Dim c2fb_temp_42 As c2fb_c_int Ptr
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As ZString Ptr Ptr
    Dim c2fb_temp_45 As ZString Ptr
    Dim c2fb_temp_46 As c2fb_source_record_419 Ptr Ptr
    Dim c2fb_temp_47 As c2fb_source_record_419 Ptr
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_source_record_419 Ptr Ptr
    Dim c2fb_temp_50 As c2fb_source_record_419 Ptr

    local0 = (*arg1)
    ' C automatic storage declaration
    ' C automatic storage declaration
    If local0 Then
        local3 = local0->nData
        local4 = local3
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, fts3PrefixCompress(CPtr(Const ZString Ptr, local0->zTerm), local0->nTerm, arg3, arg4))
        local5 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg4 - local5)))
        local6 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local6 <= Cast(c2fb_c_int, &O0ULL))))) Then
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, (Cast(c2fb_c_int, (sqlite3Fts3VarintLen(local5) + sqlite3Fts3VarintLen(local6))) + local6)))))
        local4 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 <= arg0->nNodeSize)))) <> 0) OrElse ((-Cast(c2fb_c_int, (local0->zTerm = 0))) <> 0))))) Then
            If (-Cast(c2fb_c_int, ((local4 > arg0->nNodeSize)))) Then
                ' C unused-parameter annotation
                c2fb_temp_3 = CPtr(ZString Ptr Ptr, @(local0->aData))
                c2fb_temp_4 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc64(local4)))
                (*c2fb_temp_3) = c2fb_temp_4
                If (-Cast(c2fb_c_int, (local0->aData = 0))) Then
                    Return Cast(c2fb_c_int, 7ULL)
                End If
            End If
            If local0->zTerm Then
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0->aData)[local3]))), local5))))
                local3 = c2fb_temp_5
            End If
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0->aData)[local3]))), local6))))
            local3 = c2fb_temp_6
            c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0->aData)[local3]))), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg3)[local5]))), local6))
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(local0->nData))
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + local6)))
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(local0->nEntry))
            c2fb_temp_11 = (*c2fb_temp_10)
            (*c2fb_temp_10) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
            If arg2 Then
                If (-Cast(c2fb_c_int, ((local0->nMalloc < arg4)))) Then
                    local7 = CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local0->zMalloc), Cast(c2fb_int64, (Cast(c2fb_int64, arg4) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))))
                    If (-Cast(c2fb_c_int, (local7 = 0))) Then
                        Return Cast(c2fb_c_int, 7ULL)
                    End If
                    c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @(local0->nMalloc))
                    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg4 * Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_12) = c2fb_temp_13
                    c2fb_temp_14 = CPtr(ZString Ptr Ptr, @(local0->zMalloc))
                    c2fb_temp_15 = local7
                    (*c2fb_temp_14) = c2fb_temp_15
                End If
                c2fb_temp_16 = CPtr(ZString Ptr Ptr, @(local0->zTerm))
                c2fb_temp_17 = local0->zMalloc
                (*c2fb_temp_16) = c2fb_temp_17
                c2fb_temp_18 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0->zTerm), CPtr(Const Any Ptr, arg3), arg4))
                c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @(local0->nTerm))
                c2fb_temp_20 = Cast(c2fb_c_int, arg4)
                (*c2fb_temp_19) = c2fb_temp_20
            Else
                c2fb_temp_21 = CPtr(ZString Ptr Ptr, @(local0->zTerm))
                c2fb_temp_22 = CPtr(ZString Ptr, arg3)
                (*c2fb_temp_21) = c2fb_temp_22
                c2fb_temp_23 = CPtr(c2fb_c_int Ptr, @(local0->nTerm))
                c2fb_temp_24 = Cast(c2fb_c_int, arg4)
                (*c2fb_temp_23) = c2fb_temp_24
            End If
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    End If
    c2fb_temp_25 = CPtr(c2fb_source_record_419 Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_419))) + Cast(c2fb_uint64, arg0->nNodeSize))))))
    local2 = c2fb_temp_25
    If (-Cast(c2fb_c_int, (local2 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_26 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_419))))
    c2fb_temp_27 = CPtr(c2fb_c_int Ptr, @(local2->nData))
    c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + Cast(c2fb_c_int, 10ULL))))
    (*c2fb_temp_27) = c2fb_temp_28
    c2fb_temp_29 = CPtr(ZString Ptr Ptr, @(local2->aData))
    c2fb_temp_30 = CPtr(ZString Ptr, CPtr(c2fb_source_record_419 Ptr, @(local2[Cast(c2fb_c_int, 1ULL)])))
    (*c2fb_temp_29) = c2fb_temp_30
    If local0 Then
        local8 = local0->pParent
        c2fb_temp_31 = Cast(c2fb_c_int, fts3NodeAddTerm(arg0, CPtr(c2fb_source_record_419 Ptr Ptr, @(local8)), arg2, arg3, arg4))
        local1 = c2fb_temp_31
        If (-Cast(c2fb_c_int, ((local0->pParent = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_32 = CPtr(c2fb_source_record_419 Ptr Ptr, @(local0->pParent))
            c2fb_temp_33 = local8
            (*c2fb_temp_32) = c2fb_temp_33
        End If
        c2fb_temp_34 = CPtr(c2fb_source_record_419 Ptr Ptr, @(local0->pRight))
        c2fb_temp_35 = local2
        (*c2fb_temp_34) = c2fb_temp_35
        c2fb_temp_36 = CPtr(c2fb_source_record_419 Ptr Ptr, @(local2->pLeftmost))
        c2fb_temp_37 = local0->pLeftmost
        (*c2fb_temp_36) = c2fb_temp_37
        c2fb_temp_38 = CPtr(c2fb_source_record_419 Ptr Ptr, @(local2->pParent))
        c2fb_temp_39 = local8
        (*c2fb_temp_38) = c2fb_temp_39
        c2fb_temp_40 = CPtr(ZString Ptr Ptr, @(local2->zMalloc))
        c2fb_temp_41 = local0->zMalloc
        (*c2fb_temp_40) = c2fb_temp_41
        c2fb_temp_42 = CPtr(c2fb_c_int Ptr, @(local2->nMalloc))
        c2fb_temp_43 = Cast(c2fb_c_int, local0->nMalloc)
        (*c2fb_temp_42) = c2fb_temp_43
        c2fb_temp_44 = CPtr(ZString Ptr Ptr, @(local0->zMalloc))
        c2fb_temp_45 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_44) = c2fb_temp_45
    Else
        c2fb_temp_46 = CPtr(c2fb_source_record_419 Ptr Ptr, @(local2->pLeftmost))
        c2fb_temp_47 = local2
        (*c2fb_temp_46) = c2fb_temp_47
        c2fb_temp_48 = Cast(c2fb_c_int, fts3NodeAddTerm(arg0, CPtr(c2fb_source_record_419 Ptr Ptr, @(local2)), arg2, arg3, arg4))
        local1 = c2fb_temp_48
    End If
    c2fb_temp_49 = CPtr(c2fb_source_record_419 Ptr Ptr, @((*arg1)))
    c2fb_temp_50 = local2
    (*c2fb_temp_49) = c2fb_temp_50
    Return local1
End Function
Private Function fts3TreeFinishNode CDecl Alias "fts3TreeFinishNode" (ByVal arg0 As c2fb_source_record_419 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Byte Ptr
    Dim c2fb_temp_2 As Byte

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) - sqlite3Fts3VarintLen(arg2))))
    local0 = c2fb_temp_0
    c2fb_temp_1 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->aData)[local0]))
    c2fb_temp_2 = Cast(Byte, Cast(Byte, arg1))
    (*c2fb_temp_1) = c2fb_temp_2
    sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->aData)[Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))]))), arg2)
    Return local0
End Function
' c2fb skipped fts3NodeWrite: requires unconverted C function fts3WriteSegment
Private Sub fts3NodeFree CDecl Alias "fts3NodeFree" (ByVal arg0 As c2fb_source_record_419 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_419 Ptr
    Dim local1 As c2fb_source_record_419 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_419 Ptr

    If arg0 Then
        local0 = arg0->pLeftmost
        fts3NodeFree(local0->pParent)
        While local0
            local1 = local0->pRight
            If (-Cast(c2fb_c_int, ((local0->aData <> CPtr(ZString Ptr, CPtr(c2fb_source_record_419 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)]))))))) Then
                sqlite3_free(CPtr(Any Ptr, local0->aData))
            End If
            ' C unused-parameter annotation
            sqlite3_free(CPtr(Any Ptr, local0->zMalloc))
            sqlite3_free(CPtr(Any Ptr, local0))
            c2fb_temp_0 = local1
            local0 = c2fb_temp_0
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
End Sub
' c2fb skipped fts3SegWriterAdd: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3SegWriterFlush: requires unconverted C function fts3WriteSegment
Private Sub fts3SegWriterFree CDecl Alias "fts3SegWriterFree" (ByVal arg0 As c2fb_source_record_418 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    If arg0 Then
        sqlite3_free(CPtr(Any Ptr, arg0->aData))
        sqlite3_free(CPtr(Any Ptr, arg0->zMalloc))
        fts3NodeFree(CPtr(c2fb_source_record_419 Ptr, arg0->pTree))
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
' c2fb skipped fts3IsEmpty: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3SegmentMaxLevel: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3SegmentIsMaxLevel: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3DeleteSegment: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3DeleteSegdir: requires unconverted C function fts3DeleteSegment
Private Sub fts3ColumnFilter CDecl Alias "fts3ColumnFilter" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As ZString Ptr
    Dim local5 As Byte
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As ZString Ptr Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int

    local0 = (*arg2)
    local1 = (*arg3)
    local2 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[local1])))
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = local0
    ' C unused-parameter annotation
    While Cast(c2fb_c_int, 1ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < local2)))) <> 0) AndAlso (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, local5) Or Cast(c2fb_c_int, (*CPtr(Byte Ptr, local4)))))) And Cast(c2fb_c_int, &HFEULL))) <> 0)))))
            c2fb_temp_0 = local4
            local4 = (c2fb_temp_0 + 1)
            c2fb_temp_1 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, c2fb_temp_0))) And Cast(c2fb_c_int, &H80ULL))))
            local5 = c2fb_temp_1
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((arg0 = local3)))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local4)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local0))))))
            local1 = c2fb_temp_2
            Goto c2fb_flow_0
        End If
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local4)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local0))))))))
        local1 = c2fb_temp_3
        c2fb_temp_4 = local4
        local0 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local1 <= Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_5 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[Cast(c2fb_c_int, 1ULL)])))
        local4 = c2fb_temp_5
        If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local4)))) And Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_8 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local4), CPtr(c2fb_c_int Ptr, @(local3)))
        Else
            c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local3)))))
            c2fb_temp_7 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local4))))
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = (Cast(c2fb_c_int, 1ULL))
        End If
        c2fb_temp_9 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local4) + (c2fb_temp_8)))
        local4 = c2fb_temp_9
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_int64, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local2)) - CPtr(Byte Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[local1])))))) > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[local1]))), Cast(c2fb_c_int, &O0ULL), (CPtr(Byte Ptr, CPtr(Byte Ptr, local2)) - CPtr(Byte Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[local1]))))))
    End If
    c2fb_temp_11 = CPtr(ZString Ptr Ptr, @((*arg2)))
    c2fb_temp_12 = local0
    (*c2fb_temp_11) = c2fb_temp_12
    c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_14 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_13) = c2fb_temp_14
End Sub
Private Function fts3MsrBufferData CDecl Alias "fts3MsrBufferData" (ByVal arg0 As c2fb_source_record_414 Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_int64 Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As Any Ptr

    If (-Cast(c2fb_c_int, (((Cast(c2fb_int64, (arg2 + Cast(c2fb_int64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL)))))))) > arg0->nBuffer)))) Then
        ' C automatic storage declaration
        local1 = Cast(c2fb_int64, (Cast(c2fb_int64, (arg2 * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))) + Cast(c2fb_int64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL)))))))
        c2fb_temp_0 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->aBuffer), local1)))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, (local0 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @(arg0->aBuffer))
        c2fb_temp_2 = local0
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_int64 Ptr, @(arg0->nBuffer))
        c2fb_temp_4 = Cast(c2fb_int64, local1)
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    ' C unused-parameter annotation
    c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg0->aBuffer), CPtr(Const Any Ptr, arg1), arg2))
    c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->aBuffer)[arg2]))), Cast(c2fb_c_int, &O0ULL), (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL))))))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts3MsrIncrNext CDecl Alias "sqlite3Fts3MsrIncrNext" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_417 Ptr Ptr
    Dim local2 As c2fb_callback_217
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim local3 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As ZString Ptr Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_int64 Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int

    local0 = arg1->nAdvance
    local1 = CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment)
    local2 = (IIf(arg0->bDescIdx, CPtr(Any Ptr, ProcPtr(fts3SegReaderDoclistCmpRev)), CPtr(Any Ptr, ProcPtr(fts3SegReaderDoclistCmp))))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg3)))
        c2fb_temp_1 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = c2fb_temp_1
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    While Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment))[Cast(c2fb_c_int, &O0ULL)]
        local3 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local3->pOffsetList = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = CPtr(ZString Ptr Ptr, @((*arg3)))
            c2fb_temp_4 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_3) = c2fb_temp_4
            Goto c2fb_flow_0
        Else
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            local8 = local1[Cast(c2fb_c_int, &O0ULL)]->iDocid
            c2fb_temp_5 = Cast(c2fb_c_int, fts3SegReaderNextDocid(arg0, local1[Cast(c2fb_c_int, &O0ULL)], CPtr(ZString Ptr Ptr, @(local5)), CPtr(c2fb_c_int Ptr, @(local6))))
            local4 = c2fb_temp_5
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local7 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 < local0)))) <> 0) AndAlso (local1[local7]->pOffsetList <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1[local7]->iDocid = local8)))) <> 0)))))
                c2fb_temp_7 = Cast(c2fb_c_int, fts3SegReaderNextDocid(arg0, local1[local7], Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                local4 = c2fb_temp_7
                c2fb_temp_8 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return local4
            End If
            fts3SegReaderSort(CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment), local0, local7, local2)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((local1[Cast(c2fb_c_int, &O0ULL)])->ppNextElem <> Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
                c2fb_temp_9 = Cast(c2fb_c_int, fts3MsrBufferData(arg1, local5, Cast(c2fb_int64, (Cast(c2fb_int64, local6) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))
                local4 = c2fb_temp_9
                If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Return local4
                End If
                ' C unused-parameter annotation
                c2fb_temp_10 = arg1->aBuffer
                local5 = c2fb_temp_10
            End If
            If (-Cast(c2fb_c_int, ((arg1->iColFilter >= Cast(c2fb_c_int, &O0ULL))))) Then
                fts3ColumnFilter(arg1->iColFilter, Cast(c2fb_c_int, 1ULL), CPtr(ZString Ptr Ptr, @(local5)), CPtr(c2fb_c_int Ptr, @(local6)))
            End If
            If (-Cast(c2fb_c_int, ((local6 > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_11 = CPtr(ZString Ptr Ptr, @((*arg3)))
                c2fb_temp_12 = local5
                (*c2fb_temp_11) = c2fb_temp_12
                c2fb_temp_13 = CPtr(c2fb_int64 Ptr, @((*arg2)))
                c2fb_temp_14 = Cast(c2fb_int64, local8)
                (*c2fb_temp_13) = c2fb_temp_14
                c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg4)))
                c2fb_temp_16 = Cast(c2fb_c_int, local6)
                (*c2fb_temp_15) = c2fb_temp_16
                Goto c2fb_flow_0
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3SegReaderStart CDecl Alias "fts3SegReaderStart" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_source_record_417 Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = arg1->nSegment
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->bRestart = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < arg1->nSegment)))) <> 0)))))
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment))[local0]
        Do
            local4 = fts3SegReaderNext(arg0, local3, Cast(c2fb_c_int, &O0ULL))
            If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return local4
            End If
        c2fb_flow_3:
            c2fb_temp_3 = 0
            If (arg2 <> 0) Then
                c2fb_temp_2 = Cast(c2fb_c_int, fts3SegReaderTermCmp(local3, arg2, arg3))
                local2 = c2fb_temp_2
                c2fb_temp_3 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((c2fb_temp_2) < Cast(c2fb_c_int, &O0ULL))))) <> 0))))
            End If
        Loop While c2fb_temp_3
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, (((local3->bLookup <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            fts3SegReaderSetEof(local3)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    fts3SegReaderSort(CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment), local1, local1, ProcPtr(fts3SegReaderCmp))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts3SegReaderStart CDecl Alias "sqlite3Fts3SegReaderStart" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As c2fb_source_record_413 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim c2fb_temp_0 As c2fb_source_record_413 Ptr Ptr
    Dim c2fb_temp_1 As c2fb_source_record_413 Ptr

    c2fb_temp_0 = CPtr(c2fb_source_record_413 Ptr Ptr, @(arg1->pFilter))
    c2fb_temp_1 = arg2
    (*c2fb_temp_0) = c2fb_temp_1
    Return fts3SegReaderStart(arg0, arg1, arg2->zTerm, arg2->nTerm)
End Function
Function sqlite3Fts3MsrIncrStart CDecl Alias "sqlite3Fts3MsrIncrStart" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_callback_217
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local4 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = arg1->nSegment
    local3 = (IIf(arg0->bDescIdx, CPtr(Any Ptr, ProcPtr(fts3SegReaderDoclistCmpRev)), CPtr(Any Ptr, ProcPtr(fts3SegReaderDoclistCmp))))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, fts3SegReaderStart(arg0, arg1, arg3, arg4))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local1
    End If
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local0 < local2))))
        local4 = CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment))[local0]
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local4->aNode = 0))) <> 0) OrElse (fts3SegReaderTermCmp(local4, arg3, arg4) <> 0))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg1->nAdvance))
    c2fb_temp_4 = Cast(c2fb_c_int, local0)
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_5
    While (-Cast(c2fb_c_int, ((local0 < arg1->nAdvance))))
        c2fb_temp_7 = Cast(c2fb_c_int, fts3SegReaderFirstDocid(arg0, CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment))[local0]))
        local1 = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local1
        End If
    c2fb_flow_3:
        c2fb_temp_6 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
    Wend
    c2fb_flow_2:
    fts3SegReaderSort(CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment), local0, local0, local3)
    ' C unused-parameter annotation
    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(arg1->iColFilter))
    c2fb_temp_9 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_8) = c2fb_temp_9
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts3MsrIncrRestart CDecl Alias "sqlite3Fts3MsrIncrRestart" (ByVal arg0 As c2fb_source_record_414 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_int64 Ptr
    Dim c2fb_temp_11 As c2fb_int64

    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->nAdvance))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg0->bRestart))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local0 < arg0->nSegment))))
        c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg0->apSegment))[local0]->pOffsetList))
        c2fb_temp_7 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_6) = c2fb_temp_7
        c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg0->apSegment))[local0]->nOffsetList))
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_8) = c2fb_temp_9
        c2fb_temp_10 = CPtr(c2fb_int64 Ptr, @(CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg0->apSegment))[local0]->iDocid))
        c2fb_temp_11 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_10) = c2fb_temp_11
    c2fb_flow_1:
        c2fb_temp_5 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3GrowSegReaderBuffer CDecl Alias "fts3GrowSegReaderBuffer" (ByVal arg0 As c2fb_source_record_414 Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr

    If (-Cast(c2fb_c_int, ((arg1 > arg0->nBuffer)))) Then
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(arg0->nBuffer))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_int64, (arg1 * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->aBuffer), arg0->nBuffer)))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, (local0 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_3 = CPtr(ZString Ptr Ptr, @(arg0->aBuffer))
        c2fb_temp_4 = local0
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts3SegReaderStep CDecl Alias "sqlite3Fts3SegReaderStep" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_source_record_414 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_source_record_417 Ptr Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_source_record_413 Ptr
    Dim local10 As c2fb_callback_217
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local13 As c2fb_source_record_417 Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As ZString Ptr Ptr
    Dim c2fb_temp_15 As ZString Ptr
    Dim c2fb_temp_16 As ZString Ptr Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_int64
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim local16 As c2fb_c_int
    Dim local17 As ZString Ptr
    Dim local18 As c2fb_c_int
    Dim local19 As c2fb_c_int
    Dim local20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim local21 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_int64
    Dim c2fb_temp_24 As c2fb_int64
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim local22 As ZString Ptr
    Dim local23 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_int64
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_int64
    Dim c2fb_temp_32 As Any Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Byte Ptr
    Dim c2fb_temp_36 As Byte
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As Any Ptr
    Dim c2fb_temp_39 As ZString Ptr Ptr
    Dim c2fb_temp_40 As ZString Ptr
    Dim c2fb_temp_41 As c2fb_c_int Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int Ptr
    Dim c2fb_temp_45 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (Cast(c2fb_c_int, (arg1->pFilter->flags And Cast(c2fb_c_int, &H00000002ULL))))
    local2 = (Cast(c2fb_c_int, (arg1->pFilter->flags And Cast(c2fb_c_int, &H00000001ULL))))
    local3 = (Cast(c2fb_c_int, (arg1->pFilter->flags And Cast(c2fb_c_int, &H00000004ULL))))
    local4 = (Cast(c2fb_c_int, (arg1->pFilter->flags And Cast(c2fb_c_int, &H00000008ULL))))
    local5 = (Cast(c2fb_c_int, (arg1->pFilter->flags And Cast(c2fb_c_int, &H00000010ULL))))
    local6 = (Cast(c2fb_c_int, (arg1->pFilter->flags And Cast(c2fb_c_int, &H00000020ULL))))
    local7 = CPtr(c2fb_source_record_417 Ptr Ptr, arg1->apSegment)
    local8 = arg1->nSegment
    local9 = arg1->pFilter
    local10 = (IIf(arg0->bDescIdx, CPtr(Any Ptr, ProcPtr(fts3SegReaderDoclistCmpRev)), CPtr(Any Ptr, ProcPtr(fts3SegReaderDoclistCmp))))
    If (-Cast(c2fb_c_int, ((arg1->nSegment = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    Do
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local12 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local12 < arg1->nAdvance))))
            local13 = local7[local12]
            If local13->bLookup Then
                fts3SegReaderSetEof(local13)
            Else
                c2fb_temp_2 = Cast(c2fb_c_int, fts3SegReaderNext(arg0, local13, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_2
            End If
            If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return local0
            End If
        c2fb_flow_3:
            c2fb_temp_1 = local12
            local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_2:
        fts3SegReaderSort(local7, local8, arg1->nAdvance, ProcPtr(fts3SegReaderCmp))
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg1->nAdvance))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_3) = c2fb_temp_4
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local7[Cast(c2fb_c_int, &O0ULL)]->aNode = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg1->nTerm))
        c2fb_temp_6 = Cast(c2fb_c_int, local7[Cast(c2fb_c_int, &O0ULL)]->nTerm)
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(ZString Ptr Ptr, @(arg1->zTerm))
        c2fb_temp_8 = local7[Cast(c2fb_c_int, &O0ULL)]->zTerm
        (*c2fb_temp_7) = c2fb_temp_8
        If (-Cast(c2fb_c_int, (((local9->zTerm <> 0) AndAlso ((-Cast(c2fb_c_int, (local5 = 0))) <> 0))))) Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->nTerm < local9->nTerm)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local4 = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->nTerm > local9->nTerm)))) <> 0)))))) <> 0) OrElse (c2fb_crt_memcmp(CPtr(Const Any Ptr, arg1->zTerm), CPtr(Const Any Ptr, local9->zTerm), local9->nTerm) <> 0))))) Then
                Goto c2fb_flow_0
            End If
        End If
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local11 = c2fb_temp_9
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local11 < local8)))) <> 0) AndAlso (local7[local11]->aNode <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7[local11]->nTerm = arg1->nTerm)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, arg1->zTerm), CPtr(Const Any Ptr, local7[local11]->zTerm), arg1->nTerm))))) <> 0)))))
            c2fb_temp_10 = local11
            local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
        c2fb_flow_5:
        Wend
        c2fb_flow_4:
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local11 = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (local1 = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (local6 = 0))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->bDescIdx) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((local7[Cast(c2fb_c_int, &O0ULL)])->ppNextElem <> Cast(c2fb_c_int, &O0ULL)))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
            c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @(arg1->nDoclist))
            c2fb_temp_12 = Cast(c2fb_c_int, local7[Cast(c2fb_c_int, &O0ULL)]->nDoclist)
            (*c2fb_temp_11) = c2fb_temp_12
            If ((-Cast(c2fb_c_int, (((local7[Cast(c2fb_c_int, &O0ULL)])->ppNextElem <> Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_13 = Cast(c2fb_c_int, fts3MsrBufferData(arg1, local7[Cast(c2fb_c_int, &O0ULL)]->aDoclist, Cast(c2fb_int64, arg1->nDoclist)))
                local0 = c2fb_temp_13
                c2fb_temp_14 = CPtr(ZString Ptr Ptr, @(arg1->aDoclist))
                c2fb_temp_15 = arg1->aBuffer
                (*c2fb_temp_14) = c2fb_temp_15
            Else
                c2fb_temp_16 = CPtr(ZString Ptr Ptr, @(arg1->aDoclist))
                c2fb_temp_17 = local7[Cast(c2fb_c_int, &O0ULL)]->aDoclist
                (*c2fb_temp_16) = c2fb_temp_17
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, 100ULL))
                local0 = c2fb_temp_18
            End If
        Else
            local14 = Cast(c2fb_c_int, &O0ULL)
            local15 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local12 = c2fb_temp_19
            While (-Cast(c2fb_c_int, ((local12 < local11))))
                fts3SegReaderFirstDocid(arg0, local7[local12])
            c2fb_flow_7:
                c2fb_temp_20 = local12
                local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 + 1)))
            Wend
            c2fb_flow_6:
            fts3SegReaderSort(local7, local11, local11, local10)
            While local7[Cast(c2fb_c_int, &O0ULL)]->pOffsetList
                ' C automatic storage declaration
                local17 = Cast(c2fb_c_int, &O0ULL)
                local18 = Cast(c2fb_c_int, &O0ULL)
                ' C automatic storage declaration
                local20 = local7[Cast(c2fb_c_int, &O0ULL)]->iDocid
                fts3SegReaderNextDocid(arg0, local7[Cast(c2fb_c_int, &O0ULL)], CPtr(ZString Ptr Ptr, @(local17)), CPtr(c2fb_c_int Ptr, @(local18)))
                c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local16 = c2fb_temp_21
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local16 < local11)))) <> 0) AndAlso (local7[local16]->pOffsetList <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7[local16]->iDocid = local20)))) <> 0)))))
                    fts3SegReaderNextDocid(arg0, local7[local16], Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
                    c2fb_temp_22 = local16
                    local16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_22 + 1)))
                c2fb_flow_11:
                Wend
                c2fb_flow_10:
                If local3 Then
                    fts3ColumnFilter(local9->iCol, Cast(c2fb_c_int, &O0ULL), CPtr(ZString Ptr Ptr, @(local17)), CPtr(c2fb_c_int Ptr, @(local18)))
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local1 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local18 > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    ' C automatic storage declaration
                    If (-Cast(c2fb_c_int, (((arg0->bDescIdx <> 0) AndAlso ((-Cast(c2fb_c_int, ((local14 > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        If (-Cast(c2fb_c_int, ((local15 <= local20)))) Then
                            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
                        End If
                        c2fb_temp_23 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, local15) - Cast(c2fb_uint64, local20))))))
                        local21 = c2fb_temp_23
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local14 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local15 >= local20)))) <> 0))))) Then
                            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
                        End If
                        c2fb_temp_24 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, local20) - Cast(c2fb_uint64, local15))))))
                        local21 = c2fb_temp_24
                    End If
                    c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, (sqlite3Fts3VarintLen(local21) + (IIf(local2, Cast(c2fb_c_int, (local18 + Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL))))))
                    local19 = c2fb_temp_25
                    c2fb_temp_26 = Cast(c2fb_c_int, fts3GrowSegReaderBuffer(arg1, Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, local19) + Cast(c2fb_int64, local14))) + Cast(c2fb_int64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL)))))))))
                    local0 = c2fb_temp_26
                    If local0 Then
                        Return local0
                    End If
                    If local6 Then
                        local22 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aBuffer)[local14])))
                        ' C automatic storage declaration
                        c2fb_temp_27 = Cast(c2fb_c_int, sqlite3Fts3FirstFilter(local21, local17, local18, local22))
                        local23 = c2fb_temp_27
                        If local23 Then
                            c2fb_temp_28 = Cast(c2fb_int64, local20)
                            local15 = c2fb_temp_28
                            c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 + local23)))
                            local14 = c2fb_temp_29
                        End If
                    Else
                        c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aBuffer)[local14]))), local21))))
                        local14 = c2fb_temp_30
                        c2fb_temp_31 = Cast(c2fb_int64, local20)
                        local15 = c2fb_temp_31
                        If local2 Then
                            c2fb_temp_32 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aBuffer)[local14]))), CPtr(Const Any Ptr, local17), local18))
                            c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 + local18)))
                            local14 = c2fb_temp_33
                            c2fb_temp_34 = local14
                            local14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_34 + 1)))
                            c2fb_temp_35 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aBuffer)[c2fb_temp_34]))
                            c2fb_temp_36 = Cast(Byte, Cast(c2fb_c_int, 0))
                            (*c2fb_temp_35) = c2fb_temp_36
                        End If
                    End If
                End If
                fts3SegReaderSort(local7, local11, local16, local10)
            c2fb_flow_9:
            Wend
            c2fb_flow_8:
            If (-Cast(c2fb_c_int, ((local14 > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_37 = Cast(c2fb_c_int, fts3GrowSegReaderBuffer(arg1, Cast(c2fb_int64, (Cast(c2fb_int64, local14) + Cast(c2fb_int64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL)))))))))
                local0 = c2fb_temp_37
                If local0 Then
                    Return local0
                End If
                c2fb_temp_38 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg1->aBuffer)[local14]))), Cast(c2fb_c_int, &O0ULL), (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * Cast(c2fb_c_int, 2ULL))))))
                c2fb_temp_39 = CPtr(ZString Ptr Ptr, @(arg1->aDoclist))
                c2fb_temp_40 = arg1->aBuffer
                (*c2fb_temp_39) = c2fb_temp_40
                c2fb_temp_41 = CPtr(c2fb_c_int Ptr, @(arg1->nDoclist))
                c2fb_temp_42 = Cast(c2fb_c_int, local14)
                (*c2fb_temp_41) = c2fb_temp_42
                c2fb_temp_43 = Cast(c2fb_c_int, Cast(c2fb_c_int, 100ULL))
                local0 = c2fb_temp_43
            End If
        End If
        c2fb_temp_44 = CPtr(c2fb_c_int Ptr, @(arg1->nAdvance))
        c2fb_temp_45 = Cast(c2fb_c_int, local11)
        (*c2fb_temp_44) = c2fb_temp_45
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL)))))
    c2fb_flow_0:
    Return local0
End Function
Sub sqlite3Fts3SegReaderFinish CDecl Alias "sqlite3Fts3SegReaderFinish" (ByVal arg0 As c2fb_source_record_414 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr Ptr Ptr
    Dim c2fb_temp_5 As c2fb_source_record_417 Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nSegment))))
            sqlite3Fts3SegReaderFree(CPtr(c2fb_source_record_417 Ptr Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg0->apSegment))[local0])
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_source_record_417 Ptr Ptr, arg0->apSegment)))
        sqlite3_free(CPtr(Any Ptr, arg0->aBuffer))
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg0->nSegment))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(Any Ptr Ptr Ptr, @(arg0->apSegment))
        c2fb_temp_5 = CPtr(c2fb_source_record_417 Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_4) = CPtr(Any Ptr Ptr, c2fb_temp_5)
        c2fb_temp_5 = CPtr(c2fb_source_record_417 Ptr Ptr, (*c2fb_temp_4))
        c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(arg0->aBuffer))
        c2fb_temp_7 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_6) = c2fb_temp_7
    End If
End Sub
Private Sub fts3ReadEndBlockField CDecl Alias "fts3ReadEndBlockField" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As c2fb_int64 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As Const UByte Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_uint64
    Dim c2fb_temp_3 As c2fb_int64 Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_uint64
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_uint64
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_int64 Ptr
    Dim c2fb_temp_13 As c2fb_int64

    local0 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text_(arg0, arg1))
    If local0 Then
        ' C automatic storage declaration
        local2 = Cast(c2fb_c_int, 1ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0[local1]) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0[local1]) <= Cast(c2fb_c_int, 57))))) <> 0)))))
            c2fb_temp_2 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (local3 * Cast(c2fb_uint64, Cast(c2fb_c_int, 10ULL)))) + Cast(c2fb_uint64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, local0[local1]) - Cast(c2fb_c_int, 48))))))))
            local3 = c2fb_temp_2
        c2fb_flow_1:
            c2fb_temp_1 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_3 = CPtr(c2fb_int64 Ptr, @((*arg2)))
        c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_int64, local3))
        (*c2fb_temp_3) = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0[local1]) = Cast(c2fb_c_int, 32)))))
            c2fb_temp_5 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_6 = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_6
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0[local1]) = Cast(c2fb_c_int, 45))))) Then
            c2fb_temp_7 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            local2 = c2fb_temp_8
        End If
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0[local1]) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0[local1]) <= Cast(c2fb_c_int, 57))))) <> 0)))))
            c2fb_temp_10 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (local3 * Cast(c2fb_uint64, Cast(c2fb_c_int, 10ULL)))) + Cast(c2fb_uint64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, local0[local1]) - Cast(c2fb_c_int, 48))))))))
            local3 = c2fb_temp_10
        c2fb_flow_5:
            c2fb_temp_9 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
        Wend
        c2fb_flow_4:
        If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local3) = (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))) - (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL)))))))))))))) Then
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local2 = c2fb_temp_11
        End If
        c2fb_temp_12 = CPtr(c2fb_int64 Ptr, @((*arg3)))
        c2fb_temp_13 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, local3) * Cast(c2fb_int64, local2)))))
        (*c2fb_temp_12) = c2fb_temp_13
    End If
End Sub
' c2fb skipped fts3PromoteSegments: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3SegmentMerge: requires unconverted C function fts3SegmentMaxLevel
' c2fb skipped sqlite3Fts3PendingTermsFlush: requires unconverted C function fts3SegmentMerge
Private Sub fts3EncodeIntArray CDecl Alias "fts3EncodeIntArray" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_uint Ptr, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, c2fb_temp_0)
    local0 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local0 < arg0))))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg2)[local1]))), Cast(c2fb_int64, arg1[local0])))))
        local1 = c2fb_temp_3
    c2fb_flow_1:
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_5 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_4) = c2fb_temp_5
End Sub
Private Sub fts3DecodeIntArray CDecl Alias "fts3DecodeIntArray" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_uint Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_uint Ptr
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_uint Ptr
    Dim c2fb_temp_8 As c2fb_c_uint

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, (((arg3 <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[Cast(c2fb_c_int, (arg3 - Cast(c2fb_c_int, 1ULL)))]) And Cast(c2fb_c_int, &H80ULL)))) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_temp_0)
        local0 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg0)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < arg3)))) <> 0)))))
            ' C automatic storage declaration
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg2)[local1]))), CPtr(c2fb_int64 Ptr, @(local2))))))
            local1 = c2fb_temp_3
            c2fb_temp_4 = CPtr(c2fb_c_uint Ptr, @(arg1[local0]))
            c2fb_temp_5 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_int64, (local2 And Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)))))))
            (*c2fb_temp_4) = c2fb_temp_5
        c2fb_flow_1:
            c2fb_temp_2 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
    End If
    While (-Cast(c2fb_c_int, ((local0 < arg0))))
        c2fb_temp_6 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        c2fb_temp_7 = CPtr(c2fb_c_uint Ptr, @(arg1[c2fb_temp_6]))
        c2fb_temp_8 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_7) = c2fb_temp_8
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
End Sub
' c2fb skipped fts3InsertDocsize: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3UpdateDocTotals: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3DoOptimize: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3DoRebuild: requires unconverted C function fts3DeleteAll
' c2fb skipped fts3IncrmergeCsr: requires unconverted C function fts3SqlStmt
Private Sub blobGrowBuffer CDecl Alias "blobGrowBuffer" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((*arg2) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 > arg0->nAlloc)))) <> 0))))) Then
        local0 = arg1
        local1 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->a), local0)))
        If local1 Then
            c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->nAlloc))
            c2fb_temp_1 = Cast(c2fb_c_int, local0)
            (*c2fb_temp_0) = c2fb_temp_1
            c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg0->a))
            c2fb_temp_3 = local1
            (*c2fb_temp_2) = c2fb_temp_3
        Else
            c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_4) = c2fb_temp_5
        End If
    End If
End Sub
Private Function nodeReaderNext CDecl Alias "nodeReaderNext" (ByVal arg0 As c2fb_source_record_423 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Const ZString Ptr Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Any Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As Const ZString Ptr Ptr
    Dim c2fb_temp_25 As Const ZString Ptr
    Dim c2fb_temp_26 As c2fb_c_int Ptr
    Dim c2fb_temp_27 As c2fb_c_int

    local0 = ((-Cast(c2fb_c_int, ((arg0->term.n = Cast(c2fb_c_int, &O0ULL))))))
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((arg0->iChild <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(arg0->iChild))
        c2fb_temp_1 = (*c2fb_temp_0)
        (*c2fb_temp_0) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_1 + 1)))
    End If
    If (-Cast(c2fb_c_int, ((arg0->iOff >= arg0->nNode)))) Then
        c2fb_temp_2 = CPtr(Const ZString Ptr Ptr, @(arg0->aNode))
        c2fb_temp_3 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_2) = c2fb_temp_3
    Else
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(arg0->iOff))
            If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff])))))) And Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_6 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff]))), CPtr(c2fb_c_int Ptr, @(local1)))
            Else
                c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local1)))))
                c2fb_temp_5 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff]))))))
                (*c2fb_temp_4) = c2fb_temp_5
                c2fb_temp_6 = (Cast(c2fb_c_int, 1ULL))
            End If
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_7) + (c2fb_temp_6))))
            (*c2fb_temp_7) = c2fb_temp_8
        End If
        c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @(arg0->iOff))
        If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff])))))) And Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_11 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff]))), CPtr(c2fb_c_int Ptr, @(local2)))
        Else
            c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local2)))))
            c2fb_temp_10 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff]))))))
            (*c2fb_temp_9) = c2fb_temp_10
            c2fb_temp_11 = (Cast(c2fb_c_int, 1ULL))
        End If
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_12) + (c2fb_temp_11))))
        (*c2fb_temp_12) = c2fb_temp_13
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > arg0->term.n)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 > Cast(c2fb_c_int, (arg0->nNode - arg0->iOff)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        blobGrowBuffer(CPtr(c2fb_source_record_420 Ptr, @(arg0->term)), Cast(c2fb_c_int, (local1 + local2)), CPtr(c2fb_c_int Ptr, @(local3)))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((arg0->term.a <> Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
            c2fb_temp_14 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->term.a)[local1]))), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff]))), local2))
            c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @(arg0->term.n))
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + local2)))
            (*c2fb_temp_15) = c2fb_temp_16
            c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @(arg0->iOff))
            c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_17) + local2)))
            (*c2fb_temp_17) = c2fb_temp_18
            If (-Cast(c2fb_c_int, ((arg0->iChild = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @(arg0->iOff))
                If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff])))))) And Cast(c2fb_c_int, &H80ULL)))) Then
                    c2fb_temp_21 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff]))), CPtr(c2fb_c_int Ptr, @(arg0->nDoclist)))
                Else
                    c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(arg0->nDoclist)))))
                    c2fb_temp_20 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff]))))))
                    (*c2fb_temp_19) = c2fb_temp_20
                    c2fb_temp_21 = (Cast(c2fb_c_int, 1ULL))
                End If
                c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_22) + (c2fb_temp_21))))
                (*c2fb_temp_22) = c2fb_temp_23
                If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->nNode - arg0->iOff))) < arg0->nDoclist)))) Then
                    Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
                End If
                c2fb_temp_24 = CPtr(Const ZString Ptr Ptr, @(arg0->aDoclist))
                c2fb_temp_25 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[arg0->iOff])))
                (*c2fb_temp_24) = c2fb_temp_25
                c2fb_temp_26 = CPtr(c2fb_c_int Ptr, @(arg0->iOff))
                c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_26) + arg0->nDoclist)))
                (*c2fb_temp_26) = c2fb_temp_27
            End If
        End If
    End If
    ' C unused-parameter annotation
    Return local3
End Function
Private Sub nodeReaderRelease CDecl Alias "nodeReaderRelease" (ByVal arg0 As c2fb_source_record_423 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    sqlite3_free(CPtr(Any Ptr, arg0->term.a))
End Sub
Private Function nodeReaderInit CDecl Alias "nodeReaderInit" (ByVal arg0 As c2fb_source_record_423 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_423))))
    c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, @(arg0->aNode))
    c2fb_temp_2 = arg1
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg0->nNode))
    c2fb_temp_4 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_3) = c2fb_temp_4
    If (-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso (CPtr(Const Byte Ptr, arg1)[Cast(c2fb_c_int, &O0ULL)] <> 0))))) Then
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg0->iOff))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0->aNode)[Cast(c2fb_c_int, 1ULL)]))), CPtr(c2fb_int64 Ptr, @(arg0->iChild))))))
        (*c2fb_temp_5) = c2fb_temp_6
    Else
        c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(arg0->iOff))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_7) = c2fb_temp_8
    End If
    Return IIf(arg1, nodeReaderNext(arg0), Cast(c2fb_c_int, &O0ULL))
End Function
' c2fb skipped fts3IncrmergePush: requires unconverted C function fts3WriteSegment
Private Function fts3AppendToNode CDecl Alias "fts3AppendToNode" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_source_record_420 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Any Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = ((-Cast(c2fb_c_int, ((arg1->n = Cast(c2fb_c_int, &O0ULL))))))
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    blobGrowBuffer(arg1, arg3, CPtr(c2fb_c_int Ptr, @(local0)))
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local0
    End If
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, fts3PrefixCompress(CPtr(Const ZString Ptr, arg1->a), arg1->n, arg2, arg3))
    local2 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg3 - local2)))
    local3 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local3 <= Cast(c2fb_c_int, &O0ULL))))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg1->a), CPtr(Const Any Ptr, arg2), arg3))
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg1->n))
    c2fb_temp_4 = Cast(c2fb_c_int, arg3)
    (*c2fb_temp_3) = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg0->n))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_5) + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[arg0->n]))), local2))))
        (*c2fb_temp_5) = c2fb_temp_6
    End If
    c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(arg0->n))
    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_7) + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[arg0->n]))), local3))))
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[arg0->n]))), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg2)[local2]))), local3))
    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(arg0->n))
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_10) + local3)))
    (*c2fb_temp_10) = c2fb_temp_11
    If arg4 Then
        c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @(arg0->n))
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_12) + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[arg0->n]))), arg5))))
        (*c2fb_temp_12) = c2fb_temp_13
        c2fb_temp_14 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[arg0->n]))), CPtr(Const Any Ptr, arg4), arg5))
        c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @(arg0->n))
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_15) + arg5)))
        (*c2fb_temp_15) = c2fb_temp_16
    End If
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped fts3IncrmergeAppend: requires unconverted C function fts3WriteSegment
' c2fb skipped fts3IncrmergeRelease: requires unconverted C function fts3WriteSegment
Private Function fts3TermCmp CDecl Alias "fts3TermCmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = (IIf((-Cast(c2fb_c_int, (((arg1) < (arg3))))), (arg1), (arg3)))
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((arg0) <> 0) AndAlso ((arg2) <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_crt_memcmp(CPtr(Const Any Ptr, arg0), CPtr(Const Any Ptr, arg2), local0))
        local1 = c2fb_temp_0
    Else
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1 - arg3)))
        local1 = c2fb_temp_2
    End If
    Return local1
End Function
' c2fb skipped fts3IsAppendable: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3IncrmergeLoad: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3IncrmergeOutputIdx: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3IncrmergeWriter: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3RemoveSegdirEntry: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3RepackSegdirLevel: requires unconverted C function fts3SqlStmt
Private Sub fts3StartNode CDecl Alias "fts3StartNode" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim c2fb_temp_0 As Byte Ptr
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    c2fb_temp_0 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(Byte, Cast(Byte, arg1))
    (*c2fb_temp_0) = c2fb_temp_1
    If arg2 Then
        ' C unused-parameter annotation
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg0->n))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[Cast(c2fb_c_int, 1ULL)]))), arg2))))
        (*c2fb_temp_2) = c2fb_temp_3
    Else
        ' C unused-parameter annotation
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->n))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_4) = c2fb_temp_5
    End If
End Sub
Private Function fts3TruncateNode CDecl Alias "fts3TruncateNode" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_420 Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_423
    Dim local1 As c2fb_source_record_420
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_int64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_int64 Ptr
    Dim c2fb_temp_9 As c2fb_int64

    ' C automatic storage declaration
    local1 = Type<c2fb_source_record_420>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, 1ULL))))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 0))))))
    local3 = c2fb_temp_0
    blobGrowBuffer(arg2, arg1, CPtr(c2fb_c_int Ptr, @(local2)))
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local2
    End If
    c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @(arg2->n))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = Cast(c2fb_c_int, nodeReaderInit(CPtr(c2fb_source_record_423 Ptr, @(local0)), arg0, arg1))
    local2 = c2fb_temp_3
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0.aNode <> 0)))))
        If (-Cast(c2fb_c_int, ((arg2->n = Cast(c2fb_c_int, &O0ULL))))) Then
            local4 = fts3TermCmp(CPtr(Const ZString Ptr, local0.term.a), local0.term.n, arg3, arg4)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
                Goto c2fb_flow_1
            End If
            fts3StartNode(arg2, Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)]), local0.iChild)
            c2fb_temp_5 = CPtr(c2fb_int64 Ptr, @((*arg5)))
            c2fb_temp_6 = Cast(c2fb_int64, local0.iChild)
            (*c2fb_temp_5) = c2fb_temp_6
        End If
        c2fb_temp_7 = Cast(c2fb_c_int, fts3AppendToNode(arg2, CPtr(c2fb_source_record_420 Ptr, @(local1)), CPtr(Const ZString Ptr, local0.term.a), local0.term.n, local0.aDoclist, local0.nDoclist))
        local2 = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_4 = Cast(c2fb_c_int, nodeReaderNext(CPtr(c2fb_source_record_423 Ptr, @(local0))))
        local2 = c2fb_temp_4
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((arg2->n = Cast(c2fb_c_int, &O0ULL))))) Then
        fts3StartNode(arg2, Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)]), local0.iChild)
        c2fb_temp_8 = CPtr(c2fb_int64 Ptr, @((*arg5)))
        c2fb_temp_9 = Cast(c2fb_int64, local0.iChild)
        (*c2fb_temp_8) = c2fb_temp_9
    End If
    ' C unused-parameter annotation
    nodeReaderRelease(CPtr(c2fb_source_record_423 Ptr, @(local0)))
    sqlite3_free(CPtr(Any Ptr, local1.a))
    Return local2
End Function
' c2fb skipped fts3TruncateSegment: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3IncrmergeChomp: requires unconverted C function fts3DeleteSegment
' c2fb skipped fts3IncrmergeHintStore: requires unconverted C function fts3SqlStmt
' c2fb skipped fts3IncrmergeHintLoad: requires unconverted C function fts3SqlStmt
Private Sub fts3IncrmergeHintPush CDecl Alias "fts3IncrmergeHintPush" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    blobGrowBuffer(arg0, Cast(c2fb_c_int, (arg0->n + Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) * Cast(c2fb_c_int, 10ULL))))), arg3)
    If (-Cast(c2fb_c_int, (((*arg3) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->n))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_0) + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[arg0->n]))), arg1))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg0->n))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_2) + sqlite3Fts3PutVarint(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[arg0->n]))), Cast(c2fb_int64, arg2)))))
        (*c2fb_temp_2) = c2fb_temp_3
    End If
End Sub
Private Function fts3IncrmergeHintPop CDecl Alias "fts3IncrmergeHintPop" (ByVal arg0 As c2fb_source_record_420 Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int

    local0 = arg0->n
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg0->n - Cast(c2fb_c_int, 1ULL))))
    local1 = c2fb_temp_0
    If (Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Byte Ptr, arg0->a)[local1]) And Cast(c2fb_c_int, &H80ULL)))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Byte Ptr, arg0->a)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 1ULL)))]) And Cast(c2fb_c_int, &H80ULL)))) <> 0)))))
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    c2fb_temp_2 = local1
    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 - 1)))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Byte Ptr, arg0->a)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 1ULL)))]) And Cast(c2fb_c_int, &H80ULL)))) <> 0)))))
        c2fb_temp_3 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->n))
    c2fb_temp_5 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[local1]))), arg1))))
    local1 = c2fb_temp_6
    If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[local1])))))) And Cast(c2fb_c_int, &H80ULL)))) Then
        c2fb_temp_9 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[local1]))), arg2)
    Else
        c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_8 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->a)[local1]))))))
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = (Cast(c2fb_c_int, 1ULL))
    End If
    c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + (c2fb_temp_9))))
    local1 = c2fb_temp_10
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local1 <> local0)))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped sqlite3Fts3Incrmerge: requires unconverted C function fts3IncrmergeHintLoad
Private Function fts3Getint CDecl Alias "fts3Getint" (ByVal arg0 As Const ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Const ZString Ptr Ptr
    Dim c2fb_temp_4 As Const ZString Ptr

    local0 = (*arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((*CPtr(Const Byte Ptr, local0)))) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((*CPtr(Const Byte Ptr, local0)))) <= Cast(c2fb_c_int, 57))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, 214748363ULL))))) <> 0)))))
        c2fb_temp_1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * local1))
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (c2fb_temp_1 + Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, (c2fb_temp_0)))))) - Cast(c2fb_c_int, 48))))
        local1 = c2fb_temp_2
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(Const ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_4 = local0
    (*c2fb_temp_3) = c2fb_temp_4
    Return local1
End Function
Private Function fts3DoIncrmerge CDecl Alias "fts3DoIncrmerge" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    local1 = (Cast(c2fb_c_int, (Cast(c2fb_c_int, 16ULL) \ Cast(c2fb_c_int, 2ULL))))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = arg1
    c2fb_temp_0 = Cast(c2fb_c_int, fts3Getint(CPtr(Const ZString Ptr Ptr, @(local3))))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 44))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, 1ULL)]) <> Cast(c2fb_c_int, 0))))) <> 0))))) Then
        c2fb_temp_1 = local3
        local3 = (c2fb_temp_1 + 1)
        c2fb_temp_2 = Cast(c2fb_c_int, fts3Getint(CPtr(Const ZString Ptr Ptr, @(local3))))
        local1 = c2fb_temp_2
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 0))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_3
    Else
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_4
        If (-Cast(c2fb_c_int, (arg0->bHasStat = 0))) Then
            ' C unused-parameter annotation
            sqlite3Fts3CreateStatTable(CPtr(c2fb_c_int Ptr, @(local0)), arg0)
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, sqlite3Fts3Incrmerge(arg0, local2, local1))
            local0 = c2fb_temp_5
        End If
        sqlite3Fts3SegmentsClose(arg0)
    End If
    Return local0
End Function
' c2fb skipped fts3DoAutoincrmerge: requires unconverted C function fts3SqlStmt
Private Function fts3ChecksumEntry CDecl Alias "fts3ChecksumEntry" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_int64, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int) As c2fb_uint64
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_uint64
    Dim c2fb_temp_1 As c2fb_uint64
    Dim c2fb_temp_2 As c2fb_uint64
    Dim c2fb_temp_3 As c2fb_uint64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_uint64

    ' C automatic storage declaration
    local1 = Cast(c2fb_uint64, arg4)
    c2fb_temp_0 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, arg2))))))
    local1 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, arg3))))))
    local1 = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, arg5))))))
    local1 = c2fb_temp_2
    c2fb_temp_3 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, arg6))))))
    local1 = c2fb_temp_3
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        c2fb_temp_6 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, CPtr(Const Byte Ptr, arg0)[local0]))))))
        local1 = c2fb_temp_6
    c2fb_flow_1:
        c2fb_temp_5 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function
Private Function fts3ChecksumIndex CDecl Alias "fts3ChecksumIndex" (ByVal arg0 As c2fb_source_record_408 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr) As c2fb_uint64
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_413
    Dim local1 As c2fb_source_record_414
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_uint64
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_uint64
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As ZString Ptr
    Dim local9 As c2fb_uint64
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_uint64
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As ZString Ptr
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As c2fb_int64
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_uint64
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_uint64
    Dim c2fb_temp_26 As c2fb_c_int Ptr
    Dim c2fb_temp_27 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    If (*arg3) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_413 Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_413))))
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_414 Ptr, @(local1))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_414))))
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(local0.flags))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000001ULL) Or Cast(c2fb_c_int, &H00000002ULL))))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(local0.flags))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_4) Or Cast(c2fb_c_int, &H00000010ULL))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = Cast(c2fb_c_int, sqlite3Fts3SegReaderCursor(arg0, arg1, arg2, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL), CPtr(c2fb_source_record_414 Ptr, @(local1))))
    local2 = c2fb_temp_6
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_7 = Cast(c2fb_c_int, sqlite3Fts3SegReaderStart(arg0, CPtr(c2fb_source_record_414 Ptr, @(local1)), CPtr(c2fb_source_record_413 Ptr, @(local0))))
        local2 = c2fb_temp_7
    End If
    Do
        c2fb_temp_10 = 0
        If ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) Then
            c2fb_temp_9 = Cast(c2fb_c_int, 100ULL)
            c2fb_temp_8 = Cast(c2fb_c_int, sqlite3Fts3SegReaderStep(arg0, CPtr(c2fb_source_record_414 Ptr, @(local1))))
            local2 = c2fb_temp_8
            c2fb_temp_10 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_9 = (c2fb_temp_8))))) <> 0))))
        End If
        If (c2fb_temp_10 = 0) Then Goto c2fb_flow_0
        local4 = local1.aDoclist
        local5 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local4)[local1.nDoclist])))
        local6 = Cast(c2fb_c_int, &O0ULL)
        local7 = Cast(c2fb_c_int, &O0ULL)
        local8 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_11
        c2fb_temp_12 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local4) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local4), CPtr(c2fb_int64 Ptr, @(local6)))))
        local4 = c2fb_temp_12
        While (-Cast(c2fb_c_int, ((local4 < local5))))
            local9 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_13 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local4) + sqlite3Fts3GetVarintU(CPtr(Const ZString Ptr, local4), CPtr(c2fb_uint64 Ptr, @(local9)))))
            local4 = c2fb_temp_13
            If (-Cast(c2fb_c_int, ((local4 < local5)))) Then
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local9 = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local9 = Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))) <> 0))))) Then
                    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local7 = c2fb_temp_14
                    c2fb_temp_15 = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))
                    local8 = c2fb_temp_15
                    If local9 Then
                        If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local4)))) And Cast(c2fb_c_int, &H80ULL)))) Then
                            c2fb_temp_18 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local4), CPtr(c2fb_c_int Ptr, @(local7)))
                        Else
                            c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local7)))))
                            c2fb_temp_17 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local4))))
                            (*c2fb_temp_16) = c2fb_temp_17
                            c2fb_temp_18 = (Cast(c2fb_c_int, 1ULL))
                        End If
                        c2fb_temp_19 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local4) + (c2fb_temp_18)))
                        local4 = c2fb_temp_19
                    Else
                        c2fb_temp_20 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local4) + sqlite3Fts3GetVarintU(CPtr(Const ZString Ptr, local4), CPtr(c2fb_uint64 Ptr, @(local9)))))
                        local4 = c2fb_temp_20
                        If arg0->bDescIdx Then
                            c2fb_temp_21 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, local6) - local9)))))
                            local6 = c2fb_temp_21
                        Else
                            c2fb_temp_22 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, local6) + local9)))))
                            local6 = c2fb_temp_22
                        End If
                    End If
                Else
                    c2fb_temp_23 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local8 + (Cast(c2fb_uint64, (local9 - Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))))))))
                    local8 = c2fb_temp_23
                    If (-Cast(c2fb_c_int, ((local8 > Cast(c2fb_uint64, Cast(c2fb_c_int, &H7FFFFFFFULL)))))) Then
                        c2fb_temp_24 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                        local2 = c2fb_temp_24
                        Goto c2fb_flow_2
                    Else
                        c2fb_temp_25 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local3 Xor fts3ChecksumEntry(CPtr(Const ZString Ptr, local1.zTerm), local1.nTerm, arg1, arg2, local6, local7, Cast(c2fb_c_int, local8)))))
                        local3 = c2fb_temp_25
                    End If
                End If
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
    Loop
    c2fb_flow_0:
    sqlite3Fts3SegReaderFinish(CPtr(c2fb_source_record_414 Ptr, @(local1)))
    c2fb_temp_26 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_27 = Cast(c2fb_c_int, local2)
    (*c2fb_temp_26) = c2fb_temp_27
    Return local3
End Function
' c2fb skipped sqlite3Fts3IntegrityCheck: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3Fts3IntegrityCheck: assignment parser stopped at byte 13 (rc = pModule->xNext(pT, &zToken, &nToken, &iDum1, &iDum2, &iPos)): ->xNext(pT, &zToken, &nToken, &iDum1, &iDum2, &iPos)
Private Function fts3DoIntegrityCheck CDecl Alias "fts3DoIntegrityCheck" (ByVal arg0 As c2fb_source_record_408 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, sqlite3Fts3IntegrityCheck(arg0, CPtr(c2fb_c_int Ptr, @(local1))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
        local0 = c2fb_temp_1
    End If
    Return local0
End Function
' c2fb skipped fts3SpecialInsert: requires unconverted C function fts3DoOptimize
Sub sqlite3Fts3FreeDeferredDoclists CDecl Alias "sqlite3Fts3FreeDeferredDoclists" (ByVal arg0 As c2fb_source_record_409 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_415 Ptr Ptr
    Dim c2fb_temp_3 As c2fb_source_record_415 Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_416 Ptr, arg0->pDeferred)
    local0 = c2fb_temp_0
    While local0
        fts3PendingListDelete(local0->pList)
        c2fb_temp_2 = CPtr(c2fb_source_record_415 Ptr Ptr, @(local0->pList))
        c2fb_temp_3 = CPtr(c2fb_source_record_415 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_2) = c2fb_temp_3
    c2fb_flow_1:
        c2fb_temp_1 = local0->pNext
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
End Sub
Sub sqlite3Fts3FreeDeferredTokens CDecl Alias "sqlite3Fts3FreeDeferredTokens" (ByVal arg0 As c2fb_source_record_409 Ptr)
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_416 Ptr
    Dim local1 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As c2fb_source_record_416 Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_416 Ptr, arg0->pDeferred)
    local0 = c2fb_temp_0
    While local0
        c2fb_temp_2 = local0->pNext
        local1 = c2fb_temp_2
        fts3PendingListDelete(local0->pList)
        sqlite3_free(CPtr(Any Ptr, local0))
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(Any Ptr Ptr, @(arg0->pDeferred))
    c2fb_temp_4 = CPtr(c2fb_source_record_416 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_3) = CPtr(Any Ptr, c2fb_temp_4)
    c2fb_temp_4 = CPtr(c2fb_source_record_416 Ptr, (*c2fb_temp_3))
End Sub
' c2fb skipped sqlite3Fts3CacheDeferredDoclists: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3Fts3CacheDeferredDoclists: assignment parser stopped at byte 13 (rc = pModule->xNext(pTC, &zToken, &nToken, &iDum1, &iDum2, &iPos)): ->xNext(pTC, &zToken, &nToken, &iDum1, &iDum2, &iPos)
Function sqlite3Fts3DeferredTokenList CDecl Alias "sqlite3Fts3DeferredTokenList" (ByVal arg0 As c2fb_source_record_416 Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As Any Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_1 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((arg0->pList = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_4 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc64(arg0->pList->nData)))
    local0 = c2fb_temp_4
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_5 = Cast(c2fb_c_int, sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, arg0->pList->aData), CPtr(c2fb_int64 Ptr, @(local2))))
    local1 = c2fb_temp_5
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_int64, (arg0->pList->nData - Cast(c2fb_int64, local1))))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_9 = local0
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->pList->aData)[local1]))), (*arg2)))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts3DeferToken CDecl Alias "sqlite3Fts3DeferToken" (ByVal arg0 As c2fb_source_record_409 Ptr, ByVal arg1 As c2fb_source_record_411 Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
    Dim local0 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_source_record_411 Ptr Ptr
    Dim c2fb_temp_3 As c2fb_source_record_411 Ptr
    Dim c2fb_temp_4 As c2fb_source_record_416 Ptr Ptr
    Dim c2fb_temp_5 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Any Ptr Ptr
    Dim c2fb_temp_9 As c2fb_source_record_416 Ptr
    Dim c2fb_temp_10 As Any Ptr Ptr
    Dim c2fb_temp_11 As c2fb_source_record_416 Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_416 Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_source_record_416)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_416))))
    c2fb_temp_2 = CPtr(c2fb_source_record_411 Ptr Ptr, @(local0->pToken))
    c2fb_temp_3 = arg1
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_source_record_416 Ptr Ptr, @(local0->pNext))
    c2fb_temp_5 = CPtr(c2fb_source_record_416 Ptr, arg0->pDeferred)
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(local0->iCol))
    c2fb_temp_7 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(Any Ptr Ptr, @(arg0->pDeferred))
    c2fb_temp_9 = local0
    (*c2fb_temp_8) = CPtr(Any Ptr, c2fb_temp_9)
    c2fb_temp_9 = CPtr(c2fb_source_record_416 Ptr, (*c2fb_temp_8))
    ' C unused-parameter annotation
    c2fb_temp_10 = CPtr(Any Ptr Ptr, @(arg1->pDeferred))
    c2fb_temp_11 = local0
    (*c2fb_temp_10) = CPtr(Any Ptr, c2fb_temp_11)
    c2fb_temp_11 = CPtr(c2fb_source_record_416 Ptr, (*c2fb_temp_10))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped fts3DeleteByRowid: requires unconverted C function fts3DeleteTerms
' c2fb skipped sqlite3Fts3UpdateMethod: requires unconverted C function fts3SpecialInsert
' c2fb skipped sqlite3Fts3Optimize: requires unconverted C function fts3DoOptimize
#endif

/' end of fts3_candidates/sqlite3_bulk_fts3_write_candidates.bas '/
