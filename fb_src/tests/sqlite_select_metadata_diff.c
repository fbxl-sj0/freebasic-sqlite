#define _GNU_SOURCE
/*
    Project: SQLite FreeBASIC port verification
    -------------------------------------------

    File: sqlite_select_metadata_diff.c

    Purpose:
        Compare SELECT column type and origin metadata between the FreeBASIC
        port and a matching SQLite C reference with column metadata enabled.

    Responsibilities:
        • Load each library in an isolated ELF namespace
        • Compare result names, declared types, database/table/origin names
        • Compare row types and values for derived tables, views, and CTEs

    This file intentionally does NOT contain:
        • SQLite implementation code
        • changes to upstream test scripts
*/
#include <dlfcn.h>
#include <link.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sqlite3.h"

typedef int (*DbOpenFn)(const char *, sqlite3 **);
typedef int (*DbCloseFn)(sqlite3 *);
typedef int (*DbExecFn)(sqlite3 *, const char *, int (*)(void *, int, char **, char **), void *, char **);
typedef int (*DbPrepareFn)(sqlite3 *, const char *, int, sqlite3_stmt **, const char **);
typedef int (*DbStepFn)(sqlite3_stmt *);
typedef int (*DbFinalizeFn)(sqlite3_stmt *);
typedef int (*DbColumnCountFn)(sqlite3_stmt *);
typedef const unsigned char *(*DbColumnTextFn)(sqlite3_stmt *, int);
typedef int (*DbColumnBytesFn)(sqlite3_stmt *, int);
typedef int (*DbColumnTypeFn)(sqlite3_stmt *, int);
typedef const char *(*DbColumnMetadataFn)(sqlite3_stmt *, int);
typedef const char *(*DbErrmsgFn)(sqlite3 *);
typedef const char *(*DbVersionFn)(void);
typedef void (*DbFreeFn)(void *);

typedef struct SQLiteApi SQLiteApi;
struct SQLiteApi {
    void *handle;
    DbOpenFn open;
    DbCloseFn close;
    DbExecFn exec;
    DbPrepareFn prepare;
    DbStepFn step;
    DbFinalizeFn finalize;
    DbColumnCountFn columnCount;
    DbColumnTextFn columnText;
    DbColumnBytesFn columnBytes;
    DbColumnTypeFn columnType;
    DbColumnMetadataFn columnName;
    DbColumnMetadataFn columnDecltype;
    DbColumnMetadataFn columnDatabaseName;
    DbColumnMetadataFn columnTableName;
    DbColumnMetadataFn columnOriginName;
    DbErrmsgFn errmsg;
    DbVersionFn version;
    DbFreeFn free;
};

static int loadApi(const char *path, SQLiteApi *api){
    memset(api, 0, sizeof(*api));
    api->handle = dlmopen(LM_ID_NEWLM, path, RTLD_NOW | RTLD_LOCAL);
    if( api->handle==0 ){
        fprintf(stderr, "dlmopen failed for %s: %s\n", path, dlerror());
        return 1;
    }
#define LOAD_API(member, type, symbol) api->member = (type)dlsym(api->handle, symbol)
    LOAD_API(open, DbOpenFn, "sqlite3_open");
    LOAD_API(close, DbCloseFn, "sqlite3_close");
    LOAD_API(exec, DbExecFn, "sqlite3_exec");
    LOAD_API(prepare, DbPrepareFn, "sqlite3_prepare_v2");
    LOAD_API(step, DbStepFn, "sqlite3_step");
    LOAD_API(finalize, DbFinalizeFn, "sqlite3_finalize");
    LOAD_API(columnCount, DbColumnCountFn, "sqlite3_column_count");
    LOAD_API(columnText, DbColumnTextFn, "sqlite3_column_text");
    LOAD_API(columnBytes, DbColumnBytesFn, "sqlite3_column_bytes");
    LOAD_API(columnType, DbColumnTypeFn, "sqlite3_column_type");
    LOAD_API(columnName, DbColumnMetadataFn, "sqlite3_column_name");
    LOAD_API(columnDecltype, DbColumnMetadataFn, "sqlite3_column_decltype");
    LOAD_API(columnDatabaseName, DbColumnMetadataFn, "sqlite3_column_database_name");
    LOAD_API(columnTableName, DbColumnMetadataFn, "sqlite3_column_table_name");
    LOAD_API(columnOriginName, DbColumnMetadataFn, "sqlite3_column_origin_name");
    LOAD_API(errmsg, DbErrmsgFn, "sqlite3_errmsg");
    LOAD_API(version, DbVersionFn, "sqlite3_libversion");
    LOAD_API(free, DbFreeFn, "sqlite3_free");
#undef LOAD_API
    if( !api->open || !api->close || !api->exec || !api->prepare ||
        !api->step || !api->finalize || !api->columnCount ||
        !api->columnText || !api->columnBytes || !api->columnType ||
        !api->columnName || !api->columnDecltype ||
        !api->columnDatabaseName || !api->columnTableName ||
        !api->columnOriginName || !api->errmsg || !api->version || !api->free ){
        fprintf(stderr, "required metadata API missing in %s\n", path);
        return 2;
    }
    return 0;
}

