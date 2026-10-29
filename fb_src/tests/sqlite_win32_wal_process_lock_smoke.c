/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_win32_wal_process_lock_smoke.c

    Purpose:

        Verify that the Windows VFS coordinates WAL writer locks between
        independent processes.

    Responsibilities:

        - Create a WAL database and launch a second copy of this host.
        - Hold the writer lock in the child while the parent and a worker thread
          request it.
        - Verify SQLITE_BUSY, release the child, and verify lock reacquisition.

    This file intentionally does NOT contain:

        - SQLite implementation code or modified upstream test scripts.
        - A C runtime main/startup object. The explicit PE entry point starts
          the parent or child mode; _beginthreadex initializes the worker's
          C runtime when the thread test runs.
*/

#include <sqlite3.h>

typedef void *WinHandle;
typedef unsigned int WinDword;
typedef unsigned short WinWord;
typedef int WinBool;
typedef WinDword (__stdcall *WinThreadEntry)(void *);
#if defined(_WIN64)
typedef unsigned long long WinUintptr;
#else
typedef unsigned int WinUintptr;
#endif

typedef struct WinStartupInfoA {
  WinDword cb;
  char *lpReserved;
  char *lpDesktop;
  char *lpTitle;
  WinDword dwX;
  WinDword dwY;
  WinDword dwXSize;
  WinDword dwYSize;
  WinDword dwXCountChars;
  WinDword dwYCountChars;
  WinDword dwFillAttribute;
  WinDword dwFlags;
  WinWord wShowWindow;
  WinWord cbReserved2;
  unsigned char *lpReserved2;
  WinHandle hStdInput;
  WinHandle hStdOutput;
  WinHandle hStdError;
} WinStartupInfoA;

typedef struct WinProcessInfo {
  WinHandle hProcess;
  WinHandle hThread;
  WinDword dwProcessId;
  WinDword dwThreadId;
} WinProcessInfo;

/* Windows APIs used to coordinate the parent and child without time-based
   assumptions about when the child reaches the locked section. */
__declspec(dllimport) WinHandle __stdcall CreateEventA(
    WinHandle attributes, WinBool manualReset, WinBool initialState,
    const char *name);
__declspec(dllimport) WinHandle __stdcall OpenEventA(
    WinDword desiredAccess, WinBool inheritHandle, const char *name);
__declspec(dllimport) WinBool __stdcall SetEvent(WinHandle eventHandle);
__declspec(dllimport) WinBool __stdcall ResetEvent(WinHandle eventHandle);
__declspec(dllimport) WinDword __stdcall WaitForSingleObject(
    WinHandle objectHandle, WinDword milliseconds);
__declspec(dllimport) WinBool __stdcall CloseHandle(WinHandle objectHandle);
__declspec(dllimport) WinBool __stdcall CreateProcessA(
    const char *applicationName, char *commandLine,
    WinHandle processAttributes, WinHandle threadAttributes,
    WinBool inheritHandles, WinDword creationFlags, void *environment,
    const char *currentDirectory, WinStartupInfoA *startupInfo,
    WinProcessInfo *processInfo);
__declspec(dllimport) WinBool __stdcall GetExitCodeProcess(
    WinHandle processHandle, WinDword *exitCode);
__declspec(dllimport) WinDword __stdcall GetCurrentProcessId(void);
__declspec(dllimport) WinDword __stdcall GetModuleFileNameA(
    WinHandle moduleHandle, char *filename, WinDword size);
__declspec(dllimport) WinUintptr __cdecl _beginthreadex(
    void *security, WinDword stackSize, WinThreadEntry entryPoint,
    void *argument, WinDword creationFlags, WinDword *threadId);
__declspec(dllimport) char *__stdcall GetCommandLineA(void);
__declspec(dllimport) void __stdcall ExitProcess(WinDword exitCode);

/* ------------------------------------------------------------------------- */
/* Process coordination                                                       */
/* ------------------------------------------------------------------------- */

