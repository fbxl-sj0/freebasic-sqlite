/'
** 2014 August 11
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

    File: sqlite3_bulk_fts5_hash.bas

    Purpose:

        Port FTS5's in-memory term-to-doclist hash table.

    Responsibilities:

        - Accumulate term, rowid, column, and position data.
        - Scan hash entries in sorted term order.
        - Query and merge pending FTS5 doclists.

    This file intentionally does NOT contain:

        - FTS5 on-disk index storage or virtual-table registration.
        - Test support.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_hash_types.bi"

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


Declare Function sqlite3Fts5HashNew CDecl Alias "sqlite3Fts5HashNew" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Hash Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5HashFree CDecl Alias "sqlite3Fts5HashFree" (ByVal arg0 As c2fb_Fts5Hash Ptr)
Declare Sub sqlite3Fts5HashClear CDecl Alias "sqlite3Fts5HashClear" (ByVal arg0 As c2fb_Fts5Hash Ptr)
Declare Function fts5HashKey CDecl Alias "fts5HashKey" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_uint
Declare Function fts5HashKey2 CDecl Alias "fts5HashKey2" (ByVal arg0 As c2fb_c_int, ByVal arg1 As UByte, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_uint
Declare Function fts5HashResize CDecl Alias "fts5HashResize" (ByVal arg0 As c2fb_Fts5Hash Ptr) As c2fb_c_int
Declare Function fts5HashAddPoslistSize CDecl Alias "fts5HashAddPoslistSize" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As c2fb_Fts5HashEntry Ptr, ByVal arg2 As c2fb_Fts5HashEntry Ptr) As c2fb_c_int
Declare Function sqlite3Fts5HashWrite CDecl Alias "sqlite3Fts5HashWrite" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Byte, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int) As c2fb_c_int
Declare Function fts5HashEntryMerge CDecl Alias "fts5HashEntryMerge" (ByVal arg0 As c2fb_Fts5HashEntry Ptr, ByVal arg1 As c2fb_Fts5HashEntry Ptr) As c2fb_Fts5HashEntry Ptr
Declare Function fts5HashEntrySort CDecl Alias "fts5HashEntrySort" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5HashEntry Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5HashQuery CDecl Alias "sqlite3Fts5HashQuery" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts5HashScanInit CDecl Alias "sqlite3Fts5HashScanInit" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5HashIsEmpty CDecl Alias "sqlite3Fts5HashIsEmpty" (ByVal arg0 As c2fb_Fts5Hash Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5HashScanNext CDecl Alias "sqlite3Fts5HashScanNext" (ByVal arg0 As c2fb_Fts5Hash Ptr)
Declare Function sqlite3Fts5HashScanEof CDecl Alias "sqlite3Fts5HashScanEof" (ByVal arg0 As c2fb_Fts5Hash Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5HashScanEntry CDecl Alias "sqlite3Fts5HashScanEntry" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As Const UByte Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr)
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memmove CDecl Alias "memmove" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function c2fb_external_sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3Fts5GetVarintLen CDecl Alias "sqlite3Fts5GetVarintLen" (ByVal arg0 As c2fb_c_uint) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5PutVarint CDecl Alias "sqlite3Fts5PutVarint" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_uint64) As c2fb_c_int
Function sqlite3Fts5HashNew CDecl Alias "sqlite3Fts5HashNew" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Hash Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 90
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Hash Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Hash Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Hash Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Hash Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Long Ptr Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_int64
    Dim c2fb_temp_12 As c2fb_Fts5HashEntry_ Ptr Ptr Ptr
    Dim c2fb_temp_13 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_14 As c2fb_Fts5Hash Ptr Ptr
    Dim c2fb_temp_15 As c2fb_Fts5Hash Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Any Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_1 = CPtr(c2fb_Fts5Hash Ptr Ptr, @((*arg1)))
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Hash Ptr, CPtr(c2fb_Fts5Hash Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_Fts5Hash))))))
    local1 = c2fb_temp_0
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Hash Ptr, c2fb_temp_0)
    (*c2fb_temp_1) = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_3
    Else
        ' C automatic storage declaration
        c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Hash))))
        c2fb_temp_5 = CPtr(Long Ptr Ptr, @(local1->pnByte))
        c2fb_temp_6 = arg2
        (*c2fb_temp_5) = CPtr(Long Ptr, c2fb_temp_6)
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(Long Ptr, @(local1->eDetail))
        c2fb_temp_8 = Cast(c2fb_c_int, arg0->eDetail)
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        c2fb_temp_9 = CPtr(Long Ptr, @(local1->nSlot))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1024ULL))
        (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
        c2fb_temp_11 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry Ptr))) * Cast(c2fb_uint64, local1->nSlot))))
        local2 = c2fb_temp_11
        c2fb_temp_12 = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr Ptr, @(local1->aSlot))
        c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local2))))
        (*c2fb_temp_12) = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr, c2fb_temp_13)
        c2fb_temp_13 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, (*c2fb_temp_12))
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5HashEntry Ptr Ptr, local1->aSlot) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
            c2fb_temp_14 = CPtr(c2fb_Fts5Hash Ptr Ptr, @((*arg1)))
            c2fb_temp_15 = CPtr(_c2fb_record_c2fb_Fts5Hash Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_14) = c2fb_temp_15
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_16
        Else
            c2fb_temp_17 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, local1->aSlot)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, local2)))
        End If
    End If
    Return local0
