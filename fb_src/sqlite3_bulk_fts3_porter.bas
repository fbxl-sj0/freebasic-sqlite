/'
** 2006 September 30
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
*************************************************************************
** Implementation of the full-text-search tokenizer that implements
** a Porter stemmer.
'/
/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_porter.bas

    Purpose:

        Port porter stemming tokenizer routines from ext/fts3/fts3_porter.c.

    Responsibilities:

        - Normalize and stem tokens through the Porter tokenizer.
        - Keep token buffers and callback state local to this module.

    This file intentionally does NOT contain:

        - Registration of the Porter module in the FTS3 tokenizer hash.
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
/' Porter stemming tokenizer routines                                        '/
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

Type c2fb_callback_18 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As SQLITE_C_INT) As SQLITE_C_INT
Type c2fb_callback_186 As Function CDecl(ByVal arg0 As Const ZString Ptr) As c2fb_c_int

Private Type c2fb_source_record_181
    pModule As Any Ptr
End Type

Private Type c2fb_source_record_182
    pTokenizer As c2fb_source_record_181 Ptr
End Type

Private Type c2fb_source_record_194
    base As c2fb_source_record_181
End Type

Private Type c2fb_source_record_195
    base As c2fb_source_record_182
    zInput As Const ZString Ptr
    nInput As c2fb_c_int
    iOffset As c2fb_c_int
    iToken As c2fb_c_int
    zToken As ZString Ptr
    nAllocated As c2fb_c_int
End Type

Declare Function porterCreate CDecl Alias "porterCreate" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_source_record_181 Ptr Ptr) As c2fb_c_int
Declare Function porterDestroy CDecl Alias "porterDestroy" (ByVal arg0 As c2fb_source_record_181 Ptr) As c2fb_c_int
Declare Function porterOpen CDecl Alias "porterOpen" (ByVal arg0 As c2fb_source_record_181 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_182 Ptr Ptr) As c2fb_c_int
Declare Function porterClose CDecl Alias "porterClose" (ByVal arg0 As c2fb_source_record_182 Ptr) As c2fb_c_int
Declare Function isConsonant CDecl Alias "isConsonant" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function isVowel CDecl Alias "isVowel" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function m_gt_0 CDecl Alias "m_gt_0" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function m_eq_1 CDecl Alias "m_eq_1" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function m_gt_1 CDecl Alias "m_gt_1" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function hasVowel CDecl Alias "hasVowel" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function doubleConsonant CDecl Alias "doubleConsonant" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function star_oh CDecl Alias "star_oh" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function stem CDecl Alias "stem" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_callback_186) As c2fb_c_int
Declare Sub copy_stemmer CDecl Alias "copy_stemmer" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Sub porter_stemmer CDecl Alias "porter_stemmer" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Function porterNext CDecl Alias "porterNext" (ByVal arg0 As c2fb_source_record_182 Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Private Dim Shared c2fb_global_cType(0 To 25) As Const Byte = {0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 2, 1}
Private Dim Shared c2fb_global_porterIdChar(0 To 79) As Const Byte = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0}
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
Private Function porterCreate CDecl Alias "porterCreate" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_source_record_181 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As c2fb_source_record_194 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_194 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_source_record_181 Ptr Ptr
    Dim c2fb_temp_3 As c2fb_source_record_181 Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_source_record_194 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_194)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_194))))
    c2fb_temp_2 = CPtr(c2fb_source_record_181 Ptr Ptr, @((*arg2)))
    c2fb_temp_3 = CPtr(c2fb_source_record_181 Ptr, @(local0->base))
    (*c2fb_temp_2) = c2fb_temp_3
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function porterDestroy CDecl Alias "porterDestroy" (ByVal arg0 As c2fb_source_record_181 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    sqlite3_free(CPtr(Any Ptr, arg0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function porterOpen CDecl Alias "porterOpen" (ByVal arg0 As c2fb_source_record_181 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_182 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As c2fb_source_record_195 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_195 Ptr
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
    Dim c2fb_temp_17 As c2fb_source_record_182 Ptr Ptr
    Dim c2fb_temp_18 As c2fb_source_record_182 Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_source_record_195 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_195)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, @(local0->zInput))
    c2fb_temp_2 = arg1
    (*c2fb_temp_1) = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(local0->nInput))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_3) = c2fb_temp_4
    Else
        If (-Cast(c2fb_c_int, ((arg2 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(local0->nInput))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(arg1)))
            (*c2fb_temp_5) = c2fb_temp_6
        Else
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local0->nInput))
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
    c2fb_temp_13 = CPtr(ZString Ptr Ptr, @(local0->zToken))
    c2fb_temp_14 = CPtr(ZString Ptr, (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
    (*c2fb_temp_13) = c2fb_temp_14
    c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @(local0->nAllocated))
    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_15) = c2fb_temp_16
    c2fb_temp_17 = CPtr(c2fb_source_record_182 Ptr Ptr, @((*arg3)))
    c2fb_temp_18 = CPtr(c2fb_source_record_182 Ptr, @(local0->base))
    (*c2fb_temp_17) = c2fb_temp_18
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function porterClose CDecl Alias "porterClose" (ByVal arg0 As c2fb_source_record_182 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As c2fb_source_record_195 Ptr

    local0 = CPtr(c2fb_source_record_195 Ptr, arg0)
    sqlite3_free(CPtr(Any Ptr, local0->zToken))
    sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function isConsonant CDecl Alias "isConsonant" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As c2fb_c_int
    Dim local1 As Byte
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    local1 = (*CPtr(Const Byte Ptr, arg0))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_global_cType(Cast(c2fb_c_int, (Cast(c2fb_c_int, local1) - Cast(c2fb_c_int, 97)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, 2ULL))))) Then
        Return local0
    End If
    Return (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (isVowel(CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, arg0) + Cast(c2fb_c_int, 1ULL)))) <> 0)))))
