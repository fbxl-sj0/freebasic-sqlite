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
******************************************************************************
**
** Low level access to the FTS index stored in the database file. The
** routines in this file implement all read and write access to the %_data
** table. Other parts of the system access this functionality via fts5Int.h.
'/

/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_bulk_fts5_index.bas

    Purpose:

        Port FTS5 index segment storage, iteration, merging, and updates.

    Responsibilities:

        - Read and write FTS5 index pages and segment records.
        - Manage segment structures, iterators, merges, and integrity paths.
        - Preserve the C ABI used by FTS5 storage and virtual-table code.

    This file intentionally does NOT contain:

        - FTS5 query parsing, tokenization, or virtual-table registration.
        - The upstream TCL test adapter.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_index_types.bi"
#include once "sqlite3_fts5_module_types.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_api_declarations.bi"
#include once "sqlite3_api_constants.bi"
#ifndef FTS5_DETAIL_FULL
#define FTS5_DETAIL_FULL 0
#define FTS5_DETAIL_NONE 1
#define FTS5_DETAIL_COLUMNS 2
#endif
#ifndef FTS5_SEGITER_ONETERM
#define FTS5_SEGITER_ONETERM 1
#define FTS5_SEGITER_REVERSE 2
#endif
#ifndef FTS5_MAX_LEVEL
#define FTS5_MAX_LEVEL 64
#endif
Type sqlite3 As c2fb_sqlite3
Type sqlite3_file As c2fb_sqlite3_file
Type PgHdr
    nRef As Long
End Type
#ifdef SQLITE_DEBUG
' Upstream FTS5_DATA_PADDING reserves 20 bytes beyond each configured page.
Private Const FTS5_DATA_PADDING As Long = 20
#endif
Declare Function sqlite3WhereMemset CDecl Alias "memset" (ByVal pDestination As Any Ptr, ByVal byteValue As SQLITE_C_INT, ByVal byteCount As SQLITE_SIZE_T) As Any Ptr
Declare Function sqlite3WhereMemcpy CDecl Alias "memcpy" (ByVal pDestination As Any Ptr, ByVal pSource As Const Any Ptr, ByVal byteCount As SQLITE_SIZE_T) As Any Ptr
Declare Function walSystemMemcmp CDecl Alias "memcmp" (ByVal pLeft As Const Any Ptr, ByVal pRight As Const Any Ptr, ByVal nByte As SQLITE_SIZE_T) As SQLITE_C_INT

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


Type c2fb_sqlite3_destructor_type As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_348 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
Type c2fb_callback_349 As Sub CDecl(ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Type c2fb_callback_350 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Buffer Ptr)
Type c2fb_callback_351 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
Type c2fb_callback_355 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Type c2fb_callback_356 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As Const UByte Ptr, ByVal arg4 As c2fb_c_int)

Declare Function fts5IndexCorruptRowid CDecl Alias "fts5IndexCorruptRowid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function fts5IndexCorruptIter CDecl Alias "fts5IndexCorruptIter" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr) As c2fb_c_int
Declare Function fts5IndexCorruptIdx CDecl Alias "fts5IndexCorruptIdx" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Sub fts5PutU16 CDecl Alias "fts5PutU16" (ByVal arg0 As UByte Ptr, ByVal arg1 As UShort)
Declare Function fts5GetU16 CDecl Alias "fts5GetU16" (ByVal arg0 As Const UByte Ptr) As UShort
Declare Function fts5GetU64 CDecl Alias "fts5GetU64" (ByVal arg0 As UByte Ptr) As c2fb_uint64
Declare Function fts5GetU32 CDecl Alias "fts5GetU32" (ByVal arg0 As Const UByte Ptr) As c2fb_c_uint
Declare Sub fts5PutU64 CDecl Alias "fts5PutU64" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_uint64)
Declare Sub fts5PutU32 CDecl Alias "fts5PutU32" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_uint)
Declare Function fts5IdxMalloc CDecl Alias "fts5IdxMalloc" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function fts5BufferCompare CDecl Alias "fts5BufferCompare" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr) As c2fb_c_int
Declare Function fts5LeafFirstTermOff CDecl Alias "fts5LeafFirstTermOff" (ByVal arg0 As c2fb_Fts5Data Ptr) As c2fb_c_int
Declare Sub fts5IndexCloseReader CDecl Alias "fts5IndexCloseReader" (ByVal arg0 As c2fb_Fts5Index Ptr)
Declare Function fts5DataRead CDecl Alias "fts5DataRead" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Data Ptr
Declare Sub fts5DataRelease CDecl Alias "fts5DataRelease" (ByVal arg0 As c2fb_Fts5Data Ptr)
Declare Function fts5LeafRead CDecl Alias "fts5LeafRead" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Data Ptr
Declare Function fts5IndexPrepareStmt CDecl Alias "fts5IndexPrepareStmt" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg2 As ZString Ptr) As c2fb_c_int
Declare Sub fts5DataWrite CDecl Alias "fts5DataWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub fts5DataDelete CDecl Alias "fts5DataDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64)
Declare Sub fts5DataRemoveSegment CDecl Alias "fts5DataRemoveSegment" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr)
Declare Sub fts5StructureRelease CDecl Alias "fts5StructureRelease" (ByVal arg0 As c2fb_Fts5Structure Ptr)
Declare Sub fts5StructureRef CDecl Alias "fts5StructureRef" (ByVal arg0 As c2fb_Fts5Structure Ptr)
Declare Function sqlite3Fts5StructureRef CDecl Alias "sqlite3Fts5StructureRef" (ByVal arg0 As c2fb_Fts5Index Ptr) As Any Ptr
Declare Sub sqlite3Fts5StructureRelease CDecl Alias "sqlite3Fts5StructureRelease" (ByVal arg0 As Any Ptr)
Declare Function sqlite3Fts5StructureTest CDecl Alias "sqlite3Fts5StructureTest" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr) As c2fb_c_int
Declare Sub fts5StructureMakeWritable CDecl Alias "fts5StructureMakeWritable" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr)
Declare Function fts5StructureDecode CDecl Alias "fts5StructureDecode" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_Fts5Structure Ptr Ptr) As c2fb_c_int
Declare Sub fts5StructureAddLevel CDecl Alias "fts5StructureAddLevel" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr)
Declare Sub fts5StructureExtendLevel CDecl Alias "fts5StructureExtendLevel" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int)
Declare Function fts5StructureReadUncached CDecl Alias "fts5StructureReadUncached" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_Fts5Structure Ptr
Declare Function fts5IndexDataVersion CDecl Alias "fts5IndexDataVersion" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_int64
Declare Function fts5StructureRead CDecl Alias "fts5StructureRead" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_Fts5Structure Ptr
Declare Sub fts5StructureInvalidate CDecl Alias "fts5StructureInvalidate" (ByVal arg0 As c2fb_Fts5Index Ptr)
#ifdef SQLITE_DEBUG
Declare Function fts5StructureCountSegments CDecl Alias "fts5StructureCountSegments" (ByVal arg0 As c2fb_Fts5Structure Ptr) As c2fb_c_int
#endif
Declare Sub fts5StructureWrite CDecl Alias "fts5StructureWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr)
Declare Function fts5SegmentSize CDecl Alias "fts5SegmentSize" (ByVal arg0 As c2fb_Fts5StructureSegment Ptr) As c2fb_c_int
Declare Sub fts5StructurePromoteTo CDecl Alias "fts5StructurePromoteTo" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Structure Ptr)
Declare Sub fts5StructurePromote CDecl Alias "fts5StructurePromote" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5Structure Ptr)
Declare Function fts5DlidxLvlNext CDecl Alias "fts5DlidxLvlNext" (ByVal arg0 As c2fb_Fts5DlidxLvl Ptr) As c2fb_c_int
Declare Function fts5DlidxIterNextR CDecl Alias "fts5DlidxIterNextR" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5DlidxIterNext CDecl Alias "fts5DlidxIterNext" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
Declare Function fts5DlidxIterFirst CDecl Alias "fts5DlidxIterFirst" (ByVal arg0 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
Declare Function fts5DlidxIterEof CDecl Alias "fts5DlidxIterEof" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
Declare Sub fts5DlidxIterLast CDecl Alias "fts5DlidxIterLast" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr)
Declare Function fts5DlidxLvlPrev CDecl Alias "fts5DlidxLvlPrev" (ByVal arg0 As c2fb_Fts5DlidxLvl Ptr) As c2fb_c_int
Declare Function fts5DlidxIterPrevR CDecl Alias "fts5DlidxIterPrevR" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5DlidxIterPrev CDecl Alias "fts5DlidxIterPrev" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
Declare Sub fts5DlidxIterFree CDecl Alias "fts5DlidxIterFree" (ByVal arg0 As c2fb_Fts5DlidxIter Ptr)
Declare Function fts5DlidxIterInit CDecl Alias "fts5DlidxIterInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_Fts5DlidxIter Ptr
Declare Function fts5DlidxIterRowid CDecl Alias "fts5DlidxIterRowid" (ByVal arg0 As c2fb_Fts5DlidxIter Ptr) As c2fb_int64
Declare Function fts5DlidxIterPgno CDecl Alias "fts5DlidxIterPgno" (ByVal arg0 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
Declare Sub fts5SegIterNextPage CDecl Alias "fts5SegIterNextPage" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Function fts5GetPoslistSize CDecl Alias "fts5GetPoslistSize" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub fts5SegIterLoadNPos CDecl Alias "fts5SegIterLoadNPos" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5SegIterLoadRowid CDecl Alias "fts5SegIterLoadRowid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5SegIterLoadTerm CDecl Alias "fts5SegIterLoadTerm" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub fts5SegIterSetNext CDecl Alias "fts5SegIterSetNext" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5SegIterAllocTombstone CDecl Alias "fts5SegIterAllocTombstone" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5SegIterInit CDecl Alias "fts5SegIterInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5SegIterReverseInitPage CDecl Alias "fts5SegIterReverseInitPage" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5SegIterReverseNewPage CDecl Alias "fts5SegIterReverseNewPage" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Function fts5MultiIterIsEmpty CDecl Alias "fts5MultiIterIsEmpty" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr) As c2fb_c_int
Declare Sub fts5SegIterNext_Reverse CDecl Alias "fts5SegIterNext_Reverse" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub fts5SegIterNext_None CDecl Alias "fts5SegIterNext_None" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub fts5SegIterNext CDecl Alias "fts5SegIterNext" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub fts5SegIterReverse CDecl Alias "fts5SegIterReverse" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5SegIterLoadDlidx CDecl Alias "fts5SegIterLoadDlidx" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5LeafSeek CDecl Alias "fts5LeafSeek" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5SegIter Ptr, ByVal arg3 As Const UByte Ptr, ByVal arg4 As c2fb_c_int)
Declare Function fts5IdxSelectStmt CDecl Alias "fts5IdxSelectStmt" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_sqlite3_stmt Ptr
Declare Sub fts5SegIterSeekInit CDecl Alias "fts5SegIterSeekInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5StructureSegment Ptr, ByVal arg5 As c2fb_Fts5SegIter Ptr)
Declare Function fts5IdxNextStmt CDecl Alias "fts5IdxNextStmt" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_sqlite3_stmt Ptr
Declare Sub fts5SegIterNextInit CDecl Alias "fts5SegIterNextInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5StructureSegment Ptr, ByVal arg4 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5SegIterHashInit CDecl Alias "fts5SegIterHashInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5IndexFreeArray CDecl Alias "fts5IndexFreeArray" (ByVal arg0 As c2fb_Fts5Data Ptr Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub fts5TombstoneArrayDelete CDecl Alias "fts5TombstoneArrayDelete" (ByVal arg0 As c2fb_Fts5TombstoneArray Ptr)
Declare Sub fts5SegIterClear CDecl Alias "fts5SegIterClear" (ByVal arg0 As c2fb_Fts5SegIter Ptr)
Declare Function fts5MultiIterDoCompare CDecl Alias "fts5MultiIterDoCompare" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5SegIterGotoPage CDecl Alias "fts5SegIterGotoPage" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub fts5SegIterNextFrom CDecl Alias "fts5SegIterNextFrom" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_int64)
Declare Sub fts5MultiIterFree CDecl Alias "fts5MultiIterFree" (ByVal arg0 As c2fb_Fts5Iter Ptr)
Declare Sub fts5MultiIterAdvanced CDecl Alias "fts5MultiIterAdvanced" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int)
Declare Function fts5MultiIterAdvanceRowid CDecl Alias "fts5MultiIterAdvanceRowid" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5SegIter Ptr Ptr) As c2fb_c_int
Declare Sub fts5MultiIterSetEof CDecl Alias "fts5MultiIterSetEof" (ByVal arg0 As c2fb_Fts5Iter Ptr)
Declare Function fts5IndexTombstoneQuery CDecl Alias "fts5IndexTombstoneQuery" (ByVal arg0 As c2fb_Fts5Data Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_uint64) As c2fb_c_int
Declare Function fts5MultiIterIsDeleted CDecl Alias "fts5MultiIterIsDeleted" (ByVal arg0 As c2fb_Fts5Iter Ptr) As c2fb_c_int
Declare Sub fts5MultiIterNext CDecl Alias "fts5MultiIterNext" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64)
Declare Sub fts5MultiIterNext2 CDecl Alias "fts5MultiIterNext2" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub fts5IterSetOutputs_Noop CDecl Alias "fts5IterSetOutputs_Noop" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Function fts5MultiIterAlloc CDecl Alias "fts5MultiIterAlloc" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int) As c2fb_Fts5Iter Ptr
Declare Sub fts5PoslistCallback CDecl Alias "fts5PoslistCallback" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Function fts5IndexColsetTest CDecl Alias "fts5IndexColsetTest" (ByVal arg0 As c2fb_Fts5Colset Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5PoslistOffsetsCallback CDecl Alias "fts5PoslistOffsetsCallback" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub fts5PoslistFilterCallback CDecl Alias "fts5PoslistFilterCallback" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub fts5ChunkIterate CDecl Alias "fts5ChunkIterate" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_355)
Declare Sub fts5SegiterPoslist CDecl Alias "fts5SegiterPoslist" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_Fts5Colset Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
Declare Sub fts5IndexExtractColset CDecl Alias "fts5IndexExtractColset" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5Iter Ptr)
Declare Sub fts5IterSetOutputs_None CDecl Alias "fts5IterSetOutputs_None" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5IterSetOutputs_Nocolset CDecl Alias "fts5IterSetOutputs_Nocolset" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5IterSetOutputs_ZeroColset CDecl Alias "fts5IterSetOutputs_ZeroColset" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5IterSetOutputs_Col CDecl Alias "fts5IterSetOutputs_Col" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5IterSetOutputs_Full CDecl Alias "fts5IterSetOutputs_Full" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5IterSetOutputCb CDecl Alias "fts5IterSetOutputCb" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr)
Declare Sub fts5MultiIterFinishSetup CDecl Alias "fts5MultiIterFinishSetup" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr)
Declare Sub fts5MultiIterNew CDecl Alias "fts5MultiIterNew" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Colset Ptr, ByVal arg4 As Const UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_Fts5Iter Ptr Ptr)
Declare Sub fts5MultiIterNew2 CDecl Alias "fts5MultiIterNew2" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Data Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Iter Ptr Ptr)
Declare Function fts5MultiIterEof CDecl Alias "fts5MultiIterEof" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr) As c2fb_c_int
Declare Function fts5MultiIterRowid CDecl Alias "fts5MultiIterRowid" (ByVal arg0 As c2fb_Fts5Iter Ptr) As c2fb_int64
Declare Sub fts5MultiIterNextFrom CDecl Alias "fts5MultiIterNextFrom" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr, ByVal arg2 As c2fb_int64)
Declare Function fts5MultiIterTerm CDecl Alias "fts5MultiIterTerm" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const UByte Ptr
Declare Function fts5AllocateSegid CDecl Alias "fts5AllocateSegid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr) As c2fb_c_int
Declare Sub fts5IndexDiscardData CDecl Alias "fts5IndexDiscardData" (ByVal arg0 As c2fb_Fts5Index Ptr)
Declare Function fts5PrefixCompress CDecl Alias "fts5PrefixCompress" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const UByte Ptr, ByVal arg2 As Const UByte Ptr) As c2fb_c_int
Declare Sub fts5WriteDlidxClear CDecl Alias "fts5WriteDlidxClear" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int)
Declare Function fts5WriteDlidxGrow CDecl Alias "fts5WriteDlidxGrow" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5WriteFlushDlidx CDecl Alias "fts5WriteFlushDlidx" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr) As c2fb_c_int
Declare Sub fts5WriteFlushBtree CDecl Alias "fts5WriteFlushBtree" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr)
Declare Sub fts5WriteBtreeTerm CDecl Alias "fts5WriteBtreeTerm" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
Declare Sub fts5WriteBtreeNoTerm CDecl Alias "fts5WriteBtreeNoTerm" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr)
Declare Function fts5DlidxExtractFirstRowid CDecl Alias "fts5DlidxExtractFirstRowid" (ByVal arg0 As c2fb_Fts5Buffer Ptr) As c2fb_int64
Declare Sub fts5WriteDlidxAppend CDecl Alias "fts5WriteDlidxAppend" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_int64)
Declare Sub fts5WriteFlushLeaf CDecl Alias "fts5WriteFlushLeaf" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr)
Declare Sub fts5WriteAppendTerm CDecl Alias "fts5WriteAppendTerm" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
Declare Sub fts5WriteAppendRowid CDecl Alias "fts5WriteAppendRowid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_int64)
Declare Sub fts5WriteAppendPoslistData CDecl Alias "fts5WriteAppendPoslistData" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub fts5WriteFinish CDecl Alias "fts5WriteFinish" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub fts5WriteInit CDecl Alias "fts5WriteInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub fts5TrimSegments CDecl Alias "fts5TrimSegments" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr)
Declare Sub fts5MergeChunkCallback CDecl Alias "fts5MergeChunkCallback" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub fts5IndexMergeLevel CDecl Alias "fts5IndexMergeLevel" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
Declare Function fts5IndexFindDeleteMerge CDecl Alias "fts5IndexFindDeleteMerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr) As c2fb_c_int
Declare Function fts5IndexMerge CDecl Alias "fts5IndexMerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5IndexAutomerge CDecl Alias "fts5IndexAutomerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub fts5IndexCrisismerge CDecl Alias "fts5IndexCrisismerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr)
Declare Function fts5IndexReturn CDecl Alias "fts5IndexReturn" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5IndexCloseReader CDecl Alias "sqlite3Fts5IndexCloseReader" (ByVal arg0 As c2fb_Fts5Index Ptr)
Declare Function fts5PoslistPrefix CDecl Alias "fts5PoslistPrefix" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5SecureDeleteIdxEntry CDecl Alias "fts5SecureDeleteIdxEntry" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int)
Declare Sub fts5SecureDeleteOverflow CDecl Alias "fts5SecureDeleteOverflow" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
Declare Sub fts5DoSecureDelete CDecl Alias "fts5DoSecureDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
Declare Function fts5FlushSecureDelete CDecl Alias "fts5FlushSecureDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_int64) As c2fb_c_int
Declare Sub fts5FlushOneHash CDecl Alias "fts5FlushOneHash" (ByVal arg0 As c2fb_Fts5Index Ptr)
Declare Sub fts5IndexFlush CDecl Alias "fts5IndexFlush" (ByVal arg0 As c2fb_Fts5Index Ptr)
Declare Function fts5IndexOptimizeStruct CDecl Alias "fts5IndexOptimizeStruct" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr) As c2fb_Fts5Structure Ptr
Declare Function sqlite3Fts5IndexOptimize CDecl Alias "sqlite3Fts5IndexOptimize" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexMerge CDecl Alias "sqlite3Fts5IndexMerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5AppendRowid CDecl Alias "fts5AppendRowid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
Declare Sub fts5AppendPoslist CDecl Alias "fts5AppendPoslist" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
Declare Sub fts5DoclistIterNext CDecl Alias "fts5DoclistIterNext" (ByVal arg0 As c2fb_Fts5DoclistIter Ptr)
Declare Sub fts5DoclistIterInit CDecl Alias "fts5DoclistIterInit" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5DoclistIter Ptr)
Declare Sub fts5BufferSwap CDecl Alias "fts5BufferSwap" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr)
Declare Sub fts5NextRowid CDecl Alias "fts5NextRowid" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_int64 Ptr)
Declare Sub fts5MergeRowidLists CDecl Alias "fts5MergeRowidLists" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Buffer Ptr)
Declare Sub fts5PrefixMergerInsertByRowid CDecl Alias "fts5PrefixMergerInsertByRowid" (ByVal arg0 As c2fb_PrefixMerger Ptr Ptr, ByVal arg1 As c2fb_PrefixMerger Ptr)
Declare Sub fts5PrefixMergerInsertByPosition CDecl Alias "fts5PrefixMergerInsertByPosition" (ByVal arg0 As c2fb_PrefixMerger Ptr Ptr, ByVal arg1 As c2fb_PrefixMerger Ptr)
Declare Sub fts5MergePrefixLists CDecl Alias "fts5MergePrefixLists" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Buffer Ptr)
Declare Function fts5VisitEntries CDecl Alias "fts5VisitEntries" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_356, ByVal arg6 As Any Ptr) As c2fb_c_int
Declare Sub fts5TokendataMerge CDecl Alias "fts5TokendataMerge" (ByVal arg0 As c2fb_Fts5TokenDataMap Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5TokenDataMap Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5TokenDataMap Ptr)
Declare Sub fts5TokendataIterAppendMap CDecl Alias "fts5TokendataIterAppendMap" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5TokenDataIter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_int64, ByVal arg5 As c2fb_int64)
Declare Sub fts5TokendataIterSortMap CDecl Alias "fts5TokendataIterSortMap" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5TokenDataIter Ptr)
Declare Sub fts5TokendataIterDelete CDecl Alias "fts5TokendataIterDelete" (ByVal arg0 As c2fb_Fts5TokenDataIter Ptr)
Declare Sub prefixIterSetupTokendataCb CDecl Alias "prefixIterSetupTokendataCb" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As Const UByte Ptr, ByVal arg4 As c2fb_c_int)
Declare Sub prefixIterSetupCb CDecl Alias "prefixIterSetupCb" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As Const UByte Ptr, ByVal arg4 As c2fb_c_int)
Declare Sub fts5SetupPrefixIter CDecl Alias "fts5SetupPrefixIter" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_Fts5Colset Ptr, ByVal arg6 As c2fb_Fts5Iter Ptr Ptr)
Declare Function sqlite3Fts5IndexBeginWrite CDecl Alias "sqlite3Fts5IndexBeginWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts5IndexSync CDecl Alias "sqlite3Fts5IndexSync" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexRollback CDecl Alias "sqlite3Fts5IndexRollback" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexReinit CDecl Alias "sqlite3Fts5IndexReinit" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexOpen CDecl Alias "sqlite3Fts5IndexOpen" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5Index Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexClose CDecl Alias "sqlite3Fts5IndexClose" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexCharlenToBytelen CDecl Alias "sqlite3Fts5IndexCharlenToBytelen" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5IndexCharlen CDecl Alias "fts5IndexCharlen" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5IndexWrite CDecl Alias "sqlite3Fts5IndexWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function fts5IsTokendataPrefix CDecl Alias "fts5IsTokendataPrefix" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5SegIterSetEOF CDecl Alias "fts5SegIterSetEOF" (ByVal arg0 As c2fb_Fts5SegIter Ptr)
Declare Sub fts5IterClose CDecl Alias "fts5IterClose" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
Declare Sub fts5IterSetOutputsTokendata CDecl Alias "fts5IterSetOutputsTokendata" (ByVal arg0 As c2fb_Fts5Iter Ptr)
Declare Sub fts5TokendataIterNext CDecl Alias "fts5TokendataIterNext" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64)
Declare Sub fts5TokendataSetTermIfEof CDecl Alias "fts5TokendataSetTermIfEof" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr)
Declare Function fts5SetupTokendataIter CDecl Alias "fts5SetupTokendataIter" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Colset Ptr) As c2fb_Fts5Iter Ptr
Declare Function sqlite3Fts5IndexQuery CDecl Alias "sqlite3Fts5IndexQuery" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5Colset Ptr, ByVal arg5 As c2fb_Fts5IndexIter Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IterNext CDecl Alias "sqlite3Fts5IterNext" (ByVal arg0 As c2fb_Fts5IndexIter Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IterNextScan CDecl Alias "sqlite3Fts5IterNextScan" (ByVal arg0 As c2fb_Fts5IndexIter Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IterNextFrom CDecl Alias "sqlite3Fts5IterNextFrom" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts5IterTerm CDecl Alias "sqlite3Fts5IterTerm" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const ZString Ptr
Declare Function fts5SetupPrefixIterTokendata CDecl Alias "fts5SetupPrefixIterTokendata" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5IterToken CDecl Alias "sqlite3Fts5IterToken" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5IndexIterClearTokendata CDecl Alias "sqlite3Fts5IndexIterClearTokendata" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
Declare Sub sqlite3Fts5IterClose CDecl Alias "sqlite3Fts5IterClose" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
Declare Function sqlite3Fts5IndexGetAverages CDecl Alias "sqlite3Fts5IndexGetAverages" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexSetAverages CDecl Alias "sqlite3Fts5IndexSetAverages" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5IndexReads CDecl Alias "sqlite3Fts5IndexReads" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexSetCookie CDecl Alias "sqlite3Fts5IndexSetCookie" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5IndexLoadConfig CDecl Alias "sqlite3Fts5IndexLoadConfig" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexGetOrigin CDecl Alias "sqlite3Fts5IndexGetOrigin" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts5IndexTombstoneAddToPage CDecl Alias "fts5IndexTombstoneAddToPage" (ByVal arg0 As c2fb_Fts5Data Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_uint64) As c2fb_c_int
Declare Function fts5IndexTombstoneRehash CDecl Alias "fts5IndexTombstoneRehash" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_Fts5Data Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_Fts5Data Ptr Ptr) As c2fb_c_int
Declare Sub fts5IndexTombstoneRebuild CDecl Alias "fts5IndexTombstoneRebuild" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_Fts5Data Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As c2fb_Fts5Data Ptr Ptr Ptr)
Declare Sub fts5IndexTombstoneAdd CDecl Alias "fts5IndexTombstoneAdd" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_uint64)
Declare Function sqlite3Fts5IndexContentlessDelete CDecl Alias "sqlite3Fts5IndexContentlessDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts5IndexEntryCksum CDecl Alias "sqlite3Fts5IndexEntryCksum" (ByVal arg0 As c2fb_int64, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_uint64
Declare Sub fts5IndexIntegrityCheckEmpty CDecl Alias "fts5IndexIntegrityCheckEmpty" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int)
Declare Sub fts5IntegrityCheckPgidx CDecl Alias "fts5IntegrityCheckPgidx" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_Fts5Data Ptr)
Declare Sub fts5IndexIntegrityCheckSegment CDecl Alias "fts5IndexIntegrityCheckSegment" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr)
Declare Function sqlite3Fts5IndexIntegrityCheck CDecl Alias "sqlite3Fts5IndexIntegrityCheck" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5IndexReset CDecl Alias "sqlite3Fts5IndexReset" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memmove CDecl Alias "memmove" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5ConfigLoad CDecl Alias "sqlite3Fts5ConfigLoad" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5ConfigErrmsg CDecl Alias "sqlite3Fts5ConfigErrmsg" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Function c2fb_external_sqlite3Fts5BufferSize CDecl Alias "sqlite3Fts5BufferSize" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_uint) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5BufferAppendVarint CDecl Alias "sqlite3Fts5BufferAppendVarint" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_int64)
Declare Sub c2fb_external_sqlite3Fts5BufferAppendBlob CDecl Alias "sqlite3Fts5BufferAppendBlob" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_uint, ByVal arg3 As Const UByte Ptr)
Declare Sub c2fb_external_sqlite3Fts5BufferFree CDecl Alias "sqlite3Fts5BufferFree" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
Declare Sub c2fb_external_sqlite3Fts5BufferZero CDecl Alias "sqlite3Fts5BufferZero" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
Declare Sub c2fb_external_sqlite3Fts5BufferSet CDecl Alias "sqlite3Fts5BufferSet" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
Declare Function c2fb_external_sqlite3Fts5Mprintf CDecl Alias "sqlite3Fts5Mprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
Declare Sub c2fb_external_sqlite3Fts5Put32 CDecl Alias "sqlite3Fts5Put32" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_int)
Declare Function c2fb_external_sqlite3Fts5Get32 CDecl Alias "sqlite3Fts5Get32" (ByVal arg0 As Const UByte Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5PoslistReaderInit CDecl Alias "sqlite3Fts5PoslistReaderInit" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5PoslistReaderNext CDecl Alias "sqlite3Fts5PoslistReaderNext" (ByVal arg0 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5PoslistSafeAppend CDecl Alias "sqlite3Fts5PoslistSafeAppend" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64)
Declare Function c2fb_external_sqlite3Fts5PoslistNext64 CDecl Alias "sqlite3Fts5PoslistNext64" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5MallocZero CDecl Alias "sqlite3Fts5MallocZero" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function c2fb_external_sqlite3Fts5GetVarint32 CDecl Alias "sqlite3Fts5GetVarint32" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_uint Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5GetVarint CDecl Alias "sqlite3Fts5GetVarint" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_uint64 Ptr) As UByte
Declare Function c2fb_external_sqlite3Fts5PutVarint CDecl Alias "sqlite3Fts5PutVarint" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_uint64) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5HashNew CDecl Alias "sqlite3Fts5HashNew" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_Fts5Hash Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5HashFree CDecl Alias "sqlite3Fts5HashFree" (ByVal arg0 As c2fb_Fts5Hash Ptr)
Declare Function c2fb_external_sqlite3Fts5HashWrite CDecl Alias "sqlite3Fts5HashWrite" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Byte, ByVal arg5 As Const ZString Ptr, ByVal arg6 As c2fb_c_int) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5HashClear CDecl Alias "sqlite3Fts5HashClear" (ByVal arg0 As c2fb_Fts5Hash Ptr)
Declare Function c2fb_external_sqlite3Fts5HashQuery CDecl Alias "sqlite3Fts5HashQuery" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sqlite3Fts5HashIsEmpty CDecl Alias "sqlite3Fts5HashIsEmpty" (ByVal arg0 As c2fb_Fts5Hash Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5HashScanInit CDecl Alias "sqlite3Fts5HashScanInit" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Fts5HashScanEof CDecl Alias "sqlite3Fts5HashScanEof" (ByVal arg0 As c2fb_Fts5Hash Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts5HashScanNext CDecl Alias "sqlite3Fts5HashScanNext" (ByVal arg0 As c2fb_Fts5Hash Ptr)
Declare Sub c2fb_external_sqlite3Fts5HashScanEntry CDecl Alias "sqlite3Fts5HashScanEntry" (ByVal arg0 As c2fb_Fts5Hash Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As Const UByte Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr)
Declare Function c2fb_external_sqlite3Fts5CreateTable CDecl Alias "sqlite3Fts5CreateTable" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int

#if defined(SQLITE_TEST) OrElse defined(SQLITE_FTS5_DEBUG)
Private Type c2fb_source_record_6
    base As c2fb_sqlite3_vtab
End Type
Private Type c2fb_source_record_7
    base As c2fb_sqlite3_vtab_cursor
    pStruct As c2fb_Fts5Structure Ptr
    iLevel As c2fb_c_int
    iSeg As c2fb_c_int
    iRowid As c2fb_c_int
End Type
Type c2fb_callback_8 As Sub CDecl(ByVal arg0 As Any Ptr)
Private Function __c2fb_double_value(ByVal value As Double) As Double
    Return value
End Function
Declare Function sqlite3Fts5GetVarint CDecl Alias "sqlite3Fts5GetVarint" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_uint64 Ptr) As UByte
Declare Sub c2fb_external_sqlite3Fts5BufferAppendPrintf CDecl Alias "sqlite3Fts5BufferAppendPrintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As ZString Ptr, ...)
Declare Function c2fb_external_sqlite3_value_blob_ CDecl Alias "sqlite3_value_blob" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const Any Ptr
Declare Function c2fb_external_sqlite3_value_int_ CDecl Alias "sqlite3_value_int" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_int64_ CDecl Alias "sqlite3_value_int64" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_value_text_ CDecl Alias "sqlite3_value_text" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes_ CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_user_data_ CDecl Alias "sqlite3_user_data" (ByVal arg0 As c2fb_sqlite3_context Ptr) As Any Ptr
Declare Sub c2fb_external_sqlite3_result_error_ CDecl Alias "sqlite3_result_error" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_error_code_ CDecl Alias "sqlite3_result_error_code" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_int_ CDecl Alias "sqlite3_result_int" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_int64_ CDecl Alias "sqlite3_result_int64" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_int64)
Declare Sub c2fb_external_sqlite3_result_text_ CDecl Alias "sqlite3_result_text" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_callback_8)
Declare Function c2fb_external_sqlite3_declare_vtab_ CDecl Alias "sqlite3_declare_vtab" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Sub fts5DecodeRowid CDecl Alias "fts5DecodeRowid" (ByVal arg0 As c2fb_int64, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr)
Declare Sub fts5DebugRowid CDecl Alias "fts5DebugRowid" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_int64)
Declare Sub fts5DebugStructure CDecl Alias "fts5DebugStructure" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_Fts5Structure Ptr)
Declare Sub fts5DecodeStructure CDecl Alias "fts5DecodeStructure" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub fts5DecodeAverages CDecl Alias "fts5DecodeAverages" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Function fts5DecodePoslist CDecl Alias "fts5DecodePoslist" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function fts5DecodeDoclist CDecl Alias "fts5DecodeDoclist" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Sub fts5DecodeRowidList CDecl Alias "fts5DecodeRowidList" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
Declare Sub fts5BufferAppendTerm CDecl Alias "fts5BufferAppendTerm" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_Fts5Buffer Ptr)
Declare Sub fts5DecodeFunction CDecl Alias "fts5DecodeFunction" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub fts5RowidFunction CDecl Alias "fts5RowidFunction" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function fts5structConnectMethod CDecl Alias "fts5structConnectMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts5structBestIndexMethod CDecl Alias "fts5structBestIndexMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_index_info Ptr) As c2fb_c_int
Declare Function fts5structDisconnectMethod CDecl Alias "fts5structDisconnectMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
Declare Function fts5structOpenMethod CDecl Alias "fts5structOpenMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_vtab_cursor Ptr Ptr) As c2fb_c_int
Declare Function fts5structCloseMethod CDecl Alias "fts5structCloseMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5structNextMethod CDecl Alias "fts5structNextMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5structEofMethod CDecl Alias "fts5structEofMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
Declare Function fts5structRowidMethod CDecl Alias "fts5structRowidMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function fts5structColumnMethod CDecl Alias "fts5structColumnMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_sqlite3_context Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts5structFilterMethod CDecl Alias "fts5structFilterMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5IndexInit CDecl Alias "sqlite3Fts5IndexInit" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
#endif

Private Function fts5IndexCorruptRowid CDecl Alias "fts5IndexCorruptRowid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 562
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_external_sqlite3Fts5ConfigErrmsg(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig), StrPtr(!"fts5: corruption found reading blob %lld from table \034%s\034"), arg1, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->zName)
    Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
End Function
Private Function fts5IndexCorruptIter CDecl Alias "fts5IndexCorruptIter" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 572
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_external_sqlite3Fts5ConfigErrmsg(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig), StrPtr(!"fts5: corruption on page %d, segment %d, table \034%s\034"), arg1->iLeafPgno, CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)->iSegid, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->zName)
    Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
End Function
Private Function fts5IndexCorruptIdx CDecl Alias "fts5IndexCorruptIdx" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 582
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_external_sqlite3Fts5ConfigErrmsg(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig), StrPtr(!"fts5: corruption in table \034%s\034"), CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->zName)
    Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
End Function
Private Sub fts5PutU16 CDecl Alias "fts5PutU16" (ByVal arg0 As UByte Ptr, ByVal arg1 As UShort)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 712
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, (Cast(c2fb_c_int, (Cast(c2fb_c_int, arg1) Shr Cast(c2fb_c_int, 8ULL)))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_3 = Cast(UByte, (Cast(c2fb_c_int, (Cast(c2fb_c_int, arg1) And Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_2) = c2fb_temp_3
End Sub
Private Function fts5GetU16 CDecl Alias "fts5GetU16" (ByVal arg0 As Const UByte Ptr) As UShort
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 717
    Return Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, Cast(UShort, arg0[Cast(c2fb_c_int, &O0ULL)])) Shl Cast(c2fb_c_int, 8ULL)))) + Cast(c2fb_c_int, arg0[Cast(c2fb_c_int, 1ULL)])))
End Function
Private Function fts5GetU64 CDecl Alias "fts5GetU64" (ByVal arg0 As UByte Ptr) As c2fb_uint64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 726
    Return Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0[Cast(c2fb_c_int, &O0ULL)]) Shl Cast(c2fb_c_int, 56ULL)))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0[Cast(c2fb_c_int, 1ULL)]) Shl Cast(c2fb_c_int, 48ULL)))))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0[Cast(c2fb_c_int, 2ULL)]) Shl Cast(c2fb_c_int, 40ULL)))))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0[Cast(c2fb_c_int, 3ULL)]) Shl Cast(c2fb_c_int, 32ULL)))))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0[Cast(c2fb_c_int, 4ULL)]) Shl Cast(c2fb_c_int, 24ULL)))))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0[Cast(c2fb_c_int, 5ULL)]) Shl Cast(c2fb_c_int, 16ULL)))))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0[Cast(c2fb_c_int, 6ULL)]) Shl Cast(c2fb_c_int, 8ULL)))))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0[Cast(c2fb_c_int, 7ULL)]) Shl Cast(c2fb_c_int, &O0ULL))))))
End Function
Private Function fts5GetU32 CDecl Alias "fts5GetU32" (ByVal arg0 As Const UByte Ptr) As c2fb_c_uint
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 742
    Return Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, &O0ULL)]) Shl Cast(c2fb_c_int, 24ULL)))) + (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, 1ULL)]) Shl Cast(c2fb_c_int, 16ULL)))))) + (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, 2ULL)]) Shl Cast(c2fb_c_int, 8ULL)))))) + (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, 3ULL)]) Shl Cast(c2fb_c_int, &O0ULL))))))
End Function
Private Sub fts5PutU64 CDecl Alias "fts5PutU64" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_uint64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 753
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

    c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 56ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_3 = Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 48ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 2ULL)]))
    c2fb_temp_5 = Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 40ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 3ULL)]))
    c2fb_temp_7 = Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 32ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 4ULL)]))
    c2fb_temp_9 = Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 24ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 5ULL)]))
    c2fb_temp_11 = Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 16ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 6ULL)]))
    c2fb_temp_13 = Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_12) = c2fb_temp_13
    c2fb_temp_14 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 7ULL)]))
    c2fb_temp_15 = Cast(UByte, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg1 Shr Cast(c2fb_c_int, &O0ULL)))) And Cast(c2fb_uint64, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_14) = c2fb_temp_15
End Sub
Private Sub fts5PutU32 CDecl Alias "fts5PutU32" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_uint)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 768
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte

    c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (arg1 Shr Cast(c2fb_c_int, 24ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_3 = Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (arg1 Shr Cast(c2fb_c_int, 16ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 2ULL)]))
    c2fb_temp_5 = Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (arg1 Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 3ULL)]))
    c2fb_temp_7 = Cast(UByte, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (arg1 Shr Cast(c2fb_c_int, &O0ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL))))))
    (*c2fb_temp_6) = c2fb_temp_7
End Sub
Private Function fts5IdxMalloc CDecl Alias "fts5IdxMalloc" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 781
    Return CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), arg1))
End Function
Private Function fts5BufferCompare CDecl Alias "fts5BufferCompare" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 813
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, (IIf(((-Cast(c2fb_c_int, (((arg0->n) < (arg1->n)))))), (arg0->n), (arg1->n))))
    local0 = c2fb_temp_0
#ifdef SQLITE_DEBUG
    If local0 > 0 AndAlso arg0->p = 0 Then _
        sqlite3DebugAssert(StrPtr(!"nCmp<=0 || pLeft->p!=0"))
    If local0 > 0 AndAlso arg1->p = 0 Then _
        sqlite3DebugAssert(StrPtr(!"nCmp<=0 || pRight->p!=0"))
#endif
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_1 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, (((local0) <= Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, &O0ULL), c2fb_crt_memcmp(CPtr(Const Any Ptr, (arg0->p)), CPtr(Const Any Ptr, (arg1->p)), (local0)))))
    local1 = c2fb_temp_1
    Return (IIf((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))), (Cast(c2fb_c_int, (arg0->n - arg1->n))), local1))
End Function
Private Function fts5LeafFirstTermOff CDecl Alias "fts5LeafFirstTermOff" (ByVal arg0 As c2fb_Fts5Data Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 822
    Dim local0 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->p[arg0->szLeaf]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local0)))))
    Return local0
End Function
Private Sub fts5IndexCloseReader CDecl Alias "fts5IndexCloseReader" (ByVal arg0 As c2fb_Fts5Index Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 831
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_blob Ptr
    Dim c2fb_temp_0 As c2fb_sqlite3_blob_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_sqlite3_blob Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    If CPtr(c2fb_sqlite3_blob Ptr, arg0->pReader) Then
        ' C automatic storage declaration
        local1 = CPtr(c2fb_sqlite3_blob Ptr, arg0->pReader)
        c2fb_temp_0 = CPtr(c2fb_sqlite3_blob_ Ptr Ptr, @(arg0->pReader))
        c2fb_temp_1 = CPtr(c2fb_sqlite3_blob Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = CPtr(c2fb_sqlite3_blob_ Ptr, c2fb_temp_1)
        c2fb_temp_1 = CPtr(c2fb_sqlite3_blob Ptr, (*c2fb_temp_0))
        c2fb_temp_2 = Cast(c2fb_c_int, sqlite3_blob_close(CPtr(Any Ptr, local1)))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_4 = Cast(c2fb_c_int, local0)
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        End If
    End If
End Sub
Private Function fts5DataRead CDecl Alias "fts5DataRead" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Data Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 847
    Dim local0 As c2fb_Fts5Data Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_blob Ptr
    Dim c2fb_temp_0 As c2fb_sqlite3_blob_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_sqlite3_blob Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_sqlite3_blob_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_sqlite3_blob Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local3 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local4 As UByte Ptr
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As UByte Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_19 As c2fb_u8 Ptr
    Dim c2fb_temp_20 As UByte
    Dim c2fb_temp_21 As c2fb_u8 Ptr
    Dim c2fb_temp_22 As UByte
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        If CPtr(c2fb_sqlite3_blob Ptr, arg0->pReader) Then
            local2 = CPtr(c2fb_sqlite3_blob Ptr, arg0->pReader)
            c2fb_temp_0 = CPtr(c2fb_sqlite3_blob_ Ptr Ptr, @(arg0->pReader))
            c2fb_temp_1 = CPtr(c2fb_sqlite3_blob Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_0) = CPtr(c2fb_sqlite3_blob_ Ptr, c2fb_temp_1)
            c2fb_temp_1 = CPtr(c2fb_sqlite3_blob Ptr, (*c2fb_temp_0))
#ifdef SQLITE_DEBUG
            If CPtr(c2fb_sqlite3_blob Ptr, arg0->pReader) <> 0 Then _
                sqlite3DebugAssert(StrPtr(!"p->pReader==0"))
#endif
            c2fb_temp_2 = Cast(c2fb_c_int, sqlite3_blob_reopen(CPtr(Any Ptr, local2), arg1))
            local1 = c2fb_temp_2
            ' C unused-parameter annotation
            c2fb_temp_3 = CPtr(c2fb_sqlite3_blob_ Ptr Ptr, @(arg0->pReader))
            c2fb_temp_4 = local2
            (*c2fb_temp_3) = CPtr(c2fb_sqlite3_blob_ Ptr, c2fb_temp_4)
            c2fb_temp_4 = CPtr(c2fb_sqlite3_blob Ptr, (*c2fb_temp_3))
            If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                fts5IndexCloseReader(arg0)
            End If
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 4ULL))))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local1 = c2fb_temp_5
            End If
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_blob Ptr, arg0->pReader) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            local3 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
            c2fb_temp_6 = Cast(c2fb_c_int, sqlite3_blob_open(CPtr(Any Ptr, CPtr(sqlite3 Ptr, local3->db)), CPtr(Const ZString Ptr, local3->zDb), CPtr(Const ZString Ptr, arg0->zDataTbl), StrPtr(!"block"), arg1, Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr Ptr, CPtr(c2fb_sqlite3_blob Ptr Ptr, @(arg0->pReader)))))
            local1 = c2fb_temp_6
        End If
        ' Blob reads in the FreeBASIC core can return SQLITE_CORRUPT directly
        ' for damaged FTS5 shadow data. Keep that diagnostic with the owning
        ' virtual table, as SQLite does when the blob API returns SQLITE_ERROR.
        If (-Cast(c2fb_c_int, (((local1 = SQLITE_ERROR) OrElse _
            (local1 = SQLITE_CORRUPT))))) Then
            c2fb_temp_7 = Cast(c2fb_c_int, fts5IndexCorruptRowid(arg0, arg1))
            local1 = c2fb_temp_7
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            local4 = Cast(c2fb_c_int, &O0ULL)
            local5 = sqlite3_blob_bytes(CPtr(Any Ptr, CPtr(c2fb_sqlite3_blob Ptr, arg0->pReader)))
            local6 = Cast(c2fb_uint64, ((Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Data))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 7ULL))))) And Cast(c2fb_uint64, Cast(c2fb_c_int, (Not Cast(c2fb_c_int, 7ULL))))))
            local7 = Cast(c2fb_int64, (Cast(c2fb_int64, (local6 + local5)) + Cast(c2fb_int64, Cast(c2fb_c_int, 20ULL))))
            c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, CPtr(Any Ptr, sqlite3_malloc64(local7))))
            local0 = c2fb_temp_8
            If local0 Then
                c2fb_temp_9 = CPtr(Long Ptr, @(local0->nn))
                c2fb_temp_10 = Cast(c2fb_c_int, local5)
                (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
                c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
                c2fb_temp_11 = CPtr(Long Ptr, @(local0->szLeaf))
                c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
                c2fb_temp_13 = CPtr(c2fb_u8 Ptr Ptr, @(local0->p))
                c2fb_temp_14 = CPtr(UByte Ptr, (CPtr(UByte Ptr, local0) + local6))
                (*c2fb_temp_13) = CPtr(c2fb_u8 Ptr, c2fb_temp_14)
                c2fb_temp_14 = CPtr(UByte Ptr, (*c2fb_temp_13))
                c2fb_temp_15 = c2fb_temp_14
                local4 = c2fb_temp_15
            Else
                c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local1 = c2fb_temp_16
            End If
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_17 = Cast(c2fb_c_int, sqlite3_blob_read(CPtr(Any Ptr, CPtr(c2fb_sqlite3_blob Ptr, arg0->pReader)), CPtr(Any Ptr, local4), local5, Cast(c2fb_c_int, &O0ULL)))
                local1 = c2fb_temp_17
            End If
            If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                sqlite3_free(CPtr(Any Ptr, local0))
                c2fb_temp_18 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_18
            Else
                c2fb_temp_19 = CPtr(c2fb_u8 Ptr, @(local0->p[local5]))
                c2fb_temp_20 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
                (*c2fb_temp_19) = Cast(c2fb_u8, c2fb_temp_20)
                c2fb_temp_20 = Cast(UByte, (*c2fb_temp_19))
                c2fb_temp_21 = CPtr(c2fb_u8 Ptr, @(local0->p[Cast(c2fb_int64, (local5 + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))]))
                c2fb_temp_22 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
                (*c2fb_temp_21) = Cast(c2fb_u8, c2fb_temp_22)
                c2fb_temp_22 = Cast(UByte, (*c2fb_temp_21))
            End If
        End If
        c2fb_temp_23 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_24 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
        c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
        c2fb_temp_25 = CPtr(Long Ptr, @(arg0->nRead))
        c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
        (*c2fb_temp_25) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_26 + 1)))
    End If
#ifdef SQLITE_DEBUG
    If (local0 = 0) <> (arg0->rc <> SQLITE_OK) Then _
        sqlite3DebugAssert(StrPtr(!"(pRet==0)==(p->rc!=SQLITE_OK)"))
    If local0 <> 0 AndAlso (Cast(SQLITE_SIZE_T, local0->p) And 7) <> 0 Then _
        sqlite3DebugAssert(StrPtr(!"pRet==0 || EIGHT_BYTE_ALIGNMENT(pRet->p)"))
#endif
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    Return local0
End Function
Private Sub fts5DataRelease CDecl Alias "fts5DataRelease" (ByVal arg0 As c2fb_Fts5Data Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 922
    sqlite3_free(CPtr(Any Ptr, arg0))
End Sub
Private Function fts5LeafRead CDecl Alias "fts5LeafRead" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64) As c2fb_Fts5Data Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 930
    Dim local0 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_Fts5Data Ptr

    local0 = CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, arg1))
    If local0 Then
#ifdef SQLITE_DEBUG
        If local0->szLeaf <> 0 Then _
            sqlite3DebugAssert(StrPtr(!"pRet->szLeaf==0"))
#endif
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local0->nn >= Cast(c2fb_c_int, 4ULL))))) Then
            c2fb_temp_0 = CPtr(Long Ptr, @(local0->szLeaf))
            c2fb_temp_1 = Cast(c2fb_c_int, fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->p[Cast(c2fb_c_int, 2ULL)])))))
            (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
            c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->szLeaf < Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->szLeaf > local0->nn)))) <> 0))))) Then
            fts5IndexCorruptRowid(arg0, arg1)
            fts5DataRelease(local0)
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_2
        End If
    End If
    Return local0
End Function
Private Function fts5IndexPrepareStmt CDecl Alias "fts5IndexPrepareStmt" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg2 As ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 946
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If arg2 Then
            local0 = sqlite3_prepare_v3(CPtr(Any Ptr, CPtr(sqlite3 Ptr, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->db)), CPtr(Const ZString Ptr, arg2), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, (Cast(c2fb_c_int, &H01ULL) Or Cast(c2fb_c_int, &H04ULL))), CPtr(Any Ptr Ptr, arg1), Cast(c2fb_c_int, &O0ULL))
            c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_1 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))), Cast(c2fb_c_int, 11ULL), local0)))
            (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
            c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        Else
            c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, arg2))
    Return arg0->rc
End Function
Private Sub fts5DataWrite CDecl Alias "fts5DataWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 972
    Dim local0 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pWriter) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pWriter)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"REPLACE INTO '%q'.'%q_data'(id, block) VALUES(?,?)"), local0->zDb, local0->zName)))
        If arg0->rc Then
            Return
        End If
    End If
    sqlite3_bind_int64(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pWriter)), Cast(c2fb_c_int, 1ULL), arg1)
    sqlite3_bind_blob(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pWriter)), Cast(c2fb_c_int, 2ULL), CPtr(Const Any Ptr, arg2), arg3, CPtr(Any Ptr, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
    sqlite3_step(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pWriter)))
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pWriter))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    sqlite3_bind_null(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pWriter)), Cast(c2fb_c_int, 2ULL))
End Sub
Private Sub fts5DataDelete CDecl Alias "fts5DataDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 996
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleter) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        local1 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"DELETE FROM '%q'.'%q_data' WHERE id>=? AND id<=?"), local0->zDb, local0->zName))
        If fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pDeleter)), local1) Then
            Return
        End If
    End If
    sqlite3_bind_int64(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleter)), Cast(c2fb_c_int, 1ULL), arg1)
    sqlite3_bind_int64(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleter)), Cast(c2fb_c_int, 2ULL), arg2)
    sqlite3_step(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleter)))
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleter))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
End Sub
Private Sub fts5DataRemoveSegment CDecl Alias "fts5DataRemoveSegment" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1017
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = arg1->iSegid
    local1 = (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local0)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL)))))))
    local2 = Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))))))) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))
    fts5DataDelete(arg0, local1, local2)
    If arg1->nPgTombstone Then
        local3 = (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (local0 + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 16ULL)))))))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL)))))))
        local4 = (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (local0 + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 16ULL)))))))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_c_int, (arg1->nPgTombstone - Cast(c2fb_c_int, 1ULL)))))))))
        fts5DataDelete(arg0, local3, local4)
    End If
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxDeleter) = Cast(c2fb_c_int, &O0ULL))))) Then
        local5 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pIdxDeleter)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"DELETE FROM '%q'.'%q_idx' WHERE segid=?"), local5->zDb, local5->zName)))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_bind_int(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxDeleter)), Cast(c2fb_c_int, 1ULL), local0)
        sqlite3_step(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxDeleter)))
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxDeleter))))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    End If
End Sub
Private Sub fts5StructureRelease CDecl Alias "fts5StructureRelease" (ByVal arg0 As c2fb_Fts5Structure Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1046
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    c2fb_temp_4 = 0
    If (arg0 <> 0) Then
        c2fb_temp_3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->nRef))
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
        c2fb_temp_2 = (*c2fb_temp_0)
        c2fb_temp_4 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((c2fb_temp_3 >= (c2fb_temp_2))))) <> 0))))
    End If
    If c2fb_temp_4 Then
#ifdef SQLITE_DEBUG
        If arg0->nRef <> 0 Then sqlite3DebugAssert(StrPtr(!"pStruct->nRef==0"))
#endif
        ' C automatic storage declaration
        ' C unused-parameter annotation
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_5
        While (-Cast(c2fb_c_int, ((local0 < arg0->nLevel))))
            sqlite3_free(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg0)))[local0].aSeg)
        c2fb_flow_1:
            c2fb_temp_6 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        Wend
        c2fb_flow_0:
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Private Sub fts5StructureRef CDecl Alias "fts5StructureRef" (ByVal arg0 As c2fb_Fts5Structure Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1057
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->nRef))
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
End Sub
Function sqlite3Fts5StructureRef CDecl Alias "sqlite3Fts5StructureRef" (ByVal arg0 As c2fb_Fts5Index Ptr) As Any Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1061
    fts5StructureRef(CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct))
    Return CPtr(Any Ptr, CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct))
End Function
Sub sqlite3Fts5StructureRelease CDecl Alias "sqlite3Fts5StructureRelease" (ByVal arg0 As Any Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1065
    If arg0 Then
        fts5StructureRelease(CPtr(c2fb_Fts5Structure Ptr, arg0))
    End If
End Sub
Function sqlite3Fts5StructureTest CDecl Alias "sqlite3Fts5StructureTest" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1070
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct) <> CPtr(c2fb_Fts5Structure Ptr, arg1))))) Then
        Return Cast(c2fb_c_int, 4ULL)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped fts5StructureMakeWritable: outside the supported subset
' c2fb body diagnostic [assignment-target-not-writable] line 1083: fts5StructureMakeWritable: assignment target is not writable: C type=, storage=c2fb_Fts5StructureSegment_ Ptr, record=, layout=c2fb_Fts5StructureSegment_ Ptr, expression=CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel, lvalue expression=CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel, lvalue=-1, const=0, bit width=-1
Private Sub fts5StructureMakeWritable CDecl Alias "fts5StructureMakeWritable" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr)
    Dim pStruct As c2fb_Fts5Structure Ptr
    Dim pNew As c2fb_Fts5Structure Ptr
    Dim pLevel As c2fb_Fts5StructureLevel Ptr
    Dim pSourceLevel As c2fb_Fts5StructureLevel Ptr
    Dim nByte As c2fb_int64
    Dim iLevel As c2fb_c_int
    Dim iFree As c2fb_c_int

    pStruct = *arg1
    If *arg0 = 0 AndAlso pStruct->nRef > 1 Then
        ' Remove the generated tail placeholder from SizeOf, then reserve the
        ' exact number of levels requested by the C structure macro.
        nByte = SizeOf(c2fb_Fts5Structure) - SizeOf(c2fb_Fts5StructureLevel)
        nByte += CULngInt(pStruct->nLevel) * SizeOf(c2fb_Fts5StructureLevel)

        pNew = CPtr(c2fb_Fts5Structure Ptr, _
            c2fb_external_sqlite3Fts5MallocZero(arg0, nByte))
        If pNew Then
            sqlite3WhereMemcpy(pNew, pStruct, Cast(SQLITE_SIZE_T, nByte))

            For iLevel = 0 To pStruct->nLevel - 1
                pLevel = CPtr(c2fb_Fts5StructureLevel Ptr, _
                    @(CPtr(c2fb_Fts5StructureLevel Ptr, _
                        c2fb_Fts5Structure_aLevel_tail_ptr(pNew))[iLevel]))
                pLevel->aSeg = 0
            Next

            For iLevel = 0 To pStruct->nLevel - 1
                pLevel = CPtr(c2fb_Fts5StructureLevel Ptr, _
                    @(CPtr(c2fb_Fts5StructureLevel Ptr, _
                        c2fb_Fts5Structure_aLevel_tail_ptr(pNew))[iLevel]))
                pSourceLevel = CPtr(c2fb_Fts5StructureLevel Ptr, _
                    @(CPtr(c2fb_Fts5StructureLevel Ptr, _
                        c2fb_Fts5Structure_aLevel_tail_ptr(pStruct))[iLevel]))
                nByte = CULngInt(pLevel->nSeg) * _
                    SizeOf(c2fb_Fts5StructureSegment)
                pLevel->aSeg = CPtr(c2fb_Fts5StructureSegment_ Ptr, _
                    c2fb_external_sqlite3Fts5MallocZero(arg0, nByte))

                If pLevel->aSeg = 0 Then
                    For iFree = 0 To pStruct->nLevel - 1
                        pLevel = CPtr(c2fb_Fts5StructureLevel Ptr, _
                            @(CPtr(c2fb_Fts5StructureLevel Ptr, _
                                c2fb_Fts5Structure_aLevel_tail_ptr(pNew))[iFree]))
                        sqlite3_free(pLevel->aSeg)
                    Next
                    sqlite3_free(pNew)
                    Return
                End If

                sqlite3WhereMemcpy(pLevel->aSeg, pSourceLevel->aSeg, _
                    Cast(SQLITE_SIZE_T, nByte))
            Next

            pStruct->nRef -= 1
            pNew->nRef = 1
        End If

        *arg1 = pNew
    End If
End Sub
Private Function fts5StructureDecode CDecl Alias "fts5StructureDecode" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_Fts5Structure Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1125
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_Fts5Structure Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local9 As c2fb_Fts5StructureLevel Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_Fts5StructureSegment_ Ptr Ptr
    Dim c2fb_temp_23 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim local12 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_uint64
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_u64 Ptr
    Dim c2fb_temp_44 As c2fb_uint64
    Dim c2fb_temp_45 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_46 As c2fb_Fts5Structure Ptr Ptr
    Dim c2fb_temp_47 As c2fb_Fts5Structure Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    local8 = Cast(c2fb_c_int, &O0ULL)
    If arg2 Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5Get32(arg0))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
    local1 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(Const Any Ptr, StrPtr(!"\255\000\000\001")), Cast(c2fb_c_int, 4ULL)))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 4ULL))))
        local1 = c2fb_temp_3
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local7 = c2fb_temp_4
    End If
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local3))))))))
    local1 = c2fb_temp_5
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local4))))))))
    local1 = c2fb_temp_6
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, 2000ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 > Cast(c2fb_c_int, 2000ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    c2fb_temp_7 = Cast(c2fb_int64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5Structure_aLevel_tail_ptr(Cast(c2fb_Fts5Structure Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (local3)) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureLevel)))))))))
    local5 = c2fb_temp_7
    c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), local5))))
    local6 = c2fb_temp_8
    If local6 Then
        c2fb_temp_9 = CPtr(Long Ptr, @(local6->nRef))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
        c2fb_temp_11 = CPtr(Long Ptr, @(local6->nLevel))
        c2fb_temp_12 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
        c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        c2fb_temp_13 = CPtr(Long Ptr, @(local6->nSegment))
        c2fb_temp_14 = Cast(c2fb_c_int, local4)
        (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
        c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_uint64 Ptr, @(local6->nWriteCounter)))))))
        local1 = c2fb_temp_15
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_16
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < local3)))) <> 0)))))
            local9 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local6)))[local2]))
            local10 = Cast(c2fb_c_int, &O0ULL)
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((local1 >= arg1)))) Then
                c2fb_temp_18 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                local0 = c2fb_temp_18
            Else
                c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local9->nMerge))))))))
                local1 = c2fb_temp_19
                c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local10))))))))
                local1 = c2fb_temp_20
                If (-Cast(c2fb_c_int, ((local10 < local9->nMerge)))) Then
                    c2fb_temp_21 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local0 = c2fb_temp_21
                End If
                c2fb_temp_22 = CPtr(c2fb_Fts5StructureSegment_ Ptr Ptr, @(local9->aSeg))
                c2fb_temp_23 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, local10)) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureSegment)))))))))
                (*c2fb_temp_22) = CPtr(c2fb_Fts5StructureSegment_ Ptr, c2fb_temp_23)
                c2fb_temp_23 = CPtr(c2fb_Fts5StructureSegment Ptr, (*c2fb_temp_22))
                c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 - local10)))
                local4 = c2fb_temp_24
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_25 = CPtr(Long Ptr, @(local9->nSeg))
                c2fb_temp_26 = Cast(c2fb_c_int, local10)
                (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
                c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
                c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local11 = c2fb_temp_27
                While (-Cast(c2fb_c_int, ((local11 < local10))))
                    local12 = CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local9->aSeg))[local11]))
#ifdef SQLITE_DEBUG
                    If local12 = 0 Then sqlite3DebugAssert(StrPtr(!"pSeg!=0"))
#endif
                    If (-Cast(c2fb_c_int, ((local1 >= arg1)))) Then
                        c2fb_temp_29 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                        local0 = c2fb_temp_29
                        Goto c2fb_flow_2
                    End If
                    ' C unused-parameter annotation
                    c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local12->iSegid))))))))
                    local1 = c2fb_temp_30
                    c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local12->pgnoFirst))))))))
                    local1 = c2fb_temp_31
                    c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local12->pgnoLast))))))))
                    local1 = c2fb_temp_32
                    If local7 Then
                        c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_uint64 Ptr, @(local12->iOrigin1)))))))
                        local1 = c2fb_temp_33
                        c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_uint64 Ptr, @(local12->iOrigin2)))))))
                        local1 = c2fb_temp_34
                        c2fb_temp_35 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local12->nPgTombstone))))))))
                        local1 = c2fb_temp_35
                        c2fb_temp_36 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_uint64 Ptr, @(local12->nEntryTombstone)))))))
                        local1 = c2fb_temp_36
                        c2fb_temp_37 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local1]))), CPtr(c2fb_uint64 Ptr, @(local12->nEntry)))))))
                        local1 = c2fb_temp_37
                        c2fb_temp_38 = Cast(c2fb_uint64, (IIf(((-Cast(c2fb_c_int, (((local8) > (local12->iOrigin2)))))), (local8), (local12->iOrigin2))))
                        local8 = c2fb_temp_38
                    End If
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local12->pgnoLast < local12->pgnoFirst)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local12->pgnoLast > Cast(c2fb_c_int, &H7FFFFF00ULL))))) <> 0))))) Then
                        c2fb_temp_39 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                        local0 = c2fb_temp_39
                        Goto c2fb_flow_2
                    End If
                c2fb_flow_3:
                    c2fb_temp_28 = local11
                    local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
                Wend
                c2fb_flow_2:
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_Fts5StructureLevel Ptr, local9)[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].nMerge <> 0) AndAlso ((-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_40 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local0 = c2fb_temp_40
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, 1ULL))))))) <> 0) AndAlso (local9->nMerge <> 0))))) Then
                    c2fb_temp_41 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                    local0 = c2fb_temp_41
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_17 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_42 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            local0 = c2fb_temp_42
        End If
        If local7 Then
            c2fb_temp_43 = CPtr(c2fb_u64 Ptr, @(local6->nOriginCntr))
            c2fb_temp_44 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local8 + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))
            (*c2fb_temp_43) = Cast(c2fb_u64, c2fb_temp_44)
            c2fb_temp_44 = Cast(c2fb_uint64, (*c2fb_temp_43))
        End If
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            fts5StructureRelease(local6)
            c2fb_temp_45 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local6 = c2fb_temp_45
        End If
    End If
    c2fb_temp_46 = CPtr(c2fb_Fts5Structure Ptr Ptr, @((*arg3)))
    c2fb_temp_47 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local6)
    (*c2fb_temp_46) = c2fb_temp_47
    Return local0
End Function
Private Sub fts5StructureAddLevel CDecl Alias "fts5StructureAddLevel" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1234
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_Fts5Structure Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    fts5StructureMakeWritable(arg0, arg1)
#ifdef SQLITE_DEBUG
    If (arg1 = 0 OrElse arg1[0] = 0) AndAlso (*arg0) = SQLITE_OK Then _
        sqlite3DebugAssert(StrPtr(!"(ppStruct!=0 && (*ppStruct)!=0) || (*pRc)!=SQLITE_OK"))
#endif
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = (*arg1)
        local1 = local0->nLevel
        local2 = (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5Structure_aLevel_tail_ptr(Cast(c2fb_Fts5Structure Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 2ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureLevel))))))))
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local0), local2)))
        local0 = c2fb_temp_0
        If local0 Then
            c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local0)))[local1]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureLevel))))
            c2fb_temp_2 = CPtr(Long Ptr, @(local0->nLevel))
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            (*c2fb_temp_2) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            c2fb_temp_4 = CPtr(c2fb_Fts5Structure Ptr Ptr, @((*arg1)))
            c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local0)
            (*c2fb_temp_4) = c2fb_temp_5
        Else
            c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_6) = c2fb_temp_7
        End If
    End If
End Sub
Private Sub fts5StructureExtendLevel CDecl Alias "fts5StructureExtendLevel" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1257
    Dim local0 As c2fb_Fts5StructureLevel Ptr
    Dim local1 As c2fb_Fts5StructureSegment Ptr
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_Fts5StructureSegment_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[arg2]))
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local0->nSeg + arg3)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureSegment))))))
        local2 = c2fb_temp_0
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local0->aSeg)), local2)))
        local1 = c2fb_temp_1
        If local1 Then
            If (-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, local1)[local0->nSeg]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureSegment))) * Cast(c2fb_uint64, arg3)))))
            Else
                local3 = Cast(c2fb_uint64, (Cast(c2fb_uint64, local0->nSeg) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureSegment)))))
                c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, local1)[arg3]))), CPtr(Const Any Ptr, local1), local3))
                c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureSegment))) * Cast(c2fb_uint64, arg3)))))
            End If
            c2fb_temp_5 = CPtr(c2fb_Fts5StructureSegment_ Ptr Ptr, @(local0->aSeg))
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, local1)
            (*c2fb_temp_5) = CPtr(c2fb_Fts5StructureSegment_ Ptr, c2fb_temp_6)
            c2fb_temp_6 = CPtr(c2fb_Fts5StructureSegment Ptr, (*c2fb_temp_5))
        Else
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_7) = c2fb_temp_8
        End If
    End If
End Sub
Private Function fts5StructureReadUncached CDecl Alias "fts5StructureReadUncached" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_Fts5Structure Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1286
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_Fts5Structure Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, Cast(c2fb_c_int, 10ULL))))
    local3 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(UByte Ptr, @(local3->p[local3->nn]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 20ULL)))
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_3 = Cast(c2fb_c_int, fts5StructureDecode(CPtr(Const UByte Ptr, local3->p), local3->nn, CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_Fts5Structure Ptr Ptr, @(local0))))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            If ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->pgsz = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1->iCookie <> local2)))) <> 0)))))) Then
                c2fb_temp_4 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5ConfigLoad(local1, local2))
                (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
                c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            End If
        Else
            If (-Cast(c2fb_c_int, ((arg0->rc = (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))))) Then
                c2fb_external_sqlite3Fts5ConfigErrmsg(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig), StrPtr(!"fts5: corrupt structure record for table \034%s\034"), CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->zName)
            End If
        End If
        fts5DataRelease(local3)
        If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
            fts5StructureRelease(local0)
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_6
        End If
    End If
    Return local0
End Function
Private Function fts5IndexDataVersion CDecl Alias "fts5IndexDataVersion" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_int64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1316
    Dim local0 As c2fb_int64
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDataVersion) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_1 = Cast(c2fb_c_int, fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pDataVersion)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"PRAGMA %Q.data_version"), CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->zDb))))
            (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
            c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
            If arg0->rc Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        End If
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = sqlite3_step(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDataVersion))))))) Then
            c2fb_temp_2 = Cast(c2fb_int64, sqlite3_column_int64(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDataVersion)), Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_2
        End If
        c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_4 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDataVersion))))
        (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    End If
    Return local0
End Function
Private Function fts5StructureRead CDecl Alias "fts5StructureRead" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_Fts5Structure Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1347
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_Fts5Structure_ Ptr Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Structure Ptr

    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->iStructVersion))
        c2fb_temp_1 = Cast(c2fb_int64, fts5IndexDataVersion(arg0))
        (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(c2fb_Fts5Structure_ Ptr Ptr, @(arg0->pStruct))
            c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureReadUncached(arg0)))
            (*c2fb_temp_2) = CPtr(c2fb_Fts5Structure_ Ptr, c2fb_temp_3)
            c2fb_temp_3 = CPtr(c2fb_Fts5Structure Ptr, (*c2fb_temp_2))
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
#ifdef SQLITE_DEBUG
    If arg0->iStructVersion = 0 Then _
        sqlite3DebugAssert(StrPtr(!"p->iStructVersion!=0"))
    If CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct) = 0 Then _
        sqlite3DebugAssert(StrPtr(!"p->pStruct!=0"))
#endif
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    fts5StructureRef(CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct))
    Return CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct)
End Function
Private Sub fts5StructureInvalidate CDecl Alias "fts5StructureInvalidate" (ByVal arg0 As c2fb_Fts5Index Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1386
    Dim c2fb_temp_0 As c2fb_Fts5Structure_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Structure Ptr

    If CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct) Then
        fts5StructureRelease(CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct))
        c2fb_temp_0 = CPtr(c2fb_Fts5Structure_ Ptr Ptr, @(arg0->pStruct))
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = CPtr(c2fb_Fts5Structure_ Ptr, c2fb_temp_1)
        c2fb_temp_1 = CPtr(c2fb_Fts5Structure Ptr, (*c2fb_temp_0))
    End If
End Sub
#ifdef SQLITE_DEBUG
Private Function fts5StructureCountSegments CDecl Alias "fts5StructureCountSegments" (ByVal arg0 As c2fb_Fts5Structure Ptr) As c2fb_c_int
    Dim nSegment As c2fb_c_int = 0

    If arg0 <> 0 Then
        For iLevel As c2fb_c_int = 0 To arg0->nLevel - 1
            Dim pLevel As c2fb_Fts5StructureLevel Ptr = _
                CPtr(c2fb_Fts5StructureLevel Ptr, _
                    c2fb_Fts5Structure_aLevel_tail_ptr(arg0)) + iLevel
            nSegment += pLevel->nSeg
        Next
    End If

    Return nSegment
End Function
#endif
Private Sub fts5StructureWrite CDecl Alias "fts5StructureWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1429
    Dim local0 As c2fb_Fts5Buffer
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local6 As c2fb_Fts5StructureSegment Ptr

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
#ifdef SQLITE_DEBUG
        If arg1->nSegment <> fts5StructureCountSegments(arg1) Then _
            sqlite3DebugAssert(StrPtr(!"pStruct->nSegment==fts5StructureCountSegments(pStruct)"))
#endif
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        local3 = (IIf((-Cast(c2fb_c_int, ((arg1->nOriginCntr > Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))), (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, 4ULL))) + Cast(c2fb_c_int, 9ULL))) + Cast(c2fb_c_int, 9ULL))) + Cast(c2fb_c_int, 9ULL)))), (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + Cast(c2fb_c_int, 9ULL))) + Cast(c2fb_c_int, 9ULL))))))
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
        c2fb_temp_1 = Cast(c2fb_c_int, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->iCookie)
        local2 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_2
        End If
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3Fts5BufferSize(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), local3))))) Then
            c2fb_external_sqlite3Fts5Put32(local0.p, local2)
            c2fb_temp_3 = CPtr(Long Ptr, @(local0.n))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            If (-Cast(c2fb_c_int, ((arg1->nOriginCntr > Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
                ' C unused-parameter annotation
                c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->n]))), CPtr(Const Any Ptr, StrPtr(!"\255\000\000\001")), Cast(c2fb_c_int, 4ULL)))
                c2fb_temp_6 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->n))
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_6)) + Cast(c2fb_c_int, 4ULL))))
                (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
                c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
                ' empty C statement
            End If
            c2fb_temp_8 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->n))
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_8)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->n])), (arg1->nLevel)))))
            (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
            c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
            ' C unused-parameter annotation
            ' empty C statement
            c2fb_temp_10 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->n))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_10)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->n])), (arg1->nSegment)))))
            (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
            ' C unused-parameter annotation
            ' empty C statement
            c2fb_temp_12 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->n))
            c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_12)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local0)))->n])), (Cast(c2fb_int64, arg1->nWriteCounter))))))
            (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
            c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
            ' C unused-parameter annotation
            ' empty C statement
        End If
        c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_14
        While (-Cast(c2fb_c_int, ((local1 < arg1->nLevel))))
            ' C automatic storage declaration
            local5 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[local1]))
            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local5->nMerge))
            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local5->nSeg))
            ' C unused-parameter annotation
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local4 = c2fb_temp_16
            While (-Cast(c2fb_c_int, ((local4 < local5->nSeg))))
                local6 = CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local5->aSeg))[local4]))
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local6->iSegid))
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local6->pgnoFirst))
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local6->pgnoLast))
                If (-Cast(c2fb_c_int, ((arg1->nOriginCntr > Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
                    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local6->iOrigin1))
                    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local6->iOrigin2))
                    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local6->nPgTombstone))
                    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local6->nEntryTombstone))
                    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0)), Cast(c2fb_int64, local6->nEntry))
                End If
            c2fb_flow_3:
                c2fb_temp_17 = local4
                local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
            Wend
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_15 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
        Wend
        c2fb_flow_0:
        fts5DataWrite(arg0, Cast(c2fb_c_int, 10ULL), CPtr(Const UByte Ptr, local0.p), local0.n)
        c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local0)))
    End If
End Sub
Private Function fts5SegmentSize CDecl Alias "fts5SegmentSize" (ByVal arg0 As c2fb_Fts5StructureSegment Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1496
    Return Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + arg0->pgnoLast)) - arg0->pgnoFirst))
End Function
Private Sub fts5StructurePromoteTo CDecl Alias "fts5StructurePromoteTo" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Structure Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1505
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg3)))[arg1]))
    If (-Cast(c2fb_c_int, ((local2->nMerge = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1 + Cast(c2fb_c_int, 1ULL))))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg3->nLevel))))
            local3 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg3)))[local0]))
            If local3->nMerge Then
                Return
            End If
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3->nSeg - Cast(c2fb_c_int, 1ULL))))
            local1 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL)))))
                local4 = fts5SegmentSize(CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local3->aSeg))[local1])))
                If (-Cast(c2fb_c_int, ((local4 > arg2)))) Then
                    Return
                End If
                fts5StructureExtendLevel(CPtr(c2fb_c_int Ptr, @(arg0->rc)), arg3, arg1, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, 1ULL))
                If arg0->rc Then
                    Return
                End If
                c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local2->aSeg)), CPtr(Const Any Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local3->aSeg))[local1]))), Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureSegment))))
                c2fb_temp_5 = CPtr(Long Ptr, @(local2->nSeg))
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
                (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
                c2fb_temp_7 = CPtr(Long Ptr, @(local3->nSeg))
                c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                (*c2fb_temp_7) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 - 1)))
            c2fb_flow_3:
                c2fb_temp_3 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
            Wend
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
    End If
End Sub
Private Sub fts5StructurePromote CDecl Alias "fts5StructurePromote" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5Structure Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1548
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5StructureSegment Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        local1 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
        local2 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        ' C automatic storage declaration
        local5 = CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg2)))[arg1].nSeg
        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return
        End If
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg2)))[arg1].aSeg[(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg2)))[arg1].nSeg - Cast(c2fb_c_int, 1ULL))]))
        local3 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + local3->pgnoLast)) - local3->pgnoFirst))))
        local4 = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, 1ULL))))
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg2)))[local0].nSeg = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            ' empty C statement
        c2fb_flow_1:
            c2fb_temp_3 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg2)))[local0]))
            ' C unused-parameter annotation
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local6 = c2fb_temp_4
            While (-Cast(c2fb_c_int, ((local6 < local8->nSeg))))
                local9 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local8->aSeg))[local6].pgnoLast - CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local8->aSeg))[local6].pgnoFirst)) + Cast(c2fb_c_int, 1ULL)))
                If (-Cast(c2fb_c_int, ((local9 > local7)))) Then
                    c2fb_temp_6 = Cast(c2fb_c_int, local9)
                    local7 = c2fb_temp_6
                End If
            c2fb_flow_3:
                c2fb_temp_5 = local6
                local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
            Wend
            c2fb_flow_2:
            If (-Cast(c2fb_c_int, ((local7 >= local4)))) Then
                c2fb_temp_7 = Cast(c2fb_c_int, local0)
                local1 = c2fb_temp_7
                c2fb_temp_8 = Cast(c2fb_c_int, local7)
                local2 = c2fb_temp_8
            End If
        End If
        If (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_9 = Cast(c2fb_c_int, arg1)
            local1 = c2fb_temp_9
            c2fb_temp_10 = Cast(c2fb_c_int, local4)
            local2 = c2fb_temp_10
        End If
        fts5StructurePromoteTo(arg0, local1, local2, arg2)
    End If
End Sub
Private Function fts5DlidxLvlNext CDecl Alias "fts5DlidxLvlNext" (ByVal arg0 As c2fb_Fts5DlidxLvl Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1599
    Dim local0 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local2 As c2fb_uint64
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_i64 Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Data Ptr, arg0->pData)
    If (-Cast(c2fb_c_int, ((arg0->iOff = Cast(c2fb_c_int, &O0ULL))))) Then
#ifdef SQLITE_DEBUG
        If arg0->bEof <> 0 Then sqlite3DebugAssert(StrPtr(!"pLvl->bEof==0"))
#endif
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->iOff))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->iOff))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_2)) + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->p[Cast(c2fb_c_int, 1ULL)]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((arg0->iLeafPgno))))))))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        c2fb_temp_4 = CPtr(Long Ptr, @(arg0->iOff))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_4)) + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->p[arg0->iOff]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg0->iRowid))))))))
        (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
        c2fb_temp_6 = CPtr(Long Ptr, @(arg0->iFirstOff))
        c2fb_temp_7 = Cast(c2fb_c_int, arg0->iOff)
        (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    Else
        ' C automatic storage declaration
        c2fb_temp_8 = Cast(c2fb_c_int, arg0->iOff)
        local1 = c2fb_temp_8
        While (-Cast(c2fb_c_int, ((local1 < local0->nn))))
            If local0->p[local1] Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_9 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local1 < local0->nn)))) Then
            ' C automatic storage declaration
            c2fb_temp_10 = CPtr(Long Ptr, @(arg0->iLeafPgno))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_10)) + Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local1 - arg0->iOff))) + Cast(c2fb_c_int, 1ULL))))))
            (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->p[local1]))), CPtr(c2fb_uint64 Ptr, @(local2)))))))
            local1 = c2fb_temp_12
            c2fb_temp_13 = CPtr(c2fb_i64 Ptr, @(arg0->iRowid))
            c2fb_temp_14 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_13))) + local2)))
            (*c2fb_temp_13) = Cast(c2fb_i64, c2fb_temp_14)
            c2fb_temp_14 = Cast(c2fb_int64, (*c2fb_temp_13))
            c2fb_temp_15 = CPtr(Long Ptr, @(arg0->iOff))
            c2fb_temp_16 = Cast(c2fb_c_int, local1)
            (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
            c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
        Else
            c2fb_temp_17 = CPtr(Long Ptr, @(arg0->bEof))
            c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
            c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
        End If
    End If
    Return arg0->bEof
End Function
Private Function fts5DlidxIterNextR CDecl Alias "fts5DlidxIterNextR" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1631
    Dim local0 As c2fb_Fts5DlidxLvl Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Data Ptr

#ifdef SQLITE_DEBUG
    If arg2 >= arg1->nLvl Then sqlite3DebugAssert(StrPtr(!"iLvl<pIter->nLvl"))
#endif
    local0 = CPtr(c2fb_Fts5DlidxLvl Ptr, @(CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg1)))[arg2]))
    ' C unused-parameter annotation
    If fts5DlidxLvlNext(local0) Then
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))) < arg1->nLvl)))) Then
            fts5DlidxIterNextR(arg0, arg1, Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))))
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5DlidxLvl Ptr, local0)[Cast(c2fb_c_int, 1ULL)].bEof = Cast(c2fb_c_int, &O0ULL))))) Then
                fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, local0->pData))
                c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5DlidxLvl))))
                c2fb_temp_1 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(local0->pData))
                c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (arg2)) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (CPtr(c2fb_Fts5DlidxLvl Ptr, local0)[Cast(c2fb_c_int, 1ULL)].iLeafPgno)))))))))
                (*c2fb_temp_1) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_2)
                c2fb_temp_2 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_1))
                If CPtr(c2fb_Fts5Data Ptr, local0->pData) Then
                    fts5DlidxLvlNext(local0)
                End If
            End If
        End If
    End If
    Return CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)].bEof
End Function
Private Function fts5DlidxIterNext CDecl Alias "fts5DlidxIterNext" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1651
    Return fts5DlidxIterNextR(arg0, arg1, Cast(c2fb_c_int, &O0ULL))
End Function
Private Function fts5DlidxIterFirst CDecl Alias "fts5DlidxIterFirst" (ByVal arg0 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1666
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0->nLvl))))
        fts5DlidxLvlNext(CPtr(c2fb_Fts5DlidxLvl Ptr, @(CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg0)))[local0])))
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg0)))[Cast(c2fb_c_int, &O0ULL)].bEof
End Function
Private Function fts5DlidxIterEof CDecl Alias "fts5DlidxIterEof" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
    Dim pLevel As c2fb_Fts5DlidxLvl Ptr

    pLevel = CPtr(c2fb_Fts5DlidxLvl Ptr, c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg1))
    Return IIf(arg0->rc <> 0 OrElse pLevel->bEof <> 0, 1, 0)
End Function

Private Sub fts5DlidxIterLast CDecl Alias "fts5DlidxIterLast" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1679
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_Fts5DlidxLvl Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local2 As c2fb_Fts5DlidxLvl Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_Fts5Data Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->nLvl - Cast(c2fb_c_int, 1ULL))))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        local1 = CPtr(c2fb_Fts5DlidxLvl Ptr, @(CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg1)))[local0]))
        While (-Cast(c2fb_c_int, ((fts5DlidxLvlNext(local1) = Cast(c2fb_c_int, &O0ULL)))))
            ' empty C statement
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_2 = CPtr(Long Ptr, @(local1->bEof))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        If (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, &O0ULL))))) Then
            local2 = CPtr(c2fb_Fts5DlidxLvl Ptr, @(CPtr(c2fb_Fts5DlidxLvl Ptr, local1)[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))]))
            fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, local2->pData))
            c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5DlidxLvl))))
            c2fb_temp_5 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(local2->pData))
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL))))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local1->iLeafPgno)))))))))
            (*c2fb_temp_5) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_6)
            c2fb_temp_6 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_5))
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
    Wend
    c2fb_flow_0:
End Sub
Private Function fts5DlidxLvlPrev CDecl Alias "fts5DlidxLvlPrev" (ByVal arg0 As c2fb_Fts5DlidxLvl Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1702
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_uint64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_i64 Ptr
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int

    local0 = arg0->iOff
#ifdef SQLITE_DEBUG
    If arg0->bEof <> 0 Then sqlite3DebugAssert(StrPtr(!"pLvl->bEof==0"))
#endif
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0 <= arg0->iFirstOff)))) Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->bEof))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    Else
        local1 = CPtr(c2fb_Fts5Data Ptr, arg0->pData)->p
        local2 = CPtr(c2fb_Fts5Data Ptr, arg0->pData)->nn
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->iOff))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        fts5DlidxLvlNext(arg0)
        While Cast(c2fb_c_int, 1ULL)
            local3 = Cast(c2fb_c_int, &O0ULL)
            local4 = arg0->iOff
            local5 = Cast(c2fb_c_int, &O0ULL)
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < local2)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1[local4]) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                c2fb_temp_4 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
                c2fb_temp_5 = local4
                local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1[local4]))), CPtr(c2fb_uint64 Ptr, @(local5)))))))
            local4 = c2fb_temp_6
            If (-Cast(c2fb_c_int, ((local4 >= local0)))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_7 = CPtr(Long Ptr, @(arg0->iLeafPgno))
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_7)) + Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))))
            (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
            c2fb_temp_9 = CPtr(c2fb_i64 Ptr, @(arg0->iRowid))
            c2fb_temp_10 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_9))) + local5)))
            (*c2fb_temp_9) = Cast(c2fb_i64, c2fb_temp_10)
            c2fb_temp_10 = Cast(c2fb_int64, (*c2fb_temp_9))
            c2fb_temp_11 = CPtr(Long Ptr, @(arg0->iOff))
            c2fb_temp_12 = Cast(c2fb_c_int, local4)
            (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
    Return arg0->bEof
End Function
Private Function fts5DlidxIterPrevR CDecl Alias "fts5DlidxIterPrevR" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1735
    Dim local0 As c2fb_Fts5DlidxLvl Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int

#ifdef SQLITE_DEBUG
    If arg2 >= arg1->nLvl Then sqlite3DebugAssert(StrPtr(!"iLvl<pIter->nLvl"))
#endif
    local0 = CPtr(c2fb_Fts5DlidxLvl Ptr, @(CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg1)))[arg2]))
    ' C unused-parameter annotation
    If fts5DlidxLvlPrev(local0) Then
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))) < arg1->nLvl)))) Then
            fts5DlidxIterPrevR(arg0, arg1, Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))))
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5DlidxLvl Ptr, local0)[Cast(c2fb_c_int, 1ULL)].bEof = Cast(c2fb_c_int, &O0ULL))))) Then
                fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, local0->pData))
                c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5DlidxLvl))))
                c2fb_temp_1 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(local0->pData))
                c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (arg2)) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (CPtr(c2fb_Fts5DlidxLvl Ptr, local0)[Cast(c2fb_c_int, 1ULL)].iLeafPgno)))))))))
                (*c2fb_temp_1) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_2)
                c2fb_temp_2 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_1))
                If CPtr(c2fb_Fts5Data Ptr, local0->pData) Then
                    While (-Cast(c2fb_c_int, ((fts5DlidxLvlNext(local0) = Cast(c2fb_c_int, &O0ULL)))))
                        ' empty C statement
                    c2fb_flow_1:
                    Wend
                    c2fb_flow_0:
                    c2fb_temp_3 = CPtr(Long Ptr, @(local0->bEof))
                    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
                    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
                End If
            End If
        End If
    End If
    Return CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)].bEof
End Function
Private Function fts5DlidxIterPrev CDecl Alias "fts5DlidxIterPrev" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1758
    Return fts5DlidxIterPrevR(arg0, arg1, Cast(c2fb_c_int, &O0ULL))
End Function
Private Sub fts5DlidxIterFree CDecl Alias "fts5DlidxIterFree" (ByVal arg0 As c2fb_Fts5DlidxIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1765
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nLvl))))
            fts5DataRelease(CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg0)))[local0].pData)
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Private Function fts5DlidxIterInit CDecl Alias "fts5DlidxIterInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_Fts5DlidxIter Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1775
    Dim local0 As c2fb_Fts5DlidxIter Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_Fts5DlidxIter Ptr
    Dim c2fb_temp_2 As c2fb_Fts5DlidxIter Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_Fts5DlidxLvl Ptr
    Dim c2fb_temp_5 As c2fb_Fts5DlidxIter Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_Fts5DlidxIter Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        local3 = (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5DlidxIter_aLvl_tail_ptr(Cast(c2fb_Fts5DlidxIter Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5DlidxLvl))))))))
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5DlidxIter Ptr, CPtr(c2fb_Fts5DlidxIter Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, local0), local3))))
        local4 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        Else
            local5 = (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg2)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (local1)) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (arg3))))))
            local6 = CPtr(c2fb_Fts5DlidxLvl Ptr, @(CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(local4)))[local1]))
            c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5DlidxIter Ptr, local4)
            local0 = c2fb_temp_5
            c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local6), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5DlidxLvl))))
            c2fb_temp_7 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(local6->pData))
            c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, local5)))
            (*c2fb_temp_7) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_8)
            c2fb_temp_8 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_7))
            If (-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Data Ptr, local6->pData) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(c2fb_Fts5Data Ptr, local6->pData)->p[Cast(c2fb_c_int, &O0ULL)]) And Cast(c2fb_c_int, &H0001ULL)))) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local2 = c2fb_temp_9
            End If
            c2fb_temp_10 = CPtr(Long Ptr, @(local0->nLvl))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
            If (-Cast(c2fb_c_int, ((local0->nLvl > (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 5ULL)))))))) Then
                c2fb_temp_12 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_13 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
                c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_14 = CPtr(Long Ptr, @(local0->iSegid))
        c2fb_temp_15 = Cast(c2fb_c_int, arg2)
        (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
            fts5DlidxIterFirst(local0)
        Else
            fts5DlidxIterLast(arg0, local0)
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        fts5DlidxIterFree(local0)
        c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5DlidxIter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_16
    End If
    Return local0
End Function
Private Function fts5DlidxIterRowid CDecl Alias "fts5DlidxIterRowid" (ByVal arg0 As c2fb_Fts5DlidxIter Ptr) As c2fb_int64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1825
    Return CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg0)))[Cast(c2fb_c_int, &O0ULL)].iRowid
End Function
Private Function fts5DlidxIterPgno CDecl Alias "fts5DlidxIterPgno" (ByVal arg0 As c2fb_Fts5DlidxIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1828
    Return CPtr(c2fb_Fts5DlidxLvl Ptr, (c2fb_Fts5DlidxIter_aLvl_tail_ptr(arg0)))[Cast(c2fb_c_int, &O0ULL)].iLeafPgno
End Function
Private Sub fts5SegIterNextPage CDecl Alias "fts5SegIterNextPage" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1835
    Dim local0 As c2fb_Fts5Data Ptr
    Dim local1 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_6 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_10 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)
    fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))
    c2fb_temp_0 = CPtr(Long Ptr, @(arg1->iLeafPgno))
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    If CPtr(c2fb_Fts5Data Ptr, arg1->pNextLeaf) Then
        c2fb_temp_2 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
        c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, arg1->pNextLeaf))
        (*c2fb_temp_2) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_3)
        c2fb_temp_3 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_2))
        c2fb_temp_4 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pNextLeaf))
        c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_4) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_5)
        c2fb_temp_5 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_4))
    Else
        If (-Cast(c2fb_c_int, ((arg1->iLeafPgno <= local1->pgnoLast)))) Then
            c2fb_temp_6 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (arg1->iLeafPgno)))))))))
            (*c2fb_temp_6) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_7)
            c2fb_temp_7 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_6))
        Else
            c2fb_temp_8 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
            c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_8) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_9)
            c2fb_temp_9 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_8))
        End If
    End If
    c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))
    local0 = c2fb_temp_10
    If local0 Then
        c2fb_temp_11 = CPtr(Long Ptr, @(arg1->iPgidxOff))
        c2fb_temp_12 = Cast(c2fb_c_int, local0->szLeaf)
        (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
        c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        If ((-Cast(c2fb_c_int, (((local0)->szLeaf >= (local0)->nn))))) Then
            c2fb_temp_13 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0->nn + Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
            c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
        Else
            c2fb_temp_15 = CPtr(Long Ptr, @(arg1->iPgidxOff))
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_15)) + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->p[arg1->iPgidxOff]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((arg1->iEndofDoclist))))))))
            (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
            c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
        End If
    End If
End Sub
Private Function fts5GetPoslistSize CDecl Alias "fts5GetPoslistSize" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1873
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = local1
    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
    c2fb_temp_1 = Cast(c2fb_c_int, (arg0)[c2fb_temp_0])
    local0 = c2fb_temp_1
    If Cast(c2fb_c_int, (local0 And Cast(c2fb_c_int, &H80ULL))) Then
        c2fb_temp_2 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 - 1)))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((arg0)[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local0))))))))
        local1 = c2fb_temp_3
    End If
    ' empty C statement
    ' C unused-parameter annotation
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 \ Cast(c2fb_c_int, 2ULL))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 And Cast(c2fb_c_int, &H0001ULL))))
    (*c2fb_temp_6) = c2fb_temp_7
    Return local1
End Function
Private Sub fts5SegIterLoadNPos CDecl Alias "fts5SegIterLoadNPos" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1894
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_u8 Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_u8 Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_u8 Ptr
    Dim c2fb_temp_17 As UByte
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_i64 Ptr
    Dim c2fb_temp_21 As c2fb_int64

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = arg1->iLeafOffset
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, 1ULL))))) Then
            local1 = (IIf(((-Cast(c2fb_c_int, (((arg1->iEndofDoclist) < (CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf)))))), (arg1->iEndofDoclist), (CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf)))
            c2fb_temp_0 = CPtr(c2fb_u8 Ptr, @(arg1->bDel))
            c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_0) = Cast(c2fb_u8, c2fb_temp_1)
            c2fb_temp_1 = Cast(UByte, (*c2fb_temp_0))
            c2fb_temp_2 = CPtr(Long Ptr, @(arg1->nPos))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < local1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[local0]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_4 = CPtr(c2fb_u8 Ptr, @(arg1->bDel))
                c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_4) = Cast(c2fb_u8, c2fb_temp_5)
                c2fb_temp_5 = Cast(UByte, (*c2fb_temp_4))
                c2fb_temp_6 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < local1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[local0]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_7 = CPtr(Long Ptr, @(arg1->nPos))
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
                    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                    c2fb_temp_9 = local0
                    local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
                Else
                    c2fb_temp_10 = CPtr(Long Ptr, @(arg1->nPos))
                    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
                    c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                End If
            End If
        Else
            ' C automatic storage declaration
            c2fb_temp_12 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
            c2fb_temp_13 = Cast(c2fb_c_int, (CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p)[c2fb_temp_12])
            local2 = c2fb_temp_13
            If Cast(c2fb_c_int, (local2 And Cast(c2fb_c_int, &H80ULL))) Then
                c2fb_temp_14 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 - 1)))
                c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p)[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local2))))))))
                local0 = c2fb_temp_15
            End If
            ' empty C statement
            c2fb_temp_16 = CPtr(c2fb_u8 Ptr, @(arg1->bDel))
            c2fb_temp_17 = Cast(UByte, (Cast(c2fb_c_int, (local2 And Cast(c2fb_c_int, &H0001ULL)))))
            (*c2fb_temp_16) = Cast(c2fb_u8, c2fb_temp_17)
            c2fb_temp_17 = Cast(UByte, (*c2fb_temp_16))
            c2fb_temp_18 = CPtr(Long Ptr, @(arg1->nPos))
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 Shr Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
            c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
            ' C unused-parameter annotation
        End If
        c2fb_temp_20 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
        c2fb_temp_21 = Cast(c2fb_int64, local0)
        (*c2fb_temp_20) = Cast(c2fb_i64, c2fb_temp_21)
        c2fb_temp_21 = Cast(c2fb_int64, (*c2fb_temp_20))
    End If
End Sub
Private Sub fts5SegIterLoadRowid CDecl Alias "fts5SegIterLoadRowid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1923
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_i64 Ptr
    Dim c2fb_temp_4 As c2fb_int64

    local0 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p
    local1 = arg1->iLeafOffset
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_int64, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf)))))
        fts5SegIterNextPage(arg0, arg1)
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                fts5IndexCorruptIter(arg0, arg1)
            End If
            Return
        End If
        c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL))
        local1 = c2fb_temp_0
        c2fb_temp_1 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p
        local0 = c2fb_temp_1
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0[local1]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg1->iRowid))))))))
    local1 = c2fb_temp_2
    c2fb_temp_3 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
    c2fb_temp_4 = Cast(c2fb_int64, local1)
    (*c2fb_temp_3) = Cast(c2fb_i64, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_int64, (*c2fb_temp_3))
End Sub
Private Sub fts5SegIterLoadTerm CDecl Alias "fts5SegIterLoadTerm" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1956
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_i64 Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p
    local1 = arg1->iLeafOffset
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local2)))))))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_int64, (local1 + Cast(c2fb_int64, local2))) > Cast(c2fb_int64, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2 > arg1->term.n)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        fts5IndexCorruptIter(arg0, arg1)
        Return
    End If
    c2fb_temp_1 = CPtr(Long Ptr, @(arg1->term.n))
    c2fb_temp_2 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg1->term)), local2, CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0[local1]))))
    ' C unused-parameter annotation
    c2fb_temp_3 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 + Cast(c2fb_int64, local2))))
    local1 = c2fb_temp_3
    c2fb_temp_4 = CPtr(Long Ptr, @(arg1->iTermLeafOffset))
    c2fb_temp_5 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(Long Ptr, @(arg1->iTermLeafPgno))
    c2fb_temp_7 = Cast(c2fb_c_int, arg1->iLeafPgno)
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
    c2fb_temp_9 = Cast(c2fb_int64, local1)
    (*c2fb_temp_8) = Cast(c2fb_i64, c2fb_temp_9)
    c2fb_temp_9 = Cast(c2fb_int64, (*c2fb_temp_8))
    If (-Cast(c2fb_c_int, ((arg1->iPgidxOff >= CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->nn)))) Then
        c2fb_temp_10 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->nn + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
    Else
        ' C automatic storage declaration
        c2fb_temp_12 = CPtr(Long Ptr, @(arg1->iPgidxOff))
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_12)) + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0[arg1->iPgidxOff]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local3))))))))
        (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
        c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
        c2fb_temp_14 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_14)) + local3)))
        (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
    End If
    fts5SegIterLoadRowid(arg0, arg1)
End Sub
Private Sub fts5SegIterSetNext CDecl Alias "fts5SegIterSetNext" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 1989
    Type c2fb_callback_storage_0 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5SegIter_ Ptr, ByVal arg2 As Long Ptr)
    Dim c2fb_temp_0 As c2fb_callback_storage_0 Ptr
    Dim c2fb_temp_1 As c2fb_callback_348
    Type c2fb_callback_storage_2 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5SegIter_ Ptr, ByVal arg2 As Long Ptr)
    Dim c2fb_temp_2 As c2fb_callback_storage_2 Ptr
    Dim c2fb_temp_3 As c2fb_callback_348
    Type c2fb_callback_storage_4 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5SegIter_ Ptr, ByVal arg2 As Long Ptr)
    Dim c2fb_temp_4 As c2fb_callback_storage_4 Ptr
    Dim c2fb_temp_5 As c2fb_callback_348

    If Cast(c2fb_c_int, (arg1->flags And Cast(c2fb_c_int, &H02ULL))) Then
        c2fb_temp_0 = CPtr(c2fb_callback_storage_0 Ptr, @(arg1->xNext))
        c2fb_temp_1 = ProcPtr(fts5SegIterNext_Reverse)
        (*c2fb_temp_0) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5SegIter_ Ptr, ByVal arg2 As Long Ptr), c2fb_temp_1)
        c2fb_temp_1 = CPtr(c2fb_callback_348, (*c2fb_temp_0))
    Else
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_2 = CPtr(c2fb_callback_storage_2 Ptr, @(arg1->xNext))
            c2fb_temp_3 = ProcPtr(fts5SegIterNext_None)
            (*c2fb_temp_2) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5SegIter_ Ptr, ByVal arg2 As Long Ptr), c2fb_temp_3)
            c2fb_temp_3 = CPtr(c2fb_callback_348, (*c2fb_temp_2))
        Else
            c2fb_temp_4 = CPtr(c2fb_callback_storage_4 Ptr, @(arg1->xNext))
            c2fb_temp_5 = ProcPtr(fts5SegIterNext)
            (*c2fb_temp_4) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5SegIter_ Ptr, ByVal arg2 As Long Ptr), c2fb_temp_5)
            c2fb_temp_5 = CPtr(c2fb_callback_348, (*c2fb_temp_4))
        End If
    End If
End Sub
Private Sub fts5SegIterAllocTombstone CDecl Alias "fts5SegIterAllocTombstone" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2004
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_Fts5TombstoneArray Ptr
    Dim c2fb_temp_0 As c2fb_Fts5TombstoneArray Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_Fts5TombstoneArray_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_Fts5TombstoneArray Ptr

    local0 = Cast(c2fb_int64, CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)->nPgTombstone)
    If (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        local1 = (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5TombstoneArray_apTombstone_tail_ptr(Cast(c2fb_Fts5TombstoneArray Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_int64, (local0 + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Data Ptr))))))))
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TombstoneArray Ptr, CPtr(c2fb_Fts5TombstoneArray Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), local1))))
        local2 = c2fb_temp_0
        If local2 Then
            c2fb_temp_1 = CPtr(Long Ptr, @(local2->nTombstone))
            c2fb_temp_2 = Cast(c2fb_c_int, local0)
            (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
            c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
            c2fb_temp_3 = CPtr(Long Ptr, @(local2->nRef))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            c2fb_temp_5 = CPtr(c2fb_Fts5TombstoneArray_ Ptr Ptr, @(arg1->pTombArray))
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5TombstoneArray Ptr, local2)
            (*c2fb_temp_5) = CPtr(c2fb_Fts5TombstoneArray_ Ptr, c2fb_temp_6)
            c2fb_temp_6 = CPtr(c2fb_Fts5TombstoneArray Ptr, (*c2fb_temp_5))
        End If
    End If
End Sub
Private Sub fts5SegIterInit CDecl Alias "fts5SegIterInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2026
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_Fts5StructureSegment_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_i64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg1->pgnoFirst = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        Return
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegIter))))
        fts5SegIterSetNext(arg0, arg2)
        c2fb_temp_1 = CPtr(c2fb_Fts5StructureSegment_ Ptr Ptr, @(arg2->pSeg))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, arg1)
        (*c2fb_temp_1) = CPtr(c2fb_Fts5StructureSegment_ Ptr, c2fb_temp_2)
        c2fb_temp_2 = CPtr(c2fb_Fts5StructureSegment Ptr, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(Long Ptr, @(arg2->iLeafPgno))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->pgnoFirst - Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        Do
            fts5SegIterNextPage(arg0, arg2)
        c2fb_flow_1:
        Loop While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->nn = Cast(c2fb_c_int, 4ULL))))) <> 0)))))
        c2fb_flow_0:
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf) <> 0))))) Then
        c2fb_temp_5 = CPtr(c2fb_i64 Ptr, @(arg2->iLeafOffset))
        c2fb_temp_6 = Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL))
        (*c2fb_temp_5) = Cast(c2fb_i64, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_int64, (*c2fb_temp_5))
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        c2fb_temp_7 = CPtr(Long Ptr, @(arg2->iPgidxOff))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->szLeaf + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        fts5SegIterLoadTerm(arg0, arg2, Cast(c2fb_c_int, &O0ULL))
        fts5SegIterLoadNPos(arg0, arg2)
        fts5SegIterAllocTombstone(arg0, arg2)
    End If
End Sub
Private Sub fts5SegIterReverseInitPage CDecl Alias "fts5SegIterReverseInitPage" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2078
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local5 As c2fb_uint64
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_i64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim local8 As c2fb_int64
    Dim local9 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr Ptr
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_i64 Ptr
    Dim c2fb_temp_18 As c2fb_int64
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail
    local1 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf
    local2 = arg1->iLeafOffset
    local3 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p
    local4 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((local1 > arg1->iEndofDoclist)))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, arg1->iEndofDoclist)
        local1 = c2fb_temp_0
    End If
    ' C unused-parameter annotation
    While Cast(c2fb_c_int, 1ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local2 >= local1)))) Then
            Goto c2fb_flow_0
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < local1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3[local2]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_1 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < local1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3[local2]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_2 = local2
                    local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                End If
            End If
        Else
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + fts5GetPoslistSize(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local3[local2]))), CPtr(c2fb_c_int Ptr, @(local6)), CPtr(c2fb_c_int Ptr, @(local7))))))
            local2 = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + local6)))
            local2 = c2fb_temp_4
        End If
        If (-Cast(c2fb_c_int, ((local2 >= local1)))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local3[local2]))), CPtr(c2fb_uint64 Ptr, @(local5)))))))
        local2 = c2fb_temp_5
        c2fb_temp_6 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
        c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_6))) + local5)))
        (*c2fb_temp_6) = Cast(c2fb_i64, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
        If (-Cast(c2fb_c_int, ((local4 >= arg1->nRowidOffset)))) Then
            local8 = Cast(c2fb_c_int, (arg1->nRowidOffset + Cast(c2fb_c_int, 8ULL)))
            local9 = CPtr(c2fb_c_int Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg1->aRowidOffset), Cast(c2fb_uint64, (Cast(c2fb_uint64, local8) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))))))
            If (-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_8 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
                c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
                Goto c2fb_flow_0
            End If
            c2fb_temp_10 = CPtr(Long Ptr Ptr, @(arg1->aRowidOffset))
            c2fb_temp_11 = local9
            (*c2fb_temp_10) = CPtr(Long Ptr, c2fb_temp_11)
            c2fb_temp_11 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_10))
            c2fb_temp_12 = CPtr(Long Ptr, @(arg1->nRowidOffset))
            c2fb_temp_13 = Cast(c2fb_c_int, local8)
            (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
            c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
        End If
        c2fb_temp_14 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
        c2fb_temp_15 = CPtr(Long Ptr, @(arg1->aRowidOffset[c2fb_temp_14]))
        c2fb_temp_16 = Cast(c2fb_c_int, arg1->iLeafOffset)
        (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
        c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
        c2fb_temp_17 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
        c2fb_temp_18 = Cast(c2fb_int64, local2)
        (*c2fb_temp_17) = Cast(c2fb_i64, c2fb_temp_18)
        c2fb_temp_18 = Cast(c2fb_int64, (*c2fb_temp_17))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_19 = CPtr(Long Ptr, @(arg1->iRowidOffset))
    c2fb_temp_20 = Cast(c2fb_c_int, local4)
    (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
    c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
    fts5SegIterLoadNPos(arg0, arg1)
End Sub
Private Sub fts5SegIterReverseNewPage CDecl Alias "fts5SegIterReverseNewPage" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2132
    Dim c2fb_temp_0 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Data Ptr
    Dim local0 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_7 As c2fb_i64 Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_11 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_12 As c2fb_i64 Ptr
    Dim c2fb_temp_13 As c2fb_int64
    Dim local2 As UByte Ptr
    Dim c2fb_temp_14 As c2fb_i64 Ptr
    Dim c2fb_temp_15 As c2fb_int64
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int

#ifdef SQLITE_DEBUG
    If (arg1->flags And FTS5_SEGITER_REVERSE) = 0 Then _
        sqlite3DebugAssert(StrPtr(!"pIter->flags & FTS5_SEGITER_REVERSE"))
    If (arg1->flags And FTS5_SEGITER_ONETERM) = 0 Then _
        sqlite3DebugAssert(StrPtr(!"pIter->flags & FTS5_SEGITER_ONETERM"))
#endif
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))
    c2fb_temp_0 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_0))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->iLeafPgno > arg1->iTermLeafPgno)))) <> 0)))))
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(Long Ptr, @(arg1->iLeafPgno))
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        (*c2fb_temp_2) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (arg1->iLeafPgno)))))))))
        local0 = c2fb_temp_4
        If local0 Then
            If (-Cast(c2fb_c_int, ((arg1->iLeafPgno = arg1->iTermLeafPgno)))) Then
                ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
                If arg1->pLeaf <> 0 Then _
                    sqlite3DebugAssert(StrPtr(!"pIter->pLeaf==0"))
#endif
                If (-Cast(c2fb_c_int, ((arg1->iTermLeafOffset < local0->szLeaf)))) Then
                    c2fb_temp_5 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
                    c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local0)
                    (*c2fb_temp_5) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_6)
                    c2fb_temp_6 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_5))
                    c2fb_temp_7 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                    c2fb_temp_8 = Cast(c2fb_int64, arg1->iTermLeafOffset)
                    (*c2fb_temp_7) = Cast(c2fb_i64, c2fb_temp_8)
                    c2fb_temp_8 = Cast(c2fb_int64, (*c2fb_temp_7))
                End If
            Else
                ' C automatic storage declaration
                c2fb_temp_9 = Cast(c2fb_c_int, (fts5GetU16(CPtr(Const UByte Ptr, (local0)->p))))
                local1 = c2fb_temp_9
                If local1 Then
                    If (-Cast(c2fb_c_int, ((local1 >= local0->szLeaf)))) Then
                        fts5IndexCorruptIter(arg0, arg1)
                    Else
                        c2fb_temp_10 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
                        c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local0)
                        (*c2fb_temp_10) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_11)
                        c2fb_temp_11 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_10))
                        c2fb_temp_12 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                        c2fb_temp_13 = Cast(c2fb_int64, local1)
                        (*c2fb_temp_12) = Cast(c2fb_i64, c2fb_temp_13)
                        c2fb_temp_13 = Cast(c2fb_int64, (*c2fb_temp_12))
                    End If
                End If
            End If
            If CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf) Then
                local2 = CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[arg1->iLeafOffset]))
                c2fb_temp_14 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                c2fb_temp_15 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_14)) + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, local2), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg1->iRowid))))))))
                (*c2fb_temp_14) = Cast(c2fb_i64, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_int64, (*c2fb_temp_14))
                Goto c2fb_flow_0
            Else
                fts5DataRelease(local0)
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf) Then
        c2fb_temp_16 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
        c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->nn + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
        c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
        fts5SegIterReverseInitPage(arg0, arg1)
    End If
End Sub
Private Function fts5MultiIterIsEmpty CDecl Alias "fts5MultiIterIsEmpty" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2188
    Dim local0 As c2fb_Fts5SegIter Ptr

    local0 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg1)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg1->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
    Return ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_Fts5Data Ptr, local0->pLeaf) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->nPos = Cast(c2fb_c_int, &O0ULL))))) <> 0))))))
End Function
Private Sub fts5SegIterNext_Reverse CDecl Alias "fts5SegIterNext_Reverse" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2198
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_uint64
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_i64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_i64 Ptr
    Dim c2fb_temp_7 As c2fb_int64

#ifdef SQLITE_DEBUG
    If (arg1->flags And FTS5_SEGITER_REVERSE) = 0 Then _
        sqlite3DebugAssert(StrPtr(!"pIter->flags & FTS5_SEGITER_REVERSE"))
    If arg1->pNextLeaf <> 0 Then _
        sqlite3DebugAssert(StrPtr(!"pIter->pNextLeaf==0"))
#endif
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg1->iRowidOffset > Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(Long Ptr, @(arg1->iRowidOffset))
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
        c2fb_temp_2 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
        c2fb_temp_3 = Cast(c2fb_int64, arg1->aRowidOffset[arg1->iRowidOffset])
        (*c2fb_temp_2) = Cast(c2fb_i64, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_int64, (*c2fb_temp_2))
        fts5SegIterLoadNPos(arg0, arg1)
        c2fb_temp_4 = Cast(c2fb_c_int, arg1->iLeafOffset)
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail <> Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + arg1->nPos)))
            local1 = c2fb_temp_5
        End If
        c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0[local1]))), CPtr(c2fb_uint64 Ptr, @(local2)))
        c2fb_temp_6 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
        c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_6))) - local2)))
        (*c2fb_temp_6) = Cast(c2fb_i64, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
    Else
        fts5SegIterReverseNewPage(arg0, arg1)
    End If
End Sub
Private Sub fts5SegIterNext_None CDecl Alias "fts5SegIterNext_None" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2232
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_i64 Ptr
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local1 As c2fb_uint64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_i64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_i64 Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_i64 Ptr
    Dim c2fb_temp_11 As c2fb_int64
    Dim local3 As Const UByte Ptr
    Dim local4 As Const ZString Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_i64 Ptr
    Dim c2fb_temp_21 As c2fb_int64
    Dim c2fb_temp_22 As c2fb_c_int Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_25 As c2fb_Fts5Data Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, arg1->iLeafOffset)
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 >= CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf)))) <> 0)))))
        fts5SegIterNextPage(arg0, arg1)
        If (-Cast(c2fb_c_int, (((arg0->rc <> 0) OrElse ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Return
        End If
        c2fb_temp_1 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
        c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_1) = Cast(c2fb_i64, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_int64, (*c2fb_temp_1))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
        local0 = c2fb_temp_3
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 < arg1->iEndofDoclist)))) Then
        ' C automatic storage declaration
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[local0]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_uint64 Ptr, @(local1))))))))
        local0 = c2fb_temp_4
        c2fb_temp_5 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
        c2fb_temp_6 = Cast(c2fb_int64, local0)
        (*c2fb_temp_5) = Cast(c2fb_i64, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_int64, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
        c2fb_temp_8 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_7))) + local1)))
        (*c2fb_temp_7) = Cast(c2fb_i64, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_int64, (*c2fb_temp_7))
    Else
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1->flags And Cast(c2fb_c_int, &H01ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
            If CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg) Then
                local2 = Cast(c2fb_c_int, &O0ULL)
                If (-Cast(c2fb_c_int, ((local0 <> fts5LeafFirstTermOff(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)))))) Then
                    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local2))))))))
                    local0 = c2fb_temp_9
                End If
                c2fb_temp_10 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                c2fb_temp_11 = Cast(c2fb_int64, local0)
                (*c2fb_temp_10) = Cast(c2fb_i64, c2fb_temp_11)
                c2fb_temp_11 = Cast(c2fb_int64, (*c2fb_temp_10))
                fts5SegIterLoadTerm(arg0, arg1, local2)
            Else
                local3 = Cast(c2fb_c_int, &O0ULL)
                local4 = Cast(c2fb_c_int, &O0ULL)
                local5 = Cast(c2fb_c_int, &O0ULL)
                ' C automatic storage declaration
                c2fb_external_sqlite3Fts5HashScanNext(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash))
                c2fb_external_sqlite3Fts5HashScanEntry(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash), CPtr(Const ZString Ptr Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local5)), CPtr(Const UByte Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local6)))
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_label_0
                End If
                c2fb_temp_12 = CPtr(c2fb_u8 Ptr Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p))
                c2fb_temp_13 = CPtr(UByte Ptr, local3)
                (*c2fb_temp_12) = CPtr(c2fb_u8 Ptr, c2fb_temp_13)
                c2fb_temp_13 = CPtr(UByte Ptr, (*c2fb_temp_12))
                c2fb_temp_14 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->nn))
                c2fb_temp_15 = Cast(c2fb_c_int, local6)
                (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                c2fb_temp_16 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf))
                c2fb_temp_17 = Cast(c2fb_c_int, local6)
                (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
                c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
                c2fb_temp_18 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
                c2fb_temp_19 = Cast(c2fb_c_int, local6)
                (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
                c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
                c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg1->term)), local5, CPtr(Const UByte Ptr, CPtr(UByte Ptr, local4)))
                c2fb_temp_20 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                c2fb_temp_21 = Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint(local3, CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg1->iRowid)))))
                (*c2fb_temp_20) = Cast(c2fb_i64, c2fb_temp_21)
                c2fb_temp_21 = Cast(c2fb_int64, (*c2fb_temp_20))
            End If
            If arg2 Then
                c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_22) = c2fb_temp_23
            End If
        Else
            Goto c2fb_label_0
        End If
    End If
    fts5SegIterLoadNPos(arg0, arg1)
    Return
    c2fb_label_0:
    fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))
    c2fb_temp_24 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
    c2fb_temp_25 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_24) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_25)
    c2fb_temp_25 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_24))
End Sub
Private Sub fts5SegIterNext CDecl Alias "fts5SegIterNext" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2305
    Dim local0 As c2fb_Fts5Data Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As UByte Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local6 As c2fb_uint64
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_i64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_i64 Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim local7 As Const UByte Ptr
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_11 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_12 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_i64 Ptr
    Dim c2fb_temp_21 As c2fb_int64
    Dim c2fb_temp_22 As c2fb_c_int Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_i64 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim c2fb_temp_30 As Long Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As Long Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_i64 Ptr
    Dim c2fb_temp_35 As c2fb_int64
    Dim c2fb_temp_36 As Long Ptr
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_40 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_41 As c2fb_c_int Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_i64 Ptr
    Dim c2fb_temp_44 As c2fb_int64
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As c2fb_i64 Ptr
    Dim c2fb_temp_47 As c2fb_int64
    Dim c2fb_temp_48 As c2fb_i64 Ptr
    Dim c2fb_temp_49 As c2fb_int64
    Dim c2fb_temp_50 As c2fb_u8 Ptr
    Dim c2fb_temp_51 As UByte
    Dim c2fb_temp_52 As Long Ptr
    Dim c2fb_temp_53 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = local0->p
    local4 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, local0->szLeaf)
    local5 = c2fb_temp_1
    ' C unused-parameter annotation
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_int64, (arg1->iLeafOffset + Cast(c2fb_int64, arg1->nPos))))
    local1 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local1 < local5)))) Then
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local1 >= arg1->iEndofDoclist)))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local2 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((local1 <> fts5LeafFirstTermOff(local0))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local4[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local3))))))))
                local1 = c2fb_temp_4
            End If
        Else
            ' C automatic storage declaration
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local4[local1]))), CPtr(c2fb_uint64 Ptr, @(local6)))))))
            local1 = c2fb_temp_5
            c2fb_temp_6 = CPtr(c2fb_i64 Ptr, @(arg1->iRowid))
            c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_6))) + local6)))
            (*c2fb_temp_6) = Cast(c2fb_i64, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
            ' C unused-parameter annotation
        End If
        c2fb_temp_8 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
        c2fb_temp_9 = Cast(c2fb_int64, local1)
        (*c2fb_temp_8) = Cast(c2fb_i64, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_int64, (*c2fb_temp_8))
    Else
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg) = Cast(c2fb_c_int, &O0ULL))))) Then
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = Cast(c2fb_c_int, &O0ULL)
            local9 = Cast(c2fb_c_int, &O0ULL)
            local10 = Cast(c2fb_c_int, &O0ULL)
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (Cast(c2fb_c_int, (arg1->flags And Cast(c2fb_c_int, &H01ULL)))))))) Then
                c2fb_external_sqlite3Fts5HashScanNext(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash))
                c2fb_external_sqlite3Fts5HashScanEntry(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash), CPtr(Const ZString Ptr Ptr, @(local8)), CPtr(c2fb_c_int Ptr, @(local9)), CPtr(Const UByte Ptr Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local10)))
            End If
            If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
                fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))
                c2fb_temp_10 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
                c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_10) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_11)
                c2fb_temp_11 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_10))
            Else
                c2fb_temp_12 = CPtr(c2fb_u8 Ptr Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p))
                c2fb_temp_13 = CPtr(UByte Ptr, local7)
                (*c2fb_temp_12) = CPtr(c2fb_u8 Ptr, c2fb_temp_13)
                c2fb_temp_13 = CPtr(UByte Ptr, (*c2fb_temp_12))
                c2fb_temp_14 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->nn))
                c2fb_temp_15 = Cast(c2fb_c_int, local10)
                (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                c2fb_temp_16 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf))
                c2fb_temp_17 = Cast(c2fb_c_int, local10)
                (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
                c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
                c2fb_temp_18 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
                c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local10 + Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
                c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
                c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg1->term)), local9, CPtr(Const UByte Ptr, CPtr(UByte Ptr, local8)))
                c2fb_temp_20 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                c2fb_temp_21 = Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint(local7, CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg1->iRowid)))))
                (*c2fb_temp_20) = Cast(c2fb_i64, c2fb_temp_21)
                c2fb_temp_21 = Cast(c2fb_int64, (*c2fb_temp_20))
                c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_22) = c2fb_temp_23
            End If
        Else
            c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_24
            While (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL)))))
                fts5SegIterNextPage(arg0, arg1)
                c2fb_temp_25 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))
                local0 = c2fb_temp_25
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_0
                End If
                ' C unused-parameter annotation
                c2fb_temp_26 = Cast(c2fb_c_int, (fts5GetU16(CPtr(Const UByte Ptr, (local0)->p))))
                local1 = c2fb_temp_26
                If (-Cast(c2fb_c_int, ((((c2fb_temp_26) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < local0->szLeaf)))) <> 0))))) Then
                    c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->p[local1]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg1->iRowid))))))))
                    local1 = c2fb_temp_27
                    c2fb_temp_28 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                    c2fb_temp_29 = Cast(c2fb_int64, local1)
                    (*c2fb_temp_28) = Cast(c2fb_i64, c2fb_temp_29)
                    c2fb_temp_29 = Cast(c2fb_int64, (*c2fb_temp_28))
                    If (-Cast(c2fb_c_int, ((local0->nn > local0->szLeaf)))) Then
                        c2fb_temp_30 = CPtr(Long Ptr, @(arg1->iPgidxOff))
                        c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0->szLeaf + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->p[local0->szLeaf]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((arg1->iEndofDoclist))))))))
                        (*c2fb_temp_30) = Cast(Long, c2fb_temp_31)
                        c2fb_temp_31 = Cast(c2fb_c_int, (*c2fb_temp_30))
                    End If
                Else
                    If (-Cast(c2fb_c_int, ((local0->nn > local0->szLeaf)))) Then
                        c2fb_temp_32 = CPtr(Long Ptr, @(arg1->iPgidxOff))
                        c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0->szLeaf + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local0->p[local0->szLeaf]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local1))))))))
                        (*c2fb_temp_32) = Cast(Long, c2fb_temp_33)
                        c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
                        c2fb_temp_34 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                        c2fb_temp_35 = Cast(c2fb_int64, local1)
                        (*c2fb_temp_34) = Cast(c2fb_i64, c2fb_temp_35)
                        c2fb_temp_35 = Cast(c2fb_int64, (*c2fb_temp_34))
                        c2fb_temp_36 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
                        c2fb_temp_37 = Cast(c2fb_c_int, local1)
                        (*c2fb_temp_36) = Cast(Long, c2fb_temp_37)
                        c2fb_temp_37 = Cast(c2fb_c_int, (*c2fb_temp_36))
                        c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local2 = c2fb_temp_38
                    End If
                End If
                ' C unused-parameter annotation
                If (-Cast(c2fb_c_int, ((local1 > local0->szLeaf)))) Then
                    fts5IndexCorruptIter(arg0, arg1)
                    Return
                End If
            c2fb_flow_1:
            Wend
            c2fb_flow_0:
        End If
    End If
    If CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf) Then
        If local2 Then
            If Cast(c2fb_c_int, (arg1->flags And Cast(c2fb_c_int, &H01ULL))) Then
                fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))
                c2fb_temp_39 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
                c2fb_temp_40 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_39) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_40)
                c2fb_temp_40 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_39))
            Else
                fts5SegIterLoadTerm(arg0, arg1, local3)
                fts5SegIterLoadNPos(arg0, arg1)
                If arg2 Then
                    c2fb_temp_41 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                    c2fb_temp_42 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_41) = c2fb_temp_42
                End If
            End If
        Else
            ' C automatic storage declaration
            ' C unused-parameter annotation
            c2fb_temp_43 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
            c2fb_temp_44 = Cast(c2fb_int64, (*c2fb_temp_43))
            (*c2fb_temp_43) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_44 + 1)))
            c2fb_temp_45 = Cast(c2fb_c_int, (CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p)[c2fb_temp_44])
            local11 = c2fb_temp_45
            If Cast(c2fb_c_int, (local11 And Cast(c2fb_c_int, &H80ULL))) Then
                c2fb_temp_46 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                c2fb_temp_47 = Cast(c2fb_int64, (*c2fb_temp_46))
                (*c2fb_temp_46) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_47 - 1)))
                c2fb_temp_48 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                c2fb_temp_49 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_48)) + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p)[arg1->iLeafOffset]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local11)))))))))
                (*c2fb_temp_48) = Cast(c2fb_i64, c2fb_temp_49)
                c2fb_temp_49 = Cast(c2fb_int64, (*c2fb_temp_48))
            End If
            ' empty C statement
            c2fb_temp_50 = CPtr(c2fb_u8 Ptr, @(arg1->bDel))
            c2fb_temp_51 = Cast(UByte, (Cast(c2fb_c_int, (local11 And Cast(c2fb_c_int, &H0001ULL)))))
            (*c2fb_temp_50) = Cast(c2fb_u8, c2fb_temp_51)
            c2fb_temp_51 = Cast(UByte, (*c2fb_temp_50))
            c2fb_temp_52 = CPtr(Long Ptr, @(arg1->nPos))
            c2fb_temp_53 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local11 Shr Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_52) = Cast(Long, c2fb_temp_53)
            c2fb_temp_53 = Cast(c2fb_c_int, (*c2fb_temp_52))
            ' C unused-parameter annotation
        End If
    End If
End Sub
Private Sub fts5SegIterReverse CDecl Alias "fts5SegIterReverse" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2436
    Dim local0 As c2fb_Fts5DlidxIter Ptr
    Dim local1 As c2fb_Fts5Data Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_Fts5Data Ptr
    Dim local4 As c2fb_Fts5Data Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_i64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local9 As c2fb_int64
    Dim local10 As c2fb_Fts5Data Ptr
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local13 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_11 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_12 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_13 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_i64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5DlidxIter Ptr, arg1->pDlidx)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->iVersion = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
        local3 = CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)->iSegid
        c2fb_temp_0 = Cast(c2fb_c_int, fts5DlidxIterPgno(local0))
        local2 = c2fb_temp_0
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local3)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local2)))))))))
        local1 = c2fb_temp_1
    Else
        local4 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((arg1->iTermLeafPgno = arg1->iLeafPgno)))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, arg1->iTermLeafOffset)
            local5 = c2fb_temp_2
        Else
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
            local5 = c2fb_temp_3
        End If
        local6 = Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 9ULL)))
        Do
            c2fb_temp_4 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
            If ((-Cast(c2fb_c_int, ((((Cast(c2fb_c_int, (Cast(c2fb_c_int, local4->p[c2fb_temp_4]) And Cast(c2fb_c_int, &H80ULL)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < local6)))) <> 0))))) = 0) Then Goto c2fb_flow_0
            ' empty C statement
        c2fb_flow_1:
        Loop
        c2fb_flow_0:
        ' empty C statement
        c2fb_temp_5 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
        c2fb_temp_6 = Cast(c2fb_int64, local5)
        (*c2fb_temp_5) = Cast(c2fb_i64, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_int64, (*c2fb_temp_5))
        If (-Cast(c2fb_c_int, ((arg1->iEndofDoclist >= local4->szLeaf)))) Then
            ' C automatic storage declaration
            local8 = CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->iLeafPgno + Cast(c2fb_c_int, 1ULL))))
            local7 = c2fb_temp_7
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (arg0->rc = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 <= local8->pgnoLast)))) <> 0)))))
                local9 = (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local8->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local7))))))
                local10 = CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, local9))
                If local10 Then
                    ' C automatic storage declaration
                    ' C automatic storage declaration
                    c2fb_temp_9 = Cast(c2fb_c_int, (fts5GetU16(CPtr(Const UByte Ptr, (local10)->p))))
                    local11 = c2fb_temp_9
                    c2fb_temp_10 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((local10)->szLeaf >= (local10)->nn))))))
                    local12 = c2fb_temp_10
                    If local11 Then
                        ' C automatic storage declaration
                        c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local10)
                        local13 = c2fb_temp_11
                        c2fb_temp_12 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local1)
                        local10 = c2fb_temp_12
                        c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local13)
                        local1 = c2fb_temp_13
                        ' empty C statement
                        c2fb_temp_14 = Cast(c2fb_c_int, local7)
                        local2 = c2fb_temp_14
                    End If
                    fts5DataRelease(local10)
                    If (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_2
                    End If
                End If
            c2fb_flow_3:
                c2fb_temp_8 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
            Wend
            c2fb_flow_2:
        End If
    End If
    If local1 Then
        ' C automatic storage declaration
        fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))
        c2fb_temp_15 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pLeaf))
        c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local1)
        (*c2fb_temp_15) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_16)
        c2fb_temp_16 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_15))
        c2fb_temp_17 = CPtr(Long Ptr, @(arg1->iLeafPgno))
        c2fb_temp_18 = Cast(c2fb_c_int, local2)
        (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_19 = Cast(c2fb_c_int, (fts5GetU16(CPtr(Const UByte Ptr, (local1)->p))))
            local14 = c2fb_temp_19
            If (-Cast(c2fb_c_int, ((local14 > local1->szLeaf)))) Then
                fts5IndexCorruptIter(arg0, arg1)
                Return
            End If
            c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1->p[local14]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg1->iRowid))))))))
            local14 = c2fb_temp_20
            c2fb_temp_21 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
            c2fb_temp_22 = Cast(c2fb_int64, local14)
            (*c2fb_temp_21) = Cast(c2fb_i64, c2fb_temp_22)
            c2fb_temp_22 = Cast(c2fb_int64, (*c2fb_temp_21))
            If ((-Cast(c2fb_c_int, (((local1)->szLeaf >= (local1)->nn))))) Then
                c2fb_temp_23 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
                c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1->nn + Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
                c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
            Else
                c2fb_temp_25 = CPtr(Long Ptr, @(arg1->iEndofDoclist))
                c2fb_temp_26 = Cast(c2fb_c_int, fts5LeafFirstTermOff(local1))
                (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
                c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
            End If
        End If
    End If
    fts5SegIterReverseInitPage(arg0, arg1)
End Sub
Private Sub fts5SegIterLoadDlidx CDecl Alias "fts5SegIterLoadDlidx" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2527
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_0 As c2fb_Fts5DlidxIter_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5DlidxIter Ptr

    local0 = CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)->iSegid
    local1 = (Cast(c2fb_c_int, (arg1->flags And Cast(c2fb_c_int, &H02ULL))))
    local2 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->iTermLeafPgno = arg1->iLeafPgno)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->iEndofDoclist < local2->szLeaf)))) <> 0))))) Then
        Return
    End If
    c2fb_temp_0 = CPtr(c2fb_Fts5DlidxIter_ Ptr Ptr, @(arg1->pDlidx))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5DlidxIter Ptr, CPtr(c2fb_Fts5DlidxIter Ptr, fts5DlidxIterInit(arg0, local1, local0, arg1->iTermLeafPgno)))
    (*c2fb_temp_0) = CPtr(c2fb_Fts5DlidxIter_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_Fts5DlidxIter Ptr, (*c2fb_temp_0))
End Sub
Private Sub fts5LeafSeek CDecl Alias "fts5LeafSeek" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5SegIter Ptr, ByVal arg3 As Const UByte Ptr, ByVal arg4 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2561
    Dim local0 As c2fb_c_uint
    Dim local1 As Const UByte Ptr
    Dim local2 As c2fb_c_uint
    Dim local3 As c2fb_c_uint
    Dim local4 As c2fb_c_uint
    Dim local5 As c2fb_c_uint
    Dim local6 As c2fb_c_uint
    Dim local7 As c2fb_c_uint
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim local9 As c2fb_c_uint
    Dim local10 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As c2fb_c_uint
    Dim c2fb_temp_10 As c2fb_c_uint
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_uint
    Dim c2fb_temp_13 As c2fb_c_uint
    Dim c2fb_temp_14 As c2fb_c_uint
    Dim c2fb_temp_15 As c2fb_c_uint
    Dim c2fb_temp_16 As c2fb_c_uint
    Dim c2fb_temp_17 As c2fb_c_uint
    Dim c2fb_temp_18 As c2fb_c_uint
    Dim c2fb_temp_19 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_20 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_21 As Const UByte Ptr
    Dim c2fb_temp_22 As c2fb_c_uint
    Dim c2fb_temp_23 As c2fb_c_uint
    Dim c2fb_temp_24 As c2fb_c_uint
    Dim c2fb_temp_25 As c2fb_c_uint
    Dim c2fb_temp_26 As c2fb_c_uint
    Dim c2fb_temp_27 As c2fb_c_uint
    Dim c2fb_temp_28 As c2fb_i64 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim c2fb_temp_30 As Long Ptr
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As Long Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As Long Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_uint
    Dim c2fb_temp_37 As Long Ptr
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As Long Ptr
    Dim c2fb_temp_40 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(Const UByte Ptr, CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->p)
    local2 = Cast(c2fb_c_uint, CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->nn)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local8 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->szLeaf))
    local7 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local7 + Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1[local7]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local6)))))))))
    local7 = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_uint, local6)
    local0 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local0 > local2)))) Then
        fts5IndexCorruptIter(arg0, arg2)
        Return
    End If
    While Cast(c2fb_c_int, 1ULL)
        c2fb_temp_3 = local0
        local0 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_3 + 1)))
        c2fb_temp_4 = Cast(c2fb_c_uint, (local1)[c2fb_temp_3])
        local5 = c2fb_temp_4
        If Cast(c2fb_c_uint, (local5 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_5 = local0
            local0 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_5 - 1)))
            c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 + Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((local1)[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local5)))))))))
            local0 = c2fb_temp_6
        End If
        ' empty C statement
        If (-Cast(c2fb_c_int, ((local4 < local3)))) Then
            Goto c2fb_label_0
        End If
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (local0 + local5))) > local2)))) Then
            fts5IndexCorruptIter(arg0, arg2)
            Return
        End If
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local4 = local3)))) Then
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_7 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (IIf(((-Cast(c2fb_c_int, (((local5) < (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg4) - local3)))))))), (local5), (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg4) - local3)))))))
            local9 = c2fb_temp_7
            c2fb_temp_8 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
            local10 = c2fb_temp_8
            While (-Cast(c2fb_c_int, ((local10 < local9))))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1[Cast(c2fb_c_uint, (local0 + local10))]) <> Cast(c2fb_c_int, arg3[Cast(c2fb_c_uint, (local3 + local10))]))))) Then
                    Goto c2fb_flow_2
                End If
            c2fb_flow_3:
                c2fb_temp_9 = local10
                local10 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_9 + 1)))
            Wend
            c2fb_flow_2:
            c2fb_temp_10 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local3 + local10)))
            local3 = c2fb_temp_10
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, arg4) = local3)))) Then
                If (-Cast(c2fb_c_int, ((local10 = local5)))) Then
                    Goto c2fb_label_1
                Else
                    Goto c2fb_label_0
                End If
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local10 < local5)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1[Cast(c2fb_c_uint, (local0 + local10))]) > Cast(c2fb_c_int, arg3[local3]))))) <> 0))))) Then
                    Goto c2fb_label_0
                End If
            End If
        End If
        If (-Cast(c2fb_c_int, ((local7 >= local2)))) Then
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local8 = c2fb_temp_11
            Goto c2fb_flow_0
        End If
        c2fb_temp_12 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local7 + Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1[local7]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local4)))))))))
        local7 = c2fb_temp_12
        c2fb_temp_13 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local6 + local4)))
        local6 = c2fb_temp_13
        c2fb_temp_14 = Cast(c2fb_c_uint, local6)
        local0 = c2fb_temp_14
        If (-Cast(c2fb_c_int, ((local0 >= local2)))) Then
            fts5IndexCorruptIter(arg0, arg2)
            Return
        End If
        c2fb_temp_15 = local0
        local0 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_15 + 1)))
        c2fb_temp_16 = Cast(c2fb_c_uint, (local1)[c2fb_temp_15])
        local4 = c2fb_temp_16
        If Cast(c2fb_c_uint, (local4 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_17 = local0
            local0 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_17 - 1)))
            c2fb_temp_18 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 + Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((local1)[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local4)))))))))
            local0 = c2fb_temp_18
        End If
        ' empty C statement
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_label_0:
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf))
        c2fb_temp_19 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg2->pLeaf))
        c2fb_temp_20 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_19) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_20)
        c2fb_temp_20 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_19))
        Return
    Else
        If local8 Then
            Do
                fts5SegIterNextPage(arg0, arg2)
                If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) Then
                    Return
                End If
                c2fb_temp_21 = CPtr(Const UByte Ptr, CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->p)
                local1 = c2fb_temp_21
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf))->szLeaf >= (CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf))->nn))))) = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_22 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->szLeaf))
                    local7 = c2fb_temp_22
                    c2fb_temp_23 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local7 + Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->p[local7]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local0)))))))))
                    local7 = c2fb_temp_23
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_uint, Cast(c2fb_c_int, 4ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_int64, local0) >= Cast(c2fb_int64, CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->szLeaf))))) <> 0))))) Then
                        fts5IndexCorruptIter(arg0, arg2)
                        Return
                    Else
                        c2fb_temp_24 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
                        local4 = c2fb_temp_24
                        c2fb_temp_25 = Cast(c2fb_c_uint, local0)
                        local6 = c2fb_temp_25
                        c2fb_temp_26 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->nn))
                        local2 = c2fb_temp_26
                        c2fb_temp_27 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local0 + Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local5)))))))))
                        local0 = c2fb_temp_27
                        Goto c2fb_flow_4
                    End If
                End If
            c2fb_flow_5:
            Loop While Cast(c2fb_c_int, 1ULL)
            c2fb_flow_4:
        End If
    End If
    c2fb_label_1:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_int64, (Cast(c2fb_int64, local0) + Cast(c2fb_int64, local5))) > Cast(c2fb_int64, local2))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local5 < Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))))) <> 0))))) Then
        fts5IndexCorruptIter(arg0, arg2)
        Return
    End If
    c2fb_temp_28 = CPtr(c2fb_i64 Ptr, @(arg2->iLeafOffset))
    c2fb_temp_29 = Cast(c2fb_int64, Cast(c2fb_c_uint, (local0 + local5)))
    (*c2fb_temp_28) = Cast(c2fb_i64, c2fb_temp_29)
    c2fb_temp_29 = Cast(c2fb_int64, (*c2fb_temp_28))
    c2fb_temp_30 = CPtr(Long Ptr, @(arg2->iTermLeafOffset))
    c2fb_temp_31 = Cast(c2fb_c_int, arg2->iLeafOffset)
    (*c2fb_temp_30) = Cast(Long, c2fb_temp_31)
    c2fb_temp_31 = Cast(c2fb_c_int, (*c2fb_temp_30))
    c2fb_temp_32 = CPtr(Long Ptr, @(arg2->iTermLeafPgno))
    c2fb_temp_33 = Cast(c2fb_c_int, arg2->iLeafPgno)
    (*c2fb_temp_32) = Cast(Long, c2fb_temp_33)
    c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
    c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg2->term)), local4, arg3)
    c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg2->term)), local5, CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1[local0]))))
    If (-Cast(c2fb_c_int, ((local7 >= local2)))) Then
        c2fb_temp_34 = CPtr(Long Ptr, @(arg2->iEndofDoclist))
        c2fb_temp_35 = Cast(c2fb_c_int, Cast(c2fb_c_int, (CPtr(c2fb_Fts5Data Ptr, arg2->pLeaf)->nn + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_34) = Cast(Long, c2fb_temp_35)
        c2fb_temp_35 = Cast(c2fb_c_int, (*c2fb_temp_34))
    Else
        ' C automatic storage declaration
        c2fb_temp_36 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local7 + Cast(c2fb_c_uint, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1[local7]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local11)))))))))
        local7 = c2fb_temp_36
        c2fb_temp_37 = CPtr(Long Ptr, @(arg2->iEndofDoclist))
        c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_uint, (local6 + Cast(c2fb_c_uint, local11))))
        (*c2fb_temp_37) = Cast(Long, c2fb_temp_38)
        c2fb_temp_38 = Cast(c2fb_c_int, (*c2fb_temp_37))
    End If
    c2fb_temp_39 = CPtr(Long Ptr, @(arg2->iPgidxOff))
    c2fb_temp_40 = Cast(c2fb_c_int, local7)
    (*c2fb_temp_39) = Cast(Long, c2fb_temp_40)
    c2fb_temp_40 = Cast(c2fb_c_int, (*c2fb_temp_39))
    fts5SegIterLoadRowid(arg0, arg2)
    fts5SegIterLoadNPos(arg0, arg2)
End Sub
Private Function fts5IdxSelectStmt CDecl Alias "fts5IdxSelectStmt" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_sqlite3_stmt Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2691
    Dim local0 As c2fb_Fts5Config Ptr

    If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxSelect) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pIdxSelect)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT pgno FROM '%q'.'%q_idx' WHERE segid=? AND term<=? ORDER BY term DESC LIMIT 1"), local0->zDb, local0->zName)))
    End If
    Return CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxSelect)
End Function
Private Sub fts5SegIterSeekInit CDecl Alias "fts5SegIterSeekInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5StructureSegment Ptr, ByVal arg5 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2710
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_Fts5StructureSegment_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_3 As c2fb_sqlite3_stmt Ptr
    Dim local4 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    local0 = Cast(c2fb_c_int, 1ULL)
    local1 = (Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0008ULL))))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg5), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegIter))))
    c2fb_temp_1 = CPtr(c2fb_Fts5StructureSegment_ Ptr Ptr, @(arg5->pSeg))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, arg4)
    (*c2fb_temp_1) = CPtr(c2fb_Fts5StructureSegment_ Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_Fts5StructureSegment Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(c2fb_sqlite3_stmt Ptr, fts5IdxSelectStmt(arg0))
    local3 = c2fb_temp_3
    If arg0->rc Then
        Return
    End If
    sqlite3_bind_int(CPtr(Any Ptr, local3), Cast(c2fb_c_int, 1ULL), arg4->iSegid)
    sqlite3_bind_blob(CPtr(Any Ptr, local3), Cast(c2fb_c_int, 2ULL), CPtr(Const Any Ptr, arg1), arg2, CPtr(Any Ptr, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = sqlite3_step(CPtr(Any Ptr, local3)))))) Then
        local4 = sqlite3_column_int(CPtr(Any Ptr, local3), Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (local4 Shr Cast(c2fb_c_int, 1ULL))))))
        local0 = c2fb_temp_4
        c2fb_temp_5 = Cast(c2fb_c_int, (Cast(c2fb_int64, (local4 And Cast(c2fb_int64, Cast(c2fb_c_int, &H0001ULL))))))
        local2 = c2fb_temp_5
    End If
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_7 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, local3)))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    sqlite3_bind_null(CPtr(Any Ptr, local3), Cast(c2fb_c_int, 2ULL))
    If (-Cast(c2fb_c_int, ((local0 < arg4->pgnoFirst)))) Then
        c2fb_temp_8 = Cast(c2fb_c_int, arg4->pgnoFirst)
        local0 = c2fb_temp_8
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_9
    End If
    c2fb_temp_10 = CPtr(Long Ptr, @(arg5->iLeafPgno))
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
    c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
    fts5SegIterNextPage(arg0, arg5)
    If CPtr(c2fb_Fts5Data Ptr, arg5->pLeaf) Then
        fts5LeafSeek(arg0, local1, arg5, arg1, arg2)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0100ULL)))) <> 0)))))) <> 0))))) Then
        c2fb_temp_12 = CPtr(Long Ptr, @(arg5->flags))
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_12)) Or Cast(c2fb_c_int, &H01ULL))))
        (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
        c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
        If CPtr(c2fb_Fts5Data Ptr, arg5->pLeaf) Then
            If Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0002ULL))) Then
                c2fb_temp_14 = CPtr(Long Ptr, @(arg5->flags))
                c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_14)) Or Cast(c2fb_c_int, &H02ULL))))
                (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
            End If
            If local2 Then
                fts5SegIterLoadDlidx(arg0, arg5)
            End If
            If Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0002ULL))) Then
                fts5SegIterReverse(arg0, arg5)
            End If
        End If
    End If
    fts5SegIterSetNext(arg0, arg5)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0100ULL)))))))) Then
        fts5SegIterAllocTombstone(arg0, arg5)
    End If
    ' C unused-parameter annotation
End Sub
Private Function fts5IdxNextStmt CDecl Alias "fts5IdxNextStmt" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_sqlite3_stmt Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2792
    Dim local0 As c2fb_Fts5Config Ptr

    If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxNextSelect) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pIdxNextSelect)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT pgno FROM '%q'.'%q_idx' WHERE segid=? AND term>? ORDER BY term ASC LIMIT 1"), local0->zDb, local0->zName)))
    End If
    Return CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxNextSelect)
End Function
Private Sub fts5SegIterNextInit CDecl Alias "fts5SegIterNextInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5StructureSegment Ptr, ByVal arg4 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2810
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_sqlite3_stmt Ptr
    Dim local3 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_Fts5StructureSegment_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local4 As Const UByte Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_i64 Ptr
    Dim c2fb_temp_19 As c2fb_int64

    local0 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_sqlite3_stmt Ptr, fts5IdxNextStmt(arg0))
    local2 = c2fb_temp_0
    If local2 Then
        ' C unused-parameter annotation
        sqlite3_bind_int(CPtr(Any Ptr, local2), Cast(c2fb_c_int, 1ULL), arg3->iSegid)
        sqlite3_bind_blob(CPtr(Any Ptr, local2), Cast(c2fb_c_int, 2ULL), CPtr(Const Any Ptr, arg1), arg2, CPtr(Any Ptr, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
        If (-Cast(c2fb_c_int, ((sqlite3_step(CPtr(Any Ptr, local2)) = Cast(c2fb_c_int, 100ULL))))) Then
            local3 = sqlite3_column_int64(CPtr(Any Ptr, local2), Cast(c2fb_c_int, &O0ULL))
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (local3 Shr Cast(c2fb_c_int, 1ULL))))))
            local0 = c2fb_temp_1
            c2fb_temp_2 = Cast(c2fb_c_int, (Cast(c2fb_int64, (local3 And Cast(c2fb_int64, Cast(c2fb_c_int, &H0001ULL))))))
            local1 = c2fb_temp_2
        End If
        c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_4 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, local2)))
        (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        sqlite3_bind_null(CPtr(Any Ptr, local2), Cast(c2fb_c_int, 2ULL))
        If arg0->rc Then
            Return
        End If
    End If
    c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg4), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegIter))))
    c2fb_temp_6 = CPtr(c2fb_Fts5StructureSegment_ Ptr Ptr, @(arg4->pSeg))
    c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, arg3)
    (*c2fb_temp_6) = CPtr(c2fb_Fts5StructureSegment_ Ptr, c2fb_temp_7)
    c2fb_temp_7 = CPtr(c2fb_Fts5StructureSegment Ptr, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(Long Ptr, @(arg4->flags))
    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_8)) Or Cast(c2fb_c_int, &H01ULL))))
    (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
    c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
    If (-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_10 = CPtr(Long Ptr, @(arg4->iLeafPgno))
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        fts5SegIterNextPage(arg0, arg4)
        fts5SegIterSetNext(arg0, arg4)
    End If
    If CPtr(c2fb_Fts5Data Ptr, arg4->pLeaf) Then
        local4 = CPtr(Const UByte Ptr, CPtr(c2fb_Fts5Data Ptr, arg4->pLeaf)->p)
        local5 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_12 = CPtr(Long Ptr, @(arg4->iPgidxOff))
        c2fb_temp_13 = Cast(c2fb_c_int, CPtr(c2fb_Fts5Data Ptr, arg4->pLeaf)->szLeaf)
        (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
        c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
        c2fb_temp_14 = CPtr(Long Ptr, @(arg4->iPgidxOff))
        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_14)) + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local4[arg4->iPgidxOff]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local5))))))))
        (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
        If (-Cast(c2fb_c_int, ((local5 > CPtr(c2fb_Fts5Data Ptr, arg4->pLeaf)->szLeaf)))) Then
            c2fb_temp_16 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_17 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
            (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
            c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
            Return
        End If
        c2fb_temp_18 = CPtr(c2fb_i64 Ptr, @(arg4->iLeafOffset))
        c2fb_temp_19 = Cast(c2fb_int64, local5)
        (*c2fb_temp_18) = Cast(c2fb_i64, c2fb_temp_19)
        c2fb_temp_19 = Cast(c2fb_int64, (*c2fb_temp_18))
        fts5SegIterLoadTerm(arg0, arg4, Cast(c2fb_c_int, &O0ULL))
        fts5SegIterLoadNPos(arg0, arg4)
        If local1 Then
            fts5SegIterLoadDlidx(arg0, arg4)
        End If
        ' C unused-parameter annotation
    End If
End Sub
Private Sub fts5SegIterHashInit CDecl Alias "fts5SegIterHashInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2873
    Dim local0 As c2fb_c_int
    Dim local1 As Const UByte Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5Data Ptr
    Dim local4 As Const UByte Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_3 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As Const UByte Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_20 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_21 As c2fb_i64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0008ULL)))) <> 0))))) Then
        local4 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5HashScanInit(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash), CPtr(Const ZString Ptr, arg1), arg2))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_external_sqlite3Fts5HashScanEntry(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash), CPtr(Const ZString Ptr Ptr, CPtr(Const UByte Ptr Ptr, @(local1))), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(Const UByte Ptr Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local0)))
        If local4 Then
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(Any Ptr, fts5IdxMalloc(arg0, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Data)))))
            local3 = c2fb_temp_2
            If local3 Then
                c2fb_temp_3 = CPtr(c2fb_u8 Ptr Ptr, @(local3->p))
                c2fb_temp_4 = CPtr(UByte Ptr, local4)
                (*c2fb_temp_3) = CPtr(c2fb_u8 Ptr, c2fb_temp_4)
                c2fb_temp_4 = CPtr(UByte Ptr, (*c2fb_temp_3))
            End If
        End If
        c2fb_temp_5 = CPtr(Long Ptr, @(arg0->bDelete))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    Else
        c2fb_temp_7 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_8 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5HashQuery(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Data)), CPtr(Const ZString Ptr, arg1), arg2, CPtr(Any Ptr Ptr, CPtr(c2fb_Fts5Data Ptr Ptr, @(local3))), CPtr(c2fb_c_int Ptr, @(local0))))
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        If local3 Then
            c2fb_temp_9 = CPtr(c2fb_u8 Ptr Ptr, @(local3->p))
            c2fb_temp_10 = CPtr(UByte Ptr, CPtr(c2fb_Fts5Data Ptr, @(CPtr(c2fb_Fts5Data Ptr, local3)[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_9) = CPtr(c2fb_u8 Ptr, c2fb_temp_10)
            c2fb_temp_10 = CPtr(UByte Ptr, (*c2fb_temp_9))
        End If
        c2fb_temp_11 = arg1
        local1 = c2fb_temp_11
        c2fb_temp_12 = Cast(c2fb_c_int, arg2)
        local2 = c2fb_temp_12
        c2fb_temp_13 = CPtr(Long Ptr, @(arg4->flags))
        c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_13)) Or Cast(c2fb_c_int, &H01ULL))))
        (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
        c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
    End If
    If local3 Then
        c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg4->term)), local2, local1)
        c2fb_temp_17 = CPtr(Long Ptr, @(local3->nn))
        c2fb_temp_15 = CPtr(Long Ptr, @(local3->szLeaf))
        c2fb_temp_16 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
        c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
        c2fb_temp_18 = Cast(c2fb_c_int, c2fb_temp_16)
        (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
        c2fb_temp_19 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg4->pLeaf))
        c2fb_temp_20 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local3)
        (*c2fb_temp_19) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_20)
        c2fb_temp_20 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_19))
        c2fb_temp_21 = CPtr(c2fb_i64 Ptr, @(arg4->iLeafOffset))
        c2fb_temp_22 = Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, local3->p), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg4->iRowid)))))
        (*c2fb_temp_21) = Cast(c2fb_i64, c2fb_temp_22)
        c2fb_temp_22 = Cast(c2fb_int64, (*c2fb_temp_21))
        c2fb_temp_23 = CPtr(Long Ptr, @(arg4->iEndofDoclist))
        c2fb_temp_24 = Cast(c2fb_c_int, local3->nn)
        (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
        c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
        If Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0002ULL))) Then
            c2fb_temp_25 = CPtr(Long Ptr, @(arg4->flags))
            c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_25)) Or Cast(c2fb_c_int, &H02ULL))))
            (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
            c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
            fts5SegIterReverseInitPage(arg0, arg4)
        Else
            fts5SegIterLoadNPos(arg0, arg4)
        End If
    End If
    fts5SegIterSetNext(arg0, arg4)
End Sub
Private Sub fts5IndexFreeArray CDecl Alias "fts5IndexFreeArray" (ByVal arg0 As c2fb_Fts5Data Ptr Ptr, ByVal arg1 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2940
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg1))))
            fts5DataRelease(CPtr(c2fb_Fts5Data Ptr Ptr, arg0)[local0])
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Private Sub fts5TombstoneArrayDelete CDecl Alias "fts5TombstoneArrayDelete" (ByVal arg0 As c2fb_Fts5TombstoneArray Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2954
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    If arg0 Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->nRef))
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
        If (-Cast(c2fb_c_int, ((arg0->nRef <= Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((local0 < arg0->nTombstone))))
                fts5DataRelease(CPtr(c2fb_Fts5Data Ptr Ptr, (c2fb_Fts5TombstoneArray_apTombstone_tail_ptr(arg0)))[local0])
            c2fb_flow_1:
                c2fb_temp_3 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            Wend
            c2fb_flow_0:
            sqlite3_free(CPtr(Any Ptr, arg0))
        End If
    End If
End Sub
Private Sub fts5SegIterClear CDecl Alias "fts5SegIterClear" (ByVal arg0 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 2970
    Dim c2fb_temp_0 As Any Ptr

    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->term)))
    fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg0->pLeaf))
    fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg0->pNextLeaf))
    fts5TombstoneArrayDelete(CPtr(c2fb_Fts5TombstoneArray Ptr, arg0->pTombArray))
    fts5DlidxIterFree(CPtr(c2fb_Fts5DlidxIter Ptr, arg0->pDlidx))
    sqlite3_free(CPtr(Any Ptr, arg0->aRowidOffset))
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegIter))))
End Sub
Private Function fts5MultiIterDoCompare CDecl Alias "fts5MultiIterDoCompare" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3075
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5SegIter Ptr
    Dim local4 As c2fb_Fts5SegIter Ptr
    Dim local5 As c2fb_Fts5CResult Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_5 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_6 As c2fb_u8 Ptr
    Dim c2fb_temp_7 As UByte
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_u8 Ptr
    Dim c2fb_temp_11 As UByte
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_u16 Ptr
    Dim c2fb_temp_16 As UShort

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local5 = CPtr(c2fb_Fts5CResult Ptr, @(CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[arg1]))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg1 >= (Cast(c2fb_c_int, (arg0->nSeg \ Cast(c2fb_c_int, 2ULL)))))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1 - Cast(c2fb_c_int, (arg0->nSeg \ Cast(c2fb_c_int, 2ULL)))))) * Cast(c2fb_c_int, 2ULL))))
        local0 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))))
        local1 = c2fb_temp_1
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, 2ULL)))].iFirst)
        local0 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))].iFirst)
        local1 = c2fb_temp_3
    End If
    c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[local0])))
    local3 = c2fb_temp_4
    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[local1])))
    local4 = c2fb_temp_5
    c2fb_temp_6 = CPtr(c2fb_u8 Ptr, @(local5->bTermEq))
    c2fb_temp_7 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_6) = Cast(c2fb_u8, c2fb_temp_7)
    c2fb_temp_7 = Cast(UByte, (*c2fb_temp_6))
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, local3->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_8 = Cast(c2fb_c_int, local1)
        local2 = c2fb_temp_8
    Else
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, local4->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_9 = Cast(c2fb_c_int, local0)
            local2 = c2fb_temp_9
        Else
            local6 = fts5BufferCompare(CPtr(c2fb_Fts5Buffer Ptr, @(local3->term)), CPtr(c2fb_Fts5Buffer Ptr, @(local4->term)))
            If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C unused-parameter annotation
                ' C unused-parameter annotation
                c2fb_temp_10 = CPtr(c2fb_u8 Ptr, @(local5->bTermEq))
                c2fb_temp_11 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_10) = Cast(c2fb_u8, c2fb_temp_11)
                c2fb_temp_11 = Cast(UByte, (*c2fb_temp_10))
                If (-Cast(c2fb_c_int, ((local3->iRowid = local4->iRowid)))) Then
                    Return local1
                End If
                c2fb_temp_12 = Cast(c2fb_c_int, IIf(((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3->iRowid > local4->iRowid))))) = arg0->bRev))))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, (+Cast(c2fb_c_int, 1ULL)))))
                local6 = c2fb_temp_12
            End If
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local6 < Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_13 = Cast(c2fb_c_int, local0)
                local2 = c2fb_temp_13
            Else
                c2fb_temp_14 = Cast(c2fb_c_int, local1)
                local2 = c2fb_temp_14
            End If
        End If
    End If
    c2fb_temp_15 = CPtr(c2fb_u16 Ptr, @(local5->iFirst))
    c2fb_temp_16 = Cast(UShort, Cast(UShort, local2))
    (*c2fb_temp_15) = Cast(c2fb_u16, c2fb_temp_16)
    c2fb_temp_16 = Cast(UShort, (*c2fb_temp_15))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts5SegIterGotoPage CDecl Alias "fts5SegIterGotoPage" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3129
    Dim c2fb_temp_0 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_i64 Ptr
    Dim c2fb_temp_7 As c2fb_int64

    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg2 > CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)->pgnoLast)))) Then
        fts5IndexCorruptIdx(arg0)
    Else
        fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg1->pNextLeaf))
        c2fb_temp_0 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pNextLeaf))
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_1)
        c2fb_temp_1 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(Long Ptr, @(arg1->iLeafPgno))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        While (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))
            ' C automatic storage declaration
            fts5SegIterNextPage(arg0, arg1)
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_4 = Cast(c2fb_c_int, (fts5GetU16(CPtr(Const UByte Ptr, (CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf))->p))))
            local0 = c2fb_temp_4
            If (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, &O0ULL))))) Then
                local1 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p
                local2 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 >= local2)))) <> 0))))) Then
                    fts5IndexCorruptIdx(arg0)
                Else
                    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1[local0]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg1->iRowid))))))))
                    local0 = c2fb_temp_5
                    c2fb_temp_6 = CPtr(c2fb_i64 Ptr, @(arg1->iLeafOffset))
                    c2fb_temp_7 = Cast(c2fb_int64, local0)
                    (*c2fb_temp_6) = Cast(c2fb_i64, c2fb_temp_7)
                    c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
                    fts5SegIterLoadNPos(arg0, arg1)
                End If
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
End Sub
Private Sub fts5SegIterNextFrom CDecl Alias "fts5SegIterNextFrom" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3169
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5DlidxIter Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = (Cast(c2fb_c_int, (arg1->flags And Cast(c2fb_c_int, &H02ULL))))
    local1 = CPtr(c2fb_Fts5DlidxIter Ptr, arg1->pDlidx)
    local2 = arg1->iLeafPgno
    local3 = Cast(c2fb_c_int, 1ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (fts5DlidxIterEof(arg0, local1) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 > fts5DlidxIterRowid(local1))))) <> 0)))))
            c2fb_temp_0 = Cast(c2fb_c_int, fts5DlidxIterPgno(local1))
            local2 = c2fb_temp_0
            fts5DlidxIterNext(arg0, local1)
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local2 > arg1->iLeafPgno)))) Then
            fts5SegIterGotoPage(arg0, arg1, local2)
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_1
        End If
    Else
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (fts5DlidxIterEof(arg0, local1) = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 < fts5DlidxIterRowid(local1))))) <> 0)))))
            fts5DlidxIterPrev(arg0, local1)
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_2 = Cast(c2fb_c_int, fts5DlidxIterPgno(local1))
        local2 = c2fb_temp_2
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local2 < arg1->iLeafPgno)))) Then
            c2fb_temp_3 = CPtr(Long Ptr, @(arg1->iLeafPgno))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            fts5SegIterReverseNewPage(arg0, arg1)
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_5
        End If
    End If
    Do
        If (-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            CPtr(c2fb_callback_348, arg1->xNext)(arg0, arg1, Cast(c2fb_c_int, &O0ULL))
        End If
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_4
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->iRowid >= arg2)))) <> 0))))) Then
            Goto c2fb_flow_4
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->iRowid <= arg2)))) <> 0))))) Then
            Goto c2fb_flow_4
        End If
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_6
    c2fb_flow_5:
    Loop While (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))
    c2fb_flow_4:
End Sub
Private Sub fts5MultiIterFree CDecl Alias "fts5MultiIterFree" (ByVal arg0 As c2fb_Fts5Iter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3222
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nSeg))))
            fts5SegIterClear(CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[local0])))
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Private Sub fts5MultiIterAdvanced CDecl Alias "fts5MultiIterAdvanced" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3233
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1->nSeg + arg2))) \ Cast(c2fb_c_int, 2ULL))))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 >= arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, fts5MultiIterDoCompare(arg1, local0))
        local1 = c2fb_temp_2
        If (c2fb_temp_2) Then
            local2 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg1)))[local1]))
            ' C unused-parameter annotation
            CPtr(c2fb_callback_348, local2->xNext)(arg0, local2, Cast(c2fb_c_int, &O0ULL))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->nSeg + local1)))
            local0 = c2fb_temp_3
        End If
    c2fb_flow_1:
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 \ Cast(c2fb_c_int, 2ULL))))
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
End Sub
Private Function fts5MultiIterAdvanceRowid CDecl Alias "fts5MultiIterAdvanceRowid" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5SegIter Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3261
    Dim local0 As c2fb_Fts5SegIter Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_Fts5CResult Ptr
    Dim c2fb_temp_4 As c2fb_i64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_7 As c2fb_i64 Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_u16 Ptr
    Dim c2fb_temp_10 As UShort
    Dim c2fb_temp_11 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_12 As c2fb_Fts5SegIter Ptr Ptr
    Dim c2fb_temp_13 As c2fb_Fts5SegIter Ptr

    local0 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[arg1]))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->iRowid = arg0->iSwitchRowid)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->iRowid < arg0->iSwitchRowid))))) = arg0->bRev)))) <> 0))))) Then
        ' C automatic storage declaration
        local2 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[Cast(c2fb_c_int, (arg1 Xor Cast(c2fb_c_int, &H0001ULL)))]))
        c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->iSwitchRowid))
        c2fb_temp_1 = Cast(c2fb_int64, IIf(arg0->bRev, (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))) - (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL)))))))))), (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL)))))))))
        (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->nSeg + arg1))) \ Cast(c2fb_c_int, 2ULL))))
        local1 = c2fb_temp_2
        While Cast(c2fb_c_int, 1ULL)
            local3 = CPtr(c2fb_Fts5CResult Ptr, @(CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[local1]))
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            If local3->bTermEq Then
                If (-Cast(c2fb_c_int, ((local0->iRowid = local2->iRowid)))) Then
                    Return Cast(c2fb_c_int, 1ULL)
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2->iRowid > local0->iRowid))))) = arg0->bRev)))) Then
                        c2fb_temp_4 = CPtr(c2fb_i64 Ptr, @(arg0->iSwitchRowid))
                        c2fb_temp_5 = Cast(c2fb_int64, local2->iRowid)
                        (*c2fb_temp_4) = Cast(c2fb_i64, c2fb_temp_5)
                        c2fb_temp_5 = Cast(c2fb_int64, (*c2fb_temp_4))
                        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, local2)
                        local0 = c2fb_temp_6
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2->iRowid > arg0->iSwitchRowid))))) = arg0->bRev)))) Then
                            c2fb_temp_7 = CPtr(c2fb_i64 Ptr, @(arg0->iSwitchRowid))
                            c2fb_temp_8 = Cast(c2fb_int64, local2->iRowid)
                            (*c2fb_temp_7) = Cast(c2fb_i64, c2fb_temp_8)
                            c2fb_temp_8 = Cast(c2fb_int64, (*c2fb_temp_7))
                        End If
                    End If
                End If
            End If
            c2fb_temp_9 = CPtr(c2fb_u16 Ptr, @(local3->iFirst))
            c2fb_temp_10 = Cast(UShort, Cast(UShort, ((CPtr(c2fb_Fts5SegIter Ptr, local0) - CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))))))
            (*c2fb_temp_9) = Cast(c2fb_u16, c2fb_temp_10)
            c2fb_temp_10 = Cast(UShort, (*c2fb_temp_9))
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 1ULL))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[Cast(c2fb_c_int, (local1 Xor Cast(c2fb_c_int, &H0001ULL)))].iFirst])))
            local2 = c2fb_temp_11
        c2fb_flow_1:
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 \ Cast(c2fb_c_int, 2ULL))))
            local1 = c2fb_temp_3
        Wend
        c2fb_flow_0:
    End If
    c2fb_temp_12 = CPtr(c2fb_Fts5SegIter Ptr Ptr, @((*arg2)))
    c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, local0)
    (*c2fb_temp_12) = c2fb_temp_13
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts5MultiIterSetEof CDecl Alias "fts5MultiIterSetEof" (ByVal arg0 As c2fb_Fts5Iter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3304
    Dim local0 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_0 As c2fb_u8 Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As c2fb_i64 Ptr
    Dim c2fb_temp_3 As c2fb_int64

    local0 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
    c2fb_temp_0 = CPtr(c2fb_u8 Ptr, @(arg0->base.bEof))
    c2fb_temp_1 = Cast(UByte, (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, local0->pLeaf) = Cast(c2fb_c_int, &O0ULL))))))
    (*c2fb_temp_0) = Cast(c2fb_u8, c2fb_temp_1)
    c2fb_temp_1 = Cast(UByte, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(c2fb_i64 Ptr, @(arg0->iSwitchRowid))
    c2fb_temp_3 = Cast(c2fb_int64, local0->iRowid)
    (*c2fb_temp_2) = Cast(c2fb_i64, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_int64, (*c2fb_temp_2))
End Sub
Private Function fts5IndexTombstoneQuery CDecl Alias "fts5IndexTombstoneQuery" (ByVal arg0 As c2fb_Fts5Data Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_uint64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3324
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_uint Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As c2fb_uint64 Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->p[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 4ULL))))), Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 8ULL)))
    local1 = (IIf(((-Cast(c2fb_c_int, ((arg0->nn > Cast(c2fb_c_int, 16ULL)))))), (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->nn - Cast(c2fb_c_int, 8ULL)))) \ (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->p[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 4ULL))))), Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 8ULL)))))), Cast(c2fb_c_int, 1ULL)))
    local2 = Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg2 \ Cast(c2fb_uint64, arg1)))) Mod Cast(c2fb_uint64, local1)))
    local3 = local1
    If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
        Return arg0->p[Cast(c2fb_c_int, 1ULL)]
    Else
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 4ULL))))) Then
            local4 = CPtr(c2fb_c_uint Ptr, CPtr(UByte Ptr, @(arg0->p[Cast(c2fb_c_int, 8ULL)])))
            While local4[local2]
                If (-Cast(c2fb_c_int, ((Cast(c2fb_uint64, fts5GetU32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, CPtr(c2fb_c_uint Ptr, @(local4[local2])))))) = arg2)))) Then
                    Return Cast(c2fb_c_int, 1ULL)
                End If
                c2fb_temp_0 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 - 1)))
                If (-Cast(c2fb_c_int, ((c2fb_temp_0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_0
                End If
                c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))) Mod local1)))
                local2 = c2fb_temp_1
            c2fb_flow_1:
            Wend
            c2fb_flow_0:
        Else
            local5 = CPtr(c2fb_uint64 Ptr, CPtr(UByte Ptr, @(arg0->p[Cast(c2fb_c_int, 8ULL)])))
            While local5[local2]
                If (-Cast(c2fb_c_int, ((fts5GetU64(CPtr(UByte Ptr, CPtr(c2fb_uint64 Ptr, @(local5[local2])))) = arg2)))) Then
                    Return Cast(c2fb_c_int, 1ULL)
                End If
                c2fb_temp_2 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 - 1)))
                If (-Cast(c2fb_c_int, ((c2fb_temp_2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_2
                End If
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))) Mod local1)))
                local2 = c2fb_temp_3
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        End If
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5MultiIterIsDeleted CDecl Alias "fts5MultiIterIsDeleted" (ByVal arg0 As c2fb_Fts5Iter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3360
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5SegIter Ptr
    Dim local2 As c2fb_Fts5TombstoneArray Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5Data Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Data Ptr

    local0 = CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst
    local1 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[local0]))
    local2 = CPtr(c2fb_Fts5TombstoneArray Ptr, local1->pTombArray)
    If (-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Data Ptr, local1->pLeaf) <> 0) AndAlso (local2 <> 0))))) Then
        local3 = Cast(c2fb_uint64, ((Cast(c2fb_uint64, local1->iRowid)) Mod Cast(c2fb_uint64, local2->nTombstone)))
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr Ptr, (c2fb_Fts5TombstoneArray_apTombstone_tail_ptr(local2)))[local3] = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(c2fb_Fts5Data Ptr Ptr, @(CPtr(c2fb_Fts5Data Ptr Ptr, (c2fb_Fts5TombstoneArray_apTombstone_tail_ptr(local2)))[local3]))
            c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (CPtr(c2fb_Fts5StructureSegment Ptr, local1->pSeg)->iSegid + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 16ULL)))))))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local3)))))))))
            (*c2fb_temp_0) = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr Ptr, (c2fb_Fts5TombstoneArray_apTombstone_tail_ptr(local2)))[local3] = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        End If
        Return fts5IndexTombstoneQuery(CPtr(c2fb_Fts5Data Ptr Ptr, (c2fb_Fts5TombstoneArray_apTombstone_tail_ptr(local2)))[local3], local2->nTombstone, local1->iRowid)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub fts5MultiIterNext CDecl Alias "fts5MultiIterNext" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3396
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_0 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = arg2
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))
        local1 = CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg1->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg1)))[local1]))
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso (CPtr(c2fb_Fts5DlidxIter Ptr, local3->pDlidx) <> 0))))) Then
            fts5SegIterNextFrom(arg0, local3, arg3)
        Else
            CPtr(c2fb_callback_348, local3->xNext)(arg0, local3, CPtr(c2fb_c_int Ptr, @(local2)))
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, local3->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (local2 <> 0) OrElse (fts5MultiIterAdvanceRowid(arg1, local1, CPtr(c2fb_Fts5SegIter Ptr Ptr, @(local3))) <> 0))))) Then
            fts5MultiIterAdvanced(arg0, arg1, local1, Cast(c2fb_c_int, 1ULL))
            fts5MultiIterSetEof(arg1)
            c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg1)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg1->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst])))
            local3 = c2fb_temp_0
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, local3->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) Then
                Return
            End If
        End If
        ' empty C statement
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->bSkipEmpty) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (local3->nPos <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5MultiIterIsDeleted(arg1))))) <> 0))))) Then
            CPtr(c2fb_callback_349, arg1->xSetOutputs)(arg1, local3)
            Return
        End If
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_1
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub
Private Sub fts5MultiIterNext2 CDecl Alias "fts5MultiIterNext2" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3436
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5SegIter Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
        Do
            local0 = CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg1->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst
            local1 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg1)))[local0]))
            local2 = Cast(c2fb_c_int, &O0ULL)
            ' C unused-parameter annotation
            CPtr(c2fb_callback_348, local1->xNext)(arg0, local1, CPtr(c2fb_c_int Ptr, @(local2)))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, local1->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (local2 <> 0) OrElse (fts5MultiIterAdvanceRowid(arg1, local0, CPtr(c2fb_Fts5SegIter Ptr Ptr, @(local1))) <> 0))))) Then
                fts5MultiIterAdvanced(arg0, arg1, local0, Cast(c2fb_c_int, 1ULL))
                fts5MultiIterSetEof(arg1)
                c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_2) = c2fb_temp_3
            End If
            ' empty C statement
        c2fb_flow_1:
        Loop While (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, (((fts5MultiIterIsEmpty(arg0, arg1) <> 0) OrElse (fts5MultiIterIsDeleted(arg1) <> 0)))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))) <> 0)))))
        c2fb_flow_0:
    End If
End Sub
Private Sub fts5IterSetOutputs_Noop CDecl Alias "fts5IterSetOutputs_Noop" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3466
    ' C unused-parameter annotation
End Sub
Private Function fts5MultiIterAlloc CDecl Alias "fts5MultiIterAlloc" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int) As c2fb_Fts5Iter Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3470
    Dim local0 As c2fb_Fts5Iter Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_Fts5CResult_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_Fts5CResult Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Index_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Index Ptr
    Type c2fb_callback_storage_9 As Sub CDecl(ByVal arg0 As c2fb_Fts5Iter_ Ptr, ByVal arg1 As c2fb_Fts5SegIter_ Ptr)
    Dim c2fb_temp_9 As c2fb_callback_storage_9 Ptr
    Dim c2fb_temp_10 As c2fb_callback_349

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_int64, arg1)))))
        ' empty C statement
    c2fb_flow_1:
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
        local1 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, CPtr(Any Ptr, fts5IdxMalloc(arg0, Cast(c2fb_uint64, ((Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5Iter_aSeg_tail_ptr(Cast(c2fb_Fts5Iter Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (local1)) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegIter)))))))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5CResult))) * Cast(c2fb_uint64, local1))))))))
    local0 = c2fb_temp_2
    If local0 Then
        c2fb_temp_3 = CPtr(Long Ptr, @(local0->nSeg))
        c2fb_temp_4 = Cast(c2fb_c_int, local1)
        (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        c2fb_temp_5 = CPtr(c2fb_Fts5CResult_ Ptr Ptr, @(local0->aFirst))
        c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local0)))[local1]))))
        (*c2fb_temp_5) = CPtr(c2fb_Fts5CResult_ Ptr, c2fb_temp_6)
        c2fb_temp_6 = CPtr(c2fb_Fts5CResult Ptr, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(c2fb_Fts5Index_ Ptr Ptr, @(local0->pIndex))
        c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0)
        (*c2fb_temp_7) = CPtr(c2fb_Fts5Index_ Ptr, c2fb_temp_8)
        c2fb_temp_8 = CPtr(c2fb_Fts5Index Ptr, (*c2fb_temp_7))
        c2fb_temp_9 = CPtr(c2fb_callback_storage_9 Ptr, @(local0->xSetOutputs))
        c2fb_temp_10 = ProcPtr(fts5IterSetOutputs_Noop)
        (*c2fb_temp_9) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Iter_ Ptr, ByVal arg1 As c2fb_Fts5SegIter_ Ptr), c2fb_temp_10)
        c2fb_temp_10 = CPtr(c2fb_callback_349, (*c2fb_temp_9))
    End If
    Return local0
End Function
Private Sub fts5PoslistCallback CDecl Alias "fts5PoslistCallback" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3491
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, arg1))->p[(CPtr(c2fb_Fts5Buffer Ptr, arg1))->n]))), CPtr(Const Any Ptr, arg2), arg3))
        c2fb_temp_1 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, arg1))->n))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_1)) + arg3)))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        ' empty C statement
    End If
End Sub
Private Function fts5IndexColsetTest CDecl Alias "fts5IndexColsetTest" (ByVal arg0 As c2fb_Fts5Colset Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
    Dim aiCol As Long Ptr
    Dim i As c2fb_c_int

    aiCol = c2fb_Fts5Colset_aiCol_tail_ptr(arg0)
    For i = 0 To arg0->nCol - 1
        If aiCol[i] = arg1 Then Return 1
    Next
    Return 0
End Function

Private Sub fts5PoslistOffsetsCallback CDecl Alias "fts5PoslistOffsetsCallback" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3529
    Dim local0 As c2fb_PoslistOffsetsCtx Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = CPtr(c2fb_PoslistOffsetsCtx Ptr, arg1)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        While (-Cast(c2fb_c_int, ((local1 < arg3))))
            ' C automatic storage declaration
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local2))))))))
            local1 = c2fb_temp_0
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, (local0->iRead - Cast(c2fb_c_int, 2ULL))))))
            local2 = c2fb_temp_1
            c2fb_temp_2 = CPtr(Long Ptr, @(local0->iRead))
            c2fb_temp_3 = Cast(c2fb_c_int, local2)
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            If fts5IndexColsetTest(CPtr(c2fb_Fts5Colset Ptr, local0->pColset), local2) Then
                c2fb_temp_4 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->n))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_4)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->p[(CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->n])), (Cast(c2fb_c_int, (Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 2ULL))) - local0->iWrite)))))))
                (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
                c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
                ' C unused-parameter annotation
                ' empty C statement
                c2fb_temp_6 = CPtr(Long Ptr, @(local0->iWrite))
                c2fb_temp_7 = Cast(c2fb_c_int, local2)
                (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
                c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
End Sub
Private Sub fts5PoslistFilterCallback CDecl Alias "fts5PoslistFilterCallback" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3552
    Dim local0 As c2fb_PoslistCallbackCtx Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Long Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As Any Ptr
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int

    local0 = CPtr(c2fb_PoslistCallbackCtx Ptr, arg1)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local0->eState = Cast(c2fb_c_int, 2ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_0 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
            c2fb_temp_1 = Cast(c2fb_c_int, (arg2)[c2fb_temp_0])
            local3 = c2fb_temp_1
            If Cast(c2fb_c_int, (local3 And Cast(c2fb_c_int, &H80ULL))) Then
                c2fb_temp_2 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 - 1)))
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((arg2)[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local3))))))))
                local1 = c2fb_temp_3
            End If
            ' empty C statement
            If fts5IndexColsetTest(CPtr(c2fb_Fts5Colset Ptr, local0->pColset), local3) Then
                c2fb_temp_4 = CPtr(Long Ptr, @(local0->eState))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
                c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
                c2fb_temp_6 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->n))
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_6)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->p[(CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->n])), (Cast(c2fb_c_int, 1ULL))))))
                (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
                c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
                ' C unused-parameter annotation
                ' empty C statement
            Else
                c2fb_temp_8 = CPtr(Long Ptr, @(local0->eState))
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
                c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
            End If
        End If
        Do
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg2[local1]) <> Cast(c2fb_c_int, &H01ULL))))) <> 0)))))
                local4 = Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 9ULL)))
                Do
                    c2fb_temp_10 = local1
                    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
                    If ((-Cast(c2fb_c_int, ((((Cast(c2fb_c_int, (Cast(c2fb_c_int, arg2[c2fb_temp_10]) And Cast(c2fb_c_int, &H80ULL)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < local4)))) <> 0))))) = 0) Then Goto c2fb_flow_4
                    ' empty C statement
                c2fb_flow_5:
                Loop
                c2fb_flow_4:
                ' empty C statement
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
            If local0->eState Then
                ' C unused-parameter annotation
                c2fb_temp_11 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->p[(CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->n]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(arg2[local2]))), Cast(c2fb_c_int, (local1 - local2))))
                c2fb_temp_12 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->n))
                c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_12)) + Cast(c2fb_c_int, (local1 - local2)))))
                (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
                c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
                ' empty C statement
            End If
            If (-Cast(c2fb_c_int, ((local1 < arg3)))) Then
                ' C automatic storage declaration
                c2fb_temp_14 = Cast(c2fb_c_int, local1)
                local2 = c2fb_temp_14
                c2fb_temp_15 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
                If (-Cast(c2fb_c_int, ((local1 >= arg3)))) Then
                    c2fb_temp_16 = CPtr(Long Ptr, @(local0->eState))
                    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                    (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
                    c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
                Else
                    c2fb_temp_18 = local1
                    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
                    c2fb_temp_19 = Cast(c2fb_c_int, (arg2)[c2fb_temp_18])
                    local5 = c2fb_temp_19
                    If Cast(c2fb_c_int, (local5 And Cast(c2fb_c_int, &H80ULL))) Then
                        c2fb_temp_20 = local1
                        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 - 1)))
                        c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((arg2)[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local5))))))))
                        local1 = c2fb_temp_21
                    End If
                    ' empty C statement
                    c2fb_temp_22 = CPtr(Long Ptr, @(local0->eState))
                    c2fb_temp_23 = Cast(c2fb_c_int, fts5IndexColsetTest(CPtr(c2fb_Fts5Colset Ptr, local0->pColset), local5))
                    (*c2fb_temp_22) = Cast(Long, c2fb_temp_23)
                    c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
                    If local0->eState Then
                        ' C unused-parameter annotation
                        c2fb_temp_24 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->p[(CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->n]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(arg2[local2]))), Cast(c2fb_c_int, (local1 - local2))))
                        c2fb_temp_25 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, local0->pBuf))->n))
                        c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_25)) + Cast(c2fb_c_int, (local1 - local2)))))
                        (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
                        c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
                        ' empty C statement
                        c2fb_temp_27 = Cast(c2fb_c_int, local1)
                        local2 = c2fb_temp_27
                    End If
                End If
            End If
        c2fb_flow_1:
        Loop While (-Cast(c2fb_c_int, ((local1 < arg3))))
        c2fb_flow_0:
    End If
End Sub
Private Sub fts5ChunkIterate CDecl Alias "fts5ChunkIterate" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_355)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3603
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Data Ptr
    Dim local2 As UByte Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Data Ptr

    local0 = arg1->nPos
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[arg1->iLeafOffset]))
    local3 = (IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_int64, (local0)) < (Cast(c2fb_int64, (Cast(c2fb_int64, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf) - arg1->iLeafOffset)))))))), Cast(c2fb_int64, (local0)), (Cast(c2fb_int64, (Cast(c2fb_int64, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf) - arg1->iLeafOffset)))))
    local4 = arg1->iLeafPgno
    local5 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg1->flags And Cast(c2fb_c_int, &H02ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL))))
        local5 = c2fb_temp_0
    End If
    While Cast(c2fb_c_int, 1ULL)
        arg3(arg0, arg2, CPtr(Const UByte Ptr, local2), local3)
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 - local3)))
        local0 = c2fb_temp_1
        fts5DataRelease(local1)
        If (-Cast(c2fb_c_int, ((local0 <= Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        Else
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg) = Cast(c2fb_c_int, &O0ULL))))) Then
                fts5IndexCorruptIdx(arg0)
                Return
            Else
                c2fb_temp_2 = local4
                local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
                c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local4)))))))))
                local1 = c2fb_temp_3
                If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_0
                End If
                c2fb_temp_4 = CPtr(UByte Ptr, @(local1->p[Cast(c2fb_c_int, 4ULL)]))
                local2 = c2fb_temp_4
                c2fb_temp_5 = Cast(c2fb_c_int, (IIf(((-Cast(c2fb_c_int, (((local0) < (Cast(c2fb_c_int, (local1->szLeaf - Cast(c2fb_c_int, 4ULL))))))))), (local0), (Cast(c2fb_c_int, (local1->szLeaf - Cast(c2fb_c_int, 4ULL)))))))
                local3 = c2fb_temp_5
                If (-Cast(c2fb_c_int, ((local4 = local5)))) Then
                    ' C unused-parameter annotation
                    c2fb_temp_6 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg1->pNextLeaf))
                    c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local1)
                    (*c2fb_temp_6) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_7)
                    c2fb_temp_7 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_6))
                    c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local1 = c2fb_temp_8
                End If
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub
Private Sub fts5SegiterPoslist CDecl Alias "fts5SegiterPoslist" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr, ByVal arg2 As c2fb_Fts5Colset Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3653
    Dim c2fb_temp_0 As Any Ptr
    Dim local0 As c2fb_PoslistCallbackCtx
    Dim c2fb_temp_1 As c2fb_Fts5Buffer_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local1 As c2fb_PoslistOffsetsCtx
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Buffer_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_10 As Any Ptr Ptr
    Dim c2fb_temp_11 As c2fb_Fts5Colset Ptr

    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((arg3)->n)) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (arg1->nPos + Cast(c2fb_c_int, 8ULL))))))) <= Cast(c2fb_c_uint, ((arg3)->nSpace)))))), Cast(c2fb_c_int, &O0ULL), c2fb_external_sqlite3Fts5BufferSize((CPtr(c2fb_c_int Ptr, @(arg0->rc))), (arg3), Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1->nPos + Cast(c2fb_c_int, 8ULL)))) + (arg3)->n))))))))) Then
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg3->p[Cast(c2fb_c_int, (arg3->n + arg1->nPos))]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 8ULL)))
        If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
            fts5ChunkIterate(arg0, arg1, CPtr(Any Ptr, arg3), ProcPtr(fts5PoslistCallback))
        Else
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C automatic storage declaration
                c2fb_temp_1 = CPtr(c2fb_Fts5Buffer_ Ptr Ptr, @(local0.pBuf))
                c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg3)
                (*c2fb_temp_1) = CPtr(c2fb_Fts5Buffer_ Ptr, c2fb_temp_2)
                c2fb_temp_2 = CPtr(c2fb_Fts5Buffer Ptr, (*c2fb_temp_1))
                c2fb_temp_3 = CPtr(Any Ptr Ptr, @(local0.pColset))
                c2fb_temp_4 = arg2
                (*c2fb_temp_3) = CPtr(Any Ptr, c2fb_temp_4)
                c2fb_temp_4 = CPtr(c2fb_Fts5Colset Ptr, (*c2fb_temp_3))
                c2fb_temp_5 = CPtr(Long Ptr, @(local0.eState))
                c2fb_temp_6 = Cast(c2fb_c_int, fts5IndexColsetTest(arg2, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
                ' C unused-parameter annotation
                fts5ChunkIterate(arg0, arg1, CPtr(Any Ptr, CPtr(c2fb_PoslistCallbackCtx Ptr, @(local0))), ProcPtr(fts5PoslistFilterCallback))
            Else
                ' C automatic storage declaration
                c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_PoslistOffsetsCtx Ptr, @(local1))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_PoslistOffsetsCtx))))
                c2fb_temp_8 = CPtr(c2fb_Fts5Buffer_ Ptr Ptr, @(local1.pBuf))
                c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg3)
                (*c2fb_temp_8) = CPtr(c2fb_Fts5Buffer_ Ptr, c2fb_temp_9)
                c2fb_temp_9 = CPtr(c2fb_Fts5Buffer Ptr, (*c2fb_temp_8))
                c2fb_temp_10 = CPtr(Any Ptr Ptr, @(local1.pColset))
                c2fb_temp_11 = arg2
                (*c2fb_temp_10) = CPtr(Any Ptr, c2fb_temp_11)
                c2fb_temp_11 = CPtr(c2fb_Fts5Colset Ptr, (*c2fb_temp_10))
                fts5ChunkIterate(arg0, arg1, CPtr(Any Ptr, CPtr(c2fb_PoslistOffsetsCtx Ptr, @(local1))), ProcPtr(fts5PoslistOffsetsCallback))
            End If
        End If
    End If
End Sub
Private Sub fts5IndexExtractColset CDecl Alias "fts5IndexExtractColset" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5Iter Ptr)
    Dim p As Const UByte Ptr
    Dim aCopy As Const UByte Ptr
    Dim pEnd As Const UByte Ptr
    Dim aiCol As Long Ptr
    Dim pBuf As c2fb_Fts5Buffer Ptr
    Dim i As c2fb_c_int
    Dim iCurrent As c2fb_c_int
    Dim iVarint As c2fb_c_uint
    Dim nBytes As c2fb_c_int
    Dim nCopy As c2fb_c_int

    If (*arg0) = 0 Then
        p = arg2
        aCopy = p
        pEnd = p + arg3
        aiCol = c2fb_Fts5Colset_aiCol_tail_ptr(arg1)
        pBuf = @arg4->poslist
        i = 0
        iCurrent = 0

        If arg1->nCol > 1 Then
            If c2fb_external_sqlite3Fts5BufferSize(arg0, pBuf, _
                Cast(c2fb_c_uint, arg3)) <> 0 Then Return
        End If

        While Cast(c2fb_c_int, 1)
            While aiCol[i] < iCurrent
                i += 1
                If i = arg1->nCol Then
                    arg4->base.pData = CPtr(Const c2fb_u8 Ptr, pBuf->p)
                    arg4->base.nData = pBuf->n
                    Return
                End If
            Wend

            While p < pEnd AndAlso p[0] <> 1
                While p < pEnd
                    nBytes = p[0]
                    p += 1
                    If (nBytes And &H80) = 0 Then Exit While
                Wend
            Wend

            If aiCol[i] = iCurrent Then
                If arg1->nCol = 1 Then
                    arg4->base.pData = CPtr(Const c2fb_u8 Ptr, aCopy)
                    arg4->base.nData = Cast(c2fb_c_int, p - aCopy)
                    Return
                End If

                nCopy = Cast(c2fb_c_int, p - aCopy)
                c2fb_crt_memcpy(CPtr(Any Ptr, @pBuf->p[pBuf->n]), _
                    CPtr(Const Any Ptr, aCopy), Cast(c2fb_size_t, nCopy))
                pBuf->n += nCopy
            End If

            If p >= pEnd Then
                arg4->base.pData = CPtr(Const c2fb_u8 Ptr, pBuf->p)
                arg4->base.nData = pBuf->n
                Return
            End If

            aCopy = p
            p += 1
            iCurrent = p[0]
            p += 1
            If (iCurrent And &H80) <> 0 Then
                p -= 1
                nBytes = c2fb_external_sqlite3Fts5GetVarint32(p, @iVarint)
                iCurrent = Cast(c2fb_c_int, iVarint)
                p += nBytes
            End If
        Wend
    End If
End Sub

Private Sub fts5IterSetOutputs_None CDecl Alias "fts5IterSetOutputs_None" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3758
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->base.iRowid))
    c2fb_temp_1 = Cast(c2fb_int64, arg1->iRowid)
    (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->base.nData))
    c2fb_temp_3 = Cast(c2fb_c_int, arg1->nPos)
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
End Sub
Private Sub fts5IterSetOutputs_Nocolset CDecl Alias "fts5IterSetOutputs_Nocolset" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3768
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_5 As Const UByte Ptr
    Dim c2fb_temp_6 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_7 As Const UByte Ptr

    c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->base.iRowid))
    c2fb_temp_1 = Cast(c2fb_int64, arg1->iRowid)
    (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->base.nData))
    c2fb_temp_3 = Cast(c2fb_c_int, arg1->nPos)
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (arg1->iLeafOffset + Cast(c2fb_int64, arg1->nPos))) <= Cast(c2fb_int64, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf))))) Then
        c2fb_temp_4 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg0->base.pData))
        c2fb_temp_5 = CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[arg1->iLeafOffset])))
        (*c2fb_temp_4) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_5)
        c2fb_temp_5 = CPtr(Const UByte Ptr, (*c2fb_temp_4))
    Else
        c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
        fts5SegiterPoslist(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), arg1, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
        c2fb_temp_6 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg0->base.pData))
        c2fb_temp_7 = CPtr(Const UByte Ptr, arg0->poslist.p)
        (*c2fb_temp_6) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_7)
        c2fb_temp_7 = CPtr(Const UByte Ptr, (*c2fb_temp_6))
    End If
End Sub
Private Sub fts5IterSetOutputs_ZeroColset CDecl Alias "fts5IterSetOutputs_ZeroColset" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3793
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_u8 Ptr
    Dim c2fb_temp_3 As UByte

    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->base.nData))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(c2fb_u8 Ptr, @(arg0->base.bEof))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_2) = Cast(c2fb_u8, c2fb_temp_3)
    c2fb_temp_3 = Cast(UByte, (*c2fb_temp_2))
End Sub
Private Sub fts5IterSetOutputs_Col CDecl Alias "fts5IterSetOutputs_Col" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3804
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
    fts5SegiterPoslist(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), arg1, CPtr(c2fb_Fts5Colset Ptr, arg0->pColset), CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
    c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->base.iRowid))
    c2fb_temp_1 = Cast(c2fb_int64, arg1->iRowid)
    (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg0->base.pData))
    c2fb_temp_3 = CPtr(Const UByte Ptr, arg0->poslist.p)
    (*c2fb_temp_2) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_3)
    c2fb_temp_3 = CPtr(Const UByte Ptr, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(Long Ptr, @(arg0->base.nData))
    c2fb_temp_5 = Cast(c2fb_c_int, arg0->poslist.n)
    (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
End Sub
Private Sub fts5IterSetOutputs_Full CDecl Alias "fts5IterSetOutputs_Full" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3865
    Dim local0 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim local1 As Const UByte Ptr
    Dim local2 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Colset Ptr, arg0->pColset)
#ifdef SQLITE_DEBUG
    If CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)->pConfig->eDetail <> FTS5_DETAIL_FULL Then _
        sqlite3DebugAssert(StrPtr(!"pIter->pIndex->pConfig->eDetail==FTS5_DETAIL_FULL"))
    If local0 = 0 Then sqlite3DebugAssert(StrPtr(!"pColset"))
#endif
    c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->base.iRowid))
    c2fb_temp_1 = Cast(c2fb_int64, arg1->iRowid)
    (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (arg1->iLeafOffset + Cast(c2fb_int64, arg1->nPos))) <= Cast(c2fb_int64, CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf))))) Then
        local1 = CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[arg1->iLeafOffset])))
        local2 = CPtr(c2fb_c_int Ptr, @(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)->rc))
        c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
        fts5IndexExtractColset(local2, local0, local1, arg1->nPos, arg0)
    Else
        c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
        fts5SegiterPoslist(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), arg1, local0, CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))
        c2fb_temp_2 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg0->base.pData))
        c2fb_temp_3 = CPtr(Const UByte Ptr, arg0->poslist.p)
        (*c2fb_temp_2) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_3)
        c2fb_temp_3 = CPtr(Const UByte Ptr, (*c2fb_temp_2))
        c2fb_temp_4 = CPtr(Long Ptr, @(arg0->base.nData))
        c2fb_temp_5 = Cast(c2fb_c_int, arg0->poslist.n)
        (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    End If
End Sub
Private Sub fts5IterSetOutputs_Col100 CDecl Alias "fts5IterSetOutputs_Col100" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
    Dim pConfig As c2fb_Fts5Config Ptr
    Dim pColset As c2fb_Fts5Colset Ptr
    Dim pCol As Long Ptr
    Dim pColEnd As Long Ptr
    Dim a As UByte Ptr
    Dim pEnd As UByte Ptr
    Dim aOut As UByte Ptr
    Dim iPrev As c2fb_c_int
    Dim iPrevOut As c2fb_c_int

    pConfig = CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)->pConfig
    pColset = CPtr(c2fb_Fts5Colset Ptr, arg0->pColset)

#ifdef SQLITE_DEBUG
    If pConfig->eDetail <> FTS5_DETAIL_COLUMNS Then _
        sqlite3DebugAssert(StrPtr(!"pIter->pIndex->pConfig->eDetail==FTS5_DETAIL_COLUMNS"))
    If arg0->pColset = 0 Then _
        sqlite3DebugAssert(StrPtr(!"pIter->pColset"))
    If arg0->poslist.nSpace < pConfig->nCol Then _
        sqlite3DebugAssert(StrPtr(!"pIter->poslist.nSpace>=pIter->pIndex->pConfig->nCol"))
#endif

    If (arg1->iLeafOffset + arg1->nPos > _
        CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf) OrElse _
        arg1->nPos > pConfig->nCol Then
        fts5IterSetOutputs_Col(arg0, arg1)
    Else
        a = CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p[arg1->iLeafOffset]))
        pEnd = a + arg1->nPos
        pCol = c2fb_Fts5Colset_aiCol_tail_ptr(pColset)
        pColEnd = pCol + pColset->nCol
        aOut = arg0->poslist.p
        iPrev = 0
        iPrevOut = 0

        arg0->base.iRowid = arg1->iRowid
        While a < pEnd
            iPrev += Cast(c2fb_c_int, a[0]) - 2
            a += 1
            While pCol[0] < iPrev
                pCol += 1
                If pCol = pColEnd Then Goto setoutputs_col_out
            Wend
            If pCol[0] = iPrev Then
                aOut[0] = Cast(UByte, (iPrev - iPrevOut) + 2)
                aOut += 1
                iPrevOut = iPrev
            End If
        Wend

setoutputs_col_out:
        arg0->base.pData = CPtr(Const c2fb_u8 Ptr, arg0->poslist.p)
        arg0->base.nData = Cast(c2fb_c_int, aOut - arg0->poslist.p)
    End If
End Sub

Private Sub fts5IterSetOutputCb CDecl Alias "fts5IterSetOutputCb" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr)
    Dim pConfig As c2fb_Fts5Config Ptr
    Dim pColset As c2fb_Fts5Colset Ptr

#ifdef SQLITE_DEBUG
    If arg1 = 0 AndAlso (*arg0) = 0 Then _
        sqlite3DebugAssert(StrPtr(!"pIter!=0 || (*pRc)!=SQLITE_OK"))
#endif
    If (*arg0) = 0 Then
        pConfig = CPtr(c2fb_Fts5Index Ptr, arg1->pIndex)->pConfig
        pColset = CPtr(c2fb_Fts5Colset Ptr, arg1->pColset)

        If pConfig->eDetail = FTS5_DETAIL_NONE Then
            arg1->xSetOutputs = ProcPtr(fts5IterSetOutputs_None)
        ElseIf arg1->pColset = 0 Then
            arg1->xSetOutputs = ProcPtr(fts5IterSetOutputs_Nocolset)
        ElseIf pColset->nCol = 0 Then
            arg1->xSetOutputs = ProcPtr(fts5IterSetOutputs_ZeroColset)
        ElseIf pConfig->eDetail = FTS5_DETAIL_FULL Then
            arg1->xSetOutputs = ProcPtr(fts5IterSetOutputs_Full)
        Else
#ifdef SQLITE_DEBUG
            If pConfig->eDetail <> FTS5_DETAIL_COLUMNS Then _
                sqlite3DebugAssert(StrPtr(!"pConfig->eDetail==FTS5_DETAIL_COLUMNS"))
#endif
            If pConfig->nCol <= 100 Then
                arg1->xSetOutputs = ProcPtr(fts5IterSetOutputs_Col100)
                c2fb_external_sqlite3Fts5BufferSize(arg0, _
                    @arg1->poslist, Cast(c2fb_c_uint, pConfig->nCol))
            Else
                arg1->xSetOutputs = ProcPtr(fts5IterSetOutputs_Col)
            End If
        End If
    End If
End Sub

Private Sub fts5MultiIterFinishSetup CDecl Alias "fts5MultiIterFinishSetup" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3926
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_Fts5SegIter Ptr
    Dim local3 As c2fb_Fts5SegIter Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->nSeg - Cast(c2fb_c_int, 1ULL))))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, &O0ULL)))))
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, fts5MultiIterDoCompare(arg1, local0))
        local1 = c2fb_temp_2
        If (c2fb_temp_2) Then
            local2 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg1)))[local1]))
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                CPtr(c2fb_callback_348, local2->xNext)(arg0, local2, Cast(c2fb_c_int, &O0ULL))
            End If
            fts5MultiIterAdvanced(arg0, arg1, local1, local0)
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
    Wend
    c2fb_flow_0:
    fts5MultiIterSetEof(arg1)
    ' empty C statement
    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, (((arg1->bSkipEmpty <> 0) AndAlso (fts5MultiIterIsEmpty(arg0, arg1) <> 0)))))) <> 0) OrElse (fts5MultiIterIsDeleted(arg1) <> 0))))) Then
        fts5MultiIterNext(arg0, arg1, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    Else
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->base.bEof) = Cast(c2fb_c_int, &O0ULL))))) Then
            local3 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg1)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg1->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
            CPtr(c2fb_callback_349, arg1->xSetOutputs)(arg1, local3)
        End If
    End If
End Sub
Private Sub fts5MultiIterNew CDecl Alias "fts5MultiIterNew" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Colset Ptr, ByVal arg4 As Const UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_Fts5Iter Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 3960
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5StructureLevel Ptr
    Dim local4 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Iter Ptr Ptr
    Dim c2fb_temp_5 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_u8 Ptr
    Dim c2fb_temp_9 As UByte
    Dim c2fb_temp_10 As Any Ptr Ptr
    Dim c2fb_temp_11 As c2fb_Fts5Colset Ptr
    Dim local5 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local6 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_13 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_14 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim local7 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local8 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_18 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_23 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_24 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_25 As c2fb_Fts5Iter Ptr Ptr
    Dim c2fb_temp_26 As c2fb_Fts5Iter Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
#ifdef SQLITE_DEBUG
    If (arg4 <> 0 OrElse arg5 <> 0) AndAlso arg6 >= 0 Then _
        sqlite3DebugAssert(StrPtr(!"(pTerm==0 && nTerm==0) || iLevel<0"))
#endif
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg6 < Cast(c2fb_c_int, &O0ULL))))) Then
#ifdef SQLITE_DEBUG
            If arg1->nSegment <> fts5StructureCountSegments(arg1) Then _
                sqlite3DebugAssert(StrPtr(!"pStruct->nSegment==fts5StructureCountSegments(pStruct)"))
#endif
            ' C unused-parameter annotation
            c2fb_temp_0 = Cast(c2fb_c_int, arg1->nSegment)
            local0 = c2fb_temp_0
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + ((-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Hash Ptr, arg0->pHash) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (Cast(c2fb_c_int, (arg2 And Cast(c2fb_c_int, &H0040ULL)))))))) <> 0)))))))))
            local0 = c2fb_temp_1
        Else
            c2fb_temp_2 = Cast(c2fb_c_int, (IIf(((-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[arg6].nSeg) < (arg7)))))), (CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[arg6].nSeg), (arg7))))
            local0 = c2fb_temp_2
        End If
    End If
    c2fb_temp_4 = CPtr(c2fb_Fts5Iter Ptr Ptr, @((*arg8)))
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, CPtr(c2fb_Fts5Iter Ptr, fts5MultiIterAlloc(arg0, local0)))
    local4 = c2fb_temp_3
    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, c2fb_temp_3)
    (*c2fb_temp_4) = c2fb_temp_5
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
#ifdef SQLITE_DEBUG
        If arg0->rc = SQLITE_OK Then _
            sqlite3DebugAssert(StrPtr(!"p->rc!=SQLITE_OK"))
#endif
        ' C unused-parameter annotation
        Goto c2fb_label_0
    End If
    c2fb_temp_6 = CPtr(Long Ptr, @(local4->bRev))
    c2fb_temp_7 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) <> (Cast(c2fb_c_int, (arg2 And Cast(c2fb_c_int, &H0002ULL))))))))))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(c2fb_u8 Ptr, @(local4->bSkipEmpty))
    c2fb_temp_9 = Cast(UByte, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) <> (Cast(c2fb_c_int, (arg2 And Cast(c2fb_c_int, &H0010ULL))))))))))
    (*c2fb_temp_8) = Cast(c2fb_u8, c2fb_temp_9)
    c2fb_temp_9 = Cast(UByte, (*c2fb_temp_8))
    c2fb_temp_10 = CPtr(Any Ptr Ptr, @(local4->pColset))
    c2fb_temp_11 = arg3
    (*c2fb_temp_10) = CPtr(Any Ptr, c2fb_temp_11)
    c2fb_temp_11 = CPtr(c2fb_Fts5Colset Ptr, (*c2fb_temp_10))
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg2 And Cast(c2fb_c_int, &H0020ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        fts5IterSetOutputCb(CPtr(c2fb_c_int Ptr, @(arg0->rc)), local4)
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg6 < Cast(c2fb_c_int, &O0ULL))))) Then
            local5 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[arg1->nLevel]))
            If (-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Hash Ptr, arg0->pHash) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (Cast(c2fb_c_int, (arg2 And Cast(c2fb_c_int, &H0040ULL)))))))) <> 0))))) Then
                c2fb_temp_12 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
                local6 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local4)))[c2fb_temp_12]))
                fts5SegIterHashInit(arg0, arg4, arg5, arg2, local6)
            End If
            c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5StructureLevel Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[Cast(c2fb_c_int, &O0ULL)])))
            local3 = c2fb_temp_13
            While (-Cast(c2fb_c_int, ((local3 < local5))))
                c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3->nSeg - Cast(c2fb_c_int, 1ULL))))
                local2 = c2fb_temp_15
                While (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL)))))
                    local7 = CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local3->aSeg))[local2]))
                    c2fb_temp_17 = local1
                    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
                    local8 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local4)))[c2fb_temp_17]))
                    If (-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, &O0ULL))))) Then
                        fts5SegIterInit(arg0, local7, local8)
                    Else
                        fts5SegIterSeekInit(arg0, arg4, arg5, arg2, local7, local8)
                    End If
                c2fb_flow_3:
                    c2fb_temp_16 = local2
                    local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_16 - 1)))
                Wend
                c2fb_flow_2:
            c2fb_flow_1:
                c2fb_temp_14 = local3
                local3 = (c2fb_temp_14 + 1)
            Wend
            c2fb_flow_0:
        Else
            c2fb_temp_18 = CPtr(_c2fb_record_c2fb_Fts5StructureLevel Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[arg6])))
            local3 = c2fb_temp_18
            c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL))))
            local2 = c2fb_temp_19
            While (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL)))))
                c2fb_temp_22 = arg0
                c2fb_temp_23 = CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local3->aSeg))[local2]))
                c2fb_temp_21 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
                c2fb_temp_24 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local4)))[c2fb_temp_21]))
                fts5SegIterInit(c2fb_temp_22, c2fb_temp_23, c2fb_temp_24)
            c2fb_flow_5:
                c2fb_temp_20 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 - 1)))
            Wend
            c2fb_flow_4:
        End If
#ifdef SQLITE_DEBUG
        If arg0->rc = SQLITE_OK AndAlso local1 <> local0 Then _
            sqlite3DebugAssert(StrPtr(!"iIter==nSeg"))
#endif
        ' C unused-parameter annotation
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        fts5MultiIterFinishSetup(arg0, local4)
    Else
        fts5MultiIterFree(local4)
        c2fb_temp_25 = CPtr(c2fb_Fts5Iter Ptr Ptr, @((*arg8)))
        c2fb_temp_26 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_25) = c2fb_temp_26
    End If
    c2fb_label_0:
#ifdef SQLITE_DEBUG
    If (*arg8) = 0 AndAlso arg0->rc = SQLITE_OK Then _
        sqlite3DebugAssert(StrPtr(!"(*ppOut)!=0 || p->rc!=SQLITE_OK"))
#endif
    ' C unused-parameter annotation
    Return
End Sub
Private Sub fts5MultiIterNew2 CDecl Alias "fts5MultiIterNew2" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Data Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Iter Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4049
    Dim local0 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Iter Ptr
    Dim local1 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_5 As c2fb_i64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_u16 Ptr
    Dim c2fb_temp_10 As UShort
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_16 As c2fb_u8 Ptr
    Dim c2fb_temp_17 As UByte
    Dim c2fb_temp_18 As c2fb_Fts5Iter Ptr Ptr
    Dim c2fb_temp_19 As c2fb_Fts5Iter Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, CPtr(c2fb_Fts5Iter Ptr, fts5MultiIterAlloc(arg0, Cast(c2fb_c_int, 2ULL))))
    local0 = c2fb_temp_0
    If local0 Then
        local1 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local0)))[Cast(c2fb_c_int, 1ULL)]))
        c2fb_temp_1 = CPtr(Long Ptr, @(local1->flags))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &H01ULL))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        If (-Cast(c2fb_c_int, ((arg1->szLeaf > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(local1->pLeaf))
            c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, arg1)
            (*c2fb_temp_3) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_4)
            c2fb_temp_4 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_3))
            c2fb_temp_5 = CPtr(c2fb_i64 Ptr, @(local1->iLeafOffset))
            c2fb_temp_6 = Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, arg1->p), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(local1->iRowid)))))
            (*c2fb_temp_5) = Cast(c2fb_i64, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_int64, (*c2fb_temp_5))
            c2fb_temp_7 = CPtr(Long Ptr, @(local1->iEndofDoclist))
            c2fb_temp_8 = Cast(c2fb_c_int, arg1->nn)
            (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
            c2fb_temp_9 = CPtr(c2fb_u16 Ptr, @(CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, local0->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst))
            c2fb_temp_10 = Cast(UShort, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_9) = Cast(c2fb_u16, c2fb_temp_10)
            c2fb_temp_10 = Cast(UShort, (*c2fb_temp_9))
            If arg2 Then
                c2fb_temp_11 = CPtr(Long Ptr, @(local0->bRev))
                c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
                c2fb_temp_13 = CPtr(Long Ptr, @(local1->flags))
                c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_13)) Or Cast(c2fb_c_int, &H02ULL))))
                (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
                c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
                fts5SegIterReverseInitPage(arg0, local1)
            Else
                fts5SegIterLoadNPos(arg0, local1)
            End If
            c2fb_temp_15 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            arg1 = c2fb_temp_15
        Else
            c2fb_temp_16 = CPtr(c2fb_u8 Ptr, @(local0->base.bEof))
            c2fb_temp_17 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_16) = Cast(c2fb_u8, c2fb_temp_17)
            c2fb_temp_17 = Cast(UByte, (*c2fb_temp_16))
        End If
        fts5SegIterSetNext(arg0, local1)
        c2fb_temp_18 = CPtr(c2fb_Fts5Iter Ptr Ptr, @((*arg3)))
        c2fb_temp_19 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, local0)
        (*c2fb_temp_18) = c2fb_temp_19
    End If
    fts5DataRelease(arg1)
End Sub
Private Function fts5MultiIterEof CDecl Alias "fts5MultiIterEof" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4088
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    Return ((-Cast(c2fb_c_int, (((arg0->rc <> 0) OrElse (arg1->base.bEof <> 0))))))
End Function
Private Function fts5MultiIterRowid CDecl Alias "fts5MultiIterRowid" (ByVal arg0 As c2fb_Fts5Iter Ptr) As c2fb_int64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4101
    ' C unused-parameter annotation
    Return CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst].iRowid
End Function
Private Sub fts5MultiIterNextFrom CDecl Alias "fts5MultiIterNextFrom" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4109
    Dim local0 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64

    While Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        fts5MultiIterNext(arg0, arg1, Cast(c2fb_c_int, 1ULL), arg2)
        If fts5MultiIterEof(arg0, arg1) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_0 = Cast(c2fb_int64, fts5MultiIterRowid(arg1))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->bRev = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 >= arg2)))) <> 0))))) Then
            Goto c2fb_flow_0
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->bRev <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 <= arg2)))) <> 0))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub
Private Function fts5MultiIterTerm CDecl Alias "fts5MultiIterTerm" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const UByte Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4128
    Dim local0 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, arg0->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_c_int, local0->term.n)
    (*c2fb_temp_0) = c2fb_temp_1
    Return CPtr(Const UByte Ptr, local0->term.p)
End Function
Private Function fts5AllocateSegid CDecl Alias "fts5AllocateSegid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4143
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1(0 To 62) As c2fb_c_uint
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_uint
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_uint Ptr
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg1->nSegment >= Cast(c2fb_c_int, 2000ULL))))) Then
            c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 13ULL))
            (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
            c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        Else
            ' C automatic array storage
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_c_uint Ptr, (@local1(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, (63ULL * SizeOf(c2fb_c_uint)))))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_3
            While (-Cast(c2fb_c_int, ((local2 < arg1->nLevel))))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_5
                While (-Cast(c2fb_c_int, ((local3 < CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[local2].nSeg))))
                    local6 = CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[local2].aSeg[local3].iSegid
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 <= Cast(c2fb_c_int, 2000ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6 > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        c2fb_temp_7 = CPtr(c2fb_c_uint Ptr, @(local1(Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local6 - Cast(c2fb_c_int, 1ULL)))) \ Cast(c2fb_c_int, 32ULL))))))
                        c2fb_temp_8 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, ((*c2fb_temp_7) Or Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)) Shl (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local6 - Cast(c2fb_c_int, 1ULL)))) Mod Cast(c2fb_c_int, 32ULL)))))))))
                        (*c2fb_temp_7) = c2fb_temp_8
                    End If
                c2fb_flow_3:
                    c2fb_temp_6 = local3
                    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
                Wend
                c2fb_flow_2:
            c2fb_flow_1:
                c2fb_temp_4 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
            Wend
            c2fb_flow_0:
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local4 = c2fb_temp_9
            While (-Cast(c2fb_c_int, ((local1(local4) = Cast(c2fb_c_uint, &HFFFFFFFFULL)))))
                ' empty C statement
            c2fb_flow_5:
                c2fb_temp_10 = local4
                local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
            Wend
            c2fb_flow_4:
            c2fb_temp_11 = Cast(c2fb_c_uint, local1(local4))
            local5 = c2fb_temp_11
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_12
            While Cast(c2fb_c_uint, (local5 And (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)) Shl local0)))))
                ' empty C statement
            c2fb_flow_7:
                c2fb_temp_13 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
            Wend
            c2fb_flow_6:
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + Cast(c2fb_c_int, (local4 * Cast(c2fb_c_int, 32ULL))))))))
            local0 = c2fb_temp_14
        End If
    End If
    Return local0
End Function
Private Sub fts5IndexDiscardData CDecl Alias "fts5IndexDiscardData" (ByVal arg0 As c2fb_Fts5Index Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4200
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    ' C unused-parameter annotation
    If CPtr(c2fb_Fts5Hash Ptr, arg0->pHash) Then
        c2fb_external_sqlite3Fts5HashClear(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash))
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->nPendingData))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->nPendingRow))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        c2fb_temp_4 = CPtr(Long Ptr, @(arg0->flushRc))
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    End If
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->nContentlessDelete))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
End Sub
Private Function fts5PrefixCompress CDecl Alias "fts5PrefixCompress" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const UByte Ptr, ByVal arg2 As Const UByte Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4218
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1[local0]) <> Cast(c2fb_c_int, arg2[local0]))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Sub fts5WriteDlidxClear CDecl Alias "fts5WriteDlidxClear" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4226
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_Fts5DlidxWriter Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
#ifdef SQLITE_DEBUG
    If arg2 <> 0 AndAlso _
       (arg1->nDlidx <= 0 OrElse _
        CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx)[0].buf.n <= 0) Then _
        sqlite3DebugAssert(StrPtr(!"bFlush==0 || (pWriter->nDlidx>0 && pWriter->aDlidx[0].buf.n>0)"))
#endif
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1->nDlidx))))
        local1 = CPtr(c2fb_Fts5DlidxWriter Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx))[local0]))
        If (-Cast(c2fb_c_int, ((local1->buf.n = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        If arg2 Then
#ifdef SQLITE_DEBUG
            If local1->pgno = 0 Then _
                sqlite3DebugAssert(StrPtr(!"pDlidx->pgno!=0"))
#endif
            ' C unused-parameter annotation
            fts5DataWrite(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (local0)) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local1->pgno)))))), CPtr(Const UByte Ptr, local1->buf.p), local1->buf.n)
        End If
        c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)))
        c2fb_temp_2 = CPtr(Long Ptr, @(local1->bPrevValid))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
End Sub
Private Function fts5WriteDlidxGrow CDecl Alias "fts5WriteDlidxGrow" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4252
    Dim local0 As c2fb_Fts5DlidxWriter Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_size_t
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_Fts5DlidxWriter_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5DlidxWriter Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 >= arg1->nDlidx)))) <> 0))))) Then
        local0 = CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx)), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5DlidxWriter))) * Cast(c2fb_uint64, arg2))))))
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
            c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        Else
            local1 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5DlidxWriter))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (arg2 - arg1->nDlidx))))))
            c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, local0)[arg1->nDlidx]))), Cast(c2fb_c_int, &O0ULL), local1))
            c2fb_temp_3 = CPtr(c2fb_Fts5DlidxWriter_ Ptr Ptr, @(arg1->aDlidx))
            c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5DlidxWriter Ptr, local0)
            (*c2fb_temp_3) = CPtr(c2fb_Fts5DlidxWriter_ Ptr, c2fb_temp_4)
            c2fb_temp_4 = CPtr(c2fb_Fts5DlidxWriter Ptr, (*c2fb_temp_3))
            c2fb_temp_5 = CPtr(Long Ptr, @(arg1->nDlidx))
            c2fb_temp_6 = Cast(c2fb_c_int, arg2)
            (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        End If
    End If
    Return arg0->rc
End Function
Private Function fts5WriteFlushDlidx CDecl Alias "fts5WriteFlushDlidx" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4278
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx))[Cast(c2fb_c_int, &O0ULL)].buf.n > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->nEmpty >= Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_0
    End If
    fts5WriteDlidxClear(arg0, arg1, local0)
    c2fb_temp_1 = CPtr(Long Ptr, @(arg1->nEmpty))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    Return local0
End Function
Private Sub fts5WriteFlushBtree CDecl Alias "fts5WriteFlushBtree" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4302
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    If arg1->iBtPage = 0 AndAlso arg1->nEmpty <> 0 Then _
        sqlite3DebugAssert(StrPtr(!"pWriter->iBtPage || pWriter->nEmpty==0"))
#endif
    If (-Cast(c2fb_c_int, ((arg1->iBtPage = Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, fts5WriteFlushDlidx(arg0, arg1))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = (IIf((-Cast(c2fb_c_int, ((arg1->btterm.n > Cast(c2fb_c_int, &O0ULL))))), CPtr(Const ZString Ptr, arg1->btterm.p), StrPtr(!"")))
        sqlite3_bind_blob(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxWriter)), Cast(c2fb_c_int, 2ULL), CPtr(Const Any Ptr, local1), arg1->btterm.n, CPtr(Any Ptr, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
        sqlite3_bind_int64(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxWriter)), Cast(c2fb_c_int, 3ULL), Cast(c2fb_int64, (Cast(c2fb_int64, local0) + (Cast(c2fb_int64, (Cast(c2fb_int64, arg1->iBtPage) Shl Cast(c2fb_c_int, 1ULL)))))))
        sqlite3_step(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxWriter)))
        c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_2 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxWriter))))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        sqlite3_bind_null(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxWriter)), Cast(c2fb_c_int, 2ULL))
    End If
    c2fb_temp_3 = CPtr(Long Ptr, @(arg1->iBtPage))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
End Sub
Private Sub fts5WriteBtreeTerm CDecl Alias "fts5WriteBtreeTerm" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4331
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    fts5WriteFlushBtree(arg0, arg1)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg1->btterm)), arg2, arg3)
        c2fb_temp_0 = CPtr(Long Ptr, @(arg1->iBtPage))
        c2fb_temp_1 = Cast(c2fb_c_int, arg1->writer.pgno)
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    End If
End Sub
Private Sub fts5WriteBtreeNoTerm CDecl Alias "fts5WriteBtreeNoTerm" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4347
    Dim local0 As c2fb_Fts5DlidxWriter Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((arg1->bFirstRowidInPage <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx))[Cast(c2fb_c_int, &O0ULL)].buf.n > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        local0 = CPtr(c2fb_Fts5DlidxWriter Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx))[Cast(c2fb_c_int, &O0ULL)]))
#ifdef SQLITE_DEBUG
        If local0->bPrevValid = 0 Then _
            sqlite3DebugAssert(StrPtr(!"pDlidx->bPrevValid"))
#endif
        ' C unused-parameter annotation
        c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0->buf)), Cast(c2fb_c_int, &O0ULL))
    End If
    c2fb_temp_0 = CPtr(Long Ptr, @(arg1->nEmpty))
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
End Sub
Private Function fts5DlidxExtractFirstRowid CDecl Alias "fts5DlidxExtractFirstRowid" (ByVal arg0 As c2fb_Fts5Buffer Ptr) As c2fb_int64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4363
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->p[Cast(c2fb_c_int, 1ULL)]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(local0))))))))
    local1 = c2fb_temp_0
    c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->p[local1]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(local0))))
    Return local0
End Function
Private Sub fts5WriteDlidxAppend CDecl Alias "fts5WriteDlidxAppend" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4377
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_Fts5DlidxWriter Ptr
    Dim c2fb_temp_2 As c2fb_u8 Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As c2fb_Fts5DlidxWriter Ptr
    Dim local4 As c2fb_int64
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_i64 Ptr
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_int64
    Dim local5 As c2fb_int64
    Dim c2fb_temp_17 As c2fb_int64
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_i64 Ptr
    Dim c2fb_temp_21 As c2fb_int64

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C automatic storage declaration
        local3 = CPtr(c2fb_Fts5DlidxWriter Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx))[local0]))
        If (-Cast(c2fb_c_int, ((local3->buf.n >= CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz)))) Then
            c2fb_temp_2 = CPtr(c2fb_u8 Ptr, @(local3->buf.p[Cast(c2fb_c_int, &O0ULL)]))
            c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, &H01ULL))
            (*c2fb_temp_2) = Cast(c2fb_u8, c2fb_temp_3)
            c2fb_temp_3 = Cast(UByte, (*c2fb_temp_2))
            fts5DataWrite(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (local0)) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local3->pgno)))))), CPtr(Const UByte Ptr, local3->buf.p), local3->buf.n)
            fts5WriteDlidxGrow(arg0, arg1, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 2ULL))))
            c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx))[local0])))
            local3 = c2fb_temp_4
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5DlidxWriter Ptr, local3)[Cast(c2fb_c_int, 1ULL)].buf.n = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                local4 = fts5DlidxExtractFirstRowid(CPtr(c2fb_Fts5Buffer Ptr, @(local3->buf)))
                c2fb_temp_5 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, local3)[Cast(c2fb_c_int, 1ULL)].pgno))
                c2fb_temp_6 = Cast(c2fb_c_int, local3->pgno)
                (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, local3)[Cast(c2fb_c_int, 1ULL)].buf)), Cast(c2fb_c_int, &O0ULL))
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, local3)[Cast(c2fb_c_int, 1ULL)].buf)), local3->pgno)
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, local3)[Cast(c2fb_c_int, 1ULL)].buf)), local4)
                c2fb_temp_7 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, local3)[Cast(c2fb_c_int, 1ULL)].bPrevValid))
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
                c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                c2fb_temp_9 = CPtr(c2fb_i64 Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, local3)[Cast(c2fb_c_int, 1ULL)].iPrev))
                c2fb_temp_10 = Cast(c2fb_int64, local4)
                (*c2fb_temp_9) = Cast(c2fb_i64, c2fb_temp_10)
                c2fb_temp_10 = Cast(c2fb_int64, (*c2fb_temp_9))
            End If
            c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(local3->buf)))
            c2fb_temp_11 = CPtr(Long Ptr, @(local3->bPrevValid))
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
            c2fb_temp_13 = CPtr(Long Ptr, @(local3->pgno))
            c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
            (*c2fb_temp_13) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
        Else
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local1 = c2fb_temp_15
        End If
        If local3->bPrevValid Then
            c2fb_temp_16 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, arg2) - Cast(c2fb_uint64, local3->iPrev))))
            local2 = c2fb_temp_16
        Else
            local5 = (IIf((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))), arg1->writer.pgno, CPtr(c2fb_Fts5DlidxWriter Ptr, local3)[Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))].pgno))
#ifdef SQLITE_DEBUG
            If local3->buf.n <> 0 Then _
                sqlite3DebugAssert(StrPtr(!"pDlidx->buf.n==0"))
#endif
            ' C unused-parameter annotation
            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local3->buf)), (-Cast(c2fb_c_int, (local1 = 0))))
            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local3->buf)), local5)
            c2fb_temp_17 = Cast(c2fb_int64, arg2)
            local2 = c2fb_temp_17
        End If
        c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local3->buf)), local2)
        c2fb_temp_18 = CPtr(Long Ptr, @(local3->bPrevValid))
        c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
        c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
        c2fb_temp_20 = CPtr(c2fb_i64 Ptr, @(local3->iPrev))
        c2fb_temp_21 = Cast(c2fb_int64, arg2)
        (*c2fb_temp_20) = Cast(c2fb_i64, c2fb_temp_21)
        c2fb_temp_21 = Cast(c2fb_int64, (*c2fb_temp_20))
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
End Sub
Private Sub fts5WriteFlushLeaf CDecl Alias "fts5WriteFlushLeaf" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4437
    Static local0(0 To 3) As UByte = {Cast(UByte, Cast(c2fb_c_int, &H00ULL)), Cast(UByte, Cast(c2fb_c_int, &H00ULL)), Cast(UByte, Cast(c2fb_c_int, &H00ULL)), Cast(UByte, Cast(c2fb_c_int, &H00ULL))}
    Dim local1 As c2fb_Fts5PageWriter Ptr
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_u8 Ptr
    Dim c2fb_temp_8 As UByte
    Dim c2fb_temp_9 As c2fb_u8 Ptr
    Dim c2fb_temp_10 As UByte

    ' C static array storage
    local1 = CPtr(c2fb_Fts5PageWriter Ptr, @(arg1->writer))
#ifdef SQLITE_DEBUG
    If (local1->pgidx.n = 0) <> (arg1->bFirstTermInPage <> 0) Then _
        sqlite3DebugAssert(StrPtr(!"(pPage->pgidx.n==0)==(pWriter->bFirstTermInPage)"))
#endif
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
#ifdef SQLITE_DEBUG
    If fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1->buf.p[Cast(c2fb_c_int, 2ULL)])))) <> 0 Then _
        sqlite3DebugAssert(StrPtr(!"0==fts5GetU16(&pPage->buf.p[2])"))
#endif
    fts5PutU16(CPtr(UByte Ptr, @(local1->buf.p[Cast(c2fb_c_int, 2ULL)])), Cast(UShort, local1->buf.n))
    If arg1->bFirstTermInPage Then
#ifdef SQLITE_DEBUG
        If local1->pgidx.n <> 0 Then _
            sqlite3DebugAssert(StrPtr(!"pPage->pgidx.n==0"))
#endif
        ' C unused-parameter annotation
        fts5WriteBtreeNoTerm(arg0, arg1)
    Else
        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)), local1->pgidx.n, CPtr(Const UByte Ptr, local1->pgidx.p))
    End If
    c2fb_temp_0 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local1->pgno)))))))
    local2 = c2fb_temp_0
    fts5DataWrite(arg0, local2, CPtr(Const UByte Ptr, local1->buf.p), local1->buf.n)
    c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)))
    c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(local1->pgidx)))
    c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)), Cast(c2fb_c_int, 4ULL), CPtr(Const UByte Ptr, CPtr(UByte Ptr, (@local0(0)))))
    c2fb_temp_1 = CPtr(Long Ptr, @(local1->iPrevPgidx))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(Long Ptr, @(local1->pgno))
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    c2fb_temp_5 = CPtr(Long Ptr, @(arg1->nLeafWritten))
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    (*c2fb_temp_5) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
    c2fb_temp_7 = CPtr(c2fb_u8 Ptr, @(arg1->bFirstTermInPage))
    c2fb_temp_8 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_7) = Cast(c2fb_u8, c2fb_temp_8)
    c2fb_temp_8 = Cast(UByte, (*c2fb_temp_7))
    c2fb_temp_9 = CPtr(c2fb_u8 Ptr, @(arg1->bFirstRowidInPage))
    c2fb_temp_10 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_9) = Cast(c2fb_u8, c2fb_temp_10)
    c2fb_temp_10 = Cast(UByte, (*c2fb_temp_9))
End Sub
Private Sub fts5WriteAppendTerm CDecl Alias "fts5WriteAppendTerm" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4483
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5PageWriter Ptr
    Dim local2 As c2fb_Fts5Buffer Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_Fts5PageWriter Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_u8 Ptr
    Dim c2fb_temp_10 As UByte
    Dim c2fb_temp_11 As c2fb_u8 Ptr
    Dim c2fb_temp_12 As UByte
    Dim c2fb_temp_13 As c2fb_u8 Ptr
    Dim c2fb_temp_14 As UByte
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5PageWriter Ptr, @(arg1->writer))
    local2 = CPtr(c2fb_Fts5Buffer Ptr, @(arg1->writer.pgidx))
    local3 = (IIf(((-Cast(c2fb_c_int, (((local1->term.n) < (arg2)))))), (local1->term.n), (arg2)))
#ifdef SQLITE_DEBUG
    If arg0->rc <> SQLITE_OK Then _
        sqlite3DebugAssert(StrPtr(!"p->rc==SQLITE_OK"))
    If local1->buf.n < 4 Then _
        sqlite3DebugAssert(StrPtr(!"pPage->buf.n>=4"))
    If local1->buf.n <= 4 AndAlso arg1->bFirstTermInPage = 0 Then _
        sqlite3DebugAssert(StrPtr(!"pPage->buf.n>4 || pWriter->bFirstTermInPage"))
#endif
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (local1->buf.n + local2->n)) + arg2)) + Cast(c2fb_c_int, 2ULL)))) >= CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz)))) Then
        If (-Cast(c2fb_c_int, ((local1->buf.n > Cast(c2fb_c_int, 4ULL))))) Then
            fts5WriteFlushLeaf(arg0, arg1)
            If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return
            End If
        End If
        c2fb_temp_0 = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)))->n)) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 20ULL))))))) <= Cast(c2fb_c_uint, ((CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)))->nSpace)))))), Cast(c2fb_c_int, &O0ULL), c2fb_external_sqlite3Fts5BufferSize((CPtr(c2fb_c_int Ptr, @(arg0->rc))), (CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf))), Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 20ULL)))) + (CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)))->n)))))
    End If
    c2fb_temp_1 = CPtr(Long Ptr, @(local2->n))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_1)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2->p[local2->n])), Cast(c2fb_c_int, (local1->buf.n - local1->iPrevPgidx))))))
    (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(Long Ptr, @(local1->iPrevPgidx))
    c2fb_temp_4 = Cast(c2fb_c_int, local1->buf.n)
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    If arg1->bFirstTermInPage Then
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_5
        If (-Cast(c2fb_c_int, ((local1->pgno <> Cast(c2fb_c_int, 1ULL))))) Then
            local4 = arg2
            If local1->term.n Then
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + fts5PrefixCompress(local3, CPtr(Const UByte Ptr, local1->term.p), arg3))))
                local4 = c2fb_temp_6
            End If
            fts5WriteBtreeTerm(arg0, arg1, local4, arg3)
            If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return
            End If
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5PageWriter Ptr, CPtr(c2fb_Fts5PageWriter Ptr, @(arg1->writer)))
            local1 = c2fb_temp_7
        End If
    Else
        c2fb_temp_8 = Cast(c2fb_c_int, fts5PrefixCompress(local3, CPtr(Const UByte Ptr, local1->term.p), arg3))
        local0 = c2fb_temp_8
        c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)), Cast(c2fb_int64, local0))
    End If
    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)), Cast(c2fb_int64, (Cast(c2fb_int64, arg2) - Cast(c2fb_int64, local0))))
    c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)), Cast(c2fb_c_int, (arg2 - local0)), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg3[local0]))))
    c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1->term)), arg2, arg3)
    c2fb_temp_9 = CPtr(c2fb_u8 Ptr, @(arg1->bFirstTermInPage))
    c2fb_temp_10 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_9) = Cast(c2fb_u8, c2fb_temp_10)
    c2fb_temp_10 = Cast(UByte, (*c2fb_temp_9))
    c2fb_temp_11 = CPtr(c2fb_u8 Ptr, @(arg1->bFirstRowidInPage))
    c2fb_temp_12 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_11) = Cast(c2fb_u8, c2fb_temp_12)
    c2fb_temp_12 = Cast(UByte, (*c2fb_temp_11))
    c2fb_temp_13 = CPtr(c2fb_u8 Ptr, @(arg1->bFirstRowidInDoclist))
    c2fb_temp_14 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_13) = Cast(c2fb_u8, c2fb_temp_14)
    c2fb_temp_14 = Cast(UByte, (*c2fb_temp_13))
#ifdef SQLITE_DEBUG
    If arg0->rc = SQLITE_OK AndAlso _
       (arg1->nDlidx <= 0 OrElse _
        CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx)[0].buf.n <> 0) Then _
        sqlite3DebugAssert(StrPtr(!"p->rc || (pWriter->nDlidx>0 && pWriter->aDlidx[0].buf.n==0)"))
#endif
    ' C unused-parameter annotation
    c2fb_temp_15 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx))[Cast(c2fb_c_int, &O0ULL)].pgno))
    c2fb_temp_16 = Cast(c2fb_c_int, local1->pgno)
    (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
    c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
End Sub
Private Sub fts5WriteAppendRowid CDecl Alias "fts5WriteAppendRowid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4564
    Dim local0 As c2fb_Fts5PageWriter Ptr
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_u8 Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As c2fb_u8 Ptr
    Dim c2fb_temp_5 As UByte

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = CPtr(c2fb_Fts5PageWriter Ptr, @(arg1->writer))
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local0->buf.n + local0->pgidx.n))) >= CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz)))) Then
            fts5WriteFlushLeaf(arg0, arg1)
        End If
        If arg1->bFirstRowidInPage Then
            fts5PutU16(local0->buf.p, Cast(UShort, local0->buf.n))
            fts5WriteDlidxAppend(arg0, arg1, arg2)
        End If
        If (-Cast(c2fb_c_int, (((arg1->bFirstRowidInDoclist <> 0) OrElse (arg1->bFirstRowidInPage <> 0))))) Then
            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0->buf)), Cast(c2fb_int64, arg2))
        Else
            ' C unused-parameter annotation
            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0->buf)), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, Cast(c2fb_uint64, arg2))) - Cast(c2fb_uint64, arg1->iPrevRowid))))
        End If
        c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg1->iPrevRowid))
        c2fb_temp_1 = Cast(c2fb_int64, arg2)
        (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(c2fb_u8 Ptr, @(arg1->bFirstRowidInDoclist))
        c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_2) = Cast(c2fb_u8, c2fb_temp_3)
        c2fb_temp_3 = Cast(UByte, (*c2fb_temp_2))
        c2fb_temp_4 = CPtr(c2fb_u8 Ptr, @(arg1->bFirstRowidInPage))
        c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_4) = Cast(c2fb_u8, c2fb_temp_5)
        c2fb_temp_5 = Cast(UByte, (*c2fb_temp_4))
    End If
End Sub
Private Sub fts5WriteAppendPoslistData CDecl Alias "fts5WriteAppendPoslistData" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4599
    Dim local0 As c2fb_Fts5PageWriter Ptr
    Dim local1 As Const UByte Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5PageWriter Ptr, @(arg1->writer))
    local1 = arg2
    local2 = arg3
#ifdef SQLITE_DEBUG
    If CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz <= 0 AndAlso arg0->rc = SQLITE_OK Then _
        sqlite3DebugAssert(StrPtr(!"p->pConfig->pgsz>0 || p->rc!=SQLITE_OK"))
#endif
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0->buf.n + local0->pgidx.n)) + local2))) >= CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz)))) <> 0)))))
        local3 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz - local0->buf.n)) - local0->pgidx.n))
        local4 = Cast(c2fb_c_int, &O0ULL)
        While (-Cast(c2fb_c_int, ((local4 < local3))))
            ' C automatic storage declaration
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1[local4]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(local5))))))))
            local4 = c2fb_temp_0
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0->buf)), local4, local1)
        c2fb_temp_1 = CPtr(Const UByte Ptr, (local1 + local4))
        local1 = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 - local4)))
        local2 = c2fb_temp_2
        fts5WriteFlushLeaf(arg0, arg1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local2 > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local0->buf)), local2, local1)
    End If
End Sub
Private Sub fts5WriteFinish CDecl Alias "fts5WriteFinish" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4633
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5PageWriter Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5PageWriter Ptr, @(arg1->writer))
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
#ifdef SQLITE_DEBUG
        If local1->pgno < 1 Then _
            sqlite3DebugAssert(StrPtr(!"pLeaf->pgno>=1"))
#endif
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local1->buf.n > Cast(c2fb_c_int, 4ULL))))) Then
            fts5WriteFlushLeaf(arg0, arg1)
        End If
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1->pgno - Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_0) = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local1->pgno > Cast(c2fb_c_int, 1ULL))))) Then
            fts5WriteFlushBtree(arg0, arg1)
        End If
    End If
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local1->term)))
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local1->buf)))
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local1->pgidx)))
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(arg1->btterm)))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local0 < arg1->nDlidx))))
        c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5DlidxWriter Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx))[local0].buf)))
    c2fb_flow_1:
        c2fb_temp_3 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5DlidxWriter Ptr, arg1->aDlidx)))
End Sub
Private Sub fts5WriteInit CDecl Alias "fts5WriteInit" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegWriter Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4661
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_u8 Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local1 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int

    local0 = Cast(c2fb_c_int, (CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz + Cast(c2fb_c_int, 20ULL)))
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegWriter))))
    c2fb_temp_1 = CPtr(Long Ptr, @(arg1->iSegid))
    c2fb_temp_2 = Cast(c2fb_c_int, arg2)
    (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    fts5WriteDlidxGrow(arg0, arg1, Cast(c2fb_c_int, 1ULL))
    c2fb_temp_3 = CPtr(Long Ptr, @(arg1->writer.pgno))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    c2fb_temp_5 = CPtr(c2fb_u8 Ptr, @(arg1->bFirstTermInPage))
    c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_5) = Cast(c2fb_u8, c2fb_temp_6)
    c2fb_temp_6 = Cast(UByte, (*c2fb_temp_5))
    c2fb_temp_7 = CPtr(Long Ptr, @(arg1->iBtPage))
    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
#ifdef SQLITE_DEBUG
    If arg1->writer.buf.n <> 0 Then _
        sqlite3DebugAssert(StrPtr(!"pWriter->writer.buf.n==0"))
    If arg1->writer.pgidx.n <> 0 Then _
        sqlite3DebugAssert(StrPtr(!"pWriter->writer.pgidx.n==0"))
#endif
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_external_sqlite3Fts5BufferSize(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg1->writer.pgidx)), local0)
    c2fb_external_sqlite3Fts5BufferSize(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(arg1->writer.buf)), local0)
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxWriter) = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pIdxWriter)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"INSERT INTO '%q'.'%q_idx'(segid,term,pgno) VALUES(?,?,?)"), local1->zDb, local1->zName)))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg1->writer.buf.p), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 4ULL)))
        c2fb_temp_10 = CPtr(Long Ptr, @(arg1->writer.buf.n))
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        sqlite3_bind_int(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxWriter)), Cast(c2fb_c_int, 1ULL), arg1->iSegid)
    End If
End Sub
Private Sub fts5TrimSegments CDecl Alias "fts5TrimSegments" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Iter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4708
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Buffer
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_Fts5Data Ptr
    Dim local6 As c2fb_c_int
    Dim local7(0 To 3) As UByte
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local1))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg1->nSeg)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        local2 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg1)))[local0]))
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5StructureSegment Ptr, local2->pSeg) = Cast(c2fb_c_int, &O0ULL))))) Then
            ' empty C block
        Else
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Data Ptr, local2->pLeaf) = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_3 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, local2->pSeg)->pgnoLast))
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
                c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
                c2fb_temp_5 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, local2->pSeg)->pgnoFirst))
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
            Else
                local3 = local2->iTermLeafOffset
                ' C automatic storage declaration
                ' C automatic storage declaration
                local6 = CPtr(c2fb_Fts5StructureSegment Ptr, local2->pSeg)->iSegid
                Erase local7
                local7(0) = Cast(c2fb_c_int, &H00ULL)
                local7(1) = Cast(c2fb_c_int, &H00ULL)
                local7(2) = Cast(c2fb_c_int, &H00ULL)
                local7(3) = Cast(c2fb_c_int, &H00ULL)
                c2fb_temp_7 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local6)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local2->iTermLeafPgno)))))))
                local4 = c2fb_temp_7
                c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, local4)))
                local5 = c2fb_temp_8
                If local5 Then
                    If (-Cast(c2fb_c_int, ((local3 > local5->szLeaf)))) Then
                        fts5IndexCorruptRowid(arg0, local4)
                    Else
                        c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(local1)))
                        c2fb_temp_9 = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((CPtr(c2fb_Fts5Buffer Ptr, @(local1)))->n)) + Cast(c2fb_c_uint, (local5->nn)))) <= Cast(c2fb_c_uint, ((CPtr(c2fb_Fts5Buffer Ptr, @(local1)))->nSpace)))))), Cast(c2fb_c_int, &O0ULL), c2fb_external_sqlite3Fts5BufferSize((CPtr(c2fb_c_int Ptr, @(arg0->rc))), (CPtr(c2fb_Fts5Buffer Ptr, @(local1))), Cast(c2fb_c_int, ((local5->nn) + (CPtr(c2fb_Fts5Buffer Ptr, @(local1)))->n)))))
                        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1)), Cast(c2fb_size_t, (4ULL * SizeOf(UByte))), CPtr(Const UByte Ptr, CPtr(UByte Ptr, (@local7(0)))))
                        c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1)), Cast(c2fb_int64, local2->term.n))
                        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1)), local2->term.n, CPtr(Const UByte Ptr, local2->term.p))
                        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1)), Cast(c2fb_c_int, (local5->szLeaf - local3)), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local5->p[local3]))))
                        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                            fts5PutU16(CPtr(UByte Ptr, @(local1.p[Cast(c2fb_c_int, 2ULL)])), Cast(UShort, local1.n))
                        End If
                        c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1)), Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL)))
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2->iLeafPgno = local2->iTermLeafPgno)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2->iEndofDoclist < local5->szLeaf)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2->iPgidxOff <= local5->nn)))) <> 0))))) Then
                            local8 = Cast(c2fb_c_int, (local5->szLeaf - local2->iEndofDoclist))
                            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1)), Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, local1.n) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))) - Cast(c2fb_int64, local8))) - Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL)))))
                            c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local1)), Cast(c2fb_c_int, (local5->nn - local2->iPgidxOff)), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local5->p[local2->iPgidxOff]))))
                        End If
                        c2fb_temp_10 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, local2->pSeg)->pgnoFirst))
                        c2fb_temp_11 = Cast(c2fb_c_int, local2->iTermLeafPgno)
                        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
                        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                        fts5DataDelete(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local6)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_c_int, 1ULL))))))), local4)
                        fts5DataWrite(arg0, local4, CPtr(Const UByte Ptr, local1.p), local1.n)
                    End If
                    fts5DataRelease(local5)
                End If
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local1)))
End Sub
Private Sub fts5MergeChunkCallback CDecl Alias "fts5MergeChunkCallback" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4774
    Dim local0 As c2fb_Fts5SegWriter Ptr

    local0 = CPtr(c2fb_Fts5SegWriter Ptr, arg1)
    fts5WriteAppendPoslistData(arg0, local0, arg2, arg3)
End Sub
Private Sub fts5IndexMergeLevel CDecl Alias "fts5IndexMergeLevel" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4786
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim local1 As c2fb_Fts5StructureLevel Ptr
    Dim local2 As c2fb_Fts5StructureLevel Ptr
    Dim local3 As c2fb_Fts5Iter Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_Fts5SegWriter
    Dim local7 As c2fb_Fts5StructureSegment Ptr
    Dim local8 As c2fb_Fts5Buffer
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local13 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_10 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_11 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_12 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_u64 Ptr
    Dim c2fb_temp_23 As c2fb_uint64
    Dim c2fb_temp_24 As c2fb_u64 Ptr
    Dim c2fb_temp_25 As c2fb_uint64
    Dim c2fb_temp_26 As c2fb_c_int
    Dim local14 As c2fb_Fts5SegIter Ptr
    Dim local15 As c2fb_c_int
    Dim local16 As c2fb_c_int
    Dim local17 As Const UByte Ptr
    Dim c2fb_temp_27 As Const UByte Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim local18 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim local19 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_33 As c2fb_u64 Ptr
    Dim c2fb_temp_34 As c2fb_uint64
    Dim local20 As c2fb_c_int
    Dim c2fb_temp_35 As Any Ptr
    Dim c2fb_temp_36 As Long Ptr
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As Long Ptr
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As Long Ptr
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As Long Ptr
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As Long Ptr
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As Long Ptr
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int Ptr
    Dim c2fb_temp_49 As c2fb_c_int

    local0 = (*arg1)
#ifdef SQLITE_DEBUG
    If arg2 >= local0->nLevel Then _
        sqlite3DebugAssert(StrPtr(!"iLvl<pStruct->nLevel"))
    If arg2 < 0 Then sqlite3DebugAssert(StrPtr(!"iLvl>=0"))
#endif
    local1 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local0)))[arg2]))
#ifdef SQLITE_DEBUG
    If local1->nMerge > local1->nSeg Then _
        sqlite3DebugAssert(StrPtr(!"pLvl->nMerge<=pLvl->nSeg"))
#endif
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = IIf(arg3, (*arg3), Cast(c2fb_c_int, &O0ULL))
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local10 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail
    local11 = Cast(c2fb_c_int, &H0020ULL)
    local12 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local6))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegWriter))))
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local8))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
    If local1->nMerge Then
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5StructureLevel Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local0)))[Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))])))
        local2 = c2fb_temp_2
#ifdef SQLITE_DEBUG
        If local2->nSeg = 0 Then _
            sqlite3DebugAssert(StrPtr(!"pLvlOut->nSeg>0"))
#endif
        ' C unused-parameter annotation
        c2fb_temp_3 = Cast(c2fb_c_int, local1->nMerge)
        local5 = c2fb_temp_3
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local2->aSeg))[Cast(c2fb_c_int, (local2->nSeg - Cast(c2fb_c_int, 1ULL)))])))
        local7 = c2fb_temp_4
        fts5WriteInit(arg0, CPtr(c2fb_Fts5SegWriter Ptr, @(local6)), local7->iSegid)
        c2fb_temp_5 = CPtr(Long Ptr, @(local6.writer.pgno))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local7->pgnoLast + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(Long Ptr, @(local6.iBtPage))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    Else
        local13 = fts5AllocateSegid(arg0, local0)
        If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, (local0->nLevel - Cast(c2fb_c_int, 1ULL))))))) Then
            fts5StructureAddLevel(CPtr(c2fb_c_int Ptr, @(arg0->rc)), arg1)
            c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, (*arg1))
            local0 = c2fb_temp_9
        End If
        fts5StructureExtendLevel(CPtr(c2fb_c_int Ptr, @(arg0->rc)), local0, Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))
        If arg0->rc Then
            Return
        End If
        c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5StructureLevel Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local0)))[arg2])))
        local1 = c2fb_temp_10
        c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5StructureLevel Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local0)))[Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))])))
        local2 = c2fb_temp_11
        fts5WriteInit(arg0, CPtr(c2fb_Fts5SegWriter Ptr, @(local6)), local13)
        c2fb_temp_12 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local2->aSeg))[local2->nSeg])))
        local7 = c2fb_temp_12
        c2fb_temp_13 = CPtr(Long Ptr, @(local2->nSeg))
        c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
        (*c2fb_temp_13) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
        c2fb_temp_15 = CPtr(Long Ptr, @(local7->pgnoFirst))
        c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
        c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
        c2fb_temp_17 = CPtr(Long Ptr, @(local7->iSegid))
        c2fb_temp_18 = Cast(c2fb_c_int, local13)
        (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
        c2fb_temp_19 = CPtr(Long Ptr, @(local0->nSegment))
        c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
        (*c2fb_temp_19) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 + 1)))
        c2fb_temp_21 = Cast(c2fb_c_int, local1->nSeg)
        local5 = c2fb_temp_21
        If (-Cast(c2fb_c_int, ((local0->nOriginCntr > Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_22 = CPtr(c2fb_u64 Ptr, @(local7->iOrigin1))
            c2fb_temp_23 = Cast(c2fb_uint64, CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local1->aSeg))[Cast(c2fb_c_int, &O0ULL)].iOrigin1)
            (*c2fb_temp_22) = Cast(c2fb_u64, c2fb_temp_23)
            c2fb_temp_23 = Cast(c2fb_uint64, (*c2fb_temp_22))
            c2fb_temp_24 = CPtr(c2fb_u64 Ptr, @(local7->iOrigin2))
            c2fb_temp_25 = Cast(c2fb_uint64, CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local1->aSeg))[Cast(c2fb_c_int, (local1->nSeg - Cast(c2fb_c_int, 1ULL)))].iOrigin2)
            (*c2fb_temp_24) = Cast(c2fb_u64, c2fb_temp_25)
            c2fb_temp_25 = Cast(c2fb_uint64, (*c2fb_temp_24))
        End If
    End If
    c2fb_temp_26 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2->nSeg = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->nLevel = Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 2ULL))))))) <> 0)))))))
    local9 = c2fb_temp_26
    ' C unused-parameter annotation
    fts5MultiIterNew(arg0, local0, local11, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg2, local5, CPtr(c2fb_Fts5Iter Ptr Ptr, @(local3)))
    While (-Cast(c2fb_c_int, ((fts5MultiIterEof(arg0, local3) = Cast(c2fb_c_int, &O0ULL)))))
        local14 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local3)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, local3->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_27 = CPtr(Const UByte Ptr, fts5MultiIterTerm(local3, CPtr(c2fb_c_int Ptr, @(local16))))
        local17 = c2fb_temp_27
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local16 <> local8.n)))) <> 0) OrElse ((IIf((-Cast(c2fb_c_int, (((local16) <= Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, &O0ULL), c2fb_crt_memcmp(CPtr(Const Any Ptr, (local17)), CPtr(Const Any Ptr, (local8.p)), (local16)))) <> 0))))) Then
            If (-Cast(c2fb_c_int, (((arg3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6.nLeafWritten > local4)))) <> 0))))) Then
                Goto c2fb_flow_0
            End If
            c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local8)), local16, local17)
            c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local12 = c2fb_temp_28
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local14->nPos = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((local9 <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local14->bDel) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
            Goto c2fb_flow_1
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            fts5WriteAppendTerm(arg0, CPtr(c2fb_Fts5SegWriter Ptr, @(local6)), local16, local17)
            c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local12 = c2fb_temp_29
        End If
        fts5WriteAppendRowid(arg0, CPtr(c2fb_Fts5SegWriter Ptr, @(local6)), fts5MultiIterRowid(local3))
        If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, 1ULL))))) Then
            If local14->bDel Then
                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local6.writer.buf)), Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))
                If (-Cast(c2fb_c_int, ((local14->nPos > Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local6.writer.buf)), Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))
                End If
            End If
        Else
            c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local14->nPos * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, local14->bDel))))
            local15 = c2fb_temp_30
            c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local6.writer.buf)), Cast(c2fb_int64, local15))
            fts5ChunkIterate(arg0, local14, CPtr(Any Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local6))), ProcPtr(fts5MergeChunkCallback))
        End If
    c2fb_flow_1:
        fts5MultiIterNext(arg0, local3, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    Wend
    c2fb_flow_0:
    fts5WriteFinish(arg0, CPtr(c2fb_Fts5SegWriter Ptr, @(local6)), CPtr(c2fb_c_int Ptr, @(local7->pgnoLast)))
#ifdef SQLITE_DEBUG
    If local3 = 0 AndAlso arg0->rc = SQLITE_OK Then _
        sqlite3DebugAssert(StrPtr(!"pIter!=0 || p->rc!=SQLITE_OK"))
#endif
    ' C unused-parameter annotation
    If fts5MultiIterEof(arg0, local3) Then
#ifdef SQLITE_DEBUG
        If local7->nEntry <> 0 Then _
            sqlite3DebugAssert(StrPtr(!"pSeg->nEntry==0"))
#endif
        ' C automatic storage declaration
        ' C unused-parameter annotation
        c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local18 = c2fb_temp_31
        While (-Cast(c2fb_c_int, ((local18 < local5))))
            local19 = CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local1->aSeg))[local18]))
            c2fb_temp_33 = CPtr(c2fb_u64 Ptr, @(local7->nEntry))
            c2fb_temp_34 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (*c2fb_temp_33)) + (Cast(c2fb_uint64, (local19->nEntry - local19->nEntryTombstone))))))
            (*c2fb_temp_33) = Cast(c2fb_u64, c2fb_temp_34)
            c2fb_temp_34 = Cast(c2fb_uint64, (*c2fb_temp_33))
            fts5DataRemoveSegment(arg0, local19)
        c2fb_flow_3:
            c2fb_temp_32 = local18
            local18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_32 + 1)))
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local1->nSeg <> local5)))) Then
            local20 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, (local1->nSeg - local5)))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureSegment)))))
            c2fb_temp_35 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local1->aSeg)), CPtr(Const Any Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local1->aSeg))[local5]))), local20))
        End If
        c2fb_temp_36 = CPtr(Long Ptr, @(local0->nSegment))
        c2fb_temp_37 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_36)) - local5)))
        (*c2fb_temp_36) = Cast(Long, c2fb_temp_37)
        c2fb_temp_37 = Cast(c2fb_c_int, (*c2fb_temp_36))
        c2fb_temp_38 = CPtr(Long Ptr, @(local1->nSeg))
        c2fb_temp_39 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_38)) - local5)))
        (*c2fb_temp_38) = Cast(Long, c2fb_temp_39)
        c2fb_temp_39 = Cast(c2fb_c_int, (*c2fb_temp_38))
        c2fb_temp_40 = CPtr(Long Ptr, @(local1->nMerge))
        c2fb_temp_41 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_40) = Cast(Long, c2fb_temp_41)
        c2fb_temp_41 = Cast(c2fb_c_int, (*c2fb_temp_40))
        If (-Cast(c2fb_c_int, ((local7->pgnoLast = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_42 = CPtr(Long Ptr, @(local2->nSeg))
            c2fb_temp_43 = Cast(c2fb_c_int, (*c2fb_temp_42))
            (*c2fb_temp_42) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_43 - 1)))
            c2fb_temp_44 = CPtr(Long Ptr, @(local0->nSegment))
            c2fb_temp_45 = Cast(c2fb_c_int, (*c2fb_temp_44))
            (*c2fb_temp_44) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_45 - 1)))
        End If
    Else
#ifdef SQLITE_DEBUG
        If local7->pgnoLast <= 0 Then _
            sqlite3DebugAssert(StrPtr(!"pSeg->pgnoLast>0"))
#endif
        ' C unused-parameter annotation
        fts5TrimSegments(arg0, local3)
        c2fb_temp_46 = CPtr(Long Ptr, @(local1->nMerge))
        c2fb_temp_47 = Cast(c2fb_c_int, local5)
        (*c2fb_temp_46) = Cast(Long, c2fb_temp_47)
        c2fb_temp_47 = Cast(c2fb_c_int, (*c2fb_temp_46))
    End If
    fts5MultiIterFree(local3)
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local8)))
    If arg3 Then
        c2fb_temp_48 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_49 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_48) - local6.nLeafWritten)))
        (*c2fb_temp_48) = c2fb_temp_49
    End If
End Sub
Private Function fts5IndexFindDeleteMerge CDecl Alias "fts5IndexFindDeleteMerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4948
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As c2fb_Fts5StructureLevel Ptr
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_int64
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local1 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    If (-Cast(c2fb_c_int, (((local0->bContentlessDelete <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->nDeleteMerge > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        ' C automatic storage declaration
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local2 < arg1->nLevel))))
            local4 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg1)))[local2]))
            local5 = Cast(c2fb_c_int, &O0ULL)
            local6 = Cast(c2fb_c_int, &O0ULL)
            ' C automatic storage declaration
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local7 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((local7 < local4->nSeg))))
                c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, local5) + CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local4->aSeg))[local7].nEntry)))
                local5 = c2fb_temp_4
                c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, local6) + CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local4->aSeg))[local7].nEntryTombstone)))
                local6 = c2fb_temp_5
            c2fb_flow_3:
                c2fb_temp_3 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            Wend
            c2fb_flow_2:
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local5 > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                local8 = Cast(c2fb_int64, ((Cast(c2fb_int64, (local6 * Cast(c2fb_int64, Cast(c2fb_c_int, 100ULL))))) \ local5))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 >= local0->nDeleteMerge)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 > local3)))) <> 0))))) Then
                    c2fb_temp_6 = Cast(c2fb_c_int, local2)
                    local1 = c2fb_temp_6
                    c2fb_temp_7 = Cast(c2fb_c_int, local8)
                    local3 = c2fb_temp_7
                End If
            End If
            If local4->nMerge Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
    End If
    Return local1
End Function
Private Function fts5IndexMerge CDecl Alias "fts5IndexMerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 4987
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Structure Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local6 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_Fts5Structure Ptr Ptr
    Dim c2fb_temp_10 As c2fb_Fts5Structure Ptr

    local0 = arg2
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = (*arg1)
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C automatic storage declaration
        local4 = Cast(c2fb_c_int, &O0ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        ' C unused-parameter annotation
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local3 < local2->nLevel))))
            local6 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local2)))[local3]))
            If local6->nMerge Then
                If (-Cast(c2fb_c_int, ((local6->nMerge > local5)))) Then
                    c2fb_temp_2 = Cast(c2fb_c_int, local3)
                    local4 = c2fb_temp_2
                    c2fb_temp_3 = Cast(c2fb_c_int, arg3)
                    local5 = c2fb_temp_3
                End If
                Goto c2fb_flow_2
            End If
            If (-Cast(c2fb_c_int, ((local6->nSeg > local5)))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, local6->nSeg)
                local5 = c2fb_temp_4
                c2fb_temp_5 = Cast(c2fb_c_int, local3)
                local4 = c2fb_temp_5
            End If
        c2fb_flow_3:
            c2fb_temp_1 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local5 < arg3)))) Then
            c2fb_temp_6 = Cast(c2fb_c_int, fts5IndexFindDeleteMerge(arg0, local2))
            local4 = c2fb_temp_6
        End If
        If (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local1 = c2fb_temp_7
        fts5IndexMergeLevel(arg0, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local2)), local4, CPtr(c2fb_c_int Ptr, @(local0)))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local2)))[local4].nMerge = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            fts5StructurePromote(arg0, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL))), local2)
        End If
        If (-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, 1ULL))))) Then
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
            arg3 = c2fb_temp_8
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_9 = CPtr(c2fb_Fts5Structure Ptr Ptr, @((*arg1)))
    c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local2)
    (*c2fb_temp_9) = c2fb_temp_10
    Return local1
End Function
Private Sub fts5IndexAutomerge CDecl Alias "fts5IndexAutomerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5043
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim local1 As c2fb_uint64
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_uint64
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_u64 Ptr
    Dim c2fb_temp_3 As c2fb_uint64
    Dim c2fb_temp_4 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nAutomerge > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((*arg1)) <> Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        local0 = (*arg1)
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_uint64, local0->nWriteCounter)
        local1 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_uint64, ((Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, arg2)))) \ Cast(c2fb_uint64, arg0->nWorkUnit)))) - (Cast(c2fb_uint64, (local1 \ Cast(c2fb_uint64, arg0->nWorkUnit)))))))))
        local2 = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_u64 Ptr, @(local0->nWriteCounter))
        c2fb_temp_3 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (*c2fb_temp_2)) + Cast(c2fb_uint64, arg2))))
        (*c2fb_temp_2) = Cast(c2fb_u64, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_uint64, (*c2fb_temp_2))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0->nWorkUnit * local2)) * local0->nLevel)))))
        local3 = c2fb_temp_4
        fts5IndexMerge(arg0, arg1, local3, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nAutomerge)
    End If
End Sub
Private Sub fts5IndexCrisismerge CDecl Alias "fts5IndexCrisismerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5064
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Structure Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_Fts5Structure Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Structure Ptr

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCrisisMerge
    local1 = (*arg1)
    If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->nLevel > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        local2 = Cast(c2fb_c_int, &O0ULL)
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local1)))[local2].nSeg >= local0)))) <> 0)))))
            fts5IndexMergeLevel(arg0, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local1)), local2, Cast(c2fb_c_int, &O0ULL))
            ' C unused-parameter annotation
            fts5StructurePromote(arg0, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))), local1)
            c2fb_temp_0 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_1 = CPtr(c2fb_Fts5Structure Ptr Ptr, @((*arg1)))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1)
        (*c2fb_temp_1) = c2fb_temp_2
    End If
End Sub
Private Function fts5IndexReturn CDecl Alias "fts5IndexReturn" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5082
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = arg0->rc
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    Return local0
End Function
Sub sqlite3Fts5IndexCloseReader CDecl Alias "sqlite3Fts5IndexCloseReader" (ByVal arg0 As c2fb_Fts5Index Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5091
    fts5IndexCloseReader(arg0)
    fts5IndexReturn(arg0)
End Sub
Private Function fts5PoslistPrefix CDecl Alias "fts5PoslistPrefix" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5107
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint32(arg0, CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local1))))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 < arg1)))) Then
        While Cast(c2fb_c_int, 1ULL)
            local2 = c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local1)))))
            If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local0 + local2))) > arg1)))) Then
                Goto c2fb_flow_0
            End If
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + local2)))
            local0 = c2fb_temp_1
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
    Return local0
End Function
Private Sub fts5SecureDeleteIdxEntry CDecl Alias "fts5SecureDeleteIdxEntry" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5132
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg2 <> Cast(c2fb_c_int, 1ULL))))) Then
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleteFromIdx) = Cast(c2fb_c_int, &O0ULL))))) Then
            fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg0->pDeleteFromIdx)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"DELETE FROM '%q'.'%q_idx' WHERE (segid, (pgno/2)) = (?1, ?2)"), CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->zDb, CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->zName)))
        End If
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            sqlite3_bind_int(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleteFromIdx)), Cast(c2fb_c_int, 1ULL), arg1)
            sqlite3_bind_int(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleteFromIdx)), Cast(c2fb_c_int, 2ULL), arg2)
            sqlite3_step(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleteFromIdx)))
            c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_reset(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleteFromIdx))))
            (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
            c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        End If
    End If
End Sub
Private Sub fts5SecureDeleteOverflow CDecl Alias "fts5SecureDeleteOverflow" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5164
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim local5 As UByte Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local6(0 To 3) As UByte
    Dim c2fb_temp_9 As c2fb_Fts5Data Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As UByte Ptr
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim local13 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Any Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Any Ptr
    Dim c2fb_temp_18 As Any Ptr
    Dim c2fb_temp_19 As c2fb_c_int

    local0 = ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, 1ULL))))))
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, arg2)
    local1 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 <= arg1->pgnoLast)))) <> 0)))))
        local3 = (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local1))))))
        local4 = Cast(c2fb_c_int, &O0ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, local3)))
        local2 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_5 = local2->p
        local5 = c2fb_temp_5
        c2fb_temp_6 = Cast(c2fb_c_int, fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, &O0ULL)])))))
        local4 = c2fb_temp_6
        If (-Cast(c2fb_c_int, ((local4 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_7) = c2fb_temp_8
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2->szLeaf < local2->nn)))) <> 0))))) Then
            c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local5[local2->szLeaf]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local4)))))
        End If
        If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
            Erase local6
            local6(0) = Cast(c2fb_c_int, &H00ULL)
            local6(1) = Cast(c2fb_c_int, &H00ULL)
            local6(2) = Cast(c2fb_c_int, &H00ULL)
            local6(3) = Cast(c2fb_c_int, &H04ULL)
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                fts5DataWrite(arg0, local3, CPtr(Const UByte Ptr, CPtr(UByte Ptr, (@local6(0)))), Cast(c2fb_size_t, (4ULL * SizeOf(UByte))))
            End If
            fts5DataRelease(local2)
            c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local2 = c2fb_temp_9
        Else
            If local0 Then
                Goto c2fb_flow_0
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 >= local2->szLeaf)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2->nn < local2->szLeaf)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                    fts5IndexCorruptRowid(arg0, local3)
                    Goto c2fb_flow_0
                Else
                    local7 = Cast(c2fb_c_int, (local4 - Cast(c2fb_c_int, 4ULL)))
                    ' C automatic storage declaration
                    local9 = Cast(c2fb_c_int, &O0ULL)
                    local10 = Cast(c2fb_c_int, &O0ULL)
                    If (-Cast(c2fb_c_int, ((local2->nn > local2->szLeaf)))) Then
                        local11 = Cast(c2fb_c_int, &O0ULL)
                        local12 = local2->szLeaf
                        local13 = Cast(c2fb_c_int, &O0ULL)
                        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local12 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local5[local12]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local11))))))))
                        local12 = c2fb_temp_10
                        If (-Cast(c2fb_c_int, ((local11 < local4)))) Then
                            fts5IndexCorruptRowid(arg0, local3)
                            Goto c2fb_flow_0
                        End If
                        c2fb_temp_11 = CPtr(UByte Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local2->nn - local2->szLeaf))) + Cast(c2fb_c_int, 2ULL))))))
                        local10 = c2fb_temp_11
                        If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) Then
                            Goto c2fb_flow_0
                        End If
                        c2fb_temp_12 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5PutVarint(local10, Cast(c2fb_c_int, (local11 - local7))))
                        local13 = c2fb_temp_12
                        If (-Cast(c2fb_c_int, ((local12 < local2->nn)))) Then
                            c2fb_temp_13 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local10[local13]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local5[local12]))), Cast(c2fb_c_int, (local2->nn - local12))))
                            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local13 + (Cast(c2fb_c_int, (local2->nn - local12))))))
                            local13 = c2fb_temp_14
                        End If
                        c2fb_temp_15 = Cast(c2fb_c_int, local13)
                        local9 = c2fb_temp_15
                    End If
                    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2->szLeaf - local7)))
                    local8 = c2fb_temp_16
                    c2fb_temp_17 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, 4ULL)]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, (Cast(c2fb_c_int, 4ULL) + local7))]))), Cast(c2fb_c_int, (local8 - Cast(c2fb_c_int, 4ULL)))))
                    fts5PutU16(CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, 2ULL)])), local8)
                    If fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, &O0ULL)])))) Then
                        fts5PutU16(CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, &O0ULL)])), Cast(c2fb_c_int, 4ULL))
                    End If
                    If (-Cast(c2fb_c_int, ((local9 > Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_18 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local5[local8]))), CPtr(Const Any Ptr, local10), local9))
                        c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local8 + local9)))
                        local8 = c2fb_temp_19
                    End If
                    sqlite3_free(CPtr(Any Ptr, local10))
                    ' C unused-parameter annotation
                    fts5DataWrite(arg0, local3, CPtr(Const UByte Ptr, local5), local8)
                    Goto c2fb_flow_0
                End If
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_3 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    fts5DataRelease(local2)
End Sub
Private Sub fts5DoSecureDelete CDecl Alias "fts5DoSecureDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5262
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As UByte Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_uint64
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As UByte Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim local13 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local16 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim local17 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim local18 As c2fb_c_uint
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As UByte Ptr
    Dim c2fb_temp_27 As UByte
    Dim local19 As c2fb_uint64
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim local20 As c2fb_c_int
    Dim local21 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim local22 As c2fb_c_uint
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim local23 As c2fb_uint64
    Dim local24 As c2fb_uint64
    Dim local25 As c2fb_uint64
    Dim local26 As c2fb_uint64
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_uint64
    Dim c2fb_temp_42 As c2fb_uint64
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As Any Ptr
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As Any Ptr
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_c_int
    Dim local27 As c2fb_c_int
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As c2fb_c_int
    Dim local28 As c2fb_Fts5Data Ptr
    Dim local29 As c2fb_c_int
    Dim local30 As c2fb_int64
    Dim local31 As c2fb_Fts5Data Ptr
    Dim local32 As UByte Ptr
    Dim local33 As c2fb_c_int
    Dim local34 As c2fb_c_int
    Dim local35 As c2fb_int64
    Dim local36 As c2fb_c_uint
    Dim local37 As c2fb_c_int
    Dim c2fb_temp_52 As c2fb_int64
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As c2fb_c_int
    Dim c2fb_temp_55 As Any Ptr
    Dim local38 As c2fb_c_int
    Dim local39 As c2fb_c_int
    Dim local40 As c2fb_c_int
    Dim local41 As c2fb_c_int
    Dim local42 As c2fb_int64
    Dim c2fb_temp_56 As Any Ptr
    Dim c2fb_temp_57 As c2fb_c_int
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As c2fb_c_int
    Dim local43 As c2fb_c_uint
    Dim c2fb_temp_60 As c2fb_c_int
    Dim c2fb_temp_61 As c2fb_int64
    Dim local44 As c2fb_c_int
    Dim c2fb_temp_62 As c2fb_c_int
    Dim c2fb_temp_63 As c2fb_c_int

    local0 = ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, 1ULL))))))
    local1 = CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg)->iSegid
    local2 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->p
    local3 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->nn
    local4 = CPtr(c2fb_Fts5Data Ptr, arg1->pLeaf)->szLeaf
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    local8 = Cast(c2fb_c_int, &O0ULL)
    local9 = Cast(c2fb_c_int, &O0ULL)
    local10 = Cast(c2fb_c_int, &O0ULL)
    local11 = Cast(c2fb_c_int, &O0ULL)
    local12 = Cast(c2fb_c_int, &O0ULL)
    local13 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 - local4)))
    local8 = c2fb_temp_0
    c2fb_temp_1 = CPtr(UByte Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), Cast(c2fb_int64, ((Cast(c2fb_int64, local8)) + Cast(c2fb_int64, Cast(c2fb_c_int, 16ULL)))))))
    local9 = c2fb_temp_1
    If arg0->rc Then
        Return
    End If
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local9), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local2[local4]))), local8))
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg1->iLeafPgno = arg1->iTermLeafPgno)))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, arg1->iTermLeafOffset)
        local12 = c2fb_temp_3
    Else
        c2fb_temp_4 = Cast(c2fb_c_int, fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)])))))
        local12 = c2fb_temp_4
    End If
    If (-Cast(c2fb_c_int, ((local12 > local3)))) Then
        fts5IndexCorruptIdx(arg0)
        sqlite3_free(CPtr(Any Ptr, local9))
        Return
    End If
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local12 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local12]))), CPtr(c2fb_uint64 Ptr, @(local5)))))))
    local14 = c2fb_temp_5
    ' C unused-parameter annotation
    If local0 Then
        While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local14) < arg1->iLeafOffset))))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2[local14]) = Cast(c2fb_c_int, &H00ULL))))) Then
                c2fb_temp_6 = local14
                local14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
            End If
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2[local14]) = Cast(c2fb_c_int, &H00ULL))))) Then
                c2fb_temp_7 = local14
                local14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            End If
            c2fb_temp_8 = Cast(c2fb_c_int, local14)
            local12 = c2fb_temp_8
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local12 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local12]))), CPtr(c2fb_uint64 Ptr, @(local5)))))))
            local14 = c2fb_temp_9
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_10 = Cast(c2fb_c_int, local14)
        local6 = c2fb_temp_10
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 < arg1->iEndofDoclist)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2[local6]) = Cast(c2fb_c_int, &H00ULL))))) <> 0))))) Then
            c2fb_temp_11 = local6
            local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 < arg1->iEndofDoclist)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2[local6]) = Cast(c2fb_c_int, &H00ULL))))) <> 0))))) Then
            c2fb_temp_12 = local6
            local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
        End If
    Else
        local15 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local14]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local15))))))))
        local14 = c2fb_temp_13
        While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local14) < arg1->iLeafOffset))))
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 + (Cast(c2fb_c_int, (local15 \ Cast(c2fb_c_int, 2ULL)))))))
            local12 = c2fb_temp_14
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local12 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local12]))), CPtr(c2fb_uint64 Ptr, @(local5)))))))
            local14 = c2fb_temp_15
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local14]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local15))))))))
            local14 = c2fb_temp_16
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        ' C unused-parameter annotation
        c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 + arg1->nPos)))
        local6 = c2fb_temp_17
    End If
    c2fb_temp_18 = Cast(c2fb_c_int, local12)
    local7 = c2fb_temp_18
    If (-Cast(c2fb_c_int, ((local6 >= local4)))) Then
        local16 = Cast(c2fb_c_int, (arg1->iLeafPgno + Cast(c2fb_c_int, 1ULL)))
        fts5SecureDeleteOverflow(arg0, CPtr(c2fb_Fts5StructureSegment Ptr, arg1->pSeg), local16, CPtr(c2fb_c_int Ptr, @(local10)))
        c2fb_temp_19 = Cast(c2fb_c_int, local4)
        local6 = c2fb_temp_19
    End If
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->bDel) = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((local6 <> local4)))) Then
            local17 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local11 = c2fb_temp_20
            While (-Cast(c2fb_c_int, ((local11 < local8))))
                local18 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local11 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local9[local11]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local18))))))))
                local11 = c2fb_temp_21
                c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local17) + local18)))
                local17 = c2fb_temp_22
                If (-Cast(c2fb_c_int, ((local17 = local6)))) Then
                    c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local10 = c2fb_temp_23
                End If
            c2fb_flow_5:
            Wend
            c2fb_flow_4:
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)]))))) = local12)))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((local10 <> 0) OrElse ((-Cast(c2fb_c_int, ((local6 = local4)))) <> 0)))))) <> 0))))) Then
            fts5PutU16(CPtr(UByte Ptr, @(local2[Cast(c2fb_c_int, &O0ULL)])), Cast(c2fb_c_int, &O0ULL))
        End If
    End If
    If arg1->bDel Then
        c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local7 + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2[local7])), local5))))
        local7 = c2fb_temp_24
        c2fb_temp_25 = local7
        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_25 + 1)))
        c2fb_temp_26 = CPtr(UByte Ptr, @(local2[c2fb_temp_25]))
        c2fb_temp_27 = Cast(UByte, Cast(c2fb_c_int, &H01ULL))
        (*c2fb_temp_26) = c2fb_temp_27
    Else
        If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local6 <> local4)))) Then
                local19 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local6]))), CPtr(c2fb_uint64 Ptr, @(local19)))))))
                local6 = c2fb_temp_28
                c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local7 + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2[local7])), Cast(c2fb_uint64, (local5 + local19))))))
                local7 = c2fb_temp_29
            End If
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->iLeafPgno = arg1->iTermLeafPgno)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local12 = arg1->iTermLeafOffset)))) <> 0))))) Then
                local20 = Cast(c2fb_c_int, &O0ULL)
                local21 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local11 = c2fb_temp_30
                While (-Cast(c2fb_c_int, ((local11 < local8))))
                    local22 = Cast(c2fb_c_int, &O0ULL)
                    c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local11 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local9[local11]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local22))))))))
                    local11 = c2fb_temp_32
                    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local21) + local22))) > Cast(c2fb_c_uint, local12))))) Then
                        Goto c2fb_flow_6
                    End If
                    c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local21) + local22)))
                    local21 = c2fb_temp_33
                c2fb_flow_7:
                    c2fb_temp_31 = local20
                    local20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_31 + 1)))
                Wend
                c2fb_flow_6:
                ' C unused-parameter annotation
                c2fb_temp_34 = Cast(c2fb_c_int, local21)
                local7 = c2fb_temp_34
                c2fb_temp_35 = Cast(c2fb_c_int, c2fb_temp_34)
                local13 = c2fb_temp_35
                If (-Cast(c2fb_c_int, ((local6 <> local4)))) Then
                    local23 = Cast(c2fb_c_int, &O0ULL)
                    local24 = Cast(c2fb_c_int, &O0ULL)
                    local25 = Cast(c2fb_c_int, &O0ULL)
                    local26 = Cast(c2fb_c_int, &O0ULL)
                    c2fb_temp_36 = Cast(c2fb_c_int, local6)
                    local13 = c2fb_temp_36
                    c2fb_temp_37 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local6]))), CPtr(c2fb_uint64 Ptr, @(local25)))))))
                    local6 = c2fb_temp_37
                    c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local6]))), CPtr(c2fb_uint64 Ptr, @(local26)))))))
                    local6 = c2fb_temp_38
                    If (-Cast(c2fb_c_int, ((local20 <> Cast(c2fb_c_int, 1ULL))))) Then
                        c2fb_temp_39 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local21 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local21]))), CPtr(c2fb_uint64 Ptr, @(local23)))))))
                        local21 = c2fb_temp_39
                    End If
                    c2fb_temp_40 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local21 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local2[local21]))), CPtr(c2fb_uint64 Ptr, @(local24)))))))
                    local21 = c2fb_temp_40
                    c2fb_temp_41 = Cast(c2fb_uint64, (IIf(((-Cast(c2fb_c_int, (((local23) < (local25)))))), (local23), (local25))))
                    local23 = c2fb_temp_41
                    c2fb_temp_42 = Cast(c2fb_uint64, Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local25 + local26))) - local23)))
                    local24 = c2fb_temp_42
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((Cast(c2fb_uint64, (Cast(c2fb_uint64, local21) + local24))) > Cast(c2fb_uint64, local4))))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_uint64, (Cast(c2fb_uint64, local6) + local26))) > Cast(c2fb_uint64, local4))))) <> 0))))) Then
                        fts5IndexCorruptIdx(arg0)
                    Else
                        If (-Cast(c2fb_c_int, ((local20 <> Cast(c2fb_c_int, 1ULL))))) Then
                            c2fb_temp_43 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local7 + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2[local7])), local23))))
                            local7 = c2fb_temp_43
                        End If
                        c2fb_temp_44 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local7 + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2[local7])), local24))))
                        local7 = c2fb_temp_44
                        If (-Cast(c2fb_c_int, ((local25 > Cast(c2fb_uint64, arg1->term.n))))) Then
                            fts5IndexCorruptIdx(arg0)
                        Else
                            If (-Cast(c2fb_c_int, ((local25 > local23)))) Then
                                c2fb_temp_45 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local2[local7]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(arg1->term.p[local23]))), Cast(c2fb_uint64, (local25 - local23))))
                                c2fb_temp_46 = Cast(c2fb_c_int, Cast(c2fb_uint64, (Cast(c2fb_uint64, local7) + (Cast(c2fb_uint64, (local25 - local23))))))
                                local7 = c2fb_temp_46
                            End If
                        End If
                        c2fb_temp_47 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(UByte Ptr, @(local2[local7]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local2[local6]))), local26))
                        c2fb_temp_48 = Cast(c2fb_c_int, Cast(c2fb_uint64, (Cast(c2fb_uint64, local7) + local26)))
                        local7 = c2fb_temp_48
                        c2fb_temp_49 = Cast(c2fb_c_int, Cast(c2fb_uint64, (Cast(c2fb_uint64, local6) + local26)))
                        local6 = c2fb_temp_49
                    End If
                End If
            Else
                If (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, 4ULL))))) Then
                    ' C automatic storage declaration
                    ' C unused-parameter annotation
                    c2fb_temp_50 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg1->iLeafPgno - Cast(c2fb_c_int, 1ULL))))
                    local27 = c2fb_temp_50
                    While (-Cast(c2fb_c_int, ((local27 > arg1->iTermLeafPgno))))
                        local28 = CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local1)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local27))))))))
                        local29 = ((-Cast(c2fb_c_int, (((local28 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local28->nn = Cast(c2fb_c_int, 4ULL))))) <> 0))))))
                        fts5DataRelease(local28)
                        If (-Cast(c2fb_c_int, ((local29 = Cast(c2fb_c_int, &O0ULL))))) Then
                            Goto c2fb_flow_8
                        End If
                    c2fb_flow_9:
                        c2fb_temp_51 = local27
                        local27 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_51 - 1)))
                    Wend
                    c2fb_flow_8:
                    If (-Cast(c2fb_c_int, ((local27 = arg1->iTermLeafPgno)))) Then
                        local30 = (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local1)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (arg1->iTermLeafPgno))))))
                        local31 = CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, local30))
                        If (-Cast(c2fb_c_int, (((local31 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local31->szLeaf = arg1->iTermLeafOffset)))) <> 0))))) Then
                            local32 = CPtr(UByte Ptr, @(local31->p[local31->szLeaf]))
                            local33 = Cast(c2fb_c_int, (local31->nn - local31->szLeaf))
                            local34 = Cast(c2fb_c_int, &O0ULL)
                            local35 = Cast(c2fb_c_int, &O0ULL)
                            While Cast(c2fb_c_int, 1ULL)
                                local36 = Cast(c2fb_c_int, &O0ULL)
                                local37 = c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local32[local34]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local36)))))
                                c2fb_temp_52 = Cast(c2fb_int64, Cast(c2fb_int64, (local35 + Cast(c2fb_int64, local36))))
                                local35 = c2fb_temp_52
                                If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local34 + local37))) >= local33)))) Then
                                    Goto c2fb_flow_10
                                End If
                                c2fb_temp_53 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local34 + local37)))
                                local34 = c2fb_temp_53
                            c2fb_flow_11:
                            Wend
                            c2fb_flow_10:
                            c2fb_temp_54 = Cast(c2fb_c_int, local34)
                            local33 = c2fb_temp_54
                            If (-Cast(c2fb_c_int, ((local35 > Cast(c2fb_int64, local31->szLeaf))))) Then
                                fts5IndexCorruptIdx(arg0)
                            Else
                                c2fb_temp_55 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(UByte Ptr, @(local31->p[local35]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local31->p[local31->szLeaf]))), local33))
                                fts5PutU16(CPtr(UByte Ptr, @(local31->p[Cast(c2fb_c_int, 2ULL)])), local35)
                                fts5DataWrite(arg0, local30, CPtr(Const UByte Ptr, local31->p), Cast(c2fb_int64, (local35 + Cast(c2fb_int64, local33))))
                                If (-Cast(c2fb_c_int, ((local33 = Cast(c2fb_c_int, &O0ULL))))) Then
                                    fts5SecureDeleteIdxEntry(arg0, local1, arg1->iTermLeafPgno)
                                End If
                            End If
                        End If
                        fts5DataRelease(local31)
                    End If
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local38 = Cast(c2fb_c_int, (local3 - local6))
        local39 = Cast(c2fb_c_int, (local6 - local7))
        local40 = Cast(c2fb_c_int, &O0ULL)
        local41 = Cast(c2fb_c_int, &O0ULL)
        local42 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local38 > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_56 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(UByte Ptr, @(local2[local7]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local2[local6]))), local38))
        End If
        c2fb_temp_57 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 - local39)))
        local4 = c2fb_temp_57
        c2fb_temp_58 = Cast(c2fb_c_int, local4)
        local40 = c2fb_temp_58
        fts5PutU16(CPtr(UByte Ptr, @(local2[Cast(c2fb_c_int, 2ULL)])), local4)
        c2fb_temp_59 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local11 = c2fb_temp_59
        While (-Cast(c2fb_c_int, ((local11 < local8))))
            local43 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_60 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local11 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local9[local11]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local43))))))))
            local11 = c2fb_temp_60
            c2fb_temp_61 = Cast(c2fb_int64, Cast(c2fb_int64, (local42 + Cast(c2fb_int64, local43))))
            local42 = c2fb_temp_61
            If (-Cast(c2fb_c_int, ((local42 > Cast(c2fb_int64, local3))))) Then
                fts5IndexCorruptIdx(arg0)
                Goto c2fb_flow_12
            End If
            If (-Cast(c2fb_c_int, ((local42 <> Cast(c2fb_int64, local13))))) Then
                local44 = (Cast(c2fb_int64, (local42 - Cast(c2fb_int64, (IIf((-Cast(c2fb_c_int, ((local42 > Cast(c2fb_int64, local7))))), local39, Cast(c2fb_c_int, &O0ULL)))))))
                c2fb_temp_62 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local40 + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local2[local40])), Cast(c2fb_c_int, (local44 - local41))))))
                local40 = c2fb_temp_62
                c2fb_temp_63 = Cast(c2fb_c_int, local44)
                local41 = c2fb_temp_63
            End If
        c2fb_flow_13:
        Wend
        c2fb_flow_12:
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 = local40)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->iLeafPgno <> Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
            fts5SecureDeleteIdxEntry(arg0, local1, arg1->iLeafPgno)
        End If
        ' C unused-parameter annotation
        fts5DataWrite(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local1)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (arg1->iLeafPgno)))))), CPtr(Const UByte Ptr, local2), local40)
    End If
    sqlite3_free(CPtr(Any Ptr, local9))
End Sub
Private Function fts5FlushSecureDelete CDecl Alias "fts5FlushSecureDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5571
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Iter Ptr
    Dim local2 As c2fb_Fts5Config Ptr
    Dim local3 As c2fb_sqlite3_stmt Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_Fts5SegIter Ptr

    local0 = Cast(c2fb_c_int, &H0040ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->iVersion <> Cast(c2fb_c_int, 5ULL))))) Then
        local2 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
        local3 = Cast(c2fb_c_int, &O0ULL)
        fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local3)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"REPLACE INTO %Q.'%q_config' VALUES ('version', %d)"), local2->zDb, local2->zName, Cast(c2fb_c_int, 5ULL))))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            sqlite3_step(CPtr(Any Ptr, local3))
            c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_finalize(CPtr(Any Ptr, local3)))
            local4 = c2fb_temp_0
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_2 = Cast(c2fb_c_int, local4)
                (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
                c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
            End If
            c2fb_temp_3 = CPtr(Long Ptr, @(local2->iCookie))
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
            c2fb_temp_5 = CPtr(Long Ptr, @(local2->iVersion))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 5ULL))
            (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        End If
    End If
    fts5MultiIterNew(arg0, arg1, local0, Cast(c2fb_c_int, &O0ULL), CPtr(Const UByte Ptr, arg2), arg3, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_Fts5Iter Ptr Ptr, @(local1)))
    If (-Cast(c2fb_c_int, ((fts5MultiIterEof(arg0, local1) = Cast(c2fb_c_int, &O0ULL))))) Then
        local5 = fts5MultiIterRowid(local1)
        If (-Cast(c2fb_c_int, ((local5 < arg4)))) Then
            fts5MultiIterNextFrom(arg0, local1, arg4)
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((fts5MultiIterEof(arg0, local1) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg4 = fts5MultiIterRowid(local1))))) <> 0))))) Then
            local6 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local1)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, local1->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
            fts5DoSecureDelete(arg0, local6)
        End If
    End If
    fts5MultiIterFree(local1)
    Return arg0->rc
End Function
Private Sub fts5FlushOneHash CDecl Alias "fts5FlushOneHash" (ByVal arg0 As c2fb_Fts5Index Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5627
    Dim local0 As c2fb_Fts5Hash Ptr
    Dim local1 As c2fb_Fts5Structure Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_Fts5StructureSegment Ptr
    Dim local8 As c2fb_Fts5Buffer Ptr
    Dim local9 As c2fb_Fts5Buffer Ptr
    Dim local10 As c2fb_Fts5SegWriter
    Dim c2fb_temp_2 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local11 As Const ZString Ptr
    Dim local12 As c2fb_c_int
    Dim local13 As Const UByte Ptr
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim local16 As c2fb_int64
    Dim local17 As c2fb_int64
    Dim local18 As c2fb_c_int
    Dim local19 As c2fb_uint64
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_u8 Ptr
    Dim c2fb_temp_18 As UByte
    Dim local20 As c2fb_uint64
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_int64
    Dim c2fb_temp_22 As Long Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_u8 Ptr
    Dim c2fb_temp_25 As UByte
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As Long Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_u8 Ptr
    Dim c2fb_temp_30 As UByte
    Dim c2fb_temp_31 As c2fb_c_int
    Dim local21 As c2fb_c_int
    Dim local22 As c2fb_c_int
    Dim local23 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Any Ptr
    Dim c2fb_temp_36 As Long Ptr
    Dim c2fb_temp_37 As c2fb_c_int
    Dim local24 As Const UByte Ptr
    Dim local25 As c2fb_c_int
    Dim local26 As c2fb_c_int
    Dim local27 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As Any Ptr
    Dim c2fb_temp_41 As Long Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As Long Ptr
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_48 As Long Ptr
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As Long Ptr
    Dim c2fb_temp_51 As c2fb_c_int
    Dim c2fb_temp_52 As Long Ptr
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As c2fb_u64 Ptr
    Dim c2fb_temp_55 As c2fb_uint64
    Dim c2fb_temp_56 As c2fb_u64 Ptr
    Dim c2fb_temp_57 As c2fb_uint64
    Dim c2fb_temp_58 As c2fb_u64 Ptr
    Dim c2fb_temp_59 As c2fb_uint64
    Dim c2fb_temp_60 As c2fb_u64 Ptr
    Dim c2fb_temp_61 As c2fb_uint64
    Dim c2fb_temp_62 As Long Ptr
    Dim c2fb_temp_63 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Hash Ptr, arg0->pHash)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0))))
    local1 = c2fb_temp_0
    fts5StructureInvalidate(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0))
    If (-Cast(c2fb_c_int, ((sqlite3Fts5HashIsEmpty(CPtr(_c2fb_record_c2fb_Fts5Hash Ptr, local0)) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, fts5AllocateSegid(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1)))
        local2 = c2fb_temp_1
        If local2 Then
            local4 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz
            local5 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail
            local6 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bSecureDelete
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            fts5WriteInit(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5SegWriter Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local10))), local2)
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local10.writer.buf)))
            local8 = c2fb_temp_2
            c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local10.writer.pgidx)))
            local9 = c2fb_temp_3
#ifdef SQLITE_DEBUG
            If arg0->rc = SQLITE_OK AndAlso _
               local8->nSpace < local4 + FTS5_DATA_PADDING Then _
                sqlite3DebugAssert(StrPtr(!"p->rc || pBuf->nSpace>=(pgsz + FTS5_DATA_PADDING)"))
            If arg0->rc = SQLITE_OK AndAlso _
               local9->nSpace < local4 + FTS5_DATA_PADDING Then _
                sqlite3DebugAssert(StrPtr(!"p->rc || pPgidx->nSpace>=(pgsz + FTS5_DATA_PADDING)"))
#endif
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_4 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5HashScanInit(CPtr(_c2fb_record_c2fb_Fts5Hash Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
                c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            End If
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3Fts5HashScanEof(CPtr(_c2fb_record_c2fb_Fts5Hash Ptr, local0)))))) <> 0)))))
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_external_sqlite3Fts5HashScanEntry(CPtr(_c2fb_record_c2fb_Fts5Hash Ptr, local0), CPtr(Const ZString Ptr Ptr, @(local11)), CPtr(c2fb_c_int Ptr, @(local12)), CPtr(Const UByte Ptr Ptr, @(local13)), CPtr(c2fb_c_int Ptr, @(local14)))
                If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                    fts5WriteAppendTerm(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5SegWriter Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local10))), local12, CPtr(Const UByte Ptr, local11))
                    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_0
                    End If
#ifdef SQLITE_DEBUG
                    If local10.bFirstRowidInPage <> 0 Then _
                        sqlite3DebugAssert(StrPtr(!"writer.bFirstRowidInPage==0"))
#endif
                    ' C unused-parameter annotation
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local6 = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 >= (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (local8->n + local9->n)) + local14)) + Cast(c2fb_c_int, 1ULL)))))))) <> 0))))) Then
                    ' C unused-parameter annotation
                    c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((local8)->p[(local8)->n]))), CPtr(Const Any Ptr, local13), local14))
                    c2fb_temp_7 = CPtr(Long Ptr, @((local8)->n))
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_7)) + local14)))
                    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
                    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                    ' empty C statement
                Else
                    local15 = (-Cast(c2fb_c_int, (local6 = 0)))
                    local16 = Cast(c2fb_c_int, &O0ULL)
                    local17 = Cast(c2fb_c_int, &O0ULL)
                    local18 = Cast(c2fb_c_int, &O0ULL)
                    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local18 < local14)))) <> 0)))))
                        local19 = Cast(c2fb_c_int, &O0ULL)
                        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local18 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local13[local18]))), CPtr(c2fb_uint64 Ptr, @(local19)))))))
                        local18 = c2fb_temp_9
                        c2fb_temp_10 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, local16) + local19)))
                        local16 = c2fb_temp_10
                        If local6 Then
                            If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, 1ULL))))) Then
                                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local18 < local14)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13[local18]) = Cast(c2fb_c_int, &H00ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (fts5FlushSecureDelete(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1), local11, local12, local16) = 0))) <> 0))))) Then
                                    c2fb_temp_11 = local18
                                    local18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
                                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local18 < local14)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13[local18]) = Cast(c2fb_c_int, &H00ULL))))) <> 0))))) Then
                                        c2fb_temp_12 = local18
                                        local18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
                                    Else
                                        Goto c2fb_flow_3
                                    End If
                                End If
                            Else
                                If (-Cast(c2fb_c_int, ((((Cast(c2fb_c_int, (Cast(c2fb_c_int, local13[local18]) And Cast(c2fb_c_int, &H01ULL)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (fts5FlushSecureDelete(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1), local11, local12, local16) = 0))) <> 0))))) Then
                                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13[local18]) = Cast(c2fb_c_int, &H01ULL))))) <> 0))))) Then
                                        c2fb_temp_13 = local18
                                        local18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                                        Goto c2fb_flow_3
                                    End If
                                End If
                            End If
                        End If
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local15 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                            fts5WriteAppendTerm(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5SegWriter Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local10))), local12, CPtr(Const UByte Ptr, local11))
                            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local15 = c2fb_temp_14
#ifdef SQLITE_DEBUG
                            If arg0->rc = SQLITE_OK AndAlso _
                               local10.bFirstRowidInPage <> 0 Then _
                                sqlite3DebugAssert(StrPtr(!"p->rc!=SQLITE_OK || writer.bFirstRowidInPage==0"))
#endif
                            ' C unused-parameter annotation
                        End If
                        If local10.bFirstRowidInPage Then
                            fts5PutU16(CPtr(UByte Ptr, @(local8->p[Cast(c2fb_c_int, &O0ULL)])), Cast(UShort, local8->n))
                            c2fb_temp_15 = CPtr(Long Ptr, @(local8->n))
                            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_15)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local8->p[local8->n])), local16))))
                            (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
                            c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
                            c2fb_temp_17 = CPtr(c2fb_u8 Ptr, @(local10.bFirstRowidInPage))
                            c2fb_temp_18 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                            (*c2fb_temp_17) = Cast(c2fb_u8, c2fb_temp_18)
                            c2fb_temp_18 = Cast(UByte, (*c2fb_temp_17))
                            fts5WriteDlidxAppend(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5SegWriter Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local10))), local16)
                        Else
                            local20 = Cast(c2fb_uint64, (Cast(c2fb_uint64, local16) - Cast(c2fb_uint64, local17)))
                            c2fb_temp_19 = CPtr(Long Ptr, @(local8->n))
                            c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_19)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(local8->p[local8->n])), local20))))
                            (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
                            c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
                        End If
                        If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
                            Goto c2fb_flow_2
                        End If
#ifdef SQLITE_DEBUG
                        If local8->n > local8->nSpace Then _
                            sqlite3DebugAssert(StrPtr(!"pBuf->n<=pBuf->nSpace"))
#endif
                        ' C unused-parameter annotation
                        c2fb_temp_21 = Cast(c2fb_int64, local16)
                        local17 = c2fb_temp_21
                        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, 1ULL))))) Then
                            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local18 < local14)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13[local18]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                                c2fb_temp_22 = CPtr(Long Ptr, @(local8->n))
                                c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
                                (*c2fb_temp_22) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_23 + 1)))
                                c2fb_temp_24 = CPtr(c2fb_u8 Ptr, @(local8->p[c2fb_temp_23]))
                                c2fb_temp_25 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                                (*c2fb_temp_24) = Cast(c2fb_u8, c2fb_temp_25)
                                c2fb_temp_25 = Cast(UByte, (*c2fb_temp_24))
                                c2fb_temp_26 = local18
                                local18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_26 + 1)))
                                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local18 < local14)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local13[local18]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                                    c2fb_temp_27 = CPtr(Long Ptr, @(local8->n))
                                    c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
                                    (*c2fb_temp_27) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
                                    c2fb_temp_29 = CPtr(c2fb_u8 Ptr, @(local8->p[c2fb_temp_28]))
                                    c2fb_temp_30 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                                    (*c2fb_temp_29) = Cast(c2fb_u8, c2fb_temp_30)
                                    c2fb_temp_30 = Cast(UByte, (*c2fb_temp_29))
                                    c2fb_temp_31 = local18
                                    local18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_31 + 1)))
                                End If
                            End If
                            If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local8->n + local9->n))) >= local4)))) Then
                                fts5WriteFlushLeaf(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5SegWriter Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local10))))
                            End If
                        Else
                            local21 = Cast(c2fb_c_int, &O0ULL)
                            local22 = Cast(c2fb_c_int, &O0ULL)
                            local23 = fts5GetPoslistSize(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local13[local18]))), CPtr(c2fb_c_int Ptr, @(local22)), CPtr(c2fb_c_int Ptr, @(local21)))
                            If (-Cast(c2fb_c_int, (((local21 <> 0) AndAlso (local6 <> 0))))) Then
                                c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, local8), Cast(c2fb_int64, (Cast(c2fb_int64, local22) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
                                c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local18 + local23)))
                                local18 = c2fb_temp_32
                                c2fb_temp_33 = Cast(c2fb_c_int, local22)
                                local23 = c2fb_temp_33
                            Else
                                c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local23 + local22)))
                                local23 = c2fb_temp_34
                            End If
                            If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, (local8->n + local9->n)) + local23))) <= local4)))) Then
                                ' C unused-parameter annotation
                                c2fb_temp_35 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((local8)->p[(local8)->n]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local13[local18]))), local23))
                                c2fb_temp_36 = CPtr(Long Ptr, @((local8)->n))
                                c2fb_temp_37 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_36)) + local23)))
                                (*c2fb_temp_36) = Cast(Long, c2fb_temp_37)
                                c2fb_temp_37 = Cast(c2fb_c_int, (*c2fb_temp_36))
                                ' empty C statement
                            Else
                                local24 = CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local13[local18])))
                                local25 = Cast(c2fb_c_int, &O0ULL)
                                While (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))
                                    local26 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (local4 - local8->n)) - local9->n))
                                    local27 = Cast(c2fb_c_int, &O0ULL)
                                    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local23 - local25))) <= local26)))) Then
                                        c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local23 - local25)))
                                        local27 = c2fb_temp_38
                                    Else
                                        c2fb_temp_39 = Cast(c2fb_c_int, fts5PoslistPrefix(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local24[local25]))), local26))
                                        local27 = c2fb_temp_39
                                    End If
#ifdef SQLITE_DEBUG
                                    If local27 <= 0 Then _
                                        sqlite3DebugAssert(StrPtr(!"n>0"))
#endif
                                    ' C unused-parameter annotation
                                    ' C unused-parameter annotation
                                    c2fb_temp_40 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((local8)->p[(local8)->n]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local24[local25]))), local27))
                                    c2fb_temp_41 = CPtr(Long Ptr, @((local8)->n))
                                    c2fb_temp_42 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_41)) + local27)))
                                    (*c2fb_temp_41) = Cast(Long, c2fb_temp_42)
                                    c2fb_temp_42 = Cast(c2fb_c_int, (*c2fb_temp_41))
                                    ' empty C statement
                                    c2fb_temp_43 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local25 + local27)))
                                    local25 = c2fb_temp_43
                                    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local8->n + local9->n))) >= local4)))) Then
                                        fts5WriteFlushLeaf(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5SegWriter Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local10))))
                                    End If
                                    If (-Cast(c2fb_c_int, ((local25 >= local23)))) Then
                                        Goto c2fb_flow_4
                                    End If
                                c2fb_flow_5:
                                Wend
                                c2fb_flow_4:
                            End If
                            c2fb_temp_44 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local18 + local23)))
                            local18 = c2fb_temp_44
                        End If
#ifdef SQLITE_DEBUG
                        If local8->n > local8->nSpace Then _
                            sqlite3DebugAssert(StrPtr(!"pBuf->n<=pBuf->nSpace"))
#endif
                    c2fb_flow_3:
                    Wend
                    c2fb_flow_2:
                End If
#ifdef SQLITE_DEBUG
                If local8->n > local8->nSpace Then _
                    sqlite3DebugAssert(StrPtr(!"pBuf->n<=pBuf->nSpace"))
#endif
                ' C unused-parameter annotation
                If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_external_sqlite3Fts5HashScanNext(CPtr(_c2fb_record_c2fb_Fts5Hash Ptr, local0))
                End If
            c2fb_flow_1:
            Wend
            c2fb_flow_0:
            fts5WriteFinish(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5SegWriter Ptr, CPtr(c2fb_Fts5SegWriter Ptr, @(local10))), CPtr(c2fb_c_int Ptr, @(local3)))
#ifdef SQLITE_DEBUG
            If arg0->rc = SQLITE_OK AndAlso local6 = 0 AndAlso local3 <= 0 Then _
                sqlite3DebugAssert(StrPtr(!"p->rc!=SQLITE_OK || bSecureDelete || pgnoLast>0"))
#endif
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local3 > Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((local1->nLevel = Cast(c2fb_c_int, &O0ULL))))) Then
                    fts5StructureAddLevel(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr Ptr, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local1))))
                End If
                fts5StructureExtendLevel(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))
                If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_45 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local1)))[Cast(c2fb_c_int, &O0ULL)].nSeg))
                    c2fb_temp_46 = Cast(c2fb_c_int, (*c2fb_temp_45))
                    (*c2fb_temp_45) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_46 + 1)))
                    c2fb_temp_47 = CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local1)))[Cast(c2fb_c_int, &O0ULL)].aSeg))[c2fb_temp_46])))
                    local7 = c2fb_temp_47
                    c2fb_temp_48 = CPtr(Long Ptr, @(local7->iSegid))
                    c2fb_temp_49 = Cast(c2fb_c_int, local2)
                    (*c2fb_temp_48) = Cast(Long, c2fb_temp_49)
                    c2fb_temp_49 = Cast(c2fb_c_int, (*c2fb_temp_48))
                    c2fb_temp_50 = CPtr(Long Ptr, @(local7->pgnoFirst))
                    c2fb_temp_51 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_50) = Cast(Long, c2fb_temp_51)
                    c2fb_temp_51 = Cast(c2fb_c_int, (*c2fb_temp_50))
                    c2fb_temp_52 = CPtr(Long Ptr, @(local7->pgnoLast))
                    c2fb_temp_53 = Cast(c2fb_c_int, local3)
                    (*c2fb_temp_52) = Cast(Long, c2fb_temp_53)
                    c2fb_temp_53 = Cast(c2fb_c_int, (*c2fb_temp_52))
                    If (-Cast(c2fb_c_int, ((local1->nOriginCntr > Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
                        c2fb_temp_54 = CPtr(c2fb_u64 Ptr, @(local7->iOrigin1))
                        c2fb_temp_55 = Cast(c2fb_uint64, local1->nOriginCntr)
                        (*c2fb_temp_54) = Cast(c2fb_u64, c2fb_temp_55)
                        c2fb_temp_55 = Cast(c2fb_uint64, (*c2fb_temp_54))
                        c2fb_temp_56 = CPtr(c2fb_u64 Ptr, @(local7->iOrigin2))
                        c2fb_temp_57 = Cast(c2fb_uint64, local1->nOriginCntr)
                        (*c2fb_temp_56) = Cast(c2fb_u64, c2fb_temp_57)
                        c2fb_temp_57 = Cast(c2fb_uint64, (*c2fb_temp_56))
                        c2fb_temp_58 = CPtr(c2fb_u64 Ptr, @(local7->nEntry))
                        c2fb_temp_59 = Cast(c2fb_uint64, arg0->nPendingRow)
                        (*c2fb_temp_58) = Cast(c2fb_u64, c2fb_temp_59)
                        c2fb_temp_59 = Cast(c2fb_uint64, (*c2fb_temp_58))
                        c2fb_temp_60 = CPtr(c2fb_u64 Ptr, @(local1->nOriginCntr))
                        c2fb_temp_61 = Cast(c2fb_uint64, (*c2fb_temp_60))
                        (*c2fb_temp_60) = Cast(c2fb_uint64, Cast(c2fb_uint64, (c2fb_temp_61 + 1)))
                    End If
                    c2fb_temp_62 = CPtr(Long Ptr, @(local1->nSegment))
                    c2fb_temp_63 = Cast(c2fb_c_int, (*c2fb_temp_62))
                    (*c2fb_temp_62) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_63 + 1)))
                End If
                fts5StructurePromote(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), Cast(c2fb_c_int, &O0ULL), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1))
            End If
        End If
    End If
    fts5IndexAutomerge(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr Ptr, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local1))), Cast(c2fb_c_int, (local3 + arg0->nContentlessDelete)))
    fts5IndexCrisismerge(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr Ptr, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local1))))
    fts5StructureWrite(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1))
    fts5StructureRelease(CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1))
End Sub
Private Sub fts5IndexFlush CDecl Alias "fts5IndexFlush" (ByVal arg0 As c2fb_Fts5Index Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5836
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    If arg0->flushRc Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = Cast(c2fb_c_int, arg0->flushRc)
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        Return
    End If
    If (-Cast(c2fb_c_int, (((arg0->nPendingData <> 0) OrElse (arg0->nContentlessDelete <> 0))))) Then
        ' C unused-parameter annotation
        fts5FlushOneHash(arg0)
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3Fts5HashClear(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash))
            c2fb_temp_2 = CPtr(Long Ptr, @(arg0->nPendingData))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            c2fb_temp_4 = CPtr(Long Ptr, @(arg0->nPendingRow))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
            c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            c2fb_temp_6 = CPtr(Long Ptr, @(arg0->nContentlessDelete))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        Else
            If (-Cast(c2fb_c_int, (((arg0->nPendingData <> 0) OrElse (arg0->nContentlessDelete <> 0))))) Then
                c2fb_temp_8 = CPtr(Long Ptr, @(arg0->flushRc))
                c2fb_temp_9 = Cast(c2fb_c_int, arg0->rc)
                (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
                c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
            End If
        End If
    End If
End Sub
Private Function fts5IndexOptimizeStruct CDecl Alias "fts5IndexOptimizeStruct" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Structure Ptr) As c2fb_Fts5Structure Ptr
    Dim pNew As c2fb_Fts5Structure Ptr
    Dim pLevel As c2fb_Fts5StructureLevel Ptr
    Dim pSourceLevel As c2fb_Fts5StructureLevel Ptr
    Dim pSourceSegment As c2fb_Fts5StructureSegment Ptr
    Dim pDestSegment As c2fb_Fts5StructureSegment Ptr
    Dim nByte As c2fb_int64
    Dim nSeg As c2fb_c_int
    Dim iLevel As c2fb_c_int
    Dim iSeg As c2fb_c_int
    Dim iSegOut As c2fb_c_int

    pNew = 0
    nSeg = arg1->nSegment
    If nSeg = 0 Then Return 0

    For iLevel = 0 To arg1->nLevel - 1
        pLevel = CPtr(c2fb_Fts5StructureLevel Ptr, _
            c2fb_Fts5Structure_aLevel_tail_ptr(arg1)) + iLevel
#ifdef SQLITE_DEBUG
        If pLevel->nMerge > pLevel->nSeg Then _
            sqlite3DebugAssert(StrPtr(!"pStruct->aLevel[i].nMerge<=nThis"))
#endif
        If pLevel->nSeg > 0 AndAlso _
            (pLevel->nSeg = nSeg OrElse _
            (pLevel->nSeg = nSeg - 1 AndAlso _
                pLevel->nMerge = pLevel->nSeg)) Then
            If nSeg = 1 AndAlso pLevel->nSeg = 1 Then
                pSourceSegment = pLevel->aSeg
                If pSourceSegment->nPgTombstone = 0 Then Return 0
            End If
            fts5StructureRef(arg1)
            Return arg1
        End If
    Next

    ' Allocate room for the existing levels, one extra level, and the
    ' reserved tail slot used by SQLite's structure-growth path.
    nByte = SizeOf(c2fb_Fts5Structure) - _
        SizeOf(c2fb_Fts5StructureLevel)
    nByte += CULngInt(arg1->nLevel + 2) * _
        SizeOf(c2fb_Fts5StructureLevel)
#ifdef SQLITE_DEBUG
    If nByte <> (SizeOf(c2fb_Fts5Structure) - _
        SizeOf(c2fb_Fts5StructureLevel) + _
        (arg1->nLevel + 2) * SizeOf(c2fb_Fts5StructureLevel)) Then _
        sqlite3DebugAssert(StrPtr(!"nByte==(i64)SZ_FTS5STRUCTURE(pStruct->nLevel+2)"))
#endif
    pNew = CPtr(c2fb_Fts5Structure Ptr, _
        c2fb_external_sqlite3Fts5MallocZero(@arg0->rc, nByte))

    If pNew Then
        pNew->nLevel = arg1->nLevel + 1
        If pNew->nLevel > FTS5_MAX_LEVEL Then pNew->nLevel = FTS5_MAX_LEVEL
        pNew->nRef = 1
        pNew->nWriteCounter = arg1->nWriteCounter
        pNew->nOriginCntr = arg1->nOriginCntr

        pLevel = CPtr(c2fb_Fts5StructureLevel Ptr, _
            c2fb_Fts5Structure_aLevel_tail_ptr(pNew)) + (pNew->nLevel - 1)
        nByte = CULngInt(nSeg) * SizeOf(c2fb_Fts5StructureSegment)
        pLevel->aSeg = CPtr(c2fb_Fts5StructureSegment_ Ptr, _
            c2fb_external_sqlite3Fts5MallocZero(@arg0->rc, nByte))

        If pLevel->aSeg Then
            iSegOut = 0
            For iLevel = arg1->nLevel - 1 To 0 Step -1
                pSourceLevel = CPtr(c2fb_Fts5StructureLevel Ptr, _
                    c2fb_Fts5Structure_aLevel_tail_ptr(arg1)) + iLevel
                For iSeg = 0 To pSourceLevel->nSeg - 1
                    pSourceSegment = pSourceLevel->aSeg + iSeg
                    pDestSegment = pLevel->aSeg + iSegOut
                    c2fb_crt_memcpy(CPtr(Any Ptr, pDestSegment), _
                        CPtr(Const Any Ptr, pSourceSegment), _
                        Cast(c2fb_size_t, SizeOf(c2fb_Fts5StructureSegment)))
                    iSegOut += 1
                Next
            Next
            pNew->nSegment = nSeg
            pLevel->nSeg = nSeg
        Else
            sqlite3_free(pNew)
            pNew = 0
        End If
    End If

    Return pNew
End Function

Function sqlite3Fts5IndexOptimize CDecl Alias "sqlite3Fts5IndexOptimize" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5925
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim local1 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Structure Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
#ifdef SQLITE_DEBUG
    If arg0->rc <> SQLITE_OK Then _
        sqlite3DebugAssert(StrPtr(!"p->rc==SQLITE_OK"))
#endif
    ' C unused-parameter annotation
    fts5IndexFlush(arg0)
#ifdef SQLITE_DEBUG
    If arg0->rc = SQLITE_OK AndAlso arg0->nContentlessDelete <> 0 Then _
        sqlite3DebugAssert(StrPtr(!"p->rc!=SQLITE_OK || p->nContentlessDelete==0"))
#endif
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(arg0)))
    local0 = c2fb_temp_0
#ifdef SQLITE_DEBUG
    If arg0->rc = SQLITE_OK AndAlso local0 = 0 Then _
        sqlite3DebugAssert(StrPtr(!"p->rc!=SQLITE_OK || pStruct!=0"))
#endif
    ' C unused-parameter annotation
    fts5StructureInvalidate(arg0)
    If local0 Then
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5IndexOptimizeStruct(arg0, local0)))
        local1 = c2fb_temp_1
    End If
    fts5StructureRelease(local0)
#ifdef SQLITE_DEBUG
    If local1 <> 0 AndAlso local1->nSegment <= 0 Then _
        sqlite3DebugAssert(StrPtr(!"pNew==0 || pNew->nSegment>0"))
#endif
    ' C unused-parameter annotation
    If local1 Then
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local1)))[local2].nSeg = Cast(c2fb_c_int, &O0ULL)))))
            ' empty C block
        c2fb_flow_1:
            c2fb_temp_3 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local1)))[local2].nSeg > Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            local3 = Cast(c2fb_c_int, 1000ULL)
            fts5IndexMergeLevel(arg0, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local1)), local2, CPtr(c2fb_c_int Ptr, @(local3)))
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        fts5StructureWrite(arg0, local1)
        fts5StructureRelease(local1)
    End If
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IndexMerge CDecl Alias "sqlite3Fts5IndexMerge" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5961
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    fts5IndexFlush(arg0)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(arg0)))
    local0 = c2fb_temp_0
    If local0 Then
        local1 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nUsermerge
        fts5StructureInvalidate(arg0)
        If (-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) Then
            local2 = CPtr(c2fb_Fts5Structure Ptr, fts5IndexOptimizeStruct(arg0, local0))
            fts5StructureRelease(local0)
            c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local2)
            local0 = c2fb_temp_1
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local1 = c2fb_temp_2
            c2fb_temp_3 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, ((arg1 = (Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))) - (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H7fffffffULL))))))))))))), (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H7fffffffULL)))), (Cast(c2fb_c_int, (arg1 * Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))))
            arg1 = c2fb_temp_3
        End If
        If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso (local0->nLevel <> 0))))) Then
            If fts5IndexMerge(arg0, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local0)), arg1, local1) Then
                fts5StructureWrite(arg0, local0)
            End If
        End If
        fts5StructureRelease(local0)
    End If
    Return fts5IndexReturn(arg0)
End Function
Private Sub fts5AppendRowid CDecl Alias "fts5AppendRowid" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5986
    ' C unused-parameter annotation
    c2fb_external_sqlite3Fts5BufferAppendVarint(CPtr(c2fb_c_int Ptr, @(arg0->rc)), arg3, Cast(c2fb_int64, arg1))
End Sub
Private Sub fts5AppendPoslist CDecl Alias "fts5AppendPoslist" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 5996
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Any Ptr

    local0 = arg2->base.nData
    local1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 9ULL))) + Cast(c2fb_c_int, 9ULL))) + Cast(c2fb_c_int, 8ULL)))
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((arg3)->n)) + Cast(c2fb_c_uint, (local1)))) <= Cast(c2fb_c_uint, ((arg3)->nSpace)))))), Cast(c2fb_c_int, &O0ULL), c2fb_external_sqlite3Fts5BufferSize((CPtr(c2fb_c_int Ptr, @(arg0->rc))), (arg3), Cast(c2fb_c_int, ((local1) + (arg3)->n))))))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(Long Ptr, @((arg3)->n))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_0)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((arg3)->p[(arg3)->n])), (arg1)))))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        ' C unused-parameter annotation
        ' empty C statement
        c2fb_temp_2 = CPtr(Long Ptr, @((arg3)->n))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_2)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((arg3)->p[(arg3)->n])), (Cast(c2fb_c_int, (local0 * Cast(c2fb_c_int, 2ULL))))))))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        ' C unused-parameter annotation
        ' empty C statement
        ' C unused-parameter annotation
        c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((arg3)->p[(arg3)->n]))), CPtr(Const Any Ptr, arg2->base.pData), local0))
        c2fb_temp_5 = CPtr(Long Ptr, @((arg3)->n))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_5)) + local0)))
        (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        ' empty C statement
        c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg3->p[arg3->n]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 8ULL)))
    End If
End Sub
Private Sub fts5DoclistIterNext CDecl Alias "fts5DoclistIterNext" (ByVal arg0 As c2fb_Fts5DoclistIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6014
    Dim local0 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_1 As UByte Ptr
    Dim local1 As c2fb_uint64
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As c2fb_i64 Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_16 As UByte Ptr

    local0 = CPtr(UByte Ptr, (CPtr(UByte Ptr, (arg0->aPoslist + arg0->nSize)) + arg0->nPoslist))
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0 >= arg0->aEof)))) Then
        c2fb_temp_0 = CPtr(c2fb_u8 Ptr Ptr, @(arg0->aPoslist))
        c2fb_temp_1 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = CPtr(c2fb_u8 Ptr, c2fb_temp_1)
        c2fb_temp_1 = CPtr(UByte Ptr, (*c2fb_temp_0))
    Else
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(UByte Ptr, (local0 + c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, local0), CPtr(c2fb_uint64 Ptr, @(local1)))))
        local0 = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_i64 Ptr, @(arg0->iRowid))
        c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_3))) + local1)))
        (*c2fb_temp_3) = Cast(c2fb_i64, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_int64, (*c2fb_temp_3))
        If Cast(c2fb_c_int, (Cast(c2fb_c_int, local0[Cast(c2fb_c_int, &O0ULL)]) And Cast(c2fb_c_int, &H80ULL))) Then
            ' C automatic storage declaration
            c2fb_temp_5 = CPtr(Long Ptr, @(arg0->nSize))
            c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, local0), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local2))))))
            (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
            c2fb_temp_7 = CPtr(Long Ptr, @(arg0->nPoslist))
            c2fb_temp_8 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (local2 Shr Cast(c2fb_c_int, 1ULL)))))
            (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        Else
            c2fb_temp_9 = CPtr(Long Ptr, @(arg0->nPoslist))
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0[Cast(c2fb_c_int, &O0ULL)]))) Shr Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
            c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
            c2fb_temp_11 = CPtr(Long Ptr, @(arg0->nSize))
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        End If
        c2fb_temp_13 = CPtr(c2fb_u8 Ptr Ptr, @(arg0->aPoslist))
        c2fb_temp_14 = local0
        (*c2fb_temp_13) = CPtr(c2fb_u8 Ptr, c2fb_temp_14)
        c2fb_temp_14 = CPtr(UByte Ptr, (*c2fb_temp_13))
        If (-Cast(c2fb_c_int, ((CPtr(UByte Ptr, @(arg0->aPoslist[arg0->nPoslist])) > arg0->aEof)))) Then
            c2fb_temp_15 = CPtr(c2fb_u8 Ptr Ptr, @(arg0->aPoslist))
            c2fb_temp_16 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_15) = CPtr(c2fb_u8 Ptr, c2fb_temp_16)
            c2fb_temp_16 = CPtr(UByte Ptr, (*c2fb_temp_15))
        End If
    End If
End Sub
Private Sub fts5DoclistIterInit CDecl Alias "fts5DoclistIterInit" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5DoclistIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6043
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_4 As UByte Ptr

    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5DoclistIter))))
    If (-Cast(c2fb_c_int, ((arg0->n > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(c2fb_u8 Ptr Ptr, @(arg1->aPoslist))
        c2fb_temp_2 = arg0->p
        (*c2fb_temp_1) = CPtr(c2fb_u8 Ptr, c2fb_temp_2)
        c2fb_temp_2 = CPtr(UByte Ptr, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(c2fb_u8 Ptr Ptr, @(arg1->aEof))
        c2fb_temp_4 = CPtr(UByte Ptr, @(arg0->p[arg0->n]))
        (*c2fb_temp_3) = CPtr(c2fb_u8 Ptr, c2fb_temp_4)
        c2fb_temp_4 = CPtr(UByte Ptr, (*c2fb_temp_3))
        fts5DoclistIterNext(arg1)
    End If
End Sub
Private Sub fts5BufferSwap CDecl Alias "fts5BufferSwap" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6082
    Dim local0 As c2fb_Fts5Buffer
    Dim c2fb_temp_0 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Buffer
    Dim c2fb_temp_2 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Buffer

    local0 = (*arg0)
    c2fb_temp_0 = CPtr(c2fb_Fts5Buffer Ptr, @((*arg0)))
    c2fb_temp_1 = (*arg1)
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_Fts5Buffer Ptr, @((*arg1)))
    c2fb_temp_3 = local0
    (*c2fb_temp_2) = c2fb_temp_3
End Sub
Private Sub fts5NextRowid CDecl Alias "fts5NextRowid" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_int64 Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6088
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_uint64
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_int64 Ptr
    Dim c2fb_temp_5 As c2fb_int64

    local0 = (*arg1)
    If (-Cast(c2fb_c_int, ((local0 >= arg0->n)))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_0) = c2fb_temp_1
    Else
        ' C automatic storage declaration
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->p[local0]))), CPtr(c2fb_uint64 Ptr, @(local1)))))))
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(c2fb_int64 Ptr, @((*arg2)))
        c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (*c2fb_temp_4)) + local1)))
        (*c2fb_temp_4) = c2fb_temp_5
    End If
End Sub
Private Sub fts5MergeRowidLists CDecl Alias "fts5MergeRowidLists" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6103
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_Fts5Buffer Ptr
    Dim local6 As c2fb_Fts5Buffer
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5Buffer Ptr, arg3)[Cast(c2fb_c_int, &O0ULL)]))
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local6))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
    ' C unused-parameter annotation
    c2fb_external_sqlite3Fts5BufferSize(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local6)), Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1->n + local5->n)) + Cast(c2fb_c_int, 9ULL))))
    If arg0->rc Then
        Return
    End If
    fts5NextRowid(arg1, CPtr(c2fb_c_int Ptr, @(local0)), CPtr(c2fb_int64 Ptr, @(local2)))
    fts5NextRowid(local5, CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(local3)))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 < local3)))) <> 0)))))) <> 0))))) Then
            ' C unused-parameter annotation
            c2fb_temp_1 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local6)))->n))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_1)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local6)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local6)))->n])), (Cast(c2fb_uint64, (Cast(c2fb_uint64, local2) - Cast(c2fb_uint64, local4))))))))
            (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
            c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
            ' C unused-parameter annotation
            ' empty C statement
            c2fb_temp_3 = Cast(c2fb_int64, local2)
            local4 = c2fb_temp_3
            fts5NextRowid(arg1, CPtr(c2fb_c_int Ptr, @(local0)), CPtr(c2fb_int64 Ptr, @(local2)))
        Else
            ' C unused-parameter annotation
            c2fb_temp_4 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local6)))->n))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_4)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local6)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local6)))->n])), (Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) - Cast(c2fb_uint64, local4))))))))
            (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
            c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            ' C unused-parameter annotation
            ' empty C statement
            c2fb_temp_6 = Cast(c2fb_int64, local3)
            local4 = c2fb_temp_6
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = local3)))) <> 0))))) Then
                fts5NextRowid(arg1, CPtr(c2fb_c_int Ptr, @(local0)), CPtr(c2fb_int64 Ptr, @(local2)))
            End If
            fts5NextRowid(local5, CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(local3)))
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    fts5BufferSwap(CPtr(c2fb_Fts5Buffer Ptr, @(local6)), arg1)
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local6)))
End Sub
Private Sub fts5PrefixMergerInsertByRowid CDecl Alias "fts5PrefixMergerInsertByRowid" (ByVal arg0 As c2fb_PrefixMerger Ptr Ptr, ByVal arg1 As c2fb_PrefixMerger Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6155
    Dim local0 As c2fb_PrefixMerger Ptr Ptr
    Dim c2fb_temp_0 As c2fb_PrefixMerger Ptr Ptr
    Dim c2fb_temp_1 As c2fb_PrefixMerger_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_3 As c2fb_PrefixMerger Ptr Ptr
    Dim c2fb_temp_4 As c2fb_PrefixMerger Ptr

    If arg1->iter.aPoslist Then
        local0 = arg0
        While (-Cast(c2fb_c_int, ((((*local0) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->iter.iRowid > ((*local0))->iter.iRowid)))) <> 0)))))
            c2fb_temp_0 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr Ptr, CPtr(c2fb_PrefixMerger Ptr Ptr, @(((*local0))->pNext)))
            local0 = c2fb_temp_0
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_1 = CPtr(c2fb_PrefixMerger_ Ptr Ptr, @(arg1->pNext))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, (*local0))
        (*c2fb_temp_1) = CPtr(c2fb_PrefixMerger_ Ptr, c2fb_temp_2)
        c2fb_temp_2 = CPtr(c2fb_PrefixMerger Ptr, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(c2fb_PrefixMerger Ptr Ptr, @((*local0)))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, arg1)
        (*c2fb_temp_3) = c2fb_temp_4
    End If
End Sub
Private Sub fts5PrefixMergerInsertByPosition CDecl Alias "fts5PrefixMergerInsertByPosition" (ByVal arg0 As c2fb_PrefixMerger Ptr Ptr, ByVal arg1 As c2fb_PrefixMerger Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6169
    Dim local0 As c2fb_PrefixMerger Ptr Ptr
    Dim c2fb_temp_0 As c2fb_PrefixMerger Ptr Ptr
    Dim c2fb_temp_1 As c2fb_PrefixMerger_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_3 As c2fb_PrefixMerger Ptr Ptr
    Dim c2fb_temp_4 As c2fb_PrefixMerger Ptr

    If (-Cast(c2fb_c_int, ((arg1->iPos >= Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        local0 = arg0
        While (-Cast(c2fb_c_int, ((((*local0) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->iPos > ((*local0))->iPos)))) <> 0)))))
            c2fb_temp_0 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr Ptr, CPtr(c2fb_PrefixMerger Ptr Ptr, @(((*local0))->pNext)))
            local0 = c2fb_temp_0
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_1 = CPtr(c2fb_PrefixMerger_ Ptr Ptr, @(arg1->pNext))
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, (*local0))
        (*c2fb_temp_1) = CPtr(c2fb_PrefixMerger_ Ptr, c2fb_temp_2)
        c2fb_temp_2 = CPtr(c2fb_PrefixMerger Ptr, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(c2fb_PrefixMerger Ptr Ptr, @((*local0)))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, arg1)
        (*c2fb_temp_3) = c2fb_temp_4
    End If
End Sub
Private Sub fts5MergePrefixLists CDecl Alias "fts5MergePrefixLists" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6188
    Dim local0(0 To 15) As c2fb_PrefixMerger
    Dim local1 As c2fb_PrefixMerger Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_Fts5Buffer
    Dim local5 As c2fb_Fts5Buffer
    Dim local6 As c2fb_int64
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_int64 Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_PrefixMerger Ptr
    Dim local11 As c2fb_PrefixMerger Ptr
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_PrefixMerger Ptr
    Dim local13 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_i64 Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_16 As UByte Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_20 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_21 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_22 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_23 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As Any Ptr
    Dim c2fb_temp_28 As Long Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As Any Ptr
    Dim c2fb_temp_31 As Long Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim local14 As c2fb_PrefixMerger Ptr
    Dim local15 As c2fb_PrefixMerger Ptr
    Dim local16 As c2fb_Fts5DoclistIter Ptr
    Dim c2fb_temp_36 As Any Ptr
    Dim c2fb_temp_37 As Long Ptr
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_PrefixMerger Ptr
    Dim c2fb_temp_40 As Any Ptr
    Dim c2fb_temp_41 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_42 As c2fb_Fts5Buffer

    ' C automatic array storage
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local5 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local6 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_PrefixMerger Ptr, (@local0(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_PrefixMerger))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))))))))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, CPtr(c2fb_PrefixMerger Ptr, @(local0(arg2))))
    local1 = c2fb_temp_1
    fts5DoclistIterInit(arg1, CPtr(c2fb_Fts5DoclistIter Ptr, @(local1->iter)))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local2 < arg2))))
        fts5DoclistIterInit(CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5Buffer Ptr, arg3)[local2])), CPtr(c2fb_Fts5DoclistIter Ptr, @(local0(local2).iter)))
        fts5PrefixMergerInsertByRowid(CPtr(c2fb_PrefixMerger Ptr Ptr, @(local1)), CPtr(c2fb_PrefixMerger Ptr, @(local0(local2))))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + CPtr(c2fb_Fts5Buffer Ptr, arg3)[local2].n)))
        local3 = c2fb_temp_4
    c2fb_flow_1:
        c2fb_temp_3 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1->n + Cast(c2fb_c_int, 9ULL))) + Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) * arg2)))))))
    local3 = c2fb_temp_5
    If c2fb_external_sqlite3Fts5BufferSize(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local4)), local3) Then
        Return
    End If
    While local1
        ' C unused-parameter annotation
        c2fb_temp_6 = CPtr(Long Ptr, @(((CPtr(c2fb_Fts5Buffer Ptr, @(local4))))->n))
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_6)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(((CPtr(c2fb_Fts5Buffer Ptr, @(local4))))->p[((CPtr(c2fb_Fts5Buffer Ptr, @(local4))))->n])), (Cast(c2fb_uint64, (Cast(c2fb_uint64, (local1->iter.iRowid)) - Cast(c2fb_uint64, (local6)))))))))
        (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        ' C unused-parameter annotation
        ' empty C statement
        c2fb_temp_8 = CPtr(c2fb_int64 Ptr, @((local6)))
        c2fb_temp_9 = Cast(c2fb_int64, (local1->iter.iRowid))
        (*c2fb_temp_8) = c2fb_temp_9
        ' empty C statement
        If (-Cast(c2fb_c_int, (((CPtr(c2fb_PrefixMerger Ptr, local1->pNext) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6 = CPtr(c2fb_PrefixMerger Ptr, local1->pNext)->iter.iRowid)))) <> 0))))) Then
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = Cast(c2fb_c_int, 8ULL)
            local9 = Cast(c2fb_c_int, &O0ULL)
            local10 = local1
            local11 = Cast(c2fb_c_int, &O0ULL)
            local12 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_10 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_10
            While (-Cast(c2fb_c_int, (((local10 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local10->iter.iRowid = local6)))) <> 0)))))
                local13 = CPtr(c2fb_PrefixMerger Ptr, local10->pNext)
                c2fb_temp_11 = CPtr(Long Ptr, @(local10->iOff))
                c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
                c2fb_temp_13 = CPtr(c2fb_i64 Ptr, @(local10->iPos))
                c2fb_temp_14 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_13) = Cast(c2fb_i64, c2fb_temp_14)
                c2fb_temp_14 = Cast(c2fb_int64, (*c2fb_temp_13))
                c2fb_temp_15 = CPtr(c2fb_u8 Ptr Ptr, @(local10->aPos))
                c2fb_temp_16 = CPtr(UByte Ptr, @(local10->iter.aPoslist[local10->iter.nSize]))
                (*c2fb_temp_15) = CPtr(c2fb_u8 Ptr, c2fb_temp_16)
                c2fb_temp_16 = CPtr(UByte Ptr, (*c2fb_temp_15))
                c2fb_external_sqlite3Fts5PoslistNext64(CPtr(Const UByte Ptr, (local10)->aPos), (local10)->iter.nPoslist, CPtr(c2fb_c_int Ptr, @((local10)->iOff)), CPtr(c2fb_int64 Ptr, @((local10)->iPos)))
                c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, (local10->iter.nPoslist + Cast(c2fb_c_int, 10ULL))))))
                local8 = c2fb_temp_17
                c2fb_temp_18 = local9
                local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_18 + 1)))
                fts5PrefixMergerInsertByPosition(CPtr(c2fb_PrefixMerger Ptr Ptr, @(local1)), local10)
                c2fb_temp_19 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, local13)
                local10 = c2fb_temp_19
            c2fb_flow_5:
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((CPtr(c2fb_PrefixMerger Ptr, local1->pNext) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                fts5IndexCorruptIdx(arg0)
                Goto c2fb_flow_2
            End If
            If c2fb_external_sqlite3Fts5BufferSize(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local5)), Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, (local9 * Cast(c2fb_c_int, 10ULL)))))) Then
                Goto c2fb_flow_2
            End If
            c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(local5)))
            c2fb_temp_20 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, local1)
            local11 = c2fb_temp_20
            c2fb_temp_21 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, CPtr(c2fb_PrefixMerger Ptr, local11->pNext))
            local1 = c2fb_temp_21
            c2fb_external_sqlite3Fts5PoslistSafeAppend(CPtr(c2fb_Fts5Buffer Ptr, @(local5)), CPtr(c2fb_int64 Ptr, @(local7)), local11->iPos)
            c2fb_external_sqlite3Fts5PoslistNext64(CPtr(Const UByte Ptr, (local11)->aPos), (local11)->iter.nPoslist, CPtr(c2fb_c_int Ptr, @((local11)->iOff)), CPtr(c2fb_int64 Ptr, @((local11)->iPos)))
            fts5PrefixMergerInsertByPosition(CPtr(c2fb_PrefixMerger Ptr Ptr, @(local1)), local11)
            While CPtr(c2fb_PrefixMerger Ptr, local1->pNext)
                c2fb_temp_22 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, local1)
                local11 = c2fb_temp_22
                If (-Cast(c2fb_c_int, ((local11->iPos <> local7)))) Then
                    c2fb_external_sqlite3Fts5PoslistSafeAppend(CPtr(c2fb_Fts5Buffer Ptr, @(local5)), CPtr(c2fb_int64 Ptr, @(local7)), local11->iPos)
                End If
                c2fb_external_sqlite3Fts5PoslistNext64(CPtr(Const UByte Ptr, (local11)->aPos), (local11)->iter.nPoslist, CPtr(c2fb_c_int Ptr, @((local11)->iOff)), CPtr(c2fb_int64 Ptr, @((local11)->iPos)))
                c2fb_temp_23 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, CPtr(c2fb_PrefixMerger Ptr, local11->pNext))
                local1 = c2fb_temp_23
                fts5PrefixMergerInsertByPosition(CPtr(c2fb_PrefixMerger Ptr Ptr, @(local1)), local11)
            c2fb_flow_7:
            Wend
            c2fb_flow_6:
            If (-Cast(c2fb_c_int, ((local1->iPos <> local7)))) Then
                c2fb_external_sqlite3Fts5PoslistSafeAppend(CPtr(c2fb_Fts5Buffer Ptr, @(local5)), CPtr(c2fb_int64 Ptr, @(local7)), local1->iPos)
            End If
            c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1->iter.nPoslist - local1->iOff)))
            local12 = c2fb_temp_24
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local5.n + local12)) > Cast(c2fb_c_int, (local8 - Cast(c2fb_c_int, 8ULL))))))) Then
                If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                    fts5IndexCorruptIdx(arg0)
                End If
                Goto c2fb_flow_2
            End If
            c2fb_temp_25 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->n))
            c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_25)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->n])), (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local5.n + local12))) * Cast(c2fb_c_int, 2ULL))))))))
            (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
            c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
            ' C unused-parameter annotation
            ' empty C statement
            ' C unused-parameter annotation
            c2fb_temp_27 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->n]))), CPtr(Const Any Ptr, local5.p), local5.n))
            c2fb_temp_28 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->n))
            c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_28)) + local5.n)))
            (*c2fb_temp_28) = Cast(Long, c2fb_temp_29)
            c2fb_temp_29 = Cast(c2fb_c_int, (*c2fb_temp_28))
            ' empty C statement
            If (-Cast(c2fb_c_int, ((local12 > Cast(c2fb_c_int, &O0ULL))))) Then
                ' C unused-parameter annotation
                c2fb_temp_30 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->n]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local1->aPos[local1->iOff]))), local12))
                c2fb_temp_31 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->n))
                c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_31)) + local12)))
                (*c2fb_temp_31) = Cast(Long, c2fb_temp_32)
                c2fb_temp_32 = Cast(c2fb_c_int, (*c2fb_temp_31))
                ' empty C statement
            End If
            c2fb_temp_33 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, local10)
            local1 = c2fb_temp_33
            c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_34
            While (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))))))
                local14 = CPtr(c2fb_PrefixMerger Ptr, @(local0(local2)))
                If (-Cast(c2fb_c_int, (((local14->iter.aPoslist <> 0) AndAlso ((-Cast(c2fb_c_int, ((local14->iter.iRowid = local6)))) <> 0))))) Then
                    fts5DoclistIterNext(CPtr(c2fb_Fts5DoclistIter Ptr, @(local14->iter)))
                    fts5PrefixMergerInsertByRowid(CPtr(c2fb_PrefixMerger Ptr Ptr, @(local1)), local14)
                End If
            c2fb_flow_9:
                c2fb_temp_35 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_35 + 1)))
            Wend
            c2fb_flow_8:
        Else
            local15 = local1
            local16 = CPtr(c2fb_Fts5DoclistIter Ptr, @(local15->iter))
            ' C unused-parameter annotation
            c2fb_temp_36 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->p[(CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->n]))), CPtr(Const Any Ptr, local16->aPoslist), Cast(c2fb_c_int, (local16->nPoslist + local16->nSize))))
            c2fb_temp_37 = CPtr(Long Ptr, @((CPtr(c2fb_Fts5Buffer Ptr, @(local4)))->n))
            c2fb_temp_38 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_37)) + Cast(c2fb_c_int, (local16->nPoslist + local16->nSize)))))
            (*c2fb_temp_37) = Cast(Long, c2fb_temp_38)
            c2fb_temp_38 = Cast(c2fb_c_int, (*c2fb_temp_37))
            ' empty C statement
            fts5DoclistIterNext(local16)
            c2fb_temp_39 = CPtr(_c2fb_record_c2fb_PrefixMerger Ptr, CPtr(c2fb_PrefixMerger Ptr, local15->pNext))
            local1 = c2fb_temp_39
            fts5PrefixMergerInsertByRowid(CPtr(c2fb_PrefixMerger Ptr Ptr, @(local1)), local15)
        End If
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    c2fb_external_sqlite3Fts5BufferFree(arg1)
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local5)))
    c2fb_temp_40 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(UByte Ptr, @(local4.p[local4.n]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 8ULL)))
    c2fb_temp_41 = CPtr(c2fb_Fts5Buffer Ptr, @((*arg1)))
    c2fb_temp_42 = local4
    (*c2fb_temp_41) = c2fb_temp_42
End Sub
Private Function fts5VisitEntries CDecl Alias "fts5VisitEntries" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5Colset Ptr, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_callback_356, ByVal arg6 As Any Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6362
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Iter Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_Fts5Structure Ptr
    Dim local4 As c2fb_Fts5SegIter Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As Const UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const UByte Ptr

    local0 = Cast(c2fb_c_int, (Cast(c2fb_c_int, ((IIf(arg4, Cast(c2fb_c_int, &H0008ULL), Cast(c2fb_c_int, &O0ULL))) Or Cast(c2fb_c_int, &H0010ULL))) Or Cast(c2fb_c_int, &H0020ULL)))
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, 1ULL)
    local3 = CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(arg0))
    fts5MultiIterNew(arg0, local3, local0, arg1, CPtr(Const UByte Ptr, arg2), arg3, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_Fts5Iter Ptr Ptr, @(local1)))
    fts5IterSetOutputCb(CPtr(c2fb_c_int Ptr, @(arg0->rc)), local1)
    While (-Cast(c2fb_c_int, ((fts5MultiIterEof(arg0, local1) = Cast(c2fb_c_int, &O0ULL)))))
        local4 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local1)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, local1->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
        local5 = Cast(c2fb_c_int, &O0ULL)
        local6 = Cast(c2fb_c_int, &O0ULL)
        CPtr(c2fb_callback_349, local1->xSetOutputs)(local1, local4)
        If arg0->rc Then
            Goto c2fb_flow_0
        End If
        If local2 Then
            c2fb_temp_0 = Cast(c2fb_c_int, local4->term.n)
            local5 = c2fb_temp_0
            c2fb_temp_1 = CPtr(Const UByte Ptr, local4->term.p)
            local6 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 < arg3)))) <> 0) OrElse (c2fb_crt_memcmp(CPtr(Const Any Ptr, arg2), CPtr(Const Any Ptr, local6), arg3) <> 0))))) Then
                Goto c2fb_flow_0
            End If
        End If
        arg5(arg0, arg6, local1, local6, local5)
    c2fb_flow_1:
        fts5MultiIterNext2(arg0, local1, CPtr(c2fb_c_int Ptr, @(local2)))
    Wend
    c2fb_flow_0:
    fts5MultiIterFree(local1)
    fts5StructureRelease(local3)
    Return arg0->rc
End Function
Private Sub fts5TokendataMerge CDecl Alias "fts5TokendataMerge" (ByVal arg0 As c2fb_Fts5TokenDataMap Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5TokenDataMap Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5TokenDataMap Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6483
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg1)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 < arg3)))) <> 0)))))
        local2 = CPtr(c2fb_Fts5TokenDataMap Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, arg4)[Cast(c2fb_c_int, (local0 + local1))]))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 >= arg3)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg1)))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenDataMap Ptr, arg0)[local0].iRowid < CPtr(c2fb_Fts5TokenDataMap Ptr, arg2)[local1].iRowid)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenDataMap Ptr, arg0)[local0].iRowid = CPtr(c2fb_Fts5TokenDataMap Ptr, arg2)[local1].iRowid)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenDataMap Ptr, arg0)[local0].iPos <= CPtr(c2fb_Fts5TokenDataMap Ptr, arg2)[local1].iPos)))) <> 0)))))) <> 0)))))) <> 0)))))) <> 0))))) Then
            c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local2), CPtr(Const Any Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, arg0)[local0]))), Cast(c2fb_size_t, SizeOf(c2fb_Fts5TokenDataMap))))
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Else
            c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local2), CPtr(Const Any Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, arg2)[local1]))), Cast(c2fb_size_t, SizeOf(c2fb_Fts5TokenDataMap))))
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub
Private Sub fts5TokendataIterAppendMap CDecl Alias "fts5TokendataIterAppendMap" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5TokenDataIter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_int64, ByVal arg5 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6511
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_0 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_Fts5TokenDataMap_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_5 As c2fb_i64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_i64 Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_i64 Ptr
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_i64 Ptr
    Dim c2fb_temp_16 As c2fb_int64

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg1->nMap = arg1->nMapAlloc)))) Then
            local0 = IIf(arg1->nMapAlloc, Cast(c2fb_int64, (arg1->nMapAlloc * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))), Cast(c2fb_int64, Cast(c2fb_c_int, 64ULL)))
            local1 = Cast(c2fb_uint64, (Cast(c2fb_uint64, local0) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5TokenDataMap)))))
            ' C automatic storage declaration
            c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, arg1->aMap)), local1))))
            local2 = c2fb_temp_0
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
                c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
                Return
            End If
            c2fb_temp_3 = CPtr(c2fb_Fts5TokenDataMap_ Ptr Ptr, @(arg1->aMap))
            c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5TokenDataMap Ptr, local2)
            (*c2fb_temp_3) = CPtr(c2fb_Fts5TokenDataMap_ Ptr, c2fb_temp_4)
            c2fb_temp_4 = CPtr(c2fb_Fts5TokenDataMap Ptr, (*c2fb_temp_3))
            c2fb_temp_5 = CPtr(c2fb_i64 Ptr, @(arg1->nMapAlloc))
            c2fb_temp_6 = Cast(c2fb_int64, local0)
            (*c2fb_temp_5) = Cast(c2fb_i64, c2fb_temp_6)
            c2fb_temp_6 = Cast(c2fb_int64, (*c2fb_temp_5))
        End If
        c2fb_temp_7 = CPtr(c2fb_i64 Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, arg1->aMap))[arg1->nMap].iRowid))
        c2fb_temp_8 = Cast(c2fb_int64, arg4)
        (*c2fb_temp_7) = Cast(c2fb_i64, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_int64, (*c2fb_temp_7))
        c2fb_temp_9 = CPtr(c2fb_i64 Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, arg1->aMap))[arg1->nMap].iPos))
        c2fb_temp_10 = Cast(c2fb_int64, arg5)
        (*c2fb_temp_9) = Cast(c2fb_i64, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_int64, (*c2fb_temp_9))
        c2fb_temp_11 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, arg1->aMap))[arg1->nMap].iIter))
        c2fb_temp_12 = Cast(c2fb_c_int, arg2)
        (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
        c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        c2fb_temp_13 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, arg1->aMap))[arg1->nMap].nByte))
        c2fb_temp_14 = Cast(c2fb_c_int, arg3)
        (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
        c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
        c2fb_temp_15 = CPtr(c2fb_i64 Ptr, @(arg1->nMap))
        c2fb_temp_16 = Cast(c2fb_int64, (*c2fb_temp_15))
        (*c2fb_temp_15) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_16 + 1)))
    End If
End Sub
Private Sub fts5TokendataIterSortMap CDecl Alias "fts5TokendataIterSortMap" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5TokenDataIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6549
    Dim local0 As c2fb_Fts5TokenDataMap Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_Fts5TokenDataMap Ptr
    Dim local2 As c2fb_Fts5TokenDataMap Ptr
    Dim local3 As c2fb_Fts5TokenDataMap Ptr
    Dim local4 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_5 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_6 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_7 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_8 As Any Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_uint64, (Cast(c2fb_uint64, arg1->nMap) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5TokenDataMap)))))
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), local1))))
    local0 = c2fb_temp_0
    If local0 Then
        local2 = CPtr(c2fb_Fts5TokenDataMap Ptr, arg1->aMap)
        local3 = local0
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))
        local4 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local4 < arg1->nMap))))
            ' C automatic storage declaration
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local5 = c2fb_temp_3
            While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local5) < arg1->nMap))))
                local6 = (IIf(((-Cast(c2fb_c_int, (((local4) < (Cast(c2fb_int64, (arg1->nMap - Cast(c2fb_int64, local5))))))))), (local4), (Cast(c2fb_int64, (arg1->nMap - Cast(c2fb_int64, local5))))))
                local7 = (IIf(((-Cast(c2fb_c_int, (((local4) < (Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->nMap - Cast(c2fb_int64, local5))) - Cast(c2fb_int64, local6))))))))), (local4), (Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->nMap - Cast(c2fb_int64, local5))) - Cast(c2fb_int64, local6))))))
                fts5TokendataMerge(CPtr(c2fb_Fts5TokenDataMap Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, local2)[local5])), local6, CPtr(c2fb_Fts5TokenDataMap Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, local2)[Cast(c2fb_c_int, (local5 + local6))])), local7, CPtr(c2fb_Fts5TokenDataMap Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local5])))
            c2fb_flow_3:
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_int64, (Cast(c2fb_int64, local5) + (Cast(c2fb_int64, (local4 * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))))))
                local5 = c2fb_temp_4
            Wend
            c2fb_flow_2:
            ' C automatic storage declaration
            c2fb_temp_5 = CPtr(_c2fb_record_c2fb_Fts5TokenDataMap Ptr, local2)
            local8 = c2fb_temp_5
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5TokenDataMap Ptr, local3)
            local2 = c2fb_temp_6
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5TokenDataMap Ptr, local8)
            local3 = c2fb_temp_7
            ' empty C statement
        c2fb_flow_1:
            c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_int64, (local4 * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
            local4 = c2fb_temp_2
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local2 <> CPtr(c2fb_Fts5TokenDataMap Ptr, arg1->aMap))))) Then
            c2fb_temp_8 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, arg1->aMap)), CPtr(Const Any Ptr, local2), Cast(c2fb_uint64, (Cast(c2fb_uint64, arg1->nMap) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5TokenDataMap)))))))
        End If
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Sub fts5TokendataIterDelete CDecl Alias "fts5TokendataIterDelete" (ByVal arg0 As c2fb_Fts5TokenDataIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6592
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local0) < arg0->nIter))))
            fts5MultiIterFree(CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(arg0)))[local0])
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->terms)))
        sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, arg0->aPoslistReader)))
        sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, arg0->aMap)))
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Private Sub prefixIterSetupTokendataCb CDecl Alias "prefixIterSetupTokendataCb" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As Const UByte Ptr, ByVal arg4 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6623
    Dim local0 As c2fb_TokendataSetupCtx Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = CPtr(c2fb_TokendataSetupCtx Ptr, arg1)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    If arg3 Then
        c2fb_temp_0 = CPtr(Long Ptr, @(local0->nTermByte))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg4 - Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(Long Ptr, @(local0->iTermOff))
        c2fb_temp_3 = Cast(c2fb_c_int, CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pT)->terms.n)
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pT)->terms)), Cast(c2fb_c_int, (arg4 - Cast(c2fb_c_int, 1ULL))), CPtr(Const UByte Ptr, (arg3 + Cast(c2fb_c_int, 1ULL))))
    End If
    While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3Fts5PoslistNext64(arg2->base.pData, arg2->base.nData, CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_int64 Ptr, @(local2)))))))
        fts5TokendataIterAppendMap(arg0, CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pT), local0->iTermOff, local0->nTermByte, arg2->base.iRowid, local2)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub
Private Sub prefixIterSetupCb CDecl Alias "prefixIterSetupCb" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As Const UByte Ptr, ByVal arg4 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6668
    Dim local0 As c2fb_PrefixSetupCtx Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_i64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_i64 Ptr
    Dim c2fb_temp_9 As c2fb_int64

    local0 = CPtr(c2fb_PrefixSetupCtx Ptr, arg1)
    local1 = local0->nMerge
    If (-Cast(c2fb_c_int, ((arg2->base.nData > Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2->base.iRowid <= local0->iLastRowid)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->doclist.n > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            ' C automatic storage declaration
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_0
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->doclist.n <> 0)))))
                local3 = Cast(c2fb_c_int, (local2 * local1))
                ' C automatic storage declaration
                ' C unused-parameter annotation
                c2fb_temp_2 = Cast(c2fb_c_int, local3)
                local4 = c2fb_temp_2
                While (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, (local3 + local1))))))
                    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, local0->aBuf))[local4].n = Cast(c2fb_c_int, &O0ULL))))) Then
                        fts5BufferSwap(CPtr(c2fb_Fts5Buffer Ptr, @(local0->doclist)), CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, local0->aBuf))[local4])))
                        c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(local0->doclist)))
                        Goto c2fb_flow_2
                    End If
                c2fb_flow_3:
                    c2fb_temp_3 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
                Wend
                c2fb_flow_2:
                If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, (local3 + local1)))))) Then
                    CPtr(c2fb_callback_350, local0->xMerge)(arg0, CPtr(c2fb_Fts5Buffer Ptr, @(local0->doclist)), local1, CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, local0->aBuf))[local3])))
                    c2fb_temp_4 = Cast(c2fb_c_int, local3)
                    local4 = c2fb_temp_4
                    While (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, (local3 + local1))))))
                        c2fb_external_sqlite3Fts5BufferZero(CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, local0->aBuf))[local4])))
                    c2fb_flow_5:
                        c2fb_temp_5 = local4
                        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
                    Wend
                    c2fb_flow_4:
                End If
            c2fb_flow_1:
                c2fb_temp_1 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
            Wend
            c2fb_flow_0:
            c2fb_temp_6 = CPtr(c2fb_i64 Ptr, @(local0->iLastRowid))
            c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_6) = Cast(c2fb_i64, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
        End If
        CPtr(c2fb_callback_351, local0->xAppend)(arg0, Cast(c2fb_uint64, (Cast(c2fb_uint64, arg2->base.iRowid) - Cast(c2fb_uint64, local0->iLastRowid))), arg2, CPtr(c2fb_Fts5Buffer Ptr, @(local0->doclist)))
        c2fb_temp_8 = CPtr(c2fb_i64 Ptr, @(local0->iLastRowid))
        c2fb_temp_9 = Cast(c2fb_int64, arg2->base.iRowid)
        (*c2fb_temp_8) = Cast(c2fb_i64, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_int64, (*c2fb_temp_8))
    End If
    If CPtr(c2fb_TokendataSetupCtx Ptr, local0->pTokendata) Then
        prefixIterSetupTokendataCb(arg0, CPtr(Any Ptr, CPtr(c2fb_TokendataSetupCtx Ptr, local0->pTokendata)), arg2, arg3, arg4)
    End If
End Sub
Function sqlite3Fts5IndexBeginWrite CDecl Alias "sqlite3Fts5IndexBeginWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6812
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_i64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Hash Ptr, arg0->pHash) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5HashNew(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig), CPtr(c2fb_Fts5Hash Ptr Ptr, @(arg0->pHash)), CPtr(c2fb_c_int Ptr, @(arg0->nPendingData))))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 < arg0->iWriteRowid)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 = arg0->iWriteRowid)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->bDelete = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((arg0->nPendingData > CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nHashSize))))) <> 0))))) Then
        fts5IndexFlush(arg0)
    End If
    c2fb_temp_2 = CPtr(c2fb_i64 Ptr, @(arg0->iWriteRowid))
    c2fb_temp_3 = Cast(c2fb_int64, arg2)
    (*c2fb_temp_2) = Cast(c2fb_i64, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_int64, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(Long Ptr, @(arg0->bDelete))
    c2fb_temp_5 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_6 = CPtr(Long Ptr, @(arg0->nPendingRow))
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        (*c2fb_temp_6) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
    End If
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IndexSync CDecl Alias "sqlite3Fts5IndexSync" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6839
    ' C unused-parameter annotation
    fts5IndexFlush(arg0)
    fts5IndexCloseReader(arg0)
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IndexRollback CDecl Alias "sqlite3Fts5IndexRollback" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6852
    fts5IndexCloseReader(arg0)
    fts5IndexDiscardData(arg0)
    fts5StructureInvalidate(arg0)
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IndexReinit CDecl Alias "sqlite3Fts5IndexReinit" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
    Dim sFts As c2fb_Fts5Structure

    fts5StructureInvalidate(arg0)
    fts5IndexDiscardData(arg0)
    c2fb_crt_memset(CPtr(Any Ptr, @sFts), 0, Cast(c2fb_size_t, SizeOf(sFts)))
    If arg0->pConfig->bContentlessDelete <> 0 Then sFts.nOriginCntr = 1

    ' Rowid 1 stores average document lengths in the FTS5 data table.
    fts5DataWrite(arg0, 1, CPtr(Const UByte Ptr, StrPtr(!"")), 0)
    fts5StructureWrite(arg0, @sFts)
    Return fts5IndexReturn(arg0)
End Function
' c2fb body diagnostic [unsupported-assignment-expression] line 6864: sqlite3Fts5IndexReinit: assignment parser stopped at byte 7 (union {     Fts5Structure sFts;     u8 tmpSpace[(                 __builtin_offsetof (                 Fts5Structure    ): {     Fts5Structure sFts;     u8 tmpSpace[(                 __builtin_offsetof (
Function sqlite3Fts5IndexOpen CDecl Alias "sqlite3Fts5IndexOpen" (ByVal arg0 As c2fb_Fts5Config Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5Index Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6889
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Index Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Config_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_Fts5Index Ptr Ptr
    Dim c2fb_temp_13 As c2fb_Fts5Index Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_1 = CPtr(c2fb_Fts5Index Ptr Ptr, @((*arg2)))
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Index Ptr, CPtr(c2fb_Fts5Index Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Index))))))
    local1 = c2fb_temp_0
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5Index Ptr, c2fb_temp_0)
    (*c2fb_temp_1) = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = CPtr(c2fb_Fts5Config_ Ptr Ptr, @(local1->pConfig))
        c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5Config Ptr, arg0)
        (*c2fb_temp_3) = CPtr(c2fb_Fts5Config_ Ptr, c2fb_temp_4)
        c2fb_temp_4 = CPtr(c2fb_Fts5Config Ptr, (*c2fb_temp_3))
        c2fb_temp_5 = CPtr(Long Ptr, @(local1->nWorkUnit))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 64ULL))
        (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(ZString Ptr Ptr, @(local1->zDataTbl))
        c2fb_temp_8 = CPtr(ZString Ptr, c2fb_external_sqlite3Fts5Mprintf(CPtr(c2fb_c_int Ptr, @(local0)), StrPtr(!"%s_data"), arg0->zName))
        (*c2fb_temp_7) = c2fb_temp_8
        If (-Cast(c2fb_c_int, (((local1->zDataTbl <> 0) AndAlso (arg1 <> 0))))) Then
            c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5CreateTable(arg0, StrPtr(!"data"), StrPtr(!"id INTEGER PRIMARY KEY, block BLOB"), Cast(c2fb_c_int, &O0ULL), arg3))
            local0 = c2fb_temp_9
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5CreateTable(arg0, StrPtr(!"idx"), StrPtr(!"segid, term, pgno, PRIMARY KEY(segid, term)"), Cast(c2fb_c_int, 1ULL), arg3))
                local0 = c2fb_temp_10
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_11 = Cast(c2fb_c_int, sqlite3Fts5IndexReinit(local1))
                local0 = c2fb_temp_11
            End If
        End If
    End If
    ' C unused-parameter annotation
    If local0 Then
        sqlite3Fts5IndexClose(local1)
        c2fb_temp_12 = CPtr(c2fb_Fts5Index Ptr Ptr, @((*arg2)))
        c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5Index Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_12) = c2fb_temp_13
    End If
    Return local0
End Function
Function sqlite3Fts5IndexClose CDecl Alias "sqlite3Fts5IndexClose" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6930
    Dim local0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0 Then
        ' C unused-parameter annotation
        fts5StructureInvalidate(arg0)
        sqlite3_finalize(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pWriter)))
        sqlite3_finalize(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleter)))
        sqlite3_finalize(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxWriter)))
        sqlite3_finalize(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxDeleter)))
        sqlite3_finalize(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxSelect)))
        sqlite3_finalize(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxNextSelect)))
        sqlite3_finalize(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDataVersion)))
        sqlite3_finalize(CPtr(Any Ptr, CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDeleteFromIdx)))
        c2fb_external_sqlite3Fts5HashFree(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash))
        sqlite3_free(CPtr(Any Ptr, arg0->zDataTbl))
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
    Return local0
End Function
Function sqlite3Fts5IndexCharlenToBytelen CDecl Alias "sqlite3Fts5IndexCharlenToBytelen" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6955
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < arg2))))
        If (-Cast(c2fb_c_int, ((local0 >= arg1)))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, Cast(UByte, CPtr(Const Byte Ptr, arg0)[c2fb_temp_2])) >= Cast(c2fb_c_int, &Hc0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local0 >= arg1)))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            While (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local0]) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL)))))
                c2fb_temp_3 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
                If (-Cast(c2fb_c_int, ((local0 >= arg1)))) Then
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL))) = arg2)))) Then
                        Goto c2fb_flow_2
                    End If
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Function fts5IndexCharlen CDecl Alias "fts5IndexCharlen" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6982
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    While (-Cast(c2fb_c_int, ((local1 < arg1))))
        c2fb_temp_0 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, Cast(UByte, CPtr(Const Byte Ptr, arg0)[c2fb_temp_0])) >= Cast(c2fb_c_int, &Hc0ULL))))) Then
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg0)[local1]) And Cast(c2fb_c_int, &Hc0ULL)))) = Cast(c2fb_c_int, &H80ULL))))) <> 0)))))
                c2fb_temp_1 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        End If
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local0
End Function
Function sqlite3Fts5IndexWrite CDecl Alias "sqlite3Fts5IndexWrite" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7004
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Config Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5HashWrite(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash), arg0->iWriteRowid, arg1, arg2, Cast(c2fb_c_int, 48), arg3, arg4))
    local1 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < local2->nPrefix)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        local3 = local2->aPrefix[local0]
        local4 = sqlite3Fts5IndexCharlenToBytelen(arg3, arg4, local3)
        If local4 Then
            c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts5HashWrite(CPtr(c2fb_Fts5Hash Ptr, arg0->pHash), arg0->iWriteRowid, arg1, arg2, Cast(Byte, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 48) + local0)) + Cast(c2fb_c_int, 1ULL))))), arg3, local4))
            local1 = c2fb_temp_3
        End If
    c2fb_flow_1:
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function
Private Function fts5IsTokendataPrefix CDecl Alias "fts5IsTokendataPrefix" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7042
    Return ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->n >= arg2)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, arg0->p), CPtr(Const Any Ptr, arg1), arg2))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->n = arg2)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->p[arg2]) = Cast(c2fb_c_int, &H00ULL))))) <> 0)))))) <> 0))))))
End Function
Private Sub fts5SegIterSetEOF CDecl Alias "fts5SegIterSetEOF" (ByVal arg0 As c2fb_Fts5SegIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7057
    Dim c2fb_temp_0 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Data Ptr

    fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, arg0->pLeaf))
    c2fb_temp_0 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(arg0->pLeaf))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_1)
    c2fb_temp_1 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_0))
End Sub
Private Sub fts5IterClose CDecl Alias "fts5IterClose" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7062
    Dim local0 As c2fb_Fts5Iter Ptr
    Dim local1 As c2fb_Fts5Index Ptr

    If arg0 Then
        local0 = CPtr(c2fb_Fts5Iter Ptr, arg0)
        local1 = CPtr(c2fb_Fts5Index Ptr, local0->pIndex)
        fts5TokendataIterDelete(CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pTokenDataIter))
        fts5MultiIterFree(local0)
        fts5IndexCloseReader(local1)
    End If
End Sub
Private Sub fts5IterSetOutputsTokendata CDecl Alias "fts5IterSetOutputsTokendata" (ByVal arg0 As c2fb_Fts5Iter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7115
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local5 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_9 As Const UByte Ptr
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_u8 Ptr
    Dim c2fb_temp_15 As UByte
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_u8 Ptr
    Dim c2fb_temp_17 As UByte
    Dim c2fb_temp_18 As c2fb_i64 Ptr
    Dim c2fb_temp_19 As c2fb_int64
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_int64
    Dim c2fb_temp_20 As c2fb_Fts5PoslistReader_ Ptr Ptr
    Dim c2fb_temp_21 As c2fb_Fts5PoslistReader Ptr
    Dim c2fb_temp_22 As Long Ptr Ptr
    Dim c2fb_temp_23 As c2fb_c_int Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim local10 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_26 As Long Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As Const UByte Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_Fts5PoslistReader Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim local11 As c2fb_int64
    Dim local12 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_33 As Long Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_Fts5TokenDataMap_ Ptr Ptr
    Dim c2fb_temp_36 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_37 As c2fb_i64 Ptr
    Dim c2fb_temp_38 As c2fb_int64
    Dim c2fb_temp_39 As Long Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim local13 As c2fb_int64
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim local14 As c2fb_Fts5PoslistReader Ptr
    Dim c2fb_temp_44 As c2fb_int64
    Dim c2fb_temp_45 As c2fb_c_int
    Dim c2fb_temp_46 As c2fb_i64 Ptr
    Dim c2fb_temp_47 As c2fb_int64
    Dim c2fb_temp_48 As Long Ptr
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As c2fb_i64 Ptr
    Dim c2fb_temp_51 As c2fb_int64
    Dim c2fb_temp_52 As c2fb_i64 Ptr
    Dim c2fb_temp_53 As c2fb_int64
    Dim c2fb_temp_54 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_55 As Const UByte Ptr
    Dim c2fb_temp_56 As Long Ptr
    Dim c2fb_temp_57 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))) - (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL))))))))))
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = CPtr(c2fb_Fts5TokenDataIter Ptr, arg0->pTokenDataIter)
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->base.nData))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg0->base.pData))
    c2fb_temp_3 = CPtr(Const UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_3)
    c2fb_temp_3 = CPtr(Const UByte Ptr, (*c2fb_temp_2))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local0) < local4->nIter))))
        local5 = CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(local4)))[local0]
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local5->base.bEof) = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local5->base.iRowid < local2)))) <> 0))))) Then
                c2fb_temp_6 = Cast(c2fb_int64, local5->base.iRowid)
                local2 = c2fb_temp_6
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local1 = c2fb_temp_7
                c2fb_temp_8 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg0->base.pData))
                c2fb_temp_9 = local5->base.pData
                (*c2fb_temp_8) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_9)
                c2fb_temp_9 = CPtr(Const UByte Ptr, (*c2fb_temp_8))
                c2fb_temp_10 = CPtr(Long Ptr, @(arg0->base.nData))
                c2fb_temp_11 = Cast(c2fb_c_int, local5->base.nData)
                (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
                c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                c2fb_temp_12 = Cast(c2fb_c_int, local0)
                local3 = c2fb_temp_12
            Else
                If (-Cast(c2fb_c_int, ((local5->base.iRowid = local2)))) Then
                    c2fb_temp_13 = local1
                    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
                End If
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_5 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_14 = CPtr(c2fb_u8 Ptr, @(arg0->base.bEof))
        c2fb_temp_15 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_14) = Cast(c2fb_u8, c2fb_temp_15)
        c2fb_temp_15 = Cast(UByte, (*c2fb_temp_14))
    Else
        local6 = CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)->pConfig)->eDetail
        c2fb_temp_16 = CPtr(c2fb_u8 Ptr, @(arg0->base.bEof))
        c2fb_temp_17 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_16) = Cast(c2fb_u8, c2fb_temp_17)
        c2fb_temp_17 = Cast(UByte, (*c2fb_temp_16))
        c2fb_temp_18 = CPtr(c2fb_i64 Ptr, @(arg0->base.iRowid))
        c2fb_temp_19 = Cast(c2fb_int64, local2)
        (*c2fb_temp_18) = Cast(c2fb_i64, c2fb_temp_19)
        c2fb_temp_19 = Cast(c2fb_int64, (*c2fb_temp_18))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            fts5TokendataIterAppendMap(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex), local4, local3, Cast(c2fb_c_int, &O0ULL), local2, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local6 <> Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                local7 = Cast(c2fb_c_int, &O0ULL)
                local8 = Cast(c2fb_c_int, &O0ULL)
                local9 = Cast(c2fb_c_int, &O0ULL)
                If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5PoslistReader Ptr, local4->aPoslistReader) = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_20 = CPtr(c2fb_Fts5PoslistReader_ Ptr Ptr, @(local4->aPoslistReader))
                    c2fb_temp_21 = CPtr(_c2fb_record_c2fb_Fts5PoslistReader Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)->rc)), Cast(c2fb_uint64, (Cast(c2fb_uint64, local4->nIter) * (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistReader))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))))))))))
                    (*c2fb_temp_20) = CPtr(c2fb_Fts5PoslistReader_ Ptr, c2fb_temp_21)
                    c2fb_temp_21 = CPtr(c2fb_Fts5PoslistReader Ptr, (*c2fb_temp_20))
                    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5PoslistReader Ptr, local4->aPoslistReader) = Cast(c2fb_c_int, &O0ULL))))) Then
                        Return
                    End If
                    c2fb_temp_22 = CPtr(Long Ptr Ptr, @(local4->aPoslistToIter))
                    c2fb_temp_23 = CPtr(c2fb_c_int Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, local4->aPoslistReader))[local4->nIter])))
                    (*c2fb_temp_22) = CPtr(Long Ptr, c2fb_temp_23)
                    c2fb_temp_23 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_22))
                End If
                c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local0 = c2fb_temp_24
                While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local0) < local4->nIter))))
                    local10 = CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(local4)))[local0]
                    If (-Cast(c2fb_c_int, ((local2 = local10->base.iRowid)))) Then
                        c2fb_temp_26 = CPtr(Long Ptr, @(local4->aPoslistToIter[local7]))
                        c2fb_temp_27 = Cast(c2fb_c_int, local0)
                        (*c2fb_temp_26) = Cast(Long, c2fb_temp_27)
                        c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
                        c2fb_temp_29 = local10->base.pData
                        c2fb_temp_30 = local10->base.nData
                        c2fb_temp_28 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
                        c2fb_temp_31 = CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, local4->aPoslistReader))[c2fb_temp_28]))
                        c2fb_external_sqlite3Fts5PoslistReaderInit(c2fb_temp_29, c2fb_temp_30, c2fb_temp_31)
                        c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local8 + local10->base.nData)))
                        local8 = c2fb_temp_32
                    End If
                c2fb_flow_3:
                    c2fb_temp_25 = local0
                    local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_25 + 1)))
                Wend
                c2fb_flow_2:
                If (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))->n)) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, (local1 * Cast(c2fb_c_int, 10ULL))))))))) <= Cast(c2fb_c_uint, ((CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))->nSpace)))))), Cast(c2fb_c_int, &O0ULL), c2fb_external_sqlite3Fts5BufferSize((CPtr(c2fb_c_int Ptr, @(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)->rc))), (CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist))), Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, (local1 * Cast(c2fb_c_int, 10ULL)))))) + (CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)))->n))))) Then
                    Return
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4->nMapAlloc < (Cast(c2fb_int64, (local4->nMap + Cast(c2fb_int64, local8)))))))) <> 0))))) Then
                    local11 = Cast(c2fb_int64, ((Cast(c2fb_int64, (local4->nMapAlloc + Cast(c2fb_int64, local8)))) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))
                    local12 = CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, local4->aMap)), Cast(c2fb_uint64, (Cast(c2fb_uint64, local11) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5TokenDataMap))))))))
                    If (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_33 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)->rc))
                        c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                        (*c2fb_temp_33) = Cast(Long, c2fb_temp_34)
                        c2fb_temp_34 = Cast(c2fb_c_int, (*c2fb_temp_33))
                        Return
                    End If
                    c2fb_temp_35 = CPtr(c2fb_Fts5TokenDataMap_ Ptr Ptr, @(local4->aMap))
                    c2fb_temp_36 = CPtr(_c2fb_record_c2fb_Fts5TokenDataMap Ptr, local12)
                    (*c2fb_temp_35) = CPtr(c2fb_Fts5TokenDataMap_ Ptr, c2fb_temp_36)
                    c2fb_temp_36 = CPtr(c2fb_Fts5TokenDataMap Ptr, (*c2fb_temp_35))
                    c2fb_temp_37 = CPtr(c2fb_i64 Ptr, @(local4->nMapAlloc))
                    c2fb_temp_38 = Cast(c2fb_int64, local11)
                    (*c2fb_temp_37) = Cast(c2fb_i64, c2fb_temp_38)
                    c2fb_temp_38 = Cast(c2fb_int64, (*c2fb_temp_37))
                End If
                c2fb_temp_39 = CPtr(Long Ptr, @(arg0->poslist.n))
                c2fb_temp_40 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_39) = Cast(Long, c2fb_temp_40)
                c2fb_temp_40 = Cast(c2fb_c_int, (*c2fb_temp_39))
                While Cast(c2fb_c_int, 1ULL)
                    local13 = (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL)))))))
                    c2fb_temp_41 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local3 = c2fb_temp_41
                    c2fb_temp_42 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local0 = c2fb_temp_42
                    While (-Cast(c2fb_c_int, ((local0 < local7))))
                        local14 = CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, local4->aPoslistReader))[local0]))
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local14->bEof) = Cast(c2fb_c_int, &O0ULL))))) Then
                            If (-Cast(c2fb_c_int, ((local14->iPos < local13)))) Then
                                c2fb_temp_44 = Cast(c2fb_int64, local14->iPos)
                                local13 = c2fb_temp_44
                                c2fb_temp_45 = Cast(c2fb_c_int, local0)
                                local3 = c2fb_temp_45
                            End If
                        End If
                    c2fb_flow_7:
                        c2fb_temp_43 = local0
                        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_43 + 1)))
                    Wend
                    c2fb_flow_6:
                    If (-Cast(c2fb_c_int, ((local13 = (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_uint, &HffffffffULL)) Or (Cast(c2fb_int64, ((Cast(c2fb_int64, Cast(c2fb_c_int, &H7fffffffULL))) Shl Cast(c2fb_c_int, 32ULL))))))))))) Then
                        Goto c2fb_flow_4
                    End If
                    c2fb_external_sqlite3Fts5PoslistSafeAppend(CPtr(c2fb_Fts5Buffer Ptr, @(arg0->poslist)), CPtr(c2fb_int64 Ptr, @(local9)), local13)
                    c2fb_external_sqlite3Fts5PoslistReaderNext(CPtr(c2fb_Fts5PoslistReader Ptr, @(CPtr(c2fb_Fts5PoslistReader Ptr, CPtr(c2fb_Fts5PoslistReader Ptr, local4->aPoslistReader))[local3])))
                    If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_46 = CPtr(c2fb_i64 Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, local4->aMap))[local4->nMap].iPos))
                        c2fb_temp_47 = Cast(c2fb_int64, local13)
                        (*c2fb_temp_46) = Cast(c2fb_i64, c2fb_temp_47)
                        c2fb_temp_47 = Cast(c2fb_int64, (*c2fb_temp_46))
                        c2fb_temp_48 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, local4->aMap))[local4->nMap].iIter))
                        c2fb_temp_49 = Cast(c2fb_c_int, local4->aPoslistToIter[local3])
                        (*c2fb_temp_48) = Cast(Long, c2fb_temp_49)
                        c2fb_temp_49 = Cast(c2fb_c_int, (*c2fb_temp_48))
                        c2fb_temp_50 = CPtr(c2fb_i64 Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, local4->aMap))[local4->nMap].iRowid))
                        c2fb_temp_51 = Cast(c2fb_int64, local2)
                        (*c2fb_temp_50) = Cast(c2fb_i64, c2fb_temp_51)
                        c2fb_temp_51 = Cast(c2fb_int64, (*c2fb_temp_50))
                        c2fb_temp_52 = CPtr(c2fb_i64 Ptr, @(local4->nMap))
                        c2fb_temp_53 = Cast(c2fb_int64, (*c2fb_temp_52))
                        (*c2fb_temp_52) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_53 + 1)))
                    End If
                c2fb_flow_5:
                Wend
                c2fb_flow_4:
                c2fb_temp_54 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg0->base.pData))
                c2fb_temp_55 = CPtr(Const UByte Ptr, arg0->poslist.p)
                (*c2fb_temp_54) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_55)
                c2fb_temp_55 = CPtr(Const UByte Ptr, (*c2fb_temp_54))
                c2fb_temp_56 = CPtr(Long Ptr, @(arg0->base.nData))
                c2fb_temp_57 = Cast(c2fb_c_int, arg0->poslist.n)
                (*c2fb_temp_56) = Cast(Long, c2fb_temp_57)
                c2fb_temp_57 = Cast(c2fb_c_int, (*c2fb_temp_56))
            End If
        End If
    End If
End Sub
Private Sub fts5TokendataIterNext CDecl Alias "fts5TokendataIterNext" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7241
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5TokenDataIter Ptr
    Dim local2 As c2fb_Fts5Index Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_Fts5Iter Ptr

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5TokenDataIter Ptr, arg0->pTokenDataIter)
    local2 = CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local0) < local1->nIter))))
        local3 = CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(local1)))[local0]
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3->base.bEof) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3->base.iRowid = arg0->base.iRowid)))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3->base.iRowid < arg2)))) <> 0)))))) <> 0)))))) <> 0))))) Then
            fts5MultiIterNext(local2, local3, arg1, arg2)
            While (-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3->base.bEof) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3->base.iRowid < arg2)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                fts5MultiIterNext(local2, local3, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local2->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        fts5IterSetOutputsTokendata(arg0)
    End If
End Sub
Private Sub fts5TokendataSetTermIfEof CDecl Alias "fts5TokendataSetTermIfEof" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7270
    If (-Cast(c2fb_c_int, (((arg0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[Cast(c2fb_c_int, &O0ULL)].pLeaf = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)->rc)), @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(arg0)))[Cast(c2fb_c_int, &O0ULL)].term), arg1->n, CPtr(Const UByte Ptr, arg1->p))
    End If
End Sub
Function sqlite3Fts5IndexQuery CDecl Alias "sqlite3Fts5IndexQuery" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_Fts5Colset Ptr, ByVal arg5 As c2fb_Fts5IndexIter Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7422
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_Fts5Iter Ptr
    Dim local2 As c2fb_Fts5Buffer
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_u8 Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As c2fb_Fts5Iter Ptr
    Dim local8 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_8 As c2fb_u8 Ptr
    Dim c2fb_temp_9 As UByte
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_10 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_11 As c2fb_Fts5IndexIter Ptr Ptr
    Dim c2fb_temp_12 As c2fb_Fts5IndexIter Ptr

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
#ifdef SQLITE_DEBUG
    If (arg3 And &H0008) <> 0 AndAlso arg3 <> &H0008 Then _
        sqlite3DebugAssert(StrPtr(!"(flags & FTS5INDEX_QUERY_SCAN)==0 || flags==FTS5INDEX_QUERY_SCAN"))
#endif
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3Fts5BufferSize(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
#ifdef SQLITE_DEBUG
        If local2.p = 0 Then sqlite3DebugAssert(StrPtr(!"buf.p!=0"))
#endif
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = Cast(c2fb_c_int, &O0ULL)
        local5 = local0->bTokendata
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local2.p[Cast(c2fb_c_int, 1ULL)]))), CPtr(Const Any Ptr, arg1), arg2))
        End If
        If Cast(c2fb_c_int, (arg3 And (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H0080ULL) Or Cast(c2fb_c_int, &H0008ULL)))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local5 = c2fb_temp_1
        End If
#ifdef SQLITE_DEBUG
        If local0->bPrefixIndex = 0 OrElse (arg3 And &H0004) <> 0 Then
            If (arg3 And &H0001) = 0 Then _
                sqlite3DebugAssert(StrPtr(!"flags & FTS5INDEX_QUERY_PREFIX"))
            local3 = 1 + local0->nPrefix
        Else
#endif
        If Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0001ULL))) Then
            local6 = fts5IndexCharlen(arg1, arg2)
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local3 = c2fb_temp_2
            While (-Cast(c2fb_c_int, ((local3 <= local0->nPrefix))))
                local7 = local0->aPrefix[Cast(c2fb_c_int, (local3 - Cast(c2fb_c_int, 1ULL)))]
                If (-Cast(c2fb_c_int, ((local7 = local6)))) Then
                    Goto c2fb_flow_0
                End If
                If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL))))))) Then
                    c2fb_temp_4 = Cast(c2fb_c_int, local3)
                    local4 = c2fb_temp_4
                End If
            c2fb_flow_1:
                c2fb_temp_3 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            Wend
            c2fb_flow_0:
        End If
#ifdef SQLITE_DEBUG
        End If
#endif
        If (-Cast(c2fb_c_int, (((local5 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_5 = CPtr(c2fb_u8 Ptr, @(local2.p[Cast(c2fb_c_int, &O0ULL)]))
            c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, 48))
            (*c2fb_temp_5) = Cast(c2fb_u8, c2fb_temp_6)
            c2fb_temp_6 = Cast(UByte, (*c2fb_temp_5))
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, CPtr(c2fb_Fts5Iter Ptr, fts5SetupTokendataIter(arg0, CPtr(Const UByte Ptr, local2.p), Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))), arg4)))
            local1 = c2fb_temp_7
        Else
            If (-Cast(c2fb_c_int, ((local3 <= local0->nPrefix)))) Then
                local8 = CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(arg0))
                c2fb_temp_8 = CPtr(c2fb_u8 Ptr, @(local2.p[Cast(c2fb_c_int, &O0ULL)]))
                c2fb_temp_9 = Cast(UByte, Cast(UByte, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 48) + local3)))))
                (*c2fb_temp_8) = Cast(c2fb_u8, c2fb_temp_9)
                c2fb_temp_9 = Cast(UByte, (*c2fb_temp_8))
                If local8 Then
                    fts5MultiIterNew(arg0, local8, Cast(c2fb_c_int, (arg3 Or Cast(c2fb_c_int, &H0010ULL))), arg4, CPtr(Const UByte Ptr, local2.p), Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_Fts5Iter Ptr Ptr, @(local1)))
                    fts5StructureRelease(local8)
                End If
            Else
                local9 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0002ULL)))) <> Cast(c2fb_c_int, &O0ULL)))))
                fts5SetupPrefixIter(arg0, local9, local4, local2.p, Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))), arg4, CPtr(c2fb_Fts5Iter Ptr Ptr, @(local1)))
                If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
#ifdef SQLITE_DEBUG
                    If arg0->rc = SQLITE_OK Then _
                        sqlite3DebugAssert(StrPtr(!"pRet==0 || p->rc!=SQLITE_OK"))
#endif
                    ' C unused-parameter annotation
                Else
#ifdef SQLITE_DEBUG
                    If local1->pColset <> 0 Then _
                        sqlite3DebugAssert(StrPtr(!"pRet->pColset==0"))
#endif
                    ' C unused-parameter annotation
                    fts5IterSetOutputCb(CPtr(c2fb_c_int Ptr, @(arg0->rc)), local1)
                    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                        local10 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local1)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, local1->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
                        If CPtr(c2fb_Fts5Data Ptr, local10->pLeaf) Then
                            CPtr(c2fb_callback_349, local1->xSetOutputs)(local1, local10)
                        End If
                    End If
                End If
            End If
        End If
        If arg0->rc Then
            fts5IterClose(CPtr(c2fb_Fts5IndexIter Ptr, local1))
            c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_10
            fts5IndexCloseReader(arg0)
        End If
        c2fb_temp_11 = CPtr(c2fb_Fts5IndexIter Ptr Ptr, @((*arg5)))
        c2fb_temp_12 = CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, CPtr(c2fb_Fts5IndexIter Ptr, local1))
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local2)))
    End If
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IterNext CDecl Alias "sqlite3Fts5IterNext" (ByVal arg0 As c2fb_Fts5IndexIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7524
    Dim local0 As c2fb_Fts5Iter Ptr

    local0 = CPtr(c2fb_Fts5Iter Ptr, arg0)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0->nSeg = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        fts5TokendataIterNext(local0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    Else
        fts5MultiIterNext(CPtr(c2fb_Fts5Index Ptr, local0->pIndex), local0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    End If
    Return fts5IndexReturn(CPtr(c2fb_Fts5Index Ptr, local0->pIndex))
End Function
Function sqlite3Fts5IterNextScan CDecl Alias "sqlite3Fts5IterNextScan" (ByVal arg0 As c2fb_Fts5IndexIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7539
    Dim local0 As c2fb_Fts5Iter Ptr
    Dim local1 As c2fb_Fts5Index Ptr
    Dim local2 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_2 As c2fb_u8 Ptr
    Dim c2fb_temp_3 As UByte

    local0 = CPtr(c2fb_Fts5Iter Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Index Ptr, local0->pIndex)
    ' C unused-parameter annotation
    fts5MultiIterNext(local1, local0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    If (-Cast(c2fb_c_int, ((local1->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local2 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local0)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, local0->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst]))
        If (-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Data Ptr, local2->pLeaf) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->term.p[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 48))))) <> 0))))) Then
            fts5DataRelease(CPtr(c2fb_Fts5Data Ptr, local2->pLeaf))
            c2fb_temp_0 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(local2->pLeaf))
            c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_0) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_1)
            c2fb_temp_1 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_0))
            c2fb_temp_2 = CPtr(c2fb_u8 Ptr, @(local0->base.bEof))
            c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_2) = Cast(c2fb_u8, c2fb_temp_3)
            c2fb_temp_3 = Cast(UByte, (*c2fb_temp_2))
        End If
    End If
    Return fts5IndexReturn(CPtr(c2fb_Fts5Index Ptr, local0->pIndex))
End Function
Function sqlite3Fts5IterNextFrom CDecl Alias "sqlite3Fts5IterNextFrom" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7563
    Dim local0 As c2fb_Fts5Iter Ptr

    local0 = CPtr(c2fb_Fts5Iter Ptr, arg0)
    If (-Cast(c2fb_c_int, ((local0->nSeg = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        fts5TokendataIterNext(local0, Cast(c2fb_c_int, 1ULL), arg1)
    Else
        fts5MultiIterNextFrom(CPtr(c2fb_Fts5Index Ptr, local0->pIndex), local0, arg1)
    End If
    Return fts5IndexReturn(CPtr(c2fb_Fts5Index Ptr, local0->pIndex))
End Function
Function sqlite3Fts5IterTerm CDecl Alias "sqlite3Fts5IterTerm" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As c2fb_c_int Ptr) As Const ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7577
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, fts5MultiIterTerm(CPtr(c2fb_Fts5Iter Ptr, arg0), CPtr(c2fb_c_int Ptr, @(local0)))))
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 - Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_0) = c2fb_temp_1
    Return CPtr(Const ZString Ptr, (IIf(local1, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local1)[Cast(c2fb_c_int, 1ULL)])), CPtr(Byte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
End Function
Function sqlite3Fts5IterToken CDecl Alias "sqlite3Fts5IterToken" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7638
    Dim local0 As c2fb_Fts5Iter Ptr
    Dim local1 As c2fb_Fts5TokenDataIter Ptr
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_Fts5TokenDataMap Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local8 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_8 As Const ZString Ptr Ptr
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local9 As c2fb_Fts5TokenDataMap Ptr
    Dim c2fb_temp_12 As Const ZString Ptr Ptr
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Iter Ptr, arg0)
    local1 = CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pTokenDataIter)
    local2 = Cast(c2fb_int64, ((Cast(c2fb_int64, ((Cast(c2fb_int64, arg4)) Shl Cast(c2fb_c_int, 32ULL)))) + Cast(c2fb_int64, arg5)))
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        local7 = fts5SetupPrefixIterTokendata(local0, arg1, arg2)
        If (-Cast(c2fb_c_int, ((local7 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local7
        End If
        c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pTokenDataIter))
        local1 = c2fb_temp_0
    End If
    c2fb_temp_1 = Cast(c2fb_c_int, local1->nMap)
    local5 = c2fb_temp_1
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5TokenDataMap Ptr, CPtr(c2fb_Fts5TokenDataMap Ptr, local1->aMap))
    local3 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local5 > local4))))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local4 + local5))) \ Cast(c2fb_c_int, 2ULL))))
        local6 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local6].iRowid < arg3)))) Then
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL))))
            local4 = c2fb_temp_4
        Else
            If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local6].iRowid > arg3)))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, local6)
                local5 = c2fb_temp_5
            Else
                If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local6].iPos < local2)))) Then
                    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local6].iPos < Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                        Goto c2fb_flow_0
                    End If
                    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL))))
                    local4 = c2fb_temp_6
                Else
                    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local6].iPos > local2)))) Then
                        c2fb_temp_7 = Cast(c2fb_c_int, local6)
                        local5 = c2fb_temp_7
                    Else
                        Goto c2fb_flow_0
                    End If
                End If
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local5 > local4)))) Then
        If (-Cast(c2fb_c_int, ((local0->nSeg = Cast(c2fb_c_int, &O0ULL))))) Then
            local8 = CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(local1)))[CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local6].iIter]
            c2fb_temp_8 = CPtr(Const ZString Ptr Ptr, @((*arg6)))
            c2fb_temp_9 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, CPtr(Const ZString Ptr, CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local8)))[Cast(c2fb_c_int, &O0ULL)].term.p)) + Cast(c2fb_c_int, 1ULL)))
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg7)))
            c2fb_temp_11 = Cast(c2fb_c_int, (CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local8)))[Cast(c2fb_c_int, &O0ULL)].term.n - Cast(c2fb_c_int, 1ULL)))
            (*c2fb_temp_10) = c2fb_temp_11
        Else
            local9 = CPtr(c2fb_Fts5TokenDataMap Ptr, @(CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local6]))
            c2fb_temp_12 = CPtr(Const ZString Ptr Ptr, @((*arg6)))
            c2fb_temp_13 = CPtr(Const ZString Ptr, CPtr(UByte Ptr, @(local1->terms.p[local9->iIter])))
            (*c2fb_temp_12) = c2fb_temp_13
            c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @((*arg7)))
            c2fb_temp_15 = Cast(c2fb_c_int, CPtr(c2fb_Fts5TokenDataMap Ptr, local3)[local6].nByte)
            (*c2fb_temp_14) = c2fb_temp_15
        End If
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Sub sqlite3Fts5IndexIterClearTokendata CDecl Alias "sqlite3Fts5IndexIterClearTokendata" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7704
    Dim local0 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    local0 = CPtr(c2fb_Fts5Iter Ptr, arg0)
    If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso (CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pTokenDataIter) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->nSeg = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, CPtr(c2fb_Fts5Index Ptr, local0->pIndex)->pConfig)->eDetail <> Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pTokenDataIter)->nMap))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    End If
End Sub
Sub sqlite3Fts5IterClose CDecl Alias "sqlite3Fts5IterClose" (ByVal arg0 As c2fb_Fts5IndexIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7759
    Dim local0 As c2fb_Fts5Index Ptr

    If arg0 Then
        local0 = CPtr(c2fb_Fts5Index Ptr, (CPtr(c2fb_Fts5Iter Ptr, arg0))->pIndex)
        fts5IterClose(arg0)
        fts5IndexReturn(local0)
    End If
End Sub
Function sqlite3Fts5IndexGetAverages CDecl Alias "sqlite3Fts5IndexGetAverages" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7773
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_Fts5Data Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->nCol
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_int64))) * Cast(c2fb_uint64, local0)))))
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, Cast(c2fb_c_int, 1ULL))))
    local1 = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1->nn <> 0))))) Then
        local2 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1->p[local2]))), CPtr(c2fb_uint64 Ptr, arg1))))))
        local2 = c2fb_temp_4
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_5
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 < local1->nn)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 < local0)))) <> 0)))))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local1->p[local2]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(arg2[local3]))))))))
            local2 = c2fb_temp_7
        c2fb_flow_1:
            c2fb_temp_6 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        Wend
        c2fb_flow_0:
    End If
    fts5DataRelease(local1)
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IndexSetAverages CDecl Alias "sqlite3Fts5IndexSetAverages" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7797
    ' C unused-parameter annotation
    fts5DataWrite(arg0, Cast(c2fb_c_int, 1ULL), arg1, arg2)
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IndexReads CDecl Alias "sqlite3Fts5IndexReads" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7807
    Return arg0->nRead
End Function
Function sqlite3Fts5IndexSetCookie CDecl Alias "sqlite3Fts5IndexSetCookie" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7818
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Config Ptr
    Dim local2(0 To 3) As UByte
    Dim local3 As c2fb_sqlite3_blob Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    local1 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    ' C automatic array storage
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_external_sqlite3Fts5Put32(CPtr(UByte Ptr, (@local2(0))), arg1)
    c2fb_temp_0 = Cast(c2fb_c_int, sqlite3_blob_open(CPtr(Any Ptr, CPtr(sqlite3 Ptr, local1->db)), CPtr(Const ZString Ptr, local1->zDb), CPtr(Const ZString Ptr, arg0->zDataTbl), StrPtr(!"block"), Cast(c2fb_c_int, 10ULL), Cast(c2fb_c_int, 1ULL), CPtr(Any Ptr Ptr, CPtr(c2fb_sqlite3_blob Ptr Ptr, @(local3)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_blob_write(CPtr(Any Ptr, local3), CPtr(Const Any Ptr, CPtr(UByte Ptr, (@local2(0)))), Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, &O0ULL))
        c2fb_temp_1 = Cast(c2fb_c_int, sqlite3_blob_close(CPtr(Any Ptr, local3)))
        local0 = c2fb_temp_1
    End If
    Return local0
End Function
Function sqlite3Fts5IndexLoadConfig CDecl Alias "sqlite3Fts5IndexLoadConfig" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7838
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(arg0)))
    local0 = c2fb_temp_0
    fts5StructureRelease(local0)
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IndexGetOrigin CDecl Alias "sqlite3Fts5IndexGetOrigin" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7852
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_1 As c2fb_int64 Ptr
    Dim c2fb_temp_2 As c2fb_int64

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(arg0)))
    local0 = c2fb_temp_0
    If local0 Then
        c2fb_temp_1 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_2 = Cast(c2fb_int64, local0->nOriginCntr)
        (*c2fb_temp_1) = c2fb_temp_2
        fts5StructureRelease(local0)
    End If
    Return fts5IndexReturn(arg0)
End Function
Private Function fts5IndexTombstoneAddToPage CDecl Alias "fts5IndexTombstoneAddToPage" (ByVal arg0 As c2fb_Fts5Data Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_uint64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7873
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_u8 Ptr
    Dim c2fb_temp_1 As UByte
    Dim local5 As c2fb_c_uint Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local6 As c2fb_uint64 Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->p[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 4ULL))))), Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 8ULL)))
    local1 = (IIf(((-Cast(c2fb_c_int, ((arg0->nn > Cast(c2fb_c_int, 16ULL)))))), (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->nn - Cast(c2fb_c_int, 8ULL)))) \ (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->p[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 4ULL))))), Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 8ULL)))))), Cast(c2fb_c_int, 1ULL)))
    local2 = fts5GetU32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->p[Cast(c2fb_c_int, 4ULL)]))))
    local3 = Cast(c2fb_uint64, ((Cast(c2fb_uint64, (arg3 \ Cast(c2fb_uint64, arg2)))) Mod Cast(c2fb_uint64, local1)))
    local4 = local1
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_uint64, Cast(c2fb_c_uint, &HFFFFFFFFULL)))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 2ULL)
    End If
    If (-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_0 = CPtr(c2fb_u8 Ptr, @(arg0->p[Cast(c2fb_c_int, 1ULL)]))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, &H01ULL))
        (*c2fb_temp_0) = Cast(c2fb_u8, c2fb_temp_1)
        c2fb_temp_1 = Cast(UByte, (*c2fb_temp_0))
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 >= (Cast(c2fb_c_int, (local1 \ Cast(c2fb_c_int, 2ULL)))))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    fts5PutU32(CPtr(UByte Ptr, @(arg0->p[Cast(c2fb_c_int, 4ULL)])), Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 4ULL))))) Then
        local5 = CPtr(c2fb_c_uint Ptr, CPtr(UByte Ptr, @(arg0->p[Cast(c2fb_c_int, 8ULL)])))
        While local5[local3]
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL)))) Mod local1)))
            local3 = c2fb_temp_2
            c2fb_temp_3 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
            If (-Cast(c2fb_c_int, ((c2fb_temp_3 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        fts5PutU32(CPtr(UByte Ptr, CPtr(c2fb_c_uint Ptr, @(local5[local3]))), Cast(c2fb_c_uint, arg3))
    Else
        local6 = CPtr(c2fb_uint64 Ptr, CPtr(UByte Ptr, @(arg0->p[Cast(c2fb_c_int, 8ULL)])))
        While local6[local3]
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL)))) Mod local1)))
            local3 = c2fb_temp_4
            c2fb_temp_5 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 - 1)))
            If (-Cast(c2fb_c_int, ((c2fb_temp_5 = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        fts5PutU64(CPtr(UByte Ptr, CPtr(c2fb_uint64 Ptr, @(local6[local3]))), arg3)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts5IndexTombstoneRehash CDecl Alias "fts5IndexTombstoneRehash" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_Fts5Data Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_Fts5Data Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7927
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_u8 Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local2 As c2fb_Fts5Data Ptr
    Dim local3 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_6 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_8 As c2fb_Fts5Data Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local7 As c2fb_uint64
    Dim local8 As c2fb_c_uint Ptr
    Dim c2fb_temp_11 As c2fb_uint64
    Dim local9 As c2fb_uint64 Ptr
    Dim c2fb_temp_12 As c2fb_uint64
    Dim local10 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_u8 Ptr
    Dim c2fb_temp_15 As UByte

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg5))))
        c2fb_temp_2 = CPtr(c2fb_u8 Ptr, @(CPtr(c2fb_Fts5Data Ptr Ptr, arg6)[local0]->p[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_3 = Cast(UByte, arg4)
        (*c2fb_temp_2) = Cast(c2fb_u8, c2fb_temp_3)
        c2fb_temp_3 = Cast(UByte, (*c2fb_temp_2))
        fts5PutU32(CPtr(UByte Ptr, @(CPtr(c2fb_Fts5Data Ptr Ptr, arg6)[local0]->p[Cast(c2fb_c_int, 4ULL)])), Cast(c2fb_c_int, &O0ULL))
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < arg1->nPgTombstone)))) <> 0)))))
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((arg3 = local0)))) Then
            c2fb_temp_6 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, arg2)
            local2 = c2fb_temp_6
        Else
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (arg1->iSegid + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 16ULL)))))))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local0)))))))))
            local2 = c2fb_temp_7
            c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, c2fb_temp_7)
            local3 = c2fb_temp_8
        End If
        If local2 Then
            local4 = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->p[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 4ULL))))), Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 8ULL)))
            local5 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local2->nn - Cast(c2fb_c_int, 8ULL)))) \ local4))
            ' C automatic storage declaration
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local6 = c2fb_temp_9
            While (-Cast(c2fb_c_int, ((local6 < local5))))
                local7 = Cast(c2fb_c_int, &O0ULL)
                If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 4ULL))))) Then
                    local8 = CPtr(c2fb_c_uint Ptr, CPtr(UByte Ptr, @(local2->p[Cast(c2fb_c_int, 8ULL)])))
                    If local8[local6] Then
                        c2fb_temp_11 = Cast(c2fb_uint64, fts5GetU32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, CPtr(c2fb_c_uint Ptr, @(local8[local6]))))))
                        local7 = c2fb_temp_11
                    End If
                Else
                    local9 = CPtr(c2fb_uint64 Ptr, CPtr(UByte Ptr, @(local2->p[Cast(c2fb_c_int, 8ULL)])))
                    If local9[local6] Then
                        c2fb_temp_12 = Cast(c2fb_uint64, fts5GetU64(CPtr(UByte Ptr, CPtr(c2fb_uint64 Ptr, @(local9[local6])))))
                        local7 = c2fb_temp_12
                    End If
                End If
                If local7 Then
                    local10 = CPtr(c2fb_Fts5Data Ptr Ptr, arg6)[(Cast(c2fb_uint64, (local7 Mod Cast(c2fb_uint64, arg5))))]
                    c2fb_temp_13 = Cast(c2fb_c_int, fts5IndexTombstoneAddToPage(local10, Cast(c2fb_c_int, &O0ULL), arg5, local7))
                    local1 = c2fb_temp_13
                    If local1 Then
                        Goto c2fb_flow_4
                    End If
                End If
            c2fb_flow_5:
                c2fb_temp_10 = local6
                local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 + 1)))
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_14 = CPtr(c2fb_u8 Ptr, @(CPtr(c2fb_Fts5Data Ptr Ptr, arg6)[Cast(c2fb_c_int, &O0ULL)]->p[Cast(c2fb_c_int, 1ULL)]))
                c2fb_temp_15 = Cast(UByte, local2->p[Cast(c2fb_c_int, 1ULL)])
                (*c2fb_temp_14) = Cast(c2fb_u8, c2fb_temp_15)
                c2fb_temp_15 = Cast(UByte, (*c2fb_temp_14))
            End If
        End If
        fts5DataRelease(local3)
    c2fb_flow_3:
        c2fb_temp_5 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_2:
    Return local1
End Function
Private Sub fts5IndexTombstoneRebuild CDecl Alias "fts5IndexTombstoneRebuild" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_Fts5Data Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As c2fb_Fts5Data Ptr Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8006
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim local4 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_Fts5Data Ptr Ptr
    Dim c2fb_temp_7 As c2fb_Fts5Data Ptr Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_int64
    Dim c2fb_temp_10 As c2fb_int64
    Dim local9 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As c2fb_Fts5Data Ptr Ptr
    Dim c2fb_temp_16 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_Fts5Data Ptr Ptr
    Dim c2fb_temp_19 As c2fb_int64
    Dim c2fb_temp_20 As c2fb_c_int Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_Fts5Data Ptr Ptr Ptr
    Dim c2fb_temp_23 As c2fb_Fts5Data Ptr Ptr
    Dim c2fb_temp_24 As c2fb_int64
    Dim c2fb_temp_25 As c2fb_int64

    local0 = Cast(c2fb_c_int, 32ULL)
    local1 = (IIf(((-Cast(c2fb_c_int, (((local0) > (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz - Cast(c2fb_c_int, 8ULL)))) \ arg4)))))))), (local0), (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->pgsz - Cast(c2fb_c_int, 8ULL)))) \ arg4)))))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg1->nPgTombstone = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_int64, local0)
        local2 = c2fb_temp_1
    Else
        If (-Cast(c2fb_c_int, ((arg1->nPgTombstone = Cast(c2fb_c_int, 1ULL))))) Then
            local4 = fts5GetU32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2->p[Cast(c2fb_c_int, 4ULL)]))))
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((local4 > (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local1) \ Cast(c2fb_c_uint, Cast(c2fb_c_int, 4ULL))))))))) Then
                c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_2
            Else
                c2fb_temp_3 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))
                local3 = c2fb_temp_3
                c2fb_temp_4 = Cast(c2fb_int64, (IIf(((-Cast(c2fb_c_int, (((Cast(c2fb_int64, (Cast(c2fb_int64, local4) * Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL))))) > Cast(c2fb_int64, (local0))))))), (Cast(c2fb_int64, (Cast(c2fb_int64, local4) * Cast(c2fb_int64, Cast(c2fb_c_int, 4ULL))))), Cast(c2fb_int64, (local0)))))
                local2 = c2fb_temp_4
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_5 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, arg1->nPgTombstone) * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))
        local3 = c2fb_temp_5
        c2fb_temp_6 = Cast(c2fb_int64, local1)
        local2 = c2fb_temp_6
    End If
    While Cast(c2fb_c_int, 1ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        local6 = Cast(c2fb_c_int, &O0ULL)
        local7 = Cast(c2fb_c_int, &O0ULL)
        local8 = Cast(c2fb_c_int, &O0ULL)
        ' C unused-parameter annotation
        c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr Ptr, CPtr(c2fb_Fts5Data Ptr Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Data Ptr))) * Cast(c2fb_uint64, local3)))))))
        local8 = c2fb_temp_7
        c2fb_temp_8 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 8ULL)) + Cast(c2fb_int64, (local2 * Cast(c2fb_int64, arg4))))))
        local7 = c2fb_temp_8
        c2fb_temp_9 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
        local6 = c2fb_temp_9
        While (-Cast(c2fb_c_int, ((local6 < local3))))
            local9 = CPtr(c2fb_Fts5Data Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(arg0->rc)), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Data))) + Cast(c2fb_uint64, local7))))))
            If local9 Then
                c2fb_temp_11 = CPtr(Long Ptr, @(local9->nn))
                c2fb_temp_12 = Cast(c2fb_c_int, local7)
                (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
                c2fb_temp_13 = CPtr(c2fb_u8 Ptr Ptr, @(local9->p))
                c2fb_temp_14 = CPtr(UByte Ptr, CPtr(c2fb_Fts5Data Ptr, @(CPtr(c2fb_Fts5Data Ptr, local9)[Cast(c2fb_c_int, 1ULL)])))
                (*c2fb_temp_13) = CPtr(c2fb_u8 Ptr, c2fb_temp_14)
                c2fb_temp_14 = CPtr(UByte Ptr, (*c2fb_temp_13))
                c2fb_temp_15 = CPtr(c2fb_Fts5Data Ptr Ptr, @(CPtr(c2fb_Fts5Data Ptr Ptr, local8)[local6]))
                c2fb_temp_16 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local9)
                (*c2fb_temp_15) = c2fb_temp_16
            End If
        c2fb_flow_3:
            c2fb_temp_10 = local6
            local6 = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_10 + 1)))
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_17 = Cast(c2fb_c_int, fts5IndexTombstoneRehash(arg0, arg1, arg2, arg3, arg4, local3, local8))
            local5 = c2fb_temp_17
        End If
        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
            If arg0->rc Then
                fts5IndexFreeArray(local8, local3)
                c2fb_temp_18 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local8 = c2fb_temp_18
                c2fb_temp_19 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_19
            End If
            c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @((*arg5)))
            c2fb_temp_21 = Cast(c2fb_c_int, local3)
            (*c2fb_temp_20) = c2fb_temp_21
            c2fb_temp_22 = CPtr(c2fb_Fts5Data Ptr Ptr Ptr, @((*arg6)))
            c2fb_temp_23 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr Ptr, local8)
            (*c2fb_temp_22) = c2fb_temp_23
            Goto c2fb_flow_0
        End If
        ' C unused-parameter annotation
        fts5IndexFreeArray(local8, local3)
        c2fb_temp_24 = Cast(c2fb_int64, local1)
        local2 = c2fb_temp_24
        c2fb_temp_25 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (local3 * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))
        local3 = c2fb_temp_25
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub
Private Sub fts5IndexTombstoneAdd CDecl Alias "fts5IndexTombstoneAdd" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_uint64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8108
    Dim local0 As c2fb_Fts5Data Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_Fts5Data Ptr Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->nContentlessDelete))
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    If (-Cast(c2fb_c_int, ((arg1->nPgTombstone > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_uint64, (arg2 Mod Cast(c2fb_uint64, arg1->nPgTombstone))))
        local1 = c2fb_temp_2
        c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5DataRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (arg1->iSegid + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 16ULL)))))))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local1)))))))))
        local0 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C unused-parameter annotation
            Return
        End If
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5IndexTombstoneAddToPage(local0, Cast(c2fb_c_int, &O0ULL), arg1->nPgTombstone, arg2))))) Then
            fts5DataWrite(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (arg1->iSegid + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 16ULL)))))))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local1)))))), CPtr(Const UByte Ptr, local0->p), local0->nn)
            fts5DataRelease(local0)
            Return
        End If
    End If
    c2fb_temp_4 = Cast(c2fb_c_int, IIf(local0, (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->p[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 4ULL))))), Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 8ULL))), Cast(c2fb_c_int, 4ULL)))
    local2 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_uint64, Cast(c2fb_c_uint, &HFFFFFFFFULL)))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 8ULL))
        local2 = c2fb_temp_5
    End If
    fts5IndexTombstoneRebuild(arg0, arg1, local0, local1, local2, CPtr(c2fb_c_int Ptr, @(local3)), CPtr(c2fb_Fts5Data Ptr Ptr Ptr, @(local4)))
    ' C unused-parameter annotation
    If local3 Then
        local5 = Cast(c2fb_c_int, &O0ULL)
        fts5IndexTombstoneAddToPage(CPtr(c2fb_Fts5Data Ptr Ptr, local4)[Cast(c2fb_uint64, (arg2 Mod Cast(c2fb_uint64, local3)))], Cast(c2fb_c_int, 1ULL), local3, arg2)
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local5 = c2fb_temp_6
        While (-Cast(c2fb_c_int, ((local5 < local3))))
            local6 = (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, (arg1->iSegid + (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 16ULL)))))))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local5))))))
            fts5DataWrite(arg0, local6, CPtr(Const UByte Ptr, CPtr(c2fb_Fts5Data Ptr Ptr, local4)[local5]->p), CPtr(c2fb_Fts5Data Ptr Ptr, local4)[local5]->nn)
        c2fb_flow_1:
            c2fb_temp_7 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_8 = CPtr(Long Ptr, @(arg1->nPgTombstone))
        c2fb_temp_9 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
        fts5StructureWrite(arg0, CPtr(c2fb_Fts5Structure Ptr, arg0->pStruct))
    End If
    fts5DataRelease(local0)
    fts5IndexFreeArray(local4, local3)
End Sub
Function sqlite3Fts5IndexContentlessDelete CDecl Alias "sqlite3Fts5IndexContentlessDelete" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8166
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As c2fb_Fts5StructureSegment Ptr
    Dim c2fb_temp_5 As c2fb_u64 Ptr
    Dim c2fb_temp_6 As c2fb_uint64
    Dim c2fb_temp_7 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(arg0)))
    local0 = c2fb_temp_0
    If local0 Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0->nLevel - Cast(c2fb_c_int, 1ULL))))
        local2 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL)))))
            ' C automatic storage declaration
            c2fb_temp_3 = Cast(c2fb_c_int, (CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local0)))[local2].nSeg - Cast(c2fb_c_int, 1ULL)))
            local3 = c2fb_temp_3
            While (-Cast(c2fb_c_int, ((local3 >= Cast(c2fb_c_int, &O0ULL)))))
                local4 = @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local0)))[local2].aSeg[local3])
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4->iOrigin1 <= Cast(c2fb_uint64, arg1))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4->iOrigin2 >= Cast(c2fb_uint64, arg1))))) <> 0))))) Then
                    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_5 = CPtr(c2fb_u64 Ptr, @(local4->nEntryTombstone))
                        c2fb_temp_6 = Cast(c2fb_uint64, (*c2fb_temp_5))
                        (*c2fb_temp_5) = Cast(c2fb_uint64, Cast(c2fb_uint64, (c2fb_temp_6 + 1)))
                        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local1 = c2fb_temp_7
                    End If
                    fts5IndexTombstoneAdd(arg0, local4, arg2)
                End If
            c2fb_flow_3:
                c2fb_temp_4 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 - 1)))
            Wend
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_2 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 - 1)))
        Wend
        c2fb_flow_0:
        fts5StructureRelease(local0)
    End If
    Return fts5IndexReturn(arg0)
End Function
Function sqlite3Fts5IndexEntryCksum CDecl Alias "sqlite3Fts5IndexEntryCksum" (ByVal arg0 As c2fb_int64, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int) As c2fb_uint64
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8199
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_uint64
    Dim c2fb_temp_1 As c2fb_uint64
    Dim c2fb_temp_2 As c2fb_uint64
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_uint64

    ' C automatic storage declaration
    local1 = arg0
    c2fb_temp_0 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, arg1))))))
    local1 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, arg2))))))
    local1 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((arg3 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 48) + arg3)))))))))
        local1 = c2fb_temp_2
    End If
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_3
    While (-Cast(c2fb_c_int, ((local0 < arg5))))
        c2fb_temp_5 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local1 Shl Cast(c2fb_c_int, 3ULL)))) + Cast(c2fb_uint64, CPtr(Const Byte Ptr, arg4)[local0]))))))
        local1 = c2fb_temp_5
    c2fb_flow_1:
        c2fb_temp_4 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function
Private Sub fts5IndexIntegrityCheckEmpty CDecl Alias "fts5IndexIntegrityCheckEmpty" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8430
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_Fts5Data Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, arg2)
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 <= arg4)))) <> 0)))))
        local1 = CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local0))))))))
        If local1 Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((local1)->szLeaf >= (local1)->nn))))) = 0))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 >= arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) <> Cast(c2fb_c_int, (fts5GetU16(CPtr(Const UByte Ptr, (local1)->p)))))))) <> 0)))))) <> 0))))) Then
                fts5IndexCorruptRowid(arg0, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local0)))))))
            End If
        End If
        fts5DataRelease(local1)
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
End Sub
Private Sub fts5IntegrityCheckPgidx CDecl Alias "fts5IntegrityCheckPgidx" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_Fts5Data Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8454
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_Fts5Buffer
    Dim local3 As c2fb_Fts5Buffer
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_int64
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_int64
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_int64
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local3 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    c2fb_temp_0 = Cast(c2fb_c_int, arg2->szLeaf)
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < arg2->nn)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2->p[local1]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local6))))))))
        local1 = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, local6))))
        local0 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_int64, local0)
        local5 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local5 >= Cast(c2fb_int64, arg2->szLeaf))))) Then
            fts5IndexCorruptRowid(arg0, arg1)
        Else
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_int64, local6))))) Then
                ' C automatic storage declaration
                c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_int64, (local5 + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2->p[local5]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local7)))))))))
                local5 = c2fb_temp_4
                If (-Cast(c2fb_c_int, (((Cast(c2fb_int64, (local5 + Cast(c2fb_int64, local7)))) > Cast(c2fb_int64, arg2->szLeaf))))) Then
                    fts5IndexCorruptRowid(arg0, arg1)
                Else
                    c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), local7, CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2->p[local5]))))
                End If
            Else
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_int64, (local5 + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2->p[local5]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local8)))))))))
                local5 = c2fb_temp_5
                c2fb_temp_6 = Cast(c2fb_int64, Cast(c2fb_int64, (local5 + Cast(c2fb_int64, c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2->p[local5]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local9)))))))))
                local5 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 > local2.n)))) <> 0) OrElse ((-Cast(c2fb_c_int, (((Cast(c2fb_int64, (local5 + Cast(c2fb_int64, local9)))) > Cast(c2fb_int64, arg2->szLeaf))))) <> 0))))) Then
                    fts5IndexCorruptRowid(arg0, arg1)
                Else
                    c2fb_temp_7 = CPtr(Long Ptr, @(local2.n))
                    c2fb_temp_8 = Cast(c2fb_c_int, local8)
                    (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
                    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                    c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), local9, CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2->p[local5]))))
                End If
                If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_9 = Cast(c2fb_c_int, fts5BufferCompare(CPtr(c2fb_Fts5Buffer Ptr, @(local2)), CPtr(c2fb_Fts5Buffer Ptr, @(local3))))
                    local4 = c2fb_temp_9
                    If (-Cast(c2fb_c_int, ((local4 <= Cast(c2fb_c_int, &O0ULL))))) Then
                        fts5IndexCorruptRowid(arg0, arg1)
                    End If
                End If
            End If
        End If
        c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local3)), local2.n, CPtr(Const UByte Ptr, local2.p))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local2)))
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local3)))
End Sub
Private Sub fts5IndexIntegrityCheckSegment CDecl Alias "fts5IndexIntegrityCheckSegment" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5StructureSegment Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8504
    Dim local0 As c2fb_Fts5Config Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim local7 As c2fb_Fts5Data Ptr
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_Fts5Data Ptr
    Dim local12 As c2fb_c_int
    Dim local13 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local16 As c2fb_Fts5DlidxIter Ptr
    Dim local17 As c2fb_c_int
    Dim local18 As c2fb_c_int
    Dim local19 As c2fb_c_int
    Dim local20 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_Fts5DlidxIter Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_int64
    Dim c2fb_temp_14 As c2fb_Fts5Data Ptr
    Dim local21 As c2fb_int64
    Dim local22 As c2fb_c_int
    Dim local23 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)
    local1 = ((-Cast(c2fb_c_int, ((local0->iVersion = Cast(c2fb_c_int, 5ULL))))))
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, (arg1->pgnoFirst - Cast(c2fb_c_int, 1ULL)))
    local5 = arg1->pgnoLast
    If (-Cast(c2fb_c_int, ((arg1->pgnoFirst = Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    fts5IndexPrepareStmt(arg0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2)), CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT segid, term, (pgno>>1), (pgno&1) FROM %Q.'%q_idx' WHERE segid=%d ORDER BY 1, 2"), local0->zDb, local0->zName, arg1->iSegid)))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = sqlite3_step(CPtr(Any Ptr, local2)))))) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        local8 = CPtr(Const ZString Ptr, CPtr(Const Any Ptr, sqlite3_column_blob(CPtr(Any Ptr, local2), Cast(c2fb_c_int, 1ULL))))
        local9 = sqlite3_column_bytes(CPtr(Any Ptr, local2), Cast(c2fb_c_int, 1ULL))
        local10 = sqlite3_column_int(CPtr(Any Ptr, local2), Cast(c2fb_c_int, 2ULL))
        local11 = sqlite3_column_int(CPtr(Any Ptr, local2), Cast(c2fb_c_int, 3ULL))
        If (-Cast(c2fb_c_int, ((local10 < arg1->pgnoFirst)))) Then
            Goto c2fb_flow_1
        End If
        c2fb_temp_0 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (arg1->iSegid)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local10)))))))
        local6 = c2fb_temp_0
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, local6)))
        local7 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        If (-Cast(c2fb_c_int, ((local7->nn <= local7->szLeaf)))) Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->iVersion = Cast(c2fb_c_int, 5ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7->nn = local7->szLeaf)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7->nn = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                ' empty C block
            Else
                fts5IndexCorruptRowid(arg0, local6)
            End If
        Else
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_2 = Cast(c2fb_c_int, fts5LeafFirstTermOff(local7))
            local12 = c2fb_temp_2
            c2fb_temp_3 = Cast(c2fb_c_int, (fts5GetU16(CPtr(Const UByte Ptr, (local7)->p))))
            local13 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local13 >= local12)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local12 >= local7->szLeaf)))) <> 0))))) Then
                fts5IndexCorruptRowid(arg0, local6)
            Else
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local12 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local7->p[local12]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local14))))))))
                local12 = c2fb_temp_4
                If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (Cast(c2fb_int64, local12) + Cast(c2fb_int64, local14))) > Cast(c2fb_int64, local7->szLeaf))))) Then
                    fts5IndexCorruptRowid(arg0, local6)
                Else
                    c2fb_temp_5 = Cast(c2fb_c_int, (IIf((-Cast(c2fb_c_int, ((((IIf(((-Cast(c2fb_c_int, (((local14) < (local9)))))), (local14), (local9)))) <= Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_c_int, &O0ULL), c2fb_crt_memcmp(CPtr(Const Any Ptr, (CPtr(UByte Ptr, @(local7->p[local12])))), CPtr(Const Any Ptr, (local8)), ((IIf(((-Cast(c2fb_c_int, (((local14) < (local9)))))), (local14), (local9))))))))
                    local15 = c2fb_temp_5
                    If (-Cast(c2fb_c_int, ((local15 = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local14 - local9)))
                        local15 = c2fb_temp_6
                    End If
                    If (-Cast(c2fb_c_int, ((local15 < Cast(c2fb_c_int, &O0ULL))))) Then
                        fts5IndexCorruptRowid(arg0, local6)
                    End If
                End If
            End If
            fts5IntegrityCheckPgidx(arg0, local6, local7)
        End If
        fts5DataRelease(local7)
        If arg0->rc Then
            Goto c2fb_flow_0
        End If
        fts5IndexIntegrityCheckEmpty(arg0, arg1, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, (local10 - Cast(c2fb_c_int, 1ULL))))
        If arg0->rc Then
            Goto c2fb_flow_0
        End If
        If local11 Then
            local16 = Cast(c2fb_c_int, &O0ULL)
            local17 = local10
            local18 = arg1->iSegid
            local19 = Cast(c2fb_c_int, &O0ULL)
            ' C automatic storage declaration
            c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5DlidxIter Ptr, CPtr(c2fb_Fts5DlidxIter Ptr, fts5DlidxIterInit(arg0, Cast(c2fb_c_int, &O0ULL), local18, local10)))
            local16 = c2fb_temp_7
            While (-Cast(c2fb_c_int, ((fts5DlidxIterEof(arg0, local16) = Cast(c2fb_c_int, &O0ULL)))))
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local17 + Cast(c2fb_c_int, 1ULL))))
                local19 = c2fb_temp_8
                While (-Cast(c2fb_c_int, ((local19 < fts5DlidxIterPgno(local16)))))
                    c2fb_temp_10 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local18)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local19)))))))
                    local20 = c2fb_temp_10
                    c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, local20)))
                    local7 = c2fb_temp_11
                    If local7 Then
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (fts5GetU16(CPtr(Const UByte Ptr, (local7)->p)))) <> Cast(c2fb_c_int, &O0ULL))))) Then
                            fts5IndexCorruptRowid(arg0, local20)
                        End If
                        fts5DataRelease(local7)
                    End If
                c2fb_flow_5:
                    c2fb_temp_9 = local19
                    local19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
                Wend
                c2fb_flow_4:
                c2fb_temp_12 = Cast(c2fb_c_int, fts5DlidxIterPgno(local16))
                local17 = c2fb_temp_12
                c2fb_temp_13 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local18)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local17)))))))
                local20 = c2fb_temp_13
                c2fb_temp_14 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, fts5LeafRead(arg0, local20)))
                local7 = c2fb_temp_14
                If local7 Then
                    ' C automatic storage declaration
                    local22 = (fts5GetU16(CPtr(Const UByte Ptr, (local7)->p)))
                    ' C unused-parameter annotation
                    If (-Cast(c2fb_c_int, ((local22 >= local7->szLeaf)))) Then
                        fts5IndexCorruptRowid(arg0, local20)
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local22 > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                            local23 = fts5DlidxIterRowid(local16)
                            c2fb_external_sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local7->p[local22]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(local21))))
                            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local21 < local23)))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local21 <> local23)))) <> 0)))))) <> 0))))) Then
                                fts5IndexCorruptRowid(arg0, local20)
                            End If
                        End If
                    End If
                    fts5DataRelease(local7)
                End If
            c2fb_flow_3:
                fts5DlidxIterNext(arg0, local16)
            Wend
            c2fb_flow_2:
            c2fb_temp_15 = Cast(c2fb_c_int, local19)
            local5 = c2fb_temp_15
            fts5DlidxIterFree(local16)
            ' empty C statement
        Else
            c2fb_temp_16 = Cast(c2fb_c_int, arg1->pgnoLast)
            local5 = c2fb_temp_16
        End If
        c2fb_temp_17 = Cast(c2fb_c_int, local10)
        local4 = c2fb_temp_17
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_18 = Cast(c2fb_c_int, sqlite3_finalize(CPtr(Any Ptr, local2)))
    local3 = c2fb_temp_18
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_19 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_20 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
        c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
    End If
End Sub
Function sqlite3Fts5IndexIntegrityCheck CDecl Alias "sqlite3Fts5IndexIntegrityCheck" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_uint64, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8669
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_uint64
    Dim local2 As c2fb_Fts5Buffer
    Dim local3 As c2fb_Fts5Iter Ptr
    Dim local4 As c2fb_Fts5Structure Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local8 As c2fb_Fts5StructureSegment Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_int64
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_int64
    Dim local13 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_uint64
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_uint64
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int

    local0 = CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local7 = Cast(c2fb_c_int, &H0020ULL)
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(arg0)))
    local4 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        Return fts5IndexReturn(arg0)
    End If
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local5 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((local5 < local4->nLevel))))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local6 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local6 < CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local4)))[local5].nSeg))))
            local8 = @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local4)))[local5].aSeg[local6])
            fts5IndexIntegrityCheckSegment(arg0, local8)
        c2fb_flow_3:
            c2fb_temp_4 = local6
            local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_2 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    fts5MultiIterNew(arg0, local4, local7, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_Fts5Iter Ptr Ptr, @(local3)))
    While (-Cast(c2fb_c_int, ((fts5MultiIterEof(arg0, local3) = Cast(c2fb_c_int, &O0ULL)))))
        ' C automatic storage declaration
        local10 = Cast(c2fb_c_int, &O0ULL)
        local11 = Cast(c2fb_c_int, &O0ULL)
        local12 = fts5MultiIterRowid(local3)
        local13 = CPtr(ZString Ptr, CPtr(Const UByte Ptr, fts5MultiIterTerm(local3, CPtr(c2fb_c_int Ptr, @(local9)))))
        ' empty C statement
        If arg0->rc Then
            Goto c2fb_flow_4
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5MultiIterIsEmpty(arg0, local3))))) Then
                c2fb_temp_5 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 Xor sqlite3Fts5IndexEntryCksum(local12, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Const ZString Ptr, local13), local9))))
                local1 = c2fb_temp_5
            End If
        Else
            c2fb_temp_6 = CPtr(Long Ptr, @(local2.n))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            fts5SegiterPoslist(arg0, CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local3)))[CPtr(c2fb_Fts5CResult Ptr, CPtr(c2fb_Fts5CResult Ptr, local3->aFirst))[Cast(c2fb_c_int, 1ULL)].iFirst])), Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_Fts5Buffer Ptr, @(local2)))
            c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(c2fb_Fts5Buffer Ptr, @(local2)), Cast(c2fb_c_int, 4ULL), CPtr(Const UByte Ptr, StrPtr(!"\000\000\000\000")))
            While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3Fts5PoslistNext64(CPtr(Const UByte Ptr, local2.p), local2.n, CPtr(c2fb_c_int Ptr, @(local11)), CPtr(c2fb_int64 Ptr, @(local10)))))))
                local14 = Cast(c2fb_c_int, (Cast(c2fb_int64, ((Cast(c2fb_int64, (local10 Shr Cast(c2fb_c_int, 32ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL))))))
                local15 = Cast(c2fb_c_int, (Cast(c2fb_int64, (local10 And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL))))))
                c2fb_temp_8 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local1 Xor sqlite3Fts5IndexEntryCksum(local12, local14, local15, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(Const ZString Ptr, local13), local9))))
                local1 = c2fb_temp_8
            c2fb_flow_7:
            Wend
            c2fb_flow_6:
        End If
    c2fb_flow_5:
        fts5MultiIterNext(arg0, local3, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    Wend
    c2fb_flow_4:
    ' empty C statement
    fts5MultiIterFree(local3)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 <> local1)))) <> 0))))) Then
        c2fb_temp_9 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_10 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
        (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
        c2fb_external_sqlite3Fts5ConfigErrmsg(CPtr(c2fb_Fts5Config Ptr, arg0->pConfig), StrPtr(!"fts5: checksum mismatch for table \034%s\034"), CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->zName)
    End If
    fts5StructureRelease(local4)
    c2fb_external_sqlite3Fts5BufferFree(CPtr(c2fb_Fts5Buffer Ptr, @(local2)))
    Return fts5IndexReturn(arg0)
End Function
#ifndef SQLITE_TEST
#ifndef SQLITE_FTS5_DEBUG
Function sqlite3Fts5IndexInit CDecl Alias "sqlite3Fts5IndexInit" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
    ' The release build has no test-only FTS5 diagnostic functions to register.
    Return SQLITE_OK
End Function
#endif
#endif
Function sqlite3Fts5IndexReset CDecl Alias "sqlite3Fts5IndexReset" (ByVal arg0 As c2fb_Fts5Index Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9584
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((fts5IndexDataVersion(arg0) <> arg0->iStructVersion)))) Then
        fts5StructureInvalidate(arg0)
    End If
    Return fts5IndexReturn(arg0)
End Function

/'
    C2FB tokendata-index helpers recovered with explicit source-layout maps.
    Each body retains its upstream source location comment.
'/

Private Function fts5AppendTokendataIter CDecl Alias "fts5AppendTokendataIter" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_Fts5TokenDataIter Ptr, ByVal arg2 As c2fb_Fts5Iter Ptr) As c2fb_Fts5TokenDataIter Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7076
    Dim local0 As c2fb_Fts5TokenDataIter Ptr
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_int64
    Dim local3 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_0 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_5 As c2fb_i64 Ptr
    Dim c2fb_temp_6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_i64 Ptr
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_Fts5Iter Ptr Ptr
    Dim c2fb_temp_10 As c2fb_Fts5Iter Ptr

    local0 = arg1
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->nIter = arg1->nIterAlloc)))) <> 0))))) Then
            local1 = IIf(arg1, Cast(c2fb_int64, (arg1->nIterAlloc * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))), Cast(c2fb_int64, Cast(c2fb_c_int, 16ULL)))
            local2 = (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5TokenDataIter_apIter_tail_ptr(Cast(c2fb_Fts5TokenDataIter Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_int64, (local1 + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Iter))))))))
            ' C automatic storage declaration
            c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg1), local2))))
            local3 = c2fb_temp_0
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
                c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
            Else
                If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local3), Cast(c2fb_c_int, &O0ULL), local2))
                End If
                c2fb_temp_4 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, local3)
                local0 = c2fb_temp_4
                c2fb_temp_5 = CPtr(c2fb_i64 Ptr, @(local3->nIterAlloc))
                c2fb_temp_6 = Cast(c2fb_int64, local1)
                (*c2fb_temp_5) = Cast(c2fb_i64, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_int64, (*c2fb_temp_5))
            End If
        End If
    End If
    If arg0->rc Then
        fts5IterClose(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, CPtr(c2fb_Fts5IndexIter Ptr, arg2)))
    Else
        c2fb_temp_7 = CPtr(c2fb_i64 Ptr, @(local0->nIter))
        c2fb_temp_8 = Cast(c2fb_int64, (*c2fb_temp_7))
        (*c2fb_temp_7) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_8 + 1)))
        c2fb_temp_9 = CPtr(c2fb_Fts5Iter Ptr Ptr, @(CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(local0)))[c2fb_temp_8]))
        c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, arg2)
        (*c2fb_temp_9) = c2fb_temp_10
    End If
    ' C unused-parameter annotation
    Return local0
End Function

Private Function fts5SetupPrefixIterTokendata CDecl Alias "fts5SetupPrefixIterTokendata" (ByVal arg0 As c2fb_Fts5Iter Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7590
    Dim local0 As c2fb_Fts5Index Ptr
    Dim local1 As c2fb_Fts5Buffer
    Dim local2 As c2fb_TokendataSetupCtx
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_Fts5TokenDataIter Ptr Ptr
    Dim c2fb_temp_3 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_4 As c2fb_u8 Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_Fts5TokenDataIter_ Ptr Ptr
    Dim c2fb_temp_10 As c2fb_Fts5TokenDataIter Ptr

    local0 = CPtr(c2fb_Fts5Index Ptr, arg0->pIndex)
    local1 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_TokendataSetupCtx Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_TokendataSetupCtx))))
    c2fb_temp_1 = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((CPtr(c2fb_Fts5Buffer Ptr, @(local1)))->n)) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))))))) <= Cast(c2fb_c_uint, ((CPtr(c2fb_Fts5Buffer Ptr, @(local1)))->nSpace)))))), Cast(c2fb_c_int, &O0ULL), c2fb_external_sqlite3Fts5BufferSize((CPtr(c2fb_c_int Ptr, @(local0->rc))), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, (CPtr(c2fb_Fts5Buffer Ptr, @(local1)))), Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL)))) + (CPtr(c2fb_Fts5Buffer Ptr, @(local1)))->n)))))
    ' C unused-parameter annotation
    c2fb_temp_2 = CPtr(c2fb_Fts5TokenDataIter Ptr Ptr, @(local2.pT))
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0->rc)), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5TokenDataIter_apIter_tail_ptr(Cast(c2fb_Fts5TokenDataIter Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 1ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Iter))))))))))))
    (*c2fb_temp_2) = c2fb_temp_3
    If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = CPtr(c2fb_u8 Ptr, @(local1.p[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, 48))
        (*c2fb_temp_4) = Cast(c2fb_u8, c2fb_temp_5)
        c2fb_temp_5 = Cast(UByte, (*c2fb_temp_4))
        c2fb_temp_6 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local1.p[Cast(c2fb_c_int, 1ULL)]))), CPtr(Const Any Ptr, arg1), arg2))
        c2fb_temp_7 = CPtr(Long Ptr, @(local1.n))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        fts5VisitEntries(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, local0), Cast(c2fb_c_int, &O0ULL), local1.p, local1.n, Cast(c2fb_c_int, 1ULL), ProcPtr(prefixIterSetupTokendataCb), CPtr(Any Ptr, CPtr(c2fb_TokendataSetupCtx Ptr, @(local2))))
        fts5TokendataIterSortMap(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, local0), CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, local2.pT)))
    End If
    If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_9 = CPtr(c2fb_Fts5TokenDataIter_ Ptr Ptr, @(arg0->pTokenDataIter))
        c2fb_temp_10 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, local2.pT))
        (*c2fb_temp_9) = CPtr(c2fb_Fts5TokenDataIter_ Ptr, c2fb_temp_10)
        c2fb_temp_10 = CPtr(c2fb_Fts5TokenDataIter Ptr, (*c2fb_temp_9))
    Else
        fts5TokendataIterDelete(CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, local2.pT)))
    End If
    c2fb_external_sqlite3Fts5BufferFree(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local1))))
    Return fts5IndexReturn(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, local0))
End Function

Private Function fts5SetupTokendataIter CDecl Alias "fts5SetupTokendataIter" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_Fts5Colset Ptr) As c2fb_Fts5Iter Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7280
    Dim local0 As c2fb_Fts5Iter Ptr
    Dim local1 As c2fb_Fts5TokenDataIter Ptr
    Dim local2 As c2fb_Fts5Structure Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_Fts5Buffer
    Dim local5 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr
    Dim local6 As c2fb_Fts5Iter Ptr
    Dim local7 As c2fb_Fts5Iter Ptr
    Dim local8 As c2fb_Fts5SegIter Ptr
    Dim local9 As c2fb_Fts5SegIter Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_2 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_3 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local13 As c2fb_Fts5StructureSegment Ptr
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_Fts5TombstoneArray_ Ptr Ptr
    Dim c2fb_temp_13 As c2fb_Fts5TombstoneArray Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_17 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_18 As c2fb_u8 Ptr
    Dim c2fb_temp_19 As UByte
    Dim c2fb_temp_20 As Any Ptr Ptr
    Dim c2fb_temp_21 As c2fb_Fts5Colset Ptr
    Dim c2fb_temp_22 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim local15 As c2fb_Fts5SegIter Ptr
    Dim c2fb_temp_25 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_26 As c2fb_Fts5TokenDataIter Ptr
    Dim local16 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim local17 As c2fb_Fts5Iter Ptr
    Dim local18 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As Long Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_Fts5Iter Ptr
    Dim c2fb_temp_34 As Long Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_Fts5TokenDataIter_ Ptr Ptr
    Dim c2fb_temp_37 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_38 As c2fb_u8 Ptr
    Dim c2fb_temp_39 As UByte

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, (Cast(c2fb_c_int, &H0100ULL) Or Cast(c2fb_c_int, &H0008ULL)))
    local4 = Type<c2fb_Fts5Buffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local5 = Cast(c2fb_c_int, &O0ULL)
    fts5IndexFlush(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0))
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0))))
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))
        local6 = IIf(local1, CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(local1)))[Cast(c2fb_int64, (local1->nIter - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))], CPtr(c2fb_Fts5Iter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))
        local7 = Cast(c2fb_c_int, &O0ULL)
        local8 = Cast(c2fb_c_int, &O0ULL)
        local9 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, CPtr(c2fb_Fts5Iter Ptr, fts5MultiIterAlloc(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), local2->nSegment)))
        local7 = c2fb_temp_1
        If local5 Then
            c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local4))), local5->n, CPtr(Const UByte Ptr, local5->p))
            c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local4))), Cast(c2fb_c_int, 1ULL), CPtr(Const UByte Ptr, StrPtr(!"\000")))
        Else
            c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local4))), arg2, arg1)
        End If
        If arg0->rc Then
            fts5IterClose(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, CPtr(c2fb_Fts5IndexIter Ptr, local7)))
            Goto c2fb_flow_0
        End If
        c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local7)))[Cast(c2fb_c_int, &O0ULL)])))
        local8 = c2fb_temp_2
        c2fb_temp_3 = CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, (IIf(local6, CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local6)))[Cast(c2fb_c_int, &O0ULL)])), CPtr(c2fb_Fts5SegIter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
        local9 = c2fb_temp_3
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local10 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((local10 < local2->nLevel))))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local2)))[local10].nSeg - Cast(c2fb_c_int, 1ULL))))
            local11 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((local11 >= Cast(c2fb_c_int, &O0ULL)))))
                local13 = CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local2)))[local10].aSeg))[local11]))
                local14 = Cast(c2fb_c_int, &O0ULL)
                If local9 Then
                    If fts5BufferCompare(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, local5), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9->term)))) Then
                        c2fb_temp_8 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, local8), CPtr(Const Any Ptr, local9), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegIter))))
                        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local9), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5SegIter))))
                        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local14 = c2fb_temp_10
                    Else
                        If (-Cast(c2fb_c_int, ((local9->iEndofDoclist > CPtr(c2fb_Fts5Data Ptr, local9->pLeaf)->szLeaf)))) Then
                            fts5SegIterNextInit(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(Const ZString Ptr, local4.p), Cast(c2fb_c_int, (local4.n - Cast(c2fb_c_int, 1ULL))), CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, local13), CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, local8))
                            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local14 = c2fb_temp_11
                        End If
                    End If
                End If
                If (-Cast(c2fb_c_int, ((local14 = Cast(c2fb_c_int, &O0ULL))))) Then
                    fts5SegIterSeekInit(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(Const UByte Ptr, local4.p), local4.n, local3, CPtr(_c2fb_record_c2fb_Fts5StructureSegment Ptr, local13), CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, local8))
                End If
                If local9 Then
                    If CPtr(c2fb_Fts5TombstoneArray Ptr, local9->pTombArray) Then
                        c2fb_temp_12 = CPtr(c2fb_Fts5TombstoneArray_ Ptr Ptr, @(local8->pTombArray))
                        c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5TombstoneArray Ptr, CPtr(c2fb_Fts5TombstoneArray Ptr, local9->pTombArray))
                        (*c2fb_temp_12) = CPtr(c2fb_Fts5TombstoneArray_ Ptr, c2fb_temp_13)
                        c2fb_temp_13 = CPtr(c2fb_Fts5TombstoneArray Ptr, (*c2fb_temp_12))
                        c2fb_temp_14 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5TombstoneArray Ptr, local8->pTombArray)->nRef))
                        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                        (*c2fb_temp_14) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
                    End If
                Else
                    fts5SegIterAllocTombstone(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, local8))
                End If
                c2fb_temp_16 = local8
                local8 = (c2fb_temp_16 + 1)
                If local9 Then
                    c2fb_temp_17 = local9
                    local9 = (c2fb_temp_17 + 1)
                End If
                If arg0->rc Then
                    Goto c2fb_flow_4
                End If
            c2fb_flow_5:
                c2fb_temp_7 = local11
                local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 - 1)))
            Wend
            c2fb_flow_4:
        c2fb_flow_3:
            c2fb_temp_5 = local10
            local10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_2:
        fts5TokendataSetTermIfEof(CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, local6), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, local5))
        c2fb_temp_18 = CPtr(c2fb_u8 Ptr, @(local7->bSkipEmpty))
        c2fb_temp_19 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_18) = Cast(c2fb_u8, c2fb_temp_19)
        c2fb_temp_19 = Cast(UByte, (*c2fb_temp_18))
        c2fb_temp_20 = CPtr(Any Ptr Ptr, @(local7->pColset))
        c2fb_temp_21 = CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, arg3)
        (*c2fb_temp_20) = CPtr(Any Ptr, c2fb_temp_21)
        c2fb_temp_21 = CPtr(c2fb_Fts5Colset Ptr, (*c2fb_temp_20))
        fts5IterSetOutputCb(CPtr(c2fb_c_int Ptr, @(arg0->rc)), CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, local7))
        c2fb_temp_22 = CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local5 = c2fb_temp_22
        c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local12 = c2fb_temp_23
        While (-Cast(c2fb_c_int, ((local12 < local7->nSeg))))
            local15 = CPtr(c2fb_Fts5SegIter Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local7)))[local12]))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = fts5IsTokendataPrefix(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local15->term))), arg1, arg2))))) Then
                fts5SegIterSetEOF(CPtr(_c2fb_record_c2fb_Fts5SegIter Ptr, local15))
            End If
            If (-Cast(c2fb_c_int, (((CPtr(c2fb_Fts5Data Ptr, local15->pLeaf) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local5 = 0))) <> 0) OrElse ((-Cast(c2fb_c_int, ((fts5BufferCompare(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, local5), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local15->term)))) > Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
                c2fb_temp_25 = CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local15->term)))
                local5 = c2fb_temp_25
            End If
        c2fb_flow_7:
            c2fb_temp_24 = local12
            local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_24 + 1)))
        Wend
        c2fb_flow_6:
        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
            fts5IterClose(CPtr(_c2fb_record_c2fb_Fts5IndexIter Ptr, CPtr(c2fb_Fts5IndexIter Ptr, local7)))
            Goto c2fb_flow_0
        End If
        c2fb_temp_26 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, fts5AppendTokendataIter(arg0, local1, local7)))
        local1 = c2fb_temp_26
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1 <> 0))))) Then
        ' C automatic storage declaration
        c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local16 = c2fb_temp_27
        While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local16) < local1->nIter))))
            local17 = CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(local1)))[local16]
            ' C automatic storage declaration
            c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local18 = c2fb_temp_29
            While (-Cast(c2fb_c_int, ((local18 < local17->nSeg))))
                c2fb_temp_31 = CPtr(Long Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(local17)))[local18].flags))
                c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_31)) Or Cast(c2fb_c_int, &H01ULL))))
                (*c2fb_temp_31) = Cast(Long, c2fb_temp_32)
                c2fb_temp_32 = Cast(c2fb_c_int, (*c2fb_temp_31))
            c2fb_flow_11:
                c2fb_temp_30 = local18
                local18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_30 + 1)))
            Wend
            c2fb_flow_10:
            fts5MultiIterFinishSetup(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, local17))
        c2fb_flow_9:
            c2fb_temp_28 = local16
            local16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
        Wend
        c2fb_flow_8:
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_33 = CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, CPtr(c2fb_Fts5Iter Ptr, fts5MultiIterAlloc(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), Cast(c2fb_c_int, &O0ULL))))
        local0 = c2fb_temp_33
    End If
    If local0 Then
        c2fb_temp_34 = CPtr(Long Ptr, @(local0->nSeg))
        c2fb_temp_35 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_34) = Cast(Long, c2fb_temp_35)
        c2fb_temp_35 = Cast(c2fb_c_int, (*c2fb_temp_34))
        c2fb_temp_36 = CPtr(c2fb_Fts5TokenDataIter_ Ptr Ptr, @(local0->pTokenDataIter))
        c2fb_temp_37 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, local1)
        (*c2fb_temp_36) = CPtr(c2fb_Fts5TokenDataIter_ Ptr, c2fb_temp_37)
        c2fb_temp_37 = CPtr(c2fb_Fts5TokenDataIter Ptr, (*c2fb_temp_36))
        If local1 Then
            fts5IterSetOutputsTokendata(CPtr(_c2fb_record_c2fb_Fts5Iter Ptr, local0))
        Else
            c2fb_temp_38 = CPtr(c2fb_u8 Ptr, @(local0->base.bEof))
            c2fb_temp_39 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_38) = Cast(c2fb_u8, c2fb_temp_39)
            c2fb_temp_39 = Cast(UByte, (*c2fb_temp_38))
        End If
    Else
        fts5TokendataIterDelete(CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, local1))
    End If
    fts5StructureRelease(CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local2))
    c2fb_external_sqlite3Fts5BufferFree(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local4))))
    Return local0
End Function

Private Sub fts5SetupPrefixIter CDecl Alias "fts5SetupPrefixIter" (ByVal arg0 As c2fb_Fts5Index Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_Fts5Colset Ptr, ByVal arg6 As c2fb_Fts5Iter Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 6713
    Dim local0 As c2fb_Fts5Structure Ptr
    Dim local1 As c2fb_PrefixSetupCtx
    Dim local2 As c2fb_TokendataSetupCtx
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_i64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_TokendataSetupCtx_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_TokendataSetupCtx Ptr
    Dim c2fb_temp_10 As c2fb_Fts5TokenDataIter Ptr Ptr
    Dim c2fb_temp_11 As c2fb_Fts5TokenDataIter Ptr
    Type c2fb_callback_storage_12 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Buffer Ptr)
    Dim c2fb_temp_12 As c2fb_callback_storage_12 Ptr
    Dim c2fb_temp_13 As c2fb_callback_350
    Type c2fb_callback_storage_14 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_u64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
    Dim c2fb_temp_14 As c2fb_callback_storage_14 Ptr
    Dim c2fb_temp_15 As c2fb_callback_351
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Type c2fb_callback_storage_20 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Buffer Ptr)
    Dim c2fb_temp_20 As c2fb_callback_storage_20 Ptr
    Dim c2fb_temp_21 As c2fb_callback_350
    Type c2fb_callback_storage_22 As Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_u64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr)
    Dim c2fb_temp_22 As c2fb_callback_storage_22 Ptr
    Dim c2fb_temp_23 As c2fb_callback_351
    Dim c2fb_temp_24 As c2fb_Fts5Buffer Ptr Ptr
    Dim c2fb_temp_25 As c2fb_Fts5Buffer Ptr
    Dim c2fb_temp_26 As c2fb_Fts5Structure Ptr
    Dim local3 As Any Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_27 As UByte Ptr
    Dim c2fb_temp_28 As UByte
    Dim c2fb_temp_29 As UByte Ptr
    Dim c2fb_temp_30 As UByte
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_36 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_37 As UByte Ptr
    Dim c2fb_temp_38 As Long Ptr
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As Long Ptr
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As Any Ptr
    Dim c2fb_temp_43 As c2fb_Fts5TokenDataIter_ Ptr Ptr
    Dim c2fb_temp_44 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_45 As c2fb_Fts5TokenDataIter Ptr Ptr
    Dim c2fb_temp_46 As c2fb_Fts5TokenDataIter Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_PrefixSetupCtx Ptr, @(local1))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_PrefixSetupCtx))))
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_TokendataSetupCtx Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_TokendataSetupCtx))))
    c2fb_temp_2 = CPtr(Long Ptr, @(local1.nMerge))
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(c2fb_i64 Ptr, @(local1.iLastRowid))
    c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_4) = Cast(c2fb_i64, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_int64, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(Long Ptr, @(local1.nBuf))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 32ULL))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->bPrefixInsttoken <> 0))))) Then
        c2fb_temp_8 = CPtr(c2fb_TokendataSetupCtx_ Ptr Ptr, @(local1.pTokendata))
        c2fb_temp_9 = CPtr(_c2fb_record_c2fb_TokendataSetupCtx Ptr, CPtr(c2fb_TokendataSetupCtx Ptr, @(local2)))
        (*c2fb_temp_8) = CPtr(c2fb_TokendataSetupCtx_ Ptr, c2fb_temp_9)
        c2fb_temp_9 = CPtr(c2fb_TokendataSetupCtx Ptr, (*c2fb_temp_8))
        c2fb_temp_10 = CPtr(c2fb_Fts5TokenDataIter Ptr Ptr, @(local2.pT))
        c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, CPtr(Any Ptr, fts5IdxMalloc(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5TokenDataIter_apIter_tail_ptr(Cast(c2fb_Fts5TokenDataIter Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 1ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Iter))))))))))))
        (*c2fb_temp_10) = c2fb_temp_11
    End If
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Config Ptr, arg0->pConfig)->eDetail = Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_temp_12 = CPtr(c2fb_callback_storage_12 Ptr, @(local1.xMerge))
        c2fb_temp_13 = ProcPtr(fts5MergeRowidLists)
        (*c2fb_temp_12) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Buffer Ptr), c2fb_temp_13)
        c2fb_temp_13 = CPtr(c2fb_callback_350, (*c2fb_temp_12))
        c2fb_temp_14 = CPtr(c2fb_callback_storage_14 Ptr, @(local1.xAppend))
        c2fb_temp_15 = ProcPtr(fts5AppendRowid)
        (*c2fb_temp_14) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_u64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr), c2fb_temp_15)
        c2fb_temp_15 = CPtr(c2fb_callback_351, (*c2fb_temp_14))
    Else
        c2fb_temp_16 = CPtr(Long Ptr, @(local1.nMerge))
        c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, 16ULL) - Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
        c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
        c2fb_temp_18 = CPtr(Long Ptr, @(local1.nBuf))
        c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1.nMerge * Cast(c2fb_c_int, 8ULL))))
        (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
        c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
        c2fb_temp_20 = CPtr(c2fb_callback_storage_20 Ptr, @(local1.xMerge))
        c2fb_temp_21 = ProcPtr(fts5MergePrefixLists)
        (*c2fb_temp_20) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Long, ByVal arg3 As c2fb_Fts5Buffer Ptr), c2fb_temp_21)
        c2fb_temp_21 = CPtr(c2fb_callback_350, (*c2fb_temp_20))
        c2fb_temp_22 = CPtr(c2fb_callback_storage_22 Ptr, @(local1.xAppend))
        c2fb_temp_23 = ProcPtr(fts5AppendPoslist)
        (*c2fb_temp_22) = CPtr(Sub CDecl(ByVal arg0 As c2fb_Fts5Index_ Ptr, ByVal arg1 As c2fb_u64, ByVal arg2 As c2fb_Fts5Iter Ptr, ByVal arg3 As c2fb_Fts5Buffer Ptr), c2fb_temp_23)
        c2fb_temp_23 = CPtr(c2fb_callback_351, (*c2fb_temp_22))
    End If
    c2fb_temp_24 = CPtr(c2fb_Fts5Buffer Ptr Ptr, @(local1.aBuf))
    c2fb_temp_25 = CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, CPtr(Any Ptr, fts5IdxMalloc(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))) * Cast(c2fb_uint64, local1.nBuf)))))))
    (*c2fb_temp_24) = c2fb_temp_25
    c2fb_temp_26 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, fts5StructureRead(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0))))
    local0 = c2fb_temp_26
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local3 = CPtr(Any Ptr, CPtr(c2fb_PrefixSetupCtx Ptr, @(local1)))
        ' C automatic storage declaration
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((arg2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_27 = CPtr(UByte Ptr, @(arg3[Cast(c2fb_c_int, &O0ULL)]))
            c2fb_temp_28 = Cast(UByte, Cast(c2fb_c_int, 48))
            (*c2fb_temp_27) = c2fb_temp_28
            fts5VisitEntries(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, arg5), arg3, arg4, Cast(c2fb_c_int, &O0ULL), ProcPtr(prefixIterSetupCb), local3)
        End If
        c2fb_temp_29 = CPtr(UByte Ptr, @(arg3[Cast(c2fb_c_int, &O0ULL)]))
        c2fb_temp_30 = Cast(UByte, Cast(c2fb_c_int, (Cast(c2fb_c_int, 48) + arg2)))
        (*c2fb_temp_29) = c2fb_temp_30
        fts5VisitEntries(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Colset Ptr, arg5), arg3, arg4, Cast(c2fb_c_int, 1ULL), ProcPtr(prefixIterSetupCb), local3)
        ' C unused-parameter annotation
        c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local4 = c2fb_temp_31
        While (-Cast(c2fb_c_int, ((local4 < local1.nBuf))))
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                CPtr(c2fb_callback_350, local1.xMerge)(arg0, CPtr(c2fb_Fts5Buffer Ptr, @(local1.doclist)), local1.nMerge, CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, local1.aBuf))[local4])))
            End If
            c2fb_temp_33 = Cast(c2fb_c_int, local4)
            local6 = c2fb_temp_33
            While (-Cast(c2fb_c_int, ((local6 < Cast(c2fb_c_int, (local4 + local1.nMerge))))))
                c2fb_external_sqlite3Fts5BufferFree(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, local1.aBuf))[local6]))))
            c2fb_flow_3:
                c2fb_temp_34 = local6
                local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_34 + 1)))
            Wend
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + local1.nMerge)))
            local4 = c2fb_temp_32
        Wend
        c2fb_flow_0:
        c2fb_temp_35 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(Any Ptr, fts5IdxMalloc(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Data))) + Cast(c2fb_uint64, (Cast(c2fb_int64, local1.doclist.n))))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 8ULL)))))))
        local5 = c2fb_temp_35
        ' C unused-parameter annotation
        If local5 Then
            c2fb_temp_36 = CPtr(c2fb_u8 Ptr Ptr, @(local5->p))
            c2fb_temp_37 = CPtr(UByte Ptr, CPtr(c2fb_Fts5Data Ptr, @(CPtr(c2fb_Fts5Data Ptr, local5)[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_36) = CPtr(c2fb_u8 Ptr, c2fb_temp_37)
            c2fb_temp_37 = CPtr(UByte Ptr, (*c2fb_temp_36))
            c2fb_temp_40 = CPtr(Long Ptr, @(local5->nn))
            c2fb_temp_38 = CPtr(Long Ptr, @(local5->szLeaf))
            c2fb_temp_39 = Cast(c2fb_c_int, local1.doclist.n)
            (*c2fb_temp_38) = Cast(Long, c2fb_temp_39)
            c2fb_temp_39 = Cast(c2fb_c_int, (*c2fb_temp_38))
            c2fb_temp_41 = Cast(c2fb_c_int, c2fb_temp_39)
            (*c2fb_temp_40) = Cast(Long, c2fb_temp_41)
            c2fb_temp_41 = Cast(c2fb_c_int, (*c2fb_temp_40))
            If local1.doclist.n Then
                c2fb_temp_42 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, local5->p), CPtr(Const Any Ptr, local1.doclist.p), local1.doclist.n))
            End If
            fts5MultiIterNew2(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5Data Ptr, local5), arg1, CPtr(_c2fb_record_c2fb_Fts5Iter Ptr Ptr, arg6))
        End If
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_TokendataSetupCtx Ptr, local1.pTokendata) <> 0))))) Then
            fts5TokendataIterSortMap(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, arg0), CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, local2.pT)))
            c2fb_temp_43 = CPtr(c2fb_Fts5TokenDataIter_ Ptr Ptr, @(((*arg6))->pTokenDataIter))
            c2fb_temp_44 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, local2.pT))
            (*c2fb_temp_43) = CPtr(c2fb_Fts5TokenDataIter_ Ptr, c2fb_temp_44)
            c2fb_temp_44 = CPtr(c2fb_Fts5TokenDataIter Ptr, (*c2fb_temp_43))
            c2fb_temp_45 = CPtr(c2fb_Fts5TokenDataIter Ptr Ptr, @(local2.pT))
            c2fb_temp_46 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_45) = c2fb_temp_46
        End If
    End If
    fts5TokendataIterDelete(CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, local2.pT)))
    c2fb_external_sqlite3Fts5BufferFree(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local1.doclist))))
    fts5StructureRelease(CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local0))
    sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, local1.aBuf)))
End Sub

Function sqlite3Fts5IndexIterWriteTokendata CDecl Alias "sqlite3Fts5IndexIterWriteTokendata" (ByVal arg0 As c2fb_Fts5IndexIter Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 7720
    Dim local0 As c2fb_Fts5Iter Ptr
    Dim local1 As c2fb_Fts5TokenDataIter Ptr
    Dim local2 As c2fb_Fts5Index Ptr
    Dim local3 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_Fts5TokenDataIter Ptr
    Dim c2fb_temp_1 As c2fb_Fts5TokenDataIter_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_Fts5TokenDataIter Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local5 As c2fb_Fts5Buffer Ptr

    local0 = CPtr(c2fb_Fts5Iter Ptr, arg0)
    local1 = CPtr(c2fb_Fts5TokenDataIter Ptr, local0->pTokenDataIter)
    local2 = CPtr(c2fb_Fts5Index Ptr, local0->pIndex)
    local3 = Cast(c2fb_int64, ((Cast(c2fb_int64, ((Cast(c2fb_int64, arg4)) Shl Cast(c2fb_c_int, 32ULL)))) + Cast(c2fb_int64, arg5)))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0->nSeg > Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, CPtr(c2fb_Fts5TokenDataIter Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local2->rc)), (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, c2fb_Fts5TokenDataIter_apIter_tail_ptr(Cast(c2fb_Fts5TokenDataIter Ptr, 0)))) + Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, 1ULL))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5Iter))))))))))))
            local1 = c2fb_temp_0
            c2fb_temp_1 = CPtr(c2fb_Fts5TokenDataIter_ Ptr Ptr, @(local0->pTokenDataIter))
            c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, local1)
            (*c2fb_temp_1) = CPtr(c2fb_Fts5TokenDataIter_ Ptr, c2fb_temp_2)
            c2fb_temp_2 = CPtr(c2fb_Fts5TokenDataIter Ptr, (*c2fb_temp_1))
        End If
        If local1 Then
            fts5TokendataIterAppendMap(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, local2), CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, local1), local1->terms.n, arg2, arg3, local3)
            c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(local2->rc)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local1->terms))), arg2, CPtr(Const UByte Ptr, arg1))
        End If
    Else
        ' C automatic storage declaration
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local4 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local4) < local1->nIter))))
            local5 = CPtr(c2fb_Fts5Buffer Ptr, @(CPtr(c2fb_Fts5SegIter Ptr, (c2fb_Fts5Iter_aSeg_tail_ptr(CPtr(c2fb_Fts5Iter Ptr Ptr, (c2fb_Fts5TokenDataIter_apIter_tail_ptr(local1)))[local4])))[Cast(c2fb_c_int, &O0ULL)].term))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, (local5->n - Cast(c2fb_c_int, 1ULL))))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((walSystemMemcmp(CPtr(Const Any Ptr, arg1), CPtr(Const Any Ptr, CPtr(UByte Ptr, (local5->p + Cast(c2fb_c_int, 1ULL)))), arg2) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_4 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, local4) < local1->nIter)))) Then
            fts5TokendataIterAppendMap(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, local2), CPtr(_c2fb_record_c2fb_Fts5TokenDataIter Ptr, local1), local4, Cast(c2fb_c_int, &O0ULL), arg3, local3)
        End If
    End If
    Return fts5IndexReturn(CPtr(_c2fb_record_c2fb_Fts5Index Ptr, local2))
End Function


#if defined(SQLITE_TEST) OrElse defined(SQLITE_FTS5_DEBUG)
/'
    FTS5 test-only index diagnostics and structure virtual table.
    These callbacks are available in test/debug profiles only.
'/
Private Sub fts5DecodeRowid CDecl Alias "fts5DecodeRowid" (ByVal arg0 As c2fb_int64, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8777
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_int64
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int

    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg5)))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (arg0 And (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)) Shl Cast(c2fb_c_int, 31ULL)))) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_int64, (arg0 Shr Cast(c2fb_c_int, 31ULL))))
    arg0 = c2fb_temp_2
    c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (arg0 And (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)) Shl Cast(c2fb_c_int, 5ULL)))) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))))))
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_int64, (arg0 Shr Cast(c2fb_c_int, 5ULL))))
    arg0 = c2fb_temp_5
    c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (arg0 And Cast(c2fb_int64, Cast(c2fb_c_int, &H0001ULL)))))))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = Cast(c2fb_int64, Cast(c2fb_int64, (arg0 Shr Cast(c2fb_c_int, 1ULL))))
    arg0 = c2fb_temp_8
    c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (arg0 And (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)) Shl Cast(c2fb_c_int, 16ULL)))) - Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))))))
    (*c2fb_temp_9) = c2fb_temp_10
    c2fb_temp_11 = Cast(c2fb_int64, Cast(c2fb_int64, (arg0 Shr Cast(c2fb_c_int, 16ULL))))
    arg0 = c2fb_temp_11
    c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_int64, (arg0 And Cast(c2fb_int64, Cast(c2fb_c_int, &H0001ULL)))))))
    (*c2fb_temp_12) = c2fb_temp_13
End Sub

Private Sub fts5DebugRowid CDecl Alias "fts5DebugRowid" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8802
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    fts5DecodeRowid(arg2, CPtr(c2fb_c_int Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local0)), CPtr(c2fb_c_int Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_c_int Ptr, @(local2)))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) Then
            c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!"{averages} ")))
        Else
            c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!"{structure}")))
        End If
    Else
        c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!"{%s%ssegid=%d h=%d pgno=%d}")), IIf(local3, StrPtr(!"dlidx "), StrPtr(!"")), IIf(local4, StrPtr(!"tombstone "), StrPtr(!"")), local0, local1, local2)
    End If
End Sub

Private Sub fts5DebugStructure CDecl Alias "fts5DebugStructure" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_Fts5Structure Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8824
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_Fts5StructureLevel Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As c2fb_Fts5StructureSegment Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg2->nLevel))))
        local2 = CPtr(c2fb_Fts5StructureLevel Ptr, @(CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(arg2)))[local0]))
        c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!" {lvl=%d nMerge=%d nSeg=%d")), local0, local2->nMerge, local2->nSeg)
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local1 < local2->nSeg))))
            local3 = CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, local2->aSeg))[local1]))
            c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!" {id=%d leaves=%d..%d")), local3->iSegid, local3->pgnoFirst, local3->pgnoLast)
            If (-Cast(c2fb_c_int, ((local3->iOrigin1 > Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!" origin=%lld..%lld")), local3->iOrigin1, local3->iOrigin2)
            End If
            c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!"}")))
        c2fb_flow_3:
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!"}")))
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
End Sub

Private Sub fts5DecodeStructure CDecl Alias "fts5DecodeStructure" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8861
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, fts5StructureDecode(arg2, arg3, Cast(c2fb_c_int, &O0ULL), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr Ptr, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local1)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg0)))
        c2fb_temp_2 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_1) = c2fb_temp_2
        Return
    End If
    fts5DebugStructure(arg0, arg1, local1)
    fts5StructureRelease(CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, local1))
End Sub

Private Sub fts5DecodeAverages CDecl Alias "fts5DecodeAverages" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8888
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Const ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = StrPtr(!"")
    While (-Cast(c2fb_c_int, ((local0 < arg3))))
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2[local0]))), CPtr(c2fb_uint64 Ptr, @(local2)))))))
        local0 = c2fb_temp_0
        c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!"%s%d")), local1, Cast(c2fb_c_int, local2))
        c2fb_temp_1 = StrPtr(!" ")
        local1 = c2fb_temp_1
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub

Private Function fts5DecodePoslist CDecl Alias "fts5DecodePoslist" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8913
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    While (-Cast(c2fb_c_int, ((local0 < arg3))))
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local1))))))))
        local0 = c2fb_temp_0
        c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!" %d")), local1)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local0
End Function

Private Function fts5DecodeDoclist CDecl Alias "fts5DecodeDoclist" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8933
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, sqlite3Fts5GetVarint(arg2, CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(local0)))))
        local1 = c2fb_temp_0
        c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!" id=%lld")), local0)
    End If
    While (-Cast(c2fb_c_int, ((local1 < arg3))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + fts5GetPoslistSize(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2[local1]))), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3))))))
        local1 = c2fb_temp_1
        c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!" nPos=%d%s")), local2, IIf(local3, StrPtr(!"*"), StrPtr(!"")))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + fts5DecodePoslist(arg0, arg1, CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2[local1]))), (IIf(((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg3 - local1))) < (local2)))))), (Cast(c2fb_c_int, (arg3 - local1))), (local2)))))))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local1 < arg3)))) Then
            ' C automatic storage declaration
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2[local1]))), CPtr(c2fb_uint64 Ptr, CPtr(c2fb_int64 Ptr, @(local4))))))))
            local1 = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + local4)))
            local0 = c2fb_temp_4
            c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!" id=%lld")), local0)
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local1
End Function

Private Sub fts5DecodeRowidList CDecl Alias "fts5DecodeRowidList" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const UByte Ptr, ByVal arg3 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 8973
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Const ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    While (-Cast(c2fb_c_int, ((local0 < arg3))))
        local2 = StrPtr(!"")
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, sqlite3Fts5GetVarint(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg2[local0]))), CPtr(c2fb_uint64 Ptr, @(local3)))))))
        local0 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, local1) + local3)))
        local1 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg2[local0]) = Cast(c2fb_c_int, &H00ULL))))) <> 0))))) Then
            c2fb_temp_2 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg2[local0]) = Cast(c2fb_c_int, &H00ULL))))) <> 0))))) Then
                c2fb_temp_3 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
                c2fb_temp_4 = StrPtr(!"+")
                local2 = c2fb_temp_4
            Else
                c2fb_temp_5 = StrPtr(!"*")
                local2 = c2fb_temp_5
            End If
        End If
        c2fb_external_sqlite3Fts5BufferAppendPrintf(arg0, CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, arg1), CPtr(ZString Ptr, StrPtr(!" %lld%s")), local1, local2)
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub

Private Sub fts5BufferAppendTerm CDecl Alias "fts5BufferAppendTerm" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9003
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_u8 Ptr
    Dim c2fb_temp_6 As UByte
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_u8 Ptr
    Dim c2fb_temp_10 As UByte
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_u8 Ptr
    Dim c2fb_temp_14 As UByte
    Dim c2fb_temp_15 As c2fb_u8 Ptr
    Dim c2fb_temp_16 As UByte

    ' C automatic storage declaration
    c2fb_temp_0 = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((arg1)->n)) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg2->n * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL))))))) <= Cast(c2fb_c_uint, ((arg1)->nSpace)))))), Cast(c2fb_c_int, &O0ULL), c2fb_external_sqlite3Fts5BufferSize((arg0), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, (arg1)), Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg2->n * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))) + (arg1)->n)))))
    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local0 < arg2->n))))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg2->p[local0]) = Cast(c2fb_c_int, &H00ULL))))) Then
                c2fb_temp_3 = CPtr(Long Ptr, @(arg1->n))
                c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
                (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
                c2fb_temp_5 = CPtr(c2fb_u8 Ptr, @(arg1->p[c2fb_temp_4]))
                c2fb_temp_6 = Cast(UByte, Cast(c2fb_c_int, 92))
                (*c2fb_temp_5) = Cast(c2fb_u8, c2fb_temp_6)
                c2fb_temp_6 = Cast(UByte, (*c2fb_temp_5))
                c2fb_temp_7 = CPtr(Long Ptr, @(arg1->n))
                c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
                (*c2fb_temp_7) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
                c2fb_temp_9 = CPtr(c2fb_u8 Ptr, @(arg1->p[c2fb_temp_8]))
                c2fb_temp_10 = Cast(UByte, Cast(c2fb_c_int, 48))
                (*c2fb_temp_9) = Cast(c2fb_u8, c2fb_temp_10)
                c2fb_temp_10 = Cast(UByte, (*c2fb_temp_9))
            Else
                c2fb_temp_11 = CPtr(Long Ptr, @(arg1->n))
                c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
                (*c2fb_temp_11) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
                c2fb_temp_13 = CPtr(c2fb_u8 Ptr, @(arg1->p[c2fb_temp_12]))
                c2fb_temp_14 = Cast(UByte, arg2->p[local0])
                (*c2fb_temp_13) = Cast(c2fb_u8, c2fb_temp_14)
                c2fb_temp_14 = Cast(UByte, (*c2fb_temp_13))
            End If
        c2fb_flow_1:
            c2fb_temp_2 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_15 = CPtr(c2fb_u8 Ptr, @(arg1->p[arg1->n]))
        c2fb_temp_16 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
        (*c2fb_temp_15) = Cast(c2fb_u8, c2fb_temp_16)
        c2fb_temp_16 = Cast(UByte, (*c2fb_temp_15))
    End If
End Sub

Private Sub fts5DecodeFunction CDecl Alias "fts5DecodeFunction" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9024
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As Const UByte Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As UByte Ptr
    Dim local9 As c2fb_Fts5Buffer
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_int64
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As Any Ptr
    Dim local13 As c2fb_Fts5Data
    Dim local14 As c2fb_Fts5DlidxLvl
    Dim c2fb_temp_7 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As c2fb_Fts5Data_ Ptr Ptr
    Dim c2fb_temp_13 As c2fb_Fts5Data Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local15 As c2fb_c_uint
    Dim local16 As c2fb_c_int
    Dim local17 As c2fb_c_int
    Dim local18 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local19 As c2fb_uint64
    Dim local20 As c2fb_c_uint Ptr
    Dim c2fb_temp_18 As c2fb_uint64
    Dim local21 As c2fb_uint64 Ptr
    Dim c2fb_temp_19 As c2fb_uint64
    Dim local22 As c2fb_Fts5Buffer
    Dim local23 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim local24 As c2fb_c_int
    Dim local25 As c2fb_c_int
    Dim local26 As c2fb_c_int
    Dim local27 As c2fb_c_int
    Dim c2fb_temp_21 As Any Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim local28 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Long Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim local29 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim local30 As c2fb_Fts5Buffer
    Dim local31 As c2fb_c_int
    Dim local32 As c2fb_c_int
    Dim local33 As c2fb_c_int
    Dim local34 As c2fb_c_int
    Dim local35 As c2fb_c_int
    Dim local36 As c2fb_c_int
    Dim local37 As c2fb_c_int
    Dim c2fb_temp_35 As Any Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As c2fb_c_int
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As c2fb_c_int
    Dim local38 As c2fb_c_int
    Dim local39 As c2fb_c_int
    Dim local40 As c2fb_c_int
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As c2fb_c_int
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As Long Ptr
    Dim c2fb_temp_55 As c2fb_c_int
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As c2fb_c_int
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local8 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local10 = Cast(c2fb_c_int, &O0ULL)
    local11 = Cast(c2fb_c_int, &O0ULL)
    local12 = ((-Cast(c2fb_c_int, ((CPtr(Any Ptr, c2fb_external_sqlite3_user_data_(arg0)) <> Cast(c2fb_c_int, &O0ULL))))))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
    c2fb_temp_1 = Cast(c2fb_int64, c2fb_external_sqlite3_value_int64_(arg2[Cast(c2fb_c_int, &O0ULL)]))
    local0 = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes_(arg2[Cast(c2fb_c_int, 1ULL)]))
    local7 = c2fb_temp_2
    c2fb_temp_3 = CPtr(Const UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob_(arg2[Cast(c2fb_c_int, 1ULL)])))
    local6 = c2fb_temp_3
    c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_int64, ((Cast(c2fb_int64, local7)) + Cast(c2fb_int64, Cast(c2fb_c_int, 8ULL)))))
    local11 = c2fb_temp_4
    c2fb_temp_5 = CPtr(UByte Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local10)), local11)))
    local8 = c2fb_temp_5
    If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    If (-Cast(c2fb_c_int, ((local7 > Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_6 = CPtr(Any Ptr, sqlite3WhereMemcpy(CPtr(Any Ptr, local8), CPtr(Const Any Ptr, local6), local7))
    End If
    fts5DecodeRowid(local0, CPtr(c2fb_c_int Ptr, @(local5)), CPtr(c2fb_c_int Ptr, @(local1)), CPtr(c2fb_c_int Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3)))
    fts5DebugRowid(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), local0)
    If local4 Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_7 = CPtr(c2fb_u8 Ptr Ptr, @(local13.p))
        c2fb_temp_8 = local8
        (*c2fb_temp_7) = CPtr(c2fb_u8 Ptr, c2fb_temp_8)
        c2fb_temp_8 = CPtr(UByte Ptr, (*c2fb_temp_7))
        c2fb_temp_9 = CPtr(Long Ptr, @(local13.nn))
        c2fb_temp_10 = Cast(c2fb_c_int, local7)
        (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
        c2fb_temp_11 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5DlidxLvl Ptr, @(local14))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5DlidxLvl))))
        c2fb_temp_12 = CPtr(c2fb_Fts5Data_ Ptr Ptr, @(local14.pData))
        c2fb_temp_13 = CPtr(_c2fb_record_c2fb_Fts5Data Ptr, CPtr(c2fb_Fts5Data Ptr, @(local13)))
        (*c2fb_temp_12) = CPtr(c2fb_Fts5Data_ Ptr, c2fb_temp_13)
        c2fb_temp_13 = CPtr(c2fb_Fts5Data Ptr, (*c2fb_temp_12))
        c2fb_temp_14 = CPtr(Long Ptr, @(local14.iLeafPgno))
        c2fb_temp_15 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
        fts5DlidxLvlNext(CPtr(_c2fb_record_c2fb_Fts5DlidxLvl Ptr, CPtr(c2fb_Fts5DlidxLvl Ptr, @(local14))))
        While (-Cast(c2fb_c_int, ((local14.bEof = Cast(c2fb_c_int, &O0ULL)))))
            c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))), CPtr(ZString Ptr, StrPtr(!" %d(%lld)")), local14.iLeafPgno, local14.iRowid)
        c2fb_flow_1:
            fts5DlidxLvlNext(CPtr(_c2fb_record_c2fb_Fts5DlidxLvl Ptr, CPtr(c2fb_Fts5DlidxLvl Ptr, @(local14))))
        Wend
        c2fb_flow_0:
    Else
        If local5 Then
            local15 = fts5GetU32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[Cast(c2fb_c_int, 4ULL)]))))
            local16 = IIf(((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 8ULL))))) <> 0)))))), Cast(c2fb_c_int, local6[Cast(c2fb_c_int, &O0ULL)]), Cast(c2fb_c_int, 8ULL))
            local17 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local7 - Cast(c2fb_c_int, 8ULL)))) \ local16))
            ' C automatic storage declaration
            c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))), CPtr(ZString Ptr, StrPtr(!" nElem=%d")), Cast(c2fb_c_int, local15))
            If local6[Cast(c2fb_c_int, 1ULL)] Then
                c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))), CPtr(ZString Ptr, StrPtr(!" 0")))
            End If
            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local18 = c2fb_temp_16
            While (-Cast(c2fb_c_int, ((local18 < local17))))
                local19 = Cast(c2fb_c_int, &O0ULL)
                If (-Cast(c2fb_c_int, ((local16 = Cast(c2fb_c_int, 4ULL))))) Then
                    local20 = CPtr(c2fb_c_uint Ptr, CPtr(UByte Ptr, @(local6[Cast(c2fb_c_int, 8ULL)])))
                    If local20[local18] Then
                        c2fb_temp_18 = Cast(c2fb_uint64, fts5GetU32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, CPtr(c2fb_c_uint Ptr, @(local20[local18]))))))
                        local19 = c2fb_temp_18
                    End If
                Else
                    local21 = CPtr(c2fb_uint64 Ptr, CPtr(UByte Ptr, @(local6[Cast(c2fb_c_int, 8ULL)])))
                    If local21[local18] Then
                        c2fb_temp_19 = Cast(c2fb_uint64, fts5GetU64(CPtr(UByte Ptr, CPtr(c2fb_uint64 Ptr, @(local21[local18])))))
                        local19 = c2fb_temp_19
                    End If
                End If
                If (-Cast(c2fb_c_int, ((local19 <> Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) Then
                    c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))), CPtr(ZString Ptr, StrPtr(!" %lld")), Cast(c2fb_int64, local19))
                End If
            c2fb_flow_3:
                c2fb_temp_17 = local18
                local18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
            Wend
            c2fb_flow_2:
        Else
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) Then
                    fts5DecodeAverages(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(Const UByte Ptr, local8), local7)
                Else
                    fts5DecodeStructure(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(Const UByte Ptr, local8), local7)
                End If
            Else
                If local12 Then
                    ' C automatic storage declaration
                    ' C automatic storage declaration
                    c2fb_temp_20 = Cast(c2fb_c_int, fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[Cast(c2fb_c_int, 2ULL)])))))
                    local23 = c2fb_temp_20
                    local24 = c2fb_temp_20
                    ' C automatic storage declaration
                    local26 = Cast(c2fb_c_int, &O0ULL)
                    ' C automatic storage declaration
                    c2fb_temp_21 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local22))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
                    If (-Cast(c2fb_c_int, ((local23 < local7)))) Then
                        c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local24 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local24]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local25))))))))
                        local24 = c2fb_temp_22
                    Else
                        c2fb_temp_23 = Cast(c2fb_c_int, local23)
                        local25 = c2fb_temp_23
                    End If
                    fts5DecodeRowidList(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[Cast(c2fb_c_int, 4ULL)]))), Cast(c2fb_c_int, (local25 - Cast(c2fb_c_int, 4ULL))))
                    c2fb_temp_24 = Cast(c2fb_c_int, local25)
                    local27 = c2fb_temp_24
                    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local27 < local23)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                        ' C automatic storage declaration
                        c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local27 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local27]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local28))))))))
                        local27 = c2fb_temp_25
                        c2fb_temp_26 = CPtr(Long Ptr, @(local22.n))
                        c2fb_temp_27 = Cast(c2fb_c_int, local26)
                        (*c2fb_temp_26) = Cast(Long, c2fb_temp_27)
                        c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
                        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local22))), local28, CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local27]))))
                        c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))), CPtr(ZString Ptr, StrPtr(!" term=")))
                        fts5BufferAppendTerm(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(c2fb_Fts5Buffer Ptr, @(local22)))
                        c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local27 + local28)))
                        local27 = c2fb_temp_28
                        If (-Cast(c2fb_c_int, ((local24 < local7)))) Then
                            ' C automatic storage declaration
                            c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local24 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local24]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local29))))))))
                            local24 = c2fb_temp_29
                            c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local25 + local29)))
                            local25 = c2fb_temp_30
                        Else
                            c2fb_temp_31 = Cast(c2fb_c_int, local23)
                            local25 = c2fb_temp_31
                        End If
                        If (-Cast(c2fb_c_int, ((local25 > local23)))) Then
                            c2fb_temp_32 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                            local10 = c2fb_temp_32
                        Else
                            fts5DecodeRowidList(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local27]))), Cast(c2fb_c_int, (local25 - local27)))
                        End If
                        c2fb_temp_33 = Cast(c2fb_c_int, local25)
                        local27 = c2fb_temp_33
                        If (-Cast(c2fb_c_int, ((local27 < local23)))) Then
                            c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local27 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local27]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local26))))))))
                            local27 = c2fb_temp_34
                        End If
                    c2fb_flow_5:
                    Wend
                    c2fb_flow_4:
                    c2fb_external_sqlite3Fts5BufferFree(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local22))))
                Else
                    ' C automatic storage declaration
                    ' C automatic storage declaration
                    ' C automatic storage declaration
                    local33 = Cast(c2fb_c_int, &O0ULL)
                    local34 = Cast(c2fb_c_int, &O0ULL)
                    local35 = Cast(c2fb_c_int, &O0ULL)
                    ' C automatic storage declaration
                    ' C automatic storage declaration
                    c2fb_temp_35 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local30))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
                    If (-Cast(c2fb_c_int, ((local7 < Cast(c2fb_c_int, 4ULL))))) Then
                        c2fb_external_sqlite3Fts5BufferSet(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))), Cast(c2fb_c_int, 7ULL), CPtr(Const UByte Ptr, StrPtr(!"corrupt")))
                        Goto c2fb_label_0
                    Else
                        c2fb_temp_36 = Cast(c2fb_c_int, fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[Cast(c2fb_c_int, &O0ULL)])))))
                        local35 = c2fb_temp_36
                        c2fb_temp_37 = Cast(c2fb_c_int, fts5GetU16(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[Cast(c2fb_c_int, 2ULL)])))))
                        local31 = c2fb_temp_37
                        c2fb_temp_38 = Cast(c2fb_c_int, c2fb_temp_37)
                        local32 = c2fb_temp_38
                        If (-Cast(c2fb_c_int, ((local32 < local7)))) Then
                            c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local32]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local34)))))
                        Else
                            If (-Cast(c2fb_c_int, ((local32 > local7)))) Then
                                c2fb_temp_39 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                                local10 = c2fb_temp_39
                                Goto c2fb_label_0
                            End If
                        End If
                    End If
                    If (-Cast(c2fb_c_int, ((local35 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_40 = Cast(c2fb_c_int, local35)
                        local36 = c2fb_temp_40
                    Else
                        If (-Cast(c2fb_c_int, ((local34 <> Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_41 = Cast(c2fb_c_int, local34)
                            local36 = c2fb_temp_41
                        Else
                            c2fb_temp_42 = Cast(c2fb_c_int, local31)
                            local36 = c2fb_temp_42
                        End If
                    End If
                    If (-Cast(c2fb_c_int, ((local36 > local7)))) Then
                        c2fb_temp_43 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                        local10 = c2fb_temp_43
                        Goto c2fb_label_0
                    End If
                    fts5DecodePoslist(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[Cast(c2fb_c_int, 4ULL)]))), Cast(c2fb_c_int, (local36 - Cast(c2fb_c_int, 4ULL))))
                    c2fb_temp_44 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((IIf(local34, local34, local31)) - local36)))
                    local37 = c2fb_temp_44
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local37 + local36)) > local7)))) Then
                        c2fb_temp_45 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                        local10 = c2fb_temp_45
                        Goto c2fb_label_0
                    End If
                    fts5DecodeDoclist(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local36]))), local37)
                    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local32 < local7)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                        local38 = ((-Cast(c2fb_c_int, ((local32 = local31)))))
                        ' C automatic storage declaration
                        ' C automatic storage declaration
                        c2fb_temp_46 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local32 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local32]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local39))))))))
                        local32 = c2fb_temp_46
                        c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local33 + local39)))
                        local33 = c2fb_temp_47
                        c2fb_temp_48 = Cast(c2fb_c_int, local33)
                        local36 = c2fb_temp_48
                        If (-Cast(c2fb_c_int, ((local32 < local7)))) Then
                            c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local32]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local39)))))
                            c2fb_temp_49 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local33 + local39)))
                            local40 = c2fb_temp_49
                        Else
                            c2fb_temp_50 = Cast(c2fb_c_int, local31)
                            local40 = c2fb_temp_50
                        End If
                        If (-Cast(c2fb_c_int, ((local40 > local31)))) Then
                            c2fb_temp_51 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                            local10 = c2fb_temp_51
                            Goto c2fb_flow_6
                        End If
                        If (-Cast(c2fb_c_int, ((local38 = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_52 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local36 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local36]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local39))))))))
                            local36 = c2fb_temp_52
                            If (-Cast(c2fb_c_int, ((local39 > local30.n)))) Then
                                c2fb_temp_53 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                                local10 = c2fb_temp_53
                                Goto c2fb_flow_6
                            End If
                            c2fb_temp_54 = CPtr(Long Ptr, @(local30.n))
                            c2fb_temp_55 = Cast(c2fb_c_int, local39)
                            (*c2fb_temp_54) = Cast(Long, c2fb_temp_55)
                            c2fb_temp_55 = Cast(c2fb_c_int, (*c2fb_temp_54))
                        End If
                        c2fb_temp_56 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local36 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local36]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @((local39))))))))
                        local36 = c2fb_temp_56
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local36 + local39)) > local7)))) Then
                            c2fb_temp_57 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                            local10 = c2fb_temp_57
                            Goto c2fb_flow_6
                        End If
                        c2fb_external_sqlite3Fts5BufferAppendBlob(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local30))), local39, CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local36]))))
                        c2fb_temp_58 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local36 + local39)))
                        local36 = c2fb_temp_58
                        c2fb_external_sqlite3Fts5BufferAppendPrintf(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))), CPtr(ZString Ptr, StrPtr(!" term=")))
                        fts5BufferAppendTerm(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(c2fb_Fts5Buffer Ptr, @(local30)))
                        c2fb_temp_59 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local36 + fts5DecodeDoclist(CPtr(c2fb_c_int Ptr, @(local10)), CPtr(c2fb_Fts5Buffer Ptr, @(local9)), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local8[local36]))), Cast(c2fb_c_int, (local40 - local36))))))
                        local36 = c2fb_temp_59
                    c2fb_flow_7:
                    Wend
                    c2fb_flow_6:
                    c2fb_external_sqlite3Fts5BufferFree(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local30))))
                End If
            End If
        End If
    End If
    c2fb_label_0:
    sqlite3_free(CPtr(Any Ptr, local8))
    If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_text_(arg0, CPtr(Const ZString Ptr, local9.p), local9.n, (CPtr(c2fb_callback_8, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
    Else
        c2fb_external_sqlite3_result_error_code_(arg0, local10)
    End If
    c2fb_external_sqlite3Fts5BufferFree(CPtr(_c2fb_record_c2fb_Fts5Buffer Ptr, CPtr(c2fb_Fts5Buffer Ptr, @(local9))))
End Sub

Private Sub fts5RowidFunction CDecl Alias "fts5RowidFunction" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9259
    Dim local0 As Const ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_int64

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_error_(arg0, StrPtr(!"should be: fts5_rowid(subject, ....)"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    Else
        c2fb_temp_0 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text_(arg2[Cast(c2fb_c_int, &O0ULL)])))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(local0, StrPtr(!"segment")))))) Then
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 3ULL))))) Then
                c2fb_external_sqlite3_result_error_(arg0, StrPtr(!"should be: fts5_rowid('segment', segid, pgno))"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            Else
                c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int_(arg2[Cast(c2fb_c_int, 1ULL)]))
                local2 = c2fb_temp_1
                c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int_(arg2[Cast(c2fb_c_int, 2ULL)]))
                local3 = c2fb_temp_2
                c2fb_temp_3 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_int64, (local2)) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 1ULL))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, (Cast(c2fb_c_int, 31ULL) + Cast(c2fb_c_int, 5ULL))))))))) + (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_int, &O0ULL))) Shl (Cast(c2fb_c_int, 31ULL))))))) + (Cast(c2fb_int64, (local3)))))))
                local1 = c2fb_temp_3
                c2fb_external_sqlite3_result_int64_(arg0, local1)
            End If
        Else
            c2fb_external_sqlite3_result_error_(arg0, StrPtr(!"first arg to fts5_rowid() must be 'segment'"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        End If
    End If
End Sub

Private Function fts5structConnectMethod CDecl Alias "fts5structConnectMethod" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As c2fb_sqlite3_vtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9310
    Dim local0 As c2fb_source_record_6 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_source_record_6 Ptr
    Dim c2fb_temp_2 As c2fb_sqlite3_vtab Ptr Ptr
    Dim c2fb_temp_3 As c2fb_sqlite3_vtab Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_declare_vtab_(arg0, StrPtr(!"CREATE TABLE xyz(level, segment, merge, segid, leaf1, leaf2, loc1, loc2, npgtombstone, nentrytombstone, nentry, struct HIDDEN);")))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = CPtr(c2fb_source_record_6 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local1)), Cast(c2fb_size_t, SizeOf(c2fb_source_record_6)))))
        local0 = c2fb_temp_1
    End If
    c2fb_temp_2 = CPtr(c2fb_sqlite3_vtab Ptr Ptr, @((*arg4)))
    c2fb_temp_3 = CPtr(_c2fb_record_c2fb_sqlite3_vtab Ptr, CPtr(c2fb_sqlite3_vtab Ptr, local0))
    (*c2fb_temp_2) = c2fb_temp_3
    Return local1
End Function

Private Function fts5structBestIndexMethod CDecl Alias "fts5structBestIndexMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_index_info Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9338
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_index_constraint Ptr
    Dim c2fb_temp_0 As Double Ptr
    Dim c2fb_temp_1 As Double
    Dim c2fb_temp_2 As c2fb_sqlite3_int64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_sqlite3_index_constraint Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_sqlite3_index_constraint Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, 19ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Double Ptr, @(arg1->estimatedCost))
    c2fb_temp_1 = Cast(Double, __c2fb_double_value(Cast(Double, Cast(c2fb_c_int, 100ULL))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_sqlite3_int64 Ptr, @(arg1->estimatedRows))
    c2fb_temp_3 = Cast(c2fb_int64, Cast(c2fb_c_int, 100ULL))
    (*c2fb_temp_2) = Cast(c2fb_sqlite3_int64, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_int64, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(Long Ptr, @(arg1->idxNum))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_6
    c2fb_temp_7 = CPtr(_c2fb_record_c2fb_sqlite3_index_constraint Ptr, CPtr(c2fb_sqlite3_index_constraint Ptr, arg1->aConstraint))
    local2 = c2fb_temp_7
    While (-Cast(c2fb_c_int, ((local0 < arg1->nConstraint))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->usable) = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_1
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local2->op) = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2->iColumn = Cast(c2fb_c_int, 11ULL))))) <> 0))))) Then
            c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_10
            c2fb_temp_11 = CPtr(UByte Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local0].omit))
            c2fb_temp_12 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_11) = c2fb_temp_12
            c2fb_temp_13 = CPtr(Long Ptr, @(CPtr(c2fb_sqlite3_index_constraint_usage Ptr, CPtr(c2fb_sqlite3_index_constraint_usage Ptr, arg1->aConstraintUsage))[local0].argvIndex))
            c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
            c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_8 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
        c2fb_temp_9 = local2
        local2 = (c2fb_temp_9 + 1)
    Wend
    c2fb_flow_0:
    Return local1
End Function

Private Function fts5structDisconnectMethod CDecl Alias "fts5structDisconnectMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9363
    Dim local0 As c2fb_source_record_6 Ptr

    local0 = CPtr(c2fb_source_record_6 Ptr, arg0)
    sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Function fts5structOpenMethod CDecl Alias "fts5structOpenMethod" (ByVal arg0 As c2fb_sqlite3_vtab Ptr, ByVal arg1 As c2fb_sqlite3_vtab_cursor Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9372
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_7 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_7 Ptr
    Dim c2fb_temp_1 As c2fb_sqlite3_vtab_cursor Ptr Ptr
    Dim c2fb_temp_2 As c2fb_sqlite3_vtab_cursor Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_source_record_7 Ptr, CPtr(Any Ptr, c2fb_external_sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), Cast(c2fb_size_t, SizeOf(c2fb_source_record_7)))))
    local1 = c2fb_temp_0
    c2fb_temp_1 = CPtr(c2fb_sqlite3_vtab_cursor Ptr Ptr, @((*arg1)))
    c2fb_temp_2 = CPtr(_c2fb_record_c2fb_sqlite3_vtab_cursor Ptr, CPtr(c2fb_sqlite3_vtab_cursor Ptr, local1))
    (*c2fb_temp_1) = c2fb_temp_2
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Function fts5structCloseMethod CDecl Alias "fts5structCloseMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9385
    Dim local0 As c2fb_source_record_7 Ptr

    local0 = CPtr(c2fb_source_record_7 Ptr, arg0)
    fts5StructureRelease(CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, local0->pStruct)))
    sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Function fts5structNextMethod CDecl Alias "fts5structNextMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9396
    Dim local0 As c2fb_source_record_7 Ptr
    Dim local1 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_Fts5Structure Ptr Ptr
    Dim c2fb_temp_9 As c2fb_Fts5Structure Ptr

    local0 = CPtr(c2fb_source_record_7 Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Structure Ptr, local0->pStruct)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(local0->iSeg))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(local0->iRowid))
    c2fb_temp_3 = (*c2fb_temp_2)
    (*c2fb_temp_2) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->iLevel < local1->nLevel)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->iSeg >= CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local1)))[local0->iLevel].nSeg)))) <> 0)))))
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(local0->iLevel))
        c2fb_temp_5 = (*c2fb_temp_4)
        (*c2fb_temp_4) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(local0->iSeg))
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_6) = c2fb_temp_7
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0->iLevel >= local1->nLevel)))) Then
        fts5StructureRelease(CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, local0->pStruct)))
        c2fb_temp_8 = CPtr(c2fb_Fts5Structure Ptr Ptr, @(local0->pStruct))
        c2fb_temp_9 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_8) = c2fb_temp_9
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Function fts5structEofMethod CDecl Alias "fts5structEofMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9418
    Dim local0 As c2fb_source_record_7 Ptr

    local0 = CPtr(c2fb_source_record_7 Ptr, arg0)
    Return (-Cast(c2fb_c_int, ((CPtr(c2fb_Fts5Structure Ptr, local0->pStruct) = Cast(c2fb_c_int, &O0ULL)))))
End Function

Private Function fts5structRowidMethod CDecl Alias "fts5structRowidMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9423
    Dim local0 As c2fb_source_record_7 Ptr
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    local0 = CPtr(c2fb_source_record_7 Ptr, arg0)
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_int64, local0->iRowid)
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Function fts5structColumnMethod CDecl Alias "fts5structColumnMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_sqlite3_context Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9436
    Dim local0 As c2fb_source_record_7 Ptr
    Dim local1 As c2fb_Fts5Structure Ptr
    Dim local2 As c2fb_Fts5StructureSegment Ptr

    local0 = CPtr(c2fb_source_record_7 Ptr, arg0)
    local1 = CPtr(c2fb_Fts5Structure Ptr, local0->pStruct)
    local2 = CPtr(c2fb_Fts5StructureSegment Ptr, @(CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureSegment Ptr, CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local1)))[local0->iLevel].aSeg))[local0->iSeg]))
    Select Case arg2
        Case Cast(c2fb_c_int, &O0ULL)
            c2fb_external_sqlite3_result_int_(arg1, local0->iLevel)
        Case Cast(c2fb_c_int, 1ULL)
            c2fb_external_sqlite3_result_int_(arg1, local0->iSeg)
        Case Cast(c2fb_c_int, 2ULL)
            c2fb_external_sqlite3_result_int_(arg1, (-Cast(c2fb_c_int, ((local0->iSeg < CPtr(c2fb_Fts5StructureLevel Ptr, (c2fb_Fts5Structure_aLevel_tail_ptr(local1)))[local0->iLevel].nMerge)))))
        Case Cast(c2fb_c_int, 3ULL)
            c2fb_external_sqlite3_result_int_(arg1, local2->iSegid)
        Case Cast(c2fb_c_int, 4ULL)
            c2fb_external_sqlite3_result_int_(arg1, local2->pgnoFirst)
        Case Cast(c2fb_c_int, 5ULL)
            c2fb_external_sqlite3_result_int_(arg1, local2->pgnoLast)
        Case Cast(c2fb_c_int, 6ULL)
            c2fb_external_sqlite3_result_int64_(arg1, local2->iOrigin1)
        Case Cast(c2fb_c_int, 7ULL)
            c2fb_external_sqlite3_result_int64_(arg1, local2->iOrigin2)
        Case Cast(c2fb_c_int, 8ULL)
            c2fb_external_sqlite3_result_int_(arg1, local2->nPgTombstone)
        Case Cast(c2fb_c_int, 9ULL)
            c2fb_external_sqlite3_result_int64_(arg1, local2->nEntryTombstone)
        Case Cast(c2fb_c_int, 10ULL)
            c2fb_external_sqlite3_result_int64_(arg1, local2->nEntry)
    End Select
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Function fts5structFilterMethod CDecl Alias "fts5structFilterMethod" (ByVal arg0 As c2fb_sqlite3_vtab_cursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_value Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/fts5/fts5_index.c
' c2fb source-line: 9489
    Dim local0 As c2fb_source_record_7 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As Const UByte Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5Structure Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Structure Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Const UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_7 Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    fts5StructureRelease(CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, CPtr(c2fb_Fts5Structure Ptr, local0->pStruct)))
    c2fb_temp_0 = CPtr(c2fb_Fts5Structure Ptr Ptr, @(local0->pStruct))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Structure Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes_(arg4[Cast(c2fb_c_int, &O0ULL)]))
    local3 = c2fb_temp_2
    c2fb_temp_3 = CPtr(Const UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob_(arg4[Cast(c2fb_c_int, &O0ULL)])))
    local2 = c2fb_temp_3
    c2fb_temp_4 = Cast(c2fb_c_int, fts5StructureDecode(local2, local3, Cast(c2fb_c_int, &O0ULL), CPtr(_c2fb_record_c2fb_Fts5Structure Ptr Ptr, CPtr(c2fb_Fts5Structure Ptr Ptr, @(local0->pStruct)))))
    local1 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @(local0->iLevel))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local0->iRowid))
        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(local0->iSeg))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_9) = c2fb_temp_10
        c2fb_temp_11 = Cast(c2fb_c_int, fts5structNextMethod(arg0))
        local1 = c2fb_temp_11
    End If
    Return local1
End Function

Private Dim Shared As Const c2fb_Fts5SqliteModule fts5structure_module = _
    Type<c2fb_Fts5SqliteModule>( _
        0, _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, ProcPtr(fts5structConnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5structBestIndexMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5structDisconnectMethod)), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, ProcPtr(fts5structOpenMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5structCloseMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5structFilterMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5structNextMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5structEofMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5structColumnMethod)), _
        CPtr(Any Ptr, ProcPtr(fts5structRowidMethod)), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0), _
        CPtr(Any Ptr, 0) _
    )

Function sqlite3Fts5IndexInit CDecl Alias "sqlite3Fts5IndexInit" (ByVal db As c2fb_sqlite3 Ptr) As c2fb_c_int
    Dim rc As c2fb_c_int

    rc = sqlite3_create_function( _
        CPtr(Any Ptr, db), StrPtr(!"fts5_decode"), 2, SQLITE_UTF8, _
        CPtr(Any Ptr, 0), CPtr(Any Ptr, ProcPtr(fts5DecodeFunction)), _
        CPtr(Any Ptr, 0), CPtr(Any Ptr, 0))
    If rc = SQLITE_OK Then
        rc = sqlite3_create_function( _
            CPtr(Any Ptr, db), StrPtr(!"fts5_decode_none"), 2, SQLITE_UTF8, _
            CPtr(Any Ptr, db), CPtr(Any Ptr, ProcPtr(fts5DecodeFunction)), _
            CPtr(Any Ptr, 0), CPtr(Any Ptr, 0))
    End If
    If rc = SQLITE_OK Then
        rc = sqlite3_create_function( _
            CPtr(Any Ptr, db), StrPtr(!"fts5_rowid"), -1, SQLITE_UTF8, _
            CPtr(Any Ptr, 0), CPtr(Any Ptr, ProcPtr(fts5RowidFunction)), _
            CPtr(Any Ptr, 0), CPtr(Any Ptr, 0))
    End If
    If rc = SQLITE_OK Then
        rc = sqlite3_create_module( _
            CPtr(Any Ptr, db), StrPtr(!"fts5_structure"), _
            CPtr(Const Any Ptr, @fts5structure_module), CPtr(Any Ptr, 0))
    End If
    Return rc
End Function

#endif

#endif

/' end of sqlite3_bulk_fts5_index.bas '/