End Function
Sub sqlite3Fts5HashFree CDecl Alias "sqlite3Fts5HashFree" (ByVal arg0 As c2fb_Fts5Hash Ptr)
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 120
    If arg0 Then
        sqlite3Fts5HashClear(arg0)
        c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot)))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Sub sqlite3Fts5HashClear CDecl Alias "sqlite3Fts5HashClear" (ByVal arg0 As c2fb_Fts5Hash Ptr)
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 131
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_Fts5HashEntry Ptr
    Dim local2 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_2 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_3 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_4 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0->nSlot))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot))[local0])
        local2 = c2fb_temp_2
        While local2
            c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, local2->pHashNext))
            local1 = c2fb_temp_4
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
        c2fb_flow_3:
            c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local1)
            local2 = c2fb_temp_3
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0->nSlot) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry Ptr)))))))
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->nEntry))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
End Sub
Private Function fts5HashKey CDecl Alias "fts5HashKey" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_uint
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 145
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_uint

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, 13ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 1ULL))))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL)))))
        c2fb_temp_2 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 3ULL)))) Xor local1)) Xor Cast(c2fb_c_uint, arg1[local0]))))
        local1 = c2fb_temp_2
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
    Wend
    c2fb_flow_0:
    Return (Cast(c2fb_c_uint, (local1 Mod Cast(c2fb_c_uint, arg0))))
End Function
Private Function fts5HashKey2 CDecl Alias "fts5HashKey2" (ByVal arg0 As c2fb_c_int, ByVal arg1 As UByte, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_uint
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 154
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As c2fb_c_uint

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, 13ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg3 - Cast(c2fb_c_int, 1ULL))))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL)))))
        c2fb_temp_2 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 3ULL)))) Xor local1)) Xor Cast(c2fb_c_uint, arg2[local0]))))
        local1 = c2fb_temp_2
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 3ULL)))) Xor local1)) Xor Cast(c2fb_c_uint, arg1))))
    local1 = c2fb_temp_3
    Return (Cast(c2fb_c_uint, (local1 Mod Cast(c2fb_c_uint, arg0))))
End Function
Private Function fts5HashResize CDecl Alias "fts5HashResize" (ByVal arg0 As c2fb_Fts5Hash Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 167
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5HashEntry Ptr Ptr
    Dim local3 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_0 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As c2fb_c_uint
    Dim local5 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_4 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_Fts5HashEntry_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_9 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_10 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_Fts5HashEntry_ Ptr Ptr Ptr
    Dim c2fb_temp_14 As c2fb_Fts5HashEntry Ptr Ptr

    local0 = Cast(c2fb_c_int, (arg0->nSlot * Cast(c2fb_c_int, 2ULL)))
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, local0) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry Ptr)))))))))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local2 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, local0) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry Ptr)))))))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local1 < arg0->nSlot))))
        While CPtr(c2fb_Fts5HashEntry Ptr Ptr, local3)[local1]
            ' C automatic storage declaration
            local5 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, local3)[local1]
            c2fb_temp_4 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr Ptr, local3)[local1]))
            c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, local5->pHashNext))
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_6 = Cast(c2fb_c_uint, fts5HashKey(local0, CPtr(Const UByte Ptr, CPtr(UByte Ptr, ((CPtr(ZString Ptr, (CPtr(c2fb_Fts5HashEntry Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr, (local5))[Cast(c2fb_c_int, 1ULL)])))))))), local5->nKey))
            local4 = c2fb_temp_6
            c2fb_temp_7 = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr, @(local5->pHashNext))
            c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, local2)[local4])
            (*c2fb_temp_7) = CPtr(c2fb_Fts5HashEntry_ Ptr, c2fb_temp_8)
            c2fb_temp_8 = CPtr(c2fb_Fts5HashEntry Ptr, (*c2fb_temp_7))
            c2fb_temp_9 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr Ptr, local2)[local4]))
            c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local5)
            (*c2fb_temp_9) = c2fb_temp_10
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_3 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
    c2fb_temp_11 = CPtr(Long Ptr, @(arg0->nSlot))
    c2fb_temp_12 = Cast(c2fb_c_int, local0)
    (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
    c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
    c2fb_temp_13 = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr Ptr, @(arg0->aSlot))
    c2fb_temp_14 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr Ptr, local2)
    (*c2fb_temp_13) = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr, c2fb_temp_14)
    c2fb_temp_14 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, (*c2fb_temp_13))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5HashAddPoslistSize CDecl Alias "fts5HashAddPoslistSize" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As c2fb_Fts5HashEntry Ptr, ByVal arg2 As c2fb_Fts5HashEntry Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 194
    Dim local0 As c2fb_c_int
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As UByte
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_u8 Ptr
    Dim c2fb_temp_14 As UByte
    Dim c2fb_temp_15 As c2fb_u8 Ptr
    Dim c2fb_temp_16 As UByte
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg1->iSzPoslist Then
        local1 = IIf(arg2, CPtr(UByte Ptr, arg2), CPtr(UByte Ptr, arg1))
        local2 = arg1->nData
        If (-Cast(c2fb_c_int, ((arg0->eDetail = Cast(c2fb_c_int, 1ULL))))) Then
            ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
            If local2 <> arg1->iSzPoslist Then _
                sqlite3DebugAssert(StrPtr(!"nData==p->iSzPoslist"))
