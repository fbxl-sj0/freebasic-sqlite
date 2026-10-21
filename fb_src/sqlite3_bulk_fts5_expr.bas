/'
** 2014 May 31
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
*************************************************************************
'/
/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_bulk_fts5_expr.bas

    Purpose:

        Port FTS5 expression parsing, matching, and auxiliary query APIs.

    Responsibilities:

        - Parse FTS5 query expressions and build phrase and near-set trees.
        - Execute expression iterators and expose phrase, token, and position APIs.
        - Maintain expression position-list and token state.

    This file intentionally does NOT contain:

        - The Lemon query grammar or generated parser tables.
        - FTS5 virtual-table callbacks or tokenizer implementations.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_types.bi"
#include once "sqlite3_fts5_expr_types.bi"

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


Type c2fb_callback_28 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr)
Type c2fb_callback_73 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_8 As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_285 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Type c2fb_callback_342 As Function CDecl(ByVal arg0 As c2fb_uint64) As Any Ptr

Declare Sub sqlite3Fts5ParseError CDecl Alias "sqlite3Fts5ParseError" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Function fts5ExprIsspace CDecl Alias "fts5ExprIsspace" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function fts5ExprGetToken CDecl Alias "fts5ExprGetToken" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_Fts5Token Ptr) As c2fb_c_int
Declare Function fts5ParseAlloc CDecl Alias "fts5ParseAlloc" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Sub fts5ParseFree CDecl Alias "fts5ParseFree" (ByVal arg0 As Any Ptr)
Declare Function sqlite3Fts5ExprNew CDecl Alias "sqlite3Fts5ExprNew" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_Fts5Expr Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5ExprCountChar CDecl Alias "fts5ExprCountChar" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5ExprPattern CDecl Alias "sqlite3Fts5ExprPattern" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_Fts5Expr Ptr Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5ParseNodeFree CDecl Alias "sqlite3Fts5ParseNodeFree" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
Declare Sub sqlite3Fts5ExprFree CDecl Alias "sqlite3Fts5ExprFree" (ByVal arg0 As c2fb_Fts5Expr Ptr)
Declare Function sqlite3Fts5ExprAnd CDecl Alias "sqlite3Fts5ExprAnd" (ByVal arg0 As c2fb_Fts5Expr Ptr Ptr, ByVal arg1 As c2fb_Fts5Expr Ptr) As c2fb_c_int
Declare Function fts5ExprSynonymRowid CDecl Alias "fts5ExprSynonymRowid" (ByVal arg0 As c2fb_Fts5ExprTerm Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_int64
Declare Function fts5ExprSynonymList CDecl Alias "fts5ExprSynonymList" (ByVal arg0 As c2fb_Fts5ExprTerm Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_Fts5Buffer Ptr, ByVal arg3 As UByte Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ExprPhraseIsMatch CDecl Alias "fts5ExprPhraseIsMatch" (ByVal arg0 As c2fb_Fts5ExprNode Ptr, ByVal arg1 As c2fb_Fts5ExprPhrase Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5LookaheadReaderNext CDecl Alias "fts5LookaheadReaderNext" (ByVal arg0 As c2fb_Fts5LookaheadReader Ptr) As c2fb_c_int
Declare Function fts5LookaheadReaderInit CDecl Alias "fts5LookaheadReaderInit" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5LookaheadReader Ptr) As c2fb_c_int
Declare Function fts5ExprNearIsMatch CDecl Alias "fts5ExprNearIsMatch" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5ExprNearset Ptr) As c2fb_c_int
Declare Function fts5ExprAdvanceto CDecl Alias "fts5ExprAdvanceto" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ExprSynonymAdvanceto CDecl Alias "fts5ExprSynonymAdvanceto" (ByVal arg0 As c2fb_Fts5ExprTerm Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ExprNearTest CDecl Alias "fts5ExprNearTest" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Expr Ptr, ByVal arg2 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Function fts5ExprNearInitAll CDecl Alias "fts5ExprNearInitAll" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Function fts5RowidCmp CDecl Alias "fts5RowidCmp" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Sub fts5ExprSetEof CDecl Alias "fts5ExprSetEof" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
Declare Sub fts5ExprNodeZeroPoslist CDecl Alias "fts5ExprNodeZeroPoslist" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
Declare Function fts5NodeCompare CDecl Alias "fts5NodeCompare" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Function fts5ExprNodeTest_STRING CDecl Alias "fts5ExprNodeTest_STRING" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Function fts5ExprNodeTest_TERM CDecl Alias "fts5ExprNodeTest_TERM" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Sub fts5ExprNodeTest_OR CDecl Alias "fts5ExprNodeTest_OR" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr)
Declare Function fts5ExprNodeNext_OR CDecl Alias "fts5ExprNodeNext_OR" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Declare Function fts5ExprNodeTest_AND CDecl Alias "fts5ExprNodeTest_AND" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Function fts5ExprNodeNext_AND CDecl Alias "fts5ExprNodeNext_AND" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Declare Function fts5ExprNodeTest_NOT CDecl Alias "fts5ExprNodeTest_NOT" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Function fts5ExprNodeNext_NOT CDecl Alias "fts5ExprNodeNext_NOT" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Declare Function fts5ExprNodeTest CDecl Alias "fts5ExprNodeTest" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Function fts5ExprNodeFirst CDecl Alias "fts5ExprNodeFirst" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ExprFirst CDecl Alias "sqlite3Fts5ExprFirst" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5Index Ptr, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5ExprNext CDecl Alias "sqlite3Fts5ExprNext" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts5ExprEof CDecl Alias "sqlite3Fts5ExprEof" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ExprRowid CDecl Alias "sqlite3Fts5ExprRowid" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_int64
Declare Function fts5ParseStringFromToken CDecl Alias "fts5ParseStringFromToken" (ByVal arg0 As c2fb_Fts5Token Ptr, ByVal arg1 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub fts5ExprPhraseFree CDecl Alias "fts5ExprPhraseFree" (ByVal arg0 As c2fb_Fts5ExprPhrase Ptr)
Declare Function sqlite3Fts5ParseNearset CDecl Alias "sqlite3Fts5ParseNearset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNearset Ptr, ByVal arg2 As c2fb_Fts5ExprPhrase Ptr) As c2fb_Fts5ExprNearset Ptr
Declare Sub sqlite3Fts5ParsePhraseFree CDecl Alias "sqlite3Fts5ParsePhraseFree" (ByVal arg0 As c2fb_Fts5ExprPhrase Ptr)
Declare Sub sqlite3Fts5ParseNearsetFree CDecl Alias "sqlite3Fts5ParseNearsetFree" (ByVal arg0 As c2fb_Fts5ExprNearset Ptr)
Declare Sub sqlite3Fts5ParseFinished CDecl Alias "sqlite3Fts5ParseFinished" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr)
Declare Function parseGrowPhraseArray CDecl Alias "parseGrowPhraseArray" (ByVal arg0 As c2fb_Fts5Parse Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5ParseNear CDecl Alias "sqlite3Fts5ParseNear" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5Token Ptr)
Declare Sub sqlite3Fts5ParseSetDistance CDecl Alias "sqlite3Fts5ParseSetDistance" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNearset Ptr, ByVal arg2 As c2fb_Fts5Token Ptr)
Declare Function fts5ParseColset CDecl Alias "fts5ParseColset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr, ByVal arg2 As c2fb_c_int) As c2fb_Fts5Colset Ptr
Declare Function fts5CloneColset CDecl Alias "fts5CloneColset" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr) As c2fb_Fts5Colset Ptr
Declare Sub fts5MergeColset CDecl Alias "fts5MergeColset" (ByVal arg0 As c2fb_Fts5Colset Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr)
Declare Function sqlite3Fts5ParseColset CDecl Alias "sqlite3Fts5ParseColset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr, ByVal arg2 As c2fb_Fts5Token Ptr) As c2fb_Fts5Colset Ptr
Declare Sub fts5ParseSetColset CDecl Alias "fts5ParseSetColset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_Fts5Colset Ptr, ByVal arg3 As c2fb_Fts5Colset Ptr Ptr)
Declare Sub sqlite3Fts5ParseSetColset CDecl Alias "sqlite3Fts5ParseSetColset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_Fts5Colset Ptr)
Declare Sub fts5ExprAddChildren CDecl Alias "fts5ExprAddChildren" (ByVal arg0 As c2fb_Fts5ExprNode Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr)
Declare Function sqlite3Fts5ParseNode CDecl Alias "sqlite3Fts5ParseNode" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5ExprNode Ptr, ByVal arg3 As c2fb_Fts5ExprNode Ptr, ByVal arg4 As c2fb_Fts5ExprNearset Ptr) As c2fb_Fts5ExprNode Ptr
Declare Function sqlite3Fts5ParseImplicitAnd CDecl Alias "sqlite3Fts5ParseImplicitAnd" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_Fts5ExprNode Ptr) As c2fb_Fts5ExprNode Ptr
Declare Function sqlite3Fts5ExprInit CDecl Alias "sqlite3Fts5ExprInit" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ExprPhraseCount CDecl Alias "sqlite3Fts5ExprPhraseCount" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ExprPhraseSize CDecl Alias "sqlite3Fts5ExprPhraseSize" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5ExprPoslist CDecl Alias "sqlite3Fts5ExprPoslist" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ExprClearPoslists CDecl Alias "sqlite3Fts5ExprClearPoslists" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_Fts5PoslistPopulator Ptr
Declare Function fts5ExprColsetTest CDecl Alias "fts5ExprColsetTest" (ByVal arg0 As c2fb_Fts5Colset Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5QueryTerm CDecl Alias "fts5QueryTerm" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5ExprPopulatePoslistsCb CDecl Alias "fts5ExprPopulatePoslistsCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5ExprPopulatePoslists CDecl Alias "sqlite3Fts5ExprPopulatePoslists" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Expr Ptr, ByVal arg2 As c2fb_Fts5PoslistPopulator Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5ExprClearPoslists CDecl Alias "fts5ExprClearPoslists" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
Declare Function fts5ExprCheckPoslists CDecl Alias "fts5ExprCheckPoslists" (ByVal arg0 As c2fb_Fts5ExprNode Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Sub sqlite3Fts5ExprCheckPoslists CDecl Alias "sqlite3Fts5ExprCheckPoslists" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64)
Declare Function sqlite3Fts5ExprPhraseCollist CDecl Alias "sqlite3Fts5ExprPhraseCollist" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ExprQueryToken CDecl Alias "sqlite3Fts5ExprQueryToken" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ExprInstToken CDecl Alias "sqlite3Fts5ExprInstToken" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5ExprClearTokens CDecl Alias "sqlite3Fts5ExprClearTokens" (ByVal arg0 As c2fb_Fts5Expr Ptr)
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memmove CDecl Alias "memmove" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function c2fb_external_sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5Tokenize CDecl Alias "sqlite3Fts5Tokenize" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_73) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5Dequote CDecl Alias "sqlite3Fts5Dequote" (ByVal arg0 As ZString Ptr)
Declare Sub c2fb_external_sqlite3Fts5BufferFree CDecl Alias "sqlite3Fts5BufferFree" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
Declare Sub c2fb_external_sqlite3Fts5BufferZero CDecl Alias "sqlite3Fts5BufferZero" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
Declare Function c2fb_external_sqlite3Fts5PoslistReaderInit CDecl Alias "sqlite3Fts5PoslistReaderInit" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5PoslistReaderNext CDecl Alias "sqlite3Fts5PoslistReaderNext" (ByVal arg0 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5PoslistWriterAppend CDecl Alias "sqlite3Fts5PoslistWriterAppend" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5PoslistWriter Ptr, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5PoslistSafeAppend CDecl Alias "sqlite3Fts5PoslistSafeAppend" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64)
Declare Function c2fb_external_sqlite3Fts5PoslistNext64 CDecl Alias "sqlite3Fts5PoslistNext64" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5MallocZero CDecl Alias "sqlite3Fts5MallocZero" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function c2fb_external_sqlite3Fts5Strndup CDecl Alias "sqlite3Fts5Strndup" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As ZString Ptr
Declare Function c2fb_external_sqlite3Fts5IsBareword CDecl Alias "sqlite3Fts5IsBareword" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IndexQuery CDecl Alias "sqlite3Fts5IndexQuery" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5Colset Ptr, ByVal arg5 As c2fb_Fts5IndexIter Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IterNextFrom CDecl Alias "sqlite3Fts5IterNextFrom" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5IterNext CDecl Alias "sqlite3Fts5IterNext" (ByVal arg0 As c2fb_Fts5IndexIter Ptr) As c2fb_c_int
Declare Function sqlite3WhereMemcpy CDecl Alias "memcpy" (ByVal pDestination As Any Ptr, ByVal pSource As Const Any Ptr, ByVal byteCount As SQLITE_SIZE_T) As Any Ptr
Declare Sub sqlite3Fts5BufferSet CDecl Alias "sqlite3Fts5BufferSet" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
Declare Function sqlite3SystemStrlen CDecl Alias "strlen" (ByVal z As Const ZString Ptr) As SQLITE_SIZE_T
Declare Function c2fb_external_sqlite3Fts5ParserAlloc CDecl Alias "sqlite3Fts5ParserAlloc" (ByVal arg0 As c2fb_callback_342) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts5ParserFree CDecl Alias "sqlite3Fts5ParserFree" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_callback_8)
Declare Sub c2fb_external_sqlite3Fts5Parser CDecl Alias "sqlite3Fts5Parser" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5Token, ByVal arg3 As c2fb_Fts5Parse Ptr)
Declare Sub c2fb_external_sqlite3Fts5IterClose CDecl Alias "sqlite3Fts5IterClose" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
Declare Function c2fb_external_sqlite3Fts5IterToken CDecl Alias "sqlite3Fts5IterToken" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5IndexIterClearTokendata CDecl Alias "sqlite3Fts5IndexIterClearTokendata" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
Declare Function c2fb_external_sqlite3Fts5IndexIterWriteTokendata CDecl Alias "sqlite3Fts5IndexIterWriteTokendata" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Sub sqlite3Fts5ParseError CDecl Alias "sqlite3Fts5ParseError" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As Const ZString Ptr, ...)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 186
    Dim local0 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    Cva_Start(local0, arg1)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @(arg0->zErr))
        c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local0))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    End If
    Cva_End(local0)
End Sub
Private Function fts5ExprIsspace CDecl Alias "fts5ExprIsspace" (ByVal arg0 As Byte) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 197
    Return (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 32))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 9))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 10))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 13))))) <> 0)))))
End Function
Private Function fts5ExprGetToken CDecl Alias "fts5ExprGetToken" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_Fts5Token Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 204
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Const ZString Ptr
    Dim c2fb_temp_18 As Const ZString Ptr
    Dim c2fb_temp_19 As Const ZString Ptr
    Dim c2fb_temp_20 As Long Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As Const ZString Ptr
    Dim c2fb_temp_24 As Const ZString Ptr
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As Const ZString Ptr Ptr
    Dim c2fb_temp_31 As Const ZString Ptr

    local0 = (*arg1)
    ' C automatic storage declaration
    While fts5ExprIsspace((*CPtr(Const Byte Ptr, local0)))
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, @(arg2->p))
    c2fb_temp_2 = local0
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = CPtr(Long Ptr, @(arg2->n))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    Select Case (*CPtr(Const Byte Ptr, local0))
        Case Cast(c2fb_c_int, 40)
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 10ULL))
            local1 = c2fb_temp_5
        Case Cast(c2fb_c_int, 41)
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 11ULL))
            local1 = c2fb_temp_6
        Case Cast(c2fb_c_int, 123)
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local1 = c2fb_temp_7
        Case Cast(c2fb_c_int, 125)
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 8ULL))
            local1 = c2fb_temp_8
        Case Cast(c2fb_c_int, 58)
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 5ULL))
            local1 = c2fb_temp_9
        Case Cast(c2fb_c_int, 44)
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 13ULL))
            local1 = c2fb_temp_10
        Case Cast(c2fb_c_int, 43)
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 14ULL))
            local1 = c2fb_temp_11
        Case Cast(c2fb_c_int, 42)
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 15ULL))
            local1 = c2fb_temp_12
        Case Cast(c2fb_c_int, 45)
            c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 6ULL))
            local1 = c2fb_temp_13
        Case Cast(c2fb_c_int, 94)
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 12ULL))
            local1 = c2fb_temp_14
        Case Cast(c2fb_c_int, 0)
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_15
        Case Cast(c2fb_c_int, 34)
            ' C automatic storage declaration
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 9ULL))
            local1 = c2fb_temp_16
            c2fb_temp_17 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, 1ULL)])))
            local2 = c2fb_temp_17
            While Cast(c2fb_c_int, 1ULL)
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local2)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 34))))) Then
                    c2fb_temp_19 = local2
                    local2 = (c2fb_temp_19 + 1)
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local2)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 34))))) Then
                        Goto c2fb_flow_3
                    End If
                End If
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local2)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 0))))) Then
                    sqlite3Fts5ParseError(arg0, StrPtr(!"unterminated string"))
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
            c2fb_flow_4:
                c2fb_temp_18 = local2
                local2 = (c2fb_temp_18 + 1)
            Wend
            c2fb_flow_3:
            c2fb_temp_20 = CPtr(Long Ptr, @(arg2->n))
            c2fb_temp_21 = Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Const Byte Ptr, local2)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local0)))))
            (*c2fb_temp_20) = Cast(Long, c2fb_temp_21)
            c2fb_temp_21 = Cast(c2fb_c_int, (*c2fb_temp_20))
            Goto c2fb_flow_2
        Case Else
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3Fts5IsBareword(CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, &O0ULL))))) Then
                sqlite3Fts5ParseError(arg0, StrPtr(!"fts5: syntax error near \034%.1s\034"), local0)
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 9ULL))
            local1 = c2fb_temp_22
            c2fb_temp_23 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, 1ULL)])))
            local3 = c2fb_temp_23
            While c2fb_external_sqlite3Fts5IsBareword((*CPtr(Const Byte Ptr, local3)))
                ' empty C statement
            c2fb_flow_6:
                c2fb_temp_24 = local3
                local3 = (c2fb_temp_24 + 1)
            Wend
            c2fb_flow_5:
            c2fb_temp_25 = CPtr(Long Ptr, @(arg2->n))
            c2fb_temp_26 = Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Const Byte Ptr, local3)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local0)))))
            (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
            c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2->n = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, arg2->p), CPtr(Const Any Ptr, StrPtr(!"OR")), Cast(c2fb_c_int, 2ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local1 = c2fb_temp_27
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2->n = Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, arg2->p), CPtr(Const Any Ptr, StrPtr(!"NOT")), Cast(c2fb_c_int, 3ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
                local1 = c2fb_temp_28
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2->n = Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, arg2->p), CPtr(Const Any Ptr, StrPtr(!"AND")), Cast(c2fb_c_int, 3ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                local1 = c2fb_temp_29
            End If
            Goto c2fb_flow_2
    End Select
    c2fb_flow_2:
    c2fb_temp_30 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_31 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg2->p)[arg2->n])))
    (*c2fb_temp_30) = c2fb_temp_31
    Return local1
End Function
Private Function fts5ParseAlloc CDecl Alias "fts5ParseAlloc" (ByVal arg0 As c2fb_uint64) As Any Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 268
    Return CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, arg0)))
End Function
Private Sub fts5ParseFree CDecl Alias "fts5ParseFree" (ByVal arg0 As Any Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 269
    c2fb_external_sqlite3_free(arg0)
End Sub
' c2fb skipped sqlite3Fts5ExprNew: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 271: sqlite3Fts5ExprNew: no complete C or FreeBASIC record layout for member c2fb_Fts5Colset.nCol
Private Function fts5ExprCountChar CDecl Alias "fts5ExprCountChar" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 347
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < arg1))))
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local1]) And Cast(c2fb_c_int, &HC0ULL)))) <> Cast(c2fb_c_int, &H80ULL))))) Then
            c2fb_temp_2 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local0
