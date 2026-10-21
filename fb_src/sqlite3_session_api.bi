/'
    Project: SQLite FreeBASIC port

    File: sqlite3_session_api.bi

    Purpose:

        Declare the public Session and changeset API from ext/session/sqlite3session.h.

    Responsibilities:

        - Bind Session, changeset, changegroup, and rebaser C symbols.
        - Preserve SQLite C integer and callback parameter widths.

    This file intentionally does NOT contain:

        - Session implementation bodies.
        - Test support or the standalone changeset command-line utility.
'/

#ifdef SQLITE_ENABLE_SESSION
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "sqlite3_types.bi"
#ifndef SQLITE3_SESSION_API_NO_CORE_DECLARATIONS
#include once "sqlite3_api_declarations.bi"
#endif
' User-defined scalar types and by-value records must be declared before generated declarations.
' Source filters and ordered routes apply to declarations, record layouts, macros, inline functions, and library pragmas.
' Types omitted by source filters must be supplied by an earlier declaration, --fb-include, or a preserved C include mapping.

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
#ifndef __C2FB_ABI_TYPE_SQLITE3_INT64__
#define __C2FB_ABI_TYPE_SQLITE3_INT64__
Type c2fb_sqlite3_int64 As sqlite3_int64
#endif

Declare Function c2fb_sqlite3session_create CDecl Alias "sqlite3session_create" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Any Ptr Ptr) As Long
Declare Sub c2fb_sqlite3session_delete CDecl Alias "sqlite3session_delete" (ByVal arg0 As Any Ptr)
Declare Function c2fb_sqlite3session_object_config CDecl Alias "sqlite3session_object_config" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3session_enable CDecl Alias "sqlite3session_enable" (ByVal arg0 As Any Ptr, ByVal arg1 As Long) As Long
Declare Function c2fb_sqlite3session_indirect CDecl Alias "sqlite3session_indirect" (ByVal arg0 As Any Ptr, ByVal arg1 As Long) As Long
Declare Function c2fb_sqlite3session_attach CDecl Alias "sqlite3session_attach" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As Long
Declare Sub c2fb_sqlite3session_table_filter CDecl Alias "sqlite3session_table_filter" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As Long, ByVal arg2 As Any Ptr)
Declare Function c2fb_sqlite3session_changeset CDecl Alias "sqlite3session_changeset" (ByVal arg0 As Any Ptr, ByVal arg1 As Long Ptr, ByVal arg2 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3session_changeset_size CDecl Alias "sqlite3session_changeset_size" (ByVal arg0 As Any Ptr) As c2fb_sqlite3_int64
Declare Function c2fb_sqlite3session_diff CDecl Alias "sqlite3session_diff" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As Const ZString Ptr, ByVal arg3 As ZString Ptr Ptr) As Long
Declare Function c2fb_sqlite3session_patchset CDecl Alias "sqlite3session_patchset" (ByVal arg0 As Any Ptr, ByVal arg1 As Long Ptr, ByVal arg2 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3session_isempty CDecl Alias "sqlite3session_isempty" (ByVal arg0 As Any Ptr) As Long
Declare Function c2fb_sqlite3session_memory_used CDecl Alias "sqlite3session_memory_used" (ByVal arg0 As Any Ptr) As c2fb_sqlite3_int64
Declare Function c2fb_sqlite3changeset_start CDecl Alias "sqlite3changeset_start" (ByVal arg0 As Any Ptr Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3changeset_start_v2 CDecl Alias "sqlite3changeset_start_v2" (ByVal arg0 As Any Ptr Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Long) As Long
Declare Function c2fb_sqlite3changeset_next CDecl Alias "sqlite3changeset_next" (ByVal arg0 As Any Ptr) As Long
Declare Function c2fb_sqlite3changeset_op CDecl Alias "sqlite3changeset_op" (ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr Ptr, ByVal arg2 As Long Ptr, ByVal arg3 As Long Ptr, ByVal arg4 As Long Ptr) As Long
Declare Function c2fb_sqlite3changeset_pk CDecl Alias "sqlite3changeset_pk" (ByVal arg0 As Any Ptr, ByVal arg1 As UByte Ptr Ptr, ByVal arg2 As Long Ptr) As Long
Declare Function c2fb_sqlite3changeset_old CDecl Alias "sqlite3changeset_old" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3changeset_new CDecl Alias "sqlite3changeset_new" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3changeset_conflict CDecl Alias "sqlite3changeset_conflict" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3changeset_fk_conflicts CDecl Alias "sqlite3changeset_fk_conflicts" (ByVal arg0 As Any Ptr, ByVal arg1 As Long Ptr) As Long
Declare Function c2fb_sqlite3changeset_finalize CDecl Alias "sqlite3changeset_finalize" (ByVal arg0 As Any Ptr) As Long
Declare Function c2fb_sqlite3changeset_invert CDecl Alias "sqlite3changeset_invert" (ByVal arg0 As Long, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long Ptr, ByVal arg3 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3changeset_concat CDecl Alias "sqlite3changeset_concat" (ByVal arg0 As Long, ByVal arg1 As Any Ptr, ByVal arg2 As Long, ByVal arg3 As Any Ptr, ByVal arg4 As Long Ptr, ByVal arg5 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3changegroup_new CDecl Alias "sqlite3changegroup_new" (ByVal arg0 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3changegroup_schema CDecl Alias "sqlite3changegroup_schema" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Const ZString Ptr) As Long
Declare Function c2fb_sqlite3changegroup_add CDecl Alias "sqlite3changegroup_add" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3changegroup_add_change CDecl Alias "sqlite3changegroup_add_change" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr) As Long
Declare Function c2fb_sqlite3changegroup_output CDecl Alias "sqlite3changegroup_output" (ByVal arg0 As Any Ptr, ByVal arg1 As Long Ptr, ByVal arg2 As Any Ptr Ptr) As Long
Declare Sub c2fb_sqlite3changegroup_delete CDecl Alias "sqlite3changegroup_delete" (ByVal arg0 As Any Ptr)
Declare Function c2fb_sqlite3changeset_apply CDecl Alias "sqlite3changeset_apply" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As Long, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long, ByVal arg5 As Any Ptr) As Long
Declare Function c2fb_sqlite3changeset_apply_v2 CDecl Alias "sqlite3changeset_apply_v2" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As Long, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As Long Ptr, ByVal arg8 As Long) As Long
Declare Function c2fb_sqlite3changeset_apply_v3 CDecl Alias "sqlite3changeset_apply_v3" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr) As Long, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As Long Ptr, ByVal arg8 As Long) As Long
Declare Function c2fb_sqlite3rebaser_create CDecl Alias "sqlite3rebaser_create" (ByVal arg0 As Any Ptr Ptr) As Long
Declare Function c2fb_sqlite3rebaser_configure CDecl Alias "sqlite3rebaser_configure" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const Any Ptr) As Long
Declare Function c2fb_sqlite3rebaser_rebase CDecl Alias "sqlite3rebaser_rebase" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const Any Ptr, ByVal arg3 As Long Ptr, ByVal arg4 As Any Ptr Ptr) As Long
Declare Sub c2fb_sqlite3rebaser_delete CDecl Alias "sqlite3rebaser_delete" (ByVal arg0 As Any Ptr)
Declare Function c2fb_sqlite3changeset_apply_strm CDecl Alias "sqlite3changeset_apply_strm" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As Long, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long, ByVal arg5 As Any Ptr) As Long
Declare Function c2fb_sqlite3changeset_apply_v2_strm CDecl Alias "sqlite3changeset_apply_v2_strm" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const ZString Ptr) As Long, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As Long Ptr, ByVal arg8 As Long) As Long
Declare Function c2fb_sqlite3changeset_apply_v3_strm CDecl Alias "sqlite3changeset_apply_v3_strm" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr) As Long, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long, ByVal arg5 As Any Ptr, ByVal arg6 As Any Ptr Ptr, ByVal arg7 As Long Ptr, ByVal arg8 As Long) As Long
Declare Function c2fb_sqlite3changeset_concat_strm CDecl Alias "sqlite3changeset_concat_strm" (ByVal arg0 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg1 As Any Ptr, ByVal arg2 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg3 As Any Ptr, ByVal arg4 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long) As Long, ByVal arg5 As Any Ptr) As Long
Declare Function c2fb_sqlite3changeset_invert_strm CDecl Alias "sqlite3changeset_invert_strm" (ByVal arg0 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg1 As Any Ptr, ByVal arg2 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long) As Long, ByVal arg3 As Any Ptr) As Long
Declare Function c2fb_sqlite3changeset_start_strm CDecl Alias "sqlite3changeset_start_strm" (ByVal arg0 As Any Ptr Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3changeset_start_v2_strm CDecl Alias "sqlite3changeset_start_v2_strm" (ByVal arg0 As Any Ptr Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Long) As Long
Declare Function c2fb_sqlite3session_changeset_strm CDecl Alias "sqlite3session_changeset_strm" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long) As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3session_patchset_strm CDecl Alias "sqlite3session_patchset_strm" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long) As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3changegroup_add_strm CDecl Alias "sqlite3changegroup_add_strm" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3changegroup_output_strm CDecl Alias "sqlite3changegroup_output_strm" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long) As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3rebaser_rebase_strm CDecl Alias "sqlite3rebaser_rebase_strm" (ByVal arg0 As Any Ptr, ByVal arg1 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As Long Ptr) As Long, ByVal arg2 As Any Ptr, ByVal arg3 As Function CDecl(ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As Long) As Long, ByVal arg4 As Any Ptr) As Long
Declare Function c2fb_sqlite3session_config CDecl Alias "sqlite3session_config" (ByVal arg0 As Long, ByVal arg1 As Any Ptr) As Long
Declare Function c2fb_sqlite3changegroup_config CDecl Alias "sqlite3changegroup_config" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Any Ptr) As Long
Declare Function c2fb_sqlite3changegroup_change_begin CDecl Alias "sqlite3changegroup_change_begin" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Const ZString Ptr, ByVal arg3 As Long, ByVal arg4 As ZString Ptr Ptr) As Long
Declare Function c2fb_sqlite3changegroup_change_int64 CDecl Alias "sqlite3changegroup_change_int64" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As c2fb_sqlite3_int64) As Long
Declare Function c2fb_sqlite3changegroup_change_null CDecl Alias "sqlite3changegroup_change_null" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Long) As Long
Declare Function c2fb_sqlite3changegroup_change_double CDecl Alias "sqlite3changegroup_change_double" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Double) As Long
Declare Function c2fb_sqlite3changegroup_change_text CDecl Alias "sqlite3changegroup_change_text" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Const ZString Ptr, ByVal arg4 As Long) As Long
Declare Function c2fb_sqlite3changegroup_change_blob CDecl Alias "sqlite3changegroup_change_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As Long, ByVal arg3 As Const Any Ptr, ByVal arg4 As Long) As Long
Declare Function c2fb_sqlite3changegroup_change_finish CDecl Alias "sqlite3changegroup_change_finish" (ByVal arg0 As Any Ptr, ByVal arg1 As Long, ByVal arg2 As ZString Ptr Ptr) As Long
Const c2fb_SQLITE_ENABLE_PREUPDATE_HOOK = 1
Const c2fb_SQLITE_CHANGESET_NOTFOUND = 2
Const c2fb_SQLITE_SESSION_OBJCONFIG_SIZE = 1
Const c2fb_SQLITE_CHANGESET_DATA = 1
Const c2fb_SQLITE_CHANGESET_CONFLICT = 3
Const c2fb_SQLITE_SESSION_CONFIG_STRMSIZE = 1
Const c2fb_SQLITE_CHANGESET_REPLACE = 1
Const c2fb___SQLITESESSION_H_ = 1
Const c2fb_SQLITE_CHANGESET_OMIT = 0
Const c2fb_SQLITE_SESSION_OBJCONFIG_ROWID = 2
Const c2fb_SQLITE_CHANGESETAPPLY_NOUPDATELOOP = &H0010
Const c2fb_SQLITE_CHANGESET_FOREIGN_KEY = 5
Const c2fb_SQLITE_ENABLE_SESSION = 1
Const c2fb_SQLITE_CHANGESETAPPLY_NOSAVEPOINT = &H0001
Const c2fb_SQLITE_CHANGESETSTART_INVERT = &H0002
Const c2fb_SQLITE_CHANGESET_ABORT = 2
Const c2fb_SQLITE_CHANGESETAPPLY_IGNORENOOP = &H0004
Const c2fb_SQLITE_CHANGESET_CONSTRAINT = 4
Const c2fb_SQLITE_CHANGEGROUP_CONFIG_PATCHSET = 1
Const c2fb_SQLITE_CHANGESETAPPLY_FKNOACTION = &H0008
Const c2fb_SQLITE_CHANGESETAPPLY_INVERT = &H0002

' c2fb source patterns:
' c2fb preserved C include mappings:
' c2fb preserved include matched: sqlite3.h -> sqlite3_api_declarations.bi
#endif

/' end of sqlite3_session_api.bi '/
