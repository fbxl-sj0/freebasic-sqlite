/'
** 2014 August 30
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
'/

/'
    Project: SQLite RBU Extension

    File: sqlite3_rbu.bas

    Purpose:

        Implement SQLite's resumable bulk update and vacuum operations.

    Responsibilities:

        - RBU update state and progress
        - Checkpointing and resumable operation state
        - RBU VFS support

    This file intentionally does NOT contain:

        - The command-line RBU application
        - Tcl test procedures or C test support
        - Disabled checksum verification, debug assertions, or WinCE-only code
'/

#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_types.bi"
#include once "sqlite3_rbu_types.bi"
#include once "sqlite3_api_constants.bi"
#include once "sqlite3_debug_assert.bi"

Declare Function rbuShmChecksum CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_int64
Declare Function rbuVfsShmMap CDecl ( _
    ByVal pFile As c2fb_sqlite3_file Ptr, _
    ByVal regionIndex As c2fb_c_int, _
    ByVal regionSize As c2fb_c_int, _
    ByVal isWrite As c2fb_c_int, _
    ByVal pRegion As Any Ptr Ptr _
) As c2fb_c_int
Declare Function sqlite3rbu_step CDecl Alias "sqlite3rbu_step" ( _
    ByVal pRbu As c2fb_sqlite3rbu Ptr _
) As c2fb_c_int

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


Type c2fb_sqlite3_syscall_ptr As Sub CDecl()
Type c2fb_sqlite3_destructor_type As Sub CDecl(ByVal arg0 As Any Ptr)
Type c2fb_callback_4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr Ptr) As c2fb_c_int
Type c2fb_callback_6 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr) As c2fb_c_int
Type c2fb_callback_7 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Type c2fb_callback_8 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Type c2fb_callback_9 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Type c2fb_callback_10 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_11 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Type c2fb_callback_12 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_13 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Type c2fb_callback_14 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr Ptr) As c2fb_c_int
Type c2fb_callback_15 As Function CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_16 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_file Ptr)
Type c2fb_callback_19 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_file Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_20 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_21 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Type c2fb_callback_22 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr) As c2fb_c_int
Type c2fb_callback_23 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
Type c2fb_callback_24 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr)
Type c2fb_callback_25 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr) As Sub CDecl()
Type c2fb_callback_26 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr)
Type c2fb_callback_27 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr) As c2fb_c_int
Type c2fb_callback_28 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Type c2fb_callback_29 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Double Ptr) As c2fb_c_int
Type c2fb_callback_30 As Function CDecl(ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr) As c2fb_c_int
Type c2fb_callback_98 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
Type c2fb_callback_104 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Type c2fb_callback_105 As Sub CDecl(ByVal arg0 As c2fb_sqlite3_context Ptr)

Declare Function rbuDeltaGetInt CDecl (ByVal arg0 As Const ZString Ptr Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_uint
Declare Function rbuDeltaApply CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr) As c2fb_c_int
Declare Function rbuDeltaOutputSize CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Sub rbuFossilDeltaFunc CDecl (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function prepareAndCollectError CDecl (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
Declare Function resetAndCollectError CDecl (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As ZString Ptr Ptr) As c2fb_c_int
Declare Function prepareFreeAndCollectError CDecl (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr) As c2fb_c_int
Declare Sub rbuObjIterFreeCols CDecl (ByVal arg0 As c2fb_RbuObjIter Ptr)
Declare Sub rbuObjIterClearStatements CDecl (ByVal arg0 As c2fb_RbuObjIter Ptr)
Declare Sub rbuObjIterFinalize CDecl (ByVal arg0 As c2fb_RbuObjIter Ptr)
Declare Function rbuObjIterNext CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As c2fb_c_int
Declare Sub rbuTargetNameFunc CDecl (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function rbuObjIterFirst CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As c2fb_c_int
Declare Function rbuMPrintf CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
Declare Function rbuMPrintfExec CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As Const ZString Ptr, ...) As c2fb_c_int
Declare Function rbuMalloc CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Sub rbuAllocateIterArrays CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As c2fb_c_int)
Declare Function rbuStrndup CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As ZString Ptr
Declare Sub rbuFinalize CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr)
Declare Sub rbuTableType CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr)
Declare Sub rbuObjIterCacheIndexedCols CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr)
Declare Function rbuObjIterCacheTableInfo CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As c2fb_c_int
Declare Function rbuObjIterGetCollist CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
Declare Function rbuObjIterGetPkList CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr) As ZString Ptr
Declare Function rbuVacuumTableStart CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr) As ZString Ptr
Declare Function rbuVacuumIndexStart CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
Declare Function rbuObjIterGetIndexCols CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As ZString Ptr Ptr, ByVal arg5 As c2fb_c_int Ptr) As ZString Ptr
Declare Function rbuObjIterGetOldlist CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr) As ZString Ptr
Declare Function rbuObjIterGetWhere CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
Declare Sub rbuBadControlError CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Function rbuObjIterGetSetlist CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr) As ZString Ptr
Declare Function rbuObjIterGetBindlist CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int) As ZString Ptr
Declare Function rbuWithoutRowidPK CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
Declare Sub rbuCreateImposterTable2 CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr)
Declare Sub rbuCreateImposterTable CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr)
Declare Sub rbuObjIterPrepareTmpInsert CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr)
Declare Sub rbuTmpInsertFunc CDecl (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Function rbuObjIterGetIndexWhere CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
Declare Function rbuObjIterPrepareAll CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function rbuGetUpdateStmt CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_sqlite3_stmt Ptr Ptr) As c2fb_c_int
Declare Function rbuOpenDbhandle CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_sqlite3 Ptr
Declare Sub rbuFreeState CDecl (ByVal arg0 As c2fb_RbuState Ptr)
Declare Function rbuLoadState CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_RbuState Ptr
Declare Sub rbuOpenDatabase CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Sub rbuFileSuffix3 CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As ZString Ptr)
Declare Sub rbuSetupCheckpoint CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuState Ptr)
Declare Function rbuCaptureWalRead CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function rbuCaptureDbWrite CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Sub rbuCheckpointFrame CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuFrame Ptr)
Declare Function rbuLockDatabase CDecl (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function rbuExclusiveCheckpoint CDecl (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Sub rbuMoveOalFile CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Function rbuStepType CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Sub rbuStepOneOp CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int)
Declare Function rbuStep CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_c_int
Declare Sub rbuIncrSchemaCookie CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Sub rbuSaveState CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub rbuCopyPragma CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr)
Declare Sub rbuCreateTargetSchema CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Function rbuStrCompare CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Sub rbuSetupOal CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuState Ptr)
Declare Sub rbuDeleteOalFile CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Sub rbuCreateVfs CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Sub rbuDeleteVfs CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Sub rbuIndexCntFunc CDecl (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
Declare Sub rbuInitPhaseOneSteps CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Function openRbuHandle CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_sqlite3rbu Ptr
Declare Function rbuMisuseError CDecl () As c2fb_sqlite3rbu Ptr
Declare Function sqlite3rbu_open CDecl Alias "sqlite3rbu_open" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_sqlite3rbu Ptr
Declare Function sqlite3rbu_vacuum CDecl Alias "sqlite3rbu_vacuum" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_sqlite3rbu Ptr
Declare Function sqlite3rbu_db CDecl Alias "sqlite3rbu_db" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int) As c2fb_sqlite3 Ptr
Declare Sub rbuEditErrmsg CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
Declare Function sqlite3rbu_close CDecl Alias "sqlite3rbu_close" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As ZString Ptr Ptr) As c2fb_c_int
Declare Function sqlite3rbu_progress CDecl Alias "sqlite3rbu_progress" (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_int64
Declare Sub sqlite3rbu_bp_progress CDecl Alias "sqlite3rbu_bp_progress" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int Ptr)
Declare Function sqlite3rbu_state CDecl Alias "sqlite3rbu_state" (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_c_int
Declare Function sqlite3rbu_savestate CDecl Alias "sqlite3rbu_savestate" (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_c_int
Declare Function xDefaultRename CDecl (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
Declare Sub sqlite3rbu_rename_handler CDecl Alias "sqlite3rbu_rename_handler" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_callback_98)
Declare Sub rbuUnlockShm CDecl (ByVal arg0 As c2fb_rbu_file Ptr)
Declare Function rbuUpdateTempSize CDecl (ByVal arg0 As c2fb_rbu_file Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Sub rbuMainlistAdd CDecl (ByVal arg0 As c2fb_rbu_file Ptr)
Declare Sub rbuMainlistRemove CDecl (ByVal arg0 As c2fb_rbu_file Ptr)
Declare Function rbuFindMaindb CDecl (ByVal arg0 As c2fb_rbu_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_rbu_file Ptr
Declare Function rbuVfsClose CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr) As c2fb_c_int
Declare Function rbuGetU32 CDecl (ByVal arg0 As UByte Ptr) As c2fb_c_uint
Declare Sub rbuPutU32 CDecl (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_uint)
Declare Sub rbuPutU16 CDecl (ByVal arg0 As UByte Ptr, ByVal arg1 As UShort)
Declare Function rbuVfsRead CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Declare Function rbuVfsWrite CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
Declare Function rbuVfsTruncate CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
Declare Function rbuVfsSync CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function rbuVfsFileSize CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function rbuVfsLock CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function rbuVfsUnlock CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function rbuVfsCheckReservedLock CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function rbuVfsFileControl CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
Declare Function rbuVfsSectorSize CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr) As c2fb_c_int
Declare Function rbuVfsDeviceCharacteristics CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr) As c2fb_c_int
Declare Function rbuVfsShmLock CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Sub rbuVfsShmBarrier CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr)
Declare Function rbuVfsShmUnmap CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function rbuVfsOpen CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_file Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function rbuVfsDelete CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function rbuVfsAccess CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function rbuVfsFullPathname CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr) As c2fb_c_int
Declare Function rbuVfsDlOpen CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
Declare Sub rbuVfsDlError CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr)
Declare Function rbuVfsDlSym CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr) As Sub CDecl()
Declare Sub rbuVfsDlClose CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr)
Declare Function rbuVfsRandomness CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr) As c2fb_c_int
Declare Function rbuVfsSleep CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function rbuVfsCurrentTime CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Double Ptr) As c2fb_c_int
Declare Function rbuVfsGetLastError CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr) As c2fb_c_int
Declare Sub sqlite3rbu_destroy_vfs CDecl Alias "sqlite3rbu_destroy_vfs" (ByVal arg0 As Const ZString Ptr)
Declare Function sqlite3rbu_create_vfs CDecl Alias "sqlite3rbu_create_vfs" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3rbu_temp_size_limit CDecl Alias "sqlite3rbu_temp_size_limit" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_int64) As c2fb_int64
Declare Function sqlite3rbu_temp_size CDecl Alias "sqlite3rbu_temp_size" (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_int64
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strcmp CDecl Alias "strcmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_crt_memmove CDecl Alias "memmove" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Private Sub c2fbRbuAssert CDecl Alias "c2fbRbuAssert" ( _
    ByVal expression As Const ZString Ptr, _
    ByVal sourceFile As Const ZString Ptr, _
    ByVal sourceLine As c2fb_c_uint _
)
#ifdef SQLITE_DEBUG
    sqlite3DebugAssert(expression)
#endif
End Sub
Declare Function c2fb_external_rename CDecl Alias "rename" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_close CDecl Alias "sqlite3_close" (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_exec CDecl Alias "sqlite3_exec" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_callback_4, ByVal arg3 As Any Ptr, ByVal arg4 As ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_mprintf CDecl Alias "sqlite3_mprintf" (ByVal arg0 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_snprintf CDecl Alias "sqlite3_snprintf" (ByVal arg0 As c2fb_c_int, ByVal arg1 As ZString Ptr, ByVal arg2 As Const ZString Ptr, ...) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function c2fb_external_sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Sub c2fb_external_sqlite3_randomness CDecl Alias "sqlite3_randomness" (ByVal arg0 As c2fb_c_int, ByVal arg1 As Any Ptr)
Declare Function c2fb_external_sqlite3_open_v2 CDecl Alias "sqlite3_open_v2" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_sqlite3 Ptr Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_uri_boolean CDecl Alias "sqlite3_uri_boolean" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_filename_wal CDecl Alias "sqlite3_filename_wal" (ByVal arg0 As Const ZString Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_errmsg CDecl Alias "sqlite3_errmsg" (ByVal arg0 As c2fb_sqlite3 Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_prepare_v2 CDecl Alias "sqlite3_prepare_v2" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg4 As Const ZString Ptr Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_int CDecl Alias "sqlite3_bind_int" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_text CDecl Alias "sqlite3_bind_text" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_sqlite3_destructor_type) As c2fb_c_int
Declare Function c2fb_external_sqlite3_bind_value CDecl Alias "sqlite3_bind_value" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_count CDecl Alias "sqlite3_column_count" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_name CDecl Alias "sqlite3_column_name" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_step CDecl Alias "sqlite3_step" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int CDecl Alias "sqlite3_column_int" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_column_int64 CDecl Alias "sqlite3_column_int64" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_int64
Declare Function c2fb_external_sqlite3_column_text CDecl Alias "sqlite3_column_text" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_column_value CDecl Alias "sqlite3_column_value" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_sqlite3_value Ptr
Declare Function c2fb_external_sqlite3_column_type CDecl Alias "sqlite3_column_type" (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_finalize CDecl Alias "sqlite3_finalize" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_reset CDecl Alias "sqlite3_reset" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_create_function CDecl Alias "sqlite3_create_function" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr, ByVal arg5 As c2fb_callback_104, ByVal arg6 As c2fb_callback_104, ByVal arg7 As c2fb_callback_105) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_blob CDecl Alias "sqlite3_value_blob" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const Any Ptr
Declare Function c2fb_external_sqlite3_value_int CDecl Alias "sqlite3_value_int" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_text CDecl Alias "sqlite3_value_text" (ByVal arg0 As c2fb_sqlite3_value Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As c2fb_sqlite3_value Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_user_data CDecl Alias "sqlite3_user_data" (ByVal arg0 As c2fb_sqlite3_context Ptr) As Any Ptr
Declare Sub c2fb_external_sqlite3_result_blob CDecl Alias "sqlite3_result_blob" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_destructor_type)
Declare Sub c2fb_external_sqlite3_result_error CDecl Alias "sqlite3_result_error" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_error_nomem CDecl Alias "sqlite3_result_error_nomem" (ByVal arg0 As c2fb_sqlite3_context Ptr)
Declare Sub c2fb_external_sqlite3_result_error_code CDecl Alias "sqlite3_result_error_code" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_int CDecl Alias "sqlite3_result_int" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_text CDecl Alias "sqlite3_result_text" (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_destructor_type)
Declare Function c2fb_external_sqlite3_db_handle CDecl Alias "sqlite3_db_handle" (ByVal arg0 As c2fb_sqlite3_stmt Ptr) As c2fb_sqlite3 Ptr
Declare Function c2fb_external_sqlite3_db_filename CDecl Alias "sqlite3_db_filename" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr) As Const ZString Ptr
Declare Function c2fb_external_sqlite3_table_column_metadata CDecl Alias "sqlite3_table_column_metadata" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr Ptr, ByVal arg5 As Const ZString Ptr Ptr, ByVal arg6 As c2fb_c_int Ptr, ByVal arg7 As c2fb_c_int Ptr, ByVal arg8 As c2fb_c_int Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vfs_find CDecl Alias "sqlite3_vfs_find" (ByVal arg0 As Const ZString Ptr) As c2fb_sqlite3_vfs Ptr
Declare Function c2fb_external_sqlite3_vfs_register CDecl Alias "sqlite3_vfs_register" (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vfs_unregister CDecl Alias "sqlite3_vfs_unregister" (ByVal arg0 As c2fb_sqlite3_vfs Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_mutex_alloc CDecl Alias "sqlite3_mutex_alloc" (ByVal arg0 As c2fb_c_int) As c2fb_sqlite3_mutex Ptr
Declare Sub c2fb_external_sqlite3_mutex_free CDecl Alias "sqlite3_mutex_free" (ByVal arg0 As c2fb_sqlite3_mutex Ptr)
Declare Sub c2fb_external_sqlite3_mutex_enter CDecl Alias "sqlite3_mutex_enter" (ByVal arg0 As c2fb_sqlite3_mutex Ptr)
Declare Sub c2fb_external_sqlite3_mutex_leave CDecl Alias "sqlite3_mutex_leave" (ByVal arg0 As c2fb_sqlite3_mutex Ptr)
Declare Function c2fb_external_sqlite3_file_control CDecl Alias "sqlite3_file_control" (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Any Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_test_control CDecl Alias "sqlite3_test_control" (ByVal arg0 As c2fb_c_int, ...) As c2fb_c_int
Declare Function c2fb_external_sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_strnicmp CDecl Alias "sqlite3_strnicmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Dim Shared rbuVfsIoMethodsV2 As c2fb_sqlite3_io_methods
Dim Shared rbuVfsIoMethodsV1 As c2fb_sqlite3_io_methods
Dim Shared rbuVfsMethodsInitialized As c2fb_c_int = 0
Private Function rbuDeltaGetInt CDecl (ByVal arg0 As Const ZString Ptr Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_uint
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 509
    Static local0(0 To 255) As Byte = {Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, &O0ULL)), Cast(Byte, Cast(c2fb_c_int, 1ULL)), Cast(Byte, Cast(c2fb_c_int, 2ULL)), Cast(Byte, Cast(c2fb_c_int, 3ULL)), Cast(Byte, Cast(c2fb_c_int, 4ULL)), Cast(Byte, Cast(c2fb_c_int, 5ULL)), Cast(Byte, Cast(c2fb_c_int, 6ULL)), Cast(Byte, Cast(c2fb_c_int, 7ULL)), Cast(Byte, Cast(c2fb_c_int, 8ULL)), Cast(Byte, Cast(c2fb_c_int, 9ULL)), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, 10ULL)), Cast(Byte, Cast(c2fb_c_int, 11ULL)), Cast(Byte, Cast(c2fb_c_int, 12ULL)), Cast(Byte, Cast(c2fb_c_int, 13ULL)), Cast(Byte, Cast(c2fb_c_int, 14ULL)), Cast(Byte, Cast(c2fb_c_int, 15ULL)), Cast(Byte, Cast(c2fb_c_int, 16ULL)), Cast(Byte, Cast(c2fb_c_int, 17ULL)), Cast(Byte, Cast(c2fb_c_int, 18ULL)), Cast(Byte, Cast(c2fb_c_int, 19ULL)), Cast(Byte, Cast(c2fb_c_int, 20ULL)), Cast(Byte, Cast(c2fb_c_int, 21ULL)), Cast(Byte, Cast(c2fb_c_int, 22ULL)), Cast(Byte, Cast(c2fb_c_int, 23ULL)), Cast(Byte, Cast(c2fb_c_int, 24ULL)), Cast(Byte, Cast(c2fb_c_int, 25ULL)), Cast(Byte, Cast(c2fb_c_int, 26ULL)), Cast(Byte, Cast(c2fb_c_int, 27ULL)), Cast(Byte, Cast(c2fb_c_int, 28ULL)), Cast(Byte, Cast(c2fb_c_int, 29ULL)), Cast(Byte, Cast(c2fb_c_int, 30ULL)), Cast(Byte, Cast(c2fb_c_int, 31ULL)), Cast(Byte, Cast(c2fb_c_int, 32ULL)), Cast(Byte, Cast(c2fb_c_int, 33ULL)), Cast(Byte, Cast(c2fb_c_int, 34ULL)), Cast(Byte, Cast(c2fb_c_int, 35ULL)), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, 36ULL)), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, 37ULL)), Cast(Byte, Cast(c2fb_c_int, 38ULL)), Cast(Byte, Cast(c2fb_c_int, 39ULL)), Cast(Byte, Cast(c2fb_c_int, 40ULL)), Cast(Byte, Cast(c2fb_c_int, 41ULL)), Cast(Byte, Cast(c2fb_c_int, 42ULL)), Cast(Byte, Cast(c2fb_c_int, 43ULL)), Cast(Byte, Cast(c2fb_c_int, 44ULL)), Cast(Byte, Cast(c2fb_c_int, 45ULL)), Cast(Byte, Cast(c2fb_c_int, 46ULL)), Cast(Byte, Cast(c2fb_c_int, 47ULL)), Cast(Byte, Cast(c2fb_c_int, 48ULL)), Cast(Byte, Cast(c2fb_c_int, 49ULL)), Cast(Byte, Cast(c2fb_c_int, 50ULL)), Cast(Byte, Cast(c2fb_c_int, 51ULL)), Cast(Byte, Cast(c2fb_c_int, 52ULL)), Cast(Byte, Cast(c2fb_c_int, 53ULL)), Cast(Byte, Cast(c2fb_c_int, 54ULL)), Cast(Byte, Cast(c2fb_c_int, 55ULL)), Cast(Byte, Cast(c2fb_c_int, 56ULL)), Cast(Byte, Cast(c2fb_c_int, 57ULL)), Cast(Byte, Cast(c2fb_c_int, 58ULL)), Cast(Byte, Cast(c2fb_c_int, 59ULL)), Cast(Byte, Cast(c2fb_c_int, 60ULL)), Cast(Byte, Cast(c2fb_c_int, 61ULL)), Cast(Byte, Cast(c2fb_c_int, 62ULL)), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, 63ULL)), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))), Cast(Byte, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))}
    Dim local1 As c2fb_c_uint
    Dim local2 As c2fb_c_int
    Dim local3 As UByte Ptr
    Dim local4 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_uint
    Dim c2fb_temp_3 As UByte Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Const ZString Ptr Ptr
    Dim c2fb_temp_7 As Const ZString Ptr

    ' C static array storage
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local3 = CPtr(UByte Ptr, (*arg0))
    local4 = CPtr(UByte Ptr, (local3 + ((*arg1))))
    Do
        c2fb_temp_1 = 0
        If ((-Cast(c2fb_c_int, ((local3 < local4)))) <> 0) Then
            c2fb_temp_0 = Cast(c2fb_c_int, local0((*local3)))
            local2 = c2fb_temp_0
            c2fb_temp_1 = (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((c2fb_temp_0) >= Cast(c2fb_c_int, &O0ULL))))) <> 0))))
        End If
        If (c2fb_temp_1 = 0) Then Goto c2fb_flow_0
        c2fb_temp_2 = Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local1 Shl Cast(c2fb_c_int, 6ULL)))) + Cast(c2fb_c_uint, local2)))
        local1 = c2fb_temp_2
        c2fb_temp_3 = local3
        local3 = (c2fb_temp_3 + 1)
    c2fb_flow_1:
    Loop
    c2fb_flow_0:
    c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg1)))
    c2fb_temp_5 = Cast(c2fb_c_int, ((*c2fb_temp_4) - Cast(c2fb_c_int, ((CPtr(UByte Ptr, local3) - CPtr(UByte Ptr, CPtr(UByte Ptr, (*arg0))))))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(Const ZString Ptr Ptr, @((*arg0)))
    c2fb_temp_7 = CPtr(Const ZString Ptr, CPtr(ZString Ptr, local3))
    (*c2fb_temp_6) = c2fb_temp_7
    Return local1
End Function
Private Function rbuDeltaApply CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 600
    Dim local0 As c2fb_uint64
    Dim local1 As c2fb_uint64
    Dim c2fb_temp_0 As c2fb_uint64
    Dim c2fb_temp_1 As Const ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local2 As c2fb_c_uint
    Dim local3 As c2fb_c_uint
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_uint64
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As Const ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_uint64
    Dim c2fb_temp_15 As Any Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As Const ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Const ZString Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Byte Ptr
    Dim c2fb_temp_22 As Byte

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = Cast(c2fb_uint64, rbuDeltaGetInt(CPtr(Const ZString Ptr Ptr, @(arg2)), CPtr(c2fb_c_int Ptr, @(arg3))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 <= Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg2))) <> Cast(c2fb_c_int, 10))))) <> 0))))) Then
        Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    End If
    c2fb_temp_1 = arg2
    arg2 = (c2fb_temp_1 + 1)
    c2fb_temp_2 = arg3
    arg3 = Cast(c2fb_c_int, (c2fb_temp_2 - 1))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(Const Byte Ptr, arg2)[Cast(c2fb_c_int, &O0ULL)] <> 0)))))
        ' C automatic storage declaration
        ' C automatic storage declaration
        c2fb_temp_3 = rbuDeltaGetInt(CPtr(Const ZString Ptr Ptr, @(arg2)), CPtr(c2fb_c_int Ptr, @(arg3)))
        local2 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((arg3 <= Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
        End If
        Select Case CPtr(Const Byte Ptr, arg2)[Cast(c2fb_c_int, &O0ULL)]
            Case Cast(c2fb_c_int, 64)
                c2fb_temp_4 = arg2
                arg2 = (c2fb_temp_4 + 1)
                c2fb_temp_5 = arg3
                arg3 = Cast(c2fb_c_int, (c2fb_temp_5 - 1))
                c2fb_temp_6 = rbuDeltaGetInt(CPtr(Const ZString Ptr Ptr, @(arg2)), CPtr(c2fb_c_int Ptr, @(arg3)))
                local3 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg3 > Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, arg2)[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, 44))))) <> 0))))) Then
                    Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                End If
                c2fb_temp_7 = arg2
                arg2 = (c2fb_temp_7 + 1)
                c2fb_temp_8 = arg3
                arg3 = Cast(c2fb_c_int, (c2fb_temp_8 - 1))
                c2fb_temp_9 = Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, local2)))
                local1 = c2fb_temp_9
                If (-Cast(c2fb_c_int, ((local1 > local0)))) Then
                    Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                End If
                If (-Cast(c2fb_c_int, ((Cast(c2fb_uint64, (Cast(c2fb_uint64, local3) + Cast(c2fb_uint64, local2))) > Cast(c2fb_uint64, arg1))))) Then
                    Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                End If
                c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg4), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg0)[local3]))), local2))
                c2fb_temp_11 = CPtr(ZString Ptr, (CPtr(Byte Ptr, arg4) + local2))
                arg4 = c2fb_temp_11
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 58)
                c2fb_temp_12 = arg2
                arg2 = (c2fb_temp_12 + 1)
                c2fb_temp_13 = arg3
                arg3 = Cast(c2fb_c_int, (c2fb_temp_13 - 1))
                c2fb_temp_14 = Cast(c2fb_uint64, (local1 + Cast(c2fb_uint64, local2)))
                local1 = c2fb_temp_14
                If (-Cast(c2fb_c_int, ((local1 > local0)))) Then
                    Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                End If
                If (-Cast(c2fb_c_int, ((local2 > Cast(c2fb_c_uint, arg3))))) Then
                    Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                End If
                c2fb_temp_15 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg4), CPtr(Const Any Ptr, arg2), local2))
                c2fb_temp_16 = CPtr(ZString Ptr, (CPtr(Byte Ptr, arg4) + local2))
                arg4 = c2fb_temp_16
                c2fb_temp_17 = CPtr(Const ZString Ptr, (CPtr(Const Byte Ptr, arg2) + local2))
                arg2 = c2fb_temp_17
                c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg3) - local2)))
                arg3 = c2fb_temp_18
                Goto c2fb_flow_2
            Case Cast(c2fb_c_int, 59)
                c2fb_temp_19 = arg2
                arg2 = (c2fb_temp_19 + 1)
                c2fb_temp_20 = arg3
                arg3 = Cast(c2fb_c_int, (c2fb_temp_20 - 1))
                c2fb_temp_21 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg4)[Cast(c2fb_c_int, &O0ULL)]))
                c2fb_temp_22 = Cast(Byte, Cast(c2fb_c_int, &O0ULL))
                (*c2fb_temp_21) = c2fb_temp_22
                If (-Cast(c2fb_c_int, ((local1 <> local0)))) Then
                    Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                End If
                Return local1
            Case Else
                Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
        End Select
        c2fb_flow_2:
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
End Function
Private Function rbuDeltaOutputSize CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 687
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, rbuDeltaGetInt(CPtr(Const ZString Ptr Ptr, @(arg0)), CPtr(c2fb_c_int Ptr, @(arg1))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 <= Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Const Byte Ptr, arg0))) <> Cast(c2fb_c_int, 10))))) <> 0))))) Then
        Return Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    End If
    Return local0
End Function
Private Sub rbuFossilDeltaFunc CDecl (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 709
    Dim local0 As Const ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"argc==2"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 723ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    ' C unused-parameter annotation
    c2fb_temp_2 = c2fb_external_sqlite3_value_bytes(arg2[Cast(c2fb_c_int, &O0ULL)])
    local3 = c2fb_temp_2
    c2fb_temp_3 = CPtr(Const ZString Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob(arg2[Cast(c2fb_c_int, &O0ULL)])))
    local2 = c2fb_temp_3
    c2fb_temp_4 = c2fb_external_sqlite3_value_bytes(arg2[Cast(c2fb_c_int, 1ULL)])
    local1 = c2fb_temp_4
    c2fb_temp_5 = CPtr(Const ZString Ptr, CPtr(Const Any Ptr, c2fb_external_sqlite3_value_blob(arg2[Cast(c2fb_c_int, 1ULL)])))
    local0 = c2fb_temp_5
    c2fb_temp_6 = rbuDeltaOutputSize(local0, local1)
    local4 = c2fb_temp_6
    If (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_error(arg0, StrPtr(!"corrupt fossil delta"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Return
    End If
    c2fb_temp_7 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, local4) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
    local6 = c2fb_temp_7
    If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_error_nomem(arg0)
    Else
        c2fb_temp_8 = rbuDeltaApply(local2, local3, local0, local1, local6)
        local5 = c2fb_temp_8
        If (-Cast(c2fb_c_int, ((local5 <> local4)))) Then
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local6))
            c2fb_external_sqlite3_result_error(arg0, StrPtr(!"corrupt fossil delta"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        Else
            c2fb_external_sqlite3_result_blob(arg0, CPtr(Const Any Ptr, local6), local4, ProcPtr(c2fb_external_sqlite3_free))
        End If
    End If
End Sub
Private Function prepareAndCollectError CDecl (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 763
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As c2fb_sqlite3_stmt Ptr Ptr
    Dim c2fb_temp_3 As c2fb_sqlite3_stmt Ptr

    local0 = c2fb_external_sqlite3_prepare_v2(arg0, arg3, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), arg1, CPtr(Const ZString Ptr Ptr, 0))
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg2)))
        c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(arg0))))
        (*c2fb_temp_0) = c2fb_temp_1
        c2fb_temp_2 = CPtr(c2fb_sqlite3_stmt Ptr Ptr, @((*arg1)))
        c2fb_temp_3 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_2) = c2fb_temp_3
    End If
    Return local0
End Function
Private Function resetAndCollectError CDecl (ByVal arg0 As c2fb_sqlite3_stmt Ptr, ByVal arg1 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 785
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr

    local0 = c2fb_external_sqlite3_reset(arg0)
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr Ptr, @((*arg1)))
        c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(CPtr(c2fb_sqlite3 Ptr, c2fb_external_sqlite3_db_handle(arg0))))))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
    Return local0
End Function
Private Function prepareFreeAndCollectError CDecl (ByVal arg0 As c2fb_sqlite3 Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 808
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_sqlite3_stmt Ptr Ptr
    Dim c2fb_temp_4 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((*arg2) = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"*pzErrmsg==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 815ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, 7ULL)
        local0 = c2fb_temp_2
        c2fb_temp_3 = CPtr(c2fb_sqlite3_stmt Ptr Ptr, @((*arg1)))
        c2fb_temp_4 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_3) = c2fb_temp_4
    Else
        c2fb_temp_5 = prepareAndCollectError(arg0, arg1, arg2, CPtr(Const ZString Ptr, arg3))
        local0 = c2fb_temp_5
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg3))
    End If
    Return local0