End Function
Function sqlite3Fts5ExprPattern CDecl Alias "sqlite3Fts5ExprPattern" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_Fts5Expr Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 364
    Dim local0 As c2fb_int64
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local3(0 To 2) As Byte
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_1 As Byte Ptr
    Dim c2fb_temp_2 As Byte
    Dim c2fb_temp_3 As Byte Ptr
    Dim c2fb_temp_4 As Byte
    Dim c2fb_temp_5 As Byte Ptr
    Dim c2fb_temp_6 As Byte
    Dim c2fb_temp_7 As Byte Ptr
    Dim c2fb_temp_8 As Byte
    Dim c2fb_temp_9 As Byte Ptr
    Dim c2fb_temp_10 As Byte
    Dim c2fb_temp_11 As Byte Ptr
    Dim c2fb_temp_12 As Byte
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Byte Ptr
    Dim c2fb_temp_15 As Byte
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Byte Ptr
    Dim c2fb_temp_20 As Byte
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Byte Ptr
    Dim c2fb_temp_23 As Byte
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Byte Ptr
    Dim c2fb_temp_26 As Byte
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As Byte Ptr
    Dim c2fb_temp_29 As Byte
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As Byte Ptr
    Dim c2fb_temp_38 As Byte
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_Fts5Expr Ptr Ptr
    Dim c2fb_temp_41 As c2fb_Fts5Expr Ptr

    local0 = c2fb_crt_strlen(arg3)
    local1 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, (local0 * Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
    local2 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_0
    Else
        ' C automatic array storage
        local4 = Cast(c2fb_c_int, &O0ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        local6 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(Byte Ptr, @(local3(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_2 = Cast(Byte, Cast(c2fb_c_int, 95))
            (*c2fb_temp_1) = c2fb_temp_2
            c2fb_temp_3 = CPtr(Byte Ptr, @(local3(Cast(c2fb_c_int, 1ULL))))
            c2fb_temp_4 = Cast(Byte, Cast(c2fb_c_int, 37))
            (*c2fb_temp_3) = c2fb_temp_4
            c2fb_temp_5 = CPtr(Byte Ptr, @(local3(Cast(c2fb_c_int, 2ULL))))
            c2fb_temp_6 = Cast(Byte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_5) = c2fb_temp_6
        Else
            c2fb_temp_7 = CPtr(Byte Ptr, @(local3(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_8 = Cast(Byte, Cast(c2fb_c_int, 42))
            (*c2fb_temp_7) = c2fb_temp_8
            c2fb_temp_9 = CPtr(Byte Ptr, @(local3(Cast(c2fb_c_int, 1ULL))))
            c2fb_temp_10 = Cast(Byte, Cast(c2fb_c_int, 63))
            (*c2fb_temp_9) = c2fb_temp_10
            c2fb_temp_11 = CPtr(Byte Ptr, @(local3(Cast(c2fb_c_int, 2ULL))))
            c2fb_temp_12 = Cast(Byte, Cast(c2fb_c_int, 91))
            (*c2fb_temp_11) = c2fb_temp_12
        End If
        While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local5) <= local0))))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_int64, local5) = local0)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local5]) = Cast(c2fb_c_int, local3(Cast(c2fb_c_int, &O0ULL))))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local5]) = Cast(c2fb_c_int, local3(Cast(c2fb_c_int, 1ULL))))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local5]) = Cast(c2fb_c_int, local3(Cast(c2fb_c_int, 2ULL))))))) <> 0))))) Then
                If (-Cast(c2fb_c_int, ((fts5ExprCountChar(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg3)[local6]))), Cast(c2fb_c_int, (local5 - local6))) >= Cast(c2fb_c_int, 3ULL))))) Then
                    ' C automatic storage declaration
                    c2fb_temp_13 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                    c2fb_temp_14 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[c2fb_temp_13]))
                    c2fb_temp_15 = Cast(Byte, Cast(c2fb_c_int, 34))
                    (*c2fb_temp_14) = c2fb_temp_15
                    c2fb_temp_16 = Cast(c2fb_c_int, local6)
                    local7 = c2fb_temp_16
                    While (-Cast(c2fb_c_int, ((local7 < local5))))
                        c2fb_temp_18 = local4
                        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
                        c2fb_temp_19 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[c2fb_temp_18]))
                        c2fb_temp_20 = Cast(Byte, CPtr(Const Byte Ptr, arg3)[local7])
                        (*c2fb_temp_19) = c2fb_temp_20
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local7]) = Cast(c2fb_c_int, 34))))) Then
                            c2fb_temp_21 = local4
                            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
                            c2fb_temp_22 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[c2fb_temp_21]))
                            c2fb_temp_23 = Cast(Byte, Cast(c2fb_c_int, 34))
                            (*c2fb_temp_22) = c2fb_temp_23
                        End If
                    c2fb_flow_3:
                        c2fb_temp_17 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
                    Wend
                    c2fb_flow_2:
                    c2fb_temp_24 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_24 + 1)))
                    c2fb_temp_25 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[c2fb_temp_24]))
                    c2fb_temp_26 = Cast(Byte, Cast(c2fb_c_int, 34))
                    (*c2fb_temp_25) = c2fb_temp_26
                    c2fb_temp_27 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_27 + 1)))
                    c2fb_temp_28 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[c2fb_temp_27]))
                    c2fb_temp_29 = Cast(Byte, Cast(c2fb_c_int, 32))
                    (*c2fb_temp_28) = c2fb_temp_29
                End If
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local5]) = Cast(c2fb_c_int, local3(Cast(c2fb_c_int, 2ULL))))))) Then
                    c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 2ULL))))
                    local5 = c2fb_temp_30
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[Cast(c2fb_c_int, (local5 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 94))))) Then
                        c2fb_temp_31 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_31 + 1)))
                    End If
                    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_int64, local5) < local0)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local5]) <> Cast(c2fb_c_int, 93))))) <> 0)))))
                        c2fb_temp_32 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_32 + 1)))
                    c2fb_flow_5:
                    Wend
                    c2fb_flow_4:
                End If
                c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))))
                local6 = c2fb_temp_33
            End If
            c2fb_temp_34 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_34 + 1)))
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local4 > Cast(c2fb_c_int, &O0ULL))))) Then
            local8 = Cast(c2fb_c_int, &O0ULL)
            If (-Cast(c2fb_c_int, ((arg0->eDetail <> Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_35 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local8 = c2fb_temp_35
                If (-Cast(c2fb_c_int, ((arg0->eDetail = Cast(c2fb_c_int, 1ULL))))) Then
                    c2fb_temp_36 = Cast(c2fb_c_int, arg0->nCol)
                    arg2 = c2fb_temp_36
                End If
            End If
            c2fb_temp_37 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[local4]))
            c2fb_temp_38 = Cast(Byte, Cast(c2fb_c_int, 0))
            (*c2fb_temp_37) = c2fb_temp_38
            c2fb_temp_39 = Cast(c2fb_c_int, sqlite3Fts5ExprNew(arg0, local8, arg2, CPtr(Const ZString Ptr, local1), arg4, arg0->pzErrmsg))
            local2 = c2fb_temp_39
        Else
            c2fb_temp_40 = CPtr(c2fb_Fts5Expr Ptr Ptr, @((*arg4)))
            c2fb_temp_41 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_40) = c2fb_temp_41
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Return local2
End Function
Sub sqlite3Fts5ParseNodeFree CDecl Alias "sqlite3Fts5ParseNodeFree" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 435
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nChild))))
            sqlite3Fts5ParseNodeFree(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[local0])
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        sqlite3Fts5ParseNearsetFree(CPtr(c2fb_Fts5ExprNearset Ptr, arg0->pNear))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Sub sqlite3Fts5ExprFree CDecl Alias "sqlite3Fts5ExprFree" (ByVal arg0 As c2fb_Fts5Expr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 449
    If arg0 Then
        sqlite3Fts5ParseNodeFree(CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase)))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Function sqlite3Fts5ExprAnd CDecl Alias "sqlite3Fts5ExprAnd" (ByVal arg0 As c2fb_Fts5Expr Ptr Ptr, ByVal arg1 As c2fb_Fts5Expr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 457
    Dim local0 As c2fb_Fts5Parse
    Dim c2fb_temp_0 As Any Ptr
    Dim local1 As c2fb_Fts5Expr Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_Fts5ExprNode_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_3 As c2fb_Fts5ExprNode_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5ExprNode Ptr
    Dim local3 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_11 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_Fts5ExprPhrase_ Ptr Ptr Ptr
    Dim c2fb_temp_15 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5Expr Ptr Ptr
    Dim c2fb_temp_17 As c2fb_Fts5Expr Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Parse Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Parse))))
    If (-Cast(c2fb_c_int, ((((*arg0) <> 0) AndAlso (arg1 <> 0))))) Then
        local1 = (*arg0)
        local2 = Cast(c2fb_c_int, (local1->nPhrase + arg1->nPhrase))
        c2fb_temp_1 = CPtr(c2fb_Fts5ExprNode_ Ptr Ptr, @(local1->pRoot))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, sqlite3Fts5ParseNode(CPtr(c2fb_Fts5Parse Ptr, @(local0)), Cast(c2fb_c_int, 2ULL), CPtr(c2fb_Fts5ExprNode Ptr, local1->pRoot), CPtr(c2fb_Fts5ExprNode Ptr, arg1->pRoot), Cast(c2fb_c_int, &O0ULL))))
        (*c2fb_temp_1) = CPtr(c2fb_Fts5ExprNode_ Ptr, c2fb_temp_2)
        c2fb_temp_2 = CPtr(c2fb_Fts5ExprNode Ptr, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(c2fb_Fts5ExprNode_ Ptr Ptr, @(arg1->pRoot))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_3) = CPtr(c2fb_Fts5ExprNode_ Ptr, c2fb_temp_4)
        c2fb_temp_4 = CPtr(c2fb_Fts5ExprNode Ptr, (*c2fb_temp_3))
        If (-Cast(c2fb_c_int, ((local0.rc = Cast(c2fb_c_int, &O0ULL))))) Then
            local3 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local1->apExprPhrase)), Cast(c2fb_uint64, (Cast(c2fb_uint64, local2) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprPhrase Ptr))))))))
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_5 = CPtr(Long Ptr, @(local0.rc))
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
            Else
                ' C automatic storage declaration
                c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local3)[arg1->nPhrase]))), CPtr(Const Any Ptr, local3), Cast(c2fb_uint64, (Cast(c2fb_uint64, local1->nPhrase) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprPhrase Ptr)))))))
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local4 = c2fb_temp_8
                While (-Cast(c2fb_c_int, ((local4 < arg1->nPhrase))))
                    c2fb_temp_10 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local3)[local4]))
                    c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg1->apExprPhrase))[local4])
                    (*c2fb_temp_10) = c2fb_temp_11
                c2fb_flow_1:
                    c2fb_temp_9 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
                Wend
                c2fb_flow_0:
                c2fb_temp_12 = CPtr(Long Ptr, @(local1->nPhrase))
                c2fb_temp_13 = Cast(c2fb_c_int, local2)
                (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
                c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
                c2fb_temp_14 = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr Ptr, @(local1->apExprPhrase))
                c2fb_temp_15 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr Ptr, local3)
                (*c2fb_temp_14) = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr, c2fb_temp_15)
                c2fb_temp_15 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (*c2fb_temp_14))
            End If
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg1->apExprPhrase)))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg1))
    Else
        If arg1 Then
            c2fb_temp_16 = CPtr(c2fb_Fts5Expr Ptr Ptr, @((*arg0)))
            c2fb_temp_17 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, arg1)
            (*c2fb_temp_16) = c2fb_temp_17
        End If
    End If
    Return local0.rc
End Function
Private Function fts5ExprSynonymRowid CDecl Alias "fts5ExprSynonymRowid" (ByVal arg0 As c2fb_Fts5ExprTerm Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_int64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 497
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_0 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_1 As c2fb_Fts5ExprTerm Ptr
    Dim local3 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, arg0)
    local2 = c2fb_temp_0
    While local2
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = Cast(c2fb_c_int, ((CPtr(c2fb_Fts5IndexIter Ptr, local2->pIter))->bEof)))))) Then
            local3 = CPtr(c2fb_Fts5IndexIter Ptr, local2->pIter)->iRowid
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((arg1 <> ((-Cast(c2fb_c_int, ((local3 < local0)))))))))) <> 0))))) Then
                c2fb_temp_2 = Cast(c2fb_int64, local3)
                local0 = c2fb_temp_2
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local1 = c2fb_temp_3
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local2->pSynonym))
        local2 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_4) = c2fb_temp_5
    End If
    Return local0
End Function
Private Function fts5ExprSynonymList CDecl Alias "fts5ExprSynonymList" (ByVal arg0 As c2fb_Fts5ExprTerm Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_Fts5Buffer Ptr, ByVal arg3 As UByte Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 522
    Dim local0(0 To 3) As c2fb_Fts5PoslistReader
    Dim local1 As c2fb_Fts5PoslistReader Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_0 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_1 As c2fb_Fts5ExprTerm Ptr
    Dim local6 As c2fb_Fts5IndexIter Ptr
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_Fts5PoslistReader Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_Fts5PoslistReader Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As UByte Ptr Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local9 As c2fb_Fts5PoslistWriter
    Dim local10 As c2fb_int64
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_int64
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_int64
    Dim c2fb_temp_16 As UByte Ptr Ptr
    Dim c2fb_temp_17 As UByte Ptr
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int

    ' C automatic array storage
    local1 = CPtr(c2fb_Fts5PoslistReader Ptr, (@local0(0)))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, 4ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, arg0)
    local5 = c2fb_temp_0
    While local5
        local6 = CPtr(c2fb_Fts5IndexIter Ptr, local5->pIter)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((local6)->bEof)) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6->iRowid = arg1)))) <> 0))))) Then
            If (-Cast(c2fb_c_int, ((local6->nData = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_1
            End If
            If (-Cast(c2fb_c_int, ((local2 = local3)))) Then
                local7 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistReader))) * Cast(c2fb_uint64, local3))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))))
                local8 = CPtr(c2fb_Fts5PoslistReader Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local7)))
                If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    local4 = c2fb_temp_2
                    Goto c2fb_label_0
                End If
                c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local8), CPtr(Const Any Ptr, local1), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistReader))) * Cast(c2fb_uint64, local2)))))
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 2ULL))))
                local3 = c2fb_temp_4
                If (-Cast(c2fb_c_int, ((local1 <> CPtr(c2fb_Fts5PoslistReader Ptr, (@local0(0))))))) Then
                    c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
                End If
                c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5PoslistReader Ptr, local8)
                local1 = c2fb_temp_5
            End If
            c2fb_external_sqlite3Fts5PoslistReaderInit(local6->pData, local6->nData, CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local2])))
            ' C unused-parameter annotation
            c2fb_temp_6 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local5->pSynonym))
        local5 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_temp_7 = CPtr(UByte Ptr Ptr, @((*arg3)))
        c2fb_temp_8 = CPtr(UByte Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, local1)[Cast(c2fb_c_int, &O0ULL)].a)
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_10 = Cast(c2fb_c_int, CPtr(c2fb_Fts5PoslistReader Ptr, local1)[Cast(c2fb_c_int, &O0ULL)].n)
        (*c2fb_temp_9) = c2fb_temp_10
    Else
        local9 = Type<c2fb_Fts5PoslistWriter>( Cast(c2fb_c_int, &O0ULL) )
        local10 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
        c2fb_external_sqlite3Fts5BufferZero(arg2)
        While Cast(c2fb_c_int, 1ULL)
            ' C automatic storage declaration
            local12 = (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL)))))))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local11 = c2fb_temp_11
            While (-Cast(c2fb_c_int, ((local11 < local2))))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local11].bEof) = Cast(c2fb_c_int, &O0ULL))))) Then
                    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local11].iPos = local10)))) Then
                        If c2fb_external_sqlite3Fts5PoslistReaderNext(CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local11]))) Then
                            Goto c2fb_flow_5
                        End If
                    End If
                    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local11].iPos < local12)))) Then
                        c2fb_temp_13 = Cast(c2fb_int64, CPtr(c2fb_Fts5PoslistReader Ptr, local1)[local11].iPos)
                        local12 = c2fb_temp_13
                    End If
                End If
            c2fb_flow_5:
                c2fb_temp_12 = local11
                local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local12 = (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL))))))))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                Goto c2fb_flow_2
            End If
            c2fb_temp_14 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5PoslistWriterAppend(arg2, CPtr(c2fb_Fts5PoslistWriter Ptr, @(local9)), local12))
            local4 = c2fb_temp_14
            c2fb_temp_15 = Cast(c2fb_int64, local12)
            local10 = c2fb_temp_15
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_16 = CPtr(UByte Ptr Ptr, @((*arg3)))
            c2fb_temp_17 = arg2->p
            (*c2fb_temp_16) = c2fb_temp_17
            c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg4)))
            c2fb_temp_19 = Cast(c2fb_c_int, arg2->n)
            (*c2fb_temp_18) = c2fb_temp_19
        End If
    End If
    c2fb_label_0:
    If (-Cast(c2fb_c_int, ((local1 <> CPtr(c2fb_Fts5PoslistReader Ptr, (@local0(0))))))) Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Return local4
End Function
Private Function fts5ExprPhraseIsMatch CDecl Alias "fts5ExprPhraseIsMatch" (ByVal arg0 As c2fb_Fts5ExprNode Ptr, ByVal arg1 As c2fb_Fts5ExprPhrase Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 605
    Dim local0 As c2fb_Fts5PoslistWriter
    Dim local1(0 To 3) As c2fb_Fts5PoslistReader
    Dim local2 As c2fb_Fts5PoslistReader Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_Fts5PoslistReader Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local7 As c2fb_Fts5ExprTerm Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As UByte Ptr
    Dim local11 As c2fb_Fts5Buffer
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_u8 Ptr
    Dim c2fb_temp_9 As UByte
    Dim local12 As c2fb_c_int
    Dim local13 As c2fb_int64
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local14 As c2fb_Fts5PoslistReader Ptr
    Dim local15 As c2fb_int64
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int

    local0 = Type<c2fb_Fts5PoslistWriter>( Cast(c2fb_c_int, &O0ULL) )
    ' C automatic array storage
    local2 = CPtr(c2fb_Fts5PoslistReader Ptr, (@local1(0)))
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)].bFirst
    c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(arg1->poslist)))
    If (-Cast(c2fb_c_int, ((arg1->nTerm > (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_Fts5PoslistReader)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistReader)))))))))))) Then
        local6 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistReader))) * Cast(c2fb_uint64, arg1->nTerm)))
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5PoslistReader Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local6))))
        local2 = c2fb_temp_0
        If (-Cast(c2fb_c_int, (local2 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistReader))) * Cast(c2fb_uint64, arg1->nTerm)))))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local3 < arg1->nTerm))))
        local7 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(arg1)))[local3]))
        local8 = Cast(c2fb_c_int, &O0ULL)
        local9 = Cast(c2fb_c_int, &O0ULL)
        local10 = Cast(c2fb_c_int, &O0ULL)
        If CPtr(c2fb_Fts5ExprTerm Ptr, local7->pSynonym) Then
            local11 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
            c2fb_temp_4 = Cast(c2fb_c_int, fts5ExprSynonymList(local7, arg0->iRowid, CPtr(c2fb_Fts5Buffer Ptr, @(local11)), CPtr(UByte Ptr Ptr, @(local10)), CPtr(c2fb_c_int Ptr, @(local8))))
            local4 = c2fb_temp_4
            If local4 Then
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local10))
                Goto c2fb_label_0
            End If
            If (-Cast(c2fb_c_int, ((local10 = local11.p)))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local9 = c2fb_temp_5
            End If
        Else
            c2fb_temp_6 = CPtr(UByte Ptr, CPtr(c2fb_Fts5IndexIter Ptr, local7->pIter)->pData)
            local10 = c2fb_temp_6
            c2fb_temp_7 = Cast(c2fb_c_int, CPtr(c2fb_Fts5IndexIter Ptr, local7->pIter)->nData)
            local8 = c2fb_temp_7
        End If
        c2fb_external_sqlite3Fts5PoslistReaderInit(CPtr(Const UByte Ptr, local10), local8, CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, local2)[local3])))
        c2fb_temp_8 = CPtr(c2fb_u8 Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, local2)[local3].bFlag))
        c2fb_temp_9 = Cast(UByte, Cast(UByte, local9))
        (*c2fb_temp_8) = Cast(c2fb_u8, c2fb_temp_9)
        c2fb_temp_9 = Cast(UByte, (*c2fb_temp_8))
        If CPtr(c2fb_Fts5PoslistReader Ptr, local2)[local3].bEof Then
            Goto c2fb_label_0
        End If
    c2fb_flow_1:
        c2fb_temp_3 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    While Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        local13 = CPtr(c2fb_Fts5PoslistReader Ptr, local2)[Cast(c2fb_c_int, &O0ULL)].iPos
        Do
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local12 = c2fb_temp_10
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_11
            While (-Cast(c2fb_c_int, ((local3 < arg1->nTerm))))
                local14 = CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, local2)[local3]))
                local15 = Cast(c2fb_int64, (local13 + Cast(c2fb_int64, local3)))
                If (-Cast(c2fb_c_int, ((local14->iPos <> local15)))) Then
                    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local12 = c2fb_temp_13
                    While (-Cast(c2fb_c_int, ((local14->iPos < local15))))
                        If c2fb_external_sqlite3Fts5PoslistReaderNext(local14) Then
                            Goto c2fb_label_0
                        End If
                    c2fb_flow_9:
                    Wend
                    c2fb_flow_8:
                    If (-Cast(c2fb_c_int, ((local14->iPos > local15)))) Then
                        c2fb_temp_14 = Cast(c2fb_int64, Cast(c2fb_int64, (local14->iPos - Cast(c2fb_int64, local3))))
                        local13 = c2fb_temp_14
                    End If
                End If
            c2fb_flow_7:
                c2fb_temp_12 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
            Wend
            c2fb_flow_6:
        c2fb_flow_5:
        Loop While (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, &O0ULL)))))
        c2fb_flow_4:
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_int64, (local13 And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL)))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_15 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5PoslistWriterAppend(CPtr(c2fb_Fts5Buffer Ptr, @(arg1->poslist)), CPtr(c2fb_Fts5PoslistWriter Ptr, @(local0)), local13))
            local4 = c2fb_temp_15
            If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_label_0
            End If
        End If
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_16
        While (-Cast(c2fb_c_int, ((local3 < arg1->nTerm))))
            If c2fb_external_sqlite3Fts5PoslistReaderNext(CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, local2)[local3]))) Then
                Goto c2fb_label_0
            End If
        c2fb_flow_11:
            c2fb_temp_17 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
        Wend
        c2fb_flow_10:
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    c2fb_label_0:
    c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_19 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((arg1->poslist.n > Cast(c2fb_c_int, &O0ULL)))))))
    (*c2fb_temp_18) = c2fb_temp_19
    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_20
    While (-Cast(c2fb_c_int, ((local3 < arg1->nTerm))))
        If CPtr(c2fb_Fts5PoslistReader Ptr, local2)[local3].bFlag Then
            c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(UByte Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, local2)[local3].a)))
        End If
    c2fb_flow_13:
        c2fb_temp_21 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
    Wend
    c2fb_flow_12:
    If (-Cast(c2fb_c_int, ((local2 <> CPtr(c2fb_Fts5PoslistReader Ptr, (@local1(0))))))) Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    End If
    Return local4
