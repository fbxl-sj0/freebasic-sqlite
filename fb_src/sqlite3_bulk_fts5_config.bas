/'
** 2014 Jun 09
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

    File: sqlite3_bulk_fts5_config.bas

    Purpose:

        Parse FTS5 virtual-table arguments and load persisted configuration.

    Responsibilities:

        - Parse tokenizer, prefix, detail, locale, and content options.
        - Build and free FTS5 configuration records.
        - Format configuration errors for the virtual-table layer.

    This file intentionally does NOT contain:

        - FTS5 virtual-table cursor or query-planning logic.
        - Tokenizer algorithms or the upstream Tcl test adapter.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_config_types.bi"

#ifndef FTS5_MAX_PREFIX_INDEXES
#define FTS5_MAX_PREFIX_INDEXES 31
#define FTS5_CONTENT_NORMAL 0
#define FTS5_CONTENT_NONE 1
#define FTS5_CONTENT_EXTERNAL 2
#define FTS5_CONTENT_UNINDEXED 3
#define FTS5_DETAIL_FULL 0
#define FTS5_DETAIL_NONE 1
#define FTS5_DETAIL_COLUMNS 2
#endif

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

#ifdef SQLITE_DEBUG
Private Sub fts5ConfigAssert(ByVal bCondition As c2fb_c_int, ByVal zExpression As Const ZString Ptr)
    If bCondition = 0 Then sqlite3DebugAssert(zExpression)
End Sub
#endif

Type c2fb_callback_7 As Function CDecl(ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As Const c2fb_sqlite3_api_routines Ptr) As c2fb_c_int
Type c2fb_callback_9 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Type c2fb_callback_73 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_92 As Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
Type c2fb_callback_93 As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_callback_73) As c2fb_c_int
Type c2fb_callback_94 As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_73) As c2fb_c_int

Declare Function fts5_iswhitespace CDecl Alias "fts5_iswhitespace" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function fts5_isopenquote CDecl Alias "fts5_isopenquote" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function fts5ConfigSkipWhitespace CDecl Alias "fts5ConfigSkipWhitespace" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
Declare Function fts5ConfigSkipBareword CDecl Alias "fts5ConfigSkipBareword" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
Declare Function fts5_isdigit CDecl Alias "fts5_isdigit" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function fts5ConfigSkipLiteral CDecl Alias "fts5ConfigSkipLiteral" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
Declare Function fts5Dequote CDecl Alias "fts5Dequote" (ByVal arg0 As ZString Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5Dequote CDecl Alias "sqlite3Fts5Dequote" (ByVal arg0 As ZString Ptr)
Declare Function fts5ConfigSetEnum CDecl Alias "fts5ConfigSetEnum" (ByVal arg0 As Const c2fb_Fts5Enum Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ConfigParseSpecial CDecl Alias "fts5ConfigParseSpecial" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5ConfigGobbleWord CDecl Alias "fts5ConfigGobbleWord" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As Const ZString Ptr
Declare Function fts5ConfigParseColumn CDecl Alias "fts5ConfigParseColumn" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As ZString Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5ConfigMakeExprlist CDecl Alias "fts5ConfigMakeExprlist" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ConfigParse CDecl Alias "sqlite3Fts5ConfigParse" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_Fts5Config Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5ConfigFree CDecl Alias "sqlite3Fts5ConfigFree" (ByVal arg0 As c2fb_Fts5Config Ptr)
Declare Function sqlite3Fts5ConfigDeclareVtab CDecl Alias "sqlite3Fts5ConfigDeclareVtab" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
Declare Function sqlite3Fts5Tokenize CDecl Alias "sqlite3Fts5Tokenize" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_73) As c2fb_c_int
Declare Function fts5ConfigSkipArgs CDecl Alias "fts5ConfigSkipArgs" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
Declare Function sqlite3Fts5ConfigParseRank CDecl Alias "sqlite3Fts5ConfigParseRank" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ConfigSetValue CDecl Alias "sqlite3Fts5ConfigSetValue" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts5ConfigLoad CDecl Alias "sqlite3Fts5ConfigLoad" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub sqlite3Fts5ConfigErrmsg CDecl Alias "sqlite3Fts5ConfigErrmsg" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3_prepare_v2 CDecl Alias "sqlite3_prepare_v2" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_text CDecl Alias "sqlite3_column_text" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_column_value CDecl Alias "sqlite3_column_value" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_sqlite3_value Ptr
Declare Function c2fb_external_sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_int CDecl Alias "sqlite3_value_int" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_numeric_type CDecl Alias "sqlite3_value_numeric_type" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_declare_vtab CDecl Alias "sqlite3_declare_vtab" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_strnicmp CDecl Alias "sqlite3_strnicmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5BufferAppendPrintf CDecl Alias "sqlite3Fts5BufferAppendPrintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As ZString Ptr, ...)
Declare Function c2fb_external_sqlite3Fts5Mprintf CDecl Alias "sqlite3Fts5Mprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3Fts5MallocZero CDecl Alias "sqlite3Fts5MallocZero" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function c2fb_external_sqlite3Fts5Strndup CDecl Alias "sqlite3Fts5Strndup" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As ZString Ptr
Declare Function c2fb_external_sqlite3Fts5IsBareword CDecl Alias "sqlite3Fts5IsBareword" (ByVal arg0 As Byte) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5LoadTokenizer CDecl Alias "sqlite3Fts5LoadTokenizer" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
Private Function fts5_iswhitespace CDecl Alias "fts5_iswhitespace" (ByVal arg0 As Byte) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 30
    Return ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 32))))))
End Function
Private Function fts5_isopenquote CDecl Alias "fts5_isopenquote" (ByVal arg0 As Byte) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 34
    Return ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 34))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 39))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 91))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 96))))) <> 0))))))
End Function
Private Function fts5ConfigSkipWhitespace CDecl Alias "fts5ConfigSkipWhitespace" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 43
    Dim local0 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr

    local0 = arg0
    If local0 Then
        While fts5_iswhitespace((*CPtr(Const Byte Ptr, local0)))
            c2fb_temp_0 = local0
            local0 = (c2fb_temp_0 + 1)
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
    Return local0
End Function
Private Function fts5ConfigSkipBareword CDecl Alias "fts5ConfigSkipBareword" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 56
    Dim local0 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr

    local0 = arg0
    While c2fb_external_sqlite3Fts5IsBareword((*CPtr(Const Byte Ptr, local0)))
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 = arg0)))) Then
        c2fb_temp_1 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_1
    End If
    Return local0
End Function
Private Function fts5_isdigit CDecl Alias "fts5_isdigit" (ByVal arg0 As Byte) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 63
    Return ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) <= Cast(c2fb_c_int, 57))))) <> 0))))))
