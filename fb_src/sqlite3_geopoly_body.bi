/'
** 2018-05-25
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

    File: sqlite3_geopoly_body.bi

    Purpose:

        Hold the bulk-converted GeoPoly procedures in the R-tree module.

    Responsibilities:

        - Preserve GeoPoly parsing, transformation, bbox, and overlap routines.
        - Register the GeoPoly SQL functions and virtual-table callbacks.
        - Provide the manual JSON number parser that C2FB cannot express yet.

    This file intentionally does NOT contain:

        - Test support or SQLite test cases.
'/
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_geopoly_types.bi"
#include once "sqlite3_straccum.bi"
#include once "sqlite3_rtree_types.bi"
#include once "sqlite3_result.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_fp.bi"

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

Declare Function sqlite3WhereMemset CDecl Alias "memset" ( ByVal pDestination As Any Ptr, ByVal value As SQLITE_C_INT, ByVal byteCount As SQLITE_SIZE_T ) As Any Ptr
Declare Function sqlite3WhereMemcpy CDecl Alias "memcpy" ( ByVal pDestination As Any Ptr, ByVal pSource As Const Any Ptr, ByVal byteCount As SQLITE_SIZE_T ) As Any Ptr

Type c2fb_callback_8 As Sub CDecl(ByVal arg0 As Any Ptr)

Private Type c2fb_source_record_0
    iColumn As c2fb_c_int
    op As UByte
    usable As UByte
    iTermOffset As c2fb_c_int
End Type

Private Type c2fb_source_record_1
    iColumn As c2fb_c_int
    desc As UByte
End Type

Private Type c2fb_source_record_2
    argvIndex As c2fb_c_int
    omit As UByte
End Type

Private Type c2fb_source_record_3
    nConstraint As c2fb_c_int
    aConstraint As c2fb_source_record_0 Ptr
    nOrderBy As c2fb_c_int
    aOrderBy As c2fb_source_record_1 Ptr
    aConstraintUsage As c2fb_source_record_2 Ptr
    idxNum As c2fb_c_int
    idxStr As ZString Ptr
    needToFreeIdxStr As c2fb_c_int
    orderByConsumed As c2fb_c_int
    estimatedCost As Double
    estimatedRows As c2fb_int64
    idxFlags As c2fb_c_int
    colUsed As c2fb_uint64
End Type

Private Type c2fb_source_record_4
    pModule As Const c2fb_sqlite3_module Ptr
    nRef As c2fb_c_int
    zErrMsg As ZString Ptr
End Type

Private Type c2fb_source_record_5
    pVtab As c2fb_source_record_4 Ptr
End Type

Private Type c2fb_source_record_37
    base As c2fb_source_record_4
    db As sqlite3 Ptr
    iNodeSize As c2fb_c_int
    nDim As UByte
    nDim2 As UByte
    eCoordType As UByte
    nBytesPerCell As UByte
    inWrTrans As UByte
    nAux As UShort
    nAuxNotNull As UByte
    iDepth As c2fb_c_int
    zDb As ZString Ptr
    zName As ZString Ptr
    zNodeName As ZString Ptr
    nBusy As c2fb_c_uint
    nRowEst As c2fb_int64
    nCursor As c2fb_c_uint
    nNodeRef As c2fb_c_uint
    zReadAuxSql As ZString Ptr
    pDeleted As c2fb_RtreeNode Ptr
    pNodeBlob As c2fb_sqlite3_blob Ptr
    pWriteNode As c2fb_sqlite3_stmt Ptr
    pDeleteNode As c2fb_sqlite3_stmt Ptr
    pReadRowid As c2fb_sqlite3_stmt Ptr
    pWriteRowid As c2fb_sqlite3_stmt Ptr
    pDeleteRowid As c2fb_sqlite3_stmt Ptr
    pReadParent As c2fb_sqlite3_stmt Ptr
    pWriteParent As c2fb_sqlite3_stmt Ptr
    pDeleteParent As c2fb_sqlite3_stmt Ptr
    pWriteAux As c2fb_sqlite3_stmt Ptr
    aHash(0 To 96) As c2fb_RtreeNode Ptr
End Type

Private Type c2fb_source_record_38
    base As c2fb_source_record_5
    atEOF As UByte
    bPoint As UByte
    bAuxValid As UByte
    iStrategy As c2fb_c_int
    nConstraint As c2fb_c_int
    aConstraint As c2fb_RtreeConstraint Ptr
    nPointAlloc As c2fb_c_int
    nPoint As c2fb_c_int
    mxLevel As c2fb_c_int
    aPoint As c2fb_RtreeSearchPoint Ptr
    pReadAux As c2fb_sqlite3_stmt Ptr
    sPoint As c2fb_RtreeSearchPoint
    aNode(0 To 4) As c2fb_RtreeNode Ptr
    anQueue(0 To 41) As c2fb_c_uint
End Type

Declare Sub geopolySwab32 CDecl Alias "geopolySwab32" (ByVal arg0 As UByte Ptr)
Declare Function geopolySkipSpace CDecl Alias "geopolySkipSpace" (ByVal arg0 As c2fb_GeoParse Ptr) As Byte
Declare Function geopolyParseJson CDecl Alias "geopolyParseJson" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_GeoPoly Ptr
Declare Function geopolyFuncParam CDecl Alias "geopolyFuncParam" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_GeoPoly Ptr
Declare Sub geopolyBlobFunc CDecl Alias "geopolyBlobFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolyJsonFunc CDecl Alias "geopolyJsonFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolySvgFunc CDecl Alias "geopolySvgFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolyXformFunc CDecl Alias "geopolyXformFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function geopolyArea CDecl Alias "geopolyArea" (ByVal arg0 As c2fb_GeoPoly Ptr) As Double
Declare Sub geopolyAreaFunc CDecl Alias "geopolyAreaFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolyCcwFunc CDecl Alias "geopolyCcwFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function geopolySine CDecl Alias "geopolySine" (ByVal arg0 As Double) As Double
Declare Sub geopolyRegularFunc CDecl Alias "geopolyRegularFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function geopolyBBox CDecl Alias "geopolyBBox" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr, ByVal arg2 As c2fb_RtreeCoord Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_GeoPoly Ptr
Declare Sub geopolyBBoxFunc CDecl Alias "geopolyBBoxFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolyBBoxStep CDecl Alias "geopolyBBoxStep" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolyBBoxFinal CDecl Alias "geopolyBBoxFinal" (ByVal arg0 As c2fb_sqlite3_context Ptr)
Declare Function pointBeneathLine CDecl Alias "pointBeneathLine" (ByVal arg0 As Double, ByVal arg1 As Double, ByVal arg2 As Double, ByVal arg3 As Double, ByVal arg4 As Double, ByVal arg5 As Double) As c2fb_c_int
Declare Sub geopolyContainsPointFunc CDecl Alias "geopolyContainsPointFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolyWithinFunc CDecl Alias "geopolyWithinFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolyAddOneSegment CDecl Alias "geopolyAddOneSegment" (ByVal arg0 As c2fb_GeoOverlap Ptr, ByVal arg1 As Single, ByVal arg2 As Single, ByVal arg3 As Single, ByVal arg4 As Single, ByVal arg5 As UByte, ByVal arg6 As c2fb_c_uint)
Declare Sub geopolyAddSegments CDecl Alias "geopolyAddSegments" (ByVal arg0 As c2fb_GeoOverlap Ptr, ByVal arg1 As c2fb_GeoPoly Ptr, ByVal arg2 As UByte)
Declare Function geopolyEventMerge CDecl Alias "geopolyEventMerge" (ByVal arg0 As c2fb_GeoEvent Ptr, ByVal arg1 As c2fb_GeoEvent Ptr) As c2fb_GeoEvent Ptr
Declare Function geopolySortEventsByX CDecl Alias "geopolySortEventsByX" (ByVal arg0 As c2fb_GeoEvent Ptr, ByVal arg1 As c2fb_c_int) As c2fb_GeoEvent Ptr
Declare Function geopolySegmentMerge CDecl Alias "geopolySegmentMerge" (ByVal arg0 As c2fb_GeoSegment Ptr, ByVal arg1 As c2fb_GeoSegment Ptr) As c2fb_GeoSegment Ptr
Declare Function geopolySortSegmentsByYAndC CDecl Alias "geopolySortSegmentsByYAndC" (ByVal arg0 As c2fb_GeoSegment Ptr) As c2fb_GeoSegment Ptr
Declare Function geopolyOverlap CDecl Alias "geopolyOverlap" (ByVal arg0 As c2fb_GeoPoly Ptr, ByVal arg1 As c2fb_GeoPoly Ptr) As c2fb_c_int
Declare Sub geopolyOverlapFunc CDecl Alias "geopolyOverlapFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub geopolyDebugFunc CDecl Alias "geopolyDebugFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function geopolyInit CDecl Alias "geopolyInit" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_4 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr, ByVal arg6 As c2fb_c_int) As c2fb_c_int
Declare Function geopolyCreate CDecl Alias "geopolyCreate" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_4 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function geopolyConnect CDecl Alias "geopolyConnect" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_4 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function geopolyFilter CDecl Alias "geopolyFilter" (ByVal arg0 As c2fb_source_record_5 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
Declare Function geopolyBestIndex CDecl Alias "geopolyBestIndex" (ByVal arg0 As c2fb_source_record_4 Ptr, ByVal arg1 As c2fb_source_record_3 Ptr) As c2fb_c_int
Declare Function geopolyColumn CDecl Alias "geopolyColumn" (ByVal arg0 As c2fb_source_record_5 Ptr, ByVal arg1 As c2fb_sqlite3_context Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function geopolyUpdate CDecl Alias "geopolyUpdate" (ByVal arg0 As c2fb_source_record_4 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_nochange CDecl Alias "sqlite3_value_nochange" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3_result_blob CDecl Alias "sqlite3_result_blob" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_callback_8)
' c2fb skipped nodeAcquire: FreeBASIC body already exists
' c2fb skipped nodeRelease: FreeBASIC body already exists
' c2fb skipped nodeGetRowid: FreeBASIC body already exists
' c2fb skipped rtreeReference: FreeBASIC body already exists
' c2fb skipped rtreeRelease: FreeBASIC body already exists
' c2fb skipped resetCursor: FreeBASIC body already exists
' c2fb skipped nodeRowidIndex: FreeBASIC body already exists
' c2fb skipped rtreeSearchPointFirst: FreeBASIC body already exists
' c2fb skipped rtreeNodeOfFirstSearchPoint: FreeBASIC body already exists
' c2fb skipped rtreeSearchPointNew: FreeBASIC body already exists
' c2fb skipped rtreeStepToLeaf: FreeBASIC body already exists
' c2fb skipped findLeafNode: FreeBASIC body already exists
' c2fb skipped ChooseLeaf: FreeBASIC body already exists
' c2fb skipped rtreeInsertCell: FreeBASIC body already exists
' c2fb skipped rtreeNewRowid: FreeBASIC body already exists
' c2fb skipped rtreeDeleteRowid: FreeBASIC body already exists
' c2fb skipped rtreeConstraintError: FreeBASIC body already exists

Private Function geopolyValueType(ByVal pValue As c2fb_sqlite3_value Ptr) As c2fb_c_int
    Return c2fb_external_sqlite3_value_type(CPtr(SqliteVdbeMem Ptr, pValue))
End Function

Private Function geopolyValueBytes(ByVal pValue As c2fb_sqlite3_value Ptr) As c2fb_c_int
    Return c2fb_external_sqlite3_value_bytes(CPtr(SqliteVdbeMem Ptr, pValue))
End Function

Private Function geopolyValueBlob(ByVal pValue As c2fb_sqlite3_value Ptr) As Const Any Ptr
    Return c2fb_external_sqlite3_value_blob(CPtr(SqliteVdbeMem Ptr, pValue))
End Function

Private Function geopolyValueText(ByVal pValue As c2fb_sqlite3_value Ptr) As Const UByte Ptr
    Return c2fb_external_sqlite3_value_text(CPtr(SqliteVdbeMem Ptr, pValue))
End Function

Private Function geopolyValueDouble(ByVal pValue As c2fb_sqlite3_value Ptr) As Double
    Return c2fb_external_sqlite3_value_double(CPtr(SqliteVdbeMem Ptr, pValue))
End Function

Private Function geopolyValueInt64(ByVal pValue As c2fb_sqlite3_value Ptr) As c2fb_int64
    Return c2fb_external_sqlite3_value_int64(CPtr(SqliteVdbeMem Ptr, pValue))
End Function

Private Function geopolyBindBlob( _
    ByVal pStatement As c2fb_sqlite3_stmt Ptr, _
    ByVal parameterIndex As c2fb_c_int, _
    ByVal pBlob As Const Any Ptr, _
    ByVal nByte As c2fb_c_int, _
    ByVal xDestroy As c2fb_callback_8 _
) As c2fb_c_int
    Return c2fb_external_sqlite3_bind_blob( _
        CPtr(SqliteVdbe Ptr, pStatement), parameterIndex, pBlob, nByte, xDestroy _
    )
End Function

Private Function geopolyBindValue( _
    ByVal pStatement As c2fb_sqlite3_stmt Ptr, _
    ByVal parameterIndex As c2fb_c_int, _
    ByVal pValue As Const c2fb_sqlite3_value Ptr _
) As c2fb_c_int
    Return c2fb_external_sqlite3_bind_value( _
        CPtr(SqliteVdbe Ptr, pStatement), parameterIndex, _
        CPtr(Const SqliteVdbeMem Ptr, pValue) _
    )
End Function

Private Sub geopolySwab32 CDecl Alias "geopolySwab32" (ByVal arg0 As UByte Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 145
    Dim local0 As UByte
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As UByte
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As UByte

    local0 = arg0[Cast(c2fb_c_int, &O0ULL)]
    c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, arg0[Cast(c2fb_c_int, 3ULL)])
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 3ULL)]))
    c2fb_temp_3 = Cast(UByte, local0)
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = Cast(UByte, arg0[Cast(c2fb_c_int, 1ULL)])
    local0 = c2fb_temp_4
    c2fb_temp_5 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_6 = Cast(UByte, arg0[Cast(c2fb_c_int, 2ULL)])
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 2ULL)]))
    c2fb_temp_8 = Cast(UByte, local0)
    (*c2fb_temp_7) = c2fb_temp_8
