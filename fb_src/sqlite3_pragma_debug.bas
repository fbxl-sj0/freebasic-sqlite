/'
    Project: SQLite FreeBASIC port

    File: sqlite3_pragma_debug.bas

    Purpose:

        Provide SQLITE_DEBUG-only PRAGMA entries and statistics reporting
        that are absent from the default generated name table.

    Responsibilities:

        - Resolve debug trace, VDBE-listing, and stats PRAGMAs.
        - Merge debug-only names into PRAGMA pragma_list in sorted order.
        - Emit table and index planner statistics for PRAGMA stats.

    This file intentionally does NOT contain:

        - The generated release PRAGMA-name table.
        - General PRAGMA dispatch or VDBE instruction execution.
'/

#lang "fb"
#include once "sqlite3_constants.bi"
#include once "sqlite3_pragma_helpers.bi"
#include once "sqlite3_schema_types.bi"

Declare Function sqlite3_stricmp CDecl Alias "sqlite3_stricmp" ( _
    ByVal zLeft As Const ZString Ptr, _
    ByVal zRight As Const ZString Ptr _
) As SQLITE_C_INT

Declare Function sqlite3PreferredTableName CDecl Alias "sqlite3PreferredTableName" ( _
    ByVal zName As Const ZString Ptr _
) As Const ZString Ptr
Declare Sub sqlite3CodeVerifySchema CDecl Alias "sqlite3CodeVerifySchema" ( _
    ByVal pParse As Any Ptr, _
    ByVal iDb As SQLITE_C_INT _
)

#ifdef SQLITE_DEBUG
' Match PragTyp_STATS, its three table-valued flags, and the column-name
' slice in pragma.h.
Private Const PRAGMA_STATS_TYPE As UByte = 45
Private Const PRAGMA_STATS_FLAGS As UByte = &H01 Or &H10 Or &H80
Private Const PRAGMA_STATS_COLUMN_FIRST As UByte = 38
Private Const PRAGMA_STATS_COLUMN_COUNT As UByte = 5

Private Dim Shared As Const ZString * 16 debugPragmaName0 = "parser_trace"
Private Dim Shared As Const ZString * 16 debugPragmaName1 = "sql_trace"
Private Dim Shared As Const ZString * 16 debugPragmaName2 = "stats"
Private Dim Shared As Const ZString * 16 debugPragmaName3 = "vdbe_addoptrace"
Private Dim Shared As Const ZString * 16 debugPragmaName4 = "vdbe_debug"
Private Dim Shared As Const ZString * 16 debugPragmaName5 = "vdbe_eqp"
Private Dim Shared As Const ZString * 16 debugPragmaName6 = "vdbe_listing"
Private Dim Shared As Const ZString * 16 debugPragmaName7 = "vdbe_trace"

Private Dim Shared As Const SqlitePragmaName debugPragmaEntries(0 To 7) = { _
    Type<SqlitePragmaName>(StrPtr(debugPragmaName0), 4, 20, 0, 0, SQLITE_ParserTrace), _
    Type<SqlitePragmaName>(StrPtr(debugPragmaName1), 4, 20, 0, 0, SQLITE_SqlTrace), _
    Type<SqlitePragmaName>(StrPtr(debugPragmaName2), PRAGMA_STATS_TYPE, _
        PRAGMA_STATS_FLAGS, PRAGMA_STATS_COLUMN_FIRST, _
        PRAGMA_STATS_COLUMN_COUNT, 0), _
    Type<SqlitePragmaName>(StrPtr(debugPragmaName3), 4, 20, 0, 0, SQLITE_VdbeAddopTrace), _
    Type<SqlitePragmaName>(StrPtr(debugPragmaName4), 4, 20, 0, 0, _
        SQLITE_SqlTrace Or SQLITE_VdbeListing Or SQLITE_VdbeTrace), _
    Type<SqlitePragmaName>(StrPtr(debugPragmaName5), 4, 20, 0, 0, SQLITE_VdbeEQP), _
    Type<SqlitePragmaName>(StrPtr(debugPragmaName6), 4, 20, 0, 0, SQLITE_VdbeListing), _
    Type<SqlitePragmaName>(StrPtr(debugPragmaName7), 4, 20, 0, 0, SQLITE_VdbeTrace) _
}
#endif

Function sqlite3DebugPragmaNameCount CDecl Alias "sqlite3DebugPragmaNameCount" () As SQLITE_C_INT Export
#ifdef SQLITE_DEBUG
    Return 8
#else
    Return 0
#endif
End Function

Function sqlite3DebugPragmaNameAt CDecl Alias "sqlite3DebugPragmaNameAt" ( _
    ByVal index As SQLITE_C_INT _
) As Const SqlitePragmaName Ptr Export
#ifdef SQLITE_DEBUG
    If index < 0 OrElse index >= 8 Then Return 0
    Return @debugPragmaEntries(index)