End Function
Private Function fts5LookaheadReaderNext CDecl Alias "fts5LookaheadReaderNext" (ByVal arg0 As c2fb_Fts5LookaheadReader Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 700
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_i64 Ptr
    Dim c2fb_temp_3 As c2fb_int64

    c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->iPos))
    c2fb_temp_1 = Cast(c2fb_int64, arg0->iLookahead)
    (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    If c2fb_external_sqlite3Fts5PoslistNext64(arg0->a, arg0->n, CPtr(c2fb_c_int Ptr, @(arg0->i)), CPtr(c2fb_int64 Ptr, @(arg0->iLookahead))) Then
        c2fb_temp_2 = CPtr(c2fb_i64 Ptr, @(arg0->iLookahead))
        c2fb_temp_3 = Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))) Shl Cast(c2fb_c_int, 62ULL)))))
        (*c2fb_temp_2) = Cast(c2fb_i64, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_int64, (*c2fb_temp_2))
    End If
    Return ((-Cast(c2fb_c_int, ((arg0->iPos = (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))) Shl Cast(c2fb_c_int, 62ULL)))))))))
End Function
Private Function fts5LookaheadReaderInit CDecl Alias "fts5LookaheadReaderInit" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5LookaheadReader Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 708
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_2 As Const UByte Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5LookaheadReader))))
    c2fb_temp_1 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg2->a))
    c2fb_temp_2 = arg0
    (*c2fb_temp_1) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(Const UByte Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(Long Ptr, @(arg2->n))
    c2fb_temp_4 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    fts5LookaheadReaderNext(arg2)
    Return fts5LookaheadReaderNext(arg2)
End Function
Private Function fts5ExprNearIsMatch CDecl Alias "fts5ExprNearIsMatch" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5ExprNearset Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 743
    Dim local0(0 To 3) As c2fb_Fts5NearTrimmer
    Dim local1 As c2fb_Fts5NearTrimmer Ptr
    Dim local2 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_Fts5NearTrimmer Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local7 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_Fts5Buffer_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Buffer Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_int64
    Dim local10 As c2fb_int64
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local11 As c2fb_Fts5LookaheadReader Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_int64
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local12 As c2fb_int64
    Dim local13 As c2fb_Fts5PoslistWriter Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_int64
    Dim c2fb_temp_24 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int Ptr
    Dim c2fb_temp_26 As c2fb_c_int

    ' C automatic array storage
    local1 = CPtr(c2fb_Fts5NearTrimmer Ptr, (@local0(0)))
    local2 = (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg1))
    ' C automatic storage declaration
    local4 = (*arg0)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg1->nPhrase > (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_Fts5NearTrimmer)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5NearTrimmer)))))))))))) Then
        local6 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5NearTrimmer))) * Cast(c2fb_uint64, arg1->nPhrase)))
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5NearTrimmer Ptr, CPtr(c2fb_Fts5NearTrimmer Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local4)), local6))))
        local1 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5NearTrimmer Ptr, (@local0(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_Fts5NearTrimmer)))))
    End If
    If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg0)))
        c2fb_temp_3 = Cast(c2fb_c_int, local4)
        (*c2fb_temp_2) = c2fb_temp_3
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local3 < arg1->nPhrase))))
        local7 = CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local2)[local3]->poslist))
        fts5LookaheadReaderInit(CPtr(Const UByte Ptr, local7->p), local7->n, CPtr(c2fb_Fts5LookaheadReader Ptr, @(CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].reader)))
        c2fb_temp_6 = CPtr(Long Ptr, @(local7->n))
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        c2fb_temp_8 = CPtr(c2fb_Fts5Buffer_ Ptr Ptr, @(CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].pOut))
        c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, local7)
        (*c2fb_temp_8) = CPtr(c2fb_Fts5Buffer_ Ptr, c2fb_temp_9)
        c2fb_temp_9 = CPtr(c2fb_Fts5Buffer Ptr, (*c2fb_temp_8))
    c2fb_flow_1:
        c2fb_temp_5 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    While Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_10 = Cast(c2fb_int64, CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[Cast(c2fb_c_int, &O0ULL)].reader.iPos)
        local10 = c2fb_temp_10
        Do
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local5 = c2fb_temp_11
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_12
            While (-Cast(c2fb_c_int, ((local3 < arg1->nPhrase))))
                local11 = CPtr(c2fb_Fts5LookaheadReader Ptr, @(CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].reader))
                c2fb_temp_14 = Cast(c2fb_int64, ((local10 - CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg1)))[local3]->nTerm) - arg1->nNear))
                local9 = c2fb_temp_14
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local11->iPos < local9)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local11->iPos > local10)))) <> 0))))) Then
                    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local5 = c2fb_temp_15
                    While (-Cast(c2fb_c_int, ((local11->iPos < local9))))
                        If fts5LookaheadReaderNext(local11) Then
                            Goto c2fb_label_0
                        End If
                    c2fb_flow_9:
                    Wend
                    c2fb_flow_8:
                    If (-Cast(c2fb_c_int, ((local11->iPos > local10)))) Then
                        c2fb_temp_16 = Cast(c2fb_int64, local11->iPos)
                        local10 = c2fb_temp_16
                    End If
                End If
            c2fb_flow_7:
                c2fb_temp_13 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
            Wend
            c2fb_flow_6:
        c2fb_flow_5:
        Loop While (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL)))))
        c2fb_flow_4:
        c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_17
        While (-Cast(c2fb_c_int, ((local3 < arg1->nPhrase))))
            local12 = CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].reader.iPos
            local13 = CPtr(c2fb_Fts5PoslistWriter Ptr, @(CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].writer))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].pOut)->n = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local12 <> local13->iPrev)))) <> 0))))) Then
                c2fb_external_sqlite3Fts5PoslistSafeAppend(CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].pOut), CPtr(c2fb_int64 Ptr, @(local13->iPrev)), local12)
            End If
        c2fb_flow_11:
            c2fb_temp_18 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
        Wend
        c2fb_flow_10:
        c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local8 = c2fb_temp_19
        c2fb_temp_20 = Cast(c2fb_int64, CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[Cast(c2fb_c_int, &O0ULL)].reader.iLookahead)
        local9 = c2fb_temp_20
        c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_21
        While (-Cast(c2fb_c_int, ((local3 < arg1->nPhrase))))
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].reader.iLookahead < local9)))) Then
                c2fb_temp_23 = Cast(c2fb_int64, CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local3].reader.iLookahead)
                local9 = c2fb_temp_23
                c2fb_temp_24 = Cast(c2fb_c_int, local3)
                local8 = c2fb_temp_24
            End If
        c2fb_flow_13:
            c2fb_temp_22 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_22 + 1)))
        Wend
        c2fb_flow_12:
        If fts5LookaheadReaderNext(CPtr(c2fb_Fts5LookaheadReader Ptr, @(CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[local8].reader))) Then
            Goto c2fb_label_0
        End If
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    c2fb_label_0:
    local14 = (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5NearTrimmer Ptr, local1)[Cast(c2fb_c_int, &O0ULL)].pOut)->n > Cast(c2fb_c_int, &O0ULL)))))
    c2fb_temp_25 = CPtr(c2fb_c_int Ptr, @((*arg0)))
    c2fb_temp_26 = Cast(c2fb_c_int, local4)
    (*c2fb_temp_25) = c2fb_temp_26
    If (-Cast(c2fb_c_int, ((local1 <> CPtr(c2fb_Fts5NearTrimmer Ptr, (@local0(0))))))) Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Return local14
End Function
Private Function fts5ExprAdvanceto CDecl Alias "fts5ExprAdvanceto" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 842
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64

    local0 = (*arg2)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_int64, arg0->iRowid)
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 > local1)))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < local1)))) <> 0)))))) <> 0))))) Then
        local2 = c2fb_external_sqlite3Fts5IterNextFrom(arg0, local0)
        If (-Cast(c2fb_c_int, (((local2 <> 0) OrElse (((arg0)->bEof) <> 0))))) Then
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_2 = Cast(c2fb_c_int, local2)
            (*c2fb_temp_1) = c2fb_temp_2
            c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg4)))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_3) = c2fb_temp_4
            Return Cast(c2fb_c_int, 1ULL)
        End If
        c2fb_temp_5 = Cast(c2fb_int64, arg0->iRowid)
        local1 = c2fb_temp_5
        ' C unused-parameter annotation
    End If
    c2fb_temp_6 = CPtr(c2fb_int64 Ptr, @((*arg2)))
    c2fb_temp_7 = Cast(c2fb_int64, local1)
    (*c2fb_temp_6) = c2fb_temp_7
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5ExprSynonymAdvanceto CDecl Alias "fts5ExprSynonymAdvanceto" (ByVal arg0 As c2fb_Fts5ExprTerm Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64 Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 868
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_Fts5ExprTerm Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_1 As c2fb_Fts5ExprTerm Ptr
    Dim local4 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (*arg2)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, arg0)
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local2 <> 0)))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((CPtr(c2fb_Fts5IndexIter Ptr, local2->pIter))->bEof)) = Cast(c2fb_c_int, &O0ULL))))) Then
            local4 = CPtr(c2fb_Fts5IndexIter Ptr, local2->pIter)->iRowid
            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 > local4)))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < local4)))) <> 0)))))) <> 0))))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNextFrom(CPtr(c2fb_Fts5IndexIter Ptr, local2->pIter), local1))
                local0 = c2fb_temp_2
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local2->pSynonym))
        local2 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_4 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_5
    Else
        c2fb_temp_6 = CPtr(c2fb_int64 Ptr, @((*arg2)))
        c2fb_temp_7 = Cast(c2fb_int64, fts5ExprSynonymRowid(arg0, arg1, CPtr(c2fb_c_int Ptr, @(local3))))
        (*c2fb_temp_6) = c2fb_temp_7
    End If
    Return local3
End Function
' c2fb skipped fts5ExprNearTest: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 898: fts5ExprNearTest: expression parser stopped at byte 55 in (pPhrase->nTerm>1 || pPhrase->aTerm[0].pSynonym        || pNear->pColset || pPhrase->aTerm[0].bFirst): || pNear->pColset || pPhrase->aTerm[0].bFirst
Private Function fts5ExprNearInitAll CDecl Alias "fts5ExprNearInitAll" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 957
    Dim local0 As c2fb_Fts5ExprNearset Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As c2fb_Fts5ExprTerm Ptr
    Dim local5 As c2fb_Fts5ExprTerm Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_7 As c2fb_Fts5ExprTerm Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_Fts5IndexIter_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5IndexIter Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprNearset Ptr, arg1->pNear)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < local0->nPhrase))))
        local2 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[local1]
        If (-Cast(c2fb_c_int, ((local2->nTerm = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(Long Ptr, @(arg1->bEof))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            Return Cast(c2fb_c_int, &O0ULL)
        Else
            ' C automatic storage declaration
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_4
            While (-Cast(c2fb_c_int, ((local3 < local2->nTerm))))
                local4 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local2)))[local3]))
                ' C automatic storage declaration
                local6 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, local4)
                local5 = c2fb_temp_6
                While local5
                    ' C automatic storage declaration
                    If CPtr(c2fb_Fts5IndexIter Ptr, local5->pIter) Then
                        c2fb_external_sqlite3Fts5IterClose(CPtr(c2fb_Fts5IndexIter Ptr, local5->pIter))
                        c2fb_temp_8 = CPtr(c2fb_Fts5IndexIter_ Ptr Ptr, @(local5->pIter))
                        c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                        (*c2fb_temp_8) = CPtr(c2fb_Fts5IndexIter_ Ptr, c2fb_temp_9)
                        c2fb_temp_9 = CPtr(c2fb_Fts5IndexIter Ptr, (*c2fb_temp_8))
                    End If
                    c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexQuery(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), CPtr(Const ZString Ptr, local5->pTerm), local5->nQueryTerm, Cast(c2fb_c_int, ((IIf(local4->bPrefix, Cast(c2fb_c_int, &H0001ULL), Cast(c2fb_c_int, &O0ULL))) Or (IIf(arg0->bDesc, Cast(c2fb_c_int, &H0002ULL), Cast(c2fb_c_int, &O0ULL))))), CPtr(c2fb_Fts5Colset Ptr, local0->pColset), CPtr(c2fb_Fts5IndexIter Ptr Ptr, @(local5->pIter))))
                    local7 = c2fb_temp_10
                    ' C unused-parameter annotation
                    If (-Cast(c2fb_c_int, ((local7 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        Return local7
                    End If
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = Cast(c2fb_c_int, ((CPtr(c2fb_Fts5IndexIter Ptr, local5->pIter))->bEof)))))) Then
                        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local6 = c2fb_temp_11
                    End If
                c2fb_flow_5:
                    c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local5->pSynonym))
                    local5 = c2fb_temp_7
                Wend
                c2fb_flow_4:
                If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_12 = CPtr(Long Ptr, @(arg1->bEof))
                    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
                    c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
            c2fb_flow_3:
                c2fb_temp_5 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
            Wend
            c2fb_flow_2:
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_14 = CPtr(Long Ptr, @(arg1->bEof))
    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
    c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5RowidCmp CDecl Alias "fts5RowidCmp" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1019
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->bDesc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg1 < arg2)))) Then
            Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
        End If
        Return ((-Cast(c2fb_c_int, ((arg1 > arg2)))))
    Else
        If (-Cast(c2fb_c_int, ((arg1 > arg2)))) Then
            Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
        End If
        Return ((-Cast(c2fb_c_int, ((arg1 < arg2)))))
    End If
End Function
Private Sub fts5ExprSetEof CDecl Alias "fts5ExprSetEof" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1034
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->bEof))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->bNomatch))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local0 < arg0->nChild))))
        fts5ExprSetEof(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[local0])
    c2fb_flow_1:
        c2fb_temp_5 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
End Sub
Private Sub fts5ExprNodeZeroPoslist CDecl Alias "fts5ExprNodeZeroPoslist" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1043
    Dim local0 As c2fb_Fts5ExprNearset Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eType = Cast(c2fb_c_int, 9ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->eType = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
        local0 = CPtr(c2fb_Fts5ExprNearset Ptr, arg0->pNear)
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local1 < local0->nPhrase))))
            local2 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[local1]
            c2fb_temp_2 = CPtr(Long Ptr, @(local2->poslist.n))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        c2fb_flow_1:
            c2fb_temp_1 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
    Else
        ' C automatic storage declaration
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((local3 < arg0->nChild))))
            fts5ExprNodeZeroPoslist(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[local3])
        c2fb_flow_3:
            c2fb_temp_5 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_2:
    End If
End Sub
Private Function fts5NodeCompare CDecl Alias "fts5NodeCompare" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1073
    If arg2->bEof Then
        Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    End If
    If arg1->bEof Then
        Return Cast(c2fb_c_int, (+Cast(c2fb_c_int, 1ULL)))
    End If
    Return fts5RowidCmp(arg0, arg1->iRowid, arg2->iRowid)
End Function
Private Function fts5ExprNodeTest_STRING CDecl Alias "fts5ExprNodeTest_STRING" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1094
    Dim local0 As c2fb_Fts5ExprNearset Ptr
    Dim local1 As c2fb_Fts5ExprPhrase Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local8 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local9 As c2fb_Fts5ExprTerm Ptr
    Dim local10 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local11 As c2fb_Fts5IndexIter Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_i64 Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprNearset Ptr, arg1->pNear)
    local1 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)]
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local7 = arg0->bDesc
    ' C unused-parameter annotation
    If CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local1)))[Cast(c2fb_c_int, &O0ULL)].pSynonym Then
        c2fb_temp_0 = Cast(c2fb_int64, fts5ExprSynonymRowid(CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local1)))[Cast(c2fb_c_int, &O0ULL)])), local7, Cast(c2fb_c_int, &O0ULL)))
        local3 = c2fb_temp_0
    Else
        c2fb_temp_1 = Cast(c2fb_int64, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local1)))[Cast(c2fb_c_int, &O0ULL)].pIter->iRowid)
        local3 = c2fb_temp_1
    End If
    Do
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local6 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local4 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local4 < local0->nPhrase))))
            local8 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[local4]
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local5 = c2fb_temp_5
            While (-Cast(c2fb_c_int, ((local5 < local8->nTerm))))
                local9 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local8)))[local5]))
                If CPtr(c2fb_Fts5ExprTerm Ptr, local9->pSynonym) Then
                    local10 = fts5ExprSynonymRowid(local9, local7, Cast(c2fb_c_int, &O0ULL))
                    If (-Cast(c2fb_c_int, ((local10 = local3)))) Then
                        Goto c2fb_flow_5
                    End If
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local6 = c2fb_temp_7
                    If fts5ExprSynonymAdvanceto(local9, local7, CPtr(c2fb_int64 Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local2))) Then
                        c2fb_temp_8 = CPtr(Long Ptr, @(arg1->bNomatch))
                        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
                        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
                        c2fb_temp_10 = CPtr(Long Ptr, @(arg1->bEof))
                        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
                        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                        Return local2
                    End If
                Else
                    local11 = CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local8)))[local5].pIter
                    If (-Cast(c2fb_c_int, ((local11->iRowid = local3)))) Then
                        Goto c2fb_flow_5
                    End If
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local6 = c2fb_temp_12
                    If fts5ExprAdvanceto(local11, local7, CPtr(c2fb_int64 Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(arg1->bEof))) Then
                        Return local2
                    End If
                End If
            c2fb_flow_5:
                c2fb_temp_6 = local5
                local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
            Wend
            c2fb_flow_4:
        c2fb_flow_3:
            c2fb_temp_4 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL)))))
    c2fb_flow_0:
    c2fb_temp_13 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
    c2fb_temp_14 = Cast(c2fb_int64, local3)
    (*c2fb_temp_13) = Cast(c2fb_i64, c2fb_temp_14)
    c2fb_temp_14 = Cast(c2fb_int64, (*c2fb_temp_13))
    c2fb_temp_15 = CPtr(Long Ptr, @(arg1->bNomatch))
    c2fb_temp_16 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5ExprNearTest(CPtr(c2fb_c_int Ptr, @(local2)), arg0, arg1)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))))
    (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
    c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
    ' C unused-parameter annotation
    Return local2
End Function
' c2fb skipped fts5ExprNodeNext_STRING: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 1164: fts5ExprNodeNext_STRING: no complete C or FreeBASIC record layout for member c2fb_Fts5ExprPhrase.aTerm
Private Function fts5ExprNodeTest_TERM CDecl Alias "fts5ExprNodeTest_TERM" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1229
    Dim local0 As c2fb_Fts5ExprPhrase Ptr
    Dim local1 As c2fb_Fts5IndexIter Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As c2fb_i64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(CPtr(c2fb_Fts5ExprNearset Ptr, arg1->pNear))))[Cast(c2fb_c_int, &O0ULL)]
    local1 = CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)].pIter
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Long Ptr, @(local0->poslist.n))
    c2fb_temp_1 = Cast(c2fb_c_int, local1->nData)
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = CPtr(c2fb_u8 Ptr Ptr, @(local0->poslist.p))
        c2fb_temp_3 = CPtr(UByte Ptr, local1->pData)
        (*c2fb_temp_2) = CPtr(c2fb_u8 Ptr, c2fb_temp_3)
        c2fb_temp_3 = CPtr(UByte Ptr, (*c2fb_temp_2))
    End If
    c2fb_temp_4 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
    c2fb_temp_5 = Cast(c2fb_int64, local1->iRowid)
    (*c2fb_temp_4) = Cast(c2fb_i64, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_int64, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(Long Ptr, @(arg1->bNomatch))
    c2fb_temp_7 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((local0->poslist.n = Cast(c2fb_c_int, &O0ULL)))))))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped fts5ExprNodeNext_TERM: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 1257: fts5ExprNodeNext_TERM: no complete C or FreeBASIC record layout for member c2fb_Fts5ExprPhrase.aTerm
