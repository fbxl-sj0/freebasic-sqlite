/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_segreader_free.bas

    Purpose:

        Release an FTS3 segment reader and the resources it owns.

    Responsibilities:

        - Free term and node buffers according to the root-only flag.
        - Close the reader's SQLite blob handle and free the reader object.

    This file intentionally does NOT contain:

        - Segment iteration or B-tree traversal.
        - Segment-reader allocation or FTS3 query execution.
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
#include once "sqlite3_fts3_write_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Sub sqlite3Fts3SegReaderFree CDecl Alias "sqlite3Fts3SegReaderFree" ( _
    ByVal pReader As SqliteFts3SegReader Ptr _
) Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 1622
    If pReader <> 0 Then
        sqlite3_free(CPtr(Any Ptr, pReader->zTerm))
        If pReader->rootOnly = 0 Then
            sqlite3_free(CPtr(Any Ptr, pReader->aNode))
        End If
        sqlite3_blob_close(pReader->pBlob)
    End If
    sqlite3_free(CPtr(Any Ptr, pReader))
End Sub

#endif

/' end of sqlite3_bulk_fts3_segreader_free.bas '/
