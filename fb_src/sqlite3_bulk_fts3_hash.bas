/'
** 2001 September 22
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

    File: sqlite3_bulk_fts3_hash.bas

    Purpose:

        Port SQLite's FTS3 hash-table implementation from ext/fts3/fts3_hash.c.

    Responsibilities:

        - Allocate and release hash entries through SQLite's allocator.
        - Maintain the global element list and hash bucket chains.
        - Find, insert, replace, and remove string or binary keys.

    This file intentionally does NOT contain:

        - FTS3 virtual-table registration or tokenizer implementations.
        - Test support.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
#include once "sqlite3_types.bi"
#include once "sqlite3_fts3_hash_types.bi"

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

Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_crt_strncmp CDecl Alias "strncmp" ( ByVal leftText As Const ZString Ptr, ByVal rightText As Const ZString Ptr, ByVal byteCount As SQLITE_SIZE_T ) As SQLITE_C_INT

Type c2fb_callback_2 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As SQLITE_C_INT) As SQLITE_C_INT
Type c2fb_callback_217 As Function CDecl(ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_218 As Function CDecl(ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int




Declare Function fts3HashMalloc CDecl Alias "fts3HashMalloc" (ByVal arg0 As c2fb_int64) As Any Ptr
Declare Sub fts3HashFree CDecl Alias "fts3HashFree" (ByVal arg0 As Any Ptr)
Declare Function fts3StrHash CDecl Alias "fts3StrHash" (ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3StrCompare CDecl Alias "fts3StrCompare" (ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function fts3BinHash CDecl Alias "fts3BinHash" (ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3BinCompare CDecl Alias "fts3BinCompare" (ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function ftsHashFunction CDecl Alias "ftsHashFunction" (ByVal arg0 As c2fb_c_int) As Function CDecl(ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function ftsCompareFunction CDecl Alias "ftsCompareFunction" (ByVal arg0 As c2fb_c_int) As Function CDecl(ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Sub fts3HashInsertElement CDecl Alias "fts3HashInsertElement" (ByVal arg0 As Fts3Hash Ptr, ByVal arg1 As Fts3HashBucket Ptr, ByVal arg2 As Fts3HashElem Ptr)
Declare Function fts3Rehash CDecl Alias "fts3Rehash" (ByVal arg0 As Fts3Hash Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3FindElementByHash CDecl Alias "fts3FindElementByHash" (ByVal arg0 As Const Fts3Hash Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As Fts3HashElem Ptr
Declare Sub fts3RemoveElementByHash CDecl Alias "fts3RemoveElementByHash" (ByVal arg0 As Fts3Hash Ptr, ByVal arg1 As Fts3HashElem Ptr, ByVal arg2 As c2fb_c_int)
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
Private Function fts3HashMalloc CDecl Alias "fts3HashMalloc" (ByVal arg0 As c2fb_int64) As Any Ptr
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As Any Ptr

    local0 = CPtr(Any Ptr, sqlite3_malloc64(arg0))
    If local0 Then
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(local0, Cast(c2fb_c_int, &O0ULL), arg0))
    End If
    Return local0
End Function
Private Sub fts3HashFree CDecl Alias "fts3HashFree" (ByVal arg0 As Any Ptr)
' c2fb source-path: ext/fts3/fts3_hash.c
    sqlite3_free(arg0)
End Sub
Sub sqlite3Fts3HashInit CDecl Alias "sqlite3Fts3HashInit" (ByVal arg0 As Fts3Hash Ptr, ByVal arg1 As Byte, ByVal arg2 As Byte)
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim c2fb_temp_0 As Byte Ptr
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As Byte Ptr
    Dim c2fb_temp_3 As Byte
    Dim c2fb_temp_4 As Any Ptr Ptr
    Dim c2fb_temp_5 As Fts3HashElem Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Fts3HashBucket Ptr Ptr
    Dim c2fb_temp_11 As Fts3HashBucket Ptr

    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Byte Ptr, @(arg0->keyClass))
    c2fb_temp_1 = Cast(Byte, arg1)
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(Byte Ptr, @(arg0->copyKey))
    c2fb_temp_3 = Cast(Byte, arg2)
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(Any Ptr Ptr, @(arg0->first))
    c2fb_temp_5 = CPtr(Fts3HashElem Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_4) = CPtr(Any Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg0->count))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(arg0->htsize))
    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(Fts3HashBucket Ptr Ptr, @(arg0->ht))
    c2fb_temp_11 = CPtr(Fts3HashBucket Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_10) = c2fb_temp_11
End Sub
Sub sqlite3Fts3HashClear CDecl Alias "sqlite3Fts3HashClear" (ByVal arg0 As Fts3Hash Ptr)
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As Fts3HashElem Ptr
    Dim c2fb_temp_0 As Fts3HashElem Ptr
    Dim c2fb_temp_1 As Any Ptr Ptr
    Dim c2fb_temp_2 As Fts3HashElem Ptr
    Dim c2fb_temp_3 As Fts3HashBucket Ptr Ptr
    Dim c2fb_temp_4 As Fts3HashBucket Ptr
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local1 As Fts3HashElem Ptr
    Dim c2fb_temp_7 As Fts3HashElem Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Fts3HashElem Ptr, arg0->first)
    local0 = c2fb_temp_0
    c2fb_temp_1 = CPtr(Any Ptr Ptr, @(arg0->first))
    c2fb_temp_2 = CPtr(Fts3HashElem Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_1) = CPtr(Any Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_1))
    fts3HashFree(CPtr(Any Ptr, arg0->ht))
    c2fb_temp_3 = CPtr(Fts3HashBucket Ptr Ptr, @(arg0->ht))
    c2fb_temp_4 = CPtr(Fts3HashBucket Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg0->htsize))
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_5) = c2fb_temp_6
    While local0
        local1 = local0->next
        If (-Cast(c2fb_c_int, (((arg0->copyKey <> 0) AndAlso (local0->pKey <> 0))))) Then
            fts3HashFree(local0->pKey)
        End If
        fts3HashFree(CPtr(Any Ptr, local0))
        c2fb_temp_7 = local1
        local0 = c2fb_temp_7
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(arg0->count))
    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_8) = c2fb_temp_9
