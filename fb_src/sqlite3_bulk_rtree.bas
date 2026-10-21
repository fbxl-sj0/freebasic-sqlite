/'
** 2001 September 15
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
*************************************************************************
** This file contains the FreeBASIC implementation of SQLite's R-tree
** virtual-table module, translated from ext/rtree/rtree.c.
'/

/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_rtree.bas

    Purpose:

        Implement SQLite's optional R-tree and R*-tree virtual-table module.

    Responsibilities:

        - Preserve the source R-tree node, query, and cursor algorithms.
        - Register the rtree and rtree_i32 virtual-table modules and helpers.
        - Build callback result blobs with the upstream in-memory layout.

    This file intentionally does NOT contain:

        - GeoPoly bodies, which are included under SQLITE_ENABLE_GEOPOLY.
        - SQLite test support or test cases.
        - Code compiled when virtual tables or R-Tree support are disabled.
'/

#if defined(SQLITE_ENABLE_RTREE) AndAlso Not defined(SQLITE_OMIT_VIRTUALTABLE)

#define SQLITE3_FB_RTREE_MAX_AUX_COLUMN 100
#define SQLITE3_FB_RTREE_MAX_DIMENSIONS 5

#include once "crt/stddef.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_parser_types.bi"
#include once "sqlite3_expr_types.bi"
#include once "sqlite3_vdbe_mem_types.bi"
#include once "sqlite3_vdbe_core.bi"
#include once "sqlite3_hash_types.bi"
#include once "sqlite3_pager.bi"
#include once "sqlite3_btree.bi"

#include once "sqlite3_db_types.bi"
#include once "sqlite3_vdbe_compare.bi"
#include once "sqlite3_vtab_types.bi"
#include once "sqlite3_straccum.bi"
#include once "sqlite3_vdbe_mem_types.bi"
#include once "sqlite3_result.bi"
#include once "sqlite3_vdbe_core.bi"
#include once "sqlite3_schema_types.bi"
#include once "sqlite3_rtree_types.bi"

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

Declare Function sqlite3_exec CDecl Alias "sqlite3_exec" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As Any Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function sqlite3_malloc CDecl Alias "sqlite3_malloc" (ByVal arg0 As c2fb_c_int) As Any Ptr
Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function sqlite3_prepare_v2 CDecl Alias "sqlite3_prepare_v2" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3_prepare_v3 CDecl Alias "sqlite3_prepare_v3" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_uint, ByVal arg4 As Any Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3_bind_int64 CDecl Alias "sqlite3_bind_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3_bind_null CDecl Alias "sqlite3_bind_null" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_column_count CDecl Alias "sqlite3_column_count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_column_name CDecl Alias "sqlite3_column_name" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Const ZString Ptr
Declare Function sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_column_int CDecl Alias "sqlite3_column_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_column_int64 CDecl Alias "sqlite3_column_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function sqlite3_column_value CDecl Alias "sqlite3_column_value" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Any Ptr
Declare Function sqlite3_column_bytes CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_column_type CDecl Alias "sqlite3_column_type" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_vtab_nochange CDecl Alias "sqlite3_vtab_nochange" (ByVal arg0 As Any Ptr) As c2fb_c_int
#ifdef SQLITE_ENABLE_GEOPOLY
Declare Function sqlite3_geopoly_init CDecl Alias "sqlite3_geopoly_init" (ByVal pDatabase As sqlite3 Ptr) As c2fb_c_int
#endif
Declare Function sqlite3_reset CDecl Alias "sqlite3_reset" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_context_db_handle CDecl Alias "sqlite3_context_db_handle" (ByVal arg0 As Any Ptr) As Any Ptr
Declare Sub sqlite3_result_double CDecl Alias "sqlite3_result_double" (ByVal arg0 As Any Ptr, ByVal arg1 As Double)
Declare Sub sqlite3_result_error CDecl Alias "sqlite3_result_error" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub sqlite3_result_error_nomem CDecl Alias "sqlite3_result_error_nomem" (ByVal arg0 As Any Ptr)
Declare Sub sqlite3_result_error_code CDecl Alias "sqlite3_result_error_code" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub sqlite3_result_int CDecl Alias "sqlite3_result_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub sqlite3_result_int64 CDecl Alias "sqlite3_result_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64)
Declare Sub sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr)
Declare Sub sqlite3_result_value CDecl Alias "sqlite3_result_value" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr)
Declare Function sqlite3_blob_reopen CDecl Alias "sqlite3_blob_reopen" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3_blob_close CDecl Alias "sqlite3_blob_close" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_blob_bytes CDecl Alias "sqlite3_blob_bytes" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_blob_read CDecl Alias "sqlite3_blob_read" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3GetToken CDecl Alias "sqlite3GetToken" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_int64
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As SQLITE_SIZE_T) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As SQLITE_C_INT, ByVal arg2 As SQLITE_SIZE_T) As Any Ptr
Declare Function c2fb_crt_memmove CDecl Alias "memmove" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As SQLITE_SIZE_T) As Any Ptr

Type c2fb_callback_8 As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_1 As Sub CDecl()
Type c2fb_callback_10 As Sub CDecl(ByVal arg0 As SqliteResultContext Ptr)
Type c2fb_callback_15 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As SQLITE_C_UINT, ByVal arg3 As SQLITE_C_UINT, ByVal arg4 As SQLITE_C_UINT) As SQLITE_C_UINT
Type c2fb_callback_154 As Function CDecl(ByVal arg0 As SqliteRtreeGeometry Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Double Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_155 As Function CDecl(ByVal arg0 As SqliteRtreeQueryInfo Ptr) As c2fb_c_int
Type c2fb_callback_161 As Sub CDecl(ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr)
Type c2fb_callback_171 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int

Private Type c2fb_source_record_23
    base As SqliteVtab
    db As sqlite3 Ptr
    iNodeSize As c2fb_c_int
    nDim As UByte
    nDim2 As UByte
    eCoordType As UByte
    nBytesPerCell As UByte
    inWrTrans As UByte
    nAux As UShort
#ifdef SQLITE_ENABLE_GEOPOLY
    ' GeoPoly keeps its polygon shape in the first auxiliary column.
    nAuxNotNull As UByte
#endif
    iDepth As c2fb_c_int
    zDb As ZString Ptr
    zName As ZString Ptr
    zNodeName As ZString Ptr
    nBusy As c2fb_c_uint
    nRowEst As c2fb_int64
    nCursor As c2fb_c_uint
    nNodeRef As c2fb_c_uint
    zReadAuxSql As ZString Ptr
    pDeleted As SqliteRtreeNode Ptr
    pNodeBlob As Any Ptr
    pWriteNode As SqliteVdbe Ptr
    pDeleteNode As SqliteVdbe Ptr
    pReadRowid As SqliteVdbe Ptr
    pWriteRowid As SqliteVdbe Ptr
    pDeleteRowid As SqliteVdbe Ptr
    pReadParent As SqliteVdbe Ptr
    pWriteParent As SqliteVdbe Ptr
    pDeleteParent As SqliteVdbe Ptr
    pWriteAux As SqliteVdbe Ptr
    aHash(0 To 96) As SqliteRtreeNode Ptr
End Type

Private Type c2fb_source_record_24
    rScore As Double
    id As c2fb_int64
    iLevel As UByte
    eWithin As UByte
    iCell As UByte
End Type

Private Type c2fb_source_record_25
    base As SqliteVtabCursor
    atEOF As UByte
    bPoint As UByte
    bAuxValid As UByte
    iStrategy As c2fb_c_int
    nConstraint As c2fb_c_int
    aConstraint As SqliteRtreeConstraint Ptr
    nPointAlloc As c2fb_c_int
    nPoint As c2fb_c_int
    mxLevel As c2fb_c_int
    aPoint As c2fb_source_record_24 Ptr
    pReadAux As SqliteVdbe Ptr
    sPoint As c2fb_source_record_24
    aNode(0 To 4) As SqliteRtreeNode Ptr
    anQueue(0 To 41) As c2fb_c_uint
End Type

Private Union c2fb_source_record_26
    f As Single
    i As c2fb_c_int
    u As c2fb_c_uint
End Union

Private Type c2fb_source_record_27
    iRowid As c2fb_int64
    aCoord(0 To 9) As c2fb_source_record_26
End Type

Private Type c2fb_source_record_28
    db As sqlite3 Ptr
    zDb As Const ZString Ptr
    zTab As Const ZString Ptr
    bInt As c2fb_c_int
    nDim As c2fb_c_int
    pGetNode As SqliteVdbe Ptr
    aCheckMapping(0 To 1) As SqliteVdbe Ptr
    nLeaf As c2fb_c_int
    nNonLeaf As c2fb_c_int
    rc As c2fb_c_int
    zReport As ZString Ptr
    nErr As c2fb_c_int
End Type

Private Function __c2fb_single_value(ByVal value As Single) As Single
    Return value
End Function
Private Function __c2fb_double_value(ByVal value As Double) As Double
    Return value
End Function
Declare Function __bswap_16 CDecl Alias "__bswap_16" (ByVal arg0 As UShort) As UShort
Declare Function __bswap_32 CDecl Alias "__bswap_32" (ByVal arg0 As c2fb_c_uint) As c2fb_c_uint
Declare Function __bswap_64 CDecl Alias "__bswap_64" (ByVal arg0 As c2fb_c_ulong) As c2fb_c_ulong
Declare Function __uint16_identity CDecl Alias "__uint16_identity" (ByVal arg0 As UShort) As UShort
Declare Function __uint32_identity CDecl Alias "__uint32_identity" (ByVal arg0 As c2fb_c_uint) As c2fb_c_uint
Declare Function __uint64_identity CDecl Alias "__uint64_identity" (ByVal arg0 As c2fb_c_ulong) As c2fb_c_ulong
Declare Function readInt16 CDecl Alias "readInt16" (ByVal arg0 As UByte Ptr) As c2fb_c_int
Declare Sub readCoord CDecl Alias "readCoord" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_source_record_26 Ptr)
Declare Function readInt64 CDecl Alias "readInt64" (ByVal arg0 As UByte Ptr) As c2fb_int64
Declare Sub writeInt16 CDecl Alias "writeInt16" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_int)
Declare Function writeCoord CDecl Alias "writeCoord" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_source_record_26 Ptr) As c2fb_c_int
Declare Function writeInt64 CDecl Alias "writeInt64" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function rtreeValueInt32 CDecl Alias "rtreeValueInt32" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Sub nodeReference CDecl Alias "nodeReference" (ByVal arg0 As SqliteRtreeNode Ptr)
Declare Sub nodeZero CDecl Alias "nodeZero" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr)
Declare Function nodeHash CDecl Alias "nodeHash" (ByVal arg0 As c2fb_int64) As c2fb_c_uint
Declare Function nodeHashLookup CDecl Alias "nodeHashLookup" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64) As SqliteRtreeNode Ptr
Declare Sub nodeHashInsert CDecl Alias "nodeHashInsert" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr)
Declare Sub nodeHashDelete CDecl Alias "nodeHashDelete" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr)
Declare Function nodeNew CDecl Alias "nodeNew" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As SqliteRtreeNode Ptr
Declare Sub nodeBlobReset CDecl Alias "nodeBlobReset" (ByVal arg0 As c2fb_source_record_23 Ptr)
Declare Function nodeAcquire CDecl Alias "nodeAcquire" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteRtreeNode Ptr, ByVal arg3 As SqliteRtreeNode Ptr Ptr) As c2fb_c_int
Declare Sub nodeOverwriteCell CDecl Alias "nodeOverwriteCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub nodeDeleteCell CDecl Alias "nodeDeleteCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int)
Declare Function nodeInsertCell CDecl Alias "nodeInsertCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Function nodeWrite CDecl Alias "nodeWrite" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
Declare Function nodeRelease CDecl Alias "nodeRelease" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
Declare Function nodeGetRowid CDecl Alias "nodeGetRowid" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int) As c2fb_int64
Declare Sub nodeGetCoord CDecl Alias "nodeGetCoord" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_source_record_26 Ptr)
Declare Sub nodeGetCell CDecl Alias "nodeGetCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_27 Ptr)
Declare Function rtreeCreate CDecl Alias "rtreeCreate" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As SqliteVtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function rtreeConnect CDecl Alias "rtreeConnect" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As SqliteVtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub rtreeReference CDecl Alias "rtreeReference" (ByVal arg0 As c2fb_source_record_23 Ptr)
Declare Sub rtreeRelease CDecl Alias "rtreeRelease" (ByVal arg0 As c2fb_source_record_23 Ptr)
Declare Function rtreeDisconnect CDecl Alias "rtreeDisconnect" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
Declare Function rtreeDestroy CDecl Alias "rtreeDestroy" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
Declare Function rtreeOpen CDecl Alias "rtreeOpen" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As SqliteVtabCursor Ptr Ptr) As c2fb_c_int
Declare Sub resetCursor CDecl Alias "resetCursor" (ByVal arg0 As c2fb_source_record_25 Ptr)
Declare Function rtreeClose CDecl Alias "rtreeClose" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
Declare Function rtreeEof CDecl Alias "rtreeEof" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
Declare Function rtreeCallbackConstraint CDecl Alias "rtreeCallbackConstraint" (ByVal arg0 As SqliteRtreeConstraint Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_source_record_24 Ptr, ByVal arg4 As Double Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub rtreeNonleafConstraint CDecl Alias "rtreeNonleafConstraint" (ByVal arg0 As SqliteRtreeConstraint Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Sub rtreeLeafConstraint CDecl Alias "rtreeLeafConstraint" (ByVal arg0 As SqliteRtreeConstraint Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Function nodeRowidIndex CDecl Alias "nodeRowidIndex" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function nodeParentIndex CDecl Alias "nodeParentIndex" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function rtreeSearchPointCompare CDecl Alias "rtreeSearchPointCompare" (ByVal arg0 As Const c2fb_source_record_24 Ptr, ByVal arg1 As Const c2fb_source_record_24 Ptr) As c2fb_c_int
Declare Sub rtreeSearchPointSwap CDecl Alias "rtreeSearchPointSwap" (ByVal arg0 As c2fb_source_record_25 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int)
Declare Function rtreeSearchPointFirst CDecl Alias "rtreeSearchPointFirst" (ByVal arg0 As c2fb_source_record_25 Ptr) As c2fb_source_record_24 Ptr
Declare Function rtreeNodeOfFirstSearchPoint CDecl Alias "rtreeNodeOfFirstSearchPoint" (ByVal arg0 As c2fb_source_record_25 Ptr, ByVal arg1 As c2fb_c_int Ptr) As SqliteRtreeNode Ptr
Declare Function rtreeEnqueue CDecl Alias "rtreeEnqueue" (ByVal arg0 As c2fb_source_record_25 Ptr, ByVal arg1 As Double, ByVal arg2 As UByte) As c2fb_source_record_24 Ptr
Declare Function rtreeSearchPointNew CDecl Alias "rtreeSearchPointNew" (ByVal arg0 As c2fb_source_record_25 Ptr, ByVal arg1 As Double, ByVal arg2 As UByte) As c2fb_source_record_24 Ptr
Declare Sub rtreeSearchPointPop CDecl Alias "rtreeSearchPointPop" (ByVal arg0 As c2fb_source_record_25 Ptr)
Declare Function rtreeStepToLeaf CDecl Alias "rtreeStepToLeaf" (ByVal arg0 As c2fb_source_record_25 Ptr) As c2fb_c_int
Declare Function rtreeNext CDecl Alias "rtreeNext" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
Declare Function rtreeRowid CDecl Alias "rtreeRowid" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function rtreeColumn CDecl Alias "rtreeColumn" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As SqliteResultContext Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function findLeafNode CDecl Alias "findLeafNode" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteRtreeNode Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function deserializeGeometry CDecl Alias "deserializeGeometry" (ByVal arg0 As SqliteVdbeMem Ptr, ByVal arg1 As SqliteRtreeConstraint Ptr) As c2fb_c_int
Declare Function rtreeFilter CDecl Alias "rtreeFilter" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function rtreeBestIndex CDecl Alias "rtreeBestIndex" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As SqliteIndexInfo Ptr) As c2fb_c_int
Declare Function cellArea CDecl Alias "cellArea" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr) As Double
Declare Function cellMargin CDecl Alias "cellMargin" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr) As Double
Declare Sub cellUnion CDecl Alias "cellUnion" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_source_record_27 Ptr)
Declare Function cellContains CDecl Alias "cellContains" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Function cellOverlap CDecl Alias "cellOverlap" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_source_record_27 Ptr, ByVal arg3 As c2fb_c_int) As Double
Declare Function ChooseLeaf CDecl Alias "ChooseLeaf" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As SqliteRtreeNode Ptr Ptr) As c2fb_c_int
Declare Function AdjustTree CDecl Alias "AdjustTree" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Function rowidWrite CDecl Alias "rowidWrite" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function parentWrite CDecl Alias "parentWrite" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Sub SortByDimension CDecl Alias "SortByDimension" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_source_record_27 Ptr, ByVal arg5 As c2fb_c_int Ptr)
Declare Function splitNodeStartree CDecl Alias "splitNodeStartree" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As SqliteRtreeNode Ptr, ByVal arg4 As SqliteRtreeNode Ptr, ByVal arg5 As c2fb_source_record_27 Ptr, ByVal arg6 As c2fb_source_record_27 Ptr) As c2fb_c_int
Declare Function updateMapping CDecl Alias "updateMapping" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteRtreeNode Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function SplitNode CDecl Alias "SplitNode" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function fixLeafParent CDecl Alias "fixLeafParent" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
Declare Function removeNode CDecl Alias "removeNode" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fixBoundingBox CDecl Alias "fixBoundingBox" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
Declare Function deleteCell CDecl Alias "deleteCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function rtreeInsertCell CDecl Alias "rtreeInsertCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function reinsertNodeContent CDecl Alias "reinsertNodeContent" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
Declare Function rtreeNewRowid CDecl Alias "rtreeNewRowid" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function rtreeDeleteRowid CDecl Alias "rtreeDeleteRowid" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function rtreeValueDown CDecl Alias "rtreeValueDown" (ByVal arg0 As SqliteVdbeMem Ptr) As Single
Declare Function rtreeValueUp CDecl Alias "rtreeValueUp" (ByVal arg0 As SqliteVdbeMem Ptr) As Single
Declare Function rtreeConstraintError CDecl Alias "rtreeConstraintError" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function rtreeUpdate CDecl Alias "rtreeUpdate" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function rtreeBeginTransaction CDecl Alias "rtreeBeginTransaction" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
Declare Function rtreeEndTransaction CDecl Alias "rtreeEndTransaction" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
Declare Function rtreeRollback CDecl Alias "rtreeRollback" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
Declare Function rtreeRename CDecl Alias "rtreeRename" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function rtreeSavepoint CDecl Alias "rtreeSavepoint" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function rtreeQueryStat1 CDecl Alias "rtreeQueryStat1" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_23 Ptr) As c2fb_c_int
Declare Function rtreeShadowName CDecl Alias "rtreeShadowName" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function rtreeSqlInit CDecl Alias "rtreeSqlInit" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function getIntFromStmt CDecl Alias "getIntFromStmt" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function getNodeSize CDecl Alias "getNodeSize" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_23 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function rtreeTokenLength CDecl Alias "rtreeTokenLength" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function rtreeInit CDecl Alias "rtreeInit" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As SqliteVtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr, ByVal arg6 As c2fb_c_int) As c2fb_c_int
Declare Sub rtreenode CDecl Alias "rtreenode" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr)
Declare Sub rtreedepth CDecl Alias "rtreedepth" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr)
Declare Sub rtreeCheckReset CDecl Alias "rtreeCheckReset" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As SqliteVdbe Ptr)
Declare Function rtreeCheckPrepare CDecl Alias "rtreeCheckPrepare" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Const ZString Ptr, ...) As SqliteVdbe Ptr
Declare Sub rtreeCheckAppendMsg CDecl Alias "rtreeCheckAppendMsg" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Function rtreeCheckGetNode CDecl Alias "rtreeCheckGetNode" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int Ptr) As UByte Ptr
Declare Sub rtreeCheckMapping CDecl Alias "rtreeCheckMapping" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64)
Declare Sub rtreeCheckCellCoord CDecl Alias "rtreeCheckCellCoord" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As UByte Ptr)
Declare Sub rtreeCheckNode CDecl Alias "rtreeCheckNode" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_int64)
Declare Sub rtreeCheckCount CDecl Alias "rtreeCheckCount" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64)
Declare Function rtreeCheckTable CDecl Alias "rtreeCheckTable" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function rtreeIntegrity CDecl Alias "rtreeIntegrity" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Sub rtreecheck CDecl Alias "rtreecheck" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr)
Declare Sub rtreeFreeCallback CDecl Alias "rtreeFreeCallback" (ByVal arg0 As Any Ptr)
Declare Sub rtreeMatchArgFree CDecl Alias "rtreeMatchArgFree" (ByVal arg0 As Any Ptr)
Declare Sub geomCallback CDecl Alias "geomCallback" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr)
Declare Function sqlite3_rtree_geometry_callback CDecl Alias "sqlite3_rtree_geometry_callback" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_callback_154, ByVal arg3 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_rtree_query_callback CDecl Alias "sqlite3_rtree_query_callback" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_callback_155, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_callback_8) As c2fb_c_int
Declare Function c2fb_external_sqlite3_last_insert_rowid CDecl Alias "sqlite3_last_insert_rowid" (ByVal arg0 As sqlite3 Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_errmsg CDecl Alias "sqlite3_errmsg" (ByVal arg0 As sqlite3 Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_bind_blob CDecl Alias "sqlite3_bind_blob" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_callback_8) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_value CDecl Alias "sqlite3_bind_value" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_blob CDecl Alias "sqlite3_column_blob" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function c2fb_external_sqlite3_create_function_v2 CDecl Alias "sqlite3_create_function_v2" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_161, ByVal arg6 As c2fb_callback_161, ByVal arg7 As c2fb_callback_10, ByVal arg8 As c2fb_callback_8) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_blob CDecl Alias "sqlite3_value_blob" (ByVal arg0 As SqliteVdbeMem Ptr) As Const Any Ptr
Declare Function c2fb_external_sqlite3_value_double CDecl Alias "sqlite3_value_double" (ByVal arg0 As SqliteVdbeMem Ptr) As Double
Declare Function c2fb_external_sqlite3_value_int64 CDecl Alias "sqlite3_value_int64" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_value_pointer CDecl Alias "sqlite3_value_pointer" (ByVal arg0 As SqliteVdbeMem Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As SqliteVdbeMem Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_type CDecl Alias "sqlite3_value_type" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_numeric_type CDecl Alias "sqlite3_value_numeric_type" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3_value_free CDecl Alias "sqlite3_value_free" (ByVal arg0 As SqliteVdbeMem Ptr)
Declare Function c2fb_external_sqlite3_table_column_metadata CDecl Alias "sqlite3_table_column_metadata" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr, ByVal arg6 As c2fb_c_int Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_blob_open CDecl Alias "sqlite3_blob_open" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_int64, ByVal arg5 As c2fb_c_int, ByVal arg6 As Any Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_str_new CDecl Alias "sqlite3_str_new" (ByVal arg0 As sqlite3 Ptr) As sqlite3_str Ptr
Declare Function c2fb_external_sqlite3_str_finish CDecl Alias "sqlite3_str_finish" (ByVal arg0 As sqlite3_str Ptr) As ZString Ptr
Declare Sub c2fb_external_sqlite3_str_appendf CDecl Alias "sqlite3_str_appendf" (ByVal arg0 As sqlite3_str Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub c2fb_external_sqlite3_str_append CDecl Alias "sqlite3_str_append" (ByVal arg0 As sqlite3_str Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Function c2fb_external_sqlite3_str_errcode CDecl Alias "sqlite3_str_errcode" (ByVal arg0 As sqlite3_str Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vtab_on_conflict CDecl Alias "sqlite3_vtab_on_conflict" (ByVal arg0 As sqlite3 Ptr) As c2fb_c_int
Private Function __bswap_16 CDecl Alias "__bswap_16" (ByVal arg0 As UShort) As UShort
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As UShort

    c2fb_temp_0 = arg0
    Return Cast(UShort, (((Cast(ULong, Cast(UShort, c2fb_temp_0)) And Cast(ULong, &HFF)) Shl 8) Or ((Cast(ULong, Cast(UShort, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 8)) Shr 8)))
End Function
Private Function __bswap_32 CDecl Alias "__bswap_32" (ByVal arg0 As c2fb_c_uint) As c2fb_c_uint
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As c2fb_c_uint

    c2fb_temp_0 = arg0
    Return Cast(ULong, (((Cast(ULong, Cast(ULong, c2fb_temp_0)) And Cast(ULong, &HFF)) Shl 24) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 8)) Shl 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 16)) Shr 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 24)) Shr 24)))
End Function
Private Function __bswap_64 CDecl Alias "__bswap_64" (ByVal arg0 As c2fb_c_ulong) As c2fb_c_ulong
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As c2fb_c_ulong

    c2fb_temp_0 = arg0
    Return Cast(ULongInt, (((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And Cast(ULongInt, &HFF)) Shl 56) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 8)) Shl 40) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 16)) Shl 24) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 24)) Shl 8) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 32)) Shr 8) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 40)) Shr 24) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 48)) Shr 40) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 56)) Shr 56)))
End Function
Private Function __uint16_identity CDecl Alias "__uint16_identity" (ByVal arg0 As UShort) As UShort
' c2fb source-path: ext/rtree/rtree.c
    Return arg0
End Function
Private Function __uint32_identity CDecl Alias "__uint32_identity" (ByVal arg0 As c2fb_c_uint) As c2fb_c_uint
' c2fb source-path: ext/rtree/rtree.c
    Return arg0
End Function
Private Function __uint64_identity CDecl Alias "__uint64_identity" (ByVal arg0 As c2fb_c_ulong) As c2fb_c_ulong
' c2fb source-path: ext/rtree/rtree.c
    Return arg0
End Function
Private Function readInt16 CDecl Alias "readInt16" (ByVal arg0 As UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Return Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0[Cast(c2fb_c_int, &O0ULL)]) Shl Cast(c2fb_c_int, 8ULL)))) + Cast(c2fb_c_int, arg0[Cast(c2fb_c_int, 1ULL)])))
End Function
Private Sub readCoord CDecl Alias "readCoord" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_source_record_26 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint Ptr
    Dim c2fb_temp_2 As c2fb_c_uint

    ' C unused-parameter annotation
    c2fb_temp_1 = CPtr(c2fb_c_uint Ptr, @(arg1->u))
    c2fb_temp_0 = (*CPtr(c2fb_c_uint Ptr, arg0))
    c2fb_temp_2 = Cast(c2fb_c_uint, Cast(ULong, (((Cast(ULong, Cast(ULong, c2fb_temp_0)) And Cast(ULong, &HFF)) Shl 24) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 8)) Shl 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 16)) Shr 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 24)) Shr 24))))
    (*c2fb_temp_1) = c2fb_temp_2
End Sub
Private Function readInt64 CDecl Alias "readInt64" (ByVal arg0 As UByte Ptr) As c2fb_int64
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_uint64
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_uint64

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_uint64 Ptr, @(local0))), CPtr(Const Any Ptr, arg0), Cast(c2fb_c_int, 8ULL)))
    c2fb_temp_1 = local0
    Return Cast(c2fb_int64, Cast(ULongInt, (((Cast(ULongInt, Cast(ULongInt, c2fb_temp_1)) And Cast(ULongInt, &HFF)) Shl 56) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_1)) And (Cast(ULongInt, &HFF) Shl 8)) Shl 40) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_1)) And (Cast(ULongInt, &HFF) Shl 16)) Shl 24) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_1)) And (Cast(ULongInt, &HFF) Shl 24)) Shl 8) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_1)) And (Cast(ULongInt, &HFF) Shl 32)) Shr 8) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_1)) And (Cast(ULongInt, &HFF) Shl 40)) Shr 24) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_1)) And (Cast(ULongInt, &HFF) Shl 48)) Shr 40) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_1)) And (Cast(ULongInt, &HFF) Shl 56)) Shr 56))))
End Function
Private Sub writeInt16 CDecl Alias "writeInt16" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_int)
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1 Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_c_int, &HFFULL))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1 Shr Cast(c2fb_c_int, &O0ULL)))) And Cast(c2fb_c_int, &HFFULL))))
    (*c2fb_temp_2) = c2fb_temp_3
End Sub
Private Function writeCoord CDecl Alias "writeCoord" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_source_record_26 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As Any Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = arg1->u
    c2fb_temp_1 = Cast(c2fb_c_uint, Cast(ULong, (((Cast(ULong, Cast(ULong, c2fb_temp_0)) And Cast(ULong, &HFF)) Shl 24) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 8)) Shl 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 16)) Shr 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_0)) And (Cast(ULong, &HFF) Shl 24)) Shr 24))))
    local0 = c2fb_temp_1
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg0), CPtr(Const Any Ptr, CPtr(c2fb_c_uint Ptr, @(local0))), Cast(c2fb_c_int, 4ULL)))
    Return Cast(c2fb_c_int, 4ULL)
End Function
Private Function writeInt64 CDecl Alias "writeInt64" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As c2fb_uint64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Any Ptr

    c2fb_temp_0 = Cast(c2fb_uint64, arg1)
    c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_int64, Cast(ULongInt, (((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And Cast(ULongInt, &HFF)) Shl 56) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 8)) Shl 40) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 16)) Shl 24) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 24)) Shl 8) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 32)) Shr 8) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 40)) Shr 24) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 48)) Shr 40) Or ((Cast(ULongInt, Cast(ULongInt, c2fb_temp_0)) And (Cast(ULongInt, &HFF) Shl 56)) Shr 56)))))
    arg1 = c2fb_temp_1
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg0), CPtr(Const Any Ptr, CPtr(c2fb_int64 Ptr, @(arg1))), Cast(c2fb_c_int, 8ULL)))
    Return Cast(c2fb_c_int, 8ULL)
End Function
Private Function rtreeValueInt32 CDecl Alias "rtreeValueInt32" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_int64

    local0 = c2fb_external_sqlite3_value_int64(arg0)
    If (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_int64, Cast(c2fb_c_int, 2147483647ULL)))))) Then
        Return Cast(c2fb_c_int, 2147483647ULL)
    End If
    If (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_int64, (-Cast(c2fb_int64, 2147483648ULL))))))) Then
        Return Cast(c2fb_c_int, Cast(c2fb_int64, (-Cast(c2fb_int64, 2147483648ULL))))
    End If
    Return Cast(c2fb_c_int, local0)
End Function
Private Sub nodeReference CDecl Alias "nodeReference" (ByVal arg0 As SqliteRtreeNode Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg0->nRef))
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    End If
End Sub
Private Sub nodeZero CDecl Alias "nodeZero" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg1->zData[Cast(c2fb_c_int, 2ULL)]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (arg0->iNodeSize - Cast(c2fb_c_int, 2ULL)))))
    c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(arg1->isDirty))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
End Sub
Private Function nodeHash CDecl Alias "nodeHash" (ByVal arg0 As c2fb_int64) As c2fb_c_uint
' c2fb source-path: ext/rtree/rtree.c
    Return Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, arg0)) Mod Cast(c2fb_c_uint, Cast(c2fb_c_int, 97ULL))))
End Function
Private Function nodeHashLookup CDecl Alias "nodeHashLookup" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64) As SqliteRtreeNode Ptr
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As SqliteRtreeNode Ptr
    Dim c2fb_temp_1 As SqliteRtreeNode Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = arg0->aHash(nodeHash(arg1))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->iNode <> arg1)))) <> 0)))))
        ' empty C statement
    c2fb_flow_1:
        c2fb_temp_1 = local0->pNext
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Sub nodeHashInsert CDecl Alias "nodeHashInsert" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr
    Dim c2fb_temp_3 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_4 As SqliteRtreeNode Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, nodeHash(arg1->iNode))
    local0 = c2fb_temp_0
    c2fb_temp_1 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg1->pNext))
    c2fb_temp_2 = arg0->aHash(local0)
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aHash(local0)))
    c2fb_temp_4 = arg1
    (*c2fb_temp_3) = c2fb_temp_4
End Sub
Private Sub nodeHashDelete CDecl Alias "nodeHashDelete" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_0 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_1 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_3 As SqliteRtreeNode Ptr
    Dim c2fb_temp_4 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_5 As SqliteRtreeNode Ptr

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg1->iNode <> Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_0 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aHash(nodeHash(arg1->iNode))))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((((*local0)) <> arg1))))
            ' C unused-parameter annotation
        c2fb_flow_1:
            c2fb_temp_1 = CPtr(SqliteRtreeNode Ptr Ptr, @(((*local0))->pNext))
            local0 = c2fb_temp_1
        Wend
        c2fb_flow_0:
        c2fb_temp_2 = CPtr(SqliteRtreeNode Ptr Ptr, @((*local0)))
        c2fb_temp_3 = arg1->pNext
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg1->pNext))
        c2fb_temp_5 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_4) = c2fb_temp_5
    End If
