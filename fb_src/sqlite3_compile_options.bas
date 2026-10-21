/'
    Project: SQLite FreeBASIC port

    File: sqlite3_compile_options.bas

    Purpose:

        Report the compile-time options used by this FreeBASIC library.

    Responsibilities:

        - Preserve a stable, alphabetically ordered compile-option list.
        - Match option names case-insensitively with the optional SQLITE_ prefix.
        - Report active threading, temporary-store, and enabled-feature profiles.
        - Include the configured default page size in the option string.

    This file intentionally does NOT contain:

        - Runtime PRAGMA values or options selected through sqlite3_config().
        - Compiler-specific C options that do not apply to the FreeBASIC build.
'/ 

#lang "fb"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"

Declare Function sqlite3Strlen30 CDecl Alias "sqlite3Strlen30" ( _
    ByVal z As Const ZString Ptr _
) As SQLITE_C_INT

#ifndef SQLITE_THREADSAFE
#define SQLITE_THREADSAFE 1
#endif
#ifndef SQLITE_TEMP_STORE
#define SQLITE_TEMP_STORE 1
#endif
#ifndef SQLITE_DEFAULT_PAGE_SIZE
#define SQLITE_DEFAULT_PAGE_SIZE 4096
#endif

#define SQLITE3_FB_STRINGIFY_INNER(value) #value
#define SQLITE3_FB_STRINGIFY(value) SQLITE3_FB_STRINGIFY_INNER(value)
#define SQLITE3_FB_DEFAULT_PAGE_SIZE_OPTION _
    "DEFAULT_PAGE_SIZE=" & SQLITE3_FB_STRINGIFY(SQLITE_DEFAULT_PAGE_SIZE)

