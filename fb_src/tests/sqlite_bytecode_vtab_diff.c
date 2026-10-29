/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_bytecode_vtab_diff.c

    Purpose:

        Compare the optional bytecode() and tables_used() virtual tables
        through SQLite's public C API.

    Responsibilities:

        - Exercise bytecode rows, comments, P4 rendering, and row IDs.
        - Exercise table/index rows and trigger subprogram labels.
        - Emit stable, escaped rows for direct C/FreeBASIC comparison.

    This file intentionally does NOT contain:

        - SQLite engine implementations.
        - Changes to upstream Tcl tests or C support.
*/

#include <sqlite3.h>
#include <stdio.h>
#include <string.h>

static int run_sql(sqlite3 *db, const char *sql){
  char *zError = 0;
  int rc = sqlite3_exec(db, sql, 0, 0, &zError);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "%s: %s (%d)\n", sql,
            zError ? zError : sqlite3_errmsg(db), rc);
  }
  sqlite3_free(zError);
  return rc;
}

static int dump_query(sqlite3 *db, const char *zLabel, const char *zSql){
  sqlite3_stmt *pStmt = 0;
  int rc = sqlite3_prepare_v2(db, zSql, -1, &pStmt, 0);
  int nRow = 0;
  int nColumn;
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "%s prepare: %s (%d)\n", zLabel,
            sqlite3_errmsg(db), rc);
    return rc;
  }
  nColumn = sqlite3_column_count(pStmt);
  printf("Q %s %d\n", zLabel, nColumn);
  while( (rc=sqlite3_step(pStmt))==SQLITE_ROW ){
    int i;
    printf("R");
    for(i=0; i<nColumn; i++){
      const unsigned char *pText;
      int nByte;
      int j;
      if( sqlite3_column_type(pStmt, i)==SQLITE_NULL ){
        printf("|N");
        continue;
      }
      pText = sqlite3_column_text(pStmt, i);
      nByte = sqlite3_column_bytes(pStmt, i);
      if( pText==0 && nByte!=0 ){
        sqlite3_finalize(pStmt);
        return SQLITE_NOMEM;
      }
      printf("|%d:", nByte);
      for(j=0; j<nByte; j++) printf("%02x", pText[j]);
    }
    printf("\n");
    nRow++;
  }
  if( rc!=SQLITE_DONE ){
    fprintf(stderr, "%s step: %s (%d)\n", zLabel,
            sqlite3_errmsg(db), rc);
    sqlite3_finalize(pStmt);
    return rc;
  }
  rc = sqlite3_finalize(pStmt);
  if( rc!=SQLITE_OK ) return rc;
  printf("E %s rows=%d\n", zLabel, nRow);
  return SQLITE_OK;
}

static int dump_error(sqlite3 *db, const char *zLabel, const char *zSql){
  sqlite3_stmt *pStmt = 0;
  int rc = sqlite3_prepare_v2(db, zSql, -1, &pStmt, 0);
  if( rc==SQLITE_OK ) rc = sqlite3_step(pStmt);
  if( rc==SQLITE_ROW || rc==SQLITE_DONE ){
    if( pStmt ) sqlite3_finalize(pStmt);
    fprintf(stderr, "%s unexpectedly succeeded\n", zLabel);
    return SQLITE_ERROR;
  }

  {
    const unsigned char *zError = (const unsigned char*)sqlite3_errmsg(db);
    int nError = (int)strlen((const char*)zError);
    int i;
    printf("X %s rc=%d error=", zLabel, rc & 0xff);
    for(i=0; i<nError; i++) printf("%02x", zError[i]);
    printf("\n");
  }
  if( pStmt ) sqlite3_finalize(pStmt);
  return SQLITE_OK;
}

int main(void){
  sqlite3 *db = 0;
  int rc = sqlite3_open(":memory:", &db);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "open: %s (%d)\n", sqlite3_errmsg(db), rc);
    if( db ) sqlite3_close(db);
    return 1;
  }

  if( run_sql(db,
      "CREATE TABLE t1(a INTEGER, b TEXT);"
      "CREATE INDEX i1 ON t1(a);"
      "INSERT INTO t1 VALUES(7, 'seven'), (8, 'eight');"
      "CREATE TRIGGER tr1 AFTER INSERT ON t1 BEGIN"
      " UPDATE t1 SET b=new.b || '! ' WHERE a=new.a;"
      "END;")!=SQLITE_OK ){
    rc = sqlite3_errcode(db);
    goto failed;
  }

  rc = dump_query(db, "bytecode-main",
      "SELECT rowid,addr,opcode,p1,p2,p3,p4,p5,comment,subprog,nexec,ncycle "
      "FROM bytecode('SELECT b FROM t1 INDEXED BY i1 WHERE a=7') "
      "ORDER BY addr");
  if( rc!=SQLITE_OK ) goto failed;

  rc = dump_query(db, "bytecode-main-only",
      "SELECT addr,opcode,p4 FROM "
      "bytecode('INSERT INTO t1 VALUES(9, ''nine'')') "
      "WHERE ncycle IS NULL ORDER BY addr");
  if( rc!=SQLITE_OK ) goto failed;

  rc = dump_query(db, "tables-used-select",
      "SELECT type,schema,name,wr,subprog FROM "
      "tables_used('SELECT b FROM t1 INDEXED BY i1 WHERE a=7') "
      "ORDER BY type,name");
  if( rc!=SQLITE_OK ) goto failed;

  rc = dump_query(db, "tables-used-trigger",
      "SELECT type,schema,name,wr,subprog FROM "
      "tables_used('INSERT INTO t1 VALUES(9, ''nine'')') "
      "ORDER BY subprog,type,name");
  if( rc!=SQLITE_OK ) goto failed;

  rc = dump_query(db, "trigger-program",
      "SELECT DISTINCT subprog FROM "
      "bytecode('INSERT INTO t1 VALUES(9, ''nine'')') "
      "WHERE subprog IS NOT NULL ORDER BY subprog");
  if( rc!=SQLITE_OK ) goto failed;

  rc = dump_error(db, "invalid-inner-sql",
      "SELECT * FROM bytecode('SELECT FROM')");
  if( rc!=SQLITE_OK ) goto failed;
  rc = dump_error(db, "missing-hidden-statement",
      "SELECT * FROM bytecode");
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "close: %s (%d)\n", sqlite3_errstr(rc), rc);
    return 1;
  }
  return 0;

failed:
  fprintf(stderr, "bytecode vtab differential failed: %s (%d)\n",
          sqlite3_errstr(rc), rc);
  if( db ) sqlite3_close(db);
  return 1;
}

/* end of sqlite_bytecode_vtab_diff.c */
