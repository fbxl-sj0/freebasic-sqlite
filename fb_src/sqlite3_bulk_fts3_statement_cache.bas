/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_statement_cache.bas

    Purpose:

        Cache and prepare the SQL statements used by the FTS3 write unit.

    Responsibilities:

        - Format the fixed FTS3 SQL templates for one virtual table.
        - Cache prepared statements in their per-table slots.
        - Select all segment-directory rows for a level or level range.

    This file intentionally does NOT contain:

        - FTS3 table creation, segment reads, or write transactions.
        - Query planning or full-text evaluation.
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

Declare Function sqlite3Fts3PrepareStmt CDecl Alias "sqlite3Fts3PrepareStmt" ( _
    ByVal pTable As SqliteFts3Table Ptr, _
    ByVal zSql As Const ZString Ptr, _
    ByVal persistent As SQLITE_C_INT, _
    ByVal allowVirtualTables As SQLITE_C_INT, _
    ByVal ppStatement As Any Ptr Ptr _
) As SQLITE_C_INT
Declare Function c2fb_external_sqlite3_bind_value__ CDecl Alias "sqlite3_bind_value" ( _
    ByVal pStatement As Any Ptr, _
    ByVal parameterIndex As c2fb_c_int, _
    ByVal pValue As Const Any Ptr _
) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_int64__ CDecl Alias "sqlite3_bind_int64" ( _
    ByVal pStatement As Any Ptr, _
    ByVal parameterIndex As c2fb_c_int, _
    ByVal value As c2fb_int64 _
) As c2fb_c_int

Private Function getAbsoluteLevel CDecl Alias "getAbsoluteLevel" ( _
    ByVal pTable As SqliteFts3Table Ptr, _
    ByVal languageId As c2fb_c_int, _
    ByVal indexNumber As c2fb_c_int, _
    ByVal relativeLevel As c2fb_c_int _
) As c2fb_int64
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 583
    Dim level As c2fb_int64 = _
        Cast(c2fb_int64, _
            Cast(c2fb_int64, _
                Cast(c2fb_int64, _
                    (Cast(c2fb_int64, languageId) * _
                     Cast(c2fb_int64, pTable->nIndex)) + _
                    Cast(c2fb_int64, indexNumber)) * _
                Cast(c2fb_c_int, 1024)) + _
            Cast(c2fb_int64, relativeLevel))
    Return level
End Function

