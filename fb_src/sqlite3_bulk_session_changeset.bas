/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_bulk_session_changeset.bas

    Purpose:

        Port the C2FB-supported Session lifecycle and changeset routines from
        ext/session/sqlite3session.c.

    Responsibilities:

        - Create and manage Session handles and attached-table state.
        - Encode, iterate, merge, and rebase changeset records.
        - Preserve the upstream C ABI for translated Session entry points.

    This file intentionally does NOT contain:

        - Session test support or the changeset command-line utility.
        - C bodies that C2FB still rejects or marks as dependencies.
'/

#lang "fb"
#if defined(SQLITE_ENABLE_SESSION) AndAlso _
    defined(SQLITE_ENABLE_PREUPDATE_HOOK)
#include once "sqlite3_btree.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_expr_types.bi"
#include once "sqlite3_hash_types.bi"
#include once "sqlite3_mutex.bi"
#include once "sqlite3_pager.bi"
#include once "sqlite3_parser_types.bi"
#include once "sqlite3_session_types.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_varint.bi"
#include once "sqlite3_vdbe_core.bi"
#include once "sqlite3_vdbe_mem_types.bi"
#include once "sqlite3_vdbe_record.bi"

/' ------------------------------------------------------------------------- '/
/' C2FB ABI types, Session records, and inter-unit declarations               '/
/' ------------------------------------------------------------------------- '/

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

#include once "sqlite3_session_types.bi"
#include once "sqlite3_vdbe_record.bi"
#include once "sqlite3_mutex.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_vdbe_mem_types.bi"
#include once "sqlite3_vdbe_core.bi"

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

Private Type c2fb_source_record_50
    aBuf As UByte Ptr
    nBuf As c2fb_c_int
    nAlloc As c2fb_c_int
End Type

Private Type c2fb_source_record_51
    pNext As c2fb_source_record_51 Ptr
    zName As ZString Ptr
    nCol As c2fb_c_int
    nTotalCol As c2fb_c_int
    bStat1 As c2fb_c_int
    bRowid As c2fb_c_int
    azCol As Const ZString Ptr Ptr
    azDflt As Const ZString Ptr Ptr
    aiIdx As c2fb_c_int Ptr
    abPK As UByte Ptr
    nEntry As c2fb_c_int
    nChange As c2fb_c_int
    apChange As Any Ptr Ptr
    pDfltStmt As SqliteVdbe Ptr
End Type

Private Type c2fb_source_record_52
    op As UByte
    bIndirect As UByte
    nRecordField As UShort
    nMaxSize As c2fb_c_int
    nRecord As c2fb_c_int
    aRecord As UByte Ptr
    pNext As c2fb_source_record_52 Ptr
End Type

Private Type c2fb_source_record_53
    pStmt As SqliteVdbe Ptr
    bRowid As c2fb_c_int
    nOldOff As c2fb_c_int
End Type

Private Type c2fb_source_record_54
    pStmt As SqliteVdbe Ptr
    aMask As c2fb_c_uint Ptr
    pNext As c2fb_source_record_54 Ptr
End Type

Private Type c2fb_source_record_55
    db As sqlite3 Ptr
    pDelete As SqliteVdbe Ptr
    pInsert As SqliteVdbe Ptr
    pSelect As SqliteVdbe Ptr
    nCol As c2fb_c_int
    azCol As Const ZString Ptr Ptr
    abPK As UByte Ptr
    aUpdateMask As c2fb_c_uint Ptr
    pUp As c2fb_source_record_54 Ptr
    bStat1 As c2fb_c_int
    bDeferConstraints As c2fb_c_int
    bInvertConstraints As c2fb_c_int
    constraints As c2fb_source_record_50
    rebase As c2fb_source_record_50
    bRebaseStarted As UByte
    bRebase As UByte
    bIgnoreNoop As UByte
    bNoUpdateLoop As UByte
    bRowid As c2fb_c_int
    zErr As ZString Ptr
End Type

Private Type c2fb_source_record_56
    pTab As c2fb_source_record_51 Ptr
    bIndirect As c2fb_c_int
    eOp As c2fb_c_int
    nBufAlloc As c2fb_c_int
    aBuf As c2fb_source_record_50 Ptr
    record As c2fb_source_record_50
End Type

Private Type c2fb_source_record_57
    rc As c2fb_c_int
    bPatch As c2fb_c_int
    pList As c2fb_source_record_51 Ptr
    rec As c2fb_source_record_50
    db As sqlite3 Ptr
    zDb As ZString Ptr
    cd As c2fb_source_record_56
End Type

Private Type c2fb_source_record_58
    grp As c2fb_source_record_57
End Type

Type sqlite3MemDestructor As Sub CDecl (ByVal p As Any Ptr)
Type c2fb_callback_2 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As SQLITE_C_INT) As SQLITE_C_INT
Type c2fb_callback_23 As Function CDecl(ByVal arg0 As SQLITE_C_INT, ByVal arg1 As Const Any Ptr, ByVal arg2 As sqlite3VdbeUnpackedRecord Ptr) As SQLITE_C_INT
Type c2fb_callback_22 As Sub CDecl(ByVal arg0 As PgHdr Ptr)
Type c2fb_callback_223 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Type c2fb_callback_230 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_5 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Type c2fb_callback_140 As Function CDecl(ByVal arg0 As Any Ptr) As c2fb_c_int
Type c2fb_callback_211 As Sub CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_int64, ByVal arg6 As c2fb_int64)
Type c2fb_callback_225 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Type c2fb_callback_226 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_229 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteChangesetIter Ptr) As c2fb_c_int
Type c2fb_callback_235 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As SqliteChangesetIter Ptr) As c2fb_c_int
Declare Function sqlite3WhereMemset CDecl Alias "memset" (ByVal pDestination As Any Ptr, ByVal value As SQLITE_C_INT, ByVal byteCount As SQLITE_SIZE_T) As Any Ptr
Declare Function sqlite3WhereMemcpy CDecl Alias "memcpy" (ByVal pDestination As Any Ptr, ByVal pSource As Const Any Ptr, ByVal byteCount As SQLITE_SIZE_T) As Any Ptr
Declare Function c2fb_sqlite3session_attach CDecl Alias "sqlite3session_attach" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changeset_finalize CDecl Alias "sqlite3changeset_finalize" (ByVal arg0 As SqliteChangesetIter Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changeset_new CDecl Alias "sqlite3changeset_new" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changeset_next CDecl Alias "sqlite3changeset_next" (ByVal arg0 As SqliteChangesetIter Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changeset_old CDecl Alias "sqlite3changeset_old" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changeset_op CDecl Alias "sqlite3changeset_op" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changeset_pk CDecl Alias "sqlite3changeset_pk" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changeset_start CDecl Alias "sqlite3changeset_start" (ByVal arg0 As SqliteChangesetIter Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changeset_start_strm CDecl Alias "sqlite3changeset_start_strm" (ByVal arg0 As SqliteChangesetIter Ptr Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changegroup_add CDecl Alias "sqlite3changegroup_add" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function c2fb_sqlite3changegroup_add_strm CDecl Alias "sqlite3changegroup_add_strm" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Sub c2fb_sqlite3changegroup_delete CDecl Alias "sqlite3changegroup_delete" (ByVal arg0 As SqliteChangegroup Ptr)
Declare Function sqlite3changegroup_new CDecl Alias "sqlite3changegroup_new" (ByVal arg0 As SqliteChangegroup Ptr Ptr) As c2fb_c_int
Declare Function sqlite3changegroup_output CDecl Alias "sqlite3changegroup_output" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Any Ptr Ptr) As c2fb_c_int
Declare Function sqlite3changegroup_output_strm CDecl Alias "sqlite3changegroup_output_strm" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr) As c2fb_c_int

Declare Function sqlite3_changes CDecl Alias "sqlite3_changes" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function sqlite3_malloc CDecl Alias "sqlite3_malloc" (ByVal arg0 As c2fb_c_int) As Any Ptr
Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_realloc CDecl Alias "sqlite3_realloc" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function sqlite3_msize CDecl Alias "sqlite3_msize" (ByVal arg0 As Any Ptr) As c2fb_uint64
Declare Function sqlite3_bind_parameter_count CDecl Alias "sqlite3_bind_parameter_count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_column_double CDecl Alias "sqlite3_column_double" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Double
Declare Function sqlite3_column_type CDecl Alias "sqlite3_column_type" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3_strnicmp CDecl Alias "sqlite3_strnicmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3CorruptError CDecl Alias "sqlite3CorruptError" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Strlen30 CDecl Alias "sqlite3Strlen30" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function sessionVarintPut CDecl Alias "sessionVarintPut" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sessionVarintLen CDecl Alias "sessionVarintLen" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
Declare Function sessionVarintGet CDecl Alias "sessionVarintGet" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionVarintGetSafe CDecl Alias "sessionVarintGetSafe" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionGetI64 CDecl Alias "sessionGetI64" (ByVal arg0 As UByte Ptr) As c2fb_int64
Declare Sub sessionPutI64 CDecl Alias "sessionPutI64" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_int64)
Declare Sub sessionPutDouble CDecl Alias "sessionPutDouble" (ByVal arg0 As UByte Ptr, ByVal arg1 As Double)
Declare Function sessionSerializeValue CDecl Alias "sessionSerializeValue" (ByVal arg0 As UByte Ptr, ByVal arg1 As SqliteVdbeMem Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sessionHashAppendI64 CDecl Alias "sessionHashAppendI64" (ByVal arg0 As c2fb_c_uint, ByVal arg1 As c2fb_int64) As c2fb_c_uint
Declare Function sessionHashAppendBlob CDecl Alias "sessionHashAppendBlob" (ByVal arg0 As c2fb_c_uint, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr) As c2fb_c_uint
Declare Function sessionHashAppendType CDecl Alias "sessionHashAppendType" (ByVal arg0 As c2fb_c_uint, ByVal arg1 As c2fb_c_int) As c2fb_c_uint
Declare Function sessionSerialLen CDecl Alias "sessionSerialLen" (ByVal arg0 As Const UByte Ptr) As c2fb_c_int
Declare Function sessionChangeHash CDecl Alias "sessionChangeHash" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_uint
Declare Function sessionChangeEqual CDecl Alias "sessionChangeEqual" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr) As c2fb_c_int
Declare Function sessionBufferGrow CDecl Alias "sessionBufferGrow" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub sessionAppendStr CDecl Alias "sessionAppendStr" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub sessionAppendPrintf CDecl Alias "sessionAppendPrintf" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Const ZString Ptr, ...)
Declare Function sessionPrepareDfltStmt CDecl Alias "sessionPrepareDfltStmt" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_51 Ptr, ByVal arg2 As SqliteVdbe Ptr Ptr) As c2fb_c_int
Declare Sub sessionFinalizeStmt CDecl Alias "sessionFinalizeStmt" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int Ptr)
Declare Function sessionPreupdateOld CDecl Alias "sessionPreupdateOld" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function sessionPreupdateNew CDecl Alias "sessionPreupdateNew" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function sessionPreupdateCount CDecl Alias "sessionPreupdateCount" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sessionPreupdateDepth CDecl Alias "sessionPreupdateDepth" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sessionDiffOld CDecl Alias "sessionDiffOld" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function sessionDiffNew CDecl Alias "sessionDiffNew" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function sessionDiffCount CDecl Alias "sessionDiffCount" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sessionDiffDepth CDecl Alias "sessionDiffDepth" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sessionExprComparePK CDecl Alias "sessionExprComparePK" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As UByte Ptr) As ZString Ptr
Declare Function sessionExprCompareOther CDecl Alias "sessionExprCompareOther" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As UByte Ptr) As ZString Ptr
Declare Function sessionSelectFindNew CDecl Alias "sessionSelectFindNew" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr) As ZString Ptr
Declare Function sessionAllCols CDecl Alias "sessionAllCols" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_source_record_51 Ptr) As ZString Ptr
Declare Sub sessionAppendValue CDecl Alias "sessionAppendValue" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As SqliteVdbeMem Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub sessionAppendByte CDecl Alias "sessionAppendByte" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As UByte, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub sessionAppendVarint CDecl Alias "sessionAppendVarint" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub sessionAppendBlob CDecl Alias "sessionAppendBlob" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
Declare Sub sessionAppendInteger CDecl Alias "sessionAppendInteger" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub sessionAppendIdent CDecl Alias "sessionAppendIdent" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub sessionAppendCol CDecl Alias "sessionAppendCol" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As SqliteVdbe Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
Declare Function sessionAppendUpdate CDecl Alias "sessionAppendUpdate" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbe Ptr, ByVal arg3 As c2fb_source_record_52 Ptr, ByVal arg4 As UByte Ptr) As c2fb_c_int
Declare Function sessionAppendDelete CDecl Alias "sessionAppendDelete" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_52 Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr) As c2fb_c_int
Declare Sub sessionPrepareMprintf CDecl Alias "sessionPrepareMprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As SqliteVdbe Ptr Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As Const ZString Ptr, ...)
Declare Function sessionSelectStmt CDecl Alias "sessionSelectStmt" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As UByte Ptr, ByVal arg8 As SqliteVdbe Ptr Ptr, ByVal arg9 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sessionSelectBind CDecl Alias "sessionSelectBind" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_source_record_52 Ptr) As c2fb_c_int
Declare Sub sessionAppendTableHdr CDecl Alias "sessionAppendTableHdr" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_51 Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Sub sessionSkipRecord CDecl Alias "sessionSkipRecord" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As c2fb_c_int)
Declare Function sessionValueSetStr CDecl Alias "sessionValueSetStr" (ByVal arg0 As SqliteVdbeMem Ptr, ByVal arg1 As UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte) As c2fb_c_int
Declare Function sessionBindValue CDecl Alias "sessionBindValue" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function sessionBindRow CDecl Alias "sessionBindRow" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_callback_223, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function sessionUniqueColumns CDecl Alias "sessionUniqueColumns" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr, ByVal arg3 As UByte Ptr) As c2fb_c_int
Declare Function sessionChangeMerge CDecl Alias "sessionChangeMerge" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_52 Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As UByte Ptr, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_source_record_52 Ptr Ptr) As c2fb_c_int
Declare Function sessionChangesetCheckCompat CDecl Alias "sessionChangesetCheckCompat" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr) As c2fb_c_int
Declare Function sessionChangesetExtendRecord CDecl Alias "sessionChangesetExtendRecord" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_source_record_51 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_source_record_50 Ptr) As c2fb_c_int
Declare Function sessionChangegroupOutput CDecl Alias "sessionChangegroupOutput" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
Declare Sub sessionAppendRecordMerge CDecl Alias "sessionAppendRecordMerge" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int Ptr)
Declare Function checkChangeParams CDecl Alias "checkChangeParams" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_source_record_50 Ptr Ptr) As c2fb_c_int


Declare Function sessionMalloc64 CDecl Alias "sessionMalloc64" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Sub sessionFree CDecl Alias "sessionFree" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As Any Ptr)
Declare Function sessionPreupdateHash CDecl Alias "sessionPreupdateHash" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteSessionTable Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionPreupdateEqual CDecl Alias "sessionPreupdateEqual" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteSessionTable Ptr, ByVal arg3 As SqliteSessionChange Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function sessionGrowHash CDecl Alias "sessionGrowHash" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteSessionTable Ptr) As c2fb_c_int
Declare Function sessionTableInfo CDecl Alias "sessionTableInfo" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As Const ZString Ptr Ptr Ptr, ByVal arg8 As Const ZString Ptr Ptr Ptr, ByVal arg9 As c2fb_c_int Ptr Ptr, ByVal arg10 As UByte Ptr Ptr, ByVal arg11 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionInitTable CDecl Alias "sessionInitTable" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr, ByVal arg2 As sqlite3 Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
Declare Function sessionReinitTable CDecl Alias "sessionReinitTable" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr) As c2fb_c_int
Declare Sub sessionUpdateOneChange CDecl Alias "sessionUpdateOneChange" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As SqliteSessionChange Ptr Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As SqliteVdbe Ptr)
Declare Function sessionUpdateChanges CDecl Alias "sessionUpdateChanges" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr) As c2fb_c_int
Declare Function sessionStat1Old CDecl Alias "sessionStat1Old" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function sessionStat1New CDecl Alias "sessionStat1New" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function sessionStat1Count CDecl Alias "sessionStat1Count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sessionStat1Depth CDecl Alias "sessionStat1Depth" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sessionUpdateMaxSize CDecl Alias "sessionUpdateMaxSize" (ByVal arg0 As c2fb_c_int, ByVal arg1 As SqliteSession Ptr, ByVal arg2 As SqliteSessionTable Ptr, ByVal arg3 As SqliteSessionChange Ptr) As c2fb_c_int
Declare Sub sessionPreupdateOneChange CDecl Alias "sessionPreupdateOneChange" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteSession Ptr, ByVal arg3 As SqliteSessionTable Ptr)
Declare Function sessionFindTable CDecl Alias "sessionFindTable" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As SqliteSessionTable Ptr Ptr) As c2fb_c_int
Declare Sub xPreUpdate CDecl Alias "xPreUpdate" (ByVal arg0 As Any Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_int64, ByVal arg6 As c2fb_int64)
Declare Sub sessionPreupdateHooks CDecl Alias "sessionPreupdateHooks" (ByVal arg0 As SqliteSession Ptr)
Declare Sub sessionDiffHooks CDecl Alias "sessionDiffHooks" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionDiffCtx Ptr)
Declare Function sessionDiffFindNew CDecl Alias "sessionDiffFindNew" (ByVal arg0 As c2fb_c_int, ByVal arg1 As SqliteSession Ptr, ByVal arg2 As SqliteSessionTable Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As ZString Ptr) As c2fb_c_int
Declare Function sessionDiffFindModified CDecl Alias "sessionDiffFindModified" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
Declare Sub sessionDeleteTable CDecl Alias "sessionDeleteTable" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr)
Declare Function sessionGenerateChangeset CDecl Alias "sessionGenerateChangeset" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_callback_230, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As Any Ptr Ptr) As c2fb_c_int
Declare Function sessionChangesetStart CDecl Alias "sessionChangesetStart" (ByVal arg0 As SqliteChangesetIter Ptr Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int) As c2fb_c_int
Declare Sub sessionDiscardData CDecl Alias "sessionDiscardData" (ByVal arg0 As SqliteSessionInput Ptr)
Declare Function sessionInputBuffer CDecl Alias "sessionInputBuffer" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sessionReadRecord CDecl Alias "sessionReadRecord" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As SqliteVdbeMem Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionChangesetBufferTblhdr CDecl Alias "sessionChangesetBufferTblhdr" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionChangesetBufferRecord CDecl Alias "sessionChangesetBufferRecord" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionChangesetReadTblhdr CDecl Alias "sessionChangesetReadTblhdr" (ByVal arg0 As SqliteChangesetIter Ptr) As c2fb_c_int
Declare Function sessionChangesetNextOne CDecl Alias "sessionChangesetNextOne" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionChangesetNext CDecl Alias "sessionChangesetNext" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionChangesetInvert CDecl Alias "sessionChangesetInvert" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
Declare Function sessionUpdateFind CDecl Alias "sessionUpdateFind" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As SqliteSessionApplyCtx Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As SqliteVdbe Ptr Ptr) As c2fb_c_int
Declare Function sessionSeekToRow CDecl Alias "sessionSeekToRow" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As SqliteSessionApplyCtx Ptr) As c2fb_c_int
Declare Function sessionRebaseAdd CDecl Alias "sessionRebaseAdd" (ByVal arg0 As SqliteSessionApplyCtx Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteChangesetIter Ptr) As c2fb_c_int
Declare Function sessionConflictHandler CDecl Alias "sessionConflictHandler" (ByVal arg0 As c2fb_c_int, ByVal arg1 As SqliteSessionApplyCtx Ptr, ByVal arg2 As SqliteChangesetIter Ptr, ByVal arg3 As c2fb_callback_229, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionApplyOneOp CDecl Alias "sessionApplyOneOp" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As SqliteSessionApplyCtx Ptr, ByVal arg2 As c2fb_callback_229, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function sessionApplyOneWithRetry CDecl Alias "sessionApplyOneWithRetry" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As SqliteSessionApplyCtx Ptr, ByVal arg3 As c2fb_callback_229, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function sessionRetryIterInit CDecl Alias "sessionRetryIterInit" (ByVal arg0 As SqliteSessionBuffer Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As SqliteSessionApplyCtx Ptr, ByVal arg4 As SqliteChangesetIter Ptr Ptr) As c2fb_c_int
Declare Function sessionApplyRetryBuffer CDecl Alias "sessionApplyRetryBuffer" (ByVal arg0 As SqliteSessionBuffer Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As sqlite3 Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As SqliteSessionApplyCtx Ptr, ByVal arg6 As c2fb_callback_229, ByVal arg7 As Any Ptr) As c2fb_c_int
Declare Function sessionUpdateToUpdate CDecl Alias "sessionUpdateToUpdate" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As SqliteSessionApplyCtx Ptr, ByVal arg3 As SqliteChangesetIter Ptr, ByVal arg4 As SqliteVdbe Ptr Ptr) As c2fb_c_int
Declare Function sessionRetryConstraints CDecl Alias "sessionRetryConstraints" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As SqliteSessionApplyCtx Ptr, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr) As c2fb_c_int
Declare Function sessionChangesetFindTable CDecl Alias "sessionChangesetFindTable" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As SqliteChangesetIter Ptr, ByVal arg3 As SqliteSessionTable Ptr Ptr) As c2fb_c_int
Declare Function sessionOneChangeToHash CDecl Alias "sessionOneChangeToHash" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As SqliteSessionTable Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As UByte Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int) As c2fb_c_int
Declare Function sessionOneChangeIterToHash CDecl Alias "sessionOneChangeIterToHash" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sessionChangesetToHash CDecl Alias "sessionChangesetToHash" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As SqliteChangegroup Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Sub sessionAppendPartialUpdate CDecl Alias "sessionAppendPartialUpdate" (ByVal arg0 As SqliteSessionBuffer Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int Ptr)
Declare Function sessionRebase CDecl Alias "sessionRebase" (ByVal arg0 As SqliteRebaser Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As c2fb_callback_230, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As Any Ptr Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memmove CDecl Alias "memmove" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_exec_ CDecl Alias "sqlite3_exec" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_callback_5, ByVal arg3 As Any Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_prepare_v2__ CDecl Alias "sqlite3_prepare_v2" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As SqliteVdbe Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_int_ CDecl Alias "sqlite3_bind_int" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_clear_bindings_ CDecl Alias "sqlite3_clear_bindings" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_count__ CDecl Alias "sqlite3_column_count" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_step__ CDecl Alias "sqlite3_step" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_blob__ CDecl Alias "sqlite3_column_blob" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function c2fb_external_sqlite3_column_int__ CDecl Alias "sqlite3_column_int" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int64__ CDecl Alias "sqlite3_column_int64" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function c2fb_external_sqlite3_column_text__ CDecl Alias "sqlite3_column_text" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_column_value__ CDecl Alias "sqlite3_column_value" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As SqliteVdbeMem Ptr
Declare Function c2fb_external_sqlite3_column_bytes__ CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_finalize__ CDecl Alias "sqlite3_finalize" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_reset_ CDecl Alias "sqlite3_reset" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_blob___ CDecl Alias "sqlite3_value_blob" (ByVal arg0 As SqliteVdbeMem Ptr) As Const Any Ptr
Declare Function c2fb_external_sqlite3_value_double__ CDecl Alias "sqlite3_value_double" (ByVal arg0 As SqliteVdbeMem Ptr) As Double
Declare Function c2fb_external_sqlite3_value_int64___ CDecl Alias "sqlite3_value_int64" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_value_text____ CDecl Alias "sqlite3_value_text" (ByVal arg0 As SqliteVdbeMem Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes___ CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_type__ CDecl Alias "sqlite3_value_type" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_table_column_metadata_ CDecl Alias "sqlite3_table_column_metadata" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr, ByVal arg6 As c2fb_c_int Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_db_mutex CDecl Alias "sqlite3_db_mutex" (ByVal arg0 As sqlite3 Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3_preupdate_hook CDecl Alias "sqlite3_preupdate_hook" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_callback_211, ByVal arg2 As Any Ptr) As Any Ptr
Declare Function c2fb_external_sqlite3_preupdate_blobwrite CDecl Alias "sqlite3_preupdate_blobwrite" (ByVal arg0 As sqlite3 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_db_status CDecl Alias "sqlite3_db_status" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_set_errmsg CDecl Alias "sqlite3_set_errmsg" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
Declare Sub sqlite3_log CDecl Alias "sqlite3_log" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr, ...)
Declare Sub sessionUpdateFree CDecl Alias "sessionUpdateFree" (ByVal arg0 As c2fb_source_record_55 Ptr)
Declare Function sessionDeleteRow CDecl Alias "sessionDeleteRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
Declare Function sessionSelectRow CDecl Alias "sessionSelectRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
Declare Function sessionInsertRow CDecl Alias "sessionInsertRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
Declare Function sessionStat1Sql CDecl Alias "sessionStat1Sql" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_55 Ptr) As c2fb_c_int
Declare Function sessionStreamChunkSizeGet CDecl Alias "sessionStreamChunkSizeGet" () As c2fb_c_int
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
' c2fb skipped sqlite3IsBinary: FreeBASIC body already exists
' c2fb skipped sessionVarintPut: FreeBASIC body already exists
' c2fb skipped sessionVarintLen: FreeBASIC body already exists
' c2fb skipped sessionVarintGet: FreeBASIC body already exists
' c2fb skipped sessionVarintGetSafe: FreeBASIC body already exists
' c2fb skipped sessionGetI64: FreeBASIC body already exists
' c2fb skipped sessionPutI64: FreeBASIC body already exists
' c2fb skipped sessionPutDouble: FreeBASIC body already exists
' c2fb skipped sessionSerializeValue: FreeBASIC body already exists

/' ------------------------------------------------------------------------- '/
/' Translated Session lifecycle and changeset routines                       '/
/' ------------------------------------------------------------------------- '/
Private Function sessionMalloc64 CDecl Alias "sessionMalloc64" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As sqlite3_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    local0 = CPtr(Any Ptr, sqlite3_malloc64(arg1))
    If arg0 Then
        c2fb_temp_0 = CPtr(sqlite3_int64 Ptr, @(arg0->nMalloc))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_0))) + sqlite3_msize(local0))))
        (*c2fb_temp_0) = Cast(sqlite3_int64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    End If
    Return local0
End Function

Private Sub sessionFree CDecl Alias "sessionFree" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As Any Ptr)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As sqlite3_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    If arg0 Then
        c2fb_temp_0 = CPtr(sqlite3_int64 Ptr, @(arg0->nMalloc))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_0))) - sqlite3_msize(arg1))))
        (*c2fb_temp_0) = Cast(sqlite3_int64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    End If
    sqlite3_free(arg1)
End Sub

Private Function sessionPreupdateHash CDecl Alias "sessionPreupdateHash" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteSessionTable Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As SqliteVdbeMem Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim local6 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_int64
    Dim local7 As Double
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As c2fb_c_uint
    Dim local8 As Const UByte Ptr
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_10 As Const UByte Ptr
    Dim c2fb_temp_11 As Const UByte Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_uint
    Dim c2fb_temp_14 As c2fb_c_int Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If arg2->bRowid Then
        c2fb_temp_0 = Cast(c2fb_c_uint, sessionHashAppendI64(local0, arg1))
        local0 = c2fb_temp_0
    Else
        ' C unused-parameter annotation
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local1 < arg2->nCol))))
            If arg2->abPK[local1] Then
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                local5 = arg2->aiIdx[local1]
                If arg3 Then
                    c2fb_temp_3 = Cast(c2fb_c_int, CPtr(c2fb_callback_223, arg0->hook.xNew)(arg0->hook.pCtx, local5, CPtr(SqliteVdbeMem Ptr Ptr, @(local4))))
                    local2 = c2fb_temp_3
                Else
                    c2fb_temp_4 = Cast(c2fb_c_int, CPtr(c2fb_callback_223, arg0->hook.xOld)(arg0->hook.pCtx, local5, CPtr(SqliteVdbeMem Ptr Ptr, @(local4))))
                    local2 = c2fb_temp_4
                End If
                If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Return local2
                End If
                c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_type__(local4))
                local3 = c2fb_temp_5
                c2fb_temp_6 = Cast(c2fb_c_uint, sessionHashAppendType(local0, local3))
                local0 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                    ' C automatic storage declaration
                    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 1ULL))))) Then
                        c2fb_temp_7 = Cast(c2fb_int64, c2fb_external_sqlite3_value_int64___(local4))
                        local6 = c2fb_temp_7
                    Else
                        local7 = c2fb_external_sqlite3_value_double__(local4)
                        ' C unused-parameter annotation
                        c2fb_temp_8 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_int64 Ptr, @(local6))), CPtr(Const Any Ptr, CPtr(Double Ptr, @(local7))), Cast(c2fb_c_int, 8ULL)))
                    End If
                    c2fb_temp_9 = Cast(c2fb_c_uint, sessionHashAppendI64(local0, local6))
                    local0 = c2fb_temp_9
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                        ' C automatic storage declaration
                        ' C automatic storage declaration
                        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 3ULL))))) Then
                            c2fb_temp_10 = CPtr(Const UByte Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text____(local4)))
                            local8 = c2fb_temp_10
                        Else
                            c2fb_temp_11 = CPtr(Const UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob___(local4)))
                            local8 = c2fb_temp_11
                        End If
                        c2fb_temp_12 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes___(local4))
                        local9 = c2fb_temp_12
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local8 = 0))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local9 > Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
                            Return Cast(c2fb_c_int, 7ULL)
                        End If
                        c2fb_temp_13 = Cast(c2fb_c_uint, sessionHashAppendBlob(local0, local9, local8))
                        local0 = c2fb_temp_13
                    Else
                        ' C unused-parameter annotation
                        ' C unused-parameter annotation
                        c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @((*arg5)))
                        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        (*c2fb_temp_14) = c2fb_temp_15
                    End If
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_2 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
    End If
    c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_17 = Cast(c2fb_c_int, (Cast(c2fb_c_uint, (local0 Mod Cast(c2fb_c_uint, arg2->nChange)))))
    (*c2fb_temp_16) = c2fb_temp_17
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Function sessionPreupdateEqual CDecl Alias "sessionPreupdateEqual" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteSessionTable Ptr, ByVal arg3 As SqliteSessionChange Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim local2 As SqliteVdbeMem Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local6 As c2fb_int64
    Dim c2fb_temp_6 As UByte Ptr
    Dim local7 As Double
    Dim c2fb_temp_7 As Any Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As Const UByte Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As Const UByte Ptr
    Dim c2fb_temp_10 As Const UByte Ptr
    Dim c2fb_temp_11 As UByte Ptr

    ' C automatic storage declaration
    local1 = arg3->aRecord
    If arg2->bRowid Then
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 1ULL))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        Return (-Cast(c2fb_c_int, ((sessionGetI64(CPtr(UByte Ptr, @(local1[Cast(c2fb_c_int, 1ULL)]))) = arg1))))
    End If
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg2->nCol))))
        If (-Cast(c2fb_c_int, (arg2->abPK[local0] = 0))) Then
            c2fb_temp_2 = CPtr(UByte Ptr, (local1 + sessionSerialLen(CPtr(Const UByte Ptr, local1))))
            local1 = c2fb_temp_2
        Else
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_3 = local1
            local1 = (c2fb_temp_3 + 1)
            local4 = (*c2fb_temp_3)
            local5 = arg2->aiIdx[local0]
            If (-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, 18ULL))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, CPtr(c2fb_callback_223, arg0->hook.xNew)(arg0->hook.pCtx, local5, CPtr(SqliteVdbeMem Ptr Ptr, @(local2))))
                local3 = c2fb_temp_4
            Else
                c2fb_temp_5 = Cast(c2fb_c_int, CPtr(c2fb_callback_223, arg0->hook.xOld)(arg0->hook.pCtx, local5, CPtr(SqliteVdbeMem Ptr Ptr, @(local2))))
                local3 = c2fb_temp_5
            End If
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type__(local2) <> local4)))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            ' C unused-parameter annotation
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                local6 = sessionGetI64(local1)
                c2fb_temp_6 = CPtr(UByte Ptr, (local1 + Cast(c2fb_c_int, 8ULL)))
                local1 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 1ULL))))) Then
                    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_int64___(local2) <> local6)))) Then
                        Return Cast(c2fb_c_int, &O0ULL)
                    End If
                Else
                    ' C automatic storage declaration
                    ' C unused-parameter annotation
                    c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Double Ptr, @(local7))), CPtr(Const Any Ptr, CPtr(c2fb_int64 Ptr, @(local6))), Cast(c2fb_c_int, 8ULL)))
                    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_double__(local2) <> local7)))) Then
                        Return Cast(c2fb_c_int, &O0ULL)
                    End If
                End If
            Else
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_8 = CPtr(UByte Ptr, (local1 + sessionVarintGet(CPtr(Const UByte Ptr, local1), CPtr(c2fb_c_int Ptr, @(local8)))))
                local1 = c2fb_temp_8
                If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_bytes___(local2) <> local8)))) Then
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
                If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 3ULL))))) Then
                    c2fb_temp_9 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text____(local2))
                    local9 = c2fb_temp_9
                Else
                    c2fb_temp_10 = CPtr(Const UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob___(local2)))
                    local9 = c2fb_temp_10
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (c2fb_crt_memcmp(CPtr(Const Any Ptr, local1), CPtr(Const Any Ptr, local9), local8) <> 0))))) Then
                    Return Cast(c2fb_c_int, &O0ULL)
                End If
                c2fb_temp_11 = CPtr(UByte Ptr, (local1 + local8))
                local1 = c2fb_temp_11
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, 1ULL)
End Function

