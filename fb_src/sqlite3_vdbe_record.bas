/'
    Project: SQLite FreeBASIC port

    File: sqlite3_vdbe_record.bas

    Purpose:

        Pack Mem values into a SQLite record blob.

    Responsibilities:

        - Select serial types and compute the complete record header size.
        - Write record headers and material payload bytes into database memory.
        - Preserve a trailing zero-filled suffix for the B-tree payload writer.
        - Reject invalid sizes and overlapping input/output cells.

    This file intentionally does NOT contain:

        - VDBE opcode dispatch, B-tree insertion, or record-key comparison.
'/

#lang "fb"
#include once "sqlite3_vdbe_record.bi"
#include once "sqlite3_vdbe_mem_types.bi"
#include once "sqlite3_vdbe_serial.bi"
Extern "C"
    Declare Function sqlite3RecordMemcpy CDecl Alias "memcpy" ( _
        ByVal pDestination As Any Ptr, _
        ByVal pSource As Const Any Ptr, _
        ByVal nByte As SQLITE_SIZE_T _
    ) As Any Ptr
End Extern
Function sqlite3KeyInfoRef CDecl Alias "sqlite3KeyInfoRef" ( _
    ByVal pKeyInfo As sqlite3VdbeKeyInfoPrefix Ptr _
) As sqlite3VdbeKeyInfoPrefix Ptr
    If pKeyInfo = 0 OrElse pKeyInfo->nRef = 0 Then Return 0
    pKeyInfo->nRef += 1
    Return pKeyInfo
End Function

Sub sqlite3KeyInfoUnref CDecl Alias "sqlite3KeyInfoUnref" ( _
    ByVal pKeyInfo As sqlite3VdbeKeyInfoPrefix Ptr _
)
    If pKeyInfo = 0 OrElse pKeyInfo->db = 0 OrElse pKeyInfo->nRef = 0 Then Exit Sub
    pKeyInfo->nRef -= 1
    If pKeyInfo->nRef = 0 Then sqlite3DbNNFreeNN(pKeyInfo->db, pKeyInfo)
End Sub
#include once "sqlite3_varint.bi"

