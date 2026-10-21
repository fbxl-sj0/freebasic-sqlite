/'
** 2012-05-25
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

    File: sqlite3_bulk_fts5_unicode2.bas

    Purpose:

        Provide the generated Unicode classification, case-folding, and
        diacritic mapping routines used by FTS5 tokenizers.

    Responsibilities:

        - Classify Unicode codepoints using SQLite's generated tables.
        - Fold case and optionally remove diacritics.
        - Build the ASCII token-character map from configured categories.

    This file intentionally does NOT contain:

        - Tokenizer state or token iteration logic.
        - Unicode database generation tools.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"
#include once "sqlite3_types.bi"
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_unicode2_types.bi"

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


Declare Function sqlite3Fts5UnicodeIsdiacritic CDecl Alias "sqlite3Fts5UnicodeIsdiacritic" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5UnicodeCatParse CDecl Alias "sqlite3Fts5UnicodeCatParse" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As UByte Ptr) As c2fb_c_int
Declare Function sqlite3Fts5UnicodeCategory CDecl Alias "sqlite3Fts5UnicodeCategory" (ByVal arg0 As c2fb_c_uint) As c2fb_c_int
Declare Sub sqlite3Fts5UnicodeAscii CDecl Alias "sqlite3Fts5UnicodeAscii" (ByVal arg0 As UByte Ptr, ByVal arg1 As UByte Ptr)
#ifdef SQLITE_DEBUG
Private Sub fts5Unicode2Assert(ByVal bCondition As c2fb_c_int, ByVal zExpression As Const ZString Ptr)
    If bCondition = 0 Then sqlite3DebugAssert(zExpression)
End Sub
#endif

Private Function fts5_remove_diacritic(ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int) As c2fb_c_int
    Dim key As c2fb_c_uint
    Dim iRes As c2fb_c_int
    Dim iHi As c2fb_c_int
    Dim iLo As c2fb_c_int
    Dim iTest As c2fb_c_int

    key = (Cast(c2fb_c_uint, arg0) Shl 3) Or Cast(c2fb_c_uint, 7)
    iRes = 0
    iHi = UBound(c2fb_aFts5RemoveDia)
    iLo = 0

    While iHi >= iLo
        iTest = (iHi + iLo) \ 2
        If key >= c2fb_aFts5RemoveDia(iTest) Then
            iRes = iTest
            iLo = iTest + 1
        Else
            iHi = iTest - 1
        End If
    Wend

#ifdef SQLITE_DEBUG
    fts5Unicode2Assert(key >= c2fb_aFts5RemoveDia(iRes), _
        StrPtr(!"key>=aDia[iRes]"))
#endif
    If arg1 = 0 AndAlso (c2fb_aFts5RemoveChar(iRes) And &H80) <> 0 Then _
        Return arg0

    If arg0 > ((c2fb_aFts5RemoveDia(iRes) Shr 3) + _
        (c2fb_aFts5RemoveDia(iRes) And 7)) Then Return arg0

    Return Cast(c2fb_c_int, c2fb_aFts5RemoveChar(iRes) And &H7F)
End Function

Function sqlite3Fts5UnicodeIsdiacritic CDecl Alias "sqlite3Fts5UnicodeIsdiacritic" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_unicode2.c
' c2fb source-line: 98
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_c_uint

    local0 = Cast(c2fb_c_int, &H08029FDFULL)
    local1 = Cast(c2fb_c_int, &H000361F8ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 < Cast(c2fb_c_int, 768ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0 > Cast(c2fb_c_int, 817ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    Return IIf(((-Cast(c2fb_c_int, ((arg0 < Cast(c2fb_c_int, (Cast(c2fb_c_int, 768ULL) + Cast(c2fb_c_int, 32ULL)))))))), (Cast(c2fb_c_uint, (local0 And (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)) Shl (Cast(c2fb_c_int, (arg0 - Cast(c2fb_c_int, 768ULL)))))))))), (Cast(c2fb_c_uint, (local1 And (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0 - Cast(c2fb_c_int, 768ULL))) - Cast(c2fb_c_int, 32ULL)))))))))))
