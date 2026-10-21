/'
** 2014 May 31
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
*************************************************************************
'/
/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts5_buffer.bas

    Purpose:

        Port FTS5 buffer, position-list, and term-set helpers.

    Responsibilities:

        - Grow and append to FTS5 byte buffers.
        - Encode and traverse position lists.
        - Manage temporary term sets used during query processing.

    This file intentionally does NOT contain:

        - FTS5 index storage or virtual-table registration.
        - Test support.
'/

#ifdef SQLITE_ENABLE_FTS5
#include once "sqlite3_debug_assert.bi"
#include once "crt/stddef.bi"
#include once "crt/long.bi"
#include once "crt/longdouble.bi"
#include once "crt/stdarg.bi"

#include once "sqlite3_fts5_buffer_types.bi"

#ifndef __C2FB_BODY_C_ABI_TYPES__
#define __C2FB_BODY_C_ABI_TYPES__

#ifndef __C2FB_ABI_TYPE_C_INT__
#define __C2FB_ABI_TYPE_C_INT__
Type c2fb_c_int As Long
#endif
#ifndef __C2FB_ABI_TYPE_C_UINT__
#define __C2FB_ABI_TYPE_C_UINT__
Type c2fb_c_uint As ULong
#endif
#ifndef __C2FB_ABI_TYPE_C_LONG__
#define __C2FB_ABI_TYPE_C_LONG__
Type c2fb_c_long As CLong
#endif
#ifndef __C2FB_ABI_TYPE_C_ULONG__
#define __C2FB_ABI_TYPE_C_ULONG__
Type c2fb_c_ulong As CULong
#endif
#ifndef __C2FB_ABI_TYPE_INT64__
#define __C2FB_ABI_TYPE_INT64__
Type c2fb_int64 As LongInt
#endif
#ifndef __C2FB_ABI_TYPE_UINT64__
#define __C2FB_ABI_TYPE_UINT64__
Type c2fb_uint64 As ULongInt
#endif
#ifndef __C2FB_ABI_TYPE_SIZE_T__
#define __C2FB_ABI_TYPE_SIZE_T__
Type c2fb_size_t As UInteger
#endif
#endif


Declare Function sqlite3Fts5BufferSize CDecl Alias "sqlite3Fts5BufferSize" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_uint) As c2fb_c_int
Declare Sub sqlite3Fts5BufferAppendVarint CDecl Alias "sqlite3Fts5BufferAppendVarint" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_int64)
Declare Sub sqlite3Fts5Put32 CDecl Alias "sqlite3Fts5Put32" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_int)
Declare Function sqlite3Fts5Get32 CDecl Alias "sqlite3Fts5Get32" (ByVal arg0 As Const UByte Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5BufferAppendBlob CDecl Alias "sqlite3Fts5BufferAppendBlob" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_uint, ByVal arg3 As Const UByte Ptr)
Declare Sub sqlite3Fts5BufferAppendString CDecl Alias "sqlite3Fts5BufferAppendString" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const ZString Ptr)
Declare Sub sqlite3Fts5BufferAppendPrintf CDecl Alias "sqlite3Fts5BufferAppendPrintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As ZString Ptr, ...)
Declare Function sqlite3Fts5Mprintf CDecl Alias "sqlite3Fts5Mprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
Declare Sub sqlite3Fts5BufferFree CDecl Alias "sqlite3Fts5BufferFree" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
Declare Sub sqlite3Fts5BufferZero CDecl Alias "sqlite3Fts5BufferZero" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
Declare Sub sqlite3Fts5BufferSet CDecl Alias "sqlite3Fts5BufferSet" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
Declare Function sqlite3Fts5PoslistNext64 CDecl Alias "sqlite3Fts5PoslistNext64" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
Declare Function sqlite3Fts5PoslistReaderNext CDecl Alias "sqlite3Fts5PoslistReaderNext" (ByVal arg0 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
Declare Function sqlite3Fts5PoslistReaderInit CDecl Alias "sqlite3Fts5PoslistReaderInit" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5PoslistSafeAppend CDecl Alias "sqlite3Fts5PoslistSafeAppend" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64)
Declare Function sqlite3Fts5PoslistWriterAppend CDecl Alias "sqlite3Fts5PoslistWriterAppend" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5PoslistWriter Ptr, ByVal arg2 As c2fb_int64) As c2fb_c_int
Declare Function sqlite3Fts5MallocZero CDecl Alias "sqlite3Fts5MallocZero" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
Declare Function sqlite3Fts5Strndup CDecl Alias "sqlite3Fts5Strndup" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As ZString Ptr
Declare Function sqlite3Fts5TermsetNew CDecl Alias "sqlite3Fts5TermsetNew" (ByVal arg0 As c2fb_Fts5Termset Ptr Ptr) As c2fb_c_int
Declare Function sqlite3Fts5TermsetAdd CDecl Alias "sqlite3Fts5TermsetAdd" (ByVal arg0 As c2fb_Fts5Termset Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
Declare Sub sqlite3Fts5TermsetFree CDecl Alias "sqlite3Fts5TermsetFree" (ByVal arg0 As c2fb_Fts5Termset Ptr)
Declare Function c2fb_crt_memcpy CDecl Alias "memcpy" (ByVal arg0 As Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memset CDecl Alias "memset" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_size_t) As Any Ptr
Declare Function c2fb_crt_memcmp CDecl Alias "memcmp" (ByVal arg0 As Const Any Ptr, ByVal arg1 As Const Any Ptr, ByVal arg2 As c2fb_size_t) As c2fb_c_int
Declare Function c2fb_crt_strlen CDecl Alias "strlen" (ByVal arg0 As Const ZString Ptr) As c2fb_size_t
Declare Function c2fb_external_sqlite3_vmprintf CDecl Alias "sqlite3_vmprintf" (ByVal arg0 As Const ZString Ptr, ByVal arg1 As Cva_List) As ZString Ptr
Declare Function c2fb_external_sqlite3_malloc64 CDecl Alias "sqlite3_malloc64" (ByVal arg0 As c2fb_uint64) As Any Ptr
Declare Function c2fb_external_sqlite3_realloc64 CDecl Alias "sqlite3_realloc64" (ByVal arg0 As Any Ptr, ByVal arg1 As c2fb_uint64) As Any Ptr
Declare Sub c2fb_external_sqlite3_free CDecl Alias "sqlite3_free" (ByVal arg0 As Any Ptr)
Declare Function c2fb_external_sqlite3Fts5GetVarint32 CDecl Alias "sqlite3Fts5GetVarint32" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_uint Ptr) As c2fb_c_int
Declare Function c2fb_external_sqlite3Fts5PutVarint CDecl Alias "sqlite3Fts5PutVarint" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_uint64) As c2fb_c_int
Function sqlite3Fts5BufferSize CDecl Alias "sqlite3Fts5BufferSize" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_uint) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 18
    Dim local0 As c2fb_uint64
    Dim local1 As UByte Ptr
    Dim c2fb_temp_0 As c2fb_uint64
    Dim c2fb_temp_1 As UByte Ptr
    Dim c2fb_temp_2 As c2fb_c_int Ptr
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_u8 Ptr Ptr
    Dim c2fb_temp_7 As UByte Ptr

    If (-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, arg1->nSpace) < arg2)))) Then
        local0 = IIf(arg1->nSpace, arg1->nSpace, Cast(c2fb_c_int, 64ULL))
        ' C automatic storage declaration
        While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_uint64, arg2)))))
            c2fb_temp_0 = Cast(c2fb_uint64, Cast(c2fb_uint64, (local0 * Cast(c2fb_uint64, Cast(c2fb_c_int, 2ULL)))))
            local0 = c2fb_temp_0
        c2fb_flow_1:
        Wend
        c2fb_flow_0:
        c2fb_temp_1 = CPtr(UByte Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_realloc64(CPtr(Any Ptr, arg1->p), local0)))
        local1 = c2fb_temp_1
        If (-Cast(c2fb_c_int, ((local1 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_2 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_3 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_2) = c2fb_temp_3
            Return Cast(c2fb_c_int, 1ULL)
        Else
            c2fb_temp_4 = CPtr(Long Ptr, @(arg1->nSpace))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, local0))
            (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
            c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            c2fb_temp_6 = CPtr(c2fb_u8 Ptr Ptr, @(arg1->p))
            c2fb_temp_7 = local1
            (*c2fb_temp_6) = CPtr(c2fb_u8 Ptr, c2fb_temp_7)
            c2fb_temp_7 = CPtr(UByte Ptr, (*c2fb_temp_6))
        End If
    End If
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Sub sqlite3Fts5BufferAppendVarint CDecl Alias "sqlite3Fts5BufferAppendVarint" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 42
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    If (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((arg1)->n)) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, 9ULL))))) <= Cast(c2fb_c_uint, ((arg1)->nSpace)))))), Cast(c2fb_c_int, &O0ULL), sqlite3Fts5BufferSize((arg0), (arg1), Cast(c2fb_c_int, ((Cast(c2fb_c_int, 9ULL)) + (arg1)->n))))) Then
        Return
    End If
    c2fb_temp_0 = CPtr(Long Ptr, @(arg1->n))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_0)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(arg1->p[arg1->n])), arg2))))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
