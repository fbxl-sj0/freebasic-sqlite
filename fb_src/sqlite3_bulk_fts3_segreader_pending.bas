/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_segreader_pending.bas

    Purpose:

        Create a segment reader over terms held in an FTS3 pending hash.

    Responsibilities:

        - Find one pending term or collect all terms matching a prefix.
        - Sort prefix matches in term order before exposing the reader.
        - Keep temporary arrays and reader storage on SQLite's allocator.

    This file intentionally does NOT contain:

        - Pending-term insertion or hash ownership.
        - Disk segment traversal or FTS3 query execution.
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
#include once "sqlite3_fts3_hash_types.bi"
#include once "sqlite3_fts3_write_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Type Fts3HashCompareProc As Function CDecl ( _
    ByVal leftElement As Const Any Ptr, _
    ByVal rightElement As Const Any Ptr _
) As SQLITE_C_INT

Extern "C"
    Declare Function fts3PendingMemcmp CDecl Alias "memcmp" ( _
        ByVal leftValue As Const Any Ptr, _
        ByVal rightValue As Const Any Ptr, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As SQLITE_C_INT
    Declare Sub fts3PendingQsort CDecl Alias "qsort" ( _
        ByVal base As Any Ptr, _
        ByVal elementCount As SQLITE_SIZE_T, _
        ByVal elementBytes As SQLITE_SIZE_T, _
        ByVal compare As Fts3HashCompareProc _
    )
    Declare Function fts3PendingMemcpy CDecl Alias "memcpy" ( _
        ByVal pDestination As Any Ptr, _
        ByVal pSource As Const Any Ptr, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
    Declare Function fts3PendingMemset CDecl Alias "memset" ( _
        ByVal pDestination As Any Ptr, _
        ByVal value As SQLITE_C_INT, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
End Extern

Private Function fts3CompareElemByTerm CDecl Alias "fts3CompareElemByTerm" ( _
    ByVal pLeft As Const Any Ptr, _
    ByVal pRight As Const Any Ptr _
) As SQLITE_C_INT
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 1689
    Dim leftElement As Fts3HashElem Ptr = _
        CPtr(Fts3HashElem Ptr Ptr, pLeft)[0]
    Dim rightElement As Fts3HashElem Ptr = _
        CPtr(Fts3HashElem Ptr Ptr, pRight)[0]
    Dim leftBytes As SQLITE_C_INT = leftElement->nKey
    Dim rightBytes As SQLITE_C_INT = rightElement->nKey
    Dim compareBytes As SQLITE_C_INT = IIf( _
        leftBytes < rightBytes, leftBytes, rightBytes)
    Dim result As SQLITE_C_INT = fts3PendingMemcmp( _
        leftElement->pKey, rightElement->pKey, _
        Cast(SQLITE_SIZE_T, compareBytes))
    If result = 0 Then result = leftBytes - rightBytes
    Return result
End Function

Function sqlite3Fts3SegReaderPending CDecl Alias "sqlite3Fts3SegReaderPending" ( _
    ByVal pTable As SqliteFts3Table Ptr, _
    ByVal indexNumber As SQLITE_C_INT, _
    ByVal zTerm As Const ZString Ptr, _
    ByVal termBytes As SQLITE_C_INT, _
    ByVal isPrefix As SQLITE_C_INT, _
    ByVal ppReader As SqliteFts3SegReader Ptr Ptr _
) As SQLITE_C_INT Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 1725
    If ppReader = 0 OrElse pTable = 0 OrElse _
       indexNumber < 0 OrElse indexNumber >= pTable->nIndex OrElse _
       pTable->aIndex = 0 OrElse termBytes < 0 OrElse _
       (termBytes > 0 AndAlso zTerm = 0) OrElse _
       (isPrefix = 0 AndAlso zTerm = 0) Then
        Return SQLITE_MISUSE
    End If
    ppReader[0] = 0

    Dim pHash As Fts3Hash Ptr = @pTable->aIndex[indexNumber].hPending
    Dim pReader As SqliteFts3SegReader Ptr = 0
    Dim pElement As Fts3HashElem Ptr = 0
    Dim aElement As Fts3HashElem Ptr Ptr = 0
    Dim elementCount As SQLITE_C_INT = 0
    Dim rc As SQLITE_C_INT = SQLITE_OK

    If isPrefix <> 0 Then
        Dim allocatedCount As SQLITE_C_INT = 0
        pElement = pHash->first
        While pElement
            Dim zKey As ZString Ptr = CPtr(ZString Ptr, pElement->pKey)
            Dim keyBytes As SQLITE_C_INT = pElement->nKey
            If termBytes = 0 OrElse _
               (keyBytes >= termBytes AndAlso _
                fts3PendingMemcmp( _
                    CPtr(Const Any Ptr, zKey), _
                    CPtr(Const Any Ptr, zTerm), _
                    Cast(SQLITE_SIZE_T, termBytes)) = 0) Then
                If elementCount = allocatedCount Then
                    ' Keep the signed C allocation counter from wrapping.
                    If allocatedCount > &H7FFFFFFF - 16 Then
                        rc = SQLITE_TOOBIG
                        elementCount = 0
                        Exit While
                    End If
                    allocatedCount += 16
                    Dim resizedElements As Fts3HashElem Ptr Ptr = CPtr( _
                        Fts3HashElem Ptr Ptr, _
                        sqlite3_realloc64( _
                            CPtr(Any Ptr, aElement), _
                            Cast(sqlite3_uint64, allocatedCount) * _
                                SizeOf(Fts3HashElem Ptr)))
                    If resizedElements = 0 Then
                        rc = SQLITE_NOMEM
                        elementCount = 0
                        Exit While
                    End If
                    aElement = resizedElements
                End If
                aElement[elementCount] = pElement
                elementCount += 1
            End If
            pElement = pElement->next
        Wend
        If elementCount > 1 Then
            fts3PendingQsort( _
                CPtr(Any Ptr, aElement), _
                Cast(SQLITE_SIZE_T, elementCount), _
                SizeOf(Fts3HashElem Ptr), _
                ProcPtr(fts3CompareElemByTerm))
        End If
    Else
        pElement = sqlite3Fts3HashFindElem( _
            CPtr(Const Fts3Hash Ptr, pHash), _
            CPtr(Const Any Ptr, zTerm), termBytes)
        If pElement Then
            aElement = @pElement
            elementCount = 1
        End If
    End If

    If elementCount > 0 Then
        Dim allocationBytes As sqlite3_uint64 = _
            SizeOf(SqliteFts3SegReader) + _
            Cast(sqlite3_uint64, elementCount + 1) * _
                SizeOf(Fts3HashElem Ptr)
        pReader = CPtr( _
            SqliteFts3SegReader Ptr, sqlite3_malloc64(allocationBytes))
        If pReader = 0 Then
            rc = SQLITE_NOMEM
        Else
            fts3PendingMemset(CPtr(Any Ptr, pReader), 0, allocationBytes)
            pReader->iIdx = &H7FFFFFFF
            pReader->ppNextElem = CPtr( _
                Any Ptr, CPtr(UByte Ptr, pReader) + _
                    SizeOf(SqliteFts3SegReader))
            fts3PendingMemcpy( _
                pReader->ppNextElem, CPtr(Const Any Ptr, aElement), _
                Cast(SQLITE_SIZE_T, elementCount) * _
                    SizeOf(Fts3HashElem Ptr))
        End If
    End If

    If isPrefix <> 0 Then sqlite3_free(CPtr(Any Ptr, aElement))
    ppReader[0] = pReader
    Return rc
End Function

#endif

/' end of sqlite3_bulk_fts3_segreader_pending.bas '/