End Sub
Private Function fts3StrHash CDecl Alias "fts3StrHash" (ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = CPtr(Const ZString Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg1 <= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(local0)))
        arg1 = c2fb_temp_0
    End If
    While (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, &O0ULL)))))
        c2fb_temp_2 = Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 3ULL)))) Xor local1))
        c2fb_temp_1 = local0
        local0 = (c2fb_temp_1 + 1)
        c2fb_temp_3 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_2 Xor Cast(c2fb_c_uint, (*CPtr(Const Byte Ptr, c2fb_temp_1))))))
        local1 = c2fb_temp_3
        c2fb_temp_4 = arg1
        arg1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 - 1)))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7fffffffULL))))))
End Function
Private Function fts3StrCompare CDecl Alias "fts3StrCompare" (ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_hash.c
    If (-Cast(c2fb_c_int, ((arg1 <> arg3)))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return c2fb_crt_strncmp(CPtr(Const ZString Ptr, arg0), CPtr(Const ZString Ptr, arg2), arg1)
End Function
Private Function fts3BinHash CDecl Alias "fts3BinHash" (ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(Const ZString Ptr, arg0)
    Do
        c2fb_temp_0 = arg1
        arg1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 - 1)))
        If ((-Cast(c2fb_c_int, ((c2fb_temp_0 > Cast(c2fb_c_int, &O0ULL))))) = 0) Then Goto c2fb_flow_0
        c2fb_temp_2 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0 Shl Cast(c2fb_c_int, 3ULL)))) Xor local0))
        c2fb_temp_1 = local1
        local1 = (c2fb_temp_1 + 1)
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 Xor Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, (c2fb_temp_1)))))))
        local0 = c2fb_temp_3
    c2fb_flow_1:
    Loop
    c2fb_flow_0:
    Return Cast(c2fb_c_int, (local0 And Cast(c2fb_c_int, &H7fffffffULL)))
End Function
Private Function fts3BinCompare CDecl Alias "fts3BinCompare" (ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_hash.c
    If (-Cast(c2fb_c_int, ((arg1 <> arg3)))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return c2fb_crt_memcmp(arg0, arg2, arg1)
End Function
Private Function ftsHashFunction CDecl Alias "ftsHashFunction" (ByVal arg0 As c2fb_c_int) As Function CDecl(ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_hash.c
    If (-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, 1ULL))))) Then
        Return ProcPtr(fts3StrHash)
    Else
        ' C unused-parameter annotation
        Return ProcPtr(fts3BinHash)
    End If
