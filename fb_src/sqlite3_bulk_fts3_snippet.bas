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

    File: sqlite3_bulk_fts3_snippet.bas

    Purpose:

        Implement the FTS3 snippet, offsets, and matchinfo SQL functions.

    Responsibilities:

        - Select text fragments that cover matched query phrases.
        - Translate phrase position lists into byte offsets.
        - Build per-row and database-wide matchinfo values.
        - Allocate and release the shared matchinfo buffer through SQLite.

    This file intentionally does NOT contain:

        - FTS3 query parsing, segment traversal, or module registration.
        - FTS3 test support or test-only SQL commands.
'/
#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"
#include once "sqlite3_fts3_tokenizer_types.bi"
#include once "sqlite3_fts3_write_types.bi"
#include once "sqlite3_fts3_expr_types.bi"
#include once "sqlite3_fts3_snippet_types.bi"
#include once "fts3_candidates/sqlite3_fts3_snippet_api.bi"

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

Declare Function sqlite3Fts3ExprIterate CDecl Alias "sqlite3Fts3ExprIterate" ( ByVal pExpression As SqliteFts3Expr Ptr, ByVal xVisit As SqliteFts3ExprIterateProc, ByVal pContext As Any Ptr ) As SQLITE_C_INT
Declare Sub sqlite3Fts3MIBufferFree CDecl Alias "sqlite3Fts3MIBufferFree" ( ByVal arg0 As Fts3MatchinfoBuffer Ptr )

Type c2fb_callback_70 As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_157 As Function CDecl(ByVal arg0 As Fts3TokenizerCursor Ptr) As c2fb_c_int
Type c2fb_callback_158 As Function CDecl(ByVal arg0 As Fts3TokenizerCursor Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_175 As Function CDecl(ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int

Declare Function fts3MIBufferNew CDecl Alias "fts3MIBufferNew" (ByVal arg0 As c2fb_int64, ByVal arg1 As Const ZString Ptr) As Fts3MatchinfoBuffer Ptr
Declare Sub fts3MIBufferFree CDecl Alias "fts3MIBufferFree" (ByVal arg0 As Any Ptr)
Declare Function fts3MIBufferAlloc CDecl Alias "fts3MIBufferAlloc" (ByVal arg0 As Fts3MatchinfoBuffer Ptr, ByVal arg1 As c2fb_c_uint Ptr Ptr) As Sub CDecl(ByVal arg0 As Any Ptr)
Declare Sub fts3MIBufferSetGlobal CDecl Alias "fts3MIBufferSetGlobal" (ByVal arg0 As Fts3MatchinfoBuffer Ptr)
Declare Sub fts3GetDeltaPosition CDecl Alias "fts3GetDeltaPosition" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr)
Declare Function fts3ExprIterate2 CDecl Alias "fts3ExprIterate2" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_callback_175, ByVal arg3 As Any Ptr) As c2fb_c_int
Declare Function fts3ExprLoadDoclistsCb CDecl Alias "fts3ExprLoadDoclistsCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3ExprLoadDoclists CDecl Alias "fts3ExprLoadDoclists" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts3ExprPhraseCountCb CDecl Alias "fts3ExprPhraseCountCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3ExprPhraseCount CDecl Alias "fts3ExprPhraseCount" (ByVal arg0 As SqliteFts3Expr Ptr) As c2fb_c_int
Declare Sub fts3SnippetAdvance CDecl Alias "fts3SnippetAdvance" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_c_int)
Declare Function fts3SnippetNextCandidate CDecl Alias "fts3SnippetNextCandidate" (ByVal arg0 As SqliteFts3SnippetIter Ptr) As c2fb_c_int
Declare Sub fts3SnippetDetails CDecl Alias "fts3SnippetDetails" (ByVal arg0 As SqliteFts3SnippetIter Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_uint64 Ptr, ByVal arg5 As c2fb_uint64 Ptr)
Declare Function fts3SnippetFindPositions CDecl Alias "fts3SnippetFindPositions" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3BestSnippet CDecl Alias "fts3BestSnippet" (ByVal arg0 As c2fb_c_int, ByVal arg1 As SqliteFts3Cursor Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_uint64, ByVal arg4 As c2fb_uint64 Ptr, ByVal arg5 As SqliteFts3SnippetFragment Ptr, ByVal arg6 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts3StringAppend CDecl Alias "fts3StringAppend" (ByVal arg0 As SqliteFts3StrBuffer Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts3SnippetShift CDecl Alias "fts3SnippetShift" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As c2fb_uint64 Ptr) As c2fb_c_int
Declare Function fts3SnippetText CDecl Alias "fts3SnippetText" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As SqliteFts3SnippetFragment Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As Const ZString Ptr, ByVal arg7 As Const ZString Ptr, ByVal arg8 As SqliteFts3StrBuffer Ptr) As c2fb_c_int
Declare Function fts3ColumnlistCount CDecl Alias "fts3ColumnlistCount" (ByVal arg0 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3ExprLHits CDecl Alias "fts3ExprLHits" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As SqliteFts3MatchInfo Ptr) As c2fb_c_int
Declare Function fts3ExprLHitGather CDecl Alias "fts3ExprLHitGather" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As SqliteFts3MatchInfo Ptr) As c2fb_c_int
Declare Function fts3ExprGlobalHitsCb CDecl Alias "fts3ExprGlobalHitsCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3ExprLocalHitsCb CDecl Alias "fts3ExprLocalHitsCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3MatchinfoCheck CDecl Alias "fts3MatchinfoCheck" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As Byte, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3MatchinfoSize CDecl Alias "fts3MatchinfoSize" (ByVal arg0 As SqliteFts3MatchInfo Ptr, ByVal arg1 As Byte) As c2fb_int64
Declare Function fts3MatchinfoSelectDoctotal CDecl Alias "fts3MatchinfoSelectDoctotal" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As Any Ptr Ptr, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3MatchinfoLcsCb CDecl Alias "fts3MatchinfoLcsCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3LcsIteratorAdvance CDecl Alias "fts3LcsIteratorAdvance" (ByVal arg0 As SqliteFts3LcsIterator Ptr) As c2fb_c_int
Declare Function fts3MatchinfoLcs CDecl Alias "fts3MatchinfoLcs" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As SqliteFts3MatchInfo Ptr) As c2fb_c_int
Declare Function fts3MatchinfoValues CDecl Alias "fts3MatchinfoValues" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteFts3MatchInfo Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
Declare Sub fts3GetMatchinfo CDecl Alias "fts3GetMatchinfo" (ByVal arg0 As Any Ptr, ByVal arg1 As SqliteFts3Cursor Ptr, ByVal arg2 As Const ZString Ptr)
Declare Sub sqlite3Fts3Snippet CDecl Alias "sqlite3Fts3Snippet" (ByVal arg0 As Any Ptr, ByVal arg1 As SqliteFts3Cursor Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int)
Declare Function fts3ExprTermOffsetInit CDecl Alias "fts3ExprTermOffsetInit" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts3ExprRestartIfCb CDecl Alias "fts3ExprRestartIfCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Sub sqlite3Fts3Offsets CDecl Alias "sqlite3Fts3Offsets" (ByVal arg0 As Any Ptr, ByVal arg1 As SqliteFts3Cursor Ptr)
Declare Sub sqlite3Fts3Matchinfo CDecl Alias "sqlite3Fts3Matchinfo" (ByVal arg0 As Any Ptr, ByVal arg1 As SqliteFts3Cursor Ptr, ByVal arg2 As Const ZString Ptr)
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strcmp CDecl Alias "strcmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3Fts3SelectDoctotal CDecl Alias "sqlite3Fts3SelectDoctotal" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As Any Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3SelectDocsize CDecl Alias "sqlite3Fts3SelectDocsize" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As Any Ptr Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3SegmentsClose CDecl Alias "sqlite3Fts3SegmentsClose" (ByVal arg0 As SqliteFts3Table Ptr)
Declare Sub c2fb_external_sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Function c2fb_external_sqlite3Fts3GetVarint CDecl Alias "sqlite3Fts3GetVarint" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3GetVarint32 CDecl Alias "sqlite3Fts3GetVarint32" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3EvalPhraseStats CDecl Alias "sqlite3Fts3EvalPhraseStats" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As SqliteFts3Expr Ptr, ByVal arg2 As c2fb_c_uint Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3EvalTestDeferred CDecl Alias "sqlite3Fts3EvalTestDeferred" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3MallocZero CDecl Alias "sqlite3Fts3MallocZero" (ByVal arg0 As c2fb_int64) As Any Ptr
Declare Function c2fb_external_sqlite3Fts3OpenTokenizer CDecl Alias "sqlite3Fts3OpenTokenizer" (ByVal arg0 As Fts3Tokenizer Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Fts3TokenizerCursor Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3EvalPhrasePoslist CDecl Alias "sqlite3Fts3EvalPhrasePoslist" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As SqliteFts3Expr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3MsrCancel CDecl Alias "sqlite3Fts3MsrCancel" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As SqliteFts3Expr Ptr) As c2fb_c_int
Private Function fts3MIBufferNew CDecl Alias "fts3MIBufferNew" (ByVal arg0 As c2fb_int64, ByVal arg1 As Const ZString Ptr) As Fts3MatchinfoBuffer Ptr
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 135
    Dim local0 As Fts3MatchinfoBuffer Ptr
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As Fts3MatchinfoBuffer Ptr
    Dim c2fb_temp_1 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As SQLITE_C_INT Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As UByte

    ' C automatic storage declaration
    local1 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint))) * Cast(c2fb_uint64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)) * Cast(c2fb_int64, arg0))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, OffsetOf(Fts3MatchinfoBuffer, aMI(0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL)) + Cast(c2fb_c_int, 1ULL)))) \ Cast(c2fb_c_int, 2ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_uint64))))))))))
    local2 = c2fb_crt_strlen(arg1)
    c2fb_temp_0 = CPtr(Fts3MatchinfoBuffer Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts3MallocZero(Cast(c2fb_int64, (Cast(c2fb_int64, (local1 + local2)) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
    local0 = c2fb_temp_0
    If local0 Then
        c2fb_temp_1 = CPtr(SQLITE_C_UINT Ptr, @(local0->aMI(Cast(c2fb_c_int, &O0ULL))))
        c2fb_temp_2 = Cast(c2fb_c_uint, (CPtr(UByte Ptr, CPtr(UByte Ptr, (CPtr(c2fb_c_uint Ptr, @(local0->aMI(Cast(c2fb_c_int, 1ULL))))))) - CPtr(UByte Ptr, CPtr(UByte Ptr, local0))))
        (*c2fb_temp_1) = Cast(SQLITE_C_UINT, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_uint, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(SQLITE_C_UINT Ptr, @(local0->aMI(Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)) + arg0)))))
        c2fb_temp_4 = Cast(c2fb_c_uint, Cast(c2fb_uint64, (Cast(c2fb_uint64, local0->aMI(Cast(c2fb_c_int, &O0ULL))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0) + Cast(c2fb_c_int, 1ULL))))))))))
        (*c2fb_temp_3) = Cast(SQLITE_C_UINT, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_uint, (*c2fb_temp_3))
        c2fb_temp_5 = CPtr(SQLITE_C_INT Ptr, @(local0->nElem))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, arg0))
        (*c2fb_temp_5) = Cast(SQLITE_C_INT, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(ZString Ptr Ptr, @(local0->zMatchinfo))
        c2fb_temp_8 = CPtr(ZString Ptr, (CPtr(Byte Ptr, (CPtr(ZString Ptr, local0))) + local1))
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0->zMatchinfo), CPtr(Const Any Ptr, arg1), Cast(c2fb_int64, (local2 + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))
        c2fb_temp_10 = CPtr(UByte Ptr, @(local0->aRef(Cast(c2fb_c_int, &O0ULL))))
        c2fb_temp_11 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_10) = c2fb_temp_11
    End If
    Return local0
