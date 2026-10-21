/'
    Project: SQLite FreeBASIC port

    File: sqlite3_types.bi

    Purpose:

        Map SQLite's fixed-width C types onto FreeBASIC types.

    Responsibilities:

        - Keep C ABI integer widths explicit across 32-bit and 64-bit targets.
        - Match SQLite's i64, u64, u32, u16, and u8 internal aliases.

    This file intentionally does NOT contain:

        - Structures, runtime state, or executable code.
'/

#ifndef SQLITE3_FB_TYPES_BI
#define SQLITE3_FB_TYPES_BI

' C int is 32-bit. FreeBASIC Integer follows target width and is 64-bit here.
#define SQLITE_C_INT Long
#define SQLITE_C_UINT ULong
#if defined(__FB_64BIT__) AndAlso defined(__FB_UNIX__)
#define SQLITE_C_LONG LongInt
#define SQLITE_C_ULONG ULongInt
#else
#define SQLITE_C_LONG Long
#define SQLITE_C_ULONG ULong
#endif
#if defined(__FB_64BIT__)
#define SQLITE_SIZE_T ULongInt
#else
#define SQLITE_SIZE_T ULong
#endif
#define sqlite3_int64 LongInt
#define sqlite3_uint64 ULongInt
#define i64 LongInt
#define u64 ULongInt
#define u32 ULong
#define u16 UShort
#define u8 UByte

' SQLite defaults this capability on non-MSVC targets. The FreeBASIC Unix
' profile links the host C99 math functions; platform builds may override it.
#if defined(__FB_UNIX__)
#ifndef SQLITE_HAVE_C99_MATH_FUNCS
#define SQLITE_HAVE_C99_MATH_FUNCS 1
#endif
#endif

' C2FB lowers GCC's fixed-width byte-swap builtins through these helpers.
Declare Function c2fbByteSwap16 CDecl Alias "c2fbByteSwap16" (ByVal value As u16) As u16
Declare Function c2fbByteSwap32 CDecl Alias "c2fbByteSwap32" (ByVal value As u32) As u32
Declare Function c2fbByteSwap64 CDecl Alias "c2fbByteSwap64" (ByVal value As u64) As u64

' Match C's uintptr_t-style casts without narrowing a Win64 address.
#if defined(__FB_64BIT__)
#define SQLITE3_PTR_TO_U64(pointerValue) CULngInt(pointerValue)
#define SQLITE3_U64_TO_PTR(pointerType, addressValue) CPtr(pointerType, addressValue)
#else
#define SQLITE3_PTR_TO_U64(pointerValue) CULng(pointerValue)
#define SQLITE3_U64_TO_PTR(pointerType, addressValue) CPtr(pointerType, CULng(addressValue))
#endif

#endif

/' end of sqlite3_types.bi '/
