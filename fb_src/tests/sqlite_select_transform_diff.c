/*
    Project: SQLite FreeBASIC port verification
    -------------------------------------------

    File: sqlite_select_transform_diff.c

    Purpose:
        Compare complex SELECT and CTE results from the FreeBASIC port
        with the local SQLite C reference.

    Responsibilities:
        • Load the FreeBASIC library in an isolated ELF namespace
        • Run identical setup and query SQL against both engines
        • Generate bounded compound-arm affinity permutations
        • Compare result codes, column names, values, and row counts

    This file intentionally does NOT contain:
        • SQLite implementation code
        • changes to upstream test scripts
*/
#define _GNU_SOURCE
#include <dlfcn.h>
#include <link.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sqlite3.h"

typedef int (*DbOpenFn)(const char *, sqlite3 **);
typedef int (*DbCloseFn)(sqlite3 *);
typedef int (*DbExecFn)(sqlite3 *, const char *, int (*)(void *, int, char **, char **), void *, char **);
typedef void (*DbFreeFn)(void *);
typedef const char *(*DbVersionFn)(void);

typedef struct QueryResult QueryResult;
struct QueryResult {
    uint64_t hash;
    unsigned int rows;
};

static const uint64_t HASH_OFFSET = 1469598103934665603ULL;
static const uint64_t HASH_PRIME = 1099511628211ULL;

static void hashByte(QueryResult *r, unsigned char value){
    r->hash ^= value;
    r->hash *= HASH_PRIME;
}

static void hashText(QueryResult *r, const char *text){
    if( text==0 ){
        hashByte(r, 0x00);
        return;
    }
    while( *text ) hashByte(r, (unsigned char)*text++);
    hashByte(r, 0xff);
}

static int hashCallback(void *context, int nColumn, char **values, char **names){
    QueryResult *r = (QueryResult *)context;
    int i;
    for(i=0; i<nColumn; i++){
        hashByte(r, 0xf1);
        hashText(r, names[i]);
        hashText(r, values[i]);
    }
    hashByte(r, 0xfe);
    r->rows++;
    return 0;
}

static int run(DbExecFn execFn, sqlite3 *db, const char *sql, QueryResult *r, char **error){
    r->hash = HASH_OFFSET;
    r->rows = 0;
    return execFn(db, sql, hashCallback, r, error);
}

static int runAffinityMatrix(
    DbExecFn cExec, sqlite3 *cDb, DbFreeFn cFree,
    DbExecFn fbExec, sqlite3 *fbDb, DbFreeFn fbFree
){
    static const char *noAffinity[] = {
        "NULL", "1", "'1'", "X'31'", "1+0", "'1'||''", "abs(1)", "zeroblob(1)"
    };
    static const char *typedAffinity[] = {
        "t", "i", "r", "b", "CAST(i AS TEXT)", "CAST(t AS INTEGER)"
    };
    size_t left;
    size_t middle;
    size_t selected;
    size_t queryNumber = 0;

    for(left=0; left<sizeof(noAffinity)/sizeof(noAffinity[0]); left++){
        for(middle=0; middle<sizeof(noAffinity)/sizeof(noAffinity[0]); middle++){
            for(selected=0; selected<sizeof(typedAffinity)/sizeof(typedAffinity[0]); selected++){
                char sql[2048];
                QueryResult cResult, fbResult;
                char *cError = 0;
                char *fbError = 0;
                int length;
                int cRc;
                int fbRc;

                queryNumber++;
                length = snprintf(sql, sizeof(sql),
                    "WITH q(ord,x) AS MATERIALIZED ("
                    "SELECT 1 AS ord,%s AS x FROM type_matrix "
                    "UNION ALL SELECT 2,%s FROM type_matrix "
                    "UNION ALL SELECT 3,%s FROM type_matrix) "
                    "SELECT ord,typeof(x),x=1,x='1',quote(x) FROM q ORDER BY ord",
                    noAffinity[left], noAffinity[middle], typedAffinity[selected]);
                if( length<0 || (size_t)length>=sizeof(sql) ){
                    fprintf(stderr, "affinity-matrix SQL buffer is too small\n");
                    return 7;
                }

                cRc = run(cExec, cDb, sql, &cResult, &cError);
                fbRc = run(fbExec, fbDb, sql, &fbResult, &fbError);
                if( cRc!=SQLITE_OK || fbRc!=SQLITE_OK ||
                    cResult.rows!=fbResult.rows || cResult.hash!=fbResult.hash ){
                    fprintf(stderr,
                        "compound-affinity permutation %zu mismatch: C rc=%d rows=%u, FB rc=%d rows=%u\n"
                        "SQL: %s\nC error: %s\nFB error: %s\n",
                        queryNumber, cRc, cResult.rows, fbRc, fbResult.rows, sql,
                        cError ? cError : "", fbError ? fbError : "");
                    if( cError ) cFree(cError);
                    if( fbError ) fbFree(fbError);
                    return 8;
                }
                if( cError ) cFree(cError);
                if( fbError ) fbFree(fbError);
            }
        }
    }

    printf("%zu generated compound-affinity cases matched\n", queryNumber);
    return 0;
}

