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

    File: sqlite3_bulk_fts5_tokenize.bas

    Purpose:

        Port FTS5's built-in tokenizers and tokenizer helper routines.

    Responsibilities:

        - Tokenize ASCII, Unicode61, Porter, and trigram input.
        - Parse tokenizer options and apply tokenizer-specific rules.
        - Register the built-in FTS5 tokenizers with an FTS5 API handle.

    This file intentionally does NOT contain:

        - Unicode classification data tables from fts5_unicode2.c.
        - FTS5 virtual-table registration or the upstream test adapter.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_tokenize_types.bi"
#include once "sqlite3_api_declarations.bi"

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


Type c2fb_callback_136 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_154 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
Type c2fb_callback_155 As Sub CDecl(ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
Type c2fb_callback_156 As Function CDecl(ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_callback_136) As c2fb_c_int
Type c2fb_callback_162 As Function CDecl(ByVal arg0 As c2fb_fts5_api Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr Ptr, ByVal arg3 As c2fb_fts5_tokenizer_v2 Ptr Ptr) As c2fb_c_int

Declare Sub fts5AsciiAddExceptions CDecl Alias "fts5AsciiAddExceptions" (ByVal arg0 As c2fb_AsciiTokenizer Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub fts5AsciiDelete CDecl Alias "fts5AsciiDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
Declare Function fts5AsciiCreate CDecl Alias "fts5AsciiCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
Declare Sub asciiFold CDecl Alias "asciiFold" (ByVal arg0 As ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Function fts5AsciiTokenize CDecl Alias "fts5AsciiTokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_136) As c2fb_c_int
Declare Function fts5UnicodeAddExceptions CDecl Alias "fts5UnicodeAddExceptions" (ByVal arg0 As c2fb_Unicode61Tokenizer Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5UnicodeIsException CDecl Alias "fts5UnicodeIsException" (ByVal arg0 As c2fb_Unicode61Tokenizer Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5UnicodeDelete CDecl Alias "fts5UnicodeDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
Declare Function unicodeSetCategories CDecl Alias "unicodeSetCategories" (ByVal arg0 As c2fb_Unicode61Tokenizer Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function fts5UnicodeCreate CDecl Alias "fts5UnicodeCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
Declare Function fts5UnicodeIsAlnum CDecl Alias "fts5UnicodeIsAlnum" (ByVal arg0 As c2fb_Unicode61Tokenizer Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5UnicodeTokenize CDecl Alias "fts5UnicodeTokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_136) As c2fb_c_int
Declare Sub fts5PorterDelete CDecl Alias "fts5PorterDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
Declare Function fts5PorterCreate CDecl Alias "fts5PorterCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
Declare Function fts5PorterIsVowel CDecl Alias "fts5PorterIsVowel" (ByVal arg0 As Byte, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5PorterGobbleVC CDecl Alias "fts5PorterGobbleVC" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5Porter_MGt0 CDecl Alias "fts5Porter_MGt0" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5Porter_MGt1 CDecl Alias "fts5Porter_MGt1" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5Porter_MEq1 CDecl Alias "fts5Porter_MEq1" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5Porter_Ostar CDecl Alias "fts5Porter_Ostar" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5Porter_MGt1_and_S_or_T CDecl Alias "fts5Porter_MGt1_and_S_or_T" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5Porter_Vowel CDecl Alias "fts5Porter_Vowel" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts5PorterStep4 CDecl Alias "fts5PorterStep4" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5PorterStep1B2 CDecl Alias "fts5PorterStep1B2" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5PorterStep2 CDecl Alias "fts5PorterStep2" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5PorterStep3 CDecl Alias "fts5PorterStep3" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function fts5PorterStep1B CDecl Alias "fts5PorterStep1B" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub fts5PorterStep1A CDecl Alias "fts5PorterStep1A" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr)
Declare Function fts5PorterCb CDecl Alias "fts5PorterCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
Declare Function fts5PorterTokenize CDecl Alias "fts5PorterTokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_callback_136) As c2fb_c_int
Declare Sub fts5TriDelete CDecl Alias "fts5TriDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
Declare Function fts5TriCreate CDecl Alias "fts5TriCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
Declare Function fts5TriTokenize CDecl Alias "fts5TriTokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_136) As c2fb_c_int
Declare Function sqlite3Fts5TokenizerPattern CDecl Alias "sqlite3Fts5TokenizerPattern" (ByVal arg0 As c2fb_callback_154, ByVal arg1 As c2fb_Fts5Tokenizer Ptr) As c2fb_c_int
Declare Function sqlite3Fts5TokenizerPreload CDecl Alias "sqlite3Fts5TokenizerPreload" (ByVal arg0 As c2fb_Fts5TokenizerConfig Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memmove CDecl Alias "memmove" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3Fts5UnicodeIsdiacritic CDecl Alias "sqlite3Fts5UnicodeIsdiacritic" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5UnicodeFold CDecl Alias "sqlite3Fts5UnicodeFold" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5UnicodeCatParse CDecl Alias "sqlite3Fts5UnicodeCatParse" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As UByte Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5UnicodeCategory CDecl Alias "sqlite3Fts5UnicodeCategory" (ByVal arg0 As c2fb_c_uint) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5UnicodeAscii CDecl Alias "sqlite3Fts5UnicodeAscii" (ByVal arg0 As UByte Ptr, ByVal arg1 As UByte Ptr)
#ifdef SQLITE_DEBUG
Private Sub fts5TokenizeAssert(ByVal bCondition As c2fb_c_int, ByVal zExpression As Const ZString Ptr)
    If bCondition = 0 Then sqlite3DebugAssert(zExpression)
End Sub
#endif
Private Sub fts5AsciiAddExceptions CDecl Alias "fts5AsciiAddExceptions" (ByVal arg0 As c2fb_AsciiTokenizer Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 41
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While CPtr(Const Byte Ptr, arg1)[local0]
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg1)[local0]) And Cast(c2fb_c_int, &H80ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(UByte Ptr, @(arg0->aTokenChar(Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg1)[local0]))))
            c2fb_temp_3 = Cast(UByte, Cast(UByte, arg2))
            (*c2fb_temp_2) = c2fb_temp_3
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
End Sub
Private Sub fts5AsciiDelete CDecl Alias "fts5AsciiDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 57
    sqlite3_free(CPtr(Any Ptr, arg0))
End Sub
Private Function fts5AsciiCreate CDecl Alias "fts5AsciiCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 64
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_AsciiTokenizer Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_AsciiTokenizer Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_AsciiTokenizer Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Tokenizer Ptr Ptr
    Dim c2fb_temp_10 As c2fb_Fts5Tokenizer Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If Cast(c2fb_c_int, (arg2 Mod Cast(c2fb_c_int, 2ULL))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_AsciiTokenizer Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_AsciiTokenizer)))))
        local1 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_2
        Else
            ' C automatic storage declaration
            c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_AsciiTokenizer))))
            c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, (@local1->aTokenChar(0)))), CPtr(Const Any Ptr, CPtr(UByte Ptr, (@c2fb_aAsciiTokenChar(0)))), Cast(c2fb_size_t, (128ULL * SizeOf(UByte)))))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_5
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < arg2)))) <> 0)))))
                local3 = arg1[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))]
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local2], StrPtr(!"tokenchars")))))) Then
                    fts5AsciiAddExceptions(local1, local3, Cast(c2fb_c_int, 1ULL))
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local2], StrPtr(!"separators")))))) Then
                        fts5AsciiAddExceptions(local1, local3, Cast(c2fb_c_int, &O0ULL))
                    Else
                        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local0 = c2fb_temp_7
                    End If
                End If
            c2fb_flow_1:
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 2ULL))))
                local2 = c2fb_temp_6
            Wend
            c2fb_flow_0:
            If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                fts5AsciiDelete(CPtr(c2fb_Fts5Tokenizer Ptr, local1))
                c2fb_temp_8 = CPtr(_c2fb_record_c2fb_AsciiTokenizer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local1 = c2fb_temp_8
            End If
        End If
    End If
    c2fb_temp_9 = CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @((*arg3)))
    c2fb_temp_10 = CPtr(c2fb_Fts5Tokenizer Ptr, local1)
    (*c2fb_temp_9) = c2fb_temp_10
    Return local0
End Function
Private Sub asciiFold CDecl Alias "asciiFold" (ByVal arg0 As ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 105
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As Byte
    Dim c2fb_temp_2 As Byte
    Dim c2fb_temp_3 As Byte Ptr
    Dim c2fb_temp_4 As Byte

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg2))))
        local1 = CPtr(Const Byte Ptr, arg1)[local0]
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) >= Cast(c2fb_c_int, 65))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) <= Cast(c2fb_c_int, 90))))) <> 0))))) Then
            c2fb_temp_2 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, local1) + Cast(c2fb_c_int, 32ULL))))
            local1 = c2fb_temp_2
        End If
        c2fb_temp_3 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[local0]))
        c2fb_temp_4 = Cast(Byte, local1)
        (*c2fb_temp_3) = c2fb_temp_4
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
End Sub
Private Function fts5AsciiTokenize CDecl Alias "fts5AsciiTokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_136) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 117
    Dim local0 As c2fb_AsciiTokenizer Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4(0 To 63) As Byte
    Dim local5 As c2fb_c_int
    Dim local6 As ZString Ptr
    Dim local7 As UByte Ptr
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = CPtr(c2fb_AsciiTokenizer Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic array storage
    local5 = Cast(c2fb_size_t, (64ULL * SizeOf(Byte)))
    local6 = CPtr(ZString Ptr, CPtr(Byte Ptr, (@local4(0))))
    local7 = CPtr(UByte Ptr, (@local0->aTokenChar(0)))
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < arg4)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C automatic storage declaration
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < arg4)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local3]) And Cast(c2fb_c_int, &H80ULL)))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local7[Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local3])]) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            c2fb_temp_0 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local3 = arg4)))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))
        local2 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < arg4)))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local2]) And Cast(c2fb_c_int, &H80ULL)))) <> 0) OrElse (local7[Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg3)[local2])] <> 0)))))) <> 0)))))
            c2fb_temp_2 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        c2fb_flow_5:
        Wend
        c2fb_flow_4:
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 - local3)))
        local8 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local8 > local5)))) Then
            If (-Cast(c2fb_c_int, ((local6 <> CPtr(Byte Ptr, (@local4(0))))))) Then
                sqlite3_free(CPtr(Any Ptr, local6))
            End If
            c2fb_temp_4 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, local8) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))))
            local6 = c2fb_temp_4
            If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local1 = c2fb_temp_5
                Goto c2fb_flow_0
            End If
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local8 * Cast(c2fb_c_int, 2ULL))))
            local5 = c2fb_temp_6
        End If
        asciiFold(local6, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg3)[local3]))), local8)
        c2fb_temp_7 = Cast(c2fb_c_int, arg5(arg1, Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr, local6), local8, local3, local2))
        local1 = c2fb_temp_7
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))))
        local3 = c2fb_temp_8
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local6 <> CPtr(Byte Ptr, (@local4(0))))))) Then
        sqlite3_free(CPtr(Any Ptr, local6))
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 101ULL))))) Then
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_9
    End If
    Return local1
