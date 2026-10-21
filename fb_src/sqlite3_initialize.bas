/'
    Project: SQLite FreeBASIC port

    File: sqlite3_initialize.bas

    Purpose:

        Initialize and shut down the process-wide SQLite subsystems.

    Responsibilities:

        - Serialize concurrent and recursive initialization calls.
        - Register built-in SQL functions before page-cache and VFS setup.
        - Initialize the mutex, page-cache, host VFS, and memory VFS layers.
        - Tear down initialized VFS, page-cache, allocator, and mutex state.
        - Keep internal sqlite3Initialize() work separate from the public wrapper.
        - Initialize and reset the default allocator's heap-limit state.
        - Make repeated and recursive initialization calls safe.
        - Retain the deprecated global-recovery and thread-cleanup entry points.

    This file intentionally does NOT contain:

        - sqlite3_config() processing or custom allocator selection.
        - Database connection creation or SQL execution.
'/ 

#lang "fb"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"
#include once "sqlite3_mutex.bi"
#include once "sqlite3_pcache.bi"
#include once "sqlite3_vfs.bi"
#include once "sqlite3_memdb.bi"
#include once "sqlite3_process_globals.bi"

Declare Function sqlite3MallocInit CDecl Alias "sqlite3MallocInit" () As SQLITE_C_INT
Declare Sub sqlite3MallocEnd CDecl Alias "sqlite3MallocEnd" ()
Declare Function sqlite3MemConfigIsInitialized CDecl Alias "sqlite3MemConfigIsInitialized" () As SQLITE_C_INT
Declare Function sqlite3ConfigCoreMutexEnabled CDecl Alias "sqlite3ConfigCoreMutexEnabled" () As SQLITE_C_INT
Declare Function sqlite3ConfigApplyPageCache CDecl Alias "sqlite3ConfigApplyPageCache" () As SQLITE_C_INT
Declare Sub sqlite3BuiltinFunctionInitialize CDecl Alias "sqlite3BuiltinFunctionInitialize" ()
Declare Function sqlite3_os_end CDecl Alias "sqlite3_os_end" () As SQLITE_C_INT
Declare Sub sqlite3_reset_auto_extension CDecl Alias "sqlite3_reset_auto_extension" ()
#ifdef SQLITE3_FB_TEST_CONFIG_SYNC
Declare Sub sqlite3TestConfigSync CDecl Alias "sqlite3TestConfigSync" ()
#endif

Private Const SQLITE_INITIALIZATION_NOT_STARTED As SQLITE_C_INT = 0
Private Const SQLITE_INITIALIZATION_IN_PROGRESS As SQLITE_C_INT = 1
Private Const SQLITE_INITIALIZATION_COMPLETE As SQLITE_C_INT = 2

Private Dim Shared sqlite3InitializationState As SQLITE_C_INT
Private Dim Shared sqlite3InitializationMutex As Any Ptr
Private Dim Shared sqlite3InitializationMutexReferences As SQLITE_C_INT
Private Dim Shared sqlite3MutexSubsystemInitialized As SQLITE_C_INT

Function sqlite3ConfigIsInitialized CDecl Alias "sqlite3ConfigIsInitialized" () As SQLITE_C_INT Export
    Return CInt(sqlite3InitializationState <> SQLITE_INITIALIZATION_NOT_STARTED)
End Function

/' ------------------------------------------------------------------------- '/
/' Initialization lock '/
/' ------------------------------------------------------------------------- '/

Private Function sqlite3InitializationMutexGet() As Any Ptr
    ' SINGLETHREAD mode deliberately returns NULL from the internal allocator.
    ' The mutex API treats that as a no-op, and this mode has no concurrent
    ' callers that need the process-wide initialization lock.
    If sqlite3ConfigCoreMutexEnabled() = 0 Then Return 0
    Dim pMainMutex As Any Ptr = sqlite3MutexAlloc(SQLITE_MUTEX_STATIC_MAIN)
    If pMainMutex = 0 Then Return 0

    sqlite3_mutex_enter(pMainMutex)
    Dim pExisting As Any Ptr = sqlite3InitializationMutex
    If pExisting <> 0 Then
        sqlite3InitializationMutexReferences += 1
        sqlite3_mutex_leave(pMainMutex)
        Return pExisting
    End If
    sqlite3_mutex_leave(pMainMutex)

    ' Allocate outside the main mutex because dynamic mutex allocation uses
    ' SQLite's allocator and may itself acquire a static mutex.
    Dim pCandidate As Any Ptr = sqlite3MutexAlloc(SQLITE_MUTEX_RECURSIVE)
    If pCandidate = 0 Then Return 0

    sqlite3_mutex_enter(pMainMutex)
    If sqlite3InitializationMutex = 0 Then
        sqlite3InitializationMutex = pCandidate
        pExisting = pCandidate
        pCandidate = 0
    Else
        pExisting = sqlite3InitializationMutex
    End If
    If pExisting <> 0 Then sqlite3InitializationMutexReferences += 1
    sqlite3_mutex_leave(pMainMutex)

    If pCandidate <> 0 Then sqlite3_mutex_free(pCandidate)
    Return pExisting
End Function

