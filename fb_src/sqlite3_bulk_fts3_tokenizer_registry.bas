/'
** 2007 June 22
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
** This is part of an SQLite module implementing full-text search.
** This particular file implements the generic tokenizer interface.
'/
/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_tokenizer_registry.bas

    Purpose:

        Implement the shared FTS3 tokenizer lookup and SQL registry helpers.

    Responsibilities:

        - Parse tokenizer names and arguments from FTS3 SQL declarations.
        - Register fts3_tokenizer with the upstream bound-parameter and db-config policy.
        - Provide tokenizer module lookup and tokenizer-name scanning.
        - Register upstream tokenizer test callbacks in SQLITE_TEST builds.

    This file intentionally does NOT contain:

        - FTS3/FTS4 table storage, segment traversal, or query evaluation.
        - Tcl test cases or the SQLite test runner.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts3_tokenizer_types.bi"
#include once "sqlite3_fts3_hash_types.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_vdbe_mem_types.bi"
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


Type c2fb_callback_7 As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_77 As Function CDecl(ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Fts3Tokenizer Ptr Ptr) As c2fb_c_int
Type c2fb_callback_88 As Sub CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)

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

Declare Function fts3TokenizerEnabled CDecl Alias "fts3TokenizerEnabled" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Sub fts3TokenizerFunc CDecl Alias "fts3TokenizerFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
Declare Function sqlite3Fts3IsIdChar CDecl Alias "sqlite3Fts3IsIdChar" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function sqlite3Fts3NextToken CDecl Alias "sqlite3Fts3NextToken" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const ZString Ptr
Declare Function sqlite3Fts3InitTokenizer CDecl Alias "sqlite3Fts3InitTokenizer" (ByVal arg0 As c2fb_source_record_33 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Fts3Tokenizer Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts3InitHashTable CDecl Alias "sqlite3Fts3InitHashTable" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_33 Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_db_config CDecl Alias "sqlite3_db_config" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ...) As c2fb_c_int
Declare Function c2fb_external_sqlite3_prepare_v2 CDecl Alias "sqlite3_prepare_v2" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr Ptr, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_text CDecl Alias "sqlite3_bind_text" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_blob CDecl Alias "sqlite3_bind_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_type CDecl Alias "sqlite3_column_type" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_bytes CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_blob CDecl Alias "sqlite3_column_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function c2fb_external_sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_errmsg CDecl Alias "sqlite3_errmsg" (ByVal arg0 As Any Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_create_function CDecl Alias "sqlite3_create_function" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_88, ByVal arg6 As c2fb_callback_88, ByVal arg7 As c2fb_callback_7) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_blob CDecl Alias "sqlite3_value_blob" (ByVal arg0 As Any Ptr) As Const Any Ptr
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As Any Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_frombind CDecl Alias "sqlite3_value_frombind" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_user_data CDecl Alias "sqlite3_user_data" (ByVal arg0 As Any Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3_context_db_handle CDecl Alias "sqlite3_context_db_handle" (ByVal arg0 As Any Ptr) As Any Ptr
Declare Sub c2fb_external_sqlite3_result_blob CDecl Alias "sqlite3_result_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_callback_7)
Declare Sub c2fb_external_sqlite3_result_error CDecl Alias "sqlite3_result_error" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_error_nomem CDecl Alias "sqlite3_result_error_nomem" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3_result_error_toobig CDecl Alias "sqlite3_result_error_toobig" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3_result_error_code CDecl Alias "sqlite3_result_error_code" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr)
Declare Function sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3HashInsert CDecl Alias "sqlite3Fts3HashInsert" (ByVal arg0 As c2fb_source_record_33 Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3Fts3HashFind CDecl Alias "sqlite3Fts3HashFind" (ByVal arg0 As Const c2fb_source_record_33 Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub c2fb_external_sqlite3Fts3Dequote CDecl Alias "sqlite3Fts3Dequote" (ByVal arg0 As ZString Ptr)

#ifdef SQLITE_TEST
Declare Function sqlite3Fts3OpenTokenizer CDecl Alias "sqlite3Fts3OpenTokenizer" ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr, _
    ByVal languageId As c2fb_c_int, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As c2fb_c_int, _
    ByVal ppCursor As Fts3TokenizerCursor Ptr Ptr _
) As c2fb_c_int
Declare Function Tcl_NewObj CDecl Alias "Tcl_NewObj" () As Any Ptr
Declare Function Tcl_NewIntObj CDecl Alias "Tcl_NewIntObj" (ByVal value As c2fb_c_int) As Any Ptr
Declare Function Tcl_NewStringObj CDecl Alias "Tcl_NewStringObj" (ByVal value As Const ZString Ptr, ByVal byteCount As c2fb_c_int) As Any Ptr
Declare Function Tcl_ListObjAppendElement CDecl Alias "Tcl_ListObjAppendElement" (ByVal interp As Any Ptr, ByVal listObject As Any Ptr, ByVal element As Any Ptr) As c2fb_c_int
Declare Function Tcl_GetString CDecl Alias "Tcl_GetString" (ByVal object As Any Ptr) As Const ZString Ptr
Declare Sub TclFreeObj CDecl Alias "TclFreeObj" (ByVal object As Any Ptr)
#endif
Private Function fts3TokenizerEnabled CDecl Alias "fts3TokenizerEnabled" (ByVal arg0 As Any Ptr) As c2fb_c_int
    If arg0 = 0 Then Return 0
' c2fb source-path: ext/fts3/fts3_tokenizer.c
' c2fb source-line: 37
    Dim local0 As Any Ptr
    Dim local1 As c2fb_c_int

    local0 = CPtr(Any Ptr, c2fb_external_sqlite3_context_db_handle(arg0))
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_external_sqlite3_db_config(local0, Cast(c2fb_c_int, 1004ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_c_int Ptr, @(local1)))
    Return local1
End Function
Private Sub fts3TokenizerFunc CDecl Alias "fts3TokenizerFunc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr Ptr)
    If arg0 = 0 OrElse arg2 = 0 Then Exit Sub
' c2fb source-path: ext/fts3/fts3_tokenizer.c
' c2fb source-line: 64
    Dim local0 As c2fb_source_record_33 Ptr
    Dim local1 As Any Ptr
    Dim local2 As Const UByte Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_source_record_33 Ptr
    Dim c2fb_temp_1 As Const UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local4 As Any Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Any Ptr
    Dim local6 As ZString Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_source_record_33 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_user_data(arg0)))
    local0 = c2fb_temp_0
    c2fb_temp_1 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, &O0ULL)]))
    local2 = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_external_sqlite3_value_bytes(arg2[Cast(c2fb_c_int, &O0ULL)]) + Cast(c2fb_c_int, 1ULL))))
    local3 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) Then
        If (-Cast(c2fb_c_int, (((fts3TokenizerEnabled(arg0) <> 0) OrElse (c2fb_external_sqlite3_value_frombind(arg2[Cast(c2fb_c_int, 1ULL)]) <> 0))))) Then
            ' C automatic storage declaration
            local5 = c2fb_external_sqlite3_value_bytes(arg2[Cast(c2fb_c_int, 1ULL)])
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_uint64, local5) <> Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Any Ptr))))))) <> 0))))) Then
                c2fb_external_sqlite3_result_error(arg0, StrPtr(!"argument type mismatch"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                Return
            End If
            c2fb_temp_3 = (*CPtr(Any Ptr Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob(arg2[Cast(c2fb_c_int, 1ULL)]))))
            local1 = c2fb_temp_3
            c2fb_temp_4 = CPtr(Any Ptr, c2fb_external_sqlite3Fts3HashInsert(local0, CPtr(Const Any Ptr, CPtr(Any Ptr, local2)), local3, local1))
            local4 = c2fb_temp_4
            If (-Cast(c2fb_c_int, ((local4 = local1)))) Then
                c2fb_external_sqlite3_result_error(arg0, StrPtr(!"out of memory"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            End If
        Else
            c2fb_external_sqlite3_result_error(arg0, StrPtr(!"fts3tokenize disabled"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            Return
        End If
    Else
        If local2 Then
            c2fb_temp_5 = CPtr(Any Ptr, c2fb_external_sqlite3Fts3HashFind(CPtr(Const c2fb_source_record_33 Ptr, local0), CPtr(Const Any Ptr, local2), local3))
            local1 = c2fb_temp_5
        End If
        If (-Cast(c2fb_c_int, (local1 = 0))) Then
            local6 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"unknown tokenizer: %s"), local2))
            c2fb_external_sqlite3_result_error(arg0, CPtr(Const ZString Ptr, local6), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local6))
            Return
        End If
    End If
    If (-Cast(c2fb_c_int, (((fts3TokenizerEnabled(arg0) <> 0) OrElse (c2fb_external_sqlite3_value_frombind(arg2[Cast(c2fb_c_int, &O0ULL)]) <> 0))))) Then
        c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, CPtr(Any Ptr, CPtr(Any Ptr Ptr, @(local1)))), Cast(c2fb_size_t, SizeOf(Any Ptr)), (CPtr(c2fb_callback_7, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
    End If
End Sub
Function sqlite3Fts3IsIdChar CDecl Alias "sqlite3Fts3IsIdChar" (ByVal arg0 As Byte) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer.c
' c2fb source-line: 114
    Static local0(0 To 127) As Byte = {Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, &O0ULL))}

    ' C static array storage
    Return ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0) And Cast(c2fb_c_int, &H80ULL))) <> 0) OrElse (local0(Cast(c2fb_c_int, (arg0))) <> 0))))))
