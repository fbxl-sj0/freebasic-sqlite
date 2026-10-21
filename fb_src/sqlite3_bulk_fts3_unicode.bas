/'
** 2012 May 24
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
** Implementation of the "unicode" full-text-search tokenizer.
'/
/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_unicode.bas

    Purpose:

        Port the FTS3 Unicode tokenizer routines from ext/fts3/fts3_unicode.c.

    Responsibilities:

        - Create and destroy the Unicode tokenizer state.
        - Fold codepoints and find token byte ranges in UTF-8 input.
        - Apply tokenizer exceptions and diacritic-removal settings.

    This file intentionally does NOT contain:

        - Generated Unicode classification and folding tables.
        - Registration of the Unicode module in the FTS3 tokenizer hash.
        - FTS3 virtual-table query logic.
        - Test support.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE) AndAlso _
    Not defined(SQLITE_DISABLE_FTS3_UNICODE)
#include once "sqlite3_btree.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_expr_types.bi"
#include once "sqlite3_hash_types.bi"
#include once "sqlite3_pager.bi"
#include once "sqlite3_parser_types.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_vdbe_core.bi"
#include once "sqlite3_vdbe_mem_types.bi"
#include once "sqlite3_fts3_unicode_types.bi"
#include once "sqlite3_fts3_tokenizer_types.bi"

/' ------------------------------------------------------------------------- '/
/' FTS3 Unicode tokenizer routines                                            '/
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
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int

Private Type c2fb_source_record_366
    pModule As Any Ptr
End Type

Private Type c2fb_source_record_367
    pTokenizer As c2fb_source_record_366 Ptr
End Type

Private Type c2fb_source_record_379
    base As c2fb_source_record_366
    eRemoveDiacritic As c2fb_c_int
    nException As c2fb_c_int
    aiException As c2fb_c_int Ptr
End Type

Private Type c2fb_source_record_380
    base As c2fb_source_record_367
    aInput As Const UByte Ptr
    nInput As c2fb_c_int
    iOff As c2fb_c_int
    iToken As c2fb_c_int
    zToken As ZString Ptr
    nAlloc As c2fb_c_int
End Type

