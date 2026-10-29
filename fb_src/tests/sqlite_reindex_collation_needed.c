/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_reindex_collation_needed.c

    Purpose:

        Compare REINDEX behavior when a database connection lazily registers
        a collation through sqlite3_collation_needed().

    Responsibilities:

        - Create a database whose unique indexes use application collations.
        - Reopen it without those collations and install a collation-needed hook.
        - Rebuild one index and verify the resulting index order.

    This file intentionally does NOT contain:

        - SQLite engine implementations.
        - Changes to upstream Tcl tests or C test support.
*/

#include <sqlite3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct CollationState CollationState;
struct CollationState {
  int reverse;
  int calls;
};

typedef struct NeededState NeededState;
struct NeededState {
  CollationState *pCollation;
  int nCall;
  int rc;
};

static int compare_text(void *pContext, int nLeft, const void *pLeft,
                        int nRight, const void *pRight){
  CollationState *pState = (CollationState*)pContext;
  int nCompare = nLeft<nRight ? nLeft : nRight;
  int rc = memcmp(pLeft, pRight, (size_t)nCompare);
  pState->calls++;
  if( rc==0 ) rc = (nLeft>nRight) - (nLeft<nRight);
  if( pState->reverse ) rc = -rc;
  return (rc>0) - (rc<0);
}

static void collation_needed(void *pContext, sqlite3 *db, int eTextRep,
                             const char *zName){
  NeededState *pState = (NeededState*)pContext;
  if( strcmp(zName, "c1")!=0 ) return;
  pState->nCall++;
  pState->rc = sqlite3_create_collation(db, zName, eTextRep,
      pState->pCollation, compare_text);
}

static int exec_sql(sqlite3 *db, const char *zSql){
  char *zError = 0;
  int rc = sqlite3_exec(db, zSql, 0, 0, &zError);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "%s (%d): %s\n", zSql, rc,
            zError ? zError : sqlite3_errmsg(db));
  }
  sqlite3_free(zError);
  return rc;
}

int main(int argc, char **argv){
  static const char *zCreate =
      "CREATE TABLE t2("
      " a TEXT PRIMARY KEY COLLATE c1,"
      " b TEXT UNIQUE COLLATE c2,"
      " c TEXT COLLATE nocase,"
      " d TEXT COLLATE binary"
      ");"
      "INSERT INTO t2 VALUES"
      "('abc','abc','abc','abc'),"
      "('ABCD','ABCD','ABCD','ABCD'),"
      "('bcd','bcd','bcd','bcd'),"
      "('BCDE','BCDE','BCDE','BCDE');";
  static const char *zVerify = "SELECT a FROM t2 ORDER BY a";
  static const char *azExpected[] = {"ABCD", "BCDE", "abc", "bcd"};
  sqlite3 *db = 0;
  sqlite3_stmt *pStmt = 0;
  CollationState reverse = {1, 0};
  CollationState forward = {0, 0};
  NeededState needed = {&forward, 0, SQLITE_OK};
  const char *zFilename;
  int rc;
  int iRow = 0;

  if( argc!=2 ){
    fprintf(stderr, "usage: %s DATABASE\n", argv[0]);
    return 2;
  }
  zFilename = argv[1];

  rc = sqlite3_open(zFilename, &db);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_create_collation(db, "c1", SQLITE_UTF8, &reverse, compare_text);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_create_collation(db, "c2", SQLITE_UTF8, &reverse, compare_text);
  if( rc!=SQLITE_OK ) goto failed;
  rc = exec_sql(db, zCreate);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_close(db);
  db = 0;
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_open(zFilename, &db);
  if( rc!=SQLITE_OK ) goto failed;
  rc = sqlite3_collation_needed(db, &needed, collation_needed);
  if( rc!=SQLITE_OK ) goto failed;
  rc = exec_sql(db, "REINDEX c1");
  if( rc!=SQLITE_OK ) goto failed;
  if( needed.nCall==0 || needed.rc!=SQLITE_OK || forward.calls==0 ){
    fprintf(stderr, "collation-needed callback was not used\n");
    rc = SQLITE_ERROR;
    goto failed;
  }

  rc = sqlite3_prepare_v2(db, zVerify, -1, &pStmt, 0);
  if( rc!=SQLITE_OK ) goto failed;
  while( (rc=sqlite3_step(pStmt))==SQLITE_ROW ){
    const unsigned char *zValue = sqlite3_column_text(pStmt, 0);
    const char *zWanted;
    if( iRow>=4 ){
      fprintf(stderr, "too many rows from REINDEX verification\n");
      rc = SQLITE_CORRUPT;
      goto failed;
    }
    zWanted = azExpected[iRow];
    if( zValue==0 || strcmp((const char*)zValue, zWanted)!=0 ){
      fprintf(stderr, "row %d: expected %s, got %s\n", iRow,
              zWanted, zValue ? (const char*)zValue : "NULL");
      rc = SQLITE_MISMATCH;
      goto failed;
    }
    iRow++;
  }
  if( rc!=SQLITE_DONE ) goto failed;
  rc = sqlite3_finalize(pStmt);
  pStmt = 0;
  if( rc!=SQLITE_OK ) goto failed;
  if( iRow!=4 ){
    fprintf(stderr, "expected four ordered rows, got %d\n", iRow);
    rc = SQLITE_CORRUPT;
    goto failed;
  }

  rc = sqlite3_close(db);
  db = 0;
  if( rc!=SQLITE_OK ) goto failed;
  printf("collation-needed calls=%d comparisons=%d; REINDEX and row order match\n",
         needed.nCall, forward.calls);
  return 0;

failed:
  if( pStmt ) sqlite3_finalize(pStmt);
  if( db ){
    fprintf(stderr, "SQLite error %d: %s\n", rc, sqlite3_errmsg(db));
    sqlite3_close(db);
  }
  return 1;
}

/* end of sqlite_reindex_collation_needed.c */