Private Sub fts5ExprNodeTest_OR CDecl Alias "fts5ExprNodeTest_OR" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1281
    Dim local0 As c2fb_Fts5ExprNode Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_Fts5ExprNode Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_3 As c2fb_i64 Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)]
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < arg1->nChild))))
        local2 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[local1]
        local3 = fts5NodeCompare(arg0, local0, local2)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2->bNomatch = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, local2)
            local0 = c2fb_temp_2
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
    c2fb_temp_4 = Cast(c2fb_int64, local0->iRowid)
    (*c2fb_temp_3) = Cast(c2fb_i64, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_int64, (*c2fb_temp_3))
    c2fb_temp_5 = CPtr(Long Ptr, @(arg1->bEof))
    c2fb_temp_6 = Cast(c2fb_c_int, local0->bEof)
    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    c2fb_temp_7 = CPtr(Long Ptr, @(arg1->bNomatch))
    c2fb_temp_8 = Cast(c2fb_c_int, local0->bNomatch)
    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
End Sub
Private Function fts5ExprNodeNext_OR CDecl Alias "fts5ExprNodeNext_OR" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1300
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_Fts5ExprNode Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = arg1->iRowid
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1->nChild))))
        local2 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[local0]
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local2->bEof = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((local2->iRowid = local1))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((fts5RowidCmp(arg0, local2->iRowid, arg3) < Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
                local3 = CPtr(c2fb_callback_285, (local2)->xNext)((arg0), (local2), (arg2), (arg3))
                If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_2 = CPtr(Long Ptr, @(arg1->bNomatch))
                    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
                    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
                    Return local3
                End If
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    fts5ExprNodeTest_OR(arg0, arg1)
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5ExprNodeTest_AND CDecl Alias "fts5ExprNodeTest_AND" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1332
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As c2fb_Fts5ExprNode Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_i64 Ptr
    Dim c2fb_temp_14 As c2fb_int64

    ' C automatic storage declaration
    local1 = arg1->iRowid
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    Do
        c2fb_temp_0 = CPtr(Long Ptr, @(arg1->bNomatch))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local0 < arg1->nChild))))
            local4 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[local0]
            local5 = fts5RowidCmp(arg0, local1, local4->iRowid)
            If (-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, CPtr(c2fb_callback_285, (local4)->xNext)((arg0), (local4), (Cast(c2fb_c_int, 1ULL)), (local1)))
                local2 = c2fb_temp_5
                If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_6 = CPtr(Long Ptr, @(arg1->bNomatch))
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
                    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
                    Return local2
                End If
            End If
            ' C unused-parameter annotation
            If local4->bEof Then
                fts5ExprSetEof(arg1)
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local3 = c2fb_temp_8
                Goto c2fb_flow_2
            Else
                If (-Cast(c2fb_c_int, ((local1 <> local4->iRowid)))) Then
                    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local3 = c2fb_temp_9
                    c2fb_temp_10 = Cast(c2fb_int64, local4->iRowid)
                    local1 = c2fb_temp_10
                End If
            End If
            If local4->bNomatch Then
                c2fb_temp_11 = CPtr(Long Ptr, @(arg1->bNomatch))
                c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
            End If
        c2fb_flow_3:
            c2fb_temp_4 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL)))))
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, (((arg1->bNomatch <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 <> CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot))))) <> 0))))) Then
        fts5ExprNodeZeroPoslist(arg1)
    End If
    c2fb_temp_13 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
    c2fb_temp_14 = Cast(c2fb_int64, local1)
    (*c2fb_temp_13) = Cast(c2fb_i64, c2fb_temp_14)
    c2fb_temp_14 = Cast(c2fb_int64, (*c2fb_temp_13))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5ExprNodeNext_AND CDecl Alias "fts5ExprNodeNext_AND" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1384
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_callback_285, (CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)])->xNext)((arg0), (CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)]), (arg2), (arg3))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, fts5ExprNodeTest_AND(arg0, arg1))
        local0 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(Long Ptr, @(arg1->bNomatch))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    End If
    Return local0
End Function
Private Function fts5ExprNodeTest_NOT CDecl Alias "fts5ExprNodeTest_NOT" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1399
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5ExprNode Ptr
    Dim local2 As c2fb_Fts5ExprNode Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_i64 Ptr
    Dim c2fb_temp_8 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)]
    local2 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, 1ULL)]
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->bEof = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        local3 = fts5NodeCompare(arg0, local1, local2)
        If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, CPtr(c2fb_callback_285, (local2)->xNext)((arg0), (local2), (Cast(c2fb_c_int, 1ULL)), (local1->iRowid)))
            local0 = c2fb_temp_0
            c2fb_temp_1 = Cast(c2fb_c_int, fts5NodeCompare(arg0, local1, local2))
            local3 = c2fb_temp_1
        End If
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, (((local3 <> 0) OrElse (local2->bNomatch <> 0))))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_2 = Cast(c2fb_c_int, CPtr(c2fb_callback_285, (local1)->xNext)((arg0), (local1), (Cast(c2fb_c_int, &O0ULL)), (Cast(c2fb_c_int, &O0ULL))))
        local0 = c2fb_temp_2
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(Long Ptr, @(arg1->bEof))
    c2fb_temp_4 = Cast(c2fb_c_int, local1->bEof)
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    c2fb_temp_5 = CPtr(Long Ptr, @(arg1->bNomatch))
    c2fb_temp_6 = Cast(c2fb_c_int, local1->bNomatch)
    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    c2fb_temp_7 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
    c2fb_temp_8 = Cast(c2fb_int64, local1->iRowid)
    (*c2fb_temp_7) = Cast(c2fb_i64, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_int64, (*c2fb_temp_7))
    If local1->bEof Then
        fts5ExprNodeZeroPoslist(local2)
    End If
    Return local0
End Function
Private Function fts5ExprNodeNext_NOT CDecl Alias "fts5ExprNodeNext_NOT" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1427
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_callback_285, (CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)])->xNext)((arg0), (CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)]), (arg2), (arg3))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, fts5ExprNodeTest_NOT(arg0, arg1))
        local0 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(Long Ptr, @(arg1->bNomatch))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    End If
    Return local0
End Function
Private Function fts5ExprNodeTest CDecl Alias "fts5ExprNodeTest" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1448
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg1->bEof = Cast(c2fb_c_int, &O0ULL))))) Then
        Select Case arg1->eType
            Case Cast(c2fb_c_int, 9ULL)
                c2fb_temp_0 = Cast(c2fb_c_int, fts5ExprNodeTest_STRING(arg0, arg1))
                local0 = c2fb_temp_0
                Goto c2fb_flow_0
            Case Cast(c2fb_c_int, 4ULL)
                c2fb_temp_1 = Cast(c2fb_c_int, fts5ExprNodeTest_TERM(arg0, arg1))
                local0 = c2fb_temp_1
                Goto c2fb_flow_0
            Case Cast(c2fb_c_int, 2ULL)
                c2fb_temp_2 = Cast(c2fb_c_int, fts5ExprNodeTest_AND(arg0, arg1))
                local0 = c2fb_temp_2
                Goto c2fb_flow_0
            Case Cast(c2fb_c_int, 1ULL)
                fts5ExprNodeTest_OR(arg0, arg1)
                Goto c2fb_flow_0
            Case Else
                ' C unused-parameter annotation
                c2fb_temp_3 = Cast(c2fb_c_int, fts5ExprNodeTest_NOT(arg0, arg1))
                local0 = c2fb_temp_3
                Goto c2fb_flow_0
        End Select
        c2fb_flow_0:
    End If
    Return local0
End Function
Private Function fts5ExprNodeFirst CDecl Alias "fts5ExprNodeFirst" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1493
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local3 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_i64 Ptr
    Dim c2fb_temp_12 As c2fb_int64
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Long Ptr, @(arg1->bEof))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Long Ptr, @(arg1->bNomatch))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    If ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((arg1)->eType = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((arg1)->eType = Cast(c2fb_c_int, 9ULL))))) <> 0)))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, fts5ExprNearInitAll(arg0, arg1))
        local0 = c2fb_temp_4
    Else
        If (-Cast(c2fb_c_int, ((CPtr(Any Ptr, CPtr(c2fb_callback_285, arg1->xNext)) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_5 = CPtr(Long Ptr, @(arg1->bEof))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        Else
            ' C automatic storage declaration
            local2 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_7
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < arg1->nChild)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                local3 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[local1]
                c2fb_temp_9 = Cast(c2fb_c_int, fts5ExprNodeFirst(arg0, CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[local1]))
                local0 = c2fb_temp_9
                ' C unused-parameter annotation
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + local3->bEof)))
                local2 = c2fb_temp_10
            c2fb_flow_1:
                c2fb_temp_8 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
            Wend
            c2fb_flow_0:
            c2fb_temp_11 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
            c2fb_temp_12 = Cast(c2fb_int64, CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)]->iRowid)
            (*c2fb_temp_11) = Cast(c2fb_i64, c2fb_temp_12)
            c2fb_temp_12 = Cast(c2fb_int64, (*c2fb_temp_11))
            Select Case arg1->eType
                Case Cast(c2fb_c_int, 2ULL)
                    If (-Cast(c2fb_c_int, ((local2 > Cast(c2fb_c_int, &O0ULL))))) Then
                        fts5ExprSetEof(arg1)
                    End If
                Case Cast(c2fb_c_int, 1ULL)
                    If (-Cast(c2fb_c_int, ((arg1->nChild = local2)))) Then
                        fts5ExprSetEof(arg1)
                    End If
                Case Else
                    ' C unused-parameter annotation
                    c2fb_temp_13 = CPtr(Long Ptr, @(arg1->bEof))
                    c2fb_temp_14 = Cast(c2fb_c_int, CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)]->bEof)
                    (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
                    c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
            End Select
            c2fb_flow_2:
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_15 = Cast(c2fb_c_int, fts5ExprNodeTest(arg0, arg1))
        local0 = c2fb_temp_15
    End If
    Return local0
End Function
Function sqlite3Fts5ExprFirst CDecl Alias "sqlite3Fts5ExprFirst" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5Index Ptr, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1552
    Dim local0 As c2fb_Fts5ExprNode Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5Index_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_Fts5Index_ Ptr Ptr, @(arg0->pIndex))
    c2fb_temp_1 = arg1
    (*c2fb_temp_0) = CPtr(c2fb_Fts5Index_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_Fts5Index Ptr, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->bDesc))
    c2fb_temp_3 = Cast(c2fb_c_int, arg4)
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    c2fb_temp_4 = Cast(c2fb_c_int, fts5ExprNodeFirst(arg0, local0))
    local1 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local0->bEof)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((fts5RowidCmp(arg0, local0->iRowid, arg2) < Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, CPtr(c2fb_callback_285, (local0)->xNext)((arg0), (local0), (Cast(c2fb_c_int, 1ULL)), (arg2)))
        local1 = c2fb_temp_5
    End If
    While (-Cast(c2fb_c_int, (((local0->bNomatch <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C unused-parameter annotation
        c2fb_temp_6 = Cast(c2fb_c_int, CPtr(c2fb_callback_285, (local0)->xNext)((arg0), (local0), (Cast(c2fb_c_int, &O0ULL)), (Cast(c2fb_c_int, &O0ULL))))
        local1 = c2fb_temp_6
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((fts5RowidCmp(arg0, local0->iRowid, arg3) > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_7 = CPtr(Long Ptr, @(local0->bEof))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    End If
    Return local1
End Function
Function sqlite3Fts5ExprNext CDecl Alias "sqlite3Fts5ExprNext" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1592
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot)
    ' C unused-parameter annotation
    Do
        c2fb_temp_0 = Cast(c2fb_c_int, CPtr(c2fb_callback_285, (local1)->xNext)((arg0), (local1), (Cast(c2fb_c_int, &O0ULL)), (Cast(c2fb_c_int, &O0ULL))))
        local0 = c2fb_temp_0
        ' C unused-parameter annotation
    c2fb_flow_1:
    Loop While local1->bNomatch
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((fts5RowidCmp(arg0, local1->iRowid, arg1) > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(Long Ptr, @(local1->bEof))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    End If
    Return local0
End Function
Function sqlite3Fts5ExprEof CDecl Alias "sqlite3Fts5ExprEof" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1606
    Return CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot)->bEof
End Function
Function sqlite3Fts5ExprRowid CDecl Alias "sqlite3Fts5ExprRowid" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_int64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1610
    Return CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot)->iRowid
End Function
Private Function fts5ParseStringFromToken CDecl Alias "fts5ParseStringFromToken" (ByVal arg0 As c2fb_Fts5Token Ptr, ByVal arg1 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1614
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Strndup(CPtr(c2fb_c_int Ptr, @(local0)), arg0->p, arg0->n))
    (*c2fb_temp_0) = c2fb_temp_1
    Return local0
End Function
Private Sub fts5ExprPhraseFree CDecl Alias "fts5ExprPhraseFree" (ByVal arg0 As c2fb_Fts5ExprPhrase Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1623
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_Fts5ExprTerm Ptr
    Dim local2 As c2fb_Fts5ExprTerm Ptr
    Dim local3 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_2 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_3 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_4 As c2fb_Fts5ExprTerm Ptr

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nTerm))))
            ' C automatic storage declaration
            ' C automatic storage declaration
            local3 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(arg0)))[local0]))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local3->pTerm))
            c2fb_external_sqlite3Fts5IterClose(CPtr(c2fb_Fts5IndexIter Ptr, local3->pIter))
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local3->pSynonym))
            local1 = c2fb_temp_2
            While local1
                c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local1->pSynonym))
                local2 = c2fb_temp_4
                c2fb_external_sqlite3Fts5IterClose(CPtr(c2fb_Fts5IndexIter Ptr, local1->pIter))
                c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, local1)[Cast(c2fb_c_int, 1ULL)]))))
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
            c2fb_flow_3:
                c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, local2)
                local1 = c2fb_temp_3
            Wend
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((arg0->poslist.nSpace > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
' c2fb skipped sqlite3Fts5ParseSetCaret: outside the supported subset
' c2fb body diagnostic [assignment-target-not-writable] line 1648: sqlite3Fts5ParseSetCaret: assignment target is not writable: C type=, storage=c2fb_u8, record=, layout=c2fb_u8, expression=CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_, lvalue expression=CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_, lvalue=-1, const=0, bit width=-1
Function sqlite3Fts5ParseNearset CDecl Alias "sqlite3Fts5ParseNearset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNearset Ptr, ByVal arg2 As c2fb_Fts5ExprPhrase Ptr) As c2fb_Fts5ExprNearset Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1662
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5ExprNearset Ptr
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_Fts5ExprNearset Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_Fts5ExprNearset Ptr
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_Fts5ExprNearset Ptr
    Dim local5 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_15 As c2fb_Fts5ExprPhrase_ Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Long Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_24 As c2fb_Fts5ExprPhrase Ptr

    local0 = Cast(c2fb_c_int, 8ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_0 = Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprNearset_apPhrase_tail_ptr(Cast(c2fb_Fts5ExprNearset Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprPhrase Ptr)))))))))
            local2 = c2fb_temp_0
            c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local2)))
            local1 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
                c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            Else
                c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, local2)))
            End If
        Else
            If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1->nPhrase Mod local0))) = Cast(c2fb_c_int, &O0ULL))))) Then
                local3 = Cast(c2fb_c_int, (arg1->nPhrase + local0))
                ' C automatic storage declaration
                c2fb_temp_5 = Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprNearset_apPhrase_tail_ptr(Cast(c2fb_Fts5ExprNearset Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprPhrase Ptr)))))))))
                local4 = c2fb_temp_5
                c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, CPtr(c2fb_Fts5ExprNearset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, arg1), local4))))
                local1 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_7 = CPtr(Long Ptr, @(arg0->rc))
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
                    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                End If
            Else
                c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, arg1)
                local1 = c2fb_temp_9
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        sqlite3Fts5ParseNearsetFree(arg1)
        sqlite3Fts5ParsePhraseFree(arg2)
    Else
        If (-Cast(c2fb_c_int, ((local1->nPhrase > Cast(c2fb_c_int, &O0ULL))))) Then
            local5 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local1)))[Cast(c2fb_c_int, (local1->nPhrase - Cast(c2fb_c_int, 1ULL)))]
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((arg2->nTerm = Cast(c2fb_c_int, &O0ULL))))) Then
                fts5ExprPhraseFree(arg2)
                c2fb_temp_10 = CPtr(Long Ptr, @(local1->nPhrase))
                c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                (*c2fb_temp_10) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 - 1)))
                c2fb_temp_12 = CPtr(Long Ptr, @(arg0->nPhrase))
                c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
                (*c2fb_temp_12) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 - 1)))
                c2fb_temp_14 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, local5)
                arg2 = c2fb_temp_14
            Else
                If (-Cast(c2fb_c_int, ((local5->nTerm = Cast(c2fb_c_int, &O0ULL))))) Then
                    fts5ExprPhraseFree(local5)
                    c2fb_temp_15 = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apPhrase))[Cast(c2fb_c_int, (arg0->nPhrase - Cast(c2fb_c_int, 2ULL)))]))
                    c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, arg2)
                    (*c2fb_temp_15) = CPtr(c2fb_Fts5ExprPhrase_ Ptr, c2fb_temp_16)
                    c2fb_temp_16 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_15))
                    c2fb_temp_17 = CPtr(Long Ptr, @(arg0->nPhrase))
                    c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
                    (*c2fb_temp_17) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 - 1)))
                    c2fb_temp_19 = CPtr(Long Ptr, @(local1->nPhrase))
                    c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
                    (*c2fb_temp_19) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 - 1)))
                End If
            End If
        End If
        c2fb_temp_21 = CPtr(Long Ptr, @(local1->nPhrase))
        c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
        (*c2fb_temp_21) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_22 + 1)))
        c2fb_temp_23 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local1)))[c2fb_temp_22]))
        c2fb_temp_24 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, arg2)
        (*c2fb_temp_23) = c2fb_temp_24
    End If
    Return local1
End Function
' c2fb skipped fts5ParseTokenize: outside the supported subset
' c2fb body diagnostic [assignment-target-not-writable] line 1732: fts5ParseTokenize: assignment target is not writable: C type=, storage=c2fb_Fts5ExprTerm_ Ptr, record=, layout=c2fb_Fts5ExprTerm_ Ptr, expression=CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_, lvalue expression=CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_, lvalue=-1, const=0, bit width=-1
Sub sqlite3Fts5ParsePhraseFree CDecl Alias "sqlite3Fts5ParsePhraseFree" (ByVal arg0 As c2fb_Fts5ExprPhrase Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1805
    fts5ExprPhraseFree(arg0)
End Sub
Sub sqlite3Fts5ParseNearsetFree CDecl Alias "sqlite3Fts5ParseNearsetFree" (ByVal arg0 As c2fb_Fts5ExprNearset Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1812
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nPhrase))))
            fts5ExprPhraseFree(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg0)))[local0])
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5Colset Ptr, arg0->pColset)))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Sub sqlite3Fts5ParseFinished CDecl Alias "sqlite3Fts5ParseFinished" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1823
    Dim c2fb_temp_0 As c2fb_Fts5ExprNode_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5ExprNode Ptr

    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_Fts5ExprNode_ Ptr Ptr, @(arg0->pExpr))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg1)
    (*c2fb_temp_0) = CPtr(c2fb_Fts5ExprNode_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_Fts5ExprNode Ptr, (*c2fb_temp_0))