Private Function fts3SqlStmt CDecl Alias "fts3SqlStmt" ( _
    ByVal pTable As SqliteFts3Table Ptr, _
    ByVal statementIndex As c2fb_c_int, _
    ByVal ppStatement As Any Ptr Ptr, _
    ByVal apValue As Any Ptr Ptr _
) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 305
    Dim sqlTemplates(0 To 39) As Const ZString Ptr
    Dim rc As c2fb_c_int = SQLITE_OK
    If pTable = 0 OrElse ppStatement = 0 OrElse _
       statementIndex < 0 OrElse statementIndex >= 40 Then Return SQLITE_MISUSE
    Dim pStatement As Any Ptr = pTable->aStmt(statementIndex)
    Dim allowVirtualTables As c2fb_c_int = 0
    Dim zSql As ZString Ptr = 0

    Erase sqlTemplates
    sqlTemplates(0) = StrPtr(!"DELETE FROM %Q.'%q_content' WHERE rowid = ?")
    sqlTemplates(1) = StrPtr(!"SELECT NOT EXISTS(SELECT docid FROM %Q.'%q_content' WHERE rowid!=?)")
    sqlTemplates(2) = StrPtr(!"DELETE FROM %Q.'%q_content'")
    sqlTemplates(3) = StrPtr(!"DELETE FROM %Q.'%q_segments'")
    sqlTemplates(4) = StrPtr(!"DELETE FROM %Q.'%q_segdir'")
    sqlTemplates(5) = StrPtr(!"DELETE FROM %Q.'%q_docsize'")
    sqlTemplates(6) = StrPtr(!"DELETE FROM %Q.'%q_stat'")
    sqlTemplates(7) = StrPtr(!"SELECT %s WHERE rowid=?")
    sqlTemplates(8) = StrPtr(!"SELECT (SELECT max(idx) FROM %Q.'%q_segdir' WHERE level = ?) + 1")
    sqlTemplates(9) = StrPtr(!"REPLACE INTO %Q.'%q_segments'(blockid, block) VALUES(?, ?)")
    sqlTemplates(10) = StrPtr(!"SELECT coalesce((SELECT max(blockid) FROM %Q.'%q_segments') + 1, 1)")
    sqlTemplates(11) = StrPtr(!"REPLACE INTO %Q.'%q_segdir' VALUES(?,?,?,?,?,?)")
    sqlTemplates(12) = StrPtr(!"SELECT idx, start_block, leaves_end_block, end_block, root FROM %Q.'%q_segdir' WHERE level = ? ORDER BY idx ASC")
    sqlTemplates(13) = StrPtr(!"SELECT idx, start_block, leaves_end_block, end_block, root FROM %Q.'%q_segdir' WHERE level BETWEEN ? AND ?ORDER BY level DESC, idx ASC")
    sqlTemplates(14) = StrPtr(!"SELECT count(*) FROM %Q.'%q_segdir' WHERE level = ?")
    sqlTemplates(15) = StrPtr(!"SELECT max(level) FROM %Q.'%q_segdir' WHERE level BETWEEN ? AND ?")
    sqlTemplates(16) = StrPtr(!"DELETE FROM %Q.'%q_segdir' WHERE level = ?")
    sqlTemplates(17) = StrPtr(!"DELETE FROM %Q.'%q_segments' WHERE blockid BETWEEN ? AND ?")
    sqlTemplates(18) = StrPtr(!"INSERT INTO %Q.'%q_content' VALUES(%s)")
    sqlTemplates(19) = StrPtr(!"DELETE FROM %Q.'%q_docsize' WHERE docid = ?")
    sqlTemplates(20) = StrPtr(!"REPLACE INTO %Q.'%q_docsize' VALUES(?,?)")
    sqlTemplates(21) = StrPtr(!"SELECT size FROM %Q.'%q_docsize' WHERE docid=?")
    sqlTemplates(22) = StrPtr(!"SELECT value FROM %Q.'%q_stat' WHERE id=?")
    sqlTemplates(23) = StrPtr(!"REPLACE INTO %Q.'%q_stat' VALUES(?,?)")
    sqlTemplates(24) = StrPtr(!"")
    sqlTemplates(25) = StrPtr(!"")
    sqlTemplates(26) = StrPtr(!"DELETE FROM %Q.'%q_segdir' WHERE level BETWEEN ? AND ?")
    sqlTemplates(27) = StrPtr(!"SELECT ? UNION SELECT level / (1024 * ?) FROM %Q.'%q_segdir'")
    sqlTemplates(28) = StrPtr(!"SELECT level, count(*) AS cnt FROM %Q.'%q_segdir'   GROUP BY level HAVING cnt>=?  ORDER BY (level %% 1024) ASC, 2 DESC LIMIT 1")
    sqlTemplates(29) = StrPtr(!"SELECT 2 * total(1 + leaves_end_block - start_block)   FROM (SELECT * FROM %Q.'%q_segdir'         WHERE level = ? ORDER BY idx ASC LIMIT ?  )")
    sqlTemplates(30) = StrPtr(!"DELETE FROM %Q.'%q_segdir' WHERE level = ? AND idx = ?")
    sqlTemplates(31) = StrPtr(!"UPDATE %Q.'%q_segdir' SET idx = ? WHERE level=? AND idx=?")
    sqlTemplates(32) = StrPtr(!"SELECT idx, start_block, leaves_end_block, end_block, root FROM %Q.'%q_segdir' WHERE level = ? AND idx = ?")
    sqlTemplates(33) = StrPtr(!"UPDATE %Q.'%q_segdir' SET start_block = ?, root = ?WHERE level = ? AND idx = ?")
    sqlTemplates(34) = StrPtr(!"SELECT 1 FROM %Q.'%q_segments' WHERE blockid=? AND block IS NULL")
    sqlTemplates(35) = StrPtr(!"SELECT idx FROM %Q.'%q_segdir' WHERE level=? ORDER BY 1 ASC")
    sqlTemplates(36) = StrPtr(!"SELECT max( level %% 1024 ) FROM %Q.'%q_segdir'")
    sqlTemplates(37) = StrPtr(!"SELECT level, idx, end_block FROM %Q.'%q_segdir' WHERE level BETWEEN ? AND ? ORDER BY level DESC, idx ASC")
    sqlTemplates(38) = StrPtr(!"UPDATE OR FAIL %Q.'%q_segdir' SET level=-1,idx=? WHERE level=? AND idx=?")
    sqlTemplates(39) = StrPtr(!"UPDATE OR FAIL %Q.'%q_segdir' SET level=? WHERE level=-1")

    If pStatement = 0 Then
        Dim sqlText As ZString Ptr
        If statementIndex = 18 Then
            sqlText = sqlite3_mprintf( _
                sqlTemplates(statementIndex), pTable->zDb, _
                pTable->zName, pTable->zWriteExprlist)
        ElseIf statementIndex = 7 Then
            allowVirtualTables = 1
            sqlText = sqlite3_mprintf( _
                sqlTemplates(statementIndex), pTable->zReadExprlist)
        Else
            sqlText = sqlite3_mprintf( _
                sqlTemplates(statementIndex), pTable->zDb, pTable->zName)
        End If
        If sqlText = 0 Then
            rc = SQLITE_NOMEM
        Else
            rc = sqlite3Fts3PrepareStmt( _
                pTable, sqlText, 1, allowVirtualTables, _
                CPtr(Any Ptr Ptr, @pStatement))
            sqlite3_free(CPtr(Any Ptr, sqlText))
            pTable->aStmt(statementIndex) = pStatement
        End If
    End If

    If apValue Then
        Dim parameterCount As c2fb_c_int = _
            sqlite3_bind_parameter_count(CPtr(Any Ptr, pStatement))
        Dim parameterIndex As c2fb_c_int = 0
        While rc = SQLITE_OK AndAlso parameterIndex < parameterCount
            rc = c2fb_external_sqlite3_bind_value__( _
                pStatement, parameterIndex + 1, apValue[parameterIndex])
            parameterIndex += 1
        Wend
    End If
    ppStatement[0] = pStatement
    Return rc
