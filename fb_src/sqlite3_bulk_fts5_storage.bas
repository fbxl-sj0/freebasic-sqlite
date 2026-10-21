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
******************************************************************************
**
'/ 

/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_bulk_fts5_storage.bas

    Purpose:

        Port FTS5's persistent table storage and row update operations.

    Responsibilities:

        - Prepare and manage FTS5 content, docsize, and config statements.
        - Insert, delete, rebuild, and inspect stored FTS5 rows.
        - Coordinate persistent storage operations with the FTS5 index.

    This file intentionally does NOT contain:

        - FTS5 virtual-table registration or query parsing.
        - The upstream TCL test adapter.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"

#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_storage_types.bi"

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
Type c2fb_callback_5 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Type c2fb_callback_73 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int

Declare Function fts5StorageGetStmt CDecl Alias "fts5StorageGetStmt" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5ExecPrintf CDecl Alias "fts5ExecPrintf" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As Const ZString Ptr, ...) As c2fb_c_int
Declare Function sqlite3Fts5DropAll CDecl Alias "sqlite3Fts5DropAll" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
Declare Sub fts5StorageRenameOne CDecl Alias "fts5StorageRenameOne" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr)
Declare Function sqlite3Fts5StorageRename CDecl Alias "sqlite3Fts5StorageRename" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3Fts5CreateTable CDecl Alias "sqlite3Fts5CreateTable" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageOpen CDecl Alias "sqlite3Fts5StorageOpen" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Index Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Storage Ptr Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageClose CDecl Alias "sqlite3Fts5StorageClose" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function fts5StorageInsertCallback CDecl Alias "fts5StorageInsertCallback" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5StorageFindDeleteRow CDecl Alias "sqlite3Fts5StorageFindDeleteRow" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function fts5StorageDeleteFromIndex CDecl Alias "fts5StorageDeleteFromIndex" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Sub sqlite3Fts5StorageReleaseDeleteRow CDecl Alias "sqlite3Fts5StorageReleaseDeleteRow" (ByVal arg0 As c2fb_Fts5Storage Ptr)
Declare Function fts5StorageLoadTotals CDecl Alias "fts5StorageLoadTotals" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5StorageSaveTotals CDecl Alias "fts5StorageSaveTotals" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function fts5StorageDecodeSizeArray CDecl Alias "fts5StorageDecodeSizeArray" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function fts5StorageContentlessDelete CDecl Alias "fts5StorageContentlessDelete" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function fts5StorageInsertDocsize CDecl Alias "fts5StorageInsertDocsize" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_Fts5Buffer Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageDelete CDecl Alias "sqlite3Fts5StorageDelete" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5StorageDeleteAll CDecl Alias "sqlite3Fts5StorageDeleteAll" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageRebuild CDecl Alias "sqlite3Fts5StorageRebuild" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageOptimize CDecl Alias "sqlite3Fts5StorageOptimize" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageMerge CDecl Alias "sqlite3Fts5StorageMerge" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5StorageReset CDecl Alias "sqlite3Fts5StorageReset" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function fts5StorageNewRowid CDecl Alias "fts5StorageNewRowid" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageContentInsert CDecl Alias "sqlite3Fts5StorageContentInsert" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageIndexInsert CDecl Alias "sqlite3Fts5StorageIndexInsert" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr Ptr, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function fts5StorageCount CDecl Alias "fts5StorageCount" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts5StorageIntegrityCallback CDecl Alias "fts5StorageIntegrityCallback" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5StorageIntegrity CDecl Alias "sqlite3Fts5StorageIntegrity" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5StorageStmt CDecl Alias "sqlite3Fts5StorageStmt" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5StorageStmtRelease CDecl Alias "sqlite3Fts5StorageStmtRelease" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_stmt Ptr)
Declare Function sqlite3Fts5StorageDocsize CDecl Alias "sqlite3Fts5StorageDocsize" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageSize CDecl Alias "sqlite3Fts5StorageSize" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageRowCount CDecl Alias "sqlite3Fts5StorageRowCount" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageSync CDecl Alias "sqlite3Fts5StorageSync" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageRollback CDecl Alias "sqlite3Fts5StorageRollback" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function sqlite3Fts5StorageConfigValue CDecl Alias "sqlite3Fts5StorageConfigValue" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_external_sqlite3_exec CDecl Alias "sqlite3_exec" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_callback_5, ByVal arg3 As Any Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_last_insert_rowid CDecl Alias "sqlite3_last_insert_rowid" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_int64
Declare Sub c2fb_external_sqlite3_set_last_insert_rowid CDecl Alias "sqlite3_set_last_insert_rowid" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As c2fb_int64)
Declare Function c2fb_external_sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_errmsg CDecl Alias "sqlite3_errmsg" (ByVal arg0 As c2fb_sqlite3 Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_prepare_v2 CDecl Alias "sqlite3_prepare_v2" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_prepare_v3 CDecl Alias "sqlite3_prepare_v3" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_uint, ByVal arg4 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_blob CDecl Alias "sqlite3_bind_blob" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_int CDecl Alias "sqlite3_bind_int" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_int64 CDecl Alias "sqlite3_bind_int64" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_null CDecl Alias "sqlite3_bind_null" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_text CDecl Alias "sqlite3_bind_text" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_value CDecl Alias "sqlite3_bind_value" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_clear_bindings CDecl Alias "sqlite3_clear_bindings" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_blob CDecl Alias "sqlite3_column_blob" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function c2fb_external_sqlite3_column_int CDecl Alias "sqlite3_column_int" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int64 CDecl Alias "sqlite3_column_int64" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function c2fb_external_sqlite3_column_text CDecl Alias "sqlite3_column_text" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_column_value CDecl Alias "sqlite3_column_value" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_sqlite3_value Ptr
Declare Function c2fb_external_sqlite3_column_bytes CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_reset CDecl Alias "sqlite3_reset" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_int64 CDecl Alias "sqlite3_value_int64" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_type CDecl Alias "sqlite3_value_type" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_nochange CDecl Alias "sqlite3_value_nochange" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_dup CDecl Alias "sqlite3_value_dup" (ByVal arg0 As Const c2fb_sqlite3_value Ptr) As c2fb_sqlite3_value Ptr
Declare Sub c2fb_external_sqlite3_value_free CDecl Alias "sqlite3_value_free" (ByVal arg0 As c2fb_sqlite3_value Ptr)
Declare Function c2fb_external_sqlite3_str_new CDecl Alias "sqlite3_str_new" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_sqlite3_str Ptr
Declare Function c2fb_external_sqlite3_str_finish CDecl Alias "sqlite3_str_finish" (ByVal arg0 As c2fb_sqlite3_str Ptr) As ZString Ptr
Declare Sub c2fb_external_sqlite3_str_appendf CDecl Alias "sqlite3_str_appendf" (ByVal arg0 As c2fb_sqlite3_str Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Function c2fb_external_sqlite3Fts5Tokenize CDecl Alias "sqlite3Fts5Tokenize" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_73) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5BufferAppendVarint CDecl Alias "sqlite3Fts5BufferAppendVarint" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_int64)
Declare Sub c2fb_external_sqlite3Fts5BufferZero CDecl Alias "sqlite3Fts5BufferZero" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
Declare Function c2fb_external_sqlite3Fts5Mprintf CDecl Alias "sqlite3Fts5Mprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3Fts5TermsetNew CDecl Alias "sqlite3Fts5TermsetNew" (ByVal arg0 As c2fb_Fts5Termset Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5TermsetAdd CDecl Alias "sqlite3Fts5TermsetAdd" (ByVal arg0 As c2fb_Fts5Termset Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5TermsetFree CDecl Alias "sqlite3Fts5TermsetFree" (ByVal arg0 As c2fb_Fts5Termset Ptr)
Declare Function c2fb_external_sqlite3Fts5IndexEntryCksum CDecl Alias "sqlite3Fts5IndexEntryCksum" (ByVal arg0 As c2fb_int64, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_uint64
Declare Function c2fb_external_sqlite3Fts5IndexCharlenToBytelen CDecl Alias "sqlite3Fts5IndexCharlenToBytelen" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexWrite CDecl Alias "sqlite3Fts5IndexWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexBeginWrite CDecl Alias "sqlite3Fts5IndexBeginWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexSync CDecl Alias "sqlite3Fts5IndexSync" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexRollback CDecl Alias "sqlite3Fts5IndexRollback" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexGetAverages CDecl Alias "sqlite3Fts5IndexGetAverages" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexSetAverages CDecl Alias "sqlite3Fts5IndexSetAverages" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexIntegrityCheck CDecl Alias "sqlite3Fts5IndexIntegrityCheck" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexSetCookie CDecl Alias "sqlite3Fts5IndexSetCookie" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexReinit CDecl Alias "sqlite3Fts5IndexReinit" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexOptimize CDecl Alias "sqlite3Fts5IndexOptimize" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexMerge CDecl Alias "sqlite3Fts5IndexMerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexReset CDecl Alias "sqlite3Fts5IndexReset" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexGetOrigin CDecl Alias "sqlite3Fts5IndexGetOrigin" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexContentlessDelete CDecl Alias "sqlite3Fts5IndexContentlessDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5GetVarint32 CDecl Alias "sqlite3Fts5GetVarint32" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_uint Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5ClearLocale CDecl Alias "sqlite3Fts5ClearLocale" (ByVal arg0 As c2fb_Fts5Config Ptr)
Declare Sub c2fb_external_sqlite3Fts5SetLocale CDecl Alias "sqlite3Fts5SetLocale" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Function c2fb_external_sqlite3Fts5IsLocaleValue CDecl Alias "sqlite3Fts5IsLocaleValue" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5DecodeLocaleValue CDecl Alias "sqlite3Fts5DecodeLocaleValue" (ByVal arg0 As c2fb_sqlite3_value Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
#ifdef SQLITE_DEBUG
Private Sub fts5StorageAssert(ByVal bCondition As c2fb_c_int, ByVal zExpression As Const ZString Ptr)
    If bCondition = 0 Then sqlite3DebugAssert(zExpression)
End Sub
#endif
Private Function fts5StorageGetStmt CDecl Alias "fts5StorageGetStmt" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 82
    Dim local0 As c2fb_c_int
    Dim local1(0 To 11) As Const ZString Ptr
    Dim local2 As c2fb_Fts5Config Ptr
    Dim local3 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As ZString Ptr Ptr
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_sqlite3_stmt Ptr Ptr
    Dim c2fb_temp_24 As c2fb_sqlite3_stmt Ptr

#ifdef SQLITE_DEBUG
    fts5StorageAssert(arg0->pConfig->bColumnsize <> 0 OrElse _
        (arg1 <> 7 AndAlso arg1 <> 8 AndAlso arg1 <> 9), _
        StrPtr(!"p->pConfig->bColumnsize || eStmt is not a docsize statement"))
    ' The statement templates and Fts5Storage.aStmt both have twelve entries.
    fts5StorageAssert(arg1 >= 0 AndAlso arg1 < 12, _
        StrPtr(!"eStmt>=0 && eStmt<ArraySize(p->aStmt)"))
    fts5StorageAssert(UBound(local1) = UBound(arg0->aStmt), _
        StrPtr(!"ArraySize(azStmt)==ArraySize(p->aStmt)"))
#endif
    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->aStmt(arg1) = Cast(c2fb_c_int, &O0ULL))))) Then
        Erase local1
        local1(0) = StrPtr(!"SELECT %s FROM %s T WHERE T.%Q >= ? AND T.%Q <= ? ORDER BY T.%Q ASC")
        local1(1) = StrPtr(!"SELECT %s FROM %s T WHERE T.%Q <= ? AND T.%Q >= ? ORDER BY T.%Q DESC")
        local1(2) = StrPtr(!"SELECT %s FROM %s T WHERE T.%Q=?")
        local1(3) = StrPtr(!"SELECT %s FROM %s T WHERE T.%Q=?")
        local1(4) = StrPtr(!"INSERT INTO %Q.'%q_content' VALUES(%s)")
        local1(5) = StrPtr(!"REPLACE INTO %Q.'%q_content' VALUES(%s)")
        local1(6) = StrPtr(!"DELETE FROM %Q.'%q_content' WHERE id=?")
        local1(7) = StrPtr(!"REPLACE INTO %Q.'%q_docsize' VALUES(?,?%s)")
        local1(8) = StrPtr(!"DELETE FROM %Q.'%q_docsize' WHERE id=?")
        local1(9) = StrPtr(!"SELECT sz%s FROM %Q.'%q_docsize' WHERE id=?")
        local1(10) = StrPtr(!"REPLACE INTO %Q.'%q_config' VALUES(?,?)")
        local1(11) = StrPtr(!"SELECT %s FROM %s AS T")
        local2 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        local3 = Cast(c2fb_c_int, &O0ULL)
        ' C unused-parameter annotation
        Select Case arg1
            Case Cast(c2fb_c_int, 11ULL)
                c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(local1(arg1), local2->zContentExprlist, local2->zContent))
                local3 = c2fb_temp_0
            Case Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL)
                c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(local1(arg1), local2->zContentExprlist, local2->zContent, local2->zContentRowid, local2->zContentRowid, local2->zContentRowid))
                local3 = c2fb_temp_1
            Case Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, 3ULL)
                c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(local1(arg1), local2->zContentExprlist, local2->zContent, local2->zContentRowid))
                local3 = c2fb_temp_2
            Case Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 5ULL)