#ifdef SQLITE_DEBUG
#define SQLITE_COMPILEOPTION_DEBUG_COUNT 1
#define SQLITE_COMPILEOPTION_DEBUG_EXTRA @sqlite3CompileOptionNames(53),
#else
#define SQLITE_COMPILEOPTION_DEBUG_COUNT 0
#define SQLITE_COMPILEOPTION_DEBUG_EXTRA
#endif
#ifdef SQLITE_TEST
#define SQLITE_COMPILEOPTION_TEST_COUNT 1
#define SQLITE_COMPILEOPTION_TEST_EXTRA @sqlite3CompileOptionNames(61),
#else
#define SQLITE_COMPILEOPTION_TEST_COUNT 0
#define SQLITE_COMPILEOPTION_TEST_EXTRA
#endif
#ifdef SQLITE_ENABLE_BYTECODE_VTAB
#define SQLITE_COMPILEOPTION_BYTECODE_COUNT 1
#define SQLITE_COMPILEOPTION_BYTECODE_EXTRA @sqlite3CompileOptionNames(54),
#else
#define SQLITE_COMPILEOPTION_BYTECODE_COUNT 0
#define SQLITE_COMPILEOPTION_BYTECODE_EXTRA
#endif
#ifdef SQLITE_ENABLE_URI_00_ERROR
#define SQLITE_COMPILEOPTION_URI_COUNT 1
#define SQLITE_COMPILEOPTION_URI_EXTRA @sqlite3CompileOptionNames(43),
#else
#define SQLITE_COMPILEOPTION_URI_COUNT 0
#define SQLITE_COMPILEOPTION_URI_EXTRA
#endif
#ifdef SQLITE_ENABLE_COLUMN_METADATA
#define SQLITE_COMPILEOPTION_COLUMN_METADATA_COUNT 1
#define SQLITE_COMPILEOPTION_COLUMN_METADATA_EXTRA @sqlite3CompileOptionNames(44),
#else
#define SQLITE_COMPILEOPTION_COLUMN_METADATA_COUNT 0
#define SQLITE_COMPILEOPTION_COLUMN_METADATA_EXTRA
#endif
#ifdef SQLITE_ENABLE_CARRAY
#define SQLITE_COMPILEOPTION_CARRAY_COUNT 1
#define SQLITE_COMPILEOPTION_CARRAY_EXTRA @sqlite3CompileOptionNames(50),
#else
#define SQLITE_COMPILEOPTION_CARRAY_COUNT 0
#define SQLITE_COMPILEOPTION_CARRAY_EXTRA
#endif
#ifdef SQLITE_ENABLE_DBPAGE_VTAB
#define SQLITE_COMPILEOPTION_DBPAGE_COUNT 1
#define SQLITE_COMPILEOPTION_DBPAGE_EXTRA @sqlite3CompileOptionNames(55),
#else
#define SQLITE_COMPILEOPTION_DBPAGE_COUNT 0
#define SQLITE_COMPILEOPTION_DBPAGE_EXTRA
#endif
#ifdef SQLITE_ENABLE_DBSTAT_VTAB
#define SQLITE_COMPILEOPTION_DBSTAT_COUNT 1
#define SQLITE_COMPILEOPTION_DBSTAT_EXTRA @sqlite3CompileOptionNames(52),
#else
#define SQLITE_COMPILEOPTION_DBSTAT_COUNT 0
#define SQLITE_COMPILEOPTION_DBSTAT_EXTRA
#endif
#ifdef SQLITE_ENABLE_FTS3
#define SQLITE_COMPILEOPTION_FTS3_COUNT 1
#define SQLITE_COMPILEOPTION_FTS3_EXTRA @sqlite3CompileOptionNames(63),
#else
#define SQLITE_COMPILEOPTION_FTS3_COUNT 0
#define SQLITE_COMPILEOPTION_FTS3_EXTRA
#endif
#ifdef SQLITE_ENABLE_FTS4
#define SQLITE_COMPILEOPTION_FTS4_COUNT 1
#define SQLITE_COMPILEOPTION_FTS4_EXTRA @sqlite3CompileOptionNames(65),
#else
#define SQLITE_COMPILEOPTION_FTS4_COUNT 0
#define SQLITE_COMPILEOPTION_FTS4_EXTRA
#endif
#ifdef SQLITE_ENABLE_FTS5
#define SQLITE_COMPILEOPTION_FTS5_COUNT 1
#define SQLITE_COMPILEOPTION_FTS5_EXTRA @sqlite3CompileOptionNames(66),
#else
#define SQLITE_COMPILEOPTION_FTS5_COUNT 0
#define SQLITE_COMPILEOPTION_FTS5_EXTRA
#endif
#ifdef SQLITE_ENABLE_GEOPOLY
#define SQLITE_COMPILEOPTION_GEOPOLY_COUNT 1
#define SQLITE_COMPILEOPTION_GEOPOLY_EXTRA @sqlite3CompileOptionNames(67),
#else
#define SQLITE_COMPILEOPTION_GEOPOLY_COUNT 0
#define SQLITE_COMPILEOPTION_GEOPOLY_EXTRA
#endif
#ifdef SQLITE_ENABLE_ICU
#define SQLITE_COMPILEOPTION_ICU_COUNT 1
#define SQLITE_COMPILEOPTION_ICU_EXTRA @sqlite3CompileOptionNames(68),
#else
#define SQLITE_COMPILEOPTION_ICU_COUNT 0
#define SQLITE_COMPILEOPTION_ICU_EXTRA
#endif
#ifdef SQLITE_ENABLE_SESSION
#define SQLITE_COMPILEOPTION_SESSION_COUNT 1
#define SQLITE_COMPILEOPTION_SESSION_EXTRA @sqlite3CompileOptionNames(69),
#else
#define SQLITE_COMPILEOPTION_SESSION_COUNT 0
#define SQLITE_COMPILEOPTION_SESSION_EXTRA
#endif
#ifdef SQLITE_NO_SYNC
#define SQLITE_COMPILEOPTION_NO_SYNC_COUNT 1
#define SQLITE_COMPILEOPTION_NO_SYNC_EXTRA @sqlite3CompileOptionNames(70),
#else
#define SQLITE_COMPILEOPTION_NO_SYNC_COUNT 0
#define SQLITE_COMPILEOPTION_NO_SYNC_EXTRA
#endif
#ifdef SQLITE_ENABLE_STMTVTAB
#define SQLITE_COMPILEOPTION_STMTVTAB_COUNT 1
#define SQLITE_COMPILEOPTION_STMTVTAB_EXTRA @sqlite3CompileOptionNames(71),
#else
#define SQLITE_COMPILEOPTION_STMTVTAB_COUNT 0
#define SQLITE_COMPILEOPTION_STMTVTAB_EXTRA
#endif
#ifdef SQLITE_STRICT_SUBTYPE
#define SQLITE_COMPILEOPTION_STRICT_SUBTYPE_COUNT 1
#define SQLITE_COMPILEOPTION_STRICT_SUBTYPE_EXTRA @sqlite3CompileOptionNames(72),
#else
#define SQLITE_COMPILEOPTION_STRICT_SUBTYPE_COUNT 0
#define SQLITE_COMPILEOPTION_STRICT_SUBTYPE_EXTRA
#endif
#ifdef SQLITE_ENABLE_EXPLAIN_COMMENTS
#define SQLITE_COMPILEOPTION_EXPLAIN_COUNT 1
#define SQLITE_COMPILEOPTION_EXPLAIN_EXTRA @sqlite3CompileOptionNames(56),
#else
#define SQLITE_COMPILEOPTION_EXPLAIN_COUNT 0
#define SQLITE_COMPILEOPTION_EXPLAIN_EXTRA
#endif
#ifdef SQLITE_ENABLE_MATH_FUNCTIONS
#define SQLITE_COMPILEOPTION_MATH_COUNT 1
#define SQLITE_COMPILEOPTION_MATH_EXTRA @sqlite3CompileOptionNames(57),
#else
#define SQLITE_COMPILEOPTION_MATH_COUNT 0
#define SQLITE_COMPILEOPTION_MATH_EXTRA
#endif
#ifdef SQLITE_ENABLE_MEMSYS5
#define SQLITE_COMPILEOPTION_MEMSYS5_COUNT 1
#define SQLITE_COMPILEOPTION_MEMSYS5_EXTRA @sqlite3CompileOptionNames(58),
#else
#define SQLITE_COMPILEOPTION_MEMSYS5_COUNT 0
#define SQLITE_COMPILEOPTION_MEMSYS5_EXTRA
#endif
#ifdef SQLITE_ENABLE_NORMALIZE
#define SQLITE_COMPILEOPTION_NORMALIZE_COUNT 1
#define SQLITE_COMPILEOPTION_NORMALIZE_EXTRA @sqlite3CompileOptionNames(45),
#else
#define SQLITE_COMPILEOPTION_NORMALIZE_COUNT 0
#define SQLITE_COMPILEOPTION_NORMALIZE_EXTRA
#endif
#ifdef SQLITE_ENABLE_PERCENTILE
#define SQLITE_COMPILEOPTION_PERCENTILE_COUNT 1
#define SQLITE_COMPILEOPTION_PERCENTILE_EXTRA @sqlite3CompileOptionNames(59),
#else
#define SQLITE_COMPILEOPTION_PERCENTILE_COUNT 0
#define SQLITE_COMPILEOPTION_PERCENTILE_EXTRA
#endif
#ifdef SQLITE_ENABLE_RTREE
#define SQLITE_COMPILEOPTION_RTREE_COUNT 1
#define SQLITE_COMPILEOPTION_RTREE_EXTRA @sqlite3CompileOptionNames(62),
#else
#define SQLITE_COMPILEOPTION_RTREE_COUNT 0
#define SQLITE_COMPILEOPTION_RTREE_EXTRA
#endif
#ifdef SQLITE_ENABLE_PREUPDATE_HOOK
#define SQLITE_COMPILEOPTION_PREUPDATE_COUNT 1
#define SQLITE_COMPILEOPTION_PREUPDATE_EXTRA @sqlite3CompileOptionNames(46),
#else
#define SQLITE_COMPILEOPTION_PREUPDATE_COUNT 0
#define SQLITE_COMPILEOPTION_PREUPDATE_EXTRA
#endif
#ifdef SQLITE_ENABLE_STAT4
#define SQLITE_COMPILEOPTION_STAT4_COUNT 1
#define SQLITE_COMPILEOPTION_STAT4_EXTRA @sqlite3CompileOptionNames(51),
#else
#define SQLITE_COMPILEOPTION_STAT4_COUNT 0
#define SQLITE_COMPILEOPTION_STAT4_EXTRA
#endif
#ifdef SQLITE_ENABLE_SNAPSHOT
#define SQLITE_COMPILEOPTION_SNAPSHOT_COUNT 1
#define SQLITE_COMPILEOPTION_SNAPSHOT_EXTRA @sqlite3CompileOptionNames(47),
#else
#define SQLITE_COMPILEOPTION_SNAPSHOT_COUNT 0
#define SQLITE_COMPILEOPTION_SNAPSHOT_EXTRA
#endif
#ifdef SQLITE_ENABLE_STMT_SCANSTATUS
#define SQLITE_COMPILEOPTION_SCANSTATUS_COUNT 1
#define SQLITE_COMPILEOPTION_SCANSTATUS_EXTRA @sqlite3CompileOptionNames(48),
#else
#define SQLITE_COMPILEOPTION_SCANSTATUS_COUNT 0
#define SQLITE_COMPILEOPTION_SCANSTATUS_EXTRA
#endif
#ifdef SQLITE_ENABLE_UNLOCK_NOTIFY
#define SQLITE_COMPILEOPTION_UNLOCK_NOTIFY_COUNT 1
#define SQLITE_COMPILEOPTION_UNLOCK_NOTIFY_EXTRA @sqlite3CompileOptionNames(49),
#else
#define SQLITE_COMPILEOPTION_UNLOCK_NOTIFY_COUNT 0
#define SQLITE_COMPILEOPTION_UNLOCK_NOTIFY_EXTRA
#endif
#ifdef SQLITE_ENABLE_UPDATE_DELETE_LIMIT
#define SQLITE_COMPILEOPTION_UPDATE_DELETE_LIMIT_COUNT 1
#define SQLITE_COMPILEOPTION_UPDATE_DELETE_LIMIT_EXTRA @sqlite3CompileOptionNames(64),
#else
#define SQLITE_COMPILEOPTION_UPDATE_DELETE_LIMIT_COUNT 0
#define SQLITE_COMPILEOPTION_UPDATE_DELETE_LIMIT_EXTRA
#endif
#ifdef SQLITE_ENABLE_WHERETRACE
#define SQLITE_COMPILEOPTION_WHERETRACE_COUNT 1
#define SQLITE_COMPILEOPTION_WHERETRACE_EXTRA @sqlite3CompileOptionNames(60),
#else
#define SQLITE_COMPILEOPTION_WHERETRACE_COUNT 0
#define SQLITE_COMPILEOPTION_WHERETRACE_EXTRA
#endif
#define SQLITE_COMPILEOPTION_COUNT (37 + SQLITE_COMPILEOPTION_URI_COUNT + _
    SQLITE_COMPILEOPTION_DEBUG_COUNT + _
    SQLITE_COMPILEOPTION_TEST_COUNT + _
    SQLITE_COMPILEOPTION_BYTECODE_COUNT + _
    SQLITE_COMPILEOPTION_CARRAY_COUNT + _
    SQLITE_COMPILEOPTION_COLUMN_METADATA_COUNT + _
    SQLITE_COMPILEOPTION_DBPAGE_COUNT + _
    SQLITE_COMPILEOPTION_DBSTAT_COUNT + _
    SQLITE_COMPILEOPTION_FTS3_COUNT + _
    SQLITE_COMPILEOPTION_FTS4_COUNT + _
    SQLITE_COMPILEOPTION_FTS5_COUNT + _
    SQLITE_COMPILEOPTION_GEOPOLY_COUNT + _
    SQLITE_COMPILEOPTION_ICU_COUNT + _
    SQLITE_COMPILEOPTION_EXPLAIN_COUNT + _
    SQLITE_COMPILEOPTION_MATH_COUNT + _
    SQLITE_COMPILEOPTION_MEMSYS5_COUNT + _
    SQLITE_COMPILEOPTION_NORMALIZE_COUNT + _
    SQLITE_COMPILEOPTION_PERCENTILE_COUNT + _
    SQLITE_COMPILEOPTION_RTREE_COUNT + _
    SQLITE_COMPILEOPTION_PREUPDATE_COUNT + _
    SQLITE_COMPILEOPTION_STAT4_COUNT + _
    SQLITE_COMPILEOPTION_SNAPSHOT_COUNT + _
    SQLITE_COMPILEOPTION_SCANSTATUS_COUNT + _
    SQLITE_COMPILEOPTION_SESSION_COUNT + _
    SQLITE_COMPILEOPTION_STMTVTAB_COUNT + _
    SQLITE_COMPILEOPTION_STRICT_SUBTYPE_COUNT + _
    SQLITE_COMPILEOPTION_UNLOCK_NOTIFY_COUNT + _
    SQLITE_COMPILEOPTION_UPDATE_DELETE_LIMIT_COUNT + _
    SQLITE_COMPILEOPTION_NO_SYNC_COUNT + _
    SQLITE_COMPILEOPTION_WHERETRACE_COUNT)