End Function
Function sqlite3Fts3NextToken CDecl Alias "sqlite3Fts3NextToken" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const ZString Ptr
    If arg0 = 0 OrElse arg1 = 0 Then Return 0
' c2fb source-path: ext/fts3/fts3_tokenizer.c
' c2fb source-line: 128
    Dim local0 As Const ZString Ptr
    Dim local1 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim local2 As Byte
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim c2fb_temp_10 As Const ZString Ptr
    Dim c2fb_temp_11 As Const ZString Ptr
    Dim c2fb_temp_12 As Const ZString Ptr
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = arg0
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL)))))
        local2 = (*CPtr(Const Byte Ptr, local0))
        Select Case local2
            Case Cast(c2fb_c_int, 0)
                Return Cast(c2fb_c_int, &O0ULL)
            Case Cast(c2fb_c_int, 39), Cast(c2fb_c_int, 34), Cast(c2fb_c_int, 96)
                c2fb_temp_1 = local0
                local1 = c2fb_temp_1
                Do
                    c2fb_temp_2 = local1
                    local1 = (c2fb_temp_2 + 1)
                    c2fb_temp_3 = local1
                    c2fb_temp_7 = 0
                    If ((*CPtr(Const Byte Ptr, c2fb_temp_3)) <> 0) Then
                        c2fb_temp_6 = 1
                        If (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local1))) <> Cast(c2fb_c_int, local2))))) <> 0) = 0) Then
                            c2fb_temp_4 = local1
                            local1 = (c2fb_temp_4 + 1)
                            c2fb_temp_5 = local1
                            c2fb_temp_6 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, c2fb_temp_5))) = Cast(c2fb_c_int, local2))))) <> 0))))
                        End If
                        c2fb_temp_7 = (-Cast(c2fb_c_int, (((c2fb_temp_6) <> 0))))
                    End If
                    If (c2fb_temp_7 = 0) Then Goto c2fb_flow_3
                    ' empty C statement
                c2fb_flow_4:
                Loop
                c2fb_flow_3:
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 91)
                c2fb_temp_8 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, 1ULL)])))
                local1 = c2fb_temp_8
                While (-Cast(c2fb_c_int, ((((*CPtr(Const Byte Ptr, local1)) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local1)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 93))))) <> 0)))))
                    c2fb_temp_9 = local1
                    local1 = (c2fb_temp_9 + 1)
                c2fb_flow_6:
                Wend
                c2fb_flow_5:
                If (*CPtr(Const Byte Ptr, local1)) Then
                    c2fb_temp_10 = local1
                    local1 = (c2fb_temp_10 + 1)
                End If
            Case Else
                If sqlite3Fts3IsIdChar((*CPtr(Const Byte Ptr, local0))) Then
                    c2fb_temp_11 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, 1ULL)])))
                    local1 = c2fb_temp_11
                    While sqlite3Fts3IsIdChar((*CPtr(Const Byte Ptr, local1)))
                        c2fb_temp_12 = local1
                        local1 = (c2fb_temp_12 + 1)
                    c2fb_flow_8:
                    Wend
                    c2fb_flow_7:
                Else
                    c2fb_temp_13 = local0
                    local0 = (c2fb_temp_13 + 1)
                End If
        End Select
        c2fb_flow_2:
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Const Byte Ptr, local1)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local0))))))
    (*c2fb_temp_14) = c2fb_temp_15
    Return local0
