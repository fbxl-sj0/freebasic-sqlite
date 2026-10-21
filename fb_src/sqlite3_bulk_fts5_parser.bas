/'
** 2000-05-29
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
*************************************************************************
'/
/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_bulk_fts5_parser.bas

    Purpose:

        Port the generated Lemon parser used for FTS5 query expressions.

    Responsibilities:

        - Preserve the parser stack and grammar action tables.
        - Implement the FTS5 parser allocation, token shift, reduction, and free ABI.
        - Call the FreeBASIC FTS5 expression routines for grammar actions.

    This file intentionally does NOT contain:

        - The FTS5 grammar source, which remains in ext/fts5/fts5parse.y.
        - FTS5 expression-tree, virtual-table, or tokenizer implementation.
        - The upstream Tcl test adapter.
'/
#ifdef SQLITE_ENABLE_FTS5

#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

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

Type c2fb_callback_1 As Sub CDecl()
Type c2fb_callback_2 As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_16 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As Any Ptr) As c2fb_c_int
Type c2fb_callback_168 As Function CDecl(ByVal arg0 As c2fb_uint64) As Any Ptr

Private Type c2fb_source_record_18
    p As Const ZString Ptr
    n As c2fb_c_int
End Type

Private Union c2fb_source_record_19
    yyinit As c2fb_c_int
    yy0 As c2fb_source_record_18
    yy4 As c2fb_c_int
    yy11 As Any Ptr
    yy24 As Any Ptr
    yy46 As Any Ptr
    yy53 As Any Ptr
End Union

Private Type c2fb_source_record_20
    stateno As UByte
    major As UByte
    minor As c2fb_source_record_19
End Type

Private Type c2fb_source_record_21
    yytos As c2fb_source_record_20 Ptr
    pParse As Any Ptr
    yystackEnd As c2fb_source_record_20 Ptr
    yystack As c2fb_source_record_20 Ptr
    yystk0(0 To 99) As c2fb_source_record_20
End Type

Declare Sub sqlite3Fts5ParserInit CDecl Alias "sqlite3Fts5ParserInit" (ByVal arg0 As Any Ptr)
Declare Function sqlite3Fts5ParserAlloc CDecl Alias "sqlite3Fts5ParserAlloc" (ByVal arg0 As c2fb_callback_168) As Any Ptr
Declare Sub yy_destructor CDecl Alias "yy_destructor" (ByVal arg0 As c2fb_source_record_21 Ptr, ByVal arg1 As UByte, ByVal arg2 As c2fb_source_record_19 Ptr)
Declare Sub yy_pop_parser_stack CDecl Alias "yy_pop_parser_stack" (ByVal arg0 As c2fb_source_record_21 Ptr)
Declare Sub sqlite3Fts5ParserFinalize CDecl Alias "sqlite3Fts5ParserFinalize" (ByVal arg0 As Any Ptr)
Declare Sub sqlite3Fts5ParserFree CDecl Alias "sqlite3Fts5ParserFree" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_callback_2)
Declare Function yy_find_shift_action CDecl Alias "yy_find_shift_action" (ByVal arg0 As UByte, ByVal arg1 As UByte) As UByte
Declare Function yy_find_reduce_action CDecl Alias "yy_find_reduce_action" (ByVal arg0 As UByte, ByVal arg1 As UByte) As UByte
Declare Sub yyStackOverflow CDecl Alias "yyStackOverflow" (ByVal arg0 As c2fb_source_record_21 Ptr)
Declare Sub yy_shift CDecl Alias "yy_shift" (ByVal arg0 As c2fb_source_record_21 Ptr, ByVal arg1 As UByte, ByVal arg2 As UByte, ByVal arg3 As c2fb_source_record_18)
Declare Function yy_reduce CDecl Alias "yy_reduce" (ByVal arg0 As c2fb_source_record_21 Ptr, ByVal arg1 As c2fb_c_uint, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_18) As UByte
Declare Sub yy_syntax_error CDecl Alias "yy_syntax_error" (ByVal arg0 As c2fb_source_record_21 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_18)
Declare Sub yy_accept CDecl Alias "yy_accept" (ByVal arg0 As c2fb_source_record_21 Ptr)
Declare Sub sqlite3Fts5Parser CDecl Alias "sqlite3Fts5Parser" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_18, ByVal arg3 As Any Ptr)
Declare Function sqlite3Fts5ParserFallback CDecl Alias "sqlite3Fts5ParserFallback" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3Fts5ParseError CDecl Alias "sqlite3Fts5ParseError" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Function c2fb_external_sqlite3Fts5ParseNode CDecl Alias "sqlite3Fts5ParseNode" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr, ByVal arg3 As Any Ptr, ByVal arg4 As Any Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3Fts5ParseImplicitAnd CDecl Alias "sqlite3Fts5ParseImplicitAnd" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Any Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3Fts5ParseTerm CDecl Alias "sqlite3Fts5ParseTerm" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_source_record_18 Ptr, ByVal arg3 As c2fb_c_int) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts5ParseSetCaret CDecl Alias "sqlite3Fts5ParseSetCaret" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3Fts5ParseNearset CDecl Alias "sqlite3Fts5ParseNearset" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Any Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3Fts5ParseColset CDecl Alias "sqlite3Fts5ParseColset" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_source_record_18 Ptr) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts5ParsePhraseFree CDecl Alias "sqlite3Fts5ParsePhraseFree" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3Fts5ParseNearsetFree CDecl Alias "sqlite3Fts5ParseNearsetFree" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3Fts5ParseNodeFree CDecl Alias "sqlite3Fts5ParseNodeFree" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3Fts5ParseSetDistance CDecl Alias "sqlite3Fts5ParseSetDistance" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_source_record_18 Ptr)
Declare Sub c2fb_external_sqlite3Fts5ParseSetColset CDecl Alias "sqlite3Fts5ParseSetColset" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Any Ptr)
Declare Function c2fb_external_sqlite3Fts5ParseColsetInvert CDecl Alias "sqlite3Fts5ParseColsetInvert" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts5ParseFinished CDecl Alias "sqlite3Fts5ParseFinished" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr)
Declare Sub c2fb_external_sqlite3Fts5ParseNear CDecl Alias "sqlite3Fts5ParseNear" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_18 Ptr)
/'
    Generated Lemon parser tables
