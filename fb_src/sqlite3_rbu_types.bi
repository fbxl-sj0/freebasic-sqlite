/'
    Project: SQLite RBU Extension

    File: sqlite3_rbu_types.bi

    Purpose:

        Declare private records and C ABI types used by the RBU module.

    Responsibilities:

        - RBU state and VFS records
        - Callback signatures shared by RBU procedures

    This file intentionally does NOT contain:

        - RBU operations or public API procedures
        - SQLite test support
'/
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
' User-defined scalar types and by-value records must be declared before generated declarations.
' Source filters and ordered routes apply to declarations, record layouts, macros, inline functions, and library pragmas.
' Types omitted by source filters must be supplied by an earlier declaration, --fb-include, or a preserved C include mapping.
' c2fb excludes requested function, object, or macro: *
' c2fb excludes requested procedure: *

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
Type c2fb_size_t As SQLITE_SIZE_T
#endif
Type c2fb_sqlite3_file As _c2fb_record_c2fb_sqlite3_file
Type c2fb_sqlite3_file_ As c2fb_sqlite3_file
Type c2fb_sqlite3_io_methods As _c2fb_record_c2fb_sqlite3_io_methods
Type c2fb_sqlite3_io_methods_ As c2fb_sqlite3_io_methods
Type c2fb_sqlite3_vfs As _c2fb_record_c2fb_sqlite3_vfs
Type c2fb_sqlite3_vfs_ As c2fb_sqlite3_vfs
Type c2fb_sqlite3_mem_methods As _c2fb_record_c2fb_sqlite3_mem_methods
Type c2fb_sqlite3_mem_methods_ As c2fb_sqlite3_mem_methods
Type c2fb_sqlite3_index_constraint As _c2fb_record_c2fb_sqlite3_index_constraint
Type c2fb_sqlite3_index_orderby As _c2fb_record_c2fb_sqlite3_index_orderby
Type c2fb_sqlite3_index_constraint_usage As _c2fb_record_c2fb_sqlite3_index_constraint_usage
Type c2fb_sqlite3_index_info As _c2fb_record_c2fb_sqlite3_index_info
Type c2fb_sqlite3_index_info_ As c2fb_sqlite3_index_info
Type c2fb_sqlite3_vtab As _c2fb_record_c2fb_sqlite3_vtab
Type c2fb_sqlite3_vtab_ As c2fb_sqlite3_vtab
Type c2fb_sqlite3_vtab_cursor As _c2fb_record_c2fb_sqlite3_vtab_cursor
Type c2fb_sqlite3_vtab_cursor_ As c2fb_sqlite3_vtab_cursor
Type c2fb_sqlite3_mutex_methods As _c2fb_record_c2fb_sqlite3_mutex_methods
Type c2fb_sqlite3_mutex_methods_ As c2fb_sqlite3_mutex_methods
Type c2fb_sqlite3_pcache_page As _c2fb_record_c2fb_sqlite3_pcache_page
Type c2fb_sqlite3_pcache_page_ As c2fb_sqlite3_pcache_page
Type c2fb_sqlite3_pcache_methods2 As _c2fb_record_c2fb_sqlite3_pcache_methods2
Type c2fb_sqlite3_pcache_methods2_ As c2fb_sqlite3_pcache_methods2
Type c2fb_sqlite3_pcache_methods As _c2fb_record_c2fb_sqlite3_pcache_methods
Type c2fb_sqlite3_pcache_methods_ As c2fb_sqlite3_pcache_methods
Type c2fb_sqlite3_snapshot As _c2fb_record_c2fb_sqlite3_snapshot
Type c2fb_sqlite3_snapshot_ As c2fb_sqlite3_snapshot
Type c2fb_sqlite3_rtree_geometry As _c2fb_record_c2fb_sqlite3_rtree_geometry
Type c2fb_sqlite3_rtree_geometry_ As c2fb_sqlite3_rtree_geometry
Type c2fb_sqlite3_rtree_query_info As _c2fb_record_c2fb_sqlite3_rtree_query_info
Type c2fb_sqlite3_rtree_query_info_ As c2fb_sqlite3_rtree_query_info
Type c2fb_Fts5PhraseIter As _c2fb_record_c2fb_Fts5PhraseIter
Type c2fb_Fts5PhraseIter_ As c2fb_Fts5PhraseIter
Type c2fb_Fts5ExtensionApi As _c2fb_record_c2fb_Fts5ExtensionApi
Type c2fb_Fts5ExtensionApi_ As c2fb_Fts5ExtensionApi
Type c2fb_fts5_tokenizer_v2 As _c2fb_record_c2fb_fts5_tokenizer_v2
Type c2fb_fts5_tokenizer_v2_ As c2fb_fts5_tokenizer_v2
Type c2fb_fts5_tokenizer As _c2fb_record_c2fb_fts5_tokenizer
Type c2fb_fts5_tokenizer_ As c2fb_fts5_tokenizer
Type c2fb_fts5_api As _c2fb_record_c2fb_fts5_api
Type c2fb_fts5_api_ As c2fb_fts5_api
Type c2fb_RbuState As _c2fb_record_c2fb_RbuState
Type c2fb_RbuState_ As c2fb_RbuState
Type c2fb_RbuUpdateStmt As _c2fb_record_c2fb_RbuUpdateStmt
Type c2fb_RbuUpdateStmt_ As c2fb_RbuUpdateStmt
Type c2fb_RbuSpan As _c2fb_record_c2fb_RbuSpan
Type c2fb_RbuSpan_ As c2fb_RbuSpan
Type c2fb_RbuObjIter As _c2fb_record_c2fb_RbuObjIter
Type c2fb_RbuObjIter_ As c2fb_RbuObjIter
Type c2fb_RbuFrame As _c2fb_record_c2fb_RbuFrame
Type c2fb_RbuFrame_ As c2fb_RbuFrame
Type c2fb_sqlite3rbu As _c2fb_record_c2fb_sqlite3rbu
Type c2fb_sqlite3rbu_ As c2fb_sqlite3rbu
Type c2fb_rbu_vfs As _c2fb_record_c2fb_rbu_vfs
Type c2fb_rbu_vfs_ As c2fb_rbu_vfs
Type c2fb_rbu_file As _c2fb_record_c2fb_rbu_file
Type c2fb_rbu_file_ As c2fb_rbu_file

