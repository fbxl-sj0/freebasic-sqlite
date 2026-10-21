/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_ext_icu.bas

    Purpose:

        Integrate ICU case mapping, regular expressions, LIKE matching, and
        collation sequences with SQLite connections.

    Responsibilities:

        - Register ICU SQL functions in profiles that enable the extension.
        - Preserve UTF-8 pattern matching and UTF-16 ICU text handling.
        - Own ICU regex and collation objects through SQLite destructors.

    This file intentionally does NOT contain:

        - The FTS3 ICU tokenizer, which is implemented separately.
        - ICU's Unicode, regular-expression, or collation data tables.
        - Test-runner commands or test cases.
'/ 

#lang "fb"
#if defined(SQLITE_ENABLE_ICU) OrElse defined(SQLITE_ENABLE_ICU_COLLATIONS)

#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_api_constants.bi"
#include once "sqlite3_api_declarations.bi"
#include once "build/generated/sqlite3_icu_api.bi"

Private Const ICU_ZERO_ERROR As SQLITE_C_INT = 0
Private Const ICU_BUFFER_OVERFLOW_ERROR As SQLITE_C_INT = 15
Private Const ICU_FOLD_CASE_DEFAULT As SQLITE_C_UINT = 0

' Values are the stable ICU enum values from unicode/ucol.h.
Private Const ICU_COL_LESS As SQLITE_C_INT = -1
Private Const ICU_COL_EQUAL As SQLITE_C_INT = 0
Private Const ICU_COL_GREATER As SQLITE_C_INT = 1
Private Const ICU_COL_PRIMARY As SQLITE_C_INT = 0
Private Const ICU_COL_SECONDARY As SQLITE_C_INT = 1
Private Const ICU_COL_TERTIARY As SQLITE_C_INT = 2
Private Const ICU_COL_QUATERNARY As SQLITE_C_INT = 3
Private Const ICU_COL_IDENTICAL As SQLITE_C_INT = 15
Private Dim Shared icuEmptyUtf16Text As UShort = 0

' SQLite's default pattern bound prevents unbounded recursion and quadratic LIKE work.
#ifndef SQLITE_MAX_LIKE_PATTERN_LENGTH
#define SQLITE_MAX_LIKE_PATTERN_LENGTH 50000
#endif

/' ------------------------------------------------------------------------- '/
/' ICU status and error reporting '/
/' ------------------------------------------------------------------------- '/

Private Function icuStatusSucceeded(ByVal status As SQLITE_C_INT) As SQLITE_C_INT
    Return IIf(status <= ICU_ZERO_ERROR, 1, 0)
End Function

Private Sub icuFunctionError( _
    ByVal pContext As Any Ptr, _
    ByVal zFunction As Const ZString Ptr, _
    ByVal status As SQLITE_C_INT _
)
    Dim message(0 To 127) As UByte
    sqlite3_snprintf(128, Cast(ZString Ptr, @message(0)), _
                     StrPtr(!"ICU error: %s(): %s"), _
                     zFunction, icuUErrorName(status))
    message(127) = 0
    sqlite3_result_error(pContext, Cast(Const ZString Ptr, @message(0)), -1)
End Sub

#ifdef SQLITE_ENABLE_ICU

/' ------------------------------------------------------------------------- '/
/' UTF-8 LIKE matching, regular expressions, and case mapping '/
/' ------------------------------------------------------------------------- '/

Private Sub icuFree CDecl(ByVal pAllocation As Any Ptr)
    sqlite3_free(pAllocation)
End Sub

