/'
** 2013 Apr 22
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
******************************************************************************
**
** This file contains code for the "fts3tokenize" virtual table module.
** An fts3tokenize virtual table is created as follows:
**
**   CREATE VIRTUAL TABLE <tbl> USING fts3tokenize(
**       <tokenizer-name>, <arg-1>, ...
**   );
**
** The table created has the following schema:
**
**   CREATE TABLE <tbl>(input, token, start, end, position)
**
** When queried, the query must include a WHERE clause of type:
**
**   input = <string>
**
** The virtual table module tokenizes this <string>, using the FTS3 
** tokenizer specified by the arguments to the CREATE VIRTUAL TABLE 
** statement and returns one row for each token in the result. With
** fields set as follows:
**
**   input:   Always set to a copy of <string>
**   token:   A token from the input.
**   start:   Byte offset of the token within the input <string>.
**   end:     Byte offset of the byte immediately following the end of the
**            token within the input string.
**   pos:     Token offset of token within input.
**
'/
/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_bulk_fts3_tokenize_vtab_candidates.bas

    Purpose:

        Preserve C2FB candidates from ext/fts3/fts3_tokenize_vtab.c for review.

    Responsibilities:

        - Show callback translation with the FTS3 tokenizer ABI type mappings.
        - Keep the generated candidate bodies separate from the linked library.

    This file intentionally does NOT contain:

        - The sqlite3_module initializer, which remains in the integrated module.
        - Implementations of the FTS3 error and dequote helper dependencies.
        - Test support.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts3_tokenizer_types.bi"
#include once "sqlite3_vtab_types.bi"

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