Type c2fb_threadlocaleinfostruct As _c2fb_record_c2fb_threadlocaleinfostruct
Type c2fb_threadmbcinfostruct As _c2fb_record_c2fb_threadmbcinfostruct
Type c2fb___lc_time_data As _c2fb_record_c2fb___lc_time_data
Type c2fb_localeinfo_struct As _c2fb_record_c2fb_localeinfo_struct
Type c2fb__locale_tstruct As c2fb_localeinfo_struct
Type c2fb_tagLC_ID As _c2fb_record_c2fb_tagLC_ID
Type c2fb_LC_ID As c2fb_tagLC_ID
Type c2fb_threadlocinfo As c2fb_threadlocaleinfostruct
Type c2fb__iobuf As _c2fb_record_c2fb__iobuf
Type c2fb_FILE As c2fb__iobuf
Type c2fb_sqlite3 As _c2fb_record_c2fb_sqlite3
Type c2fb_sqlite3_ As c2fb_sqlite3
Type c2fb_sqlite3_mutex As _c2fb_record_c2fb_sqlite3_mutex
Type c2fb_sqlite3_mutex_ As c2fb_sqlite3_mutex
Type c2fb_sqlite3_api_routines As _c2fb_record_c2fb_sqlite3_api_routines
Type c2fb_sqlite3_api_routines_ As c2fb_sqlite3_api_routines
Type c2fb_sqlite3_stmt As _c2fb_record_c2fb_sqlite3_stmt
Type c2fb_sqlite3_stmt_ As c2fb_sqlite3_stmt
Type c2fb_sqlite3_value As _c2fb_record_c2fb_sqlite3_value
Type c2fb_sqlite3_value_ As c2fb_sqlite3_value
Type c2fb_sqlite3_context As _c2fb_record_c2fb_sqlite3_context
Type c2fb_sqlite3_context_ As c2fb_sqlite3_context
Type c2fb_sqlite3_blob As _c2fb_record_c2fb_sqlite3_blob
Type c2fb_sqlite3_blob_ As c2fb_sqlite3_blob
Type c2fb_sqlite3_str As _c2fb_record_c2fb_sqlite3_str
Type c2fb_sqlite3_str_ As c2fb_sqlite3_str
Type c2fb_sqlite3_pcache As _c2fb_record_c2fb_sqlite3_pcache
Type c2fb_sqlite3_pcache_ As c2fb_sqlite3_pcache
Type c2fb_sqlite3_backup As _c2fb_record_c2fb_sqlite3_backup
Type c2fb_sqlite3_backup_ As c2fb_sqlite3_backup
Type c2fb_Fts5Context As _c2fb_record_c2fb_Fts5Context
Type c2fb_Fts5Context_ As c2fb_Fts5Context
Type c2fb_Fts5Tokenizer As _c2fb_record_c2fb_Fts5Tokenizer
Type c2fb_Fts5Tokenizer_ As c2fb_Fts5Tokenizer
Type c2fb_sqlite3_module As _c2fb_record_c2fb_sqlite3_module
Type c2fb_sqlite3_module_ As c2fb_sqlite3_module