' Keep the text separate from the pointer table so every returned name is stable.
Dim Shared As Const ZString * 40 sqlite3CompileOptionNames(0 To 72) = _
    { _
        "COMPILER=FreeBASIC", _
        "DEFAULT_AUTOVACUUM", _
        "DEFAULT_CACHE_SIZE=-2000", _
        "DEFAULT_FILE_FORMAT=4", _
        "DEFAULT_JOURNAL_SIZE_LIMIT=-1", _
        "DEFAULT_MMAP_SIZE=0", _
        SQLITE3_FB_DEFAULT_PAGE_SIZE_OPTION, _
        "DEFAULT_PCACHE_INITSZ=20", _
        "DEFAULT_RECURSIVE_TRIGGERS", _
        "DEFAULT_SECTOR_SIZE=4096", _
        "DEFAULT_SYNCHRONOUS=2", _
        "DEFAULT_WAL_AUTOCHECKPOINT=1000", _
        "DEFAULT_WAL_SYNCHRONOUS=2", _
        "DEFAULT_WORKER_THREADS=0", _
        "DIRECT_OVERFLOW_READ", _
        "MALLOC_SOFT_LIMIT=1024", _
        "MAX_ATTACHED=10", _
        "MAX_COLUMN=2000", _
        "MAX_COMPOUND_SELECT=500", _
        "MAX_DEFAULT_PAGE_SIZE=8192", _
        "MAX_EXPR_DEPTH=1000", _
        "MAX_FUNCTION_ARG=1000", _
        "MAX_LENGTH=1000000000", _
        "MAX_LIKE_PATTERN_LENGTH=50000", _
        "MAX_MMAP_SIZE=0x7fff0000", _
        "MAX_PAGE_COUNT=0xfffffffe", _
        "MAX_PAGE_SIZE=65536", _
        "MAX_SCHEMA=10000000", _
        "MAX_SQL_LENGTH=1000000000", _
        "MAX_TRIGGER_DEPTH=1000", _
        "MAX_VARIABLE_NUMBER=32766", _
        "MAX_VDBE_OP=250000000", _
        "MAX_WORKER_THREADS=8", _
        "MUTEX_NOOP", _
        "MUTEX_PTHREADS", _
        "SYSTEM_MALLOC", _
        "TEMP_STORE=0", _
        "TEMP_STORE=1", _
        "TEMP_STORE=2", _
        "TEMP_STORE=3", _
        "THREADSAFE=0", _
        "THREADSAFE=1", _
        "THREADSAFE=2", _
        "ENABLE_URI_00_ERROR", _
        "ENABLE_COLUMN_METADATA", _
        "ENABLE_NORMALIZE", _
        "ENABLE_PREUPDATE_HOOK", _
        "ENABLE_SNAPSHOT", _
        "ENABLE_STMT_SCANSTATUS", _
        "ENABLE_UNLOCK_NOTIFY", _
        "ENABLE_CARRAY", _
        "ENABLE_STAT4", _
        "ENABLE_DBSTAT_VTAB", _
        "DEBUG", _
        "ENABLE_BYTECODE_VTAB", _
        "ENABLE_DBPAGE_VTAB", _
        "ENABLE_EXPLAIN_COMMENTS", _
        "ENABLE_MATH_FUNCTIONS", _
        "ENABLE_MEMSYS5", _
        "ENABLE_PERCENTILE", _
        "ENABLE_WHERETRACE", _
        "TEST", _
        "ENABLE_RTREE", _
        "ENABLE_FTS3", _
        "ENABLE_UPDATE_DELETE_LIMIT", _
        "ENABLE_FTS4", _
        "ENABLE_FTS5", _
        "ENABLE_GEOPOLY", _
        "ENABLE_ICU", _
        "ENABLE_SESSION", _
        "NO_SYNC", _
        "ENABLE_STMTVTAB", _
        "STRICT_SUBTYPE" _
    }