End Function

Function sqlite3Fts5UnicodeFold CDecl Alias "sqlite3Fts5UnicodeFold" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int) As c2fb_c_int
    Dim ret As c2fb_c_int
    Dim iHi As c2fb_c_int
    Dim iLo As c2fb_c_int
    Dim iRes As c2fb_c_int
    Dim iTest As c2fb_c_int
    Dim cmp As c2fb_c_int

#ifdef SQLITE_DEBUG
    fts5Unicode2Assert(SizeOf(UShort) = 2 AndAlso SizeOf(UByte) = 1, _
        StrPtr(!"sizeof(unsigned short)==2 && sizeof(unsigned char)==1"))
#endif
    ret = arg0

    If arg0 < 128 Then
        If arg0 >= Asc("A") AndAlso arg0 <= Asc("Z") Then _
            ret = arg0 + (Asc("a") - Asc("A"))
    ElseIf arg0 < 65536 Then
#ifdef SQLITE_DEBUG
        fts5Unicode2Assert(arg0 > c2fb_aFts5UnicodeFoldEntry(0).iCode, _
            StrPtr(!"c>aEntry[0].iCode"))
#endif
        iHi = UBound(c2fb_aFts5UnicodeFoldEntry)
        iLo = 0
        iRes = -1

        While iHi >= iLo
            iTest = (iHi + iLo) \ 2
            cmp = arg0 - c2fb_aFts5UnicodeFoldEntry(iTest).iCode
            If cmp >= 0 Then
                iRes = iTest
                iLo = iTest + 1
            Else
                iHi = iTest - 1
            End If
        Wend

#ifdef SQLITE_DEBUG
        fts5Unicode2Assert(iRes >= 0 AndAlso _
            arg0 >= c2fb_aFts5UnicodeFoldEntry(iRes).iCode, _
            StrPtr(!"iRes>=0 && c>=aEntry[iRes].iCode"))
#endif
        If arg0 < (c2fb_aFts5UnicodeFoldEntry(iRes).iCode + _
            c2fb_aFts5UnicodeFoldEntry(iRes).nRange) AndAlso _
            ((1 And c2fb_aFts5UnicodeFoldEntry(iRes).flags And _
            (c2fb_aFts5UnicodeFoldEntry(iRes).iCode Xor arg0)) = 0) Then
            ret = (arg0 + c2fb_aFts5UnicodeFoldOffset(_
                c2fb_aFts5UnicodeFoldEntry(iRes).flags Shr 1)) And &HFFFF
#ifdef SQLITE_DEBUG
            fts5Unicode2Assert(ret > 0, StrPtr(!"ret>0"))
#endif
        End If

        If arg1 <> 0 Then
            ret = fts5_remove_diacritic(ret, Cast(c2fb_c_int, arg1 = 2))
        End If
    ElseIf arg0 >= 66560 AndAlso arg0 < 66600 Then
        ret = arg0 + 40
    End If

    Return ret
End Function

