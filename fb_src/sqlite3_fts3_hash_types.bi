/'
** 2001 September 22
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

    File: sqlite3_fts3_hash_types.bi

    Purpose:

        Define the FTS3 hash table layout and its internal C ABI.

    Responsibilities:

        - Preserve the field order and widths from ext/fts3/fts3_hash.h.
        - Declare the routines implemented by sqlite3_fts3_hash.bas.

    This file intentionally does NOT contain:

        - Hashing, allocation, lookup, or mutation logic.
        - FTS3 virtual-table or tokenizer declarations.
'/

#ifndef SQLITE3_FTS3_HASH_TYPES_BI
#define SQLITE3_FTS3_HASH_TYPES_BI

#include once "sqlite3_types.bi"

Type Fts3HashElem
    next As Fts3HashElem Ptr
    prev As Fts3HashElem Ptr
    data As Any Ptr
    pKey As Any Ptr
    nKey As SQLITE_C_INT
End Type

Type Fts3HashBucket
    count As SQLITE_C_INT
    chain As Fts3HashElem Ptr
End Type

Type Fts3Hash
    keyClass As Byte
    copyKey As Byte
    count As SQLITE_C_INT
    first As Fts3HashElem Ptr
    htsize As SQLITE_C_INT
    ht As Fts3HashBucket Ptr
End Type

Const FTS3_HASH_STRING As SQLITE_C_INT = 1
Const FTS3_HASH_BINARY As SQLITE_C_INT = 2

#if Not defined(SQLITE_OMIT_VIRTUALTABLE)
Declare Sub sqlite3Fts3HashInit CDecl Alias "sqlite3Fts3HashInit" ( _
    ByVal pNew As Fts3Hash Ptr, _
    ByVal keyClass As Byte, _
    ByVal copyKey As Byte _
)
Declare Sub sqlite3Fts3HashClear CDecl Alias "sqlite3Fts3HashClear" ( _
    ByVal pHash As Fts3Hash Ptr _
)
Declare Function sqlite3Fts3HashFindElem CDecl Alias "sqlite3Fts3HashFindElem" ( _
    ByVal pHash As Const Fts3Hash Ptr, _
    ByVal pKey As Const Any Ptr, _
    ByVal nKey As SQLITE_C_INT _
) As Fts3HashElem Ptr
Declare Function sqlite3Fts3HashFind CDecl Alias "sqlite3Fts3HashFind" ( _
    ByVal pHash As Const Fts3Hash Ptr, _
    ByVal pKey As Const Any Ptr, _
    ByVal nKey As SQLITE_C_INT _
) As Any Ptr
Declare Function sqlite3Fts3HashInsert CDecl Alias "sqlite3Fts3HashInsert" ( _
    ByVal pHash As Fts3Hash Ptr, _
    ByVal pKey As Const Any Ptr, _
    ByVal nKey As SQLITE_C_INT, _
    ByVal pData As Any Ptr _
) As Any Ptr
#endif

#endif

/' end of sqlite3_fts3_hash_types.bi '/
