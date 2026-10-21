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

    File: sqlite3_bulk_fts5_expr_test.bas

    Purpose:

        Provide FTS5 expression diagnostics and test-only SQL functions.

    Responsibilities:

        - Register fts5_expr, fts5_expr_tcl, fts5_isalnum, and fts5_fold.
        - Format expression trees for the upstream FTS5 test scripts.
        - Keep the FTS5 global pointer opaque while passing it to config parsing.

    This file intentionally does NOT contain:

        - FTS5 expression parsing or query iteration.
        - Lemon parser tables or the TCL test adapter.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_types.bi"

' The test functions only pass this shared object as a pointer to FTS5 config
' parsing. Its fields are defined by the main FTS5 unit and are never read here.
Type _c2fb_record_c2fb_Fts5Global
    opaqueGlobalData As Any Ptr
End Type

#include once "sqlite3_fts5_expr_types.bi"
#include once "sqlite3_api_declarations.bi"

#if defined(SQLITE_TEST) OrElse defined(SQLITE_FTS5_DEBUG)
/' ------------------------------------------------------------------------- '/
/' FTS5 expression diagnostics and test callbacks                              '/
/' ------------------------------------------------------------------------- '/

Type c2fb_callback_8 As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_285 As Function CDecl( _
    ByVal arg0 As c2fb_Fts5Expr Ptr, _
    ByVal arg1 As c2fb_Fts5ExprNode Ptr, _
    ByVal arg2 As c2fb_c_int, _
    ByVal arg3 As c2fb_int64 _
) As c2fb_c_int