#if SQLITE_THREADSAFE = 0
#define SQLITE_COMPILEOPTION_MUTEX @sqlite3CompileOptionNames(33)
#define SQLITE_COMPILEOPTION_THREADSAFE @sqlite3CompileOptionNames(40)
#elseif SQLITE_THREADSAFE = 2
#define SQLITE_COMPILEOPTION_MUTEX @sqlite3CompileOptionNames(34)
#define SQLITE_COMPILEOPTION_THREADSAFE @sqlite3CompileOptionNames(42)
#else
#define SQLITE_COMPILEOPTION_MUTEX @sqlite3CompileOptionNames(34)
#define SQLITE_COMPILEOPTION_THREADSAFE @sqlite3CompileOptionNames(41)
#endif

#if SQLITE_TEMP_STORE = 0
#define SQLITE_COMPILEOPTION_TEMP_STORE @sqlite3CompileOptionNames(36)
#elseif SQLITE_TEMP_STORE = 2
#define SQLITE_COMPILEOPTION_TEMP_STORE @sqlite3CompileOptionNames(38)
#elseif SQLITE_TEMP_STORE = 3
#define SQLITE_COMPILEOPTION_TEMP_STORE @sqlite3CompileOptionNames(39)
#else
#define SQLITE_COMPILEOPTION_TEMP_STORE @sqlite3CompileOptionNames(37)
#endif

