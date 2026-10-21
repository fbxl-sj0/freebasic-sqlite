/'
** 2014 May 31
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

    File: sqlite3_bulk_fts5_aux.bas

    Purpose:

        Port built-in FTS5 auxiliary functions and registration helpers.

    Responsibilities:

        - Implement snippet, highlight, bm25, and locale auxiliary functions.
        - Adapt tokenizer and extension callbacks to FTS5's extension API.
        - Register the built-in auxiliary functions with an FTS5 API handle.

    This file intentionally does NOT contain:

        - FTS5 virtual-table module registration.
        - The upstream Tcl test adapter.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "crt/math.bi"
#include once "sqlite3_fts5_aux_types.bi"

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


Type c2fb_sqlite3_destructor_type As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_7 As Function CDecl(ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As Const c2fb_sqlite3_api_routines Ptr) As c2fb_c_int
Type c2fb_callback_8 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr) As c2fb_c_int
Type c2fb_callback_9 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Type c2fb_callback_70 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr) As c2fb_c_int
Type c2fb_callback_71 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Type c2fb_callback_72 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Type c2fb_callback_75 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_76 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_77 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_79 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_80 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_73 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_81 As Function CDecl(ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As Any Ptr) As c2fb_c_int
Type c2fb_callback_82 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_81) As c2fb_c_int
Type c2fb_callback_83 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Type c2fb_callback_84 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int) As Any Ptr
Type c2fb_callback_90 As Function CDecl(ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Any Ptr, ByVal arg6 As c2fb_callback_73) As c2fb_c_int

Private Function __c2fb_double_value(ByVal value As Double) As Double
    Return value