static const char *const DATABASE_PREFIX =
    "sqlite_win32_wal_process_lock_smoke_";
static const char *const READY_EVENT_PREFIX =
    "Local\\sqlite3_fb_wal_process_lock_ready_";
static const char *const RELEASE_EVENT_PREFIX =
    "Local\\sqlite3_fb_wal_process_lock_release_";

static int hexValue(char value){
  if( value>='0' && value<='9' ) return value-'0';
  if( value>='a' && value<='f' ) return value-'a'+10;
  if( value>='A' && value<='F' ) return value-'A'+10;
  return -1;
}

static int parseChildProcessId(const char *commandLine, WinDword *processId){
  const char *p = commandLine;
  if( p==0 || processId==0 ) return 0;
  while( *p ){
    if( p[0]=='-' && p[1]=='-' && p[2]=='c' && p[3]=='h' && p[4]=='i'
     && p[5]=='l' && p[6]=='d' && p[7]=='='
    ){
      WinDword value = 0;
      int i;
      for(i=0; i<8; i++){
        int digit = hexValue(p[8+i]);
        if( digit<0 ) return 0;
        value = (value<<4) | (WinDword)digit;
      }
      if( p[16]!=0 && p[16]!=' ' && p[16]!='\t' && p[16]!='\r' && p[16]!='\n' ){
        return 0;
      }
      *processId = value;
      return value!=0;
    }
    p++;
  }
  return 0;
}

static void appendHex(WinDword value, char *target, int *offset){
  static const char digits[] = "0123456789abcdef";
  int shift;
  for(shift=28; shift>=0; shift-=4){
    target[*offset] = digits[(value>>shift) & 0x0f];
    (*offset)++;
  }
}

static void makeEventName(
    const char *prefix, WinDword processId, char *target){
  int offset = 0;
  while( *prefix ){
    target[offset] = *prefix;
    offset++;
    prefix++;
  }
  appendHex(processId, target, &offset);
  target[offset] = 0;
}

static void makeDatabaseName(WinDword processId, char *target){
  int offset = 0;
  const char *p = DATABASE_PREFIX;
  while( *p ){
    target[offset] = *p;
    offset++;
    p++;
  }
  appendHex(processId, target, &offset);
  target[offset] = '.';
  target[offset+1] = 'd';
  target[offset+2] = 'b';
  target[offset+3] = 0;
}

static void makeChildCommandLine(WinDword processId, char *target){
  static const char prefix[] = "--child=";
  int offset = 0;
  const char *p = prefix;
  while( *p ){
    target[offset] = *p;
    offset++;
    p++;
  }
  appendHex(processId, target, &offset);
  target[offset] = 0;
}

typedef struct WorkerLockContext {
  const char *databaseName;
  int resultCode;
} WorkerLockContext;

static WinDword __stdcall tryWriterLock(void *argument){
  WorkerLockContext *context = (WorkerLockContext *)argument;
  sqlite3 *db = 0;
  int rc = sqlite3_open_v2(
      context->databaseName, &db, SQLITE_OPEN_READWRITE, 0);
  if( rc==SQLITE_OK ){
    rc = sqlite3_exec(db, "BEGIN IMMEDIATE", 0, 0, 0);
  }
  if( db!=0 ){
    int closeRc = sqlite3_close(db);
    if( closeRc!=SQLITE_OK ) rc = closeRc;
  }
  context->resultCode = rc;
  return 0;
}

static int verifyThreadWriterLock(sqlite3 *db, const char *databaseName){
  WorkerLockContext context;
  WinDword threadId = 0;
  WinHandle threadHandle;

  if( db==0 || databaseName==0 ) return SQLITE_MISUSE;
  context.databaseName = databaseName;
  context.resultCode = SQLITE_ERROR;
  threadHandle = (WinHandle)_beginthreadex(
      0, 0, tryWriterLock, &context, 0, &threadId);
  if( threadHandle==0 ) return SQLITE_ERROR;
  if( WaitForSingleObject(threadHandle, 5000)!=0 ){
    CloseHandle(threadHandle);
    return SQLITE_ERROR;
  }
  if( !CloseHandle(threadHandle) ) return SQLITE_ERROR;
  return context.resultCode==SQLITE_BUSY ? SQLITE_OK : SQLITE_CORRUPT;
}