Private Function icuReadUtf8( _
    ByVal pInput As Const UByte Ptr, _
    ByRef inputIndex As SQLITE_C_INT, _
    ByVal inputBytes As SQLITE_C_INT _
) As SQLITE_C_INT
    If pInput = 0 OrElse inputIndex < 0 OrElse inputIndex >= inputBytes Then _
        Return 0

    Dim leadByte As SQLITE_C_INT = pInput[inputIndex]
    inputIndex += 1
    If leadByte < &HC0 Then Return leadByte

    Dim codepoint As SQLITE_C_INT
    If leadByte < &HE0 Then
        codepoint = leadByte And &H1F
    ElseIf leadByte < &HF0 Then
        codepoint = leadByte And &HF
    ElseIf leadByte < &HF8 Then
        codepoint = leadByte And &H07
    Else
        codepoint = 0
    End If

    While inputIndex < inputBytes
        Dim nextByte As SQLITE_C_INT = pInput[inputIndex]
        If (nextByte And &HC0) <> &H80 Then Exit While
        codepoint = (codepoint Shl 6) + (nextByte And &H3F)
        inputIndex += 1
    Wend

    ' SQLite's original decoder replaces overlong, surrogate, and terminal
    ' noncharacter values before passing them to ICU's case-folding routine.
    If codepoint < &H80 OrElse _
       (codepoint And &HFFFFF800) = &HD800 OrElse _
       (codepoint And &HFFFFFFFE) = &HFFFE Then
        codepoint = &HFFFD
    End If
    Return codepoint
End Function

Private Sub icuSkipUtf8( _
    ByVal pInput As Const UByte Ptr, _
    ByRef inputIndex As SQLITE_C_INT, _
    ByVal inputBytes As SQLITE_C_INT _
)
    If pInput = 0 OrElse inputIndex < 0 OrElse inputIndex >= inputBytes Then Return
    Dim leadByte As SQLITE_C_INT = pInput[inputIndex]
    inputIndex += 1
    If leadByte >= &HC0 Then
        While inputIndex < inputBytes AndAlso _
              (pInput[inputIndex] And &HC0) = &H80
            inputIndex += 1
        Wend
    End If
End Sub

Private Function icuLikeCompare( _
    ByVal pPattern As Const UByte Ptr, _
    ByVal patternBytes As SQLITE_C_INT, _
    ByVal pString As Const UByte Ptr, _
    ByVal stringBytes As SQLITE_C_INT, _
    ByVal escapeCharacter As SQLITE_C_INT _
) As SQLITE_C_INT
    Const MATCH_ONE As SQLITE_C_INT = Asc("_")
    Const MATCH_ALL As SQLITE_C_INT = Asc("%")
    Dim patternIndex As SQLITE_C_INT = 0
    Dim stringIndex As SQLITE_C_INT = 0
    Dim previousWasEscape As SQLITE_C_INT = 0

    While patternIndex < patternBytes
        Dim patternCharacter As SQLITE_C_INT = _
            icuReadUtf8(pPattern, patternIndex, patternBytes)
        If patternCharacter = 0 Then Exit While

        If patternCharacter = MATCH_ALL AndAlso previousWasEscape = 0 AndAlso _
           patternCharacter <> escapeCharacter Then
            While patternIndex < patternBytes
                Dim nextByte As SQLITE_C_INT = pPattern[patternIndex]
                If nextByte <> MATCH_ALL AndAlso nextByte <> MATCH_ONE Then Exit While
                If nextByte = MATCH_ONE Then
                    If stringIndex >= stringBytes OrElse pString[stringIndex] = 0 Then _
                        Return 0
                    icuSkipUtf8(pString, stringIndex, stringBytes)
                End If
                patternIndex += 1
            Wend

            If patternIndex >= patternBytes OrElse pPattern[patternIndex] = 0 Then _
                Return 1

            While stringIndex < stringBytes AndAlso pString[stringIndex] <> 0
                If icuLikeCompare(@pPattern[patternIndex], _
                                  patternBytes - patternIndex, _
                                  @pString[stringIndex], _
                                  stringBytes - stringIndex, _
                                  escapeCharacter) <> 0 Then
                    Return 1
                End If
                icuSkipUtf8(pString, stringIndex, stringBytes)
            Wend
            Return 0
        ElseIf patternCharacter = MATCH_ONE AndAlso previousWasEscape = 0 AndAlso _
               patternCharacter <> escapeCharacter Then
            If stringIndex >= stringBytes OrElse pString[stringIndex] = 0 Then Return 0
            icuSkipUtf8(pString, stringIndex, stringBytes)
        ElseIf patternCharacter = escapeCharacter AndAlso previousWasEscape = 0 Then
            previousWasEscape = 1
        Else
            Dim stringCharacter As SQLITE_C_INT = _
                icuReadUtf8(pString, stringIndex, stringBytes)
            stringCharacter = icuUFoldCase(stringCharacter, ICU_FOLD_CASE_DEFAULT)
            patternCharacter = icuUFoldCase(patternCharacter, ICU_FOLD_CASE_DEFAULT)
            If stringCharacter <> patternCharacter Then Return 0
            previousWasEscape = 0
        End If
    Wend

    If stringIndex >= stringBytes Then Return 1
    Return IIf(pString[stringIndex] = 0, 1, 0)