End Function
Function sqlite3Fts3InitTokenizer CDecl Alias "sqlite3Fts3InitTokenizer" (ByVal arg0 As c2fb_source_record_33 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Fts3Tokenizer Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
    If arg0 = 0 OrElse arg1 = 0 OrElse arg2 = 0 Then Return SQLITE_MISUSE
    arg2[0] = 0
' c2fb source-path: ext/fts3/fts3_tokenizer.c
' c2fb source-line: 165
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As Fts3TokenizerModule Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Byte Ptr
    Dim c2fb_temp_5 As Byte
    Dim c2fb_temp_6 As Fts3TokenizerModule Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local6 As Const ZString Ptr Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local8 As c2fb_int64
    Dim local9 As Const ZString Ptr Ptr
    Dim c2fb_temp_12 As Const ZString Ptr Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Const ZString Ptr Ptr
    Dim c2fb_temp_15 As Const ZString Ptr
    Dim c2fb_temp_16 As Byte Ptr
    Dim c2fb_temp_17 As Byte
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Any Ptr Ptr
    Dim c2fb_temp_21 As Const Fts3TokenizerModule Ptr

    ' C automatic storage declaration
    local1 = CPtr(ZString Ptr, arg1)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s"), arg1))
    local3 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local3 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local3)[c2fb_crt_strlen(CPtr(Const ZString Ptr, local3))])))
    local4 = c2fb_temp_1
    c2fb_temp_2 = CPtr(ZString Ptr, CPtr(Const ZString Ptr, sqlite3Fts3NextToken(CPtr(Const ZString Ptr, local3), CPtr(c2fb_c_int Ptr, @(local2)))))
    local1 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_3 = local3
        local1 = c2fb_temp_3
    End If
    c2fb_temp_4 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[local2]))
    c2fb_temp_5 = Cast(Byte, Cast(c2fb_c_int, 0))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_external_sqlite3Fts3Dequote(local1)
    c2fb_temp_6 = CPtr(Fts3TokenizerModule Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts3HashFind(CPtr(Const c2fb_source_record_33 Ptr, arg0), CPtr(Const Any Ptr, local1), Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_crt_strlen(CPtr(Const ZString Ptr, local1))) + Cast(c2fb_c_int, 1ULL))))))
    local5 = c2fb_temp_6
    If (-Cast(c2fb_c_int, (local5 = 0))) Then
        c2fb_external_sqlite3Fts3ErrMsg(arg3, StrPtr(!"unknown tokenizer: %s"), local1)
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_7
    Else
        local6 = Cast(c2fb_c_int, &O0ULL)
        local7 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_8 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))])))
        local1 = c2fb_temp_8
        Do
            c2fb_temp_11 = 0
            If ((-Cast(c2fb_c_int, ((local1 < local4)))) <> 0) Then
                c2fb_temp_10 = (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))
                c2fb_temp_9 = CPtr(ZString Ptr, CPtr(Const ZString Ptr, sqlite3Fts3NextToken(CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(local2)))))
                local1 = c2fb_temp_9
                c2fb_temp_11 = (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((c2fb_temp_10 <> (c2fb_temp_9)))))) <> 0))))
            End If
            If (c2fb_temp_11 = 0) Then Goto c2fb_flow_0
            local8 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (local7 + Cast(c2fb_c_int, 1ULL)))))))
            local9 = CPtr(Const ZString Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, local6), local8)))
            If (-Cast(c2fb_c_int, (local9 = 0))) Then
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local6))
                Return Cast(c2fb_c_int, 7ULL)
            End If
            c2fb_temp_12 = local9
            local6 = c2fb_temp_12
            c2fb_temp_13 = local7
            local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
            c2fb_temp_14 = CPtr(Const ZString Ptr Ptr, @(local6[c2fb_temp_13]))
            c2fb_temp_15 = CPtr(Const ZString Ptr, local1)
            (*c2fb_temp_14) = c2fb_temp_15
            c2fb_temp_16 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[local2]))
            c2fb_temp_17 = Cast(Byte, Cast(c2fb_c_int, 0))
            (*c2fb_temp_16) = c2fb_temp_17
            c2fb_external_sqlite3Fts3Dequote(local1)
            c2fb_temp_18 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))])))
            local1 = c2fb_temp_18
        c2fb_flow_1:
        Loop
        c2fb_flow_0:
        c2fb_temp_19 = Cast(c2fb_c_int, CPtr(c2fb_callback_77, local5->xCreate)(local7, local6, arg2))
        local0 = c2fb_temp_19
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3Fts3ErrMsg(arg3, StrPtr(!"unknown tokenizer"))
        Else
            c2fb_temp_20 = CPtr(Any Ptr Ptr, @(((*arg2))->pModule))
            c2fb_temp_21 = CPtr(Const Fts3TokenizerModule Ptr, local5)
            (*c2fb_temp_20) = CPtr(Any Ptr, c2fb_temp_21)
            c2fb_temp_21 = CPtr(Const Fts3TokenizerModule Ptr, (*c2fb_temp_20))
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local6))
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
    Return local0
