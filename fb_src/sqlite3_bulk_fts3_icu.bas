/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_icu.bas

    Purpose:

        Port the ICU-backed FTS3 tokenizer from ext/fts3/fts3_icu.c.

    Responsibilities:

        - Fold UTF-8 input into ICU's UTF-16 word-break representation.
        - Preserve byte offsets from the original UTF-8 input.
        - Convert ICU word ranges back to UTF-8 tokenizer output.
        - Expose the tokenizer module to the FTS3 tokenizer registry.

    This file intentionally does NOT contain:

        - ICU's Unicode or word-break data tables.
        - FTS3 tokenizer registration policy.
        - Tokenizer-inspection test support.
'/ 

/'
** SQLite's blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
'/ 

#lang "fb"
#if defined(SQLITE_ENABLE_ICU) AndAlso _
    (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

#include once "sqlite3_api_declarations.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_fts3_tokenizer_types.bi"
#include once "build/generated/sqlite3_icu_api.bi"

Const ICU_ZERO_ERROR As SQLITE_C_INT = 0
Const ICU_BUFFER_OVERFLOW_ERROR As SQLITE_C_INT = 15
Const ICU_FOLD_CASE_DEFAULT As SQLITE_C_UINT = 0
Const ICU_BREAK_WORD As SQLITE_C_INT = 1
Const ICU_BREAK_DONE As SQLITE_C_INT = -1

Private Type IcuTokenizer
    base As Fts3Tokenizer
    zLocale As ZString Ptr
End Type

Private Type IcuCursor
    base As Fts3TokenizerCursor
    pIter As Any Ptr
    nChar As SQLITE_C_INT
    aChar As UShort Ptr
    aOffset As SQLITE_C_INT Ptr
    nBuffer As SQLITE_C_INT
    zBuffer As ZString Ptr
    iToken As SQLITE_C_INT
End Type

Extern "C"
    Declare Function icuTokenizerMemset CDecl Alias "memset" ( _
        ByVal pDestination As Any Ptr, _
        ByVal value As SQLITE_C_INT, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
    Declare Function icuTokenizerMemcpy CDecl Alias "memcpy" ( _
        ByVal pDestination As Any Ptr, _
        ByVal pSource As Const Any Ptr, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
    Declare Function icuTokenizerStrlen CDecl Alias "strlen" ( _
        ByVal zText As Const ZString Ptr _
    ) As SQLITE_SIZE_T
    Declare Function sqlite3Strlen30 CDecl Alias "sqlite3Strlen30" ( _
        ByVal zText As Const ZString Ptr _
    ) As SQLITE_C_INT
End Extern

Private Function icuDecodeUtf8( _
    ByVal pInput As Const UByte Ptr, _
    ByRef inputIndex As SQLITE_C_INT, _
    ByVal inputBytes As SQLITE_C_INT _
) As SQLITE_C_INT
    If pInput = 0 OrElse inputIndex < 0 OrElse inputIndex >= inputBytes Then _
        Return -1

    Dim leadByte As SQLITE_C_INT = pInput[inputIndex]
    inputIndex += 1
    If leadByte < &H80 Then Return leadByte

    Dim continuationCount As SQLITE_C_INT
    Dim codepoint As SQLITE_C_INT
    Dim minimumCodepoint As SQLITE_C_INT
    If leadByte >= &HC2 AndAlso leadByte <= &HDF Then
        continuationCount = 1
        codepoint = leadByte And &H1F
        minimumCodepoint = &H80
    ElseIf leadByte >= &HE0 AndAlso leadByte <= &HEF Then
        continuationCount = 2
        codepoint = leadByte And &HF
        minimumCodepoint = &H800
    ElseIf leadByte >= &HF0 AndAlso leadByte <= &HF4 Then
        continuationCount = 3
        codepoint = leadByte And &H7
        minimumCodepoint = &H10000
    Else
        Return -1
    End If

    If inputIndex > inputBytes - continuationCount Then Return -1

    For continuationIndex As SQLITE_C_INT = 0 To continuationCount - 1
        Dim continuationByte As SQLITE_C_INT = pInput[inputIndex]
        If (continuationByte And &HC0) <> &H80 Then Return -1
        inputIndex += 1
        codepoint = (codepoint Shl 6) Or (continuationByte And &H3F)
    Next

    If codepoint < minimumCodepoint OrElse _
       codepoint > &H10FFFF OrElse _
       (codepoint >= &HD800 AndAlso codepoint <= &HDFFF) Then
        Return -1
    End If

    Return codepoint
End Function

Private Function icuAppendUtf16( _
    ByVal pOutput As UShort Ptr, _
    ByRef outputIndex As SQLITE_C_INT, _
    ByVal outputCapacity As SQLITE_C_INT, _
    ByVal codepoint As SQLITE_C_INT _
) As SQLITE_C_INT
    If pOutput = 0 OrElse outputIndex < 0 OrElse outputIndex >= outputCapacity Then _
        Return 0

    If codepoint <= &HFFFF Then
        pOutput[outputIndex] = CUInt(codepoint)
        outputIndex += 1
        Return 1
    End If

    If codepoint > &H10FFFF OrElse outputIndex + 1 >= outputCapacity Then _
        Return 0

    Dim supplementaryCodepoint As SQLITE_C_INT = codepoint - &H10000
    pOutput[outputIndex] = CUInt(&HD800 Or (supplementaryCodepoint Shr 10))
    pOutput[outputIndex + 1] = CUInt(&HDC00 Or (supplementaryCodepoint And &H3FF))
    outputIndex += 2
    Return 1
End Function

Private Function icuDecodeUtf16( _
    ByVal pInput As Const UShort Ptr, _
    ByRef inputIndex As SQLITE_C_INT, _
    ByVal inputUnits As SQLITE_C_INT _
) As SQLITE_C_INT
    If pInput = 0 OrElse inputIndex < 0 OrElse inputIndex >= inputUnits Then _
        Return -1

    Dim firstUnit As SQLITE_C_INT = pInput[inputIndex]
    inputIndex += 1
    If firstUnit < &HD800 OrElse firstUnit > &HDBFF OrElse _
       inputIndex >= inputUnits Then
        Return firstUnit
    End If

    Dim secondUnit As SQLITE_C_INT = pInput[inputIndex]
    If secondUnit < &HDC00 OrElse secondUnit > &HDFFF Then Return firstUnit

    inputIndex += 1
    Return &H10000 + ((firstUnit - &HD800) Shl 10) + (secondUnit - &HDC00)
End Function

Private Function icuCreate CDecl Alias "icuCreate" ( _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal arguments As Const ZString Ptr Ptr, _
    ByVal ppTokenizer As Fts3Tokenizer Ptr Ptr _
) As SQLITE_C_INT
    If ppTokenizer = 0 Then Return SQLITE_MISUSE
    ppTokenizer[0] = 0

    Dim localeBytes As SQLITE_SIZE_T = 0
    If argumentCount > 0 Then
        If arguments = 0 OrElse arguments[0] = 0 Then Return SQLITE_MISUSE
        localeBytes = icuTokenizerStrlen(arguments[0]) + 1
    End If

    If localeBytes > &H7FFFFFFF - SizeOf(IcuTokenizer) Then Return SQLITE_TOOBIG

    Dim allocationBytes As sqlite3_uint64 = _
        Cast(sqlite3_uint64, SizeOf(IcuTokenizer)) + Cast(sqlite3_uint64, localeBytes)
    Dim pTokenizer As IcuTokenizer Ptr = CPtr( _
        IcuTokenizer Ptr, sqlite3_malloc64(allocationBytes))
    If pTokenizer = 0 Then Return SQLITE_NOMEM

    icuTokenizerMemset(pTokenizer, 0, SizeOf(IcuTokenizer))
    If localeBytes > 0 Then
        pTokenizer->zLocale = CPtr( _
            ZString Ptr, CPtr(UByte Ptr, pTokenizer) + SizeOf(IcuTokenizer))
        icuTokenizerMemcpy(pTokenizer->zLocale, arguments[0], localeBytes)
    End If

    ppTokenizer[0] = CPtr(Fts3Tokenizer Ptr, pTokenizer)
    Return SQLITE_OK
End Function

Private Function icuDestroy CDecl Alias "icuDestroy" ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr _
) As SQLITE_C_INT
    sqlite3_free(pTokenizer)
    Return SQLITE_OK
End Function

Private Function icuOpen CDecl Alias "icuOpen" ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr, _
    ByVal zInput As Const ZString Ptr, _
    ByVal inputBytes As SQLITE_C_INT, _
    ByVal ppCursor As Fts3TokenizerCursor Ptr Ptr _
) As SQLITE_C_INT
    If pTokenizer = 0 OrElse ppCursor = 0 Then Return SQLITE_MISUSE
    ppCursor[0] = 0

    Dim pInputString As Const ZString Ptr = zInput
    Dim byteCount As SQLITE_C_INT = inputBytes
    If pInputString = 0 Then
        pInputString = StrPtr("")
        byteCount = 0
    ElseIf byteCount < 0 Then
        Dim inputSize As SQLITE_SIZE_T = icuTokenizerStrlen(pInputString)
        If inputSize > &H7FFFFFFB Then Return SQLITE_TOOBIG
        byteCount = Cast(SQLITE_C_INT, inputSize)
    End If

    If byteCount < 0 OrElse byteCount > &H7FFFFFFB Then Return SQLITE_TOOBIG
    Dim characterCapacity As SQLITE_C_INT = byteCount + 1
    Dim paddedCharacterCapacity As SQLITE_C_INT = _
        (characterCapacity + 3) And &H7FFFFFFC

    Dim allocationBytes As sqlite3_uint64 = _
        Cast(sqlite3_uint64, SizeOf(IcuCursor)) + _
        Cast(sqlite3_uint64, paddedCharacterCapacity) * SizeOf(UShort) + _
        Cast(sqlite3_uint64, characterCapacity + 1) * SizeOf(SQLITE_C_INT)
    Dim pCursor As IcuCursor Ptr = CPtr( _
        IcuCursor Ptr, sqlite3_malloc64(allocationBytes))
    If pCursor = 0 Then Return SQLITE_NOMEM

    icuTokenizerMemset(pCursor, 0, SizeOf(IcuCursor))
    pCursor->aChar = CPtr( _
        UShort Ptr, CPtr(UByte Ptr, pCursor) + SizeOf(IcuCursor))
    pCursor->aOffset = CPtr( _
        SQLITE_C_INT Ptr, _
        CPtr(UByte Ptr, pCursor->aChar) + _
            Cast(SQLITE_SIZE_T, paddedCharacterCapacity) * SizeOf(UShort))

    Dim inputIndex As SQLITE_C_INT = 0
    Dim outputIndex As SQLITE_C_INT = 0
    pCursor->aOffset[0] = 0
    Dim codepoint As SQLITE_C_INT = icuDecodeUtf8( _
        CPtr(Const UByte Ptr, pInputString), inputIndex, byteCount)
    While codepoint > 0
        codepoint = icuUFoldCase(codepoint, ICU_FOLD_CASE_DEFAULT)
        If icuAppendUtf16(pCursor->aChar, outputIndex, characterCapacity, codepoint) = 0 Then
            sqlite3_free(pCursor)
            Return SQLITE_ERROR
        End If
        pCursor->aOffset[outputIndex] = inputIndex

        If inputIndex < byteCount Then
            codepoint = icuDecodeUtf8( _
                CPtr(Const UByte Ptr, pInputString), inputIndex, byteCount)
        Else
            codepoint = 0
        End If
    Wend

    Dim status As SQLITE_C_INT = ICU_ZERO_ERROR
    Dim pIcuTokenizer As IcuTokenizer Ptr = CPtr(IcuTokenizer Ptr, pTokenizer)
    pCursor->pIter = icuUbrkOpen( _
        ICU_BREAK_WORD, pIcuTokenizer->zLocale, pCursor->aChar, outputIndex, @status)
    If status > ICU_ZERO_ERROR OrElse pCursor->pIter = 0 Then
        sqlite3_free(pCursor)
        Return SQLITE_ERROR
    End If

    pCursor->nChar = outputIndex
    icuUbrkFirst(pCursor->pIter)
    ppCursor[0] = CPtr(Fts3TokenizerCursor Ptr, pCursor)
    Return SQLITE_OK
End Function

Private Function icuClose CDecl Alias "icuClose" ( _
    ByVal pBaseCursor As Fts3TokenizerCursor Ptr _
) As SQLITE_C_INT
    If pBaseCursor = 0 Then Return SQLITE_MISUSE
    Dim pCursor As IcuCursor Ptr = CPtr(IcuCursor Ptr, pBaseCursor)
    If pCursor->pIter <> 0 Then icuUbrkClose(pCursor->pIter)
    sqlite3_free(pCursor->zBuffer)
    sqlite3_free(pCursor)
    Return SQLITE_OK
End Function

Private Function icuNext CDecl Alias "icuNext" ( _
    ByVal pBaseCursor As Fts3TokenizerCursor Ptr, _
    ByVal ppToken As Const ZString Ptr Ptr, _
    ByVal pTokenBytes As SQLITE_C_INT Ptr, _
    ByVal pStartOffset As SQLITE_C_INT Ptr, _
    ByVal pEndOffset As SQLITE_C_INT Ptr, _
    ByVal pPosition As SQLITE_C_INT Ptr _
) As SQLITE_C_INT
    If pBaseCursor = 0 OrElse ppToken = 0 OrElse pTokenBytes = 0 OrElse _
       pStartOffset = 0 OrElse pEndOffset = 0 OrElse pPosition = 0 Then _
        Return SQLITE_MISUSE

    Dim pCursor As IcuCursor Ptr = CPtr(IcuCursor Ptr, pBaseCursor)
    If pCursor->pIter = 0 Then Return SQLITE_ERROR

    Dim startIndex As SQLITE_C_INT = 0
    Dim endIndex As SQLITE_C_INT = 0
    Dim tokenBytes As SQLITE_C_INT = 0
    Do
        startIndex = icuUbrkCurrent(pCursor->pIter)
        endIndex = icuUbrkNext(pCursor->pIter)
        If endIndex = ICU_BREAK_DONE Then Return SQLITE_DONE
        If startIndex < 0 OrElse endIndex < startIndex OrElse _
           endIndex > pCursor->nChar Then Return SQLITE_ERROR

        While startIndex < endIndex
            Dim whitespaceIndex As SQLITE_C_INT = startIndex
            Dim codepoint As SQLITE_C_INT = icuDecodeUtf16( _
                pCursor->aChar, whitespaceIndex, pCursor->nChar)
            If icuUIsSpace(codepoint) = 0 Then Exit While
            startIndex = whitespaceIndex
        Wend
    Loop While startIndex = endIndex

    Dim status As SQLITE_C_INT
    Do
        status = ICU_ZERO_ERROR
        If tokenBytes > 0 Then
            Dim pNewBuffer As ZString Ptr = CPtr( _
                ZString Ptr, sqlite3_realloc(pCursor->zBuffer, tokenBytes))
            If pNewBuffer = 0 Then Return SQLITE_NOMEM
            pCursor->zBuffer = pNewBuffer
            pCursor->nBuffer = tokenBytes
        End If

        icuUToUtf8( _
            pCursor->zBuffer, pCursor->nBuffer, @tokenBytes, _
            @pCursor->aChar[startIndex], endIndex - startIndex, @status)
        If status > ICU_ZERO_ERROR AndAlso _
           status <> ICU_BUFFER_OVERFLOW_ERROR Then Return SQLITE_ERROR
        If status = ICU_BUFFER_OVERFLOW_ERROR AndAlso _
           tokenBytes <= pCursor->nBuffer Then Return SQLITE_ERROR
    Loop While tokenBytes > pCursor->nBuffer

    If startIndex >= pCursor->nChar OrElse endIndex > pCursor->nChar Then _
        Return SQLITE_ERROR

    ppToken[0] = pCursor->zBuffer
    pTokenBytes[0] = tokenBytes
    pStartOffset[0] = pCursor->aOffset[startIndex]
    pEndOffset[0] = pCursor->aOffset[endIndex]
    pPosition[0] = pCursor->iToken
    pCursor->iToken += 1
    Return SQLITE_OK
End Function

/' ------------------------------------------------------------------------- '/
/' ICU tokenizer module                                                    '/
/' ------------------------------------------------------------------------- '/
Private Dim Shared As Const Fts3TokenizerModule icuTokenizerModule = _
    Type<Fts3TokenizerModule>( _
        0, _
        Cast(Fts3TokenizerCreateProc, ProcPtr(icuCreate)), _
        Cast(Fts3TokenizerDestroyProc, ProcPtr(icuDestroy)), _
        Cast(Fts3TokenizerOpenProc, ProcPtr(icuOpen)), _
        Cast(Fts3TokenizerCloseProc, ProcPtr(icuClose)), _
        Cast(Fts3TokenizerNextProc, ProcPtr(icuNext)), _
        Cast(Fts3TokenizerLanguageidProc, 0) _
    )

Sub sqlite3Fts3IcuTokenizerModule CDecl Alias "sqlite3Fts3IcuTokenizerModule" ( _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr _
)
    If ppModule <> 0 Then *ppModule = @icuTokenizerModule
End Sub

#endif

/' end of sqlite3_bulk_fts3_icu.bas '/
