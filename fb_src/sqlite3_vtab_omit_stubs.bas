/'
    Project: SQLite FreeBASIC port

    File: sqlite3_vtab_omit_stubs.bas

    Purpose:

        Keep non-virtual-table engine paths linkable when SQLite is built
        with SQLITE_OMIT_VIRTUALTABLE.

    Responsibilities:

        - Provide neutral results for shared code paths that call vtab helpers.
        - Return no module or table when virtual-table registration is absent.
        - Keep transaction hooks successful when no vtab can participate.

    This file intentionally does NOT contain:

        - Virtual-table execution or API behavior.
        - Any functions in profiles where virtual tables are enabled.
'/

#lang "fb"
#include once "sqlite3_types.bi"
#include once "sqlite3_constants.bi"

#ifdef SQLITE_OMIT_VIRTUALTABLE
Function sqlite3JsonVtabRegister CDecl Alias "sqlite3JsonVtabRegister" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal zName As Const ZString Ptr _
) As Any Ptr
    Return 0
End Function

Function sqlite3PragmaVtabRegister CDecl Alias "sqlite3PragmaVtabRegister" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal zName As Const ZString Ptr _
) As Any Ptr
    Return 0
End Function

Function sqlite3GetVTable CDecl Alias "sqlite3GetVTable" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal pTable As Any Ptr _
) As Any Ptr
    Return 0
End Function

Sub sqlite3VtabDisconnect CDecl Alias "sqlite3VtabDisconnect" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal pTable As Any Ptr _
)
End Sub

Function sqlite3VtabSync CDecl Alias "sqlite3VtabSync" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal pVdbe As Any Ptr _
) As SQLITE_C_INT
    Return SQLITE_OK
End Function

Function sqlite3VtabRollback CDecl Alias "sqlite3VtabRollback" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
    Return SQLITE_OK
End Function

Function sqlite3VtabCommit CDecl Alias "sqlite3VtabCommit" ( _
    ByVal pDatabase As Any Ptr _
) As SQLITE_C_INT
    Return SQLITE_OK
End Function

Sub sqlite3VtabLock CDecl Alias "sqlite3VtabLock" (ByVal pVTable As Any Ptr)
End Sub

Sub sqlite3VtabUnlock CDecl Alias "sqlite3VtabUnlock" (ByVal pVTable As Any Ptr)
End Sub

Sub sqlite3VtabUnlockList CDecl Alias "sqlite3VtabUnlockList" ( _
    ByVal pDatabase As Any Ptr _
)
End Sub

Function sqlite3VtabSavepoint CDecl Alias "sqlite3VtabSavepoint" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal operation As SQLITE_C_INT, _
    ByVal savepointNumber As SQLITE_C_INT _
) As SQLITE_C_INT
    Return SQLITE_OK
End Function

Function sqlite3ShadowTableName CDecl Alias "sqlite3ShadowTableName" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal zTableName As Const ZString Ptr _
) As SQLITE_C_INT
    Return 0
End Function

Sub sqlite3VtabEponymousTableClearAll CDecl _
    Alias "sqlite3VtabEponymousTableClearAll" ( _
    ByVal pDatabase As Any Ptr _
)
End Sub

Function sqlite3VtabEponymousTableInit CDecl _
    Alias "sqlite3VtabEponymousTableInit" ( _
    ByVal pParse As Any Ptr, _
    ByVal pModule As Any Ptr _
) As SQLITE_C_INT
    Return SQLITE_ERROR
End Function

Sub sqlite3VtabMakeWritable CDecl Alias "sqlite3VtabMakeWritable" ( _
    ByVal pParse As Any Ptr, _
    ByVal pTable As Any Ptr _
)
End Sub

Function sqlite3VtabCallConnect CDecl Alias "sqlite3VtabCallConnect" ( _
    ByVal pParse As Any Ptr, _
    ByVal pTable As Any Ptr _
) As SQLITE_C_INT
    Return SQLITE_ERROR
End Function

Sub sqlite3VtabClear CDecl Alias "sqlite3VtabClear" ( _
    ByVal pDatabase As Any Ptr, _
    ByVal pTable As Any Ptr _
)
End Sub

Function sqlite3VtabOverloadFunction CDecl _
    Alias "sqlite3VtabOverloadFunction" ( _
    ByVal pParse As Any Ptr, _
    ByVal pExpr As Any Ptr, _
    ByVal argumentCount As SQLITE_C_INT, _
    ByVal pArgumentList As Any Ptr _
) As Any Ptr
    Return 0
End Function

Function allocateIndexInfo CDecl Alias "allocateIndexInfo" ( _
    ByVal pWhereInfo As Any Ptr, _
    ByVal pWhereClause As Any Ptr, _
    ByVal unusableMask As sqlite3_uint64, _
    ByVal pSource As Any Ptr, _
    ByVal pMaskNoOmit As Any Ptr _
) As Any Ptr
    Return 0
End Function
#endif

/' end of sqlite3_vtab_omit_stubs.bas '/
