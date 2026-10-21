#define _GNU_SOURCE
/*
    Project: SQLite FreeBASIC port verification
    File: loadext_oom_sweep.c
    Purpose: Sweep SQLite allocator failure points through extension loading.
    Responsibilities: Load one engine per process, inject allocation failures
    during sqlite3_load_extension() and sqlite3_auto_extension(), verify
    recovery and initializer registration, and check allocator cleanup.
    This file intentionally does NOT contain: SQLite implementation code.
*/
#include <dlfcn.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sqlite3.h"
#include "sqlite3ext.h"

enum { AUTO_EXTENSION_COUNT = 7 };

typedef struct DbApi DbApi;
typedef int (*DbOpenFn)(const char *, sqlite3 **);
typedef int (*DbCloseFn)(sqlite3 *);
typedef int (*DbExecFn)(
    sqlite3 *,
    const char *,
    int (*)(void *, int, char **, char **),
    void *,
    char **
);
typedef int (*DbDbConfigFn)(sqlite3 *, int, ...);
typedef int (*DbConfigFn)(int, ...);
typedef int (*DbEnableLoadExtensionFn)(sqlite3 *, int);
typedef int (*DbLoadExtensionFn)(sqlite3 *, const char *, const char *, char **);
typedef int (*DbAutoExtensionFn)(void (*)(void));
typedef void (*DbResetAutoExtensionFn)(void);
typedef void (*DbFreeFn)(void *);
typedef sqlite3_int64 (*DbMemoryUsedFn)(void);
typedef const char *(*DbVersionFn)(void);
struct DbApi {
    DbOpenFn open;
    DbCloseFn close;
    DbExecFn exec;
    DbDbConfigFn dbConfig;
    DbConfigFn config;
    int (*initialize)(void);
    int (*shutdown)(void);
    DbEnableLoadExtensionFn enableLoadExtension;
    DbLoadExtensionFn loadExtension;
    DbAutoExtensionFn autoExtension;
    DbResetAutoExtensionFn resetAutoExtension;
    DbFreeFn free;
    DbMemoryUsedFn memoryUsed;
    DbVersionFn version;
};

typedef struct LoadSweepResult LoadSweepResult;
struct LoadSweepResult {
    unsigned int faultPoints;
    unsigned int failedLoads;
    unsigned int toleratedFailures;
    unsigned int allocationsAtSuccess;
};

typedef struct SweepResult SweepResult;
struct SweepResult {
    LoadSweepResult transient;
    LoadSweepResult persistent;
    LoadSweepResult transientAuto;
    LoadSweepResult persistentAuto;
};

typedef struct FunctionListCheck FunctionListCheck;
struct FunctionListCheck {
    unsigned int halfEncodings;
    unsigned int statusOneEncodings;
    unsigned int statusTwoEncodings;
};

static sqlite3_mem_methods baseMethods;
static long allocationCount;
static long failAt;
static int didFail;
static int persistentFailure;
static unsigned int autoExtensionCalls;

#define DEFINE_AUTO_EXTENSION(name) \
    static int name( \
        sqlite3 *db, char **pzError, const sqlite3_api_routines *pApi \
    ){ \
        (void)db; \
        (void)pzError; \
        (void)pApi; \
        autoExtensionCalls++; \
        return SQLITE_OK; \
    }

DEFINE_AUTO_EXTENSION(autoExtension0)
DEFINE_AUTO_EXTENSION(autoExtension1)
DEFINE_AUTO_EXTENSION(autoExtension2)
DEFINE_AUTO_EXTENSION(autoExtension3)
DEFINE_AUTO_EXTENSION(autoExtension4)
DEFINE_AUTO_EXTENSION(autoExtension5)
DEFINE_AUTO_EXTENSION(autoExtension6)

static void (*const autoExtensionInitializers[AUTO_EXTENSION_COUNT])(void) = {
    (void (*)(void))autoExtension0,
    (void (*)(void))autoExtension1,
    (void (*)(void))autoExtension2,
    (void (*)(void))autoExtension3,
    (void (*)(void))autoExtension4,
    (void (*)(void))autoExtension5,
    (void (*)(void))autoExtension6
};

static int shouldFailAllocation(void){
    allocationCount++;
    if( failAt<=0 ) return 0;
    if( persistentFailure ) return allocationCount>=failAt;
    return allocationCount==failAt;
}

