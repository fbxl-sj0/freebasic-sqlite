/'
** 2015 May 30
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

    File: sqlite3_bulk_fts5_varint.bas

    Purpose:

        Port the FTS5 variable-length integer codecs used by index pages.

    Responsibilities:

        - Decode and encode FTS5's 1-to-9 byte integer representation.
        - Preserve C ABI names so later FTS5 source units can call these helpers.
        - Check the upstream encoding invariants in SQLITE_DEBUG builds.

    This file intentionally does NOT contain:

        - FTS5 index, storage, tokenizer, or virtual-table registration.
        - Test code.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_varint_types.bi"

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


Declare Function sqlite3Fts5GetVarint32 CDecl Alias "sqlite3Fts5GetVarint32" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_uint Ptr) As c2fb_c_int
Declare Function sqlite3Fts5GetVarint CDecl Alias "sqlite3Fts5GetVarint" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_uint64 Ptr) As UByte
Declare Function sqlite3Fts5PutVarint CDecl Alias "sqlite3Fts5PutVarint" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_uint64) As c2fb_c_int
Declare Function sqlite3Fts5GetVarintLen CDecl Alias "sqlite3Fts5GetVarintLen" (ByVal arg0 As c2fb_c_uint) As c2fb_c_int
Function sqlite3Fts5GetVarint32 CDecl Alias "sqlite3Fts5GetVarint32" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_uint Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_varint.c
' c2fb source-line: 24
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint Ptr
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_c_uint Ptr
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As Const UByte Ptr
    Dim c2fb_temp_10 As c2fb_c_uint
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim c2fb_temp_12 As c2fb_c_uint
    Dim c2fb_temp_13 As c2fb_c_uint
    Dim c2fb_temp_14 As c2fb_c_uint
    Dim c2fb_temp_15 As c2fb_c_uint Ptr
    Dim c2fb_temp_16 As c2fb_c_uint
    Dim local2 As c2fb_uint64
    Dim local3 As UByte
    Dim c2fb_temp_17 As Const UByte Ptr
    Dim c2fb_temp_18 As UByte
    Dim c2fb_temp_19 As c2fb_c_uint Ptr
    Dim c2fb_temp_20 As c2fb_c_uint

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_uint, (*arg0))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_1 = CPtr(c2fb_c_uint Ptr, @((*arg1)))
        c2fb_temp_2 = Cast(c2fb_c_uint, local0)
        (*c2fb_temp_1) = c2fb_temp_2
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_3 = arg0
    arg0 = (c2fb_temp_3 + 1)
    c2fb_temp_4 = Cast(c2fb_c_uint, (*arg0))
    local1 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_5 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7fULL)))))
        local0 = c2fb_temp_5
        c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 7ULL))))
        local0 = c2fb_temp_6
        c2fb_temp_7 = CPtr(c2fb_c_uint Ptr, @((*arg1)))
        c2fb_temp_8 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        (*c2fb_temp_7) = c2fb_temp_8
        Return Cast(c2fb_c_int, 2ULL)
    End If
    c2fb_temp_9 = arg0
    arg0 = (c2fb_temp_9 + 1)
    c2fb_temp_10 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 14ULL))))
    local0 = c2fb_temp_10
    c2fb_temp_11 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or Cast(c2fb_c_uint, (*arg0)))))
    local0 = c2fb_temp_11
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_12 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, &H7fULL) Shl Cast(c2fb_c_int, 14ULL)))) Or (Cast(c2fb_c_int, &H7fULL))))))))
        local0 = c2fb_temp_12
        c2fb_temp_13 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7fULL)))))
        local1 = c2fb_temp_13
        c2fb_temp_14 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 7ULL))))
        local1 = c2fb_temp_14
        c2fb_temp_15 = CPtr(c2fb_c_uint Ptr, @((*arg1)))
        c2fb_temp_16 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        (*c2fb_temp_15) = c2fb_temp_16
        Return Cast(c2fb_c_int, 3ULL)
    End If
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_17 = CPtr(Const UByte Ptr, (arg0 - Cast(c2fb_c_int, 2ULL)))
    arg0 = c2fb_temp_17
    c2fb_temp_18 = Cast(UByte, sqlite3Fts5GetVarint(arg0, CPtr(c2fb_uint64 Ptr, @(local2))))
    local3 = c2fb_temp_18