Type c2fb_callback_7 As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_8 As Sub CDecl(ByVal arg0 As Const Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr)
Type c2fb_callback_77 As Function CDecl(ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Fts3Tokenizer Ptr Ptr) As c2fb_c_int
Type c2fb_callback_78 As Function CDecl(ByVal arg0 As Fts3Tokenizer Ptr) As c2fb_c_int
Type c2fb_callback_79 As Function CDecl(ByVal arg0 As Fts3Tokenizer Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Fts3TokenizerCursor Ptr Ptr) As c2fb_c_int
Type c2fb_callback_80 As Function CDecl(ByVal arg0 As Fts3TokenizerCursor Ptr) As c2fb_c_int
Type c2fb_callback_81 As Function CDecl(ByVal arg0 As Fts3TokenizerCursor Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int

Private Type c2fb_source_record_23
    iColumn As c2fb_c_int
    op As UByte
    usable As UByte
    iTermOffset As c2fb_c_int
End Type

Private Type c2fb_source_record_24
    iColumn As c2fb_c_int
    desc As UByte
End Type

Private Type c2fb_source_record_25
    argvIndex As c2fb_c_int
    omit As UByte
End Type

Private Type c2fb_source_record_26
    nConstraint As c2fb_c_int
    aConstraint As c2fb_source_record_23 Ptr
    nOrderBy As c2fb_c_int
    aOrderBy As c2fb_source_record_24 Ptr
    aConstraintUsage As c2fb_source_record_25 Ptr
    idxNum As c2fb_c_int
    idxStr As ZString Ptr
    needToFreeIdxStr As c2fb_c_int
    orderByConsumed As c2fb_c_int
    estimatedCost As Double
    estimatedRows As c2fb_int64
    idxFlags As c2fb_c_int
    colUsed As c2fb_uint64
End Type

Private Type c2fb_source_record_27
    pModule As Const SqliteModuleCallbacks Ptr
    nRef As c2fb_c_int
    zErrMsg As ZString Ptr
End Type

Private Type c2fb_source_record_28
    pVtab As c2fb_source_record_27 Ptr
End Type

Private Type c2fb_source_record_32
    count As c2fb_c_int
    chain As Any Ptr
End Type

Private Type c2fb_source_record_33
    keyClass As Byte
    copyKey As Byte
    count As c2fb_c_int
    first As Any Ptr
    htsize As c2fb_c_int
    ht As c2fb_source_record_32 Ptr
End Type

Private Type c2fb_source_record_43
    base As c2fb_source_record_27
    pMod As Const Fts3TokenizerModule Ptr
    pTok As Fts3Tokenizer Ptr
End Type

Private Type c2fb_source_record_44
    base As c2fb_source_record_28
    zInput As ZString Ptr
    pCsr As Fts3TokenizerCursor Ptr
    iRowid As c2fb_c_int
    zToken As Const ZString Ptr
    nToken As c2fb_c_int
    iStart As c2fb_c_int
    iEnd As c2fb_c_int
    iPos As c2fb_c_int
End Type

Declare Function fts3tokQueryTokenizer CDecl Alias "fts3tokQueryTokenizer" (ByVal arg0 As c2fb_source_record_33 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const Fts3TokenizerModule Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3tokDequoteArray CDecl Alias "fts3tokDequoteArray" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As ZString Ptr Ptr Ptr) As c2fb_c_int
Declare Function fts3tokConnectMethod CDecl Alias "fts3tokConnectMethod" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_27 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3tokDisconnectMethod CDecl Alias "fts3tokDisconnectMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Function fts3tokBestIndexMethod CDecl Alias "fts3tokBestIndexMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_source_record_26 Ptr) As c2fb_c_int
Declare Function fts3tokOpenMethod CDecl Alias "fts3tokOpenMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_source_record_28 Ptr Ptr) As c2fb_c_int
Declare Sub fts3tokResetCursor CDecl Alias "fts3tokResetCursor" (ByVal arg0 As c2fb_source_record_44 Ptr)
Declare Function fts3tokCloseMethod CDecl Alias "fts3tokCloseMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
Declare Function fts3tokNextMethod CDecl Alias "fts3tokNextMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
Declare Function fts3tokFilterMethod CDecl Alias "fts3tokFilterMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
Declare Function fts3tokEofMethod CDecl Alias "fts3tokEofMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
Declare Function fts3tokColumnMethod CDecl Alias "fts3tokColumnMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts3tokRowidMethod CDecl Alias "fts3tokRowidMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_malloc CDecl Alias "sqlite3_malloc" (ByVal arg0 As c2fb_c_int) As Any Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As Any Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3_result_int CDecl Alias "sqlite3_result_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_callback_7)
Declare Function c2fb_external_sqlite3_declare_vtab CDecl Alias "sqlite3_declare_vtab" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3HashFind CDecl Alias "sqlite3Fts3HashFind" (ByVal arg0 As Const c2fb_source_record_33 Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int) As Any Ptr
Declare Sub c2fb_external_sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub c2fb_external_sqlite3Fts3Dequote CDecl Alias "sqlite3Fts3Dequote" (ByVal arg0 As ZString Ptr)
Private Function fts3tokQueryTokenizer CDecl Alias "fts3tokQueryTokenizer" (ByVal arg0 As c2fb_source_record_33 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const Fts3TokenizerModule Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 77
    Dim local0 As Fts3TokenizerModule Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Fts3TokenizerModule Ptr
    Dim c2fb_temp_1 As Const Fts3TokenizerModule Ptr Ptr
    Dim c2fb_temp_2 As Const Fts3TokenizerModule Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, c2fb_crt_strlen(arg1))
    c2fb_temp_0 = CPtr(Fts3TokenizerModule Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts3HashFind(CPtr(Const c2fb_source_record_33 Ptr, arg0), CPtr(Const Any Ptr, arg1), Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL))))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        c2fb_external_sqlite3Fts3ErrMsg(arg3, StrPtr(!"unknown tokenizer: %s"), arg1)
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_1 = CPtr(Const Fts3TokenizerModule Ptr Ptr, @((*arg2)))
    c2fb_temp_2 = CPtr(Const Fts3TokenizerModule Ptr, local0)
    (*c2fb_temp_1) = c2fb_temp_2
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3tokDequoteArray CDecl Alias "fts3tokDequoteArray" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As ZString Ptr Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 108
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As ZString Ptr Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local4 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_11 As ZString Ptr Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As Any Ptr
    Dim c2fb_temp_14 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr Ptr, @((*arg2)))
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = c2fb_temp_1
    Else
        ' C automatic storage declaration
        local2 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local1 < arg0))))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, c2fb_crt_strlen(arg1[local1])) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))))))
            local2 = c2fb_temp_4
        c2fb_flow_1:
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_6 = CPtr(ZString Ptr Ptr Ptr, @((*arg2)))
        c2fb_temp_5 = CPtr(ZString Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))) * Cast(c2fb_uint64, arg0))) + Cast(c2fb_uint64, local2))))))
        local3 = c2fb_temp_5
        c2fb_temp_7 = c2fb_temp_5
        (*c2fb_temp_6) = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_8
        Else
            local4 = CPtr(ZString Ptr, CPtr(ZString Ptr Ptr, @(local3[arg0])))
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_9
            While (-Cast(c2fb_c_int, ((local1 < arg0))))
                local5 = Cast(c2fb_c_int, c2fb_crt_strlen(arg1[local1]))
                c2fb_temp_11 = CPtr(ZString Ptr Ptr, @(local3[local1]))
                c2fb_temp_12 = local4
                (*c2fb_temp_11) = c2fb_temp_12
                c2fb_temp_13 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local4), CPtr(Const Any Ptr, arg1[local1]), Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL)))))
                c2fb_external_sqlite3Fts3Dequote(local4)
                c2fb_temp_14 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local4) + (Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))))))
                local4 = c2fb_temp_14
            c2fb_flow_3:
                c2fb_temp_10 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
            Wend
            c2fb_flow_2:
        End If
    End If
    Return local0