End Sub
Private Function nodeNew CDecl Alias "nodeNew" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As SqliteRtreeNode Ptr
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As SqliteRtreeNode Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As UByte Ptr Ptr
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As SQLITE_C_INT Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_uint Ptr
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim c2fb_temp_8 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_9 As SqliteRtreeNode Ptr
    Dim c2fb_temp_10 As SQLITE_C_INT Ptr
    Dim c2fb_temp_11 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(SqliteRtreeNode Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteRtreeNode))) + Cast(c2fb_uint64, arg0->iNodeSize))))))
    local0 = c2fb_temp_0
    If local0 Then
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteRtreeNode))) + Cast(c2fb_uint64, arg0->iNodeSize)))))
        c2fb_temp_2 = CPtr(UByte Ptr Ptr, @(local0->zData))
        c2fb_temp_3 = CPtr(UByte Ptr, CPtr(SqliteRtreeNode Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(SQLITE_C_INT Ptr, @(local0->nRef))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_4) = Cast(SQLITE_C_INT, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
        c2fb_temp_6 = CPtr(c2fb_c_uint Ptr, @(arg0->nNodeRef))
        c2fb_temp_7 = (*c2fb_temp_6)
        (*c2fb_temp_6) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_7 + 1)))
        c2fb_temp_8 = CPtr(SqliteRtreeNode Ptr Ptr, @(local0->pParent))
        c2fb_temp_9 = arg1
        (*c2fb_temp_8) = c2fb_temp_9
        c2fb_temp_10 = CPtr(SQLITE_C_INT Ptr, @(local0->isDirty))
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_10) = Cast(SQLITE_C_INT, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        nodeReference(arg1)
    End If
    Return local0
End Function
Private Sub nodeBlobReset CDecl Alias "nodeBlobReset" (ByVal arg0 As c2fb_source_record_23 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr

    local0 = arg0->pNodeBlob
    c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->pNodeBlob))
    c2fb_temp_1 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    sqlite3_blob_close(local0)
End Sub
Private Function nodeAcquire CDecl Alias "nodeAcquire" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteRtreeNode Ptr, ByVal arg3 As SqliteRtreeNode Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As SqliteRtreeNode Ptr
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_4 As SqliteRtreeNode Ptr
    Dim local2 As Any Ptr
    Dim c2fb_temp_5 As Any Ptr Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Any Ptr Ptr
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_12 As SqliteRtreeNode Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As SqliteRtreeNode Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_18 As SqliteRtreeNode Ptr
    Dim c2fb_temp_19 As UByte Ptr Ptr
    Dim c2fb_temp_20 As UByte Ptr
    Dim c2fb_temp_21 As SQLITE_C_INT Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_uint Ptr
    Dim c2fb_temp_24 As c2fb_c_uint
    Dim c2fb_temp_25 As sqlite3_int64 Ptr
    Dim c2fb_temp_26 As c2fb_int64
    Dim c2fb_temp_27 As SQLITE_C_INT Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_30 As SqliteRtreeNode Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_38 As SqliteRtreeNode Ptr
    Dim c2fb_temp_39 As c2fb_c_uint Ptr
    Dim c2fb_temp_40 As c2fb_c_uint
    Dim c2fb_temp_41 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_42 As SqliteRtreeNode Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(SqliteRtreeNode Ptr, nodeHashLookup(arg0, arg1))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (((c2fb_temp_0) <> Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso (((-Cast(c2fb_c_int, ((arg2 <> local1->pParent))))) <> 0))))) Then
            ' empty C statement
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(local1->nRef))
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        (*c2fb_temp_1) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        c2fb_temp_3 = CPtr(SqliteRtreeNode Ptr Ptr, @((*arg3)))
        c2fb_temp_4 = local1
        (*c2fb_temp_3) = c2fb_temp_4
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If arg0->pNodeBlob Then
        local2 = arg0->pNodeBlob
        c2fb_temp_5 = CPtr(Any Ptr Ptr, @(arg0->pNodeBlob))
        c2fb_temp_6 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = Cast(c2fb_c_int, sqlite3_blob_reopen(local2, arg1))
        local0 = c2fb_temp_7
        c2fb_temp_8 = CPtr(Any Ptr Ptr, @(arg0->pNodeBlob))
        c2fb_temp_9 = local2
        (*c2fb_temp_8) = c2fb_temp_9
        If local0 Then
            nodeBlobReset(arg0)
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 7ULL))))) Then
                Return Cast(c2fb_c_int, 7ULL)
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg0->pNodeBlob = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3_blob_open(arg0->db, CPtr(Const ZString Ptr, arg0->zDb), CPtr(Const ZString Ptr, arg0->zNodeName), StrPtr(!"data"), arg1, Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr Ptr, @(arg0->pNodeBlob))))
        local0 = c2fb_temp_10
    End If
    If local0 Then
        c2fb_temp_11 = CPtr(SqliteRtreeNode Ptr Ptr, @((*arg3)))
        c2fb_temp_12 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_11) = c2fb_temp_12
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_13 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_13
            ' empty C statement
        End If
    Else
        If (-Cast(c2fb_c_int, ((arg1 <= Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
            ' empty C statement
            c2fb_temp_14 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_14
        Else
            If (-Cast(c2fb_c_int, ((arg0->iNodeSize = sqlite3_blob_bytes(arg0->pNodeBlob))))) Then
                c2fb_temp_15 = CPtr(SqliteRtreeNode Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteRtreeNode))) + Cast(c2fb_uint64, arg0->iNodeSize))))))
                local1 = c2fb_temp_15
                If (-Cast(c2fb_c_int, (local1 = 0))) Then
                    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    local0 = c2fb_temp_16
                Else
                    c2fb_temp_17 = CPtr(SqliteRtreeNode Ptr Ptr, @(local1->pParent))
                    c2fb_temp_18 = arg2
                    (*c2fb_temp_17) = c2fb_temp_18
                    c2fb_temp_19 = CPtr(UByte Ptr Ptr, @(local1->zData))
                    c2fb_temp_20 = CPtr(UByte Ptr, CPtr(SqliteRtreeNode Ptr, @(local1[Cast(c2fb_c_int, 1ULL)])))
                    (*c2fb_temp_19) = c2fb_temp_20
                    c2fb_temp_21 = CPtr(SQLITE_C_INT Ptr, @(local1->nRef))
                    c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_21) = Cast(SQLITE_C_INT, c2fb_temp_22)
                    c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
                    c2fb_temp_23 = CPtr(c2fb_c_uint Ptr, @(arg0->nNodeRef))
                    c2fb_temp_24 = (*c2fb_temp_23)
                    (*c2fb_temp_23) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_24 + 1)))
                    c2fb_temp_25 = CPtr(sqlite3_int64 Ptr, @(local1->iNode))
                    c2fb_temp_26 = Cast(c2fb_int64, arg1)
                    (*c2fb_temp_25) = Cast(sqlite3_int64, c2fb_temp_26)
                    c2fb_temp_26 = Cast(c2fb_int64, (*c2fb_temp_25))
                    c2fb_temp_27 = CPtr(SQLITE_C_INT Ptr, @(local1->isDirty))
                    c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_27) = Cast(SQLITE_C_INT, c2fb_temp_28)
                    c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
                    c2fb_temp_29 = CPtr(SqliteRtreeNode Ptr Ptr, @(local1->pNext))
                    c2fb_temp_30 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_29) = c2fb_temp_30
                    c2fb_temp_31 = Cast(c2fb_c_int, sqlite3_blob_read(arg0->pNodeBlob, CPtr(Any Ptr, local1->zData), arg0->iNodeSize, Cast(c2fb_c_int, &O0ULL)))
                    local0 = c2fb_temp_31
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) <> 0))))) Then
        c2fb_temp_32 = CPtr(c2fb_c_int Ptr, @(arg0->iDepth))
        c2fb_temp_33 = Cast(c2fb_c_int, readInt16(local1->zData))
        (*c2fb_temp_32) = c2fb_temp_33
        If (-Cast(c2fb_c_int, ((arg0->iDepth >= Cast(c2fb_c_int, 40ULL))))) Then
            c2fb_temp_34 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_34
            ' empty C statement
        End If
    End If
    If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        If (-Cast(c2fb_c_int, ((readInt16(CPtr(UByte Ptr, @((local1)->zData[Cast(c2fb_c_int, 2ULL)]))) > (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->iNodeSize - Cast(c2fb_c_int, 4ULL)))) \ Cast(c2fb_c_int, arg0->nBytesPerCell)))))))) Then
            c2fb_temp_35 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_35
            ' empty C statement
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
            nodeReference(arg2)
            nodeHashInsert(arg0, local1)
        Else
            c2fb_temp_36 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_36
            ' empty C statement
        End If
        c2fb_temp_37 = CPtr(SqliteRtreeNode Ptr Ptr, @((*arg3)))
        c2fb_temp_38 = local1
        (*c2fb_temp_37) = c2fb_temp_38
    Else
        nodeBlobReset(arg0)
        If local1 Then
            c2fb_temp_39 = CPtr(c2fb_c_uint Ptr, @(arg0->nNodeRef))
            c2fb_temp_40 = (*c2fb_temp_39)
            (*c2fb_temp_39) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_40 - 1)))
            sqlite3_free(CPtr(Any Ptr, local1))
        End If
        c2fb_temp_41 = CPtr(SqliteRtreeNode Ptr Ptr, @((*arg3)))
        c2fb_temp_42 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_41) = c2fb_temp_42
    End If
    Return local0
End Function
Private Sub nodeOverwriteCell CDecl Alias "nodeOverwriteCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As UByte Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As SQLITE_C_INT Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(UByte Ptr, @(arg1->zData[Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->nBytesPerCell) * arg3))))]))
    c2fb_temp_0 = CPtr(UByte Ptr, (local1 + writeInt64(local1, arg2->iRowid)))
    local1 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, arg0->nDim2)))))
        c2fb_temp_3 = CPtr(UByte Ptr, (local1 + writeCoord(local1, CPtr(c2fb_source_record_26 Ptr, @(arg2->aCoord(local0))))))
        local1 = c2fb_temp_3
    c2fb_flow_1:
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(SQLITE_C_INT Ptr, @(arg1->isDirty))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_4) = Cast(SQLITE_C_INT, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
End Sub
Private Sub nodeDeleteCell CDecl Alias "nodeDeleteCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As UByte Ptr
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(UByte Ptr, @(arg1->zData[Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->nBytesPerCell) * arg2))))]))
    local1 = CPtr(UByte Ptr, @(local0[arg0->nBytesPerCell]))
    local2 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, (readInt16(CPtr(UByte Ptr, @((arg1)->zData[Cast(c2fb_c_int, 2ULL)]))) - arg2)) - Cast(c2fb_c_int, 1ULL)))) * Cast(c2fb_c_int, arg0->nBytesPerCell)))
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, local0), CPtr(Const Any Ptr, local1), local2))
    writeInt16(CPtr(UByte Ptr, @(arg1->zData[Cast(c2fb_c_int, 2ULL)])), Cast(c2fb_c_int, (readInt16(CPtr(UByte Ptr, @((arg1)->zData[Cast(c2fb_c_int, 2ULL)]))) - Cast(c2fb_c_int, 1ULL))))
    c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(arg1->isDirty))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
End Sub
Private Function nodeInsertCell CDecl Alias "nodeInsertCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As SQLITE_C_INT Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->iNodeSize - Cast(c2fb_c_int, 4ULL)))) \ Cast(c2fb_c_int, arg0->nBytesPerCell))))
    local1 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, readInt16(CPtr(UByte Ptr, @((arg1)->zData[Cast(c2fb_c_int, 2ULL)]))))
    local0 = c2fb_temp_1
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0 < local1)))) Then
        nodeOverwriteCell(arg0, arg1, arg2, local0)
        writeInt16(CPtr(UByte Ptr, @(arg1->zData[Cast(c2fb_c_int, 2ULL)])), Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))))
        c2fb_temp_2 = CPtr(SQLITE_C_INT Ptr, @(arg1->isDirty))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_2) = Cast(SQLITE_C_INT, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    End If
    Return ((-Cast(c2fb_c_int, ((local0 = local1)))))
End Function
Private Function nodeWrite CDecl Alias "nodeWrite" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteVdbe Ptr
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As sqlite3_int64 Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg1->isDirty Then
        local1 = arg0->pWriteNode
        If arg1->iNode Then
            sqlite3_bind_int64(CPtr(Any Ptr, local1), Cast(c2fb_c_int, 1ULL), arg1->iNode)
        Else
            sqlite3_bind_null(CPtr(Any Ptr, local1), Cast(c2fb_c_int, 1ULL))
        End If
        c2fb_external_sqlite3_bind_blob(local1, Cast(c2fb_c_int, 2ULL), CPtr(Const Any Ptr, arg1->zData), arg0->iNodeSize, (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        sqlite3_step(CPtr(Any Ptr, local1))
        c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg1->isDirty))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, local1)))
        local0 = c2fb_temp_2
        sqlite3_bind_null(CPtr(Any Ptr, local1), Cast(c2fb_c_int, 2ULL))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->iNode = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_3 = CPtr(sqlite3_int64 Ptr, @(arg1->iNode))
            c2fb_temp_4 = Cast(c2fb_int64, c2fb_external_sqlite3_last_insert_rowid(arg0->db))
            (*c2fb_temp_3) = Cast(sqlite3_int64, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_int64, (*c2fb_temp_3))
            If (-Cast(c2fb_c_int, ((arg1->iNode = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                local0 = c2fb_temp_5
            Else
                nodeHashInsert(arg0, arg1)
            End If
        End If
    End If
    Return local0
End Function
Private Function nodeRelease CDecl Alias "nodeRelease" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_uint Ptr
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg1 Then
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg1->nRef))
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
        If (-Cast(c2fb_c_int, ((arg1->nRef = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(c2fb_c_uint Ptr, @(arg0->nNodeRef))
            c2fb_temp_3 = (*c2fb_temp_2)
            (*c2fb_temp_2) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_3 - 1)))
            If (-Cast(c2fb_c_int, ((arg1->iNode = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) Then
                c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->iDepth))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_4) = c2fb_temp_5
            End If
            If arg1->pParent Then
                c2fb_temp_6 = Cast(c2fb_c_int, nodeRelease(arg0, arg1->pParent))
                local0 = c2fb_temp_6
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_7 = Cast(c2fb_c_int, nodeWrite(arg0, arg1))
                local0 = c2fb_temp_7
            End If
            nodeHashDelete(arg0, arg1)
            sqlite3_free(CPtr(Any Ptr, arg1))
        End If
    End If
    Return local0
End Function
Private Function nodeGetRowid CDecl Alias "nodeGetRowid" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int) As c2fb_int64
' c2fb source-path: ext/rtree/rtree.c
    ' C unused-parameter annotation
    Return readInt64(CPtr(UByte Ptr, @(arg1->zData[Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->nBytesPerCell) * arg2))))])))
End Function
Private Sub nodeGetCoord CDecl Alias "nodeGetCoord" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_source_record_26 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    ' C unused-parameter annotation
    readCoord(CPtr(UByte Ptr, @(arg1->zData[Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 12ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->nBytesPerCell) * arg2)))) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * arg3))))])), arg4)
End Sub
Private Sub nodeGetCell CDecl Alias "nodeGetCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_27 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_source_record_26 Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As c2fb_source_record_26 Ptr
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(arg3->iRowid))
    c2fb_temp_1 = Cast(c2fb_int64, nodeGetRowid(arg0, arg1, arg2))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, (arg1->zData + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 12ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->nBytesPerCell) * arg2)))))))
    local0 = c2fb_temp_2
    c2fb_temp_3 = CPtr(c2fb_source_record_26 Ptr, (@arg3->aCoord(0)))
    local1 = c2fb_temp_3
    Do
        readCoord(local0, CPtr(c2fb_source_record_26 Ptr, @(local1[local2])))
        readCoord(CPtr(UByte Ptr, (local0 + Cast(c2fb_c_int, 4ULL))), CPtr(c2fb_source_record_26 Ptr, @(local1[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))])))
        c2fb_temp_4 = CPtr(UByte Ptr, (local0 + Cast(c2fb_c_int, 8ULL)))
        local0 = c2fb_temp_4
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 2ULL))))
        local2 = c2fb_temp_5
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, arg0->nDim2)))))
    c2fb_flow_0:
End Sub
Private Function rtreeCreate CDecl Alias "rtreeCreate" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As SqliteVtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Return rtreeInit(arg0, arg1, arg2, arg3, arg4, arg5, Cast(c2fb_c_int, 1ULL))
End Function
Private Function rtreeConnect CDecl Alias "rtreeConnect" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As SqliteVtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Return rtreeInit(arg0, arg1, arg2, arg3, arg4, arg5, Cast(c2fb_c_int, &O0ULL))
End Function
Private Sub rtreeReference CDecl Alias "rtreeReference" (ByVal arg0 As c2fb_source_record_23 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As c2fb_c_uint Ptr
    Dim c2fb_temp_1 As c2fb_c_uint

    c2fb_temp_0 = CPtr(c2fb_c_uint Ptr, @(arg0->nBusy))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_1 + 1)))
End Sub
Private Sub rtreeRelease CDecl Alias "rtreeRelease" (ByVal arg0 As c2fb_source_record_23 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim c2fb_temp_0 As c2fb_c_uint Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local1 As SqliteRtreeNode Ptr
    Dim c2fb_temp_6 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_7 As SqliteRtreeNode Ptr

    c2fb_temp_0 = CPtr(c2fb_c_uint Ptr, @(arg0->nBusy))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_1 - 1)))
    If (-Cast(c2fb_c_int, ((arg0->nBusy = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_2 = CPtr(UByte Ptr, @(arg0->inWrTrans))
        c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = c2fb_temp_3
        ' C unused-parameter annotation
        nodeBlobReset(arg0)
        If arg0->nNodeRef Then
            ' C automatic storage declaration
            ' C unused-parameter annotation
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_4
            While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, 97ULL)))))
                While arg0->aHash(local0)
                    local1 = arg0->aHash(local0)->pNext
                    sqlite3_free(CPtr(Any Ptr, arg0->aHash(local0)))
                    c2fb_temp_6 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aHash(local0)))
                    c2fb_temp_7 = local1
                    (*c2fb_temp_6) = c2fb_temp_7
                c2fb_flow_3:
                Wend
                c2fb_flow_2:
            c2fb_flow_1:
                c2fb_temp_5 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
            Wend
            c2fb_flow_0:
        End If
        sqlite3_finalize(CPtr(Any Ptr, arg0->pWriteNode))
        sqlite3_finalize(CPtr(Any Ptr, arg0->pDeleteNode))
        sqlite3_finalize(CPtr(Any Ptr, arg0->pReadRowid))
        sqlite3_finalize(CPtr(Any Ptr, arg0->pWriteRowid))
        sqlite3_finalize(CPtr(Any Ptr, arg0->pDeleteRowid))
        sqlite3_finalize(CPtr(Any Ptr, arg0->pReadParent))
        sqlite3_finalize(CPtr(Any Ptr, arg0->pWriteParent))
        sqlite3_finalize(CPtr(Any Ptr, arg0->pDeleteParent))
        sqlite3_finalize(CPtr(Any Ptr, arg0->pWriteAux))
        sqlite3_free(CPtr(Any Ptr, arg0->zReadAuxSql))
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Private Function rtreeDisconnect CDecl Alias "rtreeDisconnect" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    rtreeRelease(CPtr(c2fb_source_record_23 Ptr, arg0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rtreeDestroy CDecl Alias "rtreeDestroy" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0)
    ' C automatic storage declaration
    local2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"DROP TABLE '%q'.'%q_node';DROP TABLE '%q'.'%q_rowid';DROP TABLE '%q'.'%q_parent';"), local0->zDb, local0->zName, local0->zDb, local0->zName, local0->zDb, local0->zName))
    If (-Cast(c2fb_c_int, (local2 = 0))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local1 = c2fb_temp_0
    Else
        nodeBlobReset(local0)
        c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_exec(CPtr(Any Ptr, local0->db), CPtr(Const ZString Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_1
        sqlite3_free(CPtr(Any Ptr, local2))
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        rtreeRelease(local0)
    End If
    Return local1
End Function
Private Function rtreeOpen CDecl Alias "rtreeOpen" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As SqliteVtabCursor Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_23 Ptr
    Dim local2 As c2fb_source_record_25 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_25 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As SqliteVtab Ptr Ptr
    Dim c2fb_temp_3 As SqliteVtab Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_uint Ptr
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As SqliteVtabCursor Ptr Ptr
    Dim c2fb_temp_8 As SqliteVtabCursor Ptr

    local0 = Cast(c2fb_c_int, 7ULL)
    local1 = CPtr(c2fb_source_record_23 Ptr, arg0)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_25 Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_source_record_25)))))
    local2 = c2fb_temp_0
    If local2 Then
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_25))))
        c2fb_temp_2 = CPtr(SqliteVtab Ptr Ptr, @(local2->base.pVtab))
        c2fb_temp_3 = arg0
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_4
        c2fb_temp_5 = CPtr(c2fb_c_uint Ptr, @(local1->nCursor))
        c2fb_temp_6 = (*c2fb_temp_5)
        (*c2fb_temp_5) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_6 + 1)))
    End If
    c2fb_temp_7 = CPtr(SqliteVtabCursor Ptr Ptr, @((*arg1)))
    c2fb_temp_8 = CPtr(SqliteVtabCursor Ptr, local2)
    (*c2fb_temp_7) = c2fb_temp_8
    Return local0
End Function
Private Sub resetCursor CDecl Alias "resetCursor" (ByVal arg0 As c2fb_source_record_25 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteVdbe Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As SqliteRtreeQueryInfo Ptr
    Dim c2fb_temp_2 As SqliteRtreeConstraint Ptr Ptr
    Dim c2fb_temp_3 As SqliteRtreeConstraint Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As SqliteVdbe Ptr
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As SqliteVtab Ptr Ptr
    Dim c2fb_temp_9 As SqliteVtab Ptr
    Dim c2fb_temp_10 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_11 As SqliteVdbe Ptr

    local0 = CPtr(c2fb_source_record_23 Ptr, (arg0->base.pVtab))
    ' C automatic storage declaration
    ' C automatic storage declaration
    If arg0->aConstraint Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local3 < arg0->nConstraint))))
            local4 = arg0->aConstraint[local3].pInfo
            If local4 Then
                If CPtr(c2fb_callback_8, local4->xDelUser) Then
                    CPtr(c2fb_callback_8, local4->xDelUser)(local4->pUser)
                End If
                sqlite3_free(CPtr(Any Ptr, local4))
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        sqlite3_free(CPtr(Any Ptr, arg0->aConstraint))
        c2fb_temp_2 = CPtr(SqliteRtreeConstraint Ptr Ptr, @(arg0->aConstraint))
        c2fb_temp_3 = CPtr(SqliteRtreeConstraint Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_2) = c2fb_temp_3
    End If
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, 5ULL)))))
        nodeRelease(local0, arg0->aNode(local1))
    c2fb_flow_3:
        c2fb_temp_5 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_2:
    sqlite3_free(CPtr(Any Ptr, arg0->aPoint))
    c2fb_temp_6 = arg0->pReadAux
    local2 = c2fb_temp_6
    c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_25))))
    c2fb_temp_8 = CPtr(SqliteVtab Ptr Ptr, @(arg0->base.pVtab))
    c2fb_temp_9 = CPtr(SqliteVtab Ptr, local0)
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pReadAux))
    c2fb_temp_11 = local2
    (*c2fb_temp_10) = c2fb_temp_11
    sqlite3_reset(CPtr(Any Ptr, local2))
End Sub
Private Function rtreeClose CDecl Alias "rtreeClose" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_source_record_25 Ptr
    Dim c2fb_temp_0 As c2fb_c_uint Ptr
    Dim c2fb_temp_1 As c2fb_c_uint

    local0 = CPtr(c2fb_source_record_23 Ptr, (arg0->pVtab))
    local1 = CPtr(c2fb_source_record_25 Ptr, arg0)
    ' C unused-parameter annotation
    resetCursor(local1)
    sqlite3_finalize(CPtr(Any Ptr, local1->pReadAux))
    sqlite3_free(CPtr(Any Ptr, local1))
    c2fb_temp_0 = CPtr(c2fb_c_uint Ptr, @(local0->nCursor))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_1 - 1)))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->nCursor = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->inWrTrans) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        nodeBlobReset(local0)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rtreeEof CDecl Alias "rtreeEof" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_25 Ptr

    local0 = CPtr(c2fb_source_record_25 Ptr, arg0)
    Return local0->atEOF