End Function
Declare Function fts5CInstIterNext CDecl Alias "fts5CInstIterNext" (ByVal arg0 As c2fb_CInstIter Ptr) As c2fb_c_int
Declare Function fts5CInstIterInit CDecl Alias "fts5CInstIterInit" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_CInstIter Ptr) As c2fb_c_int
Declare Sub fts5HighlightAppend CDecl Alias "fts5HighlightAppend" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_HighlightContext Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int)
Declare Function fts5HighlightCb CDecl Alias "fts5HighlightCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function fts5ValueClampedInt CDecl Alias "fts5ValueClampedInt" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Sub fts5HighlightFunction CDecl Alias "fts5HighlightFunction" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
Declare Function fts5SentenceFinderAdd CDecl Alias "fts5SentenceFinderAdd" (ByVal arg0 As c2fb_Fts5SFinder Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5SentenceFinderCb CDecl Alias "fts5SentenceFinderCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function fts5SnippetScore CDecl Alias "fts5SnippetScore" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ValueToText CDecl Alias "fts5ValueToText" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const ZString Ptr
Declare Sub fts5SnippetFunction CDecl Alias "fts5SnippetFunction" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
Declare Function fts5CountCb CDecl Alias "fts5CountCb" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function fts5Bm25GetData CDecl Alias "fts5Bm25GetData" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_Fts5Bm25Data Ptr Ptr) As c2fb_c_int
Declare Sub fts5Bm25Function CDecl Alias "fts5Bm25Function" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub fts5GetLocaleFunction CDecl Alias "fts5GetLocaleFunction" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function c2fb_external_sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_value_double CDecl Alias "sqlite3_value_double" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Double
Declare Function c2fb_external_sqlite3_value_int64 CDecl Alias "sqlite3_value_int64" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_numeric_type CDecl Alias "sqlite3_value_numeric_type" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3_result_double CDecl Alias "sqlite3_result_double" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Double)
Declare Sub c2fb_external_sqlite3_result_error CDecl Alias "sqlite3_result_error" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_error_code CDecl Alias "sqlite3_result_error_code" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_destructor_type)
Private Function fts5CInstIterNext CDecl Alias "fts5CInstIterNext" (ByVal arg0 As c2fb_CInstIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 54
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->iStart))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->iEnd))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->iInst < arg0->nInst)))) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_4 = Cast(c2fb_c_int, CPtr(c2fb_callback_77, CPtr(Const c2fb_Fts5ExtensionApi Ptr, arg0->pApi)->xInst)(CPtr(c2fb_Fts5Context Ptr, arg0->pFts), arg0->iInst, CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3))))
        local0 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local2 = arg0->iCol)))) Then
                local4 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, 1ULL))) + CPtr(c2fb_callback_75, CPtr(Const c2fb_Fts5ExtensionApi Ptr, arg0->pApi)->xPhraseSize)(CPtr(c2fb_Fts5Context Ptr, arg0->pFts), local1)))
                If (-Cast(c2fb_c_int, ((arg0->iStart < Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_5 = CPtr(Long Ptr, @(arg0->iStart))
                    c2fb_temp_6 = Cast(c2fb_c_int, local3)
                    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
                    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
                    c2fb_temp_7 = CPtr(Long Ptr, @(arg0->iEnd))
                    c2fb_temp_8 = Cast(c2fb_c_int, local4)
                    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
                    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                Else
                    If (-Cast(c2fb_c_int, ((local3 <= arg0->iEnd)))) Then
                        If (-Cast(c2fb_c_int, ((local4 > arg0->iEnd)))) Then
                            c2fb_temp_9 = CPtr(Long Ptr, @(arg0->iEnd))
                            c2fb_temp_10 = Cast(c2fb_c_int, local4)
                            (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
                            c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
                        End If
                    Else
                        Goto c2fb_flow_0
                    End If
                End If
            End If
            c2fb_temp_11 = CPtr(Long Ptr, @(arg0->iInst))
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
            (*c2fb_temp_11) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Function fts5CInstIterInit CDecl Alias "fts5CInstIterInit" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_CInstIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 85
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Const c2fb_Fts5ExtensionApi_ Ptr Ptr
    Dim c2fb_temp_2 As Const c2fb_Fts5ExtensionApi Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Context_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Context Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg3), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_CInstIter))))
    c2fb_temp_1 = CPtr(Const c2fb_Fts5ExtensionApi_ Ptr Ptr, @(arg3->pApi))
    c2fb_temp_2 = CPtr(Const _c2fb_record_c2fb_Fts5ExtensionApi Ptr, arg0)
    (*c2fb_temp_1) = CPtr(Const c2fb_Fts5ExtensionApi_ Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(Const c2fb_Fts5ExtensionApi Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(c2fb_Fts5Context_ Ptr Ptr, @(arg3->pFts))
    c2fb_temp_4 = arg1
    (*c2fb_temp_3) = CPtr(c2fb_Fts5Context_ Ptr, c2fb_temp_4)
    c2fb_temp_4 = CPtr(c2fb_Fts5Context Ptr, (*c2fb_temp_3))
    c2fb_temp_5 = CPtr(Long Ptr, @(arg3->iCol))
    c2fb_temp_6 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    c2fb_temp_7 = Cast(c2fb_c_int, CPtr(c2fb_callback_76, arg0->xInstCount)(arg1, CPtr(c2fb_c_int Ptr, @(arg3->nInst))))
    local0 = c2fb_temp_7
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_8 = Cast(c2fb_c_int, fts5CInstIterNext(arg3))
        local0 = c2fb_temp_8
    End If
    Return local0
End Function
Private Sub fts5HighlightAppend CDecl Alias "fts5HighlightAppend" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_HighlightContext Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 138
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg2 <> 0))))) Then
        If (-Cast(c2fb_c_int, ((arg3 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(arg2)))
            arg3 = c2fb_temp_0
        End If
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @(arg1->zOut))
        c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%.*s"), arg1->zOut, arg3, arg2))
        (*c2fb_temp_1) = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((arg1->zOut = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_3) = c2fb_temp_4
        End If
    End If
End Sub
Private Function fts5HighlightCb CDecl Alias "fts5HighlightCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 153
    Dim local0 As c2fb_HighlightContext Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Long Ptr
    Dim c2fb_temp_21 As c2fb_c_int

    local0 = CPtr(c2fb_HighlightContext Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0001ULL))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_0 = CPtr(Long Ptr, @(local0->iPos))
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    c2fb_temp_2 = Cast(c2fb_c_int, c2fb_temp_1)
    local2 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local0->iRangeEnd >= Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < local0->iRangeStart)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 > local0->iRangeEnd)))) <> 0))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        If (-Cast(c2fb_c_int, (((local0->iRangeStart <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = local0->iRangeStart)))) <> 0))))) Then
            c2fb_temp_3 = CPtr(Long Ptr, @(local0->iOff))
            c2fb_temp_4 = Cast(c2fb_c_int, arg4)
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        End If
    End If
    If (-Cast(c2fb_c_int, (((local0->bOpen <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 <= local0->iter.iStart)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->iter.iStart < Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg4 > local0->iOff)))) <> 0))))) Then
        fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), local0, local0->zClose, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        c2fb_temp_5 = CPtr(Long Ptr, @(local0->bOpen))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = local0->iter.iStart)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->bOpen = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), local0, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0->zIn)[local0->iOff]))), Cast(c2fb_c_int, (arg4 - local0->iOff)))
        fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), local0, local0->zOpen, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        c2fb_temp_7 = CPtr(Long Ptr, @(local0->iOff))
        c2fb_temp_8 = Cast(c2fb_c_int, arg4)
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        c2fb_temp_9 = CPtr(Long Ptr, @(local0->bOpen))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
    End If
    If (-Cast(c2fb_c_int, ((local2 = local0->iter.iEnd)))) Then
        If (-Cast(c2fb_c_int, ((local0->bOpen = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C unused-parameter annotation
            fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), local0, local0->zOpen, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            c2fb_temp_11 = CPtr(Long Ptr, @(local0->bOpen))
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        End If
        fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), local0, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0->zIn)[local0->iOff]))), Cast(c2fb_c_int, (arg5 - local0->iOff)))
        c2fb_temp_13 = CPtr(Long Ptr, @(local0->iOff))
        c2fb_temp_14 = Cast(c2fb_c_int, arg5)
        (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
        c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_15 = Cast(c2fb_c_int, fts5CInstIterNext(CPtr(c2fb_CInstIter Ptr, @(local0->iter))))
            local1 = c2fb_temp_15
        End If
    End If
    If (-Cast(c2fb_c_int, ((local2 = local0->iRangeEnd)))) Then
        If local0->bOpen Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->iter.iStart >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 >= local0->iter.iStart)))) <> 0))))) Then
                fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), local0, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0->zIn)[local0->iOff]))), Cast(c2fb_c_int, (arg5 - local0->iOff)))
                c2fb_temp_16 = CPtr(Long Ptr, @(local0->iOff))
                c2fb_temp_17 = Cast(c2fb_c_int, arg5)
                (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
                c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
            End If
            fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), local0, local0->zClose, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            c2fb_temp_18 = CPtr(Long Ptr, @(local0->bOpen))
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
            c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
        End If
        fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), local0, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0->zIn)[local0->iOff]))), Cast(c2fb_c_int, (arg5 - local0->iOff)))
        c2fb_temp_20 = CPtr(Long Ptr, @(local0->iOff))
        c2fb_temp_21 = Cast(c2fb_c_int, arg5)
        (*c2fb_temp_20) = Cast(Long, c2fb_temp_21)
        c2fb_temp_21 = Cast(c2fb_c_int, (*c2fb_temp_20))
    End If
    Return local1