static void *faultMalloc(int bytes){
    if( shouldFailAllocation() ){
        didFail = 1;
        return 0;
    }
    return baseMethods.xMalloc(bytes);
}

static void *faultRealloc(void *prior, int bytes){
    if( shouldFailAllocation() ){
        didFail = 1;
        return 0;
    }
    return baseMethods.xRealloc(prior, bytes);
}

static void faultFree(void *allocation){
    baseMethods.xFree(allocation);
}

static int checkFive(void *context, int columnCount, char **values, char **names){
    int *seen = (int *)context;
    (void)names;
    if( columnCount!=1 || values[0]==0 || strtod(values[0], 0)!=5.0 ) return 1;
    *seen = 1;
    return 0;
}

static int checkOne(void *context, int columnCount, char **values, char **names){
    int *seen = (int *)context;
    (void)names;
    if( columnCount!=1 || values[0]==0 || strcmp(values[0], "1")!=0 ) return 1;
    *seen = 1;
    return 0;
}

static int functionListCallback(void *context, int columnCount, char **values, char **names){
    FunctionListCheck *check = (FunctionListCheck *)context;
    unsigned int encodingFlag = 0;
    int argumentCount;
    (void)names;
    if( columnCount<6 || values[0]==0 || values[3]==0 || values[4]==0 ) return 0;
    if( strcmp(values[3], "utf8")==0 ) encodingFlag = 1;
    else if( strcmp(values[3], "utf16le")==0 ) encodingFlag = 2;
    else if( strcmp(values[3], "utf16be")==0 ) encodingFlag = 4;
    if( encodingFlag==0 ) return 0;
    argumentCount = atoi(values[4]);
    if( strcmp(values[0], "half")==0 && argumentCount==1 ){
        check->halfEncodings |= encodingFlag;
    }else if( strcmp(values[0], "sqlite3_status")==0 && argumentCount==1 ){
        check->statusOneEncodings |= encodingFlag;
    }else if( strcmp(values[0], "sqlite3_status")==0 && argumentCount==2 ){
        check->statusTwoEncodings |= encodingFlag;
    }
    return 0;
}

static int loadAtFailure(
    DbApi *api,
    const char *extensionPath,
    long failIndex,
    int persistent,
    int *didInject,
    int *loadResult
){
    sqlite3 *db = 0;
    char *error = 0;
    int rc;
    int seen = 0;

    rc = api->open(":memory:", &db);
    if( rc!=SQLITE_OK ) return rc;
    rc = api->enableLoadExtension(db, 1);
    if( rc!=SQLITE_OK ){
        api->close(db);
        return rc;
    }
    rc = api->dbConfig(db, SQLITE_DBCONFIG_LOOKASIDE, 0, 0, 0);
    if( rc!=SQLITE_OK ){
        api->close(db);
        return rc;
    }

    allocationCount = 0;
    failAt = failIndex;
    persistentFailure = persistent;
    didFail = 0;
    rc = api->loadExtension(db, extensionPath, "testloadext_init", &error);
    failAt = 0;
    persistentFailure = 0;
    *didInject = didFail;
    *loadResult = rc;
    if( error ) api->free(error);

    if( rc==SQLITE_OK ){
        FunctionListCheck functionList = {0, 0, 0};
        rc = api->exec(db, "SELECT half(10)", checkFive, &seen, 0);
        if( rc!=SQLITE_OK || !seen ){
            api->close(db);
            return SQLITE_ERROR;
        }
        rc = api->exec(db, "PRAGMA function_list", functionListCallback, &functionList, 0);
        if( rc!=SQLITE_OK || functionList.halfEncodings!=7 ||
            functionList.statusOneEncodings!=7 || functionList.statusTwoEncodings!=7 ){
            api->close(db);
            return SQLITE_ERROR;
        }
    }else{
        rc = api->exec(db, "SELECT 1", checkOne, &seen, 0);
        if( rc!=SQLITE_OK || !seen ){
            api->close(db);
            return SQLITE_ERROR;
        }
    }

    return api->close(db);
}