End Function
Private Function fts5UnicodeAddExceptions CDecl Alias "fts5UnicodeAddExceptions" (ByVal arg0 As c2fb_Unicode61Tokenizer Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 255
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As Const UByte Ptr
    Dim local5 As Const UByte Ptr
    Dim local6 As c2fb_c_uint
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_1 As Const UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As Const UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As UByte Ptr
    Dim c2fb_temp_10 As UByte
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Any Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr Ptr
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As Long Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, c2fb_crt_strlen(arg1))
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->aiException), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local1 + arg0->nException)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))))))
        local2 = c2fb_temp_0
        If local2 Then
            local3 = arg0->nException
            local4 = CPtr(Const UByte Ptr, arg1)
            local5 = CPtr(Const UByte Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg1)[local1])))
            While (-Cast(c2fb_c_int, ((local4 < local5))))
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_1 = local4
                local4 = (c2fb_temp_1 + 1)
                c2fb_temp_2 = Cast(c2fb_c_uint, (*(c2fb_temp_1)))
                local6 = c2fb_temp_2
                If (-Cast(c2fb_c_int, ((local6 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
                    c2fb_temp_3 = Cast(c2fb_c_uint, c2fb_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local6 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
                    local6 = c2fb_temp_3
                    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < local5)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local4)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                        c2fb_temp_6 = (Cast(c2fb_c_uint, (local6 Shl Cast(c2fb_c_int, 6ULL))))
                        c2fb_temp_5 = Cast(c2fb_c_int, &H3fULL)
                        c2fb_temp_4 = local4
                        local4 = (c2fb_temp_4 + 1)
                        c2fb_temp_7 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_6 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_5 And Cast(c2fb_c_int, (*(c2fb_temp_4))))))))))
                        local6 = c2fb_temp_7
                    c2fb_flow_3:
                    Wend
                    c2fb_flow_2:
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local6 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local6 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                        c2fb_temp_8 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                        local6 = c2fb_temp_8
                    End If
                End If
                ' empty C statement
                If (-Cast(c2fb_c_int, ((local6 < Cast(c2fb_c_uint, Cast(c2fb_c_int, 128ULL)))))) Then
                    c2fb_temp_9 = CPtr(UByte Ptr, @(arg0->aTokenChar(local6)))
                    c2fb_temp_10 = Cast(UByte, Cast(UByte, arg2))
                    (*c2fb_temp_9) = c2fb_temp_10
                Else
                    c2fb_temp_11 = Cast(c2fb_c_int, arg0->aCategory(c2fb_external_sqlite3Fts5UnicodeCategory(local6)))
                    local7 = c2fb_temp_11
#ifdef SQLITE_DEBUG
                    fts5TokenizeAssert(local7 = 0 OrElse local7 = 1, _
                        StrPtr(!"(bToken==0 || bToken==1)"))
                    fts5TokenizeAssert(arg2 = 0 OrElse arg2 = 1, _
                        StrPtr(!"(bTokenChars==0 || bTokenChars==1)"))
#endif
                    ' C unused-parameter annotation
                    ' C unused-parameter annotation
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 <> arg2)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3Fts5UnicodeIsdiacritic(local6) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        ' C automatic storage declaration
                        c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        local8 = c2fb_temp_12
                        While (-Cast(c2fb_c_int, ((local8 < local3))))
                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, local2[local8]) > local6)))) Then
                                Goto c2fb_flow_4
                            End If
                        c2fb_flow_5:
                            c2fb_temp_13 = local8
                            local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                        Wend
                        c2fb_flow_4:
                        c2fb_temp_14 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(c2fb_c_int Ptr, @(local2[Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, 1ULL)))]))), CPtr(Const Any Ptr, CPtr(c2fb_c_int Ptr, @(local2[local8]))), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local3 - local8)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int)))))))
                        c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @(local2[local8]))
                        c2fb_temp_16 = Cast(c2fb_c_int, local6)
                        (*c2fb_temp_15) = c2fb_temp_16
                        c2fb_temp_17 = local3
                        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
                    End If
                End If
            c2fb_flow_1:
            Wend
            c2fb_flow_0:
            c2fb_temp_18 = CPtr(Long Ptr Ptr, @(arg0->aiException))
            c2fb_temp_19 = local2
            (*c2fb_temp_18) = CPtr(Long Ptr, c2fb_temp_19)
            c2fb_temp_19 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_18))
            c2fb_temp_20 = CPtr(Long Ptr, @(arg0->nException))
            c2fb_temp_21 = Cast(c2fb_c_int, local3)
            (*c2fb_temp_20) = Cast(Long, c2fb_temp_21)
            c2fb_temp_21 = Cast(c2fb_c_int, (*c2fb_temp_20))
        Else
            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_22
        End If
    End If
    Return local0
End Function
Private Function fts5UnicodeIsException CDecl Alias "fts5UnicodeIsException" (ByVal arg0 As c2fb_Unicode61Tokenizer Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 305
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
Private Sub fts5UnicodeDelete CDecl Alias "fts5UnicodeDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 329
    Dim local0 As c2fb_Unicode61Tokenizer Ptr

    If arg0 Then
        local0 = CPtr(c2fb_Unicode61Tokenizer Ptr, arg0)
        sqlite3_free(CPtr(Any Ptr, local0->aiException))
        sqlite3_free(CPtr(Any Ptr, local0->aFold))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
    Return
End Sub
Private Function unicodeSetCategories CDecl Alias "unicodeSetCategories" (ByVal arg0 As c2fb_Unicode61Tokenizer Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 339
    Dim local0 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr

    local0 = arg1
    While (*CPtr(Const Byte Ptr, local0))
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 32))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) = Cast(c2fb_c_int, 9))))) <> 0)))))
            c2fb_temp_0 = local0
            local0 = (c2fb_temp_0 + 1)
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((((*CPtr(Const Byte Ptr, local0)) <> 0) AndAlso (c2fb_external_sqlite3Fts5UnicodeCatParse(local0, CPtr(UByte Ptr, (@arg0->aCategory(0)))) <> 0))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <> Cast(c2fb_c_int, 32))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <> Cast(c2fb_c_int, 9))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local0))) <> Cast(c2fb_c_int, 0))))) <> 0)))))
            c2fb_temp_1 = local0
            local0 = (c2fb_temp_1 + 1)
        c2fb_flow_5:
        Wend
        c2fb_flow_4:
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3Fts5UnicodeAscii(CPtr(UByte Ptr, (@arg0->aCategory(0))), CPtr(UByte Ptr, (@arg0->aTokenChar(0))))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5UnicodeCreate CDecl Alias "fts5UnicodeCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 357
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Unicode61Tokenizer Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_Unicode61Tokenizer Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Const ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_Unicode61Tokenizer Ptr
    Dim c2fb_temp_24 As c2fb_Fts5Tokenizer Ptr Ptr
    Dim c2fb_temp_25 As c2fb_Fts5Tokenizer Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If Cast(c2fb_c_int, (arg2 Mod Cast(c2fb_c_int, 2ULL))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Unicode61Tokenizer Ptr, CPtr(c2fb_Unicode61Tokenizer Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_Unicode61Tokenizer))))))
        local1 = c2fb_temp_1
        If local1 Then
            local2 = StrPtr(!"L* N* Co")
            ' C automatic storage declaration
            c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Unicode61Tokenizer))))
            c2fb_temp_3 = CPtr(Long Ptr, @(local1->eRemoveDiacritic))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            c2fb_temp_5 = CPtr(Long Ptr, @(local1->nFold))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 64ULL))
            (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
            c2fb_temp_7 = CPtr(ZString Ptr Ptr, @(local1->aFold))
            c2fb_temp_8 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, local1->nFold) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Byte))))))))
            (*c2fb_temp_7) = c2fb_temp_8
            If (-Cast(c2fb_c_int, ((local1->aFold = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_9
            End If
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_10
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 < arg2)))) <> 0)))))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local3], StrPtr(!"categories")))))) Then
                    c2fb_temp_12 = arg1[Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL)))]
                    local2 = c2fb_temp_12
                End If
            c2fb_flow_1:
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 2ULL))))
                local3 = c2fb_temp_11
            Wend
            c2fb_flow_0:
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_13 = Cast(c2fb_c_int, unicodeSetCategories(local1, local2))
                local0 = c2fb_temp_13
            End If
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_14
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 < arg2)))) <> 0)))))
                local4 = arg1[Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL)))]
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local3], StrPtr(!"remove_diacritics")))))) Then
                    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local4)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local4)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 49))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local4)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 50))))) <> 0)))))) <> 0) OrElse (CPtr(Const Byte Ptr, local4)[Cast(c2fb_c_int, 1ULL)] <> 0))))) Then
                        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local0 = c2fb_temp_16
                    Else
                        c2fb_temp_17 = CPtr(Long Ptr, @(local1->eRemoveDiacritic))
                        c2fb_temp_18 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, local4)[Cast(c2fb_c_int, &O0ULL)]) - Cast(c2fb_c_int, 48)))))
                        (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
                        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
#ifdef SQLITE_DEBUG
                        fts5TokenizeAssert(local1->eRemoveDiacritic = 0 OrElse _
                            local1->eRemoveDiacritic = 1 OrElse _
                            local1->eRemoveDiacritic = 2, _
                            StrPtr(!"p->eRemoveDiacritic==FTS5_REMOVE_DIACRITICS_NONE || p->eRemoveDiacritic==FTS5_REMOVE_DIACRITICS_SIMPLE || p->eRemoveDiacritic==FTS5_REMOVE_DIACRITICS_COMPLEX"))
#endif
                        ' C unused-parameter annotation
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local3], StrPtr(!"tokenchars")))))) Then
                        c2fb_temp_19 = Cast(c2fb_c_int, fts5UnicodeAddExceptions(local1, local4, Cast(c2fb_c_int, 1ULL)))
                        local0 = c2fb_temp_19
                    Else
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local3], StrPtr(!"separators")))))) Then
                            c2fb_temp_20 = Cast(c2fb_c_int, fts5UnicodeAddExceptions(local1, local4, Cast(c2fb_c_int, &O0ULL)))
                            local0 = c2fb_temp_20
                        Else
                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local3], StrPtr(!"categories")))))) Then
                                ' empty C block
                            Else
                                c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                local0 = c2fb_temp_21
                            End If
                        End If
                    End If
                End If
            c2fb_flow_3:
                c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 2ULL))))
                local3 = c2fb_temp_15
            Wend
            c2fb_flow_2:
        Else
            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_22
        End If
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            fts5UnicodeDelete(CPtr(c2fb_Fts5Tokenizer Ptr, local1))
            c2fb_temp_23 = CPtr(_c2fb_record_c2fb_Unicode61Tokenizer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_23
        End If
        c2fb_temp_24 = CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @((*arg3)))
        c2fb_temp_25 = CPtr(c2fb_Fts5Tokenizer Ptr, local1)
        (*c2fb_temp_24) = c2fb_temp_25
    End If
    Return local0