End Function
Private Sub fts3MIBufferFree CDecl Alias "fts3MIBufferFree" (ByVal arg0 As Any Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 154
    Dim local0 As Fts3MatchinfoBuffer Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    local0 = CPtr(Fts3MatchinfoBuffer Ptr, (CPtr(UByte Ptr, (CPtr(UByte Ptr, arg0) - (CPtr(c2fb_c_uint Ptr, arg0))[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))]))))
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_c_uint Ptr, arg0) = CPtr(c2fb_c_uint Ptr, @(local0->aMI(Cast(c2fb_c_int, 1ULL)))))))) Then
        c2fb_temp_0 = CPtr(UByte Ptr, @(local0->aRef(Cast(c2fb_c_int, 1ULL))))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
    Else
        c2fb_temp_2 = CPtr(UByte Ptr, @(local0->aRef(Cast(c2fb_c_int, 2ULL))))
        c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = c2fb_temp_3
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->aRef(Cast(c2fb_c_int, &O0ULL))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->aRef(Cast(c2fb_c_int, 1ULL))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->aRef(Cast(c2fb_c_int, 2ULL))) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Function fts3MIBufferAlloc CDecl Alias "fts3MIBufferAlloc" (ByVal arg0 As Fts3MatchinfoBuffer Ptr, ByVal arg1 As c2fb_c_uint Ptr Ptr) As Sub CDecl(ByVal arg0 As Any Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 171
    Dim local0 As c2fb_callback_70
    Dim local1 As c2fb_c_uint Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As c2fb_c_uint Ptr
    Dim c2fb_temp_3 As c2fb_callback_70
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As c2fb_c_uint Ptr
    Dim c2fb_temp_7 As c2fb_callback_70
    Dim c2fb_temp_8 As c2fb_c_uint Ptr
    Dim c2fb_temp_9 As c2fb_callback_70
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As c2fb_c_uint Ptr Ptr
    Dim c2fb_temp_12 As c2fb_c_uint Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->aRef(Cast(c2fb_c_int, 1ULL))) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(UByte Ptr, @(arg0->aRef(Cast(c2fb_c_int, 1ULL))))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_c_uint Ptr, @(arg0->aMI(Cast(c2fb_c_int, 1ULL))))
        local1 = c2fb_temp_2
        c2fb_temp_3 = ProcPtr(fts3MIBufferFree)
        local0 = c2fb_temp_3
    Else
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->aRef(Cast(c2fb_c_int, 2ULL))) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_4 = CPtr(UByte Ptr, @(arg0->aRef(Cast(c2fb_c_int, 2ULL))))
            c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_6 = CPtr(c2fb_c_uint Ptr, @(arg0->aMI(Cast(c2fb_c_int, (arg0->nElem + Cast(c2fb_c_int, 2ULL))))))
            local1 = c2fb_temp_6
            c2fb_temp_7 = ProcPtr(fts3MIBufferFree)
            local0 = c2fb_temp_7
        Else
            c2fb_temp_8 = CPtr(c2fb_c_uint Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0->nElem) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint))))))))
            local1 = c2fb_temp_8
            If local1 Then
                c2fb_temp_9 = ProcPtr(sqlite3_free)
                local0 = c2fb_temp_9
                If arg0->bGlobal Then
                    c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1), CPtr(Const Any Ptr, CPtr(c2fb_c_uint Ptr, @(arg0->aMI(Cast(c2fb_c_int, 1ULL))))), Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0->nElem) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))))
                End If
            End If
        End If
    End If
    c2fb_temp_11 = CPtr(c2fb_c_uint Ptr Ptr, @((*arg1)))
    c2fb_temp_12 = local1
    (*c2fb_temp_11) = c2fb_temp_12
    Return local0
End Function
Private Sub fts3MIBufferSetGlobal CDecl Alias "fts3MIBufferSetGlobal" (ByVal arg0 As Fts3MatchinfoBuffer Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 196
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr

    c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg0->bGlobal))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_c_uint Ptr, @(arg0->aMI(Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + arg0->nElem)))))), CPtr(Const Any Ptr, CPtr(c2fb_c_uint Ptr, @(arg0->aMI(Cast(c2fb_c_int, 1ULL))))), Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0->nElem) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))))
End Sub
' c2fb skipped sqlite3Fts3MIBufferFree: FreeBASIC body already exists
Private Sub fts3GetDeltaPosition CDecl Alias "fts3GetDeltaPosition" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 239
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
        c2fb_temp_2 = c2fb_external_sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, (*arg0)), CPtr(c2fb_c_int Ptr, @(local0)))
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
Private Function fts3ExprIterate2 CDecl Alias "fts3ExprIterate2" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_callback_175, ByVal arg3 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 248
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
' c2fb skipped sqlite3Fts3ExprIterate: FreeBASIC body already exists
Private Function fts3ExprLoadDoclistsCb CDecl Alias "fts3ExprLoadDoclistsCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 294
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteFts3Phrase Ptr
    Dim local2 As SqliteFts3LoadDoclistCtx Ptr
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As SQLITE_C_INT Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = arg0->pPhrase
    local2 = CPtr(SqliteFts3LoadDoclistCtx Ptr, arg2)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(local2->nPhrase))
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    c2fb_temp_2 = CPtr(SQLITE_C_INT Ptr, @(local2->nToken))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_2)) + local1->nToken)))
    (*c2fb_temp_2) = Cast(SQLITE_C_INT, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    Return local0
End Function
Private Function fts3ExprLoadDoclists CDecl Alias "fts3ExprLoadDoclists" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 317
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteFts3LoadDoclistCtx
    Dim c2fb_temp_0 As SqliteFts3Cursor Ptr Ptr
    Dim c2fb_temp_1 As SqliteFts3Cursor Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Type<SqliteFts3LoadDoclistCtx>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    c2fb_temp_0 = CPtr(SqliteFts3Cursor Ptr Ptr, @(local1.pCsr))
    c2fb_temp_1 = arg0
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, sqlite3Fts3ExprIterate(CPtr(SqliteFts3Expr Ptr, arg0->pExpr), ProcPtr(fts3ExprLoadDoclistsCb), CPtr(Any Ptr, CPtr(SqliteFts3LoadDoclistCtx Ptr, @(local1)))))
    local0 = c2fb_temp_2
    If arg1 Then
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_4 = Cast(c2fb_c_int, local1.nPhrase)
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    If arg2 Then
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_6 = Cast(c2fb_c_int, local1.nToken)
        (*c2fb_temp_5) = c2fb_temp_6
    End If
    Return local0
