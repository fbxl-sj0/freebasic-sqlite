/'
** 2011 Jan 27
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
'/
/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_aux.bas

    Purpose:

        Implement the fts4aux virtual-table callbacks and registration.

    Responsibilities:

        - Enumerate terms and aggregate document and occurrence counts.
        - Expose the fts4aux table through SQLite's virtual-table API.

    This file intentionally does NOT contain:

        - The main FTS3/FTS4 table module or tokenizer implementation.
        - SQLite test support.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
#include once "sqlite3_btree.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_expr_types.bi"
#include once "sqlite3_hash_types.bi"
#include once "sqlite3_pager.bi"
#include once "sqlite3_parser_types.bi"
#include once "sqlite3_types.bi"
#include once "sqlite3_vdbe_core.bi"
#include once "sqlite3_vdbe_mem_types.bi"


/' ------------------------------------------------------------------------- '/
/' FTS3 auxiliary SQL functions                                              '/
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
Declare Function sqlite3_malloc CDecl Alias "sqlite3_malloc" (ByVal arg0 As c2fb_c_int) As Any Ptr
Declare Function sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function sqlite3_stricmp CDecl Alias "sqlite3_stricmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function sqlite3_strnicmp CDecl Alias "sqlite3_strnicmp" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_create_module CDecl Alias "sqlite3_create_module" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const Any Ptr, ByVal arg3 As Any Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int

Type c2fb_sqlite3_destructor_type As Sub CDecl(ByVal arg0 As Any Ptr)

Private Type c2fb_source_record_41
    pModule As Any Ptr
End Type

Private Type c2fb_source_record_43
    count As c2fb_c_int
    chain As Any Ptr
End Type

Private Type c2fb_source_record_44
    keyClass As Byte
    copyKey As Byte
    count As c2fb_c_int
    first As Any Ptr
    htsize As c2fb_c_int
    ht As c2fb_source_record_43 Ptr
End Type

Private Type c2fb_source_record_46
    nPrefix As c2fb_c_int
    hPending As c2fb_source_record_44
End Type

Private Type c2fb_source_record_47
    base As SqliteVtab
    db As sqlite3 Ptr
    zDb As Const ZString Ptr
    zName As Const ZString Ptr
    nColumn As c2fb_c_int
    azColumn As ZString Ptr Ptr
    abNotindexed As UByte Ptr
    pTokenizer As c2fb_source_record_41 Ptr
    zContentTbl As ZString Ptr
    zLanguageid As ZString Ptr
    nAutoincrmerge As c2fb_c_int
    nLeafAdd As c2fb_c_uint
    bLock As c2fb_c_int
    aStmt(0 To 39) As SqliteVdbe Ptr
    pSeekStmt As SqliteVdbe Ptr
    zReadExprlist As ZString Ptr
    zWriteExprlist As ZString Ptr
    nNodeSize As c2fb_c_int
    bFts4 As UByte
    bHasStat As UByte
    bHasDocsize As UByte
    bDescIdx As UByte
    bIgnoreSavepoint As UByte
    nPgsz As c2fb_c_int
    zSegmentsTbl As ZString Ptr
    pSegments As Any Ptr
    iSavepoint As c2fb_c_int
    nIndex As c2fb_c_int
    aIndex As c2fb_source_record_46 Ptr
    nMaxPendingData As c2fb_c_int
    nPendingData As c2fb_c_int
    iPrevDocid As c2fb_int64
    iPrevLangid As c2fb_c_int
    bPrevDelete As c2fb_c_int
End Type

Private Type c2fb_source_record_52
    zTerm As Const ZString Ptr
    nTerm As c2fb_c_int
    iCol As c2fb_c_int
    flags As c2fb_c_int
End Type

Private Type c2fb_source_record_53
    apSegment As Any Ptr Ptr
    nSegment As c2fb_c_int
    nAdvance As c2fb_c_int
    pFilter As c2fb_source_record_52 Ptr
    aBuffer As ZString Ptr
    nBuffer As c2fb_int64
    iColFilter As c2fb_c_int
    bRestart As c2fb_c_int
    nCost As c2fb_c_int
    bLookup As c2fb_c_int
    zTerm As ZString Ptr
    nTerm As c2fb_c_int
    aDoclist As ZString Ptr
    nDoclist As c2fb_c_int
End Type

Private Type c2fb_source_record_54
    base As SqliteVtab
    pFts3Tab As c2fb_source_record_47 Ptr
End Type

Private Type c2fb_source_record_55
    nDoc As c2fb_int64
    nOcc As c2fb_int64
End Type

Private Type c2fb_source_record_56
    base As SqliteVtabCursor
    csr As c2fb_source_record_53
    filter As c2fb_source_record_52
    zStop As ZString Ptr
    nStop As c2fb_c_int
    iLangid As c2fb_c_int
    isEof As c2fb_c_int
    iRowid As c2fb_int64
    iCol As c2fb_c_int
    nStat As c2fb_c_int
    aStat As c2fb_source_record_55 Ptr
End Type

Private Function __c2fb_double_value(ByVal value As Double) As Double
    Return value