Declare Function c2fb_crt_memset CDecl Alias "memset" _
    (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, _
     ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_external_sqlite3_vmprintf_ CDecl Alias "sqlite3_vmprintf" _
    (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_value_int__ CDecl Alias "sqlite3_value_int" _
    (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_text__ CDecl Alias "sqlite3_value_text" _
    (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_user_data__ CDecl Alias "sqlite3_user_data" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr) As Any Ptr
Declare Sub c2fb_external_sqlite3_result_error__ CDecl Alias "sqlite3_result_error" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, _
     ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_error_nomem_ CDecl Alias "sqlite3_result_error_nomem" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr)
Declare Sub c2fb_external_sqlite3_result_error_code__ CDecl Alias "sqlite3_result_error_code" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_int__ CDecl Alias "sqlite3_result_int" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_text__ CDecl Alias "sqlite3_result_text" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, _
     ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, _
     ByVal arg3 As c2fb_callback_8)
Declare Function c2fb_external_sqlite3Fts5ConfigParse CDecl Alias "sqlite3Fts5ConfigParse" _
    (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_sqlite3 Ptr, _
     ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, _
     ByVal arg4 As c2fb_Fts5Config Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) _
     As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5ConfigFree CDecl Alias "sqlite3Fts5ConfigFree" _
    (ByVal arg0 As c2fb_Fts5Config Ptr)
Declare Function c2fb_external_sqlite3Fts5ExprNew CDecl Alias "sqlite3Fts5ExprNew" _
    (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, _
     ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, _
     ByVal arg4 As c2fb_Fts5Expr Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) _
     As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5ExprFree CDecl Alias "sqlite3Fts5ExprFree" _
    (ByVal arg0 As c2fb_Fts5Expr Ptr)
Declare Function sqlite3Fts5UnicodeCatParse CDecl Alias "sqlite3Fts5UnicodeCatParse" _
    (ByVal arg0 As Const ZString Ptr, ByVal arg1 As UByte Ptr) As c2fb_c_int
Declare Function sqlite3Fts5UnicodeCategory CDecl Alias "sqlite3Fts5UnicodeCategory" _
    (ByVal arg0 As c2fb_c_uint) As c2fb_c_int
Declare Function sqlite3Fts5UnicodeFold CDecl Alias "sqlite3Fts5UnicodeFold" _
    (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int) As c2fb_c_int

Declare Function fts5ExprTermPrint CDecl Alias "fts5ExprTermPrint" _
    (ByVal arg0 As c2fb_Fts5ExprTerm Ptr) As ZString Ptr
Declare Function fts5PrintfAppend CDecl Alias "fts5PrintfAppend" _
    (ByVal arg0 As ZString Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
Declare Function fts5ExprPrintTcl CDecl Alias "fts5ExprPrintTcl" _
    (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, _
     ByVal arg2 As c2fb_Fts5ExprNode Ptr) As ZString Ptr
Declare Function fts5ExprPrint CDecl Alias "fts5ExprPrint" _
    (ByVal arg0 As c2fb_Fts5Config Ptr, _
     ByVal arg1 As c2fb_Fts5ExprNode Ptr) As ZString Ptr
Declare Sub fts5ExprFunction CDecl Alias "fts5ExprFunction" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, _
     ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub fts5ExprFunctionHr CDecl Alias "fts5ExprFunctionHr" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, _
     ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub fts5ExprFunctionTcl CDecl Alias "fts5ExprFunctionTcl" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, _
     ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub fts5ExprIsAlnum CDecl Alias "fts5ExprIsAlnum" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, _
     ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub fts5ExprFold CDecl Alias "fts5ExprFold" _
    (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, _
     ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)

Private Function fts5ExprTermPrint CDecl Alias "fts5ExprTermPrint" (ByVal arg0 As c2fb_Fts5ExprTerm Ptr) As ZString Ptr
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2528
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_Fts5ExprTerm Ptr
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_1 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_5 As c2fb_Fts5ExprTerm Ptr
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Byte Ptr
    Dim c2fb_temp_8 As Byte
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Byte Ptr
    Dim c2fb_temp_11 As Byte
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As Byte Ptr
    Dim c2fb_temp_15 As Byte
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Byte Ptr
    Dim c2fb_temp_18 As Byte
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Byte Ptr
    Dim c2fb_temp_21 As Byte
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As Byte Ptr
    Dim c2fb_temp_24 As Byte
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Byte Ptr
    Dim c2fb_temp_27 As Byte
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As Byte Ptr
    Dim c2fb_temp_30 As Byte

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, arg0)
    local1 = c2fb_temp_0
    While local1
        c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0->nQueryTerm * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 2ULL)))))))
        local0 = c2fb_temp_2
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local1->pSynonym))
        local1 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc64(local0)))
    local2 = c2fb_temp_3
    If local2 Then
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, arg0)
        local1 = c2fb_temp_4
        While local1
            local4 = local1->pTerm
            local5 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local4)[local1->nQueryTerm])))
            c2fb_temp_6 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
            c2fb_temp_7 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[c2fb_temp_6]))
            c2fb_temp_8 = Cast(Byte, Cast(c2fb_c_int, 34))
            (*c2fb_temp_7) = c2fb_temp_8
            While (-Cast(c2fb_c_int, ((local4 < local5))))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local4))) = Cast(c2fb_c_int, 34))))) Then
                    c2fb_temp_9 = local3
                    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
                    c2fb_temp_10 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[c2fb_temp_9]))
                    c2fb_temp_11 = Cast(Byte, Cast(c2fb_c_int, 34))
                    (*c2fb_temp_10) = c2fb_temp_11
                End If
                c2fb_temp_12 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
                c2fb_temp_14 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[c2fb_temp_12]))
                c2fb_temp_13 = local4
                local4 = (c2fb_temp_13 + 1)
                c2fb_temp_15 = Cast(Byte, (*CPtr(Byte Ptr, c2fb_temp_13)))
                (*c2fb_temp_14) = c2fb_temp_15
            c2fb_flow_5:
            Wend
            c2fb_flow_4:
            c2fb_temp_16 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 + 1)))
            c2fb_temp_17 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[c2fb_temp_16]))
            c2fb_temp_18 = Cast(Byte, Cast(c2fb_c_int, 34))
            (*c2fb_temp_17) = c2fb_temp_18
            If CPtr(c2fb_Fts5ExprTerm Ptr, local1->pSynonym) Then
                c2fb_temp_19 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_19 + 1)))
                c2fb_temp_20 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[c2fb_temp_19]))
                c2fb_temp_21 = Cast(Byte, Cast(c2fb_c_int, 124))
                (*c2fb_temp_20) = c2fb_temp_21
            End If
        c2fb_flow_3:
            c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5ExprTerm Ptr, CPtr(c2fb_Fts5ExprTerm Ptr, local1->pSynonym))
            local1 = c2fb_temp_5
        Wend
        c2fb_flow_2:
        If arg0->bPrefix Then
            c2fb_temp_22 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_22 + 1)))
            c2fb_temp_23 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[c2fb_temp_22]))
            c2fb_temp_24 = Cast(Byte, Cast(c2fb_c_int, 32))
            (*c2fb_temp_23) = c2fb_temp_24
            c2fb_temp_25 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_25 + 1)))
            c2fb_temp_26 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[c2fb_temp_25]))
            c2fb_temp_27 = Cast(Byte, Cast(c2fb_c_int, 42))
            (*c2fb_temp_26) = c2fb_temp_27
        End If
        c2fb_temp_28 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
        c2fb_temp_29 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[c2fb_temp_28]))
        c2fb_temp_30 = Cast(Byte, Cast(c2fb_c_int, 0))
        (*c2fb_temp_29) = c2fb_temp_30
    End If
    Return local2
