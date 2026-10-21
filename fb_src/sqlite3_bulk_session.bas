/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_session.bas

    Purpose:

        Port C2FB-supported Session runtime bodies from
        ext/session/sqlite3session.c.

    Responsibilities:

        - Manage Session and changeset state for translated API routines.
        - Read and write changeset records through SQLite's core interfaces.
        - Preserve the upstream C ABI for each included function.

    This file intentionally does NOT contain:

        - The 106 Session routines not yet accepted by C2FB.
        - Public API declarations from ext/session/sqlite3session.h.
        - Test support or the standalone changeset command-line utility.
'/

#lang "fb"
#if defined(SQLITE_ENABLE_SESSION) AndAlso _
    defined(SQLITE_ENABLE_PREUPDATE_HOOK)
#include once "sqlite3_btree.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_expr_types.bi"
#include once "sqlite3_hash_types.bi"
#include once "sqlite3_pager.bi"
#include once "sqlite3_parser_types.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_varint.bi"
#include once "sqlite3_vdbe_core.bi"
#include once "sqlite3_vdbe_mem_types.bi"
#include once "sqlite3_vdbe_record.bi"

/' ------------------------------------------------------------------------- '/
/'
    Internal linkage across FreeBASIC modules

    The changeset batch is compiled as a separate module. Helpers shared by
    both batches therefore need linker-visible definitions here. The SQLite
    version script keeps these non-sqlite3 symbols local to the shared library.
'/

/' C2FB-translated Session runtime routines                                   '/
/' ------------------------------------------------------------------------- '/

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

Declare Function sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function sqlite3_snprintf CDecl Alias "sqlite3_snprintf" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As Const ZString Ptr, ...) As ZString Ptr
Declare Function sqlite3_malloc CDecl Alias "sqlite3_malloc" (ByVal arg0 As c2fb_c_int) As Any Ptr
Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function sqlite3_bind_double CDecl Alias "sqlite3_bind_double" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Double) As c2fb_c_int
Declare Function sqlite3_column_double CDecl Alias "sqlite3_column_double" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As Double
Declare Function sqlite3_column_type CDecl Alias "sqlite3_column_type" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3CorruptError CDecl Alias "sqlite3CorruptError" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3Strlen30 CDecl Alias "sqlite3Strlen30" (ByVal arg0 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int

Type c2fb_sqlite3_destructor_type As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_2 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As SQLITE_C_INT) As SQLITE_C_INT
Type c2fb_callback_23 As Function CDecl(ByVal arg0 As SQLITE_C_INT, ByVal arg1 As Const Any Ptr, ByVal arg2 As sqlite3VdbeUnpackedRecord Ptr) As SQLITE_C_INT
Type c2fb_callback_22 As Sub CDecl(ByVal arg0 As PgHdr Ptr)
Type c2fb_callback_223 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Type c2fb_callback_230 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int

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
Declare Sub sessionMergeRecord CDecl Alias "sessionMergeRecord" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As UByte Ptr)
Declare Function sessionMergeValue CDecl Alias "sessionMergeValue" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As UByte Ptr
Declare Function sessionMergeUpdate CDecl Alias "sessionMergeUpdate" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As c2fb_source_record_51 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As UByte Ptr, ByVal arg5 As UByte Ptr, ByVal arg6 As UByte Ptr) As c2fb_c_int
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
Declare Function sessionPrepare CDecl Alias "sessionPrepare" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As SqliteVdbe Ptr Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
Declare Sub sessionPrepareMprintf CDecl Alias "sessionPrepareMprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As SqliteVdbe Ptr Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As Const ZString Ptr, ...)
Declare Function sessionSelectStmt CDecl Alias "sessionSelectStmt" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As UByte Ptr, ByVal arg8 As SqliteVdbe Ptr Ptr, ByVal arg9 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sessionSelectBind CDecl Alias "sessionSelectBind" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_source_record_52 Ptr) As c2fb_c_int
Declare Sub sessionAppendTableHdr CDecl Alias "sessionAppendTableHdr" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_51 Ptr, ByVal arg3 As c2fb_c_int Ptr)
Declare Sub sessionSkipRecord CDecl Alias "sessionSkipRecord" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As c2fb_c_int)
Declare Function sessionValueSetStr CDecl Alias "sessionValueSetStr" (ByVal arg0 As SqliteVdbeMem Ptr, ByVal arg1 As UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte) As c2fb_c_int
Declare Sub sessionUpdateFree CDecl Alias "sessionUpdateFree" (ByVal arg0 As c2fb_source_record_55 Ptr)
Declare Function sessionDeleteRow CDecl Alias "sessionDeleteRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
Declare Function sessionSelectRow CDecl Alias "sessionSelectRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
Declare Function sessionInsertRow CDecl Alias "sessionInsertRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
Declare Function sessionStat1Sql CDecl Alias "sessionStat1Sql" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_55 Ptr) As c2fb_c_int
Declare Function sessionBindValue CDecl Alias "sessionBindValue" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function sessionBindRow CDecl Alias "sessionBindRow" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_callback_223, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function sessionUniqueColumns CDecl Alias "sessionUniqueColumns" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr, ByVal arg3 As UByte Ptr) As c2fb_c_int
Declare Function sessionChangeMerge CDecl Alias "sessionChangeMerge" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_52 Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As UByte Ptr, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_source_record_52 Ptr Ptr) As c2fb_c_int
Declare Function sessionChangesetCheckCompat CDecl Alias "sessionChangesetCheckCompat" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr) As c2fb_c_int
Declare Function sessionChangesetExtendRecord CDecl Alias "sessionChangesetExtendRecord" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_source_record_51 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_source_record_50 Ptr) As c2fb_c_int
Declare Function sessionChangegroupOutput CDecl Alias "sessionChangegroupOutput" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
Declare Function sqlite3changegroup_new CDecl Alias "sqlite3changegroup_new" (ByVal arg0 As c2fb_source_record_57 Ptr Ptr) As c2fb_c_int
Declare Function sqlite3changegroup_config CDecl Alias "sqlite3changegroup_config" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function sqlite3changegroup_schema CDecl Alias "sqlite3changegroup_schema" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3changegroup_output CDecl Alias "sqlite3changegroup_output" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Any Ptr Ptr) As c2fb_c_int
Declare Function sqlite3changegroup_output_strm CDecl Alias "sqlite3changegroup_output_strm" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Sub sessionAppendRecordMerge CDecl Alias "sessionAppendRecordMerge" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int Ptr)
Declare Function sqlite3rebaser_create CDecl Alias "sqlite3rebaser_create" (ByVal arg0 As c2fb_source_record_58 Ptr Ptr) As c2fb_c_int
Declare Function sqlite3session_config CDecl Alias "sqlite3session_config" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Any Ptr) As c2fb_c_int
Declare Function checkChangeParams CDecl Alias "checkChangeParams" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_source_record_50 Ptr Ptr) As c2fb_c_int
Declare Function sqlite3changegroup_change_int64 CDecl Alias "sqlite3changegroup_change_int64" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3changegroup_change_null CDecl Alias "sqlite3changegroup_change_null" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3changegroup_change_double CDecl Alias "sqlite3changegroup_change_double" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Double) As c2fb_c_int
Declare Function sqlite3changegroup_change_text CDecl Alias "sqlite3changegroup_change_text" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3changegroup_change_blob CDecl Alias "sqlite3changegroup_change_blob" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const Any Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_vmprintf__ CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_errcode CDecl Alias "sqlite3_errcode" (ByVal arg0 As sqlite3 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_errmsg_ CDecl Alias "sqlite3_errmsg" (ByVal arg0 As sqlite3 Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_prepare_v2_ CDecl Alias "sqlite3_prepare_v2" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As SqliteVdbe Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_blob_ CDecl Alias "sqlite3_bind_blob" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_int64_ CDecl Alias "sqlite3_bind_int64" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_text_ CDecl Alias "sqlite3_bind_text" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_value_ CDecl Alias "sqlite3_bind_value" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_count_ CDecl Alias "sqlite3_column_count" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_step_ CDecl Alias "sqlite3_step" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_blob_ CDecl Alias "sqlite3_column_blob" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As Const Any Ptr
Declare Function c2fb_external_sqlite3_column_int_ CDecl Alias "sqlite3_column_int" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int64_ CDecl Alias "sqlite3_column_int64" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function c2fb_external_sqlite3_column_text_ CDecl Alias "sqlite3_column_text" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_column_value_ CDecl Alias "sqlite3_column_value" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As SqliteVdbeMem Ptr
Declare Function c2fb_external_sqlite3_column_bytes_ CDecl Alias "sqlite3_column_bytes" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_finalize_ CDecl Alias "sqlite3_finalize" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_blob__ CDecl Alias "sqlite3_value_blob" (ByVal arg0 As SqliteVdbeMem Ptr) As Const Any Ptr
Declare Function c2fb_external_sqlite3_value_double_ CDecl Alias "sqlite3_value_double" (ByVal arg0 As SqliteVdbeMem Ptr) As Double
Declare Function c2fb_external_sqlite3_value_int64__ CDecl Alias "sqlite3_value_int64" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_int64
Declare Function c2fb_external_sqlite3_value_text___ CDecl Alias "sqlite3_value_text" (ByVal arg0 As SqliteVdbeMem Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes__ CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_type_ CDecl Alias "sqlite3_value_type" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_preupdate_old CDecl Alias "sqlite3_preupdate_old" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_preupdate_count CDecl Alias "sqlite3_preupdate_count" (ByVal arg0 As sqlite3 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_preupdate_depth CDecl Alias "sqlite3_preupdate_depth" (ByVal arg0 As sqlite3 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_preupdate_new CDecl Alias "sqlite3_preupdate_new" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
/' SQLite uses short stream chunks in test builds to exercise refill paths. '/
#ifndef SESSIONS_STRM_CHUNK_SIZE
#ifdef SQLITE_TEST
#define SESSIONS_STRM_CHUNK_SIZE 64
#else
#define SESSIONS_STRM_CHUNK_SIZE 1024
#endif
#endif
Private Dim Shared c2fb_global_sessions_strm_chunk_size As c2fb_c_int = _
    Cast(c2fb_c_int, SESSIONS_STRM_CHUNK_SIZE)

/' The changeset module reads the same source-unit static through this accessor. '/
Function sessionStreamChunkSizeGet CDecl Alias "sessionStreamChunkSizeGet" () As c2fb_c_int
    Return c2fb_global_sessions_strm_chunk_size
End Function
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
' c2fb skipped sqlite3IsBinary: FreeBASIC body already exists
Function sessionVarintPut CDecl Alias "sessionVarintPut" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte
    Dim c2fb_temp_3 As c2fb_c_int

    If ((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (arg1)) < Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL))))))) Then
        c2fb_temp_0 = CPtr(UByte Ptr, @((*(arg0))))
        c2fb_temp_1 = Cast(UByte, Cast(UByte, (arg1)))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = (c2fb_temp_1)
        c2fb_temp_3 = Cast(c2fb_c_int, 1ULL)
    Else
        c2fb_temp_3 = sqlite3PutVarint((arg0), (arg1))
    End If
    Return Cast(UByte, (c2fb_temp_3))
End Function
Function sessionVarintLen CDecl Alias "sessionVarintLen" (ByVal arg0 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Return sqlite3VarintLen(arg0)
End Function
Function sessionVarintGet CDecl Alias "sessionVarintGet" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    If ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*(arg0))) < Cast(c2fb_c_int, Cast(UByte, Cast(c2fb_c_int, &H80ULL)))))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(((*arg1))))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_uint, (*(arg0))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = (c2fb_temp_1)
        c2fb_temp_3 = Cast(c2fb_c_int, 1ULL)
    Else
        c2fb_temp_3 = Cast(c2fb_c_int, sqlite3GetVarint32((arg0), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_int Ptr, @(((*arg1)))))))
    End If
    local0 = Cast(UByte, (c2fb_temp_3))
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_5 = Cast(c2fb_c_int, (Cast(c2fb_c_int, ((*arg1) And Cast(c2fb_c_int, &H7FFFFFFFULL)))))
    (*c2fb_temp_4) = c2fb_temp_5
    Return local0
End Function
Function sessionVarintGetSafe CDecl Alias "sessionVarintGetSafe" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0(0 To 8) As UByte
    Dim local1 As Const UByte Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Const UByte Ptr

    ' C automatic array storage
    local1 = arg0
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(UByte Ptr, (@local0(0)))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, (9ULL * SizeOf(UByte)))))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_uint64, arg1) < Cast(c2fb_uint64, Cast(c2fb_size_t, (9ULL * SizeOf(UByte)))))))) Then
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, (@local0(0)))), CPtr(Const Any Ptr, arg0), arg1))
        c2fb_temp_2 = CPtr(Const UByte Ptr, CPtr(UByte Ptr, (@local0(0))))
        local1 = c2fb_temp_2
    End If
    Return sessionVarintGet(local1, arg2)
End Function
Function sessionGetI64 CDecl Alias "sessionGetI64" (ByVal arg0 As UByte Ptr) As c2fb_int64
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_uint64
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_uint64

    local0 = (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (arg0)[Cast(c2fb_c_int, &O0ULL)]) Shl Cast(c2fb_c_int, 24ULL)))) Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0)[Cast(c2fb_c_int, 1ULL)]) Shl Cast(c2fb_c_int, 16ULL))))))) Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg0)[Cast(c2fb_c_int, 2ULL)]) Shl Cast(c2fb_c_int, 8ULL))))))) Or Cast(c2fb_c_uint, (arg0)[Cast(c2fb_c_int, 3ULL)]))))
    local1 = (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (CPtr(UByte Ptr, (arg0 + Cast(c2fb_c_int, 4ULL))))[Cast(c2fb_c_int, &O0ULL)]) Shl Cast(c2fb_c_int, 24ULL)))) Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (CPtr(UByte Ptr, (arg0 + Cast(c2fb_c_int, 4ULL))))[Cast(c2fb_c_int, 1ULL)]) Shl Cast(c2fb_c_int, 16ULL))))))) Or Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (CPtr(UByte Ptr, (arg0 + Cast(c2fb_c_int, 4ULL))))[Cast(c2fb_c_int, 2ULL)]) Shl Cast(c2fb_c_int, 8ULL))))))) Or Cast(c2fb_c_uint, (CPtr(UByte Ptr, (arg0 + Cast(c2fb_c_int, 4ULL))))[Cast(c2fb_c_int, 3ULL)]))))
    c2fb_temp_0 = Cast(c2fb_uint64, Cast(c2fb_uint64, ((Cast(c2fb_uint64, (local0 Shl Cast(c2fb_c_int, 32ULL)))) + Cast(c2fb_uint64, local1))))
    local0 = c2fb_temp_0
    Return Cast(c2fb_int64, local0)
End Function
Sub sessionPutI64 CDecl Alias "sessionPutI64" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_int64)
' c2fb source-path: ext/session/sqlite3session.c
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
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, 56ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, 48ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 2ULL)]))
    c2fb_temp_5 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, 40ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 3ULL)]))
    c2fb_temp_7 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, 32ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_6) = c2fb_temp_7
    c2fb_temp_8 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 4ULL)]))
    c2fb_temp_9 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, 24ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_8) = c2fb_temp_9
    c2fb_temp_10 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 5ULL)]))
    c2fb_temp_11 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, 16ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 6ULL)]))
    c2fb_temp_13 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_12) = c2fb_temp_13
    c2fb_temp_14 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 7ULL)]))
    c2fb_temp_15 = Cast(UByte, Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, &O0ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_14) = c2fb_temp_15
End Sub
Sub sessionPutDouble CDecl Alias "sessionPutDouble" (ByVal arg0 As UByte Ptr, ByVal arg1 As Double)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_uint64
    Dim c2fb_temp_0 As Any Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(c2fb_uint64 Ptr, @(local0))), CPtr(Const Any Ptr, CPtr(Double Ptr, @(arg1))), Cast(c2fb_c_int, 8ULL)))
    sessionPutI64(arg0, local0)
