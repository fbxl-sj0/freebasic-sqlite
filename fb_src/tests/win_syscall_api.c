/*
    Project: SQLite FreeBASIC port verification
    File: win_syscall_api.c
    Purpose: Verify the Windows VFS syscall override callbacks.
    Responsibilities:
        - Check syscall enumeration and lookup.
        - Check named and global override reset behavior.
        - Confirm a ReadFile override receives real database I/O.
        - Confirm an injected ReadFile error maps to SQLITE_IOERR_READ.
    This file intentionally does NOT contain:
        - SQLite implementation code.
*/
#include "sqlite3.h"

enum {
    SQLITE_TEST_SYSCALL_PASS = 0,
    SQLITE_TEST_SYSCALL_NO_VFS = 1,
    SQLITE_TEST_SYSCALL_TOO_MANY = 2,
    SQLITE_TEST_SYSCALL_DUPLICATE = 3,
    SQLITE_TEST_SYSCALL_NO_READFILE = 4,
    SQLITE_TEST_SYSCALL_NULL_DEFAULT = 5,
    SQLITE_TEST_SYSCALL_SET_FAILED = 6,
    SQLITE_TEST_SYSCALL_UNKNOWN_SET = 7,
    SQLITE_TEST_SYSCALL_UNKNOWN_LOOKUP = 8,
    SQLITE_TEST_SYSCALL_RESET_ONE = 9,
    SQLITE_TEST_SYSCALL_OPEN_CREATE = 10,
    SQLITE_TEST_SYSCALL_INIT_DATABASE = 11,
    SQLITE_TEST_SYSCALL_CLOSE_CREATE = 12,
    SQLITE_TEST_SYSCALL_SET_IO_WRAPPER = 13,
    SQLITE_TEST_SYSCALL_OPEN_READONLY = 14,
    SQLITE_TEST_SYSCALL_PREPARE_READ = 15,
    SQLITE_TEST_SYSCALL_READ_RESULT = 16,
    SQLITE_TEST_SYSCALL_FINALIZE_READ = 17,
    SQLITE_TEST_SYSCALL_CLOSE_READ = 18,
    SQLITE_TEST_SYSCALL_NO_IO_CALLBACK = 19,
    SQLITE_TEST_SYSCALL_RESET_ALL = 20,
    SQLITE_TEST_SYSCALL_DELETE_DATABASE = 21,
    SQLITE_TEST_SYSCALL_OPEN_FOR_ERROR = 22,
    SQLITE_TEST_SYSCALL_INJECT_READ_ERROR = 23,
    SQLITE_TEST_SYSCALL_VERIFY_READ_ERROR = 24,
    SQLITE_TEST_SYSCALL_CLOSE_READ_ERROR = 25,
    /* Larger than SQLite's 60-entry table to catch a broken iterator. */
    SQLITE_TEST_SYSCALL_MAX_ENTRIES = 128,
    SQLITE_TEST_SYSCALL_ROW_VALUE = 731,
    /* Win32 ERROR_READ_FAULT, read immediately through GetLastError by xRead. */
    SQLITE_TEST_WIN_ERROR_READ_FAULT = 30
};

typedef int BOOL;
typedef unsigned long DWORD;
typedef void *HANDLE;
typedef void *LPVOID;
typedef DWORD *LPDWORD;
typedef struct _OVERLAPPED OVERLAPPED;
typedef OVERLAPPED *LPOVERLAPPED;
#define WINAPI __attribute__((stdcall))
typedef BOOL (WINAPI *ReadFileProc)(HANDLE, LPVOID, DWORD, LPDWORD, LPOVERLAPPED);
/* Keep the Windows ABI surface limited to the ReadFile fault used here. */
__declspec(dllimport) void WINAPI SetLastError(DWORD errorCode);
static sqlite3_syscall_ptr savedReadFile;
static unsigned int readFileCalls;
static int failNextRead;

static int sameString(const char *left, const char *right){
    while( *left && *left==*right ){ left++; right++; }
    return *left==*right;
}

static BOOL WINAPI auditReadFile(
    HANDLE fileHandle,
    LPVOID buffer,
    DWORD bytesToRead,
    LPDWORD bytesRead,
    LPOVERLAPPED overlapped
){
    ReadFileProc original = (ReadFileProc)savedReadFile;
    readFileCalls++;
    if( failNextRead ){
        failNextRead = 0;
        SetLastError(SQLITE_TEST_WIN_ERROR_READ_FAULT);
        return 0;
    }
    return original(fileHandle, buffer, bytesToRead, bytesRead, overlapped);
}

