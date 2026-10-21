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

    File: fts3_candidates/sqlite3_bulk_fts3_tokenizer_candidates.bas

    Purpose:

        Preserve C2FB candidates from ext/fts3/fts3_tokenizer.c for review.

    Responsibilities:

        - Translate tokenizer name scanning and callback dispatch.
        - Keep the generated bodies outside the linked library until reviewed.

    This file intentionally does NOT contain:

        - The FTS3 full-text table engine and test-only tokenizer commands.
        - FTS3 tokenizer security policy beyond the translated callback paths.
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
Declare Function c2fb_external_sqlite3Fts3HashInsert CDecl Alias "sqlite3Fts3HashInsert" (ByVal arg0 As c2fb_source_record_33 Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3Fts3HashFind CDecl Alias "sqlite3Fts3HashFind" (ByVal arg0 As Const c2fb_source_record_33 Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub c2fb_external_sqlite3Fts3Dequote CDecl Alias "sqlite3Fts3Dequote" (ByVal arg0 As ZString Ptr)
Private Function fts3TokenizerEnabled CDecl Alias "fts3TokenizerEnabled" (ByVal arg0 As Any Ptr) As c2fb_c_int
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
Function sqlite3Fts3InitHashTable CDecl Alias "sqlite3Fts3InitHashTable" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_source_record_33 Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer.c
' c2fb source-line: 473
    Dim local0 As c2fb_c_int
    Dim local1 As Any Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

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
    Return local0
End Function

#endif

/' end of sqlite3_bulk_fts3_tokenizer_candidates.bas '/