static int runChild(WinDword parentProcessId){
  char readyEventName[80];
  char releaseEventName[80];
  char databaseName[96];
  WinHandle readyEvent;
  WinHandle releaseEvent;
  sqlite3 *db = 0;
  int rc;

  makeEventName(READY_EVENT_PREFIX, parentProcessId, readyEventName);
  makeEventName(RELEASE_EVENT_PREFIX, parentProcessId, releaseEventName);
  makeDatabaseName(parentProcessId, databaseName);
  readyEvent = OpenEventA(0x0002, 0, readyEventName);
  releaseEvent = OpenEventA(0x00100000, 0, releaseEventName);

  if( readyEvent==0 || releaseEvent==0 ){
    if( readyEvent!=0 ){
      SetEvent(readyEvent);
      CloseHandle(readyEvent);
    }
    if( releaseEvent!=0 ) CloseHandle(releaseEvent);
    return SQLITE_ERROR;
  }

  rc = sqlite3_open_v2(databaseName, &db, SQLITE_OPEN_READWRITE, 0);
  if( rc==SQLITE_OK ){
    rc = sqlite3_exec(db, "BEGIN IMMEDIATE", 0, 0, 0);
  }

  /* The parent waits on this event before it tests the lock result. */
  if( !SetEvent(readyEvent) ) rc = SQLITE_ERROR;
  if( rc==SQLITE_OK ){
    WinDword waitResult = WaitForSingleObject(releaseEvent, 10000);
    if( waitResult!=0 ) rc = SQLITE_ERROR;
  }

  if( db!=0 ){
    int rollbackRc = sqlite3_exec(db, "ROLLBACK", 0, 0, 0);
    if( rc==SQLITE_OK ) rc = rollbackRc;
    if( sqlite3_close(db)!=SQLITE_OK && rc==SQLITE_OK ) rc = SQLITE_BUSY;
  }
  if( !CloseHandle(releaseEvent) && rc==SQLITE_OK ) rc = SQLITE_ERROR;
  if( !CloseHandle(readyEvent) && rc==SQLITE_OK ) rc = SQLITE_ERROR;
  return rc;
}

