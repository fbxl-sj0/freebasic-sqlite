/'
    Project: SQLite FreeBASIC port

    File: sqlite3_builtin_extensions.bas

    Purpose:

        Supply built-in initializer callbacks for default and optional profiles.

    Responsibilities:

        - Preserve main.c's fault-simulation initializer callback.
        - Initialize FTS3/4, FTS5, ICU, R-tree, DBPAGE, DBSTAT, and bytecode-vtab modules when enabled.
        - Provide stable callback-array storage and its active entry count.

    This file intentionally does NOT contain:

        - The implementations of FTS or other unported extensions.
        - SQLite test cases or test-runner code.
'/

#lang "fb"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_db_types.bi"
#include once "sqlite3_fault.bi"

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
Declare Function sqlite3Fts3Init CDecl Alias "sqlite3Fts3Init" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
#endif
#ifdef SQLITE_ENABLE_FTS5
Declare Function sqlite3Fts5Init CDecl Alias "sqlite3Fts5Init" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
#endif
#if defined(SQLITE_ENABLE_ICU) OrElse defined(SQLITE_ENABLE_ICU_COLLATIONS)
Declare Function sqlite3IcuInit CDecl Alias "sqlite3IcuInit" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
#endif
#ifdef SQLITE_ENABLE_DBPAGE_VTAB
Declare Function sqlite3DbpageRegister CDecl Alias "sqlite3DbpageRegister" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
#endif
#if defined(SQLITE_ENABLE_RTREE) AndAlso Not defined(SQLITE_OMIT_VIRTUALTABLE)
Declare Function sqlite3RtreeInit CDecl Alias "sqlite3RtreeInit" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
#endif
#ifdef SQLITE_ENABLE_DBSTAT_VTAB
Declare Function sqlite3DbstatRegister CDecl Alias "sqlite3DbstatRegister" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
#endif
#ifdef SQLITE_ENABLE_BYTECODE_VTAB
Declare Function sqlite3VdbeBytecodeVtabInit CDecl Alias "sqlite3VdbeBytecodeVtabInit" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
#endif
#ifdef SQLITE_ENABLE_STMTVTAB
Declare Function sqlite3StmtVtabInit CDecl Alias "sqlite3StmtVtabInit" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
#endif

Private Function sqlite3TestExtInit CDecl Alias "sqlite3TestExtInit" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
    ' Fault-injection site 500 exercises initialization of built-in extensions.
    Return sqlite3FaultSim(500)
End Function

Private Function sqlite3BuiltinExtensionInit CDecl Alias "sqlite3BuiltinExtensionInit" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
    Dim rc As SQLITE_C_INT = SQLITE_OK

#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
    rc = sqlite3Fts3Init(pDatabase)
#endif
#ifdef SQLITE_ENABLE_FTS5
    If rc = SQLITE_OK Then rc = sqlite3Fts5Init(pDatabase)
#endif
#if defined(SQLITE_ENABLE_ICU) OrElse defined(SQLITE_ENABLE_ICU_COLLATIONS)
    If rc = SQLITE_OK Then rc = sqlite3IcuInit(pDatabase)
#endif
#if defined(SQLITE_ENABLE_RTREE) AndAlso Not defined(SQLITE_OMIT_VIRTUALTABLE)
    If rc = SQLITE_OK Then rc = sqlite3RtreeInit(pDatabase)
#endif
#ifdef SQLITE_ENABLE_DBPAGE_VTAB
    If rc = SQLITE_OK Then rc = sqlite3DbpageRegister(pDatabase)
#endif
#ifdef SQLITE_ENABLE_DBSTAT_VTAB
    If rc = SQLITE_OK Then rc = sqlite3DbstatRegister(pDatabase)
#endif
    If rc = SQLITE_OK Then rc = sqlite3TestExtInit(pDatabase)
#ifdef SQLITE_ENABLE_STMTVTAB
    If rc = SQLITE_OK Then rc = sqlite3StmtVtabInit(pDatabase)
#endif
#ifdef SQLITE_ENABLE_BYTECODE_VTAB
    If rc = SQLITE_OK Then rc = sqlite3VdbeBytecodeVtabInit(pDatabase)
#endif

    Return rc
End Function

Private Dim Shared sqlite3BuiltinExtensionEntries(0 To 0) As _
    SqliteBuiltinExtensionInitProc = {ProcPtr(sqlite3BuiltinExtensionInit)}

Function c2fbBuiltinExtensionArray CDecl Alias "c2fbBuiltinExtensionArray" () _
    As SqliteBuiltinExtensionInitProc Ptr
    Return @sqlite3BuiltinExtensionEntries(0)
End Function

Function c2fbBuiltinExtensionCount CDecl Alias "c2fbBuiltinExtensionCount" () _
    As SQLITE_SIZE_T
    Return 1
End Function

/' end of sqlite3_builtin_extensions.bas '/