End Function
Private Function fts3ExprPhraseCountCb CDecl Alias "fts3ExprPhraseCountCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 331
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As SQLITE_C_INT Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(((*CPtr(c2fb_c_int Ptr, arg2)))))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    c2fb_temp_2 = CPtr(SQLITE_C_INT Ptr, @(arg0->iPhrase))
    c2fb_temp_3 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_2) = Cast(SQLITE_C_INT, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3ExprPhraseCount CDecl Alias "fts3ExprPhraseCount" (ByVal arg0 As SqliteFts3Expr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 336
    Dim local0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    sqlite3Fts3ExprIterate(arg0, ProcPtr(fts3ExprPhraseCountCb), CPtr(Any Ptr, CPtr(c2fb_c_int Ptr, @(local0))))
    Return local0
End Function
Private Sub fts3SnippetAdvance CDecl Alias "fts3SnippetAdvance" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 347
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
Private Function fts3SnippetNextCandidate CDecl Alias "fts3SnippetNextCandidate" (ByVal arg0 As SqliteFts3SnippetIter Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 369
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local1 As SqliteFts3SnippetPhrase Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As SqliteFts3SnippetPhrase Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As SQLITE_C_INT Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local5 As SqliteFts3SnippetPhrase Ptr

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg0->iCurrent < Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg0->iCurrent))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local0 < arg0->nPhrase))))
            local1 = CPtr(SqliteFts3SnippetPhrase Ptr, @(arg0->aPhrase[local0]))
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
            local4 = CPtr(SqliteFts3SnippetPhrase Ptr, @(arg0->aPhrase[local0]))
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
        c2fb_temp_8 = CPtr(SQLITE_C_INT Ptr, @(arg0->iCurrent))
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local3 - arg0->nSnippet)) + Cast(c2fb_c_int, 1ULL))))
        local2 = c2fb_temp_7
        c2fb_temp_9 = Cast(c2fb_c_int, c2fb_temp_7)
        (*c2fb_temp_8) = Cast(SQLITE_C_INT, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_10
        While (-Cast(c2fb_c_int, ((local0 < arg0->nPhrase))))
            local5 = CPtr(SqliteFts3SnippetPhrase Ptr, @(arg0->aPhrase[local0]))
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
Private Sub fts3SnippetDetails CDecl Alias "fts3SnippetDetails" (ByVal arg0 As SqliteFts3SnippetIter Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_uint64 Ptr, ByVal arg5 As c2fb_uint64 Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 416
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_uint64
    Dim local4 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As SqliteFts3SnippetPhrase Ptr
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
        local5 = CPtr(SqliteFts3SnippetPhrase Ptr, @(arg0->aPhrase[local2]))
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
Private Function fts3SnippetFindPositions CDecl Alias "fts3SnippetFindPositions" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 471
    Dim local0 As SqliteFts3SnippetIter Ptr
    Dim local1 As SqliteFts3SnippetPhrase Ptr
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As sqlite3_int64 Ptr
    Dim c2fb_temp_11 As c2fb_int64
    Dim c2fb_temp_12 As sqlite3_int64 Ptr
    Dim c2fb_temp_13 As c2fb_int64

    local0 = CPtr(SqliteFts3SnippetIter Ptr, arg2)
    local1 = CPtr(SqliteFts3SnippetPhrase Ptr, @(local0->aPhrase[arg1]))
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(local1->nToken))
    c2fb_temp_1 = Cast(c2fb_c_int, arg0->pPhrase->nToken)
    (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3EvalPhrasePoslist(local0->pCsr, arg0, local0->iCol, CPtr(ZString Ptr Ptr, @(local2))))
    local3 = c2fb_temp_2
    ' C unused-parameter annotation
    If local2 Then
        local4 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_3 = CPtr(ZString Ptr Ptr, @(local1->pList))
        c2fb_temp_4 = local2
        (*c2fb_temp_3) = c2fb_temp_4
        fts3GetDeltaPosition(CPtr(ZString Ptr Ptr, @(local2)), CPtr(c2fb_int64 Ptr, @(local4)))
        If (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local3 = c2fb_temp_5
        Else
            c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(local1->pHead))
            c2fb_temp_7 = local2
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(ZString Ptr Ptr, @(local1->pTail))
            c2fb_temp_9 = local2
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(sqlite3_int64 Ptr, @(local1->iHead))
            c2fb_temp_11 = Cast(c2fb_int64, local4)
            (*c2fb_temp_10) = Cast(sqlite3_int64, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_int64, (*c2fb_temp_10))
            c2fb_temp_12 = CPtr(sqlite3_int64 Ptr, @(local1->iTail))
            c2fb_temp_13 = Cast(c2fb_int64, local4)
            (*c2fb_temp_12) = Cast(sqlite3_int64, c2fb_temp_13)
            c2fb_temp_13 = Cast(c2fb_int64, (*c2fb_temp_12))
        End If
    Else
        ' C unused-parameter annotation
    End If
    Return local3
End Function
Private Function fts3BestSnippet CDecl Alias "fts3BestSnippet" (ByVal arg0 As c2fb_c_int, ByVal arg1 As SqliteFts3Cursor Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_uint64, ByVal arg4 As c2fb_uint64 Ptr, ByVal arg5 As SqliteFts3SnippetFragment Ptr, ByVal arg6 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 516
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteFts3SnippetIter
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As SqliteFts3Expr Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As SqliteFts3SnippetPhrase Ptr Ptr
    Dim c2fb_temp_4 As SqliteFts3SnippetPhrase Ptr
    Dim c2fb_temp_5 As SqliteFts3Cursor Ptr Ptr
    Dim c2fb_temp_6 As SqliteFts3Cursor Ptr
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As SQLITE_C_INT Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As SQLITE_C_INT Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As SQLITE_C_INT Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_uint64 Ptr
    Dim c2fb_temp_20 As c2fb_uint64
    Dim c2fb_temp_21 As SQLITE_C_INT Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_uint64
    Dim local10 As c2fb_uint64
    Dim c2fb_temp_23 As SQLITE_C_INT Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As sqlite3_uint64 Ptr
    Dim c2fb_temp_26 As c2fb_uint64
    Dim c2fb_temp_27 As sqlite3_uint64 Ptr
    Dim c2fb_temp_28 As c2fb_uint64
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int Ptr
    Dim c2fb_temp_31 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    ' C automatic storage declaration
    local6 = CPtr(SqliteFts3Expr Ptr, arg1->pExpr)
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteFts3SnippetIter Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteFts3SnippetIter))))
    c2fb_temp_1 = Cast(c2fb_c_int, fts3ExprLoadDoclists(arg1, CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_c_int Ptr, 0)))
    local0 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local0
    End If
    c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteFts3SnippetPhrase))) * Cast(c2fb_uint64, local1))))
    local3 = c2fb_temp_2
    c2fb_temp_3 = CPtr(SqliteFts3SnippetPhrase Ptr Ptr, @(local2.aPhrase))
    c2fb_temp_4 = CPtr(SqliteFts3SnippetPhrase Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts3MallocZero(local3)))
    (*c2fb_temp_3) = c2fb_temp_4
    If (-Cast(c2fb_c_int, (local2.aPhrase = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_5 = CPtr(SqliteFts3Cursor Ptr Ptr, @(local2.pCsr))
    c2fb_temp_6 = arg1
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(local2.iCol))
    c2fb_temp_8 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_7) = Cast(SQLITE_C_INT, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    c2fb_temp_9 = CPtr(SQLITE_C_INT Ptr, @(local2.nSnippet))
    c2fb_temp_10 = Cast(c2fb_c_int, arg0)
    (*c2fb_temp_9) = Cast(SQLITE_C_INT, c2fb_temp_10)
    c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
    c2fb_temp_11 = CPtr(SQLITE_C_INT Ptr, @(local2.nPhrase))
    c2fb_temp_12 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_11) = Cast(SQLITE_C_INT, c2fb_temp_12)
    c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
    c2fb_temp_13 = CPtr(SQLITE_C_INT Ptr, @(local2.iCurrent))
    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_13) = Cast(SQLITE_C_INT, c2fb_temp_14)
    c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
    c2fb_temp_15 = Cast(c2fb_c_int, sqlite3Fts3ExprIterate(local6, ProcPtr(fts3SnippetFindPositions), CPtr(Any Ptr, CPtr(SqliteFts3SnippetIter Ptr, @(local2)))))
    local0 = c2fb_temp_15
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_16 = Cast(c2fb_c_int, sqlite3Fts3ExprIterate(local6, ProcPtr(fts3SnippetFindPositions), CPtr(Any Ptr, CPtr(SqliteFts3SnippetIter Ptr, @(local2)))))
        local0 = c2fb_temp_16
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local5 = c2fb_temp_17
        While (-Cast(c2fb_c_int, ((local5 < local1))))
            If local2.aPhrase[local5].pHead Then
                c2fb_temp_19 = CPtr(c2fb_uint64 Ptr, @((*arg4)))
                c2fb_temp_20 = Cast(c2fb_uint64, Cast(c2fb_uint64, ((*c2fb_temp_19) Or Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)) Shl (Cast(c2fb_c_int, (local5 Mod Cast(c2fb_c_int, 64ULL)))))))))
                (*c2fb_temp_19) = c2fb_temp_20
            End If
        c2fb_flow_1:
            c2fb_temp_18 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_21 = CPtr(SQLITE_C_INT Ptr, @(arg5->iCol))
        c2fb_temp_22 = Cast(c2fb_c_int, arg2)
        (*c2fb_temp_21) = Cast(SQLITE_C_INT, c2fb_temp_22)
        c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
        While (-Cast(c2fb_c_int, (fts3SnippetNextCandidate(CPtr(SqliteFts3SnippetIter Ptr, @(local2))) = 0)))
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            fts3SnippetDetails(CPtr(SqliteFts3SnippetIter Ptr, @(local2)), arg3, CPtr(c2fb_c_int Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local8)), CPtr(c2fb_uint64 Ptr, @(local9)), CPtr(c2fb_uint64 Ptr, @(local10)))
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local8 > local4)))) Then
                c2fb_temp_23 = CPtr(SQLITE_C_INT Ptr, @(arg5->iPos))
                c2fb_temp_24 = Cast(c2fb_c_int, local7)
                (*c2fb_temp_23) = Cast(SQLITE_C_INT, c2fb_temp_24)
                c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
                c2fb_temp_25 = CPtr(sqlite3_uint64 Ptr, @(arg5->hlmask))
                c2fb_temp_26 = Cast(c2fb_uint64, local10)
                (*c2fb_temp_25) = Cast(sqlite3_uint64, c2fb_temp_26)
                c2fb_temp_26 = Cast(c2fb_uint64, (*c2fb_temp_25))
                c2fb_temp_27 = CPtr(sqlite3_uint64 Ptr, @(arg5->covered))
                c2fb_temp_28 = Cast(c2fb_uint64, local9)
                (*c2fb_temp_27) = Cast(sqlite3_uint64, c2fb_temp_28)
                c2fb_temp_28 = Cast(c2fb_uint64, (*c2fb_temp_27))
                c2fb_temp_29 = Cast(c2fb_c_int, local8)
                local4 = c2fb_temp_29
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_30 = CPtr(c2fb_c_int Ptr, @((*arg6)))
        c2fb_temp_31 = Cast(c2fb_c_int, local4)
        (*c2fb_temp_30) = c2fb_temp_31
    End If
    sqlite3_free(CPtr(Any Ptr, local2.aPhrase))
    Return local0
