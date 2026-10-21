/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_deferred_tokens.bas

    Purpose:

        Manage FTS3 deferred-token ownership and pending-list allocations.

    Responsibilities:

        - Link newly deferred phrase tokens into their cursor.
        - Delete pending-list allocations owned by deferred tokens.
        - Clear cached deferred doclists without deleting token nodes.
        - Free all deferred-token nodes when a cursor is closed.
        - Return encoded deferred doclists without their rowid prefix.

    This file intentionally does NOT contain:

        - Deferred-token match evaluation.
        - FTS3 query parsing or segment traversal.
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
#include once "sqlite3_fts3_expr_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Declare Function fts3DeferredMemset CDecl Alias "memset" ( _
    ByVal pMemory As Any Ptr, _
    ByVal fillByte As SQLITE_C_INT, _
    ByVal byteCount As SQLITE_SIZE_T _
) As Any Ptr
Declare Function fts3DeferredMemcpy CDecl Alias "memcpy" ( _
    ByVal pDestination As Any Ptr, _
    ByVal pSource As Const Any Ptr, _
    ByVal byteCount As SQLITE_SIZE_T _
) As Any Ptr
Declare Function sqlite3Fts3GetVarint CDecl Alias "sqlite3Fts3GetVarint" ( _
    ByVal zInput As Const ZString Ptr, _
    ByVal pValue As sqlite3_int64 Ptr _
) As SQLITE_C_INT

Private Sub fts3PendingListDelete CDecl Alias "fts3PendingListDelete" ( _
    ByVal pList As SqliteFts3PendingList Ptr _
)
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 761
    sqlite3_free(CPtr(Any Ptr, pList))
End Sub

Function sqlite3Fts3DeferToken CDecl Alias "sqlite3Fts3DeferToken" ( _
    ByVal pCursor As SqliteFts3Cursor Ptr, _
    ByVal pToken As SqliteFts3PhraseToken Ptr, _
    ByVal columnIndex As SQLITE_C_INT _
) As SQLITE_C_INT Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 5627
    If pCursor = 0 OrElse pToken = 0 Then Return SQLITE_MISUSE
    If pToken->pDeferred <> 0 Then Return SQLITE_MISUSE

    Dim pDeferred As SqliteFts3DeferredToken Ptr = _
        CPtr(SqliteFts3DeferredToken Ptr, sqlite3_malloc64( _
            SizeOf(SqliteFts3DeferredToken)))
    If pDeferred = 0 Then Return SQLITE_NOMEM
    fts3DeferredMemset(pDeferred, 0, SizeOf(SqliteFts3DeferredToken))

    pDeferred->pToken = pToken
    pDeferred->pNext = pCursor->pDeferred
    pDeferred->iCol = columnIndex
    pCursor->pDeferred = pDeferred
    pToken->pDeferred = pDeferred
    Return SQLITE_OK
End Function

Function sqlite3Fts3DeferredTokenList CDecl Alias "sqlite3Fts3DeferredTokenList" ( _
    ByVal pToken As SqliteFts3DeferredToken Ptr, _
    ByVal ppData As ZString Ptr Ptr, _
    ByVal pDataBytes As SQLITE_C_INT Ptr _
) As SQLITE_C_INT Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 5597
    If pToken = 0 OrElse ppData = 0 OrElse pDataBytes = 0 Then _
        Return SQLITE_MISUSE
    *ppData = 0
    *pDataBytes = 0
    If pToken->pList = 0 Then Return SQLITE_OK

    Dim pList As SqliteFts3PendingList Ptr = pToken->pList
    If pList->nData <= 0 OrElse pList->aData = 0 Then _
        Return SQLITE_CORRUPT_VTAB
    If pList->nData > &H7FFFFFFF Then Return SQLITE_TOOBIG

    Dim pCopyBuffer As ZString Ptr = CPtr(ZString Ptr, _
        sqlite3_malloc64(Cast(sqlite3_uint64, pList->nData)))
    If pCopyBuffer = 0 Then Return SQLITE_NOMEM

    Dim firstDocid As sqlite3_int64
    Dim skippedBytes As SQLITE_C_INT = sqlite3Fts3GetVarint( _
        pList->aData, @firstDocid)
    If skippedBytes <= 0 OrElse skippedBytes > pList->nData Then
        sqlite3_free(CPtr(Any Ptr, pCopyBuffer))
        Return SQLITE_CORRUPT_VTAB
    End If

    Dim dataBytes As SQLITE_C_INT = CInt(pList->nData - skippedBytes)
    If dataBytes > 0 Then
        fts3DeferredMemcpy(pCopyBuffer, _
            CPtr(Const UByte Ptr, pList->aData) + skippedBytes, dataBytes)
    End If
    *ppData = pCopyBuffer
    *pDataBytes = dataBytes
    Return SQLITE_OK
End Function

Sub sqlite3Fts3FreeDeferredDoclists CDecl Alias "sqlite3Fts3FreeDeferredDoclists" ( _
    ByVal pCursor As SqliteFts3Cursor Ptr _
) Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 5513
    Dim pDeferred As SqliteFts3DeferredToken Ptr = pCursor->pDeferred
    While pDeferred
        fts3PendingListDelete(pDeferred->pList)
        Dim pListAddress As SqliteFts3PendingList Ptr Ptr = @pDeferred->pList
        pListAddress[0] = 0
        pDeferred = pDeferred->pNext
    Wend
End Sub

Sub sqlite3Fts3FreeDeferredTokens CDecl Alias "sqlite3Fts3FreeDeferredTokens" ( _
    ByVal pCursor As SqliteFts3Cursor Ptr _
) Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 5525
    Dim pDeferred As SqliteFts3DeferredToken Ptr = pCursor->pDeferred
    While pDeferred
        Dim pNext As SqliteFts3DeferredToken Ptr = pDeferred->pNext
        fts3PendingListDelete(pDeferred->pList)
        sqlite3_free(CPtr(Any Ptr, pDeferred))
        pDeferred = pNext
    Wend
    pCursor->pDeferred = 0
End Sub

#endif

/' end of sqlite3_bulk_fts3_deferred_tokens.bas '/
