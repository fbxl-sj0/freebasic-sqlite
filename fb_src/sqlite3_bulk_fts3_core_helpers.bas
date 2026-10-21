/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_core_helpers.bas

    Purpose:

        Provide FTS3 core helpers used while constructing and parsing tables.

    Responsibilities:

        - Create the FTS3 statistics shadow table when requested.
        - Parse bounded decimal integers in FTS3 table options.

    This file intentionally does NOT contain:

        - The static FTS3 virtual-table callback table.
        - Segment traversal, query evaluation, or write execution.
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

Function sqlite3Fts3ReadInt CDecl Alias "sqlite3Fts3ReadInt" ( _
    ByVal zInput As Const ZString Ptr, _
    ByVal pValue As SQLITE_C_INT Ptr _
) As SQLITE_C_INT Export
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 972
    If zInput = 0 OrElse pValue = 0 Then Return 0

    Dim digitIndex As SQLITE_C_INT = 0
    Dim value As sqlite3_uint64 = 0
    While 1
        Dim digitByte As UByte = CByte(CPtr(Const UByte Ptr, zInput)[digitIndex])
        If digitByte < Asc("0") OrElse digitByte > Asc("9") Then Exit While

        Dim digitValue As sqlite3_uint64 = digitByte - Asc("0")
        If value > (Cast(sqlite3_uint64, &H7FFFFFFF) - digitValue) \ 10 Then _
            Return -1
        value = value * 10 + digitValue
        digitIndex += 1
    Wend

    *pValue = CInt(value)
    Return digitIndex
End Function

Sub sqlite3Fts3CreateStatTable CDecl Alias "sqlite3Fts3CreateStatTable" ( _
    ByVal pReturnCode As SQLITE_C_INT Ptr, _
    ByVal pTable As SqliteFts3Table Ptr _
) Export
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 671
    If pReturnCode = 0 Then Exit Sub
    If *pReturnCode <> SQLITE_OK Then Exit Sub
    If pTable = 0 OrElse pTable->db = 0 OrElse _
       pTable->zDb = 0 OrElse pTable->zName = 0 Then
        *pReturnCode = SQLITE_MISUSE
        Exit Sub
    End If

    Dim zSql As ZString Ptr = sqlite3_mprintf( _
        StrPtr("CREATE TABLE IF NOT EXISTS %Q.'%q_stat'(id INTEGER PRIMARY KEY, value BLOB);"), _
        pTable->zDb, pTable->zName)
    If zSql = 0 Then
        *pReturnCode = SQLITE_NOMEM
        Exit Sub
    End If

    *pReturnCode = sqlite3_exec( _
        pTable->db, zSql, 0, 0, 0)
    sqlite3_free(CPtr(Any Ptr, zSql))
    If *pReturnCode = SQLITE_OK Then pTable->bHasStat = 1
End Sub

#endif

/' end of sqlite3_bulk_fts3_core_helpers.bas '/