End Function
Private Function fts5UnicodeIsAlnum CDecl Alias "fts5UnicodeIsAlnum" (ByVal arg0 As c2fb_Unicode61Tokenizer Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 435
    Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->aCategory(c2fb_external_sqlite3Fts5UnicodeCategory(Cast(c2fb_c_uint, arg1)))) Xor fts5UnicodeIsException(arg0, arg1))))
End Function
Private Function fts5UnicodeTokenize CDecl Alias "fts5UnicodeTokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_136) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 442
    Dim local0 As c2fb_Unicode61Tokenizer Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As UByte Ptr
    Dim local3 As UByte Ptr
    Dim local4 As UByte Ptr
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As Const ZString Ptr
    Dim local8 As c2fb_c_uint
    Dim local9 As ZString Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As Any Ptr
    Dim c2fb_temp_15 As ZString Ptr Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Const ZString Ptr
    Dim c2fb_temp_21 As UByte Ptr
    Dim c2fb_temp_22 As c2fb_c_uint
    Dim c2fb_temp_23 As c2fb_c_uint
    Dim c2fb_temp_24 As UByte Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_uint
    Dim c2fb_temp_27 As c2fb_c_uint
    Dim c2fb_temp_28 As c2fb_c_uint
    Dim c2fb_temp_29 As c2fb_c_uint
    Dim c2fb_temp_30 As ZString Ptr
    Dim c2fb_temp_31 As Byte Ptr
    Dim c2fb_temp_32 As Byte
    Dim c2fb_temp_33 As ZString Ptr
    Dim c2fb_temp_34 As Byte Ptr
    Dim c2fb_temp_35 As Byte
    Dim c2fb_temp_36 As ZString Ptr
    Dim c2fb_temp_37 As Byte Ptr
    Dim c2fb_temp_38 As Byte
    Dim c2fb_temp_39 As ZString Ptr
    Dim c2fb_temp_40 As Byte Ptr
    Dim c2fb_temp_41 As Byte
    Dim c2fb_temp_42 As ZString Ptr
    Dim c2fb_temp_43 As Byte Ptr
    Dim c2fb_temp_44 As Byte
    Dim c2fb_temp_45 As ZString Ptr
    Dim c2fb_temp_46 As Byte Ptr
    Dim c2fb_temp_47 As Byte
    Dim c2fb_temp_48 As ZString Ptr
    Dim c2fb_temp_49 As Byte Ptr
    Dim c2fb_temp_50 As Byte
    Dim c2fb_temp_51 As ZString Ptr
    Dim c2fb_temp_52 As Byte Ptr
    Dim c2fb_temp_53 As Byte
    Dim c2fb_temp_54 As ZString Ptr
    Dim c2fb_temp_55 As Byte Ptr
    Dim c2fb_temp_56 As Byte
    Dim c2fb_temp_57 As ZString Ptr
    Dim c2fb_temp_58 As Byte Ptr
    Dim c2fb_temp_59 As Byte
    Dim c2fb_temp_60 As ZString Ptr
    Dim c2fb_temp_61 As Byte Ptr
    Dim c2fb_temp_62 As Byte
    Dim c2fb_temp_63 As ZString Ptr
    Dim c2fb_temp_64 As Byte Ptr
    Dim c2fb_temp_65 As Byte
    Dim c2fb_temp_66 As UByte Ptr
    Dim c2fb_temp_67 As c2fb_c_int
    Dim c2fb_temp_68 As c2fb_c_int
    Dim c2fb_temp_69 As c2fb_c_int

    local0 = CPtr(c2fb_Unicode61Tokenizer Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = CPtr(UByte Ptr, (@local0->aTokenChar(0)))
    local3 = CPtr(UByte Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg3)[arg4])))
    local4 = CPtr(UByte Ptr, arg3)
    local5 = local0->aFold
    local6 = local0->nFold
    local7 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[Cast(c2fb_c_int, (local6 - Cast(c2fb_c_int, 6ULL)))])))
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL)))))
        ' C automatic storage declaration
        local9 = local5
        ' C automatic storage declaration
        ' C automatic storage declaration
        While Cast(c2fb_c_int, 1ULL)
            If (-Cast(c2fb_c_int, ((local4 >= local3)))) Then
                Goto c2fb_label_0
            End If
            If Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local4)) And Cast(c2fb_c_int, &H80ULL))) Then
                c2fb_temp_0 = Cast(c2fb_c_int, (CPtr(UByte Ptr, local4) - CPtr(UByte Ptr, CPtr(UByte Ptr, arg3))))
                local10 = c2fb_temp_0
                c2fb_temp_1 = local4
                local4 = (c2fb_temp_1 + 1)
                c2fb_temp_2 = Cast(c2fb_c_uint, (*(c2fb_temp_1)))
                local8 = c2fb_temp_2
                If (-Cast(c2fb_c_int, ((local8 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
                    c2fb_temp_3 = Cast(c2fb_c_uint, c2fb_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local8 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
                    local8 = c2fb_temp_3
                    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < local3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local4)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                        c2fb_temp_6 = (Cast(c2fb_c_uint, (local8 Shl Cast(c2fb_c_int, 6ULL))))
                        c2fb_temp_5 = Cast(c2fb_c_int, &H3fULL)
                        c2fb_temp_4 = local4
                        local4 = (c2fb_temp_4 + 1)
                        c2fb_temp_7 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_6 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_5 And Cast(c2fb_c_int, (*(c2fb_temp_4))))))))))
                        local8 = c2fb_temp_7
                    c2fb_flow_5:
                    Wend
                    c2fb_flow_4:
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local8 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local8 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                        c2fb_temp_8 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                        local8 = c2fb_temp_8
                    End If
                End If
                ' empty C statement
                If fts5UnicodeIsAlnum(local0, local8) Then
                    Goto c2fb_label_1
                End If
            Else
                If local2[(*local4)] Then
                    c2fb_temp_9 = Cast(c2fb_c_int, (CPtr(UByte Ptr, local4) - CPtr(UByte Ptr, CPtr(UByte Ptr, arg3))))
                    local10 = c2fb_temp_9
                    Goto c2fb_label_2
                End If
                c2fb_temp_10 = local4
                local4 = (c2fb_temp_10 + 1)
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        While (-Cast(c2fb_c_int, ((local4 < local3))))
            If (-Cast(c2fb_c_int, ((local9 > local7)))) Then
                c2fb_temp_11 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, local6) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))))
                local5 = c2fb_temp_11
                If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    local1 = c2fb_temp_12
                    Goto c2fb_label_0
                End If
                c2fb_temp_13 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[(CPtr(Byte Ptr, CPtr(Byte Ptr, local9)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local0->aFold)))])))
                local9 = c2fb_temp_13
                c2fb_temp_14 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local5), CPtr(Const Any Ptr, local0->aFold), local6))
                sqlite3_free(CPtr(Any Ptr, local0->aFold))
                c2fb_temp_15 = CPtr(ZString Ptr Ptr, @(local0->aFold))
                c2fb_temp_16 = local5
                (*c2fb_temp_15) = c2fb_temp_16
                c2fb_temp_18 = CPtr(Long Ptr, @(local0->nFold))
                c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 * Cast(c2fb_c_int, 2ULL))))
                local6 = c2fb_temp_17
                c2fb_temp_19 = Cast(c2fb_c_int, c2fb_temp_17)
                (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
                c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
                c2fb_temp_20 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[Cast(c2fb_c_int, (local6 - Cast(c2fb_c_int, 6ULL)))])))
                local7 = c2fb_temp_20
            End If
            If Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local4)) And Cast(c2fb_c_int, &H80ULL))) Then
                c2fb_temp_21 = local4
                local4 = (c2fb_temp_21 + 1)
                c2fb_temp_22 = Cast(c2fb_c_uint, (*(c2fb_temp_21)))
                local8 = c2fb_temp_22
                If (-Cast(c2fb_c_int, ((local8 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
                    c2fb_temp_23 = Cast(c2fb_c_uint, c2fb_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local8 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
                    local8 = c2fb_temp_23
                    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < local3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local4)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                        c2fb_temp_26 = (Cast(c2fb_c_uint, (local8 Shl Cast(c2fb_c_int, 6ULL))))
                        c2fb_temp_25 = Cast(c2fb_c_int, &H3fULL)
                        c2fb_temp_24 = local4
                        local4 = (c2fb_temp_24 + 1)
                        c2fb_temp_27 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_26 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_25 And Cast(c2fb_c_int, (*(c2fb_temp_24))))))))))
                        local8 = c2fb_temp_27
                    c2fb_flow_9:
                    Wend
                    c2fb_flow_8:
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local8 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local8 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                        c2fb_temp_28 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                        local8 = c2fb_temp_28
                    End If
                End If
                ' empty C statement
                If (-Cast(c2fb_c_int, (((fts5UnicodeIsAlnum(local0, local8) <> 0) OrElse (c2fb_external_sqlite3Fts5UnicodeIsdiacritic(local8) <> 0))))) Then
                    c2fb_label_1:
                    c2fb_temp_29 = Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5UnicodeFold(local8, local0->eRemoveDiacritic))
                    local8 = c2fb_temp_29
                    If local8 Then
                        If (-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H00080ULL)))))) Then
                            c2fb_temp_30 = local9
                            local9 = (c2fb_temp_30 + 1)
                            c2fb_temp_31 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_30))))
                            c2fb_temp_32 = Cast(Byte, Cast(UByte, (Cast(c2fb_c_uint, (local8 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL)))))))
                            (*c2fb_temp_31) = c2fb_temp_32
                        Else
                            If (-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H00800ULL)))))) Then
                                c2fb_temp_33 = local9
                                local9 = (c2fb_temp_33 + 1)
                                c2fb_temp_34 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_33))))
                                c2fb_temp_35 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HC0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local8 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H1FULL))))))))))
                                (*c2fb_temp_34) = c2fb_temp_35
                                c2fb_temp_36 = local9
                                local9 = (c2fb_temp_36 + 1)
                                c2fb_temp_37 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_36))))
                                c2fb_temp_38 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local8 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                                (*c2fb_temp_37) = c2fb_temp_38
                            Else
                                If (-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H10000ULL)))))) Then
                                    c2fb_temp_39 = local9
                                    local9 = (c2fb_temp_39 + 1)
                                    c2fb_temp_40 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_39))))
                                    c2fb_temp_41 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HE0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local8 Shr Cast(c2fb_c_int, 12ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H0FULL))))))))))
                                    (*c2fb_temp_40) = c2fb_temp_41
                                    c2fb_temp_42 = local9
                                    local9 = (c2fb_temp_42 + 1)
                                    c2fb_temp_43 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_42))))
                                    c2fb_temp_44 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local8 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                                    (*c2fb_temp_43) = c2fb_temp_44
                                    c2fb_temp_45 = local9
                                    local9 = (c2fb_temp_45 + 1)
                                    c2fb_temp_46 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_45))))
                                    c2fb_temp_47 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local8 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                                    (*c2fb_temp_46) = c2fb_temp_47
                                Else
                                    c2fb_temp_48 = local9
                                    local9 = (c2fb_temp_48 + 1)
                                    c2fb_temp_49 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_48))))
                                    c2fb_temp_50 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HF0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local8 Shr Cast(c2fb_c_int, 18ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H07ULL))))))))))
                                    (*c2fb_temp_49) = c2fb_temp_50
                                    c2fb_temp_51 = local9
                                    local9 = (c2fb_temp_51 + 1)
                                    c2fb_temp_52 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_51))))
                                    c2fb_temp_53 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local8 Shr Cast(c2fb_c_int, 12ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                                    (*c2fb_temp_52) = c2fb_temp_53
                                    c2fb_temp_54 = local9
                                    local9 = (c2fb_temp_54 + 1)
                                    c2fb_temp_55 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_54))))
                                    c2fb_temp_56 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local8 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                                    (*c2fb_temp_55) = c2fb_temp_56
                                    c2fb_temp_57 = local9
                                    local9 = (c2fb_temp_57 + 1)
                                    c2fb_temp_58 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_57))))
                                    c2fb_temp_59 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local8 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                                    (*c2fb_temp_58) = c2fb_temp_59
                                End If
                            End If
                        End If
                    End If
                    ' empty C statement
                Else
                    Goto c2fb_flow_6
                End If
            Else
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2[(*local4)]) = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_6
                Else
                    c2fb_label_2:
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*local4)) >= Cast(c2fb_c_int, 65))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*local4)) <= Cast(c2fb_c_int, 90))))) <> 0))))) Then
                        c2fb_temp_60 = local9
                        local9 = (c2fb_temp_60 + 1)
                        c2fb_temp_61 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_60))))
                        c2fb_temp_62 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local4)) + Cast(c2fb_c_int, 32ULL))))
                        (*c2fb_temp_61) = c2fb_temp_62
                    Else
                        c2fb_temp_63 = local9
                        local9 = (c2fb_temp_63 + 1)
                        c2fb_temp_64 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_63))))
                        c2fb_temp_65 = Cast(Byte, (*local4))
                        (*c2fb_temp_64) = c2fb_temp_65
                    End If
                    c2fb_temp_66 = local4
                    local4 = (c2fb_temp_66 + 1)
                End If
            End If
            c2fb_temp_67 = Cast(c2fb_c_int, (CPtr(UByte Ptr, local4) - CPtr(UByte Ptr, CPtr(UByte Ptr, arg3))))
            local11 = c2fb_temp_67
        c2fb_flow_7:
        Wend
        c2fb_flow_6:
        c2fb_temp_68 = Cast(c2fb_c_int, arg5(arg1, Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr, local5), (CPtr(Byte Ptr, CPtr(Byte Ptr, local9)) - CPtr(Byte Ptr, CPtr(Byte Ptr, local5))), local10, local11))
        local1 = c2fb_temp_68
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_label_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 101ULL))))) Then
        c2fb_temp_69 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_69
    End If
    Return local1