Type c2fb___gnuc_va_list As __builtin_va_list
Type c2fb_va_list As c2fb___gnuc_va_list
#ifndef __C2FB_ABI_TYPE_SIZE_T__
#define __C2FB_ABI_TYPE_SIZE_T__
Type c2fb_size_t As ULong
#endif
Type c2fb_ssize_t As Long
Type c2fb_rsize_t As UInteger
Type c2fb_intptr_t As Long
Type c2fb_uintptr_t As ULong
Type c2fb_ptrdiff_t As Long
Type c2fb_wchar_t As UShort
Type c2fb_wint_t As UShort
Type c2fb_wctype_t As UShort
Type c2fb_errno_t As Long
Type c2fb___time32_t As CLong
Type c2fb___time64_t As LongInt
Type c2fb_time_t As c2fb___time32_t
Type c2fb_pthreadlocinfo As c2fb_threadlocaleinfostruct Ptr
Type c2fb_pthreadmbcinfo As c2fb_threadmbcinfostruct Ptr
Type c2fb__off_t As CLong
Type c2fb_off32_t As CLong
Type c2fb__off64_t As LongInt
Type c2fb_off64_t As LongInt
Type c2fb_off_t As c2fb_off32_t
Type c2fb_fpos_t As LongInt
Type c2fb_sqlite_int64 As LongInt
Type c2fb_sqlite_uint64 As ULongInt
Type c2fb_sqlite3_int64 As c2fb_sqlite_int64
Type c2fb_sqlite3_uint64 As c2fb_sqlite_uint64
Type c2fb_sqlite3_callback As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As Long
Type c2fb_sqlite3_file_ As c2fb_sqlite3_file
Type c2fb_sqlite3_io_methods_ As c2fb_sqlite3_io_methods
Type c2fb_sqlite3_filename As Const ZString Ptr
Type c2fb_sqlite3_vfs_ As c2fb_sqlite3_vfs
Type c2fb_sqlite3_syscall_ptr As Sub CDecl()
Type c2fb_sqlite3_mem_methods_ As c2fb_sqlite3_mem_methods
Type c2fb_sqlite3_destructor_type As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_sqlite3_vtab_ As c2fb_sqlite3_vtab
Type c2fb_sqlite3_index_info_ As c2fb_sqlite3_index_info
Type c2fb_sqlite3_vtab_cursor_ As c2fb_sqlite3_vtab_cursor
Type c2fb_sqlite3_mutex_methods_ As c2fb_sqlite3_mutex_methods
Type c2fb_sqlite3_pcache_page_ As c2fb_sqlite3_pcache_page
Type c2fb_sqlite3_pcache_methods2_ As c2fb_sqlite3_pcache_methods2
Type c2fb_sqlite3_pcache_methods_ As c2fb_sqlite3_pcache_methods
Type c2fb_sqlite3_rtree_geometry_ As c2fb_sqlite3_rtree_geometry
Type c2fb_sqlite3_rtree_query_info_ As c2fb_sqlite3_rtree_query_info
Type c2fb_sqlite3_rtree_dbl As Double
Type c2fb_Fts5ExtensionApi_ As c2fb_Fts5ExtensionApi
Type c2fb_Fts5PhraseIter_ As c2fb_Fts5PhraseIter
Type c2fb_fts5_extension_function As Sub CDecl(ByVal arg0 As Const c2fb_Fts5ExtensionApi_ Ptr, ByVal arg1 As c2fb_Fts5Context_ Ptr, ByVal arg2 As c2fb_sqlite3_context_ Ptr, ByVal arg3 As Long, ByVal arg4 As c2fb_sqlite3_value_ Ptr Ptr)
Type c2fb_fts5_tokenizer_v2_ As c2fb_fts5_tokenizer_v2
Type c2fb_fts5_tokenizer_ As c2fb_fts5_tokenizer
Type c2fb_fts5_api_ As c2fb_fts5_api
Type c2fb_sqlite3rbu_ As c2fb_sqlite3rbu
Type c2fb_RbuFrame_ As c2fb_RbuFrame
Type c2fb_RbuObjIter_ As c2fb_RbuObjIter
Type c2fb_RbuState_ As c2fb_RbuState
Type c2fb_RbuSpan_ As c2fb_RbuSpan
Type c2fb_rbu_vfs_ As c2fb_rbu_vfs
Type c2fb_rbu_file_ As c2fb_rbu_file
Type c2fb_RbuUpdateStmt_ As c2fb_RbuUpdateStmt
Type c2fb_u32 As ULong
Type c2fb_u16 As UShort
Type c2fb_u8 As UByte
Type c2fb_i64 As c2fb_sqlite3_int64
Type c2fb_u64 As c2fb_sqlite3_uint64
' c2fb skipped unsupported record declaration/layout: localeinfo_struct
' c2fb skipped unsupported record declaration/layout: tagLC_ID
' c2fb skipped unsupported record declaration/layout: threadlocaleinfostruct
' c2fb skipped unsupported record declaration/layout: _iobuf
Type _c2fb_record_c2fb_sqlite3_file
    pMethods As Const c2fb_sqlite3_io_methods Ptr
