/'
    Project: SQLite FreeBASIC port

    File: sqlite3_fts3_tokenizer_types.bi

    Purpose:

        Define the tokenizer callback ABI from ext/fts3/fts3_tokenizer.h.

    Responsibilities:

        - Preserve the tokenizer module, tokenizer, and cursor layouts.
        - Declare the built-in simple, Porter, and Unicode module accessors.

    This file intentionally does NOT contain:

        - Tokenizer registration or token iteration logic.
        - Test-only tokenizer interfaces.
'/

#ifndef SQLITE3_FTS3_TOKENIZER_TYPES_BI
#define SQLITE3_FTS3_TOKENIZER_TYPES_BI

#include once "sqlite3_types.bi"

Type Fts3Tokenizer
    pModule As Any Ptr
End Type

Type Fts3TokenizerCursor
    pTokenizer As Fts3Tokenizer Ptr
End Type

Type Fts3TokenizerCreateProc As Function CDecl ( _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal arguments As Const ZString Ptr Ptr, _
    ByVal ppTokenizer As Fts3Tokenizer Ptr Ptr _
) As SQLITE_C_INT

Type Fts3TokenizerDestroyProc As Function CDecl ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr _
) As SQLITE_C_INT

Type Fts3TokenizerOpenProc As Function CDecl ( _
    ByVal pTokenizer As Fts3Tokenizer Ptr, _
    ByVal pInput As Const ZString Ptr, _
    ByVal byteCount As SQLITE_C_INT, _
    ByVal ppCursor As Fts3TokenizerCursor Ptr Ptr _
) As SQLITE_C_INT

Type Fts3TokenizerCloseProc As Function CDecl ( _
    ByVal pCursor As Fts3TokenizerCursor Ptr _
) As SQLITE_C_INT

Type Fts3TokenizerNextProc As Function CDecl ( _
    ByVal pCursor As Fts3TokenizerCursor Ptr, _
    ByVal ppToken As Const ZString Ptr Ptr, _
    ByVal pTokenBytes As SQLITE_C_INT Ptr, _
    ByVal pStartOffset As SQLITE_C_INT Ptr, _
    ByVal pEndOffset As SQLITE_C_INT Ptr, _
    ByVal pPosition As SQLITE_C_INT Ptr _
) As SQLITE_C_INT

Type Fts3TokenizerLanguageidProc As Function CDecl ( _
    ByVal pCursor As Fts3TokenizerCursor Ptr, _
    ByVal languageId As SQLITE_C_INT _
) As SQLITE_C_INT

Type Fts3TokenizerModule
    iVersion As SQLITE_C_INT
    xCreate As Fts3TokenizerCreateProc
    xDestroy As Fts3TokenizerDestroyProc
    xOpen As Fts3TokenizerOpenProc
    xClose As Fts3TokenizerCloseProc
    xNext As Fts3TokenizerNextProc
    xLanguageid As Fts3TokenizerLanguageidProc
End Type

#if Not defined(SQLITE_OMIT_VIRTUALTABLE)
Declare Sub sqlite3Fts3SimpleTokenizerModule CDecl Alias "sqlite3Fts3SimpleTokenizerModule" ( _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr _
)
Declare Sub sqlite3Fts3PorterTokenizerModule CDecl Alias "sqlite3Fts3PorterTokenizerModule" ( _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr _
)
#if Not defined(SQLITE_DISABLE_FTS3_UNICODE)
Declare Sub sqlite3Fts3UnicodeTokenizer CDecl Alias "sqlite3Fts3UnicodeTokenizer" ( _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr _
)
#endif
#if defined(SQLITE_ENABLE_ICU)
Declare Sub sqlite3Fts3IcuTokenizerModule CDecl Alias "sqlite3Fts3IcuTokenizerModule" ( _
    ByVal ppModule As Const Fts3TokenizerModule Ptr Ptr _
)
#endif
#endif

#endif

/' end of sqlite3_fts3_tokenizer_types.bi '/
