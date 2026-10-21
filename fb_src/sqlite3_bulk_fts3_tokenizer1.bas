/'
** 2006 Oct 10
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
** Implementation of the "simple" full-text-search tokenizer.
'/
/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_tokenizer1.bas

    Purpose:

        Port simple fts3 tokenizer routines from ext/fts3/fts3_tokenizer1.c.

    Responsibilities:

        - Split input into the simple tokenizer tokens.
        - Return token byte offsets and source text through the tokenizer API.

    This file intentionally does NOT contain:

        - Registration of the simple module in the FTS3 tokenizer hash.
        - Test support.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
#include once "sqlite3_btree.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_expr_types.bi"
#include once "sqlite3_hash_types.bi"
#include once "sqlite3_pager.bi"
#include once "sqlite3_parser_types.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_fts3_tokenizer_types.bi"
#include once "sqlite3_vdbe_core.bi"
#include once "sqlite3_vdbe_mem_types.bi"


/' ------------------------------------------------------------------------- '/
/' Simple FTS3 tokenizer routines                                            '/
/' ------------------------------------------------------------------------- '/

#ifndef __C2FB_BODY_C_ABI_TYPES__
#define __C2FB_BODY_C_ABI_TYPES__

#ifndef __C2FB_ABI_TYPE_C_INT__
#define __C2FB_ABI_TYPE_C_INT__
Type c2fb_c_int As SQLITE_C_INT
#endif
#ifndef __C2FB_ABI_TYPE_C_UINT__
#define __C2FB_ABI_TYPE_C_UINT__
Type c2fb_c_uint As SQLITE_C_UINT
#endif
#ifndef __C2FB_ABI_TYPE_C_LONG__
#define __C2FB_ABI_TYPE_C_LONG__
Type c2fb_c_long As SQLITE_C_LONG
#endif
#ifndef __C2FB_ABI_TYPE_C_ULONG__
#define __C2FB_ABI_TYPE_C_ULONG__
Type c2fb_c_ulong As SQLITE_C_ULONG
#endif
#ifndef __C2FB_ABI_TYPE_INT64__
#define __C2FB_ABI_TYPE_INT64__
Type c2fb_int64 As sqlite3_int64
#endif
#ifndef __C2FB_ABI_TYPE_UINT64__
#define __C2FB_ABI_TYPE_UINT64__
Type c2fb_uint64 As sqlite3_uint64
#endif
#ifndef __C2FB_ABI_TYPE_SIZE_T__
#define __C2FB_ABI_TYPE_SIZE_T__
Type c2fb_size_t As SQLITE_SIZE_T
#endif
#endif

Declare Function sqlite3_malloc CDecl Alias "sqlite3_malloc" (ByVal arg0 As c2fb_c_int) As Any Ptr
Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)

Private Type c2fb_source_record_330
    pModule As Any Ptr
End Type

Private Type c2fb_source_record_331
    pTokenizer As c2fb_source_record_330 Ptr
End Type

Private Type c2fb_source_record_343
    base As c2fb_source_record_330
    delim(0 To 127) As Byte
End Type

Private Type c2fb_source_record_344
    base As c2fb_source_record_331
    pInput As Const ZString Ptr
    nBytes As c2fb_c_int
    iOffset As c2fb_c_int
    iToken As c2fb_c_int
    pToken As ZString Ptr
    nTokenAllocated As c2fb_c_int
End Type

Declare Function simpleDelim CDecl Alias "simpleDelim" (ByVal arg0 As c2fb_source_record_343 Ptr, ByVal arg1 As UByte) As c2fb_c_int
Declare Function fts3_isalnum CDecl Alias "fts3_isalnum" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
Declare Function simpleCreate CDecl Alias "simpleCreate" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_source_record_330 Ptr Ptr) As c2fb_c_int
Declare Function simpleDestroy CDecl Alias "simpleDestroy" (ByVal arg0 As c2fb_source_record_330 Ptr) As c2fb_c_int
Declare Function simpleOpen CDecl Alias "simpleOpen" (ByVal arg0 As c2fb_source_record_330 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_331 Ptr Ptr) As c2fb_c_int
Declare Function simpleClose CDecl Alias "simpleClose" (ByVal arg0 As c2fb_source_record_331 Ptr) As c2fb_c_int
Declare Function simpleNext CDecl Alias "simpleNext" (ByVal arg0 As c2fb_source_record_331 Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
Private Function simpleDelim CDecl Alias "simpleDelim" (ByVal arg0 As c2fb_source_record_343 Ptr, ByVal arg1 As UByte) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer1.c
    Return (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1) < Cast(c2fb_c_int, &H80ULL))))) <> 0) AndAlso (arg0->delim(arg1) <> 0)))))
End Function
Private Function fts3_isalnum CDecl Alias "fts3_isalnum" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer1.c
    Return (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0 <= Cast(c2fb_c_int, 57))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 >= Cast(c2fb_c_int, 65))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0 <= Cast(c2fb_c_int, 90))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 >= Cast(c2fb_c_int, 97))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0 <= Cast(c2fb_c_int, 122))))) <> 0)))))) <> 0)))))
