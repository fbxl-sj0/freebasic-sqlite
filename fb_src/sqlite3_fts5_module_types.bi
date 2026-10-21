/'
    Project: SQLite FreeBASIC port
    ---------------------------------

    File: sqlite3_fts5_module_types.bi

    Purpose:

        Describe the public sqlite3_module callback table used by FTS5.

    Responsibilities:

        - Preserve the iVersion and callback-pointer order from sqlite3.h.
        - Provide a shared record layout for FTS5 module registrations.

    This file intentionally does NOT contain:

        - FTS5 callback implementations or registration logic.
'/
#ifdef SQLITE_ENABLE_FTS5
Type c2fb_Fts5SqliteModule
    iVersion As Long
    xCreate As Any Ptr
    xConnect As Any Ptr
    xBestIndex As Any Ptr
    xDisconnect As Any Ptr
    xDestroy As Any Ptr
    xOpen As Any Ptr
    xClose As Any Ptr
    xFilter As Any Ptr
    xNext As Any Ptr
    xEof As Any Ptr
    xColumn As Any Ptr
    xRowid As Any Ptr
    xUpdate As Any Ptr
    xBegin As Any Ptr
    xSync As Any Ptr
    xCommit As Any Ptr
    xRollback As Any Ptr
    xFindFunction As Any Ptr
    xRename As Any Ptr
    xSavepoint As Any Ptr
    xRelease As Any Ptr
    xRollbackTo As Any Ptr
    xShadowName As Any Ptr
    xIntegrity As Any Ptr
End Type
#endif
/' end of sqlite3_fts5_module_types.bi '/