End Function

Private Sub icuLikeFunc CDecl( _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal pValues As Any Ptr Ptr _
)
    Dim pPattern As Const UByte Ptr = sqlite3_value_text(pValues[0])
    Dim pString As Const UByte Ptr = sqlite3_value_text(pValues[1])
    Dim patternBytes As SQLITE_C_INT = sqlite3_value_bytes(pValues[0])
    Dim stringBytes As SQLITE_C_INT = sqlite3_value_bytes(pValues[1])
    Dim escapeCharacter As SQLITE_C_INT = 0

    If patternBytes > SQLITE_MAX_LIKE_PATTERN_LENGTH Then
        sqlite3_result_error(pContext, StrPtr(!"LIKE or GLOB pattern too complex"), -1)
        Return
    End If

    If argumentCount = 3 Then
        Dim pEscape As Const UByte Ptr = sqlite3_value_text(pValues[2])
        Dim escapeBytes As SQLITE_C_INT = sqlite3_value_bytes(pValues[2])
        If pEscape = 0 Then Return
        If escapeBytes = 0 Then
            sqlite3_result_error(pContext, _
                StrPtr(!"ESCAPE expression must be a single character"), -1)
            Return
        End If
        Dim escapeIndex As SQLITE_C_INT = 0
        escapeCharacter = icuReadUtf8(pEscape, escapeIndex, escapeBytes)
        If escapeIndex <> escapeBytes Then
            sqlite3_result_error(pContext, _
                StrPtr(!"ESCAPE expression must be a single character"), -1)
            Return
        End If
    End If

    If pPattern <> 0 AndAlso pString <> 0 Then
        sqlite3_result_int(pContext, _
            icuLikeCompare(pPattern, patternBytes, pString, stringBytes, escapeCharacter))
    End If
End Sub

Private Sub icuRegexpDelete CDecl(ByVal pExpression As Any Ptr)
    ' SQLite auxdata owns each compiled expression until its SQL function is reset.
    If pExpression <> 0 Then icuURegexClose(pExpression)
End Sub

Private Sub icuRegexpFunc CDecl( _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal pValues As Any Ptr Ptr _
)
    ' SQLite's REGEXP operator calls regexp(pattern, value); the pattern stays
    ' in auxdata so repeated rows do not recompile the ICU expression.
    Dim status As SQLITE_C_INT = ICU_ZERO_ERROR
    Dim pRegexp As Any Ptr = sqlite3_get_auxdata(pContext, 0)
    Dim pString As Const UShort Ptr = _
        Cast(Const UShort Ptr, sqlite3_value_text16(pValues[1]))
    If pString = 0 Then Return

    If pRegexp = 0 Then
        Dim pPattern As Const UShort Ptr = _
            Cast(Const UShort Ptr, sqlite3_value_text16(pValues[0]))
        If pPattern = 0 Then Return
        pRegexp = icuURegexOpen(pPattern, -1, 0, 0, @status)
        If icuStatusSucceeded(status) Then
            sqlite3_set_auxdata(pContext, 0, pRegexp, ProcPtr(icuRegexpDelete))
            pRegexp = sqlite3_get_auxdata(pContext, 0)
        End If
        If pRegexp = 0 Then
            icuFunctionError(pContext, StrPtr(!"uregex_open"), status)
            Return
        End If
    End If

    icuURegexSetText(pRegexp, pString, -1, @status)
    If icuStatusSucceeded(status) = 0 Then
        icuFunctionError(pContext, StrPtr(!"uregex_setText"), status)
        Return
    End If

    Dim matched As SQLITE_C_INT = icuURegexMatches(pRegexp, 0, @status)
    If icuStatusSucceeded(status) = 0 Then
        icuFunctionError(pContext, StrPtr(!"uregex_matches"), status)
        Return
    End If

    ' Do not leave ICU pointing at SQLite-owned text after this callback.
    icuURegexSetText(pRegexp, 0, 0, @status)
    sqlite3_result_int(pContext, IIf(matched <> 0, 1, 0))
