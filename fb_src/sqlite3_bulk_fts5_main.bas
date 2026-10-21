/'
** 2014 Jun 09
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

    File: sqlite3_bulk_fts5_main.bas

    Purpose:

        Port FTS5 virtual-table callbacks, cursor operations, and extension APIs.

    Responsibilities:

        - Manage FTS5 table and cursor callbacks.
        - Expose auxiliary-function and tokenizer registration APIs.
        - Handle FTS5 transaction, locale, and query-result operations.

    This file intentionally does NOT contain:

        - FTS5 index storage or query parsing algorithms.
        - The upstream Tcl test adapter.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_main_types.bi"
#include once "sqlite3_fts5_module_types.bi"
#include once "sqlite3_api_constants.bi"

#ifndef FTS5_PLAN_MATCH
#define FTS5_PLAN_MATCH 1
#define FTS5_PLAN_SOURCE 2
#define FTS5_PLAN_SPECIAL 3
#define FTS5_PLAN_SORTED_MATCH 4
#define FTS5_PLAN_SCAN 5
#define FTS5_PLAN_ROWID 6
#endif

#ifndef FTS5_DETAIL_FULL
#define FTS5_DETAIL_FULL 0
#define FTS5_DETAIL_COLUMNS 2
#define FTS5_DETAIL_NONE 1
#endif

#ifndef FTS5CSR_EOF
#define FTS5CSR_EOF 1
#define FTS5CSR_REQUIRE_CONTENT 2
#define FTS5CSR_REQUIRE_DOCSIZE 4
#define FTS5CSR_REQUIRE_INST 8
#define FTS5CSR_FREE_ZRANK 16
#define FTS5CSR_REQUIRE_RESEEK 32
#define FTS5CSR_REQUIRE_POSLIST 64
#endif

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
Type c2fb_fts5_extension_function As Sub CDecl(ByVal arg0 As Const c2fb_Fts5ExtensionApi_ Ptr, ByVal arg1 As c2fb_Fts5Context_ Ptr, ByVal arg2 As c2fb_sqlite3_context_ Ptr, ByVal arg3 As Long, ByVal arg4 As c2fb_sqlite3_value_ Ptr Ptr)
Type c2fb_callback_6 As Sub CDecl(ByVal arg0 As Const c2fb_Fts5ExtensionApi Ptr, ByVal arg1 As c2fb_Fts5Context Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
Type c2fb_callback_fts5_query_phrase As Function CDecl(ByVal arg0 As Const c2fb_Fts5ExtensionApi_ Ptr, ByVal arg1 As c2fb_Fts5Context_ Ptr, ByVal arg2 As Any Ptr) As c2fb_c_int
Type c2fb_callback_7 As Function CDecl(ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As Const c2fb_sqlite3_api_routines Ptr) As c2fb_c_int
Type c2fb_callback_9 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Type c2fb_callback_73 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_91 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
Type c2fb_callback_92 As Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
Type c2fb_callback_93 As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_callback_73) As c2fb_c_int
Type c2fb_callback_94 As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_73) As c2fb_c_int

#ifdef SQLITE_DEBUG
/' ------------------------------------------------------------------------- '/
/' FTS5 corruption-test assertion state                                      '/
/' ------------------------------------------------------------------------- '/

' FTS5 corruption tests toggle this flag to distinguish assumptions that are
' valid only for a known-good database from checks required for corrupt input.
Extern sqlite3_fts5_may_be_corrupt Alias "sqlite3_fts5_may_be_corrupt" As c2fb_c_int
Dim Shared sqlite3_fts5_may_be_corrupt As c2fb_c_int = 1
#endif

#ifdef SQLITE_DEBUG
Private Sub fts5MainAssert(ByVal bCondition As c2fb_c_int, ByVal zExpression As Const ZString Ptr)
    If bCondition = 0 Then sqlite3DebugAssert(zExpression)
End Sub
#endif

Private Function __c2fb_double_value(ByVal value As Double) As Double
    Return value
End Function
Declare Function fts5IsContentless CDecl Alias "fts5IsContentless" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5FreeVtab CDecl Alias "fts5FreeVtab" (ByVal arg0 As c2fb_Fts5FullTable Ptr)
Declare Function fts5DisconnectMethod CDecl Alias "fts5DisconnectMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5DestroyMethod CDecl Alias "fts5DestroyMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5InitVtab CDecl Alias "fts5InitVtab" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg6 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5ConnectMethod CDecl Alias "fts5ConnectMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5CreateMethod CDecl Alias "fts5CreateMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub fts5SetUniqueFlag CDecl Alias "fts5SetUniqueFlag" (ByVal arg0 As c2fb_sqlite3_index_info Ptr)
Declare Sub fts5SetEstimatedRows CDecl Alias "fts5SetEstimatedRows" (ByVal arg0 As c2fb_sqlite3_index_info Ptr, ByVal arg1 As c2fb_int64)
Declare Function fts5UsePatternMatch CDecl Alias "fts5UsePatternMatch" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_index_constraint Ptr) As c2fb_c_int
Declare Function fts5BestIndexMethod CDecl Alias "fts5BestIndexMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_index_info Ptr) As c2fb_c_int
Declare Function fts5NewTransaction CDecl Alias "fts5NewTransaction" (ByVal arg0 As c2fb_Fts5FullTable Ptr) As c2fb_c_int
Declare Function fts5OpenMethod CDecl Alias "fts5OpenMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_vtab_cursor Ptr Ptr) As c2fb_c_int
Declare Function fts5StmtType CDecl Alias "fts5StmtType" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
Declare Sub fts5CsrNewrow CDecl Alias "fts5CsrNewrow" (ByVal arg0 As c2fb_Fts5Cursor Ptr)
Declare Sub fts5FreeCursorComponents CDecl Alias "fts5FreeCursorComponents" (ByVal arg0 As c2fb_Fts5Cursor Ptr)
Declare Function fts5CloseMethod CDecl Alias "fts5CloseMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5SorterNext CDecl Alias "fts5SorterNext" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
Declare Sub fts5TripCursors CDecl Alias "fts5TripCursors" (ByVal arg0 As c2fb_Fts5FullTable Ptr)
Declare Function fts5CursorReseek CDecl Alias "fts5CursorReseek" (ByVal arg0 As c2fb_Fts5Cursor Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5NextMethod CDecl Alias "fts5NextMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5PrepareStatement CDecl Alias "fts5PrepareStatement" (ByVal arg0 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg1 As c2fb_Fts5Config Ptr, ByVal arg2 As Const ZString Ptr, ...) As c2fb_c_int
Declare Function fts5CursorFirstSorted CDecl Alias "fts5CursorFirstSorted" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5CursorFirst CDecl Alias "fts5CursorFirst" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5SpecialMatch CDecl Alias "fts5SpecialMatch" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
Declare Function fts5FindAuxiliary CDecl Alias "fts5FindAuxiliary" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_Fts5Auxiliary Ptr
Declare Function fts5FindRankFunction CDecl Alias "fts5FindRankFunction" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
Declare Function fts5CursorParseRank CDecl Alias "fts5CursorParseRank" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function fts5GetRowidLimit CDecl Alias "fts5GetRowidLimit" (ByVal arg0 As c2fb_sqlite3_value Ptr, ByVal arg1 As c2fb_int64) As c2fb_int64
Declare Sub fts5SetVtabError CDecl Alias "fts5SetVtabError" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub sqlite3Fts5SetLocale CDecl Alias "sqlite3Fts5SetLocale" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub sqlite3Fts5ClearLocale CDecl Alias "sqlite3Fts5ClearLocale" (ByVal arg0 As c2fb_Fts5Config Ptr)
Declare Function sqlite3Fts5IsLocaleValue CDecl Alias "sqlite3Fts5IsLocaleValue" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function sqlite3Fts5DecodeLocaleValue CDecl Alias "sqlite3Fts5DecodeLocaleValue" (ByVal arg0 As c2fb_sqlite3_value Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ExtractExprText CDecl Alias "fts5ExtractExprText" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5FilterMethod CDecl Alias "fts5FilterMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
Declare Function fts5EofMethod CDecl Alias "fts5EofMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5CursorRowid CDecl Alias "fts5CursorRowid" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_int64
Declare Function fts5RowidMethod CDecl Alias "fts5RowidMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts5SeekCursor CDecl Alias "fts5SeekCursor" (ByVal arg0 As c2fb_Fts5Cursor Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5SpecialInsert CDecl Alias "fts5SpecialInsert" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function fts5SpecialDelete CDecl Alias "fts5SpecialDelete" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
Declare Sub fts5StorageInsert CDecl Alias "fts5StorageInsert" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5FullTable Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr)
Declare Function fts5ContentlessUpdate CDecl Alias "fts5ContentlessUpdate" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5UpdateMethod CDecl Alias "fts5UpdateMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts5SyncMethod CDecl Alias "fts5SyncMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5BeginMethod CDecl Alias "fts5BeginMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5CommitMethod CDecl Alias "fts5CommitMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5RollbackMethod CDecl Alias "fts5RollbackMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5ApiUserData CDecl Alias "fts5ApiUserData" (ByVal arg0 As c2fb_Fts5Context Ptr) As Any Ptr
Declare Function fts5ApiColumnCount CDecl Alias "fts5ApiColumnCount" (ByVal arg0 As c2fb_Fts5Context Ptr) As c2fb_c_int
Declare Function fts5ApiColumnTotalSize CDecl Alias "fts5ApiColumnTotalSize" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts5ApiRowCount CDecl Alias "fts5ApiRowCount" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts5ApiTokenize_v2 CDecl Alias "fts5ApiTokenize_v2" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Any Ptr, ByVal arg6 As c2fb_callback_73) As c2fb_c_int
Declare Function fts5ApiTokenize CDecl Alias "fts5ApiTokenize" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_callback_73) As c2fb_c_int
Declare Function fts5ApiPhraseCount CDecl Alias "fts5ApiPhraseCount" (ByVal arg0 As c2fb_Fts5Context Ptr) As c2fb_c_int
Declare Function fts5ApiPhraseSize CDecl Alias "fts5ApiPhraseSize" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5TextFromStmt CDecl Alias "fts5TextFromStmt" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ApiColumnText CDecl Alias "fts5ApiColumnText" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5CsrPoslist CDecl Alias "fts5CsrPoslist" (ByVal arg0 As c2fb_Fts5Cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5CacheInstArray CDecl Alias "fts5CacheInstArray" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
Declare Function fts5ApiInstCount CDecl Alias "fts5ApiInstCount" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ApiInst CDecl Alias "fts5ApiInst" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ApiRowid CDecl Alias "fts5ApiRowid" (ByVal arg0 As c2fb_Fts5Context Ptr) As c2fb_int64
Declare Function fts5ColumnSizeCb CDecl Alias "fts5ColumnSizeCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function fts5ApiColumnSize CDecl Alias "fts5ApiColumnSize" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ApiSetAuxdata CDecl Alias "fts5ApiSetAuxdata" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function fts5ApiGetAuxdata CDecl Alias "fts5ApiGetAuxdata" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int) As Any Ptr
Declare Sub fts5ApiPhraseNext CDecl Alias "fts5ApiPhraseNext" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_Fts5PhraseIter Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Function fts5ApiPhraseFirst CDecl Alias "fts5ApiPhraseFirst" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5PhraseIter Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub fts5ApiPhraseNextColumn CDecl Alias "fts5ApiPhraseNextColumn" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_Fts5PhraseIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Function fts5ApiQueryToken CDecl Alias "fts5ApiQueryToken" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ApiInstToken CDecl Alias "fts5ApiInstToken" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ApiColumnLocale CDecl Alias "fts5ApiColumnLocale" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ApiPhraseFirstColumn CDecl Alias "fts5ApiPhraseFirstColumn" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5PhraseIter Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ApiQueryPhrase CDecl Alias "fts5ApiQueryPhrase" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_fts5_query_phrase) As c2fb_c_int
Declare Sub fts5ApiInvoke CDecl Alias "fts5ApiInvoke" (ByVal arg0 As c2fb_Fts5Auxiliary Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr, ByVal arg2 As c2fb_sqlite3_context Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr)
Declare Function fts5CursorFromCsrid CDecl Alias "fts5CursorFromCsrid" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Cursor Ptr
Declare Sub fts5ResultError CDecl Alias "fts5ResultError" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub fts5ApiCallback CDecl Alias "fts5ApiCallback" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function sqlite3Fts5TableFromCsrid CDecl Alias "sqlite3Fts5TableFromCsrid" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Table Ptr
Declare Function fts5PoslistBlob CDecl Alias "fts5PoslistBlob" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
Declare Function fts5ColumnMethod CDecl Alias "fts5ColumnMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_sqlite3_context Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5RenameMethod CDecl Alias "fts5RenameMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3Fts5FlushToDisk CDecl Alias "sqlite3Fts5FlushToDisk" (ByVal arg0 As c2fb_Fts5Table Ptr) As c2fb_c_int
Declare Function fts5SavepointMethod CDecl Alias "fts5SavepointMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5ReleaseMethod CDecl Alias "fts5ReleaseMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5RollbackToMethod CDecl Alias "fts5RollbackToMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5CreateAux CDecl Alias "fts5CreateAux" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_6, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function fts5NewTokenizerModule CDecl Alias "fts5NewTokenizerModule" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_sqlite3_destructor_type, ByVal arg4 As c2fb_Fts5TokenizerModule Ptr Ptr) As c2fb_c_int
Declare Function fts5VtoVCreate CDecl Alias "fts5VtoVCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
Declare Sub fts5VtoVDelete CDecl Alias "fts5VtoVDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
Declare Function fts5V1toV2Tokenize CDecl Alias "fts5V1toV2Tokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_73) As c2fb_c_int
Declare Function fts5V2toV1Tokenize CDecl Alias "fts5V2toV1Tokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_callback_73) As c2fb_c_int
Declare Function fts5CreateTokenizer_v2 CDecl Alias "fts5CreateTokenizer_v2" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_fts5_tokenizer_v2 Ptr, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function fts5CreateTokenizer CDecl Alias "fts5CreateTokenizer" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_fts5_tokenizer Ptr, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function fts5LocateTokenizer CDecl Alias "fts5LocateTokenizer" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_Fts5TokenizerModule Ptr
Declare Function fts5FindTokenizer_v2 CDecl Alias "fts5FindTokenizer_v2" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_fts5_tokenizer_v2 Ptr Ptr) As c2fb_c_int
Declare Function fts5FindTokenizer CDecl Alias "fts5FindTokenizer" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_fts5_tokenizer Ptr) As c2fb_c_int
Declare Function sqlite3Fts5LoadTokenizer CDecl Alias "sqlite3Fts5LoadTokenizer" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
Declare Sub fts5ModuleDestroy CDecl Alias "fts5ModuleDestroy" (ByVal arg0 As Any Ptr)
Declare Sub fts5Fts5Func CDecl Alias "fts5Fts5Func" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub fts5SourceIdFunc CDecl Alias "fts5SourceIdFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub fts5LocaleFunc CDecl Alias "fts5LocaleFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub fts5InsttokenFunc CDecl Alias "fts5InsttokenFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function fts5ShadowName CDecl Alias "fts5ShadowName" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function fts5IntegrityMethod CDecl Alias "fts5IntegrityMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_fts5CreateModuleV2 CDecl Alias "sqlite3_create_module_v2" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As Any Ptr, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function c2fb_fts5CreateFunction CDecl Alias "sqlite3_create_function" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr, ByVal arg7 As Any Ptr) As c2fb_c_int
Declare Sub c2fb_fts5Randomness CDecl Alias "sqlite3_randomness" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Any Ptr)
Declare Function sqlite3Fts5IndexInit CDecl Alias "sqlite3Fts5IndexInit" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ExprInit CDecl Alias "sqlite3Fts5ExprInit" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5AuxInit CDecl Alias "sqlite3Fts5AuxInit" (ByVal arg0 As c2fb_fts5_api Ptr) As c2fb_c_int
Declare Function sqlite3Fts5TokenizerInit CDecl Alias "sqlite3Fts5TokenizerInit" (ByVal arg0 As c2fb_fts5_api Ptr) As c2fb_c_int
Declare Function sqlite3Fts5VocabInit CDecl Alias "sqlite3Fts5VocabInit" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function fts5Init CDecl Alias "fts5Init" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5Init CDecl Alias "sqlite3Fts5Init" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
#if defined(__FB_64BIT__)
Declare Function c2fb_crt_memset_size CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ULongInt) As Any Ptr
#else
Declare Function c2fb_crt_memset_size CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UInteger) As Any Ptr
#endif
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_snprintf CDecl Alias "sqlite3_snprintf" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function c2fb_external_sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_errmsg CDecl Alias "sqlite3_errmsg" (ByVal arg0 As c2fb_sqlite3 Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_errstr CDecl Alias "sqlite3_errstr" (ByVal arg0 As c2fb_c_int) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_prepare_v3 CDecl Alias "sqlite3_prepare_v3" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_uint, ByVal arg4 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_int64 CDecl Alias "sqlite3_bind_int64" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_value CDecl Alias "sqlite3_bind_value" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_count CDecl Alias "sqlite3_column_count" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int64 CDecl Alias "sqlite3_column_int64" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function c2fb_external_sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_text CDecl Alias "sqlite3_column_text" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_column_value CDecl Alias "sqlite3_column_value" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_sqlite3_value Ptr
Declare Function c2fb_external_sqlite3_column_bytes CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_blob CDecl Alias "sqlite3_column_blob" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function c2fb_external_sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_reset CDecl Alias "sqlite3_reset" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_blob CDecl Alias "sqlite3_value_blob" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const Any Ptr
Declare Function c2fb_external_sqlite3_value_int CDecl Alias "sqlite3_value_int" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_int64 CDecl Alias "sqlite3_value_int64" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_value_pointer CDecl Alias "sqlite3_value_pointer" (ByVal arg0 As c2fb_sqlite3_value Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_type CDecl Alias "sqlite3_value_type" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_numeric_type CDecl Alias "sqlite3_value_numeric_type" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_nochange CDecl Alias "sqlite3_value_nochange" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_subtype CDecl Alias "sqlite3_value_subtype" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_uint
Declare Function c2fb_external_sqlite3_user_data CDecl Alias "sqlite3_user_data" (ByVal arg0 As c2fb_sqlite3_context Ptr) As Any Ptr
Declare Sub c2fb_external_sqlite3_result_blob CDecl Alias "sqlite3_result_blob" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_destructor_type)
Declare Sub c2fb_external_sqlite3_result_error CDecl Alias "sqlite3_result_error" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_error_nomem CDecl Alias "sqlite3_result_error_nomem" (ByVal arg0 As c2fb_sqlite3_context Ptr)
Declare Sub c2fb_external_sqlite3_result_int64 CDecl Alias "sqlite3_result_int64" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_int64)
Declare Sub c2fb_external_sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_destructor_type)
Declare Sub c2fb_external_sqlite3_result_value CDecl Alias "sqlite3_result_value" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr)
Declare Sub c2fb_external_sqlite3_result_subtype CDecl Alias "sqlite3_result_subtype" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_uint)
Declare Function c2fb_external_sqlite3_overload_function CDecl Alias "sqlite3_overload_function" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_strnicmp CDecl Alias "sqlite3_strnicmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vtab_config CDecl Alias "sqlite3_vtab_config" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ...) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vtab_on_conflict CDecl Alias "sqlite3_vtab_on_conflict" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vtab_nochange CDecl Alias "sqlite3_vtab_nochange" (ByVal arg0 As c2fb_sqlite3_context Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ConfigParse CDecl Alias "sqlite3Fts5ConfigParse" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_Fts5Config Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5ConfigFree CDecl Alias "sqlite3Fts5ConfigFree" (ByVal arg0 As c2fb_Fts5Config Ptr)
Declare Function c2fb_external_sqlite3Fts5ConfigDeclareVtab CDecl Alias "sqlite3Fts5ConfigDeclareVtab" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5Tokenize CDecl Alias "sqlite3Fts5Tokenize" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_73) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ConfigLoad CDecl Alias "sqlite3Fts5ConfigLoad" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ConfigSetValue CDecl Alias "sqlite3Fts5ConfigSetValue" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ConfigParseRank CDecl Alias "sqlite3Fts5ConfigParseRank" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5ConfigErrmsg CDecl Alias "sqlite3Fts5ConfigErrmsg" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub c2fb_external_sqlite3Fts5BufferAppendVarint CDecl Alias "sqlite3Fts5BufferAppendVarint" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_int64)
Declare Sub c2fb_external_sqlite3Fts5BufferAppendBlob CDecl Alias "sqlite3Fts5BufferAppendBlob" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_uint, ByVal arg3 As Const UByte Ptr)
Declare Function c2fb_external_sqlite3Fts5Mprintf CDecl Alias "sqlite3Fts5Mprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3Fts5PoslistReaderInit CDecl Alias "sqlite3Fts5PoslistReaderInit" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5PoslistReaderNext CDecl Alias "sqlite3Fts5PoslistReaderNext" (ByVal arg0 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5MallocZero CDecl Alias "sqlite3Fts5MallocZero" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function c2fb_external_sqlite3Fts5IndexOpen CDecl Alias "sqlite3Fts5IndexOpen" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5Index Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexClose CDecl Alias "sqlite3Fts5IndexClose" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5IndexCloseReader CDecl Alias "sqlite3Fts5IndexCloseReader" (ByVal arg0 As c2fb_Fts5Index Ptr)
Declare Sub c2fb_external_sqlite3Fts5StorageStmtRelease CDecl Alias "sqlite3Fts5StorageStmtRelease" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_stmt Ptr)
Declare Function c2fb_external_sqlite3Fts5IndexReads CDecl Alias "sqlite3Fts5IndexReads" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexLoadConfig CDecl Alias "sqlite3Fts5IndexLoadConfig" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5GetVarint32 CDecl Alias "sqlite3Fts5GetVarint32" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_uint Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageOpen CDecl Alias "sqlite3Fts5StorageOpen" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Index Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Storage Ptr Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageClose CDecl Alias "sqlite3Fts5StorageClose" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageRename CDecl Alias "sqlite3Fts5StorageRename" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5DropAll CDecl Alias "sqlite3Fts5DropAll" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageDelete CDecl Alias "sqlite3Fts5StorageDelete" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageContentInsert CDecl Alias "sqlite3Fts5StorageContentInsert" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageIndexInsert CDecl Alias "sqlite3Fts5StorageIndexInsert" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr Ptr, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageIntegrity CDecl Alias "sqlite3Fts5StorageIntegrity" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageStmt CDecl Alias "sqlite3Fts5StorageStmt" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageDocsize CDecl Alias "sqlite3Fts5StorageDocsize" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageSize CDecl Alias "sqlite3Fts5StorageSize" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageRowCount CDecl Alias "sqlite3Fts5StorageRowCount" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageSync CDecl Alias "sqlite3Fts5StorageSync" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageRollback CDecl Alias "sqlite3Fts5StorageRollback" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageConfigValue CDecl Alias "sqlite3Fts5StorageConfigValue" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageDeleteAll CDecl Alias "sqlite3Fts5StorageDeleteAll" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageRebuild CDecl Alias "sqlite3Fts5StorageRebuild" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageOptimize CDecl Alias "sqlite3Fts5StorageOptimize" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageMerge CDecl Alias "sqlite3Fts5StorageMerge" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5StorageReset CDecl Alias "sqlite3Fts5StorageReset" (ByVal arg0 As c2fb_Fts5Storage Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5StorageReleaseDeleteRow CDecl Alias "sqlite3Fts5StorageReleaseDeleteRow" (ByVal arg0 As c2fb_Fts5Storage Ptr)
Declare Function c2fb_external_sqlite3Fts5StorageFindDeleteRow CDecl Alias "sqlite3Fts5StorageFindDeleteRow" (ByVal arg0 As c2fb_Fts5Storage Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprNew CDecl Alias "sqlite3Fts5ExprNew" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_Fts5Expr Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprPattern CDecl Alias "sqlite3Fts5ExprPattern" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_Fts5Expr Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprFirst CDecl Alias "sqlite3Fts5ExprFirst" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5Index Ptr, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprNext CDecl Alias "sqlite3Fts5ExprNext" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprEof CDecl Alias "sqlite3Fts5ExprEof" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprRowid CDecl Alias "sqlite3Fts5ExprRowid" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_int64
Declare Sub c2fb_external_sqlite3Fts5ExprFree CDecl Alias "sqlite3Fts5ExprFree" (ByVal arg0 As c2fb_Fts5Expr Ptr)
Declare Function c2fb_external_sqlite3Fts5ExprClonePhrase CDecl Alias "sqlite3Fts5ExprClonePhrase" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5Expr Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprAnd CDecl Alias "sqlite3Fts5ExprAnd" (ByVal arg0 As c2fb_Fts5Expr Ptr Ptr, ByVal arg1 As c2fb_Fts5Expr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprPhraseCount CDecl Alias "sqlite3Fts5ExprPhraseCount" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprPhraseSize CDecl Alias "sqlite3Fts5ExprPhraseSize" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprPoslist CDecl Alias "sqlite3Fts5ExprPoslist" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprPhraseCollist CDecl Alias "sqlite3Fts5ExprPhraseCollist" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprClearPoslists CDecl Alias "sqlite3Fts5ExprClearPoslists" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_Fts5PoslistPopulator Ptr
Declare Function c2fb_external_sqlite3Fts5ExprPopulatePoslists CDecl Alias "sqlite3Fts5ExprPopulatePoslists" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Expr Ptr, ByVal arg2 As c2fb_Fts5PoslistPopulator Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5ExprCheckPoslists CDecl Alias "sqlite3Fts5ExprCheckPoslists" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64)
Declare Function c2fb_external_sqlite3Fts5ExprQueryToken CDecl Alias "sqlite3Fts5ExprQueryToken" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ExprInstToken CDecl Alias "sqlite3Fts5ExprInstToken" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5ExprClearTokens CDecl Alias "sqlite3Fts5ExprClearTokens" (ByVal arg0 As c2fb_Fts5Expr Ptr)
Declare Function c2fb_external_sqlite3Fts5TokenizerPattern CDecl Alias "sqlite3Fts5TokenizerPattern" (ByVal arg0 As c2fb_callback_91, ByVal arg1 As c2fb_Fts5Tokenizer Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5TokenizerPreload CDecl Alias "sqlite3Fts5TokenizerPreload" (ByVal arg0 As c2fb_Fts5TokenizerConfig Ptr) As c2fb_c_int
Private Function fts5IsContentless CDecl Alias "fts5IsContentless" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 342
    Dim local0 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->p.pConfig)->eContent
    Return ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 3ULL))))) <> 0)))))) <> 0))))))
