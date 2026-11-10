# Project: SQLite FreeBASIC port
# File: pragma_name_list.test.tcl
#
# Purpose:
#
#     Keep the test/debug-only lock_status pragma visible through both
#     PRAGMA pragma_list and the pragma virtual table.
#
# Responsibilities:
#
#     - Check that lock_status appears in PRAGMA pragma_list.
#     - Check that pragma_pragma_list can locate the same name.
#
# This file intentionally does NOT contain:
#
#     - A copy or translation of SQLite's upstream test scripts.
#     - Runtime implementation code.

set testdir [file normalize [file join [file dirname [info script]] ../../test]]
source [file join $testdir tester.tcl]
set testprefix pragma_name_list

ifcapable !compileoption_diags {
  finish_test
  return
}

set hasTestOrDebug [db one {
  SELECT sqlite_compileoption_used('TEST') OR sqlite_compileoption_used('DEBUG')
}]
if {!$hasTestOrDebug} {
  finish_test
  return
}

do_test 1.0 {
  set pragmaNames [db eval {PRAGMA pragma_list}]
  expr {[lsearch -exact $pragmaNames lock_status] >= 0}
} 1

do_execsql_test 1.1 {
  SELECT name FROM pragma_pragma_list WHERE name='lock_status'
} {lock_status}

finish_test

# end of pragma_name_list.test.tcl