End Sub
Private Function parseGrowPhraseArray CDecl Alias "parseGrowPhraseArray" (ByVal arg0 As c2fb_Fts5Parse Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1828
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_0 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_Fts5ExprPhrase_ Ptr Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5ExprPhrase Ptr Ptr

    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->nPhrase Mod Cast(c2fb_c_int, 8ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprPhrase Ptr))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (arg0->nPhrase + Cast(c2fb_c_int, 8ULL)))))))
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apPhrase)), local0))))
        local1 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
            c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_3 = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr Ptr, @(arg0->apPhrase))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr Ptr, local1)
        (*c2fb_temp_3) = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr, c2fb_temp_4)
        c2fb_temp_4 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (*c2fb_temp_3))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped sqlite3Fts5ParseTerm: outside the supported subset
' c2fb body diagnostic [assignment-target-not-writable] line 1847: sqlite3Fts5ParseTerm: assignment target is not writable: C type=, storage=c2fb_u8, record=, layout=c2fb_u8, expression=CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_, lvalue expression=CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_, lvalue=-1, const=0, bit width=-1
' c2fb skipped sqlite3Fts5ExprClonePhrase: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 1903: sqlite3Fts5ExprClonePhrase: no complete C or FreeBASIC record layout for member c2fb_Fts5Colset.nCol
Sub sqlite3Fts5ParseNear CDecl Alias "sqlite3Fts5ParseNear" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5Token Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2002
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->n <> Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse (c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"NEAR")), CPtr(Const Any Ptr, arg1->p), Cast(c2fb_c_int, 4ULL)) <> 0))))) Then
        sqlite3Fts5ParseError(arg0, StrPtr(!"fts5: syntax error near \034%.*s\034"), arg1->n, arg1->p)
    End If
End Sub
Sub sqlite3Fts5ParseSetDistance CDecl Alias "sqlite3Fts5ParseSetDistance" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNearset Ptr, ByVal arg2 As c2fb_Fts5Token Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2010
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As Byte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    If arg1 Then
        local0 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        If arg2->n Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_0
            While (-Cast(c2fb_c_int, ((local1 < arg2->n))))
                local2 = Cast(Byte, CPtr(Const Byte Ptr, arg2->p)[local1])
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2) < Cast(c2fb_c_int, 48))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2) > Cast(c2fb_c_int, 57))))) <> 0))))) Then
                    sqlite3Fts5ParseError(arg0, StrPtr(!"expected integer, got \034%.*s\034"), arg2->n, arg2->p)
                    Return
                End If
                If (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, 214748363ULL))))) Then
                    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0 * Cast(c2fb_c_int, 10ULL))) + (Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2->p)[local1]) - Cast(c2fb_c_int, 48)))))))
                    local0 = c2fb_temp_2
                End If
            c2fb_flow_1:
                c2fb_temp_1 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
            Wend
            c2fb_flow_0:
        Else
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 10ULL))
            local0 = c2fb_temp_3
        End If
        c2fb_temp_4 = CPtr(Long Ptr, @(arg1->nNear))
        c2fb_temp_5 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    End If
End Sub
Private Function fts5ParseColset CDecl Alias "fts5ParseColset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr, ByVal arg2 As c2fb_c_int) As c2fb_Fts5Colset Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_c_int Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int

    local0 = IIf(arg1, arg1->nCol, Cast(c2fb_c_int, &O0ULL))
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, arg1), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))) + Cast(c2fb_c_int, 2ULL)))) \ Cast(c2fb_c_int, 2ULL)))))))))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    Else
        local2 = (c2fb_Fts5Colset_aiCol_tail_ptr(local1))
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local3 < local0))))
            If (-Cast(c2fb_c_int, ((local2[local3] = arg2)))) Then
                Return local1
            End If
            If (-Cast(c2fb_c_int, ((local2[local3] > arg2)))) Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_4 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_5 = Cast(c2fb_c_int, local0)
        local4 = c2fb_temp_5
        While (-Cast(c2fb_c_int, ((local4 > local3))))
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local2[local4]))
            c2fb_temp_8 = Cast(c2fb_c_int, local2[Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 1ULL)))])
            (*c2fb_temp_7) = c2fb_temp_8
        c2fb_flow_3:
            c2fb_temp_6 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 - 1)))
        Wend
        c2fb_flow_2:
        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(local2[local3]))
        c2fb_temp_10 = Cast(c2fb_c_int, arg2)
        (*c2fb_temp_9) = c2fb_temp_10
        c2fb_temp_11 = CPtr(Long Ptr, @(local1->nCol))
        c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
        c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
    End If
    Return local1
End Function
' c2fb skipped sqlite3Fts5ParseColsetInvert: outside the supported subset
' c2fb body diagnostic [unmapped-record-field] line 2087: sqlite3Fts5ParseColsetInvert: no complete C or FreeBASIC record layout for member c2fb_Fts5Colset.nCol
Function sqlite3Fts5ParseColset CDecl Alias "sqlite3Fts5ParseColset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr, ByVal arg2 As c2fb_Fts5Token Ptr) As c2fb_Fts5Colset Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2110
    Dim local0 As c2fb_Fts5Colset Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim local3 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_Fts5Colset Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Strndup(CPtr(c2fb_c_int Ptr, @(arg0->rc)), arg2->p, arg2->n))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local3 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        c2fb_external_sqlite3Fts5Dequote(local2)
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local1 < local3->nCol))))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, local3->azCol[local1]), CPtr(Const ZString Ptr, local2)))))) Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_2 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local1 = local3->nCol)))) Then
            sqlite3Fts5ParseError(arg0, StrPtr(!"no such column: %s"), local2)
        Else
            c2fb_temp_3 = CPtr(c2fb_Fts5Colset Ptr, fts5ParseColset(arg0, arg1, local1))
            local0 = c2fb_temp_3
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg1))
    End If
    Return local0
End Function
Private Function fts5CloneColset CDecl Alias "fts5CloneColset" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr) As c2fb_Fts5Colset Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
    Dim local0 As c2fb_Fts5Colset Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Colset Ptr

    ' C automatic storage declaration
    If arg1 Then
        local1 = (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1->nCol + Cast(c2fb_c_int, 2ULL)))) \ Cast(c2fb_c_int, 2ULL))))))))
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, CPtr(c2fb_Fts5Colset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(arg0, local1))))
        local0 = c2fb_temp_0
        If local0 Then
            c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0), CPtr(Const Any Ptr, arg1), Cast(c2fb_size_t, local1)))
        End If
    Else
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_2
    End If
    Return local0
End Function
Private Sub fts5MergeColset CDecl Alias "fts5MergeColset" (ByVal arg0 As c2fb_Fts5Colset Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg0->nCol)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < arg1->nCol)))) <> 0)))))
        local3 = Cast(c2fb_c_int, ((c2fb_Fts5Colset_aiCol_tail_ptr(arg0))[local0] - (c2fb_Fts5Colset_aiCol_tail_ptr(arg1))[local1]))
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((c2fb_Fts5Colset_aiCol_tail_ptr(arg0))[c2fb_temp_0]))
            c2fb_temp_2 = Cast(c2fb_c_int, (c2fb_Fts5Colset_aiCol_tail_ptr(arg1))[local1])
            (*c2fb_temp_1) = c2fb_temp_2
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            c2fb_temp_4 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Else
            If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_5 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
            Else
                c2fb_temp_6 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_7 = CPtr(Long Ptr, @(arg0->nCol))
    c2fb_temp_8 = Cast(c2fb_c_int, local2)
    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
End Sub
Private Sub fts5ParseSetColset CDecl Alias "fts5ParseSetColset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_Fts5Colset Ptr, ByVal arg3 As c2fb_Fts5Colset Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
    Dim local0 As c2fb_Fts5ExprNearset Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Type c2fb_callback_storage_2 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_2 As c2fb_callback_storage_2 Ptr
    Dim c2fb_temp_3 As c2fb_callback_285
    Dim c2fb_temp_4 As Any Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_6 As c2fb_Fts5Colset Ptr Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_8 As Any Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Colset Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 9ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
            local0 = CPtr(c2fb_Fts5ExprNearset Ptr, arg1->pNear)
            If CPtr(c2fb_Fts5Colset Ptr, local0->pColset) Then
                fts5MergeColset(CPtr(c2fb_Fts5Colset Ptr, local0->pColset), arg2)
                If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Colset Ptr, local0->pColset)->nCol = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_0 = CPtr(Long Ptr, @(arg1->eType))
                    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
                    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
                    c2fb_temp_2 = CPtr(c2fb_callback_storage_2 Ptr, @(arg1->xNext))
                    c2fb_temp_3 = CPtr(c2fb_callback_285, 0)
                    (*c2fb_temp_2) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_3)
                    c2fb_temp_3 = CPtr(c2fb_callback_285, (*c2fb_temp_2))
                End If
            Else
                If (*arg3) Then
                    c2fb_temp_4 = CPtr(Any Ptr Ptr, @(local0->pColset))
                    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, arg2)
                    (*c2fb_temp_4) = CPtr(Any Ptr, c2fb_temp_5)
                    c2fb_temp_5 = CPtr(c2fb_Fts5Colset Ptr, (*c2fb_temp_4))
                    c2fb_temp_6 = CPtr(c2fb_Fts5Colset Ptr Ptr, @((*arg3)))
                    c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_6) = c2fb_temp_7
                Else
                    c2fb_temp_8 = CPtr(Any Ptr Ptr, @(local0->pColset))
                    c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, CPtr(c2fb_Fts5Colset Ptr, fts5CloneColset(CPtr(c2fb_c_int Ptr, @(arg0->rc)), arg2)))
                    (*c2fb_temp_8) = CPtr(Any Ptr, c2fb_temp_9)
                    c2fb_temp_9 = CPtr(c2fb_Fts5Colset Ptr, (*c2fb_temp_8))
                End If
            End If
        Else
            ' C automatic storage declaration
            ' C unused-parameter annotation
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_10
            While (-Cast(c2fb_c_int, ((local1 < arg1->nChild))))
                fts5ParseSetColset(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[local1]), CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, arg2), CPtr(_c2fb_record_c2fb_Fts5Colset Ptr Ptr, arg3))
            c2fb_flow_1:
                c2fb_temp_11 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
            Wend
            c2fb_flow_0:
        End If
    End If
End Sub
Sub sqlite3Fts5ParseSetColset CDecl Alias "sqlite3Fts5ParseSetColset" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_Fts5Colset Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2231
    Dim local0 As c2fb_Fts5Colset Ptr

    local0 = arg2
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, 1ULL))))) Then
        sqlite3Fts5ParseError(arg0, StrPtr(!"fts5: column queries are not supported (detail=none)"))
    Else
        fts5ParseSetColset(arg0, arg1, arg2, CPtr(c2fb_Fts5Colset Ptr Ptr, @(local0)))
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
End Sub
Private Sub fts5ExprAddChildren CDecl Alias "fts5ExprAddChildren" (ByVal arg0 As c2fb_Fts5ExprNode Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2283
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_Fts5ExprNode Ptr Ptr
    Dim c2fb_temp_6 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = arg0->nChild
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eType <> Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->eType = arg0->eType)))) <> 0))))) Then
        local1 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprNode Ptr))) * Cast(c2fb_uint64, arg1->nChild)))
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_Fts5ExprNode Ptr Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[arg0->nChild]))), CPtr(Const Any Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1))), local1))
        c2fb_temp_1 = CPtr(Long Ptr, @(arg0->nChild))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_1)) + arg1->nChild)))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg1))
    Else
        c2fb_temp_3 = CPtr(Long Ptr, @(arg0->nChild))
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        c2fb_temp_5 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[c2fb_temp_4]))
        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg1)
        (*c2fb_temp_5) = c2fb_temp_6
    End If
    While (-Cast(c2fb_c_int, ((local0 < arg0->nChild))))
        c2fb_temp_8 = CPtr(Long Ptr, @(arg0->iHeight))
        c2fb_temp_9 = Cast(c2fb_c_int, (IIf(((-Cast(c2fb_c_int, (((arg0->iHeight) > ((CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[local0]->iHeight + Cast(c2fb_c_int, 1ULL)))))))), (arg0->iHeight), ((CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[local0]->iHeight + Cast(c2fb_c_int, 1ULL))))))
        (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
    c2fb_flow_1:
        c2fb_temp_7 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
    Wend
    c2fb_flow_0:
End Sub
Function sqlite3Fts5ParseImplicitAnd CDecl Alias "sqlite3Fts5ParseImplicitAnd" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_Fts5ExprNode Ptr) As c2fb_Fts5ExprNode Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2460
    Dim local0 As c2fb_Fts5ExprNode Ptr
    Dim local1 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_0 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_1 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_2 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local2 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_6 As c2fb_Fts5ExprNode Ptr Ptr
    Dim c2fb_temp_7 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_8 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_9 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_Fts5ExprNode Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    If arg0->rc Then
        sqlite3Fts5ParseNodeFree(arg1)
        sqlite3Fts5ParseNodeFree(arg2)
    Else
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 2ULL))))) Then
            c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, (arg1->nChild - Cast(c2fb_c_int, 1ULL)))])
            local1 = c2fb_temp_0
        Else
            c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg1)
            local1 = c2fb_temp_1
        End If
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((arg2->eType = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            sqlite3Fts5ParseNodeFree(arg2)
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg1)
            local0 = c2fb_temp_2
            c2fb_temp_3 = CPtr(Long Ptr, @(arg0->nPhrase))
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 - 1)))
        Else
            If (-Cast(c2fb_c_int, ((local1->eType = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C automatic storage declaration
                If (-Cast(c2fb_c_int, ((local1 = arg1)))) Then
                    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg2)
                    local0 = c2fb_temp_5
                Else
                    c2fb_temp_6 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[Cast(c2fb_c_int, (arg1->nChild - Cast(c2fb_c_int, 1ULL)))]))
                    c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg2)
                    (*c2fb_temp_6) = c2fb_temp_7
                    c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg1)
                    local0 = c2fb_temp_8
                End If
                c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apPhrase))[Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0->nPhrase - Cast(c2fb_c_int, 1ULL))) - CPtr(c2fb_Fts5ExprNearset Ptr, arg2->pNear)->nPhrase))])))
                local2 = c2fb_temp_9
                ' C unused-parameter annotation
                c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, local2), CPtr(Const Any Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local2)[Cast(c2fb_c_int, 1ULL)]))), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprPhrase Ptr))) * Cast(c2fb_uint64, CPtr(c2fb_Fts5ExprNearset Ptr, arg2->pNear)->nPhrase)))))
                c2fb_temp_11 = CPtr(Long Ptr, @(arg0->nPhrase))
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
                (*c2fb_temp_11) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 - 1)))
                sqlite3Fts5ParseNodeFree(local1)
            Else
                c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, sqlite3Fts5ParseNode(arg0, Cast(c2fb_c_int, 2ULL), arg1, arg2, Cast(c2fb_c_int, &O0ULL))))
                local0 = c2fb_temp_13
            End If
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5ExprPhraseCount CDecl Alias "sqlite3Fts5ExprPhraseCount" (ByVal arg0 As c2fb_Fts5Expr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2942
    Return (IIf(arg0, arg0->nPhrase, Cast(c2fb_c_int, &O0ULL)))
End Function
Function sqlite3Fts5ExprPhraseSize CDecl Alias "sqlite3Fts5ExprPhraseSize" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2949
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= arg0->nPhrase)))) <> 0))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    Return CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[arg1]->nTerm
End Function
Function sqlite3Fts5ExprPoslist CDecl Alias "sqlite3Fts5ExprPoslist" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2958
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5ExprPhrase Ptr
    Dim local2 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_0 As Const UByte Ptr Ptr
    Dim c2fb_temp_1 As Const UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Const UByte Ptr Ptr
    Dim c2fb_temp_4 As Const UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[arg1]
    local2 = CPtr(c2fb_Fts5ExprNode Ptr, local1->pNode)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2->bEof = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2->iRowid = CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot)->iRowid)))) <> 0))))) Then
        c2fb_temp_0 = CPtr(Const UByte Ptr Ptr, @((*arg2)))
        c2fb_temp_1 = CPtr(Const UByte Ptr, local1->poslist.p)
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, local1->poslist.n)
        local0 = c2fb_temp_2
    Else
        c2fb_temp_3 = CPtr(Const UByte Ptr Ptr, @((*arg2)))
        c2fb_temp_4 = CPtr(Const UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_5
    End If
    Return local0
End Function
Function sqlite3Fts5ExprClearPoslists CDecl Alias "sqlite3Fts5ExprClearPoslists" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int) As c2fb_Fts5PoslistPopulator Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2987
    Dim local0 As c2fb_Fts5PoslistPopulator Ptr
    Dim c2fb_temp_0 As c2fb_Fts5PoslistPopulator Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local2 As c2fb_Fts5Buffer Ptr
    Dim local3 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5PoslistPopulator Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistPopulator))) * Cast(c2fb_uint64, arg0->nPhrase))))))
    local0 = c2fb_temp_0
    If local0 Then
        ' C automatic storage declaration
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistPopulator))) * Cast(c2fb_uint64, arg0->nPhrase)))))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local1 < arg0->nPhrase))))
            local2 = CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[local1]->poslist))
            local3 = CPtr(c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[local1]->pNode)
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2->n = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3->iRowid <> CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot)->iRowid)))) <> 0) OrElse (local3->bEof <> 0)))))) <> 0))))) Then
                c2fb_temp_4 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5PoslistPopulator Ptr, local0)[local1].bMiss))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
                c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            Else
                c2fb_temp_6 = CPtr(Long Ptr, @(local2->n))
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
                c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            End If
        c2fb_flow_1:
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
    End If
    Return local0
End Function
Private Function fts5ExprColsetTest CDecl Alias "fts5ExprColsetTest" (ByVal arg0 As c2fb_Fts5Colset Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
        If (-Cast(c2fb_c_int, (((c2fb_Fts5Colset_aiCol_tail_ptr(arg0))[local0] = arg1)))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5QueryTerm CDecl Alias "fts5QueryTerm" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3032
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg1)))) <> 0) AndAlso (CPtr(Const Byte Ptr, arg0)[local0] <> 0)))))
        ' empty C block
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Function fts5ExprPopulatePoslistsCb CDecl Alias "fts5ExprPopulatePoslistsCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3038
    Dim local0 As c2fb_Fts5ExprCtx Ptr
    Dim local1 As c2fb_Fts5Expr Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_i64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local5 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_6 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_7 As c2fb_Fts5ExprTerm Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprCtx Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Expr Ptr, local0->pExpr)
    ' C automatic storage declaration
    local3 = arg3
    local4 = CPtr(c2fb_Fts5ExprNode Ptr, local1->pRoot)->iRowid
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, 32768ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 32768ULL))
        local3 = c2fb_temp_0
    End If
    If CPtr(c2fb_Fts5Config Ptr, local1->pConfig)->bTokendata Then
        c2fb_temp_1 = Cast(c2fb_c_int, fts5QueryTerm(arg2, local3))
        local3 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0001ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = CPtr(c2fb_i64 Ptr, @(local0->iOff))
        c2fb_temp_3 = Cast(c2fb_int64, (*c2fb_temp_2))
        (*c2fb_temp_2) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_3 + 1)))
    End If
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local2 < local1->nPhrase))))
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5PoslistPopulator Ptr, CPtr(c2fb_Fts5PoslistPopulator Ptr, local0->aPopulator))[local2].bOk = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_1
        End If
        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local1->apExprPhrase))[local2])))[Cast(c2fb_c_int, &O0ULL)])))
        local5 = c2fb_temp_6
        While local5
            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5->nQueryTerm = local3)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5->nQueryTerm < local3)))) <> 0) AndAlso (local5->bPrefix <> 0)))))) <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, local5->pTerm), CPtr(Const Any Ptr, arg2), local5->nQueryTerm) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                local6 = c2fb_external_sqlite3Fts5PoslistWriterAppend(CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local1->apExprPhrase))[local2]->poslist)), CPtr(c2fb_Fts5PoslistWriter Ptr, @(CPtr(c2fb_Fts5PoslistPopulator Ptr, CPtr(c2fb_Fts5PoslistPopulator Ptr, local0->aPopulator))[local2].writer)), local0->iOff)
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Config Ptr, local1->pConfig)->bTokendata <> 0) OrElse (local5->bPrefix <> 0)))))) <> 0))))) Then
                    local7 = Cast(c2fb_int64, (local0->iOff Shr Cast(c2fb_c_int, 32ULL)))
                    local8 = Cast(c2fb_int64, (local0->iOff And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL))))
                    c2fb_temp_8 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IndexIterWriteTokendata(CPtr(c2fb_Fts5IndexIter Ptr, local5->pIter), arg2, arg3, local4, local7, local8))
                    local6 = c2fb_temp_8
                End If
                If local6 Then
                    Return local6
                End If
                Goto c2fb_flow_2
            End If
        c2fb_flow_3:
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local5->pSynonym))
            local5 = c2fb_temp_7
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_5 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts5ExprPopulatePoslists CDecl Alias "sqlite3Fts5ExprPopulatePoslists" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Expr Ptr, ByVal arg2 As c2fb_Fts5PoslistPopulator Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3084
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5ExprCtx
    Dim c2fb_temp_0 As c2fb_Fts5Expr_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5PoslistPopulator_ Ptr Ptr
    Dim c2fb_temp_3 As c2fb_Fts5PoslistPopulator Ptr
    Dim c2fb_temp_4 As c2fb_i64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local2 As c2fb_Fts5ExprNode Ptr
    Dim local3 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_Fts5Expr_ Ptr Ptr, @(local1.pExpr))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, arg1)
    (*c2fb_temp_0) = CPtr(c2fb_Fts5Expr_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_Fts5Expr Ptr, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(c2fb_Fts5PoslistPopulator_ Ptr Ptr, @(local1.aPopulator))
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5PoslistPopulator Ptr, arg2)
    (*c2fb_temp_2) = CPtr(c2fb_Fts5PoslistPopulator_ Ptr, c2fb_temp_3)
    c2fb_temp_3 = CPtr(c2fb_Fts5PoslistPopulator Ptr, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(c2fb_i64 Ptr, @(local1.iOff))
    c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_int64, ((Cast(c2fb_int64, ((Cast(c2fb_int64, arg3)) Shl Cast(c2fb_c_int, 32ULL)))) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))
    (*c2fb_temp_4) = Cast(c2fb_i64, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_int64, (*c2fb_temp_4))
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_6
    While (-Cast(c2fb_c_int, ((local0 < arg1->nPhrase))))
        local2 = CPtr(c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg1->apExprPhrase))[local0]->pNode)
        local3 = CPtr(c2fb_Fts5Colset Ptr, CPtr(c2fb_Fts5ExprNearset Ptr, local2->pNear)->pColset)
        If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5ExprColsetTest(local3, arg3))))) <> 0)))))) <> 0) OrElse (CPtr(c2fb_Fts5PoslistPopulator Ptr, arg2)[local0].bMiss <> 0))))) Then
            c2fb_temp_8 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5PoslistPopulator Ptr, arg2)[local0].bOk))
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
            c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
        Else
            c2fb_temp_10 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5PoslistPopulator Ptr, arg2)[local0].bOk))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        End If
    c2fb_flow_1:
        c2fb_temp_7 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
    Wend
    c2fb_flow_0:
    Return c2fb_external_sqlite3Fts5Tokenize(arg0, Cast(c2fb_c_int, &H0004ULL), arg4, arg5, CPtr(Any Ptr, CPtr(c2fb_Fts5ExprCtx Ptr, @(local1))), ProcPtr(fts5ExprPopulatePoslistsCb))
