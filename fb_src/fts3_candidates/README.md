# FTS3/4 translated candidates

These files preserve C2FB routine candidates whose cross-unit FTS3 interfaces
are not integrated yet. They are intentionally outside the `fb_src/Makefile`
source glob, so unresolved candidate references cannot enter the linked library.

The initial FTS3 batch generated routine candidates from 13 runtime C files.
The root source tree integrates the independent hash, Porter, simple tokenizer,
and Unicode units, plus a manual `fts3tokenize` virtual-table implementation.
The remaining candidates cover core, auxiliary, expression, snippet, tokenizer
virtual-table, and segment-writing routines. Some units compile by themselves;
others still need declarations and implementations from neighboring FTS3
modules.

`sqlite3_bulk_fts3_tokenize_vtab_candidates.bas` now contains 13 C2FB-generated
routine bodies. The type maps in
`fb_tools/c2fb/profiles/sqlite-fts3-tokenizer-body.rsp` let C2FB resolve the
tokenizer module's function-pointer fields and the SQLite module table type.
The candidate file compiles by itself. Its hash, error-formatting, dequote,
and tokenizer implementations are now available in the linked library, though
the generated callback bodies still need safety review before integration.
The static `sqlite3_module` initializer remains manual in the linked
implementation.

The mapped `fts3_snippet.c` pass now accepts
`sqlite3Fts3MIBufferFree()` after mapping the source-local flexible
`MatchinfoBuffer` layout in `sqlite3_fts3_snippet_types.bi`. The production
cleanup routine is integrated in `sqlite3_bulk_fts3_matchinfo_free.bas`; its
reference-count and free paths pass a C API smoke against SQLite's allocator.

The mapped `fts3_write.c` pass accepts `sqlite3Fts3SegReaderFree()` with the
layout in `sqlite3_fts3_write_types.bi`. The cleanup is integrated in
`sqlite3_bulk_fts3_segreader_free.bas` and passes C API smokes for both root-only
and ordinary readers, including allocation-balance checks.

The same profile maps the multi-reader, cursor, deferred-token, and pending-list
records. It now emits `sqlite3Fts3SegReaderFinish()`,
`sqlite3Fts3FreeDeferredDoclists()`, and `sqlite3Fts3FreeDeferredTokens()`;
these are integrated in `sqlite3_bulk_fts3_segreader_finish.bas` and
`sqlite3_bulk_fts3_deferred_tokens.bas`. The C API smoke exercises list-only
cleanup followed by node cleanup, direct node cleanup, and memory balance.
The same unit now ports deferred-token creation and doclist extraction; C API
probes check cursor list ordering, rowid-prefix removal, and cleanup.

The `c2fb_Fts3SegReader` alias keeps the C record name available alongside the
reviewed layout so `sizeof(Fts3SegReader)` remains translatable. The mapped
pass now emits `sqlite3Fts3SegReaderNew()`, integrated in
`sqlite3_bulk_fts3_segreader_new.bas`; its C API probe checks root-node content,
padding, leaf-reader bounds, invalid input, and allocation balance.

The `SqliteFts3Table` and nested pending-index layouts enable
`sqlite3Fts3SegReaderPending()`, integrated in
`sqlite3_bulk_fts3_segreader_pending.bas`. Its C API smoke exercises exact,
prefix, and empty-prefix searches, sorted results, no matches, and allocator
balance.

`sqlite3Fts3ReadBlock()` and `sqlite3Fts3SegmentsClose()` are integrated in
`sqlite3_bulk_fts3_read_block.bas`. The `SQLITE_TEST` build imports the same
chunk-size globals manipulated by the unchanged FTS3 test support. The mapped
prepare flags in `sqlite3Fts3PrepareStmt()` contain a C macro conditional that
C2FB does not lower yet, so that short wrapper is ported directly in
`sqlite3_bulk_fts3_prepare_stmt.bas` and checked through the C API.

The `--keep-unresolved` write-unit pass emits `fts3SqlStmt()` and
`sqlite3Fts3AllSegdirs()`, now integrated in
`sqlite3_bulk_fts3_statement_cache.bas`. The matched C API probe reads a
specific level and a level range from the FTS3 segment-directory schema and
closes both cached statements without leaking.

The mapped C2FB pass over `fts3_write.c` now emits 104 bodies with no
unsupported routines when `Fts3SegFilter` maps to `SqliteFts3SegFilter`. This
includes `fts3IncrmergeCsr()`, `sqlite3Fts3Incrmerge()`, and
`fts3ChecksumIndex()`. The core candidate retains manual
`sqlite3Fts3SegReaderCursor()` and `fts3TermSegReaderCursor()` wrappers around
the translated segment traversal. The pending-list varint append helper is
integrated in `sqlite3_bulk_fts3_pending_list.bas` and tested through a C
caller. The combined candidate objects compile with native and GCC backends in
release and debug modes; their remaining unresolved symbols are libc memory
and string functions. Production copies are now compiled into the debug FTS3
feature library. The review snapshots in this directory remain outside the
Makefile source glob. SQL module registration and FTS3 table write, merge, and
integrity tests remain outstanding.

The C2FB tokenizer-registry pass now translates and integrates all six bodies
from `fts3_tokenizer.c` in `sqlite3_bulk_fts3_tokenizer_registry.bas`. The
per-connection registry exposes the `fts3_tokenizer()` SQL function and
preserves SQLite's db-config and bound-parameter policy. A C API smoke checks
the default-disabled lookup, db-config enablement, and alias registration.

The mapped `fts3.c` pass uses `sqlite-fts3-core-body.rsp` and emits 107 routine
bodies, including `fts3InitVtab`, `fts3ConnectMethod`, and `fts3CreateMethod`.
The updated unit is preserved in `sqlite3_bulk_fts3_core_mapped.bas` and
compiles as a candidate. Eleven already-integrated bodies are omitted; three
candidates still exceed the supported subset. C2FB emits both segment-cursor
routines; the production core keeps reviewed guards on their inputs and
clears cursor state safely. The mapped `fts3_expr.c` pass
emits 12 bodies in `sqlite3_bulk_fts3_expr_mapped.bas`; five parser routines
remain outside C2FB's supported subset. The production parser unit manually
implements those routines around the translated balance and depth-check
helpers. `sqlite3Fts3ExprFree()` and its phrase-cleanup dependency are also
integrated, along with the zeroed allocator and tokenizer-open helper. The
static module initializer, query evaluation, and production wiring of the
staged segment and write candidates remain outstanding.

`sqlite3_bulk_fts3_expr_iterate.bas` integrates phrase-tree traversal and the
NOT-branch exclusion from `fts3_snippet.c`; its C probe verifies callback order
and early error returns.

C2FB candidate counts vary with the source feature profile and explicit type
maps. The original 249-candidate count was generated without the tokenizer ABI
maps and should not be used as a current total.

Upstream test helpers remain in C and Tcl. The original SQLite test suite will
exercise the eventual FreeBASIC module without translating its tests.