End Function
Private Sub rbuObjIterFreeCols CDecl (ByVal arg0 As c2fb_RbuObjIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 830
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As Long Ptr Ptr
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_9 As UByte Ptr
    Dim c2fb_temp_10 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_11 As UByte Ptr
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, &O0ULL)
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local0 < arg0->nTblCol))))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->azTblCol[local0]))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->azTblType[local0]))
    c2fb_flow_1:
        c2fb_temp_1 = local0
        local0 = Cast(c2fb_c_int, (c2fb_temp_1 + 1))
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->azTblCol))
    c2fb_temp_2 = CPtr(ZString Ptr Ptr Ptr, @(arg0->azTblCol))
    c2fb_temp_3 = CPtr(ZString Ptr Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(ZString Ptr Ptr Ptr, @(arg0->azTblType))
    c2fb_temp_5 = CPtr(ZString Ptr Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(Long Ptr Ptr, @(arg0->aiSrcOrder))
    c2fb_temp_7 = CPtr(c2fb_c_int Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_6) = CPtr(Long Ptr, c2fb_temp_7)
    c2fb_temp_7 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(c2fb_u8 Ptr Ptr, @(arg0->abTblPk))
    c2fb_temp_9 = CPtr(UByte Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_8) = CPtr(c2fb_u8 Ptr, c2fb_temp_9)
    c2fb_temp_9 = CPtr(UByte Ptr, (*c2fb_temp_8))
    c2fb_temp_10 = CPtr(c2fb_u8 Ptr Ptr, @(arg0->abNotNull))
    c2fb_temp_11 = CPtr(UByte Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_10) = CPtr(c2fb_u8 Ptr, c2fb_temp_11)
    c2fb_temp_11 = CPtr(UByte Ptr, (*c2fb_temp_10))
    c2fb_temp_12 = CPtr(Long Ptr, @(arg0->nTblCol))
    c2fb_temp_13 = Cast(c2fb_c_int, &O0ULL)
    (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
    c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
    c2fb_temp_14 = CPtr(Long Ptr, @(arg0->eType))
    c2fb_temp_15 = Cast(c2fb_c_int, &O0ULL)
    (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
    c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
End Sub
Private Sub rbuObjIterClearStatements CDecl (ByVal arg0 As c2fb_RbuObjIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 850
    Dim local0 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_0 As c2fb_RbuUpdateStmt Ptr
    Dim local1 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_1 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_2 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_3 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_4 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_6 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_8 As c2fb_RbuUpdateStmt_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_10 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_11 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_RbuSpan_ Ptr Ptr
    Dim c2fb_temp_17 As c2fb_RbuSpan Ptr
    Dim c2fb_temp_18 As ZString Ptr Ptr
    Dim c2fb_temp_19 As ZString Ptr

    ' C automatic storage declaration
    c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pSelect))
    c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pInsert))
    c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pDelete))
    c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pTmpInsert))
    c2fb_temp_0 = CPtr(c2fb_RbuUpdateStmt Ptr, arg0->pRbuUpdate)
    local0 = c2fb_temp_0
    While local0
        local1 = CPtr(c2fb_RbuUpdateStmt Ptr, local0->pNext)
        c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, local0->pUpdate))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
        c2fb_temp_1 = local1
        local0 = c2fb_temp_1
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_RbuSpan Ptr, arg0->aIdxCol)))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zIdxSql))
    c2fb_temp_2 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pSelect))
    c2fb_temp_3 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_3)
    c2fb_temp_3 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_2))
    c2fb_temp_4 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pInsert))
    c2fb_temp_5 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_4) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pDelete))
    c2fb_temp_7 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_6) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_7)
    c2fb_temp_7 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(c2fb_RbuUpdateStmt_ Ptr Ptr, @(arg0->pRbuUpdate))
    c2fb_temp_9 = CPtr(_c2fb_record_c2fb_RbuUpdateStmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_8) = CPtr(c2fb_RbuUpdateStmt_ Ptr, c2fb_temp_9)
    c2fb_temp_9 = CPtr(c2fb_RbuUpdateStmt Ptr, (*c2fb_temp_8))
    c2fb_temp_10 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(arg0->pTmpInsert))
    c2fb_temp_11 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_10) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_11)
    c2fb_temp_11 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_10))
    c2fb_temp_12 = CPtr(Long Ptr, @(arg0->nCol))
    c2fb_temp_13 = Cast(c2fb_c_int, &O0ULL)
    (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
    c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
    c2fb_temp_14 = CPtr(Long Ptr, @(arg0->nIdxCol))
    c2fb_temp_15 = Cast(c2fb_c_int, &O0ULL)
    (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
    c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
    c2fb_temp_16 = CPtr(c2fb_RbuSpan_ Ptr Ptr, @(arg0->aIdxCol))
    c2fb_temp_17 = CPtr(_c2fb_record_c2fb_RbuSpan Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_16) = CPtr(c2fb_RbuSpan_ Ptr, c2fb_temp_17)
    c2fb_temp_17 = CPtr(c2fb_RbuSpan Ptr, (*c2fb_temp_16))
    c2fb_temp_18 = CPtr(ZString Ptr Ptr, @(arg0->zIdxSql))
    c2fb_temp_19 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_18) = c2fb_temp_19
End Sub
Private Sub rbuObjIterFinalize CDecl (ByVal arg0 As c2fb_RbuObjIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 882
    Dim c2fb_temp_0 As Any Ptr

    rbuObjIterClearStatements(arg0)
    c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pTblIter))
    c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, arg0->pIdxIter))
    rbuObjIterFreeCols(arg0)
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_RbuObjIter))))
End Sub
Private Function rbuObjIterNext CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 898
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Const ZString Ptr Ptr
    Dim c2fb_temp_6 As Const ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As Const ZString Ptr Ptr
    Dim c2fb_temp_10 As Const ZString Ptr
    Dim c2fb_temp_11 As Const ZString Ptr Ptr
    Dim c2fb_temp_12 As Const ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Const ZString Ptr Ptr
    Dim c2fb_temp_20 As Const ZString Ptr
    Dim c2fb_temp_21 As Const ZString Ptr Ptr
    Dim c2fb_temp_22 As Const ZString Ptr
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As Long Ptr
    Dim c2fb_temp_29 As c2fb_c_int

    local0 = arg0->rc
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        rbuObjIterClearStatements(arg1)
        If (-Cast(c2fb_c_int, ((arg1->zIdx = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"DROP TRIGGER IF EXISTS temp.rbu_insert_tr;DROP TRIGGER IF EXISTS temp.rbu_update1_tr;DROP TRIGGER IF EXISTS temp.rbu_update2_tr;DROP TRIGGER IF EXISTS temp.rbu_delete_tr;"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
            local0 = c2fb_temp_0
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            If arg1->bCleanup Then
                rbuObjIterFreeCols(arg1)
                c2fb_temp_1 = CPtr(Long Ptr, @(arg1->bCleanup))
                c2fb_temp_2 = Cast(c2fb_c_int, &O0ULL)
                (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
                c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
                c2fb_temp_3 = c2fb_external_sqlite3_step(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pTblIter))
                local0 = c2fb_temp_3
                If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, 100ULL))))) Then
                    c2fb_temp_4 = resetAndCollectError(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pTblIter), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
                    local0 = c2fb_temp_4
                    c2fb_temp_5 = CPtr(Const ZString Ptr Ptr, @(arg1->zTbl))
                    c2fb_temp_6 = CPtr(Const ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_5) = c2fb_temp_6
                    c2fb_temp_7 = CPtr(Const ZString Ptr Ptr, @(arg1->zDataTbl))
                    c2fb_temp_8 = CPtr(Const ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_7) = c2fb_temp_8
                Else
                    c2fb_temp_9 = CPtr(Const ZString Ptr Ptr, @(arg1->zTbl))
                    c2fb_temp_10 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pTblIter), Cast(c2fb_c_int, &O0ULL))))
                    (*c2fb_temp_9) = c2fb_temp_10
                    c2fb_temp_11 = CPtr(Const ZString Ptr Ptr, @(arg1->zDataTbl))
                    c2fb_temp_12 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pTblIter), Cast(c2fb_c_int, 1ULL))))
                    (*c2fb_temp_11) = c2fb_temp_12
                    c2fb_temp_13 = IIf(((-Cast(c2fb_c_int, (((arg1->zDataTbl <> 0) AndAlso (arg1->zTbl <> 0)))))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 7ULL))
                    local0 = c2fb_temp_13
                End If
            Else
                If (-Cast(c2fb_c_int, ((arg1->zIdx = Cast(c2fb_c_int, &O0ULL))))) Then
                    local1 = CPtr(c2fb_sqlite3_stmt Ptr, arg1->pIdxIter)
                    c2fb_temp_14 = c2fb_external_sqlite3_bind_text(local1, Cast(c2fb_c_int, 1ULL), arg1->zTbl, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_destructor_type, 0))
                    local0 = c2fb_temp_14
                End If
                If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_15 = c2fb_external_sqlite3_step(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pIdxIter))
                    local0 = c2fb_temp_15
                    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, 100ULL))))) Then
                        c2fb_temp_16 = resetAndCollectError(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pIdxIter), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
                        local0 = c2fb_temp_16
                        c2fb_temp_17 = CPtr(Long Ptr, @(arg1->bCleanup))
                        c2fb_temp_18 = Cast(c2fb_c_int, 1ULL)
                        (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
                        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
                        c2fb_temp_19 = CPtr(Const ZString Ptr Ptr, @(arg1->zIdx))
                        c2fb_temp_20 = CPtr(Const ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
                        (*c2fb_temp_19) = c2fb_temp_20
                    Else
                        c2fb_temp_21 = CPtr(Const ZString Ptr Ptr, @(arg1->zIdx))
                        c2fb_temp_22 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pIdxIter), Cast(c2fb_c_int, &O0ULL))))
                        (*c2fb_temp_21) = c2fb_temp_22
                        c2fb_temp_23 = CPtr(Long Ptr, @(arg1->iTnum))
                        c2fb_temp_24 = c2fb_external_sqlite3_column_int(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pIdxIter), Cast(c2fb_c_int, 1ULL))
                        (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
                        c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
                        c2fb_temp_25 = CPtr(Long Ptr, @(arg1->bUnique))
                        c2fb_temp_26 = c2fb_external_sqlite3_column_int(CPtr(c2fb_sqlite3_stmt Ptr, arg1->pIdxIter), Cast(c2fb_c_int, 2ULL))
                        (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
                        c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
                        c2fb_temp_27 = IIf(arg1->zIdx, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 7ULL))
                        local0 = c2fb_temp_27
                    End If
                End If
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        rbuObjIterFinalize(arg1)
        c2fb_temp_28 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_29 = local0
        (*c2fb_temp_28) = Cast(Long, c2fb_temp_29)
        c2fb_temp_29 = Cast(c2fb_c_int, (*c2fb_temp_28))
    End If
    Return local0
End Function
Private Sub rbuTargetNameFunc CDecl (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 979
    Dim local0 As c2fb_sqlite3rbu Ptr
    Dim local1 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = CPtr(c2fb_sqlite3rbu Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_user_data(arg0)))
    ' C automatic storage declaration
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"argc==1 || argc==2"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 986ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, &O0ULL)])))
    local1 = c2fb_temp_2
    If local1 Then
        If ((-Cast(c2fb_c_int, (((local0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) Then
            c2fb_temp_3 = 1
            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
                c2fbRbuAssert(StrPtr(!"argc==2 || argc==1"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 991ULL))
                c2fb_temp_3 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
            End If
            c2fb_temp_4 = (c2fb_temp_3)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_value_int(arg2[Cast(c2fb_c_int, 1ULL)]))))) <> 0))))) Then
                c2fb_external_sqlite3_result_text(arg0, local1, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_destructor_type, 0))
            End If
        Else
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, c2fb_crt_strlen(local1)) > Cast(c2fb_c_uint, Cast(c2fb_c_int, 4ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"data")), CPtr(Const Any Ptr, local1), Cast(c2fb_c_int, 4ULL)) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                ' C automatic storage declaration
                c2fb_temp_5 = Cast(c2fb_c_int, 4ULL)
                local2 = c2fb_temp_5
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local1)[local2]) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local1)[local2]) <= Cast(c2fb_c_int, 57))))) <> 0)))))
                    ' empty C statement
                c2fb_flow_1:
                    c2fb_temp_6 = local2
                    local2 = Cast(c2fb_c_int, (c2fb_temp_6 + 1))
                Wend
                c2fb_flow_0:
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local1)[local2]) = Cast(c2fb_c_int, 95))))) <> 0) AndAlso (CPtr(Const Byte Ptr, local1)[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))] <> 0))))) Then
                    c2fb_external_sqlite3_result_text(arg0, CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local1)[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))]))), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_destructor_type, 0))
                End If
            End If
        End If
    End If
End Sub
Private Function rbuObjIterFirst CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1015
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg1), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_RbuObjIter))))
    c2fb_temp_1 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pTblIter)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT rbu_target_name(name, type='view') AS target, name FROM sqlite_schema WHERE type IN ('table', 'view') AND target IS NOT NULL  %s ORDER BY name"), IIf(((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), StrPtr(!"AND rootpage!=0 AND rootpage IS NOT NULL"), StrPtr(!"")))))
    local0 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pIdxIter)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"SELECT name, rootpage, sql IS NULL OR substr(8, 6)=='UNIQUE'   FROM main.sqlite_schema   WHERE type='index' AND tbl_name = ?"))
        local0 = c2fb_temp_2
    End If
    c2fb_temp_3 = CPtr(Long Ptr, @(arg1->bCleanup))
    c2fb_temp_4 = Cast(c2fb_c_int, 1ULL)
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    c2fb_temp_5 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_6 = local0
    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    Return rbuObjIterNext(arg0, arg1)
End Function
Private Function rbuMPrintf CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1050
    Dim local0 As ZString Ptr
    Dim local1 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    Cva_Start(local1, arg1)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local1))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_2 = Cast(c2fb_c_int, 7ULL)
            (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
            c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        End If
    Else
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
        c2fb_temp_3 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_3
    End If
    Cva_End(local1)
    Return local0
End Function
Private Function rbuMPrintfExec CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As Const ZString Ptr, ...) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1075
    Dim local0 As Cva_List
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    ' C automatic storage declaration
    ' C automatic storage declaration
    Cva_Start(local0, arg2)
    c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg2, local0))
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_2 = Cast(c2fb_c_int, 7ULL)
            (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
            c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
        Else
            c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_4 = c2fb_external_sqlite3_exec(arg1, CPtr(Const ZString Ptr, local1), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        End If
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    Cva_End(local0)
    Return arg0->rc
End Function
Private Function rbuMalloc CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1102
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As Any Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"nByte>0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1105ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        c2fb_temp_2 = CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(arg1))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_4 = Cast(c2fb_c_int, 7ULL)
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        Else
            c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memset(local0, Cast(c2fb_c_int, &O0ULL), arg1))
        End If
    End If
    Return local0
End Function
Private Sub rbuAllocateIterArrays CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1122
    Dim local0 As c2fb_int64
    Dim local1 As ZString Ptr Ptr
    Dim c2fb_temp_0 As ZString Ptr Ptr
    Dim c2fb_temp_1 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As Long Ptr Ptr
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_10 As UByte Ptr
    Dim c2fb_temp_11 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_12 As UByte Ptr

    local0 = Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, 2ULL)) * Cast(c2fb_c_uint, Cast(c2fb_size_t, 8ULL)))) + Cast(c2fb_c_uint, Cast(c2fb_size_t, 4ULL)))) + Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, 3ULL)) * Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(UByte)))))))) * Cast(c2fb_c_uint, arg2)))
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(ZString Ptr Ptr, CPtr(Any Ptr, rbuMalloc(arg0, local0)))
    local1 = c2fb_temp_0
    If local1 Then
        c2fb_temp_1 = CPtr(ZString Ptr Ptr Ptr, @(arg1->azTblCol))
        c2fb_temp_2 = local1
        (*c2fb_temp_1) = c2fb_temp_2
        c2fb_temp_3 = CPtr(ZString Ptr Ptr Ptr, @(arg1->azTblType))
        c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(local1[arg2]))
        (*c2fb_temp_3) = c2fb_temp_4
        c2fb_temp_5 = CPtr(Long Ptr Ptr, @(arg1->aiSrcOrder))
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, CPtr(ZString Ptr Ptr, @(arg1->azTblType[arg2])))
        (*c2fb_temp_5) = CPtr(Long Ptr, c2fb_temp_6)
        c2fb_temp_6 = CPtr(c2fb_c_int Ptr, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(c2fb_u8 Ptr Ptr, @(arg1->abTblPk))
        c2fb_temp_8 = CPtr(UByte Ptr, CPtr(c2fb_c_int Ptr, @(arg1->aiSrcOrder[arg2])))
        (*c2fb_temp_7) = CPtr(c2fb_u8 Ptr, c2fb_temp_8)
        c2fb_temp_8 = CPtr(UByte Ptr, (*c2fb_temp_7))
        c2fb_temp_9 = CPtr(c2fb_u8 Ptr Ptr, @(arg1->abNotNull))
        c2fb_temp_10 = CPtr(UByte Ptr, CPtr(UByte Ptr, @(arg1->abTblPk[arg2])))
        (*c2fb_temp_9) = CPtr(c2fb_u8 Ptr, c2fb_temp_10)
        c2fb_temp_10 = CPtr(UByte Ptr, (*c2fb_temp_9))
        c2fb_temp_11 = CPtr(c2fb_u8 Ptr Ptr, @(arg1->abIndexed))
        c2fb_temp_12 = CPtr(UByte Ptr, CPtr(UByte Ptr, @(arg1->abNotNull[arg2])))
        (*c2fb_temp_11) = CPtr(c2fb_u8 Ptr, c2fb_temp_12)
        c2fb_temp_12 = CPtr(UByte Ptr, (*c2fb_temp_11))
    End If
End Sub
Private Function rbuStrndup CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_c_int Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1147
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_size_t
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, (((*arg1) = Cast(c2fb_c_int, &O0ULL))))) Then
        If arg0 Then
            local1 = Cast(c2fb_c_uint, (Cast(c2fb_c_uint, c2fb_crt_strlen(arg0)) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))
            c2fb_temp_0 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local1)))
            local0 = c2fb_temp_0
            If local0 Then
                c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0), CPtr(Const Any Ptr, arg0), local1))
            Else
                c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_3 = Cast(c2fb_c_int, 7ULL)
                (*c2fb_temp_2) = c2fb_temp_3
            End If
        End If
    End If
    Return local0
End Function
Private Sub rbuFinalize CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_sqlite3_stmt Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1172
    Dim local0 As c2fb_sqlite3 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr

    local0 = CPtr(c2fb_sqlite3 Ptr, c2fb_external_sqlite3_db_handle(arg1))
    local1 = c2fb_external_sqlite3_finalize(arg1)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = local1
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
        c2fb_temp_3 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(local0))))
        (*c2fb_temp_2) = c2fb_temp_3
    End If
End Sub
Private Sub rbuTableType CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_c_int Ptr, ByVal arg4 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1220
    Dim local0(0 To 3) As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local1 As Const UByte Ptr
    Dim local2 As Const UByte Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Long Ptr
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim local3 As c2fb_c_uint
    Dim c2fb_temp_28 As c2fb_c_uint
    Dim c2fb_temp_29 As c2fb_c_uint

    Erase local0
    local0(0) = Cast(c2fb_c_int, &O0ULL)
    local0(1) = Cast(c2fb_c_int, &O0ULL)
    local0(2) = Cast(c2fb_c_int, &O0ULL)
    local0(3) = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg2)))
    c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_3 = Cast(c2fb_c_int, &O0ULL)
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->rc==SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1238ULL))
        c2fb_temp_4 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_5 = (c2fb_temp_4)
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_7 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0(Cast(c2fb_c_int, &O0ULL)))), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT  (sql COLLATE nocase BETWEEN 'CREATE VIRTUAL' AND 'CREATE VIRTUAM'), rootpage  FROM sqlite_schema WHERE name=%Q"), arg1)))
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local0(Cast(c2fb_c_int, &O0ULL))) <> Cast(c2fb_c_int, 100ULL))))) <> 0))))) Then
        Goto c2fb_label_0
    End If
    If c2fb_external_sqlite3_column_int(local0(Cast(c2fb_c_int, &O0ULL)), Cast(c2fb_c_int, &O0ULL)) Then
        c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_9 = Cast(c2fb_c_int, 5ULL)
        (*c2fb_temp_8) = c2fb_temp_9
        Goto c2fb_label_0
    End If
    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg3)))
    c2fb_temp_11 = c2fb_external_sqlite3_column_int(local0(Cast(c2fb_c_int, &O0ULL)), Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_10) = c2fb_temp_11
    c2fb_temp_12 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_13 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0(Cast(c2fb_c_int, 1ULL)))), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA index_list=%Q"), arg1)))
    (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
    c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
    If arg0->rc Then
        Goto c2fb_label_0
    End If
    While (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local0(Cast(c2fb_c_int, 1ULL))) = Cast(c2fb_c_int, 100ULL)))))
        local1 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local0(Cast(c2fb_c_int, 1ULL)), Cast(c2fb_c_int, 3ULL)))
        local2 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local0(Cast(c2fb_c_int, 1ULL)), Cast(c2fb_c_int, 1ULL)))
        If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso (local2 <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local1[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 112))))) <> 0))))) Then
            c2fb_temp_14 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_15 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0(Cast(c2fb_c_int, 2ULL)))), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT rootpage FROM sqlite_schema WHERE name = %Q"), local2)))
            (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
            c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local0(Cast(c2fb_c_int, 2ULL))) = Cast(c2fb_c_int, 100ULL))))) Then
                    c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg4)))
                    c2fb_temp_17 = c2fb_external_sqlite3_column_int(local0(Cast(c2fb_c_int, 2ULL)), Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_16) = c2fb_temp_17
                    c2fb_temp_18 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                    c2fb_temp_19 = Cast(c2fb_c_int, 3ULL)
                    (*c2fb_temp_18) = c2fb_temp_19
                Else
                    c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                    c2fb_temp_21 = Cast(c2fb_c_int, 4ULL)
                    (*c2fb_temp_20) = c2fb_temp_21
                End If
            End If
            Goto c2fb_label_0
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_22 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_23 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0(Cast(c2fb_c_int, 3ULL)))), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA table_info=%Q"), arg1)))
    (*c2fb_temp_22) = Cast(Long, c2fb_temp_23)
    c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        While (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local0(Cast(c2fb_c_int, 3ULL))) = Cast(c2fb_c_int, 100ULL)))))
            If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_column_int(local0(Cast(c2fb_c_int, 3ULL)), Cast(c2fb_c_int, 5ULL)) > Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_24 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_25 = Cast(c2fb_c_int, 2ULL)
                (*c2fb_temp_24) = c2fb_temp_25
                Goto c2fb_label_0
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_26 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_27 = Cast(c2fb_c_int, 1ULL)
        (*c2fb_temp_26) = c2fb_temp_27
    End If
    c2fb_label_0:
    ' C automatic storage declaration
    c2fb_temp_28 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
    local3 = c2fb_temp_28
    While (-Cast(c2fb_c_int, ((local3 < Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_size_t, (4ULL * SizeOf(c2fb_sqlite3_stmt Ptr)))) \ Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(c2fb_sqlite3_stmt Ptr)))))))))
        rbuFinalize(arg0, local0(local3))
    c2fb_flow_5:
        c2fb_temp_29 = local3
        local3 = Cast(c2fb_c_uint, (c2fb_temp_29 + 1))
    Wend
    c2fb_flow_4:
End Sub
Private Sub rbuObjIterCacheIndexedCols CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1306
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_5 As Any Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_u8 Ptr
    Dim c2fb_temp_9 As UByte
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_17 As UByte Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, arg1->abIndexed), CPtr(Const Any Ptr, arg1->abTblPk), Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(UByte))) * Cast(c2fb_c_uint, arg1->nTblCol)))))
        c2fb_temp_1 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_2 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA main.index_list = %Q"), arg1->zTbl)))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    End If
    c2fb_temp_3 = CPtr(Long Ptr, @(arg1->nIndex))
    c2fb_temp_4 = Cast(c2fb_c_int, &O0ULL)
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local0))))) <> 0)))))
        local2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local0, Cast(c2fb_c_int, 1ULL))))
        local3 = c2fb_external_sqlite3_column_int(local0, Cast(c2fb_c_int, 4ULL))
        local4 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            Goto c2fb_flow_0
        End If
        If local3 Then
            c2fb_temp_5 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg1->abIndexed), Cast(c2fb_c_int, &H01ULL), Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(UByte))) * Cast(c2fb_c_uint, arg1->nTblCol)))))
        End If
        c2fb_temp_6 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_7 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local4)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA main.index_xinfo = %Q"), local2)))
        (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local4))))) <> 0)))))
            local5 = c2fb_external_sqlite3_column_int(local4, Cast(c2fb_c_int, 1ULL))
            If (-Cast(c2fb_c_int, ((local5 >= Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_8 = CPtr(c2fb_u8 Ptr, @(arg1->abIndexed[local5]))
                c2fb_temp_9 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_8) = Cast(c2fb_u8, c2fb_temp_9)
                c2fb_temp_9 = Cast(UByte, (*c2fb_temp_8))
            End If
            If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))))))) Then
                c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg1->abIndexed), Cast(c2fb_c_int, &H01ULL), Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(UByte))) * Cast(c2fb_c_uint, arg1->nTblCol)))))
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        rbuFinalize(arg0, local4)
        c2fb_temp_11 = Cast(c2fb_c_int, 1ULL)
        local1 = c2fb_temp_11
        c2fb_temp_12 = CPtr(Long Ptr, @(arg1->nIndex))
        c2fb_temp_13 = (*c2fb_temp_12)
        (*c2fb_temp_12) = Cast(c2fb_c_int, (c2fb_temp_13 + 1))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 4ULL))))) Then
        c2fb_temp_14 = CPtr(Long Ptr, @(arg1->nIndex))
        c2fb_temp_15 = (*c2fb_temp_14)
        (*c2fb_temp_14) = Cast(c2fb_c_int, (c2fb_temp_15 - 1))
    End If
    rbuFinalize(arg0, local0)
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_16 = CPtr(c2fb_u8 Ptr Ptr, @(arg1->abIndexed))
        c2fb_temp_17 = CPtr(UByte Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_16) = CPtr(c2fb_u8 Ptr, c2fb_temp_17)
        c2fb_temp_17 = CPtr(UByte Ptr, (*c2fb_temp_16))
    End If
End Sub
Private Function rbuObjIterCacheTableInfo CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1360
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim local7 As ZString Ptr
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As ZString Ptr Ptr
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_23 As Long Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As ZString Ptr Ptr
    Dim c2fb_temp_26 As ZString Ptr
    Dim c2fb_temp_27 As Long Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_29 As Long Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As ZString Ptr Ptr
    Dim c2fb_temp_32 As ZString Ptr
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As Long Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As ZString Ptr Ptr
    Dim c2fb_temp_38 As ZString Ptr
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As Const ZString Ptr
    Dim local13 As c2fb_c_int
    Dim c2fb_temp_39 As Long Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As Long Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim local14 As ZString Ptr
    Dim c2fb_temp_43 As ZString Ptr Ptr
    Dim c2fb_temp_44 As ZString Ptr
    Dim c2fb_temp_45 As ZString Ptr Ptr
    Dim c2fb_temp_46 As ZString Ptr
    Dim c2fb_temp_47 As ZString Ptr Ptr
    Dim c2fb_temp_48 As ZString Ptr
    Dim c2fb_temp_49 As c2fb_c_int
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As c2fb_u8 Ptr
    Dim c2fb_temp_52 As UByte
    Dim c2fb_temp_53 As c2fb_u8 Ptr
    Dim c2fb_temp_54 As UByte
    Dim c2fb_temp_55 As c2fb_c_int
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As c2fb_c_int
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg1->azTblCol = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = Cast(c2fb_c_int, &O0ULL)
        local1 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = Cast(c2fb_c_int, &O0ULL)
        local5 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"pIter->eType==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1370ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        rbuTableType(arg0, arg1->zTbl, CPtr(c2fb_c_int Ptr, @(arg1->eType)), CPtr(c2fb_c_int Ptr, @(local5)), CPtr(c2fb_c_int Ptr, @(arg1->iPkTnum)))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_3 = Cast(c2fb_c_int, 1ULL)
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
            c2fb_temp_5 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"no such table: %s"), arg1->zTbl))
            (*c2fb_temp_4) = c2fb_temp_5
        End If
        If arg0->rc Then
            Return arg0->rc
        End If
        If (-Cast(c2fb_c_int, ((arg1->zIdx = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_6 = CPtr(Long Ptr, @(arg1->iTnum))
            c2fb_temp_7 = local5
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        End If
        c2fb_temp_8 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 5ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"pIter->eType==RBU_PK_NONE || pIter->eType==RBU_PK_IPK || pIter->eType==RBU_PK_EXTERNAL || pIter->eType==RBU_PK_WITHOUT_ROWID || pIter->eType==RBU_PK_VTAB"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1379ULL))
            c2fb_temp_8 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_9 = (c2fb_temp_8)
        c2fb_temp_10 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_11 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT * FROM '%q'"), arg1->zDataTbl)))
        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_12 = c2fb_external_sqlite3_column_count(local0)
            local1 = c2fb_temp_12
            rbuAllocateIterArrays(arg0, arg1, local1)
        End If
        c2fb_temp_13 = Cast(c2fb_c_int, &O0ULL)
        local2 = c2fb_temp_13
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < local1)))) <> 0)))))
            local6 = CPtr(Const ZString Ptr, CPtr(Const ZString Ptr, c2fb_external_sqlite3_column_name(local0, local2)))
            If c2fb_external_sqlite3_strnicmp(StrPtr(!"rbu_"), local6, Cast(c2fb_c_int, 4ULL)) Then
                local7 = CPtr(ZString Ptr, rbuStrndup(local6, CPtr(c2fb_c_int Ptr, @(arg0->rc))))
                c2fb_temp_15 = CPtr(Long Ptr, @(arg1->aiSrcOrder[arg1->nTblCol]))
                c2fb_temp_16 = arg1->nTblCol
                (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
                c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
                c2fb_temp_17 = CPtr(Long Ptr, @(arg1->nTblCol))
                c2fb_temp_18 = (*c2fb_temp_17)
                (*c2fb_temp_17) = Cast(c2fb_c_int, (c2fb_temp_18 + 1))
                c2fb_temp_19 = CPtr(ZString Ptr Ptr, @(arg1->azTblCol[c2fb_temp_18]))
                c2fb_temp_20 = local7
                (*c2fb_temp_19) = c2fb_temp_20
            Else
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_external_sqlite3_stricmp(StrPtr(!"rbu_rowid"), local6))))) Then
                    c2fb_temp_21 = Cast(c2fb_c_int, 1ULL)
                    local3 = c2fb_temp_21
                End If
            End If
        c2fb_flow_1:
            c2fb_temp_14 = local2
            local2 = Cast(c2fb_c_int, (c2fb_temp_14 + 1))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_finalize(local0)
        c2fb_temp_22 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        local0 = c2fb_temp_22
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 <> ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 5ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL))))) <> 0)))))))))) <> 0))))) Then
            c2fb_temp_23 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_24 = Cast(c2fb_c_int, 1ULL)
            (*c2fb_temp_23) = Cast(Long, c2fb_temp_24)
            c2fb_temp_24 = Cast(c2fb_c_int, (*c2fb_temp_23))
            c2fb_temp_25 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
            c2fb_temp_26 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"table %q %s rbu_rowid column"), arg1->zDataTbl, (IIf(local3, StrPtr(!"may not have"), StrPtr(!"requires")))))
            (*c2fb_temp_25) = c2fb_temp_26
        End If
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_27 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_28 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA table_xinfo(%Q)"), arg1->zTbl)))
            (*c2fb_temp_27) = Cast(Long, c2fb_temp_28)
            c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
        End If
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local0))))) <> 0)))))
            local8 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local0, Cast(c2fb_c_int, 1ULL))))
            local9 = c2fb_external_sqlite3_column_int(local0, Cast(c2fb_c_int, 6ULL))
            If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
                Goto c2fb_flow_2
            End If
            If (-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, 1ULL))))) Then
                Goto c2fb_flow_3
            End If
            If (-Cast(c2fb_c_int, ((local9 <> Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_29 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_30 = Cast(c2fb_c_int, 1ULL)
                (*c2fb_temp_29) = Cast(Long, c2fb_temp_30)
                c2fb_temp_30 = Cast(c2fb_c_int, (*c2fb_temp_29))
                c2fb_temp_31 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
                c2fb_temp_32 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"generated columns not supported: %s.%s"), arg1->zTbl, local8))
                (*c2fb_temp_31) = c2fb_temp_32
                Goto c2fb_flow_2
            End If
            c2fb_temp_33 = local4
            local2 = c2fb_temp_33
            While (-Cast(c2fb_c_int, ((local2 < arg1->nTblCol))))
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_strcmp(local8, CPtr(Const ZString Ptr, arg1->azTblCol[local2])))))) Then
                    Goto c2fb_flow_4
                End If
            c2fb_flow_5:
                c2fb_temp_34 = local2
                local2 = Cast(c2fb_c_int, (c2fb_temp_34 + 1))
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, ((local2 = arg1->nTblCol)))) Then
                c2fb_temp_35 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_36 = Cast(c2fb_c_int, 1ULL)
                (*c2fb_temp_35) = Cast(Long, c2fb_temp_36)
                c2fb_temp_36 = Cast(c2fb_c_int, (*c2fb_temp_35))
                c2fb_temp_37 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
                c2fb_temp_38 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"column missing from %q: %s"), arg1->zDataTbl, local8))
                (*c2fb_temp_37) = c2fb_temp_38
            Else
                local10 = c2fb_external_sqlite3_column_int(local0, Cast(c2fb_c_int, 5ULL))
                local11 = c2fb_external_sqlite3_column_int(local0, Cast(c2fb_c_int, 3ULL))
                local12 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local0, Cast(c2fb_c_int, 2ULL))))
                If (-Cast(c2fb_c_int, ((local2 <> local4)))) Then
                    local13 = arg1->aiSrcOrder[local2]
                    c2fb_temp_39 = CPtr(Long Ptr, @(arg1->aiSrcOrder[local2]))
                    c2fb_temp_40 = arg1->aiSrcOrder[local4]
                    (*c2fb_temp_39) = Cast(Long, c2fb_temp_40)
                    c2fb_temp_40 = Cast(c2fb_c_int, (*c2fb_temp_39))
                    c2fb_temp_41 = CPtr(Long Ptr, @(arg1->aiSrcOrder[local4]))
                    c2fb_temp_42 = local13
                    (*c2fb_temp_41) = Cast(Long, c2fb_temp_42)
                    c2fb_temp_42 = Cast(c2fb_c_int, (*c2fb_temp_41))
                    ' empty C statement
                    local14 = arg1->azTblCol[local2]
                    c2fb_temp_43 = CPtr(ZString Ptr Ptr, @(arg1->azTblCol[local2]))
                    c2fb_temp_44 = arg1->azTblCol[local4]
                    (*c2fb_temp_43) = c2fb_temp_44
                    c2fb_temp_45 = CPtr(ZString Ptr Ptr, @(arg1->azTblCol[local4]))
                    c2fb_temp_46 = local14
                    (*c2fb_temp_45) = c2fb_temp_46
                    ' empty C statement
                End If
                c2fb_temp_47 = CPtr(ZString Ptr Ptr, @(arg1->azTblType[local4]))
                c2fb_temp_48 = CPtr(ZString Ptr, rbuStrndup(local12, CPtr(c2fb_c_int Ptr, @(arg0->rc))))
                (*c2fb_temp_47) = c2fb_temp_48
                c2fb_temp_49 = 1
                If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local10 >= Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
                    c2fbRbuAssert(StrPtr(!"iPk>=0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1461ULL))
                    c2fb_temp_49 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
                End If
                c2fb_temp_50 = (c2fb_temp_49)
                c2fb_temp_51 = CPtr(c2fb_u8 Ptr, @(arg1->abTblPk[local4]))
                c2fb_temp_52 = Cast(UByte, local10)
                (*c2fb_temp_51) = Cast(c2fb_u8, c2fb_temp_52)
                c2fb_temp_52 = Cast(UByte, (*c2fb_temp_51))
                c2fb_temp_53 = CPtr(c2fb_u8 Ptr, @(arg1->abNotNull[local4]))
                c2fb_temp_54 = Cast(UByte, (-Cast(c2fb_c_int, (((Cast(UByte, local11) <> 0) OrElse (((-Cast(c2fb_c_int, ((local10 <> Cast(c2fb_c_int, &O0ULL)))))) <> 0))))))
                (*c2fb_temp_53) = Cast(c2fb_u8, c2fb_temp_54)
                c2fb_temp_54 = Cast(UByte, (*c2fb_temp_53))
                c2fb_temp_55 = local4
                local4 = Cast(c2fb_c_int, (c2fb_temp_55 + 1))
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        rbuFinalize(arg0, local0)
        rbuObjIterCacheIndexedCols(arg0, arg1)
        c2fb_temp_56 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType <> Cast(c2fb_c_int, 5ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->abIndexed = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"pIter->eType!=RBU_PK_VTAB || pIter->abIndexed==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1470ULL))
            c2fb_temp_56 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_57 = (c2fb_temp_56)
        c2fb_temp_58 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType <> Cast(c2fb_c_int, 5ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->nIndex = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"pIter->eType!=RBU_PK_VTAB || pIter->nIndex==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1471ULL))
            c2fb_temp_58 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_59 = (c2fb_temp_58)
    End If
    Return arg0->rc
End Function
Private Function rbuObjIterGetCollist CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1482
    Dim local0 As ZString Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = StrPtr(!"")
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, &O0ULL)
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local2 < arg1->nTblCol))))
        local3 = CPtr(Const ZString Ptr, CPtr(Const ZString Ptr, arg1->azTblCol[local2]))
        c2fb_temp_2 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s\034%w\034"), local0, local1, local3))
        local0 = c2fb_temp_2
        c2fb_temp_3 = StrPtr(!", ")
        local1 = c2fb_temp_3
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, (c2fb_temp_1 + 1))
    Wend
    c2fb_flow_0:
    Return local0
End Function
Private Function rbuObjIterGetPkList CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Const ZString Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1503
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = Cast(c2fb_c_int, 1ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = StrPtr(!"")
    While Cast(c2fb_c_int, 1ULL)
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, &O0ULL)
        local3 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local3 < arg1->nTblCol))))
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->abTblPk[local3]) = local0)))) Then
                local4 = CPtr(Const ZString Ptr, CPtr(Const ZString Ptr, arg1->azTblCol[local3]))
                c2fb_temp_2 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s%s\034%w\034%s"), local1, local2, arg2, local4, arg4))
                local1 = c2fb_temp_2
                c2fb_temp_3 = arg3
                local2 = c2fb_temp_3
                Goto c2fb_flow_2
            End If
        c2fb_flow_3:
            c2fb_temp_1 = local3
            local3 = Cast(c2fb_c_int, (c2fb_temp_1 + 1))
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local3 = arg1->nTblCol)))) Then
            Goto c2fb_flow_0
        End If
        c2fb_temp_4 = local0
        local0 = Cast(c2fb_c_int, (c2fb_temp_4 + 1))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    Return local1
End Function
Private Function rbuVacuumTableStart CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1548
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local2 As c2fb_int64
    Dim c2fb_temp_2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    If arg2 Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT max(_rowid_) FROM \034%s%w\034"), arg3, arg1->zTbl)))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local0))))) <> 0))))) Then
            local2 = c2fb_external_sqlite3_column_int64(local0, Cast(c2fb_c_int, &O0ULL))
            c2fb_temp_2 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!" WHERE _rowid_ > %lld "), local2))
            local1 = c2fb_temp_2
        End If
        rbuFinalize(arg0, local0)
    Else
        local3 = CPtr(ZString Ptr, rbuObjIterGetPkList(arg0, arg1, StrPtr(!""), StrPtr(!", "), StrPtr(!" DESC")))
        local4 = CPtr(ZString Ptr, rbuObjIterGetPkList(arg0, arg1, StrPtr(!"quote("), StrPtr(!"||','||"), StrPtr(!")")))
        local5 = CPtr(ZString Ptr, rbuObjIterGetPkList(arg0, arg1, StrPtr(!""), StrPtr(!", "), StrPtr(!"")))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_4 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT %s FROM \034%s%w\034 ORDER BY %s LIMIT 1"), local4, arg3, arg1->zTbl, local3)))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local0))))) <> 0))))) Then
                local6 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local0, Cast(c2fb_c_int, &O0ULL))))
                c2fb_temp_5 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!" WHERE (%s) > (%s) "), local5, local6))
                local1 = c2fb_temp_5
            End If
            rbuFinalize(arg0, local0)
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local5))
    End If
    Return local1
End Function
Private Function rbuVacuumIndexStart CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1615
    Dim local0 As ZString Ptr
    Dim local1 As ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As Const ZString Ptr
    Dim local11 As Const ZString Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim c2fb_temp_10 As ZString Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim local13 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Const ZString Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim local14 As Const ZString Ptr
    Dim c2fb_temp_20 As Long Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As ZString Ptr
    Dim c2fb_temp_24 As Const ZString Ptr
    Dim c2fb_temp_25 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = StrPtr(!"")
    local7 = Cast(c2fb_c_int, &O0ULL)
    local8 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_1 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local8)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA main.index_xinfo = %Q"), arg1->zIdx)))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local8))))) <> 0)))))
        local9 = c2fb_external_sqlite3_column_int(local8, Cast(c2fb_c_int, 1ULL))
        local10 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local8, Cast(c2fb_c_int, 4ULL))))
        ' C automatic storage declaration
        If c2fb_external_sqlite3_column_int(local8, Cast(c2fb_c_int, 3ULL)) Then
            c2fb_temp_2 = Cast(c2fb_c_int, 1ULL)
            local5 = c2fb_temp_2
            Goto c2fb_flow_0
        End If
        If (-Cast(c2fb_c_int, ((local9 < Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 2ULL))))) Then
                ' C automatic storage declaration
                c2fb_temp_3 = Cast(c2fb_c_int, &O0ULL)
                local12 = c2fb_temp_3
                While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->abTblPk[local12]) = Cast(c2fb_c_int, &O0ULL)))))
                    ' empty C statement
                c2fb_flow_3:
                    c2fb_temp_4 = local12
                    local12 = Cast(c2fb_c_int, (c2fb_temp_4 + 1))
                Wend
                c2fb_flow_2:
                c2fb_temp_5 = 1
                If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local12 < arg1->nTblCol))))) = 0))) = 0)))) <> 0) = 0) Then
                    c2fbRbuAssert(StrPtr(!"i<pIter->nTblCol"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1645ULL))
                    c2fb_temp_5 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
                End If
                c2fb_temp_6 = (c2fb_temp_5)
                c2fb_temp_7 = CPtr(Const ZString Ptr, arg1->azTblCol[local12])
                local11 = c2fb_temp_7
            Else
                c2fb_temp_8 = StrPtr(!"_rowid_")
                local11 = c2fb_temp_8
            End If
        Else
            c2fb_temp_9 = CPtr(Const ZString Ptr, arg1->azTblCol[local9])
            local11 = c2fb_temp_9
        End If
        c2fb_temp_10 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s \034%w\034 COLLATE %Q"), local1, local6, local11, local10))
        local1 = c2fb_temp_10
        c2fb_temp_11 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s \034rbu_imp_%d%w\034 COLLATE %Q DESC"), local0, local6, local7, local11, local10))
        local0 = c2fb_temp_11
        c2fb_temp_12 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s quote(\034rbu_imp_%d%w\034)"), local2, local6, local7, local11))
        local2 = c2fb_temp_12
        c2fb_temp_13 = StrPtr(!", ")
        local6 = c2fb_temp_13
        c2fb_temp_14 = local7
        local7 = Cast(c2fb_c_int, (c2fb_temp_14 + 1))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    rbuFinalize(arg0, local8)
    If local5 Then
        Goto c2fb_label_0
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local13 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_15 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_16 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local13)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT %s FROM \034rbu_imp_%w\034 ORDER BY %s LIMIT 1"), local2, arg1->zTbl, local0)))
        (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
        c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local13))))) <> 0))))) Then
            c2fb_temp_17 = StrPtr(!"")
            local6 = c2fb_temp_17
            c2fb_temp_18 = Cast(c2fb_c_int, &O0ULL)
            local7 = c2fb_temp_18
            While (-Cast(c2fb_c_int, ((local7 < arg1->nCol))))
                local14 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local13, local7)))
                If (-Cast(c2fb_c_int, ((local14 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_20 = CPtr(Long Ptr, @(arg0->rc))
                    c2fb_temp_21 = Cast(c2fb_c_int, 7ULL)
                    (*c2fb_temp_20) = Cast(Long, c2fb_temp_21)
                    c2fb_temp_21 = Cast(c2fb_c_int, (*c2fb_temp_20))
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Const Byte Ptr, local14)[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 78))))) Then
                        c2fb_temp_22 = Cast(c2fb_c_int, 1ULL)
                        local5 = c2fb_temp_22
                        Goto c2fb_flow_4
                    End If
                End If
                c2fb_temp_23 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s%s"), local3, local6, local14))
                local3 = c2fb_temp_23
                c2fb_temp_24 = StrPtr(!", ")
                local6 = c2fb_temp_24
            c2fb_flow_5:
                c2fb_temp_19 = local7
                local7 = Cast(c2fb_c_int, (c2fb_temp_19 + 1))
            Wend
            c2fb_flow_4:
            If (-Cast(c2fb_c_int, (local5 = 0))) Then
                c2fb_temp_25 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"(%s) > (%s)"), local1, local3))
                local4 = c2fb_temp_25
            End If
        End If
        rbuFinalize(arg0, local13)
    End If
    c2fb_label_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
    Return local4