Private Function sessionGrowHash CDecl Alias "sessionGrowHash" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteSessionTable Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteSessionChange Ptr Ptr
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local3 As SqliteSessionChange Ptr
    Dim local4 As SqliteSessionChange Ptr
    Dim c2fb_temp_4 As SqliteSessionChange Ptr
    Dim c2fb_temp_5 As SqliteSessionChange Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_6 As SqliteSessionChange Ptr
    Dim c2fb_temp_7 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_8 As SqliteSessionChange Ptr
    Dim c2fb_temp_9 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_10 As SqliteSessionChange Ptr
    Dim c2fb_temp_11 As SQLITE_C_INT Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As SqliteSessionChange Ptr Ptr Ptr
    Dim c2fb_temp_14 As SqliteSessionChange Ptr Ptr

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2->nChange = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2->nEntry >= (Cast(c2fb_c_int, (arg2->nChange \ Cast(c2fb_c_int, 2ULL)))))))) <> 0))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        local2 = Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)) * Cast(c2fb_int64, (IIf(arg2->nChange, arg2->nChange, Cast(c2fb_c_int, 128ULL))))))
        c2fb_temp_0 = CPtr(SqliteSessionChange Ptr Ptr, CPtr(Any Ptr, sessionMalloc64(arg0, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSessionChange Ptr))) * Cast(c2fb_uint64, local2))))))
        local1 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((arg2->nChange = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, 1ULL)
            End If
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSessionChange Ptr))) * Cast(c2fb_uint64, local2)))))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local0 < arg2->nChange))))
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_4 = arg2->apChange[local0]
            local3 = c2fb_temp_4
            While local3
                local5 = ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3->op) = Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso (arg1 <> 0))))))
                local6 = sessionChangeHash(CPtr(c2fb_source_record_51 Ptr, arg2), local5, local3->aRecord, local2)
                c2fb_temp_6 = local3->pNext
                local4 = c2fb_temp_6
                c2fb_temp_7 = CPtr(SqliteSessionChange Ptr Ptr, @(local3->pNext))
                c2fb_temp_8 = local1[local6]
                (*c2fb_temp_7) = c2fb_temp_8
                c2fb_temp_9 = CPtr(SqliteSessionChange Ptr Ptr, @(local1[local6]))
                c2fb_temp_10 = local3
                (*c2fb_temp_9) = c2fb_temp_10
            c2fb_flow_3:
                c2fb_temp_5 = local4
                local3 = c2fb_temp_5
            Wend
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_3 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
        sessionFree(arg0, CPtr(Any Ptr, arg2->apChange))
        c2fb_temp_11 = CPtr(SQLITE_C_INT Ptr, @(arg2->nChange))
        c2fb_temp_12 = Cast(c2fb_c_int, local2)
        (*c2fb_temp_11) = Cast(SQLITE_C_INT, c2fb_temp_12)
        c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        c2fb_temp_13 = CPtr(SqliteSessionChange Ptr Ptr Ptr, @(arg2->apChange))
        c2fb_temp_14 = local1
        (*c2fb_temp_13) = c2fb_temp_14
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Function sessionTableInfo CDecl Alias "sessionTableInfo" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As Const ZString Ptr Ptr Ptr, ByVal arg8 As Const ZString Ptr Ptr Ptr, ByVal arg9 As c2fb_c_int Ptr Ptr, ByVal arg10 As UByte Ptr Ptr, ByVal arg11 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As ZString Ptr
    Dim local1 As SqliteVdbe Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As UByte Ptr
    Dim local8 As ZString Ptr Ptr
    Dim local9 As ZString Ptr Ptr
    Dim local10 As UByte Ptr
    Dim local11 As c2fb_c_int Ptr
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_0 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_1 As Const ZString Ptr Ptr
    Dim c2fb_temp_2 As UByte Ptr Ptr
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As Const ZString Ptr Ptr
    Dim c2fb_temp_11 As Const ZString Ptr
    Dim c2fb_temp_12 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_13 As Const ZString Ptr Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_int64
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_int64
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_int64
    Dim c2fb_temp_31 As UByte Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As Any Ptr
    Dim c2fb_temp_34 As ZString Ptr Ptr
    Dim c2fb_temp_35 As ZString Ptr Ptr
    Dim c2fb_temp_36 As c2fb_c_int Ptr
    Dim c2fb_temp_37 As UByte Ptr
    Dim c2fb_temp_38 As UByte Ptr
    Dim c2fb_temp_39 As Any Ptr
    Dim c2fb_temp_40 As Const ZString Ptr Ptr
    Dim c2fb_temp_41 As Const ZString Ptr
    Dim c2fb_temp_42 As UByte Ptr
    Dim c2fb_temp_43 As c2fb_c_int
    Dim local13 As c2fb_size_t
    Dim c2fb_temp_44 As Any Ptr
    Dim c2fb_temp_45 As ZString Ptr Ptr
    Dim c2fb_temp_46 As ZString Ptr
    Dim c2fb_temp_47 As UByte Ptr
    Dim c2fb_temp_48 As UByte Ptr
    Dim c2fb_temp_49 As UByte
    Dim c2fb_temp_50 As c2fb_c_int Ptr
    Dim c2fb_temp_51 As c2fb_c_int
    Dim c2fb_temp_52 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim local16 As Const UByte Ptr
    Dim local17 As Const UByte Ptr
    Dim c2fb_temp_53 As Any Ptr
    Dim c2fb_temp_54 As ZString Ptr Ptr
    Dim c2fb_temp_55 As ZString Ptr
    Dim c2fb_temp_56 As UByte Ptr
    Dim c2fb_temp_57 As Any Ptr
    Dim c2fb_temp_58 As ZString Ptr Ptr
    Dim c2fb_temp_59 As ZString Ptr
    Dim c2fb_temp_60 As UByte Ptr
    Dim c2fb_temp_61 As ZString Ptr Ptr
    Dim c2fb_temp_62 As ZString Ptr
    Dim c2fb_temp_63 As UByte Ptr
    Dim c2fb_temp_64 As UByte
    Dim c2fb_temp_65 As c2fb_c_int Ptr
    Dim c2fb_temp_66 As c2fb_c_int
    Dim c2fb_temp_67 As c2fb_c_int
    Dim c2fb_temp_68 As c2fb_c_int Ptr
    Dim c2fb_temp_69 As c2fb_c_int
    Dim c2fb_temp_70 As c2fb_c_int
    Dim c2fb_temp_71 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_72 As Const ZString Ptr Ptr
    Dim c2fb_temp_73 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_74 As Const ZString Ptr Ptr
    Dim c2fb_temp_75 As UByte Ptr Ptr
    Dim c2fb_temp_76 As UByte Ptr
    Dim c2fb_temp_77 As c2fb_c_int Ptr
    Dim c2fb_temp_78 As c2fb_c_int
    Dim c2fb_temp_79 As c2fb_c_int Ptr Ptr
    Dim c2fb_temp_80 As c2fb_c_int Ptr
    Dim c2fb_temp_81 As c2fb_c_int Ptr
    Dim c2fb_temp_82 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local7 = Cast(c2fb_c_int, &O0ULL)
    local8 = Cast(c2fb_c_int, &O0ULL)
    local9 = Cast(c2fb_c_int, &O0ULL)
    local10 = Cast(c2fb_c_int, &O0ULL)
    local11 = Cast(c2fb_c_int, &O0ULL)
    local12 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Const ZString Ptr Ptr Ptr, @((*arg7)))
    c2fb_temp_1 = CPtr(Const ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr Ptr, @((*arg10)))
    c2fb_temp_3 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_4) = c2fb_temp_5
    If arg5 Then
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg5)))
        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_6) = c2fb_temp_7
    End If
    If arg9 Then
        c2fb_temp_8 = CPtr(c2fb_c_int Ptr Ptr, @((*arg9)))
        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_8) = c2fb_temp_9
    End If
    If arg6 Then
        c2fb_temp_10 = CPtr(Const ZString Ptr Ptr, @((*arg6)))
        c2fb_temp_11 = CPtr(Const ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_10) = c2fb_temp_11
    End If
    If arg8 Then
        c2fb_temp_12 = CPtr(Const ZString Ptr Ptr Ptr, @((*arg8)))
        c2fb_temp_13 = CPtr(Const ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_12) = c2fb_temp_13
    End If
    c2fb_temp_14 = Cast(c2fb_c_int, sqlite3Strlen30(arg3))
    local5 = c2fb_temp_14
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, 12ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(StrPtr(!"sqlite_stat1"), arg3))))) <> 0))))) Then
        c2fb_temp_15 = Cast(c2fb_c_int, c2fb_external_sqlite3_table_column_metadata_(arg1, arg2, arg3, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local2 = c2fb_temp_15
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_16 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT 0, 'tbl',  '', 0, '', 1, 0     UNION ALL SELECT 1, 'idx',  '', 0, '', 2, 0     UNION ALL SELECT 2, 'stat', '', 0, '', 0, 0")))
            local0 = c2fb_temp_16
        Else
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) Then
                c2fb_temp_17 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"")))
                local0 = c2fb_temp_17
            Else
                Return local2
            End If
        End If
    Else
        c2fb_temp_18 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"PRAGMA '%q'.table_xinfo('%q')"), arg2, arg3))
        local0 = c2fb_temp_18
    End If
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_19 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2__(arg1, CPtr(Const ZString Ptr, local0), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(SqliteVdbe Ptr Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))
    local2 = c2fb_temp_19
    sqlite3_free(CPtr(Any Ptr, local0))
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local2
    End If
    c2fb_temp_20 = Cast(c2fb_int64, Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))))
    local3 = c2fb_temp_20
    c2fb_temp_21 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((arg11 <> Cast(c2fb_c_int, &O0ULL)))))))
    local12 = c2fb_temp_21
    While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step__(local1)))))
        c2fb_temp_22 = Cast(c2fb_int64, Cast(c2fb_int64, (local3 + Cast(c2fb_int64, c2fb_external_sqlite3_column_bytes__(local1, Cast(c2fb_c_int, 1ULL))))))
        local3 = c2fb_temp_22
        c2fb_temp_23 = Cast(c2fb_int64, Cast(c2fb_int64, (local3 + Cast(c2fb_int64, c2fb_external_sqlite3_column_bytes__(local1, Cast(c2fb_c_int, 4ULL))))))
        local3 = c2fb_temp_23
        If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_column_int__(local1, Cast(c2fb_c_int, 6ULL)) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_24 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_24 + 1)))
        End If
        If c2fb_external_sqlite3_column_int__(local1, Cast(c2fb_c_int, 5ULL)) Then
            c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local12 = c2fb_temp_25
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local12 = c2fb_temp_26
    End If
    c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 + local12)))
    local4 = c2fb_temp_27
    c2fb_temp_28 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) + Cast(c2fb_uint64, c2fb_crt_strlen(StrPtr(!"_rowid_"))))))
    local3 = c2fb_temp_28
    c2fb_temp_29 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(local1))
    local2 = c2fb_temp_29
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_30 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) + Cast(c2fb_uint64, (Cast(c2fb_uint64, local4) * (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(Const ZString Ptr))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_int))))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(UByte))))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))))))))))
        local3 = c2fb_temp_30
        c2fb_temp_31 = CPtr(UByte Ptr, CPtr(Any Ptr, sessionMalloc64(arg0, local3)))
        local7 = c2fb_temp_31
        If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local2 = c2fb_temp_32
        Else
            c2fb_temp_33 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local7), Cast(c2fb_c_int, &O0ULL), local3))
        End If
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_34 = CPtr(ZString Ptr Ptr, local7)
        local8 = c2fb_temp_34
        c2fb_temp_35 = CPtr(ZString Ptr Ptr, CPtr(ZString Ptr Ptr, @(local8[local4])))
        local9 = c2fb_temp_35
        c2fb_temp_36 = CPtr(c2fb_c_int Ptr, CPtr(ZString Ptr Ptr, @(local9[local4])))
        local11 = c2fb_temp_36
        c2fb_temp_37 = CPtr(UByte Ptr, CPtr(c2fb_c_int Ptr, @(local11[local4])))
        local10 = c2fb_temp_37
        c2fb_temp_38 = CPtr(UByte Ptr, @(local10[local4]))
        local7 = c2fb_temp_38
        If arg6 Then
            c2fb_temp_39 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local7), CPtr(Const Any Ptr, arg3), Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL)))))
            c2fb_temp_40 = CPtr(Const ZString Ptr Ptr, @((*arg6)))
            c2fb_temp_41 = CPtr(Const ZString Ptr, CPtr(ZString Ptr, local7))
            (*c2fb_temp_40) = c2fb_temp_41
            c2fb_temp_42 = CPtr(UByte Ptr, (local7 + Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL)))))
            local7 = c2fb_temp_42
        End If
        c2fb_temp_43 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local6 = c2fb_temp_43
        If local12 Then
            local13 = c2fb_crt_strlen(StrPtr(!"_rowid_"))
            c2fb_temp_44 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local7), CPtr(Const Any Ptr, StrPtr(!"_rowid_")), Cast(c2fb_uint64, (Cast(c2fb_uint64, local13) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))))))
            c2fb_temp_45 = CPtr(ZString Ptr Ptr, @(local8[local6]))
            c2fb_temp_46 = CPtr(ZString Ptr, local7)
            (*c2fb_temp_45) = c2fb_temp_46
            c2fb_temp_47 = CPtr(UByte Ptr, (local7 + Cast(c2fb_uint64, (Cast(c2fb_uint64, local13) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))))))
            local7 = c2fb_temp_47
            c2fb_temp_48 = CPtr(UByte Ptr, @(local10[local6]))
            c2fb_temp_49 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_48) = c2fb_temp_49
            c2fb_temp_50 = CPtr(c2fb_c_int Ptr, @(local11[local6]))
            c2fb_temp_51 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
            (*c2fb_temp_50) = c2fb_temp_51
            c2fb_temp_52 = local6
            local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_52 + 1)))
        End If
        While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step__(local1)))))
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_column_int__(local1, Cast(c2fb_c_int, 6ULL)) = Cast(c2fb_c_int, &O0ULL))))) Then
                local14 = c2fb_external_sqlite3_column_bytes__(local1, Cast(c2fb_c_int, 1ULL))
                local15 = c2fb_external_sqlite3_column_bytes__(local1, Cast(c2fb_c_int, 4ULL))
                local16 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text__(local1, Cast(c2fb_c_int, 1ULL)))
                local17 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text__(local1, Cast(c2fb_c_int, 4ULL)))
                If (-Cast(c2fb_c_int, ((local16 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_2
                End If
                c2fb_temp_53 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local7), CPtr(Const Any Ptr, local16), Cast(c2fb_c_int, (local14 + Cast(c2fb_c_int, 1ULL)))))
                c2fb_temp_54 = CPtr(ZString Ptr Ptr, @(local8[local6]))
                c2fb_temp_55 = CPtr(ZString Ptr, local7)
                (*c2fb_temp_54) = c2fb_temp_55
                c2fb_temp_56 = CPtr(UByte Ptr, (local7 + Cast(c2fb_c_int, (local14 + Cast(c2fb_c_int, 1ULL)))))
                local7 = c2fb_temp_56
                If local17 Then
                    c2fb_temp_57 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local7), CPtr(Const Any Ptr, local17), Cast(c2fb_c_int, (local15 + Cast(c2fb_c_int, 1ULL)))))
                    c2fb_temp_58 = CPtr(ZString Ptr Ptr, @(local9[local6]))
                    c2fb_temp_59 = CPtr(ZString Ptr, local7)
                    (*c2fb_temp_58) = c2fb_temp_59
                    c2fb_temp_60 = CPtr(UByte Ptr, (local7 + Cast(c2fb_c_int, (local15 + Cast(c2fb_c_int, 1ULL)))))
                    local7 = c2fb_temp_60
                Else
                    c2fb_temp_61 = CPtr(ZString Ptr Ptr, @(local9[local6]))
                    c2fb_temp_62 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_61) = c2fb_temp_62
                End If
                c2fb_temp_63 = CPtr(UByte Ptr, @(local10[local6]))
                c2fb_temp_64 = Cast(UByte, c2fb_external_sqlite3_column_int__(local1, Cast(c2fb_c_int, 5ULL)))
                (*c2fb_temp_63) = c2fb_temp_64
                c2fb_temp_65 = CPtr(c2fb_c_int Ptr, @(local11[local6]))
                c2fb_temp_66 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_int__(local1, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_65) = c2fb_temp_66
                c2fb_temp_67 = local6
                local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_67 + 1)))
            End If
            If arg5 Then
                c2fb_temp_68 = CPtr(c2fb_c_int Ptr, @(((*arg5))))
                c2fb_temp_69 = (*c2fb_temp_68)
                (*c2fb_temp_68) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_69 + 1)))
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_70 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(local1))
        local2 = c2fb_temp_70
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_71 = CPtr(Const ZString Ptr Ptr Ptr, @((*arg7)))
        c2fb_temp_72 = CPtr(Const ZString Ptr Ptr, local8)
        (*c2fb_temp_71) = c2fb_temp_72
        If arg8 Then
            c2fb_temp_73 = CPtr(Const ZString Ptr Ptr Ptr, @((*arg8)))
            c2fb_temp_74 = CPtr(Const ZString Ptr Ptr, local9)
            (*c2fb_temp_73) = c2fb_temp_74
        End If
        c2fb_temp_75 = CPtr(UByte Ptr Ptr, @((*arg10)))
        c2fb_temp_76 = local10
        (*c2fb_temp_75) = c2fb_temp_76
        c2fb_temp_77 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_78 = Cast(c2fb_c_int, local4)
        (*c2fb_temp_77) = c2fb_temp_78
        If arg9 Then
            c2fb_temp_79 = CPtr(c2fb_c_int Ptr Ptr, @((*arg9)))
            c2fb_temp_80 = local11
            (*c2fb_temp_79) = c2fb_temp_80
        End If
    Else
        sessionFree(arg0, CPtr(Any Ptr, local8))
    End If
    If arg11 Then
        c2fb_temp_81 = CPtr(c2fb_c_int Ptr, @((*arg11)))
        c2fb_temp_82 = Cast(c2fb_c_int, local12)
        (*c2fb_temp_81) = c2fb_temp_82
    End If
    c2fb_external_sqlite3_finalize__(local1)
    Return local2
End Function

Private Function sessionInitTable CDecl Alias "sessionInitTable" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr, ByVal arg2 As sqlite3 Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As UByte Ptr
    Dim c2fb_temp_0 As UByte Ptr Ptr
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As UByte Ptr Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As sqlite3_int64 Ptr
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As SQLITE_C_INT Ptr
    Dim c2fb_temp_12 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg1->nCol = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C unused-parameter annotation
        sqlite3_free(CPtr(Any Ptr, arg1->azCol))
        c2fb_temp_0 = CPtr(UByte Ptr Ptr, @(arg1->abPK))
        c2fb_temp_1 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, sessionTableInfo(arg0, arg2, arg3, CPtr(Const ZString Ptr, arg1->zName), CPtr(c2fb_c_int Ptr, @(arg1->nCol)), CPtr(c2fb_c_int Ptr, @(arg1->nTotalCol)), Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr Ptr Ptr, @(arg1->azCol)), CPtr(Const ZString Ptr Ptr Ptr, @(arg1->azDflt)), CPtr(c2fb_c_int Ptr Ptr, @(arg1->aiIdx)), CPtr(UByte Ptr Ptr, @(local1)), (IIf(((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (arg0->bImplicitPK <> 0)))))), CPtr(c2fb_c_int Ptr, @(arg1->bRowid)), CPtr(c2fb_c_int Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_3
            While (-Cast(c2fb_c_int, ((local2 < arg1->nCol))))
                If local1[local2] Then
                    c2fb_temp_5 = CPtr(UByte Ptr Ptr, @(arg1->abPK))
                    c2fb_temp_6 = local1
                    (*c2fb_temp_5) = c2fb_temp_6
                    Goto c2fb_flow_0
                End If
            c2fb_flow_1:
                c2fb_temp_4 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
            Wend
            c2fb_flow_0:
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(StrPtr(!"sqlite_stat1"), CPtr(Const ZString Ptr, arg1->zName)))))) Then
                c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(arg1->bStat1))
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_7) = Cast(SQLITE_C_INT, c2fb_temp_8)
                c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
            End If
            If (-Cast(c2fb_c_int, (((arg0 <> 0) AndAlso (arg0->bEnableSize <> 0))))) Then
                c2fb_temp_9 = CPtr(sqlite3_int64 Ptr, @(arg0->nMaxChangesetSize))
                c2fb_temp_10 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_int64, (*c2fb_temp_9))) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sessionVarintLen(arg1->nCol))) + arg1->nCol))) + Cast(c2fb_uint64, c2fb_crt_strlen(CPtr(Const ZString Ptr, arg1->zName))))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))))))))
                (*c2fb_temp_9) = Cast(sqlite3_int64, c2fb_temp_10)
                c2fb_temp_10 = Cast(c2fb_int64, (*c2fb_temp_9))
            End If
        End If
    End If
    If arg0 Then
        c2fb_temp_11 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
        c2fb_temp_12 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_11) = Cast(SQLITE_C_INT, c2fb_temp_12)
        c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        Return ((-Cast(c2fb_c_int, (((local0 <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->abPK = Cast(c2fb_c_int, &O0ULL))))) <> 0))))))
    End If
    Return local0
End Function

Private Function sessionReinitTable CDecl Alias "sessionReinitTable" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr Ptr
    Dim local3 As Const ZString Ptr Ptr
    Dim local4 As c2fb_c_int Ptr
    Dim local5 As UByte Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As SQLITE_C_INT Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As SQLITE_C_INT Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As SQLITE_C_INT Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim local9 As Const ZString Ptr Ptr
    Dim c2fb_temp_10 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_11 As Const ZString Ptr Ptr
    Dim c2fb_temp_12 As SQLITE_C_INT Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As SQLITE_C_INT Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_17 As Const ZString Ptr Ptr
    Dim c2fb_temp_18 As UByte Ptr Ptr
    Dim c2fb_temp_19 As UByte Ptr
    Dim c2fb_temp_20 As SQLITE_C_INT Ptr Ptr
    Dim c2fb_temp_21 As c2fb_c_int Ptr
    Dim c2fb_temp_22 As Const ZString Ptr Ptr
    Dim c2fb_temp_23 As sqlite3_int64 Ptr
    Dim c2fb_temp_24 As c2fb_int64
    Dim c2fb_temp_25 As sqlite3_int64 Ptr
    Dim c2fb_temp_26 As c2fb_int64
    Dim c2fb_temp_27 As sqlite3_int64 Ptr
    Dim c2fb_temp_28 As c2fb_int64

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
    c2fb_temp_1 = Cast(c2fb_c_int, sessionTableInfo(arg0, arg0->db, CPtr(Const ZString Ptr, arg0->zDb), CPtr(Const ZString Ptr, arg1->zName), CPtr(c2fb_c_int Ptr, @(local0)), CPtr(c2fb_c_int Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr Ptr Ptr, @(local2)), CPtr(Const ZString Ptr Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr Ptr, @(local4)), CPtr(UByte Ptr Ptr, @(local5)), (IIf(arg0->bImplicitPK, CPtr(c2fb_c_int Ptr, @(local6)), CPtr(c2fb_c_int Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))))
    (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->nCol > local0)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->bRowid <> local6)))) <> 0))))) Then
            c2fb_temp_2 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 17ULL))
            (*c2fb_temp_2) = Cast(SQLITE_C_INT, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        Else
            ' C automatic storage declaration
            local8 = arg1->nCol
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local7 = c2fb_temp_4
            While (-Cast(c2fb_c_int, ((local7 < local0))))
                If (-Cast(c2fb_c_int, ((local7 < arg1->nCol)))) Then
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->abPK[local7]) <> Cast(c2fb_c_int, local5[local7]))))) Then
                        c2fb_temp_6 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
                        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 17ULL))
                        (*c2fb_temp_6) = Cast(SQLITE_C_INT, c2fb_temp_7)
                        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
                    End If
                Else
                    If local5[local7] Then
                        c2fb_temp_8 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
                        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 17ULL))
                        (*c2fb_temp_8) = Cast(SQLITE_C_INT, c2fb_temp_9)
                        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
                    End If
                End If
            c2fb_flow_1:
                c2fb_temp_5 = local7
                local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
            Wend
            c2fb_flow_0:
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                local9 = arg1->azCol
                c2fb_temp_10 = CPtr(Const ZString Ptr Ptr Ptr, @(arg1->azCol))
                c2fb_temp_11 = local2
                (*c2fb_temp_10) = c2fb_temp_11
                c2fb_temp_12 = CPtr(SQLITE_C_INT Ptr, @(arg1->nCol))
                c2fb_temp_13 = Cast(c2fb_c_int, local0)
                (*c2fb_temp_12) = Cast(SQLITE_C_INT, c2fb_temp_13)
                c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
                c2fb_temp_14 = CPtr(SQLITE_C_INT Ptr, @(arg1->nTotalCol))
                c2fb_temp_15 = Cast(c2fb_c_int, local1)
                (*c2fb_temp_14) = Cast(SQLITE_C_INT, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                c2fb_temp_16 = CPtr(Const ZString Ptr Ptr Ptr, @(arg1->azDflt))
                c2fb_temp_17 = local3
                (*c2fb_temp_16) = c2fb_temp_17
                c2fb_temp_18 = CPtr(UByte Ptr Ptr, @(arg1->abPK))
                c2fb_temp_19 = local5
                (*c2fb_temp_18) = c2fb_temp_19
                c2fb_temp_20 = CPtr(SQLITE_C_INT Ptr Ptr, @(arg1->aiIdx))
                c2fb_temp_21 = local4
                (*c2fb_temp_20) = CPtr(SQLITE_C_INT Ptr, c2fb_temp_21)
                c2fb_temp_21 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_20))
                c2fb_temp_22 = local9
                local2 = c2fb_temp_22
            End If
            If arg0->bEnableSize Then
                c2fb_temp_23 = CPtr(sqlite3_int64 Ptr, @(arg0->nMaxChangesetSize))
                c2fb_temp_24 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_23)) + Cast(c2fb_int64, (Cast(c2fb_c_int, (local0 - local8)))))))
                (*c2fb_temp_23) = Cast(sqlite3_int64, c2fb_temp_24)
                c2fb_temp_24 = Cast(c2fb_int64, (*c2fb_temp_23))
                c2fb_temp_25 = CPtr(sqlite3_int64 Ptr, @(arg0->nMaxChangesetSize))
                c2fb_temp_26 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_25)) + Cast(c2fb_int64, sessionVarintLen(local0)))))
                (*c2fb_temp_25) = Cast(sqlite3_int64, c2fb_temp_26)
                c2fb_temp_26 = Cast(c2fb_int64, (*c2fb_temp_25))
                c2fb_temp_27 = CPtr(sqlite3_int64 Ptr, @(arg0->nMaxChangesetSize))
                c2fb_temp_28 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_27)) - Cast(c2fb_int64, sessionVarintLen(local8)))))
                (*c2fb_temp_27) = Cast(sqlite3_int64, c2fb_temp_28)
                c2fb_temp_28 = Cast(c2fb_int64, (*c2fb_temp_27))
            End If
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, CPtr(ZString Ptr, local2)))
    Return arg0->rc
End Function

Private Sub sessionUpdateOneChange CDecl Alias "sessionUpdateOneChange" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As SqliteSessionChange Ptr Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As SqliteVdbe Ptr)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionChange Ptr
    Dim local1 As SqliteSessionChange Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As SqliteSessionChange Ptr
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As UByte Ptr Ptr
    Dim c2fb_temp_9 As UByte Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As SQLITE_C_INT Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte
    Dim local7 As c2fb_int64
    Dim c2fb_temp_15 As SQLITE_C_INT Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim local8 As Double
    Dim c2fb_temp_17 As SQLITE_C_INT Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As Const ZString Ptr
    Dim c2fb_temp_19 As SQLITE_C_INT Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Any Ptr
    Dim c2fb_temp_22 As SQLITE_C_INT Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As Const UByte Ptr
    Dim c2fb_temp_24 As SQLITE_C_INT Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Any Ptr
    Dim c2fb_temp_27 As SQLITE_C_INT Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As SqliteSessionChange Ptr
    Dim c2fb_temp_30 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_31 As SqliteSessionChange Ptr
    Dim c2fb_temp_32 As UShort Ptr
    Dim c2fb_temp_33 As UShort
    Dim c2fb_temp_34 As SQLITE_C_INT Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As sqlite3_int64 Ptr
    Dim c2fb_temp_37 As c2fb_int64

    local0 = (*arg2)
    While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->nRecordField) < arg3))))
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = local0->nRecordField
        local5 = sqlite3_column_type(CPtr(Any Ptr, arg4), local4)
        Select Case local5
            Case Cast(c2fb_c_int, 5ULL)
                c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local3 = c2fb_temp_0
            Case Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, 2ULL)
                c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 9ULL))
                local3 = c2fb_temp_1
            Case Else
                local6 = c2fb_external_sqlite3_column_bytes__(arg4, local4)
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sessionVarintLen(local6))) + local6)))
                local3 = c2fb_temp_2
                ' C unused-parameter annotation
                Goto c2fb_flow_2
        End Select
        c2fb_flow_2:
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) + (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSessionChange))) + Cast(c2fb_uint64, local0->nRecord)))))))
        local2 = c2fb_temp_3
        c2fb_temp_4 = CPtr(SqliteSessionChange Ptr, CPtr(Any Ptr, sessionMalloc64(arg0, local2)))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg1)))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_5) = c2fb_temp_6
            Return
        Else
            c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1), CPtr(Const Any Ptr, local0), Cast(c2fb_size_t, SizeOf(SqliteSessionChange))))
            c2fb_temp_8 = CPtr(UByte Ptr Ptr, @(local1->aRecord))
            c2fb_temp_9 = CPtr(UByte Ptr, CPtr(SqliteSessionChange Ptr, @(local1[Cast(c2fb_c_int, 1ULL)])))
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->aRecord), CPtr(Const Any Ptr, local0->aRecord), local0->nRecord))
            c2fb_temp_11 = CPtr(SQLITE_C_INT Ptr, @(local1->nRecord))
            c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
            (*c2fb_temp_11) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
            c2fb_temp_13 = CPtr(UByte Ptr, @(local1->aRecord[c2fb_temp_12]))
            c2fb_temp_14 = Cast(UByte, Cast(UByte, local5))
            (*c2fb_temp_13) = c2fb_temp_14
            Select Case local5
                Case Cast(c2fb_c_int, 1ULL)
                    local7 = c2fb_external_sqlite3_column_int64__(arg4, local4)
                    sessionPutI64(CPtr(UByte Ptr, @(local1->aRecord[local1->nRecord])), local7)
                    c2fb_temp_15 = CPtr(SQLITE_C_INT Ptr, @(local1->nRecord))
                    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_15)) + Cast(c2fb_c_int, 8ULL))))
                    (*c2fb_temp_15) = Cast(SQLITE_C_INT, c2fb_temp_16)
                    c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
                    Goto c2fb_flow_3
                Case Cast(c2fb_c_int, 2ULL)
                    local8 = sqlite3_column_double(CPtr(Any Ptr, arg4), local4)
                    sessionPutDouble(CPtr(UByte Ptr, @(local1->aRecord[local1->nRecord])), local8)
                    c2fb_temp_17 = CPtr(SQLITE_C_INT Ptr, @(local1->nRecord))
                    c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_17)) + Cast(c2fb_c_int, 8ULL))))
                    (*c2fb_temp_17) = Cast(SQLITE_C_INT, c2fb_temp_18)
                    c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
                    Goto c2fb_flow_3
                Case Cast(c2fb_c_int, 3ULL)
                    local9 = c2fb_external_sqlite3_column_bytes__(arg4, local4)
                    local10 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text__(arg4, local4)))
                    c2fb_temp_19 = CPtr(SQLITE_C_INT Ptr, @(local1->nRecord))
                    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_19)) + sessionVarintPut(CPtr(UByte Ptr, @(local1->aRecord[local1->nRecord])), local9))))
                    (*c2fb_temp_19) = Cast(SQLITE_C_INT, c2fb_temp_20)
                    c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
                    c2fb_temp_21 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local1->aRecord[local1->nRecord]))), CPtr(Const Any Ptr, local10), local9))
                    c2fb_temp_22 = CPtr(SQLITE_C_INT Ptr, @(local1->nRecord))
                    c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_22)) + local9)))
                    (*c2fb_temp_22) = Cast(SQLITE_C_INT, c2fb_temp_23)
                    c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
                    Goto c2fb_flow_3
                Case Cast(c2fb_c_int, 4ULL)
                    local11 = c2fb_external_sqlite3_column_bytes__(arg4, local4)
                    local12 = CPtr(Const UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob__(arg4, local4)))
                    c2fb_temp_24 = CPtr(SQLITE_C_INT Ptr, @(local1->nRecord))
                    c2fb_temp_25 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_24)) + sessionVarintPut(CPtr(UByte Ptr, @(local1->aRecord[local1->nRecord])), local11))))
                    (*c2fb_temp_24) = Cast(SQLITE_C_INT, c2fb_temp_25)
                    c2fb_temp_25 = Cast(c2fb_c_int, (*c2fb_temp_24))
                    c2fb_temp_26 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local1->aRecord[local1->nRecord]))), CPtr(Const Any Ptr, local12), local11))
                    c2fb_temp_27 = CPtr(SQLITE_C_INT Ptr, @(local1->nRecord))
                    c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_27)) + local11)))
                    (*c2fb_temp_27) = Cast(SQLITE_C_INT, c2fb_temp_28)
                    c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
                    Goto c2fb_flow_3
                Case Else
                    ' C unused-parameter annotation
            End Select
            c2fb_flow_3:
            sessionFree(arg0, CPtr(Any Ptr, local0))
            c2fb_temp_30 = CPtr(SqliteSessionChange Ptr Ptr, @((*arg2)))
            c2fb_temp_29 = local1
            local0 = c2fb_temp_29
            c2fb_temp_31 = c2fb_temp_29
            (*c2fb_temp_30) = c2fb_temp_31
            c2fb_temp_32 = CPtr(UShort Ptr, @(local1->nRecordField))
            c2fb_temp_33 = (*c2fb_temp_32)
            (*c2fb_temp_32) = Cast(UShort, Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_temp_33) + 1)))
            c2fb_temp_34 = CPtr(SQLITE_C_INT Ptr, @(local1->nMaxSize))
            c2fb_temp_35 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_34)) + local3)))
            (*c2fb_temp_34) = Cast(SQLITE_C_INT, c2fb_temp_35)
            c2fb_temp_35 = Cast(c2fb_c_int, (*c2fb_temp_34))
            If arg0 Then
                c2fb_temp_36 = CPtr(sqlite3_int64 Ptr, @(arg0->nMaxChangesetSize))
                c2fb_temp_37 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_36)) + Cast(c2fb_int64, local3))))
                (*c2fb_temp_36) = Cast(sqlite3_int64, c2fb_temp_37)
                c2fb_temp_37 = Cast(c2fb_int64, (*c2fb_temp_36))
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
End Sub