End Type

Type _c2fb_record_c2fb_sqlite3_io_methods
    iVersion As Long
    xClose As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr) As Long
    xRead As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_int64) As Long
    xWrite As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_int64) As Long
    xTruncate As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_sqlite3_int64) As Long
    xSync As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Long) As Long
    xFileSize As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_sqlite3_int64 Ptr) As Long
    xLock As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Long) As Long
    xUnlock As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Long) As Long
    xCheckReservedLock As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Long Ptr) As Long
    xFileControl As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long
    xSectorSize As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr) As Long
    xDeviceCharacteristics As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr) As Long
    xShmMap As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Long, ByVal arg4 As Any Ptr Ptr) As Long
    xShmLock As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Long) As Long
    xShmBarrier As Sub CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr)
    xShmUnmap As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Long) As Long
    xFetch As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_sqlite3_int64, ByVal arg2 As Long, ByVal arg3 As Any Ptr Ptr) As Long
    xUnfetch As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_sqlite3_int64, ByVal arg2 As Any Ptr) As Long
End Type

Type _c2fb_record_c2fb_sqlite3_vfs
    iVersion As Long
    szOsFile As Long
    mxPathname As Long
    pNext As c2fb_sqlite3_vfs_ Ptr
    zName As Const ZString Ptr
    pAppData As Any Ptr
    xOpen As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_sqlite3_filename, ByVal arg2 As c2fb_sqlite3_file Ptr, ByVal arg3 As Long, ByVal arg4 As Long Ptr) As Long
    xDelete As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long) As Long
    xAccess As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Long Ptr) As Long
    xFullPathname As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As ZString Ptr) As Long
    xDlOpen As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
    xDlError As Sub CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr)
    xDlSym As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr) As Sub CDecl()
    xDlClose As Sub CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr)
    xRandomness As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr) As Long
    xSleep As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Long) As Long
    xCurrentTime As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Double Ptr) As Long
    xGetLastError As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr) As Long
    xCurrentTimeInt64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_sqlite3_int64 Ptr) As Long
    xSetSystemCall As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_syscall_ptr) As Long
    xGetSystemCall As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_sqlite3_syscall_ptr
    xNextSystemCall As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr) As Const ZString Ptr