End Function
Private Function rbuObjIterGetIndexCols CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As ZString Ptr Ptr, ByVal arg3 As ZString Ptr Ptr, ByVal arg4 As ZString Ptr Ptr, ByVal arg5 As c2fb_c_int Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1730
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As Const ZString Ptr
    Dim local8 As Const ZString Ptr
    Dim local9 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local10 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim local12 As Const ZString Ptr
    Dim local13 As Const ZString Ptr
    Dim local14 As Const ZString Ptr
    Dim local15 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim local16 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim c2fb_temp_10 As Const ZString Ptr
    Dim c2fb_temp_11 As Const ZString Ptr
    Dim c2fb_temp_12 As Const ZString Ptr
    Dim c2fb_temp_13 As Const ZString Ptr
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As ZString Ptr
    Dim local17 As Const ZString Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Const ZString Ptr
    Dim c2fb_temp_21 As Const ZString Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int
    Dim c2fb_temp_25 As ZString Ptr
    Dim c2fb_temp_26 As ZString Ptr
    Dim c2fb_temp_27 As ZString Ptr
    Dim c2fb_temp_28 As ZString Ptr
    Dim c2fb_temp_29 As Long Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As ZString Ptr Ptr
    Dim c2fb_temp_32 As ZString Ptr
    Dim c2fb_temp_33 As ZString Ptr Ptr
    Dim c2fb_temp_34 As ZString Ptr
    Dim c2fb_temp_35 As ZString Ptr Ptr
    Dim c2fb_temp_36 As ZString Ptr
    Dim c2fb_temp_37 As c2fb_c_int Ptr
    Dim c2fb_temp_38 As c2fb_c_int

    local0 = arg0->rc
    ' C automatic storage declaration
    local2 = Cast(c2fb_c_int, &O0ULL)
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = Cast(c2fb_c_int, &O0ULL)
    local7 = StrPtr(!"")
    local8 = StrPtr(!"")
    local9 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->zErrmsg = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"p->zErrmsg==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1750ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        c2fb_temp_2 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local9)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA main.index_xinfo = %Q"), arg1->zIdx)))
        local0 = c2fb_temp_2
    End If
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local9))))) <> 0)))))
        local10 = c2fb_external_sqlite3_column_int(local9, Cast(c2fb_c_int, 1ULL))
        local11 = c2fb_external_sqlite3_column_int(local9, Cast(c2fb_c_int, 3ULL))
        local12 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local9, Cast(c2fb_c_int, 4ULL))))
        local13 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))))))) Then
            local15 = c2fb_external_sqlite3_column_int(local9, Cast(c2fb_c_int, &O0ULL))
            c2fb_temp_3 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%s(%.*s) COLLATE %Q"), local2, local7, CPtr(c2fb_RbuSpan Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol))[local15].nSpan, CPtr(c2fb_RbuSpan Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol))[local15].zSpan, local12))
            local2 = c2fb_temp_3
            c2fb_temp_4 = StrPtr(!"")
            local14 = c2fb_temp_4
        Else
            If (-Cast(c2fb_c_int, ((local10 < Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 2ULL))))) Then
                    ' C automatic storage declaration
                    c2fb_temp_5 = Cast(c2fb_c_int, &O0ULL)
                    local16 = c2fb_temp_5
                    While (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->abTblPk[local16]) = Cast(c2fb_c_int, &O0ULL)))))
                        ' empty C statement
                    c2fb_flow_3:
                        c2fb_temp_6 = local16
                        local16 = Cast(c2fb_c_int, (c2fb_temp_6 + 1))
                    Wend
                    c2fb_flow_2:
                    c2fb_temp_7 = 1
                    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local16 < arg1->nTblCol))))) = 0))) = 0)))) <> 0) = 0) Then
                        c2fbRbuAssert(StrPtr(!"i<pIter->nTblCol"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 1776ULL))
                        c2fb_temp_7 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
                    End If
                    c2fb_temp_8 = (c2fb_temp_7)
                    c2fb_temp_9 = CPtr(Const ZString Ptr, arg1->azTblCol[local16])
                    local13 = c2fb_temp_9
                Else
                    If ((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) Then
                        c2fb_temp_10 = StrPtr(!"_rowid_")
                        local13 = c2fb_temp_10
                    Else
                        c2fb_temp_11 = StrPtr(!"rbu_rowid")
                        local13 = c2fb_temp_11
                    End If
                End If
                c2fb_temp_12 = StrPtr(!"INTEGER")
                local14 = c2fb_temp_12
            Else
                c2fb_temp_13 = CPtr(Const ZString Ptr, arg1->azTblCol[local10])
                local13 = c2fb_temp_13
                c2fb_temp_14 = CPtr(Const ZString Ptr, arg1->azTblType[local10])
                local14 = c2fb_temp_14
            End If
            c2fb_temp_15 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%s\034%w\034 COLLATE %Q"), local2, local7, local13, local12))
            local2 = c2fb_temp_15
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->bUnique = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (c2fb_external_sqlite3_column_int(local9, Cast(c2fb_c_int, 5ULL)) <> 0))))) Then
            local17 = (IIf(local11, StrPtr(!" DESC"), StrPtr(!"")))
            c2fb_temp_16 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%s\034rbu_imp_%d%w\034%s"), local4, local7, local6, local13, local17))
            local4 = c2fb_temp_16
        End If
        c2fb_temp_17 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%s\034rbu_imp_%d%w\034 %s COLLATE %Q"), local3, local7, local6, local13, local14, local12))
        local3 = c2fb_temp_17
        c2fb_temp_18 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%s\034rbu_imp_%d%w\034 IS ?"), local5, local8, local6, local13))
        local5 = c2fb_temp_18
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_temp_19 = Cast(c2fb_c_int, 7ULL)
            local0 = c2fb_temp_19
        End If
        c2fb_temp_20 = StrPtr(!", ")
        local7 = c2fb_temp_20
        c2fb_temp_21 = StrPtr(!" AND ")
        local8 = c2fb_temp_21
        c2fb_temp_22 = local6
        local6 = Cast(c2fb_c_int, (c2fb_temp_22 + 1))
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_23 = c2fb_external_sqlite3_finalize(local9)
    local1 = c2fb_temp_23
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_24 = local1
        local0 = c2fb_temp_24
    End If
    If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local5))
        c2fb_temp_25 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        local2 = c2fb_temp_25
        c2fb_temp_26 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        local3 = c2fb_temp_26
        c2fb_temp_27 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        local4 = c2fb_temp_27
        c2fb_temp_28 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        local5 = c2fb_temp_28
        c2fb_temp_29 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_30 = local0
        (*c2fb_temp_29) = Cast(Long, c2fb_temp_30)
        c2fb_temp_30 = Cast(c2fb_c_int, (*c2fb_temp_29))
    End If
    c2fb_temp_31 = CPtr(ZString Ptr Ptr, @((*arg2)))
    c2fb_temp_32 = local3
    (*c2fb_temp_31) = c2fb_temp_32
    c2fb_temp_33 = CPtr(ZString Ptr Ptr, @((*arg3)))
    c2fb_temp_34 = local4
    (*c2fb_temp_33) = c2fb_temp_34
    c2fb_temp_35 = CPtr(ZString Ptr Ptr, @((*arg4)))
    c2fb_temp_36 = local5
    (*c2fb_temp_35) = c2fb_temp_36
    c2fb_temp_37 = CPtr(c2fb_c_int Ptr, @((*arg5)))
    c2fb_temp_38 = local6
    (*c2fb_temp_37) = c2fb_temp_38
    Return local2
End Function
Private Function rbuObjIterGetOldlist CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1842
    Dim local0 As ZString Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As Const ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg1->abIndexed <> 0))))) Then
        local1 = StrPtr(!"")
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_int, &O0ULL)
        local2 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local2 < arg1->nTblCol))))
            If arg1->abIndexed[local2] Then
                local3 = CPtr(Const ZString Ptr, CPtr(Const ZString Ptr, arg1->azTblCol[local2]))
                c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%s%s.\034%w\034"), local0, local1, arg2, local3))
                local0 = c2fb_temp_2
            Else
                c2fb_temp_3 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%z%sNULL"), local0, local1))
                local0 = c2fb_temp_3
            End If
            c2fb_temp_4 = StrPtr(!", ")
            local1 = c2fb_temp_4
            If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_5 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_6 = Cast(c2fb_c_int, 7ULL)
                (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local2
            local2 = Cast(c2fb_c_int, (c2fb_temp_1 + 1))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
            c2fb_temp_7 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z, %s._rowid_"), local0, arg2))
            local0 = c2fb_temp_7
        End If
    End If
    Return local0
End Function
Private Function rbuObjIterGetWhere CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1883
    Dim local0 As ZString Ptr
    Dim c2fb_temp_0 As ZString Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim local3 As Const ZString Ptr
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim local5 As Const ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As Const ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 5ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"_rowid_ = ?%d"), Cast(c2fb_c_int, (arg1->nTblCol + Cast(c2fb_c_int, 1ULL)))))
        local0 = c2fb_temp_0
    Else
        If (-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) Then
            local1 = StrPtr(!"")
            ' C automatic storage declaration
            c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
            local2 = c2fb_temp_1
            While (-Cast(c2fb_c_int, ((local2 < arg1->nTblCol))))
                If arg1->abTblPk[local2] Then
                    c2fb_temp_3 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%sc%d=?%d"), local0, local1, local2, Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))))
                    local0 = c2fb_temp_3
                    c2fb_temp_4 = StrPtr(!" AND ")
                    local1 = c2fb_temp_4
                End If
            c2fb_flow_1:
                c2fb_temp_2 = local2
                local2 = Cast(c2fb_c_int, (c2fb_temp_2 + 1))
            Wend
            c2fb_flow_0:
            c2fb_temp_5 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"_rowid_ = (SELECT id FROM rbu_imposter2 WHERE %z)"), local0))
            local0 = c2fb_temp_5
        Else
            local3 = StrPtr(!"")
            ' C automatic storage declaration
            c2fb_temp_6 = Cast(c2fb_c_int, &O0ULL)
            local4 = c2fb_temp_6
            While (-Cast(c2fb_c_int, ((local4 < arg1->nTblCol))))
                If arg1->abTblPk[local4] Then
                    local5 = CPtr(Const ZString Ptr, CPtr(Const ZString Ptr, arg1->azTblCol[local4]))
                    c2fb_temp_8 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s\034%w\034=?%d"), local0, local3, local5, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL)))))
                    local0 = c2fb_temp_8
                    c2fb_temp_9 = StrPtr(!" AND ")
                    local3 = c2fb_temp_9
                End If
            c2fb_flow_3:
                c2fb_temp_7 = local4
                local4 = Cast(c2fb_c_int, (c2fb_temp_7 + 1))
            Wend
            c2fb_flow_2:
        End If
    End If
    Return local0
End Function
Private Sub rbuBadControlError CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1924
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr

    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_1 = Cast(c2fb_c_int, 1ULL)
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
    c2fb_temp_3 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"invalid rbu_control value")))
    (*c2fb_temp_2) = c2fb_temp_3
End Sub
Private Function rbuObjIterGetSetlist CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 1947
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As Byte
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As Const ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, c2fb_crt_strlen(arg2)) <> arg1->nTblCol)))) Then
            rbuBadControlError(arg0)
        Else
            local2 = StrPtr(!"")
            c2fb_temp_0 = Cast(c2fb_c_int, &O0ULL)
            local1 = c2fb_temp_0
            While (-Cast(c2fb_c_int, ((local1 < arg1->nTblCol))))
                local3 = CPtr(Const Byte Ptr, arg2)[arg1->aiSrcOrder[local1]]
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) = Cast(c2fb_c_int, 120))))) Then
                    c2fb_temp_2 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s\034%w\034=?%d"), local0, local2, arg1->azTblCol[local1], Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))))
                    local0 = c2fb_temp_2
                    c2fb_temp_3 = StrPtr(!", ")
                    local2 = c2fb_temp_3
                Else
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) = Cast(c2fb_c_int, 100))))) Then
                        c2fb_temp_4 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s\034%w\034=rbu_delta(\034%w\034, ?%d)"), local0, local2, arg1->azTblCol[local1], arg1->azTblCol[local1], Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))))
                        local0 = c2fb_temp_4
                        c2fb_temp_5 = StrPtr(!", ")
                        local2 = c2fb_temp_5
                    Else
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local3) = Cast(c2fb_c_int, 102))))) Then
                            c2fb_temp_6 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s\034%w\034=rbu_fossil_delta(\034%w\034, ?%d)"), local0, local2, arg1->azTblCol[local1], arg1->azTblCol[local1], Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL)))))
                            local0 = c2fb_temp_6
                            c2fb_temp_7 = StrPtr(!", ")
                            local2 = c2fb_temp_7
                        End If
                    End If
                End If
            c2fb_flow_1:
                c2fb_temp_1 = local1
                local1 = Cast(c2fb_c_int, (c2fb_temp_1 + 1))
            Wend
            c2fb_flow_0:
        End If
    End If
    Return local0
End Function
Private Function rbuObjIterGetBindlist CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2001
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Byte Ptr
    Dim c2fb_temp_4 As Byte
    Dim c2fb_temp_5 As Byte Ptr
    Dim c2fb_temp_6 As Byte

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL)) * Cast(c2fb_int64, arg1))) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL))))
    c2fb_temp_0 = CPtr(ZString Ptr, CPtr(Any Ptr, rbuMalloc(arg0, local1)))
    local0 = c2fb_temp_0
    If local0 Then
        ' C automatic storage declaration
        c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
        local2 = c2fb_temp_1
        While (-Cast(c2fb_c_int, ((local2 < arg1))))
            c2fb_temp_3 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[Cast(c2fb_c_int, (local2 * Cast(c2fb_c_int, 2ULL)))]))
            c2fb_temp_4 = Cast(Byte, Cast(c2fb_c_int, 63))
            (*c2fb_temp_3) = c2fb_temp_4
            c2fb_temp_5 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[Cast(c2fb_c_int, (Cast(c2fb_c_int, (local2 * Cast(c2fb_c_int, 2ULL))) + Cast(c2fb_c_int, 1ULL)))]))
            c2fb_temp_6 = Cast(Byte, IIf(((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))) = arg1))))), Cast(c2fb_c_int, 0), Cast(c2fb_c_int, 44)))
            (*c2fb_temp_5) = c2fb_temp_6
        c2fb_flow_1:
            c2fb_temp_2 = local2
            local2 = Cast(c2fb_c_int, (c2fb_temp_2 + 1))
        Wend
        c2fb_flow_0:
    End If
    Return local0
End Function
Private Function rbuWithoutRowidPK CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2028
    Dim local0 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim local3 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim local5 As Const ZString Ptr
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim local7 As Const ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg1->zIdx = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"pIter->zIdx==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2030ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = StrPtr(!"PRIMARY KEY(")
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_3 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA main.index_list = %Q"), arg1->zTbl)))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local2))))) <> 0)))))
            local4 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local2, Cast(c2fb_c_int, 3ULL))))
            If (-Cast(c2fb_c_int, (((local4 <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_strcmp(local4, StrPtr(!"pk")) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                local5 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local2, Cast(c2fb_c_int, 1ULL))))
                If local5 Then
                    c2fb_temp_4 = CPtr(Long Ptr, @(arg0->rc))
                    c2fb_temp_5 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local3)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA main.index_xinfo = %Q"), local5)))
                    (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
                    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
                End If
                Goto c2fb_flow_0
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        rbuFinalize(arg0, local2)
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local3))))) <> 0)))))
            If c2fb_external_sqlite3_column_int(local3, Cast(c2fb_c_int, 5ULL)) Then
                local6 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local3, Cast(c2fb_c_int, 2ULL))))
                local7 = IIf(c2fb_external_sqlite3_column_int(local3, Cast(c2fb_c_int, 3ULL)), StrPtr(!" DESC"), StrPtr(!""))
                c2fb_temp_6 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s\034%w\034%s"), local0, local1, local6, local7))
                local0 = c2fb_temp_6
                c2fb_temp_7 = StrPtr(!", ")
                local1 = c2fb_temp_7
            End If
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_8 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z)"), local0))
        local0 = c2fb_temp_8
        rbuFinalize(arg0, local3)
    End If
    Return local0
End Function
Private Sub rbuCreateImposterTable2 CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2087
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_sqlite3_stmt Ptr
    Dim local4 As Const ZString Ptr
    Dim local5 As ZString Ptr
    Dim local6 As ZString Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim local10 As Const ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As Const ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        local0 = arg1->iPkTnum
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = Cast(c2fb_c_int, &O0ULL)
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = StrPtr(!"")
        local5 = Cast(c2fb_c_int, &O0ULL)
        local6 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"SELECT name FROM sqlite_schema WHERE rootpage = ?"))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_bind_int(local1, Cast(c2fb_c_int, 1ULL), local0)
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local1))))) Then
                c2fb_temp_2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local1, Cast(c2fb_c_int, &O0ULL))))
                local2 = c2fb_temp_2
            End If
        End If
        If local2 Then
            c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_4 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local3)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA main.index_xinfo = %Q"), local2)))
            (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
            c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
        End If
        rbuFinalize(arg0, local1)
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local3))))) <> 0)))))
            local7 = c2fb_external_sqlite3_column_int(local3, Cast(c2fb_c_int, 5ULL))
            If local7 Then
                local8 = c2fb_external_sqlite3_column_int(local3, Cast(c2fb_c_int, 1ULL))
                local9 = c2fb_external_sqlite3_column_int(local3, Cast(c2fb_c_int, 3ULL))
                local10 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local3, Cast(c2fb_c_int, 4ULL))))
                c2fb_temp_5 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%sc%d %s COLLATE %Q"), local5, local4, local8, arg1->azTblType[local8], local10))
                local5 = c2fb_temp_5
                c2fb_temp_6 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%sc%d%s"), local6, local4, local8, IIf(local9, StrPtr(!" DESC"), StrPtr(!""))))
                local6 = c2fb_temp_6
                c2fb_temp_7 = StrPtr(!", ")
                local4 = c2fb_temp_7
            End If
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_8 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z, id INTEGER"), local5))
        local5 = c2fb_temp_8
        rbuFinalize(arg0, local3)
        c2fb_external_sqlite3_test_control(Cast(c2fb_c_int, 25ULL), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, 1ULL), local0)
        rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"CREATE TABLE rbu_imposter2(%z, PRIMARY KEY(%z)) WITHOUT ROWID"), local5, local6)
        c2fb_external_sqlite3_test_control(Cast(c2fb_c_int, 25ULL), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    End If
End Sub
Private Sub rbuCreateImposterTable CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2161
    Dim local0 As c2fb_c_int
    Dim local1 As Const ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local4 As Const ZString Ptr
    Dim local5 As Const ZString Ptr
    Dim local6 As Const ZString Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As Const ZString Ptr
    Dim local7 As ZString Ptr
    Dim c2fb_temp_7 As ZString Ptr

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->eType <> Cast(c2fb_c_int, 5ULL))))) <> 0))))) Then
        local0 = arg1->iTnum
        local1 = StrPtr(!"")
        local2 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_external_sqlite3_test_control(Cast(c2fb_c_int, 25ULL), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL))
        c2fb_temp_0 = Cast(c2fb_c_int, &O0ULL)
        local3 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3 < arg1->nTblCol)))) <> 0)))))
            local4 = StrPtr(!"")
            local5 = CPtr(Const ZString Ptr, CPtr(Const ZString Ptr, arg1->azTblCol[local3]))
            local6 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_3 = c2fb_external_sqlite3_table_column_metadata(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), arg1->zTbl, local5, CPtr(Const ZString Ptr Ptr, 0), CPtr(Const ZString Ptr Ptr, @(local6)), CPtr(c2fb_c_int Ptr, 0), CPtr(c2fb_c_int Ptr, 0), CPtr(c2fb_c_int Ptr, 0))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso (arg1->abTblPk[local3] <> 0))))) Then
                c2fb_temp_4 = StrPtr(!"PRIMARY KEY ")
                local4 = c2fb_temp_4
            End If
            c2fb_temp_5 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z%s\034%w\034 %s %sCOLLATE %Q%s"), local2, local1, local5, arg1->azTblType[local3], local4, local6, (IIf(arg1->abNotNull[local3], StrPtr(!" NOT NULL"), StrPtr(!"")))))
            local2 = c2fb_temp_5
            c2fb_temp_6 = StrPtr(!", ")
            local1 = c2fb_temp_6
        c2fb_flow_1:
            c2fb_temp_1 = local3
            local3 = Cast(c2fb_c_int, (c2fb_temp_1 + 1))
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 4ULL))))) Then
            local7 = CPtr(ZString Ptr, rbuWithoutRowidPK(arg0, arg1))
            If local7 Then
                c2fb_temp_7 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%z, %z"), local2, local7))
                local2 = c2fb_temp_7
            End If
        End If
        c2fb_external_sqlite3_test_control(Cast(c2fb_c_int, 25ULL), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, 1ULL), local0)
        rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"CREATE TABLE \034rbu_imp_%w\034(%z)%s"), arg1->zTbl, local2, (IIf((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 4ULL))))), StrPtr(!" WITHOUT ROWID"), StrPtr(!""))))
        c2fb_external_sqlite3_test_control(Cast(c2fb_c_int, 25ULL), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
    End If
End Sub
Private Sub rbuObjIterPrepareTmpInsert CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Const ZString Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2217
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL))))) <> 0))))))
    local1 = CPtr(ZString Ptr, rbuObjIterGetBindlist(arg0, Cast(c2fb_c_int, (Cast(c2fb_c_int, (arg1->nTblCol + Cast(c2fb_c_int, 1ULL))) + local0))))
    If local1 Then
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg1->pTmpInsert) = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"pIter->pTmpInsert==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2226ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_3 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pTmpInsert)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"INSERT INTO %s.'rbu_tmp_%q'(rbu_control,%s%s) VALUES(%z)"), CPtr(ZString Ptr, (@arg0->zStateDb(0))), arg1->zDataTbl, arg2, arg3, local1)))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    End If
End Sub
Private Sub rbuTmpInsertFunc CDecl (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2235
    Dim local0 As c2fb_sqlite3rbu Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_i64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = CPtr(c2fb_sqlite3rbu Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_user_data(arg0)))
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_int(arg2[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->objiter.eType = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->objiter.eType = Cast(c2fb_c_int, 1ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"sqlite3_value_int(apVal[0])!=0 || p->objiter.eType==RBU_PK_EXTERNAL || p->objiter.eType==RBU_PK_NONE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2244ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_int(arg2[Cast(c2fb_c_int, &O0ULL)]) <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = CPtr(c2fb_i64 Ptr, @(local0->nPhaseOneStep))
        c2fb_temp_3 = Cast(c2fb_int64, ((*c2fb_temp_2) + Cast(c2fb_int64, local0->objiter.nIndex)))
        (*c2fb_temp_2) = Cast(c2fb_i64, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_int64, (*c2fb_temp_2))
    End If
    c2fb_temp_4 = Cast(c2fb_c_int, &O0ULL)
    local2 = c2fb_temp_4
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 < arg1)))) <> 0)))))
        c2fb_temp_6 = c2fb_external_sqlite3_bind_value(CPtr(c2fb_sqlite3_stmt Ptr, local0->objiter.pTmpInsert), Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL))), CPtr(Const c2fb_sqlite3_value Ptr, arg2[local2]))
        local1 = c2fb_temp_6
    c2fb_flow_1:
        c2fb_temp_5 = local2
        local2 = Cast(c2fb_c_int, (c2fb_temp_5 + 1))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_step(CPtr(c2fb_sqlite3_stmt Ptr, local0->objiter.pTmpInsert))
        c2fb_temp_7 = c2fb_external_sqlite3_reset(CPtr(c2fb_sqlite3_stmt Ptr, local0->objiter.pTmpInsert))
        local1 = c2fb_temp_7
    End If
    If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_error_code(arg0, local1)
    End If
End Sub
Private Function rbuObjIterGetIndexWhere CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr) As ZString Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2265
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As ZString Ptr
    Dim c2fb_temp_4 As ZString Ptr
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local9 As Byte
    Dim local10 As c2fb_RbuSpan Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_RbuSpan_ Ptr Ptr
    Dim c2fb_temp_11 As c2fb_RbuSpan Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Const ZString Ptr Ptr
    Dim c2fb_temp_16 As Const ZString Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As Long Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim local12 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As Long Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Const ZString Ptr Ptr
    Dim c2fb_temp_27 As Const ZString Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As c2fb_c_int
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As ZString Ptr
    Dim c2fb_temp_39 As Long Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As c2fb_c_int
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As Long Ptr
    Dim c2fb_temp_44 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = arg0->rc
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->zIdxSql = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->nIdxCol = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"pIter->zIdxSql==0 && pIter->nIdxCol==0 && pIter->aIdxCol==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2270ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"SELECT trim(sql) FROM sqlite_schema WHERE type='index' AND name=?"))
        local1 = c2fb_temp_2
    End If
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_temp_3 = c2fb_external_sqlite3_bind_text(local0, Cast(c2fb_c_int, 1ULL), arg1->zIdx, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), CPtr(c2fb_sqlite3_destructor_type, 0))
        local1 = c2fb_temp_3
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local0))))) <> 0))))) Then
            local4 = CPtr(ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local0, Cast(c2fb_c_int, &O0ULL))))
            If local4 Then
                c2fb_temp_5 = CPtr(ZString Ptr Ptr, @(arg1->zIdxSql))
                c2fb_temp_4 = CPtr(ZString Ptr, rbuStrndup(CPtr(Const ZString Ptr, local4), CPtr(c2fb_c_int Ptr, @(local1))))
                local4 = c2fb_temp_4
                c2fb_temp_6 = c2fb_temp_4
                (*c2fb_temp_5) = c2fb_temp_6
            End If
            If local4 Then
                local5 = Cast(c2fb_c_int, &O0ULL)
                ' C automatic storage declaration
                local7 = Cast(c2fb_c_int, &O0ULL)
                local8 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_7 = Cast(c2fb_c_int, &O0ULL)
                local6 = c2fb_temp_7
                While CPtr(Byte Ptr, local4)[local6]
                    local9 = CPtr(Byte Ptr, local4)[local6]
                    If (-Cast(c2fb_c_int, ((local7 >= (Cast(c2fb_c_int, (local8 - Cast(c2fb_c_int, 1ULL)))))))) Then
                        local10 = CPtr(c2fb_RbuSpan Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol)), Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local8) * Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(c2fb_RbuSpan))))) + Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, 16ULL)) * Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(c2fb_RbuSpan))))))))))
                        If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_9 = Cast(c2fb_c_int, 7ULL)
                            local1 = c2fb_temp_9
                            Goto c2fb_flow_0
                        End If
                        c2fb_temp_10 = CPtr(c2fb_RbuSpan_ Ptr Ptr, @(arg1->aIdxCol))
                        c2fb_temp_11 = local10
                        (*c2fb_temp_10) = CPtr(c2fb_RbuSpan_ Ptr, c2fb_temp_11)
                        c2fb_temp_11 = CPtr(c2fb_RbuSpan Ptr, (*c2fb_temp_10))
                        c2fb_temp_12 = Cast(c2fb_c_int, (local8 + Cast(c2fb_c_int, 16ULL)))
                        local8 = c2fb_temp_12
                    End If
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 40))))) Then
                        If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_13 = 1
                            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
                                c2fbRbuAssert(StrPtr(!"iIdxCol==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2308ULL))
                                c2fb_temp_13 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
                            End If
                            c2fb_temp_14 = (c2fb_temp_13)
                            c2fb_temp_15 = CPtr(Const ZString Ptr Ptr, @(CPtr(c2fb_RbuSpan Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol))[Cast(c2fb_c_int, &O0ULL)].zSpan))
                            c2fb_temp_16 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local4)[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))])))
                            (*c2fb_temp_15) = c2fb_temp_16
                        End If
                        c2fb_temp_17 = local5
                        local5 = Cast(c2fb_c_int, (c2fb_temp_17 + 1))
                    Else
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 41))))) Then
                            c2fb_temp_18 = local5
                            local5 = Cast(c2fb_c_int, (c2fb_temp_18 - 1))
                            If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
                                local11 = Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local4)[local6]))) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, CPtr(c2fb_RbuSpan Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol))[local7].zSpan)))))
                                c2fb_temp_19 = local7
                                local7 = Cast(c2fb_c_int, (c2fb_temp_19 + 1))
                                c2fb_temp_20 = CPtr(Long Ptr, @(CPtr(c2fb_RbuSpan Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol))[c2fb_temp_19].nSpan))
                                c2fb_temp_21 = local11
                                (*c2fb_temp_20) = Cast(Long, c2fb_temp_21)
                                c2fb_temp_21 = Cast(c2fb_c_int, (*c2fb_temp_20))
                                c2fb_temp_22 = local6
                                local6 = Cast(c2fb_c_int, (c2fb_temp_22 + 1))
                                Goto c2fb_flow_0
                            End If
                        Else
                            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 44))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                                local12 = Cast(c2fb_c_int, ((CPtr(Byte Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local4)[local6]))) - CPtr(Byte Ptr, CPtr(Const Byte Ptr, CPtr(c2fb_RbuSpan Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol))[local7].zSpan)))))
                                c2fb_temp_23 = local7
                                local7 = Cast(c2fb_c_int, (c2fb_temp_23 + 1))
                                c2fb_temp_24 = CPtr(Long Ptr, @(CPtr(c2fb_RbuSpan Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol))[c2fb_temp_23].nSpan))
                                c2fb_temp_25 = local12
                                (*c2fb_temp_24) = Cast(Long, c2fb_temp_25)
                                c2fb_temp_25 = Cast(c2fb_c_int, (*c2fb_temp_24))
                                c2fb_temp_26 = CPtr(Const ZString Ptr Ptr, @(CPtr(c2fb_RbuSpan Ptr, CPtr(c2fb_RbuSpan Ptr, arg1->aIdxCol))[local7].zSpan))
                                c2fb_temp_27 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local4)[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))])))
                                (*c2fb_temp_26) = c2fb_temp_27
                            Else
                                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 34))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 39))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 96))))) <> 0))))) Then
                                    c2fb_temp_28 = local6
                                    local6 = Cast(c2fb_c_int, (c2fb_temp_28 + 1))
                                    While Cast(c2fb_c_int, 1ULL)
                                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[local6]) = Cast(c2fb_c_int, local9))))) Then
                                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))]) <> Cast(c2fb_c_int, local9))))) Then
                                                Goto c2fb_flow_2
                                            End If
                                            c2fb_temp_30 = local6
                                            local6 = Cast(c2fb_c_int, (c2fb_temp_30 + 1))
                                        End If
                                    c2fb_flow_3:
                                        c2fb_temp_29 = local6
                                        local6 = Cast(c2fb_c_int, (c2fb_temp_29 + 1))
                                    Wend
                                    c2fb_flow_2:
                                Else
                                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 91))))) Then
                                        c2fb_temp_31 = local6
                                        local6 = Cast(c2fb_c_int, (c2fb_temp_31 + 1))
                                        While Cast(c2fb_c_int, 1ULL)
                                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[local6]) = Cast(c2fb_c_int, 93))))) Then
                                                Goto c2fb_flow_4
                                            End If
                                        c2fb_flow_5:
                                            c2fb_temp_32 = local6
                                            local6 = Cast(c2fb_c_int, (c2fb_temp_32 + 1))
                                        Wend
                                        c2fb_flow_4:
                                    Else
                                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 45))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 45))))) <> 0))))) Then
                                            c2fb_temp_33 = Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 2ULL)))
                                            local6 = c2fb_temp_33
                                            While (-Cast(c2fb_c_int, (((CPtr(Byte Ptr, local4)[local6] <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[local6]) <> Cast(c2fb_c_int, 10))))) <> 0)))))
                                                ' empty C statement
                                            c2fb_flow_7:
                                                c2fb_temp_34 = local6
                                                local6 = Cast(c2fb_c_int, (c2fb_temp_34 + 1))
                                            Wend
                                            c2fb_flow_6:
                                            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[local6]) = Cast(c2fb_c_int, 0))))) Then
                                                Goto c2fb_flow_0
                                            End If
                                        Else
                                            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local9) = Cast(c2fb_c_int, 47))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))]) = Cast(c2fb_c_int, 42))))) <> 0))))) Then
                                                c2fb_temp_35 = Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 2ULL)))
                                                local6 = c2fb_temp_35
                                                While (-Cast(c2fb_c_int, (((CPtr(Byte Ptr, local4)[local6] <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[local6]) <> Cast(c2fb_c_int, 42))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))]) <> Cast(c2fb_c_int, 47))))) <> 0)))))) <> 0)))))
                                                    ' empty C statement
                                                c2fb_flow_9:
                                                    c2fb_temp_36 = local6
                                                    local6 = Cast(c2fb_c_int, (c2fb_temp_36 + 1))
                                                Wend
                                                c2fb_flow_8:
                                                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, local4)[local6]) = Cast(c2fb_c_int, 0))))) Then
                                                    Goto c2fb_flow_0
                                                End If
                                                c2fb_temp_37 = local6
                                                local6 = Cast(c2fb_c_int, (c2fb_temp_37 + 1))
                                            End If
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    End If
                c2fb_flow_1:
                    c2fb_temp_8 = local6
                    local6 = Cast(c2fb_c_int, (c2fb_temp_8 + 1))
                Wend
                c2fb_flow_0:
                If CPtr(Byte Ptr, local4)[local6] Then
                    c2fb_temp_38 = CPtr(ZString Ptr, rbuStrndup(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local4)[local6]))), CPtr(c2fb_c_int Ptr, @(local1))))
                    local2 = c2fb_temp_38
                End If
                c2fb_temp_39 = CPtr(Long Ptr, @(arg1->nIdxCol))
                c2fb_temp_40 = local7
                (*c2fb_temp_39) = Cast(Long, c2fb_temp_40)
                c2fb_temp_40 = Cast(c2fb_c_int, (*c2fb_temp_39))
            End If
        End If
        c2fb_temp_41 = c2fb_external_sqlite3_finalize(local0)
        local3 = c2fb_temp_41
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_42 = local3
            local1 = c2fb_temp_42
        End If
    End If
    c2fb_temp_43 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_44 = local1
    (*c2fb_temp_43) = Cast(Long, c2fb_temp_44)
    c2fb_temp_44 = Cast(c2fb_c_int, (*c2fb_temp_43))
    Return local2
