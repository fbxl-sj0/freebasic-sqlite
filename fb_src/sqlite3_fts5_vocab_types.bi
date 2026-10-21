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

    File: sqlite3_fts5_vocab_types.bi

    Purpose:

        Describe FTS5 vocabulary cursor and virtual-table record layouts.

    Responsibilities:

        - Preserve the C ABI for vocab tables, cursors, and callbacks.

    This file intentionally does NOT contain:

        - Vocabulary lookup algorithms or module registration.
'/
#ifdef SQLITE_ENABLE_FTS5
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
' User-defined scalar types and by-value records must be declared before generated declarations.
' Source filters and ordered routes apply to declarations, record layouts, macros, inline functions, and library pragmas.
' Types omitted by source filters must be supplied by an earlier declaration, --fb-include, or a preserved C include mapping.
' c2fb excludes requested function, object, or macro: *

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
Type c2fb_sqlite3_api_routines As _c2fb_record_c2fb_sqlite3_api_routines
Type c2fb_sqlite3_api_routines_ As c2fb_sqlite3_api_routines
Type c2fb___locale_struct As _c2fb_record_c2fb___locale_struct
Type c2fb_Fts5TokenizerConfig As _c2fb_record_c2fb_Fts5TokenizerConfig
Type c2fb_Fts5TokenizerConfig_ As c2fb_Fts5TokenizerConfig
Type c2fb_Fts5Config As _c2fb_record_c2fb_Fts5Config
Type c2fb_Fts5Config_ As c2fb_Fts5Config
Type c2fb_Fts5Buffer As _c2fb_record_c2fb_Fts5Buffer
Type c2fb_Fts5Buffer_ As c2fb_Fts5Buffer
Type c2fb_Fts5PoslistReader As _c2fb_record_c2fb_Fts5PoslistReader
Type c2fb_Fts5PoslistReader_ As c2fb_Fts5PoslistReader
Type c2fb_Fts5PoslistWriter As _c2fb_record_c2fb_Fts5PoslistWriter
Type c2fb_Fts5PoslistWriter_ As c2fb_Fts5PoslistWriter
Type c2fb_Fts5IndexIter As _c2fb_record_c2fb_Fts5IndexIter
Type c2fb_Fts5IndexIter_ As c2fb_Fts5IndexIter
Type c2fb_Fts5Table As _c2fb_record_c2fb_Fts5Table
Type c2fb_Fts5Table_ As c2fb_Fts5Table
Type c2fb_Fts5Token As _c2fb_record_c2fb_Fts5Token
Type c2fb_Fts5Token_ As c2fb_Fts5Token
Type c2fb_Fts5VocabTable As _c2fb_record_c2fb_Fts5VocabTable
Type c2fb_Fts5VocabTable_ As c2fb_Fts5VocabTable
Type c2fb_Fts5VocabCursor As _c2fb_record_c2fb_Fts5VocabCursor
Type c2fb_Fts5VocabCursor_ As c2fb_Fts5VocabCursor

Type c2fb_sqlite3 As _c2fb_record_c2fb_sqlite3
Type c2fb_sqlite3_ As c2fb_sqlite3
Type c2fb_sqlite3_mutex As _c2fb_record_c2fb_sqlite3_mutex
Type c2fb_sqlite3_mutex_ As c2fb_sqlite3_mutex
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
Type c2fb_Fts5Global As _c2fb_record_c2fb_Fts5Global
Type c2fb_Fts5Global_ As c2fb_Fts5Global
Type c2fb_Fts5Termset As _c2fb_record_c2fb_Fts5Termset
Type c2fb_Fts5Termset_ As c2fb_Fts5Termset
Type c2fb_Fts5Index As _c2fb_record_c2fb_Fts5Index
Type c2fb_Fts5Index_ As c2fb_Fts5Index
Type c2fb_Fts5Hash As _c2fb_record_c2fb_Fts5Hash
Type c2fb_Fts5Hash_ As c2fb_Fts5Hash
Type c2fb_Fts5Storage As _c2fb_record_c2fb_Fts5Storage
Type c2fb_Fts5Storage_ As c2fb_Fts5Storage
Type c2fb_Fts5Expr As _c2fb_record_c2fb_Fts5Expr
Type c2fb_Fts5Expr_ As c2fb_Fts5Expr
Type c2fb_Fts5ExprNode As _c2fb_record_c2fb_Fts5ExprNode
Type c2fb_Fts5ExprNode_ As c2fb_Fts5ExprNode
Type c2fb_Fts5Parse As _c2fb_record_c2fb_Fts5Parse
Type c2fb_Fts5Parse_ As c2fb_Fts5Parse
Type c2fb_Fts5ExprPhrase As _c2fb_record_c2fb_Fts5ExprPhrase
Type c2fb_Fts5ExprPhrase_ As c2fb_Fts5ExprPhrase
Type c2fb_Fts5ExprNearset As _c2fb_record_c2fb_Fts5ExprNearset
Type c2fb_Fts5ExprNearset_ As c2fb_Fts5ExprNearset
Type c2fb_Fts5PoslistPopulator As _c2fb_record_c2fb_Fts5PoslistPopulator
Type c2fb_Fts5PoslistPopulator_ As c2fb_Fts5PoslistPopulator
Type c2fb_sqlite3_module As _c2fb_record_c2fb_sqlite3_module
Type c2fb_sqlite3_module_ As c2fb_sqlite3_module
Type c2fb_Fts5Colset As _c2fb_record_c2fb_Fts5Colset
Type c2fb_Fts5Colset_ As c2fb_Fts5Colset