End Function
Private Function fts5ValueClampedInt CDecl Alias "fts5ValueClampedInt" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 236
    Return Cast(c2fb_c_int, (IIf(((-Cast(c2fb_c_int, ((((IIf(((-Cast(c2fb_c_int, (((c2fb_external_sqlite3_value_int64(arg0)) > Cast(c2fb_int64, (Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))))), (c2fb_external_sqlite3_value_int64(arg0)), Cast(c2fb_int64, (Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))) < Cast(c2fb_int64, (Cast(c2fb_c_int, &H7FFFFFFFULL)))))))), ((IIf(((-Cast(c2fb_c_int, (((c2fb_external_sqlite3_value_int64(arg0)) > Cast(c2fb_int64, (Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))))), (c2fb_external_sqlite3_value_int64(arg0)), Cast(c2fb_int64, (Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))), Cast(c2fb_int64, (Cast(c2fb_c_int, &H7FFFFFFFULL))))))
End Function
Private Sub fts5HighlightFunction CDecl Alias "fts5HighlightFunction" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 243
    Dim local0 As c2fb_HighlightContext
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Const ZString Ptr Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr Ptr
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg3 <> Cast(c2fb_c_int, 3ULL))))) Then
        local3 = StrPtr(!"wrong number of arguments to function highlight()")
        c2fb_external_sqlite3_result_error(arg2, local3, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Return
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, fts5ValueClampedInt(arg4[Cast(c2fb_c_int, &O0ULL)]))
    local2 = c2fb_temp_0
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_HighlightContext Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_HighlightContext))))
    c2fb_temp_2 = CPtr(Const ZString Ptr Ptr, @(local0.zOpen))
    c2fb_temp_3 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg4[Cast(c2fb_c_int, 1ULL)])))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(Const ZString Ptr Ptr, @(local0.zClose))
    c2fb_temp_5 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg4[Cast(c2fb_c_int, 2ULL)])))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(Long Ptr, @(local0.iRangeEnd))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    c2fb_temp_8 = Cast(c2fb_c_int, CPtr(c2fb_callback_79, arg0->xColumnText)(arg1, local2, CPtr(Const ZString Ptr Ptr, @(local0.zIn)), CPtr(c2fb_c_int Ptr, @(local0.nIn))))
    local1 = c2fb_temp_8
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 25ULL))))) Then
        c2fb_external_sqlite3_result_text(arg2, StrPtr(!""), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_9
    Else
        If local0.zIn Then
            local4 = Cast(c2fb_c_int, &O0ULL)
            local5 = Cast(c2fb_c_int, &O0ULL)
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_10 = Cast(c2fb_c_int, fts5CInstIterInit(arg0, arg1, local2, CPtr(c2fb_CInstIter Ptr, @(local0.iter))))
                local1 = c2fb_temp_10
            End If
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_11 = Cast(c2fb_c_int, CPtr(c2fb_callback_79, arg0->xColumnLocale)(arg1, local2, CPtr(Const ZString Ptr Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local5))))
                local1 = c2fb_temp_11
            End If
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_12 = Cast(c2fb_c_int, CPtr(c2fb_callback_90, arg0->xTokenize_v2)(arg1, local0.zIn, local0.nIn, local4, local5, CPtr(Any Ptr, CPtr(c2fb_HighlightContext Ptr, @(local0))), ProcPtr(fts5HighlightCb)))
                local1 = c2fb_temp_12
            End If
            If local0.bOpen Then
                fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_HighlightContext Ptr, @(local0)), local0.zClose, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            End If
            fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_HighlightContext Ptr, @(local0)), CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0.zIn)[local0.iOff]))), Cast(c2fb_c_int, (local0.nIn - local0.iOff)))
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_external_sqlite3_result_text(arg2, CPtr(Const ZString Ptr, local0.zOut), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
            End If
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local0.zOut))
        End If
    End If
    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_error_code(arg2, local1)
    End If