End Function
Private Function rbuObjIterPrepareAll CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2365
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim local1 As ZString Ptr
    Dim local2 As ZString Ptr Ptr
    Dim local3 As Const ZString Ptr
    Dim local4 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local5 As Const ZString Ptr
    Dim local6 As ZString Ptr
    Dim local7 As ZString Ptr
    Dim local8 As ZString Ptr
    Dim local9 As ZString Ptr
    Dim local10 As ZString Ptr
    Dim local11 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim local12 As ZString Ptr
    Dim local13 As ZString Ptr
    Dim c2fb_temp_16 As ZString Ptr
    Dim c2fb_temp_17 As ZString Ptr
    Dim c2fb_temp_18 As ZString Ptr
    Dim c2fb_temp_19 As ZString Ptr
    Dim c2fb_temp_20 As ZString Ptr
    Dim c2fb_temp_21 As Long Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim local14 As c2fb_c_int
    Dim local15 As Const ZString Ptr
    Dim local16 As Const ZString Ptr
    Dim local17 As ZString Ptr
    Dim local18 As ZString Ptr
    Dim local19 As ZString Ptr
    Dim local20 As ZString Ptr
    Dim c2fb_temp_23 As ZString Ptr
    Dim c2fb_temp_24 As Long Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Const ZString Ptr
    Dim c2fb_temp_27 As Long Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As Long Ptr
    Dim c2fb_temp_30 As c2fb_c_int
    Dim local21 As Const ZString Ptr
    Dim c2fb_temp_31 As Const ZString Ptr
    Dim local22 As Const ZString Ptr
    Dim local23 As ZString Ptr
    Dim local24 As ZString Ptr
    Dim c2fb_temp_32 As Const ZString Ptr
    Dim c2fb_temp_33 As ZString Ptr
    Dim c2fb_temp_34 As ZString Ptr
    Dim c2fb_temp_35 As ZString Ptr
    Dim c2fb_temp_36 As ZString Ptr
    Dim c2fb_temp_37 As Long Ptr
    Dim c2fb_temp_38 As c2fb_c_int

    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg1->bCleanup = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"pIter->bCleanup==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2370ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3_stmt Ptr, arg1->pSelect) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((rbuObjIterCacheTableInfo(arg0, arg1) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        local0 = arg1->iTnum
        local1 = Cast(c2fb_c_int, &O0ULL)
        local2 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
        local3 = arg1->zIdx
        local4 = Cast(c2fb_c_int, &O0ULL)
        If arg2 Then
            c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!" LIMIT -1 OFFSET %d"), arg2))
            local4 = c2fb_temp_2
            If (-Cast(c2fb_c_int, (local4 = 0))) Then
                c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_4 = Cast(c2fb_c_int, 7ULL)
                (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
                c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
            End If
        End If
        If local3 Then
            local5 = arg1->zTbl
            local6 = Cast(c2fb_c_int, &O0ULL)
            local7 = Cast(c2fb_c_int, &O0ULL)
            local8 = Cast(c2fb_c_int, &O0ULL)
            local9 = Cast(c2fb_c_int, &O0ULL)
            local10 = Cast(c2fb_c_int, &O0ULL)
            local11 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_5 = 1
            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg1->eType <> Cast(c2fb_c_int, 5ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
                c2fbRbuAssert(StrPtr(!"pIter->eType!=RBU_PK_VTAB"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2392ULL))
                c2fb_temp_5 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
            End If
            c2fb_temp_6 = (c2fb_temp_5)
            c2fb_temp_7 = CPtr(ZString Ptr, rbuObjIterGetIndexWhere(arg0, arg1))
            local10 = c2fb_temp_7
            c2fb_temp_8 = CPtr(ZString Ptr, rbuObjIterGetIndexCols(arg0, arg1, CPtr(ZString Ptr Ptr, @(local6)), CPtr(ZString Ptr Ptr, @(local7)), CPtr(ZString Ptr Ptr, @(local8)), CPtr(c2fb_c_int Ptr, @(local11))))
            local1 = c2fb_temp_8
            c2fb_temp_9 = CPtr(ZString Ptr, rbuObjIterGetBindlist(arg0, local11))
            local9 = c2fb_temp_9
            c2fb_external_sqlite3_test_control(Cast(c2fb_c_int, 25ULL), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, 1ULL))
            c2fb_external_sqlite3_test_control(Cast(c2fb_c_int, 25ULL), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, 1ULL), local0)
            rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"CREATE TABLE \034rbu_imp_%w\034( %s, PRIMARY KEY( %s ) ) WITHOUT ROWID"), local5, local6, local7)
            c2fb_external_sqlite3_test_control(Cast(c2fb_c_int, 25ULL), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, &O0ULL))
            c2fb_temp_10 = CPtr(Long Ptr, @(arg1->nCol))
            c2fb_temp_11 = local11
            (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_12 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_13 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pInsert)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"INSERT INTO \034rbu_imp_%w\034 VALUES(%s)"), local5, local9)))
                (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
                c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_14 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_15 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pDelete)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"DELETE FROM \034rbu_imp_%w\034 WHERE %s"), local5, local8)))
                (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
            End If
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                ' C automatic storage declaration
                If ((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) Then
                    local13 = Cast(c2fb_c_int, &O0ULL)
                    If arg2 Then
                        c2fb_temp_16 = CPtr(ZString Ptr, rbuVacuumIndexStart(arg0, arg1))
                        local13 = c2fb_temp_16
                        If local13 Then
                            c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
                            c2fb_temp_17 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
                            local4 = c2fb_temp_17
                        End If
                    End If
                    c2fb_temp_18 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT %s, 0 AS rbu_control FROM '%q' %s %s %s ORDER BY %s%s"), local1, arg1->zDataTbl, local10, (IIf(local13, (IIf(local10, StrPtr(!"AND"), StrPtr(!"WHERE"))), StrPtr(!""))), local13, local1, local4))
                    local12 = c2fb_temp_18
                    c2fb_external_sqlite3_free(CPtr(Any Ptr, local13))
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                        c2fb_temp_19 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT %s, rbu_control FROM %s.'rbu_tmp_%q' %s ORDER BY %s%s"), local1, CPtr(ZString Ptr, (@arg0->zStateDb(0))), arg1->zDataTbl, local10, local1, local4))
                        local12 = c2fb_temp_19
                    Else
                        c2fb_temp_20 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT %s, rbu_control FROM %s.'rbu_tmp_%q' %s UNION ALL SELECT %s, rbu_control FROM '%q' %s %s typeof(rbu_control)='integer' AND rbu_control!=1 ORDER BY %s%s"), local1, CPtr(ZString Ptr, (@arg0->zStateDb(0))), arg1->zDataTbl, local10, local1, arg1->zDataTbl, local10, (IIf(local10, StrPtr(!"AND"), StrPtr(!"WHERE"))), local1, local4))
                        local12 = c2fb_temp_20
                    End If
                End If
                If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_21 = CPtr(Long Ptr, @(arg0->rc))
                    c2fb_temp_22 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pSelect)), local2, local12)
                    (*c2fb_temp_21) = Cast(Long, c2fb_temp_22)
                    c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
                Else
                    c2fb_external_sqlite3_free(CPtr(Any Ptr, local12))
                End If
            End If
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local6))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local7))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local8))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local9))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local10))
        Else
            local14 = (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 5ULL)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL)))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0)))))) <> 0)))))
            local15 = arg1->zTbl
            ' C automatic storage declaration
            local17 = CPtr(ZString Ptr, rbuObjIterGetBindlist(arg0, Cast(c2fb_c_int, (arg1->nTblCol + local14))))
            local18 = CPtr(ZString Ptr, rbuObjIterGetWhere(arg0, arg1))
            local19 = CPtr(ZString Ptr, rbuObjIterGetOldlist(arg0, arg1, StrPtr(!"old")))
            local20 = CPtr(ZString Ptr, rbuObjIterGetOldlist(arg0, arg1, StrPtr(!"new")))
            c2fb_temp_23 = CPtr(ZString Ptr, rbuObjIterGetCollist(arg0, arg1))
            local1 = c2fb_temp_23
            c2fb_temp_24 = CPtr(Long Ptr, @(arg1->nCol))
            c2fb_temp_25 = arg1->nTblCol
            (*c2fb_temp_24) = Cast(Long, c2fb_temp_25)
            c2fb_temp_25 = Cast(c2fb_c_int, (*c2fb_temp_24))
            rbuCreateImposterTable(arg0, arg1)
            rbuCreateImposterTable2(arg0, arg1)
            c2fb_temp_26 = (IIf((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 5ULL))))), StrPtr(!""), StrPtr(!"rbu_imp_")))
            local16 = c2fb_temp_26
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_27 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_28 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pInsert)), local2, CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"INSERT INTO \034%s%w\034(%s%s) VALUES(%s)"), local16, local15, local1, (IIf(local14, StrPtr(!", _rowid_"), StrPtr(!""))), local17)))
                (*c2fb_temp_27) = Cast(Long, c2fb_temp_28)
                c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_29 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_30 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pDelete)), local2, CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"DELETE FROM \034%s%w\034 WHERE %s"), local16, local15, local18)))
                (*c2fb_temp_29) = Cast(Long, c2fb_temp_30)
                c2fb_temp_30 = Cast(c2fb_c_int, (*c2fb_temp_29))
            End If
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (arg1->abIndexed <> 0))))) Then
                local21 = StrPtr(!"")
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                    c2fb_temp_31 = StrPtr(!", rbu_rowid")
                    local21 = c2fb_temp_31
                End If
                rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"CREATE TABLE IF NOT EXISTS %s.'rbu_tmp_%q' AS SELECT *%s FROM '%q' WHERE 0;"), CPtr(ZString Ptr, (@arg0->zStateDb(0))), arg1->zDataTbl, (IIf((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))), StrPtr(!", 0 AS rbu_rowid"), StrPtr(!""))), arg1->zDataTbl)
                rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"CREATE TEMP TRIGGER rbu_delete_tr BEFORE DELETE ON \034%s%w\034 BEGIN   SELECT rbu_tmp_insert(3, %s);END;CREATE TEMP TRIGGER rbu_update1_tr BEFORE UPDATE ON \034%s%w\034 BEGIN   SELECT rbu_tmp_insert(3, %s);END;CREATE TEMP TRIGGER rbu_update2_tr AFTER UPDATE ON \034%s%w\034 BEGIN   SELECT rbu_tmp_insert(4, %s);END;"), local16, local15, local19, local16, local15, local19, local16, local15, local20)
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1->eType = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                    rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"CREATE TEMP TRIGGER rbu_insert_tr AFTER INSERT ON \034%s%w\034 BEGIN   SELECT rbu_tmp_insert(0, %s);END;"), local16, local15, local20)
                End If
                rbuObjIterPrepareTmpInsert(arg0, arg1, CPtr(Const ZString Ptr, local1), local21)
            End If
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                local22 = StrPtr(!"")
                local23 = Cast(c2fb_c_int, &O0ULL)
                local24 = Cast(c2fb_c_int, &O0ULL)
                If local14 Then
                    c2fb_temp_32 = IIf(((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), StrPtr(!",_rowid_ "), StrPtr(!",rbu_rowid"))
                    local22 = c2fb_temp_32
                End If
                If ((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) Then
                    If arg2 Then
                        c2fb_temp_33 = CPtr(ZString Ptr, rbuVacuumTableStart(arg0, arg1, local14, local16))
                        local23 = c2fb_temp_33
                        If local23 Then
                            c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
                            c2fb_temp_34 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
                            local4 = c2fb_temp_34
                        End If
                    End If
                    If local14 Then
                        c2fb_temp_35 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"_rowid_")))
                        local24 = c2fb_temp_35
                    Else
                        c2fb_temp_36 = CPtr(ZString Ptr, rbuObjIterGetPkList(arg0, arg1, StrPtr(!""), StrPtr(!", "), StrPtr(!"")))
                        local24 = c2fb_temp_36
                    End If
                End If
                If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_37 = CPtr(Long Ptr, @(arg0->rc))
                    c2fb_temp_38 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(arg1->pSelect)), local2, CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT %s,%s rbu_control%s FROM '%q'%s %s %s %s"), local1, (IIf(((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), StrPtr(!"0 AS "), StrPtr(!""))), local22, arg1->zDataTbl, (IIf(local23, CPtr(Const ZString Ptr, local23), StrPtr(!""))), (IIf(local24, StrPtr(!"ORDER BY"), StrPtr(!""))), local24, local4)))
                    (*c2fb_temp_37) = Cast(Long, c2fb_temp_38)
                    c2fb_temp_38 = Cast(c2fb_c_int, (*c2fb_temp_37))
                End If
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local23))
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local24))
            End If
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local18))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local19))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local20))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local17))
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local1))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
    End If
    Return arg0->rc
End Function
Private Function rbuGetUpdateStmt CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuObjIter Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_sqlite3_stmt Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2632
    Dim local0 As c2fb_RbuUpdateStmt Ptr Ptr
    Dim local1 As c2fb_RbuUpdateStmt Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_sqlite3_stmt Ptr Ptr
    Dim c2fb_temp_1 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_2 As c2fb_RbuUpdateStmt Ptr Ptr
    Dim c2fb_temp_3 As c2fb_RbuUpdateStmt Ptr Ptr
    Dim c2fb_temp_4 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_5 As c2fb_RbuUpdateStmt Ptr Ptr
    Dim c2fb_temp_6 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_7 As c2fb_RbuUpdateStmt_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_9 As c2fb_RbuUpdateStmt_ Ptr Ptr
    Dim c2fb_temp_10 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_11 As c2fb_sqlite3_stmt Ptr Ptr
    Dim c2fb_temp_12 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_RbuUpdateStmt Ptr Ptr
    Dim c2fb_temp_17 As c2fb_RbuUpdateStmt Ptr Ptr
    Dim c2fb_temp_18 As c2fb_RbuUpdateStmt Ptr Ptr
    Dim c2fb_temp_19 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_20 As c2fb_sqlite3_stmt_ Ptr Ptr
    Dim c2fb_temp_21 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_22 As c2fb_RbuUpdateStmt Ptr
    Dim local3 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim c2fb_temp_23 As ZString Ptr Ptr
    Dim c2fb_temp_24 As ZString Ptr
    Dim c2fb_temp_25 As c2fb_RbuUpdateStmt_ Ptr Ptr
    Dim c2fb_temp_26 As c2fb_RbuUpdateStmt Ptr
    Dim c2fb_temp_27 As c2fb_RbuUpdateStmt_ Ptr Ptr
    Dim c2fb_temp_28 As c2fb_RbuUpdateStmt Ptr
    Dim local6 As Const ZString Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As Any Ptr
    Dim c2fb_temp_32 As Const ZString Ptr
    Dim c2fb_temp_33 As ZString Ptr
    Dim c2fb_temp_34 As Long Ptr
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As c2fb_sqlite3_stmt Ptr Ptr
    Dim c2fb_temp_37 As c2fb_sqlite3_stmt Ptr

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_sqlite3_stmt Ptr Ptr, @((*arg3)))
    c2fb_temp_1 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(c2fb_RbuUpdateStmt Ptr Ptr, @(arg1->pRbuUpdate))
    local0 = c2fb_temp_2
    While (*local0)
        c2fb_temp_4 = (*local0)
        local1 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((c2fb_crt_strcmp(CPtr(Const ZString Ptr, local1->zMask), arg2) = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_5 = CPtr(c2fb_RbuUpdateStmt Ptr Ptr, @((*local0)))
            c2fb_temp_6 = CPtr(c2fb_RbuUpdateStmt Ptr, local1->pNext)
            (*c2fb_temp_5) = c2fb_temp_6
            c2fb_temp_7 = CPtr(c2fb_RbuUpdateStmt_ Ptr Ptr, @(local1->pNext))
            c2fb_temp_8 = CPtr(c2fb_RbuUpdateStmt Ptr, arg1->pRbuUpdate)
            (*c2fb_temp_7) = CPtr(c2fb_RbuUpdateStmt_ Ptr, c2fb_temp_8)
            c2fb_temp_8 = CPtr(c2fb_RbuUpdateStmt Ptr, (*c2fb_temp_7))
            c2fb_temp_9 = CPtr(c2fb_RbuUpdateStmt_ Ptr Ptr, @(arg1->pRbuUpdate))
            c2fb_temp_10 = local1
            (*c2fb_temp_9) = CPtr(c2fb_RbuUpdateStmt_ Ptr, c2fb_temp_10)
            c2fb_temp_10 = CPtr(c2fb_RbuUpdateStmt Ptr, (*c2fb_temp_9))
            c2fb_temp_11 = CPtr(c2fb_sqlite3_stmt Ptr Ptr, @((*arg3)))
            c2fb_temp_12 = CPtr(c2fb_sqlite3_stmt Ptr, local1->pUpdate)
            (*c2fb_temp_11) = c2fb_temp_12
            Return Cast(c2fb_c_int, &O0ULL)
        End If
        c2fb_temp_13 = local2
        local2 = Cast(c2fb_c_int, (c2fb_temp_13 + 1))
    c2fb_flow_1:
        c2fb_temp_3 = CPtr(c2fb_RbuUpdateStmt Ptr Ptr, @((((*local0))->pNext)))
        local0 = c2fb_temp_3
    Wend
    c2fb_flow_0:
    c2fb_temp_14 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((CPtr(c2fb_RbuUpdateStmt Ptr, local1->pNext) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"pUp==0 || pUp->pNext==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2660ULL))
        c2fb_temp_14 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_15 = (c2fb_temp_14)
    If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, 16ULL))))) Then
        c2fb_temp_16 = CPtr(c2fb_RbuUpdateStmt Ptr Ptr, @(arg1->pRbuUpdate))
        local0 = c2fb_temp_16
        While (-Cast(c2fb_c_int, (((*local0) <> local1))))
            ' empty C statement
        c2fb_flow_3:
            c2fb_temp_17 = CPtr(c2fb_RbuUpdateStmt Ptr Ptr, @((((*local0))->pNext)))
            local0 = c2fb_temp_17
        Wend
        c2fb_flow_2:
        c2fb_temp_18 = CPtr(c2fb_RbuUpdateStmt Ptr Ptr, @((*local0)))
        c2fb_temp_19 = CPtr(_c2fb_record_c2fb_RbuUpdateStmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_18) = c2fb_temp_19
        c2fb_external_sqlite3_finalize(CPtr(c2fb_sqlite3_stmt Ptr, local1->pUpdate))
        c2fb_temp_20 = CPtr(c2fb_sqlite3_stmt_ Ptr Ptr, @(local1->pUpdate))
        c2fb_temp_21 = CPtr(c2fb_sqlite3_stmt Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_20) = CPtr(c2fb_sqlite3_stmt_ Ptr, c2fb_temp_21)
        c2fb_temp_21 = CPtr(c2fb_sqlite3_stmt Ptr, (*c2fb_temp_20))
    Else
        c2fb_temp_22 = CPtr(c2fb_RbuUpdateStmt Ptr, CPtr(Any Ptr, rbuMalloc(arg0, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(c2fb_RbuUpdateStmt))) + Cast(c2fb_c_uint, arg1->nTblCol))) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))))))
        local1 = c2fb_temp_22
    End If
    If local1 Then
        local3 = CPtr(ZString Ptr, rbuObjIterGetWhere(arg0, arg1))
        local4 = CPtr(ZString Ptr, rbuObjIterGetSetlist(arg0, arg1, arg2))
        local5 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_23 = CPtr(ZString Ptr Ptr, @(local1->zMask))
        c2fb_temp_24 = CPtr(ZString Ptr, CPtr(c2fb_RbuUpdateStmt Ptr, @(CPtr(c2fb_RbuUpdateStmt Ptr, local1)[Cast(c2fb_c_int, 1ULL)])))
        (*c2fb_temp_23) = c2fb_temp_24
        c2fb_temp_25 = CPtr(c2fb_RbuUpdateStmt_ Ptr Ptr, @(local1->pNext))
        c2fb_temp_26 = CPtr(c2fb_RbuUpdateStmt Ptr, arg1->pRbuUpdate)
        (*c2fb_temp_25) = CPtr(c2fb_RbuUpdateStmt_ Ptr, c2fb_temp_26)
        c2fb_temp_26 = CPtr(c2fb_RbuUpdateStmt Ptr, (*c2fb_temp_25))
        c2fb_temp_27 = CPtr(c2fb_RbuUpdateStmt_ Ptr Ptr, @(arg1->pRbuUpdate))
        c2fb_temp_28 = local1
        (*c2fb_temp_27) = CPtr(c2fb_RbuUpdateStmt_ Ptr, c2fb_temp_28)
        c2fb_temp_28 = CPtr(c2fb_RbuUpdateStmt Ptr, (*c2fb_temp_27))
        If local4 Then
            local6 = StrPtr(!"")
            c2fb_temp_29 = 1
            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
                c2fbRbuAssert(StrPtr(!"p->rc==SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2682ULL))
                c2fb_temp_29 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
            End If
            c2fb_temp_30 = (c2fb_temp_29)
            c2fb_temp_31 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local1->zMask), CPtr(Const Any Ptr, arg2), arg1->nTblCol))
            If (-Cast(c2fb_c_int, ((arg1->eType <> Cast(c2fb_c_int, 5ULL))))) Then
                c2fb_temp_32 = StrPtr(!"rbu_imp_")
                local6 = c2fb_temp_32
            End If
            c2fb_temp_33 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"UPDATE \034%s%w\034 SET %s WHERE %s"), local6, arg1->zTbl, local4, local3))
            local5 = c2fb_temp_33
            c2fb_temp_34 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_35 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1->pUpdate)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), local5)
            (*c2fb_temp_34) = Cast(Long, c2fb_temp_35)
            c2fb_temp_35 = Cast(c2fb_c_int, (*c2fb_temp_34))
            c2fb_temp_36 = CPtr(c2fb_sqlite3_stmt Ptr Ptr, @((*arg3)))
            c2fb_temp_37 = CPtr(c2fb_sqlite3_stmt Ptr, local1->pUpdate)
            (*c2fb_temp_36) = c2fb_temp_37
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
    End If
    Return arg0->rc
End Function
Private Function rbuOpenDbhandle CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_sqlite3 Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2700
    Dim local0 As c2fb_sqlite3 Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As c2fb_sqlite3 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local1 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000002ULL) Or Cast(c2fb_c_int, &H00000004ULL))) Or Cast(c2fb_c_int, &H00000040ULL)))
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = c2fb_external_sqlite3_open_v2(arg1, CPtr(c2fb_sqlite3 Ptr Ptr, @(local0)), local1, IIf(arg2, arg0->zVfsName, CPtr(Const ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        If arg0->rc Then
            c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
            c2fb_temp_3 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(local0))))
            (*c2fb_temp_2) = c2fb_temp_3
            c2fb_external_sqlite3_close(local0)
            c2fb_temp_4 = CPtr(c2fb_sqlite3 Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
            local0 = c2fb_temp_4
        End If
    End If
    Return local0
End Function
Private Sub rbuFreeState CDecl (ByVal arg0 As c2fb_RbuState Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2721
    If arg0 Then
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zTbl))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zDataTbl))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zIdx))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub
Private Function rbuLoadState CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_RbuState Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2739
    Dim local0 As c2fb_RbuState Ptr
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_RbuState Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As ZString Ptr Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_i64 Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_i64 Ptr
    Dim c2fb_temp_16 As c2fb_int64
    Dim c2fb_temp_17 As c2fb_u32 Ptr
    Dim c2fb_temp_18 As c2fb_c_uint
    Dim c2fb_temp_19 As c2fb_i64 Ptr
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_i64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As ZString Ptr Ptr
    Dim c2fb_temp_24 As ZString Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As Long Ptr
    Dim c2fb_temp_29 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_RbuState Ptr, CPtr(Any Ptr, rbuMalloc(arg0, Cast(c2fb_size_t, SizeOf(c2fb_RbuState)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_1 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT k, v FROM %s.rbu_state"), CPtr(ZString Ptr, (@arg0->zStateDb(0))))))
    local2 = c2fb_temp_1
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local1))))) <> 0)))))
        Select Case c2fb_external_sqlite3_column_int(local1, Cast(c2fb_c_int, &O0ULL))
            Case Cast(c2fb_c_int, 1ULL)
                c2fb_temp_2 = CPtr(Long Ptr, @(local0->eStage))
                c2fb_temp_3 = c2fb_external_sqlite3_column_int(local1, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
                c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eStage <> Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->eStage <> Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->eStage <> Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
                    c2fb_temp_4 = CPtr(Long Ptr, @(arg0->rc))
                    c2fb_temp_5 = Cast(c2fb_c_int, 11ULL)
                    (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
                    c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
                End If
            Case Cast(c2fb_c_int, 2ULL)
                c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(local0->zTbl))
                c2fb_temp_7 = CPtr(ZString Ptr, rbuStrndup(CPtr(Const ZString Ptr, CPtr(ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local1, Cast(c2fb_c_int, 1ULL))))), CPtr(c2fb_c_int Ptr, @(local2))))
                (*c2fb_temp_6) = c2fb_temp_7
            Case Cast(c2fb_c_int, 3ULL)
                c2fb_temp_8 = CPtr(ZString Ptr Ptr, @(local0->zIdx))
                c2fb_temp_9 = CPtr(ZString Ptr, rbuStrndup(CPtr(Const ZString Ptr, CPtr(ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local1, Cast(c2fb_c_int, 1ULL))))), CPtr(c2fb_c_int Ptr, @(local2))))
                (*c2fb_temp_8) = c2fb_temp_9
            Case Cast(c2fb_c_int, 4ULL)
                c2fb_temp_10 = CPtr(Long Ptr, @(local0->nRow))
                c2fb_temp_11 = c2fb_external_sqlite3_column_int(local1, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
                c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
                If (-Cast(c2fb_c_int, ((local0->nRow < Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_12 = Cast(c2fb_c_int, 11ULL)
                    local2 = c2fb_temp_12
                End If
            Case Cast(c2fb_c_int, 5ULL)
                c2fb_temp_13 = CPtr(c2fb_i64 Ptr, @(local0->nProgress))
                c2fb_temp_14 = c2fb_external_sqlite3_column_int64(local1, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_13) = Cast(c2fb_i64, c2fb_temp_14)
                c2fb_temp_14 = Cast(c2fb_int64, (*c2fb_temp_13))
            Case Cast(c2fb_c_int, 6ULL)
                c2fb_temp_15 = CPtr(c2fb_i64 Ptr, @(local0->iWalCksum))
                c2fb_temp_16 = c2fb_external_sqlite3_column_int64(local1, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_15) = Cast(c2fb_i64, c2fb_temp_16)
                c2fb_temp_16 = Cast(c2fb_int64, (*c2fb_temp_15))
            Case Cast(c2fb_c_int, 7ULL)
                c2fb_temp_17 = CPtr(c2fb_u32 Ptr, @(local0->iCookie))
                c2fb_temp_18 = Cast(c2fb_c_uint, c2fb_external_sqlite3_column_int64(local1, Cast(c2fb_c_int, 1ULL)))
                (*c2fb_temp_17) = Cast(c2fb_u32, c2fb_temp_18)
                c2fb_temp_18 = Cast(c2fb_c_uint, (*c2fb_temp_17))
            Case Cast(c2fb_c_int, 8ULL)
                c2fb_temp_19 = CPtr(c2fb_i64 Ptr, @(local0->iOalSz))
                c2fb_temp_20 = c2fb_external_sqlite3_column_int64(local1, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_19) = Cast(c2fb_i64, c2fb_temp_20)
                c2fb_temp_20 = Cast(c2fb_int64, (*c2fb_temp_19))
            Case Cast(c2fb_c_int, 9ULL)
                c2fb_temp_21 = CPtr(c2fb_i64 Ptr, @(local0->nPhaseOneStep))
                c2fb_temp_22 = c2fb_external_sqlite3_column_int64(local1, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_21) = Cast(c2fb_i64, c2fb_temp_22)
                c2fb_temp_22 = Cast(c2fb_int64, (*c2fb_temp_21))
            Case Cast(c2fb_c_int, 10ULL)
                c2fb_temp_23 = CPtr(ZString Ptr Ptr, @(local0->zDataTbl))
                c2fb_temp_24 = CPtr(ZString Ptr, rbuStrndup(CPtr(Const ZString Ptr, CPtr(ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local1, Cast(c2fb_c_int, 1ULL))))), CPtr(c2fb_c_int Ptr, @(local2))))
                (*c2fb_temp_23) = c2fb_temp_24
            Case Else
                c2fb_temp_25 = Cast(c2fb_c_int, 11ULL)
                local2 = c2fb_temp_25
        End Select
        c2fb_flow_2:
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    c2fb_temp_26 = c2fb_external_sqlite3_finalize(local1)
    local3 = c2fb_temp_26
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_27 = local3
        local2 = c2fb_temp_27
    End If
    c2fb_temp_28 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_29 = local2
    (*c2fb_temp_28) = Cast(Long, c2fb_temp_29)
    c2fb_temp_29 = Cast(c2fb_c_int, (*c2fb_temp_28))
    Return local0
End Function
Private Sub rbuOpenDatabase CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_sqlite3 Ptr, ByVal arg2 As c2fb_c_int Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 2823
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_8 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_9 As c2fb_sqlite3 Ptr
    Dim local0 As Const ZString Ptr
    Dim c2fb_temp_10 As ZString Ptr Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As Any Ptr
    Dim c2fb_temp_13 As Any Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_17 As c2fb_rbu_file Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim local3 As c2fb_RbuState Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_24 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_25 As Long Ptr
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_28 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_29 As c2fb_u8 Ptr
    Dim c2fb_temp_30 As UByte
    Dim c2fb_temp_31 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_32 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_33 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_34 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_35 As c2fb_c_int Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As Long Ptr
    Dim c2fb_temp_38 As c2fb_c_int
    Dim c2fb_temp_39 As ZString Ptr Ptr
    Dim c2fb_temp_40 As ZString Ptr
    Dim local4 As ZString Ptr
    Dim local5 As ZString Ptr
    Dim c2fb_temp_41 As ZString Ptr
    Dim c2fb_temp_42 As ZString Ptr
    Dim c2fb_temp_43 As ZString Ptr
    Dim c2fb_temp_44 As ZString Ptr
    Dim c2fb_temp_45 As Long Ptr
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_48 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_49 As Long Ptr
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As Long Ptr
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As Long Ptr
    Dim c2fb_temp_54 As c2fb_c_int
    Dim c2fb_temp_55 As Long Ptr
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As Long Ptr
    Dim c2fb_temp_58 As c2fb_c_int
    Dim c2fb_temp_59 As Long Ptr
    Dim c2fb_temp_60 As c2fb_c_int
    Dim c2fb_temp_61 As ZString Ptr Ptr
    Dim c2fb_temp_62 As ZString Ptr

    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((arg0->rc <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3 Ptr, arg0->dbMain) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->rc || (p->dbMain==0 && p->dbRbu==0)"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2824ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    c2fb_temp_2 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((arg0->rc <> 0) OrElse (((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->zTarget <> Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->rc || rbuIsVacuum(p) || p->zTarget!=0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2825ULL))
        c2fb_temp_2 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_3 = (c2fb_temp_2)
    c2fb_temp_4 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"dbMain==0 || rbuIsVacuum(p)==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 2826ULL))
        c2fb_temp_4 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_5 = (c2fb_temp_4)
    c2fb_temp_6 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbRbu))
    c2fb_temp_7 = CPtr(c2fb_sqlite3 Ptr, rbuOpenDbhandle(arg0, CPtr(Const ZString Ptr, arg0->zRbu), Cast(c2fb_c_int, 1ULL)))
    (*c2fb_temp_6) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_7)
    c2fb_temp_7 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_6))
    c2fb_temp_8 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbMain))
    c2fb_temp_9 = arg1
    (*c2fb_temp_8) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_9)
    c2fb_temp_9 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_8))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        c2fb_external_sqlite3_file_control(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"main"), Cast(c2fb_c_int, 5149216ULL), CPtr(Any Ptr, arg0))
        If (-Cast(c2fb_c_int, ((arg0->zState = Cast(c2fb_c_int, &O0ULL))))) Then
            local0 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_db_filename(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"main")))
            c2fb_temp_10 = CPtr(ZString Ptr Ptr, @(arg0->zState))
            c2fb_temp_11 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"file:///%s-vacuum?modeof=%s"), local0, local0))
            (*c2fb_temp_10) = c2fb_temp_11
        End If
    End If
    If arg0->zState Then
        rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"ATTACH %Q AS stat"), arg0->zState)
        c2fb_temp_12 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(ZString Ptr, (@arg0->zStateDb(0)))), CPtr(Const Any Ptr, StrPtr(!"stat")), Cast(c2fb_c_int, 4ULL)))
    Else
        c2fb_temp_13 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(ZString Ptr, (@arg0->zStateDb(0)))), CPtr(Const Any Ptr, StrPtr(!"main")), Cast(c2fb_c_int, 4ULL)))
    End If
    rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"CREATE TABLE IF NOT EXISTS %s.rbu_state(k INTEGER PRIMARY KEY, v)"), CPtr(ZString Ptr, (@arg0->zStateDb(0))))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        ' C automatic storage declaration
        c2fb_temp_14 = CPtr(Long Ptr, @(arg0->nRbu))
        c2fb_temp_15 = Cast(c2fb_c_int, &O0ULL)
        (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
        c2fb_temp_16 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(arg0->pRbuFd))
        c2fb_temp_17 = CPtr(_c2fb_record_c2fb_rbu_file Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_16) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_17)
        c2fb_temp_17 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_16))
        c2fb_temp_18 = c2fb_external_sqlite3_file_control(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"main"), Cast(c2fb_c_int, 5149216ULL), CPtr(Any Ptr, arg0))
        local2 = c2fb_temp_18
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, 12ULL))))) Then
            c2fb_temp_19 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_20 = local2
            (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
            c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
        End If
        If (-Cast(c2fb_c_int, ((arg0->eStage >= Cast(c2fb_c_int, 2ULL))))) Then
            c2fb_temp_21 = Cast(c2fb_c_int, 1ULL)
            local1 = c2fb_temp_21
        Else
            local3 = CPtr(c2fb_RbuState Ptr, rbuLoadState(arg0))
            If local3 Then
                c2fb_temp_22 = ((-Cast(c2fb_c_int, ((local3->eStage >= Cast(c2fb_c_int, 2ULL))))))
                local1 = c2fb_temp_22
                rbuFreeState(local3)
            End If
        End If
        If local1 Then
            c2fb_temp_23 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbMain))
            c2fb_temp_24 = CPtr(c2fb_sqlite3 Ptr, rbuOpenDbhandle(arg0, CPtr(Const ZString Ptr, arg0->zRbu), (-Cast(c2fb_c_int, ((arg0->nRbu <= Cast(c2fb_c_int, 1ULL)))))))
            (*c2fb_temp_23) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_24)
            c2fb_temp_24 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_23))
        End If
    End If
    c2fb_temp_25 = CPtr(Long Ptr, @(arg0->eStage))
    c2fb_temp_26 = Cast(c2fb_c_int, &O0ULL)
    (*c2fb_temp_25) = Cast(Long, c2fb_temp_26)
    c2fb_temp_26 = Cast(c2fb_c_int, (*c2fb_temp_25))
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3 Ptr, arg0->dbMain) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        If (-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) = 0))) Then
            c2fb_temp_27 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbMain))
            c2fb_temp_28 = CPtr(c2fb_sqlite3 Ptr, rbuOpenDbhandle(arg0, CPtr(Const ZString Ptr, arg0->zTarget), Cast(c2fb_c_int, 1ULL)))
            (*c2fb_temp_27) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_28)
            c2fb_temp_28 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_27))
        Else
            If CPtr(c2fb_rbu_file Ptr, CPtr(c2fb_rbu_file Ptr, arg0->pRbuFd)->pWalFd) Then
                If arg2 Then
                    c2fb_temp_29 = CPtr(c2fb_u8 Ptr, @(CPtr(c2fb_rbu_file Ptr, arg0->pRbuFd)->bNolock))
                    c2fb_temp_30 = Cast(UByte, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_29) = Cast(c2fb_u8, c2fb_temp_30)
                    c2fb_temp_30 = Cast(UByte, (*c2fb_temp_29))
                    c2fb_external_sqlite3_close(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu))
                    c2fb_external_sqlite3_close(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain))
                    c2fb_temp_31 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbMain))
                    c2fb_temp_32 = CPtr(c2fb_sqlite3 Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_31) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_32)
                    c2fb_temp_32 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_31))
                    c2fb_temp_33 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbRbu))
                    c2fb_temp_34 = CPtr(c2fb_sqlite3 Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
                    (*c2fb_temp_33) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_34)
                    c2fb_temp_34 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_33))
                    c2fb_temp_35 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                    c2fb_temp_36 = Cast(c2fb_c_int, 1ULL)
                    (*c2fb_temp_35) = c2fb_temp_36
                    Return
                End If
                c2fb_temp_37 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_38 = Cast(c2fb_c_int, 1ULL)
                (*c2fb_temp_37) = Cast(Long, c2fb_temp_38)
                c2fb_temp_38 = Cast(c2fb_c_int, (*c2fb_temp_37))
                c2fb_temp_39 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
                c2fb_temp_40 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"cannot vacuum wal mode database")))
                (*c2fb_temp_39) = c2fb_temp_40
            Else
                ' C automatic storage declaration
                local5 = Cast(c2fb_c_int, &O0ULL)
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, c2fb_crt_strlen(CPtr(Const ZString Ptr, arg0->zRbu))) >= Cast(c2fb_c_uint, Cast(c2fb_c_int, 5ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"file:")), CPtr(Const Any Ptr, arg0->zRbu), Cast(c2fb_c_int, 5ULL)))))) <> 0))))) Then
                    c2fb_temp_41 = CPtr(ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->zRbu)[Cast(c2fb_c_int, 5ULL)])))
                    local5 = c2fb_temp_41
                    While (*CPtr(Byte Ptr, local5))
                        c2fb_temp_42 = local5
                        local5 = (c2fb_temp_42 + 1)
                        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, c2fb_temp_42))) = Cast(c2fb_c_int, 63))))) Then
                            Goto c2fb_flow_0
                        End If
                    c2fb_flow_1:
                    Wend
                    c2fb_flow_0:
                    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (*CPtr(Byte Ptr, local5))) = Cast(c2fb_c_int, 0))))) Then
                        c2fb_temp_43 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
                        local5 = c2fb_temp_43
                    End If
                End If
                c2fb_temp_44 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"file:%s-vactmp?rbu_memory=1%s%s"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_db_filename(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"main"))), (IIf((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))), StrPtr(!""), StrPtr(!"&"))), (IIf((-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))), StrPtr(!""), CPtr(Const ZString Ptr, local5)))))
                local4 = c2fb_temp_44
                If (-Cast(c2fb_c_int, ((local4 = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_45 = CPtr(Long Ptr, @(arg0->rc))
                    c2fb_temp_46 = Cast(c2fb_c_int, 7ULL)
                    (*c2fb_temp_45) = Cast(Long, c2fb_temp_46)
                    c2fb_temp_46 = Cast(c2fb_c_int, (*c2fb_temp_45))
                    Return
                End If
                c2fb_temp_47 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbMain))
                c2fb_temp_48 = CPtr(c2fb_sqlite3 Ptr, rbuOpenDbhandle(arg0, CPtr(Const ZString Ptr, local4), (-Cast(c2fb_c_int, ((arg0->nRbu <= Cast(c2fb_c_int, 1ULL)))))))
                (*c2fb_temp_47) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_48)
                c2fb_temp_48 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_47))
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local4))
            End If
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_49 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_50 = c2fb_external_sqlite3_create_function(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"rbu_tmp_insert"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL), CPtr(Any Ptr, arg0), ProcPtr(rbuTmpInsertFunc), CPtr(c2fb_callback_104, 0), CPtr(c2fb_callback_105, 0))
        (*c2fb_temp_49) = Cast(Long, c2fb_temp_50)
        c2fb_temp_50 = Cast(c2fb_c_int, (*c2fb_temp_49))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_51 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_52 = c2fb_external_sqlite3_create_function(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"rbu_fossil_delta"), Cast(c2fb_c_int, 2ULL), Cast(c2fb_c_int, 1ULL), CPtr(Any Ptr, 0), ProcPtr(rbuFossilDeltaFunc), CPtr(c2fb_callback_104, 0), CPtr(c2fb_callback_105, 0))
        (*c2fb_temp_51) = Cast(Long, c2fb_temp_52)
        c2fb_temp_52 = Cast(c2fb_c_int, (*c2fb_temp_51))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_53 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_54 = c2fb_external_sqlite3_create_function(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"rbu_target_name"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), Cast(c2fb_c_int, 1ULL), CPtr(Any Ptr, arg0), ProcPtr(rbuTargetNameFunc), CPtr(c2fb_callback_104, 0), CPtr(c2fb_callback_105, 0))
        (*c2fb_temp_53) = Cast(Long, c2fb_temp_54)
        c2fb_temp_54 = Cast(c2fb_c_int, (*c2fb_temp_53))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_55 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_56 = c2fb_external_sqlite3_file_control(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, 26ULL), CPtr(Any Ptr, arg0))
        (*c2fb_temp_55) = Cast(Long, c2fb_temp_56)
        c2fb_temp_56 = Cast(c2fb_c_int, (*c2fb_temp_55))
    End If
    rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"SELECT * FROM sqlite_schema"))
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_57 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_58 = c2fb_external_sqlite3_file_control(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, 26ULL), CPtr(Any Ptr, arg0))
        (*c2fb_temp_57) = Cast(Long, c2fb_temp_58)
        c2fb_temp_58 = Cast(c2fb_c_int, (*c2fb_temp_57))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, 12ULL))))) Then
        c2fb_temp_59 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_60 = Cast(c2fb_c_int, 1ULL)
        (*c2fb_temp_59) = Cast(Long, c2fb_temp_60)
        c2fb_temp_60 = Cast(c2fb_c_int, (*c2fb_temp_59))
        c2fb_temp_61 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
        c2fb_temp_62 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"rbu vfs not found")))
        (*c2fb_temp_61) = c2fb_temp_62
    End If
