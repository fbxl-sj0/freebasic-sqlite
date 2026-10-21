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
'/
/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_bulk_fts3_snippet_candidates.bas

    Purpose:

        Hold translated candidates from ext/fts3/fts3_snippet.c for dependency repair.

    Responsibilities:

        - Format snippets and matchinfo results from phrase positions.
        - Preserve source token offsets in returned SQL values.

    This file intentionally does NOT contain:

        - Phrase evaluation and varint helpers that are not yet ported.
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
/' FTS3 snippet and matchinfo candidates                                     '/
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

Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr

Type c2fb_callback_2 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As SQLITE_C_INT) As SQLITE_C_INT
Type c2fb_callback_216 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int

Private Type c2fb_source_record_217
    pModule As Any Ptr
End Type

Private Type c2fb_source_record_219
    count As c2fb_c_int
    chain As Any Ptr
End Type

Private Type c2fb_source_record_220
    keyClass As Byte
    copyKey As Byte
    count As c2fb_c_int
    first As Any Ptr
    htsize As c2fb_c_int
    ht As c2fb_source_record_219 Ptr
End Type

Private Type c2fb_source_record_222
    nPrefix As c2fb_c_int
    hPending As c2fb_source_record_220
End Type

Private Type c2fb_source_record_223
    base As SqliteVtab
    db As sqlite3 Ptr
    zDb As Const ZString Ptr
    zName As Const ZString Ptr
    nColumn As c2fb_c_int
    azColumn As ZString Ptr Ptr
    abNotindexed As UByte Ptr
    pTokenizer As c2fb_source_record_217 Ptr
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
    aIndex As c2fb_source_record_222 Ptr
    nMaxPendingData As c2fb_c_int
    nPendingData As c2fb_c_int
    iPrevDocid As c2fb_int64
    iPrevLangid As c2fb_c_int
    bPrevDelete As c2fb_c_int
End Type

Private Type c2fb_source_record_224
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

Private Type c2fb_source_record_227
    eType As c2fb_c_int
    nNear As c2fb_c_int
    pParent As c2fb_source_record_227 Ptr
    pLeft As c2fb_source_record_227 Ptr
    pRight As c2fb_source_record_227 Ptr
    pPhrase As Any Ptr
    iDocid As c2fb_int64
    bEof As UByte
    bStart As UByte
    bDeferred As UByte
    iPhrase As c2fb_c_int
    aMI As c2fb_c_uint Ptr
End Type

Private Type c2fb_source_record_231
    pCsr As c2fb_source_record_224 Ptr
    iCol As c2fb_c_int
    nSnippet As c2fb_c_int
    nPhrase As c2fb_c_int
    aPhrase As Any Ptr
    iCurrent As c2fb_c_int
End Type

Private Type c2fb_source_record_232
    nToken As c2fb_c_int
    pList As ZString Ptr
    iHead As c2fb_int64
    pHead As ZString Ptr
    iTail As c2fb_int64
    pTail As ZString Ptr
End Type

Private Type c2fb_source_record_234
    pCursor As c2fb_source_record_224 Ptr
    nCol As c2fb_c_int
    nPhrase As c2fb_c_int
    nDoc As c2fb_int64
    flag As Byte
    aMatchinfo As c2fb_c_uint Ptr
End Type

Private Type c2fb_source_record_235
    z As ZString Ptr
    n As c2fb_c_int
    nAlloc As c2fb_c_int
End Type

Private Type c2fb_source_record_236
    pExpr As c2fb_source_record_227 Ptr
    iPosOffset As c2fb_c_int
    pRead As ZString Ptr
    iPos As c2fb_c_int
End Type