Type c2fb___gnuc_va_list As __builtin_va_list
Type c2fb_va_list As c2fb___gnuc_va_list
Type c2fb_sqlite_int64 As LongInt
Type c2fb_sqlite_uint64 As ULongInt
Type c2fb_sqlite3_int64 As c2fb_sqlite_int64
Type c2fb_sqlite3_uint64 As c2fb_sqlite_uint64
Type c2fb_sqlite3_callback As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As Long
Type c2fb_sqlite3_file_ As c2fb_sqlite3_file
Type c2fb_sqlite3_io_methods_ As c2fb_sqlite3_io_methods
Type c2fb_sqlite3_api_routines_ As c2fb_sqlite3_api_routines
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
Type c2fb_sqlite3_loadext_entry As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As Const c2fb_sqlite3_api_routines_ Ptr) As Long
#ifndef __C2FB_ABI_TYPE_SIZE_T__
#define __C2FB_ABI_TYPE_SIZE_T__
Type c2fb_size_t As CULong
#endif
Type c2fb___locale_t As c2fb___locale_struct Ptr
Type c2fb_locale_t As c2fb___locale_t
Type c2fb_ptrdiff_t As CLong
Type c2fb_wchar_t As Long
' c2fb skipped unsupported typedef: typedef __typeof__(nullptr) nullptr_t
Type c2fb_u8 As UByte
Type c2fb_u32 As ULong
Type c2fb_u16 As UShort
Type c2fb_i16 As Short
Type c2fb_i64 As c2fb_sqlite3_int64
Type c2fb_u64 As c2fb_sqlite3_uint64
Type c2fb_Fts5Config_ As c2fb_Fts5Config
Type c2fb_Fts5TokenizerConfig_ As c2fb_Fts5TokenizerConfig
Type c2fb_Fts5Buffer_ As c2fb_Fts5Buffer
Type c2fb_Fts5PoslistReader_ As c2fb_Fts5PoslistReader
Type c2fb_Fts5PoslistWriter_ As c2fb_Fts5PoslistWriter
Type c2fb_Fts5IndexIter_ As c2fb_Fts5IndexIter
Type c2fb_Fts5Table_ As c2fb_Fts5Table
Type c2fb_Fts5Token_ As c2fb_Fts5Token
Type c2fb_Fts5VocabTable_ As c2fb_Fts5VocabTable
Type c2fb_Fts5VocabCursor_ As c2fb_Fts5VocabCursor
Type _c2fb_record_c2fb_sqlite3_file
    pMethods As Const c2fb_sqlite3_io_methods Ptr
End Type

