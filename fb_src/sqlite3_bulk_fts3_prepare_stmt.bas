/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_prepare_stmt.bas

    Purpose:

        Prepare an FTS3-owned SQL statement with the required DDL flags.

    Responsibilities:

        - Always mark the statement as originating from DDL.
        - Apply persistent and virtual-table restrictions as requested.

    This file intentionally does NOT contain:

        - SQL statement caching or FTS3 SQL template selection.
        - Binding parameters or executing the prepared statement.
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
#include once "sqlite3_api_constants.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_fts3_write_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Function sqlite3Fts3PrepareStmt CDecl Alias "sqlite3Fts3PrepareStmt" ( _
    ByVal pTable As SqliteFts3Table Ptr, _
    ByVal zSql As Const ZString Ptr, _
    ByVal persistent As SQLITE_C_INT, _
    ByVal allowVirtualTables As SQLITE_C_INT, _
    ByVal ppStatement As Any Ptr Ptr _
) As SQLITE_C_INT Export
    If pTable = 0 OrElse zSql = 0 OrElse ppStatement = 0 Then _
        Return SQLITE_MISUSE
    ppStatement[0] = 0

    Dim prepareFlags As SQLITE_C_UINT = SQLITE_PREPARE_FROM_DDL
    If allowVirtualTables = 0 Then _
        prepareFlags = prepareFlags Or SQLITE_PREPARE_NO_VTAB
    If persistent <> 0 Then _
        prepareFlags = prepareFlags Or SQLITE_PREPARE_PERSISTENT

    Return sqlite3_prepare_v3( _
        pTable->db, zSql, -1, prepareFlags, ppStatement, 0)
End Function

#endif

/' end of sqlite3_bulk_fts3_prepare_stmt.bas '/