End Function
Private Function rtreeCallbackConstraint CDecl Alias "rtreeCallbackConstraint" (ByVal arg0 As SqliteRtreeConstraint Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_source_record_24 Ptr, ByVal arg4 As Double Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeQueryInfo Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_source_record_26
    Dim local4(0 To 9) As Double
    Dim c2fb_temp_0 As sqlite3_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As Double Ptr
    Dim c2fb_temp_4 As Double
    Dim c2fb_temp_5 As Double Ptr
    Dim c2fb_temp_6 As Double
    Dim c2fb_temp_7 As Double Ptr
    Dim c2fb_temp_8 As Double
    Dim c2fb_temp_9 As Double Ptr
    Dim c2fb_temp_10 As Double
    Dim c2fb_temp_11 As Double Ptr
    Dim c2fb_temp_12 As Double
    Dim c2fb_temp_13 As Double Ptr
    Dim c2fb_temp_14 As Double
    Dim c2fb_temp_15 As Double Ptr
    Dim c2fb_temp_16 As Double
    Dim c2fb_temp_17 As Double Ptr
    Dim c2fb_temp_18 As Double
    Dim c2fb_temp_19 As Double Ptr
    Dim c2fb_temp_20 As Double
    Dim c2fb_temp_21 As Double Ptr
    Dim c2fb_temp_22 As Double
    Dim c2fb_switch_value_23 As c2fb_uint64
    Dim c2fb_switch_state_24 As c2fb_c_int
    Dim c2fb_temp_25 As Double Ptr
    Dim c2fb_temp_26 As Double
    Dim c2fb_temp_27 As Double Ptr
    Dim c2fb_temp_28 As Double
    Dim c2fb_temp_29 As Double Ptr
    Dim c2fb_temp_30 As Double
    Dim c2fb_temp_31 As Double Ptr
    Dim c2fb_temp_32 As Double
    Dim c2fb_temp_33 As Double Ptr
    Dim c2fb_temp_34 As Double
    Dim c2fb_temp_35 As Double Ptr
    Dim c2fb_temp_36 As Double
    Dim c2fb_temp_37 As Double Ptr
    Dim c2fb_temp_38 As Double
    Dim c2fb_temp_39 As Double Ptr
    Dim c2fb_temp_40 As Double
    Dim c2fb_temp_41 As Double Ptr
    Dim c2fb_temp_42 As Double
    Dim c2fb_temp_43 As Double Ptr
    Dim c2fb_temp_44 As Double
    Dim c2fb_switch_value_45 As c2fb_uint64
    Dim c2fb_switch_state_46 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int Ptr
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As Double Ptr
    Dim c2fb_temp_51 As Double
    Dim c2fb_temp_52 As SqliteRtreeDValue Ptr Ptr
    Dim c2fb_temp_53 As Double Ptr
    Dim c2fb_temp_54 As SQLITE_C_INT Ptr
    Dim c2fb_temp_55 As c2fb_c_int
    Dim c2fb_temp_56 As SqliteRtreeDValue Ptr
    Dim c2fb_temp_57 As Double
    Dim c2fb_temp_58 As SqliteRtreeDValue Ptr
    Dim c2fb_temp_59 As Double
    Dim c2fb_temp_60 As SQLITE_C_INT Ptr
    Dim c2fb_temp_61 As c2fb_c_int
    Dim c2fb_temp_62 As SQLITE_C_INT Ptr
    Dim c2fb_temp_63 As c2fb_c_int
    Dim c2fb_temp_64 As c2fb_c_int
    Dim c2fb_temp_65 As c2fb_c_int Ptr
    Dim c2fb_temp_66 As c2fb_c_int
    Dim c2fb_temp_67 As Double Ptr
    Dim c2fb_temp_68 As Double

    local0 = arg0->pInfo
    local1 = local0->nCoord
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic array storage
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->op = Cast(c2fb_c_int, &H47ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg3->iLevel) = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(sqlite3_int64 Ptr, @(local0->iRowid))
        c2fb_temp_1 = Cast(c2fb_int64, readInt64(arg2))
        (*c2fb_temp_0) = Cast(sqlite3_int64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    End If
    c2fb_temp_2 = CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 8ULL)))
    arg2 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_switch_value_23 = Cast(c2fb_uint64, local1)
        c2fb_switch_state_24 = 0
        Select Case c2fb_switch_value_23
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 10ULL))
                c2fb_switch_state_24 = 1
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 8ULL))
                c2fb_switch_state_24 = 2
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 6ULL))
                c2fb_switch_state_24 = 3
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))
                c2fb_switch_state_24 = 4
            Case Else
                c2fb_switch_state_24 = 5
        End Select
        Do
            Select Case c2fb_switch_state_24
            Case 0
                Exit Do
            Case 1
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 36ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_3 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 9ULL))))
                c2fb_temp_4 = Cast(Double, local3.f)
                (*c2fb_temp_3) = c2fb_temp_4
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 32ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_5 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 8ULL))))
                c2fb_temp_6 = Cast(Double, local3.f)
                (*c2fb_temp_5) = c2fb_temp_6
                c2fb_switch_state_24 = 2
            Case 2
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 28ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_7 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 7ULL))))
                c2fb_temp_8 = Cast(Double, local3.f)
                (*c2fb_temp_7) = c2fb_temp_8
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 24ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_9 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 6ULL))))
                c2fb_temp_10 = Cast(Double, local3.f)
                (*c2fb_temp_9) = c2fb_temp_10
                c2fb_switch_state_24 = 3
            Case 3
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 20ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_11 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 5ULL))))
                c2fb_temp_12 = Cast(Double, local3.f)
                (*c2fb_temp_11) = c2fb_temp_12
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 16ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_13 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 4ULL))))
                c2fb_temp_14 = Cast(Double, local3.f)
                (*c2fb_temp_13) = c2fb_temp_14
                c2fb_switch_state_24 = 4
            Case 4
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 12ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_15 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 3ULL))))
                c2fb_temp_16 = Cast(Double, local3.f)
                (*c2fb_temp_15) = c2fb_temp_16
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 8ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_17 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 2ULL))))
                c2fb_temp_18 = Cast(Double, local3.f)
                (*c2fb_temp_17) = c2fb_temp_18
                c2fb_switch_state_24 = 5
            Case 5
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 4ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_19 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 1ULL))))
                c2fb_temp_20 = Cast(Double, local3.f)
                (*c2fb_temp_19) = c2fb_temp_20
                readCoord(arg2, CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_21 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, &O0ULL))))
                c2fb_temp_22 = Cast(Double, local3.f)
                (*c2fb_temp_21) = c2fb_temp_22
                c2fb_switch_state_24 = 0
            End Select
        Loop
        c2fb_flow_0:
    Else
        c2fb_switch_value_45 = Cast(c2fb_uint64, local1)
        c2fb_switch_state_46 = 0
        Select Case c2fb_switch_value_45
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 10ULL))
                c2fb_switch_state_46 = 1
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 8ULL))
                c2fb_switch_state_46 = 2
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 6ULL))
                c2fb_switch_state_46 = 3
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))
                c2fb_switch_state_46 = 4
            Case Else
                c2fb_switch_state_46 = 5
        End Select
        Do
            Select Case c2fb_switch_state_46
            Case 0
                Exit Do
            Case 1
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 36ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_25 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 9ULL))))
                c2fb_temp_26 = Cast(Double, local3.i)
                (*c2fb_temp_25) = c2fb_temp_26
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 32ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_27 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 8ULL))))
                c2fb_temp_28 = Cast(Double, local3.i)
                (*c2fb_temp_27) = c2fb_temp_28
                c2fb_switch_state_46 = 2
            Case 2
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 28ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_29 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 7ULL))))
                c2fb_temp_30 = Cast(Double, local3.i)
                (*c2fb_temp_29) = c2fb_temp_30
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 24ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_31 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 6ULL))))
                c2fb_temp_32 = Cast(Double, local3.i)
                (*c2fb_temp_31) = c2fb_temp_32
                c2fb_switch_state_46 = 3
            Case 3
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 20ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_33 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 5ULL))))
                c2fb_temp_34 = Cast(Double, local3.i)
                (*c2fb_temp_33) = c2fb_temp_34
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 16ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_35 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 4ULL))))
                c2fb_temp_36 = Cast(Double, local3.i)
                (*c2fb_temp_35) = c2fb_temp_36
                c2fb_switch_state_46 = 4
            Case 4
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 12ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_37 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 3ULL))))
                c2fb_temp_38 = Cast(Double, local3.i)
                (*c2fb_temp_37) = c2fb_temp_38
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 8ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_39 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 2ULL))))
                c2fb_temp_40 = Cast(Double, local3.i)
                (*c2fb_temp_39) = c2fb_temp_40
                c2fb_switch_state_46 = 5
            Case 5
                readCoord(CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 4ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_41 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, 1ULL))))
                c2fb_temp_42 = Cast(Double, local3.i)
                (*c2fb_temp_41) = c2fb_temp_42
                readCoord(arg2, CPtr(c2fb_source_record_26 Ptr, @(local3)))
                c2fb_temp_43 = CPtr(Double Ptr, @(local4(Cast(c2fb_c_int, &O0ULL))))
                c2fb_temp_44 = Cast(Double, local3.i)
                (*c2fb_temp_43) = c2fb_temp_44
                c2fb_switch_state_46 = 0
            End Select
        Loop
        c2fb_flow_1:
    End If
    If (-Cast(c2fb_c_int, ((arg0->op = Cast(c2fb_c_int, &H46ULL))))) Then
        local5 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_47 = Cast(c2fb_c_int, CPtr(c2fb_callback_154, arg0->u.xGeom)(CPtr(SqliteRtreeGeometry Ptr, local0), local1, CPtr(Double Ptr, (@local4(0))), CPtr(c2fb_c_int Ptr, @(local5))))
        local2 = c2fb_temp_47
        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_48 = CPtr(c2fb_c_int Ptr, @((*arg5)))
            c2fb_temp_49 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_48) = c2fb_temp_49
        End If
        c2fb_temp_50 = CPtr(Double Ptr, @((*arg4)))
        c2fb_temp_51 = Cast(Double, 0.0#)
        (*c2fb_temp_50) = c2fb_temp_51
    Else
        c2fb_temp_52 = CPtr(SqliteRtreeDValue Ptr Ptr, @(local0->aCoord))
        c2fb_temp_53 = CPtr(Double Ptr, (@local4(0)))
        (*c2fb_temp_52) = CPtr(SqliteRtreeDValue Ptr, c2fb_temp_53)
        c2fb_temp_53 = CPtr(Double Ptr, (*c2fb_temp_52))
        c2fb_temp_54 = CPtr(SQLITE_C_INT Ptr, @(local0->iLevel))
        c2fb_temp_55 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, arg3->iLevel) - Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_54) = Cast(SQLITE_C_INT, c2fb_temp_55)
        c2fb_temp_55 = Cast(c2fb_c_int, (*c2fb_temp_54))
        c2fb_temp_58 = CPtr(SqliteRtreeDValue Ptr, @(local0->rScore))
        c2fb_temp_56 = CPtr(SqliteRtreeDValue Ptr, @(local0->rParentScore))
        c2fb_temp_57 = Cast(Double, arg3->rScore)
        (*c2fb_temp_56) = Cast(SqliteRtreeDValue, c2fb_temp_57)
        c2fb_temp_57 = Cast(Double, (*c2fb_temp_56))
        c2fb_temp_59 = Cast(Double, c2fb_temp_57)
        (*c2fb_temp_58) = Cast(SqliteRtreeDValue, c2fb_temp_59)
        c2fb_temp_59 = Cast(Double, (*c2fb_temp_58))
        c2fb_temp_62 = CPtr(SQLITE_C_INT Ptr, @(local0->eWithin))
        c2fb_temp_60 = CPtr(SQLITE_C_INT Ptr, @(local0->eParentWithin))
        c2fb_temp_61 = Cast(c2fb_c_int, arg3->eWithin)
        (*c2fb_temp_60) = Cast(SQLITE_C_INT, c2fb_temp_61)
        c2fb_temp_61 = Cast(c2fb_c_int, (*c2fb_temp_60))
        c2fb_temp_63 = Cast(c2fb_c_int, c2fb_temp_61)
        (*c2fb_temp_62) = Cast(SQLITE_C_INT, c2fb_temp_63)
        c2fb_temp_63 = Cast(c2fb_c_int, (*c2fb_temp_62))
        c2fb_temp_64 = Cast(c2fb_c_int, CPtr(c2fb_callback_155, arg0->u.xQueryFunc)(local0))
        local2 = c2fb_temp_64
        If (-Cast(c2fb_c_int, ((local0->eWithin < (*arg5))))) Then
            c2fb_temp_65 = CPtr(c2fb_c_int Ptr, @((*arg5)))
            c2fb_temp_66 = Cast(c2fb_c_int, local0->eWithin)
            (*c2fb_temp_65) = c2fb_temp_66
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(Double, local0->rScore) < (*arg4))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((*arg4) < 0.0#)))) <> 0))))) Then
            c2fb_temp_67 = CPtr(Double Ptr, @((*arg4)))
            c2fb_temp_68 = Cast(Double, Cast(Double, local0->rScore))
            (*c2fb_temp_67) = c2fb_temp_68
        End If
    End If
    Return local2
End Function
Private Sub rtreeNonleafConstraint CDecl Alias "rtreeNonleafConstraint" (ByVal arg0 As SqliteRtreeConstraint Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Double
    Dim c2fb_temp_0 As UByte Ptr
    Dim local1 As c2fb_source_record_26
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_c_uint Ptr
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As Double
    Dim c2fb_temp_5 As UByte Ptr
    Dim local2 As c2fb_source_record_26
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_c_uint Ptr
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As Double
    Dim local3 As c2fb_source_record_26
    Dim c2fb_temp_10 As c2fb_c_uint
    Dim c2fb_temp_11 As c2fb_c_uint Ptr
    Dim c2fb_temp_12 As c2fb_c_uint
    Dim c2fb_temp_13 As Double
    Dim c2fb_temp_14 As UByte Ptr
    Dim local4 As c2fb_source_record_26
    Dim c2fb_temp_15 As c2fb_c_uint
    Dim c2fb_temp_16 As c2fb_c_uint Ptr
    Dim c2fb_temp_17 As c2fb_c_uint
    Dim c2fb_temp_18 As Double
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * (Cast(c2fb_c_int, (arg0->iCoord And Cast(c2fb_c_int, &HfeULL))))))))))
    arg2 = c2fb_temp_0
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    Select Case arg0->op
        Case Cast(c2fb_c_int, &H3fULL)
            Return
        Case Cast(c2fb_c_int, &H40ULL)
        Case Cast(c2fb_c_int, &H41ULL)
            ' C automatic storage declaration
            c2fb_temp_2 = CPtr(c2fb_c_uint Ptr, @(local1.u))
            c2fb_temp_1 = (*CPtr(c2fb_c_uint Ptr, arg2))
            c2fb_temp_3 = Cast(c2fb_c_uint, Cast(ULong, (((Cast(ULong, Cast(ULong, c2fb_temp_1)) And Cast(ULong, &HFF)) Shl 24) Or ((Cast(ULong, Cast(ULong, c2fb_temp_1)) And (Cast(ULong, &HFF) Shl 8)) Shl 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_1)) And (Cast(ULong, &HFF) Shl 16)) Shr 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_1)) And (Cast(ULong, &HFF) Shl 24)) Shr 24))))
            (*c2fb_temp_2) = c2fb_temp_3
            c2fb_temp_4 = Cast(Double, IIf(arg1, __c2fb_double_value(Cast(Double, local1.i)), __c2fb_double_value(Cast(Double, local1.f))))
            local0 = c2fb_temp_4
            ' empty C statement
            If (-Cast(c2fb_c_int, ((Cast(Double, arg0->u.rValue) >= local0)))) Then
                c2fb_temp_5 = CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 4ULL)))
                arg2 = c2fb_temp_5
                ' C automatic storage declaration
                c2fb_temp_7 = CPtr(c2fb_c_uint Ptr, @(local2.u))
                c2fb_temp_6 = (*CPtr(c2fb_c_uint Ptr, arg2))
                c2fb_temp_8 = Cast(c2fb_c_uint, Cast(ULong, (((Cast(ULong, Cast(ULong, c2fb_temp_6)) And Cast(ULong, &HFF)) Shl 24) Or ((Cast(ULong, Cast(ULong, c2fb_temp_6)) And (Cast(ULong, &HFF) Shl 8)) Shl 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_6)) And (Cast(ULong, &HFF) Shl 16)) Shr 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_6)) And (Cast(ULong, &HFF) Shl 24)) Shr 24))))
                (*c2fb_temp_7) = c2fb_temp_8
                c2fb_temp_9 = Cast(Double, IIf(arg1, __c2fb_double_value(Cast(Double, local2.i)), __c2fb_double_value(Cast(Double, local2.f))))
                local0 = c2fb_temp_9
                ' empty C statement
                If (-Cast(c2fb_c_int, ((Cast(Double, arg0->u.rValue) <= local0)))) Then
                    Return
                End If
            End If
        Case Cast(c2fb_c_int, &H42ULL), Cast(c2fb_c_int, &H43ULL)
            ' C automatic storage declaration
            c2fb_temp_11 = CPtr(c2fb_c_uint Ptr, @(local3.u))
            c2fb_temp_10 = (*CPtr(c2fb_c_uint Ptr, arg2))
            c2fb_temp_12 = Cast(c2fb_c_uint, Cast(ULong, (((Cast(ULong, Cast(ULong, c2fb_temp_10)) And Cast(ULong, &HFF)) Shl 24) Or ((Cast(ULong, Cast(ULong, c2fb_temp_10)) And (Cast(ULong, &HFF) Shl 8)) Shl 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_10)) And (Cast(ULong, &HFF) Shl 16)) Shr 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_10)) And (Cast(ULong, &HFF) Shl 24)) Shr 24))))
            (*c2fb_temp_11) = c2fb_temp_12
            c2fb_temp_13 = Cast(Double, IIf(arg1, __c2fb_double_value(Cast(Double, local3.i)), __c2fb_double_value(Cast(Double, local3.f))))
            local0 = c2fb_temp_13
            ' empty C statement
            If (-Cast(c2fb_c_int, ((Cast(Double, arg0->u.rValue) >= local0)))) Then
                Return
            End If
        Case Else
            c2fb_temp_14 = CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, 4ULL)))
            arg2 = c2fb_temp_14
            ' C automatic storage declaration
            c2fb_temp_16 = CPtr(c2fb_c_uint Ptr, @(local4.u))
            c2fb_temp_15 = (*CPtr(c2fb_c_uint Ptr, arg2))
            c2fb_temp_17 = Cast(c2fb_c_uint, Cast(ULong, (((Cast(ULong, Cast(ULong, c2fb_temp_15)) And Cast(ULong, &HFF)) Shl 24) Or ((Cast(ULong, Cast(ULong, c2fb_temp_15)) And (Cast(ULong, &HFF) Shl 8)) Shl 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_15)) And (Cast(ULong, &HFF) Shl 16)) Shr 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_15)) And (Cast(ULong, &HFF) Shl 24)) Shr 24))))
            (*c2fb_temp_16) = c2fb_temp_17
            c2fb_temp_18 = Cast(Double, IIf(arg1, __c2fb_double_value(Cast(Double, local4.i)), __c2fb_double_value(Cast(Double, local4.f))))
            local0 = c2fb_temp_18
            ' empty C statement
            If (-Cast(c2fb_c_int, ((Cast(Double, arg0->u.rValue) <= local0)))) Then
                Return
            End If
    End Select
    c2fb_flow_0:
    c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_19) = c2fb_temp_20
End Sub
Private Sub rtreeLeafConstraint CDecl Alias "rtreeLeafConstraint" (ByVal arg0 As SqliteRtreeConstraint Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Double
    Dim c2fb_temp_0 As UByte Ptr
    Dim local1 As c2fb_source_record_26
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_c_uint Ptr
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As Double
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(UByte Ptr, (arg2 + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) + Cast(c2fb_c_int, (arg0->iCoord * Cast(c2fb_c_int, 4ULL)))))))
    arg2 = c2fb_temp_0
    ' C unused-parameter annotation
    ' C automatic storage declaration
    c2fb_temp_2 = CPtr(c2fb_c_uint Ptr, @(local1.u))
    c2fb_temp_1 = (*CPtr(c2fb_c_uint Ptr, arg2))
    c2fb_temp_3 = Cast(c2fb_c_uint, Cast(ULong, (((Cast(ULong, Cast(ULong, c2fb_temp_1)) And Cast(ULong, &HFF)) Shl 24) Or ((Cast(ULong, Cast(ULong, c2fb_temp_1)) And (Cast(ULong, &HFF) Shl 8)) Shl 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_1)) And (Cast(ULong, &HFF) Shl 16)) Shr 8) Or ((Cast(ULong, Cast(ULong, c2fb_temp_1)) And (Cast(ULong, &HFF) Shl 24)) Shr 24))))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = Cast(Double, IIf(arg1, __c2fb_double_value(Cast(Double, local1.i)), __c2fb_double_value(Cast(Double, local1.f))))
    local0 = c2fb_temp_4
    ' empty C statement
    Select Case arg0->op
        Case Cast(c2fb_c_int, &H3fULL)
            Return
        Case Cast(c2fb_c_int, &H40ULL)
        Case Cast(c2fb_c_int, &H42ULL)
            If (-Cast(c2fb_c_int, ((local0 <= Cast(Double, arg0->u.rValue))))) Then
                Return
            End If
        Case Cast(c2fb_c_int, &H43ULL)
            If (-Cast(c2fb_c_int, ((local0 < Cast(Double, arg0->u.rValue))))) Then
                Return
            End If
        Case Cast(c2fb_c_int, &H44ULL)
            If (-Cast(c2fb_c_int, ((local0 >= Cast(Double, arg0->u.rValue))))) Then
                Return
            End If
        Case Cast(c2fb_c_int, &H45ULL)
            If (-Cast(c2fb_c_int, ((local0 > Cast(Double, arg0->u.rValue))))) Then
                Return
            End If
        Case Else
            If (-Cast(c2fb_c_int, ((local0 = Cast(Double, arg0->u.rValue))))) Then
                Return
            End If
    End Select
    c2fb_flow_0:
    c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_5) = c2fb_temp_6
End Sub
Private Function nodeRowidIndex CDecl Alias "nodeRowidIndex" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = readInt16(CPtr(UByte Ptr, @((arg1)->zData[Cast(c2fb_c_int, 2ULL)])))
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < local1))))
        If (-Cast(c2fb_c_int, ((nodeGetRowid(arg0, arg1, local0) = arg2)))) Then
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_3 = Cast(c2fb_c_int, local0)
            (*c2fb_temp_2) = c2fb_temp_3
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    ' empty C statement
    Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
End Function
Private Function nodeParentIndex CDecl Alias "nodeParentIndex" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = arg1->pParent
    If (local0) Then
        Return nodeRowidIndex(arg0, local0, arg1->iNode, arg2)
    Else
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_0) = c2fb_temp_1
        Return Cast(c2fb_c_int, &O0ULL)
    End If
End Function
Private Function rtreeSearchPointCompare CDecl Alias "rtreeSearchPointCompare" (ByVal arg0 As Const c2fb_source_record_24 Ptr, ByVal arg1 As Const c2fb_source_record_24 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    If (-Cast(c2fb_c_int, ((arg0->rScore < arg1->rScore)))) Then
        Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rScore > arg1->rScore)))) Then
        Return Cast(c2fb_c_int, (+Cast(c2fb_c_int, 1ULL)))
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->iLevel) < Cast(c2fb_c_int, arg1->iLevel))))) Then
        Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->iLevel) > Cast(c2fb_c_int, arg1->iLevel))))) Then
        Return Cast(c2fb_c_int, (+Cast(c2fb_c_int, 1ULL)))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub rtreeSearchPointSwap CDecl Alias "rtreeSearchPointSwap" (ByVal arg0 As c2fb_source_record_25 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_24
    Dim c2fb_temp_0 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_24
    Dim c2fb_temp_2 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_3 As c2fb_source_record_24
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_7 As SqliteRtreeNode Ptr
    Dim local1 As SqliteRtreeNode Ptr
    Dim c2fb_temp_8 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_9 As SqliteRtreeNode Ptr
    Dim c2fb_temp_10 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_11 As SqliteRtreeNode Ptr

    local0 = arg0->aPoint[arg1]
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[arg1]))
    c2fb_temp_1 = arg0->aPoint[arg2]
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[arg2]))
    c2fb_temp_3 = local0
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = arg1
    arg1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    c2fb_temp_5 = arg2
    arg2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, 5ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg2 >= Cast(c2fb_c_int, 5ULL))))) Then
            nodeRelease((CPtr(c2fb_source_record_23 Ptr, ((arg0)->base.pVtab))), arg0->aNode(arg1))
            c2fb_temp_6 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(arg1)))
            c2fb_temp_7 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_6) = c2fb_temp_7
        Else
            local1 = arg0->aNode(arg1)
            c2fb_temp_8 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(arg1)))
            c2fb_temp_9 = arg0->aNode(arg2)
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(arg2)))
            c2fb_temp_11 = local1
            (*c2fb_temp_10) = c2fb_temp_11
        End If
    End If
End Sub
Private Function rtreeSearchPointFirst CDecl Alias "rtreeSearchPointFirst" (ByVal arg0 As c2fb_source_record_25 Ptr) As c2fb_source_record_24 Ptr
' c2fb source-path: ext/rtree/rtree.c
    Return IIf(arg0->bPoint, CPtr(c2fb_source_record_24 Ptr, @(arg0->sPoint)), IIf(arg0->nPoint, arg0->aPoint, CPtr(c2fb_source_record_24 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
End Function
Private Function rtreeNodeOfFirstSearchPoint CDecl Alias "rtreeNodeOfFirstSearchPoint" (ByVal arg0 As c2fb_source_record_25 Ptr, ByVal arg1 As c2fb_c_int Ptr) As SqliteRtreeNode Ptr
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) - Cast(c2fb_c_int, arg0->bPoint)))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->aNode(local1) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_0 = Cast(c2fb_int64, IIf(local1, arg0->aPoint[Cast(c2fb_c_int, &O0ULL)].id, arg0->sPoint.id))
        local0 = c2fb_temp_0
        c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_2 = Cast(c2fb_c_int, nodeAcquire((CPtr(c2fb_source_record_23 Ptr, ((arg0)->base.pVtab))), local0, Cast(c2fb_c_int, &O0ULL), CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(local1)))))
        (*c2fb_temp_1) = c2fb_temp_2
    End If
    Return arg0->aNode(local1)
End Function
Private Function rtreeEnqueue CDecl Alias "rtreeEnqueue" (ByVal arg0 As c2fb_source_record_25 Ptr, ByVal arg1 As Double, ByVal arg2 As UByte) As c2fb_source_record_24 Ptr
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_source_record_24 Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_24 Ptr Ptr
    Dim c2fb_temp_2 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_9 As Double Ptr
    Dim c2fb_temp_10 As Double
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte
    Dim local4 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_source_record_24 Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg0->nPoint >= arg0->nPointAlloc)))) Then
        local3 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0->nPointAlloc * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 8ULL)))
        c2fb_temp_0 = CPtr(c2fb_source_record_24 Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->aPoint), Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_24))))))))
        local2 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        c2fb_temp_1 = CPtr(c2fb_source_record_24 Ptr Ptr, @(arg0->aPoint))
        c2fb_temp_2 = local2
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg0->nPointAlloc))
        c2fb_temp_4 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg0->nPoint))
    c2fb_temp_6 = (*c2fb_temp_5)
    (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
    c2fb_temp_7 = Cast(c2fb_c_int, c2fb_temp_6)
    local0 = c2fb_temp_7
    c2fb_temp_8 = CPtr(c2fb_source_record_24 Ptr, (arg0->aPoint + local0))
    local2 = c2fb_temp_8
    c2fb_temp_9 = CPtr(Double Ptr, @(local2->rScore))
    c2fb_temp_10 = Cast(Double, arg1)
    (*c2fb_temp_9) = c2fb_temp_10
    c2fb_temp_11 = CPtr(UByte Ptr, @(local2->iLevel))
    c2fb_temp_12 = Cast(UByte, arg2)
    (*c2fb_temp_11) = c2fb_temp_12
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, &O0ULL)))))
        ' C automatic storage declaration
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL)))) \ Cast(c2fb_c_int, 2ULL))))
        local1 = c2fb_temp_13
        c2fb_temp_14 = CPtr(c2fb_source_record_24 Ptr, (arg0->aPoint + local1))
        local4 = c2fb_temp_14
        If (-Cast(c2fb_c_int, ((rtreeSearchPointCompare(CPtr(Const c2fb_source_record_24 Ptr, local2), CPtr(Const c2fb_source_record_24 Ptr, local4)) >= Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        rtreeSearchPointSwap(arg0, local1, local0)
        c2fb_temp_15 = Cast(c2fb_c_int, local1)
        local0 = c2fb_temp_15
        c2fb_temp_16 = local4
        local2 = c2fb_temp_16
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local2
End Function
Private Function rtreeSearchPointNew CDecl Alias "rtreeSearchPointNew" (ByVal arg0 As c2fb_source_record_25 Ptr, ByVal arg1 As Double, ByVal arg2 As UByte) As c2fb_source_record_24 Ptr
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_24 Ptr
    Dim local1 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_1 As c2fb_c_uint Ptr
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_6 As SqliteRtreeNode Ptr
    Dim c2fb_temp_7 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_8 As SqliteRtreeNode Ptr
    Dim c2fb_temp_9 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_10 As c2fb_source_record_24
    Dim c2fb_temp_11 As Double Ptr
    Dim c2fb_temp_12 As Double
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte
    Dim c2fb_temp_15 As UByte Ptr
    Dim c2fb_temp_16 As UByte

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_24 Ptr, rtreeSearchPointFirst(arg0))
    local1 = c2fb_temp_0
    c2fb_temp_1 = CPtr(c2fb_c_uint Ptr, @(arg0->anQueue(arg2)))
    c2fb_temp_2 = (*c2fb_temp_1)
    (*c2fb_temp_1) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_2 + 1)))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1->rScore > arg1)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->rScore = arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1->iLevel) > Cast(c2fb_c_int, arg2))))) <> 0)))))) <> 0))))) Then
        If arg0->bPoint Then
            ' C automatic storage declaration
            c2fb_temp_3 = CPtr(c2fb_source_record_24 Ptr, rtreeEnqueue(arg0, arg1, arg2))
            local0 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, ((CPtr(c2fb_source_record_24 Ptr, local0) - CPtr(c2fb_source_record_24 Ptr, arg0->aPoint)))) + Cast(c2fb_c_int, 1ULL))))
            local2 = c2fb_temp_4
            ' C unused-parameter annotation
            If ((-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, 5ULL)))))) Then
                ' C unused-parameter annotation
                c2fb_temp_5 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(local2)))
                c2fb_temp_6 = arg0->aNode(Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_5) = c2fb_temp_6
            Else
                nodeRelease((CPtr(c2fb_source_record_23 Ptr, ((arg0)->base.pVtab))), arg0->aNode(Cast(c2fb_c_int, &O0ULL)))
            End If
            c2fb_temp_7 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_8 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_7) = c2fb_temp_8
            c2fb_temp_9 = CPtr(c2fb_source_record_24 Ptr, @((*local0)))
            c2fb_temp_10 = arg0->sPoint
            (*c2fb_temp_9) = c2fb_temp_10
        End If
        c2fb_temp_11 = CPtr(Double Ptr, @(arg0->sPoint.rScore))
        c2fb_temp_12 = Cast(Double, arg1)
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_temp_13 = CPtr(UByte Ptr, @(arg0->sPoint.iLevel))
        c2fb_temp_14 = Cast(UByte, arg2)
        (*c2fb_temp_13) = c2fb_temp_14
        c2fb_temp_15 = CPtr(UByte Ptr, @(arg0->bPoint))
        c2fb_temp_16 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_15) = c2fb_temp_16
        Return CPtr(c2fb_source_record_24 Ptr, @(arg0->sPoint))
    Else
        Return CPtr(c2fb_source_record_24 Ptr, rtreeEnqueue(arg0, arg1, arg2))
    End If
End Function
Private Sub rtreeSearchPointPop CDecl Alias "rtreeSearchPointPop" (ByVal arg0 As c2fb_source_record_25 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr
    Dim c2fb_temp_3 As c2fb_c_uint Ptr
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As c2fb_c_uint Ptr
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_14 As c2fb_source_record_24
    Dim c2fb_temp_15 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_16 As SqliteRtreeNode Ptr
    Dim c2fb_temp_17 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_18 As SqliteRtreeNode Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) - Cast(c2fb_c_int, arg0->bPoint))))
    local0 = c2fb_temp_0
    ' C unused-parameter annotation
    If arg0->aNode(local0) Then
        nodeRelease((CPtr(c2fb_source_record_23 Ptr, ((arg0)->base.pVtab))), arg0->aNode(local0))
        c2fb_temp_1 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(local0)))
        c2fb_temp_2 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_1) = c2fb_temp_2
    End If
    If arg0->bPoint Then
        c2fb_temp_3 = CPtr(c2fb_c_uint Ptr, @(arg0->anQueue(arg0->sPoint.iLevel)))
        c2fb_temp_4 = (*c2fb_temp_3)
        (*c2fb_temp_3) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_4 - 1)))
        c2fb_temp_5 = CPtr(UByte Ptr, @(arg0->bPoint))
        c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_5) = c2fb_temp_6
    Else
        If (arg0->nPoint) Then
            c2fb_temp_7 = CPtr(c2fb_c_uint Ptr, @(arg0->anQueue(arg0->aPoint[Cast(c2fb_c_int, &O0ULL)].iLevel)))
            c2fb_temp_8 = (*c2fb_temp_7)
            (*c2fb_temp_7) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_8 - 1)))
            c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(arg0->nPoint))
            c2fb_temp_10 = (*c2fb_temp_9)
            (*c2fb_temp_9) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 - 1)))
            c2fb_temp_11 = (*c2fb_temp_9)
            c2fb_temp_12 = Cast(c2fb_c_int, c2fb_temp_11)
            local3 = c2fb_temp_12
            c2fb_temp_13 = CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[Cast(c2fb_c_int, &O0ULL)]))
            c2fb_temp_14 = arg0->aPoint[local3]
            (*c2fb_temp_13) = c2fb_temp_14
            If (-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_int, (Cast(c2fb_c_int, 5ULL) - Cast(c2fb_c_int, 1ULL))))))) Then
                c2fb_temp_15 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(Cast(c2fb_c_int, 1ULL))))
                c2fb_temp_16 = arg0->aNode(Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_15) = c2fb_temp_16
                c2fb_temp_17 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->aNode(Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))))
                c2fb_temp_18 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_17) = c2fb_temp_18
            End If
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_19
            Do
                c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL))))
                local1 = c2fb_temp_20
                If ((-Cast(c2fb_c_int, (((c2fb_temp_20) < local3)))) = 0) Then Goto c2fb_flow_0
                c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL))))
                local2 = c2fb_temp_21
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < local3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((rtreeSearchPointCompare(CPtr(Const c2fb_source_record_24 Ptr, CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[local2]))), CPtr(Const c2fb_source_record_24 Ptr, CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[local1])))) < Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    If (-Cast(c2fb_c_int, ((rtreeSearchPointCompare(CPtr(Const c2fb_source_record_24 Ptr, CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[local2]))), CPtr(Const c2fb_source_record_24 Ptr, CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[local0])))) < Cast(c2fb_c_int, &O0ULL))))) Then
                        rtreeSearchPointSwap(arg0, local0, local2)
                        c2fb_temp_22 = Cast(c2fb_c_int, local2)
                        local0 = c2fb_temp_22
                    Else
                        Goto c2fb_flow_0
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((rtreeSearchPointCompare(CPtr(Const c2fb_source_record_24 Ptr, CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[local1]))), CPtr(Const c2fb_source_record_24 Ptr, CPtr(c2fb_source_record_24 Ptr, @(arg0->aPoint[local0])))) < Cast(c2fb_c_int, &O0ULL))))) Then
                        rtreeSearchPointSwap(arg0, local0, local1)
                        c2fb_temp_23 = Cast(c2fb_c_int, local1)
                        local0 = c2fb_temp_23
                    Else
                        Goto c2fb_flow_0
                    End If
                End If
            c2fb_flow_1:
            Loop
            c2fb_flow_0:
        End If
    End If
End Sub
Private Function rtreeStepToLeaf CDecl Alias "rtreeStepToLeaf" (ByVal arg0 As c2fb_source_record_25 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_24 Ptr
    Dim local1 As c2fb_source_record_23 Ptr
    Dim local2 As SqliteRtreeNode Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_source_record_24
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_source_record_24 Ptr
    Dim local10 As UByte Ptr
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As UByte Ptr
    Dim local11 As Double
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local12 As SqliteRtreeConstraint Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As UByte Ptr
    Dim c2fb_temp_10 As UByte
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte Ptr
    Dim c2fb_temp_13 As UByte
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As UByte
    Dim c2fb_temp_16 As c2fb_int64 Ptr
    Dim c2fb_temp_17 As c2fb_int64
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As UByte Ptr
    Dim c2fb_temp_21 As UByte
    Dim c2fb_temp_22 As c2fb_int64 Ptr
    Dim c2fb_temp_23 As c2fb_int64
    Dim c2fb_temp_24 As UByte Ptr
    Dim c2fb_temp_25 As UByte
    Dim c2fb_temp_26 As Double
    Dim c2fb_temp_27 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_28 As UByte Ptr
    Dim c2fb_temp_29 As UByte
    Dim c2fb_temp_30 As c2fb_int64 Ptr
    Dim c2fb_temp_31 As c2fb_int64
    Dim c2fb_temp_32 As UByte Ptr
    Dim c2fb_temp_33 As UByte
    Dim c2fb_temp_34 As UByte Ptr
    Dim c2fb_temp_35 As UByte

    ' C automatic storage declaration
    local1 = (CPtr(c2fb_source_record_23 Ptr, ((arg0)->base.pVtab)))
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local6 = arg0->nConstraint
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1->eCoordType) = Cast(c2fb_c_int, 1ULL))))))
    local8 = c2fb_temp_0
    Do
        c2fb_temp_1 = CPtr(c2fb_source_record_24 Ptr, rtreeSearchPointFirst(arg0))
        local0 = c2fb_temp_1
        If ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((c2fb_temp_1) <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->iLevel) > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) = 0) Then Goto c2fb_flow_0
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(SqliteRtreeNode Ptr, rtreeNodeOfFirstSearchPoint(arg0, CPtr(c2fb_c_int Ptr, @(local4))))
        local2 = c2fb_temp_2
        If local4 Then
            Return local4
        End If
        c2fb_temp_3 = Cast(c2fb_c_int, readInt16(CPtr(UByte Ptr, @((local2)->zData[Cast(c2fb_c_int, 2ULL)]))))
        local5 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, 51ULL))))) Then
            ' empty C statement
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        c2fb_temp_4 = CPtr(UByte Ptr, (local2->zData + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, local1->nBytesPerCell) * Cast(c2fb_c_int, local0->iCell))))))))
        local10 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->iCell) < local5))))
            local11 = __c2fb_double_value(Cast(Double, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
            local3 = c2fb_temp_5
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local7 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((local7 < local6))))
                local12 = CPtr(SqliteRtreeConstraint Ptr, (arg0->aConstraint + local7))
                If (-Cast(c2fb_c_int, ((local12->op >= Cast(c2fb_c_int, &H46ULL))))) Then
                    c2fb_temp_8 = Cast(c2fb_c_int, rtreeCallbackConstraint(local12, local8, local10, local0, CPtr(Double Ptr, @(local11)), CPtr(c2fb_c_int Ptr, @(local3))))
                    local4 = c2fb_temp_8
                    If local4 Then
                        Return local4
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->iLevel) = Cast(c2fb_c_int, 1ULL))))) Then
                        rtreeLeafConstraint(local12, local8, local10, CPtr(c2fb_c_int Ptr, @(local3)))
                    Else
                        rtreeNonleafConstraint(local12, local8, local10, CPtr(c2fb_c_int Ptr, @(local3)))
                    End If
                End If
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_9 = CPtr(UByte Ptr, @(local0->iCell))
                    c2fb_temp_10 = (*c2fb_temp_9)
                    (*c2fb_temp_9) = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_temp_10) + 1)))
                    c2fb_temp_11 = CPtr(UByte Ptr, (local10 + local1->nBytesPerCell))
                    local10 = c2fb_temp_11
                    Goto c2fb_flow_4
                End If
            c2fb_flow_5:
                c2fb_temp_7 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_3
            End If
            c2fb_temp_12 = CPtr(UByte Ptr, @(local0->iCell))
            c2fb_temp_13 = (*c2fb_temp_12)
            (*c2fb_temp_12) = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_temp_13) + 1)))
            c2fb_temp_14 = CPtr(UByte Ptr, @(local9.iLevel))
            c2fb_temp_15 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, local0->iLevel) - Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_14) = c2fb_temp_15
            If local9.iLevel Then
                c2fb_temp_16 = CPtr(c2fb_int64 Ptr, @(local9.id))
                c2fb_temp_17 = Cast(c2fb_int64, readInt64(local10))
                (*c2fb_temp_16) = c2fb_temp_17
                c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local7 = c2fb_temp_18
                While (-Cast(c2fb_c_int, ((local7 < arg0->nPoint))))
                    If (-Cast(c2fb_c_int, ((arg0->aPoint[local7].id = local9.id)))) Then
                        ' empty C statement
                        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
                    End If
                c2fb_flow_7:
                    c2fb_temp_19 = local7
                    local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_19 + 1)))
                Wend
                c2fb_flow_6:
                c2fb_temp_20 = CPtr(UByte Ptr, @(local9.iCell))
                c2fb_temp_21 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_20) = c2fb_temp_21
            Else
                c2fb_temp_22 = CPtr(c2fb_int64 Ptr, @(local9.id))
                c2fb_temp_23 = Cast(c2fb_int64, local0->id)
                (*c2fb_temp_22) = c2fb_temp_23
                c2fb_temp_24 = CPtr(UByte Ptr, @(local9.iCell))
                c2fb_temp_25 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, local0->iCell) - Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_24) = c2fb_temp_25
            End If
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->iCell) >= local5)))) Then
                ' empty C statement
                rtreeSearchPointPop(arg0)
            End If
            If (-Cast(c2fb_c_int, ((local11 < 0.0#)))) Then
                c2fb_temp_26 = Cast(Double, 0.0#)
                local11 = c2fb_temp_26
            End If
            c2fb_temp_27 = CPtr(c2fb_source_record_24 Ptr, rtreeSearchPointNew(arg0, local11, local9.iLevel))
            local0 = c2fb_temp_27
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, 7ULL)
            End If
            c2fb_temp_28 = CPtr(UByte Ptr, @(local0->eWithin))
            c2fb_temp_29 = Cast(UByte, Cast(UByte, local3))
            (*c2fb_temp_28) = c2fb_temp_29
            c2fb_temp_30 = CPtr(c2fb_int64 Ptr, @(local0->id))
            c2fb_temp_31 = Cast(c2fb_int64, local9.id)
            (*c2fb_temp_30) = c2fb_temp_31
            c2fb_temp_32 = CPtr(UByte Ptr, @(local0->iCell))
            c2fb_temp_33 = Cast(UByte, local9.iCell)
            (*c2fb_temp_32) = c2fb_temp_33
            ' empty C statement
            Goto c2fb_flow_2
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->iCell) >= local5)))) Then
            ' empty C statement
            rtreeSearchPointPop(arg0)
        End If
    c2fb_flow_1:
    Loop
    c2fb_flow_0:
    c2fb_temp_34 = CPtr(UByte Ptr, @(arg0->atEOF))
    c2fb_temp_35 = Cast(UByte, (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))))
    (*c2fb_temp_34) = c2fb_temp_35
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rtreeNext CDecl Alias "rtreeNext" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_25 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_25 Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' empty C statement
    If local0->bAuxValid Then
        c2fb_temp_0 = CPtr(UByte Ptr, @(local0->bAuxValid))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
        sqlite3_reset(CPtr(Any Ptr, local0->pReadAux))
    End If
    rtreeSearchPointPop(local0)
    c2fb_temp_2 = Cast(c2fb_c_int, rtreeStepToLeaf(local0))
    local1 = c2fb_temp_2
    Return local1