End Sub
Private Sub rbuFileSuffix3 CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As ZString Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3004
    ' C unused-parameter annotation
End Sub
' c2fb skipped rbuShmChecksum: outside the supported subset
' c2fb body diagnostic [volatile-semantics-not-preserved] line 3027: rbuShmChecksum: volatile access semantics are not preserved by FreeBASIC
Private Sub rbuSetupCheckpoint CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuState Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3056
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As Long Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_14 As UByte Ptr
    Dim c2fb_temp_15 As c2fb_i64 Ptr
    Dim c2fb_temp_16 As c2fb_int64
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Long Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_file Ptr
    Dim local3 As c2fb_sqlite3_file Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As Long Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Long Ptr
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As Long Ptr
    Dim c2fb_temp_29 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->eStage))
        c2fb_temp_1 = Cast(c2fb_c_int, &O0ULL)
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_3 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"SELECT * FROM sqlite_schema"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, 0))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        c2fb_temp_4 = CPtr(Long Ptr, @(arg0->eStage))
        c2fb_temp_5 = Cast(c2fb_c_int, 3ULL)
        (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
        c2fb_temp_6 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"PRAGMA main.wal_checkpoint=restart"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, 0))
        local0 = c2fb_temp_6
        If (-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, 27ULL))))) Then
            c2fb_temp_7 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_8 = local0
            (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->nFrame > Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_9 = CPtr(Long Ptr, @(arg0->eStage))
        c2fb_temp_10 = Cast(c2fb_c_int, 4ULL)
        (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
        c2fb_temp_11 = CPtr(Long Ptr, @(arg0->nStep))
        c2fb_temp_12 = (IIf(arg1, arg1->nRow, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_11) = Cast(Long, c2fb_temp_12)
        c2fb_temp_12 = Cast(c2fb_c_int, (*c2fb_temp_11))
        c2fb_temp_13 = CPtr(c2fb_u8 Ptr Ptr, @(arg0->aBuf))
        c2fb_temp_14 = CPtr(UByte Ptr, CPtr(Any Ptr, rbuMalloc(arg0, arg0->pgsz)))
        (*c2fb_temp_13) = CPtr(c2fb_u8 Ptr, c2fb_temp_14)
        c2fb_temp_14 = CPtr(UByte Ptr, (*c2fb_temp_13))
        c2fb_temp_15 = CPtr(c2fb_i64 Ptr, @(arg0->iWalCksum))
        c2fb_temp_16 = rbuShmChecksum(arg0)
        (*c2fb_temp_15) = Cast(c2fb_i64, c2fb_temp_16)
        c2fb_temp_16 = Cast(c2fb_int64, (*c2fb_temp_15))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->nFrame = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->iWalCksum <> arg0->iWalCksum)))) <> 0)))))) <> 0))))) Then
            c2fb_temp_17 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_18 = Cast(c2fb_c_int, 101ULL)
            (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
            c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
            c2fb_temp_19 = CPtr(Long Ptr, @(arg0->eStage))
            c2fb_temp_20 = Cast(c2fb_c_int, 5ULL)
            (*c2fb_temp_19) = Cast(Long, c2fb_temp_20)
            c2fb_temp_20 = Cast(c2fb_c_int, (*c2fb_temp_19))
        Else
            ' C automatic storage declaration
            local2 = CPtr(c2fb_sqlite3_file Ptr, CPtr(c2fb_rbu_file Ptr, arg0->pTargetFd)->pReal)
            local3 = CPtr(c2fb_sqlite3_file Ptr, CPtr(c2fb_rbu_file Ptr, CPtr(c2fb_rbu_file Ptr, arg0->pTargetFd)->pWalFd)->pReal)
            c2fb_temp_21 = 1
            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->nPagePerSector = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
                c2fbRbuAssert(StrPtr(!"p->nPagePerSector==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3118ULL))
                c2fb_temp_21 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
            End If
            c2fb_temp_22 = (c2fb_temp_21)
            c2fb_temp_23 = CPtr(c2fb_callback_6, CPtr(Const c2fb_sqlite3_io_methods Ptr, local2->pMethods)->xSectorSize)(local2)
            local1 = c2fb_temp_23
            If (-Cast(c2fb_c_int, ((local1 > arg0->pgsz)))) Then
                c2fb_temp_24 = CPtr(Long Ptr, @(arg0->nPagePerSector))
                c2fb_temp_25 = Cast(c2fb_c_int, (local1 \ arg0->pgsz))
                (*c2fb_temp_24) = Cast(Long, c2fb_temp_25)
                c2fb_temp_25 = Cast(c2fb_c_int, (*c2fb_temp_24))
            Else
                c2fb_temp_26 = CPtr(Long Ptr, @(arg0->nPagePerSector))
                c2fb_temp_27 = Cast(c2fb_c_int, 1ULL)
                (*c2fb_temp_26) = Cast(Long, c2fb_temp_27)
                c2fb_temp_27 = Cast(c2fb_c_int, (*c2fb_temp_26))
            End If
            c2fb_temp_28 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_29 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, local3->pMethods)->xSync)(local3, Cast(c2fb_c_int, &H00002ULL))
            (*c2fb_temp_28) = Cast(Long, c2fb_temp_29)
            c2fb_temp_29 = Cast(c2fb_c_int, (*c2fb_temp_28))
        End If
    End If
End Sub
Private Function rbuCaptureWalRead CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_int64, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3140
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_c_uint
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_RbuFrame Ptr
    Dim c2fb_temp_4 As c2fb_RbuFrame Ptr
    Dim c2fb_temp_5 As c2fb_RbuFrame_ Ptr Ptr
    Dim c2fb_temp_6 As c2fb_RbuFrame Ptr
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_uint
    Dim c2fb_temp_10 As c2fb_u32 Ptr
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim c2fb_temp_12 As c2fb_u32 Ptr
    Dim c2fb_temp_13 As c2fb_c_uint
    Dim c2fb_temp_14 As c2fb_u32 Ptr
    Dim c2fb_temp_15 As c2fb_c_uint
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int

    local0 = Cast(c2fb_c_int, (Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, &O0ULL)))) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 1ULL)))))) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 3ULL))))))
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, ((arg0->mLock <> local0)))) Then
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = Cast(c2fb_c_int, 5ULL)
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 27ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 3ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
    End If
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->pgsz))
    c2fb_temp_3 = arg2
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    If (-Cast(c2fb_c_int, ((arg0->nFrame = arg0->nFrameAlloc)))) Then
        local2 = Cast(c2fb_c_int, ((IIf(arg0->nFrameAlloc, arg0->nFrameAlloc, Cast(c2fb_c_int, 64ULL))) * Cast(c2fb_c_int, 2ULL)))
        ' C automatic storage declaration
        c2fb_temp_4 = CPtr(c2fb_RbuFrame Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, CPtr(c2fb_RbuFrame Ptr, arg0->aFrame)), Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local2) * Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(c2fb_RbuFrame))))))))
        local3 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_5 = CPtr(c2fb_RbuFrame_ Ptr Ptr, @(arg0->aFrame))
        c2fb_temp_6 = local3
        (*c2fb_temp_5) = CPtr(c2fb_RbuFrame_ Ptr, c2fb_temp_6)
        c2fb_temp_6 = CPtr(c2fb_RbuFrame Ptr, (*c2fb_temp_5))
        c2fb_temp_7 = CPtr(Long Ptr, @(arg0->nFrameAlloc))
        c2fb_temp_8 = local2
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    End If
    c2fb_temp_9 = Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_int64, ((Cast(c2fb_int64, (arg1 - Cast(c2fb_int64, Cast(c2fb_c_int, 32ULL))))) \ Cast(c2fb_int64, (Cast(c2fb_c_int, (arg2 + Cast(c2fb_c_int, 24ULL))))))))) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))
    local1 = c2fb_temp_9
    If (-Cast(c2fb_c_int, ((arg0->iMaxFrame < local1)))) Then
        c2fb_temp_10 = CPtr(c2fb_u32 Ptr, @(arg0->iMaxFrame))
        c2fb_temp_11 = local1
        (*c2fb_temp_10) = Cast(c2fb_u32, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_uint, (*c2fb_temp_10))
    End If
    c2fb_temp_12 = CPtr(c2fb_u32 Ptr, @(CPtr(c2fb_RbuFrame Ptr, CPtr(c2fb_RbuFrame Ptr, arg0->aFrame))[arg0->nFrame].iWalFrame))
    c2fb_temp_13 = local1
    (*c2fb_temp_12) = Cast(c2fb_u32, c2fb_temp_13)
    c2fb_temp_13 = Cast(c2fb_c_uint, (*c2fb_temp_12))
    c2fb_temp_14 = CPtr(c2fb_u32 Ptr, @(CPtr(c2fb_RbuFrame Ptr, CPtr(c2fb_RbuFrame Ptr, arg0->aFrame))[arg0->nFrame].iDbPage))
    c2fb_temp_15 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_14) = Cast(c2fb_u32, c2fb_temp_15)
    c2fb_temp_15 = Cast(c2fb_c_uint, (*c2fb_temp_14))
    c2fb_temp_16 = CPtr(Long Ptr, @(arg0->nFrame))
    c2fb_temp_17 = (*c2fb_temp_16)
    (*c2fb_temp_16) = Cast(c2fb_c_int, (c2fb_temp_17 + 1))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function rbuCaptureDbWrite CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3172
    Dim c2fb_temp_0 As c2fb_u32 Ptr
    Dim c2fb_temp_1 As c2fb_c_uint

    c2fb_temp_0 = CPtr(c2fb_u32 Ptr, @(CPtr(c2fb_RbuFrame Ptr, CPtr(c2fb_RbuFrame Ptr, arg0->aFrame))[Cast(c2fb_c_int, (arg0->nFrame - Cast(c2fb_c_int, 1ULL)))].iDbPage))
    c2fb_temp_1 = Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_int64, (arg1 \ Cast(c2fb_int64, arg0->pgsz))))) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))
    (*c2fb_temp_0) = Cast(c2fb_u32, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_uint, (*c2fb_temp_0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub rbuCheckpointFrame CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuFrame Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3182
    Dim local0 As c2fb_sqlite3_file Ptr
    Dim local1 As c2fb_sqlite3_file Ptr
    Dim local2 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_int64
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_int64
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    local0 = CPtr(c2fb_sqlite3_file Ptr, CPtr(c2fb_rbu_file Ptr, CPtr(c2fb_rbu_file Ptr, arg0->pTargetFd)->pWalFd)->pReal)
    local1 = CPtr(c2fb_sqlite3_file Ptr, CPtr(c2fb_rbu_file Ptr, arg0->pTargetFd)->pReal)
    ' C automatic storage declaration
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->rc==SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3187ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    c2fb_temp_2 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_uint, (arg1->iWalFrame - Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))))) * Cast(c2fb_int64, (Cast(c2fb_c_int, (arg0->pgsz + Cast(c2fb_c_int, 24ULL))))))) + Cast(c2fb_int64, Cast(c2fb_c_int, 32ULL)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 24ULL))))
    local2 = c2fb_temp_2
    c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_4 = CPtr(c2fb_callback_7, CPtr(Const c2fb_sqlite3_io_methods Ptr, local0->pMethods)->xRead)(local0, CPtr(Any Ptr, arg0->aBuf), arg0->pgsz, local2)
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    If arg0->rc Then
        Return
    End If
    c2fb_temp_5 = Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_c_uint, (arg1->iDbPage - Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))))) * Cast(c2fb_int64, arg0->pgsz)))
    local2 = c2fb_temp_5
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_7 = CPtr(c2fb_callback_8, CPtr(Const c2fb_sqlite3_io_methods Ptr, local1->pMethods)->xWrite)(local1, CPtr(Const Any Ptr, arg0->aBuf), arg0->pgsz, local2)
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
End Sub
Private Function rbuLockDatabase CDecl (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3206
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_file Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_external_sqlite3_file_control(arg0, StrPtr(!"main"), Cast(c2fb_c_int, 230439ULL), CPtr(Any Ptr, CPtr(c2fb_sqlite3_file Ptr Ptr, @(local1))))
    If local1 Then
        c2fb_external_sqlite3_file_control(arg0, StrPtr(!"main"), Cast(c2fb_c_int, 7ULL), CPtr(Any Ptr, CPtr(c2fb_sqlite3_file Ptr Ptr, @(local1))))
        c2fb_temp_0 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, local1->pMethods)->xLock)(local1, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, local1->pMethods)->xUnlock)(local1, Cast(c2fb_c_int, &O0ULL))
            local0 = c2fb_temp_1
        End If
        c2fb_external_sqlite3_file_control(arg0, StrPtr(!"main"), Cast(c2fb_c_int, 230439ULL), CPtr(Any Ptr, CPtr(c2fb_sqlite3_file Ptr Ptr, @(local1))))
    Else
        c2fb_external_sqlite3_file_control(arg0, StrPtr(!"main"), Cast(c2fb_c_int, 7ULL), CPtr(Any Ptr, CPtr(c2fb_sqlite3_file Ptr Ptr, @(local1))))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(Const c2fb_sqlite3_io_methods Ptr, local1->pMethods) <> 0))))) Then
        c2fb_temp_2 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, local1->pMethods)->xLock)(local1, Cast(c2fb_c_int, 1ULL))
        local0 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_3 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, local1->pMethods)->xLock)(local1, Cast(c2fb_c_int, 4ULL))
            local0 = c2fb_temp_3
        End If
    End If
    Return local0
End Function
Private Function rbuExclusiveCheckpoint CDecl (ByVal arg0 As c2fb_sqlite3 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3236
    Dim local0 As Const ZString Ptr

    local0 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_db_filename(arg0, CPtr(Const ZString Ptr, 0)))
    Return c2fb_external_sqlite3_uri_boolean(local0, StrPtr(!"rbu_exclusive_checkpoint"), Cast(c2fb_c_int, &O0ULL))
End Function
Private Sub rbuMoveOalFile CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3272
    Dim local0 As Const ZString Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As ZString Ptr
    Dim local3 As ZString Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim local4 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_9 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_10 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_11 As c2fb_sqlite3_ Ptr Ptr
    Dim c2fb_temp_12 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_13 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_sqlite3 Ptr

    local0 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_db_filename(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main")))
    local1 = local0
    ' C automatic storage declaration
    ' C automatic storage declaration
    If ((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_0 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_db_filename(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"main")))
        local1 = c2fb_temp_0
    End If
    c2fb_temp_1 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s-oal"), local1))
    local2 = c2fb_temp_1
    c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"%s-wal"), local1))
    local3 = c2fb_temp_2
    c2fb_temp_3 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 2ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->eStage==RBU_STAGE_MOVE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3284ULL))
        c2fb_temp_3 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_4 = (c2fb_temp_3)
    c2fb_temp_5 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->zErrmsg = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->rc==SQLITE_OK && p->zErrmsg==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3285ULL))
        c2fb_temp_5 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_6 = (c2fb_temp_5)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_7 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_8 = Cast(c2fb_c_int, 7ULL)
        (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
        c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
    Else
        local4 = Cast(c2fb_c_int, &O0ULL)
        rbuFileSuffix3(local0, local3)
        rbuFileSuffix3(local0, local2)
        rbuObjIterFinalize(CPtr(c2fb_RbuObjIter Ptr, @(arg0->objiter)))
        c2fb_external_sqlite3_close(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu))
        c2fb_external_sqlite3_close(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain))
        c2fb_temp_9 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbMain))
        c2fb_temp_10 = CPtr(c2fb_sqlite3 Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_9) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_10)
        c2fb_temp_10 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_9))
        c2fb_temp_11 = CPtr(c2fb_sqlite3_ Ptr Ptr, @(arg0->dbRbu))
        c2fb_temp_12 = CPtr(c2fb_sqlite3 Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_11) = CPtr(c2fb_sqlite3_ Ptr, c2fb_temp_12)
        c2fb_temp_12 = CPtr(c2fb_sqlite3 Ptr, (*c2fb_temp_11))
        c2fb_temp_13 = CPtr(c2fb_sqlite3 Ptr, rbuOpenDbhandle(arg0, CPtr(Const ZString Ptr, arg0->zTarget), Cast(c2fb_c_int, 1ULL)))
        local4 = c2fb_temp_13
        If local4 Then
            c2fb_temp_14 = 1
            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
                c2fbRbuAssert(StrPtr(!"p->rc==SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3309ULL))
                c2fb_temp_14 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
            End If
            c2fb_temp_15 = (c2fb_temp_14)
            c2fb_temp_16 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_17 = rbuLockDatabase(local4)
            (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
            c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
        End If
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_18 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_19 = CPtr(c2fb_callback_98, arg0->xRename)(arg0->pRenameArg, CPtr(Const ZString Ptr, local2), CPtr(Const ZString Ptr, local3))
            (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
            c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((rbuExclusiveCheckpoint(local4) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            c2fb_external_sqlite3_close(local4)
            c2fb_temp_20 = CPtr(c2fb_sqlite3 Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
            local4 = c2fb_temp_20
        End If
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            rbuOpenDatabase(arg0, local4, CPtr(c2fb_c_int Ptr, 0))
            rbuSetupCheckpoint(arg0, CPtr(c2fb_RbuState Ptr, 0))
        End If
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local3))
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
End Sub
Private Function rbuStepType CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3352
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local3 As Const UByte Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Const ZString Ptr Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As c2fb_c_int

    local0 = arg0->objiter.nCol
    local1 = Cast(c2fb_c_int, &O0ULL)
    Select Case c2fb_external_sqlite3_column_type(CPtr(c2fb_sqlite3_stmt Ptr, arg0->objiter.pSelect), local0)
        Case Cast(c2fb_c_int, 1ULL)
            local2 = c2fb_external_sqlite3_column_int(CPtr(c2fb_sqlite3_stmt Ptr, arg0->objiter.pSelect), local0)
            Select Case local2
                Case Cast(c2fb_c_int, &O0ULL)
                    c2fb_temp_0 = Cast(c2fb_c_int, 1ULL)
                    local1 = c2fb_temp_0
                Case Cast(c2fb_c_int, 1ULL)
                    c2fb_temp_1 = Cast(c2fb_c_int, 2ULL)
                    local1 = c2fb_temp_1
                Case Cast(c2fb_c_int, 2ULL)
                    c2fb_temp_2 = Cast(c2fb_c_int, 3ULL)
                    local1 = c2fb_temp_2
                Case Cast(c2fb_c_int, 3ULL)
                    c2fb_temp_3 = Cast(c2fb_c_int, 4ULL)
                    local1 = c2fb_temp_3
                Case Cast(c2fb_c_int, 4ULL)
                    c2fb_temp_4 = Cast(c2fb_c_int, 5ULL)
                    local1 = c2fb_temp_4
            End Select
            c2fb_flow_1:
            Goto c2fb_flow_0
        Case Cast(c2fb_c_int, 3ULL)
            local3 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(CPtr(c2fb_sqlite3_stmt Ptr, arg0->objiter.pSelect), local0))
            If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_5 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_6 = Cast(c2fb_c_int, 7ULL)
                (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
            Else
                c2fb_temp_7 = CPtr(Const ZString Ptr Ptr, @((*arg1)))
                c2fb_temp_8 = CPtr(Const ZString Ptr, local3)
                (*c2fb_temp_7) = c2fb_temp_8
            End If
            c2fb_temp_9 = Cast(c2fb_c_int, 6ULL)
            local1 = c2fb_temp_9
            Goto c2fb_flow_0
        Case Else
    End Select
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
        rbuBadControlError(arg0)
    End If
    Return local1
End Function
Private Sub rbuStepOneOp CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3408
    Dim local0 As c2fb_RbuObjIter Ptr
    Dim local1 As c2fb_sqlite3_value Ptr
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_i64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_9 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As Long Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As ZString Ptr Ptr
    Dim c2fb_temp_15 As ZString Ptr
    Dim c2fb_temp_16 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_20 As Long Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As Long Ptr
    Dim c2fb_temp_23 As c2fb_c_int

    local0 = CPtr(c2fb_RbuObjIter Ptr, @(arg0->objiter))
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->rc==SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3414ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    c2fb_temp_2 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 <> Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->zIdx = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"eType!=RBU_DELETE || pIter->zIdx==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3415ULL))
        c2fb_temp_2 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_3 = (c2fb_temp_2)
    c2fb_temp_4 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 5ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"eType==RBU_DELETE || eType==RBU_IDX_DELETE || eType==RBU_INSERT || eType==RBU_IDX_INSERT"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3416ULL))
        c2fb_temp_4 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_5 = (c2fb_temp_4)
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) Then
        c2fb_temp_6 = CPtr(c2fb_i64 Ptr, @(arg0->nPhaseOneStep))
        c2fb_temp_7 = Cast(c2fb_int64, ((*c2fb_temp_6) - Cast(c2fb_int64, arg0->objiter.nIndex)))
        (*c2fb_temp_6) = Cast(c2fb_i64, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_int64, (*c2fb_temp_6))
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
        c2fb_temp_8 = CPtr(c2fb_sqlite3_stmt Ptr, local0->pDelete)
        local2 = c2fb_temp_8
    Else
        c2fb_temp_9 = CPtr(c2fb_sqlite3_stmt Ptr, local0->pInsert)
        local2 = c2fb_temp_9
    End If
    c2fb_temp_10 = Cast(c2fb_c_int, &O0ULL)
    local3 = c2fb_temp_10
    While (-Cast(c2fb_c_int, ((local3 < local0->nCol))))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->zIdx = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->eType = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso (local0->abTblPk[local3] <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_column_type(CPtr(c2fb_sqlite3_stmt Ptr, local0->pSelect), local3) = Cast(c2fb_c_int, 5ULL))))) <> 0))))) Then
            c2fb_temp_12 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_13 = Cast(c2fb_c_int, 20ULL)
            (*c2fb_temp_12) = Cast(Long, c2fb_temp_13)
            c2fb_temp_13 = Cast(c2fb_c_int, (*c2fb_temp_12))
            c2fb_temp_14 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
            c2fb_temp_15 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"datatype mismatch")))
            (*c2fb_temp_14) = c2fb_temp_15
            Return
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 2ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local0->abTblPk[local3]) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            Goto c2fb_flow_1
        End If
        c2fb_temp_16 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(CPtr(c2fb_sqlite3_stmt Ptr, local0->pSelect), local3))
        local1 = c2fb_temp_16
        c2fb_temp_17 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_18 = c2fb_external_sqlite3_bind_value(local2, Cast(c2fb_c_int, (local3 + Cast(c2fb_c_int, 1ULL))), CPtr(Const c2fb_sqlite3_value Ptr, local1))
        (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
        If arg0->rc Then
            Return
        End If
    c2fb_flow_1:
        c2fb_temp_11 = local3
        local3 = Cast(c2fb_c_int, (c2fb_temp_11 + 1))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local0->zIdx = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eType = Cast(c2fb_c_int, 5ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->eType = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eType = Cast(c2fb_c_int, 3ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0)))))) <> 0))))) Then
            ' empty C statement
            c2fb_temp_19 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(CPtr(c2fb_sqlite3_stmt Ptr, local0->pSelect), Cast(c2fb_c_int, (local0->nCol + Cast(c2fb_c_int, 1ULL)))))
            local1 = c2fb_temp_19
            c2fb_temp_20 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_21 = c2fb_external_sqlite3_bind_value(local2, Cast(c2fb_c_int, (local0->nCol + Cast(c2fb_c_int, 1ULL))), CPtr(Const c2fb_sqlite3_value Ptr, local1))
            (*c2fb_temp_20) = Cast(Long, c2fb_temp_21)
            c2fb_temp_21 = Cast(c2fb_c_int, (*c2fb_temp_20))
        End If
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_step(local2)
        c2fb_temp_22 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_23 = resetAndCollectError(local2, CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
        (*c2fb_temp_22) = Cast(Long, c2fb_temp_23)
        c2fb_temp_23 = Cast(c2fb_c_int, (*c2fb_temp_22))
    End If
End Sub
Private Function rbuStep CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3491
    Dim local0 As c2fb_RbuObjIter Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_i64 Ptr
    Dim c2fb_temp_5 As c2fb_int64
    Dim local3 As c2fb_sqlite3_value Ptr
    Dim local4 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_i64 Ptr
    Dim c2fb_temp_9 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local6 As Byte
    Dim c2fb_temp_12 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_sqlite3_value Ptr
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Long Ptr
    Dim c2fb_temp_19 As c2fb_c_int

    local0 = CPtr(c2fb_RbuObjIter Ptr, @(arg0->objiter))
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = rbuStepType(arg0, CPtr(Const ZString Ptr Ptr, @(local1)))
    If local2 Then
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 3ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 5ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 6ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"eType==RBU_INSERT || eType==RBU_DELETE || eType==RBU_REPLACE || eType==RBU_IDX_DELETE || eType==RBU_IDX_INSERT || eType==RBU_UPDATE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3497ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        c2fb_temp_2 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, 6ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->zIdx = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"eType!=RBU_UPDATE || pIter->zIdx==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3501ULL))
            c2fb_temp_2 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_3 = (c2fb_temp_2)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->zIdx = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 5ULL))))) <> 0)))))) <> 0))))) Then
            rbuBadControlError(arg0)
        Else
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 3ULL))))) Then
                If (-Cast(c2fb_c_int, ((local0->zIdx = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_4 = CPtr(c2fb_i64 Ptr, @(arg0->nPhaseOneStep))
                    c2fb_temp_5 = Cast(c2fb_int64, ((*c2fb_temp_4) + Cast(c2fb_int64, arg0->objiter.nIndex)))
                    (*c2fb_temp_4) = Cast(c2fb_i64, c2fb_temp_5)
                    c2fb_temp_5 = Cast(c2fb_int64, (*c2fb_temp_4))
                    rbuStepOneOp(arg0, Cast(c2fb_c_int, 2ULL))
                End If
                If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                    rbuStepOneOp(arg0, Cast(c2fb_c_int, 1ULL))
                End If
            Else
                If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, 6ULL))))) Then
                    rbuStepOneOp(arg0, local2)
                Else
                    ' C automatic storage declaration
                    local4 = Cast(c2fb_c_int, &O0ULL)
                    c2fb_temp_6 = 1
                    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 6ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
                        c2fbRbuAssert(StrPtr(!"eType==RBU_UPDATE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3519ULL))
                        c2fb_temp_6 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
                    End If
                    c2fb_temp_7 = (c2fb_temp_6)
                    c2fb_temp_8 = CPtr(c2fb_i64 Ptr, @(arg0->nPhaseOneStep))
                    c2fb_temp_9 = Cast(c2fb_int64, ((*c2fb_temp_8) - Cast(c2fb_int64, arg0->objiter.nIndex)))
                    (*c2fb_temp_8) = Cast(c2fb_i64, c2fb_temp_9)
                    c2fb_temp_9 = Cast(c2fb_int64, (*c2fb_temp_8))
                    rbuGetUpdateStmt(arg0, local0, local1, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local4)))
                    If local4 Then
                        ' C automatic storage declaration
                        c2fb_temp_10 = Cast(c2fb_c_int, &O0ULL)
                        local5 = c2fb_temp_10
                        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local5 < local0->nCol)))) <> 0)))))
                            local6 = CPtr(Const Byte Ptr, local1)[local0->aiSrcOrder[local5]]
                            c2fb_temp_12 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(CPtr(c2fb_sqlite3_stmt Ptr, local0->pSelect), local5))
                            local3 = c2fb_temp_12
                            If (-Cast(c2fb_c_int, (((local0->abTblPk[local5] <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, local6) <> Cast(c2fb_c_int, 46))))) <> 0))))) Then
                                c2fb_temp_13 = CPtr(Long Ptr, @(arg0->rc))
                                c2fb_temp_14 = c2fb_external_sqlite3_bind_value(local4, Cast(c2fb_c_int, (local5 + Cast(c2fb_c_int, 1ULL))), CPtr(Const c2fb_sqlite3_value Ptr, local3))
                                (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
                                c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
                            End If
                        c2fb_flow_1:
                            c2fb_temp_11 = local5
                            local5 = Cast(c2fb_c_int, (c2fb_temp_11 + 1))
                        Wend
                        c2fb_flow_0:
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eType = Cast(c2fb_c_int, 5ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->eType = Cast(c2fb_c_int, 1ULL))))) <> 0)))))) <> 0))))) Then
                            ' empty C statement
                            c2fb_temp_15 = CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(CPtr(c2fb_sqlite3_stmt Ptr, local0->pSelect), Cast(c2fb_c_int, (local0->nCol + Cast(c2fb_c_int, 1ULL)))))
                            local3 = c2fb_temp_15
                            c2fb_temp_16 = CPtr(Long Ptr, @(arg0->rc))
                            c2fb_temp_17 = c2fb_external_sqlite3_bind_value(local4, Cast(c2fb_c_int, (local0->nCol + Cast(c2fb_c_int, 1ULL))), CPtr(Const c2fb_sqlite3_value Ptr, local3))
                            (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
                            c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
                        End If
                        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_external_sqlite3_step(local4)
                            c2fb_temp_18 = CPtr(Long Ptr, @(arg0->rc))
                            c2fb_temp_19 = resetAndCollectError(local4, CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
                            (*c2fb_temp_18) = Cast(Long, c2fb_temp_19)
                            c2fb_temp_19 = Cast(c2fb_c_int, (*c2fb_temp_18))
                        End If
                    End If
                End If
            End If
        End If
    End If
    Return arg0->rc
End Function
Private Sub rbuIncrSchemaCookie CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3556
    Dim local0 As c2fb_sqlite3 Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = (IIf(((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain)))
        local1 = Cast(c2fb_c_int, 1000000ULL)
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = prepareAndCollectError(local0, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local2)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"PRAGMA schema_version"))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local2))))) Then
                c2fb_temp_2 = c2fb_external_sqlite3_column_int(local2, Cast(c2fb_c_int, &O0ULL))
                local1 = c2fb_temp_2
            End If
            rbuFinalize(arg0, local2)
        End If
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"PRAGMA schema_version = %d"), Cast(c2fb_c_int, (local1 + Cast(c2fb_c_int, 1ULL))))
        End If
    End If
End Sub
Private Sub rbuSaveState CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3587
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As c2fb_rbu_file Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, 101ULL))))) <> 0))))) Then
        local0 = Cast(c2fb_c_int, &O0ULL)
        local1 = (IIf(((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), CPtr(c2fb_rbu_file Ptr, arg0->pRbuFd), CPtr(c2fb_rbu_file Ptr, arg0->pTargetFd)))
        ' C automatic storage declaration
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->zErrmsg = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"p->zErrmsg==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3593ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        c2fb_temp_2 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"INSERT OR REPLACE INTO %s.rbu_state(k, v) VALUES (%d, %d), (%d, %Q), (%d, %Q), (%d, %d), (%d, %lld), (%d, %lld), (%d, %lld), (%d, %lld), (%d, %lld), (%d, %Q)  "), CPtr(ZString Ptr, (@arg0->zStateDb(0))), Cast(c2fb_c_int, 1ULL), arg1, Cast(c2fb_c_int, 2ULL), arg0->objiter.zTbl, Cast(c2fb_c_int, 3ULL), arg0->objiter.zIdx, Cast(c2fb_c_int, 4ULL), arg0->nStep, Cast(c2fb_c_int, 5ULL), arg0->nProgress, Cast(c2fb_c_int, 6ULL), arg0->iWalCksum, Cast(c2fb_c_int, 7ULL), Cast(c2fb_int64, local1->iCookie), Cast(c2fb_c_int, 8ULL), arg0->iOalSz, Cast(c2fb_c_int, 9ULL), arg0->nPhaseOneStep, Cast(c2fb_c_int, 10ULL), arg0->objiter.zDataTbl)))
        local2 = c2fb_temp_2
        c2fb_temp_3 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"pInsert==0 || rc==SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3620ULL))
            c2fb_temp_3 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_4 = (c2fb_temp_3)
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_step(local0)
            c2fb_temp_5 = c2fb_external_sqlite3_finalize(local0)
            local2 = c2fb_temp_5
        End If
        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_6 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_7 = local2
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        End If
    End If
End Sub
Private Sub rbuCopyPragma CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Const ZString Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3648
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_1 = prepareFreeAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"PRAGMA main.%s"), arg1)))
        (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local0))))) <> 0))))) Then
            c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_3 = rbuMPrintfExec(arg0, CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"PRAGMA main.%s = %d"), arg1, c2fb_external_sqlite3_column_int(local0, Cast(c2fb_c_int, &O0ULL)))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        End If
        rbuFinalize(arg0, local0)
    End If
End Sub
Private Sub rbuCreateTargetSchema CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3668
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim local3 As c2fb_sqlite3_stmt Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As Long Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    local1 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL))))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"rbuIsVacuum(p)"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3672ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_3 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"PRAGMA writable_schema=1"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
    (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_4 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_5 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"SELECT sql FROM sqlite_schema WHERE sql!='' AND rootpage!=0 AND name!='sqlite_sequence'  ORDER BY type DESC"))
        (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
    End If
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local0) = Cast(c2fb_c_int, 100ULL))))) <> 0)))))
        local2 = CPtr(Const ZString Ptr, CPtr(Const UByte Ptr, c2fb_external_sqlite3_column_text(local0, Cast(c2fb_c_int, &O0ULL))))
        local3 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_6 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_7 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local3)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), local2)
        (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
        c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_step(local3)
            rbuFinalize(arg0, local3)
        End If
    c2fb_flow_1:
    Wend
    c2fb_flow_0:
    rbuFinalize(arg0, local0)
    If (-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_8 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_9 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"SELECT * FROM sqlite_schema WHERE rootpage=0 OR rootpage IS NULL"))
        (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
    End If
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_10 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_11 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"INSERT INTO sqlite_schema VALUES(?,?,?,?,?)"))
        (*c2fb_temp_10) = Cast(Long, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
    End If
    While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_step(local0) = Cast(c2fb_c_int, 100ULL))))) <> 0)))))
        ' C automatic storage declaration
        c2fb_temp_12 = Cast(c2fb_c_int, &O0ULL)
        local4 = c2fb_temp_12
        While (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, 5ULL)))))
            c2fb_external_sqlite3_bind_value(local1, Cast(c2fb_c_int, (local4 + Cast(c2fb_c_int, 1ULL))), CPtr(Const c2fb_sqlite3_value Ptr, CPtr(c2fb_sqlite3_value Ptr, c2fb_external_sqlite3_column_value(local0, local4))))
        c2fb_flow_5:
            c2fb_temp_13 = local4
            local4 = Cast(c2fb_c_int, (c2fb_temp_13 + 1))
        Wend
        c2fb_flow_4:
        c2fb_external_sqlite3_step(local1)
        c2fb_temp_14 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_15 = c2fb_external_sqlite3_reset(local1)
        (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
        c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
    c2fb_flow_3:
    Wend
    c2fb_flow_2:
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_16 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_17 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"PRAGMA writable_schema=0"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
        (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
        c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
    End If
    rbuFinalize(arg0, local0)
    rbuFinalize(arg0, local1)
End Sub
' c2fb skipped sqlite3rbu_step: outside the supported subset
' c2fb body diagnostic [volatile-semantics-not-preserved] line 3725: sqlite3rbu_step: volatile access semantics are not preserved by FreeBASIC
Private Function rbuStrCompare CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3854
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 1ULL)
    End If
    Return ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_stricmp(arg0, arg1) <> Cast(c2fb_c_int, &O0ULL))))))