End Type

Type _c2fb_record_c2fb_sqlite3_mem_methods
    xMalloc As Function CDecl(ByVal arg0 As Long) As Any Ptr
    xFree As Sub CDecl(ByVal arg0 As Any Ptr)
    xRealloc As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long) As Any Ptr
    xSize As Function CDecl(ByVal arg0 As Any Ptr) As Long
    xRoundup As Function CDecl(ByVal arg0 As Long) As Long
    xInit As Function CDecl(ByVal arg0 As Any Ptr) As Long
    xShutdown As Sub CDecl(ByVal arg0 As Any Ptr)
    pAppData As Any Ptr
End Type

' c2fb skipped unsupported record declaration/layout: sqlite3_module (field xFindFunction)
Type _c2fb_record_c2fb_sqlite3_index_constraint
    iColumn As Long
    op As UByte
    usable As UByte
    iTermOffset As Long
End Type

Type _c2fb_record_c2fb_sqlite3_index_orderby
    iColumn As Long
    desc As UByte
End Type

Type _c2fb_record_c2fb_sqlite3_index_constraint_usage
    argvIndex As Long
    omit As UByte
End Type

Type _c2fb_record_c2fb_sqlite3_index_info
    nConstraint As Long
    aConstraint As c2fb_sqlite3_index_constraint Ptr
    nOrderBy As Long
    aOrderBy As c2fb_sqlite3_index_orderby Ptr
    aConstraintUsage As c2fb_sqlite3_index_constraint_usage Ptr
    idxNum As Long
    idxStr As ZString Ptr
    needToFreeIdxStr As Long
    orderByConsumed As Long
    estimatedCost As Double
    estimatedRows As c2fb_sqlite3_int64
    idxFlags As Long
    colUsed As c2fb_sqlite3_uint64
End Type

Type _c2fb_record_c2fb_sqlite3_vtab
    pModule As Const Any Ptr
    nRef As Long
    zErrMsg As ZString Ptr
End Type

Type _c2fb_record_c2fb_sqlite3_vtab_cursor
    pVtab As c2fb_sqlite3_vtab_ Ptr
End Type

Type _c2fb_record_c2fb_sqlite3_mutex_methods
    xMutexInit As Function CDecl() As Long
    xMutexEnd As Function CDecl() As Long
    xMutexAlloc As Function CDecl(ByVal arg0 As Long) As c2fb_sqlite3_mutex_ Ptr
    xMutexFree As Sub CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr)
    xMutexEnter As Sub CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr)
    xMutexTry As Function CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr) As Long
    xMutexLeave As Sub CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr)
    xMutexHeld As Function CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr) As Long
    xMutexNotheld As Function CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr) As Long
End Type

Type _c2fb_record_c2fb_sqlite3_pcache_page
    pBuf As Any Ptr
    pExtra As Any Ptr