#ifdef SQLITE_DEBUG
                fts5StorageAssert(local2->eContent = 0 OrElse local2->eContent = 3, _
                    StrPtr(!"pC->eContent==FTS5_CONTENT_NORMAL || pC->eContent==FTS5_CONTENT_UNINDEXED"))
#endif
                local4 = Cast(c2fb_c_int, &O0ULL)
                ' C automatic storage declaration
                ' C unused-parameter annotation
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local5 = c2fb_temp_3
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < (Cast(c2fb_c_int, (local2->nCol + Cast(c2fb_c_int, 1ULL)))))))) <> 0)))))
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local5 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (local2->abUnindexed[Cast(c2fb_c_int, (local5 - Cast(c2fb_c_int, 1ULL)))] <> 0))))) Then
                        c2fb_temp_5 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local0)), StrPtr(!"%z%s?%d"), local4, IIf(local4, StrPtr(!","), StrPtr(!"")), Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL)))))
                        local4 = c2fb_temp_5
                    End If
                c2fb_flow_2:
                    c2fb_temp_4 = local5
                    local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
                Wend
                c2fb_flow_1:
                If (-Cast(c2fb_c_int, (((local2->bLocale <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local5 = c2fb_temp_6
                    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < local2->nCol)))) <> 0)))))
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->abUnindexed[local5]) = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_8 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local0)), StrPtr(!"%z,?%d"), local4, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local2->nCol + local5)) + Cast(c2fb_c_int, 2ULL)))))
                            local4 = c2fb_temp_8
                        End If
                    c2fb_flow_4:
                        c2fb_temp_7 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
                    Wend
                    c2fb_flow_3:
                End If
                c2fb_temp_9 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local0)), local1(arg1), local2->zDb, local2->zName, local4))
                local3 = c2fb_temp_9
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
                Goto c2fb_flow_0
            Case Cast(c2fb_c_int, 7ULL)
                c2fb_temp_10 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(local1(arg1), local2->zDb, local2->zName, (IIf(local2->bContentlessDelete, StrPtr(!",?"), StrPtr(!"")))))
                local3 = c2fb_temp_10
            Case Cast(c2fb_c_int, 9ULL)
                c2fb_temp_11 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(local1(arg1), (IIf(local2->bContentlessDelete, StrPtr(!",origin"), StrPtr(!""))), local2->zDb, local2->zName))
                local3 = c2fb_temp_11
            Case Else
                c2fb_temp_12 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(local1(arg1), local2->zDb, local2->zName))
                local3 = c2fb_temp_12
        End Select
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_13
        Else
            local6 = Cast(c2fb_c_int, &H01ULL)
            If (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 3ULL))))) Then
                c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 Or Cast(c2fb_c_int, &H04ULL))))
                local6 = c2fb_temp_14
            End If
            c2fb_temp_15 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bLock))
            c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
            (*c2fb_temp_15) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 + 1)))
            c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v3(CPtr(c2fb_sqlite3 Ptr, local2->db), CPtr(Const ZString Ptr, local3), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), local6, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->aStmt(arg1))), Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_17
            c2fb_temp_18 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bLock))
            c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
            (*c2fb_temp_18) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_19 - 1)))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg3 <> 0))))) Then
                c2fb_temp_20 = CPtr(ZString Ptr Ptr, @((*arg3)))
                c2fb_temp_21 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(CPtr(c2fb_sqlite3 Ptr, local2->db)))))
                (*c2fb_temp_20) = c2fb_temp_21
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, 11ULL))))) <> 0))))) Then
                c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 11ULL))
                local0 = c2fb_temp_22
            End If
        End If
    End If
    c2fb_temp_23 = CPtr(c2fb_sqlite3_stmt Ptr Ptr, @((*arg2)))
    c2fb_temp_24 = arg0->aStmt(arg1)
    (*c2fb_temp_23) = c2fb_temp_24
    c2fb_external_sqlite3_reset((*arg2))
    Return local0
End Function
Private Function fts5ExecPrintf CDecl Alias "fts5ExecPrintf" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As Const ZString Ptr, ...) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 222
    Dim local0 As c2fb_c_int
    Dim local1 As Cva_List
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    Cva_Start(local1, arg2)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg2, local1))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_1
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec(arg0, CPtr(Const ZString Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1))
        local0 = c2fb_temp_2
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    End If
    Cva_End(local1)
    Return local0
End Function
Function sqlite3Fts5DropAll CDecl Alias "sqlite3Fts5DropAll" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 250
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = fts5ExecPrintf(CPtr(c2fb_sqlite3 Ptr, arg0->db), Cast(c2fb_c_int, &O0ULL), StrPtr(!"DROP TABLE IF EXISTS %Q.'%q_data';DROP TABLE IF EXISTS %Q.'%q_idx';DROP TABLE IF EXISTS %Q.'%q_config';"), arg0->zDb, arg0->zName, arg0->zDb, arg0->zName, arg0->zDb, arg0->zName)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg0->bColumnsize <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, fts5ExecPrintf(CPtr(c2fb_sqlite3 Ptr, arg0->db), Cast(c2fb_c_int, &O0ULL), StrPtr(!"DROP TABLE IF EXISTS %Q.'%q_docsize';"), arg0->zDb, arg0->zName))
        local0 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, fts5ExecPrintf(CPtr(c2fb_sqlite3 Ptr, arg0->db), Cast(c2fb_c_int, &O0ULL), StrPtr(!"DROP TABLE IF EXISTS %Q.'%q_content';"), arg0->zDb, arg0->zName))
        local0 = c2fb_temp_1
    End If
    Return local0
End Function
Private Sub fts5StorageRenameOne CDecl Alias "fts5StorageRenameOne" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 274
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((*arg1) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_1 = Cast(c2fb_c_int, fts5ExecPrintf(CPtr(c2fb_sqlite3 Ptr, arg0->db), Cast(c2fb_c_int, &O0ULL), StrPtr(!"ALTER TABLE %Q.'%q_%s' RENAME TO '%q_%s';"), arg0->zDb, arg0->zName, arg2, arg3, arg2))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
End Sub
Function sqlite3Fts5StorageRename CDecl Alias "sqlite3Fts5StorageRename" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 288
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local1 = sqlite3Fts5StorageSync(arg0)
    fts5StorageRenameOne(local0, CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"data"), arg1)
    fts5StorageRenameOne(local0, CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"idx"), arg1)
    fts5StorageRenameOne(local0, CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"config"), arg1)
    If local0->bColumnsize Then
        fts5StorageRenameOne(local0, CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"docsize"), arg1)
    End If
    If (-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, &O0ULL))))) Then
        fts5StorageRenameOne(local0, CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"content"), arg1)
    End If
    Return local1