End Sub
Private Function geopolySkipSpace CDecl Alias "geopolySkipSpace" (ByVal arg0 As c2fb_GeoParse Ptr) As Byte
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 155
    Dim c2fb_temp_0 As Const UByte Ptr Ptr
    Dim c2fb_temp_1 As Const UByte Ptr

    While (c2fb_geopolyIsSpace(Cast(UByte, arg0->z[Cast(c2fb_c_int, &O0ULL)])))
        c2fb_temp_0 = CPtr(Const UByte Ptr Ptr, @(arg0->z))
        c2fb_temp_1 = (*c2fb_temp_0)
        (*c2fb_temp_0) = (c2fb_temp_1 + 1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return arg0->z[Cast(c2fb_c_int, &O0ULL)]
End Function
' c2fb skipped geopolyParseNumber: outside the supported subset
' c2fb body diagnostic [unsupported-expression] line 163: geopolyParseNumber: expression parser stopped at byte 101 in (((*__ctype_b_loc ())[(int) ((         (unsigned char)(c)         ))] & (unsigned short int) _ISdigit)): )
Private Function geopolyParseNumber CDecl Alias "geopolyParseNumber" ( _
    ByVal p As c2fb_GeoParse Ptr, _
    ByVal pValue As c2fb_GeoCoord Ptr _
) As c2fb_c_int
    If p = 0 OrElse p->z = 0 Then Return 0

    Dim zNumber As Const UByte Ptr = p->z
    Dim currentByte As UByte = Cast(UByte, geopolySkipSpace(p))
    zNumber = p->z

    Dim characterIndex As c2fb_c_int = 0
    Dim hasDecimal As c2fb_c_int = 0
    Dim hasExponent As c2fb_c_int = 0

    If currentByte = Asc("-") Then
        characterIndex = 1
        currentByte = zNumber[characterIndex]
    End If

    If currentByte = Asc("0") AndAlso _
       zNumber[characterIndex + 1] >= Asc("0") AndAlso _
       zNumber[characterIndex + 1] <= Asc("9") Then Return 0

    While True
        currentByte = zNumber[characterIndex]

        If currentByte >= Asc("0") AndAlso currentByte <= Asc("9") Then
            characterIndex += 1
            Continue While
        End If

        If currentByte = Asc(".") Then
            If characterIndex > 0 AndAlso _
               zNumber[characterIndex - 1] = Asc("-") Then Return 0
            If hasDecimal <> 0 Then Return 0
            hasDecimal = 1
            characterIndex += 1
            Continue While
        End If

        If currentByte = Asc("e") OrElse currentByte = Asc("E") Then
            If characterIndex = 0 OrElse _
               zNumber[characterIndex - 1] < Asc("0") Then Return 0
            If hasExponent <> 0 Then Return -1

            hasDecimal = 1
            hasExponent = 1
            characterIndex += 1
            currentByte = zNumber[characterIndex]
            If currentByte = Asc("+") OrElse currentByte = Asc("-") Then
                characterIndex += 1
                currentByte = zNumber[characterIndex]
            End If
            If currentByte < Asc("0") OrElse currentByte > Asc("9") Then Return 0
            Continue While
        End If

        Exit While
    Wend

    If characterIndex = 0 OrElse _
       zNumber[characterIndex - 1] < Asc("0") Then Return 0

    If pValue <> 0 Then
        Dim parsedValue As Double
        sqlite3AtoF(CPtr(Const ZString Ptr, zNumber), @parsedValue)
        pValue[0] = Cast(c2fb_GeoCoord, parsedValue)
    End If

    p->z = zNumber + characterIndex
    Return 1
End Function
Private Function geopolyParseJson CDecl Alias "geopolyParseJson" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_GeoPoly Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 221
    Dim local0 As c2fb_GeoParse
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Const UByte Ptr Ptr
    Dim c2fb_temp_2 As Const UByte Ptr
    Dim c2fb_temp_3 As Const UByte Ptr Ptr
    Dim c2fb_temp_4 As Const UByte Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As Byte
    Dim c2fb_temp_5 As Const UByte Ptr Ptr
    Dim c2fb_temp_6 As Const UByte Ptr
    Dim local4 As Single Ptr
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Single Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_GeoCoord Ptr Ptr
    Dim c2fb_temp_14 As Single Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Byte
    Dim c2fb_temp_19 As Const UByte Ptr Ptr
    Dim c2fb_temp_20 As Const UByte Ptr
    Dim c2fb_temp_21 As Long Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As Const UByte Ptr Ptr
    Dim c2fb_temp_25 As Const UByte Ptr
    Dim c2fb_temp_26 As Const UByte Ptr Ptr
    Dim c2fb_temp_27 As Const UByte Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim local5 As c2fb_GeoPoly Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_29 As Long Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As Long Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Any Ptr
    Dim c2fb_temp_36 As UByte Ptr
    Dim c2fb_temp_37 As UByte
    Dim c2fb_temp_38 As UByte Ptr
    Dim c2fb_temp_39 As UByte
    Dim c2fb_temp_40 As UByte Ptr
    Dim c2fb_temp_41 As UByte
    Dim c2fb_temp_42 As UByte Ptr
    Dim c2fb_temp_43 As UByte
    Dim c2fb_temp_44 As c2fb_c_int Ptr
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As Long Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_c_int Ptr
    Dim c2fb_temp_50 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Any Ptr, sqlite3WhereMemset(CPtr(Any Ptr, CPtr(c2fb_GeoParse Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_GeoParse))))
    c2fb_temp_1 = CPtr(Const UByte Ptr Ptr, @(local0.z))
    c2fb_temp_2 = arg0
    (*c2fb_temp_1) = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, geopolySkipSpace(CPtr(c2fb_GeoParse Ptr, @(local0)))) = Cast(c2fb_c_int, 91))))) Then
        c2fb_temp_3 = CPtr(Const UByte Ptr Ptr, @(local0.z))
        c2fb_temp_4 = (*c2fb_temp_3)
        (*c2fb_temp_3) = (c2fb_temp_4 + 1)
        While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, geopolySkipSpace(CPtr(c2fb_GeoParse Ptr, @(local0)))) = Cast(c2fb_c_int, 91)))))
            local2 = Cast(c2fb_c_int, &O0ULL)
            ' C automatic storage declaration
            c2fb_temp_5 = CPtr(Const UByte Ptr Ptr, @(local0.z))
            c2fb_temp_6 = (*c2fb_temp_5)
            (*c2fb_temp_5) = (c2fb_temp_6 + 1)
            If (-Cast(c2fb_c_int, ((local0.nVertex >= local0.nAlloc)))) Then
                ' C automatic storage declaration
                c2fb_temp_7 = CPtr(Long Ptr, @(local0.nAlloc))
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0.nAlloc * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 16ULL))))
                (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
                c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                c2fb_temp_9 = CPtr(Single Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local0.a), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, local0.nAlloc) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Single))))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))))))
                local4 = c2fb_temp_9
                If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    local1 = c2fb_temp_10
                    c2fb_temp_11 = CPtr(Long Ptr, @(local0.nErr))
                    c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
                    (*c2fb_temp_11) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
                    Goto c2fb_flow_0
                End If
                c2fb_temp_13 = CPtr(c2fb_GeoCoord Ptr Ptr, @(local0.a))
                c2fb_temp_14 = local4
                (*c2fb_temp_13) = CPtr(c2fb_GeoCoord Ptr, c2fb_temp_14)
                c2fb_temp_14 = CPtr(Single Ptr, (*c2fb_temp_13))
            End If
            While geopolyParseNumber(CPtr(c2fb_GeoParse Ptr, @(local0)), IIf((-Cast(c2fb_c_int, ((local2 <= Cast(c2fb_c_int, 1ULL))))), CPtr(Single Ptr, @(local0.a[Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0.nVertex * Cast(c2fb_c_int, 2ULL))) + local2))])), CPtr(Single Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
                c2fb_temp_15 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 2ULL))))) Then
                    c2fb_temp_16 = CPtr(Long Ptr, @(local0.nVertex))
                    c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
                    (*c2fb_temp_16) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
                End If
                c2fb_temp_18 = Cast(Byte, geopolySkipSpace(CPtr(c2fb_GeoParse Ptr, @(local0))))
                local3 = c2fb_temp_18
                c2fb_temp_19 = CPtr(Const UByte Ptr Ptr, @(local0.z))
                c2fb_temp_20 = (*c2fb_temp_19)
                (*c2fb_temp_19) = (c2fb_temp_20 + 1)
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) = Cast(c2fb_c_int, 44))))) Then
                    Goto c2fb_flow_3
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) = Cast(c2fb_c_int, 93))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                    Goto c2fb_flow_2
                End If
                c2fb_temp_21 = CPtr(Long Ptr, @(local0.nErr))
                c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
                (*c2fb_temp_21) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_22 + 1)))
                c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local1 = c2fb_temp_23
                Goto c2fb_label_0
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, geopolySkipSpace(CPtr(c2fb_GeoParse Ptr, @(local0)))) = Cast(c2fb_c_int, 44))))) Then
                c2fb_temp_24 = CPtr(Const UByte Ptr Ptr, @(local0.z))
                c2fb_temp_25 = (*c2fb_temp_24)
                (*c2fb_temp_24) = (c2fb_temp_25 + 1)
                Goto c2fb_flow_1
            End If
            Goto c2fb_flow_0
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_28 = 0
        If ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, geopolySkipSpace(CPtr(c2fb_GeoParse Ptr, @(local0)))) = Cast(c2fb_c_int, 93))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0.nVertex >= Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0.nVertex < Cast(c2fb_c_int, 16777216ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0.a[Cast(c2fb_c_int, &O0ULL)] = local0.a[Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0.nVertex * Cast(c2fb_c_int, 2ULL))) - Cast(c2fb_c_int, 2ULL)))])))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0.a[Cast(c2fb_c_int, 1ULL)] = local0.a[Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0.nVertex * Cast(c2fb_c_int, 2ULL))) - Cast(c2fb_c_int, 1ULL)))])))) <> 0) Then
            c2fb_temp_26 = CPtr(Const UByte Ptr Ptr, @(local0.z))
            c2fb_temp_27 = (*c2fb_temp_26)
            (*c2fb_temp_26) = (c2fb_temp_27 + 1)
            c2fb_temp_28 = (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, geopolySkipSpace(CPtr(c2fb_GeoParse Ptr, @(local0)))) = Cast(c2fb_c_int, &O0ULL)))))) <> 0))))
        End If
        If c2fb_temp_28 Then
            ' C automatic storage declaration
            local6 = Cast(c2fb_c_int, 1ULL)
            c2fb_temp_29 = CPtr(Long Ptr, @(local0.nVertex))
            c2fb_temp_30 = Cast(c2fb_c_int, (*c2fb_temp_29))
            (*c2fb_temp_29) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_30 - 1)))
            c2fb_temp_31 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, CPtr(Any Ptr, sqlite3_malloc64((Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_GeoPoly))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Single))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))) * Cast(c2fb_uint64, (Cast(c2fb_int64, ((Cast(c2fb_int64, local0.nVertex)) - Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL))))))))))))))
            local5 = c2fb_temp_31
            c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local6 = c2fb_temp_32
            If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_label_0
            End If
            c2fb_temp_33 = CPtr(Long Ptr, @(local5->nVertex))
            c2fb_temp_34 = Cast(c2fb_c_int, local0.nVertex)
            (*c2fb_temp_33) = Cast(Long, c2fb_temp_34)
            c2fb_temp_34 = Cast(c2fb_c_int, (*c2fb_temp_33))
            c2fb_temp_35 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, CPtr(Single Ptr, (@local5->a(0)))), CPtr(Const Any Ptr, local0.a), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (local0.nVertex * Cast(c2fb_c_int, 2ULL)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Single)))))))
            c2fb_temp_36 = CPtr(UByte Ptr, @(local5->hdr(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_37 = Cast(UByte, (*CPtr(UByte Ptr, CPtr(c2fb_c_int Ptr, @(local6)))))
            (*c2fb_temp_36) = c2fb_temp_37
            c2fb_temp_38 = CPtr(UByte Ptr, @(local5->hdr(Cast(c2fb_c_int, 1ULL))))
            c2fb_temp_39 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0.nVertex Shr Cast(c2fb_c_int, 16ULL)))) And Cast(c2fb_c_int, &HffULL))))
            (*c2fb_temp_38) = c2fb_temp_39
            c2fb_temp_40 = CPtr(UByte Ptr, @(local5->hdr(Cast(c2fb_c_int, 2ULL))))
            c2fb_temp_41 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0.nVertex Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_c_int, &HffULL))))
            (*c2fb_temp_40) = c2fb_temp_41
            c2fb_temp_42 = CPtr(UByte Ptr, @(local5->hdr(Cast(c2fb_c_int, 3ULL))))
            c2fb_temp_43 = Cast(UByte, Cast(c2fb_c_int, (local0.nVertex And Cast(c2fb_c_int, &HffULL))))
            (*c2fb_temp_42) = c2fb_temp_43
            sqlite3_free(CPtr(Any Ptr, local0.a))
            If arg1 Then
                c2fb_temp_44 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_45 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_44) = c2fb_temp_45
            End If
            Return local5
        Else
            c2fb_temp_46 = CPtr(Long Ptr, @(local0.nErr))
            c2fb_temp_47 = Cast(c2fb_c_int, (*c2fb_temp_46))
            (*c2fb_temp_46) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_47 + 1)))
            c2fb_temp_48 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local1 = c2fb_temp_48
        End If
    End If
    c2fb_label_0:
    If arg1 Then
        c2fb_temp_49 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_50 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_49) = c2fb_temp_50
    End If
    sqlite3_free(CPtr(Any Ptr, local0.a))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function geopolyFuncParam CDecl Alias "geopolyFuncParam" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_GeoPoly Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 298
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As Const UByte Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Any Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local6 As Const UByte Ptr
    Dim c2fb_temp_15 As c2fb_c_int Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' empty C statement
    c2fb_temp_1 = 0
    If ((-Cast(c2fb_c_int, ((geopolyValueType(arg1) = Cast(c2fb_c_int, 4ULL))))) <> 0) Then
        c2fb_temp_0 = Cast(c2fb_c_int, geopolyValueBytes(arg1))
        local1 = c2fb_temp_0
        c2fb_temp_1 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((c2fb_temp_0) >= Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL)) + Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, 6ULL)) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Single))))))))))))) <> 0))))
    End If
    If c2fb_temp_1 Then
        local2 = CPtr(Const Any Ptr, geopolyValueBlob(arg1))
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            If arg0 Then
                sqlite3_result_error_nomem(CPtr(Any Ptr, arg0))
            End If
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, local2[Cast(c2fb_c_int, 1ULL)]) Shl Cast(c2fb_c_int, 16ULL)))) + (Cast(c2fb_c_int, (Cast(c2fb_c_int, local2[Cast(c2fb_c_int, 2ULL)]) Shl Cast(c2fb_c_int, 8ULL)))))) + Cast(c2fb_c_int, local2[Cast(c2fb_c_int, 3ULL)]))))
        local3 = c2fb_temp_2
        If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 1ULL))))) <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 2ULL)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Single))))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))))) = Cast(c2fb_uint64, Cast(c2fb_c_uint, local1)))))) <> 0))))) Then
            c2fb_temp_3 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_GeoPoly))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, 1ULL)))) * Cast(c2fb_c_int, 2ULL)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Single))))))))))
            local0 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                If arg2 Then
                    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    (*c2fb_temp_4) = c2fb_temp_5
                End If
                If arg0 Then
                    sqlite3_result_error_nomem(CPtr(Any Ptr, arg0))
                End If
            Else
                local4 = Cast(c2fb_c_int, 1ULL)
                c2fb_temp_6 = CPtr(Long Ptr, @(local0->nVertex))
                c2fb_temp_7 = Cast(c2fb_c_int, local3)
                (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
                c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
                c2fb_temp_8 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, CPtr(UByte Ptr, (@local0->hdr(0)))), CPtr(Const Any Ptr, local2), local1))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, (*CPtr(UByte Ptr, CPtr(c2fb_c_int Ptr, @(local4))))))))) Then
                    ' C automatic storage declaration
                    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local5 = c2fb_temp_9
                    While (-Cast(c2fb_c_int, ((local5 < local3))))
                        geopolySwab32(CPtr(UByte Ptr, CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local5) * Cast(c2fb_c_int, 2ULL)))])))))
                        geopolySwab32(CPtr(UByte Ptr, CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local5) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))))
                    c2fb_flow_1:
                        c2fb_temp_10 = local5
                        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
                    Wend
                    c2fb_flow_0:
                    c2fb_temp_11 = CPtr(UByte Ptr, @(local0->hdr(Cast(c2fb_c_int, &O0ULL))))
                    c2fb_temp_12 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_11)) Xor Cast(c2fb_c_int, 1ULL))))
                    (*c2fb_temp_11) = c2fb_temp_12
                End If
            End If
        End If
        If arg2 Then
            c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_13) = c2fb_temp_14
        End If
        Return local0
    Else
        If (-Cast(c2fb_c_int, ((geopolyValueType(arg1) = Cast(c2fb_c_int, 3ULL))))) Then
            local6 = CPtr(Const UByte Ptr, geopolyValueText(arg1))
            If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                If arg2 Then
                    c2fb_temp_15 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    (*c2fb_temp_15) = c2fb_temp_16
                End If
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            Return CPtr(c2fb_GeoPoly Ptr, geopolyParseJson(local6, arg2))
        Else
            If arg2 Then
                c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_17) = c2fb_temp_18
            End If
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    End If
End Function
Private Sub geopolyBlobFunc CDecl Alias "geopolyBlobFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 359
    Dim local0 As c2fb_GeoPoly Ptr

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL)))
    ' C unused-parameter annotation
    If local0 Then
        c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, CPtr(UByte Ptr, (@local0->hdr(0)))), Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) * local0->nVertex)))), (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Sub geopolyJsonFunc CDecl Alias "geopolyJsonFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 379
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As sqlite3 Ptr
    Dim local2 As sqlite3_str Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL)))
    ' C unused-parameter annotation
    If local0 Then
        local1 = CPtr(sqlite3 Ptr, sqlite3_context_db_handle(CPtr(Any Ptr, arg0)))
        local2 = CPtr(sqlite3_str Ptr, c2fb_external_sqlite3_str_new(local1))
        ' C automatic storage declaration
        c2fb_external_sqlite3_str_append(local2, StrPtr(!"["), Cast(c2fb_c_int, 1ULL))
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local3 < local0->nVertex))))
            c2fb_external_sqlite3_str_appendf(local2, StrPtr(!"[%!g,%!g],"), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local3) * Cast(c2fb_c_int, 2ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local3) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
        c2fb_flow_1:
            c2fb_temp_1 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_str_appendf(local2, StrPtr(!"[%!g,%!g]]"), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
        sqlite3_result_text(CPtr(Any Ptr, arg0), CPtr(Const ZString Ptr, CPtr(ZString Ptr, c2fb_external_sqlite3_str_finish(local2))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), ProcPtr(sqlite3_free))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Sub geopolySvgFunc CDecl Alias "geopolySvgFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 406
    Dim local0 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_0 As c2fb_GeoPoly Ptr
    Dim local1 As sqlite3 Ptr
    Dim local2 As sqlite3_str Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As Byte
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Byte
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local5 As Const ZString Ptr

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, 1ULL))))) Then
        Return
    End If
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL))))
    local0 = c2fb_temp_0
    If local0 Then
        local1 = CPtr(sqlite3 Ptr, sqlite3_context_db_handle(CPtr(Any Ptr, arg0)))
        local2 = CPtr(sqlite3_str Ptr, c2fb_external_sqlite3_str_new(local1))
        ' C automatic storage declaration
        local4 = Cast(c2fb_c_int, 39)
        c2fb_external_sqlite3_str_appendf(local2, StrPtr(!"<polyline points="))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local3 < local0->nVertex))))
            c2fb_external_sqlite3_str_appendf(local2, StrPtr(!"%c%g,%g"), local4, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local3) * Cast(c2fb_c_int, 2ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local3) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
            c2fb_temp_3 = Cast(Byte, Cast(c2fb_c_int, 32))
            local4 = c2fb_temp_3
        c2fb_flow_1:
            c2fb_temp_2 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_str_appendf(local2, StrPtr(!" %g,%g'"), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((local3 < arg1))))
            local5 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, geopolyValueText(arg2[local3])))
            If (-Cast(c2fb_c_int, (((local5 <> 0) AndAlso (CPtr(Const Byte Ptr, local5)[Cast(c2fb_c_int, &O0ULL)] <> 0))))) Then
                c2fb_external_sqlite3_str_appendf(local2, StrPtr(!" %s"), local5)
            End If
        c2fb_flow_3:
            c2fb_temp_5 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_external_sqlite3_str_appendf(local2, StrPtr(!"></polyline>"))
        sqlite3_result_text(CPtr(Any Ptr, arg0), CPtr(Const ZString Ptr, CPtr(ZString Ptr, c2fb_external_sqlite3_str_finish(local2))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), ProcPtr(sqlite3_free))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Sub geopolyXformFunc CDecl Alias "geopolyXformFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 453
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As Double
    Dim local2 As Double
    Dim local3 As Double
    Dim local4 As Double
    Dim local5 As Double
    Dim local6 As Double
    Dim local7 As Single
    Dim local8 As Single
    Dim local9 As Single
    Dim local10 As Single
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Single
    Dim c2fb_temp_3 As Single
    Dim c2fb_temp_4 As Single
    Dim c2fb_temp_5 As Single
    Dim c2fb_temp_6 As Single Ptr
    Dim c2fb_temp_7 As Single
    Dim c2fb_temp_8 As Single Ptr
    Dim c2fb_temp_9 As Single

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL)))
    local1 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 1ULL)])
    local2 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 2ULL)])
    local3 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 3ULL)])
    local4 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 4ULL)])
    local5 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 5ULL)])
    local6 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 6ULL)])
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If local0 Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local11 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local11 < local0->nVertex))))
            c2fb_temp_2 = Cast(Single, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local11) * Cast(c2fb_c_int, 2ULL)))]))
            local9 = c2fb_temp_2
            c2fb_temp_3 = Cast(Single, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local11) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
            local10 = c2fb_temp_3
            c2fb_temp_4 = Cast(Single, __c2fb_single_value(Cast(Single, (__c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (local1 * Cast(Double, local9)))) + __c2fb_double_value(Cast(Double, (local2 * Cast(Double, local10))))))) + local5)))))))
            local7 = c2fb_temp_4
            c2fb_temp_5 = Cast(Single, __c2fb_single_value(Cast(Single, (__c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (local3 * Cast(Double, local9)))) + __c2fb_double_value(Cast(Double, (local4 * Cast(Double, local10))))))) + local6)))))))
            local8 = c2fb_temp_5
            c2fb_temp_6 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local11) * Cast(c2fb_c_int, 2ULL)))])))
            c2fb_temp_7 = Cast(Single, local7)
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local11) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
            c2fb_temp_9 = Cast(Single, local8)
            (*c2fb_temp_8) = c2fb_temp_9
        c2fb_flow_1:
            c2fb_temp_1 = local11
            local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, CPtr(UByte Ptr, (@local0->hdr(0)))), Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) * local0->nVertex)))), (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Function geopolyArea CDecl Alias "geopolyArea" (ByVal arg0 As c2fb_GeoPoly Ptr) As Double
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 490
    Dim local0 As Double
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Double
    Dim c2fb_temp_3 As Double

    local0 = 0.0#
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, (arg0->nVertex - Cast(c2fb_c_int, 1ULL)))))))
        c2fb_temp_2 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 + __c2fb_double_value(Cast(Double, (Cast(Double, __c2fb_single_value(Cast(Single, ((__c2fb_single_value(Cast(Single, (((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg0)->a(0)))))[Cast(c2fb_c_int, ((local1) * Cast(c2fb_c_int, 2ULL)))]) - ((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))) * Cast(c2fb_c_int, 2ULL)))]))))) * (__c2fb_single_value(Cast(Single, (((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local1) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]) + ((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))))))))) * 0.5#)))))))
        local0 = c2fb_temp_2
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 + __c2fb_double_value(Cast(Double, (Cast(Double, __c2fb_single_value(Cast(Single, ((__c2fb_single_value(Cast(Single, (((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg0)->a(0)))))[Cast(c2fb_c_int, ((local1) * Cast(c2fb_c_int, 2ULL)))]) - ((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL)))]))))) * (__c2fb_single_value(Cast(Single, (((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local1) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]) + ((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))))))))) * 0.5#)))))))
    local0 = c2fb_temp_3
    Return local0