End Sub
Private Function fts5SentenceFinderAdd CDecl Alias "fts5SentenceFinderAdd" (ByVal arg0 As c2fb_Fts5SFinder Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 319
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As Long Ptr Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->nFirstAlloc = arg0->nFirst)))) Then
        local0 = IIf(arg0->nFirstAlloc, Cast(c2fb_c_int, (arg0->nFirstAlloc * Cast(c2fb_c_int, 2ULL))), Cast(c2fb_c_int, 64ULL))
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, arg0->aFirst), Cast(c2fb_uint64, (Cast(c2fb_uint64, local0) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))))))
        local1 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_1 = CPtr(Long Ptr Ptr, @(arg0->aFirst))
        c2fb_temp_2 = local1
        (*c2fb_temp_1) = CPtr(Long Ptr, c2fb_temp_2)
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(Long Ptr, @(arg0->nFirstAlloc))
        c2fb_temp_4 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    End If
    c2fb_temp_5 = CPtr(Long Ptr, @(arg0->nFirst))
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
    c2fb_temp_7 = CPtr(Long Ptr, @(arg0->aFirst[c2fb_temp_6]))
    c2fb_temp_8 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5SentenceFinderCb CDecl Alias "fts5SentenceFinderCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 338
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5SFinder Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As Byte
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Byte
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0001ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = CPtr(c2fb_Fts5SFinder Ptr, arg0)
        If (-Cast(c2fb_c_int, ((local1->iPos > Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            local3 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg4 - Cast(c2fb_c_int, 1ULL))))
            local2 = c2fb_temp_0
            While (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL)))))
                c2fb_temp_2 = Cast(Byte, CPtr(Const Byte Ptr, local1->zDoc)[local2])
                local3 = c2fb_temp_2
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) <> Cast(c2fb_c_int, 32))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) <> Cast(c2fb_c_int, 9))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) <> Cast(c2fb_c_int, 10))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) <> Cast(c2fb_c_int, 13))))) <> 0))))) Then
                    Goto c2fb_flow_0
                End If
            c2fb_flow_1:
                c2fb_temp_1 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
            Wend
            c2fb_flow_0:
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, (arg4 - Cast(c2fb_c_int, 1ULL))))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) = Cast(c2fb_c_int, 46))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) = Cast(c2fb_c_int, 58))))) <> 0)))))) <> 0))))) Then
                c2fb_temp_3 = Cast(c2fb_c_int, fts5SentenceFinderAdd(local1, local1->iPos))
                local0 = c2fb_temp_3
            End If
        Else
            c2fb_temp_4 = Cast(c2fb_c_int, fts5SentenceFinderAdd(local1, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_4
        End If
        c2fb_temp_5 = CPtr(Long Ptr, @(local1->iPos))
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
    End If
    Return local0
End Function
Private Function fts5SnippetScore CDecl Alias "fts5SnippetScore" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 371
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local10 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_int64
    Dim c2fb_temp_12 As c2fb_int64
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    ' C automatic storage declaration
    local7 = Cast(c2fb_c_int, &O0ULL)
    local8 = Cast(c2fb_c_int, &O0ULL)
    local9 = Cast(c2fb_int64, (Cast(c2fb_int64, arg5) + Cast(c2fb_int64, arg6)))
    c2fb_temp_0 = Cast(c2fb_c_int, CPtr(c2fb_callback_76, arg0->xInstCount)(arg1, CPtr(c2fb_c_int Ptr, @(local6))))
    local0 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < local6)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        c2fb_temp_3 = Cast(c2fb_c_int, CPtr(c2fb_callback_77, arg0->xInst)(arg1, local1, CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local4))))
        local0 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 = arg4)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 >= arg5)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_int64, local4) < local9)))) <> 0))))) Then
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local7 + (IIf(arg3[local2], Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, 1000ULL))))))
            local7 = c2fb_temp_4
            c2fb_temp_5 = CPtr(UByte Ptr, @(arg3[local2]))
            c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_5) = c2fb_temp_6
            If (-Cast(c2fb_c_int, ((local5 < Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_7 = Cast(c2fb_c_int, local4)
                local5 = c2fb_temp_7
            End If
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + CPtr(c2fb_callback_75, arg0->xPhraseSize)(arg1, local2))))
            local8 = c2fb_temp_8
        End If
    c2fb_flow_1:
        c2fb_temp_2 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg7)))
    c2fb_temp_10 = Cast(c2fb_c_int, local7)
    (*c2fb_temp_9) = c2fb_temp_10
    If arg8 Then
        local10 = Cast(c2fb_c_int, (local5 - Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg6 - (Cast(c2fb_c_int, (local8 - local5)))))) \ Cast(c2fb_c_int, 2ULL)))))
        If (-Cast(c2fb_c_int, (((Cast(c2fb_int64, (local10 + Cast(c2fb_int64, arg6)))) > Cast(c2fb_int64, arg2))))) Then
            c2fb_temp_11 = Cast(c2fb_int64, Cast(c2fb_c_int, (arg2 - arg6)))
            local10 = c2fb_temp_11
        End If
        If (-Cast(c2fb_c_int, ((local10 < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_12 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
            local10 = c2fb_temp_12
        End If
        c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @((*arg8)))
        c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, local10))
        (*c2fb_temp_13) = c2fb_temp_14
    End If
    Return local0
End Function
Private Function fts5ValueToText CDecl Alias "fts5ValueToText" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 420
    Dim local0 As Const ZString Ptr

    local0 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg0)))
    Return IIf(local0, local0, StrPtr(!""))