End Function
Private Function isVowel CDecl Alias "isVowel" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As c2fb_c_int
    Dim local1 As Byte
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    local1 = (*CPtr(Const Byte Ptr, arg0))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_global_cType(Cast(c2fb_c_int, (Cast(c2fb_c_int, local1) - Cast(c2fb_c_int, 97)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, 2ULL))))) Then
        Return Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) - local0))
    End If
    Return isConsonant(CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, arg0) + Cast(c2fb_c_int, 1ULL))))
End Function
Private Function m_gt_0 CDecl Alias "m_gt_0" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr

    While isVowel(arg0)
        c2fb_temp_0 = arg0
        arg0 = (c2fb_temp_0 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    While isConsonant(arg0)
        c2fb_temp_1 = arg0
        arg0 = (c2fb_temp_1 + 1)
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    Return (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) <> Cast(c2fb_c_int, &O0ULL)))))
End Function
Private Function m_eq_1 CDecl Alias "m_eq_1" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr

    While isVowel(arg0)
        c2fb_temp_0 = arg0
        arg0 = (c2fb_temp_0 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    While isConsonant(arg0)
        c2fb_temp_1 = arg0
        arg0 = (c2fb_temp_1 + 1)
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    While isVowel(arg0)
        c2fb_temp_2 = arg0
        arg0 = (c2fb_temp_2 + 1)
    c2fb_flow_5:
    Wend
    c2fb_flow_4:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    While isConsonant(arg0)
        c2fb_temp_3 = arg0
        arg0 = (c2fb_temp_3 + 1)
    c2fb_flow_7:
    Wend
    c2fb_flow_6:
    Return (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) = Cast(c2fb_c_int, &O0ULL)))))
End Function
Private Function m_gt_1 CDecl Alias "m_gt_1" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr

    While isVowel(arg0)
        c2fb_temp_0 = arg0
        arg0 = (c2fb_temp_0 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    While isConsonant(arg0)
        c2fb_temp_1 = arg0
        arg0 = (c2fb_temp_1 + 1)
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    While isVowel(arg0)
        c2fb_temp_2 = arg0
        arg0 = (c2fb_temp_2 + 1)
    c2fb_flow_5:
    Wend
    c2fb_flow_4:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    While isConsonant(arg0)
        c2fb_temp_3 = arg0
        arg0 = (c2fb_temp_3 + 1)
    c2fb_flow_7:
    Wend
    c2fb_flow_6:
    Return (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) <> Cast(c2fb_c_int, &O0ULL)))))
