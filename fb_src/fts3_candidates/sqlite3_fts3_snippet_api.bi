/'
    Project: SQLite FreeBASIC port

    File: fts3_candidates/sqlite3_fts3_snippet_api.bi

    Purpose:

        Declare the SQLite and FTS3 APIs used by the translated snippet code.

    Responsibilities:

        - Reuse the reviewed FTS3 core API declarations.
        - Declare the column type and bounded formatting calls used by offsets().

    This file intentionally does NOT contain:

        - Snippet, offsets, or matchinfo implementations.
        - FTS3 module registration or test support.
'/ 

#ifndef SQLITE3_FTS3_SNIPPET_API_BI
#define SQLITE3_FTS3_SNIPPET_API_BI

#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_fts3_core_api.bi"

Declare Function sqlite3_column_type CDecl Alias "sqlite3_column_type" ( _
    ByVal pStatement As Any Ptr, _
    ByVal columnIndex As SQLITE_C_INT _
) As SQLITE_C_INT

Declare Function sqlite3_column_text CDecl Alias "sqlite3_column_text" ( _
    ByVal pStatement As Any Ptr, _
    ByVal columnIndex As SQLITE_C_INT _
) As Const UByte Ptr

Declare Sub sqlite3_result_blob CDecl Alias "sqlite3_result_blob" ( _
    ByVal pContext As Any Ptr, _
    ByVal pBlob As Const Any Ptr, _
    ByVal byteCount As SQLITE_C_INT, _
    ByVal xDestroy As Any Ptr _
)

Declare Function sqlite3Fts3GetVarintBounded CDecl Alias "sqlite3Fts3GetVarintBounded" ( _
    ByVal pStart As Const ZString Ptr, _
    ByVal pEnd As Const ZString Ptr, _
    ByVal pValue As sqlite3_int64 Ptr _
) As SQLITE_C_INT

Declare Function sqlite3_snprintf CDecl Alias "sqlite3_snprintf" ( _
    ByVal bufferBytes As SQLITE_C_INT, _
    ByVal pBuffer As ZString Ptr, _
    ByVal zFormat As Const ZString Ptr, _
    ... _
) As ZString Ptr

#endif

/' end of sqlite3_fts3_snippet_api.bi '/
