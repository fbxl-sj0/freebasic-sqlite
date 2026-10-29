/*
 * Project: SQLite FreeBASIC port
 * -----------------------------
 *
 * File: sqlite_soundex_api_smoke.c
 *
 * Purpose:
 *
 *     Capture deterministic SQLITE_SOUNDEX results through SQLite's public C API.
 *
 * Responsibilities:
 *
 *     - Query representative names, NULL, and nonalphabetic text.
 *     - Print stable rows for comparison between C and FreeBASIC libraries.
 *
 * This file intentionally does NOT contain:
 *
 *     - Soundex implementation code.
 *     - Changes to upstream test scripts.
 */

#include <stdio.h>
#include <sqlite3.h>

struct soundex_case {
  const char *input;
  int is_null;
};

static const struct soundex_case cases[] = {
  { "Robert", 0 },
  { "Rupert", 0 },
  { "Rubin", 0 },
  { "Ashcraft", 0 },
  { "Ashcroft", 0 },
  { "Tymczak", 0 },
  { "Pfister", 0 },
  { "A", 0 },
  { 0, 1 },
  { "123", 0 }
};

int main(void){
  sqlite3 *db = 0;
  int rc = sqlite3_open_v2(":memory:", &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, 0);
  int i;
  if( rc!=SQLITE_OK ){
    fprintf(stderr, "sqlite3_open_v2 failed: %d\n", rc);
    if( db!=0 ) sqlite3_close(db);
    return 1;
  }

  for(i=0; i<(int)(sizeof(cases)/sizeof(cases[0])); i++){
    sqlite3_stmt *stmt = 0;
    const unsigned char *value;
    rc = sqlite3_prepare_v2(db, "SELECT soundex(?1)", -1, &stmt, 0);
    if( rc!=SQLITE_OK ) goto failed;
    if( cases[i].is_null ){
      rc = sqlite3_bind_null(stmt, 1);
    }else{
      rc = sqlite3_bind_text(stmt, 1, cases[i].input, -1, SQLITE_STATIC);
    }
    if( rc!=SQLITE_OK ){
      sqlite3_finalize(stmt);
      goto failed;
    }
    rc = sqlite3_step(stmt);
    if( rc!=SQLITE_ROW ){
      sqlite3_finalize(stmt);
      goto failed;
    }
    value = sqlite3_column_text(stmt, 0);
    if( value==0 ){
      puts("<NULL>");
    }else{
      printf("%s\n", value);
    }
    rc = sqlite3_finalize(stmt);
    if( rc!=SQLITE_OK ) goto failed;
  }

  rc = sqlite3_close(db);
  if( rc!=SQLITE_OK ) return 2;
  return 0;

failed:
  fprintf(stderr, "soundex query failed at row %d: %d: %s\n",
      i, rc, sqlite3_errmsg(db));
  sqlite3_close(db);
  return 3;
}

/* end of sqlite_soundex_api_smoke.c */
