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
** This is an SQLite module implementing full-text search.
'/

/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_primitives.bas

    Purpose:

        Port the low-level varint and text helpers used by FTS3/FTS4.

    Responsibilities:

        - Encode and decode FTS3's 7-bit continuation varints.
        - Dequote SQL tokenizer arguments and format FTS3 virtual-table errors.

    This file intentionally does NOT contain:

        - FTS3 segment storage, virtual-table planning, or query evaluation.
        - Test support.
'/

#lang "fb"
#include once "crt/stdarg.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

#ifndef __C2FB_BODY_C_ABI_TYPES__
#define __C2FB_BODY_C_ABI_TYPES__
Type c2fb_c_int As SQLITE_C_INT
Type c2fb_c_uint As SQLITE_C_UINT
Type c2fb_c_long As SQLITE_C_LONG
Type c2fb_c_ulong As SQLITE_C_ULONG
Type c2fb_int64 As sqlite3_int64
Type c2fb_uint64 As sqlite3_uint64
Type c2fb_size_t As SQLITE_SIZE_T
#endif

Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal pMemory As Any Ptr)
Declare Function c2fb_external_sqlite3_vmprintf__ CDecl Alias "sqlite3_vmprintf" ( _
    ByVal zFormat As Const ZString Ptr, _
    ByVal arguments As Cva_List _
) As ZString Ptr

Declare Function sqlite3Fts3PutVarint CDecl Alias "sqlite3Fts3PutVarint" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts3GetVarintU CDecl Alias "sqlite3Fts3GetVarintU" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_uint64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3GetVarint CDecl Alias "sqlite3Fts3GetVarint" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3GetVarintBounded CDecl Alias "sqlite3Fts3GetVarintBounded" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts3GetVarint32 CDecl Alias "sqlite3Fts3GetVarint32" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts3VarintLen CDecl Alias "sqlite3Fts3VarintLen" (ByVal arg0 As c2fb_uint64) As c2fb_c_int
Declare Sub sqlite3Fts3Dequote CDecl Alias "sqlite3Fts3Dequote" (ByVal arg0 As ZString Ptr)
Declare Sub sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)

/' ------------------------------------------------------------------------- '/
/' FTS3 varint and argument helpers                                          '/
/' ------------------------------------------------------------------------- '/

/'
    FTS3 stores an unsigned 64-bit varint in one to ten bytes. Each byte
    carries seven payload bits; its high bit indicates that another byte
    follows. The final byte clears the high bit. Callers provide input buffers
    with the FTS3 padding and length guarantees required by each decoder.
'/
Function sqlite3Fts3PutVarint CDecl Alias "sqlite3Fts3PutVarint" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int Export
    If arg0 = 0 Then Return 0
' c2fb source-path: ext/fts3/fts3.c
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_uint64
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As UByte
    Dim c2fb_temp_3 As c2fb_uint64
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte

    local0 = CPtr(UByte Ptr, arg0)
    local1 = arg1
    Do
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = CPtr(UByte Ptr, @((*c2fb_temp_0)))
        c2fb_temp_2 = Cast(UByte, Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7fULL))))) Or Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL)))))))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 Shr Cast(c2fb_c_int, 7ULL))))
        local1 = c2fb_temp_3
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))))))
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(UByte Ptr, @(local0[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))]))
    c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_4)) And Cast(c2fb_c_int, &H7fULL))))
    (*c2fb_temp_4) = c2fb_temp_5
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, ((CPtr(UByte Ptr, local0) - CPtr(UByte Ptr, CPtr(UByte Ptr, arg0)))))
End Function

Function sqlite3Fts3GetVarintU CDecl Alias "sqlite3Fts3GetVarintU" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_uint64 Ptr) As c2fb_c_int Export
    If arg0 = 0 OrElse arg1 = 0 Then Return 0