#endif
            If arg1->bDel Then
                c2fb_temp_0 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
                c2fb_temp_1 = CPtr(UByte Ptr, @(local1[c2fb_temp_0]))
                c2fb_temp_2 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
                (*c2fb_temp_1) = c2fb_temp_2
                If arg1->bContent Then
                    c2fb_temp_3 = local2
                    local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
                    c2fb_temp_4 = CPtr(UByte Ptr, @(local1[c2fb_temp_3]))
                    c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
                    (*c2fb_temp_4) = c2fb_temp_5
                End If
            End If
        Else
            local3 = (Cast(c2fb_c_int, (Cast(c2fb_c_int, (local2 - arg1->iSzPoslist)) - Cast(c2fb_c_int, 1ULL))))
            local4 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, arg1->bDel)))
            ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
            If arg1->bDel <> 0 AndAlso arg1->bDel <> 1 Then _
                sqlite3DebugAssert(StrPtr(!"p->bDel==0 || p->bDel==1"))
#endif
            If (-Cast(c2fb_c_int, ((local4 <= Cast(c2fb_c_int, 127ULL))))) Then
                c2fb_temp_6 = CPtr(UByte Ptr, @(local1[arg1->iSzPoslist]))
                c2fb_temp_7 = Cast(UByte, Cast(UByte, local4))
                (*c2fb_temp_6) = c2fb_temp_7
            Else
                local5 = c2fb_external_sqlite3Fts5GetVarintLen(Cast(c2fb_c_uint, local4))
                c2fb_temp_8 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(UByte Ptr, @(local1[Cast(c2fb_c_int, (arg1->iSzPoslist + local5))]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local1[Cast(c2fb_c_int, (arg1->iSzPoslist + Cast(c2fb_c_int, 1ULL)))]))), local3))
                c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local1[arg1->iSzPoslist])), local4)
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + (Cast(c2fb_c_int, (local5 - Cast(c2fb_c_int, 1ULL)))))))
                local2 = c2fb_temp_9
            End If
        End If
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 - arg1->nData)))
        local0 = c2fb_temp_10
        If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_11 = CPtr(Long Ptr, @(arg1->iSzPoslist))
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
            c2fb_temp_13 = CPtr(c2fb_u8 Ptr, @(arg1->bDel))
            c2fb_temp_14 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_13) = Cast(c2fb_u8, c2fb_temp_14)
            c2fb_temp_14 = Cast(UByte, (*c2fb_temp_13))
            c2fb_temp_15 = CPtr(c2fb_u8 Ptr, @(arg1->bContent))
            c2fb_temp_16 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_15) = Cast(c2fb_u8, c2fb_temp_16)
            c2fb_temp_16 = Cast(UByte, (*c2fb_temp_15))
            c2fb_temp_17 = CPtr(Long Ptr, @(arg1->nData))
            c2fb_temp_18 = Cast(c2fb_c_int, local2)
            (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
            c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5HashWrite CDecl Alias "sqlite3Fts5HashWrite" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Byte, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 245
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_Fts5HashEntry Ptr
    Dim local2 As UByte Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_3 As c2fb_Fts5HashEntry Ptr
    Dim local5 As ZString Ptr
    Dim local6 As ZString Ptr
    Dim local7 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_int64
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As Byte Ptr
    Dim c2fb_temp_12 As Byte
    Dim c2fb_temp_13 As Any Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Byte Ptr
    Dim c2fb_temp_17 As Byte
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_Fts5HashEntry_ Ptr Ptr
    Dim c2fb_temp_21 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_22 As c2fb_Fts5HashEntry_ Ptr Ptr
    Dim c2fb_temp_23 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_24 As Long Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Long Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_i64 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim c2fb_temp_30 As Long Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As Long Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_i16 Ptr
    Dim c2fb_temp_35 As Short
    Dim local9 As c2fb_int64
    Dim local10 As c2fb_Fts5HashEntry Ptr
    Dim local11 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_36 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_37 As Long Ptr
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_40 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_41 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_42 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_43 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As UByte Ptr
    Dim local12 As c2fb_uint64
    Dim c2fb_temp_46 As Long Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_i64 Ptr
    Dim c2fb_temp_49 As c2fb_int64
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As Long Ptr
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As Long Ptr
    Dim c2fb_temp_54 As c2fb_c_int
    Dim c2fb_temp_55 As c2fb_i16 Ptr
    Dim c2fb_temp_56 As Short
    Dim c2fb_temp_57 As Long Ptr
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As c2fb_u8 Ptr
    Dim c2fb_temp_60 As UByte
    Dim c2fb_temp_61 As Long Ptr
    Dim c2fb_temp_62 As c2fb_c_int
    Dim c2fb_temp_63 As UByte Ptr
    Dim c2fb_temp_64 As UByte
    Dim c2fb_temp_65 As Long Ptr
    Dim c2fb_temp_66 As c2fb_c_int
    Dim c2fb_temp_67 As c2fb_i16 Ptr
    Dim c2fb_temp_68 As Short
    Dim c2fb_temp_69 As Long Ptr
    Dim c2fb_temp_70 As c2fb_c_int
    Dim c2fb_temp_71 As c2fb_c_int
    Dim c2fb_temp_72 As c2fb_c_int
    Dim c2fb_temp_73 As c2fb_i16 Ptr
    Dim c2fb_temp_74 As Short
    Dim c2fb_temp_75 As Long Ptr
    Dim c2fb_temp_76 As c2fb_c_int
    Dim c2fb_temp_77 As Long Ptr
    Dim c2fb_temp_78 As c2fb_c_int
    Dim c2fb_temp_79 As c2fb_u8 Ptr
    Dim c2fb_temp_80 As UByte
    Dim c2fb_temp_81 As c2fb_c_int
    Dim c2fb_temp_82 As c2fb_c_int Ptr
    Dim c2fb_temp_83 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((arg0->eDetail = Cast(c2fb_c_int, &O0ULL)))))))
    local4 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_uint, fts5HashKey2(arg0->nSlot, Cast(UByte, arg4), CPtr(Const UByte Ptr, arg5), arg6))
    local0 = c2fb_temp_1
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot))[local0])
    local1 = c2fb_temp_2
    While local1
        local5 = ((CPtr(ZString Ptr, (CPtr(c2fb_Fts5HashEntry Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr, (local1))[Cast(c2fb_c_int, 1ULL)]))))))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local5)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, arg4))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->nKey = Cast(c2fb_c_int, (arg6 + Cast(c2fb_c_int, 1ULL))))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[Cast(c2fb_c_int, 1ULL)]))), CPtr(Const Any Ptr, arg5), arg6) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, local1->pHashNext))
        local1 = c2fb_temp_3
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        local7 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry))) + Cast(c2fb_uint64, (Cast(c2fb_c_int, (arg6 + Cast(c2fb_c_int, 1ULL))))))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 64ULL))))
        If (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_int64, Cast(c2fb_c_int, 128ULL)))))) Then
            c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_c_int, 128ULL))
            local7 = c2fb_temp_4
        End If
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->nEntry * Cast(c2fb_c_int, 2ULL)))) >= arg0->nSlot)))) Then
            local8 = fts5HashResize(arg0)
            If (-Cast(c2fb_c_int, ((local8 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return local8
            End If
            c2fb_temp_5 = Cast(c2fb_c_uint, fts5HashKey2(arg0->nSlot, Cast(UByte, arg4), CPtr(Const UByte Ptr, arg5), arg6))
            local0 = c2fb_temp_5
        End If
        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local7))))
        local1 = c2fb_temp_6
        If (-Cast(c2fb_c_int, (local1 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry))))
        c2fb_temp_8 = CPtr(Long Ptr, @(local1->nAlloc))
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, local7))
        (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
        c2fb_temp_10 = ((CPtr(ZString Ptr, (CPtr(c2fb_Fts5HashEntry Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr, (local1))[Cast(c2fb_c_int, 1ULL)]))))))
        local6 = c2fb_temp_10
        c2fb_temp_11 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local6)[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_12 = Cast(Byte, arg4)
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_temp_13 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local6)[Cast(c2fb_c_int, 1ULL)]))), CPtr(Const Any Ptr, arg5), arg6))
#ifdef SQLITE_DEBUG
        If local0 <> fts5HashKey(arg0->nSlot, CPtr(Const UByte Ptr, local6), arg6 + 1) Then _
            sqlite3DebugAssert(StrPtr(!"iHash==fts5HashKey(pHash->nSlot, (u8*)zKey, nToken+1)"))