End Function
Private Sub fts5FreeVtab CDecl Alias "fts5FreeVtab" (ByVal arg0 As c2fb_Fts5FullTable Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 353
    If arg0 Then
        c2fb_external_sqlite3Fts5IndexClose(CPtr(c2fb_Fts5Index Ptr, arg0->p.pIndex))
        c2fb_external_sqlite3Fts5StorageClose(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage))
        c2fb_external_sqlite3Fts5ConfigFree(CPtr(c2fb_Fts5Config Ptr, arg0->p.pConfig))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Private Function fts5DisconnectMethod CDecl Alias "fts5DisconnectMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 365
    fts5FreeVtab(CPtr(c2fb_Fts5FullTable Ptr, arg0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5DestroyMethod CDecl Alias "fts5DestroyMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 373
    Dim local0 As c2fb_Fts5Table Ptr
    Dim local1 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Table Ptr, arg0)
    local1 = c2fb_external_sqlite3Fts5DropAll(CPtr(c2fb_Fts5Config Ptr, local0->pConfig))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        fts5FreeVtab(CPtr(c2fb_Fts5FullTable Ptr, arg0))
    End If
    Return local1
End Function
Private Function fts5InitVtab CDecl Alias "fts5InitVtab" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg6 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 393
    Dim local0 As c2fb_Fts5Global Ptr
    Dim local1 As Const ZString Ptr Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5Config Ptr
    Dim local4 As c2fb_Fts5FullTable Ptr
    Dim c2fb_temp_0 As c2fb_Fts5FullTable Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Config_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_6 As c2fb_Fts5Global_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Global Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_16 As ZString Ptr Ptr
    Dim c2fb_temp_17 As c2fb_Fts5FullTable Ptr
    Dim c2fb_temp_18 As c2fb_sqlite3_vtab Ptr Ptr
    Dim c2fb_temp_19 As c2fb_sqlite3_vtab Ptr

    local0 = CPtr(c2fb_Fts5Global Ptr, arg2)
    local1 = CPtr(Const ZString Ptr Ptr, arg4)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5FullTable Ptr, CPtr(c2fb_Fts5FullTable Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local2)), Cast(c2fb_size_t, SizeOf(c2fb_Fts5FullTable))))))
    local4 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ConfigParse(local0, arg1, arg3, local1, CPtr(c2fb_Fts5Config Ptr Ptr, @(local3)), arg6))
        local2 = c2fb_temp_1
        ' C unused-parameter annotation
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = CPtr(ZString Ptr Ptr Ptr, @(local3->pzErrmsg))
        c2fb_temp_3 = arg6
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(c2fb_Fts5Config_ Ptr Ptr, @(local4->p.pConfig))
        c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, local3)
        (*c2fb_temp_4) = CPtr(c2fb_Fts5Config_ Ptr, c2fb_temp_5)
        c2fb_temp_5 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_4))
        c2fb_temp_6 = CPtr(c2fb_Fts5Global_ Ptr Ptr, @(local4->pGlobal))
        c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Global Ptr, local0)
        (*c2fb_temp_6) = CPtr(c2fb_Fts5Global_ Ptr, c2fb_temp_7)
        c2fb_temp_7 = CPtr(c2fb_Fts5Global Ptr, (*c2fb_temp_6))
        If (-Cast(c2fb_c_int, (((arg0 <> 0) OrElse (c2fb_external_sqlite3Fts5TokenizerPreload(CPtr(c2fb_Fts5TokenizerConfig Ptr, @(local3->t))) <> 0))))) Then
            c2fb_temp_8 = Cast(c2fb_c_int, sqlite3Fts5LoadTokenizer(local3))
            local2 = c2fb_temp_8
        End If
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexOpen(local3, arg0, CPtr(c2fb_Fts5Index Ptr Ptr, @(local4->p.pIndex)), arg6))
        local2 = c2fb_temp_9
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageOpen(local3, CPtr(c2fb_Fts5Index Ptr, local4->p.pIndex), arg0, CPtr(c2fb_Fts5Storage Ptr Ptr, @(local4->pStorage)), arg6))
        local2 = c2fb_temp_10
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ConfigDeclareVtab(local3))
        local2 = c2fb_temp_11
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_12 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ConfigLoad(CPtr(c2fb_Fts5Config Ptr, local4->p.pConfig), Cast(c2fb_c_int, (CPtr(c2fb_Fts5Config Ptr, local4->p.pConfig)->iCookie - Cast(c2fb_c_int, 1ULL)))))
        local2 = c2fb_temp_12
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_13 = Cast(c2fb_c_int, c2fb_external_sqlite3_vtab_config(arg1, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))))
        local2 = c2fb_temp_13
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_14 = Cast(c2fb_c_int, c2fb_external_sqlite3_vtab_config(arg1, Cast(c2fb_c_int, 2ULL)))
        local2 = c2fb_temp_14
    End If
    If local3 Then
        c2fb_temp_15 = CPtr(ZString Ptr Ptr Ptr, @(local3->pzErrmsg))
        c2fb_temp_16 = CPtr(ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_15) = c2fb_temp_16
    End If
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        fts5FreeVtab(local4)
        c2fb_temp_17 = CPtr(_c2fb_record_c2fb_Fts5FullTable Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local4 = c2fb_temp_17
    Else
        If arg0 Then
            ' empty C statement
        End If
    End If
    c2fb_temp_18 = CPtr(c2fb_sqlite3_vtab Ptr Ptr, @((*arg5)))
    c2fb_temp_19 = CPtr(_c2fb_record_c2fb_sqlite3_vtab Ptr, CPtr(c2fb_sqlite3_vtab Ptr, local4))
    (*c2fb_temp_18) = c2fb_temp_19
    Return local2
End Function
Private Function fts5ConnectMethod CDecl Alias "fts5ConnectMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 467
    Return fts5InitVtab(Cast(c2fb_c_int, &O0ULL), arg0, arg1, arg2, arg3, arg4, arg5)
End Function
Private Function fts5CreateMethod CDecl Alias "fts5CreateMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 477
    Return fts5InitVtab(Cast(c2fb_c_int, 1ULL), arg0, arg1, arg2, arg3, arg4, arg5)
End Function
Private Sub fts5SetUniqueFlag CDecl Alias "fts5SetUniqueFlag" (ByVal arg0 As c2fb_sqlite3_index_info Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 503
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->idxFlags))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_0)) Or Cast(c2fb_c_int, &H00000001ULL))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
End Sub
Private Sub fts5SetEstimatedRows CDecl Alias "fts5SetEstimatedRows" (ByVal arg0 As c2fb_sqlite3_index_info Ptr, ByVal arg1 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 514
    Dim c2fb_temp_0 As c2fb_sqlite3_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    c2fb_temp_0 = CPtr(c2fb_sqlite3_int64 Ptr, @(arg0->estimatedRows))
    c2fb_temp_1 = Cast(c2fb_int64, (IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))) > (arg1)))))), Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))), (arg1))))
    (*c2fb_temp_0) = Cast(c2fb_sqlite3_int64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
End Sub
Private Function fts5UsePatternMatch CDecl Alias "fts5UsePatternMatch" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_index_constraint Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 525
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->t.ePattern = Cast(c2fb_c_int, 66ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->op) = Cast(c2fb_c_int, 66ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->t.ePattern = Cast(c2fb_c_int, 65ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->op) = Cast(c2fb_c_int, 65ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->op) = Cast(c2fb_c_int, 66ULL))))) <> 0)))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5BestIndexMethod CDecl Alias "fts5BestIndexMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_index_info Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 614
    Dim local0 As c2fb_Fts5Table Ptr
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local13 As c2fb_sqlite3_index_constraint Ptr
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_9 As Byte Ptr
    Dim c2fb_temp_10 As Byte
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Byte Ptr
    Dim c2fb_temp_13 As Byte
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Byte Ptr
    Dim c2fb_temp_18 As Byte
    Dim c2fb_temp_19 As ZString Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As UByte Ptr
    Dim c2fb_temp_26 As UByte
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As Byte Ptr
    Dim c2fb_temp_29 As Byte
    Dim c2fb_temp_30 As ZString Ptr
    Dim c2fb_temp_31 As ZString Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As Long Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As Byte Ptr
    Dim c2fb_temp_39 As Byte
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As Long Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As UByte Ptr
    Dim c2fb_temp_46 As UByte
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int
    Dim local15 As c2fb_sqlite3_index_constraint Ptr
    Dim local16 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As Byte Ptr
    Dim c2fb_temp_51 As Byte
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As Long Ptr
    Dim c2fb_temp_55 As c2fb_c_int
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As c2fb_c_int
    Dim c2fb_temp_58 As Byte Ptr
    Dim c2fb_temp_59 As Byte
    Dim c2fb_temp_60 As c2fb_c_int
    Dim c2fb_temp_61 As c2fb_c_int
    Dim c2fb_temp_62 As Long Ptr
    Dim c2fb_temp_63 As c2fb_c_int
    Dim c2fb_temp_64 As c2fb_c_int
    Dim c2fb_temp_65 As Byte Ptr
    Dim c2fb_temp_66 As Byte
    Dim local17 As c2fb_c_int
    Dim c2fb_temp_67 As c2fb_c_int
    Dim c2fb_temp_68 As c2fb_c_int
    Dim c2fb_temp_69 As Long Ptr
    Dim c2fb_temp_70 As c2fb_c_int
    Dim c2fb_temp_71 As c2fb_c_int
    Dim c2fb_temp_72 As Double Ptr
    Dim c2fb_temp_73 As Double
    Dim local18 As c2fb_int64
    Dim c2fb_temp_74 As Double Ptr
    Dim c2fb_temp_75 As Double
    Dim c2fb_temp_76 As Double Ptr
    Dim c2fb_temp_77 As Double
    Dim c2fb_temp_78 As Double Ptr
    Dim c2fb_temp_79 As Double
    Dim c2fb_temp_80 As c2fb_int64
    Dim c2fb_temp_81 As c2fb_c_int
    Dim c2fb_temp_82 As c2fb_c_int
    Dim c2fb_temp_83 As Double Ptr
    Dim c2fb_temp_84 As Double
    Dim c2fb_temp_85 As c2fb_int64
    Dim c2fb_temp_86 As Double Ptr
    Dim c2fb_temp_87 As Double
    Dim c2fb_temp_88 As Double Ptr
    Dim c2fb_temp_89 As Double
    Dim c2fb_temp_90 As Double Ptr
    Dim c2fb_temp_91 As Double
    Dim c2fb_temp_92 As c2fb_int64
    Dim c2fb_temp_93 As Long Ptr
    Dim c2fb_temp_94 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Table Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Config Ptr, local0->pConfig)
    local2 = local1->nCol
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    local8 = Cast(c2fb_c_int, &O0ULL)
    local9 = Cast(c2fb_c_int, &O0ULL)
    local10 = Cast(c2fb_c_int, &O0ULL)
    local11 = Cast(c2fb_c_int, &O0ULL)
    local12 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If local1->bLock Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @(local0->base.zErrMsg))
        c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"recursively defined fts5 content table")))
        (*c2fb_temp_0) = c2fb_temp_1
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_2 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, arg1->nConstraint) * Cast(c2fb_int64, Cast(c2fb_c_int, 8ULL)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
    local5 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_3 = CPtr(ZString Ptr Ptr, @(arg1->idxStr))
    c2fb_temp_4 = local5
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(Long Ptr, @(arg1->needToFreeIdxStr))
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_7
    While (-Cast(c2fb_c_int, ((local4 < arg1->nConstraint))))
        local13 = CPtr(c2fb_sqlite3_index_constraint Ptr, @(CPtr(c2fb_sqlite3_index_constraint Ptr, CPtr(c2fb_sqlite3_index_constraint Ptr, arg1->aConstraint))[local4]))
        local14 = local13->iColumn
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13->op) = Cast(c2fb_c_int, 64ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13->op) = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local14 >= local2)))) <> 0)))))) <> 0))))) Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13->usable) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local14 < Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_9 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[local6]))
                c2fb_temp_10 = Cast(Byte, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_9) = c2fb_temp_10
                Return Cast(c2fb_c_int, 19ULL)
            Else
                If (-Cast(c2fb_c_int, ((local14 = Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))))))) Then
                    If local12 Then
                        Goto c2fb_flow_1
                    End If
                    c2fb_temp_11 = local6
                    local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
                    c2fb_temp_12 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[c2fb_temp_11]))
                    c2fb_temp_13 = Cast(Byte, Cast(c2fb_c_int, 114))
                    (*c2fb_temp_12) = c2fb_temp_13
                    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local12 = c2fb_temp_14
                Else
                    c2fb_temp_15 = local11
                    local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
                    c2fb_temp_16 = local6
                    local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 + 1)))
                    c2fb_temp_17 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[c2fb_temp_16]))
                    c2fb_temp_18 = Cast(Byte, Cast(c2fb_c_int, 77))
                    (*c2fb_temp_17) = c2fb_temp_18
                    c2fb_temp_19 = CPtr(ZString Ptr, c2fb_external_sqlite3_snprintf(Cast(c2fb_c_int, 6ULL), CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[local6]))), StrPtr(!"%d"), local14))
                    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, c2fb_crt_strlen(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[local6]))))))))
                    local6 = c2fb_temp_20
                    ' C unused-parameter annotation
                End If
                c2fb_temp_23 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local4].argvIndex))
                c2fb_temp_21 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
                c2fb_temp_22 = local7
                c2fb_temp_24 = Cast(c2fb_c_int, c2fb_temp_22)
                (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
                c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
                c2fb_temp_25 = CPtr(UByte Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local4].omit))
                c2fb_temp_26 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_25) = c2fb_temp_26
            End If
        Else
            If local13->usable Then
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local14 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local14 < local2)))) <> 0) AndAlso (fts5UsePatternMatch(local1, local13) <> 0))))) Then
                    ' C unused-parameter annotation
                    c2fb_temp_27 = local6
                    local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_27 + 1)))
                    c2fb_temp_28 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[c2fb_temp_27]))
                    c2fb_temp_29 = Cast(Byte, IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13->op) = Cast(c2fb_c_int, 65ULL))))), Cast(c2fb_c_int, 76), Cast(c2fb_c_int, 71)))
                    (*c2fb_temp_28) = c2fb_temp_29
                    c2fb_temp_30 = CPtr(ZString Ptr, c2fb_external_sqlite3_snprintf(Cast(c2fb_c_int, 6ULL), CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[local6]))), StrPtr(!"%d"), local14))
                    c2fb_temp_31 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local5) + c2fb_crt_strlen(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[local6]))))))
                    local5 = c2fb_temp_31
                    c2fb_temp_34 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local4].argvIndex))
                    c2fb_temp_32 = local7
                    local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_32 + 1)))
                    c2fb_temp_33 = local7
                    c2fb_temp_35 = Cast(c2fb_c_int, c2fb_temp_33)
                    (*c2fb_temp_34) = Cast(Long, c2fb_temp_35)
                    c2fb_temp_35 = Cast(c2fb_c_int, (*c2fb_temp_34))
                    ' C unused-parameter annotation
                    c2fb_temp_36 = local11
                    local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_36 + 1)))
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13->op) = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local14 < Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        c2fb_temp_37 = local6
                        local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_37 + 1)))
                        c2fb_temp_38 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[c2fb_temp_37]))
                        c2fb_temp_39 = Cast(Byte, Cast(c2fb_c_int, 61))
                        (*c2fb_temp_38) = c2fb_temp_39
                        c2fb_temp_40 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local8 = c2fb_temp_40
                        c2fb_temp_43 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local4].argvIndex))
                        c2fb_temp_41 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_41 + 1)))
                        c2fb_temp_42 = local7
                        c2fb_temp_44 = Cast(c2fb_c_int, c2fb_temp_42)
                        (*c2fb_temp_43) = Cast(Long, c2fb_temp_44)
                        c2fb_temp_44 = Cast(c2fb_c_int, (*c2fb_temp_43))
                        c2fb_temp_45 = CPtr(UByte Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local4].omit))
                        c2fb_temp_46 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                        (*c2fb_temp_45) = c2fb_temp_46
                    End If
                End If
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_8 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local4 = c2fb_temp_47
        While (-Cast(c2fb_c_int, ((local4 < arg1->nConstraint))))
            local15 = CPtr(c2fb_sqlite3_index_constraint Ptr, @(CPtr(c2fb_sqlite3_index_constraint Ptr, CPtr(c2fb_sqlite3_index_constraint Ptr, arg1->aConstraint))[local4]))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local15->iColumn < Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local15->usable <> 0))))) Then
                local16 = local15->op
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local16 = Cast(c2fb_c_int, 16ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local16 = Cast(c2fb_c_int, 8ULL))))) <> 0))))) Then
                    If local10 Then
                        Goto c2fb_flow_3
                    End If
                    c2fb_temp_49 = local6
                    local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_49 + 1)))
                    c2fb_temp_50 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[c2fb_temp_49]))
                    c2fb_temp_51 = Cast(Byte, Cast(c2fb_c_int, 60))
                    (*c2fb_temp_50) = c2fb_temp_51
                    c2fb_temp_54 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local4].argvIndex))
                    c2fb_temp_52 = local7
                    local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_52 + 1)))
                    c2fb_temp_53 = local7
                    c2fb_temp_55 = Cast(c2fb_c_int, c2fb_temp_53)
                    (*c2fb_temp_54) = Cast(Long, c2fb_temp_55)
                    c2fb_temp_55 = Cast(c2fb_c_int, (*c2fb_temp_54))
                    c2fb_temp_56 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local10 = c2fb_temp_56
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local16 = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local16 = Cast(c2fb_c_int, 32ULL))))) <> 0))))) Then
                        If local9 Then
                            Goto c2fb_flow_3
                        End If
                        c2fb_temp_57 = local6
                        local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_57 + 1)))
                        c2fb_temp_58 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[c2fb_temp_57]))
                        c2fb_temp_59 = Cast(Byte, Cast(c2fb_c_int, 62))
                        (*c2fb_temp_58) = c2fb_temp_59
                        c2fb_temp_62 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local4].argvIndex))
                        c2fb_temp_60 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_60 + 1)))
                        c2fb_temp_61 = local7
                        c2fb_temp_63 = Cast(c2fb_c_int, c2fb_temp_61)
                        (*c2fb_temp_62) = Cast(Long, c2fb_temp_63)
                        c2fb_temp_63 = Cast(c2fb_c_int, (*c2fb_temp_62))
                        c2fb_temp_64 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local9 = c2fb_temp_64
                    End If
                End If
            End If
        c2fb_flow_3:
            c2fb_temp_48 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_48 + 1)))
        Wend
        c2fb_flow_2:
    End If
    c2fb_temp_65 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[local6]))
    c2fb_temp_66 = Cast(Byte, Cast(c2fb_c_int, 0))
    (*c2fb_temp_65) = c2fb_temp_66
    If (-Cast(c2fb_c_int, ((arg1->nOrderBy = Cast(c2fb_c_int, 1ULL))))) Then
        local17 = CPtr(c2fb_sqlite3_index_orderby Ptr, CPtr(c2fb_sqlite3_index_orderby Ptr, arg1->aOrderBy))[Cast(c2fb_c_int, &O0ULL)].iColumn
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local17 = (Cast(c2fb_c_int, (local1->nCol + Cast(c2fb_c_int, 1ULL)))))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local11 > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_67 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 Or Cast(c2fb_c_int, &H0020ULL))))
            local3 = c2fb_temp_67
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local17 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (CPtr(c2fb_sqlite3_index_orderby Ptr, CPtr(c2fb_sqlite3_index_orderby Ptr, arg1->aOrderBy))[Cast(c2fb_c_int, &O0ULL)].desc = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, (local1->bTokendata = 0))) <> 0)))))) <> 0))))) Then
                c2fb_temp_68 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 Or Cast(c2fb_c_int, &H0040ULL))))
                local3 = c2fb_temp_68
            End If
        End If
        If ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, ((local3) And (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H0020ULL) Or Cast(c2fb_c_int, &H0040ULL))))))) <> Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_69 = CPtr(Long Ptr, @(arg1->orderByConsumed))
            c2fb_temp_70 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_69) = Cast(Long, c2fb_temp_70)
            c2fb_temp_70 = Cast(c2fb_c_int, (*c2fb_temp_69))
            If CPtr(c2fb_sqlite3_index_orderby Ptr, CPtr(c2fb_sqlite3_index_orderby Ptr, arg1->aOrderBy))[Cast(c2fb_c_int, &O0ULL)].desc Then
                c2fb_temp_71 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 Or Cast(c2fb_c_int, &H0080ULL))))
                local3 = c2fb_temp_71
            End If
        End If
    End If
    If local8 Then
        c2fb_temp_72 = CPtr(Double Ptr, @(arg1->estimatedCost))
        c2fb_temp_73 = Cast(Double, IIf(local11, 25000.0#, 25.0#))
        (*c2fb_temp_72) = c2fb_temp_73
        fts5SetEstimatedRows(arg1, Cast(c2fb_c_int, 1ULL))
        fts5SetUniqueFlag(arg1)
    Else
        ' C automatic storage declaration
        If local11 Then
            If (-Cast(c2fb_c_int, (((local10 <> 0) AndAlso (local9 <> 0))))) Then
                c2fb_temp_74 = CPtr(Double Ptr, @(arg1->estimatedCost))
                c2fb_temp_75 = Cast(Double, 50000.0#)
                (*c2fb_temp_74) = c2fb_temp_75
            Else
                If (-Cast(c2fb_c_int, (((local10 <> 0) OrElse (local9 <> 0))))) Then
                    c2fb_temp_76 = CPtr(Double Ptr, @(arg1->estimatedCost))
                    c2fb_temp_77 = Cast(Double, 37500.0#)
                    (*c2fb_temp_76) = c2fb_temp_77
                Else
                    c2fb_temp_78 = CPtr(Double Ptr, @(arg1->estimatedCost))
                    c2fb_temp_79 = Cast(Double, 50000.0#)
                    (*c2fb_temp_78) = c2fb_temp_79
                End If
            End If
            c2fb_temp_80 = Cast(c2fb_int64, Cast(c2fb_int64, Fix((__c2fb_double_value(Cast(Double, (arg1->estimatedCost / 40.0#)))))))
            local18 = c2fb_temp_80
            c2fb_temp_81 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local4 = c2fb_temp_81
            While (-Cast(c2fb_c_int, ((local4 < local11))))
                c2fb_temp_83 = CPtr(Double Ptr, @(arg1->estimatedCost))
                c2fb_temp_84 = Cast(Double, __c2fb_double_value(Cast(Double, ((*c2fb_temp_83) * 2.5#))))
                (*c2fb_temp_83) = c2fb_temp_84
                c2fb_temp_85 = Cast(c2fb_int64, Cast(c2fb_int64, (local18 \ Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
                local18 = c2fb_temp_85
            c2fb_flow_5:
                c2fb_temp_82 = local4
                local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_82 + 1)))
            Wend
            c2fb_flow_4:
        Else
            If (-Cast(c2fb_c_int, (((local10 <> 0) AndAlso (local9 <> 0))))) Then
                c2fb_temp_86 = CPtr(Double Ptr, @(arg1->estimatedCost))
                c2fb_temp_87 = Cast(Double, 750000.0#)
                (*c2fb_temp_86) = c2fb_temp_87
            Else
                If (-Cast(c2fb_c_int, (((local10 <> 0) OrElse (local9 <> 0))))) Then
                    c2fb_temp_88 = CPtr(Double Ptr, @(arg1->estimatedCost))
                    c2fb_temp_89 = Cast(Double, 2250000.0#)
                    (*c2fb_temp_88) = c2fb_temp_89
                Else
                    c2fb_temp_90 = CPtr(Double Ptr, @(arg1->estimatedCost))
                    c2fb_temp_91 = Cast(Double, 3000000.0#)
                    (*c2fb_temp_90) = c2fb_temp_91
                End If
            End If
            c2fb_temp_92 = Cast(c2fb_int64, Cast(c2fb_int64, Fix((__c2fb_double_value(Cast(Double, (arg1->estimatedCost / 4.0#)))))))
            local18 = c2fb_temp_92
        End If
        fts5SetEstimatedRows(arg1, local18)
    End If
    c2fb_temp_93 = CPtr(Long Ptr, @(arg1->idxNum))
    c2fb_temp_94 = Cast(c2fb_c_int, local3)
    (*c2fb_temp_93) = Cast(Long, c2fb_temp_94)
    c2fb_temp_94 = Cast(c2fb_c_int, (*c2fb_temp_93))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5NewTransaction CDecl Alias "fts5NewTransaction" (ByVal arg0 As c2fb_Fts5FullTable Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 773
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Cursor Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Global Ptr, arg0->pGlobal)->pCsr))
    local0 = c2fb_temp_0
    While local0
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab) = CPtr(c2fb_sqlite3_vtab Ptr, arg0))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, local0->pNext))
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    Return c2fb_external_sqlite3Fts5StorageReset(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage))
End Function
Private Function fts5OpenMethod CDecl Alias "fts5OpenMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_vtab_cursor Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 784
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_Fts5Cursor Ptr
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_Fts5Cursor Ptr
    Dim local5 As c2fb_Fts5Global Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As Long Ptr Ptr
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_Fts5Cursor_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Cursor_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_10 As c2fb_i64 Ptr
    Dim c2fb_temp_11 As c2fb_int64
    Dim c2fb_temp_12 As c2fb_int64
    Dim c2fb_temp_13 As c2fb_i64 Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_sqlite3_vtab_cursor Ptr Ptr
    Dim c2fb_temp_17 As c2fb_sqlite3_vtab_cursor Ptr

    local0 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, fts5NewTransaction(local0))
    local4 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Cursor))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, local1->nCol) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))))))
        local3 = c2fb_temp_1
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local3))))
        local2 = c2fb_temp_2
        If local2 Then
            local5 = CPtr(c2fb_Fts5Global Ptr, local0->pGlobal)
            c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, local3)))
            c2fb_temp_4 = CPtr(Long Ptr Ptr, @(local2->aColumnSize))
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, CPtr(c2fb_Fts5Cursor Ptr, @(CPtr(c2fb_Fts5Cursor Ptr, local2)[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_4) = CPtr(Long Ptr, c2fb_temp_5)
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_4))
            c2fb_temp_6 = CPtr(c2fb_Fts5Cursor_ Ptr Ptr, @(local2->pNext))
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, local5->pCsr))
            (*c2fb_temp_6) = CPtr(c2fb_Fts5Cursor_ Ptr, c2fb_temp_7)
            c2fb_temp_7 = CPtr(c2fb_Fts5Cursor Ptr, (*c2fb_temp_6))
            c2fb_temp_8 = CPtr(c2fb_Fts5Cursor_ Ptr Ptr, @(local5->pCsr))
            c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, local2)
            (*c2fb_temp_8) = CPtr(c2fb_Fts5Cursor_ Ptr, c2fb_temp_9)
            c2fb_temp_9 = CPtr(c2fb_Fts5Cursor Ptr, (*c2fb_temp_8))
            c2fb_temp_13 = CPtr(c2fb_i64 Ptr, @(local2->iCsrId))
            c2fb_temp_10 = CPtr(c2fb_i64 Ptr, @(local5->iNextId))
            c2fb_temp_11 = Cast(c2fb_int64, (*c2fb_temp_10))
            (*c2fb_temp_10) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_11 + 1)))
            c2fb_temp_12 = (*c2fb_temp_10)
            c2fb_temp_14 = Cast(c2fb_int64, c2fb_temp_12)
            (*c2fb_temp_13) = Cast(c2fb_i64, c2fb_temp_14)
            c2fb_temp_14 = Cast(c2fb_int64, (*c2fb_temp_13))
        Else
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local4 = c2fb_temp_15
        End If
    End If
    c2fb_temp_16 = CPtr(c2fb_sqlite3_vtab_cursor Ptr Ptr, @((*arg1)))
    c2fb_temp_17 = CPtr(_c2fb_record_c2fb_sqlite3_vtab_cursor Ptr, CPtr(c2fb_sqlite3_vtab_cursor Ptr, local2))
    (*c2fb_temp_16) = c2fb_temp_17
    Return local4