Function sqlite3Fts5UnicodeCatParse CDecl Alias "sqlite3Fts5UnicodeCatParse" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As UByte Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_unicode2.c
' c2fb source-line: 253
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As UByte
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As UByte
    Dim c2fb_temp_12 As UByte Ptr
    Dim c2fb_temp_13 As UByte
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As UByte
    Dim c2fb_temp_16 As UByte Ptr
    Dim c2fb_temp_17 As UByte
    Dim c2fb_temp_18 As UByte Ptr
    Dim c2fb_temp_19 As UByte
    Dim c2fb_temp_20 As UByte Ptr
    Dim c2fb_temp_21 As UByte
    Dim c2fb_temp_22 As UByte Ptr
    Dim c2fb_temp_23 As UByte
    Dim c2fb_temp_24 As UByte Ptr
    Dim c2fb_temp_25 As UByte
    Dim c2fb_temp_26 As UByte Ptr
    Dim c2fb_temp_27 As UByte
    Dim c2fb_temp_28 As UByte Ptr
    Dim c2fb_temp_29 As UByte
    Dim c2fb_temp_30 As UByte Ptr
    Dim c2fb_temp_31 As UByte
    Dim c2fb_temp_32 As UByte Ptr
    Dim c2fb_temp_33 As UByte
    Dim c2fb_temp_34 As UByte Ptr
    Dim c2fb_temp_35 As UByte
    Dim c2fb_temp_36 As UByte Ptr
    Dim c2fb_temp_37 As UByte
    Dim c2fb_temp_38 As UByte Ptr
    Dim c2fb_temp_39 As UByte
    Dim c2fb_temp_40 As UByte Ptr
    Dim c2fb_temp_41 As UByte
    Dim c2fb_temp_42 As UByte Ptr
    Dim c2fb_temp_43 As UByte
    Dim c2fb_temp_44 As UByte Ptr
    Dim c2fb_temp_45 As UByte
    Dim c2fb_temp_46 As UByte Ptr
    Dim c2fb_temp_47 As UByte
    Dim c2fb_temp_48 As UByte Ptr
    Dim c2fb_temp_49 As UByte
    Dim c2fb_temp_50 As UByte Ptr
    Dim c2fb_temp_51 As UByte
    Dim c2fb_temp_52 As UByte Ptr
    Dim c2fb_temp_53 As UByte
    Dim c2fb_temp_54 As UByte Ptr
    Dim c2fb_temp_55 As UByte
    Dim c2fb_temp_56 As UByte Ptr
    Dim c2fb_temp_57 As UByte
    Dim c2fb_temp_58 As UByte Ptr
    Dim c2fb_temp_59 As UByte
    Dim c2fb_temp_60 As UByte Ptr
    Dim c2fb_temp_61 As UByte
    Dim c2fb_temp_62 As UByte Ptr
    Dim c2fb_temp_63 As UByte
    Dim c2fb_temp_64 As UByte Ptr
    Dim c2fb_temp_65 As UByte
    Dim c2fb_temp_66 As UByte Ptr
    Dim c2fb_temp_67 As UByte
    Dim c2fb_temp_68 As UByte Ptr
    Dim c2fb_temp_69 As UByte
    Dim c2fb_temp_70 As UByte Ptr
    Dim c2fb_temp_71 As UByte
    Dim c2fb_temp_72 As UByte Ptr
    Dim c2fb_temp_73 As UByte
    Dim c2fb_temp_74 As UByte Ptr
    Dim c2fb_temp_75 As UByte
    Dim c2fb_temp_76 As UByte Ptr
    Dim c2fb_temp_77 As UByte
    Dim c2fb_temp_78 As UByte Ptr
    Dim c2fb_temp_79 As UByte
    Dim c2fb_temp_80 As UByte Ptr
    Dim c2fb_temp_81 As UByte
    Dim c2fb_temp_82 As UByte Ptr
    Dim c2fb_temp_83 As UByte
    Dim c2fb_temp_84 As UByte Ptr
    Dim c2fb_temp_85 As UByte
    Dim c2fb_temp_86 As UByte Ptr
    Dim c2fb_temp_87 As UByte
    Dim c2fb_temp_88 As UByte Ptr
    Dim c2fb_temp_89 As UByte
    Dim c2fb_temp_90 As UByte Ptr
    Dim c2fb_temp_91 As UByte
    Dim c2fb_temp_92 As UByte Ptr
    Dim c2fb_temp_93 As UByte
    Dim c2fb_temp_94 As UByte Ptr
    Dim c2fb_temp_95 As UByte
    Dim c2fb_temp_96 As UByte Ptr
    Dim c2fb_temp_97 As UByte
    Dim c2fb_temp_98 As UByte Ptr
    Dim c2fb_temp_99 As UByte
    Dim c2fb_temp_100 As UByte Ptr
    Dim c2fb_temp_101 As UByte
    Dim c2fb_temp_102 As UByte Ptr
    Dim c2fb_temp_103 As UByte
    Dim c2fb_temp_104 As UByte Ptr
    Dim c2fb_temp_105 As UByte
    Dim c2fb_temp_106 As UByte Ptr
    Dim c2fb_temp_107 As UByte
    Dim c2fb_temp_108 As UByte Ptr
    Dim c2fb_temp_109 As UByte
    Dim c2fb_temp_110 As UByte Ptr
    Dim c2fb_temp_111 As UByte
    Dim c2fb_temp_112 As UByte Ptr
    Dim c2fb_temp_113 As UByte
    Dim c2fb_temp_114 As UByte Ptr
    Dim c2fb_temp_115 As UByte
    Dim c2fb_temp_116 As UByte Ptr
    Dim c2fb_temp_117 As UByte
    Dim c2fb_temp_118 As UByte Ptr
    Dim c2fb_temp_119 As UByte
    Dim c2fb_temp_120 As UByte Ptr
    Dim c2fb_temp_121 As UByte
    Dim c2fb_temp_122 As UByte Ptr
    Dim c2fb_temp_123 As UByte
    Dim c2fb_temp_124 As UByte Ptr
    Dim c2fb_temp_125 As UByte

    c2fb_temp_0 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    Select Case CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, &O0ULL)]
        Case Cast(c2fb_c_int, 67)
            Select Case CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]
                Case Cast(c2fb_c_int, 99)
                    c2fb_temp_2 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 1ULL)]))
                    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_2) = c2fb_temp_3
                Case Cast(c2fb_c_int, 102)
                    c2fb_temp_4 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 2ULL)]))
                    c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_4) = c2fb_temp_5
                Case Cast(c2fb_c_int, 110)
                    c2fb_temp_6 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 3ULL)]))
                    c2fb_temp_7 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_6) = c2fb_temp_7
                Case Cast(c2fb_c_int, 115)
                    c2fb_temp_8 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 4ULL)]))
                    c2fb_temp_9 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_8) = c2fb_temp_9
                Case Cast(c2fb_c_int, 111)
                    c2fb_temp_10 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 31ULL)]))
                    c2fb_temp_11 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_10) = c2fb_temp_11
                Case Cast(c2fb_c_int, 42)
                    c2fb_temp_12 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 1ULL)]))
                    c2fb_temp_13 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_12) = c2fb_temp_13
                    c2fb_temp_14 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 2ULL)]))
                    c2fb_temp_15 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_14) = c2fb_temp_15
                    c2fb_temp_16 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 3ULL)]))
                    c2fb_temp_17 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_16) = c2fb_temp_17
                    c2fb_temp_18 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 4ULL)]))
                    c2fb_temp_19 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_18) = c2fb_temp_19
                    c2fb_temp_20 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 31ULL)]))
                    c2fb_temp_21 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_20) = c2fb_temp_21
                Case Else
                    Return Cast(c2fb_c_int, 1ULL)
            End Select
            c2fb_flow_1:
        Case Cast(c2fb_c_int, 76)
            Select Case CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]
                Case Cast(c2fb_c_int, 108)
                    c2fb_temp_22 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 5ULL)]))
                    c2fb_temp_23 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_22) = c2fb_temp_23
                Case Cast(c2fb_c_int, 109)
                    c2fb_temp_24 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 6ULL)]))
                    c2fb_temp_25 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_24) = c2fb_temp_25
                Case Cast(c2fb_c_int, 111)
                    c2fb_temp_26 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 7ULL)]))
                    c2fb_temp_27 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_26) = c2fb_temp_27
                Case Cast(c2fb_c_int, 116)
                    c2fb_temp_28 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 8ULL)]))
                    c2fb_temp_29 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_28) = c2fb_temp_29
                Case Cast(c2fb_c_int, 117)
                    c2fb_temp_30 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 9ULL)]))
                    c2fb_temp_31 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_30) = c2fb_temp_31
                Case Cast(c2fb_c_int, 67)
                    c2fb_temp_32 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 30ULL)]))
                    c2fb_temp_33 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_32) = c2fb_temp_33
                Case Cast(c2fb_c_int, 42)
                    c2fb_temp_34 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 5ULL)]))
                    c2fb_temp_35 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_34) = c2fb_temp_35
                    c2fb_temp_36 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 6ULL)]))
                    c2fb_temp_37 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_36) = c2fb_temp_37
                    c2fb_temp_38 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 7ULL)]))
                    c2fb_temp_39 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_38) = c2fb_temp_39
                    c2fb_temp_40 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 8ULL)]))
                    c2fb_temp_41 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_40) = c2fb_temp_41
                    c2fb_temp_42 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 9ULL)]))
                    c2fb_temp_43 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_42) = c2fb_temp_43
                    c2fb_temp_44 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 30ULL)]))
                    c2fb_temp_45 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_44) = c2fb_temp_45
                Case Else
                    Return Cast(c2fb_c_int, 1ULL)
            End Select
            c2fb_flow_2:
        Case Cast(c2fb_c_int, 77)
            Select Case CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]
                Case Cast(c2fb_c_int, 99)
                    c2fb_temp_46 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 10ULL)]))
                    c2fb_temp_47 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_46) = c2fb_temp_47
                Case Cast(c2fb_c_int, 101)
                    c2fb_temp_48 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 11ULL)]))
                    c2fb_temp_49 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_48) = c2fb_temp_49
                Case Cast(c2fb_c_int, 110)
                    c2fb_temp_50 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 12ULL)]))
                    c2fb_temp_51 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_50) = c2fb_temp_51
                Case Cast(c2fb_c_int, 42)
                    c2fb_temp_52 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 10ULL)]))
                    c2fb_temp_53 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_52) = c2fb_temp_53
                    c2fb_temp_54 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 11ULL)]))
                    c2fb_temp_55 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_54) = c2fb_temp_55
                    c2fb_temp_56 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 12ULL)]))
                    c2fb_temp_57 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_56) = c2fb_temp_57
                Case Else
                    Return Cast(c2fb_c_int, 1ULL)
            End Select
            c2fb_flow_3:
        Case Cast(c2fb_c_int, 78)
            Select Case CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]
                Case Cast(c2fb_c_int, 100)
                    c2fb_temp_58 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 13ULL)]))
                    c2fb_temp_59 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_58) = c2fb_temp_59
                Case Cast(c2fb_c_int, 108)
                    c2fb_temp_60 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 14ULL)]))
                    c2fb_temp_61 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_60) = c2fb_temp_61
                Case Cast(c2fb_c_int, 111)
                    c2fb_temp_62 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 15ULL)]))
                    c2fb_temp_63 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_62) = c2fb_temp_63
                Case Cast(c2fb_c_int, 42)
                    c2fb_temp_64 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 13ULL)]))
                    c2fb_temp_65 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_64) = c2fb_temp_65
                    c2fb_temp_66 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 14ULL)]))
                    c2fb_temp_67 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_66) = c2fb_temp_67
                    c2fb_temp_68 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 15ULL)]))
                    c2fb_temp_69 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_68) = c2fb_temp_69
                Case Else
                    Return Cast(c2fb_c_int, 1ULL)
            End Select
            c2fb_flow_4:
        Case Cast(c2fb_c_int, 80)
            Select Case CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]
                Case Cast(c2fb_c_int, 99)
                    c2fb_temp_70 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 16ULL)]))
                    c2fb_temp_71 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_70) = c2fb_temp_71
                Case Cast(c2fb_c_int, 100)
                    c2fb_temp_72 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 17ULL)]))
                    c2fb_temp_73 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_72) = c2fb_temp_73
                Case Cast(c2fb_c_int, 101)
                    c2fb_temp_74 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 18ULL)]))
                    c2fb_temp_75 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_74) = c2fb_temp_75
                Case Cast(c2fb_c_int, 102)
                    c2fb_temp_76 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 19ULL)]))
                    c2fb_temp_77 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_76) = c2fb_temp_77
                Case Cast(c2fb_c_int, 105)
                    c2fb_temp_78 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 20ULL)]))
                    c2fb_temp_79 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_78) = c2fb_temp_79
                Case Cast(c2fb_c_int, 111)
                    c2fb_temp_80 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 21ULL)]))
                    c2fb_temp_81 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_80) = c2fb_temp_81
                Case Cast(c2fb_c_int, 115)
                    c2fb_temp_82 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 22ULL)]))
                    c2fb_temp_83 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_82) = c2fb_temp_83
                Case Cast(c2fb_c_int, 42)
                    c2fb_temp_84 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 16ULL)]))
                    c2fb_temp_85 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_84) = c2fb_temp_85
                    c2fb_temp_86 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 17ULL)]))
                    c2fb_temp_87 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_86) = c2fb_temp_87
                    c2fb_temp_88 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 18ULL)]))
                    c2fb_temp_89 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_88) = c2fb_temp_89
                    c2fb_temp_90 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 19ULL)]))
                    c2fb_temp_91 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_90) = c2fb_temp_91
                    c2fb_temp_92 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 20ULL)]))
                    c2fb_temp_93 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_92) = c2fb_temp_93
                    c2fb_temp_94 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 21ULL)]))
                    c2fb_temp_95 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_94) = c2fb_temp_95
                    c2fb_temp_96 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 22ULL)]))
                    c2fb_temp_97 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_96) = c2fb_temp_97
                Case Else
                    Return Cast(c2fb_c_int, 1ULL)
            End Select
            c2fb_flow_5:
        Case Cast(c2fb_c_int, 83)
            Select Case CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]
                Case Cast(c2fb_c_int, 99)
                    c2fb_temp_98 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 23ULL)]))
                    c2fb_temp_99 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_98) = c2fb_temp_99
                Case Cast(c2fb_c_int, 107)
                    c2fb_temp_100 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 24ULL)]))
                    c2fb_temp_101 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_100) = c2fb_temp_101
                Case Cast(c2fb_c_int, 109)
                    c2fb_temp_102 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 25ULL)]))
                    c2fb_temp_103 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_102) = c2fb_temp_103
                Case Cast(c2fb_c_int, 111)
                    c2fb_temp_104 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 26ULL)]))
                    c2fb_temp_105 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_104) = c2fb_temp_105
                Case Cast(c2fb_c_int, 42)
                    c2fb_temp_106 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 23ULL)]))
                    c2fb_temp_107 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_106) = c2fb_temp_107
                    c2fb_temp_108 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 24ULL)]))
                    c2fb_temp_109 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_108) = c2fb_temp_109
                    c2fb_temp_110 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 25ULL)]))
                    c2fb_temp_111 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_110) = c2fb_temp_111
                    c2fb_temp_112 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 26ULL)]))
                    c2fb_temp_113 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_112) = c2fb_temp_113
                Case Else
                    Return Cast(c2fb_c_int, 1ULL)
            End Select
            c2fb_flow_6:
        Case Cast(c2fb_c_int, 90)
            Select Case CPtr(Const Byte Ptr, arg0)[Cast(c2fb_c_int, 1ULL)]
                Case Cast(c2fb_c_int, 108)
                    c2fb_temp_114 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 27ULL)]))
                    c2fb_temp_115 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_114) = c2fb_temp_115
                Case Cast(c2fb_c_int, 112)
                    c2fb_temp_116 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 28ULL)]))
                    c2fb_temp_117 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_116) = c2fb_temp_117
                Case Cast(c2fb_c_int, 115)
                    c2fb_temp_118 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 29ULL)]))
                    c2fb_temp_119 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_118) = c2fb_temp_119
                Case Cast(c2fb_c_int, 42)
                    c2fb_temp_120 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 27ULL)]))
                    c2fb_temp_121 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_120) = c2fb_temp_121
                    c2fb_temp_122 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 28ULL)]))
                    c2fb_temp_123 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_122) = c2fb_temp_123
                    c2fb_temp_124 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, 29ULL)]))
                    c2fb_temp_125 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_124) = c2fb_temp_125
                Case Else
                    Return Cast(c2fb_c_int, 1ULL)
            End Select
            c2fb_flow_7:
        Case Else
            Return Cast(c2fb_c_int, 1ULL)
    End Select
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts5UnicodeCategory CDecl Alias "sqlite3Fts5UnicodeCategory" (ByVal arg0 As c2fb_c_uint) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_unicode2.c
' c2fb source-line: 737
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As UShort
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UShort
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg0 >= Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 20ULL))))))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_aFts5UnicodeBlock((Cast(c2fb_c_uint, (arg0 Shr Cast(c2fb_c_int, 16ULL))))))
    local2 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, c2fb_aFts5UnicodeBlock(Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)) + (Cast(c2fb_c_uint, (arg0 Shr Cast(c2fb_c_int, 16ULL))))))))
    local1 = c2fb_temp_1
    c2fb_temp_2 = Cast(UShort, (Cast(c2fb_c_uint, (arg0 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFFULL))))))
    local4 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local1 > local2))))
        local5 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local1 + local2))) \ Cast(c2fb_c_int, 2ULL)))