End Function
Private Function fts3StringAppend CDecl Alias "fts3StringAppend" (ByVal arg0 As SqliteFts3StrBuffer Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 607
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local0 As c2fb_int64
    Dim local1 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As SQLITE_C_INT Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As SQLITE_C_INT Ptr
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
        c2fb_temp_3 = CPtr(SQLITE_C_INT Ptr, @(arg0->nAlloc))
        c2fb_temp_4 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_3) = Cast(SQLITE_C_INT, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    End If
    ' C unused-parameter annotation
    c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->z)[arg0->n]))), CPtr(Const Any Ptr, arg1), arg2))
    c2fb_temp_6 = CPtr(SQLITE_C_INT Ptr, @(arg0->n))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_6)) + arg2)))
    (*c2fb_temp_6) = Cast(SQLITE_C_INT, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->z)[arg0->n]))
    c2fb_temp_9 = Cast(Byte, Cast(c2fb_c_int, 0))
    (*c2fb_temp_8) = c2fb_temp_9
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3SnippetShift CDecl Alias "fts3SnippetShift" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As c2fb_uint64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 659
    Dim local0 As c2fb_uint64
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As Fts3TokenizerModule Ptr
    Dim local8 As Fts3TokenizerCursor Ptr
    Dim c2fb_temp_5 As Fts3TokenizerModule Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local9 As Const ZString Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_uint64 Ptr
    Dim c2fb_temp_12 As c2fb_uint64

    local0 = (*arg6)
    If local0 Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((Cast(c2fb_uint64, (local0 And (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)) Shl local1)))))) = 0)))
            ' empty C statement
        c2fb_flow_1:
            c2fb_temp_1 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((Cast(c2fb_uint64, (local0 And (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 1ULL))) - local2))))))))) = 0)))
            ' empty C statement
        c2fb_flow_3:
            c2fb_temp_3 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_2:
        ' C unused-parameter annotation
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local1 - local2))) \ Cast(c2fb_c_int, 2ULL))))
        local3 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            local5 = Cast(c2fb_c_int, &O0ULL)
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_5 = CPtr(Fts3TokenizerModule Ptr, CPtr(Const Fts3TokenizerModule Ptr, arg0->pTokenizer->pModule))
            local7 = c2fb_temp_5
            c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3OpenTokenizer(arg0->pTokenizer, arg1, arg3, arg4, CPtr(Fts3TokenizerCursor Ptr Ptr, @(local8))))
            local6 = c2fb_temp_6
            If (-Cast(c2fb_c_int, ((local6 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return local6
            End If
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < (Cast(c2fb_c_int, (arg2 + local3))))))) <> 0)))))
                ' C automatic storage declaration
                local10 = Cast(c2fb_c_int, &O0ULL)
                local11 = Cast(c2fb_c_int, &O0ULL)
                local12 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_7 = Cast(c2fb_c_int, CPtr(c2fb_callback_158, local7->xNext)(local8, CPtr(Const ZString Ptr Ptr, @(local9)), CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_c_int Ptr, @(local11)), CPtr(c2fb_c_int Ptr, @(local12)), CPtr(c2fb_c_int Ptr, @(local5))))
                local6 = c2fb_temp_7
            c2fb_flow_5:
            Wend
            c2fb_flow_4:
            CPtr(c2fb_callback_157, local7->xClose)(local8)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6 <> Cast(c2fb_c_int, 101ULL))))) <> 0))))) Then
                Return local6
            End If
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, 101ULL)))))) + local5)) - arg2)))
            local4 = c2fb_temp_8
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local4 > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg5)))
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_9) + local4)))
                (*c2fb_temp_9) = c2fb_temp_10
                c2fb_temp_11 = CPtr(c2fb_uint64 Ptr, @((*arg6)))
                c2fb_temp_12 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local0 Shr local4)))
                (*c2fb_temp_11) = c2fb_temp_12
            End If
        End If
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3SnippetText CDecl Alias "fts3SnippetText" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As SqliteFts3SnippetFragment Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As Const ZString Ptr, ByVal arg7 As Const ZString Ptr, ByVal arg8 As SqliteFts3StrBuffer Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 724
    Dim local0 As SqliteFts3Table Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_uint64
    Dim local9 As c2fb_c_int
    Dim local10 As Fts3TokenizerModule Ptr
    Dim local11 As Fts3TokenizerCursor Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Fts3TokenizerModule Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local12 As Const ZString Ptr
    Dim local13 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim local16 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local17 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int

    local0 = CPtr(SqliteFts3Table Ptr, arg0->base.pVtab)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = arg1->iPos
    local8 = arg1->hlmask
    local9 = Cast(c2fb_c_int, (arg1->iCol + Cast(c2fb_c_int, 1ULL)))
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, sqlite3_column_text(arg0->pStmt, local9)))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((sqlite3_column_type(arg0->pStmt, local9) <> Cast(c2fb_c_int, 5ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_column_bytes(arg0->pStmt, local9))
    local3 = c2fb_temp_1
    c2fb_temp_2 = CPtr(Fts3TokenizerModule Ptr, CPtr(Const Fts3TokenizerModule Ptr, local0->pTokenizer->pModule))
    local10 = c2fb_temp_2
    c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3OpenTokenizer(local0->pTokenizer, arg0->iLangid, local2, local3, CPtr(Fts3TokenizerCursor Ptr Ptr, @(local11))))
    local1 = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local1
    End If
    While (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL)))))
        ' C automatic storage declaration
        local13 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
        local14 = Cast(c2fb_c_int, &O0ULL)
        local15 = Cast(c2fb_c_int, &O0ULL)
        local16 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_4 = Cast(c2fb_c_int, CPtr(c2fb_callback_158, local10->xNext)(local11, CPtr(Const ZString Ptr Ptr, @(local12)), CPtr(c2fb_c_int Ptr, @(local13)), CPtr(c2fb_c_int Ptr, @(local14)), CPtr(c2fb_c_int Ptr, @(local15)), CPtr(c2fb_c_int Ptr, @(local4))))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 101ULL))))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, fts3StringAppend(arg8, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local2)[local5]))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
                local1 = c2fb_temp_5
            End If
            Goto c2fb_flow_0
        End If
        If (-Cast(c2fb_c_int, ((local4 < local7)))) Then
            Goto c2fb_flow_1
        End If
        If (-Cast(c2fb_c_int, (local6 = 0))) Then
            local17 = Cast(c2fb_c_int, (local3 - local14))
            c2fb_temp_6 = Cast(c2fb_c_int, fts3SnippetShift(local0, arg0->iLangid, arg4, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local2)[local14]))), local17, CPtr(c2fb_c_int Ptr, @(local7)), CPtr(c2fb_uint64 Ptr, @(local8))))
            local1 = c2fb_temp_6
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local6 = c2fb_temp_7
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 > Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_8 = Cast(c2fb_c_int, fts3StringAppend(arg8, arg7, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
                    local1 = c2fb_temp_8
                Else
                    If local14 Then
                        c2fb_temp_9 = Cast(c2fb_c_int, fts3StringAppend(arg8, local2, local14))
                        local1 = c2fb_temp_9
                    End If
                End If
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 < local7)))) <> 0))))) Then
                Goto c2fb_flow_1
            End If
        End If
        If (-Cast(c2fb_c_int, ((local4 >= (Cast(c2fb_c_int, (local7 + arg4))))))) Then
            If arg3 Then
                c2fb_temp_10 = Cast(c2fb_c_int, fts3StringAppend(arg8, arg7, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
                local1 = c2fb_temp_10
            End If
            Goto c2fb_flow_0
        End If
        c2fb_temp_11 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, (((Cast(c2fb_uint64, (local8 And (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)) Shl (Cast(c2fb_c_int, (local4 - local7))))))))) <> Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))))
        local16 = c2fb_temp_11
        If (-Cast(c2fb_c_int, ((local4 > local7)))) Then
            c2fb_temp_12 = Cast(c2fb_c_int, fts3StringAppend(arg8, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local2)[local5]))), Cast(c2fb_c_int, (local14 - local5))))
            local1 = c2fb_temp_12
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local16 <> 0))))) Then
            c2fb_temp_13 = Cast(c2fb_c_int, fts3StringAppend(arg8, arg5, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
            local1 = c2fb_temp_13
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_14 = Cast(c2fb_c_int, fts3StringAppend(arg8, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local2)[local14]))), Cast(c2fb_c_int, (local15 - local14))))
            local1 = c2fb_temp_14
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local16 <> 0))))) Then
            c2fb_temp_15 = Cast(c2fb_c_int, fts3StringAppend(arg8, arg6, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
            local1 = c2fb_temp_15
        End If
        c2fb_temp_16 = Cast(c2fb_c_int, local15)
        local5 = c2fb_temp_16
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    CPtr(c2fb_callback_157, local10->xClose)(local11)
    Return local1
End Function
Private Function fts3ColumnlistCount CDecl Alias "fts3ColumnlistCount" (ByVal arg0 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 852
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
Private Function fts3ExprLHits CDecl Alias "fts3ExprLHits" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As SqliteFts3MatchInfo Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 870
    Dim local0 As SqliteFts3Table Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteFts3Phrase Ptr
    Dim local3 As ZString Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_2 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As ZString Ptr

    local0 = CPtr(SqliteFts3Table Ptr, arg1->pCursor->base.pVtab)
    ' C automatic storage declaration
    local2 = arg0->pPhrase
    local3 = local2->doclist.pList
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->flag) = Cast(c2fb_c_int, 121))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg0->iPhrase * arg1->nCol)))
        local1 = c2fb_temp_0
    Else
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg0->iPhrase * (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1->nCol + Cast(c2fb_c_int, 31ULL)))) \ Cast(c2fb_c_int, 32ULL)))))))
        local1 = c2fb_temp_1
    End If
    If local3 Then
        While Cast(c2fb_c_int, 1ULL)
            local5 = fts3ColumnlistCount(CPtr(ZString Ptr Ptr, @(local3)))
            If ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2->iColumn >= local0->nColumn)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2->iColumn = local4)))) <> 0)))))) Then
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->flag) = Cast(c2fb_c_int, 121))))) Then
                    c2fb_temp_2 = CPtr(SQLITE_C_UINT Ptr, @(arg1->aMatchinfo[Cast(c2fb_c_int, (local1 + local4))]))
                    c2fb_temp_3 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, local5))
                    (*c2fb_temp_2) = Cast(SQLITE_C_UINT, c2fb_temp_3)
                    c2fb_temp_3 = Cast(c2fb_c_uint, (*c2fb_temp_2))
                Else
                    If local5 Then
                        c2fb_temp_4 = CPtr(SQLITE_C_UINT Ptr, @(arg1->aMatchinfo[Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, (local4 \ Cast(c2fb_c_int, 32ULL)))))]))
                        c2fb_temp_5 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (*c2fb_temp_4)) Or (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, 1ULL) Shl (Cast(c2fb_c_int, (local4 And Cast(c2fb_c_int, &H1FULL))))))))))
                        (*c2fb_temp_4) = Cast(SQLITE_C_UINT, c2fb_temp_5)
                        c2fb_temp_5 = Cast(c2fb_c_uint, (*c2fb_temp_4))
                    End If
                End If
            End If
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local3))) <> Cast(c2fb_c_int, &H01ULL))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_6 = local3
            local3 = (c2fb_temp_6 + 1)
            If (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local3)))) And Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_9 = c2fb_external_sqlite3Fts3GetVarint32(CPtr(Const ZString Ptr, local3), CPtr(c2fb_c_int Ptr, @(local4)))
            Else
                c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, @(local4)))))
                c2fb_temp_8 = Cast(c2fb_c_int, (*CPtr(UByte Ptr, (local3))))
                (*c2fb_temp_7) = c2fb_temp_8
                c2fb_temp_9 = (Cast(c2fb_c_int, 1ULL))
            End If
            c2fb_temp_10 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + (c2fb_temp_9)))
            local3 = c2fb_temp_10
            If (-Cast(c2fb_c_int, ((local4 >= arg1->nCol)))) Then
                Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3ExprLHitGather CDecl Alias "fts3ExprLHitGather" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As SqliteFts3MatchInfo Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 908
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->bEof) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->iDocid = arg1->pCursor->iPrevId)))) <> 0))))) Then
        If arg0->pLeft Then
            c2fb_temp_0 = Cast(c2fb_c_int, fts3ExprLHitGather(arg0->pLeft, arg1))
            local0 = c2fb_temp_0
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_1 = Cast(c2fb_c_int, fts3ExprLHitGather(arg0->pRight, arg1))
                local0 = c2fb_temp_1
            End If
        Else
            c2fb_temp_2 = Cast(c2fb_c_int, fts3ExprLHits(arg0, arg1))
            local0 = c2fb_temp_2
        End If
    End If
    Return local0
End Function
Private Function fts3ExprGlobalHitsCb CDecl Alias "fts3ExprGlobalHitsCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 952
    Dim local0 As SqliteFts3MatchInfo Ptr

    local0 = CPtr(SqliteFts3MatchInfo Ptr, arg2)
    Return c2fb_external_sqlite3Fts3EvalPhraseStats(local0->pCursor, arg0, CPtr(c2fb_c_uint Ptr, @(local0->aMatchinfo[Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 3ULL) * arg1)) * local0->nCol))])))