End Function
Private Sub fts5ExprClearPoslists CDecl Alias "fts5ExprClearPoslists" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eType = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->eType = Cast(c2fb_c_int, 9ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(CPtr(c2fb_Fts5ExprNearset Ptr, arg0->pNear))))[Cast(c2fb_c_int, &O0ULL)]->poslist.n))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    Else
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local0 < arg0->nChild))))
            fts5ExprClearPoslists(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[local0]))
        c2fb_flow_1:
            c2fb_temp_3 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
    End If
End Sub
Private Function fts5ExprCheckPoslists CDecl Alias "fts5ExprCheckPoslists" (ByVal arg0 As c2fb_Fts5ExprNode Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3125
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int

    c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->iRowid))
    c2fb_temp_1 = Cast(c2fb_int64, arg1)
    (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->bEof))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    Select Case arg0->eType
        Case Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 9ULL)
            Return ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(CPtr(c2fb_Fts5ExprNearset Ptr, arg0->pNear))))[Cast(c2fb_c_int, &O0ULL)]->poslist.n > Cast(c2fb_c_int, &O0ULL))))))
        Case Cast(c2fb_c_int, 2ULL)
            ' C automatic storage declaration
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_4
            While (-Cast(c2fb_c_int, ((local0 < arg0->nChild))))
                If (-Cast(c2fb_c_int, ((fts5ExprCheckPoslists(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[local0], arg1) = Cast(c2fb_c_int, &O0ULL))))) Then
                    fts5ExprClearPoslists(arg0)
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
            c2fb_flow_2:
                c2fb_temp_5 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
            Wend
            c2fb_flow_1:
            Goto c2fb_flow_0
        Case Cast(c2fb_c_int, 1ULL)
            ' C automatic storage declaration
            local2 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((local1 < arg0->nChild))))
                If fts5ExprCheckPoslists(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[local1], arg1) Then
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local2 = c2fb_temp_8
                End If
            c2fb_flow_4:
                c2fb_temp_7 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            Wend
            c2fb_flow_3:
            Return local2
        Case Else
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5ExprCheckPoslists(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[Cast(c2fb_c_int, &O0ULL)], arg1))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) <> fts5ExprCheckPoslists(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg0)))[Cast(c2fb_c_int, 1ULL)], arg1))))) <> 0))))) Then
                fts5ExprClearPoslists(arg0)
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            Goto c2fb_flow_0
    End Select
    c2fb_flow_0:
    Return Cast(c2fb_c_int, 1ULL)
End Function
Sub sqlite3Fts5ExprCheckPoslists CDecl Alias "sqlite3Fts5ExprCheckPoslists" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3170
    fts5ExprCheckPoslists(CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot), arg1)
End Sub
Function sqlite3Fts5ExprPhraseCollist CDecl Alias "sqlite3Fts5ExprPhraseCollist" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3177
    Dim local0 As c2fb_Fts5ExprPhrase Ptr
    Dim local1 As c2fb_Fts5ExprNode Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5ExprTerm Ptr
    Dim local4 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const UByte Ptr Ptr
    Dim c2fb_temp_2 As Const UByte Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Const UByte Ptr Ptr
    Dim c2fb_temp_6 As Const UByte Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[arg1]
    local1 = CPtr(c2fb_Fts5ExprNode Ptr, local0->pNode)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->bEof = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->iRowid = CPtr(c2fb_Fts5ExprNode Ptr, arg0->pRoot)->iRowid)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->poslist.n > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        local3 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)]))
        If CPtr(c2fb_Fts5ExprTerm Ptr, local3->pSynonym) Then
            local4 = CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local3->pSynonym))[Cast(c2fb_c_int, 1ULL)])))
            c2fb_temp_0 = Cast(c2fb_c_int, fts5ExprSynonymList(local3, local1->iRowid, local4, CPtr(UByte Ptr Ptr, arg2), arg3))
            local2 = c2fb_temp_0
        Else
            c2fb_temp_1 = CPtr(Const UByte Ptr Ptr, @((*arg2)))
            c2fb_temp_2 = CPtr(Const UByte Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)].pIter->pData)
            (*c2fb_temp_1) = c2fb_temp_2
            c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_4 = Cast(c2fb_c_int, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)].pIter->nData)
            (*c2fb_temp_3) = c2fb_temp_4
        End If
    Else
        c2fb_temp_5 = CPtr(Const UByte Ptr Ptr, @((*arg2)))
        c2fb_temp_6 = CPtr(Const UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_7) = c2fb_temp_8
    End If
    Return local2
End Function
Function sqlite3Fts5ExprQueryToken CDecl Alias "sqlite3Fts5ExprQueryToken" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3215
    Dim local0 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_0 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= arg0->nPhrase)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 25ULL)
    End If
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[arg1])
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2 >= local0->nTerm)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 25ULL)
    End If
    c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, @((*arg3)))
    c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local0)))[arg2].pTerm)
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_4 = Cast(c2fb_c_int, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local0)))[arg2].nFullTerm)
    (*c2fb_temp_3) = c2fb_temp_4
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts5ExprInstToken CDecl Alias "sqlite3Fts5ExprInstToken" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3240
    Dim local0 As c2fb_Fts5ExprPhrase Ptr
    Dim local1 As c2fb_Fts5ExprTerm Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_1 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Const ZString Ptr Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2 >= arg0->nPhrase)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 25ULL)
    End If
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[arg2])
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg5 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg5 >= local0->nTerm)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 25ULL)
    End If
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local0)))[arg5])))
    local1 = c2fb_temp_1
    If (-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bTokendata <> 0) OrElse (local1->bPrefix <> 0))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterToken(CPtr(c2fb_Fts5IndexIter Ptr, local1->pIter), CPtr(Const ZString Ptr, local1->pTerm), local1->nQueryTerm, arg1, arg3, Cast(c2fb_c_int, (arg4 + arg5)), arg6, arg7))
        local2 = c2fb_temp_2
    Else
        c2fb_temp_3 = CPtr(Const ZString Ptr Ptr, @((*arg6)))
        c2fb_temp_4 = CPtr(Const ZString Ptr, local1->pTerm)
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg7)))
        c2fb_temp_6 = Cast(c2fb_c_int, local1->nFullTerm)
        (*c2fb_temp_5) = c2fb_temp_6
    End If
    Return local2
End Function
Sub sqlite3Fts5ExprClearTokens CDecl Alias "sqlite3Fts5ExprClearTokens" (ByVal arg0 As c2fb_Fts5Expr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 3278
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_2 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_3 As c2fb_Fts5ExprTerm Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0->nPhrase))))
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[local0])))[Cast(c2fb_c_int, &O0ULL)])))
        local1 = c2fb_temp_2
        While local1
            c2fb_external_sqlite3Fts5IndexIterClearTokendata(CPtr(c2fb_Fts5IndexIter Ptr, local1->pIter))
        c2fb_flow_3:
            c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local1->pSynonym))
            local1 = c2fb_temp_3
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
End Sub

/'
    C2FB expression helpers recovered in the October 2026 source-unit pass.
    Each body retains its upstream file and line comment for traceability.
'/

Function sqlite3Fts5ExprNew CDecl Alias "sqlite3Fts5ExprNew" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_Fts5Expr Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 271
    Dim local0 As c2fb_Fts5Parse
    Dim local1 As c2fb_Fts5Token
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As Any Ptr
    Dim local5 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Expr Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As Any Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5Expr Ptr Ptr
    Dim c2fb_temp_17 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_Fts5ExprNode_ Ptr Ptr
    Dim c2fb_temp_21 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_22 As c2fb_Fts5Index_ Ptr Ptr
    Dim c2fb_temp_23 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_24 As Any Ptr Ptr
    Dim c2fb_temp_25 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_26 As c2fb_Fts5ExprPhrase_ Ptr Ptr Ptr
    Dim c2fb_temp_27 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_28 As Long Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As Long Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As Any Ptr Ptr Ptr
    Dim c2fb_temp_33 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_34 As ZString Ptr Ptr
    Dim c2fb_temp_35 As ZString Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = arg3
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_Fts5Expr Ptr Ptr, @((*arg4)))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @((*arg5)))
    c2fb_temp_3 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Parse Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Parse))))
    c2fb_temp_5 = CPtr(Long Ptr, @(local0.bPhraseToAnd))
    c2fb_temp_6 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    c2fb_temp_7 = CPtr(Any Ptr, c2fb_external_sqlite3Fts5ParserAlloc(ProcPtr(fts5ParseAlloc)))
    local4 = c2fb_temp_7
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_8 = CPtr(Any Ptr Ptr, @(local0.pConfig))
    c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, arg0)
    (*c2fb_temp_8) = CPtr(Any Ptr, c2fb_temp_9)
    c2fb_temp_9 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_8))
    Do
        c2fb_temp_10 = Cast(c2fb_c_int, fts5ExprGetToken(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, CPtr(c2fb_Fts5Parse Ptr, @(local0))), CPtr(Const ZString Ptr Ptr, @(local2)), CPtr(_c2fb_record_c2fb_Fts5Token Ptr, CPtr(c2fb_Fts5Token Ptr, @(local1)))))
        local3 = c2fb_temp_10
        c2fb_external_sqlite3Fts5Parser(local4, local3, local1, CPtr(c2fb_Fts5Parse Ptr, @(local0)))
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0.rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
    c2fb_flow_0:
    c2fb_external_sqlite3Fts5ParserFree(local4, ProcPtr(fts5ParseFree))
    ' C unused-parameter annotation
    ' empty C statement
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0.rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 < arg0->nCol)))) <> 0))))) Then
        local6 = (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + Cast(c2fb_c_int, 2ULL)))) \ Cast(c2fb_c_int, 2ULL))))))))
        local7 = CPtr(c2fb_Fts5Colset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0.rc)), local6)))
        If local7 Then
            c2fb_temp_11 = CPtr(Long Ptr, @(local7->nCol))
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
            c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @((c2fb_Fts5Colset_aiCol_tail_ptr(local7))[Cast(c2fb_c_int, &O0ULL)]))
            c2fb_temp_14 = Cast(c2fb_c_int, arg2)
            (*c2fb_temp_13) = c2fb_temp_14
            sqlite3Fts5ParseSetColset(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, CPtr(c2fb_Fts5Parse Ptr, @(local0))), CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local0.pExpr)), CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, local7))
        End If
    End If
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0.rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_16 = CPtr(c2fb_Fts5Expr Ptr Ptr, @((*arg4)))
        c2fb_temp_15 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_Fts5Expr)))))
        local5 = c2fb_temp_15
        c2fb_temp_17 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, c2fb_temp_15)
        (*c2fb_temp_16) = c2fb_temp_17
        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_18 = CPtr(Long Ptr, @(local0.rc))
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
            c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
            sqlite3Fts5ParseNodeFree(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local0.pExpr)))
        Else
            c2fb_temp_20 = CPtr(c2fb_Fts5ExprNode_ Ptr Ptr, @(local5->pRoot))
            c2fb_temp_21 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local0.pExpr))
            (*c2fb_temp_20) = CPtr(c2fb_Fts5ExprNode_ Ptr, c2fb_temp_21)
            c2fb_temp_21 = CPtr(c2fb_Fts5ExprNode Ptr, (*c2fb_temp_20))
            c2fb_temp_22 = CPtr(c2fb_Fts5Index_ Ptr Ptr, @(local5->pIndex))
            c2fb_temp_23 = CPtr(c2fb_Fts5Index Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_22) = CPtr(c2fb_Fts5Index_ Ptr, c2fb_temp_23)
            c2fb_temp_23 = CPtr(c2fb_Fts5Index Ptr, (*c2fb_temp_22))
            c2fb_temp_24 = CPtr(Any Ptr Ptr, @(local5->pConfig))
            c2fb_temp_25 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, arg0)
            (*c2fb_temp_24) = CPtr(Any Ptr, c2fb_temp_25)
            c2fb_temp_25 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_24))
            c2fb_temp_26 = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr Ptr, @(local5->apExprPhrase))
            c2fb_temp_27 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local0.apPhrase))
            (*c2fb_temp_26) = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr, c2fb_temp_27)
            c2fb_temp_27 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (*c2fb_temp_26))
            c2fb_temp_28 = CPtr(Long Ptr, @(local5->nPhrase))
            c2fb_temp_29 = Cast(c2fb_c_int, local0.nPhrase)
            (*c2fb_temp_28) = Cast(Long, c2fb_temp_29)
            c2fb_temp_29 = Cast(c2fb_c_int, (*c2fb_temp_28))
            c2fb_temp_30 = CPtr(Long Ptr, @(local5->bDesc))
            c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_30) = Cast(Long, c2fb_temp_31)
            c2fb_temp_31 = Cast(c2fb_c_int, (*c2fb_temp_30))
            c2fb_temp_32 = CPtr(Any Ptr Ptr Ptr, @(local0.apPhrase))
            c2fb_temp_33 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_32) = CPtr(Any Ptr Ptr, c2fb_temp_33)
            c2fb_temp_33 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (*c2fb_temp_32))
        End If
    Else
        sqlite3Fts5ParseNodeFree(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local0.pExpr)))
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local0.apPhrase)))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (*arg5))))) Then
        c2fb_temp_34 = CPtr(ZString Ptr Ptr, @((*arg5)))
        c2fb_temp_35 = local0.zErr
        (*c2fb_temp_34) = c2fb_temp_35
    Else
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0.zErr))
    End If
    Return local0.rc
End Function

Private Function fts5ExprNearTest CDecl Alias "fts5ExprNearTest" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Expr Ptr, ByVal arg2 As c2fb_Fts5ExprNode Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 898
    Dim local0 As c2fb_Fts5ExprNearset Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5ExprTerm Ptr
    Dim local3 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_3 As c2fb_Fts5ExprTerm Ptr
    Dim local4 As c2fb_Fts5IndexIter Ptr
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local6 As c2fb_Fts5ExprPhrase Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local8 As c2fb_Fts5IndexIter Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprNearset Ptr, arg2->pNear)
    local1 = (*arg0)
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg1->pConfig)->eDetail <> Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        local3 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)]
        c2fb_temp_0 = CPtr(Long Ptr, @(local3->poslist.n))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local3)))[Cast(c2fb_c_int, &O0ULL)])))
        local2 = c2fb_temp_2
        While local2
            local4 = CPtr(c2fb_Fts5IndexIter Ptr, local2->pIter)
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((local4)->bEof)) = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4->iRowid = arg2->iRowid)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4->nData > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_4 = CPtr(Long Ptr, @(local3->poslist.n))
                    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
                    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local2->pSynonym))
            local2 = c2fb_temp_3
        Wend
        c2fb_flow_0:
        Return local3->poslist.n
    Else
        ' C automatic storage declaration
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local5 = c2fb_temp_6
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < local0->nPhrase)))) <> 0)))))
            local6 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[local5]
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6->nTerm > Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse (CPtr(c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local6)))[Cast(c2fb_c_int, &O0ULL)].pSynonym) <> 0) OrElse (CPtr(c2fb_Fts5Colset Ptr, local0->pColset) <> 0) OrElse (CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local6)))[Cast(c2fb_c_int, &O0ULL)].bFirst <> 0))))) Then
                local7 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_8 = Cast(c2fb_c_int, fts5ExprPhraseIsMatch(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg2), CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, local6), CPtr(c2fb_c_int Ptr, @(local7))))
                local1 = c2fb_temp_8
                If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_2
                End If
            Else
                local8 = CPtr(c2fb_Fts5IndexIter Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local6)))[Cast(c2fb_c_int, &O0ULL)].pIter)
                sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local6->poslist))), local8->nData, local8->pData)
            End If
        c2fb_flow_3:
            c2fb_temp_7 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg0)))
        c2fb_temp_10 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_9) = c2fb_temp_10
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 = local0->nPhrase)))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse (fts5ExprNearIsMatch(arg0, CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, local0)) <> 0)))))) <> 0))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
        Return Cast(c2fb_c_int, &O0ULL)
    End If
End Function

Private Function fts5ExprNodeNext_STRING CDecl Alias "fts5ExprNodeNext_STRING" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1164
    Dim local0 As c2fb_Fts5ExprTerm Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5ExprTerm Ptr
    Dim local4 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_3 As c2fb_Fts5ExprTerm Ptr
    Dim local5 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local6 As c2fb_Fts5IndexIter Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(CPtr(c2fb_Fts5ExprNearset Ptr, arg1->pNear))))[Cast(c2fb_c_int, &O0ULL)])))[Cast(c2fb_c_int, &O0ULL)]))
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Long Ptr, @(arg1->bNomatch))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    If CPtr(c2fb_Fts5ExprTerm Ptr, local0->pSynonym) Then
        local2 = Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        local4 = fts5ExprSynonymRowid(CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, local0), arg0->bDesc, Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, local0)
        local3 = c2fb_temp_2
        While local3
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((CPtr(c2fb_Fts5IndexIter Ptr, local3->pIter))->bEof)) = Cast(c2fb_c_int, &O0ULL))))) Then
                local5 = CPtr(c2fb_Fts5IndexIter Ptr, local3->pIter)->iRowid
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 = local4)))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 <> arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 > arg3))))) = arg0->bDesc)))) <> 0)))))) <> 0))))) Then
                    If arg2 Then
                        c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNextFrom(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, CPtr(c2fb_Fts5IndexIter Ptr, local3->pIter)), arg3))
                        local1 = c2fb_temp_4
                    Else
                        c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNext(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, CPtr(c2fb_Fts5IndexIter Ptr, local3->pIter))))
                        local1 = c2fb_temp_5
                    End If
                    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_0
                    End If
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((CPtr(c2fb_Fts5IndexIter Ptr, local3->pIter))->bEof)) = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        local2 = c2fb_temp_6
                    End If
                Else
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local2 = c2fb_temp_7
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local3->pSynonym))
            local3 = c2fb_temp_3
        Wend
        c2fb_flow_0:
        c2fb_temp_8 = CPtr(Long Ptr, @(arg1->bEof))
        c2fb_temp_9 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((local1 <> 0) OrElse (local2 <> 0)))))))
        (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
    Else
        local6 = CPtr(c2fb_Fts5IndexIter Ptr, local0->pIter)
        ' C unused-parameter annotation
        If arg2 Then
            c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNextFrom(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, local6), arg3))
            local1 = c2fb_temp_10
        Else
            c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNext(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, local6)))
            local1 = c2fb_temp_11
        End If
        c2fb_temp_12 = CPtr(Long Ptr, @(arg1->bEof))
        c2fb_temp_13 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((local1 <> 0) OrElse (((local6)->bEof) <> 0)))))))
        (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
        c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
    End If
    If (-Cast(c2fb_c_int, ((arg1->bEof = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_14 = Cast(c2fb_c_int, fts5ExprNodeTest_STRING(CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg1)))
        local1 = c2fb_temp_14
    End If
    Return local1
End Function

Private Function fts5ExprNodeNext_TERM CDecl Alias "fts5ExprNodeNext_TERM" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1257
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5IndexIter Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5IndexIter Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(CPtr(c2fb_Fts5ExprNearset Ptr, arg1->pNear))))[Cast(c2fb_c_int, &O0ULL)])))[Cast(c2fb_c_int, &O0ULL)].pIter)
    ' C unused-parameter annotation
    If arg2 Then
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNextFrom(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, local1), arg3))
        local0 = c2fb_temp_0
    Else
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5IterNext(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, local1)))
        local0 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((local1)->bEof)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, fts5ExprNodeTest_TERM(CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg1)))
        local0 = c2fb_temp_2
    Else
        c2fb_temp_3 = CPtr(Long Ptr, @(arg1->bEof))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        c2fb_temp_5 = CPtr(Long Ptr, @(arg1->bNomatch))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    End If
    Return local0