End Function
Function sqlite3Fts5CreateTable CDecl Alias "sqlite3Fts5CreateTable" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 308
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, fts5ExecPrintf(CPtr(c2fb_sqlite3 Ptr, arg0->db), CPtr(ZString Ptr Ptr, @(local1)), StrPtr(!"CREATE TABLE %Q.'%q_%q'(%s)%s"), arg0->zDb, arg0->zName, arg1, arg2, IIf(arg3, StrPtr(!" WITHOUT ROWID"), StrPtr(!""))))
    local0 = c2fb_temp_0
    If local1 Then
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @((*arg4)))
        c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"fts5: error creating shadow table %q_%s: %s"), arg0->zName, arg1, local1))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Return local0
End Function
Function sqlite3Fts5StorageOpen CDecl Alias "sqlite3Fts5StorageOpen" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Index Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Storage Ptr Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 343
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Storage Ptr
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_Fts5Storage Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Storage Ptr Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Storage Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_i64 Ptr Ptr
    Dim c2fb_temp_6 As c2fb_int64 Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Config_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Index_ Ptr Ptr
    Dim c2fb_temp_10 As c2fb_Fts5Index Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As ZString Ptr
    Dim local5 As c2fb_sqlite3_str Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As ZString Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim c2fb_temp_18 As Const ZString Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_Fts5Storage Ptr Ptr
    Dim c2fb_temp_23 As c2fb_Fts5Storage Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Storage))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0->nCol) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))))))))
    local2 = c2fb_temp_0
    c2fb_temp_2 = CPtr(c2fb_Fts5Storage Ptr Ptr, @((*arg3)))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Storage Ptr, CPtr(c2fb_Fts5Storage Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local2))))
    local1 = c2fb_temp_1
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Storage Ptr, c2fb_temp_1)
    (*c2fb_temp_2) = c2fb_temp_3
    If (-Cast(c2fb_c_int, (local1 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, local2)))
    c2fb_temp_5 = CPtr(c2fb_i64 Ptr Ptr, @(local1->aTotalSize))
    c2fb_temp_6 = CPtr(c2fb_int64 Ptr, CPtr(c2fb_Fts5Storage Ptr, @(CPtr(c2fb_Fts5Storage Ptr, local1)[Cast(c2fb_c_int, 1ULL)])))
    (*c2fb_temp_5) = CPtr(c2fb_i64 Ptr, c2fb_temp_6)
    c2fb_temp_6 = CPtr(c2fb_int64 Ptr, (*c2fb_temp_5))
    c2fb_temp_7 = CPtr(c2fb_Fts5Config_ Ptr Ptr, @(local1->pConfig))
    c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, arg0)
    (*c2fb_temp_7) = CPtr(c2fb_Fts5Config_ Ptr, c2fb_temp_8)
    c2fb_temp_8 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_7))
    c2fb_temp_9 = CPtr(c2fb_Fts5Index_ Ptr Ptr, @(local1->pIndex))
    c2fb_temp_10 = arg1
    (*c2fb_temp_9) = CPtr(c2fb_Fts5Index_ Ptr, c2fb_temp_10)
    c2fb_temp_10 = CPtr(c2fb_Fts5Index Ptr, (*c2fb_temp_9))
    If arg2 Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
            local3 = Cast(c2fb_c_int, &O0ULL)
            local4 = Cast(c2fb_c_int, &O0ULL)
            local5 = CPtr(c2fb_sqlite3_str Ptr, c2fb_external_sqlite3_str_new(CPtr(c2fb_sqlite3 Ptr, arg0->db)))
            c2fb_external_sqlite3_str_appendf(local5, StrPtr(!"id INTEGER PRIMARY KEY"))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_11
            While (-Cast(c2fb_c_int, ((local3 < arg0->nCol))))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (arg0->abUnindexed[local3] <> 0))))) Then
                    c2fb_external_sqlite3_str_appendf(local5, StrPtr(!", c%d"), local3)
                End If
            c2fb_flow_1:
                c2fb_temp_12 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
            Wend
            c2fb_flow_0:
            If arg0->bLocale Then
                c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_13
                While (-Cast(c2fb_c_int, ((local3 < arg0->nCol))))
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->abUnindexed[local3]) = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_external_sqlite3_str_appendf(local5, StrPtr(!", l%d"), local3)
                    End If
                c2fb_flow_3:
                    c2fb_temp_14 = local3
                    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
                Wend
                c2fb_flow_2:
            End If
            c2fb_temp_15 = CPtr(ZString Ptr, c2fb_external_sqlite3_str_finish(local5))
            local4 = c2fb_temp_15
            If local4 Then
                c2fb_temp_16 = Cast(c2fb_c_int, sqlite3Fts5CreateTable(arg0, StrPtr(!"content"), CPtr(Const ZString Ptr, local4), Cast(c2fb_c_int, &O0ULL), arg4))
                local0 = c2fb_temp_16
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
            Else
                c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_17
            End If
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg0->bColumnsize <> 0))))) Then
            local6 = StrPtr(!"id INTEGER PRIMARY KEY, sz BLOB")
            If arg0->bContentlessDelete Then
                c2fb_temp_18 = StrPtr(!"id INTEGER PRIMARY KEY, sz BLOB, origin INTEGER")
                local6 = c2fb_temp_18
            End If
            c2fb_temp_19 = Cast(c2fb_c_int, sqlite3Fts5CreateTable(arg0, StrPtr(!"docsize"), local6, Cast(c2fb_c_int, &O0ULL), arg4))
            local0 = c2fb_temp_19
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_20 = Cast(c2fb_c_int, sqlite3Fts5CreateTable(arg0, StrPtr(!"config"), StrPtr(!"k PRIMARY KEY, v"), Cast(c2fb_c_int, 1ULL), arg4))
            local0 = c2fb_temp_20
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_21 = Cast(c2fb_c_int, sqlite3Fts5StorageConfigValue(local1, StrPtr(!"version"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 4ULL)))
            local0 = c2fb_temp_21
        End If
    End If
    If local0 Then
        sqlite3Fts5StorageClose(local1)
        c2fb_temp_22 = CPtr(c2fb_Fts5Storage Ptr Ptr, @((*arg3)))
        c2fb_temp_23 = CPtr(_c2fb_record_c2fb_Fts5Storage Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_22) = c2fb_temp_23
    End If
    Return local0
End Function
Function sqlite3Fts5StorageClose CDecl Alias "sqlite3Fts5StorageClose" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 422
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local1 < (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (12ULL * SizeOf(c2fb_sqlite3_stmt Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_sqlite3_stmt Ptr))))))))))))
            c2fb_external_sqlite3_finalize(arg0->aStmt(local1))
        c2fb_flow_1:
            c2fb_temp_1 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
    Return local0
End Function
Private Function fts5StorageInsertCallback CDecl Alias "fts5StorageInsertCallback" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 447
    Dim local0 As c2fb_Fts5InsertCtx Ptr
    Dim local1 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5InsertCtx Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Index Ptr, CPtr(c2fb_Fts5Storage Ptr, local0->pStorage)->pIndex)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, 32768ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 32768ULL))
        arg3 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0001ULL)))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->szCol = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_1 = CPtr(Long Ptr, @(local0->szCol))
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        (*c2fb_temp_1) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    End If
    Return c2fb_external_sqlite3Fts5IndexWrite(local1, local0->iCol, Cast(c2fb_c_int, (local0->szCol - Cast(c2fb_c_int, 1ULL))), arg2, arg3)
End Function
Function sqlite3Fts5StorageFindDeleteRow CDecl Alias "sqlite3Fts5StorageFindDeleteRow" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 475
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_3 As c2fb_sqlite3_stmt Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    fts5StorageAssert(arg0->pSavedRow = 0, StrPtr(!"p->pSavedRow==0"))
#endif
    c2fb_temp_0 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_bind_int64(local1, Cast(c2fb_c_int, 1ULL), arg1)
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local1) <> Cast(c2fb_c_int, 100ULL))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local1))
            local0 = c2fb_temp_1
        Else
            c2fb_temp_2 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pSavedRow))
            c2fb_temp_3 = local1
            (*c2fb_temp_2) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_3)
            c2fb_temp_3 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_2))
        End If
    End If
    Return local0
End Function
Private Function fts5StorageDeleteFromIndex CDecl Alias "fts5StorageDeleteFromIndex" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 503
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_Fts5InsertCtx
    Dim c2fb_temp_0 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_1 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_Fts5Storage_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Storage Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local6 As c2fb_sqlite3_value Ptr
    Dim local7 As c2fb_sqlite3_value Ptr
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As Const ZString Ptr
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_11 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_14 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Const ZString Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Const ZString Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Long Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_i64 Ptr
    Dim c2fb_temp_24 As c2fb_int64
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_i64 Ptr
    Dim c2fb_temp_28 As c2fb_int64
    Dim c2fb_temp_29 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_30 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    fts5StorageAssert(arg3 = 0 OrElse arg2 = 0, _
        StrPtr(!"bSaveRow==0 || apVal==0"))
    fts5StorageAssert(arg3 = 0 OrElse arg3 = 1, _
        StrPtr(!"bSaveRow==0 || bSaveRow==1"))
    fts5StorageAssert(3 = 2 + 1, _
        StrPtr(!"FTS5_STMT_LOOKUP2==FTS5_STMT_LOOKUP+1"))
