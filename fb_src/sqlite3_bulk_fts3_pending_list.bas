/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_pending_list.bas

    Purpose:

        Append serialized varints to an FTS3 pending-term list.

    Responsibilities:

        - Allocate the pending-list record and its flexible data tail.
        - Grow the buffer while preserving the serialized prefix.
        - Keep the trailing zero byte required by FTS3 list consumers.

    This file intentionally does NOT contain:

        - Token-to-document list construction or hash-table management.
        - Segment writing, merging, or query execution.
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

Const FTS3_VARINT_MAX As SQLITE_C_INT = 10
Const FTS3_PENDING_LIST_INITIAL_BYTES As SQLITE_C_INT = 100

Declare Function sqlite3Fts3PutVarint CDecl Alias "sqlite3Fts3PutVarint" ( _
    ByVal zOutput As ZString Ptr, _
    ByVal value As sqlite3_int64 _
) As SQLITE_C_INT

Function fts3PendingListAppendVarint CDecl Alias "fts3PendingListAppendVarint" ( _
    ByVal ppList As SqliteFts3PendingList Ptr Ptr, _
    ByVal value As sqlite3_int64 _
) As SQLITE_C_INT
    If ppList = 0 Then Return SQLITE_MISUSE

    Dim pList As SqliteFts3PendingList Ptr = *ppList
    If pList = 0 Then
        Dim initialBytes As sqlite3_uint64 = _
            Cast(sqlite3_uint64, SizeOf(SqliteFts3PendingList)) + _
            Cast(sqlite3_uint64, FTS3_PENDING_LIST_INITIAL_BYTES)
        pList = CPtr(SqliteFts3PendingList Ptr, sqlite3_malloc64(initialBytes))
        If pList = 0 Then Return SQLITE_NOMEM

        pList->nSpace = FTS3_PENDING_LIST_INITIAL_BYTES
        pList->aData = CPtr(ZString Ptr, _
            CPtr(UByte Ptr, pList) + SizeOf(SqliteFts3PendingList))
        pList->nData = 0
    Else
        If pList->nData < 0 OrElse pList->nSpace < 0 OrElse _
           pList->nData > pList->nSpace OrElse pList->aData = 0 Then _
            Return SQLITE_CORRUPT_VTAB

        If pList->nSpace < FTS3_VARINT_MAX + 1 OrElse _
           pList->nData > pList->nSpace - (FTS3_VARINT_MAX + 1) Then
            If pList->nSpace > &H3FFFFFFF Then
                sqlite3_free(CPtr(Any Ptr, pList))
                *ppList = 0
                Return SQLITE_TOOBIG
            End If

            Dim newSpace As sqlite3_int64 = pList->nSpace * 2
            Dim allocationBytes As sqlite3_uint64 = _
                Cast(sqlite3_uint64, SizeOf(SqliteFts3PendingList)) + _
                Cast(sqlite3_uint64, newSpace)
            Dim pGrown As SqliteFts3PendingList Ptr = CPtr( _
                SqliteFts3PendingList Ptr, _
                sqlite3_realloc64(CPtr(Any Ptr, pList), allocationBytes))
            If pGrown = 0 Then
                sqlite3_free(CPtr(Any Ptr, pList))
                *ppList = 0
                Return SQLITE_NOMEM
            End If
            pList = pGrown
            pList->nSpace = newSpace
            pList->aData = CPtr(ZString Ptr, _
                CPtr(UByte Ptr, pList) + SizeOf(SqliteFts3PendingList))
        End If
    End If

    If pList->nData > pList->nSpace - (FTS3_VARINT_MAX + 1) Then _
        Return SQLITE_CORRUPT_VTAB

    Dim nWritten As SQLITE_C_INT = sqlite3Fts3PutVarint( _
        CPtr(ZString Ptr, CPtr(UByte Ptr, pList->aData) + pList->nData), value)
    If nWritten <= 0 OrElse nWritten > FTS3_VARINT_MAX Then _
        Return SQLITE_CORRUPT_VTAB

    pList->nData += nWritten
    CPtr(UByte Ptr, pList->aData)[pList->nData] = 0
    *ppList = pList
    Return SQLITE_OK
End Function

#endif

/' end of sqlite3_bulk_fts3_pending_list.bas '/
