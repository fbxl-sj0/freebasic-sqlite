#!/bin/sh
#
# Project: SQLite FreeBASIC port
# ------------------------------
#
# File: run_apple_proxy_policy_sim.sh
#
# Purpose:
#
#     Exercise the Apple proxy-lock policy on Linux with the local Darwin
#     statfs shim. This checks the FreeBASIC proxy path without claiming to
#     replace a native Apple filesystem test.
#
# Responsibilities:
#
#     - Build Apple-guarded FreeBASIC and upstream C reference libraries.
#     - Build the unchanged C API smoke host against each library.
#     - Run remote, local, forced-on, forced-off, and FAT-empty-file cases.
#     - Compare and save one short result log for each policy case.
#
# This file intentionally does NOT contain:
#
#     - SQLite engine code.
#     - Changes to upstream Tcl or C tests.
#

set -eu

PROXY_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROXY_REPO_ROOT=$(CDPATH= cd -- "$PROXY_SCRIPT_DIR/../.." && pwd)
PROXY_FB_DIR="$PROXY_REPO_ROOT/fb_src"
PROXY_BUILD_DIR="$PROXY_FB_DIR/build/apple-proxy-simulation"
PROXY_C_INCLUDE="$PROXY_SCRIPT_DIR/apple_proxy_compat_include"
PROXY_SHIM="$PROXY_FB_DIR/build/libsqlite_apple_proxy_statfs_shim.so"
PROXY_HOST="$PROXY_FB_DIR/build/sqlite_apple_proxy_policy_smoke"
PROXY_HOST_NO_STYLE="$PROXY_FB_DIR/build/sqlite_apple_proxy_no_lockstyle_smoke"
PROXY_C_LIBRARY="$PROXY_FB_DIR/build/libsqlite3-c-apple-proxy-sim.so"
PROXY_C_LIBRARY_NO_STYLE="$PROXY_FB_DIR/build/libsqlite3-c-apple-no-lockstyle-sim.so"
PROXY_C_HOST="$PROXY_FB_DIR/build/sqlite_apple_proxy_policy_smoke_c"
PROXY_C_HOST_NO_STYLE="$PROXY_FB_DIR/build/sqlite_apple_proxy_no_lockstyle_smoke_c"
PROXY_LOCK_DIR="$PROXY_BUILD_DIR/locks/"

mkdir -p "$PROXY_BUILD_DIR"

make -C "$PROXY_FB_DIR" -j2 \
    TARGET=build/libsqlite3-fb-apple-proxy-sim.so \
    FB_DEFINE_FLAGS='-d __APPLE__'

gcc -O2 -fPIC -shared \
    "$PROXY_SCRIPT_DIR/sqlite_apple_proxy_statfs_shim.c" \
    -Wl,--version-script="$PROXY_SCRIPT_DIR/sqlite_apple_proxy_statfs_shim.map" \
    -ldl -o "$PROXY_SHIM"

gcc -O2 -fPIC -shared -I"$PROXY_C_INCLUDE" \
    -D_GNU_SOURCE -D__APPLE__ -DSQLITE_ENABLE_LOCKING_STYLE=1 \
    -DHAVE_GETHOSTUUID=0 -DSQLITE_THREADSAFE=1 -DSQLITE_WITHOUT_ZONEMALLOC \
    -o "$PROXY_C_LIBRARY" "$PROXY_REPO_ROOT/sqlite3.c" -ldl -lpthread

gcc -O2 -I"$PROXY_REPO_ROOT" \
    "$PROXY_SCRIPT_DIR/sqlite_apple_proxy_policy_smoke.c" \
    -L"$PROXY_FB_DIR/build" \
    -Wl,-rpath,"$PROXY_FB_DIR/build" \
    -l:libsqlite3-fb-apple-proxy-sim.so \
    -l:libsqlite_apple_proxy_statfs_shim.so \
    -o "$PROXY_HOST"