' c2fb source-path: ext/fts3/fts3.c
    Dim local0 As Const UByte Ptr
    Dim local1 As Const UByte Ptr
    Dim local2 As c2fb_c_uint
    Dim local3 As c2fb_uint64
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As Const UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_uint64 Ptr
    Dim c2fb_temp_3 As c2fb_uint64
    Dim c2fb_temp_4 As Const UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_uint64 Ptr
    Dim c2fb_temp_8 As c2fb_uint64
    Dim c2fb_temp_9 As Const UByte Ptr
    Dim c2fb_temp_10 As c2fb_c_uint
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim c2fb_temp_12 As c2fb_uint64 Ptr
    Dim c2fb_temp_13 As c2fb_uint64
    Dim c2fb_temp_14 As Const UByte Ptr
    Dim c2fb_temp_15 As c2fb_c_uint
    Dim c2fb_temp_16 As c2fb_c_uint
    Dim c2fb_temp_17 As c2fb_uint64 Ptr
    Dim c2fb_temp_18 As c2fb_uint64
    Dim c2fb_temp_19 As c2fb_uint64
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Const UByte Ptr
    Dim local5 As c2fb_uint64
    Dim c2fb_temp_23 As c2fb_uint64
    Dim c2fb_temp_24 As c2fb_uint64 Ptr
    Dim c2fb_temp_25 As c2fb_uint64

    local0 = CPtr(Const UByte Ptr, arg0)
    local1 = local0
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = local0
    local0 = (c2fb_temp_0 + 1)
    c2fb_temp_1 = Cast(c2fb_c_uint, ((*c2fb_temp_0)))
    local2 = c2fb_temp_1
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_2 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_3 = Cast(c2fb_uint64, local2)
        (*c2fb_temp_2) = c2fb_temp_3
        Return Cast(c2fb_c_int, 1ULL)
    End If
    ' empty C statement
    c2fb_temp_5 = (Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7FULL)))))
    c2fb_temp_4 = local0
    local0 = (c2fb_temp_4 + 1)
    c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_5 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_4))))) Shl Cast(c2fb_c_int, 7ULL))))))))
    local2 = c2fb_temp_6
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H4000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_7 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_8 = Cast(c2fb_uint64, local2)
        (*c2fb_temp_7) = c2fb_temp_8
        Return Cast(c2fb_c_int, 2ULL)
    End If
    ' empty C statement
    c2fb_temp_10 = (Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FFFULL)))))
    c2fb_temp_9 = local0
    local0 = (c2fb_temp_9 + 1)
    c2fb_temp_11 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_10 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_9))))) Shl Cast(c2fb_c_int, 14ULL))))))))
    local2 = c2fb_temp_11
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H200000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_12 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_13 = Cast(c2fb_uint64, local2)
        (*c2fb_temp_12) = c2fb_temp_13
        Return Cast(c2fb_c_int, 3ULL)
    End If
    ' empty C statement
    c2fb_temp_15 = (Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H1FFFFFULL)))))
    c2fb_temp_14 = local0
    local0 = (c2fb_temp_14 + 1)
    c2fb_temp_16 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_15 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_14))))) Shl Cast(c2fb_c_int, 21ULL))))))))
    local2 = c2fb_temp_16
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H10000000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_17 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
        c2fb_temp_18 = Cast(c2fb_uint64, local2)
        (*c2fb_temp_17) = c2fb_temp_18
        Return Cast(c2fb_c_int, 4ULL)
    End If
    ' empty C statement
    c2fb_temp_19 = Cast(c2fb_uint64, (Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H0FFFFFFFULL))))))
    local3 = c2fb_temp_19
    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, 28ULL))
    local4 = c2fb_temp_20
    While (-Cast(c2fb_c_int, ((local4 <= Cast(c2fb_c_int, 63ULL)))))
        c2fb_temp_22 = local0
        local0 = (c2fb_temp_22 + 1)
        local5 = (*c2fb_temp_22)
        c2fb_temp_23 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local3 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local5 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7FULL))))) Shl local4)))))
        local3 = c2fb_temp_23
        If (-Cast(c2fb_c_int, (((Cast(c2fb_uint64, (local5 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL))))) = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 7ULL))))
        local4 = c2fb_temp_21
    Wend
    c2fb_flow_0:
    c2fb_temp_24 = CPtr(c2fb_uint64 Ptr, @((*arg1)))
    c2fb_temp_25 = Cast(c2fb_uint64, local3)
    (*c2fb_temp_24) = c2fb_temp_25
    Return Cast(c2fb_c_int, ((CPtr(UByte Ptr, local0) - CPtr(UByte Ptr, local1))))