End Function
Private Sub fts5PorterDelete CDecl Alias "fts5PorterDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 564
    Dim local0 As c2fb_PorterTokenizer Ptr

    If arg0 Then
        local0 = CPtr(c2fb_PorterTokenizer Ptr, arg0)
        If CPtr(c2fb_Fts5Tokenizer Ptr, local0->pTokenizer) Then
            CPtr(c2fb_callback_155, local0->tokenizer_v2.xDelete)(CPtr(c2fb_Fts5Tokenizer Ptr, local0->pTokenizer))
        End If
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Function fts5PorterCreate CDecl Alias "fts5PorterCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 577
    Dim local0 As c2fb_fts5_api Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_PorterTokenizer Ptr
    Dim local3 As Any Ptr
    Dim local4 As Const ZString Ptr
    Dim local5 As c2fb_fts5_tokenizer_v2 Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_PorterTokenizer Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As Const ZString Ptr Ptr
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_PorterTokenizer Ptr
    Dim c2fb_temp_10 As c2fb_Fts5Tokenizer Ptr Ptr
    Dim c2fb_temp_11 As c2fb_Fts5Tokenizer Ptr

    local0 = CPtr(c2fb_fts5_api Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = StrPtr(!"unicode61")
    local5 = Cast(c2fb_c_int, &O0ULL)
    While (-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_c_int, &O0ULL)))))
        If (-Cast(c2fb_c_int, ((sqlite3_stricmp(arg1[Cast(c2fb_c_int, &O0ULL)], StrPtr(!"porter")) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = arg2
            arg2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 - 1)))
            c2fb_temp_1 = arg1
            arg1 = (c2fb_temp_1 + 1)
        Else
            c2fb_temp_2 = arg1[Cast(c2fb_c_int, &O0ULL)]
            local4 = c2fb_temp_2
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_PorterTokenizer Ptr, CPtr(c2fb_PorterTokenizer Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_PorterTokenizer))))))
    local2 = c2fb_temp_3
    If local2 Then
        c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_PorterTokenizer))))
        c2fb_temp_5 = Cast(c2fb_c_int, CPtr(c2fb_callback_162, local0->xFindTokenizer_v2)(local0, local4, CPtr(Any Ptr Ptr, @(local3)), CPtr(c2fb_fts5_tokenizer_v2 Ptr Ptr, @(local5))))
        local1 = c2fb_temp_5
    Else
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local1 = c2fb_temp_6
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        local6 = (IIf((-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL)))
        local7 = (IIf(local6, CPtr(Const ZString Ptr Ptr, @(arg1[Cast(c2fb_c_int, 1ULL)])), CPtr(Const ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_fts5_tokenizer_v2 Ptr, @(local2->tokenizer_v2))), CPtr(Const Any Ptr, local5), Cast(c2fb_size_t, SizeOf(c2fb_fts5_tokenizer_v2))))
        c2fb_temp_8 = Cast(c2fb_c_int, CPtr(c2fb_callback_154, local2->tokenizer_v2.xCreate)(local3, local7, local6, CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @(local2->pTokenizer))))
        local1 = c2fb_temp_8
    End If
    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
        fts5PorterDelete(CPtr(c2fb_Fts5Tokenizer Ptr, local2))
        c2fb_temp_9 = CPtr(_c2fb_record_c2fb_PorterTokenizer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local2 = c2fb_temp_9
    End If
    c2fb_temp_10 = CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @((*arg3)))
    c2fb_temp_11 = CPtr(c2fb_Fts5Tokenizer Ptr, local2)
    (*c2fb_temp_10) = c2fb_temp_11
    Return local1
End Function
Private Function fts5PorterIsVowel CDecl Alias "fts5PorterIsVowel" (ByVal arg0 As Byte, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 663
    Return ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 97))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 101))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 105))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 111))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 117))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0) = Cast(c2fb_c_int, 121))))) <> 0)))))) <> 0))))))
End Function
Private Function fts5PorterGobbleVC CDecl Alias "fts5PorterGobbleVC" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 669
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    ' C automatic storage declaration
    local1 = arg2
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        c2fb_temp_3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, (fts5PorterIsVowel(CPtr(Byte Ptr, arg0)[local0], local1) = 0))))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((c2fb_temp_3 = (c2fb_temp_2))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = local0
    local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        c2fb_temp_6 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, (fts5PorterIsVowel(CPtr(Byte Ptr, arg0)[local0], local1) = 0))))
        local1 = c2fb_temp_6
        If (c2fb_temp_6) Then
            Return Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))
        End If
    c2fb_flow_3:
        c2fb_temp_5 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_2:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5Porter_MGt0 CDecl Alias "fts5Porter_MGt0" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 686
    Return (-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (fts5PorterGobbleVC(arg0, arg1, Cast(c2fb_c_int, &O0ULL)) = 0))) = 0)))
End Function
Private Function fts5Porter_MGt1 CDecl Alias "fts5Porter_MGt1" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 691
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, fts5PorterGobbleVC(arg0, arg1, Cast(c2fb_c_int, &O0ULL)))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso (fts5PorterGobbleVC(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[local0]))), Cast(c2fb_c_int, (arg1 - local0)), Cast(c2fb_c_int, 1ULL)) <> 0))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5Porter_MEq1 CDecl Alias "fts5Porter_MEq1" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 701
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, fts5PorterGobbleVC(arg0, arg1, Cast(c2fb_c_int, &O0ULL)))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5PorterGobbleVC(CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[local0]))), Cast(c2fb_c_int, (arg1 - local0)), Cast(c2fb_c_int, 1ULL)))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5Porter_Ostar CDecl Alias "fts5Porter_Ostar" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 711
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 119))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 120))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 121))))) <> 0))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    Else
        ' C automatic storage declaration
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg1))))
            c2fb_temp_2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, (fts5PorterIsVowel(CPtr(Byte Ptr, arg0)[local0], local2) = 0))))
            local2 = c2fb_temp_2
#ifdef SQLITE_DEBUG
            fts5TokenizeAssert(local2 = 0 OrElse local2 = 1, _
                StrPtr(!"bCons==0 || bCons==1"))
#endif
            ' C unused-parameter annotation
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local1 Shl Cast(c2fb_c_int, 1ULL)))) + local2))) And Cast(c2fb_c_int, &H0007ULL))))
            local1 = c2fb_temp_3
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        Return ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &H0005ULL))))))
    End If
End Function
Private Function fts5Porter_MGt1_and_S_or_T CDecl Alias "fts5Porter_MGt1_and_S_or_T" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 728
#ifdef SQLITE_DEBUG
    fts5TokenizeAssert(arg1 > 0, StrPtr(!"nStem>0"))
#endif
    ' C unused-parameter annotation
    Return (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 115))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 116))))) <> 0)))))) <> 0) AndAlso (fts5Porter_MGt1(arg0, arg1) <> 0)))))