'/
Private Dim Shared c2fb_global_yy_action(0 To 104) As Const UByte = {81, 20, 96, 6, 28, 99, 98, 26, 26, 18, 96, 6, 28, 17, 98, 56, 26, 19, 96, 6, 28, 14, 98, 14, 26, 31, 92, 96, 6, 28, 108, 98, 25, 26, 21, 96, 6, 28, 78, 98, 58, 26, 29, 96, 6, 28, 107, 98, 22, 26, 24, 16, 12, 11, 1, 13, 13, 24, 16, 23, 11, 33, 34, 13, 97, 8, 27, 32, 98, 7, 26, 3, 4, 5, 3, 4, 5, 3, 83, 4, 5, 3, 63, 5, 3, 62, 12, 2, 86, 13, 9, 30, 10, 10, 54, 57, 75, 78, 78, 53, 57, 15, 82, 82, 71}
Private Dim Shared c2fb_global_yy_lookahead(0 To 120) As Const UByte = {16, 17, 18, 19, 20, 22, 22, 24, 24, 17, 18, 19, 20, 7, 22, 9, 24, 17, 18, 19, 20, 9, 22, 9, 24, 13, 17, 18, 19, 20, 26, 22, 24, 24, 17, 18, 19, 20, 15, 22, 9, 24, 17, 18, 19, 20, 26, 22, 21, 24, 6, 7, 9, 9, 10, 12, 12, 6, 7, 21, 9, 24, 25, 12, 18, 5, 20, 14, 22, 5, 24, 3, 1, 2, 3, 1, 2, 3, 0, 1, 2, 3, 11, 2, 3, 11, 9, 10, 5, 12, 23, 24, 10, 10, 8, 9, 9, 15, 15, 8, 9, 9, 27, 27, 11, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27}
Private Dim Shared c2fb_global_yy_shift_ofst(0 To 34) As Const UByte = {44, 44, 44, 44, 44, 44, 51, 77, 43, 12, 14, 83, 82, 14, 23, 23, 31, 31, 71, 74, 78, 81, 86, 91, 6, 53, 53, 60, 64, 68, 53, 87, 92, 53, 93}
Private Dim Shared c2fb_global_yy_reduce_ofst(0 To 17) As Const Byte = {-16, -8, 0, 9, 17, 25, 46, -17, -17, 37, 67, 4, 4, 8, 4, 20, 27, 38}
Private Dim Shared c2fb_global_yy_default(0 To 34) As Const UByte = {80, 80, 80, 80, 80, 80, 95, 80, 80, 105, 80, 110, 110, 80, 110, 110, 80, 80, 80, 80, 80, 91, 80, 80, 80, 101, 100, 80, 80, 90, 103, 80, 80, 104, 80}
Private Dim Shared c2fb_global_yyRuleInfoLhs(0 To 27) As Const UByte = {16, 20, 20, 20, 20, 21, 21, 17, 17, 17, 17, 17, 17, 19, 19, 18, 18, 22, 22, 22, 23, 23, 25, 25, 24, 24, 26, 26}
Private Dim Shared c2fb_global_yyRuleInfoNRhs(0 To 27) As Const Byte = {-1, -4, -3, -1, -2, -2, -1, -3, -3, -3, -5, -3, -1, -1, -2, -1, -3, -1, -2, -5, -1, -2, 0, -2, -4, -2, -1, 0}
/'
    Lemon parser stack and shift/reduce engine
'/
Sub sqlite3Fts5ParserInit CDecl Alias "sqlite3Fts5ParserInit" (ByVal arg0 As Any Ptr)
' c2fb source-path: fts5parse.c
' c2fb source-line: 552
    Dim local0 As c2fb_source_record_21 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_20 Ptr Ptr
    Dim c2fb_temp_1 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_20 Ptr Ptr
    Dim c2fb_temp_3 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_4 As c2fb_source_record_20 Ptr Ptr
    Dim c2fb_temp_5 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As UByte

    local0 = CPtr(c2fb_source_record_21 Ptr, arg0)
    c2fb_temp_0 = CPtr(c2fb_source_record_20 Ptr Ptr, @(local0->yystack))
    c2fb_temp_1 = CPtr(c2fb_source_record_20 Ptr, (@local0->yystk0(0)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_source_record_20 Ptr Ptr, @(local0->yystackEnd))
    c2fb_temp_3 = CPtr(c2fb_source_record_20 Ptr, @(local0->yystack[Cast(c2fb_c_int, (Cast(c2fb_c_int, 100ULL) - Cast(c2fb_c_int, 1ULL)))]))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_source_record_20 Ptr Ptr, @(local0->yytos))
    c2fb_temp_5 = local0->yystack
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(UByte Ptr, @(local0->yystack[Cast(c2fb_c_int, &O0ULL)].stateno))
    c2fb_temp_7 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(UByte Ptr, @(local0->yystack[Cast(c2fb_c_int, &O0ULL)].major))
    c2fb_temp_9 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_8) = c2fb_temp_9