End Function
Private Sub fts5SnippetFunction CDecl Alias "fts5SnippetFunction" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 428
    Dim local0 As c2fb_HighlightContext
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As UByte Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim local13 As c2fb_Fts5SFinder
    Dim local14 As c2fb_c_int
    Dim local15 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Const ZString Ptr Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Const ZString Ptr Ptr
    Dim c2fb_temp_6 As Const ZString Ptr
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Any Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local16 As Const ZString Ptr
    Dim local17 As c2fb_c_int
    Dim local18 As c2fb_c_int
    Dim local19 As c2fb_c_int
    Dim local20 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Long Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim local21 As c2fb_c_int
    Dim local22 As c2fb_c_int
    Dim local23 As c2fb_c_int
    Dim local24 As c2fb_c_int
    Dim local25 As c2fb_c_int
    Dim local26 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As Any Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As Any Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As c2fb_c_int
    Dim local27 As Const ZString Ptr
    Dim local28 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As Long Ptr
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As Long Ptr
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As c2fb_c_int
    Dim c2fb_temp_55 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local5 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local10 = Cast(c2fb_c_int, &O0ULL)
    local11 = Cast(c2fb_c_int, &O0ULL)
    local12 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg3 <> Cast(c2fb_c_int, 5ULL))))) Then
        local15 = StrPtr(!"wrong number of arguments to function snippet()")
        c2fb_external_sqlite3_result_error(arg2, local15, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Return
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, CPtr(c2fb_callback_70, arg0->xColumnCount)(arg1))
    local14 = c2fb_temp_0
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_HighlightContext Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_HighlightContext))))
    c2fb_temp_2 = Cast(c2fb_c_int, fts5ValueClampedInt(arg4[Cast(c2fb_c_int, &O0ULL)]))
    local2 = c2fb_temp_2
    c2fb_temp_3 = CPtr(Const ZString Ptr Ptr, @(local0.zOpen))
    c2fb_temp_4 = CPtr(Const ZString Ptr, fts5ValueToText(arg4[Cast(c2fb_c_int, 1ULL)]))
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(Const ZString Ptr Ptr, @(local0.zClose))
    c2fb_temp_6 = CPtr(Const ZString Ptr, fts5ValueToText(arg4[Cast(c2fb_c_int, 2ULL)]))
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(Long Ptr, @(local0.iRangeEnd))
    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    c2fb_temp_9 = CPtr(Const ZString Ptr, fts5ValueToText(arg4[Cast(c2fb_c_int, 3ULL)]))
    local3 = c2fb_temp_9
    c2fb_temp_10 = Cast(c2fb_int64, Cast(c2fb_c_int, ((IIf(((-Cast(c2fb_c_int, ((((IIf(((-Cast(c2fb_c_int, (((c2fb_external_sqlite3_value_int64(arg4[Cast(c2fb_c_int, 4ULL)])) > Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL)))))))), (c2fb_external_sqlite3_value_int64(arg4[Cast(c2fb_c_int, 4ULL)])), Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL)))))) < Cast(c2fb_int64, (Cast(c2fb_c_int, 64ULL)))))))), ((IIf(((-Cast(c2fb_c_int, (((c2fb_external_sqlite3_value_int64(arg4[Cast(c2fb_c_int, 4ULL)])) > Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL)))))))), (c2fb_external_sqlite3_value_int64(arg4[Cast(c2fb_c_int, 4ULL)])), Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL)))))), Cast(c2fb_int64, (Cast(c2fb_c_int, 64ULL))))))))
    local4 = c2fb_temp_10
    c2fb_temp_11 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL))))), local2, Cast(c2fb_c_int, &O0ULL))))
    local9 = c2fb_temp_11
    c2fb_temp_12 = Cast(c2fb_c_int, CPtr(c2fb_callback_70, arg0->xPhraseCount)(arg1))
    local7 = c2fb_temp_12
    c2fb_temp_13 = CPtr(UByte Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local7)))
    local8 = c2fb_temp_13
    If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local1 = c2fb_temp_14
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_15 = Cast(c2fb_c_int, CPtr(c2fb_callback_76, arg0->xInstCount)(arg1, CPtr(c2fb_c_int Ptr, @(local5))))
        local1 = c2fb_temp_15
    End If
    c2fb_temp_16 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5SFinder Ptr, @(local13))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SFinder))))
    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local6 = c2fb_temp_17
    While (-Cast(c2fb_c_int, ((local6 < local14))))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = local6)))) <> 0))))) Then
            local16 = Cast(c2fb_c_int, &O0ULL)
            local17 = Cast(c2fb_c_int, &O0ULL)
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_19 = CPtr(Long Ptr, @(local13.iPos))
            c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
            c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
            c2fb_temp_21 = CPtr(Long Ptr, @(local13.nFirst))
            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_21) = Cast(Long, c2fb_temp_22)
            c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
            c2fb_temp_23 = Cast(c2fb_c_int, CPtr(c2fb_callback_79, arg0->xColumnText)(arg1, local6, CPtr(Const ZString Ptr Ptr, @(local13.zDoc)), CPtr(c2fb_c_int Ptr, @(local18))))
            local1 = c2fb_temp_23
            If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_24 = Cast(c2fb_c_int, CPtr(c2fb_callback_79, arg0->xColumnLocale)(arg1, local6, CPtr(Const ZString Ptr Ptr, @(local16)), CPtr(c2fb_c_int Ptr, @(local17))))
            local1 = c2fb_temp_24
            If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_25 = Cast(c2fb_c_int, CPtr(c2fb_callback_90, arg0->xTokenize_v2)(arg1, local13.zDoc, local18, local16, local17, CPtr(Any Ptr, CPtr(c2fb_Fts5SFinder Ptr, @(local13))), ProcPtr(fts5SentenceFinderCb)))
            local1 = c2fb_temp_25
            If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_26 = Cast(c2fb_c_int, CPtr(c2fb_callback_80, arg0->xColumnSize)(arg1, local6, CPtr(c2fb_c_int Ptr, @(local19))))
            local1 = c2fb_temp_26
            If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local20 = c2fb_temp_27
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local20 < local5)))) <> 0)))))
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_29 = Cast(c2fb_c_int, CPtr(c2fb_callback_77, arg0->xInst)(arg1, local20, CPtr(c2fb_c_int Ptr, @(local21)), CPtr(c2fb_c_int Ptr, @(local22)), CPtr(c2fb_c_int Ptr, @(local23))))
                local1 = c2fb_temp_29
                If (-Cast(c2fb_c_int, ((local22 <> local6)))) Then
                    Goto c2fb_flow_3
                End If
                If (-Cast(c2fb_c_int, ((local23 > local19)))) Then
                    c2fb_temp_30 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local1 = c2fb_temp_30
                End If
                If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_3
                End If
                c2fb_temp_31 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local8), Cast(c2fb_c_int, &O0ULL), local7))
                c2fb_temp_32 = Cast(c2fb_c_int, fts5SnippetScore(arg0, arg1, local19, local8, local6, local23, local4, CPtr(c2fb_c_int Ptr, @(local25)), CPtr(c2fb_c_int Ptr, @(local24))))
                local1 = c2fb_temp_32
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local25 > local11)))) <> 0))))) Then
                    c2fb_temp_33 = Cast(c2fb_c_int, local25)
                    local11 = c2fb_temp_33
                    c2fb_temp_34 = Cast(c2fb_c_int, local6)
                    local9 = c2fb_temp_34
                    c2fb_temp_35 = Cast(c2fb_c_int, local24)
                    local10 = c2fb_temp_35
                    c2fb_temp_36 = Cast(c2fb_c_int, local19)
                    local12 = c2fb_temp_36
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local13.nFirst <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_int64, local19) > local4)))) <> 0))))) Then
                    c2fb_temp_37 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local26 = c2fb_temp_37
                    While (-Cast(c2fb_c_int, ((local26 < (Cast(c2fb_c_int, (local13.nFirst - Cast(c2fb_c_int, 1ULL))))))))
                        If (-Cast(c2fb_c_int, ((local13.aFirst[Cast(c2fb_c_int, (local26 + Cast(c2fb_c_int, 1ULL)))] > local23)))) Then
                            Goto c2fb_flow_4
                        End If
                    c2fb_flow_5:
                        c2fb_temp_38 = local26
                        local26 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_38 + 1)))
                    Wend
                    c2fb_flow_4:
                    If (-Cast(c2fb_c_int, ((local13.aFirst[local26] < local23)))) Then
                        c2fb_temp_39 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local8), Cast(c2fb_c_int, &O0ULL), local7))
                        c2fb_temp_40 = Cast(c2fb_c_int, fts5SnippetScore(arg0, arg1, local19, local8, local6, local13.aFirst[local26], local4, CPtr(c2fb_c_int Ptr, @(local25)), Cast(c2fb_c_int, &O0ULL)))
                        local1 = c2fb_temp_40
                        c2fb_temp_41 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local25 + (IIf((-Cast(c2fb_c_int, ((local13.aFirst[local26] = Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, 120ULL), Cast(c2fb_c_int, 100ULL))))))
                        local25 = c2fb_temp_41
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local25 > local11)))) <> 0))))) Then
                            c2fb_temp_42 = Cast(c2fb_c_int, local25)
                            local11 = c2fb_temp_42
                            c2fb_temp_43 = Cast(c2fb_c_int, local6)
                            local9 = c2fb_temp_43
                            c2fb_temp_44 = Cast(c2fb_c_int, local13.aFirst[local26])
                            local10 = c2fb_temp_44
                            c2fb_temp_45 = Cast(c2fb_c_int, local19)
                            local12 = c2fb_temp_45
                        End If
                    End If
                End If
            c2fb_flow_3:
                c2fb_temp_28 = local20
                local20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
            Wend
            c2fb_flow_2:
        End If
    c2fb_flow_1:
        c2fb_temp_18 = local6
        local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_46 = Cast(c2fb_c_int, CPtr(c2fb_callback_79, arg0->xColumnText)(arg1, local9, CPtr(Const ZString Ptr Ptr, @(local0.zIn)), CPtr(c2fb_c_int Ptr, @(local0.nIn))))
        local1 = c2fb_temp_46
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_47 = Cast(c2fb_c_int, CPtr(c2fb_callback_80, arg0->xColumnSize)(arg1, local9, CPtr(c2fb_c_int Ptr, @(local12))))
        local1 = c2fb_temp_47
    End If
    If local0.zIn Then
        local27 = Cast(c2fb_c_int, &O0ULL)
        local28 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_48 = Cast(c2fb_c_int, fts5CInstIterInit(arg0, arg1, local9, CPtr(c2fb_CInstIter Ptr, @(local0.iter))))
            local1 = c2fb_temp_48
        End If
        c2fb_temp_49 = CPtr(Long Ptr, @(local0.iRangeStart))
        c2fb_temp_50 = Cast(c2fb_c_int, local10)
        (*c2fb_temp_49) = Cast(Long, c2fb_temp_50)
        c2fb_temp_50 = Cast(c2fb_c_int, (*c2fb_temp_49))
        c2fb_temp_51 = CPtr(Long Ptr, @(local0.iRangeEnd))
        c2fb_temp_52 = Cast(c2fb_c_int, Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, local10) + local4)) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))
        (*c2fb_temp_51) = Cast(Long, c2fb_temp_52)
        c2fb_temp_52 = Cast(c2fb_c_int, (*c2fb_temp_51))
        If (-Cast(c2fb_c_int, ((local10 > Cast(c2fb_c_int, &O0ULL))))) Then
            fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_HighlightContext Ptr, @(local0)), local3, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        End If
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0.iter.iStart >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0.iter.iStart < local10)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            c2fb_temp_53 = Cast(c2fb_c_int, fts5CInstIterNext(CPtr(c2fb_CInstIter Ptr, @(local0.iter))))
            local1 = c2fb_temp_53
        c2fb_flow_7:
        Wend
        c2fb_flow_6:
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_54 = Cast(c2fb_c_int, CPtr(c2fb_callback_79, arg0->xColumnLocale)(arg1, local9, CPtr(Const ZString Ptr Ptr, @(local27)), CPtr(c2fb_c_int Ptr, @(local28))))
            local1 = c2fb_temp_54
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_55 = Cast(c2fb_c_int, CPtr(c2fb_callback_90, arg0->xTokenize_v2)(arg1, local0.zIn, local0.nIn, local27, local28, CPtr(Any Ptr, CPtr(c2fb_HighlightContext Ptr, @(local0))), ProcPtr(fts5HighlightCb)))
            local1 = c2fb_temp_55
        End If
        If local0.bOpen Then
            fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_HighlightContext Ptr, @(local0)), local0.zClose, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        End If
        If (-Cast(c2fb_c_int, ((local0.iRangeEnd >= (Cast(c2fb_c_int, (local12 - Cast(c2fb_c_int, 1ULL)))))))) Then
            fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_HighlightContext Ptr, @(local0)), CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0.zIn)[local0.iOff]))), Cast(c2fb_c_int, (local0.nIn - local0.iOff)))
        Else
            fts5HighlightAppend(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_HighlightContext Ptr, @(local0)), local3, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        End If
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_text(arg2, CPtr(Const ZString Ptr, local0.zOut), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
    Else
        c2fb_external_sqlite3_result_error_code(arg2, local1)
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0.zOut))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local8))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local13.aFirst))
End Sub
Private Function fts5CountCb CDecl Alias "fts5CountCb" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 614
    Dim local0 As c2fb_int64 Ptr
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    local0 = CPtr(c2fb_int64 Ptr, arg2)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(((*local0))))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_1 + 1)))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5Bm25GetData CDecl Alias "fts5Bm25GetData" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_Fts5Bm25Data Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 630
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Bm25Data Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Bm25Data Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_Fts5Bm25Data Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Double Ptr Ptr
    Dim c2fb_temp_9 As Double Ptr
    Dim c2fb_temp_10 As Double Ptr Ptr
    Dim c2fb_temp_11 As Double Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Double Ptr
    Dim c2fb_temp_15 As Double
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local7 As c2fb_int64
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local8 As Double
    Dim c2fb_temp_19 As Double
    Dim c2fb_temp_20 As Double Ptr
    Dim c2fb_temp_21 As Double
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_Fts5Bm25Data Ptr
    Dim c2fb_temp_24 As c2fb_Fts5Bm25Data Ptr Ptr
    Dim c2fb_temp_25 As c2fb_Fts5Bm25Data Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Bm25Data Ptr, CPtr(c2fb_Fts5Bm25Data Ptr, CPtr(Any Ptr, CPtr(c2fb_callback_84, arg0->xGetAuxdata)(arg1, Cast(c2fb_c_int, &O0ULL)))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, CPtr(c2fb_callback_70, arg0->xPhraseCount)(arg1))
        local2 = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Bm25Data))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (local2 * Cast(c2fb_c_int, 2ULL)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Double))))))))
        local5 = c2fb_temp_2
        c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Bm25Data Ptr, CPtr(c2fb_Fts5Bm25Data Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local5))))
        local1 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_4
        Else
            c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, local5)))
            c2fb_temp_6 = CPtr(Long Ptr, @(local1->nPhrase))
            c2fb_temp_7 = Cast(c2fb_c_int, local2)
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            c2fb_temp_8 = CPtr(Double Ptr Ptr, @(local1->aIDF))
            c2fb_temp_9 = CPtr(Double Ptr, CPtr(c2fb_Fts5Bm25Data Ptr, @(CPtr(c2fb_Fts5Bm25Data Ptr, local1)[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(Double Ptr Ptr, @(local1->aFreq))
            c2fb_temp_11 = CPtr(Double Ptr, @(local1->aIDF[local2]))
            (*c2fb_temp_10) = c2fb_temp_11
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_12 = Cast(c2fb_c_int, CPtr(c2fb_callback_71, arg0->xRowCount)(arg1, CPtr(c2fb_int64 Ptr, @(local3))))
            local0 = c2fb_temp_12
        End If
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_13 = Cast(c2fb_c_int, CPtr(c2fb_callback_72, arg0->xColumnTotalSize)(arg1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_int64 Ptr, @(local4))))
            local0 = c2fb_temp_13
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_14 = CPtr(Double Ptr, @(local1->avgdl))
            c2fb_temp_15 = Cast(Double, __c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, local4)) / __c2fb_double_value(Cast(Double, local3))))))
            (*c2fb_temp_14) = c2fb_temp_15
        End If
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local6 = c2fb_temp_16
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6 < local2)))) <> 0)))))
            local7 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_18 = Cast(c2fb_c_int, CPtr(c2fb_callback_82, arg0->xQueryPhrase)(arg1, local6, CPtr(Any Ptr, CPtr(c2fb_int64 Ptr, @(local7))), ProcPtr(fts5CountCb)))
            local0 = c2fb_temp_18
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                local8 = log_(__c2fb_double_value(Cast(Double, ((__c2fb_double_value(Cast(Double, (Cast(Double, Cast(c2fb_int64, (local3 - local7))) + 0.5#)))) / (__c2fb_double_value(Cast(Double, (Cast(Double, local7) + 0.5#))))))))
                If (-Cast(c2fb_c_int, ((local8 <= 0.0#)))) Then
                    c2fb_temp_19 = Cast(Double, 1e-6#)
                    local8 = c2fb_temp_19
                End If
                c2fb_temp_20 = CPtr(Double Ptr, @(local1->aIDF[local6]))
                c2fb_temp_21 = Cast(Double, local8)
                (*c2fb_temp_20) = c2fb_temp_21
            End If
        c2fb_flow_1:
            c2fb_temp_17 = local6
            local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
        Else
            c2fb_temp_22 = Cast(c2fb_c_int, CPtr(c2fb_callback_83, arg0->xSetAuxdata)(arg1, CPtr(Any Ptr, local1), ProcPtr(c2fb_external_sqlite3_free)))
            local0 = c2fb_temp_22
        End If
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_23 = CPtr(_c2fb_record_c2fb_Fts5Bm25Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_23
        End If
    End If
    c2fb_temp_24 = CPtr(c2fb_Fts5Bm25Data Ptr Ptr, @((*arg2)))
    c2fb_temp_25 = CPtr(_c2fb_record_c2fb_Fts5Bm25Data Ptr, local1)
    (*c2fb_temp_24) = c2fb_temp_25
    Return local0
End Function
Private Sub fts5Bm25Function CDecl Alias "fts5Bm25Function" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 703
    Dim local0 As Double
    Dim local1 As Double
    Dim local2 As c2fb_c_int
    Dim local3 As Double
    Dim local4 As c2fb_Fts5Bm25Data Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As Double
    Dim local8 As Double Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Double Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local12 As Double
    Dim c2fb_temp_7 As Double Ptr
    Dim c2fb_temp_8 As Double
    Dim local13 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Double
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Double

    local0 = 1.2#
    local1 = 0.75#
    ' C automatic storage declaration
    local3 = 0.0#
    ' C automatic storage declaration
    ' C automatic storage declaration
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = 0.0#
    local8 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, fts5Bm25GetData(arg0, arg1, CPtr(c2fb_Fts5Bm25Data Ptr Ptr, @(local4))))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = local4->aFreq
        local8 = c2fb_temp_1
        c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local8), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Double))) * Cast(c2fb_uint64, local4->nPhrase)))))
        c2fb_temp_3 = Cast(c2fb_c_int, CPtr(c2fb_callback_76, arg0->xInstCount)(arg1, CPtr(c2fb_c_int Ptr, @(local6))))
        local2 = c2fb_temp_3
    End If
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local5 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < local6)))) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_6 = Cast(c2fb_c_int, CPtr(c2fb_callback_77, arg0->xInst)(arg1, local5, CPtr(c2fb_c_int Ptr, @(local9)), CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_c_int Ptr, @(local11))))
        local2 = c2fb_temp_6
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            local12 = IIf(((-Cast(c2fb_c_int, ((arg3 > local10))))), c2fb_external_sqlite3_value_double(arg4[local10]), 1.0#)
            c2fb_temp_7 = CPtr(Double Ptr, @(local8[local9]))
            c2fb_temp_8 = Cast(Double, __c2fb_double_value(Cast(Double, ((*c2fb_temp_7) + local12))))
            (*c2fb_temp_7) = c2fb_temp_8
        End If
    c2fb_flow_1:
        c2fb_temp_5 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_temp_9 = Cast(c2fb_c_int, CPtr(c2fb_callback_80, arg0->xColumnSize)(arg1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_c_int Ptr, @(local13))))
        local2 = c2fb_temp_9
        c2fb_temp_10 = Cast(Double, __c2fb_double_value(Cast(Double, local13)))
        local7 = c2fb_temp_10
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local5 = c2fb_temp_11
        While (-Cast(c2fb_c_int, ((local5 < local4->nPhrase))))
            c2fb_temp_13 = Cast(Double, __c2fb_double_value(Cast(Double, (local3 + __c2fb_double_value(Cast(Double, (local4->aIDF[local5] * (__c2fb_double_value(Cast(Double, ((__c2fb_double_value(Cast(Double, (local8[local5] * (__c2fb_double_value(Cast(Double, (local0 + 1.0#)))))))) / (__c2fb_double_value(Cast(Double, (local8[local5] + __c2fb_double_value(Cast(Double, (local0 * (__c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (Cast(Double, Cast(c2fb_c_int, 1ULL)) - local1))) + __c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (local1 * local7))) / local4->avgdl)))))))))))))))))))))))))
            local3 = c2fb_temp_13
        c2fb_flow_3:
            c2fb_temp_12 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_external_sqlite3_result_double(arg2, __c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (-1.0#))) * local3))))
    Else
        c2fb_external_sqlite3_result_error_code(arg2, local2)
    End If
End Sub
Private Sub fts5GetLocaleFunction CDecl Alias "fts5GetLocaleFunction" (ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_aux.c
' c2fb source-line: 762
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg3 <> Cast(c2fb_c_int, 1ULL))))) Then
        local5 = StrPtr(!"wrong number of arguments to function fts5_get_locale()")
        c2fb_external_sqlite3_result_error(arg2, local5, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Return
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_numeric_type(arg4[Cast(c2fb_c_int, &O0ULL)]))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, 1ULL))))) Then
        local6 = StrPtr(!"non-integer argument passed to function fts5_get_locale()")
        c2fb_external_sqlite3_result_error(arg2, local6, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Return
    End If
    c2fb_temp_1 = Cast(c2fb_c_int, fts5ValueClampedInt(arg4[Cast(c2fb_c_int, &O0ULL)]))
    local0 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 >= CPtr(c2fb_callback_70, arg0->xColumnCount)(arg1))))) <> 0))))) Then
        c2fb_external_sqlite3_result_error_code(arg2, Cast(c2fb_c_int, 25ULL))
        Return
    End If
    c2fb_temp_2 = Cast(c2fb_c_int, CPtr(c2fb_callback_79, arg0->xColumnLocale)(arg1, local0, CPtr(Const ZString Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local4))))
    local2 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_error_code(arg2, local2)
        Return
    End If
    c2fb_external_sqlite3_result_text(arg2, local3, local4, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
End Sub
Function sqlite3Fts5AuxInit CDecl Alias "sqlite3Fts5AuxInit" (ByVal arg0 As c2fb_fts5_api Ptr) As c2fb_c_int
    Dim rc As c2fb_c_int

    rc = arg0->xCreateFunction(arg0, StrPtr(!"snippet"), 0, _
        ProcPtr(fts5SnippetFunction), 0)
    If rc = 0 Then
        rc = arg0->xCreateFunction(arg0, StrPtr(!"highlight"), 0, _
            ProcPtr(fts5HighlightFunction), 0)
    End If
    If rc = 0 Then
        rc = arg0->xCreateFunction(arg0, StrPtr(!"bm25"), 0, _
            ProcPtr(fts5Bm25Function), 0)
    End If
    If rc = 0 Then
        rc = arg0->xCreateFunction(arg0, StrPtr(!"fts5_get_locale"), 0, _
            ProcPtr(fts5GetLocaleFunction), 0)
    End If

    Return rc
End Function
#endif
/' end of sqlite3_bulk_fts5_aux.bas '/