End Type

Type _c2fb_record_c2fb_sqlite3_pcache_methods2
    iVersion As Long
    pArg As Any Ptr
    xInit As Function CDecl(ByVal arg0 As Any Ptr) As Long
    xShutdown As Sub CDecl(ByVal arg0 As Any Ptr)
    xCreate As Function CDecl(ByVal arg0 As Long, ByVal arg1 As Long, ByVal arg2 As Long) As c2fb_sqlite3_pcache_ Ptr
    xCachesize As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As Long)
    xPagecount As Function CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr) As Long
    xFetch As Function CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As ULong, ByVal arg2 As Long) As c2fb_sqlite3_pcache_page_ Ptr
    xUnpin As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As c2fb_sqlite3_pcache_page_ Ptr, ByVal arg2 As Long)
    xRekey As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As c2fb_sqlite3_pcache_page_ Ptr, ByVal arg2 As ULong, ByVal arg3 As ULong)
    xTruncate As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As ULong)
    xDestroy As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr)
    xShrink As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr)
End Type

Type _c2fb_record_c2fb_sqlite3_pcache_methods
    pArg As Any Ptr
    xInit As Function CDecl(ByVal arg0 As Any Ptr) As Long
    xShutdown As Sub CDecl(ByVal arg0 As Any Ptr)
    xCreate As Function CDecl(ByVal arg0 As Long, ByVal arg1 As Long) As c2fb_sqlite3_pcache_ Ptr
    xCachesize As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As Long)
    xPagecount As Function CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr) As Long
    xFetch As Function CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As ULong, ByVal arg2 As Long) As Any Ptr
    xUnpin As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long)
    xRekey As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As ULong, ByVal arg3 As ULong)
    xTruncate As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr, ByVal arg1 As ULong)
    xDestroy As Sub CDecl(ByVal arg0 As c2fb_sqlite3_pcache_ Ptr)
End Type

Type _c2fb_record_c2fb_sqlite3_snapshot
    hidden(0 To 47) As UByte
End Type

Type _c2fb_record_c2fb_sqlite3_rtree_geometry
    pContext As Any Ptr
    nParam As Long
    aParam As c2fb_sqlite3_rtree_dbl Ptr
    pUser As Any Ptr
    xDelUser As Sub CDecl(ByVal arg0 As Any Ptr)
End Type

Type _c2fb_record_c2fb_sqlite3_rtree_query_info
    pContext As Any Ptr
    nParam As Long
    aParam As c2fb_sqlite3_rtree_dbl Ptr
    pUser As Any Ptr
    xDelUser As Sub CDecl(ByVal arg0 As Any Ptr)
    aCoord As c2fb_sqlite3_rtree_dbl Ptr
    anQueue As ULong Ptr
    nCoord As Long
    iLevel As Long
    mxLevel As Long
    iRowid As c2fb_sqlite3_int64
    rParentScore As c2fb_sqlite3_rtree_dbl
    eParentWithin As Long
    eWithin As Long
    rScore As c2fb_sqlite3_rtree_dbl
    apSqlParam As c2fb_sqlite3_value_ Ptr Ptr
End Type

Type _c2fb_record_c2fb_Fts5PhraseIter
    a As Const UByte Ptr
    b As Const UByte Ptr
End Type