static const char setupSql[] =
    "CREATE TABLE l(k INTEGER, v TEXT, n INTEGER);"
    "INSERT INTO l VALUES"
    "(1,'one',10),(1,'uno',11),(2,'two',20),(3,'three',30),"
    "(5,'five',50),(NULL,'nil',0),(7,'seven',70);"
    "CREATE TABLE r(k INTEGER, label TEXT, n INTEGER);"
    "INSERT INTO r VALUES"
    "(1,'A',100),(2,'B',200),(2,'Bee',201),(4,'D',400),"
    "(5,'E',500),(NULL,'NullKey',-1),(8,'H',800);"
    "CREATE TABLE typed(v TEXT);"
    "INSERT INTO typed VALUES('1');"
    "CREATE TABLE typed_num(v INTEGER);"
    "INSERT INTO typed_num VALUES(1);"
    "CREATE TABLE type_matrix(t TEXT,i INTEGER,r REAL,b BLOB);"
    "INSERT INTO type_matrix VALUES('1',1,1.0,X'31');"
    "CREATE INDEX l_k_n ON l(k,n);"
    "CREATE INDEX r_k_n ON r(k,n);";

static const char *queries[] = {
    "SELECT a.k,a.v,b.label FROM "
    "(SELECT k,v FROM l WHERE n>=10) AS a "
    "LEFT JOIN (SELECT k,label FROM r WHERE n<600) AS b ON a.k=b.k "
    "ORDER BY a.k,a.v,b.label",

    "SELECT x.k,x.v,y.label FROM "
    "(SELECT k,v FROM l WHERE k<3 UNION ALL SELECT k,v FROM l WHERE k=5) AS x "
    "LEFT JOIN r AS y ON x.k=y.k ORDER BY x.k,x.v,y.label",

    "SELECT x.k,x.v FROM "
    "(SELECT k,v FROM l WHERE k<=2 UNION SELECT k,v FROM l WHERE k>=5) AS x "
    "ORDER BY x.k,x.v",

    "WITH x AS (SELECT k,v FROM l WHERE k IS NOT NULL), "
    "y AS (SELECT k,label FROM r WHERE n>=200) "
    "SELECT x.k,x.v,y.label FROM x LEFT JOIN y ON x.k=y.k "
    "ORDER BY x.k,x.v,y.label",

    "WITH RECURSIVE seq(x) AS (VALUES(0) UNION ALL SELECT x+1 FROM seq WHERE x<8) "
    "SELECT seq.x,l.v,r.label FROM seq LEFT JOIN l ON l.k=seq.x "
    "LEFT JOIN r ON r.k=seq.x ORDER BY seq.x,l.v,r.label",

    "WITH RECURSIVE tree(id,parent) AS ("
    "VALUES(1,NULL) UNION ALL SELECT id+1,id FROM tree WHERE id<7) "
    "SELECT t.id,p.id FROM tree AS t LEFT JOIN tree AS p ON t.parent=p.id "
    "ORDER BY t.id,p.id",

    "SELECT d.k,d.rn,r.label FROM "
    "(SELECT k,row_number() OVER (PARTITION BY k ORDER BY n,v) AS rn FROM l) AS d "
    "LEFT JOIN r ON d.k=r.k ORDER BY d.k,d.rn,r.label",

    "SELECT l.k,l.v,r.label FROM l RIGHT JOIN r ON l.k=r.k "
    "ORDER BY r.k,r.label,l.v",

    "SELECT l.k,l.v,r.label FROM l FULL OUTER JOIN r ON l.k=r.k "
    "ORDER BY l.k,r.k,l.v,r.label",

    "SELECT a.k,a.v,b.label FROM l AS a LEFT JOIN r AS b USING(k) "
    "ORDER BY a.k,a.v,b.label",

    "SELECT a.k,a.v,b.label FROM l AS a NATURAL LEFT JOIN "
    "(SELECT k,label FROM r) AS b ORDER BY a.k,a.v,b.label",

    "SELECT q.k,q.c,r.label FROM "
    "(SELECT k,count(*) AS c FROM l GROUP BY k HAVING count(*)>0) AS q "
    "LEFT JOIN r ON q.k=r.k ORDER BY q.k,r.label",

    "SELECT l.k,(SELECT count(*) FROM r WHERE r.k=l.k) AS nr "
    "FROM (SELECT k FROM l WHERE k IS NOT NULL GROUP BY k) AS l ORDER BY l.k",

    "WITH x(k,v) AS (VALUES(1,'x'),(3,'y'),(5,'z')) "
    "SELECT x.k,x.v FROM x LEFT JOIN l ON x.k=l.k ORDER BY x.k,x.v,l.v",

    "SELECT x.k,x.n,y.label FROM "
    "(SELECT k,sum(n) AS n FROM l GROUP BY k) AS x "
    "LEFT JOIN (SELECT k,label FROM r WHERE n>0) AS y ON x.k=y.k "
    "ORDER BY x.k,y.label",

    "SELECT d.k,d.v FROM "
    "(SELECT k,v FROM l INTERSECT SELECT k,v FROM l WHERE n<30) AS d "
    "ORDER BY d.k,d.v",

    "SELECT d.k,d.v FROM "
    "(SELECT k,v FROM l EXCEPT SELECT k,v FROM l WHERE k=1) AS d "
    "ORDER BY d.k,d.v",

    "SELECT x.k,x.v,y.label FROM "
    "(SELECT k,v FROM l ORDER BY n DESC LIMIT 4) AS x "
    "LEFT JOIN r AS y ON x.k=y.k ORDER BY x.k,x.v,y.label",

    "SELECT x.k,x.v,y.label FROM "
    "(SELECT DISTINCT k,v FROM l) AS x LEFT JOIN r AS y ON x.k=y.k "
    "WHERE y.label IS NULL OR x.k IN (1,2,5) ORDER BY x.k,x.v,y.label",

    "SELECT d.k,d.v,r.label FROM "
    "(SELECT l.k,l.v FROM l LEFT JOIN r ON l.k=r.k WHERE r.n IS NULL OR r.n>200) AS d "
    "LEFT JOIN r ON d.k=r.k ORDER BY d.k,d.v,r.label",

    "SELECT x.k,x.v FROM "
    "(SELECT k,v FROM l UNION ALL SELECT k,v FROM l WHERE k IS NULL) AS x "
    "ORDER BY x.k,x.v LIMIT 12 OFFSET 1",

    "SELECT q.ord,q.x,typeof(q.x),q.x=1 FROM ("
    "SELECT 1 AS ord,NULL AS x UNION ALL "
    "SELECT 2,'1' UNION ALL SELECT 3,v FROM typed"
    ") AS q ORDER BY q.ord",

    "WITH q(ord,x) AS MATERIALIZED ("
    "SELECT 1,NULL AS x UNION ALL SELECT 2,1 UNION ALL SELECT 3,v FROM typed"
    ") SELECT q.ord,q.x,typeof(q.x),q.x=1 FROM q ORDER BY q.ord",

    "WITH q(ord,x) AS MATERIALIZED ("
    "SELECT 1,NULL AS x UNION ALL SELECT 2,'1' UNION ALL SELECT 3,v FROM typed_num"
    ") SELECT q.ord,q.x,typeof(q.x),q.x='1' FROM q ORDER BY q.ord"
};