End Function
Private Function rtreeRowid CDecl Alias "rtreeRowid" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_25 Ptr
    Dim local1 As c2fb_source_record_24 Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_int64 Ptr
    Dim c2fb_temp_2 As c2fb_int64

    local0 = CPtr(c2fb_source_record_25 Ptr, arg0)
    local1 = CPtr(c2fb_source_record_24 Ptr, rtreeSearchPointFirst(local0))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = CPtr(SqliteRtreeNode Ptr, rtreeNodeOfFirstSearchPoint(local0, CPtr(c2fb_c_int Ptr, @(local2))))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((local1) <> 0))))) Then
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1->iCell) >= readInt16(CPtr(UByte Ptr, @((local3)->zData[Cast(c2fb_c_int, 2ULL)]))))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
            local2 = c2fb_temp_0
        Else
            c2fb_temp_1 = CPtr(c2fb_int64 Ptr, @((*arg1)))
            c2fb_temp_2 = Cast(c2fb_int64, nodeGetRowid((CPtr(c2fb_source_record_23 Ptr, ((local0)->base.pVtab))), local3, local1->iCell))
            (*c2fb_temp_1) = c2fb_temp_2
        End If
    End If
    Return local2
End Function
Private Function rtreeColumn CDecl Alias "rtreeColumn" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As SqliteResultContext Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_source_record_25 Ptr
    Dim local2 As c2fb_source_record_24 Ptr
    Dim local3 As c2fb_source_record_26
    Dim local4 As c2fb_c_int
    Dim local5 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0->pVtab)
    local1 = CPtr(c2fb_source_record_25 Ptr, arg0)
    local2 = CPtr(c2fb_source_record_24 Ptr, rtreeSearchPointFirst(local1))
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = CPtr(SqliteRtreeNode Ptr, rtreeNodeOfFirstSearchPoint(local1, CPtr(c2fb_c_int Ptr, @(local4))))
    If local4 Then
        Return local4
    End If
    If ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL)))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->iCell) >= readInt16(CPtr(UByte Ptr, @((local5)->zData[Cast(c2fb_c_int, 2ULL)]))))))) Then
        Return Cast(c2fb_c_int, 4ULL)
    End If
    If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_result_int64(CPtr(Any Ptr, arg1), nodeGetRowid(local0, local5, local2->iCell))
    Else
        If (-Cast(c2fb_c_int, ((arg2 <= Cast(c2fb_c_int, local0->nDim2))))) Then
            nodeGetCoord(local0, local5, local2->iCell, Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_source_record_26 Ptr, @(local3)))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->eCoordType) = Cast(c2fb_c_int, &O0ULL))))) Then
                sqlite3_result_double(CPtr(Any Ptr, arg1), local3.f)
            Else
                ' C unused-parameter annotation
                sqlite3_result_int(CPtr(Any Ptr, arg1), local3.i)
            End If
        Else
            If (-Cast(c2fb_c_int, (local1->bAuxValid = 0))) Then
                If (-Cast(c2fb_c_int, ((local1->pReadAux = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_prepare_v3(CPtr(Any Ptr, local0->db), CPtr(Const ZString Ptr, local0->zReadAuxSql), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr Ptr, CPtr(SqliteVdbe Ptr Ptr, @(local1->pReadAux))), Cast(c2fb_c_int, &O0ULL)))
                    local4 = c2fb_temp_0
                    If local4 Then
                        Return local4
                    End If
                End If
                sqlite3_bind_int64(CPtr(Any Ptr, local1->pReadAux), Cast(c2fb_c_int, 1ULL), nodeGetRowid(local0, local5, local2->iCell))
                c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_step(CPtr(Any Ptr, local1->pReadAux)))
                local4 = c2fb_temp_1
                If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 100ULL))))) Then
                    c2fb_temp_2 = CPtr(UByte Ptr, @(local1->bAuxValid))
                    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_2) = c2fb_temp_3
                Else
                    sqlite3_reset(CPtr(Any Ptr, local1->pReadAux))
                    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 101ULL))))) Then
                        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        local4 = c2fb_temp_4
                    End If
                    Return local4
                End If
            End If
            sqlite3_result_value(CPtr(Any Ptr, arg1), CPtr(Any Ptr, CPtr(SqliteVdbeMem Ptr, sqlite3_column_value(CPtr(Any Ptr, local1->pReadAux), Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, local0->nDim2))) + Cast(c2fb_c_int, 1ULL)))))))
        End If
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function findLeafNode CDecl Alias "findLeafNode" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteRtreeNode Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_1 As SqliteRtreeNode Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_int64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(SqliteRtreeNode Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    sqlite3_bind_int64(CPtr(Any Ptr, arg0->pReadRowid), Cast(c2fb_c_int, 1ULL), arg1)
    If (-Cast(c2fb_c_int, ((sqlite3_step(CPtr(Any Ptr, arg0->pReadRowid)) = Cast(c2fb_c_int, 100ULL))))) Then
        local1 = sqlite3_column_int64(CPtr(Any Ptr, arg0->pReadRowid), Cast(c2fb_c_int, &O0ULL))
        If arg3 Then
            c2fb_temp_2 = CPtr(c2fb_int64 Ptr, @((*arg3)))
            c2fb_temp_3 = Cast(c2fb_int64, local1)
            (*c2fb_temp_2) = c2fb_temp_3
        End If
        c2fb_temp_4 = Cast(c2fb_c_int, nodeAcquire(arg0, local1, Cast(c2fb_c_int, &O0ULL), arg2))
        local0 = c2fb_temp_4
        sqlite3_reset(CPtr(Any Ptr, arg0->pReadRowid))
    Else
        c2fb_temp_5 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, arg0->pReadRowid)))
        local0 = c2fb_temp_5
    End If
    Return local0
End Function
Private Function deserializeGeometry CDecl Alias "deserializeGeometry" (ByVal arg0 As SqliteVdbeMem Ptr, ByVal arg1 As SqliteRtreeConstraint Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeMatchArg Ptr
    Dim local1 As SqliteRtreeMatchArg Ptr
    Dim local2 As SqliteRtreeQueryInfo Ptr
    Dim c2fb_temp_0 As SqliteRtreeMatchArg Ptr
    Dim c2fb_temp_1 As SqliteRtreeQueryInfo Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As SqliteRtreeMatchArg Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Any Ptr Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As SqliteRtreeDValue Ptr Ptr
    Dim c2fb_temp_10 As Double Ptr
    Dim c2fb_temp_11 As Any Ptr Ptr Ptr
    Dim c2fb_temp_12 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_13 As SqliteRtreeGeometryCallbackProc Ptr
    Dim c2fb_temp_14 As c2fb_callback_154
    Dim c2fb_temp_15 As SQLITE_C_INT Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As SqliteRtreeQueryCallbackProc Ptr
    Dim c2fb_temp_18 As c2fb_callback_155
    Dim c2fb_temp_19 As SqliteRtreeQueryInfo Ptr Ptr
    Dim c2fb_temp_20 As SqliteRtreeQueryInfo Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(SqliteRtreeMatchArg Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_value_pointer(arg0, StrPtr(!"RtreeMatchArg"))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    c2fb_temp_1 = CPtr(SqliteRtreeQueryInfo Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteRtreeQueryInfo))) + Cast(c2fb_uint64, local1->iSize))))))
    local2 = c2fb_temp_1
    If (-Cast(c2fb_c_int, (local2 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteRtreeQueryInfo))))
    c2fb_temp_3 = CPtr(SqliteRtreeMatchArg Ptr, CPtr(SqliteRtreeQueryInfo Ptr, @(local2[Cast(c2fb_c_int, 1ULL)])))
    local0 = c2fb_temp_3
    c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0), CPtr(Const Any Ptr, local1), local1->iSize))
    c2fb_temp_5 = CPtr(Any Ptr Ptr, @(local2->pContext))
    c2fb_temp_6 = local0->cb.pContext
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(local2->nParam))
    c2fb_temp_8 = Cast(c2fb_c_int, local0->nParam)
    (*c2fb_temp_7) = Cast(SQLITE_C_INT, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    c2fb_temp_9 = CPtr(SqliteRtreeDValue Ptr Ptr, @(local2->aParam))
    c2fb_temp_10 = CPtr(Double Ptr, (@local0->aParam(0)))
    (*c2fb_temp_9) = CPtr(SqliteRtreeDValue Ptr, c2fb_temp_10)
    c2fb_temp_10 = CPtr(Double Ptr, (*c2fb_temp_9))
    c2fb_temp_11 = CPtr(Any Ptr Ptr Ptr, @(local2->apSqlParam))
    c2fb_temp_12 = CPtr(SqliteVdbeMem Ptr Ptr, local0->apSqlParam)
    (*c2fb_temp_11) = CPtr(Any Ptr Ptr, c2fb_temp_12)
    c2fb_temp_12 = CPtr(SqliteVdbeMem Ptr Ptr, (*c2fb_temp_11))
    If CPtr(c2fb_callback_154, local0->cb.xGeom) Then
        c2fb_temp_13 = CPtr(SqliteRtreeGeometryCallbackProc Ptr, @(arg1->u.xGeom))
        c2fb_temp_14 = CPtr(c2fb_callback_154, local0->cb.xGeom)
        (*c2fb_temp_13) = Cast(SqliteRtreeGeometryCallbackProc, c2fb_temp_14)
        c2fb_temp_14 = CPtr(c2fb_callback_154, (*c2fb_temp_13))
    Else
        c2fb_temp_15 = CPtr(SQLITE_C_INT Ptr, @(arg1->op))
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H47ULL))
        (*c2fb_temp_15) = Cast(SQLITE_C_INT, c2fb_temp_16)
        c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
        c2fb_temp_17 = CPtr(SqliteRtreeQueryCallbackProc Ptr, @(arg1->u.xQueryFunc))
        c2fb_temp_18 = CPtr(c2fb_callback_155, local0->cb.xQueryFunc)
        (*c2fb_temp_17) = Cast(SqliteRtreeQueryCallbackProc, c2fb_temp_18)
        c2fb_temp_18 = CPtr(c2fb_callback_155, (*c2fb_temp_17))
    End If
    c2fb_temp_19 = CPtr(SqliteRtreeQueryInfo Ptr Ptr, @(arg1->pInfo))
    c2fb_temp_20 = local2
    (*c2fb_temp_19) = c2fb_temp_20
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rtreeFilter CDecl Alias "rtreeFilter" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_source_record_25 Ptr
    Dim local2 As SqliteRtreeNode Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local6 As SqliteRtreeNode Ptr
    Dim local7 As c2fb_source_record_24 Ptr
    Dim local8 As c2fb_int64
    Dim local9 As c2fb_int64
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As SqliteRtreeNode Ptr
    Dim c2fb_temp_5 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_6 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_7 As SqliteRtreeNode Ptr
    Dim c2fb_temp_8 As c2fb_int64 Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As UByte
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte
    Dim c2fb_temp_15 As UByte Ptr
    Dim c2fb_temp_16 As UByte
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As SqliteRtreeConstraint Ptr Ptr
    Dim c2fb_temp_19 As SqliteRtreeConstraint Ptr
    Dim c2fb_temp_20 As c2fb_c_int Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As Any Ptr
    Dim c2fb_temp_24 As Any Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim local11 As SqliteRtreeConstraint Ptr
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_27 As SQLITE_C_INT Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As SQLITE_C_INT Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As SQLITE_C_INT Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As SQLITE_C_UINT Ptr Ptr
    Dim c2fb_temp_35 As c2fb_c_uint Ptr
    Dim c2fb_temp_36 As SQLITE_C_INT Ptr
    Dim c2fb_temp_37 As c2fb_c_int
    Dim local13 As c2fb_int64
    Dim c2fb_temp_38 As SqliteRtreeDValue Ptr
    Dim c2fb_temp_39 As Double
    Dim c2fb_temp_40 As SQLITE_C_INT Ptr
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As SQLITE_C_INT Ptr
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As SqliteRtreeDValue Ptr
    Dim c2fb_temp_45 As Double
    Dim c2fb_temp_46 As SqliteRtreeDValue Ptr
    Dim c2fb_temp_47 As Double
    Dim c2fb_temp_48 As SQLITE_C_INT Ptr
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As SQLITE_C_INT Ptr
    Dim c2fb_temp_51 As c2fb_c_int
    Dim c2fb_temp_52 As SQLITE_C_INT Ptr
    Dim c2fb_temp_53 As c2fb_c_int
    Dim local14 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_54 As c2fb_source_record_24 Ptr
    Dim c2fb_temp_55 As c2fb_int64 Ptr
    Dim c2fb_temp_56 As c2fb_int64
    Dim c2fb_temp_57 As UByte Ptr
    Dim c2fb_temp_58 As UByte
    Dim c2fb_temp_59 As UByte Ptr
    Dim c2fb_temp_60 As UByte
    Dim c2fb_temp_61 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_62 As SqliteRtreeNode Ptr
    Dim c2fb_temp_63 As SqliteRtreeNode Ptr
    Dim c2fb_temp_64 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0->pVtab)
    local1 = CPtr(c2fb_source_record_25 Ptr, arg0)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    rtreeReference(local0)
    resetCursor(local1)
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(local1->iStrategy))
    c2fb_temp_1 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_0) = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        local8 = c2fb_external_sqlite3_value_int64(arg4[Cast(c2fb_c_int, &O0ULL)])
        local9 = Cast(c2fb_c_int, &O0ULL)
        local10 = c2fb_external_sqlite3_value_numeric_type(arg4[Cast(c2fb_c_int, &O0ULL)])
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3IntFloatCompare(local8, c2fb_external_sqlite3_value_double(arg4[Cast(c2fb_c_int, &O0ULL)])))))) <> 0)))))) <> 0))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, findLeafNode(local0, local8, CPtr(SqliteRtreeNode Ptr Ptr, @(local6)), CPtr(c2fb_int64 Ptr, @(local9))))
            local4 = c2fb_temp_2
        Else
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local4 = c2fb_temp_3
            c2fb_temp_4 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local6 = c2fb_temp_4
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_5 = CPtr(c2fb_source_record_24 Ptr, rtreeSearchPointNew(local1, 0.0#, Cast(c2fb_c_int, &O0ULL)))
            local7 = c2fb_temp_5
            ' C unused-parameter annotation
            c2fb_temp_6 = CPtr(SqliteRtreeNode Ptr Ptr, @(local1->aNode(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_7 = local6
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(c2fb_int64 Ptr, @(local7->id))
            c2fb_temp_9 = Cast(c2fb_int64, local9)
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(UByte Ptr, @(local7->eWithin))
            c2fb_temp_11 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_10) = c2fb_temp_11
            c2fb_temp_12 = Cast(c2fb_c_int, nodeRowidIndex(local0, local6, local8, CPtr(c2fb_c_int Ptr, @(local5))))
            local4 = c2fb_temp_12
            c2fb_temp_13 = CPtr(UByte Ptr, @(local7->iCell))
            c2fb_temp_14 = Cast(UByte, Cast(UByte, local5))
            (*c2fb_temp_13) = c2fb_temp_14
            ' empty C statement
        Else
            c2fb_temp_15 = CPtr(UByte Ptr, @(local1->atEOF))
            c2fb_temp_16 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_15) = c2fb_temp_16
        End If
    Else
        c2fb_temp_17 = Cast(c2fb_c_int, nodeAcquire(local0, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL), CPtr(SqliteRtreeNode Ptr Ptr, @(local2))))
        local4 = c2fb_temp_17
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_18 = CPtr(SqliteRtreeConstraint Ptr Ptr, @(local1->aConstraint))
            c2fb_temp_19 = CPtr(SqliteRtreeConstraint Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteRtreeConstraint))) * Cast(c2fb_uint64, arg3))))))
            (*c2fb_temp_18) = c2fb_temp_19
            c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @(local1->nConstraint))
            c2fb_temp_21 = Cast(c2fb_c_int, arg3)
            (*c2fb_temp_20) = c2fb_temp_21
            If (-Cast(c2fb_c_int, (local1->aConstraint = 0))) Then
                c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local4 = c2fb_temp_22
            Else
                c2fb_temp_23 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1->aConstraint), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteRtreeConstraint))) * Cast(c2fb_uint64, arg3)))))
                c2fb_temp_24 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_c_uint Ptr, (@local1->anQueue(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (local0->iDepth + Cast(c2fb_c_int, 1ULL)))))))))
                ' C unused-parameter annotation
                c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_25
                While (-Cast(c2fb_c_int, ((local3 < arg3))))
                    local11 = CPtr(SqliteRtreeConstraint Ptr, @(local1->aConstraint[local3]))
                    local12 = c2fb_external_sqlite3_value_numeric_type(arg4[local3])
                    c2fb_temp_27 = CPtr(SQLITE_C_INT Ptr, @(local11->op))
                    c2fb_temp_28 = Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 2ULL)))])
                    (*c2fb_temp_27) = Cast(SQLITE_C_INT, c2fb_temp_28)
                    c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
                    c2fb_temp_29 = CPtr(SQLITE_C_INT Ptr, @(local11->iCoord))
                    c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[Cast(c2fb_c_int, (Cast(c2fb_c_int, (local3 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]) - Cast(c2fb_c_int, 48))))
                    (*c2fb_temp_29) = Cast(SQLITE_C_INT, c2fb_temp_30)
                    c2fb_temp_30 = Cast(c2fb_c_int, (*c2fb_temp_29))
                    If (-Cast(c2fb_c_int, ((local11->op >= Cast(c2fb_c_int, &H46ULL))))) Then
                        c2fb_temp_31 = Cast(c2fb_c_int, deserializeGeometry(arg4[local3], local11))
                        local4 = c2fb_temp_31
                        If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
                            Goto c2fb_flow_0
                        End If
                        c2fb_temp_32 = CPtr(SQLITE_C_INT Ptr, @(local11->pInfo->nCoord))
                        c2fb_temp_33 = Cast(c2fb_c_int, local0->nDim2)
                        (*c2fb_temp_32) = Cast(SQLITE_C_INT, c2fb_temp_33)
                        c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
                        c2fb_temp_34 = CPtr(SQLITE_C_UINT Ptr Ptr, @(local11->pInfo->anQueue))
                        c2fb_temp_35 = CPtr(c2fb_c_uint Ptr, (@local1->anQueue(0)))
                        (*c2fb_temp_34) = CPtr(SQLITE_C_UINT Ptr, c2fb_temp_35)
                        c2fb_temp_35 = CPtr(c2fb_c_uint Ptr, (*c2fb_temp_34))
                        c2fb_temp_36 = CPtr(SQLITE_C_INT Ptr, @(local11->pInfo->mxLevel))
                        c2fb_temp_37 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0->iDepth + Cast(c2fb_c_int, 1ULL))))
                        (*c2fb_temp_36) = Cast(SQLITE_C_INT, c2fb_temp_37)
                        c2fb_temp_37 = Cast(c2fb_c_int, (*c2fb_temp_36))
                    Else
                        If (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, 1ULL))))) Then
                            local13 = c2fb_external_sqlite3_value_int64(arg4[local3])
                            c2fb_temp_38 = CPtr(SqliteRtreeDValue Ptr, @(local11->u.rValue))
                            c2fb_temp_39 = Cast(Double, __c2fb_double_value(Cast(Double, local13)))
                            (*c2fb_temp_38) = Cast(SqliteRtreeDValue, c2fb_temp_39)
                            c2fb_temp_39 = Cast(Double, (*c2fb_temp_38))
                            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local13 >= Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))) Shl Cast(c2fb_c_int, 48ULL))))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local13 <= Cast(c2fb_int64, (-(Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))) Shl Cast(c2fb_c_int, 48ULL)))))))))) <> 0))))) Then
                                If (-Cast(c2fb_c_int, ((local11->op = Cast(c2fb_c_int, &H43ULL))))) Then
                                    c2fb_temp_40 = CPtr(SQLITE_C_INT Ptr, @(local11->op))
                                    c2fb_temp_41 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H42ULL))
                                    (*c2fb_temp_40) = Cast(SQLITE_C_INT, c2fb_temp_41)
                                    c2fb_temp_41 = Cast(c2fb_c_int, (*c2fb_temp_40))
                                End If
                                If (-Cast(c2fb_c_int, ((local11->op = Cast(c2fb_c_int, &H45ULL))))) Then
                                    c2fb_temp_42 = CPtr(SQLITE_C_INT Ptr, @(local11->op))
                                    c2fb_temp_43 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H44ULL))
                                    (*c2fb_temp_42) = Cast(SQLITE_C_INT, c2fb_temp_43)
                                    c2fb_temp_43 = Cast(c2fb_c_int, (*c2fb_temp_42))
                                End If
                            End If
                        Else
                            If (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, 2ULL))))) Then
                                c2fb_temp_44 = CPtr(SqliteRtreeDValue Ptr, @(local11->u.rValue))
                                c2fb_temp_45 = Cast(Double, c2fb_external_sqlite3_value_double(arg4[local3]))
                                (*c2fb_temp_44) = Cast(SqliteRtreeDValue, c2fb_temp_45)
                                c2fb_temp_45 = Cast(Double, (*c2fb_temp_44))
                            Else
                                c2fb_temp_46 = CPtr(SqliteRtreeDValue Ptr, @(local11->u.rValue))
                                c2fb_temp_47 = Cast(Double, 0.0#)
                                (*c2fb_temp_46) = Cast(SqliteRtreeDValue, c2fb_temp_47)
                                c2fb_temp_47 = Cast(Double, (*c2fb_temp_46))
                                If (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, 5ULL))))) Then
                                    c2fb_temp_48 = CPtr(SQLITE_C_INT Ptr, @(local11->op))
                                    c2fb_temp_49 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H40ULL))
                                    (*c2fb_temp_48) = Cast(SQLITE_C_INT, c2fb_temp_49)
                                    c2fb_temp_49 = Cast(c2fb_c_int, (*c2fb_temp_48))
                                Else
                                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local11->op = Cast(c2fb_c_int, &H43ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local11->op = Cast(c2fb_c_int, &H42ULL))))) <> 0))))) Then
                                        c2fb_temp_50 = CPtr(SQLITE_C_INT Ptr, @(local11->op))
                                        c2fb_temp_51 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H3fULL))
                                        (*c2fb_temp_50) = Cast(SQLITE_C_INT, c2fb_temp_51)
                                        c2fb_temp_51 = Cast(c2fb_c_int, (*c2fb_temp_50))
                                    Else
                                        c2fb_temp_52 = CPtr(SQLITE_C_INT Ptr, @(local11->op))
                                        c2fb_temp_53 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H40ULL))
                                        (*c2fb_temp_52) = Cast(SQLITE_C_INT, c2fb_temp_53)
                                        c2fb_temp_53 = Cast(c2fb_c_int, (*c2fb_temp_52))
                                    End If
                                End If
                            End If
                        End If
                    End If
                c2fb_flow_1:
                    c2fb_temp_26 = local3
                    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_26 + 1)))
                Wend
                c2fb_flow_0:
            End If
        End If
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            ' C unused-parameter annotation
            c2fb_temp_54 = CPtr(c2fb_source_record_24 Ptr, rtreeSearchPointNew(local1, 0.0#, Cast(UByte, (Cast(c2fb_c_int, (local0->iDepth + Cast(c2fb_c_int, 1ULL)))))))
            local14 = c2fb_temp_54
            If ((-Cast(c2fb_c_int, ((local14 = Cast(c2fb_c_int, &O0ULL)))))) Then
                Return Cast(c2fb_c_int, 7ULL)
            End If
            c2fb_temp_55 = CPtr(c2fb_int64 Ptr, @(local14->id))
            c2fb_temp_56 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_55) = c2fb_temp_56
            c2fb_temp_57 = CPtr(UByte Ptr, @(local14->iCell))
            c2fb_temp_58 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_57) = c2fb_temp_58
            c2fb_temp_59 = CPtr(UByte Ptr, @(local14->eWithin))
            c2fb_temp_60 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_59) = c2fb_temp_60
            ' C unused-parameter annotation
            c2fb_temp_61 = CPtr(SqliteRtreeNode Ptr Ptr, @(local1->aNode(Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_62 = local2
            (*c2fb_temp_61) = c2fb_temp_62
            c2fb_temp_63 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local2 = c2fb_temp_63
            ' empty C statement
            c2fb_temp_64 = Cast(c2fb_c_int, rtreeStepToLeaf(local1))
            local4 = c2fb_temp_64
        End If
    End If
    nodeRelease(local0, local2)
    rtreeRelease(local0)
    Return local4
End Function
Private Function rtreeBestIndex CDecl Alias "rtreeBestIndex" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As SqliteIndexInfo Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim local6(0 To 40) As Byte
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local7 As SqliteIndexConstraint Ptr
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As SQLITE_C_INT Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As UByte
    Dim c2fb_temp_12 As SQLITE_C_INT Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As SQLITE_C_INT Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As UByte Ptr
    Dim c2fb_temp_17 As UByte
    Dim c2fb_temp_18 As Double Ptr
    Dim c2fb_temp_19 As Double
    Dim c2fb_temp_20 As sqlite3_int64 Ptr
    Dim c2fb_temp_21 As c2fb_int64
    Dim c2fb_temp_22 As SQLITE_C_INT Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim local9 As UByte
    Dim local10 As UByte
    Dim c2fb_temp_24 As UByte
    Dim c2fb_temp_25 As UByte
    Dim c2fb_temp_26 As UByte
    Dim c2fb_temp_27 As UByte
    Dim c2fb_temp_28 As UByte
    Dim c2fb_temp_29 As UByte
    Dim c2fb_temp_30 As UByte
    Dim c2fb_temp_31 As UByte
    Dim c2fb_temp_32 As UByte
    Dim c2fb_temp_33 As UByte
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Byte Ptr
    Dim c2fb_temp_36 As Byte
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As Byte Ptr
    Dim c2fb_temp_39 As Byte
    Dim c2fb_temp_40 As SQLITE_C_INT Ptr
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As UByte Ptr
    Dim c2fb_temp_43 As UByte
    Dim c2fb_temp_44 As SQLITE_C_INT Ptr
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As SQLITE_C_INT Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As ZString Ptr Ptr
    Dim c2fb_temp_49 As ZString Ptr
    Dim c2fb_temp_50 As Any Ptr
    Dim c2fb_temp_51 As c2fb_int64
    Dim c2fb_temp_52 As Double Ptr
    Dim c2fb_temp_53 As Double
    Dim c2fb_temp_54 As sqlite3_int64 Ptr
    Dim c2fb_temp_55 As c2fb_int64

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local5 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic array storage
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(Byte Ptr, (@local6(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, (41ULL * SizeOf(Byte)))))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local2 < arg1->nConstraint))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->aConstraint[local2].op) = Cast(c2fb_c_int, 64ULL))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local3 = c2fb_temp_3
        End If
    c2fb_flow_1:
        c2fb_temp_2 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    ' C unused-parameter annotation
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < arg1->nConstraint)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (41ULL * SizeOf(Byte)))) - Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))))))) <> 0)))))
        local7 = CPtr(SqliteIndexConstraint Ptr, @(arg1->aConstraint[local2]))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local7->usable <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7->iColumn <= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local7->op) = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
            ' C automatic storage declaration
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local8 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((local8 < local2))))
                c2fb_temp_8 = CPtr(SQLITE_C_INT Ptr, @(arg1->aConstraintUsage[local8].argvIndex))
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_8) = Cast(SQLITE_C_INT, c2fb_temp_9)
                c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
                c2fb_temp_10 = CPtr(UByte Ptr, @(arg1->aConstraintUsage[local8].omit))
                c2fb_temp_11 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_10) = c2fb_temp_11
            c2fb_flow_5:
                c2fb_temp_7 = local8
                local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            Wend
            c2fb_flow_4:
            c2fb_temp_12 = CPtr(SQLITE_C_INT Ptr, @(arg1->idxNum))
            c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_12) = Cast(SQLITE_C_INT, c2fb_temp_13)
            c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
            c2fb_temp_14 = CPtr(SQLITE_C_INT Ptr, @(arg1->aConstraintUsage[local2].argvIndex))
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_14) = Cast(SQLITE_C_INT, c2fb_temp_15)
            c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
            c2fb_temp_16 = CPtr(UByte Ptr, @(arg1->aConstraintUsage[local8].omit))
            c2fb_temp_17 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_16) = c2fb_temp_17
            c2fb_temp_18 = CPtr(Double Ptr, @(arg1->estimatedCost))
            c2fb_temp_19 = Cast(Double, 30.0#)
            (*c2fb_temp_18) = c2fb_temp_19
            c2fb_temp_20 = CPtr(sqlite3_int64 Ptr, @(arg1->estimatedRows))
            c2fb_temp_21 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_20) = Cast(sqlite3_int64, c2fb_temp_21)
            c2fb_temp_21 = Cast(c2fb_int64, (*c2fb_temp_20))
            c2fb_temp_22 = CPtr(SQLITE_C_INT Ptr, @(arg1->idxFlags))
            c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H00000001ULL))
            (*c2fb_temp_22) = Cast(SQLITE_C_INT, c2fb_temp_23)
            c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        If (-Cast(c2fb_c_int, (((local7->usable <> 0) AndAlso (((-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7->iColumn > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7->iColumn <= Cast(c2fb_c_int, local0->nDim2))))) <> 0)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local7->op) = Cast(c2fb_c_int, 64ULL))))) <> 0)))))) <> 0))))) Then
            ' C automatic storage declaration
            local10 = Cast(c2fb_c_int, 1ULL)
            Select Case local7->op
                Case Cast(c2fb_c_int, 2ULL)
                    c2fb_temp_24 = Cast(UByte, Cast(c2fb_c_int, &H41ULL))
                    local9 = c2fb_temp_24
                    c2fb_temp_25 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                    local10 = c2fb_temp_25
                Case Cast(c2fb_c_int, 4ULL)
                    c2fb_temp_26 = Cast(UByte, Cast(c2fb_c_int, &H45ULL))
                    local9 = c2fb_temp_26
                    c2fb_temp_27 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                    local10 = c2fb_temp_27
                Case Cast(c2fb_c_int, 8ULL)
                    c2fb_temp_28 = Cast(UByte, Cast(c2fb_c_int, &H42ULL))
                    local9 = c2fb_temp_28
                Case Cast(c2fb_c_int, 16ULL)
                    c2fb_temp_29 = Cast(UByte, Cast(c2fb_c_int, &H43ULL))
                    local9 = c2fb_temp_29
                    c2fb_temp_30 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                    local10 = c2fb_temp_30
                Case Cast(c2fb_c_int, 32ULL)
                    c2fb_temp_31 = Cast(UByte, Cast(c2fb_c_int, &H44ULL))
                    local9 = c2fb_temp_31
                Case Cast(c2fb_c_int, 64ULL)
                    c2fb_temp_32 = Cast(UByte, Cast(c2fb_c_int, &H46ULL))
                    local9 = c2fb_temp_32
                Case Else
                    c2fb_temp_33 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                    local9 = c2fb_temp_33
            End Select
            c2fb_flow_6:
            If local9 Then
                c2fb_temp_34 = local5
                local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_34 + 1)))
                c2fb_temp_35 = CPtr(Byte Ptr, @(local6(c2fb_temp_34)))
                c2fb_temp_36 = Cast(Byte, local9)
                (*c2fb_temp_35) = c2fb_temp_36
                c2fb_temp_37 = local5
                local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_37 + 1)))
                c2fb_temp_38 = CPtr(Byte Ptr, @(local6(c2fb_temp_37)))
                c2fb_temp_39 = Cast(Byte, Cast(Byte, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (local7->iColumn - Cast(c2fb_c_int, 1ULL))) + Cast(c2fb_c_int, 48))))))
                (*c2fb_temp_38) = c2fb_temp_39
                c2fb_temp_40 = CPtr(SQLITE_C_INT Ptr, @(arg1->aConstraintUsage[local2].argvIndex))
                c2fb_temp_41 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (local5 \ Cast(c2fb_c_int, 2ULL)))))
                (*c2fb_temp_40) = Cast(SQLITE_C_INT, c2fb_temp_41)
                c2fb_temp_41 = Cast(c2fb_c_int, (*c2fb_temp_40))
                c2fb_temp_42 = CPtr(UByte Ptr, @(arg1->aConstraintUsage[local2].omit))
                c2fb_temp_43 = Cast(UByte, local10)
                (*c2fb_temp_42) = c2fb_temp_43
            End If
        End If
    c2fb_flow_3:
        c2fb_temp_5 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_2:
    c2fb_temp_44 = CPtr(SQLITE_C_INT Ptr, @(arg1->idxNum))
    c2fb_temp_45 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
    (*c2fb_temp_44) = Cast(SQLITE_C_INT, c2fb_temp_45)
    c2fb_temp_45 = Cast(c2fb_c_int, (*c2fb_temp_44))
    c2fb_temp_46 = CPtr(SQLITE_C_INT Ptr, @(arg1->needToFreeIdxStr))
    c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_46) = Cast(SQLITE_C_INT, c2fb_temp_47)
    c2fb_temp_47 = Cast(c2fb_c_int, (*c2fb_temp_46))
    If (-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_48 = CPtr(ZString Ptr Ptr, @(arg1->idxStr))
        c2fb_temp_49 = CPtr(ZString Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))))))
        (*c2fb_temp_48) = c2fb_temp_49
        If (-Cast(c2fb_c_int, ((arg1->idxStr = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_50 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg1->idxStr), CPtr(Const Any Ptr, CPtr(Byte Ptr, (@local6(0)))), Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL)))))
    End If
    c2fb_temp_51 = Cast(c2fb_int64, Cast(c2fb_int64, (local0->nRowEst Shr (Cast(c2fb_c_int, (local5 \ Cast(c2fb_c_int, 2ULL)))))))
    local4 = c2fb_temp_51
    c2fb_temp_52 = CPtr(Double Ptr, @(arg1->estimatedCost))
    c2fb_temp_53 = Cast(Double, __c2fb_double_value(Cast(Double, (__c2fb_double_value(Cast(Double, 6.0#)) * __c2fb_double_value(Cast(Double, local4))))))
    (*c2fb_temp_52) = c2fb_temp_53
    c2fb_temp_54 = CPtr(sqlite3_int64 Ptr, @(arg1->estimatedRows))
    c2fb_temp_55 = Cast(c2fb_int64, local4)
    (*c2fb_temp_54) = Cast(sqlite3_int64, c2fb_temp_55)
    c2fb_temp_55 = Cast(c2fb_int64, (*c2fb_temp_54))
    Return local1
End Function
Private Function cellArea CDecl Alias "cellArea" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr) As Double
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Double
    Dim c2fb_temp_0 As Double
    Dim c2fb_temp_1 As Double
    Dim c2fb_temp_2 As Double
    Dim c2fb_temp_3 As Double
    Dim c2fb_temp_4 As Double
    Dim c2fb_switch_value_5 As c2fb_uint64
    Dim c2fb_switch_state_6 As c2fb_c_int
    Dim c2fb_temp_7 As Double
    Dim c2fb_temp_8 As Double
    Dim c2fb_temp_9 As Double
    Dim c2fb_temp_10 As Double
    Dim c2fb_temp_11 As Double
    Dim c2fb_switch_value_12 As c2fb_uint64
    Dim c2fb_switch_state_13 As c2fb_c_int

    local0 = __c2fb_double_value(Cast(Double, Cast(c2fb_c_int, 1ULL)))
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_switch_value_5 = Cast(c2fb_uint64, arg0->nDim)
        c2fb_switch_state_6 = 0
        Select Case c2fb_switch_value_5
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 5ULL))
                c2fb_switch_state_6 = 1
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))
                c2fb_switch_state_6 = 2
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 3ULL))
                c2fb_switch_state_6 = 3
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))
                c2fb_switch_state_6 = 4
            Case Else
                c2fb_switch_state_6 = 5
        End Select
        Do
            Select Case c2fb_switch_state_6
            Case 0
                Exit Do
            Case 1
                c2fb_temp_0 = Cast(Double, __c2fb_single_value(Cast(Single, (arg1->aCoord(Cast(c2fb_c_int, 9ULL)).f - arg1->aCoord(Cast(c2fb_c_int, 8ULL)).f))))
                local0 = c2fb_temp_0
                c2fb_switch_state_6 = 2
            Case 2
                c2fb_temp_1 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 * Cast(Double, __c2fb_single_value(Cast(Single, (arg1->aCoord(Cast(c2fb_c_int, 7ULL)).f - arg1->aCoord(Cast(c2fb_c_int, 6ULL)).f))))))))
                local0 = c2fb_temp_1
                c2fb_switch_state_6 = 3
            Case 3
                c2fb_temp_2 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 * Cast(Double, __c2fb_single_value(Cast(Single, (arg1->aCoord(Cast(c2fb_c_int, 5ULL)).f - arg1->aCoord(Cast(c2fb_c_int, 4ULL)).f))))))))
                local0 = c2fb_temp_2
                c2fb_switch_state_6 = 4
            Case 4
                c2fb_temp_3 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 * Cast(Double, __c2fb_single_value(Cast(Single, (arg1->aCoord(Cast(c2fb_c_int, 3ULL)).f - arg1->aCoord(Cast(c2fb_c_int, 2ULL)).f))))))))
                local0 = c2fb_temp_3
                c2fb_switch_state_6 = 5
            Case 5
                c2fb_temp_4 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 * Cast(Double, __c2fb_single_value(Cast(Single, (arg1->aCoord(Cast(c2fb_c_int, 1ULL)).f - arg1->aCoord(Cast(c2fb_c_int, &O0ULL)).f))))))))
                local0 = c2fb_temp_4
                c2fb_switch_state_6 = 0
            End Select
        Loop
        c2fb_flow_0:
    Else
        c2fb_switch_value_12 = Cast(c2fb_uint64, arg0->nDim)
        c2fb_switch_state_13 = 0
        Select Case c2fb_switch_value_12
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 5ULL))
                c2fb_switch_state_13 = 1
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 4ULL))
                c2fb_switch_state_13 = 2
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 3ULL))
                c2fb_switch_state_13 = 3
            Case Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))
                c2fb_switch_state_13 = 4
            Case Else
                c2fb_switch_state_13 = 5
        End Select
        Do
            Select Case c2fb_switch_state_13
            Case 0
                Exit Do
            Case 1
                c2fb_temp_7 = Cast(Double, Cast(c2fb_int64, (Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 9ULL)).i) - Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 8ULL)).i))))
                local0 = c2fb_temp_7
                c2fb_switch_state_13 = 2
            Case 2
                c2fb_temp_8 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 * Cast(Double, Cast(c2fb_int64, (Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 7ULL)).i) - Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 6ULL)).i))))))))
                local0 = c2fb_temp_8
                c2fb_switch_state_13 = 3
            Case 3
                c2fb_temp_9 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 * Cast(Double, Cast(c2fb_int64, (Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 5ULL)).i) - Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 4ULL)).i))))))))
                local0 = c2fb_temp_9
                c2fb_switch_state_13 = 4
            Case 4
                c2fb_temp_10 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 * Cast(Double, Cast(c2fb_int64, (Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 3ULL)).i) - Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 2ULL)).i))))))))
                local0 = c2fb_temp_10
                c2fb_switch_state_13 = 5
            Case 5
                c2fb_temp_11 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 * Cast(Double, Cast(c2fb_int64, (Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, 1ULL)).i) - Cast(c2fb_int64, arg1->aCoord(Cast(c2fb_c_int, &O0ULL)).i))))))))
                local0 = c2fb_temp_11
                c2fb_switch_state_13 = 0
            End Select
        Loop
        c2fb_flow_1:
    End If
    Return local0