#else
    Return 0
#endif
End Function

Function sqlite3DebugPragmaLocate CDecl Alias "sqlite3DebugPragmaLocate" ( _
    ByVal zName As Const ZString Ptr _
) As Const SqlitePragmaName Ptr Export
    If zName = 0 Then Return 0
    For index As SQLITE_C_INT = 0 To sqlite3DebugPragmaNameCount() - 1
        Dim pPragma As Const SqlitePragmaName Ptr = sqlite3DebugPragmaNameAt(index)
        If pPragma <> 0 AndAlso sqlite3_stricmp(zName, pPragma->zName) = 0 Then _
            Return pPragma
    Next
    Return 0
End Function

Sub sqlite3PragmaEmitNameList CDecl Alias "sqlite3PragmaEmitNameList" ( _
    ByVal pVdbe As SqliteVdbe Ptr _
) Export
    If pVdbe = 0 Then Exit Sub

    Dim mainCount As SQLITE_C_INT = SQLITE3_PRAGMA_NAME_COUNT
    Dim debugCount As SQLITE_C_INT = sqlite3DebugPragmaNameCount()
    Dim pMainTable As Const SqlitePragmaName Ptr = sqlite3PragmaNameTable()
    If pMainTable = 0 Then Exit Sub
    Dim mainIndex As SQLITE_C_INT = 0
    Dim debugIndex As SQLITE_C_INT = 0
    While mainIndex < mainCount OrElse debugIndex < debugCount
        Dim pMain As Const SqlitePragmaName Ptr = 0
        Dim pDebug As Const SqlitePragmaName Ptr = 0
        If mainIndex < mainCount Then pMain = @pMainTable[mainIndex]
        If debugIndex < debugCount Then _
            pDebug = sqlite3DebugPragmaNameAt(debugIndex)

        If pDebug <> 0 AndAlso _
           (pMain = 0 OrElse sqlite3_stricmp(pDebug->zName, pMain->zName) < 0) Then
            sqlite3VdbeMultiLoad(pVdbe, 1, StrPtr(!"s"), pDebug->zName)
            debugIndex += 1
        ElseIf pMain <> 0 Then
            sqlite3VdbeMultiLoad(pVdbe, 1, StrPtr(!"s"), pMain->zName)
            mainIndex += 1
        Else
            Exit While
        End If
    Wend
End Sub
#ifdef SQLITE_DEBUG
Sub sqlite3PragmaStats CDecl Alias "sqlite3PragmaStats" ( _
    ByVal pParse As SqliteParseContext Ptr, _
    ByVal iDb As SQLITE_C_INT, _
    ByVal pDb As SqliteDbSlot Ptr, _
    ByVal pVdbe As SqliteVdbe Ptr _
)
    If pParse = 0 OrElse pDb = 0 OrElse pDb->pSchema = 0 OrElse _
       pVdbe = 0 Then Exit Sub

    pParse->nMem = 5
    sqlite3CodeVerifySchema(pParse, iDb)

    Dim pElement As HashElem Ptr = pDb->pSchema->tblHash.first
    While pElement <> 0
        Dim pTable As SqliteTable Ptr = CPtr(SqliteTable Ptr, pElement->data)
        If pTable <> 0 Then
            sqlite3VdbeMultiLoad(pVdbe, 1, StrPtr(!"ssiii"), _
                sqlite3PreferredTableName(pTable->zName), _
                CPtr(Const ZString Ptr, 0), _
                Cast(SQLITE_C_INT, pTable->szTabRow), _
                Cast(SQLITE_C_INT, pTable->nRowLogEst), _
                Cast(SQLITE_C_INT, pTable->tabFlags))

            Dim pIndex As SqliteIndex Ptr = CPtr(SqliteIndex Ptr, pTable->pIndex)
            While pIndex <> 0
                Dim indexRowLogEst As SQLITE_C_INT = 0
                If pIndex->aiRowLogEst <> 0 Then _
                    indexRowLogEst = Cast(SQLITE_C_INT, pIndex->aiRowLogEst[0])
                Dim hasStat1 As SQLITE_C_INT = 0
                If (pIndex->flags And SQLITE_INDEX_HAS_STAT1) <> 0 Then hasStat1 = 1

                sqlite3VdbeMultiLoad(pVdbe, 2, StrPtr(!"siiiX"), _
                    pIndex->zName, _
                    Cast(SQLITE_C_INT, pIndex->szIdxRow), _
                    indexRowLogEst, _
                    hasStat1)
                sqlite3VdbeAddOp2(pVdbe, OP_ResultRow, 1, 5)
                pIndex = pIndex->pNext
            Wend
        End If
        pElement = pElement->next
    Wend
End Sub
#endif

/' end of sqlite3_pragma_debug.bas '/