#endif
    If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, (((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow) <> 0) AndAlso (arg3 <> 0))))) Then
            c2fb_temp_0 = CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow)
            local1 = c2fb_temp_0
            c2fb_temp_1 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pSavedRow))
            c2fb_temp_2 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_1) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_2)
            c2fb_temp_2 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_1))
        Else
            c2fb_temp_3 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + arg3)), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))
            local2 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return local2
            End If
            c2fb_external_sqlite3_bind_int64(local1, Cast(c2fb_c_int, 1ULL), arg1)
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local1) <> Cast(c2fb_c_int, 100ULL))))) Then
                Return c2fb_external_sqlite3_reset(local1)
            End If
        End If
    End If
    c2fb_temp_4 = CPtr(c2fb_Fts5Storage_ Ptr Ptr, @(local5.pStorage))
    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5Storage Ptr, arg0)
    (*c2fb_temp_4) = CPtr(c2fb_Fts5Storage_ Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(c2fb_Fts5Storage Ptr, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(Long Ptr, @(local5.iCol))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    local4 = c2fb_temp_8
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 <= local0->nCol)))) <> 0)))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->abUnindexed[Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, &O0ULL))))) Then
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = Cast(c2fb_c_int, &O0ULL)
            local9 = Cast(c2fb_c_int, &O0ULL)
            local10 = Cast(c2fb_c_int, &O0ULL)
            local11 = Cast(c2fb_c_int, &O0ULL)
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            If local1 Then
                c2fb_temp_10 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(local1, local4))
                local6 = c2fb_temp_10
            Else
                c2fb_temp_11 = arg2[Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 1ULL)))]
                local6 = c2fb_temp_11
            End If
#ifdef SQLITE_DEBUG
            fts5StorageAssert(local1 = 0 OrElse arg2 = 0, _
                StrPtr(!"pSeek==0 || apVal==0"))
            fts5StorageAssert(local1 <> 0 OrElse arg2 <> 0, _
                StrPtr(!"pSeek!=0 || apVal!=0"))
#endif
            If (-Cast(c2fb_c_int, (((local0->bLocale <> 0) AndAlso (c2fb_external_sqlite3Fts5IsLocaleValue(local0, local6) <> 0))))) Then
                c2fb_temp_12 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5DecodeLocaleValue(local6, CPtr(Const ZString Ptr Ptr, @(local8)), CPtr(c2fb_c_int Ptr, @(local9)), CPtr(Const ZString Ptr Ptr, @(local10)), CPtr(c2fb_c_int Ptr, @(local11))))
                local2 = c2fb_temp_12
            Else
                If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(local6) <> Cast(c2fb_c_int, 3ULL))))) Then
                    c2fb_temp_13 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_value_dup(CPtr(Const c2fb_sqlite3_value Ptr, local6)))
                    local6 = c2fb_temp_13
                    c2fb_temp_14 = c2fb_temp_13
                    local7 = c2fb_temp_14
                    If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                        local2 = c2fb_temp_15
                    End If
                End If
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_16 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(local6)))
                    local8 = c2fb_temp_16
                    c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes(local6))
                    local9 = c2fb_temp_17
                    If (-Cast(c2fb_c_int, (((local0->bLocale <> 0) AndAlso (local1 <> 0))))) Then
                        c2fb_temp_18 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local1, Cast(c2fb_c_int, (local4 + local0->nCol)))))
                        local10 = c2fb_temp_18
                        c2fb_temp_19 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_bytes(local1, Cast(c2fb_c_int, (local4 + local0->nCol))))
                        local11 = c2fb_temp_19
                    End If
                End If
            End If
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_external_sqlite3Fts5SetLocale(local0, local10, local11)
                c2fb_temp_20 = CPtr(Long Ptr, @(local5.szCol))
                c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_20) = Cast(Long, c2fb_temp_21)
                c2fb_temp_21 = Cast(c2fb_c_int, (*c2fb_temp_20))
                c2fb_temp_22 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5Tokenize(local0, Cast(c2fb_c_int, &H0004ULL), local8, local9, CPtr(Any Ptr, CPtr(c2fb_Fts5InsertCtx Ptr, @(local5))), ProcPtr(fts5StorageInsertCallback)))
                local2 = c2fb_temp_22
                c2fb_temp_23 = CPtr(c2fb_i64 Ptr, @(arg0->aTotalSize[Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 1ULL)))]))
                c2fb_temp_24 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_23)) - Cast(c2fb_int64, local5.szCol))))
                (*c2fb_temp_23) = Cast(c2fb_i64, c2fb_temp_24)
                c2fb_temp_24 = Cast(c2fb_int64, (*c2fb_temp_23))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->aTotalSize[Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 1ULL)))] < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
                    c2fb_temp_25 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local2 = c2fb_temp_25
                End If
                c2fb_external_sqlite3Fts5ClearLocale(local0)
            End If
            c2fb_external_sqlite3_value_free(local7)
        End If
    c2fb_flow_1:
        c2fb_temp_9 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->nTotalRow < Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) <> 0))))) Then
        c2fb_temp_26 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
        local2 = c2fb_temp_26
    Else
        c2fb_temp_27 = CPtr(c2fb_i64 Ptr, @(arg0->nTotalRow))
        c2fb_temp_28 = Cast(c2fb_int64, (*c2fb_temp_27))
        (*c2fb_temp_27) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_28 - 1)))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg3 <> 0))))) Then
        ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
        fts5StorageAssert(arg0->pSavedRow = 0, StrPtr(!"p->pSavedRow==0"))
#endif
        c2fb_temp_29 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pSavedRow))
        c2fb_temp_30 = local1
        (*c2fb_temp_29) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_30)
        c2fb_temp_30 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_29))
    Else
        c2fb_temp_31 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local1))
        local3 = c2fb_temp_31
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_32 = Cast(c2fb_c_int, local3)
            local2 = c2fb_temp_32
        End If
    End If
    Return local2
End Function
Sub sqlite3Fts5StorageReleaseDeleteRow CDecl Alias "sqlite3Fts5StorageReleaseDeleteRow" (ByVal arg0 As c2fb_Fts5Storage Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 611
    Dim c2fb_temp_0 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_sqlite3_stmt Ptr

    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    fts5StorageAssert(arg0->pSavedRow = 0 OrElse _
        arg0->pSavedRow = arg0->aStmt(3), _
        StrPtr(!"pStorage->pSavedRow==0 || pStorage->pSavedRow==pStorage->aStmt[FTS5_STMT_LOOKUP2]"))
#endif
    c2fb_external_sqlite3_reset(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow))
    c2fb_temp_0 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pSavedRow))
    c2fb_temp_1 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_0))
End Sub
Private Function fts5StorageLoadTotals CDecl Alias "fts5StorageLoadTotals" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 629
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->bTotalsValid = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexGetAverages(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), CPtr(c2fb_int64 Ptr, @(arg0->nTotalRow)), arg0->aTotalSize))
        local0 = c2fb_temp_0
        c2fb_temp_1 = CPtr(Long Ptr, @(arg0->bTotalsValid))
        c2fb_temp_2 = Cast(c2fb_c_int, arg1)
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    End If
    Return local0
End Function
Private Function fts5StorageSaveTotals CDecl Alias "fts5StorageSaveTotals" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 645
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Buffer
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(local3)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), arg0->nTotalRow)
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local1 < local0))))
        c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(local3)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), arg0->aTotalSize[local1])
    c2fb_flow_1:
        c2fb_temp_2 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexSetAverages(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), CPtr(Const UByte Ptr, local2.p), local2.n))
        local3 = c2fb_temp_3
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local2.p))
    Return local3
End Function
Private Function fts5StorageDecodeSizeArray CDecl Alias "fts5StorageDecodeSizeArray" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 664
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        If (-Cast(c2fb_c_int, ((local1 >= arg3)))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((arg0[local0]))))))))
        local1 = c2fb_temp_2
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return ((-Cast(c2fb_c_int, ((local1 <> arg3)))))
End Function
Private Function fts5StorageContentlessDelete CDecl Alias "fts5StorageContentlessDelete" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 683
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local5 As Const UByte Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_i64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_i64 Ptr
    Dim c2fb_temp_13 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    fts5StorageAssert(arg0->pConfig->bContentlessDelete <> 0, _
        StrPtr(!"p->pConfig->bContentlessDelete"))
    fts5StorageAssert(arg0->pConfig->eContent = 1 OrElse _
        arg0->pConfig->eContent = 3, _
        StrPtr(!"p->pConfig->eContent==FTS5_CONTENT_NONE || p->pConfig->eContent==FTS5_CONTENT_UNINDEXED"))
#endif
    c2fb_temp_0 = Cast(c2fb_c_int, fts5StorageLoadTotals(arg0, Cast(c2fb_c_int, 1ULL)))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local2
    End If
    c2fb_temp_1 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 9ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))
    local2 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_external_sqlite3_bind_int64(local1, Cast(c2fb_c_int, 1ULL), arg1)
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local1))))) Then
            local4 = CPtr(c2fb_c_int Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))))))
            If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local2 = c2fb_temp_2
            Else
                local5 = CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob(local1, Cast(c2fb_c_int, &O0ULL)))
                local6 = c2fb_external_sqlite3_column_bytes(local1, Cast(c2fb_c_int, &O0ULL))
                ' C automatic storage declaration
                If fts5StorageDecodeSizeArray(local4, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol, local5, local6) Then
                    c2fb_temp_3 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local2 = c2fb_temp_3
                Else
                    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local7 = c2fb_temp_4
                    While (-Cast(c2fb_c_int, ((local7 < CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol))))
                        c2fb_temp_6 = CPtr(c2fb_i64 Ptr, @(arg0->aTotalSize[local7]))
                        c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_6)) - Cast(c2fb_int64, local4[local7]))))
                        (*c2fb_temp_6) = Cast(c2fb_i64, c2fb_temp_7)
                        c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
                    c2fb_flow_1:
                        c2fb_temp_5 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
                    Wend
                    c2fb_flow_0:
                End If
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
            End If
            c2fb_temp_8 = Cast(c2fb_int64, c2fb_external_sqlite3_column_int(local1, Cast(c2fb_c_int, 1ULL)))
            local0 = c2fb_temp_8
        End If
        c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local1))
        local3 = c2fb_temp_9
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_10 = Cast(c2fb_c_int, local3)
            local2 = c2fb_temp_10
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexContentlessDelete(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), local0, arg1))
        local2 = c2fb_temp_11
        c2fb_temp_12 = CPtr(c2fb_i64 Ptr, @(arg0->nTotalRow))
        c2fb_temp_13 = Cast(c2fb_int64, (*c2fb_temp_12))
        (*c2fb_temp_12) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_13 - 1)))
    End If
    Return local2