End Function
Private Function fts5ConfigSkipLiteral CDecl Alias "fts5ConfigSkipLiteral" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 69
    Dim local0 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As Const ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim c2fb_temp_10 As Const ZString Ptr
    Dim c2fb_temp_11 As Const ZString Ptr
    Dim c2fb_temp_12 As Const ZString Ptr
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As Const ZString Ptr
    Dim c2fb_temp_16 As Const ZString Ptr

    local0 = arg0
    Select Case (*CPtr(Const Byte Ptr, local0))
        Case Cast(c2fb_c_int, 110), Cast(c2fb_c_int, 78)
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_strnicmp(StrPtr(!"null"), local0, Cast(c2fb_c_int, 4ULL)) = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_0 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, 4ULL)])))
                local0 = c2fb_temp_0
            Else
                c2fb_temp_1 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_1
            End If
        Case Cast(c2fb_c_int, 120), Cast(c2fb_c_int, 88)
            c2fb_temp_2 = local0
            local0 = (c2fb_temp_2 + 1)
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 39))))) Then
                c2fb_temp_3 = local0
                local0 = (c2fb_temp_3 + 1)
                While (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) >= Cast(c2fb_c_int, 97))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <= Cast(c2fb_c_int, 102))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) >= Cast(c2fb_c_int, 65))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <= Cast(c2fb_c_int, 70))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <= Cast(c2fb_c_int, 57))))) <> 0)))))) <> 0)))))
                    c2fb_temp_4 = local0
                    local0 = (c2fb_temp_4 + 1)
                c2fb_flow_2:
                Wend
                c2fb_flow_1:
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 39))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)) = (Cast(c2fb_int64, (Cast(c2fb_int64, ((CPtr(Byte Ptr, CPtr(Const Byte Ptr, local0)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, arg0))))) Mod Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))))))) <> 0))))) Then
                    c2fb_temp_5 = local0
                    local0 = (c2fb_temp_5 + 1)
                Else
                    c2fb_temp_6 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local0 = c2fb_temp_6
                End If
            Else
                c2fb_temp_7 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_7
            End If
        Case Cast(c2fb_c_int, 39)
            c2fb_temp_8 = local0
            local0 = (c2fb_temp_8 + 1)
            While local0
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 39))))) Then
                    c2fb_temp_9 = local0
                    local0 = (c2fb_temp_9 + 1)
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <> Cast(c2fb_c_int, 39))))) Then
                        Goto c2fb_flow_3
                    End If
                End If
                c2fb_temp_10 = local0
                local0 = (c2fb_temp_10 + 1)
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_11 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local0 = c2fb_temp_11
                End If
            c2fb_flow_4:
            Wend
            c2fb_flow_3:
        Case Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 43))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 45))))) <> 0))))) Then
                c2fb_temp_12 = local0
                local0 = (c2fb_temp_12 + 1)
            End If
            While fts5_isdigit((*CPtr(Const Byte Ptr, local0)))
                c2fb_temp_13 = local0
                local0 = (c2fb_temp_13 + 1)
            c2fb_flow_6:
            Wend
            c2fb_flow_5:
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 46))))) <> 0) AndAlso (fts5_isdigit(CPtr(Const Byte Ptr, local0)[Cast(c2fb_c_int, 1ULL)]) <> 0))))) Then
                c2fb_temp_14 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, local0) + Cast(c2fb_c_int, 2ULL)))
                local0 = c2fb_temp_14
                While fts5_isdigit((*CPtr(Const Byte Ptr, local0)))
                    c2fb_temp_15 = local0
                    local0 = (c2fb_temp_15 + 1)
                c2fb_flow_8:
                Wend
                c2fb_flow_7:
            End If
            If (-Cast(c2fb_c_int, ((local0 = arg0)))) Then
                c2fb_temp_16 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_16
            End If
    End Select
    c2fb_flow_0:
    Return local0
End Function
Private Function fts5Dequote CDecl Alias "fts5Dequote" (ByVal arg0 As ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 145
    Dim local0 As Byte
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As Byte
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Byte Ptr
    Dim c2fb_temp_6 As Byte
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Byte Ptr
    Dim c2fb_temp_10 As Byte
    Dim c2fb_temp_11 As Byte Ptr
    Dim c2fb_temp_12 As Byte

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, 1ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(Byte, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)])
    local0 = c2fb_temp_0
#ifdef SQLITE_DEBUG
    fts5ConfigAssert(fts5_isopenquote(local0) <> 0, _
        StrPtr(!"q is an opening quote"))
#endif
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 91))))) Then
        c2fb_temp_1 = Cast(Byte, Cast(c2fb_c_int, 93))
        local0 = c2fb_temp_1
    End If
    While CPtr(Byte Ptr, arg0)[local1]
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[local1]) = Cast(c2fb_c_int, local0))))) Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))]) <> Cast(c2fb_c_int, local0))))) Then
                c2fb_temp_2 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                Goto c2fb_flow_0
            Else
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 2ULL))))
                local1 = c2fb_temp_3
                c2fb_temp_4 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
                c2fb_temp_5 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[c2fb_temp_4]))
                c2fb_temp_6 = Cast(Byte, local0)
                (*c2fb_temp_5) = c2fb_temp_6
            End If
        Else
            c2fb_temp_7 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            c2fb_temp_9 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[c2fb_temp_7]))
            c2fb_temp_8 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
            c2fb_temp_10 = Cast(Byte, CPtr(Byte Ptr, arg0)[c2fb_temp_8])
            (*c2fb_temp_9) = c2fb_temp_10
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_11 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[local2]))
    c2fb_temp_12 = Cast(Byte, Cast(c2fb_c_int, 0))
    (*c2fb_temp_11) = c2fb_temp_12
    Return local1
End Function
Sub sqlite3Fts5Dequote CDecl Alias "sqlite3Fts5Dequote" (ByVal arg0 As ZString Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 190
    Dim local0 As Byte
    Dim c2fb_temp_0 As Byte

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(Byte, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)])
    local0 = c2fb_temp_0
#ifdef SQLITE_DEBUG
    fts5ConfigAssert(fts5_iswhitespace(local0) = 0, _
        StrPtr(!"0==fts5_iswhitespace(z[0])"))
#endif
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 91))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 39))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 34))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 96))))) <> 0))))) Then
        fts5Dequote(arg0)
    End If
End Sub
Private Function fts5ConfigSetEnum CDecl Alias "fts5ConfigSetEnum" (ByVal arg0 As Const c2fb_Fts5Enum Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 207
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, c2fb_crt_strlen(arg1))
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While CPtr(Const c2fb_Fts5Enum Ptr, arg0)[local1].zName
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_strnicmp(CPtr(Const c2fb_Fts5Enum Ptr, arg0)[local1].zName, arg1, local0) = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, 1ULL)
            End If
            c2fb_temp_2 = Cast(c2fb_c_int, CPtr(Const c2fb_Fts5Enum Ptr, arg0)[local1].eVal)
            local2 = c2fb_temp_2
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_4 = Cast(c2fb_c_int, local2)
    (*c2fb_temp_3) = c2fb_temp_4
    Return IIf((-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))
