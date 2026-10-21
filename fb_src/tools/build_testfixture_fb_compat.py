"""
Project: SQLite FreeBASIC port
-----------------------------

File: build_testfixture_fb_compat.py

Purpose:

    Build the unchanged upstream Tcl test suite's C support against the
    FreeBASIC engine while routing its private-layout reads through accessors.

Responsibilities:

    - Copy the two upstream C support files that inspect private layouts.
    - Route VDBE flags, connection encoding and database slots, pager stats,
          raw B-tree handles, cursor ownership, and mutex reads through test-only
          FreeBASIC or public API accessors.
    - Ask the configured SQLite Makefile to link a separate compatibility
      fixture against libsqlite3-fb-testfixture-config-sync.so.
    - Allow isolated support-source directories for side-by-side test profiles.

This file intentionally does NOT contain:

    - Changes to upstream Tcl tests or checked-in upstream C support files.
    - A C engine build or any FreeBASIC SQLite implementation.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


def replace_once(source: str, old: str, new: str, expected: int = 1) -> str:
    """Replace a checked source fragment and fail if upstream drifted."""
    count = source.count(old)
    if count != expected:
        raise ValueError(f"expected {expected} occurrence(s), found {count}: {old}")
    return source.replace(old, new)


def replace_in_function(source: str, signature: str, old: str, new: str) -> str:
    """Replace a checked fragment within one C function body."""
    start = source.find(signature)
    if start < 0:
        raise ValueError(f"function signature not found: {signature}")
    end = source.find("\n}\n", start)
    if end < 0:
        raise ValueError(f"function end not found: {signature}")
    function = source[start : end + 2]
    function = replace_once(function, old, new)
    return source[:start] + function + source[end + 2 :]


def patched_test_support(repo: Path, build_dir: Path) -> list[Path]:
    """Create temporary C test support copies that call FreeBASIC accessors."""
    build_dir.mkdir(parents=True, exist_ok=True)

    test1 = (repo / "src/test1.c").read_text(encoding="utf-8")
    test1 = replace_once(
        test1,
        "#include <string.h>\n",
        "#include <string.h>\n"
        "\n"
        "/* The FreeBASIC VDBE has a different private field layout. */\n"
        "extern int sqlite3TestVdbeUsesStatementJournal(sqlite3_stmt *);\n"
        "extern int sqlite3TestConnectionEncoding(sqlite3 *);\n"
        "extern int sqlite3TestConnectionDatabaseCount(sqlite3 *);\n"
        "extern int sqlite3TestConnectionMallocFailed(sqlite3 *);\n"
        "extern void *sqlite3TestConnectionBtree(sqlite3 *, int);\n",
    )
    test1 = replace_once(
        test1,
        "Tcl_NewBooleanObj(((Vdbe *)pStmt)->usesStmtJournal)",
        "Tcl_NewBooleanObj(sqlite3TestVdbeUsesStatementJournal(pStmt))",
    )
    test1 = replace_once(test1, "int enc = ENC(db);", "int enc = sqlite3TestConnectionEncoding(db);")
    test1 = replace_once(
        test1,
        'db, "test_collate", ENC(db), SQLITE_INT_TO_PTR(enc), test_collate_func);',
        'db, "test_collate", sqlite3TestConnectionEncoding(db), '
        'SQLITE_INT_TO_PTR(enc), test_collate_func);',
    )
    test1 = replace_once(
        test1,
        "sqlite3_mutex_enter(db->mutex)",
        "sqlite3_mutex_enter(sqlite3_db_mutex(db))",
        4,
    )
    test1 = replace_once(
        test1,
        "sqlite3_mutex_leave(db->mutex)",
        "sqlite3_mutex_leave(sqlite3_db_mutex(db))",
        4,
    )
    test1 = replace_once(
        test1,
        "if( db->mallocFailed ){\n",
        "if( sqlite3TestConnectionMallocFailed(db) ){\n",
        2,
    )
    pager_refcounts_match = re.search(
        r"static int SQLITE_TCLAPI test_pager_refcounts\(.*?\n\}",
        test1,
        re.DOTALL,
    )
    if pager_refcounts_match is None:
        raise ValueError("cannot locate upstream test_pager_refcounts helper")
    pager_refcounts = pager_refcounts_match.group(0)
    pager_refcounts = replace_once(
        pager_refcounts,
        "  int v, *a;\n",
        "  int v, *a;\n  Btree *pBtree;\n  Pager *pPager;\n",
    )
    pager_refcounts = replace_once(
        pager_refcounts,
        """  for(i=0; i<db->nDb; i++){
    if( db->aDb[i].pBt==0 ){
      v = -1;
    }else{
      sqlite3_mutex_enter(sqlite3_db_mutex(db));
      a = sqlite3PagerStats(sqlite3BtreePager(db->aDb[i].pBt));
      v = a[0];
      sqlite3_mutex_leave(sqlite3_db_mutex(db));
    }
""",
        """  for(i=0; i<sqlite3TestConnectionDatabaseCount(db); i++){
    pBtree = (Btree *)sqlite3TestConnectionBtree(db, i);
    if( pBtree==0 ){
      v = -1;
    }else{
      sqlite3_mutex_enter(sqlite3_db_mutex(db));
      pPager = sqlite3BtreePager(pBtree);
      a = pPager ? sqlite3PagerStats(pPager) : 0;
      v = a ? a[0] : -1;
      sqlite3_mutex_leave(sqlite3_db_mutex(db));
    }
""",
    )
    test1 = replace_once(test1, pager_refcounts_match.group(0), pager_refcounts)
    test1_copy = build_dir / "test1_fb_compat.c"
    test1_copy.write_text(test1, encoding="utf-8")

    test3 = (repo / "src/test3.c").read_text(encoding="utf-8")
    test3 = replace_once(
        test3,
        "extern const char *sqlite3ErrName(int);\n",
        "extern const char *sqlite3ErrName(int);\n"
        "extern void *sqlite3TestConnectionBtree(sqlite3 *, int);\n"
        "extern sqlite3 *sqlite3TestBtreeDatabase(Btree *);\n"
        "extern Btree *sqlite3TestCursorBtree(BtCursor *);\n",
    )
    test3 = replace_once(
        test3,
        """/*
** A bogus sqlite3 connection structure for use in the btree
** tests.
*/
static sqlite3 sDb;
static int nRefSqlite3 = 0;
""",
        """/*
** The FreeBASIC engine owns its connection and B-tree layouts. Keep each
** raw B-tree test handle paired with its public connection so this C helper
** does not construct or inspect FreeBASIC-private records.
*/
typedef struct FBBtreeTestRef FBBtreeTestRef;
struct FBBtreeTestRef {
  Btree *pBt;
  sqlite3 *db;
  sqlite3_mutex *mutex;
  FBBtreeTestRef *pNext;
};
static FBBtreeTestRef *pFBBtreeTestRef = 0;
""",
    )
    test3 = replace_once(
        test3,
        """  Btree *pBt;
  int rc, nCache;
  int n;
  char *zFilename;
""",
        """  Btree *pBt;
  sqlite3 *db = 0;
  sqlite3_mutex *pMutex;
  FBBtreeTestRef *pRef;
  int rc, nCache;
  int n;
  char *zFilename;
""",
    )
    test3 = replace_once(
        test3,
        """  nRefSqlite3++;
  if( nRefSqlite3==1 ){
    sDb.pVfs = sqlite3_vfs_find(0);
    sDb.mutex = sqlite3MutexAlloc(SQLITE_MUTEX_RECURSIVE);
    sqlite3_mutex_enter(sDb.mutex);
  }
""",
        "",
    )
    test3 = replace_once(
        test3,
        """  rc = sqlite3BtreeOpen(sDb.pVfs, zFilename, &sDb, &pBt, 0, 
     SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_MAIN_DB);
  sqlite3_free(zFilename);
  if( rc!=SQLITE_OK ){
    Tcl_AppendResult(interp, sqlite3ErrName(rc), NULL);
    return TCL_ERROR;
  }
  sqlite3BtreeSetCacheSize(pBt, nCache);
  Tcl_AppendResult(interp, sqlite3TestPtrToText(pBt), NULL);
""",
        """  rc = sqlite3_open_v2(zFilename, &db,
     SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, 0);
  sqlite3_free(zFilename);
  if( rc!=SQLITE_OK ){
    if( db ) sqlite3_close(db);
    Tcl_AppendResult(interp, sqlite3ErrName(rc), NULL);
    return TCL_ERROR;
  }
  pBt = sqlite3TestConnectionBtree(db, 0);
  pMutex = sqlite3_db_mutex(db);
  if( pBt==0 || pMutex==0 ){
    sqlite3_close(db);
    Tcl_AppendResult(interp, sqlite3ErrName(SQLITE_ERROR), NULL);
    return TCL_ERROR;
  }
  sqlite3_mutex_enter(pMutex);
  pRef = sqlite3_malloc(sizeof(*pRef));
  if( pRef==0 ){
    sqlite3_mutex_leave(pMutex);
    sqlite3_close(db);
    Tcl_AppendResult(interp, sqlite3ErrName(SQLITE_NOMEM), NULL);
    return TCL_ERROR;
  }
  pRef->pBt = pBt;
  pRef->db = db;
  pRef->mutex = pMutex;
  pRef->pNext = pFBBtreeTestRef;
  pFBBtreeTestRef = pRef;
  sqlite3BtreeSetCacheSize(pBt, nCache);
  Tcl_AppendResult(interp, sqlite3TestPtrToText(pBt), NULL);
""",
    )
    test3 = replace_in_function(
        test3,
        "static int SQLITE_TCLAPI btree_close(",
        """  Btree *pBt;
  int rc;
  if( argc!=2 ){""",
        """  Btree *pBt;
  FBBtreeTestRef **ppRef;
  FBBtreeTestRef *pRef;
  int rc;
  if( argc!=2 ){""",
    )
    test3 = replace_once(
        test3,
        """  pBt = sqlite3TestTextToPtr(argv[1]);
  rc = sqlite3BtreeClose(pBt);
  if( rc!=SQLITE_OK ){
    Tcl_AppendResult(interp, sqlite3ErrName(rc), NULL);
    return TCL_ERROR;
  }
  nRefSqlite3--;
  if( nRefSqlite3==0 ){
    sqlite3_mutex_leave(sDb.mutex);
    sqlite3_mutex_free(sDb.mutex);
    sDb.mutex = 0;
    sDb.pVfs = 0;
  }
""",
        """  pBt = sqlite3TestTextToPtr(argv[1]);
  for(ppRef=&pFBBtreeTestRef; *ppRef && (*ppRef)->pBt!=pBt;
      ppRef=&(*ppRef)->pNext){}
  if( *ppRef==0 ){
    Tcl_AppendResult(interp, sqlite3ErrName(SQLITE_MISUSE), NULL);
    return TCL_ERROR;
  }
  pRef = *ppRef;
  sqlite3_mutex_leave(pRef->mutex);
  rc = sqlite3_close(pRef->db);
  if( rc!=SQLITE_OK ){
    sqlite3_mutex_enter(pRef->mutex);
    Tcl_AppendResult(interp, sqlite3ErrName(rc), NULL);
    return TCL_ERROR;
  }
  *ppRef = pRef->pNext;
  sqlite3_free(pRef);
""",
    )
    test3 = replace_once(
        test3,
        "pCur->pBtree->db->mutex",
        "sqlite3_db_mutex(sqlite3TestBtreeDatabase(sqlite3TestCursorBtree(pCur)))",
        2,
    )
    test3 = replace_once(
        test3,
        "pBt->db->mutex",
        "sqlite3_db_mutex(sqlite3TestBtreeDatabase(pBt))",
        10,
    )
    cursor_btree_count = test3.count("pCur->pBtree")
    if cursor_btree_count != 11:
        raise ValueError(
            f"expected 11 cursor B-tree reads in test3.c, found {cursor_btree_count}"
        )
    test3 = test3.replace("pCur->pBtree", "sqlite3TestCursorBtree(pCur)")
    test3 = replace_once(
        test3,
        "  pBt = db->aDb[iDb].pBt;",
        "  pBt = sqlite3TestConnectionBtree(db, iDb);",
    )
    test3_copy = build_dir / "test3_fb_compat.c"
    test3_copy.write_text(test3, encoding="utf-8")

    return [test1_copy, test3_copy]


def test_support_sources(repo: Path) -> list[Path]:
    """Read the configured Makefile's expanded C test-support source list."""
    result = subprocess.run(
        ["make", "-pn"],
        cwd=repo,
        check=True,
        capture_output=True,
        text=True,
    )
    match = re.search(r"(?m)^TESTSRC = (.+)$", result.stdout)
    if match is None:
        raise RuntimeError("configured Makefile did not expose TESTSRC")

    source_list = match.group(1).replace("$(TOP)", str(repo))
    sources = [Path(item) for item in source_list.split()]
    missing = [path for path in sources if not path.is_file()]
    if missing:
        raise RuntimeError(f"missing test support source: {missing[0]}")
    return sources


def testfixture_flags(repo: Path) -> str:
    """Read the configured C fixture flags before adding profile defines."""
    result = subprocess.run(
        ["make", "-pn"],
        cwd=repo,
        check=True,
        capture_output=True,
        text=True,
    )
    match = re.search(r"(?m)^TESTFIXTURE_FLAGS = (.+)$", result.stdout)
    if match is None:
        raise RuntimeError("configured Makefile did not expose TESTFIXTURE_FLAGS")
    return match.group(1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--suffix",
        default="_fb_compat",
        help="Make target suffix for the fixture executable (default: _fb_compat)",
    )
    parser.add_argument(
        "--library",
        type=Path,
        help="FreeBASIC test library to link (default: config-sync profile)",
    )
    parser.add_argument(
        "--build-dir",
        type=Path,
        help="directory for patched C sources and the fixture build log",
    )
    parser.add_argument(
        "--c-define",
        action="append",
        default=[],
        metavar="NAME[=VALUE]",
        help="extra compile definition for C test support; repeat as needed",
    )
    parser.add_argument(
        "--c-undefine",
        action="append",
        default=[],
        metavar="NAME",
        help="remove a configured feature from C test support; repeat as needed",
    )
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[2]
    fb_root = repo / "fb_src"
    build_root = fb_root / "build"
    library = (
        args.library.resolve()
        if args.library is not None
        else build_root / "libsqlite3-fb-testfixture-config-sync.so"
    )
    library_dir = library.parent
    build_dir = (
        args.build_dir.resolve()
        if args.build_dir is not None
        else build_root / "testfixture-c-compat-sources"
    )

    if not (repo / "Makefile").is_file():
        print("run ./configure --dev before building the Tcl fixture", file=sys.stderr)
        return 2
    if not library.is_file():
        print(f"missing FreeBASIC test library: {library}", file=sys.stderr)
        return 2

    try:
        copies = patched_test_support(repo, build_dir)
        sources = test_support_sources(repo)
        fixture_flags = testfixture_flags(repo)
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"cannot prepare test fixture: {error}", file=sys.stderr)
        return 2

    replacements = {
        repo / "src/test1.c": copies[0],
        repo / "src/test3.c": copies[1],
    }
    sources = [replacements.get(path, path) for path in sources]
    source_value = " ".join(str(path) for path in sources)
    if args.c_define:
        fixture_flags += " " + " ".join(f"-D{define}" for define in args.c_define)
    if args.c_undefine:
        fixture_flags += " " + " ".join(f"-U{define}" for define in args.c_undefine)
    fixture_sources = (
        f"$(TESTSRC) tclsqlite-ex.c {repo / 'src/global.c'} "
        f"{fb_root / 'tests/sqlite_testfixture_config_sync.c'}"
    )
    library_name = library.name
    if library_name.startswith("lib"):
        library_name = library_name[3:]
    if library_name.endswith(".so"):
        library_name = library_name[:-3]
    linker_flags = (
        f"-L{library_dir} -l{library_name} "
        f"-Wl,-rpath,{library_dir} -Wl,-E"
    )
    make_args = [
        "make",
        f"testfixture{args.suffix}",
        f"T.exe={args.suffix}",
        f"TESTSRC={source_value}",
        f"TESTFIXTURE_FLAGS={fixture_flags}",
        f"TESTFIXTURE_SRC={fixture_sources}",
        f"LDFLAGS.libsqlite3={linker_flags}",
    ]
    log_path = build_dir / "build.log"
    try:
        result = subprocess.run(
            make_args,
            cwd=repo,
            capture_output=True,
            text=True,
        )
    except OSError as error:
        print(f"cannot run Make: {error}", file=sys.stderr)
        return 2

    log_path.write_text(result.stdout + result.stderr, encoding="utf-8")
    fixture = repo / f"testfixture{args.suffix}"
    if result.returncode != 0 or not fixture.is_file():
        print(f"fixture build failed; see {log_path}", file=sys.stderr)
        return result.returncode or 1

    print(f"Built {fixture}")
    print(f"Build log: {log_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# end of build_testfixture_fb_compat.py