static int runParent(void){
  WinHandle readyEvent = 0;
  WinHandle releaseEvent = 0;
  WinProcessInfo processInfo = {0};
  WinStartupInfoA startupInfo = {0};
  sqlite3 *db = 0;
  int rc = SQLITE_OK;
  int childStarted = 0;
  WinDword childExitCode = 1;
  WinDword parentProcessId = GetCurrentProcessId();
  WinDword applicationPathLength;
  char readyEventName[80];
  char releaseEventName[80];
  char databaseName[96];
  char applicationPath[1024];
  char commandLine[32];

  makeDatabaseName(parentProcessId, databaseName);
  rc = sqlite3_open_v2(
      databaseName, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, 0);
  if( rc==SQLITE_OK ){
    rc = sqlite3_exec(db, "PRAGMA journal_mode=WAL", 0, 0, 0);
  }
  if( db!=0 ){
    int closeRc = sqlite3_close(db);
    db = 0;
    if( rc==SQLITE_OK ) rc = closeRc;
  }
  if( rc!=SQLITE_OK ) return rc;

  makeEventName(READY_EVENT_PREFIX, parentProcessId, readyEventName);
  makeEventName(RELEASE_EVENT_PREFIX, parentProcessId, releaseEventName);
  makeChildCommandLine(parentProcessId, commandLine);
  applicationPathLength = GetModuleFileNameA(
      0, applicationPath, (WinDword)sizeof(applicationPath));
  if( applicationPathLength==0 ||
      applicationPathLength>=(WinDword)sizeof(applicationPath) ){
    rc = SQLITE_ERROR;
    goto process_lock_cleanup;
  }
  readyEvent = CreateEventA(0, 1, 0, readyEventName);
  releaseEvent = CreateEventA(0, 1, 0, releaseEventName);
  if( readyEvent==0 || releaseEvent==0 ){
    rc = SQLITE_ERROR;
    goto process_lock_cleanup;
  }
  if( !ResetEvent(readyEvent) || !ResetEvent(releaseEvent) ){
    rc = SQLITE_ERROR;
    goto process_lock_cleanup;
  }

  startupInfo.cb = sizeof(startupInfo);
  if( !CreateProcessA(applicationPath, commandLine, 0, 0, 0, 0, 0, 0,
                      &startupInfo, &processInfo) ){
    rc = SQLITE_ERROR;
    goto process_lock_cleanup;
  }
  childStarted = 1;

  if( WaitForSingleObject(readyEvent, 5000)!=0 ){
    rc = SQLITE_ERROR;
    goto process_lock_cleanup;
  }

  rc = sqlite3_open_v2(databaseName, &db, SQLITE_OPEN_READWRITE, 0);
  if( rc==SQLITE_OK ){
    int lockRc = sqlite3_exec(db, "BEGIN IMMEDIATE", 0, 0, 0);
    if( lockRc!=SQLITE_BUSY ) rc = SQLITE_CORRUPT;
  }

process_lock_cleanup:
  if( releaseEvent!=0 && !SetEvent(releaseEvent) && rc==SQLITE_OK ){
    rc = SQLITE_ERROR;
  }
  if( childStarted ){
    if( WaitForSingleObject(processInfo.hProcess, 12000)!=0 ){
      if( rc==SQLITE_OK ) rc = SQLITE_ERROR;
    }else if( !GetExitCodeProcess(processInfo.hProcess, &childExitCode)
           || childExitCode!=SQLITE_OK ){
      if( rc==SQLITE_OK ) rc = SQLITE_ERROR;
    }
  }

  if( db!=0 && rc==SQLITE_OK ){
    int lockRc = sqlite3_exec(db, "BEGIN IMMEDIATE", 0, 0, 0);
    if( lockRc==SQLITE_OK ){
      /* A CRT-initialized worker must observe the same held WAL writer lock. */
      int threadRc = verifyThreadWriterLock(db, databaseName);
      int rollbackRc;
      if( rc==SQLITE_OK ) rc = threadRc;
      rollbackRc = sqlite3_exec(db, "ROLLBACK", 0, 0, 0);
      if( rc==SQLITE_OK ) rc = rollbackRc;
    }else if( rc==SQLITE_OK ){
      rc = lockRc;
    }
  }
  if( db!=0 ){
    if( sqlite3_close(db)!=SQLITE_OK && rc==SQLITE_OK ) rc = SQLITE_BUSY;
  }

  if( childStarted ){
    if( !CloseHandle(processInfo.hThread) && rc==SQLITE_OK ) rc = SQLITE_ERROR;
    if( !CloseHandle(processInfo.hProcess) && rc==SQLITE_OK ) rc = SQLITE_ERROR;
  }
  if( releaseEvent!=0 && !CloseHandle(releaseEvent) && rc==SQLITE_OK ){
    rc = SQLITE_ERROR;
  }
  if( readyEvent!=0 && !CloseHandle(readyEvent) && rc==SQLITE_OK ){
    rc = SQLITE_ERROR;
  }
  return rc;
}

static int entry(void){
  WinDword parentProcessId;
  if( parseChildProcessId(GetCommandLineA(), &parentProcessId) ){
    return runChild(parentProcessId);
  }
  return runParent();
}

void start(void){
  ExitProcess((WinDword)entry());
}

/* end of sqlite_win32_wal_process_lock_smoke.c */