Private Function sessionUpdateChanges CDecl Alias "sessionUpdateChanges" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteVdbe Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_4 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_5 As SQLITE_C_INT Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = arg0->rc
    c2fb_temp_0 = Cast(c2fb_c_int, sessionPrepareDfltStmt(arg0->db, CPtr(c2fb_source_record_51 Ptr, arg1), CPtr(SqliteVdbe Ptr Ptr, @(local0))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step__(local0))))) <> 0))))) Then
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local2 < arg1->nChange))))
            c2fb_temp_3 = CPtr(SqliteSessionChange Ptr Ptr, @(arg1->apChange[local2]))
            local3 = c2fb_temp_3
            While (*local3)
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((*local3))->nRecordField) <> arg1->nCol)))) Then
                    sessionUpdateOneChange(arg0, CPtr(c2fb_c_int Ptr, @(local1)), local3, arg1->nCol, local0)
                End If
            c2fb_flow_3:
                c2fb_temp_4 = CPtr(SqliteSessionChange Ptr Ptr, @((((*local3))->pNext)))
                local3 = c2fb_temp_4
            Wend
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_2 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
    End If
    sessionFinalizeStmt(local0, CPtr(c2fb_c_int Ptr, @(local1)))
    c2fb_temp_5 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
    c2fb_temp_6 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_5) = Cast(SQLITE_C_INT, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    Return arg0->rc
End Function

Private Function sessionStat1Old CDecl Alias "sessionStat1Old" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionStat1Context Ptr
    Dim local1 As SqliteVdbeMem Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteVdbeMem Ptr
    Dim c2fb_temp_1 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_2 As SqliteVdbeMem Ptr

    local0 = CPtr(SqliteSessionStat1Context Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = CPtr(c2fb_callback_223, local0->hook.xOld)(local0->hook.pCtx, arg1, CPtr(SqliteVdbeMem Ptr Ptr, @(local1)))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type__(local1) = Cast(c2fb_c_int, 5ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(SqliteVdbeMem Ptr, local0->pSession->pZeroBlob)
        local1 = c2fb_temp_0
    End If
    c2fb_temp_1 = CPtr(SqliteVdbeMem Ptr Ptr, @((*arg2)))
    c2fb_temp_2 = local1
    (*c2fb_temp_1) = c2fb_temp_2
    Return local2
End Function

Private Function sessionStat1New CDecl Alias "sessionStat1New" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionStat1Context Ptr
    Dim local1 As SqliteVdbeMem Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteVdbeMem Ptr
    Dim c2fb_temp_1 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_2 As SqliteVdbeMem Ptr

    local0 = CPtr(SqliteSessionStat1Context Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = CPtr(c2fb_callback_223, local0->hook.xNew)(local0->hook.pCtx, arg1, CPtr(SqliteVdbeMem Ptr Ptr, @(local1)))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type__(local1) = Cast(c2fb_c_int, 5ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(SqliteVdbeMem Ptr, local0->pSession->pZeroBlob)
        local1 = c2fb_temp_0
    End If
    c2fb_temp_1 = CPtr(SqliteVdbeMem Ptr Ptr, @((*arg2)))
    c2fb_temp_2 = local1
    (*c2fb_temp_1) = c2fb_temp_2
    Return local2
End Function

Private Function sessionStat1Count CDecl Alias "sessionStat1Count" (ByVal arg0 As Any Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionStat1Context Ptr

    local0 = CPtr(SqliteSessionStat1Context Ptr, arg0)
    Return CPtr(c2fb_callback_140, local0->hook.xCount)(local0->hook.pCtx)
End Function

Private Function sessionStat1Depth CDecl Alias "sessionStat1Depth" (ByVal arg0 As Any Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionStat1Context Ptr

    local0 = CPtr(SqliteSessionStat1Context Ptr, arg0)
    Return CPtr(c2fb_callback_140, local0->hook.xDepth)(local0->hook.pCtx)
End Function

Private Function sessionUpdateMaxSize CDecl Alias "sessionUpdateMaxSize" (ByVal arg0 As c2fb_c_int, ByVal arg1 As SqliteSession Ptr, ByVal arg2 As SqliteSessionTable Ptr, ByVal arg3 As SqliteSessionChange Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As SqliteVdbeMem Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_int64
    Dim local3 As c2fb_c_int
    Dim local4 As UByte Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As SqliteVdbeMem Ptr
    Dim c2fb_temp_9 As UByte Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local10 As c2fb_int64
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local11 As Double
    Dim c2fb_temp_13 As Any Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As UByte Ptr
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As UByte Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As UByte Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_int64
    Dim c2fb_temp_24 As c2fb_int64
    Dim c2fb_temp_25 As c2fb_int64
    Dim local13 As c2fb_c_int
    Dim c2fb_temp_26 As SQLITE_C_INT Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As sqlite3_int64 Ptr
    Dim c2fb_temp_29 As c2fb_int64

    local0 = Cast(c2fb_c_int, 2ULL)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg3->op) = Cast(c2fb_c_int, 18ULL))))) Then
        If arg2->bRowid Then
            c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, Cast(c2fb_c_int, 9ULL)))))
            local0 = c2fb_temp_0
        End If
        If (-Cast(c2fb_c_int, ((arg0 <> Cast(c2fb_c_int, 9ULL))))) Then
            ' C automatic storage declaration
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_1
            While (-Cast(c2fb_c_int, ((local1 < arg2->nCol))))
                local2 = Cast(c2fb_c_int, &O0ULL)
                CPtr(c2fb_callback_223, arg1->hook.xNew)(arg1->hook.pCtx, arg2->aiIdx[local1], CPtr(SqliteVdbeMem Ptr Ptr, @(local2)))
                sessionSerializeValue(Cast(c2fb_c_int, &O0ULL), local2, CPtr(c2fb_int64 Ptr, @(local0)))
            c2fb_flow_1:
                c2fb_temp_2 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            Wend
            c2fb_flow_0:
        End If
    Else
        If (-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, 9ULL))))) Then
            c2fb_temp_3 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, arg3->nRecord))))
            local0 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_preupdate_blobwrite(arg1->db) >= Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_4 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, arg3->nRecord))))
                local0 = c2fb_temp_4
            End If
        Else
            ' C automatic storage declaration
            local4 = arg3->aRecord
            If arg2->bRowid Then
                c2fb_temp_5 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, Cast(c2fb_c_int, (Cast(c2fb_c_int, 9ULL) + Cast(c2fb_c_int, 1ULL)))))))
                local0 = c2fb_temp_5
                c2fb_temp_6 = CPtr(UByte Ptr, (local4 + Cast(c2fb_c_int, 9ULL)))
                local4 = c2fb_temp_6
            End If
            c2fb_temp_7 = Cast(c2fb_c_int, arg2->bRowid)
            local3 = c2fb_temp_7
            While (-Cast(c2fb_c_int, ((local3 < arg2->nCol))))
                local5 = Cast(c2fb_c_int, 1ULL)
                local6 = Cast(c2fb_c_int, &O0ULL)
                ' C automatic storage declaration
                local8 = arg2->aiIdx[local3]
                local9 = Cast(c2fb_c_int, &O0ULL)
                CPtr(c2fb_callback_223, arg1->hook.xNew)(arg1->hook.pCtx, local8, CPtr(SqliteVdbeMem Ptr Ptr, @(local9)))
                If (-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, &O0ULL))))) Then
                    Return Cast(c2fb_c_int, 7ULL)
                End If
                c2fb_temp_9 = local4
                local4 = (c2fb_temp_9 + 1)
                c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
                local7 = c2fb_temp_10
                Select Case local7
                    Case Cast(c2fb_c_int, 5ULL)
                        c2fb_temp_11 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type__(local9) <> Cast(c2fb_c_int, 5ULL))))))
                        local5 = c2fb_temp_11
                    Case Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, 1ULL)
                        If (-Cast(c2fb_c_int, ((local7 = c2fb_external_sqlite3_value_type__(local9))))) Then
                            local10 = sessionGetI64(local4)
                            If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, 1ULL))))) Then
                                c2fb_temp_12 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((local10 <> c2fb_external_sqlite3_value_int64___(local9)))))))
                                local5 = c2fb_temp_12
                            Else
                                ' C automatic storage declaration
                                c2fb_temp_13 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Double Ptr, @(local11))), CPtr(Const Any Ptr, CPtr(c2fb_int64 Ptr, @(local10))), Cast(c2fb_c_int, 8ULL)))
                                c2fb_temp_14 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((local11 <> c2fb_external_sqlite3_value_double__(local9)))))))
                                local5 = c2fb_temp_14
                            End If
                        End If
                        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 8ULL))
                        local6 = c2fb_temp_15
                        c2fb_temp_16 = CPtr(UByte Ptr, (local4 + Cast(c2fb_c_int, 8ULL)))
                        local4 = c2fb_temp_16
                        Goto c2fb_flow_4
                    Case Else
                        ' C automatic storage declaration
                        c2fb_temp_17 = Cast(c2fb_c_int, sessionVarintGet(CPtr(Const UByte Ptr, local4), CPtr(c2fb_c_int Ptr, @(local12))))
                        local6 = c2fb_temp_17
                        c2fb_temp_18 = CPtr(UByte Ptr, (local4 + local6))
                        local4 = c2fb_temp_18
                        c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local6 + local12)))
                        local6 = c2fb_temp_19
                        ' C unused-parameter annotation
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 = c2fb_external_sqlite3_value_type__(local9))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local12 = c2fb_external_sqlite3_value_bytes___(local9))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, local4), CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob___(local9)), local12))))) <> 0)))))) <> 0))))) Then
                            c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                            local5 = c2fb_temp_20
                        End If
                        c2fb_temp_21 = CPtr(UByte Ptr, (local4 + local12))
                        local4 = c2fb_temp_21
                        Goto c2fb_flow_4
                End Select
                c2fb_flow_4:
                If (-Cast(c2fb_c_int, (((local5 <> 0) AndAlso (arg2->abPK[local3] <> 0))))) Then
                    c2fb_temp_22 = Cast(c2fb_int64, Cast(c2fb_c_int, (arg3->nRecord + Cast(c2fb_c_int, 2ULL))))
                    local0 = c2fb_temp_22
                    Goto c2fb_flow_2
                End If
                If local5 Then
                    c2fb_temp_23 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + local6))))))
                    local0 = c2fb_temp_23
                    sessionSerializeValue(Cast(c2fb_c_int, &O0ULL), local9, CPtr(c2fb_int64 Ptr, @(local0)))
                Else
                    If arg2->abPK[local3] Then
                        c2fb_temp_24 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) + local6))))))
                        local0 = c2fb_temp_24
                    Else
                        c2fb_temp_25 = Cast(c2fb_int64, Cast(c2fb_int64, (local0 + Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
                        local0 = c2fb_temp_25
                    End If
                End If
            c2fb_flow_3:
                c2fb_temp_8 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
            Wend
            c2fb_flow_2:
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_int64, arg3->nMaxSize))))) Then
        local13 = Cast(c2fb_int64, (local0 - Cast(c2fb_int64, arg3->nMaxSize)))
        c2fb_temp_26 = CPtr(SQLITE_C_INT Ptr, @(arg3->nMaxSize))
        c2fb_temp_27 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_26) = Cast(SQLITE_C_INT, c2fb_temp_27)
        c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
        c2fb_temp_28 = CPtr(sqlite3_int64 Ptr, @(arg1->nMaxChangesetSize))
        c2fb_temp_29 = Cast(c2fb_int64, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_28)) + Cast(c2fb_int64, local13))))
        (*c2fb_temp_28) = Cast(sqlite3_int64, c2fb_temp_29)
        c2fb_temp_29 = Cast(c2fb_int64, (*c2fb_temp_28))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Sub sessionPreupdateOneChange CDecl Alias "sessionPreupdateOneChange" (ByVal arg0 As c2fb_c_int, ByVal arg1 As c2fb_int64, ByVal arg2 As SqliteSession Ptr, ByVal arg3 As SqliteSessionTable Ptr)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As SqliteSessionStat1Context
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SQLITE_C_INT Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As SqliteSessionHook Ptr
    Dim c2fb_temp_6 As SqliteSessionHook
    Dim c2fb_temp_7 As SqliteSession Ptr Ptr
    Dim c2fb_temp_8 As SqliteSession Ptr
    Dim c2fb_temp_9 As Any Ptr Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As Any Ptr Ptr
    Dim c2fb_temp_12 As c2fb_callback_223
    Dim c2fb_temp_13 As Any Ptr Ptr
    Dim c2fb_temp_14 As c2fb_callback_223
    Dim c2fb_temp_15 As Any Ptr Ptr
    Dim c2fb_temp_16 As c2fb_callback_140
    Dim c2fb_temp_17 As Any Ptr Ptr
    Dim c2fb_temp_18 As c2fb_callback_140
    Dim local5 As SqliteVdbeMem Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Any Ptr Ptr
    Dim c2fb_temp_21 As SqliteVdbeMem Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim local6 As SqliteSessionChange Ptr
    Dim c2fb_temp_23 As SqliteSessionChange Ptr
    Dim c2fb_temp_24 As SqliteSessionChange Ptr
    Dim local7 As c2fb_int64
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_25 As SQLITE_C_INT Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_int64
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As SqliteVdbeMem Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_int64
    Dim c2fb_temp_33 As SqliteSessionChange Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Any Ptr
    Dim c2fb_temp_36 As UByte Ptr Ptr
    Dim c2fb_temp_37 As UByte Ptr
    Dim c2fb_temp_38 As c2fb_int64
    Dim c2fb_temp_39 As UByte Ptr
    Dim c2fb_temp_40 As UByte
    Dim c2fb_temp_41 As c2fb_int64
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As c2fb_c_int
    Dim local11 As SqliteVdbeMem Ptr
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_44 As UByte Ptr
    Dim c2fb_temp_45 As UByte
    Dim c2fb_temp_46 As UShort Ptr
    Dim c2fb_temp_47 As UShort
    Dim c2fb_temp_48 As SQLITE_C_INT Ptr
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As UByte Ptr
    Dim c2fb_temp_51 As UByte
    Dim c2fb_temp_52 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_53 As SqliteSessionChange Ptr
    Dim c2fb_temp_54 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_55 As SqliteSessionChange Ptr
    Dim c2fb_temp_56 As UByte Ptr
    Dim c2fb_temp_57 As UByte
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As SqliteSessionHook Ptr
    Dim c2fb_temp_60 As SqliteSessionHook
    Dim c2fb_temp_61 As SQLITE_C_INT Ptr
    Dim c2fb_temp_62 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Type<SqliteSessionStat1Context>( Type<SqliteSessionHook>( Cast(c2fb_c_int, &O0ULL), CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)), CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)), CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)), CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)) ), Cast(c2fb_c_int, &O0ULL) )
    If arg2->rc Then
        Return
    End If
    If sessionInitTable(arg2, arg3, arg2->db, CPtr(Const ZString Ptr, arg2->zDb)) Then
        Return
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, CPtr(c2fb_callback_140, arg2->hook.xCount)(arg2->hook.pCtx))
    local3 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg3->nTotalCol < local3)))) Then
        If sessionReinitTable(arg2, arg3) Then
            Return
        End If
        If sessionUpdateChanges(arg2, arg3) Then
            Return
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg3->nTotalCol <> local3)))) Then
        c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(arg2->rc))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 17ULL))
        (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        Return
    End If
    If sessionGrowHash(arg2, Cast(c2fb_c_int, &O0ULL), arg3) Then
        c2fb_temp_3 = CPtr(SQLITE_C_INT Ptr, @(arg2->rc))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        (*c2fb_temp_3) = Cast(SQLITE_C_INT, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        Return
    End If
    If arg3->bStat1 Then
        c2fb_temp_5 = CPtr(SqliteSessionHook Ptr, @(local4.hook))
        c2fb_temp_6 = arg2->hook
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(SqliteSession Ptr Ptr, @(local4.pSession))
        c2fb_temp_8 = arg2
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = CPtr(Any Ptr Ptr, @(arg2->hook.pCtx))
        c2fb_temp_10 = CPtr(Any Ptr, CPtr(SqliteSessionStat1Context Ptr, @(local4)))
        (*c2fb_temp_9) = c2fb_temp_10
        c2fb_temp_11 = CPtr(Any Ptr Ptr, @(arg2->hook.xNew))
        c2fb_temp_12 = ProcPtr(sessionStat1New)
        (*c2fb_temp_11) = CPtr(Any Ptr, c2fb_temp_12)
        c2fb_temp_12 = CPtr(c2fb_callback_223, (*c2fb_temp_11))
        c2fb_temp_13 = CPtr(Any Ptr Ptr, @(arg2->hook.xOld))
        c2fb_temp_14 = ProcPtr(sessionStat1Old)
        (*c2fb_temp_13) = CPtr(Any Ptr, c2fb_temp_14)
        c2fb_temp_14 = CPtr(c2fb_callback_223, (*c2fb_temp_13))
        c2fb_temp_15 = CPtr(Any Ptr Ptr, @(arg2->hook.xCount))
        c2fb_temp_16 = ProcPtr(sessionStat1Count)
        (*c2fb_temp_15) = CPtr(Any Ptr, c2fb_temp_16)
        c2fb_temp_16 = CPtr(c2fb_callback_140, (*c2fb_temp_15))
        c2fb_temp_17 = CPtr(Any Ptr Ptr, @(arg2->hook.xDepth))
        c2fb_temp_18 = ProcPtr(sessionStat1Depth)
        (*c2fb_temp_17) = CPtr(Any Ptr, c2fb_temp_18)
        c2fb_temp_18 = CPtr(c2fb_callback_140, (*c2fb_temp_17))
        If (-Cast(c2fb_c_int, ((CPtr(SqliteVdbeMem Ptr, arg2->pZeroBlob) = Cast(c2fb_c_int, &O0ULL))))) Then
            local5 = CPtr(SqliteVdbeMem Ptr, sqlite3ValueNew(Cast(c2fb_c_int, &O0ULL)))
            If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local2 = c2fb_temp_19
                Goto c2fb_label_0
            End If
            sqlite3ValueSetStr(CPtr(Any Ptr, local5), Cast(c2fb_c_int, &O0ULL), CPtr(Const Any Ptr, StrPtr(!"")), Cast(c2fb_c_int, &O0ULL), CPtr(sqlite3MemDestructor, 0))
            c2fb_temp_20 = CPtr(Any Ptr Ptr, @(arg2->pZeroBlob))
            c2fb_temp_21 = local5
            (*c2fb_temp_20) = CPtr(Any Ptr, c2fb_temp_21)
            c2fb_temp_21 = CPtr(SqliteVdbeMem Ptr, (*c2fb_temp_20))
        End If
    End If
    c2fb_temp_22 = Cast(c2fb_c_int, sessionPreupdateHash(arg2, arg1, arg3, (-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, 18ULL))))), CPtr(c2fb_c_int Ptr, @(local0)), CPtr(c2fb_c_int Ptr, @(local1))))
    local2 = c2fb_temp_22
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Goto c2fb_label_0
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_temp_23 = arg3->apChange[local0]
        local6 = c2fb_temp_23
        While local6
            If sessionPreupdateEqual(arg2, arg1, arg3, local6, arg0) Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_24 = local6->pNext
            local6 = c2fb_temp_24
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C unused-parameter annotation
            c2fb_temp_25 = CPtr(SQLITE_C_INT Ptr, @(arg3->nEntry))
            c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
            (*c2fb_temp_25) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_26 + 1)))
            c2fb_temp_27 = Cast(c2fb_int64, Cast(c2fb_size_t, SizeOf(SqliteSessionChange)))
            local7 = c2fb_temp_27
            c2fb_temp_28 = Cast(c2fb_c_int, arg3->bRowid)
            local8 = c2fb_temp_28
            While (-Cast(c2fb_c_int, ((local8 < arg3->nCol))))
                local9 = arg3->aiIdx[local8]
                local10 = Cast(c2fb_c_int, &O0ULL)
                If (-Cast(c2fb_c_int, ((arg0 <> Cast(c2fb_c_int, 18ULL))))) Then
                    c2fb_temp_30 = Cast(c2fb_c_int, CPtr(c2fb_callback_223, arg2->hook.xOld)(arg2->hook.pCtx, local9, CPtr(SqliteVdbeMem Ptr Ptr, @(local10))))
                    local2 = c2fb_temp_30
                Else
                    If arg3->abPK[local8] Then
                        CPtr(c2fb_callback_223, arg2->hook.xNew)(arg2->hook.pCtx, local9, CPtr(SqliteVdbeMem Ptr Ptr, @(local10)))
                        ' C unused-parameter annotation
                    End If
                End If
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_31 = Cast(c2fb_c_int, sessionSerializeValue(Cast(c2fb_c_int, &O0ULL), local10, CPtr(c2fb_int64 Ptr, @(local7))))
                    local2 = c2fb_temp_31
                End If
                If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_label_0
                End If
            c2fb_flow_3:
                c2fb_temp_29 = local8
                local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_29 + 1)))
            Wend
            c2fb_flow_2:
            If arg3->bRowid Then
                c2fb_temp_32 = Cast(c2fb_int64, Cast(c2fb_int64, (local7 + Cast(c2fb_int64, Cast(c2fb_c_int, 9ULL)))))
                local7 = c2fb_temp_32
            End If
            c2fb_temp_33 = CPtr(SqliteSessionChange Ptr, CPtr(Any Ptr, sessionMalloc64(arg2, local7)))
            local6 = c2fb_temp_33
            If (-Cast(c2fb_c_int, (local6 = 0))) Then
                c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local2 = c2fb_temp_34
                Goto c2fb_label_0
            Else
                c2fb_temp_35 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local6), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionChange))))
                c2fb_temp_36 = CPtr(UByte Ptr Ptr, @(local6->aRecord))
                c2fb_temp_37 = CPtr(UByte Ptr, CPtr(SqliteSessionChange Ptr, @(local6[Cast(c2fb_c_int, 1ULL)])))
                (*c2fb_temp_36) = c2fb_temp_37
            End If
            c2fb_temp_38 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))
            local7 = c2fb_temp_38
            If arg3->bRowid Then
                c2fb_temp_39 = CPtr(UByte Ptr, @(local6->aRecord[Cast(c2fb_c_int, &O0ULL)]))
                c2fb_temp_40 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_39) = c2fb_temp_40
                sessionPutI64(CPtr(UByte Ptr, @(local6->aRecord[Cast(c2fb_c_int, 1ULL)])), arg1)
                c2fb_temp_41 = Cast(c2fb_int64, Cast(c2fb_c_int, 9ULL))
                local7 = c2fb_temp_41
            End If
            c2fb_temp_42 = Cast(c2fb_c_int, arg3->bRowid)
            local8 = c2fb_temp_42
            While (-Cast(c2fb_c_int, ((local8 < arg3->nCol))))
                local11 = Cast(c2fb_c_int, &O0ULL)
                local12 = arg3->aiIdx[local8]
                If (-Cast(c2fb_c_int, ((arg0 <> Cast(c2fb_c_int, 18ULL))))) Then
                    CPtr(c2fb_callback_223, arg2->hook.xOld)(arg2->hook.pCtx, local12, CPtr(SqliteVdbeMem Ptr Ptr, @(local11)))
                Else
                    If arg3->abPK[local8] Then
                        CPtr(c2fb_callback_223, arg2->hook.xNew)(arg2->hook.pCtx, local12, CPtr(SqliteVdbeMem Ptr Ptr, @(local11)))
                    End If
                End If
                sessionSerializeValue(CPtr(UByte Ptr, @(local6->aRecord[local7])), local11, CPtr(c2fb_int64 Ptr, @(local7)))
            c2fb_flow_5:
                c2fb_temp_43 = local8
                local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_43 + 1)))
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, (((arg2->bIndirect <> 0) OrElse (CPtr(c2fb_callback_140, arg2->hook.xDepth)(arg2->hook.pCtx) <> 0))))) Then
                c2fb_temp_44 = CPtr(UByte Ptr, @(local6->bIndirect))
                c2fb_temp_45 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_44) = c2fb_temp_45
            End If
            c2fb_temp_46 = CPtr(UShort Ptr, @(local6->nRecordField))
            c2fb_temp_47 = Cast(UShort, arg3->nCol)
            (*c2fb_temp_46) = c2fb_temp_47
            c2fb_temp_48 = CPtr(SQLITE_C_INT Ptr, @(local6->nRecord))
            c2fb_temp_49 = Cast(c2fb_c_int, local7)
            (*c2fb_temp_48) = Cast(SQLITE_C_INT, c2fb_temp_49)
            c2fb_temp_49 = Cast(c2fb_c_int, (*c2fb_temp_48))
            c2fb_temp_50 = CPtr(UByte Ptr, @(local6->op))
            c2fb_temp_51 = Cast(UByte, arg0)
            (*c2fb_temp_50) = c2fb_temp_51
            c2fb_temp_52 = CPtr(SqliteSessionChange Ptr Ptr, @(local6->pNext))
            c2fb_temp_53 = arg3->apChange[local0]
            (*c2fb_temp_52) = c2fb_temp_53
            c2fb_temp_54 = CPtr(SqliteSessionChange Ptr Ptr, @(arg3->apChange[local0]))
            c2fb_temp_55 = local6
            (*c2fb_temp_54) = c2fb_temp_55
        Else
            If local6->bIndirect Then
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_callback_140, arg2->hook.xDepth)(arg2->hook.pCtx) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2->bIndirect = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_56 = CPtr(UByte Ptr, @(local6->bIndirect))
                    c2fb_temp_57 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_56) = c2fb_temp_57
                End If
            End If
        End If
        ' C unused-parameter annotation
        If arg2->bEnableSize Then
            c2fb_temp_58 = Cast(c2fb_c_int, sessionUpdateMaxSize(arg0, arg2, arg3, local6))
            local2 = c2fb_temp_58
        End If
    End If
    c2fb_label_0:
    If arg3->bStat1 Then
        c2fb_temp_59 = CPtr(SqliteSessionHook Ptr, @(arg2->hook))
        c2fb_temp_60 = local4.hook
        (*c2fb_temp_59) = c2fb_temp_60
    End If
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_61 = CPtr(SQLITE_C_INT Ptr, @(arg2->rc))
        c2fb_temp_62 = Cast(c2fb_c_int, local2)
        (*c2fb_temp_61) = Cast(SQLITE_C_INT, c2fb_temp_62)
        c2fb_temp_62 = Cast(c2fb_c_int, (*c2fb_temp_61))
    End If
End Sub

Private Function sessionFindTable CDecl Alias "sessionFindTable" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As SqliteSessionTable Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteSessionTable Ptr
    Dim c2fb_temp_0 As SqliteSessionTable Ptr
    Dim c2fb_temp_1 As SqliteSessionTable Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SqliteSessionTable Ptr
    Dim c2fb_temp_4 As SqliteSessionTable Ptr
    Dim c2fb_temp_5 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_6 As SqliteSessionTable Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = sqlite3Strlen30(arg1)
    ' C automatic storage declaration
    c2fb_temp_0 = arg0->pTable
    local2 = c2fb_temp_0
    While local2
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_strnicmp(CPtr(Const ZString Ptr, local2->zName), arg1, Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local2->pNext
        local2 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg0->bAutoAttach <> 0))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(Any Ptr, CPtr(c2fb_callback_225, arg0->xTableFilter)) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse (CPtr(c2fb_callback_225, arg0->xTableFilter)(arg0->pFilterCtx, arg1) <> 0))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, c2fb_sqlite3session_attach(CPtr(Any Ptr, arg0), arg1))
            local0 = c2fb_temp_2
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_3 = arg0->pTable
                local2 = c2fb_temp_3
                While (-Cast(c2fb_c_int, ((((local2) <> 0) AndAlso (local2->pNext <> 0)))))
                    c2fb_temp_4 = local2->pNext
                    local2 = c2fb_temp_4
                c2fb_flow_3:
                Wend
                c2fb_flow_2:
                ' C unused-parameter annotation
                ' C unused-parameter annotation
            End If
        End If
    End If
    ' C unused-parameter annotation
    c2fb_temp_5 = CPtr(SqliteSessionTable Ptr Ptr, @((*arg2)))
    c2fb_temp_6 = local2
    (*c2fb_temp_5) = c2fb_temp_6
    Return local0
End Function

Private Sub xPreUpdate CDecl Alias "xPreUpdate" (ByVal arg0 As Any Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_int64, ByVal arg6 As c2fb_int64)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSession Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteSession Ptr
    Dim c2fb_temp_1 As SqliteSession Ptr
    Dim local2 As SqliteSessionTable Ptr
    Dim c2fb_temp_2 As SQLITE_C_INT Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = sqlite3Strlen30(arg3)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(SqliteSession Ptr, arg0)
    local0 = c2fb_temp_0
    While local0
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((local0->bEnable = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_1
        End If
        If local0->rc Then
            Goto c2fb_flow_1
        End If
        If sqlite3_strnicmp(arg3, CPtr(Const ZString Ptr, local0->zDb), Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))) Then
            Goto c2fb_flow_1
        End If
        c2fb_temp_2 = CPtr(SQLITE_C_INT Ptr, @(local0->rc))
        c2fb_temp_3 = Cast(c2fb_c_int, sessionFindTable(local0, arg4, CPtr(SqliteSessionTable Ptr Ptr, @(local2))))
        (*c2fb_temp_2) = Cast(SQLITE_C_INT, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        If local2 Then
            ' C unused-parameter annotation
            ' C unused-parameter annotation
            sessionPreupdateOneChange(arg2, arg5, local0, local2)
            If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 23ULL))))) Then
                sessionPreupdateOneChange(Cast(c2fb_c_int, 18ULL), arg6, local0, local2)
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0->pNext
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
End Sub

Private Sub sessionPreupdateHooks CDecl Alias "sessionPreupdateHooks" (ByVal arg0 As SqliteSession Ptr)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As c2fb_callback_223
    Dim c2fb_temp_4 As Any Ptr Ptr
    Dim c2fb_temp_5 As c2fb_callback_223
    Dim c2fb_temp_6 As Any Ptr Ptr
    Dim c2fb_temp_7 As c2fb_callback_140
    Dim c2fb_temp_8 As Any Ptr Ptr
    Dim c2fb_temp_9 As c2fb_callback_140

    c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->hook.pCtx))
    c2fb_temp_1 = CPtr(Any Ptr, arg0->db)
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(Any Ptr Ptr, @(arg0->hook.xOld))
    c2fb_temp_3 = ProcPtr(sessionPreupdateOld)
    (*c2fb_temp_2) = CPtr(Any Ptr, c2fb_temp_3)
    c2fb_temp_3 = CPtr(c2fb_callback_223, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(Any Ptr Ptr, @(arg0->hook.xNew))
    c2fb_temp_5 = ProcPtr(sessionPreupdateNew)
    (*c2fb_temp_4) = CPtr(Any Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(c2fb_callback_223, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(Any Ptr Ptr, @(arg0->hook.xCount))
    c2fb_temp_7 = ProcPtr(sessionPreupdateCount)
    (*c2fb_temp_6) = CPtr(Any Ptr, c2fb_temp_7)
    c2fb_temp_7 = CPtr(c2fb_callback_140, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(Any Ptr Ptr, @(arg0->hook.xDepth))
    c2fb_temp_9 = ProcPtr(sessionPreupdateDepth)
    (*c2fb_temp_8) = CPtr(Any Ptr, c2fb_temp_9)
    c2fb_temp_9 = CPtr(c2fb_callback_140, (*c2fb_temp_8))
End Sub

Private Sub sessionDiffHooks CDecl Alias "sessionDiffHooks" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionDiffCtx Ptr)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As Any Ptr Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As c2fb_callback_223
    Dim c2fb_temp_4 As Any Ptr Ptr
    Dim c2fb_temp_5 As c2fb_callback_223
    Dim c2fb_temp_6 As Any Ptr Ptr
    Dim c2fb_temp_7 As c2fb_callback_140
    Dim c2fb_temp_8 As Any Ptr Ptr
    Dim c2fb_temp_9 As c2fb_callback_140

    c2fb_temp_0 = CPtr(Any Ptr Ptr, @(arg0->hook.pCtx))
    c2fb_temp_1 = CPtr(Any Ptr, arg1)
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(Any Ptr Ptr, @(arg0->hook.xOld))
    c2fb_temp_3 = ProcPtr(sessionDiffOld)
    (*c2fb_temp_2) = CPtr(Any Ptr, c2fb_temp_3)
    c2fb_temp_3 = CPtr(c2fb_callback_223, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(Any Ptr Ptr, @(arg0->hook.xNew))
    c2fb_temp_5 = ProcPtr(sessionDiffNew)
    (*c2fb_temp_4) = CPtr(Any Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(c2fb_callback_223, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(Any Ptr Ptr, @(arg0->hook.xCount))
    c2fb_temp_7 = ProcPtr(sessionDiffCount)
    (*c2fb_temp_6) = CPtr(Any Ptr, c2fb_temp_7)
    c2fb_temp_7 = CPtr(c2fb_callback_140, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(Any Ptr Ptr, @(arg0->hook.xDepth))
    c2fb_temp_9 = ProcPtr(sessionDiffDepth)
    (*c2fb_temp_8) = CPtr(Any Ptr, c2fb_temp_9)
    c2fb_temp_9 = CPtr(c2fb_callback_140, (*c2fb_temp_8))
End Sub

Private Function sessionDiffFindNew CDecl Alias "sessionDiffFindNew" (ByVal arg0 As c2fb_c_int, ByVal arg1 As SqliteSession Ptr, ByVal arg2 As SqliteSessionTable Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr, ByVal arg5 As ZString Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As SqliteVdbe Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As SqliteSessionDiffCtx Ptr
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As SqliteVdbe Ptr
    Dim c2fb_temp_4 As SQLITE_C_INT Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As SQLITE_C_INT Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(ZString Ptr, sessionSelectFindNew(arg3, arg4, arg2->bRowid, CPtr(Const ZString Ptr, arg2->zName), CPtr(Const ZString Ptr, arg5)))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_0
    Else
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2__(arg1->db, CPtr(Const ZString Ptr, local1), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(SqliteVdbe Ptr Ptr, @(local2)), Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            local3 = CPtr(SqliteSessionDiffCtx Ptr, arg1->hook.pCtx)
            c2fb_temp_2 = CPtr(Any Ptr Ptr, @(local3->pStmt))
            c2fb_temp_3 = local2
            (*c2fb_temp_2) = CPtr(Any Ptr, c2fb_temp_3)
            c2fb_temp_3 = CPtr(SqliteVdbe Ptr, (*c2fb_temp_2))
            c2fb_temp_4 = CPtr(SQLITE_C_INT Ptr, @(local3->nOldOff))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_4) = Cast(SQLITE_C_INT, c2fb_temp_5)
            c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            c2fb_temp_6 = CPtr(SQLITE_C_INT Ptr, @(local3->bRowid))
            c2fb_temp_7 = Cast(c2fb_c_int, arg2->bRowid)
            (*c2fb_temp_6) = Cast(SQLITE_C_INT, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step__(local2)))))
                local4 = (IIf(arg2->bRowid, c2fb_external_sqlite3_column_int64__(local2, Cast(c2fb_c_int, &O0ULL)), Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))))
                sessionPreupdateOneChange(arg0, local4, arg1, arg2)
            c2fb_flow_1:
            Wend
            c2fb_flow_0:
            c2fb_temp_8 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize__(local2))
            local0 = c2fb_temp_8
        End If
        sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Return local0
End Function

Private Function sessionDiffFindModified CDecl Alias "sessionDiffFindModified" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local5 As SqliteVdbe Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local6 As SqliteSessionDiffCtx Ptr
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As SqliteVdbe Ptr
    Dim c2fb_temp_5 As SQLITE_C_INT Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local7 As c2fb_int64
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = CPtr(ZString Ptr, sessionExprCompareOther(arg1->nCol, CPtr(Const ZString Ptr, arg0->zDb), arg2, CPtr(Const ZString Ptr, arg1->zName), arg1->azCol, arg1->abPK))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_0
    Else
        local2 = CPtr(ZString Ptr, sessionAllCols(CPtr(Const ZString Ptr, arg0->zDb), CPtr(c2fb_source_record_51 Ptr, arg1)))
        local3 = CPtr(ZString Ptr, sessionAllCols(arg2, CPtr(c2fb_source_record_51 Ptr, arg1)))
        local4 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT %s,%s FROM \034%w\034.\034%w\034, \034%w\034.\034%w\034 WHERE %s AND (%z)"), local2, local3, arg0->zDb, arg1->zName, arg2, arg1->zName, arg3, local1))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_1
        Else
            ' C automatic storage declaration
            c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2__(arg0->db, CPtr(Const ZString Ptr, local4), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(SqliteVdbe Ptr Ptr, @(local5)), Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_2
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                local6 = CPtr(SqliteSessionDiffCtx Ptr, arg0->hook.pCtx)
                c2fb_temp_3 = CPtr(Any Ptr Ptr, @(local6->pStmt))
                c2fb_temp_4 = local5
                (*c2fb_temp_3) = CPtr(Any Ptr, c2fb_temp_4)
                c2fb_temp_4 = CPtr(SqliteVdbe Ptr, (*c2fb_temp_3))
                c2fb_temp_5 = CPtr(SQLITE_C_INT Ptr, @(local6->nOldOff))
                c2fb_temp_6 = Cast(c2fb_c_int, arg1->nCol)
                (*c2fb_temp_5) = Cast(SQLITE_C_INT, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
                While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step__(local5)))))
                    local7 = (IIf(arg1->bRowid, c2fb_external_sqlite3_column_int64__(local5, Cast(c2fb_c_int, &O0ULL)), Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))))
                    sessionPreupdateOneChange(Cast(c2fb_c_int, 23ULL), local7, arg0, arg1)
                c2fb_flow_1:
                Wend
                c2fb_flow_0:
                c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize__(local5))
                local0 = c2fb_temp_7
            End If
        End If
        sqlite3_free(CPtr(Any Ptr, local4))
        sqlite3_free(CPtr(Any Ptr, local2))
        sqlite3_free(CPtr(Any Ptr, local3))
    End If
    Return local0
End Function