Type _c2fb_record_c2fb_Fts5ExtensionApi
    iVersion As Long
    xUserData As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr) As Any Ptr
    xColumnCount As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr) As Long
    xRowCount As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As c2fb_sqlite3_int64 Ptr) As Long
    xColumnTotalSize As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_int64 Ptr) As Long
    xTokenize As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Any Ptr, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long) As Long
    xPhraseCount As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr) As Long
    xPhraseSize As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long) As Long
    xInstCount As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long Ptr) As Long
    xInst As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long Ptr, ByVal arg3 As Long Ptr, ByVal arg4 As Long Ptr) As Long
    xRowid As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr) As c2fb_sqlite3_int64
    xColumnText As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr Ptr, ByVal arg3 As Long Ptr) As Long
    xColumnSize As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long Ptr) As Long
    xQueryPhrase As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Function CDecl(ByVal arg0 As Const c2fb_Fts5ExtensionApi_ Ptr, ByVal arg1 As c2fb_Fts5Context_ Ptr, ByVal arg2 As Any Ptr) As Long) As Long
    xSetAuxdata As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    xGetAuxdata As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long) As Any Ptr
    xPhraseFirst As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_Fts5PhraseIter_ Ptr, ByVal arg3 As Long Ptr, ByVal arg4 As Long Ptr) As Long
    xPhraseNext As Sub CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As c2fb_Fts5PhraseIter_ Ptr, ByVal arg2 As Long Ptr, ByVal arg3 As Long Ptr)
    xPhraseFirstColumn As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_Fts5PhraseIter_ Ptr, ByVal arg3 As Long Ptr) As Long
    xPhraseNextColumn As Sub CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As c2fb_Fts5PhraseIter_ Ptr, ByVal arg2 As Long Ptr)
    xQueryToken As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As Long Ptr) As Long
    xInstToken As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As Long Ptr) As Long
    xColumnLocale As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr Ptr, ByVal arg3 As Long Ptr) As Long
    xTokenize_v2 As Function CDecl(ByVal arg0 As c2fb_Fts5Context_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Long, ByVal arg5 As Any Ptr, ByVal arg6 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long) As Long
End Type

Type _c2fb_record_c2fb_fts5_tokenizer_v2
    iVersion As Long
    xCreate As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Tokenizer_ Ptr Ptr) As Long
    xDelete As Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr)
    xTokenize As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Long, ByVal arg5 As Const ZString Ptr, ByVal arg6 As Long, ByVal arg7 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long) As Long
End Type

Type _c2fb_record_c2fb_fts5_tokenizer
    xCreate As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Tokenizer_ Ptr Ptr) As Long
    xDelete As Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr)
    xTokenize As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Long, ByVal arg5 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long) As Long
End Type