End Function
Private Function cellMargin CDecl Alias "cellMargin" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr) As Double
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Double
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Double
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->nDim2) - Cast(c2fb_c_int, 2ULL)))
    Do
        c2fb_temp_0 = Cast(Double, __c2fb_double_value(Cast(Double, (local0 + (__c2fb_double_value(Cast(Double, ((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg1->aCoord(Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))).f))), (__c2fb_double_value(Cast(Double, arg1->aCoord(Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))).i))))) - (IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg1->aCoord(local1).f))), (__c2fb_double_value(Cast(Double, arg1->aCoord(local1).i)))))))))))))
        local0 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - Cast(c2fb_c_int, 2ULL))))
        local1 = c2fb_temp_1
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL)))))
    c2fb_flow_0:
    Return local0
End Function
Private Sub cellUnion CDecl Alias "cellUnion" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_source_record_27 Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Single Ptr
    Dim c2fb_temp_1 As Single
    Dim c2fb_temp_2 As Single Ptr
    Dim c2fb_temp_3 As Single
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL))))) Then
        Do
            c2fb_temp_0 = CPtr(Single Ptr, @(arg1->aCoord(local0).f))
            c2fb_temp_1 = Cast(Single, (IIf((-Cast(c2fb_c_int, (((arg1->aCoord(local0).f) > (arg2->aCoord(local0).f))))), (arg2->aCoord(local0).f), (arg1->aCoord(local0).f))))
            (*c2fb_temp_0) = c2fb_temp_1
            c2fb_temp_2 = CPtr(Single Ptr, @(arg1->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).f))
            c2fb_temp_3 = Cast(Single, (IIf((-Cast(c2fb_c_int, (((arg1->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).f) < (arg2->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).f))))), (arg2->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).f), (arg1->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).f))))
            (*c2fb_temp_2) = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 2ULL))))
            local0 = c2fb_temp_4
        c2fb_flow_1:
        Loop While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, arg0->nDim2)))))
        c2fb_flow_0:
    Else
        Do
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg1->aCoord(local0).i))
            c2fb_temp_6 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, (((arg1->aCoord(local0).i) > (arg2->aCoord(local0).i))))), (arg2->aCoord(local0).i), (arg1->aCoord(local0).i))))
            (*c2fb_temp_5) = c2fb_temp_6
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(arg1->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).i))
            c2fb_temp_8 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, (((arg1->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).i) < (arg2->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).i))))), (arg2->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).i), (arg1->aCoord(Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL)))).i))))
            (*c2fb_temp_7) = c2fb_temp_8
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 2ULL))))
            local0 = c2fb_temp_9
        c2fb_flow_3:
        Loop While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, arg0->nDim2)))))
        c2fb_flow_2:
    End If
End Sub
Private Function cellContains CDecl Alias "cellContains" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_source_record_26 Ptr
    Dim local2 As c2fb_source_record_26 Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_source_record_26 Ptr
    Dim local4 As c2fb_source_record_26 Ptr

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, arg0->nDim2)))))
            local1 = CPtr(c2fb_source_record_26 Ptr, @(arg1->aCoord(local0)))
            local2 = CPtr(c2fb_source_record_26 Ptr, @(arg2->aCoord(local0)))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2[Cast(c2fb_c_int, &O0ULL)].i < local1[Cast(c2fb_c_int, &O0ULL)].i)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2[Cast(c2fb_c_int, 1ULL)].i > local1[Cast(c2fb_c_int, 1ULL)].i)))) <> 0))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        c2fb_flow_1:
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 2ULL))))
            local0 = c2fb_temp_1
        Wend
        c2fb_flow_0:
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, arg0->nDim2)))))
            local3 = CPtr(c2fb_source_record_26 Ptr, @(arg1->aCoord(local0)))
            local4 = CPtr(c2fb_source_record_26 Ptr, @(arg2->aCoord(local0)))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4[Cast(c2fb_c_int, &O0ULL)].f < local3[Cast(c2fb_c_int, &O0ULL)].f)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4[Cast(c2fb_c_int, 1ULL)].f > local3[Cast(c2fb_c_int, 1ULL)].f)))) <> 0))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        c2fb_flow_3:
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 2ULL))))
            local0 = c2fb_temp_3
        Wend
        c2fb_flow_2:
    End If
    Return Cast(c2fb_c_int, 1ULL)
End Function
Private Function cellOverlap CDecl Alias "cellOverlap" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_source_record_27 Ptr, ByVal arg3 As c2fb_c_int) As Double
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As Double
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As Double
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As Double
    Dim local5 As Double
    Dim c2fb_temp_4 As Double
    Dim c2fb_temp_5 As Double
    Dim c2fb_temp_6 As Double
    Dim c2fb_temp_7 As Double
    Dim c2fb_temp_8 As Double

    ' C automatic storage declaration
    local1 = 0.0#
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg3))))
        ' C automatic storage declaration
        local3 = __c2fb_double_value(Cast(Double, Cast(c2fb_c_int, 1ULL)))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, arg0->nDim2)))))
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_4 = Cast(Double, (IIf((-Cast(c2fb_c_int, ((((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg1->aCoord(local2).f))), (__c2fb_double_value(Cast(Double, arg1->aCoord(local2).i)))))) < ((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg2[local0].aCoord(local2).f))), (__c2fb_double_value(Cast(Double, arg2[local0].aCoord(local2).i)))))))))), ((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg2[local0].aCoord(local2).f))), (__c2fb_double_value(Cast(Double, arg2[local0].aCoord(local2).i)))))), ((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg1->aCoord(local2).f))), (__c2fb_double_value(Cast(Double, arg1->aCoord(local2).i)))))))))
            local4 = c2fb_temp_4
            c2fb_temp_5 = Cast(Double, (IIf((-Cast(c2fb_c_int, ((((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg1->aCoord(Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))).f))), (__c2fb_double_value(Cast(Double, arg1->aCoord(Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))).i)))))) > ((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg2[local0].aCoord(Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))).f))), (__c2fb_double_value(Cast(Double, arg2[local0].aCoord(Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))).i)))))))))), ((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg2[local0].aCoord(Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))).f))), (__c2fb_double_value(Cast(Double, arg2[local0].aCoord(Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))).i)))))), ((IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg1->aCoord(Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))).f))), (__c2fb_double_value(Cast(Double, arg1->aCoord(Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))).i)))))))))
            local5 = c2fb_temp_5
            If (-Cast(c2fb_c_int, ((local5 < local4)))) Then
                c2fb_temp_6 = Cast(Double, __c2fb_double_value(Cast(Double, Cast(c2fb_c_int, &O0ULL))))
                local3 = c2fb_temp_6
                Goto c2fb_flow_2
            Else
                c2fb_temp_7 = Cast(Double, __c2fb_double_value(Cast(Double, (local3 * (__c2fb_double_value(Cast(Double, (local5 - local4))))))))
                local3 = c2fb_temp_7
            End If
        c2fb_flow_3:
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 2ULL))))
            local2 = c2fb_temp_3
        Wend
        c2fb_flow_2:
        c2fb_temp_8 = Cast(Double, __c2fb_double_value(Cast(Double, (local1 + local3))))
        local1 = c2fb_temp_8
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function
Private Function ChooseLeaf CDecl Alias "ChooseLeaf" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As SqliteRtreeNode Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim local6 As Double
    Dim local7 As Double
    Dim local8 As c2fb_c_int
    Dim local9 As SqliteRtreeNode Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local10 As c2fb_source_record_27
    Dim local11 As Double
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As Double
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local12 As c2fb_source_record_27
    Dim local13 As Double
    Dim local14 As Double
    Dim c2fb_temp_10 As Double
    Dim c2fb_temp_11 As Double
    Dim c2fb_temp_12 As Double
    Dim c2fb_temp_13 As Double
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As SqliteRtreeNode Ptr
    Dim c2fb_temp_17 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_18 As SqliteRtreeNode Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, nodeAcquire(arg0, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL), CPtr(SqliteRtreeNode Ptr Ptr, @(local2))))
    local0 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < (Cast(c2fb_c_int, (arg0->iDepth - arg2))))))) <> 0)))))
        ' C automatic storage declaration
        local4 = Cast(c2fb_c_int, &O0ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        local6 = 0.0#
        local7 = 0.0#
        local8 = readInt16(CPtr(UByte Ptr, @((local2)->zData[Cast(c2fb_c_int, 2ULL)])))
        local9 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local3 < local8))))
            ' C automatic storage declaration
            nodeGetCell(arg0, local2, local3, CPtr(c2fb_source_record_27 Ptr, @(local10)))
            If cellContains(arg0, CPtr(c2fb_source_record_27 Ptr, @(local10)), arg1) Then
                local11 = cellArea(arg0, CPtr(c2fb_source_record_27 Ptr, @(local10)))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local11 < local7)))) <> 0))))) Then
                    c2fb_temp_5 = Cast(c2fb_int64, local10.iRowid)
                    local4 = c2fb_temp_5
                    c2fb_temp_6 = Cast(Double, local11)
                    local7 = c2fb_temp_6
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local5 = c2fb_temp_7
                End If
            End If
        c2fb_flow_3:
            c2fb_temp_4 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, (local5 = 0))) Then
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_8
            While (-Cast(c2fb_c_int, ((local3 < local8))))
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                nodeGetCell(arg0, local2, local3, CPtr(c2fb_source_record_27 Ptr, @(local12)))
                c2fb_temp_10 = Cast(Double, cellArea(arg0, CPtr(c2fb_source_record_27 Ptr, @(local12))))
                local14 = c2fb_temp_10
                cellUnion(arg0, CPtr(c2fb_source_record_27 Ptr, @(local12)), arg1)
                c2fb_temp_11 = Cast(Double, __c2fb_double_value(Cast(Double, (cellArea(arg0, CPtr(c2fb_source_record_27 Ptr, @(local12))) - local14))))
                local13 = c2fb_temp_11
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local13 < local6)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local13 = local6)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local14 < local7)))) <> 0)))))) <> 0))))) Then
                    c2fb_temp_12 = Cast(Double, local13)
                    local6 = c2fb_temp_12
                    c2fb_temp_13 = Cast(Double, local14)
                    local7 = c2fb_temp_13
                    c2fb_temp_14 = Cast(c2fb_int64, local12.iRowid)
                    local4 = c2fb_temp_14
                End If
            c2fb_flow_5:
                c2fb_temp_9 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
            Wend
            c2fb_flow_4:
        End If
        c2fb_temp_15 = Cast(c2fb_c_int, nodeAcquire(arg0, local4, local2, CPtr(SqliteRtreeNode Ptr Ptr, @(local9))))
        local0 = c2fb_temp_15
        nodeRelease(arg0, local2)
        c2fb_temp_16 = local9
        local2 = c2fb_temp_16
    c2fb_flow_1:
        c2fb_temp_2 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_17 = CPtr(SqliteRtreeNode Ptr Ptr, @((*arg3)))
    c2fb_temp_18 = local2
    (*c2fb_temp_17) = c2fb_temp_18
    Return local0
End Function
Private Function AdjustTree CDecl Alias "AdjustTree" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeNode Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As SqliteRtreeNode Ptr
    Dim local4 As c2fb_source_record_27
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr

    local0 = arg1
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    While local0->pParent
        local3 = local0->pParent
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        If (-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 100ULL))))) Then
            ' empty C statement
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        c2fb_temp_1 = Cast(c2fb_c_int, nodeParentIndex(arg0, local0, CPtr(c2fb_c_int Ptr, @(local5))))
        local2 = c2fb_temp_1
        If ((-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL)))))) Then
            ' empty C statement
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        nodeGetCell(arg0, local3, local5, CPtr(c2fb_source_record_27 Ptr, @(local4)))
        If (-Cast(c2fb_c_int, (cellContains(arg0, CPtr(c2fb_source_record_27 Ptr, @(local4)), arg2) = 0))) Then
            cellUnion(arg0, CPtr(c2fb_source_record_27 Ptr, @(local4)), arg2)
            nodeOverwriteCell(arg0, local3, CPtr(c2fb_source_record_27 Ptr, @(local4)), local5)
        End If
        c2fb_temp_2 = local3
        local0 = c2fb_temp_2
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rowidWrite CDecl Alias "rowidWrite" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    sqlite3_bind_int64(CPtr(Any Ptr, arg0->pWriteRowid), Cast(c2fb_c_int, 1ULL), arg1)
    sqlite3_bind_int64(CPtr(Any Ptr, arg0->pWriteRowid), Cast(c2fb_c_int, 2ULL), arg2)
    sqlite3_step(CPtr(Any Ptr, arg0->pWriteRowid))
    Return sqlite3_reset(CPtr(Any Ptr, arg0->pWriteRowid))
End Function
Private Function parentWrite CDecl Alias "parentWrite" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    sqlite3_bind_int64(CPtr(Any Ptr, arg0->pWriteParent), Cast(c2fb_c_int, 1ULL), arg1)
    sqlite3_bind_int64(CPtr(Any Ptr, arg0->pWriteParent), Cast(c2fb_c_int, 2ULL), arg2)
    sqlite3_step(CPtr(Any Ptr, arg0->pWriteParent))
    Return sqlite3_reset(CPtr(Any Ptr, arg0->pWriteParent))
End Function
Private Sub SortByDimension CDecl Alias "SortByDimension" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_source_record_27 Ptr, ByVal arg5 As c2fb_c_int Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int Ptr
    Dim local5 As c2fb_c_int Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim local6 As Double
    Dim local7 As Double
    Dim local8 As Double
    Dim local9 As Double
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_c_int, 1ULL))))) Then
        local0 = Cast(c2fb_c_int, &O0ULL)
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = Cast(c2fb_c_int, (arg2 \ Cast(c2fb_c_int, 2ULL)))
        local3 = Cast(c2fb_c_int, (arg2 - local2))
        local4 = arg1
        local5 = CPtr(c2fb_c_int Ptr, @(arg1[local2]))
        SortByDimension(arg0, local4, local2, arg3, arg4, arg5)
        SortByDimension(arg0, local5, local3, arg3, arg4, arg5)
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg5), CPtr(Const Any Ptr, local4), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))) * Cast(c2fb_uint64, local2)))))
        c2fb_temp_1 = arg5
        local4 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < local2)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 < local3)))) <> 0)))))
            local6 = (IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg4[local4[local0]].aCoord(Cast(c2fb_c_int, (arg3 * Cast(c2fb_c_int, 2ULL)))).f))), (__c2fb_double_value(Cast(Double, arg4[local4[local0]].aCoord(Cast(c2fb_c_int, (arg3 * Cast(c2fb_c_int, 2ULL)))).i)))))
            local7 = (IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg4[local4[local0]].aCoord(Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg3 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))).f))), (__c2fb_double_value(Cast(Double, arg4[local4[local0]].aCoord(Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg3 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))).i)))))
            local8 = (IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg4[local5[local1]].aCoord(Cast(c2fb_c_int, (arg3 * Cast(c2fb_c_int, 2ULL)))).f))), (__c2fb_double_value(Cast(Double, arg4[local5[local1]].aCoord(Cast(c2fb_c_int, (arg3 * Cast(c2fb_c_int, 2ULL)))).i)))))
            local9 = (IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->eCoordType) = Cast(c2fb_c_int, &O0ULL)))))), (__c2fb_double_value(Cast(Double, arg4[local5[local1]].aCoord(Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg3 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))).f))), (__c2fb_double_value(Cast(Double, arg4[local5[local1]].aCoord(Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg3 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))).i)))))
            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((local0 <> local2))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((local1 = local3))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((local6 < local8))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 = local8)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 < local9)))) <> 0)))))) <> 0)))))) <> 0))))) Then
                c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg1[Cast(c2fb_c_int, (local0 + local1))]))
                c2fb_temp_3 = Cast(c2fb_c_int, local4[local0])
                (*c2fb_temp_2) = c2fb_temp_3
                c2fb_temp_4 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
            Else
                c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg1[Cast(c2fb_c_int, (local0 + local1))]))
                c2fb_temp_6 = Cast(c2fb_c_int, local5[local1])
                (*c2fb_temp_5) = c2fb_temp_6
                c2fb_temp_7 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
End Sub
Private Function splitNodeStartree CDecl Alias "splitNodeStartree" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_source_record_27 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As SqliteRtreeNode Ptr, ByVal arg4 As SqliteRtreeNode Ptr, ByVal arg5 As c2fb_source_record_27 Ptr, ByVal arg6 As c2fb_source_record_27 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int Ptr Ptr
    Dim local1 As c2fb_c_int Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As Double
    Dim local6 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int Ptr Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local8 As Double
    Dim local9 As Double
    Dim local10 As Double
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local13 As c2fb_source_record_27
    Dim local14 As c2fb_source_record_27
    Dim local15 As c2fb_c_int
    Dim local16 As Double
    Dim local17 As Double
    Dim c2fb_temp_15 As Any Ptr
    Dim c2fb_temp_16 As Any Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Double
    Dim c2fb_temp_20 As Double
    Dim c2fb_temp_21 As Double
    Dim c2fb_temp_22 As Double
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As Double
    Dim c2fb_temp_25 As Double
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As Double
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As Any Ptr
    Dim c2fb_temp_30 As Any Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim local18 As SqliteRtreeNode Ptr
    Dim local19 As c2fb_source_record_27 Ptr
    Dim local20 As c2fb_source_record_27 Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = 0.0#
    local6 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->nDim) + Cast(c2fb_c_int, 1ULL))))) * (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int Ptr))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, arg2) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))))))))
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr Ptr, CPtr(Any Ptr, sqlite3_malloc64(local6)))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((CPtr(c2fb_c_int Ptr, CPtr(c2fb_c_int Ptr Ptr, @(local0[arg0->nDim]))))[Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0->nDim) * arg2))]))
    local1 = c2fb_temp_1
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), local6))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_3
    While (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, arg0->nDim)))))
        ' C automatic storage declaration
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr Ptr, @(local0[local2]))
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((CPtr(c2fb_c_int Ptr, CPtr(c2fb_c_int Ptr Ptr, @(local0[arg0->nDim]))))[Cast(c2fb_c_int, (local2 * arg2))]))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local7 = c2fb_temp_7
        While (-Cast(c2fb_c_int, ((local7 < arg2))))
            c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(local0[local2][local7]))
            c2fb_temp_10 = Cast(c2fb_c_int, local7)
            (*c2fb_temp_9) = c2fb_temp_10
        c2fb_flow_3:
            c2fb_temp_8 = local7
            local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
        Wend
        c2fb_flow_2:
        SortByDimension(arg0, local0[local2], arg2, local2, arg1, local1)
    c2fb_flow_1:
        c2fb_temp_4 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_11
    While (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, arg0->nDim)))))
        local8 = 0.0#
        local9 = 0.0#
        local10 = 0.0#
        local11 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_temp_13 = Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((arg0)->iNodeSize - Cast(c2fb_c_int, 4ULL)))) \ Cast(c2fb_c_int, (arg0)->nBytesPerCell)))) \ Cast(c2fb_c_int, 3ULL)))))
        local12 = c2fb_temp_13
        While (-Cast(c2fb_c_int, ((local12 <= (Cast(c2fb_c_int, (arg2 - (Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((arg0)->iNodeSize - Cast(c2fb_c_int, 4ULL)))) \ Cast(c2fb_c_int, (arg0)->nBytesPerCell)))) \ Cast(c2fb_c_int, 3ULL)))))))))))
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_15 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_source_record_27 Ptr, @(local13))), CPtr(Const Any Ptr, CPtr(c2fb_source_record_27 Ptr, @(arg1[local0[local2][Cast(c2fb_c_int, &O0ULL)]]))), Cast(c2fb_size_t, SizeOf(c2fb_source_record_27))))
            c2fb_temp_16 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_source_record_27 Ptr, @(local14))), CPtr(Const Any Ptr, CPtr(c2fb_source_record_27 Ptr, @(arg1[local0[local2][Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 1ULL)))]]))), Cast(c2fb_size_t, SizeOf(c2fb_source_record_27))))
            c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local15 = c2fb_temp_17
            While (-Cast(c2fb_c_int, ((local15 < (Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 1ULL))))))))
                If (-Cast(c2fb_c_int, ((local15 < local12)))) Then
                    cellUnion(arg0, CPtr(c2fb_source_record_27 Ptr, @(local13)), CPtr(c2fb_source_record_27 Ptr, @(arg1[local0[local2][local15]])))
                Else
                    cellUnion(arg0, CPtr(c2fb_source_record_27 Ptr, @(local14)), CPtr(c2fb_source_record_27 Ptr, @(arg1[local0[local2][local15]])))
                End If
            c2fb_flow_9:
                c2fb_temp_18 = local15
                local15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
            Wend
            c2fb_flow_8:
            c2fb_temp_19 = Cast(Double, __c2fb_double_value(Cast(Double, (local8 + cellMargin(arg0, CPtr(c2fb_source_record_27 Ptr, @(local13)))))))
            local8 = c2fb_temp_19
            c2fb_temp_20 = Cast(Double, __c2fb_double_value(Cast(Double, (local8 + cellMargin(arg0, CPtr(c2fb_source_record_27 Ptr, @(local14)))))))
            local8 = c2fb_temp_20
            c2fb_temp_21 = Cast(Double, cellOverlap(arg0, CPtr(c2fb_source_record_27 Ptr, @(local13)), CPtr(c2fb_source_record_27 Ptr, @(local14)), Cast(c2fb_c_int, 1ULL)))
            local16 = c2fb_temp_21
            c2fb_temp_22 = Cast(Double, __c2fb_double_value(Cast(Double, (cellArea(arg0, CPtr(c2fb_source_record_27 Ptr, @(local13))) + cellArea(arg0, CPtr(c2fb_source_record_27 Ptr, @(local14)))))))
            local17 = c2fb_temp_22
            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((local12 = (Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((arg0)->iNodeSize - Cast(c2fb_c_int, 4ULL)))) \ Cast(c2fb_c_int, (arg0)->nBytesPerCell)))) \ Cast(c2fb_c_int, 3ULL))))))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((local16 < local9))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local16 = local9)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local17 < local10)))) <> 0)))))) <> 0))))) Then
                c2fb_temp_23 = Cast(c2fb_c_int, local12)
                local11 = c2fb_temp_23
                c2fb_temp_24 = Cast(Double, local16)
                local9 = c2fb_temp_24
                c2fb_temp_25 = Cast(Double, local17)
                local10 = c2fb_temp_25
            End If
        c2fb_flow_7:
            c2fb_temp_14 = local12
            local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
        Wend
        c2fb_flow_6:
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local8 < local5)))) <> 0))))) Then
            c2fb_temp_26 = Cast(c2fb_c_int, local2)
            local3 = c2fb_temp_26
            c2fb_temp_27 = Cast(Double, local8)
            local5 = c2fb_temp_27
            c2fb_temp_28 = Cast(c2fb_c_int, local11)
            local4 = c2fb_temp_28
        End If
    c2fb_flow_5:
        c2fb_temp_12 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
    Wend
    c2fb_flow_4:
    c2fb_temp_29 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg5), CPtr(Const Any Ptr, CPtr(c2fb_source_record_27 Ptr, @(arg1[local0[local3][Cast(c2fb_c_int, &O0ULL)]]))), Cast(c2fb_size_t, SizeOf(c2fb_source_record_27))))
    c2fb_temp_30 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg6), CPtr(Const Any Ptr, CPtr(c2fb_source_record_27 Ptr, @(arg1[local0[local3][local4]]))), Cast(c2fb_size_t, SizeOf(c2fb_source_record_27))))
    c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_31
    While (-Cast(c2fb_c_int, ((local2 < arg2))))
        local18 = IIf(((-Cast(c2fb_c_int, ((local2 < local4))))), arg3, arg4)
        local19 = IIf(((-Cast(c2fb_c_int, ((local2 < local4))))), arg5, arg6)
        local20 = CPtr(c2fb_source_record_27 Ptr, @(arg1[local0[local3][local2]]))
        nodeInsertCell(arg0, local18, local20)
        cellUnion(arg0, local19, local20)
    c2fb_flow_11:
        c2fb_temp_32 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_32 + 1)))
    Wend
    c2fb_flow_10:
    sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function updateMapping CDecl Alias "updateMapping" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteRtreeNode Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_callback_171
    Dim c2fb_temp_0 As c2fb_callback_171
    Dim local1 As SqliteRtreeNode Ptr
    Dim local2 As SqliteRtreeNode Ptr
    Dim c2fb_temp_1 As SqliteRtreeNode Ptr
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr
    Dim c2fb_temp_3 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_4 As SqliteRtreeNode Ptr

    ' C automatic callback storage declaration
    c2fb_temp_0 = CPtr(c2fb_callback_171, (IIf(((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL)))))), CPtr(Any Ptr, ProcPtr(rowidWrite)), CPtr(Any Ptr, ProcPtr(parentWrite)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = CPtr(SqliteRtreeNode Ptr, nodeHashLookup(arg0, arg1))
        ' C automatic storage declaration
        c2fb_temp_1 = arg2
        local2 = c2fb_temp_1
        While local2
            If (-Cast(c2fb_c_int, ((local2 = local1)))) Then
                Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
            End If
        c2fb_flow_1:
            c2fb_temp_2 = local2->pParent
            local2 = c2fb_temp_2
        Wend
        c2fb_flow_0:
        If local1 Then
            nodeRelease(arg0, local1->pParent)
            nodeReference(arg2)
            c2fb_temp_3 = CPtr(SqliteRtreeNode Ptr Ptr, @(local1->pParent))
            c2fb_temp_4 = arg2
            (*c2fb_temp_3) = c2fb_temp_4
        End If
    End If
    If ((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL)))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return local0(arg0, arg1, arg2->iNode)