Function sqlite3session_diff CDecl Alias "sqlite3session_diff" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteSessionDiffCtx
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As sqlite3 Ptr
    Dim local5 As SqliteSessionTable Ptr
    Dim c2fb_temp_3 As SQLITE_C_INT Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As SQLITE_C_INT Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As UByte Ptr
    Dim local11 As Const ZString Ptr Ptr
    Dim local12 As ZString Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local13 As SqliteVdbe Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As ZString Ptr Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As ZString Ptr Ptr
    Dim c2fb_temp_25 As ZString Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As ZString Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int

    local0 = CPtr(Const ZString Ptr, arg0->zDb)
    local1 = arg0->rc
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionDiffCtx Ptr, @(local2))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionDiffCtx))))
    sessionDiffHooks(arg0, CPtr(SqliteSessionDiffCtx Ptr, @(local2)))
    sqlite3_mutex_enter(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(arg0->db)))
    If arg3 Then
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @((*arg3)))
        c2fb_temp_2 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_1) = c2fb_temp_2
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = arg0->db
        ' C automatic storage declaration
        c2fb_temp_3 = CPtr(SQLITE_C_INT Ptr, @(arg0->bAutoAttach))
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        (*c2fb_temp_3) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        c2fb_temp_5 = Cast(c2fb_c_int, sessionFindTable(arg0, arg2, CPtr(SqliteSessionTable Ptr Ptr, @(local5))))
        local1 = c2fb_temp_5
        c2fb_temp_6 = CPtr(SQLITE_C_INT Ptr, @(arg0->bAutoAttach))
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        (*c2fb_temp_6) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 - 1)))
        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_label_0
        End If
        If sessionInitTable(arg0, local5, arg0->db, CPtr(Const ZString Ptr, arg0->zDb)) Then
            c2fb_temp_8 = Cast(c2fb_c_int, arg0->rc)
            local1 = c2fb_temp_8
            Goto c2fb_label_0
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = Cast(c2fb_c_int, &O0ULL)
            local9 = Cast(c2fb_c_int, &O0ULL)
            local10 = Cast(c2fb_c_int, &O0ULL)
            local11 = Cast(c2fb_c_int, &O0ULL)
            local12 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_9 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT * FROM %Q.sqlite_schema"), arg1))
            local12 = c2fb_temp_9
            If (-Cast(c2fb_c_int, ((local12 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local1 = c2fb_temp_10
            Else
                local13 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_11 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2__(local4, CPtr(Const ZString Ptr, local12), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(SqliteVdbe Ptr Ptr, @(local13)), Cast(c2fb_c_int, &O0ULL)))
                local1 = c2fb_temp_11
                If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 1ULL))))) Then
                    c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local1 = c2fb_temp_12
                    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                    local8 = c2fb_temp_13
                End If
                c2fb_external_sqlite3_finalize__(local13)
                sqlite3_free(CPtr(Any Ptr, local12))
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_14 = Cast(c2fb_c_int, sessionTableInfo(Cast(c2fb_c_int, &O0ULL), local4, arg1, arg2, CPtr(c2fb_c_int Ptr, @(local8)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr Ptr Ptr, @(local11)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), CPtr(UByte Ptr Ptr, @(local10)), IIf(arg0->bImplicitPK, CPtr(c2fb_c_int Ptr, @(local9)), CPtr(c2fb_c_int Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))))
                local1 = c2fb_temp_14
            End If
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((local5->nCol <> local8)))) Then
                    If (-Cast(c2fb_c_int, ((local8 <= Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 17ULL))
                        local1 = c2fb_temp_15
                        If arg3 Then
                            c2fb_temp_16 = CPtr(ZString Ptr Ptr, @((*arg3)))
                            c2fb_temp_17 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"no such table: %s.%s"), arg1, arg2))
                            (*c2fb_temp_16) = c2fb_temp_17
                        End If
                    Else
                        c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local7 = c2fb_temp_18
                    End If
                Else
                    ' C automatic storage declaration
                    c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local14 = c2fb_temp_19
                    While (-Cast(c2fb_c_int, ((local14 < local8))))
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local5->abPK[local14]) <> Cast(c2fb_c_int, local10[local14]))))) Then
                            c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local7 = c2fb_temp_21
                        End If
                        If sqlite3_stricmp(local11[local14], local5->azCol[local14]) Then
                            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local7 = c2fb_temp_22
                        End If
                        If local10[local14] Then
                            c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local6 = c2fb_temp_23
                        End If
                    c2fb_flow_1:
                        c2fb_temp_20 = local14
                        local14 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 + 1)))
                    Wend
                    c2fb_flow_0:
                End If
            End If
            sqlite3_free(CPtr(Any Ptr, CPtr(ZString Ptr, local11)))
            If local7 Then
                If arg3 Then
                    c2fb_temp_24 = CPtr(ZString Ptr Ptr, @((*arg3)))
                    c2fb_temp_25 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"table schemas do not match")))
                    (*c2fb_temp_24) = c2fb_temp_25
                End If
                c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, 17ULL))
                local1 = c2fb_temp_26
            End If
            If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_label_0
            End If
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_27 = CPtr(ZString Ptr, sessionExprComparePK(local5->nCol, local0, arg1, CPtr(Const ZString Ptr, local5->zName), local5->azCol, local5->abPK))
            local3 = c2fb_temp_27
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_28 = Cast(c2fb_c_int, sessionDiffFindNew(Cast(c2fb_c_int, 18ULL), arg0, local5, local0, arg1, local3))
            local1 = c2fb_temp_28
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_29 = Cast(c2fb_c_int, sessionDiffFindNew(Cast(c2fb_c_int, 9ULL), arg0, local5, arg1, local0, local3))
            local1 = c2fb_temp_29
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_30 = Cast(c2fb_c_int, sessionDiffFindModified(arg0, local5, arg1, CPtr(Const ZString Ptr, local3)))
            local1 = c2fb_temp_30
        End If
        sqlite3_free(CPtr(Any Ptr, local3))
    End If
    c2fb_label_0:
    sessionPreupdateHooks(arg0)
    sqlite3_mutex_leave(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(arg0->db)))
    Return local1
End Function

Function sqlite3session_create CDecl Alias "sqlite3session_create" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As SqliteSession Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSession Ptr
    Dim local1 As SqliteSession Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteSession Ptr Ptr
    Dim c2fb_temp_1 As SqliteSession Ptr
    Dim c2fb_temp_2 As SqliteSession Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As sqlite3 Ptr Ptr
    Dim c2fb_temp_5 As sqlite3 Ptr
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As SQLITE_C_INT Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As SqliteSession Ptr
    Dim c2fb_temp_12 As SqliteSession Ptr Ptr
    Dim c2fb_temp_13 As SqliteSession Ptr
    Dim c2fb_temp_14 As SqliteSession Ptr Ptr
    Dim c2fb_temp_15 As SqliteSession Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = sqlite3Strlen30(arg1)
    c2fb_temp_0 = CPtr(SqliteSession Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(SqliteSession Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(SqliteSession Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSession))) + Cast(c2fb_uint64, local2))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))))
    local0 = c2fb_temp_2
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSession))))
    c2fb_temp_4 = CPtr(sqlite3 Ptr Ptr, @(local0->db))
    c2fb_temp_5 = arg0
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(local0->zDb))
    c2fb_temp_7 = CPtr(ZString Ptr, CPtr(SqliteSession Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(SQLITE_C_INT Ptr, @(local0->bEnable))
    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_8) = Cast(SQLITE_C_INT, c2fb_temp_9)
    c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
    c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0->zDb), CPtr(Const Any Ptr, arg1), Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))))
    sessionPreupdateHooks(local0)
    sqlite3_mutex_enter(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(arg0)))
    c2fb_temp_11 = CPtr(SqliteSession Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_preupdate_hook(arg0, ProcPtr(xPreUpdate), CPtr(Any Ptr, local0))))
    local1 = c2fb_temp_11
    c2fb_temp_12 = CPtr(SqliteSession Ptr Ptr, @(local0->pNext))
    c2fb_temp_13 = local1
    (*c2fb_temp_12) = c2fb_temp_13
    sqlite3_mutex_leave(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(arg0)))
    c2fb_temp_14 = CPtr(SqliteSession Ptr Ptr, @((*arg2)))
    c2fb_temp_15 = local0
    (*c2fb_temp_14) = c2fb_temp_15
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Private Sub sessionDeleteTable CDecl Alias "sessionDeleteTable" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As SqliteSessionTable Ptr)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionTable Ptr
    Dim local1 As SqliteSessionTable Ptr
    Dim c2fb_temp_0 As SqliteSessionTable Ptr
    Dim c2fb_temp_1 As SqliteSessionTable Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As SqliteSessionTable Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local3 As SqliteSessionChange Ptr
    Dim local4 As SqliteSessionChange Ptr
    Dim c2fb_temp_5 As SqliteSessionChange Ptr
    Dim c2fb_temp_6 As SqliteSessionChange Ptr
    Dim c2fb_temp_7 As SqliteSessionChange Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = arg1
    local1 = c2fb_temp_0
    While local1
        ' C automatic storage declaration
        c2fb_temp_2 = local1->pNext
        local0 = c2fb_temp_2
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_3
        While (-Cast(c2fb_c_int, ((local2 < local1->nChange))))
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_5 = local1->apChange[local2]
            local3 = c2fb_temp_5
            While local3
                c2fb_temp_7 = local3->pNext
                local4 = c2fb_temp_7
                sessionFree(arg0, CPtr(Any Ptr, local3))
            c2fb_flow_5:
                c2fb_temp_6 = local4
                local3 = c2fb_temp_6
            Wend
            c2fb_flow_4:
        c2fb_flow_3:
            c2fb_temp_4 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
        Wend
        c2fb_flow_2:
        c2fb_external_sqlite3_finalize__(CPtr(SqliteVdbe Ptr, local1->pDfltStmt))
        sessionFree(arg0, CPtr(Any Ptr, CPtr(ZString Ptr, local1->azCol)))
        sessionFree(arg0, CPtr(Any Ptr, local1->apChange))
        sessionFree(arg0, CPtr(Any Ptr, local1))
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local1 = c2fb_temp_1
    Wend
    c2fb_flow_0:
End Sub

Sub sqlite3session_delete CDecl Alias "sqlite3session_delete" (ByVal arg0 As SqliteSession Ptr) Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As sqlite3 Ptr
    Dim local1 As SqliteSession Ptr
    Dim local2 As SqliteSession Ptr Ptr
    Dim c2fb_temp_0 As SqliteSession Ptr
    Dim c2fb_temp_1 As SqliteSession Ptr Ptr
    Dim c2fb_temp_2 As SqliteSession Ptr Ptr
    Dim c2fb_temp_3 As SqliteSession Ptr Ptr
    Dim c2fb_temp_4 As SqliteSession Ptr
    Dim c2fb_temp_5 As Any Ptr

    local0 = arg0->db
    ' C automatic storage declaration
    ' C automatic storage declaration
    sqlite3_mutex_enter(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(local0)))
    c2fb_temp_0 = CPtr(SqliteSession Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_preupdate_hook(local0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))))
    local1 = c2fb_temp_0
    c2fb_temp_1 = CPtr(SqliteSession Ptr Ptr, @(local1))
    local2 = c2fb_temp_1
    While ((-Cast(c2fb_c_int, ((((*local2)) <> Cast(c2fb_c_int, &O0ULL))))))
        If (-Cast(c2fb_c_int, ((((*local2)) = arg0)))) Then
            c2fb_temp_3 = CPtr(SqliteSession Ptr Ptr, @((*local2)))
            c2fb_temp_4 = ((*local2))->pNext
            (*c2fb_temp_3) = c2fb_temp_4
            If local1 Then
                c2fb_temp_5 = CPtr(Any Ptr, c2fb_external_sqlite3_preupdate_hook(local0, ProcPtr(xPreUpdate), CPtr(Any Ptr, local1)))
            End If
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_2 = CPtr(SqliteSession Ptr Ptr, @((((*local2))->pNext)))
        local2 = c2fb_temp_2
    Wend
    c2fb_flow_0:
    sqlite3_mutex_leave(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(local0)))
    sqlite3ValueFree(CPtr(Any Ptr, CPtr(SqliteVdbeMem Ptr, arg0->pZeroBlob)))
    sessionDeleteTable(arg0, arg0->pTable)
    sqlite3_free(CPtr(Any Ptr, arg0))
End Sub

Function sqlite3session_attach CDecl Alias "sqlite3session_attach" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As SqliteSessionTable Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SqliteSessionTable Ptr
    Dim c2fb_temp_4 As SqliteSessionTable Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_5 As SqliteSessionTable Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local4 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_12 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_13 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_14 As SqliteSessionTable Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    sqlite3_mutex_enter(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(arg0->db)))
    If (-Cast(c2fb_c_int, (arg1 = 0))) Then
        c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg0->bAutoAttach))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    Else
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, sqlite3Strlen30(arg1))
        local2 = c2fb_temp_2
        c2fb_temp_3 = arg0->pTable
        local1 = c2fb_temp_3
        While local1
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_strnicmp(CPtr(Const ZString Ptr, local1->zName), arg1, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))))))) Then
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_4 = local1->pNext
            local1 = c2fb_temp_4
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, (local1 = 0))) Then
            local3 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSessionTable))) + Cast(c2fb_uint64, local2))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))))
            c2fb_temp_5 = CPtr(SqliteSessionTable Ptr, CPtr(Any Ptr, sessionMalloc64(arg0, local3)))
            local1 = c2fb_temp_5
            If (-Cast(c2fb_c_int, (local1 = 0))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_6
            Else
                ' C automatic storage declaration
                c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionTable))))
                c2fb_temp_8 = CPtr(ZString Ptr Ptr, @(local1->zName))
                c2fb_temp_9 = CPtr(ZString Ptr, CPtr(SqliteSessionTable Ptr, @(local1[Cast(c2fb_c_int, 1ULL)])))
                (*c2fb_temp_8) = c2fb_temp_9
                c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->zName), CPtr(Const Any Ptr, arg1), Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))))
                c2fb_temp_11 = CPtr(SqliteSessionTable Ptr Ptr, @(arg0->pTable))
                local4 = c2fb_temp_11
                While (*local4)
                    ' empty C statement
                c2fb_flow_3:
                    c2fb_temp_12 = CPtr(SqliteSessionTable Ptr Ptr, @(((*local4))->pNext))
                    local4 = c2fb_temp_12
                Wend
                c2fb_flow_2:
                c2fb_temp_13 = CPtr(SqliteSessionTable Ptr Ptr, @((*local4)))
                c2fb_temp_14 = local1
                (*c2fb_temp_13) = c2fb_temp_14
            End If
        End If
    End If
    sqlite3_mutex_leave(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(arg0->db)))
    Return local0
End Function

Private Function sessionGenerateChangeset CDecl Alias "sessionGenerateChangeset" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_callback_230, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As Any Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As sqlite3 Ptr
    Dim local1 As SqliteSessionTable Ptr
    Dim local2 As SqliteSessionBuffer
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As SqliteSessionTable Ptr
    Dim c2fb_temp_6 As SqliteSessionTable Ptr
    Dim local4 As Const ZString Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As SqliteVdbe Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local10 As SqliteSessionChange Ptr
    Dim c2fb_temp_13 As SqliteSessionChange Ptr
    Dim c2fb_temp_14 As SqliteSessionChange Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As SQLITE_C_INT Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As SQLITE_C_INT Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As Any Ptr Ptr
    Dim c2fb_temp_30 As Any Ptr
    Dim c2fb_temp_31 As UByte Ptr Ptr
    Dim c2fb_temp_32 As UByte Ptr
    Dim c2fb_temp_33 As c2fb_c_int

    local0 = arg0->db
    ' C automatic storage declaration
    local2 = Type<SqliteSessionBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((CPtr(Any Ptr, arg2) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) Then
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(Any Ptr Ptr, @((*arg5)))
        c2fb_temp_3 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_2) = c2fb_temp_3
    End If
    If arg0->rc Then
        Return arg0->rc
    End If
    sqlite3_mutex_enter(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(local0)))
    c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0->db, StrPtr(!"SAVEPOINT changeset"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
    local3 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_mutex_leave(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(local0)))
        Return local3
    End If
    c2fb_temp_5 = arg0->pTable
    local1 = c2fb_temp_5
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1 <> 0)))))
        If local1->nEntry Then
            local4 = CPtr(Const ZString Ptr, local1->zName)
            ' C automatic storage declaration
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = local2.nBuf
            ' C automatic storage declaration
            local9 = local1->nCol
            c2fb_temp_7 = Cast(c2fb_c_int, sessionReinitTable(arg0, local1))
            local3 = c2fb_temp_7
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->nCol <> local9)))) <> 0))))) Then
                c2fb_temp_8 = Cast(c2fb_c_int, sessionUpdateChanges(arg0, local1))
                local3 = c2fb_temp_8
            End If
            sessionAppendTableHdr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local2))), arg1, CPtr(c2fb_source_record_51 Ptr, local1), CPtr(c2fb_c_int Ptr, @(local3)))
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_9 = Cast(c2fb_c_int, sessionSelectStmt(local0, Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr, arg0->zDb), local4, local1->bRowid, local1->nCol, local1->azCol, local1->abPK, CPtr(SqliteVdbe Ptr Ptr, @(local6)), Cast(c2fb_c_int, &O0ULL)))
                local3 = c2fb_temp_9
            End If
            c2fb_temp_10 = Cast(c2fb_c_int, local2.nBuf)
            local8 = c2fb_temp_10
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local5 = c2fb_temp_11
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 < local1->nChange)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                ' C automatic storage declaration
                c2fb_temp_13 = local1->apChange[local5]
                local10 = c2fb_temp_13
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local10 <> 0)))))
                    c2fb_temp_15 = Cast(c2fb_c_int, sessionSelectBind(local6, local1->nCol, local1->abPK, CPtr(c2fb_source_record_52 Ptr, local10)))
                    local3 = c2fb_temp_15
                    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
                        Goto c2fb_flow_5
                    End If
                    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step__(local6) = Cast(c2fb_c_int, 100ULL))))) Then
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local10->op) = Cast(c2fb_c_int, 18ULL))))) Then
                            ' C automatic storage declaration
                            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local2))), Cast(c2fb_c_int, 18ULL), CPtr(c2fb_c_int Ptr, @(local3)))
                            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local2))), local10->bIndirect, CPtr(c2fb_c_int Ptr, @(local3)))
                            c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                            local11 = c2fb_temp_16
                            While (-Cast(c2fb_c_int, ((local11 < local1->nCol))))
                                sessionAppendCol(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local2))), local6, local11, CPtr(c2fb_c_int Ptr, @(local3)))
                            c2fb_flow_7:
                                c2fb_temp_17 = local11
                                local11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_17 + 1)))
                            Wend
                            c2fb_flow_6:
                        Else
                            ' C unused-parameter annotation
                            c2fb_temp_18 = Cast(c2fb_c_int, sessionAppendUpdate(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local2))), arg1, local6, CPtr(c2fb_source_record_52 Ptr, local10), local1->abPK))
                            local3 = c2fb_temp_18
                        End If
                    Else
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local10->op) <> Cast(c2fb_c_int, 18ULL))))) Then
                            c2fb_temp_19 = Cast(c2fb_c_int, sessionAppendDelete(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local2))), arg1, CPtr(c2fb_source_record_52 Ptr, local10), local1->nCol, local1->abPK))
                            local3 = c2fb_temp_19
                        End If
                    End If
                    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_20 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(local6))
                        local3 = c2fb_temp_20
                    End If
                    If (-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2.nBuf > local8)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2.nBuf > sessionStreamChunkSizeGet())))) <> 0))))) Then
                        c2fb_temp_21 = Cast(c2fb_c_int, arg2(arg3, CPtr(Const Any Ptr, CPtr(Any Ptr, local2.aBuf)), local2.nBuf))
                        local3 = c2fb_temp_21
                        c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                        local8 = c2fb_temp_22
                        c2fb_temp_23 = CPtr(SQLITE_C_INT Ptr, @(local2.nBuf))
                        c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        (*c2fb_temp_23) = Cast(SQLITE_C_INT, c2fb_temp_24)
                        c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
                    End If
                c2fb_flow_5:
                    c2fb_temp_14 = local10->pNext
                    local10 = c2fb_temp_14
                Wend
                c2fb_flow_4:
            c2fb_flow_3:
                c2fb_temp_12 = local5
                local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
            Wend
            c2fb_flow_2:
            c2fb_external_sqlite3_finalize__(local6)
            If (-Cast(c2fb_c_int, ((local2.nBuf = local8)))) Then
                c2fb_temp_25 = CPtr(SQLITE_C_INT Ptr, @(local2.nBuf))
                c2fb_temp_26 = Cast(c2fb_c_int, local7)
                (*c2fb_temp_25) = Cast(SQLITE_C_INT, c2fb_temp_26)
                c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_6 = local1->pNext
        local1 = c2fb_temp_6
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((CPtr(Any Ptr, arg2) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_27 = CPtr(c2fb_c_int Ptr, @((*arg4)))
            c2fb_temp_28 = Cast(c2fb_c_int, local2.nBuf)
            (*c2fb_temp_27) = c2fb_temp_28
            c2fb_temp_29 = CPtr(Any Ptr Ptr, @((*arg5)))
            c2fb_temp_30 = CPtr(Any Ptr, local2.aBuf)
            (*c2fb_temp_29) = c2fb_temp_30
            c2fb_temp_31 = CPtr(UByte Ptr Ptr, @(local2.aBuf))
            c2fb_temp_32 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_31) = c2fb_temp_32
        Else
            If (-Cast(c2fb_c_int, ((local2.nBuf > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_33 = Cast(c2fb_c_int, arg2(arg3, CPtr(Const Any Ptr, CPtr(Any Ptr, local2.aBuf)), local2.nBuf))
                local3 = c2fb_temp_33
            End If
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local2.aBuf))
    c2fb_external_sqlite3_exec_(local0, StrPtr(!"RELEASE changeset"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    sqlite3_mutex_leave(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(local0)))
    Return local3
End Function

Function sqlite3session_changeset CDecl Alias "sqlite3session_changeset" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Any Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 21ULL)
    End If
    c2fb_temp_0 = Cast(c2fb_c_int, sessionGenerateChangeset(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1, arg2))
    local0 = c2fb_temp_0
    ' C unused-parameter annotation
    Return local0
End Function

Function sqlite3session_changeset_strm CDecl Alias "sqlite3session_changeset_strm" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    If (-Cast(c2fb_c_int, ((CPtr(Any Ptr, arg1) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) Then
        Return Cast(c2fb_c_int, 21ULL)
    End If
    Return sessionGenerateChangeset(arg0, Cast(c2fb_c_int, &O0ULL), arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Function

Function sqlite3session_patchset_strm CDecl Alias "sqlite3session_patchset_strm" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    If (-Cast(c2fb_c_int, ((CPtr(Any Ptr, arg1) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) Then
        Return Cast(c2fb_c_int, 21ULL)
    End If
    Return sessionGenerateChangeset(arg0, Cast(c2fb_c_int, 1ULL), arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Function

Function sqlite3session_patchset CDecl Alias "sqlite3session_patchset" (ByVal arg0 As SqliteSession Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Any Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 21ULL)
    End If
    Return sessionGenerateChangeset(arg0, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1, arg2)
End Function

Private Function sessionChangesetStart CDecl Alias "sessionChangesetStart" (ByVal arg0 As SqliteChangesetIter Ptr Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangesetIter Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteChangesetIter Ptr Ptr
    Dim c2fb_temp_1 As SqliteChangesetIter Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SqliteChangesetIter Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As UByte Ptr Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Any Ptr Ptr
    Dim c2fb_temp_10 As c2fb_callback_226
    Dim c2fb_temp_11 As Any Ptr Ptr
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As SQLITE_C_INT Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As SQLITE_C_INT Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As SQLITE_C_INT Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As SqliteChangesetIter Ptr Ptr
    Dim c2fb_temp_20 As SqliteChangesetIter Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(SqliteChangesetIter Ptr Ptr, @((*arg0)))
    c2fb_temp_1 = CPtr(SqliteChangesetIter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_size_t, SizeOf(SqliteChangesetIter)))
    local1 = c2fb_temp_2
    c2fb_temp_3 = CPtr(SqliteChangesetIter Ptr, CPtr(Any Ptr, sqlite3_malloc(local1)))
    local0 = c2fb_temp_3
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteChangesetIter))))
    c2fb_temp_5 = CPtr(UByte Ptr Ptr, @(local0->in.aData))
    c2fb_temp_6 = CPtr(UByte Ptr, arg4)
    (*c2fb_temp_5) = c2fb_temp_6
    c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(local0->in.nData))
    c2fb_temp_8 = Cast(c2fb_c_int, arg3)
    (*c2fb_temp_7) = Cast(SQLITE_C_INT, c2fb_temp_8)
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    c2fb_temp_9 = CPtr(Any Ptr Ptr, @(local0->in.xInput))
    c2fb_temp_10 = arg1
    (*c2fb_temp_9) = CPtr(Any Ptr, c2fb_temp_10)
    c2fb_temp_10 = CPtr(c2fb_callback_226, (*c2fb_temp_9))
    c2fb_temp_11 = CPtr(Any Ptr Ptr, @(local0->in.pIn))
    c2fb_temp_12 = arg2
    (*c2fb_temp_11) = c2fb_temp_12
    c2fb_temp_13 = CPtr(SQLITE_C_INT Ptr, @(local0->in.bEof))
    c2fb_temp_14 = Cast(c2fb_c_int, (IIf(arg1, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_13) = Cast(SQLITE_C_INT, c2fb_temp_14)
    c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
    c2fb_temp_15 = CPtr(SQLITE_C_INT Ptr, @(local0->bInvert))
    c2fb_temp_16 = Cast(c2fb_c_int, arg5)
    (*c2fb_temp_15) = Cast(SQLITE_C_INT, c2fb_temp_16)
    c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
    c2fb_temp_17 = CPtr(SQLITE_C_INT Ptr, @(local0->bSkipEmpty))
    c2fb_temp_18 = Cast(c2fb_c_int, arg6)
    (*c2fb_temp_17) = Cast(SQLITE_C_INT, c2fb_temp_18)
    c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
    c2fb_temp_19 = CPtr(SqliteChangesetIter Ptr Ptr, @((*arg0)))
    c2fb_temp_20 = local0
    (*c2fb_temp_19) = c2fb_temp_20
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Function sqlite3changeset_start CDecl Alias "sqlite3changeset_start" (ByVal arg0 As SqliteChangesetIter Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetStart(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Function

Function sqlite3changeset_start_v2 CDecl Alias "sqlite3changeset_start_v2" (ByVal arg0 As SqliteChangesetIter Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int

    local0 = (-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0002ULL)))) = 0))) = 0)))
    Return sessionChangesetStart(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1, arg2, local0, Cast(c2fb_c_int, &O0ULL))
End Function

Function sqlite3changeset_start_strm CDecl Alias "sqlite3changeset_start_strm" (ByVal arg0 As SqliteChangesetIter Ptr Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetStart(arg0, arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Function

Function sqlite3changeset_start_v2_strm CDecl Alias "sqlite3changeset_start_v2_strm" (ByVal arg0 As SqliteChangesetIter Ptr Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int

    local0 = (-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H0002ULL)))) = 0))) = 0)))
    Return sessionChangesetStart(arg0, arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), local0, Cast(c2fb_c_int, &O0ULL))
End Function

Private Sub sessionDiscardData CDecl Alias "sessionDiscardData" (ByVal arg0 As SqliteSessionInput Ptr)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SQLITE_C_INT Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As SQLITE_C_INT Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((CPtr(c2fb_callback_226, arg0->xInput) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->iCurrent >= sessionStreamChunkSizeGet())))) <> 0))))) Then
        local0 = Cast(c2fb_c_int, (arg0->buf.nBuf - arg0->iCurrent))
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, ((local0 > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, arg0->buf.aBuf), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(arg0->buf.aBuf[arg0->iCurrent]))), local0))
        End If
        c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(arg0->buf.nBuf))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_1)) - arg0->iCurrent)))
        (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_3)) - arg0->iCurrent)))
        (*c2fb_temp_3) = Cast(SQLITE_C_INT, c2fb_temp_4)
        c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        c2fb_temp_5 = CPtr(SQLITE_C_INT Ptr, @(arg0->iCurrent))
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_5) = Cast(SQLITE_C_INT, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(arg0->nData))
        c2fb_temp_8 = Cast(c2fb_c_int, arg0->buf.nBuf)
        (*c2fb_temp_7) = Cast(SQLITE_C_INT, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    End If
End Sub

Private Function sessionInputBuffer CDecl Alias "sessionInputBuffer" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SQLITE_C_INT Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As UByte Ptr Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If CPtr(c2fb_callback_226, arg0->xInput) Then
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (arg0->bEof = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->iNext + arg1))) >= arg0->nData)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
            local1 = sessionStreamChunkSizeGet()
            If (-Cast(c2fb_c_int, ((arg0->bNoDiscard = Cast(c2fb_c_int, &O0ULL))))) Then
                sessionDiscardData(arg0)
            End If
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionBufferGrow(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->buf))), local1, CPtr(c2fb_c_int Ptr, @(local0))))))) Then
                c2fb_temp_0 = Cast(c2fb_c_int, CPtr(c2fb_callback_226, arg0->xInput)(arg0->pIn, CPtr(Any Ptr, CPtr(UByte Ptr, @(arg0->buf.aBuf[arg0->buf.nBuf]))), CPtr(c2fb_c_int Ptr, @(local1))))
                local0 = c2fb_temp_0
                If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(arg0->bEof))
                    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
                    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
                Else
                    c2fb_temp_3 = CPtr(SQLITE_C_INT Ptr, @(arg0->buf.nBuf))
                    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_3)) + local1)))
                    (*c2fb_temp_3) = Cast(SQLITE_C_INT, c2fb_temp_4)
                    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
                End If
            End If
            c2fb_temp_5 = CPtr(UByte Ptr Ptr, @(arg0->aData))
            c2fb_temp_6 = arg0->buf.aBuf
            (*c2fb_temp_5) = c2fb_temp_6
            c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(arg0->nData))
            c2fb_temp_8 = Cast(c2fb_c_int, arg0->buf.nBuf)
            (*c2fb_temp_7) = Cast(SQLITE_C_INT, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
    End If
    Return local0
End Function

Private Function sessionReadRecord CDecl Alias "sessionReadRecord" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As SqliteVdbeMem Ptr Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As SQLITE_C_INT Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_12 As SqliteVdbeMem Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_14 As SQLITE_C_INT Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim local6 As UByte
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As SQLITE_C_INT Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim local7 As c2fb_int64
    Dim local8 As Double
    Dim c2fb_temp_22 As Any Ptr
    Dim c2fb_temp_23 As SQLITE_C_INT Ptr
    Dim c2fb_temp_24 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If arg4 Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        local2 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg2[local0]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Goto c2fb_flow_1
        End If
        c2fb_temp_4 = Cast(c2fb_c_int, sessionInputBuffer(arg0, Cast(c2fb_c_int, 9ULL)))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((arg0->iNext >= arg0->nData)))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3609ULL)))
                local1 = c2fb_temp_5
            Else
                c2fb_temp_6 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
                (*c2fb_temp_6) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
                c2fb_temp_8 = Cast(c2fb_c_int, arg0->aData[c2fb_temp_7])
                local2 = c2fb_temp_8
                ' C unused-parameter annotation
                If local2 Then
                    If arg4 Then
                        c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg4)))
                        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        (*c2fb_temp_9) = c2fb_temp_10
                    End If
                    c2fb_temp_11 = CPtr(SqliteVdbeMem Ptr Ptr, @(arg3[local0]))
                    c2fb_temp_12 = CPtr(SqliteVdbeMem Ptr, sqlite3ValueNew(Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_11) = c2fb_temp_12
                    If (-Cast(c2fb_c_int, (arg3[local0] = 0))) Then
                        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                        local1 = c2fb_temp_13
                    End If
                End If
            End If
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            local3 = CPtr(UByte Ptr, @(arg0->aData[arg0->iNext]))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                ' C automatic storage declaration
                local5 = Cast(c2fb_c_int, (arg0->nData - arg0->iNext))
                c2fb_temp_14 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_14)) + sessionVarintGetSafe(CPtr(Const UByte Ptr, local3), local5, CPtr(c2fb_c_int Ptr, @(local4))))))
                (*c2fb_temp_14) = Cast(SQLITE_C_INT, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                c2fb_temp_16 = Cast(c2fb_c_int, sessionInputBuffer(arg0, local4))
                local1 = c2fb_temp_16
                If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 > Cast(c2fb_c_int, (arg0->nData - arg0->iNext)))))) <> 0))))) Then
                        c2fb_temp_17 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3630ULL)))
                        local1 = c2fb_temp_17
                    Else
                        local6 = (IIf((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 3ULL))))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL)))
                        c2fb_temp_18 = Cast(c2fb_c_int, sessionValueSetStr(arg3[local0], CPtr(UByte Ptr, @(arg0->aData[arg0->iNext])), local4, local6))
                        local1 = c2fb_temp_18
                        c2fb_temp_19 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                        c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_19)) + local4)))
                        (*c2fb_temp_19) = Cast(SQLITE_C_INT, c2fb_temp_20)
                        c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
                    End If
                End If
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->nData - arg0->iNext))) < Cast(c2fb_c_int, 8ULL))))) Then
                    c2fb_temp_21 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3640ULL)))
                    local1 = c2fb_temp_21
                Else
                    local7 = sessionGetI64(local3)
                    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) Then
                        sqlite3VdbeMemSetInt64(CPtr(Any Ptr, arg3[local0]), local7)
                    Else
                        ' C automatic storage declaration
                        c2fb_temp_22 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Double Ptr, @(local8))), CPtr(Const Any Ptr, CPtr(c2fb_int64 Ptr, @(local7))), Cast(c2fb_c_int, 8ULL)))
                        sqlite3VdbeMemSetDouble(CPtr(Any Ptr, arg3[local0]), local8)
                    End If
                    c2fb_temp_23 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                    c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_23)) + Cast(c2fb_c_int, 8ULL))))
                    (*c2fb_temp_23) = Cast(SQLITE_C_INT, c2fb_temp_24)
                    c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
                End If
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_3 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function

Private Function sessionChangesetBufferTblhdr CDecl Alias "sessionChangesetBufferTblhdr" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, sessionInputBuffer(arg0, Cast(c2fb_c_int, 9ULL)))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        local3 = Cast(c2fb_c_int, (arg0->nData - arg0->iNext))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + sessionVarintGetSafe(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->aData[arg0->iNext]))), local3, CPtr(c2fb_c_int Ptr, @(local1))))))
        local2 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, 65536ULL))))) <> 0))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3689ULL)))
            local0 = c2fb_temp_2
        Else
            c2fb_temp_3 = Cast(c2fb_c_int, sessionInputBuffer(arg0, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local2 + local1)) + Cast(c2fb_c_int, 100ULL)))))
            local0 = c2fb_temp_3
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + local1)))
            local2 = c2fb_temp_4
        End If
    End If
    While (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL)))))
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->iNext + local2))) < arg0->nData)))) <> 0) AndAlso (arg0->aData[Cast(c2fb_c_int, (arg0->iNext + local2))] <> 0)))))
            c2fb_temp_5 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->iNext + local2))) < arg0->nData)))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_6 = Cast(c2fb_c_int, sessionInputBuffer(arg0, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 100ULL)))))
        local0 = c2fb_temp_6
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->iNext + local2))) >= arg0->nData)))) <> 0))))) Then
            c2fb_temp_7 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3707ULL)))
            local0 = c2fb_temp_7
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_8) = c2fb_temp_9
    Return local0
End Function

Private Function sessionChangesetBufferRecord CDecl Alias "sessionChangesetBufferRecord" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_int64
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < arg1)))) <> 0)))))
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, sessionInputBuffer(arg0, Cast(c2fb_int64, (local1 + Cast(c2fb_int64, Cast(c2fb_c_int, 10ULL))))))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_int64, (Cast(c2fb_int64, arg0->iNext) + local1)) >= Cast(c2fb_int64, arg0->nData))))) Then
                c2fb_temp_3 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3736ULL)))
                local0 = c2fb_temp_3
            Else
                c2fb_temp_5 = arg0->iNext
                c2fb_temp_4 = local1
                local1 = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_4 + 1)))
                c2fb_temp_6 = Cast(c2fb_c_int, arg0->aData[Cast(c2fb_int64, (Cast(c2fb_int64, c2fb_temp_5) + c2fb_temp_4))])
                local3 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                    ' C automatic storage declaration
                    local5 = Cast(c2fb_int64, (Cast(c2fb_int64, arg0->nData) - (Cast(c2fb_int64, (Cast(c2fb_int64, arg0->iNext) + local1)))))
                    c2fb_temp_7 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 + Cast(c2fb_int64, sessionVarintGetSafe(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->aData[Cast(c2fb_int64, (Cast(c2fb_int64, arg0->iNext) + local1))]))), local5, CPtr(c2fb_c_int Ptr, @(local4)))))))
                    local1 = c2fb_temp_7
                    c2fb_temp_8 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 + Cast(c2fb_int64, local4))))
                    local1 = c2fb_temp_8
                    c2fb_temp_9 = Cast(c2fb_c_int, sessionInputBuffer(arg0, local1))
                    local0 = c2fb_temp_9
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                        c2fb_temp_10 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 + Cast(c2fb_int64, Cast(c2fb_c_int, 8ULL)))))
                        local1 = c2fb_temp_10
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 5ULL))))) <> 0))))) Then
                            c2fb_temp_11 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3748ULL)))
                            local0 = c2fb_temp_11
                        End If
                    End If
                End If
            End If
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((Cast(c2fb_int64, (Cast(c2fb_int64, arg0->iNext) + local1))) > Cast(c2fb_int64, arg0->nData))))) <> 0))))) Then
            c2fb_temp_12 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3753ULL)))
            local0 = c2fb_temp_12
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_14 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_13) = c2fb_temp_14
    Return local0