#endif
        ' C unused-parameter annotation
        c2fb_temp_14 = CPtr(Long Ptr, @(local1->nKey))
        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg6 + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
        c2fb_temp_16 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local6)[Cast(c2fb_c_int, (arg6 + Cast(c2fb_c_int, 1ULL)))]))
        c2fb_temp_17 = Cast(Byte, Cast(c2fb_c_int, 0))
        (*c2fb_temp_16) = c2fb_temp_17
        c2fb_temp_18 = CPtr(Long Ptr, @(local1->nData))
        c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (arg6 + Cast(c2fb_c_int, 1ULL)))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry))))))
        (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
        c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
        c2fb_temp_20 = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr, @(local1->pHashNext))
        c2fb_temp_21 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot))[local0])
        (*c2fb_temp_20) = CPtr(c2fb_Fts5HashEntry_ Ptr, c2fb_temp_21)
        c2fb_temp_21 = CPtr(c2fb_Fts5HashEntry Ptr, (*c2fb_temp_20))
        c2fb_temp_22 = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot))[local0]))
        c2fb_temp_23 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local1)
        (*c2fb_temp_22) = CPtr(c2fb_Fts5HashEntry_ Ptr, c2fb_temp_23)
        c2fb_temp_23 = CPtr(c2fb_Fts5HashEntry Ptr, (*c2fb_temp_22))
        c2fb_temp_24 = CPtr(Long Ptr, @(arg0->nEntry))
        c2fb_temp_25 = Cast(c2fb_c_int, (*c2fb_temp_24))
        (*c2fb_temp_24) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_25 + 1)))
        c2fb_temp_26 = CPtr(Long Ptr, @(local1->nData))
        c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_26)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(UByte Ptr, local1))[local1->nData])), arg1))))
        (*c2fb_temp_26) = Cast(Long, c2fb_temp_27)
        c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
        c2fb_temp_28 = CPtr(c2fb_i64 Ptr, @(local1->iRowid))
        c2fb_temp_29 = Cast(c2fb_int64, arg1)
        (*c2fb_temp_28) = Cast(c2fb_i64, c2fb_temp_29)
        c2fb_temp_29 = Cast(c2fb_int64, (*c2fb_temp_28))
        c2fb_temp_30 = CPtr(Long Ptr, @(local1->iSzPoslist))
        c2fb_temp_31 = Cast(c2fb_c_int, local1->nData)
        (*c2fb_temp_30) = Cast(Long, c2fb_temp_31)
        c2fb_temp_31 = Cast(c2fb_c_int, (*c2fb_temp_30))
        If (-Cast(c2fb_c_int, ((arg0->eDetail <> Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_32 = CPtr(Long Ptr, @(local1->nData))
            c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_32)) + Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_32) = Cast(Long, c2fb_temp_33)
            c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
            c2fb_temp_34 = CPtr(c2fb_i16 Ptr, @(local1->iCol))
            c2fb_temp_35 = Cast(Short, (IIf((-Cast(c2fb_c_int, ((arg0->eDetail = Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))
            (*c2fb_temp_34) = Cast(c2fb_i16, c2fb_temp_35)
            c2fb_temp_35 = Cast(Short, (*c2fb_temp_34))
        End If
    Else
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local1->nAlloc - local1->nData))) < (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 9ULL) + Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 1ULL))) + Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 5ULL)))))))) Then
            local9 = Cast(c2fb_int64, (Cast(c2fb_int64, local1->nAlloc) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_36 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, local1), local9))))
            local10 = c2fb_temp_36
            If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, 7ULL)
            End If
            c2fb_temp_37 = CPtr(Long Ptr, @(local10->nAlloc))
            c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_int, local9))
            (*c2fb_temp_37) = Cast(Long, c2fb_temp_38)
            c2fb_temp_38 = Cast(c2fb_c_int, (*c2fb_temp_37))
            c2fb_temp_39 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot))[local0])))
            local11 = c2fb_temp_39
            While (-Cast(c2fb_c_int, (((*local11) <> local1))))
                ' empty C statement
            c2fb_flow_3:
                c2fb_temp_40 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(((*local11))->pHashNext)))
                local11 = c2fb_temp_40
            Wend
            c2fb_flow_2:
            c2fb_temp_41 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @((*local11)))
            c2fb_temp_42 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local10)
            (*c2fb_temp_41) = c2fb_temp_42
            c2fb_temp_43 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local10)
            local1 = c2fb_temp_43
        End If
        c2fb_temp_44 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 - local1->nData)))
        local3 = c2fb_temp_44
    End If