End Function
Private Function fts5StmtType CDecl Alias "fts5StmtType" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 810
    If (-Cast(c2fb_c_int, ((arg0->ePlan = Cast(c2fb_c_int, 5ULL))))) Then
        Return IIf((arg0->bDesc), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))
    End If
    Return Cast(c2fb_c_int, 2ULL)
End Function
Private Sub fts5CsrNewrow CDecl Alias "fts5CsrNewrow" (ByVal arg0 As c2fb_Fts5Cursor Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 822
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @((arg0)->csrflags))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_0)) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H02ULL) Or Cast(c2fb_c_int, &H04ULL))) Or Cast(c2fb_c_int, &H08ULL))) Or Cast(c2fb_c_int, &H40ULL)))))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = (c2fb_temp_1)
End Sub
' c2fb skipped fts5FreeCursorComponents: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 831: fts5FreeCursorComponents: no complete C or FreeBASIC record layout for member c2fb_Fts5Sorter.pStmt
Private Function fts5CloseMethod CDecl Alias "fts5CloseMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 875
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_Fts5Cursor Ptr
    Dim local2 As c2fb_Fts5Cursor Ptr Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Cursor Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Cursor Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Cursor Ptr Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Cursor Ptr

    If arg0 Then
        local0 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab)))
        local1 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
        ' C automatic storage declaration
        fts5FreeCursorComponents(local1)
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr Ptr, CPtr(c2fb_Fts5Cursor Ptr Ptr, @(CPtr(c2fb_Fts5Global Ptr, local0->pGlobal)->pCsr)))
        local2 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((((*local2)) <> local1))))
            ' empty C statement
        c2fb_flow_1:
            c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr Ptr, CPtr(c2fb_Fts5Cursor Ptr Ptr, @(((*local2))->pNext)))
            local2 = c2fb_temp_1
        Wend
        c2fb_flow_0:
        c2fb_temp_2 = CPtr(c2fb_Fts5Cursor Ptr Ptr, @((*local2)))
        c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, local1->pNext))
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped fts5SorterNext: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 891: fts5SorterNext: no complete C or FreeBASIC record layout for member c2fb_Fts5Sorter.pStmt
Private Sub fts5TripCursors CDecl Alias "fts5TripCursors" (ByVal arg0 As c2fb_Fts5FullTable Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 934
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Global Ptr, arg0->pGlobal)->pCsr))
    local0 = c2fb_temp_0
    While local0
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->ePlan = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab) = CPtr(c2fb_sqlite3_vtab Ptr, arg0))))) <> 0))))) Then
            c2fb_temp_2 = CPtr(Long Ptr, @((local0)->csrflags))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_2)) Or (Cast(c2fb_c_int, &H20ULL)))))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            c2fb_temp_4 = (c2fb_temp_3)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, local0->pNext))
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
End Sub
Private Function fts5CursorReseek CDecl Alias "fts5CursorReseek" (ByVal arg0 As c2fb_Fts5Cursor Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 957
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5FullTable Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (Cast(c2fb_c_int, ((arg0)->csrflags And (Cast(c2fb_c_int, &H20ULL))))) Then
        local1 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg0->base.pVtab)))
        local2 = arg0->bDesc
        local3 = c2fb_external_sqlite3Fts5ExprRowid(CPtr(c2fb_Fts5Expr Ptr, arg0->pExpr))
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprFirst(CPtr(c2fb_Fts5Expr Ptr, arg0->pExpr), CPtr(c2fb_Fts5Index Ptr, local1->p.pIndex), local3, arg0->iLastRowid, local2))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 <> c2fb_external_sqlite3Fts5ExprRowid(CPtr(c2fb_Fts5Expr Ptr, arg0->pExpr)))))) <> 0))))) Then
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg1)))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_1) = c2fb_temp_2
        End If
        c2fb_temp_3 = CPtr(Long Ptr, @((arg0)->csrflags))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_3)) And Cast(c2fb_c_int, (Not (Cast(c2fb_c_int, &H20ULL)))))))
        (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        c2fb_temp_5 = (c2fb_temp_4)
        fts5CsrNewrow(arg0)
        If c2fb_external_sqlite3Fts5ExprEof(CPtr(c2fb_Fts5Expr Ptr, arg0->pExpr)) Then
            c2fb_temp_6 = CPtr(Long Ptr, @((arg0)->csrflags))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_6)) Or (Cast(c2fb_c_int, &H01ULL)))))
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            c2fb_temp_8 = (c2fb_temp_7)
            c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg1)))
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_9) = c2fb_temp_10
        End If
    End If
    Return local0
End Function
Private Function fts5NextMethod CDecl Alias "fts5NextMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 991
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local3 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As ZString Ptr Ptr
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Long Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->ePlan = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso (CPtr(c2fb_Fts5Config Ptr, (CPtr(c2fb_Fts5Table Ptr, CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab)))->pConfig)->bTokendata <> 0))))) Then
        c2fb_external_sqlite3Fts5ExprClearTokens(CPtr(c2fb_Fts5Expr Ptr, local0->pExpr))
    End If
    If (-Cast(c2fb_c_int, ((local0->ePlan < Cast(c2fb_c_int, 3ULL))))) Then
        local2 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, fts5CursorReseek(local0, CPtr(c2fb_c_int Ptr, @(local2))))
        local1 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((((c2fb_temp_0) <> 0) OrElse (local2 <> 0))))) Then
            Return local1
        End If
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprNext(CPtr(c2fb_Fts5Expr Ptr, local0->pExpr), local0->iLastRowid))
        local1 = c2fb_temp_1
        c2fb_temp_2 = CPtr(Long Ptr, @((local0)->csrflags))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_2)) Or (c2fb_external_sqlite3Fts5ExprEof(CPtr(c2fb_Fts5Expr Ptr, local0->pExpr))))))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        c2fb_temp_4 = (c2fb_temp_3)
        fts5CsrNewrow(local0)
    Else
        Select Case local0->ePlan
            Case Cast(c2fb_c_int, 3ULL)
                c2fb_temp_5 = CPtr(Long Ptr, @((local0)->csrflags))
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_5)) Or (Cast(c2fb_c_int, &H01ULL)))))
                (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
                c2fb_temp_7 = (c2fb_temp_6)
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local1 = c2fb_temp_8
                Goto c2fb_flow_0
            Case Cast(c2fb_c_int, 4ULL)
                c2fb_temp_9 = Cast(c2fb_c_int, fts5SorterNext(local0))
                local1 = c2fb_temp_9
                Goto c2fb_flow_0
            Case Else
                local3 = CPtr(c2fb_Fts5Config Ptr, (CPtr(c2fb_Fts5Table Ptr, CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab)))->pConfig)
                c2fb_temp_10 = CPtr(Long Ptr, @(local3->bLock))
                c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                (*c2fb_temp_10) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
                c2fb_temp_12 = Cast(c2fb_c_int, c2fb_external_sqlite3_step(CPtr(c2fb_sqlite3_stmt Ptr, local0->pStmt)))
                local1 = c2fb_temp_12
                c2fb_temp_13 = CPtr(Long Ptr, @(local3->bLock))
                c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
                (*c2fb_temp_13) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 - 1)))
                If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, 100ULL))))) Then
                    c2fb_temp_15 = CPtr(Long Ptr, @((local0)->csrflags))
                    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_15)) Or (Cast(c2fb_c_int, &H01ULL)))))
                    (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
                    c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
                    c2fb_temp_17 = (c2fb_temp_16)
                    c2fb_temp_18 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(CPtr(c2fb_sqlite3_stmt Ptr, local0->pStmt)))
                    local1 = c2fb_temp_18
                    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_19 = CPtr(ZString Ptr Ptr, @(CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab)->zErrMsg))
                        c2fb_temp_20 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(CPtr(c2fb_sqlite3 Ptr, local3->db)))))
                        (*c2fb_temp_19) = c2fb_temp_20
                    End If
                Else
                    c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local1 = c2fb_temp_21
                    c2fb_temp_22 = CPtr(Long Ptr, @((local0)->csrflags))
                    c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_22)) Or (Cast(c2fb_c_int, &H04ULL)))))
                    (*c2fb_temp_22) = Cast(Long, c2fb_temp_23)
                    c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
                    c2fb_temp_24 = (c2fb_temp_23)
                End If
                Goto c2fb_flow_0
        End Select
        c2fb_flow_0:
    End If
    Return local1
End Function
Private Function fts5PrepareStatement CDecl Alias "fts5PrepareStatement" (ByVal arg0 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg1 As c2fb_Fts5Config Ptr, ByVal arg2 As Const ZString Ptr, ...) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1055
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim local3 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_sqlite3_stmt Ptr Ptr
    Dim c2fb_temp_4 As c2fb_sqlite3_stmt Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    Cva_Start(local3, arg2)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg2, local3))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local1 = c2fb_temp_1
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v3(CPtr(c2fb_sqlite3 Ptr, arg1->db), CPtr(Const ZString Ptr, local2), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &H01ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3Fts5ConfigErrmsg(arg1, StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(CPtr(c2fb_sqlite3 Ptr, arg1->db))))
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    End If
    Cva_End(local3)
    c2fb_temp_3 = CPtr(c2fb_sqlite3_stmt Ptr Ptr, @((*arg0)))
    c2fb_temp_4 = local0
    (*c2fb_temp_3) = c2fb_temp_4
    Return local1
End Function
' c2fb skipped fts5CursorFirstSorted: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 1084: fts5CursorFirstSorted: assignment parser stopped at byte 102 (nByte = (           __builtin_offsetof (           Fts5Sorter           ,            nIdx           )           +((nPhra):            +((nPhrase+2)/2)*sizeof(i64))
Private Function fts5CursorFirst CDecl Alias "fts5CursorFirst" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1136
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5Expr Ptr, arg1->pExpr)
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprFirst(local1, CPtr(c2fb_Fts5Index Ptr, arg0->p.pIndex), arg1->iFirstRowid, arg1->iLastRowid, arg2))
    local0 = c2fb_temp_0
    If c2fb_external_sqlite3Fts5ExprEof(local1) Then
        c2fb_temp_1 = CPtr(Long Ptr, @((arg1)->csrflags))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_1)) Or (Cast(c2fb_c_int, &H01ULL)))))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        c2fb_temp_3 = (c2fb_temp_2)
    End If
    fts5CsrNewrow(arg1)
    Return local0
End Function
Private Function fts5SpecialMatch CDecl Alias "fts5SpecialMatch" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1155
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_i64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_i64 Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As ZString Ptr Ptr
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = arg2
    ' C automatic storage declaration
    While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local1)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 32)))))
        c2fb_temp_0 = local1
        local1 = (c2fb_temp_0 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_1
    While (-Cast(c2fb_c_int, (((CPtr(Const Byte Ptr, local1)[local2] <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local1)[local2]) <> Cast(c2fb_c_int, 32))))) <> 0)))))
        ' empty C statement
    c2fb_flow_3:
        c2fb_temp_2 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_2:
    ' C unused-parameter annotation
    c2fb_temp_3 = CPtr(Long Ptr, @(arg1->ePlan))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_strnicmp(StrPtr(!"reads"), local1, local2))))) <> 0))))) Then
        c2fb_temp_5 = CPtr(c2fb_i64 Ptr, @(arg1->iSpecial))
        c2fb_temp_6 = Cast(c2fb_int64, c2fb_external_sqlite3Fts5IndexReads(CPtr(c2fb_Fts5Index Ptr, arg0->p.pIndex)))
        (*c2fb_temp_5) = Cast(c2fb_i64, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_int64, (*c2fb_temp_5))
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_strnicmp(StrPtr(!"id"), local1, local2))))) <> 0))))) Then
            c2fb_temp_7 = CPtr(c2fb_i64 Ptr, @(arg1->iSpecial))
            c2fb_temp_8 = Cast(c2fb_int64, arg1->iCsrId)
            (*c2fb_temp_7) = Cast(c2fb_i64, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_int64, (*c2fb_temp_7))
        Else
            c2fb_temp_9 = CPtr(ZString Ptr Ptr, @(arg0->p.base.zErrMsg))
            c2fb_temp_10 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"unknown special query: %.*s"), local2, local1))
            (*c2fb_temp_9) = c2fb_temp_10
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local0 = c2fb_temp_11
        End If
    End If
    Return local0
End Function
Private Function fts5FindAuxiliary CDecl Alias "fts5FindAuxiliary" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_Fts5Auxiliary Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1190
    Dim local0 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Auxiliary Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Global Ptr, arg0->pGlobal)->pAux))
    local0 = c2fb_temp_0
    While local0
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(arg1, CPtr(Const ZString Ptr, local0->zFunc)) = Cast(c2fb_c_int, &O0ULL))))) Then
            Return local0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, local0->pNext))
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5FindRankFunction CDecl Alias "fts5FindRankFunction" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1202
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5Auxiliary Ptr
    Dim local4 As Const ZString Ptr
    Dim local5 As Const ZString Ptr
    Dim local6 As ZString Ptr
    Dim local7 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local8 As c2fb_int64
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_sqlite3_value_ Ptr Ptr Ptr
    Dim c2fb_temp_5 As c2fb_sqlite3_value Ptr Ptr
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_sqlite3_value_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_10 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_11 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_14 As ZString Ptr Ptr
    Dim c2fb_temp_15 As ZString Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_Fts5Auxiliary_ Ptr Ptr
    Dim c2fb_temp_18 As c2fb_Fts5Auxiliary Ptr

    local0 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg0->base.pVtab)))
    local1 = CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = CPtr(Const ZString Ptr, arg0->zRank)
    local5 = CPtr(Const ZString Ptr, arg0->zRankArgs)
    If local5 Then
        local6 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local2)), StrPtr(!"SELECT %s"), local5))
        If local6 Then
            local7 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v3(CPtr(c2fb_sqlite3 Ptr, local1->db), CPtr(Const ZString Ptr, local6), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &H01ULL), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local7)), Cast(c2fb_c_int, &O0ULL)))
            local2 = c2fb_temp_0
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local6))
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local7))))) Then
                    ' C automatic storage declaration
                    c2fb_temp_1 = CPtr(Long Ptr, @(arg0->nRankArg))
                    c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_count(local7))
                    (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
                    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
                    c2fb_temp_3 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_sqlite3_value Ptr))) * Cast(c2fb_uint64, arg0->nRankArg))))
                    local8 = c2fb_temp_3
                    c2fb_temp_4 = CPtr(c2fb_sqlite3_value_ Ptr Ptr Ptr, @(arg0->apRankArg))
                    c2fb_temp_5 = CPtr(c2fb_sqlite3_value Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local2)), local8)))
                    (*c2fb_temp_4) = CPtr(c2fb_sqlite3_value_ Ptr Ptr, c2fb_temp_5)
                    c2fb_temp_5 = CPtr(c2fb_sqlite3_value Ptr Ptr, (*c2fb_temp_4))
                    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                        ' C automatic storage declaration
                        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        local9 = c2fb_temp_6
                        While (-Cast(c2fb_c_int, ((local9 < arg0->nRankArg))))
                            c2fb_temp_8 = CPtr(c2fb_sqlite3_value_ Ptr Ptr, @(CPtr(c2fb_sqlite3_value Ptr Ptr, CPtr(c2fb_sqlite3_value Ptr Ptr, arg0->apRankArg))[local9]))
                            c2fb_temp_9 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(local7, local9))
                            (*c2fb_temp_8) = CPtr(c2fb_sqlite3_value_ Ptr, c2fb_temp_9)
                            c2fb_temp_9 = CPtr(c2fb_sqlite3_value Ptr, (*c2fb_temp_8))
                        c2fb_flow_1:
                            c2fb_temp_7 = local9
                            local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
                        Wend
                        c2fb_flow_0:
                    End If
                    c2fb_temp_10 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pRankArgStmt))
                    c2fb_temp_11 = local7
                    (*c2fb_temp_10) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_11)
                    c2fb_temp_11 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_10))
                Else
                    c2fb_temp_12 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize(local7))
                    local2 = c2fb_temp_12
                    ' C unused-parameter annotation
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, fts5FindAuxiliary(local0, local4)))
        local3 = c2fb_temp_13
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C unused-parameter annotation
            c2fb_temp_14 = CPtr(ZString Ptr Ptr, @(local0->p.base.zErrMsg))
            c2fb_temp_15 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"no such function: %s"), local4))
            (*c2fb_temp_14) = c2fb_temp_15
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local2 = c2fb_temp_16
        End If
    End If
    c2fb_temp_17 = CPtr(c2fb_Fts5Auxiliary_ Ptr Ptr, @(arg0->pRank))
    c2fb_temp_18 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, local3)
    (*c2fb_temp_17) = CPtr(c2fb_Fts5Auxiliary_ Ptr, c2fb_temp_18)
    c2fb_temp_18 = CPtr(c2fb_Fts5Auxiliary Ptr, (*c2fb_temp_17))
    Return local2
End Function
Private Function fts5CursorParseRank CDecl Alias "fts5CursorParseRank" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1253
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As ZString Ptr Ptr
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As ZString Ptr Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As ZString Ptr Ptr
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As ZString Ptr Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr Ptr
    Dim c2fb_temp_18 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg2 Then
        local1 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2)))
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg2) = Cast(c2fb_c_int, 5ULL))))) Then
                c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_0
            End If
        Else
            c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ConfigParseRank(local1, CPtr(ZString Ptr Ptr, @(local2)), CPtr(ZString Ptr Ptr, @(local3))))
            local0 = c2fb_temp_1
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg1->zRank))
            c2fb_temp_3 = local2
            (*c2fb_temp_2) = c2fb_temp_3
            c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(arg1->zRankArgs))
            c2fb_temp_5 = local3
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_6 = CPtr(Long Ptr, @((arg1)->csrflags))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_6)) Or (Cast(c2fb_c_int, &H10ULL)))))
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            c2fb_temp_8 = (c2fb_temp_7)
        Else
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
                c2fb_temp_9 = CPtr(ZString Ptr Ptr, @(CPtr(c2fb_sqlite3_vtab Ptr, arg1->base.pVtab)->zErrMsg))
                c2fb_temp_10 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"parse error in rank function: %s"), local1))
                (*c2fb_temp_9) = c2fb_temp_10
            End If
        End If
    Else
        If arg0->zRank Then
            c2fb_temp_11 = CPtr(ZString Ptr Ptr, @(arg1->zRank))
            c2fb_temp_12 = CPtr(ZString Ptr, arg0->zRank)
            (*c2fb_temp_11) = c2fb_temp_12
            c2fb_temp_13 = CPtr(ZString Ptr Ptr, @(arg1->zRankArgs))
            c2fb_temp_14 = CPtr(ZString Ptr, arg0->zRankArgs)
            (*c2fb_temp_13) = c2fb_temp_14
        Else
            c2fb_temp_15 = CPtr(ZString Ptr Ptr, @(arg1->zRank))
            c2fb_temp_16 = CPtr(ZString Ptr, StrPtr(!"bm25"))
            (*c2fb_temp_15) = c2fb_temp_16
            c2fb_temp_17 = CPtr(ZString Ptr Ptr, @(arg1->zRankArgs))
            c2fb_temp_18 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_17) = c2fb_temp_18
        End If
    End If
    Return local0
End Function
Private Function fts5GetRowidLimit CDecl Alias "fts5GetRowidLimit" (ByVal arg0 As c2fb_sqlite3_value Ptr, ByVal arg1 As c2fb_int64) As c2fb_int64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1290
    Dim local0 As c2fb_c_int

    If arg0 Then
        local0 = c2fb_external_sqlite3_value_numeric_type(arg0)
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
            Return c2fb_external_sqlite3_value_int64(arg0)
        End If
    End If
    Return arg1
End Function
Private Sub fts5SetVtabError CDecl Alias "fts5SetVtabError" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As Const ZString Ptr, ...)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1303
    Dim local0 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr

    ' C automatic storage declaration
    Cva_Start(local0, arg1)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->p.base.zErrMsg))
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, @(arg0->p.base.zErrMsg))
    c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local0))
    (*c2fb_temp_0) = c2fb_temp_1
    Cva_End(local0)
End Sub
Sub sqlite3Fts5SetLocale CDecl Alias "sqlite3Fts5SetLocale" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1317
    Dim local0 As c2fb_Fts5TokenizerConfig Ptr
    Dim c2fb_temp_0 As Const ZString Ptr Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5TokenizerConfig Ptr, @(arg0->t))
    c2fb_temp_0 = CPtr(Const ZString Ptr Ptr, @(local0->pLocale))
    c2fb_temp_1 = arg1
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(Long Ptr, @(local0->nLocale))
    c2fb_temp_3 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
End Sub
Sub sqlite3Fts5ClearLocale CDecl Alias "sqlite3Fts5ClearLocale" (ByVal arg0 As c2fb_Fts5Config Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1330
    sqlite3Fts5SetLocale(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Sub
Function sqlite3Fts5IsLocaleValue CDecl Alias "sqlite3Fts5IsLocaleValue" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1338
    Dim local0 As c2fb_c_int
    Dim local1 As Const UByte Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg1) = Cast(c2fb_c_int, 4ULL))))) Then
        local1 = CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob(arg1))
        local2 = c2fb_external_sqlite3_value_bytes(arg1)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 > (Cast(c2fb_c_int, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_c_uint))))))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, local1), CPtr(Const Any Ptr, (CPtr(Const UByte Ptr, (CPtr(c2fb_c_uint Ptr, (@CPtr(c2fb_Fts5Global Ptr, arg0->pGlobal)->aLocaleHdr(0))))))), (Cast(c2fb_c_int, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_c_uint)))))))))) <> 0))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local0 = c2fb_temp_0
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5DecodeLocaleValue CDecl Alias "sqlite3Fts5DecodeLocaleValue" (ByVal arg0 As c2fb_sqlite3_value Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1371
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Const ZString Ptr Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Const ZString Ptr Ptr
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob(arg0))
    local1 = c2fb_external_sqlite3_value_bytes(arg0)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, (Cast(c2fb_c_int, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_c_uint))))))
    local2 = c2fb_temp_0
    While CPtr(Const Byte Ptr, local0)[local2]
        If (-Cast(c2fb_c_int, ((local2 = (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 1ULL)))))))) Then
            Return Cast(c2fb_c_int, 20ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_2 = CPtr(Const ZString Ptr Ptr, @((*arg3)))
    c2fb_temp_3 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0)[(Cast(c2fb_c_int, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_c_uint)))))])))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 - (Cast(c2fb_c_int, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_c_uint))))))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_7 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))])))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - local2)) - Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_8) = c2fb_temp_9
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5ExtractExprText CDecl Alias "fts5ExtractExprText" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1411
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If sqlite3Fts5IsLocaleValue(arg0, arg1) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, sqlite3Fts5DecodeLocaleValue(arg1, CPtr(Const ZString Ptr Ptr, @(local1)), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(Const ZString Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local4))))
        local0 = c2fb_temp_0
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @((*arg2)))
        c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local0)), StrPtr(!"%.*s"), local2, local1))
        (*c2fb_temp_1) = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            sqlite3Fts5SetLocale(arg0, local3, local4)
        End If
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_3) = c2fb_temp_4
    Else
        c2fb_temp_5 = CPtr(ZString Ptr Ptr, @((*arg2)))
        c2fb_temp_6 = CPtr(ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg1)))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_7) = c2fb_temp_8
    End If
    Return local0