End Function

Private Function sessionChangesetReadTblhdr CDecl Alias "sessionChangesetReadTblhdr" (ByVal arg0 As SqliteChangesetIter Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As SQLITE_C_INT Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As SQLITE_C_INT Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local4 As c2fb_size_t
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As SQLITE_C_INT Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As Any Ptr Ptr Ptr
    Dim c2fb_temp_14 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_15 As UByte Ptr Ptr
    Dim c2fb_temp_16 As UByte Ptr
    Dim c2fb_temp_17 As ZString Ptr Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As UByte Ptr Ptr
    Dim c2fb_temp_20 As UByte Ptr
    Dim c2fb_temp_21 As ZString Ptr Ptr
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As SQLITE_C_INT Ptr
    Dim c2fb_temp_24 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, sessionChangesetBufferTblhdr(CPtr(SqliteSessionInput Ptr, @(arg0->in)), CPtr(c2fb_c_int Ptr, @(local1))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, sessionVarintGet(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->in.aData[arg0->in.iNext]))), CPtr(c2fb_c_int Ptr, @(arg0->nCol))))
        local3 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((arg0->nCol > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local1 - local3)))
            local1 = c2fb_temp_2
            c2fb_temp_3 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.iNext))
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_3)) + local3)))
            (*c2fb_temp_3) = Cast(SQLITE_C_INT, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, arg0->nCol) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteVdbeMem Ptr))))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))) + Cast(c2fb_uint64, local1))))
            local2 = c2fb_temp_5
            c2fb_temp_6 = CPtr(SQLITE_C_INT Ptr, @(arg0->tblhdr.nBuf))
            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_6) = Cast(SQLITE_C_INT, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            sessionBufferGrow(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->tblhdr))), local2, CPtr(c2fb_c_int Ptr, @(local0)))
        Else
            c2fb_temp_8 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3794ULL)))
            local0 = c2fb_temp_8
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        local4 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteVdbeMem Ptr))) * Cast(c2fb_uint64, arg0->nCol))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))))
        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0->tblhdr.aBuf), Cast(c2fb_c_int, &O0ULL), local4))
        c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg0->tblhdr.aBuf[local4]))), CPtr(Const Any Ptr, CPtr(UByte Ptr, @(arg0->in.aData[arg0->in.iNext]))), local1))
        c2fb_temp_11 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.iNext))
        c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_11)) + local1)))
        (*c2fb_temp_11) = Cast(SQLITE_C_INT, c2fb_temp_12)
        c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
    End If
    c2fb_temp_13 = CPtr(Any Ptr Ptr Ptr, @(arg0->apValue))
    c2fb_temp_14 = CPtr(SqliteVdbeMem Ptr Ptr, arg0->tblhdr.aBuf)
    (*c2fb_temp_13) = CPtr(Any Ptr Ptr, c2fb_temp_14)
    c2fb_temp_14 = CPtr(SqliteVdbeMem Ptr Ptr, (*c2fb_temp_13))
    If (-Cast(c2fb_c_int, ((CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_15 = CPtr(UByte Ptr Ptr, @(arg0->abPK))
        c2fb_temp_16 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_15) = c2fb_temp_16
        c2fb_temp_17 = CPtr(ZString Ptr Ptr, @(arg0->zTab))
        c2fb_temp_18 = CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_17) = c2fb_temp_18
    Else
        c2fb_temp_19 = CPtr(UByte Ptr Ptr, @(arg0->abPK))
        c2fb_temp_20 = CPtr(UByte Ptr, CPtr(SqliteVdbeMem Ptr Ptr, @(CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[Cast(c2fb_c_int, (arg0->nCol * Cast(c2fb_c_int, 2ULL)))])))
        (*c2fb_temp_19) = c2fb_temp_20
        c2fb_temp_21 = CPtr(ZString Ptr Ptr, @(arg0->zTab))
        c2fb_temp_22 = IIf(arg0->abPK, CPtr(ZString Ptr, CPtr(UByte Ptr, @(arg0->abPK[arg0->nCol]))), CPtr(ZString Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))
        (*c2fb_temp_21) = c2fb_temp_22
    End If
    c2fb_temp_23 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
    c2fb_temp_24 = Cast(c2fb_c_int, local0)
    (*c2fb_temp_23) = Cast(SQLITE_C_INT, c2fb_temp_24)
    c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
    Return (c2fb_temp_24)
End Function

Private Function sessionChangesetNextOne CDecl Alias "sessionChangesetNextOne" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As UByte
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As SQLITE_C_INT Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As SQLITE_C_INT Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As UByte
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As SQLITE_C_INT Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As SQLITE_C_INT Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As SQLITE_C_INT Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As SQLITE_C_INT Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As UByte
    Dim c2fb_temp_21 As SQLITE_C_INT Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As SQLITE_C_INT Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As SQLITE_C_INT Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As SQLITE_C_INT Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As SQLITE_C_INT Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As SQLITE_C_INT Ptr
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As UByte Ptr Ptr
    Dim c2fb_temp_40 As UByte Ptr
    Dim c2fb_temp_41 As SQLITE_C_INT Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim local3 As SqliteVdbeMem Ptr Ptr
    Dim local4 As SqliteVdbeMem Ptr Ptr
    Dim local5 As UByte Ptr
    Dim c2fb_temp_43 As SQLITE_C_INT Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As SQLITE_C_INT Ptr
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As Any Ptr Ptr
    Dim c2fb_temp_50 As SqliteVdbeMem Ptr
    Dim c2fb_temp_51 As SQLITE_C_INT Ptr
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As Any Ptr Ptr
    Dim c2fb_temp_54 As SqliteVdbeMem Ptr
    Dim c2fb_temp_55 As SQLITE_C_INT Ptr
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As SQLITE_C_INT Ptr
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As c2fb_c_int
    Dim c2fb_temp_60 As c2fb_c_int
    Dim c2fb_temp_61 As Any Ptr Ptr
    Dim c2fb_temp_62 As SqliteVdbeMem Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return arg0->rc
    End If
    If CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_int, (arg0->nCol * Cast(c2fb_c_int, 2ULL)))))))
            sqlite3ValueFree(CPtr(Any Ptr, CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[local0]))
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteVdbeMem Ptr))) * Cast(c2fb_uint64, arg0->nCol))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))))))
    End If
    c2fb_temp_3 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
    c2fb_temp_4 = Cast(c2fb_c_int, sessionInputBuffer(CPtr(SqliteSessionInput Ptr, @(arg0->in)), Cast(c2fb_c_int, 2ULL)))
    (*c2fb_temp_3) = Cast(SQLITE_C_INT, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return arg0->rc
    End If
    c2fb_temp_5 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.iCurrent))
    c2fb_temp_6 = Cast(c2fb_c_int, arg0->in.iNext)
    (*c2fb_temp_5) = Cast(SQLITE_C_INT, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    sessionDiscardData(CPtr(SqliteSessionInput Ptr, @(arg0->in)))
    If (-Cast(c2fb_c_int, ((arg0->in.iNext >= arg0->in.nData)))) Then
        Return Cast(c2fb_c_int, 101ULL)
    End If
    c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.iNext))
    c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    (*c2fb_temp_7) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
    c2fb_temp_9 = Cast(UByte, arg0->in.aData[c2fb_temp_8])
    local1 = c2fb_temp_9
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, 84))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, 80))))) <> 0)))))
        If arg3 Then
            c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg3)))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_10) = c2fb_temp_11
        End If
        c2fb_temp_12 = CPtr(SQLITE_C_INT Ptr, @(arg0->bPatchset))
        c2fb_temp_13 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, 80)))))))
        (*c2fb_temp_12) = Cast(SQLITE_C_INT, c2fb_temp_13)
        c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
        If sessionChangesetReadTblhdr(arg0) Then
            Return arg0->rc
        End If
        c2fb_temp_14 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
        c2fb_temp_15 = Cast(c2fb_c_int, sessionInputBuffer(CPtr(SqliteSessionInput Ptr, @(arg0->in)), Cast(c2fb_c_int, 2ULL)))
        (*c2fb_temp_14) = Cast(SQLITE_C_INT, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
        If (c2fb_temp_15) Then
            Return arg0->rc
        End If
        c2fb_temp_16 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.iCurrent))
        c2fb_temp_17 = Cast(c2fb_c_int, arg0->in.iNext)
        (*c2fb_temp_16) = Cast(SQLITE_C_INT, c2fb_temp_17)
        c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
        If (-Cast(c2fb_c_int, ((arg0->in.iNext >= arg0->in.nData)))) Then
            Return Cast(c2fb_c_int, 101ULL)
        End If
        c2fb_temp_18 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.iNext))
        c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
        (*c2fb_temp_18) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_19 + 1)))
        c2fb_temp_20 = Cast(UByte, arg0->in.aData[c2fb_temp_19])
        local1 = c2fb_temp_20
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->zTab = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg0->bPatchset <> 0) AndAlso (arg0->bInvert <> 0)))))) <> 0))))) Then
        ' C unused-parameter annotation
        c2fb_temp_21 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
        c2fb_temp_22 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3880ULL)))
        (*c2fb_temp_21) = Cast(SQLITE_C_INT, c2fb_temp_22)
        c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
        Return (c2fb_temp_22)
    End If
    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) <> Cast(c2fb_c_int, 23ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) <> Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) <> Cast(c2fb_c_int, 18ULL))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((arg0->in.iNext >= arg0->in.nData))))) <> 0))))) Then
        c2fb_temp_23 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
        c2fb_temp_24 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3886ULL)))
        (*c2fb_temp_23) = Cast(SQLITE_C_INT, c2fb_temp_24)
        c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
        Return (c2fb_temp_24)
    End If
    c2fb_temp_25 = CPtr(SQLITE_C_INT Ptr, @(arg0->op))
    c2fb_temp_26 = Cast(c2fb_c_int, local1)
    (*c2fb_temp_25) = Cast(SQLITE_C_INT, c2fb_temp_26)
    c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
    c2fb_temp_29 = CPtr(SQLITE_C_INT Ptr, @(arg0->bIndirect))
    c2fb_temp_27 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.iNext))
    c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
    (*c2fb_temp_27) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_28 + 1)))
    c2fb_temp_30 = Cast(c2fb_c_int, arg0->in.aData[c2fb_temp_28])
    (*c2fb_temp_29) = Cast(SQLITE_C_INT, c2fb_temp_30)
    c2fb_temp_30 = Cast(c2fb_c_int, (*c2fb_temp_29))
    If arg1 Then
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->bPatchset = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, 23ULL))))) <> 0))))) Then
            c2fb_temp_31 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg0->nCol * Cast(c2fb_c_int, 2ULL))))
            local2 = c2fb_temp_31
        Else
            If (-Cast(c2fb_c_int, (((arg0->bPatchset <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1) = Cast(c2fb_c_int, 9ULL))))) <> 0))))) Then
                c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local2 = c2fb_temp_32
                c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local0 = c2fb_temp_33
                While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
                    If arg0->abPK[local0] Then
                        c2fb_temp_35 = local2
                        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_35 + 1)))
                    End If
                c2fb_flow_5:
                    c2fb_temp_34 = local0
                    local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_34 + 1)))
                Wend
                c2fb_flow_4:
            Else
                c2fb_temp_36 = Cast(c2fb_c_int, arg0->nCol)
                local2 = c2fb_temp_36
            End If
        End If
        c2fb_temp_37 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
        c2fb_temp_38 = Cast(c2fb_c_int, sessionChangesetBufferRecord(CPtr(SqliteSessionInput Ptr, @(arg0->in)), local2, arg2))
        (*c2fb_temp_37) = Cast(SQLITE_C_INT, c2fb_temp_38)
        c2fb_temp_38 = Cast(c2fb_c_int, (*c2fb_temp_37))
        If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return arg0->rc
        End If
        c2fb_temp_39 = CPtr(UByte Ptr Ptr, @((*arg1)))
        c2fb_temp_40 = CPtr(UByte Ptr, @(arg0->in.aData[arg0->in.iNext]))
        (*c2fb_temp_39) = c2fb_temp_40
        c2fb_temp_41 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.iNext))
        c2fb_temp_42 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_41)) + (*arg2))))
        (*c2fb_temp_41) = Cast(SQLITE_C_INT, c2fb_temp_42)
        c2fb_temp_42 = Cast(c2fb_c_int, (*c2fb_temp_41))
    Else
        local3 = (IIf(arg0->bInvert, CPtr(SqliteVdbeMem Ptr Ptr, @(CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[arg0->nCol])), CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue)))
        local4 = (IIf(arg0->bInvert, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue), CPtr(SqliteVdbeMem Ptr Ptr, @(CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[arg0->nCol]))))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->op <> Cast(c2fb_c_int, 18ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->bPatchset = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->op = Cast(c2fb_c_int, 9ULL))))) <> 0)))))) <> 0))))) Then
            local5 = IIf(arg0->bPatchset, arg0->abPK, CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))))
            c2fb_temp_43 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
            c2fb_temp_44 = Cast(c2fb_c_int, sessionReadRecord(CPtr(SqliteSessionInput Ptr, @(arg0->in)), arg0->nCol, local5, local3, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_43) = Cast(SQLITE_C_INT, c2fb_temp_44)
            c2fb_temp_44 = Cast(c2fb_c_int, (*c2fb_temp_43))
            If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return arg0->rc
            End If
        End If
        If (-Cast(c2fb_c_int, ((arg0->op <> Cast(c2fb_c_int, 9ULL))))) Then
            c2fb_temp_45 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
            c2fb_temp_46 = Cast(c2fb_c_int, sessionReadRecord(CPtr(SqliteSessionInput Ptr, @(arg0->in)), arg0->nCol, Cast(c2fb_c_int, &O0ULL), local4, arg4))
            (*c2fb_temp_45) = Cast(SQLITE_C_INT, c2fb_temp_46)
            c2fb_temp_46 = Cast(c2fb_c_int, (*c2fb_temp_45))
            If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return arg0->rc
            End If
        End If
        If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, (((arg0->bPatchset <> 0) OrElse (arg0->bInvert <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->op = Cast(c2fb_c_int, 23ULL))))) <> 0))))) Then
            c2fb_temp_47 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_47
            While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
                ' C unused-parameter annotation
                If arg0->abPK[local0] Then
                    ' C unused-parameter annotation
                    c2fb_temp_49 = CPtr(Any Ptr Ptr, @(CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[local0]))
                    c2fb_temp_50 = CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[Cast(c2fb_c_int, (local0 + arg0->nCol))]
                    (*c2fb_temp_49) = CPtr(Any Ptr, c2fb_temp_50)
                    c2fb_temp_50 = CPtr(SqliteVdbeMem Ptr, (*c2fb_temp_49))
                    If (-Cast(c2fb_c_int, ((CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[local0] = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_51 = CPtr(SQLITE_C_INT Ptr, @(arg0->rc))
                        c2fb_temp_52 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 3932ULL)))
                        (*c2fb_temp_51) = Cast(SQLITE_C_INT, c2fb_temp_52)
                        c2fb_temp_52 = Cast(c2fb_c_int, (*c2fb_temp_51))
                        Return (c2fb_temp_52)
                    End If
                    c2fb_temp_53 = CPtr(Any Ptr Ptr, @(CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[Cast(c2fb_c_int, (local0 + arg0->nCol))]))
                    c2fb_temp_54 = CPtr(SqliteVdbeMem Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_53) = CPtr(Any Ptr, c2fb_temp_54)
                    c2fb_temp_54 = CPtr(SqliteVdbeMem Ptr, (*c2fb_temp_53))
                End If
            c2fb_flow_7:
                c2fb_temp_48 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_48 + 1)))
            Wend
            c2fb_flow_6:
        Else
            If arg0->bInvert Then
                If (-Cast(c2fb_c_int, ((arg0->op = Cast(c2fb_c_int, 18ULL))))) Then
                    c2fb_temp_55 = CPtr(SQLITE_C_INT Ptr, @(arg0->op))
                    c2fb_temp_56 = Cast(c2fb_c_int, Cast(c2fb_c_int, 9ULL))
                    (*c2fb_temp_55) = Cast(SQLITE_C_INT, c2fb_temp_56)
                    c2fb_temp_56 = Cast(c2fb_c_int, (*c2fb_temp_55))
                Else
                    If (-Cast(c2fb_c_int, ((arg0->op = Cast(c2fb_c_int, 9ULL))))) Then
                        c2fb_temp_57 = CPtr(SQLITE_C_INT Ptr, @(arg0->op))
                        c2fb_temp_58 = Cast(c2fb_c_int, Cast(c2fb_c_int, 18ULL))
                        (*c2fb_temp_57) = Cast(SQLITE_C_INT, c2fb_temp_58)
                        c2fb_temp_58 = Cast(c2fb_c_int, (*c2fb_temp_57))
                    End If
                End If
            End If
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->bPatchset = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->op = Cast(c2fb_c_int, 23ULL))))) <> 0))))) Then
            c2fb_temp_59 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_59
            While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->abPK[local0]) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[Cast(c2fb_c_int, (local0 + arg0->nCol))] = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    sqlite3ValueFree(CPtr(Any Ptr, CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[local0]))
                    c2fb_temp_61 = CPtr(Any Ptr Ptr, @(CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[local0]))
                    c2fb_temp_62 = CPtr(SqliteVdbeMem Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_61) = CPtr(Any Ptr, c2fb_temp_62)
                    c2fb_temp_62 = CPtr(SqliteVdbeMem Ptr, (*c2fb_temp_61))
                End If
            c2fb_flow_9:
                c2fb_temp_60 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_60 + 1)))
            Wend
            c2fb_flow_8:
        End If
    End If
    Return Cast(c2fb_c_int, 100ULL)
End Function

Private Function sessionChangesetNext CDecl Alias "sessionChangesetNext" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    Do
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        c2fb_temp_1 = Cast(c2fb_c_int, sessionChangesetNextOne(arg0, arg1, arg2, arg3, CPtr(c2fb_c_int Ptr, @(local0))))
        local1 = c2fb_temp_1
    c2fb_flow_1:
    Loop While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 100ULL))))) <> 0) AndAlso (arg0->bSkipEmpty <> 0) AndAlso (local0 <> 0)))))
    c2fb_flow_0:
    Return local1
End Function

Function sqlite3changeset_next CDecl Alias "sqlite3changeset_next" (ByVal arg0 As SqliteChangesetIter Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetNext(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Function

Function sqlite3changeset_op CDecl Alias "sqlite3changeset_op" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Const ZString Ptr Ptr
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_1 = Cast(c2fb_c_int, arg0->op)
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_3 = Cast(c2fb_c_int, arg0->nCol)
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
    c2fb_temp_5 = CPtr(Const ZString Ptr, arg0->zTab)
    (*c2fb_temp_4) = c2fb_temp_5
    If arg4 Then
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg4)))
        c2fb_temp_7 = Cast(c2fb_c_int, arg0->bIndirect)
        (*c2fb_temp_6) = c2fb_temp_7
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Function sqlite3changeset_pk CDecl Alias "sqlite3changeset_pk" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As UByte Ptr Ptr
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    c2fb_temp_0 = CPtr(UByte Ptr Ptr, @((*arg1)))
    c2fb_temp_1 = arg0->abPK
    (*c2fb_temp_0) = c2fb_temp_1
    If arg2 Then
        c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_3 = Cast(c2fb_c_int, arg0->nCol)
        (*c2fb_temp_2) = c2fb_temp_3
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Function sqlite3changeset_old CDecl Alias "sqlite3changeset_old" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_1 As SqliteVdbeMem Ptr

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->op <> Cast(c2fb_c_int, 23ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->op <> Cast(c2fb_c_int, 9ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 21ULL)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= arg0->nCol)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 25ULL)
    End If
    c2fb_temp_0 = CPtr(SqliteVdbeMem Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[arg1]
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Function sqlite3changeset_new CDecl Alias "sqlite3changeset_new" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_1 As SqliteVdbeMem Ptr

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->op <> Cast(c2fb_c_int, 23ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->op <> Cast(c2fb_c_int, 18ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 21ULL)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= arg0->nCol)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 25ULL)
    End If
    c2fb_temp_0 = CPtr(SqliteVdbeMem Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[Cast(c2fb_c_int, (arg0->nCol + arg1))]
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Function sqlite3changeset_conflict CDecl Alias "sqlite3changeset_conflict" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_1 As SqliteVdbeMem Ptr

    If (-Cast(c2fb_c_int, (CPtr(SqliteVdbe Ptr, arg0->pConflict) = 0))) Then
        Return Cast(c2fb_c_int, 21ULL)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 >= arg0->nCol)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 25ULL)
    End If
    c2fb_temp_0 = CPtr(SqliteVdbeMem Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(SqliteVdbeMem Ptr, c2fb_external_sqlite3_column_value__(CPtr(SqliteVdbe Ptr, arg0->pConflict), arg1))
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Function sqlite3changeset_fk_conflicts CDecl Alias "sqlite3changeset_fk_conflicts" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((CPtr(SqliteVdbe Ptr, arg0->pConflict) <> 0) OrElse (CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue) <> 0))))) Then
        Return Cast(c2fb_c_int, 21ULL)
    End If
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_c_int, arg0->nCol)
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function

Function sqlite3changeset_finalize CDecl Alias "sqlite3changeset_finalize" (ByVal arg0 As SqliteChangesetIter Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, arg0->rc)
        local0 = c2fb_temp_0
        If CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue) Then
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_1
            While (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, (arg0->nCol * Cast(c2fb_c_int, 2ULL)))))))
                sqlite3ValueFree(CPtr(Any Ptr, CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, arg0->apValue))[local1]))
            c2fb_flow_1:
                c2fb_temp_2 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            Wend
            c2fb_flow_0:
        End If
        sqlite3_free(CPtr(Any Ptr, arg0->tblhdr.aBuf))
        sqlite3_free(CPtr(Any Ptr, arg0->in.buf.aBuf))
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
    Return local0
End Function

Private Function sessionChangesetInvert CDecl Alias "sessionChangesetInvert" (ByVal arg0 As SqliteSessionInput Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteSessionBuffer
    Dim local2 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim local4 As SqliteVdbeMem Ptr Ptr
    Dim local5 As SqliteSessionBuffer
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Any Ptr Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local6 As UByte
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As UByte
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_8 As SQLITE_C_INT Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As SQLITE_C_INT Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As SQLITE_C_INT Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_17 As UByte Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_18 As SQLITE_C_INT Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As SQLITE_C_INT Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_23 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Any Ptr
    Dim c2fb_temp_26 As SQLITE_C_INT Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim local13 As SqliteVdbeMem Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim local14 As SqliteVdbeMem Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As Any Ptr
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As SQLITE_C_INT Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As Any Ptr Ptr
    Dim c2fb_temp_44 As Any Ptr
    Dim c2fb_temp_45 As UByte Ptr Ptr
    Dim c2fb_temp_46 As UByte Ptr
    Dim c2fb_temp_47 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Type<SqliteSessionBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
    If arg4 Then
        c2fb_temp_1 = CPtr(Any Ptr Ptr, @((*arg4)))
        c2fb_temp_2 = CPtr(Any Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    While Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        c2fb_temp_5 = Cast(c2fb_c_int, sessionInputBuffer(arg0, Cast(c2fb_c_int, 2ULL)))
        local0 = c2fb_temp_5
        If (c2fb_temp_5) Then
            Goto c2fb_label_0
        End If
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->iNext + Cast(c2fb_c_int, 1ULL))) >= arg0->nData)))) Then
            If (-Cast(c2fb_c_int, ((arg0->iNext <> arg0->nData)))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 4200ULL)))
                local0 = c2fb_temp_6
                Goto c2fb_label_0
            End If
            Goto c2fb_flow_0
        End If
        c2fb_temp_7 = Cast(UByte, arg0->aData[arg0->iNext])
        local6 = c2fb_temp_7
        Select Case local6
            Case Cast(c2fb_c_int, 84)
                ' C automatic storage declaration
                ' C automatic storage declaration
                c2fb_temp_8 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
                (*c2fb_temp_8) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
                c2fb_temp_10 = Cast(c2fb_c_int, sessionChangesetBufferTblhdr(arg0, CPtr(c2fb_c_int Ptr, @(local7))))
                local0 = c2fb_temp_10
                If (c2fb_temp_10) Then
                    Goto c2fb_label_0
                End If
                c2fb_temp_11 = Cast(c2fb_c_int, sessionVarintGet(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->aData[arg0->iNext]))), CPtr(c2fb_c_int Ptr, @(local2))))
                local8 = c2fb_temp_11
                c2fb_temp_12 = CPtr(SQLITE_C_INT Ptr, @(local5.nBuf))
                c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_12) = Cast(SQLITE_C_INT, c2fb_temp_13)
                c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
                sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->aData[Cast(c2fb_c_int, (arg0->iNext + local8))]))), local2, CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), local6, CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->aData[arg0->iNext]))), local7, CPtr(c2fb_c_int Ptr, @(local0)))
                If local0 Then
                    Goto c2fb_label_0
                End If
                c2fb_temp_14 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_14)) + local7)))
                (*c2fb_temp_14) = Cast(SQLITE_C_INT, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                sqlite3_free(CPtr(Any Ptr, local4))
                c2fb_temp_16 = CPtr(SqliteVdbeMem Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local4 = c2fb_temp_16
                c2fb_temp_17 = local5.aBuf
                local3 = c2fb_temp_17
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 18ULL), Cast(c2fb_c_int, 9ULL)
                ' C automatic storage declaration
                local10 = arg0->aData[Cast(c2fb_c_int, (arg0->iNext + Cast(c2fb_c_int, 1ULL)))]
                local11 = (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6) = Cast(c2fb_c_int, 9ULL))))), Cast(c2fb_c_int, 18ULL), Cast(c2fb_c_int, 9ULL)))
                c2fb_temp_18 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_18)) + Cast(c2fb_c_int, 2ULL))))
                (*c2fb_temp_18) = Cast(SQLITE_C_INT, c2fb_temp_19)
                c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
                ' C unused-parameter annotation
                c2fb_temp_20 = Cast(c2fb_c_int, sessionChangesetBufferRecord(arg0, local2, CPtr(c2fb_c_int Ptr, @(local9))))
                local0 = c2fb_temp_20
                sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), local11, CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), local10, CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0->aData[arg0->iNext]))), local9, CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_temp_21 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_21)) + local9)))
                (*c2fb_temp_21) = Cast(SQLITE_C_INT, c2fb_temp_22)
                c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
                If local0 Then
                    Goto c2fb_label_0
                End If
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 23ULL)
                ' C automatic storage declaration
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local4)))) Then
                    c2fb_temp_23 = CPtr(SqliteVdbeMem Ptr Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteVdbeMem Ptr))) * Cast(c2fb_uint64, local2))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))))))
                    local4 = c2fb_temp_23
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local4)))) Then
                        c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                        local0 = c2fb_temp_24
                        Goto c2fb_label_0
                    End If
                    c2fb_temp_25 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local4), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteVdbeMem Ptr))) * Cast(c2fb_uint64, local2))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))))))
                End If
                sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), local6, CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), arg0->aData[Cast(c2fb_c_int, (arg0->iNext + Cast(c2fb_c_int, 1ULL)))], CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_temp_26 = CPtr(SQLITE_C_INT Ptr, @(arg0->iNext))
                c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_26)) + Cast(c2fb_c_int, 2ULL))))
                (*c2fb_temp_26) = Cast(SQLITE_C_INT, c2fb_temp_27)
                c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
                c2fb_temp_28 = Cast(c2fb_c_int, sessionReadRecord(arg0, local2, Cast(c2fb_c_int, &O0ULL), CPtr(SqliteVdbeMem Ptr Ptr, @(local4[Cast(c2fb_c_int, &O0ULL)])), Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_28
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_29 = Cast(c2fb_c_int, sessionReadRecord(arg0, local2, Cast(c2fb_c_int, &O0ULL), CPtr(SqliteVdbeMem Ptr Ptr, @(local4[local2])), Cast(c2fb_c_int, &O0ULL)))
                    local0 = c2fb_temp_29
                End If
                c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local12 = c2fb_temp_30
                While (-Cast(c2fb_c_int, ((local12 < local2))))
                    local13 = local4[Cast(c2fb_c_int, (local12 + (IIf(local3[local12], Cast(c2fb_c_int, &O0ULL), local2))))]
                    sessionAppendValue(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), local13, CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_flow_4:
                    c2fb_temp_31 = local12
                    local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_31 + 1)))
                Wend
                c2fb_flow_3:
                c2fb_temp_32 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local12 = c2fb_temp_32
                While (-Cast(c2fb_c_int, ((local12 < local2))))
                    local14 = (IIf(local3[local12], CPtr(SqliteVdbeMem Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL))), local4[local12]))
                    sessionAppendValue(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local1))), local14, CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_flow_6:
                    c2fb_temp_33 = local12
                    local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_33 + 1)))
                Wend
                c2fb_flow_5:
                c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local12 = c2fb_temp_34
                While (-Cast(c2fb_c_int, ((local12 < Cast(c2fb_c_int, (local2 * Cast(c2fb_c_int, 2ULL)))))))
                    sqlite3ValueFree(CPtr(Any Ptr, local4[local12]))
                c2fb_flow_8:
                    c2fb_temp_35 = local12
                    local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_35 + 1)))
                Wend
                c2fb_flow_7:
                c2fb_temp_36 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local4), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteVdbeMem Ptr))) * Cast(c2fb_uint64, local2))) * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))))))
                If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_label_0
                End If
                Goto c2fb_flow_2
            Case Else
                c2fb_temp_37 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 4303ULL)))
                local0 = c2fb_temp_37
                Goto c2fb_label_0
        End Select
        c2fb_flow_2:
        ' C unused-parameter annotation
        If (-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1.nBuf >= sessionStreamChunkSizeGet())))) <> 0))))) Then
            c2fb_temp_38 = Cast(c2fb_c_int, arg1(arg2, CPtr(Const Any Ptr, local1.aBuf), local1.nBuf))
            local0 = c2fb_temp_38
            c2fb_temp_39 = CPtr(SQLITE_C_INT Ptr, @(local1.nBuf))
            c2fb_temp_40 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_39) = Cast(SQLITE_C_INT, c2fb_temp_40)
            c2fb_temp_40 = Cast(c2fb_c_int, (*c2fb_temp_39))
            If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_label_0
            End If
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (((arg3 <> 0) AndAlso ((arg4) <> 0))))) Then
        c2fb_temp_41 = CPtr(c2fb_c_int Ptr, @((*arg3)))
        c2fb_temp_42 = Cast(c2fb_c_int, local1.nBuf)
        (*c2fb_temp_41) = c2fb_temp_42
        c2fb_temp_43 = CPtr(Any Ptr Ptr, @((*arg4)))
        c2fb_temp_44 = CPtr(Any Ptr, local1.aBuf)
        (*c2fb_temp_43) = c2fb_temp_44
        c2fb_temp_45 = CPtr(UByte Ptr Ptr, @(local1.aBuf))
        c2fb_temp_46 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_45) = c2fb_temp_46
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1.nBuf > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((CPtr(Any Ptr, arg1) <> CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL))))))) <> 0))))) Then
            c2fb_temp_47 = Cast(c2fb_c_int, arg1(arg2, CPtr(Const Any Ptr, local1.aBuf), local1.nBuf))
            local0 = c2fb_temp_47
        End If
    End If
    c2fb_label_0:
    sqlite3_free(CPtr(Any Ptr, local1.aBuf))
    sqlite3_free(CPtr(Any Ptr, local4))
    sqlite3_free(CPtr(Any Ptr, local5.aBuf))
    Return local0
End Function

