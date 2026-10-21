/'
** 2015 May 08
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

    File: sqlite3_bulk_fts5_vocab.bas

    Purpose:

        Port the FTS5 vocabulary virtual-table implementation.

    Responsibilities:

        - Expose term, row, and instance vocabulary queries.
        - Register the fts5vocab virtual-table module.

    This file intentionally does NOT contain:

        - FTS5 index construction or query parsing.
        - The upstream Tcl test adapter.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_vocab_types.bi"
#include once "sqlite3_fts5_module_types.bi"
#include once "sqlite3_fts5_module_types.bi"

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

Private Function __c2fb_double_value(ByVal value As Double) As Double
    Return value
End Function
Declare Function fts5VocabTableType CDecl Alias "fts5VocabTableType" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5VocabDisconnectMethod CDecl Alias "fts5VocabDisconnectMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5VocabDestroyMethod CDecl Alias "fts5VocabDestroyMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5VocabInitVtab CDecl Alias "fts5VocabInitVtab" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5VocabConnectMethod CDecl Alias "fts5VocabConnectMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5VocabCreateMethod CDecl Alias "fts5VocabCreateMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5VocabIsBinary CDecl Alias "fts5VocabIsBinary" (ByVal arg0 As c2fb_sqlite3_index_info Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5VocabBestIndexMethod CDecl Alias "fts5VocabBestIndexMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_index_info Ptr) As c2fb_c_int
Declare Function fts5VocabOpenMethod CDecl Alias "fts5VocabOpenMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_vtab_cursor Ptr Ptr) As c2fb_c_int
Declare Sub fts5VocabResetCursor CDecl Alias "fts5VocabResetCursor" (ByVal arg0 As c2fb_Fts5VocabCursor Ptr)
Declare Function fts5VocabCloseMethod CDecl Alias "fts5VocabCloseMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5VocabInstanceNewTerm CDecl Alias "fts5VocabInstanceNewTerm" (ByVal arg0 As c2fb_Fts5VocabCursor Ptr) As c2fb_c_int
Declare Function fts5VocabInstanceNext CDecl Alias "fts5VocabInstanceNext" (ByVal arg0 As c2fb_Fts5VocabCursor Ptr) As c2fb_c_int
Declare Function fts5VocabNextMethod CDecl Alias "fts5VocabNextMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5VocabValueText CDecl Alias "fts5VocabValueText" (ByVal arg0 As c2fb_sqlite3_value Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const ZString Ptr
Declare Function fts5VocabFilterMethod CDecl Alias "fts5VocabFilterMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
Declare Function fts5VocabEofMethod CDecl Alias "fts5VocabEofMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5VocabColumnMethod CDecl Alias "fts5VocabColumnMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_sqlite3_context Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5VocabRowidMethod CDecl Alias "fts5VocabRowidMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_create_module_v2 CDecl Alias "sqlite3_create_module_v2" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As Any Ptr, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_prepare_v2 CDecl Alias "sqlite3_prepare_v2" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int64 CDecl Alias "sqlite3_column_int64" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function c2fb_external_sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_type CDecl Alias "sqlite3_value_type" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3_result_int CDecl Alias "sqlite3_result_int" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_int64 CDecl Alias "sqlite3_result_int64" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_int64)
Declare Sub c2fb_external_sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_destructor_type)
Declare Function c2fb_external_sqlite3_declare_vtab CDecl Alias "sqlite3_declare_vtab" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vtab_collation CDecl Alias "sqlite3_vtab_collation" (ByVal arg0 As c2fb_sqlite3_index_info Ptr, ByVal arg1 As c2fb_c_int) As Const ZString Ptr
Declare Sub c2fb_external_sqlite3Fts5Dequote CDecl Alias "sqlite3Fts5Dequote" (ByVal arg0 As ZString Ptr)
Declare Sub c2fb_external_sqlite3Fts5BufferFree CDecl Alias "sqlite3Fts5BufferFree" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
Declare Sub c2fb_external_sqlite3Fts5BufferSet CDecl Alias "sqlite3Fts5BufferSet" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
Declare Function c2fb_external_sqlite3Fts5Mprintf CDecl Alias "sqlite3Fts5Mprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3Fts5PoslistNext64 CDecl Alias "sqlite3Fts5PoslistNext64" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5MallocZero CDecl Alias "sqlite3Fts5MallocZero" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function c2fb_external_sqlite3Fts5Strndup CDecl Alias "sqlite3Fts5Strndup" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As ZString Ptr
Declare Function c2fb_external_sqlite3Fts5IndexQuery CDecl Alias "sqlite3Fts5IndexQuery" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5Colset Ptr, ByVal arg5 As c2fb_Fts5IndexIter Ptr Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5IterClose CDecl Alias "sqlite3Fts5IterClose" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
Declare Function c2fb_external_sqlite3Fts5IterTerm CDecl Alias "sqlite3Fts5IterTerm" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3Fts5IterNextScan CDecl Alias "sqlite3Fts5IterNextScan" (ByVal arg0 As c2fb_Fts5IndexIter Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StructureRef CDecl Alias "sqlite3Fts5StructureRef" (ByVal arg0 As c2fb_Fts5Index Ptr) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts5StructureRelease CDecl Alias "sqlite3Fts5StructureRelease" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3Fts5StructureTest CDecl Alias "sqlite3Fts5StructureTest" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5GetVarint32 CDecl Alias "sqlite3Fts5GetVarint32" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_uint Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5TableFromCsrid CDecl Alias "sqlite3Fts5TableFromCsrid" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Table Ptr
Declare Function c2fb_external_sqlite3Fts5FlushToDisk CDecl Alias "sqlite3Fts5FlushToDisk" (ByVal arg0 As c2fb_Fts5Table Ptr) As c2fb_c_int
Private Function fts5VocabTableType CDecl Alias "fts5VocabTableType" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 107
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Strndup(CPtr(c2fb_c_int Ptr, @(local0)), arg0, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3Fts5Dequote(local1)
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, local1), StrPtr(!"col")) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_0) = c2fb_temp_1
        Else
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, local1), StrPtr(!"row")) = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_2) = c2fb_temp_3
            Else
                If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, local1), StrPtr(!"instance")) = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                    (*c2fb_temp_4) = c2fb_temp_5
                Else
                    c2fb_temp_6 = CPtr(ZString Ptr Ptr, @((*arg1)))
                    c2fb_temp_7 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"fts5vocab: unknown table type: %Q"), local1))
                    (*c2fb_temp_6) = c2fb_temp_7
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local0 = c2fb_temp_8
                End If
            End If
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Return local0
End Function
Private Function fts5VocabDisconnectMethod CDecl Alias "fts5VocabDisconnectMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 136
    Dim local0 As c2fb_Fts5VocabTable Ptr

    local0 = CPtr(c2fb_Fts5VocabTable Ptr, arg0)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5VocabDestroyMethod CDecl Alias "fts5VocabDestroyMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 145
    Dim local0 As c2fb_Fts5VocabTable Ptr

    local0 = CPtr(c2fb_Fts5VocabTable Ptr, arg0)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5VocabInitVtab CDecl Alias "fts5VocabInitVtab" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 172
    Dim local0(0 To 2) As Const ZString Ptr
    Dim local1 As c2fb_Fts5VocabTable Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim local5 As Const ZString Ptr
    Dim local6 As Const ZString Ptr
    Dim local7 As Const ZString Ptr
    Dim local8 As c2fb_int64
    Dim local9 As c2fb_int64
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_Fts5VocabTable Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Global_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Global Ptr
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_13 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_14 As ZString Ptr Ptr
    Dim c2fb_temp_15 As ZString Ptr
    Dim c2fb_temp_16 As ZString Ptr Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As Any Ptr
    Dim c2fb_temp_19 As Any Ptr
    Dim c2fb_temp_20 As c2fb_sqlite3_vtab Ptr Ptr
    Dim c2fb_temp_21 As c2fb_sqlite3_vtab Ptr

    Erase local0
    local0(0) = StrPtr(!"CREATE TABlE vocab(term, col, doc, cnt)")
    local0(1) = StrPtr(!"CREATE TABlE vocab(term, doc, cnt)")
    local0(2) = StrPtr(!"CREATE TABlE vocab(term, doc, col, offset)")
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 6ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_uint64, c2fb_crt_strlen(arg3[Cast(c2fb_c_int, 1ULL)])) = Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"temp")), CPtr(Const Any Ptr, arg3[Cast(c2fb_c_int, 1ULL)]), Cast(c2fb_c_int, 4ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))))
    local3 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 <> Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @((*arg5)))
        c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"wrong number of vtable arguments")))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local2 = c2fb_temp_3
    Else
        ' C automatic storage declaration
        local5 = IIf(local3, arg3[Cast(c2fb_c_int, 3ULL)], arg3[Cast(c2fb_c_int, 1ULL)])
        local6 = IIf(local3, arg3[Cast(c2fb_c_int, 4ULL)], arg3[Cast(c2fb_c_int, 3ULL)])
        local7 = IIf(local3, arg3[Cast(c2fb_c_int, 5ULL)], arg3[Cast(c2fb_c_int, 4ULL)])
        local8 = Cast(c2fb_uint64, (Cast(c2fb_uint64, c2fb_crt_strlen(local5)) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))))
        local9 = Cast(c2fb_uint64, (Cast(c2fb_uint64, c2fb_crt_strlen(local6)) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))))
        local10 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_4 = Cast(c2fb_c_int, fts5VocabTableType(local7, arg5, CPtr(c2fb_c_int Ptr, @(local10))))
        local2 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C unused-parameter annotation
            c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_declare_vtab(arg0, local0(local10)))
            local2 = c2fb_temp_5
        End If
        c2fb_temp_6 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5VocabTable))) + Cast(c2fb_uint64, local8))) + Cast(c2fb_uint64, local9))))
        local4 = c2fb_temp_6
        c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5VocabTable Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local2)), local4)))
        local1 = c2fb_temp_7
        If local1 Then
            c2fb_temp_8 = CPtr(c2fb_Fts5Global_ Ptr Ptr, @(local1->pGlobal))
            c2fb_temp_9 = CPtr(c2fb_Fts5Global Ptr, arg1)
            (*c2fb_temp_8) = CPtr(c2fb_Fts5Global_ Ptr, c2fb_temp_9)
            c2fb_temp_9 = CPtr(c2fb_Fts5Global Ptr, (*c2fb_temp_8))
            c2fb_temp_10 = CPtr(Long Ptr, @(local1->eType))
            c2fb_temp_11 = Cast(c2fb_c_int, local10)
            (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
            c2fb_temp_12 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(local1->db))
            c2fb_temp_13 = arg0
            (*c2fb_temp_12) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_13)
            c2fb_temp_13 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_12))
            c2fb_temp_14 = CPtr(ZString Ptr Ptr, @(local1->zFts5Tbl))
            c2fb_temp_15 = CPtr(ZString Ptr, CPtr(c2fb_Fts5VocabTable Ptr, @(CPtr(c2fb_Fts5VocabTable Ptr, local1)[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_14) = c2fb_temp_15
            c2fb_temp_16 = CPtr(ZString Ptr Ptr, @(local1->zFts5Db))
            c2fb_temp_17 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1->zFts5Tbl)[local9])))
            (*c2fb_temp_16) = c2fb_temp_17
            c2fb_temp_18 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->zFts5Tbl), CPtr(Const Any Ptr, local6), local9))
            c2fb_temp_19 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->zFts5Db), CPtr(Const Any Ptr, local5), local8))
            c2fb_external_sqlite3Fts5Dequote(local1->zFts5Tbl)
            c2fb_external_sqlite3Fts5Dequote(local1->zFts5Db)
        End If
    End If
    c2fb_temp_20 = CPtr(c2fb_sqlite3_vtab Ptr Ptr, @((*arg4)))
    c2fb_temp_21 = CPtr(_c2fb_record_c2fb_sqlite3_vtab Ptr, CPtr(c2fb_sqlite3_vtab Ptr, local1))
    (*c2fb_temp_20) = c2fb_temp_21
    Return local2