Declare Sub fts3GetDeltaPosition CDecl Alias "fts3GetDeltaPosition" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr)
Declare Function fts3ExprIterate2 CDecl Alias "fts3ExprIterate2" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_callback_216, ByVal arg3 As Any Ptr) As c2fb_c_int
Declare Function sqlite3Fts3ExprIterate CDecl Alias "sqlite3Fts3ExprIterate" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_callback_216, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3ExprPhraseCountCb CDecl Alias "fts3ExprPhraseCountCb" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3ExprPhraseCount CDecl Alias "fts3ExprPhraseCount" (ByVal arg0 As c2fb_source_record_227 Ptr) As c2fb_c_int
Declare Sub fts3SnippetAdvance CDecl Alias "fts3SnippetAdvance" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_c_int)
Declare Function fts3SnippetNextCandidate CDecl Alias "fts3SnippetNextCandidate" (ByVal arg0 As c2fb_source_record_231 Ptr) As c2fb_c_int
Declare Sub fts3SnippetDetails CDecl Alias "fts3SnippetDetails" (ByVal arg0 As c2fb_source_record_231 Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_uint64 Ptr, ByVal arg5 As c2fb_uint64 Ptr)
Declare Function fts3StringAppend CDecl Alias "fts3StringAppend" (ByVal arg0 As c2fb_source_record_235 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts3ColumnlistCount CDecl Alias "fts3ColumnlistCount" (ByVal arg0 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3ExprGlobalHitsCb CDecl Alias "fts3ExprGlobalHitsCb" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3ExprLocalHitsCb CDecl Alias "fts3ExprLocalHitsCb" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3MatchinfoCheck CDecl Alias "fts3MatchinfoCheck" (ByVal arg0 As c2fb_source_record_223 Ptr, ByVal arg1 As Byte, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3MatchinfoSize CDecl Alias "fts3MatchinfoSize" (ByVal arg0 As c2fb_source_record_234 Ptr, ByVal arg1 As Byte) As c2fb_int64
Declare Function fts3MatchinfoSelectDoctotal CDecl Alias "fts3MatchinfoSelectDoctotal" (ByVal arg0 As c2fb_source_record_223 Ptr, ByVal arg1 As SqliteVdbe Ptr Ptr, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3MatchinfoLcsCb CDecl Alias "fts3MatchinfoLcsCb" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3LcsIteratorAdvance CDecl Alias "fts3LcsIteratorAdvance" (ByVal arg0 As c2fb_source_record_236 Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_column_blob_ CDecl Alias "sqlite3_column_blob" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function c2fb_external_sqlite3_column_bytes_ CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
' c2fb skipped fts3MIBufferNew: outside the supported subset
' c2fb body diagnostic [unsupported-return-type]: fts3MIBufferNew: return type resolution failed: no mapping for type under target profile
' c2fb skipped fts3MIBufferFree: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: fts3MIBufferFree: expression parser stopped at byte 15 in ((u32*)p==&pBuf->aMI[1]): ->aMI[1]
' c2fb skipped fts3MIBufferAlloc: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: fts3MIBufferAlloc: expression parser stopped at byte 2 in (p->aRef[1]==0): ->aRef[1]==0
' c2fb skipped fts3MIBufferSetGlobal: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3MIBufferSetGlobal: assignment parser stopped at byte 2 (p->bGlobal = 1): ->bGlobal = 1
' c2fb skipped sqlite3Fts3MIBufferFree: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3Fts3MIBufferFree: assignment parser stopped at byte 2 (p->aRef[0] = 0): ->aRef[0] = 0
Private Sub fts3GetDeltaPosition CDecl Alias "fts3GetDeltaPosition" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_int64 Ptr
    Dim c2fb_temp_6 As c2fb_int64

    ' C automatic storage declaration
    c2fb_temp_3 = CPtr(ZString Ptr Ptr, @((*arg0)))
    If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, ((*arg0))))) And Cast(c2fb_c_int, &H80ULL)))) Then
        c2fb_temp_2 = sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, (*arg0)), CPtr(c2fb_c_int Ptr, @(local0)))
    Else
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local0)))))
        c2fb_temp_1 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, ((*arg0)))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = (Cast(c2fb_c_int, 1ULL))
    End If
    c2fb_temp_4 = CPtr(ZString Ptr, (CPtr(Byte Ptr, (*c2fb_temp_3)) + (c2fb_temp_2)))
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_6 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_5) + Cast(c2fb_int64, (Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 2ULL))))))))
    (*c2fb_temp_5) = c2fb_temp_6