End Function
Private Function ftsCompareFunction CDecl Alias "ftsCompareFunction" (ByVal arg0 As c2fb_c_int) As Function CDecl(ByVal arg0 As Const Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_hash.c
    If (-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, 1ULL))))) Then
        Return ProcPtr(fts3StrCompare)
    Else
        ' C unused-parameter annotation
        Return ProcPtr(fts3BinCompare)
    End If
End Function
Private Sub fts3HashInsertElement CDecl Alias "fts3HashInsertElement" (ByVal arg0 As Fts3Hash Ptr, ByVal arg1 As Fts3HashBucket Ptr, ByVal arg2 As Fts3HashElem Ptr)
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As Fts3HashElem Ptr
    Dim c2fb_temp_0 As Fts3HashElem Ptr
    Dim c2fb_temp_1 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_2 As Fts3HashElem Ptr
    Dim c2fb_temp_3 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_4 As Fts3HashElem Ptr
    Dim c2fb_temp_5 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_6 As Fts3HashElem Ptr
    Dim c2fb_temp_7 As Any Ptr Ptr
    Dim c2fb_temp_8 As Fts3HashElem Ptr
    Dim c2fb_temp_9 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_10 As Fts3HashElem Ptr
    Dim c2fb_temp_11 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_12 As Fts3HashElem Ptr
    Dim c2fb_temp_13 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_14 As Fts3HashElem Ptr
    Dim c2fb_temp_15 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_16 As Fts3HashElem Ptr
    Dim c2fb_temp_17 As Any Ptr Ptr
    Dim c2fb_temp_18 As Fts3HashElem Ptr
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Any Ptr Ptr
    Dim c2fb_temp_22 As Fts3HashElem Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Fts3HashElem Ptr, arg1->chain)
    local0 = c2fb_temp_0
    If local0 Then
        c2fb_temp_1 = CPtr(Fts3HashElem Ptr Ptr, @(arg2->next))
        c2fb_temp_2 = local0
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(Fts3HashElem Ptr Ptr, @(arg2->prev))
        c2fb_temp_4 = local0->prev
        (*c2fb_temp_3) = c2fb_temp_4
        If local0->prev Then
            c2fb_temp_5 = CPtr(Fts3HashElem Ptr Ptr, @(local0->prev->next))
            c2fb_temp_6 = arg2
            (*c2fb_temp_5) = c2fb_temp_6
        Else
            c2fb_temp_7 = CPtr(Any Ptr Ptr, @(arg0->first))
            c2fb_temp_8 = arg2
            (*c2fb_temp_7) = CPtr(Any Ptr, c2fb_temp_8)
            c2fb_temp_8 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_7))
        End If
        c2fb_temp_9 = CPtr(Fts3HashElem Ptr Ptr, @(local0->prev))
        c2fb_temp_10 = arg2
        (*c2fb_temp_9) = c2fb_temp_10
    Else
        c2fb_temp_11 = CPtr(Fts3HashElem Ptr Ptr, @(arg2->next))
        c2fb_temp_12 = CPtr(Fts3HashElem Ptr, arg0->first)
        (*c2fb_temp_11) = c2fb_temp_12
        If CPtr(Fts3HashElem Ptr, arg0->first) Then
            c2fb_temp_13 = CPtr(Fts3HashElem Ptr Ptr, @(CPtr(Fts3HashElem Ptr, arg0->first)->prev))
            c2fb_temp_14 = arg2
            (*c2fb_temp_13) = c2fb_temp_14
        End If
        c2fb_temp_15 = CPtr(Fts3HashElem Ptr Ptr, @(arg2->prev))
        c2fb_temp_16 = CPtr(Fts3HashElem Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_15) = c2fb_temp_16
        c2fb_temp_17 = CPtr(Any Ptr Ptr, @(arg0->first))
        c2fb_temp_18 = arg2
        (*c2fb_temp_17) = CPtr(Any Ptr, c2fb_temp_18)
        c2fb_temp_18 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_17))
    End If
    c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @(arg1->count))
    c2fb_temp_20 = (*c2fb_temp_19)
    (*c2fb_temp_19) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 + 1)))
    c2fb_temp_21 = CPtr(Any Ptr Ptr, @(arg1->chain))
    c2fb_temp_22 = arg2
    (*c2fb_temp_21) = CPtr(Any Ptr, c2fb_temp_22)
    c2fb_temp_22 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_21))