End Sub
Sub sqlite3Fts5Put32 CDecl Alias "sqlite3Fts5Put32" (ByVal arg0 As UByte Ptr, ByVal arg1 As c2fb_c_int)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 47
    Dim c2fb_temp_0 As UByte Ptr
    Dim c2fb_temp_1 As UByte
    Dim c2fb_temp_2 As UByte Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As UByte Ptr
    Dim c2fb_temp_5 As UByte
    Dim c2fb_temp_6 As UByte Ptr
    Dim c2fb_temp_7 As UByte

    c2fb_temp_0 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, &O0ULL)]))
    c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1 Shr Cast(c2fb_c_int, 24ULL)))) And Cast(c2fb_c_int, &H00FFULL))))
    (*c2fb_temp_0) = c2fb_temp_1
    c2fb_temp_2 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 1ULL)]))
    c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1 Shr Cast(c2fb_c_int, 16ULL)))) And Cast(c2fb_c_int, &H00FFULL))))
    (*c2fb_temp_2) = c2fb_temp_3
    c2fb_temp_4 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 2ULL)]))
    c2fb_temp_5 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1 Shr Cast(c2fb_c_int, 8ULL)))) And Cast(c2fb_c_int, &H00FFULL))))
    (*c2fb_temp_4) = c2fb_temp_5
    c2fb_temp_6 = CPtr(UByte Ptr, @(arg0[Cast(c2fb_c_int, 3ULL)]))
    c2fb_temp_7 = Cast(UByte, Cast(c2fb_c_int, ((Cast(c2fb_c_int, (arg1 Shr Cast(c2fb_c_int, &O0ULL)))) And Cast(c2fb_c_int, &H00FFULL))))
    (*c2fb_temp_6) = c2fb_temp_7
End Sub
Function sqlite3Fts5Get32 CDecl Alias "sqlite3Fts5Get32" (ByVal arg0 As Const UByte Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 54
    Return Cast(c2fb_c_int, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, &O0ULL)])) Shl Cast(c2fb_c_int, 24ULL)))) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0[Cast(c2fb_c_int, 1ULL)]) Shl Cast(c2fb_c_int, 16ULL))))))) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, arg0[Cast(c2fb_c_int, 2ULL)]) Shl Cast(c2fb_c_int, 8ULL))))))) + Cast(c2fb_c_uint, arg0[Cast(c2fb_c_int, 3ULL)])))))