End Function

Sub sqlite3Fts5ParseSetCaret CDecl Alias "sqlite3Fts5ParseSetCaret" (ByVal arg0 As c2fb_Fts5ExprPhrase Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1648
    Dim c2fb_temp_0 As c2fb_u8 Ptr
    Dim c2fb_temp_1 As UByte

    If (-Cast(c2fb_c_int, (((arg0 <> 0) AndAlso (arg0->nTerm <> 0))))) Then
        c2fb_temp_0 = CPtr(c2fb_u8 Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(arg0)))[Cast(c2fb_c_int, &O0ULL)].bFirst))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = Cast(c2fb_u8, c2fb_temp_1)
        c2fb_temp_1 = Cast(UByte, (*c2fb_temp_0))
    End If
End Sub

Private Function fts5ParseTokenize CDecl Alias "fts5ParseTokenize" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1732
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_TokenCtx Ptr
    Dim local3 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local4 As c2fb_Fts5ExprTerm Ptr
    Dim local5 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_Fts5ExprTerm_ Ptr Ptr
    Dim c2fb_temp_14 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_15 As c2fb_Fts5ExprTerm_ Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5ExprTerm Ptr
    Dim local6 As c2fb_Fts5ExprTerm Ptr
    Dim local7 As c2fb_Fts5ExprPhrase Ptr
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Any Ptr
    Dim c2fb_temp_20 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_21 As Any Ptr Ptr
    Dim c2fb_temp_22 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_28 As Any Ptr
    Dim c2fb_temp_29 As ZString Ptr Ptr
    Dim c2fb_temp_30 As ZString Ptr
    Dim c2fb_temp_31 As Long Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As Long Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Long Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As Long Ptr
    Dim c2fb_temp_38 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, 8ULL)
    local2 = CPtr(c2fb_TokenCtx Ptr, arg0)
    local3 = CPtr(c2fb_Fts5ExprPhrase Ptr, local2->pPhrase)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local2->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local2->rc
    End If
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, 32768ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 32768ULL))
        arg3 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3->nTerm > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, &H0001ULL)))) <> 0))))) Then
        ' C automatic storage declaration
        local5 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprTerm))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))) + Cast(c2fb_uint64, arg3))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))))
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local5))))
        local4 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_2
        Else
            c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local4), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, local5)))
            c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(local4->pTerm))
            c2fb_temp_5 = CPtr(ZString Ptr, (CPtr(Byte Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, (CPtr(ZString Ptr, local4))) + Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprTerm))))) + Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_8 = CPtr(Long Ptr, @(local4->nFullTerm))
            c2fb_temp_6 = CPtr(Long Ptr, @(local4->nQueryTerm))
            c2fb_temp_7 = Cast(c2fb_c_int, arg3)
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            c2fb_temp_9 = Cast(c2fb_c_int, c2fb_temp_7)
            (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
            c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
            c2fb_temp_10 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, local4->pTerm), CPtr(Const Any Ptr, arg2), arg3))
            If CPtr(c2fb_Fts5Config Ptr, local2->pConfig)->bTokendata Then
                c2fb_temp_11 = CPtr(Long Ptr, @(local4->nQueryTerm))
                c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, sqlite3SystemStrlen(CPtr(Const ZString Ptr, local4->pTerm))))
                (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
            End If
            c2fb_temp_13 = CPtr(c2fb_Fts5ExprTerm_ Ptr Ptr, @(local4->pSynonym))
            c2fb_temp_14 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local3)))[Cast(c2fb_c_int, (local3->nTerm - Cast(c2fb_c_int, 1ULL)))].pSynonym))
            (*c2fb_temp_13) = CPtr(c2fb_Fts5ExprTerm_ Ptr, c2fb_temp_14)
            c2fb_temp_14 = CPtr(c2fb_Fts5ExprTerm Ptr, (*c2fb_temp_13))
            c2fb_temp_15 = CPtr(c2fb_Fts5ExprTerm_ Ptr Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local3)))[Cast(c2fb_c_int, (local3->nTerm - Cast(c2fb_c_int, 1ULL)))].pSynonym))
            c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, local4)
            (*c2fb_temp_15) = CPtr(c2fb_Fts5ExprTerm_ Ptr, c2fb_temp_16)
            c2fb_temp_16 = CPtr(c2fb_Fts5ExprTerm Ptr, (*c2fb_temp_15))
        End If
    Else
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local3->nTerm Mod local1))) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            ' C automatic storage declaration
            local8 = Cast(c2fb_c_int, (local1 + (IIf(local3, local3->nTerm, Cast(c2fb_c_int, &O0ULL)))))
            c2fb_temp_17 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, local3), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprPhrase_aTerm_tail_ptr(Cast(c2fb_Fts5ExprPhrase Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, 1ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprTerm))))))))))))
            local7 = c2fb_temp_17
            If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_18
            Else
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_19 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local7), Cast(c2fb_c_int, &O0ULL), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprPhrase_aTerm_tail_ptr(Cast(c2fb_Fts5ExprPhrase Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 1ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprTerm))))))))))
                End If
                c2fb_temp_21 = CPtr(Any Ptr Ptr, @(local2->pPhrase))
                c2fb_temp_20 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, local7)
                local3 = c2fb_temp_20
                c2fb_temp_22 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, c2fb_temp_20)
                (*c2fb_temp_21) = CPtr(Any Ptr, c2fb_temp_22)
                c2fb_temp_22 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_21))
                c2fb_temp_23 = CPtr(Long Ptr, @(local7->nTerm))
                c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local8 - local1)))
                (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
                c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
            End If
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_25 = CPtr(Long Ptr, @(local3->nTerm))
            c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
            (*c2fb_temp_25) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_26 + 1)))
            c2fb_temp_27 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local3)))[c2fb_temp_26])))
            local6 = c2fb_temp_27
            c2fb_temp_28 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local6), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprTerm))))
            c2fb_temp_29 = CPtr(ZString Ptr Ptr, @(local6->pTerm))
            c2fb_temp_30 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Strndup(CPtr(c2fb_c_int Ptr, @(local0)), arg2, arg3))
            (*c2fb_temp_29) = c2fb_temp_30
            c2fb_temp_33 = CPtr(Long Ptr, @(local6->nFullTerm))
            c2fb_temp_31 = CPtr(Long Ptr, @(local6->nQueryTerm))
            c2fb_temp_32 = Cast(c2fb_c_int, arg3)
            (*c2fb_temp_31) = Cast(Long, c2fb_temp_32)
            c2fb_temp_32 = Cast(c2fb_c_int, (*c2fb_temp_31))
            c2fb_temp_34 = Cast(c2fb_c_int, c2fb_temp_32)
            (*c2fb_temp_33) = Cast(Long, c2fb_temp_34)
            c2fb_temp_34 = Cast(c2fb_c_int, (*c2fb_temp_33))
            If (-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Config Ptr, local2->pConfig)->bTokendata <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_35 = CPtr(Long Ptr, @(local6->nQueryTerm))
                c2fb_temp_36 = Cast(c2fb_c_int, Cast(c2fb_c_int, sqlite3SystemStrlen(CPtr(Const ZString Ptr, local6->pTerm))))
                (*c2fb_temp_35) = Cast(Long, c2fb_temp_36)
                c2fb_temp_36 = Cast(c2fb_c_int, (*c2fb_temp_35))
            End If
        End If
    End If
    c2fb_temp_37 = CPtr(Long Ptr, @(local2->rc))
    c2fb_temp_38 = Cast(c2fb_c_int, local0)
    (*c2fb_temp_37) = Cast(Long, c2fb_temp_38)
    c2fb_temp_38 = Cast(c2fb_c_int, (*c2fb_temp_37))
    Return local0
End Function

Function sqlite3Fts5ParseTerm CDecl Alias "sqlite3Fts5ParseTerm" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprPhrase Ptr, ByVal arg2 As c2fb_Fts5Token Ptr, ByVal arg3 As c2fb_c_int) As c2fb_Fts5ExprPhrase Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1847
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_TokenCtx
    Dim local2 As c2fb_c_int
    Dim local3 As ZString Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Any Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Any Ptr Ptr
    Dim c2fb_temp_13 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Any Ptr Ptr
    Dim c2fb_temp_17 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_18 As c2fb_u8 Ptr
    Dim c2fb_temp_19 As UByte
    Dim c2fb_temp_20 As Any Ptr Ptr
    Dim c2fb_temp_21 As c2fb_Fts5ExprPhrase Ptr

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_TokenCtx Ptr, @(local1))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_TokenCtx))))
    c2fb_temp_1 = CPtr(Any Ptr Ptr, @(local1.pPhrase))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, arg1)
    (*c2fb_temp_1) = CPtr(Any Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(Any Ptr Ptr, @(local1.pConfig))
    c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, local0)
    (*c2fb_temp_3) = CPtr(Any Ptr, c2fb_temp_4)
    c2fb_temp_4 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_3))
    c2fb_temp_5 = Cast(c2fb_c_int, fts5ParseStringFromToken(CPtr(_c2fb_record_c2fb_Fts5Token Ptr, arg2), CPtr(ZString Ptr Ptr, @(local3))))
    local2 = c2fb_temp_5
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        local4 = Cast(c2fb_c_int, (Cast(c2fb_c_int, &H0001ULL) Or (IIf(arg3, Cast(c2fb_c_int, &H0002ULL), Cast(c2fb_c_int, &O0ULL)))))
        ' C automatic storage declaration
        c2fb_external_sqlite3Fts5Dequote(local3)
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, sqlite3SystemStrlen(CPtr(Const ZString Ptr, local3))))
        local5 = c2fb_temp_6
        c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5Tokenize(CPtr(_c2fb_record_c2fb_Fts5Config Ptr, local0), local4, CPtr(Const ZString Ptr, local3), local5, CPtr(Any Ptr, CPtr(c2fb_TokenCtx Ptr, @(local1))), ProcPtr(fts5ParseTokenize)))
        local2 = c2fb_temp_7
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
    c2fb_temp_9 = 1
    If ((local2 <> 0) = 0) Then
        c2fb_temp_8 = Cast(c2fb_c_int, local1.rc)
        local2 = c2fb_temp_8
        c2fb_temp_9 = (-Cast(c2fb_c_int, (((c2fb_temp_8) <> 0))))
    End If
    If c2fb_temp_9 Then
        c2fb_temp_10 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_11 = Cast(c2fb_c_int, local2)
        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        fts5ExprPhraseFree(CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr, local1.pPhrase)))
        c2fb_temp_12 = CPtr(Any Ptr Ptr, @(local1.pPhrase))
        c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_12) = CPtr(Any Ptr, c2fb_temp_13)
        c2fb_temp_13 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_12))
    Else
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
            If parseGrowPhraseArray(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, arg0)) Then
                fts5ExprPhraseFree(CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr, local1.pPhrase)))
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            c2fb_temp_14 = CPtr(Long Ptr, @(arg0->nPhrase))
            c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
            (*c2fb_temp_14) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
        End If
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5ExprPhrase Ptr, local1.pPhrase) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_16 = CPtr(Any Ptr Ptr, @(local1.pPhrase))
            c2fb_temp_17 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprPhrase_aTerm_tail_ptr(Cast(c2fb_Fts5ExprPhrase Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 1ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprTerm)))))))))))
            (*c2fb_temp_16) = CPtr(Any Ptr, c2fb_temp_17)
            c2fb_temp_17 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_16))
        Else
            If CPtr(c2fb_Fts5ExprPhrase Ptr, local1.pPhrase)->nTerm Then
                c2fb_temp_18 = CPtr(c2fb_u8 Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr, local1.pPhrase))))[Cast(c2fb_c_int, (CPtr(c2fb_Fts5ExprPhrase Ptr, local1.pPhrase)->nTerm - Cast(c2fb_c_int, 1ULL)))].bPrefix))
                c2fb_temp_19 = Cast(UByte, Cast(UByte, arg3))
                (*c2fb_temp_18) = Cast(c2fb_u8, c2fb_temp_19)
                c2fb_temp_19 = Cast(UByte, (*c2fb_temp_18))
            End If
        End If
        ' C unused-parameter annotation
        c2fb_temp_20 = CPtr(Any Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apPhrase))[Cast(c2fb_c_int, (arg0->nPhrase - Cast(c2fb_c_int, 1ULL)))]))
        c2fb_temp_21 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr, local1.pPhrase))
        (*c2fb_temp_20) = CPtr(Any Ptr, c2fb_temp_21)
        c2fb_temp_21 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_20))
    End If
    Return CPtr(c2fb_Fts5ExprPhrase Ptr, local1.pPhrase)
End Function

Function sqlite3Fts5ExprClonePhrase CDecl Alias "sqlite3Fts5ExprClonePhrase" (ByVal arg0 As c2fb_Fts5Expr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5Expr Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 1903
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5ExprPhrase Ptr
    Dim local2 As c2fb_Fts5Expr Ptr
    Dim local3 As c2fb_TokenCtx
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_3 As c2fb_Fts5ExprPhrase_ Ptr Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5ExprNode_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_7 As c2fb_Fts5ExprNearset_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_Fts5ExprNearset Ptr
    Dim local4 As c2fb_Fts5Colset Ptr
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim c2fb_temp_10 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As Any Ptr Ptr
    Dim c2fb_temp_13 As c2fb_Fts5Colset Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_14 As Any Ptr Ptr
    Dim c2fb_temp_15 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_18 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_19 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_u8 Ptr
    Dim c2fb_temp_23 As UByte
    Dim c2fb_temp_24 As c2fb_u8 Ptr
    Dim c2fb_temp_25 As UByte
    Dim c2fb_temp_26 As Any Ptr Ptr
    Dim c2fb_temp_27 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_28 As c2fb_Fts5Index_ Ptr Ptr
    Dim c2fb_temp_29 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_30 As Any Ptr Ptr
    Dim c2fb_temp_31 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_32 As Long Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_Fts5ExprPhrase_ Ptr Ptr
    Dim c2fb_temp_35 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_36 As c2fb_Fts5ExprPhrase Ptr Ptr
    Dim c2fb_temp_37 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_38 As Long Ptr
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_Fts5ExprNode_ Ptr Ptr
    Dim c2fb_temp_41 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_42 As Long Ptr
    Dim c2fb_temp_43 As c2fb_c_int
    Type c2fb_callback_storage_44 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_44 As c2fb_callback_storage_44 Ptr
    Dim c2fb_temp_45 As c2fb_callback_285
    Dim c2fb_temp_46 As Long Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Type c2fb_callback_storage_48 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_48 As c2fb_callback_storage_48 Ptr
    Dim c2fb_temp_49 As c2fb_callback_285
    Dim c2fb_temp_50 As c2fb_Fts5Expr Ptr
    Dim c2fb_temp_51 As c2fb_Fts5Expr Ptr Ptr
    Dim c2fb_temp_52 As c2fb_Fts5Expr Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Type<c2fb_TokenCtx>( CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)), CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)), Cast(c2fb_c_int, &O0ULL) )
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (arg0 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= arg0->nPhrase)))) <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 25ULL))
        local0 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apExprPhrase))[arg1])
        local1 = c2fb_temp_1
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, CPtr(c2fb_Fts5Expr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Expr))))))
        local2 = c2fb_temp_2
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr Ptr, @(local2->apExprPhrase))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprPhrase Ptr))))))
        (*c2fb_temp_3) = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr, c2fb_temp_4)
        c2fb_temp_4 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (*c2fb_temp_3))
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = CPtr(c2fb_Fts5ExprNode_ Ptr Ptr, @(local2->pRoot))
        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprNode_apChild_tail_ptr(Cast(c2fb_Fts5ExprNode Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 1ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprNode Ptr))))))))))))
        (*c2fb_temp_5) = CPtr(c2fb_Fts5ExprNode_ Ptr, c2fb_temp_6)
        c2fb_temp_6 = CPtr(c2fb_Fts5ExprNode Ptr, (*c2fb_temp_5))
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_7 = CPtr(c2fb_Fts5ExprNearset_ Ptr Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot)->pNear))
        c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, CPtr(c2fb_Fts5ExprNearset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprNearset_apPhrase_tail_ptr(Cast(c2fb_Fts5ExprNearset Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 2ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprPhrase Ptr))))))))))))
        (*c2fb_temp_7) = CPtr(c2fb_Fts5ExprNearset_ Ptr, c2fb_temp_8)
        c2fb_temp_8 = CPtr(c2fb_Fts5ExprNearset Ptr, (*c2fb_temp_7))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        local4 = CPtr(c2fb_Fts5Colset Ptr, CPtr(c2fb_Fts5ExprNearset Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local1->pNode)->pNear)->pColset)
        If local4 Then
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_9 = Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local4->nCol + Cast(c2fb_c_int, 2ULL)))) \ Cast(c2fb_c_int, 2ULL)))))))))
            local5 = c2fb_temp_9
            c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, CPtr(c2fb_Fts5Colset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), local5))))
            local6 = c2fb_temp_10
            If local6 Then
                c2fb_temp_11 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, local6), CPtr(Const Any Ptr, local4), Cast(c2fb_size_t, local5)))
            End If
            c2fb_temp_12 = CPtr(Any Ptr Ptr, @(CPtr(c2fb_Fts5ExprNearset Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot)->pNear)->pColset))
            c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, local6)
            (*c2fb_temp_12) = CPtr(Any Ptr, c2fb_temp_13)
            c2fb_temp_13 = CPtr(c2fb_Fts5Colset Ptr, (*c2fb_temp_12))
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If local1->nTerm Then
            ' C automatic storage declaration
            c2fb_temp_14 = CPtr(Any Ptr Ptr, @(local3.pConfig))
            c2fb_temp_15 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig))
            (*c2fb_temp_14) = CPtr(Any Ptr, c2fb_temp_15)
            c2fb_temp_15 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_14))
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local7 = c2fb_temp_16
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 < local1->nTerm)))) <> 0)))))
                local8 = Cast(c2fb_c_int, &O0ULL)
                ' C automatic storage declaration
                c2fb_temp_18 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local1)))[local7])))
                local9 = c2fb_temp_18
                While (-Cast(c2fb_c_int, (((local9 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                    c2fb_temp_20 = Cast(c2fb_c_int, fts5ParseTokenize(CPtr(Any Ptr, CPtr(c2fb_TokenCtx Ptr, @(local3))), local8, CPtr(Const ZString Ptr, local9->pTerm), local9->nFullTerm, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                    local0 = c2fb_temp_20
                    c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H0001ULL))
                    local8 = c2fb_temp_21
                c2fb_flow_3:
                    c2fb_temp_19 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local9->pSynonym))
                    local9 = c2fb_temp_19
                Wend
                c2fb_flow_2:
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_22 = CPtr(c2fb_u8 Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr, local3.pPhrase))))[local7].bPrefix))
                    c2fb_temp_23 = Cast(UByte, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local1)))[local7].bPrefix)
                    (*c2fb_temp_22) = Cast(c2fb_u8, c2fb_temp_23)
                    c2fb_temp_23 = Cast(UByte, (*c2fb_temp_22))
                    c2fb_temp_24 = CPtr(c2fb_u8 Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr, local3.pPhrase))))[local7].bFirst))
                    c2fb_temp_25 = Cast(UByte, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local1)))[local7].bFirst)
                    (*c2fb_temp_24) = Cast(c2fb_u8, c2fb_temp_25)
                    c2fb_temp_25 = Cast(UByte, (*c2fb_temp_24))
                End If
            c2fb_flow_1:
                c2fb_temp_17 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
            Wend
            c2fb_flow_0:
        Else
            c2fb_temp_26 = CPtr(Any Ptr Ptr, @(local3.pPhrase))
            c2fb_temp_27 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprPhrase_aTerm_tail_ptr(Cast(c2fb_Fts5ExprPhrase Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 1ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprTerm)))))))))))
            (*c2fb_temp_26) = CPtr(Any Ptr, c2fb_temp_27)
            c2fb_temp_27 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_26))
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((CPtr(c2fb_Fts5ExprPhrase Ptr, local3.pPhrase)) <> 0))))) Then
        c2fb_temp_28 = CPtr(c2fb_Fts5Index_ Ptr Ptr, @(local2->pIndex))
        c2fb_temp_29 = CPtr(c2fb_Fts5Index Ptr, CPtr(c2fb_Fts5Index Ptr, arg0->pIndex))
        (*c2fb_temp_28) = CPtr(c2fb_Fts5Index_ Ptr, c2fb_temp_29)
        c2fb_temp_29 = CPtr(c2fb_Fts5Index Ptr, (*c2fb_temp_28))
        c2fb_temp_30 = CPtr(Any Ptr Ptr, @(local2->pConfig))
        c2fb_temp_31 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig))
        (*c2fb_temp_30) = CPtr(Any Ptr, c2fb_temp_31)
        c2fb_temp_31 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_30))
        c2fb_temp_32 = CPtr(Long Ptr, @(local2->nPhrase))
        c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_32) = Cast(Long, c2fb_temp_33)
        c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
        c2fb_temp_34 = CPtr(c2fb_Fts5ExprPhrase_ Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, local2->apExprPhrase))[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_35 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr, local3.pPhrase))
        (*c2fb_temp_34) = CPtr(c2fb_Fts5ExprPhrase_ Ptr, c2fb_temp_35)
        c2fb_temp_35 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_34))
        c2fb_temp_36 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(CPtr(c2fb_Fts5ExprNearset Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot)->pNear))))[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_37 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr, local3.pPhrase))
        (*c2fb_temp_36) = c2fb_temp_37
        c2fb_temp_38 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5ExprNearset Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot)->pNear)->nPhrase))
        c2fb_temp_39 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_38) = Cast(Long, c2fb_temp_39)
        c2fb_temp_39 = Cast(c2fb_c_int, (*c2fb_temp_38))
        c2fb_temp_40 = CPtr(c2fb_Fts5ExprNode_ Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr, local3.pPhrase)->pNode))
        c2fb_temp_41 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot))
        (*c2fb_temp_40) = CPtr(c2fb_Fts5ExprNode_ Ptr, c2fb_temp_41)
        c2fb_temp_41 = CPtr(c2fb_Fts5ExprNode Ptr, (*c2fb_temp_40))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->nTerm = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local1)))[Cast(c2fb_c_int, &O0ULL)].pSynonym) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local1)))[Cast(c2fb_c_int, &O0ULL)].bFirst) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_42 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot)->eType))
            c2fb_temp_43 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
            (*c2fb_temp_42) = Cast(Long, c2fb_temp_43)
            c2fb_temp_43 = Cast(c2fb_c_int, (*c2fb_temp_42))
            c2fb_temp_44 = CPtr(c2fb_callback_storage_44 Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot)->xNext))
            c2fb_temp_45 = ProcPtr(fts5ExprNodeNext_TERM)
            (*c2fb_temp_44) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_45)
            c2fb_temp_45 = CPtr(c2fb_callback_285, (*c2fb_temp_44))
        Else
            c2fb_temp_46 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot)->eType))
            c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, 9ULL))
            (*c2fb_temp_46) = Cast(Long, c2fb_temp_47)
            c2fb_temp_47 = Cast(c2fb_c_int, (*c2fb_temp_46))
            c2fb_temp_48 = CPtr(c2fb_callback_storage_48 Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr, local2->pRoot)->xNext))
            c2fb_temp_49 = ProcPtr(fts5ExprNodeNext_STRING)
            (*c2fb_temp_48) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_49)
            c2fb_temp_49 = CPtr(c2fb_callback_285, (*c2fb_temp_48))
        End If
    Else
        sqlite3Fts5ExprFree(CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, local2))
        fts5ExprPhraseFree(CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr, local3.pPhrase)))
        c2fb_temp_50 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local2 = c2fb_temp_50
    End If
    c2fb_temp_51 = CPtr(c2fb_Fts5Expr Ptr Ptr, @((*arg2)))
    c2fb_temp_52 = CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, local2)
    (*c2fb_temp_51) = c2fb_temp_52
    Return local0