End Function
Private Function fts3tokConnectMethod CDecl Alias "fts3tokConnectMethod" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_27 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 158
    Dim local0 As c2fb_source_record_43 Ptr
    Dim local1 As Const Fts3TokenizerModule Ptr
    Dim local2 As Fts3Tokenizer Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As ZString Ptr Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local7 As Const ZString Ptr Ptr
    Dim c2fb_temp_6 As Const ZString Ptr Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_source_record_43 Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As Const Fts3TokenizerModule Ptr Ptr
    Dim c2fb_temp_12 As Const Fts3TokenizerModule Ptr
    Dim c2fb_temp_13 As Fts3Tokenizer Ptr Ptr
    Dim c2fb_temp_14 As Fts3Tokenizer Ptr
    Dim c2fb_temp_15 As c2fb_source_record_27 Ptr Ptr
    Dim c2fb_temp_16 As c2fb_source_record_27 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_declare_vtab(arg0, StrPtr(!"CREATE TABLE x(input, token, start, end, position)")))
    local3 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local3
    End If
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 3ULL))))
    local5 = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, fts3tokDequoteArray(local5, CPtr(Const ZString Ptr Ptr, @(arg3[Cast(c2fb_c_int, 3ULL)])), CPtr(ZString Ptr Ptr Ptr, @(local4))))
    local3 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((local5 < Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_3 = StrPtr(!"simple")
            local6 = c2fb_temp_3
        Else
            c2fb_temp_4 = CPtr(Const ZString Ptr, local4[Cast(c2fb_c_int, &O0ULL)])
            local6 = c2fb_temp_4
        End If
        c2fb_temp_5 = Cast(c2fb_c_int, fts3tokQueryTokenizer(CPtr(c2fb_source_record_33 Ptr, arg1), local6, CPtr(Const Fts3TokenizerModule Ptr Ptr, @(local1)), arg5))
        local3 = c2fb_temp_5
    End If
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        local7 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_6 = CPtr(Const ZString Ptr Ptr, CPtr(ZString Ptr Ptr, @(local4[Cast(c2fb_c_int, 1ULL)])))
            local7 = c2fb_temp_6
        End If
        c2fb_temp_7 = Cast(c2fb_c_int, CPtr(c2fb_callback_77, local1->xCreate)((IIf((-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, 1ULL))))), Cast(c2fb_c_int, (local5 - Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL))), local7, CPtr(Fts3Tokenizer Ptr Ptr, @(local2))))
        local3 = c2fb_temp_7
    End If
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_8 = CPtr(c2fb_source_record_43 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_43)))))
        local0 = c2fb_temp_8
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local3 = c2fb_temp_9
        End If
    End If
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_43))))
        c2fb_temp_11 = CPtr(Const Fts3TokenizerModule Ptr Ptr, @(local0->pMod))
        c2fb_temp_12 = local1
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_temp_13 = CPtr(Fts3Tokenizer Ptr Ptr, @(local0->pTok))
        c2fb_temp_14 = local2
        (*c2fb_temp_13) = c2fb_temp_14
        c2fb_temp_15 = CPtr(c2fb_source_record_27 Ptr Ptr, @((*arg4)))
        c2fb_temp_16 = CPtr(c2fb_source_record_27 Ptr, @(local0->base))
        (*c2fb_temp_15) = c2fb_temp_16
    Else
        If local2 Then
            CPtr(c2fb_callback_78, local1->xDestroy)(local2)
        End If
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
    Return local3
