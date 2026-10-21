/'
** 2012-05-25
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
******************************************************************************
'/
/'
    Project: SQLite FreeBASIC port

    File: sqlite3_fts3_unicode_types.bi

    Purpose:

        Declare the Unicode classification and folding API from FTS3.

    Responsibilities:

        - Expose codepoint classification, diacritic, and case-fold helpers.
        - Preserve the C integer ABI used by the FTS3 tokenizer.

    This file intentionally does NOT contain:

        - Unicode tables or tokenizer iteration state.
        - The implementation of any declared routine.
'/

#ifndef SQLITE3_FTS3_UNICODE_TYPES_BI
#define SQLITE3_FTS3_UNICODE_TYPES_BI

#include once "sqlite3_types.bi"

#if Not defined(SQLITE_DISABLE_FTS3_UNICODE) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
Declare Function sqlite3FtsUnicodeIsalnum CDecl Alias "sqlite3FtsUnicodeIsalnum" ( _
    ByVal codepoint As SQLITE_C_INT _
) As SQLITE_C_INT
Declare Function sqlite3FtsUnicodeIsdiacritic CDecl Alias "sqlite3FtsUnicodeIsdiacritic" ( _
    ByVal codepoint As SQLITE_C_INT _
) As SQLITE_C_INT
Declare Function sqlite3FtsUnicodeFold CDecl Alias "sqlite3FtsUnicodeFold" ( _
    ByVal codepoint As SQLITE_C_INT, _
    ByVal removeDiacriticMode As SQLITE_C_INT _
) As SQLITE_C_INT
#endif

#endif

/' end of sqlite3_fts3_unicode_types.bi '/