End Function
Private Function fts5VocabConnectMethod CDecl Alias "fts5VocabConnectMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 234
    Return fts5VocabInitVtab(arg0, arg1, arg2, arg3, arg4, arg5)
End Function
Private Function fts5VocabCreateMethod CDecl Alias "fts5VocabCreateMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 244
    Return fts5VocabInitVtab(arg0, arg1, arg2, arg3, arg4, arg5)
End Function
Private Function fts5VocabIsBinary CDecl Alias "fts5VocabIsBinary" (ByVal arg0 As c2fb_sqlite3_index_info Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 259
    Return (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"binary"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_vtab_collation(arg0, arg1)))))))
End Function
Private Function fts5VocabBestIndexMethod CDecl Alias "fts5VocabBestIndexMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_index_info Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 275
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local6 As c2fb_sqlite3_index_constraint Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Double Ptr
    Dim c2fb_temp_13 As Double
    Dim c2fb_temp_14 As Double Ptr
    Dim c2fb_temp_15 As Double
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Double Ptr
    Dim c2fb_temp_22 As Double
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Long Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As Double Ptr
    Dim c2fb_temp_29 As Double
    Dim c2fb_temp_30 As Long Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As Long Ptr
    Dim c2fb_temp_33 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local3 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local4 = Cast(c2fb_c_int, arg1->colUsed)
    local5 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1->nConstraint))))
        local6 = CPtr(c2fb_sqlite3_index_constraint Ptr, @(CPtr(c2fb_sqlite3_index_constraint Ptr, CPtr(c2fb_sqlite3_index_constraint Ptr, arg1->aConstraint))[local0]))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->usable) = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_1
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6->iColumn = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (fts5VocabIsBinary(arg1, local0) <> 0))))) Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->op) = Cast(c2fb_c_int, 2ULL))))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, local0)
                local1 = c2fb_temp_2
            End If
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->op) = Cast(c2fb_c_int, 8ULL))))) Then
                c2fb_temp_3 = Cast(c2fb_c_int, local0)
                local3 = c2fb_temp_3
            End If
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->op) = Cast(c2fb_c_int, 16ULL))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, local0)
                local3 = c2fb_temp_4
            End If
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->op) = Cast(c2fb_c_int, 32ULL))))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, local0)
                local2 = c2fb_temp_5
            End If
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->op) = Cast(c2fb_c_int, 4ULL))))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, local0)
                local2 = c2fb_temp_6
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 Or Cast(c2fb_c_int, &H0100ULL))))
        local4 = c2fb_temp_7
        c2fb_temp_10 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local1].argvIndex))
        c2fb_temp_8 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
        c2fb_temp_9 = local5
        c2fb_temp_11 = Cast(c2fb_c_int, c2fb_temp_9)
        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        c2fb_temp_12 = CPtr(Double Ptr, @(arg1->estimatedCost))
        c2fb_temp_13 = Cast(Double, Cast(c2fb_c_int, 100ULL))
        (*c2fb_temp_12) = c2fb_temp_13
    Else
        c2fb_temp_14 = CPtr(Double Ptr, @(arg1->estimatedCost))
        c2fb_temp_15 = Cast(Double, Cast(c2fb_c_int, 1000000ULL))
        (*c2fb_temp_14) = c2fb_temp_15
        If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 Or Cast(c2fb_c_int, &H0200ULL))))
            local4 = c2fb_temp_16
            c2fb_temp_19 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local2].argvIndex))
            c2fb_temp_17 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
            c2fb_temp_18 = local5
            c2fb_temp_20 = Cast(c2fb_c_int, c2fb_temp_18)
            (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
            c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
            c2fb_temp_21 = CPtr(Double Ptr, @(arg1->estimatedCost))
            c2fb_temp_22 = Cast(Double, __c2fb_double_value(Cast(Double, (arg1->estimatedCost / Cast(Double, Cast(c2fb_c_int, 2ULL))))))
            (*c2fb_temp_21) = c2fb_temp_22
        End If
        If (-Cast(c2fb_c_int, ((local3 >= Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 Or Cast(c2fb_c_int, &H0400ULL))))
            local4 = c2fb_temp_23
            c2fb_temp_26 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local3].argvIndex))
            c2fb_temp_24 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_24 + 1)))
            c2fb_temp_25 = local5
            c2fb_temp_27 = Cast(c2fb_c_int, c2fb_temp_25)
            (*c2fb_temp_26) = Cast(Long, c2fb_temp_27)
            c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
            c2fb_temp_28 = CPtr(Double Ptr, @(arg1->estimatedCost))
            c2fb_temp_29 = Cast(Double, __c2fb_double_value(Cast(Double, (arg1->estimatedCost / Cast(Double, Cast(c2fb_c_int, 2ULL))))))
            (*c2fb_temp_28) = c2fb_temp_29
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->nOrderBy = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_index_orderby Ptr, CPtr(c2fb_sqlite3_index_orderby Ptr, arg1->aOrderBy))[Cast(c2fb_c_int, &O0ULL)].iColumn = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(c2fb_sqlite3_index_orderby Ptr, CPtr(c2fb_sqlite3_index_orderby Ptr, arg1->aOrderBy))[Cast(c2fb_c_int, &O0ULL)].desc) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_30 = CPtr(Long Ptr, @(arg1->orderByConsumed))
        c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_30) = Cast(Long, c2fb_temp_31)
        c2fb_temp_31 = Cast(c2fb_c_int, (*c2fb_temp_30))
    End If
    c2fb_temp_32 = CPtr(Long Ptr, @(arg1->idxNum))
    c2fb_temp_33 = Cast(c2fb_c_int, local4)
    (*c2fb_temp_32) = Cast(Long, c2fb_temp_33)
    c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5VocabOpenMethod CDecl Alias "fts5VocabOpenMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_vtab_cursor Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 339
    Dim local0 As c2fb_Fts5VocabTable Ptr
    Dim local1 As c2fb_Fts5Table Ptr
    Dim local2 As c2fb_Fts5VocabCursor Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_sqlite3_stmt Ptr
    Dim local5 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As ULong Ptr
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim local6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_Fts5Table Ptr
    Dim c2fb_temp_8 As ULong Ptr
    Dim c2fb_temp_9 As c2fb_c_uint
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local7 As c2fb_int64
    Dim c2fb_temp_16 As c2fb_Fts5VocabCursor Ptr
    Dim c2fb_temp_17 As c2fb_Fts5Table_ Ptr Ptr
    Dim c2fb_temp_18 As c2fb_Fts5Table Ptr
    Dim c2fb_temp_19 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_20 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_21 As c2fb_i64 Ptr Ptr
    Dim c2fb_temp_22 As c2fb_int64 Ptr
    Dim c2fb_temp_23 As c2fb_i64 Ptr Ptr
    Dim c2fb_temp_24 As c2fb_int64 Ptr
    Dim c2fb_temp_25 As c2fb_sqlite3_vtab_cursor Ptr Ptr
    Dim c2fb_temp_26 As c2fb_sqlite3_vtab_cursor Ptr

    local0 = CPtr(c2fb_Fts5VocabTable Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    If local0->bBusy Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @(arg0->zErrMsg))
        c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"recursive definition for %s.%s"), local0->zFts5Db, local0->zFts5Tbl))
        (*c2fb_temp_0) = c2fb_temp_1
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local3)), StrPtr(!"SELECT t.%Q FROM %Q.%Q AS t WHERE t.%Q MATCH '*id'"), local0->zFts5Tbl, local0->zFts5Db, local0->zFts5Tbl, local0->zFts5Tbl))
    local5 = c2fb_temp_2
    If local5 Then
        c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2(CPtr(c2fb_sqlite3 Ptr, local0->db), CPtr(Const ZString Ptr, local5), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local4)), Cast(c2fb_c_int, &O0ULL)))
        local3 = c2fb_temp_3
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local5))
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_4
    End If
    c2fb_temp_5 = CPtr(ULong Ptr, @(local0->bBusy))
    c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_5) = Cast(ULong, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_uint, (*c2fb_temp_5))
    If (-Cast(c2fb_c_int, (((local4 <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local4) = Cast(c2fb_c_int, 100ULL))))) <> 0))))) Then
        local6 = c2fb_external_sqlite3_column_int64(local4, Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Table Ptr, CPtr(c2fb_Fts5Table Ptr, c2fb_external_sqlite3Fts5TableFromCsrid(CPtr(c2fb_Fts5Global Ptr, local0->pGlobal), local6)))
        local1 = c2fb_temp_7
    End If
    c2fb_temp_8 = CPtr(ULong Ptr, @(local0->bBusy))
    c2fb_temp_9 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_8) = Cast(ULong, c2fb_temp_9)
    c2fb_temp_9 = Cast(c2fb_c_uint, (*c2fb_temp_8))
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize(local4))
            local3 = c2fb_temp_10
            c2fb_temp_11 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local4 = c2fb_temp_11
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_12 = CPtr(ZString Ptr Ptr, @(arg0->zErrMsg))
                c2fb_temp_13 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"no such fts5 table: %s.%s"), local0->zFts5Db, local0->zFts5Tbl))
                (*c2fb_temp_12) = c2fb_temp_13
                c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local3 = c2fb_temp_14
            End If
        Else
            c2fb_temp_15 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5FlushToDisk(local1))
            local3 = c2fb_temp_15
        End If
    End If
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        local7 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, CPtr(c2fb_Fts5Config Ptr, local1->pConfig)->nCol) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5VocabCursor)))))
        c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5VocabCursor Ptr, CPtr(c2fb_Fts5VocabCursor Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local3)), local7))))
        local2 = c2fb_temp_16
    End If
    If local2 Then
        c2fb_temp_17 = CPtr(c2fb_Fts5Table_ Ptr Ptr, @(local2->pFts5))
        c2fb_temp_18 = CPtr(_c2fb_record_c2fb_Fts5Table Ptr, local1)
        (*c2fb_temp_17) = CPtr(c2fb_Fts5Table_ Ptr, c2fb_temp_18)
        c2fb_temp_18 = CPtr(c2fb_Fts5Table Ptr, (*c2fb_temp_17))
        c2fb_temp_19 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(local2->pStmt))
        c2fb_temp_20 = local4
        (*c2fb_temp_19) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_20)
        c2fb_temp_20 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_19))
        c2fb_temp_21 = CPtr(c2fb_i64 Ptr Ptr, @(local2->aCnt))
        c2fb_temp_22 = CPtr(c2fb_int64 Ptr, CPtr(c2fb_Fts5VocabCursor Ptr, @(CPtr(c2fb_Fts5VocabCursor Ptr, local2)[Cast(c2fb_c_int, 1ULL)])))
        (*c2fb_temp_21) = CPtr(c2fb_i64 Ptr, c2fb_temp_22)
        c2fb_temp_22 = CPtr(c2fb_int64 Ptr, (*c2fb_temp_21))
        c2fb_temp_23 = CPtr(c2fb_i64 Ptr Ptr, @(local2->aDoc))
        c2fb_temp_24 = CPtr(c2fb_int64 Ptr, @(local2->aCnt[CPtr(c2fb_Fts5Config Ptr, local1->pConfig)->nCol]))
        (*c2fb_temp_23) = CPtr(c2fb_i64 Ptr, c2fb_temp_24)
        c2fb_temp_24 = CPtr(c2fb_int64 Ptr, (*c2fb_temp_23))
    Else
        c2fb_external_sqlite3_finalize(local4)
    End If
    c2fb_temp_25 = CPtr(c2fb_sqlite3_vtab_cursor Ptr Ptr, @((*arg1)))
    c2fb_temp_26 = CPtr(_c2fb_record_c2fb_sqlite3_vtab_cursor Ptr, CPtr(c2fb_sqlite3_vtab_cursor Ptr, local2))
    (*c2fb_temp_25) = c2fb_temp_26
    Return local3