End Function
Private Function fts3tokDisconnectMethod CDecl Alias "fts3tokDisconnectMethod" (ByVal arg0 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 223
    Dim local0 As c2fb_source_record_43 Ptr

    local0 = CPtr(c2fb_source_record_43 Ptr, arg0)
    CPtr(c2fb_callback_78, local0->pMod->xDestroy)(local0->pTok)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3tokBestIndexMethod CDecl Alias "fts3tokBestIndexMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_source_record_26 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 234
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte
    Dim c2fb_temp_8 As Double Ptr
    Dim c2fb_temp_9 As Double
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1->nConstraint))))
        If (-Cast(c2fb_c_int, (((arg1->aConstraint[local0].usable <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->aConstraint[local0].iColumn = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->aConstraint[local0].op) = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_2) = c2fb_temp_3
            c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg1->aConstraintUsage[local0].argvIndex))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_6 = CPtr(UByte Ptr, @(arg1->aConstraintUsage[local0].omit))
            c2fb_temp_7 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(Double Ptr, @(arg1->estimatedCost))
            c2fb_temp_9 = Cast(Double, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_8) = c2fb_temp_9
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_10) = c2fb_temp_11
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3tokOpenMethod CDecl Alias "fts3tokOpenMethod" (ByVal arg0 As c2fb_source_record_27 Ptr, ByVal arg1 As c2fb_source_record_28 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 263
    Dim local0 As c2fb_source_record_44 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_44 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_source_record_28 Ptr Ptr
    Dim c2fb_temp_3 As c2fb_source_record_28 Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_source_record_44 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_44)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_44))))
    c2fb_temp_2 = CPtr(c2fb_source_record_28 Ptr Ptr, @((*arg1)))
    c2fb_temp_3 = CPtr(c2fb_source_record_28 Ptr, local0)
    (*c2fb_temp_2) = c2fb_temp_3
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts3tokResetCursor CDecl Alias "fts3tokResetCursor" (ByVal arg0 As c2fb_source_record_44 Ptr)
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 281
    Dim local0 As c2fb_source_record_43 Ptr
    Dim c2fb_temp_0 As Fts3TokenizerCursor Ptr Ptr
    Dim c2fb_temp_1 As Fts3TokenizerCursor Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr Ptr
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    If arg0->pCsr Then
        local0 = CPtr(c2fb_source_record_43 Ptr, (arg0->base.pVtab))
        CPtr(c2fb_callback_80, local0->pMod->xClose)(arg0->pCsr)
        c2fb_temp_0 = CPtr(Fts3TokenizerCursor Ptr Ptr, @(arg0->pCsr))
        c2fb_temp_1 = CPtr(Fts3TokenizerCursor Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zInput))
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg0->zInput))
    c2fb_temp_3 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(Const ZString Ptr Ptr, @(arg0->zToken))
    c2fb_temp_5 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg0->nToken))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(arg0->iStart))
    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(arg0->iEnd))
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @(arg0->iPos))
    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_12) = c2fb_temp_13
    c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @(arg0->iRowid))
    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_14) = c2fb_temp_15
End Sub
Private Function fts3tokCloseMethod CDecl Alias "fts3tokCloseMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 300
    Dim local0 As c2fb_source_record_44 Ptr

    local0 = CPtr(c2fb_source_record_44 Ptr, arg0)
    fts3tokResetCursor(local0)
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3tokNextMethod CDecl Alias "fts3tokNextMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 311
    Dim local0 As c2fb_source_record_44 Ptr
    Dim local1 As c2fb_source_record_43 Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_44 Ptr, arg0)
    local1 = CPtr(c2fb_source_record_43 Ptr, (arg0->pVtab))
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(local0->iRowid))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    c2fb_temp_2 = Cast(c2fb_c_int, CPtr(c2fb_callback_81, local1->pMod->xNext)(local0->pCsr, CPtr(Const ZString Ptr Ptr, @(local0->zToken)), CPtr(c2fb_c_int Ptr, @(local0->nToken)), CPtr(c2fb_c_int Ptr, @(local0->iStart)), CPtr(c2fb_c_int Ptr, @(local0->iEnd)), CPtr(c2fb_c_int Ptr, @(local0->iPos))))
    local2 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        fts3tokResetCursor(local0)
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 101ULL))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_3
        End If
    End If
    Return local2