End Sub
Function sessionSerializeValue CDecl Alias "sessionSerializeValue" (ByVal arg0 As UByte Ptr, ByVal arg1 As SqliteVdbeMem Ptr, ByVal arg2 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As UByte
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local2 As c2fb_uint64
    Dim local3 As Double
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local4 As UByte Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As UByte Ptr
    Dim c2fb_temp_13 As UByte
    Dim c2fb_temp_14 As c2fb_int64 Ptr
    Dim c2fb_temp_15 As c2fb_int64

    ' C automatic storage declaration
    If arg1 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_type_(arg1))
        local1 = c2fb_temp_0
        If arg0 Then
            c2fb_temp_1 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
            c2fb_temp_2 = Cast(UByte, local1)
            (*c2fb_temp_1) = c2fb_temp_2
        End If
        Select Case local1
            Case Cast(c2fb_c_int, 5ULL)
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_3
            Case Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, 2ULL)
                If arg0 Then
                    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 1ULL))))) Then
                        local2 = Cast(c2fb_uint64, c2fb_external_sqlite3_value_int64__(arg1))
                        sessionPutI64(CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)])), local2)
                    Else
                        local3 = c2fb_external_sqlite3_value_double_(arg1)
                        sessionPutDouble(CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)])), local3)
                    End If
                End If
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 9ULL))
                local0 = c2fb_temp_4
            Case Else
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C automatic storage declaration
                ' C unused-parameter annotation
                If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, 3ULL))))) Then
                    c2fb_temp_5 = CPtr(UByte Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text___(arg1)))
                    local4 = c2fb_temp_5
                Else
                    c2fb_temp_6 = CPtr(UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob__(arg1)))
                    local4 = c2fb_temp_6
                End If
                c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_bytes__(arg1))
                local5 = c2fb_temp_7
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
                    Return Cast(c2fb_c_int, 7ULL)
                End If
                c2fb_temp_8 = Cast(c2fb_c_int, sessionVarintLen(local5))
                local6 = c2fb_temp_8
                If arg0 Then
                    sessionVarintPut(CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)])), local5)
                    If (-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))]))), CPtr(Const Any Ptr, local4), local5))
                    End If
                End If
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + local6)) + local5)))
                local0 = c2fb_temp_10
                Goto c2fb_flow_0
        End Select
        c2fb_flow_0:
    Else
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_11
        If arg0 Then
            c2fb_temp_12 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
            c2fb_temp_13 = Cast(UByte, Cast(c2fb_c_int, 0))
            (*c2fb_temp_12) = c2fb_temp_13
        End If
    End If
    If arg2 Then
        c2fb_temp_14 = CPtr(c2fb_int64 Ptr, @((*arg2)))
        c2fb_temp_15 = Cast(c2fb_int64, Cast(c2fb_int64, ((*c2fb_temp_14) + Cast(c2fb_int64, local0))))
        (*c2fb_temp_14) = c2fb_temp_15
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped sessionMalloc64: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionMalloc64: assignment parser stopped at byte 9 (pSession->nMalloc += sqlite3_msize(pRet)): ->nMalloc += sqlite3_msize(pRet)
' c2fb skipped sessionFree: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionFree: assignment parser stopped at byte 9 (pSession->nMalloc -= sqlite3_msize(pFree)): ->nMalloc -= sqlite3_msize(pFree)
Function sessionHashAppendI64 CDecl Alias "sessionHashAppendI64" (ByVal arg0 As c2fb_c_uint, ByVal arg1 As c2fb_int64) As c2fb_c_uint
' c2fb source-path: ext/session/sqlite3session.c
    Dim c2fb_temp_0 As c2fb_c_uint

    c2fb_temp_0 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, ((arg0) Shl Cast(c2fb_c_int, 3ULL)))) Xor (arg0))) Xor Cast(c2fb_c_uint, (Cast(c2fb_int64, (arg1 And Cast(c2fb_int64, Cast(c2fb_c_uint, &HFFFFFFFFULL)))))))))
    arg0 = c2fb_temp_0
    Return Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, ((arg0) Shl Cast(c2fb_c_int, 3ULL)))) Xor (arg0))) Xor Cast(c2fb_c_uint, (Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 Shr Cast(c2fb_c_int, 32ULL)))) And Cast(c2fb_int64, Cast(c2fb_c_uint, &HFFFFFFFFULL))))))))
End Function
Function sessionHashAppendBlob CDecl Alias "sessionHashAppendBlob" (ByVal arg0 As c2fb_c_uint, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const UByte Ptr) As c2fb_c_uint
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_uint

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1))))
        c2fb_temp_2 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, ((arg0) Shl Cast(c2fb_c_int, 3ULL)))) Xor (arg0))) Xor Cast(c2fb_c_uint, (arg2[local0])))))
        arg0 = c2fb_temp_2
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return arg0
End Function
Function sessionHashAppendType CDecl Alias "sessionHashAppendType" (ByVal arg0 As c2fb_c_uint, ByVal arg1 As c2fb_c_int) As c2fb_c_uint
' c2fb source-path: ext/session/sqlite3session.c
    Return Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, ((arg0) Shl Cast(c2fb_c_int, 3ULL)))) Xor (arg0))) Xor Cast(c2fb_c_uint, (arg1))))
End Function
' c2fb skipped sessionPreupdateHash: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionPreupdateHash: assignment parser stopped at byte 14 (rc = pSession->hook.xNew(pSession->hook.pCtx, iIdx, &pVal)): ->hook.xNew(pSession->hook.pCtx, iIdx, &pVal)
Function sessionSerialLen CDecl Alias "sessionSerialLen" (ByVal arg0 As Const UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, (*arg0))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 9ULL)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, (Cast(c2fb_c_int, (sessionVarintGet(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))), CPtr(c2fb_c_int Ptr, @(local1))) + Cast(c2fb_c_int, 1ULL))) + local1))
    End If
    Return Cast(c2fb_c_int, 1ULL)
End Function
Function sessionChangeHash CDecl Alias "sessionChangeHash" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int) As c2fb_c_uint
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_c_int
    Dim local2 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As UByte Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As c2fb_c_uint
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As UByte Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = arg2
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < arg0->nCol))))
        local3 = arg0->abPK[local1]
        If (-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Goto c2fb_flow_1
        End If
        If local3 Then
            c2fb_temp_2 = local2
            local2 = (c2fb_temp_2 + 1)
            local4 = (*c2fb_temp_2)
            ' C unused-parameter annotation
            c2fb_temp_3 = Cast(c2fb_c_uint, sessionHashAppendType(local0, local4))
            local0 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                c2fb_temp_4 = Cast(c2fb_c_uint, sessionHashAppendI64(local0, sessionGetI64(local2)))
                local0 = c2fb_temp_4
                c2fb_temp_5 = CPtr(UByte Ptr, (local2 + Cast(c2fb_c_int, 8ULL)))
                local2 = c2fb_temp_5
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                    ' C automatic storage declaration
                    c2fb_temp_6 = CPtr(UByte Ptr, (local2 + sessionVarintGet(CPtr(Const UByte Ptr, local2), CPtr(c2fb_c_int Ptr, @(local5)))))
                    local2 = c2fb_temp_6
                    c2fb_temp_7 = Cast(c2fb_c_uint, sessionHashAppendBlob(local0, local5, CPtr(Const UByte Ptr, local2)))
                    local0 = c2fb_temp_7
                    c2fb_temp_8 = CPtr(UByte Ptr, (local2 + local5))
                    local2 = c2fb_temp_8
                End If
            End If
        Else
            c2fb_temp_9 = CPtr(UByte Ptr, (local2 + sessionSerialLen(CPtr(Const UByte Ptr, local2))))
            local2 = c2fb_temp_9
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return (Cast(c2fb_c_uint, (local0 Mod Cast(c2fb_c_uint, arg3))))
End Function
Function sessionChangeEqual CDecl Alias "sessionChangeEqual" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte Ptr

    local0 = arg2
    local1 = arg4
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local2 < arg0->nCol))))
        If arg0->abPK[local2] Then
            local3 = sessionSerialLen(CPtr(Const UByte Ptr, local0))
            local4 = sessionSerialLen(CPtr(Const UByte Ptr, local1))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 <> local4)))) <> 0) OrElse (c2fb_crt_memcmp(CPtr(Const Any Ptr, local0), CPtr(Const Any Ptr, local1), local3) <> 0))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            c2fb_temp_2 = CPtr(UByte Ptr, (local0 + local3))
            local0 = c2fb_temp_2
            c2fb_temp_3 = CPtr(UByte Ptr, (local1 + local4))
            local1 = c2fb_temp_3
        Else
            If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_4 = CPtr(UByte Ptr, (local0 + sessionSerialLen(CPtr(Const UByte Ptr, local0))))
                local0 = c2fb_temp_4
            End If
            If (-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_5 = CPtr(UByte Ptr, (local1 + sessionSerialLen(CPtr(Const UByte Ptr, local1))))
                local1 = c2fb_temp_5
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, 1ULL)
End Function
Private Sub sessionMergeRecord CDecl Alias "sessionMergeRecord" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As UByte Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim local1 As UByte Ptr
    Dim local2 As UByte Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As UByte Ptr Ptr
    Dim c2fb_temp_9 As UByte Ptr

    local0 = arg2
    local1 = arg3
    local2 = (*arg0)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local3 < arg1))))
        local4 = sessionSerialLen(CPtr(Const UByte Ptr, local0))
        local5 = sessionSerialLen(CPtr(Const UByte Ptr, local1))
        If (*local1) Then
            c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local2), CPtr(Const Any Ptr, local1), local5))
            c2fb_temp_3 = CPtr(UByte Ptr, (local2 + local5))
            local2 = c2fb_temp_3
        Else
            c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local2), CPtr(Const Any Ptr, local0), local4))
            c2fb_temp_5 = CPtr(UByte Ptr, (local2 + local4))
            local2 = c2fb_temp_5
        End If
        c2fb_temp_6 = CPtr(UByte Ptr, (local0 + local4))
        local0 = c2fb_temp_6
        c2fb_temp_7 = CPtr(UByte Ptr, (local1 + local5))
        local1 = c2fb_temp_7
    c2fb_flow_1:
        c2fb_temp_1 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_8 = CPtr(UByte Ptr Ptr, @((*arg0)))
    c2fb_temp_9 = local2
    (*c2fb_temp_8) = c2fb_temp_9
End Sub
Private Function sessionMergeValue CDecl Alias "sessionMergeValue" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As c2fb_c_int Ptr) As UByte Ptr
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim local1 As UByte Ptr
    Dim local2 As UByte Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte Ptr Ptr
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As UByte Ptr Ptr
    Dim c2fb_temp_10 As UByte Ptr

    local0 = (*arg0)
    local1 = (*arg1)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If local1 Then
        local4 = sessionSerialLen(CPtr(Const UByte Ptr, local1))
        If (*local1) Then
            c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_1 = Cast(c2fb_c_int, local4)
            (*c2fb_temp_0) = c2fb_temp_1
            c2fb_temp_2 = local1
            local2 = c2fb_temp_2
        End If
        c2fb_temp_3 = CPtr(UByte Ptr Ptr, @((*arg1)))
        c2fb_temp_4 = CPtr(UByte Ptr, @(local1[local4]))
        (*c2fb_temp_3) = c2fb_temp_4
    End If
    c2fb_temp_5 = Cast(c2fb_c_int, sessionSerialLen(CPtr(Const UByte Ptr, local0)))
    local3 = c2fb_temp_5
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_7 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_6) = c2fb_temp_7
        c2fb_temp_8 = local0
        local2 = c2fb_temp_8
    End If
    c2fb_temp_9 = CPtr(UByte Ptr Ptr, @((*arg0)))
    c2fb_temp_10 = CPtr(UByte Ptr, @(local0[local3]))
    (*c2fb_temp_9) = c2fb_temp_10
    Return local2
End Function
Private Function sessionMergeUpdate CDecl Alias "sessionMergeUpdate" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As c2fb_source_record_51 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As UByte Ptr, ByVal arg5 As UByte Ptr, ByVal arg6 As UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim local1 As UByte Ptr
    Dim local2 As UByte Ptr
    Dim local3 As UByte Ptr
    Dim local4 As UByte Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As UByte Ptr
    Dim local9 As c2fb_c_int
    Dim local10 As UByte Ptr
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As UByte
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As UByte Ptr
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As UByte Ptr
    Dim local13 As c2fb_c_int
    Dim local14 As UByte Ptr
    Dim c2fb_temp_16 As UByte Ptr
    Dim c2fb_temp_17 As UByte Ptr
    Dim c2fb_temp_18 As UByte Ptr
    Dim c2fb_temp_19 As UByte Ptr
    Dim c2fb_temp_20 As UByte
    Dim c2fb_temp_21 As Any Ptr
    Dim c2fb_temp_22 As UByte Ptr
    Dim c2fb_temp_23 As UByte Ptr Ptr
    Dim c2fb_temp_24 As UByte Ptr

    local0 = arg3
    local1 = arg4
    local2 = arg5
    local3 = arg6
    local4 = (*arg0)
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
        local6 = Cast(c2fb_c_int, &O0ULL)
        ' C unused-parameter annotation
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local5 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local5 < arg1->nCol))))
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            ' C automatic storage declaration
            c2fb_temp_2 = CPtr(UByte Ptr, sessionMergeValue(CPtr(UByte Ptr Ptr, @(local0)), CPtr(UByte Ptr Ptr, @(local1)), CPtr(c2fb_c_int Ptr, @(local7))))
            local8 = c2fb_temp_2
            c2fb_temp_3 = CPtr(UByte Ptr, sessionMergeValue(CPtr(UByte Ptr Ptr, @(local2)), CPtr(UByte Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local9))))
            local10 = c2fb_temp_3
            If (-Cast(c2fb_c_int, (((arg1->abPK[local5] <> 0) OrElse ((-Cast(c2fb_c_int, ((local7 <> local9)))) <> 0) OrElse (c2fb_crt_memcmp(CPtr(Const Any Ptr, local8), CPtr(Const Any Ptr, local10), local9) <> 0))))) Then
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->abPK[local5]) = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local6 = c2fb_temp_4
                End If
                c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local4), CPtr(Const Any Ptr, local8), local7))
                c2fb_temp_6 = CPtr(UByte Ptr, (local4 + local7))
                local4 = c2fb_temp_6
            Else
                c2fb_temp_7 = local4
                local4 = (c2fb_temp_7 + 1)
                c2fb_temp_8 = CPtr(UByte Ptr, @((*(c2fb_temp_7))))
                c2fb_temp_9 = Cast(UByte, Cast(c2fb_c_int, 0))
                (*c2fb_temp_8) = c2fb_temp_9
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, (local6 = 0))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    End If
    c2fb_temp_10 = arg3
    local0 = c2fb_temp_10
    c2fb_temp_11 = arg4
    local1 = c2fb_temp_11
    c2fb_temp_12 = arg5
    local2 = c2fb_temp_12
    c2fb_temp_13 = arg6
    local3 = c2fb_temp_13
    c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local5 = c2fb_temp_14
    While (-Cast(c2fb_c_int, ((local5 < arg1->nCol))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_16 = CPtr(UByte Ptr, sessionMergeValue(CPtr(UByte Ptr Ptr, @(local0)), CPtr(UByte Ptr Ptr, @(local1)), CPtr(c2fb_c_int Ptr, @(local11))))
        local12 = c2fb_temp_16
        c2fb_temp_17 = CPtr(UByte Ptr, sessionMergeValue(CPtr(UByte Ptr Ptr, @(local2)), CPtr(UByte Ptr Ptr, @(local3)), CPtr(c2fb_c_int Ptr, @(local13))))
        local14 = c2fb_temp_17
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg1->abPK[local5] <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local11 = local13)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, local12), CPtr(Const Any Ptr, local14), local13))))) <> 0)))))) <> 0)))))) <> 0))))) Then
            c2fb_temp_18 = local4
            local4 = (c2fb_temp_18 + 1)
            c2fb_temp_19 = CPtr(UByte Ptr, @((*(c2fb_temp_18))))
            c2fb_temp_20 = Cast(UByte, Cast(c2fb_c_int, 0))
            (*c2fb_temp_19) = c2fb_temp_20
        Else
            c2fb_temp_21 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local4), CPtr(Const Any Ptr, local14), local13))
            c2fb_temp_22 = CPtr(UByte Ptr, (local4 + local13))
            local4 = c2fb_temp_22
        End If
    c2fb_flow_3:
        c2fb_temp_15 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 + 1)))
    Wend
    c2fb_flow_2:
    c2fb_temp_23 = CPtr(UByte Ptr Ptr, @((*arg0)))
    c2fb_temp_24 = local4
    (*c2fb_temp_23) = c2fb_temp_24
    Return Cast(c2fb_c_int, 1ULL)