#ifdef SQLITE_DEBUG
    ' Keep the upstream reserve for rowid, column, and position-list writes.
    If local1->nAlloc - local1->nData < (9 + 4 + 1 + 3 + 5) Then _
        sqlite3DebugAssert(StrPtr(!"(p->nAlloc - p->nData) >= (9 + 4 + 1 + 3 + 5)"))
#endif
    ' C unused-parameter annotation
    c2fb_temp_45 = CPtr(UByte Ptr, local1)
    local2 = c2fb_temp_45
    If (-Cast(c2fb_c_int, ((arg1 <> local1->iRowid)))) Then
        local12 = Cast(c2fb_uint64, (Cast(c2fb_uint64, arg1) - Cast(c2fb_uint64, local1->iRowid)))
        fts5HashAddPoslistSize(arg0, local1, Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_46 = CPtr(Long Ptr, @(local1->nData))
        c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_46)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2[local1->nData])), local12))))
        (*c2fb_temp_46) = Cast(Long, c2fb_temp_47)
        c2fb_temp_47 = Cast(c2fb_c_int, (*c2fb_temp_46))
        c2fb_temp_48 = CPtr(c2fb_i64 Ptr, @(local1->iRowid))
        c2fb_temp_49 = Cast(c2fb_int64, arg1)
        (*c2fb_temp_48) = Cast(c2fb_i64, c2fb_temp_49)
        c2fb_temp_49 = Cast(c2fb_int64, (*c2fb_temp_48))
        c2fb_temp_50 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local4 = c2fb_temp_50
        c2fb_temp_51 = CPtr(Long Ptr, @(local1->iSzPoslist))
        c2fb_temp_52 = Cast(c2fb_c_int, local1->nData)
        (*c2fb_temp_51) = Cast(Long, c2fb_temp_52)
        c2fb_temp_52 = Cast(c2fb_c_int, (*c2fb_temp_51))
        If (-Cast(c2fb_c_int, ((arg0->eDetail <> Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_53 = CPtr(Long Ptr, @(local1->nData))
            c2fb_temp_54 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_53)) + Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_53) = Cast(Long, c2fb_temp_54)
            c2fb_temp_54 = Cast(c2fb_c_int, (*c2fb_temp_53))
            c2fb_temp_55 = CPtr(c2fb_i16 Ptr, @(local1->iCol))
            c2fb_temp_56 = Cast(Short, (IIf((-Cast(c2fb_c_int, ((arg0->eDetail = Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))
            (*c2fb_temp_55) = Cast(c2fb_i16, c2fb_temp_56)
            c2fb_temp_56 = Cast(Short, (*c2fb_temp_55))
            c2fb_temp_57 = CPtr(Long Ptr, @(local1->iPos))
            c2fb_temp_58 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_57) = Cast(Long, c2fb_temp_58)
            c2fb_temp_58 = Cast(c2fb_c_int, (*c2fb_temp_57))
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg2 >= Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg0->eDetail = Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_59 = CPtr(c2fb_u8 Ptr, @(local1->bContent))
            c2fb_temp_60 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_59) = Cast(c2fb_u8, c2fb_temp_60)
            c2fb_temp_60 = Cast(UByte, (*c2fb_temp_59))
        Else
            ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
            If arg2 < local1->iCol Then _
                sqlite3DebugAssert(StrPtr(!"iCol>=p->iCol"))
#endif
            If (-Cast(c2fb_c_int, ((arg2 <> Cast(c2fb_c_int, local1->iCol))))) Then
                If (-Cast(c2fb_c_int, ((arg0->eDetail = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_61 = CPtr(Long Ptr, @(local1->nData))
                    c2fb_temp_62 = Cast(c2fb_c_int, (*c2fb_temp_61))
                    (*c2fb_temp_61) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_62 + 1)))
                    c2fb_temp_63 = CPtr(UByte Ptr, @(local2[c2fb_temp_62]))
                    c2fb_temp_64 = Cast(UByte, Cast(c2fb_c_int, &H01ULL))
                    (*c2fb_temp_63) = c2fb_temp_64
                    c2fb_temp_65 = CPtr(Long Ptr, @(local1->nData))
                    c2fb_temp_66 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_65)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2[local1->nData])), arg2))))
                    (*c2fb_temp_65) = Cast(Long, c2fb_temp_66)
                    c2fb_temp_66 = Cast(c2fb_c_int, (*c2fb_temp_65))
                    c2fb_temp_67 = CPtr(c2fb_i16 Ptr, @(local1->iCol))
                    c2fb_temp_68 = Cast(Short, Cast(Short, arg2))
                    (*c2fb_temp_67) = Cast(c2fb_i16, c2fb_temp_68)
                    c2fb_temp_68 = Cast(Short, (*c2fb_temp_67))
                    c2fb_temp_69 = CPtr(Long Ptr, @(local1->iPos))
                    c2fb_temp_70 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_69) = Cast(Long, c2fb_temp_70)
                    c2fb_temp_70 = Cast(c2fb_c_int, (*c2fb_temp_69))
                Else
                    c2fb_temp_71 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local4 = c2fb_temp_71
                    c2fb_temp_73 = CPtr(c2fb_i16 Ptr, @(local1->iCol))
                    c2fb_temp_72 = Cast(c2fb_c_int, arg2)
                    arg3 = c2fb_temp_72
                    c2fb_temp_74 = Cast(Short, Cast(Short, (c2fb_temp_72)))
                    (*c2fb_temp_73) = Cast(c2fb_i16, c2fb_temp_74)
                    c2fb_temp_74 = Cast(Short, (*c2fb_temp_73))
                End If
            End If
            If local4 Then
                c2fb_temp_75 = CPtr(Long Ptr, @(local1->nData))
                c2fb_temp_76 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_75)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2[local1->nData])), Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg3 - local1->iPos)) + Cast(c2fb_c_int, 2ULL)))))))
                (*c2fb_temp_75) = Cast(Long, c2fb_temp_76)
                c2fb_temp_76 = Cast(c2fb_c_int, (*c2fb_temp_75))
                c2fb_temp_77 = CPtr(Long Ptr, @(local1->iPos))
                c2fb_temp_78 = Cast(c2fb_c_int, arg3)
                (*c2fb_temp_77) = Cast(Long, c2fb_temp_78)
                c2fb_temp_78 = Cast(c2fb_c_int, (*c2fb_temp_77))
            End If
        End If
    Else
        c2fb_temp_79 = CPtr(c2fb_u8 Ptr, @(local1->bDel))
        c2fb_temp_80 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_79) = Cast(c2fb_u8, c2fb_temp_80)
        c2fb_temp_80 = Cast(UByte, (*c2fb_temp_79))
    End If
    c2fb_temp_81 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + local1->nData)))
    local3 = c2fb_temp_81
    c2fb_temp_82 = CPtr(c2fb_c_int Ptr, @((*arg0->pnByte)))
    c2fb_temp_83 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_82) + local3)))
    (*c2fb_temp_82) = c2fb_temp_83
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5HashEntryMerge CDecl Alias "fts5HashEntryMerge" (ByVal arg0 As c2fb_Fts5HashEntry Ptr, ByVal arg1 As c2fb_Fts5HashEntry Ptr) As c2fb_Fts5HashEntry Ptr
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 398
    Dim local0 As c2fb_Fts5HashEntry Ptr
    Dim local1 As c2fb_Fts5HashEntry Ptr
    Dim local2 As c2fb_Fts5HashEntry Ptr
    Dim local3 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_0 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_2 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_3 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_5 As c2fb_Fts5HashEntry Ptr
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_8 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_9 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_10 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_11 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_12 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_13 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_14 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_15 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5HashEntry Ptr

    local0 = arg0
    local1 = arg1
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(local2))
    While (-Cast(c2fb_c_int, (((local0 <> 0) OrElse (local1 <> 0)))))
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @((*local3)))
            c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local1)
            (*c2fb_temp_0) = c2fb_temp_1
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_2
        Else
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_3 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @((*local3)))
                c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local0)
                (*c2fb_temp_3) = c2fb_temp_4
                c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_5
            Else
                local4 = ((CPtr(ZString Ptr, (CPtr(c2fb_Fts5HashEntry Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr, (local0))[Cast(c2fb_c_int, 1ULL)]))))))
                local5 = ((CPtr(ZString Ptr, (CPtr(c2fb_Fts5HashEntry Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr, (local1))[Cast(c2fb_c_int, 1ULL)]))))))
                local6 = (IIf(((-Cast(c2fb_c_int, (((local0->nKey) < (local1->nKey)))))), (local0->nKey), (local1->nKey)))
                local7 = c2fb_crt_memcmp(CPtr(Const Any Ptr, local4), CPtr(Const Any Ptr, local5), local6)
                If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0->nKey - local1->nKey)))
                    local7 = c2fb_temp_6
                End If