End Function
Private Function fts3tokFilterMethod CDecl Alias "fts3tokFilterMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 333
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_44 Ptr
    Dim local2 As c2fb_source_record_43 Ptr
    Dim local3 As Const ZString Ptr
    Dim local4 As c2fb_int64
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As Byte Ptr
    Dim c2fb_temp_5 As Byte
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Fts3Tokenizer Ptr Ptr
    Dim c2fb_temp_8 As Fts3Tokenizer Ptr

    local0 = Cast(c2fb_c_int, 1ULL)
    local1 = CPtr(c2fb_source_record_44 Ptr, arg0)
    local2 = CPtr(c2fb_source_record_43 Ptr, (arg0->pVtab))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    fts3tokResetCursor(local1)
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) Then
        local3 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg4[Cast(c2fb_c_int, &O0ULL)])))
        local4 = c2fb_external_sqlite3_value_bytes(arg4[Cast(c2fb_c_int, &O0ULL)])
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @(local1->zInput))
        c2fb_temp_1 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (local4 + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
        (*c2fb_temp_0) = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local1->zInput = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_2
        Else
            If (-Cast(c2fb_c_int, ((local4 > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->zInput), CPtr(Const Any Ptr, local3), local4))
            End If
            c2fb_temp_4 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1->zInput)[local4]))
            c2fb_temp_5 = Cast(Byte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_6 = Cast(c2fb_c_int, CPtr(c2fb_callback_79, local2->pMod->xOpen)(local2->pTok, CPtr(Const ZString Ptr, local1->zInput), local4, CPtr(Fts3TokenizerCursor Ptr Ptr, @(local1->pCsr))))
            local0 = c2fb_temp_6
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_7 = CPtr(Fts3Tokenizer Ptr Ptr, @(local1->pCsr->pTokenizer))
                c2fb_temp_8 = local2->pTok
                (*c2fb_temp_7) = c2fb_temp_8
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local0
    End If
    Return fts3tokNextMethod(arg0)
End Function
Private Function fts3tokEofMethod CDecl Alias "fts3tokEofMethod" (ByVal arg0 As c2fb_source_record_28 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 370
    Dim local0 As c2fb_source_record_44 Ptr

    local0 = CPtr(c2fb_source_record_44 Ptr, arg0)
    Return ((-Cast(c2fb_c_int, ((local0->zToken = Cast(c2fb_c_int, &O0ULL))))))
End Function
Private Function fts3tokColumnMethod CDecl Alias "fts3tokColumnMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 378
    Dim local0 As c2fb_source_record_44 Ptr

    local0 = CPtr(c2fb_source_record_44 Ptr, arg0)
    Select Case arg2
        Case Cast(c2fb_c_int, &O0ULL)
            c2fb_external_sqlite3_result_text(arg1, CPtr(Const ZString Ptr, local0->zInput), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_callback_7, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
        Case Cast(c2fb_c_int, 1ULL)
            c2fb_external_sqlite3_result_text(arg1, local0->zToken, local0->nToken, (CPtr(c2fb_callback_7, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
        Case Cast(c2fb_c_int, 2ULL)
            c2fb_external_sqlite3_result_int(arg1, local0->iStart)
        Case Cast(c2fb_c_int, 3ULL)
            c2fb_external_sqlite3_result_int(arg1, local0->iEnd)
        Case Else
            ' C unused-parameter annotation
            c2fb_external_sqlite3_result_int(arg1, local0->iPos)
    End Select
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3tokRowidMethod CDecl Alias "fts3tokRowidMethod" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenize_vtab.c
' c2fb source-line: 410
    Dim local0 As c2fb_source_record_44 Ptr
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    local0 = CPtr(c2fb_source_record_44 Ptr, arg0)
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_int64, local0->iRowid))
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped sqlite3Fts3InitTok: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 423: sqlite3Fts3InitTok: assignment parser stopped at byte 8 (static const sqlite3_module fts3tok_module = {      0,      fts3tokConnectMethod,      fts3tokConnectMethod,      fts3to): const sqlite3_module fts3tok_module = {      0,      fts3tokConnectMethod,
#endif

/' end of sqlite3_bulk_fts3_tokenize_vtab_candidates.bas '/
