/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_expr_parse.bas

    Purpose:

        Parse FTS3 MATCH expressions into owned expression trees.

    Responsibilities:

        - Tokenize terms and phrases with the configured FTS3 tokenizer.
        - Parse legacy and parenthesis-enabled query syntax.
        - Build, balance, and validate the expression tree.

    This file intentionally does NOT contain:

        - FTS3 query execution or inverted-index traversal.
        - The virtual-table module initializer or segment storage.
'/

#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts3_tokenizer_types.bi"
#include once "sqlite3_fts3_expr_types.bi"
#include once "sqlite3_fts3_hash_types.bi"
#include once "sqlite3_api_declarations.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
#include once "sqlite3_debug_assert.bi"

#ifndef __C2FB_BODY_C_ABI_TYPES__
#define __C2FB_BODY_C_ABI_TYPES__

#ifndef __C2FB_ABI_TYPE_C_INT__
#define __C2FB_ABI_TYPE_C_INT__
Type c2fb_c_int As Long
#endif
#ifndef __C2FB_ABI_TYPE_C_UINT__
#define __C2FB_ABI_TYPE_C_UINT__
Type c2fb_c_uint As ULong
#endif
#ifndef __C2FB_ABI_TYPE_C_LONG__
#define __C2FB_ABI_TYPE_C_LONG__
Type c2fb_c_long As CLong
#endif
#ifndef __C2FB_ABI_TYPE_C_ULONG__
#define __C2FB_ABI_TYPE_C_ULONG__
Type c2fb_c_ulong As CULong
#endif
#ifndef __C2FB_ABI_TYPE_INT64__
#define __C2FB_ABI_TYPE_INT64__
Type c2fb_int64 As LongInt
#endif
#ifndef __C2FB_ABI_TYPE_UINT64__
#define __C2FB_ABI_TYPE_UINT64__
Type c2fb_uint64 As ULongInt
#endif
#ifndef __C2FB_ABI_TYPE_SIZE_T__
#define __C2FB_ABI_TYPE_SIZE_T__
Type c2fb_size_t As UInteger
#endif
#endif

#include once "sqlite3_api_declarations.bi"

#ifdef SQLITE_TEST
Extern sqlite3_fts3_enable_parentheses _
    Alias "sqlite3_fts3_enable_parentheses" As SQLITE_C_INT
Dim Shared sqlite3_fts3_enable_parentheses As SQLITE_C_INT
#endif

Private Function fts3ParenthesesEnabled CDecl Alias "fts3ParenthesesEnabled" () _
    As SQLITE_C_INT
#ifdef SQLITE_TEST
    Return CInt(sqlite3_fts3_enable_parentheses <> 0)
#elseif defined(SQLITE_ENABLE_FTS3_PARENTHESIS)
    Return -1
#else
    Return 0
#endif
End Function

Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub sqlite3Fts3EvalPhraseCleanup CDecl Alias "sqlite3Fts3EvalPhraseCleanup" ( ByVal pPhrase As SqliteFts3Phrase Ptr )
Declare Sub sqlite3Fts3ExprFree CDecl Alias "sqlite3Fts3ExprFree" ( ByVal pDelete As SqliteFts3Expr Ptr )
Declare Function sqlite3Fts3MallocZero CDecl Alias "sqlite3Fts3MallocZero" ( _
    ByVal byteCount As sqlite3_int64 _
) As Any Ptr
Declare Function sqlite3Fts3OpenTokenizer CDecl Alias "sqlite3Fts3OpenTokenizer" ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr, _
    ByVal languageId As SQLITE_C_INT, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppCursor As Fts3TokenizerCursor Ptr Ptr _
) As SQLITE_C_INT
Declare Function sqlite3Fts3InitTokenizer CDecl Alias "sqlite3Fts3InitTokenizer" ( _
    ByVal pHash As Fts3Hash Ptr, _
    ByVal zTokenizer As Const ZString Ptr, _
    ByVal ppTokenizer As Fts3Tokenizer Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr _
) As SQLITE_C_INT

Declare Function fts3isspace CDecl Alias "fts3isspace" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function findBarredChar CDecl Alias "findBarredChar" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3ReallocOrFree CDecl Alias "fts3ReallocOrFree" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function opPrecedence CDecl Alias "opPrecedence" (ByVal arg0 As SqliteFts3Expr Ptr) As c2fb_c_int
Declare Sub insertBinaryOperator CDecl Alias "insertBinaryOperator" (ByVal arg0 As SqliteFts3Expr Ptr Ptr, ByVal arg1 As SqliteFts3Expr Ptr, ByVal arg2 As SqliteFts3Expr Ptr)
Declare Function fts3ExprCheckDepth CDecl Alias "fts3ExprCheckDepth" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3ExprBalance CDecl Alias "fts3ExprBalance" (ByVal arg0 As SqliteFts3Expr Ptr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3ExprParseUnbalanced CDecl Alias "fts3ExprParseUnbalanced" (ByVal arg0 As Fts3Tokenizer Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr, ByVal arg7 As c2fb_c_int, ByVal arg8 As SqliteFts3Expr Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts3ExprParse CDecl Alias "sqlite3Fts3ExprParse" (ByVal arg0 As Fts3Tokenizer Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr, ByVal arg7 As c2fb_c_int, ByVal arg8 As SqliteFts3Expr Ptr Ptr, ByVal arg9 As ZString Ptr Ptr) As c2fb_c_int

Declare Function fts3ExprParse CDecl Alias "fts3ExprParse" ( _
    ByVal pParse As SqliteFts3ParseContext Ptr, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr, _
    ByVal pConsumedBytes As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
Declare Function getNextToken CDecl Alias "getNextToken" ( _
    ByVal pParse As SqliteFts3ParseContext Ptr, _
    ByVal columnIndex As SQLITE_C_INT, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr, _
    ByVal pConsumedBytes As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
Declare Function getNextString CDecl Alias "getNextString" ( _
    ByVal pParse As SqliteFts3ParseContext Ptr, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr _
) As SQLITE_C_INT
Declare Function getNextNode CDecl Alias "getNextNode" ( _
    ByVal pParse As SqliteFts3ParseContext Ptr, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr, _
    ByVal pConsumedBytes As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
Declare Function fts3ReadQueryInteger CDecl Alias "fts3ReadQueryInteger" ( _
    ByVal zInteger As Const ZString Ptr, _
    ByVal maxBytes As SQLITE_C_INT, _
    ByVal pValue As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
Declare Function fts3ParserMemcopy CDecl Alias "memcpy" ( _
    ByVal pDestination As Any Ptr, _
    ByVal pSource As Const Any Ptr, _
    ByVal byteCount As SQLITE_SIZE_T _
) As Any Ptr
Declare Function fts3ParserMemcmp CDecl Alias "memcmp" ( _
    ByVal pLeft As Const Any Ptr, _
    ByVal pRight As Const Any Ptr, _
    ByVal byteCount As SQLITE_SIZE_T _
) As SQLITE_C_INT
Declare Function fts3ParserStrlen CDecl Alias "strlen" ( _
    ByVal zText As Const ZString Ptr _
) As SQLITE_SIZE_T

Private Function fts3isspace CDecl Alias "fts3isspace" (ByVal arg0 As Byte) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 116
    Return (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 32))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 9))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 10))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 13))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 11))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 12))))) <> 0)))))
End Function
' c2fb skipped sqlite3Fts3MallocZero: FreeBASIC body already exists
' c2fb skipped sqlite3Fts3OpenTokenizer: FreeBASIC body already exists
Private Function findBarredChar CDecl Alias "findBarredChar" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 169
    If arg0 = 0 OrElse arg1 <= 0 Then Return -1
    Dim byteIndex As SQLITE_C_INT
    For byteIndex = 0 To arg1 - 1
        Dim currentByte As UByte = CByte(CPtr(Const UByte Ptr, arg0)[byteIndex])
        If currentByte = Asc(Chr(34)) Then Return byteIndex
        If fts3ParenthesesEnabled() <> 0 AndAlso _
           (currentByte = Asc("(") OrElse currentByte = Asc(")")) Then _
            Return byteIndex
    Next
    Return -1
End Function
' c2fb skipped getNextToken: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 193: getNextToken: assignment parser stopped at byte 25 (nByte = sizeof(Fts3Expr) + (                                  __builtin_offsetof (                                  Fts3):  + (                                  __builtin_offsetof (
Private Function fts3ReallocOrFree CDecl Alias "fts3ReallocOrFree" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 280
    Dim local0 As Any Ptr

    local0 = CPtr(Any Ptr, sqlite3_realloc64(arg0, arg1))
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        sqlite3_free(arg0)
    End If
    Return local0