End Function
Declare Function fts3auxConnectMethod CDecl Alias "fts3auxConnectMethod" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As SqliteVtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
Declare Function fts3auxDisconnectMethod CDecl Alias "fts3auxDisconnectMethod" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
Declare Function fts3auxIsBinary CDecl Alias "fts3auxIsBinary" (ByVal arg0 As SqliteIndexInfo Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3auxBestIndexMethod CDecl Alias "fts3auxBestIndexMethod" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As SqliteIndexInfo Ptr) As c2fb_c_int
Declare Function fts3auxOpenMethod CDecl Alias "fts3auxOpenMethod" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As SqliteVtabCursor Ptr Ptr) As c2fb_c_int
Declare Function fts3auxCloseMethod CDecl Alias "fts3auxCloseMethod" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
Declare Function fts3auxGrowStatArray CDecl Alias "fts3auxGrowStatArray" (ByVal arg0 As c2fb_source_record_56 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function fts3auxNextMethod CDecl Alias "fts3auxNextMethod" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
Declare Function fts3auxFilterMethod CDecl Alias "fts3auxFilterMethod" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
Declare Function fts3auxEofMethod CDecl Alias "fts3auxEofMethod" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
Declare Function fts3auxColumnMethod CDecl Alias "fts3auxColumnMethod" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As SqliteResultContext Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function fts3auxRowidMethod CDecl Alias "fts3auxRowidMethod" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_finalize_ CDecl Alias "sqlite3_finalize" (ByVal arg0 As SqliteVdbe Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_int___ CDecl Alias "sqlite3_value_int" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_value_text___ CDecl Alias "sqlite3_value_text" (ByVal arg0 As SqliteVdbeMem Ptr) As Const UByte Ptr
Declare Function c2fb_external_sqlite3_value_type_ CDecl Alias "sqlite3_value_type" (ByVal arg0 As SqliteVdbeMem Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3_result_int___ CDecl Alias "sqlite3_result_int" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_c_int)
Declare Sub c2fb_external_sqlite3_result_int64__ CDecl Alias "sqlite3_result_int64" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As c2fb_int64)
Declare Sub c2fb_external_sqlite3_result_text___ CDecl Alias "sqlite3_result_text" (ByVal arg0 As SqliteResultContext Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_sqlite3_destructor_type)
Declare Function c2fb_external_sqlite3_declare_vtab__ CDecl Alias "sqlite3_declare_vtab" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Const ZString Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3_vtab_collation_ CDecl Alias "sqlite3_vtab_collation" (ByVal arg0 As SqliteIndexInfo Ptr, ByVal arg1 As c2fb_c_int) As Const ZString Ptr
Declare Sub c2fb_external_sqlite3Fts3SegmentsClose CDecl Alias "sqlite3Fts3SegmentsClose" (ByVal arg0 As c2fb_source_record_47 Ptr)
Declare Function c2fb_external_sqlite3Fts3SegReaderStart CDecl Alias "sqlite3Fts3SegReaderStart" (ByVal arg0 As c2fb_source_record_47 Ptr, ByVal arg1 As c2fb_source_record_53 Ptr, ByVal arg2 As c2fb_source_record_52 Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts3SegReaderStep CDecl Alias "sqlite3Fts3SegReaderStep" (ByVal arg0 As c2fb_source_record_47 Ptr, ByVal arg1 As c2fb_source_record_53 Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3SegReaderFinish CDecl Alias "sqlite3Fts3SegReaderFinish" (ByVal arg0 As c2fb_source_record_53 Ptr)
Declare Function c2fb_external_sqlite3Fts3SegReaderCursor CDecl Alias "sqlite3Fts3SegReaderCursor" (ByVal arg0 As c2fb_source_record_47 Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int, ByVal arg4 As Const ZString Ptr, ByVal arg5 As c2fb_c_int, ByVal arg6 As c2fb_c_int, ByVal arg7 As c2fb_c_int, ByVal arg8 As c2fb_source_record_53 Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3ErrMsg CDecl Alias "sqlite3Fts3ErrMsg" (ByVal arg0 As ZString Ptr Ptr, ByVal arg1 As Const ZString Ptr, ...)
Declare Function c2fb_external_sqlite3Fts3GetVarint CDecl Alias "sqlite3Fts3GetVarint" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
Declare Sub c2fb_external_sqlite3Fts3Dequote CDecl Alias "sqlite3Fts3Dequote" (ByVal arg0 As ZString Ptr)
' c2fb skipped __bswap_16: FreeBASIC body already exists
' c2fb skipped __bswap_32: FreeBASIC body already exists
' c2fb skipped __bswap_64: FreeBASIC body already exists
' c2fb skipped __uint16_identity: FreeBASIC body already exists
' c2fb skipped __uint32_identity: FreeBASIC body already exists
' c2fb skipped __uint64_identity: FreeBASIC body already exists
Private Function fts3auxConnectMethod CDecl Alias "fts3auxConnectMethod" (ByVal arg0 As sqlite3 Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const ZString Ptr Ptr, ByVal arg4 As SqliteVtab Ptr Ptr, ByVal arg5 As ZString Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As Const ZString Ptr
    Dim local1 As Const ZString Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_int64
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_source_record_54 Ptr
    Dim c2fb_temp_0 As Const ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As Const ZString Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Const ZString Ptr
    Dim c2fb_temp_5 As Const ZString Ptr
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_int64
    Dim c2fb_temp_9 As c2fb_source_record_54 Ptr
    Dim c2fb_temp_10 As Any Ptr
    Dim c2fb_temp_11 As c2fb_source_record_47 Ptr Ptr
    Dim c2fb_temp_12 As c2fb_source_record_47 Ptr
    Dim c2fb_temp_13 As Const ZString Ptr Ptr
    Dim c2fb_temp_14 As Const ZString Ptr
    Dim c2fb_temp_15 As Const ZString Ptr Ptr
    Dim c2fb_temp_16 As Const ZString Ptr
    Dim c2fb_temp_17 As sqlite3 Ptr Ptr
    Dim c2fb_temp_18 As sqlite3 Ptr
    Dim c2fb_temp_19 As c2fb_c_int Ptr
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As Any Ptr
    Dim c2fb_temp_22 As Any Ptr
    Dim c2fb_temp_23 As SqliteVtab Ptr Ptr
    Dim c2fb_temp_24 As SqliteVtab Ptr

    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C automatic storage declaration
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg2 <> Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg2 <> Cast(c2fb_c_int, 5ULL))))) <> 0))))) Then
        Goto c2fb_label_0
    End If
    c2fb_temp_0 = arg3[Cast(c2fb_c_int, 1ULL)]
    local0 = c2fb_temp_0
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(local0)))
    local2 = c2fb_temp_1
    If (-Cast(c2fb_c_int, ((arg2 = Cast(c2fb_c_int, 5ULL))))) Then
        If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 4ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_strnicmp(StrPtr(!"temp"), local0, Cast(c2fb_c_int, 4ULL)))))) <> 0))))) Then
            c2fb_temp_2 = arg3[Cast(c2fb_c_int, 3ULL)]
            local0 = c2fb_temp_2
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(local0)))
            local2 = c2fb_temp_3
            c2fb_temp_4 = arg3[Cast(c2fb_c_int, 4ULL)]
            local1 = c2fb_temp_4
        Else
            Goto c2fb_label_0
        End If
    Else
        c2fb_temp_5 = arg3[Cast(c2fb_c_int, 3ULL)]
        local1 = c2fb_temp_5
    End If
    c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(local1)))
    local3 = c2fb_temp_6
    c2fb_temp_7 = Cast(c2fb_c_int, c2fb_external_sqlite3_declare_vtab__(arg0, StrPtr(!"CREATE TABLE x(term, col, documents, occurrences, languageid HIDDEN)")))
    local5 = c2fb_temp_7
    If (-Cast(c2fb_c_int, ((local5 <> Cast(c2fb_c_int, &O0ULL))))) Then
        Return local5
    End If
    c2fb_temp_8 = Cast(c2fb_int64, Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_54))) + Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_47))))) + Cast(c2fb_uint64, local2))) + Cast(c2fb_uint64, local3))) + Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))))
    local4 = c2fb_temp_8
    c2fb_temp_9 = CPtr(c2fb_source_record_54 Ptr, CPtr(Any Ptr, sqlite3_malloc64(local4)))
    local6 = c2fb_temp_9
    If (-Cast(c2fb_c_int, (local6 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_10 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local6), Cast(c2fb_c_int, &O0ULL), local4))
    c2fb_temp_11 = CPtr(c2fb_source_record_47 Ptr Ptr, @(local6->pFts3Tab))
    c2fb_temp_12 = CPtr(c2fb_source_record_47 Ptr, CPtr(c2fb_source_record_54 Ptr, @(local6[Cast(c2fb_c_int, 1ULL)])))
    (*c2fb_temp_11) = c2fb_temp_12
    c2fb_temp_13 = CPtr(Const ZString Ptr Ptr, @(local6->pFts3Tab->zDb))
    c2fb_temp_14 = CPtr(Const ZString Ptr, CPtr(ZString Ptr, CPtr(c2fb_source_record_47 Ptr, @(local6->pFts3Tab[Cast(c2fb_c_int, 1ULL)]))))
    (*c2fb_temp_13) = c2fb_temp_14
    c2fb_temp_15 = CPtr(Const ZString Ptr Ptr, @(local6->pFts3Tab->zName))
    c2fb_temp_16 = CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Const Byte Ptr, local6->pFts3Tab->zDb)[Cast(c2fb_c_int, (local2 + Cast(c2fb_c_int, 1ULL)))])))
    (*c2fb_temp_15) = c2fb_temp_16
    c2fb_temp_17 = CPtr(sqlite3 Ptr Ptr, @(local6->pFts3Tab->db))
    c2fb_temp_18 = arg0
    (*c2fb_temp_17) = c2fb_temp_18
    c2fb_temp_19 = CPtr(c2fb_c_int Ptr, @(local6->pFts3Tab->nIndex))
    c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
    (*c2fb_temp_19) = c2fb_temp_20
    c2fb_temp_21 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(ZString Ptr, local6->pFts3Tab->zDb)), CPtr(Const Any Ptr, local0), local2))
    c2fb_temp_22 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(ZString Ptr, local6->pFts3Tab->zName)), CPtr(Const Any Ptr, local1), local3))
    c2fb_external_sqlite3Fts3Dequote(CPtr(ZString Ptr, local6->pFts3Tab->zName))
    c2fb_temp_23 = CPtr(SqliteVtab Ptr Ptr, @((*arg4)))
    c2fb_temp_24 = CPtr(SqliteVtab Ptr, local6)
    (*c2fb_temp_23) = c2fb_temp_24
    Return Cast(c2fb_c_int, &O0ULL)
    c2fb_label_0:
    c2fb_external_sqlite3Fts3ErrMsg(arg5, StrPtr(!"invalid arguments to fts4aux constructor"))
    Return Cast(c2fb_c_int, 1ULL)