End Function

Function sqlite3Fts3GetVarint CDecl Alias "sqlite3Fts3GetVarint" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int Export
    If arg0 = 0 OrElse arg1 = 0 Then Return 0
' c2fb source-path: ext/fts3/fts3.c
    Return sqlite3Fts3GetVarintU(arg0, CPtr(c2fb_uint64 Ptr, arg1))
End Function

Function sqlite3Fts3GetVarintBounded CDecl Alias "sqlite3Fts3GetVarintBounded" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int Export
    If arg0 = 0 OrElse arg1 = 0 OrElse arg2 = 0 Then Return 0
' c2fb source-path: ext/fts3/fts3.c
    Dim local0 As Const UByte Ptr
    Dim local1 As Const UByte Ptr
    Dim local2 As Const UByte Ptr
    Dim local3 As c2fb_uint64
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As c2fb_uint64
    Dim c2fb_temp_2 As Const UByte Ptr
    Dim c2fb_temp_3 As c2fb_uint64
    Dim c2fb_temp_4 As c2fb_int64 Ptr
    Dim c2fb_temp_5 As c2fb_int64

    local0 = CPtr(Const UByte Ptr, arg0)
    local1 = local0
    local2 = CPtr(Const UByte Ptr, arg1)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local4 <= Cast(c2fb_c_int, 63ULL)))))
        local5 = IIf((-Cast(c2fb_c_int, ((local0 < local2)))), Cast(c2fb_c_int, (*local0)), Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_2 = local0
        local0 = (c2fb_temp_2 + 1)
        c2fb_temp_3 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local3 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local5 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H7FULL))))) Shl local4)))))
        local3 = c2fb_temp_3
        If (-Cast(c2fb_c_int, (((Cast(c2fb_uint64, (local5 And Cast(c2fb_uint64, Cast(c2fb_c_int, &H80ULL))))) = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 7ULL))))
        local4 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(c2fb_int64 Ptr, @((*arg2)))
    c2fb_temp_5 = Cast(c2fb_int64, local3)
    (*c2fb_temp_4) = c2fb_temp_5
    Return Cast(c2fb_c_int, ((CPtr(UByte Ptr, local0) - CPtr(UByte Ptr, local1))))
End Function

Function sqlite3Fts3GetVarint32 CDecl Alias "sqlite3Fts3GetVarint32" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int Export
    If arg0 = 0 OrElse arg1 = 0 Then Return 0
' c2fb source-path: ext/fts3/fts3.c
    Dim local0 As Const UByte Ptr
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As Const UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As Const UByte Ptr
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Const UByte Ptr
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As c2fb_c_uint
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Const UByte Ptr
    Dim c2fb_temp_13 As c2fb_c_uint
    Dim c2fb_temp_14 As c2fb_c_uint
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_uint
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int

    local0 = CPtr(Const UByte Ptr, arg0)
    ' C automatic storage declaration
    c2fb_temp_0 = local0
    local0 = (c2fb_temp_0 + 1)
    c2fb_temp_1 = Cast(c2fb_c_uint, ((*c2fb_temp_0)))
    local1 = c2fb_temp_1
    ' C unused-parameter annotation
    c2fb_temp_3 = (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7FULL)))))
    c2fb_temp_2 = local0
    local0 = (c2fb_temp_2 + 1)
    c2fb_temp_4 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_3 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_2))))) Shl Cast(c2fb_c_int, 7ULL))))))))
    local1 = c2fb_temp_4
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H4000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_6 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_5) = c2fb_temp_6
        Return Cast(c2fb_c_int, 2ULL)
    End If
    ' empty C statement
    c2fb_temp_8 = (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FFFULL)))))
    c2fb_temp_7 = local0
    local0 = (c2fb_temp_7 + 1)
    c2fb_temp_9 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_8 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_7))))) Shl Cast(c2fb_c_int, 14ULL))))))))
    local1 = c2fb_temp_9
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H200000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_11 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_10) = c2fb_temp_11
        Return Cast(c2fb_c_int, 3ULL)
    End If
    ' empty C statement
    c2fb_temp_13 = (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H1FFFFFULL)))))
    c2fb_temp_12 = local0
    local0 = (c2fb_temp_12 + 1)
    c2fb_temp_14 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_13 Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*CPtr(Const UByte Ptr, (c2fb_temp_12))))) Shl Cast(c2fb_c_int, 21ULL))))))))
    local1 = c2fb_temp_14
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H10000000ULL))))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_16 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_15) = c2fb_temp_16
        Return Cast(c2fb_c_int, 4ULL)
    End If
    ' empty C statement
    c2fb_temp_17 = Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (local1 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H0FFFFFFFULL))))))
    local1 = c2fb_temp_17
    c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_uint, (local1 Or (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local0)) And Cast(c2fb_c_int, &H07ULL))))) Shl Cast(c2fb_c_int, 28ULL)))))))))
    (*c2fb_temp_18) = c2fb_temp_19
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, 5ULL)
End Function