End Function
Private Function fts5StorageInsertDocsize CDecl Alias "fts5StorageInsertDocsize" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_Fts5Buffer Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 741
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bColumnsize Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 7ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_bind_int64(local1, Cast(c2fb_c_int, 1ULL), arg1)
            If CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bContentlessDelete Then
                local2 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexGetOrigin(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), CPtr(c2fb_int64 Ptr, @(local2))))
                local0 = c2fb_temp_1
                c2fb_external_sqlite3_bind_int64(local1, Cast(c2fb_c_int, 3ULL), local2)
            End If
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_bind_blob(local1, Cast(c2fb_c_int, 2ULL), CPtr(Const Any Ptr, arg2->p), arg2->n, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
            c2fb_external_sqlite3_step(local1)
            c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local1))
            local0 = c2fb_temp_2
            c2fb_external_sqlite3_bind_null(local1, Cast(c2fb_c_int, 2ULL))
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5StorageDelete CDecl Alias "sqlite3Fts5StorageDelete" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 771
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
#ifdef SQLITE_DEBUG
    fts5StorageAssert(local0->eContent <> 0 OrElse arg2 = 0, _
        StrPtr(!"pConfig->eContent!=FTS5_CONTENT_NORMAL || apVal==0"))
#endif
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, fts5StorageLoadTotals(arg0, Cast(c2fb_c_int, 1ULL)))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexBeginWrite(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), Cast(c2fb_c_int, 1ULL), arg1))
        local1 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        If CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bContentlessDelete Then
            c2fb_temp_2 = Cast(c2fb_c_int, fts5StorageContentlessDelete(arg0, arg1))
            local1 = c2fb_temp_2
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eContent = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
                c2fb_temp_3 = Cast(c2fb_c_int, sqlite3Fts5StorageFindDeleteRow(arg0, arg1))
                local1 = c2fb_temp_3
            End If
        Else
            c2fb_temp_4 = Cast(c2fb_c_int, fts5StorageDeleteFromIndex(arg0, arg1, arg2, arg3))
            local1 = c2fb_temp_4
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->bColumnsize <> 0))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 8ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_5
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_bind_int64(local2, Cast(c2fb_c_int, 1ULL), arg1)
            c2fb_external_sqlite3_step(local2)
            c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local2))
            local1 = c2fb_temp_6
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_7 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 6ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_7
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_bind_int64(local2, Cast(c2fb_c_int, 1ULL), arg1)
            c2fb_external_sqlite3_step(local2)
            c2fb_temp_8 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local2))
            local1 = c2fb_temp_8
        End If
    End If
    Return local1
End Function
Function sqlite3Fts5StorageDeleteAll CDecl Alias "sqlite3Fts5StorageDeleteAll" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 833
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->bTotalsValid))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = Cast(c2fb_c_int, fts5ExecPrintf(CPtr(c2fb_sqlite3 Ptr, local0->db), Cast(c2fb_c_int, &O0ULL), StrPtr(!"DELETE FROM %Q.'%q_data';DELETE FROM %Q.'%q_idx';"), local0->zDb, local0->zName, local0->zDb, local0->zName))
    local1 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->bColumnsize <> 0))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, fts5ExecPrintf(CPtr(c2fb_sqlite3 Ptr, local0->db), Cast(c2fb_c_int, &O0ULL), StrPtr(!"DELETE FROM %Q.'%q_docsize';"), local0->zDb, local0->zName))
        local1 = c2fb_temp_3
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, fts5ExecPrintf(CPtr(c2fb_sqlite3 Ptr, local0->db), Cast(c2fb_c_int, &O0ULL), StrPtr(!"DELETE FROM %Q.'%q_content';"), local0->zDb, local0->zName))
        local1 = c2fb_temp_4
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexReinit(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)))
        local1 = c2fb_temp_5
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_6 = Cast(c2fb_c_int, sqlite3Fts5StorageConfigValue(arg0, StrPtr(!"version"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 4ULL)))
        local1 = c2fb_temp_6
    End If
    Return local1
End Function
Function sqlite3Fts5StorageRebuild CDecl Alias "sqlite3Fts5StorageRebuild" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 869
    Dim local0 As c2fb_Fts5Buffer
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim local3 As c2fb_Fts5InsertCtx
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Storage_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Storage Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As Const ZString Ptr
    Dim local11 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_16 As Const ZString Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_i64 Ptr
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_i64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int

    local0 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local1 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5InsertCtx Ptr, @(local3))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5InsertCtx))))
    c2fb_temp_1 = CPtr(c2fb_Fts5Storage_ Ptr Ptr, @(local3.pStorage))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Storage Ptr, arg0)
    (*c2fb_temp_1) = CPtr(c2fb_Fts5Storage_ Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_Fts5Storage Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = Cast(c2fb_c_int, sqlite3Fts5StorageDeleteAll(arg0))
    local4 = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, fts5StorageLoadTotals(arg0, Cast(c2fb_c_int, 1ULL)))
        local4 = c2fb_temp_4
    End If
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 11ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2)), local1->pzErrmsg))
        local4 = c2fb_temp_5
    End If
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local2))))) <> 0)))))
        local6 = c2fb_external_sqlite3_column_int64(local2, Cast(c2fb_c_int, &O0ULL))
        c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(local0)))
        c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexBeginWrite(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), Cast(c2fb_c_int, &O0ULL), local6))
        local4 = c2fb_temp_6
        c2fb_temp_7 = CPtr(Long Ptr, @(local3.iCol))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3.iCol < local1->nCol)))) <> 0)))))
            c2fb_temp_11 = CPtr(Long Ptr, @(local3.szCol))
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1->abUnindexed[local3.iCol]) = Cast(c2fb_c_int, &O0ULL))))) Then
                local7 = Cast(c2fb_c_int, &O0ULL)
                local8 = Cast(c2fb_c_int, &O0ULL)
                local9 = Cast(c2fb_c_int, &O0ULL)
                local10 = Cast(c2fb_c_int, &O0ULL)
                local11 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(local2, Cast(c2fb_c_int, (local3.iCol + Cast(c2fb_c_int, 1ULL)))))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->eContent = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso (c2fb_external_sqlite3Fts5IsLocaleValue(local1, local11) <> 0))))) Then
                    c2fb_temp_13 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5DecodeLocaleValue(local11, CPtr(Const ZString Ptr Ptr, @(local8)), CPtr(c2fb_c_int Ptr, @(local7)), CPtr(Const ZString Ptr Ptr, @(local10)), CPtr(c2fb_c_int Ptr, @(local9))))
                    local4 = c2fb_temp_13
                Else
                    c2fb_temp_14 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(local11)))
                    local8 = c2fb_temp_14
                    c2fb_temp_15 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes(local11))
                    local7 = c2fb_temp_15
                    If local1->bLocale Then
                        local12 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (local3.iCol + Cast(c2fb_c_int, 1ULL))) + local1->nCol))
                        c2fb_temp_16 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local2, local12)))
                        local10 = c2fb_temp_16
                        c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_bytes(local2, local12))
                        local9 = c2fb_temp_17
                    End If
                End If
                If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_external_sqlite3Fts5SetLocale(local1, local10, local9)
                    c2fb_temp_18 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5Tokenize(local1, Cast(c2fb_c_int, &H0004ULL), local8, local7, CPtr(Any Ptr, CPtr(c2fb_Fts5InsertCtx Ptr, @(local3))), ProcPtr(fts5StorageInsertCallback)))
                    local4 = c2fb_temp_18
                    c2fb_external_sqlite3Fts5ClearLocale(local1)
                End If
            End If
            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(local4)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), local3.szCol)
            c2fb_temp_19 = CPtr(c2fb_i64 Ptr, @(arg0->aTotalSize[local3.iCol]))
            c2fb_temp_20 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_19)) + Cast(c2fb_int64, local3.szCol))))
            (*c2fb_temp_19) = Cast(c2fb_i64, c2fb_temp_20)
            c2fb_temp_20 = Cast(c2fb_int64, (*c2fb_temp_19))
        c2fb_flow_3:
            c2fb_temp_9 = CPtr(Long Ptr, @(local3.iCol))
            c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
            (*c2fb_temp_9) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_temp_21 = CPtr(c2fb_i64 Ptr, @(arg0->nTotalRow))
        c2fb_temp_22 = Cast(c2fb_int64, (*c2fb_temp_21))
        (*c2fb_temp_21) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_22 + 1)))
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_23 = Cast(c2fb_c_int, fts5StorageInsertDocsize(arg0, local6, CPtr(c2fb_Fts5Buffer Ptr, @(local0))))
            local4 = c2fb_temp_23
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0.p))
    c2fb_temp_24 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local2))
    local5 = c2fb_temp_24
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_25 = Cast(c2fb_c_int, local5)
        local4 = c2fb_temp_25
    End If
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_26 = Cast(c2fb_c_int, fts5StorageSaveTotals(arg0))
        local4 = c2fb_temp_26
    End If
    Return local4
End Function
Function sqlite3Fts5StorageOptimize CDecl Alias "sqlite3Fts5StorageOptimize" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 946
    Return c2fb_external_sqlite3Fts5IndexOptimize(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex))
End Function
Function sqlite3Fts5StorageMerge CDecl Alias "sqlite3Fts5StorageMerge" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 950
    Return c2fb_external_sqlite3Fts5IndexMerge(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), arg1)
End Function
Function sqlite3Fts5StorageReset CDecl Alias "sqlite3Fts5StorageReset" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 954
    Return c2fb_external_sqlite3Fts5IndexReset(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex))
