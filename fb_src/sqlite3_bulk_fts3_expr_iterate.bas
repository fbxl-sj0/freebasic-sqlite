/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_expr_iterate.bas

    Purpose:

        Visit phrase nodes in an FTS3 expression tree.

    Responsibilities:

        - Invoke a caller callback for each phrase in left-to-right order.
        - Skip the right-hand subtree of NOT expressions.
        - Stop immediately when a callback reports an error.

    This file intentionally does NOT contain:

        - Expression parsing or phrase evaluation.
        - Query planning or segment traversal.
'/ 

/'
** SQLite's blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
'/ 

#lang "fb"
#include once "sqlite3_constants.bi"
#include once "sqlite3_debug_assert.bi"
#include once "sqlite3_fts3_expr_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Private Function fts3ExprIterate2( _
    ByVal pExpression As SqliteFts3Expr Ptr, _
    ByRef phraseIndex As SQLITE_C_INT, _
    ByVal xVisit As SqliteFts3ExprIterateProc, _
    ByVal pContext As Any Ptr _
) As SQLITE_C_INT
    If pExpression = 0 Then Return SQLITE_OK

    If pExpression->eType <> FTSQUERY_PHRASE Then
        If pExpression->pLeft = 0 OrElse pExpression->pRight = 0 Then
#ifdef SQLITE_DEBUG
            sqlite3DebugAssert(StrPtr("pExpr->pLeft && pExpr->pRight"))
#endif
            Return SQLITE_CORRUPT_VTAB
        End If

        Dim rc As SQLITE_C_INT = fts3ExprIterate2( _
            pExpression->pLeft, phraseIndex, xVisit, pContext)
        If rc = SQLITE_OK AndAlso pExpression->eType <> FTSQUERY_NOT Then
            rc = fts3ExprIterate2( _
                pExpression->pRight, phraseIndex, xVisit, pContext)
        End If
        Return rc
    End If

    If xVisit = 0 Then Return SQLITE_MISUSE
    Dim rc As SQLITE_C_INT = xVisit(pExpression, phraseIndex, pContext)
    phraseIndex += 1
    Return rc
End Function

Function sqlite3Fts3ExprIterate CDecl Alias "sqlite3Fts3ExprIterate" ( _
    ByVal pExpression As SqliteFts3Expr Ptr, _
    ByVal xVisit As SqliteFts3ExprIterateProc, _
    ByVal pContext As Any Ptr _
) As SQLITE_C_INT Export
    If pExpression = 0 Then Return SQLITE_OK
    If xVisit = 0 Then Return SQLITE_MISUSE

    Dim phraseIndex As SQLITE_C_INT = 0
    Return fts3ExprIterate2(pExpression, phraseIndex, xVisit, pContext)
End Function

#endif

/' end of sqlite3_bulk_fts3_expr_iterate.bas '/