End Function
Private Sub geopolyAreaFunc CDecl Alias "geopolyAreaFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 512
    Dim local0 As c2fb_GeoPoly Ptr

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL)))
    ' C unused-parameter annotation
    If local0 Then
        sqlite3_result_double(CPtr(Any Ptr, arg0), geopolyArea(local0))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Sub geopolyCcwFunc CDecl Alias "geopolyCcwFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 538
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As Single
    Dim c2fb_temp_4 As Single Ptr
    Dim c2fb_temp_5 As Single
    Dim c2fb_temp_6 As Single Ptr
    Dim c2fb_temp_7 As Single
    Dim c2fb_temp_8 As Single
    Dim c2fb_temp_9 As Single Ptr
    Dim c2fb_temp_10 As Single
    Dim c2fb_temp_11 As Single Ptr
    Dim c2fb_temp_12 As Single

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL)))
    ' C unused-parameter annotation
    If local0 Then
        If (-Cast(c2fb_c_int, ((geopolyArea(local0) < 0.0#)))) Then
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local1 = c2fb_temp_0
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0->nVertex - Cast(c2fb_c_int, 1ULL))))
            local2 = c2fb_temp_1
            While (-Cast(c2fb_c_int, ((local1 < local2))))
                local3 = ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local1) * Cast(c2fb_c_int, 2ULL)))])
                c2fb_temp_4 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local1) * Cast(c2fb_c_int, 2ULL)))])))
                c2fb_temp_5 = Cast(Single, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local2) * Cast(c2fb_c_int, 2ULL)))]))
                (*c2fb_temp_4) = c2fb_temp_5
                c2fb_temp_6 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local2) * Cast(c2fb_c_int, 2ULL)))])))
                c2fb_temp_7 = Cast(Single, local3)
                (*c2fb_temp_6) = c2fb_temp_7
                c2fb_temp_8 = Cast(Single, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local1) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
                local3 = c2fb_temp_8
                c2fb_temp_9 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local1) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
                c2fb_temp_10 = Cast(Single, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local2) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
                (*c2fb_temp_9) = c2fb_temp_10
                c2fb_temp_11 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local2) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
                c2fb_temp_12 = Cast(Single, local3)
                (*c2fb_temp_11) = c2fb_temp_12
            c2fb_flow_1:
                c2fb_temp_2 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                c2fb_temp_3 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
            Wend
            c2fb_flow_0:
        End If
        c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, CPtr(UByte Ptr, (@local0->hdr(0)))), Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) * local0->nVertex)))), (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Function geopolySine CDecl Alias "geopolySine" (ByVal arg0 As Double) As Double
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 567
    Dim c2fb_temp_0 As Double
    Dim local0 As Double
    Dim local1 As Double
    Dim local2 As Double

    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0 >= __c2fb_double_value(Cast(Double, (1.5# * 3.1415926535897932385#))))))) Then
        c2fb_temp_0 = Cast(Double, __c2fb_double_value(Cast(Double, (arg0 - __c2fb_double_value(Cast(Double, (2.0# * 3.1415926535897932385#)))))))
        arg0 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((arg0 >= __c2fb_double_value(Cast(Double, (0.5# * 3.1415926535897932385#))))))) Then
        Return __c2fb_double_value(Cast(Double, (-geopolySine(__c2fb_double_value(Cast(Double, (arg0 - 3.1415926535897932385#)))))))
    Else
        local0 = __c2fb_double_value(Cast(Double, (arg0 * arg0)))
        local1 = __c2fb_double_value(Cast(Double, (local0 * arg0)))
        local2 = __c2fb_double_value(Cast(Double, (local1 * local0)))
        Return __c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (0.9996949# * arg0))) - __c2fb_double_value(Cast(Double, (0.1656700# * local1)))))) + __c2fb_double_value(Cast(Double, (0.0075134# * local2))))))
    End If
End Function
Private Sub geopolyRegularFunc CDecl Alias "geopolyRegularFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 590
    Dim local0 As Double
    Dim local1 As Double
    Dim local2 As Double
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As UByte
    Dim c2fb_temp_9 As UByte Ptr
    Dim c2fb_temp_10 As UByte
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local6 As Double
    Dim c2fb_temp_13 As Single Ptr
    Dim c2fb_temp_14 As Single
    Dim c2fb_temp_15 As Single Ptr
    Dim c2fb_temp_16 As Single

    local0 = geopolyValueDouble(arg2[Cast(c2fb_c_int, &O0ULL)])
    local1 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 1ULL)])
    local2 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 2ULL)])
    local3 = geopolyValueInt64(arg2[Cast(c2fb_c_int, 3ULL)])
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < Cast(c2fb_int64, Cast(c2fb_c_int, 3ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 <= 0.0#)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 >= 1e300#)))) <> 0))))) Then
        Return
    End If
    If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_int64, Cast(c2fb_c_int, 1000ULL)))))) Then
        c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_c_int, 1000ULL))
        local3 = c2fb_temp_0
    End If
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_GeoPoly))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, ((Cast(c2fb_int64, (local3 - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Single))))))))))
    local5 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_result_error_nomem(CPtr(Any Ptr, arg0))
        Return
    End If
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    local4 = c2fb_temp_2
    c2fb_temp_3 = CPtr(UByte Ptr, @(local5->hdr(Cast(c2fb_c_int, &O0ULL))))
    c2fb_temp_4 = Cast(UByte, (*CPtr(UByte Ptr, CPtr(c2fb_c_int Ptr, @(local4)))))
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(UByte Ptr, @(local5->hdr(Cast(c2fb_c_int, 1ULL))))
    c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(UByte Ptr, @(local5->hdr(Cast(c2fb_c_int, 2ULL))))
    c2fb_temp_8 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (local3 Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HffULL)))))
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(UByte Ptr, @(local5->hdr(Cast(c2fb_c_int, 3ULL))))
    c2fb_temp_10 = Cast(UByte, Cast(c2fb_int64, (local3 And Cast(c2fb_int64, Cast(c2fb_c_int, &HffULL)))))
    (*c2fb_temp_9) = c2fb_temp_10
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_11
    While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local4) < local3))))
        local6 = __c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (2.0# * 3.1415926535897932385#))) * Cast(Double, local4)))) / Cast(Double, local3))))
        c2fb_temp_13 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local5)->a(0)))))[Cast(c2fb_c_int, ((local4) * Cast(c2fb_c_int, 2ULL)))])))
        c2fb_temp_14 = Cast(Single, __c2fb_double_value(Cast(Double, (local0 - __c2fb_double_value(Cast(Double, (local2 * geopolySine(__c2fb_double_value(Cast(Double, (local6 - __c2fb_double_value(Cast(Double, (0.5# * 3.1415926535897932385#))))))))))))))
        (*c2fb_temp_13) = c2fb_temp_14
        c2fb_temp_15 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local5)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local4) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
        c2fb_temp_16 = Cast(Single, __c2fb_double_value(Cast(Double, (local1 + __c2fb_double_value(Cast(Double, (local2 * geopolySine(local6))))))))
        (*c2fb_temp_15) = c2fb_temp_16
    c2fb_flow_1:
        c2fb_temp_12 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, CPtr(UByte Ptr, (@local5->hdr(0)))), Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL)) + Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 8ULL)) * local3)))), (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
    sqlite3_free(CPtr(Any Ptr, local5))
End Sub
Private Function geopolyBBox CDecl Alias "geopolyBBox" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_sqlite3_value Ptr, ByVal arg2 As c2fb_RtreeCoord Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_GeoPoly Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 634
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As c2fb_GeoPoly Ptr
    Dim local2 As Single
    Dim local3 As Single
    Dim local4 As Single
    Dim local5 As Single
    Dim c2fb_temp_0 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_1 As Single
    Dim c2fb_temp_2 As Single
    Dim c2fb_temp_3 As Single
    Dim c2fb_temp_4 As Single
    Dim c2fb_temp_5 As c2fb_GeoPoly Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_6 As Single
    Dim c2fb_temp_7 As Single
    Dim c2fb_temp_8 As Single
    Dim c2fb_temp_9 As Single
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local7 As Double
    Dim c2fb_temp_12 As Single
    Dim c2fb_temp_13 As Single
    Dim c2fb_temp_14 As Double
    Dim c2fb_temp_15 As Single
    Dim c2fb_temp_16 As Single
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_20 As c2fb_c_int Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Long Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As UByte Ptr
    Dim c2fb_temp_26 As UByte
    Dim c2fb_temp_27 As UByte Ptr
    Dim c2fb_temp_28 As UByte
    Dim c2fb_temp_29 As UByte Ptr
    Dim c2fb_temp_30 As UByte
    Dim c2fb_temp_31 As UByte Ptr
    Dim c2fb_temp_32 As UByte
    Dim c2fb_temp_33 As Single Ptr
    Dim c2fb_temp_34 As Single
    Dim c2fb_temp_35 As Single Ptr
    Dim c2fb_temp_36 As Single
    Dim c2fb_temp_37 As Single Ptr
    Dim c2fb_temp_38 As Single
    Dim c2fb_temp_39 As Single Ptr
    Dim c2fb_temp_40 As Single
    Dim c2fb_temp_41 As Single Ptr
    Dim c2fb_temp_42 As Single
    Dim c2fb_temp_43 As Single Ptr
    Dim c2fb_temp_44 As Single
    Dim c2fb_temp_45 As Single Ptr
    Dim c2fb_temp_46 As Single
    Dim c2fb_temp_47 As Single Ptr
    Dim c2fb_temp_48 As Single
    Dim c2fb_temp_49 As c2fb_RtreeValue Ptr
    Dim c2fb_temp_50 As Single
    Dim c2fb_temp_51 As c2fb_RtreeValue Ptr
    Dim c2fb_temp_52 As Single
    Dim c2fb_temp_53 As c2fb_RtreeValue Ptr
    Dim c2fb_temp_54 As Single
    Dim c2fb_temp_55 As c2fb_RtreeValue Ptr
    Dim c2fb_temp_56 As Single
    Dim c2fb_temp_57 As Any Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_0
        c2fb_temp_1 = Cast(Single, CPtr(c2fb_RtreeCoord Ptr, arg2)[Cast(c2fb_c_int, &O0ULL)].f)
        local2 = c2fb_temp_1
        c2fb_temp_2 = Cast(Single, CPtr(c2fb_RtreeCoord Ptr, arg2)[Cast(c2fb_c_int, 1ULL)].f)
        local3 = c2fb_temp_2
        c2fb_temp_3 = Cast(Single, CPtr(c2fb_RtreeCoord Ptr, arg2)[Cast(c2fb_c_int, 2ULL)].f)
        local4 = c2fb_temp_3
        c2fb_temp_4 = Cast(Single, CPtr(c2fb_RtreeCoord Ptr, arg2)[Cast(c2fb_c_int, 3ULL)].f)
        local5 = c2fb_temp_4
        Goto c2fb_label_0
    Else
        c2fb_temp_5 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg1, arg3)))
        local1 = c2fb_temp_5
    End If
    If local1 Then
        ' C automatic storage declaration
        c2fb_temp_6 = Cast(Single, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local1)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL)))]))
        local3 = c2fb_temp_6
        c2fb_temp_7 = Cast(Single, c2fb_temp_6)
        local2 = c2fb_temp_7
        c2fb_temp_8 = Cast(Single, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local1)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
        local5 = c2fb_temp_8
        c2fb_temp_9 = Cast(Single, c2fb_temp_8)
        local4 = c2fb_temp_9
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local6 = c2fb_temp_10
        While (-Cast(c2fb_c_int, ((local6 < local1->nVertex))))
            local7 = ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local1)->a(0)))))[Cast(c2fb_c_int, ((local6) * Cast(c2fb_c_int, 2ULL)))])
            If (-Cast(c2fb_c_int, ((local7 < Cast(Double, local2))))) Then
                c2fb_temp_12 = Cast(Single, __c2fb_single_value(Cast(Single, local7)))
                local2 = c2fb_temp_12
            Else
                If (-Cast(c2fb_c_int, ((local7 > Cast(Double, local3))))) Then
                    c2fb_temp_13 = Cast(Single, __c2fb_single_value(Cast(Single, local7)))
                    local3 = c2fb_temp_13
                End If
            End If
            c2fb_temp_14 = Cast(Double, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local1)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local6) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
            local7 = c2fb_temp_14
            If (-Cast(c2fb_c_int, ((local7 < Cast(Double, local4))))) Then
                c2fb_temp_15 = Cast(Single, __c2fb_single_value(Cast(Single, local7)))
                local4 = c2fb_temp_15
            Else
                If (-Cast(c2fb_c_int, ((local7 > Cast(Double, local5))))) Then
                    c2fb_temp_16 = Cast(Single, __c2fb_single_value(Cast(Single, local7)))
                    local5 = c2fb_temp_16
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_11 = local6
            local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
        Wend
        c2fb_flow_0:
        If arg3 Then
            c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_17) = c2fb_temp_18
        End If
        If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_label_0:
            c2fb_temp_19 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local1), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_GeoPoly))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Single))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, 4ULL)) - Cast(c2fb_c_int, 4ULL)))))))))))))
            local0 = c2fb_temp_19
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                sqlite3_free(CPtr(Any Ptr, local1))
                If arg0 Then
                    sqlite3_result_error_nomem(CPtr(Any Ptr, arg0))
                End If
                If arg3 Then
                    c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                    c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    (*c2fb_temp_20) = c2fb_temp_21
                End If
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            c2fb_temp_22 = CPtr(Long Ptr, @(local0->nVertex))
            c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
            (*c2fb_temp_22) = Cast(Long, c2fb_temp_23)
            c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
            c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local6 = c2fb_temp_24
            c2fb_temp_25 = CPtr(UByte Ptr, @(local0->hdr(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_26 = Cast(UByte, (*CPtr(UByte Ptr, CPtr(c2fb_c_int Ptr, @(local6)))))
            (*c2fb_temp_25) = c2fb_temp_26
            c2fb_temp_27 = CPtr(UByte Ptr, @(local0->hdr(Cast(c2fb_c_int, 1ULL))))
            c2fb_temp_28 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_27) = c2fb_temp_28
            c2fb_temp_29 = CPtr(UByte Ptr, @(local0->hdr(Cast(c2fb_c_int, 2ULL))))
            c2fb_temp_30 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_29) = c2fb_temp_30
            c2fb_temp_31 = CPtr(UByte Ptr, @(local0->hdr(Cast(c2fb_c_int, 3ULL))))
            c2fb_temp_32 = Cast(UByte, Cast(c2fb_c_int, 4ULL))
            (*c2fb_temp_31) = c2fb_temp_32
            c2fb_temp_33 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL)))])))
            c2fb_temp_34 = Cast(Single, local2)
            (*c2fb_temp_33) = c2fb_temp_34
            c2fb_temp_35 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
            c2fb_temp_36 = Cast(Single, local4)
            (*c2fb_temp_35) = c2fb_temp_36
            c2fb_temp_37 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL)) * Cast(c2fb_c_int, 2ULL)))])))
            c2fb_temp_38 = Cast(Single, local3)
            (*c2fb_temp_37) = c2fb_temp_38
            c2fb_temp_39 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
            c2fb_temp_40 = Cast(Single, local4)
            (*c2fb_temp_39) = c2fb_temp_40
            c2fb_temp_41 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, 2ULL)) * Cast(c2fb_c_int, 2ULL)))])))
            c2fb_temp_42 = Cast(Single, local3)
            (*c2fb_temp_41) = c2fb_temp_42
            c2fb_temp_43 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, 2ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
            c2fb_temp_44 = Cast(Single, local5)
            (*c2fb_temp_43) = c2fb_temp_44
            c2fb_temp_45 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, 3ULL)) * Cast(c2fb_c_int, 2ULL)))])))
            c2fb_temp_46 = Cast(Single, local2)
            (*c2fb_temp_45) = c2fb_temp_46
            c2fb_temp_47 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, 3ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
            c2fb_temp_48 = Cast(Single, local5)
            (*c2fb_temp_47) = c2fb_temp_48
        Else
            sqlite3_free(CPtr(Any Ptr, local1))
            c2fb_temp_49 = CPtr(c2fb_RtreeValue Ptr, @(CPtr(c2fb_RtreeCoord Ptr, arg2)[Cast(c2fb_c_int, &O0ULL)].f))
            c2fb_temp_50 = Cast(Single, local2)
            (*c2fb_temp_49) = Cast(c2fb_RtreeValue, c2fb_temp_50)
            c2fb_temp_50 = Cast(Single, (*c2fb_temp_49))
            c2fb_temp_51 = CPtr(c2fb_RtreeValue Ptr, @(CPtr(c2fb_RtreeCoord Ptr, arg2)[Cast(c2fb_c_int, 1ULL)].f))
            c2fb_temp_52 = Cast(Single, local3)
            (*c2fb_temp_51) = Cast(c2fb_RtreeValue, c2fb_temp_52)
            c2fb_temp_52 = Cast(Single, (*c2fb_temp_51))
            c2fb_temp_53 = CPtr(c2fb_RtreeValue Ptr, @(CPtr(c2fb_RtreeCoord Ptr, arg2)[Cast(c2fb_c_int, 2ULL)].f))
            c2fb_temp_54 = Cast(Single, local4)
            (*c2fb_temp_53) = Cast(c2fb_RtreeValue, c2fb_temp_54)
            c2fb_temp_54 = Cast(Single, (*c2fb_temp_53))
            c2fb_temp_55 = CPtr(c2fb_RtreeValue Ptr, @(CPtr(c2fb_RtreeCoord Ptr, arg2)[Cast(c2fb_c_int, 3ULL)].f))
            c2fb_temp_56 = Cast(Single, local5)
            (*c2fb_temp_55) = Cast(c2fb_RtreeValue, c2fb_temp_56)
            c2fb_temp_56 = Cast(Single, (*c2fb_temp_55))
        End If
    Else
        If arg2 Then
            c2fb_temp_57 = CPtr(Any Ptr, sqlite3WhereMemset(CPtr(Any Ptr, arg2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_RtreeCoord))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))))))
        End If
    End If
    Return local0
