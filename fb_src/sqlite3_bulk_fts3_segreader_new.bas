/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_segreader_new.bas

    Purpose:

        Allocate an FTS3 segment reader for an on-disk or root-only segment.

    Responsibilities:

        - Preserve segment age, block bounds, and lookup mode.
        - Store a root node inline with the reader when no leaf block exists.
        - Add FTS3 node padding so bounded varint reads remain safe.

    This file intentionally does NOT contain:

        - Database reads or segment iteration.
        - Pending-term readers or query planning.
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

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

' SQLite varints are at most 10 bytes; readers reserve two varints for safe lookahead.
Const FTS3_VARINT_MAX As SQLITE_C_INT = 10
Const FTS3_NODE_PADDING As SQLITE_C_INT = FTS3_VARINT_MAX * 2
Const FTS3_MAX_ROOT_BYTES As SQLITE_C_INT = _
    &H7FFFFFFF - FTS3_NODE_PADDING

Extern "C"
    Declare Function sqlite3_fts3_segreader_memcpy CDecl Alias "memcpy" ( _
        ByVal pDestination As Any Ptr, _
        ByVal pSource As Const Any Ptr, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
    Declare Function sqlite3_fts3_segreader_memset CDecl Alias "memset" ( _
        ByVal pDestination As Any Ptr, _
        ByVal value As SQLITE_C_INT, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
End Extern

Function sqlite3Fts3SegReaderNew CDecl Alias "sqlite3Fts3SegReaderNew" ( _
    ByVal age As SQLITE_C_INT, _
    ByVal lookupOnly As SQLITE_C_INT, _
    ByVal firstLeaf As sqlite3_int64, _
    ByVal lastLeaf As sqlite3_int64, _
    ByVal lastBlock As sqlite3_int64, _
    ByVal rootData As Const ZString Ptr, _
    ByVal rootBytes As SQLITE_C_INT, _
    ByVal ppReader As SqliteFts3SegReader Ptr Ptr _
) As SQLITE_C_INT Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 1636
    If ppReader = 0 Then Return SQLITE_MISUSE
    ppReader[0] = 0

    If rootBytes < 0 OrElse _
       (rootBytes > 0 AndAlso rootData = 0) OrElse _
       firstLeaf = -9223372036854775808LL Then
        Return SQLITE_CORRUPT_VTAB
    End If

    ' Preserve SQLite's handling of signed segment-directory values. A corrupt
    ' end-block value may be carried but is not dereferenced by this allocator.
    Dim extraBytes As SQLITE_C_INT = 0
    If firstLeaf = 0 Then
        If lastLeaf <> 0 OrElse rootBytes > FTS3_MAX_ROOT_BYTES Then _
            Return SQLITE_CORRUPT_VTAB
        extraBytes = rootBytes + FTS3_NODE_PADDING
    End If

    Dim allocationBytes As sqlite3_uint64 = _
        Cast(sqlite3_uint64, SizeOf(SqliteFts3SegReader)) + _
        Cast(sqlite3_uint64, extraBytes)
    Dim pReader As SqliteFts3SegReader Ptr = CPtr( _
        SqliteFts3SegReader Ptr, sqlite3_malloc64(allocationBytes))
    If pReader = 0 Then Return SQLITE_NOMEM

    sqlite3_fts3_segreader_memset( _
        pReader, 0, SizeOf(SqliteFts3SegReader))
    pReader->iIdx = age
    pReader->bLookup = CByte(lookupOnly <> 0)
    pReader->iStartBlock = firstLeaf
    pReader->iLeafEndBlock = lastLeaf
    pReader->iEndBlock = lastBlock

    If extraBytes <> 0 Then
        pReader->aNode = CPtr(ZString Ptr, CPtr( _
            UByte Ptr, pReader) + SizeOf(SqliteFts3SegReader))
        pReader->rootOnly = 1
        pReader->nNode = rootBytes

        If rootBytes <> 0 Then
            sqlite3_fts3_segreader_memcpy( _
                pReader->aNode, rootData, rootBytes)
        End If
        sqlite3_fts3_segreader_memset( _
            CPtr(UByte Ptr, pReader->aNode) + rootBytes, _
            0, FTS3_NODE_PADDING)
    Else
        pReader->iCurrentBlock = firstLeaf - 1
    End If

    ppReader[0] = pReader
    Return SQLITE_OK
End Function

#endif

/' end of sqlite3_bulk_fts3_segreader_new.bas '/