End Function
Private Function fts3auxDisconnectMethod CDecl Alias "fts3auxDisconnectMethod" (ByVal arg0 As SqliteVtab Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_54 Ptr
    Dim local1 As c2fb_source_record_47 Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_54 Ptr, arg0)
    local1 = local0->pFts3Tab
    ' C automatic storage declaration
    c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local2 = c2fb_temp_0
    While (-Cast(c2fb_c_int, ((local2 < (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (40ULL * SizeOf(SqliteVdbe Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(SqliteVdbe Ptr))))))))))))
        c2fb_external_sqlite3_finalize_(local1->aStmt(local2))
    c2fb_flow_1:
        c2fb_temp_1 = local2
        local2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
    Wend
    c2fb_flow_0:
    sqlite3_free(CPtr(Any Ptr, local1->zSegmentsTbl))
    sqlite3_free(CPtr(Any Ptr, local0))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3auxIsBinary CDecl Alias "fts3auxIsBinary" (ByVal arg0 As SqliteIndexInfo Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Return (-Cast(c2fb_c_int, ((Cast(c2fb_c_int, &O0ULL) = sqlite3_stricmp(StrPtr(!"binary"), CPtr(Const ZString Ptr, c2fb_external_sqlite3_vtab_collation_(arg0, arg1)))))))
End Function
Private Function fts3auxBestIndexMethod CDecl Alias "fts3auxBestIndexMethod" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As SqliteIndexInfo Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim c2fb_temp_0 As SQLITE_C_INT Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As SQLITE_C_INT Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As SQLITE_C_INT Ptr
    Dim c2fb_temp_14 As c2fb_c_int
    Dim c2fb_temp_15 As Double Ptr
    Dim c2fb_temp_16 As Double
    Dim c2fb_temp_17 As SQLITE_C_INT Ptr
    Dim c2fb_temp_18 As c2fb_c_int
    Dim c2fb_temp_19 As Double Ptr
    Dim c2fb_temp_20 As Double
    Dim c2fb_temp_21 As SQLITE_C_INT Ptr
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As SQLITE_C_INT Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As Double Ptr
    Dim c2fb_temp_27 As Double
    Dim c2fb_temp_28 As SQLITE_C_INT Ptr
    Dim c2fb_temp_29 As c2fb_c_int
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_temp_31 As SQLITE_C_INT Ptr
    Dim c2fb_temp_32 As c2fb_c_int
    Dim c2fb_temp_33 As Double Ptr
    Dim c2fb_temp_34 As Double
    Dim c2fb_temp_35 As c2fb_c_int
    Dim c2fb_temp_36 As SQLITE_C_INT Ptr
    Dim c2fb_temp_37 As c2fb_c_int
    Dim c2fb_temp_38 As Double Ptr
    Dim c2fb_temp_39 As Double

    ' C automatic storage declaration
    local1 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local2 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local3 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local4 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local5 = Cast(c2fb_c_int, 1ULL)
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((arg1->nOrderBy = Cast(c2fb_c_int, 1ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((arg1->aOrderBy[Cast(c2fb_c_int, &O0ULL)].iColumn = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((Cast(c2fb_c_int, arg1->aOrderBy[Cast(c2fb_c_int, &O0ULL)].desc) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
        c2fb_temp_0 = CPtr(SQLITE_C_INT Ptr, @(arg1->orderByConsumed))
        c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = Cast(SQLITE_C_INT, c2fb_temp_1)
        c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    End If
    c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    local0 = c2fb_temp_2
    While (-Cast(c2fb_c_int, ((local0 < arg1->nConstraint))))
        If (-Cast(c2fb_c_int, (((arg1->aConstraint[local0].usable <> 0) AndAlso (fts3auxIsBinary(arg1, local0) <> 0))))) Then
            local6 = arg1->aConstraint[local0].op
            local7 = arg1->aConstraint[local0].iColumn
            If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, &O0ULL))))) Then
                If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, 2ULL))))) Then
                    c2fb_temp_4 = Cast(c2fb_c_int, local0)
                    local1 = c2fb_temp_4
                End If
                If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, 16ULL))))) Then
                    c2fb_temp_5 = Cast(c2fb_c_int, local0)
                    local3 = c2fb_temp_5
                End If
                If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, 8ULL))))) Then
                    c2fb_temp_6 = Cast(c2fb_c_int, local0)
                    local3 = c2fb_temp_6
                End If
                If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, 4ULL))))) Then
                    c2fb_temp_7 = Cast(c2fb_c_int, local0)
                    local2 = c2fb_temp_7
                End If
                If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, 32ULL))))) Then
                    c2fb_temp_8 = Cast(c2fb_c_int, local0)
                    local2 = c2fb_temp_8
                End If
            End If
            If (-Cast(c2fb_c_int, ((local7 = Cast(c2fb_c_int, 4ULL))))) Then
                If (-Cast(c2fb_c_int, ((local6 = Cast(c2fb_c_int, 2ULL))))) Then
                    c2fb_temp_9 = Cast(c2fb_c_int, local0)
                    local4 = c2fb_temp_9
                End If
            End If
        End If
    c2fb_flow_1:
        c2fb_temp_3 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    Wend
    c2fb_flow_0:
    If (-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_10 = CPtr(SQLITE_C_INT Ptr, @(arg1->idxNum))
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_10) = Cast(SQLITE_C_INT, c2fb_temp_11)
        c2fb_temp_11 = Cast(c2fb_c_int, (*c2fb_temp_10))
        c2fb_temp_13 = CPtr(SQLITE_C_INT Ptr, @(arg1->aConstraintUsage[local1].argvIndex))
        c2fb_temp_12 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_12 + 1)))
        c2fb_temp_14 = Cast(c2fb_c_int, c2fb_temp_12)
        (*c2fb_temp_13) = Cast(SQLITE_C_INT, c2fb_temp_14)
        c2fb_temp_14 = Cast(c2fb_c_int, (*c2fb_temp_13))
        c2fb_temp_15 = CPtr(Double Ptr, @(arg1->estimatedCost))
        c2fb_temp_16 = Cast(Double, Cast(c2fb_c_int, 5ULL))
        (*c2fb_temp_15) = c2fb_temp_16
    Else
        c2fb_temp_17 = CPtr(SQLITE_C_INT Ptr, @(arg1->idxNum))
        c2fb_temp_18 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_17) = Cast(SQLITE_C_INT, c2fb_temp_18)
        c2fb_temp_18 = Cast(c2fb_c_int, (*c2fb_temp_17))
        c2fb_temp_19 = CPtr(Double Ptr, @(arg1->estimatedCost))
        c2fb_temp_20 = Cast(Double, Cast(c2fb_c_int, 20000ULL))
        (*c2fb_temp_19) = c2fb_temp_20
        If (-Cast(c2fb_c_int, ((local2 >= Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_21 = CPtr(SQLITE_C_INT Ptr, @(arg1->idxNum))
            c2fb_temp_22 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_21)) + Cast(c2fb_c_int, 2ULL))))
            (*c2fb_temp_21) = Cast(SQLITE_C_INT, c2fb_temp_22)
            c2fb_temp_22 = Cast(c2fb_c_int, (*c2fb_temp_21))
            c2fb_temp_24 = CPtr(SQLITE_C_INT Ptr, @(arg1->aConstraintUsage[local2].argvIndex))
            c2fb_temp_23 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_23 + 1)))
            c2fb_temp_25 = Cast(c2fb_c_int, c2fb_temp_23)
            (*c2fb_temp_24) = Cast(SQLITE_C_INT, c2fb_temp_25)
            c2fb_temp_25 = Cast(c2fb_c_int, (*c2fb_temp_24))
            c2fb_temp_26 = CPtr(Double Ptr, @(arg1->estimatedCost))
            c2fb_temp_27 = Cast(Double, __c2fb_double_value(Cast(Double, ((*c2fb_temp_26) / Cast(Double, Cast(c2fb_c_int, 2ULL))))))
            (*c2fb_temp_26) = c2fb_temp_27
        End If
        If (-Cast(c2fb_c_int, ((local3 >= Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_28 = CPtr(SQLITE_C_INT Ptr, @(arg1->idxNum))
            c2fb_temp_29 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_28)) + Cast(c2fb_c_int, 4ULL))))
            (*c2fb_temp_28) = Cast(SQLITE_C_INT, c2fb_temp_29)
            c2fb_temp_29 = Cast(c2fb_c_int, (*c2fb_temp_28))
            c2fb_temp_31 = CPtr(SQLITE_C_INT Ptr, @(arg1->aConstraintUsage[local3].argvIndex))
            c2fb_temp_30 = local5
            local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_30 + 1)))
            c2fb_temp_32 = Cast(c2fb_c_int, c2fb_temp_30)
            (*c2fb_temp_31) = Cast(SQLITE_C_INT, c2fb_temp_32)
            c2fb_temp_32 = Cast(c2fb_c_int, (*c2fb_temp_31))
            c2fb_temp_33 = CPtr(Double Ptr, @(arg1->estimatedCost))
            c2fb_temp_34 = Cast(Double, __c2fb_double_value(Cast(Double, ((*c2fb_temp_33) / Cast(Double, Cast(c2fb_c_int, 2ULL))))))
            (*c2fb_temp_33) = c2fb_temp_34
        End If
    End If
    If (-Cast(c2fb_c_int, ((local4 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_36 = CPtr(SQLITE_C_INT Ptr, @(arg1->aConstraintUsage[local4].argvIndex))
        c2fb_temp_35 = local5
        local5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_35 + 1)))
        c2fb_temp_37 = Cast(c2fb_c_int, c2fb_temp_35)
        (*c2fb_temp_36) = Cast(SQLITE_C_INT, c2fb_temp_37)
        c2fb_temp_37 = Cast(c2fb_c_int, (*c2fb_temp_36))
        c2fb_temp_38 = CPtr(Double Ptr, @(arg1->estimatedCost))
        c2fb_temp_39 = (*c2fb_temp_38)
        (*c2fb_temp_38) = Cast(Double, Cast(Double, (c2fb_temp_39 - 1)))
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3auxOpenMethod CDecl Alias "fts3auxOpenMethod" (ByVal arg0 As SqliteVtab Ptr, ByVal arg1 As SqliteVtabCursor Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_56 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_56 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As SqliteVtabCursor Ptr Ptr
    Dim c2fb_temp_3 As SqliteVtabCursor Ptr

    ' C automatic storage declaration
    ' C unused-parameter annotation
    c2fb_temp_0 = CPtr(c2fb_source_record_56 Ptr, CPtr(Any Ptr, sqlite3_malloc(Cast(c2fb_size_t, SizeOf(c2fb_source_record_56)))))
    local0 = c2fb_temp_0
    If (-Cast(c2fb_c_int, (local0 = 0))) Then
        Return Cast(c2fb_c_int, 7ULL)
    End If
    c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_source_record_56))))
    c2fb_temp_2 = CPtr(SqliteVtabCursor Ptr Ptr, @((*arg1)))
    c2fb_temp_3 = CPtr(SqliteVtabCursor Ptr, local0)
    (*c2fb_temp_2) = c2fb_temp_3
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3auxCloseMethod CDecl Alias "fts3auxCloseMethod" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_47 Ptr
    Dim local1 As c2fb_source_record_56 Ptr

    local0 = (CPtr(c2fb_source_record_54 Ptr, arg0->pVtab))->pFts3Tab
    local1 = CPtr(c2fb_source_record_56 Ptr, arg0)
    c2fb_external_sqlite3Fts3SegmentsClose(local0)
    c2fb_external_sqlite3Fts3SegReaderFinish(CPtr(c2fb_source_record_53 Ptr, @(local1->csr)))
    sqlite3_free(CPtr(Any Ptr, local1->filter.zTerm))
    sqlite3_free(CPtr(Any Ptr, local1->zStop))
    sqlite3_free(CPtr(Any Ptr, local1->aStat))
    sqlite3_free(CPtr(Any Ptr, local1))
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3auxGrowStatArray CDecl Alias "fts3auxGrowStatArray" (ByVal arg0 As c2fb_source_record_56 Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_55 Ptr
    Dim c2fb_temp_0 As c2fb_source_record_55 Ptr
    Dim c2fb_temp_1 As Any Ptr
    Dim c2fb_temp_2 As c2fb_source_record_55 Ptr Ptr
    Dim c2fb_temp_3 As c2fb_source_record_55 Ptr
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int

    If (-Cast(c2fb_c_int, ((arg1 > arg0->nStat)))) Then
        ' C automatic storage declaration
        c2fb_temp_0 = CPtr(c2fb_source_record_55 Ptr, CPtr(Any Ptr, sqlite3_realloc64(CPtr(Any Ptr, arg0->aStat), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_55))) * Cast(c2fb_uint64, arg1))))))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_1 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_55 Ptr, @(local0[arg0->nStat]))), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_55))) * Cast(c2fb_uint64, (Cast(c2fb_c_int, (arg1 - arg0->nStat))))))))
        c2fb_temp_2 = CPtr(c2fb_source_record_55 Ptr Ptr, @(arg0->aStat))
        c2fb_temp_3 = local0
        (*c2fb_temp_2) = c2fb_temp_3
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(arg0->nStat))
        c2fb_temp_5 = Cast(c2fb_c_int, arg1)
        (*c2fb_temp_4) = c2fb_temp_5
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3auxNextMethod CDecl Alias "fts3auxNextMethod" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_56 Ptr
    Dim local1 As c2fb_source_record_47 Ptr
    Dim local2 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As ZString Ptr
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int Ptr
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim local10 As c2fb_int64
    Dim c2fb_temp_12 As c2fb_c_int
    Dim c2fb_temp_13 As c2fb_int64 Ptr
    Dim c2fb_temp_14 As c2fb_int64
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_int64 Ptr
    Dim c2fb_temp_18 As c2fb_int64
    Dim c2fb_temp_19 As c2fb_c_int
    Dim c2fb_temp_20 As c2fb_c_int
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_int64 Ptr
    Dim c2fb_temp_23 As c2fb_int64
    Dim c2fb_temp_24 As c2fb_int64 Ptr
    Dim c2fb_temp_25 As c2fb_int64
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_int64 Ptr
    Dim c2fb_temp_29 As c2fb_int64
    Dim c2fb_temp_30 As c2fb_c_int
    Dim c2fb_switch_value_31 As c2fb_uint64
    Dim c2fb_switch_state_32 As c2fb_c_int
    Dim c2fb_temp_33 As c2fb_c_int Ptr
    Dim c2fb_temp_34 As c2fb_c_int
    Dim c2fb_temp_35 As c2fb_c_int Ptr
    Dim c2fb_temp_36 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_56 Ptr, arg0)
    local1 = (CPtr(c2fb_source_record_54 Ptr, arg0->pVtab))->pFts3Tab
    ' C automatic storage declaration
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @(local0->iRowid))
    c2fb_temp_1 = (*c2fb_temp_0)
    (*c2fb_temp_0) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_1 + 1)))
    c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @(local0->iCol))
    c2fb_temp_3 = (*c2fb_temp_2)
    (*c2fb_temp_2) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
    While (-Cast(c2fb_c_int, ((local0->iCol < local0->nStat))))
        If (-Cast(c2fb_c_int, ((local0->aStat[local0->iCol].nDoc > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
            Return Cast(c2fb_c_int, &O0ULL)
        End If
    c2fb_flow_1:
        c2fb_temp_4 = CPtr(c2fb_c_int Ptr, @(local0->iCol))
        c2fb_temp_5 = (*c2fb_temp_4)
        (*c2fb_temp_4) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
    Wend
    c2fb_flow_0:
    c2fb_temp_6 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SegReaderStep(local1, CPtr(c2fb_source_record_53 Ptr, @(local0->csr))))
    local2 = c2fb_temp_6
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, 100ULL))))) Then
        local3 = Cast(c2fb_c_int, &O0ULL)
        local4 = local0->csr.nDoclist
        local5 = local0->csr.aDoclist
        ' C automatic storage declaration
        local7 = Cast(c2fb_c_int, &O0ULL)
        If local0->zStop Then
            local8 = IIf(((-Cast(c2fb_c_int, ((local0->nStop < local0->csr.nTerm))))), local0->nStop, local0->csr.nTerm)
            local9 = c2fb_crt_memcmp(CPtr(Const Any Ptr, local0->zStop), CPtr(Const Any Ptr, local0->csr.zTerm), local8)
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local9 < Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse (((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local9 = Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local0->csr.nTerm > local0->nStop)))) <> 0)))))) <> 0))))) Then
                c2fb_temp_7 = CPtr(c2fb_c_int Ptr, @(local0->isEof))
                c2fb_temp_8 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_7) = c2fb_temp_8
                Return Cast(c2fb_c_int, &O0ULL)
            End If
        End If
        If fts3auxGrowStatArray(local0, Cast(c2fb_c_int, 2ULL)) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, local0->aStat), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_source_record_55))) * Cast(c2fb_uint64, local0->nStat)))))
        c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local6 = c2fb_temp_10
        c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        local2 = c2fb_temp_11
        While (-Cast(c2fb_c_int, ((local3 < local4))))
            local10 = Cast(c2fb_c_int, &O0ULL)
            c2fb_temp_12 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local3 + c2fb_external_sqlite3Fts3GetVarint(CPtr(Const ZString Ptr, CPtr(Byte Ptr, @(CPtr(Byte Ptr, local5)[local3]))), CPtr(c2fb_int64 Ptr, @(local10))))))
            local3 = c2fb_temp_12
            c2fb_switch_value_31 = Cast(c2fb_uint64, local7)
            c2fb_switch_state_32 = 0
            Select Case c2fb_switch_value_31
                Case Cast(c2fb_uint64, Cast(c2fb_c_int, &O0ULL))
                    c2fb_switch_state_32 = 1
                Case Cast(c2fb_uint64, Cast(c2fb_c_int, 1ULL))
                    c2fb_switch_state_32 = 2
                Case Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL))
                    c2fb_switch_state_32 = 3
                Case Else
                    c2fb_switch_state_32 = 4
            End Select
            Do
                Select Case c2fb_switch_state_32
                Case 0
                    Exit Do
                Case 1
                    c2fb_temp_13 = CPtr(c2fb_int64 Ptr, @(local0->aStat[Cast(c2fb_c_int, &O0ULL)].nDoc))
                    c2fb_temp_14 = (*c2fb_temp_13)
                    (*c2fb_temp_13) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_14 + 1)))
                    c2fb_temp_15 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                    local7 = c2fb_temp_15
                    c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                    local6 = c2fb_temp_16
                    c2fb_switch_state_32 = 0
                Case 2
                    ' C unused-parameter annotation
                    If (-Cast(c2fb_c_int, ((local10 > Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) Then
                        c2fb_temp_17 = CPtr(c2fb_int64 Ptr, @(local0->aStat[Cast(c2fb_c_int, 1ULL)].nDoc))
                        c2fb_temp_18 = (*c2fb_temp_17)
                        (*c2fb_temp_17) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_18 + 1)))
                    End If
                    c2fb_temp_19 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                    local7 = c2fb_temp_19
                    ' C switch fallthrough annotation
                    c2fb_switch_state_32 = 3
                Case 3
                    If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                        c2fb_temp_20 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
                        local7 = c2fb_temp_20
                    Else
                        If (-Cast(c2fb_c_int, ((local10 = Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))) Then
                            c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, 3ULL))
                            local7 = c2fb_temp_21
                        Else
                            c2fb_temp_22 = CPtr(c2fb_int64 Ptr, @(local0->aStat[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))].nOcc))
                            c2fb_temp_23 = (*c2fb_temp_22)
                            (*c2fb_temp_22) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_23 + 1)))
                            c2fb_temp_24 = CPtr(c2fb_int64 Ptr, @(local0->aStat[Cast(c2fb_c_int, &O0ULL)].nOcc))
                            c2fb_temp_25 = (*c2fb_temp_24)
                            (*c2fb_temp_24) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_25 + 1)))
                        End If
                    End If
                    c2fb_switch_state_32 = 0
                Case 4
                    ' C unused-parameter annotation
                    c2fb_temp_26 = Cast(c2fb_c_int, Cast(c2fb_c_int, local10))
                    local6 = c2fb_temp_26
                    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local6 < Cast(c2fb_c_int, 1ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local6 > Cast(c2fb_c_int, 32767ULL))))) <> 0))))) Then
                        c2fb_temp_27 = Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 11ULL) Or (Cast(c2fb_c_int, (Cast(c2fb_c_int, 1ULL) Shl Cast(c2fb_c_int, 8ULL))))))))
                        local2 = c2fb_temp_27
                        Goto c2fb_flow_4
                    End If
                    If fts3auxGrowStatArray(local0, Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 2ULL)))) Then
                        Return Cast(c2fb_c_int, 7ULL)
                    End If
                    c2fb_temp_28 = CPtr(c2fb_int64 Ptr, @(local0->aStat[Cast(c2fb_c_int, (local6 + Cast(c2fb_c_int, 1ULL)))].nDoc))
                    c2fb_temp_29 = (*c2fb_temp_28)
                    (*c2fb_temp_28) = Cast(c2fb_int64, Cast(c2fb_int64, (c2fb_temp_29 + 1)))
                    c2fb_temp_30 = Cast(c2fb_c_int, Cast(c2fb_c_int, 2ULL))
                    local7 = c2fb_temp_30
                    c2fb_switch_state_32 = 0
                End Select
            Loop
            c2fb_flow_4:
        c2fb_flow_3:
        Wend
        c2fb_flow_2:
        c2fb_temp_33 = CPtr(c2fb_c_int Ptr, @(local0->iCol))
        c2fb_temp_34 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
        (*c2fb_temp_33) = c2fb_temp_34
    Else
        c2fb_temp_35 = CPtr(c2fb_c_int Ptr, @(local0->isEof))
        c2fb_temp_36 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_35) = c2fb_temp_36
    End If
    Return local2