End Function
Private Function hasVowel CDecl Alias "hasVowel" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim c2fb_temp_0 As Const ZString Ptr

    While isConsonant(arg0)
        c2fb_temp_0 = arg0
        arg0 = (c2fb_temp_0 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) <> Cast(c2fb_c_int, &O0ULL)))))
End Function
Private Function doubleConsonant CDecl Alias "doubleConsonant" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Return (-Cast(c2fb_c_int, (((isConsonant(arg0) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]))))) <> 0)))))
End Function
Private Function star_oh CDecl Alias "star_oh" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Return (-Cast(c2fb_c_int, (((isConsonant(arg0) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 119))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 120))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 121))))) <> 0) AndAlso (isVowel(CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, arg0) + Cast(c2fb_c_int, 1ULL)))) <> 0) AndAlso (isConsonant(CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, arg0) + Cast(c2fb_c_int, 2ULL)))) <> 0)))))
End Function
Private Function stem CDecl Alias "stem" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_callback_186) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Byte Ptr
    Dim c2fb_temp_6 As Byte
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr

    local0 = (*arg0)
    While (-Cast(c2fb_c_int, ((((*CPtr(Const Byte Ptr, arg1)) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg1))) = Cast(c2fb_c_int, (*CPtr(Byte Ptr, local0))))))) <> 0)))))
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = arg1
        arg1 = (c2fb_temp_1 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg1))) <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, (((arg3 <> 0) AndAlso ((-Cast(c2fb_c_int, (arg3(CPtr(Const ZString Ptr, local0)) = 0))) <> 0))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    While (*CPtr(Const Byte Ptr, arg2))
        c2fb_temp_2 = local0
        local0 = (c2fb_temp_2 - 1)
        c2fb_temp_3 = local0
        c2fb_temp_5 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, (c2fb_temp_3)))))
        c2fb_temp_4 = arg2
        arg2 = (c2fb_temp_4 + 1)
        c2fb_temp_6 = Cast(Byte, (*CPtr(Const Byte Ptr, (c2fb_temp_4))))
        (*c2fb_temp_5) = c2fb_temp_6
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    c2fb_temp_7 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_8 = local0
    (*c2fb_temp_7) = c2fb_temp_8
    Return Cast(c2fb_c_int, 1ULL)
End Function
Private Sub copy_stemmer CDecl Alias "copy_stemmer" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As Byte
    Dim c2fb_temp_2 As Byte Ptr
    Dim c2fb_temp_3 As Byte
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Byte Ptr
    Dim c2fb_temp_6 As Byte
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Byte Ptr
    Dim c2fb_temp_13 As Byte
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Byte Ptr
    Dim c2fb_temp_16 As Byte
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        local4 = CPtr(Const Byte Ptr, arg0)[local0]
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4) >= Cast(c2fb_c_int, 65))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4) <= Cast(c2fb_c_int, 90))))) <> 0))))) Then
            c2fb_temp_2 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg2)[local0]))
            c2fb_temp_3 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, local4) - Cast(c2fb_c_int, 65))) + Cast(c2fb_c_int, 97))))
            (*c2fb_temp_2) = c2fb_temp_3
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4) <= Cast(c2fb_c_int, 57))))) <> 0))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local3 = c2fb_temp_4
            End If
            c2fb_temp_5 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg2)[local0]))
            c2fb_temp_6 = Cast(Byte, local4)
            (*c2fb_temp_5) = c2fb_temp_6
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_7 = Cast(c2fb_c_int, IIf(local3, Cast(c2fb_c_int, 3ULL), Cast(c2fb_c_int, 10ULL)))
    local1 = c2fb_temp_7
    If (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, (local1 * Cast(c2fb_c_int, 2ULL))))))) Then
        c2fb_temp_8 = Cast(c2fb_c_int, local1)
        local2 = c2fb_temp_8
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1 - local1)))
        local0 = c2fb_temp_9
        While (-Cast(c2fb_c_int, ((local0 < arg1))))
            c2fb_temp_12 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg2)[local2]))
            c2fb_temp_13 = Cast(Byte, CPtr(Byte Ptr, arg2)[local0])
            (*c2fb_temp_12) = c2fb_temp_13
        c2fb_flow_3:
            c2fb_temp_10 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
            c2fb_temp_11 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_temp_14 = Cast(c2fb_c_int, local2)
        local0 = c2fb_temp_14
    End If
    c2fb_temp_15 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg2)[local0]))
    c2fb_temp_16 = Cast(Byte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_15) = c2fb_temp_16
    c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_18 = Cast(c2fb_c_int, local0)
    (*c2fb_temp_17) = c2fb_temp_18