End Sub
Function sqlite3Fts5ParserAlloc CDecl Alias "sqlite3Fts5ParserAlloc" (ByVal arg0 As c2fb_callback_168) As Any Ptr
' c2fb source-path: fts5parse.c
' c2fb source-line: 581
    Dim local0 As c2fb_source_record_21 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_21 Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_21 Ptr, CPtr(Any Ptr, (arg0)(Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_21))))))
    local0 = c2fb_temp_0
    If local0 Then
        sqlite3Fts5ParserInit(CPtr(Any Ptr, local0))
    End If
    Return CPtr(Any Ptr, local0)
End Function
Private Sub yy_destructor CDecl Alias "yy_destructor" (ByVal arg0 As c2fb_source_record_21 Ptr, ByVal arg1 As UByte, ByVal arg2 As c2fb_source_record_19 Ptr)
' c2fb source-path: fts5parse.c
' c2fb source-line: 600
    Dim local0 As Any Ptr

    local0 = arg0->pParse
    Select Case arg1
        Case Cast(c2fb_c_int, 16ULL)
            ' C unused-parameter annotation
        Case Cast(c2fb_c_int, 17ULL), Cast(c2fb_c_int, 18ULL), Cast(c2fb_c_int, 19ULL)
            c2fb_external_sqlite3Fts5ParseNodeFree((arg2->yy24))
        Case Cast(c2fb_c_int, 20ULL), Cast(c2fb_c_int, 21ULL)
            c2fb_external_sqlite3_free((arg2->yy11))
        Case Cast(c2fb_c_int, 22ULL), Cast(c2fb_c_int, 23ULL)
            c2fb_external_sqlite3Fts5ParseNearsetFree((arg2->yy46))
        Case Cast(c2fb_c_int, 24ULL)
            c2fb_external_sqlite3Fts5ParsePhraseFree((arg2->yy53))
        Case Else
    End Select
    c2fb_flow_0:
End Sub
Private Sub yy_pop_parser_stack CDecl Alias "yy_pop_parser_stack" (ByVal arg0 As c2fb_source_record_21 Ptr)
' c2fb source-path: fts5parse.c
' c2fb source-line: 669
    Dim local0 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_20 Ptr Ptr
    Dim c2fb_temp_1 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_20 Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_source_record_20 Ptr Ptr, @(arg0->yytos))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = (c2fb_temp_1 - 1)
    c2fb_temp_2 = c2fb_temp_1
    local0 = c2fb_temp_2
    yy_destructor(arg0, local0->major, CPtr(c2fb_source_record_19 Ptr, @(local0->minor)))
End Sub
Sub sqlite3Fts5ParserFinalize CDecl Alias "sqlite3Fts5ParserFinalize" (ByVal arg0 As Any Ptr)
' c2fb source-path: fts5parse.c
' c2fb source-line: 687
    Dim local0 As c2fb_source_record_21 Ptr
    Dim local1 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_20 Ptr

    local0 = CPtr(c2fb_source_record_21 Ptr, arg0)
    local1 = local0->yytos
    While (-Cast(c2fb_c_int, ((local1 > local0->yystack))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1->major) >= Cast(c2fb_c_int, 16ULL))))) Then
            yy_destructor(local0, local1->major, CPtr(c2fb_source_record_19 Ptr, @(local1->minor)))
        End If
        c2fb_temp_0 = local1
        local1 = (c2fb_temp_0 - 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub
Sub sqlite3Fts5ParserFree CDecl Alias "sqlite3Fts5ParserFree" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_callback_2)
' c2fb source-path: fts5parse.c
' c2fb source-line: 723
    If (-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    sqlite3Fts5ParserFinalize(arg0)
    (arg1)(arg0)
End Sub
Private Function yy_find_shift_action CDecl Alias "yy_find_shift_action" (ByVal arg0 As UByte, ByVal arg1 As UByte) As UByte
' c2fb source-path: fts5parse.c
' c2fb source-line: 786
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) > Cast(c2fb_c_int, 34ULL))))) Then
        Return arg1
    End If
    ' C unused-parameter annotation
    Do
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_global_yy_shift_ofst(arg1))
        local0 = c2fb_temp_0
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, arg0))))
        local0 = c2fb_temp_1
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, c2fb_global_yy_lookahead(local0)) <> Cast(c2fb_c_int, arg0))))) Then
            Return c2fb_global_yy_default(arg1)
        Else
            ' C unused-parameter annotation
            Return c2fb_global_yy_action(local0)
        End If
    c2fb_flow_1:
    Loop While Cast(c2fb_c_int, 1ULL)
    c2fb_flow_0:
End Function
Private Function yy_find_reduce_action CDecl Alias "yy_find_reduce_action" (ByVal arg0 As UByte, ByVal arg1 As UByte) As UByte
' c2fb source-path: fts5parse.c
' c2fb source-line: 851
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_global_yy_reduce_ofst(arg0))
    local0 = c2fb_temp_0
    ' C unused-parameter annotation
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, arg1))))
    local0 = c2fb_temp_1
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    Return c2fb_global_yy_action(local0)
End Function
Private Sub yyStackOverflow CDecl Alias "yyStackOverflow" (ByVal arg0 As c2fb_source_record_21 Ptr)
' c2fb source-path: fts5parse.c
' c2fb source-line: 880
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr

    local0 = arg0->pParse
    While (-Cast(c2fb_c_int, ((arg0->yytos > arg0->yystack))))
        yy_pop_parser_stack(arg0)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3Fts5ParseError(local0, StrPtr(!"fts5: parser stack overflow"))
    c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->pParse))
    c2fb_temp_1 = local0
    (*c2fb_temp_0) = c2fb_temp_1
End Sub
Private Sub yy_shift CDecl Alias "yy_shift" (ByVal arg0 As c2fb_source_record_21 Ptr, ByVal arg1 As UByte, ByVal arg2 As UByte, ByVal arg3 As c2fb_source_record_18)
' c2fb source-path: fts5parse.c
' c2fb source-line: 925
    Dim local0 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_20 Ptr Ptr
    Dim c2fb_temp_1 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_3 As c2fb_source_record_20 Ptr Ptr
    Dim c2fb_temp_4 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_5 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As UByte
    Dim c2fb_temp_9 As UByte Ptr
    Dim c2fb_temp_10 As UByte
    Dim c2fb_temp_11 As c2fb_source_record_18 Ptr
    Dim c2fb_temp_12 As c2fb_source_record_18

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_20 Ptr Ptr, @(arg0->yytos))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = (c2fb_temp_1 + 1)
    c2fb_temp_2 = arg0->yytos
    local0 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local0 > arg0->yystackEnd)))) Then
        If Cast(c2fb_c_int, 1ULL) Then
            c2fb_temp_3 = CPtr(c2fb_source_record_20 Ptr Ptr, @(arg0->yytos))
            c2fb_temp_4 = (*c2fb_temp_3)
            (*c2fb_temp_3) = (c2fb_temp_4 - 1)
            yyStackOverflow(arg0)
            Return
        End If
        c2fb_temp_5 = arg0->yytos
        local0 = c2fb_temp_5
        ' C unused-parameter annotation
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) > Cast(c2fb_c_int, 34ULL))))) Then
        c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, arg1) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 83ULL) - Cast(c2fb_c_int, 52ULL))))))
        arg1 = c2fb_temp_6
    End If
    c2fb_temp_7 = CPtr(UByte Ptr, @(local0->stateno))
    c2fb_temp_8 = Cast(UByte, arg1)
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(UByte Ptr, @(local0->major))
    c2fb_temp_10 = Cast(UByte, arg2)
    (*c2fb_temp_9) = c2fb_temp_10
    c2fb_temp_11 = CPtr(c2fb_source_record_18 Ptr, @(local0->minor.yy0))
    c2fb_temp_12 = arg3
    (*c2fb_temp_11) = c2fb_temp_12
    ' empty C statement