End Function
Private Function fts5PrintfAppend CDecl Alias "fts5PrintfAppend" (ByVal arg0 As ZString Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2561
    Dim local0 As ZString Ptr
    Dim local1 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    Cva_Start(local1, arg1)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf_(arg1, local1))
    local0 = c2fb_temp_0
    Cva_End(local1)
    If (-Cast(c2fb_c_int, (((arg0 <> 0) AndAlso (local0 <> 0))))) Then
        local2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s%s"), arg0, local0))
        sqlite3_free(CPtr(Any Ptr, local0))
        c2fb_temp_1 = local2
        local0 = c2fb_temp_1
    End If
    sqlite3_free(CPtr(Any Ptr, arg0))
    Return local0
End Function
Private Function fts5ExprPrintTcl CDecl Alias "fts5ExprPrintTcl" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_Fts5ExprNode Ptr) As ZString Ptr
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2582
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_Fts5ExprNearset Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim local4 As c2fb_c_int Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local6 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local7 As c2fb_Fts5ExprTerm Ptr
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As ZString Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_18 As Const ZString Ptr
    Dim c2fb_temp_19 As Const ZString Ptr
    Dim c2fb_temp_20 As Const ZString Ptr
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim local10 As ZString Ptr
    Dim c2fb_temp_24 As ZString Ptr
    Dim c2fb_temp_25 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2->eType = Cast(c2fb_c_int, 9ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2->eType = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
        local1 = CPtr(c2fb_Fts5ExprNearset Ptr, arg2->pNear)
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"%s "), arg1))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        If CPtr(c2fb_Fts5Colset Ptr, local1->pColset) Then
            local4 = (c2fb_Fts5Colset_aiCol_tail_ptr(CPtr(c2fb_Fts5Colset Ptr, local1->pColset)))
            local5 = CPtr(c2fb_Fts5Colset Ptr, local1->pColset)->nCol
            If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, 1ULL))))) Then
                c2fb_temp_1 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"-col %d "), local4[Cast(c2fb_c_int, &O0ULL)]))
                local0 = c2fb_temp_1
            Else
                c2fb_temp_2 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"-col {%d"), local4[Cast(c2fb_c_int, &O0ULL)]))
                local0 = c2fb_temp_2
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local2 = c2fb_temp_3
                While (-Cast(c2fb_c_int, ((local2 < CPtr(c2fb_Fts5Colset Ptr, local1->pColset)->nCol))))
                    c2fb_temp_5 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!" %d"), local4[local2]))
                    local0 = c2fb_temp_5
                c2fb_flow_1:
                    c2fb_temp_4 = local2
                    local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
                Wend
                c2fb_flow_0:
                c2fb_temp_6 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"} ")))
                local0 = c2fb_temp_6
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        End If
        If (-Cast(c2fb_c_int, ((local1->nPhrase > Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_7 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"-near %d "), local1->nNear))
            local0 = c2fb_temp_7
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        End If
        c2fb_temp_8 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"--")))
        local0 = c2fb_temp_8
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_9
        While (-Cast(c2fb_c_int, ((local2 < local1->nPhrase))))
            local6 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local1)))[local2]
            c2fb_temp_11 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!" {")))
            local0 = c2fb_temp_11
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_12
            While (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 < local6->nTerm)))) <> 0)))))
                local7 = CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local6)))[local3]))
                c2fb_temp_14 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"%s%.*s"), IIf((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))), StrPtr(!""), StrPtr(!" ")), local7->nQueryTerm, local7->pTerm))
                local0 = c2fb_temp_14
                If CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local6)))[local3].bPrefix Then
                    c2fb_temp_15 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"*")))
                    local0 = c2fb_temp_15
                End If
            c2fb_flow_5:
                c2fb_temp_13 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
            Wend
            c2fb_flow_4:
            If local0 Then
                c2fb_temp_16 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"}")))
                local0 = c2fb_temp_16
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        c2fb_flow_3:
            c2fb_temp_10 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
        Wend
        c2fb_flow_2:
    Else
        If (-Cast(c2fb_c_int, ((arg2->eType = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_17 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"{}")))
            local0 = c2fb_temp_17
        Else
            local8 = Cast(c2fb_c_int, &O0ULL)
            ' C automatic storage declaration
            Select Case arg2->eType
                Case Cast(c2fb_c_int, 2ULL)
                    c2fb_temp_18 = StrPtr(!"AND")
                    local8 = c2fb_temp_18
                Case Cast(c2fb_c_int, 3ULL)
                    c2fb_temp_19 = StrPtr(!"NOT")
                    local8 = c2fb_temp_19
                Case Else
                    ' C unused-parameter annotation
                    c2fb_temp_20 = StrPtr(!"OR")
                    local8 = c2fb_temp_20
            End Select
            c2fb_flow_6:
            c2fb_temp_21 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s"), local8))
            local0 = c2fb_temp_21
            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local9 = c2fb_temp_22
            While (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local9 < arg2->nChild)))) <> 0)))))
                local10 = CPtr(ZString Ptr, fts5ExprPrintTcl(arg0, arg1, CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg2)))[local9]))
                If (-Cast(c2fb_c_int, (local10 = 0))) Then
                    sqlite3_free(CPtr(Any Ptr, local0))
                    c2fb_temp_24 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local0 = c2fb_temp_24
                Else
                    c2fb_temp_25 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!" [%z]"), local10))
                    local0 = c2fb_temp_25
                End If
            c2fb_flow_8:
                c2fb_temp_23 = local9
                local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_23 + 1)))
            Wend
            c2fb_flow_7:
        End If
    End If
    Return local0