End Function
Sub sqlite3Fts5BufferAppendBlob CDecl Alias "sqlite3Fts5BufferAppendBlob" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_uint, ByVal arg3 As Const UByte Ptr)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 63
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Long Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    If arg2 Then
        If (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((arg1)->n)) + Cast(c2fb_c_uint, (arg2)))) <= Cast(c2fb_c_uint, ((arg1)->nSpace)))))), Cast(c2fb_c_int, &O0ULL), sqlite3Fts5BufferSize((arg0), (arg1), Cast(c2fb_c_uint, ((arg2) + Cast(c2fb_c_uint, (arg1)->n)))))) Then
            Return
        End If
#ifdef SQLITE_DEBUG
        If CPtr(Any Ptr, arg1->p) = 0 Then _
            sqlite3DebugAssert(StrPtr(!"pBuf->p!=0"))
#endif
        ' C unused-parameter annotation
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, CPtr(UByte Ptr, @(arg1->p[arg1->n]))), CPtr(Const Any Ptr, arg3), arg2))
        c2fb_temp_1 = CPtr(Long Ptr, @(arg1->n))
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, Cast(c2fb_c_int, (*c2fb_temp_1))) + arg2)))
        (*c2fb_temp_1) = Cast(Long, c2fb_temp_2)
        c2fb_temp_2 = Cast(c2fb_c_int, (*c2fb_temp_1))
    End If
End Sub
Sub sqlite3Fts5BufferAppendString CDecl Alias "sqlite3Fts5BufferAppendString" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As Const ZString Ptr)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 82
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    local0 = Cast(c2fb_c_int, c2fb_crt_strlen(arg2))
    sqlite3Fts5BufferAppendBlob(arg0, arg1, Cast(c2fb_c_int, (local0 + Cast(c2fb_c_int, 1ULL))), CPtr(Const UByte Ptr, arg2))
    c2fb_temp_0 = CPtr(Long Ptr, @(arg1->n))
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 - 1)))
End Sub
Sub sqlite3Fts5BufferAppendPrintf CDecl Alias "sqlite3Fts5BufferAppendPrintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As ZString Ptr, ...)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 100
    Dim local0 As ZString Ptr
    Dim local1 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        ' C automatic storage declaration
        Cva_Start(local1, arg2)
        c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(CPtr(Const ZString Ptr, arg2), local1))
        local0 = c2fb_temp_0
        Cva_End(local1)
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_1) = c2fb_temp_2
        Else
            sqlite3Fts5BufferAppendString(arg0, arg1, CPtr(Const ZString Ptr, local0))
            c2fb_external_sqlite3_free(CPtr(Any Ptr, local0))
        End If
    End If
End Sub
Function sqlite3Fts5Mprintf CDecl Alias "sqlite3Fts5Mprintf" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ...) As ZString Ptr
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 121
    Dim local0 As ZString Ptr
    Dim local1 As Cva_List
    Dim c2fb_temp_0 As ZString Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        ' C automatic storage declaration
        Cva_Start(local1, arg1)
        c2fb_temp_0 = CPtr(ZString Ptr, c2fb_external_sqlite3_vmprintf(arg1, local1))
        local0 = c2fb_temp_0
        Cva_End(local1)
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_1) = c2fb_temp_2
        End If
    End If
    Return local0
End Function
Sub sqlite3Fts5BufferFree CDecl Alias "sqlite3Fts5BufferFree" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 139
    Dim c2fb_temp_0 As Any Ptr

    c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0->p))
    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg0), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Buffer))))
End Sub
Sub sqlite3Fts5BufferZero CDecl Alias "sqlite3Fts5BufferZero" (ByVal arg0 As c2fb_Fts5Buffer Ptr)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 148
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @(arg0->n))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
End Sub
Sub sqlite3Fts5BufferSet CDecl Alias "sqlite3Fts5BufferSet" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_Fts5Buffer Ptr, ByVal arg2 As c2fb_c_int, ByVal arg3 As Const UByte Ptr)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 157
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int

    c2fb_temp_0 = CPtr(Long Ptr, @(arg1->n))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = Cast(Long, c2fb_temp_1)
    c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
    sqlite3Fts5BufferAppendBlob(arg0, arg1, arg2, arg3)
End Sub
Function sqlite3Fts5PoslistNext64 CDecl Alias "sqlite3Fts5PoslistNext64" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_c_int Ptr, ByVal arg3 As c2fb_int64 Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 167
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_int64 Ptr
    Dim c2fb_temp_1 As c2fb_int64
    Dim local1 As c2fb_int64
    Dim local2 As c2fb_c_uint
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_uint
    Dim c2fb_temp_4 As c2fb_c_int
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_c_int Ptr
    Dim c2fb_temp_7 As c2fb_c_int
    Dim c2fb_temp_8 As c2fb_c_int
    Dim c2fb_temp_9 As c2fb_c_uint
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_c_int
    Dim c2fb_temp_12 As c2fb_int64
    Dim c2fb_temp_13 As c2fb_c_int
    Dim c2fb_temp_14 As c2fb_c_uint
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As c2fb_c_int
    Dim c2fb_temp_17 As c2fb_int64 Ptr
    Dim c2fb_temp_18 As c2fb_int64
    Dim c2fb_temp_19 As c2fb_int64 Ptr
    Dim c2fb_temp_20 As c2fb_int64
    Dim c2fb_temp_21 As c2fb_int64 Ptr
    Dim c2fb_temp_22 As c2fb_int64
    Dim c2fb_temp_23 As c2fb_c_int Ptr
    Dim c2fb_temp_24 As c2fb_c_int

    local0 = (*arg2)
