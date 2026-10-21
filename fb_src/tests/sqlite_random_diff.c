#define _GNU_SOURCE
/*
    Project: SQLite FreeBASIC port verification
    File: sqlite_random_diff.c
    Purpose: Differentially compare deterministic SQL workloads against C SQLite.
    Responsibilities:
        - Check that both libraries report the same SQLite version.
        - Create matched in-memory databases and generate bounded SQL expressions.
        - Compare result codes, row counts, and result bytes.
    This file intentionally does NOT contain: SQLite implementation code.
*/
#include <dlfcn.h>
#include <link.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sqlite3.h"

#define RESULT_HASH_FNV64_OFFSET 1469598103934665603ULL
#define RESULT_HASH_FNV64_PRIME 1099511628211ULL
#define RESULT_HASH_COLUMN_START 0xff
#define RESULT_HASH_COLUMN_END 0xfe

typedef int (*DbOpenFn)(const char *, sqlite3 **);
typedef int (*DbCloseFn)(sqlite3 *);
typedef int (*DbExecFn)(
    sqlite3 *,
    const char *,
    int (*)(void *, int, char **, char **),
    void *,
    char **
);
typedef void (*DbFreeFn)(void *);
typedef const char *(*DbVersionFn)(void);
enum {
    DIFFERENTIAL_EXPRESSION_DEPTH = 2,
    DIFFERENTIAL_DEFAULT_QUERY_COUNT = 2000,
    DIFFERENTIAL_MAX_QUERY_COUNT = 1000000,
    DIFFERENTIAL_MAX_PROJECTION_COLUMNS = 3,
    DIFFERENTIAL_MAX_RESULT_ROWS = 24
};
typedef struct ResultHash ResultHash;
struct ResultHash {
    uint64_t hash;
    unsigned int rows;
};

/* Fixed non-zero xorshift seed keeps each run reproducible. */
static uint32_t randomState = 0x7b8d4a31u;

static uint32_t nextRandom(void){
    randomState ^= randomState << 13;
    randomState ^= randomState >> 17;
    randomState ^= randomState << 5;
    return randomState;
}

static void appendText(char *out, size_t capacity, const char *text){
    size_t used = strlen(out);
    size_t length = strlen(text);
    if( used + length + 1 >= capacity ){
        fprintf(stderr, "expression buffer overflow\n");
        exit(90);
    }
    memcpy(out + used, text, length + 1);
}

static void buildExpression(char *out, size_t capacity, int depth){
    /* BLOB inputs are read through hex()/length() so exec output stays text. */
    static const char *atoms[] = {
        "a", "b", "c", "a%7", "length(b)", "abs(a%97)",
        "hex(d)", "length(d)", "typeof(d)", "typeof(a)",
        "coalesce(b,'empty')", "substr(b,1,3)",
        "round(c,2)", "a IS NULL", "quote(b)", "replace(b,'a','A')",
        "cast(c AS INTEGER)", "nullif(a%7,0)", "upper(b)", "lower(b)"
    };
    static const char *binaryOps[] = {
        "+", "-", "*", "%", "&", "|", "<<", ">>", "=", "!=",
        "<", "<=", ">", ">=", "IS", "IS NOT", "AND", "OR", "||"
    };
    static const char *unaryOps[] = {"-", "+", "NOT "};
    uint32_t choice;
    char left[512] = "";
    char right[512] = "";
    char item[512];
    const char *op;

    if( depth<=0 || nextRandom()%5==0 ){
        appendText(out, capacity, atoms[nextRandom() % (sizeof(atoms)/sizeof(atoms[0]))]);
        return;
    }

    choice = nextRandom()%7;
    if( choice==0 ){
        op = unaryOps[nextRandom() % (sizeof(unaryOps)/sizeof(unaryOps[0]))];
        appendText(out, capacity, "(");
        appendText(out, capacity, op);
        buildExpression(out, capacity, depth-1);
        appendText(out, capacity, ")");
    }else if( choice<=3 ){
        buildExpression(left, sizeof(left), depth-1);
        buildExpression(right, sizeof(right), depth-1);
        op = binaryOps[nextRandom() % (sizeof(binaryOps)/sizeof(binaryOps[0]))];
        appendText(out, capacity, "(");
        appendText(out, capacity, left);
        appendText(out, capacity, " ");
        appendText(out, capacity, op);
        appendText(out, capacity, " ");
        appendText(out, capacity, right);
        appendText(out, capacity, ")");
    }else if( choice==4 ){
        buildExpression(left, sizeof(left), depth-1);
        snprintf(item, sizeof(item), "coalesce((%s),'fallback')", left);
        appendText(out, capacity, item);
    }else if( choice==5 ){
        buildExpression(left, sizeof(left), depth-1);
        buildExpression(right, sizeof(right), depth-1);
        snprintf(item, sizeof(item), "iif((%s),(%s),NULL)", left, right);
        appendText(out, capacity, item);
    }else{
        buildExpression(left, sizeof(left), depth-1);
        buildExpression(right, sizeof(right), depth-1);
        snprintf(item, sizeof(item), "CASE WHEN (%s) THEN (%s) ELSE NULL END", left, right);
        appendText(out, capacity, item);
    }
}