End Function
Private Function SplitNode CDecl Alias "SplitNode" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_source_record_27 Ptr
    Dim local5 As c2fb_c_int Ptr
    Dim local6 As SqliteRtreeNode Ptr
    Dim local7 As SqliteRtreeNode Ptr
    Dim local8 As c2fb_source_record_27
    Dim local9 As c2fb_source_record_27
    Dim c2fb_temp_0 As c2fb_source_record_27 Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As SqliteRtreeNode Ptr
    Dim c2fb_temp_9 As SqliteRtreeNode Ptr
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As SQLITE_C_INT Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As SqliteRtreeNode Ptr
    Dim c2fb_temp_15 As SqliteRtreeNode Ptr
    Dim c2fb_temp_16 As SQLITE_C_INT Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Any Ptr
    Dim c2fb_temp_20 As Any Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_int64 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim c2fb_temp_30 As c2fb_int64 Ptr
    Dim c2fb_temp_31 As c2fb_int64
    Dim c2fb_temp_32 As c2fb_c_int
    Dim local10 As SqliteRtreeNode Ptr
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim local12 As c2fb_int64
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int
    Dim local13 As c2fb_int64
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = readInt16(CPtr(UByte Ptr, @((arg1)->zData[Cast(c2fb_c_int, 2ULL)])))
    ' C automatic storage declaration
    ' C automatic storage declaration
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_27 Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, ((Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_27))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int)))))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))))))))
    local4 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local4 = 0))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_1
        Goto c2fb_label_0
    End If
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, CPtr(c2fb_source_record_27 Ptr, @(local4[Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL)))])))
    local5 = c2fb_temp_2
    c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local5), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL)))))))))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((local0 < local3))))
        nodeGetCell(arg0, arg1, local0, CPtr(c2fb_source_record_27 Ptr, @(local4[local0])))
    c2fb_flow_1:
        c2fb_temp_5 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    nodeZero(arg0, arg1)
    c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_source_record_27 Ptr, @(local4[local3]))), CPtr(Const Any Ptr, arg2), Cast(c2fb_size_t, SizeOf(c2fb_source_record_27))))
    c2fb_temp_7 = local3
    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
    If (-Cast(c2fb_c_int, ((arg1->iNode = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) Then
        c2fb_temp_8 = CPtr(SqliteRtreeNode Ptr, nodeNew(arg0, arg1))
        local7 = c2fb_temp_8
        c2fb_temp_9 = CPtr(SqliteRtreeNode Ptr, nodeNew(arg0, arg1))
        local6 = c2fb_temp_9
        c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(arg0->iDepth))
        c2fb_temp_11 = (*c2fb_temp_10)
        (*c2fb_temp_10) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
        c2fb_temp_12 = CPtr(SQLITE_C_INT Ptr, @(arg1->isDirty))
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_12) = Cast(SQLITE_C_INT, c2fb_temp_13)
        c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
        writeInt16(arg1->zData, arg0->iDepth)
    Else
        c2fb_temp_14 = arg1
        local6 = c2fb_temp_14
        c2fb_temp_15 = CPtr(SqliteRtreeNode Ptr, nodeNew(arg0, local6->pParent))
        local7 = c2fb_temp_15
        c2fb_temp_16 = CPtr(SQLITE_C_INT Ptr, @(local6->nRef))
        c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
        (*c2fb_temp_16) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local6 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, (local7 = 0))) <> 0))))) Then
        c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_18
        Goto c2fb_label_0
    End If
    c2fb_temp_19 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local6->zData), Cast(c2fb_c_int, &O0ULL), arg0->iNodeSize))
    c2fb_temp_20 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local7->zData), Cast(c2fb_c_int, &O0ULL), arg0->iNodeSize))
    c2fb_temp_21 = Cast(c2fb_c_int, splitNodeStartree(arg0, local4, local3, local6, local7, CPtr(c2fb_source_record_27 Ptr, @(local8)), CPtr(c2fb_source_record_27 Ptr, @(local9))))
    local2 = c2fb_temp_21
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    c2fb_temp_23 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_22 = Cast(c2fb_c_int, nodeWrite(arg0, local7))
    local2 = c2fb_temp_22
    c2fb_temp_27 = 1
    If (((-Cast(c2fb_c_int, ((c2fb_temp_23 <> (c2fb_temp_22))))) <> 0) = 0) Then
        c2fb_temp_26 = 0
        If ((-Cast(c2fb_c_int, ((Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)) = local6->iNode)))) <> 0) Then
            c2fb_temp_25 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_24 = Cast(c2fb_c_int, nodeWrite(arg0, local6))
            local2 = c2fb_temp_24
            c2fb_temp_26 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_25 <> (c2fb_temp_24))))) <> 0))))
        End If
        c2fb_temp_27 = (-Cast(c2fb_c_int, (((c2fb_temp_26) <> 0))))
    End If
    If c2fb_temp_27 Then
        Goto c2fb_label_0
    End If
    c2fb_temp_28 = CPtr(c2fb_int64 Ptr, @(local9.iRowid))
    c2fb_temp_29 = Cast(c2fb_int64, local7->iNode)
    (*c2fb_temp_28) = c2fb_temp_29
    c2fb_temp_30 = CPtr(c2fb_int64 Ptr, @(local8.iRowid))
    c2fb_temp_31 = Cast(c2fb_int64, local6->iNode)
    (*c2fb_temp_30) = c2fb_temp_31
    If (-Cast(c2fb_c_int, ((arg1->iNode = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) Then
        c2fb_temp_32 = Cast(c2fb_c_int, rtreeInsertCell(arg0, local6->pParent, CPtr(c2fb_source_record_27 Ptr, @(local8)), Cast(c2fb_c_int, (arg3 + Cast(c2fb_c_int, 1ULL)))))
        local2 = c2fb_temp_32
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_label_0
        End If
    Else
        local10 = local6->pParent
        ' C automatic storage declaration
        c2fb_temp_33 = Cast(c2fb_c_int, nodeParentIndex(arg0, local6, CPtr(c2fb_c_int Ptr, @(local11))))
        local2 = c2fb_temp_33
        If ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL)))))) Then
            nodeOverwriteCell(arg0, local10, CPtr(c2fb_source_record_27 Ptr, @(local8)), local11)
            c2fb_temp_34 = Cast(c2fb_c_int, AdjustTree(arg0, local10, CPtr(c2fb_source_record_27 Ptr, @(local8))))
            local2 = c2fb_temp_34
            ' C unused-parameter annotation
        End If
        If ((-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL)))))) Then
            Goto c2fb_label_0
        End If
    End If
    c2fb_temp_35 = Cast(c2fb_c_int, rtreeInsertCell(arg0, local7->pParent, CPtr(c2fb_source_record_27 Ptr, @(local9)), Cast(c2fb_c_int, (arg3 + Cast(c2fb_c_int, 1ULL)))))
    local2 = c2fb_temp_35
    If (c2fb_temp_35) Then
        Goto c2fb_label_0
    End If
    c2fb_temp_36 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_36
    While (-Cast(c2fb_c_int, ((local0 < readInt16(CPtr(UByte Ptr, @((local7)->zData[Cast(c2fb_c_int, 2ULL)])))))))
        local12 = nodeGetRowid(arg0, local7, local0)
        c2fb_temp_38 = Cast(c2fb_c_int, updateMapping(arg0, local12, local7, arg3))
        local2 = c2fb_temp_38
        If (-Cast(c2fb_c_int, ((local12 = arg2->iRowid)))) Then
            c2fb_temp_39 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local1 = c2fb_temp_39
        End If
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_label_0
        End If
    c2fb_flow_3:
        c2fb_temp_37 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_37 + 1)))
    Wend
    c2fb_flow_2:
    If (-Cast(c2fb_c_int, ((arg1->iNode = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) Then
        c2fb_temp_40 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_40
        While (-Cast(c2fb_c_int, ((local0 < readInt16(CPtr(UByte Ptr, @((local6)->zData[Cast(c2fb_c_int, 2ULL)])))))))
            local13 = nodeGetRowid(arg0, local6, local0)
            c2fb_temp_42 = Cast(c2fb_c_int, updateMapping(arg0, local13, local6, arg3))
            local2 = c2fb_temp_42
            If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_label_0
            End If
        c2fb_flow_5:
            c2fb_temp_41 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_41 + 1)))
        Wend
        c2fb_flow_4:
    Else
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_43 = Cast(c2fb_c_int, updateMapping(arg0, arg2->iRowid, local6, arg3))
            local2 = c2fb_temp_43
        End If
    End If
    c2fb_label_0:
    nodeRelease(arg0, local7)
    nodeRelease(arg0, local6)
    sqlite3_free(CPtr(Any Ptr, local4))
    Return local2
End Function
Private Function fixLeafParent CDecl Alias "fixLeafParent" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteRtreeNode Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local3 As SqliteRtreeNode Ptr
    Dim local4 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr
    Dim c2fb_temp_3 As SqliteRtreeNode Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As SqliteRtreeNode Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = arg1
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->iNode <> Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->pParent = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        local2 = Cast(c2fb_c_int, &O0ULL)
        sqlite3_bind_int64(CPtr(Any Ptr, arg0->pReadParent), Cast(c2fb_c_int, 1ULL), local1->iNode)
        c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_step(CPtr(Any Ptr, arg0->pReadParent)))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 100ULL))))) Then
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_1 = Cast(c2fb_int64, sqlite3_column_int64(CPtr(Any Ptr, arg0->pReadParent), Cast(c2fb_c_int, &O0ULL)))
            local4 = c2fb_temp_1
            c2fb_temp_2 = arg1
            local3 = c2fb_temp_2
            While (-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3->iNode <> local4)))) <> 0)))))
                ' empty C statement
            c2fb_flow_3:
                c2fb_temp_3 = local3->pParent
                local3 = c2fb_temp_3
            Wend
            c2fb_flow_2:
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, nodeAcquire(arg0, local4, Cast(c2fb_c_int, &O0ULL), CPtr(SqliteRtreeNode Ptr Ptr, @(local1->pParent))))
                local2 = c2fb_temp_4
            End If
        End If
        c2fb_temp_5 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, arg0->pReadParent)))
        local0 = c2fb_temp_5
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_6 = Cast(c2fb_c_int, local2)
            local0 = c2fb_temp_6
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (local1->pParent = 0))) <> 0))))) Then
            ' empty C statement
            c2fb_temp_7 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_7
        End If
        c2fb_temp_8 = local1->pParent
        local1 = c2fb_temp_8
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Function removeNode CDecl Alias "removeNode" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteRtreeNode Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As SqliteRtreeNode Ptr
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_3 As SqliteRtreeNode Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As sqlite3_int64 Ptr
    Dim c2fb_temp_12 As c2fb_int64
    Dim c2fb_temp_13 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_14 As SqliteRtreeNode Ptr
    Dim c2fb_temp_15 As SQLITE_C_INT Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_18 As SqliteRtreeNode Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, nodeParentIndex(arg0, arg1, CPtr(c2fb_c_int Ptr, @(local3))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = arg1->pParent
        local2 = c2fb_temp_1
        c2fb_temp_2 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg1->pParent))
        c2fb_temp_3 = CPtr(SqliteRtreeNode Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = Cast(c2fb_c_int, deleteCell(arg0, local2, local3, Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))))
        local0 = c2fb_temp_4
        ' empty C statement
    End If
    c2fb_temp_5 = Cast(c2fb_c_int, nodeRelease(arg0, local2))
    local1 = c2fb_temp_5
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_6 = Cast(c2fb_c_int, local1)
        local0 = c2fb_temp_6
    End If
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local0
    End If
    sqlite3_bind_int64(CPtr(Any Ptr, arg0->pDeleteNode), Cast(c2fb_c_int, 1ULL), arg1->iNode)
    sqlite3_step(CPtr(Any Ptr, arg0->pDeleteNode))
    c2fb_temp_8 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_7 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, arg0->pDeleteNode)))
    local0 = c2fb_temp_7
    If (-Cast(c2fb_c_int, ((c2fb_temp_8 <> (c2fb_temp_7))))) Then
        Return local0
    End If
    sqlite3_bind_int64(CPtr(Any Ptr, arg0->pDeleteParent), Cast(c2fb_c_int, 1ULL), arg1->iNode)
    sqlite3_step(CPtr(Any Ptr, arg0->pDeleteParent))
    c2fb_temp_10 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_9 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, arg0->pDeleteParent)))
    local0 = c2fb_temp_9
    If (-Cast(c2fb_c_int, ((c2fb_temp_10 <> (c2fb_temp_9))))) Then
        Return local0
    End If
    nodeHashDelete(arg0, arg1)
    c2fb_temp_11 = CPtr(sqlite3_int64 Ptr, @(arg1->iNode))
    c2fb_temp_12 = Cast(c2fb_int64, arg2)
    (*c2fb_temp_11) = Cast(sqlite3_int64, c2fb_temp_12)
    c2fb_temp_12 = Cast(c2fb_int64, (*c2fb_temp_11))
    c2fb_temp_13 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg1->pNext))
    c2fb_temp_14 = arg0->pDeleted
    (*c2fb_temp_13) = c2fb_temp_14
    c2fb_temp_15 = CPtr(SQLITE_C_INT Ptr, @(arg1->nRef))
    c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
    (*c2fb_temp_15) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 + 1)))
    c2fb_temp_17 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->pDeleted))
    c2fb_temp_18 = arg1
    (*c2fb_temp_17) = c2fb_temp_18
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fixBoundingBox CDecl Alias "fixBoundingBox" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeNode Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_source_record_27
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As c2fb_source_record_27
    Dim c2fb_temp_2 As c2fb_int64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = arg1->pParent
    local1 = Cast(c2fb_c_int, &O0ULL)
    If local0 Then
        ' C automatic storage declaration
        local3 = readInt16(CPtr(UByte Ptr, @((arg1)->zData[Cast(c2fb_c_int, 2ULL)])))
        ' C automatic storage declaration
        nodeGetCell(arg0, arg1, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_source_record_27 Ptr, @(local4)))
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local2 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local2 < local3))))
            ' C automatic storage declaration
            nodeGetCell(arg0, arg1, local2, CPtr(c2fb_source_record_27 Ptr, @(local5)))
            cellUnion(arg0, CPtr(c2fb_source_record_27 Ptr, @(local4)), CPtr(c2fb_source_record_27 Ptr, @(local5)))
        c2fb_flow_1:
            c2fb_temp_1 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_2 = CPtr(c2fb_int64 Ptr, @(local4.iRowid))
        c2fb_temp_3 = Cast(c2fb_int64, arg1->iNode)
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = Cast(c2fb_c_int, nodeParentIndex(arg0, arg1, CPtr(c2fb_c_int Ptr, @(local2))))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            nodeOverwriteCell(arg0, local0, CPtr(c2fb_source_record_27 Ptr, @(local4)), local2)
            c2fb_temp_5 = Cast(c2fb_c_int, fixBoundingBox(arg0, local0))
            local1 = c2fb_temp_5
        End If
    End If
    Return local1
End Function
Private Function deleteCell CDecl Alias "deleteCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeNode Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As SqliteRtreeNode Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, fixLeafParent(arg0, arg1))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((c2fb_temp_1 <> (c2fb_temp_0))))) Then
        Return local1
    End If
    nodeDeleteCell(arg0, arg1, arg2)
    c2fb_temp_2 = arg1->pParent
    local0 = c2fb_temp_2
    ' C unused-parameter annotation
    If local0 Then
        If (-Cast(c2fb_c_int, ((readInt16(CPtr(UByte Ptr, @((arg1)->zData[Cast(c2fb_c_int, 2ULL)]))) < (Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((arg0)->iNodeSize - Cast(c2fb_c_int, 4ULL)))) \ Cast(c2fb_c_int, (arg0)->nBytesPerCell)))) \ Cast(c2fb_c_int, 3ULL)))))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, removeNode(arg0, arg1, arg3))
            local1 = c2fb_temp_3
        Else
            c2fb_temp_4 = Cast(c2fb_c_int, fixBoundingBox(arg0, arg1))
            local1 = c2fb_temp_4
        End If
    End If
    Return local1
End Function
Private Function rtreeInsertCell CDecl Alias "rtreeInsertCell" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr, ByVal arg2 As c2fb_source_record_27 Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_1 As SqliteRtreeNode Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = CPtr(SqliteRtreeNode Ptr, nodeHashLookup(arg0, arg2->iRowid))
        If local1 Then
            nodeRelease(arg0, local1->pParent)
            nodeReference(arg1)
            c2fb_temp_0 = CPtr(SqliteRtreeNode Ptr Ptr, @(local1->pParent))
            c2fb_temp_1 = arg1
            (*c2fb_temp_0) = c2fb_temp_1
        End If
    End If
    If nodeInsertCell(arg0, arg1, arg2) Then
        c2fb_temp_2 = Cast(c2fb_c_int, SplitNode(arg0, arg1, arg2, arg3))
        local0 = c2fb_temp_2
    Else
        c2fb_temp_3 = Cast(c2fb_c_int, AdjustTree(arg0, arg1, arg2))
        local0 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, rowidWrite(arg0, arg2->iRowid, arg1->iNode))
                local0 = c2fb_temp_4
            Else
                c2fb_temp_5 = Cast(c2fb_c_int, parentWrite(arg0, arg2->iRowid, arg1->iNode))
                local0 = c2fb_temp_5
            End If
        End If
    End If
    Return local0
End Function
Private Function reinsertNodeContent CDecl Alias "reinsertNodeContent" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As SqliteRtreeNode Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As SqliteRtreeNode Ptr
    Dim local4 As c2fb_source_record_27
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = readInt16(CPtr(UByte Ptr, @((arg1)->zData[Cast(c2fb_c_int, 2ULL)])))
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < local2)))) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        nodeGetCell(arg0, arg1, local0, CPtr(c2fb_source_record_27 Ptr, @(local4)))
        c2fb_temp_2 = Cast(c2fb_c_int, ChooseLeaf(arg0, CPtr(c2fb_source_record_27 Ptr, @(local4)), Cast(c2fb_c_int, arg1->iNode), CPtr(SqliteRtreeNode Ptr Ptr, @(local3))))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_3 = Cast(c2fb_c_int, rtreeInsertCell(arg0, local3, CPtr(c2fb_source_record_27 Ptr, @(local4)), Cast(c2fb_c_int, arg1->iNode)))
            local1 = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_c_int, nodeRelease(arg0, local3))
            local5 = c2fb_temp_4
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, local5)
                local1 = c2fb_temp_5
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function
Private Function rtreeNewRowid CDecl Alias "rtreeNewRowid" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_int64 Ptr
    Dim c2fb_temp_2 As c2fb_int64

    ' C automatic storage declaration
    sqlite3_bind_null(CPtr(Any Ptr, arg0->pWriteRowid), Cast(c2fb_c_int, 1ULL))
    sqlite3_bind_null(CPtr(Any Ptr, arg0->pWriteRowid), Cast(c2fb_c_int, 2ULL))
    sqlite3_step(CPtr(Any Ptr, arg0->pWriteRowid))
    c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, arg0->pWriteRowid)))
    local0 = c2fb_temp_0
    c2fb_temp_1 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_2 = Cast(c2fb_int64, c2fb_external_sqlite3_last_insert_rowid(arg0->db))
    (*c2fb_temp_1) = c2fb_temp_2
    Return local0
End Function
Private Function rtreeDeleteRowid CDecl Alias "rtreeDeleteRowid" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteRtreeNode Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As SqliteRtreeNode Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As SqliteRtreeNode Ptr
    Dim local7 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As SQLITE_C_INT Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As SqliteRtreeNode Ptr
    Dim c2fb_temp_16 As SqliteRtreeNode Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As SqliteRtreeNode Ptr Ptr
    Dim c2fb_temp_19 As SqliteRtreeNode Ptr
    Dim c2fb_temp_20 As c2fb_c_uint Ptr
    Dim c2fb_temp_21 As c2fb_c_uint
    Dim c2fb_temp_22 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, nodeAcquire(arg0, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL), CPtr(SqliteRtreeNode Ptr Ptr, @(local3))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, findLeafNode(arg0, arg1, CPtr(SqliteRtreeNode Ptr Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1 <> 0))))) Then
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, nodeRowidIndex(arg0, local1, arg1, CPtr(c2fb_c_int Ptr, @(local2))))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, deleteCell(arg0, local1, local2, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_3
        End If
        c2fb_temp_4 = Cast(c2fb_c_int, nodeRelease(arg0, local1))
        local4 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, local4)
            local0 = c2fb_temp_5
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_bind_int64(CPtr(Any Ptr, arg0->pDeleteRowid), Cast(c2fb_c_int, 1ULL), arg1)
        sqlite3_step(CPtr(Any Ptr, arg0->pDeleteRowid))
        c2fb_temp_6 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, arg0->pDeleteRowid)))
        local0 = c2fb_temp_6
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->iDepth > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((readInt16(CPtr(UByte Ptr, @((local3)->zData[Cast(c2fb_c_int, 2ULL)]))) = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        ' C automatic storage declaration
        local6 = Cast(c2fb_c_int, &O0ULL)
        local7 = nodeGetRowid(arg0, local3, Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_7 = Cast(c2fb_c_int, nodeAcquire(arg0, local7, local3, CPtr(SqliteRtreeNode Ptr Ptr, @(local6))))
        local0 = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_8 = Cast(c2fb_c_int, removeNode(arg0, local6, Cast(c2fb_c_int, (arg0->iDepth - Cast(c2fb_c_int, 1ULL)))))
            local0 = c2fb_temp_8
        End If
        c2fb_temp_9 = Cast(c2fb_c_int, nodeRelease(arg0, local6))
        local5 = c2fb_temp_9
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_10 = Cast(c2fb_c_int, local5)
            local0 = c2fb_temp_10
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @(arg0->iDepth))
            c2fb_temp_12 = (*c2fb_temp_11)
            (*c2fb_temp_11) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 - 1)))
            writeInt16(local3->zData, arg0->iDepth)
            c2fb_temp_13 = CPtr(SQLITE_C_INT Ptr, @(local3->isDirty))
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_13) = Cast(SQLITE_C_INT, c2fb_temp_14)
            c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
        End If
    End If
    c2fb_temp_15 = arg0->pDeleted
    local1 = c2fb_temp_15
    While local1
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_17 = Cast(c2fb_c_int, reinsertNodeContent(arg0, local1))
            local0 = c2fb_temp_17
        End If
        c2fb_temp_18 = CPtr(SqliteRtreeNode Ptr Ptr, @(arg0->pDeleted))
        c2fb_temp_19 = local1->pNext
        (*c2fb_temp_18) = c2fb_temp_19
        c2fb_temp_20 = CPtr(c2fb_c_uint Ptr, @(arg0->nNodeRef))
        c2fb_temp_21 = (*c2fb_temp_20)
        (*c2fb_temp_20) = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_21 - 1)))
        sqlite3_free(CPtr(Any Ptr, local1))
    c2fb_flow_1:
        c2fb_temp_16 = arg0->pDeleted
        local1 = c2fb_temp_16
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_22 = Cast(c2fb_c_int, nodeRelease(arg0, local3))
        local0 = c2fb_temp_22
    Else
        nodeRelease(arg0, local3)
    End If
    Return local0
End Function
Private Function rtreeValueDown CDecl Alias "rtreeValueDown" (ByVal arg0 As SqliteVdbeMem Ptr) As Single
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Double
    Dim local1 As Single
    Dim local2 As c2fb_c_uint
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As Any Ptr

    local0 = c2fb_external_sqlite3_value_double(arg0)
    local1 = __c2fb_single_value(Cast(Single, local0))
    If (-Cast(c2fb_c_int, ((Cast(Double, local1) > local0)))) Then
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_c_uint Ptr, @(local2))), CPtr(Const Any Ptr, CPtr(Single Ptr, @(local1))), Cast(c2fb_c_int, 4ULL)))
        c2fb_temp_1 = Cast(c2fb_c_uint, IIf((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &H80000000ULL)))) <> Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))), Cast(c2fb_c_uint, (local2 + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))), Cast(c2fb_c_uint, (local2 - Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))))
        local2 = c2fb_temp_1
        c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Single Ptr, @(local1))), CPtr(Const Any Ptr, CPtr(c2fb_c_uint Ptr, @(local2))), Cast(c2fb_c_int, 4ULL)))
    End If
    Return local1
End Function
Private Function rtreeValueUp CDecl Alias "rtreeValueUp" (ByVal arg0 As SqliteVdbeMem Ptr) As Single
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Double
    Dim local1 As Single
    Dim local2 As c2fb_c_uint
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As Any Ptr

    local0 = c2fb_external_sqlite3_value_double(arg0)
    local1 = __c2fb_single_value(Cast(Single, local0))
    If (-Cast(c2fb_c_int, ((Cast(Double, local1) < local0)))) Then
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_c_uint Ptr, @(local2))), CPtr(Const Any Ptr, CPtr(Single Ptr, @(local1))), Cast(c2fb_c_int, 4ULL)))
        c2fb_temp_1 = Cast(c2fb_c_uint, IIf((-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, &H80000000ULL)))) <> Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))), Cast(c2fb_c_uint, (local2 - Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))), Cast(c2fb_c_uint, (local2 + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))))
        local2 = c2fb_temp_1
        c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Single Ptr, @(local1))), CPtr(Const Any Ptr, CPtr(c2fb_c_uint Ptr, @(local2))), Cast(c2fb_c_int, 4ULL)))
    End If
    Return local1
End Function
Private Function rtreeConstraintError CDecl Alias "rtreeConstraintError" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteVdbe Ptr
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim local4 As Const ZString Ptr
    Dim local5 As Const ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT * FROM %Q.%Q"), arg0->zDb, arg0->zName))
    local1 = c2fb_temp_0
    If local1 Then
        c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_prepare_v2(CPtr(Any Ptr, arg0->db), CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Any Ptr Ptr, CPtr(SqliteVdbe Ptr Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL)))
        local2 = c2fb_temp_1
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_2
    End If
    sqlite3_free(CPtr(Any Ptr, local1))
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
            local3 = CPtr(Const ZString Ptr, sqlite3_column_name(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL)))
            c2fb_temp_3 = CPtr(ZString Ptr Ptr, @(arg0->base.zErrMsg))
            c2fb_temp_4 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"UNIQUE constraint failed: %s.%s"), arg0->zName, local3))
            (*c2fb_temp_3) = c2fb_temp_4
        Else
            local4 = CPtr(Const ZString Ptr, sqlite3_column_name(CPtr(Any Ptr, local0), arg1))
            local5 = CPtr(Const ZString Ptr, sqlite3_column_name(CPtr(Any Ptr, local0), Cast(c2fb_c_int, (arg1 + Cast(c2fb_c_int, 1ULL)))))
            c2fb_temp_5 = CPtr(ZString Ptr Ptr, @(arg0->base.zErrMsg))
            c2fb_temp_6 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"rtree constraint failed: %s.(%s<=%s)"), arg0->zName, local4, local5))
            (*c2fb_temp_5) = c2fb_temp_6
        End If
    End If
    sqlite3_finalize(CPtr(Any Ptr, local0))
    Return (IIf((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, 19ULL), local2))
End Function
Private Function rtreeUpdate CDecl Alias "rtreeUpdate" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_source_record_27
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Single Ptr
    Dim c2fb_temp_5 As Single
    Dim c2fb_temp_6 As Single Ptr
    Dim c2fb_temp_7 As Single
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_int64 Ptr
    Dim c2fb_temp_17 As c2fb_int64
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim local7 As SqliteRtreeNode Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_int64 Ptr
    Dim c2fb_temp_26 As c2fb_int64
    Dim c2fb_temp_27 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim local9 As SqliteVdbe Ptr
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    If local0->nNodeRef Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 6ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    rtreeReference(local0)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_27 Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_27))))
    If (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 1ULL))))) Then
        ' C automatic storage declaration
        local5 = Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 4ULL)))
        If (-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, local0->nDim2))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, local0->nDim2)
            local5 = c2fb_temp_1
        End If
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->eCoordType) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local4 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((local4 < local5))))
                c2fb_temp_4 = CPtr(Single Ptr, @(local2.aCoord(local4).f))
                c2fb_temp_5 = Cast(Single, rtreeValueDown(arg2[Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 3ULL)))]))
                (*c2fb_temp_4) = c2fb_temp_5
                c2fb_temp_6 = CPtr(Single Ptr, @(local2.aCoord(Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))).f))
                c2fb_temp_7 = Cast(Single, rtreeValueUp(arg2[Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 4ULL)))]))
                (*c2fb_temp_6) = c2fb_temp_7
                If (-Cast(c2fb_c_int, ((local2.aCoord(local4).f > local2.aCoord(Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))).f)))) Then
                    c2fb_temp_8 = Cast(c2fb_c_int, rtreeConstraintError(local0, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))))
                    local1 = c2fb_temp_8
                    Goto c2fb_label_0
                End If
            c2fb_flow_1:
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 2ULL))))
                local4 = c2fb_temp_3
            Wend
            c2fb_flow_0:
        Else
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local4 = c2fb_temp_9
            While (-Cast(c2fb_c_int, ((local4 < local5))))
                c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @(local2.aCoord(local4).i))
                c2fb_temp_12 = Cast(c2fb_c_int, rtreeValueInt32(arg2[Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 3ULL)))]))
                (*c2fb_temp_11) = c2fb_temp_12
                c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @(local2.aCoord(Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))).i))
                c2fb_temp_14 = Cast(c2fb_c_int, rtreeValueInt32(arg2[Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 4ULL)))]))
                (*c2fb_temp_13) = c2fb_temp_14
                If (-Cast(c2fb_c_int, ((local2.aCoord(local4).i > local2.aCoord(Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))).i)))) Then
                    c2fb_temp_15 = Cast(c2fb_c_int, rtreeConstraintError(local0, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))))
                    local1 = c2fb_temp_15
                    Goto c2fb_label_0
                End If
            c2fb_flow_3:
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 2ULL))))
                local4 = c2fb_temp_10
            Wend
            c2fb_flow_2:
        End If
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg2[Cast(c2fb_c_int, 2ULL)]) <> Cast(c2fb_c_int, 5ULL))))) Then
            c2fb_temp_16 = CPtr(c2fb_int64 Ptr, @(local2.iRowid))
            c2fb_temp_17 = Cast(c2fb_int64, c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, 2ULL)]))
            (*c2fb_temp_16) = c2fb_temp_17
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg2[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 5ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, &O0ULL)]) <> local2.iRowid)))) <> 0))))) Then
                ' C automatic storage declaration
                sqlite3_bind_int64(CPtr(Any Ptr, local0->pReadRowid), Cast(c2fb_c_int, 1ULL), local2.iRowid)
                c2fb_temp_18 = Cast(c2fb_c_int, sqlite3_step(CPtr(Any Ptr, local0->pReadRowid)))
                local6 = c2fb_temp_18
                c2fb_temp_19 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, local0->pReadRowid)))
                local1 = c2fb_temp_19
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = local6)))) Then
                    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_vtab_on_conflict(local0->db) = Cast(c2fb_c_int, 5ULL))))) Then
                        c2fb_temp_20 = Cast(c2fb_c_int, rtreeDeleteRowid(local0, local2.iRowid))
                        local1 = c2fb_temp_20
                    Else
                        c2fb_temp_21 = Cast(c2fb_c_int, rtreeConstraintError(local0, Cast(c2fb_c_int, &O0ULL)))
                        local1 = c2fb_temp_21
                        Goto c2fb_label_0
                    End If
                End If
            End If
            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local3 = c2fb_temp_22
        End If
    End If
    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg2[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 5ULL))))) Then
        c2fb_temp_23 = Cast(c2fb_c_int, rtreeDeleteRowid(local0, c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, &O0ULL)])))
        local1 = c2fb_temp_23
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        local7 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_24 = Cast(c2fb_c_int, rtreeNewRowid(local0, CPtr(c2fb_int64 Ptr, @(local2.iRowid))))
            local1 = c2fb_temp_24
        End If
        c2fb_temp_25 = CPtr(c2fb_int64 Ptr, @((*arg3)))
        c2fb_temp_26 = Cast(c2fb_int64, local2.iRowid)
        (*c2fb_temp_25) = c2fb_temp_26
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_27 = Cast(c2fb_c_int, ChooseLeaf(local0, CPtr(c2fb_source_record_27 Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL), CPtr(SqliteRtreeNode Ptr Ptr, @(local7))))
            local1 = c2fb_temp_27
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_28 = Cast(c2fb_c_int, rtreeInsertCell(local0, local7, CPtr(c2fb_source_record_27 Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_28
            c2fb_temp_29 = Cast(c2fb_c_int, nodeRelease(local0, local7))
            local8 = c2fb_temp_29
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_30 = Cast(c2fb_c_int, local8)
                local1 = c2fb_temp_30
            End If
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->nAux <> 0))))) Then
            local9 = local0->pWriteAux
            ' C automatic storage declaration
            sqlite3_bind_int64(CPtr(Any Ptr, local9), Cast(c2fb_c_int, 1ULL), (*arg3))
            c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local10 = c2fb_temp_31
            While (-Cast(c2fb_c_int, ((local10 < Cast(c2fb_c_int, local0->nAux)))))
                c2fb_external_sqlite3_bind_value(local9, Cast(c2fb_c_int, (local10 + Cast(c2fb_c_int, 2ULL))), CPtr(Const SqliteVdbeMem Ptr, arg2[Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, local0->nDim2) + Cast(c2fb_c_int, 3ULL))) + local10))]))
            c2fb_flow_5:
                c2fb_temp_32 = local10
                local10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_32 + 1)))
            Wend
            c2fb_flow_4:
            sqlite3_step(CPtr(Any Ptr, local9))
            c2fb_temp_33 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, local9)))
            local1 = c2fb_temp_33
        End If
    End If
    c2fb_label_0:
    rtreeRelease(local0)
    Return local1