End Function
#ifdef SQLITE_TEST
/' ------------------------------------------------------------------------- '/
/' Upstream tokenizer test SQL functions                                      '/
/' ------------------------------------------------------------------------- '/
Private Sub fts3TokenizerTest CDecl Alias "fts3TokenizerTest" ( _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As c2fb_c_int, _
    ByVal ppValue As Any Ptr Ptr _
)
    Dim pHash As c2fb_source_record_33 Ptr = _
        CPtr(c2fb_source_record_33 Ptr, c2fb_external_sqlite3_user_data(pContext))
    Dim pModule As Fts3TokenizerModule Ptr = 0
    Dim pTokenizer As Fts3Tokenizer Ptr = 0
    Dim pCursor As Fts3TokenizerCursor Ptr = 0
    Dim pList As Any Ptr = 0
    Dim zError As Const ZString Ptr = 0
    Dim zName As Const ZString Ptr
    Dim zInput As Const ZString Ptr
    Dim inputBytes As c2fb_c_int
    Dim argumentCountForTokenizer As c2fb_c_int
    Dim tokenizerArguments(0 To 63) As Const ZString Ptr
    Dim token As Const ZString Ptr = 0
    Dim tokenBytes As c2fb_c_int = 0
    Dim startOffset As c2fb_c_int = 0
    Dim endOffset As c2fb_c_int = 0
    Dim position As c2fb_c_int = 0
    Dim rc As c2fb_c_int
    Dim outOfMemory As c2fb_c_int = 0

    If argumentCount < 2 OrElse ppValue = 0 Then
        c2fb_external_sqlite3_result_error( _
            pContext, StrPtr(!"insufficient arguments"), -1)
        Return
    End If
    If pHash = 0 Then
        c2fb_external_sqlite3_result_error_code(pContext, SQLITE_MISUSE)
        Return
    End If

    zName = CPtr(Const ZString Ptr, _
        c2fb_external_sqlite3_value_text(ppValue[0]))
    zInput = CPtr(Const ZString Ptr, _
        c2fb_external_sqlite3_value_text(ppValue[argumentCount - 1]))
    inputBytes = c2fb_external_sqlite3_value_bytes(ppValue[argumentCount - 1])
    If zInput = 0 Then
        If inputBytes <> 0 Then
            c2fb_external_sqlite3_result_error_nomem(pContext)
            Return
        End If
        zInput = StrPtr(!"")
    End If

    If zName = 0 Then
        c2fb_external_sqlite3_result_error_nomem(pContext)
        Return
    End If
    Dim nameBytes As c2fb_c_int = _
        c2fb_external_sqlite3_value_bytes(ppValue[0])
    If nameBytes < 0 OrElse nameBytes = &H7FFFFFFF Then
        c2fb_external_sqlite3_result_error_toobig(pContext)
        Return
    End If
    pModule = CPtr(Fts3TokenizerModule Ptr, _
        c2fb_external_sqlite3Fts3HashFind( _
            pHash, CPtr(Const Any Ptr, zName), nameBytes + 1))
    If pModule = 0 Then
        Dim zUnknown As ZString Ptr = _
            c2fb_external_sqlite3_mprintf( _
                StrPtr(!"unknown tokenizer: %s"), zName)
        If zUnknown = 0 Then
            c2fb_external_sqlite3_result_error_nomem(pContext)
        Else
            c2fb_external_sqlite3_result_error(pContext, zUnknown, -1)
            c2fb_external_sqlite3_free(zUnknown)
        End If
        Return
    End If

    argumentCountForTokenizer = argumentCount - 2
    If argumentCountForTokenizer > 64 Then
        c2fb_external_sqlite3_result_error_toobig(pContext)
        Return
    End If
    For argumentIndex As c2fb_c_int = 0 To argumentCountForTokenizer - 1
        tokenizerArguments(argumentIndex) = CPtr(Const ZString Ptr, _
            c2fb_external_sqlite3_value_text(ppValue[argumentIndex + 1]))
        If tokenizerArguments(argumentIndex) = 0 Then
            c2fb_external_sqlite3_result_error_nomem(pContext)
            Return
        End If
    Next

    pList = Tcl_NewObj()
    If pList = 0 Then
        outOfMemory = 1
        Goto fts3_tokenizer_test_cleanup
    End If

    rc = pModule->xCreate( _
        argumentCountForTokenizer, @tokenizerArguments(0), @pTokenizer)
    If rc <> SQLITE_OK OrElse pTokenizer = 0 Then
        zError = StrPtr(!"error in xCreate()")
        Goto fts3_tokenizer_test_cleanup
    End If
    pTokenizer->pModule = CPtr(Any Ptr, pModule)

    rc = sqlite3Fts3OpenTokenizer( _
        pTokenizer, 0, zInput, inputBytes, @pCursor)
    If rc <> SQLITE_OK OrElse pCursor = 0 Then
        zError = StrPtr(!"error in xOpen()")
        Goto fts3_tokenizer_test_cleanup
    End If

    While pModule->xNext( _
        pCursor, @token, @tokenBytes, @startOffset, @endOffset, @position _
    ) = SQLITE_OK
        If tokenBytes < 0 OrElse startOffset < 0 OrElse _
           endOffset < startOffset OrElse endOffset > inputBytes OrElse _
           (token = 0 AndAlso tokenBytes <> 0) Then
            zError = StrPtr(!"invalid tokenizer offsets")
            Exit While
        End If

        Dim pElement As Any Ptr = Tcl_NewIntObj(position)
        If pElement = 0 Then
            outOfMemory = 1
            Exit While
        End If
        If Tcl_ListObjAppendElement(0, pList, pElement) <> 0 Then
            TclFreeObj(pElement)
            outOfMemory = 1
            Exit While
        End If

        pElement = Tcl_NewStringObj(token, tokenBytes)
        If pElement = 0 Then
            outOfMemory = 1
            Exit While
        End If
        If Tcl_ListObjAppendElement(0, pList, pElement) <> 0 Then
            TclFreeObj(pElement)
            outOfMemory = 1
            Exit While
        End If

        Dim zInputToken As Const ZString Ptr = CPtr( _
            Const ZString Ptr, CPtr(Const UByte Ptr, zInput) + startOffset)
        pElement = Tcl_NewStringObj(zInputToken, endOffset - startOffset)
        If pElement = 0 Then
            outOfMemory = 1
            Exit While
        End If
        If Tcl_ListObjAppendElement(0, pList, pElement) <> 0 Then
            TclFreeObj(pElement)
            outOfMemory = 1
            Exit While
        End If
    Wend