End Function

Function sqlite3Fts5ParseColsetInvert CDecl Alias "sqlite3Fts5ParseColsetInvert" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr) As c2fb_Fts5Colset Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2087
    Dim local0 As c2fb_Fts5Colset Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5Colset Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, CPtr(c2fb_Fts5Colset Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL))) + Cast(c2fb_c_int, 2ULL)))) \ Cast(c2fb_c_int, 2ULL))))))))))))
    local0 = c2fb_temp_0
    If local0 Then
        ' C automatic storage declaration
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local2 < local1))))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 >= arg1->nCol)))) <> 0) OrElse ((-Cast(c2fb_c_int, (((c2fb_Fts5Colset_aiCol_tail_ptr(arg1))[local3] <> local2)))) <> 0))))) Then
                c2fb_temp_3 = CPtr(Long Ptr, @(local0->nCol))
                c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
                (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
                c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((c2fb_Fts5Colset_aiCol_tail_ptr(local0))[c2fb_temp_4]))
                c2fb_temp_6 = Cast(c2fb_c_int, local2)
                (*c2fb_temp_5) = c2fb_temp_6
            Else
                c2fb_temp_7 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            End If
        c2fb_flow_1:
            c2fb_temp_2 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg1))
    Return local0
End Function


/'
    C2FB expression-parser helpers recovered after switch and record-lvalue support.
    The procedure comments retain upstream source locations.
'/

Private Sub fts5ExprAssignXNext CDecl Alias "fts5ExprAssignXNext" (ByVal arg0 As c2fb_Fts5ExprNode Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2247
    Dim local0 As c2fb_Fts5ExprNearset Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Type c2fb_callback_storage_2 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_2 As c2fb_callback_storage_2 Ptr
    Dim c2fb_temp_3 As c2fb_callback_285
    Type c2fb_callback_storage_4 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_4 As c2fb_callback_storage_4 Ptr
    Dim c2fb_temp_5 As c2fb_callback_285
    Type c2fb_callback_storage_6 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_6 As c2fb_callback_storage_6 Ptr
    Dim c2fb_temp_7 As c2fb_callback_285
    Type c2fb_callback_storage_8 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_8 As c2fb_callback_storage_8 Ptr
    Dim c2fb_temp_9 As c2fb_callback_285
    Type c2fb_callback_storage_10 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_10 As c2fb_callback_storage_10 Ptr
    Dim c2fb_temp_11 As c2fb_callback_285

    Select Case arg0->eType
        Case Cast(c2fb_c_int, 9ULL)
            local0 = CPtr(c2fb_Fts5ExprNearset Ptr, arg0->pNear)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->nPhrase = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)]->nTerm = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)])))[Cast(c2fb_c_int, &O0ULL)].pSynonym) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local0)))[Cast(c2fb_c_int, &O0ULL)])))[Cast(c2fb_c_int, &O0ULL)].bFirst) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_0 = CPtr(Long Ptr, @(arg0->eType))
                c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
                (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
                c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
                c2fb_temp_2 = CPtr(c2fb_callback_storage_2 Ptr, @(arg0->xNext))
                c2fb_temp_3 = ProcPtr(fts5ExprNodeNext_TERM)
                (*c2fb_temp_2) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_3)
                c2fb_temp_3 = CPtr(c2fb_callback_285, (*c2fb_temp_2))
            Else
                c2fb_temp_4 = CPtr(c2fb_callback_storage_4 Ptr, @(arg0->xNext))
                c2fb_temp_5 = ProcPtr(fts5ExprNodeNext_STRING)
                (*c2fb_temp_4) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_5)
                c2fb_temp_5 = CPtr(c2fb_callback_285, (*c2fb_temp_4))
            End If
            Goto c2fb_flow_0
        Case Cast(c2fb_c_int, 1ULL)
            c2fb_temp_6 = CPtr(c2fb_callback_storage_6 Ptr, @(arg0->xNext))
            c2fb_temp_7 = ProcPtr(fts5ExprNodeNext_OR)
            (*c2fb_temp_6) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_7)
            c2fb_temp_7 = CPtr(c2fb_callback_285, (*c2fb_temp_6))
            Goto c2fb_flow_0
        Case Cast(c2fb_c_int, 2ULL)
            c2fb_temp_8 = CPtr(c2fb_callback_storage_8 Ptr, @(arg0->xNext))
            c2fb_temp_9 = ProcPtr(fts5ExprNodeNext_AND)
            (*c2fb_temp_8) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_9)
            c2fb_temp_9 = CPtr(c2fb_callback_285, (*c2fb_temp_8))
            Goto c2fb_flow_0
        Case Else
            ' C unused-parameter annotation
            c2fb_temp_10 = CPtr(c2fb_callback_storage_10 Ptr, @(arg0->xNext))
            c2fb_temp_11 = ProcPtr(fts5ExprNodeNext_NOT)
            (*c2fb_temp_10) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_11)
            c2fb_temp_11 = CPtr(c2fb_callback_285, (*c2fb_temp_10))
            Goto c2fb_flow_0
    End Select
    c2fb_flow_0:
End Sub

Private Function fts5ParsePhraseToAnd CDecl Alias "fts5ParsePhraseToAnd" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_Fts5ExprNearset Ptr) As c2fb_Fts5ExprNode Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2309
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local4 As c2fb_Fts5ExprPhrase Ptr
    Dim local5 As c2fb_Fts5ExprTerm Ptr
    Dim local6 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Any Ptr Ptr
    Dim c2fb_temp_15 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As ZString Ptr Ptr
    Dim c2fb_temp_19 As ZString Ptr
    Dim c2fb_temp_20 As Long Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Long Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_Fts5ExprNode Ptr Ptr
    Dim c2fb_temp_25 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_26 As c2fb_Fts5ExprNode Ptr

    local0 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)]->nTerm
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprNode_apChild_tail_ptr(Cast(c2fb_Fts5ExprNode Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprNode Ptr)))))))))
    local2 = c2fb_temp_0
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), local2))))
    local3 = c2fb_temp_1
    If local3 Then
        c2fb_temp_2 = CPtr(Long Ptr, @(local3->eType))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        c2fb_temp_4 = CPtr(Long Ptr, @(local3->nChild))
        c2fb_temp_5 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
        c2fb_temp_6 = CPtr(Long Ptr, @(local3->iHeight))
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        fts5ExprAssignXNext(local3)
        c2fb_temp_8 = CPtr(Long Ptr, @(arg0->nPhrase))
        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
        (*c2fb_temp_8) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 - 1)))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_10
        While (-Cast(c2fb_c_int, ((local1 < local0))))
            local4 = CPtr(c2fb_Fts5ExprPhrase Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprPhrase_aTerm_tail_ptr(Cast(c2fb_Fts5ExprPhrase Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 1ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprTerm)))))))))))
            If local4 Then
                If parseGrowPhraseArray(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, arg0)) Then
                    fts5ExprPhraseFree(CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, local4))
                Else
                    local5 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)])))[local1]))
                    local6 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local4)))[Cast(c2fb_c_int, &O0ULL)]))
                    c2fb_temp_12 = CPtr(Long Ptr, @(arg0->nPhrase))
                    c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
                    (*c2fb_temp_12) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                    c2fb_temp_14 = CPtr(Any Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, arg0->apPhrase))[c2fb_temp_13]))
                    c2fb_temp_15 = CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, local4)
                    (*c2fb_temp_14) = CPtr(Any Ptr, c2fb_temp_15)
                    c2fb_temp_15 = CPtr(c2fb_Fts5ExprPhrase Ptr, (*c2fb_temp_14))
                    c2fb_temp_16 = CPtr(Long Ptr, @(local4->nTerm))
                    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
                    c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
                    c2fb_temp_18 = CPtr(ZString Ptr Ptr, @(local6->pTerm))
                    c2fb_temp_19 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Strndup(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(Const ZString Ptr, local5->pTerm), local5->nFullTerm))
                    (*c2fb_temp_18) = c2fb_temp_19
                    c2fb_temp_20 = CPtr(Long Ptr, @(local6->nQueryTerm))
                    c2fb_temp_21 = Cast(c2fb_c_int, local5->nQueryTerm)
                    (*c2fb_temp_20) = Cast(Long, c2fb_temp_21)
                    c2fb_temp_21 = Cast(c2fb_c_int, (*c2fb_temp_20))
                    c2fb_temp_22 = CPtr(Long Ptr, @(local6->nFullTerm))
                    c2fb_temp_23 = Cast(c2fb_c_int, local5->nFullTerm)
                    (*c2fb_temp_22) = Cast(Long, c2fb_temp_23)
                    c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
                    c2fb_temp_24 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, @(CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(local3)))[local1]))
                    c2fb_temp_25 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, sqlite3Fts5ParseNode(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, arg0), Cast(c2fb_c_int, 9ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, CPtr(c2fb_Fts5ExprNearset Ptr, sqlite3Fts5ParseNearset(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, arg0), Cast(c2fb_c_int, &O0ULL), CPtr(_c2fb_record_c2fb_Fts5ExprPhrase Ptr, local4)))))))
                    (*c2fb_temp_24) = c2fb_temp_25
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_11 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
        Wend
        c2fb_flow_0:
        If arg0->rc Then
            sqlite3Fts5ParseNodeFree(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, local3))
            c2fb_temp_26 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local3 = c2fb_temp_26
        Else
            sqlite3Fts5ParseNearsetFree(CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, arg1))
        End If
    End If
    Return local3
End Function

Function sqlite3Fts5ParseNode CDecl Alias "sqlite3Fts5ParseNode" (ByVal arg0 As c2fb_Fts5Parse Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5ExprNode Ptr, ByVal arg3 As c2fb_Fts5ExprNode Ptr, ByVal arg4 As c2fb_Fts5ExprNearset Ptr) As c2fb_Fts5ExprNode Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_expr.c
' c2fb source-line: 2366
    Dim local0 As c2fb_Fts5ExprNode Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_Fts5ExprNearset_ Ptr Ptr
    Dim c2fb_temp_10 As c2fb_Fts5ExprNearset Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_Fts5ExprNode_ Ptr Ptr
    Dim c2fb_temp_14 As c2fb_Fts5ExprNode Ptr
    Type c2fb_callback_storage_15 As Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long
    Dim c2fb_temp_15 As c2fb_callback_storage_15 Ptr
    Dim c2fb_temp_16 As c2fb_callback_285
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local4 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_19 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_20 As c2fb_Fts5ExprNearset Ptr
    Dim c2fb_temp_21 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_22 As c2fb_Fts5ExprNode Ptr
    Dim c2fb_temp_23 As c2fb_Fts5ExprNode Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Return arg3
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Return arg2
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso (arg0->bPhraseToAnd <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg4)))[Cast(c2fb_c_int, &O0ULL)]->nTerm > Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
            c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, fts5ParsePhraseToAnd(arg0, arg4)))
            local0 = c2fb_temp_0
        Else
            If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 3ULL))))) Then
                c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                local1 = c2fb_temp_1
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                    local1 = c2fb_temp_2
                    If (-Cast(c2fb_c_int, ((arg2->eType = arg1)))) Then
                        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, (arg2->nChild - Cast(c2fb_c_int, 1ULL))))))
                        local1 = c2fb_temp_3
                    End If
                    If (-Cast(c2fb_c_int, ((arg3->eType = arg1)))) Then
                        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, (arg3->nChild - Cast(c2fb_c_int, 1ULL))))))
                        local1 = c2fb_temp_4
                    End If
                End If
            End If
            c2fb_temp_5 = Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5ExprNode_apChild_tail_ptr(Cast(c2fb_Fts5ExprNode Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (local1)) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5ExprNode Ptr)))))))))
            local2 = c2fb_temp_5
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, CPtr(c2fb_Fts5ExprNode Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), local2))))
            local0 = c2fb_temp_6
            If local0 Then
                c2fb_temp_7 = CPtr(Long Ptr, @(local0->eType))
                c2fb_temp_8 = Cast(c2fb_c_int, arg1)
                (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
                c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                c2fb_temp_9 = CPtr(c2fb_Fts5ExprNearset_ Ptr Ptr, @(local0->pNear))
                c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, arg4)
                (*c2fb_temp_9) = CPtr(c2fb_Fts5ExprNearset_ Ptr, c2fb_temp_10)
                c2fb_temp_10 = CPtr(c2fb_Fts5ExprNearset Ptr, (*c2fb_temp_9))
                fts5ExprAssignXNext(local0)
                If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 9ULL))))) Then
                    ' C automatic storage declaration
                    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local3 = c2fb_temp_11
                    While (-Cast(c2fb_c_int, ((local3 < arg4->nPhrase))))
                        c2fb_temp_13 = CPtr(c2fb_Fts5ExprNode_ Ptr Ptr, @(CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg4)))[local3]->pNode))
                        c2fb_temp_14 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, local0)
                        (*c2fb_temp_13) = CPtr(c2fb_Fts5ExprNode_ Ptr, c2fb_temp_14)
                        c2fb_temp_14 = CPtr(c2fb_Fts5ExprNode Ptr, (*c2fb_temp_13))
                        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg4)))[local3]->nTerm = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_15 = CPtr(c2fb_callback_storage_15 Ptr, @(local0->xNext))
                            c2fb_temp_16 = CPtr(c2fb_callback_285, 0)
                            (*c2fb_temp_15) = CPtr(Function CDecl(ByVal arg0 As c2fb_Fts5Expr_ Ptr, ByVal arg1 As c2fb_Fts5ExprNode_ Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_i64) As Long, c2fb_temp_16)
                            c2fb_temp_16 = CPtr(c2fb_callback_285, (*c2fb_temp_15))
                            c2fb_temp_17 = CPtr(Long Ptr, @(local0->eType))
                            c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                            (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
                            c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
                        End If
                    c2fb_flow_1:
                        c2fb_temp_12 = local3
                        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
                    Wend
                    c2fb_flow_0:
                    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail <> Cast(c2fb_c_int, &O0ULL))))) Then
                        local4 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(arg4)))[Cast(c2fb_c_int, &O0ULL)]
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg4->nPhrase <> Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4->nTerm > Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4->nTerm > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local4)))[Cast(c2fb_c_int, &O0ULL)].bFirst <> 0)))))) <> 0))))) Then
                            sqlite3Fts5ParseError(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, arg0), StrPtr(!"fts5: %s queries are not supported (detail!=full)"), IIf((-Cast(c2fb_c_int, ((arg4->nPhrase = Cast(c2fb_c_int, 1ULL))))), StrPtr(!"phrase"), StrPtr(!"NEAR")))
                            sqlite3Fts5ParseNodeFree(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, local0))
                            c2fb_temp_19 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            local0 = c2fb_temp_19
                            c2fb_temp_20 = CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                            arg4 = c2fb_temp_20
                            ' C unused-parameter annotation
                        End If
                    End If
                Else
                    ' C unused-parameter annotation
                    fts5ExprAddChildren(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, local0), CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg2))
                    fts5ExprAddChildren(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, local0), CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg3))
                    c2fb_temp_21 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    arg3 = c2fb_temp_21
                    c2fb_temp_22 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, c2fb_temp_21)
                    arg2 = c2fb_temp_22
                    If (-Cast(c2fb_c_int, ((local0->iHeight > Cast(c2fb_c_int, 256ULL))))) Then
                        sqlite3Fts5ParseError(CPtr(_c2fb_record_c2fb_Fts5Parse Ptr, arg0), StrPtr(!"fts5 expression tree is too large (maximum depth %d)"), Cast(c2fb_c_int, 256ULL))
                        sqlite3Fts5ParseNodeFree(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, local0))
                        c2fb_temp_23 = CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                        local0 = c2fb_temp_23
                    End If
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        sqlite3Fts5ParseNodeFree(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg2))
        sqlite3Fts5ParseNodeFree(CPtr(_c2fb_record_c2fb_Fts5ExprNode Ptr, arg3))
        sqlite3Fts5ParseNearsetFree(CPtr(_c2fb_record_c2fb_Fts5ExprNearset Ptr, arg4))
    End If
    Return local0
End Function

#endif
/' end of sqlite3_bulk_fts5_expr.bas '/