End Function
Private Function fts3ExprLocalHitsCb CDecl Alias "fts3ExprLocalHitsCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 968
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteFts3MatchInfo Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_6 As c2fb_c_uint

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(SqliteFts3MatchInfo Ptr, arg2)
    local2 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 * local1->nCol)) * Cast(c2fb_c_int, 3ULL)))
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < local1->nCol)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3EvalPhrasePoslist(local1->pCursor, arg0, local3, CPtr(ZString Ptr Ptr, @(local4))))
        local0 = c2fb_temp_2
        If local4 Then
            c2fb_temp_3 = CPtr(SQLITE_C_UINT Ptr, @(local1->aMatchinfo[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 3ULL)))))]))
            c2fb_temp_4 = Cast(c2fb_c_uint, fts3ColumnlistCount(CPtr(ZString Ptr Ptr, @(local4))))
            (*c2fb_temp_3) = Cast(SQLITE_C_UINT, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_uint, (*c2fb_temp_3))
        Else
            c2fb_temp_5 = CPtr(SQLITE_C_UINT Ptr, @(local1->aMatchinfo[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 3ULL)))))]))
            c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_5) = Cast(SQLITE_C_UINT, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_c_uint, (*c2fb_temp_5))
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Function fts3MatchinfoCheck CDecl Alias "fts3MatchinfoCheck" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As Byte, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 991
    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 112)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 99)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 110))))) <> 0) AndAlso (arg0->bFts4 <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 97))))) <> 0) AndAlso (arg0->bFts4 <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 108))))) <> 0) AndAlso (arg0->bHasDocsize <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 115)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 120)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 121)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) = Cast(c2fb_c_int, 98)))))) <> 0))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_external_sqlite3Fts3ErrMsg(arg2, StrPtr(!"unrecognized matchinfo request: %c"), arg1)
    Return Cast(c2fb_c_int, 1ULL)
End Function
Private Function fts3MatchinfoSize CDecl Alias "fts3MatchinfoSize" (ByVal arg0 As SqliteFts3MatchInfo Ptr, ByVal arg1 As Byte) As c2fb_int64
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1012
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
Private Function fts3MatchinfoSelectDoctotal CDecl Alias "fts3MatchinfoSelectDoctotal" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As Any Ptr Ptr, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1045
    Dim local0 As Any Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
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
        local5 = c2fb_external_sqlite3Fts3SelectDoctotal(arg0, arg1)
        If (-Cast(c2fb_c_int, ((local5 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local5
        End If
    End If
    c2fb_temp_0 = (*arg1)
    local0 = c2fb_temp_0
    ' C unused-parameter annotation
    c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_column_bytes(local0, Cast(c2fb_c_int, &O0ULL)))
    local4 = c2fb_temp_1
    c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(Const Any Ptr, sqlite3_column_blob(local0, Cast(c2fb_c_int, &O0ULL))))
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
Private Function fts3MatchinfoLcsCb CDecl Alias "fts3MatchinfoLcsCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1103
    Dim local0 As SqliteFts3LcsIterator Ptr
    Dim c2fb_temp_0 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_1 As SqliteFts3Expr Ptr

    local0 = CPtr(SqliteFts3LcsIterator Ptr, arg2)
    c2fb_temp_0 = CPtr(SqliteFts3Expr Ptr Ptr, @(local0[arg1].pExpr))
    c2fb_temp_1 = arg0
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3LcsIteratorAdvance CDecl Alias "fts3LcsIteratorAdvance" (ByVal arg0 As SqliteFts3LcsIterator Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1118
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As SQLITE_C_INT Ptr
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
    c2fb_temp_1 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local0) + c2fb_external_sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, local0), CPtr(c2fb_int64 Ptr, @(local1)))))
    local0 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) <> 0))))) Then
        c2fb_temp_2 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local2 = c2fb_temp_3
    Else
        c2fb_temp_4 = CPtr(SQLITE_C_INT Ptr, @(arg0->iPos))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_4)) + Cast(c2fb_c_int, (Cast(c2fb_int64, (local1 - Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))))))
        (*c2fb_temp_4) = Cast(SQLITE_C_INT, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    End If
    c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(arg0->pRead))
    c2fb_temp_7 = local0
    (*c2fb_temp_6) = c2fb_temp_7
    Return local2
End Function
Private Function fts3MatchinfoLcs CDecl Alias "fts3MatchinfoLcs" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As SqliteFts3MatchInfo Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1148
    Dim local0 As SqliteFts3LcsIterator Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteFts3LcsIterator Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local5 As SqliteFts3LcsIterator Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As SQLITE_C_INT Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local8 As SqliteFts3LcsIterator Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As SQLITE_C_INT Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local9 As SqliteFts3LcsIterator Ptr
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim local11 As SqliteFts3LcsIterator Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As SqliteFts3LcsIterator Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_24 As c2fb_c_uint

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(SqliteFts3LcsIterator Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts3MallocZero(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteFts3LcsIterator))) * Cast(c2fb_uint64, arg0->nPhrase))))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    sqlite3Fts3ExprIterate(CPtr(SqliteFts3Expr Ptr, arg0->pExpr), ProcPtr(fts3MatchinfoLcsCb), CPtr(Any Ptr, local0))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local1 < arg1->nPhrase))))
        local5 = CPtr(SqliteFts3LcsIterator Ptr, @(local0[local1]))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 - local5->pExpr->pPhrase->nToken)))
        local3 = c2fb_temp_3
        c2fb_temp_4 = CPtr(SQLITE_C_INT Ptr, @(local5->iPosOffset))
        c2fb_temp_5 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_4) = Cast(SQLITE_C_INT, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    c2fb_flow_1:
        c2fb_temp_2 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_6
    While (-Cast(c2fb_c_int, ((local2 < arg1->nCol))))
        local6 = Cast(c2fb_c_int, &O0ULL)
        local7 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_8
        While (-Cast(c2fb_c_int, ((local1 < arg1->nPhrase))))
            local8 = CPtr(SqliteFts3LcsIterator Ptr, @(local0[local1]))
            c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3EvalPhrasePoslist(arg0, local8->pExpr, local2, CPtr(ZString Ptr Ptr, @(local8->pRead))))
            local4 = c2fb_temp_10
            If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_label_0
            End If
            If local8->pRead Then
                c2fb_temp_11 = CPtr(SQLITE_C_INT Ptr, @(local8->iPos))
                c2fb_temp_12 = Cast(c2fb_c_int, local8->iPosOffset)
                (*c2fb_temp_11) = Cast(SQLITE_C_INT, c2fb_temp_12)
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
                fts3LcsIteratorAdvance(local8)
                If (-Cast(c2fb_c_int, ((local8->pRead = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_13 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local4 = c2fb_temp_13
                    Goto c2fb_label_0
                End If
                c2fb_temp_14 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
            End If
        c2fb_flow_5:
            c2fb_temp_9 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
        Wend
        c2fb_flow_4:
        While (-Cast(c2fb_c_int, ((local7 > Cast(c2fb_c_int, &O0ULL)))))
            local9 = Cast(c2fb_c_int, &O0ULL)
            local10 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_15
            While (-Cast(c2fb_c_int, ((local1 < arg1->nPhrase))))
                local11 = CPtr(SqliteFts3LcsIterator Ptr, @(local0[local1]))
                If (-Cast(c2fb_c_int, ((local11->pRead = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local10 = c2fb_temp_17
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local11->iPos < local9->iPos)))) <> 0))))) Then
                        c2fb_temp_18 = local11
                        local9 = c2fb_temp_18
                    End If
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local11->iPos = local11[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].iPos)))) <> 0))))) Then
                        c2fb_temp_19 = local10
                        local10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_19 + 1)))
                    Else
                        c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local10 = c2fb_temp_20
                    End If
                    If (-Cast(c2fb_c_int, ((local10 > local6)))) Then
                        c2fb_temp_21 = Cast(c2fb_c_int, local10)
                        local6 = c2fb_temp_21
                    End If
                End If
            c2fb_flow_9:
                c2fb_temp_16 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 + 1)))
            Wend
            c2fb_flow_8:
            If fts3LcsIteratorAdvance(local9) Then
                c2fb_temp_22 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_22 - 1)))
            End If
        c2fb_flow_7:
        Wend
        c2fb_flow_6:
        c2fb_temp_23 = CPtr(SQLITE_C_UINT Ptr, @(arg1->aMatchinfo[local2]))
        c2fb_temp_24 = Cast(c2fb_c_uint, local6)
        (*c2fb_temp_23) = Cast(SQLITE_C_UINT, c2fb_temp_24)
        c2fb_temp_24 = Cast(c2fb_c_uint, (*c2fb_temp_23))
    c2fb_flow_3:
        c2fb_temp_7 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
    Wend
    c2fb_flow_2:
    c2fb_label_0:
    sqlite3_free(CPtr(Any Ptr, local0))
    Return local4