End Function
Private Function fts5Porter_Vowel CDecl Alias "fts5Porter_Vowel" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 735
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        If fts5PorterIsVowel(CPtr(Byte Ptr, arg0)[local0], (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, &O0ULL)))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5PorterStep4 CDecl Alias "fts5PorterStep4" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 751
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int
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
    Dim c2fb_temp_26 As c2fb_c_int Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int Ptr
    Dim c2fb_temp_37 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (*arg1)
    Select Case CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]
        Case Cast(c2fb_c_int, 97)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"al")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))) Then
                    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_0) = c2fb_temp_1
                End If
            End If
        Case Cast(c2fb_c_int, 99)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ance")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))))
                    (*c2fb_temp_2) = c2fb_temp_3
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ence")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))))
                        (*c2fb_temp_4) = c2fb_temp_5
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 101)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"er")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))) Then
                    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_6) = c2fb_temp_7
                End If
            End If
        Case Cast(c2fb_c_int, 105)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ic")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))) Then
                    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_8) = c2fb_temp_9
                End If
            End If
        Case Cast(c2fb_c_int, 108)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"able")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))))
                    (*c2fb_temp_10) = c2fb_temp_11
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ible")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                        c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))))
                        (*c2fb_temp_12) = c2fb_temp_13
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 110)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ant")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_14) = c2fb_temp_15
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ement")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                        c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))))
                        (*c2fb_temp_16) = c2fb_temp_17
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ment")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                        If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                            c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))))
                            (*c2fb_temp_18) = c2fb_temp_19
                        End If
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ent")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                            If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                                c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                                c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                                (*c2fb_temp_20) = c2fb_temp_21
                            End If
                        End If
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 111)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ion")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1_and_S_or_T(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_22) = c2fb_temp_23
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ou")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))) Then
                        c2fb_temp_24 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))))
                        (*c2fb_temp_24) = c2fb_temp_25
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 115)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ism")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_26 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_26) = c2fb_temp_27
                End If
            End If
        Case Cast(c2fb_c_int, 116)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ate")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_28 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_28) = c2fb_temp_29
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"iti")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                        c2fb_temp_30 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                        (*c2fb_temp_30) = c2fb_temp_31
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 117)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ous")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_32 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_32) = c2fb_temp_33
                End If
            End If
        Case Cast(c2fb_c_int, 118)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ive")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_34 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_35 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_34) = c2fb_temp_35
                End If
            End If
        Case Cast(c2fb_c_int, 122)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ize")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt1(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_36 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_37 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_36) = c2fb_temp_37
                End If
            End If
    End Select
    c2fb_flow_0:
    Return local0
End Function
Private Function fts5PorterStep1B2 CDecl Alias "fts5PorterStep1B2" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 885
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (*arg1)
    Select Case CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]
        Case Cast(c2fb_c_int, 97)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"at")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ate")), Cast(c2fb_c_int, 3ULL)))
                c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 3ULL))))
                (*c2fb_temp_1) = c2fb_temp_2
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_3
            End If
        Case Cast(c2fb_c_int, 98)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"bl")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ble")), Cast(c2fb_c_int, 3ULL)))
                c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 3ULL))))
                (*c2fb_temp_5) = c2fb_temp_6
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_7
            End If
        Case Cast(c2fb_c_int, 105)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"iz")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                c2fb_temp_8 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ize")), Cast(c2fb_c_int, 3ULL)))
                c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 3ULL))))
                (*c2fb_temp_9) = c2fb_temp_10
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_11
            End If
    End Select
    c2fb_flow_0:
    Return local0
End Function
Private Function fts5PorterStep2 CDecl Alias "fts5PorterStep2" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 919
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Any Ptr
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Any Ptr
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Any Ptr
    Dim c2fb_temp_22 As c2fb_c_int Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As Any Ptr
    Dim c2fb_temp_25 As c2fb_c_int Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As Any Ptr
    Dim c2fb_temp_28 As c2fb_c_int Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As Any Ptr
    Dim c2fb_temp_31 As c2fb_c_int Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As Any Ptr
    Dim c2fb_temp_34 As c2fb_c_int Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As Any Ptr
    Dim c2fb_temp_37 As c2fb_c_int Ptr
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As Any Ptr
    Dim c2fb_temp_40 As c2fb_c_int Ptr
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As Any Ptr
    Dim c2fb_temp_43 As c2fb_c_int Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As Any Ptr
    Dim c2fb_temp_46 As c2fb_c_int Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As Any Ptr
    Dim c2fb_temp_49 As c2fb_c_int Ptr
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As Any Ptr
    Dim c2fb_temp_52 As c2fb_c_int Ptr
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As Any Ptr
    Dim c2fb_temp_55 As c2fb_c_int Ptr
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As Any Ptr
    Dim c2fb_temp_58 As c2fb_c_int Ptr
    Dim c2fb_temp_59 As c2fb_c_int
    Dim c2fb_temp_60 As Any Ptr
    Dim c2fb_temp_61 As c2fb_c_int Ptr
    Dim c2fb_temp_62 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (*arg1)
    Select Case CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]
        Case Cast(c2fb_c_int, 97)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 7ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ational")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), Cast(c2fb_c_int, 7ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))) Then
                    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ate")), Cast(c2fb_c_int, 3ULL)))
                    c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL))) + Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_1) = c2fb_temp_2
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 6ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"tional")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 6ULL)))]))), Cast(c2fb_c_int, 6ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 6ULL)))) Then
                        c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 6ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"tion")), Cast(c2fb_c_int, 4ULL)))
                        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 6ULL))) + Cast(c2fb_c_int, 4ULL))))
                        (*c2fb_temp_4) = c2fb_temp_5
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 99)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"enci")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                    c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ence")), Cast(c2fb_c_int, 4ULL)))
                    c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 4ULL))))
                    (*c2fb_temp_7) = c2fb_temp_8
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"anci")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ance")), Cast(c2fb_c_int, 4ULL)))
                        c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 4ULL))))
                        (*c2fb_temp_10) = c2fb_temp_11
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 101)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"izer")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                    c2fb_temp_12 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ize")), Cast(c2fb_c_int, 3ULL)))
                    c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_13) = c2fb_temp_14
                End If
            End If
        Case Cast(c2fb_c_int, 103)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"logi")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                    c2fb_temp_15 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"log")), Cast(c2fb_c_int, 3ULL)))
                    c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_16) = c2fb_temp_17
                End If
            End If
        Case Cast(c2fb_c_int, 108)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"bli")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_18 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ble")), Cast(c2fb_c_int, 3ULL)))
                    c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_19) = c2fb_temp_20
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"alli")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                        c2fb_temp_21 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"al")), Cast(c2fb_c_int, 2ULL)))
                        c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 2ULL))))
                        (*c2fb_temp_22) = c2fb_temp_23
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"entli")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                        If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                            c2fb_temp_24 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ent")), Cast(c2fb_c_int, 3ULL)))
                            c2fb_temp_25 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                            c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 3ULL))))
                            (*c2fb_temp_25) = c2fb_temp_26
                        End If
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"eli")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                            If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                                c2fb_temp_27 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"e")), Cast(c2fb_c_int, 1ULL)))
                                c2fb_temp_28 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                                c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 1ULL))))
                                (*c2fb_temp_28) = c2fb_temp_29
                            End If
                        Else
                            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ousli")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                                    c2fb_temp_30 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ous")), Cast(c2fb_c_int, 3ULL)))
                                    c2fb_temp_31 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                                    c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 3ULL))))
                                    (*c2fb_temp_31) = c2fb_temp_32
                                End If
                            End If
                        End If
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 111)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 7ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ization")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), Cast(c2fb_c_int, 7ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))) Then
                    c2fb_temp_33 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ize")), Cast(c2fb_c_int, 3ULL)))
                    c2fb_temp_34 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_35 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL))) + Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_34) = c2fb_temp_35
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ation")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                        c2fb_temp_36 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ate")), Cast(c2fb_c_int, 3ULL)))
                        c2fb_temp_37 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 3ULL))))
                        (*c2fb_temp_37) = c2fb_temp_38
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ator")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                        If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                            c2fb_temp_39 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ate")), Cast(c2fb_c_int, 3ULL)))
                            c2fb_temp_40 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                            c2fb_temp_41 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 3ULL))))
                            (*c2fb_temp_40) = c2fb_temp_41
                        End If
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 115)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"alism")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                    c2fb_temp_42 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"al")), Cast(c2fb_c_int, 2ULL)))
                    c2fb_temp_43 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_44 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_43) = c2fb_temp_44
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 7ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"iveness")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), Cast(c2fb_c_int, 7ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))) Then
                        c2fb_temp_45 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ive")), Cast(c2fb_c_int, 3ULL)))
                        c2fb_temp_46 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL))) + Cast(c2fb_c_int, 3ULL))))
                        (*c2fb_temp_46) = c2fb_temp_47
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 7ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"fulness")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), Cast(c2fb_c_int, 7ULL)))))) <> 0))))) Then
                        If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))) Then
                            c2fb_temp_48 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ful")), Cast(c2fb_c_int, 3ULL)))
                            c2fb_temp_49 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                            c2fb_temp_50 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL))) + Cast(c2fb_c_int, 3ULL))))
                            (*c2fb_temp_49) = c2fb_temp_50
                        End If
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 7ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ousness")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), Cast(c2fb_c_int, 7ULL)))))) <> 0))))) Then
                            If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))) Then
                                c2fb_temp_51 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ous")), Cast(c2fb_c_int, 3ULL)))
                                c2fb_temp_52 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                                c2fb_temp_53 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 7ULL))) + Cast(c2fb_c_int, 3ULL))))
                                (*c2fb_temp_52) = c2fb_temp_53
                            End If
                        End If
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 116)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"aliti")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                    c2fb_temp_54 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"al")), Cast(c2fb_c_int, 2ULL)))
                    c2fb_temp_55 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_56 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_55) = c2fb_temp_56
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"iviti")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                        c2fb_temp_57 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ive")), Cast(c2fb_c_int, 3ULL)))
                        c2fb_temp_58 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_59 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 3ULL))))
                        (*c2fb_temp_58) = c2fb_temp_59
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 6ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"biliti")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 6ULL)))]))), Cast(c2fb_c_int, 6ULL)))))) <> 0))))) Then
                        If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 6ULL)))) Then
                            c2fb_temp_60 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 6ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ble")), Cast(c2fb_c_int, 3ULL)))
                            c2fb_temp_61 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                            c2fb_temp_62 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 6ULL))) + Cast(c2fb_c_int, 3ULL))))
                            (*c2fb_temp_61) = c2fb_temp_62
                        End If
                    End If
                End If
            End If
    End Select
    c2fb_flow_0:
    Return local0