End Function
' c2fb skipped sessionPreupdateEqual: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionPreupdateEqual: assignment parser stopped at byte 14 (rc = pSession->hook.xNew(pSession->hook.pCtx, iIdx, &pVal)): ->hook.xNew(pSession->hook.pCtx, iIdx, &pVal)
' c2fb skipped sessionGrowHash: requires unconverted C function sessionMalloc64
' c2fb skipped sessionTableInfo: requires unconverted C function sessionMalloc64
' c2fb skipped sessionInitTable: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionInitTable: assignment parser stopped at byte 188 (rc = sessionTableInfo(pSession, db, zDb,         pTab->zName, &pTab->nCol, &pTab->nTotalCol, 0, &pTab->azCol,         &p): ->bImplicitPK) ? &pTab->bRowid : 0)     )
' c2fb skipped sessionReinitTable: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionReinitTable: assignment parser stopped at byte 9 (pSession->rc = sessionTableInfo(pSession, pSession->db, pSession->zDb,       pTab->zName, &nCol, &nTotalCol, 0, &azCol, ): ->rc = sessionTableInfo(pSession, pSession->db, pSession->zDb,       pTab->zName
' c2fb skipped sessionUpdateOneChange: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionUpdateOneChange: assignment parser stopped at byte 9 (pSession->nMaxChangesetSize += nIncr): ->nMaxChangesetSize += nIncr
Function sessionBufferGrow CDecl Alias "sessionBufferGrow" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_int64
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_int64
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As UByte Ptr Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int

    local0 = Cast(c2fb_int64, (Cast(c2fb_int64, arg0->nBuf) + arg1))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((*arg2) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 > Cast(c2fb_int64, arg0->nAlloc))))) <> 0))))) Then
        ' C automatic storage declaration
        local2 = IIf(arg0->nAlloc, arg0->nAlloc, Cast(c2fb_c_int, 128ULL))
        Do
            c2fb_temp_0 = Cast(c2fb_int64, Cast(c2fb_int64, (local2 * Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)))))
            local2 = c2fb_temp_0
        c2fb_flow_1:
        Loop While (-Cast(c2fb_c_int, ((local2 < local0))))
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((local2 > Cast(c2fb_int64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H7FFFFF00ULL) - Cast(c2fb_c_int, 1ULL))))))))) Then
            c2fb_temp_1 = Cast(c2fb_int64, (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H7FFFFF00ULL) - Cast(c2fb_c_int, 1ULL)))))
            local2 = c2fb_temp_1
            If (-Cast(c2fb_c_int, ((local2 < local0)))) Then
                c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_2) = c2fb_temp_3
                Return Cast(c2fb_c_int, 1ULL)
            End If
        End If
        c2fb_temp_4 = CPtr(UByte Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->aBuf), local2)))
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = local1)))) Then
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_5) = c2fb_temp_6
        Else
            c2fb_temp_7 = CPtr(UByte Ptr Ptr, @(arg0->aBuf))
            c2fb_temp_8 = local1
            (*c2fb_temp_7) = c2fb_temp_8
            c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @(arg0->nAlloc))
            c2fb_temp_10 = Cast(c2fb_c_int, local2)
            (*c2fb_temp_9) = c2fb_temp_10
        End If
    End If
    Return ((-Cast(c2fb_c_int, (((*arg2) <> Cast(c2fb_c_int, &O0ULL))))))
End Function
Sub sessionAppendStr CDecl Alias "sessionAppendStr" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte

    local0 = sqlite3Strlen30(arg1)
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionBufferGrow(arg0, Cast(c2fb_int64, (Cast(c2fb_int64, local0) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))), arg2))))) Then
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf]))), CPtr(Const Any Ptr, arg1), local0))
        c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @(arg0->nBuf))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_1) + local0)))
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf]))
        c2fb_temp_4 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
        (*c2fb_temp_3) = c2fb_temp_4
    End If
End Sub
Sub sessionAppendPrintf CDecl Alias "sessionAppendPrintf" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Const ZString Ptr, ...)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As ZString Ptr
    Dim local1 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((*arg1) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        Cva_Start(local1, arg2)
        c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf__(arg2, local1))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg1)))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_1) = c2fb_temp_2
        Else
            sessionAppendStr(arg0, CPtr(Const ZString Ptr, local0), arg1)
        End If
        Cva_End(local1)
        sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Function sessionPrepareDfltStmt CDecl Alias "sessionPrepareDfltStmt" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_51 Ptr, ByVal arg2 As SqliteVdbe Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_source_record_50
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As SqliteVdbe Ptr Ptr
    Dim c2fb_temp_1 As SqliteVdbe Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = StrPtr(!" ")
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(SqliteVdbe Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(SqliteVdbe Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    sessionAppendPrintf(CPtr(c2fb_source_record_50 Ptr, @(local0)), CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"SELECT"))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local3 < arg1->nCol))))
        local4 = IIf(arg1->azDflt[local3], arg1->azDflt[local3], StrPtr(!"NULL"))
        sessionAppendPrintf(CPtr(c2fb_source_record_50 Ptr, @(local0)), CPtr(c2fb_c_int Ptr, @(local1)), StrPtr(!"%s%s"), local2, local4)
        c2fb_temp_4 = StrPtr(!", ")
        local2 = c2fb_temp_4
    c2fb_flow_1:
        c2fb_temp_3 = local3
        local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_prepare_v2_(arg0, CPtr(Const ZString Ptr, local0.aBuf), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), arg2, Cast(c2fb_c_int, &O0ULL)))
        local1 = c2fb_temp_5
    End If
    sqlite3_free(CPtr(Any Ptr, local0.aBuf))
    Return local1
End Function
Sub sessionFinalizeStmt CDecl Alias "sessionFinalizeStmt" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = c2fb_external_sqlite3_finalize_(arg0)
    If (-Cast(c2fb_c_int, (((*arg1) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
        c2fb_temp_1 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_0) = c2fb_temp_1
    End If
End Sub
' c2fb skipped sessionUpdateChanges: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionUpdateChanges: expression parser stopped at byte 9 in (pSession->rc): ->rc
' c2fb skipped sessionStat1Old: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionStat1Old: expression parser stopped at byte 2 in (p->hook.xOld(p->hook.pCtx, iCol, &pVal)): ->hook.xOld(p->hook.pCtx, iCol, &pVal)
' c2fb skipped sessionStat1New: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionStat1New: expression parser stopped at byte 2 in (p->hook.xNew(p->hook.pCtx, iCol, &pVal)): ->hook.xNew(p->hook.pCtx, iCol, &pVal)
' c2fb skipped sessionStat1Count: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionStat1Count: expression parser stopped at byte 2 in (p->hook.xCount(p->hook.pCtx)): ->hook.xCount(p->hook.pCtx)
' c2fb skipped sessionStat1Depth: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionStat1Depth: expression parser stopped at byte 2 in (p->hook.xDepth(p->hook.pCtx)): ->hook.xDepth(p->hook.pCtx)
' c2fb skipped sessionUpdateMaxSize: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionUpdateMaxSize: assignment parser stopped at byte 9 (pSession->hook.xNew(pSession->hook.pCtx, pTab->aiIdx[ii], &p)): ->hook.xNew(pSession->hook.pCtx, pTab->aiIdx[ii], &p)
' c2fb skipped sessionPreupdateOneChange: outside the supported subset
' c2fb body diagnostic [incomplete-local-record-layout]: sessionPreupdateOneChange: C record has no complete FreeBASIC storage layout: SessionStat1Ctx
' c2fb skipped sessionFindTable: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionFindTable: assignment parser stopped at byte 14 (pRet=pSession->pTable): ->pTable
' c2fb skipped xPreUpdate: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: xPreUpdate: assignment parser stopped at byte 18 (pSession=pSession->pNext): ->pNext
Function sessionPreupdateOld CDecl Alias "sessionPreupdateOld" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Return c2fb_external_sqlite3_preupdate_old(CPtr(sqlite3 Ptr, arg0), arg1, arg2)
End Function
Function sessionPreupdateNew CDecl Alias "sessionPreupdateNew" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Return c2fb_external_sqlite3_preupdate_new(CPtr(sqlite3 Ptr, arg0), arg1, arg2)
End Function
Function sessionPreupdateCount CDecl Alias "sessionPreupdateCount" (ByVal arg0 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Return c2fb_external_sqlite3_preupdate_count(CPtr(sqlite3 Ptr, arg0))
End Function
Function sessionPreupdateDepth CDecl Alias "sessionPreupdateDepth" (ByVal arg0 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Return c2fb_external_sqlite3_preupdate_depth(CPtr(sqlite3 Ptr, arg0))
End Function
' c2fb skipped sessionPreupdateHooks: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionPreupdateHooks: assignment parser stopped at byte 9 (pSession->hook.pCtx = (void*)pSession->db): ->hook.pCtx = (void*)pSession->db
Function sessionDiffOld CDecl Alias "sessionDiffOld" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_source_record_53 Ptr
    Dim c2fb_temp_0 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_1 As SqliteVdbeMem Ptr

    local0 = CPtr(c2fb_source_record_53 Ptr, arg0)
    c2fb_temp_0 = CPtr(SqliteVdbeMem Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(SqliteVdbeMem Ptr, c2fb_external_sqlite3_column_value_(local0->pStmt, Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1 + local0->nOldOff)) + local0->bRowid))))
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sessionDiffNew CDecl Alias "sessionDiffNew" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_source_record_53 Ptr
    Dim c2fb_temp_0 As SqliteVdbeMem Ptr Ptr
    Dim c2fb_temp_1 As SqliteVdbeMem Ptr

    local0 = CPtr(c2fb_source_record_53 Ptr, arg0)
    c2fb_temp_0 = CPtr(SqliteVdbeMem Ptr Ptr, @((*arg2)))
    c2fb_temp_1 = CPtr(SqliteVdbeMem Ptr, c2fb_external_sqlite3_column_value_(local0->pStmt, Cast(c2fb_c_int, (arg1 + local0->bRowid))))
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sessionDiffCount CDecl Alias "sessionDiffCount" (ByVal arg0 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_source_record_53 Ptr

    local0 = CPtr(c2fb_source_record_53 Ptr, arg0)
    Return Cast(c2fb_c_int, ((IIf(local0->nOldOff, local0->nOldOff, c2fb_external_sqlite3_column_count_(local0->pStmt))) - local0->bRowid))
End Function
Function sessionDiffDepth CDecl Alias "sessionDiffDepth" (ByVal arg0 As Any Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped sessionDiffHooks: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionDiffHooks: assignment parser stopped at byte 9 (pSession->hook.pCtx = (void*)pDiffCtx): ->hook.pCtx = (void*)pDiffCtx
Function sessionExprComparePK CDecl Alias "sessionExprComparePK" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As UByte Ptr) As ZString Ptr
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr

    ' C automatic storage declaration
    local1 = StrPtr(!"")
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0))))
        If arg5[local0] Then
            c2fb_temp_2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%z%s\034%w\034.\034%w\034.\034%w\034=\034%w\034.\034%w\034.\034%w\034"), local2, local1, arg1, arg3, arg4[local0], arg2, arg3, arg4[local0]))
            local2 = c2fb_temp_2
            c2fb_temp_3 = StrPtr(!" AND ")
            local1 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local2
End Function
Function sessionExprCompareOther CDecl Alias "sessionExprCompareOther" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As UByte Ptr) As ZString Ptr
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr

    ' C automatic storage declaration
    local1 = StrPtr(!"")
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0))))
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg5[local0]) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
            local3 = c2fb_temp_2
            c2fb_temp_3 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%z%s\034%w\034.\034%w\034.\034%w\034 IS NOT \034%w\034.\034%w\034.\034%w\034"), local2, local1, arg1, arg3, arg4[local0], arg2, arg3, arg4[local0]))
            local2 = c2fb_temp_3
            c2fb_temp_4 = StrPtr(!" OR ")
            local1 = c2fb_temp_4
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_0
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C unused-parameter annotation
        c2fb_temp_5 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"0")))
        local2 = c2fb_temp_5
    End If
    Return local2
End Function
Function sessionSelectFindNew CDecl Alias "sessionSelectFindNew" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr) As ZString Ptr
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As Const ZString Ptr
    Dim local1 As ZString Ptr

    local0 = (IIf(arg2, StrPtr(!"_rowid_, *"), StrPtr(!"*")))
    local1 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT %s FROM \034%w\034.\034%w\034 WHERE NOT EXISTS (  SELECT 1 FROM \034%w\034.\034%w\034 WHERE %s)"), local0, arg0, arg3, arg1, arg3, arg4))
    Return local1
End Function
' c2fb skipped sessionDiffFindNew: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionDiffFindNew: assignment parser stopped at byte 33 (rc = sqlite3_prepare_v2(pSession->db, zStmt, -1, &pStmt, 0)): ->db, zStmt, -1, &pStmt, 0)
Function sessionAllCols CDecl Alias "sessionAllCols" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_source_record_51 Ptr) As ZString Ptr
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg1->nCol))))
        c2fb_temp_2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%z%s\034%w\034.\034%w\034.\034%w\034"), local1, (IIf(local1, StrPtr(!", "), StrPtr(!""))), arg0, arg1->zName, arg1->azCol[local0]))
        local1 = c2fb_temp_2
        If (-Cast(c2fb_c_int, (local1 = 0))) Then
            Goto c2fb_flow_0
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function
' c2fb skipped sessionDiffFindModified: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionDiffFindModified: expression parser stopped at byte 51 in (sessionExprCompareOther(pTab->nCol,       pSession->zDb, zFrom, pTab->zName, pTab->azCol, pTab->abPK   )): ->zDb, zFrom, pTab->zName, pTab->azCol, pTab->abPK   )
' c2fb skipped sqlite3session_diff: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3session_diff: expression parser stopped at byte 9 in (pSession->zDb): ->zDb
' c2fb skipped sqlite3session_create: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3session_create: assignment parser stopped at byte 66 (pNew = (sqlite3_session *)sqlite3_malloc64(sizeof(sqlite3_session) + nDb + 1)): ) + nDb + 1)
' c2fb skipped sessionDeleteTable: requires unconverted C function sessionFree
' c2fb skipped sqlite3session_delete: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3session_delete: expression parser stopped at byte 9 in (pSession->db): ->db
' c2fb skipped sqlite3session_table_filter: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3session_table_filter: assignment parser stopped at byte 9 (pSession->bAutoAttach = 1): ->bAutoAttach = 1
' c2fb skipped sqlite3session_attach: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3session_attach: assignment parser stopped at byte 46 (sqlite3_mutex_enter(sqlite3_db_mutex(pSession->db))): ->db))
Sub sessionAppendValue CDecl Alias "sessionAppendValue" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As SqliteVdbeMem Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = (*arg2)
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = Cast(c2fb_c_int, sessionSerializeValue(Cast(c2fb_c_int, &O0ULL), arg1, CPtr(c2fb_int64 Ptr, @(local1))))
        local0 = c2fb_temp_0
        sessionBufferGrow(arg0, local1, CPtr(c2fb_c_int Ptr, @(local0)))
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, sessionSerializeValue(CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf])), arg1, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_1
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(arg0->nBuf))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_2)) + local1)))
            (*c2fb_temp_2) = c2fb_temp_3
        Else
            c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_5 = Cast(c2fb_c_int, local0)
            (*c2fb_temp_4) = c2fb_temp_5
        End If
    End If
End Sub
Sub sessionAppendByte CDecl Alias "sessionAppendByte" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As UByte, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionBufferGrow(arg0, Cast(c2fb_c_int, 1ULL), arg2))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->nBuf))
        c2fb_temp_1 = (*c2fb_temp_0)
        (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        c2fb_temp_2 = CPtr(UByte Ptr, @(arg0->aBuf[c2fb_temp_1]))
        c2fb_temp_3 = Cast(UByte, arg1)
        (*c2fb_temp_2) = c2fb_temp_3
    End If
End Sub
Sub sessionAppendVarint CDecl Alias "sessionAppendVarint" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionBufferGrow(arg0, Cast(c2fb_c_int, 9ULL), arg2))))) Then
        c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->nBuf))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_0) + sessionVarintPut(CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf])), arg1))))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
End Sub
Sub sessionAppendBlob CDecl Alias "sessionAppendBlob" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As Const UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionBufferGrow(arg0, arg2, arg3))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf]))), CPtr(Const Any Ptr, arg1), arg2))
        c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @(arg0->nBuf))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_1) + arg2)))
        (*c2fb_temp_1) = c2fb_temp_2
    End If