Function sqlite3changeset_invert CDecl Alias "sqlite3changeset_invert" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As Any Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionInput
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr Ptr
    Dim c2fb_temp_4 As UByte Ptr

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionInput Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionInput))))
    c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(local0.nData))
    c2fb_temp_2 = Cast(c2fb_c_int, arg0)
    (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
    c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(UByte Ptr Ptr, @(local0.aData))
    c2fb_temp_4 = CPtr(UByte Ptr, arg1)
    (*c2fb_temp_3) = c2fb_temp_4
    Return sessionChangesetInvert(CPtr(SqliteSessionInput Ptr, @(local0)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg2, arg3)
End Function

Function sqlite3changeset_invert_strm CDecl Alias "sqlite3changeset_invert_strm" (ByVal arg0 As c2fb_callback_226, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_callback_230, ByVal arg3 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionInput
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Any Ptr Ptr
    Dim c2fb_temp_2 As c2fb_callback_226
    Dim c2fb_temp_3 As Any Ptr Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionInput Ptr, @(local0))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionInput))))
    c2fb_temp_1 = CPtr(Any Ptr Ptr, @(local0.xInput))
    c2fb_temp_2 = arg0
    (*c2fb_temp_1) = CPtr(Any Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_callback_226, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(Any Ptr Ptr, @(local0.pIn))
    c2fb_temp_4 = arg1
    (*c2fb_temp_3) = c2fb_temp_4
    c2fb_temp_5 = Cast(c2fb_c_int, sessionChangesetInvert(CPtr(SqliteSessionInput Ptr, @(local0)), arg2, arg3, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
    local1 = c2fb_temp_5
    sqlite3_free(CPtr(Any Ptr, local0.buf.aBuf))
    Return local1
End Function

Private Function sessionUpdateFind CDecl Alias "sessionUpdateFind" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As SqliteSessionApplyCtx Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As SqliteVdbe Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteSessionUpdate Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As SQLITE_C_UINT Ptr Ptr
    Dim c2fb_temp_1 As c2fb_c_uint Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As SQLITE_C_UINT Ptr
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim local5 As c2fb_c_int
    Dim local6 As SqliteSessionUpdate Ptr Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As SqliteSessionUpdate Ptr
    Dim c2fb_temp_14 As SqliteSessionUpdate Ptr Ptr
    Dim c2fb_temp_15 As SqliteSessionUpdate Ptr
    Dim c2fb_temp_16 As SqliteSessionUpdate Ptr Ptr
    Dim c2fb_temp_17 As SqliteSessionUpdate Ptr
    Dim c2fb_temp_18 As SqliteSessionUpdate Ptr Ptr
    Dim c2fb_temp_19 As SqliteSessionUpdate Ptr
    Dim c2fb_temp_20 As SqliteSessionUpdate Ptr Ptr
    Dim c2fb_temp_21 As SqliteSessionUpdate Ptr Ptr
    Dim c2fb_temp_22 As SqliteSessionUpdate Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_23 As SqliteSessionUpdate Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim local9 As Const ZString Ptr
    Dim local10 As SqliteSessionBuffer
    Dim c2fb_temp_25 As Any Ptr
    Dim c2fb_temp_26 As SQLITE_C_UINT Ptr Ptr
    Dim c2fb_temp_27 As c2fb_c_uint Ptr
    Dim c2fb_temp_28 As Any Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As Const ZString Ptr
    Dim c2fb_temp_32 As Const ZString Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Const ZString Ptr
    Dim local11 As ZString Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As SqliteSessionUpdate Ptr
    Dim c2fb_temp_38 As SqliteSessionUpdate Ptr Ptr
    Dim c2fb_temp_39 As SqliteSessionUpdate Ptr
    Dim c2fb_temp_40 As SqliteSessionUpdate Ptr Ptr
    Dim c2fb_temp_41 As SqliteSessionUpdate Ptr
    Dim c2fb_temp_42 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_43 As SqliteVdbe Ptr
    Dim c2fb_temp_44 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_45 As SqliteVdbe Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = arg0->nCol
    local3 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->nCol + Cast(c2fb_c_int, 33ULL)))) \ Cast(c2fb_c_int, 32ULL)))
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg1->aUpdateMask = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(SQLITE_C_UINT Ptr Ptr, @(arg1->aUpdateMask))
        c2fb_temp_1 = CPtr(c2fb_c_uint Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint))))))))
        (*c2fb_temp_0) = CPtr(SQLITE_C_UINT Ptr, c2fb_temp_1)
        c2fb_temp_1 = CPtr(c2fb_c_uint Ptr, (*c2fb_temp_0))
        If (-Cast(c2fb_c_int, ((arg1->aUpdateMask = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_2
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg1->aUpdateMask), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))))
        c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 11ULL))
        local0 = c2fb_temp_4
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local4 = c2fb_temp_5
        While (-Cast(c2fb_c_int, ((local4 < arg0->nCol))))
            If CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, (arg0)->apValue))[Cast(c2fb_c_int, ((arg0)->nCol + (local4)))] Then
                c2fb_temp_7 = CPtr(SQLITE_C_UINT Ptr, @(arg1->aUpdateMask[Cast(c2fb_c_int, (local4 \ Cast(c2fb_c_int, 32ULL)))]))
                c2fb_temp_8 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (*c2fb_temp_7)) Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl (Cast(c2fb_c_int, (local4 Mod Cast(c2fb_c_int, 32ULL)))))))))))
                (*c2fb_temp_7) = Cast(SQLITE_C_UINT, c2fb_temp_8)
                c2fb_temp_8 = Cast(c2fb_c_uint, (*c2fb_temp_7))
                c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local0 = c2fb_temp_9
            End If
        c2fb_flow_1:
            c2fb_temp_6 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        Wend
        c2fb_flow_0:
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If arg2 Then
            c2fb_temp_10 = CPtr(SQLITE_C_UINT Ptr, @(arg1->aUpdateMask[Cast(c2fb_c_int, (local2 \ Cast(c2fb_c_int, 32ULL)))]))
            c2fb_temp_11 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (*c2fb_temp_10)) Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl (Cast(c2fb_c_int, (local2 Mod Cast(c2fb_c_int, 32ULL)))))))))))
            (*c2fb_temp_10) = Cast(SQLITE_C_UINT, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_uint, (*c2fb_temp_10))
        End If
        If arg1->pUp Then
            local5 = Cast(c2fb_c_int, &O0ULL)
            local6 = CPtr(SqliteSessionUpdate Ptr Ptr, @(arg1->pUp))
            While Cast(c2fb_c_int, 1ULL)
                c2fb_temp_12 = local5
                local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, arg1->aUpdateMask), CPtr(Const Any Ptr, ((*local6))->aMask), Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))))))) Then
                    c2fb_temp_13 = (*local6)
                    local1 = c2fb_temp_13
                    c2fb_temp_14 = CPtr(SqliteSessionUpdate Ptr Ptr, @((*local6)))
                    c2fb_temp_15 = local1->pNext
                    (*c2fb_temp_14) = c2fb_temp_15
                    c2fb_temp_16 = CPtr(SqliteSessionUpdate Ptr Ptr, @(local1->pNext))
                    c2fb_temp_17 = arg1->pUp
                    (*c2fb_temp_16) = c2fb_temp_17
                    c2fb_temp_18 = CPtr(SqliteSessionUpdate Ptr Ptr, @(arg1->pUp))
                    c2fb_temp_19 = local1
                    (*c2fb_temp_18) = c2fb_temp_19
                    Goto c2fb_flow_2
                End If
                If ((*local6))->pNext Then
                    c2fb_temp_20 = CPtr(SqliteSessionUpdate Ptr Ptr, @(((*local6))->pNext))
                    local6 = c2fb_temp_20
                Else
                    If (-Cast(c2fb_c_int, ((local5 >= Cast(c2fb_c_int, 12ULL))))) Then
                        c2fb_external_sqlite3_finalize__(CPtr(SqliteVdbe Ptr, ((*local6))->pStmt))
                        sqlite3_free(CPtr(Any Ptr, (*local6)))
                        c2fb_temp_21 = CPtr(SqliteSessionUpdate Ptr Ptr, @((*local6)))
                        c2fb_temp_22 = CPtr(SqliteSessionUpdate Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                        (*c2fb_temp_21) = c2fb_temp_22
                    End If
                    Goto c2fb_flow_2
                End If
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            local7 = Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSessionUpdate))) * Cast(c2fb_uint64, local3))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))
            local8 = ((-Cast(c2fb_c_int, ((sqlite3_stricmp(CPtr(Const ZString Ptr, arg0->zTab), StrPtr(!"sqlite_stat1")) = Cast(c2fb_c_int, &O0ULL))))))
            c2fb_temp_23 = CPtr(SqliteSessionUpdate Ptr, CPtr(Any Ptr, sqlite3_malloc(local7)))
            local1 = c2fb_temp_23
            If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_24 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local0 = c2fb_temp_24
            Else
                local9 = StrPtr(!"")
                ' C automatic storage declaration
                c2fb_temp_25 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
                c2fb_temp_26 = CPtr(SQLITE_C_UINT Ptr Ptr, @(local1->aMask))
                c2fb_temp_27 = CPtr(c2fb_c_uint Ptr, CPtr(SqliteSessionUpdate Ptr, @(local1[Cast(c2fb_c_int, 1ULL)])))
                (*c2fb_temp_26) = CPtr(SQLITE_C_UINT Ptr, c2fb_temp_27)
                c2fb_temp_27 = CPtr(c2fb_c_uint Ptr, (*c2fb_temp_26))
                c2fb_temp_28 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->aMask), CPtr(Const Any Ptr, arg1->aUpdateMask), Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_c_uint)))))))
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), StrPtr(!"UPDATE main."), CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), CPtr(Const ZString Ptr, arg0->zTab), CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), StrPtr(!" SET "), CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local4 = c2fb_temp_29
                While (-Cast(c2fb_c_int, ((local4 < arg0->nCol))))
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->abPK[local4]) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, (arg0)->apValue))[Cast(c2fb_c_int, ((arg0)->nCol + (local4)))] <> 0))))) Then
                        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), local9, CPtr(c2fb_c_int Ptr, @(local0)))
                        sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), arg1->azCol[local4], CPtr(c2fb_c_int Ptr, @(local0)))
                        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), StrPtr(!" = ?"), CPtr(c2fb_c_int Ptr, @(local0)))
                        sessionAppendInteger(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), Cast(c2fb_c_int, (Cast(c2fb_c_int, (local4 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_c_int Ptr, @(local0)))
                        c2fb_temp_31 = StrPtr(!", ")
                        local9 = c2fb_temp_31
                    End If
                c2fb_flow_5:
                    c2fb_temp_30 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_30 + 1)))
                Wend
                c2fb_flow_4:
                c2fb_temp_32 = StrPtr(!"")
                local9 = c2fb_temp_32
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), StrPtr(!" WHERE "), CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local4 = c2fb_temp_33
                While (-Cast(c2fb_c_int, ((local4 < arg0->nCol))))
                    If (-Cast(c2fb_c_int, (((arg1->abPK[local4] <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, (arg0)->apValue))[(local4)] <> 0)))))) <> 0))))) Then
                        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), local9, CPtr(c2fb_c_int Ptr, @(local0)))
                        If (-Cast(c2fb_c_int, (((local8 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                            ' C unused-parameter annotation
                            sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), StrPtr(!"idx IS CASE WHEN length(?4)=0 AND typeof(?4)='blob' THEN NULL ELSE ?4 END "), CPtr(c2fb_c_int Ptr, @(local0)))
                        Else
                            sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), arg1->azCol[local4], CPtr(c2fb_c_int Ptr, @(local0)))
                            sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), StrPtr(!" IS ?"), CPtr(c2fb_c_int Ptr, @(local0)))
                            sessionAppendInteger(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local10))), Cast(c2fb_c_int, (Cast(c2fb_c_int, (local4 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 2ULL))), CPtr(c2fb_c_int Ptr, @(local0)))
                        End If
                        c2fb_temp_35 = StrPtr(!" AND ")
                        local9 = c2fb_temp_35
                    End If
                c2fb_flow_7:
                    c2fb_temp_34 = local4
                    local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_34 + 1)))
                Wend
                c2fb_flow_6:
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    local11 = CPtr(ZString Ptr, local10.aBuf)
                    c2fb_temp_36 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2__(arg1->db, CPtr(Const ZString Ptr, local11), local10.nBuf, CPtr(SqliteVdbe Ptr Ptr, @(local1->pStmt)), Cast(c2fb_c_int, &O0ULL)))
                    local0 = c2fb_temp_36
                End If
                If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    sqlite3_free(CPtr(Any Ptr, local1))
                    c2fb_temp_37 = CPtr(SqliteSessionUpdate Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                    local1 = c2fb_temp_37
                Else
                    c2fb_temp_38 = CPtr(SqliteSessionUpdate Ptr Ptr, @(local1->pNext))
                    c2fb_temp_39 = arg1->pUp
                    (*c2fb_temp_38) = c2fb_temp_39
                    c2fb_temp_40 = CPtr(SqliteSessionUpdate Ptr Ptr, @(arg1->pUp))
                    c2fb_temp_41 = local1
                    (*c2fb_temp_40) = c2fb_temp_41
                End If
                sqlite3_free(CPtr(Any Ptr, local10.aBuf))
            End If
        End If
    End If
    ' C unused-parameter annotation
    If local1 Then
        c2fb_temp_42 = CPtr(SqliteVdbe Ptr Ptr, @((*arg3)))
        c2fb_temp_43 = CPtr(SqliteVdbe Ptr, local1->pStmt)
        (*c2fb_temp_42) = c2fb_temp_43
    Else
        c2fb_temp_44 = CPtr(SqliteVdbe Ptr Ptr, @((*arg3)))
        c2fb_temp_45 = CPtr(SqliteVdbe Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_44) = c2fb_temp_45
    End If
    Return local0
End Function

Private Function sessionSeekToRow CDecl Alias "sessionSeekToRow" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As SqliteSessionApplyCtx Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteVdbe Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local6 As SqliteVdbeMem Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = CPtr(SqliteVdbe Ptr, arg1->pSelect)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_external_sqlite3_clear_bindings_(local0)
    c2fb_sqlite3changeset_op(CPtr(Any Ptr, arg0), CPtr(Const ZString Ptr Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3)), Cast(c2fb_c_int, &O0ULL))
    c2fb_temp_0 = Cast(c2fb_c_int, sessionBindRow(CPtr(Any Ptr, arg0), CPtr(c2fb_callback_223, IIf((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 18ULL))))), CPtr(Any Ptr, ProcPtr(c2fb_sqlite3changeset_new)), CPtr(Any Ptr, ProcPtr(c2fb_sqlite3changeset_old)))), local2, arg1->abPK, local0))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso (arg1->bIgnoreNoop <> 0))))) Then
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local5 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < local2)))) <> 0)))))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->abPK[local5]) = Cast(c2fb_c_int, &O0ULL))))) Then
                local6 = Cast(c2fb_c_int, &O0ULL)
                c2fb_sqlite3changeset_new(CPtr(Any Ptr, arg0), local5, CPtr(Any Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, @(local6))))
                c2fb_external_sqlite3_bind_int_(local0, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))) + local2)), ((-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL)))))))
                If local6 Then
                    c2fb_temp_3 = Cast(c2fb_c_int, sessionBindValue(local0, Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))), local6))
                    local1 = c2fb_temp_3
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_2 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        Wend
        c2fb_flow_0:
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3_step__(local0))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, 100ULL))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(local0))
            local1 = c2fb_temp_5
        End If
    End If
    Return local1
End Function

Private Function sessionRebaseAdd CDecl Alias "sessionRebaseAdd" (ByVal arg0 As SqliteSessionApplyCtx Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteChangesetIter Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As SqliteVdbeMem Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0->bRebase Then
        ' C automatic storage declaration
        local2 = arg2->op
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->bRebaseStarted) = Cast(c2fb_c_int, &O0ULL))))) Then
            local3 = CPtr(Const ZString Ptr, arg2->zTab)
            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->rebase))), Cast(c2fb_c_int, 84), CPtr(c2fb_c_int Ptr, @(local0)))
            sessionAppendVarint(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->rebase))), arg0->nCol, CPtr(c2fb_c_int Ptr, @(local0)))
            sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->rebase))), CPtr(Const UByte Ptr, arg0->abPK), arg0->nCol, CPtr(c2fb_c_int Ptr, @(local0)))
            sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->rebase))), CPtr(Const UByte Ptr, CPtr(UByte Ptr, local3)), Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_crt_strlen(local3)) + Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_c_int Ptr, @(local0)))
            c2fb_temp_0 = CPtr(UByte Ptr, @(arg0->bRebaseStarted))
            c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_0) = c2fb_temp_1
        End If
        ' C unused-parameter annotation
        ' C unused-parameter annotation
        sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->rebase))), (IIf((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 9ULL))))), Cast(c2fb_c_int, 9ULL), Cast(c2fb_c_int, 18ULL))), CPtr(c2fb_c_int Ptr, @(local0)))
        sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->rebase))), ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL)))))), CPtr(c2fb_c_int Ptr, @(local0)))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local1 < arg0->nCol))))
            local4 = Cast(c2fb_c_int, &O0ULL)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 9ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 23ULL))))) <> 0) AndAlso (arg0->abPK[local1] <> 0)))))) <> 0))))) Then
                c2fb_sqlite3changeset_old(CPtr(Any Ptr, arg2), local1, CPtr(Any Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, @(local4))))
            Else
                c2fb_sqlite3changeset_new(CPtr(Any Ptr, arg2), local1, CPtr(Any Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, @(local4))))
            End If
            sessionAppendValue(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->rebase))), local4, CPtr(c2fb_c_int Ptr, @(local0)))
        c2fb_flow_1:
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_0:
    End If
    Return local0
End Function

Private Function sessionConflictHandler CDecl Alias "sessionConflictHandler" (ByVal arg0 As c2fb_c_int, ByVal arg1 As SqliteSessionApplyCtx Ptr, ByVal arg2 As SqliteChangesetIter Ptr, ByVal arg3 As c2fb_callback_229, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As SqliteVdbe Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr Ptr
    Dim c2fb_temp_6 As SqliteVdbe Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local5 As UByte Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_sqlite3changeset_op(CPtr(Any Ptr, arg2), CPtr(Const ZString Ptr Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3)), Cast(c2fb_c_int, &O0ULL))
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If arg5 Then
        c2fb_temp_0 = Cast(c2fb_c_int, sessionSeekToRow(arg2, arg1))
        local1 = c2fb_temp_0
    Else
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 100ULL))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = Cast(c2fb_c_int, arg1->bIgnoreNoop))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_column_int__(CPtr(SqliteVdbe Ptr, arg1->pSelect), Cast(c2fb_c_int, (c2fb_external_sqlite3_column_count__(CPtr(SqliteVdbe Ptr, arg1->pSelect)) - Cast(c2fb_c_int, 1ULL)))))))) <> 0))))) Then
            c2fb_temp_2 = CPtr(Any Ptr Ptr, @(arg2->pConflict))
            c2fb_temp_3 = CPtr(SqliteVdbe Ptr, arg1->pSelect)
            (*c2fb_temp_2) = CPtr(Any Ptr, c2fb_temp_3)
            c2fb_temp_3 = CPtr(SqliteVdbe Ptr, (*c2fb_temp_2))
            c2fb_temp_4 = Cast(c2fb_c_int, arg3(arg4, arg0, arg2))
            local0 = c2fb_temp_4
            c2fb_temp_5 = CPtr(Any Ptr Ptr, @(arg2->pConflict))
            c2fb_temp_6 = CPtr(SqliteVdbe Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_5) = CPtr(Any Ptr, c2fb_temp_6)
            c2fb_temp_6 = CPtr(SqliteVdbe Ptr, (*c2fb_temp_5))
        End If
        c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(CPtr(SqliteVdbe Ptr, arg1->pSelect)))
        local1 = c2fb_temp_7
    Else
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, (((arg1->bDeferConstraints <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
                local5 = CPtr(UByte Ptr, @(arg2->in.aData[arg2->in.iCurrent]))
                local6 = Cast(c2fb_c_int, (arg2->in.iNext - arg2->in.iCurrent))
                sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg1->constraints))), CPtr(Const UByte Ptr, local5), local6, CPtr(c2fb_c_int Ptr, @(local1)))
                Return local1
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->bIgnoreNoop) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, 9ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
                    c2fb_temp_8 = Cast(c2fb_c_int, arg3(arg4, Cast(c2fb_c_int, (arg0 + Cast(c2fb_c_int, 1ULL))), arg2))
                    local0 = c2fb_temp_8
                    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
                        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, 21ULL))
                        local1 = c2fb_temp_9
                    End If
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        Select Case local0
            Case Cast(c2fb_c_int, 1ULL)
                ' C unused-parameter annotation
                c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg5)))
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_10) = c2fb_temp_11
            Case Cast(c2fb_c_int, &O0ULL)
            Case Cast(c2fb_c_int, 2ULL)
                c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, 4ULL))
                local1 = c2fb_temp_12
            Case Else
                c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 21ULL))
                local1 = c2fb_temp_13
        End Select
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_14 = Cast(c2fb_c_int, sessionRebaseAdd(arg1, local0, arg2))
            local1 = c2fb_temp_14
        End If
    End If
    Return local1
End Function

Private Function sessionApplyOneOp CDecl Alias "sessionApplyOneOp" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As SqliteSessionApplyCtx Ptr, ByVal arg2 As c2fb_callback_229, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As SqliteVdbe Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local8 As SqliteVdbeMem Ptr
    Dim local9 As SqliteVdbeMem Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_sqlite3changeset_op(CPtr(Any Ptr, arg0), CPtr(Const ZString Ptr Ptr, @(local0)), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 9ULL))))) Then
        local4 = (IIf(arg0->bPatchset, arg1->abPK, CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
        c2fb_temp_0 = Cast(c2fb_c_int, sessionBindRow(CPtr(Any Ptr, arg0), ProcPtr(c2fb_sqlite3changeset_old), local2, local4, CPtr(SqliteVdbe Ptr, arg1->pDelete)))
        local3 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((sqlite3_bind_parameter_count(CPtr(Any Ptr, CPtr(SqliteVdbe Ptr, arg1->pDelete))) > local2)))) <> 0))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, c2fb_external_sqlite3_bind_int_(CPtr(SqliteVdbe Ptr, arg1->pDelete), Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))), ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg5 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (local4 <> 0))))))))
            local3 = c2fb_temp_1
        End If
        If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local3
        End If
        c2fb_temp_17 = Cast(c2fb_c_int, c2fb_external_sqlite3_step__(CPtr(SqliteVdbe Ptr, arg1->pDelete)))
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(CPtr(SqliteVdbe Ptr, arg1->pDelete)))
        local3 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((sqlite3_changes(CPtr(Any Ptr, arg1->db)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, sessionConflictHandler(Cast(c2fb_c_int, 1ULL), arg1, arg0, arg2, arg3, arg5))
            local3 = c2fb_temp_3
        Else
            If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local3 And Cast(c2fb_c_int, &HffULL)))) = Cast(c2fb_c_int, 19ULL))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, sessionConflictHandler(Cast(c2fb_c_int, 3ULL), arg1, arg0, arg2, arg3, Cast(c2fb_c_int, &O0ULL)))
                local3 = c2fb_temp_4
            End If
        End If
    Else
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 23ULL))))) Then
            ' C automatic storage declaration
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg5 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (arg0->bPatchset <> 0))))))
            c2fb_temp_5 = Cast(c2fb_c_int, sessionUpdateFind(arg0, arg1, local7, CPtr(SqliteVdbe Ptr Ptr, @(local6))))
            local3 = c2fb_temp_5
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local5 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < local2)))) <> 0)))))
                local8 = CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, (arg0)->apValue))[(local5)]
                local9 = CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, (arg0)->apValue))[Cast(c2fb_c_int, ((arg0)->nCol + (local5)))]
                If (-Cast(c2fb_c_int, (((local8 <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg1->abPK[local5] <> 0) OrElse ((-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
                    c2fb_temp_8 = Cast(c2fb_c_int, sessionBindValue(local6, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local5 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 2ULL))), local8))
                    local3 = c2fb_temp_8
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local9 <> 0))))) Then
                    c2fb_temp_9 = Cast(c2fb_c_int, sessionBindValue(local6, Cast(c2fb_c_int, (Cast(c2fb_c_int, (local5 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL))), local9))
                    local3 = c2fb_temp_9
                End If
            c2fb_flow_1:
                c2fb_temp_7 = local5
                local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
            Wend
            c2fb_flow_0:
            If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Return local3
            End If
            c2fb_external_sqlite3_step__(local6)
            c2fb_temp_10 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(local6))
            local3 = c2fb_temp_10
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((sqlite3_changes(CPtr(Any Ptr, arg1->db)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_11 = Cast(c2fb_c_int, sessionConflictHandler(Cast(c2fb_c_int, 1ULL), arg1, arg0, arg2, arg3, arg5))
                local3 = c2fb_temp_11
            Else
                If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local3 And Cast(c2fb_c_int, &HffULL)))) = Cast(c2fb_c_int, 19ULL))))) Then
                    c2fb_temp_12 = Cast(c2fb_c_int, sessionConflictHandler(Cast(c2fb_c_int, 3ULL), arg1, arg0, arg2, arg3, Cast(c2fb_c_int, &O0ULL)))
                    local3 = c2fb_temp_12
                End If
            End If
        Else
            ' C unused-parameter annotation
            If arg1->bStat1 Then
                c2fb_temp_13 = Cast(c2fb_c_int, sessionSeekToRow(arg0, arg1))
                local3 = c2fb_temp_13
                If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, 100ULL))))) Then
                    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, 19ULL))
                    local3 = c2fb_temp_14
                    c2fb_external_sqlite3_reset_(CPtr(SqliteVdbe Ptr, arg1->pSelect))
                End If
            End If
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_15 = Cast(c2fb_c_int, sessionBindRow(CPtr(Any Ptr, arg0), ProcPtr(c2fb_sqlite3changeset_new), local2, Cast(c2fb_c_int, &O0ULL), CPtr(SqliteVdbe Ptr, arg1->pInsert)))
                local3 = c2fb_temp_15
                If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Return local3
                End If
                c2fb_external_sqlite3_step__(CPtr(SqliteVdbe Ptr, arg1->pInsert))
                c2fb_temp_16 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(CPtr(SqliteVdbe Ptr, arg1->pInsert)))
                local3 = c2fb_temp_16
            End If
            If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local3 And Cast(c2fb_c_int, &HffULL)))) = Cast(c2fb_c_int, 19ULL))))) Then
                c2fb_temp_17 = Cast(c2fb_c_int, sessionConflictHandler(Cast(c2fb_c_int, 3ULL), arg1, arg0, arg2, arg3, arg4))
                local3 = c2fb_temp_17
            End If
        End If
    End If
    Return local3
End Function

Private Function sessionApplyOneWithRetry CDecl Alias "sessionApplyOneWithRetry" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As SqliteSessionApplyCtx Ptr, ByVal arg3 As c2fb_callback_229, ByVal arg4 As Any Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, sessionApplyOneOp(arg1, arg2, arg3, arg4, CPtr(c2fb_c_int Ptr, @(local0)), CPtr(c2fb_c_int Ptr, @(local1))))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        If local1 Then
            ' C unused-parameter annotation
            c2fb_temp_1 = Cast(c2fb_c_int, sessionApplyOneOp(arg1, arg2, arg3, arg4, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
            local2 = c2fb_temp_1
        Else
            If local0 Then
                ' C unused-parameter annotation
                c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0, StrPtr(!"SAVEPOINT replace_op"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                local2 = c2fb_temp_2
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_3 = Cast(c2fb_c_int, sessionBindRow(CPtr(Any Ptr, arg1), ProcPtr(c2fb_sqlite3changeset_new), arg2->nCol, arg2->abPK, CPtr(SqliteVdbe Ptr, arg2->pDelete)))
                    local2 = c2fb_temp_3
                    c2fb_external_sqlite3_bind_int_(CPtr(SqliteVdbe Ptr, arg2->pDelete), Cast(c2fb_c_int, (arg2->nCol + Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL))
                End If
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_external_sqlite3_step__(CPtr(SqliteVdbe Ptr, arg2->pDelete))
                    c2fb_temp_4 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(CPtr(SqliteVdbe Ptr, arg2->pDelete)))
                    local2 = c2fb_temp_4
                End If
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_5 = Cast(c2fb_c_int, sessionApplyOneOp(arg1, arg2, arg3, arg4, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                    local2 = c2fb_temp_5
                End If
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0, StrPtr(!"RELEASE replace_op"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                    local2 = c2fb_temp_6
                End If
            End If
        End If
    End If
    Return local2
End Function

Private Function sessionRetryIterInit CDecl Alias "sessionRetryIterInit" (ByVal arg0 As SqliteSessionBuffer Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As SqliteSessionApplyCtx Ptr, ByVal arg4 As SqliteChangesetIter Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangesetIter Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local2 As c2fb_size_t
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As SQLITE_C_INT Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As UByte Ptr Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As Any Ptr Ptr Ptr
    Dim c2fb_temp_10 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As SqliteChangesetIter Ptr
    Dim c2fb_temp_13 As SqliteChangesetIter Ptr Ptr
    Dim c2fb_temp_14 As SqliteChangesetIter Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, sessionChangesetStart(CPtr(SqliteChangesetIter Ptr Ptr, @(local0)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg0->nBuf, CPtr(Any Ptr, arg0->aBuf), arg3->bInvertConstraints, Cast(c2fb_c_int, 1ULL)))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        local2 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) * arg3->nCol))) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteVdbeMem Ptr)))))
        c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(local0->bPatchset))
        c2fb_temp_2 = Cast(c2fb_c_int, arg1)
        (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        c2fb_temp_3 = CPtr(ZString Ptr Ptr, @(local0->zTab))
        c2fb_temp_4 = CPtr(ZString Ptr, arg2)
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = CPtr(SQLITE_C_INT Ptr, @(local0->nCol))
        c2fb_temp_6 = Cast(c2fb_c_int, arg3->nCol)
        (*c2fb_temp_5) = Cast(SQLITE_C_INT, c2fb_temp_6)
        c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(UByte Ptr Ptr, @(local0->abPK))
        c2fb_temp_8 = arg3->abPK
        (*c2fb_temp_7) = c2fb_temp_8
        sessionBufferGrow(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local0->tblhdr))), local2, CPtr(c2fb_c_int Ptr, @(local1)))
        c2fb_temp_9 = CPtr(Any Ptr Ptr Ptr, @(local0->apValue))
        c2fb_temp_10 = CPtr(SqliteVdbeMem Ptr Ptr, local0->tblhdr.aBuf)
        (*c2fb_temp_9) = CPtr(Any Ptr Ptr, c2fb_temp_10)
        c2fb_temp_10 = CPtr(SqliteVdbeMem Ptr Ptr, (*c2fb_temp_9))
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_11 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteVdbeMem Ptr Ptr, local0->apValue)), Cast(c2fb_c_int, &O0ULL), local2))
        Else
            c2fb_sqlite3changeset_finalize(CPtr(Any Ptr, local0))
            c2fb_temp_12 = CPtr(SqliteChangesetIter Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_12
        End If
    End If
    c2fb_temp_13 = CPtr(SqliteChangesetIter Ptr Ptr, @((*arg4)))
    c2fb_temp_14 = local0
    (*c2fb_temp_13) = c2fb_temp_14
    Return local1
End Function

Private Function sessionApplyRetryBuffer CDecl Alias "sessionApplyRetryBuffer" (ByVal arg0 As SqliteSessionBuffer Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As sqlite3 Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As SqliteSessionApplyCtx Ptr, ByVal arg6 As c2fb_callback_229, ByVal arg7 As Any Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As SqliteChangesetIter Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, sessionRetryIterInit(arg0, arg3, arg4, arg5, CPtr(SqliteChangesetIter Ptr Ptr, @(local3))))
    local0 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_sqlite3changeset_next(CPtr(Any Ptr, local3)))))) <> 0)))))
        If (-Cast(c2fb_c_int, ((local2 <> arg1)))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, sessionApplyOneWithRetry(arg2, local3, arg5, arg6, arg7))
            local0 = c2fb_temp_3
        End If
    c2fb_flow_1:
        c2fb_temp_2 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_4 = Cast(c2fb_c_int, c2fb_sqlite3changeset_finalize(CPtr(Any Ptr, local3)))
    local1 = c2fb_temp_4
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, local1)
        local0 = c2fb_temp_5
    End If
    ' C unused-parameter annotation
    Return local0
End Function

Private Function sessionUpdateToUpdate CDecl Alias "sessionUpdateToUpdate" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As SqliteSessionApplyCtx Ptr, ByVal arg3 As SqliteChangesetIter Ptr, ByVal arg4 As SqliteVdbe Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteVdbe Ptr
    Dim local1 As SqliteVdbe Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim local4 As SqliteSessionBuffer
    Dim local5 As SqliteSessionBuffer
    Dim local6 As SqliteSessionBuffer
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local8 As SqliteVdbeMem Ptr
    Dim c2fb_temp_5 As SqliteVdbeMem Ptr
    Dim local9 As Const ZString Ptr
    Dim c2fb_temp_6 As Const ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local10 As SqliteVdbeMem Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As SqliteVdbe Ptr
    Dim c2fb_temp_18 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_19 As SqliteVdbe Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Type<SqliteSessionBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local5 = Type<SqliteSessionBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local6 = Type<SqliteSessionBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(UByte Ptr, CPtr(Any Ptr, sqlite3_malloc64(arg2->nCol)))
    local3 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local2 = c2fb_temp_1
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, sessionUniqueColumns(arg0, arg1, CPtr(c2fb_source_record_55 Ptr, arg2), local3))
        local2 = c2fb_temp_2
    End If
    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local7 = c2fb_temp_3
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 < arg2->nCol)))) <> 0)))))
        local8 = Cast(c2fb_c_int, &O0ULL)
        If arg2->abPK[local7] Then
            If (-Cast(c2fb_c_int, ((local6.nBuf > Cast(c2fb_c_int, &O0ULL))))) Then
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local6))), StrPtr(!" AND "), CPtr(c2fb_c_int Ptr, @(local2)))
            End If
            sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local6))), arg2->azCol[local7], CPtr(c2fb_c_int Ptr, @(local2)))
            sessionAppendPrintf(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local6))), CPtr(c2fb_c_int Ptr, @(local2)), StrPtr(!" IS ?%d"), Cast(c2fb_c_int, (local7 + Cast(c2fb_c_int, 1ULL))))
        Else
            c2fb_temp_5 = CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, (arg3)->apValue))[Cast(c2fb_c_int, ((arg3)->nCol + (local7)))]
            local8 = c2fb_temp_5
            If (-Cast(c2fb_c_int, (((c2fb_temp_5) <> Cast(c2fb_c_int, &O0ULL))))) Then
                If local3[local7] Then
                    local9 = Cast(c2fb_c_int, &O0ULL)
                    Select Case c2fb_external_sqlite3_value_type__(local8)
                        Case Cast(c2fb_c_int, 5ULL)
                            c2fb_temp_6 = StrPtr(!"NULL")
                            local9 = c2fb_temp_6
                        Case Cast(c2fb_c_int, 3ULL)
                            c2fb_temp_7 = StrPtr(!"CAST(random() AS TEXT)")
                            local9 = c2fb_temp_7
                        Case Cast(c2fb_c_int, 4ULL)
                            c2fb_temp_8 = StrPtr(!"unhex(hex(random()))")
                            local9 = c2fb_temp_8
                        Case Else
                            c2fb_temp_9 = StrPtr(!"random()")
                            local9 = c2fb_temp_9
                    End Select
                    c2fb_flow_2:
                    If (-Cast(c2fb_c_int, ((local4.nBuf > Cast(c2fb_c_int, &O0ULL))))) Then
                        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local4))), StrPtr(!", "), CPtr(c2fb_c_int Ptr, @(local2)))
                    End If
                    sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local4))), arg2->azCol[local7], CPtr(c2fb_c_int Ptr, @(local2)))
                    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local4))), StrPtr(!" = "), CPtr(c2fb_c_int Ptr, @(local2)))
                    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local4))), local9, CPtr(c2fb_c_int Ptr, @(local2)))
                End If
                If (-Cast(c2fb_c_int, ((local5.nBuf > Cast(c2fb_c_int, &O0ULL))))) Then
                    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), StrPtr(!", "), CPtr(c2fb_c_int Ptr, @(local2)))
                End If
                sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg2->azCol[local7], CPtr(c2fb_c_int Ptr, @(local2)))
                sessionAppendPrintf(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), CPtr(c2fb_c_int Ptr, @(local2)), StrPtr(!" = ?%d"), Cast(c2fb_c_int, (local7 + Cast(c2fb_c_int, 1ULL))))
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_4 = local7
        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4.nBuf = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 19ULL))
        local2 = c2fb_temp_10
    End If
    sessionPrepareMprintf(CPtr(c2fb_c_int Ptr, @(local2)), arg0, CPtr(SqliteVdbe Ptr Ptr, @(local1)), CPtr(ZString Ptr Ptr, @(arg2->zErr)), StrPtr(!"UPDATE main.\034%w\034 SET %s WHERE %s"), arg1, CPtr(ZString Ptr, local4.aBuf), CPtr(ZString Ptr, local6.aBuf))
    sessionPrepareMprintf(CPtr(c2fb_c_int Ptr, @(local2)), arg0, CPtr(SqliteVdbe Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg2->zErr)), StrPtr(!"UPDATE main.\034%w\034 SET %s WHERE %s"), arg1, CPtr(ZString Ptr, local5.aBuf), CPtr(ZString Ptr, local6.aBuf))
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_11 = Cast(c2fb_c_int, sessionBindRow(CPtr(Any Ptr, arg3), ProcPtr(c2fb_sqlite3changeset_old), arg2->nCol, arg2->abPK, local1))
        local2 = c2fb_temp_11
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_12 = Cast(c2fb_c_int, sessionBindRow(CPtr(Any Ptr, arg3), ProcPtr(c2fb_sqlite3changeset_old), arg2->nCol, arg2->abPK, local0))
        local2 = c2fb_temp_12
    End If
    c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local7 = c2fb_temp_13
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local7 < arg2->nCol)))) <> 0)))))
        local10 = CPtr(SqliteVdbeMem Ptr Ptr, CPtr(SqliteVdbeMem Ptr Ptr, (arg3)->apValue))[Cast(c2fb_c_int, ((arg3)->nCol + (local7)))]
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg2->abPK[local7]) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local10 <> 0))))) Then
            c2fb_temp_15 = Cast(c2fb_c_int, sessionBindValue(local0, Cast(c2fb_c_int, (local7 + Cast(c2fb_c_int, 1ULL))), local10))
            local2 = c2fb_temp_15
        End If
    c2fb_flow_4:
        c2fb_temp_14 = local7
        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
    Wend
    c2fb_flow_3:
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_step__(local1)
        c2fb_temp_16 = Cast(c2fb_c_int, c2fb_external_sqlite3_reset_(local1))
        local2 = c2fb_temp_16
    End If
    c2fb_external_sqlite3_finalize__(local1)
    If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_finalize__(local0)
        c2fb_temp_17 = CPtr(SqliteVdbe Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_17
    End If
    c2fb_temp_18 = CPtr(SqliteVdbe Ptr Ptr, @((*arg4)))
    c2fb_temp_19 = local0
    (*c2fb_temp_18) = c2fb_temp_19
    sqlite3_free(CPtr(Any Ptr, local3))
    sqlite3_free(CPtr(Any Ptr, local4.aBuf))
    sqlite3_free(CPtr(Any Ptr, local5.aBuf))
    sqlite3_free(CPtr(Any Ptr, local6.aBuf))
    Return local2
End Function

Private Function sessionRetryConstraints CDecl Alias "sessionRetryConstraints" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As SqliteSessionApplyCtx Ptr, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteSessionBuffer
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As SqliteSessionBuffer
    Dim local4 As SqliteChangesetIter Ptr
    Dim local5 As SqliteVdbe Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As SqliteSessionBuffer
    Dim c2fb_temp_10 As Any Ptr
    Dim local9 As SqliteSessionBuffer
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As SqliteVdbe Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As SqliteSessionBuffer Ptr
    Dim c2fb_temp_21 As SqliteSessionBuffer
    Dim c2fb_temp_22 As Any Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim local10 As SqliteSessionBuffer
    Dim c2fb_temp_25 As Any Ptr
    Dim c2fb_temp_26 As SQLITE_C_INT Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    While arg3->constraints.nBuf
        local2 = arg3->constraints
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg3->constraints))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
        c2fb_temp_1 = Cast(c2fb_c_int, sessionApplyRetryBuffer(CPtr(SqliteSessionBuffer Ptr, @(local2)), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), arg0, arg1, arg2, arg3, arg4, arg5))
        local0 = c2fb_temp_1
        sqlite3_free(CPtr(Any Ptr, local2.aBuf))
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        If (-Cast(c2fb_c_int, ((arg3->constraints.nBuf >= local2.nBuf)))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg3->constraints.nBuf <> 0) AndAlso ((-Cast(c2fb_c_int, (arg3->bNoUpdateLoop = 0))) <> 0)))))
        local3 = Type<SqliteSessionBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
        local4 = Cast(c2fb_c_int, &O0ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        local6 = Cast(c2fb_c_int, &O0ULL)
        local7 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_2 = Cast(c2fb_c_int, sessionRetryIterInit(CPtr(SqliteSessionBuffer Ptr, @(arg3->constraints)), arg1, arg2, arg3, CPtr(SqliteChangesetIter Ptr Ptr, @(local4))))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            local8 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
            While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_sqlite3changeset_next(CPtr(Any Ptr, local4))))))
                If (-Cast(c2fb_c_int, ((local4->op = Cast(c2fb_c_int, 23ULL))))) Then
                    c2fb_temp_3 = local8
                    local8 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
                End If
                If (-Cast(c2fb_c_int, ((local8 = local1)))) Then
                    Goto c2fb_flow_4
                End If
                c2fb_temp_4 = local6
                local6 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 + 1)))
            c2fb_flow_5:
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, ((local8 = local1)))) Then
                c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0, StrPtr(!"SAVEPOINT update_op"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_5
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_6 = Cast(c2fb_c_int, sessionUpdateToUpdate(arg0, arg2, arg3, local4, CPtr(SqliteVdbe Ptr Ptr, @(local5))))
                    local0 = c2fb_temp_6
                    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local0 And Cast(c2fb_c_int, &HffULL)))) = Cast(c2fb_c_int, 19ULL))))) Then
                        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local7 = c2fb_temp_7
                        c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        local0 = c2fb_temp_8
                    End If
                End If
            End If
            c2fb_sqlite3changeset_finalize(CPtr(Any Ptr, local4))
            If (-Cast(c2fb_c_int, ((local8 <> local1)))) Then
                Goto c2fb_flow_2
            End If
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_9 = arg3->constraints
            local3 = c2fb_temp_9
            If local7 Then
                c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg3->constraints))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
            End If
            While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3->constraints.nBuf > Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
                local9 = arg3->constraints
                c2fb_temp_11 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg3->constraints))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
                c2fb_temp_12 = Cast(c2fb_c_int, sessionApplyRetryBuffer(CPtr(SqliteSessionBuffer Ptr, @(local9)), local6, arg0, arg1, arg2, arg3, arg4, arg5))
                local0 = c2fb_temp_12
                If (-Cast(c2fb_c_int, ((local9.aBuf <> local3.aBuf)))) Then
                    sqlite3_free(CPtr(Any Ptr, local9.aBuf))
                End If
                If (-Cast(c2fb_c_int, ((arg3->constraints.nBuf >= local9.nBuf)))) Then
                    Goto c2fb_flow_6
                End If
                c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                local6 = c2fb_temp_13
            c2fb_flow_7:
            Wend
            c2fb_flow_6:
        End If
        c2fb_temp_14 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_external_sqlite3_step__(local5)
                c2fb_temp_15 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize__(local5))
                local0 = c2fb_temp_15
                c2fb_temp_16 = CPtr(SqliteVdbe Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                local5 = c2fb_temp_16
                If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local0 And Cast(c2fb_c_int, &HffULL)))) = Cast(c2fb_c_int, 19ULL))))) Then
                    c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local7 = c2fb_temp_17
                    c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local0 = c2fb_temp_18
                End If
            End If
            If local7 Then
                c2fb_temp_19 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0, StrPtr(!"ROLLBACK TO update_op"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_19
                sqlite3_free(CPtr(Any Ptr, arg3->constraints.aBuf))
                c2fb_temp_20 = CPtr(SqliteSessionBuffer Ptr, @(arg3->constraints))
                c2fb_temp_21 = local3
                (*c2fb_temp_20) = c2fb_temp_21
                c2fb_temp_22 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(local3))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
            Else
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local1 = c2fb_temp_23
                End If
            End If
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_24 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0, StrPtr(!"RELEASE update_op"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_24
            End If
        End If
        c2fb_external_sqlite3_finalize__(local5)
        sqlite3_free(CPtr(Any Ptr, local3.aBuf))
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg3->constraints.nBuf <> 0))))) Then
        local10 = arg3->constraints
        c2fb_temp_25 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg3->constraints))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
        c2fb_temp_26 = CPtr(SQLITE_C_INT Ptr, @(arg3->bDeferConstraints))
        c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_26) = Cast(SQLITE_C_INT, c2fb_temp_27)
        c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
        c2fb_temp_28 = Cast(c2fb_c_int, sessionApplyRetryBuffer(CPtr(SqliteSessionBuffer Ptr, @(local10)), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), arg0, arg1, arg2, arg3, arg4, arg5))
        local0 = c2fb_temp_28
        sqlite3_free(CPtr(Any Ptr, local10.aBuf))
    End If
    Return local0