static int sameText(const char *left, const char *right){
    if( left==0 || right==0 ) return left==right;
    return strcmp(left, right)==0;
}

static int compareMetadata(
    const char *label,
    const char *query,
    int column,
    const char *field,
    const char *cValue,
    const char *fbValue
){
    if( sameText(cValue, fbValue) ) return 0;
    fprintf(stderr,
        "%s metadata mismatch, query=%s column=%d C=%s FB=%s\n",
        field, label, column,
        cValue ? cValue : "<NULL>", fbValue ? fbValue : "<NULL>");
    (void)query;
    return 1;
}

static int compareQuery(
    const char *label,
    const char *query,
    SQLiteApi *cApi,
    sqlite3 *cDb,
    SQLiteApi *fbApi,
    sqlite3 *fbDb
){
    sqlite3_stmt *cStmt = 0;
    sqlite3_stmt *fbStmt = 0;
    const char *tail = 0;
    int rc = 0;
    int cRc = cApi->prepare(cDb, query, -1, &cStmt, &tail);
    int fbRc = fbApi->prepare(fbDb, query, -1, &fbStmt, &tail);
    if( cRc!=SQLITE_OK || fbRc!=SQLITE_OK ){
        fprintf(stderr, "prepare failed for %s: C=%d (%s), FB=%d (%s)\n",
            label, cRc, cApi->errmsg(cDb), fbRc, fbApi->errmsg(fbDb));
        rc = 1;
        goto cleanup;
    }
    if( cApi->columnCount(cStmt)!=fbApi->columnCount(fbStmt) ){
        fprintf(stderr, "column count mismatch for %s: C=%d FB=%d\n",
            label, cApi->columnCount(cStmt), fbApi->columnCount(fbStmt));
        rc = 1;
        goto cleanup;
    }
    for(int i=0; i<cApi->columnCount(cStmt); i++){
        rc |= compareMetadata(label, query, i, "name",
            cApi->columnName(cStmt, i), fbApi->columnName(fbStmt, i));
        rc |= compareMetadata(label, query, i, "decltype",
            cApi->columnDecltype(cStmt, i), fbApi->columnDecltype(fbStmt, i));
        rc |= compareMetadata(label, query, i, "database",
            cApi->columnDatabaseName(cStmt, i), fbApi->columnDatabaseName(fbStmt, i));
        rc |= compareMetadata(label, query, i, "table",
            cApi->columnTableName(cStmt, i), fbApi->columnTableName(fbStmt, i));
        rc |= compareMetadata(label, query, i, "origin",
            cApi->columnOriginName(cStmt, i), fbApi->columnOriginName(fbStmt, i));
    }
    if( rc ) goto cleanup;
    for(;;){
        cRc = cApi->step(cStmt);
        fbRc = fbApi->step(fbStmt);
        if( cRc!=fbRc ){
            fprintf(stderr, "step result mismatch for %s: C=%d FB=%d\n", label, cRc, fbRc);
            rc = 1;
            break;
        }
        if( cRc==SQLITE_DONE ) break;
        if( cRc!=SQLITE_ROW ){
            fprintf(stderr, "step failed for %s: C=%d (%s), FB=%d (%s)\n",
                label, cRc, cApi->errmsg(cDb), fbRc, fbApi->errmsg(fbDb));
            rc = 1;
            break;
        }
        for(int i=0; i<cApi->columnCount(cStmt); i++){
            int cType = cApi->columnType(cStmt, i);
            int fbType = fbApi->columnType(fbStmt, i);
            const unsigned char *cText = cApi->columnText(cStmt, i);
            const unsigned char *fbText = fbApi->columnText(fbStmt, i);
            int cBytes = cApi->columnBytes(cStmt, i);
            int fbBytes = fbApi->columnBytes(fbStmt, i);
            if( cType!=fbType || cBytes!=fbBytes ||
                (cBytes>0 && memcmp(cText, fbText, (size_t)cBytes)!=0) ){
                fprintf(stderr, "row value mismatch for %s column=%d type C=%d FB=%d bytes C=%d FB=%d\n",
                    label, i, cType, fbType, cBytes, fbBytes);
                rc = 1;
                break;
            }
        }
        if( rc ) break;
        if( rc ) break;
    }
cleanup:
    if( cStmt ) cApi->finalize(cStmt);
    if( fbStmt ) fbApi->finalize(fbStmt);
    if( !rc ) printf("%s metadata and values match\n", label);
    return rc;
}