End Function
Private Function simpleCreate CDecl Alias "simpleCreate" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_source_record_330 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer1.c
    Dim local0 As c2fb_source_record_343 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_343 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As UByte
    Dim c2fb_temp_4 As Byte Ptr
    Dim c2fb_temp_5 As Byte
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Byte Ptr
    Dim c2fb_temp_9 As Byte
    Dim c2fb_temp_10 As c2fb_source_record_330 Ptr Ptr
    Dim c2fb_temp_11 As c2fb_source_record_330 Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_343 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_343)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_343))))
    If (-Cast(c2fb_c_int, ((arg0 > Cast(c2fb_c_int, 1ULL))))) Then
        ' C automatic storage declaration
        local2 = Cast(c2fb_c_int, c2fb_crt_strlen(arg1[Cast(c2fb_c_int, 1ULL)]))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local1 < local2))))
            local3 = CPtr(Const Byte Ptr, arg1[Cast(c2fb_c_int, 1ULL)])[local1]
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) >= Cast(c2fb_c_int, &H80ULL))))) Then
                sqlite3_free(CPtr(Any Ptr, local0))
                Return Cast(c2fb_c_int, 1ULL)
            End If
            c2fb_temp_4 = CPtr(Byte Ptr, @(local0->delim(local3)))
            c2fb_temp_5 = Cast(Byte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_4) = c2fb_temp_5
        c2fb_flow_1:
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
    Else
        ' C automatic storage declaration
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local4 = c2fb_temp_6
        While (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, &H80ULL)))))
            c2fb_temp_8 = CPtr(Byte Ptr, @(local0->delim(local4)))
            c2fb_temp_9 = Cast(Byte, IIf((-Cast(c2fb_c_int, (fts3_isalnum(local4) = 0))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_8) = c2fb_temp_9
        c2fb_flow_3:
            c2fb_temp_7 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
        Wend
        c2fb_flow_2:
    End If
    c2fb_temp_10 = CPtr(c2fb_source_record_330 Ptr Ptr, @((*arg2)))
    c2fb_temp_11 = CPtr(c2fb_source_record_330 Ptr, @(local0->base))
    (*c2fb_temp_10) = c2fb_temp_11
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function simpleDestroy CDecl Alias "simpleDestroy" (ByVal arg0 As c2fb_source_record_330 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer1.c
    sqlite3_free(CPtr(Any Ptr, arg0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function simpleOpen CDecl Alias "simpleOpen" (ByVal arg0 As c2fb_source_record_330 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_331 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer1.c
    Dim local0 As c2fb_source_record_344 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_344 Ptr
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As ZString Ptr Ptr
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_source_record_331 Ptr Ptr
    Dim c2fb_temp_18 As c2fb_source_record_331 Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_source_record_344 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_344)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, @(local0->pInput))
    c2fb_temp_2 = arg1
    (*c2fb_temp_1) = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(local0->nBytes))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_3) = c2fb_temp_4
    Else
        If (-Cast(c2fb_c_int, ((arg2 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(local0->nBytes))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(arg1)))
            (*c2fb_temp_5) = c2fb_temp_6
        Else
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local0->nBytes))
            c2fb_temp_8 = Cast(c2fb_c_int, arg2)
            (*c2fb_temp_7) = c2fb_temp_8
        End If
    End If
    c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(local0->iOffset))
    c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_9) = c2fb_temp_10
    c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @(local0->iToken))
    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_11) = c2fb_temp_12
    c2fb_temp_13 = CPtr(ZString Ptr Ptr, @(local0->pToken))
    c2fb_temp_14 = CPtr(ZString Ptr, (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
    (*c2fb_temp_13) = c2fb_temp_14
    c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @(local0->nTokenAllocated))
    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_15) = c2fb_temp_16
    c2fb_temp_17 = CPtr(c2fb_source_record_331 Ptr Ptr, @((*arg3)))
    c2fb_temp_18 = CPtr(c2fb_source_record_331 Ptr, @(local0->base))
    (*c2fb_temp_17) = c2fb_temp_18
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function simpleClose CDecl Alias "simpleClose" (ByVal arg0 As c2fb_source_record_331 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer1.c
    Dim local0 As c2fb_source_record_344 Ptr

    local0 = CPtr(c2fb_source_record_344 Ptr, arg0)
    sqlite3_free(CPtr(Any Ptr, local0->pToken))
    sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function simpleNext CDecl Alias "simpleNext" (ByVal arg0 As c2fb_source_record_331 Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_tokenizer1.c
    Dim local0 As c2fb_source_record_344 Ptr
    Dim local1 As c2fb_source_record_343 Ptr
    Dim local2 As UByte Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local7 As UByte
    Dim c2fb_temp_12 As Byte Ptr
    Dim c2fb_temp_13 As Byte
    Dim c2fb_temp_14 As Const ZString Ptr Ptr
    Dim c2fb_temp_15 As Const ZString Ptr
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int Ptr
    Dim c2fb_temp_25 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_344 Ptr, arg0)
    local1 = CPtr(c2fb_source_record_343 Ptr, arg0->pTokenizer)
    local2 = CPtr(UByte Ptr, local0->pInput)
    While (-Cast(c2fb_c_int, ((local0->iOffset < local0->nBytes))))
        ' C automatic storage declaration
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->iOffset < local0->nBytes)))) <> 0) AndAlso (simpleDelim(local1, local2[local0->iOffset]) <> 0)))))
            c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(local0->iOffset))
            c2fb_temp_1 = (*c2fb_temp_0)
            (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_2 = Cast(c2fb_c_int, local0->iOffset)
        local3 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->iOffset < local0->nBytes)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (simpleDelim(local1, local2[local0->iOffset]) = 0))) <> 0)))))
            c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(local0->iOffset))
            c2fb_temp_4 = (*c2fb_temp_3)
            (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        c2fb_flow_5:
        Wend
        c2fb_flow_4:
        If (-Cast(c2fb_c_int, ((local0->iOffset > local3)))) Then
            ' C automatic storage declaration
            local5 = Cast(c2fb_c_int, (local0->iOffset - local3))
            If (-Cast(c2fb_c_int, ((local5 > local0->nTokenAllocated)))) Then
                ' C automatic storage declaration
                c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(local0->nTokenAllocated))
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 20ULL))))
                (*c2fb_temp_5) = c2fb_temp_6
                c2fb_temp_7 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local0->pToken), local0->nTokenAllocated)))
                local6 = c2fb_temp_7
                If (-Cast(c2fb_c_int, (local6 = 0))) Then
                    Return Cast(c2fb_c_int, 7ULL)
                End If
                c2fb_temp_8 = CPtr(ZString Ptr Ptr, @(local0->pToken))
                c2fb_temp_9 = local6
                (*c2fb_temp_8) = c2fb_temp_9
            End If
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local4 = c2fb_temp_10
            While (-Cast(c2fb_c_int, ((local4 < local5))))
                local7 = local2[Cast(c2fb_c_int, (local3 + local4))]
                c2fb_temp_12 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0->pToken)[local4]))
                c2fb_temp_13 = Cast(Byte, Cast(Byte, (IIf(((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local7) >= Cast(c2fb_c_int, 65))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local7) <= Cast(c2fb_c_int, 90))))) <> 0)))))), Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, local7) - Cast(c2fb_c_int, 65))) + Cast(c2fb_c_int, 97))), Cast(c2fb_c_int, local7)))))
                (*c2fb_temp_12) = c2fb_temp_13
            c2fb_flow_7:
                c2fb_temp_11 = local4
                local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
            Wend
            c2fb_flow_6:
            c2fb_temp_14 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
            c2fb_temp_15 = CPtr(Const ZString Ptr, local0->pToken)
            (*c2fb_temp_14) = c2fb_temp_15
            c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_17 = Cast(c2fb_c_int, local5)
            (*c2fb_temp_16) = c2fb_temp_17
            c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_19 = Cast(c2fb_c_int, local3)
            (*c2fb_temp_18) = c2fb_temp_19
            c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @((*arg4)))
            c2fb_temp_21 = Cast(c2fb_c_int, local0->iOffset)
            (*c2fb_temp_20) = c2fb_temp_21
            c2fb_temp_24 = CPtr(c2fb_c_int Ptr, @((*arg5)))
            c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @(local0->iToken))
            c2fb_temp_23 = (*c2fb_temp_22)
            (*c2fb_temp_22) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_23 + 1)))
            c2fb_temp_25 = Cast(c2fb_c_int, c2fb_temp_23)
            (*c2fb_temp_24) = c2fb_temp_25
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, 101ULL)
End Function
/' ------------------------------------------------------------------------- '/
/' Simple tokenizer module registration                                      '/
/' ------------------------------------------------------------------------- '/
/'
    The tokenizer interface carries byte offsets into the caller-owned input
    buffer; this table only binds the five lifecycle and token callbacks.
'/
Private Dim Shared As Const Fts3TokenizerModule simpleTokenizerModule = _
    Type<Fts3TokenizerModule>( _
        0, _
        Cast(Fts3TokenizerCreateProc, ProcPtr(simpleCreate)), _
        Cast(Fts3TokenizerDestroyProc, ProcPtr(simpleDestroy)), _
        Cast(Fts3TokenizerOpenProc, ProcPtr(simpleOpen)), _
        Cast(Fts3TokenizerCloseProc, ProcPtr(simpleClose)), _
        Cast(Fts3TokenizerNextProc, ProcPtr(simpleNext)), _
        Cast(Fts3TokenizerLanguageidProc, 0) _
    )

Sub sqlite3Fts3SimpleTokenizerModule CDecl Alias "sqlite3Fts3SimpleTokenizerModule" ( _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr _
)
    If CPtr(Any Ptr, ppModule) <> 0 Then *ppModule = @simpleTokenizerModule
End Sub
#endif

/' end of sqlite3_bulk_fts3_tokenizer1.bas '/