End Sub
Sub sessionAppendInteger CDecl Alias "sessionAppendInteger" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0(0 To 23) As Byte
    Dim c2fb_temp_0 As ZString Ptr

    ' C automatic array storage
    c2fb_temp_0 = CPtr(ZString Ptr, sqlite3_snprintf(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (24ULL * SizeOf(Byte)))) - Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL)))), CPtr(ZString Ptr, CPtr(Byte Ptr, (@local0(0)))), StrPtr(!"%d"), arg1))
    sessionAppendStr(arg0, CPtr(Const ZString Ptr, CPtr(Byte Ptr, (@local0(0)))), arg2)
End Sub
Sub sessionAppendIdent CDecl Alias "sessionAppendIdent" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As Const ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Byte Ptr
    Dim c2fb_temp_2 As Byte
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Byte Ptr
    Dim c2fb_temp_5 As Byte
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As Byte Ptr
    Dim c2fb_temp_9 As Byte
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As Byte Ptr
    Dim c2fb_temp_12 As Byte
    Dim c2fb_temp_13 As c2fb_c_int Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As UByte Ptr
    Dim c2fb_temp_16 As UByte

    local0 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (sqlite3Strlen30(arg1) * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 2ULL)))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionBufferGrow(arg0, local0, arg2))))) Then
        local1 = CPtr(ZString Ptr, CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf])))
        local2 = arg1
        c2fb_temp_0 = local1
        local1 = (c2fb_temp_0 + 1)
        c2fb_temp_1 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_0))))
        c2fb_temp_2 = Cast(Byte, Cast(c2fb_c_int, 34))
        (*c2fb_temp_1) = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            While (*CPtr(Const Byte Ptr, local2))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, local2))) = Cast(c2fb_c_int, 34))))) Then
                    c2fb_temp_3 = local1
                    local1 = (c2fb_temp_3 + 1)
                    c2fb_temp_4 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_3))))
                    c2fb_temp_5 = Cast(Byte, Cast(c2fb_c_int, 34))
                    (*c2fb_temp_4) = c2fb_temp_5
                End If
                c2fb_temp_6 = local1
                local1 = (c2fb_temp_6 + 1)
                c2fb_temp_8 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_6))))
                c2fb_temp_7 = local2
                local2 = (c2fb_temp_7 + 1)
                c2fb_temp_9 = Cast(Byte, (*CPtr(Const Byte Ptr, (c2fb_temp_7))))
                (*c2fb_temp_8) = c2fb_temp_9
            c2fb_flow_1:
            Wend
            c2fb_flow_0:
        End If
        c2fb_temp_10 = local1
        local1 = (c2fb_temp_10 + 1)
        c2fb_temp_11 = CPtr(Byte Ptr, @((*CPtr(Byte Ptr, c2fb_temp_10))))
        c2fb_temp_12 = Cast(Byte, Cast(c2fb_c_int, 34))
        (*c2fb_temp_11) = c2fb_temp_12
        c2fb_temp_13 = CPtr(c2fb_c_int Ptr, @(arg0->nBuf))
        c2fb_temp_14 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(UByte Ptr, CPtr(UByte Ptr, local1)) - CPtr(UByte Ptr, arg0->aBuf)))))
        (*c2fb_temp_13) = c2fb_temp_14
        c2fb_temp_15 = CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf]))
        c2fb_temp_16 = Cast(UByte, Cast(c2fb_c_int, &H00ULL))
        (*c2fb_temp_15) = c2fb_temp_16
    End If
End Sub
Sub sessionAppendCol CDecl Alias "sessionAppendCol" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As SqliteVdbe Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1(0 To 7) As UByte
    Dim local2 As c2fb_int64
    Dim local3 As Double
    Dim local4 As UByte Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((*arg3) = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = sqlite3_column_type(CPtr(Any Ptr, arg1), arg2)
        sessionAppendByte(arg0, Cast(UByte, local0), arg3)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
            ' C automatic array storage
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 1ULL))))) Then
                local2 = c2fb_external_sqlite3_column_int64_(arg1, arg2)
                sessionPutI64(CPtr(UByte Ptr, (@local1(0))), local2)
            Else
                local3 = sqlite3_column_double(CPtr(Any Ptr, arg1), arg2)
                sessionPutDouble(CPtr(UByte Ptr, (@local1(0))), local3)
            End If
            sessionAppendBlob(arg0, CPtr(Const UByte Ptr, CPtr(UByte Ptr, (@local1(0)))), Cast(c2fb_c_int, 8ULL), arg3)
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
            ' C automatic storage declaration
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 4ULL))))) Then
                c2fb_temp_0 = CPtr(UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob_(arg1, arg2)))
                local4 = c2fb_temp_0
            Else
                c2fb_temp_1 = CPtr(UByte Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text_(arg1, arg2)))
                local4 = c2fb_temp_1
            End If
            c2fb_temp_2 = Cast(c2fb_c_int, c2fb_external_sqlite3_column_bytes_(arg1, arg2))
            local5 = c2fb_temp_2
            If (-Cast(c2fb_c_int, (((local4 <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
                sessionAppendVarint(arg0, local5, arg3)
                sessionAppendBlob(arg0, CPtr(Const UByte Ptr, local4), local5, arg3)
            Else
                c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_3) = c2fb_temp_4
            End If
        End If
    End If
End Sub
Function sessionAppendUpdate CDecl Alias "sessionAppendUpdate" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbe Ptr, ByVal arg3 As c2fb_source_record_52 Ptr, ByVal arg4 As UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_50
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local9 As c2fb_int64
    Dim local10 As Double
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As c2fb_c_int Ptr
    Dim c2fb_temp_12 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local2 = Cast(c2fb_c_int, 1ULL)
    local3 = arg0->nBuf
    ' C automatic storage declaration
    local5 = arg3->aRecord
    ' C unused-parameter annotation
    sessionAppendByte(arg0, Cast(c2fb_c_int, 23ULL), CPtr(c2fb_c_int Ptr, @(local0)))
    sessionAppendByte(arg0, arg3->bIndirect, CPtr(c2fb_c_int Ptr, @(local0)))
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local4 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local4 < c2fb_external_sqlite3_column_count_(arg2)))))
        local6 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        local8 = (*local5)
        Select Case local8
            Case Cast(c2fb_c_int, 5ULL)
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local7 = c2fb_temp_2
                If (-Cast(c2fb_c_int, ((sqlite3_column_type(CPtr(Any Ptr, arg2), local4) <> Cast(c2fb_c_int, 5ULL))))) Then
                    c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local6 = c2fb_temp_3
                End If
            Case Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, 1ULL)
                c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 9ULL))
                local7 = c2fb_temp_4
                If (-Cast(c2fb_c_int, ((local8 = sqlite3_column_type(CPtr(Any Ptr, arg2), local4))))) Then
                    local9 = sessionGetI64(CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, 1ULL)])))
                    If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, 1ULL))))) Then
                        If (-Cast(c2fb_c_int, ((local9 = c2fb_external_sqlite3_column_int64_(arg2, local4))))) Then
                            Goto c2fb_flow_2
                        End If
                    Else
                        ' C automatic storage declaration
                        c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Double Ptr, @(local10))), CPtr(Const Any Ptr, CPtr(c2fb_int64 Ptr, @(local9))), Cast(c2fb_c_int, 8ULL)))
                        If (-Cast(c2fb_c_int, ((local10 = sqlite3_column_double(CPtr(Any Ptr, arg2), local4))))) Then
                            Goto c2fb_flow_2
                        End If
                    End If
                End If
                c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local6 = c2fb_temp_6
                Goto c2fb_flow_2
            Case Else
                ' C automatic storage declaration
                local12 = Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sessionVarintGet(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(local5[Cast(c2fb_c_int, 1ULL)]))), CPtr(c2fb_c_int Ptr, @(local11)))))
                ' C unused-parameter annotation
                c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local12 + local11)))
                local7 = c2fb_temp_7
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local8 = sqlite3_column_type(CPtr(Any Ptr, arg2), local4))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local11 = c2fb_external_sqlite3_column_bytes_(arg2, local4))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local11 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, CPtr(UByte Ptr, @(local5[local12]))), CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob_(arg2, local4)), local11))))) <> 0)))))) <> 0))))) Then
                    Goto c2fb_flow_2
                End If
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local6 = c2fb_temp_8
        End Select
        c2fb_flow_2:
        If local6 Then
            c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_9
        End If
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, (((local6 <> 0) OrElse (arg4[local4] <> 0))))) Then
                sessionAppendBlob(arg0, CPtr(Const UByte Ptr, local5), local7, CPtr(c2fb_c_int Ptr, @(local0)))
            Else
                sessionAppendByte(arg0, Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_c_int Ptr, @(local0)))
            End If
        End If
        If (-Cast(c2fb_c_int, (((local6 <> 0) OrElse (((-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso (arg4[local4] <> 0)))))) <> 0))))) Then
            sessionAppendCol(CPtr(c2fb_source_record_50 Ptr, @(local1)), arg2, local4, CPtr(c2fb_c_int Ptr, @(local0)))
        Else
            sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, @(local1)), Cast(c2fb_c_int, &O0ULL), CPtr(c2fb_c_int Ptr, @(local0)))
        End If
        c2fb_temp_10 = CPtr(UByte Ptr, (local5 + local7))
        local5 = c2fb_temp_10
    c2fb_flow_1:
        c2fb_temp_1 = local4
        local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If local2 Then
        c2fb_temp_11 = CPtr(c2fb_c_int Ptr, @(arg0->nBuf))
        c2fb_temp_12 = Cast(c2fb_c_int, local3)
        (*c2fb_temp_11) = c2fb_temp_12
    Else
        sessionAppendBlob(arg0, CPtr(Const UByte Ptr, local1.aBuf), local1.nBuf, CPtr(c2fb_c_int Ptr, @(local0)))
    End If
    sqlite3_free(CPtr(Any Ptr, local1.aBuf))
    Return local0
End Function
Function sessionAppendDelete CDecl Alias "sessionAppendDelete" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_52 Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim c2fb_temp_2 As UByte Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    sessionAppendByte(arg0, Cast(c2fb_c_int, 9ULL), CPtr(c2fb_c_int Ptr, @(local0)))
    sessionAppendByte(arg0, arg2->bIndirect, CPtr(c2fb_c_int Ptr, @(local0)))
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        sessionAppendBlob(arg0, CPtr(Const UByte Ptr, arg2->aRecord), arg2->nRecord, CPtr(c2fb_c_int Ptr, @(local0)))
    Else
        ' C automatic storage declaration
        local2 = arg2->aRecord
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local1 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local1 < arg3))))
            local3 = local2
            c2fb_temp_2 = local2
            local2 = (c2fb_temp_2 + 1)
            local4 = (*c2fb_temp_2)
            Select Case local4
                Case Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 5ULL)
                    ' C unused-parameter annotation
                Case Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, 1ULL)
                    c2fb_temp_3 = CPtr(UByte Ptr, (local2 + Cast(c2fb_c_int, 8ULL)))
                    local2 = c2fb_temp_3
                Case Else
                    ' C automatic storage declaration
                    c2fb_temp_4 = CPtr(UByte Ptr, (local2 + sessionVarintGet(CPtr(Const UByte Ptr, local2), CPtr(c2fb_c_int Ptr, @(local5)))))
                    local2 = c2fb_temp_4
                    c2fb_temp_5 = CPtr(UByte Ptr, (local2 + local5))
                    local2 = c2fb_temp_5
                    Goto c2fb_flow_2
            End Select
            c2fb_flow_2:
            If arg4[local1] Then
                sessionAppendBlob(arg0, CPtr(Const UByte Ptr, local3), Cast(c2fb_c_int, ((CPtr(UByte Ptr, local2) - CPtr(UByte Ptr, local3)))), CPtr(c2fb_c_int Ptr, @(local0)))
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        ' C unused-parameter annotation
    End If
    Return local0
End Function
Private Function sessionPrepare CDecl Alias "sessionPrepare" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As SqliteVdbe Ptr Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr

    local0 = c2fb_external_sqlite3_prepare_v2_(arg0, arg3, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), arg1, Cast(c2fb_c_int, &O0ULL))
    If (-Cast(c2fb_c_int, (((arg2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg2)))
        c2fb_temp_1 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg_(arg0))))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    Return local0
End Function
Sub sessionPrepareMprintf CDecl Alias "sessionPrepareMprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As SqliteVdbe Ptr Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As Const ZString Ptr, ...)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As ZString Ptr
    Dim local1 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        Cva_Start(local1, arg4)
        c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf__(arg4, local1))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_1) = c2fb_temp_2
        Else
            c2fb_temp_3 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_4 = Cast(c2fb_c_int, sessionPrepare(arg1, arg2, arg3, CPtr(Const ZString Ptr, local0)))
            (*c2fb_temp_3) = c2fb_temp_4
            sqlite3_free(CPtr(Any Ptr, local0))
        End If
        Cva_End(local1)
    End If
End Sub
Function sessionSelectStmt CDecl Alias "sessionSelectStmt" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As Const ZString Ptr Ptr, ByVal arg7 As UByte Ptr, ByVal arg8 As SqliteVdbe Ptr Ptr, ByVal arg9 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_source_record_50
    Dim local5 As c2fb_source_record_50
    Dim local6 As c2fb_source_record_50
    Dim local7 As c2fb_source_record_50
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = StrPtr(!"")
    ' C automatic storage declaration
    local4 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local5 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local6 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local7 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local5)), StrPtr(!", 1"), CPtr(c2fb_c_int Ptr, @(local0)))
    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(StrPtr(!"sqlite_stat1"), arg3))))) Then
        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local5)), StrPtr(!" AND (?6 OR ?3 IS stat)"), CPtr(c2fb_c_int Ptr, @(local0)))
        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local6)), StrPtr(!"tbl, idx"), CPtr(c2fb_c_int Ptr, @(local0)))
        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local7)), StrPtr(!"?1, (CASE WHEN ?2=X'' THEN NULL ELSE ?2 END)"), CPtr(c2fb_c_int Ptr, @(local0)))
        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local4)), StrPtr(!"tbl, ?2, stat"), CPtr(c2fb_c_int Ptr, @(local0)))
    Else
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local3 < arg5))))
            If local4.nBuf Then
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local4)), StrPtr(!", "), CPtr(c2fb_c_int Ptr, @(local0)))
            End If
            sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, @(local4)), arg6[local3], CPtr(c2fb_c_int Ptr, @(local0)))
            If arg7[local3] Then
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local6)), local2, CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local7)), local2, CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_temp_2 = StrPtr(!", ")
                local2 = c2fb_temp_2
                sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, @(local6)), arg6[local3], CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendPrintf(CPtr(c2fb_source_record_50 Ptr, @(local7)), CPtr(c2fb_c_int Ptr, @(local0)), StrPtr(!"?%d"), Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))))
            Else
                sessionAppendPrintf(CPtr(c2fb_source_record_50 Ptr, @(local5)), CPtr(c2fb_c_int Ptr, @(local0)), StrPtr(!" AND (?%d OR ?%d IS %w.%w)"), Cast(c2fb_c_int, (Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))) + arg5)), Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))), arg3, arg6[local3])
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_3 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"SELECT %s%s FROM %Q.%Q WHERE (%s) IS (%s)"), CPtr(ZString Ptr, local4.aBuf), (IIf(arg1, CPtr(Const ZString Ptr, CPtr(ZString Ptr, local5.aBuf)), StrPtr(!""))), arg2, arg3, CPtr(ZString Ptr, local6.aBuf), CPtr(ZString Ptr, local7.aBuf)))
        local1 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_4
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_5 = Cast(c2fb_c_int, sessionPrepare(arg0, arg8, arg9, CPtr(Const ZString Ptr, local1)))
        local0 = c2fb_temp_5
    End If
    sqlite3_free(CPtr(Any Ptr, local1))
    sqlite3_free(CPtr(Any Ptr, local5.aBuf))
    sqlite3_free(CPtr(Any Ptr, local6.aBuf))
    sqlite3_free(CPtr(Any Ptr, local7.aBuf))
    sqlite3_free(CPtr(Any Ptr, local4.aBuf))
    Return local0
