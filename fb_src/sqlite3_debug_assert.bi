/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_debug_assert.bi

    Purpose:

        Declare the centralized debug assertion failure handler.

    Responsibilities:

        - Expose the debug-only assertion failure and check callbacks.

    This file intentionally does NOT contain:

        - Release-build assertion policy or test-runner logic.
'/

#ifndef SQLITE3_FB_DEBUG_ASSERT_BI
#define SQLITE3_FB_DEBUG_ASSERT_BI

#include once "sqlite3_types.bi"

#ifdef SQLITE_DEBUG
Declare Sub sqlite3DebugAssert CDecl Alias "sqlite3DebugAssert" ( _
    ByVal zExpression As Const ZString Ptr _
)
Declare Sub sqlite3DebugAssertCheck CDecl Alias "sqlite3DebugAssertCheck" ( _
    ByVal bCondition As SQLITE_C_INT, _
    ByVal zExpression As Const ZString Ptr _
)
#endif

#endif

/' end of sqlite3_debug_assert.bi '/
