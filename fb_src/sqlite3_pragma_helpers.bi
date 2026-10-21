/'
    Project: SQLite FreeBASIC port

    File: sqlite3_pragma_helpers.bi

    Purpose:

        Declare local helpers shared by PRAGMA code-generation modules.

    Responsibilities:

        - Expose result-column setup for generated PRAGMA statements.
        - Expose one-row formatting for user-defined functions.
        - Declare debug-only PRAGMA lookup and name-list helpers.

    This file intentionally does NOT contain:

        - PRAGMA dispatch or virtual-table callback behavior.
'/

#ifndef SQLITE3_FB_PRAGMA_HELPERS_BI
#define SQLITE3_FB_PRAGMA_HELPERS_BI

#include once "sqlite3_pragma_types.bi"
#include once "sqlite3_vdbe_core.bi"

Declare Sub setPragmaResultColumnNames CDecl Alias "setPragmaResultColumnNames" ( _
    ByVal pVdbe As SqliteVdbe Ptr, _
    ByVal pPragma As Const SqlitePragmaName Ptr _
)

Declare Sub sqlite3PragmaFunctionListUserLine CDecl Alias "sqlite3PragmaFunctionListUserLine" ( _
    ByVal pVdbe As SqliteVdbe Ptr, _
    ByVal pFunction As Const SqliteFuncDef Ptr, _
    ByVal showInternFuncs As SQLITE_C_INT _
)

Declare Function sqlite3DebugPragmaNameCount CDecl Alias "sqlite3DebugPragmaNameCount" () As SQLITE_C_INT
Declare Function sqlite3DebugPragmaNameAt CDecl Alias "sqlite3DebugPragmaNameAt" ( _
    ByVal index As SQLITE_C_INT _
) As Const SqlitePragmaName Ptr
Declare Function sqlite3DebugPragmaLocate CDecl Alias "sqlite3DebugPragmaLocate" ( _
    ByVal zName As Const ZString Ptr _
) As Const SqlitePragmaName Ptr
Declare Sub sqlite3PragmaEmitNameList CDecl Alias "sqlite3PragmaEmitNameList" ( _
    ByVal pVdbe As SqliteVdbe Ptr _
)

#ifdef SQLITE_DEBUG
Declare Sub sqlite3PragmaStats CDecl Alias "sqlite3PragmaStats" ( _
    ByVal pParse As SqliteParseContext Ptr, _
    ByVal iDb As SQLITE_C_INT, _
    ByVal pDb As SqliteDbSlot Ptr, _
    ByVal pVdbe As SqliteVdbe Ptr _
)
#endif

#endif

/' end of sqlite3_pragma_helpers.bi '/
