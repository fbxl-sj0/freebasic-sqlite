/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_fts3_core_api.bi

    Purpose:

        Provide the public API declarations used by the staged FTS3 core.

    Responsibilities:

        - Reuse C ABI aliases from SQLite's generated API declaration file.
        - Limit declarations to the FTS3 core's direct API references.

    This file intentionally does NOT contain:

        - FTS3 private routines or database layouts.
        - SQLite test support.
'/
#include once "crt/stdarg.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_fts3_write_types.bi"

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

Declare Function sqlite3_column_blob CDecl Alias "sqlite3_column_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function sqlite3_column_bytes CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_column_count CDecl Alias "sqlite3_column_count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_column_int CDecl Alias "sqlite3_column_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_column_int64 CDecl Alias "sqlite3_column_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function sqlite3_column_name CDecl Alias "sqlite3_column_name" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Const ZString Ptr
Declare Function sqlite3_column_value CDecl Alias "sqlite3_column_value" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Any Ptr
Declare Function sqlite3_create_module_v2 CDecl Alias "sqlite3_create_module_v2" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const Any Ptr, ByVal arg3 As Any Ptr, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_overload_function CDecl Alias "sqlite3_overload_function" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_data_count CDecl Alias "sqlite3_data_count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_declare_vtab CDecl Alias "sqlite3_declare_vtab" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3_errmsg CDecl Alias "sqlite3_errmsg" (ByVal arg0 As Any Ptr) As Const ZString Ptr
Declare Function sqlite3_errstr CDecl Alias "sqlite3_errstr" (ByVal arg0 As c2fb_c_int) As Const ZString Ptr
Declare Function sqlite3_exec CDecl Alias "sqlite3_exec" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As Any Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function sqlite3_last_insert_rowid CDecl Alias "sqlite3_last_insert_rowid" (ByVal arg0 As Any Ptr) As c2fb_int64
Declare Function sqlite3_libversion_number CDecl Alias "sqlite3_libversion_number" () As c2fb_c_int
Declare Function sqlite3_malloc CDecl Alias "sqlite3_malloc" (ByVal arg0 As c2fb_c_int) As Any Ptr
Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function sqlite3_prepare CDecl Alias "sqlite3_prepare" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_reset CDecl Alias "sqlite3_reset" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Sub sqlite3_result_error CDecl Alias "sqlite3_result_error" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub sqlite3_result_error_code CDecl Alias "sqlite3_result_error_code" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub sqlite3_result_error_nomem CDecl Alias "sqlite3_result_error_nomem" (ByVal arg0 As Any Ptr)
Declare Sub sqlite3_result_int CDecl Alias "sqlite3_result_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub sqlite3_result_int64 CDecl Alias "sqlite3_result_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64)
Declare Sub sqlite3_result_pointer CDecl Alias "sqlite3_result_pointer" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Any Ptr)
Declare Sub sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr)
Declare Sub sqlite3_result_value CDecl Alias "sqlite3_result_value" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr)
Declare Sub sqlite3_set_last_insert_rowid CDecl Alias "sqlite3_set_last_insert_rowid" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64)
Declare Function sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3_strnicmp CDecl Alias "sqlite3_strnicmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_table_column_metadata CDecl Alias "sqlite3_table_column_metadata" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr, ByVal arg6 As c2fb_c_int Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3_value_int CDecl Alias "sqlite3_value_int" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_value_int64 CDecl Alias "sqlite3_value_int64" (ByVal arg0 As Any Ptr) As c2fb_int64
Declare Function sqlite3_value_numeric_type CDecl Alias "sqlite3_value_numeric_type" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_value_pointer CDecl Alias "sqlite3_value_pointer" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
Declare Function sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As Any Ptr) As Const UByte Ptr
Declare Function sqlite3_value_type CDecl Alias "sqlite3_value_type" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_vtab_config CDecl Alias "sqlite3_vtab_config" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ...) As c2fb_c_int
Declare Function sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function sqlite3_bind_int64 CDecl Alias "sqlite3_bind_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3_bind_value CDecl Alias "sqlite3_bind_value" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr) As c2fb_c_int
Declare Function sqlite3Fts3SegReaderCursor CDecl Alias "sqlite3Fts3SegReaderCursor" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As SqliteFts3MultiSegReader Ptr) As c2fb_c_int
Declare Function sqlite3Fts3Init CDecl Alias "sqlite3Fts3Init" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3Fts3InitAux CDecl Alias "sqlite3Fts3InitAux" (ByVal arg0 As Any Ptr) As c2fb_c_int
#if defined(SQLITE_TEST)
Declare Function sqlite3Fts3InitTerm CDecl Alias "sqlite3Fts3InitTerm" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3Fts3ExprInitTestInterface CDecl Alias "sqlite3Fts3ExprInitTestInterface" (ByVal arg0 As Any Ptr, ByVal arg1 As Fts3Hash Ptr) As c2fb_c_int
#endif
Declare Function sqlite3Fts3InitHashTable CDecl Alias "sqlite3Fts3InitHashTable" (ByVal arg0 As Any Ptr, ByVal arg1 As Fts3Hash Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3Fts3InitTok CDecl Alias "sqlite3Fts3InitTok" (ByVal arg0 As Any Ptr, ByVal arg1 As Fts3Hash Ptr, ByVal arg2 As Any Ptr) As c2fb_c_int
#ifdef SQLITE_DEBUG
Declare Function sqlite3Fts3Corrupt CDecl Alias "sqlite3Fts3Corrupt" () As c2fb_c_int
#endif

/' end of fts3_candidates/sqlite3_fts3_core_api.bi '/