gcc -O2 -I"$PROXY_REPO_ROOT" \
    "$PROXY_SCRIPT_DIR/sqlite_apple_proxy_policy_smoke.c" \
    -L"$PROXY_FB_DIR/build" \
    -Wl,-rpath,"$PROXY_FB_DIR/build" \
    -l:libsqlite3-c-apple-proxy-sim.so \
    -l:libsqlite_apple_proxy_statfs_shim.so \
    -o "$PROXY_C_HOST"

run_case(){
    PROXY_CASE_NAME=$1
    PROXY_EXPECTED=$2
    shift 2
    PROXY_DATABASE="$PROXY_BUILD_DIR/$PROXY_CASE_NAME.db"
    PROXY_LOG="$PROXY_BUILD_DIR/$PROXY_CASE_NAME.log"
    rm -f "$PROXY_DATABASE" "$PROXY_DATABASE-journal" \
        "$PROXY_DATABASE-wal" "$PROXY_DATABASE-shm" "$PROXY_DATABASE.lock"
    rm -rf "$PROXY_LOCK_DIR"
    mkdir -p "$PROXY_LOCK_DIR"
    env -u SQLITE_FORCE_PROXY_LOCKING \
        -u SQLITE3_FB_FAKE_MNT_LOCAL \
        -u SQLITE3_FB_FAKE_FSTYPE \
        SQLITE3_FB_FAKE_PROXYDIR="$PROXY_LOCK_DIR" \
        "$@" \
        LD_PRELOAD="$PROXY_SHIM" \
        "$PROXY_HOST" "$PROXY_DATABASE" "$PROXY_EXPECTED" \
        > "$PROXY_LOG" 2>&1
    cat "$PROXY_LOG"
}

run_c_case(){
    PROXY_CASE_NAME=$1
    PROXY_EXPECTED=$2
    shift 2
    PROXY_DATABASE="$PROXY_BUILD_DIR/c-$PROXY_CASE_NAME.db"
    PROXY_LOG="$PROXY_BUILD_DIR/c-$PROXY_CASE_NAME.log"
    rm -f "$PROXY_DATABASE" "$PROXY_DATABASE-journal" \
        "$PROXY_DATABASE-wal" "$PROXY_DATABASE-shm" "$PROXY_DATABASE.lock"
    rm -rf "$PROXY_LOCK_DIR"
    mkdir -p "$PROXY_LOCK_DIR"
    env -u SQLITE_FORCE_PROXY_LOCKING \
        -u SQLITE3_FB_FAKE_MNT_LOCAL \
        -u SQLITE3_FB_FAKE_FSTYPE \
        SQLITE3_FB_FAKE_PROXYDIR="$PROXY_LOCK_DIR" \
        "$@" \
        LD_PRELOAD="$PROXY_SHIM" \
        "$PROXY_C_HOST" "$PROXY_DATABASE" "$PROXY_EXPECTED" \
        > "$PROXY_LOG" 2>&1
    diff -u "$PROXY_BUILD_DIR/$PROXY_CASE_NAME.log" "$PROXY_LOG"
    cat "$PROXY_LOG"
}

run_case remote_auto 1
run_case remote_forced_off 0 SQLITE_FORCE_PROXY_LOCKING=0
run_case local_auto 0 SQLITE3_FB_FAKE_MNT_LOCAL=1
run_case local_forced_on 1 \
    SQLITE3_FB_FAKE_MNT_LOCAL=1 SQLITE_FORCE_PROXY_LOCKING=1
run_case local_fat_empty 0 \
    SQLITE3_FB_FAKE_MNT_LOCAL=1 SQLITE3_FB_FAKE_FSTYPE=msdos

run_c_case remote_auto 1
run_c_case remote_forced_off 0 SQLITE_FORCE_PROXY_LOCKING=0
run_c_case local_auto 0 SQLITE3_FB_FAKE_MNT_LOCAL=1
run_c_case local_forced_on 1 \
    SQLITE3_FB_FAKE_MNT_LOCAL=1 SQLITE_FORCE_PROXY_LOCKING=1
run_c_case local_fat_empty 0 \
    SQLITE3_FB_FAKE_MNT_LOCAL=1 SQLITE3_FB_FAKE_FSTYPE=msdos