Private Sub sqlite3InitializationMutexPut(ByVal pMutex As Any Ptr)
    If pMutex = 0 Then Exit Sub
    Dim pMainMutex As Any Ptr = sqlite3MutexAlloc(SQLITE_MUTEX_STATIC_MAIN)
    If pMainMutex = 0 Then Exit Sub

    Dim freeMutex As SQLITE_C_INT = 0
    sqlite3_mutex_enter(pMainMutex)
    If sqlite3InitializationMutex = pMutex AndAlso _
       sqlite3InitializationMutexReferences > 0 Then
        sqlite3InitializationMutexReferences -= 1
        If sqlite3InitializationMutexReferences = 0 Then
            sqlite3InitializationMutex = 0
            freeMutex = 1
        End If
    End If
    sqlite3_mutex_leave(pMainMutex)

    If freeMutex <> 0 Then sqlite3_mutex_free(pMutex)
End Sub

/' ------------------------------------------------------------------------- '/
/' Public initialization API '/
/' ------------------------------------------------------------------------- '/

Private Function sqlite3Initialize CDecl Alias "sqlite3Initialize" () As SQLITE_C_INT
    Dim rc As SQLITE_C_INT = sqlite3MutexInit()
    If rc <> SQLITE_OK Then Return rc
    sqlite3MutexSubsystemInitialized = 1
    rc = sqlite3MallocInit()
    If rc <> SQLITE_OK Then Return rc

    Dim pMutex As Any Ptr = sqlite3InitializationMutexGet()
    If pMutex = 0 AndAlso sqlite3ConfigCoreMutexEnabled() <> 0 Then _
        Return SQLITE_NOMEM
    sqlite3_mutex_enter(pMutex)

    If sqlite3InitializationState = SQLITE_INITIALIZATION_COMPLETE Then
        sqlite3_mutex_leave(pMutex)
        sqlite3InitializationMutexPut(pMutex)
        Return SQLITE_OK
    End If
    If sqlite3InitializationState = SQLITE_INITIALIZATION_IN_PROGRESS Then
        ' A recursive call from the initializing thread must not deadlock.
        sqlite3_mutex_leave(pMutex)
        sqlite3InitializationMutexPut(pMutex)
        Return SQLITE_OK
    End If

    sqlite3InitializationState = SQLITE_INITIALIZATION_IN_PROGRESS
    sqlite3BuiltinFunctionInitialize()
    rc = sqlite3PcacheInitialize()
    If rc = SQLITE_OK Then rc = sqlite3OsInit()
#ifndef SQLITE_OMIT_DESERIALIZE
    If rc = SQLITE_OK Then rc = sqlite3MemdbInit()
#endif
    If rc = SQLITE_OK Then rc = sqlite3ConfigApplyPageCache()

    If rc = SQLITE_OK Then
        sqlite3MemoryBarrier()
        sqlite3InitializationState = SQLITE_INITIALIZATION_COMPLETE
    Else
        sqlite3PcacheShutdown()
        sqlite3InitializationState = SQLITE_INITIALIZATION_NOT_STARTED
    End If
    sqlite3_mutex_leave(pMutex)
    sqlite3InitializationMutexPut(pMutex)
    Return rc
End Function

Function sqlite3_initialize CDecl Alias "sqlite3_initialize" () As SQLITE_C_INT Export
    ' Public allocation APIs may call initialize while a SQLite static mutex
    ' is held. Once complete, return before entering the initialization lock.
    If sqlite3InitializationState = SQLITE_INITIALIZATION_COMPLETE Then
        sqlite3MemoryBarrier()
#ifdef SQLITE3_FB_TEST_CONFIG_SYNC
        sqlite3TestConfigSync()
#endif
        Return SQLITE_OK
    End If
    Dim initializeCode As SQLITE_C_INT = sqlite3Initialize()
#ifdef SQLITE3_FB_TEST_CONFIG_SYNC
    sqlite3TestConfigSync()
#endif
    Return initializeCode
End Function

Function sqlite3_shutdown CDecl Alias "sqlite3_shutdown" () As SQLITE_C_INT Export
    If sqlite3InitializationState = SQLITE_INITIALIZATION_COMPLETE Then
        sqlite3_os_end()
        sqlite3_reset_auto_extension()
        sqlite3InitializationState = SQLITE_INITIALIZATION_NOT_STARTED
        sqlite3PcacheShutdown()
    End If
    If sqlite3MemConfigIsInitialized() <> 0 Then
        sqlite3MallocEnd()
#ifndef SQLITE_OMIT_SHUTDOWN_DIRECTORIES
        sqlite3_data_directory = 0
        sqlite3_temp_directory = 0
#endif
    End If
    If sqlite3MutexSubsystemInitialized <> 0 Then
        sqlite3MutexEnd()
        sqlite3MutexSubsystemInitialized = 0
    End If
    sqlite3MemoryBarrier()
    Return SQLITE_OK
End Function

Function sqlite3_global_recover CDecl Alias "sqlite3_global_recover" () As SQLITE_C_INT Export
    Return SQLITE_OK
End Function

Sub sqlite3_thread_cleanup CDecl Alias "sqlite3_thread_cleanup" () Export
    ' SQLite no longer uses thread-specific data; keep the compatibility hook empty.
End Sub

/' end of sqlite3_initialize.bas '/