End Function
Private Function fts5ConfigParseSpecial CDecl Alias "fts5ConfigParseSpecial" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
    Dim rc As c2fb_c_int
    Dim nCmd As c2fb_c_int
    Dim p As Const ZString Ptr
    Dim p2 As Const ZString Ptr
    Dim pSpace As Byte Ptr
    Dim nPre As c2fb_c_int
    Dim bFirst As c2fb_c_int
    Dim nAllocArg As c2fb_size_t
    Dim nArg As c2fb_c_int
    Dim nBytes As c2fb_size_t
    Dim azArg As ZString Ptr Ptr
    Dim aDetail(0 To 3) As c2fb_Fts5Enum
    Dim i As c2fb_c_int

    rc = 0
    nCmd = Cast(c2fb_c_int, c2fb_crt_strlen(arg1))

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"prefix"), arg1, nCmd) = 0 Then
        If arg0->aPrefix = 0 Then
            nBytes = SizeOf(c2fb_c_int) * FTS5_MAX_PREFIX_INDEXES
            arg0->aPrefix = CPtr(Long Ptr, _
                c2fb_external_sqlite3Fts5MallocZero(@rc, Cast(c2fb_int64, nBytes)))
            If rc <> 0 Then Return rc
        End If

        p = arg2
        bFirst = 1
        While Cast(c2fb_c_int, 1)
            While p[0] = Asc(" ")
                p += 1
            Wend
            If bFirst = 0 AndAlso p[0] = Asc(",") Then
                p += 1
                While p[0] = Asc(" ")
                    p += 1
                Wend
            ElseIf p[0] = 0 Then
                Exit While
            End If

            If p[0] < Asc("0") OrElse p[0] > Asc("9") Then
                *arg3 = c2fb_external_sqlite3_mprintf(_
                    StrPtr(!"malformed prefix=... directive"))
                rc = 1
                Exit While
            End If
            If arg0->nPrefix = FTS5_MAX_PREFIX_INDEXES Then
                *arg3 = c2fb_external_sqlite3_mprintf(_
                    StrPtr(!"too many prefix indexes (max %d)"), _
                    FTS5_MAX_PREFIX_INDEXES)
                rc = 1
                Exit While
            End If

            nPre = 0
            While p[0] >= Asc("0") AndAlso p[0] <= Asc("9") AndAlso nPre < 1000
                nPre = nPre * 10 + (p[0] - Asc("0"))
                p += 1
            Wend
            If nPre <= 0 OrElse nPre >= 1000 Then
                *arg3 = c2fb_external_sqlite3_mprintf(_
                    StrPtr(!"prefix length out of range (max 999)"))
                rc = 1
                Exit While
            End If

            arg0->aPrefix[arg0->nPrefix] = nPre
            arg0->nPrefix += 1
            bFirst = 0
        Wend
#ifdef SQLITE_DEBUG
        fts5ConfigAssert(arg0->nPrefix <= FTS5_MAX_PREFIX_INDEXES, _
            StrPtr(!"pConfig->nPrefix<=FTS5_MAX_PREFIX_INDEXES"))
#endif
        Return rc
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"tokenize"), arg1, nCmd) = 0 Then
        nAllocArg = c2fb_crt_strlen(arg2) + 1
        nBytes = Cast(c2fb_size_t, (SizeOf(ZString Ptr) + 2) * nAllocArg)
        azArg = CPtr(ZString Ptr Ptr, _
            c2fb_external_sqlite3Fts5MallocZero(@rc, Cast(c2fb_int64, nBytes)))
        If azArg Then
            pSpace = CPtr(Byte Ptr, @azArg[nAllocArg])
            If arg0->t.azArg Then
                *arg3 = c2fb_external_sqlite3_mprintf(_
                    StrPtr(!"multiple tokenize=... directives"))
                rc = 1
            Else
                p = arg2
                nArg = 0
                While p AndAlso p[0] <> 0
                    p2 = fts5ConfigSkipWhitespace(p)
                    If p2[0] = Asc("'") Then
                        p = fts5ConfigSkipLiteral(p2)
                    Else
                        p = fts5ConfigSkipBareword(p2)
                    End If
                    If p Then
                        nBytes = Cast(c2fb_size_t, p - p2)
                        c2fb_crt_memcpy(CPtr(Any Ptr, pSpace), _
                            CPtr(Const Any Ptr, p2), nBytes)
                        azArg[nArg] = CPtr(ZString Ptr, pSpace)
                        sqlite3Fts5Dequote(azArg[nArg])
                        pSpace += nBytes + 1
                        nArg += 1
                        p = fts5ConfigSkipWhitespace(p)
                    End If
                Wend
                If p = 0 Then
                    *arg3 = c2fb_external_sqlite3_mprintf(_
                        StrPtr(!"parse error in tokenize directive"))
                    rc = 1
                Else
                    arg0->t.azArg = CPtr(Const ZString Ptr Ptr, azArg)
                    arg0->t.nArg = nArg
                    azArg = 0
                End If
            End If
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, azArg))
        Return rc
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"content"), arg1, nCmd) = 0 Then
        If arg0->eContent <> FTS5_CONTENT_NORMAL Then
            *arg3 = c2fb_external_sqlite3_mprintf(_
                StrPtr(!"multiple content=... directives"))
            rc = 1
        ElseIf arg2[0] <> 0 Then
            arg0->eContent = FTS5_CONTENT_EXTERNAL
            arg0->zContent = c2fb_external_sqlite3Fts5Mprintf(@rc, _
                StrPtr(!"%Q.%Q"), arg0->zDb, arg2)
        Else
            arg0->eContent = FTS5_CONTENT_NONE
        End If
        Return rc
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"contentless_delete"), arg1, nCmd) = 0 Then
        If (arg2[0] <> Asc("0") AndAlso arg2[0] <> Asc("1")) OrElse arg2[1] <> 0 Then
            *arg3 = c2fb_external_sqlite3_mprintf(_
                StrPtr(!"malformed contentless_delete=... directive"))
            Return 1
        End If
        arg0->bContentlessDelete = (arg2[0] = Asc("1"))
        Return 0
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"contentless_unindexed"), arg1, nCmd) = 0 Then
        If (arg2[0] <> Asc("0") AndAlso arg2[0] <> Asc("1")) OrElse arg2[1] <> 0 Then
            *arg3 = c2fb_external_sqlite3_mprintf(_
                StrPtr(!"malformed contentless_delete=... directive"))
            Return 1
        End If
        arg0->bContentlessUnindexed = (arg2[0] = Asc("1"))
        Return 0
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"content_rowid"), arg1, nCmd) = 0 Then
        If arg0->zContentRowid Then
            *arg3 = c2fb_external_sqlite3_mprintf(_
                StrPtr(!"multiple content_rowid=... directives"))
            Return 1
        End If
        arg0->zContentRowid = c2fb_external_sqlite3Fts5Strndup(@rc, arg2, -1)
        Return rc
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"columnsize"), arg1, nCmd) = 0 Then
        If (arg2[0] <> Asc("0") AndAlso arg2[0] <> Asc("1")) OrElse arg2[1] <> 0 Then
            *arg3 = c2fb_external_sqlite3_mprintf(_
                StrPtr(!"malformed columnsize=... directive"))
            Return 1
        End If
        arg0->bColumnsize = (arg2[0] = Asc("1"))
        Return 0
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"locale"), arg1, nCmd) = 0 Then
        If (arg2[0] <> Asc("0") AndAlso arg2[0] <> Asc("1")) OrElse arg2[1] <> 0 Then
            *arg3 = c2fb_external_sqlite3_mprintf(_
                StrPtr(!"malformed locale=... directive"))
            Return 1
        End If
        arg0->bLocale = (arg2[0] = Asc("1"))
        Return 0
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"detail"), arg1, nCmd) = 0 Then
        aDetail(0).zName = StrPtr(!"none")
        aDetail(0).eVal = FTS5_DETAIL_NONE
        aDetail(1).zName = StrPtr(!"full")
        aDetail(1).eVal = FTS5_DETAIL_FULL
        aDetail(2).zName = StrPtr(!"columns")
        aDetail(2).eVal = FTS5_DETAIL_COLUMNS
        aDetail(3).zName = 0
        aDetail(3).eVal = 0
        rc = fts5ConfigSetEnum(@aDetail(0), arg2, @arg0->eDetail)
        If rc <> 0 Then
            *arg3 = c2fb_external_sqlite3_mprintf(_
                StrPtr(!"malformed detail=... directive"))
        End If
        Return rc
    End If

    If c2fb_external_sqlite3_strnicmp(StrPtr(!"tokendata"), arg1, nCmd) = 0 Then
        If (arg2[0] <> Asc("0") AndAlso arg2[0] <> Asc("1")) OrElse arg2[1] <> 0 Then
            *arg3 = c2fb_external_sqlite3_mprintf(_
                StrPtr(!"malformed tokendata=... directive"))
            Return 1
        End If
        arg0->bTokendata = (arg2[0] = Asc("1"))
        Return 0
    End If

    *arg3 = c2fb_external_sqlite3_mprintf(_
        StrPtr("unrecognized option: ""%.*s"""), nCmd, arg1)
    Return 1