static int hashCallback(void *context, int columnCount, char **values, char **names){
    ResultHash *result = (ResultHash *)context;
    (void)names;
    for(int column=0; column<columnCount; column++){
        const unsigned char *p = (const unsigned char *)values[column];
        /* Delimit columns, NULL, and empty text as distinct values. */
        result->hash ^= RESULT_HASH_COLUMN_START;
        result->hash *= RESULT_HASH_FNV64_PRIME;
        if( p ){
            while( *p ){
                result->hash ^= *p++;
                result->hash *= RESULT_HASH_FNV64_PRIME;
            }
        }else{
            result->hash ^= 0;
            result->hash *= RESULT_HASH_FNV64_PRIME;
        }
        result->hash ^= RESULT_HASH_COLUMN_END;
        result->hash *= RESULT_HASH_FNV64_PRIME;
    }
    result->rows++;
    return 0;
}

static int runQuery(
    DbExecFn execFn,
    sqlite3 *db,
    const char *sql,
    ResultHash *result,
    char **error
){
    result->hash = RESULT_HASH_FNV64_OFFSET;
    result->rows = 0;
    return execFn(db, sql, hashCallback, result, error);
}

static int prepareDatabase(DbExecFn execFn, sqlite3 *db, char **error){
    static const char setupSql[] =
        "CREATE TABLE t(a INTEGER,b TEXT,c REAL,d BLOB);"
        "INSERT INTO t VALUES"
        "(-9223372036854775808,'',-0.0,X''),"
        "(-4294967296,'alpha',1.25,X'0001'),"
        "(-97,'Alpha',-1.25,X'7fff'),"
        "(-7,'a''b',3.5,X'ff00'),"
        "(-1,'line1',-3.5,X'000000'),"
        "(0,'line2',0.0,X'102030'),"
        "(1,'',0.125,X'80'),"
        "(2,'beta',-0.125,X'01'),"
        "(7,'Beta',8.0,X'000102030405'),"
        "(97,'gamma',-8.0,X'fe'),"
        "(255,'delta',99.99,X'abcdef'),"
        "(65535,'epsilon',-99.99,X'1234567890'),"
        "(2147483647,'zeta',1.0e12,X'0102030405060708'),"
        "(4294967296,'eta',-1.0e12,X'ffeeddccbbaa'),"
        "(9223372036854775807,'theta',1.0e-12,X'0000000000000000'),"
        "(NULL,NULL,NULL,NULL);"
        "CREATE INDEX t_a ON t(a);";
    return execFn(db, setupSql, 0, 0, error);
}

