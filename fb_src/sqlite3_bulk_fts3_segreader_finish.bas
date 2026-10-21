/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_segreader_finish.bas

    Purpose:

        Release the segment readers and buffers owned by an FTS3 multi-reader.

    Responsibilities:

        - Close every segment reader in the multi-reader array.
        - Free the segment array and merge buffer, then reset the handle.

    This file intentionally does NOT contain:

        - Segment traversal or term merging.
        - Allocation of multi-reader state or FTS3 query execution.
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

Declare Sub sqlite3Fts3SegReaderFree CDecl Alias "sqlite3Fts3SegReaderFree" ( _
    ByVal pReader As SqliteFts3SegReader Ptr _
)

Sub sqlite3Fts3SegReaderFinish CDecl Alias "sqlite3Fts3SegReaderFinish" ( _
    ByVal pReader As SqliteFts3MultiSegReader Ptr _
) Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 3081
    Dim local0 As SQLITE_C_INT
    Dim c2fb_temp_0 As SQLITE_C_INT
    Dim c2fb_temp_1 As SQLITE_C_INT
    Dim c2fb_temp_2 As SQLITE_C_INT Ptr
    Dim c2fb_temp_3 As SQLITE_C_INT
    Dim c2fb_temp_4 As SqliteFts3SegReader Ptr Ptr Ptr
    Dim c2fb_temp_5 As SqliteFts3SegReader Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr

    If pReader Then
        c2fb_temp_0 = Cast(SQLITE_C_INT, &O0ULL)
        local0 = c2fb_temp_0
        While local0 < pReader->nSegment
            sqlite3Fts3SegReaderFree(pReader->apSegment[local0])
            c2fb_temp_1 = local0
            local0 = Cast(SQLITE_C_INT, c2fb_temp_1 + 1)
        Wend
        sqlite3_free(CPtr(Any Ptr, pReader->apSegment))
        sqlite3_free(CPtr(Any Ptr, pReader->aBuffer))
        c2fb_temp_2 = CPtr(SQLITE_C_INT Ptr, @(pReader->nSegment))
        c2fb_temp_3 = Cast(SQLITE_C_INT, &O0ULL)
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(SqliteFts3SegReader Ptr Ptr Ptr, @(pReader->apSegment))
        c2fb_temp_5 = CPtr( _
            SqliteFts3SegReader Ptr Ptr, Cast(Integer, &O0ULL))
        (*c2fb_temp_4) = c2fb_temp_5
        c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(pReader->aBuffer))
        c2fb_temp_7 = CPtr(ZString Ptr, Cast(Integer, &O0ULL))
        (*c2fb_temp_6) = c2fb_temp_7
    End If
End Sub

#endif

/' end of sqlite3_bulk_fts3_segreader_finish.bas '/