End Function

Private Function fts5ConfigGobbleWord CDecl Alias "fts5ConfigGobbleWord" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As c2fb_c_int Ptr) As Const ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 447
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_int64
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Any Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Const ZString Ptr
    Dim c2fb_temp_11 As Byte Ptr
    Dim c2fb_temp_12 As Byte
    Dim c2fb_temp_13 As ZString Ptr Ptr
    Dim c2fb_temp_14 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = c2fb_crt_strlen(arg1)
    local2 = CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (local1 + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))
#ifdef SQLITE_DEBUG
    fts5ConfigAssert(*arg0 = 0, StrPtr(!"*pRc==SQLITE_OK"))
#endif
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @((*arg2)))
    c2fb_temp_3 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg0)))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        (*c2fb_temp_4) = c2fb_temp_5
    Else
        c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local2), CPtr(Const Any Ptr, arg1), Cast(c2fb_size_t, (Cast(c2fb_int64, (local1 + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))))
        If fts5_isopenquote(CPtr(Byte Ptr, local2)[Cast(c2fb_c_int, &O0ULL)]) Then
            local3 = fts5Dequote(local2)
            c2fb_temp_7 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg1)[local3])))
            local0 = c2fb_temp_7
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_8) = c2fb_temp_9
        Else
            c2fb_temp_10 = CPtr(Const ZString Ptr, fts5ConfigSkipBareword(arg1))
            local0 = c2fb_temp_10
            If local0 Then
                c2fb_temp_11 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local2)[(CPtr(Byte Ptr, CPtr(Const Byte Ptr, local0)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, arg1)))]))
                c2fb_temp_12 = Cast(Byte, Cast(c2fb_c_int, 0))
                (*c2fb_temp_11) = c2fb_temp_12
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    Else
        c2fb_temp_13 = CPtr(ZString Ptr Ptr, @((*arg2)))
        c2fb_temp_14 = local2
        (*c2fb_temp_13) = c2fb_temp_14
    End If
    Return local0
End Function
Private Function fts5ConfigParseColumn CDecl Alias "fts5ConfigParseColumn" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As ZString Ptr, ByVal arg2 As ZString Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 487
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_u8 Ptr
    Dim c2fb_temp_4 As UByte
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, arg1), StrPtr(!"rank")))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, arg1), StrPtr(!"rowid")))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg3)))
        c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"reserved fts5 column name: %s"), arg1))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_2
    Else
        If arg2 Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, arg2), StrPtr(!"unindexed")))))) Then
                c2fb_temp_3 = CPtr(c2fb_u8 Ptr, @(arg0->abUnindexed[arg0->nCol]))
                c2fb_temp_4 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_3) = Cast(c2fb_u8, c2fb_temp_4)
                c2fb_temp_4 = Cast(UByte, (*c2fb_temp_3))
                c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg4)))
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_5) = c2fb_temp_6
            Else
                c2fb_temp_7 = CPtr(ZString Ptr Ptr, @((*arg3)))
                c2fb_temp_8 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"unrecognized column option: %s"), arg2))
                (*c2fb_temp_7) = c2fb_temp_8
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_9
            End If
        End If
    End If
    c2fb_temp_10 = CPtr(Long Ptr, @(arg0->nCol))
    c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
    (*c2fb_temp_10) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
    c2fb_temp_12 = CPtr(ZString Ptr Ptr, @(arg0->azCol[c2fb_temp_11]))
    c2fb_temp_13 = arg1
    (*c2fb_temp_12) = c2fb_temp_13
    Return local0
End Function
Private Function fts5ConfigMakeExprlist CDecl Alias "fts5ConfigMakeExprlist" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 517
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Buffer
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), CPtr(ZString Ptr, StrPtr(!"T.%Q")), arg0->zContentRowid)
    If (-Cast(c2fb_c_int, ((arg0->eContent <> Cast(c2fb_c_int, 1ULL))))) Then
#ifdef SQLITE_DEBUG
        fts5ConfigAssert(arg0->eContent = FTS5_CONTENT_EXTERNAL OrElse _
            arg0->eContent = FTS5_CONTENT_NORMAL OrElse _
            arg0->eContent = FTS5_CONTENT_UNINDEXED, _
            StrPtr(!"valid eContent for expression list"))
#endif
        ' C unused-parameter annotation
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
            If (-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, 2ULL))))) Then
                c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), CPtr(ZString Ptr, StrPtr(!", T.%Q")), arg0->azCol[local0])
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (arg0->abUnindexed[local0] <> 0))))) Then
                    c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), CPtr(ZString Ptr, StrPtr(!", T.c%d")), local0)
                Else
                    c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), CPtr(ZString Ptr, StrPtr(!", NULL")))
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eContent = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg0->bLocale <> 0))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->abUnindexed[local0]) = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), CPtr(ZString Ptr, StrPtr(!", T.l%d")), local0)
            Else
                c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), CPtr(ZString Ptr, StrPtr(!", NULL")))
            End If
        c2fb_flow_3:
            c2fb_temp_3 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_2:
    End If
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    fts5ConfigAssert(arg0->zContentExprlist = 0, _
        StrPtr(!"p->zContentExprlist==0"))
#endif
    c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(arg0->zContentExprlist))
    c2fb_temp_5 = CPtr(ZString Ptr, local2.p)
    (*c2fb_temp_4) = c2fb_temp_5
    Return local1