End Function
' c2fb skipped getNextString: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 300: getNextString: expression parser stopped at byte 17 in (sizeof(Fts3Expr) + (                                         __builtin_offsetof (                                       ):  + (                                         __builtin_offsetof (
' c2fb skipped getNextNode: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 417: getNextNode: expression parser stopped at byte 41 in (ii<(int)(sizeof(aKeyword)/sizeof(struct Fts3Keyword))): Fts3Keyword))
Private Function opPrecedence CDecl Alias "opPrecedence" (ByVal arg0 As SqliteFts3Expr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 585
    If arg0 = 0 Then Return 3
    If fts3ParenthesesEnabled() <> 0 Then Return arg0->eType
    If arg0->eType = FTSQUERY_NEAR Then Return 1
    If arg0->eType = FTSQUERY_OR Then Return 2
    Return 3
End Function
Private Sub insertBinaryOperator CDecl Alias "insertBinaryOperator" (ByVal arg0 As SqliteFts3Expr Ptr Ptr, ByVal arg1 As SqliteFts3Expr Ptr, ByVal arg2 As SqliteFts3Expr Ptr)
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 606
    Dim local0 As SqliteFts3Expr Ptr
    Dim c2fb_temp_0 As SqliteFts3Expr Ptr
    Dim c2fb_temp_1 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_2 As SqliteFts3Expr Ptr
    Dim c2fb_temp_3 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_4 As SqliteFts3Expr Ptr
    Dim c2fb_temp_5 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_6 As SqliteFts3Expr Ptr
    Dim c2fb_temp_7 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_8 As SqliteFts3Expr Ptr
    Dim c2fb_temp_9 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_10 As SqliteFts3Expr Ptr

    local0 = arg1
    While (-Cast(c2fb_c_int, (((local0->pParent <> 0) AndAlso ((-Cast(c2fb_c_int, ((opPrecedence(local0->pParent) <= opPrecedence(arg2))))) <> 0)))))
        c2fb_temp_0 = local0->pParent
        local0 = c2fb_temp_0
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If local0->pParent Then
        ' C unused-parameter annotation
        c2fb_temp_1 = CPtr(SqliteFts3Expr Ptr Ptr, @(local0->pParent->pRight))
        c2fb_temp_2 = arg2
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(SqliteFts3Expr Ptr Ptr, @(arg2->pParent))
        c2fb_temp_4 = local0->pParent
        (*c2fb_temp_3) = c2fb_temp_4
    Else
        c2fb_temp_5 = CPtr(SqliteFts3Expr Ptr Ptr, @((*arg0)))
        c2fb_temp_6 = arg2
        (*c2fb_temp_5) = c2fb_temp_6
    End If
    c2fb_temp_7 = CPtr(SqliteFts3Expr Ptr Ptr, @(arg2->pLeft))
    c2fb_temp_8 = local0
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(SqliteFts3Expr Ptr Ptr, @(local0->pParent))
    c2fb_temp_10 = arg2
    (*c2fb_temp_9) = c2fb_temp_10
End Sub
' c2fb skipped fts3ExprParse: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 637: fts3ExprParse: expression parser stopped at byte 39 in (sqlite3Fts3MallocZero(sizeof(Fts3Expr))): )
Private Function fts3ExprCheckDepth CDecl Alias "fts3ExprCheckDepth" (ByVal arg0 As SqliteFts3Expr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 786
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0 Then
        If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 18ULL))
            local0 = c2fb_temp_0
        Else
            c2fb_temp_1 = Cast(c2fb_c_int, fts3ExprCheckDepth(arg0->pLeft, Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
            local0 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, fts3ExprCheckDepth(arg0->pRight, Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
                local0 = c2fb_temp_2
            End If
        End If
    End If
    Return local0
End Function
Private Function fts3ExprBalance CDecl Alias "fts3ExprBalance" (ByVal arg0 As SqliteFts3Expr Ptr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_expr.c
' c2fb source-line: 812
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteFts3Expr Ptr
    Dim local2 As SqliteFts3Expr Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local4 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_1 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As SqliteFts3Expr Ptr
    Dim c2fb_temp_4 As SqliteFts3Expr Ptr
    Dim c2fb_temp_5 As SqliteFts3Expr Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As SqliteFts3Expr Ptr
    Dim c2fb_temp_6 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_7 As SqliteFts3Expr Ptr
    Dim c2fb_temp_8 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_9 As SqliteFts3Expr Ptr
    Dim c2fb_temp_10 As SqliteFts3Expr Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_15 As SqliteFts3Expr Ptr
    Dim c2fb_temp_16 As SqliteFts3Expr Ptr
    Dim c2fb_temp_17 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_18 As SqliteFts3Expr Ptr
    Dim c2fb_temp_19 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_20 As SqliteFts3Expr Ptr
    Dim c2fb_temp_21 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_22 As SqliteFts3Expr Ptr
    Dim c2fb_temp_23 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_24 As SqliteFts3Expr Ptr
    Dim c2fb_temp_25 As SqliteFts3Expr Ptr
    Dim c2fb_temp_26 As SqliteFts3Expr Ptr
    Dim c2fb_temp_27 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_28 As SqliteFts3Expr Ptr
    Dim c2fb_temp_29 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_30 As SqliteFts3Expr Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As SqliteFts3Expr Ptr
    Dim c2fb_temp_33 As SqliteFts3Expr Ptr
    Dim c2fb_temp_34 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_35 As SqliteFts3Expr Ptr
    Dim c2fb_temp_36 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_37 As SqliteFts3Expr Ptr
    Dim c2fb_temp_38 As SqliteFts3Expr Ptr
    Dim c2fb_temp_39 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_40 As SqliteFts3Expr Ptr
    Dim c2fb_temp_41 As SqliteFts3Expr Ptr
    Dim c2fb_temp_42 As SqliteFts3Expr Ptr
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As SqliteFts3Expr Ptr
    Dim c2fb_temp_46 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_47 As SqliteFts3Expr Ptr
    Dim c2fb_temp_48 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_49 As SqliteFts3Expr Ptr
    Dim c2fb_temp_50 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_51 As SqliteFts3Expr Ptr
    Dim c2fb_temp_52 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_53 As SqliteFts3Expr Ptr
    Dim c2fb_temp_54 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_55 As SqliteFts3Expr Ptr
    Dim c2fb_temp_56 As SqliteFts3Expr Ptr
    Dim c2fb_temp_57 As SqliteFts3Expr Ptr
    Dim c2fb_temp_58 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_59 As SqliteFts3Expr Ptr
    Dim c2fb_temp_60 As SqliteFts3Expr Ptr
    Dim local9 As SqliteFts3Expr Ptr
    Dim c2fb_temp_61 As c2fb_c_int
    Dim c2fb_temp_62 As c2fb_c_int
    Dim c2fb_temp_63 As SqliteFts3Expr Ptr
    Dim c2fb_temp_64 As SqliteFts3Expr Ptr
    Dim local10 As SqliteFts3Expr Ptr
    Dim local11 As SqliteFts3Expr Ptr
    Dim c2fb_temp_65 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_66 As SqliteFts3Expr Ptr
    Dim c2fb_temp_67 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_68 As SqliteFts3Expr Ptr
    Dim c2fb_temp_69 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_70 As SqliteFts3Expr Ptr
    Dim c2fb_temp_71 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_72 As SqliteFts3Expr Ptr
    Dim c2fb_temp_73 As c2fb_c_int
    Dim c2fb_temp_74 As c2fb_c_int
    Dim c2fb_temp_75 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_76 As SqliteFts3Expr Ptr
    Dim c2fb_temp_77 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_78 As SqliteFts3Expr Ptr
    Dim c2fb_temp_79 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_80 As SqliteFts3Expr Ptr
    Dim c2fb_temp_81 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_82 As SqliteFts3Expr Ptr
    Dim c2fb_temp_83 As SqliteFts3Expr Ptr
    Dim c2fb_temp_84 As SqliteFts3Expr Ptr Ptr
    Dim c2fb_temp_85 As SqliteFts3Expr Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (*arg0)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = local1->eType
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 4ULL))))) <> 0)))))) Then
            ' C automatic storage declaration
            c2fb_temp_1 = CPtr(SqliteFts3Expr Ptr Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteFts3Expr Ptr))) * Cast(c2fb_uint64, arg1))))))
            local4 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local4)))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_2
            Else
                c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local4), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteFts3Expr Ptr))) * Cast(c2fb_uint64, arg1)))))
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_4 = local1
                local6 = c2fb_temp_4
                While (-Cast(c2fb_c_int, ((local6->eType = local3))))
                    ' C unused-parameter annotation
                    ' C unused-parameter annotation
                c2fb_flow_1:
                    c2fb_temp_5 = local6->pLeft
                    local6 = c2fb_temp_5
                Wend
                c2fb_flow_0:
                While Cast(c2fb_c_int, 1ULL)
                    ' C automatic storage declaration
                    local8 = local6->pParent
                    ' C unused-parameter annotation
                    c2fb_temp_6 = CPtr(SqliteFts3Expr Ptr Ptr, @(local6->pParent))
                    c2fb_temp_7 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_6) = c2fb_temp_7
                    If local8 Then
                        c2fb_temp_8 = CPtr(SqliteFts3Expr Ptr Ptr, @(local8->pLeft))
                        c2fb_temp_9 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                        (*c2fb_temp_8) = c2fb_temp_9
                    Else
                        c2fb_temp_10 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                        local1 = c2fb_temp_10
                    End If
                    c2fb_temp_11 = Cast(c2fb_c_int, fts3ExprBalance(CPtr(SqliteFts3Expr Ptr Ptr, @(local6)), Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
                    local0 = c2fb_temp_11
                    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_2
                    End If
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local7 = c2fb_temp_12
                    While (-Cast(c2fb_c_int, (((local6 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 < arg1)))) <> 0)))))
                        If (-Cast(c2fb_c_int, ((local4[local7] = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_14 = CPtr(SqliteFts3Expr Ptr Ptr, @(local4[local7]))
                            c2fb_temp_15 = local6
                            (*c2fb_temp_14) = c2fb_temp_15
                            c2fb_temp_16 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local6 = c2fb_temp_16
                        Else
                            ' C unused-parameter annotation
                            c2fb_temp_17 = CPtr(SqliteFts3Expr Ptr Ptr, @(local2->pLeft))
                            c2fb_temp_18 = local4[local7]
                            (*c2fb_temp_17) = c2fb_temp_18
                            c2fb_temp_19 = CPtr(SqliteFts3Expr Ptr Ptr, @(local2->pRight))
                            c2fb_temp_20 = local6
                            (*c2fb_temp_19) = c2fb_temp_20
                            c2fb_temp_21 = CPtr(SqliteFts3Expr Ptr Ptr, @(local2->pLeft->pParent))
                            c2fb_temp_22 = local2
                            (*c2fb_temp_21) = c2fb_temp_22
                            c2fb_temp_23 = CPtr(SqliteFts3Expr Ptr Ptr, @(local2->pRight->pParent))
                            c2fb_temp_24 = local2
                            (*c2fb_temp_23) = c2fb_temp_24
                            c2fb_temp_25 = local2
                            local6 = c2fb_temp_25
                            c2fb_temp_26 = local2->pParent
                            local2 = c2fb_temp_26
                            c2fb_temp_27 = CPtr(SqliteFts3Expr Ptr Ptr, @(local6->pParent))
                            c2fb_temp_28 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            (*c2fb_temp_27) = c2fb_temp_28
                            c2fb_temp_29 = CPtr(SqliteFts3Expr Ptr Ptr, @(local4[local7]))
                            c2fb_temp_30 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            (*c2fb_temp_29) = c2fb_temp_30
                        End If
                    c2fb_flow_5:
                        c2fb_temp_13 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                    Wend
                    c2fb_flow_4:
                    If local6 Then
                        sqlite3Fts3ExprFree(local6)
                        c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, 18ULL))
                        local0 = c2fb_temp_31
                        Goto c2fb_flow_2
                    End If
                    If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_2
                    End If
                    c2fb_temp_32 = local8->pRight
                    local6 = c2fb_temp_32
                    While (-Cast(c2fb_c_int, ((local6->eType = local3))))
                        ' empty C statement
                    c2fb_flow_7:
                        c2fb_temp_33 = local6->pLeft
                        local6 = c2fb_temp_33
                    Wend
                    c2fb_flow_6:
                    ' C unused-parameter annotation
                    c2fb_temp_34 = CPtr(SqliteFts3Expr Ptr Ptr, @(local8->pRight->pParent))
                    c2fb_temp_35 = local8->pParent
                    (*c2fb_temp_34) = c2fb_temp_35
                    If local8->pParent Then
                        c2fb_temp_36 = CPtr(SqliteFts3Expr Ptr Ptr, @(local8->pParent->pLeft))
                        c2fb_temp_37 = local8->pRight
                        (*c2fb_temp_36) = c2fb_temp_37
                    Else
                        ' C unused-parameter annotation
                        c2fb_temp_38 = local8->pRight
                        local1 = c2fb_temp_38
                    End If
                    c2fb_temp_39 = CPtr(SqliteFts3Expr Ptr Ptr, @(local8->pParent))
                    c2fb_temp_40 = local2
                    (*c2fb_temp_39) = c2fb_temp_40
                    c2fb_temp_41 = local8
                    local2 = c2fb_temp_41
                c2fb_flow_3:
                Wend
                c2fb_flow_2:
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_42 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local6 = c2fb_temp_42
                    c2fb_temp_43 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local5 = c2fb_temp_43
                    While (-Cast(c2fb_c_int, ((local5 < arg1))))
                        If local4[local5] Then
                            If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_45 = local4[local5]
                                local6 = c2fb_temp_45
                                c2fb_temp_46 = CPtr(SqliteFts3Expr Ptr Ptr, @(local6->pParent))
                                c2fb_temp_47 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                                (*c2fb_temp_46) = c2fb_temp_47
                            Else
                                ' C unused-parameter annotation
                                c2fb_temp_48 = CPtr(SqliteFts3Expr Ptr Ptr, @(local2->pRight))
                                c2fb_temp_49 = local6
                                (*c2fb_temp_48) = c2fb_temp_49
                                c2fb_temp_50 = CPtr(SqliteFts3Expr Ptr Ptr, @(local2->pLeft))
                                c2fb_temp_51 = local4[local5]
                                (*c2fb_temp_50) = c2fb_temp_51
                                c2fb_temp_52 = CPtr(SqliteFts3Expr Ptr Ptr, @(local2->pLeft->pParent))
                                c2fb_temp_53 = local2
                                (*c2fb_temp_52) = c2fb_temp_53
                                c2fb_temp_54 = CPtr(SqliteFts3Expr Ptr Ptr, @(local2->pRight->pParent))
                                c2fb_temp_55 = local2
                                (*c2fb_temp_54) = c2fb_temp_55
                                c2fb_temp_56 = local2
                                local6 = c2fb_temp_56
                                c2fb_temp_57 = local2->pParent
                                local2 = c2fb_temp_57
                                c2fb_temp_58 = CPtr(SqliteFts3Expr Ptr Ptr, @(local6->pParent))
                                c2fb_temp_59 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                                (*c2fb_temp_58) = c2fb_temp_59
                            End If
                        End If
                    c2fb_flow_9:
                        c2fb_temp_44 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_44 + 1)))
                    Wend
                    c2fb_flow_8:
                    c2fb_temp_60 = local6
                    local1 = c2fb_temp_60
                Else
                    ' C automatic storage declaration
                    c2fb_temp_61 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local5 = c2fb_temp_61
                    While (-Cast(c2fb_c_int, ((local5 < arg1))))
                        sqlite3Fts3ExprFree(local4[local5])
                    c2fb_flow_11:
                        c2fb_temp_62 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_62 + 1)))
                    Wend
                    c2fb_flow_10:
                    Do
                        c2fb_temp_63 = local2
                        local9 = c2fb_temp_63
                        If ((-Cast(c2fb_c_int, (((c2fb_temp_63) <> Cast(c2fb_c_int, &O0ULL))))) = 0) Then Goto c2fb_flow_12
                        c2fb_temp_64 = local9->pParent
                        local2 = c2fb_temp_64
                        sqlite3_free(CPtr(Any Ptr, local9))
                    c2fb_flow_13:
                    Loop
                    c2fb_flow_12:
                End If
                ' C unused-parameter annotation
                sqlite3_free(CPtr(Any Ptr, local4))
            End If
        Else
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 2ULL))))) Then
                local10 = local1->pLeft
                local11 = local1->pRight
                c2fb_temp_65 = CPtr(SqliteFts3Expr Ptr Ptr, @(local1->pLeft))
                c2fb_temp_66 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_65) = c2fb_temp_66
                c2fb_temp_67 = CPtr(SqliteFts3Expr Ptr Ptr, @(local1->pRight))
                c2fb_temp_68 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_67) = c2fb_temp_68
                c2fb_temp_69 = CPtr(SqliteFts3Expr Ptr Ptr, @(local10->pParent))
                c2fb_temp_70 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_69) = c2fb_temp_70
                c2fb_temp_71 = CPtr(SqliteFts3Expr Ptr Ptr, @(local11->pParent))
                c2fb_temp_72 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_71) = c2fb_temp_72
                c2fb_temp_73 = Cast(c2fb_c_int, fts3ExprBalance(CPtr(SqliteFts3Expr Ptr Ptr, @(local10)), Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
                local0 = c2fb_temp_73
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_74 = Cast(c2fb_c_int, fts3ExprBalance(CPtr(SqliteFts3Expr Ptr Ptr, @(local11)), Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))))
                    local0 = c2fb_temp_74
                End If
                If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    sqlite3Fts3ExprFree(local11)
                    sqlite3Fts3ExprFree(local10)
                Else
                    ' C unused-parameter annotation
                    c2fb_temp_75 = CPtr(SqliteFts3Expr Ptr Ptr, @(local1->pLeft))
                    c2fb_temp_76 = local10
                    (*c2fb_temp_75) = c2fb_temp_76
                    c2fb_temp_77 = CPtr(SqliteFts3Expr Ptr Ptr, @(local10->pParent))
                    c2fb_temp_78 = local1
                    (*c2fb_temp_77) = c2fb_temp_78
                    c2fb_temp_79 = CPtr(SqliteFts3Expr Ptr Ptr, @(local1->pRight))
                    c2fb_temp_80 = local11
                    (*c2fb_temp_79) = c2fb_temp_80
                    c2fb_temp_81 = CPtr(SqliteFts3Expr Ptr Ptr, @(local11->pParent))
                    c2fb_temp_82 = local1
                    (*c2fb_temp_81) = c2fb_temp_82
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3Fts3ExprFree(local1)
        c2fb_temp_83 = CPtr(SqliteFts3Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_83
    End If
    c2fb_temp_84 = CPtr(SqliteFts3Expr Ptr Ptr, @((*arg0)))
    c2fb_temp_85 = local1
    (*c2fb_temp_84) = c2fb_temp_85
    Return local0
End Function
' c2fb skipped fts3ExprParseUnbalanced: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 986: fts3ExprParseUnbalanced: assignment parser stopped at byte 40 (memset(&sParse, 0, sizeof(ParseContext))): )
Const SQLITE_FTS3_MAX_EXPR_DEPTH As SQLITE_C_INT = 12

Function sqlite3Fts3ExprParse CDecl Alias "sqlite3Fts3ExprParse" ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr, _
    ByVal languageId As SQLITE_C_INT, _
    ByVal azColumn As ZString Ptr Ptr, _
    ByVal isFts4 As SQLITE_C_INT, _
    ByVal columnCount As SQLITE_C_INT, _
    ByVal defaultColumn As SQLITE_C_INT, _
    ByVal zQuery As Const ZString Ptr, _
    ByVal queryBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr _
) As SQLITE_C_INT Export
    If ppExpression = 0 Then Return SQLITE_MISUSE
    *ppExpression = 0
    If pzError <> 0 Then *pzError = 0

    Dim rc As SQLITE_C_INT = fts3ExprParseUnbalanced( _
        pTokenizer, languageId, azColumn, isFts4, columnCount, _
        defaultColumn, zQuery, queryBytes, ppExpression)

    If rc = SQLITE_OK AndAlso *ppExpression <> 0 Then
        rc = fts3ExprBalance(ppExpression, SQLITE_FTS3_MAX_EXPR_DEPTH)
        If rc = SQLITE_OK Then _
            rc = fts3ExprCheckDepth(*ppExpression, SQLITE_FTS3_MAX_EXPR_DEPTH)
    End If

    If rc <> SQLITE_OK Then
        sqlite3Fts3ExprFree(*ppExpression)
        *ppExpression = 0
        If rc = SQLITE_TOOBIG AndAlso pzError <> 0 Then
            c2fb_external_sqlite3Fts3ErrMsg( _
                pzError, _
                StrPtr("FTS expression tree is too large (maximum depth %d)"), _
                SQLITE_FTS3_MAX_EXPR_DEPTH)
            rc = SQLITE_ERROR
        ElseIf rc = SQLITE_ERROR AndAlso pzError <> 0 Then
            c2fb_external_sqlite3Fts3ErrMsg( _
                pzError, StrPtr("malformed MATCH expression: [%s]"), zQuery)
        ElseIf rc = SQLITE_TOOBIG Then
            rc = SQLITE_ERROR
        End If
    End If

    Return rc