End Function
Function sessionSelectBind CDecl Alias "sessionSelectBind" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_source_record_52 Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As UByte Ptr
    Dim local5 As Double
    Dim local6 As c2fb_int64
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As UByte Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As UByte Ptr
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As UByte Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = arg3->aRecord
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 < arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))
        c2fb_temp_2 = local2
        local2 = (c2fb_temp_2 + 1)
        local3 = (*c2fb_temp_2)
        Select Case local3
            Case Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 5ULL)
                ' C unused-parameter annotation
            Case Cast(c2fb_c_int, 1ULL)
                If arg2[local0] Then
                    local4 = sessionGetI64(local2)
                    c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3_bind_int64_(arg0, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))), local4))
                    local1 = c2fb_temp_3
                End If
                c2fb_temp_4 = CPtr(UByte Ptr, (local2 + Cast(c2fb_c_int, 8ULL)))
                local2 = c2fb_temp_4
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 2ULL)
                If arg2[local0] Then
                    ' C automatic storage declaration
                    local6 = sessionGetI64(local2)
                    c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(Double Ptr, @(local5))), CPtr(Const Any Ptr, CPtr(c2fb_int64 Ptr, @(local6))), Cast(c2fb_c_int, 8ULL)))
                    c2fb_temp_6 = Cast(c2fb_c_int, sqlite3_bind_double(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))), local5))
                    local1 = c2fb_temp_6
                End If
                c2fb_temp_7 = CPtr(UByte Ptr, (local2 + Cast(c2fb_c_int, 8ULL)))
                local2 = c2fb_temp_7
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 3ULL)
                ' C automatic storage declaration
                c2fb_temp_8 = CPtr(UByte Ptr, (local2 + sessionVarintGet(CPtr(Const UByte Ptr, local2), CPtr(c2fb_c_int Ptr, @(local7)))))
                local2 = c2fb_temp_8
                If arg2[local0] Then
                    c2fb_temp_9 = Cast(c2fb_c_int, c2fb_external_sqlite3_bind_text_(arg0, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))), CPtr(Const ZString Ptr, CPtr(ZString Ptr, local2)), local7, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))))
                    local1 = c2fb_temp_9
                End If
                c2fb_temp_10 = CPtr(UByte Ptr, (local2 + local7))
                local2 = c2fb_temp_10
                Goto c2fb_flow_2
            Case Else
                ' C automatic storage declaration
                ' C unused-parameter annotation
                c2fb_temp_11 = CPtr(UByte Ptr, (local2 + sessionVarintGet(CPtr(Const UByte Ptr, local2), CPtr(c2fb_c_int Ptr, @(local8)))))
                local2 = c2fb_temp_11
                If arg2[local0] Then
                    c2fb_temp_12 = Cast(c2fb_c_int, c2fb_external_sqlite3_bind_blob_(arg0, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))), CPtr(Const Any Ptr, local2), local8, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))))))
                    local1 = c2fb_temp_12
                End If
                c2fb_temp_13 = CPtr(UByte Ptr, (local2 + local8))
                local2 = c2fb_temp_13
                Goto c2fb_flow_2
        End Select
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function
Sub sessionAppendTableHdr CDecl Alias "sessionAppendTableHdr" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_source_record_51 Ptr, ByVal arg3 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    sessionAppendByte(arg0, (IIf(arg1, Cast(c2fb_c_int, 80), Cast(c2fb_c_int, 84))), arg3)
    sessionAppendVarint(arg0, arg2->nCol, arg3)
    sessionAppendBlob(arg0, CPtr(Const UByte Ptr, arg2->abPK), arg2->nCol, arg3)
    sessionAppendBlob(arg0, CPtr(Const UByte Ptr, CPtr(UByte Ptr, arg2->zName)), Cast(c2fb_c_int, (Cast(c2fb_c_int, c2fb_crt_strlen(CPtr(Const ZString Ptr, arg2->zName))) + Cast(c2fb_c_int, 1ULL))), arg3)
End Sub
' c2fb skipped sessionGenerateChangeset: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionGenerateChangeset: expression parser stopped at byte 9 in (pSession->db): ->db
' c2fb skipped sqlite3session_changeset: requires unconverted C function sessionGenerateChangeset
' c2fb skipped sqlite3session_changeset_strm: requires unconverted C function sessionGenerateChangeset
' c2fb skipped sqlite3session_patchset_strm: requires unconverted C function sessionGenerateChangeset
' c2fb skipped sqlite3session_patchset: requires unconverted C function sessionGenerateChangeset
' c2fb skipped sqlite3session_enable: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3session_enable: assignment parser stopped at byte 46 (sqlite3_mutex_enter(sqlite3_db_mutex(pSession->db))): ->db))
' c2fb skipped sqlite3session_indirect: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3session_indirect: assignment parser stopped at byte 46 (sqlite3_mutex_enter(sqlite3_db_mutex(pSession->db))): ->db))
' c2fb skipped sqlite3session_isempty: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3session_isempty: assignment parser stopped at byte 46 (sqlite3_mutex_enter(sqlite3_db_mutex(pSession->db))): ->db))
' c2fb skipped sqlite3session_memory_used: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3session_memory_used: expression parser stopped at byte 9 in (pSession->nMalloc): ->nMalloc
' c2fb skipped sqlite3session_object_config: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3session_object_config: expression parser stopped at byte 9 in (pSession->pTable): ->pTable
' c2fb skipped sqlite3session_changeset_size: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3session_changeset_size: expression parser stopped at byte 9 in (pSession->nMaxChangesetSize): ->nMaxChangesetSize
' c2fb skipped sessionChangesetStart: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionChangesetStart: assignment parser stopped at byte 38 (nByte = sizeof(sqlite3_changeset_iter)): )
' c2fb skipped sqlite3changeset_start: requires unconverted C function sessionChangesetStart
' c2fb skipped sqlite3changeset_start_v2: requires unconverted C function sessionChangesetStart
' c2fb skipped sqlite3changeset_start_strm: requires unconverted C function sessionChangesetStart
' c2fb skipped sqlite3changeset_start_v2_strm: requires unconverted C function sessionChangesetStart
' c2fb skipped sessionDiscardData: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionDiscardData: expression parser stopped at byte 4 in (pIn->xInput && pIn->iCurrent>=sessions_strm_chunk_size): ->xInput && pIn->iCurrent>=sessions_strm_chunk_size
' c2fb skipped sessionInputBuffer: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionInputBuffer: expression parser stopped at byte 4 in (pIn->xInput): ->xInput
Sub sessionSkipRecord CDecl Alias "sessionSkipRecord" (ByVal arg0 As UByte Ptr Ptr, ByVal arg1 As c2fb_c_int)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte Ptr Ptr
    Dim c2fb_temp_7 As UByte Ptr

    local0 = (*arg0)
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < arg1))))
        c2fb_temp_2 = local0
        local0 = (c2fb_temp_2 + 1)
        local2 = (*c2fb_temp_2)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
            ' C automatic storage declaration
            c2fb_temp_3 = CPtr(UByte Ptr, (local0 + sessionVarintGet(CPtr(Const UByte Ptr, CPtr(UByte Ptr, local0)), CPtr(c2fb_c_int Ptr, @(local3)))))
            local0 = c2fb_temp_3
            c2fb_temp_4 = CPtr(UByte Ptr, (local0 + local3))
            local0 = c2fb_temp_4
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
                c2fb_temp_5 = CPtr(UByte Ptr, (local0 + Cast(c2fb_c_int, 8ULL)))
                local0 = c2fb_temp_5
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_6 = CPtr(UByte Ptr Ptr, @((*arg0)))
    c2fb_temp_7 = local0
    (*c2fb_temp_6) = c2fb_temp_7
End Sub
Function sessionValueSetStr CDecl Alias "sessionValueSetStr" (ByVal arg0 As SqliteVdbeMem Ptr, ByVal arg1 As UByte Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim c2fb_temp_0 As Any Ptr

    local0 = CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, arg2) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0), CPtr(Const Any Ptr, arg1), arg2))
    sqlite3ValueSetStr(CPtr(Any Ptr, arg0), arg2, CPtr(Const Any Ptr, CPtr(ZString Ptr, local0)), arg3, ProcPtr(sqlite3_free))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped sessionReadRecord: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionReadRecord: expression parser stopped at byte 4 in (pIn->iNext>=pIn->nData): ->iNext>=pIn->nData
' c2fb skipped sessionChangesetBufferTblhdr: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionChangesetBufferTblhdr: expression parser stopped at byte 4 in (pIn->nData - pIn->iNext): ->nData - pIn->iNext
' c2fb skipped sessionChangesetBufferRecord: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionChangesetBufferRecord: expression parser stopped at byte 4 in (pIn->iNext+nByte>=pIn->nData): ->iNext+nByte>=pIn->nData
' c2fb skipped sessionChangesetReadTblhdr: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionChangesetReadTblhdr: assignment parser stopped at byte 37 (rc = sessionChangesetBufferTblhdr(&p->in, &nCopy)): ->in, &nCopy)
' c2fb skipped sessionChangesetNextOne: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionChangesetNextOne: expression parser stopped at byte 2 in (p->rc!=0): ->rc!=0
' c2fb skipped sessionChangesetNext: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionChangesetNext: expression parser stopped at byte 13 in (rc==100 && p->bSkipEmpty && bEmpty): ->bSkipEmpty && bEmpty
' c2fb skipped sqlite3changeset_next: requires unconverted C function sessionChangesetNext
' c2fb skipped sqlite3changeset_op: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3changeset_op: assignment parser stopped at byte 13 (*pOp = pIter->op): ->op
' c2fb skipped sqlite3changeset_pk: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3changeset_pk: assignment parser stopped at byte 15 (*pabPK = pIter->abPK): ->abPK
' c2fb skipped sqlite3changeset_old: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3changeset_old: expression parser stopped at byte 6 in (pIter->op!=23 && pIter->op!=9): ->op!=23 && pIter->op!=9
' c2fb skipped sqlite3changeset_new: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3changeset_new: expression parser stopped at byte 6 in (pIter->op!=23 && pIter->op!=18): ->op!=23 && pIter->op!=18
' c2fb skipped sqlite3changeset_conflict: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3changeset_conflict: expression parser stopped at byte 7 in (!pIter->pConflict): ->pConflict
' c2fb skipped sqlite3changeset_fk_conflicts: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3changeset_fk_conflicts: expression parser stopped at byte 6 in (pIter->pConflict || pIter->apValue): ->pConflict || pIter->apValue
' c2fb skipped sqlite3changeset_finalize: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sqlite3changeset_finalize: assignment parser stopped at byte 7 (rc = p->rc): ->rc
' c2fb skipped sessionChangesetInvert: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionChangesetInvert: expression parser stopped at byte 7 in (pInput->iNext+1>=pInput->nData): ->iNext+1>=pInput->nData
' c2fb skipped sqlite3changeset_invert: outside the supported subset
' c2fb body diagnostic [incomplete-local-record-layout]: sqlite3changeset_invert: C record has no complete FreeBASIC storage layout: SessionInput
' c2fb skipped sqlite3changeset_invert_strm: outside the supported subset
' c2fb body diagnostic [incomplete-local-record-layout]: sqlite3changeset_invert_strm: C record has no complete FreeBASIC storage layout: SessionInput
' c2fb skipped sessionUpdateFind: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionUpdateFind: expression parser stopped at byte 6 in (pIter->nCol): ->nCol
Sub sessionUpdateFree CDecl Alias "sessionUpdateFree" (ByVal arg0 As c2fb_source_record_55 Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_source_record_54 Ptr
    Dim local1 As c2fb_source_record_54 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_54 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_54 Ptr
    Dim c2fb_temp_2 As c2fb_source_record_54 Ptr
    Dim c2fb_temp_3 As c2fb_source_record_54 Ptr Ptr
    Dim c2fb_temp_4 As c2fb_source_record_54 Ptr
    Dim c2fb_temp_5 As c2fb_c_uint Ptr Ptr
    Dim c2fb_temp_6 As c2fb_c_uint Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = arg0->pUp
    local0 = c2fb_temp_0
    While local0
        c2fb_temp_2 = local0->pNext
        local1 = c2fb_temp_2
        c2fb_external_sqlite3_finalize_(local0->pStmt)
        sqlite3_free(CPtr(Any Ptr, local0))
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    c2fb_temp_3 = CPtr(c2fb_source_record_54 Ptr Ptr, @(arg0->pUp))
    c2fb_temp_4 = CPtr(c2fb_source_record_54 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_3) = c2fb_temp_4
    sqlite3_free(CPtr(Any Ptr, arg0->aUpdateMask))
    c2fb_temp_5 = CPtr(c2fb_c_uint Ptr Ptr, @(arg0->aUpdateMask))
    c2fb_temp_6 = CPtr(c2fb_c_uint Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_5) = c2fb_temp_6
End Sub
Function sessionDeleteRow CDecl Alias "sessionDeleteRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_source_record_50
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    ' C automatic storage declaration
    local1 = StrPtr(!"")
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    local4 = Cast(c2fb_c_int, &O0ULL)
    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), StrPtr(!"DELETE FROM main."), CPtr(c2fb_c_int Ptr, @(local2)))
    sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, @(local3)), arg1, CPtr(c2fb_c_int Ptr, @(local2)))
    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), StrPtr(!" WHERE "), CPtr(c2fb_c_int Ptr, @(local2)))
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg2->nCol))))
        If arg2->abPK[local0] Then
            c2fb_temp_2 = local4
            local4 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), local1, CPtr(c2fb_c_int Ptr, @(local2)))
            sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, @(local3)), arg2->azCol[local0], CPtr(c2fb_c_int Ptr, @(local2)))
            sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), StrPtr(!" = ?"), CPtr(c2fb_c_int Ptr, @(local2)))
            sessionAppendInteger(CPtr(c2fb_source_record_50 Ptr, @(local3)), Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_c_int Ptr, @(local2)))
            c2fb_temp_3 = StrPtr(!" AND ")
            local1 = c2fb_temp_3
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local4 < arg2->nCol)))) Then
        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), StrPtr(!" AND (?"), CPtr(c2fb_c_int Ptr, @(local2)))
        sessionAppendInteger(CPtr(c2fb_source_record_50 Ptr, @(local3)), Cast(c2fb_c_int, (arg2->nCol + Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_c_int Ptr, @(local2)))
        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), StrPtr(!" OR "), CPtr(c2fb_c_int Ptr, @(local2)))
        c2fb_temp_4 = StrPtr(!"")
        local1 = c2fb_temp_4
        c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_5
        While (-Cast(c2fb_c_int, ((local0 < arg2->nCol))))
            If (-Cast(c2fb_c_int, (arg2->abPK[local0] = 0))) Then
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), local1, CPtr(c2fb_c_int Ptr, @(local2)))
                sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, @(local3)), arg2->azCol[local0], CPtr(c2fb_c_int Ptr, @(local2)))
                sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), StrPtr(!" IS ?"), CPtr(c2fb_c_int Ptr, @(local2)))
                sessionAppendInteger(CPtr(c2fb_source_record_50 Ptr, @(local3)), Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_c_int Ptr, @(local2)))
                c2fb_temp_7 = StrPtr(!"AND ")
                local1 = c2fb_temp_7
            End If
        c2fb_flow_3:
            c2fb_temp_6 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_6 + 1)))
        Wend
        c2fb_flow_2:
        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local3)), StrPtr(!")"), CPtr(c2fb_c_int Ptr, @(local2)))
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_8 = Cast(c2fb_c_int, sessionPrepare(arg0, CPtr(SqliteVdbe Ptr Ptr, @(arg2->pDelete)), CPtr(ZString Ptr Ptr, @(arg2->zErr)), CPtr(Const ZString Ptr, CPtr(ZString Ptr, local3.aBuf))))
        local2 = c2fb_temp_8
    End If
    sqlite3_free(CPtr(Any Ptr, local3.aBuf))
    Return local2
End Function
Function sessionSelectRow CDecl Alias "sessionSelectRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Return sessionSelectStmt(arg0, arg2->bIgnoreNoop, StrPtr(!"main"), arg1, arg2->bRowid, arg2->nCol, arg2->azCol, arg2->abPK, CPtr(SqliteVdbe Ptr Ptr, @(arg2->pSelect)), CPtr(ZString Ptr Ptr, @(arg2->zErr)))
End Function
Function sessionInsertRow CDecl Alias "sessionInsertRow" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_source_record_50
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local2 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local2)), StrPtr(!"INSERT INTO main."), CPtr(c2fb_c_int Ptr, @(local0)))
    sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, @(local2)), arg1, CPtr(c2fb_c_int Ptr, @(local0)))
    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local2)), StrPtr(!"("), CPtr(c2fb_c_int Ptr, @(local0)))
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local1 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local1 < arg2->nCol))))
        If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
            sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local2)), StrPtr(!", "), CPtr(c2fb_c_int Ptr, @(local0)))
        End If
        sessionAppendIdent(CPtr(c2fb_source_record_50 Ptr, @(local2)), arg2->azCol[local1], CPtr(c2fb_c_int Ptr, @(local0)))
    c2fb_flow_1:
        c2fb_temp_1 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local2)), StrPtr(!") VALUES(?"), CPtr(c2fb_c_int Ptr, @(local0)))
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    local1 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local1 < arg2->nCol))))
        sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local2)), StrPtr(!", ?"), CPtr(c2fb_c_int Ptr, @(local0)))
    c2fb_flow_3:
        c2fb_temp_3 = local1
        local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_2:
    sessionAppendStr(CPtr(c2fb_source_record_50 Ptr, @(local2)), StrPtr(!")"), CPtr(c2fb_c_int Ptr, @(local0)))
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = Cast(c2fb_c_int, sessionPrepare(arg0, CPtr(SqliteVdbe Ptr Ptr, @(arg2->pInsert)), CPtr(ZString Ptr Ptr, @(arg2->zErr)), CPtr(Const ZString Ptr, CPtr(ZString Ptr, local2.aBuf))))
        local0 = c2fb_temp_4
    End If
    sqlite3_free(CPtr(Any Ptr, local2.aBuf))
    Return local0