#ifndef SQLITE_OMIT_COMPILEOPTION_DIAGS
Dim Shared As Const ZString Ptr sqlite3CompileOptionPointers(0 To SQLITE_COMPILEOPTION_COUNT - 1) = _
    { _
        @sqlite3CompileOptionNames(0), _
        SQLITE_COMPILEOPTION_DEBUG_EXTRA _
        @sqlite3CompileOptionNames(1), _
        @sqlite3CompileOptionNames(2), @sqlite3CompileOptionNames(3), _
        @sqlite3CompileOptionNames(4), @sqlite3CompileOptionNames(5), _
        @sqlite3CompileOptionNames(6), @sqlite3CompileOptionNames(7), _
        @sqlite3CompileOptionNames(8), @sqlite3CompileOptionNames(9), _
        @sqlite3CompileOptionNames(10), @sqlite3CompileOptionNames(11), _
        @sqlite3CompileOptionNames(12), @sqlite3CompileOptionNames(13), _
        @sqlite3CompileOptionNames(14), _
        SQLITE_COMPILEOPTION_BYTECODE_EXTRA _
        SQLITE_COMPILEOPTION_CARRAY_EXTRA _
        SQLITE_COMPILEOPTION_COLUMN_METADATA_EXTRA _
        SQLITE_COMPILEOPTION_DBPAGE_EXTRA _
        SQLITE_COMPILEOPTION_DBSTAT_EXTRA _
        SQLITE_COMPILEOPTION_EXPLAIN_EXTRA _
        SQLITE_COMPILEOPTION_FTS3_EXTRA _
        SQLITE_COMPILEOPTION_FTS4_EXTRA _
        SQLITE_COMPILEOPTION_FTS5_EXTRA _
        SQLITE_COMPILEOPTION_GEOPOLY_EXTRA _
        SQLITE_COMPILEOPTION_ICU_EXTRA _
        SQLITE_COMPILEOPTION_MATH_EXTRA _
        SQLITE_COMPILEOPTION_MEMSYS5_EXTRA _
        SQLITE_COMPILEOPTION_NORMALIZE_EXTRA _
        SQLITE_COMPILEOPTION_PERCENTILE_EXTRA _
        SQLITE_COMPILEOPTION_PREUPDATE_EXTRA _
        SQLITE_COMPILEOPTION_RTREE_EXTRA _
        SQLITE_COMPILEOPTION_SESSION_EXTRA _
        SQLITE_COMPILEOPTION_SNAPSHOT_EXTRA _
        SQLITE_COMPILEOPTION_STAT4_EXTRA _
        SQLITE_COMPILEOPTION_SCANSTATUS_EXTRA _
        SQLITE_COMPILEOPTION_STMTVTAB_EXTRA _
        SQLITE_COMPILEOPTION_UNLOCK_NOTIFY_EXTRA _
        SQLITE_COMPILEOPTION_UPDATE_DELETE_LIMIT_EXTRA _
        SQLITE_COMPILEOPTION_URI_EXTRA _
        SQLITE_COMPILEOPTION_WHERETRACE_EXTRA _
        @sqlite3CompileOptionNames(15), @sqlite3CompileOptionNames(16), _
        @sqlite3CompileOptionNames(17), _
        @sqlite3CompileOptionNames(18), @sqlite3CompileOptionNames(19), _
        @sqlite3CompileOptionNames(20), @sqlite3CompileOptionNames(21), _
        @sqlite3CompileOptionNames(22), @sqlite3CompileOptionNames(23), _
        @sqlite3CompileOptionNames(24), @sqlite3CompileOptionNames(25), _
        @sqlite3CompileOptionNames(26), @sqlite3CompileOptionNames(27), _
        @sqlite3CompileOptionNames(28), @sqlite3CompileOptionNames(29), _
        @sqlite3CompileOptionNames(30), @sqlite3CompileOptionNames(31), _
        @sqlite3CompileOptionNames(32), SQLITE_COMPILEOPTION_MUTEX, _
        SQLITE_COMPILEOPTION_NO_SYNC_EXTRA _
        SQLITE_COMPILEOPTION_STRICT_SUBTYPE_EXTRA _
        @sqlite3CompileOptionNames(35), SQLITE_COMPILEOPTION_TEMP_STORE, _
        SQLITE_COMPILEOPTION_TEST_EXTRA _
        SQLITE_COMPILEOPTION_THREADSAFE _
    }