End Sub

Private Sub icuCaseFunc16 CDecl( _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal pValues As Any Ptr Ptr _
)
    Dim pInput As Const UShort Ptr = _
        Cast(Const UShort Ptr, sqlite3_value_text16(pValues[0]))
    If pInput = 0 Then Return

    Dim inputBytes As SQLITE_C_INT = sqlite3_value_bytes16(pValues[0])
    If inputBytes = 0 Then
        ' SQLITE_STATIC requires storage that remains valid after this callback.
        sqlite3_result_text16(pContext, @icuEmptyUtf16Text, 0, 0)
        Return
    End If

    Dim pOutput As Any Ptr = 0
    Dim outputBytes As sqlite3_int64 = inputBytes
    Dim toUpper As SQLITE_C_INT = IIf(sqlite3_user_data(pContext) <> 0, 1, 0)
    Dim pLocale As Const ZString Ptr = 0
    If argumentCount = 2 Then pLocale = sqlite3_value_text(pValues[1])

    For retryIndex As SQLITE_C_INT = 0 To 1
        Dim pNewOutput As Any Ptr = _
            sqlite3_realloc64(pOutput, Cast(SQLITE_SIZE_T, outputBytes))
        If pNewOutput = 0 Then
            sqlite3_free(pOutput)
            sqlite3_result_error_nomem(pContext)
            Return
        End If
        pOutput = pNewOutput

        Dim status As SQLITE_C_INT = ICU_ZERO_ERROR
        Dim outputUnits As SQLITE_C_INT
        If toUpper <> 0 Then
            outputUnits = icuUToUpper( _
                Cast(UShort Ptr, pOutput), Cast(SQLITE_C_INT, outputBytes \ 2), _
                pInput, inputBytes \ 2, pLocale, @status)
        Else
            outputUnits = icuUToLower( _
                Cast(UShort Ptr, pOutput), Cast(SQLITE_C_INT, outputBytes \ 2), _
                pInput, inputBytes \ 2, pLocale, @status)
        End If

        If icuStatusSucceeded(status) <> 0 Then
            outputBytes = Cast(sqlite3_int64, outputUnits) * 2
            If outputBytes > &H7FFFFFFF Then
                sqlite3_free(pOutput)
                sqlite3_result_error_toobig(pContext)
                Return
            End If
            sqlite3_result_text16(pContext, pOutput, Cast(SQLITE_C_INT, outputBytes), _
                                  ProcPtr(icuFree))
            Return
        ElseIf status = ICU_BUFFER_OVERFLOW_ERROR AndAlso retryIndex = 0 Then
            outputBytes = Cast(sqlite3_int64, outputUnits) * 2
        ElseIf status = ICU_BUFFER_OVERFLOW_ERROR Then
            sqlite3_free(pOutput)
            sqlite3_result_error_toobig(pContext)
            Return
        Else
            sqlite3_free(pOutput)
            icuFunctionError(pContext, _
                IIf(toUpper <> 0, StrPtr(!"u_strToUpper"), StrPtr(!"u_strToLower")), _
                status)
            Return
        End If
    Next
End Sub

#endif