Declare Function unicodeDestroy CDecl Alias "unicodeDestroy" (ByVal arg0 As c2fb_source_record_366 Ptr) As c2fb_c_int
Declare Function unicodeAddExceptions CDecl Alias "unicodeAddExceptions" (ByVal arg0 As c2fb_source_record_379 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function unicodeIsException CDecl Alias "unicodeIsException" (ByVal arg0 As c2fb_source_record_379 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function unicodeIsAlnum CDecl Alias "unicodeIsAlnum" (ByVal arg0 As c2fb_source_record_379 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function unicodeCreate CDecl Alias "unicodeCreate" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_source_record_366 Ptr Ptr) As c2fb_c_int
Declare Function unicodeOpen CDecl Alias "unicodeOpen" (ByVal arg0 As c2fb_source_record_366 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_367 Ptr Ptr) As c2fb_c_int
Declare Function unicodeClose CDecl Alias "unicodeClose" (ByVal arg0 As c2fb_source_record_367 Ptr) As c2fb_c_int
Declare Function unicodeNext CDecl Alias "unicodeNext" (ByVal arg0 As c2fb_source_record_367 Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Private Dim Shared c2fb_global_sqlite3Utf8Trans1(0 To 63) As Const UByte = {&H00, &H01, &H02, &H03, &H04, &H05, &H06, &H07, &H08, &H09, &H0a, &H0b, &H0c, &H0d, &H0e, &H0f, &H10, &H11, &H12, &H13, &H14, &H15, &H16, &H17, &H18, &H19, &H1a, &H1b, &H1c, &H1d, &H1e, &H1f, &H00, &H01, &H02, &H03, &H04, &H05, &H06, &H07, &H08, &H09, &H0a, &H0b, &H0c, &H0d, &H0e, &H0f, &H00, &H01, &H02, &H03, &H04, &H05, &H06, &H07, &H00, &H01, &H02, &H03, &H00, &H01, &H00, &H00}
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
Private Function unicodeDestroy CDecl Alias "unicodeDestroy" (ByVal arg0 As c2fb_source_record_366 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_unicode.c
    Dim local0 As c2fb_source_record_379 Ptr

    If arg0 Then
        local0 = CPtr(c2fb_source_record_379 Ptr, arg0)
        sqlite3_free(CPtr(Any Ptr, local0->aiException))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function unicodeAddExceptions CDecl Alias "unicodeAddExceptions" (ByVal arg0 As c2fb_source_record_379 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_unicode.c
    Dim local0 As Const UByte Ptr
    Dim local1 As Const UByte Ptr
    Dim local2 As c2fb_c_uint
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As Const UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local4 As c2fb_c_int Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Const UByte Ptr
    Dim c2fb_temp_12 As Const UByte Ptr
    Dim c2fb_temp_13 As c2fb_c_uint
    Dim c2fb_temp_14 As c2fb_c_uint
    Dim c2fb_temp_15 As Const UByte Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_uint
    Dim c2fb_temp_18 As c2fb_c_uint
    Dim c2fb_temp_19 As c2fb_c_uint
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int Ptr Ptr
    Dim c2fb_temp_30 As c2fb_c_int Ptr
    Dim c2fb_temp_31 As c2fb_c_int Ptr
    Dim c2fb_temp_32 As c2fb_c_int

    local0 = CPtr(Const UByte Ptr, arg2)
    local1 = CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0[arg3])))
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((local0 < local1))))
        c2fb_temp_0 = local0
        local0 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = Cast(c2fb_c_uint, (*(c2fb_temp_0)))
        local2 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
            c2fb_temp_2 = Cast(c2fb_c_uint, c2fb_global_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local2 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
            local2 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 <> local1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local0)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                c2fb_temp_5 = (Cast(c2fb_c_uint, (local2 Shl Cast(c2fb_c_int, 6ULL))))
                c2fb_temp_4 = Cast(c2fb_c_int, &H3fULL)
                c2fb_temp_3 = local0
                local0 = (c2fb_temp_3 + 1)
                c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_5 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_4 And Cast(c2fb_c_int, (*(c2fb_temp_3))))))))))
                local2 = c2fb_temp_6
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                c2fb_temp_7 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                local2 = c2fb_temp_7
            End If
        End If
        ' empty C statement
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((sqlite3FtsUnicodeIsalnum(Cast(c2fb_c_int, local2)) <> arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((sqlite3FtsUnicodeIsdiacritic(Cast(c2fb_c_int, local2)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_8 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If local3 Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->aiException), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (arg0->nException + local3)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))))))
        local4 = c2fb_temp_9
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_10 = Cast(c2fb_c_int, arg0->nException)
        local5 = c2fb_temp_10
        c2fb_temp_11 = CPtr(Const UByte Ptr, arg2)
        local0 = c2fb_temp_11
        While (-Cast(c2fb_c_int, ((local0 < local1))))
            c2fb_temp_12 = local0
            local0 = (c2fb_temp_12 + 1)
            c2fb_temp_13 = Cast(c2fb_c_uint, (*(c2fb_temp_12)))
            local2 = c2fb_temp_13
            If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
                c2fb_temp_14 = Cast(c2fb_c_uint, c2fb_global_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local2 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
                local2 = c2fb_temp_14
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 <> local1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local0)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                    c2fb_temp_17 = (Cast(c2fb_c_uint, (local2 Shl Cast(c2fb_c_int, 6ULL))))
                    c2fb_temp_16 = Cast(c2fb_c_int, &H3fULL)
                    c2fb_temp_15 = local0
                    local0 = (c2fb_temp_15 + 1)
                    c2fb_temp_18 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_17 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_16 And Cast(c2fb_c_int, (*(c2fb_temp_15))))))))))
                    local2 = c2fb_temp_18
                c2fb_flow_7:
                Wend
                c2fb_flow_6:
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                    c2fb_temp_19 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                    local2 = c2fb_temp_19
                End If
            End If
            ' empty C statement
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((sqlite3FtsUnicodeIsalnum(Cast(c2fb_c_int, local2)) <> arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((sqlite3FtsUnicodeIsdiacritic(Cast(c2fb_c_int, local2)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local6 = c2fb_temp_20
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 < local5)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4[local6] < Cast(c2fb_c_int, local2))))) <> 0)))))
                    ' empty C statement
                c2fb_flow_9:
                    c2fb_temp_21 = local6
                    local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
                Wend
                c2fb_flow_8:
                c2fb_temp_22 = Cast(c2fb_c_int, local5)
                local7 = c2fb_temp_22
                While (-Cast(c2fb_c_int, ((local7 > local6))))
                    c2fb_temp_24 = CPtr(c2fb_c_int Ptr, @(local4[local7]))
                    c2fb_temp_25 = Cast(c2fb_c_int, local4[Cast(c2fb_c_int, (local7 - Cast(c2fb_c_int, 1ULL)))])
                    (*c2fb_temp_24) = c2fb_temp_25
                c2fb_flow_11:
                    c2fb_temp_23 = local7
                    local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_23 - 1)))
                Wend
                c2fb_flow_10:
                c2fb_temp_26 = CPtr(c2fb_c_int Ptr, @(local4[local6]))
                c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, local2))
                (*c2fb_temp_26) = c2fb_temp_27
                c2fb_temp_28 = local5
                local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
            End If
        c2fb_flow_5:
        Wend
        c2fb_flow_4:
        c2fb_temp_29 = CPtr(c2fb_c_int Ptr Ptr, @(arg0->aiException))
        c2fb_temp_30 = local4
        (*c2fb_temp_29) = c2fb_temp_30
        c2fb_temp_31 = CPtr(c2fb_c_int Ptr, @(arg0->nException))
        c2fb_temp_32 = Cast(c2fb_c_int, local5)
        (*c2fb_temp_31) = c2fb_temp_32
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function unicodeIsException CDecl Alias "unicodeIsException" (ByVal arg0 As c2fb_source_record_379 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_unicode.c
    Dim local0 As c2fb_c_int Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->nException > Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = arg0->aiException
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = Cast(c2fb_c_int, (arg0->nException - Cast(c2fb_c_int, 1ULL)))
        While (-Cast(c2fb_c_int, ((local2 >= local1))))
            local3 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local2 + local1))) \ Cast(c2fb_c_int, 2ULL)))
            If (-Cast(c2fb_c_int, ((arg1 = local0[local3])))) Then
                Return Cast(c2fb_c_int, 1ULL)
            Else
                If (-Cast(c2fb_c_int, ((arg1 > local0[local3])))) Then
                    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))
                    local1 = c2fb_temp_0
                Else
                    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, 1ULL))))
                    local2 = c2fb_temp_1
                End If
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function unicodeIsAlnum CDecl Alias "unicodeIsAlnum" (ByVal arg0 As c2fb_source_record_379 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_unicode.c
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, (sqlite3FtsUnicodeIsalnum(arg1) Xor unicodeIsException(arg0, arg1)))
End Function
Private Function unicodeCreate CDecl Alias "unicodeCreate" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_source_record_366 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_unicode.c
    Dim local0 As c2fb_source_record_379 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_source_record_379 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_source_record_379 Ptr
    Dim c2fb_temp_16 As c2fb_source_record_366 Ptr Ptr
    Dim c2fb_temp_17 As c2fb_source_record_366 Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_source_record_379 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_379)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = (CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_379))))
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(local0->eRemoveDiacritic))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < arg0)))) <> 0)))))
        local3 = arg1[local1]
        local4 = Cast(c2fb_c_int, c2fb_crt_strlen(local3))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 19ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"remove_diacritics=1")), CPtr(Const Any Ptr, local3), Cast(c2fb_c_int, 19ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(local0->eRemoveDiacritic))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_6) = c2fb_temp_7
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 19ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"remove_diacritics=0")), CPtr(Const Any Ptr, local3), Cast(c2fb_c_int, 19ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(local0->eRemoveDiacritic))
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_8) = c2fb_temp_9
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 19ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"remove_diacritics=2")), CPtr(Const Any Ptr, local3), Cast(c2fb_c_int, 19ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(local0->eRemoveDiacritic))
                    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                    (*c2fb_temp_10) = c2fb_temp_11
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 >= Cast(c2fb_c_int, 11ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"tokenchars=")), CPtr(Const Any Ptr, local3), Cast(c2fb_c_int, 11ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        c2fb_temp_12 = Cast(c2fb_c_int, unicodeAddExceptions(local0, Cast(c2fb_c_int, 1ULL), CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, 11ULL)]))), Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 11ULL)))))
                        local2 = c2fb_temp_12
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 >= Cast(c2fb_c_int, 11ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"separators=")), CPtr(Const Any Ptr, local3), Cast(c2fb_c_int, 11ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                            c2fb_temp_13 = Cast(c2fb_c_int, unicodeAddExceptions(local0, Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, 11ULL)]))), Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 11ULL)))))
                            local2 = c2fb_temp_13
                        Else
                            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local2 = c2fb_temp_14
                        End If
                    End If
                End If
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_5 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        unicodeDestroy(CPtr(c2fb_source_record_366 Ptr, local0))
        c2fb_temp_15 = CPtr(c2fb_source_record_379 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_15
    End If
    c2fb_temp_16 = CPtr(c2fb_source_record_366 Ptr Ptr, @((*arg2)))
    c2fb_temp_17 = CPtr(c2fb_source_record_366 Ptr, local0)
    (*c2fb_temp_16) = c2fb_temp_17
    Return local2
End Function
Private Function unicodeOpen CDecl Alias "unicodeOpen" (ByVal arg0 As c2fb_source_record_366 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_367 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_unicode.c
    Dim local0 As c2fb_source_record_380 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_380 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Const UByte Ptr Ptr
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Const UByte Ptr Ptr
    Dim c2fb_temp_7 As Const UByte Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_source_record_367 Ptr Ptr
    Dim c2fb_temp_13 As c2fb_source_record_367 Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_380 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_380)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_380))))
    c2fb_temp_2 = CPtr(Const UByte Ptr Ptr, @(local0->aInput))
    c2fb_temp_3 = CPtr(Const UByte Ptr, arg1)
    (*c2fb_temp_2) = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(local0->nInput))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_4) = c2fb_temp_5
        c2fb_temp_6 = CPtr(Const UByte Ptr Ptr, @(local0->aInput))
        c2fb_temp_7 = CPtr(Const UByte Ptr, StrPtr(!""))
        (*c2fb_temp_6) = c2fb_temp_7
    Else
        If (-Cast(c2fb_c_int, ((arg2 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(local0->nInput))
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(arg1)))
            (*c2fb_temp_8) = c2fb_temp_9
        Else
            c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(local0->nInput))
            c2fb_temp_11 = Cast(c2fb_c_int, arg2)
            (*c2fb_temp_10) = c2fb_temp_11
        End If
    End If
    c2fb_temp_12 = CPtr(c2fb_source_record_367 Ptr Ptr, @((*arg3)))
    c2fb_temp_13 = CPtr(c2fb_source_record_367 Ptr, @(local0->base))
    (*c2fb_temp_12) = c2fb_temp_13
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function unicodeClose CDecl Alias "unicodeClose" (ByVal arg0 As c2fb_source_record_367 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_unicode.c
    Dim local0 As c2fb_source_record_380 Ptr

    local0 = CPtr(c2fb_source_record_380 Ptr, arg0)
    sqlite3_free(CPtr(Any Ptr, local0->zToken))
    sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function unicodeNext CDecl Alias "unicodeNext" (ByVal arg0 As c2fb_source_record_367 Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_unicode.c
    Dim local0 As c2fb_source_record_380 Ptr
    Dim local1 As c2fb_source_record_379 Ptr
    Dim local2 As c2fb_c_uint
    Dim local3 As ZString Ptr
    Dim local4 As Const UByte Ptr
    Dim local5 As Const UByte Ptr
    Dim local6 As Const UByte Ptr
    Dim local7 As Const UByte Ptr
    Dim c2fb_temp_0 As Const UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim c2fb_temp_8 As Const UByte Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As ZString Ptr
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As ZString Ptr Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Const UByte Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As Byte Ptr
    Dim c2fb_temp_19 As Byte
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As Byte Ptr
    Dim c2fb_temp_22 As Byte
    Dim c2fb_temp_23 As ZString Ptr
    Dim c2fb_temp_24 As Byte Ptr
    Dim c2fb_temp_25 As Byte
    Dim c2fb_temp_26 As ZString Ptr
    Dim c2fb_temp_27 As Byte Ptr
    Dim c2fb_temp_28 As Byte
    Dim c2fb_temp_29 As ZString Ptr
    Dim c2fb_temp_30 As Byte Ptr
    Dim c2fb_temp_31 As Byte
    Dim c2fb_temp_32 As ZString Ptr
    Dim c2fb_temp_33 As Byte Ptr
    Dim c2fb_temp_34 As Byte
    Dim c2fb_temp_35 As ZString Ptr
    Dim c2fb_temp_36 As Byte Ptr
    Dim c2fb_temp_37 As Byte
    Dim c2fb_temp_38 As ZString Ptr
    Dim c2fb_temp_39 As Byte Ptr
    Dim c2fb_temp_40 As Byte
    Dim c2fb_temp_41 As ZString Ptr
    Dim c2fb_temp_42 As Byte Ptr
    Dim c2fb_temp_43 As Byte
    Dim c2fb_temp_44 As ZString Ptr
    Dim c2fb_temp_45 As Byte Ptr
    Dim c2fb_temp_46 As Byte
    Dim c2fb_temp_47 As Const UByte Ptr
    Dim c2fb_temp_48 As c2fb_c_uint
    Dim c2fb_temp_49 As c2fb_c_uint
    Dim c2fb_temp_50 As Const UByte Ptr
    Dim c2fb_temp_51 As c2fb_c_int
    Dim c2fb_temp_52 As c2fb_c_uint
    Dim c2fb_temp_53 As c2fb_c_uint
    Dim c2fb_temp_54 As c2fb_c_uint
    Dim c2fb_temp_55 As c2fb_c_int Ptr
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As Const ZString Ptr Ptr
    Dim c2fb_temp_58 As Const ZString Ptr
    Dim c2fb_temp_59 As c2fb_c_int Ptr
    Dim c2fb_temp_60 As c2fb_c_int
    Dim c2fb_temp_61 As c2fb_c_int Ptr
    Dim c2fb_temp_62 As c2fb_c_int
    Dim c2fb_temp_63 As c2fb_c_int Ptr
    Dim c2fb_temp_64 As c2fb_c_int
    Dim c2fb_temp_65 As c2fb_c_int Ptr
    Dim c2fb_temp_66 As c2fb_c_int
    Dim c2fb_temp_67 As c2fb_c_int Ptr
    Dim c2fb_temp_68 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_380 Ptr, arg0)
    local1 = (CPtr(c2fb_source_record_379 Ptr, local0->base.pTokenizer))
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local4 = CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->aInput[local0->iOff])))
    local5 = local4
    ' C automatic storage declaration
    local7 = CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->aInput[local0->nInput])))
    While (-Cast(c2fb_c_int, ((local4 < local7))))
        c2fb_temp_0 = local4
        local4 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = Cast(c2fb_c_uint, (*(c2fb_temp_0)))
        local2 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
            c2fb_temp_2 = Cast(c2fb_c_uint, c2fb_global_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local2 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
            local2 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 <> local7)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local4)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                c2fb_temp_5 = (Cast(c2fb_c_uint, (local2 Shl Cast(c2fb_c_int, 6ULL))))
                c2fb_temp_4 = Cast(c2fb_c_int, &H3fULL)
                c2fb_temp_3 = local4
                local4 = (c2fb_temp_3 + 1)
                c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_5 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_4 And Cast(c2fb_c_int, (*(c2fb_temp_3))))))))))
                local2 = c2fb_temp_6
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                c2fb_temp_7 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                local2 = c2fb_temp_7
            End If
        End If
        ' empty C statement
        If unicodeIsAlnum(local1, Cast(c2fb_c_int, local2)) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_8 = local4
        local5 = c2fb_temp_8
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local5 >= local7)))) Then
        Return Cast(c2fb_c_int, 101ULL)
    End If
    c2fb_temp_9 = local0->zToken
    local3 = c2fb_temp_9
    Do
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local3)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local0->zToken))))) >= Cast(c2fb_int64, (Cast(c2fb_c_int, (local0->nAlloc - Cast(c2fb_c_int, 4ULL))))))))) Then
            local9 = CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local0->zToken), Cast(c2fb_c_int, (local0->nAlloc + Cast(c2fb_c_int, 64ULL)))))
            If (-Cast(c2fb_c_int, (local9 = 0))) Then
                Return Cast(c2fb_c_int, 7ULL)
            End If
            c2fb_temp_10 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local9)[(CPtr(Byte Ptr, CPtr(Byte Ptr, local3)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local0->zToken)))])))
            local3 = c2fb_temp_10
            c2fb_temp_11 = CPtr(ZString Ptr Ptr, @(local0->zToken))
            c2fb_temp_12 = local9
            (*c2fb_temp_11) = c2fb_temp_12
            c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @(local0->nAlloc))
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_13) + Cast(c2fb_c_int, 64ULL))))
            (*c2fb_temp_13) = c2fb_temp_14
        End If
        c2fb_temp_15 = local4
        local6 = c2fb_temp_15
        c2fb_temp_16 = Cast(c2fb_c_int, sqlite3FtsUnicodeFold(Cast(c2fb_c_int, local2), local1->eRemoveDiacritic))
        local8 = c2fb_temp_16
        If local8 Then
            If (-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_int, &H00080ULL))))) Then
                c2fb_temp_17 = local3
                local3 = (c2fb_temp_17 + 1)
                c2fb_temp_18 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_17))))
                c2fb_temp_19 = Cast(Byte, Cast(UByte, (Cast(c2fb_c_int, (local8 And Cast(c2fb_c_int, &HFFULL))))))
                (*c2fb_temp_18) = c2fb_temp_19
            Else
                If (-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_int, &H00800ULL))))) Then
                    c2fb_temp_20 = local3
                    local3 = (c2fb_temp_20 + 1)
                    c2fb_temp_21 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_20))))
                    c2fb_temp_22 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HC0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local8 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_int, &H1FULL)))))))))
                    (*c2fb_temp_21) = c2fb_temp_22
                    c2fb_temp_23 = local3
                    local3 = (c2fb_temp_23 + 1)
                    c2fb_temp_24 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_23))))
                    c2fb_temp_25 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, (local8 And Cast(c2fb_c_int, &H3FULL)))))))))
                    (*c2fb_temp_24) = c2fb_temp_25
                Else
                    If (-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_int, &H10000ULL))))) Then
                        c2fb_temp_26 = local3
                        local3 = (c2fb_temp_26 + 1)
                        c2fb_temp_27 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_26))))
                        c2fb_temp_28 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HE0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local8 Shr Cast(c2fb_c_int, 12ULL)))) And Cast(c2fb_c_int, &H0FULL)))))))))
                        (*c2fb_temp_27) = c2fb_temp_28
                        c2fb_temp_29 = local3
                        local3 = (c2fb_temp_29 + 1)
                        c2fb_temp_30 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_29))))
                        c2fb_temp_31 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local8 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_int, &H3FULL)))))))))
                        (*c2fb_temp_30) = c2fb_temp_31
                        c2fb_temp_32 = local3
                        local3 = (c2fb_temp_32 + 1)
                        c2fb_temp_33 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_32))))
                        c2fb_temp_34 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, (local8 And Cast(c2fb_c_int, &H3FULL)))))))))
                        (*c2fb_temp_33) = c2fb_temp_34
                    Else
                        c2fb_temp_35 = local3
                        local3 = (c2fb_temp_35 + 1)
                        c2fb_temp_36 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_35))))
                        c2fb_temp_37 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HF0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local8 Shr Cast(c2fb_c_int, 18ULL)))) And Cast(c2fb_c_int, &H07ULL)))))))))
                        (*c2fb_temp_36) = c2fb_temp_37
                        c2fb_temp_38 = local3
                        local3 = (c2fb_temp_38 + 1)
                        c2fb_temp_39 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_38))))
                        c2fb_temp_40 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local8 Shr Cast(c2fb_c_int, 12ULL)))) And Cast(c2fb_c_int, &H3FULL)))))))))
                        (*c2fb_temp_39) = c2fb_temp_40
                        c2fb_temp_41 = local3
                        local3 = (c2fb_temp_41 + 1)
                        c2fb_temp_42 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_41))))
                        c2fb_temp_43 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local8 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_int, &H3FULL)))))))))
                        (*c2fb_temp_42) = c2fb_temp_43
                        c2fb_temp_44 = local3
                        local3 = (c2fb_temp_44 + 1)
                        c2fb_temp_45 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_44))))
                        c2fb_temp_46 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_int, (local8 And Cast(c2fb_c_int, &H3FULL)))))))))
                        (*c2fb_temp_45) = c2fb_temp_46
                    End If
                End If
            End If
            ' empty C statement
        End If
        If (-Cast(c2fb_c_int, ((local4 >= local7)))) Then
            Goto c2fb_flow_4
        End If
        c2fb_temp_47 = local4
        local4 = (c2fb_temp_47 + 1)
        c2fb_temp_48 = Cast(c2fb_c_uint, (*(c2fb_temp_47)))
        local2 = c2fb_temp_48
        If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
            c2fb_temp_49 = Cast(c2fb_c_uint, c2fb_global_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local2 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
            local2 = c2fb_temp_49
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 <> local7)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local4)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                c2fb_temp_52 = (Cast(c2fb_c_uint, (local2 Shl Cast(c2fb_c_int, 6ULL))))
                c2fb_temp_51 = Cast(c2fb_c_int, &H3fULL)
                c2fb_temp_50 = local4
                local4 = (c2fb_temp_50 + 1)
                c2fb_temp_53 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_52 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_51 And Cast(c2fb_c_int, (*(c2fb_temp_50))))))))))
                local2 = c2fb_temp_53
            c2fb_flow_7:
            Wend
            c2fb_flow_6:
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                c2fb_temp_54 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                local2 = c2fb_temp_54
            End If
        End If
        ' empty C statement
    c2fb_flow_5:
    Loop While (-Cast(c2fb_c_int, (((unicodeIsAlnum(local1, Cast(c2fb_c_int, local2)) <> 0) OrElse (sqlite3FtsUnicodeIsdiacritic(Cast(c2fb_c_int, local2)) <> 0)))))
    c2fb_flow_4:
    c2fb_temp_55 = CPtr(c2fb_c_int Ptr, @(local0->iOff))
    c2fb_temp_56 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(UByte Ptr, local4) - CPtr(UByte Ptr, local0->aInput)))))
    (*c2fb_temp_55) = c2fb_temp_56
    c2fb_temp_57 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_58 = CPtr(Const ZString Ptr, local0->zToken)
    (*c2fb_temp_57) = c2fb_temp_58
    c2fb_temp_59 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_60 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, local3)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local0->zToken))))))
    (*c2fb_temp_59) = c2fb_temp_60
    c2fb_temp_61 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_62 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(UByte Ptr, local5) - CPtr(UByte Ptr, local0->aInput)))))
    (*c2fb_temp_61) = c2fb_temp_62
    c2fb_temp_63 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_64 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(UByte Ptr, local6) - CPtr(UByte Ptr, local0->aInput)))))
    (*c2fb_temp_63) = c2fb_temp_64
    c2fb_temp_67 = CPtr(c2fb_c_int Ptr, @((*arg5)))
    c2fb_temp_65 = CPtr(c2fb_c_int Ptr, @(local0->iToken))
    c2fb_temp_66 = (*c2fb_temp_65)
    (*c2fb_temp_65) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_66 + 1)))
    c2fb_temp_68 = Cast(c2fb_c_int, c2fb_temp_66)
    (*c2fb_temp_67) = c2fb_temp_68
    Return Cast(c2fb_c_int, &O0ULL)
End Function
/' ------------------------------------------------------------------------- '/
/' Unicode tokenizer module registration                                     '/
/' ------------------------------------------------------------------------- '/
Private Dim Shared As Const Fts3TokenizerModule unicodeTokenizerModule = _
    Type<Fts3TokenizerModule>( _
        0, _
        Cast(Fts3TokenizerCreateProc, ProcPtr(unicodeCreate)), _
        Cast(Fts3TokenizerDestroyProc, ProcPtr(unicodeDestroy)), _
        Cast(Fts3TokenizerOpenProc, ProcPtr(unicodeOpen)), _
        Cast(Fts3TokenizerCloseProc, ProcPtr(unicodeClose)), _
        Cast(Fts3TokenizerNextProc, ProcPtr(unicodeNext)), _
        Cast(Fts3TokenizerLanguageidProc, 0) _
    )

Sub sqlite3Fts3UnicodeTokenizer CDecl Alias "sqlite3Fts3UnicodeTokenizer" ( _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr _
)
    If CPtr(Any Ptr, ppModule) <> 0 Then *ppModule = @unicodeTokenizerModule
End Sub
#endif

/' end of sqlite3_bulk_fts3_unicode.bas '/