End Function
Private Sub geopolyBBoxFunc CDecl Alias "geopolyBBoxFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 705
    Dim local0 As c2fb_GeoPoly Ptr

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyBBox(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
    ' C unused-parameter annotation
    If local0 Then
        c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, CPtr(UByte Ptr, (@local0->hdr(0)))), Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) * local0->nVertex)))), (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Sub geopolyBBoxStep CDecl Alias "geopolyBBoxStep" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 732
    Dim local0(0 To 3) As c2fb_RtreeCoord
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_GeoPoly Ptr
    Dim local2 As c2fb_GeoBBox Ptr
    Dim c2fb_temp_1 As c2fb_GeoBBox Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_RtreeCoord_ Ptr
    Dim c2fb_temp_6 As c2fb_RtreeCoord
    Dim c2fb_temp_7 As c2fb_RtreeCoord_ Ptr
    Dim c2fb_temp_8 As c2fb_RtreeCoord
    Dim c2fb_temp_9 As c2fb_RtreeCoord_ Ptr
    Dim c2fb_temp_10 As c2fb_RtreeCoord
    Dim c2fb_temp_11 As c2fb_RtreeCoord_ Ptr
    Dim c2fb_temp_12 As c2fb_RtreeCoord

    ' C automatic array storage
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_GeoPoly Ptr, geopolyBBox(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], CPtr(c2fb_RtreeCoord Ptr, (@local0(0))), CPtr(c2fb_c_int Ptr, @(local1))))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_GeoBBox Ptr, CPtr(c2fb_GeoBBox Ptr, CPtr(Any Ptr, sqlite3_aggregate_context(CPtr(Any Ptr, arg0), Cast(c2fb_size_t, SizeOf(c2fb_GeoBBox))))))
        local2 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return
        End If
        If (-Cast(c2fb_c_int, ((local2->isInit = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(Long Ptr, @(local2->isInit))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            c2fb_temp_4 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, CPtr(c2fb_RtreeCoord Ptr, (@local2->a(0)))), CPtr(Const Any Ptr, CPtr(c2fb_RtreeCoord Ptr, (@local0(0)))), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_RtreeCoord))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))))))
        Else
            If (-Cast(c2fb_c_int, ((local0(Cast(c2fb_c_int, &O0ULL)).f < local2->a(Cast(c2fb_c_int, &O0ULL)).f)))) Then
                c2fb_temp_5 = CPtr(c2fb_RtreeCoord_ Ptr, @(local2->a(Cast(c2fb_c_int, &O0ULL))))
                c2fb_temp_6 = local0(Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_5) = Cast(c2fb_RtreeCoord_, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_RtreeCoord, (*c2fb_temp_5))
            End If
            If (-Cast(c2fb_c_int, ((local0(Cast(c2fb_c_int, 1ULL)).f > local2->a(Cast(c2fb_c_int, 1ULL)).f)))) Then
                c2fb_temp_7 = CPtr(c2fb_RtreeCoord_ Ptr, @(local2->a(Cast(c2fb_c_int, 1ULL))))
                c2fb_temp_8 = local0(Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_7) = Cast(c2fb_RtreeCoord_, c2fb_temp_8)
                c2fb_temp_8 = Cast(c2fb_RtreeCoord, (*c2fb_temp_7))
            End If
            If (-Cast(c2fb_c_int, ((local0(Cast(c2fb_c_int, 2ULL)).f < local2->a(Cast(c2fb_c_int, 2ULL)).f)))) Then
                c2fb_temp_9 = CPtr(c2fb_RtreeCoord_ Ptr, @(local2->a(Cast(c2fb_c_int, 2ULL))))
                c2fb_temp_10 = local0(Cast(c2fb_c_int, 2ULL))
                (*c2fb_temp_9) = Cast(c2fb_RtreeCoord_, c2fb_temp_10)
                c2fb_temp_10 = Cast(c2fb_RtreeCoord, (*c2fb_temp_9))
            End If
            If (-Cast(c2fb_c_int, ((local0(Cast(c2fb_c_int, 3ULL)).f > local2->a(Cast(c2fb_c_int, 3ULL)).f)))) Then
                c2fb_temp_11 = CPtr(c2fb_RtreeCoord_ Ptr, @(local2->a(Cast(c2fb_c_int, 3ULL))))
                c2fb_temp_12 = local0(Cast(c2fb_c_int, 3ULL))
                (*c2fb_temp_11) = Cast(c2fb_RtreeCoord_, c2fb_temp_12)
                c2fb_temp_12 = Cast(c2fb_RtreeCoord, (*c2fb_temp_11))
            End If
        End If
    End If
End Sub
Private Sub geopolyBBoxFinal CDecl Alias "geopolyBBoxFinal" (ByVal arg0 As c2fb_sqlite3_context Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 756
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As c2fb_GeoBBox Ptr
    Dim c2fb_temp_0 As c2fb_GeoBBox Ptr
    Dim c2fb_temp_1 As c2fb_GeoPoly Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_GeoBBox Ptr, CPtr(c2fb_GeoBBox Ptr, CPtr(Any Ptr, sqlite3_aggregate_context(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, &O0ULL)))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, CPtr(c2fb_GeoPoly Ptr, geopolyBBox(arg0, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_RtreeCoord Ptr, (@local1->a(0))), Cast(c2fb_c_int, &O0ULL))))
    local0 = c2fb_temp_1
    If local0 Then
        c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, CPtr(UByte Ptr, (@local0->hdr(0)))), Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) * local0->nVertex)))), (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Function pointBeneathLine CDecl Alias "pointBeneathLine" (ByVal arg0 As Double, ByVal arg1 As Double, ByVal arg2 As Double, ByVal arg3 As Double, ByVal arg4 As Double, ByVal arg5 As Double) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 786
    Dim local0 As Double
    Dim c2fb_temp_0 As Double

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 = arg2)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 = arg3)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 2ULL)
    End If
    If (-Cast(c2fb_c_int, ((arg2 < arg4)))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 <= arg2)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0 > arg4)))) <> 0))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    Else
        If (-Cast(c2fb_c_int, ((arg2 > arg4)))) Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 <= arg4)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0 > arg2)))) <> 0))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        Else
            If (-Cast(c2fb_c_int, ((arg0 <> arg2)))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 < arg5)))) <> 0))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 > arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 > arg5)))) <> 0))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            Return Cast(c2fb_c_int, 2ULL)
        End If
    End If
    c2fb_temp_0 = Cast(Double, __c2fb_double_value(Cast(Double, (arg3 + __c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, ((__c2fb_double_value(Cast(Double, (arg5 - arg3)))) * (__c2fb_double_value(Cast(Double, (arg0 - arg2))))))) / (__c2fb_double_value(Cast(Double, (arg4 - arg2)))))))))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg1 = local0)))) Then
        Return Cast(c2fb_c_int, 2ULL)
    End If
    If (-Cast(c2fb_c_int, ((arg1 < local0)))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub geopolyContainsPointFunc CDecl Alias "geopolyContainsPointFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 817
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As Double
    Dim local2 As Double
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL)))
    local1 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 1ULL)])
    local2 = geopolyValueDouble(arg2[Cast(c2fb_c_int, 2ULL)])
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local5 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local5 < Cast(c2fb_c_int, (local0->nVertex - Cast(c2fb_c_int, 1ULL)))))))
        c2fb_temp_2 = Cast(c2fb_c_int, pointBeneathLine(local1, local2, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local5) * Cast(c2fb_c_int, 2ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local5) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL)))) * Cast(c2fb_c_int, 2ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL)))) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
        local3 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 2ULL))))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + local3)))
        local4 = c2fb_temp_3
    c2fb_flow_1:
        c2fb_temp_1 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 2ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, pointBeneathLine(local1, local2, ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((local5) * Cast(c2fb_c_int, 2ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((local5) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL)))]), ((CPtr(Single Ptr, CPtr(Single Ptr, (@(local0)->a(0)))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))])))
        local3 = c2fb_temp_4
    End If
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 2ULL))))) Then
        sqlite3_result_int(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, 1ULL))
    Else
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local3 + local4))) And Cast(c2fb_c_int, 1ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
            sqlite3_result_int(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, &O0ULL))
        Else
            sqlite3_result_int(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, 2ULL))
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local0))
End Sub
Private Sub geopolyWithinFunc CDecl Alias "geopolyWithinFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 862
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As c2fb_GeoPoly Ptr
    Dim local2 As c2fb_c_int

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL)))
    local1 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, 1ULL)], Cast(c2fb_c_int, &O0ULL)))
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso (local1 <> 0))))) Then
        local2 = geopolyOverlap(local0, local1)
        If (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, &O0ULL))))) Then
            sqlite3_result_error_nomem(CPtr(Any Ptr, arg0))
        Else
            sqlite3_result_int(CPtr(Any Ptr, arg0), IIf((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 2ULL))))), Cast(c2fb_c_int, 1ULL), IIf((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 4ULL))))), Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, &O0ULL))))
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local0))
    sqlite3_free(CPtr(Any Ptr, local1))
End Sub
Private Sub geopolyAddOneSegment CDecl Alias "geopolyAddOneSegment" (ByVal arg0 As c2fb_GeoOverlap Ptr, ByVal arg1 As Single, ByVal arg2 As Single, ByVal arg3 As Single, ByVal arg4 As Single, ByVal arg5 As UByte, ByVal arg6 As c2fb_c_uint)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 910
    Dim local0 As c2fb_GeoSegment Ptr
    Dim local1 As c2fb_GeoEvent Ptr
    Dim local2 As Single
    Dim c2fb_temp_0 As Single
    Dim c2fb_temp_1 As Single
    Dim c2fb_temp_2 As Single
    Dim c2fb_temp_3 As Single
    Dim c2fb_temp_4 As Single
    Dim c2fb_temp_5 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Double Ptr
    Dim c2fb_temp_9 As Double
    Dim c2fb_temp_10 As Double Ptr
    Dim c2fb_temp_11 As Double
    Dim c2fb_temp_12 As Single Ptr
    Dim c2fb_temp_13 As Single
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As UByte
    Dim c2fb_temp_16 As ULong Ptr
    Dim c2fb_temp_17 As c2fb_c_uint
    Dim c2fb_temp_18 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Double Ptr
    Dim c2fb_temp_22 As Double
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_26 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_27 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_28 As Long Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As Double Ptr
    Dim c2fb_temp_31 As Double
    Dim c2fb_temp_32 As Long Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_35 As c2fb_GeoSegment Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg1 = arg3)))) Then
        Return
    End If
    If (-Cast(c2fb_c_int, ((arg1 > arg3)))) Then
        local2 = arg1
        c2fb_temp_0 = Cast(Single, arg3)
        arg1 = c2fb_temp_0
        c2fb_temp_1 = Cast(Single, local2)
        arg3 = c2fb_temp_1
        c2fb_temp_2 = Cast(Single, arg2)
        local2 = c2fb_temp_2
        c2fb_temp_3 = Cast(Single, arg4)
        arg2 = c2fb_temp_3
        c2fb_temp_4 = Cast(Single, local2)
        arg4 = c2fb_temp_4
    End If
    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, (CPtr(c2fb_GeoSegment Ptr, arg0->aSegment) + arg0->nSegment)))
    local0 = c2fb_temp_5
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->nSegment))
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    (*c2fb_temp_6) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
    c2fb_temp_8 = CPtr(Double Ptr, @(local0->C))
    c2fb_temp_9 = Cast(Double, __c2fb_single_value(Cast(Single, ((__c2fb_single_value(Cast(Single, (arg4 - arg2)))) / (__c2fb_single_value(Cast(Single, (arg3 - arg1))))))))
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(Double Ptr, @(local0->B))
    c2fb_temp_11 = Cast(Double, __c2fb_double_value(Cast(Double, (Cast(Double, arg4) - __c2fb_double_value(Cast(Double, (Cast(Double, arg3) * local0->C)))))))
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(Single Ptr, @(local0->y0))
    c2fb_temp_13 = Cast(Single, arg2)
    (*c2fb_temp_12) = c2fb_temp_13
    c2fb_temp_14 = CPtr(UByte Ptr, @(local0->side))
    c2fb_temp_15 = Cast(UByte, arg5)
    (*c2fb_temp_14) = c2fb_temp_15
    c2fb_temp_16 = CPtr(ULong Ptr, @(local0->idx))
    c2fb_temp_17 = Cast(c2fb_c_uint, arg6)
    (*c2fb_temp_16) = Cast(ULong, c2fb_temp_17)
    c2fb_temp_17 = Cast(c2fb_c_uint, (*c2fb_temp_16))
    c2fb_temp_18 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, (CPtr(c2fb_GeoEvent Ptr, arg0->aEvent) + arg0->nEvent)))
    local1 = c2fb_temp_18
    c2fb_temp_19 = CPtr(Long Ptr, @(arg0->nEvent))
    c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
    (*c2fb_temp_19) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 + 1)))
    c2fb_temp_21 = CPtr(Double Ptr, @(local1->x))
    c2fb_temp_22 = Cast(Double, arg1)
    (*c2fb_temp_21) = c2fb_temp_22
    c2fb_temp_23 = CPtr(Long Ptr, @(local1->eType))
    c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
    c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
    c2fb_temp_25 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local1->pSeg))
    c2fb_temp_26 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local0)
    (*c2fb_temp_25) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_26)
    c2fb_temp_26 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_25))
    c2fb_temp_27 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, (CPtr(c2fb_GeoEvent Ptr, arg0->aEvent) + arg0->nEvent)))
    local1 = c2fb_temp_27
    c2fb_temp_28 = CPtr(Long Ptr, @(arg0->nEvent))
    c2fb_temp_29 = Cast(c2fb_c_int, (*c2fb_temp_28))
    (*c2fb_temp_28) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_29 + 1)))
    c2fb_temp_30 = CPtr(Double Ptr, @(local1->x))
    c2fb_temp_31 = Cast(Double, arg3)
    (*c2fb_temp_30) = c2fb_temp_31
    c2fb_temp_32 = CPtr(Long Ptr, @(local1->eType))
    c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_32) = Cast(Long, c2fb_temp_33)
    c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
    c2fb_temp_34 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local1->pSeg))
    c2fb_temp_35 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local0)
    (*c2fb_temp_34) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_35)
    c2fb_temp_35 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_34))
