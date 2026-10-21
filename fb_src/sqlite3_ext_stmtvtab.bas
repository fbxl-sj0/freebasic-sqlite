/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_ext_stmtvtab.bas

    Purpose:

        Implement the eponymous sqlite_stmt virtual table.

    Responsibilities:

        - Snapshot prepared statements and their status counters for each scan.
        - Expose SQL text, result-column count, read-only/busy state, and VDBE
          counters through the virtual-table callbacks.
        - Register the module when SQLITE_ENABLE_STMTVTAB is enabled.

    This file intentionally does NOT contain:

        - Statement execution or status-counter maintenance.
        - The SQLite test commands that exercise sqlite_stmt.
'/ 

#lang "fb"
#if defined(SQLITE_ENABLE_STMTVTAB) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_vtab_types.bi"
#include once "sqlite3_api_constants.bi"
#include once "sqlite3_api_declarations.bi"

Private Const STMT_NUM_INTEGER_COLUMN As SQLITE_C_INT = 10
Private Const STMT_COLUMN_SQL As SQLITE_C_INT = 0
Private Const STMT_COLUMN_NCOL As SQLITE_C_INT = 1
Private Const STMT_COLUMN_RO As SQLITE_C_INT = 2
Private Const STMT_COLUMN_BUSY As SQLITE_C_INT = 3
Private Const STMT_COLUMN_NSCAN As SQLITE_C_INT = 4
Private Const STMT_COLUMN_NSORT As SQLITE_C_INT = 5
Private Const STMT_COLUMN_NAIDX As SQLITE_C_INT = 6
Private Const STMT_COLUMN_NSTEP As SQLITE_C_INT = 7
Private Const STMT_COLUMN_REPREP As SQLITE_C_INT = 8
Private Const STMT_COLUMN_RUN As SQLITE_C_INT = 9
Private Const STMT_COLUMN_MEM As SQLITE_C_INT = 10

Private Type SqliteStmtRow
    iRowid As sqlite3_int64
    zSql As ZString Ptr
    aCol(0 To STMT_NUM_INTEGER_COLUMN) As SQLITE_C_INT
    pNext As SqliteStmtRow Ptr
End Type

Private Type SqliteStmtVtab
    base As SqliteVtab
    db As Any Ptr
End Type

Private Type SqliteStmtCursor
    base As SqliteVtabCursor
    db As Any Ptr
    pRow As SqliteStmtRow Ptr
End Type

Extern "C"
    Declare Function stmtCrtStrlen CDecl Alias "strlen" ( _
        ByVal zText As Const ZString Ptr _
    ) As SQLITE_SIZE_T
    Declare Function stmtCrtMemcpy CDecl Alias "memcpy" ( _
        ByVal pDestination As Any Ptr, _
        ByVal pSource As Const Any Ptr, _
        ByVal nByte As SQLITE_SIZE_T _
    ) As Any Ptr
End Extern

/' ------------------------------------------------------------------------- '/
/' Cursor-owned statement snapshot rows '/
/' ------------------------------------------------------------------------- '/

Private Sub stmtCursorReset(ByVal pCursor As SqliteStmtCursor Ptr)
    If pCursor = 0 Then Return

    Dim pRow As SqliteStmtRow Ptr = pCursor->pRow
    While pRow <> 0
        Dim pNext As SqliteStmtRow Ptr = pRow->pNext
        sqlite3_free(pRow)
        pRow = pNext
    Wend
    pCursor->pRow = 0
End Sub

/' ------------------------------------------------------------------------- '/
/' Virtual-table connection and cursor lifecycle '/
/' ------------------------------------------------------------------------- '/

Private Function stmtConnect CDecl ( _
    ByVal db As Any Ptr, _
    ByVal pAux As Any Ptr, _
    ByVal argc As SQLITE_C_INT, _
    ByVal argv As Const ZString Ptr Ptr, _
    ByVal ppVtab As SqliteVtab Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr _
) As SQLITE_C_INT
    If ppVtab = 0 Then Return SQLITE_MISUSE
    *ppVtab = 0
    If pzError <> 0 Then *pzError = 0

    ' SQLite calls xConnect for each connection to the eponymous table.
    Dim rc As SQLITE_C_INT = sqlite3_declare_vtab( _
        db, StrPtr(!"CREATE TABLE x(sql,ncol,ro,busy,nscan,nsort,naidx,nstep,reprep,run,mem)"))
    If rc <> SQLITE_OK Then Return rc

    Dim pNew As SqliteStmtVtab Ptr = Cast(SqliteStmtVtab Ptr, _
        sqlite3_malloc64(SizeOf(SqliteStmtVtab)))
    If pNew = 0 Then Return SQLITE_NOMEM

    pNew->base.pModule = 0
    pNew->base.nRef = 0
    pNew->base.zErrMsg = 0
    pNew->db = db
    *ppVtab = @pNew->base
    Return SQLITE_OK