fts3_tokenizer_test_cleanup:
    If pCursor <> 0 Then
        If pModule->xClose(pCursor) <> SQLITE_OK AndAlso zError = 0 Then _
            zError = StrPtr(!"error in xClose()")
        pCursor = 0
    End If
    If pTokenizer <> 0 Then
        If pModule->xDestroy(pTokenizer) <> SQLITE_OK AndAlso zError = 0 Then _
            zError = StrPtr(!"error in xDestroy()")
        pTokenizer = 0
    End If

    If outOfMemory <> 0 Then
        c2fb_external_sqlite3_result_error_nomem(pContext)
    ElseIf zError <> 0 Then
        c2fb_external_sqlite3_result_error(pContext, zError, -1)
    ElseIf pList = 0 Then
        c2fb_external_sqlite3_result_error_nomem(pContext)
    Else
        Dim zResult As Const ZString Ptr = Tcl_GetString(pList)
        If zResult = 0 Then
            c2fb_external_sqlite3_result_error_nomem(pContext)
        Else
            c2fb_external_sqlite3_result_text( _
                pContext, zResult, -1, _
                CPtr(Any Ptr, Cast(Integer, -1)))
        End If
    End If
    If pList <> 0 Then TclFreeObj(pList)
End Sub

Private Function fts3QueryTokenizer( _
    ByVal pDatabase As Any Ptr, _
    ByVal zName As Const ZString Ptr, _
    ByVal ppModule As Fts3TokenizerModule Ptr Ptr _
) As c2fb_c_int
    If pDatabase = 0 OrElse zName = 0 OrElse ppModule = 0 Then _
        Return SQLITE_MISUSE
    ppModule[0] = 0

    Dim pStatement As Any Ptr = 0
    Dim rc As c2fb_c_int = c2fb_external_sqlite3_prepare_v2( _
        pDatabase, StrPtr(!"SELECT fts3_tokenizer(?)"), -1, @pStatement, 0)
    If rc = SQLITE_OK Then _
        rc = c2fb_external_sqlite3_bind_text( _
            pStatement, 1, zName, -1, 0)
    If rc = SQLITE_OK Then
        rc = c2fb_external_sqlite3_step(pStatement)
        If rc = SQLITE_ROW Then
            If c2fb_external_sqlite3_column_type(pStatement, 0) = SQLITE_BLOB AndAlso _
               c2fb_external_sqlite3_column_bytes(pStatement, 0) = SizeOf(Any Ptr) Then
                Dim pBlob As Const Any Ptr = _
                    c2fb_external_sqlite3_column_blob(pStatement, 0)
                If pBlob <> 0 Then _
                    ppModule[0] = CPtr(Fts3TokenizerModule Ptr, _
                        CPtr(Any Ptr Ptr, pBlob)[0])
            End If
            rc = SQLITE_OK
        ElseIf rc = SQLITE_DONE Then
            rc = SQLITE_OK
        End If
    End If
    If pStatement <> 0 Then
        Dim finalizeRc As c2fb_c_int = _
            c2fb_external_sqlite3_finalize(pStatement)
        If rc = SQLITE_OK Then rc = finalizeRc
    End If
    Return rc