End Sub
Private Sub geopolyAddSegments CDecl Alias "geopolyAddSegments" (ByVal arg0 As c2fb_GeoOverlap Ptr, ByVal arg1 As c2fb_GeoPoly Ptr, ByVal arg2 As UByte)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 954
    Dim local0 As c2fb_c_uint
    Dim local1 As Single Ptr
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As Single Ptr
    Dim c2fb_temp_3 As Single Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg1->nVertex) - Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))))))
        c2fb_temp_2 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg1)->a(0)))))[Cast(c2fb_c_uint, ((local0) * Cast(c2fb_c_uint, Cast(c2fb_c_int, 2ULL))))])))
        local1 = c2fb_temp_2
        geopolyAddOneSegment(arg0, local1[Cast(c2fb_c_int, &O0ULL)], local1[Cast(c2fb_c_int, 1ULL)], local1[Cast(c2fb_c_int, 2ULL)], local1[Cast(c2fb_c_int, 3ULL)], arg2, local0)
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(Single Ptr, @(((CPtr(Single Ptr, CPtr(Single Ptr, (@(arg1)->a(0)))))[Cast(c2fb_c_uint, ((local0) * Cast(c2fb_c_uint, Cast(c2fb_c_int, 2ULL))))])))
    local1 = c2fb_temp_3
    geopolyAddOneSegment(arg0, local1[Cast(c2fb_c_int, &O0ULL)], local1[Cast(c2fb_c_int, 1ULL)], arg1->a(Cast(c2fb_c_int, &O0ULL)), arg1->a(Cast(c2fb_c_int, 1ULL)), arg2, local0)
End Sub
Private Function geopolyEventMerge CDecl Alias "geopolyEventMerge" (ByVal arg0 As c2fb_GeoEvent Ptr, ByVal arg1 As c2fb_GeoEvent Ptr) As c2fb_GeoEvent Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 972
    Dim local0 As c2fb_GeoEvent
    Dim local1 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_0 As c2fb_GeoEvent_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_2 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_3 As c2fb_GeoEvent_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_5 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_6 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_7 As c2fb_GeoEvent_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_9 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_10 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_11 As c2fb_GeoEvent_ Ptr Ptr
    Dim c2fb_temp_12 As c2fb_GeoEvent Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_GeoEvent_ Ptr Ptr, @(local0.pNext))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = CPtr(c2fb_GeoEvent_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_GeoEvent Ptr, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, @(local0)))
    local1 = c2fb_temp_2
    While (-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso (arg0 <> 0)))))
        If (-Cast(c2fb_c_int, ((arg1->x <= arg0->x)))) Then
            c2fb_temp_3 = CPtr(c2fb_GeoEvent_ Ptr Ptr, @(local1->pNext))
            c2fb_temp_4 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, arg1)
            (*c2fb_temp_3) = CPtr(c2fb_GeoEvent_ Ptr, c2fb_temp_4)
            c2fb_temp_4 = CPtr(c2fb_GeoEvent Ptr, (*c2fb_temp_3))
            c2fb_temp_5 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, arg1)
            local1 = c2fb_temp_5
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, arg1->pNext))
            arg1 = c2fb_temp_6
        Else
            c2fb_temp_7 = CPtr(c2fb_GeoEvent_ Ptr Ptr, @(local1->pNext))
            c2fb_temp_8 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, arg0)
            (*c2fb_temp_7) = CPtr(c2fb_GeoEvent_ Ptr, c2fb_temp_8)
            c2fb_temp_8 = CPtr(c2fb_GeoEvent Ptr, (*c2fb_temp_7))
            c2fb_temp_9 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, arg0)
            local1 = c2fb_temp_9
            c2fb_temp_10 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, arg0->pNext))
            arg0 = c2fb_temp_10
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_11 = CPtr(c2fb_GeoEvent_ Ptr Ptr, @(local1->pNext))
    c2fb_temp_12 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, IIf(arg1, arg1, arg0))
    (*c2fb_temp_11) = CPtr(c2fb_GeoEvent_ Ptr, c2fb_temp_12)
    c2fb_temp_12 = CPtr(c2fb_GeoEvent Ptr, (*c2fb_temp_11))
    Return CPtr(c2fb_GeoEvent Ptr, local0.pNext)
End Function
Private Function geopolySortEventsByX CDecl Alias "geopolySortEventsByX" (ByVal arg0 As c2fb_GeoEvent Ptr, ByVal arg1 As c2fb_c_int) As c2fb_GeoEvent Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 994
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_GeoEvent Ptr
    Dim local4(0 To 49) As c2fb_GeoEvent Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_3 As c2fb_GeoEvent_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_8 As c2fb_GeoEvent Ptr Ptr
    Dim c2fb_temp_9 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_10 As c2fb_GeoEvent Ptr Ptr
    Dim c2fb_temp_11 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_GeoEvent Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic array storage
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < arg1))))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, @(CPtr(c2fb_GeoEvent Ptr, arg0)[local1])))
        local3 = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_GeoEvent_ Ptr Ptr, @(local3->pNext))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_3) = CPtr(c2fb_GeoEvent_ Ptr, c2fb_temp_4)
        c2fb_temp_4 = CPtr(c2fb_GeoEvent Ptr, (*c2fb_temp_3))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_5
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < local0)))) <> 0) AndAlso (local4(local2) <> 0)))))
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, geopolyEventMerge(local4(local2), local3)))
            local3 = c2fb_temp_7
            c2fb_temp_8 = CPtr(c2fb_GeoEvent Ptr Ptr, @(local4(local2)))
            c2fb_temp_9 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_8) = c2fb_temp_9
        c2fb_flow_3:
            c2fb_temp_6 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_temp_10 = CPtr(c2fb_GeoEvent Ptr Ptr, @(local4(local2)))
        c2fb_temp_11 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, local3)
        (*c2fb_temp_10) = c2fb_temp_11
        If (-Cast(c2fb_c_int, ((local2 >= local0)))) Then
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))))
            local0 = c2fb_temp_12
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_13 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    local3 = c2fb_temp_13
    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_14
    While (-Cast(c2fb_c_int, ((local1 < local0))))
        c2fb_temp_16 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, geopolyEventMerge(local4(local1), local3)))
        local3 = c2fb_temp_16
    c2fb_flow_5:
        c2fb_temp_15 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
    Wend
    c2fb_flow_4:
    Return local3
End Function
Private Function geopolySegmentMerge CDecl Alias "geopolySegmentMerge" (ByVal arg0 As c2fb_GeoSegment Ptr, ByVal arg1 As c2fb_GeoSegment Ptr) As c2fb_GeoSegment Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1019
    Dim local0 As c2fb_GeoSegment
    Dim local1 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_0 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_2 As c2fb_GeoSegment Ptr
    Dim local2 As Double
    Dim c2fb_temp_3 As Double
    Dim c2fb_temp_4 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_6 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_7 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_8 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_10 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_11 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_12 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_13 As c2fb_GeoSegment Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local0.pNext))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, @(local0)))
    local1 = c2fb_temp_2
    While (-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso (arg0 <> 0)))))
        local2 = __c2fb_double_value(Cast(Double, (arg1->y - arg0->y)))
        If (-Cast(c2fb_c_int, ((local2 = 0.0#)))) Then
            c2fb_temp_3 = Cast(Double, __c2fb_double_value(Cast(Double, (arg1->C - arg0->C))))
            local2 = c2fb_temp_3
        End If
        If (-Cast(c2fb_c_int, ((local2 < 0.0#)))) Then
            c2fb_temp_4 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local1->pNext))
            c2fb_temp_5 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, arg1)
            (*c2fb_temp_4) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_5)
            c2fb_temp_5 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_4))
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, arg1)
            local1 = c2fb_temp_6
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, arg1->pNext))
            arg1 = c2fb_temp_7
        Else
            c2fb_temp_8 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local1->pNext))
            c2fb_temp_9 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, arg0)
            (*c2fb_temp_8) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_9)
            c2fb_temp_9 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_8))
            c2fb_temp_10 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, arg0)
            local1 = c2fb_temp_10
            c2fb_temp_11 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, arg0->pNext))
            arg0 = c2fb_temp_11
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_12 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local1->pNext))
    c2fb_temp_13 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, IIf(arg1, arg1, arg0))
    (*c2fb_temp_12) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_13)
    c2fb_temp_13 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_12))
    Return CPtr(c2fb_GeoSegment Ptr, local0.pNext)
End Function
Private Function geopolySortSegmentsByYAndC CDecl Alias "geopolySortSegmentsByYAndC" (ByVal arg0 As c2fb_GeoSegment Ptr) As c2fb_GeoSegment Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1044
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_GeoSegment Ptr
    Dim local3(0 To 49) As c2fb_GeoSegment Ptr
    Dim c2fb_temp_0 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_1 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_2 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_3 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_7 As c2fb_GeoSegment Ptr Ptr
    Dim c2fb_temp_8 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_9 As c2fb_GeoSegment Ptr Ptr
    Dim c2fb_temp_10 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_GeoSegment Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic array storage
    While arg0
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, arg0)
        local2 = c2fb_temp_0
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, arg0->pNext))
        arg0 = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local2->pNext))
        c2fb_temp_3 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_2) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_3)
        c2fb_temp_3 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_2))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < local0)))) <> 0) AndAlso (local3(local1) <> 0)))))
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, geopolySegmentMerge(local3(local1), local2)))
            local2 = c2fb_temp_6
            c2fb_temp_7 = CPtr(c2fb_GeoSegment Ptr Ptr, @(local3(local1)))
            c2fb_temp_8 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_7) = c2fb_temp_8
        c2fb_flow_3:
            c2fb_temp_5 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_temp_9 = CPtr(c2fb_GeoSegment Ptr Ptr, @(local3(local1)))
        c2fb_temp_10 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local2)
        (*c2fb_temp_9) = c2fb_temp_10
        If (-Cast(c2fb_c_int, ((local1 >= local0)))) Then
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL))))
            local0 = c2fb_temp_11
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_12 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    local2 = c2fb_temp_12
    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_13
    While (-Cast(c2fb_c_int, ((local1 < local0))))
        c2fb_temp_15 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, geopolySegmentMerge(local3(local1), local2)))
        local2 = c2fb_temp_15
    c2fb_flow_5:
        c2fb_temp_14 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
    Wend
    c2fb_flow_4:
    Return local2
End Function
Private Function geopolyOverlap CDecl Alias "geopolyOverlap" (ByVal arg0 As c2fb_GeoPoly Ptr, ByVal arg1 As c2fb_GeoPoly Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1070
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_GeoOverlap Ptr
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_GeoEvent Ptr
    Dim local4 As Double
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_GeoSegment Ptr
    Dim local8 As c2fb_GeoSegment Ptr
    Dim local9(0 To 3) As UByte
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_GeoOverlap Ptr
    Dim c2fb_temp_2 As c2fb_GeoEvent_ Ptr Ptr
    Dim c2fb_temp_3 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_4 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_11 As Double
    Dim c2fb_temp_12 As Any Ptr
    Dim local10 As c2fb_GeoSegment Ptr
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_13 As Double
    Dim c2fb_temp_14 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_17 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_18 As UByte Ptr
    Dim c2fb_temp_19 As UByte
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_22 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_23 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_24 As c2fb_GeoSegment Ptr
    Dim local12 As Double
    Dim c2fb_temp_25 As Double Ptr
    Dim c2fb_temp_26 As Double
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As UByte Ptr
    Dim c2fb_temp_29 As UByte
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_32 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_33 As Double Ptr
    Dim c2fb_temp_34 As Double
    Dim c2fb_temp_35 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_36 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_37 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_40 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_41 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_42 As c2fb_GeoSegment_ Ptr Ptr
    Dim c2fb_temp_43 As c2fb_GeoSegment Ptr
    Dim c2fb_temp_44 As c2fb_GeoEvent Ptr
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_c_int

    local0 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0->nVertex + arg1->nVertex)) + Cast(c2fb_c_int, 2ULL)))
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic array storage
    c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_GeoEvent))) * Cast(c2fb_uint64, local0))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_GeoSegment))) * Cast(c2fb_uint64, local0))))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_GeoOverlap))))))
    local2 = c2fb_temp_0
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_GeoOverlap Ptr, CPtr(Any Ptr, sqlite3_malloc64(local2)))
    local1 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    End If
    c2fb_temp_2 = CPtr(c2fb_GeoEvent_ Ptr Ptr, @(local1->aEvent))
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, CPtr(c2fb_GeoOverlap Ptr, @(CPtr(c2fb_GeoOverlap Ptr, local1)[Cast(c2fb_c_int, 1ULL)]))))
    (*c2fb_temp_2) = CPtr(c2fb_GeoEvent_ Ptr, c2fb_temp_3)
    c2fb_temp_3 = CPtr(c2fb_GeoEvent Ptr, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local1->aSegment))
    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, CPtr(c2fb_GeoEvent Ptr, @(CPtr(c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, local1->aEvent))[Cast(c2fb_int64, (local0 * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))]))))
    (*c2fb_temp_4) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_4))
    c2fb_temp_8 = CPtr(Long Ptr, @(local1->nEvent))
    c2fb_temp_6 = CPtr(Long Ptr, @(local1->nSegment))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    c2fb_temp_9 = Cast(c2fb_c_int, c2fb_temp_7)
    (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
    c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
    geopolyAddSegments(local1, arg0, Cast(c2fb_c_int, 1ULL))
    geopolyAddSegments(local1, arg1, Cast(c2fb_c_int, 2ULL))
    c2fb_temp_10 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, geopolySortEventsByX(CPtr(c2fb_GeoEvent Ptr, local1->aEvent), local1->nEvent)))
    local3 = c2fb_temp_10
    c2fb_temp_11 = Cast(Double, IIf((-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3->x = 0.0#)))) <> 0))))), __c2fb_double_value(Cast(Double, (-1.0#))), 0.0#))
    local4 = c2fb_temp_11
    c2fb_temp_12 = CPtr(Any Ptr, sqlite3WhereMemset(CPtr(Any Ptr, CPtr(UByte Ptr, (@local9(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, (4ULL * SizeOf(UByte)))))
    While local3
        If (-Cast(c2fb_c_int, ((local3->x <> local4)))) Then
            local10 = Cast(c2fb_c_int, &O0ULL)
            local11 = Cast(c2fb_c_int, &O0ULL)
            ' empty C statement
            c2fb_temp_13 = Cast(Double, local3->x)
            local4 = c2fb_temp_13
            If local6 Then
                ' empty C statement
                c2fb_temp_14 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, geopolySortSegmentsByYAndC(local7)))
                local7 = c2fb_temp_14
                c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local6 = c2fb_temp_15
            End If
            c2fb_temp_16 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local7)
            local8 = c2fb_temp_16
            While local8
                If local10 Then
                    If (-Cast(c2fb_c_int, ((local10->y <> local8->y)))) Then
                        ' empty C statement
                        c2fb_temp_18 = CPtr(UByte Ptr, @(local9(local11)))
                        c2fb_temp_19 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                        (*c2fb_temp_18) = c2fb_temp_19
                    End If
                End If
                c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local11 Xor Cast(c2fb_c_int, local8->side))))
                local11 = c2fb_temp_20
                c2fb_temp_21 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local8)
                local10 = c2fb_temp_21
            c2fb_flow_3:
                c2fb_temp_17 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, local8->pNext))
                local8 = c2fb_temp_17
            Wend
            c2fb_flow_2:
            c2fb_temp_22 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local10 = c2fb_temp_22
            c2fb_temp_23 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local7)
            local8 = c2fb_temp_23
            While local8
                local12 = __c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, (local8->C * local4))) + local8->B)))
                ' empty C statement
                c2fb_temp_25 = CPtr(Double Ptr, @(local8->y))
                c2fb_temp_26 = Cast(Double, local12)
                (*c2fb_temp_25) = c2fb_temp_26
                If local10 Then
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local10->y > local8->y)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local10->side) <> Cast(c2fb_c_int, local8->side))))) <> 0))))) Then
                        c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local5 = c2fb_temp_27
                        ' empty C statement
                        Goto c2fb_label_0
                    Else
                        If (-Cast(c2fb_c_int, ((local10->y <> local8->y)))) Then
                            ' empty C statement
                            c2fb_temp_28 = CPtr(UByte Ptr, @(local9(local11)))
                            c2fb_temp_29 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                            (*c2fb_temp_28) = c2fb_temp_29
                        End If
                    End If
                End If
                c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local11 Xor Cast(c2fb_c_int, local8->side))))
                local11 = c2fb_temp_30
                c2fb_temp_31 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local8)
                local10 = c2fb_temp_31
            c2fb_flow_5:
                c2fb_temp_24 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, local8->pNext))
                local8 = c2fb_temp_24
            Wend
            c2fb_flow_4:
        End If
        ' empty C statement
        If (-Cast(c2fb_c_int, ((local3->eType = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_32 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, local3->pSeg))
            local8 = c2fb_temp_32
            c2fb_temp_33 = CPtr(Double Ptr, @(local8->y))
            c2fb_temp_34 = Cast(Double, local8->y0)
            (*c2fb_temp_33) = c2fb_temp_34
            c2fb_temp_35 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local8->pNext))
            c2fb_temp_36 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local7)
            (*c2fb_temp_35) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_36)
            c2fb_temp_36 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_35))
            c2fb_temp_37 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local8)
            local7 = c2fb_temp_37
            c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local6 = c2fb_temp_38
        Else
            If (-Cast(c2fb_c_int, ((local7 = CPtr(c2fb_GeoSegment Ptr, local3->pSeg))))) Then
                c2fb_temp_39 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, IIf((local7), CPtr(c2fb_GeoSegment Ptr, local7->pNext), CPtr(c2fb_GeoSegment Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
                local7 = c2fb_temp_39
            Else
                c2fb_temp_40 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, local7)
                local8 = c2fb_temp_40
                While local8
                    If (-Cast(c2fb_c_int, ((CPtr(c2fb_GeoSegment Ptr, local8->pNext) = CPtr(c2fb_GeoSegment Ptr, local3->pSeg))))) Then
                        c2fb_temp_42 = CPtr(c2fb_GeoSegment_ Ptr Ptr, @(local8->pNext))
                        c2fb_temp_43 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, IIf((CPtr(c2fb_GeoSegment Ptr, local8->pNext)), CPtr(c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, local8->pNext)->pNext), CPtr(c2fb_GeoSegment Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
                        (*c2fb_temp_42) = CPtr(c2fb_GeoSegment_ Ptr, c2fb_temp_43)
                        c2fb_temp_43 = CPtr(c2fb_GeoSegment Ptr, (*c2fb_temp_42))
                        Goto c2fb_flow_6
                    End If
                c2fb_flow_7:
                    c2fb_temp_41 = CPtr(_c2fb_record_c2fb_GeoSegment Ptr, CPtr(c2fb_GeoSegment Ptr, local8->pNext))
                    local8 = c2fb_temp_41
                Wend
                c2fb_flow_6:
            End If
        End If
        c2fb_temp_44 = CPtr(_c2fb_record_c2fb_GeoEvent Ptr, CPtr(c2fb_GeoEvent Ptr, local3->pNext))
        local3 = c2fb_temp_44
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9(Cast(c2fb_c_int, 3ULL))) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_45 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local5 = c2fb_temp_45
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9(Cast(c2fb_c_int, 1ULL))) <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9(Cast(c2fb_c_int, 2ULL))) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_46 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
            local5 = c2fb_temp_46
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9(Cast(c2fb_c_int, 1ULL))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9(Cast(c2fb_c_int, 2ULL))) <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                local5 = c2fb_temp_47
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9(Cast(c2fb_c_int, 1ULL))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9(Cast(c2fb_c_int, 2ULL))) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_48 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
                    local5 = c2fb_temp_48
                Else
                    c2fb_temp_49 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local5 = c2fb_temp_49
                End If
            End If
        End If
    End If
    c2fb_label_0:
    sqlite3_free(CPtr(Any Ptr, local1))
    Return local5