#ifdef SQLITE_DEBUG
                If local7 = 0 Then sqlite3DebugAssert(StrPtr(!"cmp!=0"))
#endif
                ' C unused-parameter annotation
                If (-Cast(c2fb_c_int, ((local7 > Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_7 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @((*local3)))
                    c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local1)
                    (*c2fb_temp_7) = c2fb_temp_8
                    c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(local1->pScanNext)))
                    local3 = c2fb_temp_9
                    c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, local1->pScanNext))
                    local1 = c2fb_temp_10
                Else
                    c2fb_temp_11 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @((*local3)))
                    c2fb_temp_12 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local0)
                    (*c2fb_temp_11) = c2fb_temp_12
                    c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(local0->pScanNext)))
                    local3 = c2fb_temp_13
                    c2fb_temp_14 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, local0->pScanNext))
                    local0 = c2fb_temp_14
                End If
                c2fb_temp_15 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @((*local3)))
                c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_15) = c2fb_temp_16
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local2
End Function
Private Function fts5HashEntrySort CDecl Alias "fts5HashEntrySort" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5HashEntry Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 447
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5HashEntry Ptr Ptr
    Dim local2 As c2fb_Fts5HashEntry Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_2 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local5 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_6 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_7 As c2fb_Fts5HashEntry Ptr
    Dim local6 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_8 As c2fb_Fts5HashEntry_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_13 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_14 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_15 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_17 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_21 As c2fb_Fts5HashEntry Ptr Ptr
    Dim c2fb_temp_22 As c2fb_Fts5HashEntry Ptr

    local0 = Cast(c2fb_c_int, 32ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @((*arg3)))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry Ptr))) * Cast(c2fb_uint64, local0))))))
    local1 = c2fb_temp_2
    If (-Cast(c2fb_c_int, (local1 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry Ptr))) * Cast(c2fb_uint64, local0)))))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local3 < arg0->nSlot))))
        ' C automatic storage declaration
        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot))[local3])
        local5 = c2fb_temp_6
        While local5
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5->nKey >= arg2)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, ((CPtr(ZString Ptr, (CPtr(c2fb_Fts5HashEntry Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr, (local5))[Cast(c2fb_c_int, 1ULL)]))))))), CPtr(Const Any Ptr, arg1), arg2))))) <> 0)))))) <> 0))))) Then
                local6 = local5
                c2fb_temp_8 = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr, @(local6->pScanNext))
                c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_8) = CPtr(c2fb_Fts5HashEntry_ Ptr, c2fb_temp_9)
                c2fb_temp_9 = CPtr(c2fb_Fts5HashEntry Ptr, (*c2fb_temp_8))
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local4 = c2fb_temp_10
                While CPtr(c2fb_Fts5HashEntry Ptr Ptr, local1)[local4]
                    c2fb_temp_12 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, fts5HashEntryMerge(local6, CPtr(c2fb_Fts5HashEntry Ptr Ptr, local1)[local4])))
                    local6 = c2fb_temp_12
                    c2fb_temp_13 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr Ptr, local1)[local4]))
                    c2fb_temp_14 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_13) = c2fb_temp_14
                c2fb_flow_5:
                    c2fb_temp_11 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
                Wend
                c2fb_flow_4:
                c2fb_temp_15 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr Ptr, local1)[local4]))
                c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local6)
                (*c2fb_temp_15) = c2fb_temp_16
            End If
        c2fb_flow_3:
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, local5->pHashNext))
            local5 = c2fb_temp_7
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_5 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_17 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    local2 = c2fb_temp_17
    c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_18
    While (-Cast(c2fb_c_int, ((local4 < local0))))
        c2fb_temp_20 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, fts5HashEntryMerge(local2, CPtr(c2fb_Fts5HashEntry Ptr Ptr, local1)[local4])))
        local2 = c2fb_temp_20
    c2fb_flow_7:
        c2fb_temp_19 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_19 + 1)))
    Wend
    c2fb_flow_6:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    c2fb_temp_21 = CPtr(c2fb_Fts5HashEntry Ptr Ptr, @((*arg3)))
    c2fb_temp_22 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, local2)
    (*c2fb_temp_21) = c2fb_temp_22
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts5HashQuery CDecl Alias "sqlite3Fts5HashQuery" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 493
    Dim local0 As c2fb_c_uint
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_0 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_1 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim local5 As UByte Ptr
    Dim local6 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Any Ptr Ptr
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int

    local0 = fts5HashKey(arg0->nSlot, CPtr(Const UByte Ptr, arg2), arg3)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, arg0->aSlot))[local0])
    local2 = c2fb_temp_0
    While local2
        c2fb_temp_2 = ((CPtr(ZString Ptr, (CPtr(c2fb_Fts5HashEntry Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr, (local2))[Cast(c2fb_c_int, 1ULL)]))))))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 = local2->nKey)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, local1), CPtr(Const Any Ptr, arg2), arg3) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, local2->pHashNext))
        local2 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If local2 Then
        local3 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry))) + Cast(c2fb_uint64, arg3)))
        local4 = Cast(c2fb_c_int, (local2->nData - local3))
        c2fb_temp_3 = CPtr(Any Ptr Ptr, @((*arg4)))
        c2fb_temp_4 = CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 + local4)) + Cast(c2fb_c_int, 10ULL)))))
        (*c2fb_temp_3) = c2fb_temp_4
        local5 = CPtr(UByte Ptr, (c2fb_temp_4))
        If local5 Then
            local6 = CPtr(c2fb_Fts5HashEntry Ptr, CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, (arg1 - local3))])))
            c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local5[arg1]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @((CPtr(UByte Ptr, local2))[local3]))), local4))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + fts5HashAddPoslistSize(arg0, local2, local6))))
            local4 = c2fb_temp_6
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*arg5)))
            c2fb_temp_8 = Cast(c2fb_c_int, local4)
            (*c2fb_temp_7) = c2fb_temp_8
        Else
            c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg5)))
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_9) = c2fb_temp_10
            Return Cast(c2fb_c_int, 7ULL)
        End If
    Else
        c2fb_temp_11 = CPtr(Any Ptr Ptr, @((*arg4)))
        c2fb_temp_12 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @((*arg5)))
        c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_13) = c2fb_temp_14
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts5HashScanInit CDecl Alias "sqlite3Fts5HashScanInit" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 530
    Return fts5HashEntrySort(arg0, arg1, arg2, CPtr(c2fb_Fts5HashEntry Ptr Ptr, @(arg0->pScan)))