#ifdef SQLITE_DEBUG
    If local3 <= 3 OrElse local3 > 9 Then _
        sqlite3DebugAssert(StrPtr(!"n>3 && n<=9"))
#endif
    c2fb_temp_19 = CPtr(c2fb_c_uint Ptr, @((*arg1)))
    c2fb_temp_20 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, local2)) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7FFFFFFFULL)))))
    (*c2fb_temp_19) = c2fb_temp_20
    ' C unused-parameter annotation
    Return local3
End Function
Function sqlite3Fts5GetVarint CDecl Alias "sqlite3Fts5GetVarint" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_uint64 Ptr) As UByte
' c2fb source-path: ext/fts5/fts5_varint.c
' c2fb source-line: 102
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_c_uint
    Dim local2 As c2fb_c_uint
    Dim expectedMask2 As c2fb_c_uint
    Dim expectedMask4 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_uint64 Ptr
    Dim c2fb_temp_2 As c2fb_uint64
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim c2fb_temp_8 As c2fb_uint64 Ptr
    Dim c2fb_temp_9 As c2fb_uint64
    Dim c2fb_temp_10 As Const UByte Ptr
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim c2fb_temp_12 As c2fb_c_uint
    Dim c2fb_temp_13 As c2fb_c_uint
    Dim c2fb_temp_14 As c2fb_c_uint
    Dim c2fb_temp_15 As c2fb_c_uint
    Dim c2fb_temp_16 As c2fb_c_uint
    Dim c2fb_temp_17 As c2fb_uint64 Ptr
    Dim c2fb_temp_18 As c2fb_uint64
    Dim c2fb_temp_19 As c2fb_c_uint
    Dim c2fb_temp_20 As Const UByte Ptr
    Dim c2fb_temp_21 As c2fb_c_uint
    Dim c2fb_temp_22 As c2fb_c_uint
    Dim c2fb_temp_23 As c2fb_c_uint
    Dim c2fb_temp_24 As c2fb_c_uint
    Dim c2fb_temp_25 As c2fb_c_uint
    Dim c2fb_temp_26 As c2fb_uint64 Ptr
    Dim c2fb_temp_27 As c2fb_uint64
    Dim c2fb_temp_28 As c2fb_c_uint
    Dim c2fb_temp_29 As c2fb_c_uint
    Dim c2fb_temp_30 As Const UByte Ptr
    Dim c2fb_temp_31 As c2fb_c_uint
    Dim c2fb_temp_32 As c2fb_c_uint
    Dim c2fb_temp_33 As c2fb_c_uint
    Dim c2fb_temp_34 As c2fb_c_uint
    Dim c2fb_temp_35 As c2fb_c_uint
    Dim c2fb_temp_36 As c2fb_uint64 Ptr
    Dim c2fb_temp_37 As c2fb_uint64
    Dim c2fb_temp_38 As c2fb_c_uint
    Dim c2fb_temp_39 As c2fb_c_uint
    Dim c2fb_temp_40 As Const UByte Ptr
    Dim c2fb_temp_41 As c2fb_c_uint
    Dim c2fb_temp_42 As c2fb_c_uint
    Dim c2fb_temp_43 As c2fb_c_uint
    Dim c2fb_temp_44 As c2fb_c_uint
    Dim c2fb_temp_45 As c2fb_c_uint
    Dim c2fb_temp_46 As c2fb_c_uint
    Dim c2fb_temp_47 As c2fb_uint64 Ptr
    Dim c2fb_temp_48 As c2fb_uint64
    Dim c2fb_temp_49 As Const UByte Ptr
    Dim c2fb_temp_50 As c2fb_c_uint
    Dim c2fb_temp_51 As c2fb_c_uint
    Dim c2fb_temp_52 As c2fb_c_uint
    Dim c2fb_temp_53 As c2fb_c_uint
    Dim c2fb_temp_54 As c2fb_c_uint
    Dim c2fb_temp_55 As c2fb_c_uint
    Dim c2fb_temp_56 As c2fb_c_uint
    Dim c2fb_temp_57 As c2fb_uint64 Ptr
    Dim c2fb_temp_58 As c2fb_uint64
    Dim c2fb_temp_59 As c2fb_c_uint
    Dim c2fb_temp_60 As Const UByte Ptr
    Dim c2fb_temp_61 As c2fb_c_uint
    Dim c2fb_temp_62 As c2fb_c_uint
    Dim c2fb_temp_63 As c2fb_c_uint
    Dim c2fb_temp_64 As c2fb_c_uint
    Dim c2fb_temp_65 As c2fb_c_uint
    Dim c2fb_temp_66 As c2fb_c_uint
    Dim c2fb_temp_67 As c2fb_uint64 Ptr
    Dim c2fb_temp_68 As c2fb_uint64
    Dim c2fb_temp_69 As Const UByte Ptr
    Dim c2fb_temp_70 As c2fb_c_uint
    Dim c2fb_temp_71 As c2fb_c_uint
    Dim c2fb_temp_72 As c2fb_c_uint
    Dim c2fb_temp_73 As c2fb_c_uint
    Dim c2fb_temp_74 As c2fb_c_uint
    Dim c2fb_temp_75 As c2fb_c_uint
    Dim c2fb_temp_76 As c2fb_c_uint
    Dim c2fb_temp_77 As c2fb_c_uint
    Dim c2fb_temp_78 As c2fb_c_uint
    Dim c2fb_temp_79 As c2fb_c_uint
    Dim c2fb_temp_80 As c2fb_uint64 Ptr
    Dim c2fb_temp_81 As c2fb_uint64

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_uint, (*arg0))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_1 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_2 = Cast(c2fb_uint64, local0)
        (*c2fb_temp_1) = c2fb_temp_2
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_3 = arg0
    arg0 = (c2fb_temp_3 + 1)
    c2fb_temp_4 = Cast(c2fb_c_uint, (*arg0))
    local1 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_5 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7fULL)))))
        local0 = c2fb_temp_5
        c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 7ULL))))
        local0 = c2fb_temp_6
        c2fb_temp_7 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        local0 = c2fb_temp_7
        c2fb_temp_8 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_9 = Cast(c2fb_uint64, local0)
        (*c2fb_temp_8) = c2fb_temp_9
        Return Cast(c2fb_c_int, 2ULL)
    End If