End Sub
Private Sub porter_stemmer CDecl Alias "porter_stemmer" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2(0 To 27) As Byte
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local5 As Byte
    Dim c2fb_temp_4 As Byte Ptr
    Dim c2fb_temp_5 As Byte
    Dim c2fb_temp_6 As Byte Ptr
    Dim c2fb_temp_7 As Byte
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As Byte Ptr
    Dim c2fb_temp_16 As Byte
    Dim c2fb_temp_17 As Byte Ptr
    Dim c2fb_temp_18 As Byte
    Dim c2fb_temp_19 As ZString Ptr
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As ZString Ptr
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As ZString Ptr
    Dim c2fb_temp_24 As ZString Ptr
    Dim c2fb_temp_25 As ZString Ptr
    Dim c2fb_temp_26 As ZString Ptr
    Dim c2fb_temp_27 As ZString Ptr
    Dim c2fb_temp_28 As ZString Ptr
    Dim c2fb_temp_29 As ZString Ptr
    Dim c2fb_temp_30 As ZString Ptr
    Dim c2fb_temp_31 As ZString Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Byte Ptr
    Dim c2fb_temp_36 As Byte
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As ZString Ptr
    Dim c2fb_temp_40 As Byte Ptr
    Dim c2fb_temp_41 As Byte

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic array storage
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= Cast(c2fb_c_int, (Cast(c2fb_c_int, Cast(c2fb_size_t, (28ULL * SizeOf(Byte)))) - Cast(c2fb_c_int, 7ULL))))))) <> 0))))) Then
        copy_stemmer(arg0, arg1, arg2, arg3)
        Return
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (28ULL * SizeOf(Byte)))) - Cast(c2fb_uint64, Cast(c2fb_c_int, 6ULL)))))
    local1 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        local5 = CPtr(Const Byte Ptr, arg0)[local0]
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local5) >= Cast(c2fb_c_int, 65))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local5) <= Cast(c2fb_c_int, 90))))) <> 0))))) Then
            c2fb_temp_4 = CPtr(Byte Ptr, @(local2(local1)))
            c2fb_temp_5 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, local5) + Cast(c2fb_c_int, 97))) - Cast(c2fb_c_int, 65))))
            (*c2fb_temp_4) = c2fb_temp_5
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local5) >= Cast(c2fb_c_int, 97))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local5) <= Cast(c2fb_c_int, 122))))) <> 0))))) Then
                c2fb_temp_6 = CPtr(Byte Ptr, @(local2(local1)))
                c2fb_temp_7 = Cast(Byte, local5)
                (*c2fb_temp_6) = c2fb_temp_7
            Else
                copy_stemmer(arg0, arg1, arg2, arg3)
                Return
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        c2fb_temp_3 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_8 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, @(local2(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (28ULL * SizeOf(Byte)))) - Cast(c2fb_uint64, Cast(c2fb_c_int, 5ULL)))))))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 5ULL)))
    c2fb_temp_9 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(local2(Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))))))
    local3 = c2fb_temp_9
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 115))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"sess"), StrPtr(!"ss"), Cast(c2fb_c_int, &O0ULL)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"sei"), StrPtr(!"i"), Cast(c2fb_c_int, &O0ULL)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ss"), StrPtr(!"ss"), Cast(c2fb_c_int, &O0ULL)) = 0))) <> 0))))) Then
            c2fb_temp_10 = local3
            local3 = (c2fb_temp_10 + 1)
        End If
    End If
    c2fb_temp_11 = local3
    local4 = c2fb_temp_11
    If stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"dee"), StrPtr(!"ee"), ProcPtr(m_gt_0)) Then
        ' empty C block
    Else
        If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, (((stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"gni"), StrPtr(!""), ProcPtr(hasVowel)) <> 0) OrElse (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"de"), StrPtr(!""), ProcPtr(hasVowel)) <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 <> local4)))) <> 0))))) Then
            If (-Cast(c2fb_c_int, (((stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ta"), StrPtr(!"ate"), Cast(c2fb_c_int, &O0ULL)) <> 0) OrElse (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"lb"), StrPtr(!"ble"), Cast(c2fb_c_int, &O0ULL)) <> 0) OrElse (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"zi"), StrPtr(!"ize"), Cast(c2fb_c_int, &O0ULL)) <> 0))))) Then
                ' empty C block
            Else
                If (-Cast(c2fb_c_int, (((doubleConsonant(CPtr(Const ZString Ptr, local3)) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local3))) <> Cast(c2fb_c_int, 108))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local3))) <> Cast(c2fb_c_int, 115))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local3))) <> Cast(c2fb_c_int, 122))))) <> 0))))) Then
                    c2fb_temp_12 = local3
                    local3 = (c2fb_temp_12 + 1)
                Else
                    If (-Cast(c2fb_c_int, (((m_eq_1(CPtr(Const ZString Ptr, local3)) <> 0) AndAlso (star_oh(CPtr(Const ZString Ptr, local3)) <> 0))))) Then
                        c2fb_temp_13 = local3
                        local3 = (c2fb_temp_13 - 1)
                        c2fb_temp_14 = local3
                        c2fb_temp_15 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, (c2fb_temp_14)))))
                        c2fb_temp_16 = Cast(Byte, Cast(c2fb_c_int, 101))
                        (*c2fb_temp_15) = c2fb_temp_16
                    End If
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 121))))) <> 0) AndAlso (hasVowel(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        c2fb_temp_17 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_18 = Cast(Byte, Cast(c2fb_c_int, 105))
        (*c2fb_temp_17) = c2fb_temp_18
    End If
    Select Case CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 1ULL)]
        Case Cast(c2fb_c_int, 97)
            If (-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"lanoita"), StrPtr(!"ate"), ProcPtr(m_gt_0)) = 0))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"lanoit"), StrPtr(!"tion"), ProcPtr(m_gt_0))
            End If
        Case Cast(c2fb_c_int, 99)
            If (-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"icne"), StrPtr(!"ence"), ProcPtr(m_gt_0)) = 0))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"icna"), StrPtr(!"ance"), ProcPtr(m_gt_0))
            End If
        Case Cast(c2fb_c_int, 101)
            stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"rezi"), StrPtr(!"ize"), ProcPtr(m_gt_0))
        Case Cast(c2fb_c_int, 103)
            stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"igol"), StrPtr(!"log"), ProcPtr(m_gt_0))
        Case Cast(c2fb_c_int, 108)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ilb"), StrPtr(!"ble"), ProcPtr(m_gt_0)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"illa"), StrPtr(!"al"), ProcPtr(m_gt_0)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"iltne"), StrPtr(!"ent"), ProcPtr(m_gt_0)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ile"), StrPtr(!"e"), ProcPtr(m_gt_0)) = 0))) <> 0))))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ilsuo"), StrPtr(!"ous"), ProcPtr(m_gt_0))
            End If
        Case Cast(c2fb_c_int, 111)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"noitazi"), StrPtr(!"ize"), ProcPtr(m_gt_0)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"noita"), StrPtr(!"ate"), ProcPtr(m_gt_0)) = 0))) <> 0))))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"rota"), StrPtr(!"ate"), ProcPtr(m_gt_0))
            End If
        Case Cast(c2fb_c_int, 115)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"msila"), StrPtr(!"al"), ProcPtr(m_gt_0)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ssenevi"), StrPtr(!"ive"), ProcPtr(m_gt_0)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ssenluf"), StrPtr(!"ful"), ProcPtr(m_gt_0)) = 0))) <> 0))))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ssensuo"), StrPtr(!"ous"), ProcPtr(m_gt_0))
            End If
        Case Cast(c2fb_c_int, 116)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"itila"), StrPtr(!"al"), ProcPtr(m_gt_0)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"itivi"), StrPtr(!"ive"), ProcPtr(m_gt_0)) = 0))) <> 0))))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"itilib"), StrPtr(!"ble"), ProcPtr(m_gt_0))
            End If
    End Select
    c2fb_flow_2:
    Select Case CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]
        Case Cast(c2fb_c_int, 101)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"etaci"), StrPtr(!"ic"), ProcPtr(m_gt_0)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"evita"), StrPtr(!""), ProcPtr(m_gt_0)) = 0))) <> 0))))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ezila"), StrPtr(!"al"), ProcPtr(m_gt_0))
            End If
        Case Cast(c2fb_c_int, 105)
            stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"itici"), StrPtr(!"ic"), ProcPtr(m_gt_0))
        Case Cast(c2fb_c_int, 108)
            If (-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"laci"), StrPtr(!"ic"), ProcPtr(m_gt_0)) = 0))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"luf"), StrPtr(!""), ProcPtr(m_gt_0))
            End If
        Case Cast(c2fb_c_int, 115)
            stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"ssen"), StrPtr(!""), ProcPtr(m_gt_0))
    End Select
    c2fb_flow_3:
    Select Case CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 1ULL)]
        Case Cast(c2fb_c_int, 97)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 108))))) <> 0) AndAlso (m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                c2fb_temp_19 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 2ULL)))
                local3 = c2fb_temp_19
            End If
        Case Cast(c2fb_c_int, 99)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 101))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 2ULL)]) = Cast(c2fb_c_int, 110))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 3ULL)]) = Cast(c2fb_c_int, 97))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 3ULL)]) = Cast(c2fb_c_int, 101))))) <> 0)))))) <> 0) AndAlso (m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                c2fb_temp_20 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 4ULL)))
                local3 = c2fb_temp_20
            End If
        Case Cast(c2fb_c_int, 101)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 114))))) <> 0) AndAlso (m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                c2fb_temp_21 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 2ULL)))
                local3 = c2fb_temp_21
            End If
        Case Cast(c2fb_c_int, 105)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 99))))) <> 0) AndAlso (m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                c2fb_temp_22 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 2ULL)))
                local3 = c2fb_temp_22
            End If
        Case Cast(c2fb_c_int, 108)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 101))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 2ULL)]) = Cast(c2fb_c_int, 98))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 3ULL)]) = Cast(c2fb_c_int, 97))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 3ULL)]) = Cast(c2fb_c_int, 105))))) <> 0)))))) <> 0) AndAlso (m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                c2fb_temp_23 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 4ULL)))
                local3 = c2fb_temp_23
            End If
        Case Cast(c2fb_c_int, 110)
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 116))))) Then
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 2ULL)]) = Cast(c2fb_c_int, 97))))) Then
                    If m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 3ULL))))) Then
                        c2fb_temp_24 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 3ULL)))
                        local3 = c2fb_temp_24
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 2ULL)]) = Cast(c2fb_c_int, 101))))) Then
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"tneme"), StrPtr(!""), ProcPtr(m_gt_1)) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"tnem"), StrPtr(!""), ProcPtr(m_gt_1)) = 0))) <> 0))))) Then
                            stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"tne"), StrPtr(!""), ProcPtr(m_gt_1))
                        End If
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 111)
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 117))))) Then
                If m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 2ULL))))) Then
                    c2fb_temp_25 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 2ULL)))
                    local3 = c2fb_temp_25
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 3ULL)]) = Cast(c2fb_c_int, 115))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 3ULL)]) = Cast(c2fb_c_int, 116))))) <> 0))))) Then
                    stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"noi"), StrPtr(!""), ProcPtr(m_gt_1))
                End If
            End If
        Case Cast(c2fb_c_int, 115)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 109))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 2ULL)]) = Cast(c2fb_c_int, 105))))) <> 0) AndAlso (m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
                c2fb_temp_26 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 3ULL)))
                local3 = c2fb_temp_26
            End If
        Case Cast(c2fb_c_int, 116)
            If (-Cast(c2fb_c_int, (stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"eta"), StrPtr(!""), ProcPtr(m_gt_1)) = 0))) Then
                stem(CPtr(ZString Ptr Ptr, @(local3)), StrPtr(!"iti"), StrPtr(!""), ProcPtr(m_gt_1))
            End If
        Case Cast(c2fb_c_int, 117)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 115))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 2ULL)]) = Cast(c2fb_c_int, 111))))) <> 0) AndAlso (m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
                c2fb_temp_27 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 3ULL)))
                local3 = c2fb_temp_27
            End If
        Case Cast(c2fb_c_int, 118), Cast(c2fb_c_int, 122)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 101))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 2ULL)]) = Cast(c2fb_c_int, 105))))) <> 0) AndAlso (m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
                c2fb_temp_28 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 3ULL)))
                local3 = c2fb_temp_28
            End If
    End Select
    c2fb_flow_4:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 101))))) Then
        If m_gt_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_29 = local3
            local3 = (c2fb_temp_29 + 1)
        Else
            If (-Cast(c2fb_c_int, (((m_eq_1(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (star_oh(CPtr(Const ZString Ptr, CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) + Cast(c2fb_c_int, 1ULL))))) = 0))) <> 0))))) Then
                c2fb_temp_30 = local3
                local3 = (c2fb_temp_30 + 1)
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, (((m_gt_1(CPtr(Const ZString Ptr, local3)) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 108))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local3)[Cast(c2fb_c_int, 1ULL)]) = Cast(c2fb_c_int, 108))))) <> 0))))) Then
        c2fb_temp_31 = local3
        local3 = (c2fb_temp_31 + 1)
    End If
    c2fb_temp_33 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(CPtr(Const ZString Ptr, local3))))
    local0 = c2fb_temp_32
    c2fb_temp_34 = Cast(c2fb_c_int, c2fb_temp_32)
    (*c2fb_temp_33) = c2fb_temp_34
    c2fb_temp_35 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg2)[local0]))
    c2fb_temp_36 = Cast(Byte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_35) = c2fb_temp_36
    While (*CPtr(Byte Ptr, local3))
        c2fb_temp_37 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_37 - 1)))
        c2fb_temp_38 = local0
        c2fb_temp_40 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg2)[c2fb_temp_38]))
        c2fb_temp_39 = local3
        local3 = (c2fb_temp_39 + 1)
        c2fb_temp_41 = Cast(Byte, (*CPtr(Byte Ptr, (c2fb_temp_39))))
        (*c2fb_temp_40) = c2fb_temp_41
    c2fb_flow_6:
    Wend
    c2fb_flow_5:
End Sub
Private Function porterNext CDecl Alias "porterNext" (ByVal arg0 As c2fb_source_record_182 Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_porter.c
    Dim local0 As c2fb_source_record_195 Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim local6 As ZString Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As ZString Ptr
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

    local0 = CPtr(c2fb_source_record_195 Ptr, arg0)
    local1 = local0->zInput
    While (-Cast(c2fb_c_int, ((local0->iOffset < local0->nInput))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        Do
            c2fb_temp_1 = 0
            If ((-Cast(c2fb_c_int, ((local0->iOffset < local0->nInput)))) <> 0) Then
                c2fb_temp_0 = Cast(c2fb_c_int, CPtr(Const Byte Ptr, local1)[local0->iOffset])
                local3 = c2fb_temp_0
                c2fb_temp_1 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, ((c2fb_temp_0) And Cast(c2fb_c_int, &H80ULL)))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_int, &H30ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, (c2fb_global_porterIdChar(Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, &H30ULL)))) = 0))) <> 0)))))) <> 0))))
            End If
            If (c2fb_temp_1 = 0) Then Goto c2fb_flow_2
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(local0->iOffset))
            c2fb_temp_3 = (*c2fb_temp_2)
            (*c2fb_temp_2) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        c2fb_flow_3:
        Loop
        c2fb_flow_2:
        c2fb_temp_4 = Cast(c2fb_c_int, local0->iOffset)
        local2 = c2fb_temp_4
        Do
            c2fb_temp_6 = 0
            If ((-Cast(c2fb_c_int, ((local0->iOffset < local0->nInput)))) <> 0) Then
                c2fb_temp_5 = Cast(c2fb_c_int, CPtr(Const Byte Ptr, local1)[local0->iOffset])
                local3 = c2fb_temp_5
                c2fb_temp_6 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, ((c2fb_temp_5) And Cast(c2fb_c_int, &H80ULL)))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_int, &H30ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, (c2fb_global_porterIdChar(Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, &H30ULL)))) = 0))) <> 0)))))) <> 0)))))) = 0))) <> 0))))
            End If
            If (c2fb_temp_6 = 0) Then Goto c2fb_flow_4
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local0->iOffset))
            c2fb_temp_8 = (*c2fb_temp_7)
            (*c2fb_temp_7) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
        c2fb_flow_5:
        Loop
        c2fb_flow_4:
        If (-Cast(c2fb_c_int, ((local0->iOffset > local2)))) Then
            local4 = Cast(c2fb_c_int, (local0->iOffset - local2))
            If (-Cast(c2fb_c_int, ((local4 > local0->nAllocated)))) Then
                local5 = Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 20ULL)))
                ' C automatic storage declaration
                c2fb_temp_9 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local0->zToken), local5)))
                local6 = c2fb_temp_9
                If (-Cast(c2fb_c_int, (local6 = 0))) Then
                    Return Cast(c2fb_c_int, 7ULL)
                End If
                c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(local0->nAllocated))
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, local5))
                (*c2fb_temp_10) = c2fb_temp_11
                c2fb_temp_12 = CPtr(ZString Ptr Ptr, @(local0->zToken))
                c2fb_temp_13 = local6
                (*c2fb_temp_12) = c2fb_temp_13
            End If
            porter_stemmer(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local1)[local2]))), local4, local0->zToken, arg2)
            c2fb_temp_14 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
            c2fb_temp_15 = CPtr(Const ZString Ptr, local0->zToken)
            (*c2fb_temp_14) = c2fb_temp_15
            c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_17 = Cast(c2fb_c_int, local2)
            (*c2fb_temp_16) = c2fb_temp_17
            c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg4)))
            c2fb_temp_19 = Cast(c2fb_c_int, local0->iOffset)
            (*c2fb_temp_18) = c2fb_temp_19
            c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @((*arg5)))
            c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @(local0->iToken))
            c2fb_temp_21 = (*c2fb_temp_20)
            (*c2fb_temp_20) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
            c2fb_temp_23 = Cast(c2fb_c_int, c2fb_temp_21)
            (*c2fb_temp_22) = c2fb_temp_23
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, 101ULL)
End Function
/' ------------------------------------------------------------------------- '/
/' Porter tokenizer module registration                                      '/
/' ------------------------------------------------------------------------- '/
/'
    The C module table contains callback addresses only. Tokenizer and cursor
    state remain owned by the create/open and destroy/close callbacks above.
'/
Private Dim Shared As Const Fts3TokenizerModule porterTokenizerModule = _
    Type<Fts3TokenizerModule>( _
        0, _
        Cast(Fts3TokenizerCreateProc, ProcPtr(porterCreate)), _
        Cast(Fts3TokenizerDestroyProc, ProcPtr(porterDestroy)), _
        Cast(Fts3TokenizerOpenProc, ProcPtr(porterOpen)), _
        Cast(Fts3TokenizerCloseProc, ProcPtr(porterClose)), _
        Cast(Fts3TokenizerNextProc, ProcPtr(porterNext)), _
        Cast(Fts3TokenizerLanguageidProc, 0) _
    )

Sub sqlite3Fts3PorterTokenizerModule CDecl Alias "sqlite3Fts3PorterTokenizerModule" ( _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr _
)
    If CPtr(Any Ptr, ppModule) <> 0 Then *ppModule = @porterTokenizerModule
End Sub
#endif

/' end of sqlite3_bulk_fts3_porter.bas '/