Type _c2fb_record_c2fb_sqlite3_io_methods
    iVersion As Long
    xClose As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr) As Long
    xRead As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_int64) As Long
    xWrite As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_int64) As Long
    xTruncate As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As c2fb_sqlite3_int64) As Long
    xSync As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Long) As Long
    xFileSize As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As c2fb_sqlite3_int64 Ptr) As Long
    xLock As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Long) As Long
    xUnlock As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Long) As Long
    xCheckReservedLock As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Long Ptr) As Long
    xFileControl As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long
    xSectorSize As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr) As Long
    xDeviceCharacteristics As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr) As Long
    xShmMap As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Long, ByVal arg4 As Any Ptr Ptr) As Long
    xShmLock As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Long) As Long
    xShmBarrier As Sub CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr)
    xShmUnmap As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As Long) As Long
    xFetch As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As c2fb_sqlite3_int64, ByVal arg2 As Long, ByVal arg3 As Any Ptr Ptr) As Long
    xUnfetch As Function CDecl(ByVal arg0 As c2fb_sqlite3_file_ Ptr, ByVal arg1 As c2fb_sqlite3_int64, ByVal arg2 As Any Ptr) As Long
End Type

Type _c2fb_record_c2fb_sqlite3_vfs
    iVersion As Long
    szOsFile As Long
    mxPathname As Long
    pNext As c2fb_sqlite3_vfs_ Ptr
    zName As Const ZString Ptr
    pAppData As Any Ptr
    xOpen As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As c2fb_sqlite3_filename, ByVal arg2 As c2fb_sqlite3_file_ Ptr, ByVal arg3 As Long, ByVal arg4 As Long Ptr) As Long
    xDelete As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long) As Long
    xAccess As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Long Ptr) As Long
    xFullPathname As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As ZString Ptr) As Long
    xDlOpen As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
    xDlError As Sub CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr)
    xDlSym As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr) As Sub CDecl()
    xDlClose As Sub CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Any Ptr)
    xRandomness As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr) As Long
    xSleep As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Long) As Long
    xCurrentTime As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Double Ptr) As Long
    xGetLastError As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr) As Long
    xCurrentTimeInt64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As c2fb_sqlite3_int64 Ptr) As Long
    xSetSystemCall As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_syscall_ptr) As Long
    xGetSystemCall As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_sqlite3_syscall_ptr
    xNextSystemCall As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Const ZString Ptr) As Const ZString Ptr
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

