/'
** 2008 Nov 28
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
** This module contains code that implements a parser for fts3 query strings
** (the right-hand argument to the MATCH operator). Because the supported 
** syntax is relatively simple, the whole tokenizer/parser system is
** hand-coded. 
'/
/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_bulk_fts3_expr_candidates.bas

    Purpose:

        Hold translated candidates from ext/fts3/fts3_expr.c for dependency repair.

    Responsibilities:

        - Parse, compare, and iterate FTS3 expression trees.
        - Keep expression evaluation separate from on-disk segment operations.

    This file intentionally does NOT contain:

        - The shared FTS3 private declarations needed by its callers.
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
/' FTS3 expression-tree evaluation candidates                                '/
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

Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)

Private Type c2fb_source_record_88
    eType As c2fb_c_int
    nNear As c2fb_c_int
    pParent As c2fb_source_record_88 Ptr
    pLeft As c2fb_source_record_88 Ptr
    pRight As c2fb_source_record_88 Ptr
    pPhrase As Any Ptr
    iDocid As c2fb_int64
    bEof As UByte
    bStart As UByte
    bDeferred As UByte
    iPhrase As c2fb_c_int
    aMI As c2fb_c_uint Ptr
End Type

Declare Function fts3isspace CDecl Alias "fts3isspace" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function sqlite3Fts3MallocZero CDecl Alias "sqlite3Fts3MallocZero" (ByVal arg0 As c2fb_int64) As Any Ptr
Declare Function findBarredChar CDecl Alias "findBarredChar" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3ReallocOrFree CDecl Alias "fts3ReallocOrFree" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function opPrecedence CDecl Alias "opPrecedence" (ByVal arg0 As c2fb_source_record_88 Ptr) As c2fb_c_int
Declare Sub insertBinaryOperator CDecl Alias "insertBinaryOperator" (ByVal arg0 As c2fb_source_record_88 Ptr Ptr, ByVal arg1 As c2fb_source_record_88 Ptr, ByVal arg2 As c2fb_source_record_88 Ptr)
Declare Function fts3ExprCheckDepth CDecl Alias "fts3ExprCheckDepth" (ByVal arg0 As c2fb_source_record_88 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3ExprBalance CDecl Alias "fts3ExprBalance" (ByVal arg0 As c2fb_source_record_88 Ptr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub fts3FreeExprNode CDecl Alias "fts3FreeExprNode" (ByVal arg0 As c2fb_source_record_88 Ptr)
Declare Sub sqlite3Fts3ExprFree CDecl Alias "sqlite3Fts3ExprFree" (ByVal arg0 As c2fb_source_record_88 Ptr)
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
Private Function fts3isspace CDecl Alias "fts3isspace" (ByVal arg0 As Byte) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
    Return (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 32))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 9))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 10))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 13))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 11))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 12))))) <> 0)))))
End Function
Function sqlite3Fts3MallocZero CDecl Alias "sqlite3Fts3MallocZero" (ByVal arg0 As c2fb_int64) As Any Ptr
' c2fb source-path: ext/fts3/fts3_expr.c
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As Any Ptr

    local0 = CPtr(Any Ptr, sqlite3_malloc64(arg0))
    If local0 Then
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(local0, Cast(c2fb_c_int, &O0ULL), arg0))
    End If
    Return local0
End Function
' c2fb skipped sqlite3Fts3OpenTokenizer: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3Fts3OpenTokenizer: assignment parser stopped at byte 13 (rc = pModule->xOpen(pTokenizer, z, n, &pCsr)): ->xOpen(pTokenizer, z, n, &pCsr)
Private Function findBarredChar CDecl Alias "findBarredChar" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local0]) = Cast(c2fb_c_int, 34)))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local0]) = Cast(c2fb_c_int, 40))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local0]) = Cast(c2fb_c_int, 41))))) <> 0)))))) <> 0)))))) <> 0))))) Then
            Return local0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
End Function
' c2fb skipped getNextToken: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: getNextToken: assignment parser stopped at byte 13 (rc = pModule->xNext(pCursor, &zToken, &nToken, &iStart, &iEnd, &iPosition)): ->xNext(pCursor, &zToken, &nToken, &iStart, &iEnd, &iPosition)
Private Function fts3ReallocOrFree CDecl Alias "fts3ReallocOrFree" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
' c2fb source-path: ext/fts3/fts3_expr.c
    Dim local0 As Any Ptr

    local0 = CPtr(Any Ptr, sqlite3_realloc64(arg0, arg1))
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        sqlite3_free(arg0)
    End If
    Return local0