End Function
Private Function fts5PorterStep3 CDecl Alias "fts5PorterStep3" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1066
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Any Ptr
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (*arg1)
    Select Case CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]
        Case Cast(c2fb_c_int, 97)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ical")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ic")), Cast(c2fb_c_int, 2ULL)))
                    c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_1) = c2fb_temp_2
                End If
            End If
        Case Cast(c2fb_c_int, 115)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ness")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))]))), Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL)))) Then
                    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 4ULL))))
                    (*c2fb_temp_3) = c2fb_temp_4
                End If
            End If
        Case Cast(c2fb_c_int, 116)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"icate")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                    c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ic")), Cast(c2fb_c_int, 2ULL)))
                    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_6) = c2fb_temp_7
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"iciti")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                    If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                        c2fb_temp_8 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ic")), Cast(c2fb_c_int, 2ULL)))
                        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 2ULL))))
                        (*c2fb_temp_9) = c2fb_temp_10
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 117)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ful")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_11) = c2fb_temp_12
                End If
            End If
        Case Cast(c2fb_c_int, 118)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ative")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                    c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))))
                    (*c2fb_temp_13) = c2fb_temp_14
                End If
            End If
        Case Cast(c2fb_c_int, 122)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"alize")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))) Then
                    c2fb_temp_15 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"al")), Cast(c2fb_c_int, 2ULL)))
                    c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_16) = c2fb_temp_17
                End If
            End If
    End Select
    c2fb_flow_0:
    Return local0
End Function
Private Function fts5PorterStep1B CDecl Alias "fts5PorterStep1B" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1132
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = (*arg1)
    Select Case CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]
        Case Cast(c2fb_c_int, 101)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"eed")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_MGt0(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), CPtr(Const Any Ptr, StrPtr(!"ee")), Cast(c2fb_c_int, 2ULL)))
                    c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))) + Cast(c2fb_c_int, 2ULL))))
                    (*c2fb_temp_1) = c2fb_temp_2
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ed")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))]))), Cast(c2fb_c_int, 2ULL)))))) <> 0))))) Then
                    If fts5Porter_Vowel(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL)))) Then
                        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))))
                        (*c2fb_temp_3) = c2fb_temp_4
                        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local0 = c2fb_temp_5
                    End If
                End If
            End If
        Case Cast(c2fb_c_int, 110)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"ing")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))]))), Cast(c2fb_c_int, 3ULL)))))) <> 0))))) Then
                If fts5Porter_Vowel(arg0, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL)))) Then
                    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 3ULL))))
                    (*c2fb_temp_6) = c2fb_temp_7
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local0 = c2fb_temp_8
                End If
            End If
    End Select
    c2fb_flow_0:
    Return local0
End Function
Private Sub fts5PorterStep1A CDecl Alias "fts5PorterStep1A" (ByVal arg0 As ZString Ptr, ByVal arg1 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1169
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = (*arg1)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 115))))) Then
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 2ULL)))]) = Cast(c2fb_c_int, 101))))) Then
            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 4ULL)))]) = Cast(c2fb_c_int, 115))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 3ULL)))]) = Cast(c2fb_c_int, 115))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 3ULL)))]) = Cast(c2fb_c_int, 105))))) <> 0)))))) <> 0))))) Then
                c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 2ULL))))
                (*c2fb_temp_0) = c2fb_temp_1
            Else
                c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_2) = c2fb_temp_3
            End If
        Else
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0)[Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 2ULL)))]) <> Cast(c2fb_c_int, 115))))) Then
                c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_4) = c2fb_temp_5
            End If
        End If
    End If
End Sub
Private Function fts5PorterCb CDecl Alias "fts5PorterCb" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1187
    Dim local0 As c2fb_PorterContext Ptr
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim local3 As Byte
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Byte Ptr
    Dim c2fb_temp_6 As Byte
    Dim c2fb_temp_7 As Byte Ptr
    Dim c2fb_temp_8 As Byte
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int

    local0 = CPtr(c2fb_PorterContext Ptr, arg0)
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, 64ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg3 < Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        Goto c2fb_label_0
    End If
    c2fb_temp_0 = local0->aBuf
    local1 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, arg3)
    local2 = c2fb_temp_1
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1), CPtr(Const Any Ptr, arg2), local2))
    fts5PorterStep1A(local1, CPtr(c2fb_c_int Ptr, @(local2)))
    If fts5PorterStep1B(local1, CPtr(c2fb_c_int Ptr, @(local2))) Then
        If (-Cast(c2fb_c_int, ((fts5PorterStep1B2(local1, CPtr(c2fb_c_int Ptr, @(local2))) = Cast(c2fb_c_int, &O0ULL))))) Then
            local3 = CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))]
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((fts5PorterIsVowel(local3, Cast(c2fb_c_int, &O0ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) <> Cast(c2fb_c_int, 108))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) <> Cast(c2fb_c_int, 115))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) <> Cast(c2fb_c_int, 122))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) = Cast(c2fb_c_int, CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 2ULL)))]))))) <> 0))))) Then
                c2fb_temp_3 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
            Else
                If (-Cast(c2fb_c_int, (((fts5Porter_MEq1(local1, local2) <> 0) AndAlso (fts5Porter_Ostar(local1, local2) <> 0))))) Then
                    c2fb_temp_4 = local2
                    local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
                    c2fb_temp_5 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[c2fb_temp_4]))
                    c2fb_temp_6 = Cast(Byte, Cast(c2fb_c_int, 101))
                    (*c2fb_temp_5) = c2fb_temp_6
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 121))))) <> 0) AndAlso (fts5Porter_Vowel(local1, Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))) <> 0))))) Then
        c2fb_temp_7 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))]))
        c2fb_temp_8 = Cast(Byte, Cast(c2fb_c_int, 105))
        (*c2fb_temp_7) = c2fb_temp_8
    End If
    fts5PorterStep2(local1, CPtr(c2fb_c_int Ptr, @(local2)))
    fts5PorterStep3(local1, CPtr(c2fb_c_int Ptr, @(local2)))
    fts5PorterStep4(local1, CPtr(c2fb_c_int Ptr, @(local2)))
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    fts5TokenizeAssert(local2 > 0, StrPtr(!"nBuf>0"))
#endif
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 101))))) Then
        If (-Cast(c2fb_c_int, (((fts5Porter_MGt1(local1, Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))) <> 0) OrElse (((-Cast(c2fb_c_int, (((fts5Porter_MEq1(local1, Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (fts5Porter_Ostar(local1, Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))) = 0))) <> 0)))))) <> 0))))) Then
            c2fb_temp_9 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 - 1)))
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 > Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 108))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local1)[Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 2ULL)))]) = Cast(c2fb_c_int, 108))))) <> 0) AndAlso (fts5Porter_MGt1(local1, Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 1ULL)))) <> 0))))) Then
        c2fb_temp_10 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 - 1)))
    End If
    Return CPtr(c2fb_callback_136, local0->xToken)(local0->pCtx, arg1, CPtr(Const ZString Ptr, local1), local2, arg4, arg5)
    c2fb_label_0:
    Return CPtr(c2fb_callback_136, local0->xToken)(local0->pCtx, arg1, arg2, arg3, arg4, arg5)
End Function
Private Function fts5PorterTokenize CDecl Alias "fts5PorterTokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_callback_136) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1256
    Dim local0 As c2fb_PorterTokenizer Ptr
    Dim local1 As c2fb_PorterContext
    Type c2fb_callback_storage_0 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long
    Dim c2fb_temp_0 As c2fb_callback_storage_0 Ptr
    Dim c2fb_temp_1 As c2fb_callback_136
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr

    local0 = CPtr(c2fb_PorterTokenizer Ptr, arg0)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_callback_storage_0 Ptr, @(local1.xToken))
    c2fb_temp_1 = arg7
    (*c2fb_temp_0) = CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As Long, ByVal arg5 As Long) As Long, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_callback_136, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Any Ptr Ptr, @(local1.pCtx))
    c2fb_temp_3 = arg1
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(local1.aBuf))
    c2fb_temp_5 = CPtr(ZString Ptr, (@local0->aBuf(0)))
    (*c2fb_temp_4) = c2fb_temp_5
    Return CPtr(c2fb_callback_156, local0->tokenizer_v2.xTokenize)(CPtr(c2fb_Fts5Tokenizer Ptr, local0->pTokenizer), CPtr(Any Ptr, CPtr(c2fb_PorterContext Ptr, @(local1))), arg2, arg3, arg4, arg5, arg6, ProcPtr(fts5PorterCb))
End Function
Private Sub fts5TriDelete CDecl Alias "fts5TriDelete" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1286
    sqlite3_free(CPtr(Any Ptr, arg0))