End Sub
Private Function fts3ExprIterate2 CDecl Alias "fts3ExprIterate2" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_callback_216, ByVal arg3 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    local1 = arg0->eType
    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, 5ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_0 = Cast(c2fb_c_int, fts3ExprIterate2(arg0->pLeft, arg1, arg2, arg3))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, fts3ExprIterate2(arg0->pRight, arg1, arg2, arg3))
            local0 = c2fb_temp_1
        End If
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, arg2(arg0, (*arg1), arg3))
        local0 = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(((*arg1))))
        c2fb_temp_4 = (*c2fb_temp_3)
        (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    End If
    Return local0
End Function
Function sqlite3Fts3ExprIterate CDecl Alias "sqlite3Fts3ExprIterate" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_callback_216, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    Return fts3ExprIterate2(arg0, CPtr(c2fb_c_int Ptr, @(local0)), arg1, arg2)
End Function
' c2fb skipped fts3ExprLoadDoclistsCb: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3ExprLoadDoclistsCb: assignment parser stopped at byte 21 (p->nToken += pPhrase->nToken): ->nToken
' c2fb skipped fts3ExprLoadDoclists: requires unconverted C function fts3ExprLoadDoclistsCb
Private Function fts3ExprPhraseCountCb CDecl Alias "fts3ExprPhraseCountCb" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(((*CPtr(c2fb_c_int Ptr, arg2)))))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg0->iPhrase))
    c2fb_temp_3 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_2) = c2fb_temp_3
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3ExprPhraseCount CDecl Alias "fts3ExprPhraseCount" (ByVal arg0 As c2fb_source_record_227 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    sqlite3Fts3ExprIterate(arg0, ProcPtr(fts3ExprPhraseCountCb), CPtr(Any Ptr, CPtr(c2fb_c_int Ptr, @(local0))))
    Return local0
End Function
Private Sub fts3SnippetAdvance CDecl Alias "fts3SnippetAdvance" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_int64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr

    local0 = (*arg0)
    If local0 Then
        local1 = (*arg1)
        While (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_int64, arg2)))))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local0))) And Cast(c2fb_c_int, &HFEULL)))))))) Then
                c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                local1 = c2fb_temp_0
                c2fb_temp_1 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_1
                Goto c2fb_flow_0
            End If
            fts3GetDeltaPosition(CPtr(ZString Ptr Ptr, @(local0)), CPtr(c2fb_int64 Ptr, @(local1)))
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_2 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_3 = Cast(c2fb_int64, local1)
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(ZString Ptr Ptr, @((*arg0)))
        c2fb_temp_5 = local0
        (*c2fb_temp_4) = c2fb_temp_5
    End If