End Function
Function sqlite3Fts5ConfigParse CDecl Alias "sqlite3Fts5ConfigParse" (ByVal arg0 As c2fb_Fts5Global Ptr, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_Fts5Config Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 565
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Config Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Global_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Global Ptr
    Dim c2fb_temp_6 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As ZString Ptr Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Long Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As ZString Ptr Ptr
    Dim c2fb_temp_24 As ZString Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim local5 As Const ZString Ptr
    Dim local6 As Const ZString Ptr
    Dim local7 As ZString Ptr
    Dim local8 As ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_28 As Const ZString Ptr
    Dim c2fb_temp_29 As Const ZString Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As Const ZString Ptr
    Dim c2fb_temp_32 As Const ZString Ptr
    Dim c2fb_temp_33 As Const ZString Ptr
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_34 As Const ZString Ptr
    Dim c2fb_temp_35 As Const ZString Ptr
    Dim c2fb_temp_36 As ZString Ptr Ptr
    Dim c2fb_temp_37 As ZString Ptr
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As ZString Ptr
    Dim c2fb_temp_42 As ZString Ptr Ptr
    Dim c2fb_temp_43 As ZString Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As ZString Ptr Ptr
    Dim c2fb_temp_46 As ZString Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As ZString Ptr Ptr
    Dim c2fb_temp_49 As ZString Ptr
    Dim c2fb_temp_50 As c2fb_c_int
    Dim local12 As Const ZString Ptr
    Dim c2fb_temp_51 As Const ZString Ptr
    Dim c2fb_temp_52 As Long Ptr
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As Const ZString Ptr
    Dim c2fb_temp_55 As Const ZString Ptr
    Dim c2fb_temp_56 As ZString Ptr Ptr
    Dim c2fb_temp_57 As ZString Ptr
    Dim c2fb_temp_58 As ZString Ptr Ptr
    Dim c2fb_temp_59 As ZString Ptr
    Dim c2fb_temp_60 As c2fb_c_int
    Dim c2fb_temp_61 As c2fb_Fts5Config Ptr Ptr
    Dim c2fb_temp_62 As c2fb_Fts5Config Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_1 = CPtr(c2fb_Fts5Config Ptr Ptr, @((*arg4)))
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Config Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_Fts5Config))))))
    local1 = c2fb_temp_0
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, c2fb_temp_0)
    (*c2fb_temp_1) = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Config))))
    c2fb_temp_4 = CPtr(c2fb_Fts5Global_ Ptr Ptr, @(local1->pGlobal))
    c2fb_temp_5 = arg0
    (*c2fb_temp_4) = CPtr(c2fb_Fts5Global_ Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(c2fb_Fts5Global Ptr, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(local1->db))
    c2fb_temp_7 = arg1
    (*c2fb_temp_6) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_7)
    c2fb_temp_7 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(Long Ptr, @(local1->iCookie))
    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
    c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
    c2fb_temp_10 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, arg2) * (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(ZString Ptr))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(UByte)))))))))
    local3 = c2fb_temp_10
    c2fb_temp_11 = CPtr(ZString Ptr Ptr Ptr, @(local1->azCol))
    c2fb_temp_12 = CPtr(ZString Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), local3)))
    (*c2fb_temp_11) = c2fb_temp_12
    c2fb_temp_13 = CPtr(c2fb_u8 Ptr Ptr, @(local1->abUnindexed))
    c2fb_temp_14 = IIf(local1->azCol, CPtr(UByte Ptr, CPtr(ZString Ptr Ptr, @(local1->azCol[arg2]))), CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))
    (*c2fb_temp_13) = CPtr(c2fb_u8 Ptr, c2fb_temp_14)
    c2fb_temp_14 = CPtr(UByte Ptr, (*c2fb_temp_13))
    c2fb_temp_15 = CPtr(ZString Ptr Ptr, @(local1->zDb))
    c2fb_temp_16 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Strndup(CPtr(c2fb_c_int Ptr, @(local0)), arg3[Cast(c2fb_c_int, 1ULL)], Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
    (*c2fb_temp_15) = c2fb_temp_16
    c2fb_temp_17 = CPtr(ZString Ptr Ptr, @(local1->zName))
    c2fb_temp_18 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Strndup(CPtr(c2fb_c_int Ptr, @(local0)), arg3[Cast(c2fb_c_int, 2ULL)], Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
    (*c2fb_temp_17) = c2fb_temp_18
    c2fb_temp_19 = CPtr(Long Ptr, @(local1->bColumnsize))
    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
    c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
    c2fb_temp_21 = CPtr(Long Ptr, @(local1->eDetail))
    c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_21) = Cast(Long, c2fb_temp_22)
    c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
#ifdef SQLITE_DEBUG
    local1->bPrefixIndex = 1
#endif
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(CPtr(Const ZString Ptr, local1->zName), StrPtr(!"rank")) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_23 = CPtr(ZString Ptr Ptr, @((*arg5)))
        c2fb_temp_24 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"reserved fts5 table name: %s"), local1->zName))
        (*c2fb_temp_23) = c2fb_temp_24
        c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_25
    End If
#ifdef SQLITE_DEBUG
    fts5ConfigAssert((local1->abUnindexed <> 0 AndAlso local1->azCol <> 0) _
        OrElse local0 <> 0, _
        StrPtr(!"(pRet->abUnindexed && pRet->azCol) || rc!=SQLITE_OK"))
#endif
    ' C unused-parameter annotation
    c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
    local2 = c2fb_temp_26
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < arg2)))) <> 0)))))
        local5 = arg3[local2]
        ' C automatic storage declaration
        local7 = Cast(c2fb_c_int, &O0ULL)
        local8 = Cast(c2fb_c_int, &O0ULL)
        local9 = Cast(c2fb_c_int, &O0ULL)
        local10 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_28 = CPtr(Const ZString Ptr, fts5ConfigGobbleWord(CPtr(c2fb_c_int Ptr, @(local0)), local5, CPtr(ZString Ptr Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local10))))
        local6 = c2fb_temp_28
        c2fb_temp_29 = CPtr(Const ZString Ptr, fts5ConfigSkipWhitespace(local6))
        local6 = c2fb_temp_29
        If (-Cast(c2fb_c_int, (((local6 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local6))) = Cast(c2fb_c_int, 61))))) <> 0))))) Then
            c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local9 = c2fb_temp_30
#ifdef SQLITE_DEBUG
            fts5ConfigAssert(local7 <> 0, StrPtr(!"zOne!=0"))
#endif
            ' C unused-parameter annotation
            c2fb_temp_31 = local6
            local6 = (c2fb_temp_31 + 1)
            If local10 Then
                c2fb_temp_32 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local6 = c2fb_temp_32
            End If
        End If
        c2fb_temp_33 = CPtr(Const ZString Ptr, fts5ConfigSkipWhitespace(local6))
        local6 = c2fb_temp_33
        If (-Cast(c2fb_c_int, (((local6 <> 0) AndAlso (CPtr(Const Byte Ptr, local6)[Cast(c2fb_c_int, &O0ULL)] <> 0))))) Then
            ' C automatic storage declaration
            c2fb_temp_34 = CPtr(Const ZString Ptr, fts5ConfigGobbleWord(CPtr(c2fb_c_int Ptr, @(local0)), local6, CPtr(ZString Ptr Ptr, @(local8)), CPtr(c2fb_c_int Ptr, @(local11))))
            local6 = c2fb_temp_34
            If (-Cast(c2fb_c_int, (((local6 <> 0) AndAlso (CPtr(Const Byte Ptr, local6)[Cast(c2fb_c_int, &O0ULL)] <> 0))))) Then
                c2fb_temp_35 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local6 = c2fb_temp_35
            End If
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_36 = CPtr(ZString Ptr Ptr, @((*arg5)))
                c2fb_temp_37 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"parse error in \034%s\034"), local5))
                (*c2fb_temp_36) = c2fb_temp_37
                c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_38
            Else
                If local9 Then
                    c2fb_temp_39 = Cast(c2fb_c_int, fts5ConfigParseSpecial(local1, IIf((local7), CPtr(Const ZString Ptr, local7), StrPtr(!"")), IIf(local8, CPtr(Const ZString Ptr, local8), StrPtr(!"")), arg5))
                    local0 = c2fb_temp_39
                Else
                    c2fb_temp_40 = Cast(c2fb_c_int, fts5ConfigParseColumn(local1, local7, local8, arg5, CPtr(c2fb_c_int Ptr, @(local4))))
                    local0 = c2fb_temp_40
                    c2fb_temp_41 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local7 = c2fb_temp_41
                End If
            End If
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local7))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local8))
    c2fb_flow_1:
        c2fb_temp_27 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_27 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1->bContentlessDelete <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eContent <> Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        c2fb_temp_42 = CPtr(ZString Ptr Ptr, @((*arg5)))
        c2fb_temp_43 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"contentless_delete=1 requires a contentless table")))
        (*c2fb_temp_42) = c2fb_temp_43
        c2fb_temp_44 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_44
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1->bContentlessDelete <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->bColumnsize = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_45 = CPtr(ZString Ptr Ptr, @((*arg5)))
        c2fb_temp_46 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"contentless_delete=1 is incompatible with columnsize=0")))
        (*c2fb_temp_45) = c2fb_temp_46
        c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_47
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1->bContentlessUnindexed <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eContent <> Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        c2fb_temp_48 = CPtr(ZString Ptr Ptr, @((*arg5)))
        c2fb_temp_49 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"contentless_unindexed=1 requires a contentless table")))
        (*c2fb_temp_48) = c2fb_temp_49
        c2fb_temp_50 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_50
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->zContent = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
#ifdef SQLITE_DEBUG
        fts5ConfigAssert(local1->eContent = FTS5_CONTENT_NORMAL OrElse _
            local1->eContent = FTS5_CONTENT_NONE, _
            StrPtr(!"valid default eContent"))
