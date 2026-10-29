/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_explain_rows_diff.c

    Purpose:

        Compare EXPLAIN result rows from the C and FreeBASIC libraries through
        SQLite's public C API.

    Responsibilities:

        - Build a schema with indexes and trigger subprograms.
        - Capture opcode operands, P4 text, and debug comments.
        - Compare selected SQL results independently of EXPLAIN output.
        - Emit stable, escaped rows for direct C/FreeBASIC comparison.

    This file intentionally does NOT contain:

        - SQLite engine implementations.
        - Changes to upstream Tcl tests or C support.
*/

#include <sqlite3.h>
#include <stdio.h>
#include <string.h>

static int dump_value(sqlite3_stmt *pStmt, int iColumn){
  const unsigned char *pText;
  int nByte;
  int i;
  if( sqlite3_column_type(pStmt, iColumn)==SQLITE_NULL ){
    printf("|N");
    return SQLITE_OK;
  }
  pText = sqlite3_column_text(pStmt, iColumn);
  nByte = sqlite3_column_bytes(pStmt, iColumn);
  if( pText==0 && nByte!=0 ) return SQLITE_NOMEM;
  printf("|%d:", nByte);
  for(i=0; i<nByte; i++) printf("%02x", pText[i]);
  return SQLITE_OK;
}

static int run_sql(sqlite3 *db, const char *zSql){
  char *zError = 0;
  int rc = sqlite3_exec(db, zSql, 0, 0, &zError);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "setup failed: %s (%d)\n",
            zError ? zError : sqlite3_errmsg(db), rc);
  }
  sqlite3_free(zError);
  return rc;
}