End Function
' c2fb skipped sqlite3Fts3ExprFree: FreeBASIC body already exists



Private Function fts3ReadQueryInteger CDecl Alias "fts3ReadQueryInteger" ( _
    ByVal zInteger As Const ZString Ptr, _
    ByVal maxBytes As SQLITE_C_INT, _
    ByVal pValue As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
    If zInteger = 0 OrElse pValue = 0 OrElse maxBytes <= 0 Then Return 0

    Dim byteIndex As SQLITE_C_INT
    Dim value As sqlite3_uint64 = 0
    For byteIndex = 0 To maxBytes - 1
        Dim digitByte As UByte = CByte(CPtr(Const UByte Ptr, zInteger)[byteIndex])
        If digitByte < Asc("0") OrElse digitByte > Asc("9") Then Exit For

        value = value * 10 + (digitByte - Asc("0"))
        If value > &H7FFFFFFF Then Return -1
    Next

    *pValue = CInt(value)
    Return byteIndex
End Function

Private Function getNextToken CDecl Alias "getNextToken" ( _
    ByVal pParse As SqliteFts3ParseContext Ptr, _
    ByVal columnIndex As SQLITE_C_INT, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr, _
    ByVal pConsumedBytes As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
    If pParse = 0 OrElse ppExpression = 0 OrElse pConsumedBytes = 0 Then _
        Return SQLITE_MISUSE
    *ppExpression = 0
    *pConsumedBytes = inputBytes
    If inputBytes < 0 OrElse (zInput = 0 AndAlso inputBytes <> 0) Then _
        Return SQLITE_MISUSE
    If pParse->pTokenizer = 0 OrElse pParse->pTokenizer->pModule = 0 Then _
        Return SQLITE_MISUSE

    Dim pTokenizer As Fts3Tokenizer Ptr = pParse->pTokenizer
    Dim pModule As Const Fts3TokenizerModule Ptr = _
        CPtr(Const Fts3TokenizerModule Ptr, pTokenizer->pModule)
    If pModule->xNext = 0 OrElse pModule->xClose = 0 Then _
        Return SQLITE_MISUSE

    Dim pCursor As Fts3TokenizerCursor Ptr = 0
    Dim rc As SQLITE_C_INT = sqlite3Fts3OpenTokenizer( _
        pTokenizer, pParse->iLangid, zInput, inputBytes, @pCursor)
    If rc <> SQLITE_OK Then Return rc
    If pCursor = 0 Then Return SQLITE_ERROR

    Dim pExpression As SqliteFts3Expr Ptr = 0
    Dim tokenBytes As SQLITE_C_INT = 0
    Dim startOffset As SQLITE_C_INT = 0
    Dim endOffset As SQLITE_C_INT = 0
    Dim tokenPosition As SQLITE_C_INT = 0
    Dim zToken As Const ZString Ptr = 0
    rc = pModule->xNext( _
        pCursor, @zToken, @tokenBytes, @startOffset, @endOffset, @tokenPosition)

    If rc = SQLITE_OK Then
        If tokenBytes <= 0 OrElse zToken = 0 OrElse _
           startOffset < 0 OrElse endOffset < startOffset OrElse _
           endOffset > inputBytes Then
            rc = SQLITE_ERROR
        Else
            Dim barredOffset As SQLITE_C_INT = _
                findBarredChar(zInput, endOffset)
            If barredOffset >= 0 Then
                pModule->xClose(pCursor)
                pCursor = 0
                If barredOffset = 0 Then Return SQLITE_ERROR
                Return getNextToken( _
                    pParse, columnIndex, zInput, barredOffset, _
                    ppExpression, pConsumedBytes)
            End If

            Dim allocationBytes As sqlite3_uint64 = _
                Cast(sqlite3_uint64, SizeOf(SqliteFts3Expr)) + _
                Cast(sqlite3_uint64, OffsetOf(SqliteFts3Phrase, aToken(0))) + _
                Cast(sqlite3_uint64, SizeOf(SqliteFts3PhraseToken)) + _
                Cast(sqlite3_uint64, tokenBytes)
            If allocationBytes > Cast(sqlite3_uint64, &H7FFFFFFFFFFFFFFF) Then
                rc = SQLITE_TOOBIG
            Else
                pExpression = CPtr(SqliteFts3Expr Ptr, _
                    sqlite3Fts3MallocZero(Cast(sqlite3_int64, allocationBytes)))
                If pExpression = 0 Then
                    rc = SQLITE_NOMEM
                Else
                    pExpression->eType = FTSQUERY_PHRASE
                    pExpression->pPhrase = CPtr( _
                        SqliteFts3Phrase Ptr, _
                        CPtr(UByte Ptr, pExpression) + SizeOf(SqliteFts3Expr))

                    Dim pPhrase As SqliteFts3Phrase Ptr = pExpression->pPhrase
                    pPhrase->nToken = 1
                    pPhrase->iColumn = columnIndex

                    Dim pToken As SqliteFts3PhraseToken Ptr = _
                        @pPhrase->aToken(0)
                    pToken->n = tokenBytes
                    pToken->z = CPtr(ZString Ptr, _
                        CPtr(UByte Ptr, pToken) + _
                        SizeOf(SqliteFts3PhraseToken))
                    fts3ParserMemcopy( _
                        pToken->z, zToken, Cast(SQLITE_SIZE_T, tokenBytes))

                    If endOffset < inputBytes AndAlso _
                       CPtr(Const UByte Ptr, zInput)[endOffset] = Asc("*") Then
                        pToken->isPrefix = 1
                        endOffset += 1
                    End If

                    While 1
                        If fts3ParenthesesEnabled() = 0 AndAlso _
                           startOffset > 0 AndAlso _
                           CPtr(Const UByte Ptr, zInput)[startOffset - 1] = Asc("-") Then
                            pParse->isNot = 1
                            startOffset -= 1
                        ElseIf pParse->bFts4 <> 0 AndAlso startOffset > 0 AndAlso _
                               CPtr(Const UByte Ptr, zInput)[startOffset - 1] = Asc("^") Then
                            pToken->bFirst = 1
                            startOffset -= 1
                        Else
                            Exit While
                        End If
                    Wend
                    *pConsumedBytes = endOffset
                End If
            End If
        End If
    ElseIf rc = SQLITE_DONE Then
        If inputBytes > 0 Then
            Dim barredOffset As SQLITE_C_INT = _
                findBarredChar(zInput, inputBytes)
            If barredOffset >= 0 Then *pConsumedBytes = barredOffset
        End If
        rc = SQLITE_OK
    End If

    pModule->xClose(pCursor)
    *ppExpression = pExpression
    Return rc
End Function

Private Function getNextString CDecl Alias "getNextString" ( _
    ByVal pParse As SqliteFts3ParseContext Ptr, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr _
) As SQLITE_C_INT
    If pParse = 0 OrElse ppExpression = 0 Then Return SQLITE_MISUSE
    *ppExpression = 0
    If inputBytes < 0 OrElse (zInput = 0 AndAlso inputBytes <> 0) Then _
        Return SQLITE_MISUSE
    If pParse->pTokenizer = 0 OrElse pParse->pTokenizer->pModule = 0 Then _
        Return SQLITE_MISUSE

    Dim pTokenizer As Fts3Tokenizer Ptr = pParse->pTokenizer
    Dim pModule As Const Fts3TokenizerModule Ptr = _
        CPtr(Const Fts3TokenizerModule Ptr, pTokenizer->pModule)
    If pModule->xNext = 0 OrElse pModule->xClose = 0 Then _
        Return SQLITE_MISUSE

    Dim pCursor As Fts3TokenizerCursor Ptr = 0
    Dim rc As SQLITE_C_INT = sqlite3Fts3OpenTokenizer( _
        pTokenizer, pParse->iLangid, zInput, inputBytes, @pCursor)
    If rc <> SQLITE_OK Then Return rc
    If pCursor = 0 Then Return SQLITE_ERROR

    Dim pTokenArray As SqliteFts3PhraseToken Ptr = 0
    Dim pTokenText As ZString Ptr = 0
    Dim pExpression As SqliteFts3Expr Ptr = 0
    Dim tokenCount As SQLITE_C_INT = 0
    Dim tokenTextBytes As sqlite3_int64 = 0

    Do
        Dim zToken As Const ZString Ptr = 0
        Dim tokenBytes As SQLITE_C_INT = 0
        Dim startOffset As SQLITE_C_INT = 0
        Dim endOffset As SQLITE_C_INT = 0
        Dim tokenPosition As SQLITE_C_INT = 0
        rc = pModule->xNext( _
            pCursor, @zToken, @tokenBytes, @startOffset, @endOffset, _
            @tokenPosition)
        If rc <> SQLITE_OK Then Exit Do

        If zToken = 0 OrElse tokenBytes <= 0 OrElse _
           startOffset < 0 OrElse endOffset < startOffset OrElse _
           endOffset > inputBytes Then
            rc = SQLITE_ERROR
            Exit Do
        End If
        If tokenCount = &H7FFFFFFF OrElse _
           tokenTextBytes > &H7FFFFFFFFFFFFFFF - tokenBytes Then
            rc = SQLITE_TOOBIG
            Exit Do
        End If

        Dim nextTokenCount As SQLITE_C_INT = tokenCount + 1
        Dim tokenArrayBytes As sqlite3_uint64 = _
            Cast(sqlite3_uint64, nextTokenCount) * _
            Cast(sqlite3_uint64, SizeOf(SqliteFts3PhraseToken))
        pTokenArray = CPtr(SqliteFts3PhraseToken Ptr, _
            fts3ReallocOrFree(pTokenArray, Cast(sqlite3_int64, tokenArrayBytes)))
        If pTokenArray = 0 Then
            rc = SQLITE_NOMEM
            Exit Do
        End If

        c2fb_crt_memset(@pTokenArray[tokenCount], 0, _
            SizeOf(SqliteFts3PhraseToken))
        Dim nextTextBytes As sqlite3_int64 = tokenTextBytes + tokenBytes
        pTokenText = CPtr(ZString Ptr, _
            fts3ReallocOrFree(pTokenText, nextTextBytes))
        If pTokenText = 0 Then
            rc = SQLITE_NOMEM
            Exit Do
        End If

        fts3ParserMemcopy( _
            CPtr(UByte Ptr, pTokenText) + tokenTextBytes, _
            zToken, Cast(SQLITE_SIZE_T, tokenBytes))
        pTokenArray[tokenCount].n = tokenBytes
        If endOffset < inputBytes AndAlso _
           CPtr(Const UByte Ptr, zInput)[endOffset] = Asc("*") Then _
            pTokenArray[tokenCount].isPrefix = 1
        If startOffset > 0 AndAlso _
           CPtr(Const UByte Ptr, zInput)[startOffset - 1] = Asc("^") Then _
            pTokenArray[tokenCount].bFirst = 1

        tokenCount = nextTokenCount
        tokenTextBytes = nextTextBytes
    Loop

    If rc = SQLITE_DONE Then
        Dim oneTokenBytes As sqlite3_uint64 = _
            Cast(sqlite3_uint64, SizeOf(SqliteFts3PhraseToken))
        Dim phraseOffset As sqlite3_uint64 = _
            Cast(sqlite3_uint64, OffsetOf(SqliteFts3Phrase, aToken(0)))
        Dim allocationBytes As sqlite3_uint64 = _
            Cast(sqlite3_uint64, SizeOf(SqliteFts3Expr)) + phraseOffset + _
            oneTokenBytes + _
            Cast(sqlite3_uint64, tokenCount) * oneTokenBytes + _
            Cast(sqlite3_uint64, tokenTextBytes)

        If allocationBytes > Cast(sqlite3_uint64, &H7FFFFFFFFFFFFFFF) Then
            rc = SQLITE_TOOBIG
        Else
            pExpression = CPtr(SqliteFts3Expr Ptr, _
                sqlite3Fts3MallocZero(Cast(sqlite3_int64, allocationBytes)))
            If pExpression = 0 Then
                rc = SQLITE_NOMEM
            Else
                pExpression->eType = FTSQUERY_PHRASE
                pExpression->pPhrase = CPtr( _
                    SqliteFts3Phrase Ptr, _
                    CPtr(UByte Ptr, pExpression) + SizeOf(SqliteFts3Expr))
                pExpression->pPhrase->iColumn = pParse->iDefaultCol
                pExpression->pPhrase->nToken = tokenCount

                Dim pFinalTokens As SqliteFts3PhraseToken Ptr = _
                    @pExpression->pPhrase->aToken(0)
                Dim finalTokenBytes As SQLITE_SIZE_T = _
                    Cast(SQLITE_SIZE_T, tokenCount) * _
                    SizeOf(SqliteFts3PhraseToken)
                If tokenCount > 0 Then _
                    fts3ParserMemcopy(pFinalTokens, pTokenArray, finalTokenBytes)

                Dim pTextCursor As UByte Ptr = _
                    CPtr(UByte Ptr, pFinalTokens) + finalTokenBytes
                If tokenTextBytes > 0 Then _
                    fts3ParserMemcopy(pTextCursor, pTokenText, _
                                      Cast(SQLITE_SIZE_T, tokenTextBytes))

                Dim tokenIndex As SQLITE_C_INT
                For tokenIndex = 0 To tokenCount - 1
                    pFinalTokens[tokenIndex].z = CPtr(ZString Ptr, pTextCursor)
                    pTextCursor += pFinalTokens[tokenIndex].n
                Next
                rc = SQLITE_OK
            End If
        End If
    End If

    pModule->xClose(pCursor)
    sqlite3_free(CPtr(Any Ptr, pTokenArray))
    sqlite3_free(CPtr(Any Ptr, pTokenText))
    If rc <> SQLITE_OK Then
        sqlite3_free(CPtr(Any Ptr, pExpression))
        pExpression = 0
    End If
    *ppExpression = pExpression
    Return rc
End Function

Private Function getNextNode CDecl Alias "getNextNode" ( _
    ByVal pParse As SqliteFts3ParseContext Ptr, _
    ByVal z As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr, _
    ByVal pConsumedBytes As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
    If pParse = 0 OrElse ppExpression = 0 OrElse pConsumedBytes = 0 Then _
        Return SQLITE_MISUSE
    *ppExpression = 0
    *pConsumedBytes = 0
    If inputBytes < 0 OrElse (z = 0 AndAlso inputBytes <> 0) Then _
        Return SQLITE_MISUSE

    Dim zInput As Const ZString Ptr = z
    Dim nInput As SQLITE_C_INT = inputBytes
    Dim skippedBytes As SQLITE_C_INT = 0
    pParse->isNot = 0

    While nInput > 0 AndAlso _
          fts3isspace(CByte(CPtr(Const UByte Ptr, zInput)[0])) <> 0
        zInput = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, zInput) + 1)
        nInput -= 1
        skippedBytes += 1
    Wend
    If nInput = 0 Then Return SQLITE_DONE

    Dim keywordType As SQLITE_C_INT = 0
    Dim keywordBytes As SQLITE_C_INT = 0
    Dim isParenOnlyKeyword As SQLITE_C_INT = 0
    Dim nearDistance As SQLITE_C_INT = SQLITE_FTS3_DEFAULT_NEAR_PARAM

    If nInput >= 2 AndAlso _
       fts3ParserMemcmp(zInput, StrPtr("OR"), 2) = 0 Then
        keywordType = FTSQUERY_OR
        keywordBytes = 2
    ElseIf nInput >= 3 AndAlso _
           fts3ParserMemcmp(zInput, StrPtr("AND"), 3) = 0 Then
        keywordType = FTSQUERY_AND
        keywordBytes = 3
        isParenOnlyKeyword = 1
    ElseIf nInput >= 3 AndAlso _
           fts3ParserMemcmp(zInput, StrPtr("NOT"), 3) = 0 Then
        keywordType = FTSQUERY_NOT
        keywordBytes = 3
        isParenOnlyKeyword = 1
    ElseIf nInput >= 4 AndAlso _
           fts3ParserMemcmp(zInput, StrPtr("NEAR"), 4) = 0 Then
        keywordType = FTSQUERY_NEAR
        keywordBytes = 4
    End If

    If keywordType <> 0 AndAlso _
       (isParenOnlyKeyword = 0 OrElse fts3ParenthesesEnabled() <> 0) Then
        If keywordType = FTSQUERY_NEAR AndAlso nInput >= 6 AndAlso _
           CPtr(Const UByte Ptr, zInput)[4] = Asc("/") AndAlso _
           CPtr(Const UByte Ptr, zInput)[5] >= Asc("0") AndAlso _
           CPtr(Const UByte Ptr, zInput)[5] <= Asc("9") Then
            Dim distanceBytes As SQLITE_C_INT = fts3ReadQueryInteger( _
                CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, zInput) + 5), _
                nInput - 5, @nearDistance)
            If distanceBytes >= 0 Then _
                keywordBytes += 1 + distanceBytes
            If nearDistance >= 1000000000 Then nearDistance = 1000000000
        End If

        Dim nextByte As UByte = 0
        If keywordBytes < nInput Then _
            nextByte = CByte(CPtr(Const UByte Ptr, zInput)[keywordBytes])
        If fts3isspace(CByte(nextByte)) <> 0 OrElse _
           nextByte = Asc(Chr(34)) OrElse nextByte = Asc("(") OrElse _
           nextByte = Asc(")") OrElse nextByte = 0 Then
            Dim pOperator As SqliteFts3Expr Ptr = CPtr( _
                SqliteFts3Expr Ptr, sqlite3Fts3MallocZero(SizeOf(SqliteFts3Expr)))
            If pOperator = 0 Then Return SQLITE_NOMEM
            pOperator->eType = keywordType
            pOperator->nNear = nearDistance
            *ppExpression = pOperator
            *pConsumedBytes = skippedBytes + keywordBytes
            Return SQLITE_OK
        End If
    End If

    If CPtr(Const UByte Ptr, zInput)[0] = Asc(Chr(34)) Then
        Dim quoteEnd As SQLITE_C_INT = 1
        While quoteEnd < nInput AndAlso _
              CPtr(Const UByte Ptr, zInput)[quoteEnd] <> Asc(Chr(34))
            quoteEnd += 1
        Wend
        *pConsumedBytes = skippedBytes + quoteEnd + 1
        If quoteEnd = nInput Then Return SQLITE_ERROR
        Return getNextString( _
            pParse, _
            CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, zInput) + 1), _
            quoteEnd - 1, ppExpression)
    End If

    If fts3ParenthesesEnabled() <> 0 Then
        Dim firstByte As UByte = CByte(CPtr(Const UByte Ptr, zInput)[0])
        If firstByte = Asc("(") Then
            pParse->nNest += 1