int main(int argc, char **argv){
    const char *fbPath = argc>1 ? argv[1] : "fb_src/build/libsqlite3-fb.so";
    void *handle = 0;
    DbOpenFn fbOpen = 0;
    DbCloseFn fbClose = 0;
    DbExecFn fbExec = 0;
    DbFreeFn fbFree = 0;
    DbVersionFn fbVersion = 0;
    sqlite3 *cDb = 0;
    sqlite3 *fbDb = 0;
    char *cError = 0;
    char *fbError = 0;
    size_t i;
    int rc = 0;
    if( argc>2 ){
        fprintf(stderr, "usage: %s [FreeBASIC-library]\n", argv[0]);
        return 7;
    }
    handle = dlmopen(LM_ID_NEWLM, fbPath, RTLD_NOW | RTLD_LOCAL);
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
        fprintf(stderr, "FreeBASIC API lookup failed\n");
        rc = 2;
        goto cleanup;
    }
    if( strcmp(sqlite3_libversion(), fbVersion())!=0 ){
        fprintf(stderr, "version mismatch C=%s FB=%s\n", sqlite3_libversion(), fbVersion());
        rc = 3;
        goto cleanup;
    }
    if( sqlite3_open(":memory:", &cDb)!=SQLITE_OK || fbOpen(":memory:", &fbDb)!=SQLITE_OK ){
        fprintf(stderr, "database open failed\n");
        rc = 4;
        goto cleanup;
    }
    if( sqlite3_exec(cDb, setupSql, 0, 0, &cError)!=SQLITE_OK ||
        fbExec(fbDb, setupSql, 0, 0, &fbError)!=SQLITE_OK ){
        fprintf(stderr, "setup failed C=%s FB=%s\n", cError ? cError : "", fbError ? fbError : "");
        rc = 5;
        goto cleanup;
    }
    if( cError ) sqlite3_free(cError);
    if( fbError ) fbFree(fbError);
    cError = 0;
    fbError = 0;
    for(i=0; i<sizeof(queries)/sizeof(queries[0]); i++){
        QueryResult cResult, fbResult;
        int cRc = run(sqlite3_exec, cDb, queries[i], &cResult, &cError);
        int fbRc = run(fbExec, fbDb, queries[i], &fbResult, &fbError);
        if( cRc!=SQLITE_OK || fbRc!=SQLITE_OK ){
            fprintf(stderr, "query %zu unexpectedly failed rc C=%d FB=%d\nSQL: %s\nC error: %s\nFB error: %s\n",
                    i+1, cRc, fbRc, queries[i], cError ? cError : "", fbError ? fbError : "");
            rc = 6;
        }else if( cRc!=fbRc || cResult.rows!=fbResult.rows || cResult.hash!=fbResult.hash ){
            fprintf(stderr, "mismatch query %zu rc C=%d FB=%d rows C=%u FB=%u hash C=%016llx FB=%016llx\nSQL: %s\nC error: %s\nFB error: %s\n",
                    i+1, cRc, fbRc, cResult.rows, fbResult.rows,
                    (unsigned long long)cResult.hash, (unsigned long long)fbResult.hash,
                    queries[i], cError ? cError : "", fbError ? fbError : "");
            rc = 6;
        }else{
            printf("query %zu matched (%u rows)\n", i+1, cResult.rows);
        }
        if( cError ) sqlite3_free(cError);
        if( fbError ) fbFree(fbError);
        cError=0; fbError=0;
    }
    if( runAffinityMatrix(
            sqlite3_exec, cDb, sqlite3_free, fbExec, fbDb, fbFree)!=0 ){
        rc = 8;
    }
cleanup:
    if( cError ) sqlite3_free(cError);
    if( fbError && fbFree ) fbFree(fbError);
    if( cDb ) sqlite3_close(cDb);
    if( fbDb && fbClose ) fbClose(fbDb);
    if( handle ) dlclose(handle);
    return rc;
}
/* end of sqlite_select_transform_diff.c */