static int loadApi(void *handle, DbApi *api){
#define LOAD_API(field, type, symbol) \
    api->field = (type)dlsym(handle, symbol); \
    if( api->field==0 ) return 0
    LOAD_API(open, DbOpenFn, "sqlite3_open");
    LOAD_API(close, DbCloseFn, "sqlite3_close");
    LOAD_API(exec, DbExecFn, "sqlite3_exec");
    LOAD_API(dbConfig, DbDbConfigFn, "sqlite3_db_config");
    LOAD_API(config, DbConfigFn, "sqlite3_config");
    LOAD_API(initialize, int (*)(void), "sqlite3_initialize");
    LOAD_API(shutdown, int (*)(void), "sqlite3_shutdown");
    LOAD_API(enableLoadExtension, DbEnableLoadExtensionFn, "sqlite3_enable_load_extension");
    LOAD_API(loadExtension, DbLoadExtensionFn, "sqlite3_load_extension");
    LOAD_API(autoExtension, DbAutoExtensionFn, "sqlite3_auto_extension");
    LOAD_API(resetAutoExtension, DbResetAutoExtensionFn, "sqlite3_reset_auto_extension");
    LOAD_API(free, DbFreeFn, "sqlite3_free");
    LOAD_API(memoryUsed, DbMemoryUsedFn, "sqlite3_memory_used");
    LOAD_API(version, DbVersionFn, "sqlite3_libversion");
#undef LOAD_API
    return 1;
}

static int runLoadSweep(
    DbApi *api,
    const char *extensionPath,
    int persistent,
    sqlite3_int64 baselineMemory,
    LoadSweepResult *result
){
    unsigned int failIndex;
    int rc;

    memset(result, 0, sizeof(*result));

    for(failIndex=1; failIndex<=1024; failIndex++){
        int injected = 0;
        int loadResult = SQLITE_OK;
        rc = loadAtFailure(
            api, extensionPath, failIndex, persistent, &injected, &loadResult);
        if( rc!=SQLITE_OK ) return rc;
        if( api->memoryUsed()!=baselineMemory ) return SQLITE_NOMEM;

        if( !injected ){
            if( loadResult!=SQLITE_OK ) return loadResult;
            result->allocationsAtSuccess = (unsigned int)allocationCount;
            break;
        }
        result->faultPoints++;
        if( loadResult==SQLITE_OK ) result->toleratedFailures++;
        else result->failedLoads++;
    }
    if( failIndex>1024 ) return SQLITE_TOOBIG;
    if( result->faultPoints==0 || result->allocationsAtSuccess==0 ) return SQLITE_ERROR;

    return SQLITE_OK;
}

static int runAutoExtensionAtFailure(
    DbApi *api,
    unsigned int failIndex,
    int persistent,
    int *didInject,
    unsigned int *registeredCount
){
    sqlite3 *db = 0;
    unsigned int index;
    int rc;

    api->resetAutoExtension();
    autoExtensionCalls = 0;
    allocationCount = 0;
    failAt = failIndex;
    persistentFailure = persistent;
    didFail = 0;
    *registeredCount = 0;
    for(index=0; index<AUTO_EXTENSION_COUNT; index++){
        rc = api->autoExtension(autoExtensionInitializers[index]);
        if( rc==SQLITE_OK ){
            (*registeredCount)++;
        }else if( rc!=SQLITE_NOMEM ){
            failAt = 0;
            persistentFailure = 0;
            api->resetAutoExtension();
            return rc;
        }
    }
    failAt = 0;
    persistentFailure = 0;
    *didInject = didFail;

    rc = api->open(":memory:", &db);
    if( rc!=SQLITE_OK ){
        api->resetAutoExtension();
        return rc;
    }
    if( autoExtensionCalls!=*registeredCount ){
        api->close(db);
        api->resetAutoExtension();
        return SQLITE_ERROR;
    }
    rc = api->close(db);
    api->resetAutoExtension();
    return rc;
}