static int dump_explain(sqlite3 *db, const char *zLabel, const char *zSql){
  static const char *azColumn[] = {
    "addr", "opcode", "p1", "p2", "p3", "p4", "p5", "comment"
  };
  sqlite3_stmt *pStmt = 0;
  char *zExplain = sqlite3_mprintf("EXPLAIN %s", zSql);
  int rc;
  int nRow = 0;
  int nColumn;
  if( zExplain==0 ) return SQLITE_NOMEM;
  rc = sqlite3_prepare_v2(db, zExplain, -1, &pStmt, 0);
  sqlite3_free(zExplain);
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
      int valueRc = dump_value(pStmt, i);
      if( valueRc!=SQLITE_OK ){
        sqlite3_finalize(pStmt);
        return valueRc;
      }
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

static int dump_result(sqlite3 *db, const char *zLabel, const char *zSql){
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
      int valueRc = dump_value(pStmt, i);
      if( valueRc!=SQLITE_OK ){
        sqlite3_finalize(pStmt);
        return valueRc;
      }
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

int main(void){
  sqlite3 *db = 0;
  int rc = sqlite3_open(":memory:", &db);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "open: %s (%d)\n", sqlite3_errmsg(db), rc);
    if( db ) sqlite3_close(db);
    return 1;
  }

  rc = run_sql(db,
      "CREATE TABLE t(a INTEGER PRIMARY KEY, b TEXT, c INTEGER);"
      "CREATE INDEX i_tb ON t(b);"
      "CREATE TABLE log(a INTEGER, old_b TEXT, new_b TEXT);"
      "CREATE TRIGGER tr_ai AFTER INSERT ON t BEGIN"
      " UPDATE t SET c=coalesce(c,0)+1 WHERE a=new.a;"
      "END;"
      "CREATE TRIGGER tr_au AFTER UPDATE OF b ON t BEGIN"
      " INSERT INTO log VALUES(new.a,old.b,new.b);"
      "END;");
  if( rc!=SQLITE_OK ) goto failed;
  rc = run_sql(db,
      "INSERT INTO t VALUES(1,'x',0),(2,'y',0)");
  if( rc!=SQLITE_OK ) goto failed;

#define DUMP_EXPLAIN(name, sql) \
  do{ rc = dump_explain(db, name, sql); if( rc!=SQLITE_OK ) goto failed; }while(0)

  DUMP_EXPLAIN("indexed-select",
      "SELECT b FROM t WHERE b='x'");
  DUMP_EXPLAIN("aggregate-subquery",
      "SELECT (SELECT max(a) FROM t) FROM t AS x "
      "WHERE EXISTS(SELECT 1 FROM t AS y WHERE y.a=x.a)");
  DUMP_EXPLAIN("aggregate-limit-zero",
      "SELECT (SELECT max(a) FROM t LIMIT 0) FROM t AS x "
      "WHERE EXISTS(SELECT 1 FROM t AS y WHERE y.a=x.a)");
  DUMP_EXPLAIN("aggregate-limit-expression",
      "SELECT (SELECT max(a) FROM t LIMIT abs(-1)) FROM t AS x "
      "WHERE EXISTS(SELECT 1 FROM t AS y WHERE y.a=x.a)");
  DUMP_EXPLAIN("aggregate-offset",
      "SELECT (SELECT max(a) FROM t LIMIT 1 OFFSET 1) FROM t AS x "
      "WHERE EXISTS(SELECT 1 FROM t AS y WHERE y.a=x.a)");
  DUMP_EXPLAIN("grouped-aggregate-subquery",
      "SELECT (SELECT sum(a) FROM t GROUP BY a ORDER BY a LIMIT 1) "
      "FROM t AS x WHERE x.a=1");
  DUMP_EXPLAIN("insert-trigger",
      "INSERT INTO t(b,c) VALUES('x',0)");
  DUMP_EXPLAIN("update-trigger",
      "UPDATE t SET b=b||'!' WHERE a=1");
  DUMP_EXPLAIN("delete",
      "DELETE FROM t WHERE a=1");
  DUMP_EXPLAIN("distinct-sort",
      "SELECT DISTINCT b FROM t ORDER BY b");

  if( dump_result(db, "indexed-result",
      "SELECT b FROM t WHERE b='x'")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "aggregate-subquery-result",
      "SELECT (SELECT max(a) FROM t) FROM t AS x "
      "WHERE EXISTS(SELECT 1 FROM t AS y WHERE y.a=x.a)")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "aggregate-limit-zero-result",
      "SELECT (SELECT max(a) FROM t LIMIT 0) FROM t AS x "
      "WHERE EXISTS(SELECT 1 FROM t AS y WHERE y.a=x.a)")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "aggregate-limit-expression-result",
      "SELECT (SELECT max(a) FROM t LIMIT abs(-1)) FROM t AS x "
      "WHERE EXISTS(SELECT 1 FROM t AS y WHERE y.a=x.a)")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "aggregate-offset-result",
      "SELECT (SELECT max(a) FROM t LIMIT 1 OFFSET 1) FROM t AS x "
      "WHERE EXISTS(SELECT 1 FROM t AS y WHERE y.a=x.a)")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "grouped-aggregate-subquery-result",
      "SELECT (SELECT sum(a) FROM t GROUP BY a ORDER BY a LIMIT 1) "
      "FROM t AS x WHERE x.a=1")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "grouped-sort-limit-zero-result",
      "SELECT b COLLATE NOCASE, avg(c) FROM t GROUP BY b COLLATE NOCASE "
      "HAVING coalesce(sum(c),0)>=0 ORDER BY 1 DESC LIMIT 0")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "grouped-sort-limit-zero-offset-result",
      "SELECT b COLLATE NOCASE, avg(c) FROM t GROUP BY b COLLATE NOCASE "
      "HAVING coalesce(sum(c),0)>=0 ORDER BY 1 DESC LIMIT 0 OFFSET 2")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "distinct-sort-result",
      "SELECT DISTINCT b FROM t ORDER BY b")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "top-level-aggregate-limit-zero-result",
      "SELECT max(a) FROM t LIMIT 0")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "top-level-aggregate-limit-one-result",
      "SELECT max(a) FROM t LIMIT 1")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "top-level-aggregate-offset-result",
      "SELECT max(a) FROM t LIMIT 1 OFFSET 1")!=SQLITE_OK ) goto failed;

  if( run_sql(db, "INSERT INTO t(b,c) VALUES('z',0)")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "insert-trigger-result",
      "SELECT a,b,c FROM t WHERE b='z'")!=SQLITE_OK ) goto failed;
  if( run_sql(db, "UPDATE t SET b=b||'!' WHERE a=1")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "update-trigger-result",
      "SELECT a,old_b,new_b FROM log ORDER BY a")!=SQLITE_OK ) goto failed;
  if( run_sql(db, "DELETE FROM t WHERE a=2")!=SQLITE_OK ) goto failed;
  if( dump_result(db, "delete-result",
      "SELECT a,b,c FROM t ORDER BY a")!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "close: %s (%d)\n", sqlite3_errstr(rc), rc);
    return 1;
  }
  return 0;

failed:
  fprintf(stderr, "EXPLAIN differential failed: %s (%d)\n",
          sqlite3_errstr(rc), rc);
  if( db ) sqlite3_close(db);
  return 1;
}

/* end of sqlite_explain_rows_diff.c */
