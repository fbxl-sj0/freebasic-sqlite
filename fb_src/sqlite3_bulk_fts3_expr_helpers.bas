/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_expr_helpers.bas

    Purpose:

        Supply allocation and tokenizer-cursor helpers used by FTS3 queries.

    Responsibilities:

        - Allocate zeroed FTS3 query records through SQLite's allocator.
        - Open tokenizer cursors and apply versioned language-id callbacks.

    This file intentionally does NOT contain:

        - FTS3 query parsing or expression-tree evaluation.
        - Tokenizer registration or on-disk segment traversal.
'/ 

/'
** SQLite's blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
'/ 

#lang "fb"
#include once "sqlite3_api_declarations.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_debug_assert.bi"
#include once "sqlite3_fts3_tokenizer_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Declare Function fts3ExprMemset CDecl Alias "memset" ( _
    ByVal pDestination As Any Ptr, _
    ByVal fillByte As SQLITE_C_INT, _
    ByVal byteCount As SQLITE_SIZE_T _
) As Any Ptr

Function sqlite3Fts3MallocZero CDecl Alias "sqlite3Fts3MallocZero" ( _
    ByVal byteCount As sqlite3_int64 _
) As Any Ptr Export
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 125
    Dim pMemory As Any Ptr = sqlite3_malloc64(Cast(sqlite3_uint64, byteCount))
    If pMemory <> 0 Then
        fts3ExprMemset(pMemory, 0, Cast(SQLITE_SIZE_T, byteCount))
    End If
    Return pMemory
End Function

Function sqlite3Fts3OpenTokenizer CDecl Alias "sqlite3Fts3OpenTokenizer" ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr, _
    ByVal languageId As SQLITE_C_INT, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppCursor As Fts3TokenizerCursor Ptr Ptr _
) As SQLITE_C_INT Export
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 131
    If ppCursor = 0 Then Return SQLITE_MISUSE
    *ppCursor = 0

    If pTokenizer = 0 OrElse pTokenizer->pModule = 0 Then Return SQLITE_MISUSE

    Dim pModule As Const Fts3TokenizerModule Ptr = _
        CPtr(Const Fts3TokenizerModule Ptr, pTokenizer->pModule)
    If pModule->xOpen = 0 OrElse pModule->xClose = 0 Then _
        Return SQLITE_MISUSE

    Dim pCursor As Fts3TokenizerCursor Ptr = 0
    Dim rc As SQLITE_C_INT = pModule->xOpen( _
        pTokenizer, zInput, inputBytes, @pCursor)
#ifdef SQLITE_DEBUG
    If rc <> SQLITE_OK AndAlso pCursor <> 0 Then _
        sqlite3DebugAssert(StrPtr("rc==SQLITE_OK || pCsr==0"))
#endif

    If rc = SQLITE_OK Then
        If pCursor = 0 Then Return SQLITE_ERROR
        pCursor->pTokenizer = pTokenizer

        If pModule->iVersion >= 1 Then
            If pModule->xLanguageid = 0 Then
                pModule->xClose(pCursor)
                Return SQLITE_MISUSE
            End If
            rc = pModule->xLanguageid(pCursor, languageId)
            If rc <> SQLITE_OK Then
                pModule->xClose(pCursor)
                pCursor = 0
            End If
        End If
    End If

    *ppCursor = pCursor
    Return rc
End Function

#endif

/' end of sqlite3_bulk_fts3_expr_helpers.bas '/