End Function
Private Sub fts5VocabResetCursor CDecl Alias "fts5VocabResetCursor" (ByVal arg0 As c2fb_Fts5VocabCursor Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 411
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_Fts5IndexIter_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5IndexIter Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_i64 Ptr
    Dim c2fb_temp_15 As c2fb_int64
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Any Ptr
    Dim c2fb_temp_21 As Any Ptr

    local0 = CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, arg0->pFts5)->pConfig)->nCol
    c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->rowid))
    c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    c2fb_external_sqlite3Fts5IterClose(CPtr(c2fb_Fts5IndexIter Ptr, arg0->pIter))
    c2fb_external_sqlite3Fts5StructureRelease(arg0->pStruct)
    c2fb_temp_2 = CPtr(Any Ptr Ptr, @(arg0->pStruct))
    c2fb_temp_3 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_Fts5IndexIter_ Ptr Ptr, @(arg0->pIter))
    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_4) = CPtr(c2fb_Fts5IndexIter_ Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(c2fb_Fts5IndexIter Ptr, (*c2fb_temp_4))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zLeTerm))
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->nLeTerm))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(ZString Ptr Ptr, @(arg0->zLeTerm))
    c2fb_temp_9 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(Long Ptr, @(arg0->bEof))
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
    c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
    c2fb_temp_12 = CPtr(Long Ptr, @(arg0->iCol))
    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
    c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
    c2fb_temp_14 = CPtr(c2fb_i64 Ptr, @(arg0->iInstPos))
    c2fb_temp_15 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_14) = Cast(c2fb_i64, c2fb_temp_15)
    c2fb_temp_15 = Cast(c2fb_int64, (*c2fb_temp_14))
    c2fb_temp_16 = CPtr(Long Ptr, @(arg0->iInstOff))
    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
    c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
    c2fb_temp_18 = CPtr(Long Ptr, @(arg0->colUsed))
    c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
    c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
    c2fb_temp_20 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0->aCnt), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, local0)))))
    c2fb_temp_21 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0->aDoc), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, local0)))))