End Function
Function sessionStat1Sql CDecl Alias "sessionStat1Sql" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As c2fb_source_record_55 Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = sessionSelectRow(arg0, StrPtr(!"sqlite_stat1"), arg1)
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, sessionPrepare(arg0, CPtr(SqliteVdbe Ptr Ptr, @(arg1->pInsert)), Cast(c2fb_c_int, &O0ULL), StrPtr(!"INSERT INTO main.sqlite_stat1 VALUES(?1, CASE WHEN length(?2)=0 AND typeof(?2)='blob' THEN NULL ELSE ?2 END, ?3)")))
        local0 = c2fb_temp_0
    End If
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, sessionPrepare(arg0, CPtr(SqliteVdbe Ptr Ptr, @(arg1->pDelete)), Cast(c2fb_c_int, &O0ULL), StrPtr(!"DELETE FROM main.sqlite_stat1 WHERE tbl=?1 AND idx IS CASE WHEN length(?2)=0 AND typeof(?2)='blob' THEN NULL ELSE ?2 END AND (?4 OR stat IS ?3)")))
        local0 = c2fb_temp_1
    End If
    Return local0
End Function
Function sessionBindValue CDecl Alias "sessionBindValue" (ByVal arg0 As SqliteVdbe Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As SqliteVdbeMem Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int

    local0 = c2fb_external_sqlite3_value_type_(arg2)
    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 4ULL))))) <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(ZString Ptr, arg2->z) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    Return c2fb_external_sqlite3_bind_value_(arg0, arg1, CPtr(Const SqliteVdbeMem Ptr, arg2))
End Function
Function sessionBindRow CDecl Alias "sessionBindRow" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_callback_223, ByVal arg2 As c2fb_c_int, ByVal arg3 As UByte Ptr, ByVal arg4 As SqliteVdbe Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As SqliteVdbeMem Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0 < arg2)))) <> 0)))))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (arg3 = 0))) <> 0) OrElse (arg3[local0] <> 0))))) Then
            local2 = Cast(c2fb_c_int, &O0ULL)
            arg1(arg0, local0, CPtr(SqliteVdbeMem Ptr Ptr, @(local2)))
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, sqlite3CorruptError(Cast(c2fb_c_int, 4783ULL)))
                local1 = c2fb_temp_2
            Else
                c2fb_temp_3 = Cast(c2fb_c_int, sessionBindValue(arg4, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))), local2))
                local1 = c2fb_temp_3
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    Return local1
End Function
' c2fb skipped sessionSeekToRow: requires unconverted C function sqlite3changeset_op
' c2fb skipped sessionRebaseAdd: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionRebaseAdd: expression parser stopped at byte 6 in (pIter->op): ->op
' c2fb skipped sessionConflictHandler: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionConflictHandler: assignment parser stopped at byte 6 (pIter->pConflict = p->pSelect): ->pConflict = p->pSelect
' c2fb skipped sessionApplyOneOp: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionApplyOneOp: expression parser stopped at byte 7 in ((pIter->bPatchset ? p->abPK : 0)): ->bPatchset ? p->abPK : 0)
' c2fb skipped sessionApplyOneWithRetry: requires unconverted C function sessionApplyOneOp
' c2fb skipped sessionRetryIterInit: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionRetryIterInit: assignment parser stopped at byte 5 (pRet->bPatchset = bPatchset): ->bPatchset = bPatchset
' c2fb skipped sessionApplyRetryBuffer: requires unconverted C function sessionRetryIterInit
Function sessionUniqueColumns CDecl Alias "sessionUniqueColumns" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_source_record_55 Ptr, ByVal arg3 As UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As SqliteVdbe Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As SqliteVdbe Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As Const ZString Ptr
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As UByte
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg3), Cast(c2fb_c_int, &O0ULL), arg2->nCol))
    sessionPrepareMprintf(CPtr(c2fb_c_int Ptr, @(local1)), arg0, CPtr(SqliteVdbe Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg2->zErr)), StrPtr(!"PRAGMA main.index_list(%Q)"), arg1)
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step_(local0))))) <> 0)))))
        local2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text_(local0, Cast(c2fb_c_int, 1ULL))))
        local3 = c2fb_external_sqlite3_column_int_(local0, Cast(c2fb_c_int, 2ULL))
        local4 = c2fb_external_sqlite3_column_int_(local0, Cast(c2fb_c_int, 4ULL))
        local5 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_1
        End If
        sessionPrepareMprintf(CPtr(c2fb_c_int Ptr, @(local1)), arg0, CPtr(SqliteVdbe Ptr Ptr, @(local5)), CPtr(ZString Ptr Ptr, @(arg2->zErr)), StrPtr(!"PRAGMA main.index_xinfo(%Q)"), local2)
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step_(local5))))) <> 0)))))
            local6 = c2fb_external_sqlite3_column_int_(local5, Cast(c2fb_c_int, 1ULL))
            local7 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text_(local5, Cast(c2fb_c_int, 2ULL))))
            local8 = c2fb_external_sqlite3_column_int_(local5, Cast(c2fb_c_int, 5ULL))
            ' C automatic storage declaration
            If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_3
            End If
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local9 = c2fb_temp_1
            While (-Cast(c2fb_c_int, ((local9 < arg2->nCol))))
                If (-Cast(c2fb_c_int, (((local4 <> 0) OrElse ((-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((local7 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(local7, arg2->azCol[local9]))))) <> 0)))))) <> 0))))) Then
                    c2fb_temp_3 = CPtr(UByte Ptr, @(arg3[local9]))
                    c2fb_temp_4 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                    (*c2fb_temp_3) = c2fb_temp_4
                End If
            c2fb_flow_5:
                c2fb_temp_2 = local9
                local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
            Wend
            c2fb_flow_4:
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize_(local5))
            local1 = c2fb_temp_5
        Else
            c2fb_external_sqlite3_finalize_(local5)
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3_finalize_(local0))
        local1 = c2fb_temp_6
    Else
        c2fb_external_sqlite3_finalize_(local0)
    End If
    Return local1
End Function
' c2fb skipped sessionUpdateToUpdate: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionUpdateToUpdate: expression parser stopped at byte 14 in ((pNew = (pUp)->apValue[(pUp)->nCol+(ii)])!=0): ->apValue[(pUp)->nCol+(ii)])!=0
' c2fb skipped sessionRetryConstraints: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionRetryConstraints: expression parser stopped at byte 4 in (pUp->op==23): ->op==23
' c2fb skipped sessionChangesetApply: outside the supported subset
' c2fb body diagnostic [unmapped-record-field]: sessionChangesetApply: no FreeBASIC storage field for C member sqlite3.flags
' c2fb skipped sessionChangesetApplyV23: requires unconverted C function sessionChangesetStart
' c2fb skipped sqlite3changeset_apply_v2: requires unconverted C function sessionChangesetApplyV23
' c2fb skipped sqlite3changeset_apply_v3: requires unconverted C function sessionChangesetApplyV23
' c2fb skipped sqlite3changeset_apply: requires unconverted C function sessionChangesetApplyV23
' c2fb skipped sqlite3changeset_apply_v3_strm: requires unconverted C function sessionChangesetApplyV23
' c2fb skipped sqlite3changeset_apply_v2_strm: requires unconverted C function sessionChangesetApplyV23
' c2fb skipped sqlite3changeset_apply_strm: requires unconverted C function sessionChangesetApplyV23
Function sessionChangeMerge CDecl Alias "sessionChangeMerge" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_source_record_52 Ptr, ByVal arg4 As c2fb_c_int, ByVal arg5 As c2fb_c_int, ByVal arg6 As UByte Ptr, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_source_record_52 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_source_record_52 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_source_record_52 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As UByte Ptr Ptr
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Any Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim local4 As UByte Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_13 As UByte Ptr
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As UByte
    Dim c2fb_temp_16 As UByte Ptr
    Dim c2fb_temp_17 As UByte Ptr
    Dim c2fb_temp_18 As UByte
    Dim c2fb_temp_19 As Any Ptr
    Dim c2fb_temp_20 As UByte Ptr
    Dim c2fb_temp_21 As UByte Ptr
    Dim c2fb_temp_22 As c2fb_c_int Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_source_record_52 Ptr Ptr
    Dim c2fb_temp_25 As c2fb_source_record_52 Ptr
    Dim local6 As c2fb_int64
    Dim c2fb_temp_26 As c2fb_source_record_52 Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As UByte Ptr
    Dim local9 As UByte Ptr
    Dim local10 As UByte Ptr
    Dim c2fb_temp_28 As Any Ptr
    Dim c2fb_temp_29 As UByte Ptr
    Dim c2fb_temp_30 As UByte
    Dim c2fb_temp_31 As UByte Ptr
    Dim c2fb_temp_32 As UByte
    Dim c2fb_temp_33 As UByte Ptr Ptr
    Dim c2fb_temp_34 As UByte Ptr
    Dim c2fb_temp_35 As UByte Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_38 As UByte Ptr
    Dim c2fb_temp_39 As UByte Ptr
    Dim c2fb_temp_40 As UByte
    Dim c2fb_temp_41 As Any Ptr
    Dim c2fb_temp_42 As UByte Ptr
    Dim c2fb_temp_43 As Any Ptr
    Dim c2fb_temp_44 As UByte Ptr
    Dim c2fb_temp_45 As UByte Ptr
    Dim c2fb_temp_46 As UByte Ptr
    Dim c2fb_temp_47 As c2fb_c_int Ptr
    Dim c2fb_temp_48 As c2fb_c_int
    Dim local13 As c2fb_c_int
    Dim c2fb_temp_49 As c2fb_source_record_52 Ptr
    Dim local14 As UByte Ptr
    Dim local15 As c2fb_int64
    Dim local16 As UByte Ptr
    Dim c2fb_temp_50 As c2fb_int64
    Dim c2fb_temp_51 As c2fb_source_record_52 Ptr
    Dim c2fb_temp_52 As Any Ptr
    Dim c2fb_temp_53 As UByte Ptr
    Dim c2fb_temp_54 As UByte
    Dim c2fb_temp_55 As UByte Ptr Ptr
    Dim c2fb_temp_56 As UByte Ptr
    Dim c2fb_temp_57 As UByte Ptr
    Dim local17 As UByte Ptr
    Dim c2fb_temp_58 As UByte Ptr
    Dim c2fb_temp_59 As UByte
    Dim c2fb_temp_60 As UByte Ptr
    Dim c2fb_temp_61 As UByte
    Dim c2fb_temp_62 As Any Ptr
    Dim c2fb_temp_63 As UByte Ptr
    Dim c2fb_temp_64 As c2fb_source_record_52 Ptr
    Dim local18 As UByte Ptr
    Dim local19 As UByte Ptr
    Dim c2fb_temp_65 As UByte Ptr
    Dim c2fb_temp_66 As UByte
    Dim c2fb_temp_67 As c2fb_source_record_52 Ptr
    Dim c2fb_temp_68 As UByte Ptr
    Dim c2fb_temp_69 As UByte
    Dim c2fb_temp_70 As Any Ptr
    Dim c2fb_temp_71 As UByte Ptr
    Dim c2fb_temp_72 As c2fb_c_int Ptr
    Dim c2fb_temp_73 As c2fb_c_int
    Dim c2fb_temp_74 As c2fb_source_record_52 Ptr Ptr
    Dim c2fb_temp_75 As c2fb_source_record_52 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, (arg3 = 0))) Then
        c2fb_temp_0 = CPtr(c2fb_source_record_52 Ptr, CPtr(Any Ptr, sqlite3_malloc64(Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_52))) + Cast(c2fb_uint64, arg7))))))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, (local0 = 0))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_52))))
        c2fb_temp_2 = CPtr(UByte Ptr, @(local0->op))
        c2fb_temp_3 = Cast(UByte, arg4)
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(UByte Ptr, @(local0->bIndirect))
        c2fb_temp_5 = Cast(UByte, arg5)
        (*c2fb_temp_4) = c2fb_temp_5
        c2fb_temp_6 = CPtr(UByte Ptr Ptr, @(local0->aRecord))
        c2fb_temp_7 = CPtr(UByte Ptr, CPtr(c2fb_source_record_52 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
        (*c2fb_temp_6) = c2fb_temp_7
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg5 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(local0->nRecord))
            c2fb_temp_9 = Cast(c2fb_c_int, arg7)
            (*c2fb_temp_8) = c2fb_temp_9
            c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0->aRecord), CPtr(Const Any Ptr, arg6), arg7))
        Else
            ' C automatic storage declaration
            local3 = arg6
            local4 = local0->aRecord
            c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local2 = c2fb_temp_11
            While (-Cast(c2fb_c_int, ((local2 < arg0->nCol))))
                local5 = sessionSerialLen(CPtr(Const UByte Ptr, local3))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*local3)) = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_13 = local4
                    local4 = (c2fb_temp_13 + 1)
                    c2fb_temp_14 = CPtr(UByte Ptr, @((*c2fb_temp_13)))
                    c2fb_temp_15 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_14) = c2fb_temp_15
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->abPK[local2]) = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_16 = local4
                        local4 = (c2fb_temp_16 + 1)
                        c2fb_temp_17 = CPtr(UByte Ptr, @((*c2fb_temp_16)))
                        c2fb_temp_18 = Cast(UByte, Cast(c2fb_c_int, &HFFULL))
                        (*c2fb_temp_17) = c2fb_temp_18
                    Else
                        c2fb_temp_19 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local4), CPtr(Const Any Ptr, local3), local5))
                        c2fb_temp_20 = CPtr(UByte Ptr, (local4 + local5))
                        local4 = c2fb_temp_20
                    End If
                End If
                c2fb_temp_21 = CPtr(UByte Ptr, (local3 + local5))
                local3 = c2fb_temp_21
            c2fb_flow_1:
                c2fb_temp_12 = local2
                local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
            Wend
            c2fb_flow_0:
            c2fb_temp_22 = CPtr(c2fb_c_int Ptr, @(local0->nRecord))
            c2fb_temp_23 = Cast(c2fb_c_int, (CPtr(UByte Ptr, local4) - CPtr(UByte Ptr, local0->aRecord)))
            (*c2fb_temp_22) = c2fb_temp_23
        End If
    Else
        If arg1 Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg3->op) = Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso (arg3->bIndirect <> 0))))) Then
                c2fb_temp_24 = CPtr(c2fb_source_record_52 Ptr Ptr, @((*arg8)))
                c2fb_temp_25 = arg3
                (*c2fb_temp_24) = c2fb_temp_25
            Else
                local6 = Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_c_int, (arg7 + arg3->nRecord))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_52)))))
                c2fb_temp_26 = CPtr(c2fb_source_record_52 Ptr, CPtr(Any Ptr, sqlite3_malloc64(local6)))
                local0 = c2fb_temp_26
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_27 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                    local1 = c2fb_temp_27
                Else
                    ' C automatic storage declaration
                    local8 = arg3->aRecord
                    local9 = arg6
                    ' C automatic storage declaration
                    c2fb_temp_28 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), local6))
                    c2fb_temp_29 = CPtr(UByte Ptr, @(local0->bIndirect))
                    c2fb_temp_30 = Cast(UByte, (-Cast(c2fb_c_int, (((arg5 <> 0) OrElse (arg3->bIndirect <> 0))))))
                    (*c2fb_temp_29) = c2fb_temp_30
                    c2fb_temp_31 = CPtr(UByte Ptr, @(local0->op))
                    c2fb_temp_32 = Cast(UByte, arg4)
                    (*c2fb_temp_31) = c2fb_temp_32
                    c2fb_temp_33 = CPtr(UByte Ptr Ptr, @(local0->aRecord))
                    c2fb_temp_34 = CPtr(UByte Ptr, CPtr(c2fb_source_record_52 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
                    (*c2fb_temp_33) = c2fb_temp_34
                    c2fb_temp_35 = c2fb_temp_34
                    local10 = c2fb_temp_35
                    c2fb_temp_36 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local7 = c2fb_temp_36
                    While (-Cast(c2fb_c_int, ((local7 < arg0->nCol))))
                        local11 = sessionSerialLen(CPtr(Const UByte Ptr, local8))
                        local12 = sessionSerialLen(CPtr(Const UByte Ptr, local9))
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*local8)) = Cast(c2fb_c_int, &HFFULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->abPK[local7]) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg5 <> 0)))))) <> 0))))) Then
                            c2fb_temp_38 = local10
                            local10 = (c2fb_temp_38 + 1)
                            c2fb_temp_39 = CPtr(UByte Ptr, @((*c2fb_temp_38)))
                            c2fb_temp_40 = Cast(UByte, Cast(c2fb_c_int, &HFFULL))
                            (*c2fb_temp_39) = c2fb_temp_40
                        Else
                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*local9)) = Cast(c2fb_c_int, &O0ULL))))) Then
                                c2fb_temp_41 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local10), CPtr(Const Any Ptr, local8), local11))
                                c2fb_temp_42 = CPtr(UByte Ptr, (local10 + local11))
                                local10 = c2fb_temp_42
                            Else
                                c2fb_temp_43 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local10), CPtr(Const Any Ptr, local9), local12))
                                c2fb_temp_44 = CPtr(UByte Ptr, (local10 + local12))
                                local10 = c2fb_temp_44
                            End If
                        End If
                        c2fb_temp_45 = CPtr(UByte Ptr, (local8 + local11))
                        local8 = c2fb_temp_45
                        c2fb_temp_46 = CPtr(UByte Ptr, (local9 + local12))
                        local9 = c2fb_temp_46
                    c2fb_flow_3:
                        c2fb_temp_37 = local7
                        local7 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_37 + 1)))
                    Wend
                    c2fb_flow_2:
                    c2fb_temp_47 = CPtr(c2fb_c_int Ptr, @(local0->nRecord))
                    c2fb_temp_48 = Cast(c2fb_c_int, (CPtr(UByte Ptr, local10) - CPtr(UByte Ptr, local0->aRecord)))
                    (*c2fb_temp_47) = c2fb_temp_48
                End If
                sqlite3_free(CPtr(Any Ptr, arg3))
            End If
        Else
            local13 = arg3->op
            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, 18ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, 18ULL))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, 23ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, 18ULL))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, 23ULL))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, 9ULL))))) <> 0)))))) <> 0))))) Then
                c2fb_temp_49 = arg3
                local0 = c2fb_temp_49
            Else
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, 18ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, 9ULL))))) <> 0))))) Then
                    sqlite3_free(CPtr(Any Ptr, arg3))
                    ' C unused-parameter annotation
                Else
                    local14 = arg3->aRecord
                    ' C automatic storage declaration
                    ' C automatic storage declaration
                    c2fb_temp_50 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_52))) + Cast(c2fb_uint64, arg3->nRecord))) + Cast(c2fb_uint64, arg7))))
                    local15 = c2fb_temp_50
                    c2fb_temp_51 = CPtr(c2fb_source_record_52 Ptr, CPtr(Any Ptr, sqlite3_malloc64(local15)))
                    local0 = c2fb_temp_51
                    If (-Cast(c2fb_c_int, (local0 = 0))) Then
                        sqlite3_free(CPtr(Any Ptr, arg3))
                        Return Cast(c2fb_c_int, 7ULL)
                    End If
                    c2fb_temp_52 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_52))))
                    c2fb_temp_53 = CPtr(UByte Ptr, @(local0->bIndirect))
                    c2fb_temp_54 = Cast(UByte, ((-Cast(c2fb_c_int, (((arg5 <> 0) AndAlso (arg3->bIndirect <> 0)))))))
                    (*c2fb_temp_53) = c2fb_temp_54
                    c2fb_temp_55 = CPtr(UByte Ptr Ptr, @(local0->aRecord))
                    c2fb_temp_56 = CPtr(UByte Ptr, CPtr(c2fb_source_record_52 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)])))
                    (*c2fb_temp_55) = c2fb_temp_56
                    c2fb_temp_57 = c2fb_temp_56
                    local16 = c2fb_temp_57
                    If (-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, 18ULL))))) Then
                        local17 = arg6
                        ' C unused-parameter annotation
                        c2fb_temp_58 = CPtr(UByte Ptr, @(local0->op))
                        c2fb_temp_59 = Cast(UByte, Cast(c2fb_c_int, 18ULL))
                        (*c2fb_temp_58) = c2fb_temp_59
                        If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
                            sessionSkipRecord(CPtr(UByte Ptr Ptr, @(local17)), arg0->nCol)
                        End If
                        sessionMergeRecord(CPtr(UByte Ptr Ptr, @(local16)), arg0->nCol, local14, local17)
                    Else
                        If (-Cast(c2fb_c_int, ((local13 = Cast(c2fb_c_int, 9ULL))))) Then
                            ' C unused-parameter annotation
                            c2fb_temp_60 = CPtr(UByte Ptr, @(local0->op))
                            c2fb_temp_61 = Cast(UByte, Cast(c2fb_c_int, 23ULL))
                            (*c2fb_temp_60) = c2fb_temp_61
                            If arg2 Then
                                c2fb_temp_62 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local16), CPtr(Const Any Ptr, arg6), arg7))
                                c2fb_temp_63 = CPtr(UByte Ptr, (local16 + arg7))
                                local16 = c2fb_temp_63
                            Else
                                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionMergeUpdate(CPtr(UByte Ptr Ptr, @(local16)), arg0, arg2, local14, Cast(c2fb_c_int, &O0ULL), arg6, Cast(c2fb_c_int, &O0ULL)))))) Then
                                    sqlite3_free(CPtr(Any Ptr, local0))
                                    c2fb_temp_64 = CPtr(c2fb_source_record_52 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                                    local0 = c2fb_temp_64
                                End If
                            End If
                        Else
                            If (-Cast(c2fb_c_int, ((arg4 = Cast(c2fb_c_int, 23ULL))))) Then
                                local18 = local14
                                local19 = arg6
                                ' C unused-parameter annotation
                                If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) Then
                                    sessionSkipRecord(CPtr(UByte Ptr Ptr, @(local18)), arg0->nCol)
                                    sessionSkipRecord(CPtr(UByte Ptr Ptr, @(local19)), arg0->nCol)
                                End If
                                c2fb_temp_65 = CPtr(UByte Ptr, @(local0->op))
                                c2fb_temp_66 = Cast(UByte, Cast(c2fb_c_int, 23ULL))
                                (*c2fb_temp_65) = c2fb_temp_66
                                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionMergeUpdate(CPtr(UByte Ptr Ptr, @(local16)), arg0, arg2, arg6, local14, local18, local19))))) Then
                                    sqlite3_free(CPtr(Any Ptr, local0))
                                    c2fb_temp_67 = CPtr(c2fb_source_record_52 Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                                    local0 = c2fb_temp_67
                                End If
                            Else
                                ' C unused-parameter annotation
                                c2fb_temp_68 = CPtr(UByte Ptr, @(local0->op))
                                c2fb_temp_69 = Cast(UByte, Cast(c2fb_c_int, 9ULL))
                                (*c2fb_temp_68) = c2fb_temp_69
                                If arg2 Then
                                    c2fb_temp_70 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local16), CPtr(Const Any Ptr, arg6), arg7))
                                    c2fb_temp_71 = CPtr(UByte Ptr, (local16 + arg7))
                                    local16 = c2fb_temp_71
                                Else
                                    sessionMergeRecord(CPtr(UByte Ptr Ptr, @(local16)), arg0->nCol, arg6, local14)
                                End If
                            End If
                        End If
                    End If
                    If local0 Then
                        c2fb_temp_72 = CPtr(c2fb_c_int Ptr, @(local0->nRecord))
                        c2fb_temp_73 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((CPtr(UByte Ptr, local16) - CPtr(UByte Ptr, local0->aRecord)))))
                        (*c2fb_temp_72) = c2fb_temp_73
                    End If
                    sqlite3_free(CPtr(Any Ptr, arg3))
                End If
            End If
        End If
    End If
    c2fb_temp_74 = CPtr(c2fb_source_record_52 Ptr Ptr, @((*arg8)))
    c2fb_temp_75 = local0
    (*c2fb_temp_74) = c2fb_temp_75
    Return local1
