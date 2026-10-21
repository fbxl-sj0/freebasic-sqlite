/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_fts3_write_api.bi

    Purpose:

        Bind the public SQLite API used by the staged FTS3 write candidate.

    Responsibilities:

        - Reuse signatures from SQLite's generated public API declarations.
        - Supply only declarations needed by this candidate file.

    This file intentionally does NOT contain:

        - FTS3 private declarations or layouts.
        - SQLite test support.
'/
#include once "crt/stdarg.bi"
#include once "sqlite3_fts3_write_types.bi"

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

Declare Function sqlite3_bind_blob CDecl Alias "sqlite3_bind_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_bind_int CDecl Alias "sqlite3_bind_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_bind_int64 CDecl Alias "sqlite3_bind_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3_bind_null CDecl Alias "sqlite3_bind_null" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_bind_parameter_count CDecl Alias "sqlite3_bind_parameter_count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_bind_text CDecl Alias "sqlite3_bind_text" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_bind_value CDecl Alias "sqlite3_bind_value" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr) As c2fb_c_int
Declare Function sqlite3_blob_close CDecl Alias "sqlite3_blob_close" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_blob_read CDecl Alias "sqlite3_blob_read" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_column_blob CDecl Alias "sqlite3_column_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function sqlite3_column_bytes CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_column_int CDecl Alias "sqlite3_column_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_column_int64 CDecl Alias "sqlite3_column_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function sqlite3_column_text CDecl Alias "sqlite3_column_text" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Const UByte Ptr
Declare Function sqlite3_column_type CDecl Alias "sqlite3_column_type" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_exec CDecl Alias "sqlite3_exec" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As Any Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function sqlite3_last_insert_rowid CDecl Alias "sqlite3_last_insert_rowid" (ByVal arg0 As Any Ptr) As c2fb_int64
Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_reset CDecl Alias "sqlite3_reset" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_strnicmp CDecl Alias "sqlite3_strnicmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_value_int CDecl Alias "sqlite3_value_int" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_value_int64 CDecl Alias "sqlite3_value_int64" (ByVal arg0 As Any Ptr) As c2fb_int64
Declare Function sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As Any Ptr) As Const UByte Ptr
Declare Function sqlite3_value_type CDecl Alias "sqlite3_value_type" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_vtab_on_conflict CDecl Alias "sqlite3_vtab_on_conflict" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3Fts3SegReaderCursor CDecl Alias "sqlite3Fts3SegReaderCursor" (ByVal arg0 As SqliteFts3Table Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As SqliteFts3MultiSegReader Ptr) As c2fb_c_int
Declare Function sqlite3Fts3GetVarintBounded CDecl Alias "sqlite3Fts3GetVarintBounded" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3SegReaderNew CDecl Alias "sqlite3Fts3SegReaderNew" (ByVal age As c2fb_c_int, ByVal lookupOnly As c2fb_c_int, ByVal firstLeaf As c2fb_int64, ByVal lastLeaf As c2fb_int64, ByVal lastBlock As c2fb_int64, ByVal rootData As Const ZString Ptr, ByVal rootBytes As c2fb_c_int, ByVal ppReader As SqliteFts3SegReader Ptr Ptr) As c2fb_c_int
#ifdef SQLITE_DEBUG
Declare Function sqlite3Fts3Corrupt CDecl Alias "sqlite3Fts3Corrupt" () As c2fb_c_int
#endif
#ifdef FTS3_LOG_MERGES
Declare Sub sqlite3_log CDecl Alias "sqlite3_log" (ByVal errorCode As c2fb_c_int, ByVal zFormat As Const ZString Ptr, ...)
#endif

/' end of fts3_candidates/sqlite3_fts3_write_api.bi '/