End Function

Private Function stmtDisconnect CDecl(ByVal pVtab As SqliteVtab Ptr) As SQLITE_C_INT
    sqlite3_free(pVtab)
    Return SQLITE_OK
End Function

Private Function stmtOpen CDecl ( _
    ByVal pVtab As SqliteVtab Ptr, _
    ByVal ppCursor As SqliteVtabCursor Ptr Ptr _
) As SQLITE_C_INT
    If pVtab = 0 OrElse ppCursor = 0 Then Return SQLITE_MISUSE
    *ppCursor = 0

    Dim pCursor As SqliteStmtCursor Ptr = Cast(SqliteStmtCursor Ptr, _
        sqlite3_malloc64(SizeOf(SqliteStmtCursor)))
    If pCursor = 0 Then Return SQLITE_NOMEM

    pCursor->base.pVtab = pVtab
    pCursor->db = CPtr(SqliteStmtVtab Ptr, pVtab)->db
    pCursor->pRow = 0
    *ppCursor = @pCursor->base
    Return SQLITE_OK
End Function

Private Function stmtClose CDecl( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 Then Return SQLITE_OK
    Dim pCursor As SqliteStmtCursor Ptr = Cast(SqliteStmtCursor Ptr, pVtabCursor)
    stmtCursorReset(pCursor)
    sqlite3_free(pCursor)
    Return SQLITE_OK
End Function

/' ------------------------------------------------------------------------- '/
/' Statement snapshot scanning '/
/' ------------------------------------------------------------------------- '/

Private Function stmtFilter CDecl ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr, _
    ByVal idxNum As SQLITE_C_INT, _
    ByVal idxStr As Const ZString Ptr, _
    ByVal argc As SQLITE_C_INT, _
    ByVal argv As Any Ptr Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 Then Return SQLITE_MISUSE
    Dim pCursor As SqliteStmtCursor Ptr = Cast(SqliteStmtCursor Ptr, pVtabCursor)
    stmtCursorReset(pCursor)

    Dim pNextRow As SqliteStmtRow Ptr Ptr = @pCursor->pRow
    Dim pStatement As Any Ptr = sqlite3_next_stmt(pCursor->db, 0)
    Dim rowid As sqlite3_int64 = 1
    While pStatement <> 0
        Dim zSql As Const ZString Ptr = sqlite3_sql(pStatement)
        Dim nSql As SQLITE_SIZE_T = 0
        If zSql <> 0 Then nSql = stmtCrtStrlen(zSql) + 1

        Dim rowBytes As SQLITE_SIZE_T = SizeOf(SqliteStmtRow)
        If nSql > Cast(SQLITE_SIZE_T, SQLITE_MAX_ALLOCATION_SIZE) - rowBytes Then
            stmtCursorReset(pCursor)
            Return SQLITE_TOOBIG
        End If
        Dim pRow As SqliteStmtRow Ptr = Cast(SqliteStmtRow Ptr, _
            sqlite3_malloc64(rowBytes + nSql))
        If pRow = 0 Then
            stmtCursorReset(pCursor)
            Return SQLITE_NOMEM
        End If

        pRow->iRowid = rowid
        rowid += 1
        pRow->zSql = 0
        pRow->pNext = 0
        For columnIndex As SQLITE_C_INT = 0 To STMT_NUM_INTEGER_COLUMN
            pRow->aCol(columnIndex) = 0
        Next

        If zSql <> 0 Then
            pRow->zSql = Cast(ZString Ptr, _
                CPtr(UByte Ptr, pRow) + SizeOf(SqliteStmtRow))
            stmtCrtMemcpy(pRow->zSql, zSql, nSql)
        End If

        pRow->aCol(STMT_COLUMN_NCOL) = sqlite3_column_count(pStatement)
        pRow->aCol(STMT_COLUMN_RO) = sqlite3_stmt_readonly(pStatement)
        pRow->aCol(STMT_COLUMN_BUSY) = sqlite3_stmt_busy(pStatement)
        pRow->aCol(STMT_COLUMN_NSCAN) = sqlite3_stmt_status( _
            pStatement, SQLITE_STMTSTATUS_FULLSCAN_STEP, 0)
        pRow->aCol(STMT_COLUMN_NSORT) = sqlite3_stmt_status( _
            pStatement, SQLITE_STMTSTATUS_SORT, 0)
        pRow->aCol(STMT_COLUMN_NAIDX) = sqlite3_stmt_status( _
            pStatement, SQLITE_STMTSTATUS_AUTOINDEX, 0)
        pRow->aCol(STMT_COLUMN_NSTEP) = sqlite3_stmt_status( _
            pStatement, SQLITE_STMTSTATUS_VM_STEP, 0)
        pRow->aCol(STMT_COLUMN_REPREP) = sqlite3_stmt_status( _
            pStatement, SQLITE_STMTSTATUS_REPREPARE, 0)
        pRow->aCol(STMT_COLUMN_RUN) = sqlite3_stmt_status( _
            pStatement, SQLITE_STMTSTATUS_RUN, 0)
        pRow->aCol(STMT_COLUMN_MEM) = sqlite3_stmt_status( _
            pStatement, SQLITE_STMTSTATUS_MEMUSED, 0)

        *pNextRow = pRow
        pNextRow = @pRow->pNext
        pStatement = sqlite3_next_stmt(pCursor->db, pStatement)
    Wend

    Return SQLITE_OK
End Function

Private Function stmtNext CDecl( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 Then Return SQLITE_MISUSE
    Dim pCursor As SqliteStmtCursor Ptr = Cast(SqliteStmtCursor Ptr, pVtabCursor)
    If pCursor->pRow = 0 Then Return SQLITE_CORRUPT_VTAB

    Dim pNext As SqliteStmtRow Ptr = pCursor->pRow->pNext
    sqlite3_free(pCursor->pRow)
    pCursor->pRow = pNext
    Return SQLITE_OK
End Function

Private Function stmtEof CDecl( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 Then Return 1
    Return IIf(CPtr(SqliteStmtCursor Ptr, pVtabCursor)->pRow = 0, 1, 0)
End Function

Private Function stmtColumn CDecl ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr, _
    ByVal pContext As Any Ptr, _
    ByVal columnIndex As SQLITE_C_INT _
) As SQLITE_C_INT
    If pVtabCursor = 0 OrElse pContext = 0 OrElse _
       columnIndex < STMT_COLUMN_SQL OrElse _
       columnIndex > STMT_COLUMN_MEM Then Return SQLITE_CORRUPT_VTAB

    Dim pRow As SqliteStmtRow Ptr = _
        CPtr(SqliteStmtCursor Ptr, pVtabCursor)->pRow
    If pRow = 0 Then Return SQLITE_CORRUPT_VTAB
    If columnIndex = STMT_COLUMN_SQL Then
        ' SQLITE_TRANSIENT makes SQLite copy text owned by this scan row.
        sqlite3_result_text(pContext, pRow->zSql, -1, CPtr(Any Ptr, -1))
    Else
        sqlite3_result_int(pContext, pRow->aCol(columnIndex))
    End If
    Return SQLITE_OK
End Function

Private Function stmtRowid CDecl ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr, _
    ByVal pRowid As sqlite3_int64 Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 OrElse pRowid = 0 Then Return SQLITE_MISUSE
    Dim pRow As SqliteStmtRow Ptr = _
        CPtr(SqliteStmtCursor Ptr, pVtabCursor)->pRow
    If pRow = 0 Then Return SQLITE_CORRUPT_VTAB
    *pRowid = pRow->iRowid
    Return SQLITE_OK
End Function

/' ------------------------------------------------------------------------- '/
/' Query planning and static module table '/
/' ------------------------------------------------------------------------- '/

Private Function stmtBestIndex CDecl ( _
    ByVal pVtab As SqliteVtab Ptr, _
    ByVal pIndexInfo As SqliteIndexInfo Ptr _
) As SQLITE_C_INT
    If pVtab = 0 OrElse pIndexInfo = 0 Then Return SQLITE_MISUSE
    pIndexInfo->estimatedCost = 500.0
    pIndexInfo->estimatedRows = 500
    Return SQLITE_OK
End Function

Private Dim Shared As Const SqliteModuleCallbacks stmtVtabModule = _
    Type<SqliteModuleCallbacks>( _
        0, _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, ProcPtr(stmtConnect)), _
        Cast(SqliteModuleBestIndexProc, ProcPtr(stmtBestIndex)), _
        Cast(Any Ptr, ProcPtr(stmtDisconnect)), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, ProcPtr(stmtOpen)), _
        Cast(Any Ptr, ProcPtr(stmtClose)), _
        Cast(Any Ptr, ProcPtr(stmtFilter)), _
        Cast(Any Ptr, ProcPtr(stmtNext)), _
        Cast(Any Ptr, ProcPtr(stmtEof)), _
        Cast(Any Ptr, ProcPtr(stmtColumn)), _
        Cast(Any Ptr, ProcPtr(stmtRowid)), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0), _
        Cast(Any Ptr, 0) _
    )

Function sqlite3StmtVtabInit CDecl Alias "sqlite3StmtVtabInit" ( _
    ByVal db As Any Ptr _
) As SQLITE_C_INT Export
    If db = 0 Then Return SQLITE_MISUSE
    Return sqlite3_create_module( _
        db, StrPtr("sqlite_stmt"), @stmtVtabModule, 0)
End Function

#endif

/' end of sqlite3_ext_stmtvtab.bas '/