End Function
Private Function fts5StorageNewRowid CDecl Alias "fts5StorageNewRowid" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 967
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_int64 Ptr
    Dim c2fb_temp_3 As c2fb_int64

    local0 = Cast(c2fb_c_int, 20ULL)
    If CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bColumnsize Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 7ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_bind_null(local1, Cast(c2fb_c_int, 1ULL))
            c2fb_external_sqlite3_bind_null(local1, Cast(c2fb_c_int, 2ULL))
            c2fb_external_sqlite3_step(local1)
            c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local1))
            local0 = c2fb_temp_1
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(c2fb_int64 Ptr, @((*arg1)))
            c2fb_temp_3 = Cast(c2fb_int64, c2fb_external_sqlite3_last_insert_rowid(CPtr(c2fb_sqlite3 Ptr, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->db)))
            (*c2fb_temp_2) = c2fb_temp_3
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5StorageContentInsert CDecl Alias "sqlite3Fts5StorageContentInsert" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 988
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_6 As c2fb_sqlite3_value Ptr
    Dim local6 As Const ZString Ptr
    Dim local7 As Const ZString Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_int64 Ptr
    Dim c2fb_temp_11 As c2fb_int64

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local1 = Cast(c2fb_c_int, &O0ULL)
#ifdef SQLITE_DEBUG
    fts5StorageAssert(4 + 1 = 5, _
        StrPtr(!"FTS5_STMT_INSERT_CONTENT+1==FTS5_STMT_REPLACE_CONTENT"))
    fts5StorageAssert(arg1 = 0 OrElse arg1 = 1, _
        StrPtr(!"bReplace==0 || bReplace==1"))
#endif
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eContent <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->eContent <> Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg2[Cast(c2fb_c_int, 1ULL)]) = Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg3)))
            c2fb_temp_1 = Cast(c2fb_int64, c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, 1ULL)]))
            (*c2fb_temp_0) = c2fb_temp_1
        Else
            c2fb_temp_2 = Cast(c2fb_c_int, fts5StorageNewRowid(arg0, arg3))
            local1 = c2fb_temp_2
        End If
    Else
        local2 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        c2fb_temp_3 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + arg1)), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_3
        If local2 Then
            c2fb_external_sqlite3_clear_bindings(local2)
        End If
        c2fb_external_sqlite3_bind_value(local2, Cast(c2fb_c_int, 1ULL), CPtr(Const c2fb_sqlite3_value Ptr, arg2[Cast(c2fb_c_int, 1ULL)]))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
        local3 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 <= Cast(c2fb_c_int, (local0->nCol + Cast(c2fb_c_int, 1ULL))))))) <> 0)))))
            local4 = local0->abUnindexed[Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, 2ULL)))]
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (local4 <> 0))))) Then
                local5 = arg2[local3]
                If (-Cast(c2fb_c_int, (((c2fb_external_sqlite3_value_nochange(local5) <> 0) AndAlso (CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow) <> 0))))) Then
                    c2fb_temp_6 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow), Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, 1ULL)))))
                    local5 = c2fb_temp_6
                    If (-Cast(c2fb_c_int, (((local0->bLocale <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        c2fb_external_sqlite3_bind_value(local2, Cast(c2fb_c_int, (local0->nCol + local3)), CPtr(Const c2fb_sqlite3_value Ptr, CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow), Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0->nCol + local3)) - Cast(c2fb_c_int, 1ULL)))))))
                    End If
                Else
                    If c2fb_external_sqlite3Fts5IsLocaleValue(local0, local5) Then
#ifdef SQLITE_DEBUG
                        fts5StorageAssert(local0->bLocale <> 0, _
                            StrPtr(!"pConfig->bLocale"))
#endif
                        local6 = Cast(c2fb_c_int, &O0ULL)
                        local7 = Cast(c2fb_c_int, &O0ULL)
                        local8 = Cast(c2fb_c_int, &O0ULL)
                        local9 = Cast(c2fb_c_int, &O0ULL)
                        ' C unused-parameter annotation
                        c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5DecodeLocaleValue(local5, CPtr(Const ZString Ptr Ptr, @(local6)), CPtr(c2fb_c_int Ptr, @(local8)), CPtr(Const ZString Ptr Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local9))))
                        local1 = c2fb_temp_7
                        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_external_sqlite3_bind_text(local2, local3, local6, local8, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
                            If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
                                local10 = Cast(c2fb_c_int, (local0->nCol + local3))
                                c2fb_external_sqlite3_bind_text(local2, local10, local7, local9, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
                            End If
                        End If
                        Goto c2fb_flow_1
                    End If
                End If
                c2fb_temp_8 = Cast(c2fb_c_int, c2fb_external_sqlite3_bind_value(local2, local3, CPtr(Const c2fb_sqlite3_value Ptr, local5)))
                local1 = c2fb_temp_8
            End If
        c2fb_flow_1:
            c2fb_temp_5 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_step(local2)
            c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local2))
            local1 = c2fb_temp_9
        End If
        c2fb_temp_10 = CPtr(c2fb_int64 Ptr, @((*arg3)))
        c2fb_temp_11 = Cast(c2fb_int64, c2fb_external_sqlite3_last_insert_rowid(CPtr(c2fb_sqlite3 Ptr, local0->db)))
        (*c2fb_temp_10) = c2fb_temp_11
    End If
    Return local1
End Function
Function sqlite3Fts5StorageIndexInsert CDecl Alias "sqlite3Fts5StorageIndexInsert" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr Ptr, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1069
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5InsertCtx
    Dim local3 As c2fb_Fts5Buffer
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Storage_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Storage Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As Const ZString Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As Const ZString Ptr
    Dim local8 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_11 As c2fb_sqlite3_value Ptr
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_12 As Const ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Const ZString Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_i64 Ptr
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_i64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local3))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
    c2fb_temp_1 = CPtr(c2fb_Fts5Storage_ Ptr Ptr, @(local2.pStorage))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Storage Ptr, arg0)
    (*c2fb_temp_1) = CPtr(c2fb_Fts5Storage_ Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_Fts5Storage Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = Cast(c2fb_c_int, fts5StorageLoadTotals(arg0, Cast(c2fb_c_int, 1ULL)))
    local1 = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexBeginWrite(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), Cast(c2fb_c_int, &O0ULL), arg2))
        local1 = c2fb_temp_4
    End If
    c2fb_temp_5 = CPtr(Long Ptr, @(local2.iCol))
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2.iCol < local0->nCol)))) <> 0)))))
        c2fb_temp_9 = CPtr(Long Ptr, @(local2.szCol))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->abUnindexed[local2.iCol]) = Cast(c2fb_c_int, &O0ULL))))) Then
            local4 = Cast(c2fb_c_int, &O0ULL)
            local5 = Cast(c2fb_c_int, &O0ULL)
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = arg1[Cast(c2fb_c_int, (local2.iCol + Cast(c2fb_c_int, 2ULL)))]
            If (-Cast(c2fb_c_int, (((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow) <> 0) AndAlso (c2fb_external_sqlite3_value_nochange(local8) <> 0))))) Then
                c2fb_temp_11 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow), Cast(c2fb_c_int, (local2.iCol + Cast(c2fb_c_int, 1ULL)))))
                local8 = c2fb_temp_11
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->bLocale <> 0))))) Then
                    local9 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (local2.iCol + Cast(c2fb_c_int, 1ULL))) + local0->nCol))
                    c2fb_temp_12 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow), local9)))
                    local7 = c2fb_temp_12
                    c2fb_temp_13 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_bytes(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSavedRow), local9))
                    local6 = c2fb_temp_13
                End If
            Else
                c2fb_temp_14 = arg1[Cast(c2fb_c_int, (local2.iCol + Cast(c2fb_c_int, 2ULL)))]
                local8 = c2fb_temp_14
            End If
            If (-Cast(c2fb_c_int, (((local0->bLocale <> 0) AndAlso (c2fb_external_sqlite3Fts5IsLocaleValue(local0, local8) <> 0))))) Then
                c2fb_temp_15 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5DecodeLocaleValue(local8, CPtr(Const ZString Ptr Ptr, @(local5)), CPtr(c2fb_c_int Ptr, @(local4)), CPtr(Const ZString Ptr Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local6))))
                local1 = c2fb_temp_15
            Else
                c2fb_temp_16 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(local8)))
                local5 = c2fb_temp_16
                c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes(local8))
                local4 = c2fb_temp_17
            End If
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_external_sqlite3Fts5SetLocale(local0, local7, local6)
                c2fb_temp_18 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5Tokenize(local0, Cast(c2fb_c_int, &H0004ULL), local5, local4, CPtr(Any Ptr, CPtr(c2fb_Fts5InsertCtx Ptr, @(local2))), ProcPtr(fts5StorageInsertCallback)))
                local1 = c2fb_temp_18
                c2fb_external_sqlite3Fts5ClearLocale(local0)
            End If
        End If
        c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local3)), local2.szCol)
        c2fb_temp_19 = CPtr(c2fb_i64 Ptr, @(arg0->aTotalSize[local2.iCol]))
        c2fb_temp_20 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_19)) + Cast(c2fb_int64, local2.szCol))))
        (*c2fb_temp_19) = Cast(c2fb_i64, c2fb_temp_20)
        c2fb_temp_20 = Cast(c2fb_int64, (*c2fb_temp_19))
    c2fb_flow_1:
        c2fb_temp_7 = CPtr(Long Ptr, @(local2.iCol))
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        (*c2fb_temp_7) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_21 = CPtr(c2fb_i64 Ptr, @(arg0->nTotalRow))
    c2fb_temp_22 = Cast(c2fb_int64, (*c2fb_temp_21))
    (*c2fb_temp_21) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_22 + 1)))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_23 = Cast(c2fb_c_int, fts5StorageInsertDocsize(arg0, arg2, CPtr(c2fb_Fts5Buffer Ptr, @(local3))))
        local1 = c2fb_temp_23
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local3.p))
    Return local1