#endif
        local12 = Cast(c2fb_c_int, &O0ULL)
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local1->eContent = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_51 = StrPtr(!"content")
            local12 = c2fb_temp_51
        Else
            If (-Cast(c2fb_c_int, (((local4 <> 0) AndAlso (local1->bContentlessUnindexed <> 0))))) Then
                c2fb_temp_52 = CPtr(Long Ptr, @(local1->eContent))
                c2fb_temp_53 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
                (*c2fb_temp_52) = Cast(Long, c2fb_temp_53)
                c2fb_temp_53 = Cast(c2fb_c_int, (*c2fb_temp_52))
                c2fb_temp_54 = StrPtr(!"content")
                local12 = c2fb_temp_54
            Else
                If local1->bColumnsize Then
                    c2fb_temp_55 = StrPtr(!"docsize")
                    local12 = c2fb_temp_55
                End If
            End If
        End If
        If local12 Then
            c2fb_temp_56 = CPtr(ZString Ptr Ptr, @(local1->zContent))
            c2fb_temp_57 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local0)), StrPtr(!"%Q.'%q_%s'"), local1->zDb, local1->zName, local12))
            (*c2fb_temp_56) = c2fb_temp_57
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->zContentRowid = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_58 = CPtr(ZString Ptr Ptr, @(local1->zContentRowid))
        c2fb_temp_59 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Strndup(CPtr(c2fb_c_int Ptr, @(local0)), StrPtr(!"rowid"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
        (*c2fb_temp_58) = c2fb_temp_59
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_60 = Cast(c2fb_c_int, fts5ConfigMakeExprlist(local1))
        local0 = c2fb_temp_60
    End If
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3Fts5ConfigFree(local1)
        c2fb_temp_61 = CPtr(c2fb_Fts5Config Ptr Ptr, @((*arg4)))
        c2fb_temp_62 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_61) = c2fb_temp_62
    End If
    Return local0
End Function
Sub sqlite3Fts5ConfigFree CDecl Alias "sqlite3Fts5ConfigFree" (ByVal arg0 As c2fb_Fts5Config Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 723
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C automatic storage declaration
        If CPtr(c2fb_Fts5Tokenizer Ptr, arg0->t.pTok) Then
            If CPtr(c2fb_fts5_tokenizer Ptr, arg0->t.pApi1) Then
                CPtr(c2fb_callback_92, CPtr(c2fb_fts5_tokenizer Ptr, arg0->t.pApi1)->xDelete)(CPtr(c2fb_Fts5Tokenizer Ptr, arg0->t.pTok))
            Else
                CPtr(c2fb_callback_92, CPtr(c2fb_fts5_tokenizer_v2 Ptr, arg0->t.pApi2)->xDelete)(CPtr(c2fb_Fts5Tokenizer Ptr, arg0->t.pTok))
            End If
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(ZString Ptr, arg0->t.azArg)))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zDb))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zName))
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->azCol[local0]))
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->azCol))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->aPrefix))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zRank))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zRankArgs))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zContent))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zContentRowid))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zContentExprlist))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Function sqlite3Fts5ConfigDeclareVtab CDecl Alias "sqlite3Fts5ConfigDeclareVtab" (ByVal arg0 As c2fb_Fts5Config Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 755
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"CREATE TABLE x(")))
    local2 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_1
    While (-Cast(c2fb_c_int, (((local2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < arg0->nCol)))) <> 0)))))
        local3 = (IIf((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))), StrPtr(!""), StrPtr(!", ")))
        c2fb_temp_3 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"%z%s%Q"), local2, local3, arg0->azCol[local0]))
        local2 = c2fb_temp_3
    c2fb_flow_1:
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"%z, %Q HIDDEN, %s HIDDEN)"), local2, arg0->zName, StrPtr(!"rank")))
    local2 = c2fb_temp_4
#ifdef SQLITE_DEBUG
    fts5ConfigAssert(local2 <> 0 OrElse local1 = 7, _
        StrPtr(!"zSql || rc==SQLITE_NOMEM"))
#endif
    ' C unused-parameter annotation
    If local2 Then
        c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_declare_vtab(CPtr(c2fb_sqlite3 Ptr, arg0->db), CPtr(Const ZString Ptr, local2)))
        local1 = c2fb_temp_5
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    End If
    Return local1
End Function
Function sqlite3Fts5Tokenize CDecl Alias "sqlite3Fts5Tokenize" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_73) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 801
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg2 Then
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Tokenizer Ptr, arg0->t.pTok) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5LoadTokenizer(arg0))
            local0 = c2fb_temp_0
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            If CPtr(c2fb_fts5_tokenizer Ptr, arg0->t.pApi1) Then
                c2fb_temp_1 = Cast(c2fb_c_int, CPtr(c2fb_callback_94, CPtr(c2fb_fts5_tokenizer Ptr, arg0->t.pApi1)->xTokenize)(CPtr(c2fb_Fts5Tokenizer Ptr, arg0->t.pTok), arg4, arg1, arg2, arg3, arg5))
                local0 = c2fb_temp_1
            Else
                c2fb_temp_2 = Cast(c2fb_c_int, CPtr(c2fb_callback_93, CPtr(c2fb_fts5_tokenizer_v2 Ptr, arg0->t.pApi2)->xTokenize)(CPtr(c2fb_Fts5Tokenizer Ptr, arg0->t.pTok), arg4, arg1, arg2, arg3, arg0->t.pLocale, arg0->t.nLocale, arg5))
                local0 = c2fb_temp_2
            End If
        End If
    End If
    Return local0