#ifdef SQLITE_DEBUG
    expectedMask2 = Cast(c2fb_c_uint, _
        (Cast(c2fb_c_uint, &H7FULL) Shl 14) Or Cast(c2fb_c_uint, &H7FULL))
    expectedMask4 = Cast(c2fb_c_uint, _
        (Cast(c2fb_c_uint, &HFULL) Shl 28) Or _
        (Cast(c2fb_c_uint, &H7FULL) Shl 14) Or Cast(c2fb_c_uint, &H7FULL))
    If Cast(c2fb_c_uint, &H001FC07FULL) <> expectedMask2 Then _
        sqlite3DebugAssert(StrPtr(!"SLOT_2_0 expression"))
    If Cast(c2fb_c_uint, &HF01FC07FULL) <> expectedMask4 Then _
        sqlite3DebugAssert(StrPtr(!"SLOT_4_2_0 expression"))
#endif
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_10 = arg0
    arg0 = (c2fb_temp_10 + 1)
    c2fb_temp_11 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 14ULL))))
    local0 = c2fb_temp_11
    c2fb_temp_12 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or Cast(c2fb_c_uint, (*arg0)))))
    local0 = c2fb_temp_12
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_13 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H001fc07fULL)))))
        local0 = c2fb_temp_13
        c2fb_temp_14 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7fULL)))))
        local1 = c2fb_temp_14
        c2fb_temp_15 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 7ULL))))
        local1 = c2fb_temp_15
        c2fb_temp_16 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        local0 = c2fb_temp_16
        c2fb_temp_17 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_18 = Cast(c2fb_uint64, local0)
        (*c2fb_temp_17) = c2fb_temp_18
        Return Cast(c2fb_c_int, 3ULL)
    End If
    c2fb_temp_19 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H001fc07fULL)))))
    local0 = c2fb_temp_19
    c2fb_temp_20 = arg0
    arg0 = (c2fb_temp_20 + 1)
    c2fb_temp_21 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 14ULL))))
    local1 = c2fb_temp_21
    c2fb_temp_22 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Or Cast(c2fb_c_uint, (*arg0)))))
    local1 = c2fb_temp_22
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_23 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H001fc07fULL)))))
        local1 = c2fb_temp_23
        c2fb_temp_24 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 7ULL))))
        local0 = c2fb_temp_24
        c2fb_temp_25 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        local0 = c2fb_temp_25
        c2fb_temp_26 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_27 = Cast(c2fb_uint64, local0)
        (*c2fb_temp_26) = c2fb_temp_27
        Return Cast(c2fb_c_int, 4ULL)
    End If
    c2fb_temp_28 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H001fc07fULL)))))
    local1 = c2fb_temp_28
    c2fb_temp_29 = Cast(c2fb_c_uint, local0)
    local2 = c2fb_temp_29
    c2fb_temp_30 = arg0
    arg0 = (c2fb_temp_30 + 1)
    c2fb_temp_31 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 14ULL))))
    local0 = c2fb_temp_31
    c2fb_temp_32 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or Cast(c2fb_c_uint, (*arg0)))))
    local0 = c2fb_temp_32
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_33 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 7ULL))))
        local1 = c2fb_temp_33
        c2fb_temp_34 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        local0 = c2fb_temp_34
        c2fb_temp_35 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Shr Cast(c2fb_c_int, 18ULL))))
        local2 = c2fb_temp_35
        c2fb_temp_36 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_37 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, local2)) Shl Cast(c2fb_c_int, 32ULL))) Or Cast(c2fb_uint64, local0))))
        (*c2fb_temp_36) = c2fb_temp_37
        Return Cast(c2fb_c_int, 5ULL)
    End If
    c2fb_temp_38 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Shl Cast(c2fb_c_int, 7ULL))))
    local2 = c2fb_temp_38
    c2fb_temp_39 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Or local1)))
    local2 = c2fb_temp_39
    c2fb_temp_40 = arg0
    arg0 = (c2fb_temp_40 + 1)
    c2fb_temp_41 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 14ULL))))
    local1 = c2fb_temp_41
    c2fb_temp_42 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Or Cast(c2fb_c_uint, (*arg0)))))
    local1 = c2fb_temp_42
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_43 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H001fc07fULL)))))
        local0 = c2fb_temp_43
        c2fb_temp_44 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 7ULL))))
        local0 = c2fb_temp_44
        c2fb_temp_45 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        local0 = c2fb_temp_45
        c2fb_temp_46 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Shr Cast(c2fb_c_int, 18ULL))))
        local2 = c2fb_temp_46
        c2fb_temp_47 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_48 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, local2)) Shl Cast(c2fb_c_int, 32ULL))) Or Cast(c2fb_uint64, local0))))
        (*c2fb_temp_47) = c2fb_temp_48
        Return Cast(c2fb_c_int, 6ULL)
    End If
    c2fb_temp_49 = arg0
    arg0 = (c2fb_temp_49 + 1)
    c2fb_temp_50 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 14ULL))))
    local0 = c2fb_temp_50
    c2fb_temp_51 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or Cast(c2fb_c_uint, (*arg0)))))
    local0 = c2fb_temp_51
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_52 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, &Hf01fc07fULL))))
        local0 = c2fb_temp_52
        c2fb_temp_53 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H001fc07fULL)))))
        local1 = c2fb_temp_53
        c2fb_temp_54 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 7ULL))))
        local1 = c2fb_temp_54
        c2fb_temp_55 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        local0 = c2fb_temp_55
        c2fb_temp_56 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Shr Cast(c2fb_c_int, 11ULL))))
        local2 = c2fb_temp_56
        c2fb_temp_57 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_58 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, local2)) Shl Cast(c2fb_c_int, 32ULL))) Or Cast(c2fb_uint64, local0))))
        (*c2fb_temp_57) = c2fb_temp_58
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_59 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H001fc07fULL)))))
    local0 = c2fb_temp_59
    c2fb_temp_60 = arg0
    arg0 = (c2fb_temp_60 + 1)
    c2fb_temp_61 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 14ULL))))
    local1 = c2fb_temp_61
    c2fb_temp_62 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Or Cast(c2fb_c_uint, (*arg0)))))
    local1 = c2fb_temp_62
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = 0))) Then
        c2fb_temp_63 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, &Hf01fc07fULL))))
        local1 = c2fb_temp_63
        c2fb_temp_64 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 7ULL))))
        local0 = c2fb_temp_64
        c2fb_temp_65 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
        local0 = c2fb_temp_65
        c2fb_temp_66 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Shr Cast(c2fb_c_int, 4ULL))))
        local2 = c2fb_temp_66
        c2fb_temp_67 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_68 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, local2)) Shl Cast(c2fb_c_int, 32ULL))) Or Cast(c2fb_uint64, local0))))
        (*c2fb_temp_67) = c2fb_temp_68
        Return Cast(c2fb_c_int, 8ULL)
    End If
    c2fb_temp_69 = arg0
    arg0 = (c2fb_temp_69 + 1)
    c2fb_temp_70 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Shl Cast(c2fb_c_int, 15ULL))))
    local0 = c2fb_temp_70
    c2fb_temp_71 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or Cast(c2fb_c_uint, (*arg0)))))
    local0 = c2fb_temp_71
    c2fb_temp_72 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H001fc07fULL)))))
    local1 = c2fb_temp_72
    c2fb_temp_73 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 8ULL))))
    local1 = c2fb_temp_73
    c2fb_temp_74 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 Or local1)))
    local0 = c2fb_temp_74
    c2fb_temp_75 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Shl Cast(c2fb_c_int, 4ULL))))
    local2 = c2fb_temp_75
    c2fb_temp_76 = Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 4ULL)))])
    local1 = c2fb_temp_76
    c2fb_temp_77 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7fULL)))))
    local1 = c2fb_temp_77
    c2fb_temp_78 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local1 Shr Cast(c2fb_c_int, 3ULL))))
    local1 = c2fb_temp_78
    c2fb_temp_79 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Or local1)))
    local2 = c2fb_temp_79
    c2fb_temp_80 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
    c2fb_temp_81 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, local2)) Shl Cast(c2fb_c_int, 32ULL))) Or Cast(c2fb_uint64, local0))))
    (*c2fb_temp_80) = c2fb_temp_81
    Return Cast(c2fb_c_int, 9ULL)