End Sub
Private Function fts3SnippetNextCandidate CDecl Alias "fts3SnippetNextCandidate" (ByVal arg0 As c2fb_source_record_231 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local1 As c2fb_source_record_232 Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As c2fb_source_record_232 Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local5 As c2fb_source_record_232 Ptr

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg0->iCurrent < Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->iCurrent))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local0 < arg0->nPhrase))))
            local1 = CPtr(c2fb_source_record_232 Ptr, @(CPtr(c2fb_source_record_232 Ptr, CPtr(c2fb_source_record_232 Ptr, arg0->aPhrase))[local0]))
            fts3SnippetAdvance(CPtr(ZString Ptr Ptr, @(local1->pHead)), CPtr(c2fb_int64 Ptr, @(local1->iHead)), arg0->nSnippet)
        c2fb_flow_1:
            c2fb_temp_3 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
    Else
        ' C automatic storage declaration
        local3 = Cast(c2fb_c_int, &H7FFFFFFFULL)
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((local0 < arg0->nPhrase))))
            local4 = CPtr(c2fb_source_record_232 Ptr, @(CPtr(c2fb_source_record_232 Ptr, CPtr(c2fb_source_record_232 Ptr, arg0->aPhrase))[local0]))
            If (-Cast(c2fb_c_int, (((local4->pHead <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4->iHead < Cast(c2fb_int64, local3))))) <> 0))))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, local4->iHead)
                local3 = c2fb_temp_6
            End If
        c2fb_flow_3:
            c2fb_temp_5 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &H7FFFFFFFULL))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
        ' C unused-parameter annotation
        c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(arg0->iCurrent))
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local3 - arg0->nSnippet)) + Cast(c2fb_c_int, 1ULL))))
        local2 = c2fb_temp_7
        c2fb_temp_9 = Cast(c2fb_c_int, c2fb_temp_7)
        (*c2fb_temp_8) = c2fb_temp_9
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_10
        While (-Cast(c2fb_c_int, ((local0 < arg0->nPhrase))))
            local5 = CPtr(c2fb_source_record_232 Ptr, @(CPtr(c2fb_source_record_232 Ptr, CPtr(c2fb_source_record_232 Ptr, arg0->aPhrase))[local0]))
            fts3SnippetAdvance(CPtr(ZString Ptr Ptr, @(local5->pHead)), CPtr(c2fb_int64 Ptr, @(local5->iHead)), Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))
            fts3SnippetAdvance(CPtr(ZString Ptr Ptr, @(local5->pTail)), CPtr(c2fb_int64 Ptr, @(local5->iTail)), local2)
        c2fb_flow_5:
            c2fb_temp_11 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
        Wend
        c2fb_flow_4:
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts3SnippetDetails CDecl Alias "fts3SnippetDetails" (ByVal arg0 As c2fb_source_record_231 Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_uint64 Ptr, ByVal arg5 As c2fb_uint64 Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_uint64
    Dim local4 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As c2fb_source_record_232 Ptr
    Dim local6 As ZString Ptr
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_uint64
    Dim local10 As c2fb_uint64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_uint64
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_uint64
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_uint64 Ptr
    Dim c2fb_temp_13 As c2fb_uint64
    Dim c2fb_temp_14 As c2fb_uint64 Ptr
    Dim c2fb_temp_15 As c2fb_uint64

    local0 = arg0->iCurrent
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local2 < arg0->nPhrase))))
        local5 = CPtr(c2fb_source_record_232 Ptr, @(CPtr(c2fb_source_record_232 Ptr, CPtr(c2fb_source_record_232 Ptr, arg0->aPhrase))[local2]))
        If local5->pTail Then
            local6 = local5->pTail
            local7 = local5->iTail
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 < Cast(c2fb_int64, (Cast(c2fb_c_int, (local0 + arg0->nSnippet)))))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 >= Cast(c2fb_int64, local0))))) <> 0)))))
                ' C automatic storage declaration
                local9 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)) Shl (Cast(c2fb_c_int, (local2 Mod Cast(c2fb_c_int, 64ULL))))))
                local10 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)) Shl (Cast(c2fb_int64, (local7 - Cast(c2fb_int64, local0))))))
                ' C unused-parameter annotation
                ' C unused-parameter annotation
                If Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local3 Or arg1))) And local9)) Then
                    c2fb_temp_2 = local1
                    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                Else
                    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1000ULL))))
                    local1 = c2fb_temp_3
                End If
                c2fb_temp_4 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local3 Or local9)))
                local3 = c2fb_temp_4
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local8 = c2fb_temp_5
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 < local5->nToken)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 < arg0->nSnippet)))) <> 0)))))
                    c2fb_temp_7 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local4 Or (Cast(c2fb_uint64, (local10 Shr local8))))))
                    local4 = c2fb_temp_7
                c2fb_flow_5:
                    c2fb_temp_6 = local8
                    local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
                Wend
                c2fb_flow_4:
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local6))) And Cast(c2fb_c_int, &H0FEULL)))))))) Then
                    Goto c2fb_flow_2
                End If
                fts3GetDeltaPosition(CPtr(ZString Ptr Ptr, @(local6)), CPtr(c2fb_int64 Ptr, @(local7)))
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_9 = Cast(c2fb_c_int, local0)
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_11 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(c2fb_uint64 Ptr, @((*arg4)))
    c2fb_temp_13 = Cast(c2fb_uint64, local3)
    (*c2fb_temp_12) = c2fb_temp_13
    c2fb_temp_14 = CPtr(c2fb_uint64 Ptr, @((*arg5)))
    c2fb_temp_15 = Cast(c2fb_uint64, local4)
    (*c2fb_temp_14) = c2fb_temp_15