#if defined(SQLITE_MAX_EXPR_DEPTH)
#if SQLITE_MAX_EXPR_DEPTH > 0
            If pParse->nNest > SQLITE_MAX_EXPR_DEPTH Then
                *pConsumedBytes = skippedBytes + 1
                Return SQLITE_ERROR
            End If
#endif
#else
            If pParse->nNest > 1000 Then
                *pConsumedBytes = skippedBytes + 1
                Return SQLITE_ERROR
            End If
#endif
            Dim nestedBytes As SQLITE_C_INT = 0
            Dim rc As SQLITE_C_INT = fts3ExprParse( _
                pParse, _
                CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, zInput) + 1), _
                nInput - 1, ppExpression, @nestedBytes)
            *pConsumedBytes = skippedBytes + 1 + nestedBytes
            Return rc
        ElseIf firstByte = Asc(")") Then
            pParse->nNest -= 1
            *pConsumedBytes = skippedBytes + 1
            Return SQLITE_DONE
        End If
    End If

    Dim columnIndex As SQLITE_C_INT = pParse->iDefaultCol
    Dim columnPrefixBytes As SQLITE_C_INT = 0
    If pParse->nCol < 0 Then Return SQLITE_MISUSE
    If pParse->nCol > 0 AndAlso pParse->azCol = 0 Then Return SQLITE_MISUSE

    Dim columnNumber As SQLITE_C_INT
    For columnNumber = 0 To pParse->nCol - 1
        Dim zColumn As Const ZString Ptr = pParse->azCol[columnNumber]
        Dim zColumnForCompare As Const ZString Ptr = zColumn
        Dim columnNameBytes As SQLITE_C_INT = 0
        If zColumn = 0 Then
            zColumnForCompare = StrPtr("")
        Else
            Dim nameBytes As SQLITE_SIZE_T = fts3ParserStrlen(zColumn)
            If nameBytes > &H7FFFFFFF Then Return SQLITE_TOOBIG
            columnNameBytes = CInt(nameBytes)
        End If

        If nInput > columnNameBytes AndAlso _
           CPtr(Const UByte Ptr, zInput)[columnNameBytes] = Asc(":") AndAlso _
           sqlite3_strnicmp(zColumnForCompare, zInput, columnNameBytes) = 0 Then
            columnIndex = columnNumber
            columnPrefixBytes = skippedBytes + columnNameBytes + 1
            Exit For
        End If
    Next

    Dim relativeConsumed As SQLITE_C_INT = 0
    Dim rc As SQLITE_C_INT = getNextToken( _
        pParse, columnIndex, _
        CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, z) + columnPrefixBytes), _
        inputBytes - columnPrefixBytes, ppExpression, @relativeConsumed)
    *pConsumedBytes = columnPrefixBytes + relativeConsumed
    Return rc