End Function
Private Sub rbuSetupOal CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_RbuState Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3870
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local0 As c2fb_RbuObjIter Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As ZString Ptr Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int

    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->rc==SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3871ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If arg1->zTbl Then
        local0 = CPtr(c2fb_RbuObjIter Ptr, @(arg0->objiter))
        local1 = Cast(c2fb_c_int, &O0ULL)
        While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local0->zTbl <> 0) AndAlso (((-Cast(c2fb_c_int, (((local0->bCleanup <> 0) OrElse (rbuStrCompare(local0->zIdx, CPtr(Const ZString Ptr, arg1->zIdx)) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->zDataTbl = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (rbuStrCompare(local0->zTbl, CPtr(Const ZString Ptr, arg1->zTbl)) <> 0)))))) <> 0) OrElse (((-Cast(c2fb_c_int, (((arg1->zDataTbl <> 0) AndAlso (rbuStrCompare(local0->zDataTbl, CPtr(Const ZString Ptr, arg1->zDataTbl)) <> 0)))))) <> 0)))))) <> 0)))))
            c2fb_temp_2 = rbuObjIterNext(arg0, local0)
            local1 = c2fb_temp_2
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (local0->zTbl = 0))) <> 0))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, 1ULL)
            local1 = c2fb_temp_3
            c2fb_temp_4 = CPtr(ZString Ptr Ptr, @(arg0->zErrmsg))
            c2fb_temp_5 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"rbu_state mismatch error")))
            (*c2fb_temp_4) = c2fb_temp_5
        End If
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_6 = CPtr(Long Ptr, @(arg0->nStep))
            c2fb_temp_7 = arg1->nRow
            (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
            c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            c2fb_temp_8 = rbuObjIterPrepareAll(arg0, CPtr(c2fb_RbuObjIter Ptr, @(arg0->objiter)), arg0->nStep)
            local1 = c2fb_temp_8
        End If
        c2fb_temp_9 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_10 = local1
        (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
        c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
    End If
End Sub
Private Sub rbuDeleteOalFile CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3903
    Dim local0 As ZString Ptr
    Dim local1 As c2fb_sqlite3_vfs Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(ZString Ptr, rbuMPrintf(arg0, StrPtr(!"%s-oal"), arg0->zTarget))
    If local0 Then
        local1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_external_sqlite3_file_control(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"main"), Cast(c2fb_c_int, 27ULL), CPtr(Any Ptr, CPtr(c2fb_sqlite3_vfs Ptr Ptr, @(local1))))
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->zErrmsg = Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"pVfs && p->rc==SQLITE_OK && p->zErrmsg==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3908ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        CPtr(c2fb_callback_20, local1->xDelete)(local1, CPtr(Const ZString Ptr, local0), Cast(c2fb_c_int, &O0ULL))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
Private Sub rbuCreateVfs CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3920
    Dim local0 As c2fb_c_int
    Dim local1(0 To 63) As Byte
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local2 As c2fb_sqlite3_vfs Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Const ZString Ptr Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim c2fb_temp_9 As c2fb_sqlite3rbu_ Ptr Ptr
    Dim c2fb_temp_10 As c2fb_sqlite3rbu Ptr

    ' C automatic storage declaration
    ' C automatic array storage
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->rc==SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3924ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    c2fb_external_sqlite3_randomness(Cast(c2fb_size_t, 4ULL), CPtr(Any Ptr, CPtr(c2fb_c_int Ptr, @(local0))))
    c2fb_temp_2 = CPtr(ZString Ptr, c2fb_external_sqlite3_snprintf(Cast(c2fb_size_t, (64ULL * SizeOf(Byte))), CPtr(ZString Ptr, CPtr(Byte Ptr, (@local1(0)))), StrPtr(!"rbu_vfs_%d"), local0))
    c2fb_temp_3 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_4 = sqlite3rbu_create_vfs(CPtr(Const ZString Ptr, CPtr(Byte Ptr, (@local1(0)))), CPtr(Const ZString Ptr, 0))
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local2 = CPtr(c2fb_sqlite3_vfs Ptr, c2fb_external_sqlite3_vfs_find(CPtr(Const ZString Ptr, CPtr(Byte Ptr, (@local1(0))))))
        c2fb_temp_5 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((local2) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"pVfs"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3930ULL))
            c2fb_temp_5 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_6 = (c2fb_temp_5)
        c2fb_temp_7 = CPtr(Const ZString Ptr Ptr, @(arg0->zVfsName))
        c2fb_temp_8 = local2->zName
        (*c2fb_temp_7) = c2fb_temp_8
        c2fb_temp_9 = CPtr(c2fb_sqlite3rbu_ Ptr Ptr, @((CPtr(c2fb_rbu_vfs Ptr, local2))->pRbu))
        c2fb_temp_10 = arg0
        (*c2fb_temp_9) = CPtr(c2fb_sqlite3rbu_ Ptr, c2fb_temp_10)
        c2fb_temp_10 = CPtr(c2fb_sqlite3rbu Ptr, (*c2fb_temp_9))
    End If
End Sub
Private Sub rbuDeleteVfs CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3940
    Dim c2fb_temp_0 As Const ZString Ptr Ptr
    Dim c2fb_temp_1 As Const ZString Ptr

    If arg0->zVfsName Then
        sqlite3rbu_destroy_vfs(arg0->zVfsName)
        c2fb_temp_0 = CPtr(Const ZString Ptr Ptr, @(arg0->zVfsName))
        c2fb_temp_1 = CPtr(Const ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_0) = c2fb_temp_1
    End If
End Sub
Private Sub rbuIndexCntFunc CDecl (ByVal arg0 As c2fb_sqlite3_context Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_sqlite3_value Ptr Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 3952
    Dim local0 As c2fb_sqlite3rbu Ptr
    Dim local1 As c2fb_sqlite3_stmt Ptr
    Dim local2 As ZString Ptr
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int

    local0 = CPtr(c2fb_sqlite3rbu Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_user_data(arg0)))
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = Cast(c2fb_c_int, &O0ULL)
    ' C automatic storage declaration
    local4 = (IIf(((-Cast(c2fb_c_int, (((local0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), CPtr(c2fb_sqlite3 Ptr, local0->dbRbu), CPtr(c2fb_sqlite3 Ptr, local0->dbMain)))
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"nVal==1"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 3963ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    ' C unused-parameter annotation
    c2fb_temp_2 = prepareFreeAndCollectError(local4, CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local1)), CPtr(ZString Ptr Ptr, @(local2)), CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"SELECT count(*) FROM sqlite_schema WHERE type='index' AND tbl_name = %Q"), CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text(arg2[Cast(c2fb_c_int, &O0ULL)])))))
    local3 = c2fb_temp_2
    If (-Cast(c2fb_c_int, ((local3 <> Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_external_sqlite3_result_error(arg0, CPtr(Const ZString Ptr, local2), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
    Else
        local5 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local1))))) Then
            c2fb_temp_3 = c2fb_external_sqlite3_column_int(local1, Cast(c2fb_c_int, &O0ULL))
            local5 = c2fb_temp_3
        End If
        c2fb_temp_4 = c2fb_external_sqlite3_finalize(local1)
        local3 = c2fb_temp_4
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_external_sqlite3_result_int(arg0, local5)
        Else
            c2fb_external_sqlite3_result_error(arg0, CPtr(Const ZString Ptr, c2fb_external_sqlite3_errmsg(local4)), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        End If
    End If
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
End Sub
Private Sub rbuInitPhaseOneSteps CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4003
    Dim local0 As c2fb_sqlite3_stmt Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Long Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Long Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_i64 Ptr
    Dim c2fb_temp_12 As c2fb_int64
    Dim c2fb_temp_13 As Long Ptr
    Dim c2fb_temp_14 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
        local0 = Cast(c2fb_c_int, &O0ULL)
        local1 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->nPhaseOneStep))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
        c2fb_temp_3 = c2fb_external_sqlite3_create_function(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"rbu_index_cnt"), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, 1ULL), CPtr(Any Ptr, arg0), ProcPtr(rbuIndexCntFunc), CPtr(c2fb_callback_104, 0), CPtr(c2fb_callback_105, 0))
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_4 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_5 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"SELECT 1 FROM sqlite_schema WHERE tbl_name = 'rbu_count'"))
            (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
            c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
        End If
        If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local0))))) Then
                c2fb_temp_6 = Cast(c2fb_c_int, 1ULL)
                local1 = c2fb_temp_6
            End If
            c2fb_temp_7 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_8 = c2fb_external_sqlite3_finalize(local0)
            (*c2fb_temp_7) = Cast(Long, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_int, (*c2fb_temp_7))
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (local1 <> 0))))) Then
            c2fb_temp_9 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_10 = prepareAndCollectError(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3_stmt Ptr Ptr, @(local0)), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)), StrPtr(!"SELECT sum(cnt * (1 + rbu_index_cnt(rbu_target_name(tbl))))FROM rbu_count"))
            (*c2fb_temp_9) = Cast(Long, c2fb_temp_10)
            c2fb_temp_10 = Cast(c2fb_c_int, (*c2fb_temp_9))
            If (-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 100ULL) = c2fb_external_sqlite3_step(local0))))) Then
                    c2fb_temp_11 = CPtr(c2fb_i64 Ptr, @(arg0->nPhaseOneStep))
                    c2fb_temp_12 = c2fb_external_sqlite3_column_int64(local0, Cast(c2fb_c_int, &O0ULL))
                    (*c2fb_temp_11) = Cast(c2fb_i64, c2fb_temp_12)
                    c2fb_temp_12 = Cast(c2fb_int64, (*c2fb_temp_11))
                End If
                c2fb_temp_13 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_14 = c2fb_external_sqlite3_finalize(local0)
                (*c2fb_temp_13) = Cast(Long, c2fb_temp_14)
                c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
            End If
        End If
    End If
End Sub
Private Function openRbuHandle CDecl (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_sqlite3rbu Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4044
    Dim local0 As c2fb_sqlite3rbu Ptr
    Dim local1 As c2fb_size_t
    Dim local2 As c2fb_size_t
    Dim local3 As c2fb_size_t
    Dim c2fb_temp_0 As c2fb_sqlite3rbu Ptr
    Dim local4 As c2fb_RbuState Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As ZString Ptr
    Dim c2fb_temp_6 As ZString Ptr Ptr
    Dim c2fb_temp_7 As ZString Ptr
    Dim c2fb_temp_8 As Any Ptr
    Dim c2fb_temp_9 As ZString Ptr
    Dim c2fb_temp_10 As ZString Ptr Ptr
    Dim c2fb_temp_11 As ZString Ptr
    Dim c2fb_temp_12 As c2fb_RbuState Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Long Ptr
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As Long Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_i64 Ptr
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_sqlite3_int64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_i64 Ptr
    Dim c2fb_temp_24 As c2fb_int64
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As Long Ptr
    Dim c2fb_temp_28 As c2fb_c_int
    Dim c2fb_temp_29 As ZString Ptr Ptr
    Dim c2fb_temp_30 As ZString Ptr
    Dim c2fb_temp_31 As Long Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As Long Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim local7 As c2fb_rbu_file Ptr
    Dim c2fb_temp_35 As Long Ptr
    Dim c2fb_temp_36 As c2fb_c_int
    Dim c2fb_temp_37 As ZString Ptr Ptr
    Dim c2fb_temp_38 As ZString Ptr
    Dim local8 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_39 As Long Ptr
    Dim c2fb_temp_40 As c2fb_c_int
    Dim c2fb_temp_41 As Long Ptr
    Dim c2fb_temp_42 As c2fb_c_int
    Dim c2fb_temp_43 As Long Ptr
    Dim c2fb_temp_44 As c2fb_c_int
    Dim c2fb_temp_45 As Long Ptr
    Dim c2fb_temp_46 As c2fb_c_int
    Dim c2fb_temp_47 As Long Ptr
    Dim c2fb_temp_48 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_49 As Long Ptr
    Dim c2fb_temp_50 As c2fb_c_int
    Dim c2fb_temp_51 As Long Ptr
    Dim c2fb_temp_52 As c2fb_c_int
    Dim c2fb_temp_53 As Long Ptr
    Dim c2fb_temp_54 As c2fb_c_int
    Dim c2fb_temp_55 As Long Ptr
    Dim c2fb_temp_56 As c2fb_c_int
    Dim c2fb_temp_57 As Long Ptr
    Dim c2fb_temp_58 As c2fb_c_int

    ' C automatic storage declaration
    local1 = IIf(arg0, Cast(c2fb_c_uint, c2fb_crt_strlen(arg0)), Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))
    local2 = c2fb_crt_strlen(arg1)
    local3 = Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_size_t, SizeOf(c2fb_sqlite3rbu))) + Cast(c2fb_c_uint, local1))) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))) + Cast(c2fb_c_uint, local2))) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))
    c2fb_temp_0 = CPtr(c2fb_sqlite3rbu Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(local3)))
    local0 = c2fb_temp_0
    If local0 Then
        local4 = Cast(c2fb_c_int, &O0ULL)
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_sqlite3rbu))))
        sqlite3rbu_rename_handler(local0, CPtr(Any Ptr, 0), CPtr(c2fb_callback_98, 0))
        rbuCreateVfs(local0)
        If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            local5 = CPtr(ZString Ptr, CPtr(c2fb_sqlite3rbu Ptr, @(CPtr(c2fb_sqlite3rbu Ptr, local0)[Cast(c2fb_c_int, 1ULL)])))
            local6 = Cast(c2fb_c_int, &O0ULL)
            If arg0 Then
                c2fb_temp_2 = CPtr(ZString Ptr Ptr, @(local0->zTarget))
                c2fb_temp_3 = local5
                (*c2fb_temp_2) = c2fb_temp_3
                c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0->zTarget), CPtr(Const Any Ptr, arg0), Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local1) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))))
                c2fb_temp_5 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local5) + Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local1) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))))
                local5 = c2fb_temp_5
            End If
            c2fb_temp_6 = CPtr(ZString Ptr Ptr, @(local0->zRbu))
            c2fb_temp_7 = local5
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0->zRbu), CPtr(Const Any Ptr, arg1), Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local2) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))))
            c2fb_temp_9 = CPtr(ZString Ptr, (CPtr(Byte Ptr, local5) + Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local2) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL))))))
            local5 = c2fb_temp_9
            If arg2 Then
                c2fb_temp_10 = CPtr(ZString Ptr Ptr, @(local0->zState))
                c2fb_temp_11 = CPtr(ZString Ptr, rbuMPrintf(local0, StrPtr(!"%s"), arg2))
                (*c2fb_temp_10) = c2fb_temp_11
            End If
            rbuOpenDatabase(local0, CPtr(c2fb_sqlite3 Ptr, 0), CPtr(c2fb_c_int Ptr, @(local6)))
            If local6 Then
                rbuOpenDatabase(local0, CPtr(c2fb_sqlite3 Ptr, 0), CPtr(c2fb_c_int Ptr, 0))
            End If
        End If
        If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_12 = CPtr(c2fb_RbuState Ptr, rbuLoadState(local0))
            local4 = c2fb_temp_12
            c2fb_temp_13 = 1
            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((local4 <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->rc <> Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
                c2fbRbuAssert(StrPtr(!"pState || p->rc!=SQLITE_OK"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4094ULL))
                c2fb_temp_13 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
            End If
            c2fb_temp_14 = (c2fb_temp_13)
            If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((local4->eStage = Cast(c2fb_c_int, &O0ULL))))) Then
                    rbuDeleteOalFile(local0)
                    rbuInitPhaseOneSteps(local0)
                    c2fb_temp_15 = CPtr(Long Ptr, @(local0->eStage))
                    c2fb_temp_16 = Cast(c2fb_c_int, 1ULL)
                    (*c2fb_temp_15) = Cast(Long, c2fb_temp_16)
                    c2fb_temp_16 = Cast(c2fb_c_int, (*c2fb_temp_15))
                Else
                    c2fb_temp_17 = CPtr(Long Ptr, @(local0->eStage))
                    c2fb_temp_18 = local4->eStage
                    (*c2fb_temp_17) = Cast(Long, c2fb_temp_18)
                    c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
                    c2fb_temp_19 = CPtr(c2fb_i64 Ptr, @(local0->nPhaseOneStep))
                    c2fb_temp_20 = local4->nPhaseOneStep
                    (*c2fb_temp_19) = Cast(c2fb_i64, c2fb_temp_20)
                    c2fb_temp_20 = Cast(c2fb_int64, (*c2fb_temp_19))
                End If
                c2fb_temp_21 = CPtr(c2fb_sqlite3_int64 Ptr, @(local0->nProgress))
                c2fb_temp_22 = local4->nProgress
                (*c2fb_temp_21) = Cast(c2fb_sqlite3_int64, c2fb_temp_22)
                c2fb_temp_22 = Cast(c2fb_int64, (*c2fb_temp_21))
                c2fb_temp_23 = CPtr(c2fb_i64 Ptr, @(local0->iOalSz))
                c2fb_temp_24 = local4->iOalSz
                (*c2fb_temp_23) = Cast(c2fb_i64, c2fb_temp_24)
                c2fb_temp_24 = Cast(c2fb_int64, (*c2fb_temp_23))
            End If
        End If
        c2fb_temp_25 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->rc <> Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->eStage <> Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"p->rc!=SQLITE_OK || p->eStage!=0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4109ULL))
            c2fb_temp_25 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_26 = (c2fb_temp_25)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_rbu_file Ptr, CPtr(c2fb_rbu_file Ptr, local0->pTargetFd)->pWalFd) <> 0))))) Then
            If (-Cast(c2fb_c_int, ((local0->eStage = Cast(c2fb_c_int, 1ULL))))) Then
                c2fb_temp_27 = CPtr(Long Ptr, @(local0->rc))
                c2fb_temp_28 = Cast(c2fb_c_int, 1ULL)
                (*c2fb_temp_27) = Cast(Long, c2fb_temp_28)
                c2fb_temp_28 = Cast(c2fb_c_int, (*c2fb_temp_27))
                c2fb_temp_29 = CPtr(ZString Ptr Ptr, @(local0->zErrmsg))
                c2fb_temp_30 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"cannot update wal mode database")))
                (*c2fb_temp_29) = c2fb_temp_30
            Else
                If (-Cast(c2fb_c_int, ((local0->eStage = Cast(c2fb_c_int, 2ULL))))) Then
                    c2fb_temp_31 = CPtr(Long Ptr, @(local0->eStage))
                    c2fb_temp_32 = Cast(c2fb_c_int, 4ULL)
                    (*c2fb_temp_31) = Cast(Long, c2fb_temp_32)
                    c2fb_temp_32 = Cast(c2fb_c_int, (*c2fb_temp_31))
                    c2fb_temp_33 = CPtr(Long Ptr, @(local0->nStep))
                    c2fb_temp_34 = Cast(c2fb_c_int, &O0ULL)
                    (*c2fb_temp_33) = Cast(Long, c2fb_temp_34)
                    c2fb_temp_34 = Cast(c2fb_c_int, (*c2fb_temp_33))
                End If
            End If
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local0->eStage = Cast(c2fb_c_int, 2ULL))))) <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4->eStage <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
            local7 = (IIf(((-Cast(c2fb_c_int, (((local0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), CPtr(c2fb_rbu_file Ptr, local0->pRbuFd), CPtr(c2fb_rbu_file Ptr, local0->pTargetFd)))
            If (-Cast(c2fb_c_int, ((local7->iCookie <> local4->iCookie)))) Then
                c2fb_temp_35 = CPtr(Long Ptr, @(local0->rc))
                c2fb_temp_36 = Cast(c2fb_c_int, 5ULL)
                (*c2fb_temp_35) = Cast(Long, c2fb_temp_36)
                c2fb_temp_36 = Cast(c2fb_c_int, (*c2fb_temp_35))
                c2fb_temp_37 = CPtr(ZString Ptr Ptr, @(local0->zErrmsg))
                c2fb_temp_38 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"database modified during rbu %s"), (IIf(((-Cast(c2fb_c_int, (((local0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), StrPtr(!"vacuum"), StrPtr(!"update")))))
                (*c2fb_temp_37) = c2fb_temp_38
            End If
        End If
        If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((local0->eStage = Cast(c2fb_c_int, 1ULL))))) Then
                local8 = CPtr(c2fb_sqlite3 Ptr, local0->dbMain)
                c2fb_temp_39 = CPtr(Long Ptr, @(local0->rc))
                c2fb_temp_40 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, local0->dbRbu), StrPtr(!"BEGIN"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(local0->zErrmsg)))
                (*c2fb_temp_39) = Cast(Long, c2fb_temp_40)
                c2fb_temp_40 = Cast(c2fb_c_int, (*c2fb_temp_39))
                If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                    c2fb_temp_41 = CPtr(Long Ptr, @(local0->rc))
                    c2fb_temp_42 = rbuObjIterFirst(local0, CPtr(c2fb_RbuObjIter Ptr, @(local0->objiter)))
                    (*c2fb_temp_41) = Cast(Long, c2fb_temp_42)
                    c2fb_temp_42 = Cast(c2fb_c_int, (*c2fb_temp_41))
                End If
                If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->objiter.zTbl = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                    c2fb_temp_43 = CPtr(Long Ptr, @(local0->rc))
                    c2fb_temp_44 = Cast(c2fb_c_int, 101ULL)
                    (*c2fb_temp_43) = Cast(Long, c2fb_temp_44)
                    c2fb_temp_44 = Cast(c2fb_c_int, (*c2fb_temp_43))
                    c2fb_temp_45 = CPtr(Long Ptr, @(local0->eStage))
                    c2fb_temp_46 = Cast(c2fb_c_int, 5ULL)
                    (*c2fb_temp_45) = Cast(Long, c2fb_temp_46)
                    c2fb_temp_46 = Cast(c2fb_c_int, (*c2fb_temp_45))
                Else
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local4->eStage = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((local0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
                        rbuCopyPragma(local0, StrPtr(!"page_size"))
                        rbuCopyPragma(local0, StrPtr(!"auto_vacuum"))
                    End If
                    If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                        c2fb_temp_47 = CPtr(Long Ptr, @(local0->rc))
                        c2fb_temp_48 = c2fb_external_sqlite3_exec(local8, StrPtr(!"BEGIN IMMEDIATE"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(local0->zErrmsg)))
                        (*c2fb_temp_47) = Cast(Long, c2fb_temp_48)
                        c2fb_temp_48 = Cast(c2fb_c_int, (*c2fb_temp_47))
                    End If
                    If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                        local9 = c2fb_external_sqlite3_file_control(local8, StrPtr(!"main"), Cast(c2fb_c_int, 25ULL), CPtr(Any Ptr, 0))
                        If (-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, &O0ULL))))) Then
                            c2fb_temp_49 = CPtr(Long Ptr, @(local0->rc))
                            c2fb_temp_50 = c2fb_external_sqlite3_exec(local8, StrPtr(!"PRAGMA journal_mode=off"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(local0->zErrmsg)))
                            (*c2fb_temp_49) = Cast(Long, c2fb_temp_50)
                            c2fb_temp_50 = Cast(c2fb_c_int, (*c2fb_temp_49))
                        End If
                    End If
                    If (-Cast(c2fb_c_int, ((local0->rc = Cast(c2fb_c_int, &O0ULL))))) Then
                        rbuSetupOal(local0, local4)
                    End If
                End If
            Else
                If (-Cast(c2fb_c_int, ((local0->eStage = Cast(c2fb_c_int, 2ULL))))) Then
                    ' empty C block
                Else
                    If (-Cast(c2fb_c_int, ((local0->eStage = Cast(c2fb_c_int, 4ULL))))) Then
                        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((local0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) = 0))) <> 0) AndAlso (rbuExclusiveCheckpoint(CPtr(c2fb_sqlite3 Ptr, local0->dbMain)) <> 0))))) Then
                            c2fb_temp_51 = CPtr(Long Ptr, @(local0->eStage))
                            c2fb_temp_52 = Cast(c2fb_c_int, 5ULL)
                            (*c2fb_temp_51) = Cast(Long, c2fb_temp_52)
                            c2fb_temp_52 = Cast(c2fb_c_int, (*c2fb_temp_51))
                            rbuLockDatabase(CPtr(c2fb_sqlite3 Ptr, local0->dbMain))
                            c2fb_temp_53 = CPtr(Long Ptr, @(local0->eStage))
                            c2fb_temp_54 = Cast(c2fb_c_int, 4ULL)
                            (*c2fb_temp_53) = Cast(Long, c2fb_temp_54)
                            c2fb_temp_54 = Cast(c2fb_c_int, (*c2fb_temp_53))
                        End If
                        rbuSetupCheckpoint(local0, local4)
                    Else
                        If (-Cast(c2fb_c_int, ((local0->eStage = Cast(c2fb_c_int, 5ULL))))) Then
                            c2fb_temp_55 = CPtr(Long Ptr, @(local0->rc))
                            c2fb_temp_56 = Cast(c2fb_c_int, 101ULL)
                            (*c2fb_temp_55) = Cast(Long, c2fb_temp_56)
                            c2fb_temp_56 = Cast(c2fb_c_int, (*c2fb_temp_55))
                        Else
                            c2fb_temp_57 = CPtr(Long Ptr, @(local0->rc))
                            c2fb_temp_58 = Cast(c2fb_c_int, 11ULL)
                            (*c2fb_temp_57) = Cast(Long, c2fb_temp_58)
                            c2fb_temp_58 = Cast(c2fb_c_int, (*c2fb_temp_57))
                        End If
                    End If
                End If
            End If
        End If
        rbuFreeState(local4)
    End If
    Return local0
End Function
Private Function rbuMisuseError CDecl () As c2fb_sqlite3rbu Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4209
    Dim local0 As c2fb_sqlite3rbu Ptr
    Dim c2fb_temp_0 As c2fb_sqlite3rbu Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int

    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(_c2fb_record_c2fb_sqlite3rbu Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_size_t, SizeOf(c2fb_sqlite3rbu)))))
    local0 = c2fb_temp_0
    If local0 Then
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_sqlite3rbu))))
        c2fb_temp_2 = CPtr(Long Ptr, @(local0->rc))
        c2fb_temp_3 = Cast(c2fb_c_int, 21ULL)
        (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
        c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
    End If
    Return local0
End Function
Function sqlite3rbu_open CDecl Alias "sqlite3rbu_open" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_sqlite3rbu Ptr Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4222
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        Return CPtr(c2fb_sqlite3rbu Ptr, rbuMisuseError())
    End If
    Return CPtr(c2fb_sqlite3rbu Ptr, openRbuHandle(arg0, arg1, arg2))
End Function
Function sqlite3rbu_vacuum CDecl Alias "sqlite3rbu_vacuum" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_sqlite3rbu Ptr Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4234
    Dim local0 As c2fb_size_t

    If (-Cast(c2fb_c_int, ((arg0 = Cast(c2fb_c_int, &O0ULL))))) Then
        Return CPtr(c2fb_sqlite3rbu Ptr, rbuMisuseError())
    End If
    If arg1 Then
        local0 = c2fb_crt_strlen(arg1)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, local0) >= Cast(c2fb_c_uint, Cast(c2fb_c_int, 7ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = c2fb_crt_memcmp(CPtr(Const Any Ptr, StrPtr(!"-vactmp")), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, arg1)[Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local0) - Cast(c2fb_c_uint, Cast(c2fb_c_int, 7ULL))))]))), Cast(c2fb_c_int, 7ULL)))))) <> 0))))) Then
            Return CPtr(c2fb_sqlite3rbu Ptr, rbuMisuseError())
        End If
    End If
    Return CPtr(c2fb_sqlite3rbu Ptr, openRbuHandle(CPtr(Const ZString Ptr, 0), arg0, arg1))
End Function
Function sqlite3rbu_db CDecl Alias "sqlite3rbu_db" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int) As c2fb_sqlite3 Ptr Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4252
    Dim local0 As c2fb_sqlite3 Ptr
    Dim c2fb_temp_0 As c2fb_sqlite3 Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If arg0 Then
        c2fb_temp_0 = (IIf(arg1, CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), CPtr(c2fb_sqlite3 Ptr, arg0->dbMain)))
        local0 = c2fb_temp_0
    End If
    Return local0
End Function
Private Sub rbuEditErrmsg CDecl (ByVal arg0 As c2fb_sqlite3rbu Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4266
    Dim local0 As c2fb_c_uint
    Dim local1 As c2fb_size_t
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr
    Dim c2fb_temp_4 As c2fb_size_t

    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, 19ULL))))) <> 0) AndAlso (arg0->zErrmsg <> 0))))) Then
        ' C automatic storage declaration
        local1 = c2fb_crt_strlen(CPtr(Const ZString Ptr, arg0->zErrmsg))
        c2fb_temp_0 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local1) - Cast(c2fb_c_uint, Cast(c2fb_c_int, 8ULL)))))))))
            If (-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->zErrmsg)[local0]))), CPtr(Const Any Ptr, StrPtr(!"rbu_imp_")), Cast(c2fb_c_int, 8ULL)) = Cast(c2fb_c_int, &O0ULL))))) Then
                local2 = Cast(c2fb_c_int, 8ULL)
                While (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0->zErrmsg)[Cast(c2fb_c_uint, (local0 + Cast(c2fb_c_uint, local2)))]) >= Cast(c2fb_c_int, 48))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, CPtr(Byte Ptr, arg0->zErrmsg)[Cast(c2fb_c_uint, (local0 + Cast(c2fb_c_uint, local2)))]) <= Cast(c2fb_c_int, 57))))) <> 0)))))
                    c2fb_temp_2 = local2
                    local2 = Cast(c2fb_c_int, (c2fb_temp_2 + 1))
                c2fb_flow_3:
                Wend
                c2fb_flow_2:
                c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memmove(CPtr(Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->zErrmsg)[local0]))), CPtr(Const Any Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, arg0->zErrmsg)[Cast(c2fb_c_uint, (local0 + Cast(c2fb_c_uint, local2)))]))), Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local1) + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))) - local0)) - Cast(c2fb_c_uint, local2)))))
                c2fb_temp_4 = Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local1) - Cast(c2fb_c_uint, local2)))
                local1 = c2fb_temp_4
            End If
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_uint, (c2fb_temp_1 + 1))
        Wend
        c2fb_flow_0:
    End If
End Sub
Function sqlite3rbu_close CDecl Alias "sqlite3rbu_close" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As ZString Ptr Ptr) As c2fb_c_int Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4284
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_file Ptr
    Dim c2fb_temp_2 As Long Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As ZString Ptr Ptr
    Dim c2fb_temp_12 As ZString Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As ZString Ptr Ptr
    Dim c2fb_temp_15 As ZString Ptr

    ' C automatic storage declaration
    If arg0 Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
            c2fb_temp_0 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_1 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"COMMIT"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
            (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
            c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
            local1 = CPtr(c2fb_sqlite3_file Ptr, CPtr(c2fb_rbu_file Ptr, arg0->pTargetFd)->pReal)
            c2fb_temp_2 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_3 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, local1->pMethods)->xSync)(local1, Cast(c2fb_c_int, &H00002ULL))
            (*c2fb_temp_2) = Cast(Long, c2fb_temp_3)
            c2fb_temp_3 = Cast(c2fb_c_int, (*c2fb_temp_2))
        End If
        rbuSaveState(arg0, arg0->eStage)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
            c2fb_temp_4 = CPtr(Long Ptr, @(arg0->rc))
            c2fb_temp_5 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"COMMIT"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, @(arg0->zErrmsg)))
            (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
            c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
        End If
        rbuObjIterFinalize(CPtr(c2fb_RbuObjIter Ptr, @(arg0->objiter)))
        If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso (CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu) <> 0))))) Then
            local2 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"DELETE FROM stat.rbu_state"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, 0))
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc = Cast(c2fb_c_int, 101ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_6 = CPtr(Long Ptr, @(arg0->rc))
                c2fb_temp_7 = local2
                (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
                c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
            End If
        End If
        c2fb_external_sqlite3_close(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu))
        c2fb_external_sqlite3_close(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain))
        c2fb_temp_8 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((arg0->szTemp = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"p->szTemp==0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4321ULL))
            c2fb_temp_8 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_9 = (c2fb_temp_8)
        rbuDeleteVfs(arg0)
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->aBuf))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, CPtr(c2fb_RbuFrame Ptr, arg0->aFrame)))
        rbuEditErrmsg(arg0)
        c2fb_temp_10 = arg0->rc
        local0 = c2fb_temp_10
        If arg1 Then
            c2fb_temp_11 = CPtr(ZString Ptr Ptr, @((*arg1)))
            c2fb_temp_12 = arg0->zErrmsg
            (*c2fb_temp_11) = c2fb_temp_12
        Else
            c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zErrmsg))
        End If
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->zState))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    Else
        c2fb_temp_13 = Cast(c2fb_c_int, 7ULL)
        local0 = c2fb_temp_13
        c2fb_temp_14 = CPtr(ZString Ptr Ptr, @((*arg1)))
        c2fb_temp_15 = CPtr(ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_14) = c2fb_temp_15
    End If
    Return local0