/' ------------------------------------------------------------------------- '/
/' Locale-aware ICU collations '/
/' ------------------------------------------------------------------------- '/

Private Sub icuCollationDelete CDecl(ByVal pCollator As Any Ptr)
    If pCollator <> 0 Then icuUColClose(pCollator)
End Sub

Private Function icuCollationCompare CDecl( _
    ByVal pCollator As Any Ptr, _
    ByVal leftBytes As SQLITE_C_INT, _
    ByVal pLeft As Const Any Ptr, _
    ByVal rightBytes As SQLITE_C_INT, _
    ByVal pRight As Const Any Ptr _
) As SQLITE_C_INT
    If pCollator = 0 Then Return 0
    Dim comparison As SQLITE_C_INT = icuUColStrcoll( _
        pCollator, Cast(Const UShort Ptr, pLeft), leftBytes \ 2, _
        Cast(Const UShort Ptr, pRight), rightBytes \ 2)
    Select Case comparison
        Case ICU_COL_LESS
            Return -1
        Case ICU_COL_GREATER
            Return 1
        Case ICU_COL_EQUAL
            Return 0
        Case Else
            Return 0
    End Select
End Function

Private Sub icuLoadCollation CDecl( _
    ByVal pContext As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal pValues As Any Ptr Ptr _
)
    Dim pDatabase As Any Ptr = sqlite3_user_data(pContext)
    Dim status As SQLITE_C_INT = ICU_ZERO_ERROR
    Dim pLocale As Const ZString Ptr = sqlite3_value_text(pValues[0])
    Dim pName As Const ZString Ptr = sqlite3_value_text(pValues[1])
    If pLocale = 0 OrElse pName = 0 Then Return

    Dim pCollator As Any Ptr = icuUColOpen(pLocale, @status)
    If icuStatusSucceeded(status) = 0 Then
        icuFunctionError(pContext, StrPtr(!"ucol_open"), status)
        Return
    End If
    If pCollator = 0 Then
        sqlite3_result_error_nomem(pContext)
        Return
    End If

    If argumentCount = 3 Then
        Dim pOption As Const ZString Ptr = sqlite3_value_text(pValues[2])
        If pOption = 0 Then
            icuUColClose(pCollator)
            Return
        End If

        Dim strengthValue As SQLITE_C_INT = -1
        If sqlite3_stricmp(pOption, StrPtr(!"PRIMARY")) = 0 Then
            strengthValue = ICU_COL_PRIMARY
        ElseIf sqlite3_stricmp(pOption, StrPtr(!"SECONDARY")) = 0 Then
            strengthValue = ICU_COL_SECONDARY
        ElseIf sqlite3_stricmp(pOption, StrPtr(!"TERTIARY")) = 0 OrElse _
               sqlite3_stricmp(pOption, StrPtr(!"DEFAULT")) = 0 Then
            strengthValue = ICU_COL_TERTIARY
        ElseIf sqlite3_stricmp(pOption, StrPtr(!"QUARTERNARY")) = 0 Then
            strengthValue = ICU_COL_QUATERNARY
        ElseIf sqlite3_stricmp(pOption, StrPtr(!"IDENTICAL")) = 0 Then
            strengthValue = ICU_COL_IDENTICAL
        End If

        If strengthValue < 0 Then
            Dim pMessage As Any Ptr = sqlite3_str_new(pDatabase)
            If pMessage = 0 Then
                icuUColClose(pCollator)
                sqlite3_result_error_nomem(pContext)
                Return
            End If
            sqlite3_str_appendf(pMessage, _
                StrPtr(!"unknown collation strength \"%s\" - should be one of:"), pOption)
            sqlite3_str_appendf(pMessage, StrPtr(!" %s"), StrPtr(!"PRIMARY"))
            sqlite3_str_appendf(pMessage, StrPtr(!" %s"), StrPtr(!"SECONDARY"))
            sqlite3_str_appendf(pMessage, StrPtr(!" %s"), StrPtr(!"TERTIARY"))
            sqlite3_str_appendf(pMessage, StrPtr(!" %s"), StrPtr(!"DEFAULT"))
            sqlite3_str_appendf(pMessage, StrPtr(!" %s"), StrPtr(!"QUARTERNARY"))
            sqlite3_str_appendf(pMessage, StrPtr(!" %s"), StrPtr(!"IDENTICAL"))
            sqlite3_result_error(pContext, sqlite3_str_value(pMessage), -1)
            sqlite3_free(sqlite3_str_finish(pMessage))
            icuUColClose(pCollator)
            Return
        End If
        icuUColSetStrength(pCollator, strengthValue)
    End If

    Dim rc As SQLITE_C_INT = sqlite3_create_collation_v2( _
        pDatabase, pName, SQLITE_UTF16, pCollator, _
        ProcPtr(icuCollationCompare), ProcPtr(icuCollationDelete))
    If rc <> SQLITE_OK Then
        icuUColClose(pCollator)
        sqlite3_result_error(pContext, _
            StrPtr(!"Error registering collation function"), -1)
    End If