End Function

Private Function fts3RegisterTokenizer( _
    ByVal pDatabase As Any Ptr, _
    ByVal zName As Const ZString Ptr, _
    ByVal pModule As Const Fts3TokenizerModule Ptr _
) As c2fb_c_int
    If pDatabase = 0 OrElse zName = 0 OrElse pModule = 0 Then _
        Return SQLITE_MISUSE

    Dim pStatement As Any Ptr = 0
    Dim rc As c2fb_c_int = c2fb_external_sqlite3_prepare_v2( _
        pDatabase, StrPtr(!"SELECT fts3_tokenizer(?, ?)"), -1, @pStatement, 0)
    If rc = SQLITE_OK Then _
        rc = c2fb_external_sqlite3_bind_text( _
            pStatement, 1, zName, -1, 0)
    Dim pModuleValue As Any Ptr = CPtr(Any Ptr, pModule)
    If rc = SQLITE_OK Then _
        rc = c2fb_external_sqlite3_bind_blob( _
            pStatement, 2, @pModuleValue, SizeOf(Any Ptr), 0)
    If rc = SQLITE_OK Then
        rc = c2fb_external_sqlite3_step(pStatement)
        If rc = SQLITE_ROW Then rc = SQLITE_OK
    End If
    If pStatement <> 0 Then
        Dim finalizeRc As c2fb_c_int = _
            c2fb_external_sqlite3_finalize(pStatement)
        If rc = SQLITE_OK Then rc = finalizeRc
    End If
    Return rc