End Sub
' c2fb skipped fts3SnippetFindPositions: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3SnippetFindPositions: assignment parser stopped at byte 33 (pPhrase->nToken = pExpr->pPhrase->nToken): ->nToken
' c2fb skipped fts3BestSnippet: requires unconverted C function fts3ExprLoadDoclists
Private Function fts3StringAppend CDecl Alias "fts3StringAppend" (ByVal arg0 As c2fb_source_record_235 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local0 As c2fb_int64
    Dim local1 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Byte Ptr
    Dim c2fb_temp_9 As Byte

    If (-Cast(c2fb_c_int, ((arg2 < Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(arg1)))
        arg2 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, arg0->n) + Cast(c2fb_int64, arg2))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))) >= Cast(c2fb_int64, arg0->nAlloc))))) Then
        local0 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, arg0->nAlloc) + Cast(c2fb_int64, arg2))) + Cast(c2fb_int64, Cast(c2fb_c_int, 100ULL))))
        local1 = CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->z), local0))
        If (-Cast(c2fb_c_int, (local1 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @(arg0->z))
        c2fb_temp_2 = local1
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg0->nAlloc))
        c2fb_temp_4 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    ' C unused-parameter annotation
    c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->z)[arg0->n]))), CPtr(Const Any Ptr, arg1), arg2))
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg0->n))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_6) + arg2)))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->z)[arg0->n]))
    c2fb_temp_9 = Cast(Byte, Cast(c2fb_c_int, 0))
    (*c2fb_temp_8) = c2fb_temp_9
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped fts3SnippetShift: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3SnippetShift: assignment parser stopped at byte 10 (rc = pMod->xNext(pC, &ZDUMMY, &DUMMY1, &DUMMY2, &DUMMY3, &iCurrent)): ->xNext(pC, &ZDUMMY, &DUMMY1, &DUMMY2, &DUMMY3, &iCurrent)
' c2fb skipped fts3SnippetText: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3SnippetText: assignment parser stopped at byte 10 (rc = pMod->xNext(pC, &ZDUMMY, &DUMMY1, &iBegin, &iFin, &iCurrent)): ->xNext(pC, &ZDUMMY, &DUMMY1, &iBegin, &iFin, &iCurrent)
Private Function fts3ColumnlistCount CDecl Alias "fts3ColumnlistCount" (ByVal arg0 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As ZString Ptr
    Dim local1 As Byte
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr

    local0 = (*arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    While Cast(c2fb_c_int, (Cast(c2fb_c_int, &HFEULL) And (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, local0))) Or Cast(c2fb_c_int, local1))))))
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(Byte Ptr, c2fb_temp_0))) And Cast(c2fb_c_int, &H80ULL))))
        local1 = c2fb_temp_1
        If (-Cast(c2fb_c_int, (local1 = 0))) Then
            c2fb_temp_2 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_4 = local0
    (*c2fb_temp_3) = c2fb_temp_4
    Return local2
End Function
' c2fb skipped fts3ExprLHits: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: fts3ExprLHits: expression parser stopped at byte 8 in (pPhrase->doclist.pList): ->doclist.pList
' c2fb skipped fts3ExprLHitGather: requires unconverted C function fts3ExprLHits
Private Function fts3ExprGlobalHitsCb CDecl Alias "fts3ExprGlobalHitsCb" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_source_record_234 Ptr

    local0 = CPtr(c2fb_source_record_234 Ptr, arg2)
    Return sqlite3Fts3EvalPhraseStats(local0->pCursor, arg0, CPtr(c2fb_c_uint Ptr, @(local0->aMatchinfo[Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 3ULL) * arg1)) * local0->nCol))])))