End Function
Private Function fts5StorageCount CDecl Alias "fts5StorageCount" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1136
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_int64 Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT count(*) FROM %Q.'%q_%s'"), local0->zDb, local0->zName, arg1))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_1
    Else
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2(CPtr(c2fb_sqlite3 Ptr, local0->db), CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local3)), Cast(c2fb_c_int, &O0ULL)))
        local2 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local3))))) Then
                c2fb_temp_3 = CPtr(c2fb_int64 Ptr, @((*arg2)))
                c2fb_temp_4 = Cast(c2fb_int64, c2fb_external_sqlite3_column_int64(local3, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_3) = c2fb_temp_4
            End If
            c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize(local3))
            local2 = c2fb_temp_5
        End If
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    Return local2
End Function
Private Function fts5StorageIntegrityCallback CDecl Alias "fts5StorageIntegrityCallback" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1178
    Dim local0 As c2fb_Fts5IntegrityCtx Ptr
    Dim local1 As c2fb_Fts5Termset Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_u64 Ptr
    Dim c2fb_temp_11 As c2fb_uint64
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_u64 Ptr
    Dim c2fb_temp_16 As c2fb_uint64

    local0 = CPtr(c2fb_Fts5IntegrityCtx Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Termset Ptr, local0->pTermset)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, 32768ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 32768ULL))
        arg3 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0001ULL)))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->szCol = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_1 = CPtr(Long Ptr, @(local0->szCol))
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        (*c2fb_temp_1) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    End If
    Select Case CPtr(c2fb_Fts5Config Ptr, local0->pConfig)->eDetail
        Case Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0->szCol - Cast(c2fb_c_int, 1ULL))))
            local5 = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_c_int, local0->iCol)
            local6 = c2fb_temp_4
        Case Cast(c2fb_c_int, 2ULL)
            c2fb_temp_5 = Cast(c2fb_c_int, local0->iCol)
            local5 = c2fb_temp_5
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local6 = c2fb_temp_6
        Case Else
            ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
            fts5StorageAssert(CPtr(c2fb_Fts5Config Ptr, local0->pConfig)->eDetail = 1, _
                StrPtr(!"pCtx->pConfig->eDetail==FTS5_DETAIL_NONE"))
#endif
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local5 = c2fb_temp_7
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local6 = c2fb_temp_8
    End Select
    c2fb_flow_0:
    c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5TermsetAdd(local1, Cast(c2fb_c_int, &O0ULL), arg2, arg3, CPtr(c2fb_c_int Ptr, @(local2))))
    local4 = c2fb_temp_9
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_10 = CPtr(c2fb_u64 Ptr, @(local0->cksum))
        c2fb_temp_11 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (*c2fb_temp_10)) Xor c2fb_external_sqlite3Fts5IndexEntryCksum(local0->iRowid, local6, local5, Cast(c2fb_c_int, &O0ULL), arg2, arg3))))
        (*c2fb_temp_10) = Cast(c2fb_u64, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_uint64, (*c2fb_temp_10))
    End If
    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_12
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 < CPtr(c2fb_Fts5Config Ptr, local0->pConfig)->nPrefix)))) <> 0)))))
        local7 = CPtr(c2fb_Fts5Config Ptr, local0->pConfig)->aPrefix[local3]
        local8 = c2fb_external_sqlite3Fts5IndexCharlenToBytelen(arg2, arg3, local7)
        If local8 Then
            c2fb_temp_14 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5TermsetAdd(local1, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))), arg2, local8, CPtr(c2fb_c_int Ptr, @(local2))))
            local4 = c2fb_temp_14
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_15 = CPtr(c2fb_u64 Ptr, @(local0->cksum))
                c2fb_temp_16 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (*c2fb_temp_15)) Xor c2fb_external_sqlite3Fts5IndexEntryCksum(local0->iRowid, local6, local5, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))), arg2, local8))))
                (*c2fb_temp_15) = Cast(c2fb_u64, c2fb_temp_16)
                c2fb_temp_16 = Cast(c2fb_uint64, (*c2fb_temp_15))
            End If
        End If
    c2fb_flow_2:
        c2fb_temp_13 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
    Wend
    c2fb_flow_1:
    Return local4
End Function
Function sqlite3Fts5StorageIntegrity CDecl Alias "sqlite3Fts5StorageIntegrity" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1248
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int Ptr
    Dim local3 As c2fb_int64 Ptr
    Dim local4 As c2fb_Fts5IntegrityCtx
    Dim local5 As c2fb_sqlite3_stmt Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Config_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_3 As c2fb_int64 Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_i64 Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local9 As Const ZString Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As Const ZString Ptr
    Dim local12 As c2fb_c_int
    Dim local13 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_17 As Const ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Const ZString Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Long Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_int64 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim c2fb_temp_30 As c2fb_Fts5Termset_ Ptr Ptr
    Dim c2fb_temp_31 As c2fb_Fts5Termset Ptr
    Dim c2fb_temp_32 As c2fb_Fts5Termset_ Ptr Ptr
    Dim c2fb_temp_33 As c2fb_Fts5Termset Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_c_int
    Dim local16 As c2fb_int64
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int
    Dim local17 As c2fb_int64
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5IntegrityCtx Ptr, @(local4))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5IntegrityCtx))))
    c2fb_temp_1 = CPtr(c2fb_Fts5Config_ Ptr Ptr, @(local4.pConfig))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig))
    (*c2fb_temp_1) = CPtr(c2fb_Fts5Config_ Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(c2fb_int64 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, local0->nCol) * (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64)))))))))))
    local3 = c2fb_temp_3
    If (-Cast(c2fb_c_int, (local3 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, CPtr(c2fb_int64 Ptr, @(local3[local0->nCol])))
    local2 = c2fb_temp_4
    c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local3), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, local0->nCol)))))
    c2fb_temp_6 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso (arg1 <> 0)))))) <> 0)))))))
    local6 = c2fb_temp_6
    If local6 Then
        c2fb_temp_7 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 11ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local5)), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local5)))))
                ' C automatic storage declaration
                c2fb_temp_8 = CPtr(c2fb_i64 Ptr, @(local4.iRowid))
                c2fb_temp_9 = Cast(c2fb_int64, c2fb_external_sqlite3_column_int64(local5, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_8) = Cast(c2fb_i64, c2fb_temp_9)
                c2fb_temp_9 = Cast(c2fb_int64, (*c2fb_temp_8))
                c2fb_temp_10 = CPtr(Long Ptr, @(local4.szCol))
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
                c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                If local0->bColumnsize Then
                    c2fb_temp_12 = Cast(c2fb_c_int, sqlite3Fts5StorageDocsize(arg0, local4.iRowid, local2))
                    local1 = c2fb_temp_12
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->eDetail = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                    c2fb_temp_13 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5TermsetNew(CPtr(c2fb_Fts5Termset Ptr Ptr, @(local4.pTermset))))
                    local1 = c2fb_temp_13
                End If
                c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local8 = c2fb_temp_14
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 < local0->nCol)))) <> 0)))))
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->abUnindexed[local8]) = Cast(c2fb_c_int, &O0ULL))))) Then
                        local9 = Cast(c2fb_c_int, &O0ULL)
                        local10 = Cast(c2fb_c_int, &O0ULL)
                        local11 = Cast(c2fb_c_int, &O0ULL)
                        local12 = Cast(c2fb_c_int, &O0ULL)
                        local13 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(local5, Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, 1ULL)))))
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso (c2fb_external_sqlite3Fts5IsLocaleValue(local0, local13) <> 0))))) Then
                            c2fb_temp_16 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5DecodeLocaleValue(local13, CPtr(Const ZString Ptr Ptr, @(local9)), CPtr(c2fb_c_int Ptr, @(local10)), CPtr(Const ZString Ptr Ptr, @(local11)), CPtr(c2fb_c_int Ptr, @(local12))))
                            local1 = c2fb_temp_16
                        Else
                            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->bLocale <> 0))))) Then
                                local14 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, 1ULL))) + local0->nCol))
                                c2fb_temp_17 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local5, local14)))
                                local11 = c2fb_temp_17
                                c2fb_temp_18 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_bytes(local5, local14))
                                local12 = c2fb_temp_18
                            End If
                            c2fb_temp_19 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(local13)))
                            local9 = c2fb_temp_19
                            c2fb_temp_20 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes(local13))
                            local10 = c2fb_temp_20
                        End If
                        c2fb_temp_21 = CPtr(Long Ptr, @(local4.iCol))
                        c2fb_temp_22 = Cast(c2fb_c_int, local8)
                        (*c2fb_temp_21) = Cast(Long, c2fb_temp_22)
                        c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
                        c2fb_temp_23 = CPtr(Long Ptr, @(local4.szCol))
                        c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
                        c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->eDetail = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                            c2fb_temp_25 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5TermsetNew(CPtr(c2fb_Fts5Termset Ptr Ptr, @(local4.pTermset))))
                            local1 = c2fb_temp_25
                        End If
                        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_external_sqlite3Fts5SetLocale(local0, local11, local12)
                            c2fb_temp_26 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5Tokenize(local0, Cast(c2fb_c_int, &H0004ULL), local9, local10, CPtr(Any Ptr, CPtr(c2fb_Fts5IntegrityCtx Ptr, @(local4))), ProcPtr(fts5StorageIntegrityCallback)))
                            local1 = c2fb_temp_26
                            c2fb_external_sqlite3Fts5ClearLocale(local0)
                        End If
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->bColumnsize <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4.szCol <> local2[local8])))) <> 0))))) Then
                            c2fb_temp_27 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                            local1 = c2fb_temp_27
                        End If
                        c2fb_temp_28 = CPtr(c2fb_int64 Ptr, @(local3[local8]))
                        c2fb_temp_29 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_28) + Cast(c2fb_int64, local4.szCol))))
                        (*c2fb_temp_28) = c2fb_temp_29
                        If (-Cast(c2fb_c_int, ((local0->eDetail = Cast(c2fb_c_int, 2ULL))))) Then
                            c2fb_external_sqlite3Fts5TermsetFree(CPtr(c2fb_Fts5Termset Ptr, local4.pTermset))
                            c2fb_temp_30 = CPtr(c2fb_Fts5Termset_ Ptr Ptr, @(local4.pTermset))
                            c2fb_temp_31 = CPtr(c2fb_Fts5Termset Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            (*c2fb_temp_30) = CPtr(c2fb_Fts5Termset_ Ptr, c2fb_temp_31)
                            c2fb_temp_31 = CPtr(c2fb_Fts5Termset Ptr, (*c2fb_temp_30))
                        End If
                    End If
                c2fb_flow_3:
                    c2fb_temp_15 = local8
                    local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
                Wend
                c2fb_flow_2:
                c2fb_external_sqlite3Fts5TermsetFree(CPtr(c2fb_Fts5Termset Ptr, local4.pTermset))
                c2fb_temp_32 = CPtr(c2fb_Fts5Termset_ Ptr Ptr, @(local4.pTermset))
                c2fb_temp_33 = CPtr(c2fb_Fts5Termset Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_32) = CPtr(c2fb_Fts5Termset_ Ptr, c2fb_temp_33)
                c2fb_temp_33 = CPtr(c2fb_Fts5Termset Ptr, (*c2fb_temp_32))
                If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_0
                End If
            c2fb_flow_1:
            Wend
            c2fb_flow_0:
            c2fb_temp_34 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local5))
            local7 = c2fb_temp_34
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_35 = Cast(c2fb_c_int, local7)
                local1 = c2fb_temp_35
            End If
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_36 = Cast(c2fb_c_int, fts5StorageLoadTotals(arg0, Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_36
            c2fb_temp_37 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local15 = c2fb_temp_37
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local15 < local0->nCol)))) <> 0)))))
                If (-Cast(c2fb_c_int, ((arg0->aTotalSize[local15] <> local3[local15])))) Then
                    c2fb_temp_39 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local1 = c2fb_temp_39
                End If
            c2fb_flow_5:
                c2fb_temp_38 = local15
                local15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_38 + 1)))
            Wend
            c2fb_flow_4:
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            local16 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_40 = Cast(c2fb_c_int, fts5StorageCount(arg0, StrPtr(!"content"), CPtr(c2fb_int64 Ptr, @(local16))))
            local1 = c2fb_temp_40
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local16 <> arg0->nTotalRow)))) <> 0))))) Then
                c2fb_temp_41 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                local1 = c2fb_temp_41
            End If
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->bColumnsize <> 0))))) Then
            local17 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_42 = Cast(c2fb_c_int, fts5StorageCount(arg0, StrPtr(!"docsize"), CPtr(c2fb_int64 Ptr, @(local17))))
            local1 = c2fb_temp_42
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local17 <> arg0->nTotalRow)))) <> 0))))) Then
                c2fb_temp_43 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                local1 = c2fb_temp_43
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_44 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexIntegrityCheck(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), local4.cksum, local6))
        local1 = c2fb_temp_44
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
    Return local1