End Function
' c2fb skipped getNextString: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: getNextString: expression parser stopped at byte 60 in (sizeof(Fts3Expr) + (__builtin_offsetof (Fts3Phrase, aToken)+(1)*sizeof(Fts3PhraseToken))): +(1)*sizeof(Fts3PhraseToken))
' c2fb skipped getNextNode: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: getNextNode: expression parser stopped at byte 41 in (ii<(int)(sizeof(aKeyword)/sizeof(struct Fts3Keyword))): Fts3Keyword))
Private Function opPrecedence CDecl Alias "opPrecedence" (ByVal arg0 As c2fb_source_record_88 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
    ' C unused-parameter annotation
    If Cast(c2fb_c_int, &O0ULL) Then
        Return arg0->eType
    Else
        If (-Cast(c2fb_c_int, ((arg0->eType = Cast(c2fb_c_int, 1ULL))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        Else
            If (-Cast(c2fb_c_int, ((arg0->eType = Cast(c2fb_c_int, 4ULL))))) Then
                Return Cast(c2fb_c_int, 2ULL)
            End If
        End If
    End If
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, 3ULL)
End Function
Private Sub insertBinaryOperator CDecl Alias "insertBinaryOperator" (ByVal arg0 As c2fb_source_record_88 Ptr Ptr, ByVal arg1 As c2fb_source_record_88 Ptr, ByVal arg2 As c2fb_source_record_88 Ptr)
' c2fb source-path: ext/fts3/fts3_expr.c
    Dim local0 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_2 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_3 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_4 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_5 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_6 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_7 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_8 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_9 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_10 As c2fb_source_record_88 Ptr

    local0 = arg1
    While (-Cast(c2fb_c_int, (((local0->pParent <> 0) AndAlso ((-Cast(c2fb_c_int, ((opPrecedence(local0->pParent) <= opPrecedence(arg2))))) <> 0)))))
        c2fb_temp_0 = local0->pParent
        local0 = c2fb_temp_0
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If local0->pParent Then
        ' C unused-parameter annotation
        c2fb_temp_1 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local0->pParent->pRight))
        c2fb_temp_2 = arg2
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_source_record_88 Ptr Ptr, @(arg2->pParent))
        c2fb_temp_4 = local0->pParent
        (*c2fb_temp_3) = c2fb_temp_4
    Else
        c2fb_temp_5 = CPtr(c2fb_source_record_88 Ptr Ptr, @((*arg0)))
        c2fb_temp_6 = arg2
        (*c2fb_temp_5) = c2fb_temp_6
    End If
    c2fb_temp_7 = CPtr(c2fb_source_record_88 Ptr Ptr, @(arg2->pLeft))
    c2fb_temp_8 = local0
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local0->pParent))
    c2fb_temp_10 = arg2
    (*c2fb_temp_9) = c2fb_temp_10
