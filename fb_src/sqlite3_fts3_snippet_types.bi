/'
    Project: SQLite FreeBASIC port

    File: sqlite3_fts3_snippet_types.bi

    Purpose:

        Describe the private FTS3 snippet records used by translated code.

    Responsibilities:

        - Preserve the layouts of source-local snippet and matchinfo records.
        - Let C2FB type-check callbacks and cross-record field accesses.
        - Preserve the fixed fields and flexible payload start of MatchinfoBuffer.

    This file intentionally does NOT contain:

        - Snippet selection, token iteration, or matchinfo execution logic.
        - Ownership or allocation of the flexible matchinfo payload.
        - Allocation-size calculations for the flexible matchinfo array.
'/

#ifndef SQLITE3_FTS3_SNIPPET_TYPES_BI
#define SQLITE3_FTS3_SNIPPET_TYPES_BI

#include once "sqlite3_types.bi"
#include once "sqlite3_fts3_expr_types.bi"
#include once "sqlite3_fts3_tokenizer_types.bi"

' C2FB's source view for sqlite3_vtab_cursor keeps the opaque sqlite3_vtab
' pointer distinct from the port's common Any Ptr storage field.
Type c2fb_sqlite3_vtab As SqliteVtab

' These records are local to ext/fts3/fts3_snippet.c. They are exposed here
' only so generated bodies can use the port's already-reviewed C ABI layouts.
Type SqliteFts3LoadDoclistCtx
    pCsr As SqliteFts3Cursor Ptr
    nPhrase As SQLITE_C_INT
    nToken As SQLITE_C_INT
End Type

Type SqliteFts3SnippetPhrase
    nToken As SQLITE_C_INT
    pList As ZString Ptr
    iHead As sqlite3_int64
    pHead As ZString Ptr
    iTail As sqlite3_int64
    pTail As ZString Ptr
End Type

Type SqliteFts3SnippetIter
    pCsr As SqliteFts3Cursor Ptr
    iCol As SQLITE_C_INT
    nSnippet As SQLITE_C_INT
    nPhrase As SQLITE_C_INT
    aPhrase As SqliteFts3SnippetPhrase Ptr
    iCurrent As SQLITE_C_INT
End Type

Type SqliteFts3SnippetFragment
    iCol As SQLITE_C_INT
    iPos As SQLITE_C_INT
    covered As sqlite3_uint64
    hlmask As sqlite3_uint64
End Type

Type SqliteFts3MatchInfo
    pCursor As SqliteFts3Cursor Ptr
    nCol As SQLITE_C_INT
    nPhrase As SQLITE_C_INT
    nDoc As sqlite3_int64
    flag As Byte
    aMatchinfo As SQLITE_C_UINT Ptr
End Type

Type SqliteFts3StrBuffer
    z As ZString Ptr
    n As SQLITE_C_INT
    nAlloc As SQLITE_C_INT
End Type

Type SqliteFts3TermOffset
    pList As ZString Ptr
    iPos As sqlite3_int64
    iOff As sqlite3_int64
End Type

Type SqliteFts3TermOffsetCtx
    pCsr As SqliteFts3Cursor Ptr
    iCol As SQLITE_C_INT
    iTerm As SQLITE_C_INT
    iDocid As sqlite3_int64
    aTerm As SqliteFts3TermOffset Ptr
End Type

Type SqliteFts3LcsIterator
    pExpr As SqliteFts3Expr Ptr
    iPosOffset As SQLITE_C_INT
    pRead As ZString Ptr
    iPos As SQLITE_C_INT
End Type

' C uses a flexible array at aMI. One FreeBASIC element keeps its field offset
' and type available to C2FB, but must not be included in allocation sizing.
Type Fts3MatchinfoBuffer
    aRef(0 To 2) As UByte
    nElem As SQLITE_C_INT
    bGlobal As SQLITE_C_INT
    zMatchinfo As ZString Ptr
    aMI(0 To 0) As SQLITE_C_UINT
End Type

#endif

/' end of sqlite3_fts3_snippet_types.bi '/