End Function
Private Function fts5FilterMethod CDecl Alias "fts5FilterMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1450
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_Fts5Cursor Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_sqlite3_value Ptr
    Dim local7 As c2fb_sqlite3_value Ptr
    Dim local8 As c2fb_sqlite3_value Ptr
    Dim local9 As c2fb_sqlite3_value Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As ZString Ptr Ptr
    Dim local12 As c2fb_c_int
    Dim local13 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_sqlite3_value Ptr
    Dim local16 As ZString Ptr
    Dim local17 As c2fb_c_int
    Dim local18 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local19 As ZString Ptr Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_Fts5Expr Ptr
    Dim local20 As c2fb_c_int
    Dim local21 As Const ZString Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_25 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_26 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_27 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As Long Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_33 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_34 As c2fb_i64 Ptr
    Dim c2fb_temp_35 As c2fb_int64
    Dim c2fb_temp_36 As c2fb_i64 Ptr
    Dim c2fb_temp_37 As c2fb_int64
    Dim c2fb_temp_38 As c2fb_i64 Ptr
    Dim c2fb_temp_39 As c2fb_int64
    Dim c2fb_temp_40 As c2fb_i64 Ptr
    Dim c2fb_temp_41 As c2fb_int64
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_i64 Ptr
    Dim c2fb_temp_44 As c2fb_int64
    Dim c2fb_temp_45 As c2fb_i64 Ptr
    Dim c2fb_temp_46 As c2fb_int64
    Dim c2fb_temp_47 As c2fb_i64 Ptr
    Dim c2fb_temp_48 As c2fb_int64
    Dim c2fb_temp_49 As c2fb_i64 Ptr
    Dim c2fb_temp_50 As c2fb_int64
    Dim c2fb_temp_51 As Long Ptr
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As c2fb_Fts5Expr_ Ptr Ptr
    Dim c2fb_temp_54 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_55 As c2fb_c_int
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As Long Ptr
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As c2fb_c_int
    Dim c2fb_temp_60 As Long Ptr
    Dim c2fb_temp_61 As c2fb_c_int
    Dim c2fb_temp_62 As c2fb_c_int
    Dim c2fb_temp_63 As c2fb_c_int
    Dim c2fb_temp_64 As Long Ptr
    Dim c2fb_temp_65 As c2fb_c_int
    Dim c2fb_temp_66 As c2fb_c_int
    Dim c2fb_temp_67 As c2fb_c_int
    Dim c2fb_temp_68 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_69 As ZString Ptr Ptr
    Dim c2fb_temp_70 As Long Ptr
    Dim c2fb_temp_71 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab)))
    local1 = CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)
    local2 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    local8 = Cast(c2fb_c_int, &O0ULL)
    local9 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local11 = local1->pzErrmsg
    local12 = local1->bPrefixInsttoken
    ' C automatic storage declaration
    local14 = Cast(c2fb_c_int, &O0ULL)
    local15 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If local2->ePlan Then
        fts5FreeCursorComponents(local2)
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_c_int Ptr, @(local2->ePlan))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Cursor))) - Cast(c2fb_uint64, ((CPtr(UByte Ptr, CPtr(UByte Ptr, CPtr(c2fb_c_int Ptr, @(local2->ePlan)))) - CPtr(UByte Ptr, CPtr(UByte Ptr, local2)))))))))
    End If
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_1 = CPtr(ZString Ptr Ptr Ptr, @(local1->pzErrmsg))
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(local0->p.base.zErrMsg))
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local13 = c2fb_temp_3
    While (-Cast(c2fb_c_int, ((local13 < arg3))))
        c2fb_temp_5 = local14
        local14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Select Case CPtr(Const Byte Ptr, arg2)[c2fb_temp_5]
            Case Cast(c2fb_c_int, 114)
                c2fb_temp_6 = arg4[local13]
                local6 = c2fb_temp_6
            Case Cast(c2fb_c_int, 77)
                local16 = Cast(c2fb_c_int, &O0ULL)
                local17 = Cast(c2fb_c_int, &O0ULL)
                local18 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_7 = Cast(c2fb_c_int, fts5ExtractExprText(local1, arg4[local13], CPtr(ZString Ptr Ptr, @(local16)), CPtr(c2fb_c_int Ptr, @(local17))))
                local3 = c2fb_temp_7
                If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_label_0
                End If
                If (-Cast(c2fb_c_int, ((local16 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_8 = CPtr(ZString Ptr, StrPtr(!""))
                    local16 = c2fb_temp_8
                End If
                If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_subtype(arg4[local13]) = Cast(c2fb_c_uint, Cast(c2fb_c_int, 73ULL)))))) Then
                    c2fb_temp_9 = CPtr(Long Ptr, @(local1->bPrefixInsttoken))
                    c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
                    c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
                End If
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local10 = c2fb_temp_11
                Do
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local10 * Cast(c2fb_c_int, 10ULL))) + (Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[local14]) - Cast(c2fb_c_int, 48)))))))
                    local10 = c2fb_temp_12
                    c2fb_temp_13 = local14
                    local14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                c2fb_flow_4:
                Loop While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[local14]) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[local14]) <= Cast(c2fb_c_int, 57))))) <> 0)))))
                c2fb_flow_3:
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local16)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 42))))) Then
                    c2fb_temp_14 = Cast(c2fb_c_int, fts5SpecialMatch(local0, local2, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local16)[Cast(c2fb_c_int, 1ULL)])))))
                    local3 = c2fb_temp_14
                    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local18 = c2fb_temp_15
                Else
                    local19 = CPtr(ZString Ptr Ptr, @(local0->p.base.zErrMsg))
                    c2fb_temp_16 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprNew(local1, Cast(c2fb_c_int, &O0ULL), local10, CPtr(Const ZString Ptr, local16), CPtr(c2fb_Fts5Expr Ptr Ptr, @(local15)), local19))
                    local3 = c2fb_temp_16
                    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprAnd(CPtr(c2fb_Fts5Expr Ptr Ptr, @(local2->pExpr)), local15))
                        local3 = c2fb_temp_17
                        c2fb_temp_18 = CPtr(c2fb_Fts5Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                        local15 = c2fb_temp_18
                    End If
                End If
                If local17 Then
                    c2fb_external_sqlite3_free(CPtr(Any Ptr, local16))
                    sqlite3Fts5ClearLocale(local1)
                End If
                If (-Cast(c2fb_c_int, (((local18 <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    Goto c2fb_label_0
                End If
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 76), Cast(c2fb_c_int, 71)
                local20 = ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[Cast(c2fb_c_int, (local14 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 71))))))
                local21 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg4[local13])))
                c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local10 = c2fb_temp_19
                Do
                    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local10 * Cast(c2fb_c_int, 10ULL))) + (Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[local14]) - Cast(c2fb_c_int, 48)))))))
                    local10 = c2fb_temp_20
                    c2fb_temp_21 = local14
                    local14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
                c2fb_flow_6:
                Loop While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[local14]) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[local14]) <= Cast(c2fb_c_int, 57))))) <> 0)))))
                c2fb_flow_5:
                If local21 Then
                    c2fb_temp_22 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprPattern(local1, local20, local10, local21, CPtr(c2fb_Fts5Expr Ptr Ptr, @(local15))))
                    local3 = c2fb_temp_22
                End If
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_23 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprAnd(CPtr(c2fb_Fts5Expr Ptr Ptr, @(local2->pExpr)), local15))
                    local3 = c2fb_temp_23
                    c2fb_temp_24 = CPtr(c2fb_Fts5Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local15 = c2fb_temp_24
                End If
                If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_label_0
                End If
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 61)
                c2fb_temp_25 = arg4[local13]
                local7 = c2fb_temp_25
            Case Cast(c2fb_c_int, 60)
                c2fb_temp_26 = arg4[local13]
                local8 = c2fb_temp_26
            Case Else
                ' C unused-parameter annotation
                c2fb_temp_27 = arg4[local13]
                local9 = c2fb_temp_27
        End Select
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_4 = local13
        local13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_28 = Cast(c2fb_c_int, (IIf((Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0020ULL)))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))))
    local5 = c2fb_temp_28
    c2fb_temp_30 = CPtr(Long Ptr, @(local2->bDesc))
    c2fb_temp_29 = Cast(c2fb_c_int, (IIf((Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0080ULL)))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))))
    local4 = c2fb_temp_29
    c2fb_temp_31 = Cast(c2fb_c_int, c2fb_temp_29)
    (*c2fb_temp_30) = Cast(Long, c2fb_temp_31)
    c2fb_temp_31 = Cast(c2fb_c_int, (*c2fb_temp_30))
    If local7 Then
        c2fb_temp_32 = local7
        local9 = c2fb_temp_32
        c2fb_temp_33 = c2fb_temp_32
        local8 = c2fb_temp_33
    End If
    If local4 Then
        c2fb_temp_34 = CPtr(c2fb_i64 Ptr, @(local2->iFirstRowid))
        c2fb_temp_35 = Cast(c2fb_int64, fts5GetRowidLimit(local8, (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL)))))))))
        (*c2fb_temp_34) = Cast(c2fb_i64, c2fb_temp_35)
        c2fb_temp_35 = Cast(c2fb_int64, (*c2fb_temp_34))
        c2fb_temp_36 = CPtr(c2fb_i64 Ptr, @(local2->iLastRowid))
        c2fb_temp_37 = Cast(c2fb_int64, fts5GetRowidLimit(local9, (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))) - (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL))))))))))))
        (*c2fb_temp_36) = Cast(c2fb_i64, c2fb_temp_37)
        c2fb_temp_37 = Cast(c2fb_int64, (*c2fb_temp_36))
    Else
        c2fb_temp_38 = CPtr(c2fb_i64 Ptr, @(local2->iLastRowid))
        c2fb_temp_39 = Cast(c2fb_int64, fts5GetRowidLimit(local8, (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL)))))))))
        (*c2fb_temp_38) = Cast(c2fb_i64, c2fb_temp_39)
        c2fb_temp_39 = Cast(c2fb_int64, (*c2fb_temp_38))
        c2fb_temp_40 = CPtr(c2fb_i64 Ptr, @(local2->iFirstRowid))
        c2fb_temp_41 = Cast(c2fb_int64, fts5GetRowidLimit(local9, (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))) - (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL))))))))))))
        (*c2fb_temp_40) = Cast(c2fb_i64, c2fb_temp_41)
        c2fb_temp_41 = Cast(c2fb_int64, (*c2fb_temp_40))
    End If
    c2fb_temp_42 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexLoadConfig(CPtr(c2fb_Fts5Index Ptr, local0->p.pIndex)))
    local3 = c2fb_temp_42
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    If CPtr(c2fb_Fts5Cursor Ptr, local0->pSortCsr) Then
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        If CPtr(c2fb_Fts5Cursor Ptr, local0->pSortCsr)->bDesc Then
            c2fb_temp_43 = CPtr(c2fb_i64 Ptr, @(local2->iLastRowid))
            c2fb_temp_44 = Cast(c2fb_int64, CPtr(c2fb_Fts5Cursor Ptr, local0->pSortCsr)->iFirstRowid)
            (*c2fb_temp_43) = Cast(c2fb_i64, c2fb_temp_44)
            c2fb_temp_44 = Cast(c2fb_int64, (*c2fb_temp_43))
            c2fb_temp_45 = CPtr(c2fb_i64 Ptr, @(local2->iFirstRowid))
            c2fb_temp_46 = Cast(c2fb_int64, CPtr(c2fb_Fts5Cursor Ptr, local0->pSortCsr)->iLastRowid)
            (*c2fb_temp_45) = Cast(c2fb_i64, c2fb_temp_46)
            c2fb_temp_46 = Cast(c2fb_int64, (*c2fb_temp_45))
        Else
            c2fb_temp_47 = CPtr(c2fb_i64 Ptr, @(local2->iLastRowid))
            c2fb_temp_48 = Cast(c2fb_int64, CPtr(c2fb_Fts5Cursor Ptr, local0->pSortCsr)->iLastRowid)
            (*c2fb_temp_47) = Cast(c2fb_i64, c2fb_temp_48)
            c2fb_temp_48 = Cast(c2fb_int64, (*c2fb_temp_47))
            c2fb_temp_49 = CPtr(c2fb_i64 Ptr, @(local2->iFirstRowid))
            c2fb_temp_50 = Cast(c2fb_int64, CPtr(c2fb_Fts5Cursor Ptr, local0->pSortCsr)->iFirstRowid)
            (*c2fb_temp_49) = Cast(c2fb_i64, c2fb_temp_50)
            c2fb_temp_50 = Cast(c2fb_int64, (*c2fb_temp_49))
        End If
        c2fb_temp_51 = CPtr(Long Ptr, @(local2->ePlan))
        c2fb_temp_52 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
        (*c2fb_temp_51) = Cast(Long, c2fb_temp_52)
        c2fb_temp_52 = Cast(c2fb_c_int, (*c2fb_temp_51))
        c2fb_temp_53 = CPtr(c2fb_Fts5Expr_ Ptr Ptr, @(local2->pExpr))
        c2fb_temp_54 = CPtr(c2fb_Fts5Expr Ptr, CPtr(c2fb_Fts5Cursor Ptr, local0->pSortCsr)->pExpr)
        (*c2fb_temp_53) = CPtr(c2fb_Fts5Expr_ Ptr, c2fb_temp_54)
        c2fb_temp_54 = CPtr(c2fb_Fts5Expr Ptr, (*c2fb_temp_53))
        c2fb_temp_55 = Cast(c2fb_c_int, fts5CursorFirst(local0, local2, local4))
        local3 = c2fb_temp_55
    Else
        If CPtr(c2fb_Fts5Expr Ptr, local2->pExpr) Then
            ' C unused-parameter annotation
            c2fb_temp_56 = Cast(c2fb_c_int, fts5CursorParseRank(local1, local2, local6))
            local3 = c2fb_temp_56
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                If local5 Then
                    c2fb_temp_57 = CPtr(Long Ptr, @(local2->ePlan))
                    c2fb_temp_58 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
                    (*c2fb_temp_57) = Cast(Long, c2fb_temp_58)
                    c2fb_temp_58 = Cast(c2fb_c_int, (*c2fb_temp_57))
                    c2fb_temp_59 = Cast(c2fb_c_int, fts5CursorFirstSorted(local0, local2, local4))
                    local3 = c2fb_temp_59
                Else
                    c2fb_temp_60 = CPtr(Long Ptr, @(local2->ePlan))
                    c2fb_temp_61 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_60) = Cast(Long, c2fb_temp_61)
                    c2fb_temp_61 = Cast(c2fb_c_int, (*c2fb_temp_60))
                    c2fb_temp_62 = Cast(c2fb_c_int, fts5CursorFirst(local0, local2, local4))
                    local3 = c2fb_temp_62
                End If
            End If
        Else
            If (-Cast(c2fb_c_int, ((local1->zContent = Cast(c2fb_c_int, &O0ULL))))) Then
                fts5SetVtabError(local0, StrPtr(!"%s: table does not support scanning"), local1->zName)
                c2fb_temp_63 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local3 = c2fb_temp_63
            Else
                c2fb_temp_64 = CPtr(Long Ptr, @(local2->ePlan))
                c2fb_temp_65 = Cast(c2fb_c_int, (IIf(local7, Cast(c2fb_c_int, 6ULL), Cast(c2fb_c_int, 5ULL))))
                (*c2fb_temp_64) = Cast(Long, c2fb_temp_65)
                c2fb_temp_65 = Cast(c2fb_c_int, (*c2fb_temp_64))
                c2fb_temp_66 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageStmt(CPtr(c2fb_Fts5Storage Ptr, local0->pStorage), fts5StmtType(local2), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2->pStmt)), CPtr(ZString Ptr Ptr, @(local0->p.base.zErrMsg))))
                local3 = c2fb_temp_66
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                    If (-Cast(c2fb_c_int, ((local7 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        ' C unused-parameter annotation
                        c2fb_external_sqlite3_bind_value(CPtr(c2fb_sqlite3_stmt Ptr, local2->pStmt), Cast(c2fb_c_int, 1ULL), CPtr(Const c2fb_sqlite3_value Ptr, local7))
                    Else
                        c2fb_external_sqlite3_bind_int64(CPtr(c2fb_sqlite3_stmt Ptr, local2->pStmt), Cast(c2fb_c_int, 1ULL), local2->iFirstRowid)
                        c2fb_external_sqlite3_bind_int64(CPtr(c2fb_sqlite3_stmt Ptr, local2->pStmt), Cast(c2fb_c_int, 2ULL), local2->iLastRowid)
                    End If
                    c2fb_temp_67 = Cast(c2fb_c_int, fts5NextMethod(arg0))
                    local3 = c2fb_temp_67
                End If
            End If
        End If
    End If
    c2fb_label_0:
    c2fb_external_sqlite3Fts5ExprFree(local15)
    c2fb_temp_68 = CPtr(ZString Ptr Ptr Ptr, @(local1->pzErrmsg))
    c2fb_temp_69 = local11
    (*c2fb_temp_68) = c2fb_temp_69
    c2fb_temp_70 = CPtr(Long Ptr, @(local1->bPrefixInsttoken))
    c2fb_temp_71 = Cast(c2fb_c_int, local12)
    (*c2fb_temp_70) = Cast(Long, c2fb_temp_71)
    c2fb_temp_71 = Cast(c2fb_c_int, (*c2fb_temp_70))
    Return local3
End Function
Private Function fts5EofMethod CDecl Alias "fts5EofMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1656
    Dim local0 As c2fb_Fts5Cursor Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    Return (IIf((Cast(c2fb_c_int, ((local0)->csrflags And (Cast(c2fb_c_int, &H01ULL))))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL)))
End Function
Private Function fts5CursorRowid CDecl Alias "fts5CursorRowid" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_int64
#ifdef SQLITE_DEBUG
    fts5MainAssert(arg0->ePlan = FTS5_PLAN_MATCH OrElse _
        arg0->ePlan = FTS5_PLAN_SORTED_MATCH OrElse _
        arg0->ePlan = FTS5_PLAN_SOURCE OrElse _
        arg0->ePlan = FTS5_PLAN_SCAN OrElse _
        arg0->ePlan = FTS5_PLAN_ROWID, _
        StrPtr(!"pCsr->ePlan==FTS5_PLAN_MATCH || pCsr->ePlan==FTS5_PLAN_SORTED_MATCH || pCsr->ePlan==FTS5_PLAN_SOURCE || pCsr->ePlan==FTS5_PLAN_SCAN || pCsr->ePlan==FTS5_PLAN_ROWID"))
#endif
    If arg0->pSorter Then
        Return CPtr(c2fb_Fts5Sorter Ptr, arg0->pSorter)->iRowid
    ElseIf arg0->ePlan >= FTS5_PLAN_SCAN Then
        Return c2fb_external_sqlite3_column_int64(arg0->pStmt, 0)
    Else
        Return c2fb_external_sqlite3Fts5ExprRowid(arg0->pExpr)
    End If
End Function

Private Function fts5RowidMethod CDecl Alias "fts5RowidMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1686
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_int64 Ptr
    Dim c2fb_temp_3 As c2fb_int64

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = local0->ePlan
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 3ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
    Else
        c2fb_temp_2 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_3 = Cast(c2fb_int64, fts5CursorRowid(local0))
        (*c2fb_temp_2) = c2fb_temp_3
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5SeekCursor CDecl Alias "fts5SeekCursor" (ByVal arg0 As c2fb_Fts5Cursor Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1708
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5FullTable Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local3 As c2fb_Fts5Table Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pStmt) = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg0->base.pVtab)))
        local2 = fts5StmtType(arg0)
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageStmt(CPtr(c2fb_Fts5Storage Ptr, local1->pStorage), local2, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pStmt)), (IIf(arg1, CPtr(ZString Ptr Ptr, @(local1->p.base.zErrMsg)), CPtr(ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))))
        local0 = c2fb_temp_0
        ' C unused-parameter annotation
        ' C unused-parameter annotation
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((Cast(c2fb_c_int, ((arg0)->csrflags And (Cast(c2fb_c_int, &H02ULL))))) <> 0))))) Then
        local3 = CPtr(c2fb_Fts5Table Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg0->base.pVtab)))
        ' C unused-parameter annotation
        c2fb_external_sqlite3_reset(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pStmt))
        c2fb_external_sqlite3_bind_int64(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pStmt), Cast(c2fb_c_int, 1ULL), fts5CursorRowid(arg0))
        c2fb_temp_1 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Config Ptr, local3->pConfig)->bLock))
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        (*c2fb_temp_1) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3_step(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pStmt)))
        local0 = c2fb_temp_3
        c2fb_temp_4 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Config Ptr, local3->pConfig)->bLock))
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
        (*c2fb_temp_4) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 - 1)))
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 100ULL))))) Then
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_6
            c2fb_temp_7 = CPtr(Long Ptr, @((arg0)->csrflags))
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_7)) And Cast(c2fb_c_int, (Not (Cast(c2fb_c_int, &H02ULL)))))))
            (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
            c2fb_temp_9 = (c2fb_temp_8)
        Else
            c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pStmt)))
            local0 = c2fb_temp_10
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_11 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                local0 = c2fb_temp_11
                fts5SetVtabError(CPtr(c2fb_Fts5FullTable Ptr, local3), StrPtr(!"fts5: missing row %lld from content table %s"), fts5CursorRowid(arg0), CPtr(c2fb_Fts5Config Ptr, local3->pConfig)->zContent)
            Else
                If CPtr(c2fb_Fts5Config Ptr, local3->pConfig)->pzErrmsg Then
                    fts5SetVtabError(CPtr(c2fb_Fts5FullTable Ptr, local3), StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(CPtr(c2fb_sqlite3 Ptr, CPtr(c2fb_Fts5Config Ptr, local3->pConfig)->db))))
                End If
            End If
        End If
    End If
    Return local0
End Function
Private Function fts5SpecialInsert CDecl Alias "fts5SpecialInsert" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1767
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->p.pConfig)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"delete-all"), arg1))))) Then
        If (-Cast(c2fb_c_int, ((local0->eContent = Cast(c2fb_c_int, &O0ULL))))) Then
            fts5SetVtabError(arg0, StrPtr(!"'delete-all' may only be used with a contentless or external content fts5 table"))
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local1 = c2fb_temp_0
        Else
            c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDeleteAll(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage)))
            local1 = c2fb_temp_1
        End If
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_2
    Else
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"rebuild"), arg1))))) Then
            If fts5IsContentless(arg0, Cast(c2fb_c_int, 1ULL)) Then
                fts5SetVtabError(arg0, StrPtr(!"'rebuild' may not be used with a contentless fts5 table"))
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local1 = c2fb_temp_3
            Else
                c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageRebuild(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage)))
                local1 = c2fb_temp_4
            End If
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local3 = c2fb_temp_5
        Else
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"optimize"), arg1))))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageOptimize(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage)))
                local1 = c2fb_temp_6
            Else
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"merge"), arg1))))) Then
                    local4 = c2fb_external_sqlite3_value_int(arg2)
                    c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageMerge(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage), local4))
                    local1 = c2fb_temp_7
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"integrity-check"), arg1))))) Then
                        local5 = c2fb_external_sqlite3_value_int(arg2)
                        c2fb_temp_8 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageIntegrity(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage), local5))
                        local1 = c2fb_temp_8
                    Else
#ifdef SQLITE_DEBUG
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"prefix-index"), arg1))))) Then
                            local0->bPrefixIndex = c2fb_external_sqlite3_value_int(arg2)
                        Else
#endif
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"flush"), arg1))))) Then
                            c2fb_temp_9 = Cast(c2fb_c_int, sqlite3Fts5FlushToDisk(CPtr(c2fb_Fts5Table Ptr, @(arg0->p))))
                            local1 = c2fb_temp_9
                        Else
                            c2fb_temp_10 = Cast(c2fb_c_int, sqlite3Fts5FlushToDisk(CPtr(c2fb_Fts5Table Ptr, @(arg0->p))))
                            local1 = c2fb_temp_10
                            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexLoadConfig(CPtr(c2fb_Fts5Index Ptr, arg0->p.pIndex)))
                                local1 = c2fb_temp_11
                            End If
                            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_12 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ConfigSetValue(CPtr(c2fb_Fts5Config Ptr, arg0->p.pConfig), arg1, arg2, CPtr(c2fb_c_int Ptr, @(local2))))
                                local1 = c2fb_temp_12
                            End If
                            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                                If local2 Then
                                    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                    local1 = c2fb_temp_13
                                Else
                                    c2fb_temp_14 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageConfigValue(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage), arg1, arg2, Cast(c2fb_c_int, &O0ULL)))
                                    local1 = c2fb_temp_14
                                End If
                            End If
                        End If
#ifdef SQLITE_DEBUG
                        End If
#endif
                    End If
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local3 <> 0))))) Then
        c2fb_temp_15 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Config Ptr, arg0->p.pConfig)->iCookie))
        c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
        (*c2fb_temp_15) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 - 1)))
        c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexLoadConfig(CPtr(c2fb_Fts5Index Ptr, arg0->p.pIndex)))
        local1 = c2fb_temp_17
    End If
    Return local1
End Function
Private Function fts5SpecialDelete CDecl Alias "fts5SpecialDelete" (ByVal arg0 As c2fb_Fts5FullTable Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1837
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = c2fb_external_sqlite3_value_type(arg1[Cast(c2fb_c_int, 1ULL)])
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 1ULL))))) Then
        local2 = c2fb_external_sqlite3_value_int64(arg1[Cast(c2fb_c_int, 1ULL)])
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDelete(CPtr(c2fb_Fts5Storage Ptr, arg0->pStorage), local2, CPtr(c2fb_sqlite3_value Ptr Ptr, @(arg1[Cast(c2fb_c_int, 2ULL)])), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_0
    End If
    Return local0
End Function
Private Sub fts5StorageInsert CDecl Alias "fts5StorageInsert" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5FullTable Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1850
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = (*arg0)
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageContentInsert(CPtr(c2fb_Fts5Storage Ptr, arg1->pStorage), Cast(c2fb_c_int, &O0ULL), arg2, arg3))
        local0 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageIndexInsert(CPtr(c2fb_Fts5Storage Ptr, arg1->pStorage), arg2, (*arg3)))
        local0 = c2fb_temp_1
    End If
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg0)))
    c2fb_temp_3 = Cast(c2fb_c_int, local0)
    (*c2fb_temp_2) = c2fb_temp_3
End Sub
Private Function fts5ContentlessUpdate CDecl Alias "fts5ContentlessUpdate" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1889
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->abUnindexed[local0]) = Cast(c2fb_c_int, &O0ULL))))) Then
            If c2fb_external_sqlite3_value_nochange(arg1[local0]) Then
                c2fb_temp_2 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            Else
                c2fb_temp_3 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_4) = c2fb_temp_5
    Else
        If (-Cast(c2fb_c_int, (((local2 <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->bContentlessDelete = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local3 = c2fb_temp_6
            c2fb_external_sqlite3Fts5ConfigErrmsg(arg0, (IIf(arg0->bContentlessDelete, StrPtr(!"%s a subset of columns on fts5 contentless-delete table: %s"), StrPtr(!"%s contentless fts5 table: %s"))), StrPtr(!"cannot UPDATE"), arg0->zName)
        End If
    End If
    Return local3
End Function
Private Function fts5UpdateMethod CDecl Alias "fts5UpdateMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 1941
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local9 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local10 As c2fb_int64
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local11 As c2fb_Fts5Storage Ptr
    Dim local12 As c2fb_int64
    Dim local13 As c2fb_int64
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_26 As ZString Ptr Ptr

    local0 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local1->pgsz = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ConfigLoad(CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig), CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)->iCookie))
        local3 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local3
        End If
    End If
    c2fb_temp_1 = CPtr(ZString Ptr Ptr Ptr, @(CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)->pzErrmsg))
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(local0->p.base.zErrMsg))
    (*c2fb_temp_1) = c2fb_temp_2
    fts5TripCursors(local0)
    c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_type(arg2[Cast(c2fb_c_int, &O0ULL)]))
    local2 = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg2[Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + local1->nCol))]) <> Cast(c2fb_c_int, 5ULL))))) <> 0))))) Then
        local4 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + local1->nCol))])))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->eContent <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"delete"), local4))))) <> 0))))) Then
            If local1->bContentlessDelete Then
                fts5SetVtabError(local0, StrPtr(!"'delete' may not be used with a contentless_delete=1 table"))
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local3 = c2fb_temp_4
            Else
                c2fb_temp_5 = Cast(c2fb_c_int, fts5SpecialDelete(local0, arg2))
                local3 = c2fb_temp_5
            End If
        Else
            c2fb_temp_6 = Cast(c2fb_c_int, fts5SpecialInsert(local0, local4, arg2[Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + local1->nCol)) + Cast(c2fb_c_int, 1ULL)))]))
            local3 = c2fb_temp_6
        End If
    Else
        local5 = Cast(c2fb_c_int, 4ULL)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (local1->bContentlessDelete <> 0))))) Then
            c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3_vtab_on_conflict(CPtr(c2fb_sqlite3 Ptr, local1->db)))
            local5 = c2fb_temp_7
        End If
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) Then
            If (-Cast(c2fb_c_int, (((fts5IsContentless(local0, Cast(c2fb_c_int, 1ULL)) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->bContentlessDelete = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                fts5SetVtabError(local0, StrPtr(!"cannot DELETE from contentless fts5 table: %s"), local1->zName)
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local3 = c2fb_temp_8
            Else
                local6 = c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, &O0ULL)])
                c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDelete(CPtr(c2fb_Fts5Storage Ptr, local0->pStorage), local6, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                local3 = c2fb_temp_9
            End If
        Else
            local7 = c2fb_external_sqlite3_value_numeric_type(arg2[Cast(c2fb_c_int, 1ULL)])
            If (-Cast(c2fb_c_int, ((local1->bLocale = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C automatic storage declaration
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local8 = c2fb_temp_10
                While (-Cast(c2fb_c_int, ((local8 < local1->nCol))))
                    local9 = arg2[Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, 2ULL)))]
                    If sqlite3Fts5IsLocaleValue(local1, local9) Then
                        fts5SetVtabError(local0, StrPtr(!"fts5_locale() requires locale=1"))
                        c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 20ULL))
                        local3 = c2fb_temp_12
                        Goto c2fb_label_0
                    End If
                c2fb_flow_1:
                    c2fb_temp_11 = local8
                    local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
                Wend
                c2fb_flow_0:
            End If
            If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, 1ULL))))) Then
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                    local10 = c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, 1ULL)])
                    c2fb_temp_13 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDelete(CPtr(c2fb_Fts5Storage Ptr, local0->pStorage), local10, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                    local3 = c2fb_temp_13
                End If
                fts5StorageInsert(CPtr(c2fb_c_int Ptr, @(local3)), local0, arg2, arg3)
            Else
                local11 = CPtr(c2fb_Fts5Storage Ptr, local0->pStorage)
                local12 = c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, &O0ULL)])
                local13 = c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, 1ULL)])
                local14 = Cast(c2fb_c_int, &O0ULL)
                If fts5IsContentless(local0, Cast(c2fb_c_int, 1ULL)) Then
                    c2fb_temp_14 = Cast(c2fb_c_int, fts5ContentlessUpdate(local1, CPtr(c2fb_sqlite3_value Ptr Ptr, @(arg2[Cast(c2fb_c_int, 2ULL)])), (-Cast(c2fb_c_int, ((local12 <> local13)))), CPtr(c2fb_c_int Ptr, @(local14))))
                    local3 = c2fb_temp_14
                    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_label_0
                    End If
                End If
                If (-Cast(c2fb_c_int, ((local7 <> Cast(c2fb_c_int, 1ULL))))) Then
                    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 20ULL))
                    local3 = c2fb_temp_15
                Else
                    If (-Cast(c2fb_c_int, ((local12 <> local13)))) Then
                        ' C unused-parameter annotation
                        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, 5ULL))))) Then
                            c2fb_temp_16 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDelete(local11, local12, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL)))
                            local3 = c2fb_temp_16
                            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDelete(local11, local13, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                                local3 = c2fb_temp_17
                            End If
                            fts5StorageInsert(CPtr(c2fb_c_int Ptr, @(local3)), local0, arg2, arg3)
                        Else
                            c2fb_temp_18 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageFindDeleteRow(local11, local12))
                            local3 = c2fb_temp_18
                            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_19 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageContentInsert(local11, Cast(c2fb_c_int, &O0ULL), arg2, arg3))
                                local3 = c2fb_temp_19
                            End If
                            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_20 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDelete(local11, local12, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                                local3 = c2fb_temp_20
                            End If
                            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_21 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageIndexInsert(local11, arg2, (*arg3)))
                                local3 = c2fb_temp_21
                            End If
                        End If
                    Else
                        If local14 Then
                            ' C unused-parameter annotation
                            c2fb_temp_22 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageFindDeleteRow(local11, local12))
                            local3 = c2fb_temp_22
                            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_23 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageContentInsert(local11, Cast(c2fb_c_int, 1ULL), arg2, arg3))
                                local3 = c2fb_temp_23
                            End If
                        Else
                            c2fb_temp_24 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDelete(local11, local12, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL)))
                            local3 = c2fb_temp_24
                            fts5StorageInsert(CPtr(c2fb_c_int Ptr, @(local3)), local0, arg2, arg3)
                        End If
                    End If
                End If
                c2fb_external_sqlite3Fts5StorageReleaseDeleteRow(local11)
            End If
        End If
    End If
    c2fb_label_0:
    c2fb_external_sqlite3Fts5IndexCloseReader(CPtr(c2fb_Fts5Index Ptr, local0->p.pIndex))
    c2fb_temp_25 = CPtr(ZString Ptr Ptr Ptr, @(CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)->pzErrmsg))
    c2fb_temp_26 = CPtr(ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_25) = c2fb_temp_26
    Return local3