End Sub
' c2fb skipped fts3ExprParse: requires unconverted C function getNextNode
Private Function fts3ExprCheckDepth CDecl Alias "fts3ExprCheckDepth" (ByVal arg0 As c2fb_source_record_88 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0 Then
        If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 18ULL))
            local0 = c2fb_temp_0
        Else
            c2fb_temp_1 = Cast(c2fb_c_int, fts3ExprCheckDepth(arg0->pLeft, Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
            local0 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, fts3ExprCheckDepth(arg0->pRight, Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
                local0 = c2fb_temp_2
            End If
        End If
    End If
    Return local0
End Function
Private Function fts3ExprBalance CDecl Alias "fts3ExprBalance" (ByVal arg0 As c2fb_source_record_88 Ptr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_88 Ptr
    Dim local2 As c2fb_source_record_88 Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local4 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_1 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_4 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_5 As c2fb_source_record_88 Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_6 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_7 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_8 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_9 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_10 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_15 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_16 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_17 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_18 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_19 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_20 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_21 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_22 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_23 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_24 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_25 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_26 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_27 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_28 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_29 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_30 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_33 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_34 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_35 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_36 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_37 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_38 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_39 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_40 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_41 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_42 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_46 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_47 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_48 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_49 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_50 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_51 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_52 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_53 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_54 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_55 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_56 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_57 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_58 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_59 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_60 As c2fb_source_record_88 Ptr
    Dim local9 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_61 As c2fb_c_int
    Dim c2fb_temp_62 As c2fb_c_int
    Dim c2fb_temp_63 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_64 As c2fb_source_record_88 Ptr
    Dim local10 As c2fb_source_record_88 Ptr
    Dim local11 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_65 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_66 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_67 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_68 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_69 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_70 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_71 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_72 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_73 As c2fb_c_int
    Dim c2fb_temp_74 As c2fb_c_int
    Dim c2fb_temp_75 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_76 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_77 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_78 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_79 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_80 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_81 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_82 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_83 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_84 As c2fb_source_record_88 Ptr Ptr
    Dim c2fb_temp_85 As c2fb_source_record_88 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (*arg0)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = local1->eType
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 4ULL))))) <> 0)))))) Then
            ' C automatic storage declaration
            c2fb_temp_1 = CPtr(c2fb_source_record_88 Ptr Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_88 Ptr))) * Cast(c2fb_uint64, arg1))))))
            local4 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local4)))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_2
            Else
                c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local4), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_88 Ptr))) * Cast(c2fb_uint64, arg1)))))
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_4 = local1
                local6 = c2fb_temp_4
                While (-Cast(c2fb_c_int, ((local6->eType = local3))))
                    ' C unused-parameter annotation
                    ' C unused-parameter annotation
                c2fb_flow_1:
                    c2fb_temp_5 = local6->pLeft
                    local6 = c2fb_temp_5
                Wend
                c2fb_flow_0:
                While Cast(c2fb_c_int, 1ULL)
                    ' C automatic storage declaration
                    local8 = local6->pParent
                    ' C unused-parameter annotation
                    c2fb_temp_6 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local6->pParent))
                    c2fb_temp_7 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_6) = c2fb_temp_7
                    If local8 Then
                        c2fb_temp_8 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local8->pLeft))
                        c2fb_temp_9 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                        (*c2fb_temp_8) = c2fb_temp_9
                    Else
                        c2fb_temp_10 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                        local1 = c2fb_temp_10
                    End If
                    c2fb_temp_11 = Cast(c2fb_c_int, fts3ExprBalance(CPtr(c2fb_source_record_88 Ptr Ptr, @(local6)), Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
                    local0 = c2fb_temp_11
                    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_2
                    End If
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local7 = c2fb_temp_12
                    While (-Cast(c2fb_c_int, (((local6 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 < arg1)))) <> 0)))))
                        If (-Cast(c2fb_c_int, ((local4[local7] = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_14 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local4[local7]))
                            c2fb_temp_15 = local6
                            (*c2fb_temp_14) = c2fb_temp_15
                            c2fb_temp_16 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local6 = c2fb_temp_16
                        Else
                            ' C unused-parameter annotation
                            c2fb_temp_17 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local2->pLeft))
                            c2fb_temp_18 = local4[local7]
                            (*c2fb_temp_17) = c2fb_temp_18
                            c2fb_temp_19 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local2->pRight))
                            c2fb_temp_20 = local6
                            (*c2fb_temp_19) = c2fb_temp_20
                            c2fb_temp_21 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local2->pLeft->pParent))
                            c2fb_temp_22 = local2
                            (*c2fb_temp_21) = c2fb_temp_22
                            c2fb_temp_23 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local2->pRight->pParent))
                            c2fb_temp_24 = local2
                            (*c2fb_temp_23) = c2fb_temp_24
                            c2fb_temp_25 = local2
                            local6 = c2fb_temp_25
                            c2fb_temp_26 = local2->pParent
                            local2 = c2fb_temp_26
                            c2fb_temp_27 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local6->pParent))
                            c2fb_temp_28 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            (*c2fb_temp_27) = c2fb_temp_28
                            c2fb_temp_29 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local4[local7]))
                            c2fb_temp_30 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            (*c2fb_temp_29) = c2fb_temp_30
                        End If
                    c2fb_flow_5:
                        c2fb_temp_13 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                    Wend
                    c2fb_flow_4:
                    If local6 Then
                        sqlite3Fts3ExprFree(local6)
                        c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, 18ULL))
                        local0 = c2fb_temp_31
                        Goto c2fb_flow_2
                    End If
                    If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_2
                    End If
                    c2fb_temp_32 = local8->pRight
                    local6 = c2fb_temp_32
                    While (-Cast(c2fb_c_int, ((local6->eType = local3))))
                        ' empty C statement
                    c2fb_flow_7:
                        c2fb_temp_33 = local6->pLeft
                        local6 = c2fb_temp_33
                    Wend
                    c2fb_flow_6:
                    ' C unused-parameter annotation
                    c2fb_temp_34 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local8->pRight->pParent))
                    c2fb_temp_35 = local8->pParent
                    (*c2fb_temp_34) = c2fb_temp_35
                    If local8->pParent Then
                        c2fb_temp_36 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local8->pParent->pLeft))
                        c2fb_temp_37 = local8->pRight
                        (*c2fb_temp_36) = c2fb_temp_37
                    Else
                        ' C unused-parameter annotation
                        c2fb_temp_38 = local8->pRight
                        local1 = c2fb_temp_38
                    End If
                    c2fb_temp_39 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local8->pParent))
                    c2fb_temp_40 = local2
                    (*c2fb_temp_39) = c2fb_temp_40
                    c2fb_temp_41 = local8
                    local2 = c2fb_temp_41
                c2fb_flow_3:
                Wend
                c2fb_flow_2:
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_42 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local6 = c2fb_temp_42
                    c2fb_temp_43 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local5 = c2fb_temp_43
                    While (-Cast(c2fb_c_int, ((local5 < arg1))))
                        If local4[local5] Then
                            If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_45 = local4[local5]
                                local6 = c2fb_temp_45
                                c2fb_temp_46 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local6->pParent))
                                c2fb_temp_47 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                                (*c2fb_temp_46) = c2fb_temp_47
                            Else
                                ' C unused-parameter annotation
                                c2fb_temp_48 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local2->pRight))
                                c2fb_temp_49 = local6
                                (*c2fb_temp_48) = c2fb_temp_49
                                c2fb_temp_50 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local2->pLeft))
                                c2fb_temp_51 = local4[local5]
                                (*c2fb_temp_50) = c2fb_temp_51
                                c2fb_temp_52 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local2->pLeft->pParent))
                                c2fb_temp_53 = local2
                                (*c2fb_temp_52) = c2fb_temp_53
                                c2fb_temp_54 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local2->pRight->pParent))
                                c2fb_temp_55 = local2
                                (*c2fb_temp_54) = c2fb_temp_55
                                c2fb_temp_56 = local2
                                local6 = c2fb_temp_56
                                c2fb_temp_57 = local2->pParent
                                local2 = c2fb_temp_57
                                c2fb_temp_58 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local6->pParent))
                                c2fb_temp_59 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                                (*c2fb_temp_58) = c2fb_temp_59
                            End If
                        End If
                    c2fb_flow_9:
                        c2fb_temp_44 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_44 + 1)))
                    Wend
                    c2fb_flow_8:
                    c2fb_temp_60 = local6
                    local1 = c2fb_temp_60
                Else
                    ' C automatic storage declaration
                    c2fb_temp_61 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local5 = c2fb_temp_61
                    While (-Cast(c2fb_c_int, ((local5 < arg1))))
                        sqlite3Fts3ExprFree(local4[local5])
                    c2fb_flow_11:
                        c2fb_temp_62 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_62 + 1)))
                    Wend
                    c2fb_flow_10:
                    Do
                        c2fb_temp_63 = local2
                        local9 = c2fb_temp_63
                        If ((-Cast(c2fb_c_int, (((c2fb_temp_63) <> Cast(c2fb_c_int, &O0ULL))))) = 0) Then Goto c2fb_flow_12
                        c2fb_temp_64 = local9->pParent
                        local2 = c2fb_temp_64
                        sqlite3_free(CPtr(Any Ptr, local9))
                    c2fb_flow_13:
                    Loop
                    c2fb_flow_12:
                End If
                ' C unused-parameter annotation
                sqlite3_free(CPtr(Any Ptr, local4))
            End If
        Else
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 2ULL))))) Then
                local10 = local1->pLeft
                local11 = local1->pRight
                c2fb_temp_65 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local1->pLeft))
                c2fb_temp_66 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_65) = c2fb_temp_66
                c2fb_temp_67 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local1->pRight))
                c2fb_temp_68 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_67) = c2fb_temp_68
                c2fb_temp_69 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local10->pParent))
                c2fb_temp_70 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_69) = c2fb_temp_70
                c2fb_temp_71 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local11->pParent))
                c2fb_temp_72 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_71) = c2fb_temp_72
                c2fb_temp_73 = Cast(c2fb_c_int, fts3ExprBalance(CPtr(c2fb_source_record_88 Ptr Ptr, @(local10)), Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
                local0 = c2fb_temp_73
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_74 = Cast(c2fb_c_int, fts3ExprBalance(CPtr(c2fb_source_record_88 Ptr Ptr, @(local11)), Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
                    local0 = c2fb_temp_74
                End If
                If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    sqlite3Fts3ExprFree(local11)
                    sqlite3Fts3ExprFree(local10)
                Else
                    ' C unused-parameter annotation
                    c2fb_temp_75 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local1->pLeft))
                    c2fb_temp_76 = local10
                    (*c2fb_temp_75) = c2fb_temp_76
                    c2fb_temp_77 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local10->pParent))
                    c2fb_temp_78 = local1
                    (*c2fb_temp_77) = c2fb_temp_78
                    c2fb_temp_79 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local1->pRight))
                    c2fb_temp_80 = local11
                    (*c2fb_temp_79) = c2fb_temp_80
                    c2fb_temp_81 = CPtr(c2fb_source_record_88 Ptr Ptr, @(local11->pParent))
                    c2fb_temp_82 = local1
                    (*c2fb_temp_81) = c2fb_temp_82
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3Fts3ExprFree(local1)
        c2fb_temp_83 = CPtr(c2fb_source_record_88 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_83
    End If
    c2fb_temp_84 = CPtr(c2fb_source_record_88 Ptr Ptr, @((*arg0)))
    c2fb_temp_85 = local1
    (*c2fb_temp_84) = c2fb_temp_85
    Return local0
End Function
' c2fb skipped fts3ExprParseUnbalanced: requires unconverted C function fts3ExprParse
' c2fb skipped sqlite3Fts3ExprParse: requires unconverted C function fts3ExprParseUnbalanced
Private Sub fts3FreeExprNode CDecl Alias "fts3FreeExprNode" (ByVal arg0 As c2fb_source_record_88 Ptr)
' c2fb source-path: ext/fts3/fts3_expr.c
    ' C unused-parameter annotation
    sqlite3Fts3EvalPhraseCleanup(arg0->pPhrase)
    sqlite3_free(CPtr(Any Ptr, arg0->aMI))
    sqlite3_free(CPtr(Any Ptr, arg0))
End Sub
Sub sqlite3Fts3ExprFree CDecl Alias "sqlite3Fts3ExprFree" (ByVal arg0 As c2fb_source_record_88 Ptr)
' c2fb source-path: ext/fts3/fts3_expr.c
    Dim local0 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_88 Ptr
    Dim local1 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_3 As c2fb_source_record_88 Ptr
    Dim c2fb_temp_4 As c2fb_source_record_88 Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = arg0
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso (((-Cast(c2fb_c_int, (((local0->pLeft <> 0) OrElse (local0->pRight <> 0)))))) <> 0)))))
        ' C unused-parameter annotation
    c2fb_flow_1:
        c2fb_temp_1 = (IIf(local0->pLeft, local0->pLeft, local0->pRight))
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    While local0
        local1 = local0->pParent
        fts3FreeExprNode(local0)
        If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = local1->pLeft)))) <> 0) AndAlso (local1->pRight <> 0))))) Then
            c2fb_temp_2 = local1->pRight
            local0 = c2fb_temp_2
            While (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso (((-Cast(c2fb_c_int, (((local0->pLeft <> 0) OrElse (local0->pRight <> 0)))))) <> 0)))))
                ' C unused-parameter annotation
                c2fb_temp_3 = (IIf(local0->pLeft, local0->pLeft, local0->pRight))
                local0 = c2fb_temp_3
            c2fb_flow_5:
            Wend
            c2fb_flow_4:
        Else
            c2fb_temp_4 = local1
            local0 = c2fb_temp_4
        End If
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
End Sub
#endif

/' end of fts3_candidates/sqlite3_bulk_fts3_expr_candidates.bas '/