End Function

Private Function fts3ExprParse CDecl Alias "fts3ExprParse" ( _
    ByVal pParse As SqliteFts3ParseContext Ptr, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr, _
    ByVal pConsumedBytes As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
    If pParse = 0 OrElse ppExpression = 0 OrElse pConsumedBytes = 0 Then _
        Return SQLITE_MISUSE
    *ppExpression = 0
    *pConsumedBytes = 0
    If inputBytes < 0 OrElse (zInput = 0 AndAlso inputBytes <> 0) Then _
        Return SQLITE_MISUSE

    Dim pRoot As SqliteFts3Expr Ptr = 0
    Dim pPrevious As SqliteFts3Expr Ptr = 0
    Dim pNotBranch As SqliteFts3Expr Ptr = 0
    Dim remainingBytes As SQLITE_C_INT = inputBytes
    Dim zCurrent As Const ZString Ptr = zInput
    Dim rc As SQLITE_C_INT = SQLITE_OK
    Dim isPhraseRequired As SQLITE_C_INT = 1

    While rc = SQLITE_OK
        Dim pNode As SqliteFts3Expr Ptr = 0
        Dim nodeBytes As SQLITE_C_INT = 0
        rc = getNextNode( _
            pParse, zCurrent, remainingBytes, @pNode, @nodeBytes)

        If rc = SQLITE_OK Then
            If nodeBytes <= 0 OrElse nodeBytes > remainingBytes Then
                sqlite3Fts3ExprFree(pNode)
                rc = SQLITE_ERROR
                Exit While
            End If

            If pNode <> 0 Then
                If fts3ParenthesesEnabled() = 0 AndAlso _
                   pNode->eType = FTSQUERY_PHRASE AndAlso pParse->isNot <> 0 Then
                    Dim pNot As SqliteFts3Expr Ptr = CPtr( _
                        SqliteFts3Expr Ptr, _
                        sqlite3Fts3MallocZero(SizeOf(SqliteFts3Expr)))
                    If pNot = 0 Then
                        sqlite3Fts3ExprFree(pNode)
                        rc = SQLITE_NOMEM
                        Exit While
                    End If
                    pNot->eType = FTSQUERY_NOT
                    pNot->pRight = pNode
                    pNode->pParent = pNot
                    If pNotBranch <> 0 Then
                        pNot->pLeft = pNotBranch
                        pNotBranch->pParent = pNot
                    End If
                    pNotBranch = pNot
                    pNode = pPrevious
                Else
                    Dim isPhrase As SQLITE_C_INT = 0
                    Dim nodeType As SQLITE_C_INT = pNode->eType
                    If nodeType = FTSQUERY_PHRASE OrElse pNode->pLeft <> 0 Then _
                        isPhrase = 1

                    If isPhrase = 0 AndAlso isPhraseRequired <> 0 Then
                        sqlite3Fts3ExprFree(pNode)
                        rc = SQLITE_ERROR
                        Exit While
                    End If

                    If isPhrase <> 0 AndAlso isPhraseRequired = 0 Then
                        If pRoot = 0 OrElse pPrevious = 0 Then
                            sqlite3Fts3ExprFree(pNode)
                            rc = SQLITE_ERROR
                            Exit While
                        End If
                        Dim pAnd As SqliteFts3Expr Ptr = CPtr( _
                            SqliteFts3Expr Ptr, _
                            sqlite3Fts3MallocZero(SizeOf(SqliteFts3Expr)))
                        If pAnd = 0 Then
                            sqlite3Fts3ExprFree(pNode)
                            rc = SQLITE_NOMEM
                            Exit While
                        End If
                        pAnd->eType = FTSQUERY_AND
                        insertBinaryOperator(@pRoot, pPrevious, pAnd)
                        pPrevious = pAnd
                    End If

                    If pPrevious <> 0 AndAlso _
                       ((nodeType = FTSQUERY_NEAR AndAlso isPhrase = 0 AndAlso _
                         pPrevious->eType <> FTSQUERY_PHRASE) OrElse _
                        (nodeType <> FTSQUERY_PHRASE AndAlso isPhrase <> 0 AndAlso _
                         pPrevious->eType = FTSQUERY_NEAR)) Then
                        sqlite3Fts3ExprFree(pNode)
                        rc = SQLITE_ERROR
                        Exit While
                    End If

                    If isPhrase <> 0 Then
                        If pRoot <> 0 Then
                            If pPrevious = 0 OrElse pPrevious->pLeft = 0 OrElse _
                               pPrevious->pRight <> 0 Then
                                sqlite3Fts3ExprFree(pNode)
                                rc = SQLITE_ERROR
                                Exit While
                            End If
                            pPrevious->pRight = pNode
                            pNode->pParent = pPrevious
                        Else
                            pRoot = pNode
                        End If
                    Else
                        insertBinaryOperator(@pRoot, pPrevious, pNode)
                    End If
                    isPhraseRequired = 1 - isPhrase
                End If
                pPrevious = pNode
            End If
        ElseIf rc = SQLITE_DONE Then
            If nodeBytes < 0 OrElse nodeBytes > remainingBytes Then
                rc = SQLITE_ERROR
                Exit While
            End If
        Else
            Exit While
        End If

        remainingBytes -= nodeBytes
        If zCurrent <> 0 Then _
            zCurrent = CPtr(Const ZString Ptr, _
                CPtr(Const UByte Ptr, zCurrent) + nodeBytes)
    Wend

    If rc = SQLITE_DONE AndAlso pRoot <> 0 AndAlso isPhraseRequired <> 0 Then _
        rc = SQLITE_ERROR

    If rc = SQLITE_DONE Then
        rc = SQLITE_OK
        If fts3ParenthesesEnabled() = 0 AndAlso pNotBranch <> 0 Then
            If pRoot = 0 Then
                rc = SQLITE_ERROR
            Else
                Dim pLeftMost As SqliteFts3Expr Ptr = pNotBranch
                While pLeftMost->pLeft <> 0
                    pLeftMost = pLeftMost->pLeft
                Wend
                pLeftMost->pLeft = pRoot
                pRoot->pParent = pLeftMost
                pRoot = pNotBranch
            End If
        End If
    End If

    *pConsumedBytes = inputBytes - remainingBytes
    If rc <> SQLITE_OK Then
        sqlite3Fts3ExprFree(pRoot)
        sqlite3Fts3ExprFree(pNotBranch)
        pRoot = 0
    End If
    *ppExpression = pRoot
    Return rc
End Function

Private Function fts3ExprParseUnbalanced CDecl Alias "fts3ExprParseUnbalanced" ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr, _
    ByVal languageId As SQLITE_C_INT, _
    ByVal azColumn As ZString Ptr Ptr, _
    ByVal isFts4 As SQLITE_C_INT, _
    ByVal columnCount As SQLITE_C_INT, _
    ByVal defaultColumn As SQLITE_C_INT, _
    ByVal zQuery As Const ZString Ptr, _
    ByVal queryBytes As SQLITE_C_INT, _
    ByVal ppExpression As SqliteFts3Expr Ptr Ptr _
) As SQLITE_C_INT
    If ppExpression = 0 Then Return SQLITE_MISUSE
    *ppExpression = 0
    If zQuery = 0 Then Return SQLITE_OK

    Dim pParse As SqliteFts3ParseContext
    c2fb_crt_memset(@pParse, 0, SizeOf(SqliteFts3ParseContext))
    pParse.pTokenizer = pTokenizer
    pParse.iLangid = languageId
    pParse.azCol = CPtr(Const ZString Ptr Ptr, azColumn)
    pParse.bFts4 = isFts4
    pParse.nCol = columnCount
    pParse.iDefaultCol = defaultColumn

    Dim inputBytes As SQLITE_C_INT = queryBytes
    If inputBytes < 0 Then
        Dim querySize As SQLITE_SIZE_T = fts3ParserStrlen(zQuery)
        If querySize > &H7FFFFFFF Then Return SQLITE_TOOBIG
        inputBytes = CInt(querySize)
    End If

    Dim consumedBytes As SQLITE_C_INT = 0
    Dim rc As SQLITE_C_INT = fts3ExprParse( _
        @pParse, zQuery, inputBytes, ppExpression, @consumedBytes)