Function sqlite3VdbeRecordPack CDecl Alias "sqlite3VdbeRecordPack" ( _
    ByVal db As sqlite3 Ptr, _
    ByVal pOutputArgument As Any Ptr, _
    ByVal pValuesArgument As Any Ptr, _
    ByVal fieldCount As SQLITE_C_INT, _
    ByVal fileFormat As SQLITE_C_INT _
) As SQLITE_C_INT Export

    If pOutputArgument = 0 OrElse pValuesArgument = 0 OrElse fieldCount <= 0 Then
        Return SQLITE_MISUSE
    End If
    Dim pOutput As SqliteVdbeMem Ptr = CPtr(SqliteVdbeMem Ptr, pOutputArgument)
    Dim pValues As SqliteVdbeMem Ptr = CPtr(SqliteVdbeMem Ptr, pValuesArgument)
    If pOutput->db <> 0 AndAlso pOutput->db <> db Then Return SQLITE_MISUSE
    If (pOutput->flags And MEM_AGG) <> 0 Then Return SQLITE_MISUSE

    Dim pValuesStart As UByte Ptr = CPtr(UByte Ptr, pValues)
    Dim pValuesEnd As UByte Ptr = pValuesStart + CULngInt(fieldCount) * SizeOf(SqliteVdbeMem)
    Dim pOutputBytes As UByte Ptr = CPtr(UByte Ptr, pOutput)
    If pOutputBytes >= pValuesStart AndAlso pOutputBytes < pValuesEnd Then Return SQLITE_MISUSE

    Dim serialHeaderBytes As ULongInt = 0
    Dim payloadBytes As ULongInt = 0
    Dim trailingZeroBytes As ULongInt = 0
    For i As Long = fieldCount - 1 To 0 Step -1
        Dim pValue As SqliteVdbeMem Ptr = @pValues[i]
        If (pValue->flags And (MEM_INT Or MEM_INTREAL Or MEM_REAL Or MEM_STR Or MEM_BLOB Or MEM_NULL)) = 0 Then
            Return SQLITE_MISUSE
        End If
        If pValue->db <> 0 AndAlso pValue->db <> db Then Return SQLITE_MISUSE
        Dim valueLength As u32 = 0
        Dim serialType As u32
        If (pValue->flags And (MEM_NULL Or MEM_ZERO)) = (MEM_NULL Or MEM_ZERO) Then
            serialType = 10
        Else
            serialType = sqlite3VdbeSerialType(pValue, fileFormat, @valueLength)
            If serialType = 0 AndAlso (pValue->flags And MEM_NULL) = 0 Then Return SQLITE_TOOBIG
        End If
        pValue->uTemp = serialType
        Dim serialBytes As ULongInt = CULngInt(sqlite3VarintLen(serialType))
        If serialBytes > SQLITE_MAX_ALLOCATION_SIZE - serialHeaderBytes Then Return SQLITE_TOOBIG
        serialHeaderBytes += serialBytes

        Dim valueBytes As ULongInt = CULngInt(valueLength)
        If (pValue->flags And MEM_ZERO) <> 0 AndAlso _
           (pValue->flags And MEM_NULL) = 0 Then
            If pValue->n < 0 OrElse pValue->u.nZero < 0 Then Return SQLITE_MISUSE
            If payloadBytes > 0 Then
                ' Keep a zero suffix implicit only when no payload bytes follow.
                ' OP_Insert passes the suffix length to the B-tree payload writer.
                Dim expandCode As SQLITE_C_INT = sqlite3VdbeMemExpandBlob(pValue)
                If expandCode <> SQLITE_OK Then Return expandCode
                valueBytes = CULngInt(pValue->n)
            Else
                valueBytes = CULngInt(pValue->n)
                Dim zeroBytes As ULongInt = CULngInt(pValue->u.nZero)
                If zeroBytes > SQLITE_MAX_ALLOCATION_SIZE - trailingZeroBytes Then _
                    Return SQLITE_TOOBIG
                trailingZeroBytes += zeroBytes
            End If
        End If
        If valueBytes > SQLITE_MAX_ALLOCATION_SIZE - payloadBytes Then Return SQLITE_TOOBIG
        payloadBytes += valueBytes
    Next

    Dim headerBytes As ULongInt = serialHeaderBytes + 1
    For iteration As Long = 0 To 9
        Dim lengthBytes As ULongInt = CULngInt(sqlite3VarintLen(headerBytes))
        Dim nextHeaderBytes As ULongInt = serialHeaderBytes + lengthBytes
        If nextHeaderBytes = headerBytes Then Exit For
        headerBytes = nextHeaderBytes
    Next

    If headerBytes > SQLITE_MAX_ALLOCATION_SIZE OrElse _
       payloadBytes > SQLITE_MAX_ALLOCATION_SIZE - headerBytes Then Return SQLITE_TOOBIG
    Dim recordBytes As ULongInt = headerBytes + payloadBytes
    Dim lengthLimit As ULongInt = SQLITE_MAX_LENGTH
    If db <> 0 Then lengthLimit = CULngInt(db->lengthLimit)
    If recordBytes > lengthLimit OrElse _
       trailingZeroBytes > lengthLimit - recordBytes OrElse _
       trailingZeroBytes > &H7FFFFFFF OrElse recordBytes > &H7FFFFFFF Then _
        Return SQLITE_TOOBIG

    Dim zRecord As UByte Ptr = CPtr(UByte Ptr, sqlite3DbMallocRaw(db, recordBytes))
    If zRecord = 0 Then Return SQLITE_NOMEM
    Dim sizeLength As SQLITE_C_INT = sqlite3PutVarint(zRecord, headerBytes)
    If sizeLength <= 0 OrElse CULngInt(sizeLength) > headerBytes Then
        sqlite3DbFree(db, zRecord)
        Return SQLITE_CORRUPT
    End If

    Dim headerOffset As ULongInt = CULngInt(sizeLength)
    Dim payloadOffset As ULongInt = headerBytes
    For i As Long = 0 To fieldCount - 1
        Dim pValue As SqliteVdbeMem Ptr = @pValues[i]
        Dim headerWritten As u32 = 0
        Dim payloadWritten As u32 = 0
        Dim remainingHeader As u32 = CUInt(headerBytes - headerOffset)
        Dim remainingPayload As u32 = CUInt(recordBytes - payloadOffset)
        Dim rc As SQLITE_C_INT
        If (pValue->flags And MEM_ZERO) <> 0 AndAlso _
           (pValue->flags And MEM_NULL) = 0 AndAlso pValue->u.nZero > 0 Then
            If pValue->n < 0 OrElse CULngInt(pValue->n) > remainingPayload OrElse _
               (pValue->n > 0 AndAlso pValue->z = 0) Then
                sqlite3DbFree(db, zRecord)
                Return SQLITE_CORRUPT
            End If
            Dim writtenHeader As SQLITE_C_INT = sqlite3PutVarint( _
                zRecord + headerOffset, pValue->uTemp)
            If writtenHeader <= 0 OrElse CUInt(writtenHeader) > remainingHeader Then
                sqlite3DbFree(db, zRecord)
                Return SQLITE_CORRUPT
            End If
            headerWritten = CUInt(writtenHeader)
            If pValue->n > 0 Then
                sqlite3RecordMemcpy( _
                    zRecord + payloadOffset, pValue->z, CULngInt(pValue->n))
            End If
            payloadWritten = CUInt(pValue->n)
        Else
            rc = sqlite3VdbeSerialPut( _
                pValue, pValue->uTemp, zRecord + headerOffset, remainingHeader, @headerWritten, _
                zRecord + payloadOffset, remainingPayload, @payloadWritten)
            If rc <> SQLITE_OK Then
                sqlite3DbFree(db, zRecord)
                Return rc
            End If
        End If
        headerOffset += headerWritten
        payloadOffset += payloadWritten
    Next

    If headerOffset <> headerBytes OrElse payloadOffset <> recordBytes Then
        sqlite3DbFree(db, zRecord)
        Return SQLITE_CORRUPT
    End If
    sqlite3VdbeMemRelease(pOutput)
    pOutput->u.nZero = CInt(trailingZeroBytes)
    pOutput->z = zRecord
    pOutput->n = CLng(recordBytes)
    pOutput->flags = MEM_BLOB
    If trailingZeroBytes > 0 Then pOutput->flags Or= MEM_ZERO
    pOutput->enc = SQLITE_UTF8
    pOutput->db = db
    pOutput->szMalloc = sqlite3DbMallocSize(db, zRecord)
    pOutput->uTemp = 0
    pOutput->zMalloc = zRecord
    pOutput->xDel = 0
    pOutput->eSubtype = 0
    Return SQLITE_OK
End Function

/' end of sqlite3_vdbe_record.bas '/