End Function
Private Function fts3ExprLocalHitsCb CDecl Alias "fts3ExprLocalHitsCb" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_234 Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_uint Ptr
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As c2fb_c_uint Ptr
    Dim c2fb_temp_6 As c2fb_c_uint

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(c2fb_source_record_234 Ptr, arg2)
    local2 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 * local1->nCol)) * Cast(c2fb_c_int, 3ULL)))
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < local1->nCol)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, sqlite3Fts3EvalPhrasePoslist(local1->pCursor, arg0, local3, CPtr(ZString Ptr Ptr, @(local4))))
        local0 = c2fb_temp_2
        If local4 Then
            c2fb_temp_3 = CPtr(c2fb_c_uint Ptr, @(local1->aMatchinfo[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 3ULL)))))]))
            c2fb_temp_4 = Cast(c2fb_c_uint, fts3ColumnlistCount(CPtr(ZString Ptr Ptr, @(local4))))
            (*c2fb_temp_3) = c2fb_temp_4
        Else
            c2fb_temp_5 = CPtr(c2fb_c_uint Ptr, @(local1->aMatchinfo[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 3ULL)))))]))
            c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_5) = c2fb_temp_6
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Function fts3MatchinfoCheck CDecl Alias "fts3MatchinfoCheck" (ByVal arg0 As c2fb_source_record_223 Ptr, ByVal arg1 As Byte, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 112)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 99)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 110))))) <> 0) AndAlso (arg0->bFts4 <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 97))))) <> 0) AndAlso (arg0->bFts4 <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 108))))) <> 0) AndAlso (arg0->bHasDocsize <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 115)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 120)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 121)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 98)))))) <> 0))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    sqlite3Fts3ErrMsg(arg2, StrPtr(!"unrecognized matchinfo request: %c"), arg1)
    Return Cast(c2fb_c_int, 1ULL)
End Function
Private Function fts3MatchinfoSize CDecl Alias "fts3MatchinfoSize" (ByVal arg0 As c2fb_source_record_234 Ptr, ByVal arg1 As Byte) As c2fb_int64
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_int64

    ' C automatic storage declaration
    Select Case arg1
        Case Cast(c2fb_c_int, 110), Cast(c2fb_c_int, 112), Cast(c2fb_c_int, 99)
            c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))
            local0 = c2fb_temp_0
        Case Cast(c2fb_c_int, 97), Cast(c2fb_c_int, 108), Cast(c2fb_c_int, 115)
            c2fb_temp_1 = Cast(c2fb_int64, arg0->nCol)
            local0 = c2fb_temp_1
        Case Cast(c2fb_c_int, 121)
            c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, arg0->nCol) * Cast(c2fb_int64, arg0->nPhrase))))
            local0 = c2fb_temp_2
        Case Cast(c2fb_c_int, 98)
            c2fb_temp_3 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, arg0->nPhrase) * Cast(c2fb_int64, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->nCol + Cast(c2fb_c_int, 31ULL)))) \ Cast(c2fb_c_int, 32ULL))))))))
            local0 = c2fb_temp_3
        Case Else
            ' C unused-parameter annotation
            c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, arg0->nCol) * Cast(c2fb_int64, arg0->nPhrase))) * Cast(c2fb_int64, Cast(c2fb_c_int, 3ULL)))))
            local0 = c2fb_temp_4
    End Select
    c2fb_flow_0:
    Return local0