End Sub
Private Function fts5TriCreate CDecl Alias "fts5TriCreate" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Tokenizer Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1293
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_TrigramTokenizer Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_TrigramTokenizer Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_TrigramTokenizer Ptr
    Dim c2fb_temp_18 As c2fb_Fts5Tokenizer Ptr Ptr
    Dim c2fb_temp_19 As c2fb_Fts5Tokenizer Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If Cast(c2fb_c_int, (arg2 Mod Cast(c2fb_c_int, 2ULL))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_0
    Else
        ' C automatic storage declaration
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_TrigramTokenizer Ptr, CPtr(c2fb_TrigramTokenizer Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_TrigramTokenizer))))))
        local1 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_2
        Else
            c2fb_temp_3 = CPtr(Long Ptr, @(local1->bFold))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            c2fb_temp_5 = CPtr(Long Ptr, @(local1->iFoldParam))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_7
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < arg2)))) <> 0)))))
                local3 = arg1[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))]
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local2], StrPtr(!"case_sensitive")))))) Then
                    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 49))))) <> 0)))))) <> 0) OrElse (CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, 1ULL)] <> 0))))) Then
                        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local0 = c2fb_temp_9
                    Else
                        c2fb_temp_10 = CPtr(Long Ptr, @(local1->bFold))
                        c2fb_temp_11 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 48)))))))
                        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
                        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg1[local2], StrPtr(!"remove_diacritics")))))) Then
                        If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 49))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 50))))) <> 0)))))) <> 0) OrElse (CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, 1ULL)] <> 0))))) Then
                            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local0 = c2fb_temp_12
                        Else
                            c2fb_temp_13 = CPtr(Long Ptr, @(local1->iFoldParam))
                            c2fb_temp_14 = Cast(c2fb_c_int, IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local3)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 48)))))), Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, &O0ULL)))
                            (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
                            c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
                        End If
                    Else
                        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local0 = c2fb_temp_15
                    End If
                End If
            c2fb_flow_1:
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 2ULL))))
                local2 = c2fb_temp_8
            Wend
            c2fb_flow_0:
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->iFoldParam <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->bFold = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_16
            End If
            If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                fts5TriDelete(CPtr(c2fb_Fts5Tokenizer Ptr, local1))
                c2fb_temp_17 = CPtr(_c2fb_record_c2fb_TrigramTokenizer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local1 = c2fb_temp_17
            End If
        End If
    End If
    c2fb_temp_18 = CPtr(c2fb_Fts5Tokenizer Ptr Ptr, @((*arg3)))
    c2fb_temp_19 = CPtr(c2fb_Fts5Tokenizer Ptr, local1)
    (*c2fb_temp_18) = c2fb_temp_19
    Return local0
End Function
Private Function fts5TriTokenize CDecl Alias "fts5TriTokenize" (ByVal arg0 As c2fb_Fts5Tokenizer Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_136) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1349
    Dim local0 As c2fb_TrigramTokenizer Ptr
    Dim local1 As c2fb_c_int
    Dim local2(0 To 31) As Byte
    Dim local3 As ZString Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As Const UByte Ptr
    Dim local6 As Const UByte Ptr
    Dim local7 As c2fb_c_uint
    Dim local8(0 To 2) As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Const UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As Const UByte Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_uint
    Dim c2fb_temp_10 As c2fb_c_uint
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim c2fb_temp_12 As c2fb_c_uint
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As Byte Ptr
    Dim c2fb_temp_15 As Byte
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As Byte Ptr
    Dim c2fb_temp_18 As Byte
    Dim c2fb_temp_19 As ZString Ptr
    Dim c2fb_temp_20 As Byte Ptr
    Dim c2fb_temp_21 As Byte
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As Byte Ptr
    Dim c2fb_temp_24 As Byte
    Dim c2fb_temp_25 As ZString Ptr
    Dim c2fb_temp_26 As Byte Ptr
    Dim c2fb_temp_27 As Byte
    Dim c2fb_temp_28 As ZString Ptr
    Dim c2fb_temp_29 As Byte Ptr
    Dim c2fb_temp_30 As Byte
    Dim c2fb_temp_31 As ZString Ptr
    Dim c2fb_temp_32 As Byte Ptr
    Dim c2fb_temp_33 As Byte
    Dim c2fb_temp_34 As ZString Ptr
    Dim c2fb_temp_35 As Byte Ptr
    Dim c2fb_temp_36 As Byte
    Dim c2fb_temp_37 As ZString Ptr
    Dim c2fb_temp_38 As Byte Ptr
    Dim c2fb_temp_39 As Byte
    Dim c2fb_temp_40 As ZString Ptr
    Dim c2fb_temp_41 As Byte Ptr
    Dim c2fb_temp_42 As Byte
    Dim local9 As c2fb_c_int
    Dim local10 As Const ZString Ptr
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_uint
    Dim c2fb_temp_45 As Const UByte Ptr
    Dim c2fb_temp_46 As c2fb_c_uint
    Dim c2fb_temp_47 As c2fb_c_uint
    Dim c2fb_temp_48 As Const UByte Ptr
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As c2fb_c_uint
    Dim c2fb_temp_51 As c2fb_c_uint
    Dim c2fb_temp_52 As c2fb_c_uint
    Dim c2fb_temp_53 As c2fb_c_uint
    Dim c2fb_temp_54 As c2fb_c_int
    Dim c2fb_temp_55 As Const ZString Ptr
    Dim c2fb_temp_56 As Const ZString Ptr
    Dim c2fb_temp_57 As Const ZString Ptr
    Dim c2fb_temp_58 As Any Ptr
    Dim c2fb_temp_59 As ZString Ptr
    Dim c2fb_temp_60 As ZString Ptr
    Dim c2fb_temp_61 As Byte Ptr
    Dim c2fb_temp_62 As Byte
    Dim c2fb_temp_63 As ZString Ptr
    Dim c2fb_temp_64 As Byte Ptr
    Dim c2fb_temp_65 As Byte
    Dim c2fb_temp_66 As ZString Ptr
    Dim c2fb_temp_67 As Byte Ptr
    Dim c2fb_temp_68 As Byte
    Dim c2fb_temp_69 As ZString Ptr
    Dim c2fb_temp_70 As Byte Ptr
    Dim c2fb_temp_71 As Byte
    Dim c2fb_temp_72 As ZString Ptr
    Dim c2fb_temp_73 As Byte Ptr
    Dim c2fb_temp_74 As Byte
    Dim c2fb_temp_75 As ZString Ptr
    Dim c2fb_temp_76 As Byte Ptr
    Dim c2fb_temp_77 As Byte
    Dim c2fb_temp_78 As ZString Ptr
    Dim c2fb_temp_79 As Byte Ptr
    Dim c2fb_temp_80 As Byte
    Dim c2fb_temp_81 As ZString Ptr
    Dim c2fb_temp_82 As Byte Ptr
    Dim c2fb_temp_83 As Byte
    Dim c2fb_temp_84 As ZString Ptr
    Dim c2fb_temp_85 As Byte Ptr
    Dim c2fb_temp_86 As Byte
    Dim c2fb_temp_87 As ZString Ptr
    Dim c2fb_temp_88 As Byte Ptr
    Dim c2fb_temp_89 As Byte
    Dim c2fb_temp_90 As c2fb_c_int Ptr
    Dim c2fb_temp_91 As c2fb_c_int
    Dim c2fb_temp_92 As c2fb_c_int Ptr
    Dim c2fb_temp_93 As c2fb_c_int
    Dim c2fb_temp_94 As c2fb_c_int Ptr
    Dim c2fb_temp_95 As c2fb_c_int

    local0 = CPtr(c2fb_TrigramTokenizer Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic array storage
    local3 = CPtr(ZString Ptr, CPtr(Byte Ptr, (@local2(0))))
    ' C automatic storage declaration
    local5 = CPtr(Const UByte Ptr, arg3)
    local6 = CPtr(Const UByte Ptr, (IIf(local5, CPtr(UByte Ptr, @(local5[arg4])), CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
    local7 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic array storage
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, 3ULL)))))
        Do
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(local8(local4)))
            c2fb_temp_3 = Cast(c2fb_c_int, (CPtr(UByte Ptr, local5) - CPtr(UByte Ptr, CPtr(Const UByte Ptr, arg3))))
            (*c2fb_temp_2) = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((local5 >= local6)))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            c2fb_temp_4 = local5
            local5 = (c2fb_temp_4 + 1)
            c2fb_temp_5 = Cast(c2fb_c_uint, (*(c2fb_temp_4)))
            local7 = c2fb_temp_5
            If (-Cast(c2fb_c_int, ((local7 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
                c2fb_temp_6 = Cast(c2fb_c_uint, c2fb_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local7 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
                local7 = c2fb_temp_6
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 < local6)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local5)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                    c2fb_temp_9 = (Cast(c2fb_c_uint, (local7 Shl Cast(c2fb_c_int, 6ULL))))
                    c2fb_temp_8 = Cast(c2fb_c_int, &H3fULL)
                    c2fb_temp_7 = local5
                    local5 = (c2fb_temp_7 + 1)
                    c2fb_temp_10 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_9 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_8 And Cast(c2fb_c_int, (*(c2fb_temp_7))))))))))
                    local7 = c2fb_temp_10
                c2fb_flow_5:
                Wend
                c2fb_flow_4:
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                    c2fb_temp_11 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                    local7 = c2fb_temp_11
                End If
            End If
            ' empty C statement
            If local0->bFold Then
                c2fb_temp_12 = Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5UnicodeFold(local7, local0->iFoldParam))
                local7 = c2fb_temp_12
            End If
        c2fb_flow_3:
        Loop While (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))))))
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H00080ULL)))))) Then
            c2fb_temp_13 = local3
            local3 = (c2fb_temp_13 + 1)
            c2fb_temp_14 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_13))))
            c2fb_temp_15 = Cast(Byte, Cast(UByte, (Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL)))))))
            (*c2fb_temp_14) = c2fb_temp_15
        Else
            If (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H00800ULL)))))) Then
                c2fb_temp_16 = local3
                local3 = (c2fb_temp_16 + 1)
                c2fb_temp_17 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_16))))
                c2fb_temp_18 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HC0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H1FULL))))))))))
                (*c2fb_temp_17) = c2fb_temp_18
                c2fb_temp_19 = local3
                local3 = (c2fb_temp_19 + 1)
                c2fb_temp_20 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_19))))
                c2fb_temp_21 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                (*c2fb_temp_20) = c2fb_temp_21
            Else
                If (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H10000ULL)))))) Then
                    c2fb_temp_22 = local3
                    local3 = (c2fb_temp_22 + 1)
                    c2fb_temp_23 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_22))))
                    c2fb_temp_24 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HE0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 12ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H0FULL))))))))))
                    (*c2fb_temp_23) = c2fb_temp_24
                    c2fb_temp_25 = local3
                    local3 = (c2fb_temp_25 + 1)
                    c2fb_temp_26 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_25))))
                    c2fb_temp_27 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_26) = c2fb_temp_27
                    c2fb_temp_28 = local3
                    local3 = (c2fb_temp_28 + 1)
                    c2fb_temp_29 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_28))))
                    c2fb_temp_30 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_29) = c2fb_temp_30
                Else
                    c2fb_temp_31 = local3
                    local3 = (c2fb_temp_31 + 1)
                    c2fb_temp_32 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_31))))
                    c2fb_temp_33 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HF0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 18ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H07ULL))))))))))
                    (*c2fb_temp_32) = c2fb_temp_33
                    c2fb_temp_34 = local3
                    local3 = (c2fb_temp_34 + 1)
                    c2fb_temp_35 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_34))))
                    c2fb_temp_36 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 12ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_35) = c2fb_temp_36
                    c2fb_temp_37 = local3
                    local3 = (c2fb_temp_37 + 1)
                    c2fb_temp_38 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_37))))
                    c2fb_temp_39 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_38) = c2fb_temp_39
                    c2fb_temp_40 = local3
                    local3 = (c2fb_temp_40 + 1)
                    c2fb_temp_41 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_40))))
                    c2fb_temp_42 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_41) = c2fb_temp_42
                End If
            End If
        End If
        ' empty C statement
    c2fb_flow_1:
        c2fb_temp_1 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    fts5TokenizeAssert(local5 <= local6, StrPtr(!"zIn<=zEof"))
