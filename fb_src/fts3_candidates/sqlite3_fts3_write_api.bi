/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_fts3_write_api.bi

    Purpose:

        Bind the API unique to the staged FTS3 write candidate.

    Responsibilities:

        - Reuse shared SQLite signatures from the FTS3 core API catalog.
        - Supply FTS3 write and SQLite API signatures absent from that catalog.

    This file intentionally does NOT contain:

        - FTS3 private declarations or layouts.
        - SQLite test support.
'/

#ifndef SQLITE3_FTS3_WRITE_API_BI
#define SQLITE3_FTS3_WRITE_API_BI

#include once "crt/stdarg.bi"
#include once "sqlite3_fts3_write_types.bi"
#include once "sqlite3_fts3_core_api.bi"

Declare Function sqlite3_bind_blob CDecl Alias "sqlite3_bind_blob" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const Any Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_bind_int CDecl Alias "sqlite3_bind_int" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_bind_null CDecl Alias "sqlite3_bind_null" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_bind_parameter_count CDecl Alias "sqlite3_bind_parameter_count" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_bind_text CDecl Alias "sqlite3_bind_text" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_blob_close CDecl Alias "sqlite3_blob_close" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_blob_read CDecl Alias "sqlite3_blob_read" (ByVal arg0 As Any Ptr, ByVal arg1 As Any Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As c2fb_c_int) As c2fb_c_int
Declare Function sqlite3_value_bytes CDecl Alias "sqlite3_value_bytes" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3_vtab_on_conflict CDecl Alias "sqlite3_vtab_on_conflict" (ByVal arg0 As Any Ptr) As c2fb_c_int
Declare Function sqlite3Fts3SegReaderNew CDecl Alias "sqlite3Fts3SegReaderNew" (ByVal age As c2fb_c_int, ByVal lookupOnly As c2fb_c_int, ByVal firstLeaf As c2fb_int64, ByVal lastLeaf As c2fb_int64, ByVal lastBlock As c2fb_int64, ByVal rootData As Const ZString Ptr, ByVal rootBytes As c2fb_c_int, ByVal ppReader As SqliteFts3SegReader Ptr Ptr) As c2fb_c_int
#ifdef FTS3_LOG_MERGES
Declare Sub sqlite3_log CDecl Alias "sqlite3_log" (ByVal errorCode As c2fb_c_int, ByVal zFormat As Const ZString Ptr, ...)
#endif

#endif

/' end of fts3_candidates/sqlite3_fts3_write_api.bi '/