End Function
Private Function fts3MatchinfoValues CDecl Alias "fts3MatchinfoValues" (ByVal arg0 As SqliteFts3Cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteFts3MatchInfo Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1236
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteFts3Table Ptr
    Dim local3 As Any Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Byte Ptr
    Dim c2fb_temp_3 As Byte
    Dim c2fb_temp_4 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim local4 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_10 As c2fb_c_uint
    Dim local5 As c2fb_int64
    Dim local6 As Const ZString Ptr
    Dim local7 As Const ZString Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local9 As c2fb_c_uint
    Dim local10 As c2fb_int64
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_uint
    Dim c2fb_temp_17 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_18 As c2fb_c_uint
    Dim local11 As Any Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim local13 As Const ZString Ptr
    Dim local14 As Const ZString Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim local15 As c2fb_int64
    Dim c2fb_temp_22 As Const ZString Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_25 As c2fb_c_uint
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim local16 As c2fb_int64
    Dim c2fb_temp_28 As Any Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim local17 As SqliteFts3Expr Ptr
    Dim c2fb_temp_30 As SqliteFts3Expr Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As SQLITE_C_UINT Ptr Ptr
    Dim c2fb_temp_35 As c2fb_c_uint Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = CPtr(SqliteFts3Table Ptr, arg0->base.pVtab)
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(Const Byte Ptr, arg3)[local1] <> 0)))))
        c2fb_temp_2 = CPtr(Byte Ptr, @(arg2->flag))
        c2fb_temp_3 = Cast(Byte, CPtr(Const Byte Ptr, arg3)[local1])
        (*c2fb_temp_2) = c2fb_temp_3
        Select Case CPtr(Const Byte Ptr, arg3)[local1]
            Case Cast(c2fb_c_int, 112)
                If arg1 Then
                    c2fb_temp_4 = CPtr(SQLITE_C_UINT Ptr, @(arg2->aMatchinfo[Cast(c2fb_c_int, &O0ULL)]))
                    c2fb_temp_5 = Cast(c2fb_c_uint, arg2->nPhrase)
                    (*c2fb_temp_4) = Cast(SQLITE_C_UINT, c2fb_temp_5)
                    c2fb_temp_5 = Cast(c2fb_c_uint, (*c2fb_temp_4))
                End If
            Case Cast(c2fb_c_int, 99)
                If arg1 Then
                    c2fb_temp_6 = CPtr(SQLITE_C_UINT Ptr, @(arg2->aMatchinfo[Cast(c2fb_c_int, &O0ULL)]))
                    c2fb_temp_7 = Cast(c2fb_c_uint, arg2->nCol)
                    (*c2fb_temp_6) = Cast(SQLITE_C_UINT, c2fb_temp_7)
                    c2fb_temp_7 = Cast(c2fb_c_uint, (*c2fb_temp_6))
                End If
            Case Cast(c2fb_c_int, 110)
                If arg1 Then
                    local4 = Cast(c2fb_c_int, &O0ULL)
                    c2fb_temp_8 = Cast(c2fb_c_int, fts3MatchinfoSelectDoctotal(local2, CPtr(Any Ptr Ptr, @(local3)), CPtr(c2fb_int64 Ptr, @(local4)), CPtr(Const ZString Ptr Ptr, 0), CPtr(Const ZString Ptr Ptr, 0)))
                    local0 = c2fb_temp_8
                    c2fb_temp_9 = CPtr(SQLITE_C_UINT Ptr, @(arg2->aMatchinfo[Cast(c2fb_c_int, &O0ULL)]))
                    c2fb_temp_10 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, local4))
                    (*c2fb_temp_9) = Cast(SQLITE_C_UINT, c2fb_temp_10)
                    c2fb_temp_10 = Cast(c2fb_c_uint, (*c2fb_temp_9))
                End If
            Case Cast(c2fb_c_int, 97)
                If arg1 Then
                    ' C automatic storage declaration
                    ' C automatic storage declaration
                    ' C automatic storage declaration
                    c2fb_temp_11 = Cast(c2fb_c_int, fts3MatchinfoSelectDoctotal(local2, CPtr(Any Ptr Ptr, @(local3)), CPtr(c2fb_int64 Ptr, @(local5)), CPtr(Const ZString Ptr Ptr, @(local6)), CPtr(Const ZString Ptr Ptr, @(local7))))
                    local0 = c2fb_temp_11
                    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                        ' C automatic storage declaration
                        c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        local8 = c2fb_temp_12
                        While (-Cast(c2fb_c_int, ((local8 < arg2->nCol))))
                            ' C automatic storage declaration
                            ' C automatic storage declaration
                            c2fb_temp_14 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local6) + c2fb_external_sqlite3Fts3GetVarint(local6, CPtr(c2fb_int64 Ptr, @(local10)))))
                            local6 = c2fb_temp_14
                            If (-Cast(c2fb_c_int, ((local6 > local7)))) Then
                                c2fb_temp_15 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                                local0 = c2fb_temp_15
                                Goto c2fb_flow_3
                            End If
                            c2fb_temp_16 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, (Cast(c2fb_int64, (local10 And Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL))))))) + Cast(c2fb_int64, (local5 \ Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))))) \ local5)))))
                            local9 = c2fb_temp_16
                            c2fb_temp_17 = CPtr(SQLITE_C_UINT Ptr, @(arg2->aMatchinfo[local8]))
                            c2fb_temp_18 = Cast(c2fb_c_uint, local9)
                            (*c2fb_temp_17) = Cast(SQLITE_C_UINT, c2fb_temp_18)
                            c2fb_temp_18 = Cast(c2fb_c_uint, (*c2fb_temp_17))
                        c2fb_flow_4:
                            c2fb_temp_13 = local8
                            local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                        Wend
                        c2fb_flow_3:
                    End If
                End If
            Case Cast(c2fb_c_int, 108)
                local11 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_19 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SelectDocsize(local2, arg0->iPrevId, CPtr(Any Ptr Ptr, @(local11))))
                local0 = c2fb_temp_19
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    ' C automatic storage declaration
                    local13 = CPtr(Const Any Ptr, sqlite3_column_blob(local11, Cast(c2fb_c_int, &O0ULL)))
                    local14 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local13) + sqlite3_column_bytes(local11, Cast(c2fb_c_int, &O0ULL))))
                    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local12 = c2fb_temp_20
                    While (-Cast(c2fb_c_int, ((local12 < arg2->nCol))))
                        ' C automatic storage declaration
                        c2fb_temp_22 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local13) + sqlite3Fts3GetVarintBounded(local13, local14, CPtr(c2fb_int64 Ptr, @(local15)))))
                        local13 = c2fb_temp_22
                        If (-Cast(c2fb_c_int, ((local13 > local14)))) Then
                            c2fb_temp_23 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                            local0 = c2fb_temp_23
                            Goto c2fb_flow_5
                        End If
                        c2fb_temp_24 = CPtr(SQLITE_C_UINT Ptr, @(arg2->aMatchinfo[local12]))
                        c2fb_temp_25 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, local15))
                        (*c2fb_temp_24) = Cast(SQLITE_C_UINT, c2fb_temp_25)
                        c2fb_temp_25 = Cast(c2fb_c_uint, (*c2fb_temp_24))
                    c2fb_flow_6:
                        c2fb_temp_21 = local12
                        local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
                    Wend
                    c2fb_flow_5:
                End If
                sqlite3_reset(local11)
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 115)
                c2fb_temp_26 = Cast(c2fb_c_int, fts3ExprLoadDoclists(arg0, CPtr(c2fb_c_int Ptr, 0), CPtr(c2fb_c_int Ptr, 0)))
                local0 = c2fb_temp_26
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_27 = Cast(c2fb_c_int, fts3MatchinfoLcs(arg0, arg2))
                    local0 = c2fb_temp_27
                End If
            Case Cast(c2fb_c_int, 98), Cast(c2fb_c_int, 121)
                local16 = Cast(c2fb_uint64, (Cast(c2fb_uint64, fts3MatchinfoSize(arg2, CPtr(Const Byte Ptr, arg3)[local1])) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))
                c2fb_temp_28 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg2->aMatchinfo), Cast(c2fb_c_int, &O0ULL), local16))
                c2fb_temp_29 = Cast(c2fb_c_int, fts3ExprLHitGather(CPtr(SqliteFts3Expr Ptr, arg0->pExpr), arg2))
                local0 = c2fb_temp_29
                Goto c2fb_flow_2
            Case Else
                ' C automatic storage declaration
                ' C unused-parameter annotation
                c2fb_temp_30 = CPtr(SqliteFts3Expr Ptr, arg0->pExpr)
                local17 = c2fb_temp_30
                c2fb_temp_31 = Cast(c2fb_c_int, fts3ExprLoadDoclists(arg0, CPtr(c2fb_c_int Ptr, 0), CPtr(c2fb_c_int Ptr, 0)))
                local0 = c2fb_temp_31
                If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_2
                End If
                If arg1 Then
                    If CPtr(Any Ptr, arg0->pDeferred) Then
                        c2fb_temp_32 = Cast(c2fb_c_int, fts3MatchinfoSelectDoctotal(local2, CPtr(Any Ptr Ptr, @(local3)), CPtr(c2fb_int64 Ptr, @(arg2->nDoc)), CPtr(Const ZString Ptr Ptr, 0), CPtr(Const ZString Ptr Ptr, 0)))
                        local0 = c2fb_temp_32
                        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                            Goto c2fb_flow_2
                        End If
                    End If
                    c2fb_temp_33 = Cast(c2fb_c_int, sqlite3Fts3ExprIterate(local17, ProcPtr(fts3ExprGlobalHitsCb), CPtr(Any Ptr, arg2)))
                    local0 = c2fb_temp_33
                    c2fb_external_sqlite3Fts3EvalTestDeferred(arg0, CPtr(c2fb_c_int Ptr, @(local0)))
                    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_2
                    End If
                End If
                sqlite3Fts3ExprIterate(local17, ProcPtr(fts3ExprLocalHitsCb), CPtr(Any Ptr, arg2))
                Goto c2fb_flow_2
        End Select
        c2fb_flow_2:
        c2fb_temp_34 = CPtr(SQLITE_C_UINT Ptr Ptr, @(arg2->aMatchinfo))
        c2fb_temp_35 = CPtr(c2fb_c_uint Ptr, ((*c2fb_temp_34) + fts3MatchinfoSize(arg2, CPtr(Const Byte Ptr, arg3)[local1])))
        (*c2fb_temp_34) = CPtr(SQLITE_C_UINT Ptr, c2fb_temp_35)
        c2fb_temp_35 = CPtr(c2fb_c_uint Ptr, (*c2fb_temp_34))
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    sqlite3_reset(local3)
    Return local0