int main(int argc, char **argv){
    void *handle;
    DbOpenFn fbOpen;
    DbCloseFn fbClose;
    DbExecFn fbExec;
    DbFreeFn fbFree;
    DbVersionFn fbVersion;
    sqlite3 *cDb = 0;
    sqlite3 *fbDb = 0;
    char *cError = 0;
    char *fbError = 0;
    ResultHash cResult;
    ResultHash fbResult;
    int queryCount = DIFFERENTIAL_DEFAULT_QUERY_COUNT;
    int query;
    const char *fbLibrary = argc>1 ? argv[1] : "fb_src/build/api-audit-linux-export-check.so";

    if( argc>3 ){
        fprintf(stderr, "usage: %s [FreeBASIC-library [query-count]]\n", argv[0]);
        return 7;
    }
    if( argc>2 ){
        char *end = 0;
        long value = strtol(argv[2], &end, 10);
        if( end==argv[2] || *end!=0 ||
            value<1 || value>DIFFERENTIAL_MAX_QUERY_COUNT ){
            fprintf(stderr, "query-count must be between 1 and 1000000\n");
            return 8;
        }
        queryCount = (int)value;
    }

    /* Isolate the FreeBASIC engine from the statically linked C reference. */
    handle = dlmopen(LM_ID_NEWLM, fbLibrary, RTLD_NOW | RTLD_LOCAL);
    if( handle==0 ){
        fprintf(stderr, "dlmopen failed: %s\n", dlerror());
        return 1;
    }
    fbOpen = (DbOpenFn)dlsym(handle, "sqlite3_open");
    fbClose = (DbCloseFn)dlsym(handle, "sqlite3_close");
    fbExec = (DbExecFn)dlsym(handle, "sqlite3_exec");
    fbFree = (DbFreeFn)dlsym(handle, "sqlite3_free");
    fbVersion = (DbVersionFn)dlsym(handle, "sqlite3_libversion");
    if( !fbOpen || !fbClose || !fbExec || !fbFree || !fbVersion ){
        fprintf(stderr, "FreeBASIC SQLite public API lookup failed\n");
        return 2;
    }
    if( strcmp(sqlite3_libversion(), fbVersion())!=0 ){
        fprintf(stderr, "SQLite version mismatch: C=%s FB=%s\n",
                sqlite3_libversion(), fbVersion());
        return 6;
    }
    if( sqlite3_open(":memory:", &cDb)!=SQLITE_OK || fbOpen(":memory:", &fbDb)!=SQLITE_OK ){
        fprintf(stderr, "database open failed\n");
        return 3;
    }
    if( prepareDatabase(sqlite3_exec, cDb, &cError)!=SQLITE_OK ||
        prepareDatabase(fbExec, fbDb, &fbError)!=SQLITE_OK ){
        fprintf(stderr, "database initialization failed: C=%s FB=%s\n",
                cError ? cError : "", fbError ? fbError : "");
        return 4;
    }
    if( cError ) sqlite3_free(cError);
    if( fbError ) fbFree(fbError);

    for(query=0; query<queryCount; query++){
        char expr1[512] = "";
        char expr2[512] = "";
        char predicate[512] = "";
        char sortExpr[512] = "";
        char sql[3072];
        int nProjection = 1 + (nextRandom()%DIFFERENTIAL_MAX_PROJECTION_COLUMNS);
        int withWhere = (nextRandom()%4)!=0;
        int withOrder = (nextRandom()%4)!=0;
        int limit = 1 + (int)(nextRandom()%DIFFERENTIAL_MAX_RESULT_ROWS);

        buildExpression(expr1, sizeof(expr1), DIFFERENTIAL_EXPRESSION_DEPTH);
        if( nProjection>1 ){
            buildExpression(expr2, sizeof(expr2), DIFFERENTIAL_EXPRESSION_DEPTH);
        }
        if( withWhere ){
            buildExpression(predicate, sizeof(predicate), DIFFERENTIAL_EXPRESSION_DEPTH);
        }
        if( withOrder ){
            buildExpression(sortExpr, sizeof(sortExpr), DIFFERENTIAL_EXPRESSION_DEPTH);
        }

        snprintf(sql, sizeof(sql), "SELECT %s%s%s FROM t%s%s%s%s%s LIMIT %d",
                 expr1,
                 nProjection>1 ? "," : "",
                 nProjection>1 ? expr2 : "",
                 withWhere ? " WHERE " : "",
                 withWhere ? predicate : "",
                 withOrder ? " ORDER BY " : "",
                 withOrder ? sortExpr : "",
                 withOrder ? ",rowid" : "",
                 limit);

        int cRc = runQuery(sqlite3_exec, cDb, sql, &cResult, &cError);
        int fbRc = runQuery(fbExec, fbDb, sql, &fbResult, &fbError);
        if( cRc!=fbRc || cResult.hash!=fbResult.hash || cResult.rows!=fbResult.rows ){
            fprintf(stderr,
                    "mismatch at query %d "
                    "(C rc=%d rows=%u hash=%016llx; "
                    "FB rc=%d rows=%u hash=%016llx)\n"
                    "SQL: %s\nC error: %s\nFB error: %s\n",
                    query, cRc, cResult.rows, (unsigned long long)cResult.hash,
                    fbRc, fbResult.rows, (unsigned long long)fbResult.hash,
                    sql, cError ? cError : "", fbError ? fbError : "");
            return 5;
        }
        if( cError ){ sqlite3_free(cError); cError = 0; }
        if( fbError ){ fbFree(fbError); fbError = 0; }
    }

    if( sqlite3_close(cDb)!=SQLITE_OK || fbClose(fbDb)!=SQLITE_OK ){
        fprintf(stderr, "database close failed\n");
        return 9;
    }
    dlclose(handle);
    printf("PASS: %d seeded SQL queries match C SQLite version %s.\n",
           queryCount, sqlite3_libversion());
    return 0;
}
/* end of sqlite_random_diff.c */