End Function
Private Function fts5ConfigSkipArgs CDecl Alias "fts5ConfigSkipArgs" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 834
    Dim local0 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr

    local0 = arg0
    While Cast(c2fb_c_int, 1ULL)
        c2fb_temp_0 = CPtr(Const ZString Ptr, fts5ConfigSkipWhitespace(local0))
        local0 = c2fb_temp_0
        c2fb_temp_1 = CPtr(Const ZString Ptr, fts5ConfigSkipLiteral(local0))
        local0 = c2fb_temp_1
        c2fb_temp_2 = CPtr(Const ZString Ptr, fts5ConfigSkipWhitespace(local0))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 41))))) <> 0))))) Then
            Goto c2fb_flow_0
        End If
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <> Cast(c2fb_c_int, 44))))) Then
            c2fb_temp_3 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_3
            Goto c2fb_flow_0
        End If
        c2fb_temp_4 = local0
        local0 = (c2fb_temp_4 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local0
End Function
Function sqlite3Fts5ConfigParseRank CDecl Alias "sqlite3Fts5ConfigParseRank" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As ZString Ptr Ptr, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 861
    Dim local0 As Const ZString Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As Const ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Const ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim local5 As Const ZString Ptr
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As Const ZString Ptr
    Dim c2fb_temp_16 As Const ZString Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As Any Ptr
    Dim c2fb_temp_20 As ZString Ptr Ptr
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As ZString Ptr Ptr
    Dim c2fb_temp_23 As ZString Ptr

    local0 = arg0
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_1 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @((*arg2)))
    c2fb_temp_3 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local4 = c2fb_temp_4
    Else
        c2fb_temp_5 = CPtr(Const ZString Ptr, fts5ConfigSkipWhitespace(local0))
        local0 = c2fb_temp_5
        c2fb_temp_6 = local0
        local1 = c2fb_temp_6
        c2fb_temp_7 = CPtr(Const ZString Ptr, fts5ConfigSkipBareword(local0))
        local0 = c2fb_temp_7
        If local0 Then
            c2fb_temp_8 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local4)), (CPtr(Byte Ptr, CPtr(Const Byte Ptr, CPtr(Const ZString Ptr, (Cast(c2fb_c_int, 1ULL) + CPtr(Const Byte Ptr, local0))))) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local1))))))
            local2 = c2fb_temp_8
            If local2 Then
                c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local2), CPtr(Const Any Ptr, local1), (CPtr(Byte Ptr, CPtr(Const Byte Ptr, local0)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local1)))))
            End If
        Else
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local4 = c2fb_temp_10
        End If
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_11 = CPtr(Const ZString Ptr, fts5ConfigSkipWhitespace(local0))
            local0 = c2fb_temp_11
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <> Cast(c2fb_c_int, 40))))) Then
                c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local4 = c2fb_temp_12
            End If
            c2fb_temp_13 = local0
            local0 = (c2fb_temp_13 + 1)
        End If
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_14 = CPtr(Const ZString Ptr, fts5ConfigSkipWhitespace(local0))
            local0 = c2fb_temp_14
            c2fb_temp_15 = local0
            local5 = c2fb_temp_15
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <> Cast(c2fb_c_int, 41))))) Then
                c2fb_temp_16 = CPtr(Const ZString Ptr, fts5ConfigSkipArgs(local0))
                local0 = c2fb_temp_16
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local4 = c2fb_temp_17
                Else
                    c2fb_temp_18 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local4)), (CPtr(Byte Ptr, CPtr(Const Byte Ptr, CPtr(Const ZString Ptr, (Cast(c2fb_c_int, 1ULL) + CPtr(Const Byte Ptr, local0))))) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local5))))))
                    local3 = c2fb_temp_18
                    If local3 Then
                        c2fb_temp_19 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local3), CPtr(Const Any Ptr, local5), (CPtr(Byte Ptr, CPtr(Const Byte Ptr, local0)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local5)))))
                    End If
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
#ifdef SQLITE_DEBUG
        fts5ConfigAssert(local3 = 0, StrPtr(!"zRankArgs==0"))
#endif
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
        ' C unused-parameter annotation
    Else
        c2fb_temp_20 = CPtr(ZString Ptr Ptr, @((*arg1)))
        c2fb_temp_21 = local2
        (*c2fb_temp_20) = c2fb_temp_21
        c2fb_temp_22 = CPtr(ZString Ptr Ptr, @((*arg2)))
        c2fb_temp_23 = local3
        (*c2fb_temp_22) = c2fb_temp_23
    End If
    Return local4