End Function

Private Function sessionChangesetFindTable CDecl Alias "sessionChangesetFindTable" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As SqliteChangesetIter Ptr, ByVal arg3 As SqliteSessionTable Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteSessionTable Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_1 As SqliteSessionTable Ptr
    Dim c2fb_temp_2 As SqliteSessionTable Ptr
    Dim c2fb_temp_3 As SqliteSessionTable Ptr
    Dim local5 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_4 As SqliteSessionTable Ptr
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As SQLITE_C_INT Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As UByte Ptr Ptr
    Dim c2fb_temp_9 As UByte Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As ZString Ptr Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As Any Ptr
    Dim c2fb_temp_14 As SQLITE_C_INT Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_18 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_19 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_20 As SqliteSessionTable Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_23 As SqliteSessionTable Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, c2fb_crt_strlen(arg1))
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(SqliteSessionTable Ptr Ptr, @((*arg3)))
    c2fb_temp_1 = CPtr(SqliteSessionTable Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = arg0->pList
    local1 = c2fb_temp_2
    While local1
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_strnicmp(CPtr(Const ZString Ptr, local1->zName), arg1, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_3 = local1->pNext
        local1 = c2fb_temp_3
    Wend
    c2fb_flow_0:
    If arg2 Then
        c2fb_sqlite3changeset_pk(CPtr(Any Ptr, arg2), CPtr(UByte Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local4)))
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (local1 = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, (arg0->db = 0))) <> 0))))) Then
            Return Cast(c2fb_c_int, 1ULL)
        End If
    End If
    If (-Cast(c2fb_c_int, (local1 = 0))) Then
        ' C automatic storage declaration
        c2fb_temp_4 = CPtr(SqliteSessionTable Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSessionTable))) + Cast(c2fb_uint64, local4))) + Cast(c2fb_uint64, local2))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))))))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, (local1 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionTable))))
        c2fb_temp_6 = CPtr(SQLITE_C_INT Ptr, @(local1->nCol))
        c2fb_temp_7 = Cast(c2fb_c_int, local4)
        (*c2fb_temp_6) = Cast(SQLITE_C_INT, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        c2fb_temp_8 = CPtr(UByte Ptr Ptr, @(local1->abPK))
        c2fb_temp_9 = CPtr(UByte Ptr, CPtr(SqliteSessionTable Ptr, @(local1[Cast(c2fb_c_int, 1ULL)])))
        (*c2fb_temp_8) = c2fb_temp_9
        If (-Cast(c2fb_c_int, ((local4 > Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->abPK), CPtr(Const Any Ptr, local3), local4))
        End If
        c2fb_temp_11 = CPtr(ZString Ptr Ptr, @(local1->zName))
        c2fb_temp_12 = CPtr(ZString Ptr, CPtr(UByte Ptr, @(local1->abPK[local4])))
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_temp_13 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->zName), CPtr(Const Any Ptr, arg1), Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))))
        If arg0->db Then
            c2fb_temp_14 = CPtr(SQLITE_C_INT Ptr, @(local1->nCol))
            c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_14) = Cast(SQLITE_C_INT, c2fb_temp_15)
            c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
            c2fb_temp_16 = Cast(c2fb_c_int, sessionInitTable(Cast(c2fb_c_int, &O0ULL), local1, arg0->db, CPtr(Const ZString Ptr, arg0->zDb)))
            local0 = c2fb_temp_16
            If (-Cast(c2fb_c_int, (((local0 <> 0) OrElse ((-Cast(c2fb_c_int, ((local1->nCol = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                sqlite3_free(CPtr(Any Ptr, local1->azCol))
                sqlite3_free(CPtr(Any Ptr, local1))
                Return IIf(local0, local0, Cast(c2fb_c_int, 1ULL))
            End If
        End If
        c2fb_temp_17 = CPtr(SqliteSessionTable Ptr Ptr, @(arg0->pList))
        local5 = c2fb_temp_17
        While (*local5)
            ' empty C statement
        c2fb_flow_3:
            c2fb_temp_18 = CPtr(SqliteSessionTable Ptr Ptr, @(((*local5))->pNext))
            local5 = c2fb_temp_18
        Wend
        c2fb_flow_2:
        c2fb_temp_19 = CPtr(SqliteSessionTable Ptr Ptr, @((*local5)))
        c2fb_temp_20 = local1
        (*c2fb_temp_19) = c2fb_temp_20
    End If
    If (-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, (sessionChangesetCheckCompat(CPtr(c2fb_source_record_51 Ptr, local1), local4, local3) = 0))) <> 0))))) Then
        c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, 17ULL))
        local0 = c2fb_temp_21
    End If
    c2fb_temp_22 = CPtr(SqliteSessionTable Ptr Ptr, @((*arg3)))
    c2fb_temp_23 = local1
    (*c2fb_temp_22) = c2fb_temp_23
    Return local0
End Function

Private Function sessionOneChangeToHash CDecl Alias "sessionOneChangeToHash" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As SqliteSessionTable Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int, ByVal arg5 As UByte Ptr, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As SqliteSessionChange Ptr
    Dim local3 As SqliteSessionChange Ptr
    Dim local4 As SqliteSessionChange Ptr Ptr
    Dim local5 As SqliteSessionBuffer Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_6 As SqliteSessionChange Ptr Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As SqliteSessionChange Ptr
    Dim c2fb_temp_10 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_11 As SqliteSessionChange Ptr
    Dim c2fb_temp_12 As SQLITE_C_INT Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_16 As SqliteSessionChange Ptr
    Dim c2fb_temp_17 As SqliteSessionChange Ptr Ptr
    Dim c2fb_temp_18 As SqliteSessionChange Ptr
    Dim c2fb_temp_19 As SQLITE_C_INT Ptr
    Dim c2fb_temp_20 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg4 < arg1->nCol)))) Then
        local5 = CPtr(SqliteSessionBuffer Ptr, @(arg0->rec))
        c2fb_temp_0 = Cast(c2fb_c_int, sessionChangesetExtendRecord(CPtr(c2fb_source_record_57 Ptr, arg0), CPtr(c2fb_source_record_51 Ptr, arg1), arg4, arg2, CPtr(Const UByte Ptr, arg5), arg6, CPtr(c2fb_source_record_50 Ptr, local5)))
        local0 = c2fb_temp_0
        c2fb_temp_1 = local5->aBuf
        arg5 = c2fb_temp_1
        c2fb_temp_2 = Cast(c2fb_c_int, local5->nBuf)
        arg6 = c2fb_temp_2
        ' C unused-parameter annotation
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (sessionGrowHash(Cast(c2fb_c_int, &O0ULL), arg0->bPatch, arg1) <> 0))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_3
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, sessionChangeHash(CPtr(c2fb_source_record_51 Ptr, arg1), ((-Cast(c2fb_c_int, (((arg0->bPatch <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 9ULL))))) <> 0)))))), arg5, arg1->nChange))
        local1 = c2fb_temp_4
        c2fb_temp_5 = CPtr(SqliteSessionChange Ptr Ptr, @(arg1->apChange[local1]))
        local4 = c2fb_temp_5
        While (*local4)
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = Cast(c2fb_c_int, &O0ULL)
            If arg0->bPatch Then
                c2fb_temp_7 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((*local4))->op) = Cast(c2fb_c_int, 9ULL))))))
                local6 = c2fb_temp_7
                c2fb_temp_8 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 9ULL))))))
                local7 = c2fb_temp_8
            End If
            If sessionChangeEqual(CPtr(c2fb_source_record_51 Ptr, arg1), local6, ((*local4))->aRecord, local7, arg5) Then
                c2fb_temp_9 = (*local4)
                local3 = c2fb_temp_9
                c2fb_temp_10 = CPtr(SqliteSessionChange Ptr Ptr, @((*local4)))
                c2fb_temp_11 = ((*local4))->pNext
                (*c2fb_temp_10) = c2fb_temp_11
                c2fb_temp_12 = CPtr(SQLITE_C_INT Ptr, @(arg1->nEntry))
                c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
                (*c2fb_temp_12) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 - 1)))
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_6 = CPtr(SqliteSessionChange Ptr Ptr, @(((*local4))->pNext))
            local4 = c2fb_temp_6
        Wend
        c2fb_flow_0:
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_14 = Cast(c2fb_c_int, sessionChangeMerge(CPtr(c2fb_source_record_51 Ptr, arg1), arg7, arg0->bPatch, CPtr(c2fb_source_record_52 Ptr, local3), arg2, arg3, arg5, arg6, CPtr(c2fb_source_record_52 Ptr Ptr, CPtr(SqliteSessionChange Ptr Ptr, @(local2)))))
        local0 = c2fb_temp_14
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local2 <> 0))))) Then
        c2fb_temp_15 = CPtr(SqliteSessionChange Ptr Ptr, @(local2->pNext))
        c2fb_temp_16 = arg1->apChange[local1]
        (*c2fb_temp_15) = c2fb_temp_16
        c2fb_temp_17 = CPtr(SqliteSessionChange Ptr Ptr, @(arg1->apChange[local1]))
        c2fb_temp_18 = local2
        (*c2fb_temp_17) = c2fb_temp_18
        c2fb_temp_19 = CPtr(SQLITE_C_INT Ptr, @(arg1->nEntry))
        c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
        (*c2fb_temp_19) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_20 + 1)))
    End If
    Return local0
End Function

Private Function sessionOneChangeIterToHash CDecl Alias "sessionOneChangeIterToHash" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As SqliteSessionTable Ptr
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = CPtr(UByte Ptr, @(arg1->in.aData[Cast(c2fb_c_int, (arg1->in.iCurrent + Cast(c2fb_c_int, 2ULL)))]))
    local1 = Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1->in.iNext - arg1->in.iCurrent))) - Cast(c2fb_c_int, 2ULL)))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->pList = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg0->bPatch))
        c2fb_temp_1 = Cast(c2fb_c_int, arg1->bPatchset)
        (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    Else
        If (-Cast(c2fb_c_int, ((arg1->bPatchset <> arg0->bPatch)))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local6 = c2fb_temp_2
        End If
    End If
    If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_sqlite3changeset_op(CPtr(Any Ptr, arg1), CPtr(Const ZString Ptr Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local4)), CPtr(c2fb_c_int Ptr, @(local5)))
        c2fb_temp_3 = Cast(c2fb_c_int, sessionChangesetFindTable(arg0, local2, arg1, CPtr(SqliteSessionTable Ptr Ptr, @(local7))))
        local6 = c2fb_temp_3
    End If
    If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, sessionOneChangeToHash(arg0, local7, local4, local5, local3, local0, local1, arg2))
        local6 = c2fb_temp_4
    End If
    If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, arg1->rc)
        local6 = c2fb_temp_5
    End If
    Return local6
End Function

Private Function sessionChangesetToHash CDecl Alias "sessionChangesetToHash" (ByVal arg0 As SqliteChangesetIter Ptr, ByVal arg1 As SqliteChangegroup Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg0->in.bNoDiscard))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = (sessionChangesetNext(arg0, CPtr(UByte Ptr Ptr, @(local0)), CPtr(c2fb_c_int Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL)))))))
        If (-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso (arg0->bPatchset <> 0))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local2 = c2fb_temp_2
        Else
            c2fb_temp_3 = Cast(c2fb_c_int, sessionOneChangeIterToHash(arg1, arg0, arg2))
            local2 = c2fb_temp_3
        End If
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, arg0->rc)
        local2 = c2fb_temp_4
    End If
    Return local2
End Function

Function sqlite3changegroup_add CDecl Alias "sqlite3changegroup_add" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangesetIter Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_sqlite3changeset_start(CPtr(Any Ptr Ptr, CPtr(SqliteChangesetIter Ptr Ptr, @(local0))), arg1, arg2))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, sessionChangesetToHash(local0, arg0, Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_1
    End If
    c2fb_sqlite3changeset_finalize(CPtr(Any Ptr, local0))
    Return local1
End Function

Function sqlite3changegroup_add_change CDecl Alias "sqlite3changegroup_add_change" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As SqliteChangesetIter Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As SQLITE_C_INT Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->in.iCurrent = arg1->in.iNext)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->rc <> Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (arg1->bInvert <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(SQLITE_C_INT Ptr, @(arg1->in.bNoDiscard))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_1) = Cast(SQLITE_C_INT, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        c2fb_temp_3 = Cast(c2fb_c_int, sessionOneChangeIterToHash(arg0, arg1, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_3
    End If
    Return local0
End Function

Function sqlite3changegroup_add_strm CDecl Alias "sqlite3changegroup_add_strm" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangesetIter Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_sqlite3changeset_start_strm(CPtr(Any Ptr Ptr, CPtr(SqliteChangesetIter Ptr Ptr, @(local0))), CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, arg1), arg2))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, sessionChangesetToHash(local0, arg0, Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_1
    End If
    c2fb_sqlite3changeset_finalize(CPtr(Any Ptr, local0))
    Return local1
End Function

Sub sqlite3changegroup_delete CDecl Alias "sqlite3changegroup_delete" (ByVal arg0 As SqliteChangegroup Ptr) Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->cd.nBufAlloc))))
            sqlite3_free(CPtr(Any Ptr, arg0->cd.aBuf[local0].aBuf))
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        sqlite3_free(CPtr(Any Ptr, arg0->cd.record.aBuf))
        sqlite3_free(CPtr(Any Ptr, arg0->cd.aBuf))
        sqlite3_free(CPtr(Any Ptr, arg0->zDb))
        sessionDeleteTable(Cast(c2fb_c_int, &O0ULL), arg0->pList)
        sqlite3_free(CPtr(Any Ptr, arg0->rec.aBuf))
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub

Function sqlite3changeset_concat CDecl Alias "sqlite3changeset_concat" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As Any Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangegroup Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, sqlite3changegroup_new(CPtr(SqliteChangegroup Ptr Ptr, @(local0))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_sqlite3changegroup_add(CPtr(Any Ptr, local0), arg0, arg1))
        local1 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_sqlite3changegroup_add(CPtr(Any Ptr, local0), arg2, arg3))
        local1 = c2fb_temp_2
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, sqlite3changegroup_output(local0, arg4, arg5))
        local1 = c2fb_temp_3
    End If
    c2fb_sqlite3changegroup_delete(CPtr(Any Ptr, local0))
    Return local1
End Function

Function sqlite3changeset_concat_strm CDecl Alias "sqlite3changeset_concat_strm" (ByVal arg0 As c2fb_callback_226, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_callback_226, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_callback_230, ByVal arg5 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangegroup Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, sqlite3changegroup_new(CPtr(SqliteChangegroup Ptr Ptr, @(local0))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_sqlite3changegroup_add_strm(CPtr(Any Ptr, local0), CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, arg0), arg1))
        local1 = c2fb_temp_1
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, c2fb_sqlite3changegroup_add_strm(CPtr(Any Ptr, local0), CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, arg2), arg3))
        local1 = c2fb_temp_2
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = Cast(c2fb_c_int, sqlite3changegroup_output_strm(local0, arg4, arg5))
        local1 = c2fb_temp_3
    End If
    c2fb_sqlite3changegroup_delete(CPtr(Any Ptr, local0))
    Return local1
End Function

Private Sub sessionAppendPartialUpdate CDecl Alias "sessionAppendPartialUpdate" (ByVal arg0 As SqliteSessionBuffer Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int Ptr)
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim local4 As UByte Ptr
    Dim local5 As UByte Ptr
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As UByte
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As UByte Ptr
    Dim c2fb_temp_16 As UByte
    Dim c2fb_temp_17 As UByte Ptr
    Dim c2fb_temp_18 As UByte Ptr
    Dim c2fb_temp_19 As UByte Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_22 As Any Ptr
    Dim c2fb_temp_23 As UByte Ptr
    Dim c2fb_temp_24 As UByte Ptr
    Dim c2fb_temp_25 As UByte Ptr
    Dim c2fb_temp_26 As UByte
    Dim c2fb_temp_27 As UByte Ptr
    Dim c2fb_temp_28 As UByte Ptr
    Dim c2fb_temp_29 As SQLITE_C_INT Ptr
    Dim c2fb_temp_30 As c2fb_c_int

    sessionBufferGrow(CPtr(c2fb_source_record_50 Ptr, arg0), Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)) + Cast(c2fb_int64, arg3))) + Cast(c2fb_int64, arg5))), arg6)
    If (-Cast(c2fb_c_int, (((*arg6) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = Cast(c2fb_c_int, &O0ULL)
        local1 = CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf]))
        ' C automatic storage declaration
        local3 = arg2
        local4 = arg4
        local5 = CPtr(UByte Ptr, @(local4[arg5]))
        c2fb_temp_0 = local1
        local1 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = CPtr(UByte Ptr, @((*c2fb_temp_0)))
        c2fb_temp_2 = Cast(UByte, Cast(c2fb_c_int, 23ULL))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = local1
        local1 = (c2fb_temp_3 + 1)
        c2fb_temp_4 = CPtr(UByte Ptr, @((*c2fb_temp_3)))
        c2fb_temp_5 = Cast(UByte, arg1->bIndirect)
        (*c2fb_temp_4) = c2fb_temp_5
        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_6
        While (-Cast(c2fb_c_int, ((local2 < arg1->nCol))))
            local6 = sessionSerialLen(CPtr(Const UByte Ptr, local3))
            local7 = IIf(((-Cast(c2fb_c_int, ((local4 >= local5))))), Cast(c2fb_c_int, &O0ULL), sessionSerialLen(CPtr(Const UByte Ptr, local4)))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 <= Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (arg1->abPK[local2] <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (arg1->abPK[local2] = 0))) <> 0) AndAlso (local3[Cast(c2fb_c_int, &O0ULL)] <> 0))))) Then
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local0 = c2fb_temp_8
                End If
                c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1), CPtr(Const Any Ptr, local3), local6))
                c2fb_temp_10 = CPtr(UByte Ptr, (local1 + local6))
                local1 = c2fb_temp_10
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, &HFFULL))))) <> 0) AndAlso (local3[Cast(c2fb_c_int, &O0ULL)] <> 0))))) Then
                    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local0 = c2fb_temp_11
                    c2fb_temp_12 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1), CPtr(Const Any Ptr, local4), local7))
                    c2fb_temp_13 = CPtr(UByte Ptr, (local1 + local7))
                    local1 = c2fb_temp_13
                Else
                    c2fb_temp_14 = local1
                    local1 = (c2fb_temp_14 + 1)
                    c2fb_temp_15 = CPtr(UByte Ptr, @((*c2fb_temp_14)))
                    c2fb_temp_16 = Cast(UByte, Cast(c2fb_c_int, 0))
                    (*c2fb_temp_15) = c2fb_temp_16
                End If
            End If
            c2fb_temp_17 = CPtr(UByte Ptr, (local3 + local6))
            local3 = c2fb_temp_17
            c2fb_temp_18 = CPtr(UByte Ptr, (local4 + local7))
            local4 = c2fb_temp_18
        c2fb_flow_1:
            c2fb_temp_7 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
        Wend
        c2fb_flow_0:
        If local0 Then
            c2fb_temp_19 = arg4
            local4 = c2fb_temp_19
            c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_20
            While (-Cast(c2fb_c_int, ((local2 < arg1->nCol))))
                local8 = sessionSerialLen(CPtr(Const UByte Ptr, local3))
                local9 = sessionSerialLen(CPtr(Const UByte Ptr, local4))
                If (-Cast(c2fb_c_int, (((arg1->abPK[local2] <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local4[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, &HFFULL))))) <> 0))))) Then
                    c2fb_temp_22 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1), CPtr(Const Any Ptr, local3), local8))
                    c2fb_temp_23 = CPtr(UByte Ptr, (local1 + local8))
                    local1 = c2fb_temp_23
                Else
                    c2fb_temp_24 = local1
                    local1 = (c2fb_temp_24 + 1)
                    c2fb_temp_25 = CPtr(UByte Ptr, @((*c2fb_temp_24)))
                    c2fb_temp_26 = Cast(UByte, Cast(c2fb_c_int, 0))
                    (*c2fb_temp_25) = c2fb_temp_26
                End If
                c2fb_temp_27 = CPtr(UByte Ptr, (local3 + local8))
                local3 = c2fb_temp_27
                c2fb_temp_28 = CPtr(UByte Ptr, (local4 + local9))
                local4 = c2fb_temp_28
            c2fb_flow_3:
                c2fb_temp_21 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_21 + 1)))
            Wend
            c2fb_flow_2:
            c2fb_temp_29 = CPtr(SQLITE_C_INT Ptr, @(arg0->nBuf))
            c2fb_temp_30 = Cast(c2fb_c_int, ((CPtr(UByte Ptr, local1) - CPtr(UByte Ptr, arg0->aBuf))))
            (*c2fb_temp_29) = Cast(SQLITE_C_INT, c2fb_temp_30)
            c2fb_temp_30 = Cast(c2fb_c_int, (*c2fb_temp_29))
        End If
    End If
End Sub

Private Function sessionRebase CDecl Alias "sessionRebase" (ByVal arg0 As SqliteRebaser Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As c2fb_callback_230, ByVal arg3 As Any Ptr, ByVal arg4 As c2fb_c_int Ptr, ByVal arg5 As Any Ptr Ptr) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As SqliteSessionTable Ptr
    Dim local5 As SqliteSessionBuffer
    Dim local6 As SqliteSessionChange Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As Const ZString Ptr
    Dim c2fb_temp_0 As SqliteSessionTable Ptr
    Dim c2fb_temp_1 As SqliteSessionTable Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_4 As SqliteSessionChange Ptr
    Dim c2fb_temp_5 As SqliteSessionChange Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local10 As UByte Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As SQLITE_C_INT Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Any Ptr Ptr
    Dim c2fb_temp_15 As Any Ptr
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As UByte Ptr Ptr
    Dim c2fb_temp_19 As UByte Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Type<SqliteSessionBuffer>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = sessionChangesetNext(arg1, CPtr(UByte Ptr Ptr, @(local1)), CPtr(c2fb_c_int Ptr, @(local2)), CPtr(c2fb_c_int Ptr, @(local3)))))))
        local6 = Cast(c2fb_c_int, &O0ULL)
        local7 = Cast(c2fb_c_int, &O0ULL)
        If local3 Then
            local8 = CPtr(Const ZString Ptr, arg1->zTab)
            c2fb_temp_0 = arg0->grp.pList
            local4 = c2fb_temp_0
            While local4
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(CPtr(Const ZString Ptr, local4->zName), local8))))) Then
                    Goto c2fb_flow_2
                End If
            c2fb_flow_3:
                c2fb_temp_1 = local4->pNext
                local4 = c2fb_temp_1
            Wend
            c2fb_flow_2:
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_2
            If arg1->bPatchset Then
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_3
            End If
            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), IIf(arg1->bPatchset, Cast(c2fb_c_int, 80), Cast(c2fb_c_int, 84)), CPtr(c2fb_c_int Ptr, @(local0)))
            sessionAppendVarint(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg1->nCol, CPtr(c2fb_c_int Ptr, @(local0)))
            sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), CPtr(Const UByte Ptr, arg1->abPK), arg1->nCol, CPtr(c2fb_c_int Ptr, @(local0)))
            sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), CPtr(Const UByte Ptr, CPtr(UByte Ptr, arg1->zTab)), Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_crt_strlen(CPtr(Const ZString Ptr, arg1->zTab))) + Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_c_int Ptr, @(local0)))
        End If
        If (-Cast(c2fb_c_int, (((local4 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            local9 = sessionChangeHash(CPtr(c2fb_source_record_51 Ptr, local4), Cast(c2fb_c_int, &O0ULL), local1, local4->nChange)
            c2fb_temp_4 = local4->apChange[local9]
            local6 = c2fb_temp_4
            While local6
                If sessionChangeEqual(CPtr(c2fb_source_record_51 Ptr, local4), Cast(c2fb_c_int, &O0ULL), local1, Cast(c2fb_c_int, &O0ULL), local6->aRecord) Then
                    Goto c2fb_flow_4
                End If
            c2fb_flow_5:
                c2fb_temp_5 = local6->pNext
                local6 = c2fb_temp_5
            Wend
            c2fb_flow_4:
        End If
        If local6 Then
            ' C unused-parameter annotation
            Select Case arg1->op
                Case Cast(c2fb_c_int, 18ULL)
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->op) = Cast(c2fb_c_int, 18ULL))))) Then
                        c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local7 = c2fb_temp_6
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->bIndirect) = Cast(c2fb_c_int, &O0ULL))))) Then
                            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), Cast(c2fb_c_int, 23ULL), CPtr(c2fb_c_int Ptr, @(local0)))
                            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg1->bIndirect, CPtr(c2fb_c_int Ptr, @(local0)))
                            sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), CPtr(Const UByte Ptr, local6->aRecord), local6->nRecord, CPtr(c2fb_c_int Ptr, @(local0)))
                            sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), CPtr(Const UByte Ptr, local1), local2, CPtr(c2fb_c_int Ptr, @(local0)))
                        End If
                    End If
                Case Cast(c2fb_c_int, 23ULL)
                    c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local7 = c2fb_temp_7
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->op) = Cast(c2fb_c_int, 9ULL))))) Then
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->bIndirect) = Cast(c2fb_c_int, &O0ULL))))) Then
                            local10 = local1
                            sessionSkipRecord(CPtr(UByte Ptr Ptr, @(local10)), arg1->nCol)
                            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), Cast(c2fb_c_int, 18ULL), CPtr(c2fb_c_int Ptr, @(local0)))
                            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg1->bIndirect, CPtr(c2fb_c_int Ptr, @(local0)))
                            sessionAppendRecordMerge(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg1->nCol, local10, Cast(c2fb_int64, (Cast(c2fb_int64, local2) - Cast(c2fb_int64, ((CPtr(UByte Ptr, local10) - CPtr(UByte Ptr, local1)))))), local6->aRecord, local6->nRecord, CPtr(c2fb_c_int Ptr, @(local0)))
                        End If
                    Else
                        sessionAppendPartialUpdate(CPtr(SqliteSessionBuffer Ptr, @(local5)), arg1, local1, local2, local6->aRecord, local6->nRecord, CPtr(c2fb_c_int Ptr, @(local0)))
                    End If
                Case Else
                    ' C unused-parameter annotation
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local7 = c2fb_temp_8
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6->op) = Cast(c2fb_c_int, 18ULL))))) Then
                        sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), Cast(c2fb_c_int, 9ULL), CPtr(c2fb_c_int Ptr, @(local0)))
                        sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg1->bIndirect, CPtr(c2fb_c_int Ptr, @(local0)))
                        sessionAppendRecordMerge(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg1->nCol, local6->aRecord, local6->nRecord, local1, local2, CPtr(c2fb_c_int Ptr, @(local0)))
                    End If
            End Select
            c2fb_flow_6:
        End If
        If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg1->op, CPtr(c2fb_c_int Ptr, @(local0)))
            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), arg1->bIndirect, CPtr(c2fb_c_int Ptr, @(local0)))
            sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), CPtr(Const UByte Ptr, local1), local2, CPtr(c2fb_c_int Ptr, @(local0)))
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5.nBuf > sessionStreamChunkSizeGet())))) <> 0))))) Then
            c2fb_temp_9 = Cast(c2fb_c_int, arg2(arg3, CPtr(Const Any Ptr, local5.aBuf), local5.nBuf))
            local0 = c2fb_temp_9
            c2fb_temp_10 = CPtr(SQLITE_C_INT Ptr, @(local5.nBuf))
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_10) = Cast(SQLITE_C_INT, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        End If
        If local0 Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        sqlite3_free(CPtr(Any Ptr, local5.aBuf))
        c2fb_temp_12 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(local5))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If arg2 Then
            If (-Cast(c2fb_c_int, ((local5.nBuf > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_13 = Cast(c2fb_c_int, arg2(arg3, CPtr(Const Any Ptr, local5.aBuf), local5.nBuf))
                local0 = c2fb_temp_13
            End If
        Else
            If arg5 Then
                c2fb_temp_14 = CPtr(Any Ptr Ptr, @((*arg5)))
                c2fb_temp_15 = CPtr(Any Ptr, local5.aBuf)
                (*c2fb_temp_14) = c2fb_temp_15
                c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg4)))
                c2fb_temp_17 = Cast(c2fb_c_int, local5.nBuf)
                (*c2fb_temp_16) = c2fb_temp_17
                c2fb_temp_18 = CPtr(UByte Ptr Ptr, @(local5.aBuf))
                c2fb_temp_19 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_18) = c2fb_temp_19
            End If
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local5.aBuf))
    Return local0
End Function

Function sqlite3rebaser_configure CDecl Alias "sqlite3rebaser_configure" (ByVal arg0 As SqliteRebaser Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As SqliteChangesetIter Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, c2fb_sqlite3changeset_start(CPtr(Any Ptr Ptr, CPtr(SqliteChangesetIter Ptr Ptr, @(local1))), arg1, CPtr(Any Ptr, arg2)))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, sessionChangesetToHash(local1, CPtr(SqliteChangegroup Ptr, @(arg0->grp)), Cast(c2fb_c_int, 1ULL)))
        local0 = c2fb_temp_1
    End If
    c2fb_sqlite3changeset_finalize(CPtr(Any Ptr, local1))
    Return local0
End Function

Function sqlite3rebaser_rebase CDecl Alias "sqlite3rebaser_rebase" (ByVal arg0 As SqliteRebaser Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangesetIter Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = c2fb_sqlite3changeset_start(CPtr(Any Ptr Ptr, CPtr(SqliteChangesetIter Ptr Ptr, @(local0))), arg1, CPtr(Any Ptr, arg2))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, sessionRebase(arg0, local0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg3, arg4))
        local1 = c2fb_temp_0
        c2fb_sqlite3changeset_finalize(CPtr(Any Ptr, local0))
    End If
    Return local1
End Function