End Function
Private Function fts5SyncMethod CDecl Alias "fts5SyncMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2117
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5FullTable Ptr
    Dim c2fb_temp_0 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    ' empty C statement
    c2fb_temp_0 = CPtr(ZString Ptr Ptr Ptr, @(CPtr(c2fb_Fts5Config Ptr, local1->p.pConfig)->pzErrmsg))
    c2fb_temp_1 = CPtr(ZString Ptr Ptr, @(local1->p.base.zErrMsg))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, sqlite3Fts5FlushToDisk(CPtr(c2fb_Fts5Table Ptr, @(local1->p))))
    local0 = c2fb_temp_2
    c2fb_temp_3 = CPtr(ZString Ptr Ptr Ptr, @(CPtr(c2fb_Fts5Config Ptr, local1->p.pConfig)->pzErrmsg))
    c2fb_temp_4 = CPtr(ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_3) = c2fb_temp_4
    Return local0
End Function
Private Function fts5BeginMethod CDecl Alias "fts5BeginMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2130
    Dim local0 As c2fb_c_int

    local0 = fts5NewTransaction(CPtr(c2fb_Fts5FullTable Ptr, arg0))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' empty C statement
    End If
    Return local0
End Function
Private Function fts5CommitMethod CDecl Alias "fts5CommitMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2143
    ' C unused-parameter annotation
    ' empty C statement
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5RollbackMethod CDecl Alias "fts5RollbackMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2153
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5FullTable Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    ' empty C statement
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageRollback(CPtr(c2fb_Fts5Storage Ptr, local1->pStorage)))
    local0 = c2fb_temp_0
    c2fb_temp_1 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Config Ptr, local1->p.pConfig)->pgsz))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    Return local0
End Function
Private Function fts5ApiUserData CDecl Alias "fts5ApiUserData" (ByVal arg0 As c2fb_Fts5Context Ptr) As Any Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2164
    Dim local0 As c2fb_Fts5Cursor Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    Return CPtr(c2fb_Fts5Auxiliary Ptr, local0->pAux)->pUserData
End Function
Private Function fts5ApiColumnCount CDecl Alias "fts5ApiColumnCount" (ByVal arg0 As c2fb_Fts5Context Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2169
    Dim local0 As c2fb_Fts5Cursor Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    Return CPtr(c2fb_Fts5Config Ptr, (CPtr(c2fb_Fts5Table Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab))))->pConfig)->nCol
End Function
Private Function fts5ApiColumnTotalSize CDecl Alias "fts5ApiColumnTotalSize" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2174
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_Fts5FullTable Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab)))
    Return c2fb_external_sqlite3Fts5StorageSize(CPtr(c2fb_Fts5Storage Ptr, local1->pStorage), arg1, arg2)
End Function
Private Function fts5ApiRowCount CDecl Alias "fts5ApiRowCount" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2184
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_Fts5FullTable Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab)))
    Return c2fb_external_sqlite3Fts5StorageRowCount(CPtr(c2fb_Fts5Storage Ptr, local1->pStorage), arg1)
End Function
Private Function fts5ApiTokenize_v2 CDecl Alias "fts5ApiTokenize_v2" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Any Ptr, ByVal arg6 As c2fb_callback_73) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2193
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_Fts5Table Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Table Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab)))
    local2 = Cast(c2fb_c_int, &O0ULL)
    sqlite3Fts5SetLocale(CPtr(c2fb_Fts5Config Ptr, local1->pConfig), arg3, arg4)
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5Tokenize(CPtr(c2fb_Fts5Config Ptr, local1->pConfig), Cast(c2fb_c_int, &H0008ULL), arg1, arg2, arg5, arg6))
    local2 = c2fb_temp_0
    sqlite3Fts5SetLocale(CPtr(c2fb_Fts5Config Ptr, local1->pConfig), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    Return local2
End Function
Private Function fts5ApiTokenize CDecl Alias "fts5ApiTokenize" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_callback_73) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2217
    Return fts5ApiTokenize_v2(arg0, arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg3, arg4)
End Function
Private Function fts5ApiPhraseCount CDecl Alias "fts5ApiPhraseCount" (ByVal arg0 As c2fb_Fts5Context Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2226
    Dim local0 As c2fb_Fts5Cursor Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    Return c2fb_external_sqlite3Fts5ExprPhraseCount(CPtr(c2fb_Fts5Expr Ptr, local0->pExpr))
End Function
Private Function fts5ApiPhraseSize CDecl Alias "fts5ApiPhraseSize" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2231
    Dim local0 As c2fb_Fts5Cursor Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    Return c2fb_external_sqlite3Fts5ExprPhraseSize(CPtr(c2fb_Fts5Expr Ptr, local0->pExpr), arg1)
End Function
Private Function fts5TextFromStmt CDecl Alias "fts5TextFromStmt" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2250
    Dim local0 As c2fb_sqlite3_value Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(arg1, Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))))
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, (((arg0->bLocale <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso (sqlite3Fts5IsLocaleValue(arg0, local0) <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, sqlite3Fts5DecodeLocaleValue(local0, arg3, arg4, CPtr(Const ZString Ptr Ptr, @(local1)), CPtr(c2fb_c_int Ptr, @(local2))))
        local3 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, @((*arg3)))
        c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(local0)))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes(local0))
        (*c2fb_temp_3) = c2fb_temp_4
        If (-Cast(c2fb_c_int, (((arg0->bLocale <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_5 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(arg1, Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))) + arg0->nCol)))))
            local1 = c2fb_temp_5
            c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_bytes(arg1, Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))) + arg0->nCol))))
            local2 = c2fb_temp_6
        End If
    End If
    sqlite3Fts5SetLocale(arg0, local1, local2)
    Return local3
End Function
Private Function fts5ApiColumnText CDecl Alias "fts5ApiColumnText" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2279
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Cursor Ptr
    Dim local2 As c2fb_Fts5Table Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local2 = CPtr(c2fb_Fts5Table Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local1->base.pVtab)))
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= CPtr(c2fb_Fts5Config Ptr, local2->pConfig)->nCol)))) <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 25ULL))
        local0 = c2fb_temp_0
    Else
        If fts5IsContentless(CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local1->base.pVtab))), Cast(c2fb_c_int, &O0ULL)) Then
            c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, @((*arg2)))
            c2fb_temp_2 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_1) = c2fb_temp_2
            c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_3) = c2fb_temp_4
        Else
            c2fb_temp_5 = Cast(c2fb_c_int, fts5SeekCursor(local1, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_5
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, fts5TextFromStmt(CPtr(c2fb_Fts5Config Ptr, local2->pConfig), CPtr(c2fb_sqlite3_stmt Ptr, local1->pStmt), arg1, arg2, arg3))
                local0 = c2fb_temp_6
                sqlite3Fts5ClearLocale(CPtr(c2fb_Fts5Config Ptr, local2->pConfig))
            End If
        End If
    End If
    Return local0
End Function
' c2fb skipped fts5CsrPoslist: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 2312: fts5CsrPoslist: no FreeBASIC storage field for C member c2fb_Fts5Sorter.iRowid
Private Function fts5CacheInstArray CDecl Alias "fts5CacheInstArray" (ByVal arg0 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2382
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5PoslistReader Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_Fts5PoslistReader_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5PoslistReader Ptr
    Dim c2fb_temp_3 As c2fb_Fts5PoslistReader Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local7 As Const UByte Ptr
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local9 As c2fb_c_int Ptr
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As Long Ptr Ptr
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Long Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As Long Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = CPtr(c2fb_Fts5Config Ptr, (CPtr(c2fb_Fts5Table Ptr, CPtr(c2fb_sqlite3_vtab Ptr, arg0->base.pVtab)))->pConfig)->nCol
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprPhraseCount(CPtr(c2fb_Fts5Expr Ptr, arg0->pExpr)))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5PoslistReader Ptr, arg0->aInstIter) = Cast(c2fb_c_int, &O0ULL))))) Then
        local4 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistReader))) * Cast(c2fb_uint64, local2)))
        c2fb_temp_1 = CPtr(c2fb_Fts5PoslistReader_ Ptr Ptr, @(arg0->aInstIter))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5PoslistReader Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), local4))))
        (*c2fb_temp_1) = CPtr(c2fb_Fts5PoslistReader_ Ptr, c2fb_temp_2)
        c2fb_temp_2 = CPtr(c2fb_Fts5PoslistReader Ptr, (*c2fb_temp_1))
    End If
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5PoslistReader Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, arg0->aInstIter))
    local1 = c2fb_temp_3
    If local1 Then
        local5 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local6 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 < local2)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_6 = Cast(c2fb_c_int, fts5CsrPoslist(arg0, local6, CPtr(Const UByte Ptr Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local8))))
            local0 = c2fb_temp_6
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_external_sqlite3Fts5PoslistReaderInit(local7, local8, CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local6])))
            End If
        c2fb_flow_1:
            c2fb_temp_5 = local6
            local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            While Cast(c2fb_c_int, 1ULL)
                ' C automatic storage declaration
                local10 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local6 = c2fb_temp_7
                While (-Cast(c2fb_c_int, ((local6 < local2))))
                    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local6].bEof) = Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local10 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local6].iPos < CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local10].iPos)))) <> 0)))))) <> 0))))) Then
                        c2fb_temp_9 = Cast(c2fb_c_int, local6)
                        local10 = c2fb_temp_9
                    End If
                c2fb_flow_5:
                    c2fb_temp_8 = local6
                    local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
                Wend
                c2fb_flow_4:
                If (-Cast(c2fb_c_int, ((local10 < Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_2
                End If
                c2fb_temp_10 = local5
                local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
                If (-Cast(c2fb_c_int, ((local5 >= arg0->nInstAlloc)))) Then
                    local11 = IIf(arg0->nInstAlloc, Cast(c2fb_c_int, (arg0->nInstAlloc * Cast(c2fb_c_int, 2ULL))), Cast(c2fb_c_int, 32ULL))
                    c2fb_temp_11 = CPtr(c2fb_c_int Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, arg0->aInst), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, local11) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 3ULL)))))))
                    local9 = c2fb_temp_11
                    If local9 Then
                        c2fb_temp_12 = CPtr(Long Ptr Ptr, @(arg0->aInst))
                        c2fb_temp_13 = local9
                        (*c2fb_temp_12) = CPtr(Long Ptr, c2fb_temp_13)
                        c2fb_temp_13 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_12))
                        c2fb_temp_14 = CPtr(Long Ptr, @(arg0->nInstAlloc))
                        c2fb_temp_15 = Cast(c2fb_c_int, local11)
                        (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
                        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                    Else
                        c2fb_temp_16 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 - 1)))
                        c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                        local0 = c2fb_temp_17
                        Goto c2fb_flow_2
                    End If
                End If
                c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @(arg0->aInst[Cast(c2fb_c_int, (Cast(c2fb_c_int, 3ULL) * (Cast(c2fb_c_int, (local5 - Cast(c2fb_c_int, 1ULL))))))]))
                local9 = c2fb_temp_18
                c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @(local9[Cast(c2fb_c_int, &O0ULL)]))
                c2fb_temp_20 = Cast(c2fb_c_int, local10)
                (*c2fb_temp_19) = c2fb_temp_20
                c2fb_temp_21 = CPtr(c2fb_c_int Ptr, @(local9[Cast(c2fb_c_int, 1ULL)]))
                c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, ((Cast(c2fb_int64, (CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local10].iPos Shr Cast(c2fb_c_int, 32ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL)))))))
                (*c2fb_temp_21) = c2fb_temp_22
                c2fb_temp_23 = CPtr(c2fb_c_int Ptr, @(local9[Cast(c2fb_c_int, 2ULL)]))
                c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local10].iPos And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL)))))))
                (*c2fb_temp_23) = c2fb_temp_24
                ' C unused-parameter annotation
                If (-Cast(c2fb_c_int, ((local9[Cast(c2fb_c_int, 1ULL)] >= local3)))) Then
                    c2fb_temp_25 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local0 = c2fb_temp_25
                    Goto c2fb_flow_2
                End If
                c2fb_external_sqlite3Fts5PoslistReaderNext(CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local10])))
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        End If
        c2fb_temp_26 = CPtr(Long Ptr, @(arg0->nInstCount))
        c2fb_temp_27 = Cast(c2fb_c_int, local5)
        (*c2fb_temp_26) = Cast(Long, c2fb_temp_27)
        c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
        c2fb_temp_28 = CPtr(Long Ptr, @((arg0)->csrflags))
        c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_28)) And Cast(c2fb_c_int, (Not (Cast(c2fb_c_int, &H08ULL)))))))
        (*c2fb_temp_28) = Cast(Long, c2fb_temp_29)
        c2fb_temp_29 = Cast(c2fb_c_int, (*c2fb_temp_28))
        c2fb_temp_30 = (c2fb_temp_29)
    End If
    Return local0
End Function
Private Function fts5ApiInstCount CDecl Alias "fts5ApiInstCount" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2457
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_2 = 1
    If (((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, ((local0)->csrflags And (Cast(c2fb_c_int, &H08ULL))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) = 0) Then
        c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, fts5CacheInstArray(local0))
        local1 = c2fb_temp_0
        c2fb_temp_2 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_1 = (c2fb_temp_0))))) <> 0))))
    End If
    If c2fb_temp_2 Then
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_4 = Cast(c2fb_c_int, local0->nInstCount)
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    Return local1
End Function
Private Function fts5ApiInst CDecl Alias "fts5ApiInst" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2467
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_2 = 1
    If (((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, ((local0)->csrflags And (Cast(c2fb_c_int, &H08ULL))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) = 0) Then
        c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, fts5CacheInstArray(local0))
        local1 = c2fb_temp_0
        c2fb_temp_2 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_1 = (c2fb_temp_0))))) <> 0))))
    End If
    If c2fb_temp_2 Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= local0->nInstCount)))) <> 0))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 25ULL))
            local1 = c2fb_temp_3
        Else
            c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_5 = Cast(c2fb_c_int, local0->aInst[Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, 3ULL)))])
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_7 = Cast(c2fb_c_int, local0->aInst[Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 1ULL)))])
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg4)))
            c2fb_temp_9 = Cast(c2fb_c_int, local0->aInst[Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 2ULL)))])
            (*c2fb_temp_8) = c2fb_temp_9
        End If
    End If
    Return local1
End Function
Private Function fts5ApiRowid CDecl Alias "fts5ApiRowid" (ByVal arg0 As c2fb_Fts5Context Ptr) As c2fb_int64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2490
    Return fts5CursorRowid(CPtr(c2fb_Fts5Cursor Ptr, arg0))
End Function
Private Function fts5ColumnSizeCb CDecl Alias "fts5ColumnSizeCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2494
    Dim local0 As c2fb_c_int Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(c2fb_c_int Ptr, arg0)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0001ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(((*local0))))
        c2fb_temp_1 = (*c2fb_temp_0)
        (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5ApiColumnSize CDecl Alias "fts5ApiColumnSize" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2511
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_Fts5FullTable Ptr
    Dim local2 As c2fb_Fts5Config Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local7 As Const ZString Ptr
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab)))
    local2 = CPtr(c2fb_Fts5Config Ptr, local1->p.pConfig)
    local3 = Cast(c2fb_c_int, &O0ULL)
    If (Cast(c2fb_c_int, ((local0)->csrflags And (Cast(c2fb_c_int, &H04ULL))))) Then
        If local2->bColumnsize Then
            local4 = fts5CursorRowid(local0)
            c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageDocsize(CPtr(c2fb_Fts5Storage Ptr, local1->pStorage), local4, local0->aColumnSize))
            local3 = c2fb_temp_0
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local2->zContent = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2->eContent = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
                ' C automatic storage declaration
                c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local5 = c2fb_temp_1
                While (-Cast(c2fb_c_int, ((local5 < local2->nCol))))
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->abUnindexed[local5]) = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_3 = CPtr(Long Ptr, @(local0->aColumnSize[local5]))
                        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                        (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
                        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
                    End If
                c2fb_flow_1:
                    c2fb_temp_2 = local5
                    local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                Wend
                c2fb_flow_0:
            Else
                ' C automatic storage declaration
                c2fb_temp_5 = Cast(c2fb_c_int, fts5SeekCursor(local0, Cast(c2fb_c_int, &O0ULL)))
                local3 = c2fb_temp_5
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local6 = c2fb_temp_6
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6 < local2->nCol)))) <> 0)))))
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->abUnindexed[local6]) = Cast(c2fb_c_int, &O0ULL))))) Then
                        local7 = Cast(c2fb_c_int, &O0ULL)
                        local8 = Cast(c2fb_c_int, &O0ULL)
                        c2fb_temp_8 = CPtr(Long Ptr, @(local0->aColumnSize[local6]))
                        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
                        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
                        c2fb_temp_10 = Cast(c2fb_c_int, fts5TextFromStmt(local2, CPtr(c2fb_sqlite3_stmt Ptr, local0->pStmt), local6, CPtr(Const ZString Ptr Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local8))))
                        local3 = c2fb_temp_10
                        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5Tokenize(local2, Cast(c2fb_c_int, &H0008ULL), local7, local8, CPtr(Any Ptr, CPtr(c2fb_c_int Ptr, @(local0->aColumnSize[local6]))), ProcPtr(fts5ColumnSizeCb)))
                            local3 = c2fb_temp_11
                        End If
                        sqlite3Fts5ClearLocale(local2)
                    End If
                c2fb_flow_3:
                    c2fb_temp_7 = local6
                    local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
                Wend
                c2fb_flow_2:
            End If
        End If
        c2fb_temp_12 = CPtr(Long Ptr, @((local0)->csrflags))
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_12)) And Cast(c2fb_c_int, (Not (Cast(c2fb_c_int, &H04ULL)))))))
        (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
        c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
        c2fb_temp_14 = (c2fb_temp_13)
    End If
    If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_15) = c2fb_temp_16
        c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local9 = c2fb_temp_17
        While (-Cast(c2fb_c_int, ((local9 < local2->nCol))))
            c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_19) + local0->aColumnSize[local9])))
            (*c2fb_temp_19) = c2fb_temp_20
        c2fb_flow_5:
            c2fb_temp_18 = local9
            local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
        Wend
        c2fb_flow_4:
    Else
        If (-Cast(c2fb_c_int, ((arg1 < local2->nCol)))) Then
            c2fb_temp_21 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_22 = Cast(c2fb_c_int, local0->aColumnSize[arg1])
            (*c2fb_temp_21) = c2fb_temp_22
        Else
            c2fb_temp_23 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_23) = c2fb_temp_24
            c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, 25ULL))
            local3 = c2fb_temp_25
        End If
    End If
    Return local3
End Function
Private Function fts5ApiSetAuxdata CDecl Alias "fts5ApiSetAuxdata" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_sqlite3_destructor_type) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2566
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_Fts5Auxdata Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Auxdata Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Auxdata Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_Fts5Auxdata Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Auxiliary_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Auxdata_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_Fts5Auxdata Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Auxdata_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Auxdata Ptr
    Type c2fb_callback_storage_9 As Sub CDecl(ByVal arg0 As Any Ptr)
    Dim c2fb_temp_9 As c2fb_callback_storage_9 Ptr
    Dim c2fb_temp_10 As c2fb_sqlite3_destructor_type
    Dim c2fb_temp_11 As Any Ptr Ptr
    Dim c2fb_temp_12 As Any Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Auxdata Ptr, CPtr(c2fb_Fts5Auxdata Ptr, local0->pAuxdata))
    local1 = c2fb_temp_0
    While local1
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Auxiliary Ptr, local1->pAux) = CPtr(c2fb_Fts5Auxiliary Ptr, local0->pAux))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Auxdata Ptr, CPtr(c2fb_Fts5Auxdata Ptr, local1->pNext))
        local1 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If local1 Then
        If CPtr(c2fb_sqlite3_destructor_type, local1->xDelete) Then
            CPtr(c2fb_sqlite3_destructor_type, local1->xDelete)(local1->pPtr)
        End If
    Else
        local2 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Auxdata Ptr, CPtr(c2fb_Fts5Auxdata Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local2)), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Auxdata))))))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            If arg2 Then
                arg2(arg1)
            End If
            Return local2
        End If
        c2fb_temp_3 = CPtr(c2fb_Fts5Auxiliary_ Ptr Ptr, @(local1->pAux))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, local0->pAux))
        (*c2fb_temp_3) = CPtr(c2fb_Fts5Auxiliary_ Ptr, c2fb_temp_4)
        c2fb_temp_4 = CPtr(c2fb_Fts5Auxiliary Ptr, (*c2fb_temp_3))
        c2fb_temp_5 = CPtr(c2fb_Fts5Auxdata_ Ptr Ptr, @(local1->pNext))
        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5Auxdata Ptr, CPtr(c2fb_Fts5Auxdata Ptr, local0->pAuxdata))
        (*c2fb_temp_5) = CPtr(c2fb_Fts5Auxdata_ Ptr, c2fb_temp_6)
        c2fb_temp_6 = CPtr(c2fb_Fts5Auxdata Ptr, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(c2fb_Fts5Auxdata_ Ptr Ptr, @(local0->pAuxdata))
        c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Auxdata Ptr, local1)
        (*c2fb_temp_7) = CPtr(c2fb_Fts5Auxdata_ Ptr, c2fb_temp_8)
        c2fb_temp_8 = CPtr(c2fb_Fts5Auxdata Ptr, (*c2fb_temp_7))
    End If
    c2fb_temp_9 = CPtr(c2fb_callback_storage_9 Ptr, @(local1->xDelete))
    c2fb_temp_10 = arg2
    (*c2fb_temp_9) = CPtr(Sub CDecl(ByVal arg0 As Any Ptr), c2fb_temp_10)
    c2fb_temp_10 = CPtr(c2fb_sqlite3_destructor_type, (*c2fb_temp_9))
    c2fb_temp_11 = CPtr(Any Ptr Ptr, @(local1->pPtr))
    c2fb_temp_12 = arg1
    (*c2fb_temp_11) = c2fb_temp_12
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5ApiGetAuxdata CDecl Alias "fts5ApiGetAuxdata" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int) As Any Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2601
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_Fts5Auxdata Ptr
    Dim local2 As Any Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Auxdata Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Auxdata Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As Any Ptr
    Type c2fb_callback_storage_5 As Sub CDecl(ByVal arg0 As Any Ptr)
    Dim c2fb_temp_5 As c2fb_callback_storage_5 Ptr
    Dim c2fb_temp_6 As c2fb_sqlite3_destructor_type

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Auxdata Ptr, CPtr(c2fb_Fts5Auxdata Ptr, local0->pAuxdata))
    local1 = c2fb_temp_0
    While local1
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Auxiliary Ptr, local1->pAux) = CPtr(c2fb_Fts5Auxiliary Ptr, local0->pAux))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Auxdata Ptr, CPtr(c2fb_Fts5Auxdata Ptr, local1->pNext))
        local1 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If local1 Then
        c2fb_temp_2 = local1->pPtr
        local2 = c2fb_temp_2
        If arg1 Then
            c2fb_temp_3 = CPtr(Any Ptr Ptr, @(local1->pPtr))
            c2fb_temp_4 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_3) = c2fb_temp_4
            c2fb_temp_5 = CPtr(c2fb_callback_storage_5 Ptr, @(local1->xDelete))
            c2fb_temp_6 = CPtr(c2fb_sqlite3_destructor_type, 0)
            (*c2fb_temp_5) = CPtr(Sub CDecl(ByVal arg0 As Any Ptr), c2fb_temp_6)
            c2fb_temp_6 = CPtr(c2fb_sqlite3_destructor_type, (*c2fb_temp_5))
        End If
    End If
    Return local2
