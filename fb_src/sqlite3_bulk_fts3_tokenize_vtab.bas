/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_tokenize_vtab.bas

    Purpose:

        Provide the FTS3 tokenizer-inspection virtual table and its built-in
        tokenizer registry.

    Responsibilities:

        - Register the fts3tokenize virtual-table module.
        - Connect the existing simple, Porter, and Unicode tokenizer ABIs.
        - Report token bytes, positions, and offsets through SQLite's vtab API.

    This file intentionally does NOT contain:

        - FTS3/FTS4 full-text table storage, planning, or query execution.
        - The fts3_tokenizer() SQL function or custom-tokenizer security policy.
'/

/'
** SQLite's blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
'/

#lang "fb"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_api_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_hash_types.bi"
#include once "sqlite3_vtab_types.bi"
#include once "sqlite3_fts3_hash_types.bi"
#include once "sqlite3_fts3_tokenizer_types.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)

Extern "C"
    Declare Function fts3tokMemcpy CDecl Alias "memcpy" ( _
        ByVal pDestination As Any Ptr, _
        ByVal pSource As Const Any Ptr, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
    Declare Function fts3tokMemset CDecl Alias "memset" ( _
        ByVal pDestination As Any Ptr, _
        ByVal value As SQLITE_C_INT, _
        ByVal byteCount As SQLITE_SIZE_T _
    ) As Any Ptr
End Extern

Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" ( _
    ByVal byteCount As sqlite3_uint64 _
) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal pMemory As Any Ptr)
Declare Function sqlite3_mprintf CDecl Alias "sqlite3_mprintf" ( _
    ByVal zFormat As Const ZString Ptr, ... _
) As ZString Ptr
Declare Function sqlite3Strlen30 CDecl Alias "sqlite3Strlen30" ( _
    ByVal zText As Const ZString Ptr _
) As SQLITE_C_INT
Declare Function sqlite3_declare_vtab CDecl Alias "sqlite3_declare_vtab" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal zSchema As Const ZString Ptr _
) As SQLITE_C_INT
Declare Function sqlite3_create_module_v2 CDecl Alias "sqlite3_create_module_v2" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal zName As Const ZString Ptr, _
    ByVal pModule As Const Any Ptr, _
    ByVal pAuxiliary As Any Ptr, _
    ByVal xDestroy As Any Ptr _
) As SQLITE_C_INT
Declare Function sqlite3Fts3InitHashTable CDecl Alias "sqlite3Fts3InitHashTable" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal pHash As Fts3Hash Ptr, _
    ByVal zFunctionName As Const ZString Ptr _
) As SQLITE_C_INT
Declare Function sqlite3_value_text CDecl Alias "sqlite3_value_text" ( _
    ByVal pValue As Any Ptr _
) As Const UByte Ptr
Declare Function sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" ( _
    ByVal pValue As Any Ptr _
) As SQLITE_C_INT
Declare Sub sqlite3_result_text CDecl Alias "sqlite3_result_text" ( _
    ByVal pContext As Any Ptr, _
    ByVal zText As Const ZString Ptr, _
    ByVal byteCount As SQLITE_C_INT, _
    ByVal xDestroy As Any Ptr _
)
Declare Sub sqlite3_result_int CDecl Alias "sqlite3_result_int" ( _
    ByVal pContext As Any Ptr, _
    ByVal value As SQLITE_C_INT _
)