int main(int argc, char **argv){
    const char *cPath = argc>1 ? argv[1] : "fb_src/build/columnmeta-subquery-affinity-20261020/libsqlite3-c-columnmeta.so";
    const char *fbPath = argc>2 ? argv[2] : "fb_src/build/columnmeta-subquery-affinity-20261020/libsqlite3-fb-columnmeta.so";
    static const char setup[] =
        "CREATE TABLE typed(v TEXT COLLATE NOCASE, id INTEGER);"
        "INSERT INTO typed VALUES('1',1),('Alpha',2);"
        "CREATE VIEW typed_view AS SELECT v,id FROM typed;"
        "CREATE TABLE typed_num(v INTEGER);"
        "INSERT INTO typed_num VALUES(1),(2);";
    static const struct { const char *label; const char *sql; } cases[] = {
        {"table", "SELECT v,id FROM typed ORDER BY id"},
        {"view", "SELECT v,id FROM typed_view ORDER BY id"},
        {"derived", "SELECT x FROM (SELECT v AS x FROM typed) ORDER BY x"},
        {"limited-derived", "SELECT x FROM (SELECT v AS x FROM typed LIMIT 2) ORDER BY x"},
        {"materialized-cte", "WITH q AS MATERIALIZED (SELECT v AS x FROM typed) SELECT x FROM q ORDER BY x"},
        {"compound-text-affinity", "WITH q(ord,x) AS MATERIALIZED (SELECT 1,NULL AS x UNION ALL SELECT 2,1 UNION ALL SELECT 3,v FROM typed) SELECT x FROM q ORDER BY ord"},
        {"compound-numeric-affinity", "WITH q(ord,x) AS MATERIALIZED (SELECT 1,NULL AS x UNION ALL SELECT 2,'1' UNION ALL SELECT 3,v FROM typed_num) SELECT x FROM q ORDER BY ord"},
        {"expression", "SELECT v||'x' AS expression FROM typed ORDER BY id"},
        {"nested-view", "SELECT x FROM (SELECT v AS x FROM typed_view LIMIT 2) ORDER BY x"}
    };
    SQLiteApi cApi = {0};
    SQLiteApi fbApi = {0};
    sqlite3 *cDb = 0;
    sqlite3 *fbDb = 0;
    char *cError = 0;
    char *fbError = 0;
    int rc = 0;
    if( argc>3 ){
        fprintf(stderr, "usage: %s [C-library [FreeBASIC-library]]\n", argv[0]);
        return 9;
    }
    if( loadApi(cPath, &cApi)!=0 ){
        if( cApi.handle ) dlclose(cApi.handle);
        return 1;
    }
    if( loadApi(fbPath, &fbApi)!=0 ){
        dlclose(cApi.handle);
        if( fbApi.handle ) dlclose(fbApi.handle);
        return 2;
    }
    if( strcmp(cApi.version(), fbApi.version())!=0 ){
        fprintf(stderr, "version mismatch C=%s FB=%s\n", cApi.version(), fbApi.version());
        rc = 3;
        goto cleanup;
    }
    if( cApi.open(":memory:", &cDb)!=SQLITE_OK ||
        fbApi.open(":memory:", &fbDb)!=SQLITE_OK ){
        fprintf(stderr, "database open failed\n");
        rc = 4;
        goto cleanup;
    }
    if( cApi.exec(cDb, setup, 0, 0, &cError)!=SQLITE_OK ||
        fbApi.exec(fbDb, setup, 0, 0, &fbError)!=SQLITE_OK ){
        fprintf(stderr, "setup failed C=%s FB=%s\n",
            cError ? cError : "", fbError ? fbError : "");
        rc = 5;
        goto cleanup;
    }
    if( cError ) cApi.free(cError);
    if( fbError ) fbApi.free(fbError);
    cError = 0;
    fbError = 0;
    for(size_t i=0; i<sizeof(cases)/sizeof(cases[0]); i++){
        if( compareQuery(cases[i].label, cases[i].sql, &cApi, cDb, &fbApi, fbDb) ) rc = 6;
    }
cleanup:
    if( cError ) cApi.free(cError);
    if( fbError ) fbApi.free(fbError);
    if( cDb ) cApi.close(cDb);
    if( fbDb ) fbApi.close(fbDb);
    if( fbApi.handle ) dlclose(fbApi.handle);
    if( cApi.handle ) dlclose(cApi.handle);
    return rc;
}
/* end of sqlite_select_metadata_diff.c */