#ifdef SQLITE_DEBUG
    If CPtr(Any Ptr, arg0) = 0 AndAlso local0 <> 0 Then _
        sqlite3DebugAssert(StrPtr(!"a!=0 || i==0"))
#endif
    ' C unused-parameter annotation
    If (-Cast(c2fb_c_int, ((local0 >= arg1)))) Then
        c2fb_temp_0 = CPtr(c2fb_int64 Ptr, @((*arg3)))
        c2fb_temp_1 = Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
        (*c2fb_temp_0) = c2fb_temp_1
        Return Cast(c2fb_c_int, 1ULL)
    Else
#ifdef SQLITE_DEBUG
        If CPtr(Any Ptr, arg0) = 0 Then _
            sqlite3DebugAssert(StrPtr(!"a!=0"))
#endif
        local1 = (*arg3)
        ' C automatic storage declaration
        ' C unused-parameter annotation
        c2fb_temp_2 = local0
        local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_2 + 1)))
        c2fb_temp_3 = Cast(c2fb_c_uint, (arg0)[c2fb_temp_2])
        local2 = c2fb_temp_3
        If Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))) Then
            c2fb_temp_4 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_4 - 1)))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((arg0)[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local2))))))))
            local0 = c2fb_temp_5
        End If
        ' empty C statement
        If (-Cast(c2fb_c_int, ((local2 <= Cast(c2fb_c_uint, Cast(c2fb_c_int, 1ULL)))))) Then
            If (-Cast(c2fb_c_int, ((local2 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_6 = CPtr(c2fb_c_int Ptr, @((*arg2)))
                c2fb_temp_7 = Cast(c2fb_c_int, local0)
                (*c2fb_temp_6) = c2fb_temp_7
                Return Cast(c2fb_c_int, &O0ULL)
            End If
            c2fb_temp_8 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_8 + 1)))
            c2fb_temp_9 = Cast(c2fb_c_uint, (arg0)[c2fb_temp_8])
            local2 = c2fb_temp_9
            If Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_10 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_10 - 1)))
                c2fb_temp_11 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((arg0)[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local2))))))))
                local0 = c2fb_temp_11
            End If
            ' empty C statement
            c2fb_temp_12 = Cast(c2fb_int64, Cast(c2fb_int64, ((Cast(c2fb_int64, local2)) Shl Cast(c2fb_c_int, 32ULL))))
            local1 = c2fb_temp_12
#ifdef SQLITE_DEBUG
            If local1 < 0 Then sqlite3DebugAssert(StrPtr(!"iOff>=0"))
#endif
            ' C unused-parameter annotation
            c2fb_temp_13 = local0
            local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_13 + 1)))
            c2fb_temp_14 = Cast(c2fb_c_uint, (arg0)[c2fb_temp_13])
            local2 = c2fb_temp_14
            If Cast(c2fb_c_uint, (local2 And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H80ULL)))) Then
                c2fb_temp_15 = local0
                local0 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_15 - 1)))
                c2fb_temp_16 = Cast(c2fb_c_int, Cast(c2fb_c_int, (local0 + c2fb_external_sqlite3Fts5GetVarint32(CPtr(Const UByte Ptr, CPtr(UByte Ptr, @((arg0)[local0]))), CPtr(c2fb_c_uint Ptr, CPtr(c2fb_c_uint Ptr, @((local2))))))))
                local0 = c2fb_temp_16
            End If
            ' empty C statement
            If (-Cast(c2fb_c_int, ((local2 < Cast(c2fb_c_uint, Cast(c2fb_c_int, 2ULL)))))) Then
                c2fb_temp_17 = CPtr(c2fb_int64 Ptr, @((*arg3)))
                c2fb_temp_18 = Cast(c2fb_int64, Cast(c2fb_c_int, (-Cast(c2fb_c_int, 1ULL))))
                (*c2fb_temp_17) = c2fb_temp_18
                Return Cast(c2fb_c_int, 1ULL)
            End If
            c2fb_temp_19 = CPtr(c2fb_int64 Ptr, @((*arg3)))
            c2fb_temp_20 = Cast(c2fb_int64, Cast(c2fb_int64, (local1 + Cast(c2fb_int64, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local2 - Cast(c2fb_c_uint, Cast(c2fb_c_int, 2ULL))))) And Cast(c2fb_c_uint, Cast(c2fb_c_int, &H7FFFFFFFULL)))))))))
            (*c2fb_temp_19) = c2fb_temp_20
        Else
            c2fb_temp_21 = CPtr(c2fb_int64 Ptr, @((*arg3)))
            c2fb_temp_22 = Cast(c2fb_int64, Cast(c2fb_int64, ((Cast(c2fb_int64, (local1 And Cast(c2fb_int64, (Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL)) Shl Cast(c2fb_c_int, 32ULL)))))) + (Cast(c2fb_int64, ((Cast(c2fb_int64, (local1 + Cast(c2fb_int64, (Cast(c2fb_c_uint, (local2 - Cast(c2fb_c_uint, Cast(c2fb_c_int, 2ULL))))))))) And Cast(c2fb_int64, Cast(c2fb_c_int, &H7FFFFFFFULL))))))))
            (*c2fb_temp_21) = c2fb_temp_22
        End If
#ifdef SQLITE_DEBUG
        If (*arg3) < local1 Then _
            sqlite3DebugAssert(StrPtr(!"*piOff>=iOff"))
#endif
        c2fb_temp_23 = CPtr(c2fb_c_int Ptr, @((*arg2)))
        c2fb_temp_24 = Cast(c2fb_c_int, local0)
        (*c2fb_temp_23) = c2fb_temp_24
        ' C unused-parameter annotation
        Return Cast(c2fb_c_int, &O0ULL)
    End If