Function sqlite3CompileOptions CDecl Alias "sqlite3CompileOptions" ( _
    ByVal pOptionCount As SQLITE_C_INT Ptr _
) As Const ZString Ptr Ptr Export
    If pOptionCount = 0 Then Return 0
    pOptionCount[0] = SQLITE_COMPILEOPTION_COUNT
    Return @sqlite3CompileOptionPointers(0)
End Function

Private Function sqlite3CompileOptionFold(ByVal value As UByte) As UByte
    If value >= Asc("A") AndAlso value <= Asc("Z") Then Return value + 32
    Return value
End Function

Private Function sqlite3CompileOptionPrefixEquals( _
    ByVal zLeft As Const UByte Ptr, _
    ByVal zRight As Const UByte Ptr, _
    ByVal nByte As SQLITE_C_INT _
) As SQLITE_C_INT
    For iByte As SQLITE_C_INT = 0 To nByte - 1
        If sqlite3CompileOptionFold(zLeft[iByte]) <> _
           sqlite3CompileOptionFold(zRight[iByte]) Then Return 0
    Next
    Return 1
End Function

Private Function sqlite3CompileOptionIsIdentifier(ByVal value As UByte) As SQLITE_C_INT
    If value >= Asc("A") AndAlso value <= Asc("Z") Then Return 1
    If value >= Asc("a") AndAlso value <= Asc("z") Then Return 1
    If value >= Asc("0") AndAlso value <= Asc("9") Then Return 1
    If value = Asc("_") Then Return 1
    Return 0