Type _c2fb_record_c2fb_sqlite3_api_routines
    aggregate_context As Function CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long) As Any Ptr
    aggregate_count As Function CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr) As Long
    bind_blob As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const Any Ptr, ByVal arg3 As Long, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    bind_double As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Double) As Long
    bind_int As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long) As Long
    bind_int64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite_int64) As Long
    bind_null As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Long
    bind_parameter_count As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    bind_parameter_index As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Const ZString Ptr) As Long
    bind_parameter_name As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const ZString Ptr
    bind_text As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    bind_text16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const Any Ptr, ByVal arg3 As Long, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    bind_value As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const c2fb_sqlite3_value_ Ptr) As Long
    busy_handler As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long) As Long, ByVal arg2 As Any Ptr) As Long
    busy_timeout As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long) As Long
    changes As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    close As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    collation_needed As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Sub CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_sqlite3_ Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr)) As Long
    collation_needed16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Sub CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_sqlite3_ Ptr, ByVal arg2 As Long, ByVal arg3 As Const Any Ptr)) As Long
    column_blob As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const Any Ptr
    column_bytes As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Long
    column_bytes16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Long
    column_count As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    column_database_name As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const ZString Ptr
    column_database_name16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const Any Ptr
    column_decltype As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const ZString Ptr
    column_decltype16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const Any Ptr
    column_double As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Double
    column_int As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Long
    column_int64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As c2fb_sqlite_int64
    column_name As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const ZString Ptr
    column_name16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const Any Ptr
    column_origin_name As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const ZString Ptr
    column_origin_name16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const Any Ptr
    column_table_name As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const ZString Ptr
    column_table_name16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const Any Ptr
    column_text As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const UByte Ptr
    column_text16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Const Any Ptr
    column_type As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Long
    column_value As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As c2fb_sqlite3_value_ Ptr
    commit_hook As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr) As Long, ByVal arg2 As Any Ptr) As Any Ptr
    complete As Function CDecl(ByVal arg0 As Const ZString Ptr) As Long
    complete16 As Function CDecl(ByVal arg0 As Const Any Ptr) As Long
    create_collation As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Any Ptr, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const Any Ptr, ByVal arg3 As Long, ByVal arg4 As Const Any Ptr) As Long) As Long
    create_collation16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As Any Ptr, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const Any Ptr, ByVal arg3 As Long, ByVal arg4 As Const Any Ptr) As Long) As Long
    create_function As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Long, ByVal arg4 As Any Ptr, ByVal arg5 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr), ByVal arg6 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr), ByVal arg7 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr)) As Long
    create_function16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As Long, ByVal arg4 As Any Ptr, ByVal arg5 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr), ByVal arg6 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr), ByVal arg7 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr)) As Long
    create_module As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const Any Ptr, ByVal arg3 As Any Ptr) As Long
    data_count As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    db_handle As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As c2fb_sqlite3_ Ptr
    declare_vtab As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr) As Long
    enable_shared_cache As Function CDecl(ByVal arg0 As Long) As Long
    errcode As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    errmsg As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Const ZString Ptr
    errmsg16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Const Any Ptr
    exec As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_callback, ByVal arg3 As Any Ptr, ByVal arg4 As ZString Ptr Ptr) As Long
    expired As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    finalize As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    free As Sub CDecl(ByVal arg0 As Any Ptr)
    free_table As Sub CDecl(ByVal arg0 As ZString Ptr Ptr)
    get_autocommit As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    get_auxdata As Function CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long) As Any Ptr
    get_table As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As ZString Ptr Ptr Ptr, ByVal arg3 As Long Ptr, ByVal arg4 As Long Ptr, ByVal arg5 As ZString Ptr Ptr) As Long
    global_recover As Function CDecl() As Long
    interruptx As Sub CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr)
    last_insert_rowid As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As c2fb_sqlite_int64
    libversion As Function CDecl() As Const ZString Ptr
    libversion_number As Function CDecl() As Long
    malloc As Function CDecl(ByVal arg0 As Long) As Any Ptr
    mprintf As Function CDecl(ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
    open As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_sqlite3_ Ptr Ptr) As Long
    open16 As Function CDecl(ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_sqlite3_ Ptr Ptr) As Long
    prepare As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_stmt_ Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As Long
    prepare16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_stmt_ Ptr Ptr, ByVal arg4 As Const Any Ptr Ptr) As Long
    profile As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Sub CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite_uint64), ByVal arg2 As Any Ptr) As Any Ptr
    progress_handler As Sub CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long, ByVal arg2 As Function CDecl(ByVal arg0 As Any Ptr) As Long, ByVal arg3 As Any Ptr)
    realloc As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long) As Any Ptr
    reset As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    result_blob As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr))
    result_double As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Double)
    result_error As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long)
    result_error16 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long)
    result_int As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long)
    result_int64 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As c2fb_sqlite_int64)
    result_null As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr)
    result_text As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr))
    result_text16 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr))
    result_text16be As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr))
    result_text16le As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr))
    result_value As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As c2fb_sqlite3_value_ Ptr)
    rollback_hook As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Sub CDecl(ByVal arg0 As Any Ptr), ByVal arg2 As Any Ptr) As Any Ptr
    set_authorizer As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As Const ZString Ptr) As Long, ByVal arg2 As Any Ptr) As Long
    set_auxdata As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr))
    xsnprintf As Function CDecl(ByVal arg0 As Long, ByVal arg1 As ZString Ptr, ByVal arg2 As Const ZString Ptr, ...) As ZString Ptr
    step As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    table_column_metadata As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr, ByVal arg6 As Long Ptr, ByVal arg7 As Long Ptr, ByVal arg8 As Long Ptr) As Long
    thread_cleanup As Sub CDecl()
    total_changes As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    trace As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Sub CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr), ByVal arg2 As Any Ptr) As Any Ptr
    transfer_bindings As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As c2fb_sqlite3_stmt_ Ptr) As Long
    update_hook As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Sub CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_sqlite_int64), ByVal arg2 As Any Ptr) As Any Ptr
    user_data As Function CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr) As Any Ptr
    value_blob As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Const Any Ptr
    value_bytes As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Long
    value_bytes16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Long
    value_double As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Double
    value_int As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Long
    value_int64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As c2fb_sqlite_int64
    value_numeric_type As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Long
    value_text As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Const UByte Ptr
    value_text16 As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Const Any Ptr
    value_text16be As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Const Any Ptr
    value_text16le As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Const Any Ptr
    value_type As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Long
    vmprintf As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
    overload_function As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long) As Long
    prepare_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_stmt_ Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As Long
    prepare16_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_stmt_ Ptr Ptr, ByVal arg4 As Const Any Ptr Ptr) As Long
    clear_bindings As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    create_module_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const Any Ptr, ByVal arg3 As Any Ptr, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    bind_zeroblob As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long) As Long
    blob_bytes As Function CDecl(ByVal arg0 As c2fb_sqlite3_blob_ Ptr) As Long
    blob_close As Function CDecl(ByVal arg0 As c2fb_sqlite3_blob_ Ptr) As Long
    blob_open As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_sqlite3_int64, ByVal arg5 As Long, ByVal arg6 As c2fb_sqlite3_blob_ Ptr Ptr) As Long
    blob_read As Function CDecl(ByVal arg0 As c2fb_sqlite3_blob_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As Long) As Long
    blob_write As Function CDecl(ByVal arg0 As c2fb_sqlite3_blob_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As Long) As Long
    create_collation_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Any Ptr, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const Any Ptr, ByVal arg3 As Long, ByVal arg4 As Const Any Ptr) As Long, ByVal arg5 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    file_control As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Any Ptr) As Long
    memory_highwater As Function CDecl(ByVal arg0 As Long) As c2fb_sqlite3_int64
    memory_used As Function CDecl() As c2fb_sqlite3_int64
    mutex_alloc As Function CDecl(ByVal arg0 As Long) As c2fb_sqlite3_mutex_ Ptr
    mutex_enter As Sub CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr)
    mutex_free As Sub CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr)
    mutex_leave As Sub CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr)
    mutex_try As Function CDecl(ByVal arg0 As c2fb_sqlite3_mutex_ Ptr) As Long
    open_v2 As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_sqlite3_ Ptr Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr) As Long
    release_memory As Function CDecl(ByVal arg0 As Long) As Long
    result_error_nomem As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr)
    result_error_toobig As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr)
    sleep As Function CDecl(ByVal arg0 As Long) As Long
    soft_heap_limit As Sub CDecl(ByVal arg0 As Long)
    vfs_find As Function CDecl(ByVal arg0 As Const ZString Ptr) As c2fb_sqlite3_vfs_ Ptr
    vfs_register As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr, ByVal arg1 As Long) As Long
    vfs_unregister As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs_ Ptr) As Long
    xthreadsafe As Function CDecl() As Long
    result_zeroblob As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long)
    result_error_code As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long)
    test_control As Function CDecl(ByVal arg0 As Long, ...) As Long
    randomness As Sub CDecl(ByVal arg0 As Long, ByVal arg1 As Any Ptr)
    context_db_handle As Function CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr) As c2fb_sqlite3_ Ptr
    extended_result_codes As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long) As Long
    limit As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long) As Long
    next_stmt As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As c2fb_sqlite3_stmt_ Ptr) As c2fb_sqlite3_stmt_ Ptr
    sql As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Const ZString Ptr
    status As Function CDecl(ByVal arg0 As Long, ByVal arg1 As Long Ptr, ByVal arg2 As Long Ptr, ByVal arg3 As Long) As Long
    backup_finish As Function CDecl(ByVal arg0 As c2fb_sqlite3_backup_ Ptr) As Long
    backup_init As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_ Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_sqlite3_backup_ Ptr
    backup_pagecount As Function CDecl(ByVal arg0 As c2fb_sqlite3_backup_ Ptr) As Long
    backup_remaining As Function CDecl(ByVal arg0 As c2fb_sqlite3_backup_ Ptr) As Long
    backup_step As Function CDecl(ByVal arg0 As c2fb_sqlite3_backup_ Ptr, ByVal arg1 As Long) As Long
    compileoption_get As Function CDecl(ByVal arg0 As Long) As Const ZString Ptr
    compileoption_used As Function CDecl(ByVal arg0 As Const ZString Ptr) As Long
    create_function_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Long, ByVal arg4 As Any Ptr, ByVal arg5 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr), ByVal arg6 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr), ByVal arg7 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr), ByVal arg8 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    db_config As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long, ...) As Long
    db_mutex As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As c2fb_sqlite3_mutex_ Ptr
    db_status As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long Ptr, ByVal arg3 As Long Ptr, ByVal arg4 As Long) As Long
    extended_errcode As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    log As Sub CDecl(ByVal arg0 As Long, ByVal arg1 As Const ZString Ptr, ...)
    soft_heap_limit64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_int64) As c2fb_sqlite3_int64
    sourceid As Function CDecl() As Const ZString Ptr
    stmt_status As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long) As Long
    strnicmp As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long) As Long
    unlock_notify As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Sub CDecl(ByVal arg0 As Any Ptr Ptr, ByVal arg1 As Long), ByVal arg2 As Any Ptr) As Long
    wal_autocheckpoint As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long) As Long
    wal_checkpoint As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr) As Long
    wal_hook As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_sqlite3_ Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long) As Long, ByVal arg2 As Any Ptr) As Any Ptr
    blob_reopen As Function CDecl(ByVal arg0 As c2fb_sqlite3_blob_ Ptr, ByVal arg1 As c2fb_sqlite3_int64) As Long
    vtab_config As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long, ...) As Long
    vtab_on_conflict As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    close_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    db_filename As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr) As Const ZString Ptr
    db_readonly As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr) As Long
    db_release_memory As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    errstr As Function CDecl(ByVal arg0 As Long) As Const ZString Ptr
    stmt_busy As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    stmt_readonly As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    stricmp As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As Long
    uri_boolean As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long) As Long
    uri_int64 As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_int64) As c2fb_sqlite3_int64
    uri_parameter As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As Const ZString Ptr
    xvsnprintf As Function CDecl(ByVal arg0 As Long, ByVal arg1 As ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Cva_List) As ZString Ptr
    wal_checkpoint_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Long Ptr, ByVal arg4 As Long Ptr) As Long
    auto_extension As Function CDecl(ByVal arg0 As Sub CDecl()) As Long
    bind_blob64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_sqlite3_uint64, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    bind_text64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_sqlite3_uint64, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr), ByVal arg5 As UByte) As Long
    cancel_auto_extension As Function CDecl(ByVal arg0 As Sub CDecl()) As Long
    load_extension As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As ZString Ptr Ptr) As Long
    malloc64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_uint64) As Any Ptr
    msize As Function CDecl(ByVal arg0 As Any Ptr) As c2fb_sqlite3_uint64
    realloc64 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_sqlite3_uint64) As Any Ptr
    reset_auto_extension As Sub CDecl()
    result_blob64 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_sqlite3_uint64, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr))
    result_text64 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_uint64, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr), ByVal arg4 As UByte)
    strglob As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As Long
    value_dup As Function CDecl(ByVal arg0 As Const c2fb_sqlite3_value_ Ptr) As c2fb_sqlite3_value_ Ptr
    value_free As Sub CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr)
    result_zeroblob64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As c2fb_sqlite3_uint64) As Long
    bind_zeroblob64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_uint64) As Long
    value_subtype As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As ULong
    result_subtype As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As ULong)
    status64 As Function CDecl(ByVal arg0 As Long, ByVal arg1 As c2fb_sqlite3_int64 Ptr, ByVal arg2 As c2fb_sqlite3_int64 Ptr, ByVal arg3 As Long) As Long
    strlike As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As ULong) As Long
    db_cacheflush As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    system_errno As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    trace_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As ULong, ByVal arg2 As Function CDecl(ByVal arg0 As ULong, ByVal arg1 As Any Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As Any Ptr) As Long, ByVal arg3 As Any Ptr) As Long
    expanded_sql As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As ZString Ptr
    set_last_insert_rowid As Sub CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As c2fb_sqlite3_int64)
    prepare_v3 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As ULong, ByVal arg4 As c2fb_sqlite3_stmt_ Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr) As Long
    prepare16_v3 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long, ByVal arg3 As ULong, ByVal arg4 As c2fb_sqlite3_stmt_ Ptr Ptr, ByVal arg5 As Const Any Ptr Ptr) As Long
    bind_pointer As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    result_pointer As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr))
    value_pointer As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
    vtab_nochange As Function CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr) As Long
    value_nochange As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Long
    vtab_collation As Function CDecl(ByVal arg0 As c2fb_sqlite3_index_info_ Ptr, ByVal arg1 As Long) As Const ZString Ptr
    keyword_count As Function CDecl() As Long
    keyword_name As Function CDecl(ByVal arg0 As Long, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Long Ptr) As Long
    keyword_check As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Long) As Long
    str_new As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As c2fb_sqlite3_str_ Ptr
    str_finish As Function CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr) As ZString Ptr
    str_appendf As Sub CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr, ByVal arg1 As Const ZString Ptr, ...)
    str_vappendf As Sub CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Cva_List)
    str_append As Sub CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long)
    str_appendall As Sub CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr, ByVal arg1 As Const ZString Ptr)
    str_appendchar As Sub CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr, ByVal arg1 As Long, ByVal arg2 As Byte)
    str_reset As Sub CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr)
    str_errcode As Function CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr) As Long
    str_length As Function CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr) As Long
    str_value As Function CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr) As ZString Ptr
    create_window_function As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Long, ByVal arg3 As Long, ByVal arg4 As Any Ptr, ByVal arg5 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr), ByVal arg6 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr), ByVal arg7 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr), ByVal arg8 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr), ByVal arg9 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    normalized_sql As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Const ZString Ptr
    stmt_isexplain As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr) As Long
    value_frombind As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Long
    drop_modules As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr Ptr) As Long
    hard_heap_limit64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_int64) As c2fb_sqlite3_int64
    uri_key As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Long) As Const ZString Ptr
    filename_database As Function CDecl(ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
    filename_journal As Function CDecl(ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
    filename_wal As Function CDecl(ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
    create_filename As Function CDecl(ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Const ZString Ptr Ptr) As Const ZString Ptr
    free_filename As Sub CDecl(ByVal arg0 As Const ZString Ptr)
    database_file_object As Function CDecl(ByVal arg0 As Const ZString Ptr) As c2fb_sqlite3_file_ Ptr
    txn_state As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr) As Long
    changes64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As c2fb_sqlite3_int64
    total_changes64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As c2fb_sqlite3_int64
    autovacuum_pages As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As ULong, ByVal arg3 As ULong, ByVal arg4 As ULong) As ULong, ByVal arg2 As Any Ptr, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    error_offset As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    vtab_rhs_value As Function CDecl(ByVal arg0 As c2fb_sqlite3_index_info_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_value_ Ptr Ptr) As Long
    vtab_distinct As Function CDecl(ByVal arg0 As c2fb_sqlite3_index_info_ Ptr) As Long
    vtab_in As Function CDecl(ByVal arg0 As c2fb_sqlite3_index_info_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long) As Long
    vtab_in_first As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr, ByVal arg1 As c2fb_sqlite3_value_ Ptr Ptr) As Long
    vtab_in_next As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr, ByVal arg1 As c2fb_sqlite3_value_ Ptr Ptr) As Long
    deserialize As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_sqlite3_int64, ByVal arg4 As c2fb_sqlite3_int64, ByVal arg5 As ULong) As Long
    serialize As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_int64 Ptr, ByVal arg3 As ULong) As UByte Ptr
    db_name As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long) As Const ZString Ptr
    value_encoding As Function CDecl(ByVal arg0 As c2fb_sqlite3_value_ Ptr) As Long
    is_interrupted As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr) As Long
    stmt_explain As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long) As Long
    get_clientdata As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
    set_clientdata As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    setlk_timeout As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long, ByVal arg2 As Long) As Long
    set_errmsg As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr) As Long
    db_status64 As Function CDecl(ByVal arg0 As c2fb_sqlite3_ Ptr, ByVal arg1 As Long, ByVal arg2 As c2fb_sqlite3_int64 Ptr, ByVal arg3 As c2fb_sqlite3_int64 Ptr, ByVal arg4 As Long) As Long
    str_truncate As Sub CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr, ByVal arg1 As Long)
    str_free As Sub CDecl(ByVal arg0 As c2fb_sqlite3_str_ Ptr)
    carray_bind As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Sub CDecl(ByVal arg0 As Any Ptr)) As Long
    carray_bind_v2 As Function CDecl(ByVal arg0 As c2fb_sqlite3_stmt_ Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Sub CDecl(ByVal arg0 As Any Ptr), ByVal arg6 As Any Ptr) As Long
    incomplete As Function CDecl(ByVal arg0 As Const ZString Ptr) As c2fb_sqlite3_int64
    result_str As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context_ Ptr, ByVal arg1 As c2fb_sqlite3_str_ Ptr, ByVal arg2 As Long)