End Function
Function sqlite3Fts5StorageStmt CDecl Alias "sqlite3Fts5StorageStmt" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1388
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Any Ptr Ptr
    Dim c2fb_temp_2 As c2fb_sqlite3_stmt Ptr

#ifdef SQLITE_DEBUG
    fts5StorageAssert(arg1 = 0 OrElse arg1 = 1 OrElse arg1 = 2, _
        StrPtr(!"eStmt is SCAN_ASC, SCAN_DESC, or LOOKUP"))
#endif
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, arg1, arg2, arg3))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
        fts5StorageAssert(CPtr(Any Ptr, arg0->aStmt(arg1)) = CPtr(Any Ptr, (*arg2)), _
            StrPtr(!"p->aStmt[eStmt]==*pp"))
#endif
        c2fb_temp_1 = CPtr(Any Ptr Ptr, @(arg0->aStmt(arg1)))
        c2fb_temp_2 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_1) = CPtr(Any Ptr, c2fb_temp_2)
        c2fb_temp_2 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_1))
    End If
    Return local0
End Function
Sub sqlite3Fts5StorageStmtRelease CDecl Alias "sqlite3Fts5StorageStmtRelease" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_stmt Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1412
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As c2fb_sqlite3_stmt Ptr

    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    fts5StorageAssert(arg1 = 0 OrElse arg1 = 1 OrElse arg1 = 2, _
        StrPtr(!"eStmt is SCAN_ASC, SCAN_DESC, or LOOKUP"))
#endif
    If (-Cast(c2fb_c_int, ((arg0->aStmt(arg1) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_reset(arg2)
        c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->aStmt(arg1)))
        c2fb_temp_1 = arg2
        (*c2fb_temp_0) = CPtr(Any Ptr, c2fb_temp_1)
        c2fb_temp_1 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_0))
    Else
        c2fb_external_sqlite3_finalize(arg2)
    End If
End Sub
Function sqlite3Fts5StorageDocsize CDecl Alias "sqlite3Fts5StorageDocsize" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1437
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As Const UByte Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

#ifdef SQLITE_DEBUG
    fts5StorageAssert(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bColumnsize <> 0, _
        StrPtr(!"p->pConfig->bColumnsize"))
#endif
    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 9ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))
    local2 = c2fb_temp_0
    If local1 Then
#ifdef SQLITE_DEBUG
        fts5StorageAssert(local2 = 0, StrPtr(!"rc==SQLITE_OK"))
#endif
        local3 = Cast(c2fb_c_int, 1ULL)
        ' C unused-parameter annotation
        c2fb_external_sqlite3_bind_int64(local1, Cast(c2fb_c_int, 1ULL), arg1)
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local1))))) Then
            local4 = CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob(local1, Cast(c2fb_c_int, &O0ULL)))
            local5 = c2fb_external_sqlite3_column_bytes(local1, Cast(c2fb_c_int, &O0ULL))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5StorageDecodeSizeArray(arg2, local0, local4, local5))))) Then
                c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_1
            End If
        End If
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local1))
        local2 = c2fb_temp_2
        If (-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local2 = c2fb_temp_3
        End If
    Else
#ifdef SQLITE_DEBUG
        fts5StorageAssert(local2 <> 0, StrPtr(!"rc!=SQLITE_OK"))
#endif
    End If
    Return local2
End Function
Function sqlite3Fts5StorageSize CDecl Alias "sqlite3Fts5StorageSize" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1466
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_int64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = fts5StorageLoadTotals(arg0, Cast(c2fb_c_int, &O0ULL))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg2)))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((local1 < CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol))))
                c2fb_temp_4 = CPtr(c2fb_int64 Ptr, @((*arg2)))
                c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_4) + arg0->aTotalSize[local1])))
                (*c2fb_temp_4) = c2fb_temp_5
            c2fb_flow_1:
                c2fb_temp_3 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            Wend
            c2fb_flow_0:
        Else
            If (-Cast(c2fb_c_int, ((arg1 < CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol)))) Then
                c2fb_temp_6 = CPtr(c2fb_int64 Ptr, @((*arg2)))
                c2fb_temp_7 = Cast(c2fb_int64, arg0->aTotalSize[arg1])
                (*c2fb_temp_6) = c2fb_temp_7
            Else
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 25ULL))
                local0 = c2fb_temp_8
            End If
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5StorageRowCount CDecl Alias "sqlite3Fts5StorageRowCount" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1484
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = fts5StorageLoadTotals(arg0, Cast(c2fb_c_int, &O0ULL))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_1 = Cast(c2fb_int64, arg0->nTotalRow)
        (*c2fb_temp_0) = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((arg0->nTotalRow <= Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_2
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5StorageSync CDecl Alias "sqlite3Fts5StorageSync" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1501
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = c2fb_external_sqlite3_last_insert_rowid(CPtr(c2fb_sqlite3 Ptr, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->db))
    If arg0->bTotalsValid Then
        c2fb_temp_0 = Cast(c2fb_c_int, fts5StorageSaveTotals(arg0))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(Long Ptr, @(arg0->bTotalsValid))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
            c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexSync(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)))
        local0 = c2fb_temp_3
    End If
    c2fb_external_sqlite3_set_last_insert_rowid(CPtr(c2fb_sqlite3 Ptr, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->db), local1)
    Return local0
End Function
Function sqlite3Fts5StorageRollback CDecl Alias "sqlite3Fts5StorageRollback" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1517
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->bTotalsValid))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    Return c2fb_external_sqlite3Fts5IndexRollback(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex))
End Function
Function sqlite3Fts5StorageConfigValue CDecl Alias "sqlite3Fts5StorageConfigValue" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_storage.c
' c2fb source-line: 1522
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = fts5StorageGetStmt(arg0, Cast(c2fb_c_int, 10ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), Cast(c2fb_c_int, &O0ULL))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_bind_text(local0, Cast(c2fb_c_int, 1ULL), arg1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        If arg2 Then
            c2fb_external_sqlite3_bind_value(local0, Cast(c2fb_c_int, 2ULL), CPtr(Const c2fb_sqlite3_value Ptr, arg2))
        Else
            c2fb_external_sqlite3_bind_int(local0, Cast(c2fb_c_int, 2ULL), arg3)
        End If
        c2fb_external_sqlite3_step(local0)
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(local0))
        local1 = c2fb_temp_0
        c2fb_external_sqlite3_bind_null(local0, Cast(c2fb_c_int, 1ULL))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg2 <> 0))))) Then
        local2 = Cast(c2fb_c_int, (CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->iCookie + Cast(c2fb_c_int, 1ULL)))
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexSetCookie(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), local2))
        local1 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->iCookie))
            c2fb_temp_3 = Cast(c2fb_c_int, local2)
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        End If
    End If
    Return local1
End Function
#endif

/' end of sqlite3_bulk_fts5_storage.bas '/