End Function
Private Sub fts3GetMatchinfo CDecl Alias "fts3GetMatchinfo" (ByVal arg0 As Any Ptr, ByVal arg1 As SqliteFts3Cursor Ptr, ByVal arg2 As Const ZString Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1358
    Dim local0 As SqliteFts3MatchInfo
    Dim local1 As SqliteFts3Table Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_uint Ptr
    Dim local5 As c2fb_callback_70
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As SqliteFts3Cursor Ptr Ptr
    Dim c2fb_temp_2 As SqliteFts3Cursor Ptr
    Dim c2fb_temp_3 As SQLITE_C_INT Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr Ptr
    Dim c2fb_temp_6 As Fts3MatchinfoBuffer Ptr
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As SQLITE_C_INT Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local8 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_int64
    Dim c2fb_temp_14 As Any Ptr Ptr
    Dim c2fb_temp_15 As Fts3MatchinfoBuffer Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As SQLITE_C_INT Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_callback_70
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As SQLITE_C_UINT Ptr Ptr
    Dim c2fb_temp_23 As c2fb_c_uint Ptr
    Dim c2fb_temp_24 As SQLITE_C_INT Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim local9 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(SqliteFts3Table Ptr, arg1->base.pVtab)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteFts3MatchInfo Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteFts3MatchInfo))))
    c2fb_temp_1 = CPtr(SqliteFts3Cursor Ptr Ptr, @(local0.pCursor))
    c2fb_temp_2 = arg1
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = CPtr(SQLITE_C_INT Ptr, @(local0.nCol))
    c2fb_temp_4 = Cast(c2fb_c_int, local1->nColumn)
    (*c2fb_temp_3) = Cast(SQLITE_C_INT, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    If (-Cast(c2fb_c_int, (((CPtr(Fts3MatchinfoBuffer Ptr, arg1->pMIBuffer) <> 0) AndAlso (c2fb_crt_strcmp(CPtr(Const ZString Ptr, CPtr(Fts3MatchinfoBuffer Ptr, arg1->pMIBuffer)->zMatchinfo), arg2) <> 0))))) Then
        sqlite3Fts3MIBufferFree(CPtr(Fts3MatchinfoBuffer Ptr, arg1->pMIBuffer))
        c2fb_temp_5 = CPtr(Any Ptr Ptr, @(arg1->pMIBuffer))
        c2fb_temp_6 = CPtr(Fts3MatchinfoBuffer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_5) = CPtr(Any Ptr, c2fb_temp_6)
        c2fb_temp_6 = CPtr(Fts3MatchinfoBuffer Ptr, (*c2fb_temp_5))
    End If
    If (-Cast(c2fb_c_int, ((CPtr(Fts3MatchinfoBuffer Ptr, arg1->pMIBuffer) = Cast(c2fb_c_int, &O0ULL))))) Then
        local6 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(arg1->nPhrase))
        c2fb_temp_8 = Cast(c2fb_c_int, fts3ExprPhraseCount(CPtr(SqliteFts3Expr Ptr, arg1->pExpr)))
        (*c2fb_temp_7) = Cast(SQLITE_C_INT, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        c2fb_temp_9 = CPtr(SQLITE_C_INT Ptr, @(local0.nPhrase))
        c2fb_temp_10 = Cast(c2fb_c_int, arg1->nPhrase)
        (*c2fb_temp_9) = Cast(SQLITE_C_INT, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local7 = c2fb_temp_11
        While CPtr(Const Byte Ptr, arg2)[local7]
            local8 = Cast(c2fb_c_int, &O0ULL)
            If fts3MatchinfoCheck(local1, CPtr(Const Byte Ptr, arg2)[local7], CPtr(ZString Ptr Ptr, @(local8))) Then
                sqlite3_result_error(arg0, CPtr(Const ZString Ptr, local8), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                sqlite3_free(CPtr(Any Ptr, local8))
                Return
            End If
            c2fb_temp_13 = Cast(c2fb_int64, Cast(c2fb_int64, (local6 + fts3MatchinfoSize(CPtr(SqliteFts3MatchInfo Ptr, @(local0)), CPtr(Const Byte Ptr, arg2)[local7]))))
            local6 = c2fb_temp_13
        c2fb_flow_1:
            c2fb_temp_12 = local7
            local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_14 = CPtr(Any Ptr Ptr, @(arg1->pMIBuffer))
        c2fb_temp_15 = CPtr(Fts3MatchinfoBuffer Ptr, fts3MIBufferNew(local6, arg2))
        (*c2fb_temp_14) = CPtr(Any Ptr, c2fb_temp_15)
        c2fb_temp_15 = CPtr(Fts3MatchinfoBuffer Ptr, (*c2fb_temp_14))
        If (-Cast(c2fb_c_int, (CPtr(Fts3MatchinfoBuffer Ptr, arg1->pMIBuffer) = 0))) Then
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local2 = c2fb_temp_16
        End If
        c2fb_temp_17 = CPtr(SQLITE_C_INT Ptr, @(arg1->isMatchinfoNeeded))
        c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_17) = Cast(SQLITE_C_INT, c2fb_temp_18)
        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
        c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_19
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_20 = CPtr(c2fb_callback_70, CPtr(Any Ptr, fts3MIBufferAlloc(CPtr(Fts3MatchinfoBuffer Ptr, arg1->pMIBuffer), CPtr(c2fb_c_uint Ptr Ptr, @(local4)))))
        local5 = c2fb_temp_20
        If (-Cast(c2fb_c_int, ((CPtr(Any Ptr, local5) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local2 = c2fb_temp_21
        End If
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_22 = CPtr(SQLITE_C_UINT Ptr Ptr, @(local0.aMatchinfo))
        c2fb_temp_23 = local4
        (*c2fb_temp_22) = CPtr(SQLITE_C_UINT Ptr, c2fb_temp_23)
        c2fb_temp_23 = CPtr(c2fb_c_uint Ptr, (*c2fb_temp_22))
        c2fb_temp_24 = CPtr(SQLITE_C_INT Ptr, @(local0.nPhrase))
        c2fb_temp_25 = Cast(c2fb_c_int, arg1->nPhrase)
        (*c2fb_temp_24) = Cast(SQLITE_C_INT, c2fb_temp_25)
        c2fb_temp_25 = Cast(c2fb_c_int, (*c2fb_temp_24))
        c2fb_temp_26 = Cast(c2fb_c_int, fts3MatchinfoValues(arg1, local3, CPtr(SqliteFts3MatchInfo Ptr, @(local0)), arg2))
        local2 = c2fb_temp_26
        If local3 Then
            fts3MIBufferSetGlobal(CPtr(Fts3MatchinfoBuffer Ptr, arg1->pMIBuffer))
        End If
    End If
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_result_error_code(arg0, local2)
        If local5 Then
            local5(CPtr(Any Ptr, local4))
        End If
    Else
        local9 = Cast(c2fb_uint64, (Cast(c2fb_uint64, CPtr(Fts3MatchinfoBuffer Ptr, arg1->pMIBuffer)->nElem) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))
        sqlite3_result_blob(arg0, CPtr(Const Any Ptr, local4), local9, CPtr(Any Ptr, local5))
    End If
End Sub
Sub sqlite3Fts3Snippet CDecl Alias "sqlite3Fts3Snippet" (ByVal arg0 As Any Ptr, ByVal arg1 As SqliteFts3Cursor Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1443
    Dim local0 As SqliteFts3Table Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As SqliteFts3StrBuffer
    Dim local4 As c2fb_c_int
    Dim local5(0 To 3) As SqliteFts3SnippetFragment
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_uint64
    Dim local9 As c2fb_uint64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As SqliteFts3SnippetFragment Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local13 As SqliteFts3SnippetFragment
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As SqliteFts3SnippetFragment Ptr
    Dim c2fb_temp_11 As SqliteFts3SnippetFragment
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_uint64
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int

    local0 = CPtr(SqliteFts3Table Ptr, arg1->base.pVtab)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Type<SqliteFts3StrBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic array storage
    local6 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    If (-Cast(c2fb_c_int, (CPtr(SqliteFts3Expr Ptr, arg1->pExpr) = 0))) Then
        sqlite3_result_text(arg0, StrPtr(!""), Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr, 0))
        Return
    End If
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    local4 = c2fb_temp_0
    While Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        local8 = Cast(c2fb_c_int, &O0ULL)
        local9 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((arg6 >= Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg6 + local4)) - Cast(c2fb_c_int, 1ULL)))) \ local4)))
            local6 = c2fb_temp_2
        Else
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))) * arg6)))
            local6 = c2fb_temp_3
        End If
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local7 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((local7 < local4))))
            local10 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
            ' C automatic storage declaration
            local12 = CPtr(SqliteFts3SnippetFragment Ptr, @(local5(local7)))
            c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local12), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteFts3SnippetFragment))))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local11 = c2fb_temp_7
            While (-Cast(c2fb_c_int, ((local11 < local0->nColumn))))
                local13 = Type<SqliteFts3SnippetFragment>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
                local14 = Cast(c2fb_c_int, &O0ULL)
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg5 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local11 <> arg5)))) <> 0))))) Then
                    Goto c2fb_flow_5
                End If
                c2fb_temp_9 = Cast(c2fb_c_int, fts3BestSnippet(local6, arg1, local11, local8, CPtr(c2fb_uint64 Ptr, @(local9)), CPtr(SqliteFts3SnippetFragment Ptr, @(local13)), CPtr(c2fb_c_int Ptr, @(local14))))
                local1 = c2fb_temp_9
                If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_label_0
                End If
                If (-Cast(c2fb_c_int, ((local14 > local10)))) Then
                    c2fb_temp_10 = CPtr(SqliteFts3SnippetFragment Ptr, @((*local12)))
                    c2fb_temp_11 = local13
                    (*c2fb_temp_10) = c2fb_temp_11
                    c2fb_temp_12 = Cast(c2fb_c_int, local14)
                    local10 = c2fb_temp_12
                End If
            c2fb_flow_5:
                c2fb_temp_8 = local11
                local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
            Wend
            c2fb_flow_4:
            c2fb_temp_13 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local8 Or local12->covered)))
            local8 = c2fb_temp_13
        c2fb_flow_3:
            c2fb_temp_5 = local7
            local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_2:
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local9 = local8)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 = (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (4ULL * SizeOf(SqliteFts3SnippetFragment)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteFts3SnippetFragment)))))))))))) <> 0))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    ' C unused-parameter annotation
    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_14
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < local4)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        c2fb_temp_16 = Cast(c2fb_c_int, fts3SnippetText(arg1, CPtr(SqliteFts3SnippetFragment Ptr, @(local5(local2))), local2, ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 1ULL)))))))), local6, arg2, arg3, arg4, CPtr(SqliteFts3StrBuffer Ptr, @(local3))))
        local1 = c2fb_temp_16
    c2fb_flow_7:
        c2fb_temp_15 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
    Wend
    c2fb_flow_6:
    c2fb_label_0:
    c2fb_external_sqlite3Fts3SegmentsClose(local0)
    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_result_error_code(arg0, local1)
        sqlite3_free(CPtr(Any Ptr, local3.z))
    Else
        sqlite3_result_text(arg0, CPtr(Const ZString Ptr, local3.z), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), ProcPtr(sqlite3_free))
    End If