End Sub
Private Function fts5VocabCloseMethod CDecl Alias "fts5VocabCloseMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 434
    Dim local0 As c2fb_Fts5VocabCursor Ptr

    local0 = CPtr(c2fb_Fts5VocabCursor Ptr, arg0)
    fts5VocabResetCursor(local0)
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local0->term)))
    c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, local0->pStmt))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5VocabInstanceNewTerm CDecl Alias "fts5VocabInstanceNewTerm" (ByVal arg0 As c2fb_Fts5VocabCursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 443
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If ((CPtr(c2fb_Fts5IndexIter Ptr, arg0->pIter))->bEof) Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->bEof))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    Else
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(Const ZString Ptr, c2fb_external_sqlite3Fts5IterTerm(CPtr(c2fb_Fts5IndexIter Ptr, arg0->pIter), CPtr(c2fb_c_int Ptr, @(local2))))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((arg0->nLeTerm >= Cast(c2fb_c_int, &O0ULL))))) Then
            local3 = (IIf(((-Cast(c2fb_c_int, (((local2) < (arg0->nLeTerm)))))), (local2), (arg0->nLeTerm)))
            local4 = c2fb_crt_memcmp(CPtr(Const Any Ptr, arg0->zLeTerm), CPtr(Const Any Ptr, local1), local3)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->nLeTerm < local2)))) <> 0)))))) <> 0))))) Then
                c2fb_temp_3 = CPtr(Long Ptr, @(arg0->bEof))
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
                c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            End If
        End If
        c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(local0)), CPtr(c2fb_Fts5Buffer Ptr, @(arg0->term)), local2, CPtr(Const UByte Ptr, local1))
    End If
    Return local0
