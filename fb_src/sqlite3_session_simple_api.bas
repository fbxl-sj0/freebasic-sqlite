/'
    Project: SQLite FreeBASIC port

    File: sqlite3_session_simple_api.bas

    Purpose:

        Implement Session state accessors from ext/session/sqlite3session.c.

    Responsibilities:

        - Enable or disable change recording and indirect-change state.
        - Report whether a Session has recorded changes or allocated memory.
        - Apply Session object configuration before tables are attached.
        - Store the per-Session table filter callback.

    This file intentionally does NOT contain:

        - Session creation, preupdate callback installation, or table capture.
        - Changeset serialization, iteration, or application.
'/

#lang "fb"
#if defined(SQLITE_ENABLE_SESSION) AndAlso _
    defined(SQLITE_ENABLE_PREUPDATE_HOOK)

#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_session_types.bi"
#include once "sqlite3_debug_assert.bi"

Declare Function sqlite3_db_mutex CDecl Alias "sqlite3_db_mutex" ( _
    ByVal pDatabase As sqlite3 Ptr _
) As Any Ptr

/' ------------------------------------------------------------------------- '/
/' Session state accessors                                                   '/
/' ------------------------------------------------------------------------- '/

Function sqlite3session_enable CDecl Alias "sqlite3session_enable" ( _
    ByVal pSession As SqliteSession Ptr, _
    ByVal enable As SQLITE_C_INT _
) As SQLITE_C_INT Export
#ifdef SQLITE_DEBUG
    ASSERT(pSession <> 0)
#endif
    If pSession = 0 Then Return SQLITE_MISUSE

    Dim pMutex As Any Ptr = sqlite3_db_mutex(pSession->db)
    sqlite3_mutex_enter(pMutex)
    If enable >= 0 Then pSession->bEnable = enable
    Dim currentState As SQLITE_C_INT = pSession->bEnable
    sqlite3_mutex_leave(pMutex)
    Return currentState
End Function

Function sqlite3session_indirect CDecl Alias "sqlite3session_indirect" ( _
    ByVal pSession As SqliteSession Ptr, _
    ByVal indirect As SQLITE_C_INT _
) As SQLITE_C_INT Export
#ifdef SQLITE_DEBUG
    ASSERT(pSession <> 0)
#endif
    If pSession = 0 Then Return SQLITE_MISUSE

    Dim pMutex As Any Ptr = sqlite3_db_mutex(pSession->db)
    sqlite3_mutex_enter(pMutex)
    If indirect >= 0 Then pSession->bIndirect = indirect
    Dim currentState As SQLITE_C_INT = pSession->bIndirect
    sqlite3_mutex_leave(pMutex)
    Return currentState
End Function

Function sqlite3session_isempty CDecl Alias "sqlite3session_isempty" ( _
    ByVal pSession As SqliteSession Ptr _
) As SQLITE_C_INT Export
#ifdef SQLITE_DEBUG
    ASSERT(pSession <> 0)
#endif
    If pSession = 0 Then Return 1

    Dim pMutex As Any Ptr = sqlite3_db_mutex(pSession->db)
    Dim pTable As SqliteSessionTable Ptr
    Dim hasChanges As SQLITE_C_INT = 0
    sqlite3_mutex_enter(pMutex)
    pTable = pSession->pTable
    While pTable <> 0 AndAlso hasChanges = 0
        If pTable->nEntry > 0 Then hasChanges = 1
        pTable = pTable->pNext
    Wend
    sqlite3_mutex_leave(pMutex)
    If hasChanges = 0 Then Return 1
    Return 0
End Function

Function sqlite3session_memory_used CDecl Alias "sqlite3session_memory_used" ( _
    ByVal pSession As SqliteSession Ptr _
) As sqlite3_int64 Export
#ifdef SQLITE_DEBUG
    ASSERT(pSession <> 0)
#endif
    If pSession = 0 Then Return 0
    Return pSession->nMalloc
End Function

Function sqlite3session_changeset_size CDecl Alias "sqlite3session_changeset_size" ( _
    ByVal pSession As SqliteSession Ptr _
) As sqlite3_int64 Export
#ifdef SQLITE_DEBUG
    ASSERT(pSession <> 0)
#endif
    If pSession = 0 Then Return 0
    Return pSession->nMaxChangesetSize
End Function

Function sqlite3session_object_config CDecl Alias "sqlite3session_object_config" ( _
    ByVal pSession As SqliteSession Ptr, _
    ByVal operation As SQLITE_C_INT, _
    ByVal pArgument As Any Ptr _
) As SQLITE_C_INT Export
    If pSession = 0 Then Return SQLITE_MISUSE

    Dim pSetting As SQLITE_C_INT Ptr
    Dim requestedState As SQLITE_C_INT
    Dim rc As SQLITE_C_INT = SQLITE_OK
    pSetting = CPtr(SQLITE_C_INT Ptr, pArgument)

    Select Case operation
    Case SQLITE_SESSION_OBJCONFIG_SIZE
        If pSetting = 0 Then Return SQLITE_MISUSE
        requestedState = *pSetting
        If requestedState >= 0 Then
            If pSession->pTable <> 0 Then
                rc = SQLITE_MISUSE
            Else
                ' The C API stores a normalized integer truth value. FreeBASIC
                ' Boolean True is -1, so convert it explicitly to 1 here.
                If requestedState <> 0 Then
                    pSession->bEnableSize = 1
                Else
                    pSession->bEnableSize = 0
                End If
            End If
        End If
        *pSetting = pSession->bEnableSize

    Case SQLITE_SESSION_OBJCONFIG_ROWID
        If pSetting = 0 Then Return SQLITE_MISUSE
        requestedState = *pSetting
        If requestedState >= 0 Then
            If pSession->pTable <> 0 Then
                rc = SQLITE_MISUSE
            Else
                If requestedState <> 0 Then
                    pSession->bImplicitPK = 1
                Else
                    pSession->bImplicitPK = 0
                End If
            End If
        End If
        *pSetting = pSession->bImplicitPK

    Case Else
        rc = SQLITE_MISUSE
    End Select

    Return rc
End Function

Sub sqlite3session_table_filter CDecl Alias "sqlite3session_table_filter" ( _
    ByVal pSession As SqliteSession Ptr, _
    ByVal tableFilter As Any Ptr, _
    ByVal pContext As Any Ptr _
) Export
#ifdef SQLITE_DEBUG
    ASSERT(pSession <> 0)
#endif
    If pSession = 0 Then Return

    pSession->bAutoAttach = 1
    pSession->pFilterCtx = pContext
    pSession->xTableFilter = tableFilter
End Sub

#endif

/' end of sqlite3_session_simple_api.bas '/