End Function
Function sqlite3Fts5PoslistReaderNext CDecl Alias "sqlite3Fts5PoslistReaderNext" (ByVal arg0 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 212
    Dim c2fb_temp_0 As c2fb_u8 Ptr
    Dim c2fb_temp_1 As UByte

    If sqlite3Fts5PoslistNext64(arg0->a, arg0->n, CPtr(c2fb_c_int Ptr, @(arg0->i)), CPtr(c2fb_int64 Ptr, @(arg0->iPos))) Then
        c2fb_temp_0 = CPtr(c2fb_u8 Ptr, @(arg0->bEof))
        c2fb_temp_1 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
        (*c2fb_temp_0) = Cast(c2fb_u8, c2fb_temp_1)
        c2fb_temp_1 = Cast(UByte, (*c2fb_temp_0))
    End If
    Return arg0->bEof
End Function
Function sqlite3Fts5PoslistReaderInit CDecl Alias "sqlite3Fts5PoslistReaderInit" (ByVal arg0 As Const UByte Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As c2fb_Fts5PoslistReader Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 219
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As Const c2fb_u8 Ptr Ptr
    Dim c2fb_temp_2 As Const UByte Ptr
    Dim c2fb_temp_3 As Long Ptr
    Dim c2fb_temp_4 As c2fb_c_int

    c2fb_temp_0 = CPtr(Any Ptr, c2fb_crt_memset(CPtr(Any Ptr, arg2), Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, SizeOf(c2fb_Fts5PoslistReader))))
    c2fb_temp_1 = CPtr(Const c2fb_u8 Ptr Ptr, @(arg2->a))
    c2fb_temp_2 = arg0
    (*c2fb_temp_1) = CPtr(Const c2fb_u8 Ptr, c2fb_temp_2)
    c2fb_temp_2 = CPtr(Const UByte Ptr, (*c2fb_temp_1))
    c2fb_temp_3 = CPtr(Long Ptr, @(arg2->n))
    c2fb_temp_4 = Cast(c2fb_c_int, arg1)
    (*c2fb_temp_3) = Cast(Long, c2fb_temp_4)
    c2fb_temp_4 = Cast(c2fb_c_int, (*c2fb_temp_3))
    sqlite3Fts5PoslistReaderNext(arg2)
    Return arg2->bEof
End Function
Sub sqlite3Fts5PoslistSafeAppend CDecl Alias "sqlite3Fts5PoslistSafeAppend" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_int64 Ptr, ByVal arg2 As c2fb_int64)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 236
    Static local0 As c2fb_int64 = Cast(c2fb_int64, ((Cast(c2fb_int64, (Cast(c2fb_c_int, &H7FFFFFFFULL)))) Shl Cast(c2fb_c_int, 32ULL)))
    Dim c2fb_temp_0 As Long Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim c2fb_temp_2 As c2fb_u8 Ptr
    Dim c2fb_temp_3 As UByte
    Dim c2fb_temp_4 As Long Ptr
    Dim c2fb_temp_5 As c2fb_c_int
    Dim c2fb_temp_6 As c2fb_int64 Ptr
    Dim c2fb_temp_7 As c2fb_int64
    Dim c2fb_temp_8 As Long Ptr
    Dim c2fb_temp_9 As c2fb_c_int
    Dim c2fb_temp_10 As c2fb_int64 Ptr
    Dim c2fb_temp_11 As c2fb_int64

    If (-Cast(c2fb_c_int, ((arg2 >= (*arg1))))) Then
        ' C static scalar storage
        If (-Cast(c2fb_c_int, (((Cast(c2fb_int64, (arg2 And local0))) <> (Cast(c2fb_int64, ((*arg1) And local0))))))) Then
            c2fb_temp_0 = CPtr(Long Ptr, @(arg0->n))
            c2fb_temp_1 = Cast(c2fb_c_int, (*c2fb_temp_0))
            (*c2fb_temp_0) = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_1 + 1)))
            c2fb_temp_2 = CPtr(c2fb_u8 Ptr, @(arg0->p[c2fb_temp_1]))
            c2fb_temp_3 = Cast(UByte, Cast(c2fb_c_int, 1ULL))
            (*c2fb_temp_2) = Cast(c2fb_u8, c2fb_temp_3)
            c2fb_temp_3 = Cast(UByte, (*c2fb_temp_2))
            c2fb_temp_4 = CPtr(Long Ptr, @(arg0->n))
            c2fb_temp_5 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_4)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(arg0->p[arg0->n])), (Cast(c2fb_int64, (arg2 Shr Cast(c2fb_c_int, 32ULL))))))))
            (*c2fb_temp_4) = Cast(Long, c2fb_temp_5)
            c2fb_temp_5 = Cast(c2fb_c_int, (*c2fb_temp_4))
            c2fb_temp_6 = CPtr(c2fb_int64 Ptr, @((*arg1)))
            c2fb_temp_7 = Cast(c2fb_int64, (Cast(c2fb_int64, (arg2 And local0))))
            (*c2fb_temp_6) = c2fb_temp_7
        End If
        c2fb_temp_8 = CPtr(Long Ptr, @(arg0->n))
        c2fb_temp_9 = Cast(c2fb_c_int, Cast(c2fb_c_int, (Cast(c2fb_c_int, (*c2fb_temp_8)) + c2fb_external_sqlite3Fts5PutVarint(CPtr(UByte Ptr, @(arg0->p[arg0->n])), Cast(c2fb_int64, ((Cast(c2fb_int64, (arg2 - (*arg1)))) + Cast(c2fb_int64, Cast(c2fb_c_int, 2ULL))))))))
        (*c2fb_temp_8) = Cast(Long, c2fb_temp_9)
        c2fb_temp_9 = Cast(c2fb_c_int, (*c2fb_temp_8))
        c2fb_temp_10 = CPtr(c2fb_int64 Ptr, @((*arg1)))
        c2fb_temp_11 = Cast(c2fb_int64, arg2)
        (*c2fb_temp_10) = c2fb_temp_11
    End If