End Function
Private Function fts3MatchinfoSelectDoctotal CDecl Alias "fts3MatchinfoSelectDoctotal" (ByVal arg0 As c2fb_source_record_223 Ptr, ByVal arg1 As SqliteVdbe Ptr Ptr, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As SqliteVdbe Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteVdbe Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As c2fb_int64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As Const ZString Ptr Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As Const ZString Ptr Ptr
    Dim c2fb_temp_10 As Const ZString Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((*arg1) = 0))) Then
        local5 = sqlite3Fts3SelectDoctotal(arg0, arg1)
        If (-Cast(c2fb_c_int, ((local5 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local5
        End If
    End If
    c2fb_temp_0 = (*arg1)
    local0 = c2fb_temp_0
    ' C unused-parameter annotation
    c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_bytes_(local0, Cast(c2fb_c_int, &O0ULL)))
    local4 = c2fb_temp_1
    c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob_(local0, Cast(c2fb_c_int, &O0ULL))))
    local1 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    c2fb_temp_3 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local1) + local4))
    local2 = c2fb_temp_3
    c2fb_temp_4 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local1) + sqlite3Fts3GetVarintBounded(local1, local2, CPtr(c2fb_int64 Ptr, @(local3)))))
    local1 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 <= Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 > local2)))) <> 0))))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    c2fb_temp_5 = CPtr(c2fb_int64 Ptr, @((*arg2)))
    c2fb_temp_6 = Cast(c2fb_int64, local3)
    (*c2fb_temp_5) = c2fb_temp_6
    If arg3 Then
        c2fb_temp_7 = CPtr(Const ZString Ptr Ptr, @((*arg3)))
        c2fb_temp_8 = local1
        (*c2fb_temp_7) = c2fb_temp_8
    End If
    If arg4 Then
        c2fb_temp_9 = CPtr(Const ZString Ptr Ptr, @((*arg4)))
        c2fb_temp_10 = local2
        (*c2fb_temp_9) = c2fb_temp_10
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3MatchinfoLcsCb CDecl Alias "fts3MatchinfoLcsCb" (ByVal arg0 As c2fb_source_record_227 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As c2fb_source_record_236 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_227 Ptr Ptr
    Dim c2fb_temp_1 As c2fb_source_record_227 Ptr

    local0 = CPtr(c2fb_source_record_236 Ptr, arg2)
    c2fb_temp_0 = CPtr(c2fb_source_record_227 Ptr Ptr, @(local0[arg1].pExpr))
    c2fb_temp_1 = arg0
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3LcsIteratorAdvance CDecl Alias "fts3LcsIteratorAdvance" (ByVal arg0 As c2fb_source_record_236 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    If ((-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL)))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_0 = arg0->pRead
    local0 = c2fb_temp_0
    c2fb_temp_1 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local0) + sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local0), CPtr(c2fb_int64 Ptr, @(local1)))))
    local0 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) <> 0))))) Then
        c2fb_temp_2 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local2 = c2fb_temp_3
    Else
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->iPos))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_4) + Cast(c2fb_c_int, (Cast(c2fb_int64, (local1 - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))))))
        (*c2fb_temp_4) = c2fb_temp_5
    End If
    c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(arg0->pRead))
    c2fb_temp_7 = local0
    (*c2fb_temp_6) = c2fb_temp_7
    Return local2
End Function
' c2fb skipped fts3MatchinfoLcs: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3MatchinfoLcs: assignment parser stopped at byte 32 (nToken -= pIter->pExpr->pPhrase->nToken): ->nToken
' c2fb skipped fts3MatchinfoValues: requires unconverted C function fts3ExprLoadDoclists
' c2fb skipped fts3GetMatchinfo: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: fts3GetMatchinfo: expression parser stopped at byte 42 in (pCsr->pMIBuffer && strcmp(pCsr->pMIBuffer->zMatchinfo, zArg)): ->zMatchinfo, zArg)
' c2fb skipped sqlite3Fts3Snippet: requires unconverted C function fts3BestSnippet
' c2fb skipped fts3ExprTermOffsetInit: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: fts3ExprTermOffsetInit: assignment parser stopped at byte 23 (nTerm = pExpr->pPhrase->nToken): ->nToken
' c2fb skipped fts3ExprRestartIfCb: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: fts3ExprRestartIfCb: expression parser stopped at byte 33 in (pExpr->pPhrase && pExpr->pPhrase->bIncr): ->bIncr
' c2fb skipped sqlite3Fts3Offsets: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3Fts3Offsets: assignment parser stopped at byte 10 (rc = pMod->xNext(pC, &ZDUMMY, &NDUMMY, &iStart, &iEnd, &iCurrent)): ->xNext(pC, &ZDUMMY, &NDUMMY, &iStart, &iEnd, &iCurrent)
' c2fb skipped sqlite3Fts3Matchinfo: requires unconverted C function fts3GetMatchinfo
#endif

/' end of fts3_candidates/sqlite3_bulk_fts3_snippet_candidates.bas '/