End Function
Private Sub fts5ApiPhraseNext CDecl Alias "fts5ApiPhraseNext" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_Fts5PhraseIter Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2621
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_4 As Const UByte Ptr Ptr
    Dim c2fb_temp_5 As Const UByte Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_6 As Const UByte Ptr Ptr
    Dim c2fb_temp_7 As Const UByte Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Const UByte Ptr Ptr
    Dim c2fb_temp_13 As Const UByte Ptr
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg1->a >= arg1->b)))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_2) = c2fb_temp_3
    Else
        ' C automatic storage declaration
        c2fb_temp_4 = CPtr(Const UByte Ptr Ptr, @(arg1->a))
        c2fb_temp_5 = CPtr(Const UByte Ptr, ((*c2fb_temp_4) + c2fb_external_sqlite3Fts5GetVarint32(arg1->a, CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local0)))))))
        (*c2fb_temp_4) = c2fb_temp_5
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
            local1 = CPtr(c2fb_Fts5Config Ptr, (CPtr(c2fb_Fts5Table Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, (CPtr(c2fb_Fts5Cursor Ptr, arg0))->base.pVtab))))->pConfig)->nCol
            c2fb_temp_6 = CPtr(Const UByte Ptr Ptr, @(arg1->a))
            c2fb_temp_7 = CPtr(Const UByte Ptr, ((*c2fb_temp_6) + c2fb_external_sqlite3Fts5GetVarint32(arg1->a, CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local0)))))))
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_9 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, ((local0 >= local1)))), Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 1ULL))), local0)))
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_10) = c2fb_temp_11
            c2fb_temp_12 = CPtr(Const UByte Ptr Ptr, @(arg1->a))
            c2fb_temp_13 = CPtr(Const UByte Ptr, ((*c2fb_temp_12) + c2fb_external_sqlite3Fts5GetVarint32(arg1->a, CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local0)))))))
            (*c2fb_temp_12) = c2fb_temp_13
        End If
        c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_14) + (Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 2ULL)))))))
        (*c2fb_temp_14) = c2fb_temp_15
    End If
End Sub
Private Function fts5ApiPhraseFirst CDecl Alias "fts5ApiPhraseFirst" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5PhraseIter Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2646
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As Const UByte Ptr Ptr
    Dim c2fb_temp_1 As Const UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    ' C automatic storage declaration
    local2 = fts5CsrPoslist(local0, arg1, CPtr(Const UByte Ptr Ptr, @(arg2->a)), CPtr(c2fb_c_int Ptr, @(local1)))
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(Const UByte Ptr Ptr, @(arg2->b))
        c2fb_temp_1 = CPtr(Const UByte Ptr, (IIf(arg2->a, CPtr(UByte Ptr, @(arg2->a[local1])), CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_4) = c2fb_temp_5
        fts5ApiPhraseNext(arg0, arg2, arg3, arg4)
    End If
    Return local2
End Function
Private Sub fts5ApiPhraseNextColumn CDecl Alias "fts5ApiPhraseNextColumn" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_Fts5PhraseIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2665
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As Const UByte Ptr Ptr
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Const UByte Ptr Ptr
    Dim c2fb_temp_9 As Const UByte Ptr
    Dim c2fb_temp_10 As Const UByte Ptr Ptr
    Dim c2fb_temp_11 As Const UByte Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Config Ptr, (CPtr(c2fb_Fts5Table Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab))))->pConfig)
    If (-Cast(c2fb_c_int, ((local1->eDetail = Cast(c2fb_c_int, 2ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg1->a >= arg1->b)))) Then
            c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_0) = c2fb_temp_1
        Else
            ' C automatic storage declaration
            c2fb_temp_2 = CPtr(Const UByte Ptr Ptr, @(arg1->a))
            c2fb_temp_3 = CPtr(Const UByte Ptr, ((*c2fb_temp_2) + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg1->a[Cast(c2fb_c_int, &O0ULL)]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local2)))))))
            (*c2fb_temp_2) = c2fb_temp_3
            c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_4) + (Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 2ULL)))))))
            (*c2fb_temp_4) = c2fb_temp_5
        End If
    Else
        While Cast(c2fb_c_int, 1ULL)
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((arg1->a >= arg1->b)))) Then
                c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_6) = c2fb_temp_7
                Return
            End If
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->a[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, &H01ULL))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_8 = CPtr(Const UByte Ptr Ptr, @(arg1->a))
            c2fb_temp_9 = CPtr(Const UByte Ptr, ((*c2fb_temp_8) + c2fb_external_sqlite3Fts5GetVarint32(arg1->a, CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local3)))))))
            (*c2fb_temp_8) = c2fb_temp_9
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_10 = CPtr(Const UByte Ptr Ptr, @(arg1->a))
        c2fb_temp_11 = CPtr(Const UByte Ptr, ((*c2fb_temp_10) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg1->a[Cast(c2fb_c_int, 1ULL)]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @(((*arg2))))))))))
        (*c2fb_temp_10) = c2fb_temp_11
    End If
End Sub
' c2fb skipped fts5ApiPhraseFirstColumn: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 2695: fts5ApiPhraseFirstColumn: no complete C or FreeBASIC record layout for member c2fb_Fts5Sorter.aIdx
Private Function fts5ApiQueryToken CDecl Alias "fts5ApiQueryToken" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2747
    Dim local0 As c2fb_Fts5Cursor Ptr

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    Return c2fb_external_sqlite3Fts5ExprQueryToken(CPtr(c2fb_Fts5Expr Ptr, local0->pExpr), arg1, arg2, arg3, arg4)
End Function
Private Function fts5ApiInstToken CDecl Alias "fts5ApiInstToken" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2761
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_2 = 1
    If (((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, ((local0)->csrflags And (Cast(c2fb_c_int, &H08ULL))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) = 0) Then
        c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, fts5CacheInstArray(local0))
        local1 = c2fb_temp_0
        c2fb_temp_2 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_1 = (c2fb_temp_0))))) <> 0))))
    End If
    If c2fb_temp_2 Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= local0->nInstCount)))) <> 0))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 25ULL))
            local1 = c2fb_temp_3
        Else
            local2 = local0->aInst[Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, 3ULL)))]
            local3 = local0->aInst[Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 1ULL)))]
            local4 = local0->aInst[Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 2ULL)))]
            local5 = fts5CursorRowid(local0)
            c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprInstToken(CPtr(c2fb_Fts5Expr Ptr, local0->pExpr), local5, local2, local3, local4, arg2, arg3, arg4))
            local1 = c2fb_temp_4
        End If
    End If
    Return local1
End Function
Private Function fts5ApiColumnLocale CDecl Alias "fts5ApiColumnLocale" (ByVal arg0 As c2fb_Fts5Context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2795
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Cursor Ptr
    Dim local2 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_0 As Const ZString Ptr Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Const ZString Ptr Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local2 = CPtr(c2fb_Fts5Config Ptr, (CPtr(c2fb_Fts5Table Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, local1->base.pVtab))))->pConfig)
    c2fb_temp_0 = CPtr(Const ZString Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= local2->nCol)))) <> 0))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 25ULL))
        local0 = c2fb_temp_4
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->abUnindexed[arg1]) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5IsContentless(CPtr(c2fb_Fts5FullTable Ptr, CPtr(c2fb_sqlite3_vtab Ptr, local1->base.pVtab)), Cast(c2fb_c_int, 1ULL)))))) <> 0) AndAlso (local2->bLocale <> 0))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, fts5SeekCursor(local1, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_5
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                local3 = Cast(c2fb_c_int, &O0ULL)
                local4 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_6 = Cast(c2fb_c_int, fts5TextFromStmt(local2, CPtr(c2fb_sqlite3_stmt Ptr, local1->pStmt), arg1, CPtr(Const ZString Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local4))))
                local0 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_7 = CPtr(Const ZString Ptr Ptr, @((*arg2)))
                    c2fb_temp_8 = local2->t.pLocale
                    (*c2fb_temp_7) = c2fb_temp_8
                    c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                    c2fb_temp_10 = Cast(c2fb_c_int, local2->t.nLocale)
                    (*c2fb_temp_9) = c2fb_temp_10
                End If
                sqlite3Fts5ClearLocale(local2)
            End If
        End If
    End If
    Return local0
End Function
' c2fb skipped fts5ApiQueryPhrase: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 2862: fts5ApiQueryPhrase: assignment parser stopped at byte 25 (rc = xCallback(&sFts5Api, (Fts5Context*)pNew, pUserData)): , (Fts5Context*)pNew, pUserData)
' c2fb skipped fts5ApiInvoke: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 2899: fts5ApiInvoke: assignment parser stopped at byte 22 (pAux->xFunc(&sFts5Api, (Fts5Context*)pCsr, context, argc, argv)): , (Fts5Context*)pCsr, context, argc, argv)
Private Function fts5CursorFromCsrid CDecl Alias "fts5CursorFromCsrid" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Cursor Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2913
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Cursor Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, arg0->pCsr))
    local0 = c2fb_temp_0
    While local0
        If (-Cast(c2fb_c_int, ((local0->iCsrId = arg1)))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, local0->pNext))
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Sub fts5ResultError CDecl Alias "fts5ResultError" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ...)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2926
    Dim local0 As ZString Ptr
    Dim local1 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    Cva_Start(local1, arg1)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local1))
    local0 = c2fb_temp_0
    c2fb_external_sqlite3_result_error(arg0, CPtr(Const ZString Ptr, local0), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    Cva_End(local1)
End Sub
Private Sub fts5ApiCallback CDecl Alias "fts5ApiCallback" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2936
    Dim local0 As c2fb_Fts5Auxiliary Ptr
    Dim local1 As c2fb_Fts5Cursor Ptr
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_Fts5Cursor Ptr
    Dim local3 As c2fb_sqlite3_vtab Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_user_data(arg0))))
    local0 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_int64, c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, &O0ULL)]))
    local2 = c2fb_temp_1
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, fts5CursorFromCsrid(CPtr(c2fb_Fts5Global Ptr, local0->pGlobal), local2)))
    local1 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1->ePlan = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1->ePlan = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        fts5ResultError(arg0, StrPtr(!"no such cursor: %lld"), local2)
    Else
        local3 = CPtr(c2fb_sqlite3_vtab Ptr, local1->base.pVtab)
        fts5ApiInvoke(local0, local1, arg0, Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_value Ptr Ptr, @(arg2[Cast(c2fb_c_int, 1ULL)])))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local3->zErrMsg))
        c2fb_temp_3 = CPtr(ZString Ptr Ptr, @(local3->zErrMsg))
        c2fb_temp_4 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_3) = c2fb_temp_4
    End If
End Sub
Function sqlite3Fts5TableFromCsrid CDecl Alias "sqlite3Fts5TableFromCsrid" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Table Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2966
    Dim local0 As c2fb_Fts5Cursor Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Cursor Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Cursor Ptr, CPtr(c2fb_Fts5Cursor Ptr, fts5CursorFromCsrid(arg0, arg1)))
    local0 = c2fb_temp_0
    If local0 Then
        Return CPtr(c2fb_Fts5Table Ptr, CPtr(c2fb_sqlite3_vtab Ptr, local0->base.pVtab))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5PoslistBlob CDecl Alias "fts5PoslistBlob" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_Fts5Cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 2993
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5Buffer
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local4 As Const UByte Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local6 As Const UByte Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local8 As Const UByte Ptr
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local10 As Const UByte Ptr
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = c2fb_external_sqlite3Fts5ExprPhraseCount(CPtr(c2fb_Fts5Expr Ptr, arg1->pExpr))
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local3))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
    Select Case CPtr(c2fb_Fts5Config Ptr, (CPtr(c2fb_Fts5Table Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg1->base.pVtab))))->pConfig)->eDetail
        Case Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_1
            While (-Cast(c2fb_c_int, ((local0 < (Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL))))))))
                ' C automatic storage declaration
                local5 = c2fb_external_sqlite3Fts5ExprPoslist(CPtr(c2fb_Fts5Expr Ptr, arg1->pExpr), local0, CPtr(Const UByte Ptr Ptr, @(local4)))
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local3)), local5)
            c2fb_flow_2:
                c2fb_temp_2 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            Wend
            c2fb_flow_1:
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_3
            While (-Cast(c2fb_c_int, ((local0 < local2))))
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprPoslist(CPtr(c2fb_Fts5Expr Ptr, arg1->pExpr), local0, CPtr(Const UByte Ptr Ptr, @(local6))))
                local7 = c2fb_temp_5
                c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local3)), local7, local6)
            c2fb_flow_4:
                c2fb_temp_4 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
            Wend
            c2fb_flow_3:
        Case Cast(c2fb_c_int, 2ULL)
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < (Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))))))) <> 0)))))
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_8 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprPhraseCollist(CPtr(c2fb_Fts5Expr Ptr, arg1->pExpr), local0, CPtr(Const UByte Ptr Ptr, @(local8)), CPtr(c2fb_c_int Ptr, @(local9))))
                local1 = c2fb_temp_8
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local3)), local9)
            c2fb_flow_6:
                c2fb_temp_7 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            Wend
            c2fb_flow_5:
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_9
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < local2)))) <> 0)))))
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprPhraseCollist(CPtr(c2fb_Fts5Expr Ptr, arg1->pExpr), local0, CPtr(Const UByte Ptr Ptr, @(local10)), CPtr(c2fb_c_int Ptr, @(local11))))
                local1 = c2fb_temp_11
                c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local3)), local11, local10)
            c2fb_flow_8:
                c2fb_temp_10 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
            Wend
            c2fb_flow_7:
        Case Else
    End Select
    c2fb_flow_0:
    c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, local3.p), local3.n, ProcPtr(c2fb_external_sqlite3_free))
    Return local1
End Function
Private Function fts5ColumnMethod CDecl Alias "fts5ColumnMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_sqlite3_context Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3050
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_Fts5Cursor Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As c2fb_sqlite3_value Ptr
    Dim local5 As Const ZString Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr Ptr

    local0 = CPtr(c2fb_Fts5FullTable Ptr, (CPtr(c2fb_sqlite3_vtab Ptr, arg0->pVtab)))
    local1 = CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)
    local2 = CPtr(c2fb_Fts5Cursor Ptr, arg0)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local2->ePlan = Cast(c2fb_c_int, 3ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg2 = local1->nCol)))) Then
            c2fb_external_sqlite3_result_int64(arg1, local2->iSpecial)
        End If
    Else
        If (-Cast(c2fb_c_int, ((arg2 = local1->nCol)))) Then
            c2fb_external_sqlite3_result_int64(arg1, local2->iCsrId)
        Else
            If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, (local1->nCol + Cast(c2fb_c_int, 1ULL))))))) Then
                If (-Cast(c2fb_c_int, ((local2->ePlan = Cast(c2fb_c_int, 2ULL))))) Then
                    fts5PoslistBlob(arg1, local2)
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2->ePlan = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2->ePlan = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                        c2fb_temp_2 = 1
                        If ((CPtr(c2fb_Fts5Auxiliary Ptr, local2->pRank) <> 0) = 0) Then
                            c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
                            c2fb_temp_0 = Cast(c2fb_c_int, fts5FindRankFunction(local2))
                            local3 = c2fb_temp_0
                            c2fb_temp_2 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_1 = (c2fb_temp_0))))) <> 0))))
                        End If
                        If c2fb_temp_2 Then
                            fts5ApiInvoke(CPtr(c2fb_Fts5Auxiliary Ptr, local2->pRank), local2, arg1, local2->nRankArg, CPtr(c2fb_sqlite3_value Ptr Ptr, local2->apRankArg))
                        End If
                    End If
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (c2fb_external_sqlite3_vtab_nochange(arg1) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eContent <> Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                    c2fb_temp_3 = CPtr(ZString Ptr Ptr Ptr, @(local1->pzErrmsg))
                    c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(local0->p.base.zErrMsg))
                    (*c2fb_temp_3) = c2fb_temp_4
                    c2fb_temp_5 = Cast(c2fb_c_int, fts5SeekCursor(local2, Cast(c2fb_c_int, 1ULL)))
                    local3 = c2fb_temp_5
                    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                        local4 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(CPtr(c2fb_sqlite3_stmt Ptr, local2->pStmt), Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))))
                        If (-Cast(c2fb_c_int, (((local1->bLocale <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eContent = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso (sqlite3Fts5IsLocaleValue(local1, local4) <> 0))))) Then
                            local5 = Cast(c2fb_c_int, &O0ULL)
                            local6 = Cast(c2fb_c_int, &O0ULL)
                            c2fb_temp_6 = Cast(c2fb_c_int, fts5TextFromStmt(local1, CPtr(c2fb_sqlite3_stmt Ptr, local2->pStmt), arg2, CPtr(Const ZString Ptr Ptr, @(local5)), CPtr(c2fb_c_int Ptr, @(local6))))
                            local3 = c2fb_temp_6
                            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_external_sqlite3_result_text(arg1, local5, local6, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
                            End If
                            sqlite3Fts5ClearLocale(local1)
                        Else
                            c2fb_external_sqlite3_result_value(arg1, local4)
                        End If
                    End If
                    c2fb_temp_7 = CPtr(ZString Ptr Ptr Ptr, @(local1->pzErrmsg))
                    c2fb_temp_8 = CPtr(ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_7) = c2fb_temp_8
                End If
            End If
        End If
    End If
    Return local3
End Function
' c2fb skipped fts5FindFunctionMethod: outside the supported subset
' c2fb body diagnostic [unsupported-parameter-declaration] line 3121: fts5FindFunctionMethod: unsupported parameter declaration
Private Function fts5RenameMethod CDecl Alias "fts5RenameMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3146
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5FullTable Ptr
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageRename(CPtr(c2fb_Fts5Storage Ptr, local1->pStorage), arg1))
    local0 = c2fb_temp_0
    Return local0
End Function
Function sqlite3Fts5FlushToDisk CDecl Alias "sqlite3Fts5FlushToDisk" (ByVal arg0 As c2fb_Fts5Table Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3156
    fts5TripCursors(CPtr(c2fb_Fts5FullTable Ptr, arg0))
    Return c2fb_external_sqlite3Fts5StorageSync(CPtr(c2fb_Fts5Storage Ptr, (CPtr(c2fb_Fts5FullTable Ptr, arg0))->pStorage))
End Function
Private Function fts5SavepointMethod CDecl Alias "fts5SavepointMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3166
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' empty C statement
    c2fb_temp_0 = Cast(c2fb_c_int, sqlite3Fts5FlushToDisk(CPtr(c2fb_Fts5Table Ptr, arg0)))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(Long Ptr, @(local0->iSavepoint))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1 + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    End If
    Return local1
End Function
Private Function fts5ReleaseMethod CDecl Alias "fts5ReleaseMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3183
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' empty C statement
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1 + Cast(c2fb_c_int, 1ULL)))) < local0->iSavepoint)))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, sqlite3Fts5FlushToDisk(CPtr(c2fb_Fts5Table Ptr, @(local0->p))))
        local1 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(Long Ptr, @(local0->iSavepoint))
            c2fb_temp_2 = Cast(c2fb_c_int, arg1)
            (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
            c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        End If
    End If
    Return local1
End Function
Private Function fts5RollbackToMethod CDecl Alias "fts5RollbackToMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3201
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' empty C statement
    fts5TripCursors(local0)
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1 + Cast(c2fb_c_int, 1ULL)))) <= local0->iSavepoint)))) Then
        c2fb_temp_0 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)->pgsz))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageRollback(CPtr(c2fb_Fts5Storage Ptr, local0->pStorage)))
        local1 = c2fb_temp_2
    End If
    Return local1
End Function
Private Function fts5CreateAux CDecl Alias "fts5CreateAux" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_6, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3216
    Dim local0 As c2fb_Fts5Global Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Auxiliary Ptr
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Global_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Global Ptr
    Dim c2fb_temp_9 As Any Ptr Ptr
    Dim c2fb_temp_10 As Any Ptr
    Type c2fb_callback_storage_11 As c2fb_fts5_extension_function
    Dim c2fb_temp_11 As c2fb_callback_storage_11 Ptr
    Dim c2fb_temp_12 As c2fb_callback_6
    Type c2fb_callback_storage_13 As Sub CDecl(ByVal arg0 As Any Ptr)
    Dim c2fb_temp_13 As c2fb_callback_storage_13 Ptr
    Dim c2fb_temp_14 As c2fb_sqlite3_destructor_type
    Dim c2fb_temp_15 As c2fb_Fts5Auxiliary_ Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_17 As c2fb_Fts5Auxiliary_ Ptr Ptr
    Dim c2fb_temp_18 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_19 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Global Ptr, arg0)
    local1 = c2fb_external_sqlite3_overload_function(CPtr(c2fb_sqlite3 Ptr, local0->db), arg1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, c2fb_crt_strlen(arg1)) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))
        local3 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Auxiliary))) + Cast(c2fb_uint64, local3))))
        local4 = c2fb_temp_1
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local4))))
        local2 = c2fb_temp_2
        If local2 Then
            c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, local4)))
            c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(local2->zFunc))
            c2fb_temp_5 = CPtr(ZString Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, @(CPtr(c2fb_Fts5Auxiliary Ptr, local2)[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local2->zFunc), CPtr(Const Any Ptr, arg1), local3))
            c2fb_temp_7 = CPtr(c2fb_Fts5Global_ Ptr Ptr, @(local2->pGlobal))
            c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Global Ptr, local0)
            (*c2fb_temp_7) = CPtr(c2fb_Fts5Global_ Ptr, c2fb_temp_8)
            c2fb_temp_8 = CPtr(c2fb_Fts5Global Ptr, (*c2fb_temp_7))
            c2fb_temp_9 = CPtr(Any Ptr Ptr, @(local2->pUserData))
            c2fb_temp_10 = arg2
            (*c2fb_temp_9) = c2fb_temp_10
            c2fb_temp_11 = CPtr(c2fb_callback_storage_11 Ptr, @(local2->xFunc))
            c2fb_temp_12 = arg3
            (*c2fb_temp_11) = CPtr(c2fb_fts5_extension_function, c2fb_temp_12)
            c2fb_temp_12 = CPtr(c2fb_callback_6, (*c2fb_temp_11))
            c2fb_temp_13 = CPtr(c2fb_callback_storage_13 Ptr, @(local2->xDestroy))
            c2fb_temp_14 = arg4
            (*c2fb_temp_13) = CPtr(Sub CDecl(ByVal arg0 As Any Ptr), c2fb_temp_14)
            c2fb_temp_14 = CPtr(c2fb_sqlite3_destructor_type, (*c2fb_temp_13))
            c2fb_temp_15 = CPtr(c2fb_Fts5Auxiliary_ Ptr Ptr, @(local2->pNext))
            c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, local0->pAux))
            (*c2fb_temp_15) = CPtr(c2fb_Fts5Auxiliary_ Ptr, c2fb_temp_16)
            c2fb_temp_16 = CPtr(c2fb_Fts5Auxiliary Ptr, (*c2fb_temp_15))
            c2fb_temp_17 = CPtr(c2fb_Fts5Auxiliary_ Ptr Ptr, @(local0->pAux))
            c2fb_temp_18 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, local2)
            (*c2fb_temp_17) = CPtr(c2fb_Fts5Auxiliary_ Ptr, c2fb_temp_18)
            c2fb_temp_18 = CPtr(c2fb_Fts5Auxiliary Ptr, (*c2fb_temp_17))
        Else
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local1 = c2fb_temp_19
        End If
    End If
    Return local1
End Function
Private Function fts5NewTokenizerModule CDecl Alias "fts5NewTokenizerModule" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_sqlite3_destructor_type, ByVal arg4 As c2fb_Fts5TokenizerModule Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3266
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5TokenizerModule Ptr
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_3 As c2fb_Fts5TokenizerModule Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As Any Ptr Ptr
    Dim c2fb_temp_9 As Any Ptr
    Type c2fb_callback_storage_10 As Sub CDecl(ByVal arg0 As Any Ptr)
    Dim c2fb_temp_10 As c2fb_callback_storage_10 Ptr
    Dim c2fb_temp_11 As c2fb_sqlite3_destructor_type
    Dim c2fb_temp_12 As c2fb_Fts5TokenizerModule_ Ptr Ptr
    Dim c2fb_temp_13 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_14 As c2fb_Fts5TokenizerModule_ Ptr Ptr
    Dim c2fb_temp_15 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_16 As c2fb_Fts5TokenizerModule_ Ptr Ptr
    Dim c2fb_temp_17 As c2fb_Fts5TokenizerModule Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, c2fb_crt_strlen(arg1)) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))
    local2 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5TokenizerModule))) + Cast(c2fb_uint64, local2))))
    local3 = c2fb_temp_1
    c2fb_temp_3 = CPtr(c2fb_Fts5TokenizerModule Ptr Ptr, @((*arg4)))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), local3))))
    local1 = c2fb_temp_2
    c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, c2fb_temp_2)
    (*c2fb_temp_3) = c2fb_temp_4
    If local1 Then
        c2fb_temp_5 = CPtr(ZString Ptr Ptr, @(local1->zName))
        c2fb_temp_6 = CPtr(ZString Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, @(CPtr(c2fb_Fts5TokenizerModule Ptr, local1)[Cast(c2fb_c_int, 1ULL)])))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->zName), CPtr(Const Any Ptr, arg1), local2))
        c2fb_temp_8 = CPtr(Any Ptr Ptr, @(local1->pUserData))
        c2fb_temp_9 = arg2
        (*c2fb_temp_8) = c2fb_temp_9
        c2fb_temp_10 = CPtr(c2fb_callback_storage_10 Ptr, @(local1->xDestroy))
        c2fb_temp_11 = arg3
        (*c2fb_temp_10) = CPtr(Sub CDecl(ByVal arg0 As Any Ptr), c2fb_temp_11)
        c2fb_temp_11 = CPtr(c2fb_sqlite3_destructor_type, (*c2fb_temp_10))
        c2fb_temp_12 = CPtr(c2fb_Fts5TokenizerModule_ Ptr Ptr, @(local1->pNext))
        c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, arg0->pTok))
        (*c2fb_temp_12) = CPtr(c2fb_Fts5TokenizerModule_ Ptr, c2fb_temp_13)
        c2fb_temp_13 = CPtr(c2fb_Fts5TokenizerModule Ptr, (*c2fb_temp_12))
        c2fb_temp_14 = CPtr(c2fb_Fts5TokenizerModule_ Ptr Ptr, @(arg0->pTok))
        c2fb_temp_15 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, local1)
        (*c2fb_temp_14) = CPtr(c2fb_Fts5TokenizerModule_ Ptr, c2fb_temp_15)
        c2fb_temp_15 = CPtr(c2fb_Fts5TokenizerModule Ptr, (*c2fb_temp_14))
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenizerModule Ptr, local1->pNext) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_16 = CPtr(c2fb_Fts5TokenizerModule_ Ptr Ptr, @(arg0->pDfltTok))
            c2fb_temp_17 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, local1)
            (*c2fb_temp_16) = CPtr(c2fb_Fts5TokenizerModule_ Ptr, c2fb_temp_17)
            c2fb_temp_17 = CPtr(c2fb_Fts5TokenizerModule Ptr, (*c2fb_temp_16))
        End If
    End If
    Return local0