End Sub
Function sqlite3Fts5PoslistWriterAppend CDecl Alias "sqlite3Fts5PoslistWriterAppend" (ByVal arg0 As c2fb_Fts5Buffer Ptr, ByVal arg1 As c2fb_Fts5PoslistWriter Ptr, ByVal arg2 As c2fb_int64) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 253
    Dim local0 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (IIf((-Cast(c2fb_c_int, ((Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((arg0)->n)) + Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 5ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 5ULL))))))) <= Cast(c2fb_c_uint, ((arg0)->nSpace)))))), Cast(c2fb_c_int, &O0ULL), sqlite3Fts5BufferSize((CPtr(c2fb_c_int Ptr, @(local0))), (arg0), Cast(c2fb_c_int, ((Cast(c2fb_c_int, (Cast(c2fb_c_int, (Cast(c2fb_c_int, 5ULL) + Cast(c2fb_c_int, 5ULL))) + Cast(c2fb_c_int, 5ULL)))) + (arg0)->n))))) Then
        Return local0
    End If
    sqlite3Fts5PoslistSafeAppend(arg0, CPtr(c2fb_int64 Ptr, @(arg1->iPrev)), arg2)
    Return Cast(c2fb_c_int, &O0ULL)
End Function
Function sqlite3Fts5MallocZero CDecl Alias "sqlite3Fts5MallocZero" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As c2fb_int64) As Any Ptr
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 264
    Dim local0 As Any Ptr
    Dim c2fb_temp_0 As Any Ptr
    Dim c2fb_temp_1 As c2fb_c_int Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As Any Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        c2fb_temp_0 = CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(arg1))
        local0 = c2fb_temp_0
        If (-Cast(c2fb_c_int, ((local0 = Cast(c2fb_c_int, &O0ULL))))) Then
            If (-Cast(c2fb_c_int, ((arg1 > Cast(c2fb_int64, Cast(c2fb_c_int, &O0ULL)))))) Then
                c2fb_temp_1 = CPtr(c2fb_c_int Ptr, @((*arg0)))
                c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
                (*c2fb_temp_1) = c2fb_temp_2
            End If
        Else
            c2fb_temp_3 = CPtr(Any Ptr, c2fb_crt_memset(local0, Cast(c2fb_c_int, &O0ULL), Cast(c2fb_size_t, arg1)))
        End If
    End If
    Return local0
End Function
Function sqlite3Fts5Strndup CDecl Alias "sqlite3Fts5Strndup" (ByVal arg0 As c2fb_c_int Ptr, ByVal arg1 As Const ZString Ptr, ByVal arg2 As c2fb_c_int) As ZString Ptr
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 285
    Dim local0 As ZString Ptr
    Dim c2fb_temp_0 As c2fb_c_int
    Dim c2fb_temp_1 As ZString Ptr
    Dim c2fb_temp_2 As Any Ptr
    Dim c2fb_temp_3 As Byte Ptr
    Dim c2fb_temp_4 As Byte
    Dim c2fb_temp_5 As c2fb_c_int Ptr
    Dim c2fb_temp_6 As c2fb_c_int

    local0 = Cast(c2fb_c_int, &O0ULL)
    If (-Cast(c2fb_c_int, (((*arg0) = Cast(c2fb_c_int, &O0ULL))))) Then
        If (-Cast(c2fb_c_int, ((arg2 < Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_0 = Cast(c2fb_c_int, Cast(c2fb_c_int, c2fb_crt_strlen(arg1)))
            arg2 = c2fb_temp_0
        End If
        c2fb_temp_1 = CPtr(ZString Ptr, CPtr(Any Ptr, c2fb_external_sqlite3_malloc64(Cast(c2fb_int64, (Cast(c2fb_int64, arg2) + Cast(c2fb_int64, Cast(c2fb_c_int, 1ULL)))))))
        local0 = c2fb_temp_1
        If local0 Then
            c2fb_temp_2 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local0), CPtr(Const Any Ptr, arg1), arg2))
            c2fb_temp_3 = CPtr(Byte Ptr, @(CPtr(Byte Ptr, local0)[arg2]))
            c2fb_temp_4 = Cast(Byte, Cast(c2fb_c_int, 0))
            (*c2fb_temp_3) = c2fb_temp_4
        Else
            c2fb_temp_5 = CPtr(c2fb_c_int Ptr, @((*arg0)))
            c2fb_temp_6 = Cast(c2fb_c_int, Cast(c2fb_c_int, 7ULL))
            (*c2fb_temp_5) = c2fb_temp_6
        End If
    End If
    Return local0
End Function
' c2fb skipped sqlite3Fts5IsBareword: outside the supported subset
' c2fb body diagnostic [unsupported-assignment-expression] line 313: sqlite3Fts5IsBareword: assignment parser stopped at byte 4 (u8 aBareword[128] = {     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, ): aBareword[128] = {     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     0, 0,
Function sqlite3Fts5TermsetNew CDecl Alias "sqlite3Fts5TermsetNew" (ByVal arg0 As c2fb_Fts5Termset Ptr Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 343
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_Fts5Termset Ptr Ptr
    Dim c2fb_temp_1 As c2fb_Fts5Termset Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_Fts5Termset Ptr Ptr, @((*arg0)))
    c2fb_temp_1 = CPtr(_c2fb_record_c2fb_Fts5Termset Ptr, CPtr(Any Ptr, sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), Cast(c2fb_size_t, SizeOf(c2fb_Fts5Termset)))))
    (*c2fb_temp_0) = c2fb_temp_1
    Return local0