End Sub
Private Function fts3Rehash CDecl Alias "fts3Rehash" (ByVal arg0 As Fts3Hash Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As Fts3HashBucket Ptr
    Dim local1 As Fts3HashElem Ptr
    Dim local2 As Fts3HashElem Ptr
    Dim local3 As c2fb_callback_217
    Dim c2fb_temp_0 As Fts3HashBucket Ptr
    Dim c2fb_temp_1 As Fts3HashBucket Ptr Ptr
    Dim c2fb_temp_2 As Fts3HashBucket Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_callback_217
    Dim c2fb_temp_6 As Fts3HashElem Ptr
    Dim c2fb_temp_7 As Any Ptr Ptr
    Dim c2fb_temp_8 As Fts3HashElem Ptr
    Dim c2fb_temp_9 As Fts3HashElem Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_10 As Fts3HashElem Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic callback storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Fts3HashBucket Ptr, CPtr(Any Ptr, fts3HashMalloc(Cast(c2fb_uint64, (Cast(c2fb_uint64, arg1) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Fts3HashBucket))))))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    fts3HashFree(CPtr(Any Ptr, arg0->ht))
    c2fb_temp_1 = CPtr(Fts3HashBucket Ptr Ptr, @(arg0->ht))
    c2fb_temp_2 = local0
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg0->htsize))
    c2fb_temp_4 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(c2fb_callback_217, CPtr(Any Ptr, ftsHashFunction(arg0->keyClass)))
    local3 = c2fb_temp_5
    c2fb_temp_6 = CPtr(Fts3HashElem Ptr, arg0->first)
    local1 = c2fb_temp_6
    c2fb_temp_7 = CPtr(Any Ptr Ptr, @(arg0->first))
    c2fb_temp_8 = CPtr(Fts3HashElem Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_7) = CPtr(Any Ptr, c2fb_temp_8)
    c2fb_temp_8 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_7))
    While local1
        local4 = Cast(c2fb_c_int, ((local3)(CPtr(Const Any Ptr, local1->pKey), local1->nKey) And (Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL))))))
        c2fb_temp_10 = local1->next
        local2 = c2fb_temp_10
        fts3HashInsertElement(arg0, CPtr(Fts3HashBucket Ptr, @(local0[local4])), local1)
    c2fb_flow_1:
        c2fb_temp_9 = local2
        local1 = c2fb_temp_9
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3FindElementByHash CDecl Alias "fts3FindElementByHash" (ByVal arg0 As Const Fts3Hash Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As Fts3HashElem Ptr
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As Fts3HashElem Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_callback_218
    Dim local3 As Fts3HashBucket Ptr
    Dim c2fb_temp_0 As Fts3HashElem Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_callback_218
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Fts3HashElem Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic callback storage declaration
    If arg0->ht Then
        local3 = CPtr(Fts3HashBucket Ptr, @(arg0->ht[arg3]))
        c2fb_temp_0 = CPtr(Fts3HashElem Ptr, local3->chain)
        local0 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, local3->count)
        local1 = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_callback_218, CPtr(Any Ptr, ftsCompareFunction(arg0->keyClass)))
        local2 = c2fb_temp_2
        Do
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
            If ((-Cast(c2fb_c_int, (((c2fb_temp_3 <> 0) AndAlso (local0 <> 0))))) = 0) Then Goto c2fb_flow_0
            If (-Cast(c2fb_c_int, (((local2)(CPtr(Const Any Ptr, local0->pKey), local0->nKey, arg1, arg2) = Cast(c2fb_c_int, &O0ULL))))) Then
                Return local0
            End If
            c2fb_temp_4 = local0->next
            local0 = c2fb_temp_4
        c2fb_flow_1:
        Loop
        c2fb_flow_0:
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts3RemoveElementByHash CDecl Alias "fts3RemoveElementByHash" (ByVal arg0 As Fts3Hash Ptr, ByVal arg1 As Fts3HashElem Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As Fts3HashBucket Ptr
    Dim c2fb_temp_0 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_1 As Fts3HashElem Ptr
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As Fts3HashElem Ptr
    Dim c2fb_temp_4 As Fts3HashElem Ptr Ptr
    Dim c2fb_temp_5 As Fts3HashElem Ptr
    Dim c2fb_temp_6 As Fts3HashBucket Ptr
    Dim c2fb_temp_7 As Any Ptr Ptr
    Dim c2fb_temp_8 As Fts3HashElem Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Any Ptr Ptr
    Dim c2fb_temp_12 As Fts3HashElem Ptr
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int

    ' C automatic storage declaration
    If arg1->prev Then
        c2fb_temp_0 = CPtr(Fts3HashElem Ptr Ptr, @(arg1->prev->next))
        c2fb_temp_1 = arg1->next
        (*c2fb_temp_0) = c2fb_temp_1
    Else
        c2fb_temp_2 = CPtr(Any Ptr Ptr, @(arg0->first))
        c2fb_temp_3 = arg1->next
        (*c2fb_temp_2) = CPtr(Any Ptr, c2fb_temp_3)
        c2fb_temp_3 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_2))
    End If
    If arg1->next Then
        c2fb_temp_4 = CPtr(Fts3HashElem Ptr Ptr, @(arg1->next->prev))
        c2fb_temp_5 = arg1->prev
        (*c2fb_temp_4) = c2fb_temp_5
    End If
    c2fb_temp_6 = CPtr(Fts3HashBucket Ptr, @(arg0->ht[arg2]))
    local0 = c2fb_temp_6
    If (-Cast(c2fb_c_int, ((CPtr(Fts3HashElem Ptr, local0->chain) = arg1)))) Then
        c2fb_temp_7 = CPtr(Any Ptr Ptr, @(local0->chain))
        c2fb_temp_8 = arg1->next
        (*c2fb_temp_7) = CPtr(Any Ptr, c2fb_temp_8)
        c2fb_temp_8 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_7))
    End If
    c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(local0->count))
    c2fb_temp_10 = (*c2fb_temp_9)
    (*c2fb_temp_9) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 - 1)))
    If (-Cast(c2fb_c_int, ((local0->count <= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_11 = CPtr(Any Ptr Ptr, @(local0->chain))
        c2fb_temp_12 = CPtr(Fts3HashElem Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_11) = CPtr(Any Ptr, c2fb_temp_12)
        c2fb_temp_12 = CPtr(Fts3HashElem Ptr, (*c2fb_temp_11))
    End If
    If (-Cast(c2fb_c_int, (((arg0->copyKey <> 0) AndAlso (arg1->pKey <> 0))))) Then
        fts3HashFree(arg1->pKey)
    End If
    fts3HashFree(CPtr(Any Ptr, arg1))
    c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @(arg0->count))
    c2fb_temp_14 = (*c2fb_temp_13)
    (*c2fb_temp_13) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 - 1)))
    If (-Cast(c2fb_c_int, ((arg0->count <= Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        sqlite3Fts3HashClear(arg0)
    End If
End Sub
Function sqlite3Fts3HashFindElem CDecl Alias "sqlite3Fts3HashFindElem" (ByVal arg0 As Const Fts3Hash Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int) As Fts3HashElem Ptr
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_callback_217
    Dim c2fb_temp_0 As c2fb_callback_217
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic callback storage declaration
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->ht = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_0 = CPtr(c2fb_callback_217, CPtr(Any Ptr, ftsHashFunction(arg0->keyClass)))
    local1 = c2fb_temp_0
    ' C unused-parameter annotation
    c2fb_temp_1 = Cast(c2fb_c_int, (local1)(arg1, arg2))
    local0 = c2fb_temp_1
    ' C unused-parameter annotation
    Return CPtr(Fts3HashElem Ptr, fts3FindElementByHash(arg0, arg1, arg2, Cast(c2fb_c_int, (local0 And (Cast(c2fb_c_int, (arg0->htsize - Cast(c2fb_c_int, 1ULL))))))))
End Function
Function sqlite3Fts3HashFind CDecl Alias "sqlite3Fts3HashFind" (ByVal arg0 As Const Fts3Hash Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int) As Any Ptr
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As Fts3HashElem Ptr
    Dim c2fb_temp_0 As Fts3HashElem Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Fts3HashElem Ptr, sqlite3Fts3HashFindElem(arg0, arg1, arg2))
    local0 = c2fb_temp_0
    Return IIf(local0, local0->data, CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))
End Function
Function sqlite3Fts3HashInsert CDecl Alias "sqlite3Fts3HashInsert" (ByVal arg0 As Fts3Hash Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr) As Any Ptr
' c2fb source-path: ext/fts3/fts3_hash.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As Fts3HashElem Ptr
    Dim local3 As Fts3HashElem Ptr
    Dim local4 As c2fb_callback_217
    Dim c2fb_temp_0 As c2fb_callback_217
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Fts3HashElem Ptr
    Dim local5 As Any Ptr
    Dim c2fb_temp_4 As Any Ptr Ptr
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Fts3HashElem Ptr
    Dim c2fb_temp_9 As Any Ptr Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As Any Ptr Ptr
    Dim c2fb_temp_13 As Any Ptr
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Any Ptr Ptr
    Dim c2fb_temp_20 As Any Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic callback storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_callback_217, CPtr(Any Ptr, ftsHashFunction(arg0->keyClass)))
    local4 = c2fb_temp_0
    ' C unused-parameter annotation
    c2fb_temp_1 = Cast(c2fb_c_int, (local4)(arg1, arg2))
    local0 = c2fb_temp_1
    ' C unused-parameter annotation
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 And (Cast(c2fb_c_int, (arg0->htsize - Cast(c2fb_c_int, 1ULL)))))))
    local1 = c2fb_temp_2
    c2fb_temp_3 = CPtr(Fts3HashElem Ptr, fts3FindElementByHash(CPtr(Const Fts3Hash Ptr, arg0), arg1, arg2, local1))
    local2 = c2fb_temp_3
    If local2 Then
        local5 = local2->data
        If (-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL))))) Then
            fts3RemoveElementByHash(arg0, local2, local1)
        Else
            c2fb_temp_4 = CPtr(Any Ptr Ptr, @(local2->data))
            c2fb_temp_5 = arg3
            (*c2fb_temp_4) = c2fb_temp_5
        End If
        Return local5
    End If
    If (-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->htsize = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (fts3Rehash(arg0, Cast(c2fb_c_int, 8ULL)) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->count >= arg0->htsize)))) <> 0) AndAlso (fts3Rehash(arg0, Cast(c2fb_c_int, (arg0->htsize * Cast(c2fb_c_int, 2ULL)))) <> 0)))))) <> 0))))) Then
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg0->count))
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_6) = c2fb_temp_7
        Return arg3
    End If
    ' C unused-parameter annotation
    c2fb_temp_8 = CPtr(Fts3HashElem Ptr, CPtr(Any Ptr, fts3HashMalloc(Cast(c2fb_size_t, SizeOf(Fts3HashElem)))))
    local3 = c2fb_temp_8
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return arg3
    End If
    If (-Cast(c2fb_c_int, (((arg0->copyKey <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_9 = CPtr(Any Ptr Ptr, @(local3->pKey))
        c2fb_temp_10 = CPtr(Any Ptr, fts3HashMalloc(arg2))
        (*c2fb_temp_9) = c2fb_temp_10
        If (-Cast(c2fb_c_int, ((local3->pKey = Cast(c2fb_c_int, &O0ULL))))) Then
            fts3HashFree(CPtr(Any Ptr, local3))
            Return arg3
        End If
        c2fb_temp_11 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local3->pKey), arg1, arg2))
    Else
        c2fb_temp_12 = CPtr(Any Ptr Ptr, @(local3->pKey))
        c2fb_temp_13 = CPtr(Any Ptr, arg1)
        (*c2fb_temp_12) = c2fb_temp_13
    End If
    c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @(local3->nKey))
    c2fb_temp_15 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_14) = c2fb_temp_15
    c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @(arg0->count))
    c2fb_temp_17 = (*c2fb_temp_16)
    (*c2fb_temp_16) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 And (Cast(c2fb_c_int, (arg0->htsize - Cast(c2fb_c_int, 1ULL)))))))
    local1 = c2fb_temp_18
    fts3HashInsertElement(arg0, CPtr(Fts3HashBucket Ptr, @(arg0->ht[local1])), local3)
    c2fb_temp_19 = CPtr(Any Ptr Ptr, @(local3->data))
    c2fb_temp_20 = arg3
    (*c2fb_temp_19) = c2fb_temp_20
    Return Cast(c2fb_c_int, &O0ULL)
End Function
#endif

/' end of sqlite3_bulk_fts3_hash.bas '/
