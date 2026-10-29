/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_api_armor_preupdate_null_smoke.c

    Purpose:

        Check null-handle API Armor behavior for the pre-update value APIs.

    Responsibilities:

        - Verify sqlite3_preupdate_old() rejects a NULL connection and
          clears the output value.
        - Verify sqlite3_preupdate_new() has the same behavior.

    This file intentionally does NOT contain:

        - SQLite implementation code or changes to upstream tests.
        - A test of valid pre-update callback state.
*/

#include <sqlite3.h>
#include <stdio.h>

#if !defined(SQLITE_ENABLE_PREUPDATE_HOOK)
# error "This smoke test requires SQLITE_ENABLE_PREUPDATE_HOOK"
#endif

int main(void){
  sqlite3_value *pValue = 0;
  int rc;

  rc = sqlite3_preupdate_old(0, 0, &pValue);
  if( rc!=SQLITE_MISUSE || pValue!=0 ){
    fprintf(stderr, "sqlite3_preupdate_old returned %d\n", rc);
    return 1;
  }

  rc = sqlite3_preupdate_new(0, 0, &pValue);
  if( rc!=SQLITE_MISUSE || pValue!=0 ){
    fprintf(stderr, "sqlite3_preupdate_new returned %d\n", rc);
    return 1;
  }
  return 0;
}

/* end of sqlite_api_armor_preupdate_null_smoke.c */