End Sub
Private Function yy_reduce CDecl Alias "yy_reduce" (ByVal arg0 As c2fb_source_record_21 Ptr, ByVal arg1 As c2fb_c_uint, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_18) As UByte
' c2fb source-path: fts5parse.c
' c2fb source-line: 1036
    Dim local0 As c2fb_c_int
    Dim local1 As UByte
    Dim local2 As c2fb_source_record_20 Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As Any Ptr
    Dim c2fb_temp_0 As c2fb_source_record_20 Ptr
    Dim local5 As c2fb_source_record_19
    Dim c2fb_temp_1 As Any Ptr Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Any Ptr Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As Any Ptr Ptr
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As Any Ptr Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As Any Ptr Ptr
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As Any Ptr Ptr
    Dim c2fb_temp_14 As Any Ptr
    Dim c2fb_temp_15 As Any Ptr Ptr
    Dim c2fb_temp_16 As Any Ptr
    Dim c2fb_temp_17 As Any Ptr Ptr
    Dim c2fb_temp_18 As Any Ptr
    Dim c2fb_temp_19 As Any Ptr Ptr
    Dim c2fb_temp_20 As Any Ptr
    Dim c2fb_temp_21 As Any Ptr Ptr
    Dim c2fb_temp_22 As Any Ptr
    Dim c2fb_temp_23 As Any Ptr Ptr
    Dim c2fb_temp_24 As Any Ptr
    Dim c2fb_temp_25 As Any Ptr Ptr
    Dim c2fb_temp_26 As Any Ptr
    Dim c2fb_temp_27 As Any Ptr Ptr
    Dim c2fb_temp_28 As Any Ptr
    Dim c2fb_temp_29 As Any Ptr Ptr
    Dim c2fb_temp_30 As Any Ptr
    Dim c2fb_temp_31 As Any Ptr Ptr
    Dim c2fb_temp_32 As Any Ptr
    Dim c2fb_temp_33 As Any Ptr Ptr
    Dim c2fb_temp_34 As Any Ptr
    Dim c2fb_temp_35 As Any Ptr Ptr
    Dim c2fb_temp_36 As Any Ptr
    Dim c2fb_temp_37 As Any Ptr Ptr
    Dim c2fb_temp_38 As Any Ptr
    Dim c2fb_temp_39 As Any Ptr Ptr
    Dim c2fb_temp_40 As Any Ptr
    Dim c2fb_temp_41 As Any Ptr Ptr
    Dim c2fb_temp_42 As Any Ptr
    Dim c2fb_temp_43 As Any Ptr Ptr
    Dim c2fb_temp_44 As Any Ptr
    Dim c2fb_temp_45 As Any Ptr Ptr
    Dim c2fb_temp_46 As Any Ptr
    Dim c2fb_temp_47 As Any Ptr Ptr
    Dim c2fb_temp_48 As Any Ptr
    Dim c2fb_temp_49 As Any Ptr Ptr
    Dim c2fb_temp_50 As Any Ptr
    Dim c2fb_temp_51 As Any Ptr Ptr
    Dim c2fb_temp_52 As Any Ptr
    Dim c2fb_temp_53 As Any Ptr Ptr
    Dim c2fb_temp_54 As Any Ptr
    Dim c2fb_temp_55 As Any Ptr Ptr
    Dim c2fb_temp_56 As Any Ptr
    Dim c2fb_temp_57 As Any Ptr Ptr
    Dim c2fb_temp_58 As Any Ptr
    Dim c2fb_temp_59 As Any Ptr Ptr
    Dim c2fb_temp_60 As Any Ptr
    Dim c2fb_temp_61 As Any Ptr Ptr
    Dim c2fb_temp_62 As Any Ptr
    Dim c2fb_temp_63 As Any Ptr Ptr
    Dim c2fb_temp_64 As Any Ptr
    Dim c2fb_temp_65 As Any Ptr Ptr
    Dim c2fb_temp_66 As Any Ptr
    Dim c2fb_temp_67 As Any Ptr Ptr
    Dim c2fb_temp_68 As Any Ptr
    Dim c2fb_temp_69 As Any Ptr Ptr
    Dim c2fb_temp_70 As Any Ptr
    Dim c2fb_temp_71 As Any Ptr Ptr
    Dim c2fb_temp_72 As Any Ptr
    Dim c2fb_temp_73 As Const ZString Ptr Ptr
    Dim c2fb_temp_74 As Const ZString Ptr
    Dim c2fb_temp_75 As c2fb_c_int Ptr
    Dim c2fb_temp_76 As c2fb_c_int
    Dim c2fb_temp_77 As c2fb_source_record_18 Ptr
    Dim c2fb_temp_78 As c2fb_source_record_18
    Dim c2fb_temp_79 As Any Ptr Ptr
    Dim c2fb_temp_80 As Any Ptr
    Dim c2fb_temp_81 As Any Ptr Ptr
    Dim c2fb_temp_82 As Any Ptr
    Dim c2fb_temp_83 As Any Ptr Ptr
    Dim c2fb_temp_84 As Any Ptr
    Dim c2fb_temp_85 As Any Ptr Ptr
    Dim c2fb_temp_86 As Any Ptr
    Dim c2fb_temp_87 As c2fb_c_int Ptr
    Dim c2fb_temp_88 As c2fb_c_int
    Dim c2fb_temp_89 As c2fb_c_int Ptr
    Dim c2fb_temp_90 As c2fb_c_int
    Dim c2fb_temp_91 As c2fb_c_int
    Dim c2fb_temp_92 As c2fb_c_int
    Dim c2fb_temp_93 As UByte
    Dim c2fb_temp_94 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_95 As c2fb_source_record_20 Ptr Ptr
    Dim c2fb_temp_96 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_97 As UByte Ptr
    Dim c2fb_temp_98 As UByte
    Dim c2fb_temp_99 As UByte Ptr
    Dim c2fb_temp_100 As UByte

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = arg0->pParse
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = arg0->yytos
    local2 = c2fb_temp_0
    ' C automatic storage declaration
    Select Case arg1
        Case Cast(c2fb_c_int, &O0ULL)
            c2fb_external_sqlite3Fts5ParseFinished(local4, local2[Cast(c2fb_c_int, &O0ULL)].minor.yy24)
        Case Cast(c2fb_c_int, 1ULL)
            c2fb_temp_1 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 3ULL)))].minor.yy11))
            c2fb_temp_2 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseColsetInvert(local4, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy11))
            (*c2fb_temp_1) = c2fb_temp_2
        Case Cast(c2fb_c_int, 2ULL)
            c2fb_temp_3 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy11))
            c2fb_temp_4 = local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy11
            (*c2fb_temp_3) = c2fb_temp_4
        Case Cast(c2fb_c_int, 3ULL)
            c2fb_temp_5 = CPtr(Any Ptr Ptr, @(local5.yy11))
            c2fb_temp_6 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseColset(local4, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy0))))
            (*c2fb_temp_5) = c2fb_temp_6
            c2fb_temp_7 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy11))
            c2fb_temp_8 = local5.yy11
            (*c2fb_temp_7) = c2fb_temp_8
        Case Cast(c2fb_c_int, 4ULL)
            c2fb_temp_9 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy11))
            c2fb_temp_10 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseColset(local4, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy0))))
            (*c2fb_temp_9) = c2fb_temp_10
            c2fb_temp_11 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy11))
            c2fb_temp_12 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseColsetInvert(local4, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy11))
            (*c2fb_temp_11) = c2fb_temp_12
        Case Cast(c2fb_c_int, 5ULL)
            c2fb_temp_13 = CPtr(Any Ptr Ptr, @(local5.yy11))
            c2fb_temp_14 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseColset(local4, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy11, CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy0))))
            (*c2fb_temp_13) = c2fb_temp_14
            c2fb_temp_15 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy11))
            c2fb_temp_16 = local5.yy11
            (*c2fb_temp_15) = c2fb_temp_16
        Case Cast(c2fb_c_int, 6ULL)
            c2fb_temp_17 = CPtr(Any Ptr Ptr, @(local5.yy11))
            c2fb_temp_18 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseColset(local4, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy0))))
            (*c2fb_temp_17) = c2fb_temp_18
            c2fb_temp_19 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy11))
            c2fb_temp_20 = local5.yy11
            (*c2fb_temp_19) = c2fb_temp_20
        Case Cast(c2fb_c_int, 7ULL)
            c2fb_temp_21 = CPtr(Any Ptr Ptr, @(local5.yy24))
            c2fb_temp_22 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNode(local4, Cast(c2fb_c_int, 2ULL), local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy24, local2[Cast(c2fb_c_int, &O0ULL)].minor.yy24, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_21) = c2fb_temp_22
            c2fb_temp_23 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy24))
            c2fb_temp_24 = local5.yy24
            (*c2fb_temp_23) = c2fb_temp_24
        Case Cast(c2fb_c_int, 8ULL)
            c2fb_temp_25 = CPtr(Any Ptr Ptr, @(local5.yy24))
            c2fb_temp_26 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNode(local4, Cast(c2fb_c_int, 1ULL), local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy24, local2[Cast(c2fb_c_int, &O0ULL)].minor.yy24, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_25) = c2fb_temp_26
            c2fb_temp_27 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy24))
            c2fb_temp_28 = local5.yy24
            (*c2fb_temp_27) = c2fb_temp_28
        Case Cast(c2fb_c_int, 9ULL)
            c2fb_temp_29 = CPtr(Any Ptr Ptr, @(local5.yy24))
            c2fb_temp_30 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNode(local4, Cast(c2fb_c_int, 3ULL), local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy24, local2[Cast(c2fb_c_int, &O0ULL)].minor.yy24, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_29) = c2fb_temp_30
            c2fb_temp_31 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy24))
            c2fb_temp_32 = local5.yy24
            (*c2fb_temp_31) = c2fb_temp_32
        Case Cast(c2fb_c_int, 10ULL)
            c2fb_external_sqlite3Fts5ParseSetColset(local4, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy24, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 4ULL)))].minor.yy11)
            c2fb_temp_33 = CPtr(Any Ptr Ptr, @(local5.yy24))
            c2fb_temp_34 = local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy24
            (*c2fb_temp_33) = c2fb_temp_34
            c2fb_temp_35 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 4ULL)))].minor.yy24))
            c2fb_temp_36 = local5.yy24
            (*c2fb_temp_35) = c2fb_temp_36
        Case Cast(c2fb_c_int, 11ULL)
            c2fb_temp_37 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy24))
            c2fb_temp_38 = local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy24
            (*c2fb_temp_37) = c2fb_temp_38
        Case Cast(c2fb_c_int, 12ULL), Cast(c2fb_c_int, 13ULL)
            ' empty C statement
            c2fb_temp_39 = CPtr(Any Ptr Ptr, @(local5.yy24))
            c2fb_temp_40 = local2[Cast(c2fb_c_int, &O0ULL)].minor.yy24
            (*c2fb_temp_39) = c2fb_temp_40
            c2fb_temp_41 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy24))
            c2fb_temp_42 = local5.yy24
            (*c2fb_temp_41) = c2fb_temp_42
        Case Cast(c2fb_c_int, 14ULL)
            c2fb_temp_43 = CPtr(Any Ptr Ptr, @(local5.yy24))
            c2fb_temp_44 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseImplicitAnd(local4, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy24, local2[Cast(c2fb_c_int, &O0ULL)].minor.yy24))
            (*c2fb_temp_43) = c2fb_temp_44
            c2fb_temp_45 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy24))
            c2fb_temp_46 = local5.yy24
            (*c2fb_temp_45) = c2fb_temp_46
        Case Cast(c2fb_c_int, 15ULL)
            c2fb_temp_47 = CPtr(Any Ptr Ptr, @(local5.yy24))
            c2fb_temp_48 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNode(local4, Cast(c2fb_c_int, 9ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), local2[Cast(c2fb_c_int, &O0ULL)].minor.yy46))
            (*c2fb_temp_47) = c2fb_temp_48
            c2fb_temp_49 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy24))
            c2fb_temp_50 = local5.yy24
            (*c2fb_temp_49) = c2fb_temp_50
        Case Cast(c2fb_c_int, 16ULL)
            c2fb_temp_51 = CPtr(Any Ptr Ptr, @(local5.yy24))
            c2fb_temp_52 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNode(local4, Cast(c2fb_c_int, 9ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), local2[Cast(c2fb_c_int, &O0ULL)].minor.yy46))
            (*c2fb_temp_51) = c2fb_temp_52
            c2fb_external_sqlite3Fts5ParseSetColset(local4, local5.yy24, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy11)
            c2fb_temp_53 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy24))
            c2fb_temp_54 = local5.yy24
            (*c2fb_temp_53) = c2fb_temp_54
        Case Cast(c2fb_c_int, 17ULL)
            c2fb_temp_55 = CPtr(Any Ptr Ptr, @(local5.yy46))
            c2fb_temp_56 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNearset(local4, Cast(c2fb_c_int, &O0ULL), local2[Cast(c2fb_c_int, &O0ULL)].minor.yy53))
            (*c2fb_temp_55) = c2fb_temp_56
            c2fb_temp_57 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy46))
            c2fb_temp_58 = local5.yy46
            (*c2fb_temp_57) = c2fb_temp_58
        Case Cast(c2fb_c_int, 18ULL)
            c2fb_external_sqlite3Fts5ParseSetCaret(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy53)
            c2fb_temp_59 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy46))
            c2fb_temp_60 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNearset(local4, Cast(c2fb_c_int, &O0ULL), local2[Cast(c2fb_c_int, &O0ULL)].minor.yy53))
            (*c2fb_temp_59) = c2fb_temp_60
        Case Cast(c2fb_c_int, 19ULL)
            c2fb_external_sqlite3Fts5ParseNear(local4, CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 4ULL)))].minor.yy0)))
            c2fb_external_sqlite3Fts5ParseSetDistance(local4, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy46, CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy0)))
            c2fb_temp_61 = CPtr(Any Ptr Ptr, @(local5.yy46))
            c2fb_temp_62 = local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL)))].minor.yy46
            (*c2fb_temp_61) = c2fb_temp_62
            c2fb_temp_63 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 4ULL)))].minor.yy46))
            c2fb_temp_64 = local5.yy46
            (*c2fb_temp_63) = c2fb_temp_64
        Case Cast(c2fb_c_int, 20ULL)
            c2fb_temp_65 = CPtr(Any Ptr Ptr, @(local5.yy46))
            c2fb_temp_66 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNearset(local4, Cast(c2fb_c_int, &O0ULL), local2[Cast(c2fb_c_int, &O0ULL)].minor.yy53))
            (*c2fb_temp_65) = c2fb_temp_66
            c2fb_temp_67 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy46))
            c2fb_temp_68 = local5.yy46
            (*c2fb_temp_67) = c2fb_temp_68
        Case Cast(c2fb_c_int, 21ULL)
            c2fb_temp_69 = CPtr(Any Ptr Ptr, @(local5.yy46))
            c2fb_temp_70 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseNearset(local4, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy46, local2[Cast(c2fb_c_int, &O0ULL)].minor.yy53))
            (*c2fb_temp_69) = c2fb_temp_70
            c2fb_temp_71 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy46))
            c2fb_temp_72 = local5.yy46
            (*c2fb_temp_71) = c2fb_temp_72
        Case Cast(c2fb_c_int, 22ULL)
            c2fb_temp_73 = CPtr(Const ZString Ptr Ptr, @(local2[Cast(c2fb_c_int, 1ULL)].minor.yy0.p))
            c2fb_temp_74 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_73) = c2fb_temp_74
            c2fb_temp_75 = CPtr(c2fb_c_int Ptr, @(local2[Cast(c2fb_c_int, 1ULL)].minor.yy0.n))
            c2fb_temp_76 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_75) = c2fb_temp_76
        Case Cast(c2fb_c_int, 23ULL)
            c2fb_temp_77 = CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy0))
            c2fb_temp_78 = local2[Cast(c2fb_c_int, &O0ULL)].minor.yy0
            (*c2fb_temp_77) = c2fb_temp_78
        Case Cast(c2fb_c_int, 24ULL)
            c2fb_temp_79 = CPtr(Any Ptr Ptr, @(local5.yy53))
            c2fb_temp_80 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseTerm(local4, local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 3ULL)))].minor.yy53, CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy0)), local2[Cast(c2fb_c_int, &O0ULL)].minor.yy4))
            (*c2fb_temp_79) = c2fb_temp_80
            c2fb_temp_81 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 3ULL)))].minor.yy53))
            c2fb_temp_82 = local5.yy53
            (*c2fb_temp_81) = c2fb_temp_82
        Case Cast(c2fb_c_int, 25ULL)
            c2fb_temp_83 = CPtr(Any Ptr Ptr, @(local5.yy53))
            c2fb_temp_84 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParseTerm(local4, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_source_record_18 Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy0)), local2[Cast(c2fb_c_int, &O0ULL)].minor.yy4))
            (*c2fb_temp_83) = c2fb_temp_84
            c2fb_temp_85 = CPtr(Any Ptr Ptr, @(local2[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].minor.yy53))
            c2fb_temp_86 = local5.yy53
            (*c2fb_temp_85) = c2fb_temp_86
        Case Cast(c2fb_c_int, 26ULL)
            c2fb_temp_87 = CPtr(c2fb_c_int Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)].minor.yy4))
            c2fb_temp_88 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_87) = c2fb_temp_88
        Case Cast(c2fb_c_int, 27ULL)
            c2fb_temp_89 = CPtr(c2fb_c_int Ptr, @(local2[Cast(c2fb_c_int, 1ULL)].minor.yy4))
            c2fb_temp_90 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_89) = c2fb_temp_90
        Case Else
    End Select
    c2fb_flow_0:
    ' empty C statement
    ' C unused-parameter annotation
    c2fb_temp_91 = Cast(c2fb_c_int, c2fb_global_yyRuleInfoLhs(arg1))
    local0 = c2fb_temp_91
    c2fb_temp_92 = Cast(c2fb_c_int, c2fb_global_yyRuleInfoNRhs(arg1))
    local3 = c2fb_temp_92
    c2fb_temp_93 = Cast(UByte, yy_find_reduce_action(local2[local3].stateno, Cast(UByte, local0)))
    local1 = c2fb_temp_93
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_94 = CPtr(c2fb_source_record_20 Ptr, (local2 + Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL)))))
    local2 = c2fb_temp_94
    c2fb_temp_95 = CPtr(c2fb_source_record_20 Ptr Ptr, @(arg0->yytos))
    c2fb_temp_96 = local2
    (*c2fb_temp_95) = c2fb_temp_96
    c2fb_temp_97 = CPtr(UByte Ptr, @(local2->stateno))
    c2fb_temp_98 = Cast(UByte, Cast(UByte, local1))
    (*c2fb_temp_97) = c2fb_temp_98
    c2fb_temp_99 = CPtr(UByte Ptr, @(local2->major))
    c2fb_temp_100 = Cast(UByte, Cast(UByte, local0))
    (*c2fb_temp_99) = c2fb_temp_100
    ' empty C statement
    Return local1