End Function
Private Sub geopolyOverlapFunc CDecl Alias "geopolyOverlapFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1193
    Dim local0 As c2fb_GeoPoly Ptr
    Dim local1 As c2fb_GeoPoly Ptr
    Dim local2 As c2fb_c_int

    local0 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, &O0ULL)], Cast(c2fb_c_int, &O0ULL)))
    local1 = CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(arg0, arg2[Cast(c2fb_c_int, 1ULL)], Cast(c2fb_c_int, &O0ULL)))
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso (local1 <> 0))))) Then
        local2 = geopolyOverlap(local0, local1)
        If (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, &O0ULL))))) Then
            sqlite3_result_error_nomem(CPtr(Any Ptr, arg0))
        Else
            sqlite3_result_int(CPtr(Any Ptr, arg0), local2)
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local0))
    sqlite3_free(CPtr(Any Ptr, local1))
End Sub
Private Sub geopolyDebugFunc CDecl Alias "geopolyDebugFunc" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1216
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
End Sub
' c2fb skipped geopolyInit: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 1239: geopolyInit: assignment parser stopped at byte 36 (pRtree->base.pModule = &rtreeModule):
Private Function geopolyCreate CDecl Alias "geopolyCreate" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_4 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1333
    Return geopolyInit(arg0, arg1, arg2, arg3, arg4, arg5, Cast(c2fb_c_int, 1ULL))
End Function
Private Function geopolyConnect CDecl Alias "geopolyConnect" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_source_record_4 Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1346
    Return geopolyInit(arg0, arg1, arg2, arg3, arg4, arg5, Cast(c2fb_c_int, &O0ULL))