End Function
Private Function fts5PutVarint64 CDecl Alias "fts5PutVarint64" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_uint64) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_varint.c
' c2fb source-line: 296
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3(0 To 9) As UByte
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As c2fb_uint64
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As c2fb_uint64
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As UByte
    Dim c2fb_temp_12 As c2fb_uint64
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As UByte Ptr
    Dim c2fb_temp_20 As UByte

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic array storage
    If Cast(c2fb_uint64, (arg1 And (Cast(c2fb_uint64, ((Cast(c2fb_uint64, Cast(c2fb_c_uint, &Hff000000ULL))) Shl Cast(c2fb_c_int, 32ULL)))))) Then
        c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 8ULL)]))
        c2fb_temp_1 = Cast(UByte, Cast(UByte, arg1))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_uint64, Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 8ULL))))
        arg1 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL)))))
            c2fb_temp_5 = CPtr(UByte Ptr, @(arg0[local0]))
            c2fb_temp_6 = Cast(UByte, Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7fULL))))) Or Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL)))))))
            (*c2fb_temp_5) = c2fb_temp_6
            c2fb_temp_7 = Cast(c2fb_uint64, Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 7ULL))))
            arg1 = c2fb_temp_7
        c2fb_flow_1:
            c2fb_temp_4 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 - 1)))
        Wend
        c2fb_flow_0:
        Return Cast(c2fb_c_int, 9ULL)
    End If
    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_8
    Do
        c2fb_temp_9 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
        c2fb_temp_10 = CPtr(UByte Ptr, @(local3(c2fb_temp_9)))
        c2fb_temp_11 = Cast(UByte, Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7fULL))))) Or Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL)))))))
        (*c2fb_temp_10) = c2fb_temp_11
        c2fb_temp_12 = Cast(c2fb_uint64, Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 7ULL))))
        arg1 = c2fb_temp_12
    c2fb_flow_3:
    Loop While (-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))))))
    c2fb_flow_2:
#ifdef SQLITE_DEBUG
    If local2 > 9 Then sqlite3DebugAssert(StrPtr(!"n<=9"))
#endif
    c2fb_temp_13 = CPtr(UByte Ptr, @(local3(Cast(c2fb_c_int, &O0ULL))))
    c2fb_temp_14 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_13)) And Cast(c2fb_c_int, &H7fULL))))
    (*c2fb_temp_13) = c2fb_temp_14
    ' C unused-parameter annotation
    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_15
    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL))))
    local1 = c2fb_temp_16
    While (-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL)))))
        c2fb_temp_19 = CPtr(UByte Ptr, @(arg0[local0]))
        c2fb_temp_20 = Cast(UByte, local3(local1))
        (*c2fb_temp_19) = c2fb_temp_20
    c2fb_flow_5:
        c2fb_temp_17 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 - 1)))
        c2fb_temp_18 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
    Wend
    c2fb_flow_4:
    Return local2
End Function
Function sqlite3Fts5PutVarint CDecl Alias "sqlite3Fts5PutVarint" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_uint64) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_varint.c
' c2fb source-line: 321
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte

    If (-Cast(c2fb_c_int, ((arg1 <= Cast(c2fb_uint64, Cast(c2fb_c_int, &H7fULL)))))) Then
        c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_uint64, (arg1 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7fULL)))))
        (*c2fb_temp_0) = c2fb_temp_1
        Return Cast(c2fb_c_int, 1ULL)
    End If
    If (-Cast(c2fb_c_int, ((arg1 <= Cast(c2fb_uint64, Cast(c2fb_c_int, &H3fffULL)))))) Then
        c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_3 = Cast(UByte, Cast(c2fb_uint64, ((Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 7ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7fULL))))) Or Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL)))))
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
        c2fb_temp_5 = Cast(UByte, Cast(c2fb_uint64, (arg1 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7fULL)))))
        (*c2fb_temp_4) = c2fb_temp_5
        Return Cast(c2fb_c_int, 2ULL)
    End If
    Return fts5PutVarint64(arg0, arg1)
End Function
Function sqlite3Fts5GetVarintLen CDecl Alias "sqlite3Fts5GetVarintLen" (ByVal arg0 As c2fb_c_uint) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_varint.c
' c2fb source-line: 335
#ifdef SQLITE_DEBUG
    If arg0 < 128 Then sqlite3DebugAssert(StrPtr(!"iVal>=(1 << 7)"))
#endif
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0 < Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 14ULL))))))))) Then
        Return Cast(c2fb_c_int, 2ULL)
    End If
    If (-Cast(c2fb_c_int, ((arg0 < Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 21ULL))))))))) Then
        Return Cast(c2fb_c_int, 3ULL)
    End If
    If (-Cast(c2fb_c_int, ((arg0 < Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 28ULL))))))))) Then
        Return Cast(c2fb_c_int, 4ULL)
    End If
    Return Cast(c2fb_c_int, 5ULL)
End Function
#endif

/' end of sqlite3_bulk_fts5_varint.bas '/