Function sqlite3rebaser_rebase_strm CDecl Alias "sqlite3rebaser_rebase_strm" (ByVal arg0 As SqliteRebaser Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_230, ByVal arg4 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangesetIter Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = c2fb_sqlite3changeset_start_strm(CPtr(Any Ptr Ptr, CPtr(SqliteChangesetIter Ptr Ptr, @(local0))), CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, arg1), arg2)
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, sessionRebase(arg0, local0, arg3, arg4, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_0
        c2fb_sqlite3changeset_finalize(CPtr(Any Ptr, local0))
    End If
    Return local1
End Function

Sub sqlite3rebaser_delete CDecl Alias "sqlite3rebaser_delete" (ByVal arg0 As SqliteRebaser Ptr) Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    If arg0 Then
        sessionDeleteTable(Cast(c2fb_c_int, &O0ULL), arg0->grp.pList)
        sqlite3_free(CPtr(Any Ptr, arg0->grp.rec.aBuf))
        sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub

Function sqlite3changegroup_change_begin CDecl Alias "sqlite3changegroup_change_begin" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteSessionTable Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_5 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_6 As SqliteSessionTable Ptr
    Dim c2fb_temp_7 As SQLITE_C_INT Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As SQLITE_C_INT Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim local3 As SqliteSessionBuffer Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As SqliteSessionBuffer Ptr Ptr
    Dim c2fb_temp_14 As SqliteSessionBuffer Ptr
    Dim c2fb_temp_15 As SQLITE_C_INT Ptr
    Dim c2fb_temp_16 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If arg0->cd.pTab Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 21ULL))
        local1 = c2fb_temp_0
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 18ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 23ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 9ULL))))) <> 0))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local1 = c2fb_temp_1
        Else
            c2fb_temp_2 = Cast(c2fb_c_int, sessionChangesetFindTable(arg0, arg2, Cast(c2fb_c_int, &O0ULL), CPtr(SqliteSessionTable Ptr Ptr, @(local0))))
            local1 = c2fb_temp_2
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg4 <> 0))))) Then
                c2fb_temp_3 = CPtr(ZString Ptr Ptr, @((*arg4)))
                c2fb_temp_4 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"no such table: %s"), arg2))
                (*c2fb_temp_3) = c2fb_temp_4
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        local2 = Cast(c2fb_c_int, (local0->nCol * (IIf((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 23ULL))))), Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, 1ULL)))))
        c2fb_temp_5 = CPtr(SqliteSessionTable Ptr Ptr, @(arg0->cd.pTab))
        c2fb_temp_6 = local0
        (*c2fb_temp_5) = c2fb_temp_6
        c2fb_temp_7 = CPtr(SQLITE_C_INT Ptr, @(arg0->cd.eOp))
        c2fb_temp_8 = Cast(c2fb_c_int, arg1)
        (*c2fb_temp_7) = Cast(SQLITE_C_INT, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        c2fb_temp_9 = CPtr(SQLITE_C_INT Ptr, @(arg0->cd.bIndirect))
        c2fb_temp_10 = Cast(c2fb_c_int, arg3)
        (*c2fb_temp_9) = Cast(SQLITE_C_INT, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
        If (-Cast(c2fb_c_int, ((arg0->cd.nBufAlloc < local2)))) Then
            local3 = CPtr(SqliteSessionBuffer Ptr, CPtr(Any Ptr, sqlite3_realloc(CPtr(Any Ptr, arg0->cd.aBuf), Cast(c2fb_uint64, (Cast(c2fb_uint64, local2) * Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))))))
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                local1 = c2fb_temp_11
            Else
                c2fb_temp_12 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(local3[arg0->cd.nBufAlloc]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (local2 - arg0->cd.nBufAlloc))))))))
                c2fb_temp_13 = CPtr(SqliteSessionBuffer Ptr Ptr, @(arg0->cd.aBuf))
                c2fb_temp_14 = local3
                (*c2fb_temp_13) = c2fb_temp_14
                c2fb_temp_15 = CPtr(SQLITE_C_INT Ptr, @(arg0->cd.nBufAlloc))
                c2fb_temp_16 = Cast(c2fb_c_int, local2)
                (*c2fb_temp_15) = Cast(SQLITE_C_INT, c2fb_temp_16)
                c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
            End If
        End If
    End If
    Return local1
End Function

Function sqlite3changegroup_change_finish CDecl Alias "sqlite3changegroup_change_finish" (ByVal arg0 As SqliteChangegroup Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As SqliteSessionBuffer Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As UByte
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As UByte
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As ZString Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As SQLITE_C_INT Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim local7 As SqliteSessionBuffer Ptr
    Dim c2fb_temp_20 As SqliteSessionBuffer Ptr
    Dim c2fb_temp_21 As Any Ptr
    Dim c2fb_temp_22 As SQLITE_C_INT Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As SQLITE_C_INT Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As UByte Ptr
    Dim c2fb_temp_27 As UByte
    Dim c2fb_temp_28 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As SQLITE_C_INT Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As SqliteSessionTable Ptr Ptr
    Dim c2fb_temp_35 As SqliteSessionTable Ptr
    Dim c2fb_temp_36 As ZString Ptr Ptr
    Dim c2fb_temp_37 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If arg0->cd.pTab Then
        local2 = arg0->cd.aBuf
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
            local4 = arg0->cd.pTab->nCol
            local5 = Cast(c2fb_c_int, 5ULL)
            If (-Cast(c2fb_c_int, ((arg0->cd.eOp = Cast(c2fb_c_int, 23ULL))))) Then
                c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_0
                While (-Cast(c2fb_c_int, ((local3 < local4))))
                    If arg0->cd.pTab->abPK[local3] Then
                        If (-Cast(c2fb_c_int, ((local2[local3].nBuf <= Cast(c2fb_c_int, 1ULL))))) Then
                            c2fb_temp_2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"invalid change: %s value in PK of old.* record"), IIf((-Cast(c2fb_c_int, ((local2[local3].nBuf = Cast(c2fb_c_int, 1ULL))))), StrPtr(!"null"), StrPtr(!"undefined"))))
                            local1 = c2fb_temp_2
                            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local0 = c2fb_temp_3
                            Goto c2fb_flow_0
                        Else
                            If (-Cast(c2fb_c_int, ((local2[Cast(c2fb_c_int, (local3 + local4))].nBuf > Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_4 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"invalid change: defined value in PK of new.* record")))
                                local1 = c2fb_temp_4
                                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                local0 = c2fb_temp_5
                                Goto c2fb_flow_0
                            End If
                        End If
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->bPatch = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2[local3].nBuf > Cast(c2fb_c_int, &O0ULL)))))) <> ((-Cast(c2fb_c_int, ((local2[Cast(c2fb_c_int, (local3 + local4))].nBuf > Cast(c2fb_c_int, &O0ULL)))))))))) <> 0))))) Then
                            c2fb_temp_6 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"invalid change: column %d - old.* value is %sdefined but new.* is %sdefined"), local3, IIf(local2[local3].nBuf, StrPtr(!""), StrPtr(!"un")), IIf(local2[Cast(c2fb_c_int, (local3 + local4))].nBuf, StrPtr(!""), StrPtr(!"un"))))
                            local1 = c2fb_temp_6
                            c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local0 = c2fb_temp_7
                            Goto c2fb_flow_0
                        End If
                    End If
                c2fb_flow_1:
                    c2fb_temp_1 = local3
                    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
                Wend
                c2fb_flow_0:
                c2fb_temp_8 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
                local5 = c2fb_temp_8
                If (-Cast(c2fb_c_int, ((arg0->bPatch = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local4 * Cast(c2fb_c_int, 2ULL))))
                    local4 = c2fb_temp_9
                End If
            Else
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local3 = c2fb_temp_10
                While (-Cast(c2fb_c_int, ((local3 < local4))))
                    local6 = arg0->cd.pTab->abPK[local3]
                    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->cd.eOp = Cast(c2fb_c_int, 18ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->bPatch = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (local6 <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2[local3].nBuf = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                        c2fb_temp_12 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"invalid change: column %d is undefined"), local3))
                        local1 = c2fb_temp_12
                        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local0 = c2fb_temp_13
                        Goto c2fb_flow_2
                    End If
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2[local3].nBuf = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso (local6 <> 0))))) Then
                        c2fb_temp_14 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"invalid change: null value in PK")))
                        local1 = c2fb_temp_14
                        c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local0 = c2fb_temp_15
                        Goto c2fb_flow_2
                    End If
                c2fb_flow_3:
                    c2fb_temp_11 = local3
                    local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_11 + 1)))
                Wend
                c2fb_flow_2:
            End If
            c2fb_temp_16 = CPtr(SQLITE_C_INT Ptr, @(arg0->cd.record.nBuf))
            c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_16) = Cast(SQLITE_C_INT, c2fb_temp_17)
            c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
            c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local3 = c2fb_temp_18
            While (-Cast(c2fb_c_int, ((local3 < local4))))
                local7 = CPtr(SqliteSessionBuffer Ptr, @(arg0->cd.aBuf[local3]))
                If arg0->bPatch Then
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->cd.pTab->abPK[local3]) = Cast(c2fb_c_int, &O0ULL))))) Then
                        If (-Cast(c2fb_c_int, ((arg0->cd.eOp = Cast(c2fb_c_int, 23ULL))))) Then
                            c2fb_temp_20 = CPtr(SqliteSessionBuffer Ptr, (local7 + arg0->cd.pTab->nCol))
                            local7 = c2fb_temp_20
                        Else
                            If (-Cast(c2fb_c_int, ((arg0->cd.eOp = Cast(c2fb_c_int, 9ULL))))) Then
                                Goto c2fb_flow_5
                            End If
                        End If
                    End If
                End If
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionBufferGrow(CPtr(c2fb_source_record_50 Ptr, CPtr(SqliteSessionBuffer Ptr, @(arg0->cd.record))), IIf(local7->nBuf, local7->nBuf, Cast(c2fb_c_int, 1ULL)), CPtr(c2fb_c_int Ptr, @(local0))))))) Then
                    If local7->nBuf Then
                        c2fb_temp_21 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg0->cd.record.aBuf[arg0->cd.record.nBuf]))), CPtr(Const Any Ptr, local7->aBuf), local7->nBuf))
                        c2fb_temp_22 = CPtr(SQLITE_C_INT Ptr, @(arg0->cd.record.nBuf))
                        c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_22)) + local7->nBuf)))
                        (*c2fb_temp_22) = Cast(SQLITE_C_INT, c2fb_temp_23)
                        c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
                    Else
                        c2fb_temp_24 = CPtr(SQLITE_C_INT Ptr, @(arg0->cd.record.nBuf))
                        c2fb_temp_25 = Cast(c2fb_c_int, (*c2fb_temp_24))
                        (*c2fb_temp_24) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_25 + 1)))
                        c2fb_temp_26 = CPtr(UByte Ptr, @(arg0->cd.record.aBuf[c2fb_temp_25]))
                        c2fb_temp_27 = Cast(UByte, local5)
                        (*c2fb_temp_26) = c2fb_temp_27
                    End If
                End If
            c2fb_flow_5:
                c2fb_temp_19 = local3
                local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_19 + 1)))
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_28 = Cast(c2fb_c_int, sessionOneChangeToHash(arg0, arg0->cd.pTab, arg0->cd.eOp, arg0->cd.bIndirect, arg0->cd.pTab->nCol, arg0->cd.record.aBuf, arg0->cd.record.nBuf, Cast(c2fb_c_int, &O0ULL)))
                local0 = c2fb_temp_28
            End If
        End If
        local8 = arg0->cd.pTab->nCol
        If (-Cast(c2fb_c_int, ((arg0->cd.eOp = Cast(c2fb_c_int, 23ULL))))) Then
            c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local8 + local8)))
            local8 = c2fb_temp_29
        End If
        c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_30
        While (-Cast(c2fb_c_int, ((local3 < local8))))
            c2fb_temp_32 = CPtr(SQLITE_C_INT Ptr, @(arg0->cd.aBuf[local3].nBuf))
            c2fb_temp_33 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_32) = Cast(SQLITE_C_INT, c2fb_temp_33)
            c2fb_temp_33 = Cast(c2fb_c_int, (*c2fb_temp_32))
        c2fb_flow_7:
            c2fb_temp_31 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_31 + 1)))
        Wend
        c2fb_flow_6:
        c2fb_temp_34 = CPtr(SqliteSessionTable Ptr Ptr, @(arg0->cd.pTab))
        c2fb_temp_35 = CPtr(SqliteSessionTable Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_34) = c2fb_temp_35
    End If
    If arg2 Then
        c2fb_temp_36 = CPtr(ZString Ptr Ptr, @((*arg2)))
        c2fb_temp_37 = local1
        (*c2fb_temp_36) = c2fb_temp_37
    Else
        sqlite3_free(CPtr(Any Ptr, local1))
    End If
    Return local0
End Function

/' ------------------------------------------------------------------------- '/
/' Changeset application entry points                                         '/
/' ------------------------------------------------------------------------- '/

Private Function sessionChangesetApply CDecl Alias "sessionChangesetApply" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As SqliteChangesetIter Ptr, ByVal arg2 As c2fb_callback_225, ByVal arg3 As c2fb_callback_235, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim local3 As SqliteSessionApplyCtx
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_uint64
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_0 As sqlite3_uint64 Ptr
    Dim c2fb_temp_1 As c2fb_uint64
    Dim c2fb_temp_2 As SQLITE_C_INT Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As SQLITE_C_INT Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As UByte
    Dim c2fb_temp_9 As SQLITE_C_INT Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As Const ZString Ptr
    Dim local10 As UByte Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As sqlite3 Ptr Ptr
    Dim c2fb_temp_20 As sqlite3 Ptr
    Dim c2fb_temp_21 As Any Ptr Ptr
    Dim c2fb_temp_22 As SqliteVdbe Ptr
    Dim c2fb_temp_23 As Any Ptr Ptr
    Dim c2fb_temp_24 As SqliteVdbe Ptr
    Dim c2fb_temp_25 As Any Ptr Ptr
    Dim c2fb_temp_26 As SqliteVdbe Ptr
    Dim c2fb_temp_27 As SQLITE_C_INT Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_30 As Const ZString Ptr Ptr
    Dim c2fb_temp_31 As UByte Ptr Ptr
    Dim c2fb_temp_32 As UByte Ptr
    Dim c2fb_temp_33 As SQLITE_C_INT Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As SQLITE_C_INT Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As UByte Ptr
    Dim c2fb_temp_38 As UByte
    Dim c2fb_temp_39 As SQLITE_C_INT Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As Any Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As Const ZString Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As Const ZString Ptr Ptr Ptr
    Dim c2fb_temp_46 As Const ZString Ptr Ptr
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_47 As c2fb_c_int
    Dim c2fb_temp_48 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As c2fb_c_int
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As c2fb_c_int
    Dim c2fb_temp_54 As SQLITE_C_INT Ptr
    Dim c2fb_temp_55 As c2fb_c_int
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As SQLITE_C_INT Ptr
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As c2fb_c_int
    Dim c2fb_temp_60 As c2fb_c_int
    Dim c2fb_temp_61 As c2fb_c_int
    Dim c2fb_temp_62 As c2fb_c_int
    Dim c2fb_temp_63 As c2fb_c_int
    Dim c2fb_temp_64 As SQLITE_C_INT Ptr
    Dim c2fb_temp_65 As c2fb_c_int
    Dim c2fb_temp_66 As c2fb_c_int
    Dim c2fb_temp_67 As c2fb_c_int
    Dim c2fb_temp_68 As c2fb_c_int
    Dim c2fb_temp_69 As c2fb_c_int
    Dim local13 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim local15 As c2fb_c_int
    Dim local16 As SqliteChangesetIter
    Dim c2fb_temp_70 As Any Ptr
    Dim c2fb_temp_71 As SQLITE_C_INT Ptr
    Dim c2fb_temp_72 As c2fb_c_int
    Dim c2fb_temp_73 As c2fb_c_int
    Dim c2fb_temp_74 As c2fb_c_int
    Dim local17 As c2fb_c_int
    Dim c2fb_temp_75 As c2fb_c_int
    Dim c2fb_temp_76 As c2fb_c_int
    Dim c2fb_temp_77 As Any Ptr Ptr
    Dim c2fb_temp_78 As Any Ptr
    Dim c2fb_temp_79 As c2fb_c_int Ptr
    Dim c2fb_temp_80 As c2fb_c_int
    Dim c2fb_temp_81 As UByte Ptr Ptr
    Dim c2fb_temp_82 As UByte Ptr
    Dim c2fb_temp_83 As sqlite3_uint64 Ptr
    Dim c2fb_temp_84 As c2fb_uint64
    Dim c2fb_temp_85 As SQLITE_C_INT Ptr
    Dim c2fb_temp_86 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    local5 = Cast(c2fb_uint64, (arg0->flags And (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, &H00008ULL))) Shl Cast(c2fb_c_int, 32ULL))))))
    local6 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    sqlite3_mutex_enter(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(arg0)))
    If Cast(c2fb_c_int, (arg8 And Cast(c2fb_c_int, &H0008ULL))) Then
        c2fb_temp_0 = CPtr(sqlite3_uint64 Ptr, @(arg0->flags))
        c2fb_temp_1 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (*c2fb_temp_0)) Or (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, &H00008ULL))) Shl Cast(c2fb_c_int, 32ULL)))))))))
        (*c2fb_temp_0) = Cast(sqlite3_uint64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_uint64, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(SQLITE_C_INT Ptr, @(arg0->aDb(Cast(c2fb_c_int, &O0ULL)).pSchema->schema_cookie))
        c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_2)) - Cast(c2fb_c_int, 32ULL))))
        (*c2fb_temp_2) = Cast(SQLITE_C_INT, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    End If
    c2fb_temp_4 = CPtr(SQLITE_C_INT Ptr, @(arg1->in.bNoDiscard))
    c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_4) = Cast(SQLITE_C_INT, c2fb_temp_5)
    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionApplyCtx))))
    c2fb_temp_7 = CPtr(UByte Ptr, @(local3.bRebase))
    c2fb_temp_8 = Cast(UByte, ((-Cast(c2fb_c_int, (((arg6 <> 0) AndAlso (arg7 <> 0)))))))
    (*c2fb_temp_7) = c2fb_temp_8
    c2fb_temp_9 = CPtr(SQLITE_C_INT Ptr, @(local3.bInvertConstraints))
    c2fb_temp_10 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg8 And Cast(c2fb_c_int, &H0002ULL)))) = 0))) = 0))))
    (*c2fb_temp_9) = Cast(SQLITE_C_INT, c2fb_temp_10)
    c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
    c2fb_temp_11 = CPtr(UByte Ptr, @(local3.bIgnoreNoop))
    c2fb_temp_12 = Cast(UByte, (-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg8 And Cast(c2fb_c_int, &H0004ULL)))) = 0))) = 0))))
    (*c2fb_temp_11) = c2fb_temp_12
    c2fb_temp_13 = CPtr(UByte Ptr, @(local3.bNoUpdateLoop))
    c2fb_temp_14 = Cast(UByte, (-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg8 And Cast(c2fb_c_int, &H0010ULL)))) = 0))) = 0))))
    (*c2fb_temp_13) = c2fb_temp_14
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg8 And Cast(c2fb_c_int, &H0001ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_15 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0, StrPtr(!"SAVEPOINT changeset_apply"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_15
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_16 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0, StrPtr(!"PRAGMA defer_foreign_keys = 1"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_16
    End If
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = sessionChangesetNext(arg1, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_c_int Ptr, @(local6))))))) <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        sqlite3changeset_op(arg1, CPtr(Const ZString Ptr Ptr, @(local9)), CPtr(c2fb_c_int Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local8)), Cast(c2fb_c_int, &O0ULL))
        If local6 Then
            ' C automatic storage declaration
            c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local6 = c2fb_temp_17
            c2fb_temp_18 = Cast(c2fb_c_int, sessionRetryConstraints(arg0, arg1->bPatchset, local2, CPtr(SqliteSessionApplyContext Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3))), arg4, arg5))
            local1 = c2fb_temp_18
            If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
            sessionUpdateFree(CPtr(c2fb_source_record_55 Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3))))
            sqlite3_free(CPtr(Any Ptr, CPtr(ZString Ptr, local3.azCol)))
            c2fb_external_sqlite3_finalize__(CPtr(SqliteVdbe Ptr, local3.pDelete))
            c2fb_external_sqlite3_finalize__(CPtr(SqliteVdbe Ptr, local3.pInsert))
            c2fb_external_sqlite3_finalize__(CPtr(SqliteVdbe Ptr, local3.pSelect))
            c2fb_temp_19 = CPtr(sqlite3 Ptr Ptr, @(local3.db))
            c2fb_temp_20 = arg0
            (*c2fb_temp_19) = c2fb_temp_20
            c2fb_temp_21 = CPtr(Any Ptr Ptr, @(local3.pDelete))
            c2fb_temp_22 = CPtr(SqliteVdbe Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_21) = CPtr(Any Ptr, c2fb_temp_22)
            c2fb_temp_22 = CPtr(SqliteVdbe Ptr, (*c2fb_temp_21))
            c2fb_temp_23 = CPtr(Any Ptr Ptr, @(local3.pInsert))
            c2fb_temp_24 = CPtr(SqliteVdbe Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_23) = CPtr(Any Ptr, c2fb_temp_24)
            c2fb_temp_24 = CPtr(SqliteVdbe Ptr, (*c2fb_temp_23))
            c2fb_temp_25 = CPtr(Any Ptr Ptr, @(local3.pSelect))
            c2fb_temp_26 = CPtr(SqliteVdbe Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_25) = CPtr(Any Ptr, c2fb_temp_26)
            c2fb_temp_26 = CPtr(SqliteVdbe Ptr, (*c2fb_temp_25))
            c2fb_temp_27 = CPtr(SQLITE_C_INT Ptr, @(local3.nCol))
            c2fb_temp_28 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_27) = Cast(SQLITE_C_INT, c2fb_temp_28)
            c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
            c2fb_temp_29 = CPtr(Const ZString Ptr Ptr Ptr, @(local3.azCol))
            c2fb_temp_30 = CPtr(Const ZString Ptr Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_29) = c2fb_temp_30
            c2fb_temp_31 = CPtr(UByte Ptr Ptr, @(local3.abPK))
            c2fb_temp_32 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_31) = c2fb_temp_32
            c2fb_temp_33 = CPtr(SQLITE_C_INT Ptr, @(local3.bStat1))
            c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_33) = Cast(SQLITE_C_INT, c2fb_temp_34)
            c2fb_temp_34 = Cast(c2fb_c_int, (*c2fb_temp_33))
            c2fb_temp_35 = CPtr(SQLITE_C_INT Ptr, @(local3.bDeferConstraints))
            c2fb_temp_36 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_35) = Cast(SQLITE_C_INT, c2fb_temp_36)
            c2fb_temp_36 = Cast(c2fb_c_int, (*c2fb_temp_35))
            c2fb_temp_37 = CPtr(UByte Ptr, @(local3.bRebaseStarted))
            c2fb_temp_38 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_37) = c2fb_temp_38
            c2fb_temp_39 = CPtr(SQLITE_C_INT Ptr, @(local3.bRowid))
            c2fb_temp_40 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            (*c2fb_temp_39) = Cast(SQLITE_C_INT, c2fb_temp_40)
            c2fb_temp_40 = Cast(c2fb_c_int, (*c2fb_temp_39))
            c2fb_temp_41 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteSessionBuffer Ptr, @(local3.constraints))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteSessionBuffer))))
            c2fb_temp_42 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = arg2(arg5, local9)))))) <> 0)))))))
            local0 = c2fb_temp_42
            If local0 Then
                c2fb_temp_43 = CPtr(Const ZString Ptr, CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s"), local9)))
                local2 = c2fb_temp_43
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_44 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    local1 = c2fb_temp_44
                    Goto c2fb_flow_0
                End If
                c2fb_temp_45 = CPtr(Const ZString Ptr Ptr Ptr, @(local3.azCol))
                c2fb_temp_46 = CPtr(Const ZString Ptr Ptr, local2)
                (*c2fb_temp_45) = c2fb_temp_46
            Else
                local11 = Cast(c2fb_c_int, &O0ULL)
                ' C automatic storage declaration
                sqlite3changeset_pk(arg1, CPtr(UByte Ptr Ptr, @(local10)), Cast(c2fb_c_int, &O0ULL))
                c2fb_temp_47 = Cast(c2fb_c_int, sessionTableInfo(Cast(c2fb_c_int, &O0ULL), arg0, StrPtr(!"main"), local9, CPtr(c2fb_c_int Ptr, @(local3.nCol)), Cast(c2fb_c_int, &O0ULL), CPtr(Const ZString Ptr Ptr, @(local2)), CPtr(Const ZString Ptr Ptr Ptr, @(local3.azCol)), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), CPtr(UByte Ptr Ptr, @(local3.abPK)), CPtr(c2fb_c_int Ptr, @(local3.bRowid))))
                local1 = c2fb_temp_47
                If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
                    Goto c2fb_flow_0
                End If
                c2fb_temp_48 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local12 = c2fb_temp_48
                While (-Cast(c2fb_c_int, ((local12 < local3.nCol))))
                    If local3.abPK[local12] Then
                        c2fb_temp_50 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local12 + Cast(c2fb_c_int, 1ULL))))
                        local11 = c2fb_temp_50
                    End If
                c2fb_flow_3:
                    c2fb_temp_49 = local12
                    local12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_49 + 1)))
                Wend
                c2fb_flow_2:
                If (-Cast(c2fb_c_int, ((local3.nCol = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_51 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local0 = c2fb_temp_51
                    sqlite3_log(Cast(c2fb_c_int, 17ULL), StrPtr(!"sqlite3changeset_apply(): no such table: %s"), local2)
                Else
                    If (-Cast(c2fb_c_int, ((local3.nCol < local7)))) Then
                        c2fb_temp_52 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                        local0 = c2fb_temp_52
                        sqlite3_log(Cast(c2fb_c_int, 17ULL), StrPtr(!"sqlite3changeset_apply(): table %s has %d columns, expected %d or more"), local2, local3.nCol, local7)
                    Else
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 < local11)))) <> 0) OrElse ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, local3.abPK), CPtr(Const Any Ptr, local10), local7) <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                            c2fb_temp_53 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                            local0 = c2fb_temp_53
                            sqlite3_log(Cast(c2fb_c_int, 17ULL), StrPtr(!"sqlite3changeset_apply(): primary key mismatch for table %s"), local2)
                        Else
                            c2fb_temp_54 = CPtr(SQLITE_C_INT Ptr, @(local3.nCol))
                            c2fb_temp_55 = Cast(c2fb_c_int, local7)
                            (*c2fb_temp_54) = Cast(SQLITE_C_INT, c2fb_temp_55)
                            c2fb_temp_55 = Cast(c2fb_c_int, (*c2fb_temp_54))
                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(local2, StrPtr(!"sqlite_stat1")))))) Then
                                c2fb_temp_56 = Cast(c2fb_c_int, sessionStat1Sql(arg0, CPtr(c2fb_source_record_55 Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3)))))
                                local1 = c2fb_temp_56
                                If (c2fb_temp_56) Then
                                    Goto c2fb_flow_0
                                End If
                                c2fb_temp_57 = CPtr(SQLITE_C_INT Ptr, @(local3.bStat1))
                                c2fb_temp_58 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                                (*c2fb_temp_57) = Cast(SQLITE_C_INT, c2fb_temp_58)
                                c2fb_temp_58 = Cast(c2fb_c_int, (*c2fb_temp_57))
                            Else
                                c2fb_temp_59 = Cast(c2fb_c_int, sessionSelectRow(arg0, local2, CPtr(c2fb_source_record_55 Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3)))))
                                local1 = c2fb_temp_59
                                c2fb_temp_61 = 1
                                If (((c2fb_temp_59) <> 0) = 0) Then
                                    c2fb_temp_60 = Cast(c2fb_c_int, sessionDeleteRow(arg0, local2, CPtr(c2fb_source_record_55 Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3)))))
                                    local1 = c2fb_temp_60
                                    c2fb_temp_61 = (-Cast(c2fb_c_int, (((c2fb_temp_60) <> 0))))
                                End If
                                c2fb_temp_63 = 1
                                If ((c2fb_temp_61 <> 0) = 0) Then
                                    c2fb_temp_62 = Cast(c2fb_c_int, sessionInsertRow(arg0, local2, CPtr(c2fb_source_record_55 Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3)))))
                                    local1 = c2fb_temp_62
                                    c2fb_temp_63 = (-Cast(c2fb_c_int, (((c2fb_temp_62) <> 0))))
                                End If
                                If c2fb_temp_63 Then
                                    Goto c2fb_flow_0
                                End If
                                c2fb_temp_64 = CPtr(SQLITE_C_INT Ptr, @(local3.bStat1))
                                c2fb_temp_65 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                                (*c2fb_temp_64) = Cast(SQLITE_C_INT, c2fb_temp_65)
                                c2fb_temp_65 = Cast(c2fb_c_int, (*c2fb_temp_64))
                            End If
                        End If
                    End If
                End If
            End If
        End If
        If local0 Then
            Goto c2fb_flow_1
        End If
        If (-Cast(c2fb_c_int, (((arg3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = arg3(arg5, arg1))))) <> 0))))) Then
            Goto c2fb_flow_1
        End If
        c2fb_temp_66 = Cast(c2fb_c_int, sessionApplyOneWithRetry(arg0, arg1, CPtr(SqliteSessionApplyContext Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3))), arg4, arg5))
        local1 = c2fb_temp_66
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_67 = Cast(c2fb_c_int, arg1->bPatchset)
    local4 = c2fb_temp_67
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_68 = Cast(c2fb_c_int, sqlite3changeset_finalize(arg1))
        local1 = c2fb_temp_68
    Else
        sqlite3changeset_finalize(arg1)
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_69 = Cast(c2fb_c_int, sessionRetryConstraints(arg0, local4, local2, CPtr(SqliteSessionApplyContext Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3))), arg4, arg5))
        local1 = c2fb_temp_69
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_external_sqlite3_db_status(arg0, Cast(c2fb_c_int, 10ULL), CPtr(c2fb_c_int Ptr, @(local13)), CPtr(c2fb_c_int Ptr, @(local14)), Cast(c2fb_c_int, &O0ULL))
        If (-Cast(c2fb_c_int, ((local13 <> Cast(c2fb_c_int, &O0ULL))))) Then
            local15 = Cast(c2fb_c_int, 2ULL)
            ' C automatic storage declaration
            c2fb_temp_70 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(SqliteChangesetIter Ptr, @(local16))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(SqliteChangesetIter))))
            c2fb_temp_71 = CPtr(SQLITE_C_INT Ptr, @(local16.nCol))
            c2fb_temp_72 = Cast(c2fb_c_int, local13)
            (*c2fb_temp_71) = Cast(SQLITE_C_INT, c2fb_temp_72)
            c2fb_temp_72 = Cast(c2fb_c_int, (*c2fb_temp_71))
            c2fb_temp_73 = Cast(c2fb_c_int, arg4(arg5, Cast(c2fb_c_int, 5ULL), CPtr(SqliteChangesetIter Ptr, @(local16))))
            local15 = c2fb_temp_73
            If (-Cast(c2fb_c_int, ((local15 <> Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_74 = Cast(c2fb_c_int, Cast(c2fb_c_int, 19ULL))
                local1 = c2fb_temp_74
            End If
        End If
    End If
    local17 = c2fb_external_sqlite3_exec_(arg0, StrPtr(!"PRAGMA defer_foreign_keys = 0"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_75 = Cast(c2fb_c_int, local17)
        local1 = c2fb_temp_75
    End If
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg8 And Cast(c2fb_c_int, &H0001ULL)))) = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_76 = Cast(c2fb_c_int, c2fb_external_sqlite3_exec_(arg0, StrPtr(!"RELEASE changeset_apply"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL)))
            local1 = c2fb_temp_76
        End If
        If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_exec_(arg0, StrPtr(!"ROLLBACK TO changeset_apply"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
            c2fb_external_sqlite3_exec_(arg0, StrPtr(!"RELEASE changeset_apply"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
        End If
    End If
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local3.bRebase <> 0))))) Then
        ' C unused-parameter annotation
        c2fb_temp_77 = CPtr(Any Ptr Ptr, @((*arg6)))
        c2fb_temp_78 = CPtr(Any Ptr, local3.rebase.aBuf)
        (*c2fb_temp_77) = c2fb_temp_78
        c2fb_temp_79 = CPtr(c2fb_c_int Ptr, @((*arg7)))
        c2fb_temp_80 = Cast(c2fb_c_int, local3.rebase.nBuf)
        (*c2fb_temp_79) = c2fb_temp_80
        c2fb_temp_81 = CPtr(UByte Ptr Ptr, @(local3.rebase.aBuf))
        c2fb_temp_82 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_81) = c2fb_temp_82
    End If
    sessionUpdateFree(CPtr(c2fb_source_record_55 Ptr, CPtr(SqliteSessionApplyCtx Ptr, @(local3))))
    c2fb_external_sqlite3_finalize__(CPtr(SqliteVdbe Ptr, local3.pInsert))
    c2fb_external_sqlite3_finalize__(CPtr(SqliteVdbe Ptr, local3.pDelete))
    c2fb_external_sqlite3_finalize__(CPtr(SqliteVdbe Ptr, local3.pSelect))
    sqlite3_free(CPtr(Any Ptr, CPtr(ZString Ptr, local3.azCol)))
    sqlite3_free(CPtr(Any Ptr, CPtr(ZString Ptr, local3.constraints.aBuf)))
    sqlite3_free(CPtr(Any Ptr, CPtr(ZString Ptr, local3.rebase.aBuf)))
    If (-Cast(c2fb_c_int, ((((Cast(c2fb_c_int, (arg8 And Cast(c2fb_c_int, &H0008ULL)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        ' C unused-parameter annotation
        c2fb_temp_83 = CPtr(sqlite3_uint64 Ptr, @(arg0->flags))
        c2fb_temp_84 = Cast(c2fb_uint64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (*c2fb_temp_83)) And Cast(c2fb_uint64, (Not (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_c_int, &H00008ULL))) Shl Cast(c2fb_c_int, 32ULL)))))))))))
        (*c2fb_temp_83) = Cast(sqlite3_uint64, c2fb_temp_84)
        c2fb_temp_84 = Cast(c2fb_uint64, (*c2fb_temp_83))
        c2fb_temp_85 = CPtr(SQLITE_C_INT Ptr, @(arg0->aDb(Cast(c2fb_c_int, &O0ULL)).pSchema->schema_cookie))
        c2fb_temp_86 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_85)) - Cast(c2fb_c_int, 32ULL))))
        (*c2fb_temp_85) = Cast(SQLITE_C_INT, c2fb_temp_86)
        c2fb_temp_86 = Cast(c2fb_c_int, (*c2fb_temp_85))
    End If
    ' C unused-parameter annotation
    c2fb_external_sqlite3_set_errmsg(arg0, local1, CPtr(Const ZString Ptr, local3.zErr))
    sqlite3_free(CPtr(Any Ptr, local3.zErr))
    sqlite3_mutex_leave(CPtr(Any Ptr, c2fb_external_sqlite3_db_mutex(arg0)))
    Return local1
End Function

Private Function sessionChangesetApplyV23 CDecl Alias "sessionChangesetApplyV23" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_226, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_225, ByVal arg6 As c2fb_callback_235, ByVal arg7 As c2fb_callback_229, ByVal arg8 As Any Ptr, ByVal arg9 As Any Ptr Ptr, ByVal arg10 As c2fb_c_int Ptr, ByVal arg11 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Dim local0 As SqliteChangesetIter Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    local1 = (-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg11 And Cast(c2fb_c_int, &H0002ULL)))) = 0))) = 0)))
    local2 = sessionChangesetStart(CPtr(SqliteChangesetIter Ptr Ptr, @(local0)), arg3, arg4, arg1, arg2, local1, Cast(c2fb_c_int, 1ULL))
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, sessionChangesetApply(arg0, local0, arg5, arg6, arg7, arg8, arg9, arg10, arg11))
        local2 = c2fb_temp_0
    End If
    Return local2
End Function

Function sqlite3changeset_apply_v2 CDecl Alias "sqlite3changeset_apply_v2" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_225, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetApplyV23(arg0, arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg3, Cast(c2fb_c_int, &O0ULL), arg4, arg5, arg6, arg7, arg8)
End Function

Function sqlite3changeset_apply_v3 CDecl Alias "sqlite3changeset_apply_v3" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_235, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetApplyV23(arg0, arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg3, arg4, arg5, arg6, arg7, arg8)
End Function

Function sqlite3changeset_apply CDecl Alias "sqlite3changeset_apply" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_225, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetApplyV23(arg0, arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg3, Cast(c2fb_c_int, &O0ULL), arg4, arg5, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Function

Function sqlite3changeset_apply_v3_strm CDecl Alias "sqlite3changeset_apply_v3_strm" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_235, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetApplyV23(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1, arg2, Cast(c2fb_c_int, &O0ULL), arg3, arg4, arg5, arg6, arg7, arg8)
End Function

Function sqlite3changeset_apply_v2_strm CDecl Alias "sqlite3changeset_apply_v2_strm" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_225, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetApplyV23(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1, arg2, arg3, Cast(c2fb_c_int, &O0ULL), arg4, arg5, arg6, arg7, arg8)
End Function

Function sqlite3changeset_apply_strm CDecl Alias "sqlite3changeset_apply_strm" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_callback_226, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_callback_225, ByVal arg4 As c2fb_callback_229, ByVal arg5 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: /tmp/sqlite_fb_session_root/src/sqlite3session.c
    Return sessionChangesetApplyV23(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1, arg2, arg3, Cast(c2fb_c_int, &O0ULL), arg4, arg5, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Function
#endif

/' end of sqlite3_bulk_session_changeset.bas '/