End Function
Function sessionChangesetCheckCompat CDecl Alias "sessionChangesetCheckCompat" (ByVal arg0 As c2fb_source_record_51 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As UByte

    If (-Cast(c2fb_c_int, (((arg0->azCol <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 < arg0->nCol)))) <> 0))))) Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < arg0->nCol))))
            local1 = IIf(((-Cast(c2fb_c_int, ((local0 < arg1))))), Cast(c2fb_c_int, arg2[local0]), Cast(c2fb_c_int, &O0ULL))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg0->abPK[local0]) <> Cast(c2fb_c_int, local1))))) Then
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->nCol = arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, arg2), CPtr(Const Any Ptr, arg0->abPK), arg1))))) <> 0))))))
End Function
Function sessionChangesetExtendRecord CDecl Alias "sessionChangesetExtendRecord" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_source_record_51 Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_source_record_50 Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_int64
    Dim local4 As Double
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As Const UByte Ptr
    Dim local7 As Const UByte Ptr
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg6->nBuf))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, 18ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, 9ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->bPatch = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0))))) Then
        sessionAppendBlob(arg6, arg4, arg5, CPtr(c2fb_c_int Ptr, @(local0)))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->pDfltStmt = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, sessionPrepareDfltStmt(arg0->db, arg1, CPtr(SqliteVdbe Ptr Ptr, @(arg1->pDfltStmt))))
            local0 = c2fb_temp_2
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) <> c2fb_external_sqlite3_step_(arg1->pDfltStmt))))) <> 0))))) Then
                c2fb_temp_3 = Cast(c2fb_c_int, c2fb_external_sqlite3_errcode(arg0->db))
                local0 = c2fb_temp_3
            End If
        End If
        c2fb_temp_4 = Cast(c2fb_c_int, arg2)
        local1 = c2fb_temp_4
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 < arg1->nCol)))) <> 0)))))
            local2 = sqlite3_column_type(CPtr(Any Ptr, arg1->pDfltStmt), local1)
            sessionAppendByte(arg6, local2, CPtr(c2fb_c_int Ptr, @(local0)))
            Select Case local2
                Case Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, 1ULL)
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sessionBufferGrow(arg6, Cast(c2fb_c_int, 8ULL), CPtr(c2fb_c_int Ptr, @(local0))))))) Then
                        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) Then
                            local3 = c2fb_external_sqlite3_column_int64_(arg1->pDfltStmt, local1)
                            sessionPutI64(CPtr(UByte Ptr, @(arg6->aBuf[arg6->nBuf])), local3)
                        Else
                            local4 = sqlite3_column_double(CPtr(Any Ptr, arg1->pDfltStmt), local1)
                            sessionPutDouble(CPtr(UByte Ptr, @(arg6->aBuf[arg6->nBuf])), local4)
                        End If
                        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(arg6->nBuf))
                        c2fb_temp_7 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_6) + Cast(c2fb_c_int, 8ULL))))
                        (*c2fb_temp_6) = c2fb_temp_7
                    End If
                    Goto c2fb_flow_2
                Case Cast(c2fb_c_int, 4ULL), Cast(c2fb_c_int, 3ULL)
                    local5 = c2fb_external_sqlite3_column_bytes_(arg1->pDfltStmt, local1)
                    sessionAppendVarint(arg6, local5, CPtr(c2fb_c_int Ptr, @(local0)))
                    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 3ULL))))) Then
                        local6 = CPtr(Const UByte Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text_(arg1->pDfltStmt, local1)))
                        sessionAppendBlob(arg6, local6, local5, CPtr(c2fb_c_int Ptr, @(local0)))
                    Else
                        local7 = CPtr(Const UByte Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_column_blob_(arg1->pDfltStmt, local1)))
                        sessionAppendBlob(arg6, local7, local5, CPtr(c2fb_c_int Ptr, @(local0)))
                    End If
                    Goto c2fb_flow_2
                Case Else
                    ' C unused-parameter annotation
            End Select
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_5 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
        Wend
        c2fb_flow_0:
    Else
        If (-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, 23ULL))))) Then
            local8 = Cast(c2fb_c_int, &O0ULL)
            If (-Cast(c2fb_c_int, ((arg0->bPatch = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local1 = c2fb_temp_8
                While (-Cast(c2fb_c_int, ((local1 < arg2))))
                    c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local8 + sessionSerialLen(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg4[local8])))))))
                    local8 = c2fb_temp_10
                c2fb_flow_4:
                    c2fb_temp_9 = local1
                    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_9 + 1)))
                Wend
                c2fb_flow_3:
                sessionAppendBlob(arg6, arg4, local8, CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                local1 = c2fb_temp_11
                While (-Cast(c2fb_c_int, ((local1 < (Cast(c2fb_c_int, (arg1->nCol - arg2)))))))
                    sessionAppendByte(arg6, Cast(c2fb_c_int, &H00ULL), CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_flow_6:
                    c2fb_temp_12 = local1
                    local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
                Wend
                c2fb_flow_5:
            End If
            sessionAppendBlob(arg6, CPtr(Const UByte Ptr, CPtr(UByte Ptr, @(arg4[local8]))), Cast(c2fb_c_int, (arg5 - local8)), CPtr(c2fb_c_int Ptr, @(local0)))
            c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local1 = c2fb_temp_13
            While (-Cast(c2fb_c_int, ((local1 < (Cast(c2fb_c_int, (arg1->nCol - arg2)))))))
                sessionAppendByte(arg6, Cast(c2fb_c_int, &H00ULL), CPtr(c2fb_c_int Ptr, @(local0)))
            c2fb_flow_8:
                c2fb_temp_14 = local1
                local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_14 + 1)))
            Wend
            c2fb_flow_7:
        Else
            ' C unused-parameter annotation
            sessionAppendBlob(arg6, arg4, arg5, CPtr(c2fb_c_int Ptr, @(local0)))
        End If
    End If
    Return local0