End Sub
Private Function fts3ExprTermOffsetInit CDecl Alias "fts3ExprTermOffsetInit" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1565
    Dim local0 As SqliteFts3TermOffsetCtx Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As ZString Ptr
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As SQLITE_C_INT Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local6 As SqliteFts3TermOffset Ptr
    Dim c2fb_temp_6 As sqlite3_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As sqlite3_int64 Ptr
    Dim c2fb_temp_11 As c2fb_int64

    local0 = CPtr(SqliteFts3TermOffsetCtx Ptr, arg2)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3EvalPhrasePoslist(local0->pCsr, arg0, local0->iCol, CPtr(ZString Ptr Ptr, @(local3))))
    local5 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, arg0->pPhrase->nToken)
    local1 = c2fb_temp_1
    If local3 Then
        fts3GetDeltaPosition(CPtr(ZString Ptr Ptr, @(local3)), CPtr(c2fb_int64 Ptr, @(local4)))
        ' C unused-parameter annotation
    End If
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local2 < local1))))
        c2fb_temp_4 = CPtr(SQLITE_C_INT Ptr, @(local0->iTerm))
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
        (*c2fb_temp_4) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        local6 = CPtr(SqliteFts3TermOffset Ptr, @(local0->aTerm[c2fb_temp_5]))
        c2fb_temp_6 = CPtr(sqlite3_int64 Ptr, @(local6->iOff))
        c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - local2)) - Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_6) = Cast(sqlite3_int64, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
        c2fb_temp_8 = CPtr(ZString Ptr Ptr, @(local6->pList))
        c2fb_temp_9 = local3
        (*c2fb_temp_8) = c2fb_temp_9
        c2fb_temp_10 = CPtr(sqlite3_int64 Ptr, @(local6->iPos))
        c2fb_temp_11 = Cast(c2fb_int64, local4)
        (*c2fb_temp_10) = Cast(sqlite3_int64, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_int64, (*c2fb_temp_10))
    c2fb_flow_1:
        c2fb_temp_3 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    Return local5
End Function
Private Function fts3ExprRestartIfCb CDecl Alias "fts3ExprRestartIfCb" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1596
    Dim local0 As SqliteFts3TermOffsetCtx Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(SqliteFts3TermOffsetCtx Ptr, arg2)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((arg0->pPhrase <> 0) AndAlso (arg0->pPhrase->bIncr <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3MsrCancel(local0->pCsr, arg0))
        local1 = c2fb_temp_0
        c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(arg0->pPhrase->bIncr))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    End If
    Return local1
End Function
Sub sqlite3Fts3Offsets CDecl Alias "sqlite3Fts3Offsets" (ByVal arg0 As Any Ptr, ByVal arg1 As SqliteFts3Cursor Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1610
    Dim local0 As SqliteFts3Table Ptr
    Dim local1 As Const Fts3TokenizerModule Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As SqliteFts3StrBuffer
    Dim local6 As SqliteFts3TermOffsetCtx
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As SqliteFts3TermOffset Ptr Ptr
    Dim c2fb_temp_3 As SqliteFts3TermOffset Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As sqlite3_int64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As SqliteFts3Cursor Ptr Ptr
    Dim c2fb_temp_8 As SqliteFts3Cursor Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local7 As Fts3TokenizerCursor Ptr
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim local13 As Const ZString Ptr
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_12 As SQLITE_C_INT Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As SQLITE_C_INT Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Const ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim local16 As c2fb_c_int
    Dim local17 As SqliteFts3TermOffset Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim local18 As SqliteFts3TermOffset Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As SqliteFts3TermOffset Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As ZString Ptr Ptr
    Dim c2fb_temp_28 As ZString Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim local19(0 To 63) As Byte
    Dim c2fb_temp_30 As ZString Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int

    local0 = CPtr(SqliteFts3Table Ptr, arg1->base.pVtab)
    local1 = CPtr(Const Fts3TokenizerModule Ptr, local0->pTokenizer->pModule)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local5 = Type<SqliteFts3StrBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, (CPtr(SqliteFts3Expr Ptr, arg1->pExpr) = 0))) Then
        sqlite3_result_text(arg0, StrPtr(!""), Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr, 0))
        Return
    End If
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteFts3TermOffsetCtx Ptr, @(local6))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteFts3TermOffsetCtx))))
    ' C unused-parameter annotation
    c2fb_temp_1 = Cast(c2fb_c_int, fts3ExprLoadDoclists(arg1, CPtr(c2fb_c_int Ptr, 0), CPtr(c2fb_c_int Ptr, @(local3))))
    local2 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    c2fb_temp_2 = CPtr(SqliteFts3TermOffset Ptr Ptr, @(local6.aTerm))
    c2fb_temp_3 = CPtr(SqliteFts3TermOffset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts3MallocZero(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteFts3TermOffset))) * Cast(c2fb_uint64, local3))))))
    (*c2fb_temp_2) = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local6.aTerm)))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_4
        Goto c2fb_label_0
    End If
    c2fb_temp_5 = CPtr(sqlite3_int64 Ptr, @(local6.iDocid))
    c2fb_temp_6 = Cast(c2fb_int64, arg1->iPrevId)
    (*c2fb_temp_5) = Cast(sqlite3_int64, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_int64, (*c2fb_temp_5))
    c2fb_temp_7 = CPtr(SqliteFts3Cursor Ptr Ptr, @(local6.pCsr))
    c2fb_temp_8 = arg1
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = Cast(c2fb_c_int, sqlite3Fts3ExprIterate(CPtr(SqliteFts3Expr Ptr, arg1->pExpr), ProcPtr(fts3ExprRestartIfCb), CPtr(Any Ptr, CPtr(SqliteFts3TermOffsetCtx Ptr, @(local6)))))
    local2 = c2fb_temp_9
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_10
    While (-Cast(c2fb_c_int, ((local4 < local0->nColumn))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        local9 = Cast(c2fb_c_int, &O0ULL)
        local10 = Cast(c2fb_c_int, &O0ULL)
        local11 = Cast(c2fb_c_int, &O0ULL)
        local12 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_12 = CPtr(SQLITE_C_INT Ptr, @(local6.iCol))
        c2fb_temp_13 = Cast(c2fb_c_int, local4)
        (*c2fb_temp_12) = Cast(SQLITE_C_INT, c2fb_temp_13)
        c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
        c2fb_temp_14 = CPtr(SQLITE_C_INT Ptr, @(local6.iTerm))
        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_14) = Cast(SQLITE_C_INT, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
        c2fb_temp_16 = Cast(c2fb_c_int, sqlite3Fts3ExprIterate(CPtr(SqliteFts3Expr Ptr, arg1->pExpr), ProcPtr(fts3ExprTermOffsetInit), CPtr(Any Ptr, CPtr(SqliteFts3TermOffsetCtx Ptr, @(local6)))))
        local2 = c2fb_temp_16
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_label_0
        End If
        c2fb_temp_17 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, sqlite3_column_text(arg1->pStmt, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL))))))
        local13 = c2fb_temp_17
        c2fb_temp_18 = Cast(c2fb_c_int, sqlite3_column_bytes(arg1->pStmt, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))))
        local14 = c2fb_temp_18
        If (-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((sqlite3_column_type(arg1->pStmt, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))) = Cast(c2fb_c_int, 5ULL))))) Then
                Goto c2fb_flow_1
            End If
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local2 = c2fb_temp_19
            Goto c2fb_label_0
        End If
        c2fb_temp_20 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3OpenTokenizer(local0->pTokenizer, arg1->iLangid, local13, local14, CPtr(Fts3TokenizerCursor Ptr Ptr, @(local7))))
        local2 = c2fb_temp_20
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_label_0
        End If
        c2fb_temp_21 = Cast(c2fb_c_int, CPtr(c2fb_callback_158, local1->xNext)(local7, CPtr(Const ZString Ptr Ptr, @(local8)), CPtr(c2fb_c_int Ptr, @(local9)), CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_c_int Ptr, @(local11)), CPtr(c2fb_c_int Ptr, @(local12))))
        local2 = c2fb_temp_21
        While (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL)))))
            ' C automatic storage declaration
            local16 = Cast(c2fb_c_int, &H7FFFFFFFULL)
            local17 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local15 = c2fb_temp_22
            While (-Cast(c2fb_c_int, ((local15 < local3))))
                local18 = CPtr(SqliteFts3TermOffset Ptr, @(local6.aTerm[local15]))
                If (-Cast(c2fb_c_int, (((local18->pList <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_int64, (local18->iPos - local18->iOff))) < Cast(c2fb_int64, local16))))) <> 0))))) Then
                    c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_int64, (local18->iPos - local18->iOff)))
                    local16 = c2fb_temp_24
                    c2fb_temp_25 = local18
                    local17 = c2fb_temp_25
                End If
            c2fb_flow_5:
                c2fb_temp_23 = local15
                local15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_23 + 1)))
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, (local17 = 0))) Then
                c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, 101ULL))
                local2 = c2fb_temp_26
            Else
                ' C unused-parameter annotation
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (Cast(c2fb_c_int, (Cast(c2fb_c_int, &HFEULL) And Cast(c2fb_c_int, (*CPtr(Byte Ptr, local17->pList)))))))))) Then
                    c2fb_temp_27 = CPtr(ZString Ptr Ptr, @(local17->pList))
                    c2fb_temp_28 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_27) = c2fb_temp_28
                Else
                    fts3GetDeltaPosition(CPtr(ZString Ptr Ptr, @(local17->pList)), CPtr(c2fb_int64 Ptr, @(local17->iPos)))
                End If
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local12 < local16)))) <> 0)))))
                    c2fb_temp_29 = Cast(c2fb_c_int, CPtr(c2fb_callback_158, local1->xNext)(local7, CPtr(Const ZString Ptr Ptr, @(local8)), CPtr(c2fb_c_int Ptr, @(local9)), CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_c_int Ptr, @(local11)), CPtr(c2fb_c_int Ptr, @(local12))))
                    local2 = c2fb_temp_29
                c2fb_flow_7:
                Wend
                c2fb_flow_6:
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    ' C automatic array storage
                    c2fb_temp_30 = CPtr(ZString Ptr, sqlite3_snprintf(Cast(c2fb_size_t, (64ULL * SizeOf(Byte))), CPtr(ZString Ptr, CPtr(Byte Ptr, (@local19(0)))), StrPtr(!"%d %d %d %d "), local4, (CPtr(SqliteFts3TermOffset Ptr, local17) - CPtr(SqliteFts3TermOffset Ptr, local6.aTerm)), local10, Cast(c2fb_c_int, (local11 - local10))))
                    c2fb_temp_31 = Cast(c2fb_c_int, fts3StringAppend(CPtr(SqliteFts3StrBuffer Ptr, @(local5)), CPtr(Const ZString Ptr, CPtr(Byte Ptr, (@local19(0)))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
                    local2 = c2fb_temp_31
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 101ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->zContentTbl = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        c2fb_temp_32 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                        local2 = c2fb_temp_32
                    End If
                End If
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 101ULL))))) Then
            c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_33
        End If
        CPtr(c2fb_callback_157, local1->xClose)(local7)
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_label_0
        End If
    c2fb_flow_1:
        c2fb_temp_11 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_label_0:
    sqlite3_free(CPtr(Any Ptr, local6.aTerm))
    ' C unused-parameter annotation
    c2fb_external_sqlite3Fts3SegmentsClose(local0)
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_result_error_code(arg0, local2)
        sqlite3_free(CPtr(Any Ptr, local5.z))
    Else
        sqlite3_result_text(arg0, CPtr(Const ZString Ptr, local5.z), Cast(c2fb_c_int, (local5.n - Cast(c2fb_c_int, 1ULL))), ProcPtr(sqlite3_free))
    End If
    Return
End Sub
Sub sqlite3Fts3Matchinfo CDecl Alias "sqlite3Fts3Matchinfo" (ByVal arg0 As Any Ptr, ByVal arg1 As SqliteFts3Cursor Ptr, ByVal arg2 As Const ZString Ptr)
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 1756
    Dim local0 As SqliteFts3Table Ptr
    Dim local1 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr

    local0 = CPtr(SqliteFts3Table Ptr, arg1->base.pVtab)
    ' C automatic storage declaration
    If arg2 Then
        c2fb_temp_0 = arg2
        local1 = c2fb_temp_0
    Else
        c2fb_temp_1 = StrPtr(!"pcx")
        local1 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, (CPtr(SqliteFts3Expr Ptr, arg1->pExpr) = 0))) Then
        sqlite3_result_blob(arg0, CPtr(Const Any Ptr, StrPtr(!"")), Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr, 0))
        Return
    Else
        fts3GetMatchinfo(arg0, arg1, local1)
        c2fb_external_sqlite3Fts3SegmentsClose(local0)
    End If
End Sub
#endif

/' end of sqlite3_bulk_fts3_snippet.bas '/