End Function
Function sqlite3Fts5ConfigSetValue CDecl Alias "sqlite3Fts5ConfigSetValue" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_value Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 920
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Long Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As Long Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim local7 As Const ZString Ptr
    Dim local8 As ZString Ptr
    Dim local9 As ZString Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As ZString Ptr Ptr
    Dim c2fb_temp_37 As ZString Ptr
    Dim c2fb_temp_38 As ZString Ptr Ptr
    Dim c2fb_temp_39 As ZString Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int Ptr
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As Long Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_c_int Ptr
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As Long Ptr
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As c2fb_c_int Ptr
    Dim c2fb_temp_54 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"pgsz")))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = c2fb_external_sqlite3_value_numeric_type(arg2))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(arg2))
            local1 = c2fb_temp_0
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, 32ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 > (Cast(c2fb_c_int, (Cast(c2fb_c_int, 64ULL) * Cast(c2fb_c_int, 1024ULL)))))))) <> 0))))) Then
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_1) = c2fb_temp_2
        Else
            c2fb_temp_3 = CPtr(Long Ptr, @(arg0->pgsz))
            c2fb_temp_4 = Cast(c2fb_c_int, local1)
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        End If
    Else
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"hashsize")))))) Then
            local2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = c2fb_external_sqlite3_value_numeric_type(arg2))))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(arg2))
                local2 = c2fb_temp_5
            End If
            If (-Cast(c2fb_c_int, ((local2 <= Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_6) = c2fb_temp_7
            Else
                c2fb_temp_8 = CPtr(Long Ptr, @(arg0->nHashSize))
                c2fb_temp_9 = Cast(c2fb_c_int, local2)
                (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
                c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
            End If
        Else
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"automerge")))))) Then
                local3 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = c2fb_external_sqlite3_value_numeric_type(arg2))))) Then
                    c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(arg2))
                    local3 = c2fb_temp_10
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, 64ULL))))) <> 0))))) Then
                    c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_11) = c2fb_temp_12
                Else
                    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 1ULL))))) Then
                        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
                        local3 = c2fb_temp_13
                    End If
                    c2fb_temp_14 = CPtr(Long Ptr, @(arg0->nAutomerge))
                    c2fb_temp_15 = Cast(c2fb_c_int, local3)
                    (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
                    c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                End If
            Else
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"usermerge")))))) Then
                    local4 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = c2fb_external_sqlite3_value_numeric_type(arg2))))) Then
                        c2fb_temp_16 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(arg2))
                        local4 = c2fb_temp_16
                    End If
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 > Cast(c2fb_c_int, 16ULL))))) <> 0))))) Then
                        c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                        c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        (*c2fb_temp_17) = c2fb_temp_18
                    Else
                        c2fb_temp_19 = CPtr(Long Ptr, @(arg0->nUsermerge))
                        c2fb_temp_20 = Cast(c2fb_c_int, local4)
                        (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
                        c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"crisismerge")))))) Then
                        local5 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = c2fb_external_sqlite3_value_numeric_type(arg2))))) Then
                            c2fb_temp_21 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(arg2))
                            local5 = c2fb_temp_21
                        End If
                        If (-Cast(c2fb_c_int, ((local5 < Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                            c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            (*c2fb_temp_22) = c2fb_temp_23
                        Else
                            If (-Cast(c2fb_c_int, ((local5 <= Cast(c2fb_c_int, 1ULL))))) Then
                                c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, 16ULL))
                                local5 = c2fb_temp_24
                            End If
                            If (-Cast(c2fb_c_int, ((local5 >= Cast(c2fb_c_int, 2000ULL))))) Then
                                c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 2000ULL) - Cast(c2fb_c_int, 1ULL))))
                                local5 = c2fb_temp_25
                            End If
                            c2fb_temp_26 = CPtr(Long Ptr, @(arg0->nCrisisMerge))
                            c2fb_temp_27 = Cast(c2fb_c_int, local5)
                            (*c2fb_temp_26) = Cast(Long, c2fb_temp_27)
                            c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
                        End If
                    Else
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"deletemerge")))))) Then
                            local6 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = c2fb_external_sqlite3_value_numeric_type(arg2))))) Then
                                c2fb_temp_28 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(arg2))
                                local6 = c2fb_temp_28
                            Else
                                c2fb_temp_29 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                                c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                (*c2fb_temp_29) = c2fb_temp_30
                            End If
                            If (-Cast(c2fb_c_int, ((local6 < Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, 10ULL))
                                local6 = c2fb_temp_31
                            End If
                            If (-Cast(c2fb_c_int, ((local6 > Cast(c2fb_c_int, 100ULL))))) Then
                                c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                                local6 = c2fb_temp_32
                            End If
                            c2fb_temp_33 = CPtr(Long Ptr, @(arg0->nDeleteMerge))
                            c2fb_temp_34 = Cast(c2fb_c_int, local6)
                            (*c2fb_temp_33) = Cast(Long, c2fb_temp_34)
                            c2fb_temp_34 = Cast(c2fb_c_int, (*c2fb_temp_33))
                        Else
                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"rank")))))) Then
                                local7 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2)))
                                ' C automatic storage declaration
                                ' C automatic storage declaration
                                c2fb_temp_35 = Cast(c2fb_c_int, sqlite3Fts5ConfigParseRank(local7, CPtr(ZString Ptr Ptr, @(local8)), CPtr(ZString Ptr Ptr, @(local9))))
                                local0 = c2fb_temp_35
                                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                                    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zRank))
                                    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zRankArgs))
                                    c2fb_temp_36 = CPtr(ZString Ptr Ptr, @(arg0->zRank))
                                    c2fb_temp_37 = local8
                                    (*c2fb_temp_36) = c2fb_temp_37
                                    c2fb_temp_38 = CPtr(ZString Ptr Ptr, @(arg0->zRankArgs))
                                    c2fb_temp_39 = local9
                                    (*c2fb_temp_38) = c2fb_temp_39
                                Else
                                    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
                                        c2fb_temp_40 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                                        local0 = c2fb_temp_40
                                        c2fb_temp_41 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                                        c2fb_temp_42 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                        (*c2fb_temp_41) = c2fb_temp_42
                                    End If
                                End If
                            Else
                                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"secure-delete")))))) Then
                                    local10 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = c2fb_external_sqlite3_value_numeric_type(arg2))))) Then
                                        c2fb_temp_43 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(arg2))
                                        local10 = c2fb_temp_43
                                    End If
                                    If (-Cast(c2fb_c_int, ((local10 < Cast(c2fb_c_int, &O0ULL))))) Then
                                        c2fb_temp_44 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                                        c2fb_temp_45 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                        (*c2fb_temp_44) = c2fb_temp_45
                                    Else
                                        c2fb_temp_46 = CPtr(Long Ptr, @(arg0->bSecureDelete))
                                        c2fb_temp_47 = Cast(c2fb_c_int, (IIf(local10, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))))
                                        (*c2fb_temp_46) = Cast(Long, c2fb_temp_47)
                                        c2fb_temp_47 = Cast(c2fb_c_int, (*c2fb_temp_46))
                                    End If
                                Else
                                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(arg1, StrPtr(!"insttoken")))))) Then
                                        local11 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = c2fb_external_sqlite3_value_numeric_type(arg2))))) Then
                                            c2fb_temp_48 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(arg2))
                                            local11 = c2fb_temp_48
                                        End If
                                        If (-Cast(c2fb_c_int, ((local11 < Cast(c2fb_c_int, &O0ULL))))) Then
                                            c2fb_temp_49 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                                            c2fb_temp_50 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                            (*c2fb_temp_49) = c2fb_temp_50
                                        Else
                                            c2fb_temp_51 = CPtr(Long Ptr, @(arg0->bPrefixInsttoken))
                                            c2fb_temp_52 = Cast(c2fb_c_int, (IIf(local11, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))))
                                            (*c2fb_temp_51) = Cast(Long, c2fb_temp_52)
                                            c2fb_temp_52 = Cast(c2fb_c_int, (*c2fb_temp_51))
                                        End If
                                    Else
                                        c2fb_temp_53 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                                        c2fb_temp_54 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                        (*c2fb_temp_53) = c2fb_temp_54
                                    End If
                                End If
                            End If
                        End If
                    End If
                End If
            End If
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5ConfigLoad CDecl Alias "sqlite3Fts5ConfigLoad" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 1051
    Dim local0 As Const ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local5 As Const ZString Ptr
    Dim local6 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int

    local0 = StrPtr(!"SELECT k, v FROM %Q.'%q_config'")
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->pgsz))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4050ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->nAutomerge))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(Long Ptr, @(arg0->nUsermerge))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
    (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->nCrisisMerge))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 16ULL))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(Long Ptr, @(arg0->nHashSize))
    c2fb_temp_9 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1024ULL) * Cast(c2fb_c_int, 1024ULL)))))
    (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
    c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
    c2fb_temp_10 = CPtr(Long Ptr, @(arg0->nDeleteMerge))
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 10ULL))
    (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
    c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
    c2fb_temp_12 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local3)), local0, arg0->zDb, arg0->zName))
    local1 = c2fb_temp_12
    If local1 Then
        c2fb_temp_13 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2(CPtr(c2fb_sqlite3 Ptr, arg0->db), CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL)))
        local3 = c2fb_temp_13
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
#ifdef SQLITE_DEBUG
    fts5ConfigAssert(local3 = 0 OrElse local2 = 0, _
        StrPtr(!"rc==SQLITE_OK || p==0"))
#endif
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local2)))))
            local5 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local2, Cast(c2fb_c_int, &O0ULL))))
            local6 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(local2, Cast(c2fb_c_int, 1ULL)))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(local5, StrPtr(!"version")))))) Then
                c2fb_temp_14 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int(local6))
                local4 = c2fb_temp_14
            Else
                local7 = Cast(c2fb_c_int, &O0ULL)
                sqlite3Fts5ConfigSetValue(arg0, local5, local6, CPtr(c2fb_c_int Ptr, @(local7)))
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_15 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize(local2))
        local3 = c2fb_temp_15
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, 5ULL))))) <> 0))))) Then
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_16
        sqlite3Fts5ConfigErrmsg(arg0, StrPtr(!"invalid fts5 file format (found %d, expected %d or %d) - run 'rebuild'"), local4, Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 5ULL))
    Else
        c2fb_temp_17 = CPtr(Long Ptr, @(arg0->iVersion))
        c2fb_temp_18 = Cast(c2fb_c_int, local4)
        (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
    End If
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_19 = CPtr(Long Ptr, @(arg0->iCookie))
        c2fb_temp_20 = Cast(c2fb_c_int, arg1)
        (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
        c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
    End If
    Return local3
End Function
Sub sqlite3Fts5ConfigErrmsg CDecl Alias "sqlite3Fts5ConfigErrmsg" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ...)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_config.c
' c2fb source-line: 1111
    Dim local0 As Cva_List
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    Cva_Start(local0, arg1)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local0))
    local1 = c2fb_temp_0
    If arg0->pzErrmsg Then
#ifdef SQLITE_DEBUG
        fts5ConfigAssert(*arg0->pzErrmsg = 0, _
            StrPtr(!"*pConfig->pzErrmsg==0"))
#endif
        ' C unused-parameter annotation
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @((*arg0->pzErrmsg)))
        c2fb_temp_2 = local1
        (*c2fb_temp_1) = c2fb_temp_2
    Else
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Cva_End(local0)
End Sub
#endif
/' end of sqlite3_bulk_fts5_config.bas '/