Function sqlite3Fts3VarintLen CDecl Alias "sqlite3Fts3VarintLen" (ByVal arg0 As c2fb_uint64) As c2fb_c_int Export
' c2fb source-path: ext/fts3/fts3.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_uint64

    local0 = Cast(c2fb_c_int, &O0ULL)
    Do
        c2fb_temp_0 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        c2fb_temp_1 = Cast(c2fb_uint64, Cast(c2fb_uint64, (arg0 Shr Cast(c2fb_c_int, 7ULL))))
        arg0 = c2fb_temp_1
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((arg0 <> Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))))))
    c2fb_flow_0:
    Return local0
End Function

Sub sqlite3Fts3Dequote CDecl Alias "sqlite3Fts3Dequote" (ByVal arg0 As ZString Ptr) Export
    If arg0 = 0 Then Exit Sub
' c2fb source-path: ext/fts3/fts3.c
    Dim local0 As Byte
    Dim c2fb_temp_0 As Byte
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As Byte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Byte Ptr
    Dim c2fb_temp_4 As Byte
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Byte Ptr
    Dim c2fb_temp_9 As Byte
    Dim c2fb_temp_10 As Byte Ptr
    Dim c2fb_temp_11 As Byte

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(Byte, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)])
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 91))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 39))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 34))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 96))))) <> 0))))) Then
        local1 = Cast(c2fb_c_int, 1ULL)
        local2 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0) = Cast(c2fb_c_int, 91))))) Then
            c2fb_temp_1 = Cast(Byte, Cast(c2fb_c_int, 93))
            local0 = c2fb_temp_1
        End If
        While CPtr(Byte Ptr, arg0)[local1]
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[local1]) = Cast(c2fb_c_int, local0))))) Then
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))]) <> Cast(c2fb_c_int, local0))))) Then
                    Goto c2fb_flow_0
                End If
                c2fb_temp_2 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                c2fb_temp_3 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[c2fb_temp_2]))
                c2fb_temp_4 = Cast(Byte, local0)
                (*c2fb_temp_3) = c2fb_temp_4
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 2ULL))))
                local1 = c2fb_temp_5
            Else
                c2fb_temp_6 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
                c2fb_temp_8 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[c2fb_temp_6]))
                c2fb_temp_7 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
                c2fb_temp_9 = Cast(Byte, CPtr(Byte Ptr, arg0)[c2fb_temp_7])
                (*c2fb_temp_8) = c2fb_temp_9
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_10 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[local2]))
        c2fb_temp_11 = Cast(Byte, Cast(c2fb_c_int, 0))
        (*c2fb_temp_10) = c2fb_temp_11
    End If
End Sub

Sub sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...) Export
    If arg0 = 0 Then Exit Sub
' c2fb source-path: ext/fts3/fts3.c
    Dim local0 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr

    ' C automatic storage declaration
    sqlite3_free(CPtr(Any Ptr, (*arg0)))
    Cva_Start(local0, arg1)
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf__(arg1, local0))
    (*c2fb_temp_0) = c2fb_temp_1
    Cva_End(local0)
End Sub

#endif

/' end of sqlite3_bulk_fts3_primitives.bas '/