End Function
Private Function geopolyFilter CDecl Alias "geopolyFilter" (ByVal arg0 As c2fb_source_record_5 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1369
    Dim local0 As c2fb_source_record_37 Ptr
    Dim local1 As c2fb_source_record_38 Ptr
    Dim local2 As c2fb_RtreeNode Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As c2fb_RtreeNode Ptr
    Dim local6 As c2fb_RtreeSearchPoint Ptr
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_RtreeSearchPoint Ptr
    Dim c2fb_temp_4 As c2fb_RtreeNode Ptr Ptr
    Dim c2fb_temp_5 As c2fb_RtreeNode Ptr
    Dim c2fb_temp_6 As c2fb_sqlite3_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_u8 Ptr
    Dim c2fb_temp_9 As UByte
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_u8 Ptr
    Dim c2fb_temp_12 As UByte
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local9(0 To 3) As c2fb_RtreeCoord
    Dim local10 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_16 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_17 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_18 As c2fb_RtreeConstraint Ptr Ptr
    Dim c2fb_temp_19 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_20 As c2fb_c_int Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As Any Ptr
    Dim c2fb_temp_24 As Any Ptr
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As Long Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_RtreeDValue Ptr
    Dim c2fb_temp_30 As Double
    Dim c2fb_temp_31 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_32 As Long Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As Long Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_RtreeDValue Ptr
    Dim c2fb_temp_37 As Double
    Dim c2fb_temp_38 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_39 As Long Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As Long Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_RtreeDValue Ptr
    Dim c2fb_temp_44 As Double
    Dim c2fb_temp_45 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_46 As Long Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As Long Ptr
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As c2fb_RtreeDValue Ptr
    Dim c2fb_temp_51 As Double
    Dim c2fb_temp_52 As Long Ptr
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As Long Ptr
    Dim c2fb_temp_55 As c2fb_c_int
    Dim c2fb_temp_56 As c2fb_RtreeDValue Ptr
    Dim c2fb_temp_57 As Double
    Dim c2fb_temp_58 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_59 As Long Ptr
    Dim c2fb_temp_60 As c2fb_c_int
    Dim c2fb_temp_61 As Long Ptr
    Dim c2fb_temp_62 As c2fb_c_int
    Dim c2fb_temp_63 As c2fb_RtreeDValue Ptr
    Dim c2fb_temp_64 As Double
    Dim c2fb_temp_65 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_66 As Long Ptr
    Dim c2fb_temp_67 As c2fb_c_int
    Dim c2fb_temp_68 As Long Ptr
    Dim c2fb_temp_69 As c2fb_c_int
    Dim c2fb_temp_70 As c2fb_RtreeDValue Ptr
    Dim c2fb_temp_71 As Double
    Dim c2fb_temp_72 As c2fb_RtreeConstraint Ptr
    Dim c2fb_temp_73 As Long Ptr
    Dim c2fb_temp_74 As c2fb_c_int
    Dim c2fb_temp_75 As Long Ptr
    Dim c2fb_temp_76 As c2fb_c_int
    Dim c2fb_temp_77 As c2fb_RtreeDValue Ptr
    Dim c2fb_temp_78 As Double
    Dim local11 As c2fb_RtreeSearchPoint Ptr
    Dim c2fb_temp_79 As c2fb_RtreeSearchPoint Ptr
    Dim c2fb_temp_80 As c2fb_c_int
    Dim c2fb_temp_81 As c2fb_sqlite3_int64 Ptr
    Dim c2fb_temp_82 As c2fb_int64
    Dim c2fb_temp_83 As c2fb_u8 Ptr
    Dim c2fb_temp_84 As UByte
    Dim c2fb_temp_85 As c2fb_u8 Ptr
    Dim c2fb_temp_86 As UByte
    Dim c2fb_temp_87 As c2fb_RtreeNode Ptr Ptr
    Dim c2fb_temp_88 As c2fb_RtreeNode Ptr
    Dim c2fb_temp_89 As c2fb_RtreeNode Ptr
    Dim c2fb_temp_90 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_37 Ptr, arg0->pVtab)
    local1 = CPtr(c2fb_source_record_38 Ptr, arg0)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    rtreeReference(CPtr(c2fb_source_record_23 Ptr, local0))
    resetCursor(CPtr(c2fb_source_record_25 Ptr, local1))
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(local1->iStrategy))
    c2fb_temp_1 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_0) = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        local7 = geopolyValueInt64(arg4[Cast(c2fb_c_int, &O0ULL)])
        local8 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_2 = Cast(c2fb_c_int, findLeafNode(CPtr(c2fb_source_record_23 Ptr, local0), local7, CPtr(SqliteRtreeNode Ptr Ptr, CPtr(c2fb_RtreeNode Ptr Ptr, @(local5))), CPtr(c2fb_int64 Ptr, @(local8))))
        local3 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_3 = CPtr(_c2fb_record_c2fb_RtreeSearchPoint Ptr, CPtr(c2fb_RtreeSearchPoint Ptr, rtreeSearchPointNew(CPtr(c2fb_source_record_25 Ptr, local1), 0.0#, Cast(c2fb_c_int, &O0ULL))))
            local6 = c2fb_temp_3
            ' C unused-parameter annotation
            c2fb_temp_4 = CPtr(c2fb_RtreeNode Ptr Ptr, @(local1->aNode(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_5 = CPtr(_c2fb_record_c2fb_RtreeNode Ptr, local5)
            (*c2fb_temp_4) = c2fb_temp_5
            c2fb_temp_6 = CPtr(c2fb_sqlite3_int64 Ptr, @(local6->id))
            c2fb_temp_7 = Cast(c2fb_int64, local8)
            (*c2fb_temp_6) = Cast(c2fb_sqlite3_int64, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
            c2fb_temp_8 = CPtr(c2fb_u8 Ptr, @(local6->eWithin))
            c2fb_temp_9 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_8) = Cast(c2fb_u8, c2fb_temp_9)
            c2fb_temp_9 = Cast(UByte, (*c2fb_temp_8))
            c2fb_temp_10 = Cast(c2fb_c_int, nodeRowidIndex(CPtr(c2fb_source_record_23 Ptr, local0), CPtr(SqliteRtreeNode Ptr, local5), local7, CPtr(c2fb_c_int Ptr, @(local4))))
            local3 = c2fb_temp_10
            c2fb_temp_11 = CPtr(c2fb_u8 Ptr, @(local6->iCell))
            c2fb_temp_12 = Cast(UByte, Cast(UByte, local4))
            (*c2fb_temp_11) = Cast(c2fb_u8, c2fb_temp_12)
            c2fb_temp_12 = Cast(UByte, (*c2fb_temp_11))
            ' empty C statement
        Else
            c2fb_temp_13 = CPtr(UByte Ptr, @(local1->atEOF))
            c2fb_temp_14 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_13) = c2fb_temp_14
        End If
    Else
        c2fb_temp_15 = Cast(c2fb_c_int, nodeAcquire(CPtr(c2fb_source_record_23 Ptr, local0), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL), CPtr(SqliteRtreeNode Ptr Ptr, CPtr(c2fb_RtreeNode Ptr Ptr, @(local2)))))
        local3 = c2fb_temp_15
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 <= Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
            ' C automatic array storage
            ' C automatic storage declaration
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            c2fb_temp_16 = CPtr(c2fb_GeoPoly Ptr, geopolyBBox(Cast(c2fb_c_int, &O0ULL), arg4[Cast(c2fb_c_int, &O0ULL)], CPtr(c2fb_RtreeCoord Ptr, (@local9(0))), CPtr(c2fb_c_int Ptr, @(local3))))
            If local3 Then
                Goto c2fb_label_0
            End If
            c2fb_temp_18 = CPtr(c2fb_RtreeConstraint Ptr Ptr, @(local1->aConstraint))
            c2fb_temp_17 = CPtr(_c2fb_record_c2fb_RtreeConstraint Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_RtreeConstraint))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL)))))))
            local10 = c2fb_temp_17
            c2fb_temp_19 = CPtr(_c2fb_record_c2fb_RtreeConstraint Ptr, c2fb_temp_17)
            (*c2fb_temp_18) = c2fb_temp_19
            c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @(local1->nConstraint))
            c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
            (*c2fb_temp_20) = c2fb_temp_21
            If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local3 = c2fb_temp_22
            Else
                c2fb_temp_23 = CPtr(Any Ptr, sqlite3WhereMemset(CPtr(Any Ptr, CPtr(c2fb_RtreeConstraint Ptr, local1->aConstraint)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_RtreeConstraint))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))))))
                c2fb_temp_24 = CPtr(Any Ptr, sqlite3WhereMemset(CPtr(Any Ptr, CPtr(c2fb_c_uint Ptr, (@local1->anQueue(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (local0->iDepth + Cast(c2fb_c_int, 1ULL)))))))))
                If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) Then
                    c2fb_temp_25 = CPtr(Long Ptr, @(local10->op))
                    c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, 66))
                    (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
                    c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
                    c2fb_temp_27 = CPtr(Long Ptr, @(local10->iCoord))
                    c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_27) = Cast(Long, c2fb_temp_28)
                    c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
                    c2fb_temp_29 = CPtr(c2fb_RtreeDValue Ptr, @(local10->u.rValue))
                    c2fb_temp_30 = Cast(Double, local9(Cast(c2fb_c_int, 1ULL)).f)
                    (*c2fb_temp_29) = Cast(c2fb_RtreeDValue, c2fb_temp_30)
                    c2fb_temp_30 = Cast(Double, (*c2fb_temp_29))
                    c2fb_temp_31 = local10
                    local10 = (c2fb_temp_31 + 1)
                    c2fb_temp_32 = CPtr(Long Ptr, @(local10->op))
                    c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, 68))
                    (*c2fb_temp_32) = Cast(Long, c2fb_temp_33)
                    c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
                    c2fb_temp_34 = CPtr(Long Ptr, @(local10->iCoord))
                    c2fb_temp_35 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_34) = Cast(Long, c2fb_temp_35)
                    c2fb_temp_35 = Cast(c2fb_c_int, (*c2fb_temp_34))
                    c2fb_temp_36 = CPtr(c2fb_RtreeDValue Ptr, @(local10->u.rValue))
                    c2fb_temp_37 = Cast(Double, local9(Cast(c2fb_c_int, &O0ULL)).f)
                    (*c2fb_temp_36) = Cast(c2fb_RtreeDValue, c2fb_temp_37)
                    c2fb_temp_37 = Cast(Double, (*c2fb_temp_36))
                    c2fb_temp_38 = local10
                    local10 = (c2fb_temp_38 + 1)
                    c2fb_temp_39 = CPtr(Long Ptr, @(local10->op))
                    c2fb_temp_40 = Cast(c2fb_c_int, Cast(c2fb_c_int, 66))
                    (*c2fb_temp_39) = Cast(Long, c2fb_temp_40)
                    c2fb_temp_40 = Cast(c2fb_c_int, (*c2fb_temp_39))
                    c2fb_temp_41 = CPtr(Long Ptr, @(local10->iCoord))
                    c2fb_temp_42 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                    (*c2fb_temp_41) = Cast(Long, c2fb_temp_42)
                    c2fb_temp_42 = Cast(c2fb_c_int, (*c2fb_temp_41))
                    c2fb_temp_43 = CPtr(c2fb_RtreeDValue Ptr, @(local10->u.rValue))
                    c2fb_temp_44 = Cast(Double, local9(Cast(c2fb_c_int, 3ULL)).f)
                    (*c2fb_temp_43) = Cast(c2fb_RtreeDValue, c2fb_temp_44)
                    c2fb_temp_44 = Cast(Double, (*c2fb_temp_43))
                    c2fb_temp_45 = local10
                    local10 = (c2fb_temp_45 + 1)
                    c2fb_temp_46 = CPtr(Long Ptr, @(local10->op))
                    c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, 68))
                    (*c2fb_temp_46) = Cast(Long, c2fb_temp_47)
                    c2fb_temp_47 = Cast(c2fb_c_int, (*c2fb_temp_46))
                    c2fb_temp_48 = CPtr(Long Ptr, @(local10->iCoord))
                    c2fb_temp_49 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
                    (*c2fb_temp_48) = Cast(Long, c2fb_temp_49)
                    c2fb_temp_49 = Cast(c2fb_c_int, (*c2fb_temp_48))
                    c2fb_temp_50 = CPtr(c2fb_RtreeDValue Ptr, @(local10->u.rValue))
                    c2fb_temp_51 = Cast(Double, local9(Cast(c2fb_c_int, 2ULL)).f)
                    (*c2fb_temp_50) = Cast(c2fb_RtreeDValue, c2fb_temp_51)
                    c2fb_temp_51 = Cast(Double, (*c2fb_temp_50))
                Else
                    c2fb_temp_52 = CPtr(Long Ptr, @(local10->op))
                    c2fb_temp_53 = Cast(c2fb_c_int, Cast(c2fb_c_int, 68))
                    (*c2fb_temp_52) = Cast(Long, c2fb_temp_53)
                    c2fb_temp_53 = Cast(c2fb_c_int, (*c2fb_temp_52))
                    c2fb_temp_54 = CPtr(Long Ptr, @(local10->iCoord))
                    c2fb_temp_55 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_54) = Cast(Long, c2fb_temp_55)
                    c2fb_temp_55 = Cast(c2fb_c_int, (*c2fb_temp_54))
                    c2fb_temp_56 = CPtr(c2fb_RtreeDValue Ptr, @(local10->u.rValue))
                    c2fb_temp_57 = Cast(Double, local9(Cast(c2fb_c_int, &O0ULL)).f)
                    (*c2fb_temp_56) = Cast(c2fb_RtreeDValue, c2fb_temp_57)
                    c2fb_temp_57 = Cast(Double, (*c2fb_temp_56))
                    c2fb_temp_58 = local10
                    local10 = (c2fb_temp_58 + 1)
                    c2fb_temp_59 = CPtr(Long Ptr, @(local10->op))
                    c2fb_temp_60 = Cast(c2fb_c_int, Cast(c2fb_c_int, 66))
                    (*c2fb_temp_59) = Cast(Long, c2fb_temp_60)
                    c2fb_temp_60 = Cast(c2fb_c_int, (*c2fb_temp_59))
                    c2fb_temp_61 = CPtr(Long Ptr, @(local10->iCoord))
                    c2fb_temp_62 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_61) = Cast(Long, c2fb_temp_62)
                    c2fb_temp_62 = Cast(c2fb_c_int, (*c2fb_temp_61))
                    c2fb_temp_63 = CPtr(c2fb_RtreeDValue Ptr, @(local10->u.rValue))
                    c2fb_temp_64 = Cast(Double, local9(Cast(c2fb_c_int, 1ULL)).f)
                    (*c2fb_temp_63) = Cast(c2fb_RtreeDValue, c2fb_temp_64)
                    c2fb_temp_64 = Cast(Double, (*c2fb_temp_63))
                    c2fb_temp_65 = local10
                    local10 = (c2fb_temp_65 + 1)
                    c2fb_temp_66 = CPtr(Long Ptr, @(local10->op))
                    c2fb_temp_67 = Cast(c2fb_c_int, Cast(c2fb_c_int, 68))
                    (*c2fb_temp_66) = Cast(Long, c2fb_temp_67)
                    c2fb_temp_67 = Cast(c2fb_c_int, (*c2fb_temp_66))
                    c2fb_temp_68 = CPtr(Long Ptr, @(local10->iCoord))
                    c2fb_temp_69 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                    (*c2fb_temp_68) = Cast(Long, c2fb_temp_69)
                    c2fb_temp_69 = Cast(c2fb_c_int, (*c2fb_temp_68))
                    c2fb_temp_70 = CPtr(c2fb_RtreeDValue Ptr, @(local10->u.rValue))
                    c2fb_temp_71 = Cast(Double, local9(Cast(c2fb_c_int, 2ULL)).f)
                    (*c2fb_temp_70) = Cast(c2fb_RtreeDValue, c2fb_temp_71)
                    c2fb_temp_71 = Cast(Double, (*c2fb_temp_70))
                    c2fb_temp_72 = local10
                    local10 = (c2fb_temp_72 + 1)
                    c2fb_temp_73 = CPtr(Long Ptr, @(local10->op))
                    c2fb_temp_74 = Cast(c2fb_c_int, Cast(c2fb_c_int, 66))
                    (*c2fb_temp_73) = Cast(Long, c2fb_temp_74)
                    c2fb_temp_74 = Cast(c2fb_c_int, (*c2fb_temp_73))
                    c2fb_temp_75 = CPtr(Long Ptr, @(local10->iCoord))
                    c2fb_temp_76 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
                    (*c2fb_temp_75) = Cast(Long, c2fb_temp_76)
                    c2fb_temp_76 = Cast(c2fb_c_int, (*c2fb_temp_75))
                    c2fb_temp_77 = CPtr(c2fb_RtreeDValue Ptr, @(local10->u.rValue))
                    c2fb_temp_78 = Cast(Double, local9(Cast(c2fb_c_int, 3ULL)).f)
                    (*c2fb_temp_77) = Cast(c2fb_RtreeDValue, c2fb_temp_78)
                    c2fb_temp_78 = Cast(Double, (*c2fb_temp_77))
                End If
            End If
        End If
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_79 = CPtr(_c2fb_record_c2fb_RtreeSearchPoint Ptr, CPtr(c2fb_RtreeSearchPoint Ptr, rtreeSearchPointNew(CPtr(c2fb_source_record_25 Ptr, local1), 0.0#, Cast(UByte, (Cast(c2fb_c_int, (local0->iDepth + Cast(c2fb_c_int, 1ULL))))))))
            local11 = c2fb_temp_79
            If (-Cast(c2fb_c_int, ((local11 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_80 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local3 = c2fb_temp_80
                Goto c2fb_label_0
            End If
            c2fb_temp_81 = CPtr(c2fb_sqlite3_int64 Ptr, @(local11->id))
            c2fb_temp_82 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_81) = Cast(c2fb_sqlite3_int64, c2fb_temp_82)
            c2fb_temp_82 = Cast(c2fb_int64, (*c2fb_temp_81))
            c2fb_temp_83 = CPtr(c2fb_u8 Ptr, @(local11->iCell))
            c2fb_temp_84 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_83) = Cast(c2fb_u8, c2fb_temp_84)
            c2fb_temp_84 = Cast(UByte, (*c2fb_temp_83))
            c2fb_temp_85 = CPtr(c2fb_u8 Ptr, @(local11->eWithin))
            c2fb_temp_86 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_85) = Cast(c2fb_u8, c2fb_temp_86)
            c2fb_temp_86 = Cast(UByte, (*c2fb_temp_85))
            ' C unused-parameter annotation
            c2fb_temp_87 = CPtr(c2fb_RtreeNode Ptr Ptr, @(local1->aNode(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_88 = CPtr(_c2fb_record_c2fb_RtreeNode Ptr, local2)
            (*c2fb_temp_87) = c2fb_temp_88
            c2fb_temp_89 = CPtr(_c2fb_record_c2fb_RtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local2 = c2fb_temp_89
            ' empty C statement
            c2fb_temp_90 = Cast(c2fb_c_int, rtreeStepToLeaf(CPtr(c2fb_source_record_25 Ptr, local1)))
            local3 = c2fb_temp_90
        End If
    End If
    c2fb_label_0:
    nodeRelease(CPtr(c2fb_source_record_23 Ptr, local0), CPtr(SqliteRtreeNode Ptr, local2))
    rtreeRelease(CPtr(c2fb_source_record_23 Ptr, local0))
    Return local3
End Function
Private Function geopolyBestIndex CDecl Alias "geopolyBestIndex" (ByVal arg0 As c2fb_source_record_4 Ptr, ByVal arg1 As c2fb_source_record_3 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1502
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As c2fb_source_record_0 Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte
    Dim c2fb_temp_13 As Double Ptr
    Dim c2fb_temp_14 As Double
    Dim c2fb_temp_15 As c2fb_int64 Ptr
    Dim c2fb_temp_16 As c2fb_int64
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As ZString Ptr Ptr
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As c2fb_c_int Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As UByte Ptr
    Dim c2fb_temp_26 As UByte
    Dim c2fb_temp_27 As Double Ptr
    Dim c2fb_temp_28 As Double
    Dim c2fb_temp_29 As c2fb_int64 Ptr
    Dim c2fb_temp_30 As c2fb_int64
    Dim c2fb_temp_31 As c2fb_c_int Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As ZString Ptr Ptr
    Dim c2fb_temp_34 As ZString Ptr
    Dim c2fb_temp_35 As Double Ptr
    Dim c2fb_temp_36 As Double
    Dim c2fb_temp_37 As c2fb_int64 Ptr
    Dim c2fb_temp_38 As c2fb_int64

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1->nConstraint))))
        local4 = CPtr(c2fb_source_record_0 Ptr, @(arg1->aConstraint[local0]))
        If (-Cast(c2fb_c_int, (local4->usable = 0))) Then
            Goto c2fb_flow_1
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4->iColumn < Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4->op) = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, local0)
            local1 = c2fb_temp_2
            Goto c2fb_flow_0
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4->iColumn = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4->op) >= Cast(c2fb_c_int, 150ULL))))) <> 0))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, local0)
            local2 = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, local4->op) - Cast(c2fb_c_int, 150ULL))) + Cast(c2fb_c_int, 2ULL))))
            local3 = c2fb_temp_4
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(ZString Ptr Ptr, @(arg1->idxStr))
        c2fb_temp_8 = CPtr(ZString Ptr, StrPtr(!"rowid"))
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(arg1->aConstraintUsage[local1].argvIndex))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_9) = c2fb_temp_10
        c2fb_temp_11 = CPtr(UByte Ptr, @(arg1->aConstraintUsage[local1].omit))
        c2fb_temp_12 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_temp_13 = CPtr(Double Ptr, @(arg1->estimatedCost))
        c2fb_temp_14 = Cast(Double, 30.0#)
        (*c2fb_temp_13) = c2fb_temp_14
        c2fb_temp_15 = CPtr(c2fb_int64 Ptr, @(arg1->estimatedRows))
        c2fb_temp_16 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_15) = c2fb_temp_16
        c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @(arg1->idxFlags))
        c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H00000001ULL))
        (*c2fb_temp_17) = c2fb_temp_18
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
        c2fb_temp_20 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_19) = c2fb_temp_20
        c2fb_temp_21 = CPtr(ZString Ptr Ptr, @(arg1->idxStr))
        c2fb_temp_22 = CPtr(ZString Ptr, StrPtr(!"rtree"))
        (*c2fb_temp_21) = c2fb_temp_22
        c2fb_temp_23 = CPtr(c2fb_c_int Ptr, @(arg1->aConstraintUsage[local2].argvIndex))
        c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_23) = c2fb_temp_24
        c2fb_temp_25 = CPtr(UByte Ptr, @(arg1->aConstraintUsage[local2].omit))
        c2fb_temp_26 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_25) = c2fb_temp_26
        c2fb_temp_27 = CPtr(Double Ptr, @(arg1->estimatedCost))
        c2fb_temp_28 = Cast(Double, 300.0#)
        (*c2fb_temp_27) = c2fb_temp_28
        c2fb_temp_29 = CPtr(c2fb_int64 Ptr, @(arg1->estimatedRows))
        c2fb_temp_30 = Cast(c2fb_int64, Cast(c2fb_c_int, 10ULL))
        (*c2fb_temp_29) = c2fb_temp_30
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_31 = CPtr(c2fb_c_int Ptr, @(arg1->idxNum))
    c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
    (*c2fb_temp_31) = c2fb_temp_32
    c2fb_temp_33 = CPtr(ZString Ptr Ptr, @(arg1->idxStr))
    c2fb_temp_34 = CPtr(ZString Ptr, StrPtr(!"fullscan"))
    (*c2fb_temp_33) = c2fb_temp_34
    c2fb_temp_35 = CPtr(Double Ptr, @(arg1->estimatedCost))
    c2fb_temp_36 = Cast(Double, 3000000.0#)
    (*c2fb_temp_35) = c2fb_temp_36
    c2fb_temp_37 = CPtr(c2fb_int64 Ptr, @(arg1->estimatedRows))
    c2fb_temp_38 = Cast(c2fb_int64, Cast(c2fb_c_int, 100000ULL))
    (*c2fb_temp_37) = c2fb_temp_38
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function geopolyColumn CDecl Alias "geopolyColumn" (ByVal arg0 As c2fb_source_record_5 Ptr, ByVal arg1 As c2fb_sqlite3_context Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1555
    Dim local0 As c2fb_source_record_37 Ptr
    Dim local1 As c2fb_source_record_38 Ptr
    Dim local2 As c2fb_RtreeSearchPoint Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_RtreeNode Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_37 Ptr, arg0->pVtab)
    local1 = CPtr(c2fb_source_record_38 Ptr, arg0)
    local2 = CPtr(c2fb_RtreeSearchPoint Ptr, rtreeSearchPointFirst(CPtr(c2fb_source_record_25 Ptr, local1)))
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = CPtr(c2fb_RtreeNode Ptr, rtreeNodeOfFirstSearchPoint(CPtr(c2fb_source_record_25 Ptr, local1), CPtr(c2fb_c_int Ptr, @(local3))))
    If local3 Then
        Return local3
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (sqlite3_vtab_nochange(CPtr(Any Ptr, arg1)) <> 0))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, ((arg2 <= Cast(c2fb_c_int, local0->nAux))))) Then
        If (-Cast(c2fb_c_int, (local1->bAuxValid = 0))) Then
            If (-Cast(c2fb_c_int, ((local1->pReadAux = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_prepare_v3(CPtr(Any Ptr, local0->db), CPtr(Const ZString Ptr, local0->zReadAuxSql), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr Ptr, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1->pReadAux))), Cast(c2fb_c_int, &O0ULL)))
                local3 = c2fb_temp_0
                If local3 Then
                    Return local3
                End If
            End If
            sqlite3_bind_int64(CPtr(Any Ptr, local1->pReadAux), Cast(c2fb_c_int, 1ULL), nodeGetRowid(CPtr(c2fb_source_record_23 Ptr, local0), CPtr(SqliteRtreeNode Ptr, local4), local2->iCell))
            c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_step(CPtr(Any Ptr, local1->pReadAux)))
            local3 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 100ULL))))) Then
                c2fb_temp_2 = CPtr(UByte Ptr, @(local1->bAuxValid))
                c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_2) = c2fb_temp_3
            Else
                sqlite3_reset(CPtr(Any Ptr, local1->pReadAux))
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 101ULL))))) Then
                    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local3 = c2fb_temp_4
                End If
                Return local3
            End If
        End If
        sqlite3_result_value(CPtr(Any Ptr, arg1), CPtr(Any Ptr, CPtr(c2fb_sqlite3_value Ptr, sqlite3_column_value(CPtr(Any Ptr, local1->pReadAux), Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 2ULL)))))))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function geopolyUpdate CDecl Alias "geopolyUpdate" (ByVal arg0 As c2fb_source_record_4 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rtree/geopoly.c
' c2fb source-line: 1610
    Dim local0 As c2fb_source_record_37 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_RtreeCell
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_i64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local9 As c2fb_RtreeNode Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_int64 Ptr
    Dim c2fb_temp_17 As c2fb_int64
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim local11 As c2fb_sqlite3_stmt Ptr
    Dim local12 As c2fb_c_int
    Dim local13 As c2fb_c_int
    Dim local14 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_22 As c2fb_GeoPoly Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_37 Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local7 = Cast(c2fb_c_int, &O0ULL)
    If local0->nNodeRef Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 6ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    rtreeReference(CPtr(c2fb_source_record_23 Ptr, local0))
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, ((geopolyValueType(arg2[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 5ULL))))))
    local4 = c2fb_temp_0
    ' empty C statement
    c2fb_temp_1 = Cast(c2fb_int64, IIf(local4, geopolyValueInt64(arg2[Cast(c2fb_c_int, &O0ULL)]), Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))))
    local3 = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((geopolyValueType(arg2[Cast(c2fb_c_int, 1ULL)]) <> Cast(c2fb_c_int, 5ULL))))) <> 0))))))
    local6 = c2fb_temp_2
    c2fb_temp_3 = Cast(c2fb_int64, IIf(local6, geopolyValueInt64(arg2[Cast(c2fb_c_int, 1ULL)]), Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))))
    local5 = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_i64 Ptr, @(local2.iRowid))
    c2fb_temp_5 = Cast(c2fb_int64, local5)
    (*c2fb_temp_4) = Cast(c2fb_i64, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_int64, (*c2fb_temp_4))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local4 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, (c2fb_external_sqlite3_value_nochange(arg2[Cast(c2fb_c_int, 2ULL)]) = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 <> local5)))) <> 0)))))) <> 0))))) Then
        ' C unused-parameter annotation
        c2fb_temp_6 = CPtr(c2fb_GeoPoly Ptr, geopolyBBox(Cast(c2fb_c_int, &O0ULL), arg2[Cast(c2fb_c_int, 2ULL)], CPtr(c2fb_RtreeCoord Ptr, (@local2.aCoord(0))), CPtr(c2fb_c_int Ptr, @(local1))))
        If local1 Then
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 1ULL))))) Then
                c2fb_temp_7 = CPtr(ZString Ptr Ptr, @(arg0->zErrMsg))
                c2fb_temp_8 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"_shape does not contain a valid polygon")))
                (*c2fb_temp_7) = c2fb_temp_8
            End If
            Goto c2fb_label_0
        End If
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local7 = c2fb_temp_9
        If (-Cast(c2fb_c_int, (((local6 <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local4 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 <> local5)))) <> 0)))))) <> 0))))) Then
            ' C automatic storage declaration
            sqlite3_bind_int64(CPtr(Any Ptr, local0->pReadRowid), Cast(c2fb_c_int, 1ULL), local2.iRowid)
            c2fb_temp_10 = Cast(c2fb_c_int, sqlite3_step(CPtr(Any Ptr, local0->pReadRowid)))
            local8 = c2fb_temp_10
            c2fb_temp_11 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, local0->pReadRowid)))
            local1 = c2fb_temp_11
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = local8)))) Then
                If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_vtab_on_conflict(local0->db) = Cast(c2fb_c_int, 5ULL))))) Then
                    c2fb_temp_12 = Cast(c2fb_c_int, rtreeDeleteRowid(CPtr(c2fb_source_record_23 Ptr, local0), local2.iRowid))
                    local1 = c2fb_temp_12
                Else
                    c2fb_temp_13 = Cast(c2fb_c_int, rtreeConstraintError(CPtr(c2fb_source_record_23 Ptr, local0), Cast(c2fb_c_int, &O0ULL)))
                    local1 = c2fb_temp_13
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((local7 <> 0) AndAlso (local4 <> 0)))))) <> 0)))))) <> 0))))) Then
        c2fb_temp_14 = Cast(c2fb_c_int, rtreeDeleteRowid(CPtr(c2fb_source_record_23 Ptr, local0), local3))
        local1 = c2fb_temp_14
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso (local7 <> 0))))) Then
        local9 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, (local6 = 0))) Then
            c2fb_temp_15 = Cast(c2fb_c_int, rtreeNewRowid(CPtr(c2fb_source_record_23 Ptr, local0), CPtr(c2fb_int64 Ptr, @(local2.iRowid))))
            local1 = c2fb_temp_15
        End If
        c2fb_temp_16 = CPtr(c2fb_int64 Ptr, @((*arg3)))
        c2fb_temp_17 = Cast(c2fb_int64, local2.iRowid)
        (*c2fb_temp_16) = c2fb_temp_17
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_18 = Cast(c2fb_c_int, ChooseLeaf(CPtr(c2fb_source_record_23 Ptr, local0), CPtr(c2fb_source_record_27 Ptr, CPtr(c2fb_RtreeCell Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL), CPtr(SqliteRtreeNode Ptr Ptr, CPtr(c2fb_RtreeNode Ptr Ptr, @(local9)))))
            local1 = c2fb_temp_18
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_19 = Cast(c2fb_c_int, rtreeInsertCell(CPtr(c2fb_source_record_23 Ptr, local0), CPtr(SqliteRtreeNode Ptr, local9), CPtr(c2fb_source_record_27 Ptr, CPtr(c2fb_RtreeCell Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_19
            c2fb_temp_20 = Cast(c2fb_c_int, nodeRelease(CPtr(c2fb_source_record_23 Ptr, local0), CPtr(SqliteRtreeNode Ptr, local9)))
            local10 = c2fb_temp_20
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_21 = Cast(c2fb_c_int, local10)
                local1 = c2fb_temp_21
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        local11 = local0->pWriteAux
        ' C automatic storage declaration
        local13 = Cast(c2fb_c_int, &O0ULL)
        sqlite3_bind_int64(CPtr(Any Ptr, local11), Cast(c2fb_c_int, 1ULL), local2.iRowid)
        ' C unused-parameter annotation
        If c2fb_external_sqlite3_value_nochange(arg2[Cast(c2fb_c_int, 2ULL)]) Then
            sqlite3_bind_null(CPtr(Any Ptr, local11), Cast(c2fb_c_int, 2ULL))
        Else
            local14 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_23 = 0
            If ((-Cast(c2fb_c_int, ((geopolyValueType(arg2[Cast(c2fb_c_int, 2ULL)]) = Cast(c2fb_c_int, 3ULL))))) <> 0) Then
                c2fb_temp_22 = CPtr(_c2fb_record_c2fb_GeoPoly Ptr, CPtr(c2fb_GeoPoly Ptr, geopolyFuncParam(Cast(c2fb_c_int, &O0ULL), arg2[Cast(c2fb_c_int, 2ULL)], CPtr(c2fb_c_int Ptr, @(local1)))))
                local14 = c2fb_temp_22
                c2fb_temp_23 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((c2fb_temp_22) <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))
            End If
            If (-Cast(c2fb_c_int, (((c2fb_temp_23 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                geopolyBindBlob(local11, Cast(c2fb_c_int, 2ULL), CPtr(Const Any Ptr, CPtr(UByte Ptr, (@local14->hdr(0)))), Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) * local14->nVertex)))), (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
            Else
                geopolyBindValue(local11, Cast(c2fb_c_int, 2ULL), CPtr(Const c2fb_sqlite3_value Ptr, arg2[Cast(c2fb_c_int, 2ULL)]))
            End If
            sqlite3_free(CPtr(Any Ptr, local14))
            c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local13 = c2fb_temp_24
        End If
        c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local12 = c2fb_temp_25
        While (-Cast(c2fb_c_int, ((local12 < Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 2ULL)))))))
            c2fb_temp_27 = local13
            local13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_27 + 1)))
            geopolyBindValue(local11, Cast(c2fb_c_int, (local12 + Cast(c2fb_c_int, 2ULL))), CPtr(Const c2fb_sqlite3_value Ptr, arg2[Cast(c2fb_c_int, (local12 + Cast(c2fb_c_int, 2ULL)))]))
        c2fb_flow_1:
            c2fb_temp_26 = local12
            local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_26 + 1)))
        Wend
        c2fb_flow_0:
        If local13 Then
            sqlite3_step(CPtr(Any Ptr, local11))
            c2fb_temp_28 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, local11)))
            local1 = c2fb_temp_28
        End If
    End If
    c2fb_label_0:
    rtreeRelease(CPtr(c2fb_source_record_23 Ptr, local0))
    Return local1