End Function
Function sqlite3rbu_progress CDecl Alias "sqlite3rbu_progress" (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_int64 Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4347
    Return arg0->nProgress
End Function
Sub sqlite3rbu_bp_progress CDecl Alias "sqlite3rbu_bp_progress" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_c_int Ptr, ByVal arg2 As c2fb_c_int Ptr) Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4355
    Dim local0 As c2fb_c_int
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
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int

    local0 = Cast(c2fb_c_int, 10000ULL)
    Select Case arg0->eStage
        Case Cast(c2fb_c_int, 1ULL)
            If (-Cast(c2fb_c_int, ((arg0->nPhaseOneStep > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_1 = Cast(c2fb_c_int, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, local0) * Cast(c2fb_int64, arg0->nProgress))) \ Cast(c2fb_int64, arg0->nPhaseOneStep)))))
                (*c2fb_temp_0) = c2fb_temp_1
            Else
                c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg1)))
                c2fb_temp_3 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
                (*c2fb_temp_2) = c2fb_temp_3
            End If
            c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_5 = Cast(c2fb_c_int, &O0ULL)
            (*c2fb_temp_4) = c2fb_temp_5
        Case Cast(c2fb_c_int, 2ULL)
            c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg1)))
            c2fb_temp_7 = local0
            (*c2fb_temp_6) = c2fb_temp_7
            c2fb_temp_8 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_9 = Cast(c2fb_c_int, &O0ULL)
            (*c2fb_temp_8) = c2fb_temp_9
        Case Cast(c2fb_c_int, 4ULL)
            c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @((*arg1)))
            c2fb_temp_11 = local0
            (*c2fb_temp_10) = c2fb_temp_11
            c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_13 = Cast(c2fb_c_int, (Cast(c2fb_int64, (Cast(c2fb_int64, (Cast(c2fb_int64, local0) * Cast(c2fb_int64, arg0->nStep))) \ Cast(c2fb_int64, arg0->nFrame)))))
            (*c2fb_temp_12) = c2fb_temp_13
        Case Cast(c2fb_c_int, 5ULL)
            c2fb_temp_14 = CPtr(c2fb_c_int Ptr, @((*arg1)))
            c2fb_temp_15 = local0
            (*c2fb_temp_14) = c2fb_temp_15
            c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @((*arg2)))
            c2fb_temp_17 = local0
            (*c2fb_temp_16) = c2fb_temp_17
        Case Else
            c2fb_temp_18 = 1
            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL)) = 0))) = 0)))) <> 0) = 0) Then
                c2fbRbuAssert(StrPtr(!"0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4383ULL))
                c2fb_temp_18 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
            End If
            c2fb_temp_19 = (c2fb_temp_18)
    End Select
    c2fb_flow_0:
End Sub
Function sqlite3rbu_state CDecl Alias "sqlite3rbu_state" (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_c_int Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4390
    Dim local0(0 To 5) As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
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
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As c2fb_c_int

    Erase local0
    local0(0) = Cast(c2fb_c_int, &O0ULL)
    local0(1) = Cast(c2fb_c_int, 1ULL)
    local0(2) = Cast(c2fb_c_int, 2ULL)
    local0(3) = Cast(c2fb_c_int, &O0ULL)
    local0(4) = Cast(c2fb_c_int, 3ULL)
    local0(5) = Cast(c2fb_c_int, 4ULL)
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 1ULL) = Cast(c2fb_c_int, 1ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"RBU_STAGE_OAL==1"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4396ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    c2fb_temp_2 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 2ULL) = Cast(c2fb_c_int, 2ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"RBU_STAGE_MOVE==2"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4397ULL))
        c2fb_temp_2 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_3 = (c2fb_temp_2)
    c2fb_temp_4 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 4ULL) = Cast(c2fb_c_int, 4ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"RBU_STAGE_CKPT==4"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4398ULL))
        c2fb_temp_4 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_5 = (c2fb_temp_4)
    c2fb_temp_6 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, 5ULL) = Cast(c2fb_c_int, 5ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"RBU_STAGE_DONE==5"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4399ULL))
        c2fb_temp_6 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_7 = (c2fb_temp_6)
    c2fb_temp_8 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local0(Cast(c2fb_c_int, 1ULL)) = Cast(c2fb_c_int, 1ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"aRes[RBU_STAGE_OAL]==SQLITE_RBU_STATE_OAL"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4400ULL))
        c2fb_temp_8 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_9 = (c2fb_temp_8)
    c2fb_temp_10 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local0(Cast(c2fb_c_int, 2ULL)) = Cast(c2fb_c_int, 2ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"aRes[RBU_STAGE_MOVE]==SQLITE_RBU_STATE_MOVE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4401ULL))
        c2fb_temp_10 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_11 = (c2fb_temp_10)
    c2fb_temp_12 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local0(Cast(c2fb_c_int, 4ULL)) = Cast(c2fb_c_int, 3ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"aRes[RBU_STAGE_CKPT]==SQLITE_RBU_STATE_CHECKPOINT"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4402ULL))
        c2fb_temp_12 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_13 = (c2fb_temp_12)
    c2fb_temp_14 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local0(Cast(c2fb_c_int, 5ULL)) = Cast(c2fb_c_int, 4ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"aRes[RBU_STAGE_DONE]==SQLITE_RBU_STATE_DONE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4403ULL))
        c2fb_temp_14 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_15 = (c2fb_temp_14)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, 101ULL))))) <> 0))))) Then
        Return Cast(c2fb_c_int, 5ULL)
    Else
        c2fb_temp_16 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->rc <> Cast(c2fb_c_int, 101ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 5ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"p->rc!=SQLITE_DONE || p->eStage==RBU_STAGE_DONE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4408ULL))
            c2fb_temp_16 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_17 = (c2fb_temp_16)
        c2fb_temp_18 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 4ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 5ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"p->eStage==RBU_STAGE_OAL || p->eStage==RBU_STAGE_MOVE || p->eStage==RBU_STAGE_CKPT || p->eStage==RBU_STAGE_DONE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4409ULL))
            c2fb_temp_18 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_19 = (c2fb_temp_18)
        Return local0(arg0->eStage)
    End If
End Function
Function sqlite3rbu_savestate CDecl Alias "sqlite3rbu_savestate" (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_c_int Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4418
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim local1 As c2fb_sqlite3_file Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As Long Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local2 As Const ZString Ptr
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int

    local0 = arg0->rc
    If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, 101ULL))))) Then
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg0->eStage >= Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->eStage <= Cast(c2fb_c_int, 5ULL))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->eStage>=RBU_STAGE_OAL && p->eStage<=RBU_STAGE_DONE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4422ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_temp_2 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, 101ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"rc!=SQLITE_DONE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4424ULL))
            c2fb_temp_2 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_3 = (c2fb_temp_2)
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_4 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"COMMIT"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, 0))
            local0 = c2fb_temp_4
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 4ULL))))) <> 0))))) Then
        local1 = CPtr(c2fb_sqlite3_file Ptr, CPtr(c2fb_rbu_file Ptr, arg0->pTargetFd)->pReal)
        c2fb_temp_5 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, local1->pMethods)->xSync)(local1, Cast(c2fb_c_int, &H00002ULL))
        local0 = c2fb_temp_5
    End If
    c2fb_temp_6 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_7 = local0
    (*c2fb_temp_6) = Cast(Long, c2fb_temp_7)
    c2fb_temp_7 = Cast(c2fb_c_int, (*c2fb_temp_6))
    rbuSaveState(arg0, arg0->eStage)
    c2fb_temp_8 = arg0->rc
    local0 = c2fb_temp_8
    If (-Cast(c2fb_c_int, ((arg0->eStage = Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_temp_9 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local0 <> Cast(c2fb_c_int, 101ULL)))))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"rc!=SQLITE_DONE"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4439ULL))
            c2fb_temp_9 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_10 = (c2fb_temp_9)
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_11 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), StrPtr(!"COMMIT"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, 0))
            local0 = c2fb_temp_11
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            local2 = IIf(((-Cast(c2fb_c_int, (((arg0)->zTarget = Cast(c2fb_c_int, &O0ULL)))))), StrPtr(!"BEGIN"), StrPtr(!"BEGIN IMMEDIATE"))
            c2fb_temp_12 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbRbu), local2, CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, 0))
            local0 = c2fb_temp_12
        End If
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_13 = c2fb_external_sqlite3_exec(CPtr(c2fb_sqlite3 Ptr, arg0->dbMain), StrPtr(!"BEGIN IMMEDIATE"), CPtr(c2fb_callback_4, 0), CPtr(Any Ptr, 0), CPtr(ZString Ptr Ptr, 0))
            local0 = c2fb_temp_13
        End If
    End If
    c2fb_temp_14 = CPtr(Long Ptr, @(arg0->rc))
    c2fb_temp_15 = local0
    (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
    c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
    Return local0
End Function
Private Function xDefaultRename CDecl (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4455
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    c2fb_temp_0 = IIf(c2fb_external_rename(arg1, arg2), Cast(c2fb_c_int, 10ULL), Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_0
    Return local0
End Function
Sub sqlite3rbu_rename_handler CDecl Alias "sqlite3rbu_rename_handler" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_callback_98) Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4487
    Type c2fb_callback_storage_0 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As Long
    Dim c2fb_temp_0 As c2fb_callback_storage_0 Ptr
    Dim c2fb_temp_1 As c2fb_callback_98
    Dim c2fb_temp_2 As Any Ptr Ptr
    Dim c2fb_temp_3 As Any Ptr
    Type c2fb_callback_storage_4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As Long
    Dim c2fb_temp_4 As c2fb_callback_storage_4 Ptr
    Dim c2fb_temp_5 As c2fb_callback_98
    Dim c2fb_temp_6 As Any Ptr Ptr
    Dim c2fb_temp_7 As Any Ptr

    If arg2 Then
        c2fb_temp_0 = CPtr(c2fb_callback_storage_0 Ptr, @(arg0->xRename))
        c2fb_temp_1 = arg2
        (*c2fb_temp_0) = CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As Long, c2fb_temp_1)
        c2fb_temp_1 = CPtr(c2fb_callback_98, (*c2fb_temp_0))
        c2fb_temp_2 = CPtr(Any Ptr Ptr, @(arg0->pRenameArg))
        c2fb_temp_3 = arg1
        (*c2fb_temp_2) = c2fb_temp_3
    Else
        c2fb_temp_4 = CPtr(c2fb_callback_storage_4 Ptr, @(arg0->xRename))
        c2fb_temp_5 = ProcPtr(xDefaultRename)
        (*c2fb_temp_4) = CPtr(Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr) As Long, c2fb_temp_5)
        c2fb_temp_5 = CPtr(c2fb_callback_98, (*c2fb_temp_4))
        c2fb_temp_6 = CPtr(Any Ptr Ptr, @(arg0->pRenameArg))
        c2fb_temp_7 = CPtr(Any Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        (*c2fb_temp_6) = c2fb_temp_7
    End If
End Sub
Private Sub rbuUnlockShm CDecl (ByVal arg0 As c2fb_rbu_file Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4560
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local0 As c2fb_callback_15
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_u32 Ptr
    Dim c2fb_temp_5 As c2fb_c_uint

    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg0->openFlags And Cast(c2fb_c_int, &H00000100ULL)))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->openFlags & SQLITE_OPEN_MAIN_DB"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4561ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If CPtr(c2fb_sqlite3rbu Ptr, arg0->pRbu) Then
        local0 = CPtr(c2fb_callback_15, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, arg0->pReal)->pMethods)->xShmLock)
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, &O0ULL)
        local1 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local1 < Cast(c2fb_c_int, 8ULL)))))
            If Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl local1)))) And CPtr(c2fb_sqlite3rbu Ptr, arg0->pRbu)->mLock)) Then
                local0(CPtr(c2fb_sqlite3_file Ptr, arg0->pReal), local1, Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Or Cast(c2fb_c_int, 8ULL))))
            End If
        c2fb_flow_1:
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, (c2fb_temp_3 + 1))
        Wend
        c2fb_flow_0:
        c2fb_temp_4 = CPtr(c2fb_u32 Ptr, @(CPtr(c2fb_sqlite3rbu Ptr, arg0->pRbu)->mLock))
        c2fb_temp_5 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_4) = Cast(c2fb_u32, c2fb_temp_5)
        c2fb_temp_5 = Cast(c2fb_c_uint, (*c2fb_temp_4))
    End If
End Sub
Private Function rbuUpdateTempSize CDecl (ByVal arg0 As c2fb_rbu_file Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4576
    Dim local0 As c2fb_sqlite3rbu Ptr
    Dim local1 As c2fb_int64
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_i64 Ptr
    Dim c2fb_temp_3 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int

    local0 = CPtr(c2fb_sqlite3rbu Ptr, arg0->pRbu)
    local1 = Cast(c2fb_int64, (arg1 - arg0->sz))
    c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(local0->szTemp))
    c2fb_temp_1 = Cast(c2fb_int64, ((*c2fb_temp_0) + local1))
    (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    c2fb_temp_2 = CPtr(c2fb_i64 Ptr, @(arg0->sz))
    c2fb_temp_3 = arg1
    (*c2fb_temp_2) = Cast(c2fb_i64, c2fb_temp_3)
    c2fb_temp_3 = Cast(c2fb_int64, (*c2fb_temp_2))
    c2fb_temp_4 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((local0->szTemp >= Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL))))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"pRbu->szTemp>=0"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4581ULL))
        c2fb_temp_4 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_5 = (c2fb_temp_4)
    If (-Cast(c2fb_c_int, (((local0->szTempLimit <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->szTemp > local0->szTempLimit)))) <> 0))))) Then
        Return Cast(c2fb_c_int, 13ULL)
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Sub rbuMainlistAdd CDecl (ByVal arg0 As c2fb_rbu_file Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4594
    Dim local0 As c2fb_rbu_vfs Ptr
    Dim local1 As c2fb_rbu_file Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_rbu_file Ptr
    Dim c2fb_temp_3 As c2fb_rbu_file Ptr
    Dim c2fb_temp_4 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_rbu_file Ptr
    Dim c2fb_temp_6 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_7 As c2fb_rbu_file Ptr
    Dim c2fb_temp_8 As c2fb_rbu_file Ptr
    Dim c2fb_temp_9 As c2fb_rbu_file Ptr
    Dim c2fb_temp_10 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_11 As c2fb_rbu_file Ptr
    Dim c2fb_temp_12 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_13 As c2fb_rbu_file Ptr

    local0 = CPtr(c2fb_rbu_vfs Ptr, arg0->pRbuVfs)
    ' C automatic storage declaration
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (arg0->openFlags And Cast(c2fb_c_int, &H00000100ULL))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"(p->openFlags & SQLITE_OPEN_MAIN_DB)"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4597ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    c2fb_external_sqlite3_mutex_enter(CPtr(c2fb_sqlite3_mutex Ptr, local0->mutex))
    If (-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3rbu Ptr, arg0->pRbu) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_2 = CPtr(c2fb_rbu_file Ptr, local0->pMain)
        local1 = c2fb_temp_2
        While local1
            ' empty C statement
        c2fb_flow_1:
            c2fb_temp_3 = CPtr(c2fb_rbu_file Ptr, local1->pMainNext)
            local1 = c2fb_temp_3
        Wend
        c2fb_flow_0:
        c2fb_temp_4 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(arg0->pMainNext))
        c2fb_temp_5 = CPtr(c2fb_rbu_file Ptr, local0->pMain)
        (*c2fb_temp_4) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_5)
        c2fb_temp_5 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_4))
        c2fb_temp_6 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(local0->pMain))
        c2fb_temp_7 = arg0
        (*c2fb_temp_6) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_7)
        c2fb_temp_7 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_6))
    Else
        c2fb_temp_8 = CPtr(c2fb_rbu_file Ptr, local0->pMainRbu)
        local1 = c2fb_temp_8
        While (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1 <> arg0)))) <> 0)))))
            ' empty C block
        c2fb_flow_3:
            c2fb_temp_9 = CPtr(c2fb_rbu_file Ptr, local1->pMainRbuNext)
            local1 = c2fb_temp_9
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_10 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(arg0->pMainRbuNext))
            c2fb_temp_11 = CPtr(c2fb_rbu_file Ptr, local0->pMainRbu)
            (*c2fb_temp_10) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_11)
            c2fb_temp_11 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_10))
            c2fb_temp_12 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(local0->pMainRbu))
            c2fb_temp_13 = arg0
            (*c2fb_temp_12) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_13)
            c2fb_temp_13 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_12))
        End If
    End If
    c2fb_external_sqlite3_mutex_leave(CPtr(c2fb_sqlite3_mutex Ptr, local0->mutex))
End Sub
Private Sub rbuMainlistRemove CDecl (ByVal arg0 As c2fb_rbu_file Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4616
    Dim local0 As c2fb_rbu_file Ptr Ptr
    Dim c2fb_temp_0 As c2fb_rbu_file Ptr Ptr
    Dim c2fb_temp_1 As c2fb_rbu_file Ptr Ptr
    Dim c2fb_temp_2 As c2fb_rbu_file Ptr Ptr
    Dim c2fb_temp_3 As c2fb_rbu_file Ptr
    Dim c2fb_temp_4 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_5 As c2fb_rbu_file Ptr
    Dim c2fb_temp_6 As c2fb_rbu_file Ptr Ptr
    Dim c2fb_temp_7 As c2fb_rbu_file Ptr Ptr
    Dim c2fb_temp_8 As c2fb_rbu_file Ptr Ptr
    Dim c2fb_temp_9 As c2fb_rbu_file Ptr
    Dim c2fb_temp_10 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_11 As c2fb_rbu_file Ptr

    ' C automatic storage declaration
    c2fb_external_sqlite3_mutex_enter(CPtr(c2fb_sqlite3_mutex Ptr, CPtr(c2fb_rbu_vfs Ptr, arg0->pRbuVfs)->mutex))
    c2fb_temp_0 = CPtr(c2fb_rbu_file Ptr Ptr, @(CPtr(c2fb_rbu_vfs Ptr, arg0->pRbuVfs)->pMain))
    local0 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((((*local0) <> 0) AndAlso ((-Cast(c2fb_c_int, (((*local0) <> arg0)))) <> 0)))))
        ' empty C block
    c2fb_flow_1:
        c2fb_temp_1 = CPtr(c2fb_rbu_file Ptr Ptr, @((((*local0))->pMainNext)))
        local0 = c2fb_temp_1
    Wend
    c2fb_flow_0:
    If (*local0) Then
        c2fb_temp_2 = CPtr(c2fb_rbu_file Ptr Ptr, @((*local0)))
        c2fb_temp_3 = CPtr(c2fb_rbu_file Ptr, arg0->pMainNext)
        (*c2fb_temp_2) = c2fb_temp_3
    End If
    c2fb_temp_4 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(arg0->pMainNext))
    c2fb_temp_5 = CPtr(_c2fb_record_c2fb_rbu_file Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_4) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_5)
    c2fb_temp_5 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_4))
    c2fb_temp_6 = CPtr(c2fb_rbu_file Ptr Ptr, @(CPtr(c2fb_rbu_vfs Ptr, arg0->pRbuVfs)->pMainRbu))
    local0 = c2fb_temp_6
    While (-Cast(c2fb_c_int, ((((*local0) <> 0) AndAlso ((-Cast(c2fb_c_int, (((*local0) <> arg0)))) <> 0)))))
        ' empty C block
    c2fb_flow_3:
        c2fb_temp_7 = CPtr(c2fb_rbu_file Ptr Ptr, @((((*local0))->pMainRbuNext)))
        local0 = c2fb_temp_7
    Wend
    c2fb_flow_2:
    If (*local0) Then
        c2fb_temp_8 = CPtr(c2fb_rbu_file Ptr Ptr, @((*local0)))
        c2fb_temp_9 = CPtr(c2fb_rbu_file Ptr, arg0->pMainRbuNext)
        (*c2fb_temp_8) = c2fb_temp_9
    End If
    c2fb_temp_10 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(arg0->pMainRbuNext))
    c2fb_temp_11 = CPtr(_c2fb_record_c2fb_rbu_file Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_10) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_11)
    c2fb_temp_11 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_10))
    c2fb_external_sqlite3_mutex_leave(CPtr(c2fb_sqlite3_mutex Ptr, CPtr(c2fb_rbu_vfs Ptr, arg0->pRbuVfs)->mutex))
End Sub
Private Function rbuFindMaindb CDecl (ByVal arg0 As c2fb_rbu_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_rbu_file Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4637
    Dim local0 As c2fb_rbu_file Ptr
    Dim c2fb_temp_0 As c2fb_rbu_file Ptr
    Dim c2fb_temp_1 As c2fb_rbu_file Ptr
    Dim c2fb_temp_2 As c2fb_rbu_file Ptr
    Dim c2fb_temp_3 As c2fb_rbu_file Ptr

    ' C automatic storage declaration
    c2fb_external_sqlite3_mutex_enter(CPtr(c2fb_sqlite3_mutex Ptr, arg0->mutex))
    If arg2 Then
        c2fb_temp_0 = CPtr(c2fb_rbu_file Ptr, arg0->pMainRbu)
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->zWal <> arg1)))) <> 0)))))
            ' empty C block
        c2fb_flow_1:
            c2fb_temp_1 = CPtr(c2fb_rbu_file Ptr, local0->pMainRbuNext)
            local0 = c2fb_temp_1
        Wend
        c2fb_flow_0:
    Else
        c2fb_temp_2 = CPtr(c2fb_rbu_file Ptr, arg0->pMain)
        local0 = c2fb_temp_2
        While (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->zWal <> arg1)))) <> 0)))))
            ' empty C block
        c2fb_flow_3:
            c2fb_temp_3 = CPtr(c2fb_rbu_file Ptr, local0->pMainNext)
            local0 = c2fb_temp_3
        Wend
        c2fb_flow_2:
    End If
    c2fb_external_sqlite3_mutex_leave(CPtr(c2fb_sqlite3_mutex Ptr, arg0->mutex))
    Return local0
End Function
Private Function rbuVfsClose CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4652
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As ZString Ptr Ptr Ptr
    Dim c2fb_temp_3 As ZString Ptr Ptr
    Dim local3 As Const c2fb_sqlite3_io_methods Ptr
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    ' C automatic storage declaration
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, &O0ULL)
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local2 < local0->nShm))))
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0->apShm[local2]))
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, (c2fb_temp_1 + 1))
    Wend
    c2fb_flow_0:
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0->apShm))
    c2fb_temp_2 = CPtr(ZString Ptr Ptr Ptr, @(local0->apShm))
    c2fb_temp_3 = CPtr(ZString Ptr Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_external_sqlite3_free(CPtr(Any Ptr, local0->zDel))
    If Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000100ULL))) Then
        local3 = CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)
        rbuMainlistRemove(local0)
        rbuUnlockShm(local0)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3->iVersion > Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso (CPtr(c2fb_callback_10, local3->xShmUnmap) <> 0))))) Then
            CPtr(c2fb_callback_10, local3->xShmUnmap)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), Cast(c2fb_c_int, &O0ULL))
        End If
    Else
        If (-Cast(c2fb_c_int, ((((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000008ULL)))) <> 0) AndAlso (CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu) <> 0))))) Then
            rbuUpdateTempSize(local0, Cast(c2fb_c_int, &O0ULL))
        End If
    End If
    c2fb_temp_4 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((CPtr(c2fb_rbu_file Ptr, local0->pMainNext) = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_rbu_file Ptr, CPtr(c2fb_rbu_vfs Ptr, local0->pRbuVfs)->pMain) <> local0)))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->pMainNext==0 && p->pRbuVfs->pMain!=p"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4676ULL))
        c2fb_temp_4 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_5 = (c2fb_temp_4)
    c2fb_temp_6 = CPtr(c2fb_callback_6, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xClose)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal))
    local1 = c2fb_temp_6
    Return local1
End Function
Private Function rbuGetU32 CDecl (ByVal arg0 As UByte Ptr) As c2fb_c_uint
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4688
    Return Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, &O0ULL)]) Shl Cast(c2fb_c_int, 24ULL)))) + (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, 1ULL)]) Shl Cast(c2fb_c_int, 16ULL)))))) + (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, 2ULL)]) Shl Cast(c2fb_c_int, 8ULL)))))) + (Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, 3ULL)]))))
End Function
Private Sub rbuPutU32 CDecl (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_uint)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4699
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte

    c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (arg1 Shr Cast(c2fb_c_int, 24ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (arg1 Shr Cast(c2fb_c_int, 16ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 2ULL)]))
    c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (arg1 Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 3ULL)]))
    c2fb_temp_7 = Cast(UByte, Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (arg1 Shr Cast(c2fb_c_int, &O0ULL)))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &HFFULL)))))
    (*c2fb_temp_6) = c2fb_temp_7
End Sub
Private Sub rbuPutU16 CDecl (ByVal arg0 As UByte Ptr, ByVal arg1 As UShort)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4706
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte

    c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, arg1) Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_c_int, &HFFULL))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, arg1) Shr Cast(c2fb_c_int, &O0ULL)))) And Cast(c2fb_c_int, &HFFULL))))
    (*c2fb_temp_2) = c2fb_temp_3
End Sub
Private Function rbuVfsRead CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4714
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_sqlite3rbu Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Any Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim local3 As c2fb_sqlite3_file Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local4 As UByte Ptr
    Dim local5 As c2fb_c_uint
    Dim c2fb_temp_7 As Any Ptr
    Dim c2fb_temp_8 As UByte Ptr
    Dim c2fb_temp_9 As UByte
    Dim local6 As UByte Ptr
    Dim c2fb_temp_10 As c2fb_u32 Ptr
    Dim c2fb_temp_11 As c2fb_c_uint
    Dim c2fb_temp_12 As c2fb_u8 Ptr
    Dim c2fb_temp_13 As UByte

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    local1 = CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu)
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eStage = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00080000ULL)))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"p->openFlags & SQLITE_OPEN_WAL"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4725ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        c2fb_temp_2 = rbuCaptureWalRead(CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu), arg3, arg2)
        local2 = c2fb_temp_2
    Else
        If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00080000ULL)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3 >= local1->iOalSz)))) <> 0))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, &O0ULL)
            local2 = c2fb_temp_3
            c2fb_temp_4 = CPtr(Any Ptr, c2fb_crt_memset(arg1, Cast(c2fb_c_int, &O0ULL), arg2))
        Else
            c2fb_temp_5 = CPtr(c2fb_callback_7, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xRead)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1, arg2, arg3)
            local2 = c2fb_temp_5
            If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso (((-Cast(c2fb_c_int, (((local1)->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = (Cast(c2fb_c_int, (Cast(c2fb_c_int, 10ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 2ULL) Shl Cast(c2fb_c_int, 8ULL))))))))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000100ULL)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->rc = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                local3 = CPtr(c2fb_sqlite3_file Ptr, CPtr(c2fb_rbu_file Ptr, local1->pRbuFd))
                c2fb_temp_6 = CPtr(c2fb_callback_7, CPtr(Const c2fb_sqlite3_io_methods Ptr, local3->pMethods)->xRead)(local3, arg1, arg2, arg3)
                local2 = c2fb_temp_6
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                    local4 = CPtr(UByte Ptr, arg1)
                    local5 = IIf(rbuGetU32(CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 52ULL)]))), Cast(c2fb_c_int, 1ULL), Cast(c2fb_c_int, &O0ULL))
                    rbuPutU32(CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 52ULL)])), local5)
                    rbuPutU32(CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 36ULL)])), Cast(c2fb_c_int, &O0ULL))
                    rbuPutU32(CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 32ULL)])), Cast(c2fb_c_int, &O0ULL))
                    rbuPutU32(CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 28ULL)])), Cast(c2fb_c_int, 1ULL))
                    rbuPutU32(CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 24ULL)])), Cast(c2fb_c_uint, (CPtr(c2fb_rbu_file Ptr, local1->pRbuFd)->iCookie + Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))))
                    If (-Cast(c2fb_c_int, ((arg2 > Cast(c2fb_c_int, 100ULL))))) Then
                        c2fb_temp_7 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 100ULL)]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (arg2 - Cast(c2fb_c_int, 100ULL)))))
                        rbuPutU16(CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 105ULL)])), Cast(c2fb_c_int, (arg2 And Cast(c2fb_c_int, &HFFFFULL))))
                        c2fb_temp_8 = CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 100ULL)]))
                        c2fb_temp_9 = Cast(UByte, Cast(c2fb_c_int, &H0DULL))
                        (*c2fb_temp_8) = c2fb_temp_9
                    End If
                End If
            End If
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000100ULL)))) <> 0))))) Then
            local6 = CPtr(UByte Ptr, arg1)
            c2fb_temp_10 = CPtr(c2fb_u32 Ptr, @(local0->iCookie))
            c2fb_temp_11 = rbuGetU32(CPtr(UByte Ptr, @(local6[Cast(c2fb_c_int, 24ULL)])))
            (*c2fb_temp_10) = Cast(c2fb_u32, c2fb_temp_11)
            c2fb_temp_11 = Cast(c2fb_c_uint, (*c2fb_temp_10))
            c2fb_temp_12 = CPtr(c2fb_u8 Ptr, @(local0->iWriteVer))
            c2fb_temp_13 = local6[Cast(c2fb_c_int, 19ULL)]
            (*c2fb_temp_12) = Cast(c2fb_u8, c2fb_temp_13)
            c2fb_temp_13 = Cast(UByte, (*c2fb_temp_12))
        End If
    End If
    Return local2
End Function
Private Function rbuVfsWrite CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4780
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_sqlite3rbu Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_i64 Ptr
    Dim c2fb_temp_4 As c2fb_int64
    Dim local3 As c2fb_int64
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local4 As UByte Ptr
    Dim c2fb_temp_7 As c2fb_u32 Ptr
    Dim c2fb_temp_8 As c2fb_c_uint
    Dim c2fb_temp_9 As c2fb_u8 Ptr
    Dim c2fb_temp_10 As UByte

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    local1 = CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu)
    ' C automatic storage declaration
    If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eStage = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        c2fb_temp_0 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000100ULL)))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"p->openFlags & SQLITE_OPEN_MAIN_DB"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4791ULL))
            c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_1 = (c2fb_temp_0)
        c2fb_temp_2 = rbuCaptureDbWrite(CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu), arg3)
        local2 = c2fb_temp_2
    Else
        If local1 Then
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00080000ULL)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3 >= local1->iOalSz)))) <> 0))))) Then
                c2fb_temp_3 = CPtr(c2fb_i64 Ptr, @(local1->iOalSz))
                c2fb_temp_4 = Cast(c2fb_int64, (Cast(c2fb_int64, arg2) + arg3))
                (*c2fb_temp_3) = Cast(c2fb_i64, c2fb_temp_4)
                c2fb_temp_4 = Cast(c2fb_int64, (*c2fb_temp_3))
            Else
                If Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000008ULL))) Then
                    local3 = Cast(c2fb_int64, (Cast(c2fb_int64, arg2) + arg3))
                    If (-Cast(c2fb_c_int, ((local3 > local0->sz)))) Then
                        c2fb_temp_5 = rbuUpdateTempSize(local0, local3)
                        local2 = c2fb_temp_5
                        If (-Cast(c2fb_c_int, ((local2 <> Cast(c2fb_c_int, &O0ULL))))) Then
                            Return local2
                        End If
                    End If
                End If
            End If
        End If
        c2fb_temp_6 = CPtr(c2fb_callback_8, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xWrite)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1, arg2, arg3)
        local2 = c2fb_temp_6
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg3 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000100ULL)))) <> 0))))) Then
            local4 = CPtr(UByte Ptr, arg1)
            c2fb_temp_7 = CPtr(c2fb_u32 Ptr, @(local0->iCookie))
            c2fb_temp_8 = rbuGetU32(CPtr(UByte Ptr, @(local4[Cast(c2fb_c_int, 24ULL)])))
            (*c2fb_temp_7) = Cast(c2fb_u32, c2fb_temp_8)
            c2fb_temp_8 = Cast(c2fb_c_uint, (*c2fb_temp_7))
            c2fb_temp_9 = CPtr(c2fb_u8 Ptr, @(local0->iWriteVer))
            c2fb_temp_10 = local4[Cast(c2fb_c_int, 19ULL)]
            (*c2fb_temp_9) = Cast(c2fb_u8, c2fb_temp_10)
            c2fb_temp_10 = Cast(UByte, (*c2fb_temp_9))
        End If
    End If
    Return local2
End Function
Private Function rbuVfsTruncate CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_int64) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4823
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_c_int

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    If (-Cast(c2fb_c_int, ((((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000008ULL)))) <> 0) AndAlso (CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu) <> 0))))) Then
        local1 = rbuUpdateTempSize(local0, arg1)
        If (-Cast(c2fb_c_int, ((local1 <> Cast(c2fb_c_int, &O0ULL))))) Then
            Return local1
        End If
    End If
    Return CPtr(c2fb_callback_9, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xTruncate)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1)
End Function
Private Function rbuVfsSync CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4835
    Dim local0 As c2fb_rbu_file Ptr

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    If (-Cast(c2fb_c_int, (((CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu)->eStage = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        If Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000100ULL))) Then
            Return (Cast(c2fb_c_int, (Cast(c2fb_c_int, 27ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 3ULL) Shl Cast(c2fb_c_int, 8ULL)))))))
        End If
        Return Cast(c2fb_c_int, &O0ULL)
    End If
    Return CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xSync)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1)
End Function
Private Function rbuVfsFileSize CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4849
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_int64 Ptr
    Dim c2fb_temp_2 As c2fb_int64

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_callback_11, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xFileSize)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1)
    local1 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, (((*arg1) = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso (CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu) <> 0) AndAlso (((-Cast(c2fb_c_int, (((CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu))->zTarget = Cast(c2fb_c_int, &O0ULL)))))) <> 0) AndAlso ((Cast(c2fb_c_int, (local0->openFlags And Cast(c2fb_c_int, &H00000100ULL)))) <> 0))))) Then
        c2fb_temp_1 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_2 = Cast(c2fb_int64, Cast(c2fb_c_int, 1024ULL))
        (*c2fb_temp_1) = c2fb_temp_2
    End If
    Return local1
End Function
Private Function rbuVfsLock CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4870
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_sqlite3rbu Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    local1 = CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0->openFlags And (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000100ULL) Or Cast(c2fb_c_int, &H00000200ULL))))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->openFlags & (SQLITE_OPEN_MAIN_DB|SQLITE_OPEN_TEMP_DB)"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4875ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso (((-Cast(c2fb_c_int, (((local0->bNolock <> 0) OrElse (((-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eStage <> Cast(c2fb_c_int, 5ULL))))) <> 0)))))) <> 0)))))) <> 0))))) Then
        c2fb_temp_2 = Cast(c2fb_c_int, 5ULL)
        local2 = c2fb_temp_2
    Else
        c2fb_temp_3 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xLock)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1)
        local2 = c2fb_temp_3
    End If
    Return local2
End Function
Private Function rbuVfsUnlock CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4892
    Dim local0 As c2fb_rbu_file Ptr

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    Return CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xUnlock)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1)
End Function
Private Function rbuVfsCheckReservedLock CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4900
    Dim local0 As c2fb_rbu_file Ptr

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    Return CPtr(c2fb_callback_12, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xCheckReservedLock)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1)
End Function
Private Function rbuVfsFileControl CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Any Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4908
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_callback_13
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local3 As c2fb_sqlite3rbu Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local4 As Any Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As ZString Ptr Ptr
    Dim c2fb_temp_6 As ZString Ptr
    Dim c2fb_temp_7 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_8 As c2fb_rbu_file Ptr
    Dim c2fb_temp_9 As c2fb_sqlite3rbu_ Ptr Ptr
    Dim c2fb_temp_10 As c2fb_sqlite3rbu Ptr
    Dim c2fb_temp_11 As c2fb_sqlite3rbu_ Ptr Ptr
    Dim c2fb_temp_12 As c2fb_sqlite3rbu Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local5 As c2fb_sqlite3rbu Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_17 As c2fb_rbu_file Ptr
    Dim c2fb_temp_18 As c2fb_u8 Ptr
    Dim c2fb_temp_19 As UByte
    Dim c2fb_temp_20 As c2fb_c_int
    Dim local6 As c2fb_rbu_vfs Ptr
    Dim local7 As ZString Ptr
    Dim local8 As ZString Ptr
    Dim c2fb_temp_21 As ZString Ptr Ptr
    Dim c2fb_temp_22 As ZString Ptr
    Dim c2fb_temp_23 As c2fb_c_int

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    local1 = CPtr(c2fb_callback_13, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xFileControl)
    ' C automatic storage declaration
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, (((-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local0->openFlags And (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000100ULL) Or Cast(c2fb_c_int, &H00000200ULL)))))) <> 0) OrElse (Cast(c2fb_c_int, (local0->openFlags And (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000400ULL) Or Cast(c2fb_c_int, &H00001000ULL)))))) <> 0)))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->openFlags & (SQLITE_OPEN_MAIN_DB|SQLITE_OPEN_TEMP_DB) || p->openFlags & (SQLITE_OPEN_TRANSIENT_DB|SQLITE_OPEN_TEMP_JOURNAL)"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4913ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 26ULL))))) Then
        local3 = CPtr(c2fb_sqlite3rbu Ptr, arg2)
        c2fb_temp_2 = local1(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1, arg2)
        local2 = c2fb_temp_2
        If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 12ULL))))) Then
            local4 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_3 = local1(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), Cast(c2fb_c_int, 25ULL), CPtr(Any Ptr, CPtr(Any Ptr Ptr, @(local4))))
            local2 = c2fb_temp_3
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
                c2fb_temp_4 = Cast(c2fb_c_int, 1ULL)
                local2 = c2fb_temp_4
                c2fb_temp_5 = CPtr(ZString Ptr Ptr, @(local3->zErrmsg))
                c2fb_temp_6 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"rbu/zipvfs setup error")))
                (*c2fb_temp_5) = c2fb_temp_6
            Else
                If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 12ULL))))) Then
                    c2fb_temp_7 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(local3->pTargetFd))
                    c2fb_temp_8 = local0
                    (*c2fb_temp_7) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_8)
                    c2fb_temp_8 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_7))
                    c2fb_temp_9 = CPtr(c2fb_sqlite3rbu_ Ptr Ptr, @(local0->pRbu))
                    c2fb_temp_10 = local3
                    (*c2fb_temp_9) = CPtr(c2fb_sqlite3rbu_ Ptr, c2fb_temp_10)
                    c2fb_temp_10 = CPtr(c2fb_sqlite3rbu Ptr, (*c2fb_temp_9))
                    rbuMainlistAdd(local0)
                    If CPtr(c2fb_rbu_file Ptr, local0->pWalFd) Then
                        c2fb_temp_11 = CPtr(c2fb_sqlite3rbu_ Ptr Ptr, @(CPtr(c2fb_rbu_file Ptr, local0->pWalFd)->pRbu))
                        c2fb_temp_12 = local3
                        (*c2fb_temp_11) = CPtr(c2fb_sqlite3rbu_ Ptr, c2fb_temp_12)
                        c2fb_temp_12 = CPtr(c2fb_sqlite3rbu Ptr, (*c2fb_temp_11))
                    End If
                    c2fb_temp_13 = Cast(c2fb_c_int, &O0ULL)
                    local2 = c2fb_temp_13
                End If
            End If
        End If
        Return local2
    Else
        If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 5149216ULL))))) Then
            local5 = CPtr(c2fb_sqlite3rbu Ptr, arg2)
            c2fb_temp_14 = CPtr(Long Ptr, @(local5->nRbu))
            c2fb_temp_15 = (*c2fb_temp_14)
            (*c2fb_temp_14) = Cast(c2fb_c_int, (c2fb_temp_15 + 1))
            c2fb_temp_16 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(local5->pRbuFd))
            c2fb_temp_17 = local0
            (*c2fb_temp_16) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_17)
            c2fb_temp_17 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_16))
            c2fb_temp_18 = CPtr(c2fb_u8 Ptr, @(local0->bNolock))
            c2fb_temp_19 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_18) = Cast(c2fb_u8, c2fb_temp_19)
            c2fb_temp_19 = Cast(UByte, (*c2fb_temp_18))
        End If
    End If
    c2fb_temp_20 = local1(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1, arg2)
    local2 = c2fb_temp_20
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 12ULL))))) <> 0))))) Then
        local6 = CPtr(c2fb_rbu_vfs Ptr, local0->pRbuVfs)
        local7 = (*CPtr(ZString Ptr Ptr, arg2))
        local8 = CPtr(ZString Ptr, c2fb_external_sqlite3_mprintf(StrPtr(!"rbu(%s)/%z"), local6->base.zName, local7))
        c2fb_temp_21 = CPtr(ZString Ptr Ptr, @((*CPtr(ZString Ptr Ptr, arg2))))
        c2fb_temp_22 = local8
        (*c2fb_temp_21) = c2fb_temp_22
        If (-Cast(c2fb_c_int, ((local8 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_23 = Cast(c2fb_c_int, 7ULL)
            local2 = c2fb_temp_23
        End If
    End If
    Return local2
End Function
Private Function rbuVfsSectorSize CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4964
    Dim local0 As c2fb_rbu_file Ptr

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    Return CPtr(c2fb_callback_6, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xSectorSize)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal))
End Function
Private Function rbuVfsDeviceCharacteristics CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4972
    Dim local0 As c2fb_rbu_file Ptr

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    Return CPtr(c2fb_callback_6, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xDeviceCharacteristics)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal))
End Function
Private Function rbuVfsShmLock CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 4980
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_sqlite3rbu Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_u32 Ptr
    Dim c2fb_temp_6 As c2fb_c_uint

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    local1 = CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu)
    local2 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0->openFlags And (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000100ULL) Or Cast(c2fb_c_int, &H00000200ULL))))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->openFlags & (SQLITE_OPEN_MAIN_DB|SQLITE_OPEN_TEMP_DB)"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 4989ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local1->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1->eStage = Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local1->eStage = Cast(c2fb_c_int, 5ULL))))) <> 0)))))) <> 0))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
            c2fb_temp_2 = Cast(c2fb_c_int, 5ULL)
            local2 = c2fb_temp_2
        End If
    Else
        local3 = Cast(c2fb_c_int, &O0ULL)
        If (-Cast(c2fb_c_int, (((local1 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local1->eStage = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
            c2fb_temp_3 = Cast(c2fb_c_int, 1ULL)
            local3 = c2fb_temp_3
        End If
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = (Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, 1ULL)))))))) <> 0))))) Then
            c2fb_temp_4 = CPtr(c2fb_callback_15, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xShmLock)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1, arg2, arg3)
            local2 = c2fb_temp_4
            If (-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_5 = CPtr(c2fb_u32 Ptr, @(local1->mLock))
                c2fb_temp_6 = Cast(c2fb_c_uint, ((*c2fb_temp_5) Or Cast(c2fb_c_uint, Cast(c2fb_c_int, ((Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl arg2))) - Cast(c2fb_c_int, 1ULL)))) Shl arg1)))))
                (*c2fb_temp_5) = Cast(c2fb_u32, c2fb_temp_6)
                c2fb_temp_6 = Cast(c2fb_c_uint, (*c2fb_temp_5))
            End If
        End If
    End If
    Return local2
