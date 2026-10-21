/'
    Project: SQLite FreeBASIC port

    File: sqlite3_rtree_types.bi

    Purpose:

        Define internal records shared by the optional R-Tree virtual table.

    Responsibilities:

        - Preserve node, geometry, query, constraint, callback, and match-blob layouts.
        - Give translated R-Tree code complete record and callback pointer types.

    This file intentionally does NOT contain:

        - R-Tree cursor, cell, or module callback-table state.
'/ 

#ifndef SQLITE3_FB_RTREE_TYPES_BI
#define SQLITE3_FB_RTREE_TYPES_BI

#include once "sqlite3_types.bi"

#ifdef SQLITE_RTREE_INT_ONLY
#define SqliteRtreeDValue sqlite3_int64
#define SqliteRtreeValue SQLITE_C_INT
#else
#define SqliteRtreeDValue Double
#define SqliteRtreeValue Single
#endif

Type SqliteRtreeGeometryDeleteProc As Sub CDecl ( _
    ByVal pUser As Any Ptr _
)

Type SqliteRtreeNode
    pParent As SqliteRtreeNode Ptr
    iNode As sqlite3_int64
    nRef As SQLITE_C_INT
    isDirty As SQLITE_C_INT
    zData As UByte Ptr
    pNext As SqliteRtreeNode Ptr
End Type

Type SqliteRtreeGeometry
    pContext As Any Ptr
    nParam As SQLITE_C_INT
    aParam As SqliteRtreeDValue Ptr
    pUser As Any Ptr
    xDelUser As SqliteRtreeGeometryDeleteProc
End Type

Type SqliteRtreeQueryInfo
    pContext As Any Ptr
    nParam As SQLITE_C_INT
    aParam As SqliteRtreeDValue Ptr
    pUser As Any Ptr
    xDelUser As SqliteRtreeGeometryDeleteProc
    aCoord As SqliteRtreeDValue Ptr
    anQueue As SQLITE_C_UINT Ptr
    nCoord As SQLITE_C_INT
    iLevel As SQLITE_C_INT
    mxLevel As SQLITE_C_INT
    iRowid As sqlite3_int64
    rParentScore As SqliteRtreeDValue
    eParentWithin As SQLITE_C_INT
    eWithin As SQLITE_C_INT
    rScore As SqliteRtreeDValue
    apSqlParam As Any Ptr Ptr
End Type

Type SqliteRtreeGeometryCallbackProc As Function CDecl ( _
    ByVal pGeometry As SqliteRtreeGeometry Ptr, _
    ByVal nCoordinate As SQLITE_C_INT, _
    ByVal aCoordinate As SqliteRtreeDValue Ptr, _
    ByVal pWithin As SQLITE_C_INT Ptr _
) As SQLITE_C_INT

Type SqliteRtreeQueryCallbackProc As Function CDecl ( _
    ByVal pInfo As SqliteRtreeQueryInfo Ptr _
) As SQLITE_C_INT

Union SqliteRtreeConstraintValue
    rValue As SqliteRtreeDValue
    xGeom As SqliteRtreeGeometryCallbackProc
    xQueryFunc As SqliteRtreeQueryCallbackProc
End Union

Type SqliteRtreeConstraint
    iCoord As SQLITE_C_INT
    op As SQLITE_C_INT
    u As SqliteRtreeConstraintValue
    pInfo As SqliteRtreeQueryInfo Ptr
End Type

Type SqliteRtreeGeomCallback
    xGeom As SqliteRtreeGeometryCallbackProc
    xQueryFunc As SqliteRtreeQueryCallbackProc
    xDestructor As SqliteRtreeGeometryDeleteProc
    pContext As Any Ptr
End Type

' The C record ends in a flexible array. This one-element tail provides an
' addressable offset while keeping all fixed prefix fields in source order.
Type SqliteRtreeMatchArg
    iSize As u32
    cb As SqliteRtreeGeomCallback
    nParam As SQLITE_C_INT
    apSqlParam As Any Ptr Ptr
    aParam(0 To 0) As SqliteRtreeDValue
End Type

#endif

/' end of sqlite3_rtree_types.bi '/