End Function
Private Function fts5ExprPrint CDecl Alias "fts5ExprPrint" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5ExprNode Ptr) As ZString Ptr
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2665
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_Fts5ExprNearset Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local6 As c2fb_Fts5ExprPhrase Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local7 As ZString Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As Const ZString Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local10 As ZString Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_19 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, &O0ULL))))) Then
        Return CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"\034\034")))
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 9ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
            local1 = CPtr(c2fb_Fts5ExprNearset Ptr, arg1->pNear)
            ' C automatic storage declaration
            ' C automatic storage declaration
            If CPtr(c2fb_Fts5Colset Ptr, local1->pColset) Then
                ' C automatic storage declaration
                local5 = CPtr(c2fb_Fts5Colset Ptr, local1->pColset)
                If (-Cast(c2fb_c_int, ((local5->nCol > Cast(c2fb_c_int, 1ULL))))) Then
                    c2fb_temp_0 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"{")))
                    local0 = c2fb_temp_0
                End If
                c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local4 = c2fb_temp_1
                While (-Cast(c2fb_c_int, ((local4 < local5->nCol))))
                    c2fb_temp_3 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"%s%s"), arg0->azCol[(c2fb_Fts5Colset_aiCol_tail_ptr(local5))[local4]], IIf((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, (local5->nCol - Cast(c2fb_c_int, 1ULL))))))), StrPtr(!""), StrPtr(!" "))))
                    local0 = c2fb_temp_3
                c2fb_flow_1:
                    c2fb_temp_2 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                Wend
                c2fb_flow_0:
                If local0 Then
                    c2fb_temp_4 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"%s : "), IIf((-Cast(c2fb_c_int, ((local5->nCol > Cast(c2fb_c_int, 1ULL))))), StrPtr(!"}"), StrPtr(!""))))
                    local0 = c2fb_temp_4
                End If
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
            End If
            If (-Cast(c2fb_c_int, ((local1->nPhrase > Cast(c2fb_c_int, 1ULL))))) Then
                c2fb_temp_5 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"NEAR(")))
                local0 = c2fb_temp_5
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
            End If
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((local2 < local1->nPhrase))))
                local6 = CPtr(c2fb_Fts5ExprPhrase Ptr Ptr, (c2fb_Fts5ExprNearset_apPhrase_tail_ptr(local1)))[local2]
                If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_8 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!" ")))
                    local0 = c2fb_temp_8
                    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                        Return Cast(c2fb_c_int, &O0ULL)
                    End If
                End If
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_9
                While (-Cast(c2fb_c_int, ((local3 < local6->nTerm))))
                    local7 = CPtr(ZString Ptr, fts5ExprTermPrint(CPtr(c2fb_Fts5ExprTerm Ptr, @(CPtr(c2fb_Fts5ExprTerm Ptr, (c2fb_Fts5ExprPhrase_aTerm_tail_ptr(local6)))[local3]))))
                    If local7 Then
                        c2fb_temp_11 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"%s%s"), IIf((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))), StrPtr(!""), StrPtr(!" + ")), local7))
                        local0 = c2fb_temp_11
                        sqlite3_free(CPtr(Any Ptr, local7))
                    End If
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        sqlite3_free(CPtr(Any Ptr, local0))
                        Return Cast(c2fb_c_int, &O0ULL)
                    End If
                c2fb_flow_5:
                    c2fb_temp_10 = local3
                    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
                Wend
                c2fb_flow_4:
            c2fb_flow_3:
                c2fb_temp_7 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            Wend
            c2fb_flow_2:
            If (-Cast(c2fb_c_int, ((local1->nPhrase > Cast(c2fb_c_int, 1ULL))))) Then
                c2fb_temp_12 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!", %d)"), local1->nNear))
                local0 = c2fb_temp_12
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
            End If
        Else
            local8 = Cast(c2fb_c_int, &O0ULL)
            ' C automatic storage declaration
            Select Case arg1->eType
                Case Cast(c2fb_c_int, 2ULL)
                    c2fb_temp_13 = StrPtr(!" AND ")
                    local8 = c2fb_temp_13
                Case Cast(c2fb_c_int, 3ULL)
                    c2fb_temp_14 = StrPtr(!" NOT ")
                    local8 = c2fb_temp_14
                Case Else
                    ' C unused-parameter annotation
                    c2fb_temp_15 = StrPtr(!" OR ")
                    local8 = c2fb_temp_15
            End Select
            c2fb_flow_6:
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local9 = c2fb_temp_16
            While (-Cast(c2fb_c_int, ((local9 < arg1->nChild))))
                local10 = CPtr(ZString Ptr, fts5ExprPrint(arg0, CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[local9]))
                If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) Then
                    sqlite3_free(CPtr(Any Ptr, local0))
                    c2fb_temp_18 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local0 = c2fb_temp_18
                Else
                    local11 = CPtr(c2fb_Fts5ExprNode Ptr Ptr, (c2fb_Fts5ExprNode_apChild_tail_ptr(arg1)))[local9]->eType
                    local12 = ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local11 <> Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local11 <> Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local11 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))))
                    c2fb_temp_19 = CPtr(ZString Ptr, fts5PrintfAppend(local0, StrPtr(!"%s%s%z%s"), (IIf((-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, &O0ULL))))), StrPtr(!""), local8)), (IIf(local12, StrPtr(!"("), StrPtr(!""))), local10, (IIf(local12, StrPtr(!")"), StrPtr(!"")))))
                    local0 = c2fb_temp_19
                End If
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_7
                End If
            c2fb_flow_8:
                c2fb_temp_17 = local9
                local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
            Wend
            c2fb_flow_7:
        End If
    End If
    Return local0