End Function
Private Sub yy_syntax_error CDecl Alias "yy_syntax_error" (ByVal arg0 As c2fb_source_record_21 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_18)
' c2fb source-path: fts5parse.c
' c2fb source-line: 1308
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr

    local0 = arg0->pParse
    ' C unused-parameter annotation
    c2fb_external_sqlite3Fts5ParseError(local0, StrPtr(!"fts5: syntax error near \034%.*s\034"), arg2.n, arg2.p)
    c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->pParse))
    c2fb_temp_1 = local0
    (*c2fb_temp_0) = c2fb_temp_1
End Sub
Private Sub yy_accept CDecl Alias "yy_accept" (ByVal arg0 As c2fb_source_record_21 Ptr)
' c2fb source-path: fts5parse.c
' c2fb source-line: 1332
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr

    local0 = arg0->pParse
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->pParse))
    c2fb_temp_1 = local0
    (*c2fb_temp_0) = c2fb_temp_1
End Sub
Sub sqlite3Fts5Parser CDecl Alias "sqlite3Fts5Parser" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_18, ByVal arg3 As Any Ptr)
' c2fb source-path: fts5parse.c
' c2fb source-line: 1373
    Dim local0 As c2fb_source_record_19
    Dim local1 As UByte
    Dim local2 As c2fb_source_record_21 Ptr
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As UByte
    Dim c2fb_temp_3 As UByte
    Dim local3 As c2fb_c_uint
    Dim c2fb_temp_4 As UByte
    Dim c2fb_temp_5 As c2fb_source_record_20 Ptr Ptr
    Dim c2fb_temp_6 As c2fb_source_record_20 Ptr
    Dim c2fb_temp_7 As c2fb_source_record_18 Ptr
    Dim c2fb_temp_8 As c2fb_source_record_18

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = CPtr(c2fb_source_record_21 Ptr, arg0)
    c2fb_temp_0 = CPtr(Any Ptr Ptr, @(local2->pParse))
    c2fb_temp_1 = arg3
    (*c2fb_temp_0) = c2fb_temp_1
    ' C unused-parameter annotation
    c2fb_temp_2 = Cast(UByte, local2->yytos->stateno)
    local1 = c2fb_temp_2
    While Cast(c2fb_c_int, 1ULL)
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        c2fb_temp_3 = Cast(UByte, yy_find_shift_action(Cast(UByte, arg1), local1))
        local1 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) >= Cast(c2fb_c_int, 83ULL))))) Then
            local3 = Cast(c2fb_c_int, (Cast(c2fb_c_int, local1) - Cast(c2fb_c_int, 83ULL)))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, c2fb_global_yyRuleInfoNRhs(local3)) = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((local2->yytos >= local2->yystackEnd)))) Then
                    If Cast(c2fb_c_int, 1ULL) Then
                        yyStackOverflow(local2)
                        Goto c2fb_flow_0
                    End If
                End If
            End If
            c2fb_temp_4 = Cast(UByte, yy_reduce(local2, local3, arg1, arg2))
            local1 = c2fb_temp_4
        Else
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) <= Cast(c2fb_c_int, 79ULL))))) Then
                yy_shift(local2, local1, Cast(UByte, arg1), arg2)
                Goto c2fb_flow_0
            Else
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, 81ULL))))) Then
                    c2fb_temp_5 = CPtr(c2fb_source_record_20 Ptr Ptr, @(local2->yytos))
                    c2fb_temp_6 = (*c2fb_temp_5)
                    (*c2fb_temp_5) = (c2fb_temp_6 - 1)
                    yy_accept(local2)
                    Return
                Else
                    ' C unused-parameter annotation
                    c2fb_temp_7 = CPtr(c2fb_source_record_18 Ptr, @(local0.yy0))
                    c2fb_temp_8 = arg2
                    (*c2fb_temp_7) = c2fb_temp_8
                    yy_syntax_error(local2, arg1, arg2)
                    yy_destructor(local2, Cast(UByte, arg1), CPtr(c2fb_source_record_19 Ptr, @(local0)))
                    Goto c2fb_flow_0
                End If
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return
End Sub
Function sqlite3Fts5ParserFallback CDecl Alias "sqlite3Fts5ParserFallback" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: fts5parse.c
' c2fb source-line: 1583
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, &O0ULL)
End Function

#endif

/' end of sqlite3_bulk_fts5_parser.bas '/