End Function
Private Function fts5VocabInstanceNext CDecl Alias "fts5VocabInstanceNext" (ByVal arg0 As c2fb_Fts5VocabCursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 465
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5IndexIter Ptr
    Dim local3 As c2fb_int64 Ptr
    Dim local4 As c2fb_c_int Ptr
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, arg0->pFts5)->pConfig)->eDetail
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = CPtr(c2fb_Fts5IndexIter Ptr, arg0->pIter)
    local3 = CPtr(c2fb_int64 Ptr, @(arg0->iInstPos))
    local4 = CPtr(c2fb_c_int Ptr, @(arg0->iInstOff))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse (c2fb_external_sqlite3Fts5PoslistNext64(local2->pData, local2->nData, local4, local3) <> 0)))))
        c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->iInstPos))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->iInstOff))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNextScan(CPtr(c2fb_Fts5IndexIter Ptr, arg0->pIter)))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, fts5VocabInstanceNewTerm(arg0))
            local1 = c2fb_temp_5
            If (-Cast(c2fb_c_int, (((arg0->bEof <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                Goto c2fb_flow_0
            End If
        End If
        If local1 Then
            c2fb_temp_6 = CPtr(Long Ptr, @(arg0->bEof))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local1
End Function
Private Function fts5VocabNextMethod CDecl Alias "fts5VocabNextMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 497
    Dim local0 As c2fb_Fts5VocabCursor Ptr
    Dim local1 As c2fb_Fts5VocabTable Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_i64 Ptr
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As Any Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As Const UByte Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_int64
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_16 As Const UByte Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local13 As c2fb_c_uint
    Dim c2fb_temp_18 As c2fb_int64
    Dim c2fb_temp_19 As c2fb_c_uint
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_int64
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_c_uint
    Dim c2fb_temp_24 As c2fb_int64
    Dim c2fb_temp_25 As c2fb_int64
    Dim c2fb_temp_26 As c2fb_i64 Ptr
    Dim c2fb_temp_27 As c2fb_int64
    Dim c2fb_temp_28 As c2fb_i64 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_i64 Ptr
    Dim c2fb_temp_32 As c2fb_int64
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_i64 Ptr
    Dim c2fb_temp_35 As c2fb_int64
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_i64 Ptr
    Dim c2fb_temp_38 As c2fb_int64
    Dim c2fb_temp_39 As c2fb_i64 Ptr
    Dim c2fb_temp_40 As c2fb_int64
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As Const ZString Ptr
    Dim c2fb_temp_43 As Long Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5VocabCursor Ptr, arg0)
    local1 = CPtr(c2fb_Fts5VocabTable Ptr, CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab))
    local2 = CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, local0->pFts5)->pConfig)->nCol
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StructureTest(CPtr(c2fb_Fts5Index Ptr, CPtr(c2fb_Fts5Table Ptr, local0->pFts5)->pIndex), local0->pStruct))
    local3 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local3
    End If
    c2fb_temp_1 = CPtr(c2fb_i64 Ptr, @(local0->rowid))
    c2fb_temp_2 = Cast(c2fb_int64, (*c2fb_temp_1))
    (*c2fb_temp_1) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_2 + 1)))
    If (-Cast(c2fb_c_int, ((local1->eType = Cast(c2fb_c_int, 2ULL))))) Then
        Return fts5VocabInstanceNext(local0)
    End If
    If (-Cast(c2fb_c_int, ((local1->eType = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = CPtr(Long Ptr, @(local0->iCol))
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        While (-Cast(c2fb_c_int, ((local0->iCol < local2))))
            If local0->aDoc[local0->iCol] Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_5 = CPtr(Long Ptr, @(local0->iCol))
            c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
            (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        Wend
        c2fb_flow_0:
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->eType <> Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->iCol >= local2)))) <> 0))))) Then
        If ((CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter))->bEof) Then
            c2fb_temp_7 = CPtr(Long Ptr, @(local0->bEof))
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        Else
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_9 = CPtr(Const ZString Ptr, c2fb_external_sqlite3Fts5IterTerm(CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter), CPtr(c2fb_c_int Ptr, @(local5))))
            local4 = c2fb_temp_9
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local0->nLeTerm >= Cast(c2fb_c_int, &O0ULL))))) Then
                local6 = (IIf(((-Cast(c2fb_c_int, (((local5) < (local0->nLeTerm)))))), (local5), (local0->nLeTerm)))
                local7 = c2fb_crt_memcmp(CPtr(Const Any Ptr, local0->zLeTerm), CPtr(Const Any Ptr, local4), local6)
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->nLeTerm < local5)))) <> 0)))))) <> 0))))) Then
                    c2fb_temp_10 = CPtr(Long Ptr, @(local0->bEof))
                    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
                    c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
            End If
            c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(local3)), CPtr(c2fb_Fts5Buffer Ptr, @(local0->term)), local5, CPtr(Const UByte Ptr, local4))
            c2fb_temp_12 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0->aCnt), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, local2) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64)))))))
            c2fb_temp_13 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0->aDoc), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, local2) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64)))))))
            c2fb_temp_14 = CPtr(Long Ptr, @(local0->iCol))
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
            c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
            ' C unused-parameter annotation
            While (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL)))))
                local8 = CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, local0->pFts5)->pConfig)->eDetail
                ' C automatic storage declaration
                ' C automatic storage declaration
                local11 = Cast(c2fb_c_int, &O0ULL)
                local12 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_16 = CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter)->pData
                local9 = c2fb_temp_16
                c2fb_temp_17 = Cast(c2fb_c_int, CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter)->nData)
                local10 = c2fb_temp_17
                Select Case local1->eType
                    Case Cast(c2fb_c_int, 1ULL)
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((Cast(c2fb_c_int, (local0->colUsed And Cast(c2fb_c_int, &H04ULL)))) <> 0))))) Then
                            While (-Cast(c2fb_c_int, ((local11 < Cast(c2fb_int64, local10)))))
                                ' C automatic storage declaration
                                c2fb_temp_18 = local11
                                local11 = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_18 + 1)))
                                c2fb_temp_19 = Cast(c2fb_c_uint, (local9)[c2fb_temp_18])
                                local13 = c2fb_temp_19
                                If Cast(c2fb_c_uint, (local13 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))) Then
                                    c2fb_temp_20 = local11
                                    local11 = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_20 - 1)))
                                    c2fb_temp_21 = Cast(c2fb_int64, Cast(c2fb_int64, (local11 + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((local9)[local11]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local13)))))))))
                                    local11 = c2fb_temp_21
                                End If
                                ' empty C statement
                                If (-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))))) Then
                                    c2fb_temp_22 = local11
                                    local11 = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_22 + 1)))
                                    c2fb_temp_23 = Cast(c2fb_c_uint, (local9)[c2fb_temp_22])
                                    local13 = c2fb_temp_23
                                    If Cast(c2fb_c_uint, (local13 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))) Then
                                        c2fb_temp_24 = local11
                                        local11 = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_24 - 1)))
                                        c2fb_temp_25 = Cast(c2fb_int64, Cast(c2fb_int64, (local11 + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((local9)[local11]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local13)))))))))
                                        local11 = c2fb_temp_25
                                    End If
                                    ' empty C statement
                                Else
                                    c2fb_temp_26 = CPtr(c2fb_i64 Ptr, @(local0->aCnt[Cast(c2fb_c_int, &O0ULL)]))
                                    c2fb_temp_27 = Cast(c2fb_int64, (*c2fb_temp_26))
                                    (*c2fb_temp_26) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_27 + 1)))
                                End If
                            c2fb_flow_6:
                            Wend
                            c2fb_flow_5:
                        End If
                        c2fb_temp_28 = CPtr(c2fb_i64 Ptr, @(local0->aDoc[Cast(c2fb_c_int, &O0ULL)]))
                        c2fb_temp_29 = Cast(c2fb_int64, (*c2fb_temp_28))
                        (*c2fb_temp_28) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_29 + 1)))
                    Case Cast(c2fb_c_int, &O0ULL)
                        If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
                            local14 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                            While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3Fts5PoslistNext64(local9, local10, CPtr(c2fb_c_int Ptr, @(local12)), CPtr(c2fb_int64 Ptr, @(local11)))))))
                                local15 = Cast(c2fb_c_int, (Cast(c2fb_int64, ((Cast(c2fb_int64, (local11 Shr Cast(c2fb_c_int, 32ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL))))))
                                If (-Cast(c2fb_c_int, ((local14 <> local15)))) Then
                                    If (-Cast(c2fb_c_int, ((local15 >= local2)))) Then
                                        c2fb_temp_30 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                                        local3 = c2fb_temp_30
                                        Goto c2fb_flow_7
                                    End If
                                    c2fb_temp_31 = CPtr(c2fb_i64 Ptr, @(local0->aDoc[local15]))
                                    c2fb_temp_32 = Cast(c2fb_int64, (*c2fb_temp_31))
                                    (*c2fb_temp_31) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_32 + 1)))
                                    c2fb_temp_33 = Cast(c2fb_c_int, local15)
                                    local14 = c2fb_temp_33
                                End If
                                c2fb_temp_34 = CPtr(c2fb_i64 Ptr, @(local0->aCnt[local15]))
                                c2fb_temp_35 = Cast(c2fb_int64, (*c2fb_temp_34))
                                (*c2fb_temp_34) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_35 + 1)))
                            c2fb_flow_8:
                            Wend
                            c2fb_flow_7:
                        Else
                            If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, 2ULL))))) Then
                                While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3Fts5PoslistNext64(local9, local10, CPtr(c2fb_c_int Ptr, @(local12)), CPtr(c2fb_int64 Ptr, @(local11)))))))
                                    ' C unused-parameter annotation
                                    If (-Cast(c2fb_c_int, ((local11 >= Cast(c2fb_int64, local2))))) Then
                                        c2fb_temp_36 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                                        local3 = c2fb_temp_36
                                        Goto c2fb_flow_9
                                    End If
                                    c2fb_temp_37 = CPtr(c2fb_i64 Ptr, @(local0->aDoc[local11]))
                                    c2fb_temp_38 = Cast(c2fb_int64, (*c2fb_temp_37))
                                    (*c2fb_temp_37) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_38 + 1)))
                                c2fb_flow_10:
                                Wend
                                c2fb_flow_9:
                            Else
                                ' C unused-parameter annotation
                                c2fb_temp_39 = CPtr(c2fb_i64 Ptr, @(local0->aDoc[Cast(c2fb_c_int, &O0ULL)]))
                                c2fb_temp_40 = Cast(c2fb_int64, (*c2fb_temp_39))
                                (*c2fb_temp_39) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_40 + 1)))
                            End If
                        End If
                    Case Else
                        ' C unused-parameter annotation
                End Select
                c2fb_flow_4:
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_41 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNextScan(CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter)))
                    local3 = c2fb_temp_41
                End If
                If (-Cast(c2fb_c_int, ((local1->eType = Cast(c2fb_c_int, 2ULL))))) Then
                    Goto c2fb_flow_2
                End If
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_42 = CPtr(Const ZString Ptr, c2fb_external_sqlite3Fts5IterTerm(CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter), CPtr(c2fb_c_int Ptr, @(local5))))
                    local4 = c2fb_temp_42
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 <> local0->term.n)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (c2fb_crt_memcmp(CPtr(Const Any Ptr, local4), CPtr(Const Any Ptr, local0->term.p), local5) <> 0)))))) <> 0))))) Then
                        Goto c2fb_flow_2
                    End If
                    If ((CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter))->bEof) Then
                        Goto c2fb_flow_2
                    End If
                End If
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->bEof = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eType = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->iCol < local2)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->aDoc[local0->iCol] = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0)))))
            ' empty C statement
        c2fb_flow_12:
            c2fb_temp_43 = CPtr(Long Ptr, @(local0->iCol))
            c2fb_temp_44 = Cast(c2fb_c_int, (*c2fb_temp_43))
            (*c2fb_temp_43) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_44 + 1)))
        Wend
        c2fb_flow_11:
        If (-Cast(c2fb_c_int, ((local0->iCol = local2)))) Then
            c2fb_temp_45 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local3 = c2fb_temp_45
        End If
    End If
    Return local3