#ifdef SQLITE_DEBUG
        fts5Unicode2Assert(local5 >= local2 AndAlso local5 < local1, _
            StrPtr(!"iTest>=iLo && iTest<iHi"))
#endif
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4) >= Cast(c2fb_c_int, c2fb_aFts5UnicodeMap(local5)))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, local5)
            local0 = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))))
            local2 = c2fb_temp_4
        Else
            c2fb_temp_5 = Cast(c2fb_c_int, local5)
            local1 = c2fb_temp_5
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4) >= (Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_aFts5UnicodeMap(local0)) + (Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_aFts5UnicodeData(local0)) Shr Cast(c2fb_c_int, 5ULL))))))))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_aFts5UnicodeData(local0)) And Cast(c2fb_c_int, &H1FULL))))
    local3 = c2fb_temp_6
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 30ULL))))) Then
        Return local3
    End If
    Return IIf((Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, local4) - Cast(c2fb_c_int, c2fb_aFts5UnicodeMap(local0))))) And Cast(c2fb_c_int, &H01ULL)))), Cast(c2fb_c_int, 5ULL), Cast(c2fb_c_int, 9ULL))
End Function
Sub sqlite3Fts5UnicodeAscii CDecl Alias "sqlite3Fts5UnicodeAscii" (ByVal arg0 As UByte Ptr, ByVal arg1 As UByte Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_unicode2.c
' c2fb source-line: 768
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As UByte
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, 128ULL)))))
        local2 = arg0[Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_aFts5UnicodeData(local1)) And Cast(c2fb_c_int, &H1FULL)))]
        local3 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_aFts5UnicodeData(local1)) Shr Cast(c2fb_c_int, 5ULL)))) + local0))
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, 128ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < local3)))) <> 0)))))
            c2fb_temp_1 = CPtr(UByte Ptr, @(arg1[local0]))
            c2fb_temp_2 = Cast(UByte, Cast(UByte, local2))
            (*c2fb_temp_1) = c2fb_temp_2
        c2fb_flow_3:
            c2fb_temp_0 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_temp_3 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(UByte Ptr, @(arg1[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_4) = c2fb_temp_5
End Sub
' c2fb body rename mappings:
' c2fb rename matched: aFts5UnicodeBlock -> c2fb_aFts5UnicodeBlock
' c2fb rename matched: aFts5UnicodeData -> c2fb_aFts5UnicodeData
' c2fb rename matched: aFts5UnicodeMap -> c2fb_aFts5UnicodeMap
#endif
/' end of sqlite3_bulk_fts5_unicode2.bas '/