Type _c2fb_record_c2fb_fts5_api
    iVersion As Long
    xCreateTokenizer As Function CDecl(ByVal arg0 As c2fb_fts5_api_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_fts5_tokenizer_ Ptr, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    xFindTokenizer As Function CDecl(ByVal arg0 As c2fb_fts5_api_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_fts5_tokenizer_ Ptr) As Long
    xCreateFunction As Function CDecl(ByVal arg0 As c2fb_fts5_api_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_fts5_extension_function, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    xCreateTokenizer_v2 As Function CDecl(ByVal arg0 As c2fb_fts5_api_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_fts5_tokenizer_v2_ Ptr, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    xFindTokenizer_v2 As Function CDecl(ByVal arg0 As c2fb_fts5_api_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_fts5_tokenizer_v2_ Ptr Ptr) As Long
End Type

Type _c2fb_record_c2fb_RbuState
    eStage As Long
    zTbl As ZString Ptr
    zDataTbl As ZString Ptr
    zIdx As ZString Ptr
    iWalCksum As c2fb_i64
    nRow As Long
    nProgress As c2fb_i64
    iCookie As c2fb_u32
    iOalSz As c2fb_i64
    nPhaseOneStep As c2fb_i64
End Type

Type _c2fb_record_c2fb_RbuUpdateStmt
    zMask As ZString Ptr
    pUpdate As c2fb_sqlite3_stmt_ Ptr
    pNext As c2fb_RbuUpdateStmt_ Ptr
End Type

Type _c2fb_record_c2fb_RbuSpan
    zSpan As Const ZString Ptr
    nSpan As Long
End Type

Type _c2fb_record_c2fb_RbuObjIter
    pTblIter As c2fb_sqlite3_stmt_ Ptr
    pIdxIter As c2fb_sqlite3_stmt_ Ptr
    nTblCol As Long
    azTblCol As ZString Ptr Ptr
    azTblType As ZString Ptr Ptr
    aiSrcOrder As Long Ptr
    abTblPk As c2fb_u8 Ptr
    abNotNull As c2fb_u8 Ptr
    abIndexed As c2fb_u8 Ptr
    eType As Long
    bCleanup As Long
    zTbl As Const ZString Ptr
    zDataTbl As Const ZString Ptr
    zIdx As Const ZString Ptr
    iTnum As Long
    iPkTnum As Long
    bUnique As Long
    nIndex As Long
    nCol As Long
    pSelect As c2fb_sqlite3_stmt_ Ptr
    pInsert As c2fb_sqlite3_stmt_ Ptr
    pDelete As c2fb_sqlite3_stmt_ Ptr
    pTmpInsert As c2fb_sqlite3_stmt_ Ptr
    nIdxCol As Long
    aIdxCol As c2fb_RbuSpan_ Ptr
    zIdxSql As ZString Ptr
    pRbuUpdate As c2fb_RbuUpdateStmt_ Ptr
End Type

Type _c2fb_record_c2fb_RbuFrame
    iDbPage As c2fb_u32
    iWalFrame As c2fb_u32
End Type

Type _c2fb_record_c2fb_sqlite3rbu
    eStage As Long
    dbMain As c2fb_sqlite3_ Ptr
    dbRbu As c2fb_sqlite3_ Ptr
    zTarget As ZString Ptr
    zRbu As ZString Ptr
    zState As ZString Ptr
    zStateDb(0 To 4) As Byte
    rc As Long
    zErrmsg As ZString Ptr
    nStep As Long
    nProgress As c2fb_sqlite3_int64
    objiter As c2fb_RbuObjIter_
    zVfsName As Const ZString Ptr
    pTargetFd As c2fb_rbu_file_ Ptr
    nPagePerSector As Long
    iOalSz As c2fb_i64
    nPhaseOneStep As c2fb_i64
    pRenameArg As Any Ptr
    xRename As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As Long
    iMaxFrame As c2fb_u32
    mLock As c2fb_u32
    nFrame As Long
    nFrameAlloc As Long
    aFrame As c2fb_RbuFrame_ Ptr
    pgsz As Long
    aBuf As c2fb_u8 Ptr
    iWalCksum As c2fb_i64
    szTemp As c2fb_i64
    szTempLimit As c2fb_i64
    nRbu As Long
    pRbuFd As c2fb_rbu_file_ Ptr
End Type

Type _c2fb_record_c2fb_rbu_vfs
    base As c2fb_sqlite3_vfs_
    pRealVfs As c2fb_sqlite3_vfs_ Ptr
    mutex As c2fb_sqlite3_mutex_ Ptr
    pRbu As c2fb_sqlite3rbu_ Ptr
    pMain As c2fb_rbu_file_ Ptr
    pMainRbu As c2fb_rbu_file_ Ptr
End Type

Type _c2fb_record_c2fb_rbu_file
    base As c2fb_sqlite3_file_
    pReal As c2fb_sqlite3_file_ Ptr
    pRbuVfs As c2fb_rbu_vfs_ Ptr
    pRbu As c2fb_sqlite3rbu_ Ptr
    sz As c2fb_i64
    openFlags As Long
    iCookie As c2fb_u32
    iWriteVer As c2fb_u8
    bNolock As c2fb_u8
    nShm As Long
    apShm As ZString Ptr Ptr
    zDel As ZString Ptr
    zWal As Const ZString Ptr
    pWalFd As c2fb_rbu_file_ Ptr
    pMainNext As c2fb_rbu_file_ Ptr
    pMainRbuNext As c2fb_rbu_file_ Ptr
End Type

' c2fb source patterns:
' c2fb emit source matched: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb emit source matched: *
' c2fb forward declaration requests:
' c2fb add-forward-decl matched: *
/' end of sqlite3_rbu_types.bi '/