End Function
Private Sub fts5ExprFunction CDecl Alias "fts5ExprFunction" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2756
    Dim local0 As c2fb_Fts5Global Ptr
    Dim local1 As c2fb_sqlite3 Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As c2fb_Fts5Expr Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As Const ZString Ptr Ptr
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_Fts5Config Ptr
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Const ZString Ptr Ptr
    Dim c2fb_temp_5 As Const ZString Ptr Ptr
    Dim c2fb_temp_6 As Const ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As Const ZString Ptr Ptr
    Dim c2fb_temp_10 As Const ZString Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local12 As Const ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Const ZString Ptr Ptr
    Dim c2fb_temp_15 As Const ZString Ptr
    Dim c2fb_temp_16 As Const ZString Ptr
    Dim c2fb_temp_17 As Const ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim local13 As ZString Ptr
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Global Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_user_data__(arg0)))
    local1 = CPtr(c2fb_sqlite3 Ptr, sqlite3_context_db_handle(CPtr(Any Ptr, arg0)))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local8 = StrPtr(!"nearset")
    ' C automatic storage declaration
    local10 = Cast(c2fb_c_int, &O0ULL)
    local11 = Cast(c2fb_c_int, 1ULL)
    If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"wrong number of arguments to function %s"), IIf(arg3, StrPtr(!"fts5_expr_tcl"), StrPtr(!"fts5_expr"))))
        local3 = c2fb_temp_0
        c2fb_external_sqlite3_result_error__(arg0, CPtr(Const ZString Ptr, local3), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        sqlite3_free(CPtr(Any Ptr, local3))
        Return
    End If
    If (-Cast(c2fb_c_int, (((arg3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        c2fb_temp_1 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text__(arg2[Cast(c2fb_c_int, 1ULL)])))
        local8 = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
        local11 = c2fb_temp_2
    End If
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 3ULL) + (Cast(c2fb_c_int, (arg1 - local11))))))
    local9 = c2fb_temp_3
    c2fb_temp_4 = CPtr(Const ZString Ptr Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))) * Cast(c2fb_uint64, local9))))))
    local7 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_error_nomem_(arg0)
        Return
    End If
    c2fb_temp_5 = CPtr(Const ZString Ptr Ptr, @(local7[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_6 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(Const ZString Ptr Ptr, @(local7[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_8 = StrPtr(!"main")
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(Const ZString Ptr Ptr, @(local7[Cast(c2fb_c_int, 2ULL)]))
    c2fb_temp_10 = StrPtr(!"tbl")
    (*c2fb_temp_9) = c2fb_temp_10
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
    local6 = c2fb_temp_11
    While (-Cast(c2fb_c_int, ((local11 < arg1))))
        local12 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text__(arg2[local11])))
        c2fb_temp_13 = local6
        local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
        c2fb_temp_14 = CPtr(Const ZString Ptr Ptr, @(local7[c2fb_temp_13]))
        c2fb_temp_15 = (IIf(local12, local12, StrPtr(!"")))
        (*c2fb_temp_14) = c2fb_temp_15
    c2fb_flow_1:
        c2fb_temp_12 = local11
        local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_16 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text__(arg2[Cast(c2fb_c_int, &O0ULL)])))
    local2 = c2fb_temp_16
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_17 = StrPtr(!"")
        local2 = c2fb_temp_17
    End If
    c2fb_temp_18 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ConfigParse(CPtr(_c2fb_record_c2fb_Fts5Global Ptr, local0), local1, local9, local7, CPtr(_c2fb_record_c2fb_Fts5Config Ptr Ptr, CPtr(c2fb_Fts5Config Ptr Ptr, @(local10))), CPtr(ZString Ptr Ptr, @(local3))))
    local5 = c2fb_temp_18
    If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_19 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ExprNew(CPtr(_c2fb_record_c2fb_Fts5Config Ptr, local10), Cast(c2fb_c_int, &O0ULL), local10->nCol, local2, CPtr(_c2fb_record_c2fb_Fts5Expr Ptr Ptr, CPtr(c2fb_Fts5Expr Ptr Ptr, @(local4))), CPtr(ZString Ptr Ptr, @(local3))))
        local5 = c2fb_temp_19
    End If
    If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((CPtr(Any Ptr, CPtr(c2fb_callback_285, CPtr(c2fb_Fts5ExprNode Ptr, local4->pRoot)->xNext)) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_20 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"")))
            local13 = c2fb_temp_20
        Else
            If arg3 Then
                c2fb_temp_21 = CPtr(ZString Ptr, fts5ExprPrintTcl(local10, local8, CPtr(c2fb_Fts5ExprNode Ptr, local4->pRoot)))
                local13 = c2fb_temp_21
            Else
                c2fb_temp_22 = CPtr(ZString Ptr, fts5ExprPrint(local10, CPtr(c2fb_Fts5ExprNode Ptr, local4->pRoot)))
                local13 = c2fb_temp_22
            End If
        End If
        If (-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local5 = c2fb_temp_23
        Else
            c2fb_external_sqlite3_result_text__(arg0, CPtr(Const ZString Ptr, local13), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
            sqlite3_free(CPtr(Any Ptr, local13))
        End If
    End If
    If (-Cast(c2fb_c_int, ((local5 <> Cast(c2fb_c_int, &O0ULL))))) Then
        If local3 Then
            c2fb_external_sqlite3_result_error__(arg0, CPtr(Const ZString Ptr, local3), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            sqlite3_free(CPtr(Any Ptr, local3))
        Else
            c2fb_external_sqlite3_result_error_code__(arg0, local5)
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local7))
    c2fb_external_sqlite3Fts5ConfigFree(CPtr(_c2fb_record_c2fb_Fts5Config Ptr, local10))
    c2fb_external_sqlite3Fts5ExprFree(CPtr(_c2fb_record_c2fb_Fts5Expr Ptr, local4))
End Sub
Private Sub fts5ExprFunctionHr CDecl Alias "fts5ExprFunctionHr" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2841
    fts5ExprFunction(arg0, arg1, arg2, Cast(c2fb_c_int, &O0ULL))
End Sub
Private Sub fts5ExprFunctionTcl CDecl Alias "fts5ExprFunctionTcl" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2848
    fts5ExprFunction(arg0, arg1, arg2, Cast(c2fb_c_int, 1ULL))
End Sub
Private Sub fts5ExprIsAlnum CDecl Alias "fts5ExprIsAlnum" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2861
    Dim local0 As c2fb_c_int
    Dim local1(0 To 31) As UByte
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic array storage
    If (-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_external_sqlite3_result_error__(arg0, StrPtr(!"wrong number of arguments to function fts5_isalnum"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Return
    End If
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(UByte Ptr, (@local1(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, (32ULL * SizeOf(UByte)))))
    sqlite3Fts5UnicodeCatParse(StrPtr(!"L*"), CPtr(UByte Ptr, (@local1(0))))
    sqlite3Fts5UnicodeCatParse(StrPtr(!"N*"), CPtr(UByte Ptr, (@local1(0))))
    sqlite3Fts5UnicodeCatParse(StrPtr(!"Co"), CPtr(UByte Ptr, (@local1(0))))
    c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int__(arg2[Cast(c2fb_c_int, &O0ULL)]))
    local0 = c2fb_temp_1
    c2fb_external_sqlite3_result_int__(arg0, local1(sqlite3Fts5UnicodeCategory(Cast(c2fb_c_uint, local0))))
End Sub
Private Sub fts5ExprFold CDecl Alias "fts5ExprFold" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: ext/fts5/fts5_expr.c
' c2fb source-line: 2882
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
        c2fb_external_sqlite3_result_error__(arg0, StrPtr(!"wrong number of arguments to function fts5_fold"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    Else
        ' C automatic storage declaration
        local1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int__(arg2[Cast(c2fb_c_int, &O0ULL)]))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int__(arg2[Cast(c2fb_c_int, 1ULL)]))
            local1 = c2fb_temp_1
        End If
        c2fb_external_sqlite3_result_int__(arg0, sqlite3Fts5UnicodeFold(local0, local1))
    End If
End Sub

#endif

/' ------------------------------------------------------------------------- '/
/' Register FTS5 expression diagnostics for test and debug builds             '/
/' ------------------------------------------------------------------------- '/

Function sqlite3Fts5ExprInit CDecl Alias "sqlite3Fts5ExprInit" ( _
    ByVal pGlobal As c2fb_Fts5Global Ptr, _
    ByVal db As c2fb_sqlite3 Ptr _
) As c2fb_c_int
    Dim rc As c2fb_c_int

    rc = SQLITE_OK
#if defined(SQLITE_TEST) OrElse defined(SQLITE_FTS5_DEBUG)
    rc = sqlite3_create_function( _
        CPtr(Any Ptr, db), StrPtr(!"fts5_expr"), -1, SQLITE_UTF8, _
        CPtr(Any Ptr, pGlobal), CPtr(Any Ptr, ProcPtr(fts5ExprFunctionHr)), _
        CPtr(Any Ptr, 0), CPtr(Any Ptr, 0))
    If rc = SQLITE_OK Then
        rc = sqlite3_create_function( _
            CPtr(Any Ptr, db), StrPtr(!"fts5_expr_tcl"), -1, SQLITE_UTF8, _
            CPtr(Any Ptr, pGlobal), CPtr(Any Ptr, ProcPtr(fts5ExprFunctionTcl)), _
            CPtr(Any Ptr, 0), CPtr(Any Ptr, 0))
    End If
    If rc = SQLITE_OK Then
        rc = sqlite3_create_function( _
            CPtr(Any Ptr, db), StrPtr(!"fts5_isalnum"), -1, SQLITE_UTF8, _
            CPtr(Any Ptr, pGlobal), CPtr(Any Ptr, ProcPtr(fts5ExprIsAlnum)), _
            CPtr(Any Ptr, 0), CPtr(Any Ptr, 0))
    End If
    If rc = SQLITE_OK Then
        rc = sqlite3_create_function( _
            CPtr(Any Ptr, db), StrPtr(!"fts5_fold"), -1, SQLITE_UTF8, _
            CPtr(Any Ptr, pGlobal), CPtr(Any Ptr, ProcPtr(fts5ExprFold)), _
            CPtr(Any Ptr, 0), CPtr(Any Ptr, 0))
    End If
#endif
    Return rc
End Function
#endif

/' end of sqlite3_bulk_fts5_expr_test.bas '/
