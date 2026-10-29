/*
    Project: SQLite FreeBASIC port
    ------------------------------

    File: sqlite_windows_spatial_smoke.c

    Purpose:

        Exercise the R-Tree and GeoPoly modules through SQLite's public C API
        on a Windows DLL build.

    Responsibilities:

        - Write R-Tree and GeoPoly rows to a file-backed database.
        - Reopen the database and verify spatial overlap queries.
        - Return an exact process status without requiring CRT startup code.

    This file intentionally does NOT contain:

        - R-Tree, GeoPoly, or SQLite implementation code.
        - A port or modification of upstream test scripts.
*/

#include <sqlite3.h>

static int expectRtreeRows(sqlite3 *db){
  static const sqlite3_int64 expected[] = {1, 3};
  sqlite3_stmt *stmt = 0;
  int rc = sqlite3_prepare_v2(db,
      "SELECT id FROM rt "
      "WHERE x1<=1.5 AND x2>=1.5 AND y1<=1.5 AND y2>=1.5 "
      "ORDER BY id",
      -1, &stmt, 0);
  int i;
  if( rc!=SQLITE_OK ) return rc;
  for(i=0; i<2; i++){
    rc = sqlite3_step(stmt);
    if( rc!=SQLITE_ROW || sqlite3_column_int64(stmt, 0)!=expected[i] ){
      sqlite3_finalize(stmt);
      return SQLITE_CORRUPT;
    }
  }
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_DONE ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  return sqlite3_finalize(stmt);
}

static int expectGeoPolyRow(sqlite3 *db){
  sqlite3_stmt *stmt = 0;
  int rc = sqlite3_prepare_v2(db,
      "SELECT name,geopoly_area(_shape) FROM geo "
      "WHERE geopoly_overlap(_shape,"
      "'[[1,1],[3,1],[3,3],[1,3],[1,1]]')",
      -1, &stmt, 0);
  const unsigned char *name;
  double area;
  if( rc!=SQLITE_OK ) return rc;
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_ROW ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  name = sqlite3_column_text(stmt, 0);
  area = sqlite3_column_double(stmt, 1);
  if( name==0 || name[0]!='s' || name[1]!='q' || name[2]!='u' ||
      name[3]!='a' || name[4]!='r' || name[5]!='e' || name[6]!=0 ||
      area<3.99 || area>4.01 ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  rc = sqlite3_step(stmt);
  if( rc!=SQLITE_DONE ){
    sqlite3_finalize(stmt);
    return SQLITE_CORRUPT;
  }
  return sqlite3_finalize(stmt);
}

static int entry(void){
  sqlite3 *db = 0;
  int rc = sqlite3_open_v2(
      "sqlite_windows_spatial_smoke.db",
      &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_exec(db,
      "DROP TABLE IF EXISTS rt;"
      "DROP TABLE IF EXISTS geo;"
      "CREATE VIRTUAL TABLE rt USING rtree(id,x1,x2,y1,y2);"
      "INSERT INTO rt VALUES"
      "(1,0,2,0,2),(2,4,5,4,5),(3,1,3,1,3);"
      "CREATE VIRTUAL TABLE geo USING geopoly(name);"
      /* Counter-clockwise winding gives geopoly_area() a positive result. */
      "INSERT INTO geo(_shape,name) VALUES"
      "('[[0,0],[2,0],[2,2],[0,2],[0,0]]','square'),"
      "('[[4,4],[6,4],[6,6],[4,6],[4,4]]','distant');",
      0, 0, 0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  db = 0;
  if( rc!=SQLITE_OK ) return rc;

  rc = sqlite3_open_v2(
      "sqlite_windows_spatial_smoke.db",
      &db,
      SQLITE_OPEN_READWRITE,
      0
  );
  if( rc!=SQLITE_OK ) goto failed;

  rc = expectRtreeRows(db);
  if( rc!=SQLITE_OK ) goto failed;
  rc = expectGeoPolyRow(db);
  if( rc!=SQLITE_OK ) goto failed;

  rc = sqlite3_close(db);
  return rc;

failed:
  if( db!=0 ) sqlite3_close(db);
  return rc==SQLITE_OK ? SQLITE_ERROR : rc;
}

__declspec(dllimport) void __stdcall ExitProcess(unsigned int exitCode);

void start(void){
  ExitProcess((unsigned int)entry());
}

/* end of sqlite_windows_spatial_smoke.c */