Type Fts3TokenizerRegistryDestroy As Sub CDecl (ByVal pAuxiliary As Any Ptr)
Type Fts3TokenizerVtabConnect As Function CDecl ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal pAuxiliary As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal arguments As Const ZString Ptr Ptr, _
    ByVal ppVtab As SqliteVtab Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr _
) As SQLITE_C_INT
Type Fts3TokenizerVtabDisconnect As Function CDecl ( _
    ByVal pVtab As SqliteVtab Ptr _
) As SQLITE_C_INT
Type Fts3TokenizerVtabOpen As Function CDecl ( _
    ByVal pVtab As SqliteVtab Ptr, _
    ByVal ppCursor As SqliteVtabCursor Ptr Ptr _
) As SQLITE_C_INT
Type Fts3TokenizerVtabClose As Function CDecl ( _
    ByVal pCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
Type Fts3TokenizerVtabFilter As Function CDecl ( _
    ByVal pCursor As SqliteVtabCursor Ptr, _
    ByVal indexNumber As SQLITE_C_INT, _
    ByVal zIndexString As Const ZString Ptr, _
    ByVal valueCount As SQLITE_C_INT, _
    ByVal apValue As Any Ptr Ptr _
) As SQLITE_C_INT
Type Fts3TokenizerVtabNext As Function CDecl ( _
    ByVal pCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
Type Fts3TokenizerVtabEof As Function CDecl ( _
    ByVal pCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
Type Fts3TokenizerVtabColumn As Function CDecl ( _
    ByVal pCursor As SqliteVtabCursor Ptr, _
    ByVal pContext As Any Ptr, _
    ByVal columnIndex As SQLITE_C_INT _
) As SQLITE_C_INT
Type Fts3TokenizerVtabRowid As Function CDecl ( _
    ByVal pCursor As SqliteVtabCursor Ptr, _
    ByVal pRowid As sqlite3_int64 Ptr _
) As SQLITE_C_INT

Type Fts3TokenizerVtab
    base As SqliteVtab
    pModule As Const Fts3TokenizerModule Ptr
    pTokenizer As Fts3Tokenizer Ptr
End Type

Type Fts3TokenizerVtabCursor
    base As SqliteVtabCursor
    zInput As ZString Ptr
    pTokenizerCursor As Fts3TokenizerCursor Ptr
    rowid As SQLITE_C_INT
    zToken As Const ZString Ptr
    tokenBytes As SQLITE_C_INT
    startOffset As SQLITE_C_INT
    endOffset As SQLITE_C_INT
    position As SQLITE_C_INT
End Type

Declare Function fts3tokConnectMethod CDecl Alias "fts3tokConnectMethod" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal pAuxiliary As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal arguments As Const ZString Ptr Ptr, _
    ByVal ppVtab As SqliteVtab Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr _
) As SQLITE_C_INT
Declare Function fts3tokDisconnectMethod CDecl Alias "fts3tokDisconnectMethod" ( _
    ByVal pVtab As SqliteVtab Ptr _
) As SQLITE_C_INT
Declare Function fts3tokBestIndexMethod CDecl Alias "fts3tokBestIndexMethod" ( _
    ByVal pVtab As SqliteVtab Ptr, _
    ByVal pIndexInfo As SqliteIndexInfo Ptr _
) As SQLITE_C_INT
Declare Function fts3tokOpenMethod CDecl Alias "fts3tokOpenMethod" ( _
    ByVal pVtab As SqliteVtab Ptr, _
    ByVal ppCursor As SqliteVtabCursor Ptr Ptr _
) As SQLITE_C_INT
Declare Function fts3tokCloseMethod CDecl Alias "fts3tokCloseMethod" ( _
    ByVal pCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
Declare Function fts3tokFilterMethod CDecl Alias "fts3tokFilterMethod" ( _
    ByVal pCursor As SqliteVtabCursor Ptr, _
    ByVal indexNumber As SQLITE_C_INT, _
    ByVal zIndexString As Const ZString Ptr, _
    ByVal valueCount As SQLITE_C_INT, _
    ByVal apValue As Any Ptr Ptr _
) As SQLITE_C_INT
Declare Function fts3tokNextMethod CDecl Alias "fts3tokNextMethod" ( _
    ByVal pCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
Declare Function fts3tokEofMethod CDecl Alias "fts3tokEofMethod" ( _
    ByVal pCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
Declare Function fts3tokColumnMethod CDecl Alias "fts3tokColumnMethod" ( _
    ByVal pCursor As SqliteVtabCursor Ptr, _
    ByVal pContext As Any Ptr, _
    ByVal columnIndex As SQLITE_C_INT _
) As SQLITE_C_INT
Declare Function fts3tokRowidMethod CDecl Alias "fts3tokRowidMethod" ( _
    ByVal pCursor As SqliteVtabCursor Ptr, _
    ByVal pRowid As sqlite3_int64 Ptr _
) As SQLITE_C_INT
Declare Sub fts3tokResetCursor CDecl Alias "fts3tokResetCursor" ( _
    ByVal pCursor As Fts3TokenizerVtabCursor Ptr _
)
Declare Sub fts3tokRegistryDestroy CDecl Alias "fts3tokRegistryDestroy" ( _
    ByVal pAuxiliary As Any Ptr _
)

Private Dim Shared As SqliteModuleCallbacks fts3tokModule = _
    Type<SqliteModuleCallbacks>( _
        0, _
        CPtr(Any Ptr, ProcPtr(fts3tokConnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokConnectMethod)), _
        Cast(SqliteModuleBestIndexProc, ProcPtr(fts3tokBestIndexMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokDisconnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokDisconnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokOpenMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokCloseMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokFilterMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokNextMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokEofMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokColumnMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3tokRowidMethod)), _
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 _
    )

Private Function fts3tokDequote(ByVal zText As UByte Ptr) As SQLITE_C_INT
    If zText = 0 Then Return SQLITE_MISUSE
    Dim quoteByte As UByte = zText[0]
    If quoteByte <> Asc("[") AndAlso quoteByte <> Asc("'") AndAlso _
       quoteByte <> Asc(Chr(34)) AndAlso quoteByte <> Asc("`") Then Return SQLITE_OK

    Dim closeByte As UByte = quoteByte
    If quoteByte = Asc("[") Then closeByte = Asc("]")
    Dim inputIndex As SQLITE_C_INT = 1
    Dim outputIndex As SQLITE_C_INT = 0
    While zText[inputIndex] <> 0
        If CUByte(zText[inputIndex]) = closeByte Then
            If zText[inputIndex + 1] <> 0 AndAlso _
               CUByte(zText[inputIndex + 1]) = closeByte Then
                zText[outputIndex] = closeByte
                outputIndex += 1
                inputIndex += 2
            Else
                zText[outputIndex] = 0
                Return SQLITE_OK
            End If
        Else
            zText[outputIndex] = zText[inputIndex]
            outputIndex += 1
            inputIndex += 1
        End If
    Wend

    ' Parser-supplied module arguments are quoted tokens. A missing closing
    ' quote indicates malformed parser input; leave it untouched for SQLite.
    Return SQLITE_ERROR
End Function

Private Function fts3tokDequoteArray( _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal arguments As Const ZString Ptr Ptr, _
    ByVal pazDequote As ZString Ptr Ptr Ptr _
) As SQLITE_C_INT
    If pazDequote = 0 OrElse argumentCount < 0 OrElse _
       (argumentCount > 0 AndAlso arguments = 0) Then Return SQLITE_MISUSE
    pazDequote[0] = 0
    If argumentCount = 0 Then Return SQLITE_OK

    Dim textBytes As sqlite3_uint64 = 0
    For i As SQLITE_C_INT = 0 To argumentCount - 1
        If arguments[i] = 0 Then Return SQLITE_MISUSE
        Dim byteCount As SQLITE_C_INT = sqlite3Strlen30(arguments[i])
        If byteCount < 0 OrElse _
           CULngInt(byteCount) + 1ULL > SQLITE_MAX_ALLOCATION_SIZE - textBytes Then _
            Return SQLITE_TOOBIG
        textBytes += CULngInt(byteCount) + 1ULL
    Next
    Dim pointerBytes As sqlite3_uint64 = _
        CULngInt(argumentCount) * SizeOf(ZString Ptr)
    If pointerBytes > SQLITE_MAX_ALLOCATION_SIZE - textBytes Then Return SQLITE_TOOBIG

    Dim pBlock As UByte Ptr = CPtr(UByte Ptr, sqlite3_malloc64(pointerBytes + textBytes))
    If pBlock = 0 Then Return SQLITE_NOMEM
    Dim pResult As ZString Ptr Ptr = CPtr(ZString Ptr Ptr, pBlock)
    Dim pText As UByte Ptr = pBlock + pointerBytes
    For i As SQLITE_C_INT = 0 To argumentCount - 1
        Dim byteCount As SQLITE_C_INT = sqlite3Strlen30(arguments[i])
        pResult[i] = CPtr(ZString Ptr, pText)
        fts3tokMemcpy(pText, arguments[i], CULngInt(byteCount) + 1ULL)
        If fts3tokDequote(CPtr(UByte Ptr, pResult[i])) <> SQLITE_OK Then
            sqlite3_free(pBlock)
            Return SQLITE_ERROR
        End If
        pText += byteCount + 1
    Next
    pazDequote[0] = pResult
    Return SQLITE_OK
End Function

Private Function fts3tokQueryTokenizer( _
    ByVal pHash As Fts3Hash Ptr, _
    ByVal zName As Const ZString Ptr, _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr _
) As SQLITE_C_INT
    If pHash = 0 OrElse zName = 0 OrElse ppModule = 0 Then Return SQLITE_MISUSE
    ppModule[0] = CPtr(Const Fts3TokenizerModule Ptr, _
        sqlite3Fts3HashFind(pHash, zName, sqlite3Strlen30(zName) + 1))
    If ppModule[0] <> 0 Then Return SQLITE_OK
    If pzError <> 0 Then
        pzError[0] = sqlite3_mprintf(StrPtr(!"unknown tokenizer: %s"), zName)
        If pzError[0] = 0 Then Return SQLITE_NOMEM
    End If
    Return SQLITE_ERROR
End Function

Private Function fts3tokConnectMethod CDecl Alias "fts3tokConnectMethod" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal pAuxiliary As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal arguments As Const ZString Ptr Ptr, _
    ByVal ppVtab As SqliteVtab Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr _
) As SQLITE_C_INT
    If ppVtab = 0 OrElse pDatabase = 0 OrElse argumentCount < 3 Then Return SQLITE_MISUSE
    ppVtab[0] = 0
    If pzError <> 0 Then pzError[0] = 0

    Dim rc As SQLITE_C_INT = sqlite3_declare_vtab( _
        pDatabase, StrPtr(!"CREATE TABLE x(input, token, start, end, position)"))
    Dim argumentValues As ZString Ptr Ptr = 0
    Dim tokenizerName As Const ZString Ptr = StrPtr("simple")
    Dim pTokenizerModule As Const Fts3TokenizerModule Ptr = 0
    Dim pTokenizer As Fts3Tokenizer Ptr = 0
    Dim pTable As Fts3TokenizerVtab Ptr = 0
    Dim dequoteCount As SQLITE_C_INT = argumentCount - 3

    If rc = SQLITE_OK Then _
        rc = fts3tokDequoteArray(dequoteCount, @arguments[3], @argumentValues)
    If rc = SQLITE_OK AndAlso dequoteCount > 0 Then _
        tokenizerName = argumentValues[0]
    If rc = SQLITE_OK Then
        rc = fts3tokQueryTokenizer(CPtr(Fts3Hash Ptr, pAuxiliary), _
                                   tokenizerName, @pTokenizerModule, pzError)
    End If
    If rc = SQLITE_OK Then
        If pTokenizerModule = 0 OrElse pTokenizerModule->xCreate = 0 OrElse _
           pTokenizerModule->xDestroy = 0 OrElse _
           pTokenizerModule->xOpen = 0 OrElse pTokenizerModule->xClose = 0 OrElse _
           pTokenizerModule->xNext = 0 Then
            rc = SQLITE_MISUSE
        Else
            Dim pTokenizerArguments As Const ZString Ptr Ptr = 0
            Dim tokenizerArgumentCount As SQLITE_C_INT = 0
            If dequoteCount > 1 Then
                pTokenizerArguments = CPtr(Const ZString Ptr Ptr, @argumentValues[1])
                tokenizerArgumentCount = dequoteCount - 1
            End If
            rc = pTokenizerModule->xCreate( _
                tokenizerArgumentCount, pTokenizerArguments, @pTokenizer)
        End If
    End If
    If rc = SQLITE_OK Then
        pTable = CPtr(Fts3TokenizerVtab Ptr, _
            sqlite3_malloc64(SizeOf(Fts3TokenizerVtab)))
        If pTable = 0 Then rc = SQLITE_NOMEM
    End If

    If rc = SQLITE_OK Then
        fts3tokMemset(pTable, 0, SizeOf(Fts3TokenizerVtab))
        pTable->pModule = pTokenizerModule
        pTable->pTokenizer = pTokenizer
        ppVtab[0] = @pTable->base
    ElseIf pTokenizer <> 0 AndAlso pTokenizerModule <> 0 AndAlso _
           pTokenizerModule->xDestroy <> 0 Then
        pTokenizerModule->xDestroy(pTokenizer)
    End If

    If argumentValues <> 0 Then sqlite3_free(argumentValues)
    Return rc
End Function

Private Function fts3tokDisconnectMethod CDecl Alias "fts3tokDisconnectMethod" ( _
    ByVal pVtab As SqliteVtab Ptr _
) As SQLITE_C_INT
    If pVtab = 0 Then Return SQLITE_MISUSE
    Dim pTable As Fts3TokenizerVtab Ptr = CPtr(Fts3TokenizerVtab Ptr, pVtab)
    If pTable->pTokenizer <> 0 AndAlso pTable->pModule <> 0 AndAlso _
       pTable->pModule->xDestroy <> 0 Then
        pTable->pModule->xDestroy(pTable->pTokenizer)
    End If
    sqlite3_free(pTable)
    Return SQLITE_OK
End Function

Private Function fts3tokBestIndexMethod CDecl Alias "fts3tokBestIndexMethod" ( _
    ByVal pVtab As SqliteVtab Ptr, _
    ByVal pInfo As SqliteIndexInfo Ptr _
) As SQLITE_C_INT
    If pVtab = 0 OrElse pInfo = 0 OrElse _
       (pInfo->nConstraint > 0 AndAlso _
        (pInfo->aConstraint = 0 OrElse pInfo->aConstraintUsage = 0)) Then _
        Return SQLITE_MISUSE

    pInfo->idxNum = 0
    pInfo->estimatedCost = 1000000000.0
    For i As SQLITE_C_INT = 0 To pInfo->nConstraint - 1
        If pInfo->aConstraint[i].usable <> 0 AndAlso _
           pInfo->aConstraint[i].iColumn = 0 AndAlso _
           pInfo->aConstraint[i].op = SQLITE_INDEX_CONSTRAINT_EQ Then
            pInfo->idxNum = 1
            pInfo->aConstraintUsage[i].argvIndex = 1
            pInfo->aConstraintUsage[i].omit = 1
            pInfo->estimatedCost = 1.0
            Return SQLITE_OK
        End If
    Next
    Return SQLITE_OK
End Function

Private Sub fts3tokResetCursor CDecl Alias "fts3tokResetCursor" ( _
    ByVal pCursor As Fts3TokenizerVtabCursor Ptr _
)
    If pCursor = 0 Then Exit Sub
    If pCursor->pTokenizerCursor <> 0 Then
        Dim pVtab As SqliteVtab Ptr = pCursor->base.pVtab
        If pVtab <> 0 Then
            Dim pTable As Fts3TokenizerVtab Ptr = CPtr(Fts3TokenizerVtab Ptr, pVtab)
            If pTable->pModule <> 0 AndAlso pTable->pModule->xClose <> 0 Then _
                pTable->pModule->xClose(pCursor->pTokenizerCursor)
        End If
        pCursor->pTokenizerCursor = 0
    End If
    If pCursor->zInput <> 0 Then sqlite3_free(pCursor->zInput)
    pCursor->zInput = 0
    pCursor->zToken = 0
    pCursor->tokenBytes = 0
    pCursor->startOffset = 0
    pCursor->endOffset = 0
    pCursor->position = 0
    pCursor->rowid = 0
End Sub

Private Function fts3tokOpenMethod CDecl Alias "fts3tokOpenMethod" ( _
    ByVal pVtab As SqliteVtab Ptr, _
    ByVal ppCursor As SqliteVtabCursor Ptr Ptr _
) As SQLITE_C_INT
    If pVtab = 0 OrElse ppCursor = 0 Then Return SQLITE_MISUSE
    ppCursor[0] = 0
    Dim pCursor As Fts3TokenizerVtabCursor Ptr = CPtr( _
        Fts3TokenizerVtabCursor Ptr, sqlite3_malloc64(SizeOf(Fts3TokenizerVtabCursor)))
    If pCursor = 0 Then Return SQLITE_NOMEM
    fts3tokMemset(pCursor, 0, SizeOf(Fts3TokenizerVtabCursor))
    pCursor->base.pVtab = pVtab
    ppCursor[0] = @pCursor->base
    Return SQLITE_OK
End Function

Private Function fts3tokCloseMethod CDecl Alias "fts3tokCloseMethod" ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 Then Return SQLITE_MISUSE
    Dim pCursor As Fts3TokenizerVtabCursor Ptr = _
        CPtr(Fts3TokenizerVtabCursor Ptr, pVtabCursor)
    fts3tokResetCursor(pCursor)
    sqlite3_free(pCursor)
    Return SQLITE_OK
End Function

Private Function fts3tokNextMethod CDecl Alias "fts3tokNextMethod" ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 OrElse pVtabCursor->pVtab = 0 Then Return SQLITE_MISUSE
    Dim pCursor As Fts3TokenizerVtabCursor Ptr = _
        CPtr(Fts3TokenizerVtabCursor Ptr, pVtabCursor)
    Dim pTable As Fts3TokenizerVtab Ptr = _
        CPtr(Fts3TokenizerVtab Ptr, pVtabCursor->pVtab)
    If pTable->pModule = 0 OrElse pTable->pModule->xNext = 0 OrElse _
       pCursor->pTokenizerCursor = 0 Then Return SQLITE_MISUSE
    If pCursor->rowid = &H7FFFFFFF Then
        fts3tokResetCursor(pCursor)
        Return SQLITE_TOOBIG
    End If
    pCursor->rowid += 1
    Dim rc As SQLITE_C_INT = pTable->pModule->xNext( _
        pCursor->pTokenizerCursor, @pCursor->zToken, @pCursor->tokenBytes, _
        @pCursor->startOffset, @pCursor->endOffset, @pCursor->position)
    If rc <> SQLITE_OK Then
        fts3tokResetCursor(pCursor)
        If rc = SQLITE_DONE Then Return SQLITE_OK
    End If
    Return rc
End Function

Private Function fts3tokFilterMethod CDecl Alias "fts3tokFilterMethod" ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr, _
    ByVal indexNumber As SQLITE_C_INT, _
    ByVal zIndexString As Const ZString Ptr, _
    ByVal valueCount As SQLITE_C_INT, _
    ByVal apValue As Any Ptr Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 OrElse pVtabCursor->pVtab = 0 Then Return SQLITE_MISUSE
    Dim pCursor As Fts3TokenizerVtabCursor Ptr = _
        CPtr(Fts3TokenizerVtabCursor Ptr, pVtabCursor)
    Dim pTable As Fts3TokenizerVtab Ptr = _
        CPtr(Fts3TokenizerVtab Ptr, pVtabCursor->pVtab)
    fts3tokResetCursor(pCursor)
    If indexNumber <> 1 OrElse valueCount < 1 OrElse apValue = 0 OrElse _
       pTable->pModule = 0 OrElse pTable->pTokenizer = 0 OrElse _
       pTable->pModule->xOpen = 0 Then Return SQLITE_ERROR

    Dim pText As Const UByte Ptr = sqlite3_value_text(apValue[0])
    Dim byteCount As SQLITE_C_INT = sqlite3_value_bytes(apValue[0])
    If byteCount < 0 OrElse byteCount > SQLITE_MAX_LENGTH Then Return SQLITE_TOOBIG
    If byteCount > 0 AndAlso pText = 0 Then Return SQLITE_NOMEM
    pCursor->zInput = CPtr(ZString Ptr, sqlite3_malloc64(CULngInt(byteCount) + 1ULL))
    If pCursor->zInput = 0 Then Return SQLITE_NOMEM
    If byteCount > 0 Then fts3tokMemcpy(pCursor->zInput, pText, CULngInt(byteCount))
    CPtr(UByte Ptr, pCursor->zInput)[byteCount] = 0

    Dim rc As SQLITE_C_INT = pTable->pModule->xOpen( _
        pTable->pTokenizer, pCursor->zInput, byteCount, @pCursor->pTokenizerCursor)
    If rc = SQLITE_OK AndAlso pCursor->pTokenizerCursor <> 0 Then
        pCursor->pTokenizerCursor->pTokenizer = pTable->pTokenizer
        rc = fts3tokNextMethod(pVtabCursor)
    ElseIf rc = SQLITE_OK Then
        rc = SQLITE_CORRUPT
    End If
    If rc <> SQLITE_OK Then fts3tokResetCursor(pCursor)
    Return rc
End Function

Private Function fts3tokEofMethod CDecl Alias "fts3tokEofMethod" ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 Then Return 1
    Dim pCursor As Fts3TokenizerVtabCursor Ptr = _
        CPtr(Fts3TokenizerVtabCursor Ptr, pVtabCursor)
    Return CInt(pCursor->zToken = 0)
End Function

Private Function fts3tokColumnMethod CDecl Alias "fts3tokColumnMethod" ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr, _
    ByVal pContext As Any Ptr, _
    ByVal columnIndex As SQLITE_C_INT _
) As SQLITE_C_INT
    If pVtabCursor = 0 OrElse pContext = 0 OrElse columnIndex < 0 OrElse _
       columnIndex > 4 Then Return SQLITE_MISUSE
    Dim pCursor As Fts3TokenizerVtabCursor Ptr = _
        CPtr(Fts3TokenizerVtabCursor Ptr, pVtabCursor)
    Select Case columnIndex
    Case 0
        sqlite3_result_text(pContext, pCursor->zInput, -1, CPtr(Any Ptr, -1))
    Case 1
        If pCursor->tokenBytes < 0 OrElse _
           (pCursor->tokenBytes > 0 AndAlso pCursor->zToken = 0) Then Return SQLITE_CORRUPT
        sqlite3_result_text(pContext, pCursor->zToken, pCursor->tokenBytes, _
                            CPtr(Any Ptr, -1))
    Case 2
        sqlite3_result_int(pContext, pCursor->startOffset)
    Case 3
        sqlite3_result_int(pContext, pCursor->endOffset)
    Case 4
        sqlite3_result_int(pContext, pCursor->position)
    End Select
    Return SQLITE_OK
End Function

Private Function fts3tokRowidMethod CDecl Alias "fts3tokRowidMethod" ( _
    ByVal pVtabCursor As SqliteVtabCursor Ptr, _
    ByVal pRowid As sqlite3_int64 Ptr _
) As SQLITE_C_INT
    If pVtabCursor = 0 OrElse pRowid = 0 Then Return SQLITE_MISUSE
    Dim pCursor As Fts3TokenizerVtabCursor Ptr = _
        CPtr(Fts3TokenizerVtabCursor Ptr, pVtabCursor)
    pRowid[0] = pCursor->rowid
    Return SQLITE_OK
End Function

Function sqlite3Fts3InitTok CDecl Alias "sqlite3Fts3InitTok" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal pHash As Fts3Hash Ptr, _
    ByVal xDestroy As Fts3TokenizerRegistryDestroy _
) As SQLITE_C_INT Export
    If pDatabase = 0 OrElse pHash = 0 Then Return SQLITE_MISUSE
    Return sqlite3_create_module_v2( _
        pDatabase, StrPtr("fts3tokenize"), CPtr(Const Any Ptr, @fts3tokModule), _
        pHash, CPtr(Any Ptr, xDestroy))
End Function

Private Sub fts3tokRegistryDestroy CDecl Alias "fts3tokRegistryDestroy" ( _
    ByVal pAuxiliary As Any Ptr _
)
    If pAuxiliary = 0 Then Exit Sub
    Dim pHash As Fts3Hash Ptr = CPtr(Fts3Hash Ptr, pAuxiliary)
    sqlite3Fts3HashClear(pHash)
    sqlite3_free(pHash)
End Sub

Function sqlite3Fts3TokenizeInit CDecl Alias "sqlite3Fts3TokenizeInit" ( _
    ByVal pDatabase As sqlite3 Ptr _
) As SQLITE_C_INT Export
    If pDatabase = 0 Then Return SQLITE_MISUSE
    Dim pHash As Fts3Hash Ptr = CPtr(Fts3Hash Ptr, _
        sqlite3_malloc64(SizeOf(Fts3Hash)))
    If pHash = 0 Then Return SQLITE_NOMEM
    fts3tokMemset(pHash, 0, SizeOf(Fts3Hash))
    sqlite3Fts3HashInit(pHash, FTS3_HASH_STRING, 1)

    Dim pTokenizer As Const Fts3TokenizerModule Ptr = 0
    sqlite3Fts3SimpleTokenizerModule(@pTokenizer)
    If pTokenizer = 0 OrElse _
       sqlite3Fts3HashInsert(pHash, StrPtr("simple"), 7, _
                             CPtr(Any Ptr, pTokenizer)) <> 0 Then
        fts3tokRegistryDestroy(pHash)
        Return SQLITE_NOMEM
    End If

    sqlite3Fts3PorterTokenizerModule(@pTokenizer)
    If pTokenizer = 0 OrElse _
       sqlite3Fts3HashInsert(pHash, StrPtr("porter"), 7, _
                             CPtr(Any Ptr, pTokenizer)) <> 0 Then
        fts3tokRegistryDestroy(pHash)
        Return SQLITE_NOMEM
    End If

#if Not defined(SQLITE_DISABLE_FTS3_UNICODE)
    sqlite3Fts3UnicodeTokenizer(@pTokenizer)
    If pTokenizer = 0 OrElse _
       sqlite3Fts3HashInsert(pHash, StrPtr("unicode61"), 10, _
                             CPtr(Any Ptr, pTokenizer)) <> 0 Then
        fts3tokRegistryDestroy(pHash)
        Return SQLITE_NOMEM
    End If
#endif

#if defined(SQLITE_ENABLE_ICU)
    sqlite3Fts3IcuTokenizerModule(@pTokenizer)
    If pTokenizer = 0 OrElse _
       sqlite3Fts3HashInsert(pHash, StrPtr("icu"), 4, _
                             CPtr(Any Ptr, pTokenizer)) <> 0 Then
        fts3tokRegistryDestroy(pHash)
        Return SQLITE_NOMEM
    End If
#endif

    ' Register the module first so its destructor owns the hash before the
    ' scalar tokenizer lookup function receives the same pointer as user data.
    Dim rc As SQLITE_C_INT = sqlite3Fts3InitTok( _
        pDatabase, pHash, _
        CPtr(Fts3TokenizerRegistryDestroy, ProcPtr(fts3tokRegistryDestroy)))
    If rc <> SQLITE_OK Then Return rc
    Return sqlite3Fts3InitHashTable( _
        pDatabase, pHash, StrPtr("fts3_tokenizer"))
End Function

#endif

/' end of sqlite3_bulk_fts3_tokenize_vtab.bas '/