End Function
Private Function rtreeBeginTransaction CDecl Alias "rtreeBeginTransaction" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(UByte Ptr, @(local0->inWrTrans))
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rtreeEndTransaction CDecl Alias "rtreeEndTransaction" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0)
    c2fb_temp_0 = CPtr(UByte Ptr, @(local0->inWrTrans))
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    nodeBlobReset(local0)
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rtreeRollback CDecl Alias "rtreeRollback" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Return rtreeEndTransaction(arg0)
End Function
Private Function rtreeRename CDecl Alias "rtreeRename" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0)
    local1 = Cast(c2fb_c_int, 7ULL)
    local2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"ALTER TABLE %Q.'%q_node'   RENAME TO \034%w_node\034;ALTER TABLE %Q.'%q_parent' RENAME TO \034%w_parent\034;ALTER TABLE %Q.'%q_rowid'  RENAME TO \034%w_rowid\034;"), local0->zDb, local0->zName, arg1, local0->zDb, local0->zName, arg1, local0->zDb, local0->zName, arg1))
    If local2 Then
        nodeBlobReset(local0)
        c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_exec(CPtr(Any Ptr, local0->db), CPtr(Const ZString Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_0
        sqlite3_free(CPtr(Any Ptr, local2))
    End If
    Return local1
End Function
Private Function rtreeSavepoint CDecl Alias "rtreeSavepoint" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As UByte
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0)
    local1 = local0->inWrTrans
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(UByte Ptr, @(local0->inWrTrans))
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    nodeBlobReset(local0)
    c2fb_temp_2 = CPtr(UByte Ptr, @(local0->inWrTrans))
    c2fb_temp_3 = Cast(UByte, local1)
    (*c2fb_temp_2) = c2fb_temp_3
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rtreeQueryStat1 CDecl Alias "rtreeQueryStat1" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_23 Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Const ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As SqliteVdbe Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_int64 Ptr
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_int64 Ptr
    Dim c2fb_temp_9 As c2fb_int64

    local0 = StrPtr(!"SELECT stat FROM %Q.sqlite_stat1 WHERE tbl = '%q_rowid'")
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, 100ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_table_column_metadata(arg0, CPtr(Const ZString Ptr, arg1->zDb), StrPtr(!"sqlite_stat1"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
    local3 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(c2fb_int64 Ptr, @(arg1->nRowEst))
        c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_c_int, 1048576ULL))
        (*c2fb_temp_1) = c2fb_temp_2
        Return IIf((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 1ULL))))), Cast(c2fb_c_int, &O0ULL), local3)
    End If
    c2fb_temp_3 = CPtr(ZString Ptr, sqlite3_mprintf(local0, arg1->zDb, arg1->zName))
    local1 = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local3 = c2fb_temp_4
    Else
        c2fb_temp_5 = Cast(c2fb_c_int, sqlite3_prepare_v2(CPtr(Any Ptr, arg0), CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Any Ptr Ptr, CPtr(SqliteVdbe Ptr Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL)))
        local3 = c2fb_temp_5
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((sqlite3_step(CPtr(Any Ptr, local2)) = Cast(c2fb_c_int, 100ULL))))) Then
                c2fb_temp_6 = Cast(c2fb_int64, sqlite3_column_int64(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL)))
                local4 = c2fb_temp_6
            End If
            c2fb_temp_7 = Cast(c2fb_c_int, sqlite3_finalize(CPtr(Any Ptr, local2)))
            local3 = c2fb_temp_7
        End If
        sqlite3_free(CPtr(Any Ptr, local1))
    End If
    c2fb_temp_8 = CPtr(c2fb_int64 Ptr, @(arg1->nRowEst))
    c2fb_temp_9 = Cast(c2fb_int64, (IIf((-Cast(c2fb_c_int, (((local4) < Cast(c2fb_int64, (Cast(c2fb_c_int, 100ULL))))))), Cast(c2fb_int64, (Cast(c2fb_c_int, 100ULL))), (local4))))
    (*c2fb_temp_8) = c2fb_temp_9
    Return local3
End Function
Private Function rtreeShadowName CDecl Alias "rtreeShadowName" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Static local0(0 To 2) As Const ZString Ptr = {Cast(Const ZString Ptr, StrPtr(!"node")), Cast(Const ZString Ptr, StrPtr(!"parent")), Cast(Const ZString Ptr, StrPtr(!"rowid"))}
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint

    ' C static array storage
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((Cast(c2fb_uint64, local1) < Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (3ULL * SizeOf(Const ZString Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Const ZString Ptr)))))))))
        If (-Cast(c2fb_c_int, ((sqlite3_stricmp(arg0, local0(local1)) = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rtreeSqlInit CDecl Alias "rtreeSqlInit" (ByVal arg0 As c2fb_source_record_23 Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Static local1(0 To 7) As Const ZString Ptr = {Cast(Const ZString Ptr, StrPtr(!"INSERT OR REPLACE INTO '%q'.'%q_node' VALUES(?1, ?2)")), Cast(Const ZString Ptr, StrPtr(!"DELETE FROM '%q'.'%q_node' WHERE nodeno = ?1")), Cast(Const ZString Ptr, StrPtr(!"SELECT nodeno FROM '%q'.'%q_rowid' WHERE rowid = ?1")), Cast(Const ZString Ptr, StrPtr(!"INSERT OR REPLACE INTO '%q'.'%q_rowid' VALUES(?1, ?2)")), Cast(Const ZString Ptr, StrPtr(!"DELETE FROM '%q'.'%q_rowid' WHERE rowid = ?1")), Cast(Const ZString Ptr, StrPtr(!"SELECT parentnode FROM '%q'.'%q_parent' WHERE nodeno = ?1")), Cast(Const ZString Ptr, StrPtr(!"INSERT OR REPLACE INTO '%q'.'%q_parent' VALUES(?1, ?2)")), Cast(Const ZString Ptr, StrPtr(!"DELETE FROM '%q'.'%q_parent' WHERE nodeno = ?1"))}
    Dim local2(0 To 7) As SqliteVdbe Ptr Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As sqlite3 Ptr Ptr
    Dim c2fb_temp_1 As sqlite3 Ptr
    Dim local5 As ZString Ptr
    Dim local6 As sqlite3_str Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As SqliteVdbe Ptr Ptr Ptr
    Dim c2fb_temp_7 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_8 As SqliteVdbe Ptr Ptr Ptr
    Dim c2fb_temp_9 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_10 As SqliteVdbe Ptr Ptr Ptr
    Dim c2fb_temp_11 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_12 As SqliteVdbe Ptr Ptr Ptr
    Dim c2fb_temp_13 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_14 As SqliteVdbe Ptr Ptr Ptr
    Dim c2fb_temp_15 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_16 As SqliteVdbe Ptr Ptr Ptr
    Dim c2fb_temp_17 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_18 As SqliteVdbe Ptr Ptr Ptr
    Dim c2fb_temp_19 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_20 As SqliteVdbe Ptr Ptr Ptr
    Dim c2fb_temp_21 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim local8 As ZString Ptr
    Dim local9 As Const ZString Ptr
    Dim c2fb_temp_25 As Const ZString Ptr
    Dim c2fb_temp_26 As Const ZString Ptr
    Dim c2fb_temp_27 As ZString Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As ZString Ptr Ptr
    Dim c2fb_temp_31 As ZString Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim local10 As sqlite3_str Ptr
    Dim local11 As c2fb_c_int
    Dim local12 As ZString Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As ZString Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C static array storage
    ' C automatic array storage
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, (Cast(c2fb_c_int, &H01ULL) Or Cast(c2fb_c_int, &H04ULL)))
    c2fb_temp_0 = CPtr(sqlite3 Ptr Ptr, @(arg0->db))
    c2fb_temp_1 = arg1
    (*c2fb_temp_0) = c2fb_temp_1
    If arg4 Then
        ' C automatic storage declaration
        local6 = CPtr(sqlite3_str Ptr, c2fb_external_sqlite3_str_new(arg1))
        ' C automatic storage declaration
        c2fb_external_sqlite3_str_appendf(local6, StrPtr(!"CREATE TABLE \034%w\034.\034%w_rowid\034(rowid INTEGER PRIMARY KEY,nodeno"), arg2, arg3)
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local7 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_int, arg0->nAux)))))
            c2fb_external_sqlite3_str_appendf(local6, StrPtr(!",a%d"), local7)
        c2fb_flow_1:
            c2fb_temp_3 = local7
            local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_str_appendf(local6, StrPtr(!");CREATE TABLE \034%w\034.\034%w_node\034(nodeno INTEGER PRIMARY KEY,data);"), arg2, arg3)
        c2fb_external_sqlite3_str_appendf(local6, StrPtr(!"CREATE TABLE \034%w\034.\034%w_parent\034(nodeno INTEGER PRIMARY KEY,parentnode);"), arg2, arg3)
        c2fb_external_sqlite3_str_appendf(local6, StrPtr(!"INSERT INTO \034%w\034.\034%w_node\034VALUES(1,zeroblob(%d))"), arg2, arg3, arg0->iNodeSize)
        c2fb_temp_4 = CPtr(ZString Ptr, c2fb_external_sqlite3_str_finish(local6))
        local5 = c2fb_temp_4
        If (-Cast(c2fb_c_int, (local5 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_5 = Cast(c2fb_c_int, sqlite3_exec(CPtr(Any Ptr, arg1), CPtr(Const ZString Ptr, local5), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_5
        sqlite3_free(CPtr(Any Ptr, local5))
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local0
        End If
    End If
    c2fb_temp_6 = CPtr(SqliteVdbe Ptr Ptr Ptr, @(local2(Cast(c2fb_c_int, &O0ULL))))
    c2fb_temp_7 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pWriteNode))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(SqliteVdbe Ptr Ptr Ptr, @(local2(Cast(c2fb_c_int, 1ULL))))
    c2fb_temp_9 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pDeleteNode))
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(SqliteVdbe Ptr Ptr Ptr, @(local2(Cast(c2fb_c_int, 2ULL))))
    c2fb_temp_11 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pReadRowid))
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(SqliteVdbe Ptr Ptr Ptr, @(local2(Cast(c2fb_c_int, 3ULL))))
    c2fb_temp_13 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pWriteRowid))
    (*c2fb_temp_12) = c2fb_temp_13
    c2fb_temp_14 = CPtr(SqliteVdbe Ptr Ptr Ptr, @(local2(Cast(c2fb_c_int, 4ULL))))
    c2fb_temp_15 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pDeleteRowid))
    (*c2fb_temp_14) = c2fb_temp_15
    c2fb_temp_16 = CPtr(SqliteVdbe Ptr Ptr Ptr, @(local2(Cast(c2fb_c_int, 5ULL))))
    c2fb_temp_17 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pReadParent))
    (*c2fb_temp_16) = c2fb_temp_17
    c2fb_temp_18 = CPtr(SqliteVdbe Ptr Ptr Ptr, @(local2(Cast(c2fb_c_int, 6ULL))))
    c2fb_temp_19 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pWriteParent))
    (*c2fb_temp_18) = c2fb_temp_19
    c2fb_temp_20 = CPtr(SqliteVdbe Ptr Ptr Ptr, @(local2(Cast(c2fb_c_int, 7ULL))))
    c2fb_temp_21 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pDeleteParent))
    (*c2fb_temp_20) = c2fb_temp_21
    c2fb_temp_22 = Cast(c2fb_c_int, rtreeQueryStat1(arg1, arg0))
    local0 = c2fb_temp_22
    c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_23
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_int, 8ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->nAux) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_25 = local1(local3)
            local9 = c2fb_temp_25
        Else
            c2fb_temp_26 = StrPtr(!"INSERT INTO\034%w\034.\034%w_rowid\034(rowid,nodeno)VALUES(?1,?2)ON CONFLICT(rowid)DO UPDATE SET nodeno=excluded.nodeno")
            local9 = c2fb_temp_26
        End If
        c2fb_temp_27 = CPtr(ZString Ptr, sqlite3_mprintf(local9, arg2, arg3))
        local8 = c2fb_temp_27
        If local8 Then
            c2fb_temp_28 = Cast(c2fb_c_int, sqlite3_prepare_v3(CPtr(Any Ptr, arg1), CPtr(Const ZString Ptr, local8), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), local4, CPtr(Any Ptr Ptr, local2(local3)), Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_28
        Else
            c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_29
        End If
        sqlite3_free(CPtr(Any Ptr, local8))
    c2fb_flow_3:
        c2fb_temp_24 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_24 + 1)))
    Wend
    c2fb_flow_2:
    If (-Cast(c2fb_c_int, (((arg0->nAux <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, 7ULL))))) <> 0))))) Then
        c2fb_temp_30 = CPtr(ZString Ptr Ptr, @(arg0->zReadAuxSql))
        c2fb_temp_31 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT * FROM \034%w\034.\034%w_rowid\034 WHERE rowid=?1"), arg2, arg3))
        (*c2fb_temp_30) = c2fb_temp_31
        If (-Cast(c2fb_c_int, ((arg0->zReadAuxSql = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_32
        Else
            local10 = CPtr(sqlite3_str Ptr, c2fb_external_sqlite3_str_new(arg1))
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_external_sqlite3_str_appendf(local10, StrPtr(!"UPDATE \034%w\034.\034%w_rowid\034SET "), arg2, arg3)
            c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local11 = c2fb_temp_33
            While (-Cast(c2fb_c_int, ((local11 < Cast(c2fb_c_int, arg0->nAux)))))
                If local11 Then
                    c2fb_external_sqlite3_str_append(local10, StrPtr(!","), Cast(c2fb_c_int, 1ULL))
                End If
                c2fb_external_sqlite3_str_appendf(local10, StrPtr(!"a%d=?%d"), local11, Cast(c2fb_c_int, (local11 + Cast(c2fb_c_int, 2ULL))))
            c2fb_flow_5:
                c2fb_temp_34 = local11
                local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_34 + 1)))
            Wend
            c2fb_flow_4:
            c2fb_external_sqlite3_str_appendf(local10, StrPtr(!" WHERE rowid=?1"))
            c2fb_temp_35 = CPtr(ZString Ptr, c2fb_external_sqlite3_str_finish(local10))
            local12 = c2fb_temp_35
            If (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_36 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_36
            Else
                c2fb_temp_37 = Cast(c2fb_c_int, sqlite3_prepare_v3(CPtr(Any Ptr, arg1), CPtr(Const ZString Ptr, local12), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), local4, CPtr(Any Ptr Ptr, CPtr(SqliteVdbe Ptr Ptr, @(arg0->pWriteAux))), Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_37
                sqlite3_free(CPtr(Any Ptr, local12))
            End If
        End If
    End If
    Return local0
End Function
Private Function getIntFromStmt CDecl Alias "getIntFromStmt" ( _
    ByVal arg0 As sqlite3 Ptr, _
    ByVal arg1 As Const ZString Ptr, _
    ByVal arg2 As c2fb_c_int Ptr, _
    ByVal pRowFound As c2fb_c_int Ptr _
) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteVdbe Ptr
    Dim stepResult As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, 7ULL)
    If pRowFound <> 0 Then pRowFound[0] = 0
    If arg1 Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_prepare_v2(CPtr(Any Ptr, arg0), arg1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Any Ptr Ptr, CPtr(SqliteVdbe Ptr Ptr, @(local1))), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            stepResult = sqlite3_step(CPtr(Any Ptr, local1))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = stepResult)))) Then
                If pRowFound <> 0 Then pRowFound[0] = 1
                c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_2 = Cast(c2fb_c_int, sqlite3_column_int(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_1) = c2fb_temp_2
            End If
            c2fb_temp_3 = Cast(c2fb_c_int, sqlite3_finalize(CPtr(Any Ptr, local1)))
            If stepResult <> 100 AndAlso stepResult <> 101 Then
                local0 = stepResult
            Else
                local0 = c2fb_temp_3
            End If
        End If
    End If
    Return local0
End Function
Private Function getNodeSize CDecl Alias "getNodeSize" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_23 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim rootRowFound As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As ZString Ptr Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As ZString Ptr Ptr
    Dim c2fb_temp_14 As ZString Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    If arg2 Then
        local2 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"PRAGMA %Q.page_size"), arg1->zDb))
        local1 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, getIntFromStmt(arg0, CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(local2)), Cast(c2fb_c_int Ptr, 0)))
        local0 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg1->iNodeSize))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 - Cast(c2fb_c_int, 64ULL))))
            (*c2fb_temp_2) = c2fb_temp_3
            If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, arg1->nBytesPerCell) * Cast(c2fb_c_int, 51ULL)))))) < arg1->iNodeSize)))) Then
                c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg1->iNodeSize))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, arg1->nBytesPerCell) * Cast(c2fb_c_int, 51ULL))))))
                (*c2fb_temp_4) = c2fb_temp_5
            End If
        Else
            c2fb_temp_6 = CPtr(ZString Ptr Ptr, @((*arg3)))
            c2fb_temp_7 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(arg0))))
            (*c2fb_temp_6) = c2fb_temp_7
        End If
    Else
        c2fb_temp_8 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT length(data) FROM '%q'.'%q_node' WHERE nodeno = 1"), arg1->zDb, arg1->zName))
        local1 = c2fb_temp_8
        rootRowFound = 0
        arg1->iNodeSize = 0
        c2fb_temp_9 = Cast(c2fb_c_int, getIntFromStmt(arg0, CPtr(Const ZString Ptr, local1), CPtr(c2fb_c_int Ptr, @(arg1->iNodeSize)), CPtr(c2fb_c_int Ptr, @(rootRowFound))))
        local0 = c2fb_temp_9
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_10 = CPtr(ZString Ptr Ptr, @((*arg3)))
            c2fb_temp_11 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(arg0))))
            (*c2fb_temp_10) = c2fb_temp_11
        ElseIf rootRowFound = 0 Then
            local0 = SQLITE_CORRUPT
            If arg3 <> 0 Then _
                arg3[0] = sqlite3_mprintf( _
                    StrPtr(!"%s"), StrPtr(!"database disk image is malformed"))
        Else
            If (-Cast(c2fb_c_int, ((arg1->iNodeSize < (Cast(c2fb_c_int, (Cast(c2fb_c_int, 512ULL) - Cast(c2fb_c_int, 64ULL)))))))) Then
                c2fb_temp_12 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                local0 = c2fb_temp_12
                ' empty C statement
                c2fb_temp_13 = CPtr(ZString Ptr Ptr, @((*arg3)))
                c2fb_temp_14 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"undersize RTree blobs in \034%q_node\034"), arg1->zName))
                (*c2fb_temp_13) = c2fb_temp_14
            End If
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local1))
    Return local0
End Function
Private Function rtreeTokenLength CDecl Alias "rtreeTokenLength" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    Return sqlite3GetToken(CPtr(Const UByte Ptr, arg0), CPtr(c2fb_c_int Ptr, @(local0)))
End Function
' c2fb skipped rtreeInit: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: rtreeInit: assignment parser stopped at byte 36 (pRtree->base.pModule = &rtreeModule):
Private Sub rtreenode CDecl Alias "rtreenode" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeNode
    Dim local1 As c2fb_source_record_23
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As sqlite3_str Ptr
    Dim local6 As c2fb_int64
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As UByte
    Dim c2fb_temp_9 As UByte Ptr Ptr
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As sqlite3_str Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local7 As c2fb_source_record_27
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteRtreeNode Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteRtreeNode))))
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_23 Ptr, @(local1))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_23))))
    c2fb_temp_2 = Cast(c2fb_int64, c2fb_external_sqlite3_value_int64(arg2[Cast(c2fb_c_int, &O0ULL)]))
    local6 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 < Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local6 > Cast(c2fb_int64, Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
        Return
    End If
    c2fb_temp_3 = CPtr(UByte Ptr, @(local1.nDim))
    c2fb_temp_4 = Cast(UByte, Cast(UByte, local6))
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(UByte Ptr, @(local1.nDim2))
    c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, local1.nDim) * Cast(c2fb_c_int, 2ULL))))
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(UByte Ptr, @(local1.nBytesPerCell))
    c2fb_temp_8 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) * Cast(c2fb_c_int, local1.nDim))))))
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(UByte Ptr Ptr, @(local0.zData))
    c2fb_temp_10 = CPtr(UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob(arg2[Cast(c2fb_c_int, 1ULL)])))
    (*c2fb_temp_9) = c2fb_temp_10
    If (-Cast(c2fb_c_int, ((local0.zData = Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes(arg2[Cast(c2fb_c_int, 1ULL)]))
    local3 = c2fb_temp_11
    If (-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_int, 4ULL))))) Then
        Return
    End If
    If (-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (readInt16(CPtr(UByte Ptr, @((CPtr(SqliteRtreeNode Ptr, @(local0)))->zData[Cast(c2fb_c_int, 2ULL)]))) * Cast(c2fb_c_int, local1.nBytesPerCell))))))))) Then
        Return
    End If
    c2fb_temp_12 = CPtr(sqlite3_str Ptr, c2fb_external_sqlite3_str_new(Cast(c2fb_c_int, &O0ULL)))
    local5 = c2fb_temp_12
    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_13
    While (-Cast(c2fb_c_int, ((local2 < readInt16(CPtr(UByte Ptr, @((CPtr(SqliteRtreeNode Ptr, @(local0)))->zData[Cast(c2fb_c_int, 2ULL)])))))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        nodeGetCell(CPtr(c2fb_source_record_23 Ptr, @(local1)), CPtr(SqliteRtreeNode Ptr, @(local0)), local2, CPtr(c2fb_source_record_27 Ptr, @(local7)))
        If (-Cast(c2fb_c_int, ((local2 > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_str_append(local5, StrPtr(!" "), Cast(c2fb_c_int, 1ULL))
        End If
        c2fb_external_sqlite3_str_appendf(local5, StrPtr(!"{%lld"), local7.iRowid)
        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local8 = c2fb_temp_15
        While (-Cast(c2fb_c_int, ((local8 < Cast(c2fb_c_int, local1.nDim2)))))
            c2fb_external_sqlite3_str_appendf(local5, StrPtr(!" %g"), __c2fb_double_value(Cast(Double, local7.aCoord(local8).f)))
        c2fb_flow_3:
            c2fb_temp_16 = local8
            local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_external_sqlite3_str_append(local5, StrPtr(!"}"), Cast(c2fb_c_int, 1ULL))
    c2fb_flow_1:
        c2fb_temp_14 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3_str_errcode(local5))
    local4 = c2fb_temp_17
    sqlite3_result_error_code(CPtr(Any Ptr, arg0), local4)
    sqlite3_result_text(CPtr(Any Ptr, arg0), CPtr(Const ZString Ptr, CPtr(ZString Ptr, c2fb_external_sqlite3_str_finish(local5))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), ProcPtr(sqlite3_free))
End Sub
Private Sub rtreedepth CDecl Alias "rtreedepth" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As UByte Ptr

    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type(arg2[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_bytes(arg2[Cast(c2fb_c_int, &O0ULL)]) < Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
        sqlite3_result_error(CPtr(Any Ptr, arg0), StrPtr(!"Invalid argument to rtreedepth()"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    Else
        local0 = CPtr(UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob(arg2[Cast(c2fb_c_int, &O0ULL)])))
        If local0 Then
            sqlite3_result_int(CPtr(Any Ptr, arg0), readInt16(local0))
        Else
            sqlite3_result_error_nomem(CPtr(Any Ptr, arg0))
        End If
    End If
End Sub
Private Sub rtreeCheckReset CDecl Alias "rtreeCheckReset" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As SqliteVdbe Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = sqlite3_reset(CPtr(Any Ptr, arg1))
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->rc))
        c2fb_temp_1 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_0) = c2fb_temp_1
    End If
End Sub
Private Function rtreeCheckPrepare CDecl Alias "rtreeCheckPrepare" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Const ZString Ptr, ...) As SqliteVdbe Ptr
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Cva_List
    Dim local1 As ZString Ptr
    Dim local2 As SqliteVdbe Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    Cva_Start(local0, arg1)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local0))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @(arg0->rc))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_1) = c2fb_temp_2
        Else
            c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg0->rc))
            c2fb_temp_4 = Cast(c2fb_c_int, sqlite3_prepare_v2(CPtr(Any Ptr, arg0->db), CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Any Ptr Ptr, CPtr(SqliteVdbe Ptr Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_3) = c2fb_temp_4
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local1))
    Cva_End(local0)
    Return local2
End Function
Private Sub rtreeCheckAppendMsg CDecl Alias "rtreeCheckAppendMsg" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Const ZString Ptr, ...)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As Cva_List
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    ' C automatic storage declaration
    Cva_Start(local0, arg1)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->nErr < Cast(c2fb_c_int, 100ULL))))) <> 0))))) Then
        local1 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local0))
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->rc))
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_0) = c2fb_temp_1
        Else
            c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg0->zReport))
            c2fb_temp_3 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%z%s%z"), arg0->zReport, (IIf(arg0->zReport, StrPtr(!"\010"), StrPtr(!""))), local1))
            (*c2fb_temp_2) = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((arg0->zReport = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->rc))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_4) = c2fb_temp_5
            End If
        End If
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg0->nErr))
        c2fb_temp_7 = (*c2fb_temp_6)
        (*c2fb_temp_6) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
    End If
    Cva_End(local0)
End Sub
Private Function rtreeCheckGetNode CDecl Alias "rtreeCheckGetNode" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int Ptr) As UByte Ptr
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As UByte Ptr
    Dim c2fb_temp_0 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_1 As SqliteVdbe Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As Const UByte Ptr
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim stepResult As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->pGetNode = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->pGetNode))
        c2fb_temp_1 = CPtr(SqliteVdbe Ptr, rtreeCheckPrepare(arg0, StrPtr(!"SELECT data FROM %Q.'%q_node' WHERE nodeno=?"), arg0->zDb, arg0->zTab))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_bind_int64(CPtr(Any Ptr, arg0->pGetNode), Cast(c2fb_c_int, 1ULL), arg1)
        stepResult = sqlite3_step(CPtr(Any Ptr, arg0->pGetNode))
        If (-Cast(c2fb_c_int, ((stepResult = Cast(c2fb_c_int, 100ULL))))) Then
            local1 = sqlite3_column_bytes(CPtr(Any Ptr, arg0->pGetNode), Cast(c2fb_c_int, &O0ULL))
            local2 = CPtr(Const UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob(arg0->pGetNode, Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_2 = CPtr(UByte Ptr, CPtr(Any Ptr, sqlite3_malloc64(local1)))
            local0 = c2fb_temp_2
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @(arg0->rc))
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_3) = c2fb_temp_4
            Else
                c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0), CPtr(Const Any Ptr, local2), local1))
                c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_7 = Cast(c2fb_c_int, local1)
                (*c2fb_temp_6) = c2fb_temp_7
            End If
        End If
        rtreeCheckReset(arg0, arg0->pGetNode)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            rtreeCheckAppendMsg(arg0, StrPtr(!"Node %lld missing from database"), arg1)
        End If
    End If
    Return local0
End Function
Private Sub rtreeCheckMapping CDecl Alias "rtreeCheckMapping" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64, ByVal arg3 As c2fb_int64)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteVdbe Ptr
    Dim local2(0 To 1) As Const ZString Ptr
    Dim c2fb_temp_0 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_1 As SqliteVdbe Ptr
    Dim c2fb_temp_2 As SqliteVdbe Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_int64

    ' C automatic storage declaration
    ' C automatic storage declaration
    Erase local2
    local2(0) = StrPtr(!"SELECT parentnode FROM %Q.'%q_parent' WHERE nodeno=?1")
    local2(1) = StrPtr(!"SELECT nodeno FROM %Q.'%q_rowid' WHERE rowid=?1")
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->aCheckMapping(arg1) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(SqliteVdbe Ptr Ptr, @(arg0->aCheckMapping(arg1)))
        c2fb_temp_1 = CPtr(SqliteVdbe Ptr, rtreeCheckPrepare(arg0, local2(arg1), arg0->zDb, arg0->zTab))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    c2fb_temp_2 = arg0->aCheckMapping(arg1)
    local1 = c2fb_temp_2
    sqlite3_bind_int64(CPtr(Any Ptr, local1), Cast(c2fb_c_int, 1ULL), arg2)
    c2fb_temp_3 = Cast(c2fb_c_int, sqlite3_step(CPtr(Any Ptr, local1)))
    local0 = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 101ULL))))) Then
        rtreeCheckAppendMsg(arg0, StrPtr(!"Mapping (%lld -> %lld) missing from %s table"), arg2, arg3, (IIf(arg1, StrPtr(!"%_rowid"), StrPtr(!"%_parent"))))
    Else
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 100ULL))))) Then
            local3 = sqlite3_column_int64(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL))
            If (-Cast(c2fb_c_int, ((local3 <> arg3)))) Then
                rtreeCheckAppendMsg(arg0, StrPtr(!"Found (%lld -> %lld) in %s table, expected (%lld -> %lld)"), arg2, local3, (IIf(arg1, StrPtr(!"%_rowid"), StrPtr(!"%_parent"))), arg2, arg3)
            End If
        End If
    End If
    rtreeCheckReset(arg0, local1)
End Sub
Private Sub rtreeCheckCellCoord CDecl Alias "rtreeCheckCellCoord" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As UByte Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_26
    Dim local1 As c2fb_source_record_26
    Dim local2 As c2fb_source_record_26
    Dim local3 As c2fb_source_record_26
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local4 < arg0->nDim))))
        readCoord(CPtr(UByte Ptr, @(arg3[Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * Cast(c2fb_c_int, 2ULL))) * local4))])), CPtr(c2fb_source_record_26 Ptr, @(local0)))
        readCoord(CPtr(UByte Ptr, @(arg3[Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) * local4)) + Cast(c2fb_c_int, 1ULL))))))])), CPtr(c2fb_source_record_26 Ptr, @(local1)))
        If IIf(arg0->bInt, (-Cast(c2fb_c_int, ((local0.i > local1.i)))), (-Cast(c2fb_c_int, ((local0.f > local1.f))))) Then
            rtreeCheckAppendMsg(arg0, StrPtr(!"Dimension %d of cell %d on node %lld is corrupt"), local4, arg2, arg1)
        End If
        If arg4 Then
            readCoord(CPtr(UByte Ptr, @(arg4[Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * Cast(c2fb_c_int, 2ULL))) * local4))])), CPtr(c2fb_source_record_26 Ptr, @(local2)))
            readCoord(CPtr(UByte Ptr, @(arg4[Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) * (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) * local4)) + Cast(c2fb_c_int, 1ULL))))))])), CPtr(c2fb_source_record_26 Ptr, @(local3)))
            If (-Cast(c2fb_c_int, ((((IIf(arg0->bInt, (-Cast(c2fb_c_int, ((local0.i < local2.i)))), (-Cast(c2fb_c_int, ((local0.f < local2.f)))))) <> 0) OrElse ((IIf(arg0->bInt, (-Cast(c2fb_c_int, ((local1.i > local3.i)))), (-Cast(c2fb_c_int, ((local1.f > local3.f)))))) <> 0))))) Then
                rtreeCheckAppendMsg(arg0, StrPtr(!"Dimension %d of cell %d on node %lld is corrupt relative to parent"), local4, arg2, arg1)
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
End Sub
Private Sub rtreeCheckNode CDecl Alias "rtreeCheckNode" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_int64)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As UByte Ptr
    Dim local5 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(UByte Ptr, rtreeCheckGetNode(arg0, arg3, CPtr(c2fb_c_int Ptr, @(local1))))
    local0 = c2fb_temp_0
    If local0 Then
        If (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, 4ULL))))) Then
            rtreeCheckAppendMsg(arg0, StrPtr(!"Node %lld is too small (%d bytes)"), arg3, local1)
        Else
            ' C automatic storage declaration
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_1 = Cast(c2fb_c_int, readInt16(local0))
                arg1 = c2fb_temp_1
                If (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, 40ULL))))) Then
                    rtreeCheckAppendMsg(arg0, StrPtr(!"Rtree depth out of range (%d)"), arg1)
                    sqlite3_free(CPtr(Any Ptr, local0))
                    Return
                End If
            End If
            c2fb_temp_2 = Cast(c2fb_c_int, readInt16(CPtr(UByte Ptr, @(local0[Cast(c2fb_c_int, 2ULL)]))))
            local2 = c2fb_temp_2
            If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (local2 * (Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0->nDim * Cast(c2fb_c_int, 2ULL))) * Cast(c2fb_c_int, 4ULL))))))))))) > local1)))) Then
                rtreeCheckAppendMsg(arg0, StrPtr(!"Node %lld is too small for cell count of %d (%d bytes)"), arg3, local2, local1)
            Else
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_3
                While (-Cast(c2fb_c_int, ((local3 < local2))))
                    local4 = CPtr(UByte Ptr, @(local0[Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, (local3 * (Cast(c2fb_c_int, (Cast(c2fb_c_int, 8ULL) + Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0->nDim * Cast(c2fb_c_int, 2ULL))) * Cast(c2fb_c_int, 4ULL))))))))))]))
                    local5 = readInt64(local4)
                    rtreeCheckCellCoord(arg0, arg3, local3, CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 8ULL)])), arg2)
                    If (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_c_int, &O0ULL))))) Then
                        rtreeCheckMapping(arg0, Cast(c2fb_c_int, &O0ULL), local5, arg3)
                        rtreeCheckNode(arg0, Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL))), CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 8ULL)])), local5)
                        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(arg0->nNonLeaf))
                        c2fb_temp_6 = (*c2fb_temp_5)
                        (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
                    Else
                        rtreeCheckMapping(arg0, Cast(c2fb_c_int, 1ULL), local5, arg3)
                        c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(arg0->nLeaf))
                        c2fb_temp_8 = (*c2fb_temp_7)
                        (*c2fb_temp_7) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
                    End If
                c2fb_flow_1:
                    c2fb_temp_4 = local3
                    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
                Wend
                c2fb_flow_0:
            End If
        End If
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Sub rtreeCheckCount CDecl Alias "rtreeCheckCount" (ByVal arg0 As c2fb_source_record_28 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteVdbe Ptr
    Dim c2fb_temp_0 As SqliteVdbe Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(SqliteVdbe Ptr, rtreeCheckPrepare(arg0, StrPtr(!"SELECT count(*) FROM %Q.'%q%s'"), arg0->zDb, arg0->zTab, arg1))
        local0 = c2fb_temp_0
        If local0 Then
            If (-Cast(c2fb_c_int, ((sqlite3_step(CPtr(Any Ptr, local0)) = Cast(c2fb_c_int, 100ULL))))) Then
                local1 = sqlite3_column_int64(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL))
                If (-Cast(c2fb_c_int, ((local1 <> arg2)))) Then
                    rtreeCheckAppendMsg(arg0, StrPtr(!"Wrong number of entries in %%%s table - expected %lld, actual %lld"), arg1, arg2, local1)
                End If
            End If
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @(arg0->rc))
            c2fb_temp_2 = Cast(c2fb_c_int, sqlite3_finalize(CPtr(Any Ptr, local0)))
            (*c2fb_temp_1) = c2fb_temp_2
        End If
    End If