End Function
#ifdef SQLITE_DEBUG
Private Function fts5HashCount(ByVal pHash As c2fb_Fts5Hash Ptr) As c2fb_c_int
    Dim iSlot As c2fb_c_int
    Dim nEntry As c2fb_c_int
    Dim pEntry As c2fb_Fts5HashEntry Ptr

    For iSlot = 0 To pHash->nSlot - 1
        pEntry = CPtr(c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr Ptr, pHash->aSlot)[iSlot])
        While pEntry
            nEntry += 1
            pEntry = CPtr(c2fb_Fts5HashEntry Ptr, pEntry->pHashNext)
        Wend
    Next

    Return nEntry
End Function
#endif
Function sqlite3Fts5HashIsEmpty CDecl Alias "sqlite3Fts5HashIsEmpty" (ByVal arg0 As c2fb_Fts5Hash Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 554
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    If arg0->nEntry <> fts5HashCount(arg0) Then _
        sqlite3DebugAssert(StrPtr(!"pHash->nEntry==fts5HashCount(pHash)"))
#endif
    Return (-Cast(c2fb_c_int, ((arg0->nEntry = Cast(c2fb_c_int, &O0ULL)))))
End Function
Sub sqlite3Fts5HashScanNext CDecl Alias "sqlite3Fts5HashScanNext" (ByVal arg0 As c2fb_Fts5Hash Ptr)
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 559
    Dim c2fb_temp_0 As c2fb_Fts5HashEntry_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5HashEntry Ptr

    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    If sqlite3Fts5HashScanEof(arg0) Then _
        sqlite3DebugAssert(StrPtr(!"!sqlite3Fts5HashScanEof(p)"))
#endif
    c2fb_temp_0 = CPtr(c2fb_Fts5HashEntry_ Ptr Ptr, @(arg0->pScan))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, arg0->pScan)->pScanNext))
    (*c2fb_temp_0) = CPtr(c2fb_Fts5HashEntry_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_Fts5HashEntry Ptr, (*c2fb_temp_0))
