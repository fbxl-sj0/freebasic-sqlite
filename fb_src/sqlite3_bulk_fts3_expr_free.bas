/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_expr_free.bas

    Purpose:

        Free an FTS3 query expression without recursive stack growth.

    Responsibilities:

        - Release phrase doclists and per-token segment readers.
        - Walk the expression tree iteratively and free each node once.
        - Check tree ownership invariants in SQLITE_DEBUG builds.

    This file intentionally does NOT contain:

        - Query parsing, expression construction, or phrase evaluation.
        - Query planning or FTS3 table storage.
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
#include once "sqlite3_debug_assert.bi"
#include once "sqlite3_fts3_expr_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Declare Sub sqlite3Fts3SegReaderFinish CDecl Alias "sqlite3Fts3SegReaderFinish" ( _
    ByVal pReader As SqliteFts3MultiSegReader Ptr _
)

Private Sub fts3EvalInvalidatePoslist( _
    ByVal pPhrase As SqliteFts3Phrase Ptr _
)
    If pPhrase = 0 Then Exit Sub
    If pPhrase->doclist.bFreeList <> 0 Then _
        sqlite3_free(CPtr(Any Ptr, pPhrase->doclist.pList))
    pPhrase->doclist.pList = 0
    pPhrase->doclist.nList = 0
    pPhrase->doclist.bFreeList = 0
End Sub

Private Sub fts3SegReaderCursorFree( _
    ByVal pReader As SqliteFts3MultiSegReader Ptr _
)
    If pReader = 0 Then Exit Sub
    sqlite3Fts3SegReaderFinish(pReader)
    sqlite3_free(CPtr(Any Ptr, pReader))
End Sub

Sub sqlite3Fts3EvalPhraseCleanup CDecl Alias "sqlite3Fts3EvalPhraseCleanup" ( _
    ByVal pPhrase As SqliteFts3Phrase Ptr _
) Export
' c2fb source-path: ext/fts3/fts3.c
' c2fb source-line: 6188
    If pPhrase = 0 Then Exit Sub
    sqlite3_free(CPtr(Any Ptr, pPhrase->doclist.aAll))
    fts3EvalInvalidatePoslist(pPhrase)

    pPhrase->doclist.aAll = 0
    pPhrase->doclist.nAll = 0
    pPhrase->doclist.pNextDocid = 0
    pPhrase->doclist.iDocid = 0
    pPhrase->doclist.bFreeList = 0
    pPhrase->doclist.pList = 0
    pPhrase->doclist.nList = 0

    Dim tokenIndex As SQLITE_C_INT
    Dim pTokenArray As SqliteFts3PhraseToken Ptr = _
        @pPhrase->aToken(0)
    For tokenIndex = 0 To pPhrase->nToken - 1
        fts3SegReaderCursorFree(pTokenArray[tokenIndex].pSegcsr)
        pTokenArray[tokenIndex].pSegcsr = 0
    Next
End Sub

Private Sub fts3FreeExprNode CDecl Alias "fts3FreeExprNode" ( _
    ByVal pExpression As SqliteFts3Expr Ptr _
)
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 1093
    If pExpression = 0 Then Exit Sub
#ifdef SQLITE_DEBUG
    If pExpression->eType <> FTSQUERY_PHRASE AndAlso _
       pExpression->pPhrase <> 0 Then
        sqlite3DebugAssert(StrPtr("p->eType==FTSQUERY_PHRASE || p->pPhrase==0"))
    End If
#endif
    sqlite3Fts3EvalPhraseCleanup(CPtr( _
        SqliteFts3Phrase Ptr, pExpression->pPhrase))
    sqlite3_free(CPtr(Any Ptr, pExpression->aMI))
    sqlite3_free(CPtr(Any Ptr, pExpression))
End Sub

Sub sqlite3Fts3ExprFree CDecl Alias "sqlite3Fts3ExprFree" ( _
    ByVal pDelete As SqliteFts3Expr Ptr _
) Export
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 1115
    If pDelete = 0 Then Exit Sub
#ifdef SQLITE_DEBUG
    If pDelete->pParent <> 0 Then _
        sqlite3DebugAssert(StrPtr("pDel==0 || pDel->pParent==0"))
#endif

    Dim pExpression As SqliteFts3Expr Ptr = pDelete
    While pExpression->pLeft <> 0 OrElse pExpression->pRight <> 0
#ifdef SQLITE_DEBUG
        If pExpression->pParent <> 0 AndAlso _
           pExpression <> pExpression->pParent->pRight AndAlso _
           pExpression <> pExpression->pParent->pLeft Then
            sqlite3DebugAssert(StrPtr( _
                "p->pParent==0 || p==p->pParent->pRight || p==p->pParent->pLeft"))
        End If
#endif
        If pExpression->pLeft <> 0 Then
            pExpression = pExpression->pLeft
        Else
            pExpression = pExpression->pRight
        End If
    Wend

    While pExpression <> 0
        Dim pParent As SqliteFts3Expr Ptr = pExpression->pParent
        Dim wasLeftChild As Long = CInt( _
            pParent <> 0 AndAlso pParent->pLeft = pExpression)
        Dim hasRightChild As Long = CInt( _
            pParent <> 0 AndAlso pParent->pRight <> 0)
        fts3FreeExprNode(pExpression)

        If pParent <> 0 AndAlso wasLeftChild <> 0 AndAlso _
           hasRightChild <> 0 Then
            pExpression = pParent->pRight
            While pExpression->pLeft <> 0 OrElse pExpression->pRight <> 0
#ifdef SQLITE_DEBUG
                If pExpression->pParent <> 0 AndAlso _
                   pExpression <> pExpression->pParent->pRight AndAlso _
                   pExpression <> pExpression->pParent->pLeft Then
                    sqlite3DebugAssert(StrPtr( _
                        "p==p->pParent->pRight || p==p->pParent->pLeft"))
                End If
#endif
                If pExpression->pLeft <> 0 Then
                    pExpression = pExpression->pLeft
                Else
                    pExpression = pExpression->pRight
                End If
            Wend
        Else
            pExpression = pParent
        End If
    Wend
End Sub

#endif

/' end of sqlite3_bulk_fts3_expr_free.bas '/
