/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_matchinfo_free.bas

    Purpose:

        Release an FTS3 matchinfo buffer after its reference slots are unused.

    Responsibilities:

        - Clear the primary reference slot.
        - Free the SQLite allocation when all three slots are clear.

    This file intentionally does NOT contain:

        - Matchinfo buffer allocation or payload sizing.
        - Snippet generation, phrase statistics, or matchinfo SQL functions.
'/

/'
** SQLite's blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
'/

#lang "fb"
#include once "sqlite3_constants.bi"
#include once "sqlite3_debug_assert.bi"
#include once "sqlite3_fts3_snippet_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Type c2fb_c_int As Long

Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal pMemory As Any Ptr)

Sub sqlite3Fts3MIBufferFree CDecl Alias "sqlite3Fts3MIBufferFree" ( _
    ByVal arg0 As Fts3MatchinfoBuffer Ptr _
) Export
' c2fb source-path: ext/fts3/fts3_snippet.c
' c2fb source-line: 204
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte

    If arg0 Then
#ifdef SQLITE_DEBUG
        If arg0->aRef(0) <> 1 Then _
            sqlite3DebugAssert(StrPtr("p->aRef[0]==1"))
#endif
        c2fb_temp_0 = CPtr(UByte Ptr, @(arg0->aRef(0)))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
        If arg0->aRef(0) = 0 AndAlso _
           arg0->aRef(1) = 0 AndAlso _
           arg0->aRef(2) = 0 Then
            sqlite3_free(CPtr(Any Ptr, arg0))
        End If
    End If
End Sub

#endif

/' end of sqlite3_bulk_fts3_matchinfo_free.bas '/