make -C "$PROXY_FB_DIR" -j2 \
    TARGET=build/libsqlite3-fb-apple-no-lockstyle-sim.so \
    FB_DEFINE_FLAGS='-d __APPLE__ -d SQLITE_ENABLE_LOCKING_STYLE=0'

gcc -O2 -fPIC -shared -I"$PROXY_C_INCLUDE" \
    -D_GNU_SOURCE -D__APPLE__ -DSQLITE_ENABLE_LOCKING_STYLE=0 \
    -DHAVE_GETHOSTUUID=0 -DSQLITE_THREADSAFE=1 -DSQLITE_WITHOUT_ZONEMALLOC \
    -o "$PROXY_C_LIBRARY_NO_STYLE" "$PROXY_REPO_ROOT/sqlite3.c" -ldl -lpthread

gcc -O2 -I"$PROXY_REPO_ROOT" \
    "$PROXY_SCRIPT_DIR/sqlite_apple_proxy_policy_smoke.c" \
    -L"$PROXY_FB_DIR/build" \
    -Wl,-rpath,"$PROXY_FB_DIR/build" \
    -l:libsqlite3-fb-apple-no-lockstyle-sim.so \
    -l:libsqlite_apple_proxy_statfs_shim.so \
    -o "$PROXY_HOST_NO_STYLE"

gcc -O2 -I"$PROXY_REPO_ROOT" \
    "$PROXY_SCRIPT_DIR/sqlite_apple_proxy_policy_smoke.c" \
    -L"$PROXY_FB_DIR/build" \
    -Wl,-rpath,"$PROXY_FB_DIR/build" \
    -l:libsqlite3-c-apple-no-lockstyle-sim.so \
    -l:libsqlite_apple_proxy_statfs_shim.so \
    -o "$PROXY_C_HOST_NO_STYLE"

PROXY_DATABASE="$PROXY_BUILD_DIR/local_fat_no_lockstyle.db"
PROXY_LOG="$PROXY_BUILD_DIR/local_fat_no_lockstyle.log"
rm -f "$PROXY_DATABASE" "$PROXY_DATABASE-journal" \
    "$PROXY_DATABASE-wal" "$PROXY_DATABASE-shm" "$PROXY_DATABASE.lock"
env -u SQLITE_FORCE_PROXY_LOCKING \
    SQLITE3_FB_FAKE_MNT_LOCAL=1 \
    SQLITE3_FB_FAKE_FSTYPE=msdos \
    SQLITE3_FB_FAKE_PROXYDIR="$PROXY_LOCK_DIR" \
    LD_PRELOAD="$PROXY_SHIM" \
    "$PROXY_HOST_NO_STYLE" "$PROXY_DATABASE" 0 > "$PROXY_LOG" 2>&1
cat "$PROXY_LOG"

PROXY_DATABASE="$PROXY_BUILD_DIR/c-local_fat_no_lockstyle.db"
PROXY_LOG="$PROXY_BUILD_DIR/c-local_fat_no_lockstyle.log"
rm -f "$PROXY_DATABASE" "$PROXY_DATABASE-journal" \
    "$PROXY_DATABASE-wal" "$PROXY_DATABASE-shm" "$PROXY_DATABASE.lock"
rm -rf "$PROXY_LOCK_DIR"
mkdir -p "$PROXY_LOCK_DIR"
env -u SQLITE_FORCE_PROXY_LOCKING \
    SQLITE3_FB_FAKE_MNT_LOCAL=1 \
    SQLITE3_FB_FAKE_FSTYPE=msdos \
    SQLITE3_FB_FAKE_PROXYDIR="$PROXY_LOCK_DIR" \
    LD_PRELOAD="$PROXY_SHIM" \
    "$PROXY_C_HOST_NO_STYLE" "$PROXY_DATABASE" 0 > "$PROXY_LOG" 2>&1
diff -u "$PROXY_BUILD_DIR/local_fat_no_lockstyle.log" "$PROXY_LOG"
cat "$PROXY_LOG"

# end of run_apple_proxy_policy_sim.sh