End Sub
Private Function rtreeCheckTable CDecl Alias "rtreeCheckTable" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_28
    Dim local1 As SqliteVdbe Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As sqlite3 Ptr Ptr
    Dim c2fb_temp_2 As sqlite3 Ptr
    Dim c2fb_temp_3 As Const ZString Ptr Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Const ZString Ptr Ptr
    Dim c2fb_temp_6 As Const ZString Ptr
    Dim c2fb_temp_7 As SqliteVdbe Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As SqliteVdbe Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As ZString Ptr Ptr
    Dim c2fb_temp_20 As ZString Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_28 Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_28))))
    c2fb_temp_1 = CPtr(sqlite3 Ptr Ptr, @(local0.db))
    c2fb_temp_2 = arg0
    (*c2fb_temp_1) = c2fb_temp_2
    c2fb_temp_3 = CPtr(Const ZString Ptr Ptr, @(local0.zDb))
    c2fb_temp_4 = arg1
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = CPtr(Const ZString Ptr Ptr, @(local0.zTab))
    c2fb_temp_6 = arg2
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(SqliteVdbe Ptr, rtreeCheckPrepare(CPtr(c2fb_source_record_28 Ptr, @(local0)), StrPtr(!"SELECT * FROM %Q.'%q_rowid'"), arg1, arg2))
    local1 = c2fb_temp_7
    If local1 Then
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (sqlite3_column_count(CPtr(Any Ptr, local1)) - Cast(c2fb_c_int, 2ULL))))
        local2 = c2fb_temp_8
        sqlite3_finalize(CPtr(Any Ptr, local1))
    Else
        If (-Cast(c2fb_c_int, ((local0.rc <> Cast(c2fb_c_int, 7ULL))))) Then
            c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(local0.rc))
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_9) = c2fb_temp_10
        End If
    End If
    c2fb_temp_11 = CPtr(SqliteVdbe Ptr, rtreeCheckPrepare(CPtr(c2fb_source_record_28 Ptr, @(local0)), StrPtr(!"SELECT * FROM %Q.%Q"), arg1, arg2))
    local1 = c2fb_temp_11
    If local1 Then
        ' C automatic storage declaration
        c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @(local0.nDim))
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, (sqlite3_column_count(CPtr(Any Ptr, local1)) - Cast(c2fb_c_int, 1ULL))) - local2))) \ Cast(c2fb_c_int, 2ULL))))
        (*c2fb_temp_12) = c2fb_temp_13
        If (-Cast(c2fb_c_int, ((local0.nDim < Cast(c2fb_c_int, 1ULL))))) Then
            rtreeCheckAppendMsg(CPtr(c2fb_source_record_28 Ptr, @(local0)), StrPtr(!"Schema corrupt or not an rtree"))
        Else
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = sqlite3_step(CPtr(Any Ptr, local1)))))) Then
                c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @(local0.bInt))
                c2fb_temp_15 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((sqlite3_column_type(CPtr(Any Ptr, local1), Cast(c2fb_c_int, 1ULL)) = Cast(c2fb_c_int, 1ULL)))))))
                (*c2fb_temp_14) = c2fb_temp_15
            End If
        End If
        c2fb_temp_16 = Cast(c2fb_c_int, sqlite3_finalize(CPtr(Any Ptr, local1)))
        local3 = c2fb_temp_16
        If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 11ULL))))) Then
            c2fb_temp_17 = CPtr(c2fb_c_int Ptr, @(local0.rc))
            c2fb_temp_18 = Cast(c2fb_c_int, local3)
            (*c2fb_temp_17) = c2fb_temp_18
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0.nDim >= Cast(c2fb_c_int, 1ULL))))) Then
        If (-Cast(c2fb_c_int, ((local0.rc = Cast(c2fb_c_int, &O0ULL))))) Then
            rtreeCheckNode(CPtr(c2fb_source_record_28 Ptr, @(local0)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL))
        End If
        rtreeCheckCount(CPtr(c2fb_source_record_28 Ptr, @(local0)), StrPtr(!"_rowid"), local0.nLeaf)
        rtreeCheckCount(CPtr(c2fb_source_record_28 Ptr, @(local0)), StrPtr(!"_parent"), local0.nNonLeaf)
    End If
    sqlite3_finalize(CPtr(Any Ptr, local0.pGetNode))
    sqlite3_finalize(CPtr(Any Ptr, local0.aCheckMapping(Cast(c2fb_c_int, &O0ULL))))
    sqlite3_finalize(CPtr(Any Ptr, local0.aCheckMapping(Cast(c2fb_c_int, 1ULL))))
    c2fb_temp_19 = CPtr(ZString Ptr Ptr, @((*arg3)))
    c2fb_temp_20 = local0.zReport
    (*c2fb_temp_19) = c2fb_temp_20
    Return local0.rc
End Function
Private Function rtreeIntegrity CDecl Alias "rtreeIntegrity" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_source_record_23 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_23 Ptr, arg0)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, rtreeCheckTable(local0->db, CPtr(Const ZString Ptr, local0->zDb), CPtr(Const ZString Ptr, local0->zName), arg4))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((*arg4) <> 0))))) Then
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @((*arg4)))
        c2fb_temp_2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"In RTree %s.%s:\010%z"), local0->zDb, local0->zName, (*arg4)))
        (*c2fb_temp_1) = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((((*arg4)) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local1 = c2fb_temp_3
        End If
    End If
    Return local1
End Function
Private Sub rtreecheck CDecl Alias "rtreecheck" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
        sqlite3_result_error(CPtr(Any Ptr, arg0), StrPtr(!"wrong number of arguments to function rtreecheck()"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    Else
        ' C automatic storage declaration
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, &O0ULL)])))
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_0 = local2
            local3 = c2fb_temp_0
            c2fb_temp_1 = StrPtr(!"main")
            local2 = c2fb_temp_1
        Else
            c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, 1ULL)])))
            local3 = c2fb_temp_2
        End If
        c2fb_temp_3 = Cast(c2fb_c_int, rtreeCheckTable(CPtr(sqlite3 Ptr, sqlite3_context_db_handle(CPtr(Any Ptr, arg0))), local2, local3, CPtr(ZString Ptr Ptr, @(local1))))
        local0 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            sqlite3_result_text(CPtr(Any Ptr, arg0), IIf(local1, CPtr(Const ZString Ptr, local1), StrPtr(!"ok")), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Any Ptr, (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))))
        Else
            sqlite3_result_error_code(CPtr(Any Ptr, arg0), local0)
        End If
        sqlite3_free(CPtr(Any Ptr, local1))
    End If
End Sub
' c2fb skipped sqlite3RtreeInit: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3RtreeInit: assignment parser stopped at byte 56 (rc = sqlite3_create_module_v2(db, "rtree", &rtreeModule, c, 0)): , c, 0)
Private Sub rtreeFreeCallback CDecl Alias "rtreeFreeCallback" (ByVal arg0 As Any Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeGeomCallback Ptr

    local0 = CPtr(SqliteRtreeGeomCallback Ptr, arg0)
    If CPtr(c2fb_callback_8, local0->xDestructor) Then
        CPtr(c2fb_callback_8, local0->xDestructor)(local0->pContext)
    End If
    sqlite3_free(arg0)
End Sub
Private Sub rtreeMatchArgFree CDecl Alias "rtreeMatchArgFree" (ByVal arg0 As Any Ptr)
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteRtreeMatchArg Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(SqliteRtreeMatchArg Ptr, arg0)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < local1->nParam))))
        c2fb_external_sqlite3_value_free(CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, local1->apSqlParam))[local0])
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    sqlite3_free(CPtr(Any Ptr, local1))
End Sub
' c2fb skipped geomCallback: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: geomCallback: assignment parser stopped at byte 52 (nBlob = (__builtin_offsetof (RtreeMatchArg, aParam)+(nArg)*sizeof(RtreeDValue)) + nArg*sizeof(sqlite3_value*)): +(nArg)*sizeof(RtreeDValue)) + nArg*sizeof(sqlite3_value*)
Function sqlite3_rtree_geometry_callback CDecl Alias "sqlite3_rtree_geometry_callback" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_callback_154, ByVal arg3 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeGeomCallback Ptr
    Dim c2fb_temp_0 As SqliteRtreeGeomCallback Ptr
    Dim c2fb_temp_1 As SqliteRtreeGeometryCallbackProc Ptr
    Dim c2fb_temp_2 As c2fb_callback_154
    Dim c2fb_temp_3 As SqliteRtreeQueryCallbackProc Ptr
    Dim c2fb_temp_4 As c2fb_callback_155
    Dim c2fb_temp_5 As SqliteRtreeGeometryDeleteProc Ptr
    Dim c2fb_temp_6 As c2fb_callback_8
    Dim c2fb_temp_7 As Any Ptr Ptr
    Dim c2fb_temp_8 As Any Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(SqliteRtreeGeomCallback Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(SqliteRtreeGeomCallback)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(SqliteRtreeGeometryCallbackProc Ptr, @(local0->xGeom))
    c2fb_temp_2 = arg2
    (*c2fb_temp_1) = Cast(SqliteRtreeGeometryCallbackProc, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_callback_154, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(SqliteRtreeQueryCallbackProc Ptr, @(local0->xQueryFunc))
    c2fb_temp_4 = CPtr(c2fb_callback_155, 0)
    (*c2fb_temp_3) = Cast(SqliteRtreeQueryCallbackProc, c2fb_temp_4)
    c2fb_temp_4 = CPtr(c2fb_callback_155, (*c2fb_temp_3))
    c2fb_temp_5 = CPtr(SqliteRtreeGeometryDeleteProc Ptr, @(local0->xDestructor))
    c2fb_temp_6 = CPtr(c2fb_callback_8, 0)
    (*c2fb_temp_5) = Cast(SqliteRtreeGeometryDeleteProc, c2fb_temp_6)
    c2fb_temp_6 = CPtr(c2fb_callback_8, (*c2fb_temp_5))
    c2fb_temp_7 = CPtr(Any Ptr Ptr, @(local0->pContext))
    c2fb_temp_8 = arg3
    (*c2fb_temp_7) = c2fb_temp_8
    Return c2fb_external_sqlite3_create_function_v2(arg0, arg1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 5ULL), CPtr(Any Ptr, local0), ProcPtr(geomCallback), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), ProcPtr(rtreeFreeCallback))
End Function
Function sqlite3_rtree_query_callback CDecl Alias "sqlite3_rtree_query_callback" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_callback_155, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_callback_8) As c2fb_c_int
' c2fb source-path: ext/rtree/rtree.c
    Dim local0 As SqliteRtreeGeomCallback Ptr
    Dim c2fb_temp_0 As SqliteRtreeGeomCallback Ptr
    Dim c2fb_temp_1 As SqliteRtreeGeometryCallbackProc Ptr
    Dim c2fb_temp_2 As c2fb_callback_154
    Dim c2fb_temp_3 As SqliteRtreeQueryCallbackProc Ptr
    Dim c2fb_temp_4 As c2fb_callback_155
    Dim c2fb_temp_5 As SqliteRtreeGeometryDeleteProc Ptr
    Dim c2fb_temp_6 As c2fb_callback_8
    Dim c2fb_temp_7 As Any Ptr Ptr
    Dim c2fb_temp_8 As Any Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(SqliteRtreeGeomCallback Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(SqliteRtreeGeomCallback)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        If arg4 Then
            arg4(arg3)
        End If
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(SqliteRtreeGeometryCallbackProc Ptr, @(local0->xGeom))
    c2fb_temp_2 = CPtr(c2fb_callback_154, 0)
    (*c2fb_temp_1) = Cast(SqliteRtreeGeometryCallbackProc, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_callback_154, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(SqliteRtreeQueryCallbackProc Ptr, @(local0->xQueryFunc))
    c2fb_temp_4 = arg2
    (*c2fb_temp_3) = Cast(SqliteRtreeQueryCallbackProc, c2fb_temp_4)
    c2fb_temp_4 = CPtr(c2fb_callback_155, (*c2fb_temp_3))
    c2fb_temp_5 = CPtr(SqliteRtreeGeometryDeleteProc Ptr, @(local0->xDestructor))
    c2fb_temp_6 = arg4
    (*c2fb_temp_5) = Cast(SqliteRtreeGeometryDeleteProc, c2fb_temp_6)
    c2fb_temp_6 = CPtr(c2fb_callback_8, (*c2fb_temp_5))
    c2fb_temp_7 = CPtr(Any Ptr Ptr, @(local0->pContext))
    c2fb_temp_8 = arg3
    (*c2fb_temp_7) = c2fb_temp_8
    Return c2fb_external_sqlite3_create_function_v2(arg0, arg1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 5ULL), CPtr(Any Ptr, local0), ProcPtr(geomCallback), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), ProcPtr(rtreeFreeCallback))
End Function
/'
    SQLite retains the module table pointer after sqlite3_create_module_v2()
    returns, so this callback table has static storage duration.
'/ 
Private Dim Shared As Const SqliteModuleCallbacks rtreeModule = _
    Type<SqliteModuleCallbacks>( _
        4, _
        CPtr(Any Ptr, ProcPtr(rtreeCreate)), _
        CPtr(Any Ptr, ProcPtr(rtreeConnect)), _
        CPtr(SqliteModuleBestIndexProc, ProcPtr(rtreeBestIndex)), _
        CPtr(Any Ptr, ProcPtr(rtreeDisconnect)), _
        CPtr(Any Ptr, ProcPtr(rtreeDestroy)), _
        CPtr(Any Ptr, ProcPtr(rtreeOpen)), _
        CPtr(Any Ptr, ProcPtr(rtreeClose)), _
        CPtr(Any Ptr, ProcPtr(rtreeFilter)), _
        CPtr(Any Ptr, ProcPtr(rtreeNext)), _
        CPtr(Any Ptr, ProcPtr(rtreeEof)), _
        CPtr(Any Ptr, ProcPtr(rtreeColumn)), _
        CPtr(Any Ptr, ProcPtr(rtreeRowid)), _
        CPtr(Any Ptr, ProcPtr(rtreeUpdate)), _
        CPtr(Any Ptr, ProcPtr(rtreeBeginTransaction)), _
        CPtr(Any Ptr, ProcPtr(rtreeEndTransaction)), _
        CPtr(Any Ptr, ProcPtr(rtreeEndTransaction)), _
        CPtr(Any Ptr, ProcPtr(rtreeRollback)), _
        0, _
        CPtr(Any Ptr, ProcPtr(rtreeRename)), _
        CPtr(Any Ptr, ProcPtr(rtreeSavepoint)), _
        0, _
        0, _
        CPtr(Any Ptr, ProcPtr(rtreeShadowName)), _
        CPtr(Any Ptr, ProcPtr(rtreeIntegrity)) _
    )

Declare Function sqlite3_vtab_config CDecl Alias "sqlite3_vtab_config" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal operation As c2fb_c_int, _
    ... _
) As c2fb_c_int
Declare Function sqlite3_declare_vtab CDecl Alias "sqlite3_declare_vtab" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal zSql As Const ZString Ptr _
) As c2fb_c_int
Declare Function sqlite3_create_module_v2 CDecl Alias "sqlite3_create_module_v2" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal zName As Const ZString Ptr, _
    ByVal pModule As Const SqliteModuleCallbacks Ptr, _
    ByVal pAuxiliary As Any Ptr, _
    ByVal xDestroy As Any Ptr _
) As c2fb_c_int
Declare Function sqlite3_user_data CDecl Alias "sqlite3_user_data" ( _
    ByVal pContext As Any Ptr _
) As Any Ptr
Declare Function sqlite3_value_dup CDecl Alias "sqlite3_value_dup" ( _
    ByVal pValue As Const Any Ptr _
) As Any Ptr
Declare Sub sqlite3_result_pointer CDecl Alias "sqlite3_result_pointer" ( _
    ByVal pContext As Any Ptr, _
    ByVal pPointer As Any Ptr, _
    ByVal zType As Const ZString Ptr, _
    ByVal xDestroy As Any Ptr _
)
Declare Function sqlite3Strlen30 CDecl Alias "sqlite3Strlen30" ( _
    ByVal zText As Const ZString Ptr _
) As c2fb_c_int
#if defined(SQLITE_DEBUG) AndAlso Not defined(SQLITE_RTREE_INT_ONLY)
Declare Sub rtreeRoundFunc CDecl Alias "rtreeRoundFunc" ( _
    ByVal pContext As SqliteResultContext Ptr, _
    ByVal argumentCount As c2fb_c_int, _
    ByVal aArgument As SqliteVdbeMem Ptr Ptr _
)
#endif

Private Function rtreeTokenLengthForArgument( _
    ByVal zToken As Const ZString Ptr _
) As c2fb_c_int
    If zToken = 0 Then Return 0
    Return rtreeTokenLength(zToken)
End Function

Private Function rtreeInit CDecl Alias "rtreeInit" ( _
    ByVal pDatabase As sqlite3 Ptr, _
    ByVal pAuxiliary As Any Ptr, _
    ByVal argumentCount As c2fb_c_int, _
    ByVal aArgument As Const ZString Ptr Ptr, _
    ByVal ppVtab As SqliteVtab Ptr Ptr, _
    ByVal pzError As ZString Ptr Ptr, _
    ByVal isCreate As c2fb_c_int _
) As c2fb_c_int
    Dim rc As c2fb_c_int = SQLITE_OK
    Dim pRtree As c2fb_source_record_23 Ptr = 0
    Dim pSql As sqlite3_str Ptr = 0
    Dim zSql As ZString Ptr = 0
    Dim allocationSize As sqlite3_uint64
    Dim nDatabase As c2fb_c_int
    Dim nName As c2fb_c_int
    Dim coordinateType As c2fb_c_int
    Dim argumentIndex As c2fb_c_int
    Dim errorIndex As c2fb_c_int
    Dim zArgument As Const ZString Ptr
    Dim zError As Const ZString Ptr
    Dim pTextStorage As UByte Ptr

    If CPtr(Any Ptr, ppVtab) = 0 OrElse pDatabase = 0 OrElse _
       CPtr(Any Ptr, aArgument) = 0 Then
        Return SQLITE_MISUSE
    End If
    ppVtab[0] = 0
    If pzError <> 0 Then pzError[0] = 0

    If argumentCount < 6 Then
        zError = StrPtr(!"Too few columns for an rtree table")
        If pzError <> 0 Then pzError[0] = sqlite3_mprintf(StrPtr(!"%s"), zError)
        Return SQLITE_ERROR
    ElseIf argumentCount > SQLITE3_FB_RTREE_MAX_AUX_COLUMN + 3 Then
        zError = StrPtr(!"Too many columns for an rtree table")
        If pzError <> 0 Then pzError[0] = sqlite3_mprintf(StrPtr(!"%s"), zError)
        Return SQLITE_ERROR
    End If
    If aArgument[1] = 0 OrElse aArgument[2] = 0 OrElse aArgument[3] = 0 Then
        If pzError <> 0 Then _
            pzError[0] = sqlite3_mprintf(StrPtr(!"%s"), StrPtr(!"Invalid R-tree table declaration"))
        Return SQLITE_ERROR
    End If

    If pAuxiliary <> 0 Then
        coordinateType = 1
    Else
        coordinateType = 0
    End If

    ' These settings tell the virtual-table planner which guarantees the
    ' R-tree implementation makes while evaluating constraints.
    sqlite3_vtab_config(pDatabase, SQLITE_VTAB_CONSTRAINT_SUPPORT, 1)
    sqlite3_vtab_config(pDatabase, SQLITE_VTAB_INNOCUOUS)

    nDatabase = sqlite3Strlen30(aArgument[1])
    nName = sqlite3Strlen30(aArgument[2])
    If nDatabase < 0 OrElse nName < 0 Then Return SQLITE_TOOBIG

    allocationSize = Cast(sqlite3_uint64, SizeOf(c2fb_source_record_23))
    allocationSize += Cast(sqlite3_uint64, nDatabase)
    allocationSize += Cast(sqlite3_uint64, nName) * 2ULL
    ' The trailing bytes hold two names, both terminators, and the _node suffix.
    allocationSize += 8ULL
    pRtree = CPtr(c2fb_source_record_23 Ptr, sqlite3_malloc64(allocationSize))
    If pRtree = 0 Then Return SQLITE_NOMEM
    c2fb_crt_memset(pRtree, 0, Cast(SQLITE_SIZE_T, allocationSize))

    pRtree->nBusy = 1
    pRtree->base.pModule = @rtreeModule
    pTextStorage = CPtr(UByte Ptr, pRtree) + SizeOf(c2fb_source_record_23)
    pRtree->zDb = CPtr(ZString Ptr, pTextStorage)
    pRtree->zName = CPtr(ZString Ptr, pTextStorage + nDatabase + 1)
    pRtree->zNodeName = CPtr(ZString Ptr, pTextStorage + nDatabase + nName + 2)
    pRtree->eCoordType = Cast(UByte, coordinateType)
    c2fb_crt_memcpy(pRtree->zDb, aArgument[1], Cast(SQLITE_SIZE_T, nDatabase))
    c2fb_crt_memcpy(pRtree->zName, aArgument[2], Cast(SQLITE_SIZE_T, nName))
    c2fb_crt_memcpy(pRtree->zNodeName, aArgument[2], Cast(SQLITE_SIZE_T, nName))
    c2fb_crt_memcpy( _
        CPtr(UByte Ptr, pRtree->zNodeName) + nName, _
        StrPtr(!"_node"), _
        6 _
    )

    pSql = c2fb_external_sqlite3_str_new(pDatabase)
    c2fb_external_sqlite3_str_appendf( _
        pSql, _
        StrPtr(!"CREATE TABLE x(%.*s INT"), _
        rtreeTokenLengthForArgument(aArgument[3]), _
        aArgument[3] _
    )
    argumentIndex = 4
    While argumentIndex < argumentCount
        zArgument = aArgument[argumentIndex]
        If zArgument = 0 Then
            If pzError <> 0 Then _
                pzError[0] = sqlite3_mprintf(StrPtr(!"%s"), StrPtr(!"Invalid R-tree column name"))
            rc = SQLITE_ERROR
            Exit While
        End If

        If CPtr(Const UByte Ptr, zArgument)[0] = Asc("+") Then
            pRtree->nAux += 1
            c2fb_external_sqlite3_str_appendf( _
                pSql, _
                StrPtr(!",%.*s"), _
                rtreeTokenLengthForArgument(CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, zArgument) + 1)), _
                CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, zArgument) + 1) _
            )
        ElseIf pRtree->nAux > 0 Then
            Exit While
        ElseIf coordinateType = 0 Then
            pRtree->nDim2 += 1
            c2fb_external_sqlite3_str_appendf( _
                pSql, StrPtr(!",%.*s REAL"), _
                rtreeTokenLengthForArgument(zArgument), zArgument _
            )
        Else
            pRtree->nDim2 += 1
            c2fb_external_sqlite3_str_appendf( _
                pSql, StrPtr(!",%.*s INT"), _
                rtreeTokenLengthForArgument(zArgument), zArgument _
            )
        End If
        argumentIndex += 1
    Wend
    c2fb_external_sqlite3_str_appendf(pSql, StrPtr(!");"))

    zSql = c2fb_external_sqlite3_str_finish(pSql)
    If rc = SQLITE_OK Then
        If zSql = 0 Then
            rc = SQLITE_NOMEM
        ElseIf argumentIndex < argumentCount Then
            If pzError <> 0 Then _
                pzError[0] = sqlite3_mprintf(StrPtr(!"%s"), StrPtr(!"Auxiliary rtree columns must be last"))
            rc = SQLITE_ERROR
        Else
            rc = sqlite3_declare_vtab(pDatabase, zSql)
            If rc <> SQLITE_OK AndAlso pzError <> 0 Then
                pzError[0] = sqlite3_mprintf(StrPtr(!"%s"), c2fb_external_sqlite3_errmsg(pDatabase))
            End If
        End If
    End If
    sqlite3_free(zSql)
    If rc <> SQLITE_OK Then GoTo rtreeInitFailure

    pRtree->nDim = pRtree->nDim2 \ 2
    If pRtree->nDim < 1 Then
        errorIndex = 2
    ElseIf pRtree->nDim2 > SQLITE3_FB_RTREE_MAX_DIMENSIONS * 2 Then
        errorIndex = 3
    ElseIf (pRtree->nDim2 Mod 2) <> 0 Then
        errorIndex = 1
    Else
        errorIndex = 0
    End If
    If errorIndex <> 0 Then
        Select Case errorIndex
        Case 1
            zError = StrPtr(!"Wrong number of columns for an rtree table")
        Case 2
            zError = StrPtr(!"Too few columns for an rtree table")
        Case Else
            zError = StrPtr(!"Too many columns for an rtree table")
        End Select
        If pzError <> 0 Then pzError[0] = sqlite3_mprintf(StrPtr(!"%s"), zError)
        rc = SQLITE_ERROR
        GoTo rtreeInitFailure
    End If

    ' Each cell stores an 8-byte rowid followed by 4-byte coordinates.
    pRtree->nBytesPerCell = 8 + pRtree->nDim2 * 4
    rc = getNodeSize(pDatabase, pRtree, isCreate, pzError)
    If rc <> SQLITE_OK Then GoTo rtreeInitFailure

    rc = rtreeSqlInit(pRtree, pDatabase, aArgument[1], aArgument[2], isCreate)
    If rc <> SQLITE_OK Then
        If pzError <> 0 Then _
            pzError[0] = sqlite3_mprintf(StrPtr(!"%s"), c2fb_external_sqlite3_errmsg(pDatabase))
        GoTo rtreeInitFailure
    End If

    ppVtab[0] = CPtr(SqliteVtab Ptr, pRtree)
    Return SQLITE_OK

rtreeInitFailure:
    If rc = SQLITE_OK Then rc = SQLITE_ERROR
    rtreeRelease(pRtree)
    Return rc
End Function

Function sqlite3RtreeInit CDecl Alias "sqlite3RtreeInit" ( _
    ByVal pDatabase As sqlite3 Ptr _
) As c2fb_c_int
    Dim rc As c2fb_c_int
    Dim coordinateAux As Any Ptr

    rc = c2fb_external_sqlite3_create_function_v2( _
        pDatabase, StrPtr(!"rtreenode"), 2, SQLITE_UTF8, 0, _
        CPtr(c2fb_callback_161, ProcPtr(rtreenode)), 0, 0, 0 _
    )
    If rc = SQLITE_OK Then
        rc = c2fb_external_sqlite3_create_function_v2( _
            pDatabase, StrPtr(!"rtreedepth"), 1, SQLITE_UTF8, 0, _
            CPtr(c2fb_callback_161, ProcPtr(rtreedepth)), 0, 0, 0 _
        )
    End If
    If rc = SQLITE_OK Then
        rc = c2fb_external_sqlite3_create_function_v2( _
            pDatabase, StrPtr(!"rtreecheck"), -1, SQLITE_UTF8, 0, _
            CPtr(c2fb_callback_161, ProcPtr(rtreecheck)), 0, 0, 0 _
        )
    End If

#if defined(SQLITE_DEBUG) AndAlso Not defined(SQLITE_RTREE_INT_ONLY)
    If rc = SQLITE_OK Then
        rc = c2fb_external_sqlite3_create_function_v2( _
            pDatabase, StrPtr(!"rtree_round"), 2, SQLITE_UTF8, 0, _
            CPtr(c2fb_callback_161, ProcPtr(rtreeRoundFunc)), 0, 0, 0 _
        )
    End If
#endif

    If rc = SQLITE_OK Then
#ifdef SQLITE_RTREE_INT_ONLY
        coordinateAux = CPtr(Any Ptr, 1)
#else
        coordinateAux = 0
#endif
        rc = sqlite3_create_module_v2( _
            pDatabase, StrPtr(!"rtree"), @rtreeModule, coordinateAux, 0 _
        )
    End If
    If rc = SQLITE_OK Then
        rc = sqlite3_create_module_v2( _
            pDatabase, StrPtr(!"rtree_i32"), @rtreeModule, CPtr(Any Ptr, 1), 0 _
        )
    End If
#ifdef SQLITE_ENABLE_GEOPOLY
    If rc = SQLITE_OK Then rc = sqlite3_geopoly_init(pDatabase)
#endif

    Return rc
End Function

Private Sub geomCallback CDecl Alias "geomCallback" ( _
    ByVal pContext As SqliteResultContext Ptr, _
    ByVal argumentCount As c2fb_c_int, _
    ByVal aArgument As SqliteVdbeMem Ptr Ptr _
)
    Dim pGeometry As SqliteRtreeGeomCallback Ptr
    Dim pBlob As SqliteRtreeMatchArg Ptr
    Dim pValues As SqliteRtreeDValue Ptr
    Dim pSqlValues As Any Ptr Ptr
    Dim fixedBytes As sqlite3_uint64
    Dim valueBytes As sqlite3_uint64
    Dim pointerBytes As sqlite3_uint64
    Dim allocationBytes As sqlite3_uint64
    Dim i As c2fb_c_int
    Dim failedToDuplicate As c2fb_c_int

    If pContext = 0 Then Return
    If argumentCount < 0 OrElse _
       (argumentCount > 0 AndAlso aArgument = 0) Then
        sqlite3_result_error(pContext, StrPtr(!"Invalid R-tree callback arguments"), -1)
        Return
    End If
    pGeometry = CPtr(SqliteRtreeGeomCallback Ptr, sqlite3_user_data(pContext))
    If pGeometry = 0 Then
        sqlite3_result_error(pContext, StrPtr(!"Missing R-tree callback state"), -1)
        Return
    End If

    ' The C flexible-array offset equals sizeof(the one-element FB layout)
    ' minus the placeholder element at its tail.
    fixedBytes = Cast(sqlite3_uint64, SizeOf(SqliteRtreeMatchArg)) _
        - Cast(sqlite3_uint64, SizeOf(SqliteRtreeDValue))
    valueBytes = Cast(sqlite3_uint64, argumentCount) * _
        Cast(sqlite3_uint64, SizeOf(SqliteRtreeDValue))
    pointerBytes = Cast(sqlite3_uint64, argumentCount) * _
        Cast(sqlite3_uint64, SizeOf(Any Ptr))
    allocationBytes = fixedBytes + valueBytes + pointerBytes
    If allocationBytes > &HFFFFFFFFULL Then
        sqlite3_result_error(pContext, StrPtr(!"R-tree callback arguments exceed the supported size"), -1)
        Return
    End If

    pBlob = CPtr(SqliteRtreeMatchArg Ptr, sqlite3_malloc64(allocationBytes))
    If pBlob = 0 Then
        sqlite3_result_error_nomem(pContext)
        Return
    End If
    pBlob->iSize = Cast(u32, allocationBytes)
    pBlob->cb = *pGeometry
    pBlob->nParam = argumentCount
    pValues = CPtr(SqliteRtreeDValue Ptr, @pBlob->aParam(0))
    pSqlValues = CPtr(Any Ptr Ptr, _
        CPtr(UByte Ptr, pValues) + Cast(SQLITE_SIZE_T, valueBytes))
    pBlob->apSqlParam = pSqlValues
    failedToDuplicate = 0

    For i = 0 To argumentCount - 1
        pSqlValues[i] = sqlite3_value_dup(aArgument[i])
        If pSqlValues[i] = 0 Then failedToDuplicate = 1
#ifdef SQLITE_RTREE_INT_ONLY
        pValues[i] = c2fb_external_sqlite3_value_int64(aArgument[i])
#else
        pValues[i] = c2fb_external_sqlite3_value_double(aArgument[i])
#endif
    Next

    If failedToDuplicate <> 0 Then
        sqlite3_result_error_nomem(pContext)
        rtreeMatchArgFree(pBlob)
    Else
        sqlite3_result_pointer( _
            pContext, pBlob, StrPtr(!"RtreeMatchArg"), ProcPtr(rtreeMatchArgFree) _
        )
    End If
End Sub

#ifdef SQLITE_DEBUG
#ifndef SQLITE_RTREE_INT_ONLY
Private Sub rtreeRoundFunc CDecl Alias "rtreeRoundFunc" ( _
    ByVal pContext As SqliteResultContext Ptr, _
    ByVal argumentCount As c2fb_c_int, _
    ByVal aArgument As SqliteVdbeMem Ptr Ptr _
)
    Dim rounded As Single
    If c2fb_external_sqlite3_value_int64(aArgument[1]) <> 0 Then
        rounded = rtreeValueUp(aArgument[0])
    Else
        rounded = rtreeValueDown(aArgument[0])
    End If
    sqlite3_result_double(pContext, rounded)
End Sub
#endif
#endif

#ifdef SQLITE_ENABLE_GEOPOLY
#include once "sqlite3_geopoly_body.bi"
#endif

#endif
/' end of sqlite3_bulk_rtree.bas '/
/' end of sqlite3_bulk_rtree.bas '/