#ifdef SQLITE_DEBUG
    If rc <> SQLITE_OK AndAlso *ppExpression <> 0 Then _
        sqlite3DebugAssert(StrPtr("rc==SQLITE_OK || *ppExpr==0"))
#endif
    If rc = SQLITE_OK AndAlso pParse.nNest <> 0 Then rc = SQLITE_ERROR
    Return rc
End Function

#if defined(SQLITE_TEST)
' -------------------------------------------------------------------------
' FTS3 expression test SQL functions
' -------------------------------------------------------------------------

Private Function fts3ExprTestToString( _
    ByVal pExpression As SqliteFts3Expr Ptr, _
    ByVal zBuffer As ZString Ptr _
) As ZString Ptr

    If pExpression = 0 Then Return sqlite3_mprintf(StrPtr(!""))

    Select Case pExpression->eType
    Case FTSQUERY_PHRASE
        If pExpression->pPhrase = 0 Then Return 0

        zBuffer = sqlite3_mprintf( _
            StrPtr(!"%zPHRASE %d 0"), zBuffer, _
            pExpression->pPhrase->iColumn)
        If zBuffer = 0 Then Return 0

        For tokenIndex As SQLITE_C_INT = 0 To _
            pExpression->pPhrase->nToken - 1
            Dim pToken As SqliteFts3PhraseToken Ptr = _
                @pExpression->pPhrase->aToken(tokenIndex)
            Dim zPrefix As Const ZString Ptr = StrPtr(!"")
            If pToken->isPrefix <> 0 Then zPrefix = StrPtr(!"+")

            zBuffer = sqlite3_mprintf( _
                StrPtr(!"%z %.*s%s"), zBuffer, pToken->n, pToken->z, zPrefix)
            If zBuffer = 0 Then Return 0
        Next

        Return zBuffer

    Case FTSQUERY_NEAR
        zBuffer = sqlite3_mprintf( _
            StrPtr(!"%zNEAR/%d "), zBuffer, pExpression->nNear)
    Case FTSQUERY_NOT
        zBuffer = sqlite3_mprintf(StrPtr(!"%zNOT "), zBuffer)
    Case FTSQUERY_AND
        zBuffer = sqlite3_mprintf(StrPtr(!"%zAND "), zBuffer)
    Case FTSQUERY_OR
        zBuffer = sqlite3_mprintf(StrPtr(!"%zOR "), zBuffer)
    Case Else
        Return 0
    End Select

    If zBuffer = 0 Then Return 0
    zBuffer = sqlite3_mprintf(StrPtr(!"%z{"), zBuffer)
    If zBuffer = 0 Then Return 0

    zBuffer = fts3ExprTestToString(pExpression->pLeft, zBuffer)
    If zBuffer = 0 Then Return 0

    zBuffer = sqlite3_mprintf(StrPtr(!"%z} {"), zBuffer)
    If zBuffer = 0 Then Return 0

    zBuffer = fts3ExprTestToString(pExpression->pRight, zBuffer)
    If zBuffer = 0 Then Return 0

    Return sqlite3_mprintf(StrPtr(!"%z}"), zBuffer)