End Sub

/' ------------------------------------------------------------------------- '/
/' Register the ICU functions and collation loader '/
/' ------------------------------------------------------------------------- '/

Private Function icuRegisterFunction( _
    ByVal pDatabase As Any Ptr, _
    ByVal zName As Const ZString Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal encodingFlags As SQLITE_C_INT, _
    ByVal pUserData As Any Ptr, _
    ByVal xFunction As Any Ptr _
) As SQLITE_C_INT
    Return sqlite3_create_function(pDatabase, zName, argumentCount, encodingFlags, _
                                   pUserData, xFunction, 0, 0)
End Function

Function sqlite3IcuInit CDecl Alias "sqlite3IcuInit" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT Export
#if defined(SQLITE_ENABLE_ICU) OrElse defined(SQLITE_ENABLE_ICU_COLLATIONS)
    Dim rc As SQLITE_C_INT = SQLITE_OK

    rc = icuRegisterFunction(pDatabase, StrPtr(!"icu_load_collation"), 2, _
        SQLITE_UTF8 Or SQLITE_DIRECTONLY, pDatabase, ProcPtr(icuLoadCollation))
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"icu_load_collation"), 3, _
            SQLITE_UTF8 Or SQLITE_DIRECTONLY, pDatabase, ProcPtr(icuLoadCollation))
    End If

#ifdef SQLITE_ENABLE_ICU
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"regexp"), 2, _
            SQLITE_ANY Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, 0, _
            ProcPtr(icuRegexpFunc))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"lower"), 1, _
            SQLITE_UTF16 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, 0, _
            ProcPtr(icuCaseFunc16))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"lower"), 2, _
            SQLITE_UTF16 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, 0, _
            ProcPtr(icuCaseFunc16))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"upper"), 1, _
            SQLITE_UTF16 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, pDatabase, _
            ProcPtr(icuCaseFunc16))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"upper"), 2, _
            SQLITE_UTF16 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, pDatabase, _
            ProcPtr(icuCaseFunc16))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"lower"), 1, _
            SQLITE_UTF8 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, 0, _
            ProcPtr(icuCaseFunc16))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"lower"), 2, _
            SQLITE_UTF8 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, 0, _
            ProcPtr(icuCaseFunc16))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"upper"), 1, _
            SQLITE_UTF8 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, pDatabase, _
            ProcPtr(icuCaseFunc16))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"upper"), 2, _
            SQLITE_UTF8 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, pDatabase, _
            ProcPtr(icuCaseFunc16))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"like"), 2, _
            SQLITE_UTF8 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, 0, _
            ProcPtr(icuLikeFunc))
    End If
    If rc = SQLITE_OK Then
        rc = icuRegisterFunction(pDatabase, StrPtr(!"like"), 3, _
            SQLITE_UTF8 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, 0, _
            ProcPtr(icuLikeFunc))
    End If
#endif

    Return rc
#else
    Return SQLITE_OK
#endif
End Function

#endif

/' end of sqlite3_ext_icu.bas '/