End Sub
Function sqlite3Fts5HashScanEof CDecl Alias "sqlite3Fts5HashScanEof" (ByVal arg0 As c2fb_Fts5Hash Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 564
    Return ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5HashEntry Ptr, arg0->pScan) = Cast(c2fb_c_int, &O0ULL))))))
End Function
Sub sqlite3Fts5HashScanEntry CDecl Alias "sqlite3Fts5HashScanEntry" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As Const UByte Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr)
' c2fb source-path: ext/fts5/fts5_hash.c
' c2fb source-line: 568
    Dim local0 As c2fb_Fts5HashEntry Ptr
    Dim c2fb_temp_0 As c2fb_Fts5HashEntry Ptr
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Const UByte Ptr Ptr
    Dim c2fb_temp_6 As Const UByte Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Const ZString Ptr Ptr
    Dim c2fb_temp_10 As Const ZString Ptr
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Const UByte Ptr Ptr
    Dim c2fb_temp_14 As Const UByte Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5HashEntry Ptr, CPtr(c2fb_Fts5HashEntry Ptr, arg0->pScan))
    local0 = c2fb_temp_0
    If (c2fb_temp_0) Then
        local1 = ((CPtr(ZString Ptr, (CPtr(c2fb_Fts5HashEntry Ptr, @(CPtr(c2fb_Fts5HashEntry Ptr, (local0))[Cast(c2fb_c_int, 1ULL)]))))))
        local2 = local0->nKey
        fts5HashAddPoslistSize(arg0, local0, Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
        c2fb_temp_2 = CPtr(Const ZString Ptr, local1)
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_4 = Cast(c2fb_c_int, local2)
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = CPtr(Const UByte Ptr Ptr, @((*arg3)))
        c2fb_temp_6 = CPtr(Const UByte Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[local2])))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_uint64, (Cast(c2fb_uint64, local0->nData) - (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5HashEntry))) + Cast(c2fb_uint64, local2)))))))
        (*c2fb_temp_7) = c2fb_temp_8
    Else
        c2fb_temp_9 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
        c2fb_temp_10 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_9) = c2fb_temp_10
        c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_temp_13 = CPtr(Const UByte Ptr Ptr, @((*arg3)))
        c2fb_temp_14 = CPtr(Const UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_13) = c2fb_temp_14
        c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_15) = c2fb_temp_16
    End If
End Sub
#endif

/' end of sqlite3_bulk_fts5_hash.bas '/