End Function
Private Function fts3auxFilterMethod CDecl Alias "fts3auxFilterMethod" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As SqliteVdbeMem Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_56 Ptr
    Dim local1 As c2fb_source_record_47 Ptr
    Dim local2 As c2fb_c_int
    Dim local3 As c2fb_c_int
    Dim local4 As c2fb_c_int
    Dim local5 As c2fb_c_int
    Dim local6 As c2fb_c_int
    Dim local7 As c2fb_c_int
    Dim local8 As c2fb_c_int
    Dim local9 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As Any Ptr
    Dim c2fb_temp_10 As c2fb_c_int Ptr
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_c_int Ptr
    Dim c2fb_temp_13 As c2fb_c_int
    Dim local10 As Const UByte Ptr
    Dim c2fb_temp_14 As Const ZString Ptr Ptr
    Dim c2fb_temp_15 As Const ZString Ptr
    Dim c2fb_temp_16 As c2fb_c_int Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As ZString Ptr Ptr
    Dim c2fb_temp_19 As ZString Ptr
    Dim c2fb_temp_20 As c2fb_c_int Ptr
    Dim c2fb_temp_21 As c2fb_c_int
    Dim c2fb_temp_22 As c2fb_c_int
    Dim c2fb_temp_23 As c2fb_c_int
    Dim c2fb_temp_24 As c2fb_c_int Ptr
    Dim c2fb_temp_25 As c2fb_c_int
    Dim c2fb_temp_26 As c2fb_c_int
    Dim c2fb_temp_27 As c2fb_c_int
    Dim c2fb_temp_28 As c2fb_c_int

    local0 = CPtr(c2fb_source_record_56 Ptr, arg0)
    local1 = (CPtr(c2fb_source_record_54 Ptr, arg0->pVtab))->pFts3Tab
    ' C automatic storage declaration
    local3 = Cast(c2fb_c_int, &O0ULL)
    local4 = Cast(c2fb_c_int, &O0ULL)
    local5 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local6 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local7 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local8 = Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))
    local9 = Cast(c2fb_c_int, &O0ULL)
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((arg1 = Cast(c2fb_c_int, 1ULL))))) Then
        c2fb_temp_0 = local9
        local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_0 + 1)))
        c2fb_temp_1 = Cast(c2fb_c_int, c2fb_temp_0)
        local5 = c2fb_temp_1
    Else
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
        local3 = c2fb_temp_2
        If Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, 2ULL))) Then
            c2fb_temp_3 = local9
            local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 + 1)))
            c2fb_temp_4 = Cast(c2fb_c_int, c2fb_temp_3)
            local6 = c2fb_temp_4
        End If
        If Cast(c2fb_c_int, (arg1 And Cast(c2fb_c_int, 4ULL))) Then
            c2fb_temp_5 = local9
            local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_5 + 1)))
            c2fb_temp_6 = Cast(c2fb_c_int, c2fb_temp_5)
            local7 = c2fb_temp_6
        End If
    End If
    If (-Cast(c2fb_c_int, ((local9 < arg3)))) Then
        c2fb_temp_7 = local9
        local9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_7 + 1)))
        c2fb_temp_8 = Cast(c2fb_c_int, c2fb_temp_7)
        local8 = c2fb_temp_8
    End If
    ' empty C statement
    c2fb_external_sqlite3Fts3SegReaderFinish(CPtr(c2fb_source_record_53 Ptr, @(local0->csr)))
    sqlite3_free(CPtr(Any Ptr, local0->filter.zTerm))
    sqlite3_free(CPtr(Any Ptr, local0->aStat))
    sqlite3_free(CPtr(Any Ptr, local0->zStop))
    c2fb_temp_9 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, CPtr(c2fb_source_record_53 Ptr, @(local0->csr))), Cast(c2fb_c_int, &O0ULL), (CPtr(UByte Ptr, (CPtr(UByte Ptr, CPtr(c2fb_source_record_56 Ptr, @(local0[Cast(c2fb_c_int, 1ULL)]))))) - CPtr(UByte Ptr, CPtr(UByte Ptr, CPtr(c2fb_source_record_53 Ptr, @(local0->csr)))))))
    c2fb_temp_10 = CPtr(c2fb_c_int Ptr, @(local0->filter.flags))
    c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, &H00000001ULL) Or Cast(c2fb_c_int, &H00000002ULL))))
    (*c2fb_temp_10) = c2fb_temp_11
    If local3 Then
        c2fb_temp_12 = CPtr(c2fb_c_int Ptr, @(local0->filter.flags))
        c2fb_temp_13 = Cast(c2fb_c_int, Cast(c2fb_c_int, ((*c2fb_temp_12) Or Cast(c2fb_c_int, &H00000010ULL))))
        (*c2fb_temp_12) = c2fb_temp_13
    End If
    If (-Cast(c2fb_c_int, (((((-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local5 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) OrElse ((-Cast(c2fb_c_int, ((local6 >= Cast(c2fb_c_int, &O0ULL))))) <> 0)))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type_(arg4[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        local10 = CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text___(arg4[Cast(c2fb_c_int, &O0ULL)]))
        ' C unused-parameter annotation
        If local10 Then
            c2fb_temp_14 = CPtr(Const ZString Ptr Ptr, @(local0->filter.zTerm))
            c2fb_temp_15 = CPtr(Const ZString Ptr, CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s"), local10)))
            (*c2fb_temp_14) = c2fb_temp_15
            If (-Cast(c2fb_c_int, ((local0->filter.zTerm = Cast(c2fb_c_int, &O0ULL))))) Then
                Return Cast(c2fb_c_int, 7ULL)
            End If
            c2fb_temp_16 = CPtr(c2fb_c_int Ptr, @(local0->filter.nTerm))
            c2fb_temp_17 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(local0->filter.zTerm)))
            (*c2fb_temp_16) = c2fb_temp_17
        End If
    End If
    If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local7 >= Cast(c2fb_c_int, &O0ULL))))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_external_sqlite3_value_type_(arg4[Cast(c2fb_c_int, &O0ULL)]) = Cast(c2fb_c_int, 3ULL))))) <> 0))))) Then
        c2fb_temp_18 = CPtr(ZString Ptr Ptr, @(local0->zStop))
        c2fb_temp_19 = CPtr(ZString Ptr, sqlite3_mprintf(StrPtr(!"%s"), CPtr(Const UByte Ptr, c2fb_external_sqlite3_value_text___(arg4[local7]))))
        (*c2fb_temp_18) = c2fb_temp_19
        If (-Cast(c2fb_c_int, ((local0->zStop = Cast(c2fb_c_int, &O0ULL))))) Then
            Return Cast(c2fb_c_int, 7ULL)
        End If
        c2fb_temp_20 = CPtr(c2fb_c_int Ptr, @(local0->nStop))
        c2fb_temp_21 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(CPtr(Const ZString Ptr, local0->zStop))))
        (*c2fb_temp_20) = c2fb_temp_21
    End If
    If (-Cast(c2fb_c_int, ((local8 >= Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_22 = Cast(c2fb_c_int, c2fb_external_sqlite3_value_int___(arg4[local8]))
        local4 = c2fb_temp_22
        If (-Cast(c2fb_c_int, ((local4 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_23 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
            local4 = c2fb_temp_23
        End If
    End If
    c2fb_temp_24 = CPtr(c2fb_c_int Ptr, @(local0->iLangid))
    c2fb_temp_25 = Cast(c2fb_c_int, local4)
    (*c2fb_temp_24) = c2fb_temp_25
    c2fb_temp_26 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SegReaderCursor(local1, local4, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 2ULL))), local0->filter.zTerm, local0->filter.nTerm, Cast(c2fb_c_int, &O0ULL), local3, CPtr(c2fb_source_record_53 Ptr, @(local0->csr))))
    local2 = c2fb_temp_26
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_27 = Cast(c2fb_c_int, c2fb_external_sqlite3Fts3SegReaderStart(local1, CPtr(c2fb_source_record_53 Ptr, @(local0->csr)), CPtr(c2fb_source_record_52 Ptr, @(local0->filter))))
        local2 = c2fb_temp_27
    End If
    If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_28 = Cast(c2fb_c_int, fts3auxNextMethod(arg0))
        local2 = c2fb_temp_28
    End If
    Return local2
End Function
Private Function fts3auxEofMethod CDecl Alias "fts3auxEofMethod" (ByVal arg0 As SqliteVtabCursor Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_56 Ptr

    local0 = CPtr(c2fb_source_record_56 Ptr, arg0)
    Return local0->isEof
End Function
Private Function fts3auxColumnMethod CDecl Alias "fts3auxColumnMethod" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As SqliteResultContext Ptr, ByVal arg2 As c2fb_c_int) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_56 Ptr

    local0 = CPtr(c2fb_source_record_56 Ptr, arg0)
    ' C unused-parameter annotation
    Select Case arg2
        Case Cast(c2fb_c_int, &O0ULL)
            c2fb_external_sqlite3_result_text___(arg1, CPtr(Const ZString Ptr, local0->csr.zTerm), local0->csr.nTerm, (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL)))))))
        Case Cast(c2fb_c_int, 1ULL)
            If local0->iCol Then
                c2fb_external_sqlite3_result_int___(arg1, Cast(c2fb_c_int, (local0->iCol - Cast(c2fb_c_int, 1ULL))))
            Else
                c2fb_external_sqlite3_result_text___(arg1, StrPtr(!"*"), Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))), (CPtr(c2fb_sqlite3_destructor_type, Cast(Integer, Cast(c2fb_c_int, &O0ULL)))))
            End If
        Case Cast(c2fb_c_int, 2ULL)
            c2fb_external_sqlite3_result_int64__(arg1, local0->aStat[local0->iCol].nDoc)
        Case Cast(c2fb_c_int, 3ULL)
            c2fb_external_sqlite3_result_int64__(arg1, local0->aStat[local0->iCol].nOcc)
        Case Else
            ' C unused-parameter annotation
            c2fb_external_sqlite3_result_int___(arg1, local0->iLangid)
    End Select
    c2fb_flow_0:
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Private Function fts3auxRowidMethod CDecl Alias "fts3auxRowidMethod" (ByVal arg0 As SqliteVtabCursor Ptr, ByVal arg1 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts3/fts3_aux.c
    Dim local0 As c2fb_source_record_56 Ptr
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64

    local0 = CPtr(c2fb_source_record_56 Ptr, arg0)
    c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg1)))
    c2fb_temp_1 = Cast(c2fb_int64, local0->iRowid)
    (*c2fb_temp_0) = c2fb_temp_1
    Return Cast(c2fb_c_int, &O0ULL)
End Function
' C2FB emits the callbacks; the static sqlite3_module table is initialized here.

Private Dim Shared As Const SqliteModuleCallbacks fts3auxModule = _
    Type<SqliteModuleCallbacks>( _
        0, _
        CPtr(Any Ptr, ProcPtr(fts3auxConnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxConnectMethod)), _
        Cast(SqliteModuleBestIndexProc, ProcPtr(fts3auxBestIndexMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxDisconnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxDisconnectMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxOpenMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxCloseMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxFilterMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxNextMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxEofMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxColumnMethod)), _
        CPtr(Any Ptr, ProcPtr(fts3auxRowidMethod)), _
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 _
    )

Function sqlite3Fts3InitAux CDecl Alias "sqlite3Fts3InitAux" ( _
    ByVal pDatabase As Any Ptr _
) As c2fb_c_int
    If pDatabase = 0 Then Return SQLITE_MISUSE
    Return sqlite3_create_module( _
        pDatabase, StrPtr("fts4aux"), CPtr(Const Any Ptr, @fts3auxModule), 0)
End Function

#endif

/' end of sqlite3_bulk_fts3_aux.bas '/