End Function
Private Function fts5VtoVCreate CDecl Alias "fts5VtoVCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3314
    Dim local0 As c2fb_Fts5TokenizerModule Ptr
    Dim local1 As c2fb_Fts5VtoVTokenizer Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5VtoVTokenizer Ptr
    Dim c2fb_temp_1 As c2fb_fts5_tokenizer_ Ptr
    Dim c2fb_temp_2 As c2fb_fts5_tokenizer
    Dim c2fb_temp_3 As c2fb_fts5_tokenizer_v2_ Ptr
    Dim c2fb_temp_4 As c2fb_fts5_tokenizer_v2
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_Fts5VtoVTokenizer Ptr
    Dim c2fb_temp_10 As c2fb_Fts5Tokenizer Ptr Ptr
    Dim c2fb_temp_11 As c2fb_Fts5Tokenizer Ptr

    local0 = CPtr(c2fb_Fts5TokenizerModule Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5VtoVTokenizer Ptr, CPtr(c2fb_Fts5VtoVTokenizer Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local2)), Cast(c2fb_size_t, SizeOf(c2fb_Fts5VtoVTokenizer))))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(c2fb_fts5_tokenizer_ Ptr, @(local1->x1))
        c2fb_temp_2 = local0->x1
        (*c2fb_temp_1) = Cast(c2fb_fts5_tokenizer_, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_fts5_tokenizer, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(c2fb_fts5_tokenizer_v2_ Ptr, @(local1->x2))
        c2fb_temp_4 = local0->x2
        (*c2fb_temp_3) = Cast(c2fb_fts5_tokenizer_v2_, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_fts5_tokenizer_v2, (*c2fb_temp_3))
        c2fb_temp_5 = CPtr(Long Ptr, @(local1->bV2Native))
        c2fb_temp_6 = Cast(c2fb_c_int, local0->bV2Native)
        (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        If local0->bV2Native Then
            c2fb_temp_7 = Cast(c2fb_c_int, CPtr(c2fb_callback_91, local0->x2.xCreate)(local0->pUserData, arg1, arg2, CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @(local1->pReal))))
            local2 = c2fb_temp_7
        Else
            c2fb_temp_8 = Cast(c2fb_c_int, CPtr(c2fb_callback_91, local0->x1.xCreate)(local0->pUserData, arg1, arg2, CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @(local1->pReal))))
            local2 = c2fb_temp_8
        End If
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
            c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5VtoVTokenizer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_9
        End If
    End If
    c2fb_temp_10 = CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @((*arg3)))
    c2fb_temp_11 = CPtr(c2fb_Fts5Tokenizer Ptr, local1)
    (*c2fb_temp_10) = c2fb_temp_11
    Return local2
End Function
Private Sub fts5VtoVDelete CDecl Alias "fts5VtoVDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3347
    Dim local0 As c2fb_Fts5VtoVTokenizer Ptr

    local0 = CPtr(c2fb_Fts5VtoVTokenizer Ptr, arg0)
    If local0 Then
        If local0->bV2Native Then
            CPtr(c2fb_callback_92, local0->x2.xDelete)(CPtr(c2fb_Fts5Tokenizer Ptr, local0->pReal))
        Else
            CPtr(c2fb_callback_92, local0->x1.xDelete)(CPtr(c2fb_Fts5Tokenizer Ptr, local0->pReal))
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Function fts5V1toV2Tokenize CDecl Alias "fts5V1toV2Tokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_73) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3364
    Dim local0 As c2fb_Fts5VtoVTokenizer Ptr

    local0 = CPtr(c2fb_Fts5VtoVTokenizer Ptr, arg0)
    ' C unused-parameter annotation
    Return CPtr(c2fb_callback_93, local0->x2.xTokenize)(CPtr(c2fb_Fts5Tokenizer Ptr, local0->pReal), arg1, arg2, arg3, arg4, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg5)
End Function
Private Function fts5V2toV1Tokenize CDecl Alias "fts5V2toV1Tokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_callback_73) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3379
    Dim local0 As c2fb_Fts5VtoVTokenizer Ptr

    local0 = CPtr(c2fb_Fts5VtoVTokenizer Ptr, arg0)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    Return CPtr(c2fb_callback_94, local0->x1.xTokenize)(CPtr(c2fb_Fts5Tokenizer Ptr, local0->pReal), arg1, arg2, arg3, arg4, arg7)
End Function
Private Function fts5CreateTokenizer_v2 CDecl Alias "fts5CreateTokenizer_v2" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_fts5_tokenizer_v2 Ptr, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3396
    Dim local0 As c2fb_Fts5Global Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_fts5_tokenizer_v2_ Ptr
    Dim c2fb_temp_3 As c2fb_fts5_tokenizer_v2
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Type c2fb_callback_storage_6 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Tokenizer_ Ptr Ptr) As Long
    Dim c2fb_temp_6 As c2fb_callback_storage_6 Ptr
    Dim c2fb_temp_7 As c2fb_callback_91
    Type c2fb_callback_storage_8 As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Long, ByVal arg5 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long) As Long
    Dim c2fb_temp_8 As c2fb_callback_storage_8 Ptr
    Dim c2fb_temp_9 As c2fb_callback_94
    Type c2fb_callback_storage_10 As Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr)
    Dim c2fb_temp_10 As c2fb_callback_storage_10 Ptr
    Dim c2fb_temp_11 As c2fb_callback_92

    local0 = CPtr(c2fb_Fts5Global Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg3->iVersion > Cast(c2fb_c_int, 2ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local1 = c2fb_temp_0
    Else
        local2 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_1 = Cast(c2fb_c_int, fts5NewTokenizerModule(local0, arg1, arg2, arg4, CPtr(c2fb_Fts5TokenizerModule Ptr Ptr, @(local2))))
        local1 = c2fb_temp_1
        If local2 Then
            c2fb_temp_2 = CPtr(c2fb_fts5_tokenizer_v2_ Ptr, @(local2->x2))
            c2fb_temp_3 = (*arg3)
            (*c2fb_temp_2) = Cast(c2fb_fts5_tokenizer_v2_, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_fts5_tokenizer_v2, (*c2fb_temp_2))
            c2fb_temp_4 = CPtr(Long Ptr, @(local2->bV2Native))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
            c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            c2fb_temp_6 = CPtr(c2fb_callback_storage_6 Ptr, @(local2->x1.xCreate))
            c2fb_temp_7 = ProcPtr(fts5VtoVCreate)
            (*c2fb_temp_6) = CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Tokenizer_ Ptr Ptr) As Long, c2fb_temp_7)
            c2fb_temp_7 = CPtr(c2fb_callback_91, (*c2fb_temp_6))
            c2fb_temp_8 = CPtr(c2fb_callback_storage_8 Ptr, @(local2->x1.xTokenize))
            c2fb_temp_9 = ProcPtr(fts5V1toV2Tokenize)
            (*c2fb_temp_8) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Long, ByVal arg5 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long) As Long, c2fb_temp_9)
            c2fb_temp_9 = CPtr(c2fb_callback_94, (*c2fb_temp_8))
            c2fb_temp_10 = CPtr(c2fb_callback_storage_10 Ptr, @(local2->x1.xDelete))
            c2fb_temp_11 = ProcPtr(fts5VtoVDelete)
            (*c2fb_temp_10) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr), c2fb_temp_11)
            c2fb_temp_11 = CPtr(c2fb_callback_92, (*c2fb_temp_10))
        End If
    End If
    Return local1
End Function
Private Function fts5CreateTokenizer CDecl Alias "fts5CreateTokenizer" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_fts5_tokenizer Ptr, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3426
    Dim local0 As c2fb_Fts5TokenizerModule Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_fts5_tokenizer_ Ptr
    Dim c2fb_temp_2 As c2fb_fts5_tokenizer
    Type c2fb_callback_storage_3 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Tokenizer_ Ptr Ptr) As Long
    Dim c2fb_temp_3 As c2fb_callback_storage_3 Ptr
    Dim c2fb_temp_4 As c2fb_callback_91
    Type c2fb_callback_storage_5 As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Long, ByVal arg5 As Const ZString Ptr, ByVal arg6 As Long, ByVal arg7 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long) As Long
    Dim c2fb_temp_5 As c2fb_callback_storage_5 Ptr
    Dim c2fb_temp_6 As c2fb_callback_93
    Type c2fb_callback_storage_7 As Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr)
    Dim c2fb_temp_7 As c2fb_callback_storage_7 Ptr
    Dim c2fb_temp_8 As c2fb_callback_92

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, fts5NewTokenizerModule(CPtr(c2fb_Fts5Global Ptr, arg0), arg1, arg2, arg4, CPtr(c2fb_Fts5TokenizerModule Ptr Ptr, @(local0))))
    local1 = c2fb_temp_0
    If local0 Then
        c2fb_temp_1 = CPtr(c2fb_fts5_tokenizer_ Ptr, @(local0->x1))
        c2fb_temp_2 = (*arg3)
        (*c2fb_temp_1) = Cast(c2fb_fts5_tokenizer_, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_fts5_tokenizer, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(c2fb_callback_storage_3 Ptr, @(local0->x2.xCreate))
        c2fb_temp_4 = ProcPtr(fts5VtoVCreate)
        (*c2fb_temp_3) = CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Tokenizer_ Ptr Ptr) As Long, c2fb_temp_4)
        c2fb_temp_4 = CPtr(c2fb_callback_91, (*c2fb_temp_3))
        c2fb_temp_5 = CPtr(c2fb_callback_storage_5 Ptr, @(local0->x2.xTokenize))
        c2fb_temp_6 = ProcPtr(fts5V2toV1Tokenize)
        (*c2fb_temp_5) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Long, ByVal arg5 As Const ZString Ptr, ByVal arg6 As Long, ByVal arg7 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long) As Long, c2fb_temp_6)
        c2fb_temp_6 = CPtr(c2fb_callback_93, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(c2fb_callback_storage_7 Ptr, @(local0->x2.xDelete))
        c2fb_temp_8 = ProcPtr(fts5VtoVDelete)
        (*c2fb_temp_7) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer_ Ptr), c2fb_temp_8)
        c2fb_temp_8 = CPtr(c2fb_callback_92, (*c2fb_temp_7))
    End If
    Return local1
End Function
Private Function fts5LocateTokenizer CDecl Alias "fts5LocateTokenizer" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_Fts5TokenizerModule Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3453
    Dim local0 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_0 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_1 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_2 As c2fb_Fts5TokenizerModule Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, arg0->pDfltTok))
        local0 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, arg0->pTok))
        local0 = c2fb_temp_1
        While local0
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(arg1, CPtr(Const ZString Ptr, local0->zName)) = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, local0->pNext))
            local0 = c2fb_temp_2
        Wend
        c2fb_flow_0:
    End If
    Return local0
End Function
Private Function fts5FindTokenizer_v2 CDecl Alias "fts5FindTokenizer_v2" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_fts5_tokenizer_v2 Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3474
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_0 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_1 As Any Ptr Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_fts5_tokenizer_v2 Ptr Ptr
    Dim c2fb_temp_6 As c2fb_fts5_tokenizer_v2 Ptr
    Dim c2fb_temp_7 As c2fb_fts5_tokenizer_v2 Ptr Ptr
    Dim c2fb_temp_8 As c2fb_fts5_tokenizer_v2 Ptr
    Dim c2fb_temp_9 As Any Ptr Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, fts5LocateTokenizer(CPtr(c2fb_Fts5Global Ptr, arg0), arg1)))
    local1 = c2fb_temp_0
    If local1 Then
        If local1->bV2Native Then
            c2fb_temp_1 = CPtr(Any Ptr Ptr, @((*arg2)))
            c2fb_temp_2 = local1->pUserData
            (*c2fb_temp_1) = c2fb_temp_2
        Else
            c2fb_temp_3 = CPtr(Any Ptr Ptr, @((*arg2)))
            c2fb_temp_4 = CPtr(Any Ptr, local1)
            (*c2fb_temp_3) = c2fb_temp_4
        End If
        c2fb_temp_5 = CPtr(c2fb_fts5_tokenizer_v2 Ptr Ptr, @((*arg3)))
        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_fts5_tokenizer_v2 Ptr, CPtr(c2fb_fts5_tokenizer_v2 Ptr, @(local1->x2)))
        (*c2fb_temp_5) = c2fb_temp_6
    Else
        c2fb_temp_7 = CPtr(c2fb_fts5_tokenizer_v2 Ptr Ptr, @((*arg3)))
        c2fb_temp_8 = CPtr(_c2fb_record_c2fb_fts5_tokenizer_v2 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = CPtr(Any Ptr Ptr, @((*arg2)))
        c2fb_temp_10 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_9) = c2fb_temp_10
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_11
    End If
    Return local0
End Function
Private Function fts5FindTokenizer CDecl Alias "fts5FindTokenizer" (ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_fts5_tokenizer Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3504
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_0 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_1 As Any Ptr Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_fts5_tokenizer Ptr
    Dim c2fb_temp_6 As c2fb_fts5_tokenizer
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As Any Ptr Ptr
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, fts5LocateTokenizer(CPtr(c2fb_Fts5Global Ptr, arg0), arg1)))
    local1 = c2fb_temp_0
    If local1 Then
        If (-Cast(c2fb_c_int, ((local1->bV2Native = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(Any Ptr Ptr, @((*arg2)))
            c2fb_temp_2 = local1->pUserData
            (*c2fb_temp_1) = c2fb_temp_2
        Else
            c2fb_temp_3 = CPtr(Any Ptr Ptr, @((*arg2)))
            c2fb_temp_4 = CPtr(Any Ptr, local1)
            (*c2fb_temp_3) = c2fb_temp_4
        End If
        c2fb_temp_5 = CPtr(c2fb_fts5_tokenizer Ptr, @((*arg3)))
        c2fb_temp_6 = local1->x1
        (*c2fb_temp_5) = c2fb_temp_6
    Else
        c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg3), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_fts5_tokenizer))))
        c2fb_temp_8 = CPtr(Any Ptr Ptr, @((*arg2)))
        c2fb_temp_9 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_8) = c2fb_temp_9
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_10
    End If
    Return local0
End Function
Function sqlite3Fts5LoadTokenizer CDecl Alias "sqlite3Fts5LoadTokenizer" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3533
    Dim local0 As Const ZString Ptr Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5TokenizerModule Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As c2fb_callback_91
    Dim c2fb_temp_2 As c2fb_callback_91
    Dim c2fb_temp_3 As c2fb_fts5_tokenizer_v2_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_fts5_tokenizer_v2 Ptr
    Dim c2fb_temp_5 As c2fb_fts5_tokenizer_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_fts5_tokenizer Ptr
    Dim c2fb_temp_7 As c2fb_callback_91
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_fts5_tokenizer_ Ptr Ptr
    Dim c2fb_temp_12 As c2fb_fts5_tokenizer Ptr
    Dim c2fb_temp_13 As c2fb_fts5_tokenizer_v2_ Ptr Ptr
    Dim c2fb_temp_14 As c2fb_fts5_tokenizer_v2 Ptr
    Dim c2fb_temp_15 As c2fb_Fts5Tokenizer_ Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5Tokenizer Ptr

    local0 = arg0->t.azArg
    local1 = arg0->t.nArg
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, fts5LocateTokenizer(CPtr(c2fb_Fts5Global Ptr, arg0->pGlobal), IIf((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))), CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))), local0[Cast(c2fb_c_int, &O0ULL)]))))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_1
        c2fb_external_sqlite3Fts5ConfigErrmsg(arg0, StrPtr(!"no such tokenizer: %s"), local0[Cast(c2fb_c_int, &O0ULL)])
    Else
        local4 = Cast(c2fb_c_int, &O0ULL)
        If local2->bV2Native Then
            c2fb_temp_2 = CPtr(c2fb_callback_91, local2->x2.xCreate)
            local4 = c2fb_temp_2
            c2fb_temp_3 = CPtr(c2fb_fts5_tokenizer_v2_ Ptr Ptr, @(arg0->t.pApi2))
            c2fb_temp_4 = CPtr(_c2fb_record_c2fb_fts5_tokenizer_v2 Ptr, CPtr(c2fb_fts5_tokenizer_v2 Ptr, @(local2->x2)))
            (*c2fb_temp_3) = CPtr(c2fb_fts5_tokenizer_v2_ Ptr, c2fb_temp_4)
            c2fb_temp_4 = CPtr(c2fb_fts5_tokenizer_v2 Ptr, (*c2fb_temp_3))
        Else
            c2fb_temp_5 = CPtr(c2fb_fts5_tokenizer_ Ptr Ptr, @(arg0->t.pApi1))
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_fts5_tokenizer Ptr, CPtr(c2fb_fts5_tokenizer Ptr, @(local2->x1)))
            (*c2fb_temp_5) = CPtr(c2fb_fts5_tokenizer_ Ptr, c2fb_temp_6)
            c2fb_temp_6 = CPtr(c2fb_fts5_tokenizer Ptr, (*c2fb_temp_5))
            c2fb_temp_7 = CPtr(c2fb_callback_91, local2->x1.xCreate)
            local4 = c2fb_temp_7
        End If
        c2fb_temp_8 = Cast(c2fb_c_int, local4(local2->pUserData, (IIf(local0, CPtr(Const ZString Ptr Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])), CPtr(Const ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))), (IIf(local1, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL))), CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @(arg0->t.pTok))))
        local3 = c2fb_temp_8
        If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 7ULL))))) Then
                c2fb_external_sqlite3Fts5ConfigErrmsg(arg0, StrPtr(!"error in tokenizer constructor"))
            End If
        Else
            If (-Cast(c2fb_c_int, ((local2->bV2Native = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_9 = CPtr(Long Ptr, @(arg0->t.ePattern))
                c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5TokenizerPattern(CPtr(c2fb_callback_91, local2->x1.xCreate), CPtr(c2fb_Fts5Tokenizer Ptr, arg0->t.pTok)))
                (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
                c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_11 = CPtr(c2fb_fts5_tokenizer_ Ptr Ptr, @(arg0->t.pApi1))
        c2fb_temp_12 = CPtr(_c2fb_record_c2fb_fts5_tokenizer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_11) = CPtr(c2fb_fts5_tokenizer_ Ptr, c2fb_temp_12)
        c2fb_temp_12 = CPtr(c2fb_fts5_tokenizer Ptr, (*c2fb_temp_11))
        c2fb_temp_13 = CPtr(c2fb_fts5_tokenizer_v2_ Ptr Ptr, @(arg0->t.pApi2))
        c2fb_temp_14 = CPtr(_c2fb_record_c2fb_fts5_tokenizer_v2 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_13) = CPtr(c2fb_fts5_tokenizer_v2_ Ptr, c2fb_temp_14)
        c2fb_temp_14 = CPtr(c2fb_fts5_tokenizer_v2 Ptr, (*c2fb_temp_13))
        c2fb_temp_15 = CPtr(c2fb_Fts5Tokenizer_ Ptr Ptr, @(arg0->t.pTok))
        c2fb_temp_16 = CPtr(c2fb_Fts5Tokenizer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_15) = CPtr(c2fb_Fts5Tokenizer_ Ptr, c2fb_temp_16)
        c2fb_temp_16 = CPtr(c2fb_Fts5Tokenizer Ptr, (*c2fb_temp_15))
    End If
    Return local3
End Function
Private Sub fts5ModuleDestroy CDecl Alias "fts5ModuleDestroy" (ByVal arg0 As Any Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3584
    Dim local0 As c2fb_Fts5TokenizerModule Ptr
    Dim local1 As c2fb_Fts5TokenizerModule Ptr
    Dim local2 As c2fb_Fts5Auxiliary Ptr
    Dim local3 As c2fb_Fts5Auxiliary Ptr
    Dim local4 As c2fb_Fts5Global Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Auxiliary Ptr
    Dim c2fb_temp_3 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_4 As c2fb_Fts5TokenizerModule Ptr
    Dim c2fb_temp_5 As c2fb_Fts5TokenizerModule Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = CPtr(c2fb_Fts5Global Ptr, arg0)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, local4->pAux))
    local2 = c2fb_temp_0
    While local2
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, CPtr(c2fb_Fts5Auxiliary Ptr, local2->pNext))
        local3 = c2fb_temp_2
        If CPtr(c2fb_sqlite3_destructor_type, local2->xDestroy) Then
            CPtr(c2fb_sqlite3_destructor_type, local2->xDestroy)(local2->pUserData)
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Auxiliary Ptr, local3)
        local2 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, local4->pTok))
    local0 = c2fb_temp_3
    While local0
        c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, CPtr(c2fb_Fts5TokenizerModule Ptr, local0->pNext))
        local1 = c2fb_temp_5
        If CPtr(c2fb_sqlite3_destructor_type, local0->xDestroy) Then
            CPtr(c2fb_sqlite3_destructor_type, local0->xDestroy)(local0->pUserData)
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    c2fb_flow_3:
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5TokenizerModule Ptr, local1)
        local0 = c2fb_temp_4
    Wend
    c2fb_flow_2:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
End Sub
Private Sub fts5Fts5Func CDecl Alias "fts5Fts5Func" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3608
    Dim local0 As c2fb_Fts5Global Ptr
    Dim local1 As c2fb_fts5_api Ptr Ptr
    Dim c2fb_temp_0 As c2fb_fts5_api Ptr Ptr
    Dim c2fb_temp_1 As c2fb_fts5_api Ptr Ptr
    Dim c2fb_temp_2 As c2fb_fts5_api Ptr

    local0 = CPtr(c2fb_Fts5Global Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_user_data(arg0)))
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_fts5_api Ptr Ptr, CPtr(c2fb_fts5_api Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_value_pointer(arg2[Cast(c2fb_c_int, &O0ULL)], StrPtr(!"fts5_api_ptr")))))
    local1 = c2fb_temp_0
    If local1 Then
        c2fb_temp_1 = CPtr(c2fb_fts5_api Ptr Ptr, @((*local1)))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_fts5_api Ptr, CPtr(c2fb_fts5_api Ptr, @(local0->api)))
        (*c2fb_temp_1) = c2fb_temp_2
    End If
End Sub
Private Sub fts5SourceIdFunc CDecl Alias "fts5SourceIdFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3624
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_external_sqlite3_result_text(arg0, StrPtr(!"--FTS5-SOURCE-ID--"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
End Sub
Private Sub fts5LocaleFunc CDecl Alias "fts5LocaleFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3648
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_int64
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_int64
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim local4 As c2fb_Fts5Global Ptr
    Dim local5 As UByte Ptr
    Dim local6 As UByte Ptr
    Dim local7 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte Ptr
    Dim c2fb_temp_13 As UByte
    Dim c2fb_temp_14 As Any Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, &O0ULL)])))
    local0 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_int64, c2fb_external_sqlite3_value_bytes(arg2[Cast(c2fb_c_int, &O0ULL)]))
    local1 = c2fb_temp_1
    c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, 1ULL)])))
    local2 = c2fb_temp_2
    c2fb_temp_3 = Cast(c2fb_int64, c2fb_external_sqlite3_value_bytes(arg2[Cast(c2fb_c_int, 1ULL)]))
    local3 = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 0))))) <> 0))))) Then
        c2fb_external_sqlite3_result_text(arg0, local2, local3, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
    Else
        local4 = CPtr(c2fb_Fts5Global Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_user_data(arg0)))
        local5 = Cast(c2fb_c_int, &O0ULL)
        local6 = Cast(c2fb_c_int, &O0ULL)
        local7 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_c_uint)))))) + local1)) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))) + local3)))
        local7 = c2fb_temp_4
        c2fb_temp_5 = CPtr(UByte Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local7)))
        local5 = c2fb_temp_5
        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_result_error_nomem(arg0)
            Return
        End If
        c2fb_temp_6 = local5
        local6 = c2fb_temp_6
        c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local6), CPtr(Const Any Ptr, CPtr(Const UByte Ptr, CPtr(c2fb_c_uint Ptr, (@local4->aLocaleHdr(0))))), (Cast(c2fb_c_int, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_c_uint)))))))
        c2fb_temp_8 = CPtr(UByte Ptr, (local6 + (Cast(c2fb_c_int, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_c_uint)))))))
        local6 = c2fb_temp_8
        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local6), CPtr(Const Any Ptr, local0), local1))
        c2fb_temp_10 = CPtr(UByte Ptr, (local6 + local1))
        local6 = c2fb_temp_10
        c2fb_temp_11 = local6
        local6 = (c2fb_temp_11 + 1)
        c2fb_temp_12 = CPtr(UByte Ptr, @(((*c2fb_temp_11))))
        c2fb_temp_13 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
        (*c2fb_temp_12) = c2fb_temp_13
        If local2 Then
            c2fb_temp_14 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local6), CPtr(Const Any Ptr, local2), local3))
        End If
        ' C unused-parameter annotation
        c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, local5), local7, ProcPtr(c2fb_external_sqlite3_free))
    End If
End Sub
Private Sub fts5InsttokenFunc CDecl Alias "fts5InsttokenFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3698
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_external_sqlite3_result_value(arg0, arg2[Cast(c2fb_c_int, &O0ULL)])
    c2fb_external_sqlite3_result_subtype(arg0, Cast(c2fb_c_int, 73ULL))
End Sub
Private Function fts5ShadowName CDecl Alias "fts5ShadowName" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3713
    Static local0(0 To 4) As Const ZString Ptr = {Cast(Const ZString Ptr, StrPtr(!"config")), Cast(Const ZString Ptr, StrPtr(!"content")), Cast(Const ZString Ptr, StrPtr(!"data")), Cast(Const ZString Ptr, StrPtr(!"docsize")), Cast(Const ZString Ptr, StrPtr(!"idx"))}
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint

    ' C static array storage
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((Cast(c2fb_uint64, local1) < Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (5ULL * SizeOf(Const ZString Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Const ZString Ptr)))))))))
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(arg0, local0(local1)) = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5IntegrityMethod CDecl Alias "fts5IntegrityMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3729
    Dim local0 As c2fb_Fts5FullTable Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_10 As ZString Ptr Ptr

    local0 = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(ZString Ptr Ptr Ptr, @(CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)->pzErrmsg))
    c2fb_temp_1 = arg4
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5StorageIntegrity(CPtr(c2fb_Fts5Storage Ptr, local0->pStorage), Cast(c2fb_c_int, &O0ULL)))
    local1 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((*arg4) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local1 And Cast(c2fb_c_int, &HffULL)))) = Cast(c2fb_c_int, 11ULL))))) Then
            c2fb_temp_3 = CPtr(ZString Ptr Ptr, @((*arg4)))
            c2fb_temp_4 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"malformed inverted index for FTS5 table %s.%s"), arg1, arg2))
            (*c2fb_temp_3) = c2fb_temp_4
            c2fb_temp_5 = Cast(c2fb_c_int, IIf(((*arg4)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 7ULL)))
            local1 = c2fb_temp_5
        Else
            c2fb_temp_6 = CPtr(ZString Ptr Ptr, @((*arg4)))
            c2fb_temp_7 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"unable to validate the inverted index for FTS5 table %s.%s: %s"), arg1, arg2, CPtr(Const ZString Ptr, c2fb_external_sqlite3_errstr(local1))))
            (*c2fb_temp_6) = c2fb_temp_7
        End If
    Else
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local1 And Cast(c2fb_c_int, &HffULL)))) = Cast(c2fb_c_int, 11ULL))))) Then
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_8
        End If
    End If
    c2fb_external_sqlite3Fts5IndexCloseReader(CPtr(c2fb_Fts5Index Ptr, local0->p.pIndex))
    c2fb_temp_9 = CPtr(ZString Ptr Ptr Ptr, @(CPtr(c2fb_Fts5Config Ptr, local0->p.pConfig)->pzErrmsg))
    c2fb_temp_10 = CPtr(ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_9) = c2fb_temp_10
    Return local1