End Function

Function sqlite3_compileoption_used CDecl Alias "sqlite3_compileoption_used" ( _
    ByVal zOptionName As Const ZString Ptr _
) As SQLITE_C_INT Export
    If zOptionName = 0 Then Return 0

    Dim zQuery As Const UByte Ptr = CPtr(Const UByte Ptr, zOptionName)
    If sqlite3CompileOptionPrefixEquals(zQuery, CPtr(Const UByte Ptr, StrPtr("SQLITE_")), 7) <> 0 Then _
        zQuery += 7

    Dim nameLength As SQLITE_C_INT = sqlite3Strlen30( _
        CPtr(Const ZString Ptr, zQuery))

    Dim optionCount As SQLITE_C_INT = 0
    Dim pOptions As Const ZString Ptr Ptr = sqlite3CompileOptions(@optionCount)
    For iOption As SQLITE_C_INT = 0 To optionCount - 1
        Dim zOption As Const UByte Ptr = CPtr(Const UByte Ptr, pOptions[iOption])
        If sqlite3CompileOptionPrefixEquals(zQuery, zOption, nameLength) <> 0 AndAlso _
           sqlite3CompileOptionIsIdentifier(zOption[nameLength]) = 0 Then Return 1
    Next
    Return 0
End Function

Function sqlite3_compileoption_get CDecl Alias "sqlite3_compileoption_get" ( _
    ByVal optionIndex As SQLITE_C_INT _
) As Const ZString Ptr Export
    Dim optionCount As SQLITE_C_INT = 0
    Dim pOptions As Const ZString Ptr Ptr = sqlite3CompileOptions(@optionCount)
    If optionIndex < 0 OrElse optionIndex >= optionCount Then Return 0
    Return pOptions[optionIndex]
End Function
#endif

/' end of sqlite3_compile_options.bas '/
