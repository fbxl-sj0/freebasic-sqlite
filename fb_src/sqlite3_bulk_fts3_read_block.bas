/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_read_block.bas

    Purpose:

        Read an FTS3 segment block through SQLite's incremental-blob API.

    Responsibilities:

        - Lazily open and reuse the %_segments blob handle.
        - Return block bytes with padding for bounded FTS3 varint reads.
        - Preserve incremental loading and close the cached blob handle.

    This file intentionally does NOT contain:

        - Segment-directory queries or term iteration.
        - FTS3 query planning or write-path logic.
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
#include once "sqlite3_fts3_write_types.bi"

Extern "C"
    Declare Function fts3ReadBlockMemset CDecl Alias "memset" ( _
        ByVal pDestination As Any Ptr, _
        ByVal value As SQLITE_C_INT, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
End Extern

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

' Each varint can occupy up to 10 bytes. FTS3 keeps two varints of lookahead safe.
Const FTS3_VARINT_MAX As SQLITE_C_INT = 10
Const FTS3_NODE_PADDING As SQLITE_C_INT = FTS3_VARINT_MAX * 2
Const FTS3_NODE_CHUNKSIZE_DEFAULT As SQLITE_C_INT = 4 * 1024
Const FTS3_NODE_CHUNK_THRESHOLD_DEFAULT As SQLITE_C_INT = _
    FTS3_NODE_CHUNKSIZE_DEFAULT * 4

#ifdef SQLITE_TEST
' The unchanged C test support may adjust the default 4 KiB/16 KiB chunk sizes.
Extern test_fts3_node_chunksize Alias "test_fts3_node_chunksize" As SQLITE_C_INT
Extern test_fts3_node_chunk_threshold Alias "test_fts3_node_chunk_threshold" As SQLITE_C_INT
Dim Shared test_fts3_node_chunksize As SQLITE_C_INT = FTS3_NODE_CHUNKSIZE_DEFAULT
Dim Shared test_fts3_node_chunk_threshold As SQLITE_C_INT = _
    FTS3_NODE_CHUNK_THRESHOLD_DEFAULT
#endif

Sub sqlite3Fts3SegmentsClose CDecl Alias "sqlite3Fts3SegmentsClose" ( _
    ByVal pTable As SqliteFts3Table Ptr _
) Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 1275
    If pTable = 0 OrElse pTable->pSegments = 0 Then Exit Sub
    sqlite3_blob_close(pTable->pSegments)
    pTable->pSegments = 0
End Sub

Function sqlite3Fts3ReadBlock CDecl Alias "sqlite3Fts3ReadBlock" ( _
    ByVal pTable As SqliteFts3Table Ptr, _
    ByVal blockId As sqlite3_int64, _
    ByVal ppBlob As ZString Ptr Ptr, _
    ByVal pBlobBytes As SQLITE_C_INT Ptr, _
    ByVal pLoadedBytes As SQLITE_C_INT Ptr _
) As SQLITE_C_INT Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 1219
    If pTable = 0 OrElse pBlobBytes = 0 Then Return SQLITE_MISUSE
    If ppBlob Then ppBlob[0] = 0

    Dim rc As SQLITE_C_INT
    If pTable->pSegments <> 0 Then
        rc = sqlite3_blob_reopen(pTable->pSegments, blockId)
    Else
        If pTable->zSegmentsTbl = 0 Then
            If pTable->zName = 0 Then Return SQLITE_MISUSE
            pTable->zSegmentsTbl = sqlite3_mprintf( _
                StrPtr(!"%s_segments"), pTable->zName)
            If pTable->zSegmentsTbl = 0 Then Return SQLITE_NOMEM
        End If
        rc = sqlite3_blob_open( _
            pTable->db, pTable->zDb, pTable->zSegmentsTbl, _
            StrPtr("block"), blockId, 0, @pTable->pSegments)
    End If

    If rc <> SQLITE_OK Then
        If rc = SQLITE_ERROR Then Return SQLITE_CORRUPT_VTAB
        Return rc
    End If

    Dim blobBytes As SQLITE_C_INT = sqlite3_blob_bytes(pTable->pSegments)
    If blobBytes < 0 OrElse _
       blobBytes > &H7FFFFFFF - FTS3_NODE_PADDING Then _
        Return SQLITE_CORRUPT_VTAB
    pBlobBytes[0] = blobBytes
    If ppBlob = 0 Then Return SQLITE_OK

    Dim allocationBytes As sqlite3_uint64 = _
        Cast(sqlite3_uint64, blobBytes) + FTS3_NODE_PADDING
    Dim pBuffer As ZString Ptr = CPtr( _
        ZString Ptr, sqlite3_malloc64(allocationBytes))
    If pBuffer = 0 Then Return SQLITE_NOMEM

    Dim bytesToRead As SQLITE_C_INT = blobBytes
#ifdef SQLITE_TEST
    If pLoadedBytes <> 0 AndAlso _
       blobBytes > test_fts3_node_chunk_threshold Then
        If test_fts3_node_chunksize < 1 Then
            sqlite3_free(CPtr(Any Ptr, pBuffer))
            Return SQLITE_MISUSE
        End If
        bytesToRead = test_fts3_node_chunksize
        pLoadedBytes[0] = bytesToRead
    End If
#else
    If pLoadedBytes <> 0 AndAlso _
       blobBytes > FTS3_NODE_CHUNK_THRESHOLD_DEFAULT Then
        bytesToRead = FTS3_NODE_CHUNKSIZE_DEFAULT
        pLoadedBytes[0] = bytesToRead
    End If
#endif

    If bytesToRead < 0 OrElse _
       bytesToRead > blobBytes OrElse _
       bytesToRead > &H7FFFFFFF - FTS3_NODE_PADDING Then
        sqlite3_free(CPtr(Any Ptr, pBuffer))
        Return SQLITE_MISUSE
    End If
    rc = sqlite3_blob_read(pTable->pSegments, pBuffer, bytesToRead, 0)
    Dim pPadding As UByte Ptr = CPtr(UByte Ptr, pBuffer) + bytesToRead
    fts3ReadBlockMemset(pPadding, 0, FTS3_NODE_PADDING)

    If rc <> SQLITE_OK Then
        sqlite3_free(CPtr(Any Ptr, pBuffer))
        Return rc
    End If
    ppBlob[0] = pBuffer
    Return SQLITE_OK
End Function

#endif

/' end of sqlite3_bulk_fts3_read_block.bas '/