End Function

Private Sub fts3ExprTestCommon( _
    ByVal bRebalance As SQLITE_C_INT, _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal ppValue As Any Ptr Ptr _
)
    Dim pHash As Fts3Hash Ptr = CPtr(Fts3Hash Ptr, sqlite3_user_data(pContext))
    Dim pTokenizer As Fts3Tokenizer Ptr = 0
    Dim pExpression As SqliteFts3Expr Ptr = 0
    Dim azColumn As ZString Ptr Ptr = 0
    Dim zTokenizer As Const ZString Ptr
    Dim zExpression As Const ZString Ptr
    Dim zError As ZString Ptr = 0
    Dim zResult As ZString Ptr = 0
    Dim expressionBytes As SQLITE_C_INT
    Dim columnCount As SQLITE_C_INT
    Dim rc As SQLITE_C_INT

    If argumentCount < 3 Then
        sqlite3_result_error( _
            pContext, StrPtr(!"Usage: fts3_exprtest(tokenizer, expr, col1, ..."), -1)
        Return
    End If
    If pHash = 0 OrElse ppValue = 0 Then
        sqlite3_result_error_code(pContext, SQLITE_MISUSE)
        Return
    End If

    zTokenizer = CPtr(Const ZString Ptr, sqlite3_value_text(ppValue[0]))
    rc = sqlite3Fts3InitTokenizer(pHash, zTokenizer, @pTokenizer, @zError)
    If rc <> SQLITE_OK Then
        If rc = SQLITE_NOMEM Then
            sqlite3_result_error_nomem(pContext)
        ElseIf zError <> 0 Then
            sqlite3_result_error(pContext, zError, -1)
        Else
            sqlite3_result_error(pContext, StrPtr(!"unknown tokenizer"), -1)
        End If
        sqlite3_free(zError)
        Return
    End If

    zExpression = CPtr(Const ZString Ptr, _
        sqlite3_value_text(ppValue[1]))
    expressionBytes = sqlite3_value_bytes(ppValue[1])
    columnCount = argumentCount - 2

    If columnCount > 0 Then
        Dim columnBytes As ULongInt = _
            Cast(ULongInt, columnCount) * SizeOf(ZString Ptr)
        azColumn = CPtr(ZString Ptr Ptr, sqlite3_malloc64(columnBytes))
        If azColumn = 0 Then
            sqlite3_result_error_nomem(pContext)
            Goto fts3_expr_test_cleanup
        End If

        For columnIndex As SQLITE_C_INT = 0 To columnCount - 1
            azColumn[columnIndex] = CPtr(ZString Ptr, _
                sqlite3_value_text(ppValue[columnIndex + 2]))
        Next
    End If

    If bRebalance <> 0 Then
        rc = sqlite3Fts3ExprParse( _
            pTokenizer, 0, azColumn, 0, columnCount, columnCount, _
            zExpression, expressionBytes, @pExpression, @zError)
        sqlite3_free(zError)
        zError = 0
    Else
        rc = fts3ExprParseUnbalanced( _
            pTokenizer, 0, azColumn, 0, columnCount, columnCount, _
            zExpression, expressionBytes, @pExpression)
    End If

    If rc = SQLITE_OK AndAlso _
       fts3ExprCheckDepth(pExpression, SQLITE_FTS3_MAX_EXPR_DEPTH) <> 0 Then
        sqlite3_result_error( _
            pContext, StrPtr(!"Expression nested too deep"), -1)
    ElseIf rc <> SQLITE_OK AndAlso rc <> SQLITE_NOMEM Then
        sqlite3_result_error( _
            pContext, StrPtr(!"Error parsing expression"), -1)
    ElseIf rc = SQLITE_NOMEM Then
        sqlite3_result_error_nomem(pContext)
    Else
        zResult = fts3ExprTestToString(pExpression, 0)
        If zResult = 0 Then
            sqlite3_result_error_nomem(pContext)
        Else
            sqlite3_result_text( _
                pContext, zResult, -1, CPtr(Any Ptr, Cast(Integer, -1)))
            sqlite3_free(zResult)
        End If
    End If