End Function

Function sqlite3Fts3AllSegdirs CDecl Alias "sqlite3Fts3AllSegdirs" ( _
    ByVal pTable As SqliteFts3Table Ptr, _
    ByVal languageId As c2fb_c_int, _
    ByVal indexNumber As c2fb_c_int, _
    ByVal level As c2fb_c_int, _
    ByVal ppStatement As Any Ptr Ptr _
) As c2fb_c_int Export
' c2fb source-path: ext/fts3/fts3_write.c
' c2fb source-line: 615
    ' -2 is FTS3_SEGCURSOR_ALL; -1 is the separate pending-reader sentinel.
    Const FTS3_SEGCURSOR_ALL As c2fb_c_int = -2
    ' fts4aux uses a synthetic table without aIndex for segment-directory scans.
    If pTable = 0 OrElse ppStatement = 0 OrElse _
       indexNumber < 0 OrElse indexNumber >= pTable->nIndex OrElse _
       level >= 1024 OrElse _
       (level < 0 AndAlso level <> FTS3_SEGCURSOR_ALL) Then
        Return SQLITE_MISUSE
    End If
    ppStatement[0] = 0

    Dim pStatement As Any Ptr = 0
    Dim rc As c2fb_c_int
    If level < 0 Then
        rc = fts3SqlStmt(pTable, 13, @pStatement, 0)
        If rc = SQLITE_OK Then
            c2fb_external_sqlite3_bind_int64__( _
                pStatement, 1, _
                getAbsoluteLevel(pTable, languageId, indexNumber, 0))
            c2fb_external_sqlite3_bind_int64__( _
                pStatement, 2, _
                getAbsoluteLevel(pTable, languageId, indexNumber, 1023))
        End If
    Else
        rc = fts3SqlStmt(pTable, 12, @pStatement, 0)
        If rc = SQLITE_OK Then
            c2fb_external_sqlite3_bind_int64__( _
                pStatement, 1, _
                getAbsoluteLevel(pTable, languageId, indexNumber, level))
        End If
    End If
    ppStatement[0] = pStatement
    Return rc
End Function

#endif

/' end of sqlite3_bulk_fts3_statement_cache.bas '/