End Function

Private Sub fts3TokenizerInternalTest CDecl Alias "fts3TokenizerInternalTest" ( _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As c2fb_c_int, _
    ByVal ppValue As Any Ptr Ptr _
)
    Dim pDatabase As Any Ptr = _
        c2fb_external_sqlite3_context_db_handle(pContext)
    Dim pSimple As Const Fts3TokenizerModule Ptr = 0
    Dim pQueried As Fts3TokenizerModule Ptr = 0
    Dim rc As c2fb_c_int
    Dim isEnabled As c2fb_c_int = fts3TokenizerEnabled(pContext)

    sqlite3Fts3SimpleTokenizerModule(@pSimple)
    rc = fts3QueryTokenizer(pDatabase, StrPtr(!"simple"), @pQueried)
    If rc <> SQLITE_OK Then
        Dim zErrorDetail As ZString Ptr = c2fb_external_sqlite3_mprintf( _
            StrPtr(!"simple tokenizer query failed: %d"), rc)
        If zErrorDetail <> 0 Then
            c2fb_external_sqlite3_result_error(pContext, zErrorDetail, -1)
            c2fb_external_sqlite3_free(zErrorDetail)
            Return
        End If
        c2fb_external_sqlite3_result_error( _
            pContext, StrPtr(!"simple tokenizer query failed"), -1)
        Return
    End If
    If pSimple = 0 Then
        c2fb_external_sqlite3_result_error( _
            pContext, StrPtr(!"simple tokenizer module is missing"), -1)
        Return
    End If
    If pQueried <> pSimple Then
        c2fb_external_sqlite3_result_error( _
            pContext, StrPtr(!"simple tokenizer pointer mismatch"), -1)
        Return
    End If

    rc = fts3QueryTokenizer( _
        pDatabase, StrPtr(!"nosuchtokenizer"), @pQueried)
    If rc <> SQLITE_ERROR OrElse pQueried <> 0 Then
        c2fb_external_sqlite3_result_error( _
            pContext, StrPtr(!"unknown tokenizer query failed"), -1)
        Return
    End If
    If sqlite3_stricmp( _
        c2fb_external_sqlite3_errmsg(pDatabase), _
        StrPtr(!"unknown tokenizer: nosuchtokenizer")) <> 0 Then
        c2fb_external_sqlite3_result_error( _
            pContext, StrPtr(!"unknown tokenizer error text mismatch"), -1)
        Return
    End If

    If isEnabled <> 0 Then
        rc = fts3RegisterTokenizer( _
            pDatabase, StrPtr(!"nosuchtokenizer"), pSimple)
        If rc <> SQLITE_OK Then
            c2fb_external_sqlite3_result_error( _
                pContext, StrPtr(!"tokenizer registration failed"), -1)
            Return
        End If
        rc = fts3QueryTokenizer( _
            pDatabase, StrPtr(!"nosuchtokenizer"), @pQueried)
        If rc <> SQLITE_OK OrElse pQueried <> pSimple Then
            c2fb_external_sqlite3_result_error( _
                pContext, StrPtr(!"registered tokenizer lookup failed"), -1)
            Return
        End If
    End If

    c2fb_external_sqlite3_result_text( _
        pContext, StrPtr(!"ok"), -1, 0)