End Function
' c2fb skipped sessionChangesetFindTable: requires unconverted C function sqlite3changeset_pk
' c2fb skipped sessionOneChangeToHash: requires unconverted C function sessionGrowHash
' c2fb skipped sessionOneChangeIterToHash: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionOneChangeIterToHash: expression parser stopped at byte 7 in (&pIter->in.aData[pIter->in.iCurrent + 2]): ->in.aData[pIter->in.iCurrent + 2]
' c2fb skipped sessionChangesetToHash: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionChangesetToHash: assignment parser stopped at byte 6 (pIter->in.bNoDiscard = 1): ->in.bNoDiscard = 1
Private Function sessionChangegroupOutput CDecl Alias "sessionChangegroupOutput" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_50
    Dim local2 As c2fb_source_record_51 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_51 Ptr
    Dim c2fb_temp_1 As c2fb_source_record_51 Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As c2fb_source_record_52 Ptr
    Dim c2fb_temp_4 As c2fb_source_record_52 Ptr
    Dim c2fb_temp_5 As c2fb_source_record_52 Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Any Ptr Ptr
    Dim c2fb_temp_11 As Any Ptr
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As UByte Ptr Ptr
    Dim c2fb_temp_15 As UByte Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Type<c2fb_source_record_50>( Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL) )
    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = arg0->pList
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local2 <> 0)))))
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((local2->nEntry = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_1
        End If
        sessionAppendTableHdr(CPtr(c2fb_source_record_50 Ptr, @(local1)), arg0->bPatch, local2, CPtr(c2fb_c_int Ptr, @(local0)))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local3 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local3 < local2->nChange))))
            ' C automatic storage declaration
            c2fb_temp_4 = CPtr(c2fb_source_record_52 Ptr Ptr, CPtr(c2fb_source_record_52 Ptr Ptr, local2->apChange))[local3]
            local4 = c2fb_temp_4
            While local4
                sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, @(local1)), local4->op, CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendByte(CPtr(c2fb_source_record_50 Ptr, @(local1)), local4->bIndirect, CPtr(c2fb_c_int Ptr, @(local0)))
                sessionAppendBlob(CPtr(c2fb_source_record_50 Ptr, @(local1)), CPtr(Const UByte Ptr, local4->aRecord), local4->nRecord, CPtr(c2fb_c_int Ptr, @(local0)))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1.nBuf >= c2fb_global_sessions_strm_chunk_size)))) <> 0))))) Then
                    c2fb_temp_6 = Cast(c2fb_c_int, arg1(arg2, CPtr(Const Any Ptr, local1.aBuf), local1.nBuf))
                    local0 = c2fb_temp_6
                    c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local1.nBuf))
                    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_7) = c2fb_temp_8
                End If
            c2fb_flow_5:
                c2fb_temp_5 = local4->pNext
                local4 = c2fb_temp_5
            Wend
            c2fb_flow_4:
        c2fb_flow_3:
            c2fb_temp_3 = local3
            local3 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
        Wend
        c2fb_flow_2:
    c2fb_flow_1:
        c2fb_temp_1 = local2->pNext
        local2 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        If arg1 Then
            If (-Cast(c2fb_c_int, ((local1.nBuf > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_9 = Cast(c2fb_c_int, arg1(arg2, CPtr(Const Any Ptr, local1.aBuf), local1.nBuf))
                local0 = c2fb_temp_9
            End If
        Else
            If arg4 Then
                c2fb_temp_10 = CPtr(Any Ptr Ptr, @((*arg4)))
                c2fb_temp_11 = CPtr(Any Ptr, local1.aBuf)
                (*c2fb_temp_10) = c2fb_temp_11
                If arg3 Then
                    c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                    c2fb_temp_13 = Cast(c2fb_c_int, local1.nBuf)
                    (*c2fb_temp_12) = c2fb_temp_13
                End If
                c2fb_temp_14 = CPtr(UByte Ptr Ptr, @(local1.aBuf))
                c2fb_temp_15 = CPtr(UByte Ptr, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))
                (*c2fb_temp_14) = c2fb_temp_15
            End If
        End If
    End If
    sqlite3_free(CPtr(Any Ptr, local1.aBuf))
    Return local0
End Function
Function sqlite3changegroup_new CDecl Alias "sqlite3changegroup_new" (ByVal arg0 As c2fb_source_record_57 Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_57 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_57 Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_source_record_57 Ptr Ptr
    Dim c2fb_temp_4 As c2fb_source_record_57 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_57 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_57)))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_1
    Else
        c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_57))))
    End If
    c2fb_temp_3 = CPtr(c2fb_source_record_57 Ptr Ptr, @((*arg0)))
    c2fb_temp_4 = local1
    (*c2fb_temp_3) = c2fb_temp_4
    Return local0
End Function
Function sqlite3changegroup_config CDecl Alias "sqlite3changegroup_config" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    Select Case arg1
        Case Cast(c2fb_c_int, 1ULL)
            local1 = (*CPtr(c2fb_c_int Ptr, arg2))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->pList = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @(arg0->bPatch))
                c2fb_temp_1 = Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((local1 > Cast(c2fb_c_int, &O0ULL)))))))
                (*c2fb_temp_0) = c2fb_temp_1
            End If
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*CPtr(c2fb_c_int Ptr, arg2))))
            c2fb_temp_3 = Cast(c2fb_c_int, arg0->bPatch)
            (*c2fb_temp_2) = c2fb_temp_3
            Goto c2fb_flow_0
        Case Else
            c2fb_temp_4 = Cast(c2fb_c_int, Cast(c2fb_c_int, 21ULL))
            local0 = c2fb_temp_4
    End Select
    c2fb_flow_0:
    Return local0
End Function
Function sqlite3changegroup_schema CDecl Alias "sqlite3changegroup_schema" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As sqlite3 Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As sqlite3 Ptr Ptr
    Dim c2fb_temp_5 As sqlite3 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, (((arg0->pList <> 0) OrElse (arg0->db <> 0))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 21ULL))
        local0 = c2fb_temp_0
    Else
        c2fb_temp_1 = CPtr(ZString Ptr Ptr, @(arg0->zDb))
        c2fb_temp_2 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s"), arg2))
        (*c2fb_temp_1) = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((arg0->zDb = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            local0 = c2fb_temp_3
        Else
            c2fb_temp_4 = CPtr(sqlite3 Ptr Ptr, @(arg0->db))
            c2fb_temp_5 = arg1
            (*c2fb_temp_4) = c2fb_temp_5
        End If
    End If
    Return local0
End Function
' c2fb skipped sqlite3changegroup_add: requires unconverted C function sqlite3changeset_start
' c2fb skipped sqlite3changegroup_add_change: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sqlite3changegroup_add_change: expression parser stopped at byte 6 in (pIter->in.iCurrent==pIter->in.iNext    || pIter->rc!=0    || pIter->bInvert): ->in.iCurrent==pIter->in.iNext    || pIter->rc!=0    || pIter->bInvert
Function sqlite3changegroup_output CDecl Alias "sqlite3changegroup_output" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As Any Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Return sessionChangegroupOutput(arg0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL), arg1, arg2)
End Function
' c2fb skipped sqlite3changegroup_add_strm: requires unconverted C function sqlite3changeset_start_strm
Function sqlite3changegroup_output_strm CDecl Alias "sqlite3changegroup_output_strm" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_callback_230, ByVal arg2 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Return sessionChangegroupOutput(arg0, arg1, arg2, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
End Function
' c2fb skipped sqlite3changegroup_delete: requires unconverted C function sessionDeleteTable
' c2fb skipped sqlite3changeset_concat: requires unconverted C function sqlite3changegroup_add
' c2fb skipped sqlite3changeset_concat_strm: requires unconverted C function sqlite3changegroup_add_strm
Sub sessionAppendRecordMerge CDecl Alias "sessionAppendRecordMerge" (ByVal arg0 As c2fb_source_record_50 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As UByte Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As UByte Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int Ptr)
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As UByte Ptr
    Dim local1 As UByte Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As UByte Ptr
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte Ptr
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = CPtr(UByte Ptr, @(arg2[arg3]))
    local1 = CPtr(UByte Ptr, @(arg4[arg5]))
    sessionBufferGrow(arg0, Cast(c2fb_int64, (Cast(c2fb_int64, arg3) + Cast(c2fb_int64, arg5))), arg6)
    If (-Cast(c2fb_c_int, (((*arg6) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        local3 = CPtr(UByte Ptr, @(arg0->aBuf[arg0->nBuf]))
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local2 < arg1))))
            local4 = (IIf((-Cast(c2fb_c_int, ((arg2 < local0)))), sessionSerialLen(CPtr(Const UByte Ptr, arg2)), Cast(c2fb_c_int, &O0ULL)))
            local5 = (IIf((-Cast(c2fb_c_int, ((arg4 < local1)))), sessionSerialLen(CPtr(Const UByte Ptr, arg4)), Cast(c2fb_c_int, &O0ULL)))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*arg2)) = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*arg2)) = Cast(c2fb_c_int, &HFFULL))))) <> 0)))))) <> 0)))))) <> 0))))) Then
                c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local3), CPtr(Const Any Ptr, arg4), local5))
                c2fb_temp_3 = CPtr(UByte Ptr, (local3 + local5))
                local3 = c2fb_temp_3
            Else
                c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local3), CPtr(Const Any Ptr, arg2), local4))
                c2fb_temp_5 = CPtr(UByte Ptr, (local3 + local4))
                local3 = c2fb_temp_5
            End If
            c2fb_temp_6 = CPtr(UByte Ptr, (arg2 + local4))
            arg2 = c2fb_temp_6
            c2fb_temp_7 = CPtr(UByte Ptr, (arg4 + local5))
            arg4 = c2fb_temp_7
        c2fb_flow_1:
            c2fb_temp_1 = local2
            local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @(arg0->nBuf))
        c2fb_temp_9 = Cast(c2fb_c_int, (CPtr(UByte Ptr, local3) - CPtr(UByte Ptr, arg0->aBuf)))
        (*c2fb_temp_8) = c2fb_temp_9
        ' C unused-parameter annotation
    End If
End Sub
' c2fb skipped sessionAppendPartialUpdate: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression]: sessionAppendPartialUpdate: assignment parser stopped at byte 16 (*pOut++ = pIter->bIndirect): ->bIndirect
' c2fb skipped sessionRebase: outside the supported subset
' c2fb body diagnostic [unsupported-expression]: sessionRebase: expression parser stopped at byte 6 in (pIter->zTab): ->zTab
Function sqlite3rebaser_create CDecl Alias "sqlite3rebaser_create" (ByVal arg0 As c2fb_source_record_58 Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_58 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_58 Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As c2fb_source_record_58 Ptr Ptr
    Dim c2fb_temp_4 As c2fb_source_record_58 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_source_record_58 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_58)))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
        local0 = c2fb_temp_1
    Else
        c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_58))))
    End If
    c2fb_temp_3 = CPtr(c2fb_source_record_58 Ptr Ptr, @((*arg0)))
    c2fb_temp_4 = local1
    (*c2fb_temp_3) = c2fb_temp_4
    Return local0
End Function
' c2fb skipped sqlite3rebaser_configure: requires unconverted C function sqlite3changeset_start
' c2fb skipped sqlite3rebaser_rebase: requires unconverted C function sqlite3changeset_start
' c2fb skipped sqlite3rebaser_rebase_strm: requires unconverted C function sqlite3changeset_start_strm
' c2fb skipped sqlite3rebaser_delete: requires unconverted C function sessionDeleteTable
Function sqlite3session_config CDecl Alias "sqlite3session_config" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Any Ptr) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    Select Case arg0
        Case Cast(c2fb_c_int, 1ULL)
            local1 = CPtr(c2fb_c_int Ptr, arg1)
            If (-Cast(c2fb_c_int, (((*local1) > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_0 = Cast(c2fb_c_int, (*local1))
                c2fb_global_sessions_strm_chunk_size = c2fb_temp_0
            End If
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*local1)))
            c2fb_temp_2 = Cast(c2fb_c_int, c2fb_global_sessions_strm_chunk_size)
            (*c2fb_temp_1) = c2fb_temp_2
            Goto c2fb_flow_0
        Case Else
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 21ULL))
            local0 = c2fb_temp_3
    End Select
    c2fb_flow_0:
    Return local0
End Function
' c2fb skipped sqlite3changegroup_change_begin: requires unconverted C function sessionChangesetFindTable
Private Function checkChangeParams CDecl Alias "checkChangeParams" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64, ByVal arg4 As c2fb_source_record_50 Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local1 As c2fb_source_record_50 Ptr
    Dim c2fb_temp_3 As c2fb_source_record_50 Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_source_record_50 Ptr Ptr
    Dim c2fb_temp_9 As c2fb_source_record_50 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->cd.pTab = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, 21ULL))
        local0 = c2fb_temp_0
    Else
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg2 >= arg0->cd.pTab->nCol)))) <> 0))))) Then
            c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 25ULL))
            local0 = c2fb_temp_1
        Else
            If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->cd.eOp = Cast(c2fb_c_int, 9ULL))))) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (arg1 = 0))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->cd.eOp = Cast(c2fb_c_int, 18ULL))))) <> 0)))))) <> 0))))) Then
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                local0 = c2fb_temp_2
            Else
                local1 = CPtr(c2fb_source_record_50 Ptr, @(arg0->cd.aBuf[arg2]))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->cd.eOp = Cast(c2fb_c_int, 23ULL))))) <> 0) AndAlso (arg1 <> 0))))) Then
                    c2fb_temp_3 = CPtr(c2fb_source_record_50 Ptr, (local1 + arg0->cd.pTab->nCol))
                    local1 = c2fb_temp_3
                End If
                c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(local1->nBuf))
                c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_4) = c2fb_temp_5
                sessionBufferGrow(local1, arg3, CPtr(c2fb_c_int Ptr, @(local0)))
                c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @(local1->nBuf))
                c2fb_temp_7 = Cast(c2fb_c_int, arg3)
                (*c2fb_temp_6) = c2fb_temp_7
                c2fb_temp_8 = CPtr(c2fb_source_record_50 Ptr Ptr, @((*arg4)))
                c2fb_temp_9 = local1
                (*c2fb_temp_8) = c2fb_temp_9
            End If
        End If
    End If
    Return local0
End Function
Function sqlite3changegroup_change_int64 CDecl Alias "sqlite3changegroup_change_int64" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_50 Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, checkChangeParams(arg0, arg1, arg2, Cast(c2fb_c_int, 9ULL), CPtr(c2fb_source_record_50 Ptr Ptr, @(local1))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((c2fb_temp_1 <> (c2fb_temp_0))))) Then
        Return local0
    End If
    c2fb_temp_2 = CPtr(UByte Ptr, @(local1->aBuf[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    sessionPutI64(CPtr(UByte Ptr, @(local1->aBuf[Cast(c2fb_c_int, 1ULL)])), arg3)
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3changegroup_change_null CDecl Alias "sqlite3changegroup_change_null" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_50 Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, checkChangeParams(arg0, arg1, arg2, Cast(c2fb_c_int, 1ULL), CPtr(c2fb_source_record_50 Ptr Ptr, @(local1))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((c2fb_temp_1 <> (c2fb_temp_0))))) Then
        Return local0
    End If
    c2fb_temp_2 = CPtr(UByte Ptr, @(local1->aBuf[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 5ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3changegroup_change_double CDecl Alias "sqlite3changegroup_change_double" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Double) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_source_record_50 Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, checkChangeParams(arg0, arg1, arg2, Cast(c2fb_c_int, 9ULL), CPtr(c2fb_source_record_50 Ptr Ptr, @(local1))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((c2fb_temp_1 <> (c2fb_temp_0))))) Then
        Return local0
    End If
    c2fb_temp_2 = CPtr(UByte Ptr, @(local1->aBuf[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 2ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    sessionPutDouble(CPtr(UByte Ptr, @(local1->aBuf[Cast(c2fb_c_int, 1ULL)])), arg3)
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3changegroup_change_text CDecl Alias "sqlite3changegroup_change_text" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_source_record_50 Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = IIf((-Cast(c2fb_c_int, ((arg4 >= Cast(c2fb_c_int, &O0ULL))))), Cast(c2fb_uint64, arg4), Cast(c2fb_uint64, c2fb_crt_strlen(arg3)))
    local1 = Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sessionVarintLen(local0)))) + local0))
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, checkChangeParams(arg0, arg1, arg2, local1, CPtr(c2fb_source_record_50 Ptr Ptr, @(local3))))
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((c2fb_temp_1 <> (c2fb_temp_0))))) Then
        Return local2
    End If
    c2fb_temp_2 = CPtr(UByte Ptr, @(local3->aBuf[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 3ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(local3->nBuf))
    c2fb_temp_5 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sessionVarintPut(CPtr(UByte Ptr, @(local3->aBuf[Cast(c2fb_c_int, 1ULL)])), local0)))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local3->aBuf[local3->nBuf]))), CPtr(Const Any Ptr, arg3), local0))
    c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local3->nBuf))
    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_int64, (Cast(c2fb_int64, (*c2fb_temp_7)) + local0)))
    (*c2fb_temp_7) = c2fb_temp_8
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3changegroup_change_blob CDecl Alias "sqlite3changegroup_change_blob" (ByVal arg0 As c2fb_source_record_57 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const Any Ptr, ByVal arg4 As c2fb_c_int) As c2fb_c_int Export
' c2fb source-path: ext/session/sqlite3session.c
    Dim local0 As c2fb_int64
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_source_record_50 Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Any Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    local0 = Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sessionVarintLen(arg4)))) + Cast(c2fb_int64, arg4)))
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_c_int, checkChangeParams(arg0, arg1, arg2, local0, CPtr(c2fb_source_record_50 Ptr Ptr, @(local2))))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((c2fb_temp_1 <> (c2fb_temp_0))))) Then
        Return local1
    End If
    c2fb_temp_2 = CPtr(UByte Ptr, @(local2->aBuf[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 4ULL))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(local2->nBuf))
    c2fb_temp_5 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) + sessionVarintPut(CPtr(UByte Ptr, @(local2->aBuf[Cast(c2fb_c_int, 1ULL)])), arg4)))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(local2->aBuf[local2->nBuf]))), arg3, arg4))
    c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local2->nBuf))
    c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_7) + arg4)))
    (*c2fb_temp_7) = c2fb_temp_8
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' c2fb skipped sqlite3changegroup_change_finish: requires unconverted C function sessionOneChangeToHash
#endif

/' end of sqlite3_bulk_session.bas '/