#endif
    While Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        ' C automatic storage declaration
        Do
            c2fb_temp_43 = Cast(c2fb_c_int, (CPtr(UByte Ptr, local5) - CPtr(UByte Ptr, CPtr(Const UByte Ptr, arg3))))
            local9 = c2fb_temp_43
            If (-Cast(c2fb_c_int, ((local5 >= local6)))) Then
                c2fb_temp_44 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
                local7 = c2fb_temp_44
                Goto c2fb_flow_8
            End If
            c2fb_temp_45 = local5
            local5 = (c2fb_temp_45 + 1)
            c2fb_temp_46 = Cast(c2fb_c_uint, (*(c2fb_temp_45)))
            local7 = c2fb_temp_46
            If (-Cast(c2fb_c_int, ((local7 >= Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL)))))) Then
                c2fb_temp_47 = Cast(c2fb_c_uint, c2fb_sqlite3Utf8Trans1(Cast(c2fb_c_uint, (local7 - Cast(c2fb_c_uint, Cast(c2fb_c_int, &Hc0ULL))))))
                local7 = c2fb_temp_47
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 < local6)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (*local5)) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                    c2fb_temp_50 = (Cast(c2fb_c_uint, (local7 Shl Cast(c2fb_c_int, 6ULL))))
                    c2fb_temp_49 = Cast(c2fb_c_int, &H3fULL)
                    c2fb_temp_48 = local5
                    local5 = (c2fb_temp_48 + 1)
                    c2fb_temp_51 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_50 + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (c2fb_temp_49 And Cast(c2fb_c_int, (*(c2fb_temp_48))))))))))
                    local7 = c2fb_temp_51
                c2fb_flow_11:
                Wend
                c2fb_flow_10:
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, &HFFFFF800ULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HD800ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, &HFFFFFFFEULL)))) = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFEULL)))))) <> 0))))) Then
                    c2fb_temp_52 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFFDULL))
                    local7 = c2fb_temp_52
                End If
            End If
            ' empty C statement
            If local0->bFold Then
                c2fb_temp_53 = Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5UnicodeFold(local7, local0->iFoldParam))
                local7 = c2fb_temp_53
            End If
        c2fb_flow_9:
        Loop While (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))))))
        c2fb_flow_8:
        c2fb_temp_54 = Cast(c2fb_c_int, arg5(arg1, Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr, CPtr(Byte Ptr, (@local2(0)))), (CPtr(Byte Ptr, CPtr(Byte Ptr, local3)) - CPtr(Byte Ptr, CPtr(Byte Ptr, (@local2(0))))), local8(Cast(c2fb_c_int, &O0ULL)), local9))
        local1 = c2fb_temp_54
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Goto c2fb_flow_6
        End If
        c2fb_temp_55 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, (@local2(0))))
        local10 = c2fb_temp_55
        c2fb_temp_56 = local10
        local10 = (c2fb_temp_56 + 1)
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(UByte, ((*CPtr(Const Byte Ptr, (c2fb_temp_56))))))) >= Cast(c2fb_c_int, &Hc0ULL))))) Then
            While (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(UByte, (*CPtr(Const Byte Ptr, local10))))) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL)))))
                c2fb_temp_57 = local10
                local10 = (c2fb_temp_57 + 1)
            c2fb_flow_13:
            Wend
            c2fb_flow_12:
        End If
        ' empty C statement
        c2fb_temp_58 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(Byte Ptr, (@local2(0)))), CPtr(Const Any Ptr, local10), (CPtr(Byte Ptr, CPtr(Byte Ptr, local3)) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, local10)))))
        c2fb_temp_59 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local3) - ((CPtr(Byte Ptr, CPtr(Const Byte Ptr, local10)) - CPtr(Byte Ptr, CPtr(Byte Ptr, (@local2(0))))))))
        local3 = c2fb_temp_59
        If (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H00080ULL)))))) Then
            c2fb_temp_60 = local3
            local3 = (c2fb_temp_60 + 1)
            c2fb_temp_61 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_60))))
            c2fb_temp_62 = Cast(Byte, Cast(UByte, (Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL)))))))
            (*c2fb_temp_61) = c2fb_temp_62
        Else
            If (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H00800ULL)))))) Then
                c2fb_temp_63 = local3
                local3 = (c2fb_temp_63 + 1)
                c2fb_temp_64 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_63))))
                c2fb_temp_65 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HC0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H1FULL))))))))))
                (*c2fb_temp_64) = c2fb_temp_65
                c2fb_temp_66 = local3
                local3 = (c2fb_temp_66 + 1)
                c2fb_temp_67 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_66))))
                c2fb_temp_68 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                (*c2fb_temp_67) = c2fb_temp_68
            Else
                If (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H10000ULL)))))) Then
                    c2fb_temp_69 = local3
                    local3 = (c2fb_temp_69 + 1)
                    c2fb_temp_70 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_69))))
                    c2fb_temp_71 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HE0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 12ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H0FULL))))))))))
                    (*c2fb_temp_70) = c2fb_temp_71
                    c2fb_temp_72 = local3
                    local3 = (c2fb_temp_72 + 1)
                    c2fb_temp_73 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_72))))
                    c2fb_temp_74 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_73) = c2fb_temp_74
                    c2fb_temp_75 = local3
                    local3 = (c2fb_temp_75 + 1)
                    c2fb_temp_76 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_75))))
                    c2fb_temp_77 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_76) = c2fb_temp_77
                Else
                    c2fb_temp_78 = local3
                    local3 = (c2fb_temp_78 + 1)
                    c2fb_temp_79 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_78))))
                    c2fb_temp_80 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &HF0ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 18ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H07ULL))))))))))
                    (*c2fb_temp_79) = c2fb_temp_80
                    c2fb_temp_81 = local3
                    local3 = (c2fb_temp_81 + 1)
                    c2fb_temp_82 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_81))))
                    c2fb_temp_83 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 12ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_82) = c2fb_temp_83
                    c2fb_temp_84 = local3
                    local3 = (c2fb_temp_84 + 1)
                    c2fb_temp_85 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_84))))
                    c2fb_temp_86 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local7 Shr Cast(c2fb_c_int, 6ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_85) = c2fb_temp_86
                    c2fb_temp_87 = local3
                    local3 = (c2fb_temp_87 + 1)
                    c2fb_temp_88 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_87))))
                    c2fb_temp_89 = Cast(Byte, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H80ULL) + Cast(c2fb_c_int, Cast(UByte, (Cast(c2fb_c_uint, (local7 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H3FULL))))))))))
                    (*c2fb_temp_88) = c2fb_temp_89
                End If
            End If
        End If
        ' empty C statement
        c2fb_temp_90 = CPtr(c2fb_c_int Ptr, @(local8(Cast(c2fb_c_int, &O0ULL))))
        c2fb_temp_91 = Cast(c2fb_c_int, local8(Cast(c2fb_c_int, 1ULL)))
        (*c2fb_temp_90) = c2fb_temp_91
        c2fb_temp_92 = CPtr(c2fb_c_int Ptr, @(local8(Cast(c2fb_c_int, 1ULL))))
        c2fb_temp_93 = Cast(c2fb_c_int, local8(Cast(c2fb_c_int, 2ULL)))
        (*c2fb_temp_92) = c2fb_temp_93
        c2fb_temp_94 = CPtr(c2fb_c_int Ptr, @(local8(Cast(c2fb_c_int, 2ULL))))
        c2fb_temp_95 = Cast(c2fb_c_int, local9)
        (*c2fb_temp_94) = c2fb_temp_95
    c2fb_flow_7:
    Wend
    c2fb_flow_6:
    Return local1
End Function
Function sqlite3Fts5TokenizerPattern CDecl Alias "sqlite3Fts5TokenizerPattern" (ByVal arg0 As c2fb_callback_154, ByVal arg1 As c2fb_Fts5Tokenizer Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1434
    Dim local0 As c2fb_TrigramTokenizer Ptr

    If (-Cast(c2fb_c_int, ((CPtr(Any Ptr, arg0) = CPtr(Any Ptr, ProcPtr(fts5TriCreate)))))) Then
        local0 = CPtr(c2fb_TrigramTokenizer Ptr, arg1)
        If (-Cast(c2fb_c_int, ((local0->iFoldParam = Cast(c2fb_c_int, &O0ULL))))) Then
            Return IIf(local0->bFold, Cast(c2fb_c_int, 65ULL), Cast(c2fb_c_int, 66ULL))
        End If
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts5TokenizerPreload CDecl Alias "sqlite3Fts5TokenizerPreload" (ByVal arg0 As c2fb_Fts5TokenizerConfig Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_tokenize.c
' c2fb source-line: 1452
    Return ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->nArg >= Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(arg0->azArg[Cast(c2fb_c_int, &O0ULL)], StrPtr(!"trigram")))))) <> 0))))))
End Function
' Manual registration preserves SQLite's static tokenizer table and v2 porter ABI.
Function sqlite3Fts5TokenizerInit CDecl Alias "sqlite3Fts5TokenizerInit" (ByVal arg0 As c2fb_fts5_api Ptr) As c2fb_c_int
    Type BuiltinTokenizer
        zName As Const ZString Ptr
        x As c2fb_fts5_tokenizer_
    End Type

    Dim aBuiltin(0 To 2) As BuiltinTokenizer
    Dim sPorter As c2fb_fts5_tokenizer_v2_
    Dim rc As c2fb_c_int
    Dim i As c2fb_c_int

    aBuiltin(0).zName = StrPtr(!"unicode61")
    aBuiltin(0).x.xCreate = ProcPtr(fts5UnicodeCreate)
    aBuiltin(0).x.xDelete = ProcPtr(fts5UnicodeDelete)
    aBuiltin(0).x.xTokenize = ProcPtr(fts5UnicodeTokenize)

    aBuiltin(1).zName = StrPtr(!"ascii")
    aBuiltin(1).x.xCreate = ProcPtr(fts5AsciiCreate)
    aBuiltin(1).x.xDelete = ProcPtr(fts5AsciiDelete)
    aBuiltin(1).x.xTokenize = ProcPtr(fts5AsciiTokenize)

    aBuiltin(2).zName = StrPtr(!"trigram")
    aBuiltin(2).x.xCreate = ProcPtr(fts5TriCreate)
    aBuiltin(2).x.xDelete = ProcPtr(fts5TriDelete)
    aBuiltin(2).x.xTokenize = ProcPtr(fts5TriTokenize)

    rc = 0
    For i = 0 To UBound(aBuiltin)
        rc = arg0->xCreateTokenizer(arg0, aBuiltin(i).zName, arg0, _
            @aBuiltin(i).x, 0)
        If rc <> 0 Then Exit For
    Next

    If rc = 0 Then
        sPorter.iVersion = 2
        sPorter.xCreate = ProcPtr(fts5PorterCreate)
        sPorter.xDelete = ProcPtr(fts5PorterDelete)
        sPorter.xTokenize = ProcPtr(fts5PorterTokenize)
        rc = arg0->xCreateTokenizer_v2(arg0, StrPtr(!"porter"), arg0, _
            @sPorter, 0)
    End If

    Return rc
End Function
' c2fb body rename mappings:
' c2fb rename matched: aAsciiTokenChar -> c2fb_aAsciiTokenChar
' c2fb rename matched: sqlite3Utf8Trans1 -> c2fb_sqlite3Utf8Trans1
#endif

/' end of sqlite3_bulk_fts5_tokenize.bas '/