End Sub
#endif

Function sqlite3Fts3InitHashTable CDecl Alias "sqlite3Fts3InitHashTable" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_33 Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
    If arg0 = 0 OrElse arg1 = 0 OrElse arg2 = 0 Then Return SQLITE_MISUSE
' c2fb source-path: ext/fts3/fts3_tokenizer.c
' c2fb source-line: 473
    Dim local0 As c2fb_c_int
    Dim local1 As Any Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
#ifdef SQLITE_TEST
    Dim zTest As ZString Ptr = 0
    Dim zTest2 As ZString Ptr = 0
#endif

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(Any Ptr, arg1)
    local2 = Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Or Cast(c2fb_c_int, &H000080000ULL)))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local0)))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_create_function(arg0, arg2, Cast(c2fb_c_int, 1ULL), local2, local1, ProcPtr(fts3TokenizerFunc), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local0)))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_create_function(arg0, arg2, Cast(c2fb_c_int, 2ULL), local2, local1, ProcPtr(fts3TokenizerFunc), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_1
    End If
#ifdef SQLITE_TEST
    If local0 = SQLITE_OK Then
        zTest = c2fb_external_sqlite3_mprintf(StrPtr(!"%s_test"), arg2)
        zTest2 = c2fb_external_sqlite3_mprintf(StrPtr(!"%s_internal_test"), arg2)
        If zTest = 0 OrElse zTest2 = 0 Then
            local0 = SQLITE_NOMEM
        End If
    End If
    If local0 = SQLITE_OK Then
        local0 = c2fb_external_sqlite3_create_function( _
            arg0, zTest, -1, local2, local1, _
            ProcPtr(fts3TokenizerTest), 0, 0)
    End If
    If local0 = SQLITE_OK Then
        local0 = c2fb_external_sqlite3_create_function( _
            arg0, zTest2, 0, local2, arg0, _
            ProcPtr(fts3TokenizerInternalTest), 0, 0)
    End If
    c2fb_external_sqlite3_free(zTest)
    c2fb_external_sqlite3_free(zTest2)
#endif
    Return local0
End Function

#endif

/' end of sqlite3_bulk_fts3_tokenizer_registry.bas '/