int main(void){
    sqlite3_vfs *vfs = sqlite3_vfs_find(0);
    const char *name;
    const char *seen[SQLITE_TEST_SYSCALL_MAX_ENTRIES];
    unsigned int syscallCount = 0;
    int sawReadFile = 0;
    int rc;
    sqlite3 *db = 0;
    sqlite3_stmt *stmt = 0;
    const char *databasePath = "sqlite3_win_syscall_audit.db";

    if( vfs==0 || vfs->iVersion<3 || vfs->xSetSystemCall==0 ||
        vfs->xGetSystemCall==0 || vfs->xNextSystemCall==0 ){
        return SQLITE_TEST_SYSCALL_NO_VFS;
    }
    for(name=vfs->xNextSystemCall(vfs, 0); name; name=vfs->xNextSystemCall(vfs, name)){
        if( syscallCount>=SQLITE_TEST_SYSCALL_MAX_ENTRIES ){
            return SQLITE_TEST_SYSCALL_TOO_MANY;
        }
        for( unsigned int priorIndex=0; priorIndex<syscallCount; priorIndex++ ){
            if( sameString(seen[priorIndex], name) ){
                return SQLITE_TEST_SYSCALL_DUPLICATE;
            }
        }
        if( sameString(name, "ReadFile") ) sawReadFile = 1;
        seen[syscallCount++] = name;
    }
    if( syscallCount==0 || !sawReadFile ) return SQLITE_TEST_SYSCALL_NO_READFILE;

    savedReadFile = vfs->xGetSystemCall(vfs, "ReadFile");
    if( savedReadFile==0 ) return SQLITE_TEST_SYSCALL_NULL_DEFAULT;
    rc = vfs->xSetSystemCall(vfs, "ReadFile", (sqlite3_syscall_ptr)auditReadFile);
    if( rc!=SQLITE_OK || vfs->xGetSystemCall(vfs, "ReadFile")!=(sqlite3_syscall_ptr)auditReadFile ){
        return SQLITE_TEST_SYSCALL_SET_FAILED;
    }
    if( vfs->xSetSystemCall(
            vfs, "no-such-system-call", (sqlite3_syscall_ptr)auditReadFile
        )!=SQLITE_NOTFOUND
    ){
        return SQLITE_TEST_SYSCALL_UNKNOWN_SET;
    }
    if( vfs->xGetSystemCall(vfs, "no-such-system-call")!=0 ||
        vfs->xNextSystemCall(vfs, "no-such-system-call")!=0 ){
        return SQLITE_TEST_SYSCALL_UNKNOWN_LOOKUP;
    }
    rc = vfs->xSetSystemCall(vfs, "ReadFile", 0);
    if( rc!=SQLITE_OK || vfs->xGetSystemCall(vfs, "ReadFile")!=savedReadFile ){
        return SQLITE_TEST_SYSCALL_RESET_ONE;
    }

    rc = sqlite3_open(databasePath, &db);
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_OPEN_CREATE;
    rc = sqlite3_exec(
        db,
        "CREATE TABLE IF NOT EXISTS t(x); DELETE FROM t; INSERT INTO t VALUES(731);",
        0, 0, 0
    );
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_INIT_DATABASE;
    rc = sqlite3_close(db);
    db = 0;
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_CLOSE_CREATE;

    rc = vfs->xSetSystemCall(vfs, "ReadFile", (sqlite3_syscall_ptr)auditReadFile);
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_SET_IO_WRAPPER;
    rc = sqlite3_open_v2(databasePath, &db, SQLITE_OPEN_READONLY, 0);
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_OPEN_READONLY;
    rc = sqlite3_prepare_v2(db, "SELECT x FROM t", -1, &stmt, 0);
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_PREPARE_READ;
    if( sqlite3_step(stmt)!=SQLITE_ROW ||
        sqlite3_column_int(stmt, 0)!=SQLITE_TEST_SYSCALL_ROW_VALUE ){
        return SQLITE_TEST_SYSCALL_READ_RESULT;
    }
    rc = sqlite3_finalize(stmt);
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_FINALIZE_READ;
    rc = sqlite3_close(db);
    db = 0;
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_CLOSE_READ;
    if( readFileCalls==0 ) return SQLITE_TEST_SYSCALL_NO_IO_CALLBACK;

    rc = sqlite3_open_v2(databasePath, &db, SQLITE_OPEN_READONLY, 0);
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_OPEN_FOR_ERROR;
    sqlite3_extended_result_codes(db, 1);
    failNextRead = 1;
    /* xRead consumes the error code immediately after the failed ReadFile. */
    rc = sqlite3_prepare_v2(db, "SELECT x FROM t", -1, &stmt, 0);
    if( failNextRead ) return SQLITE_TEST_SYSCALL_INJECT_READ_ERROR;
    if( rc!=SQLITE_IOERR_READ || sqlite3_extended_errcode(db)!=SQLITE_IOERR_READ ){
        return SQLITE_TEST_SYSCALL_VERIFY_READ_ERROR;
    }
    if( stmt!=0 ) sqlite3_finalize(stmt);
    rc = sqlite3_close(db);
    db = 0;
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_CLOSE_READ_ERROR;

    rc = vfs->xSetSystemCall(vfs, 0, 0);
    if( rc!=SQLITE_OK || vfs->xGetSystemCall(vfs, "ReadFile")!=savedReadFile ){
        return SQLITE_TEST_SYSCALL_RESET_ALL;
    }
    /* xDelete's final argument disables directory syncing for this scratch file. */
    rc = vfs->xDelete(vfs, databasePath, 0);
    if( rc!=SQLITE_OK ) return SQLITE_TEST_SYSCALL_DELETE_DATABASE;
    return SQLITE_TEST_SYSCALL_PASS;
}
/* end of win_syscall_api.c */