End Function
Private Function fts5FindFunctionMethod CDecl Alias "fts5FindFunctionMethod" ( _
    ByVal arg0 As c2fb_sqlite3_vtab Ptr, _
    ByVal arg1 As c2fb_c_int, _
    ByVal arg2 As Const ZString Ptr, _
    ByVal arg3 As Any Ptr Ptr, _
    ByVal arg4 As Any Ptr Ptr _
) As c2fb_c_int
    Dim pTable As c2fb_Fts5FullTable Ptr
    Dim pAux As c2fb_Fts5Auxiliary Ptr

    pTable = CPtr(c2fb_Fts5FullTable Ptr, arg0)
    pAux = fts5FindAuxiliary(pTable, arg2)
    If pAux Then
        (*arg3) = CPtr(Any Ptr, ProcPtr(fts5ApiCallback))
        (*arg4) = CPtr(Any Ptr, pAux)
        Return 1
    End If
    Return 0
End Function

/' ------------------------------------------------------------------------- '/
/' FTS5 public extension API callbacks                                        '/
/' ------------------------------------------------------------------------- '/

/'
    Auxiliary functions receive this callback table for the duration of each
    invocation. Keeping the table static matches SQLite's API lifetime and
    lets xQueryPhrase pass the same API back to nested callbacks.
'/
Private Dim Shared As Const c2fb_Fts5ExtensionApi sFts5Api = _
    Type<c2fb_Fts5ExtensionApi>( _
        4, _
        ProcPtr(fts5ApiUserData), _
        ProcPtr(fts5ApiColumnCount), _
        ProcPtr(fts5ApiRowCount), _
        ProcPtr(fts5ApiColumnTotalSize), _
        ProcPtr(fts5ApiTokenize), _
        ProcPtr(fts5ApiPhraseCount), _
        ProcPtr(fts5ApiPhraseSize), _
        ProcPtr(fts5ApiInstCount), _
        ProcPtr(fts5ApiInst), _
        ProcPtr(fts5ApiRowid), _
        ProcPtr(fts5ApiColumnText), _
        ProcPtr(fts5ApiColumnSize), _
        ProcPtr(fts5ApiQueryPhrase), _
        ProcPtr(fts5ApiSetAuxdata), _
        ProcPtr(fts5ApiGetAuxdata), _
        ProcPtr(fts5ApiPhraseFirst), _
        ProcPtr(fts5ApiPhraseNext), _
        ProcPtr(fts5ApiPhraseFirstColumn), _
        ProcPtr(fts5ApiPhraseNextColumn), _
        ProcPtr(fts5ApiQueryToken), _
        ProcPtr(fts5ApiInstToken), _
        ProcPtr(fts5ApiColumnLocale), _
        ProcPtr(fts5ApiTokenize_v2) _
    )

Private Dim Shared As Const c2fb_Fts5SqliteModule fts5Mod = _
    Type<c2fb_Fts5SqliteModule>( _
        4, _
        CPtr(Any Ptr, ProcPtr(fts5CreateMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5ConnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5BestIndexMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5DisconnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5DestroyMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5OpenMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5CloseMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5FilterMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5NextMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5EofMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5ColumnMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5RowidMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5UpdateMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5BeginMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5SyncMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5CommitMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5RollbackMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5FindFunctionMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5RenameMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5SavepointMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5ReleaseMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5RollbackToMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5ShadowName)), _
        CPtr(Any Ptr, ProcPtr(fts5IntegrityMethod)) _
    )

Private Function fts5Init CDecl Alias "fts5Init" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
    Dim pGlobal As c2fb_Fts5Global Ptr
    Dim rc As c2fb_c_int

    pGlobal = CPtr(c2fb_Fts5Global Ptr, _
        c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, SizeOf(c2fb_Fts5Global))))
    If pGlobal = 0 Then Return SQLITE_NOMEM

    c2fb_crt_memset(CPtr(Any Ptr, pGlobal), 0, _
        Cast(c2fb_size_t, SizeOf(c2fb_Fts5Global)))
    pGlobal->db = arg0
    pGlobal->api.iVersion = 3
    pGlobal->api.xCreateFunction = ProcPtr(fts5CreateAux)
    pGlobal->api.xCreateTokenizer = ProcPtr(fts5CreateTokenizer)
    pGlobal->api.xFindTokenizer = ProcPtr(fts5FindTokenizer)
    pGlobal->api.xCreateTokenizer_v2 = ProcPtr(fts5CreateTokenizer_v2)
    pGlobal->api.xFindTokenizer_v2 = ProcPtr(fts5FindTokenizer_v2)

    ' The 128-bit header distinguishes FTS5 locale values from ordinary blobs.
    c2fb_fts5Randomness(Cast(c2fb_c_int, 4 * SizeOf(c2fb_u32)), _
        CPtr(Any Ptr, @pGlobal->aLocaleHdr(0)))
    pGlobal->aLocaleHdr(0) = pGlobal->aLocaleHdr(0) Xor &HF924976D
    pGlobal->aLocaleHdr(1) = pGlobal->aLocaleHdr(1) Xor &H16596E13
    pGlobal->aLocaleHdr(2) = pGlobal->aLocaleHdr(2) Xor &H7C80BEAA
    pGlobal->aLocaleHdr(3) = pGlobal->aLocaleHdr(3) Xor &H9B03A67F
#ifdef SQLITE_DEBUG
    fts5MainAssert(4 * SizeOf(c2fb_u32) = 16, _
        StrPtr(!"sizeof(pGlobal->aLocaleHdr)==16"))
#endif

    rc = c2fb_fts5CreateModuleV2(arg0, StrPtr(!"fts5"), _
        CPtr(Any Ptr, @fts5Mod), CPtr(Any Ptr, pGlobal), _
        CPtr(Any Ptr, ProcPtr(fts5ModuleDestroy)))
    If rc = SQLITE_OK Then rc = sqlite3Fts5IndexInit(arg0)
    If rc = SQLITE_OK Then rc = sqlite3Fts5ExprInit(pGlobal, arg0)
    If rc = SQLITE_OK Then _
        rc = sqlite3Fts5AuxInit(CPtr(c2fb_fts5_api Ptr, @pGlobal->api))
    If rc = SQLITE_OK Then _
        rc = sqlite3Fts5TokenizerInit(CPtr(c2fb_fts5_api Ptr, @pGlobal->api))
    If rc = SQLITE_OK Then rc = sqlite3Fts5VocabInit(pGlobal, arg0)

    If rc = SQLITE_OK Then
        rc = c2fb_fts5CreateFunction(arg0, StrPtr(!"fts5"), 1, _
            SQLITE_UTF8, CPtr(Any Ptr, pGlobal), _
            CPtr(Any Ptr, ProcPtr(fts5Fts5Func)), 0, 0)
    End If
    If rc = SQLITE_OK Then
        rc = c2fb_fts5CreateFunction(arg0, StrPtr(!"fts5_source_id"), 0, _
            SQLITE_UTF8 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, _
            CPtr(Any Ptr, pGlobal), CPtr(Any Ptr, ProcPtr(fts5SourceIdFunc)), _
            0, 0)
    End If
    If rc = SQLITE_OK Then
        rc = c2fb_fts5CreateFunction(arg0, StrPtr(!"fts5_locale"), 2, _
            SQLITE_UTF8 Or SQLITE_INNOCUOUS Or _
                SQLITE_RESULT_SUBTYPE Or SQLITE_SUBTYPE, _
            CPtr(Any Ptr, pGlobal), CPtr(Any Ptr, ProcPtr(fts5LocaleFunc)), _
            0, 0)
    End If
    If rc = SQLITE_OK Then
        rc = c2fb_fts5CreateFunction(arg0, StrPtr(!"fts5_insttoken"), 1, _
            SQLITE_UTF8 Or SQLITE_INNOCUOUS Or SQLITE_RESULT_SUBTYPE, _
            CPtr(Any Ptr, pGlobal), CPtr(Any Ptr, ProcPtr(fts5InsttokenFunc)), _
            0, 0)
    End If

    Return rc
End Function

Function sqlite3Fts5Init CDecl Alias "sqlite3Fts5Init" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_main.c
' c2fb source-line: 3901
    Return fts5Init(arg0)
End Function

/' ------------------------------------------------------------------------- '/
/' Manually lowered cursor and extension API helpers                         '/
/' ------------------------------------------------------------------------- '/

Private Sub fts5FreeCursorComponents CDecl Alias "fts5FreeCursorComponents" ( _
    ByVal pCsr As c2fb_Fts5Cursor Ptr _
)
    Dim pTab As c2fb_Fts5FullTable Ptr
    Dim pSorter As c2fb_Fts5Sorter Ptr
    Dim pData As c2fb_Fts5Auxdata Ptr
    Dim pNext As c2fb_Fts5Auxdata Ptr
    Dim pStart As UByte Ptr
    Dim nClear As c2fb_uint64

    If pCsr = 0 Then Exit Sub

    pTab = CPtr(c2fb_Fts5FullTable Ptr, pCsr->base.pVtab)
    pSorter = CPtr(c2fb_Fts5Sorter Ptr, pCsr->pSorter)

    c2fb_external_sqlite3_free(CPtr(Any Ptr, pCsr->aInstIter))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, pCsr->aInst))

    If pCsr->pStmt Then
        c2fb_external_sqlite3Fts5StorageStmtRelease( _
            CPtr(c2fb_Fts5Storage Ptr, pTab->pStorage), _
            fts5StmtType(pCsr), pCsr->pStmt)
    End If

    If pSorter Then
        c2fb_external_sqlite3_finalize(pSorter->pStmt)
        c2fb_external_sqlite3_free(CPtr(Any Ptr, pSorter))
    End If

    If pCsr->ePlan <> FTS5_PLAN_SOURCE Then
        c2fb_external_sqlite3Fts5ExprFree( _
            CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr))
    End If

    pData = CPtr(c2fb_Fts5Auxdata Ptr, pCsr->pAuxdata)
    While pData
        pNext = CPtr(c2fb_Fts5Auxdata Ptr, pData->pNext)
        If pData->xDelete Then pData->xDelete(pData->pPtr)
        c2fb_external_sqlite3_free(CPtr(Any Ptr, pData))
        pData = pNext
    Wend

    c2fb_external_sqlite3_finalize(pCsr->pRankArgStmt)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, pCsr->apRankArg))

    If (pCsr->csrflags And FTS5CSR_FREE_ZRANK) <> 0 Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, pCsr->zRank))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, pCsr->zRankArgs))
    End If

    c2fb_external_sqlite3Fts5IndexCloseReader( _
        CPtr(c2fb_Fts5Index Ptr, pTab->p.pIndex))

    ' Cursor initialization starts at ePlan, leaving the SQLite vtab base
    ' and list link intact until the close method unlinks this cursor.
    pStart = CPtr(UByte Ptr, @pCsr->ePlan)
    nClear = Cast(c2fb_uint64, SizeOf(c2fb_Fts5Cursor)) - _
        Cast(c2fb_uint64, pStart - CPtr(UByte Ptr, pCsr))
    c2fb_crt_memset_size(CPtr(Any Ptr, pStart), 0, nClear)
End Sub

Private Function fts5SorterNext CDecl Alias "fts5SorterNext" ( _
    ByVal pCsr As c2fb_Fts5Cursor Ptr _
) As c2fb_c_int
    Dim pSorter As c2fb_Fts5Sorter Ptr
    Dim aBlob As Const UByte Ptr
    Dim a As Const UByte Ptr
    Dim nBlob As c2fb_c_int
    Dim iOff As c2fb_c_int
    Dim iVal As c2fb_c_uint
    Dim i As c2fb_c_int
    Dim rc As c2fb_c_int

    If pCsr = 0 Then Return SQLITE_MISUSE
    pSorter = CPtr(c2fb_Fts5Sorter Ptr, pCsr->pSorter)
    If pSorter = 0 Then Return SQLITE_MISUSE

    rc = c2fb_external_sqlite3_step(pSorter->pStmt)
    If rc = SQLITE_DONE Then
        rc = SQLITE_OK
        pCsr->csrflags = pCsr->csrflags Or _
            FTS5CSR_EOF Or FTS5CSR_REQUIRE_CONTENT
    ElseIf rc = SQLITE_ROW Then
        ' The internal SELECT returned a row; the virtual-table callback
        ' reports SQLITE_OK after copying that row into the FTS5 cursor.
        rc = SQLITE_OK
        pSorter->iRowid = c2fb_external_sqlite3_column_int64( _
            pSorter->pStmt, 0)
        nBlob = c2fb_external_sqlite3_column_bytes(pSorter->pStmt, 1)
        aBlob = CPtr(Const UByte Ptr, _
            c2fb_external_sqlite3_column_blob(pSorter->pStmt, 1))
        a = aBlob
        iOff = 0

        ' Detail=none produces a zero-length rank blob.  In all other cases
        ' SQLite's column API guarantees a non-NULL blob for a positive size.
        If nBlob > 0 Then
            If aBlob = 0 Then Return SQLITE_CORRUPT

            i = 0
            While i < pSorter->nIdx - 1
                iVal = 0
                a += c2fb_external_sqlite3Fts5GetVarint32(a, @iVal)
                iOff += Cast(c2fb_c_int, iVal)
                c2fb_Fts5Sorter_aIdx_tail_ptr(pSorter)[i] = iOff
                i += 1
            Wend

            c2fb_Fts5Sorter_aIdx_tail_ptr(pSorter)[i] = _
                nBlob - Cast(c2fb_c_int, a - aBlob)
            pSorter->aPoslist = a
        End If

        fts5CsrNewrow(pCsr)
    End If

    Return rc
End Function

Private Function fts5CursorFirstSorted CDecl Alias "fts5CursorFirstSorted" ( _
    ByVal pTab As c2fb_Fts5FullTable Ptr, _
    ByVal pCsr As c2fb_Fts5Cursor Ptr, _
    ByVal bDesc As c2fb_c_int _
) As c2fb_c_int
    Dim pConfig As c2fb_Fts5Config Ptr
    Dim pSorter As c2fb_Fts5Sorter Ptr
    Dim nPhrase As c2fb_c_int
    Dim nByte As c2fb_uint64
    Dim zRank As Const ZString Ptr
    Dim zRankArgs As Const ZString Ptr
    Dim zRankSep As Const ZString Ptr
    Dim zRankArgText As Const ZString Ptr
    Dim zOrder As Const ZString Ptr
    Dim rc As c2fb_c_int

    If pTab = 0 Or pCsr = 0 Then Return SQLITE_MISUSE

    pConfig = CPtr(c2fb_Fts5Config Ptr, pTab->p.pConfig)
    nPhrase = c2fb_external_sqlite3Fts5ExprPhraseCount( _
        CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr))
    If nPhrase < 0 Then Return SQLITE_CORRUPT_VTAB

    ' Keep the flexible aIdx tail aligned like SZ_FTS5SORTER() in C.
    nByte = Cast(c2fb_uint64, _
        SizeOf(c2fb_Fts5Sorter) - SizeOf(c2fb_i64))
    nByte += ((Cast(c2fb_uint64, nPhrase) + 2) \ 2) * _
        Cast(c2fb_uint64, SizeOf(c2fb_i64))
    pSorter = CPtr(c2fb_Fts5Sorter Ptr, _
        c2fb_external_sqlite3_malloc64(nByte))
    If pSorter = 0 Then Return SQLITE_NOMEM

    c2fb_crt_memset_size(CPtr(Any Ptr, pSorter), 0, nByte)
    pSorter->nIdx = nPhrase

    zRank = CPtr(Const ZString Ptr, pCsr->zRank)
    zRankArgs = CPtr(Const ZString Ptr, pCsr->zRankArgs)
    If zRankArgs Then
        zRankSep = StrPtr(!", ")
        zRankArgText = zRankArgs
    Else
        zRankSep = StrPtr(!"")
        zRankArgText = StrPtr(!"")
    End If
    If bDesc Then
        zOrder = StrPtr(!"DESC")
    Else
        zOrder = StrPtr(!"ASC")
    End If

    rc = fts5PrepareStatement(@pSorter->pStmt, pConfig, _
        StrPtr(!"SELECT rowid, rank FROM %Q.%Q ORDER BY %s(\"%w\"%s%s) %s"), _
        pConfig->zDb, pConfig->zName, zRank, pConfig->zName, _
        zRankSep, zRankArgText, zOrder)

    pCsr->pSorter = CPtr(Any Ptr, pSorter)
    If rc = SQLITE_OK Then
        If pTab->pSortCsr <> 0 Then
            rc = SQLITE_MISUSE
        Else
            pTab->pSortCsr = pCsr
            rc = fts5SorterNext(pCsr)
            pTab->pSortCsr = 0
        End If
    End If

    If rc <> SQLITE_OK Then
        c2fb_external_sqlite3_finalize(pSorter->pStmt)
        c2fb_external_sqlite3_free(CPtr(Any Ptr, pSorter))
        pCsr->pSorter = 0
    End If
    Return rc
End Function

Private Function fts5CsrPoslist CDecl Alias "fts5CsrPoslist" ( _
    ByVal pCsr As c2fb_Fts5Cursor Ptr, _
    ByVal iPhrase As c2fb_c_int, _
    ByVal pa As Const UByte Ptr Ptr, _
    ByVal pn As c2fb_c_int Ptr _
) As c2fb_c_int
    Dim pTable As c2fb_Fts5Table Ptr
    Dim pConfig As c2fb_Fts5Config Ptr
    Dim pSorter As c2fb_Fts5Sorter Ptr
    Dim aPopulator As c2fb_Fts5PoslistPopulator Ptr
    Dim pText As Const ZString Ptr
    Dim nText As c2fb_c_int
    Dim nPhrase As c2fb_c_int
    Dim i As c2fb_c_int
    Dim iFirst As c2fb_c_int
    Dim bLive As c2fb_c_int
    Dim rc As c2fb_c_int

    If pCsr = 0 Or pa = 0 Or pn = 0 Then Return SQLITE_MISUSE

    pTable = CPtr(c2fb_Fts5Table Ptr, pCsr->base.pVtab)
    pConfig = CPtr(c2fb_Fts5Config Ptr, pTable->pConfig)
    nPhrase = c2fb_external_sqlite3Fts5ExprPhraseCount( _
        CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr))
    rc = SQLITE_OK
    bLive = IIf(pCsr->pSorter = 0, 1, 0)
    aPopulator = 0

    If iPhrase < 0 Or iPhrase >= nPhrase Then
        rc = SQLITE_RANGE
    ElseIf pConfig->eDetail <> FTS5_DETAIL_FULL AndAlso _
           fts5IsContentless(CPtr(c2fb_Fts5FullTable Ptr, pCsr->base.pVtab), 1) Then
        *pa = 0
        *pn = 0
        Return SQLITE_OK
    ElseIf (pCsr->csrflags And FTS5CSR_REQUIRE_POSLIST) <> 0 Then
        If pConfig->eDetail <> FTS5_DETAIL_FULL Then
            aPopulator = c2fb_external_sqlite3Fts5ExprClearPoslists( _
                CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr), bLive)
            If aPopulator = 0 Then rc = SQLITE_NOMEM
            If rc = SQLITE_OK Then rc = fts5SeekCursor(pCsr, 0)

            i = 0
            While i < pConfig->nCol And rc = SQLITE_OK
                pText = 0
                nText = 0
                rc = fts5TextFromStmt(pConfig, pCsr->pStmt, i, _
                    @pText, @nText)
                If rc = SQLITE_OK Then
                    rc = c2fb_external_sqlite3Fts5ExprPopulatePoslists( _
                        pConfig, CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr), _
                        aPopulator, i, pText, nText)
                End If
                sqlite3Fts5ClearLocale(pConfig)
                i += 1
            Wend

            c2fb_external_sqlite3_free(CPtr(Any Ptr, aPopulator))
            If pCsr->pSorter Then
                pSorter = CPtr(c2fb_Fts5Sorter Ptr, pCsr->pSorter)
                c2fb_external_sqlite3Fts5ExprCheckPoslists( _
                    CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr), pSorter->iRowid)
            End If
        End If
        pCsr->csrflags = pCsr->csrflags And Not FTS5CSR_REQUIRE_POSLIST
    End If

    If rc = SQLITE_OK Then
        If pCsr->pSorter <> 0 AndAlso _
           pConfig->eDetail = FTS5_DETAIL_FULL Then
            pSorter = CPtr(c2fb_Fts5Sorter Ptr, pCsr->pSorter)
            iFirst = IIf(iPhrase = 0, 0, _
                c2fb_Fts5Sorter_aIdx_tail_ptr(pSorter)[iPhrase - 1])
            *pn = c2fb_Fts5Sorter_aIdx_tail_ptr(pSorter)[iPhrase] - iFirst
            *pa = pSorter->aPoslist + iFirst
        Else
            *pn = c2fb_external_sqlite3Fts5ExprPoslist( _
                CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr), iPhrase, pa)
        End If
    Else
        *pa = 0
        *pn = 0
    End If

    Return rc
End Function

Private Function fts5ApiPhraseFirstColumn CDecl Alias "fts5ApiPhraseFirstColumn" ( _
    ByVal pCtx As c2fb_Fts5Context Ptr, _
    ByVal iPhrase As c2fb_c_int, _
    ByVal pIter As c2fb_Fts5PhraseIter Ptr, _
    ByVal piCol As c2fb_c_int Ptr _
) As c2fb_c_int
    Dim pCsr As c2fb_Fts5Cursor Ptr
    Dim pTable As c2fb_Fts5Table Ptr
    Dim pConfig As c2fb_Fts5Config Ptr
    Dim pSorter As c2fb_Fts5Sorter Ptr
    Dim iFirst As c2fb_c_int
    Dim n As c2fb_c_int
    Dim iCol As c2fb_c_int
    Dim nPhrase As c2fb_c_int
    Dim rc As c2fb_c_int

    If pCtx = 0 Or pIter = 0 Or piCol = 0 Then Return SQLITE_MISUSE
    pCsr = CPtr(c2fb_Fts5Cursor Ptr, pCtx)
    pTable = CPtr(c2fb_Fts5Table Ptr, pCsr->base.pVtab)
    pConfig = CPtr(c2fb_Fts5Config Ptr, pTable->pConfig)
    rc = SQLITE_OK

    If pConfig->eDetail = FTS5_DETAIL_COLUMNS Then
        pSorter = CPtr(c2fb_Fts5Sorter Ptr, pCsr->pSorter)
        nPhrase = c2fb_external_sqlite3Fts5ExprPhraseCount( _
            CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr))
        If iPhrase < 0 Or iPhrase >= nPhrase Then
            rc = SQLITE_RANGE
        ElseIf pSorter Then
            iFirst = 0
            If iPhrase > 0 Then
                iFirst = c2fb_Fts5Sorter_aIdx_tail_ptr(pSorter)[iPhrase - 1]
            End If
            n = c2fb_Fts5Sorter_aIdx_tail_ptr(pSorter)[iPhrase] - iFirst
            pIter->a = pSorter->aPoslist + iFirst
        Else
            rc = c2fb_external_sqlite3Fts5ExprPhraseCollist( _
                CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr), iPhrase, _
                @pIter->a, @n)
        End If
        If rc = SQLITE_OK Then
            pIter->b = IIf(pIter->a, pIter->a + n, 0)
            *piCol = 0
            fts5ApiPhraseNextColumn(pCtx, pIter, piCol)
        End If
    Else
        n = 0
        rc = fts5CsrPoslist(pCsr, iPhrase, @pIter->a, @n)
        If rc = SQLITE_OK Then
            pIter->b = IIf(pIter->a, pIter->a + n, 0)
            If n <= 0 Then
                *piCol = -1
            ElseIf pIter->a[0] = 1 Then
                iCol = 0
                pIter->a += 1 + c2fb_external_sqlite3Fts5GetVarint32( _
                    @pIter->a[1], @iCol)
                *piCol = iCol
            Else
                *piCol = 0
            End If
        End If
    End If
    Return rc
End Function

Private Function fts5ApiQueryPhrase CDecl Alias "fts5ApiQueryPhrase" ( _
    ByVal pCtx As c2fb_Fts5Context Ptr, _
    ByVal iPhrase As c2fb_c_int, _
    ByVal pUserData As Any Ptr, _
    ByVal xCallback As c2fb_callback_fts5_query_phrase _
) As c2fb_c_int
    Dim pCsr As c2fb_Fts5Cursor Ptr
    Dim pTab As c2fb_Fts5FullTable Ptr
    Dim pNew As c2fb_Fts5Cursor Ptr
    Dim rc As c2fb_c_int

    If pCtx = 0 Or xCallback = 0 Then Return SQLITE_MISUSE
    pCsr = CPtr(c2fb_Fts5Cursor Ptr, pCtx)
    pTab = CPtr(c2fb_Fts5FullTable Ptr, pCsr->base.pVtab)
    pNew = 0

    rc = fts5OpenMethod(CPtr(c2fb_sqlite3_vtab Ptr, pCsr->base.pVtab), _
        CPtr(c2fb_sqlite3_vtab_cursor Ptr Ptr, @pNew))
    If rc = SQLITE_OK Then
        pNew->ePlan = FTS5_PLAN_MATCH
        pNew->iFirstRowid = Cast(c2fb_int64, &H8000000000000000ULL)
        pNew->iLastRowid = Cast(c2fb_int64, &H7FFFFFFFFFFFFFFFULL)
        pNew->base.pVtab = CPtr(c2fb_sqlite3_vtab_ Ptr, pTab)
        rc = c2fb_external_sqlite3Fts5ExprClonePhrase( _
            CPtr(c2fb_Fts5Expr Ptr, pCsr->pExpr), iPhrase, _
            CPtr(c2fb_Fts5Expr Ptr Ptr, @pNew->pExpr))
    End If

    If rc = SQLITE_OK Then
        rc = fts5CursorFirst(pTab, pNew, 0)
        While rc = SQLITE_OK AndAlso _
              (pNew->csrflags And FTS5CSR_EOF) = 0
            rc = xCallback(CPtr(Const c2fb_Fts5ExtensionApi_ Ptr, @sFts5Api), _
                CPtr(c2fb_Fts5Context_ Ptr, pNew), pUserData)
            If rc = SQLITE_DONE Then
                rc = SQLITE_OK
                Exit While
            ElseIf rc <> SQLITE_OK Then
                Exit While
            End If
            rc = fts5NextMethod(CPtr(c2fb_sqlite3_vtab_cursor Ptr, pNew))
        Wend
    End If

    fts5CloseMethod(CPtr(c2fb_sqlite3_vtab_cursor Ptr, pNew))
    Return rc
End Function

Private Sub fts5ApiInvoke CDecl Alias "fts5ApiInvoke" ( _
    ByVal pAux As c2fb_Fts5Auxiliary Ptr, _
    ByVal pCsr As c2fb_Fts5Cursor Ptr, _
    ByVal context As c2fb_sqlite3_context Ptr, _
    ByVal argc As c2fb_c_int, _
    ByVal argv As c2fb_sqlite3_value Ptr Ptr _
)
    If pAux = 0 Or pCsr = 0 Then Exit Sub
    pCsr->pAux = CPtr(c2fb_Fts5Auxiliary_ Ptr, pAux)
    pAux->xFunc(CPtr(Const c2fb_Fts5ExtensionApi_ Ptr, @sFts5Api), _
        CPtr(c2fb_Fts5Context_ Ptr, pCsr), _
        CPtr(c2fb_sqlite3_context_ Ptr, context), argc, _
        CPtr(c2fb_sqlite3_value_ Ptr Ptr, argv))
    pCsr->pAux = 0
End Sub
#endif
/' end of sqlite3_bulk_fts5_main.bas '/