End Function
Function sqlite3Fts5TermsetAdd CDecl Alias "sqlite3Fts5TermsetAdd" (ByVal arg0 As c2fb_Fts5Termset Ptr, ByVal arg1 As c2fb_c_int, ByVal arg2 As Const ZString Ptr, ByVal arg3 As c2fb_c_int, ByVal arg4 As c2fb_c_int Ptr) As c2fb_c_int
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 349
    Dim local0 As c2fb_c_int
    Dim c2fb_temp_0 As c2fb_c_int Ptr
    Dim c2fb_temp_1 As c2fb_c_int
    Dim local1 As c2fb_c_int
    Dim local2 As c2fb_c_uint
    Dim local3 As c2fb_Fts5TermsetEntry Ptr
    Dim c2fb_temp_2 As c2fb_c_int
    Dim c2fb_temp_3 As c2fb_c_int
    Dim c2fb_temp_4 As c2fb_c_uint
    Dim c2fb_temp_5 As c2fb_c_uint
    Dim c2fb_temp_6 As c2fb_c_uint
    Dim c2fb_temp_7 As c2fb_Fts5TermsetEntry Ptr
    Dim c2fb_temp_8 As c2fb_Fts5TermsetEntry Ptr
    Dim c2fb_temp_9 As c2fb_c_int Ptr
    Dim c2fb_temp_10 As c2fb_c_int
    Dim c2fb_temp_11 As c2fb_Fts5TermsetEntry Ptr
    Dim c2fb_temp_12 As ZString Ptr Ptr
    Dim c2fb_temp_13 As ZString Ptr
    Dim c2fb_temp_14 As Long Ptr
    Dim c2fb_temp_15 As c2fb_c_int
    Dim c2fb_temp_16 As Long Ptr
    Dim c2fb_temp_17 As c2fb_c_int
    Dim c2fb_temp_18 As Any Ptr
    Dim c2fb_temp_19 As c2fb_Fts5TermsetEntry_ Ptr Ptr
    Dim c2fb_temp_20 As c2fb_Fts5TermsetEntry Ptr
    Dim c2fb_temp_21 As Any Ptr Ptr
    Dim c2fb_temp_22 As c2fb_Fts5TermsetEntry Ptr

    local0 = Cast(c2fb_c_int, &O0ULL)
    c2fb_temp_0 = CPtr(c2fb_c_int Ptr, @((*arg4)))
    c2fb_temp_1 = Cast(c2fb_c_int, Cast(c2fb_c_int, &O0ULL))
    (*c2fb_temp_0) = c2fb_temp_1
    If arg0 Then
        ' C automatic storage declaration
        local2 = Cast(c2fb_c_int, 13ULL)
        ' C automatic storage declaration
        c2fb_temp_2 = Cast(c2fb_c_int, Cast(c2fb_c_int, (arg3 - Cast(c2fb_c_int, 1ULL))))
        local1 = c2fb_temp_2
        While (-Cast(c2fb_c_int, ((local1 >= Cast(c2fb_c_int, &O0ULL)))))
            c2fb_temp_4 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local2 Shl Cast(c2fb_c_int, 3ULL)))) Xor local2)) Xor Cast(c2fb_c_uint, CPtr(Const Byte Ptr, arg2)[local1]))))
            local2 = c2fb_temp_4
        c2fb_flow_1:
            c2fb_temp_3 = local1
            local1 = Cast(c2fb_c_int, Cast(c2fb_c_int, (c2fb_temp_3 - 1)))
        Wend
        c2fb_flow_0:
        c2fb_temp_5 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (Cast(c2fb_c_uint, ((Cast(c2fb_c_uint, (local2 Shl Cast(c2fb_c_int, 3ULL)))) Xor local2)) Xor Cast(c2fb_c_uint, arg1))))
        local2 = c2fb_temp_5
        c2fb_temp_6 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (local2 Mod Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (512ULL * SizeOf(c2fb_Fts5TermsetEntry Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5TermsetEntry Ptr))))))))))))
        local2 = c2fb_temp_6
        c2fb_temp_7 = CPtr(_c2fb_record_c2fb_Fts5TermsetEntry Ptr, arg0->apHash(local2))
        local3 = c2fb_temp_7
        While local3
            If (-Cast(c2fb_c_int, ((((-Cast(c2fb_c_int, ((local3->iIdx = arg1)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((local3->nTerm = arg3)))) <> 0) AndAlso ((-Cast(c2fb_c_int, ((c2fb_crt_memcmp(CPtr(Const Any Ptr, local3->pTerm), CPtr(Const Any Ptr, arg2), arg3) = Cast(c2fb_c_int, &O0ULL))))) <> 0))))) Then
                c2fb_temp_9 = CPtr(c2fb_c_int Ptr, @((*arg4)))
                c2fb_temp_10 = Cast(c2fb_c_int, Cast(c2fb_c_int, 1ULL))
                (*c2fb_temp_9) = c2fb_temp_10
                Goto c2fb_flow_2
            End If
        c2fb_flow_3:
            c2fb_temp_8 = CPtr(_c2fb_record_c2fb_Fts5TermsetEntry Ptr, CPtr(c2fb_Fts5TermsetEntry Ptr, local3->pNext))
            local3 = c2fb_temp_8
        Wend
        c2fb_flow_2:
        If (-Cast(c2fb_c_int, ((local3 = Cast(c2fb_c_int, &O0ULL))))) Then
            c2fb_temp_11 = CPtr(_c2fb_record_c2fb_Fts5TermsetEntry Ptr, CPtr(Any Ptr, sqlite3Fts5MallocZero(CPtr(c2fb_c_int Ptr, @(local0)), Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5TermsetEntry))) + Cast(c2fb_uint64, arg3))))))
            local3 = c2fb_temp_11
            If local3 Then
                c2fb_temp_12 = CPtr(ZString Ptr Ptr, @(local3->pTerm))
                c2fb_temp_13 = CPtr(ZString Ptr, CPtr(c2fb_Fts5TermsetEntry Ptr, @(CPtr(c2fb_Fts5TermsetEntry Ptr, local3)[Cast(c2fb_c_int, 1ULL)])))
                (*c2fb_temp_12) = c2fb_temp_13
                c2fb_temp_14 = CPtr(Long Ptr, @(local3->nTerm))
                c2fb_temp_15 = Cast(c2fb_c_int, arg3)
                (*c2fb_temp_14) = Cast(Long, c2fb_temp_15)
                c2fb_temp_15 = Cast(c2fb_c_int, (*c2fb_temp_14))
                c2fb_temp_16 = CPtr(Long Ptr, @(local3->iIdx))
                c2fb_temp_17 = Cast(c2fb_c_int, arg1)
                (*c2fb_temp_16) = Cast(Long, c2fb_temp_17)
                c2fb_temp_17 = Cast(c2fb_c_int, (*c2fb_temp_16))
                c2fb_temp_18 = CPtr(Any Ptr, c2fb_crt_memcpy(CPtr(Any Ptr, local3->pTerm), CPtr(Const Any Ptr, arg2), arg3))
                c2fb_temp_19 = CPtr(c2fb_Fts5TermsetEntry_ Ptr Ptr, @(local3->pNext))
                c2fb_temp_20 = CPtr(_c2fb_record_c2fb_Fts5TermsetEntry Ptr, arg0->apHash(local2))
                (*c2fb_temp_19) = CPtr(c2fb_Fts5TermsetEntry_ Ptr, c2fb_temp_20)
                c2fb_temp_20 = CPtr(c2fb_Fts5TermsetEntry Ptr, (*c2fb_temp_19))
                c2fb_temp_21 = CPtr(Any Ptr Ptr, @(arg0->apHash(local2)))
                c2fb_temp_22 = CPtr(_c2fb_record_c2fb_Fts5TermsetEntry Ptr, local3)
                (*c2fb_temp_21) = CPtr(Any Ptr, c2fb_temp_22)
                c2fb_temp_22 = CPtr(c2fb_Fts5TermsetEntry Ptr, (*c2fb_temp_21))
            End If
        End If
    End If
    Return local0