static int runAutoExtensionSweep(
    DbApi *api,
    int persistent,
    sqlite3_int64 baselineMemory,
    LoadSweepResult *result
){
    unsigned int failIndex;
    int rc;

    memset(result, 0, sizeof(*result));
    for(failIndex=1; failIndex<=1024; failIndex++){
        int injected = 0;
        unsigned int registered = 0;
        rc = runAutoExtensionAtFailure(
            api, failIndex, persistent, &injected, &registered);
        if( rc!=SQLITE_OK ) return rc;
        if( api->memoryUsed()!=baselineMemory ) return SQLITE_NOMEM;
        if( !injected ){
            if( registered!=AUTO_EXTENSION_COUNT ) return SQLITE_ERROR;
            result->allocationsAtSuccess = (unsigned int)allocationCount;
            break;
        }
        result->faultPoints++;
        result->failedLoads += AUTO_EXTENSION_COUNT - registered;
        result->toleratedFailures += registered;
    }
    if( failIndex>1024 ) return SQLITE_TOOBIG;
    if( result->faultPoints==0 || result->allocationsAtSuccess==0 ) return SQLITE_ERROR;
    return SQLITE_OK;
}

static int runSweep(DbApi *api, const char *extensionPath, SweepResult *result){
    sqlite3_mem_methods wrappedMethods;
    sqlite3_int64 baselineMemory;
    int rc;

    memset(result, 0, sizeof(*result));
    rc = api->shutdown();
    if( rc!=SQLITE_OK ) return rc;
    rc = api->config(SQLITE_CONFIG_GETMALLOC, &baseMethods);
    if( rc!=SQLITE_OK ) return rc;

    wrappedMethods = baseMethods;
    wrappedMethods.xMalloc = faultMalloc;
    wrappedMethods.xRealloc = faultRealloc;
    wrappedMethods.xFree = faultFree;
    rc = api->config(SQLITE_CONFIG_MALLOC, &wrappedMethods);
    if( rc!=SQLITE_OK ) return rc;
    rc = api->initialize();
    if( rc!=SQLITE_OK ) return rc;
    baselineMemory = api->memoryUsed();

    rc = runLoadSweep(api, extensionPath, 0, baselineMemory, &result->transient);
    if( rc!=SQLITE_OK ) return rc;
    rc = runLoadSweep(api, extensionPath, 1, baselineMemory, &result->persistent);
    if( rc!=SQLITE_OK ) return rc;
    rc = runAutoExtensionSweep(api, 0, baselineMemory, &result->transientAuto);
    if( rc!=SQLITE_OK ) return rc;
    rc = runAutoExtensionSweep(api, 1, baselineMemory, &result->persistentAuto);
    if( rc!=SQLITE_OK ) return rc;

    rc = api->shutdown();
    if( rc!=SQLITE_OK ) return rc;
    return api->config(SQLITE_CONFIG_MALLOC, &baseMethods);
}

int main(int argc, char **argv){
    const char *libraryPath = argc>1 ? argv[1] : "fb_src/build/api-audit-linux-export-check.so";
    const char *extensionPath = argc>2 ? argv[2] : "/tmp/libtestloadext.so";
    void *handle;
    DbApi api;
    SweepResult result;

    if( argc>3 ){
        fprintf(stderr, "usage: %s [SQLite-library [test-extension]]\n", argv[0]);
        return 1;
    }
    handle = dlopen(libraryPath, RTLD_NOW | RTLD_LOCAL);
    if( handle==0 ){
        fprintf(stderr, "dlopen failed: %s\n", dlerror());
        return 2;
    }
    if( !loadApi(handle, &api) ){
        fprintf(stderr, "SQLite API lookup failed\n");
        return 3;
    }
    if( strcmp(api.version(), SQLITE_VERSION)!=0 ){
        fprintf(stderr, "SQLite version mismatch: library=%s header=%s\n",
                api.version(), SQLITE_VERSION);
        return 4;
    }
    if( runSweep(&api, extensionPath, &result)!=SQLITE_OK ){
        fprintf(stderr, "extension-load allocation sweep failed for %s\n", libraryPath);
        return 5;
    }
    printf("PASS: %s, version %s; load transient=%u (%u failed, %u tolerated), "
           "load persistent=%u (%u failed, %u tolerated); "
           "auto-extension transient=%u (%u registration failures), "
           "auto-extension persistent=%u (%u registration failures).\n",
           libraryPath, api.version(), result.transient.faultPoints,
           result.transient.failedLoads, result.transient.toleratedFailures,
           result.persistent.faultPoints, result.persistent.failedLoads,
           result.persistent.toleratedFailures,
           result.transientAuto.faultPoints, result.transientAuto.failedLoads,
           result.persistentAuto.faultPoints, result.persistentAuto.failedLoads);
    dlclose(handle);
    return 0;
}
/* end of loadext_oom_sweep.c */