End Function
' c2fb skipped rbuVfsShmMap: outside the supported subset
' c2fb body diagnostic [volatile-semantics-not-preserved] line 5018: rbuVfsShmMap: volatile access semantics are not preserved by FreeBASIC
Private Sub rbuVfsShmBarrier CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5076
    Dim local0 As c2fb_rbu_file Ptr

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    CPtr(c2fb_callback_16, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xShmBarrier)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal))
End Sub
Private Function rbuVfsShmUnmap CDecl (ByVal arg0 As c2fb_sqlite3_file Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5084
    Dim local0 As c2fb_rbu_file Ptr
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = CPtr(c2fb_rbu_file Ptr, arg0)
    local1 = Cast(c2fb_c_int, &O0ULL)
    local2 = (IIf(CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu), CPtr(c2fb_sqlite3rbu Ptr, local0->pRbu)->eStage, Cast(c2fb_c_int, &O0ULL)))
    c2fb_temp_0 = 1
    If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local0->openFlags And (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000100ULL) Or Cast(c2fb_c_int, &H00000200ULL))))))) = 0))) = 0)))) <> 0) = 0) Then
        c2fbRbuAssert(StrPtr(!"p->openFlags & (SQLITE_OPEN_MAIN_DB|SQLITE_OPEN_TEMP_DB)"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 5089ULL))
        c2fb_temp_0 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
    End If
    c2fb_temp_1 = (c2fb_temp_0)
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 2ULL))))) <> 0))))) Then
        ' empty C block
    Else
        rbuUnlockShm(local0)
        c2fb_temp_2 = CPtr(c2fb_callback_10, CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local0->pReal)->pMethods)->xShmUnmap)(CPtr(c2fb_sqlite3_file Ptr, local0->pReal), arg1)
        local1 = c2fb_temp_2
    End If
    Return local1
End Function
Private Function rbuVfsOpen CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_sqlite3_file Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5103
    Dim local2 As c2fb_rbu_vfs Ptr
    Dim local3 As c2fb_sqlite3_vfs Ptr
    Dim local4 As c2fb_rbu_file Ptr
    Dim local5 As c2fb_c_int
    Dim local6 As Const ZString Ptr
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_sqlite3_file_ Ptr Ptr
    Dim c2fb_temp_2 As c2fb_sqlite3_file Ptr
    Dim c2fb_temp_3 As c2fb_rbu_vfs_ Ptr Ptr
    Dim c2fb_temp_4 As c2fb_rbu_vfs Ptr
    Dim c2fb_temp_5 As Long Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As Const ZString Ptr Ptr
    Dim c2fb_temp_8 As Const ZString Ptr
    Dim local8 As c2fb_rbu_file Ptr
    Dim local9 As c2fb_size_t
    Dim c2fb_temp_9 As Const ZString Ptr
    Dim c2fb_temp_10 As Const ZString Ptr
    Dim c2fb_temp_11 As c2fb_size_t
    Dim c2fb_temp_12 As Byte Ptr
    Dim c2fb_temp_13 As Byte
    Dim c2fb_temp_14 As c2fb_sqlite3rbu_ Ptr Ptr
    Dim c2fb_temp_15 As c2fb_sqlite3rbu Ptr
    Dim c2fb_temp_16 As c2fb_rbu_file_ Ptr Ptr
    Dim c2fb_temp_17 As c2fb_rbu_file Ptr
    Dim c2fb_temp_18 As c2fb_sqlite3rbu_ Ptr Ptr
    Dim c2fb_temp_19 As c2fb_sqlite3rbu Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As Const ZString Ptr
    Dim c2fb_temp_24 As c2fb_c_int
    Dim rbuVfsIoMethodsV10 As Const c2fb_sqlite3_io_methods Ptr
    Dim c2fb_temp_25 As Const c2fb_sqlite3_io_methods Ptr Ptr
    Dim c2fb_temp_26 As Const c2fb_sqlite3_io_methods Ptr
    Dim c2fb_temp_27 As Const c2fb_sqlite3_io_methods Ptr Ptr
    Dim c2fb_temp_28 As Const c2fb_sqlite3_io_methods Ptr

    ' C static scalar storage
    ' C static scalar storage
    local2 = CPtr(c2fb_rbu_vfs Ptr, arg0)
    local3 = CPtr(c2fb_sqlite3_vfs Ptr, local2->pRealVfs)
    local4 = CPtr(c2fb_rbu_file Ptr, arg2)
    local5 = Cast(c2fb_c_int, &O0ULL)
    local6 = arg1
    local7 = arg3
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local4), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_rbu_file))))
    c2fb_temp_1 = CPtr(c2fb_sqlite3_file_ Ptr Ptr, @(local4->pReal))
    c2fb_temp_2 = CPtr(c2fb_sqlite3_file Ptr, CPtr(c2fb_rbu_file Ptr, @(CPtr(c2fb_rbu_file Ptr, local4)[Cast(c2fb_c_int, 1ULL)])))
    (*c2fb_temp_1) = CPtr(c2fb_sqlite3_file_ Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(c2fb_sqlite3_file Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(c2fb_rbu_vfs_ Ptr Ptr, @(local4->pRbuVfs))
    c2fb_temp_4 = local2
    (*c2fb_temp_3) = CPtr(c2fb_rbu_vfs_ Ptr, c2fb_temp_4)
    c2fb_temp_4 = CPtr(c2fb_rbu_vfs Ptr, (*c2fb_temp_3))
    c2fb_temp_5 = CPtr(Long Ptr, @(local4->openFlags))
    c2fb_temp_6 = arg3
    (*c2fb_temp_5) = Cast(Long, c2fb_temp_6)
    c2fb_temp_6 = Cast(c2fb_c_int, (*c2fb_temp_5))
    If arg1 Then
        If Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H00000100ULL))) Then
            c2fb_temp_7 = CPtr(Const ZString Ptr Ptr, @(local4->zWal))
            c2fb_temp_8 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_filename_wal(arg1))
            (*c2fb_temp_7) = c2fb_temp_8
        Else
            If Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H00080000ULL))) Then
                local8 = CPtr(c2fb_rbu_file Ptr, rbuFindMaindb(local2, arg1, Cast(c2fb_c_int, &O0ULL)))
                If local8 Then
                    If (-Cast(c2fb_c_int, (((CPtr(c2fb_sqlite3rbu Ptr, local8->pRbu) <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3rbu Ptr, local8->pRbu)->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
                        ' C automatic storage declaration
                        If ((-Cast(c2fb_c_int, (((CPtr(c2fb_sqlite3rbu Ptr, local8->pRbu))->zTarget = Cast(c2fb_c_int, &O0ULL)))))) Then
                            c2fb_temp_9 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_db_filename(CPtr(c2fb_sqlite3 Ptr, CPtr(c2fb_sqlite3rbu Ptr, local8->pRbu)->dbRbu), StrPtr(!"main")))
                            local6 = c2fb_temp_9
                            c2fb_temp_10 = CPtr(Const ZString Ptr, c2fb_external_sqlite3_filename_wal(local6))
                            local6 = c2fb_temp_10
                        End If
                        c2fb_temp_11 = c2fb_crt_strlen(local6)
                        local9 = c2fb_temp_11
                        c2fb_temp_12 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, (CPtr(ZString Ptr, local6)))[Cast(c2fb_c_uint, (Cast(c2fb_c_uint, local9) - Cast(c2fb_c_uint, Cast(c2fb_c_int, 3ULL))))]))
                        c2fb_temp_13 = Cast(Byte, Cast(c2fb_c_int, 111))
                        (*c2fb_temp_12) = c2fb_temp_13
                        c2fb_temp_14 = CPtr(c2fb_sqlite3rbu_ Ptr Ptr, @(local4->pRbu))
                        c2fb_temp_15 = CPtr(c2fb_sqlite3rbu Ptr, local8->pRbu)
                        (*c2fb_temp_14) = CPtr(c2fb_sqlite3rbu_ Ptr, c2fb_temp_15)
                        c2fb_temp_15 = CPtr(c2fb_sqlite3rbu Ptr, (*c2fb_temp_14))
                    End If
                    c2fb_temp_16 = CPtr(c2fb_rbu_file_ Ptr Ptr, @(local8->pWalFd))
                    c2fb_temp_17 = local4
                    (*c2fb_temp_16) = CPtr(c2fb_rbu_file_ Ptr, c2fb_temp_17)
                    c2fb_temp_17 = CPtr(c2fb_rbu_file Ptr, (*c2fb_temp_16))
                End If
            End If
        End If
    Else
        c2fb_temp_18 = CPtr(c2fb_sqlite3rbu_ Ptr Ptr, @(local4->pRbu))
        c2fb_temp_19 = CPtr(c2fb_sqlite3rbu Ptr, local2->pRbu)
        (*c2fb_temp_18) = CPtr(c2fb_sqlite3rbu_ Ptr, c2fb_temp_19)
        c2fb_temp_19 = CPtr(c2fb_sqlite3rbu Ptr, (*c2fb_temp_18))
    End If
    If (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, (local7 And Cast(c2fb_c_int, &H00000100ULL))) <> 0) AndAlso (c2fb_external_sqlite3_uri_boolean(arg1, StrPtr(!"rbu_memory"), Cast(c2fb_c_int, &O0ULL)) <> 0))))) Then
        c2fb_temp_20 = 1
        If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, (local7 And Cast(c2fb_c_int, &H00000100ULL)))) = 0))) = 0)))) <> 0) = 0) Then
            c2fbRbuAssert(StrPtr(!"oflags & SQLITE_OPEN_MAIN_DB"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 5193ULL))
            c2fb_temp_20 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
        End If
        c2fb_temp_21 = (c2fb_temp_20)
        c2fb_temp_22 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000200ULL) Or Cast(c2fb_c_int, &H00000002ULL))) Or Cast(c2fb_c_int, &H00000004ULL))) Or Cast(c2fb_c_int, &H00000010ULL))) Or Cast(c2fb_c_int, &H00000008ULL)))
        local7 = c2fb_temp_22
        c2fb_temp_23 = CPtr(Const ZString Ptr, Cast(ULongInt, Cast(c2fb_c_int, &O0ULL)))
        local6 = c2fb_temp_23
    End If
    If (-Cast(c2fb_c_int, ((local5 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_24 = CPtr(c2fb_callback_19, local3->xOpen)(local3, local6, CPtr(c2fb_sqlite3_file Ptr, local4->pReal), local7, arg4)
        local5 = c2fb_temp_24
    End If
    If CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local4->pReal)->pMethods) Then
        rbuVfsIoMethodsV10 = CPtr(Const c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_file Ptr, local4->pReal)->pMethods)
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((rbuVfsIoMethodsV10->iVersion < Cast(c2fb_c_int, 2ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((CPtr(Any Ptr, CPtr(c2fb_callback_15, rbuVfsIoMethodsV10->xShmLock)) = CPtr(Any Ptr, Cast(c2fb_c_int, &O0ULL)))))) <> 0))))) Then
            c2fb_temp_25 = CPtr(Const c2fb_sqlite3_io_methods Ptr Ptr, @(arg2->pMethods))
            c2fb_temp_26 = CPtr(Const _c2fb_record_c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_io_methods Ptr, @(rbuVfsIoMethodsV1)))
            (*c2fb_temp_25) = c2fb_temp_26
        Else
            c2fb_temp_27 = CPtr(Const c2fb_sqlite3_io_methods Ptr Ptr, @(arg2->pMethods))
            c2fb_temp_28 = CPtr(Const _c2fb_record_c2fb_sqlite3_io_methods Ptr, CPtr(c2fb_sqlite3_io_methods Ptr, @(rbuVfsIoMethodsV2)))
            (*c2fb_temp_27) = c2fb_temp_28
        End If
        If Cast(c2fb_c_int, (arg3 And Cast(c2fb_c_int, &H00000100ULL))) Then
            rbuMainlistAdd(local4)
        End If
    Else
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local4->zDel))
    End If
    Return local5
End Function
Private Function rbuVfsDelete CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5225
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    Return CPtr(c2fb_callback_20, local0->xDelete)(local0, arg1, arg2)
End Function
Private Function rbuVfsAccess CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5234
    Dim local0 As c2fb_rbu_vfs Ptr
    Dim local1 As c2fb_sqlite3_vfs Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim local3 As c2fb_rbu_file Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = CPtr(c2fb_rbu_vfs Ptr, arg0)
    local1 = CPtr(c2fb_sqlite3_vfs Ptr, local0->pRealVfs)
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_callback_21, local1->xAccess)(local1, arg1, arg2, arg3)
    local2 = c2fb_temp_0
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        local3 = CPtr(c2fb_rbu_file Ptr, rbuFindMaindb(local0, arg1, Cast(c2fb_c_int, 1ULL)))
        If (-Cast(c2fb_c_int, (((local3 <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3rbu Ptr, local3->pRbu)->eStage = Cast(c2fb_c_int, 1ULL))))) <> 0))))) Then
            c2fb_temp_1 = 1
            If ((((-Cast(c2fb_c_int, ((-Cast(c2fb_c_int, ((CPtr(c2fb_sqlite3rbu Ptr, local3->pRbu)) = 0))) = 0)))) <> 0) = 0) Then
                c2fbRbuAssert(StrPtr(!"pDb->pRbu"), StrPtr(!"/home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c"), Cast(c2fb_c_int, 5263ULL))
                c2fb_temp_1 = (-Cast(c2fb_c_int, (((Cast(c2fb_c_int, &O0ULL)) <> 0))))
            End If
            c2fb_temp_2 = (c2fb_temp_1)
            If (*arg3) Then
                c2fb_temp_3 = Cast(c2fb_c_int, 14ULL)
                local2 = c2fb_temp_3
            Else
                local4 = Cast(c2fb_c_int, &O0ULL)
                c2fb_temp_4 = rbuVfsFileSize(CPtr(c2fb_sqlite3_file Ptr, @(local3->base)), CPtr(c2fb_int64 Ptr, @(local4)))
                local2 = c2fb_temp_4
                c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg3)))
                c2fb_temp_6 = ((-Cast(c2fb_c_int, ((local4 > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))))
                (*c2fb_temp_5) = c2fb_temp_6
            End If
        End If
    End If
    Return local2
End Function
Private Function rbuVfsFullPathname CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5282
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    Return CPtr(c2fb_callback_22, local0->xFullPathname)(local0, arg1, arg2, arg3)
End Function
Private Function rbuVfsDlOpen CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Const ZString Ptr) As Any Ptr
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5296
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    Return CPtr(Any Ptr, CPtr(c2fb_callback_23, local0->xDlOpen)(local0, arg1))
End Function
Private Sub rbuVfsDlError CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5306
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    CPtr(c2fb_callback_24, local0->xDlError)(local0, arg1, arg2)
End Sub
Private Function rbuVfsDlSym CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr) As Sub CDecl()
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5314
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    Return CPtr(c2fb_callback_25, local0->xDlSym)(local0, arg1, arg2)
End Function
Private Sub rbuVfsDlClose CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Any Ptr)
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5326
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    CPtr(c2fb_callback_26, local0->xDlClose)(local0, arg1)
End Sub
Private Function rbuVfsRandomness CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5336
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    Return CPtr(c2fb_callback_27, local0->xRandomness)(local0, arg1, arg2)
End Function
Private Function rbuVfsSleep CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5345
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    Return CPtr(c2fb_callback_28, local0->xSleep)(local0, arg1)
End Function
Private Function rbuVfsCurrentTime CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As Double Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5353
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, (CPtr(c2fb_rbu_vfs Ptr, arg0))->pRealVfs)
    Return CPtr(c2fb_callback_29, local0->xCurrentTime)(local0, arg1)
End Function
Private Function rbuVfsGetLastError CDecl (ByVal arg0 As c2fb_sqlite3_vfs Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As ZString Ptr) As c2fb_c_int
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5361
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Sub sqlite3rbu_destroy_vfs CDecl Alias "sqlite3rbu_destroy_vfs" (ByVal arg0 As Const ZString Ptr) Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5372
    Dim local0 As c2fb_sqlite3_vfs Ptr

    local0 = CPtr(c2fb_sqlite3_vfs Ptr, c2fb_external_sqlite3_vfs_find(arg0))
    If (-Cast(c2fb_c_int, (((local0 <> 0) AndAlso ((-Cast(c2fb_c_int, ((CPtr(Any Ptr, CPtr(c2fb_callback_19, local0->xOpen)) = CPtr(Any Ptr, ProcPtr(rbuVfsOpen)))))) <> 0))))) Then
        c2fb_external_sqlite3_mutex_free(CPtr(c2fb_sqlite3_mutex Ptr, (CPtr(c2fb_rbu_vfs Ptr, local0))->mutex))
        c2fb_external_sqlite3_vfs_unregister(local0)
        c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
    End If
End Sub
' c2fb skipped sqlite3rbu_create_vfs: outside the supported subset
' c2fb body diagnostic [static-record-callback-type-mismatch] line 5386: sqlite3rbu_create_vfs: static record callback field types do not match sqlite3_vfs.xOpen
Function sqlite3rbu_temp_size_limit CDecl Alias "sqlite3rbu_temp_size_limit" (ByVal arg0 As c2fb_sqlite3rbu Ptr, ByVal arg1 As c2fb_int64) As c2fb_int64 Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5464
    Dim c2fb_temp_0 As c2fb_i64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    If (-Cast(c2fb_c_int, ((arg1 >= Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
        c2fb_temp_0 = CPtr(c2fb_i64 Ptr, @(arg0->szTempLimit))
        c2fb_temp_1 = arg1
        (*c2fb_temp_0) = Cast(c2fb_i64, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_int64, (*c2fb_temp_0))
    End If
    Return arg0->szTempLimit
End Function
Function sqlite3rbu_temp_size CDecl Alias "sqlite3rbu_temp_size" (ByVal arg0 As c2fb_sqlite3rbu Ptr) As c2fb_int64 Export
' c2fb source-path: /home/jkfirth/port_corpus/sqlite/ext/rbu/sqlite3rbu.c
' c2fb source-line: 5471
    Return arg0->szTemp
End Function

/' ------------------------------------------------------------------------- '/
/' RBU shared-memory and step operations                                     '/
/' ------------------------------------------------------------------------- '/

Const RBU_STAGE_OAL As c2fb_c_int = 1
Const RBU_STAGE_MOVE As c2fb_c_int = 2
Const RBU_STAGE_CKPT As c2fb_c_int = 4
Const RBU_STAGE_DONE As c2fb_c_int = 5

Private Function rbuIsVacuum(ByVal pRbu As c2fb_sqlite3rbu Ptr) As c2fb_c_int
    If pRbu = 0 Then Return 0
    Return CInt(pRbu->zTarget = 0)
End Function

Private Function rbuShmChecksum CDecl Alias "rbuShmChecksum" ( _
    ByVal pRbu As c2fb_sqlite3rbu Ptr _
) As c2fb_int64
    Dim checksum As c2fb_int64 = 0

    If pRbu->rc = SQLITE_OK Then
        Dim pDatabaseFile As c2fb_sqlite3_file Ptr = pRbu->pTargetFd->pReal
        Dim sharedMemory As Any Ptr = 0
        Dim mapCode As c2fb_c_int = _
            CPtr(c2fb_callback_14, pDatabaseFile->pMethods->xShmMap)( _
                pDatabaseFile, 0, 32 * 1024, 0, @sharedMemory)
        pRbu->rc = mapCode

        If mapCode = SQLITE_OK Then
            ' The restart checkpoint still owns the WAL-index locks here.
            ' The two words form the checksum stored at byte offset 40.
            Dim checksumWords As c2fb_u32 Ptr = CPtr(c2fb_u32 Ptr, sharedMemory)
            checksum = Cast(c2fb_int64, _
                (Cast(c2fb_u64, checksumWords[10]) Shl 32) + _
                 Cast(c2fb_u64, checksumWords[11]))
        End If
    End If

    Return checksum
End Function

Function sqlite3rbu_step CDecl Alias "sqlite3rbu_step" ( _
    ByVal pRbu As c2fb_sqlite3rbu Ptr _
) As c2fb_c_int Export
    If pRbu = 0 Then Return SQLITE_NOMEM

    Select Case pRbu->eStage
    Case RBU_STAGE_OAL
        Dim pIterator As c2fb_RbuObjIter Ptr = @pRbu->objiter

        If rbuIsVacuum(pRbu) <> 0 AndAlso _
           pRbu->nProgress = 0 AndAlso pRbu->rc = SQLITE_OK Then
            rbuCreateTargetSchema(pRbu)
            rbuCopyPragma(pRbu, StrPtr(!"user_version"))
            rbuCopyPragma(pRbu, StrPtr(!"application_id"))
        End If

        While pRbu->rc = SQLITE_OK AndAlso pIterator->zTbl <> 0
            If pIterator->bCleanup <> 0 Then
                If rbuIsVacuum(pRbu) = 0 AndAlso pIterator->abIndexed <> 0 Then
                    rbuMPrintfExec( _
                        pRbu, pRbu->dbRbu, _
                        StrPtr(!"DELETE FROM %s.'rbu_tmp_%q'"), _
                        CPtr(Const ZString Ptr, @pRbu->zStateDb(0)), _
                        pIterator->zDataTbl)
                End If
            Else
                rbuObjIterPrepareAll(pRbu, pIterator, 0)

                If pRbu->rc = SQLITE_OK Then
                    Dim stepCode As c2fb_c_int = _
                        c2fb_external_sqlite3_step(pIterator->pSelect)
                    If stepCode = SQLITE_ROW Then
                        pRbu->nProgress += 1
                        pRbu->nStep += 1
                        Return rbuStep(pRbu)
                    End If

                    pRbu->rc = c2fb_external_sqlite3_reset(pIterator->pSelect)
                    pRbu->nStep = 0
                End If
            End If

            rbuObjIterNext(pRbu, pIterator)
        Wend

        If pRbu->rc = SQLITE_OK Then
            rbuSaveState(pRbu, RBU_STAGE_MOVE)
            rbuIncrSchemaCookie(pRbu)
            If pRbu->rc = SQLITE_OK Then
                pRbu->rc = c2fb_external_sqlite3_exec( _
                    pRbu->dbMain, StrPtr(!"COMMIT"), _
                    CPtr(c2fb_callback_4, 0), 0, 0)
            End If
            If pRbu->rc = SQLITE_OK Then
                pRbu->rc = c2fb_external_sqlite3_exec( _
                    pRbu->dbRbu, StrPtr(!"COMMIT"), _
                    CPtr(c2fb_callback_4, 0), 0, 0)
            End If
            pRbu->eStage = RBU_STAGE_MOVE
        End If

    Case RBU_STAGE_MOVE
        If pRbu->rc = SQLITE_OK Then
            rbuMoveOalFile(pRbu)
            pRbu->nProgress += 1
        End If

    Case RBU_STAGE_CKPT
        If pRbu->rc = SQLITE_OK Then
            If pRbu->nStep >= pRbu->nFrame Then
                Dim pDatabaseFile As c2fb_sqlite3_file Ptr = pRbu->pTargetFd->pReal
                pRbu->rc = CPtr(c2fb_callback_10, pDatabaseFile->pMethods->xSync)( _
                    pDatabaseFile, SQLITE_SYNC_NORMAL)

                If pRbu->rc = SQLITE_OK Then
                    Dim sharedMemory As Any Ptr = 0
                    pRbu->rc = CPtr( _
                        c2fb_callback_14, pDatabaseFile->pMethods->xShmMap)( _
                            pDatabaseFile, 0, 32 * 1024, 0, @sharedMemory)
                    If pRbu->rc = SQLITE_OK Then
                        ' nBackfill is the 25th 32-bit word in WAL-index page 0.
                        Dim walIndexWords As c2fb_u32 Ptr = _
                            CPtr(c2fb_u32 Ptr, sharedMemory)
                        walIndexWords[24] = pRbu->iMaxFrame
                    End If
                End If

                If pRbu->rc = SQLITE_OK Then
                    pRbu->eStage = RBU_STAGE_DONE
                    pRbu->rc = SQLITE_DONE
                End If
            Else
                ' Finish the current disk sector before saving checkpoint state.
                Dim sectorIndex As c2fb_u32
                Do
                    Dim pFrame As c2fb_RbuFrame Ptr = _
                        @pRbu->aFrame[pRbu->nStep]
                    sectorIndex = _
                        (pFrame->iDbPage - 1) \ pRbu->nPagePerSector
                    rbuCheckpointFrame(pRbu, pFrame)
                    pRbu->nStep += 1
                Loop While pRbu->nStep < pRbu->nFrame AndAlso _
                    sectorIndex = _
                        ((pRbu->aFrame[pRbu->nStep].iDbPage - 1) \ _
                         pRbu->nPagePerSector) AndAlso _
                    pRbu->rc = SQLITE_OK
            End If

            pRbu->nProgress += 1
        End If
    End Select

    Return pRbu->rc
End Function

/' ------------------------------------------------------------------------- '/
/' RBU shared-memory VFS callback                                            '/
/' ------------------------------------------------------------------------- '/

Private Function rbuVfsShmMap CDecl Alias "rbuVfsShmMap" ( _
    ByVal pFile As c2fb_sqlite3_file Ptr, _
    ByVal regionIndex As c2fb_c_int, _
    ByVal regionSize As c2fb_c_int, _
    ByVal isWrite As c2fb_c_int, _
    ByVal pRegion As Any Ptr Ptr _
) As c2fb_c_int
    Dim pRbuFile As c2fb_rbu_file Ptr = CPtr(c2fb_rbu_file Ptr, pFile)
    Dim resultCode As c2fb_c_int = SQLITE_OK
    Dim stage As c2fb_c_int = 0
    If pRbuFile->pRbu <> 0 Then stage = pRbuFile->pRbu->eStage

    If (pRbuFile->openFlags And _
        (SQLITE_OPEN_MAIN_DB Or SQLITE_OPEN_TEMP_DB)) = 0 Then
        Return SQLITE_MISUSE
    End If

    If stage = RBU_STAGE_OAL Then
        Dim allocationBytes As c2fb_size_t = _
            Cast(c2fb_size_t, (regionIndex + 1) * SizeOf(ZString Ptr))
        Dim pNewRegions As ZString Ptr Ptr = CPtr( _
            ZString Ptr Ptr, _
            c2fb_external_sqlite3_realloc64( _
                pRbuFile->apShm, Cast(c2fb_uint64, allocationBytes)))

        If regionIndex <> pRbuFile->nShm Then Return SQLITE_CORRUPT
        If pNewRegions = 0 Then
            resultCode = SQLITE_NOMEM
        Else
            Dim newRegionCount As c2fb_size_t = _
                Cast(c2fb_size_t, 1 + regionIndex - pRbuFile->nShm)
            If newRegionCount > 0 Then
                c2fb_crt_memset( _
                    @pNewRegions[pRbuFile->nShm], 0, _
                    Cast(c2fb_size_t, newRegionCount * SizeOf(ZString Ptr)))
            End If
            pRbuFile->apShm = pNewRegions
            pRbuFile->nShm = regionIndex + 1
        End If

        If resultCode = SQLITE_OK Then
            Dim pNewRegion As ZString Ptr = CPtr( _
                ZString Ptr, _
                c2fb_external_sqlite3_malloc64( _
                    Cast(c2fb_uint64, regionSize)))
            If pNewRegion = 0 Then
                resultCode = SQLITE_NOMEM
            Else
                c2fb_crt_memset(pNewRegion, 0, Cast(c2fb_size_t, regionSize))
                pRbuFile->apShm[regionIndex] = pNewRegion
            End If
        End If

        If resultCode = SQLITE_OK Then
            pRegion[0] = pRbuFile->apShm[regionIndex]
        Else
            pRegion[0] = 0
        End If
    Else
        If pRbuFile->apShm <> 0 Then Return SQLITE_MISUSE
        resultCode = CPtr( _
            c2fb_callback_14, pRbuFile->pReal->pMethods->xShmMap)( _
                pRbuFile->pReal, regionIndex, regionSize, isWrite, pRegion)
    End If

    Return resultCode
End Function

/' ------------------------------------------------------------------------- '/
/' RBU VFS method table initialization and registration                      '/
/' ------------------------------------------------------------------------- '/

Private Sub rbuInitializeVfsIoMethods()
    Dim pInitializationMutex As c2fb_sqlite3_mutex Ptr = _
        c2fb_external_sqlite3_mutex_alloc(SQLITE_MUTEX_STATIC_APP1)
    If pInitializationMutex <> 0 Then _
        c2fb_external_sqlite3_mutex_enter(pInitializationMutex)

    If rbuVfsMethodsInitialized = 0 Then
        rbuVfsIoMethodsV2.iVersion = 2
        rbuVfsIoMethodsV2.xClose = CPtr(c2fb_callback_6, ProcPtr(rbuVfsClose))
        rbuVfsIoMethodsV2.xRead = CPtr(c2fb_callback_7, ProcPtr(rbuVfsRead))
        rbuVfsIoMethodsV2.xWrite = CPtr(c2fb_callback_8, ProcPtr(rbuVfsWrite))
        rbuVfsIoMethodsV2.xTruncate = CPtr(c2fb_callback_9, ProcPtr(rbuVfsTruncate))
        rbuVfsIoMethodsV2.xSync = CPtr(c2fb_callback_10, ProcPtr(rbuVfsSync))
        rbuVfsIoMethodsV2.xFileSize = CPtr(c2fb_callback_11, ProcPtr(rbuVfsFileSize))
        rbuVfsIoMethodsV2.xLock = CPtr(c2fb_callback_10, ProcPtr(rbuVfsLock))
        rbuVfsIoMethodsV2.xUnlock = CPtr(c2fb_callback_10, ProcPtr(rbuVfsUnlock))
        rbuVfsIoMethodsV2.xCheckReservedLock = _
            CPtr(c2fb_callback_12, ProcPtr(rbuVfsCheckReservedLock))
        rbuVfsIoMethodsV2.xFileControl = _
            CPtr(c2fb_callback_13, ProcPtr(rbuVfsFileControl))
        rbuVfsIoMethodsV2.xSectorSize = CPtr(c2fb_callback_6, ProcPtr(rbuVfsSectorSize))
        rbuVfsIoMethodsV2.xDeviceCharacteristics = _
            CPtr(c2fb_callback_6, ProcPtr(rbuVfsDeviceCharacteristics))
        rbuVfsIoMethodsV2.xShmMap = _
            CPtr(c2fb_callback_14, ProcPtr(rbuVfsShmMap))
        rbuVfsIoMethodsV2.xShmLock = CPtr(c2fb_callback_15, ProcPtr(rbuVfsShmLock))
        rbuVfsIoMethodsV2.xShmBarrier = _
            CPtr(c2fb_callback_16, ProcPtr(rbuVfsShmBarrier))
        rbuVfsIoMethodsV2.xShmUnmap = _
            CPtr(c2fb_callback_10, ProcPtr(rbuVfsShmUnmap))
        rbuVfsIoMethodsV2.xFetch = 0
        rbuVfsIoMethodsV2.xUnfetch = 0

        rbuVfsIoMethodsV1.iVersion = 1
        rbuVfsIoMethodsV1.xClose = rbuVfsIoMethodsV2.xClose
        rbuVfsIoMethodsV1.xRead = rbuVfsIoMethodsV2.xRead
        rbuVfsIoMethodsV1.xWrite = rbuVfsIoMethodsV2.xWrite
        rbuVfsIoMethodsV1.xTruncate = rbuVfsIoMethodsV2.xTruncate
        rbuVfsIoMethodsV1.xSync = rbuVfsIoMethodsV2.xSync
        rbuVfsIoMethodsV1.xFileSize = rbuVfsIoMethodsV2.xFileSize
        rbuVfsIoMethodsV1.xLock = rbuVfsIoMethodsV2.xLock
        rbuVfsIoMethodsV1.xUnlock = rbuVfsIoMethodsV2.xUnlock
        rbuVfsIoMethodsV1.xCheckReservedLock = _
            rbuVfsIoMethodsV2.xCheckReservedLock
        rbuVfsIoMethodsV1.xFileControl = rbuVfsIoMethodsV2.xFileControl
        rbuVfsIoMethodsV1.xSectorSize = rbuVfsIoMethodsV2.xSectorSize
        rbuVfsIoMethodsV1.xDeviceCharacteristics = _
            rbuVfsIoMethodsV2.xDeviceCharacteristics
        rbuVfsMethodsInitialized = 1
    End If

    If pInitializationMutex <> 0 Then _
        c2fb_external_sqlite3_mutex_leave(pInitializationMutex)
End Sub

Function sqlite3rbu_create_vfs CDecl Alias "sqlite3rbu_create_vfs" ( _
    ByVal zName As Const ZString Ptr, _
    ByVal zParent As Const ZString Ptr _
) As c2fb_c_int Export
    If zName = 0 Then Return SQLITE_MISUSE

    rbuInitializeVfsIoMethods()

    Dim nameBytes As c2fb_size_t = c2fb_crt_strlen(zName)
    Dim allocationBytes As c2fb_size_t = _
        Cast(c2fb_size_t, SizeOf(c2fb_rbu_vfs) + nameBytes + 1)
    Dim pNewVfs As c2fb_rbu_vfs Ptr = CPtr( _
        c2fb_rbu_vfs Ptr, _
        c2fb_external_sqlite3_malloc64(Cast(c2fb_uint64, allocationBytes)))
    If pNewVfs = 0 Then Return SQLITE_NOMEM
    c2fb_crt_memset(pNewVfs, 0, allocationBytes)

    Dim resultCode As c2fb_c_int = SQLITE_OK
    Dim pParentVfs As c2fb_sqlite3_vfs Ptr = _
        c2fb_external_sqlite3_vfs_find(zParent)
    If pParentVfs = 0 Then
        resultCode = SQLITE_NOTFOUND
    Else
        pNewVfs->base.iVersion = 1
        pNewVfs->base.szOsFile = _
            SizeOf(c2fb_rbu_file) + pParentVfs->szOsFile
        pNewVfs->base.mxPathname = pParentVfs->mxPathname
        pNewVfs->base.pNext = 0
        pNewVfs->base.zName = CPtr(Const ZString Ptr, @pNewVfs[1])
        pNewVfs->base.pAppData = 0
        pNewVfs->pRealVfs = pParentVfs
        c2fb_crt_memcpy(CPtr(ZString Ptr, @pNewVfs[1]), zName, nameBytes)

        pNewVfs->base.xOpen = _
            CPtr(c2fb_callback_19, ProcPtr(rbuVfsOpen))
        pNewVfs->base.xDelete = _
            CPtr(c2fb_callback_20, ProcPtr(rbuVfsDelete))
        pNewVfs->base.xAccess = _
            CPtr(c2fb_callback_21, ProcPtr(rbuVfsAccess))
        pNewVfs->base.xFullPathname = _
            CPtr(c2fb_callback_22, ProcPtr(rbuVfsFullPathname))
#ifndef SQLITE_OMIT_LOAD_EXTENSION
        pNewVfs->base.xDlOpen = CPtr(c2fb_callback_23, ProcPtr(rbuVfsDlOpen))
        pNewVfs->base.xDlError = CPtr(c2fb_callback_24, ProcPtr(rbuVfsDlError))
        pNewVfs->base.xDlSym = CPtr(c2fb_callback_25, ProcPtr(rbuVfsDlSym))
        pNewVfs->base.xDlClose = CPtr(c2fb_callback_26, ProcPtr(rbuVfsDlClose))
#endif
        pNewVfs->base.xRandomness = _
            CPtr(c2fb_callback_27, ProcPtr(rbuVfsRandomness))
        pNewVfs->base.xSleep = CPtr(c2fb_callback_28, ProcPtr(rbuVfsSleep))
        pNewVfs->base.xCurrentTime = _
            CPtr(c2fb_callback_29, ProcPtr(rbuVfsCurrentTime))
        pNewVfs->base.xGetLastError = _
            CPtr(c2fb_callback_30, ProcPtr(rbuVfsGetLastError))
        pNewVfs->base.xCurrentTimeInt64 = 0
        pNewVfs->base.xSetSystemCall = 0
        pNewVfs->base.xGetSystemCall = 0
        pNewVfs->base.xNextSystemCall = 0

        pNewVfs->mutex = _
            c2fb_external_sqlite3_mutex_alloc(SQLITE_MUTEX_RECURSIVE)
        If pNewVfs->mutex = 0 Then
            resultCode = SQLITE_NOMEM
        Else
            resultCode = c2fb_external_sqlite3_vfs_register( _
                @pNewVfs->base, 0)
        End If
    End If

    If resultCode <> SQLITE_OK Then
        If pNewVfs->mutex <> 0 Then _
            c2fb_external_sqlite3_mutex_free(pNewVfs->mutex)
        c2fb_external_sqlite3_free(pNewVfs)
    End If

    Return resultCode
End Function
/' end of sqlite3_rbu.bas '/