End Type

Type _c2fb_record_c2fb___locale_struct
    __locales(0 To 12) As Any Ptr
    __ctype_b As Const UShort Ptr
    __ctype_tolower As Const Long Ptr
    __ctype_toupper As Const Long Ptr
    __names(0 To 12) As Any Ptr
End Type

' c2fb skipped unsupported record declaration/layout: max_align_t
' c2fb skipped unsupported record declaration/layout: Fts5Colset (field aiCol)
Type _c2fb_record_c2fb_Fts5TokenizerConfig
    pTok As c2fb_Fts5Tokenizer_ Ptr
    pApi2 As c2fb_fts5_tokenizer_v2_ Ptr
    pApi1 As c2fb_fts5_tokenizer_ Ptr
    azArg As Const ZString Ptr Ptr
    nArg As Long
    ePattern As Long
    pLocale As Const ZString Ptr
    nLocale As Long
End Type

Type _c2fb_record_c2fb_Fts5Config
    db As c2fb_sqlite3_ Ptr
    pGlobal As c2fb_Fts5Global_ Ptr
    zDb As ZString Ptr
    zName As ZString Ptr
    nCol As Long
    azCol As ZString Ptr Ptr
    abUnindexed As c2fb_u8 Ptr
    nPrefix As Long
    aPrefix As Long Ptr
    eContent As Long
    bContentlessDelete As Long
    bContentlessUnindexed As Long
    zContent As ZString Ptr
    zContentRowid As ZString Ptr
    bColumnsize As Long
    bTokendata As Long
    bLocale As Long
    eDetail As Long
    zContentExprlist As ZString Ptr
    t As c2fb_Fts5TokenizerConfig_
    bLock As Long
    iVersion As Long
    iCookie As Long
    pgsz As Long
    nAutomerge As Long
    nCrisisMerge As Long
    nUsermerge As Long
    nHashSize As Long
    zRank As ZString Ptr
    zRankArgs As ZString Ptr
    bSecureDelete As Long
    nDeleteMerge As Long
    bPrefixInsttoken As Long
    pzErrmsg As ZString Ptr Ptr