End Function
Private Function fts5VocabValueText CDecl Alias "fts5VocabValueText" (ByVal arg0 As c2fb_sqlite3_value Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 639
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg0) = Cast(c2fb_c_int, 3ULL))))) Then
        c2fb_temp_0 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg0)))
        local0 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes(arg0))
        local1 = c2fb_temp_1
    End If
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_3 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_2) = c2fb_temp_3
    Return local0
End Function
Private Function fts5VocabFilterMethod CDecl Alias "fts5VocabFilterMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 655
    Dim local0 As c2fb_Fts5VocabTable Ptr
    Dim local1 As c2fb_Fts5VocabCursor Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_sqlite3_value Ptr
    Dim local9 As c2fb_sqlite3_value Ptr
    Dim local10 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_2 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_5 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_8 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Const ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim local11 As Const ZString Ptr
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As ZString Ptr Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Any Ptr
    Dim local12 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Any Ptr Ptr
    Dim c2fb_temp_21 As Any Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5VocabTable Ptr, CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab))
    local1 = CPtr(c2fb_Fts5VocabCursor Ptr, arg0)
    local2 = local0->eType
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &H0008ULL)
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    local8 = Cast(c2fb_c_int, &O0ULL)
    local9 = Cast(c2fb_c_int, &O0ULL)
    local10 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    fts5VocabResetCursor(local1)
    If Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0100ULL))) Then
        c2fb_temp_0 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        c2fb_temp_1 = arg4[c2fb_temp_0]
        local8 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(local8) <> Cast(c2fb_c_int, 3ULL))))) Then
            c2fb_temp_2 = CPtr(c2fb_sqlite3_value Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local8 = c2fb_temp_2
        End If
    End If
    If Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0200ULL))) Then
        c2fb_temp_3 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        c2fb_temp_4 = arg4[c2fb_temp_3]
        local9 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(local9) <> Cast(c2fb_c_int, 3ULL))))) Then
            c2fb_temp_5 = CPtr(c2fb_sqlite3_value Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local9 = c2fb_temp_5
        End If
    End If
    If Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0400ULL))) Then
        c2fb_temp_6 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        c2fb_temp_7 = arg4[c2fb_temp_6]
        local10 = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(local10) <> Cast(c2fb_c_int, 3ULL))))) Then
            c2fb_temp_8 = CPtr(c2fb_sqlite3_value Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local10 = c2fb_temp_8
        End If
    End If
    c2fb_temp_9 = CPtr(Long Ptr, @(local1->colUsed))
    c2fb_temp_10 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
    c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
    If local8 Then
        c2fb_temp_11 = CPtr(Const ZString Ptr, fts5VocabValueText(local8, CPtr(c2fb_c_int Ptr, @(local7))))
        local6 = c2fb_temp_11
        c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H0080ULL))
        local5 = c2fb_temp_12
    Else
        If local9 Then
            c2fb_temp_13 = CPtr(Const ZString Ptr, fts5VocabValueText(local9, CPtr(c2fb_c_int Ptr, @(local7))))
            local6 = c2fb_temp_13
        End If
        If local10 Then
            local11 = CPtr(Const ZString Ptr, fts5VocabValueText(local10, CPtr(c2fb_c_int Ptr, @(local1->nLeTerm))))
            If (-Cast(c2fb_c_int, ((local11 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_14 = StrPtr(!"")
                local11 = c2fb_temp_14
            End If
            c2fb_temp_15 = CPtr(ZString Ptr Ptr, @(local1->zLeTerm))
            c2fb_temp_16 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, local1->nLeTerm) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
            (*c2fb_temp_15) = c2fb_temp_16
            If (-Cast(c2fb_c_int, ((local1->zLeTerm = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local3 = c2fb_temp_17
            Else
                c2fb_temp_18 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->zLeTerm), CPtr(Const Any Ptr, local11), Cast(c2fb_c_int, (local1->nLeTerm + Cast(c2fb_c_int, 1ULL)))))
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        local12 = CPtr(c2fb_Fts5Index Ptr, CPtr(c2fb_Fts5Table Ptr, local1->pFts5)->pIndex)
        c2fb_temp_19 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexQuery(local12, local6, local7, local5, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_Fts5IndexIter Ptr Ptr, @(local1->pIter))))
        local3 = c2fb_temp_19
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_20 = CPtr(Any Ptr Ptr, @(local1->pStruct))
            c2fb_temp_21 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5StructureRef(local12))
            (*c2fb_temp_20) = c2fb_temp_21
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
        c2fb_temp_22 = Cast(c2fb_c_int, fts5VocabInstanceNewTerm(local1))
        local3 = c2fb_temp_22
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (local1->bEof = 0))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, local1->pFts5)->pConfig)->eDetail <> Cast(c2fb_c_int, 1ULL))))) <> 0)))))) <> 0))))) Then
        c2fb_temp_23 = Cast(c2fb_c_int, fts5VocabNextMethod(arg0))
        local3 = c2fb_temp_23
    End If
    Return local3