End Function
Sub sqlite3Fts5TermsetFree CDecl Alias "sqlite3Fts5TermsetFree" (ByVal arg0 As c2fb_Fts5Termset Ptr)
' c2fb source-path: ext/fts5/fts5_buffer.c
' c2fb source-line: 398
    Dim local0 As c2fb_c_uint
    Dim c2fb_temp_0 As c2fb_c_uint
    Dim c2fb_temp_1 As c2fb_c_uint
    Dim local1 As c2fb_Fts5TermsetEntry Ptr
    Dim local2 As c2fb_Fts5TermsetEntry Ptr
    Dim c2fb_temp_2 As c2fb_Fts5TermsetEntry Ptr

    If arg0 Then
        ' C automatic storage declaration
        c2fb_temp_0 = Cast(c2fb_c_uint, Cast(c2fb_c_int, &O0ULL))
        local0 = c2fb_temp_0
        While (-Cast(c2fb_c_int, ((local0 < Cast(c2fb_c_uint, (Cast(c2fb_c_int, (Cast(c2fb_uint64, (Cast(c2fb_uint64, Cast(c2fb_size_t, (512ULL * SizeOf(c2fb_Fts5TermsetEntry Ptr)))) \ Cast(c2fb_uint64, Cast(c2fb_size_t, SizeOf(c2fb_Fts5TermsetEntry Ptr)))))))))))))
            local1 = arg0->apHash(local0)
            While local1
                local2 = local1
                c2fb_temp_2 = CPtr(_c2fb_record_c2fb_Fts5TermsetEntry Ptr, CPtr(c2fb_Fts5TermsetEntry Ptr, local1->pNext))
                local1 = c2fb_temp_2
                c2fb_external_sqlite3_free(CPtr(Any Ptr, local2))
            c2fb_flow_3:
            Wend
            c2fb_flow_2:
        c2fb_flow_1:
            c2fb_temp_1 = local0
            local0 = Cast(c2fb_c_uint, Cast(c2fb_c_uint, (c2fb_temp_1 + 1)))
        Wend
        c2fb_flow_0:
        c2fb_external_sqlite3_free(CPtr(Any Ptr, arg0))
    End If
End Sub

Private Const FTS5_BAREWORD_UNICODE_SUBSTITUTE As UByte = &H1A

Function sqlite3Fts5IsBareword CDecl Alias "sqlite3Fts5IsBareword" ( _
    ByVal character As Byte _
) As c2fb_c_int
    Dim characterCode As UByte = Cast(UByte, character)

    ' All non-ASCII bytes remain part of a bareword, including malformed UTF-8.
    If (characterCode And &H80) <> 0 Then Return 1
    If characterCode = FTS5_BAREWORD_UNICODE_SUBSTITUTE Then Return 1
    If characterCode = Asc("_") Then Return 1
    If characterCode >= Asc("0") AndAlso characterCode <= Asc("9") Then Return 1
    If characterCode >= Asc("A") AndAlso characterCode <= Asc("Z") Then Return 1
    If characterCode >= Asc("a") AndAlso characterCode <= Asc("z") Then Return 1
    Return 0
End Function
#endif

/' end of sqlite3_bulk_fts5_buffer.bas '/