#ifdef SQLITE_DEBUG
    ' FTS5 debug prefix-index selector; it is absent from release layouts.
    bPrefixIndex As Long
#endif
End Type

Type _c2fb_record_c2fb_Fts5Buffer
    p As c2fb_u8 Ptr
    n As Long
    nSpace As Long
End Type

Type _c2fb_record_c2fb_Fts5PoslistReader
    a As Const c2fb_u8 Ptr
    n As Long
    i As Long
    bFlag As c2fb_u8
    bEof As c2fb_u8
    iPos As c2fb_i64
End Type

Type _c2fb_record_c2fb_Fts5PoslistWriter
    iPrev As c2fb_i64
End Type

Type _c2fb_record_c2fb_Fts5IndexIter
    iRowid As c2fb_i64
    pData As Const c2fb_u8 Ptr
    nData As Long
    bEof As c2fb_u8
End Type

Type _c2fb_record_c2fb_Fts5Table
    base As c2fb_sqlite3_vtab_
    pConfig As c2fb_Fts5Config_ Ptr
    pIndex As c2fb_Fts5Index_ Ptr
End Type

Type _c2fb_record_c2fb_Fts5Token
    p As Const ZString Ptr
    n As Long
End Type

Type _c2fb_record_c2fb_Fts5VocabTable
    base As c2fb_sqlite3_vtab_
    zFts5Tbl As ZString Ptr
    zFts5Db As ZString Ptr
    db As c2fb_sqlite3_ Ptr
    pGlobal As c2fb_Fts5Global_ Ptr
    eType As Long
    bBusy As ULong
End Type

Type _c2fb_record_c2fb_Fts5VocabCursor
    base As c2fb_sqlite3_vtab_cursor_
    pStmt As c2fb_sqlite3_stmt_ Ptr
    pFts5 As c2fb_Fts5Table_ Ptr
    bEof As Long
    pIter As c2fb_Fts5IndexIter_ Ptr
    pStruct As Any Ptr
    nLeTerm As Long
    zLeTerm As ZString Ptr
    colUsed As Long
    iCol As Long
    aCnt As c2fb_i64 Ptr
    aDoc As c2fb_i64 Ptr
    rowid As c2fb_i64
    term As c2fb_Fts5Buffer_
    iInstPos As c2fb_i64
    iInstOff As Long
End Type

' c2fb source patterns:
' c2fb emit source matched: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_vocab.c
' c2fb emit source matched: *
' c2fb forward declaration requests:
' c2fb add-forward-decl matched: *
#endif
/' end of sqlite3_fts5_vocab_types.bi '/