End Function
Private Function fts5VocabEofMethod CDecl Alias "fts5VocabEofMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 736
    Dim local0 As c2fb_Fts5VocabCursor Ptr

    local0 = CPtr(c2fb_Fts5VocabCursor Ptr, arg0)
    Return local0->bEof
End Function
Private Function fts5VocabColumnMethod CDecl Alias "fts5VocabColumnMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_sqlite3_context Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 741
    Dim local0 As c2fb_Fts5VocabCursor Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim local4 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim local7 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5VocabCursor Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, local0->pFts5)->pConfig)->eDetail
    local2 = (CPtr(c2fb_Fts5VocabTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab))))->eType
    local3 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_text(arg1, CPtr(Const ZString Ptr, local0->term.p), local0->term.n, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
    Else
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 1ULL))))) Then
                If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, 1ULL))))) Then
                    local4 = CPtr(Const ZString Ptr, CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, local0->pFts5)->pConfig)->azCol[local0->iCol])
                    c2fb_external_sqlite3_result_text(arg1, local4, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
                End If
            Else
                If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 2ULL))))) Then
                    c2fb_temp_0 = Cast(c2fb_int64, local0->aDoc[local0->iCol])
                    local3 = c2fb_temp_0
                Else
                    c2fb_temp_1 = Cast(c2fb_int64, local0->aCnt[local0->iCol])
                    local3 = c2fb_temp_1
                End If
            End If
        Else
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) Then
                ' C unused-parameter annotation
                If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 1ULL))))) Then
                    c2fb_temp_2 = Cast(c2fb_int64, local0->aDoc[Cast(c2fb_c_int, &O0ULL)])
                    local3 = c2fb_temp_2
                Else
                    c2fb_temp_3 = Cast(c2fb_int64, local0->aCnt[Cast(c2fb_c_int, &O0ULL)])
                    local3 = c2fb_temp_3
                End If
            Else
                ' C unused-parameter annotation
                Select Case arg2
                    Case Cast(c2fb_c_int, 1ULL)
                        c2fb_external_sqlite3_result_int64(arg1, CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter)->iRowid)
                    Case Cast(c2fb_c_int, 2ULL)
                        local5 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, ((Cast(c2fb_int64, (local0->iInstPos Shr Cast(c2fb_c_int, 32ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL)))))))
                            local5 = c2fb_temp_4
                        Else
                            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 2ULL))))) Then
                                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, local0->iInstPos))
                                local5 = c2fb_temp_5
                            End If
                        End If
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, local0->pFts5)->pConfig)->nCol)))) <> 0))))) Then
                            local6 = CPtr(Const ZString Ptr, CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Table Ptr, local0->pFts5)->pConfig)->azCol[local5])
                            c2fb_external_sqlite3_result_text(arg1, local6, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
                        End If
                        Goto c2fb_flow_0
                    Case Else
                        ' C unused-parameter annotation
                        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                            local7 = Cast(c2fb_c_int, (Cast(c2fb_int64, (local0->iInstPos And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL))))))
                            c2fb_external_sqlite3_result_int(arg1, local7)
                        End If
                        Goto c2fb_flow_0
                End Select
                c2fb_flow_0:
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_external_sqlite3_result_int64(arg1, local3)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5VocabRowidMethod CDecl Alias "fts5VocabRowidMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb source-line: 813
    Dim local0 As c2fb_Fts5VocabCursor Ptr
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    local0 = CPtr(c2fb_Fts5VocabCursor Ptr, arg0)
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_int64, local0->rowid)
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Dim Shared As Const c2fb_Fts5SqliteModule fts5VocabModule = Type<c2fb_Fts5SqliteModule>( _
    2, _
    CPtr(Any Ptr, ProcPtr(fts5VocabCreateMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabConnectMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabBestIndexMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabDisconnectMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabDestroyMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabOpenMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabCloseMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabFilterMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabNextMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabEofMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabColumnMethod)), _
    CPtr(Any Ptr, ProcPtr(fts5VocabRowidMethod)), _
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 _
)

Function sqlite3Fts5VocabInit CDecl Alias "sqlite3Fts5VocabInit" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_sqlite3 Ptr) As c2fb_c_int
    Return c2fb_external_sqlite3_create_module_v2(arg1, _
        StrPtr(!"fts5vocab"), CPtr(Any Ptr, @fts5VocabModule), _
        CPtr(Any Ptr, arg0), 0)
End Function
#endif
/' end of sqlite3_bulk_fts5_vocab.bas '/
