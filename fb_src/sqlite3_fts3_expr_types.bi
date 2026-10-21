/'
    Project: SQLite FreeBASIC port

    File: sqlite3_fts3_expr_types.bi

    Purpose:

        Preserve the FTS3 expression and phrase layouts used by the query path.

    Responsibilities:

        - Match expression, phrase, doclist, and parser-context layouts.
        - Preserve the flexible aToken member's starting offset.
        - Link phrase tokens to their deferred and segment-reader state.
        - Define the expression node codes used by the parser and evaluator.

    This file intentionally does NOT contain:

        - Phrase parsing, query evaluation, or token allocation policy.
        - Allocation-size calculations for flexible expression records.
'/

#ifndef SQLITE3_FTS3_EXPR_TYPES_BI
#define SQLITE3_FTS3_EXPR_TYPES_BI

#include once "sqlite3_types.bi"
#include once "sqlite3_fts3_write_types.bi"

Type SqliteFts3Doclist
    aAll As ZString Ptr
    nAll As SQLITE_C_INT
    pNextDocid As ZString Ptr
    iDocid As sqlite3_int64
    bFreeList As SQLITE_C_INT
    pList As ZString Ptr
    nList As SQLITE_C_INT
End Type

Type SqliteFts3PhraseToken
    z As ZString Ptr
    n As SQLITE_C_INT
    isPrefix As SQLITE_C_INT
    bFirst As SQLITE_C_INT
    pDeferred As SqliteFts3DeferredToken Ptr
    pSegcsr As SqliteFts3MultiSegReader Ptr
End Type

Type SqliteFts3Phrase
    doclist As SqliteFts3Doclist
    bIncr As SQLITE_C_INT
    iDoclistToken As SQLITE_C_INT
    pOrPoslist As ZString Ptr
    iOrDocid As sqlite3_int64
    nToken As SQLITE_C_INT
    iColumn As SQLITE_C_INT
    ' One placeholder matches the offset of C's flexible aToken[] member.
    aToken(0 To 0) As SqliteFts3PhraseToken
End Type

Type SqliteFts3Expr
    eType As SQLITE_C_INT
    nNear As SQLITE_C_INT
    pParent As SqliteFts3Expr Ptr
    pLeft As SqliteFts3Expr Ptr
    pRight As SqliteFts3Expr Ptr
    pPhrase As SqliteFts3Phrase Ptr
    iDocid As sqlite3_int64
    bEof As UByte
    bStart As UByte
    bDeferred As UByte
    iPhrase As SQLITE_C_INT
    aMI As SQLITE_C_UINT Ptr
End Type

Type SqliteFts3ParseContext
    pTokenizer As Fts3Tokenizer Ptr
    iLangid As SQLITE_C_INT
    azCol As Const ZString Ptr Ptr
    bFts4 As SQLITE_C_INT
    nCol As SQLITE_C_INT
    iDefaultCol As SQLITE_C_INT
    isNot As SQLITE_C_INT
    pCtx As Any Ptr
    nNest As SQLITE_C_INT
End Type

Type SqliteFts3ExprIterateProc As Function CDecl ( _
    ByVal pExpression As SqliteFts3Expr Ptr, _
    ByVal phraseIndex As SQLITE_C_INT, _
    ByVal pContext As Any Ptr _
) As SQLITE_C_INT

Const FTSQUERY_NEAR As SQLITE_C_INT = 1
Const FTSQUERY_NOT As SQLITE_C_INT = 2
Const FTSQUERY_AND As SQLITE_C_INT = 3
Const FTSQUERY_OR As SQLITE_C_INT = 4
Const FTSQUERY_PHRASE As SQLITE_C_INT = 5
Const SQLITE_FTS3_DEFAULT_NEAR_PARAM As SQLITE_C_INT = 10

#endif

/' end of sqlite3_fts3_expr_types.bi '/