End Function
' c2fb skipped geopolyFindFunction: outside the supported subset
' c2fb body diagnostic [unsupported-parameter-declaration] line 1746: geopolyFindFunction: unsupported parameter declaration
' c2fb skipped sqlite3_geopoly_init: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 1797: sqlite3_geopoly_init: assignment parser stopped at byte 60 (rc = sqlite3_create_module_v2(db, "geopoly", &geopolyModule, 0, 0)): , 0, 0)
' c2fb body rename mappings:
' c2fb rename matched: geopolyIsSpace -> c2fb_geopolyIsSpace

/' ------------------------------------------------------------------------- '/
/' GeoPoly virtual-table registration                                        '/
/' ------------------------------------------------------------------------- '/

/'
    The xFindFunction callback lets the query planner use GeoPoly's overlap
    predicates as R-tree constraints. SQLite owns the callback table after
    registration, so geopolyModule must have static storage duration.
'/
Private Function geopolyFindFunction CDecl Alias "geopolyFindFunction" ( _
    ByVal pVtab As SqliteVtab Ptr, _
    ByVal argumentCount As c2fb_c_int, _
    ByVal zName As Const ZString Ptr, _
    ByVal pxFunction As c2fb_callback_161 Ptr, _
    ByVal ppArgument As Any Ptr Ptr _
) As c2fb_c_int
    If zName = 0 OrElse pxFunction = 0 OrElse ppArgument = 0 Then Return 0

    If sqlite3_stricmp(zName, StrPtr(!"geopoly_overlap")) = 0 Then
        pxFunction[0] = CPtr(c2fb_callback_161, ProcPtr(geopolyOverlapFunc))
        ppArgument[0] = 0
        Return SQLITE_INDEX_CONSTRAINT_FUNCTION
    End If
    If sqlite3_stricmp(zName, StrPtr(!"geopoly_within")) = 0 Then
        pxFunction[0] = CPtr(c2fb_callback_161, ProcPtr(geopolyWithinFunc))
        ppArgument[0] = 0
        Return SQLITE_INDEX_CONSTRAINT_FUNCTION + 1
    End If
    Return 0
End Function

Private Dim Shared As Const SqliteModuleCallbacks geopolyModule = _
    Type<SqliteModuleCallbacks>( _
        3, _
        CPtr(Any Ptr, ProcPtr(geopolyCreate)), _
        CPtr(Any Ptr, ProcPtr(geopolyConnect)), _
        CPtr(SqliteModuleBestIndexProc, ProcPtr(geopolyBestIndex)), _
        CPtr(Any Ptr, ProcPtr(rtreeDisconnect)), _
        CPtr(Any Ptr, ProcPtr(rtreeDestroy)), _
        CPtr(Any Ptr, ProcPtr(rtreeOpen)), _
        CPtr(Any Ptr, ProcPtr(rtreeClose)), _
        CPtr(Any Ptr, ProcPtr(geopolyFilter)), _
        CPtr(Any Ptr, ProcPtr(rtreeNext)), _
        CPtr(Any Ptr, ProcPtr(rtreeEof)), _
        CPtr(Any Ptr, ProcPtr(geopolyColumn)), _
        CPtr(Any Ptr, ProcPtr(rtreeRowid)), _
        CPtr(Any Ptr, ProcPtr(geopolyUpdate)), _
        CPtr(Any Ptr, ProcPtr(rtreeBeginTransaction)), _
        CPtr(Any Ptr, ProcPtr(rtreeEndTransaction)), _
        CPtr(Any Ptr, ProcPtr(rtreeEndTransaction)), _
        CPtr(Any Ptr, ProcPtr(rtreeEndTransaction)), _
        CPtr(Any Ptr, ProcPtr(geopolyFindFunction)), _
        CPtr(Any Ptr, ProcPtr(rtreeRename)), _
        CPtr(Any Ptr, ProcPtr(rtreeSavepoint)), _
        0, _
        0, _
        CPtr(Any Ptr, ProcPtr(rtreeShadowName)), _
        CPtr(Any Ptr, ProcPtr(rtreeIntegrity)) _
    )

Private Function geopolyInit CDecl Alias "geopolyInit" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal pAuxiliary As Any Ptr, _
    ByVal argumentCount As c2fb_c_int, _
    ByVal aArgument As Const ZString Ptr Ptr, _
    ByVal ppVtab As c2fb_source_record_4 Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr, _
    ByVal isCreate As c2fb_c_int _
) As c2fb_c_int
    Dim rc As c2fb_c_int = SQLITE_OK
    Dim pRtree As c2fb_source_record_37 Ptr
    Dim nDatabase As c2fb_c_int
    Dim nName As c2fb_c_int
    Dim pSql As sqlite3_str Ptr
    Dim zSql As ZString Ptr
    Dim pTextStorage As UByte Ptr
    Dim allocationBytes As sqlite3_uint64
    Dim columnIndex As c2fb_c_int
    Dim zLocalError As ZString Ptr
    Dim pError As ZString Ptr Ptr

    If ppVtab = 0 OrElse pDatabase = 0 Then Return SQLITE_MISUSE
    ppVtab[0] = 0
    zLocalError = 0
    If pzError = 0 Then
        pError = @zLocalError
    Else
        pError = pzError
        pError[0] = 0
    End If
    If CPtr(Any Ptr, aArgument) = 0 OrElse argumentCount < 3 Then Return SQLITE_ERROR
    If aArgument[1] = 0 OrElse aArgument[2] = 0 Then Return SQLITE_ERROR

    If argumentCount >= SQLITE3_FB_RTREE_MAX_AUX_COLUMN + 4 Then
        pError[0] = sqlite3_mprintf(StrPtr(!"%s"), StrPtr(!"Too many columns for a geopoly table"))
        rc = SQLITE_ERROR
        GoTo geopolyInitCleanup
    End If

    ' SQLite limits identifiers well below this range. Check the source
    ' helper's signed result before calculating the allocation size.
    nDatabase = sqlite3Strlen30(aArgument[1])
    nName = sqlite3Strlen30(aArgument[2])
    If nDatabase < 0 OrElse nName < 0 Then
        rc = SQLITE_TOOBIG
        GoTo geopolyInitCleanup
    End If

    allocationBytes = SizeOf(c2fb_source_record_37)
    allocationBytes += Cast(sqlite3_uint64, nDatabase)
    allocationBytes += Cast(sqlite3_uint64, nName) * 2ULL
    allocationBytes += 8ULL
    pRtree = CPtr(c2fb_source_record_37 Ptr, sqlite3_malloc64(allocationBytes))
    If pRtree = 0 Then
        rc = SQLITE_NOMEM
        GoTo geopolyInitCleanup
    End If
    c2fb_crt_memset(pRtree, 0, Cast(SQLITE_SIZE_T, allocationBytes))

    pRtree->nBusy = 1
    pRtree->base.pModule = CPtr(Const c2fb_sqlite3_module Ptr, @rtreeModule)
    pRtree->db = pDatabase
    pTextStorage = CPtr(UByte Ptr, pRtree) + SizeOf(c2fb_source_record_37)
    pRtree->zDb = CPtr(ZString Ptr, pTextStorage)
    pRtree->zName = CPtr(ZString Ptr, pTextStorage + nDatabase + 1)
    pRtree->zNodeName = CPtr(ZString Ptr, pTextStorage + nDatabase + nName + 2)
    pRtree->eCoordType = 0 ' RTREE_COORD_REAL32 from ext/rtree/rtree.c.
    pRtree->nDim = 2
    pRtree->nDim2 = 4
    c2fb_crt_memcpy(pRtree->zDb, aArgument[1], Cast(SQLITE_SIZE_T, nDatabase))
    c2fb_crt_memcpy(pRtree->zName, aArgument[2], Cast(SQLITE_SIZE_T, nName))
    c2fb_crt_memcpy(pRtree->zNodeName, aArgument[2], Cast(SQLITE_SIZE_T, nName))
    c2fb_crt_memcpy( _
        CPtr(UByte Ptr, pRtree->zNodeName) + nName, _
        StrPtr(!"_node"), _
        6 _
    )

    pSql = sqlite3_str_new(pDatabase)
    If pSql = 0 Then
        rc = SQLITE_NOMEM
        GoTo geopolyInitFailure
    End If
    c2fb_external_sqlite3_str_appendf(pSql, StrPtr(!"CREATE TABLE x(_shape"))
    pRtree->nAux = 1
    pRtree->nAuxNotNull = 1
    columnIndex = 3
    While columnIndex < argumentCount
        If aArgument[columnIndex] = 0 Then
            rc = SQLITE_ERROR
            Exit While
        End If
        pRtree->nAux += 1
        c2fb_external_sqlite3_str_appendf(pSql, StrPtr(!",%s"), aArgument[columnIndex])
        columnIndex += 1
    Wend
    c2fb_external_sqlite3_str_appendf(pSql, StrPtr(!");"))
    zSql = sqlite3_str_finish(pSql)
    pSql = 0
    If zSql = 0 Then rc = SQLITE_NOMEM
    If rc = SQLITE_OK Then
        rc = sqlite3_declare_vtab(pDatabase, zSql)
        If rc <> SQLITE_OK Then _
            pError[0] = sqlite3_mprintf(StrPtr(!"%s"), c2fb_external_sqlite3_errmsg(pDatabase))
    End If
    sqlite3_free(zSql)
    If rc <> SQLITE_OK Then GoTo geopolyInitFailure

    pRtree->nBytesPerCell = 8 + pRtree->nDim2 * 4
    rc = getNodeSize( _
        pDatabase, _
        CPtr(c2fb_source_record_23 Ptr, pRtree), _
        isCreate, _
        pError _
    )
    If rc <> SQLITE_OK Then GoTo geopolyInitFailure
    rc = rtreeSqlInit( _
        CPtr(c2fb_source_record_23 Ptr, pRtree), _
        pDatabase, _
        aArgument[1], _
        aArgument[2], _
        isCreate _
    )
    If rc <> SQLITE_OK Then
        pError[0] = sqlite3_mprintf(StrPtr(!"%s"), c2fb_external_sqlite3_errmsg(pDatabase))
        GoTo geopolyInitFailure
    End If

    ppVtab[0] = CPtr(c2fb_source_record_4 Ptr, pRtree)
    If pzError = 0 Then sqlite3_free(zLocalError)
    Return SQLITE_OK

geopolyInitFailure:
    If rc = SQLITE_OK Then rc = SQLITE_ERROR
    rtreeRelease(CPtr(c2fb_source_record_23 Ptr, pRtree))

geopolyInitCleanup:
    If pzError = 0 Then sqlite3_free(zLocalError)
    Return rc
End Function

Private Type GeoPolyFunctionRegistration
    xFunction As c2fb_callback_161
    nArg As Byte
    bPure As UByte
    zName As ZString * 32
End Type

Private Type GeoPolyAggregateRegistration
    xStep As c2fb_callback_161
    xFinal As c2fb_callback_10
    zName As ZString * 32
End Type

/'
    Keep function order aligned with ext/rtree/geopoly.c. The planner and
    test harness use the exact same names, arities, and function flags.
'/
Private Dim Shared As Const GeoPolyFunctionRegistration geopolyFunctionList(0 To 11) = { _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyAreaFunc)), 1, 1, "geopoly_area"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyBlobFunc)), 1, 1, "geopoly_blob"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyJsonFunc)), 1, 1, "geopoly_json"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolySvgFunc)), -1, 1, "geopoly_svg"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyWithinFunc)), 2, 1, "geopoly_within"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyContainsPointFunc)), 3, 1, "geopoly_contains_point"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyOverlapFunc)), 2, 1, "geopoly_overlap"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyDebugFunc)), 1, 0, "geopoly_debug"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyBBoxFunc)), 1, 1, "geopoly_bbox"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyXformFunc)), 7, 1, "geopoly_xform"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyRegularFunc)), 4, 1, "geopoly_regular"), _
    Type<GeoPolyFunctionRegistration>(CPtr(c2fb_callback_161, ProcPtr(geopolyCcwFunc)), 1, 1, "geopoly_ccw") _
}

Private Dim Shared As Const GeoPolyAggregateRegistration geopolyAggregateList(0 To 0) = { _
    Type<GeoPolyAggregateRegistration>( _
        CPtr(c2fb_callback_161, ProcPtr(geopolyBBoxStep)), _
        CPtr(c2fb_callback_10, ProcPtr(geopolyBBoxFinal)), _
        "geopoly_group_bbox" _
    ) _
}

Function sqlite3_geopoly_init CDecl Alias "sqlite3_geopoly_init" ( _
    ByVal pDatabase As sqlite3 Ptr _
) As c2fb_c_int
    Dim rc As c2fb_c_int = SQLITE_OK
    Dim i As c2fb_c_int
    Dim flags As c2fb_c_int

    For i = 0 To UBound(geopolyFunctionList)
        If rc <> SQLITE_OK Then Exit For
        flags = SQLITE_UTF8
        If geopolyFunctionList(i).bPure Then
            flags = flags Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS
        Else
            flags = flags Or SQLITE_DIRECTONLY
        End If
        rc = c2fb_external_sqlite3_create_function_v2( _
            pDatabase, _
            StrPtr(geopolyFunctionList(i).zName), _
            geopolyFunctionList(i).nArg, _
            flags, _
            0, _
            geopolyFunctionList(i).xFunction, _
            0, _
            0, _
            0 _
        )
    Next

    For i = 0 To UBound(geopolyAggregateList)
        If rc <> SQLITE_OK Then Exit For
        rc = c2fb_external_sqlite3_create_function_v2( _
            pDatabase, _
            StrPtr(geopolyAggregateList(i).zName), _
            1, _
            SQLITE_UTF8 Or SQLITE_DETERMINISTIC Or SQLITE_INNOCUOUS, _
            0, _
            0, _
            geopolyAggregateList(i).xStep, _
            geopolyAggregateList(i).xFinal, _
            0 _
        )
    Next
    If rc = SQLITE_OK Then
        rc = sqlite3_create_module_v2(pDatabase, StrPtr(!"geopoly"), @geopolyModule, 0, 0)
    End If
    Return rc
End Function

/' end of sqlite3_geopoly_body.bi '/