fts3_expr_test_cleanup:
    sqlite3Fts3ExprFree(pExpression)
    If pTokenizer <> 0 Then
        Dim pModule As Fts3TokenizerModule Ptr = _
            CPtr(Fts3TokenizerModule Ptr, pTokenizer->pModule)
        If pModule <> 0 Then pModule->xDestroy(pTokenizer)
    End If
    sqlite3_free(azColumn)
End Sub

Private Sub fts3ExprTest CDecl Alias "fts3ExprTest" ( _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal ppValue As Any Ptr Ptr _
)
    fts3ExprTestCommon(0, pContext, argumentCount, ppValue)
End Sub

Private Sub fts3ExprTestRebalance CDecl Alias "fts3ExprTestRebalance" ( _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal ppValue As Any Ptr Ptr _
)
    fts3ExprTestCommon(1, pContext, argumentCount, ppValue)
End Sub

Function sqlite3Fts3ExprInitTestInterface CDecl Alias "sqlite3Fts3ExprInitTestInterface" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal pHash As Fts3Hash Ptr _
) As SQLITE_C_INT Export
    If pDatabase = 0 OrElse pHash = 0 Then Return SQLITE_MISUSE

    Dim rc As SQLITE_C_INT = sqlite3_create_function( _
        pDatabase, StrPtr(!"fts3_exprtest"), -1, SQLITE_UTF8, _
        CPtr(Any Ptr, pHash), CPtr(Any Ptr, ProcPtr(fts3ExprTest)), 0, 0)
    If rc = SQLITE_OK Then
        rc = sqlite3_create_function( _
            pDatabase, StrPtr(!"fts3_exprtest_rebalance"), -1, SQLITE_UTF8, _
            CPtr(Any Ptr, pHash), CPtr(Any Ptr, ProcPtr(fts3ExprTestRebalance)), 0, 0)
    End If
    Return rc
End Function
#endif

#endif

' c2fb skipped sqlite3Fts3ExprFree: FreeBASIC body already exists

/' end of sqlite3_bulk_fts3_expr_parse.bas '/
