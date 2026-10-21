# SQLite FreeBASIC port

`fb_src/` is the FreeBASIC implementation tree for SQLite's core and selected
optional extensions. The core inventory covers 211,790 lines of non-test-
support sources and build inputs before exclusions. The shell template (14,931
lines) and Tcl test adapter (4,665 lines) stay outside the core port, leaving
192,194 upstream engine and public-ABI lines in core scope. Optional R-Tree,
GeoPoly, FTS3/4, Session, and FTS5 sources are tracked separately. FTS5 adds
26,669 C implementation, header, and grammar lines; FTS3/4 adds 20,051
implementation and header lines; Session adds 10,236 implementation and API
header lines. The FTS3/4 feature profile now registers the full-text tables and
`fts4aux`, with query, write, snippet, offsets, and matchinfo paths running in
the C test fixture driven by unchanged upstream scripts. Fifteen focused FTS3
scripts pass 25,927 tests with no tracked leaks in the fixture-matched
`SQLITE_DEFAULT_PAGE_SIZE=1024` profile. This includes snippet, offsets,
matchinfo, auxiliary scans, expression parsing, tokenizer tests, and all 41
`fts3defer2` cases. Five additional scripts cover corruption handling and FTS4
growth and add 314 checks. Across these 20 scripts, all 26,241 checks pass
with no tracked leaks in the fixture-matched `SQLITE_DEFAULT_PAGE_SIZE=1024`
profile. Each script ran in its own test directory, so database state does not
carry between scripts. The broader matched-profile `test/fts3.test` run
completed 113,519 invocations, with one run-dependent malformed-image failure
at `fts3corrupt4-25.5`; the other 113,518 passed, and no tracked allocations
remained. The standalone `fts3corrupt4.test` run passes 159/159. An earlier
broader run used the library's 4096-byte default instead of the fixture's
1024-byte page size; its 106,799 passing cases and 32 failures are superseded
by the matched-profile runs above. Test-support code remains in C or Tcl so
the unchanged upstream scripts can exercise the FreeBASIC engine; the
FreeBASIC SQLITE_TEST profile supplies the extension SQL hooks those scripts
call.
Session has 175 unique
translated procedures across its core, changeset, and simple-API modules. Its
full public API is linked in the feature profile, and the unchanged 44-script
Session suite passes 21,006 invocations. Test-support code remains in C or Tcl
so the unchanged upstream suite can exercise the FreeBASIC engine through the
existing fixture.

`PORTING_FUNCTIONS.csv` tracks source-definition rows. A C function name can
appear more than once when mutually exclusive implementation files define it,
such as the MEM0, MEM1, and MEM2 allocators or the Unix and Windows VFS. Name
matching is an initial reconciliation signal; rows marked `Needs variant
port` identify alternate implementations that a same-named FreeBASIC body does
not cover. `FB body present` records source coverage, not full behavioral
parity.

The core function index has FreeBASIC bodies for all 3,263 indexed definitions
(100% by row count) and all 124,853 indexed function lines. This is 65.0% of
the 192,194 in-scope engine and public-ABI source lines when measured by
function-definition lines; that ratio is not a completeness score. The
remaining source lines include declarations, macros, static data, comments,
and generated interfaces. The final 20 body entries include 11 test/debug
helpers and nine upstream-disabled or historical definitions. Eight are off
by default to match upstream and compile under the optional
`SQLITE3_FB_COMPILE_DISABLED_BODIES` validation define; the historical
serial-type definition is represented by the live implementation in
`sqlite3_vdbe_serial.bas`.
Body presence does not establish semantic parity. Run
`make -C fb_src reconcile-function-status` to reconcile ordinary name matches.
The command preserves custom statuses such as `Needs variant port` and
`Disabled upstream`. Regenerate the index with
`c2fb functions ../src PORTING_FUNCTIONS.csv` when the SQLite source set
changes, then reconcile it again and re-audit duplicated names. The coverage
checker searches integrated FreeBASIC source units and excludes build output
and nested candidate-conversion directories, so an unintegrated C2FB candidate
cannot satisfy a function row.

## FTS3/4 port progress (2026-10-20)

The FTS3 hash-table unit has C-compatible `Fts3Hash`, `Fts3HashElem`, and
bucket layouts, internal API declarations, and all 17 routine bodies from
`ext/fts3/fts3_hash.c`. The feature build exports its five public hash symbols.
The Porter and simple-tokenizer units add 16 and seven routine bodies. The
Unicode tokenizer source adds eight routines, and `fts3_unicode2.c` has all four
of its routines with the generated data tables represented as FreeBASIC constant
arrays. The Unicode classification, fold, and diacritic-removal code uses
bounded table searches and explicit branches for shifts.

The tokenizer ABI from `fts3_tokenizer.h` is defined in
`sqlite3_fts3_tokenizer_types.bi`. FreeBASIC callback tables and C ABI accessors
now expose the built-in simple, Porter, and Unicode tokenizers. A temporary C
host using the upstream header created, opened, iterated, and closed all three
modules; each returned three tokens with in-range byte offsets.

The hash, Porter, simple-tokenizer, Unicode tokenizer, and Unicode data units
provide 52 integrated routine bodies. `sqlite3_bulk_fts3_primitives.bas` adds
eight C2FB-translated varint and shared helper routines, for 60 integrated
bodies across six units. The new
`sqlite3_bulk_fts3_tokenize_vtab.bas` module registers `fts3tokenize`, owns a
per-connection registry for `simple`, `porter`, and `unicode61`, and implements
the vtab callbacks for token text, byte offsets, and positions. The tokenizer
hash destructor clears the hash and frees its allocation when the connection
closes. A temporary C host created and queried all three tokenizers through
the registered virtual table.

The ICU tokenizer from `ext/fts3/fts3_icu.c` is ported in
`sqlite3_bulk_fts3_icu.bas`. FTS3/4 initialization registers it alongside the
built-in tokenizers when `SQLITE_ENABLE_ICU` is enabled. The build runs C2FB on
a narrow header of ICU API declarations, allowing ICU's own headers to supply
the versioned ABI symbol names. Native debug and release libraries build with
ICU 78.2, and the GCC-backend debug library also builds. The unchanged
`fts3atoken.test` passes 36/36 on native and GCC FreeBASIC with ICU cases
enabled and no tracked leaks. A public C API smoke also checks apostrophe word
breaking and Thai segmentation.

The new `sqlite3_bulk_fts3_tokenizer_registry.bas` integrates six C2FB bodies
from `fts3_tokenizer.c`: tokenizer name scanning, tokenizer creation, the
identifier-character check, and the `fts3_tokenizer()` SQL function. The SQL
function is registered on the same per-connection hash. A C API smoke confirms
that pointer lookup is hidden by default, becomes available after the
`SQLITE_DBCONFIG_ENABLE_FTS3_TOKENIZER` setting is enabled, and that a pointer
can be registered and looked up under an alias.

The mapped `fts3_write.c` pass also accepts `sqlite3Fts3SegReaderFree()` using
the `Fts3SegReader` layout in `sqlite3_fts3_write_types.bi`. The linked cleanup
handles root-only and ordinary readers; a C API smoke verifies their
allocations return to baseline in the `SQLITE_DEBUG` feature profile.

The same write-unit map now supports `Fts3MultiSegReader`, `Fts3Cursor`,
`Fts3DeferredToken`, and `PendingList`. C2FB output for
`sqlite3Fts3SegReaderFinish()`, `sqlite3Fts3FreeDeferredDoclists()`, and
`sqlite3Fts3FreeDeferredTokens()` is integrated in the segment-reader and
deferred-token units. C API smokes cover root-only and ordinary segment arrays,
retained deferred-token nodes, list clearing, full cleanup, and allocator
balance.

The `c2fb_Fts3SegReader` alias in `sqlite3_fts3_write_types.bi` lets C2FB keep
the C record name visible while using the reviewed FreeBASIC layout. This
preserves `sizeof(Fts3SegReader)` in allocation expressions. The generated
`sqlite3Fts3SegReaderNew()` body is integrated in
`sqlite3_bulk_fts3_segreader_new.bas`; its C API smoke checks root-node bytes,
padding, leaf bounds, invalid inputs, and allocator balance.

The complete `SqliteFts3Table` and nested index layouts also let C2FB translate
`sqlite3Fts3SegReaderPending()`. It is integrated in
`sqlite3_bulk_fts3_segreader_pending.bas`; a C API smoke checks exact lookup,
sorted prefix lookup, empty-prefix enumeration, no-match behavior, and cleanup.

`sqlite3_bulk_fts3_read_block.bas` integrates C2FB's
`sqlite3Fts3ReadBlock()` and `sqlite3Fts3SegmentsClose()` candidates. It opens
and reuses SQLite blob handles, pads loaded nodes, and follows the FTS3
incremental-read settings. The C API probe verifies blob reopen, chunked and
full reads, error translation, padding, and handle cleanup. The `SQLITE_TEST`
profile imports the two unchanged FTS3 test-control globals through C ABI
storage supplied by the temporary fixture adapter.

`sqlite3_bulk_fts3_prepare_stmt.bas` implements
`sqlite3Fts3PrepareStmt()`. Its C API smoke prepares and steps a simple query,
allows an FTS3 tokenizer virtual table when requested, and confirms the
`SQLITE_PREPARE_NO_VTAB` path rejects virtual-table SQL.

The mapped write-unit pass with `--keep-unresolved` emits `fts3SqlStmt()` and
`sqlite3Fts3AllSegdirs()`. Both are integrated in
`sqlite3_bulk_fts3_statement_cache.bas`; a C API probe reads segment-directory
rows at one level and across a level range, then confirms cached statements are
finalized without allocator leaks.

`sqlite3_bulk_fts3_pending_list.bas` implements the write-side varint append
helper, including flexible-tail allocation, growth, and the trailing NUL byte.
A C ABI probe decodes boundary values after repeated growth and checks that the
SQLite allocator returns to baseline. `sqlite3_bulk_fts3_core_helpers.bas`
implements `sqlite3Fts3ReadInt()` and `sqlite3Fts3CreateStatTable()`; its C
probe checks numeric overflow, stat-table creation and the existing-table path.

The mapped C2FB pass over `fts3_write.c` now emits 104 bodies with no
unsupported routines when `Fts3SegFilter` is mapped to
`SqliteFts3SegFilter`. This includes the segment merge, incremental merge, and
integrity-check routines that were previously manual ports or skips. The core
candidate still supplies the two segment-cursor wrappers omitted by C2FB. Both
objects compile with native and GCC backends in release and `SQLITE_DEBUG`
profiles. Their combined closure has no unresolved SQLite symbols against the
FTS3 feature library; only libc memory and string routines remain. The
production core and write copies now build into the debug FTS3 feature library.
`sqlite3Fts3Init()` registers the FTS3 and FTS4 modules through the manually
initialized `sqlite3_module` table. The test profile also registers upstream's
`fts4term` index-inspection module from unchanged C test support. The focused
runtime results are listed above; the broad suite still exposes deferred-token,
corruption, and test-helper gaps.

`sqlite3_bulk_fts3_primitives.bas` integrates the FTS3 64-bit varint encoder,
unbounded and bounded decoders, 32-bit decoder, varint length helper, string
dequote helper, and virtual-table error formatter. The unchanged
`fts3varint.test` passes 68/68 on both the FreeBASIC fixture and C reference,
with no tracked FreeBASIC leaks.

The FTS3 expression layouts now include the recursive `SqliteFts3Expr` and
parser-context records.
`sqlite3_bulk_fts3_expr_free.bas` integrates `sqlite3Fts3ExprFree()` and
`sqlite3Fts3EvalPhraseCleanup()`; `sqlite3_bulk_fts3_expr_helpers.bas` adds
`sqlite3Fts3MallocZero()` and `sqlite3Fts3OpenTokenizer()`. The FTS3 debug
library builds, and C ABI probes verify expression ownership and cleanup,
zeroed allocation, tokenizer v0/v1 callbacks, language-id errors, and cleanup.
The saved FTS3 API probes all pass against the rebuilt library.

`sqlite3_bulk_fts3_expr_parse.bas` now parses FTS3 terms, quoted phrases,
column-qualified terms, prefix tokens, operators, NEAR distances, and both
legacy and parenthesis-enabled syntax. It uses C2FB's translated expression
balancer and depth check, with manual ports for five parser routines that
remain outside the converter's supported subset. A C ABI probe checks tree
shape, malformed input, parenthesis handling, and a 100-term OR expression
balanced to the configured depth limit. Parser allocations return to baseline.
Both the production profile and the `SQLITE_TEST` toggle profile compile.

`sqlite3_bulk_fts3_expr_iterate.bas` visits phrase nodes left-to-right and
stops at the right branch of NOT, matching `sqlite3Fts3ExprIterate()`. The
deferred-token unit now creates deferred entries and copies their serialized
doclists, in addition to cleanup. C ABI probes check callback ordering,
NOT-subtree skipping, callback errors, deferred-list ownership, and memory
balance.

The unchanged `fts3tok_err.test` passes 902/902 invocations and `fts3tok1.test`
passes 22/22 on the FreeBASIC test profile, with no tracked leaks. The C
reference passes 866/866 and 23/23 respectively, including ICU-only cases not
enabled in the FreeBASIC profile. The 864 common passing labels from
`fts3tok_err.test` and 20 from `fts3tok1.test` add 884 distinct labels;
`fts3varint.test` adds another 67. Fault-injection invocation totals differ
because the two builds reach different allocation points.

The initial default-map C2FB pass across 13 runtime C files generated 249
routine candidates. The FreeBASIC source tree now compiles 57 C2FB bodies and
includes three Unicode routines completed manually around their generated static tables.
C2FB translates all four routines from `fts3_unicode2.c`. Their generated
tables stay shared, and the port uses explicit branches around bounded bit
shifts. A C API differential fed every valid Unicode scalar value from U+0001
through U+10FFFF, separated each value so it was tested as its own token, and
hashed token text, byte offsets, and positions. The C reference, native
FreeBASIC, and GCC-backend FreeBASIC matched all 1,104,042 emitted tokens in
each of the three `remove_diacritics` modes.

The remaining candidates are preserved under `fts3_candidates/` for interface
and dependency repair. The repeatable type maps in
`fb_tools/c2fb/profiles/sqlite-fts3-tokenizer-body.rsp` let C2FB translate 13
routines from `fts3_tokenize_vtab.c`, including indirect tokenizer callback
calls. The new `sqlite-fts3-core-body.rsp` maps the table, expression, hash,
and tokenizer records used by `fts3.c`. The updated mapped pass emits 107
candidate bodies; the staged unit compiles. Eleven bodies already implemented
in FreeBASIC are omitted. C2FB still skips `fts3PrefixParameter`,
`fts3InitVtab`, and `fts3ClearCursor`, but the active production core contains
reviewed manual FreeBASIC implementations for all three. C2FB emits both
segment-cursor routines; the production core keeps reviewed guards on their
inputs and clears cursor state safely.
The mapped pass over `fts3_expr.c` emits 12 bodies; the candidate unit compiles.
C2FB omits the existing expression cleanup because it is already ported. Its
five parser routines that still exceed the supported subset have manual ports
in `sqlite3_bulk_fts3_expr_parse.bas`. The mapped core and write modules now
compile into the production FTS3 feature library. The full C2FB suite passes
11,154 C/FreeBASIC behavior comparisons on each backend. Rebuilt C API probes
for the `fts3tokenize` virtual table and `fts3_tokenizer()` pass against this
library. FTS3 and FTS4 SQL modules now register and support table queries. The
`SQLITE_TEST` profile registers the expression and tokenizer SQL callbacks used
by the unchanged upstream suites; the focused parser and tokenizer tests pass.

The refreshed mapped pass over `fts3_write.c` emits 104 bodies in
`fts3_candidates/sqlite3_bulk_fts3_write_mapped.bas`, with all 13 already
implemented bodies omitted and no unsupported candidates. The updated C2FB
layout lookup uses the mapped `SqliteFts3SegFilter` size for `sizeof` forms.
The write candidate includes `fts3IncrmergeCsr()`,
`sqlite3Fts3Incrmerge()`, and `fts3ChecksumIndex()` from upstream C2FB output.
The production copies compile with the core cursor wrappers, and `ldd -r`
reports no unresolved symbols. The unchanged `fts3aux1.test` and `fts3aux2.test`
pass 127 invocations after allowing their synthetic table layout without an
`aIndex` array. In the matched 1 KiB profile, the complete `fts3.test`
aggregate reaches the FTS3/4 merge cases and finishes with 113,518 passes and
one run-dependent failure at `fts3corrupt4-25.5` (expected query success,
received `SQLITE_CORRUPT`). The isolated corruption script passes 159/159. A
fixed-seed comparison of the `25.*` block on C and FreeBASIC for seeds 1 to
100 produced identical outcomes. Seeds 13, 37, and 72 hit `25.4`; seeds 24,
36, 63, 66, and 84 hit `25.5`. The exact PRNG state from the broader aggregate
was not replayed, but this failure class is shared with upstream C.

## Session port progress (2026-10-19)

`sqlite3_bulk_session.bas` and `sqlite3_bulk_session_changeset.bas` contain 168
C2FB-translated procedure bodies. `sqlite3_session_simple_api.bas` adds seven
small API routines, for 175 unique procedures total across the three modules.
The feature build enables `SQLITE_ENABLE_SESSION` and
`SQLITE_ENABLE_PREUPDATE_HOOK`, links without unresolved Session symbols, and
exports all 59 declarations in `sqlite3_session_api.bi`.

A C smoke using the unchanged upstream headers creates a session, records and
serializes changes, iterates a changeset, applies it to a second database,
checks the changed row, exercises changegroup output, and frees the objects.
Streaming chunk size is shared across modules so the `SQLITE_TEST` 64-byte
setting matches upstream.

All 44 unchanged Session scripts pass 21,006 test invocations with zero errors.
The initial aggregate run completed 42 scripts with 9,247 invocations;
`sessionB.test` and `sessionfault.test` exceeded the wrapper timeout while
waiting on filesystem journal sync. Rerunning those unchanged scripts from
tmpfs completed cleanly: `sessionB.test` (125/125) and `sessionfault.test`
(11,634/11,634), both with no tracked leaks. The suite also passes
`session1.test` (211/211), `sessionbig.test` (6/6), `sessionnoop2.test` (51/51),
`sessionsize.test` (24/24), and `sessionfault2.test` (6,032/6,032).

Two engine fixes were required for the Session suite. The VDBE now keeps its
compiled statement-journal flag when a prepared statement is reset after an
error, so repeated trigger constraint failures roll back each attempt. The
pre-update `new()` accessor unpacks a callback-owned expanded copy of an
inserted zero-blob record; expanding the live VDBE register corrupted the row
that OP_Insert was about to write. `ext/session/changeset.c`, the standalone
command-line utility, remains unported.

## FTS5 port status (2026-10-19)

The FTS5 varint, buffer, hash, storage, configuration, main, expression,
auxiliary-function, vocabulary, index, Unicode-data, tokenizer, and query
parser units are integrated in `fb_src/`. The tokenizer registers `unicode61`,
`ascii`, `trigram`, and v2 `porter`. The Unicode tables and fold routines match
the upstream C implementation for every codepoint through U+10FFFF, including
all three diacritic-removal modes. The release and debug feature libraries link
without unresolved FTS5 parser symbols.

The unchanged upstream FTS5 suite has now run with FTS5 enabled in the C test
adapter and its default page size matched to the C fixture at 1 KiB. The latest
run executed all 148 scripts and passed 223,556 of 223,557 test invocations;
147 scripts had no errors. The C reference shares one known failure in
`fts5bigtok2.test`. All three FTS5 corruption scripts pass: `fts5corrupt3.test`
(2,022/2,022), `fts5corrupt5.test` (41/41), and `fts5corruptA.test` (56/56).
Fault and fuzz invocation totals vary between runs. The FTS5 labels are not yet
reconciled into the distinct-label ledger below.

Recent fixes make `fts5ab.test` pass 287/287 and `fts5unicode3.test` pass 10/10.
The `fts5ab` failures came from bound BLOB values keeping the wrong encoding;
the tokenizer test exposed a test UDF registered with a fixed argument count.
The BLOB encoding change also passes `bind.test` (119/119), `blob.test`
(24/24), `enc.test` (115/115), `enc2.test` (90/90), `enc3.test` (12/12),
`enc4.test` (1,115/1,115), and `utf16align.test` (7/7), with no tracked leaks.
The VDBE now marks explicit transactions read-only after `SQLITE_CORRUPT`,
rejects later writes and refuses to commit them. The record comparator also
matches SQLite's corrupt-key ordering rule: it compares an available field
before reporting a short declared header when that field already determines
sort order. The C and FreeBASIC delete and commit probes agree, and the three
FTS5 corruption scripts now pass.
Transaction regressions pass with the aligned page size, including
`savepoint.test` (140/140), `trans.test` (329/329), and `trans2.test` (408/408).
The unchanged 15-file `index*.test` set passes 7,724/7,724; `corruptL.test`
passes 56/56 and `corruptN.test` passes 18/18.

## Test ledger (2026-10-19)

The focused cumulative ledger records 499,743 distinct upstream test-case
labels that passed on the FreeBASIC port in unchanged test runs. The FTS3
tokenizer and varint subsets add 951 C-common labels, bringing the distinct
count across these runs to 500,694. The four
recovered `recover1` labels and two `corruptL` labels that previously failed
are now included; reruns of already-passing labels remain deduplicated.

The latest native all-job run passed 1,088,422 invocations across all 1,516
jobs with no errors. The GCC-backend run passed 1,088,708 invocations across
all 1,516 jobs with no errors. Fault-injection workloads depend on runtime
failure points, so invocation totals vary between backends and runs.

The separate FTS5-enabled profile passed 223,556 of 223,557 invocations across
all 148 FTS5 scripts. Its sole error also occurs in the C reference. The FTS5
test library uses the same 1 KiB default page size as the C test fixture. These
counts are kept separate from the core all-job profile and distinct-label
ledger.

The matched FTS3/4 profile completed the broad `test/fts3.test` aggregate with
113,518 of 113,519 invocations passing. Its sole error is the run-dependent
`fts3corrupt4-25.5` malformed-image case; the isolated 20-script subset passes
all 26,241 checks. These totals overlap feature-specific focused runs and are
not added to the distinct-label ledger.

A full native test-fixture run with `SQLITE_ENABLE_RTREE` and
`SQLITE_ENABLE_GEOPOLY` enabled completed all 1,516 jobs and 1,234,924
invocations with zero errors after the runner's failed-job retest. The first
parallel pass reported one `temptable2-4.1.4` temp-page-count mismatch; the
unchanged test passes 257/257 on both the C and FreeBASIC fixtures when run
alone, and the retest passed. The run includes the two GeoPoly cases in
`ext/rtree/rtreefuzz001.test`. FTS3/4/5 and Session remain disabled in this
profile, and these run-dependent labels are not added to the focused distinct
label ledger above.

## Combined optional-feature profile (2026-10-20)

A single FreeBASIC test library enabled FTS3/4, FTS5, ICU, R-Tree, GeoPoly,
Session, CARRAY, DBPAGE, DBSTAT, Bytecode VTab, math functions, and percentile.
The unchanged `test/fts3.test` passes 115,959/115,959, `test/rtree.test`
40,692/40,692, and all 44 Session scripts pass 21,781/21,781 after rerunning
`sessionbig.test` on ext4. The FTS5 scripts pass 224,449/224,450 invocations;
the sole `fts5bigtok2-1.1` OOM expectation mismatch also reproduces on C.
Completed runs report no tracked allocation leaks.

The first combined run's C test adapter suppressed DEBUG and MEMSYS5 test
capabilities. The FreeBASIC FTS3 core now exports the debug-only
`sqlite3_fts3_may_be_corrupt` global used by the unchanged C test support. A
static-mutex guard initializes it once and preserves later test changes; the
C test command sees the initial value of 1, changes it to 0, and still sees 0
after opening another connection. This lets the follow-up C adapter enable
DEBUG. MEMSYS5 remains unadvertised because its allocator-dump hook is test-only
C support. The FreeBASIC library is built with both options enabled.

In the debug-capable combined profile, `test/fts3.test` passes
115,959/115,959, `test/rtree.test` passes 40,657/40,657, all 44 Session files
pass 22,843/22,843, and the 148 FTS5 scripts pass 224,437/224,438 invocations.
The debug-capable `fts3corrupt4.test` also passes 160/160. The single FTS5 error
is again `fts5bigtok2-1.1`, also reproduced on C. The Session fault-injection
files `sessionB.test` and `sessionfault.test` ran on tmpfs; `sessionbig.test`
ran on ext4. These profile totals remain separate from the full core all-job
totals and the distinct-label ledger.

## Debug assertions in C2FB and FTS5 (2026-10-20)

C2FB's SQLite preprocessing path now supports `C2FB_RESTORE_ASSERTS=1`. It
converts each active C `assert(expression)` into one call to
`sqlite3DebugAssertCheck(condition, expression-text)`, preserving single
evaluation and converting pointer/scalar truth values to C's integer form. The
FreeBASIC debug handler logs and aborts when the condition is false.
`C2FB_DISABLE_ASSERTS=1` remains available for candidate sweeps that need
assertions omitted; the options cannot be combined. The full C2FB regression
suite passes 11,154 C/FreeBASIC behavior comparisons on both native and GCC
backends, accepting 166 candidates and rejecting 36 unsupported functions.

A real debug candidate pass over `src/btree.c` translates 15 routines and
identifies 197 already-ported routines. It still reports 9 unsupported bodies
and 4 helper dependency gaps. Its `cursorOwnsBtShared()` candidate retains the
mutex assertion; the FreeBASIC implementation now routes that check through the
debug handler before comparing database owners. The B-tree unit compiles in
native-debug, GCC-debug, and release profiles. With the rebuilt debug
combined-feature library, unchanged `mutex1.test` passes 29/29 and
`btree01.test` passes 215/215, with no tracked leaks.

The manual `allocateSpace()` port now restores all 14 upstream debug checks for
page writability, mutex ownership, free-space bounds, and allocation limits.
Both source-local `freeSpace()` copies now restore all nine upstream checks for
page state, freeblock ordering, and 16-bit block sizes. On the rebuilt debug
feature library, unchanged `btree01.test` passes 215/215 and `btreefault.test`
passes 510/510 with no tracked leaks. Fault-injection counts vary by profile.

The FTS5 index now implements the debug-only `fts5StructureCountSegments()`
helper and restores 76 upstream checks across buffer comparison, blob and leaf
reads, structure ownership and decoding, structure counts, forward and reverse
iterator setup, doclist-index iteration, `detail=full` output, segment-writer
invariants, and multi-iterator construction. The debug
combined-feature library rebuilds successfully.
With it, unchanged `fts5simple.test` passes 86/86 and
`fts5corrupt3.test` passes 2,022/2,022; both runs report zero errors and no
tracked leaks. The broader FTS5 index assertion set still needs porting. These
counts are profile runs and are not added to the distinct-label ledger.

After the native full run, `sqlite3PagerStats()` was adjusted to keep its
statistics array available when the page cache has not yet been initialized,
matching the upstream test hook. The unchanged `cache.test` passes 190/190 on
both rebuilt backends after that change. The full GCC run includes the change.
The focused distinct-label ledger above remains separate from these invocation
totals. `ext/recover/recover1.test` passes 100/100, `test/corruptL.test` 56/56,
and `test/zipfilefault.test` 1,443/1,443 on native and GCC with no tracked
leaks. The unchanged `test/dbfuzz001.test` passes 12/12 and
`test/mmapcorrupt.test` 4/4 on native and GCC, with no tracked leaks.
Temp-database regressions also pass on both backends: `temptable.test` 63/63,
`temptable2.test` 257/257, `tempdb.test` 6/6, `tempdb2.test` 8/8,
`temptable3.test` 3/3, and `temptrigger.test` 77/77. Fault-injection runs have
profile-dependent invocation counts.

On both native and GCC-backend fixtures, `qrf01.test` passes 147/147,
`resetdb.test` 28/28, `ext/expert/expert1.test` 69/69, `tkt3838.test` 3/3,
`tclsqlite.test` 132/132, `ctime.test` 79/79, `altertab.test` 120/120,
`printf.test` 1,439/1,439, and `printf2.test` 51/51. These focused regression
runs report no tracked FreeBASIC leaks. Their labels have not yet been
reconciled against the 498,792 distinct-label ledger.

A later full-run snapshot exposed an expression-index grouped aggregate
regression in `in.test`: WHERE planning added an aggregate column after the
sorter register range had been allocated. The grouped SELECT path now resizes
that range after planning. The unchanged `in.test` passes 127/127 on native
and GCC; `indexexpr1.test` (117/117) and `tkt-99378177930f87bd.test` (16/16)
pass on C, native, and GCC. `select1.test` (199/199), `indexexpr2.test`
(128/128), and `indexexpr3.test` (14/14) pass on both FreeBASIC backends. All
of these retests reported no tracked FreeBASIC allocations. The pager now
accepts `SQLITE_OK_SYMLINK` after path resolution unless
`SQLITE_OPEN_NOFOLLOW` was requested; `symlink.test` passes 39/39 on C, native,
and GCC without tracked FreeBASIC allocations. These reruns are verification
evidence and are not added to the unique-label total until their labels are
reconciled with the existing ledger. The Unix VFS now follows SQLite's lock
transition for hot-journal rollback, and pendingrace.test passes 6/6 on C,
native, and GCC without tracked leaks. A pre-fix full-run snapshot was stopped
after 1,496 of 1,516 jobs because misc7.test remained active for over 36
minutes; its partial rows are excluded from the cumulative ledger.

The full upstream C reference run completed 1,826,438 test invocations across
1,516 jobs, with one failure in `ext/fts5/test/fts5bigtok2.test`. A later full
run against the linked FreeBASIC fixture completed all 1,516 jobs in 22:45. It
recorded 1,035,861 test invocations, 1,034,924 passing cases, and 937 errors
across 103 failed jobs. A retest of failed jobs then finished with 1,035,962
recorded invocations across all 1,516 job rows: 1,035,045 cases without errors
and 917 errors in 98 still-failed jobs. This database combines unchanged rows
from the full run with refreshed failed-job results. Its fault-injection and
fuzz workloads have run-dependent case counts.

A fresh all-job run with the feature-enabled FreeBASIC library completed all
1,516 jobs in 27:38 and recorded 1,055,901 invocations, with 332 errors. That
library included the LIMIT and OFFSET fixes but predated the soft-collate
subtype fix. Retesting the failed jobs with the latest library and a 1,024
file-descriptor cap for `misc7.test` left 1,057,215 recorded invocations,
1,056,886 invocations without errors, and 329 errors across 69 still-failed
jobs. `misc7.test` passes 1,315/1,315 under that cap. This database combines
successful rows from the all-job run with refreshed failed-job results.

A fresh all-job run after the immutable-pager fix completed all 1,516 jobs in
22:39. It recorded 1,057,409 invocations, 1,057,083 invocations without errors,
and 326 errors. The runner database records 1,448 jobs without errors and 68
failed jobs. The unchanged `nolock.test` passes 26/26 in this run. Fault,
fuzz, and randomized crash workloads have run-dependent invocation counts.

A fresh full run after the Unix chunk-size fix completed all 1,516 jobs in
22:16. It recorded 1,057,231 invocations, 1,056,917 invocations without
errors, and 314 errors across 68 failed jobs; 1,448 jobs had no errors. The
unchanged `fallocate.test` passes 19/19 and `chunksize.test` passes 7/7 in the
full harness. The unchanged `nolock.test` passes 26/26. The invocation total
differs from the prior run because fault and randomized workloads are
run-dependent.

The full-run `pager1.test` job was marked failed because the temporary C test
adapter read the FreeBASIC connection and pager records using C structure
offsets. The adapter now calls the port's test-only pager-count and refcount
accessors. After rebuilding it, unchanged `pager1.test` passes 1,373/1,373
with no tracked allocations.

Retesting the previously failed jobs with the iif fix and updated pager
adapter refreshed the combined database to 1,062,521 invocations, 1,062,223
without errors, and 298 errors across 65 failed jobs. The database contains
1,451 jobs with no errors and combines unchanged successful rows from the
full run with refreshed results for failed jobs. Fault and fuzz workloads have
run-dependent case counts.

The remaining 10 `malloc8.test` errors came from a pending `SQLITE_NOMEM` set
by a result-column encoding conversion. The next VM step must halt on that
saved error; the port now does so in `sqlite3VdbeExec()`. The unchanged test
passes 668/668 with no errors or tracked leaks. Replacing only that job's old
result in the combined snapshot gives 1,062,233 invocations without errors
and 288 errors across 64 failed jobs; the other failed jobs have not been
rerun against this latest change.

`autoinc.test` exposed the same root-register rule in `OP_NewRowid`: trigger
programs must use the outermost VDBE frame's AUTOINCREMENT sequence register.
The opcode now resolves P3 through that frame. The unchanged test passes 88/88
on native and GCC-backend builds, with no tracked leaks. Replacing the stale
`malloc8.test` and `autoinc.test` rows gives 1,062,239 invocations without
errors and 282 errors across 63 failed jobs; the other failed jobs have not
been rerun against these changes.

Eight `fkey8.test` failures came from the temporary C adapter reading
`usesStmtJournal` at the C VDBE field offset. The FreeBASIC VDBE stores that
state in its flags word, so the adapter now calls a test-profile accessor.
Unchanged `fkey8.test` passes 38/38 with no tracked leaks. Replacing the stale
`malloc8.test`, `autoinc.test`, and `fkey8.test` rows gives 1,062,247
invocations without errors and 274 errors across 62 failed jobs; the other
failed jobs have not been rerun against these changes.

`securedel.test` caught `sqlite3GetBoolean()` narrowing FreeBASIC's true value
of -1 to the C byte value 255. It now returns exactly 0 or 1; the unchanged
test passes 12/12 on native and GCC-backend builds with no tracked leaks.
`pragma.test` then exposed stale prepared statements after TEMP storage is
replaced. The port now expires cached VDBE programs after clearing that schema.
The temporary C test adapter obtains the current B-tree through a port accessor
and handles an absent file object without relying on C structure offsets.
Unchanged `pragma.test` passes 236/236 on both backends with no tracked leaks.
Substituting all five refreshed rows (`malloc8`, `autoinc`, `fkey8`,
`securedel`, and `pragma`) gives 1,062,756 invocations, 1,062,489 without
errors, and 267 errors across 60 failed jobs. The other failed jobs have not
been rerun against these changes.

`trace3.test` exposed omitted `SQLITE_TRACE_ROW` delivery from `OP_ResultRow`,
the close callback missing from the active connection-close path, and embedded
NUL handling in expanded SQL. Those paths now match SQLite's callback and
`%q` behavior. The unchanged test passes 42/42 on native and GCC-backend builds
with no tracked leaks. Replacing its stale row yields 1,062,756 invocations,
1,062,496 without errors, and 260 errors across 59 failed jobs; the remaining
failed jobs have not been rerun against these changes.

`pushdown.test` showed that the translated count-of-view optimization was not
connected to SELECT dispatch, and that EXPLAIN QUERY PLAN labeled compatible
`IN` subqueries before the reuse decision. SELECT dispatch now runs the count
rewrite before choosing the FROM-clause path, and `sqlite3CodeRhsOfIN()` emits
the plan row after checking for reuse. The unchanged test passes 29/29 on the
native and GCC-backend profiles with no tracked leaks. The unchanged
`count.test` also passes 41/41 on both profiles with no tracked leaks.
Replacing the stale pushdown row gives 1,062,756 invocations, 1,062,500
without errors, and 256 errors across 58 failed jobs. The remaining failed
jobs have not been rerun against these changes.

`filter1.test` caught the min/max shortcut running on an aggregate FILTER
expression; the SELECT-side helper now applies SQLite's `EP_WinFunc` guard.
`e_changes.test` caught the VDBE retaining changes from rows rolled back with
an autocommit statement; rollback paths now clear the pending change count
before publishing it to the connection. Both unchanged tests pass on native
and GCC-backend builds with no tracked leaks (`filter1` 36/36, `e_changes`
72/72). Replacing both stale rows gives 1,062,756 invocations, 1,062,504
without errors, and 252 errors across 56 failed jobs. The other failed jobs
have not been rerun against these changes.

`alter.test` exposed a byte-versus-character offset in `ALTER TABLE ADD
COLUMN` when the existing schema contains malformed UTF-8. The schema rewrite
now slices the stored SQL as a BLOB at `addColOffset`, preserving the original
bytes. The unchanged test passes 122/122 on both backends with no tracked
leaks. Replacing its stale row gives 1,062,756 invocations, 1,062,512 without
errors, and 244 errors across 55 failed jobs; the other failed jobs have not
been rerun against these changes.

`tkt-f777251dc7a.test` caught the executor opening a B-tree cursor after an
active VDBE was expired by transaction rollback. The `OP_OpenRead`/`OP_OpenWrite`
and reopen paths now return `SQLITE_ABORT_ROLLBACK` for immediate expiration,
as upstream does. The unchanged test passes 10/10 on both backends with no
tracked leaks. Replacing its stale row gives 1,062,756 invocations, 1,062,514
without errors, and 242 errors across 54 failed jobs. The other failed jobs
have not been rerun against these changes.

`corruptH.test` exposed `clearDatabasePage()` reporting an unexpected page
reference count as `SQLITE_LOCKED` instead of `SQLITE_CORRUPT_PAGE`. The B-tree
port now uses the upstream corruption error for that invariant. The unchanged
test passes 10/10 on native and GCC with no tracked leaks. Replacing its stale
row gives 1,062,756 invocations, 1,062,515 without errors, and 241 errors
across 53 failed jobs. The other failed jobs have not been rerun against these
changes.

The same correction resolves `corruptN-6.1` and `corruptN-6.3`, where page
reference mismatches also must report corruption. At that checkpoint,
`corruptN.test` passed 17/18 on native and GCC with no tracked leaks; its
remaining failure involved two indexes with a deliberately duplicated root
page. Replacing the stale row reduced the composite to 1,062,756 invocations,
1,062,517 without errors, and 239 errors across 53 failed jobs.

The `corruptN-4.2` failure came from `sqlite3BtreeDelete()` turning a successful
cursor restore to `CURSOR_SKIPNEXT` into `SQLITE_CORRUPT`. When another cursor
with the same root page has removed the saved key, upstream treats this delete
as a no-op. The port now follows that behavior. The unchanged `corruptN.test`
passes 18/18 on native and GCC with no tracked leaks.

`corruptI-6.1` exposed a second mismatch for a cell with a payload size of
`UINT32_MAX`. SQLite's u32 overflow-page rounding wraps to zero for this
corrupted size, allowing DELETE to discard the cell without walking an invalid
overflow chain. The port now preserves that defined wrap and bounds all
nonzero overflow walks by the database page count. The unchanged
`corruptI.test` passes 24/24 on native and GCC with no tracked leaks.
The current `corruptJ.test` rerun also passes 6/6 on native and GCC. Its two
self-child corruption cases now report `SQLITE_CORRUPT` instead of
`SQLITE_LOCKED`, matching the expected error.

`securedel2.test` also passes all 13 cases on native and GCC, with no tracked
leaks. This refresh covers its four stale failures from the earlier run; the
current implementation returns strict 0/1 booleans to the B-tree secure-delete
setting.

Replacing the four stale rows (`corruptN`, `corruptI`, `corruptJ`, and
`securedel2`) in the composite gives 1,062,756 invocations, 1,062,525 without
errors, and 231 errors across 49 failed jobs. The other failed jobs have not
been rerun against these changes.

The six repaired or fixture-adjusted files (`malloc8`, `autoinc`, `fkey8`,
`securedel`, `pragma`, and `trace3`) were rerun on the current native and
GCC-backend test profiles. All twelve runs passed with no tracked leaks.

The earlier full run preceded the latest `badutf.test`,
`tkt-78e04e52ea.test`, and `hexlit.test` fixes; those files now pass in focused
native and GCC reruns.
The focused distinct-label total cannot be subtracted from the C suite's
invocation total because they count different things.

The unchanged `rowvalueA.test` passes 35/35 on C `testfixture`, native
FreeBASIC, and the GCC backend, with no tracked FreeBASIC leaks. Its 2,000-row
`VALUES` list exposed an extra compound-SELECT limit in `sqlite3SelectDup()`.
Upstream copies the full `pPrior` chain and applies the compound-term limit
during compilation; `SF_MultiValue` rows are exempt and generated code is
bounded by `SQLITE_MAX_VDBE_OP`. The port now copies the full chain. The same
test caught missing comparison affinity in the tableless SELECT emitter;
comparison opcodes now use the source expressions to set P5 and preserve
NULL-equal behavior for `IS` and `IS NOT`.

Replacing the stale `rowvalueA.test` row removes its four errors from the
composite, giving 1,062,756 invocations, 1,062,529 without errors, and 227
errors across 48 failed jobs. The other failed jobs have not been rerun against
these changes. Its 33 distinct C-common labels bring the focused ledger to
421,152.

The unchanged `crash.test` passes on C `testfixture` (858/858), native
FreeBASIC (906/906), and GCC-backend FreeBASIC (897/897), with no tracked
FreeBASIC leaks. This crash-replay workload produces run-dependent case
counts. The current C-common labels were already present in the focused ledger.
Replacing the stale native row (271 invocations, 76 errors) with its current
result updates the composite to 1,063,391 invocations, 1,063,240 without
errors, and 151 errors across 47 failed jobs. The other failed jobs have not
been rerun against these changes.

The unchanged `crash2.test` passes 84/84 on C `testfixture`, native FreeBASIC,
and GCC-backend FreeBASIC, with no tracked FreeBASIC leaks. Replacing its
stale row removes 36 errors while keeping the invocation total unchanged; the
composite now has 1,063,391 invocations, 1,063,276 without errors, and 115
errors across 46 failed jobs. These case labels were already included in the
focused ledger; the other failed jobs have not been rerun against these
changes.

The unchanged `fuzz.test` passes 35,036/35,036 on C `testfixture`, native
FreeBASIC, and GCC-backend FreeBASIC, with no tracked FreeBASIC leaks. It
exposed an unresolved OFFSET continue label in internal SELECT rows; resolving
the label cleared 26 generated-query errors. Two remaining cases showed that
simple and grouped aggregate paths emitted sorter code without the
`OP_OffsetLimit` counter. Both now reserve the adjacent register and compute
LIMIT+OFFSET before aggregate output. Replacing the stale fuzz row removes its
28 errors; the composite now has 1,063,391 invocations, 1,063,304 without
errors, and 87 errors across 45 failed jobs. The other failed jobs have not
been rerun against these changes. Its 35,035 distinct C-common labels bring
the focused ledger to 456,187.

The unchanged `ext/intck/intckfault.test` passes 34,200/34,200 on native and
GCC-backend FreeBASIC, with no tracked allocations remaining. The OOM cleanup
path in `sqlite3_str_vappendf` now consumes the remaining format arguments
without rendering so later `%z` arguments are released after an accumulator
error. Replacing its stale row (34,707 invocations, 29 errors) updates the
composite to 1,062,884 invocations, 1,062,826 without errors, and 58 errors
across 44 failed jobs. Its 31,282 distinct C-common labels bring the focused
ledger to 487,469.

The unchanged `istrue.test` exposed eager conversion of bare `true` and
`false` identifiers into literals. The parser now preserves them as identifiers
until name resolution binds a matching column or converts an unresolved name
to a boolean literal. `istrue.test` passes 57/57 on C, native, and GCC with no
tracked leaks. The adjacent unchanged `keyword1.test` and `altertab3.test`
also pass 117/117 each on all three profiles, with matching labels and no
tracked leaks. Replacing the stale `istrue.test` row (57 invocations, 1 error)
updates the composite to 1,062,884 invocations, 1,062,827 without errors, and
57 errors across 43 failed jobs. Its 56 C-common labels, plus 116 from
`keyword1.test` and 112 from `altertab3.test`, bring the focused ledger to
487,753.

The unchanged `ieee754.test` exposed loss of the sign bit for `-0.0` in the
tableless expression compiler. `TK_UMINUS` now negates a `TK_FLOAT` literal
before loading it, matching SQLite's direct real-literal code path. The test
passes 36/36 on C, native, and GCC with matching labels and no tracked leaks.
Replacing its stale row (36 invocations, 1 error) leaves 1,062,884 composite
invocations, with 1,062,828 without errors and 56 errors across 42 failed
jobs. Its 35 C-common labels bring the focused ledger to 487,788.

The unchanged `fordelete.test` exposed a VDBE record-decoder mismatch for
zero-sized and empty record headers. The port now accepts these historical
encodings and returns NULL for missing fields, matching SQLite's C executor.
`fordelete.test` passes 20/20 on C, native, and GCC with matching labels and no
tracked leaks. `rowvalueA.test` was rerun as a corruption regression and also
passes 35/35 on all three profiles with no tracked leaks. Replacing the stale
`fordelete.test` row (20 invocations, 2 errors) leaves 1,062,884 composite
invocations, 1,062,830 without errors, and 54 errors across 41 failed jobs.
Its 19 C-common labels bring the focused ledger to 487,807.

The unchanged `exclusive2.test` exposed the pager clearing `changeCountDone`
after each commit even while the exclusive lock remained held. The port now
retains that state across exclusive commits and resets it when normal locking
releases the file lock. The test passes 29/29 on C, native, and GCC with
matching labels and no tracked leaks. Replacing its stale row (29 invocations,
3 errors) leaves 1,062,884 composite invocations, with 1,062,833 without
errors and 51 errors across 40 failed jobs. Its 28 C-common labels bring the
focused ledger to 487,835.

`utf16align.test` and `mallocK.test` exposed missing `SQLITE_UTF16_ALIGNED`
handling in `sqlite3ValueText()`. The port now separates the alignment modifier
from the text encoding and copies odd-addressed strings to aligned storage
before calling the collation. `utf16align.test` passes 7/7 on C, native, and
GCC. `mallocK.test` passes 4,020/4,020 on C and 3,910/3,910 on native and GCC;
the feature profiles run different fault counts, with 3,859 matching labels.
All runs end without tracked leaks. Replacing their stale rows (mallocK: 4,014
invocations, 4 errors; utf16align: 7 invocations, 1 error) leaves 1,062,780
composite invocations, 1,062,734 without errors, and 46 errors across 38 failed
jobs. Their 3,859 and 6 common labels bring the focused ledger to 491,700.

The unchanged `hook2.test` exposed an omitted preprocessor guard around the
single-index REPLACE shortcut in the generated constraint-check path. That
shortcut skips the conflict check and pre-update-only `OP_Delete`, so the
callback missed the replaced row in a WITHOUT ROWID table. The port now keeps
the shortcut disabled when `SQLITE_ENABLE_PREUPDATE_HOOK` is set. The test
passes 35/35 on C, native, and GCC with matching labels and no tracked leaks.
Replacing its stale row (35 invocations, 1 error) leaves 1,062,780 composite
invocations, 1,062,735 without errors, and 45 errors across 37 failed jobs.
Its 34 C-common labels bring the focused ledger to 491,734.

The unchanged `hook.test` exposed missing pre-update events for ANALYZE writes
to `sqlite_stat1`. When the pre-update hook is active, the port now deletes
existing statistics through nested SQL and attaches temporary `sqlite_stat1`
metadata to the VDBE insert opcodes. The test passes 108/108 on C, native, and
GCC, with no tracked leaks. Replacing the stale full-run row (108 invocations,
2 errors) leaves 1,062,780 composite invocations, 1,062,737 without errors,
and 43 errors across 36 failed jobs. All 1,516 suite jobs have been run; 1,480
currently have no errors. The focused ledger still records 491,734 distinct
labels; this profile's labels need cross-run reconciliation before they can be
added to that deduplicated count.

The follow-up `crash.test` run also passes: C completes 888 cases and native
FreeBASIC completes 897, with no tracked leaks; the previously recorded GCC
run passed 897. Replacing the earlier 906-invocation native row (zero errors)
updates the composite to 1,062,771 invocations, 1,062,728 without errors, and
43 errors across 36 failed jobs. The distinct-label count is unchanged because
the current native labels were already represented by the earlier crash run.

The grouped SELECT path now reapplies aggregate analysis after WHERE planning
finds usable expression-index columns, then converts those matches to index
column references. This removes redundant `->>` function calls from the
aggregate scan. The unchanged `tkt-99378177930f87bd.test` passes all 16
invocations on C, native, and GCC; `indexexpr1.test` passes 117/117 on all
three profiles, with no tracked leaks. Replacing the stale tkt row (16
invocations, 3 errors) leaves 1,062,771 composite invocations, 1,062,731
without errors, and 40 errors across 35 failed jobs. Its 15 shared case labels
bring the focused ledger to 491,749. There are now 1,481 error-free jobs among
the 1,516 suite jobs.

The unchanged `sqllimits1.test` exposed a debug-only trigger-frame leak while
rolling back an INSERT at the page-count limit. VDBE frame reuse now clears
value-type bits while preserving dynamic ownership flags. The large BLOB
literal scan is also bounded by `SQLITE_LIMIT_SQL_LENGTH`, since its hex token
is twice the decoded BLOB length. The test records 3,122 invocations with no
errors or tracked leaks on C, native, and GCC. Replacing its stale row (3,122
invocations, 1 error) leaves 1,062,771 composite invocations, 1,062,732
without errors, and 39 errors across 34 failed jobs. Its 2,124 shared distinct
labels bring the focused ledger to 495,997. There are now 1,482 error-free
jobs among the 1,516 suite jobs.

The unchanged `exprfault.test` now passes on C (1,007 invocations), native
FreeBASIC (993), and GCC (993), with no tracked leaks. The fault schedules
produce profile-dependent invocation counts. Replacing the stale native row
(993 invocations, 1 error) leaves 1,062,771 composite invocations, 1,062,733
without errors, and 38 errors across 33 failed jobs. Its 451 new C-common
labels bring the focused ledger to 496,448. There are now 1,483 error-free
jobs among the 1,516 suite jobs.

The unchanged `mallocB.test` also passes on C (1,581 invocations), native
FreeBASIC (1,499), and GCC (1,499), with no tracked leaks. The fault profiles
run different allocation counts. Replacing the stale native row (1,499
invocations, 1 error) leaves 1,062,771 composite invocations, 1,062,734
without errors, and 37 errors across 32 failed jobs. Its 1,498 shared labels
bring the focused ledger to 497,946. There are now 1,484 error-free jobs among
the 1,516 suite jobs.

The unchanged `mallocH.test` now passes on C (1,093 invocations), native
FreeBASIC (1,173), and GCC (1,173), with no tracked leaks. Fault schedules
produce different invocation counts. Replacing the stale native row (1,173
invocations, 1 error) leaves 1,062,771 composite invocations, 1,062,735
without errors, and 36 errors across 31 failed jobs. Its 840 shared distinct
labels bring the focused ledger to 498,786. There are now 1,485 error-free
jobs among the 1,516 suite jobs.

The unchanged `fkey2.test` passes 1,217/1,217 on C, native FreeBASIC, and GCC,
with no tracked leaks. Its case labels were already in the focused ledger.
Replacing the stale native row (1,217 invocations, 1 error) leaves 1,062,771
composite invocations, 1,062,735 without errors, and 36 errors across 31
failed jobs. There are now 1,485 error-free jobs among the 1,516 suite jobs.

The unchanged `without_rowid3.test` passes 1,198/1,198 on C, native FreeBASIC,
and GCC with no tracked leaks. Its labels were already in the focused ledger.
Replacing the stale native row (1,198 invocations, 1 error) leaves 1,062,771
composite invocations, 1,062,736 without errors, and 35 errors across 30
failed jobs. There are now 1,486 error-free jobs among the 1,516 suite jobs.

## Runtime checkpoint (2026-10-16)

The default and `SQLITE_ENABLE_PREUPDATE_HOOK` libraries build. The unchanged
upstream `test/hook.test` passes 103/103, including ALTER TABLE defaults,
WITHOUT ROWID updates, and nested triggers. A temporary Tcl bridge shim maps
extended code 531 to the symbolic name expected by `hook-3.6b`; a direct C ABI
probe confirms `sqlite3ErrName(531)` returns `SQLITE_CONSTRAINT_COMMITHOOK`.
The upstream test source remains unchanged.

`sqlite3BtreeOpen()` now applies `sqlite3TempInMemory()` when it opens an
unnamed TEMP database, so `PRAGMA temp_store` controls the TEMP pager as in
upstream. `sqlite3PagerOpen()` leaves journal mode OFF when an in-memory pager
was opened with journaling omitted, preserving the debug pager invariant. The
release, debug, and omit-deserialize temp-store probes pass. The unchanged
`pragma.test` TEMP-store checks pass (9.1.1, 9.2.1, and 9.3.1). `sqlite3VdbeExec`
follows the `OP_Init.P3` corruption target when `OP_Column` encounters a
malformed record, so `pragma-24.2` also passes. Right-edge B-tree insertion now
uses `balance_quick()` when the expanded root has no separator cells, matching
upstream page allocation. The 1,024-row insertion workload now matches the C
reference page count at every doubling step. The unchanged `pragma.test` passes
all 127 cases enabled by the FB Tcl bridge, with no tracked allocations. The
upstream test source remains unchanged.

This pass corrected four FreeBASIC runtime paths: parser lookaside accounting
for ALTER ADD schema reload, default semantic copies for multi-token Lemon
rules, rename-token preservation for identifier and expression-list names,
and `OP_SetCookie` handling when P4 is unused. `OP_ParseSchema` also permits an
unopened TEMP B-tree, `OP_Column` loads P4_MEM defaults for older rows, and
B-tree insertion preserves an exact-match index cursor during multi-row
WITHOUT ROWID updates. The source routines already had translated bodies, so
C2FB required no change for these repairs.

The unchanged upstream `hook.test` passes 103/103. `alter3.test` passes 43/43
with temporary `hexio_read` and `hexio_get_int` fixture helpers, and
`alter4.test` passes 42/42. `altercol.test` passes 257/257 with its VTab cases
enabled through a temporary schema-only echo module; the upstream test file is
unchanged. All tracked allocations are freed at shutdown. Default-profile C
probes verify ALTER defaults, `PRAGMA schema_version`, and multi-row WITHOUT
ROWID updates.

A direct C ABI smoke now exercises a three-row `:memory:` table with an
integer primary key, integer and text columns, and an index on the integer
column. It verifies table and forced-index scans, a range scan ordered by the
index while reading a non-indexed text column, NULL lookup, `COUNT(*)`, update,
delete, rollback, statement finalization, and connection close. All statements
return `SQLITE_DONE`, `sqlite3_close` returns `SQLITE_OK`, and lookaside usage
returns to zero after each finalized statement. The release and `SQLITE_DEBUG`
libraries pass this smoke.

`make -C fb_src check-interrupt` builds the library in temporary storage and
checks that a progress callback calling `sqlite3_interrupt()` stops a long
SQL preparation with `SQLITE_INTERRUPT`. The test removes its library, client,
and executable when it finishes. Pass `THREADSAFE=0` to check the no-op mutex
profile as well.

A second direct C ABI smoke uses a file-backed database. It creates parent and
child tables plus an index, inserts three rows, and checks ordered reads,
plain and aggregate `GROUP BY`, `LEFT JOIN` with `COUNT` and `SUM`, an `IN`
subquery, a correlated scalar subquery with `LIMIT`, scalar aggregate subqueries
using `COUNT(*)` and `MAX`, and close/reopen. The printed rows match the fixture
values, all statements return `SQLITE_DONE`, and both release and `SQLITE_DEBUG`
libraries pass. The debug profile marks persistent B-trees sharable, so this
also exercises recursive B-tree entry and table-lock cleanup. It does not test
two simultaneous connections using shared cache.

Function-expression cleanup previously leaked the argument list and its
expression because `sqlite3ExprAlloc` marked every new node `EP_Leaf`. The
allocator now leaves flags zeroed, matching SQLite; constructors mark leaf
nodes only where required. Release and debug C ABI probes now pass scalar and
aggregate functions with arguments, with lookaside usage returning to zero
after each finalized statement. UTF-16 `group_concat` returns `a:b` and closes
the connection successfully. This was an existing port bug, not a missing
routine, so no C2FB or FBC change was needed.

This caught several integration errors in existing bodies: index cursors were
rejected by the deferred-seek check; cursor cleanup skipped sorter destruction;
index metadata left `colNotIdxed` unset and misclassified non-covering scans;
aggregate helpers repeated `sqlite3ArrayAllocate` and `sqlite3ExprAlloc` calls,
leaving empty aggregate slots and an orphan expression; and ROLLBACK encoded a
FreeBASIC true value of -1 instead of the C opcode operand 1. The pager debug
assertions also exposed the missing `changeCountDone = tempFile` initialization
for temporary and in-memory pagers. These repairs are in the SQLite port; no
additional function bodies were needed. The aggregate allocation duplication
came from older generated module output; the C2FB source was left unchanged in
this run.

The file-backed probe also exposed integration issues in the existing B-tree
and aggregate bodies. Shared B-tree wrappers and cursor creation now use the
recursive `sqlite3BtreeEnter`/`sqlite3BtreeLeave` path, and transaction end
removes embedded schema/table-lock entries while maintaining shared transaction
counts. Cursor allocation no longer rejects an undefined VDBE cursor cell just
because its `db` field is unset. The older generated aggregate helper emitted
one `sqlite3VdbeAddOp1(OP_If, ...)` call twice; the integrated body now emits
and patches one instruction. No converter source or test source was changed.

The scalar aggregate probe exposed a VDBE finalization error: negative `P2`
operands on non-jump opcodes were being treated as jump-label references.
`resolveP2Values` now resolves negative operands only for opcodes marked
`OPFLG_JUMP`, preserving negative immediates such as `OP_AddImm P2=-1`. Scalar
`COUNT(*)` and `MAX` subqueries, including a correlated aggregate, now pass in
release and `SQLITE_DEBUG` builds.

The integrity and foreign-key probe then found three more integration defects.
`OP_IsType` now handles cached cursor serial types as well as register values,
and the generic `releasePage` path decrements duplicate references to page one
while the B-tree's base page-one reference retains its dedicated release path.
Savepoint rollback now passes an exact C integer boolean to cursor invalidation.
VDBE halt/reset cleanup also drains deferred trigger frames through
`closeAllCursors`. In release and debug builds, a failed foreign-key insert
followed by cascading delete, `ROLLBACK TO`, `RELEASE`, `foreign_key_check`,
`integrity_check`, and file reopen restores the original rows and closes with
`SQLITE_OK`; lookaside usage returns to zero. No converter or test source was
changed.

A trigger/view probe found an omitted Lemon default token copy: the
`createkw ::= CREATE` reduction did not preserve the CREATE token used to form
view SQL and trigger spans. It now copies the token into the result. Existing
trigger bodies also repeated side-effecting allocator and hash calls; those
calls now run once. `OP_Program` accepts SQLite's negative parameter-base
offsets and validates the final parent register used by `OP_Param`. The VDBE
`OP_Concat` handler now follows SQLite's `P2 || P1` operand order. Release and
debug C ABI probes pass CREATE VIEW, INSERT/UPDATE/DELETE triggers, OLD/NEW
values, `RAISE(ABORT)`, `RAISE(IGNORE)`, integrity checking, and close.

Attached-database testing exposed several transaction and parser-lifetime
defects. Opening a super-journal passes a null optional `pOutFlags`; the generic
OS wrapper and Unix VFS now accept that call. File rollback no longer clears
the page cache before journal playback, and internal playback preserves the
current page size while handling zero-record journal headers. Successful VDBE
commits now clear `DBFLAG_SchemaChange`, and `sqlite3RollbackAll` passes a
0/1 C boolean to B-tree rollback. The parser driver now frees transient tables,
triggers, variable lists, and VFS locks after parsing; nested SQL keeps the
outer parse's table/index/trigger state intact. This removes stale foreign-key
entries that had generated an `OpenRead` on root page zero. The executor also
passes root page zero and optional P4 text through `OP_TableLock` and
`OP_OpenRead` to the B-tree layer, as SQLite does.

Release and debug C ABI probes now pass file-backed `ROLLBACK`, foreign-key
cascade delete, savepoint rollback, `integrity_check`, and a two-file
super-journal transaction. Both attached databases preserve their committed
rows after a cross-database rollback, then detach and reopen successfully.

WAL runtime probes exposed missing transaction wiring and pager cleanup. WAL
writers now take the WAL write lock, append frames during phase one, and end
that transaction during phase two. Releasing the last page reference runs the
full pager teardown so WAL read locks do not remain held across transactions.
Full rollback rewinds uncommitted frames; savepoint rollback rewinds its frame
set and restores page images from the subjournal. Release and debug C ABI probes
pass writer commits, reader snapshot visibility, full rollback, nested
`ROLLBACK TO`, truncate checkpoint, `integrity_check`, and reopen. Existing
in-memory DML and savepoint probes also pass in both profiles. The WAL frame,
undo, and pager teardown bodies were already present as C2FB candidates, so this
work only added the missing pager branches and module bridges; no C2FB or FBC
source change was needed.

The unchanged upstream `test/wal.test` passes 581/581 on the C reference
fixture. The FreeBASIC `SQLITE_TEST` runner completes 581 test cases with zero
failures and no tracked leaks. Its temporary Tcl bridge loads the FreeBASIC
library in both the main and child processes, and matches the fixture's 1 KiB
page size, 64 KiB pending-byte offset, and current-directory capability. No
upstream test source was changed.

The initial WAL run exposed and fixed three port issues. Passive checkpoint
busy codes are cleared even when there is no iterator to backfill;
`wal-10.2.14` now reports a successful partial checkpoint. `sqlite3_log()` now
passes the full 10,000-byte stack-buffer capacity to the formatter instead of
`SizeOf(array)`, which is only one element in FreeBASIC; the recovery event in
`wal-23.4` now includes its formatted message. The pending-byte test control
now drives both the B-tree's reserved-page skip and Unix VFS lock offsets.
Auto-vacuum skips the 64 KiB lock page. `wal-8.2`, `wal-8.3`, and the
attached-database `wal-26` cases pass. The VDBE accepts SQLite's all-database sentinel only for
`OP_Checkpoint`; a direct C ABI `PRAGMA wal_checkpoint(TRUNCATE)` smoke passes.

The unchanged upstream `test/wal2.test` through `test/wal9.test` now pass
alongside `test/wal.test`: 1,843 cases total, with no failures or tracked
leaks. This exposed a checkpoint path that returned as soon as all WAL frames
were backfilled. RESTART and TRUNCATE must still wait for reader locks and
reset or truncate the WAL in that state; `walCheckpoint()` now skips only the
page-copy work. Read-only shared-memory mapping and recovered WAL-index frame
lookup also pass their WAL2/WAL3 cases. The temporary Tcl bridge links directly
to the FreeBASIC test library and provides its expected checkpoint command and
sync counters. No upstream test files changed. The ordinary release
shared-library build also passes. The affected functions already had
FreeBASIC bodies, so no C2FB or compiler change was needed.

The unchanged `walhook.test` passes 15/15 and `walbak.test` passes 84/84, both
with no tracked leaks. The reverse-backup cases exposed a release-build bug:
`sqlite3_backup_step()` opened a temporary read transaction on the WAL source,
but the port only closed it under `SQLITE_DEBUG`. The source transaction now
closes in every build, so a later backup can use that connection as a WAL-mode
destination. A direct C ABI probe confirms the source transaction returns to
`SQLITE_TXN_NONE` before the reverse backup begins.

The unchanged `walmode.test` passes 94/94 and `walckptnoop.test` passes 12/12,
with no tracked leaks; the upstream C fixture passes both suites as well.
These runs exercise persistent WAL mode transitions, WAL-file lifecycle, and
no-op checkpoint accounting.

The unchanged `walpersist.test` passes 21/21 and `walrestart.test` passes
7/7, also with no tracked leaks and matching the C fixture. These checks cover
the PERSIST_WAL file-control path and the fault-simulated WAL restart race.
The temporary Tcl adapter supplies those test-control commands; the upstream
test files remain unchanged.

The unchanged `walro.test` passes 38/38 and `walro2.test` passes 264/264,
with no tracked leaks and matching C-fixture results. These exercise read-only
WAL connections, read-only shared-memory mappings, and recovery across page
sizes. The temporary multi-process runner uses the FreeBASIC library in its
child connections.

The unchanged `walvfs.test` passes 35/35 with no tracked leaks. Its VFS callback
cases caught an unsynchronized interrupt-flag read in the WAL checkpoint loop;
the loop now uses the synchronized interrupt helper and correctly propagates
interrupt and OOM results.

The rollback-journal tests exposed a commit/reset interaction. When an explicit
`COMMIT` cannot acquire the exclusive lock, the write transaction must remain
open and `sqlite3_reset()` must return the prior `SQLITE_BUSY`. The VDBE halt
path now preserves that error, and journal finalization retains the zeroed
journal in exclusive or persistent mode until the lock is released. A direct
C ABI probe confirms that the uncommitted updates remain visible to their
connection after the busy commit. The unchanged `pager3.test` (13/13),
`pager4.test` (12/12), `jrnlmode.test` (82/82), and `jrnlmode2.test` (14/14)
pass; the initial multi-client section of `pager1.test` also passes through
`pager1-3.6`. Later `pager1` sections need a working test VFS helper in the
temporary runner, so the full file has not been counted as passing.

The raw `translate-simple` pass rejects pager bodies whose active code is still
surrounded by C preprocessor branches. C2FB's preprocessed file mode selects
the build branch before translating and is the applicable path for those
functions. The WAL fixes in this run were missing caller integration in
existing FreeBASIC bodies, so they did not require a C2FB change.

The preprocessed file-selective C2FB run emitted 127 pager candidates, including
`pagerStress`. Reviewing that candidate showed the rollback-mode spill path
should delegate writes to `pager_write_pagelist`; the FreeBASIC body now does
so, preserving the shared page-hash, size-hint, and backup updates. A direct C
ABI smoke with a one-page cache spilled 96 four-kilobyte blobs, rolled the
transaction back, committed the same workload, and passed `integrity_check`.

This remains evidence for the tested build profile, not a claim of complete
SQLite compatibility. The unchanged upstream Tcl suite now runs through the
C `testfixture` linked to a profile-specific
`libsqlite3-fb-testfixture-config` shared library built from the FreeBASIC
engine sources. The upstream C test-support objects remain in the fixture;
temporary C adapters supply a small number of test commands. The fixture
wrapper selects the native or GCC FreeBASIC library through `LD_LIBRARY_PATH`.
No upstream test source was changed.

Mutex initialization now selects a default, no-op, or caller-supplied callback
table. `SQLITE_CONFIG_MUTEX` copies a validated method table and
`SQLITE_CONFIG_GETMUTEX` returns the current methods. With
`SQLITE_THREAD_MISUSE_WARNINGS`, the default provider wraps connection mutexes
and logs contention for handles opened with NOMUTEX. Default, misuse-warning,
debug/abort, no-op/misuse, and `THREADSAFE=0` library builds pass. C API probes
cover GETMUTEX state, method-table round trips, and thread-mode configuration.
The upstream standalone `test/threadtest4.c` stress program passes against C,
native FreeBASIC, and GCC-backend FreeBASIC in multithread, serialized, and WAL
modes with zero errors. The unchanged `mutex1.test` and `mutex2.test` pass
29/29 and 14/14 on C, native FreeBASIC, and GCC-backend FreeBASIC, covering
single-thread, multithread, and serialized mutex counters plus injected mutex
initialization failure. Native and GCC `THREADSAFE=0` C ABI smokes also open an
in-memory database, create and populate a table, read the aggregate result, and
close cleanly. Broader no-op provider behavior remains under validation.

STAT4 value extraction now invokes eligible deterministic or slow-change SQL
functions while building sample probe values. The path is compiled only with
`SQLITE_ENABLE_STAT4`; the unchanged `analyzeF.test` exercises this path and
passes all 27 cases on current native and GCC-backend STAT4 builds with no
tracked leaks.

B-tree cursor setup now uses the upstream scratch-space allocator and clears a
cursor if that allocation fails. VDBE statement arrays use the unused opcode
allocation tail as shared scratch space, with one spill block when the tail
cannot hold all arrays. VDBE deletion releases register and variable payloads
before freeing either backing block. Default and debug library builds pass;
runtime allocation behavior is unverified. Page-one initialization opens WAL
files when the header requests WAL and applies the journal-mode synchronous
default to the matching database slot. Debug builds now check parent-child page pointers,
and the cursor-hint opcode dispatches range and table-cursor hints under
`SQLITE_ENABLE_CURSOR_HINTS`. Default, differing WAL-sync, and debug cursor-hint
library profiles build; runtime behavior is unverified.

Shared-cache B-tree opens now canonicalize database paths, match the VFS and
path against the shared list, increment `BtShared.nRef`, and link each B-tree
handle into address order for mutex entry. Close rolls back that handle and
frees the shared pager only after the last reference. Default, debug, and
`THREADSAFE=0` library builds pass; runtime shared-cache behavior is unverified.

Expression-list construction now routes through separate new-list and growth
helpers in `sqlite3_expr.bas`. They retain SQLite's four-item initial capacity,
double capacity as needed, initialize new items, and dispose of both the list
and pending expression when growth fails. The default library build passes;
runtime behavior remains unverified.

`sqlite3ExprDup()` preserves reduced/token-only input prefixes for ordinary
full copies, relocates inline token strings, and duplicates window definitions.
`EXPRDUP_REDUCE` requests now place each left/right expression tree in one
SQLite-owned buffer and mark its child nodes static, avoiding separate node
allocations. Copied Expr records remain full-sized because downstream
FreeBASIC readers do not consistently guard compact prefixes. A C ABI smoke
created a table with a default and CHECK expression, a view, and a trigger,
inserted data, reopened the database, and verified the view row and
`integrity_check`. Release and debug builds pass. Compact Expr records remain
unsupported; this path uses more memory than upstream SQLite.

`PORTING_PARSER_RULES.csv` tracks all 412 generated Lemon rules separately from
the C function ledger. All 348 rules with custom semantic actions now have
FreeBASIC cases; the other 64 use Lemon's default
semantic-value copy. Recent reductions handle parenthesized `FROM` lists,
including their source-item ownership transfers, and the DROP TABLE, VIEW,
INDEX, and TRIGGER commands. CREATE INDEX and ATTACH/DETACH are wired, as are
trigger creation, trigger command lists, DML trigger steps, and `RAISE`
expressions. DML reductions now construct UPDATE assignment lists, including
vector assignments, and dispatch DELETE, UPDATE, INSERT, UPSERT, and RETURNING
operations. IdList reductions use the dedicated parser minor field. The
expression reductions now include current-time functions, row vectors, pointer
expressions, scalar subqueries, `IN` subqueries and table-valued functions,
`EXISTS`, qualified column names, ordered function arguments, window
attachments, and parenthesized expression lists. ALTER TABLE column and
constraint operations, virtual-table declarations, window definitions, frame
bounds, FILTER, and OVER clauses are now connected to their existing engine
helpers.
`make -C fb_src regen-generated` refreshes this ledger with the parser rule IDs.

The latest default-profile C2FB sweep processed 79 tracked engine C inputs in
eight balanced batches, with no preprocessing failures. It emitted 127
procedure candidates, and none matched an uncovered function row. The focused
`SQLITE_TEST` plus `SQLITE_DEBUG` pass over `wal.c` emitted `walLockName` after
C2FB gained support for zero-initialized local static arrays. That helper is
integrated under the same guards as the C source. `walHandleException` has a
FreeBASIC body that releases transient WAL locks and restores deferred WAL-index
state, and it compiles in the SEH profile. The FreeBASIC WAL module still has no
`__try`/`__except` boundary to call it. The exception filter and fault injector
now have bodies with the upstream exception code and argument layout, and the
default, Windows SEH, and debug Windows SEH WAL objects compile. Without the
boundary, WAL operations do not invoke the filter, and injected faults are not
caught. Default and debug/test library builds pass; runtime behavior is
unverified. The Windows thread callback `sqlite3ThreadProc` is
also ported with the original StdCall convention and `_endthreadex`; the
Windows target build is unverified. The five constant-propagation helpers from
`select.c` are ported in `sqlite3_select_constant_propagation.bas` and now run
after FROM-subquery flattening in the table-backed SELECT path. The unchanged
`whereL.test` passes 28/28, including the join-order cases that require the
rewrite.

The B-tree `OP_Column` path now decodes only enough record header to reach the
requested column and reads overflow content through `vdbeColumnFromOverflow`.
Large table TEXT/BLOB values use the existing reference-counted string allocator
and cursor cleanup path. The default shared-library build passes; runtime
behavior is unverified. The SQLITE_DEBUG library now checks the fast record
comparators against generic Mem comparison and validates KeyInfo field limits;
that debug profile builds, but runtime assertion behavior is unverified.

The optional `SQLITE_ENABLE_IOTRACE` profile now exports `sqlite3IoTrace` and
formats normalized SQL for the callback at VDBE entry. The profile builds and
exports both trace symbols; callback output is unverified at runtime.

Initial follow-up passes translated `mem2.c` and `os_kv.c` with
`SQLITE_MEMDEBUG` and `SQLITE_OS_KV`, then `os_unix.c` with debug,
locking-style, timeout, and mmap options. Those passes emitted six and 14
candidates, all already represented by existing function bodies. C2FB rejected
the guarded MEM2 allocator because its shared record state and allocation
layout are outside the body subset; all 20 indexed `mem2.c` functions have
since been ported directly in `sqlite3_memdebug.bas`.

A later default-profile batch over 16 files emitted 66 procedure candidates:
36 compiled individually and 30 failed, but every passing name already had a
FreeBASIC body. The guard audit found that most remaining functions are behind
optional or platform-specific macros. Other skips use source-local globals or
callback fields whose ABI types are not supplied to C2FB. The FTS3 tokenizer
candidates now provide those types through the
`sqlite-fts3-tokenizer-body.rsp` profile.

A feature pass using `SQLITE_MAX_ATTACHED=32` and explain comments compiled six
candidate procedures, all already present in the port. C2FB skipped
`analyzeVdbeCommentIndexWithColumnName` on the `NEVER()` macro expansion, so
the helper and its three opcode-comment call sites were ported directly in
`sqlite3_analyze.bas`. The debug/explain library builds; runtime comment output
remains unverified.

A remaining-source batch processed 12 C inputs with debug, Unix locking, and
assertion-stub options. It emitted 76 candidates with no preprocessing
failures, but none matched an uncovered function row. A separate
`SQLITE_MAX_ATTACHED=32` pass exposed C array-typedef parameter decay and the
`sizeof(yDbMask)` extent. C2FB now emits `sqlite3DbMaskAllZero` with a `UByte
Ptr` parameter and the correct five-byte extent. The helper is integrated in
`sqlite3_build.bas` under `SQLITE_MAX_ATTACHED>30`; that module compiles in the
max-32 profile. Runtime behavior and the other wide-mask operations remain
unverified.

An earlier IOTRACE/SQLLOG candidate pass over `vdbeaux.c` did not produce an
uncovered body. `sqlite3VdbeIOTraceSql` is now ported in `sqlite3_iotrace.bas`
and called at VDBE entry; the feature build exports both trace symbols. The
SQLLOG callback now receives open, completed-statement, and close events when
`SQLITE_ENABLE_SQLLOG` is enabled; statement text is expanded before dispatch.
The SQLLOG feature library builds. `checkActiveVdbeCnt` also checks active,
reader, and writer counters after cursor cleanup and VDBE halt. Debug, IOTRACE,
and SQLLOG runtime output remains unverified.

The Unix VFS now uses `seekAndRead`, `seekAndWriteFd`, and `seekAndWrite` for
positioned I/O. Reads retry interrupted calls, report short reads after
zero-filling the remaining buffer, and preserve the last system error. Writes
retry interrupted calls and retain SQLite's short-write and disk-full results.
The close path logs descriptor errors without retrying `close()` after
`EINTR`, and last-error storage uses a shared helper.
The final inode-reference close drains its deferred-descriptor list through
`releaseInodeInfo` and `closePendingFds` before freeing the shared lock record.
The main-database open/close path checks link count and inode identity, and
`SQLITE_FCNTL_HAS_MOVED` reports path replacement or unlinking.
The VFS creates random, collision-checked temporary filenames under its temp
directory mutex and exposes them through `SQLITE_FCNTL_TEMPFILENAME`.
File controls query or change persistent-WAL and powersafe-overwrite flags.
Sector size and device capabilities are initialized lazily, including optional
F2FS atomic-write detection.
Descriptor diagnostics, null-I/O, file/VFS pointer, and VFS-name controls are
also handled by the Unix file-control callback.
Chunk-size and size-hint controls round requested growth and extend the file
before remapping when required. The WAL external-reader control checks for
conflicting reader locks in the shared-memory lock range.
The Unix VFS module compiles in normal and `SQLITE_TEST` profiles; runtime I/O
behavior remains unverified.

Unix WAL shared-memory opens now use SQLite's deadman-switch byte at offset
128. The first writable opener takes an exclusive lock, initializes the
shared-memory file, and downgrades to a shared lock; read-only openers can
retry after another process initializes it. Database exclusive locking checks
for another process's DMS lock before proceeding. The default library builds;
cross-process WAL locking behavior remains unverified.

A full SQLITE_DEBUG/SQLITE_ENABLE_TREETRACE loose pass also preprocessed all
80 engine C inputs without failures. It emitted 168 procedures; per-procedure
compilation passed 95 and failed 73. Two passing procedures lacked bodies in
the ledger at scan time: parseuriFunc and sqlite3VdbeMemValidStrRep. Both are
integrated. fpdecodeFunc is also ported; parseuri and fpdecode are registered
only in SQLITE_DEBUG builds (78 indexed C lines). sqlite3VdbeMemValidStrRep
sits beside its private numeric renderer with the string termination and
allocation checks restored. Follow-up repairs added six procedures for JSONB
debug output, WHERE term tracing, and VDBE opcode rewrite traces (119 indexed C
lines). The JSON debug parser is registered only in SQLITE_DEBUG builds. A
preceding debug batch also added seven procedures across ALTER, B-tree,
expression walking, SELECT planning, and VDBE Mem (112 indexed C lines). The
six-file VFS/pager/VDBE batch emitted 31 procedures; 17 compiled, and all 17
already had bodies in the ledger. The MEMDEBUG port now implements guarded
allocation headers, list maintenance, trailer and padding checks, allocation
type tags, size-bucket statistics, backtrace controls, title storage, dump
output, and allocation counts. `sqlite3_memory.bas` selects these callbacks
when `SQLITE_MEMDEBUG` is enabled. For `THREADSAFE=0`, the memory-journal
method table now initializes without a mutex, since that profile does not
support concurrent SQLite calls. A direct C API probe passes in-memory
`CREATE TABLE` and `SELECT 1`; the unchanged `altercol.test` also passes 257/257
under `SQLITE_MEMDEBUG` with no allocations left at shutdown.

The current C2FB executable was rebuilt from its latest FreeBASIC sources and
rerun across all 80 engine C inputs with SQLITE_DEBUG, TREETRACE, and
WHERETRACE enabled. Preprocessing had no failures and produced 164 procedure
candidates; the 160 in-scope names already had bodies, so this broad pass added
no coverage. A selected pass over `wherecode.c`, `where.c`, `mem2.c`, and
`malloc.c` enabled cursor hints, STAT4, and MEMDEBUG. It emitted 12 candidate
procedures, nine of which compiled individually. The new eight-line
`sqlite3IndexColumnAffinity` body is integrated with bounds and allocation
checks. Together with the WHERE trace helpers, all 107 indexed functions and
6,399 indexed function lines from `src/where.c` now have FreeBASIC bodies.

The C2FB record catalog now maps the local C `CCurHint` record to
`SqliteCursorHint` in `sqlite3_walker.bi`. That allowed a cursor-hint batch to
emit and compile all four procedures in `wherecode.c`. The port adds the missing
`codeCursorHintCheckExpr`, `codeCursorHintFixExpr`, and 100-line `codeCursorHint`
procedures, then wires the three hint call sites into
`sqlite3WhereCodeOneLoopStart` under `SQLITE_ENABLE_CURSOR_HINTS`. The full
debug/cursor-hint library and the combined debug/trace/cursor-hint/STAT4 library
build; the default library also builds. At this stage, `src/wherecode.c` had
bodies for 27 of 28 indexed functions and 2,528 of 2,569 indexed function lines.

A selected batch enabled `SQLITE_ENABLE_SORTER_REFERENCES` and
`SQLITE_ENABLE_STMT_SCANSTATUS` across `select.c` and `wherecode.c`. It emitted
six candidates, five compiled, and two new bodies are integrated:
`selectExprDefer` selects primary-key columns for deferred sorter reads, and
`sqlite3WhereAddScanStatus` records outer-loop and OR-subloop scan entries.
The sorter path now carries the extra expressions through row loading and
updates the sorter record metadata. The default and combined sorter-reference/
scan-status libraries build. All 28 indexed functions and 2,569 indexed
function lines from `src/wherecode.c` now have FreeBASIC bodies. At that point,
`src/select.c` had bodies for 102 of 109 indexed functions and 6,845 of 7,147
indexed lines.

One of the remaining SELECT helpers, `sqlite3JoinType`, is now ported in
`sqlite3_bulk_select_join_type.bas`. It matches the three token slots against
SQLite's accepted keywords, rejects incompatible join masks, and retains the
existing parser diagnostic. The default and sorter/scan-status libraries build
with this 53-line body included.

The Unix locking-style batch now includes the dot-file and flock lock,
unlock, reserved-lock check, and close procedures. Under
`SQLITE_ENABLE_LOCKING_STYLE`, `sqlite3_os_init()` registers `unix-dotfile`
and `unix-flock` VFS entries. Dot-file locking creates a sibling `.lock`
directory and maps an existing directory to `SQLITE_BUSY`; both styles use
the shared Unix open, I/O, and close paths. The guarded Apple profile now
registers `unix-nfs` with a split-range unlock to avoid stale NFS write locks.
Default, locking-style, and debug/test locking-style library builds pass, and
the Apple-guarded object compiles locally; runtime locking behavior is
unverified. WAL shared-memory mappings now group 32 KiB regions to the host
page size, keeping offsets aligned when the host page is 64 KiB or larger.
The default Unix I/O methods also expose version 3 `xFetch`/`xUnfetch`: they map
reads on demand within the configured size, retain reference counts, and fall
back to `xRead` if mapping fails. `SQLITE_FCNTL_MMAP_SIZE` changes the mapping
limit after outstanding references are released. Default and locking-style
libraries, plus a build with a nonzero default mmap size, pass. The unchanged
`mmapcorrupt.test` passes 4/4 with mmap enabled. The later unchanged
`mmapfault.test` checkpoint below covers allocator and VFS faults through mapped
reads. The Unix VFS now has bodies for 112 of 135 indexed functions and 4,213
of 5,514 indexed lines at this earlier checkpoint.

The matching C2FB release-profile pass over `os_unix.c` enabled
`SQLITE_ENABLE_LOCKING_STYLE`, `SQLITE_ENABLE_SETLK_TIMEOUT`, and
`SQLITE_ENABLE_BATCH_ATOMIC_WRITE` with `NDEBUG=1`. It emitted 12 procedure
candidates; four compiled individually. The remaining flock helper closure was
ported together and included in the passing locking-style library build.
The latest loose source-aware pass emitted 13 simple procedures, all of which
already had bodies. The missing NFS unlock and timeout helper were then ported
as a guarded group, with `unix-nfs` method selection and VFS registration.
An Apple-macro C2FB pass used a temporary `TargetConditionals.h` stub for
preprocessing and emitted 16 simple procedures. Two uncovered helpers,
`proxyGetHostID` and `proxyCreateConchPathname`, came from that batch; four
additional proxy file/path helpers were ported together. The file-open helper
uses the Unix internal open path with no-follow and deferred-descriptor reuse.
At that checkpoint, the conch break and retry helpers had Apple-guarded bodies,
but `proxyTakeConch` and proxy method switching remained incomplete.
Apple-profile objects compile with `HAVE_GETHOSTUUID=0`, `HAVE_GETHOSTUUID=1`
plus `SQLITE_TEST`, and a `LOCKPROXYDIR` override; no native Apple runtime was
used. The proxy lock state machine was still unmapped at that checkpoint.

The refreshed loose C2FB pass translated all 80 engine C inputs without a
preprocessing failure. It emitted 164 procedures; the individual-procedure
screen checked 161, with 87 compiling and 74 failing. Every emitted name
already has a port body, so this broad pass added no coverage. A pager pass with
`SQLITE_DEBUG`, `SQLITE_CHECK_PAGES`, and `SQLITE_TEST` exposed four missing
page-hash helpers that compile individually. They are integrated into the
pager path, with the page check called before a page is made writable.
The debug `print_pager_state()` routine was rejected for its static local
buffer, so it now uses a module-static buffer with `sqlite3_snprintf()`.
`sqlite3PagerStats()` is also implemented under `SQLITE_TEST`; its C static
array became a module static array. The default library and a full
`SQLITE_DEBUG`/`SQLITE_CHECK_PAGES`/`SQLITE_TEST` library build pass. Runtime
page-hash, debug output, and test-hook behavior remains unverified.

A Windows-focused loose C2FB pass preprocessed `os_win.c` with
`SQLITE_OS_WIN=1` and `_WIN32=1`, emitting 14 candidates. Eight compile
individually; seven mapped to uncovered rows and are now implemented in the
guarded `sqlite3_os_win_helpers.bas` module: the UTF-8 directory setter, the
no-lock callbacks, sector-size query, UNC-path check, and temp-directory state
check. The eighth candidate wrapped the UTF-16 directory setter before that
conversion path was ported. The helper module now includes the
UTF-16 directory setters, UTF-8/UTF-16 and ANSI/OEM conversion helpers and
wrappers, the native filename conversion helper, VFS error formatting,
last-error, dynamic-library, debug-output, I/O-retry, file-handle, and mapping
callbacks, the Win32 sleep wrapper and callback, and both VFS clock callbacks.
It compiles in the default Unix library build and as separate debug/test and
release-profile objects with `SQLITE_OS_WIN=1`; a native Windows compiler and
runtime have not been used. Four more small path helpers now
recognize long-path, drive-letter, and verbatim prefixes, and append a trailing
separator within the supplied buffer. At that checkpoint, the module covered
65 Windows functions and 1,249 indexed C lines. C2FB now maps common Windows SDK scalar and pointer
types and reads the WinFile layouts from `sqlite3_os_win_types.bi`. A
source-name-preserving pass over the Windows-preprocessed `os_win.c` emitted 23
procedures; 12 compile individually. It exposed the mode-bit and device
characteristic callbacks, then the record layouts exposed shared-memory lock
and mapping candidates. The shared-memory lock, file-handle helpers, and
ordinary-file mmap fetch/unfetch callbacks were integrated in later batches.
The Windows backend now initializes the 60-entry syscall table before VFS
registration and connects its set/get/next callbacks to all four VFS variants.
Typed dispatch aliases route overrideable Win32 calls in the VFS and optional
heap allocator through the table. Table updates follow SQLite's unsynchronized
configuration model, so set overrides before concurrent I/O. Cygwin builds now
populate the POSIX syscall slots and convert UTF-8 paths through
`cygwin_conv_path`. Full-path resolution checks and follows symbolic links,
builds the Cygwin working-directory prefix, and simplifies the resulting path.
Temporary-directory lookup also checks the Cygwin environment variables and
standard POSIX locations. The branch follows Cygwin's documented size-query
call for `cygwin_conv_path` and its POSIX-to-wide-Windows conversion flags
([Cygwin API documentation](https://cygwin.com/cygwin/doc/preview/cygwin-api/func-cygwin-conv-path.html)).
FreeBASIC generated C for the Cygwin target; the object stage could not run
because `cygwin-gcc` is not installed, and native Cygwin runtime behavior is
unverified. Shared-memory mutex callbacks and the barrier are also in the
module.
The initial `mutex_w32.c` C2FB pass emitted no in-scope bodies because the
converter does not lower Interlocked operations or Windows lock records. The Windows backend now
implements all 11 indexed mutex functions (201 C lines) across
`sqlite3_mutex_windows.bi` and `sqlite3_os_win_helpers.bas`. Recursive locks use
`CRITICAL_SECTION`; fast and static locks use exclusive `SRWLOCK`s, with the
static lock storage aligned to the upstream 128-byte stride. Its debug,
release, misuse-warning, no-op, and single-thread objects compile under the
local FreeBASIC compiler with `SQLITE_OS_WIN=1`; a native Windows compiler and
runtime have not been used. Optional Windows mutex `OSTRACE`
messages are not ported. The Unix debug mutex queries now inspect this port's
shared bookkeeping mutex instead of the upstream per-inode mutex. C2FB still
rejects `lockTrace` at its indirect
syscall call, so that 47-line helper wraps the port's `unixFcntlRaw` dispatcher.
The `SQLITE_DEBUG`/`SQLITE_LOCK_TRACE` library profile builds; trace output is
unverified.

Since the previous checkpoint, this continuation added 28 function bodies
covering 716 indexed C lines. C2FB
ledger reconciliation now scans executable `.bi` bodies as well as `.bas`
modules, so included platform implementations are counted automatically.

The `SQLITE_ENABLE_SETLK_TIMEOUT` path now carries per-connection timeout and
block-on-connect settings through the Unix file-control interface and WAL
writer locks. The B-tree transaction path sets and clears the WAL connection
context, and stops busy-handler retries after a timed lock. The full
`SQLITE_DEBUG`/`SQLITE_TEST` build with timeout mode 1 and the full `SQLITE_TEST`
build with timeout mode 2 pass; runtime lock behavior remains unverified. The
pager's two `SQLITE_TEST` I/O-error suppression routines are implemented and
called around pager close. The Unix VFS test profile exports the C-named I/O
error, disk-full, open-file, and sync counters and applies pending I/O faults
to its read, write, sync, truncate, size, lock, delete, access, and temp-open
operations. The pager ledger now covers all 152 indexed functions and 5,104
function lines. Default, `SQLITE_TEST`, debug/test/setlk mode 1, and test/setlk
mode 2 library builds pass; no C test suite has been run and runtime fault
recovery and lock behavior remain unverified.

A feature-aware C2FB batch covered 17 remaining core files, including the B-tree,
planner, VDBE, allocator, and mutex sources. The batch emitted 92 unique
procedure names; 91 non-helper procedures were compiled individually, with 47
compiling and 44 still needing converter or dependency repairs. The 12-file
remainder ran as four independent C2FB processes with separate output
directories before their candidates were merged. Two Unix debug helpers from
these passes are now integrated: `azFileLock` supplies OS trace lock labels
(the port does not yet include its OSTRACE call sites), and
`assertLockingArrayOk` checks shared counts against exclusive owners after
SHM lock updates. Candidate compilation does not establish runtime behavior.

The default shared-library link audit found `sqlite3ParserSemanticReduce` was
implemented but its source module was missing from the build list; adding the
module resolves that reference. `sqlite3SubqueryColumnTypes` now propagates
affinity, type names, and collation to transient tables for resolved compound
SELECTs. `sqlite3CodeSubselect` emits scalar and EXISTS subquery subroutines.
`sqlite3CodeRhsOfIN` fills an ephemeral index with the RHS list or SELECT and
preserves expression affinity and collation. It now reuses completed
uncorrelated SELECT RHS subroutines when the select ID and affinity match;
correlated SELECTs and variable expression lists are still regenerated, and
eligible one-time SELECT RHS subroutines also use Bloom filters when all
comparison collations are BINARY and the optimization is enabled. The active
SELECT compiler now accepts `SRT_Mem`, `SRT_Exists`, and `SRT_Set` destinations
for tableless, table-backed, and aggregate results. Scalar, EXISTS, and IN-SELECT subqueries
therefore reach the expression subroutines. The default library builds, and its
dynamic symbol audit finds no unresolved internal SQLite names. Runtime
behavior is covered by the IN-subquery checkpoint at the end of this log.

The CREATE TABLE reducer now handles table setup, type names, table options,
defaults, NOT NULL, primary keys, unique/check constraints, collations, and
column and table foreign keys. `sqlite3AddColumn` stores standard types in the
packed column flags and custom types beside the column name. The foreign-key
builder links definitions into the child table and parent-name hash. Constraint
runtime behavior, generated columns, virtual-table actions, and most DML parser
actions remain unverified or unmapped; this parser slice has only been
build-checked.

A selected debug/trace batch used `SQLITE_ENABLE_TREETRACE` and the loose
candidate target. It preprocessed 12 files and emitted 74 procedures; 25 of 74
compiled individually. After fixing C2FB's runtime-alias call mapping, a fresh
TreeView-only pass compiled all six emitted procedures, including five
previously missing bodies: `sqlite3TreeViewExpr`,
`sqlite3TreeViewSrcList`, and the DELETE, INSERT, and UPDATE renderers. The
manual `sqlite3TreeViewBareExprList` port completes the remaining renderer.
Candidate-only assert suppression made those bodies parseable; the integrated
expression and source-list procedures restore their C invariants through the
central debug assertion handler. The TreeView ledger is now 35 of 35 functions
and 1,189 of 1,189 indexed C lines. The earlier cursor-hint batch also added
`codeCursorHintIsOrFunction`; a manual B-tree hint getter and two TreeView list
renderers followed. The pager/VDBE debug work adds the savepoint count check,
two truncate-constraint helpers, the pager-state validator, and the RIGHT JOIN
subroutine jump validator (217 indexed C lines). The pager-state validator is
also called while opening a savepoint; the jump validator runs for generated
RIGHT JOIN subroutines. At that point the index was 2,938 functions. The full default
and debug/TREETRACE library builds pass; runtime behavior remains unverified.

The debug bitmap dumper now recursively prints small bitmaps, hash entries, and
child bitmaps through SQLite's centralized debug printer. `bitvec.c` has bodies
for all 10 indexed functions and 281 indexed C lines. At that point the index
was 2,940 functions; debug output remains unverified at runtime.

The function-registration batch now includes `functionDestroy`,
`sqlite3CreateFunc`, `createFunctionApi`, and
`sqlite3_create_window_function` (201 C lines). C2FB maps the fixed
`FuncDestructor` record. The full threaded library builds and exports the
window-function API; `window5.test` and a C API destructor probe now verify
registration, replacement, and connection-close cleanup. C2FB's declaration
token limit is now 256, up from 96; the 100-token nested callback signature in
`createFunctionApi` now converts. With existing-body filtering disabled, the
`main.c` pass emitted 101 candidates; the helper and window wrapper pass an
isolated compiler screen. The preceding whole-tree pass preprocessed all 80
engine files without failures; its only new candidate was the fault-injection
initializer, which was ported because `main.c` calls it during connection open.

C2FB now retains parenthesized, multi-digit array bounds from preprocessed C
records, sizes the port-owned `sqlite3` record for its allocation, and maps
`aHardLimit` to the table shared with `sqlite3_limit`. The generated
`sqlite3_limit` candidate compiles. C2FB now translates `openDatabase` through
its built-in extension loop. The 331-line body is integrated with port-specific
setup for inline database slots, the main B-tree handle, and cached length
limit. The built-in callback table retains the fault-simulation hook used by
the C test API. The full default library build passes; runtime behavior remains
unverified.

The variadic conversion pass now recognizes C implementation signatures ending
in `...`, maps `va_list` to FreeBASIC `Cva_List`, and lowers preprocessed
`va_start`, `va_end`, and typed `va_arg` builtins. The pass exposed the
`sqlite3_db_config()` option table and connection-field mapping as remaining
barriers for that routine, so its 89-line body is ported in
`sqlite3_db_config.bas`. It covers the complete default-profile option table,
including lookaside and floating-point digit settings. The full threaded
library build passes and exports `sqlite3_db_config`. A C ABI smoke now
compares the default release library with the upstream C build across all 21
flag options, lookaside, FP_DIGITS, MAINDBNAME, DQS behavior, and foreign-key
enforcement. Flag outputs use C's integer 0/1 values.

The `sqlite3_test_control()` dispatcher is now ported in
`sqlite3_test_control.bas` using FreeBASIC's C varargs support. It connects the
PRNG save/restore/seed controls, fault and benign-allocation hooks, Bitvec test
program, per-connection flags, local-time fault override, schema checks,
`OP_Once` reset threshold, sorter mapping limit, imposter-table setup, result
int-real control, trace flags, LogEst conversion, and AtoF conversion. The
supporting state lives in `sqlite3_config.bas`; `sqlite3OsRandomness()` and
`osLocaltime()` now honor its test overrides. `sqlite3BitvecBuiltinTest()` and
the debug-aware `sqlite3BtreeSeekCount()` are represented. The full threaded
library build passes. Runtime behavior remains unverified; parser-coverage,
VDBE-coverage, and debug-only tuning profiles remain unverified.

The `sqlite3Initialize()` process-initialization body is a private helper called
by the public `sqlite3_initialize()` wrapper. The wrapper now uses SQLite's
initialized-state fast path and memory barrier, so allocator calls made under
the static main mutex do not recursively enter the non-recursive initialization
lock. The automatic-extension C ABI smoke exercises this path while growing the
registry. `sqlite3ErrName()` maps primary and extended result codes to their
symbolic names and returns unknown codes through a reusable static buffer. The
`src/main.c` ledger has bodies for all 126 indexed functions and all 4,297
indexed function lines.

The C2FB record catalog now maps the memory VFS `MemStore` and `MemFile` records
to shared internal layouts. That mapping enabled the loose C2FB pass to emit
`sqlite3_serialize()` and `sqlite3_deserialize()` together. Their bodies are
integrated in `sqlite3_bulk_memdb_serialization.bas`; the VFS-specific
`memdbFromDbSchema()` helper stays beside the store state. The full threaded
library build passes; runtime behavior is unverified.

The variadic C body for `sqlite3VdbeExplain()` now translates through C2FB's
`Cva_List` support. The regenerated internal declaration maps C `va_list` to
`ByRef Cva_List`, matching the FreeBASIC formatter implementation. The
27-line candidate passed per-procedure compilation and the full library build;
its direct runtime comparison is recorded in the later EXPLAIN checkpoint.

The optional `SQLITE_ENABLE_SNAPSHOT` path now includes the public get/open/
recover APIs, the pager bridge, WAL snapshot validation and read-lock selection,
and checkpoint recovery (14 functions, 242 C lines). The full threaded library
build passes with snapshots enabled; the API-armor snapshot module also compiles.
The default threaded library rebuild passes afterward. Runtime behavior remains
unverified.

The latest C2FB pass preprocessed all 80 engine source files without failures.
The converter now preserves pointee `const` through pointer-to-pointer
indexing, resolves aliased FreeBASIC records, lowers mapped member offsets, and
indexes C function signatures after removing compiler attributes. An earlier
integration series added 42 functions and 9,492 upstream C lines. These include
`sqlite3InitOne`, `sqlite3AddCollateType`,
`constructAutomaticIndex`, WHERE path solving and ordering, VDBE numeric and
memory helpers, INSERT constraint generation, `sqlite3Update`, and the 677-line
`sqlite3WhereBegin` with the 1,365-line `sqlite3WhereCodeOneLoopStart`. The
expression batch adds `sqlite3ExprCodeTarget` and `sqlite3FindInIndex`; the
SELECT batch adds compound-query merge, output generation, subquery flattening,
and EXISTS-to-join procedures. The full threaded library builds; runtime
behavior remains unverified.

The latest loose C2FB refresh preprocessed all 80 engine C files without
failures and emitted 15 procedures from `btree.c`, `vtab.c`, and `vdbe.c`.
All 15 passed the per-procedure compiler screen. Six new in-scope bodies were
integrated: B-tree freelist, overflow, and page-tree integrity checks
(`checkList`, `checkTreePage`, `sqlite3BtreeIntegrityCheck`; 494 C lines),
virtual-table parser setup and token extension (`sqlite3VtabBeginParse`,
`sqlite3VtabArgExtend`; 53 lines), and the VDBE index-key comparator
(`vdbeIndexKeyCompare`; 25 lines). The B-tree module keeps its private helper
closure beside the integrity traversal. Integrity state and progress/diagnostic
helpers live in `sqlite3_integrity_types.bi` and
`sqlite3_btree_integrity_helpers.bas`. A populated, indexed database passes
`PRAGMA integrity_check` in release and debug builds; broader corruption
diagnostics remain unverified.

The follow-up expression batch adds `exprIdxCover` and
`sqlite3ExprCoveredByIndex` (25 indexed C lines). C2FB now maps the fixed
`IdxCover` record stored through the Walker union. Exact C record-owner lookup
now preserves field types when a C tag such as `Walker` maps to a differently
named FreeBASIC type. The two bodies were integrated from upstream and compile
with the full library.

A follow-up corrected unary dereference of `const T **`: the pointed-to pointer
slot remains writable while a single pointer to const data remains read-only.
A targeted main.c conversion then emitted `sqlite3_table_column_metadata` (111
C lines), including its optional pointer outputs. The next full-tree refresh
again processed all 80 engine C files without preprocessing failures and found
no further in-scope candidates; the only new body was the test-only
`sqlite3TestExtInit`, which remains out of scope. The threaded library build
passes with the metadata API included.

The shared-cache default now has a stored FreeBASIC flag, a C2FB-visible
getter, and the `sqlite3_enable_shared_cache` setter in `sqlite3_config.bas`.
At this earlier checkpoint, `openDatabase` was still unmapped. It was later
ported in `sqlite3_bulk_open_database.bas`; shared-cache connection behavior
remains unverified at runtime.

The `RETURNING` context now maps to `SqliteReturning`, including its embedded
Trigger and TriggerStep layouts. The C2FB cleanup callback and the parse-time
trigger setup are integrated (50 C lines); the setup call formats its transient
name with the port's existing `sqlite3_snprintf`. The full library build passes.

A fixed `VdbeFrame` layout now lets C2FB translate frame cleanup and restoration
plus cursor closure (56 C lines). The five-candidate helper group compiled
individually, and the full library build passes.

The optional `SQLITE_ENABLE_NORMALIZE` profile now has the two double-quoted
identifier list routines and VDBE deletion cleanup (24 C lines). Their module
and the full threaded library build with `SQLITE_ENABLE_NORMALIZE=1` pass; the
default threaded library build passes as well.

C2FB now emits initialized scalar C statics as procedure-local FreeBASIC
`Static` storage. This added `sqlite3BtreeFakeValidCursor` (5 C lines), whose
persistent byte backs the B-tree cursor-state sentinel; its candidate compiled
individually. The latest full-tree scan had no additional in-scope candidates.

The initial 80-file candidate screen emitted 74 bodies in ten source files,
with 55 passing its per-procedure compile screen. A later loose whole-tree
refresh took about 8½ minutes, preprocessed all 80 engine files without failures,
and emitted 36 bodies in six source files; 25 compiled individually. The
remaining batch exposed local dependencies that blocked several entry points.
The repair pass added seven indexed functions covering 652 C lines:
`multiSelect`, `multiSelectValues`, `accessPayload`, `allocateSpace`,
`insertCell`, `insertCellFast`, and `vdbeSorterCompareReal`.

The next loose refresh again preprocessed all 80 engine files without failures
and emitted five candidate bodies in three source files; four compiled
individually. The port added `sqlite3WhereEnd`, its RIGHT JOIN unmatched-row
pass, and the VDBE statement-savepoint helper and wrapper, covering 567 C lines.
The complete threaded library builds; runtime behavior remains unverified.

A targeted B-tree conversion maps `BtreePayload` to `SqliteBtreePayload` and
retains the exported `sqlite3PendingByte` integer. It emitted six unmapped
routines for payload construction, auto-vacuum, and root-page creation/removal,
along with 18 helper bodies. All 24 procedures compile individually. The
existing incremental-vacuum and commit paths now call the translated C helpers
for page-count calculation and page relocation. This batch covers 609 indexed
C lines, and the full threaded library builds; runtime behavior remains
unverified.

A second targeted B-tree pass lowers GCC's 16-bit byte-swap read through fixed-
width FreeBASIC helpers. It added cell-size validation, index-cell comparison,
backward cursor traversal, and database-page clearing, covering another 173 C
lines. All 20 candidate procedures compile individually; the full threaded
library builds, and runtime behavior remains unverified.

A pointer qualifier correction and typed pointer difference lowering
unlocked `rebuildPage`, `pageFreeArray`, and `editPage`, adding 233 C lines.
Their nine-procedure helper closure compiles individually, and the threaded
library builds. C2FB now treats a trailing top-level pointer `const` separately
from pointee `const`, and computes compatible pointer differences in element
units.

A VDBE auxiliary pass maps the serial-type length table and the fixed
`UnpackedRecord` layout, which enables automatic locals for mapped records. It
adds `sqlite3VdbeAllocUnpackedRecord`, the integer and string comparison
specializations, `sqlite3VdbeFindCompare`, and `sqlite3VdbeIdxRowid` (256 C
lines). All five candidates compile individually, and the full threaded
library builds; runtime behavior remains unverified.

The pager write cluster now covers `pager_write`, `pager_open_journal`,
`openSubJournal`, `pager_write_pagelist`, `writeJournalHdr`, `syncJournal`,
`pager_incr_changecounter`, `writeSuperJournal`, and `pagerOpenSavepoint`
(668 indexed C lines).
Journal sync invalidates a stale following header before committing the page
count and honors SAFE_APPEND and SEQUENTIAL capabilities.
Dirty-page output applies the VFS size hint, refreshes page hashes, and updates
database-version and backup state. Super-journal records use SQLite’s signed-byte
checksum and truncate any persistent-journal tail after the record. Savepoint
creation initializes bitvecs and captures WAL state. The full threaded library
build passes; runtime behavior remains unverified.

The B-tree allocator now follows the upstream freelist search modes. The
generic wrapper selects any available page, while auto-vacuum and root-page
paths request exact or less-than-or-equal pages where the C source requires it.
It also skips pending-byte and pointer-map pages when extending the database.
The full threaded library build passes; runtime behavior is unverified.

The earlier WHERE batches added `sqlite3WhereBegin` and
`sqlite3WhereCodeOneLoopStart` with their IN-loop and indexed-expression
helpers.

The ALTER conversion work maps SQLite's five-field `RenameCtx`, preserves
`const void *` types, and recognizes the record's fixed layout. That enabled a
33-procedure conversion batch from `src/alter.c`; nine previously missing
engine functions are now integrated, covering 577 upstream C lines. The built-in
registration path now calls `sqlite3AlterFunctions()` unless ALTER TABLE is
omitted. The full library builds; runtime behavior remains unverified.

A focused follow-up on `src/pragma.c` mapped its generated `pragCName` column
table to stable storage, enabling C2FB to translate `pragmaVtabConnect`. The
pragma virtual-table callback table and `sqlite3PragmaVtabRegister()` are now
integrated; all 30 indexed functions in `pragma.c` have FreeBASIC bodies,
covering 2,816 C lines. The full library builds; runtime behavior remains
unverified.

The date module now includes `currentTimeFunc` for builds that omit full date
handling and the `datedebugFunc` JSON callback in debug builds. The date module
compiles in the default, omit-datetime, and debug profiles; the full default
library build passes. Runtime behavior remains unverified.

The no-op mutex source now exposes a static nine-callback method table and the
`SQLITE_MUTEX_NOOP` default selector. The mutex module compiles in threaded,
single-thread no-op, and debug no-op profiles. Full library builds pass with
both `THREADSAFE=1` and `THREADSAFE=0`. Runtime behavior remains unverified.

The Unix pthread backend now exposes its typed callback adapters and a static
method table through `sqlite3DefaultMutex()`. All 11 indexed functions in
`src/mutex_unix.c` have FreeBASIC bodies (240 C lines). Both full library
threading profiles build. The upstream `test/threadtest4.c` shared-cache stress
workload passes with 2 and 4 workers in multithread, serialized, and WAL modes,
and with 8 workers in multithread and WAL modes on the C reference, native
FreeBASIC, and GCC-backend FreeBASIC libraries. `mutex1.test` and `mutex2.test`
pass against those same three libraries.

The ATTACH port now includes `attachFunc`, `sqlite3Attach`, and `sqlite3Detach`,
alongside the existing VDBE code generator and cleanup helpers. C2FB maps the
fixed `Db` slot size; the port uses its preallocated database-slot array instead
of reallocating C's `aDb` pointer. All 15 indexed functions in `src/attach.c`
have bodies (523 C lines). The full threaded library builds; the upstream
`test/threadtest4.c` workload exercises attached databases in multithread,
serialized, and WAL modes on C, native FreeBASIC, and GCC-backend FreeBASIC.

C2FB now recognizes the fixed `Trigger` and `TriggerStep` records, which enabled
`sqlite3BeginTrigger`; the debug-only `onErrorText` helper is also ported.
`src/trigger.c` now has bodies for all 33 indexed functions (1,295 C lines).
The trigger module compiles with `SQLITE_DEBUG`, and the full libraries build in
both threading profiles. Runtime behavior remains unverified.

The earlier repaired batch added 18 indexed functions and 3,148 C function
lines, including `sqlite3Pragma` at 2,372 C lines and its generated 66-name,
57-column metadata. The other additions cover B-tree page insertion, JSONB
extraction and updates, `sqlite3Reprepare`, expression generation, VDBE type
naming, value text conversion, and window value checks. The load-extension
table has 279 C-ordered pointer slots; 255 currently point to FreeBASIC bodies,
with unavailable APIs left null.

The PRAGMA-name and result-column tables are generated by the FreeBASIC
`sqlite_codegen` tool from the preprocessed `pragma.c` source. The loose
whole-tree target refreshes them together with the candidate bodies.

A focused C2FB pass on `src/where.c` emitted 11 procedures with their local
helper closure. The new `sqlite3_bulk_where_loop_generation.bas` adds
`termCanDriveIndex`, `whereLoopAddBtree`, `whereLoopAddOr`, `whereLoopAddAll`,
and `whereReverseScanOrder`, covering 568 indexed C lines. C2FB now resolves
FreeBASIC type aliases before field matching, casts opaque pointer fields using
their actual storage types, and accepts the fixed planner records used by this
build profile. The candidate module compiles and the full library build passes;
runtime behavior remains unverified.

A focused `src/whereexpr.c` pass then emitted 16 procedures with helper closure.
The new `sqlite3_bulk_whereexpr_analysis.bas` adds seven missing functions,
including `exprAnalyze`, its OR-term helper, and the auxiliary virtual-table
operator check. This covers 945 indexed C lines and completes body coverage for
all 31 indexed `whereexpr.c` functions. C2FB now handles the existing uppercase
map, stable BINARY collation-name pointer, arrays of fixed planner records, and
local C callback variables. The generated candidate module compiles and the
full library builds; runtime behavior remains unverified. The loose repair queue
is empty. The earlier typed SELECT batch compiled 10 of 13 procedures
individually and enabled six SELECT expansion bodies.

The SELECT path now constructs join terms for NATURAL, USING, and ON clauses,
resolves FROM terms against nested WITH contexts, expands SELECT sources, and
rewrites compound SELECTs with ORDER BY expressions. These bodies compile as
part of the library; runtime behavior is unverified.

WHERE bytecode generation now has IN-loop setup, equality-term register
handling, index affinity selection, and Bloom-filter pull-down. The full
library build passes; runtime behavior remains unverified.

The Unix VFS now supplies C-named unlock and close adapters over its Linux
lock and close paths. Apple NFS split-range unlock is unsupported. The full
library build passes; runtime behavior remains unverified.

SELECT flattening now substitutes output columns through expressions, nested
SELECTs, and window definitions while preserving join flags, outer-join nullability,
and collation.

The load-extension API resolves platform-library callbacks, initializes the
extension function table, and records loaded handles on each connection. The
automatic-extension registry now supports register, cancel, reset, and callback
invocation outside its static mutex. Missing API bodies leave null table entries.
The full library build passes; runtime behavior is unverified.

The public UTF-8 and UTF-16 prepare APIs now use the shared lock-and-prepare
path. It checks schema locks, validates schema cookies after parse errors,
retries schema and transient parser errors, and releases parser-owned state
before returning. The library build passes; prepare behavior is unverified at
runtime.

C2FB now adds declarations for referenced public FreeBASIC procedures when their
bodies are in sibling `.bas` files without a shared `.bi` declaration. This made
isolated candidate checks reflect the full build's cross-module interfaces. It
unlocked `sqlite3BtreeCheckpoint` and `doWalCallbacks`; the port now also includes
`sqlite3Checkpoint`, `sqlite3_wal_checkpoint_v2`, `sqlite3_wal_checkpoint`,
`readDbPage`, `pagerUndoCallback`, `pagerRollbackWal`, `appendOnePathElement`,
and `appendAllPathElements`. The three pager rollback
functions cover 107 indexed C lines. The Unix VFS now normalizes path components
and follows symbolic links, selects database-matching journal/WAL permissions,
reserves low file descriptors, syncs the directory after creating a journal or
WAL file, and chooses temporary directories from the public override, environment,
and standard Unix locations. The public `sqlite3_temp_directory` and
`sqlite3_data_directory` C symbols are exported. The full thread-safe library
build passes. The Unix VFS also provides dlopen/dlsym/dlerror/dlclose callbacks
when loadable extensions are enabled. `sqlite3_bulk_loadext.bas` implements the
high-level loader, authorization check, suffix and entry-point fallback,
extension API initialization, and per-connection handle cleanup. A C ABI smoke
using SQLite's `test/testloadext.c` verified the disabled-by-default behavior,
implicit `.so` suffix and entry-point resolution, extension API calls, SQL
function registration, and handle cleanup on close. A second C ABI smoke
verified automatic extension registration and invocation, duplicate
suppression, registry reset, and cancellation. Broader extension error paths
remain unverified.
The aggregate analyzer reuses existing aggregate allocation helpers and tracks index-backed
expressions, ORDER BY/DISTINCT metadata, and column/function references. The full library
build passes; runtime behavior remains unverified.

A VDBE cleanup batch adds PMA reader and merge teardown, sorter task joins, sorter reset/close, and B-tree, sorter, and virtual-table cursor release. These procedures cover 191 indexed C lines across sqlite3_bulk_vdbesort_repair.bas and sqlite3_bulk43_vdbe_cursor_cleanup.bas. The full library build passes; runtime behavior is unverified.

The sorter PMA batch now provides 66 of 66 indexed bodies from `src/vdbesort.c`
(1,929 indexed C lines), including PMA readers and writers, in-memory sorting,
incremental merge scheduling, sorter cursor operations, and initialization.
The fixed sorter layouts and flexible `VdbeSorter.aTask` tail are shared through
`sqlite3_vdbesort_types.bi`; `sqlite3VdbeSorterInit()` also uses the configured
PMA threshold and small-allocation setting. Four worker-debug helpers compile
with `SQLITE_DEBUG_SORTER_THREADS=1`. A C API probe forced file-backed PMAs with
`SQLITE_CONFIG_PMASZ=1` and `temp_store=FILE`: release and debug-symbol builds
sorted 50,000 out-of-order rows.
EXPLAIN showed all five sorter opcodes, both probes reported a sort, and
finalize/close left lookaside usage at zero. `strace` observed two temporary
files opened and removed during the 50,000-row run.

The WAL utility batch adds page-size decoding, WAL-size configuration and truncation, heap-memory mode reporting, and header restart state. The single-frame read helper now reads WAL payload bytes and zero-fills a caller buffer tail when it exceeds the page size. Hash-page mapping and collision-chain search now locate the newest committed frame for a database page. Frame salt/checksum validation, hash append/cleanup, and read-frame lookup now cover recovery prerequisites. WAL-index recovery now has a body that rebuilds the frame hashes under recovery locks and publishes the recovered header; it compiles, but runtime behavior is unverified. The read-transaction path now reads or rebuilds the WAL-index header, handles unreliable read-only shared memory, selects a stable reader mark, and releases transaction locks. The full library build passes; runtime behavior is unverified. Frame writes cover writer locks, WAL frame encoding, WAL-file sync boundaries, checksum repair after overwrites, wal-index publication, rollback callbacks, and savepoints. The full library build passes; runtime behavior is unverified. The checkpoint iterator and passive/full/restart/truncate paths also build; runtime checkpoint behavior is unverified. SETLK-timeout and SEH accessors are present behind their feature guards. The SQLITE_DEBUG plus SQLITE_USE_SEH profile also checks the tracked WAL lock mask against reader, writer, and checkpoint state; that profile builds, but runtime assertions remain unverified.

The B-tree overflow cleanup path now maps `getOverflowPage()` and
`clearCellOverflow()`. Auto-vacuum databases use the pointer map to locate a
next overflow page when possible, with a page-read fallback. Cleanup keeps the
existing chain-length and page-reference checks. The full library build passes;
overflow runtime behavior is unverified.

The B-tree balance cluster now maps `balance_deeper()`, `balance_quick()`,
`balance_nonroot()`, and `balance()`. Root expansion repairs pointer maps after
copying node contents, and the quick right-edge path uses caller-owned divider
scratch. The balance planner repairs child and overflow pointer maps for auto-vacuum.
The planner counts a table-leaf overflow cell when it moves that cell to a new
sibling, and quick balance uses the validated saved size for queued scratch
cells. Newly allocated internal siblings now use a valid empty old-cell range,
and page rebuilds use cached cell sizes so earlier writes cannot change the
sizes of later source cells. The 50,000-row release and debug-symbol probes
exercise deeper internal-page balancing, PMA merge, sorted output, and clean
finalize/close.

The cursor movement path now maps `btreeMoveto()`,
`btreeRestoreCursorPosition()`, `btreeNext()`, and `moveToLeftmost()`. Packed
index keys use the record-unpack path, while table seeks use the rowid path.
The next-key helper runs after the exported wrapper restores cursor state. The
full library build passes; cursor runtime behavior is unverified.

The pager savepoint path now maps `subjournalPage()` and
`subjournalPageIfRequired()` and uses the `subjRequiresPage()` predicate. It
updates later savepoint truncation flags and advances the subjournal record
count even when rollback journaling is off, following SQLite’s C behavior.
The full library build passes; pager runtime behavior is unverified.

The pager now reads committed page counts from the WAL before falling back to
database file size, and hot-journal detection checks the journal header before
rollback playback. The WAL handle and index records are defined in
`sqlite3_wal_types.bi`, with optional fields guarded alongside `src/wal.c`.
Both the WAL implementation and conversion candidates use these declarations.
Default and ZIPVFS library builds pass; profile layout parity and runtime
behavior remain unverified.

The WAL layer now opens handles, allocates and maps wal-index pages, reads and
publishes the duplicated wal-index headers with checksums and shared-memory
barriers, and switches Pager into WAL mode when requested. WAL-index recovery,
frame lookup, frame reads, and the read-transaction path now compile with the
library. Frame writes, rollback, and savepoint handling now compile; WAL
checkpoint code now builds; checkpoint and end-to-end WAL behavior are unverified.

An earlier C2FB fix preserved pointer depth when an indexed C pointer-to-pointer
field uses opaque `Any Ptr` storage. The refreshed whole-tree scan emitted 89
procedures in 14 modules. Thirty-nine candidate compiles passed: 38 were bodies
already present and one was a test-only hook. Forty-nine unported engine bodies
still fail on dependencies or unsupported statements; one already-ported pager
helper also failed inside a dependency closure. This pass found no additional
ready engine body beyond the PCache1 batch.

The preprocessed C2FB pass scans the default source profile for all 80 engine C
files. Adding layouts for `sqlite3_index_info` and its hidden planner tail
unlocked five WHERE procedures and the JSON callback `jsonEachBestIndex`.
Bounded integer constant array expressions, the exact `CellArray` layout, and
typed B-tree page callbacks then unlocked `populateCellCache` and
`computeCellSize`. `sqlite3_vtab_collation()` is also implemented directly over
the new public and hidden index-info layouts.

A full sweep at that stage emitted 395 procedures in 46 source modules. After
correcting the const-qualified `sqlite3MemCompare` and `sqlite3BlobCompare`
declarations and adding the missing internal callback declarations, all 395
procedures compile individually. Thirty-three newly mapped procedures,
covering 1,014 upstream function lines, are integrated in bulk modules 20
through 35. This includes the virtual-table allocator `allocateIndexInfo`.
The per-procedure check does not assess runtime behavior. Other accepted output
was already mapped or outside the indexed engine scope.

An earlier C2FB sweep emitted 405 procedures across 47 source modules. Mapping
`sqlite3.suppressErr`, `sqlite3.eOpenState`, and `VdbeOp.p4.pVtab` let all 405
candidates compile individually. At that stage, 403 were integrated; the
test-only `sqlite3TestExtInit` stays out of scope, and `sqlite3Close` was
deferred pending the `sqlite3LeaveMutexAndCloseZombie` cleanup path. Nine newly
indexed functions added 275 upstream function lines to the coverage ledger. A follow-up
dependency pass added another 20 indexed functions, including table and AST
cleanup, shared-cache locks, window cleanup, authorization, column defaults,
and WAL callbacks. The full library build passes and the unresolved SQLite
symbol count fell from 39 to 30. A later layout extension mapped FKey,
Trigger, TriggerStep, IdList, Subquery, and Upsert records. It enabled 23
compile-clean FK/Trigger procedures and four UPSERT procedures; the FK delete
path, IdList lookup, and UPSERT allocation/cleanup entry points are also
ported. Adding `Parse.eOrconf` then let the full-tree sweep compile all 614
candidate bodies across 66 modules. The port now integrates 424 preprocessed
body definitions across 47 modules, excluding the test-only hook. This added
16 newly indexed functions and 557 upstream function lines, including
`codeTriggerProgram` and `sqlite3Close`. At that stage, `sqlite3Close` still
depended on the unported `sqlite3LeaveMutexAndCloseZombie` cleanup path. A follow-up ported
`sqlite3CollapseDatabaseArray` against the fixed-size database-slot layout.
The rename-token map and UPSERT allocator also have bodies now. A fresh
preprocessed sweep over all 80 engine C files emitted 423 procedure definitions
across 47 source modules; every emitted module compiled. It added
`renameTokenFree` and `renameParseCleanup` to the ALTER batch. The candidate
directory retained 20 older candidate files, so the combined checker reported
634 bodies across 67 files; 423 is the fresh sweep count. A subsequent isolated
pass checked 418 bodies across 47 nonempty modules; all 47 compiled. Candidate
body counts do not by themselves represent new source coverage. A manual port of
`sqlite3VtabCreateModule` reduced unresolved SQLite symbols to 25. A source-list
batch then added `sqlite3SrcListEnlarge`, `sqlite3SrcListAppend`, and
`sqlite3SrcListAppendList`. A copy layer added `sqlite3IdListDup` and
`sqlite3SrcListDup`, and `sqlite3SelectDup` now delegates FROM-list copying to
the mapped source-list routine. A follow-on parser pass added FROM-term assembly, ON/USING cleanup, subquery
attachment and detachment, table-valued function arguments, and INDEXED BY
metadata. Rename expression-list cleanup now maps list names back to source
tokens. `sqlite3OpenTempDatabase` opens the TEMP B-tree with the pending page
size. AUTOINCREMENT now reserves its rowid registers, initializes the sequence cursor, tracks maximum rowids, and emits sequence writeback. Index affinity caching, the optional NULL-trim MakeRecord flag, and updated-column checks for constraint expressions are also ported. The full library build passes with 22 unresolved SQLite symbols. The library is not ready for
the upstream SQLite suites. These checks establish compiler acceptance, not
runtime behavior parity.

A fresh C2FB sweep scanned all 80 engine C files and emitted 424 procedure
definitions across 47 modules. The 419 candidate function bodies compile as
grouped modules after adding a shared declaration for
`sqlite3VdbeSetP4KeyInfo`. Comparing their names with earlier modules showed
that 417 were already-ported private procedures emitted again as local
helpers. `sqlite3TestExtInit` remains out of scope. Only `fkLookupParent` added
a new in-scope function, covering 141 upstream lines; `sqlite3_bulk40_fkey.bas`
keeps that body without the redundant candidates. The library build passes and
the unresolved SQLite dynamic symbol count remains 22.

The next preprocessed sweep emitted 420 bodies across 47 modules, and every
module compiled. Inventory comparison showed that 419 were private helper
copies for functions already mapped elsewhere; the remaining body was the
out-of-scope `sqlite3TestExtInit`. Those copies remain in the candidate tree
instead of being added to the library. C2FB also confirmed that
`sqlite3RunVacuum()` depends on a variadic `execSqlF()` it cannot translate.
The 285-line runner is now ported manually in `sqlite3_bulk_vacuum.bas`,
including `VACUUM INTO` file checks, schema and row copying, metadata
preservation, B-tree replacement, and cleanup. The full library build passes;
the dynamic undefined SQLite symbol count is still 22. No SQLite runtime suite
has been run against the port.

Mapping `DbFixer` to its embedded `Walker` record and verifying the fixed
`Select` layout let C2FB translate five schema-fixer procedures from
`src/attach.c`. `fixSelectCb()` writes C bitfields, so its six `SrcItem.fg`
flags are set through explicit masks in `sqlite3_walker.bi`; `sqlite3FixInit()`
and the callback are implemented in `sqlite3_bulk_attachfix.bas`. The seven
procedures cover 135 upstream lines. At that stage the full library build
passed with 22 undefined SQLite symbols; it reports a generated-C const-qualification warning
on the `sqlite3FixInit()` schema-fixer type pointer. Runtime behavior remains
unverified.

Mapping `AuthContext` to the parser's saved authorization state let C2FB
translate `sqlite3AuthContextPush()` and `sqlite3AuthContextPop()` from
`src/auth.c`. Their two bodies cover 16 upstream lines and compile in
`sqlite3_bulk_authctx.bas`. The full library build passes with 22 unresolved
SQLite symbols.

Adding `Parse.sLastToken` to the port and updating it before each parser token
submission made all 47 groups in the refreshed C2FB sweep compile. It exposed
`sqlite3CreateView()` and `sqlite3FinishTrigger()`, translated across 194
upstream lines, plus `sqlite3ShadowTableName()`. Mapping the complete `Table`
record and the packed `sqlite3InitInfo` flags let C2FB translate
`sqlite3StartTable()`; direct writes to the separately stored unsigned
`checkSchema` bitfield are now width-masked. `sqlite3CheckObjectName()` is also
ported manually. At that stage the library build passed with 23 unresolved
SQLite symbols. `sqlite3EndTable()`, `sqlite3NestedParse()`, and
`sqlite3CreateIndex()` now have bodies. The manual index builder is integrated
with table creation, including the WITHOUT ROWID path; index runtime behavior
remains unverified.

Mapping C `Window` to the complete `SqliteWalkerWindow` layout and adding the
private aggregate state records let C2FB translate 31 more indexed functions
from `src/window.c`, covering 529 upstream lines. The new module contains the
rank, percent-rank, cumulative distribution, ntile, nth-value, first-value,
and last-value callbacks, plus window allocation, linking, comparison, and copy
helpers. Its local `sqlite3WindowOffsetExpr()` copy calls the now-ported
`sqlite3RenameExprUnmap()` path. CTE cleanup now reaches the ported
`sqlite3SelectPrep()` and translated recursive CTE generator. The full library
build passes. A 20-row `WITH RECURSIVE ... UNION ALL` C API probe returns the
expected sequence in release and debug builds; other recursive CTE cases remain
unverified.

Mapping the generated `PragmaName` record and pragma virtual-table cursor
layouts let C2FB translate 10 more callbacks from `src/pragma.c`, covering 149
upstream lines. `sqlite3_bulk_pragma_vtab.bas` implements cursor open, close,
filter, iteration, column, rowid, and best-index callbacks. The full library
build passes with the same 27 unresolved SQLite symbols.

Mapping `JsonParent`, `JsonEachCursor`, and `JsonEachConnection` to the JSON
parser, path-string, and virtual-table layouts enabled 10 more C2FB bodies
from `src/json.c`, covering 127 upstream lines. The new module ports cursor
creation, cleanup, reset, end-of-scan, path-length, malformed-input, and rowid
helpers. At this checkpoint, JSON row-value production, module registration,
and scan callbacks were still outstanding. They were later added in
`sqlite3_bulk_json_vtab.bas`; runtime verification was added later and is
recorded in the JSON test checkpoint below.
The full library build passes with 27 unresolved SQLite symbols.

After the window and JSON layout mappings, a fresh C2FB sweep emitted 482
candidate bodies across 48 source files; all 48 groups compiled. Five new
indexed functions covering 79 lines are integrated in
`sqlite3_bulk_expr_windows.bas`, `sqlite3_bulk_select_windows.bas`, and
`sqlite3_bulk_resolve_windows.bas`. They discover window functions during
expression walks, attach function `ORDER BY` terms, and apply window-specific
checks during SELECT push-down and resolution. The full library build still
has 27 unresolved SQLite symbols.

Mapping `NameContext` to its parser, source-list, SELECT, and upsert records
enabled a loose C2FB batch for the resolver core. `sqlite3_bulk_resolve_core.bas`
now contains `resolveExprStep`, `resolveSelectStep`, `lookupName`,
`sqlite3ResolveExprNames()`, `sqlite3ResolveExprListNames()`, and
`sqlite3ResolveSelectNames()`, plus their local callbacks. The ALTER rename
walkers and `sqlite3RenameExprUnmap()` are also ported. Nested CTE name
resolution reaches `sqlite3SelectPrep()`, and compound SELECTs now dispatch to
the translated multi-select path, including recursive CTE generation. Runtime
behavior remains unverified.

The fixed `AggInfo`, column-entry, and function-entry records enabled 12
aggregate-analysis helpers from `src/expr.c` and `src/select.c`, covering 465
upstream lines. `sqlite3_bulk_aggregate_expr.bas` creates aggregate
column/function entries and persists their references; the SELECT module
assigns accumulator registers, updates aggregate inputs, and applies indexed
expression optimizations. `sqlite3ArrayAllocate()` is also ported.

Mapping `RefSrcList` and `CheckOnCtx` enabled 20 more walker helpers, covering
889 upstream lines. These scan expression references and validate join clauses.
A follow-up sweep found four additional functions covering 87 lines for
deterministic expressions, column defaults, RETURNING subqueries, and table
transfer checks. The last full-tree loose C2FB sweep emitted 658 candidate
bodies across 53 nonempty source groups. Twenty-five groups compiled together;
per-procedure checks compiled 534 of the 658 bodies. Ninety-five still-unported
indexed procedures depended on unresolved helpers at that snapshot. A targeted
repair since that sweep added `whereLoopInsert()` and `whereLoopXfer()`, then
integrated `whereLoopAddBtreeIndex()` and `whereShortCut()`. Those four bodies
add 650 upstream function lines. The full library build passes with 27
unresolved SQLite symbols, including `sqlite3SelectPrep()` and the remaining
DDL, foreign-key, VDBE, and virtual-table entry points.

The converter's loose-candidate mode keeps callers whose private helpers have
not translated, so larger source batches can be staged and repaired together.
The default candidate mode still filters those callers before compilation.
C2FB now removes FreeBASIC macro-name collisions that differ only by C
identifier case, and emits named procedure-pointer aliases for generated
callback signatures. Internal declarations expose already-ported helpers to
candidate modules, including B-tree page helpers, virtual-table index-info
allocation, VDBE P4 cleanup, and the pager WAL capability check.
`sqlite3VdbeClearObject()` is integrated with its local memory and opcode
cleanup helpers. Targeted B-tree batches added page initialization and cursor
walking, page-format decoding, node-content copying, and loop insertion. The
shared B-tree interface now exposes existing page, cell-parser, and pointer-map
helpers that those modules reuse. The planner now ports WHERE scanning,
temporary term allocation, term insertion, expression-use masks, and limit
term generation. Two candidate routines, `whereLoopAddBtreeIndex()` and
`whereShortCut()`, also compile with the shared loop insertion path.

The query-planner pass now includes `sqlite3_where_scan.bas` for scanner state,
term matching, and index affinity checks; `sqlite3_where_clause.bas` for
WhereTerm growth and WhereInfo-owned allocation; and
`sqlite3_bulk_where_expr_terms.bas` for expression-use masks, clause splitting,
and limit terms. `sqlite3_bulk_where_scan_queries.bas` adds indexed-term lookup
and DISTINCT redundancy checks.

The next WHERE pass added `whereLoopAddVirtualOne()` (180 indexed C lines)
and `whereLoopAddVirtual()` (123 indexed C lines). `decodeIntArray()` from
`src/analyze.c` is also translated as a source-local helper. A full C2FB sweep
emitted 536 candidate bodies across 48 source groups, and all 48 groups
compiled after exposing the shared `sqlite3WhereFindTerm()` declaration.
Most emitted bodies were duplicate local implementations needed to compile
candidate groups in isolation; those duplicate modules were consolidated or
discarded. The test-only `sqlite3TestExtInit()` candidate was excluded. The
loose sweep emitted 656 bodies across 53 source groups; 25 groups compiled,
while 28 groups still fail on untranslated helpers. Eighty still-missing
indexed candidates in that report cover 3,899 C lines. The trigger group now
has a FreeBASIC `triggerStepAllocate()` and the `sqlite3TriggerInsertStep()`,
`sqlite3TriggerUpdateStep()`, `sqlite3TriggerDeleteStep()`, and
`sqlite3TriggerSelectStep()` bodies in `sqlite3_bulk36_trigger.bas`.
The virtual-table group now has `vtabCallConstructor()` and its three
connect, create, and eponymous-table callers in `sqlite3_bulk36_vtab.bas`.
The expression modules now include the reduced Expr copy-size helpers,
`sqlite3ExprIsIIF()`, `sqlite3ExprCodeExprList()`, and the expression implication
walkers, including the RIGHT JOIN-aware non-NULL-row check. The expression-list
code generator lives beside its private constant-analysis helper in
`sqlite3_expr.bas`.
`sqlite3_bulk_vdbeblob.bas` now owns the incremental-BLOB handle layout,
open/read/write/reopen/close routines, size query, and shared row-seek path.
The complete FreeBASIC library builds with 13 unresolved SQLite symbols. No
SQLite runtime test suite has been run against this port.

The default STAT1 `ANALYZE` path now creates or clears `sqlite_stat1`, scans
table indexes, emits the per-prefix distinct-count bytecode, writes the new
statistics, and schedules `OP_LoadAnalysis`. The `stat_init`, `stat_push`, and
`stat_get` callbacks use a variable-sized accumulator allocated through
SQLite's database allocator. STAT4 sampling is not included. The full library
build passes; runtime behavior is unverified.

`sqlite3LimitWhere()` now builds the primary-key subquery used to implement
ORDER BY and LIMIT for DELETE and UPDATE. The public code preserves source-list
ownership, indexed-by cleanup, and CTE-use accounting while constructing the
row-key IN expression.

After C2FB began filtering already-ported private bodies while retaining
transitive helpers needed by new candidates, the cached sweep fell from 654 to
155 candidate bodies. The assignment-lowering fix then reduced it to 151; 68
compile individually. `sqlite3FkDropTable()` is integrated in
`sqlite3_bulk36_fkey.bas`; its call to `sqlite3DeleteFrom()` is still
unresolved.

C2FB assignment lowering now freezes a converted right-hand value before
writing it to its target, so a call on the right-hand side is evaluated once.
The converted foreign-key candidate set had eight of nine procedures compile
with their helper closure. `isSetNullAction()`, `sqlite3FkCheck()`,
`fkActionTrigger()`, and `sqlite3FkActions()` are now integrated in
`sqlite3_bulk36_fkey.bas` and `sqlite3_bulk41_fkey_check.bas`. The unresolved
set includes `sqlite3DeleteFrom()`, `sqlite3Insert()`, `sqlite3Update()`,
`sqlite3SelectPrep()`, `sqlite3WhereBegin()`, and `sqlite3WhereEnd()`.
`sqlite3CodeRowTriggerDirect()` compiles cached trigger subprograms and emits
`OP_Program` calls. `sqlite3CodeRowTrigger()` selects matching triggers,
`codeReturningTrigger()` generates inline RETURNING rows, and
`sqlite3TriggerColmask()` uses cached old/new column masks.

The VDBE auxiliary port now resolves symbolic jump labels and transfers
completed opcode arrays through `sqlite3VdbeTakeOpArray()`. The trigger module
uses that path to cache trigger programs while preserving parser error state
and trigger column masks. `sqlite3GenerateColumnNames()` supplies the result
names needed by the RETURNING path.

The date subsystem now has FreeBASIC bodies for all 36 indexed functions
(1,380 of 1,380 function lines). It parses timestamps and modifiers, converts
Julian-day/calendar/time state, handles local time, and registers
`julianday()`, `unixepoch()`, `date()`, `time()`, `datetime()`, `strftime()`,
`timediff()`, the three `current_*` callbacks, the `datedebug()` diagnostic,
and the `SQLITE_OMIT_DATETIME_FUNCS` current-time fallback.

The current source files port the version and source-identity entry points
from `src/main.c`, the statement-completeness functions from `src/complete.c`,
tokenization plus keyword inspection from `src/tokenize.c`, and UTF-8/UTF-16
conversion and length helpers from `src/utf.c`. Lemon's parser tables, action lookups,
allocation, stack growth, push-token transition loop, and tokenizer-to-parser
runner are ported. A small subset of grammar actions now builds literal
expressions and expression lists, then compiles tableless SELECTs, compound
`UNION`, `UNION ALL`, `INTERSECT`, and `EXCEPT` chains, plus single- or
multi-row VALUES clauses. Supported values
include integers, reals, digit-separated numeric literals, strings, blobs,
NULL, TRUE/FALSE, bound parameters, unary and binary operators, and simple
or searched CASE expressions. Constant-list `IN`/`NOT IN` tests and the
`coalesce()`, `ifnull()`, and `nullif()` calls use specialized lowering;
`typeof()` uses the registered scalar callback path.
Lemon reduce lookup accepts nonterminal symbols, pure-reduce goto states stay
encoded as reduce states, and the parser runner preserves caller-owned Parse
state during nested SQL parsing. An early C API smoke found that nested
`OP_ParseSchema` SQL failed while parsing `AND`, and that a later close could
return `SQLITE_MISUSE`. Subsequent parser and cleanup repairs fixed those
cases: a current C ABI probe creates a table, reads its row through
`SELECT * FROM sqlite_master`, and closes with `SQLITE_OK`. VDBE make-ready
also clears the cursor-pointer array before execution; without that
initialization, `sqlite3StartTable` could reuse stale opcode bytes as a
cursor address and crash in `sqlite3BtreeCloseCursor`.
Transaction grammar actions generate `OP_Transaction`, `OP_AutoCommit`, and
`OP_Savepoint` instructions. BEGIN, COMMIT, ROLLBACK, and savepoint commands
now call `sqlite3AuthCheck()` with SQLite's transaction action and operation
name before emitting those instructions. The VDBE tracks selected databases
in its B-tree masks, starts transactions and opens B-tree cursors by database
index, and finalizes active B-trees through SQLite's two-phase commit path.
Release/debug C ABI probes and the unchanged `attach.test` through
`attach4.test` suites exercise attached-database behavior; the suite results
are recorded near the end of this log.
Logical `AND` folds a known false input when the expression is outside a join
constraint, and defers releasing its unused inputs until preparation finishes.
Planner helpers also inspect boolean tokens, signed integer expressions, and
bound integer parameters while recording when a later bind requires reprepare.
Walker-based constant analysis now handles outer-join terms, fixed columns,
per-cursor table constants, constant scalar-function flags, and legacy schema
defaults that contain bound parameters.
Expression comparison now checks mapped operators, token text, child nodes,
and expression-list ordering. It returns indeterminate for variable-to-literal
matching and window-function comparisons that need unported state.
Vector expressions expose their width and SELECT/list field expressions.
Deep copies preserve token, child-expression, ExprList, compound SELECT,
CTE-owned state, and mapped FROM-list entries. SrcList copies duplicate owned
names, ON/USING and table-function expressions, retain shared table references,
and increment CTE-use counts. `sqlite3SelectDup` now uses this path for its
FROM lists. Reduced/token-only nodes and window definitions remain unsupported
by the shared-buffer duplication path. Ordinary expression copies preserve
reduced and token-only prefixes and duplicate attached window-function state
through `sqlite3WindowDup()`.
SELECT-column wrappers preserve their borrowed SELECT owner. Tableless SELECT
expressions containing row-value vectors now route through SQLite's shared
expression bytecode emitter, including contiguous vector evaluation and row
comparison handling. Runtime behavior is unverified.
`sqlite3_cte.bas` appends CTE entries with duplicate-name checks, duplicates
CTE names, column lists, and supported SELECT trees, and releases CTE-owned
allocations. Parser reductions construct CTE lists, push cleanup ownership, and
attach WITH clauses to parsed SELECTs. `sqlite3_bulk39_select.bas` resolves CTE
names and expands FROM-term references. The active SELECT path materializes CTE
FROM terms, ordinary derived tables, and views through shared fill subroutines.
Multiple references to the same CTE reuse one cursor; correlated subqueries
are recomputed for each outer row. Tableless literal and VALUES bodies and
table-backed queries use the existing SELECT paths. Compound SELECTs dispatch
through the translated multi-select implementation, including recursive CTE
queues. Table-backed simple and grouped aggregate CTE bodies also write to
ephemeral destinations. Window SELECTs use the translated rewrite, initialization,
and frame-code paths through the table-backed scan compiler. Source-less
ungrouped and grouped aggregate CTE bodies now use the aggregate analyzer and
accumulator paths; flattening and coroutine optimizations for FROM subqueries
are not integrated. The full library build passes; runtime behavior is
unverified.
GROUP BY constant analysis accepts matching terms only when BINARY collation
is known; unresolved column collations remain conservative false negatives.
The single-table constraint helper also checks outer-join provenance and
subquery constancy against the selected FROM item.
Affinity analysis identifies literal and rowid expressions that do not need
an additional OP_Affinity conversion.
Expression height is now calculated across children, lists, and compound
SELECT terms before the configured depth limit is checked.
The bytewise BINARY comparator and its CollSeq predicate are in
`sqlite3_vdbe_compare.bas`; registration and lookup for custom collations are
still outstanding.
Simple SELECT statements also support constant WHERE expressions,
`IS`/`IS NOT` null-safe comparisons, `IS NULL` predicates, and LIMIT/OFFSET
counters. CAST to BLOB, TEXT, NUMERIC, INTEGER, and REAL affinities and
BETWEEN/NOT BETWEEN expressions are also available for tableless queries.
The VDBE is created on demand through `sqlite3GetVdbe()`, and the expression
walker can visit expression children, expression lists, compound SELECT terms,
FROM subqueries, and table-valued-function arguments. Window expression terms
are included when requested by the walker callbacks. The CTE stack callback
unwinds the active WITH clause after compound SELECT walks. SELECT preparation
resolves and expands CTE references; CTE FROM terms, ordinary derived tables,
and views use materialization, and recursive CTEs use the translated compound
dispatcher.
Runtime behavior remains unverified.
UTF-8 `sqlite3_prepare()`/`_v2()`/`_v3()` and UTF-16 `sqlite3_prepare16()`/
`_v2()`/`_v3()` return a ready VDBE and the tail after the first statement;
UTF-16 tail offsets are mapped back to the original input.
`sqlite3_errmsg16()` returns connection error text in native UTF-16.
Basic table-backed SELECTs now run `sqlite3SelectPrep()` for source expansion
and name resolution, then `sqlite3WhereBegin()`/`sqlite3WhereEnd()` for source
scans and WHERE filtering. Result expressions use SQLite's expression code
generator, and LIMIT/OFFSET counters are emitted in the scan loop. ORDER BY
uses index order when the planner proves it and a bounded ephemeral index for
LIMIT/OFFSET queries that need a temporary sort; unbounded sorts use the
translated sorter. DISTINCT uses an ephemeral duplicate set. Simple table-backed aggregate
queries without GROUP BY and grouped queries use SQLite's aggregate analysis,
accumulator, sorter, and finalization helpers; HAVING filters the completed
aggregate row. Recursive CTE code generation is connected through the compound
dispatcher, table-backed aggregate CTE bodies can materialize into ephemeral
tables, and window SELECTs use the translated rewrite and frame-code path;
runtime behavior is unverified. Source-less ungrouped and grouped aggregate
SELECTs and CTE bodies use the shared aggregate analyzer and accumulator
paths. A no-FROM WHERE clause filters the implicit single input row; grouped
code emits no group when that row is rejected. Ungrouped aggregate SELECTs accept top-level
DISTINCT and ORDER BY; grouped aggregate output also sorts and removes duplicate
result rows. Grouped and ungrouped aggregate paths apply LIMIT and OFFSET,
including after grouped output sorting or duplicate removal. Aggregate DISTINCT,
ORDER BY, and FILTER use the accumulator helper paths. Runtime behavior is
unverified.

All custom grammar actions have handlers. Parser finalization now mirrors all
50 active Lemon `%destructor` symbols from `src/parse.y`, including expression
and list values, SELECT and source lists, CTEs, windows, trigger steps, ID lists,
and window-frame bounds. Stack values are cleared before destruction so a
second finalization cannot release them again. Parser cleanup behavior remains
unverified at runtime.
`sqlite3_exec()` now loops over prepared statements and delivers result rows
to the supplied C callback for this supported subset. It applies
`sqlite3ApiExit()` before returning so the connection error mask controls
whether callers receive primary or extended result codes. `sqlite3_get_table()`
collects those callback rows into SQLite-owned strings, with
`sqlite3_free_table()` releasing the flattened result.
The registered progress callback is checked during implemented SELECT code
generation and while the VDBE counts virtual-machine steps.
Parser diagnostics retain a formatted message and token byte offset through
prepare cleanup, then transfer the message to the connection's error value.
Prepared-statement metadata includes binding, column access, status counters,
expiration state, and original SQL text. `sqlite3_expanded_sql()` substitutes
bound values as SQL literals using SQLite's tokenizer and value formatter.
The library also contains the default
system-backed allocation routines from `src/mem1.c`
and `src/malloc.c`. `SQLITE_CONFIG_MALLOC` can replace the callback table,
`SQLITE_CONFIG_GETMALLOC` returns it, and the `SQLITE_ZERO_MALLOC` build profile
selects the upstream all-failing allocator callbacks. The public connection
layer now opens and closes one main
database through `sqlite3_open()`/`sqlite3_open_v2()` and exposes error,
system-error, offset, mutex, database-name lookup, pager filename, read-only, autocommit-state,
transaction-state, and temporary-store-mode APIs, along with `sqlite3_set_errmsg()`,
extended-result-code configuration, named `sqlite3_get_clientdata()` and
`sqlite3_set_clientdata()` entries with destructor ownership, write-transaction
cache flushing, and main-pager memory release. `sqlite3_setlk_timeout()` keeps
the default build's range check and success result; the optional set-lock
feature remains unsupported. `sqlite3_busy_handler()` and
`sqlite3_busy_timeout()` configure the callback used by B-tree pager locks.
`sqlite3_interrupt()` signals active VDBE execution through a separate
per-connection lock; the executor checks the flag between instructions.
Invalid connection handles are
reported through the configured log callback. `sqlite3_limit()` initializes and
updates all 15 per-connection limit classes. SQL length, value length, column count,
expression depth, compound SELECT terms, parser-stack growth, VDBE opcode
allocation, variable numbers, function arguments, and LIKE/GLOB pattern length
use the connection's configured limits. `SQLITE_LIMIT_ATTACHED` is checked by
ATTACH, and `SQLITE_LIMIT_TRIGGER_DEPTH` is enforced during trigger generation
and nested VDBE program entry. `SQLITE_LIMIT_SCHEMA` is checked as schema rows
are loaded. Sorter initialization caps worker tasks using
`SQLITE_LIMIT_WORKER_THREADS` and `SQLITE_MAX_WORKER_THREADS`. These paths build;
runtime behavior is unverified.
`sqlite3_compileoption_get()` and `sqlite3_compileoption_used()` report the
sorted FreeBASIC build-profile options. `ENABLE_URI_00_ERROR` appears only in
builds compiled with `SQLITE_ENABLE_URI_00_ERROR`; the strict URI profile passes
uri2.test 22/22 and uri.test 99/99.
Main, temp, and attached schema slots receive initialized schema hash
containers. `sqlite3InitOne()` reads each database's `sqlite_schema` rows and
passes them through the init callback that builds table, index, and trigger
objects. Schema loading and reload behavior remain unverified at runtime.
`sqlite3ReadOnlyShadowTables()` checks defensive mode against VDBE execution
and virtual-table synchronization state.
The TEMP trigger-presence helper is in `sqlite3_trigger_helpers.bas`.
`sqlite3_filename.bas` allocates and frees the pager's packed VFS filename
layout and exposes its database, journal, WAL, and URI parameter segments. When
`SQLITE_ENABLE_8_3_NAMES` is enabled, it also applies SQLite's optional short
suffix rewrite to journal, WAL, and shared-memory filenames.
`sqlite3GetBoolean()` handles SQLite's shared boolean spellings for URI and
PRAGMA values. `sqlite3_uri.bas` parses `file:` URIs for both
`sqlite3_open_v2()` and `ATTACH`, including path escapes, VFS, cache, and
access-mode parameters. `sqlite3_config.bas` implements the
pre-initialization `SQLITE_CONFIG_URI`, `SQLITE_CONFIG_MALLOC`, and
`SQLITE_CONFIG_GETMALLOC` options, the SINGLETHREAD, MULTITHREAD, and SERIALIZED
mutex modes, `SQLITE_CONFIG_PAGECACHE`, default lookaside settings,
`SQLITE_CONFIG_MEMSTATUS`, `SQLITE_CONFIG_PCACHE_HDRSZ`, and
`SQLITE_CONFIG_MEMDB_MAXSIZE` for the memory-database VFS when deserialize
support is enabled. The memory layer
routes allocation, reallocation, sizing, and shutdown through the configured
`sqlite3_mem_methods`, with the system allocator as its default. `SQLITE_CONFIG_LOG`
and `sqlite3_log()` use the configured callback and fixed-size stack buffers.
The formatter blocks scratch-buffer growth for no-allocation accumulators,
including the logger. `SQLITE_CONFIG_PCACHE` now returns its documented no-op
success, while `SQLITE_CONFIG_GETPCACHE` returns `SQLITE_ERROR`. The
`SQLITE_CONFIG_ROWID_IN_VIEW` case reports zero when the compatibility feature
is absent and updates stored-view visibility flags when
`SQLITE_ALLOW_ROWID_IN_VIEW` is enabled. Under
`SQLITE_ENABLE_SORTER_REFERENCES`, `SQLITE_CONFIG_SORTERREF_SIZE` now sets the
threshold used to mark untyped BLOB columns for sorter references. The default
and combined sorter-reference/rowid-in-view builds pass with zero unresolved
SQLite symbols. A temporary C ABI smoke matches the upstream C build for
GETMUTEX before initialization and after init/shutdown, allocator and PCACHE2
method-table round trips, mutex-mode options, URI open, LOG callback dispatch,
and the post-initialization configuration guard. Feature-specific rowid,
sorter-reference, and Windows heap behavior remain unverified at runtime.
`SQLITE_CONFIG_WIN32_HEAPSIZE` now writes the shared heap-size setting
consumed by the Windows allocator. The config and allocator modules compile
with `SQLITE_OS_WIN` and `SQLITE_WIN32_MALLOC` enabled. The default library
build passes; native Windows runtime behavior is unverified.
`SQLITE_OMIT_DESERIALIZE` now follows upstream source omission: the build
excludes the memory VFS, both serializer implementations, and the retained
C2FB helper candidates from `memdb.c`; those modules also carry source-level
guards. C2FB emits compile-time guards around the serializer extension-table
slots so those entries remain NULL. Release and debug omit-profile libraries
build with no exported `sqlite3_serialize`, `sqlite3_deserialize`, or
`sqlite3MemdbInit` symbols. A
loaded C extension confirmed that both slots are NULL; the default profile
retains both slots, and a C ABI smoke serialized a database, deserialized it
into a second connection, and read the stored row in release and debug builds.
`SQLITE_CONFIG_MEMDB_MAXSIZE` also returns `SQLITE_ERROR` in the omit profile,
matching `src/main.c`. The existing C2FB suite passes 10,754 behavior
comparisons in each of its native and GCC backend runs.

Build the omitted profile with:

```sh
make -C fb_src TARGET=build/libsqlite3-fb-omit-deserialize.so \
  FB_DEFINE_FLAGS='-d SQLITE_OMIT_DESERIALIZE=1'
```
FROM-subquery rowid visibility also follows `SQLITE_CONFIG_ROWID_IN_VIEW`.
The resolver applies SQLite's view/base-table rowid candidate precedence and
mode 2 resolves view rowids to `NULL`. The SELECT optimizer blocks unsafe
`rowid IS NULL` predicate pushdown, and declaration-type lookup leaves view
rowid metadata unset without indexing before the result list. Default, mode-1,
and mode-2 builds pass with zero unresolved SQLite symbols; runtime SQL
behavior remains unverified.
`sqlite3_open16()` converts native UTF-16 filenames and selects the main
schema encoding before schema loading. The UTF-16 prepare, prepare-v2, and
prepare-v3 APIs share the bounded UTF-16-to-UTF-8 parser path and map the tail
pointer back to the input encoding. Release and debug C ABI smokes opened a
UTF-16 database, checked its encoding, used all three prepare variants, and
registered a UTF-16 custom collation that ordered rows correctly after reopen.
`sqlite3_hooks.bas` stores trace, profile, commit, rollback, update, and
optional pre-update callbacks under the connection mutex. The VDBE dispatches
statement trace callbacks from OP_Init/OP_Trace and profile callbacks when a
step completes or the statement is reset or finalized. Main-B-tree commits
and VDBE rollback paths invoke commit and rollback hooks. Successful rowid-table
Insert/Delete opcodes invoke the update hook with the database and table names.
With `SQLITE_ENABLE_PREUPDATE_HOOK`, OP_Insert and OP_Delete invoke the
registered pre-update callback before changing the B-tree row. The dispatcher
distinguishes insert, update, and delete, supplies the update register for new
values, and supports WITHOUT ROWID no-op insert notifications. Default and
pre-update-enabled library builds pass with zero unresolved SQLite symbols;
the two upstream VDBE callback call sites are both represented. Runtime callback
behavior remains unverified.
`sqlite3_collation.bas` stores per-connection collation sequences, registers
BINARY, ASCII-only NOCASE, and RTRIM, and exposes the UTF-8/UTF-16 registration
and collation-needed APIs. `sqlite3ExprCollSeq()` resolves explicit COLLATE
nodes and declared column collations from the table schema, then passes those
sequences to expression comparison code. Broader planner and index-codegen
collation integration remains incomplete.
Per-connection status handles all 14 public `SQLITE_DBSTATUS_*` operations.
Lookaside usage and high-water reset now include both large and 128-byte slot
pools. The unchanged `dbstatus.test` passes 154/154 and `dbstatus2.test` passes
33/33 with no tracked leaks. Windows mutex callbacks have since been ported;
their native Windows runtime behavior remains unverified, and optional
OSTRACE messages are not ported.
Process-wide status counters, serialized automatic initialization,
and Unix pthread/no-op mutex APIs are implemented. `sqlite3ThreadCreate()` and
`sqlite3ThreadJoin()` use pthreads in thread-safe builds and run the callback
synchronously when threading is disabled or pthread creation fails. The
single-thread debug mutex profile tracks allocation type and enter/leave counts;
the release profile retains the no-op marker mutex.
Case-insensitive string comparison and 8-bit hashing, the public LIKE/GLOB
matching APIs, and the SQL `like()`/`glob()` callbacks from `src/util.c` and
`src/func.c` are also ported. Bounded string length, in-place dequoting, and
Token initialization helpers from `src/util.c`, plus the public
`sqlite3_errstr()` API and per-connection error set/clear and formatted-message
helpers from `src/util.c`, are ported as well. Build with `make -C fb_src`; the
shared library is written under `fb_src/build/`.

The pager and B-tree bitmap primitive from `src/bitvec.c` is ported, including
its compact bitmap, sparse hash, recursive subdivision, and mutation paths.
Its debugger display and built-in test-program runner are intentionally left
with the upstream test and debug support.

The generic case-insensitive hash table from `src/hash.c` and its internal
structure layouts from `src/hash.h` are ported. Hash growth remains
opportunistic: an allocation failure leaves lookups on the existing table or
linear list, matching SQLite's non-fatal rehash behavior.

The database-aware allocator paths from `src/malloc.c` now include per-connection
OOM latching, lookaside-aware non-null free entry points, pnBytesFreed accounting,
and a two-size lookaside pool with large slots and 128-byte slots. Reallocation
can copy a lookaside allocation into a larger heap block using the original slot
size.
The benign-allocation callbacks
from `src/fault.c` are in `sqlite3_fault.bas`. Unix worker creation and join
from `src/threads.c` are in `sqlite3_threads.bas`; single-thread builds and
pthread creation failures run worker callbacks synchronously. The public
`sqlite3*` handle is
opaque, so `sqlite3_db_types.bi` defines the FreeBASIC port's private connection
state. `src/rowset.c` is ported on top of that allocator, including batch tests,
tree merging, and sorted extraction.

`sqlite3_status()`, `sqlite3_status64()`, `sqlite3_memory_used()`, and
`sqlite3_memory_highwater()` are backed by synchronized counters. Heap
allocation and reallocation update memory-used, allocation-count, and largest
request values. The deprecated `sqlite3_memory_alarm()` ABI remains a no-op.
Public malloc and realloc entry points run automatic initialization unless
`SQLITE_OMIT_AUTOINIT` is selected.
Soft and hard heap-limit APIs update allocator state, the hard limit is enforced
by malloc/realloc, and `sqlite3HeapNearlyFull()` reports the soft-limit state.
`sqlite3_release_memory()` returns zero unless SQLite is built with
`SQLITE_ENABLE_MEMORY_MANAGEMENT`. That optional profile evicts clean,
unpinned pages from the shared page-cache LRU and its full library profile
builds. A negative byte request passes through as SQLite's release-all
sentinel. `SQLITE_CONFIG_PAGECACHE`
preserves the caller's buffer and slot settings, then applies them during
initialization through `sqlite3PCacheBufferSetup()`. Heap fallback allocations
flow through the page-cache overflow and size counters; caller-owned fixed
slots are not returned by `sqlite3_release_memory()`. Runtime allocator and
page-pool behavior is unverified.
`sqlite3_db_status()` and `sqlite3_db_status64()` report/reset lookaside
counts, page-cache memory/hits/misses/writes/spills across attached databases,
deferred foreign-key state, and temporary-buffer spill bytes. The
`SQLITE_DBSTATUS_STMT_USED` case estimates statement-owned bytes by walking VDBEs
under `pnBytesFreed` mode with lookaside temporarily disabled, without unlinking
statements or running value destructors. VDBE deletion also applies
opcode/argument-mask filtering to auxdata
and invokes its destructor callbacks. The `SQLITE_DBSTATUS_SCHEMA_USED` case
counts schema hash storage and measures table/trigger allocations through the
same non-destructive `pnBytesFreed` path while all attached B-trees are entered.
The unchanged DBSTATUS tests pass, including the shared-cache
`CACHE_USED_SHARED` cases.

The page-reference and dirty-list layer from `src/pcache.c` is implemented in
`sqlite3_pcache.bas`, with its pager-facing layouts in `sqlite3_pcache.bi`.
The current default backend uses a page-number hash table and a clean-page
LRU. It supports page fetch, release, dirty-list ordering, spill callbacks,
rekeying, truncation, cache sizing, shrink, and fixed-slot allocation through
`sqlite3PCacheBufferSetup()`. The backend can recycle clean, unpinned pages
across caches when their allocation sizes match, and allocates a per-cache bulk
page block when a cache first needs storage. `SQLITE_CONFIG_PCACHE2` selects a
caller-supplied method table. The sanity check verifies dirty-list membership,
back-links, and page-state flags. Cache operations rely on the owning pager to
serialize access. Table-backed SELECT and DML paths now reach the pager and
B-tree layers; runtime behavior remains unverified.

The public `sqlite3_file`, `sqlite3_io_methods`, and `sqlite3_vfs` layouts and
the OS dispatch wrappers from `src/os.c` are in `sqlite3_vfs.bi` and
`sqlite3_os.bas`. The VFS list supports registration, lookup, and removal under
SQLite's main mutex. `sqlite3_initialize()` calls `sqlite3OsInit()`, which
installs a Linux x86-64 VFS from
`sqlite3_os_unix.bas` with positioned reads and writes, file synchronization,
truncation, path handling, randomness, time, POSIX database byte-range locks,
and shared-memory mapping and lock methods. The Linux VFS and public extension
loader implement dynamic library open/symbol/close dispatch; runtime extension
loading remains unverified, and unsupported extension API entries stay null.
The file-fetch mmap path is exercised by `mmapcorrupt.test`; syscall overrides
and other Unix targets remain outstanding. WAL read/write and checkpoint code
passes the Linux WAL suites; cross-platform behavior remains unverified.

The SQLite-level PRNG from `src/random.c` is in `sqlite3_random.bas`. It
implements ChaCha20 block generation, buffered byte consumption, VFS seeding,
serialized access through SQLite's static PRNG mutex, and state save/restore
hooks used by `sqlite3_test_control()`.

The pager now has its state layout and a read path in `sqlite3_pager.bi` and
`sqlite3_pager.bas`. It opens a VFS-backed database, creates its page cache,
acquires a shared database lock, reads and zero-fills pages, and releases page
references. It parses and replays hot rollback journals before returning the
database image, including page checksums and super-journal presence checks.
It can create rollback journals, save original page images before mutation,
protect all pages sharing a larger disk sector, flush database pages after
syncing the journal, spill unreferenced dirty pages after an exclusive-lock
upgrade, report cache hit/miss/write/spill counts, commit or roll back a
single-file transaction, and
capture or restore statement savepoints through a sub-journal. The sub-journal
uses linked memory chunks, keeps up to the configured statement-journal limit
in memory, and can spill to a temporary VFS file. Page move/rekey support is
now present for B-tree relocation. The VDBE coordinates multi-database
super-journal creation, sync, deletion, and phase two; attached-database tests
pass, while crash recovery across every I/O boundary remains unverified. The
mmap page path passes `mmapcorrupt.test`; the unchanged `mmapfault.test` also
exercises allocator and VFS faults during mapped reads. WAL frame and checkpoint
paths pass the tested Linux WAL suites.

`sqlite3_memjournal.bas` implements the journal's `sqlite3_file` methods. Its
VFS spill path saves the memory-journal state, opens the real file, and copies
each chunk before releasing the memory copy. If opening or copying fails, the
original memory journal is restored so pager rollback can still read it.

`sqlite3_memdb.bas` implements the memory database VFS. It stores each database
as a resizable byte array with a 1 GiB default limit, implements SQLite's
shared/reserved/exclusive lock transitions, and implements xFetch/xUnfetch for
fixed-size stores. Names beginning with `/` share one store across open handles;
other names receive a private store. Dynamic loading, time, randomness, and
sleep requests pass through to the underlying VFS. `sqlite3_serialize()` and
`sqlite3_deserialize()` are implemented in
`sqlite3_bulk_memdb_serialization.bas`; they copy pager pages or attach a
caller-owned buffer to the memory store. Release and debug C ABI smokes cover
serialization, deserialization, ownership transfer, and row readback. Other
memory-VFS sharing and locking behavior remains unverified.

The first B-tree layer is in `sqlite3_btree.bi` and `sqlite3_btree.bas`. It
opens and closes a single B-tree handle through the pager, binds pager pages to
`MemPage` state, validates page headers, cell offsets, and freeblock chains,
decodes table and index cells, and calculates local versus overflow payload
sizes. It lazily allocates one shared schema blob per `BtShared` and invokes
its registered destructor when the B-tree closes. It exposes the pager handle,
clears write-transaction content tracking,
and releases temporary page space. The freelist content bitvec marks leaf pages
freed during a write transaction, so reusing them preserves original page bytes
for rollback; the map is cleared when the write transaction ends. Helper
Free-page release accepts a held page or checks the pager cache first; it reads
an uncached page only when secure-delete or trunk-page conversion needs the
contents. Helper routines construct local leaf cells and write overflow payload
chains, reusing freelist pages or extending the
database when auto-vacuum is off. A companion routine releases bounded
overflow chains back to the freelist. The module also has page-local allocation/defragmentation, cell
removal, leaf insertion, deferred overflow-cell queuing, right-edge table-leaf
split and root-expansion helpers, sibling selection/divider detachment,
CellArray assembly and size caching, ordered-cell page rebuild/insert/free/edit
helpers, sibling-page distribution planning and application for the
non-auto-vacuum path, including safe page-edit order, parent divider updates,
root collapse, and unused-page reclamation, plus same-size payload overwrite
primitives. `sqlite3BtreeInsert()` now builds and replaces table/index cells,
saves other cursors on the same root, and connects the balance steps through
parent-overflow recursion. `sqlite3BtreeDelete()` frees cell overflow chains,
replaces internal index separators, balances underfull pages, and preserves
cursor positions when requested. Checked payload reads and incremental-blob
range writes cover local and overflow-page content. B-tree entry counts,
row-count estimates, and preformatted row transfer support VDBE operations.
The cursor restore path re-seeks saved table and index positions. Cache/spill
sizing, pager flags, page-size/reserve controls,
secure-delete and auto-vacuum mode accessors, cursor-state queries, cursor
pinning/hints, transaction/backup status, and database format-version setting
are also implemented. Cursors can be tripped after rollback, and a table
can be cleared through its open cursor. Pointer-map lookup and I/O, allocation
and free-page marking, overflow-owner entries, child-map refresh after page
rebuilds, parent-pointer repair, and page-relocation primitives are integrated.
Incremental vacuum and the default full auto-vacuum commit/truncate path are
also implemented. Auto-vacuum root creation and drop relocation now preserve
root-page ordering and pointer-map entries. Custom vacuum-page callbacks and
shared-cache B-tree mutex entry/leave helpers are in `sqlite3_btmutex.bas`;
attached-B-tree lock ordering and shared-cache table locks remain. The SQL
VACUUM command now reaches `sqlite3RunVacuum()` and the B-tree replacement path.
A single handle
can start read/write
transactions, commit or roll them back, access page-one
metadata, create empty table/index root pages when auto-vacuum is off, traverse
metadata, create roots with auto-vacuum page placement, traverse table/index
cursors, search integer rowids, and search unpacked index keys through the VDBE
record comparator. It can read payloads from overflow chains, save cursor
positions, clear a table/index tree, and drop roots while keeping the
auto-vacuum root range compact.

The VDBE `Mem` cell layout and its NULL, integer, real, text/blob setters,
zero-blob, pointer, RowSet, move, copy, writable-buffer, UTF-16 BOM, B-tree
payload-read, and release paths are in `sqlite3_vdbe_mem_types.bi` and
`sqlite3_vdbe_mem.bas`. Bounded
UTF-8/UTF-16 integer parsing, decimal/hex integer token conversion, 32-bit
integer extraction, and the VDBE integer value, integerify, real clamp, integer
affinity, numeric affinity in `sqlite3_vdbe_affinity.bas`, and decimal-to-real
conversion helpers are also ported. The decimal parser and real renderer use
SQLite's power-of-ten tables and fixed-width multiplication path. UTF-8/UTF-16
translation, integer/real stringification, and value text/byte accessors are
implemented in `sqlite3_vdbe_mem_text.bas` and `sqlite3_vdbe_api.bas`. The public
value API also includes numeric accessors, pointer-type checks,
encoding/subtype/nochange/from-bind queries, duplication/freeing, and the
transient value-list allocator callback. Virtual-table context helpers report
unchanged columns and iterate packed right-hand-side values in a B-tree value
list. Statement time is cached on the VDBE for the duration of one execution.
Value-level affinity dispatch, numeric
type classification, numeric/text CAST helpers,
integer-versus-real comparison,
Mem NULL/numeric/TEXT/BLOB comparison, and record serial-type length/value
decoding, serial-type selection, and field payload encoding are implemented.
The `sqlite3_result_*` family now writes integer, real, NULL, pointer, subtype,
text, blob, zero-blob, and copied-value results into the VDBE output cell. It
also tracks result errors, destructor ownership, and output encoding through
the `sqlite3_context` prefix in `sqlite3_result.bi`; SQL-function invocation
is implemented for the statically registered `abs()`, `char()`, `instr()`,
`length()`, `octet_length()`, `lower()`, `upper()`, `hex()`, `unhex()`,
`random()`, `randomblob()`, `round()`, `sign()`, `substr()`, `unicode()`,
`zeroblob()`, `concat()`, `concat_ws()`, `replace()`, `trim()`, `ltrim()`,
`rtrim()`, `typeof()`, `quote()`, `unistr_quote()`, `unistr()`,
`sqlite_version()`, `sqlite_source_id()`, `sqlite_compileoption_used()`,
`sqlite_compileoption_get()`, `last_insert_rowid()`, `changes()`,
`total_changes()`, `subtype()`, `like()`, and `glob()` functions through
`OP_Function`. SQL `printf()` and `format()` use SQLite value arguments in the
shared formatter. The registered `nullif()` callback gets its collation from
`OP_CollSeq`; the supported tableless compiler also lowers `nullif()` directly.
LIKE pattern calls support the single-character ESCAPE argument;
infix LIKE, GLOB, and MATCH actions build function nodes with the C argument
order (pattern, value, optional ESCAPE), with `NOT` as an outer expression
node. Built-ins are indexed by SQLite's 23-slot function-name hash, and
overload selection scores argument counts and text encoding like
`matchQuality()` in `src/callback.c`.
The unchanged `func2.test` (99 tests) and `func9.test` (17 tests) pass.
An initial smoke across `date.test` through `date5.test` recorded 10 combined
invocations; it did not cover the date suites in full. `func9.test` covers Unicode
escapes, including `hex(unistr(\UFFFFFFFF))` returning `F7BFBFBF`. That test
exposed a byte lookup table declared as `ZString Ptr` and indexed as bytes;
the hex callback now uses `Const UByte Ptr`. A direct C probe verifies
`hex('abc')` returns `616263`. A separate C API probe registers and invokes a
custom scalar function successfully.
The unchanged `expr.test` (539 tests) and `expr2.test` (9 tests) also pass
with no failures or tracked allocation leaks. This run caught three port
mismatches: LIKE/GLOB returned `-1` for true, function error text was
discarded by the VDBE, and unary minus of the exact decimal 2^63 value
became REAL. The port now emits canonical 0/1 comparison results,
preserves scalar-function error text, and emits `INT64_MIN` for that
unary-minus case.
The `sqlite3_create_function()` and `sqlite3_create_function_v2()` APIs
register per-connection scalar and aggregate callbacks and invoke their destructor on
replacement, deletion, allocation failure, or connection close.
Scalar callbacks can retrieve and replace per-argument auxdata through
`sqlite3_get_auxdata()` and `sqlite3_set_auxdata()`; statement reset runs the
registered destructor callbacks.
`sqlite3_create_function16()` converts its UTF-16 function name to UTF-8 before
registration. `sqlite3_progress_handler()` calls the registered C callback at
the requested VDBE instruction interval and interrupts execution when it asks
to stop. Aggregate context and step/final dispatch support the built-in
`count()`, `sum()`, `total()`, `avg()`, `min()`, `max()`, `group_concat()`,
and `string_agg()` functions and direct aggregate calls in tableless, single-row
SELECTs. `group_concat()` uses the separator from each non-NULL step row.
Multi-argument `min()` and `max()` use the scalar comparison callbacks.
Table-backed aggregates without GROUP BY use the aggregate analyzer and
accumulator path for basic scans; grouping and aggregate modifiers remain
unsupported. Built-in window
aggregate callbacks, SELECT rewriting, and VDBE frame-code generation now have
FreeBASIC bodies. The default thread-safe library build passes, but window
runtime behavior remains unverified.
`sqlite3VdbeRecordPack` assembles a record blob from already-affinitized Mem
cells; `sqlite3VdbeRecordUnpack` decodes bounded record data into Mem fields.
SQLite varint readers/writers and fixed-width big-endian integer helpers are in
`sqlite3_varint.bas`. `sqlite3VdbeRecordCompare` compares record keys through
Mem ordering and collation callbacks. The executor applies OP_MakeRecord
affinities, packs records, reads table columns, probes index keys with Found,
NotFound, and NoConflict, inserts and deletes index entries, and extracts the
rowid from an index record. Per-register affinity and table-backed aggregate
grouping are wired into the executor and SELECT compiler. Dispatch cases now
exist for all generated opcode labels; semantic behavior remains unverified.

`sqlite3_vdbe_core.bi` now defines the common-build `Vdbe`, `VdbeOp`, and
`VdbeOpList` layouts. `sqlite3_vdbe_core.bas` creates a builder with its initial
`OP_Init`, retains statement SQL, emits integer, real, string, jump, and opcode
list instructions, grows the opcode array, tracks main-B-tree dependencies,
and links owned subprograms for deletion.
It handles transient/static/dynamic string and integer P4 values, stores result
column names, and implements operand-patching and jump-target helpers.
`sqlite3_opcodes.bi` now includes
generated jump-opcode metadata used to adjust relative P2 targets in opcode
lists. Parse-schema setup and coroutine cleanup are included for the single
main database represented in the current connection layout.
`sqlite3VdbeMakeReady()` allocates register, variable, argument, and
cursor-pointer arrays, resolves labels, and rewinds a prepared VDBE into READY
state. In `SQLITE_DEBUG` builds, the core checks opcode reservation,
no-result-row, and abort-journal invariants. Its abortability checker walks
the main opcode program and reachable P4 subprograms. `sqlite3_vdbe_exec.bas`
dispatches main-database transactions, metadata-cookie reads/writes, ANALYZE
statistics reloads, database-root destruction, schema-entry reloads, and
in-memory DROP cleanup,
OpenRead/OpenWrite/ReopenIdx/OpenEphemeral/OpenAutoindex/OpenDup/SorterOpen/OpenPseudo/Close,
Rewind/Sort/SorterSort/Last/SeekEnd/Next/SorterNext/Prev, InitCoroutine/Yield/
EndCoroutine, CollSeq initialization, SeekHit bounds, IfEmpty/IfNotOpen,
Pagecount/MaxPgcnt, IncrVacuum, strict-table TypeCheck, ResetCount, SoftNull,
subtype get/set/clear, ElseEq, sorter insert, compare, row-key, and
reset operations, vector
OP_Compare/OP_Jump with register permutations and KeyInfo collation ordering, table
SeekLT/LE/GE/GT and SeekRowid/NotExists, Rowid/IdxRowid,
DeferredSeek/FinishSeek, NullRow and cursor tests, Column, Count/Clear, RowData,
CreateBtree, NewRowid, Sequence/MemMax, table and index Insert/Delete,
Found/NotFound/NoConflict, index SeekLT/LE/GE/GT and IdxLE/GT/LT/GE, MakeRecord,
Gosub/Return, BeginSubrtn, AggInverse/AggValue callbacks, jumps,
integer/real/string and bound values,
register copies/moves, affinity, arithmetic, bitwise and shift operations,
comparisons, boolean logic, IS TRUE/FALSE, Cast/RealAffinity, Concat, OffsetLimit,
ZeroOrNull, OP_Function/OP_PureFunc calls, integer checks, NULL ranges,
RowSetAdd/Read/Test, FilterAdd/Filter bloom-filter checks, Destroy, ParseSchema,
DropTable/DropIndex/DropTrigger, foreign-key counter/jump/check opcodes, result rows,
HaltIfNull constraint checks, and halt. Autocommit toggles,
named-savepoint bookkeeping, and statement savepoints for writes inside explicit
transactions are represented. Coroutine transfers keep the resume address in
the designated VDBE register; `EndCoroutine` returns to the caller's P2 target.
`sqlite3_step()` drives the loop.
Reset can halt a partially stepped VDBE before it is reused or finalized.
`sqlite3_vdbe_trace.bas` expands bound SQL and dispatches statement and profile
callbacks through the registered connection hooks.
The VDBE core tracks change-count and expiration flags; successful execution
records the statement and cumulative change totals through
`sqlite3VdbeSetChanges()`. It resets the step result, formats VDBE-owned errors,
and checks immediate/deferred foreign-key counters at halt. INSERT, UPDATE, and
DELETE generation call the foreign-key check/action helpers; INSERT and UPDATE
also generate NOT NULL, CHECK, and uniqueness constraint bytecode. Constraint
runtime behavior remains unverified. The core exposes the database handle,
prepare flags, and subprogram state.
`sqlite3_vdbe_cursor.bi` defines the VdbeCursor prefix and
`sqlite3_vdbe_cursor.bas` allocates its variable-sized record metadata and
embedded B-tree cursor storage. Sorter initialization, writes, merging, row-key
lookup, and iteration are connected to sorter opcodes; ephemeral cursors use
transient B-trees; OpenDup creates independent cursors over shared ephemeral
tables. Bloom filter operations reuse the C2FB-translated hash routine.
The Bloom-filter path was exercised with a 20-row IN-subquery: FilterAdd and
Filter were emitted, ten matches produced ten filter hits and ten misses, and
finalizing the statement left no lookaside slots in use. A NOCASE comparison
correctly skipped the filter. Release and debug probes passed. The foreign-key
cascade probe also exercised RowSetAdd/RowSetRead and removed the expected child
rows. `sqlite3SelectCompileFromClause()` now applies
`fromClauseTermCanBeCoroutine()` and sends eligible FROM-subqueries through the
SRT_Coroutine path; the WHERE loop yields each row and rewrites column reads to
the coroutine's result registers. A sorted-LIMIT C API probe returned the five
expected values with two InitCoroutine ops, two Yield ops, and one EndCoroutine
op. Default and NOT MATERIALIZED single-use CTEs also used coroutines; an
AS MATERIALIZED CTE and a multiply referenced default CTE stayed on the shared
ephemeral-table path and returned the expected rows. Disabling SQLITE_Coroutines
through SQLITE_TESTCTRL_OPTIMIZATIONS retained the same result and selected
materialization. These CTE cases passed in release and debug builds.
A LEFT JOIN with an ordered-LIMIT derived table stayed materialized and retained
the unmatched row with NULL columns in both builds.
PMA sorter runtime is now verified by the probes described above.
DDL runtime behavior remains unverified. Destroy uses the existing B-tree drop
routine, updates schema root pages after autovacuum movement, and resets the
affected schema if a later error rolls the operation back. ParseSchema uses the
ported initializer callback for filtered schema reloads and `sqlite3InitOne`
for full schema reinitialization. `OP_ColumnsUsed` records its 64-bit mask when
enabled, and debug `OP_Abortable` checks use the VDBE journal invariant.
Virtual-table cursors and attached-database coordination are represented, and
the executor has dispatch cases for all 192 generated opcodes. Complete
halt/error parity and parts of SQL compilation remain incomplete.
`sqlite3_prepare.bas` implements the UTF-8 prepare APIs for the current parser
subset. It copies the input buffer for bounded parsing, stops after the first
compiled statement, maps the parser tail back to the caller's buffer, and keeps
SQL text for v2/v3 statements. The parser context is freed after compilation
and detached from the ready VDBE.
`sqlite3_vdbe_stmt.bas` exposes the connection handle, retained SQL, EXPLAIN,
read-only, busy-state, statement-list, reset/finalize, and bind-parameter metadata APIs. It also
logs NULL/finalized-statement misuse, supports parameter-name lookup, integer/real/NULL/text/blob/pointer/zeroblob
bindings, copy-from-value binding, clearing all bindings, and transferring
bindings between statements on the same connection. Statement counters
can be read or reset; MEMUSED uses the VDBE's count-only delete path so shared
execution-arena slices are measured through their backing allocations. The
unchanged `stmtvtab1.test` passes 8/8 and `mallocK.test` passes 3,910/3,910.
Reset/finalize clean VDBE resources and close zombie connections after their
last statement. Broader frame and subprogram memory-accounting coverage remains
outstanding. The module also exposes result
column count, data count, type/value/text/blob accessors, names, declared types,
and optional database/table/origin metadata from the current result-row state.

`sqlite3_util_numeric.bas` adds the standalone integer helpers from `src/util.c`:
checked signed arithmetic, unsigned decimal parsing, logarithmic row estimates,
NaN/overflow classification, hex digit and blob decoding, byte swapping, and
packed VList name mappings.
`sqlite3_where_helpers.bas` contains `src/where.c`'s standalone `estLog` cost
conversion and `allConstraintsUsed()` virtual-table constraint helper, kept
separate from the still-unported query planner.
`sqlite3_date_helpers.bas` adds `validJulianDay()` with the 64-bit upper bound
used by SQLite's internal date representation.
`sqlite3_pragma.bas` also includes the one-column text result helper used by
PRAGMA implementations.
`sqlite3_snapshot.bas` implements snapshot get/open/recover/compare/free when
`SQLITE_ENABLE_SNAPSHOT` is enabled. The unchanged snapshot test family passes
205/205 on C, native, and GCC snapshot profiles, with matching case labels and
no tracked allocations; see the runtime checkpoint below.
`sqlite3_backup_types.bi` preserves the private backup-context field layout;
`sqlite3_backup.bas` returns the remaining and source page counts, finalizes
backup handles, restarts page progress after external changes, and copies
modified pages through the pager callback. `sqlite3_backup_init()` allocates
state and resolves named B-trees. `sqlite3_backup_step()` copies pages, handles
destination page-size rules, updates schema metadata, and commits the
destination. The VACUUM-specific `sqlite3BtreeCopyFile()` wrapper is now
available for its B-tree replacement stage. `sqlite3RunVacuum()` now performs
the temporary-schema rebuild, preserves selected database metadata, replaces
the B-tree for ordinary VACUUM, and writes a separate target for VACUUM INTO.
`sqlite3ParseObjectInit()` establishes the per-connection parse context used
when opening a named TEMP source or destination database.
`sqlite3_bulk_attachfix.bas` maps schema references in views, triggers, and
indexes to the database that owns them, rejects cross-database stored queries,
and walks trigger steps, CTEs, and expressions while preserving the parser's
error state.
`sqlite3_bulk_authctx.bas` pushes and restores `Parse.zAuthContext` around
authorization checks using the matching stack-owned context layout.
`sqlite3_bulk_create_view.bas` builds view metadata and copies the defining
SELECT into the schema. `sqlite3_bulk_finish_trigger.bas` validates and stores
trigger schema references and SQL text. `sqlite3_bulk_shadow_table.bas`
resolves a shadow table's virtual-table owner before delegating suffix checks
to its module. `sqlite3_bulk_start_table.bas` validates the schema and reserves
the table's schema row and B-tree root page. Final schema generation now has a
body in `sqlite3_bulk_create_table_repair.bas`; `sqlite3CreateIndex()` remains
an unresolved dependency. `sqlite3_bulk_objectname.bas` checks
reserved names and verifies schema-initialization object names.
`sqlite3_bulk39_main.bas` now closes zombie connections after all statements
and backup objects finish, releasing attached B-trees, schemas, collations,
virtual-table modules, extensions, and connection state. Function-registry
cleanup walks the per-connection `aFunc` hash and calls
`sqlite3DbFunctionDestroy`; each user `FuncDef` and its trailing name use one
C-compatible allocation. Both the hand-written registry and generated
`FuncDef.u` entries release the reference-counted destructor record.
`window5.test` verifies the window callback teardown path.
Mapping the private `sqlite3_backup` record in C2FB unlocked three more
compiler-clean bodies: `attachBackupObject`, `sqlite3_backup_finish`, and
`sqlite3BackupRestart`. The page-copy helper, pager update callback,
`sqlite3_backup_init()`, and the 269-line `sqlite3_backup_step()` routine were
ported alongside those candidates. The 49-line `sqlite3BtreeCopyFile()` helper
is now implemented; `sqlite3RunVacuum()` handles the B-tree rewrite and
temporary-database cleanup.
`sqlite3_pager.bas` also exposes SQLite's sector-size clamp, page-number,
cache-reference, backup-pointer, journal-mode safety, and exclusive-lock
helpers.

`sqlite3_straccum.bas` implements the bounded `sqlite3_str` buffer lifecycle:
append, growth, finish, reset, truncate, and inspection. It also routes a
too-large error into an active parser context through `sqlite3ErrorToParser`.
`sqlite3_printf.bas` adds integer, floating-point, string, SQL quote, and JSON
format conversions, along with `sqlite3_str_vappendf`, `sqlite3_str_appendf`,
`sqlite3_mprintf`, `sqlite3_vmprintf`, and bounded snprintf APIs. The internal
`SQLITE_PRINTF_SQLFUNC` argument mode backs the registered SQL `printf()` and
`format()` functions, and `sqlite3RecordErrorOffsetOfExpr()` records expression
token offsets. Internal `%S` and expression form `%#T` formatting remain
outstanding. The log renderer uses stack buffers, and the debug formatter uses
the C runtime output stream. Token byte offsets and the public
`sqlite3_error_offset()` accessor are connected to the syntax parser.
Reference-counted string allocation, resize, and release operations are in the
same module.

`sqlite3_json_string.bas` ports the JSON accumulator lifecycle, byte appends,
quoted-string escaping, and control-byte escapes, using the existing
reference-counted string allocator. It retains the 100-byte inline buffer
before growing to dynamic storage and reports allocation and nesting errors
through the SQL function context. `sqlite3_json_hex.bas` ports hexadecimal
conversion and escape-shape checks.

`sqlite3_json_parse_state.bas` defines the JSONB parse object lifecycle and
four-entry per-statement translation cache stored through VDBE auxdata. JSON
text parsing and JSONB validation use that state.
`sqlite3_json_parse_arg.bas` selects validated JSONB input or parses text,
promotes retained text to reference-counted storage, and manages editable cache
copies.
`sqlite3_json_valid.bas` implements and registers the one- and two-argument
`json_valid()` overloads, including JSON5 and superficial/strict JSONB flags.
`sqlite3_json_query.bas` implements JSON path lookup and the `json_type()` and
`json_array_length()` callbacks. JSONB path edits back `json_insert()`,
`json_replace()`, `json_set()`, and `json_remove()`; merge-patch and array
insertion use the same edit path. The unchanged suites json102.test through
json109.test, json501.test, json502.test, and jsonb01.test now pass 45,711
enabled assertions with no tracked leaks. This includes 45,001 randomized
JSON and JSON5 invariant assertions in json106.test, plus JSONB path edits,
array insertion, pretty output, and json_each/json_tree queries. The temporary
runner loads the upstream randomjson and strdup test extensions dynamically;
test sources remain unchanged.
`sqlite3_json_values.bas` converts SQL scalar values into JSON output and
implements the one-argument `json()`/`jsonb()` callbacks plus `json_quote()`,
`json_array()`, and `jsonb_array()`.
`sqlite3_json_return.bas` transfers generated output as text or JSONB and keeps
reference-counted storage and cache ownership consistent. `jsonReturnParse()`
selects JSONB blob output or canonical JSON text from a parsed value.
`sqlite3_json_blob_text.bas` renders JSONB scalars, strings, arrays, and objects
back into JSON text.
`sqlite3_json_blob.bas` provides bounded JSONB buffer growth, node append, and
payload-size patching for the parser and later edit operations.
`sqlite3_json_payload.bas` decodes compact and extended node headers and checks
payload spans against both the stored blob length and pending edit size.
`sqlite3_json_validate.bas` recursively validates JSONB scalar payloads, string
escapes, arrays, and object key/value pairs; `jsonArgIsJsonb()` uses it to
distinguish valid JSONB blobs from text-compatible blobs.
`sqlite3_json_text_parse.bas` recursively translates JSON/JSON5 strings,
numbers, arrays, objects, and keywords into JSONB nodes. The text-to-JSONB
parser and completion wrapper are ported and called by the argument dispatcher.
`sqlite3_json_text_scan.bas` recognizes JSON5 whitespace/comments and decodes
one bounded escape sequence, including Unicode surrogate pairs and continued
lines. `sqlite3_json_labels.bas` compares raw UTF-8 labels with escaped JSON
labels. Object constructors, JSON aggregates, pretty rendering, and the
`json_each`/`json_tree` table-valued functions have registered callbacks.
The unchanged `json101.test` (282/282), `json102.test` (317/317),
`json106.test` (45,001/45,001), and `json108.test` (18/18) pass against both
FreeBASIC and C `testfixture`, with no tracked FreeBASIC leaks. These suites
exercise `json_each`/`json_tree` row production, JSONB input, nested paths, and
joins. Their cases overlap the JSON runtime checkpoint below and are not added
to the cumulative count again.

`PORTING_INVENTORY.csv` tracks every `src/` input listed in SQLite's core
`SRC` list, plus generated parser/opcode/PRAGMA inputs and the later test-runner
bridge. It records port status and upstream line count by source file.
`PORTING_FUNCTIONS.csv`, generated by `fb_tools/c2fb/c2fb.bas functions src`,
indexes 3,263 C function-definition rows across 80 in-scope source files with
line spans and rough size classes. Alternate definitions behind preprocessor
conditions share one row. Its initial status column is `Needs mapping` so newly
indexed functions can be reconciled as the port proceeds. Run
`make -C fb_src reconcile-function-status` to mark rows with a matching
FreeBASIC body; this reports body presence, not semantic completeness.
The inventory excludes SQLite extensions and test implementation files. The
tests themselves remain upstream and in their current languages. SQLite's
engine is over 200,000 source lines, so this is a staged port of its subsystems,
not a small conversion of a handful of files.

The existing tests remain in their current languages. SQLite's `testfixture`
build uses private implementation symbols, while the Tcl extension path uses
the public `sqlite3_*` API. Once the FreeBASIC library implements enough of
that API, the Tcl extension can be linked against it and the existing Tcl
regression scripts can exercise the port. Reusing `testfixture` will also
require a deliberate compatibility layer for its private test hooks.

The remaining implementation order is:

1. Custom allocator configuration, per-connection status, and process initialization.
2. VFS and operating-system interfaces, including the Windows mutex backend.
3. Remaining Lemon semantic actions and destructors, then name resolution.
4. Table-backed SELECT, DDL/DML compilation, and the virtual database engine.
5. B-tree, pager, rollback journal, and WAL.
6. Remaining public API coverage, test hooks, and optional extensions.

The source files `sqlite3_tokens.bi`, `sqlite3_keyword_data.bi`,
`sqlite3_character_classes.bi`, `sqlite3_parser_tables.bi`,
`sqlite3_parser_rule_ids.bi`,
`sqlite3_api_constants.bi`, `sqlite3_fp10_tables.bi`, `sqlite3_opcodes.bi`,
`sqlite3_global_data.bi`,
`sqlite3_api_declarations.bi`, and
`sqlite3_internal_api_declarations.bi` are generated.
`fb_tools/sqlite_codegen/`
contains the FreeBASIC converter that reads Lemon's `parse.h`, SQLite's
generated `keywordhash.h`, parser tables, the selected grammar rule and symbol
names used by semantic actions and stack cleanup, the opcode table, the ASCII
character table in `src/tokenize.c`, and the ASCII lowercase map in
`src/global.c`. IDs are regenerated from Lemon's name tables so grammar
changes do not silently redirect handlers or destructors.
Run `make -C fb_src regen-generated` to regenerate those includes after
changing the SQLite grammar or tokenizer tables.

`fb_tools/c2fb/` contains a FreeBASIC C-header converter. It emits reusable
declarations for the public API and internal functions, 493 public numeric
constants from `sqlite.h.in`, and the power-of-ten words used by `sqlite3AtoF`.
It preserves the parser's `Token` value layout in the generated internal ABI
declarations and reports variadic declarations and unsupported constants.
It emits C variadic prototypes as FreeBASIC `...` declarations.
Unknown typedef scalars are emitted as C `int` and need review before use.
Its `translate-simple-tree` mode emits candidate bodies for a conservative
subset of local declarations, assignments, conditionals, loops, returns, and
selected pointer and structure expressions. The expression parser preserves C
grouping, integer boolean values, known arithmetic types, scalar casts, ASCII
character constants, and nested conditional expressions. It skips conditional
C branches and any function containing unsupported statements or types.
It also handles typedef chains, known call signatures, forward/private helpers,
static string literals, primitive size queries, multiple declarations, lexical
scopes, fixed local arrays, and loop exits or named jumps. The port's declared
array fields select the correct FreeBASIC indexing syntax. Missing structure
fields and opaque child-pointer layouts still need review or type mapping.
Run `make -C fb_src check-bulk-candidates` to generate a preprocessed batch and
write `fb_src/build/candidates/compile-report.csv` with compiler diagnostics.
Files with missing layouts or other compilation failures make the check return
a nonzero status. Review each candidate's layout and dependencies before
integration. `make -C fb_tools/c2fb test` compares the supported conversion
behavior against compiled C using both FreeBASIC backends.
Use `make -C fb_src bulk-candidate-files SOURCE_FILES='carray.c,vdbevtab.c'`
to regenerate a selected source batch without preprocessing the full tree.
Set `FEATURE_DEFINES` and `CANDIDATE_DIR` for the intended profile and output.
For wider debug branches, `bulk-candidate-files-loose` accepts the same source
selection and feature definitions while keeping callers with unconverted local
helpers. `C2FB_DISABLE_ASSERTS=1` suppresses expanded C assertions only in the
candidate preprocessor input; candidate files mark this and required checks
must be restored before integration. For a debug batch,
`C2FB_RESTORE_ASSERTS=1` translates active assertions into calls to the
FreeBASIC `sqlite3DebugAssertCheck()` helper, which logs and aborts on a failed
condition. The two options are mutually exclusive. Use
`check-bulk-candidate-files-loose` with matching `FBC` feature flags to
compile-screen the selected batch.
Regenerate declarations and constants with `make -C fb_src regen-api-declarations`.

FreeBASIC is also part of the work: port code will be used to exercise the
compiler, and reproducible compiler defects can be fixed in the compiler
checkout at `/home/jkfirth/fbc/src`. Before changing the compiler, reduce the
issue to a small FreeBASIC program and confirm at least one compiler defect:
valid FreeBASIC is rejected; backends disagree semantically; generated code
violates documented FreeBASIC behavior; an internal invariant is broken;
target or host behavior differs where the language requires consistency; or
the compiler crashes, corrupts state, or emits invalid output. Port-specific
assumptions belong in this tree.

The version string and source ID in `sqlite3_metadata.bas` describe the
upstream check-in represented by this checkout. Update them with the SQLite
version and source ID when rebasing the port.

For C ABI declarations, use FreeBASIC `Long` for C `int` and `LongInt` for
SQLite's 64-bit integer types. On the current 64-bit target, FreeBASIC
`Integer` is 64 bits and does not match SQLite's 32-bit `int` parameters.

<!-- end of README.md -->

The WAL read-transaction cluster now maps walIndexReadHdr(), walBeginShmUnreliable(), and walTryBeginRead(), then connects the C2FB-generated read-transaction entry points and lock teardown. The default thread-safe library build passes; WAL runtime behavior is unverified.

The WAL writer cluster now begins and ends writer transactions, restarts the WAL when reader marks permit it, encodes and writes frames, recomputes checksums after in-place changes, updates the wal-index, and handles rollback/savepoint state. The default thread-safe library build passes; WAL runtime behavior is unverified.

The WAL checkpoint cluster now builds a sorted iterator over frame pages, copies safe frames into the database, syncs checkpoint data, tracks backfill progress, and handles passive, full, restart, and truncate modes. The default thread-safe library build passes; checkpoint runtime behavior is unverified.

WAL close, commit-callback retrieval, exclusive-mode transitions, and file-handle accessors now have bodies. The ZIPVFS frame-size accessor remains behind its feature guard. The default thread-safe build passes; WAL runtime behavior is unverified.

The latest pager batch translates transaction finalization, WAL read-transaction begin, checkpoint forwarding, and WAL callback retrieval together with their local helper closure. It passes the default thread-safe library build; runtime behavior is unverified.

The Pager WAL write path now includes pagerWalFrames and pager_write_changecounter. It filters pages past the commit size, updates page-1 version metadata, forwards frames to WAL, and notifies backups after successful writes. The full build passes; runtime behavior is unverified.

The C2FB window batch now covers all 62 indexed functions in `src/window.c`
(2,113 indexed C lines). Its 11 newly integrated routines generate aggregate,
peer, row-return, and frame VDBE code through `sqlite3WindowCodeStep()`.
Stable name and no-op callback accessors preserve the pointer comparisons used
by SQLite's built-in window functions. All 15 translated procedures passed
per-procedure compiler checks, and the full thread-safe library build passes.

The unchanged `window1.test` now executes all 348 cases. It passes the named-
window view, trigger INSERT SELECT, and tuple-IN cases that previously failed
or crashed. Source-less SELECTs now dispatch to window rewriting after name
resolution attaches the window list. EXISTS and discard destinations drop
unneeded ORDER BY and DISTINCT clauses before that rewrite. Simple SELECTs now
open `SRT_EphemTab` destinations before writing rows; this fixes view
materialization during UPDATE ... RETURNING at 73.2. The suite passes 348/348
and leaves 1,760 bytes in 28 SQLite allocations. The temporary Tcl bridge
advertises `windowfunc` so these upstream cases execute.
The unchanged `select1.test` passes 200/200 with its existing 304-byte
shutdown allocation; `select2.test` passes 22/22. The earlier `with1.test`
through `with3.test` runs occurred before the bridge enabled its CTE option, so
their 2/2 results were close-file checks only and did not cover CTE behavior.
The bridge cannot start `exists.test` because it lacks the Tcl helper
`faultsim_delete_and_reopen`.
The release, `SQLITE_TEST`, math-enabled, and statement-scanstatus library
profiles build with the latest SELECT destination handling.

The DROP TABLE and DROP VIEW parser actions now read `ifexists` from the
correct Lemon stack slot. This restores errors for nonexistent objects while
preserving `IF EXISTS`; `view-17.1` and `view-17.2` now pass. The unchanged
`view.test` run reaches view-32.1, then stops because the temporary Tcl bridge
does not accept `SQLITE_LIMIT_EXPR_DEPTH`. Before that bridge limit, view-29.1
still reports a malformed schema after an earlier rejected CREATE VIEW.

The REAL text rendering path now preserves a decimal marker for plain integral
REAL values, and the internal `%!` formatting flag keeps that marker when
formatting with `%g`. This fixes the distinction between `8` and `8.0` in
`quote()` output. The unchanged `windowA.test` passes all 20 cases with no
SQLite allocation leaks. The release, math-enabled, and statement-scanstatus
shared libraries also rebuild successfully with this formatting change.

Two runtime fixes restore aggregate-context reset and zero-argument aggregate
execution in the VDBE. `sqlite3SelectDup()` now copies window definitions and
rebuilds the cloned SELECT's window-function list, matching upstream. The
tuple-vector semantic action now reads the expression list from the correct
Lemon stack slot. These changes let trigger INSERT SELECT and windowed tuple-IN
queries generate their input records. No C2FB changes were needed because the
relevant window copy helpers were already translated; the gap was in the
manual SELECT-copy and parser integrations.

`sqlite3_create_window_function()` now allocates a user-function definition
when `sqlite3FindFunction()` is called with its create flag. A direct C API
probe registers a sliding `winsum()` callback and returns `1, 3, 5` as expected.
With a temporary test-only Tcl bridge helper, unchanged `window5.test` now
passes 9/9 and reports no tracked allocation leaks.

The per-connection `sqlite3RegisterLikeFunctions()` path is now implemented
beside the private `likeFunc` callback. It re-registers the two- and
three-argument LIKE overloads and applies case-sensitivity flags; the full
threaded library build passes, while runtime LIKE reconfiguration is unverified.

Virtual-table coverage is now 39 of 39 indexed functions (1,062 C lines):
`sqlite3_declare_vtab()` parses module-declared columns, `sqlite3_vtab_config()`
applies constructor options, `sqlite3VtabOverloadFunction()` handles module
function overrides, and `callFinaliser()` routes commit and rollback callbacks.
The full library build passes; virtual-table runtime behavior is unverified.

The DBSTAT module now has bodies for all 19 indexed functions (681 C lines).
Shared `StatTable`, `StatCursor`, `StatPage`, and `StatCell` layouts let C2FB
translate the page scan and column callbacks; its constructor, ZIPVFS offset
helper, and module registration were adapted manually. The default library
build passes, and the DBSTAT-enabled module compiles; runtime scan behavior is
unverified.

The DBSTAT module now has bodies for all 19 indexed functions (681 C lines).
The shared `SqliteDbstatTable`, `SqliteDbstatCursor`, `SqliteDbstatPage`, and
`SqliteDbstatCell` layouts let C2FB translate the page scan and column callbacks;
the module constructor, ZIPVFS size helper, and registration table are adapted
manually. The default library build passes, and the DBSTAT-enabled module
compiles; runtime scan behavior is unverified.


The all-source C2FB pass now preprocesses all 80 engine C files without
failures and can regenerate candidates even for functions that already have
FreeBASIC bodies. Its 897 emitted procedures were compile-checked individually;
449 compile on their own. All emitted names already matched existing bodies, so
this was a broad converter audit rather than a coverage increase. The failed
checks identify compiler and helper-closure blockers in the existing source
groups.

The later focused C2FB passes compiled 88 selected-source candidates and 24
candidates from a loose residual-module pass. All passing names already had
bodies in the ledger, so these passes added no source coverage. `allocSpace` is
now ported in `sqlite3_vdbe_core.bas`; it reuses unused opcode-array storage and
places any remainder in one fallback allocation.

Optional scalar math and percentile callbacks now register through the
FreeBASIC function table with SQLite's feature flags and callback user data.
ceilingFunc and logFunc are ported alongside the converted math and percentile
callbacks. The optional SQLITE_SOUNDEX profile also ports and registers
soundexFunc. The default, combined math/percentile, soundex-only, and combined
scalar-feature library builds pass; runtime behavior remains unverified.


The optional FILESTAT and WALSTAT profile now registers sqlite_filestat() and
sqlite_walstat(). C2FB translated both callbacks; the port also supplies the
pager forwarding routine and WAL-index/checkpoint JSON helpers. The enabled
library builds. The Windows SEH exception handler used by SQLite around WAL
diagnostics is not reproduced, and diagnostic runtime behavior remains
unverified.


The SQLITE_ENABLE_STMT_SCANSTATUS profile now collects scan entries, records
VDBE instruction ranges, and exposes sqlite3_stmt_scanstatus_v2() output
including frame-aware cycle totals. The FreeBASIC opcode table now imports all
property bits from SQLite's generated OPFLG_INITIALIZER; the previous table
contained only jump flags, which caused NCYCLE range queries to return zero.
The regenerated 192-entry table matches the C table. A direct C ABI smoke now
passes for loop/visit counts, estimates, names, explain text, reset behavior,
and nonzero cycle counts. The unchanged upstream scanstatus.test passes 60/60,
and scanstatus2.test passes 22/22, both with all tracked allocations freed.
These cases cover scan ranges, correlated subqueries, materialized CTEs,
temporary sort/group-by plans, automatic indexes, bloom filters, and trace-time
scanstatus reporting. A temporary Tcl bridge supplies the test-only last-
statement and scanstatus commands; the upstream test files remain unchanged.


The SQLITE_ENABLE_PREUPDATE_HOOK profile now includes the VDBE callback producer, old/new row-value accessors, and the
count, trigger-depth, and blob-write APIs. The enabled library builds; callback
behavior remains unverified at runtime.


The public sqlite3_stmt_explain() setter now updates the packed EXPLAIN mode,
uses the existing reprepare path when needed, and refreshes result-column
counts. Default and combined optional-feature library builds pass; runtime
behavior remains unverified.

The statement execution path now follows SQLite's `sqlite3Step` and outer
`sqlite3_step` split. It starts and resets VDBEs, accounts for active readers
and writers, transfers saved-SQL errors, invokes profile callbacks, and retries
schema invalidation through `sqlite3Reprepare`. VDBE halt handling releases
the matching reader and writer counts. This adds 136 indexed C lines, alongside
the two VDBE halt-accounting changes. The default threaded library builds;
runtime behavior remains unverified.

The EXPLAIN path now generates opcode names with embedded synopsis text from the
same `opcodes.h` used for opcode constants. It formats P4 values, recursively
renders cursor-hint expressions, translates opcode synopsis placeholders, walks
trigger subprograms, and populates EXPLAIN and EXPLAIN QUERY PLAN rows. These
bodies add 372 indexed C lines. The FreeBASIC `sqlite_codegen opcode-names` mode
regenerates the opcode names as part of `make -C fb_src regen-generated`. The
default threaded library builds, and the source module compiles with
`SQLITE_ENABLE_EXPLAIN_COMMENTS` and `SQLITE_ENABLE_CURSOR_HINTS`; its later
runtime differential is recorded in the EXPLAIN checkpoint below.

VDBE explain-comment support now formats variadic opcode comments and prints
the SQL text retained by a debug VDBE. Debug register traces now print Mem
values and check Mem ownership invariants. Build that profile with:

The parser and query debug tree renderer now covers 27 of 35 indexed functions
(410 of 1,189 indexed C lines). Its indentation state is defined in
`sqlite3_treeview_types.bi`; the `SQLITE_DEBUG` library builds, but
runtime output remains unverified.

```sh
make -C fb_src TARGET=build/libsqlite3-fb-debug.so \
  FB_DEFINE_FLAGS='-d SQLITE_DEBUG=1 -d SQLITE_ENABLE_EXPLAIN_COMMENTS=1'
```

The debug library builds. Runtime trace output is unverified; the coverage-only
`test_addop_breakpoint` hook remains outside the port.

The JSON virtual-table callback table now registers `json_each`, `json_tree`,
`jsonb_each`, and `jsonb_tree`. Its filter accepts text or JSONB input with an
optional root path, and its column callback returns each row's key, value,
type, atom, id, parent, full key, path, and source JSON. This adds 199 indexed C
lines and connects the existing eponymous-table lookup path. The default
threaded library builds; JSON virtual-table behavior remains unverified at
runtime.

The JSON registration table now includes the JSON and JSONB scalar overloads,
the extraction operators, pretty printing, error-position reporting, and the
four JSON group aggregates. The new pretty/error/aggregate callbacks add 195
indexed C lines. The default library builds; runtime function behavior remains
unverified. The debug batch provides `jsonDebugPrintBlob()`, `jsonShowParse()`,
and `jsonParseFunc()`; the `json_parse()` SQL callback is registered only in
`SQLITE_DEBUG` builds. Runtime behavior remains unverified.

JSON path lookup now also performs insert, replace, delete, and set edits. It
builds nested JSONB object/array tails when an edit creates missing path
components, then repairs the affected parent sizes. This adds the 31-line
`jsonCreateEditSubstructure` helper and restores edit-mode handling in the
existing path traversal. The default library builds; mutation behavior remains
unverified at runtime.

The converter now accepts a comma-separated source-file selection through
`make -C fb_src bulk-candidate-files SOURCE_FILES='carray.c,vdbevtab.c'`. This
keeps iterative batch conversion scoped to the files whose layouts or parser
support have just changed. Its new private layouts cover the CARRAY bind/cursor
records and bytecode-vtab records; pointer-level `const` no longer prevents
prototype generation. The selected CARRAY, DBSTAT, and bytecode-vtab pass
produced 14 candidate callback bodies, of which 13 filled previously missing
functions. Each candidate compiled individually.

The CARRAY source now has FreeBASIC bodies for all 14 indexed functions and
331 C lines. The bytecode-vtab source has bodies for all 12 indexed functions
and 311 C lines. `sqlite3_carray_bind_v2` copies transient numeric, text, and
iovec data into SQLite-owned storage, checks allocation-size arithmetic, and
retains the caller's destructor for non-transient data. Both virtual tables
have stable callback tables and feature-guarded registration paths. The
combined CARRAY, DBSTAT, and bytecode-vtab feature library builds; runtime
behavior remains unverified.

The optional `sqlite_dbpage` virtual table now has bodies for all 16 indexed
functions, covering 371 C lines. The `DbpageTable` and `DbpageCursor` records
are mapped explicitly, and the static module callback table is registered in
the built-in extension list. The `SQLITE_ENABLE_DBPAGE_VTAB` library builds,
and the unchanged upstream `dbpage.test` passes 34/34 cases with no tracked
leaks.
Build the feature profile with:

```sh
make -C fb_src TARGET=build/libsqlite3-fb-dbpage.so \
  FB_DEFINE_FLAGS='-d SQLITE_ENABLE_DBPAGE_VTAB=1'
```

The MEMSYS5 module participates in the build when enabled and is selected
through `SQLITE_CONFIG_HEAP`. Its initialization and allocation paths are now
covered by the runtime checkpoint below. Debug assertion failures go through a
single log-and-abort helper.

The optional MEMSYS3 allocator has translated allocation and free-list
procedures, a manual heap initializer and callback table, and a checked
pool-index calculation in `memsys3FreeUnsafe`. `sqlite3Memsys3Dump` now emits
chunk metadata, small and hashed free lists, and current and peak usage to
stdout or a file. It checks chunk boundaries before reading tail metadata and
uses the SQLite debug assertion handler for inconsistent headers. A temporary C
ABI smoke configured the MEMSYS3 callbacks, allocated and freed blocks, and
verified the debug dump output. A current `THREADSAFE=1` stress workload also
matches C across 2,048 variable-size allocations, shuffled frees, reallocations,
a forced oversized allocation failure, and recovery afterward. It verifies
payload preservation, non-overlap, and clean shutdown. Default and
`SQLITE_DEBUG` MEMSYS3 library builds pass. The debug dump candidate was
generated with C2FB's preprocessed file mode and assertion suppression, then
integrated with debug assertions restored. No converter change was needed.
Build the optional allocator with:

```sh
make -C fb_src TARGET=build/libsqlite3-fb-memsys3.so \
  FB_DEFINE_FLAGS='-d SQLITE_ENABLE_MEMSYS3=1'
```

Repeated C2FB batches and manual backend/registration ports now cover all 39
`os_kv.c` functions and 618 indexed C lines. The optional Unix VFS includes
file-backed record reads and writes, binary decoding, file callbacks, VFS
tables, and registration. The `SQLITE3_FB_OS_KV_DEFAULT` profile routes
`sqlite3_os_init()` through the K/V VFS registration and returns `SQLITE_OK`
from `sqlite3_os_end()`. The optional Unix and standalone default-VFS profiles
build. Both profiles pass the local/session binary-storage C API differential
described below; the default profile also opens plain filenames through the
VFS selected by `sqlite3_os_init()`. The open path preserves SQLite's
`:localStorage:` and `:sessionStorage:` aliases and stores KVVFS temporary
tables in memory.
Build the Unix optional profile with:

```sh
make -C fb_src TARGET=build/libsqlite3-fb-oskv.so OS_KV_OPTIONAL=1 \
  FB_DEFINE_FLAGS='-d SQLITE3_FB_OS_KV_OPTIONAL=1'
```

Build the standalone profile that makes `kvvfs` the default VFS with:

```sh
make -C fb_src TARGET=build/libsqlite3-fb-oskv-default.so OS_KV_OPTIONAL=1 \
  FB_DEFINE_FLAGS='-d SQLITE3_FB_OS_KV_OPTIONAL=1 -d SQLITE3_FB_OS_KV_DEFAULT=1'
```

The Linux Unix VFS now includes C-named aliases for xOpen, POSIX xLock, close,
read, write, truncate, sync, and access callbacks, plus `robust_ftruncate`,
`unixGetpagesize`, and `unixSleep`. Shared inode and SHM bookkeeping use the
same process-wide mutex wrappers as upstream. Debug and FILESTAT builds now
describe POSIX advisory locks from `/proc/<pid>/fdinfo`, including held
database and WAL locks, and report SHM and inode state in the file-stat JSON.
The Unix VFS exposes version 3 system-call set/get/next callbacks, and its
common POSIX wrappers dispatch through the override table. As in the upstream
implementation, changing that table is not synchronized with concurrent I/O,
so configure overrides before database operations begin. Main-database opens
also reuse deferred descriptors when the device, inode, and read mode match;
runtime descriptor reuse is unverified.
All 135 indexed Unix functions now have bodies (5,514 indexed C lines); this
source signal does not establish semantic parity. The xOpen/xLock adapters use
the port's UnixFile and UnixLockInfo layouts. Apple proxy conch acquisition,
path switching, file controls, lock callbacks, AFP byte-range locking, and the
`unix-afp` VFS run through guarded method tables. VxWorks canonical path IDs
and named-semaphore locking are also represented. Native Apple and VxWorks
runtime behavior remains unverified, and automatic filesystem-based proxy
selection is still unmapped. The Windows source index now
has bodies for 109 of 109 functions (3,594 of 3,594 indexed C lines). The
dedicated `sqlite3_os_win_memory.bas` module supplies the optional Win32 heap
callbacks, method table, compact operation, and reset operation; the general
allocator selects it under `SQLITE_OS_WIN` and `SQLITE_WIN32_MALLOC`. The Win32
alertable worker wait retries completion notifications.
Guarded helper and allocator objects compile in local base,
debug/heap-validation, and process-heap profiles; native Windows and Cygwin
object builds and runtime behavior remain unverified.

The latest source-aware C2FB pass expanded `os_win.c` against MinGW headers and
used a 32,768-entry declaration bound while retaining 8,192-entry function
workspaces. It emitted 26 simple procedures and skipped 5,720 unsupported or
duplicate candidates. It identified the allocator's `winMemRoundup` identity
callback. The isolated candidate checker still lacks some WinFile and helper
declarations for larger Windows batches; the integrated guarded objects compile.

The latest bulk C2FB sweep covered `os_unix.c`, `os_win.c`, and `wal.c`; the
default-profile candidates were already represented in the port. An Apple
locking-style sweep emitted eight simple procedures, also already present, and
rejected the remaining proxy callbacks at `unixFile` member access. I ported
the proxy group together in `sqlite3_os_unix.bas`: path switching, transform,
GET/SET file controls, reserved-lock checking, lock/unlock callbacks, and method
table routing now use the conch helpers. The transform path includes the
read-only filesystem fallback using Darwin's `statfs` layout, guarded by a
size check against [Apple's `statfs` definition](https://github.com/apple/darwin-xnu/blob/main/bsd/sys/mount.h).
`fillInUnixFile` now owns common post-open setup and selects the registered
no-lock, POSIX, dot-file, flock, and NFS methods. POSIX byte-range operations
route through `unixFileLock`, and final WAL shared-memory disposal goes through
`unixShmPurge`. Apple-profile object builds pass with `HAVE_GETHOSTUUID=0` and
with `SQLITE_TEST`, `HAVE_GETHOSTUUID=1`, and a `LOCKPROXYDIR` override. The
default threaded library build passes. Native Apple runtime behavior and
automatic filesystem-based proxy selection remain unverified. The source
index now has bodies for all 3,243 in-scope definitions and all 124,545 indexed
function lines; source-body coverage does not establish semantic parity.

The latest Unix pass connected VxWorks path-ID lifetime and named-semaphore
callbacks, then added the Apple AFP `fsctl` lock group and registered
`unix-afp`. AFP lock transitions share the inode counters and use the common
Unix mutex; proxy path lookup now understands the AFP context record. Default
threaded library and Apple locking-style objects compile, including the Apple
`SQLITE_TEST` profile. Apple errno lookup now uses Darwin's `__error()` and
Darwin's EAGAIN, ETIMEDOUT, and ENOLCK values; lock-error classification also
matches SQLite's transient-error set. C2FB now scans private layouts in
implementation `.bas` files, maps the Unix C records to `UnixFile` and
`UnixLockInfo`, and lowers mapped local struct declarations and `sizeof`
expressions. The Apple profile translated 22 candidates, including
`afpSetLock`, `afpCheckReservedLock`, and `afpLock`; loose mode translated 45,
including all five AFP callbacks after retaining callers with unresolved local
helpers. The Unix private records now live in `sqlite3_os_unix_types.bi`, which
is included by both the backend and separate C2FB candidate modules. C2FB also
suppresses a second prototype when its C and FreeBASIC indexes describe the
same helper. An isolated strict-candidate compile accepts the translated AFP
set-lock, reserved-lock check, and lock callbacks. The full loose candidate
still depends on helpers outside the translated subset, and the strict profile
does not yet translate AFP unlock/close. These candidates have not replaced the
hand-integrated AFP implementation. The macro-generated `afpIoFinderImpl`
remains outside the body translator. A Windows-profile C2FB pass now converts
`winSetSystemCall`, `winGetSystemCall`, and `winNextSystemCall` from
`os_win.c`. It maps the file-local `win_syscall` array through an explicit
FreeBASIC name and counts its aggregate initializer; the focused candidate
object compiles. These callbacks are now implemented in the Windows VFS helper;
the override table initializes before VFS registration, and typed dispatch
aliases route its supported Win32 entries through the table. The Cygwin
full-path branch now uses the same table for POSIX path conversion and symlink
resolution, and its temporary-directory search follows Cygwin's environment.
FBC generated C for the Cygwin target with `-target cygwin -r`; no Cygwin object
or runtime verification is available because `cygwin-gcc` is not installed.
Native Apple, VxWorks, and Windows runtime behavior remains unverified.

A VDBE DDL pass now dispatches OP_Destroy, OP_ParseSchema, and the three
OP_Drop* cleanup instructions. The executor uses the existing translated
B-tree, schema initializer, and unlink routines; no C2FB changes were needed
for this gap. Follow-up dispatch now includes IfEmpty, Pagecount/MaxPgcnt,
IncrVacuum, SqlExec, Vacuum, IntegrityCk/IFindKey, strict-table TypeCheck,
ReopenIdx, Program/Param trigger frames, ResetCount, SoftNull, subtype, ElseEq,
AggInverse, and AggValue, and gives CollSeq and SeekHit their runtime state
changes.
The executor now has dispatch cases for all 192 generated opcode labels;
compile-time feature guards still control which optional handlers are built.
Strict-table `TypeCheck` applies column affinity, checks the resulting Mem type
against the packed standard-type nibble, handles generated columns, and reports
`SQLITE_CONSTRAINT_DATATYPE` with the table and column names. `ReopenIdx`
clears an existing index cursor when its root is unchanged and opens a replacement
when the root changes.
Window aggregate inverse/value operations use the registered callbacks and
VDBE accumulator cells; aggregate and window runtime behavior remains unverified.
Trigger Program frames allocate and reuse child Mem/cursor storage, map OLD/NEW
registers through Param, and restore the caller when a successful child Halt runs.
Trigger runtime behavior remains unverified.
SqlExec saves and restores authorization, trace, and analysis-limit state around
nested sqlite3_exec calls. Vacuum calls the translated database rewrite routine.
IntegrityCk calls the B-tree integrity walker for each selected root page;
IFindKey applies the expression-index floating-point tolerance helper.
Default and debug/column-mask library builds pass. Runtime behavior remains
unverified.

A follow-up VDBE pass added virtual-table cursor, filter, column, rowid, update,
transaction, create, destroy, rename, `IN` value-list, and integrity-check
operations. It also adds aggregate-step fallback, cursor pin/unpin, row-size
branching, preformatted row transfer, shared-cache table locks, WAL checkpoint
and journal-mode changes, and the optional `sqlite_offset()` opcode. The
shared-cache B-tree lock wrapper was already available as a C2FB translation;
this pass did not require converter changes. The default threaded library
build passes, and the executor compiles with `SQLITE_ENABLE_OFFSET_SQL_FUNC`.
The executor also compiles in the `SQLITE_DEBUG` plus column-mask profile.
Runtime behavior is unverified; no SQLite tests were run in this pass.

The authorizer callback repair now invokes `xAuth` once per authorization
action. C2FB's older translated `realAuthCheck` body had emitted the callback
twice; `sqlite3_set_authorizer()` also now honors `SQLITE_ENABLE_API_ARMOR`.
Transaction and savepoint generation performs its corresponding parse-time
authorization checks. The default threaded library build passes, and the
authorizer modules compile with API armor enabled. Runtime behavior remains
unverified; no SQLite tests were run.

The attached-database VDBE pass now records B-tree and shared-cache lock masks
for each database, dispatches `OP_Transaction`, `OP_OpenRead`, `OP_OpenWrite`,
`OP_ReopenIdx`, `OP_CreateBtree`, and `OP_Clear` with database indices, and
routes commit finalization through the translated `vdbeCommit()` two-phase
commit helper. Savepoint operations now visit each attached B-tree and preserve
deferred-constraint snapshots in the Savepoint record layout. Thirteen repeated
side-effecting calls in the translated commit helper were corrected to reuse
their first result. The full threaded library builds with both the default and
`SQLITE_MAX_ATTACHED=32` profiles; VDBE shared-lock entry/leave code handles
the byte-array mask in the large profile. The source ledger lists all 3,243
in-scope definitions as present and its C2FB repair queue is empty, so this pass
needed no converter change. Runtime behavior is unverified; no SQLite tests
were run.

The release VDBE executor now guards `sqlite3VdbeIncrWriteCounter` at its
declaration and all five call sites with `SQLITE_DEBUG`, matching the upstream
empty macro in non-debug builds. Full release, debug, and
`SQLITE_MAX_ATTACHED=32` library builds pass. An SQLite-internal dynamic-symbol
audit finds no undefined SQLite symbols in the release, debug, or
`SQLITE_MAX_ATTACHED=32` libraries. The debug library still exports the
counter helper. Runtime behavior is unverified.

`SQLITE_DBSTATUS_SCHEMA_USED` now counts the schema hash tables and walks table
and trigger allocations through the non-destructive `pnBytesFreed` path, across
all attached databases. Release, `SQLITE_DEBUG`, and
`SQLITE_ENABLE_MEMORY_MANAGEMENT` library builds pass, and each has zero
undefined SQLite symbols. C2FB's repair queue is empty and the latest candidate
sweep found no uncovered body, so this change reused existing translated
deletion routines. Status behavior is unverified; no SQLite tests were run.

Parser finalization now dispatches all 50 active Lemon `%destructor` symbols
from `src/parse.y` in stack-pop order, including source lists, ID lists, CTEs,
windows, trigger steps, and frame-bound expressions. The FreeBASIC parser-ID
generator now emits those nonterminal IDs alongside the existing reduction
IDs. A static comparison against the generated Lemon `yy_destructor` found no
missing symbol IDs or cleanup cases. Release and debug full-library builds
pass with no undefined SQLite symbols; parser error cleanup remains unverified
at runtime.

The `SQLITE_DBSTATUS_STMT_USED` sizing walk now temporarily disables lookaside
while VDBEs are measured, then restores it before clearing `pnBytesFreed`, as
`src/status.c` does. The unchanged `dbstatus.test` and `dbstatus2.test` pass
154/154 and 33/33 with no tracked leaks.

Compound SELECT reductions now carry the operator token for `UNION`, `EXCEPT`,
and `INTERSECT` as well as `UNION ALL`. A compound right-hand SELECT is wrapped
as a FROM-subquery before linking, matching the `src/parse.y` action. Release
and debug library builds pass. Compound SELECT runtime behavior remains
unverified; no SQLite tests were run.

Window-expression duplication uses `sqlite3WindowDup()` and clears the
copied Window pointer before allocation so OOM cleanup cannot release the
source expression's window. The `SQLITE_OMIT_WINDOWFUNC` library profile also
builds after adding the upstream feature guards around window-only code in the
translated resolver, SELECT planning, expression walkers, cleanup, and parser
paths. The expression-duplication smoke exercises window definitions only
through compilation; separate window tests cover query execution.

The full `SQLITE_ENABLE_PERCENTILE` library profile builds and has no undefined
SQLite symbols. The earlier inventory note about a duplicate declaration in
`sqlite3_analyze.bas` was stale; the profile needed no source or C2FB repair.
Percentile runtime behavior remains unverified.

IN-SELECT code generation now allocates an OP_Blob Bloom filter for eligible
one-time RHS subroutines, attaches the comparison KeyInfo before compiling the
SELECT, and passes the register through the SELECT destination so OP_FilterAdd
populates it. The OP_Once P3 register then enables OP_Filter probes in
`sqlite3ExprCodeIN`. Non-BINARY comparison collations and disabled optimization
profiles skip the filter. A source audit found 2,653 adjacent assignments in
139 older bulk-generated files that evaluated a captured C expression twice;
the port now reuses the C2FB temporary for the following local assignment.
This prevents duplicated allocator calls, VDBE emissions, and other expression
side effects. A second pass repaired 1,384 more adjacent captured-value
duplicates across 135 bulk files, including pointer stores. That pass fixed a
derived-table prepare leak in `sqlite3ExpandSubquery`; release and debug probes now finalize
simple, limited, and ordered FROM-subqueries with zero lookaside slots in use
and close successfully. A 100-iteration same-connection repeat also kept
lookaside usage at zero after each finalize. The current C2FB preprocessed-tree
output does not emit the audited duplicate patterns; these repairs required no
C2FB source change. Release and debug libraries build. Targeted Bloom,
function-call, DML, join, attached-database, foreign-key, savepoint, rollback,
and integrity probes pass.

C2FB now maps SQLite's `SubrtnSig` record to the existing
`SqliteSubroutineSignature` layout and lowers mixed string/integer
`sqlite3VdbeExplain` calls through a fixed adapter. Its `include-existing` path
now stages mapped bodies for comparison and filters duplicate declarations
against FreeBASIC call signatures. The isolated `expr.c` candidate pass emitted
169 procedures; 101 compiled individually and 68 still fail on unresolved
helper dependencies or layout mismatches. The candidate pass used the converter
build before a follow-up private-helper declaration refinement. The latest
converter failure note is stale: the current converter completed a fresh
preprocessed `expr.c` conversion, and the emitted candidates contained no
adjacent duplicate temp-to-assignment evaluations. The 68 procedures still need
dependency or layout work, though all already have port bodies. The Bloom
branch was integrated into the existing SQLite helper after comparing the
generated candidate with upstream.

`SQLITE_DBSTATUS_LOOKASIDE_USED` now counts both large and small lookaside
slots. Reset reattaches each pool's free list to its initial list and refreshes
the aggregate slot counters. Release, debug, and `SQLITE_OMIT_TWOSIZE_LOOKASIDE`
library builds pass with zero unresolved SQLite symbols. The unchanged
DBSTATUS tests exercise lookaside counts and high-water reset.

The pager now builds with both `SQLITE_ENABLE_SNAPSHOT` and
`SQLITE_OMIT_WAL`. WAL-only pager operations are excluded or stubbed under the
same feature guard used by upstream, and snapshot get/open/recover return
`SQLITE_ERROR` when WAL support is omitted. The default release,
snapshot-with-WAL, and snapshot-without-WAL builds pass; each has zero
unresolved SQLite symbols. At that checkpoint, no SQLite runtime tests had been
run for these profiles.

The current function index contains FreeBASIC bodies for all 3,243 in-scope
SQLite source definitions, and `PORTING_REPAIR_QUEUE.csv` has no missing-body
entries. The separate `expr.c` candidate audit still has 68 procedures that do
not compile individually because of unresolved helper dependencies or layout
mismatches; those functions already have port bodies, so they are not missing
routines. This pager feature-guard pass exposed no converter defect and needed
changes in the SQLite port only. Body presence and successful linking do not
establish semantic parity; the direct API smoke above covers only the listed
table, index, aggregate, transaction, and cleanup cases.

The initialization mutex now uses the reference-counted lifetime from
`src/main.c`: concurrent and recursive initialization callers share it, and
the final caller frees it after leaving the lock. This removes a 56-byte
process-memory remainder that survived database close. A direct C ABI
lifecycle probe reports zero bytes after initialize, close, and shutdown in
both release and `SQLITE_DEBUG` builds. A fresh run of the unchanged upstream
`test/main.test` through the C Tcl shell linked to the FreeBASIC `SQLITE_TEST`
library passes 56/56 tests with no tracked allocations at finalization. Its
thread tests are skipped because the temporary Tcl bridge lacks the `sqlthread`
command; the linked library reports `sqlite3_threadsafe() == 1`. Sixteen threads
making 3,200 concurrent `sqlite3_initialize()` calls also complete without
errors in release and debug builds; shutdown leaves zero tracked bytes.

The unchanged upstream C `testfixture`, linked directly to the current native
and GCC-backend FreeBASIC libraries, now runs `test/main.test` 95/95 on both
backends with no errors or tracked leaks. This covers the cases omitted by the
earlier Tcl bridge profile.
The 50,000-row external-sort probe still passes in release and debug builds,
including all five sorter opcodes and zero lookaside usage after close.

No C2FB change was needed for this repair. The function ledger has no missing
in-scope routine bodies, and the 68 `expr.c` candidates with individual
compile blockers already have integrated FreeBASIC bodies; their blockers are
helper dependencies or record layouts rather than conversion throughput.

The unchanged upstream `test/select1.test`, `test/select2.test`, and
`test/select3.test` files now run through a temporary C Tcl shell linked to
the FreeBASIC library, using SQLite's per-file slave-interpreter lifecycle.
Their assertions pass: 200/200, 22/22, and 92/92. The close-all-files checks
pass in all three suites. `select2.test` and `select3.test` end with zero
tracked allocations; `select1.test` retains 304 bytes in six allocations and
needs a separate leak trace. The `SQLITE_TEST` VDBE search, found, and sort
counters now match `select2.test`'s planner checks. Temporary `BTREE_SINGLE`
handles close with their last cursor, and connection close now releases the
main, TEMP, and attached B-trees. The `group_concat()` separator is omitted
for the first non-NULL input. This pass found no C2FB conversion limitation.

The multi-row VALUES coroutine is now implemented in `sqlite3_values.bas`.
`sqlite3SelectNew` reserves the first SrcItem used by its zero-source-list
selects, and the SELECT materializer now reuses a coroutine already emitted
while parsing VALUES. Compound SELECT compilation passes its LIMIT counter
through each no-FROM term and does not decrement it twice. Compound output
names remain those of the left-most term.

The unchanged upstream `select1.test` through `select4.test` files pass all
assertions: 200/200, 22/22, 92/92, and 125/125. `select2.test` and
`select3.test` finish with no tracked allocations. `select1.test` retains
304 bytes in six allocations, and `select4.test` retains 576 bytes in eight
allocations; both pass their assertions and close-all-files checks. The
per-file slave runner and Tcl shell shim live in `/tmp`; upstream test files
were not modified.

These failures were in existing FreeBASIC SELECT and VALUES code, so this
repair did not require a C2FB change. The function ledger still has bodies
for all 3,243 indexed in-scope definitions. This test sample verifies the
listed query paths only; it is not full SQLite behavioral parity.

The unchanged `test/select7.test` initially exposed a mixed VALUES fallback:
double-quoted identifiers force UNION ALL terms, then a later constant row
starts a coroutine. The port now exempts VALUES terms from the ordinary
compound SELECT limit, emits a single VALUES term without consuming its
`pNext` compound sibling, and allows an `SF_Values` coroutine wrapper through
FROM-clause code generation. VDBE label resolution also permits unused labels
without an allocated label array while still validating every referenced jump
label. These repairs keep negative immediate operands separate from jump
targets and reject invalid label references before dereferencing them.

The unchanged upstream `select1.test` through `select7.test` files now pass
592/592 assertions. `select2`, `select3`, `select5`, `select6`, and `select7`
finish with no tracked allocations; `select1` retains 304 bytes in six
allocations and `select4` retains 576 bytes in eight allocations. In
`select7.test`, the 16-row DQS VALUES insert succeeds with
`SQLITE_LIMIT_COMPOUND_SELECT` set to 10. C2FB and FBC were unchanged: each
routine involved already had a body, and the failures were in FreeBASIC path
integration and validation.

The unchanged `test/select8.test` and `test/select9.test` also pass: 5/5 and
36,718/36,718 assertions, with no tracked allocation leaks. Across `select1`
through `select9`, 37,315 assertions pass. `select9` exposed two more SELECT
integration defects. `OP_ResetSorter` now clears sorter rows without resetting
the cursor's `OP_SequenceTest` counter, so partial ORDER BY sorting retains its
prefix groups. The LIMIT decrement emitted by `sqlite3SelectEmitOutputRow` is
now limited to an active sorter path, avoiding a second decrement when an
index already satisfies ORDER BY.

The C2FB-generated `flattenSubquery` body now handles the compound UNION ALL
view cases covered by `select9.test`. After preparation rewrites a collated
compound into a FROM-subquery, the SELECT dispatcher rechecks `pPrior` and
routes the rewritten tree through FROM code generation. The view queries use
their indexes and avoid a temporary sort, and the collated compound ORDER BY
cases pass. No C2FB or FBC source change was needed; the conversion body was
already present, and the remaining defects were in caller integration and
VDBE/SELECT runtime paths. Other compound flattening shapes still need
coverage.

The unchanged upstream `select1.test` through `select9.test`, plus
`selectA.test`, `selectB.test`, and `selectC.test`, now pass 37,749/37,749
enabled assertions through a temporary Tcl shell linked to the FreeBASIC
`SQLITE_TEST` library. The harness links the search, sort, and transfer-
optimization counters, and supplies the fixture's `optimization_control` and
selected `sqlite3_db_config` names; no upstream test files were changed. The
test library used:

```sh
make TARGET=build/libsqlite3-fb-test.so FBC='fbc -g -export' FB_DEFINE_FLAGS='-d SQLITE_TEST=1'
```

The temporary Tcl binding and fixture runner are under `/tmp/sqlite_fb_tests`.
`select1` retains 304 bytes in six allocations,
`select4` retains 576 bytes in eight allocations, and `selectA` retains 288
bytes in four allocations. The other listed suites report no tracked
allocations at finalization.

These runs found and repaired four integration defects. `sqlite3HexToBlob`
now treats its byte-count argument as the caller-provided number of hex digits,
which already excludes the closing quote; the manual SELECT literal path now
passes that same length. The B-tree cell parser accepts bounded reads from
`BtShared.pTmpSpace` as well as database pages, so the preformatted cell built
by `sqlite3BtreeTransferRow` can be validated before `OP_Insert`. The VDBE
cursor allocator now closes any existing cursor type, including a sorter,
before reusing its memory register. `sqlite3BtreeInsert` also accepts any
signed index-comparison result and uses its sign, matching the B-tree API
contract.

`sqlite3Select` now restores the EXPLAIN QUERY PLAN parent after each completed
SELECT path. This keeps compound merge branches as siblings and fixes the
`selectA-4.1.2` plan shape. The C2FB-generated `flattenSubquery` body was already
present; these were FreeBASIC integration and runtime fixes, so no C2FB or FBC
source change was needed. Source-body coverage remains 64.8% of the indexed
in-scope engine and public API code; at the recent source-body throughput, the
remaining body volume is about three days of work. Full semantic parity will
take substantially longer than completing the source-body inventory.

The standard release library also builds after these changes. The `SQLITE_TEST`
library builds with the VDBE search/sort counters exported for the temporary C
Tcl fixture adapter.

The latest unchanged B-tree regressions pass `delete.test` (68/68),
`delete3.test` (4/4), and `delete4.test` (29/29) on native and GCC, with all
tracked allocations released at shutdown. `insert2.test` passes all 29
assertions but reports 16 bytes in two allocations at shutdown. The full
`select1` through `select9`,
`selectA`, `selectB`, and `selectC` group still passes 37,749/37,749
assertions; `select1`, `select4`, and `selectA` retain the previously recorded
1,168 bytes in 18 allocations, while the other SELECT files finish without
tracked allocations.

These B-tree tests found several state and boundary defects in existing ported
routines. Commit phase two now changes `BtShared.inTransaction` from write to
read before the shared writer is dropped when another VDBE still holds a read
transaction. `moveToRoot` now clears the saved cursor key before opening the
root for a `CURSOR_REQUIRESEEK` cursor, keeping `pKey` and `eState` consistent.
Cursor restoration also preserves the search comparison in `skipNext`, as the
upstream routine does. The delete tests cover nested trigger deletes and a
WITHOUT ROWID delete spanning multiple indexes.

Large-delete cases additionally exposed two page-boundary errors. Leaf-page
redistribution now subtracts moved cell bytes from the next-page fill count,
and defragmentation accepts a cell beginning at the final valid four-byte
offset. No C2FB or compiler changes were needed: each affected routine already
had a FreeBASIC body. Source-body coverage remains 64.8% of the indexed
in-scope engine and public API code; at the recent source-body throughput, the
remaining body volume is about three days of work. Full semantic parity will
take substantially longer than completing the source-body inventory.

The VDBE halt path now includes the constraint detail stored in OP_Halt P4,
and OP_AutoCommit supplies the specific message for COMMIT, ROLLBACK, and
BEGIN when no matching transaction state exists. The first unchanged
`update.test` run passed 135/136 assertions; its remaining query-plan mismatch
was traced and repaired below. All 71 `insert.test`
assertions pass. `insert4.test` passes all 83 assertions, including
transfer-optimization selection and conflict rollback, once the temporary Tcl
bridge links the port's `sqlite3_xferopt_count` test counter. The bridge also
supports the `LEGACY_FILE_FORMAT` and `DEFENSIVE` db-config names required by
upstream fixtures. The initial `insert.test` run reported 160 bytes in 18
allocations, and the earlier `insert4.test` run reported 3,872 bytes in 36
allocations. The duplicate expression-list append and default/RETURNING text
copies described below account for those leaks.

`insert4.test` exposed a signed-rowid cell-size defect: the ordinary B-tree
cell builder and OP_RowCell transfer builder used the generic 7-bit length
for keys whose high byte is set, while SQLite's ninth varint byte carries all
eight remaining bits. Both builders now share the upstream-compatible
9-byte rowid length rule. The reduced C API case and all signed-rowid conflict
cases in `insert4.test` pass. The `SQLITE_TEST` optimizer counter increments
after the optimizer's semantic checks, matching upstream even when generated
code includes a runtime empty-destination guard. C2FB and FBC were unchanged;
the converter already produced the optimizer body, and the failures were in
FreeBASIC cell construction and test instrumentation.

The CHECK-constraint leak trace found older integrated bodies that evaluated
side-effecting C assignment values twice. `sqlite3AddCheckConstraint` appended
the expression list twice, `sqlite3AddDefaultValue` duplicated the default
span twice, and `sqlite3ExpandReturning` duplicated each output name twice.
These bodies now store the value already captured in a temporary. A fresh
C2FB `build.c` pass emits one `sqlite3ExprListAppend` call for
`sqlite3AddCheckConstraint`, so no converter source change was needed. The
unchanged upstream `insert.test` and `insert4.test` now pass 71/71 and 83/83
assertions with all SQLite allocations freed. A focused memdebug probe
covering DEFAULT, CHECK, and `RETURNING *` also closes with `SQLITE_OK` and
zero live allocations.

The `update-21.12` query plan was missing the correlated-subquery EXPLAIN
parent and the FROM-subquery co-routine parents. `sqlite3CodeSubselect` now
emits the scalar-subquery and reused-subquery rows, and SELECT subquery setup
labels co-routines and materializations with SQLite's internal source-item
formatter. SELECT planning now initializes and refines `nSelectRow` from the
WHERE output estimate. This restores the expected CTE/window plan hierarchy,
automatic covering index, and Bloom filter. Unchanged `update.test` now passes
136/136 assertions with all allocations freed. The unchanged `analyze.test`
passes 2/2. The unchanged `where.test` file now passes all 322 assertions in a
math-enabled `SQLITE_TEST` build, with all SQLite allocations freed. In the
default profile, the only failure is `where-30.1`, which needs the optional
`log()` math function. Its
`where-5.1` through `where-5.15` counter checks pass after the VDBE `OP_Prev`
and `OP_SorterNext` success paths were aligned with upstream's `SQLITE_TEST`
search counter. `where-6.1` and all `where-6.9` cases now pass. `ANALYZE`
previously reported `SQLITE_NOMEM` because `analyzeOneTable` reserved only the
first saved index-prefix register; reserving the full prefix and trailing
rowid slot keeps analyzer registers out of the VDBE cursor cells. The ORDER BY
cases also depended on `sqlite3ExprCollSeq` resolving an implicit column
collation to the database default. The port now does that lookup, matching
upstream's `BINARY` fallback. The two `where-27` overflow cases now pass after
`compare2pow63` was changed to index the boundary as bytes, preserving the
`INT64_MAX` literal as an integer. The former `where-14` order failures came
from `sqlite3AffinityType` omitting the declared-column size estimate used by
covering-index planning. The port now records `Column.szEst`; the planner sees
that the automatic index is smaller than the table and selects its expected
covering scan. A C2FB pass over `where.c` emitted 91 candidate procedures,
including the upstream automatic-index loop branch already present in the
integrated planner. A preprocessed C2FB `include-existing` pass over
`build.c` emitted 127 candidates, including a `sqlite3AffinityType` candidate
that compiles in isolation. This gap was in the existing handwritten body, so
no C2FB source change was needed.

A separate `SQLITE_ENABLE_MATH_FUNCTIONS` test build registers `log()` and runs
the full `where.test` file. The SELECT path caps grouped-query output at 100
rows (`sqlite3LogEst(100) = 66`) before publishing the estimate to later CTE
uses. This matches SQLite's aggregate estimate and lets the planner choose the
automatic indexes in `where-30.1`; all 322 assertions now pass, with all
tracked allocations freed.

The simple aggregate SELECT path now uses SQLite's `WHERE_ORDERBY_MIN` and
`WHERE_ORDERBY_MAX` flags and emits the corresponding early-out after the
aggregate update. Scalar `min()` and `max()` pass the selected function
collation into `sqlite3MemCompare`. Together, these changes make the unchanged
`collate4.test` pass all 109 assertions.

VACUUM now accepts `OP_Vacuum P2=0`, which means no output filename register.
The `OP_IdxInsert` path also accepts a NULL register when `OPFLAG_PREFORMAT`
marks a preceding `OP_RowCell` copy. `OP_AutoCommit` now follows SQLite's
active-writer check for COMMIT and allows the nested `BEGIN` used by VACUUM.
The unchanged `vacuum.test` passes 2/2, and `collateB.test` passes 16/16; both
finish with all tracked allocations freed.

The earlier `where-6.7.2` fixed-LIMIT plan mismatch is resolved. The table-
backed SELECT path now passes the bounded LIMIT estimate and `SF_FixedLimit`
into `sqlite3WhereBegin`, along with its ORDER BY LIMIT sorter label. The
unchanged `where.test` through `whereN.test` run passes 3,044 cases in the
current SQLITE_TEST profile; broader LIMIT costing parity remains unverified.

The unchanged `select1.test` through `select9.test` and `selectA.test` through
`selectC.test` pass 37,749 assertions. `select1`, `select4`, and `selectA`
retain 304, 576, and 288 bytes respectively; the other files free all tracked
allocations. Schema loading now uses `db->init.busy` while resolving column
collations, so an unavailable collation remains attached to its table until a
query needs it. The unchanged `collate3.test` passes 73/73. The unchanged
`collate2`, `collate4`, `collate5`, `collate6`, `collate7`, `collate8`,
`collate9`, and `collateA` suites also pass. The temporary Tcl bridge provides
the upstream test-only `sqlite3_create_collation_v2` and
`sqlite_delete_collation` commands needed by `collate7`. It still stops
`collate1` at the unavailable `do_faultsim_test` helper.

After the final cursor-state fix, the default `SQLITE_TEST` rerun of the 12 SELECT suites, `collate2.test` through `collateB.test`, and `vacuum.test` reported zero SQLite test errors across 38,223 cases. `select1`, `select4`, and `selectA` still leave 304, 576, and 288 bytes respectively, so the test harness exits nonzero for those three suites despite zero test errors.

The C callback probe also found `sqlite3_exec()` returning an extended error code while extended-code mode was disabled. The wrapper now applies `sqlite3ApiExit()` before returning, matching the configured error mask; forward and reverse probes match SQLite in both modes: primary code `SQLITE_ABORT` by default and extended code `SQLITE_ABORT_ROLLBACK` when extended-code mode is enabled, with the same rollback error message.

The unchanged `trans3.test` passes all 10 tests, `rollback2.test` passes 139, and `savepoint4.test` plus `savepoint5.test` pass 7 combined. The transaction run exposed that `sqlite3BtreeNext` and `sqlite3BtreePrevious` treated a tripped `CURSOR_FAULT` as end-of-file. Both wrappers now restore every non-valid cursor state before stepping, so the stored `SQLITE_ABORT_ROLLBACK` reaches the caller. Forward and reverse index-scan C callback probes now return “abort due to ROLLBACK”; the passing test runs free all tracked allocations.

The default release, default `SQLITE_TEST`, math-enabled `SQLITE_TEST`, and
`SQLITE_ENABLE_STMT_SCANSTATUS` library builds pass with the current ANALYZE,
collation, numeric, SELECT, VDBE, and EXPLAIN changes. In the math-enabled
profile, the selected where, SELECT, collation, and VACUUM suites pass 38,281
assertions with zero failures. The three noted SELECT suites retain small
allocations at test finalization. The SQLite test files remain unchanged; runs
use the temporary Tcl bridge described above.

Grouped aggregate output now reuses the saved GROUP BY key when the result
column is named by a GROUP BY ordinal. This avoids reevaluating volatile
expressions such as `random()` for the output row. When GROUP BY and ORDER BY
lists compare equal, the existing group sorter also supplies the requested
order, so the SELECT path does not open a redundant second sorter. The
unchanged `distinct2.test` now reports zero errors across 51 tests, including
`distinct2-5030`; its harness still reports 864 bytes in 12 allocations at
shutdown, matching the earlier failing run. The direct C probe returns
`0 1 2 3 4` for both the deterministic and random grouped queries.

After this SELECT change, the unchanged `select1.test` through `selectC.test`
pass all 37,749 assertions. `select1`, `select4`, and `selectA` retain their
known 304, 576, and 288 byte shutdown allocations. Release, `SQLITE_TEST`,
math-enabled, and statement-scanstatus library profiles all build. No C2FB
change was needed: the required `sqlite3ExprToRegister` routine was already
ported, and this defect was in grouped-query integration rather than a missing
converter translation. Source-body coverage remains 64.8% of the indexed
in-scope engine and public API code.

Aggregate DISTINCT planning now passes the aggregate argument and, for grouped
queries, the GROUP BY keys to the WHERE planner. The aggregate bytecode follows
the planner's `UNIQUE` or `ORDERED` result and removes the unused ephemeral
table open, including both reset sites in the grouped path. The unchanged
`distinctagg.test` now passes 72/72 assertions with all tracked allocations
freed; its tests confirm both the index-based temporary-table eliminations and
the result values. The unchanged `select1.test` through `selectC.test` still
pass all 37,749 assertions, and `distinct2.test` passes all 51 assertions.
Their previously recorded shutdown allocations remain in `select1`,
`select4`, `selectA`, and `distinct2`. Release, `SQLITE_TEST`, math-enabled,
and statement-scanstatus profiles all build after the planner integration.
The existing C2FB-generated WHERE planner and helper bodies provide the
`WHERE_DISTINCT_*` result; SELECT now connects that result to aggregate
bytecode generation.

The unchanged PRAGMA suites run against the port. Pager opening and page-size
changes advance the pager data version through `pager_reset()`, and
`sqlite3PagerSharedLock()` calls the same reset when the on-disk file version
changes. Current test-profile checkpoints pass `pragma.test` 127/127,
`pragma2.test` 1/1, `pragma3.test` 24/24, `pragma4.test` 108/108,
`pragma5.test` 6/6, and `pragma6.test` 4/4, with no tracked leaks. `pragma3`
includes its separate-process data-version case; the temporary runner loads
SQLite in that child while leaving the upstream test file unchanged.

The integrity walker initializes page headers without pre-validating every
cell so it can report malformed cell layouts. Normal B-tree page loading now
matches SQLite's `cell_size_check` setting: per-cell size checks run only when
that flag is enabled. PRAGMA row-level checks still execute after a diagnostic,
which preserves the later cursor errors expected for a damaged tree. The test
bridge supplies child-process, statement-introspection, and hex-database
helpers; the upstream Tcl files are unchanged. Release, `SQLITE_TEST`,
math-enabled, and statement-scanstatus profiles build with these pager and
PRAGMA changes.

Ordinary `SELECT DISTINCT` now supplies `WHERE_WANT_DISTINCT` to the planner
and uses its UNIQUE or ORDERED result. Matching DISTINCT and ORDER BY lists
share the grouped query path, and a source-less SELECT accepts DISTINCT for
its single implicit row. The skip-ahead optimization in the translated
`sqlite3WhereEnd` path now stays off for LEFT JOIN levels; this avoids seeking
past a NULL-extended row after ANALYZE. The unchanged `distinct.test` passes
88/88 with no tracked leaks. `distinct2.test` passes 51/51 assertions, with
its earlier 864-byte shutdown allocation still reported. `distinctagg.test`
passes 72/72, and `select1.test` through `selectC.test` pass 37,749 assertions.
Release, `SQLITE_TEST`, math-enabled, and statement-scanstatus builds pass.
These fixes use existing converted planner routines; C2FB and FBC sources were
unchanged. Source-body coverage remains 64.8% of the indexed in-scope engine
and public API code.

A view regression exposed two VDBE integration defects. Ordinary statement failures were passing their SQLite error code to `sqlite3RollbackAll`, although B-tree rollback accepts `SQLITE_OK` for an ordinary abort and reserves `SQLITE_ABORT_ROLLBACK` for cursor faults. Failed statements now roll back their statement savepoint before closing it, and whole-transaction aborts use the ordinary rollback code. The grouped aggregate `ORDER BY ... LIMIT` path now opens an ephemeral B-tree for top-N trimming; unbounded sorting continues to use the sorter.

The unchanged `view.test` now passes 121/121, including `view-29.0/.1` and grouped aggregate cases `view-9.2` through `view-9.6`. `trans3.test` passes 10/10, `savepoint4.test` 2/2, and `savepoint5.test` 5/5. Release, `SQLITE_TEST`, math-enabled, and statement-scanstatus libraries build. The view suite still reports 7,504 bytes in 138 shutdown allocations. No missing routine caused these failures, so no C2FB change was needed.

Virtual-table planning and JSON path checks exposed three connected runtime
issues. The VDBE now resolves jump labels and the maximum
`OP_VFilter`/`OP_VUpdate` argument count before allocating its argument vector.
The translated `allocateIndexInfo` compares against `TABTYP_VTAB`, and JSON
`each` carries the selected root token through payload validation so a path
such as `$.items` walks the chosen array rather than treating its parent-object
label as the row. The unchanged `json101.test` passes all 283 test cases, and
all tracked allocations are freed at shutdown.

SQLite's printf regression also covered buffer growth and special values.
`%c` now retains the original UTF-8 codepoint when a precision larger than
the stack buffer requires reallocation. The float renderer receives
the zero-pad flag, which makes alternate-form infinity render as `9.0e+999`
(or its negative form) and zero-padded NaN render as `null`. A release-library
C ABI probe passes for a root-path `json_each` query, both infinity encodings,
a 1,000-deep JSON array built with `%.1000c`, and 500 repeated `%c` bytes.
The release library builds successfully.

The direct JSON virtual-table memory probe traced the remaining connection
allocations to a close-path gap: `sqlite3_close()` was not disconnecting cached
virtual tables or rolling back virtual-table transactions before its busy-state
check. The shared close path now performs both operations, matching SQLite's
close order. The direct `json_each` probe returns to zero tracked bytes and
allocations after close and shutdown; the unchanged `json101.test` also passes
283/283 with no tracked allocations remaining.

C2FB's SQLite body profile now maps all four public virtual-table planner
records. Its `__builtin_offsetof` translation handles a trailing flexible
pointer array represented by a one-element FreeBASIC placeholder, and its
regression compiles the candidate and compares offsets and allocation sizes
with C for several planner sizes. The extracted `allocateIndexInfo` candidate
compiles. The full C2FB suite passes: 10,745 C/FreeBASIC behavior comparisons
in both native and GCC modes, with 150 candidates accepted and 31 unsupported
functions rejected. Source-body coverage remains approximately 64.8% of the
indexed in-scope engine and public API code.

Recursive CTE code generation now accepts FIFO and queue destinations for
simple aggregate anchors and emits their completed rows through the shared
SELECT destination path. Safe subquery ORDER BY elision prevents recursive
queries from repeatedly evaluating an irrelevant ordered subquery. The
min/max aggregate callback now uses SQLite's skip-accumulator signal for NULL
and non-improving values, and `OP_AggStep` consumes that signal as a request to
preserve the existing accumulator. SELECT flattening also skips compound
terms, and parse errors stop later name resolution from replacing the original
diagnostic.

The source-less SELECT path now adds SQLite's `SCAN CONSTANT ROW` explanation
entry. Repeated unmodified view or derived-table aliases reuse their first
materialization with `OP_OpenDup`; the matching `isSelfJoinView()` body was
already available from C2FB in `sqlite3_bulk39_select.bas`, so this repair only
connected existing translated code to SELECT materialization.

With CTE and virtual-table support enabled in the temporary test bridge, the
unchanged `with2.test` passes 73/73 with no tracked leaks, `with3.test` passes
15/15, `with4.test` passes 8/8, and `with5.test` passes 19/19. The `with2`
bridge uses upstream `ext/misc/series.c`; its earlier no-module stub skipped
the virtual-table case. At this point,
`with1.test` passed 118/119; the later parser-semantic update recorded below
fixed the remaining `with1-26.0` diagnostic. The suite reported 576 bytes in
8 shutdown allocations. `view.test` passes 121/121 after self-join materialization
reuse, with its existing 7,504-byte shutdown allocation. `with3.test` leaves
304 bytes in 6 allocations. SQLite upstream test files remain unchanged.
Release and `SQLITE_TEST` library profiles build with these changes.

The function ledger currently has FreeBASIC bodies for all 3,243 in-scope
indexed definitions; 13 test/debug-only definitions are out of scope and 7
upstream definitions are disabled. The broader source-body coverage estimate
remains 64.8% because it includes source that is not represented by this
function ledger.

`sqlite3SelectCompileExpr()` now handles SQLite's planner-only
`likely()`/`unlikely()`/`likelihood()` wrappers by compiling the value argument
directly. It also delegates integer literals to the shared `codeInteger()`
path, fixing wide hexadecimal literals. `OP_AggFinal` now retrieves the error
text from the finalizer result without trying to stringify an already-text
value, preserving `SQLITE_ERROR` for `sum()` overflow. The SELECT emitter passes
`length()`, `typeof()`, and `octet_length()` flags through to `OP_Column`, whose
overflow path can skip payload pages when only record metadata is needed.

With the temporary C test adapter extended for the upstream Tcl APIs,
`func3.test` passes 37/37 with no tracked leaks. The unchanged `func.test`
executes all 15,030 cases with zero test errors; the harness reports 288 bytes
in 4 remaining SQLite allocations at shutdown. The later parser-semantic
update brings `with1.test` to 119/119 with no tracked leaks. No upstream test
source was changed.

The temporary C test adapter now includes the upstream test-only SQL functions
and Tcl commands needed to execute `func.test` without changing its source.
The unchanged `func4.test` passes 185/185 with no tracked leaks. No C2FB change
was needed for the SELECT expression repair: the shared C2FB `codeInteger()`
and inline-function paths were already available; the dedicated SELECT emitter
now connects to those behaviors and transfers metadata-only column hints to the
VDBE.

`sqlite3ExprCodeCopy()` now preserves the upstream null-expression path, which
lets omitted INSERT columns emit `OP_Null`. `sqlite3MayAbort()` now records the
abort flag on the top-level parse context, so trigger subprograms participate in
the parent statement journal. With the unchanged upstream trigger tests,
`trigger1.test`, `trigger3.test`, and `trigger4.test` pass 79/79, 25/25, and
25/25 with no tracked leaks. `trigger5.test` through `trigger9.test` also pass
3/3, 8/8, 12/12, 3/3, and 30/30 with no tracked leaks. `trigger2.test` passes
72/72 assertions but leaves 336 bytes in 10 allocations at shutdown. The
temporary Tcl bridge advertises trigger support, maps
`SQLITE_LIMIT_TRIGGER_STEPS`, and supplies the test-only `randstr()` function
needed by `trigger9.test`; no upstream test file was modified. C2FB needed no
change for these fixes: its generated expression switch already preserved the
null fallback, while the missing behavior was in the hand-maintained
expression-copy and parse-context helpers.

A loose preprocessed C2FB sweep covered all 80 engine C inputs with no
preprocessing failures and wrote isolated candidates under
`build/candidates-sweep/`. It translated 694 simple-function candidates and
skipped 2,465 unsupported or duplicate bodies. Candidate files remain review
artifacts rather than linked sources; those counts do not establish semantic
parity.

The sweep exposed an extension API table regeneration bug. The owner module
includes the table it generates, so C2FB had treated declarations in the old
table as independent bindings and omitted them from the replacement. The API
adapter now excludes the stable owner include while scanning declarations,
even when a profile-specific table is written to a separate build directory,
and recognizes public `Alias` bodies in the FreeBASIC source directory. This
includes the generated `sqlite3_keyword_*` APIs, which do not have ordinary C
function rows in the ledger. The default extension table now backs 268/279
slots; the remaining 11 are omitted by upstream deprecated or feature-gated
entries. Both release and `SQLITE_TEST` builds succeed. The unchanged
`keyword1.test` passes 118/118 with no tracked leaks, and a loaded C extension
calls `sqlite3_keyword_count()` through the generated API table and receives
147. At this earlier checkpoint, the unchanged `loadext.test` passed through
`loadext-4.4`; the first temporary bridge stopped at the test-only
`do_malloc_test` helper. A later runtime checkpoint below extends the coverage.

The C2FB regression suite passes 10,745 C/FreeBASIC behavior comparisons on
both native and GCC backends, accepts 150 candidates, and rejects 31 unsupported
functions. It now also checks that API body aliases survive repeated table
generation when the owner includes the stable table name and the generated
output is in a separate directory.

An include-existing conversion of `src/build.c` emitted 127 candidates. Its
`sqlite3CreateView()` body evaluates `sqlite3ExprListDup()` once and stores that
result for `pCheck`. The already integrated body came from an older conversion
and called the allocator twice. Updating the stored expression removed the
leaks in `altercol.test` groups 8, 12, and 19; the full 257-test file now passes
with no tracked allocations left at shutdown. The current converter already
produces the corrected code for this case.

The latest loose C2FB sweep covered all 80 engine C inputs and emitted 694
simple-function candidates. The function ledger already has FreeBASIC bodies
for all 3,243 in-scope definitions, so this sweep did not reveal a missing
indexed routine that a broad converter change could safely supply. The
remaining skips include unsupported type/layout cases and duplicate bodies;
they need targeted work with their owning subsystem. The 64.8% ratio above
measures indexed function-definition lines against all in-scope lines; it is
separate from the 100% function-row count and does not measure semantic parity.

The feature-enabled C2FB pass over `select.c` supplied the missing
`columnTypeImpl()` and `generateColumnTypes()` variants. With
`SQLITE_ENABLE_COLUMN_METADATA`, the SELECT path now copies database, table,
and origin names into result-column metadata. A feature-profile library build
and direct C smoke test pass for `SELECT a FROM t`, a view, a nested subquery,
and an expression result; the test also loads a C extension and confirms the
database/table/origin API slots are populated. The UTF-16 metadata functions
compile but were not exercised. The generated feature API table backed 274 of
279 slots; the default table was restored to 268 of 279. Default release and
`SQLITE_TEST` library profiles also build after the conditional SELECT changes.
The C smoke used the system SQLite 3.46.1 headers because this checkout lacks
the generated 3.54.0 `sqlite3.h`; it checks the stable extension API prefix,
but a same-version header remains a stronger ABI check.

The unchanged upstream `with1.test` now passes 119/119, and `altercol.test`
passes 257/257 after the parser changes; both finish with no tracked leaks.
The default release and `SQLITE_TEST` plus preupdate-hook builds succeed.
Its syntax diagnostic exposed drift in two hand-maintained parser actions:
`cmd ::= select` now follows `DBFLAG_EncodingFixed`/`sqlite3ReadSchema()` and
always deletes the temporary SELECT, while `cmdx ::= cmd` no longer turns the
existing parse result into a parser-action failure after `sqlite3FinishCoding()`.
The parser driver distinguishes a token syntax failure from a semantic-action
failure so the syntax diagnostic replaces an earlier name-resolution message,
matching the upstream `%syntax_error` action. No C2FB change was needed.

`join8.test` exposed a dispatch error in `sqlite3Analyze()`: an unqualified
object name was treated as a database name even when no attached schema matched.
The port now falls through to table/index lookup in that case, matching
`src/analyze.c`. This lets `ANALYZE sqlite_schema` create `sqlite_stat1`; the
unchanged `analyze.test` passes 42/42 and `join8.test` passes 107/107, including
the expected Bloom-filter query plan. Both finish with no tracked leaks. The
test bridge registers the upstream C series module; no upstream test source
was changed, and no C2FB update was needed.

The `bloom1.test` run found that the `expr IN ()` parser action had omitted
SQLite's empty-list, singleton-constant, singleton-subquery, and vector-list
paths. Restoring those reductions prevents an empty expression list from
reaching `sqlite3FindInIndex()` as a null list and preserves aggregate function
classification. The SELECT path now also emits the missing DISTINCT temporary
B-tree row in EXPLAIN QUERY PLAN. `bloom1.test` passes 29/29; `in.test` through
`in5.test` pass 128/128, 2001/2001, 38/38, 83/83, and 46/46 respectively, with
all tracked allocations freed.

The `in2.test` 2000-row stress loop exposed a divider-size check that used the
page-local B-tree cell parser on a buffer located in a sibling page or balance
scratch. The port now parses that cell against its known buffer length. The
unchanged `in2.test` passes 2001/2001 with no tracked leaks. The B-tree and
parser repairs were in hand-maintained paths; no C2FB change was needed.

The unchanged `index.test` exposed a parser stack-offset error in the `DROP
INDEX` action. It read the `INDEX` keyword token as the `IF EXISTS` flag, so
`DROP INDEX missing_name` could silently succeed. The action now reads the flag
from the correct RHS slot. The large BLOB workload in `index4.test` exposed a
second issue: index searches descended past exact keys stored in interior
separator cells. The B-tree search now leaves the cursor on an exact interior
match. `index.test` passes 101/101, `index2.test` 9/9, `index3.test` 12/12,
`index4.test` 10/10, and `btree01.test` 216/216, all with no tracked leaks. No
C2FB or compiler change was needed.


The partial-index cases in `index9.test` exposed a missing bound-variable
comparison in `sqlite3ExprCompare()`. The port now compares a bound `TK_VARIABLE`
with a literal when QPSG is disabled and marks the prepared VDBE for reprepare
when the binding changes. Unchanged `index9.test` passes 25/25, including the
64-bit integer boundary cases, and `indexA.test` passes 150/150; both finish
with no tracked leaks.

The B-tree follow-up also passes `btree02.test` (4/4) after the temporary test
bridge registered upstream's `eval` extension. The unchanged `in2.test` stress
file passes 2001/2001 again after the interior-index-cell search fix.

The unchanged `index8.test` exposed missing planner metadata for a literal
LIMIT. The SELECT path emitted the counter but left `nSelectRow` unconstrained
and omitted `SF_FixedLimit` when entering WHERE planning. It now passes the
bounded estimate and flag, and supplies the planner's ORDER BY LIMIT label to
the sorter context. This makes the non-covering `t1abd` case choose a table scan,
matching upstream. Removing a duplicate OFFSET check lets `selectInnerLoop`
apply OFFSET after DISTINCT filtering. `index8.test` passes 6/6, `limit.test`
124/124, `limit2.test` 26/26, `orderby8.test` 202/202, and `select1.test`
200/200, all with no tracked leaks.


The ORDER BY regression sweep now passes `orderby1.test` (66/66),
`orderby2.test` through `orderby7.test`, `orderby8.test` (202/202),
`orderby9.test`, `orderbyA.test` (100/100), and `orderbyB.test`, all with no
tracked leaks. The grouped aggregate path passes GROUP BY expressions and flags
to WHERE planning. It processes adjacent groups directly when the selected scan
provides group order, and uses the grouping sorter when it does not. A separate
ORDER BY sorter is emitted only when that scan or grouping order cannot satisfy
the requested order. This brings both result rows and EXPLAIN sort counts in
`orderbyA.test` into line with upstream. No C2FB or FBC change was required; the
SELECT and WHERE routine bodies were already present in FreeBASIC.


The VDBE numeric-affinity regression sweep caught a `MustBeInt` mismatch: text
values were numerically converted, but an already-REAL value such as `2.0` was
never promoted to an integer when it had no fractional part. `OP_MustBeInt` now
applies integer affinity after numeric parsing, matching upstream while still
rejecting `2.5`.

All 15 unchanged upstream window test files now pass 2,907 assertions with no
tracked SQLite allocation leaks. Temporary Tcl bridge helpers expose the
upstream window and aggregate test commands; no upstream test sources changed.
`window5.test` covers custom window callback registration and connection-close
cleanup. Its teardown case exposed a layout mismatch: the hand written function
registry treated `FuncDef.u` as a callback pointer, while SQLite stores a
reference-counted destructor record there. The registry now increments,
releases, and frees that record according to its reference count. A separate C
API probe verifies destructor callbacks run once on replacement and once on
connection close.

`windowE.test` exposed a precise-mode floating point mismatch in Kahan summation.
A reduced FreeBASIC testcase showed FBC reassociating floating point expressions
even with `-fpmode precise`. The compiler optimizer now preserves floating
point grouping in precise mode while retaining reassociation in fast mode. The
patched compiler passes its complete unit suite (1,617,124 assertions), and the
upstream `windowE.test` cases now return the expected large-integer moving
sums. A release C API probe confirms custom sliding callbacks return 1, 3, 5;
integral REAL `nth_value` offsets are accepted while fractional offsets still
raise the documented error.

The selected neighboring suites also pass after these shared changes:
`limit.test` (124/124), `limit2.test` (26/26), `index8.test` (6/6),
`orderbyA.test` (100/100), and `select1.test` (200/200), all without tracked
leaks. The upstream test files remain unchanged.

The unchanged printf suites now pass `printf.test` (1,437 cases) and
`printf2.test` (51 cases), and `cast.test` passes its 1 case. The C reference
`testfixture` passes the same `printf.test` with 1,439 cases. The temporary FB
Tcl bridge uses SQLite's status API and reports zero outstanding allocations
after each run. Its allocator-fault injection command was a no-op, so this
initial run did not verify the FB `printf` OOM-injection branch. A later test
bridge wraps the FreeBASIC SQLite allocator and covers those fault cases. The formatter fixes cover the
optional printf precision limit, SQLite's 32-bit width parsing, incomplete
format specifiers, pointer-case output, floating-point grouping, and lowercase
JSON control escapes. A release C API probe verifies oversized widths fail
before allocating large fields and that large fixed-format values use
SQLite's 16-significant-digit rounding.

The unchanged SELECT stress suites `select2.test` through `selectG.test` pass
37,586 cases, including all 36,717 cases in `select9.test`. The write-side
follow-up suites `insert.test` through `insert5.test`, `update.test` and
`update2.test`, and `delete.test` through `delete4.test` pass 494 cases with
zero tracked allocations remaining.
`update2.test` and `delete4.test` first exposed a malformed-record error in
`OP_NotFound`: the port allocated `nAllField` cells, while SQLite allocates
`nKeyField + 1` for a decoded index key. Matching that capacity rule resolves
the WITHOUT ROWID update and trigger-delete failures. The upstream test files
remain unchanged; temporary Tcl support links the port's VDBE counters and
registers upstream-only helper functions.

The unchanged `where.test` now passes 322/322 in a rebuilt math-enabled test
profile. This run exercises the final VDBE record-unpack fix as well as the
planner cases that call the optional `log()` function; SQLite memory status
returns to zero.


The VDBE GLOB regression exposed the P3/P5 behavior missing from `OP_String`.
The LIKE/GLOB prefix loop revisits its lower-bound literal once; upstream marks
that second value as a BLOB so the next text-index seek exits. The port now
applies the same type change. A temporary Tcl adapter provides `sqlite3_exec`
and advertises the build's default `like_match_blobs` capability. Unchanged
`like.test`, `like2.test`, `like3.test`, `where2.test` through `where9.test`,
and `whereA.test` through `whereC.test` pass 2,988 cases total with zero
tracked SQLite allocations remaining.
No routine was missing, so C2FB was unchanged.


The VDBE covering-index tests exposed a missing `OP_Column` path. When
`OP_DeferredSeek` supplies a `P4_INTARRAY` map, the requested table column can
be read from the current index record if that column is covered. The port now
uses that map instead of seeking the table. `whereD.test` passes 62/62, and the
unchanged `select1.test` through `selectG.test` pass 37,785 cases with zero
tracked SQLite allocations.

The expression-index sweep exposed a DDL name-context layout error.
`SqliteNestedNameContextUnion` was a sequential record, shifting `ncFlags` from
byte offset 40 to 64. Declaring it as a FreeBASIC `Union` restores the C layout.
The resolver now sees `NC_IdxExpr` and rejects nondeterministic functions and
subqueries. The unchanged `indexexpr1.test` passes 117/117, including its
`integrity_check` case.


The unchanged `pragma4.test` passes 108/108 with the temporary Tcl bridge
providing the statement column-count and SQLite log callbacks; tracked memory
returns to zero.


The SELECT constant-propagation helper is now connected after FROM-subquery
flattening. Its affinity guard follows SQLite's expression API:
`sqlite3ExprAffinity()` returns zero for an expression with no affinity, while
`SQLITE_AFF_NONE` is the separate tagged affinity value. The previous comparison
rejected all eligible constants, leaving the routine's translated body inert.
The unchanged `whereL.test` now passes 28/28, including the expected index order
and omitted ORDER BY sorter. `select1.test` through `selectH.test` pass 37,803
cases; `where.test` and `where2.test` through `whereN.test` pass 3,044 cases
with capability-appropriate adapters. Each run reports zero outstanding SQLite
allocations.

This issue did not expose a missing routine or a C2FB conversion limitation;
C2FB was left unchanged.

The unchanged upstream `pragma.test` passes 145/145 cases enabled by the
FreeBASIC Tcl adapter, including the schema-version cases. Its schema-cookie cases exposed
an API difference: a legacy `sqlite3_prepare()` statement must return
`SQLITE_ERROR` from `sqlite3_step()` after invalidation, while finalize retains
`SQLITE_SCHEMA`. The step wrapper now preserves that behavior and keeps
automatic reprepare for saved-SQL statements such as `sqlite3_prepare_v2()`.
Targeted C ABI probes confirm both paths. This was a statement API repair, not
a missing routine or a C2FB conversion limitation, so C2FB was unchanged.

The temporary Tcl bridge now dispatches `sqlite3_prepare` to the legacy C API
and `sqlite3_prepare_v2` to the saved-SQL API. This made the unchanged schema
tests usable against the port. They exposed two active-statement
mismatches: collation changes checked `nVdbeExec` instead of `nVdbeActive`, and
function replacement returned a generic busy message. Both paths now match
SQLite's active-VDBE guard and error text. `schema.test` passes 52/52,
`schema2.test` through `schema5.test` pass another 107 cases, and `schema6.test`
passes 21/21. The 180 schema cases and 145 pragma cases report no tracked
allocations remaining. The bridge uses the upstream Tcl test VFS and a temporary
`md5file` helper; test files remain unchanged.

The unchanged `alter.test` exposed a parser-action offset error in the vector
assignment rule `setlist ::= LP idlist RP EQ expr`. The FreeBASIC action read
RHS slot -2 (`RP`) instead of -3 (`idlist`), passing a pointer into the SQL
text to vector cleanup. The unchanged `alter-19.1` reproducer crashed in the
port but completed in the C ABI reference. Correcting the stack slot makes
`alter-19.1` through `alter-19.3` pass. C and FreeBASIC probes report the same
Lemon stack layout, so no compiler change was needed. The full `alter.test`
now passes all 118 cases enabled by the temporary adapter, with no tracked
leaks; the C reference passes all 123 cases. The adapter now provides the
upstream `sqlite3_exec`, test-control, and rename-test helpers. The upstream
test file remains unchanged.

The unchanged `altercons.test` exposed another hand-written Lemon action error:
rule 298 (`ALTER TABLE ... ALTER ... DROP NOT NULL`) has nine right-hand-side
symbols, but its FreeBASIC guard expected eight and rejected the reduction
before calling the already-ported ALTER routine. The guard now expects nine.
All explicit `rhsCount` checks match their Lemon productions after the fix.
`altercons.test` passes 189/189 and `altercons2.test` passes 70/70 through the
temporary Tcl adapter, with no tracked allocations remaining. The C reference
passes the same unchanged `altercons.test`. This was a parser-action count
error, so no C2FB or FBC change was needed.

The unchanged `alterdropcol.test` exposed a WITHOUT ROWID cursor-state mismatch
in the already-ported B-tree insert path. Upstream only saves the cursor for
later restoration if page balancing invalidated it. The FreeBASIC path forced
that restoration after every `BTREE_SAVEPOSITION` insert, so `OP_Next` could not
advance after rewriting a row. It now keeps the cursor on the replaced key
unless balancing moved it, and skips an unnecessary seek when the caller
already supplied the saved position. `alterdropcol.test` passes all 101 cases
enabled by the adapter; the C reference passes all 103. Both runs report no
tracked allocations remaining. This was a B-tree behavior repair, not a missing
function body, so C2FB and FBC remain unchanged.

The WITHOUT ROWID suite then exposed missing error-mask handling in the public
`sqlite3_reset()` and `sqlite3_finalize()` wrappers. Both now keep the extended
error in connection state while returning the value masked by `db->errMask`,
matching `sqlite3ApiExit()`. A default-profile C ABI probe confirms primary
`SQLITE_CONSTRAINT` returns with extended result codes off and code 787 with
them on. The unchanged `without_rowid3.test` passes 1,198/1,198 enabled cases;
the C reference passes 1,198/1,198. The selected batch also passes
`without_rowid1.test` (83), `without_rowid2.test` (10),
`without_rowid4.test` (88), `without_rowid5.test` (33),
`without_rowid6.test` (22), and `without_rowid7.test` (22), along with
`altercons3.test` (30) and `alterdropcol2.test` (24). These 1,510 cases report
no tracked allocations remaining. The temporary Tcl bridge supplies the
upstream test-only commands and a schema-only echo virtual table; test sources
remain unchanged.

The foreign-key sweep exposed two more semantic mismatches. The parser now
stops as soon as semantic code sets a non-OK `Parse.rc`; it no longer parses
later statements and replaces an earlier foreign-key mismatch with a syntax
error. The VDBE halt path now checks immediate and deferred foreign keys after
`OR FAIL` conflicts, so an FK violation overrides a later UNIQUE error and
rolls back the statement as SQLite does. The unchanged `fkey1.test` through
`fkey8.test` pass 1,441 cases enabled by the port profile, with no tracked
allocations remaining. The C reference passes 1,445; its four additional cases
require FTS5. The temporary Tcl bridge supplies the unchanged tests' prepare,
error-code, db-status, bind, column, trace, and statement-journal helpers.

The unchanged trigger suite passes 711 assertions across `trigger1.test`
through `trigger9.test`, `triggerA.test` through `triggerG.test`, and
`triggerupfrom.test`. Adding the trigger-depth and trigger-step limit names to
the temporary Tcl bridge and setting its default depth unblocked
`trigger1.test` and `triggerC.test`. `triggerA.test` also runs, but its
`do_malloc_test` cases use the adapter's no-op allocator-failure hook and do
not provide out-of-memory coverage. The completed runs report no tracked
allocation leaks. The trigger failures were in test-adapter setup; no missing
routine required a C2FB change, and the upstream test files remain unchanged.

The follow-up CTE and view checks pass `with6.test` (30/30) in the
math-enabled test profile, `withM.test` (32/32), `view2.test` (5/5), and
`view3.test` (2/2), all with no tracked allocations remaining. `withM.test`
exposed a crash when a persistent `CANTOPEN` fault rejected a temporary B-tree
open during a recursive CTE. The failed pager had a null file-handle pointer,
but translated cleanup helpers assumed that pointer was always present. The
pager cleanup now checks the pointer before reading its I/O methods or
requesting device characteristics. A focused `CANTOPEN` fault case and the
full `withM.test` pass. Its OOM cases still use the adapter's no-op memory
failure hook, so they do not exercise allocation failures. `with6.test` uses
the optional math functions and the temporary runner's optimizer-control
adapter; no SQLite test source or C2FB code changed.

The 1 KiB `SQLITE_TEST` profile now matches the default page size used by
upstream `testfixture`. In that profile the unchanged `pager2.test` passes
2,003/2,003 enabled cases with no tracked leaks; the C reference passes
2,004/2,004, including one shared-cache case disabled in the port profile.
The savepoint stress cases exposed an incomplete main-journal rollback path:
it stopped at one journal segment instead of continuing across later journal
headers. `pagerPlaybackSavepoint()` now follows the upstream multi-segment
playback order and uses the existing page replay helper. Journal-mode OFF
rollback also follows SQLite's no-journal path, so the pager does not return
to reader state with a cache whose writes cannot be rolled back. A reduced
savepoint repro, the journal-off rollback case, and the full pager2 suite pass.
After this repair, `pager3.test` (13/13), `pager4.test` (12/12),
`jrnlmode.test` (98/98), and `jrnlmode2.test` (14/14) also pass with no
tracked leaks.

With the page-size-aligned profile and updated temporary bridge,
`trigger1.test` through `trigger9.test`, `triggerA.test` through
`triggerG.test`, and `triggerupfrom.test` still pass 711/711. The unchanged
`fkey1.test` through `fkey8.test` pass all 1,441 cases enabled by the profile,
with no tracked leaks; four additional C-reference cases require FTS5. The
statement-journal helper reads the flag from the FreeBASIC VDBE layout.
At this stage, `pager1.test` reached 1,382 assertions and reported 34 errors,
including missing test-only commands, unsupported I/O fault cases, and
pager/index mismatches. That run was superseded by the rollback repair below.
The large-sector case pager1-42.2 now passes after the FreeBASIC
pagerWriteLargeSector path was aligned with SQLite's sector journaling:
it skips the reserved lock page, journals and dirties each co-resident page,
and propagates the journal-sync requirement across the sector. A focused
large-sector update and integrity-check repro passes 5/5, and pager2.test
still passes 2,003/2,003; both runs report no tracked allocation leaks.
fkey8.test passes 38/38 with no tracked leaks. Default, 1 KiB test, and
math-enabled test libraries rebuild successfully. This was a repair to an
existing FreeBASIC body, so no C2FB or FBC change was needed.

The B-tree payload reader now preserves the byte offset within an overflow
page while it follows earlier pages in the chain. Before this repair, reading
a field that began on a later overflow page restarted that page at byte zero;
a 1,600-byte update could rotate the stored text. The same-table update and
two-column overflow repros now pass. The unchanged update.test (142/142) and
insert.test (77/77) pass, and all 45,001 randomized JSON invariant cases
pass. OP_Seek* also clears a deferred cursor position before each new seek,
as SQLite does; rowid-15.1 and rowid-15.2 now pass. The same overflow offset
repair also fixes pager1-31.1. The FB rowid.test run reaches 249 cases with
one remaining adapter limitation: rowid-12.4 expects a disk-full fault,
which this runner does not inject. Its C reference passes 249/249. The latest
pager1.test now passes all 1,382 cases; its cross-process and
same-process multi-client lock sections now pass after the rollback repair
below. pager1-19.1, pager1-31.1, pager1-32.1, pager1-33.1, pager1-42.2,
pager1-44.2, and pager1-44.3 also pass. The latest run reports no errors
and no tracked leaks.

The temporary Tcl bridge does not collect actual pager reference counts for
the `sqlite3_pager_refcounts` helper. `pager1.27.1` does not assert that
diagnostic list; its transaction and SQL cases still execute.

The unchanged backup suites now pass in the `SQLITE_DEBUG`, 1 KiB page-size
test profile used to match upstream `testfixture`: `backup.test` passes
869/869 and `backup2.test` passes 16/16, with no tracked allocations left at
shutdown. Connection close now reports `SQLITE_BUSY` with SQLite's public
unfinished-statement/backup message while a backup retains a source B-tree.
The backup step also closes the temporary source read transaction in the
debug profile, following upstream's `TESTONLY` cleanup; this lets the
multi-connection writer cases run as they do under `testfixture`. Error
precedence for a detached destination remains intact. These were repairs to
existing FreeBASIC bodies, so no C2FB change was needed.

The pager1 multi-client tests exposed a rollback failure after an autocommit
write hit `SQLITE_BUSY`. `sqlite3PagerRollback()` first tried to synchronize
the journal through `pagerSyncJournal()`, which requires an exclusive lock.
When another connection still held a shared read lock, rollback stopped before
restoring the changed pages in the cache. The same connection then observed
rows from the failed update. The live rollback path now calls the existing
C2FB-translated `pager_playback()` through `pagerPlaybackBridge()`, matching
SQLite's journal replay path without that extra lock request. A reduced
two-connection repro now leaves the original rows intact, matching the C
reference. The unchanged `pager1.test` cross-process and same-process locking
sections pass. `pager2.test` (2,003/2,003), `pager3.test` (13/13),
`pager4.test` (12/12), `jrnlmode.test` (98/98), and `jrnlmode2.test` (14/14)
also pass with no tracked leaks. The backup regression set remains green:
`backup.test` (869/869), `backup2.test` (16/16), `backup4.test` (12/12),
`backup5.test` (20/20), `update.test` (142/142), and `insert.test` (77/77),
all with no tracked leaks. No C2FB or FBC change was required.

`pager1-19.1` exposed an auto-vacuum limitation in the B-tree transfer
optimization used by VACUUM. The port rejected preformatted overflow cells
for auto-vacuum databases, and its insertion path did not refresh the first
overflow page's pointer-map entry after the destination page was selected.
`sqlite3BtreeTransferRow()` now permits auto-vacuum allocation through the
pointer-map-aware allocator, and `sqlite3BtreeInsert()` records the first
overflow page against the final destination leaf as SQLite does. The unchanged
`pager1-19.1` passes. `vacuum.test` (41/41) and `vacuum6.test` (35/35) pass
in regular and `SQLITE_DEBUG` profiles. `vacuum2.test` (1/1),
`vacuum3.test` (110/110), `vacuum4.test` (2/2),
`autovacuum.test` (338/338), `incrvacuum2.test` (31/31), and
`incrvacuum3.test` (53/53) pass with no tracked leaks. The `vacuum5.test`
VFS-open-order check now passes 22/22 with no tracked leaks. The mismatch was
an eager open in transient pagers. The CTE's transient B-tree remains in
cache until it needs a spill, so PagerOpen now allocates an unopened file
handle and pagerOpentemp opens it only when disk backing is needed. The focused
CTE VFS trace matches the C reference. These repairs used existing pager and
B-tree bodies; no C2FB or FBC change was needed. After this pager change,
`backup.test` (869/869), `backup2.test` (16/16), `backup4.test` (12/12),
`backup5.test` (20/20), `update.test` (142/142), and `insert.test` (77/77)
still pass with no tracked leaks.

The unchanged `autovacuum2.test` passes 9/9 against the FreeBASIC library.
It verifies the callback's schema and page-count arguments, callback-selected
database shrink size, callback removal, and a zero-page result that disables
auto-vacuum. A temporary Tcl adapter mirrors the existing `test1.c` command;
the upstream test remains unchanged, and all tracked allocations are freed.
The ported `sqlite3_autovacuum_pages()` routine and B-tree callback path needed
no source changes for this test. No C2FB or FBC change was needed.

The `pager1-44.2` and `pager1-44.3` cases exposed an extra clamp in
`sqlite3PagerMaxPageCount()`. SQLite lets `OP_MaxPgcnt` set the limit using the
live B-tree page count, even when the pager's cached `dbSize` is larger during
an uncommitted auto-vacuum shrink. The pager's journal playback restores the
maximum from the original database size on rollback. Removing the `dbSize`
clamp matches that contract; both unchanged cases now pass, and the full
`pager1.test` failure count falls from 24 to 18, with no tracked leaks. No
C2FB or FBC change was needed.

`pager1-33.1` exposed a Unix VFS mismatch: `unixDelete()` ignored `ENOENT`,
allowing COMMIT to succeed after the rollback journal had been moved away.
It now returns `SQLITE_IOERR_DELETE_NOENT`, matching SQLite. The same suite
also found `pagerWriteDirtyPages()` truncating every committed database to
its logical page count, even when the VFS had preallocated more space. The
commit path now calls `pager_truncate()` after page writes only when the
logical image extends past the highest page written, and after journal
finalization only when written pages exceed the final image. The focused
diagnostic retains its 20 MiB file size after commit. `pager1-32.1` and
`pager1-33.1` pass, as do `pager2.test` (2,003/2,003), `vacuum.test` (41/41),
`vacuum3.test` (110/110), `vacuum6.test` (35/35), `autovacuum.test` (338/338),
and `incrvacuum3.test` (53/53), with no tracked leaks. The unchanged full
`pager1.test` now passes 1,382/1,382 with no tracked leaks.

The remaining pager1 cases found two more source-level differences. URI option
names and the `file:` scheme prefix were read through `ZString Ptr[index]`,
which does not index the C string bytes; the URI parser now uses byte-pointer
indexing. The four shared-memory and URI cases pass. Pager open also checks
that the resolved database path plus the eight-byte `-journal` suffix fits
`mxPathname`. Hot-journal recovery now checks the VFS output flags and returns
`SQLITE_CANTOPEN` if a read/write journal open falls back to read-only. These
fixes complete the 1,382-case pager1 run. No C2FB or FBC change was needed.


The unchanged URI suite exposed that Pager kept the database and sidecar paths
as separate allocations, dropping URI query options before the VFS xOpen call.
Pager now uses sqlite3_create_filename() to retain the four-byte database
prefix, URI key/value tail, journal path, and WAL path in one allocation, and
releases it with sqlite3_free_filename(). The temporary Tcl bridge adds the
existing sqlite3_open, sqlite3_errmsg, and sqlite3_errcode test helpers.
Upstream test files remain unchanged. uri.test passes 117/117 and
openv2.test 7/7 with no tracked leaks.


The SQLITE_DEBUG pager1 run caught an inverted guard in renameTokenCheckAll():
the translated assertion fired when mallocFailed was clear and no parser error
was present. Its condition now matches C, and both the focused pager1-18.5
case and full SQLITE_DEBUG pager1.test pass, with no tracked leaks.


The URI-00-error feature profile rejects `%00` escapes as SQLite specifies and
reports `ENABLE_URI_00_ERROR` through the compile-option API. The unchanged
uri2.test passes 22/22, and uri.test passes 99 cases with the strict profile
capability enabled. The regular profile's uri.test passes 117/117.


The unchanged attached-database suites `attach.test`, `attach2.test`,
`attach3.test`, and `attach4.test` pass 106, 70, 32, and 13 cases respectively
through the FreeBASIC `SQLITE_TEST` library, with no tracked allocation leaks.
The temporary Tcl adapter supplies the fixture's `sqlite3_db_filename`,
`SQLITE_LIMIT_ATTACHED`, and deprecated soft-heap-limit commands. This profile
reports that multithreaded tests are skipped. All 15 indexed functions in
`src/attach.c` already had FreeBASIC bodies, so this pass found no missing
routines and required no C2FB or FBC change. The upstream test files remain
unchanged.


The unchanged OOM-focused suites now also pass with no tracked allocation
leaks: `altermalloc.test` 4,109/4,109 (including the echo virtual-table case),
`alterfault.test` 3,109/3,109, `exprfault.test` 543/543, and
`schemafault.test` 86/86. The temporary echo adapter maps upstream numeric
connection pointers back to their Tcl database commands. The ATTACH suite's
shared-cache branch remains disabled in this fixture.

This coverage exposed three more OOM parity issues. `sqlite3OomFault()` now
disables lookaside, interrupts an active VDBE, and propagates the error through
outer parser contexts; the Lemon allocation-failure path calls it. This keeps
nested schema and ALTER failures as `SQLITE_NOMEM`. `sqlite3_exec()` now checks
the statement's OOM state when `sqlite3_column_text()` returns NULL, before
passing that value to a row callback as SQL NULL. Nested SQL now preserves the
nested error message so the outer Parse can report and free it.
`sqlite3SelectDup()` now attaches each copied source list to its owning Select
before later allocations, so OOM cleanup can use the full Select destructor.
This fixed the two qualified-name leaks in `schemafault.test`. Together, these
changes bring the schema, expression, ALTER, and ATTACH OOM suites to zero
failures and zero tracked leaks. The upstream test files remain unchanged; no
C2FB or FBC changes were needed.


The unchanged `attachmalloc.test` passes all 1,821 allocation-failure cases
enabled by this fixture, with no tracked leaks. Its shared-cache branch is
disabled here; the C reference fixture runs 3,041 cases including that branch.
The tests exposed two missed OOM paths in existing FreeBASIC bodies.
`sqlite3CreateIndex()` now checks the value returned by `sqlite3HashInsert()`:
the hash helper returns the uninserted index when its generic allocation fails,
without setting a connection's `mallocFailed` flag. `sqlite3SelectNew()` now
allocates its Select node before its child lists and releases the complete
source list when construction fails. The former issue caused the transient
failure at allocation 259 to be reported as success; the latter left qualified
schema names allocated during `ATTACH` schema loading. No missing routine or
C2FB/FBC change was needed, and the upstream test files remain unchanged.

The unchanged `wherefault.test` now passes 5,082 injected-allocation cases in
the FreeBASIC `SQLITE_TEST` build, with no tracked allocations at shutdown.
Failure injection found three more ownership errors in `sqlite3_select.bas`:
discarded ORDER BY lists remained attached when cleanup registration failed,
failed column-name copies leaked a partially built NATURAL JOIN USING list, and
failed comparison-expression allocation leaked the left side of that
comparison. Cleanup now takes ownership before registration, and local lists
and expressions are released on allocation failure. The temporary runner skips
multithreaded tests; the upstream test file is unchanged. These routines were
already implemented, so no C2FB change was needed.

The join regression sweep covered 3,228 cases across the unchanged `join`,
`join2` through `join9`, `joinA`, `joinB` through `joinF`, `joinH`, `joinI`,
and `joinD` scripts. All 3,228 assertions pass, and each run ends with no
tracked allocations. The SELECT path applies outer-join strength
reduction; both `join5-7.4` and `join5-7.2` now produce the reference plans.
The OR plan fix masks temporary opcode flags to SQLite's stored low byte in
`sqlite3PExpr()` and `sqlite3ExprAlloc()`. The parser driver now handles
Lemon's syntax-error flag before honoring `SQLITE_DONE`, so the invalid
lookahead after a completed statement reports `USING` without parsing the
remaining `(b);` tail as a new statement. `join3.test` passes 130/130 when the
temporary runner supplies SQLite's 64-bit `bitmask_size`; `join8.test` passes
106/106 with a temporary adapter that loads the upstream `series` extension.
The upstream test scripts remain unchanged.

After the expression-opcode fix, the unchanged `where.test` also passes 322/322
in the math-enabled `SQLITE_TEST` profile, and `wherefault.test` passes
5,082/5,082 with no tracked allocations. The non-math fixture reports one
missing `log()` function for `where-30.1`, so the math-enabled result is the
applicable WHERE-suite run. After the parser-driver change, `select1.test`
passes 199/199 and `select2.test` passes 21/21, both with no tracked leaks.
The unchanged INSERT, UPDATE, DELETE, and UPSERT suites (`insert.test` through
`insert5.test`, `update.test`, `update2.test`, `delete.test` through
`delete4.test`, and `upsert1.test` through `upsert5.test`) also pass 964/964,
with clean leak summaries. The temporary Tcl adapter routes the upstream
`ENABLE_QPSG` request through the connection's `config enable_qpsg` command;
all upstream test files remain unchanged.

Virtual-table interface checks using the unchanged upstream `qpvtab` module
pass `vtabdistinct.test` (5/5) and `vtabrhs1.test` (8/8), with no tracked
allocations. The echo-module runner now compiles upstream `src/test8.c` as a
test adapter, so the unchanged `vtab1.test` exercises SQLite's echo module.
The FreeBASIC fixture profile passes its 212 enabled cases with no tracked
leaks. The C `testfixture` baseline passes 223/223; its additional 11 cases
are guarded by `ifcapable fts3`, and FTS3 is not compiled into the FreeBASIC
test profile.

A C2FB audit found no missing routine behind the join failures. Both causes
were integration errors in existing FreeBASIC code: high opcode flags were
rejected by expression constructors, and the parser driver honored
`SQLITE_DONE` before reporting a syntax error on the lookahead. No C2FB or FBC
change was needed.

The unchanged `pragma.test` passes 127/127 after a pager-cache fix for small
file-backed TEMP databases. When phase one skipped writing a TEMP database
because fewer than 25% of its cache pages were dirty, phase two incorrectly
marked every cached page clean and discarded the only committed copy. The
FreeBASIC pager now uses SQLite's `pagerFlushOnCommit` condition in both commit
phases and keeps writable dirty pages cached when the backing file was not
flushed. That exposed a second parity issue: committed TEMP pages can need a
cache spill after the pager returns to reader state, so `pagerStress()` must
not reject those spills based on the pager state. A direct `cache_size=1`
reproduction now succeeds. The unchanged `tempdb.test`, `tempdb2.test`,
`temptable.test`, and `temptable2.test` suites pass 6/6, 8/8, 63/63, and
256/256 respectively. `pager1.test` passes 1,382/1,382, `pager3.test` passes
13/13, and `wherefault.test` passes 5,082/5,082. All these runs report no
tracked allocation leaks.

The backup cases in `temptable2.test` exposed one related classification
mismatch: SQLite's `sqlite3PagerIsMemdb()` includes file-backed TEMP pagers when
checking whether a backup may change page size. The FreeBASIC implementation
now matches that rule. The updated `SQLITE_TEST` library also passes
`pragma.test` 127/127, and the release library has been rebuilt after these
changes.
`tempfault.test` passes 6,381/6,381 cases through the temporary bridge with
VFS OOM injection enabled and no tracked allocation leaks. The unchanged C
`testfixture` baseline passes 16,419/16,419. The group 3 savepoint fault cases
now pass, including the deterministic `SQLITE_FULL` failure during
`ROLLBACK TO` that previously left duplicate references in the index tree.
The fault exposed a missing special-error branch in the existing
`sqlite3VdbeHalt` body: SQLite rolls back the statement when a `FULL` or
`NOMEM` error has a statement journal, and rolls back the full transaction
when no statement journal can restore consistency. The FreeBASIC halt path
now follows that decision for `FULL`, `NOMEM`, `IOERR`, and `INTERRUPT` errors.
The unchanged `sortfault.test` also passes 23,295/23,295 with no tracked leaks.
No C2FB or FBC changes were needed, and the upstream test scripts remain
unchanged.

The index-family sweep passes 776 assertions across `index.test` through
`index9.test`, `indexA.test`, `indexedby.test`, and `indexexpr1.test` through
`indexexpr3.test`, with no tracked allocation leaks. `index7.test` found a
cursor-restore bound error for WITHOUT ROWID records: the restore buffer was
set to the total payload field count instead of the key field count plus its
tie-break field. `indexexpr2.test` found a grouped scalar subquery whose LIMIT
exit label also ran on normal scan completion; the final group is now emitted
before that exit path. After the repair, `select1.test` through `select4.test`
pass 435/435, `aggnested.test` 48/48, and `aggorderby.test` 30/30. `index6`
and `index7` use the unchanged upstream
wholenumber extension, `indexexpr2` uses the unchanged explain extension, and
`index9` uses the test bridge's QPSG adapter. No upstream test files changed.

The unchanged backup API suites also pass: `backup.test` 869/869 and
`backup2.test` 16/16 under `SQLITE_DEBUG` (matching the C test fixture's
debug-only source-transaction cleanup), `backup4.test` 12/12,
`backup5.test` 20/20, `backup_malloc.test` 62/62, and `backup_ioerr.test`
52/52. The pragma follow-up suites pass `pragma2.test` 1/1, `pragma3.test`
24/24, `pragma4.test` 108/108, and `pragma5.test` 6/6. The temporary
`pragma3` runner loads the FreeBASIC-backed Tcl extension in its child process;
the upstream test contents remain unchanged. These runs end with no tracked
allocation leaks.

The next planner sweep passed 3,009 assertions across automatic-index,
quick-check, WHERE, skip-scan, ORDER BY, transitive-constraint, and covering
index tests. This includes `autoindex2.test` through `autoindex5.test`,
`where2.test` through `whereN.test`, `wherelimit.test` through
`wherelimit3.test`, `skipscan1.test`, `orderby1.test`, `orderby2.test`,
`transitive1.test`, `coveridxscan.test`, and `quickcheck.test`. The temporary
test runners match the C fixture's `like_match_blobs` setting and expose its
optimizer controls. A direct release C-API probe also confirms that
`SQLITE_CONFIG_COVERING_INDEX_SCAN` changes the scan order after shutdown and
reinitialization. The upstream tests remain unchanged, and these runs end
without tracked allocations.

The unchanged `IN` operator suites pass 2,363/2,363 across `in.test` through
`in7.test`, with no tracked allocations. `in6.test` exposed that the VDBE
treated `OP_IfNoHope` as a no-op, so composite-index `IN` probes did not stop
after a prior seek had established the needed key prefix. The VDBE now checks
the cursor's `seekHit` value before falling through to the normal NotFound
lookup. This was a behavior repair in the existing executor; no C2FB or FBC
change was needed.

After the index and aggregate changes, `btreefault.test` passes 124/124,
`indexfault.test` passes its active 1/1 case, and `wherefault.test` passes
5,082/5,082, all with no tracked allocation leaks.

Sorter coverage now includes `sort.test` 92/92, `sort2.test` 13/13,
`sort3.test` 7/7, `sort4.test` 11/11, and `sort5.test` 16/16, all leak-clean.
`sort4.test` used temporary harness adapters for its sorter verifier and worker
thread limit. `sort.test` exposed that the memjournal initializer rejected a
null static mutex after `SQLITE_CONFIG_SINGLETHREAD`, although runtime
single-thread mode makes one-time method-table initialization safe. The
FreeBASIC pager now follows the C behavior in this case. A `SQLITE_TEST`-only
heap-sentinel hook lets the unchanged sort test drive the same fake-heap state
as SQLite's test helper.

`sortfault.test` passes 23,295/23,295 assertions with no tracked allocation
leaks. It previously stopped because the port lacked the test-only VFS OOM
switch. The `sqlite3Os*` wrappers now reproduce upstream `DO_OS_MALLOC_TEST`
behavior at the same VFS dispatch boundaries, including the in-memory journal
exception and file-control exclusions. The unchanged Tcl test runs through a
temporary bridge that exposes the test switch and existing SQLite test
helpers. The sorter suite was rerun after the pager/B-tree rollback changes.


Shared-cache validation now covers the unchanged upstream `shared.test`
(207 enabled cases), `shared2.test` (13), `shared3.test` (16), `shared4.test`
(17), `shared6.test` (40), `shared7.test` (5), `shared8.test` (11),
`shared9.test` (17), `sharedlock.test` (13), `sharedA.test` (9), and
`sharedB.test` (102): 450 cases with no tracked leaks. Four optional
`shared.test` checks use the fixture-only
`sqlite3_shared_cache_report` command, and three `shared9.test` checks require
FTS3. The test runner directly links the FreeBASIC library and supplies the
shared-cache and UTF-16 fixture commands; parent and child processes receive
the same 64 KiB pending-byte setting.

These tests found three existing port defects. B-tree rollback now sets the
shared state back to `TRANS_READ` before ending the writer transaction, and
connection close checks only cursors owned by that handle. The Unix VFS now
registers `unix-none` with no-lock file methods. The VDBE abort path returns
`SQLITE_ERROR` while retaining the original error in `pVdbe->rc`; its
`OP_Transaction` busy path keeps the program counter for retry. The unchanged
`tempfault.test` passes 6,081 enabled cases and `sortfault.test` passes
23,295/23,295, both without tracked leaks. The full WAL suite still passes
1,843/1,843. Upstream test files were not changed.

The unchanged `shared_err.test` completes with 0 errors out of 6,569 reported
tests. Its I/O-fault phase passes 6,567 assertions through a temporary Tcl
bridge that calls the port's PRNG save/restore controls and links the I/O-fault
counters. The runner explicitly skips its 8 allocator-failure groups because
this profile has no allocation-failure hook; `finish_test` reports all tracked
allocations freed. A temporary adapter around unchanged `src/test_thread.c`
provides the real worker-thread path used by `sharedA.test` and `sharedB.test`;
both suites pass with no tracked leaks. `sharedA.test` steps a prepared
statement on a worker thread during another handle's rollback. Upstream test
files remain unchanged.

The unchanged `thread001.test` and `thread002.test` now pass 52/52 and 15/15
with no tracked leaks. Both run the upstream `src/test_thread.c` worker code;
`thread001` covers same-handle, separate-handle, and shared-cache writers, while
`thread002` overlaps transactions across three attached databases. These runs
found that VDBE execution was not holding the shared B-tree mutex while it read
cursor pages. The executor now acquires/releases VDBE-declared B-tree locks for
each execution slice and during halt cleanup. `sqlite3BtreeEnterAll()` and
`sqlite3BtreeLeaveAll()` now cover every shared attached database, and the
aggregate SELECT compiler no longer marks `mayAbort` without an abort-capable
VDBE opcode. Release `thread001`/`thread002` and debug `thread001`/`thread002`
all pass.

After these source changes, the ordinary release target
`build/libsqlite3-fb.so` rebuilt successfully and reports up to date.

The source-line tracker remains at 124,545 of 192,194 in-scope upstream lines
(64.8%); all 3,243 in-scope indexed function entries have FreeBASIC bodies.
This is body coverage, not full behavioral parity. No C2FB change was needed:
the failures came from missing lock integration and one extra error-analysis
call, not missing indexed SQLite routine bodies. The allocator-failure groups
in `shared_err.test` remain unavailable in this profile.

## Authorizer and TEMP authorization checkpoint (2026-10-16)

The unchanged `auth.test`, `auth2.test`, and `auth3.test` pass 343, 15, and 10
test cases with no tracked leaks. `temptable.test` passes 62/62. These runs
found that FreeBASIC represents a true comparison as -1, while the parser's
TEMP action must pass the C integer value 1 to `sqlite3StartTable`; the action
now stores exactly 0 or 1. SELECT compilation also emits SQLite's
`SQLITE_SELECT` authorization event, and unreferenced FROM terms receive the
empty-column `SQLITE_READ` event.

The FreeBASIC test library uses the same 1,024-byte default page size as the
C fixture, and its Tcl bridge forwards the fixture's 64 KiB pending-byte
setting. This matters when a database uses 8,192-byte pages: page 9 holds the
reserved lock byte and `PRAGMA page_count` reports 10, matching C. The
temporary runner also exposes the fixture's `sqlite3_backup`,
`atomic_batch_write`, and `test_error` support commands and sets `TEMP_STORE`
to the profile's value of 1.

With that fixture setup, the unchanged `temptable.test`, `temptable2.test`,
`tempdb.test`, `tempdb2.test`, `temptable3.test`, and `temptrigger.test` pass
62, 256, 6, 8, 3, and 1 test cases respectively, with no tracked leaks.
Upstream Tcl tests remain unchanged.

These fixes were in parser semantic values and SELECT integration. No C2FB or
FBC change was needed.

## JSON runtime checkpoint (2026-10-16)

The unchanged `json101.test` through `json109.test`, `json501.test`,
`json502.test`, and `jsonb01.test` pass 45,993 cases with no tracked leaks.
The temporary Tcl bridge supplies `strdup()` and loads the upstream C
`randomjson` test extension against the FreeBASIC library; JSON test files were
not modified.

## Virtual-table runtime checkpoint (2026-10-16)

The unchanged `vtab1.test` passes all 212 cases enabled in the FreeBASIC test
profile, with no tracked leaks. Its `vtab1-23.3.1` regression calls
`DROP TABLE` from an `eval()` callback while the outer statement still has an
`OP_VUpdate` pending. The nested drop clears the VTable's `pVtab`; SQLite
returns `SQLITE_LOCKED` when the outer VDBE reaches `OP_VUpdate`. The port
previously returned `SQLITE_READONLY` for the same state. The VDBE now returns
`SQLITE_LOCKED` when that wrapper has no virtual-table instance or module.

The C reference passes 223/223 cases. Its additional 11 FTS3-only cases are
disabled in the FreeBASIC profile. Both the test-profile and ordinary release
libraries rebuilt successfully after the fix. No C2FB or FBC change was
needed.

## Bit-vector runtime checkpoint (2026-10-16)

The unchanged `bitvec.test` passes 72/72 cases in both the FreeBASIC profile
and C `testfixture`, with no tracked leaks. The temporary Tcl bridge exposes
the upstream test2 command by calling the port's `SQLITE_TESTCTRL_BITVEC_TEST`;
it also installs a C-compatible allocator fault-simulation wrapper before
SQLite initializes. The run includes the upstream allocation-failure
iterations.

The first bit-vector run found mismatches in ordinary set and clear checks.
The reference comparison converted a FreeBASIC Boolean directly to
`SQLITE_C_INT`, producing -1 for true where the C `!= 0` expression produces
1. The reference check now stores 0 or 1 explicitly. No C2FB or FBC change
was needed.

## STAT4 and ANALYZE runtime checkpoint (2026-10-16)

The unchanged ANALYZE test family ran in a `SQLITE_ENABLE_STAT4` FreeBASIC
build with `SQLITE_MEMDEBUG`. Across `analyze.test`, `analyze3.test`,
`analyze4.test`, `analyze5.test`, `analyze6.test`, `analyze7.test`,
`analyze8.test`, `analyze9.test`, `analyzeC.test`, `analyzeD.test`,
`analyzeE.test`, `analyzeF.test`, `analyzeG.test`, and `analyzer1.test`,
all 563 cases passed, with all SQLite allocations freed. The `analyzeG-1.3.2`
join-order mismatch was caused by a missing STAT4 adjustment to the full-table
scan cost. The planner now reduces that cost when the table has STAT4 data,
matching `src/where.c`; the expected `t1`-then-`t2` scan order is restored.
WHERE output adjustment also reads the feature-dependent `TERM_HIGHTRUTH` flag.

The temporary test adapter implements `test_decode()` and `test_zeroblob()`
outside the repository; no upstream test source was changed. The runs found
missing STAT4 probe cleanup between index candidates, a missing restore of the
planner's valid equality-prefix count after each constraint candidate, an
uninitialized output pointer when STAT4 cannot evaluate a function argument,
and a range estimate that read a bound probe as the equality prefix. Those
paths are now repaired.

The prior `analyze.test` checkpoint already counted 42 cases. This family adds
521 distinct passing cases, bringing the focused cumulative count to 72,001.
The later `capi3.test` through `capi3e.test` checkpoints add 764 distinct cases,
bringing the focused count to 72,765.
This remains a focused count, not a whole-suite total.

At that checkpoint, the focused checkpoints covered 72,765 passing upstream cases across
authorizer, TEMP, JSON, virtual-table, bit-vector, DBPAGE, PRAGMA, VDBE sorter,
PCACHE, DBSTAT, DBSTATUS, memory-database, scanstatus, WAL, window, VALUES,
cache-flush, core DDL, collation, concurrency, conflict, allocator
fault-injection, expression and descending indexes, query plans, STAT4/ANALYZE,
and public C API behavior. This is not a whole-suite count; the VTab profile omits 11
FTS3-only cases and several test profiles enable fewer cases than C
`testfixture`.

## B-tree and PRAGMA runtime checkpoint (2026-10-16)

The unchanged `dbpage.test` passes 34/34 cases in the DBPAGE-enabled test
profile. Its corruption checks require both the integrity-check diagnostic row
and the later `SQLITE_CORRUPT` from scanning the damaged tree. The port had an
extra PRAGMA branch that skipped those row-level scans after any diagnostic;
that non-upstream branch is removed. Ordinary page initialization now only
performs the extra cell-size scan when `cell_size_check` is enabled, matching
SQLite's B-tree behavior.

The unchanged `pragma6.test` passes 4/4 cases, including its generated-column
fixture, and `pragma4.test` passes 108/108 cases, including
`PRAGMA cell_size_check` and a 10,000-row integrity-check bytecode workload.
These runs found that `sqlite3_db_release_memory()` entered a fast B-tree
mutex directly while `PRAGMA shrink_memory` ran during statement preparation.
The port now enters all attached B-trees through `sqlite3BtreeEnterAll()` and
shrinks each database pager, matching upstream. All three test files pass with
no tracked leaks, and their C `testfixture` baselines pass.

The latest unchanged PRAGMA runs pass `pragma.test` 127/127, `pragma2.test`
1/1, `pragma3.test` 24/24, `pragma4.test` 108/108, `pragma5.test` 6/6, and
`pragma6.test` 4/4, with no tracked leaks. The temporary test bridge maps
`database_may_be_corrupt` to `SQLITE_TESTCTRL_NEVER_CORRUPT`; the separate
`pragma3.test` child process loads the FreeBASIC library. The upstream Tcl
scripts are unchanged.

B-tree index seeks now use the record-comparison specialization selected by
`sqlite3VdbeFindCompare()` for local cells and overflow payloads, and use the
same inclusive binary-search bounds as SQLite. Record comparison follows
SQLite's serial-type ordering for corrupt records, allowing an earlier type
mismatch to decide comparison without rejecting a damaged trailing field.
These paths are exercised by the corruption cases in `pragma.test` and
`dbpage.test`.

## VDBE sorter runtime checkpoint (2026-10-16)

The unchanged sorter suites pass: `sort.test` 92/92, `sort2.test` 13/13,
`sort3.test` 7/7, `sort4.test` 11/11, `sort5.test` 16/16, and
`sorterref.test` 5/5. These total 144 cases, with no tracked SQLite
allocations left at shutdown. The unchanged scripts exercise in-memory
sorting, stable order, PMA spills and merges, large records, sorter references,
fake-heap allocation, and PMA-size configuration. The temporary Tcl bridge
uses the port's `SQLITE_TEST` `sqlite3_test_set_sorter_fakeheap()` helper and
the existing `SQLITE_CONFIG_PMASZ` control. The generic test runner reports
that multithreaded permutations are skipped; the `sort4.test` worker-limit
setup and large sort cases still pass. No upstream test source changed.

## Page-cache runtime checkpoint (2026-10-16)

The unchanged `pcache2.test` passes 7/7 and `pcache.test` passes 17/17 in the
FreeBASIC profile and C `testfixture`, with no tracked allocations left at
shutdown. Together they cover fixed-size page-cache buffers, allocation
accounting, shared cache limits across connections, pinned pages, and
recycling. `pcache.test` requires `SQLITE_ENABLE_MEMORY_MANAGEMENT`; the test
profile matches `testfixture`'s 1 KiB default page size.

The temporary C/Tcl bridge matches the upstream `sqlite3_config_pagecache`
helper, including its negative-size and negative-page-count arguments. A
FreeBASIC `SQLITE_TEST`-only `sqlite3PcacheStats()` hook supplies the internal
shared-group counters used by the unchanged Tcl test. The upstream test files
remain unchanged. An initial run with the port's 4 KiB release default differed
from the test fixture's 1 KiB cache counts; rebuilding the test profile with
the matching page size made all cases agree.

## Memory-database VFS runtime checkpoint (2026-10-16)

The unchanged `memdb.test` passes 334/334, `memdb1.test` passes 57/57, and
`memdb2.test` passes 15/15 in the FreeBASIC profile, matching C `testfixture`
with no tracked allocations left at shutdown. These suites cover in-memory
rollback and auto-vacuum, serialize/deserialize including read-only and
maximum-size modes, and named memdb VFS locking across two connections. The
memdb tests use a 1 KiB test profile with deserialize enabled. The Tcl bridge
loads SQLite's upstream C `wholenumber` extension for `memdb.test`; the test
scripts remain unchanged.

## DBSTAT runtime checkpoint (2026-10-16)

The unchanged `stat.test` passes 41/41 in the DBSTAT-enabled FreeBASIC profile
and C `testfixture`, with no tracked allocations left at shutdown. The suite
checks page traversal, payload and unused-byte accounting, subtree queries,
aggregate mode, schema argument handling, and the eponymous and explicit
virtual-table forms. A temporary Tcl bridge maps the upstream
`register_dbstat_vtab` command to the port's `sqlite3DbstatRegister()` entry
point; the test file remains unchanged.

The unchanged `statfault.test` passes 684 enabled fault-injection cases in the
FreeBASIC profile with no tracked leaks. C `testfixture` runs 1,298 cases with
its broader allocator simulator; the remaining 614 fault cases are not covered
by the current FreeBASIC bridge.

## DBSTATUS and Unix file-layout checkpoint (2026-10-16)

The unchanged `dbstatus.test` passes 154/154 and `dbstatus2.test` passes 33/33
with no tracked allocations left at shutdown. The shared-cache
`CACHE_USED`/`CACHE_USED_SHARED` values now match the C test fixture.
`sqlite3PagerMemUsed()` sums the separate FreeBASIC allocations for the Pager,
PCache, database and journal file handles, and packed filename. Upstream C
counts those objects through one allocation measured from the Pager pointer.

The Unix VFS file record now stores its path through a pointer, matching the C
layout. Pager-owned filenames remain borrowed pointers; generated temporary or
normalized paths get SQLite-owned copies that are released on close. This
removes a 4 KiB inline path buffer from every Unix file handle. The unchanged
`temptable.test` passes 63/63, `tempfault.test` passes 6,171 enabled cases,
`stat.test` passes 41/41, and `statfault.test` passes 684 enabled cases, all
with no tracked leaks. The unchanged `shared.test` also passes 207/207 with no
tracked leaks after the file-handle layout change.

## Virtual-table API C ABI checkpoint (2026-10-16)

A temporary C module linked to the default FreeBASIC release library calls all
four `sqlite3_vtab_config()` options during `xConnect` and uses `xFindFunction`
to override a registered scalar for a virtual-table column. Its `xUpdate`
returns `SQLITE_CONSTRAINT`; `INSERT OR IGNORE` handles that result as expected.
The query returns the expected value and the connection closes cleanly.
The upstream `vtab2.test` adapter still lacks `register_schema_module`, and the
current `vtab1.test` bridge supplies only a reduced echo module, so those runs
do not provide full upstream-suite coverage.

## Process configuration C ABI checkpoint (2026-10-16)

A temporary C API smoke passes against both the default FreeBASIC release
library and the upstream C amalgamation. It checks allocator and PCACHE2
method-table round trips, default mutex callbacks before and after
initialization, the three mutex modes, URI-based in-memory open, memory and
lookaside settings, mmap and spill limits, PMA sizing, log callback dispatch,
page-cache header size before and after initialization, and rejection of
ordinary configuration changes after initialization. It does not add to the
upstream Tcl test-case tally.

## Per-connection configuration C ABI checkpoint (2026-10-16)

A temporary C API smoke passes against both the default FreeBASIC release
library and the upstream C amalgamation. It exercises every default-profile
flag option's set, clear, query, and result-pointer behavior, plus
FP_DIGITS bounds, LOOKASIDE setup, MAINDBNAME, DQS DDL/DML semantics and
prepared-statement expiration, foreign-key enforcement, and unknown-option
errors. The upstream regression scripts remain unchanged.

The unchanged `quote.test` passes 30/30 with no tracked allocations, matching
the C `testfixture`. It covers the DQS_DDL/DQS_DML behavior configured through
`sqlite3_db_config()`. The FreeBASIC Tcl adapter was extended only in `/tmp` to
map the test's DQS_DDL name to the public API; no upstream test file changed.

## Process memory status C ABI checkpoint (2026-10-16)

A temporary C API smoke passes against both the FreeBASIC release library and
the upstream C build. It checks allocation and free counter changes,
`sqlite3_memory_used()`, high-water output and reset, the 32-bit and 64-bit
status APIs, and invalid operation codes. The smoke is not an upstream test
case and does not change the tracked case tally.

The unchanged `memsubsys1.test` and `memsubsys2.test` pass 24/24 and 26/26
against both the FreeBASIC profile and C `testfixture`, with no tracked leaks.
They cover caller-supplied page-cache buffers, overflow accounting, memory
high-water resets, and disabling/re-enabling allocation statistics.

## Index seek and WAL fault-injection checkpoint (2026-10-17)

The unchanged `walfault.test` passes 5,238 cases on native FreeBASIC and 5,265
on GCC-backend FreeBASIC, with no failures or tracked allocations. The current
C `testfixture` passes 6,074 cases. Fault-simulation loop lengths differ by
backend, so I counted the 942 new case labels that pass on C, native, and GCC
and were absent from the earlier 4,273-case FreeBASIC run. Broader allocator
fault-index parity remains unverified.

The `walfault-10` failure came from stale cursor `CellInfo`. An overflow-key
comparison could cache metadata for one index cell, then the binary search
could select a different exact-match cell without clearing that cache. The
cursor then read the previous cell's payload size while extracting the rowid
from a NULL-key index entry. `sqlite3BtreeIndexMoveto()` now clears cached cell
metadata after setting the matched cell index. The unchanged `index.test`
passes 119/119, `index4.test` passes 11/11, and `pragma.test` passes 164/164
after the fix, all with no tracked leaks.

Implicit BINARY collation names in index construction now use the canonical
SQLite name pointer. This preserves the pointer identity used by SQLite's
integrity-check code and keeps the generated check plan aligned with upstream.
The upstream Tcl tests remain unchanged; no compiler change was needed.

## Aggregate error and allocation-fault checkpoint (2026-10-16)

The unchanged `aggerror.test` passes 7/7, covering errors raised by aggregate
step and finalize callbacks, including UTF-16 error text. The unchanged
`aggfault.test` passes 296/296 in the FreeBASIC `SQLITE_TEST` profile, with no
tracked allocations remaining. The C `testfixture` runs 390 cases; 94 OOM
iterations remain outside the current FreeBASIC allocator-simulation bridge.
A temporary Tcl adapter registers the upstream `x_count()` aggregate through
the public C API; no upstream test source was changed.

## Window allocation-fault cleanup checkpoint (2026-10-16)

The unchanged `windowfault.test` passes 6,176/6,176 cases in the FreeBASIC
profile and 5,601/5,601 in C `testfixture`, with no tracked allocations in
either run. The fault-injection counts differ because each build follows its
own allocation path. The original FreeBASIC run passed its assertions but left
3,648 bytes in 36 allocations after OOM failures while compiling a compound
VALUES query with a window aggregate. `sqlite3MultiValues()` now releases its
pending row expression list when VDBE creation or `SelectNew` fails, and frees
a partially allocated return `Select` on the corresponding early exit. The
unchanged `valuesfault.test` also passes 273/273; C `testfixture` passes
417/417. These fault-simulation counts differ between profiles. The upstream
Tcl scripts remain unchanged.

## INSERT allocation-fault checkpoint (2026-10-16)

The unchanged `insertfault.test` passes 48/48 in the FreeBASIC test profile,
with no tracked allocations remaining. C `testfixture` passes 88 fault
iterations. The unchanged `upsertfault.test` passes 114/114 with no tracked
leaks; C `testfixture` passes 190 fault iterations. The different counts
reflect each profile's allocation-failure sequence.

The unchanged `unionallfault.test` also passes 208/208 with no tracked leaks;
C `testfixture` passes 262 fault iterations. It exercises OOM cleanup through
nested UNION ALL subqueries.

## RETURNING allocation-fault checkpoint (2026-10-16)

The unchanged `returningfault.test` passes 5,180/5,180 in the FreeBASIC test
profile and 5,409/5,409 in C `testfixture`, with no tracked leaks. The
temporary test bridge supplies the one eponymous Tcl virtual table required by
the upstream script; its xConnect callback also queries `sqlite_schema`, as
the Tcl callback does. No upstream test file changed.

## UPDATE FROM allocation-fault checkpoint (2026-10-16)

The unchanged `upfromfault.test` passes 1,785/1,785 in the FreeBASIC test
profile and 2,029/2,029 in C `testfixture`, with no tracked allocations in
either run. The test exercises UPDATE FROM inside trigger and subquery paths.

## Row-value allocation-fault checkpoint (2026-10-16)

The unchanged `rowvaluefault.test` passes 1,420/1,420 in the FreeBASIC test
profile and 236/236 in C `testfixture`, with no tracked allocations in either
run. The profile-specific fault-injection loops cover row-value comparisons,
IN subqueries, and range predicates.

## Cache-flush allocation-fault checkpoint (2026-10-16)

The unchanged `cffault.test` passes 365/365 in the FreeBASIC test profile, with
no tracked allocations remaining. C `testfixture` passes 647 cases; its fault
simulator covers more allocation-failure iterations than the temporary
FreeBASIC bridge. No upstream test source changed.

The unchanged `cacheflush.test` exposed that the API only flushed the main
database. `sqlite3_db_cacheflush()` now enters all attached B-trees, flushes
each write transaction, and continues after `SQLITE_BUSY` so later attached
databases are still flushed, matching `src/main.c`. The test passes 43/43 in
both the FreeBASIC profile and C `testfixture`, with no tracked allocations.

An additional unchanged core batch passes 1,364/1,364 FreeBASIC cases across
`affinity2.test`, `affinity3.test`, `alter2.test`, `alterauth.test`,
`alterauth2.test`, `altertab2.test`, `altertab3.test`, `altertrig.test`,
`autoinc.test`, `autoindex3.test`, `autoindex4.test`, `busy.test`,
`busy2.test`, `cachespill.test`, `check.test`, `coalesce.test`,
`collate1.test`, `collate5.test`, `collate6.test`, `collate8.test`,
`collate9.test`, `collateA.test`, `colname.test`, `conflict.test`,
`conflict2.test`, `conflict3.test`, `conflict4.test`, `countofview.test`,
`default.test`, `delete2.test`, `descidx2.test`, `descidx3.test`, `eqp2.test`,
and `exec.test`. Each run reports no tracked allocations. The C reference passes
1,450 cases across the same files; its profile enables more cases in several
suites. The unchanged `createtab.test` also passes 64/64 in both profiles, with
no tracked allocations. Its 100,000-column rejection case initially timed out
because the temporary allocator bridge used a linear scan to find freed
allocations. A hash index and constant-time record unlinking in that test-only
bridge brought the complete suite run down to a few seconds; no SQLite code or
upstream test source changed for this performance fix.

The unchanged `errmsg.test` passes 12/12 in both the FreeBASIC profile and C
`testfixture`, with no tracked allocations. The VDBE now returns `SQLITE_ERROR`
from `sqlite3_step()` for legacy prepared statements while retaining the
extended constraint code for `sqlite3_finalize()`. V2 statements continue to
return the extended code and message immediately, as the upstream API requires.

The unchanged `capi2.test` passes 116/116 in both the FreeBASIC profile and C
`testfixture`, with no tracked allocations. The temporary Tcl bridge now
forwards the C test commands for column metadata, change counts, and legacy
prepare/error inspection to the port's public API. Statement rollback now
resets `sqlite3_changes()` to zero, and legacy prepared statements return the
generic step error while preserving the constraint code for finalize. No
upstream test or fixture source changed.

The unchanged `capi3.test` passes all 194 cases enabled in the FreeBASIC C API
profile, with no tracked allocations remaining. Its temporary Tcl C bridge
forwards upstream open, error, prepare, step, reset, finalize, binding, and
column-value helpers to the port's public C API. This covers legacy schema
invalidation, live-statement close behavior, result conversions, and active
VDBE transaction cases. The fault-simulation permutation and no-VFS block are
excluded because this profile does not install SQLite's allocator fault
simulator or unregister every VFS. The upstream test file remains unchanged.

The unchanged `capi3b.test`, `capi3c.test`, `capi3d.test`, and `capi3e.test`
pass 23, 228, 276, and 43 enabled cases respectively, with no tracked
allocations remaining. These cover heap-limit configuration, V2 statement
reprepare, statement-state APIs, and UTF-8 filenames used by ATTACH. The
unarmored profile skips the deliberate double-close misuse checks in
`capi3c.test`; allocator fault simulation and the no-VFS block are disabled in
these runs. UTF-16 cases are disabled in the filename and C API profiles. All
upstream test files remain unchanged.

The unchanged `close.test` passes 13/13 in both profiles, with no tracked
allocations. Temporary Tcl wrappers forward `sqlite3_close_v2()` and
incremental blob open/close calls to the FreeBASIC library; the upstream test
and C test support remain unchanged.

The unchanged `descidx1.test` passes 44/44 cases enabled in the FreeBASIC
profile; C `testfixture` passes 52/52. The temporary bridge now forwards
`SQLITE_TESTCTRL_IMPOSTER` to the FreeBASIC API, allowing the unchanged
expression-index corruption cases to run. `expridx1.test` passes 42/42 in both
profiles. `expridx2.test` passes 9/9 in both profiles after `OP_IdxDelete`
implements P3's byte-for-byte key comparison: when an UPDATE leaves an
expression-index entry unchanged, the opcode skips both its deletion and the
following insertion. All runs report no tracked allocations.

The unchanged `collate7.test` passes 9/9 in both profiles, including the
`sqlite3_create_collation_v2()` destructor callbacks. The temporary Tcl bridge
forwards that upstream test command through a case-insensitive C callback.
`existsexpr.test` passes 103/103 and `existsexpr2.test` passes 10/10 in both
profiles. `sqlite3SelectCompileFromClause()` now invokes the existing
EXISTS-to-join transformation after FROM-subquery flattening, as SQLite does,
so eligible correlated EXISTS expressions no longer remain scalar subqueries.

The unchanged `eqp.test` now passes all 65 enabled cases in the FreeBASIC
profile; C `testfixture` also passes 65/65. Moving the grouped DISTINCT plan
node after the source scan and GROUP BY nodes fixed the three remaining
assertions. The list-subquery and bloom-filter plan labels also match.

## Corruption regression checkpoint (2026-10-16)

The unchanged `corrupt2.test` through `corrupt9.test`, `corruptA.test`,
`corruptB.test`, and `corruptD.test` through `corruptG.test`
pass 420 enabled cases across the FreeBASIC test profile, with no tracked
allocations remaining. Case counts vary with database behavior and loop exits.
The unchanged `corruptC.test` passes all 101,707 enabled cases with no tracked
allocations. It exposed two failures: a zero-payload malformed schema record
was treated as an empty row, and the integrity checker lost a cell extent
before it could report a page overrun. Both paths are fixed. The VDBE now
rejects a missing payload pointer, while the integrity checker gets a bounded
cell-size recovery path for reporting out-of-page table leaf cells. No
upstream test source changed.

The focused cumulative ledger then recorded 174,892 passing upstream cases:
72,765 previously tallied cases, 420 corruption-suite cases, and the
101,707-case `corruptC.test` sweep. This is still not a whole-suite count.
The repository contains 1,196 Tcl `.test` files; enabled case totals depend on
build options and dynamic loops, and full-suite parity has not been measured.

## mmap-backed transfer checkpoint (2026-10-16)

The unchanged `mmapcorrupt.test` passes 4/4 in both the FreeBASIC mmap-enabled
profile and C `testfixture`, with no tracked FreeBASIC allocations remaining.
It exercises a 16 KiB page size, `PRAGMA mmap_size`, a damaged record, and an
`INSERT ... SELECT` into an empty WITHOUT ROWID table. The xfer path copies the
raw record without decoding its key when the destination tree is empty. The
B-tree cursor now checks that empty-root case before unpacking the record,
matching SQLite. Payload access can use a malformed cell's local payload only
when its in-page range is still valid. The unchanged `insert4.test` also passes
86/86 with no tracked leaks. The temporary Tcl bridge forwards
`sqlite3_config_lookaside` to the FreeBASIC library for the mmap test setup. No
upstream test source changed.

The focused cumulative ledger now records 174,896 passing upstream cases,
including the four `mmapcorrupt.test` cases. This remains a focused count;
full-suite parity has not been measured.

## Binding and range-predicate checkpoint (2026-10-16)

The unchanged `bind.test` passes all 119 cases enabled in the FreeBASIC test
profile with UTF-16 enabled, matching C `testfixture` at 119/119; neither run
has tracked allocations remaining. Binding coverage includes parameter naming
and indexing, 64-bit integers, doubles and NaN, NULL values, UTF-8 and UTF-16
text with embedded NULs, busy-statement and out-of-range errors, clearing
bindings, and multi-variable INSERTs. The temporary Tcl bridge forwards the
bind commands to the FreeBASIC API and registers the one test-only
`x_coalesce()` function; upstream tests are unchanged.
`sqlite3ExprAssignVarNumber()` reports the upstream variable number diagnostic
and offset, so `bind-9.1` and `bind-9.2` pass. The unchanged `bindxfer.test`
passes 9/9 in both profiles, including deprecated binding transfer, with no
tracked allocations.

The unchanged `between.test` passes 23/23 with no tracked allocations. The
unchanged `stmt.test` passes 15/15 with no tracked allocations. Its test
profile sets `TEMP_STORE=1` and reports that the Unix VFS does not support
atomic batch writes, matching the C reference setup. The focused cumulative
ledger now records 175,062 passing upstream cases, adding 119 binding cases,
9 binding-transfer cases, 23 BETWEEN cases, and 15 statement-journal cases to
the previous 174,896. This remains a focused count; the full suite has not
been measured.

## Bind-value and pre-update checkpoint (2026-10-16)

The unchanged `bind2.test` passes 4/4 in both the FreeBASIC profile and C
`testfixture`, with no tracked allocations remaining. It covers binding an
integer-real value read from a table and values obtained through pre-update
old/new callbacks. The temporary Tcl extension was rebuilt with
`SQLITE_ENABLE_PREUPDATE_HOOK` to expose the upstream `db preupdate hook`
command; the test file remains unchanged. The focused cumulative ledger now
records 175,066 passing upstream cases, adding these four cases to the previous
175,062. Full-suite parity remains unmeasured.

## Stale rollback-journal checkpoint (2026-10-16)

The unchanged `journal1.test` passes 3/3 in both the FreeBASIC test profile and
C `testfixture`, with no tracked allocations remaining. It preserves a journal
from a deleted database, installs that journal beside a newly created database
with the same name, and verifies that opening the replacement does not replay
the stale journal. The temporary runner reports no atomic-batch-write support,
matching the Unix reference environment. The focused cumulative ledger now
records 175,069 passing upstream cases, adding these three cases to the previous
175,066. Full-suite parity remains unmeasured.

## Transaction rollback checkpoint (2026-10-16)

The unchanged `rollback.test` passes 14/14 and `rollback2.test` passes 138/138
in both the FreeBASIC profile and C `testfixture`, with no tracked allocations
remaining. These exercise `ON CONFLICT ROLLBACK` while a SELECT statement is
active, rollback during a SELECT callback, and hot-journal recovery with a
missing master-journal file. The FreeBASIC test runner enables the conflict
capability and uses the 64 KiB pending-byte offset configured by this test
profile. The focused cumulative ledger now records 175,221 passing upstream
cases, adding the 14 and 138 cases to the previous 175,069. Full-suite parity
remains unmeasured.

## Test-VFS journal checkpoint (2026-10-16)

The unchanged `journal2.test` passes 24/24 and `journal3.test` passes 22/22 in
both the FreeBASIC profile and C `testfixture`, with no tracked allocations
remaining. These cover SAFE_DELETE journal lifecycle and journal-file
permissions. The temporary test runner loads SQLite's original C
`src/test_vfs.c` helper against the FreeBASIC VFS; neither upstream test source
was changed. The focused cumulative ledger now records 175,267 passing
upstream cases, adding the 24 and 22 cases to the previous 175,221. Full-suite
parity remains unmeasured.

## Pager fault and hot-journal recovery checkpoint (2026-10-16)

The unchanged `pagerfault.test` passes all 28,705 cases generated by the
FreeBASIC test profile, with zero errors and no tracked allocations remaining.
The unchanged `pagerfault3.test` passes 33/33, also with no tracked allocations
remaining. The C `testfixture` profiles passed 31,538 `pagerfault` cases and
31 `pagerfault3` cases. Totals differ because fault-injection loops enumerate
allocator and I/O calls, which vary by build. The upstream test sources are
unchanged.

The suite exposed and verified fixes for pager recovery from an unknown lock
state, page-size retry cleanup and allocation ordering, and VDBE P4 ownership
when opcode allocation fails. The focused cumulative ledger now records
204,005 passing upstream cases, adding the 28,705 `pagerfault` cases and 33
`pagerfault3` cases to the previous 175,267. Full-suite parity remains
unmeasured.

## Large-database pager OOM checkpoint (2026-10-16)

The unchanged `pagerfault2.test` passes 552/552 generated cases in the
FreeBASIC profile, with no errors or tracked allocations remaining. The C
`testfixture` profile passes 542 cases; the OOM loops stop at different
allocation counts in each build. These cases exercise rollback and savepoint
recovery while updating large databases. The focused cumulative ledger now
records 204,557 passing upstream cases, adding the 552 `pagerfault2` cases to
the previous 204,005. Full-suite parity remains unmeasured.

## Pager optimization checkpoint (2026-10-16)

The unchanged `pageropt.test` passes all 16 FreeBASIC-profile cases, with no
errors or tracked allocations remaining. The test-only pager exposes the
upstream counters for database-page reads, database-page writes, and journal
writes through the Tcl bridge, so the original cache and freelist optimization
assertions run unchanged. The C `testfixture` profile runs only one case
because its `direct_read` capability skips the counter-sensitive tests. The
focused cumulative ledger now records 204,573 passing upstream cases, adding
these 16 cases to the previous 204,557. Full-suite parity remains unmeasured.

## Page-cache sizing checkpoint (2026-10-16)

The unchanged `cache.test` passes all 190 cases in both the FreeBASIC and C
profiles, with no tracked allocations remaining. It exercises cache-size
limits, reads from a warm cache, spilling with a one-page cache, and flushing
with cache size zero. The FreeBASIC Tcl adapter maps the upstream pager stats
and mutex commands to the test-only pager snapshot. The cumulative ledger now
records 204,763 passing upstream cases, adding these 190 cases to 204,573.
Full-suite parity remains unmeasured.

The unchanged `cachespill.test` also passes 8/8 in both profiles with no
tracked allocations remaining. It verifies that `PRAGMA cache_spill` disables
and re-enables pager spill behavior. The cumulative ledger now records 204,771
passing upstream cases. Full-suite parity remains unmeasured.

## Unix synchronization checkpoint (2026-10-16)

The unchanged `sync.test` passes 5/5 and `sync2.test` passes 22/22 in both the
FreeBASIC and C profiles, with no tracked allocations remaining. The tests
verify synchronous modes across rollback journals, attached databases, and
WAL. The Unix VFS now counts directory fsyncs in `SQLITE_TEST` builds like
upstream's `full_fsync()` instrumentation; the filesystem sync behavior was
already present. The cumulative ledger now records 204,798 passing upstream
cases. Full-suite parity remains unmeasured.

## Disk-full recovery checkpoint (2026-10-16)

The unchanged `diskfull.test` passes all 745 cases in both the FreeBASIC and C
profiles, with no tracked allocations remaining. The suite injects `SQLITE_FULL`
during table and index writes, delete, and `VACUUM`, then checks database
integrity. The cumulative ledger now records 205,543 passing upstream cases,
adding these 745 cases to 204,798. Full-suite parity remains unmeasured.

## Crash recovery checkpoint (2026-10-17)

The unchanged `crash.test` passes all 882 cases against the FreeBASIC library,
with zero errors and no tracked allocations remaining. The temporary runner
loads SQLite's original C `test6.c` crash VFS helper and launches child
processes for the simulated crashes; the upstream test source is unchanged.
The single-threaded profile skips multithreaded tests. The focused cumulative
ledger now records 206,425 passing upstream cases, adding 882 cases to
205,543. The unchanged `crash2.test` also passes all 84 cases with zero errors
and no tracked leaks. It exercises crash recovery with database files whose
length is not a multiple of the simulated disk-block size. The focused ledger
now records 206,509 passing upstream cases. The unchanged `crash3.test` passes
all 992 cases with zero errors and no tracked leaks. It covers recovery with
atomic, sequential-write, and safe-append device characteristics. The focused
ledger now records 207,501 passing upstream cases. Full-suite parity remains
unmeasured. The unchanged `crash4.test` passes all 1,654 cases with zero
errors and no tracked leaks. It repeatedly increases the simulated crash delay
until the write sequence completes and verifies database integrity and state.
Its randomized delay loop makes the case count run-dependent. The focused ledger
now records 209,155 passing upstream cases. Full-suite parity remains
unmeasured. The unchanged `crash6.test` passes all 141 cases with zero errors
and no tracked leaks. It checks rollback recovery at page sizes from 1 KiB
through 8 KiB, including repeated large-database crash and reopen cycles. The
focused ledger now records 209,296 passing upstream cases. Full-suite parity
remains unmeasured. The unchanged `crash7.test` passes all 294 cases with zero
errors and no tracked leaks. It covers page-size-changing `VACUUM` interrupted
at both database and journal writes, followed by integrity checks. The focused
ledger now records 209,590 passing upstream cases. Full-suite parity remains
unmeasured. The unchanged `crash8.test` passes all 46 cases with zero errors
and no tracked leaks. It checks crash-induced cache recovery, rollback of
persistent journals, and rejection of journal headers with invalid sector or
page sizes. The focused ledger now records 209,636 passing upstream cases.
Full-suite parity remains unmeasured. The unchanged `crash9.test` passes all
2,402 cases with zero errors and no tracked leaks. It repeats 200 seeded
super-journal crash and integrity-check sequences for the journal checksum
regression. The focused ledger now records 212,038 passing upstream cases.
Full-suite parity remains unmeasured. To cover `crash5.test`, the test library
was rebuilt with `SQLITE_ENABLE_MEMORY_MANAGEMENT`; all 2,971 cases pass with
zero errors and no tracked leaks. The default test library was restored after
the profile run. The focused ledger now records 215,009 passing upstream
cases. The unchanged `crashM.test` then passed all 42 cases with
`SQLITE_ENABLE_8_3_NAMES`, loading SQLite's original C `test_multiplex.c` test
support as a temporary Tcl module. This also verified filename suffix
shortening with split database and journal files. The first run exposed an
8-byte leak because the temporary Tcl runner stubbed out
`sqlite3_reset_auto_extension`; the runner now calls SQLite's public cleanup
API, matching `finalize_testing`, and the rerun exits with no tracked leaks.
The default test library was restored. The focused ledger now records 215,051
passing upstream cases. Full-suite parity remains unmeasured.

## Multiplex VFS checkpoint (2026-10-17)

The unchanged `multiplex.test` passes all 1,313 cases generated by the
FreeBASIC test profile, with zero errors and no tracked leaks. The C
`testfixture` profile passes 2,024 cases; the OOM and I/O fault loops enumerate
different counts in the two builds. The test uses SQLite's original C
`test_multiplex.c` support as a temporary Tcl module. It exposed a Unix VFS
porting difference: the read-only fallback must not retry `open()` after
`EISDIR`, or a directory is accepted as a database file and later reported as
an I/O error. The FreeBASIC VFS now preserves `SQLITE_CANTOPEN`, matching
upstream. The test library passes the full multiplex suite, and the default
release library rebuilds successfully. The focused ledger now records 216,364
passing upstream cases. Full-suite parity remains unmeasured.

## 8.3-name filename checkpoint (2026-10-17)

The unchanged `8_3_names.test` passes all 20 cases with
`SQLITE_ENABLE_8_3_NAMES=1`, zero errors, and no tracked leaks. The feature
shortens rollback-journal and WAL names in the pager and shared-memory names in
the Unix VFS, using the original URI filename to check the `8_3_names` option.
The temporary Tcl runner loads SQLite's original `wholenumber` extension for
the WAL cases. The default test library was restored and the release library
rebuilds successfully. The focused ledger now records 216,384 passing upstream
cases. Full-suite parity remains unmeasured.

## Database file-format checkpoint (2026-10-17)

The unchanged `filefmt.test` passes all 42 cases in both the FreeBASIC profile
and C `testfixture`, with no tracked leaks. It caught an eager reserved-space
check in `sqlite3BtreeOpen`: upstream permits `sqlite3_open()` to succeed on a
file whose page header is malformed, then reports corruption when the schema
is read. The port now validates the reserved-space limit during page-one
initialization. The default release library rebuilds successfully. The
cumulative focused ledger now records 216,426 passing upstream cases.
Full-suite parity remains unmeasured.

## Unix VFS error logging checkpoint (2026-10-17)

The unchanged `oserror.test` passes all 12 cases generated by the FreeBASIC
profile, with zero errors and no tracked leaks. C `testfixture` passes 10 cases;
the file-descriptor exhaustion test adds cases only when the host reaches its
open-file limit. The runner loads SQLite's original C `test_syscall.c` helper.
The VFS now logs failed `open()` and `unlink()` operations in SQLite's expected
`os_unix.c:line: (errno)` format, and path-resolution failures use the same
format. The default release library rebuilds successfully. The focused ledger
now records 216,438 passing upstream cases. Full-suite parity remains
unmeasured. The unchanged `syscall.test` passes all 81 cases in both the
FreeBASIC profile and C `testfixture`, with no tracked leaks. The original C
`test_syscall.c` support drives the VFS system-call override table. These tests
exposed two more upstream differences: directory syncing after unlink must use
the retrying `openDirectory()` helper, and a one-byte file must be reported as
empty. The VFS and B-tree open paths now match those behaviors. The cumulative
focused ledger records 216,519 passing upstream cases. Full-suite parity
remains unmeasured. The unchanged `filectrl.test` passes all 7 cases in both
the FreeBASIC profile and C `testfixture`, with no tracked leaks. A temporary C
Tcl adapter exposes the file-control commands from `test1.c` through the
public API; the upstream test source remains unchanged. The focused ledger now
records 216,526 passing upstream cases. Full-suite parity remains unmeasured.

## Table-column metadata checkpoint (2026-10-17)

The unchanged `colmeta.test` passes all 52 cases in both the FreeBASIC profile
and C `testfixture`, with no tracked leaks. The temporary Tcl bridge calls the
FreeBASIC `sqlite3_table_column_metadata()` API and returns the same metadata
list shape as SQLite's `test1.c` helper. Coverage includes declared types,
collations, rowid aliases, WITHOUT ROWID primary keys, temporary schemas,
views, and missing tables or columns. The focused cumulative ledger now
records 216,578 passing upstream cases. Full-suite parity remains unmeasured.

## Public API feature-profile audit (2026-10-17)

The generated FreeBASIC declarations contain 306 public API aliases. The
default Linux release library exports 278; the absent APIs are controlled by
disabled optional features, CEROD (which has no implementation source in this
checkout), or the Windows-only VFS. A combined audit build enabling CARRAY,
column metadata, normalization, preupdate hooks, snapshots, statement scan
status, and unlock notification exports 302 of 306 aliases. The four absent
symbols are `sqlite3_activate_cerod` and the three `sqlite3_win32_set_directory`
variants. `ldd -r` reports no unresolved symbols for either build. The seven
enabled feature names are reported by `sqlite3_compileoption_used()` in the
audit build and are all absent in the default build.

An expanded audit of `sqlite3.h` finds 308 public function names. With column
metadata, normalization, snapshots, and statement scan-status enabled, the
Linux all-feature profile exports 304. The four absent names are the three
Win32 directory setters, which do not apply to Linux, and
`sqlite3_activate_cerod`, whose optional implementation is not present in the
upstream source tree.

The unchanged `carray01.test` passes 31/31 cases, `carray02.test` passes 19/19,
and `carrayfault.test` passes 254/254 in the FreeBASIC CARRAY test profile.
All three runs report zero errors and no tracked allocations remaining. The C
`testfixture` passes 31/31, 19/19, and 194/194 respectively; its OOM fault
loops enumerate fewer cases. A temporary Tcl bridge supplies the upstream
`sqlite3_carray_bind` and `bind_carray_intptr` test commands; upstream test
files remain unchanged. The focused cumulative ledger now records 216,882
passing upstream cases. Full-suite parity remains unmeasured.

## C API checkpoint (2026-10-17)

The unchanged `capi3.test` passes all 250 cases enabled by the FreeBASIC test
profile, with zero errors and no tracked allocations remaining. C `testfixture`
passes 249; the FreeBASIC runner includes one misuse case that the C fixture
profile skips. Coverage includes legacy and UTF-16 prepare/open calls, column
accessors, close with an outstanding statement, bind clearing, VFS sleep
behavior, and error propagation. A temporary Tcl adapter supplies missing
test commands while leaving the upstream test unchanged. This run adds 56
cases beyond the earlier 194-case C API checkpoint, bringing the focused
ledger to 216,938 passing upstream cases. A separate
`SQLITE_ENABLE_COLUMN_METADATA` profile passes all 286 `capi3.test` cases with
zero errors and no tracked allocations. Its 36 metadata-only cases exercise
the database, table, and origin name APIs in UTF-8 and UTF-16. This raises the
focused cumulative count to 216,974. Full-suite parity remains unmeasured.

## V2 prepare C API checkpoint (2026-10-17)

The unchanged `capi3c.test` passes 291/291 cases in the FreeBASIC profile and
291/291 in C `testfixture`, with zero errors and no tracked allocations. The
profile enables UTF-16, schema-pragma, deprecated-API, and progress-handler
cases. The upstream sanitizer guard skips the deliberate double-close misuse
probes in both runs. This adds 63 cases beyond the earlier 228-case
`capi3c.test` checkpoint, bringing the focused cumulative count to 217,037.
Full-suite parity remains unmeasured.

## C API statement-state checkpoint (2026-10-17)

The unchanged `capi3d.test` passes 282/282 cases against both the FreeBASIC
library and C `testfixture`, with no errors or tracked allocations. The Tcl
adapter now forwards `sqlite3_next_stmt()`, `sqlite3_stmt_readonly()`,
`sqlite3_stmt_isexplain()`, and `sqlite3_stmt_busy()` to the public API. This
adds six cases beyond the earlier 276-case checkpoint and brings the focused
cumulative count to 217,043. Full-suite parity remains unmeasured.

## C API UTF-8 filename checkpoint (2026-10-17)

The unchanged `capi3e.test` passes 115/115 cases against both the FreeBASIC
library and C `testfixture`, with zero errors or tracked allocations. It
covers UTF-8 and UTF-16 `sqlite3_open()` filenames and ATTACH/DETACH with
non-ASCII filenames. This adds 72 cases beyond the earlier 43-case checkpoint
and brings the focused cumulative count to 217,115. Full-suite parity remains
unmeasured.

## Blob literal and binding checkpoint (2026-10-17)

The unchanged `blob.test` passes 24/24 cases against both the FreeBASIC
library and C `testfixture`, with zero errors and no tracked allocations. The
tests cover blob-literal tokenization and diagnostics, stored and indexed blob
values, and binding a blob through the public API. The focused cumulative
ledger now records 217,139 passing upstream cases. Full-suite parity remains
unmeasured.

## Incremental blob checkpoint (2026-10-17)

The unchanged `incrblob3.test` passes 64/64 cases and `incrblob.test` passes
97/97 cases against both the FreeBASIC library and C `testfixture`, with no
errors or tracked leaks. The latter uses the 1 KiB default-page-size profile
used by the upstream test configuration. Temporary Tcl adapters expose the
public incremental-blob APIs while leaving the upstream test scripts unchanged.

The runs exposed and fixed three porting issues: the schema retry loop now
clears each attempt's return code, synthetic no-SQL VDBEs pass schema errors
back to the blob API that owns the retry, and blob payload access skips
auto-vacuum pointer-map pages. The pager read counter now also matches the
expected page-read statistics. The focused cumulative ledger records 217,300
passing upstream test cases. Full-suite parity and the full case denominator
remain unmeasured.

## Corrupt database checkpoint (2026-10-17)

The unchanged `corrupt.test` passes all 12,320 cases in the FreeBASIC test
profile, with zero errors and no tracked allocations remaining. C
`testfixture` passes 12,288 cases. Both use a 1 KiB default page size, and every
case ID produced by C also appears in the FreeBASIC run. This test derives its
256-byte corruption sweep length from the generated database file size, so the
FreeBASIC run exercised four additional chunks (32 assertions).

The suite corrupts database-file regions and checks that schema reads, table
scans, index scans, writes, and integrity checks return safely. The focused
cumulative ledger now records 229,620 passing FreeBASIC upstream test cases.
Full-suite parity and the full case denominator remain unmeasured.

## Virtual-table planner checkpoint (2026-10-17)

The unchanged `bestindex1.test` through `bestindex9.test` and `bestindexA.test`
through `bestindexG.test` pass all 1,377 cases against both the FreeBASIC
library and C `testfixture`, with zero errors and no tracked leaks. The same
case total passed in each profile. These suites cover xBestIndex constraints,
ORDER BY and DISTINCT modes, `IN`, LIMIT/OFFSET, and query plans over compound
subqueries.

The upstream C support module `src/test_bestindex.c` is compiled as a temporary
Tcl extension for the FreeBASIC runner; `ext/misc/series.c` supplies the
unchanged bestindexC extension case. The upstream test scripts remain unchanged.

The tests exposed and fixed two planner gaps. DISTINCT-to-GROUP-BY rewrites now
pass `WHERE_DISTINCTBY` to xBestIndex, and the sort-group mode uses normalized
0/1 values to match C arithmetic. FROM-subquery materialization now invokes the
existing predicate-pushdown helper while respecting the optimizer setting and
CTE reuse restrictions. The focused cumulative ledger records 230,997 passing
FreeBASIC upstream test cases. Full-suite parity and the full case denominator
remain unmeasured.

## SELECT subquery checkpoint (2026-10-17)

The unchanged `subquery.test` (82/82), `subquery2.test` (31/31), `select5.test`
(35/35), `select6.test` (88/88), `selectD.test` (32/32), `selectE.test`
(8/8), and `selectF.test` (3/3) pass against both the FreeBASIC library and C
`testfixture`, with zero errors and no tracked leaks. The tests exercise subquery
execution, compound SELECTs, and SELECT planner paths after predicate pushdown
was connected to FROM-subquery materialization. Upstream scripts are unchanged.

The focused cumulative ledger now records 231,276 passing FreeBASIC upstream
test cases. Full-suite parity and the full case denominator remain unmeasured.

## WHERE and index regression checkpoint (2026-10-17)

The unchanged `where3.test` through `where8.test`, `whereB.test`, and
`whereE.test` through `whereM.test`, plus `wherelfault.test` and
`wherelimit2.test`, pass 4,525 cases against both the FreeBASIC library and C
`testfixture`, with zero errors and no tracked leaks. The feature profile now
advertises the compiled engine's OR optimization, JSON functions, and
blob-compatible LIKE/GLOB behavior, so the upstream capability guards select
the same cases in both runs. These suites overlap earlier `where2` through
`whereN` and `wherelimit` sweeps; only `wherelfault.test` adds a previously
unrecorded case.

The unchanged `index5.test` passes 4/4 and `index6.test` passes 74/74 against
both builds, with no tracked leaks. They cover ordered B-tree index creation
and partial-index updates, including `ANALYZE` and integrity checks. These add
78 cases to the written ledger. The focused cumulative total is now 231,355
passing FreeBASIC upstream cases. Full-suite parity and the full case
denominator remain unmeasured.

## Large-row storage checkpoint (2026-10-17)

The unchanged `bigrow.test` passes 61/61 cases against both the FreeBASIC
library and C `testfixture`, with zero errors and no tracked leaks. It covers
large row payloads at the 256/257-byte and 65,536/65,537-byte record-size
transitions, indexed large columns, and updates across overflow pages. The
focused cumulative ledger now records 231,416 passing FreeBASIC upstream
test cases. Full-suite parity and the full case denominator remain unmeasured.

## Foreign-key allocation-fault checkpoint (2026-10-17)

The unchanged `fkey_malloc.test` passes 3,339 allocation-fault cases against
the FreeBASIC library and 4,497 against C `testfixture`, with zero errors and
no tracked leaks in either run. The fault simulator visits each build's own
allocation points, so its case totals differ. Coverage includes immediate and
deferred foreign-key checks, CASCADE, SET NULL, SET DEFAULT, invalid parent
keys, and dropping referenced tables. The upstream test is unchanged.

The focused cumulative ledger now records 234,755 passing FreeBASIC upstream
test cases. Full-suite parity and the full case denominator remain unmeasured.

## Cross-process WAL reader checkpoint (2026-10-17)

The unchanged `walshared.test` passes 6/6 and `external_reader.test` passes
15/15 against both the FreeBASIC library and C `testfixture`, with zero errors
and no tracked leaks. These cases verify shared-cache checkpoint locking and
the WAL external-reader file-control across multiple clients. The FreeBASIC
runner uses a temporary Tcl adapter for the existing C file-control API; the
upstream test scripts remain unchanged.

The focused cumulative ledger now records 234,776 passing FreeBASIC upstream
test cases. Full-suite parity and the full case denominator remain unmeasured.

## WAL iterator and overwrite checkpoint (2026-10-17)

The unchanged `waliter.test` passes 10/10 and `waloverwrite.test` passes
23/23 against both the FreeBASIC library and C `testfixture`, with zero errors
and no tracked leaks. `waliter.test` drives 4,000 update/checkpoint iterations
and checks integrity; `waloverwrite.test` rewrites WAL frames repeatedly and
verifies recovery after savepoint rollback. The upstream scripts are unchanged.

The focused cumulative ledger now records 234,809 passing FreeBASIC upstream
test cases. Full-suite parity and the full case denominator remain unmeasured.

## WAL cache spill and unix-excl checkpoint (2026-10-17)

The unchanged `wal64k.test` now passes 6/6 cases against both the FreeBASIC
library and C `testfixture`, with no tracked FreeBASIC allocations remaining.
The test grows the WAL shared-memory file from 64 KiB to 128 KiB, checks
integrity, and then writes an 8,200-row database through SQLite's `unix-excl`
VFS. That VFS is now registered with POSIX locking and the `UNIXFILE_EXCL`
connection flag.

The test exposed a cache-size conversion error: negative cache sizes represent
KiB, but the FreeBASIC page cache passed the negative value directly to
`xCachesize()`. The lower cache converted it to an enormous unsigned page
limit, so `createFlag=1` fetches never requested pager spilling. The cache now
passes `numberOfCachePages()` to `xCachesize()`, matching `src/pcache.c`. The
open path also applies the configurable `SQLITE_DEFAULT_CACHE_SIZE` when the
new B-tree has no schema cache yet, matching `src/btree.c` before schema
initialization begins. Its source default is -2000 KiB. The
unchanged `cache.test` (190/190), `cachespill.test` (8/8), and
`cacheflush.test` (43/43) also pass against both builds after the fix.

The focused cumulative ledger now records 234,815 passing FreeBASIC upstream
test cases, adding the six newly passing `wal64k.test` cases. Full-suite parity
and the full case denominator remain unmeasured.

## Debug corruption-check checkpoint (2026-10-17)

The 1 KiB `SQLITE_DEBUG`/`SQLITE_TEST` build previously aborted while checking
an intentionally damaged index in `pragma-22.2`. SQLite only asserts the fast
record field-count invariant when `CORRUPT_DB` is false. The FreeBASIC debug
helpers now check the same `SQLITE_TESTCTRL_NEVER_CORRUPT` state before
asserting field counts or comparator agreement. Corrupt-index checks through
`pragma-22.4.3` now complete without aborting, and the run reports no tracked
leaks.

The debug pragma helper now supplies SQLite's seven `SQLITE_DEBUG` flag names
to pragma lookup and `PRAGMA pragma_list`, without adding them to release
builds. The VDBE executor also prints SQL, opcode listings, query plans, and
opcode traces when their debug flags are enabled. `vdbe_addoptrace` logs opcode
construction and label resolution, while `sql_trace` logs trigger subprogram
SQL. `parser_trace` logs parser input, reductions, and shifts. A temporary
debug-flag smoke passed 3/3 and observed opcode, SQL, and query-plan traces; a
second smoke confirms all seven pragma names appear in `pragma_list`.

The planner's `translateColumnToCopy` helper now emits the same debug messages
when it scans coroutine bytecode for automatic-index construction or finalizes
a coroutine source. A direct C API smoke with `vdbe_addoptrace` enabled forced
an automatic index over a limited subquery and observed both the `OP_Column` to
`OP_Copy` and `OP_Rowid` to `OP_Sequence` rewrites. This is a debug trace smoke,
not an additional upstream test case.

With the `schema_version` test guard enabled, the non-debug 1 KiB profile
passes all 228 enabled `pragma.test` cases; C `testfixture` runs 236 cases in
its feature profile. The 1 KiB debug profile passes 230/230, including
`pragma-1.15` and `pragma-1.16`. Six C-profile cases require
writable-schema-directory support and remain disabled in the FreeBASIC test
profile. `pragma2.test` passes 27/27 in both profiles. The focused
cumulative ledger now records 234,817 passing FreeBASIC upstream cases, adding
the two newly passing debug pragma assertions; expanded pragma-profile runs
are not added until overlap with the earlier sweeps is reconciled.

## Window-subquery regression checkpoint (2026-10-17)

The unchanged `window2.test` (68), `window3.test` (1,603), `window4.test`
(226), `window6.test` (75), `window7.test` (11), `window8.test` (362),
`window9.test` (43), `windowB.test` (73), `windowC.test` (44),
`windowD.test` (14), `windowerr.test` (15), and `windowpushd.test` (36) pass
all 2,570 cases against both the FreeBASIC library and C `testfixture`, with
zero errors and no tracked leaks. The upstream test scripts are unchanged.

`window9.test` exposed an initialization-order bug: `sqlite3SelectDup` called
`gatherSelectWindows` before copying the duplicated SELECT's LIMIT expression.
The walker visits LIMIT expressions, so it read an uninitialized pointer. The
FreeBASIC copy now sets `pLimit` before gathering window functions, matching C.
`window9.test` then passed all 43 cases in both profiles.

`windowpushd.test` exposed a false negative in safe predicate pushdown. The
GROUP BY stability check rejected column expressions before checking their
resolved collation, so it missed BINARY partition keys and left indexable
predicates outside the window subquery. It now uses SQLite's non-null
expression-collation lookup and binary-collation check, matching C. All four
query-plan regressions now select the expected indexes, and the suite passes
36/36 in both profiles.

The focused cumulative ledger now records 237,387 passing FreeBASIC upstream
test cases, adding the 2,570 newly reconciled window cases. Full-suite parity
and the full case denominator remain unmeasured.

## Authorizer capability reconciliation (2026-10-17)

With `reindex` enabled in the temporary FreeBASIC test profile, the unchanged
`auth.test` passes 380/380 cases against both FreeBASIC and C `testfixture`.
The current profile runs 37 more `auth.test` case identities than the earlier
343-case profile, including the REINDEX authorization callbacks. The unchanged
`auth2.test` passes 15/15 and `auth3.test` passes 10/10 in both profiles, with
no tracked FreeBASIC leaks. The test scripts are unchanged; only the temporary
runner's capability list changed.

The cumulative ledger now records 237,424 passing FreeBASIC upstream cases,
adding the 37 newly enabled authorizer cases. `auth2.test` and `auth3.test`
were already counted. Full-suite parity and the complete case denominator
remain unmeasured.

## Transaction and savepoint checkpoint (2026-10-17)

The transaction suites were reconciled against the unchanged C `testfixture`:
`trans.test` passes 329/329, `trans2.test` 408/408, `savepoint.test` 140/140,
`savepoint2.test` 182/182, `savepoint6.test` 8,007/8,007, and
`savepoint7.test` 12/12 in FreeBASIC and C. All FreeBASIC runs finish with zero
tracked allocations. The cumulative focused ledger is now 246,502 passing
cases. `atomic.test` and `atomic2.test` match C's one-case skip result because
the host does not provide f2fs atomic-batch-write support; those skipped cases
are not included in the cumulative count. Full-suite parity and the complete
case denominator remain unmeasured.

`savepoint6.test` exposed stale PagerSavepoint records after `ROLLBACK TO` a
transaction-level savepoint. The FreeBASIC pager now sends savepoint index -1
through the common rollback cleanup path, which truncates and frees records
before replaying the journal. The VDBE savepoint path also preserves SQLite's
specific "no such savepoint" diagnostic and retains transaction state when a
release returns `SQLITE_BUSY`. The unchanged savepoint suites pass after these
repairs.

The unchanged `savepointfault.test` also completes without errors or tracked
FreeBASIC leaks. Its allocator-fault loops generate 699 FreeBASIC cases and 888
C cases because the profiles reach different allocation counts; the FreeBASIC
run reaches the end of each fault-injection loop. The 699 FreeBASIC cases are
included in the focused cumulative count, which now stands at 247,201. This
suite's dynamic case counts are not a one-to-one comparison.

With `autoindex` enabled in the temporary FreeBASIC test capability list, the
unchanged `autoindex1.test` passes 40/40 in both FreeBASIC and C. This covers
automatic-index creation, query results, scan counts, and the warning callback.
The test runner's temporary log adapter now preserves the extended
`SQLITE_WARNING_AUTOINDEX` name; the engine emitted the correct code and no
SQLite source repair was needed. The focused cumulative ledger is now 247,241
passing FreeBASIC cases. The unchanged `autoindex2.test` through
`autoindex5.test` also pass against C: 4/4, 10/10, 54/54, and 9/9 cases,
respectively, with no tracked FreeBASIC leaks. The five autoindex suites now
cover 117/117 cases, and the focused cumulative ledger stands at 247,318.

## Debug ANALYZE checkpoint (2026-10-17)

The FreeBASIC debug/test profile passes unchanged `autoanalyze1.test` 18/18 in
both `THREADSAFE=0` and `THREADSAFE=1` builds, matching C, with zero tracked
allocations. The debug-only `PRAGMA stats` name, table-valued pragma lookup,
and VDBE rows are implemented from upstream `pragma.c`. The Unix VFS now uses
SQLite's `SQLITE_MUTEX_STATIC_VFS1` lock and permits the null no-op mutex used
when core mutexes are disabled; this matches the upstream lock contract and
removes the debug assertion on the first database open. The focused cumulative ledger now
stands at 247,336 passing FreeBASIC cases. Full-suite parity and the complete
case denominator remain unmeasured.

## Scan-status test reconciliation (2026-10-17)

The unchanged `scanstatus.test` passes all 60 cases enabled by the FreeBASIC
profile, and `scanstatus2.test` passes all 22; both end with zero tracked
allocations. A C `testfixture` rebuilt with `SQLITE_ENABLE_STMT_SCANSTATUS=1`
passes 63 and 24 cases, respectively. Its extra cases use FTS3 and FTS5, which
are disabled in the current FreeBASIC test profile. All shared cases pass.

These runs corrected two temporary Tcl-adapter mismatches: selecting the
statement-cache head for `db version -last-stmt-ptr`, and routing scan-status
configuration through the underlying database handle. A direct C ABI probe
also confirms scan-status rows appear when enabled and disappear for a newly
prepared statement when disabled. No upstream test source or SQLite engine
change was needed for this reconciliation; the cumulative case total remains
247,336 because these suites were already counted.

## CARRAY runtime recheck (2026-10-17)

The unchanged `carray01.test` and `carray02.test` pass 31/31 and 19/19 in both
engines. With the current FreeBASIC feature profile,
`carrayfault.test` passes 266/266 with no tracked leaks; C passes 194/194.
The OOM harness generates a different number of allocation-failure cases in
the two profiles. The CARRAY suites were already included in the focused
cumulative count, so this profile recheck does not add cases to 247,336.

## SQLITE_ENABLE_NORMALIZE runtime checkpoint (2026-10-17)

The unchanged `normalize.test` passes all 70 cases in the FreeBASIC normalize
profile, with zero tracked allocations. The port now creates the SELECT VDBE
before name resolution, matching SQLite's ordering so double-quoted names
that resolve as string literals are recorded and normalized to `?`. The
unchanged `select1.test` also passes 199/199 in a regression recheck with zero
tracked allocations; those cases were already counted.

The temporary Tcl adapter supplies the test-only `hex8()` SQL function,
result-code formatting, and `sqlite3_bind_null` command required by the
unchanged upstream test. The test source itself is unchanged. The focused
cumulative ledger now stands at 247,406 passing FreeBASIC cases. Full-suite
parity and the complete case denominator remain unmeasured.

## Math and percentile runtime checkpoint (2026-10-17)

With `SQLITE_ENABLE_MATH_FUNCTIONS` and `SQLITE_ENABLE_PERCENTILE`, the
unchanged `func7.test` passes 74/74 and `percentile.test` passes 128/128; both
finish with zero tracked allocations. The percentile suite's million-row cases
also complete successfully using the unchanged `wholenumber` test extension.

The first math run exposed four functions hidden by the absent
`SQLITE_HAVE_C99_MATH_FUNCS` build flag. The FreeBASIC Unix profile now mirrors
SQLite's non-MSVC default for this capability, enabling `trunc`, `asinh`,
`acosh`, and `atanh` when the math feature is built. The temporary Tcl runner
sets the math capability and loads `wholenumber`; upstream test sources remain
unchanged. The focused cumulative ledger now stands at 247,608 passing
FreeBASIC cases. Full-suite parity and the complete case denominator remain
unmeasured.

## Virtual-table schema recheck (2026-10-17)

With the full upstream `test8.c` echo module loaded through the temporary C
fixture bridge, unchanged `vtab1.test` passes 213/213 with zero tracked leaks.
This covers module construction, `sqlite3_declare_vtab()` schema transfer,
virtual-table scans and updates, and the reentrant schema-lock case. The full
adapter enables `vtab1.8-1` in addition to the 212 cases in the prior profile,
so this recheck adds one case. A prior attempt using a reduced echo adapter
was invalid and was not counted. The focused ledger now stands at 247,609.

## Core runtime rechecks (2026-10-17)

The current feature profile also passes unchanged `trans.test` 329/329 and
`createtab.test` 64/64, both with zero tracked leaks. The transaction run
reaches the end of the 40-iteration rollback workload; the CREATE TABLE suite
includes the 100,000-column rejection case. Both suites were already included
in the focused cumulative ledger, which remains at 247,609.

## Shared-cache locking recheck (2026-10-17)

With the child-process pending-byte setup and upstream result-code formatting
in the temporary Tcl bridge, the current math/C99 profile passes unchanged
`shared.test`, `shared2.test`, `shared9.test`, and `sharedlock.test` 250/250
with zero tracked leaks. These rechecks were already counted in the broader
shared-cache checkpoint above. The initial run without these adapter shims
was not counted.

## Window VDBE runtime recheck (2026-10-17)

The current feature profile passes unchanged `window1.test` 348/348 and the
window2/3/4/6/7/8/9/B/C/D/err/pushd family 2,537/2,537, all with zero tracked
allocations. The same build passes the math, percentile, virtual-table, and
transaction suites. An earlier broader window-profile run passed 2,570/2,570
against C; the enabled case counts differ by profile. The window cases were
already counted, so the focused cumulative total remains 247,609.

## Attached-database commit recheck (2026-10-17)

The current profile passes unchanged `attach.test` 111/111 with zero tracked
leaks. Its `schema_pragmas` capability enables five `db_list` cases beyond the
prior 106-case profile; the other attached-database suites remain covered by
their earlier results. These newly enabled cases bring the focused cumulative
ledger to 247,614. The upstream test source is unchanged.

## Soundex feature C-reference smoke (2026-10-17)

The `SQLITE_SOUNDEX` FreeBASIC profile builds and matches a C amalgamation
built with the same option for ten inputs: Robert/Rupert/Rubin, Ashcraft/
Ashcroft, Tymczak/Pfister, a one-letter word, NULL, and nonalphabetic text.
The checkout has no dedicated upstream Soundex test file, so this direct
comparison adds no cases to the focused ledger, which remains at 247,614.

## Storage-class and record-size runtime checkpoint (2026-10-17)

The unchanged upstream `types.test` passes 56/56 cases against both the
FreeBASIC library and C `testfixture`, with no tracked SQLite allocations
remaining. This includes all literal-affinity cases with `bloblit` enabled and
the direct B-tree payload-size checks for integer, real, NULL, text, and mixed
records. The focused cumulative ledger now records 247,670 passing FreeBASIC
upstream cases. Full-suite parity and the complete case denominator remain
unmeasured.

The upstream `src/test3.c` B-tree helper uses a private C-layout fake
`sqlite3` object, which is incompatible with the FreeBASIC connection layout.
A temporary Tcl adapter instead opens a real FreeBASIC connection through the
public API and exposes its main B-tree to the existing record-size procedure.
The adapter and Tcl runner stay in `/tmp`; no upstream test or engine source
was changed for this checkpoint.

## Tcl value representation checkpoint (2026-10-17)

The unchanged upstream `types3.test` passes 19/19 cases against both the
FreeBASIC library and C `testfixture`, with no tracked SQLite allocations
remaining. Its checks cover Tcl string, integer, wide-integer, double, and
byte-array representations, plus SQLite callbacks that force another value
representation before returning it. The focused cumulative ledger now records
247,689 passing FreeBASIC upstream cases.

The temporary runner implements `tcl_variable_type` using Tcl's
`tcl::unsupported::representation` output and registers the three test SQL
callbacks with the same public API operations used by upstream `src/test1.c`.
Both helpers are outside the repository; the original Tcl test remains
unchanged.

## CAST and UTF-16 blob conversion checkpoint (2026-10-17)

After enabling the port's CAST capability in the temporary runner, the
unchanged `cast.test` passes 135/135 cases against both FreeBASIC and C
`testfixture`. The unchanged `numcast.test` passes 52/52 in both profiles.
`types.test` and `types3.test` remain green at 56/56 and 19/19, respectively,
with no tracked SQLite allocations remaining in any run. Across the type and
CAST checkpoints, the ledger increased by 261 distinct cases from 247,614 to
247,875. Full-suite parity and the full case denominator remain unmeasured.

The newly enabled CAST cases found that `OP_Blob` had left blob registers
tagged as UTF-8 instead of using the database encoding. The executor now sets
the encoding to `db->enc`, matching `src/vdbe.c`. A direct UTF-16 probe also
found that `hexFunc` fetched the byte count before the blob pointer. Since the
byte-count call can convert text to UTF-8, the order now matches `src/func.c`.
The FreeBASIC and C probes agree on the text, length, hexadecimal bytes, and
comparison result. The test-only Tcl bridge and runners remain in `/tmp`.

The related unchanged `numcast.test` contributes 52 passing cases. The
`affinity2.test` and `affinity3.test` results were already counted in the
earlier core batch. `types2.test` was rechecked at 399/399 but is not added to
the cumulative tally.

The reduced CAST runner's first `func.test` attempt omitted helper callbacks
from upstream `src/test_func.c`. After registering those unchanged C test
callbacks and the `abuse_create_function` command in the temporary bridge,
`func.test` passes 15,031/15,031 against both the FreeBASIC engine and C
`testfixture`, with no tracked SQLite allocations remaining. The test file and
engine APIs remain unchanged. The earlier checkpoint counted 15,030 cases;
this profile's extra enabled case is not added until case identities are
reconciled, avoiding a duplicate or profile-dependent count.

## Optional sqlite_offset runtime checkpoint (2026-10-17)

The feature-enabled build now passes unchanged `func6.test` 12/12 against both
FreeBASIC and a C reference build with `SQLITE_ENABLE_OFFSET_SQL_FUNC`, with no
tracked allocations remaining. `func5.test` and `func8.test` also pass their
6 and 9 cases in both default profiles. The regular default build succeeds and
the feature guard skips `func6.test` when the option is absent. A direct SQL
probe confirms both default builds report `sqlite_offset()` as unavailable.

The feature path needed three pieces that had only been compile-checked:
registering `sqlite_offset` as an inline builtin, emitting `OP_Offset` for
column expressions, and rewriting that opcode to use the selected index
cursor. The `WhereEnd` rewrite now preserves the opcode's column metadata
while translating its cursor. These tests add 27 distinct cases to the
focused ledger, bringing it to 247,902.

## Text encoding test checkpoint (2026-10-17)

The unchanged upstream `enc.test` passes 115/115 cases against the FreeBASIC
library; the C reference passes 116/116 because one additional R-Tree case is
enabled there. `enc3.test` passes 12/12 and `enc4.test` passes 1,115/1,115 in
both profiles. Temporary Tcl bridges provide the upstream UTF test helpers,
shared-cache capability, and `sqlite3_bind_text16` command. No upstream test
source or engine code changed for these runs.

These encoding suites add 1,242 cases to the focused ledger, bringing it to
249,144 passing upstream cases. The checkout contains 1,196 Tcl `.test` files;
the complete case denominator and full-suite parity remain unmeasured.

## Optional key/value VFS runtime checkpoint (2026-10-20)

The `SQLITE3_FB_OS_KV_OPTIONAL` profile passes an out-of-tree C API smoke
against a C reference built with `SQLITE_OS_KV_OPTIONAL`. The extended probe
opens both `local` and `session` storage classes, writes and reads 32 BLOB rows
per class, and covers all byte values, zero runs, empty and large BLOBs, an
update, a rolled-back insert, close and reopen, and `PRAGMA integrity_check`.
It calls `sqlite3_shutdown()` between the local and session runs, then opens
the next database again to exercise OS shutdown and reinitialization. The
explicit optional-VFS profile and the `SQLITE3_FB_OS_KV_DEFAULT` profile both
match the C reference's row checksums. A second pass uses the upstream
`:localStorage:` and `:sessionStorage:` filename aliases and verifies that
`PRAGMA temp_store` is 2 and temporary tables work through KVVFS. For each
profile, all 170 backing records are byte-identical between C and FreeBASIC,
totaling 993,450 bytes per run. The probe adds no upstream test cases and
changes no upstream test source.

## Parallel sorter runtime checkpoint (2026-10-17)

An out-of-tree C API workload builds a 40,000-row in-memory table, sets
`SQLITE_CONFIG_PMASZ=10`, `PRAGMA cache_size=10`, `temp_store=FILE`, and
`threads=4`, then sorts all rows in descending order with a 512-byte payload.
Both the current FreeBASIC library and a C reference report
`MAX_WORKER_THREADS=8`, return every row in order with intact payloads, and
report `ok` from `PRAGMA integrity_check`. An `LD_PRELOAD` counter confirms
that each profile actually calls `pthread_create`; the call count varies with
worker scheduling and is not used as a parity metric. The direct probe adds no
upstream test cases.

The unchanged upstream `sort4.test` multithread permutation now completes with
zero errors in the current FreeBASIC `THREADSAFE=1`, `MAX_WORKER_THREADS=8`
profile and in the C `testfixture`. Its worker-limit checks pass at five and
three workers. The timed loops report 19 FreeBASIC test invocations and 51 C
invocations; the totals vary with runtime and are not added as new unique case
IDs. Both runners finish with no tracked SQLite allocations. The temporary
FreeBASIC Tcl harness emits its generic `thread_common.tcl` warning because it
does not declare the fixture's `mutex` capability; `sort4.test` itself still
configures and exercises the VDBE sorter workers.

## Extension loading runtime checkpoint (2026-10-17)

With a temporary Tcl bridge for the test fixture's extension-loading commands,
the unchanged `loadext.test` passes 26/26 FreeBASIC invocations; C `testfixture`
passes 29/29. The suite exercises extension loading authorization, successful
entry points, missing files, invalid shared objects, missing symbols, and the
SQL `load_extension()` authorization boundary. The invocation totals differ
because the Tcl fixture and fault loops enumerate different helper cases. The
FreeBASIC fault bridge produced no injected allocation failures in the
`loadext-5` and `loadext-6` loops. A separate fail-next-allocation probe during
extension loading recorded one failure in both profiles and produced the same
Tcl error text and database error code. This checks one failure point; broad
OOM parity was still open at this 2026-10-17 checkpoint and is extended by the
later differential sweep.

The unchanged `loadext2.test` passes all 23 test-script cases against the
FreeBASIC engine; C `testfixture` reports 29 cases. Those counts reflect
different fixture-side helper accounting. The script checks auto-extension
registration, invocation on new connections, cancellation, reset, and failure
during initialization. Both profiles report zero test errors; the FreeBASIC run
has no tracked SQLite allocations. These 23 cases bring the focused unique-case
ledger to 249,167. The complete suite denominator remains unmeasured. No
upstream test files were modified.

## MEMSYS5 allocator runtime checkpoint (2026-10-17)

The unchanged `mem5.test` passes all four configuration cases in the
`SQLITE_ENABLE_MEMSYS5`, `THREADSAFE=1` FreeBASIC profile with zero errors and
no tracked allocations. A C reference compiled with MEMSYS5 returns the same
heap-configuration and initialization codes: ordinary heap setup succeeds,
minimum request sizes of 2^30 and 2^30+1 produce `SQLITE_NOMEM` at initialize,
and resetting to the default allocator succeeds.

A second C API workload configures a 25 MB MEMSYS5 heap, populates a 5,000-row
in-memory table, checks aggregate values and `integrity_check`, closes, and
shuts down. FreeBASIC and C outputs match exactly. These runs add five reported
upstream test invocations to the focused ledger, bringing it to 249,172; the
full suite denominator remains unmeasured.

## SQL completeness API checkpoint (2026-10-17)

An out-of-tree C API comparison matched the FreeBASIC and C results for 29
UTF-8 inputs to `sqlite3_complete()` and `sqlite3_incomplete()`, including
quoted semicolons, unterminated comments and literals, trigger endings,
parentheses, and trailing text. Native-endian UTF-16 complete and incomplete
inputs also match through `sqlite3_complete16()`. This direct probe adds no
upstream test cases.

## Bytecode virtual-table runtime checkpoint (2026-10-17)

An out-of-tree probe against the `SQLITE_ENABLE_BYTECODE_VTAB` profile found
that `bytecode()` rows matched C but `tables_used()` returned no rows. The
FreeBASIC vtab connection had converted C's `0/1` flag using FreeBASIC's `0/-1`
boolean values, producing `-2` instead of the required mode value `2`; the
shared `sqlite3VdbeNextOpcode()` port also lacked C's mode-2 opcode filter. Both
paths now match C. The probe returns the same 13 bytecode rows, identifies
`index i1` and `table t1` in `tables_used()`, and reports the `tr1` trigger
subprogram in both profiles. No upstream test source or case count changed.


## UTF-16 recursive CTE runtime checkpoint (2026-10-17)

The unchanged upstream `atof1.test` passes 40,006/40,006 cases against both the
FreeBASIC library and C `testfixture`, with no tracked FreeBASIC allocations.
This includes the 40,000 randomized numeric round-trip checks and the recent
large-number conversion regressions. The initial FreeBASIC run failed the three
new regression cases after the script switched the database to UTF-16BE.

The mismatch was in pseudo-cursor record decoding. `sqlite3VdbeSerialGet()`
leaves the destination encoding unchanged, but the pseudo-cursor path initialized
its temporary value as UTF-8 even though recursive CTE records use the database
encoding. The decoder now sets both the temporary and output Mem cells to the
connection encoding before copying text. A reduced probe confirms recursive
CTE literals, concatenation, formatting, and numeric casts match C in UTF-16BE.
These 40,006 previously untracked cases bring the focused cumulative ledger to
289,178 passing upstream cases. The full-suite denominator remains unmeasured.


## SELECT planner and HAVING runtime checkpoint (2026-10-17)

The unchanged `cost.test` (43/43), `cse.test` (125/125), `emptytable.test`
(5/5), and `having.test` (22/22) pass against both the FreeBASIC engine and C
`testfixture`, with no tracked FreeBASIC allocations. The HAVING suite checks
that deterministic predicates matching BINARY `GROUP BY` terms move into
WHERE, while aggregate, collation-sensitive, and nondeterministic terms remain
in HAVING. Its VDBE-equivalence cases now pass as well.

The translated `havingToWhere()` helper existed but the grouped aggregate path
did not call it. The path now invokes the walker before aggregate analysis, as
SQLite does. Aggregate output uses the existing `sqlite3ExprIfFalse()` branch
compiler so a rewritten `HAVING 1` emits no redundant test and NULL still
rejects a group. This batch adds 195 distinct cases to the focused ledger,
bringing it to 289,373 passing upstream cases. The full-suite denominator
remains unmeasured.


## Join and outer-join runtime checkpoint (2026-10-17)

The unchanged `join.test`, `join2.test`, `join4.test` through `join7.test`,
and `join9.test` through `joinI.test` pass 2,992 combined cases against both
the FreeBASIC engine and C `testfixture`. The suites cover NATURAL and USING
joins, legacy ON-clause forms, outer-join filtering, join ordering, and nested
join expressions. All runs report zero errors and no tracked FreeBASIC
allocations. No upstream test file was changed.

These 2,992 distinct cases bring the focused cumulative ledger to 292,365
passing upstream cases. The complete suite denominator remains unmeasured.


## Simple-count and float-rounding runtime checkpoint (2026-10-17)

The unchanged `count.test` passes 41/41 cases against both engines with no
tracked FreeBASIC allocations. It covers empty tables, table and index counts,
large B-trees, `COUNT()` opcode selection, WITHOUT ROWID tables, and
`NOT INDEXED` plan behavior. The ungrouped aggregate compiler now calls the
ported `isSimpleCount()` helper, verifies and locks the table schema, chooses
the smallest eligible ordered non-partial index, and emits `OP_OpenRead`,
`OP_Count`, and `OP_Close`. `NOT INDEXED` prevents index selection, while
WITHOUT ROWID tables start from their primary-key index. A separate public C
API probe against the release library returns `count=3` and confirms its
EXPLAIN program contains `OP_Count`.

The unchanged `atof2.test` passes 5/5 in both engines with no tracked
allocations; its temporary IEEE-754 test extension was built outside the
repository. The `count.test` echo virtual-table fixture bridge also remains
outside the repository. These 46 distinct upstream cases bring the focused
cumulative ledger to 292,411 passing cases. The full-suite denominator remains
unmeasured.


## Row-value comparison checkpoint (2026-10-17)

The unchanged `rowvalue2.test` (3,835/3,835), `rowvalue3.test` (112/112),
`rowvalue4.test` (298/298), `rowvalue6.test` (3/3), `rowvalue7.test` (9/9),
`rowvalue8.test` (4/4), and `rowvalue9.test` (96/96) pass in the FreeBASIC
profile with no tracked allocations. The unchanged `rowvalue.test` now passes
308/308 with no tracked allocations. The nested-vector predicate
`rowvalue-20.1` passes after the tableless SELECT WHERE path flattens matching
nested tuple shapes for the existing vector comparison emitter. The invalid
nested-vector expression in `rowvalue-29.1` reports the expected error, and
the formerly malformed database-image cases `rowvalue-18.2` and `rowvalue-18.5`
pass. `rowvalue-30.2` passes after aggregate UPDATE FROM output uses the shared
row emitter and propagates failed source SELECT compilation instead of leaving
an empty update source table.

The unchanged `rowvalue5.test` now passes 16/16 with no tracked allocations in
a scan-status-enabled FreeBASIC test profile. Its temporary runner loads the
existing `test_bestindex` adapter and scan-status bridge; the upstream test
file remains unchanged. C `testfixture` also passes 16/16. These row-value
runs add 4,681 passing cases to the focused cumulative ledger, bringing it to
297,092. The complete suite denominator remains unmeasured.


## UPDATE FROM runtime checkpoint (2026-10-17)

The unchanged `upfrom1.test` (23/23), `upfrom2.test` (47/47),
`upfrom3.test` (43/43), and `upfrom4.test` (9/9) pass in the FreeBASIC profile
with no tracked allocations. The target-table and target-alias duplicate checks
now match SQLite's diagnostic. `upfromfault.test` also passes 1,887/1,887 with
no tracked allocations; 154 passing case invocations in this profile were not
included in its previously recorded profile run.

The UPDATE FROM source-select path now reports non-OK SELECT compilation
results to the parser. Simple aggregate SELECT output supports the `SRT_Upfrom`
destination and uses the normal internal-row emitter, including the empty
source-row check. Duplicate target table and alias references in the FROM
clause report SQLite's expected error. These UPDATE FROM runs add 276 passing
cases to the focused cumulative ledger, bringing it to 297,368. The complete
suite denominator remains unmeasured. The release library also builds, and a
public C API probe returns the expected `1000 2` row with one changed row.


## Correlated VALUES and constant-expression traversal checkpoint (2026-10-17)

The unchanged `values.test` (133/133), `subselect.test` (27/27),
`valuesfault.test` (329/329), and `windowfault.test` (5,750/5,750) pass in the
current FreeBASIC test profile with no tracked allocations. The unchanged
`rowvalue.test` remains 308/308, and `rowvaluefault.test` passes 1,335/1,335.
The full-adapter `func.test` rerun also passes 15,031/15,031; its case labels
match the earlier profile and add no new cases to the ledger.

The constant-expression walker now returns `WRC_PRUNE` for a deterministic
function after checking its arguments. This lets the enclosing expression
list continue to correlated sibling expressions. The VALUES coroutine
eligibility check therefore chooses its UNION ALL fallback when a row
expression refers to an outer column. This fixes `values-13.0` and the nested
VALUES row-value cases without adding a VALUES-specific reference scan. The
newly counted values, subselect, and fault cases add 216 passes to the focused
ledger, bringing it to 297,584. The complete suite denominator remains
unmeasured. A public C API probe against the release library returns
`xyz`, both expected row-value result sets, and `1000 2` after the UPDATE FROM
aggregate.


## IN-subquery Bloom filter runtime checkpoint (2026-10-17)

A direct C API differential probe runs the same membership queries against
the FreeBASIC release library and the C reference. Both return identical
results when the RHS contains `NULL`, including the projected three-valued
membership results. The `WHERE x IN (SELECT y ...)` bytecode contains one
`OP_Filter`, one `OP_FilterAdd`, and one Bloom-filter `OP_Blob` in both
libraries. Disabling only `SQLITE_BloomFilter` through
`SQLITE_TESTCTRL_OPTIMIZATIONS` removes all three opcodes in both libraries;
restoring the optimization restores them. A `NOCASE` comparison returns the
same rows in both libraries and emits none of the Bloom opcodes. This checks
the binary-collation guard and negative-membership shortcut without changing
upstream tests or adding upstream case IDs.


## JSONB payload-resize runtime checkpoint (2026-10-17)

A direct C API differential probe compares JSONB set, replace, insert, and
remove results at 17 input-string sizes from 0 through 512 bytes, including
payload-size transition boundaries. All 612 result rows match the C reference.
Together with the unchanged JSON suites, this verifies the JSONB mutation path
and its encoded-payload resize handling without adding upstream case IDs.


## GCC backend differential checkpoint (2026-10-17)

The full release library builds with `fbc -gen gcc` in
`build/gcc/libsqlite3-fb.so`. The GCC-backend library produces byte-identical
output to both the native FreeBASIC build and the C reference for the 612-row
JSONB edit probe and the IN-subquery Bloom probe, including enabled/disabled
optimization and `NOCASE` paths. No backend mismatch was found, so this run
did not establish a FreeBASIC compiler defect or require an FBC source change.


## Join Bloom-filter runtime recheck (2026-10-17)

The unchanged `joinD.test` passes 1,171/1,171 and `joinE.test` passes 37/37
against native FreeBASIC, GCC-backend FreeBASIC, and C `testfixture`, with no
tracked FreeBASIC allocations. The emitted case labels match across all three
runs. These suites were already included in the 2,992-case join checkpoint,
so this recheck adds no upstream case IDs.


## WHERE planner runtime checkpoint (2026-10-17)

The unchanged `where4.test` through `where7.test`, `whereF.test` through
`whereI.test`, and `whereK.test` pass 2,267/2,267 cases against the FreeBASIC
engine and C `testfixture`, with no tracked FreeBASIC leaks. The unchanged
`whereJ.test` passes 18/18 in matching `SQLITE_ENABLE_STAT4` profiles. The
emitted case labels match across profiles. These 2,285 previously uncounted
cases bring the focused ledger to 299,869; the full-suite denominator remains
unmeasured. The largest suite, `where7.test` (2,027/2,027), also passes in the
GCC-backend test profile; its case labels match native FreeBASIC and C.


## Trigger execution runtime checkpoint (2026-10-17)

The unchanged `trigger6.test` (7/7), `trigger7.test` (11/11), and
`trigger8.test` (2/2) pass against both the FreeBASIC engine and C
`testfixture`, with zero errors and no tracked FreeBASIC leaks. These 20
previously uncounted cases bring the focused ledger to 299,889; the complete
suite denominator remains unmeasured.


## Parser stack OOM recovery checkpoint (2026-10-17)

The unchanged `exprfault2.test` now passes all 8,999 FreeBASIC fault-injection
iterations in both native and GCC-backend profiles with no tracked leaks; the
test labels are identical. C `testfixture` completes 25,187/25,187 in its
allocator profile, with no leaks. The two FreeBASIC failures at fault points 2
and 52 came from parser-stack reallocations that did not mark their owning
Parse as out of memory; stack overflow was then reported as an error at the
current token. The parser stack allocator now calls `sqlite3OomFault()` on
failure, records `SQLITE_NOMEM` on the owning Parse, and the driver preserves
Lemon's overflow diagnostic. A direct C API probe with parser depth limited to
40 returns the same `SQLITE_ERROR`, `Recursion limit` message, and tail offset
in C, native FreeBASIC, and GCC-backend FreeBASIC. These 8,999 previously
uncounted cases bring the focused ledger to 308,888.


## Additional trigger runtime checkpoint (2026-10-17)

The unchanged `triggerB.test` (203/203), `triggerD.test` (13/13), and
`triggerF.test` (13/13) pass against both engines. `triggerE.test` passes
27/27 in the FreeBASIC profile and 28/28 in C; its extra C case is gated on
the R-Tree extension, which the current FreeBASIC profile does not enable.
All shared case labels match, and the FreeBASIC runs end with no tracked
allocations. These 256 shared cases bring the focused ledger to 309,144.


## Integrity-check allocation-fault runtime checkpoint (2026-10-17)

The unchanged `pragmafault.test` passes all 235 test invocations on both
native and GCC-backend FreeBASIC builds, with matching labels, zero errors,
and no tracked leaks. C `testfixture` passes 351 invocations; its allocator
profile exposes more fault points. The suite injects allocation and
shared-memory errors while running `PRAGMA integrity_check`. These 235
previously uncounted FreeBASIC cases bring the focused ledger to 309,379.


## Legacy table API runtime checkpoint (2026-10-17)

The unchanged `tableapi.test` passes 125/125 on both native and GCC-backend
FreeBASIC builds with matching case labels and no tracked leaks; C `testfixture`
passes 171/171 under its allocator profile. It covers formatted SQL, empty
results with `empty_result_callbacks`, multiple statements with incompatible
result columns, 100-column rows, and allocation faults. The run exposed and
fixed the empty-result column-header callback and the exact incompatible-query
diagnostic. These 125 previously uncounted FreeBASIC cases bring the focused
ledger to 309,504.


## Legacy ALTER rename runtime checkpoint (2026-10-17)

The unchanged `alterlegacy.test` passes 61/61 cases on native and GCC-backend
FreeBASIC builds with identical labels and no tracked leaks. C `testfixture`
passes 69/69; eight C-only cases are gated on FTS5 and R-Tree, which the
FreeBASIC profile does not enable. A temporary C echo-vtab adapter supplies
the test fixture behavior without changing upstream tests. These 61 newly
counted cases bring the focused ledger to 309,565.


## ALTER allocation-fault runtime checkpoint (2026-10-17)

The unchanged `altermalloc2.test` passes 9,501 FreeBASIC fault iterations and
`altermalloc3.test` passes 4,436, with no tracked leaks. C `testfixture` passes
10,335 and 4,570 iterations respectively; the allocator profiles enumerate
different failure points. The suites exercise column/table rename, UTF-16
schema rewriting, DROP COLUMN, WITHOUT ROWID indexes, views, and triggers.
The temporary runner enables DQS DDL for `altermalloc3`; upstream tests remain
unchanged. The unchanged `altercorrupt.test` passes 5/5 on native and
GCC-backend FreeBASIC and C `testfixture`, with no tracked FreeBASIC leaks;
a temporary bridge provides upstream's `decode_hexdb` fixture helper.
These 13,942 previously uncounted FreeBASIC cases bring the focused ledger to
323,507. The full-suite denominator remains unmeasured.


## ALTER table rename runtime checkpoint (2026-10-17)

The unchanged `altertab.test` passes 120/120 invocations on native and
GCC-backend FreeBASIC with identical case labels and no tracked leaks. C
`testfixture` passes 138/138; its 18 additional cases require FTS3, FTS5, or
R-Tree support that is not enabled in the FreeBASIC profile. These 120 newly
counted cases bring the focused ledger to 323,627. The full-suite denominator
remains unmeasured.


## DROP COLUMN runtime checkpoint (2026-10-17)

The unchanged `alterdropcol.test` passes 101/101 invocations on native and
GCC-backend FreeBASIC with identical case labels and no tracked leaks. C
`testfixture` passes 103/103; its two additional cases are gated on FTS5.
These 101 newly counted cases bring the focused ledger to 323,728. The
full-suite denominator remains unmeasured.


## ALTER quoted-identifier rewrite checkpoint (2026-10-17)

The unchanged `alterqf.test` passes 15/15 invocations on native and
GCC-backend FreeBASIC and C `testfixture`, with identical labeled cases and no
tracked FreeBASIC leaks. It exercises `sqlite_rename_quotefix()` with quoted
strings in views, indexes, triggers, generated columns, and WITHOUT ROWID
schemas. These 15 newly counted cases bring the focused ledger to 323,743.
The full-suite denominator remains unmeasured.


## INSERT trigger runtime checkpoint (2026-10-17)

The unchanged `insert3.test` passes 19/19 invocations on native and
GCC-backend FreeBASIC and C `testfixture`, with matching emitted labels and no
tracked FreeBASIC leaks. The temporary runner enables the engine's blob-literal
capability so the FTS-independent `DEFAULT VALUES` blob case runs as well.
The suite covers INSERT FROM SELECT, trigger execution, default values,
constraint handling, and B-tree stress. These 19 newly counted cases bring the
focused ledger to 323,762. The full-suite denominator remains unmeasured.


## INTEGER PRIMARY KEY and UNIQUE index checkpoint (2026-10-17)

The unchanged `intpkey.test` passes 108/108 invocations and `unique2.test`
passes 27/27 on native FreeBASIC, GCC-backend FreeBASIC, and C `testfixture`.
All labeled cases match across profiles, and the FreeBASIC runs report no
tracked leaks. The `intpkey` runner enables the upstream integrity-check and
blob-literal branches that were disabled in the initial temporary profile.
The suites cover rowid aliases, generated rowids, type conversion, UNIQUE
constraint enforcement, and index creation on rowid and WITHOUT ROWID tables.
These 135 newly counted cases bring the focused ledger to 323,897. The
full-suite denominator remains unmeasured.


## Column-count C API checkpoint (2026-10-17)

The unchanged `columncount.test` passes 8/8 invocations on native and
GCC-backend FreeBASIC and C `testfixture`, with identical labeled cases and no
tracked FreeBASIC leaks. A temporary Tcl C API bridge exposes
`sqlite3_data_count()` and `sqlite3_errmsg()` to the unchanged test script.
These eight newly counted cases bring the focused ledger to 323,905. The
full-suite denominator remains unmeasured.


## NULL ordering and row-value checkpoint (2026-10-17)

The unchanged `nulls1.test` passes 120/120 and `nulls2.test` passes 21/21 on
native and GCC-backend FreeBASIC and C `testfixture`, with matching case labels
and no tracked FreeBASIC leaks. These suites cover NULLS FIRST/LAST ordering
with and without indexes, virtual-table ordering, and row-value `IN` queries
with NULL values. The 141 newly counted cases bring the focused ledger to
324,046. The full-suite denominator remains unmeasured.


## Incremental BLOB zero-tail runtime checkpoint (2026-10-17)

The unchanged `incrblob2.test` passes 82/82 invocations on native and
GCC-backend FreeBASIC and C `testfixture`, with identical labeled cases and no
tracked FreeBASIC leaks. Its 10 MiB `zeroblob` memory checks exposed that record
packing materialized a zero-filled tail before B-tree insertion. The record
packer now leaves a trailing zero suffix implicit as `MEM_ZERO`, which the
table-insert opcode passes to the B-tree payload writer. Both FreeBASIC
backends now pass all three high-water assertions under 5 MiB. These 82 newly
counted cases bring the focused ledger to 324,128. The full-suite denominator
remains unmeasured.


## Incremental BLOB preupdate checkpoint (2026-10-17)

The unchanged `incrblob4.test` passes 26/26 invocations on native and
GCC-backend FreeBASIC and C `testfixture`, with matching case labels and no
tracked FreeBASIC leaks. `blobReadWrite()` now restores an invalidated cursor
and invokes the registered preupdate hook before writing BLOB bytes, matching
the C path. The temporary runner forwards the database command's preupdate
method and maps its extended-error query to the wrapped connection. These 26
newly counted cases bring the focused ledger to 324,154. The full-suite
denominator remains unmeasured.


## Incremental-vacuum corruption checkpoint (2026-10-17)

The unchanged `incrcorrupt.test` passes 36/36 invocations on native and
GCC-backend FreeBASIC and C `testfixture`, with identical case labels and no
tracked FreeBASIC leaks. The FreeBASIC test libraries use the 1 KiB default
page size from SQLite's C testfixture profile; the initial 4 KiB profile
produced different page-count expectations. Corruption detection and error
state persistence match C after aligning the test build. These 36 newly
counted cases bring the focused ledger to 324,190. The full-suite denominator
remains unmeasured.


## Reserve-byte VACUUM checkpoint (2026-10-17)

The unchanged `reservebytes.test` passes 12/12 invocations on native and
GCC-backend FreeBASIC and C `testfixture`, with matching case labels and no
tracked FreeBASIC leaks. The test profile uses the C fixture's 1 KiB default
page size. B-tree header reads no longer overwrite `nReserveWanted` with the
current on-disk reserve, so a later VACUUM preserves a newly requested 16-byte
reserve after a prior 8-byte reserve. These 12 newly counted cases bring the
focused ledger to 324,202. The full-suite denominator remains unmeasured.


## Incremental-vacuum mode and corruption checkpoint (2026-10-17)

The unchanged `incrvacuum.test` passes 168/168 invocations on native and
GCC-backend FreeBASIC and C `testfixture`, with matching case labels and no
tracked FreeBASIC leaks. The test profile enables mmap, hex-database decoding,
and the C fixture's 1 KiB default page size. `sqlite3BtreeUpdateMeta()` now
updates the in-memory incremental-vacuum flag when writing meta[6]. Page-one
validation also permits a header page count beyond the file size under
`writable_schema`, clamping it to the physical page count as C does. These 168
newly counted cases bring the focused ledger to 324,370. The full-suite
denominator remains unmeasured. The already-counted `incrvacuum2.test` and
`incrvacuum3.test` were rechecked after the change: 31/31 and 53/53 pass on
both FreeBASIC backends and C, with matching labels and no tracked leaks.


## Date-function context and regression checkpoint (2026-10-17)

The unchanged upstream `date2.test` passes 30/30, `date3.test` passes 127/127,
`date4.test` passes 24,860/24,860, and `date5.test` passes 875/875 on native
FreeBASIC, GCC-backend FreeBASIC, and C `testfixture`. All emitted case labels
match across the three runs, and both FreeBASIC runs finish with zero tracked
SQLite allocations.
The Tcl runner skips the fixture's threaded-test phase because its `tclsh`
process has no `sqlthread` command; these date suites do not exercise that
phase. No upstream test source was changed.

`sqlite3VdbeAddFunctionCall()` previously copied only bit 0 of `callContext`
into `OP_PureFunc` P5. SQLite uses the combined `NC_SelfRef` mask (`0x2e`) to
retain CHECK, partial-index, expression-index, and generated-column context.
The FreeBASIC routine now uses that same mask. Before the fix, four `date2`
cases rejected the nondeterministic date value with the wrong context in the
error message. They now match C. The 875 newly counted `date5.test` invocations
bring the focused ledger to 350,262; the full-suite denominator remains
unmeasured.


## Full date regression checkpoint (2026-10-17)

The unchanged upstream `date.test` passes 1,743/1,743 on native FreeBASIC,
GCC-backend FreeBASIC, and C `testfixture`. The updated native and GCC builds
also pass `date2.test` (30/30), `date3.test` (127/127), `date4.test`
(24,860/24,860), and `date5.test` (875/875). All emitted case labels match C,
and both FreeBASIC runs finish with zero tracked SQLite allocations. The
temporary Tcl runner uses a C test-support bridge for the fake clock and
alternate localtime callback; no upstream test source changed. Threaded tests
are skipped because the `tclsh` runner has no `sqlthread` command.

The Unix `SQLITE_TEST` VFS now honors the `sqlite3_current_time` override used
by testfixture. The full `date.test` also exposed four `timediff()` cases that
returned out-of-memory for small floating-point fields. `sqlite3_str_vappendf`
now tries its bounded stack buffer before allocating scratch space.
`sqlite3FpFormatPrintf()` reports the required field capacity, so the fallback
can allocate exactly what a large value needs instead of reserving the
worst-case bound for every float. The capacity includes the exponent sign and
digits and the final NUL byte; a 3.84 MB `%E` probe now matches C. `printf.test` passes 1,439/1,439 and
`printf2.test` passes 51/51 on native FreeBASIC, GCC-backend FreeBASIC, and C
`testfixture`, with matching case labels and no tracked FreeBASIC leaks. The
temporary C test bridge wraps the FreeBASIC allocator so `printf.test`'s
failure-injection loop runs against the port. This newly covers the two
`printf-malloc` fault cases previously omitted. The 1,743 date cases and two
newly counted formatter fault cases bring the focused ledger to 352,007; the
full-suite denominator remains unmeasured.


## Varint encode/decode checkpoint (2026-10-17)

The unchanged upstream `varint.test` passes 161/161 on native FreeBASIC,
GCC-backend FreeBASIC, and C `testfixture`. All 160 emitted case labels match,
and both FreeBASIC runs finish with zero tracked SQLite allocations. A
temporary C Tcl adapter implements testfixture's `btree_varint_test` command
by calling the port's C ABI varint functions; the upstream Tcl test remains
unchanged. These 161 newly counted invocations bring the focused ledger to
352,168. The full-suite denominator remains unmeasured.


## UPSERT trigger and CTE checkpoint (2026-10-17)

The unchanged upstream `upsert2.test` passes 15/15 on native FreeBASIC,
GCC-backend FreeBASIC, and C `testfixture`, with identical case labels and no
tracked FreeBASIC leaks. It checks multi-row UPSERT with and without CTE input,
WITHOUT ROWID conflict handling, and the before-insert/before-update/after-update
trigger order. These 15 newly counted invocations bring the focused ledger to
352,183. The full-suite denominator remains unmeasured.


## NOT NULL query-planner checkpoint (2026-10-17)

The unchanged upstream `notnull.test` passes 107/107 and `notnull2.test`
passes 29/29 on native FreeBASIC, GCC-backend FreeBASIC, and C `testfixture`.
All case labels match, and both FreeBASIC runs finish with no tracked leaks.
The VM-step constraints in `notnull2.test` now pass: `sqlite3ExprCanBeNull()`
recognizes a declared NOT NULL column instead of conservatively treating every
column reference as nullable. The impossible `IS NULL` terms no longer make the
planner scan thousands of rows. A direct query-plan probe matches C's outer
table scan and partial automatic index; it uses 5 VDBE steps versus 7 for C.
These 136 newly counted cases bring the focused ledger to 352,319.

The unchanged `notnullfault.test` passes 517/517 on native and GCC FreeBASIC;
C `testfixture` passes 533. Every case label emitted by the FreeBASIC runner
also appears in the C run. C explores 16 additional allocator-failure points
because its allocation paths have more fail sites. A temporary C test adapter
provides the needed testvfs and faultsim controls; no upstream test source was
changed. These 517 newly counted fault cases bring the focused ledger to
352,836. The full-suite denominator remains unmeasured.


## UPSERT target analysis checkpoint (2026-10-17)

The unchanged upstream `upsert3.test` passes 8/8 and `upsert4.test` passes
129/129 on native FreeBASIC, GCC-backend FreeBASIC, and C `testfixture`. Case
labels match across all three runs, and both FreeBASIC runs finish with no
tracked SQLite allocations. Along with the previously recorded `upsert2.test`,
these suites exercise conflict-target matching, expression and collation
indexes, CTE input, WITHOUT ROWID tables, and trigger ordering. These 137
newly counted invocations bring the focused ledger to 352,973; the full-suite
denominator remains unmeasured.


## Foreign-key test checkpoint (2026-10-17)

The unchanged upstream `fkey3.test` passes 32/32 and `fkey4.test` passes 7/7
on native FreeBASIC, GCC-backend FreeBASIC, and C `testfixture`. Case labels
match across all three runs, and both FreeBASIC runs finish with no tracked
SQLite allocations. The unchanged upstream `fkey1.test` passes 27/27 and
`fkey2.test` passes 1,217/1,217 on native FreeBASIC, GCC-backend FreeBASIC, and
C `testfixture`; all case labels match, and the FreeBASIC runs finish with no
tracked SQLite allocations. The `fkey2.test` runner uses SQLite's existing C
`test8.c` virtual-table helper. Its temporary malloc-fault adapter is disabled
because enabling that adapter makes three VDBE search-count checks read zero;
`fkey2.test` does not request allocation-failure injection. These runs
reconfirm cases already included in the earlier 1,441-case `fkey1.test` through
`fkey8.test` sweep, so the focused ledger remains 352,973. The full-suite
denominator remains unmeasured.


## EXPLAIN and debug bytecode differential checkpoint (2026-10-17)

A direct C API probe was built against the C and FreeBASIC libraries with
`SQLITE_TEST`, `SQLITE_DEBUG`, `SQLITE_ENABLE_EXPLAIN_COMMENTS`, and
`SQLITE_ENABLE_PREUPDATE_HOOK` enabled. It
covered scalar and indexed EXPLAIN output, an INSERT trigger subprogram, and
integer SELECT results. The FreeBASIC opcode-name generator now emits the
second NUL that SQLite's debug formatter expects when an opcode has no synopsis.
Before this change, the formatter read past the opcode name and could report
the next string in memory as a comment. The tableless SELECT path also uses
`OP_Integer` for `EP_IntValue`, matching C for `EXPLAIN SELECT 1`. INSERT debug
code now emits the rowid and unique-index abortability checks, no-op labels,
and temporary index-register release markers.

The native and GCC debug-profile builds complete, and their probe output is
byte-identical. C and FreeBASIC agree on the `EXPLAIN SELECT 1` rows and on the
ordinary result rows for `SELECT 1`, `SELECT 2147483648`, `SELECT -2147483648`,
`SELECT 0`, and `SELECT 1+2`. Broader EXPLAIN output still differs in some
subquery register-release annotations, P4 table/index names, transaction
comments, and trigger annotations. Those differences remain open; this probe
adds no upstream test cases to the focused ledger.


## sqlite3_exec extended-error checkpoint (2026-10-17)

A C API probe found that `sqlite3_exec()` overwrote the extended error saved by
the VDBE with the primary return code from `sqlite3_step()`. For example, C
returns primary code 19 from a UNIQUE failure while
`sqlite3_extended_errcode()` still returns 2067; the FreeBASIC wrapper returned
19 for both. The wrapper now preserves the VDBE error state, clears the
connection error through `sqlite3Error()` at entry, and records its own
callback-abort and locally detected errors explicitly.

The C, native FreeBASIC, and GCC-backend probes now agree on successful INSERT,
UNIQUE failure (19/2067 and the same message), and callback abort (4/4). Native
and GCC output is byte-identical. No upstream case count was added. The C
`testfixture`, native FreeBASIC, and GCC-backend FreeBASIC all pass the unchanged
`capi3.test` 249/249, with matching labels and no tracked leaks. The temporary
runner now supplies `sqlite3_db_config`, `sqlite3_test_errstr`, VFS command
aliases, and the allocator fault simulator. This reconfirms cases already
included in the earlier C API suite tally; the focused ledger remains 352,973.


## UTF-16 prepare extended-error checkpoint (2026-10-17)

A direct C API probe found that UTF-16 prepare returned the correct primary
`SQLITE_ERROR` for a query using an unknown collation, but overwrote the
connection's extended `SQLITE_ERROR_MISSING_COLLSEQ` code while applying the
API error mask. The UTF-16 wrapper now preserves the extended parser error.
C, native FreeBASIC, and GCC-backend probes all report return code 1, extended
code 257, and the same error message.

The unchanged `capi3.test` rerun passes 249/249 on C, native FreeBASIC, and GCC
FreeBASIC with matching labels and no tracked leaks. Those cases were already
included in the focused ledger, which remains 352,973.


## UTF-16 C API suite recheck (2026-10-17)

The unchanged `capi3c.test` passes 291/291 on C `testfixture`, native
FreeBASIC, and GCC-backend FreeBASIC. Case labels match across all three runs,
and both FreeBASIC runs finish with no tracked allocations. The previous
FreeBASIC attempt stopped at `capi3c-22.1` because its temporary Tcl runner did
not register SQLite's `test_error()` helper for the opened connection; adding
that registration to the runner resolved the harness gap. These cases were
already included in the focused ledger, which remains 352,973.


## C API regression recheck (2026-10-17)

The unchanged `capi2.test`, `capi3d.test`, and `capi3e.test` pass 116/116,
282/282, and 115/115 cases respectively on native and GCC-backend FreeBASIC,
and on C `testfixture`. Case labels match across all three profiles, and both
FreeBASIC runs finish with no tracked allocations. The `capi3e.test` runner
enables both UTF-16 and ATTACH and loads the existing C API adapter for
`sqlite3_open16()`. These suites were already in the focused ledger, which
remains 352,973. The unchanged `capi3b.test` also passes 23/23 in all three
profiles with matching case labels and no tracked FreeBASIC allocations; this
rechecks busy-write retry behavior across two connections.


## Shared-cache concurrency stress (2026-10-17)

The unmodified upstream `test/threadtest4.c` standalone stress program was
compiled against the C reference library and both thread-safe FreeBASIC
backends. Four-worker runs in multithread, serialized, and WAL modes each
complete 245 operations with zero errors on all three libraries. Two-worker
runs also complete 62 operations with zero errors in all three modes and
profiles. Eight-worker runs in multithread and WAL modes each complete 982
operations with zero errors on all three libraries. The test exercises
shared-cache access across three databases, concurrent reads, writes,
rollback, VACUUM, and WAL. These standalone operation counts are not Tcl
test-case invocations and do not change the focused ledger.


## Mutex mode and initialization failure checkpoint (2026-10-17)

The unchanged upstream `mutex1.test` passes 29/29, and `mutex2.test` passes
14/14 on C `testfixture`, native FreeBASIC, and GCC-backend FreeBASIC. Case
labels match in all six runs, and both FreeBASIC runs report no tracked leaks.
The temporary C adapter uses upstream `test_mutex.c`, `test_init.c`, and
`test_autoext.c`, plus small Tcl adapters for raw malloc calls and the VFS
initialization probe; the upstream tests remain unchanged. The runner skips
its generic threaded Tcl phase because `sqlthread` is not loaded; the mutex
mode checks run explicitly, and `threadtest4.c` separately covers concurrent
access.

The suites exposed three initialization mismatches in the FreeBASIC paths.
Internal engine calls now use `sqlite3MutexAlloc()` so `SQLITE_CONFIG_SINGLETHREAD`
can disable core mutexes without allocating locks, and memory allocation
continues with null no-op mutexes. Unix OS shutdown clears the cached big-lock
pointer and initialization guard so a later init uses the newly configured
mutex methods. `sqlite3_complete16()`
and the VFS find/register/unregister APIs now run auto-initialization and return
its error code as upstream does. These 43 newly passing cases bring the focused
ledger to 353,016; the full-suite denominator remains unmeasured.

Native and GCC release libraries also build with `THREADSAFE=0`; direct C ABI
smokes report `sqlite3_threadsafe()==0`, compute the expected in-memory sum,
and return `SQLITE_OK` from close. These smokes are not upstream test cases and
do not change the cumulative ledger.

## Threadless Tcl runtime recheck (2026-10-20)

The GCC backend `THREADSAFE=0`, `SQLITE_TEST`, and `SQLITE_DEBUG` profile passes
the unchanged upstream `main.test` (95/95), `func.test` (15,031/15,031),
`insert.test` (84/84), `select1.test` (199/199), and `pager1.test` (1,373/1,373).
The unchanged `wal.test` (581/581), `shared.test` (211/211), `btree01.test`
(215/215), `btree02.test` (3/3), `btreefault.test` (509/509), `savepoint.test`
(140/140), and `vacuum.test` (47/47) also pass. All twelve scripts report zero
The unchanged `mallocK.test` (3,906/3,906), `pager2.test` (2,004/2,004),
`savepointfault.test` (875/875), and `ioerr.test` (4,584/4,584) also pass. All
sixteen scripts report zero errors across 29,857 invocations, and the
allocator tracker returns to zero. Thread-dependent test sections are skipped
as expected for this profile.

`pager1.test` exposed a no-op mutex assertion mismatch at its WAL setup. When
`THREADSAFE=0`, the Unix bookkeeping mutex is null and SQLite's no-op mutex
provider reports `sqlite3_mutex_held(NULL)` as true. `unixMutexHeld()` and the
matching file mutex predicate now use that callback result even when the
mutex pointer is null. The rerun passes the WAL shared-memory purge path, and
the unchanged WAL and shared-cache suites pass in the same threadless debug
profile.


## STAT4 function-probe recheck (2026-10-17)

The unchanged upstream `analyzeF.test` passes 27/27 on current native and
GCC-backend `SQLITE_ENABLE_STAT4` builds. Case labels match, and both runs
finish with no tracked allocations. This exercises function-valued index
constraints and error handling while STAT4 builds histogram probes. The suite
was already counted in the 563-case STAT4 ANALYZE checkpoint, so this recheck
does not change the focused ledger.


## Compile-option reporting checkpoints (2026-10-17)

The compile-option list now includes `ENABLE_STAT4` only when the library is
built with `SQLITE_ENABLE_STAT4`. It also includes `ENABLE_DBSTAT_VTAB` only
when `SQLITE_ENABLE_DBSTAT_VTAB` is defined. On native and GCC thread-safe
STAT4/DBSTAT libraries, `sqlite3_compileoption_used()` returns true with and
without the `SQLITE_` prefix, and `PRAGMA compile_options` lists both options.
The upstream C library also reports both options in its enabled profile. On the
default thread-safe library, both checks report them absent while
`THREADSAFE=1` remains present. The unchanged `analyzeF.test` passes 27/27 on
both STAT4 backends with no tracked allocations. These cases were already
counted and do not change the focused ledger.

The option string for `DEFAULT_PAGE_SIZE` now reflects the active macro value.
The native and GCC test profiles built with `SQLITE_DEFAULT_PAGE_SIZE=1024`
report `DEFAULT_PAGE_SIZE=1024` and omit `DEFAULT_PAGE_SIZE=4096`, matching an
upstream C amalgamation built with the same flags. The default native profile
reports 4096 and omits 1024. The compile-option probes do not add upstream test
cases to the focused ledger.


## WAL snapshot runtime checkpoint (2026-10-17)

The unchanged upstream snapshot test family passes 205/205 on C, native, and
GCC-backend builds with `SQLITE_ENABLE_SNAPSHOT`:
`snapshot.test` (127), `snapshot2.test` (31), `snapshot3.test` (18),
`snapshot4.test` (6), and `snapshot_up.test` (23). All three builds report the
same case labels, and both FreeBASIC runs finish with no tracked allocations.
The C test sources remain unchanged; a temporary C Tcl adapter
registers the snapshot commands that SQLite's test fixture normally provides.

The test exposed a Unix VFS lock bug on the path that reopens a snapshot while
a read transaction is active. The shared-memory layer rejected a second shared
checkpoint lock from the same file handle with `SQLITE_IOERR_SHMLOCK`. UnixFile
now tracks the depth of shared locks per slot and releases all outstanding
levels when the mapping is unmapped. The direct C API probe and the upstream
suite now match C on get, compare, open, recover, free, and the associated error
cases.

These additional four suites add 78 cases to the 127 from `snapshot.test`,
bringing the focused ledger to 353,221. A separate
`wal.test` recheck in this profile stopped later because its temporary runner
does not register `faultsim_delete_and_reopen`; both C and FreeBASIC also report
the same `wal-8.2` file-size result (68,608, while the script expects 69,632).
Those rechecked cases do not change the ledger.

The unchanged `test/snapshot_fault.test` also passes 145/145 on C, native
FreeBASIC, and GCC-backend FreeBASIC with matching case labels and no tracked
FreeBASIC allocations. It exercises checkpoint, recovery, snapshot open, and
snapshot get under injected OOM, I/O, SHM, and file-open faults. Its C test
source remains unchanged; the temporary runner uses the existing C fault
injector bridge. These 145 new cases bring the focused ledger to 353,366.

With `SQLITE_ENABLE_SETLK_TIMEOUT=1`, the unchanged
`test/walsetlk_snapshot.test` passes 7/7 and
`test/walsetlk_recover.test` passes 6/6, and `test/walsetlk.test` passes 51/51
on the C reference, native FreeBASIC, and GCC-backend FreeBASIC. The API-focused
`test/walsetlk2.test` (22) and `test/walsetlk3.test` (7) also pass on all three
profiles. These verify lock timeout API behavior, shared-memory lock sequences,
and `SQLITE_SETLK_BLOCK_ON_CONNECT` in WAL and rollback modes. The snapshot and
recovery tests verify that a contended read returns `SQLITE_BUSY` within the
configured timeout without calling VFS `xSleep`; `walsetlk.test` covers writer
and checkpoint contention across process and same-process clients.

The tests exposed four omissions in the FreeBASIC port: the snapshot read path
did not bracket its initial shared checkpoint lock with the blocking timeout,
`pagerOpenWal` did not transfer the saved database handle into a new WAL,
`sqlite3WalCheckpoint` lacked timeout setup and cleanup, and Unix shared locks
skipped SQLite's nonblocking pending-byte check before taking the shared-byte
range. These paths now match `src/wal.c` and `src/os_unix.c`. All runs report no
tracked memory leaks. The shared-cache suite's 92 cases enabled by the current
test adapter also pass on C/native/GCC. The runner skips its multithreaded
fixture permutations, so this post-change run is a regression subset and adds
no ledger cases. The broader unchanged `test/wal.test` also passes 581/581 on
C/native/GCC after the Unix lock change, with no tracked leaks; this regression
rerun adds no cases. The 93 new cases bring the focused test ledger to 353,459.

The unchanged `test/walcrash.test` passes 2,971/2,971 on the C reference and
both FreeBASIC backends, using SQLite's C crash-VFS adapter. It kills child
processes at WAL write and sync points, then checks recovered rows, journal
mode, and integrity across repeated page-size and transaction-boundary cases.
All runs finish with no tracked FreeBASIC allocations. These 2,971 new cases
had brought the focused test ledger to 356,430 at that checkpoint.

The expanded unchanged `test/walfault.test` runs pass 5,238 cases on native
FreeBASIC, 5,265 on GCC-backend FreeBASIC, and 6,074 on the C `testfixture`, all
with zero failures. The allocator-fault loops visit different final indices by
backend; 942 additional case labels common to C/native/GCC and absent from the
earlier 4,273-case FreeBASIC run add to the focused ledger, bringing it to
357,372. Full allocator fault-index parity remains unverified.


## Shared-cache unlock-notify checkpoint (2026-10-17)

The unchanged `test/notify1.test` passes with `SQLITE_ENABLE_UNLOCK_NOTIFY` on
the C reference (289 invocations), native FreeBASIC (297), and GCC-backend
FreeBASIC (297), with zero failures. The allocator fault bridge reports zero
outstanding allocations after each run. The test covers callback registration,
cancellation and replacement, deadlock detection, connection closure, grouped
callbacks, and allocation failure during callback-array growth. Its fault loop
reaches four additional case labels on each FreeBASIC backend. The 277 distinct
case labels common to all three runs bring the focused ledger to 357,649.
Allocator failure indices differ by backend, so complete per-index parity is
not established. The upstream Tcl test remains unchanged; the temporary runner
provides the testfixture-only Tcl commands needed to call the library.

The notify1 test exposed missing blocker tracking in two B-tree conflict paths
and missing VDBE autocommit notification after locks were released. Both the
table-lock and writer-transaction paths now call `sqlite3ConnectionBlocked()`
with the owning connection. VDBE halt calls `sqlite3ConnectionUnlocked()`
after leaving the VDBE when autocommit has released the connection's locks.
A direct C ABI probe verifies that 20 waiters receive one callback with 20
arguments, that a callback runs immediately when no blocker remains, and that
a wait-for cycle returns `SQLITE_LOCKED`.

The unchanged `test/notify3.test` passes 34/34 test-runner invocations on the C
reference and both FreeBASIC backends, with zero tracked allocator leaks. Its
33 distinct case labels cover schema-lock errors while attaching a shared-cache
database and callback timing as blocked schemas unlock. These labels bring the
focused ledger to 357,682.

The notify3 run found a second private copy of `querySharedCacheTableLock` in
`sqlite3_bulk_btree.bas`. `sqlite3BtreeSchemaLocked()` uses this copy while ATTACH
loads an unloaded schema, so it also records the blocking connection. Both
B-tree helper copies now register blockers for incompatible table locks and
exclusive writers.


The unchanged `test/notify2.test` passes 20/20 test-runner invocations on the C
reference and both FreeBASIC backends. Its 19 labeled cases are identical
across runs. The suite launches six Tcl worker threads and compares ordinary
step calls with SQLite's blocking-step example from upstream `src/test_thread.c`.
In this environment, blocking-step completed 59.3–60.4% of attempted
transactions, compared with 17.2–18.1% for ordinary step. The test helper and
test file remain in C and Tcl; the temporary adapter only supplies the C ABI
commands needed to run them against the port. These 19 new labels bring the
focused ledger to 357,701.


## Unix mmap fault checkpoint (2026-10-17)

The unchanged `test/mmapfault.test` passes 203/203 test-runner invocations on
the C `testfixture` and 87/87 on each FreeBASIC backend, with zero failures.
The FreeBASIC test profile links the upstream I/O fault counters to the Unix VFS,
so the run injects OOM, I/O, `SQLITE_FULL`, shared-memory, and cannot-open errors
while mmap and cache spill are active. Native and GCC FreeBASIC report zero
outstanding allocator records. All 86 distinct FreeBASIC fault labels match
labels passed by C; the C allocator reaches 116 additional failure indices
because its allocation sequence differs. The earlier run had already counted
82 of the common labels; four newly reached fault labels, including two I/O
failpoints, bring the focused ledger to 357,787. The upstream test remains
unchanged; the FreeBASIC runner loads upstream `src/test_vfs.c` as a temporary
C VFS adapter.


## Unix I/O error checkpoint (2026-10-17)

The unchanged `test/ioerr.test` passes on the C reference with 10,885/10,885
invocations. A FreeBASIC `SQLITE_TEST`/`SQLITE_DEBUG` profile with a 1024-byte
default page size passes all enabled cases on both native and GCC backends:
0 errors out of 4,315 invocations on each, with zero tracked allocations at
shutdown. The test runner omits the
crashtest-only `ioerr-6` group. C and FreeBASIC exercise different I/O counts,
so 3,971 distinct labels common to both runs add to the focused ledger, which
now stands at 361,758. The total full-suite denominator remains unmeasured.

The debug run exposed a B-tree mutex deadlock during VACUUM. `OP_RowCell`
already runs under the VDBE's declared B-tree lock set, so
`sqlite3BtreeTransferRow()` no longer takes a raw second mutex. The fault suite
also showed that post-super-journal phase-two cleanup must disable simulated
I/O errors, and that a rollback I/O error must replace a stale UNIQUE error
message. Both paths now match the upstream cleanup and error-promotion rules.
The default release library and both matched debug/test libraries build; the
focused `ioerr-5.49` and `ioerr-10.27` fault points pass. Upstream C and Tcl
test sources remain unchanged; the fixture adapters and run logs are kept in
`/tmp/sqlite_fb_tests`. A separate public C API smoke on the thread-safe release
library copied a 300-row table and index through VACUUM, then returned
`integrity_check=ok`.


## Incremental-vacuum I/O fault checkpoint (2026-10-17)

The unchanged `test/incrvacuum_ioerr.test` passes on C (4,394 invocations),
native FreeBASIC (4,315), and GCC-backend FreeBASIC (4,219), with zero errors
and zero tracked allocations on both FreeBASIC backends. The FreeBASIC runs
exercise the autovacuum pager path with I/O injection enabled, including the
shared-cache case. The 4,200 distinct labels common to C/native/GCC bring the
focused ledger to 365,958. The upstream test remains unchanged; its C runner
output was taken from the active full-suite baseline, and the FreeBASIC Tcl
adapters remain under `/tmp/sqlite_fb_tests`.


## File-descriptor and read-only VFS checkpoint (2026-10-18)

The unchanged `test/misc7.test` passes on a C reference run, native FreeBASIC,
and GCC-backend FreeBASIC with a 1,024-descriptor limit: 1,198, 1,201, and
1,120 invocations respectively, with zero errors and no tracked FreeBASIC
allocations. The 1,117 distinct labels common to all three runs bring the
focused ledger to 367,075. The shared-cache and virtual-table portions use the
upstream C test-support modules `src/test8.c` and `src/test9.c` as temporary
Tcl extensions; upstream test sources remain unchanged.

This suite exposed a Unix VFS error-code mismatch. When a new journal cannot
be created because its containing directory is read-only, the port now returns
`SQLITE_READONLY_DIRECTORY`, matching upstream `src/os_unix.c`. This fixes the
read-only-directory cases `misc7-23.3` and `misc7-23.4` on both FreeBASIC
backends.


## C testfixture linked to the FreeBASIC engine (2026-10-18)

A temporary upstream `testfixture` build now links its unchanged C test
support to the FreeBASIC shared library. The link map contains no SQLite C
engine objects. Its focused test selection matches the FreeBASIC library's
runtime capabilities. The initial full run stopped in `sysfault.test`; a later
run completed all 1,516 jobs and recorded its failures in the test ledger.
The test-only `SQLITE3_FB_TEST_CONFIG_SYNC` profile mirrors
heap, page-cache, lookaside, and shared-cache fields into the C fixture's
compatibility record. This is configuration synchronization, not a general
translation layer for private C structure offsets. Some unchanged C test
helpers still inspect `sqlite3`, `Vdbe`, and B-tree records directly; those
helpers require port-specific accessors when the FreeBASIC private layout is
different. Direct C writes to the fake-heap sentinel are not reflected in the
port, so sorter paths controlled by that sentinel remain unverified. The
October 21 test runs below document two such helper gaps.

The unchanged `zeroblob.test` passes 56/56 on C, native FreeBASIC, and the GCC
backend, with 55 distinct labels common to all three. The unchanged
`interrupt.test` passes 3,099 C, 3,034 native, and 3,041 GCC-backend
invocations; 3,006 distinct labels are common to all three. These 3,061 new
labels bring the focused ledger to 370,136. Both FreeBASIC backends report no
errors and no tracked leaks.

The unchanged `like.test` passes 159/159 on all three builds, and
`conflict.test` passes 154/154 on native and GCC-backend FreeBASIC through this
fixture. These labels were already counted in earlier LIKE and conflict
checkpoints. The tests exercise the linked LIKE call counter and temporary
file-open counter.

The VFS cleanup at the end of `zeroblob.test` exposed that
`sqlite3_vfs_unregister(NULL)` dereferenced a null pointer. The port now skips
the list-link reset for a null VFS, matching upstream's harmless no-op path.


## Sort fault suite through the linked fixture (2026-10-18)

The unchanged `sortfault.test` passes 33,916/33,916 on C, 38,144/38,144 on
native FreeBASIC, and 38,144/38,144 on the GCC backend, with no errors or
tracked leaks. The three runs share 33,915 distinct labels. Archived FreeBASIC
runs already cover 20,657 of those C-common labels; the 13,258 additional
labels bring the focused ledger to 383,394. The test-only configuration mirror
keeps the C fixture's page-cache and lookaside observations synchronized with
the port while the allocator-fault matrix runs.


## Allocation fault matrix through the linked fixture (2026-10-18)

The unchanged `malloc.test` passes 18,914/18,914 cases on native FreeBASIC and
18,918/18,918 on the GCC backend, with no errors or tracked leaks. The C
reference run logged 19,419 passing labels; 17,632 labels are common to C and
both FreeBASIC backends. Those new labels bring the focused ledger to 401,026.
The differing totals reflect backend-specific allocation sequences during
fault injection.

This run fixed two temporary fixture layout assumptions. `test1_fb.c` now reads
the port's `mallocFailed` field through a test-profile-only accessor, and the
fake B-tree connection in `test3_fb.c` locks its stored `sDb.mutex` directly.
These changes let the unchanged connection-function and crash-recovery tests
run through their actual injected failures without reading the port's
connection record as a C `sqlite3` structure.

The sorter OOM case `malloc-40.3-oom-transient.53` exposed a second issue:
record comparison could turn a failed UTF-16 conversion into an equal-key
result and continue with partially sorted rows. The port now passes the
unpacked record's error byte through SQLite's collation conversion helper and
keeps that error set until sorter setup. The exact case and the full malloc
fault suite pass on both backends.


## Unix system-call faults and function encoding (2026-10-18)

The unchanged `sysfault.test` passes 1,546/1,546 on native and GCC-backend
FreeBASIC, with no tracked allocations at shutdown. The tests exposed three
Unix VFS mismatches: two lock checks retried `EINTR` where upstream makes one
`fcntl()` call, the main truncate callback bypassed `robust_ftruncate()`, and
the `seekAndRead()` retry path did not set the positive loop value used by the
upstream `do-while` loop. Each path now follows the upstream behavior.

The unchanged `enc2.test`, `func3.test`, and `func.test` pass on both backends:
90/90, 40/40, and 15,031/15,031. These runs found that
`sqlite3_create_function_v2()` replaced a registered callback for a different
text encoding. The public API now uses the ported `sqlite3CreateFunc()` path,
which preserves separate UTF-8 and UTF-16 registrations and shared destructor
references. A test-profile accessor supplies the connection encoding to the
temporary C fixture adapter without reading the FreeBASIC record as a C
`sqlite3` structure. The `func-15.1` null-error case now reports an empty
message instead of leaving prior VM error text in place.

After the full run, `badutf.test` passes 37/37 and
`tkt-78e04e52ea.test` passes 9/9 on C, native FreeBASIC, and GCC-backend
FreeBASIC. The unchanged `hexlit.test` passes 133/133 on C, native, and GCC.
The C-common passing labels from `sysfault.test`, `enc2.test`, `badutf.test`,
`tkt-78e04e52ea.test`, and `hexlit.test` add 1,529 distinct cases and bring
the focused ledger to 402,555. The native and GCC release libraries also
rebuild with the fixes, and the test-only encoding accessor is absent from
both.

## Min/max aggregate collation (2026-10-18)

The aggregate `minmaxStep()` now obtains the active function collation using
`sqlite3GetFuncCollSeq()` and passes it to `sqlite3MemCompare()`, matching
upstream `src/func.c`. Previously it compared with a null collation, so
`min(x COLLATE nocase)` and `max(x COLLATE nocase)` silently used binary order.

The unchanged `minmax3.test` passes 48/48 on C, native FreeBASIC, and
GCC-backend FreeBASIC, with no tracked allocations. Its 10 collation failures
in the prior retest are cleared. The related `collate8.test` passes 24/24 on
all three builds, and `window1.test` passes 349/349 on C and 348/348 on each
FreeBASIC backend; these latter suites were already in the focused ledger.
The 48 C-common labels from `minmax3.test` bring the focused ledger to 402,603.

## Compile-option feature profile (2026-10-18)

`sqlite3_compile_options.bas` now reports the enabled `DEBUG`, `TEST`,
bytecode-vtab, dbpage-vtab, explain-comment, math, MEMSYS5, percentile, and
where-trace options. The feature-enabled test library also registers the
ported dbpage, dbstat, and bytecode modules. This makes the reported SQLite
configuration match the features present in these builds.
The `sqlite3_compileoption_used()` C API probe returns true for both prefixed
and unprefixed math and virtual-table options, and reports `DEBUG` and `TEST`.
The test profile sets `SQLITE_TEST`, `SQLITE_DEBUG`, a 1 KiB page size, and the
ported BYTECODE_VTAB, CARRAY, DBPAGE_VTAB, DBSTAT_VTAB, EXPLAIN_COMMENTS,
MATH_FUNCTIONS, MEMSYS5, PERCENTILE, PREUPDATE_HOOK, UNLOCK_NOTIFY, and
WHERETRACE options.

The native feature profile passes unchanged `dbpage.test` 34/34,
`dbpagefault.test` 1,075/1,075, `stat.test` 41/41, `statfault.test` 1,298/1,298,
`percentile.test` 128/128, `carray01.test` 31/31, `carray02.test` 19/19, and
`carrayfault.test` 238/238, with no tracked allocations. The unchanged
`func7.test` passes 74/74 when the temporary Tcl adapter sets the `mathlib`
capability; its C test configuration was built with that capability disabled.
The tests themselves remain unchanged. The fault-simulation output adds 610
new C-common labels from `statfault.test` beyond the earlier 684-case profile,
and 912 common labels from `dbpagefault.test`. The other feature-profile
rechecks were already represented in the focused ledger. The two new label
sets bring the total from 402,603 to 404,125.

## Compound SELECT LIMIT sharing (2026-10-18)

The ordered left term of a `UNION ALL` may allocate the LIMIT register before
it emits its bounded sorter. `sqlite3SelectCompileFromClause()` now keeps that
new register on the SELECT after successful code generation, so the compound
parent reuses the decremented counter for its right term. When OFFSET is
present, it also reserves the `LIMIT+OFFSET` register even if the current
term has no sorter; the next term's sorter uses that shared register. Error
cleanup still restores the original SELECT state. Previously the restore
cleared the LIMIT register and the unreserved OFFSET register overlapped with
result-row registers.

The unchanged `tkt-38cb5df375.test` now passes 294/294 on C, native FreeBASIC,
and GCC-backend FreeBASIC, with no tracked allocations. The unchanged
`offset1.test` passes 28/28 on all three backends; its 12 malformed-database
errors in the prior feature-profile retest are cleared. These results add 293
and 27 C-common labels respectively, bringing the focused ledger from 404,125
to 404,445. `limit.test` passes 123/123, `limit2.test` 25/25, and
`orderby1.test` 65/65 on all three backends; those rechecks were already
counted.

## Subtype clearing at soft-collate boundaries (2026-10-18)

`sqlite3SelectCompileExpr()` now clears `MEM_Subtype` after compiling the left
expression of a `TK_COLLATE` node whose `EP_Collate` flag is unset. These
soft-collate nodes are introduced when predicates are pushed into subqueries;
the clear matches upstream `sqlite3ExprCodeTarget()` and prevents JSON result
subtypes from changing `json_quote()` behavior across a view boundary.

The unchanged `subtype1.test` passes 34/34 on C, native FreeBASIC, and
GCC-backend FreeBASIC, with no tracked allocations. The 33 C-common labels
bring the focused ledger from 404,445 to 404,478.

## Immutable pager page count and no-lock tests (2026-10-18)

Immutable pagers enter directly in the reader state and skip the ordinary
shared-lock transition. `sqlite3PagerOpen()` now initializes their database
page count from the already-open file after setting the pager page size. This
keeps page 1 available to the B-tree layer without checking or replaying a hot
journal. The pager still opens immutable files read-only and skips VFS locking.

The unchanged `nolock.test` passes 26/26 on C `testfixture`, native FreeBASIC,
and GCC-backend FreeBASIC, with no tracked FreeBASIC allocations. This clears
the nine failures recorded for that file in the prior full-suite retest. The
26 shared labels bring the focused ledger from 404,478 to 404,504. The fresh
1,516-job feature-profile run then confirmed 26/26 in the full harness. Native
and GCC release libraries rebuild successfully; `sqlite3_compileoption_used()`
is exported, and the test-only connection-encoding accessor remains absent
from both release libraries.

## Unix VFS chunk-size truncation (2026-10-18)

`unixTruncateFile()` now rounds physical file truncations up to the configured
`SQLITE_FCNTL_CHUNK_SIZE`, matching `src/os_unix.c`. The previous path applied
the requested logical size directly, so auto-vacuum and WAL checkpoint
truncations discarded the reserved chunk space. The mmap length is reduced
after a truncate when the remaining file is smaller than the current mapping.
Rounding checks for signed 64-bit overflow before calculating the chunk edge.

The unchanged `fallocate.test` passes 19/19 and `chunksize.test` passes 7/7 on
C, native FreeBASIC, and GCC-backend FreeBASIC. `sysfault.test` also passes on
all three profiles after the VFS change; each run reports zero errors and no
tracked FreeBASIC allocations. The 23 distinct shared labels from the first
two suites bring the focused ledger from 404,504 to 404,527. The subsequent
full feature-profile run completed in 22:16 with 314 errors across 68 failed
jobs, down from 326 errors in the prior full run. The focused suites identify
the chunk-size regression fix. The full run still has unrelated outstanding
failures; the subsequent failed-job retest recorded above clears the iif and
pager adapter failures.

## Inline iif() in tableless SELECT (2026-10-18)

The tableless SELECT compiler handled `coalesce()`, `ifnull()`, and `nullif()`
inline but sent `iif()` and `if()` through `OP_Function`. Their placeholder
callback returns no value, so `iif()` produced NULL. `sqlite3SelectCompileExpr()`
now recognizes the built-in inline function ID and routes its argument list
through the existing CASE compiler. This keeps branch evaluation lazy and
leaves application-defined functions with those names on the normal callback
path.

The unchanged `e_expr.test` passes 16,619/16,619 on C, native FreeBASIC, and
GCC-backend FreeBASIC. Its 16,592 distinct shared labels bring the focused
ledger from 404,527 to 421,119. The related `indexexpr1.test` passes 117/117
and `percentile.test` passes 128/128 on all three profiles; those labels were
already in the ledger.
A direct short-circuit probe also returns 42 and 43 on all three profiles
without evaluating an unselected `abs(-9223372036854775807 - 1)` branch.

## Optional extension API slots (2026-10-18)

The extension API table now fills upstream slot 172 with
`sqlite3_unlock_notify()` when `SQLITE_ENABLE_UNLOCK_NOTIFY` is enabled, slots
23, 24, and 32-35 with column metadata APIs when
`SQLITE_ENABLE_COLUMN_METADATA` is enabled, slot 240 with
`sqlite3_normalized_sql()` when `SQLITE_ENABLE_NORMALIZE` is enabled, and slots
275 and 276 with `sqlite3_carray_bind()` and `sqlite3_carray_bind_v2()` when
CARRAY and virtual tables are enabled. The FreeBASIC routines already existed;
the table had left these optional C API entries null.

A temporary C extension loaded through `sqlite3_load_extension()` calls
`sqlite3_unlock_notify()`, both CARRAY bind entries, UTF-8/UTF-16 column
metadata, and normalized SQL in feature-enabled builds. It binds an integer
array and reads the expected rows from `carray(?1)`. Its two Tcl cases pass on
native and GCC with no tracked allocations. The unchanged `loadext.test` passes
68/68 and `loadext2.test` 23/23 on both backends; CARRAY01/02 pass 50/50.
C2FB's API-table generator restores these optional slots with compile-time
guards when the upstream preprocessed initializer contains zero entries for
disabled features. The default release library builds successfully with
CARRAY, unlock-notify, column metadata, and normalization disabled, leaving
those optional slots absent when their features are not compiled.

## Omitted-feature build checks (2026-10-18)

The generated extension API table also preserves the `loadext.c` guards for
UTF-16, virtual-table, incremental-BLOB, WAL, mutex, authorization, tracing,
compile-option diagnostics, and other optional API entries.
`SQLITE_OMIT_UTF16`, `SQLITE_OMIT_VIRTUALTABLE`, and `SQLITE_OMIT_WAL` GCC
test-profile libraries build successfully, as do `SQLITE_OMIT_DEPRECATED` and
`THREADSAFE=0` profiles. Standalone C API hosts confirm that omitted API
pointers remain null; the deprecated profile also checks that legacy
trace/profile slots are null, and the threadless profile checks all five mutex
slots. The virtual-table-omitted host creates, inserts, and reads an ordinary
table, and the WAL-omitted host passes the same DDL/DML check. The
OMIT_VIRTUALTABLE build excludes vtab-only C2FB shards and uses neutral
internal helpers only in that profile. Pager commit, rollback, and filename
packing now guard WAL state the same way as SQLite.
`SQLITE_MUTEX_OMIT` is derived from `SQLITE_THREADSAFE=0`, matching upstream
`src/mutex.h`.
`SQLITE_OMIT_INCRBLOB` also builds successfully after excluding the `vdbeblob.c`
translation shard. A standalone C extension confirms all six incremental-BLOB
API entries are null, while a basic CREATE/INSERT/SELECT host check succeeds.


## Windows VFS build checks (2026-10-19)

`FB_OS=windows` defines `SQLITE_OS_WIN`, selects the Win32 VFS, and excludes
the Unix VFS and its C2FB shards. The profile passes `-asm att` for the
Windows atomic helper and links MinGW runtime libraries. With a configured
Win64 MinGW compiler and FBC runtime prefix, build with:

```sh
make -C fb_src FB_OS=windows FB_TARGET=win64 \
  FBC='fbc -gen gcc -prefix /path/to/fbc-win64-prefix' \
  TARGET=build/sqlite3-fb-win64.dll
```

For an i686 MinGW toolchain, set the target triplet explicitly:

```sh
PATH=/path/to/i686-mingw/bin:$PATH make -C fb_src \
  FB_OS=windows FB_TARGET=win32 \
  FB_TARGET_FLAGS='-target i686-w64-mingw32 -asm att' \
  FBC='fbc -gen gcc -prefix /path/to/fbc-win32-prefix' \
  TARGET=build/sqlite3-fb-win32.dll
```

FBC and Clang compile all 502 selected source units to COFF objects for both
Win64 and Win32. The Win64 profile links a 9.3 MB DLL that exports
`sqlite3_open`, `sqlite3_exec`, and the public SQLite API. A MinGW C host links
against its import library and passes a file-backed create/insert/select smoke
test under Wine 10.

The Win32 profile also links a 9.0 MB DLL and import library. Its C API host
runs under Wine 10 and exercises an in-memory database, file-backed writes,
64-bit rowids, WAL mode and checkpoint, reopen, and `PRAGMA integrity_check`.
The unchanged upstream C tests `test/c/malloc1.c` and `test/c/snprintf1.c`
also compile against both DLL import libraries and pass under Wine 10 on Win32
and Win64. The snprintf output matches the expected strings on each target.
These file-backed smokes exercise both Windows VFS paths. The full upstream Tcl
suite has not been run on Windows, and native Windows execution remains
unverified.

The Windows symbol audit found that `sqlite3_win32_set_directory8()` had a
FreeBASIC body but lacked the `Export` attribute. It is now exported alongside
`sqlite3_win32_set_directory()` and `sqlite3_win32_set_directory16()` in both
the Win32 and Win64 DLLs. A MinGW C host under Wine successfully sets and clears
the temp-directory override through all three entry points and verifies that
an unsupported directory type returns `SQLITE_ERROR`.

The Win64 DLL link used the current FBC compiler with the bundled Win64
`libfbmt.a` runtime from a FreeBASIC 1.10.1 package and MinGW GCC 13. The Win32
DLL used the FBC source-tree Win32 runtime with MinGW GCC 13 for i686. The VFS
and Windows mutex provider share a FreeBASIC `lock cmpxchg` implementation for
InterlockedCompareExchange, which MinGW exposes as a compiler intrinsic rather
than a DLL import. Mutex-storage alignment uses pointer-width casts on both
targets.


## Windows C varargs and shared-cache stress (2026-10-19)

C `va_list` arguments now pass through `Cva_List` by value. Passing them
`ByRef` added an extra pointer level on Windows. The unchanged upstream
`test/threadtest4.c` exposed the defect by faulting in the formatter; the same
program passed against the C reference. C2FB's declaration and body generators
now emit the value-passing signature, and the SQLite printf entry points use
the matching ABI. Direct C callers of `sqlite3_vmprintf()` and
`sqlite3_vsnprintf()` pass on Linux, Win32, and Win64.

The unchanged `test/threadtest4.c` passes under Wine 10 on Win32 and Win64.
Two-worker runs pass in multithread, serialized, and WAL modes at 62/62 checks
each. Four-worker runs pass in multithread and WAL modes at 245/245 checks each.
All runs report zero errors. An initial Win64 serialized run in a reused
directory returned `SQLITE_CANTOPEN` at `VACUUM`; a clean-directory rerun
passed 62/62.


## Windows sorter worker execution (2026-10-19)

An out-of-tree MinGW C API probe exposed a Windows temporary-name failure in
the FreeBASIC VFS. The suffix alphabet was typed as `ZString Ptr`, so indexed
access treated each suffix as a string instead of reading its byte. It is now
stored as `Const UByte Ptr`, matching the character-table layout.

The probe configures `SQLITE_CONFIG_PMASZ=10`, creates 40,000 rows with
512-byte payloads, sets `PRAGMA temp_store=FILE`, `cache_size=10`, and
`threads=4`, then verifies descending order, payload size, and
`PRAGMA integrity_check`. It passes against both Win32 and Win64 FreeBASIC
DLLs under Wine 10. A process-thread monitor sees the count rise from 2 to 6
during the sort, confirming that four sorter workers launch. A separate Win64
run with `threads=0` also passes. The upstream Windows Tcl suite and native
Windows execution remain unverified.


## Current regression checks (2026-10-19)

After the C `va_list` ABI correction, the native feature-profile library passes
the unchanged full upstream Tcl suite through the C `testfixture`: all 1,516
jobs completed, with 1,088,422 invocations and zero errors. The GCC-backend
library passes the same suite with all 1,516 jobs complete, 1,088,708
invocations, and zero errors. The runner wrapper caps `misc7.test` at 1,024
open file descriptors so its deliberate descriptor-exhaustion loop stays
bounded. Fault-injection counts vary by backend. This fixture profile disables
optional FTS3/4/5, R-Tree, GeoPoly, and Session modules, along with several
feature-specific test commands; those extension suites are outside these totals.

The earlier post-pointer-width focused run passed the unchanged tests
`altertab.test` (120), `where8.test` (2,052), `expr.test` (661),
`dbstatus.test` (154), `incrvacuum.test` (168), `table.test` (97), and
`json106.test` (45,001), for 48,253 records per backend. The full runs above
also cover these tests after the `va_list` correction.


## `SQLITE_OMIT_AUTOINIT` profile (2026-10-18)

The GCC FreeBASIC library builds successfully with `SQLITE_OMIT_AUTOINIT`.
Unchanged `test/c/malloc1.c` and `test/c/snprintf1.c` were compiled with the
same option and linked separately to the FreeBASIC library and to the C
amalgamation reference. Both tests pass on both engines; `snprintf1` output
matches byte for byte. These tests explicitly call `sqlite3_initialize()`
before using the allocator and formatting APIs, as required by this profile.


## `SQLITE_OMIT_SHARED_CACHE` profile (2026-10-18)

The GCC test-profile library builds with `SQLITE_OMIT_SHARED_CACHE`. A
standalone C extension loaded through SQLite checks that
`sqlite3_api_routines.enable_shared_cache` is null. A C host also performs
CREATE, INSERT, and SELECT through the FreeBASIC library. The same extension
and database-operation probe passes against a C amalgamation compiled with the
same omission option.


The same `SQLITE_OMIT_SHARED_CACHE` library also passes unchanged
`e_uri.test` (65/65), `attach.test` (113/113), `mutex1.test` (16/16), and
`thread001.test` (1/1) through the C testfixture adapter with zero errors.
The upstream capability checks skip shared-cache-only cases in this profile.


## R-Tree integrity-check cleanup (2026-10-19)

The optional `SQLITE_ENABLE_RTREE` feature profile now links all 116 R-Tree
procedure bodies, including the manual `rtreeInit`, `sqlite3RtreeInit`, and
`geomCallback` implementations. The unchanged upstream `test/rtree.test`
passes 39,213 invocations with zero errors and no tracked SQLite allocations.
The all-job profile above still disables optional R-Tree support, so this is
separate feature coverage.

With GeoPoly enabled in the same R-Tree test profile, `test/rtree.test` passes
39,260 invocations in the latest table-driven registration build, with zero
errors and no tracked allocations. A prior run passed 39,284; invocation
counts vary by feature profile and fault-injection settings.

The R-Tree suite exposed a VDBE reference leak in `PRAGMA integrity_check`.
The pragma stores each virtual-table `Table` pointer in a `P4_TABLEREF` operand
and increments its reference count. The shared P4 destructor lacked the
matching release. It now calls `sqlite3DeleteTable()` for `P4_TABLEREF`,
matching `src/vdbeaux.c`. A reduced C-fixture probe and the full R-Tree suite
both return tracked memory to baseline after connection close. The unchanged
`ext/rtree/rtreefuzz001.test` also passes 9/9 with no tracked allocations.


## GeoPoly runtime integration (2026-10-19)

The `SQLITE_ENABLE_GEOPOLY` profile now completes the port of
`ext/rtree/geopoly.c`. C2FB supplies 35 routine bodies; manual FreeBASIC code
adds the JSON number parser, virtual-table constructor, overloaded-function
callback, and extension initializer. The initializer registers the GeoPoly
module, its scalar functions and aggregate, and the `geopoly_overlap()` and
`geopoly_within()` planner overloads.

The unchanged `ext/rtree/rtreefuzz001.test` passes 11/11 with GeoPoly enabled,
including its two conditional GeoPoly cases, and reports no tracked SQLite
allocations at close. A direct C API smoke check matches the C reference for
table creation, insert/update, decimal and exponent coordinate parsing,
malformed JSON handling, area and point queries, JSON/SVG conversion,
bounding-box and transform functions, regular polygons, winding correction,
the group bounding-box aggregate, and overlap/within virtual-table plans.
The same successful and malformed-input paths pass a targeted Tcl smoke run
through the C testfixture, with all tracked allocations freed; the C API smoke
passes on native and GCC FreeBASIC libraries as well as the C reference.
The feature DLLs also build for Win32 and Win64, and the C API smoke passes on
both under Wine. The full Tcl R-Tree suite has not yet run on Windows.
SQLite has no dedicated GeoPoly test file, so persistence and fault-injection
paths still need broader coverage.


## FTS5 port progress (2026-10-19)

The inventory now tracks FTS5's 12 implementation C files, its public and
private headers, the Lemon grammar, and three C test-support files that remain
unported. The initial source-unit C2FB batch produced 530 of 580 routine-body
candidates across the implementation files. Six later expression helpers,
`fts5FlushOneHash()`, nine expression/parser helpers, three parser-tree helpers,
and five token-data index helpers bring the integrated C2FB body count to 554. The varint, buffer, hash, storage,
configuration, main, expression, index, Unicode-data, and tokenizer units are
now integrated. The FTS5 module registers and creates virtual tables. The
generated query parser is integrated in `sqlite3_bulk_fts5_parser.bas`; the
current full-suite results are summarized at the top of this file.

`ext/fts5/fts5_varint.c` contributes five C ABI routines in
`sqlite3_bulk_fts5_varint.bas`. Release and `SQLITE_DEBUG` builds match C for
100,022 boundary and deterministic pseudo-random integer values; the unit also
compiles with FTS5 disabled and for Win32 and Win64 targets.

`ext/fts5/fts5_buffer.c` contributes 21 C2FB bodies plus a manual
`sqlite3Fts5IsBareword()` implementation in `sqlite3_bulk_fts5_buffer.bas`.
Release and debug C API comparisons pass for buffer contents, varargs
formatting, position-list encoding and iteration, term-set duplicate handling,
and all 256 bareword byte values. Both units compile for Win32 and Win64. The
FTS5 table-creation smoke and unchanged upstream SQL suite now run.

`ext/fts5/fts5_hash.c` contributes all 16 translated routine bodies in
`sqlite3_bulk_fts5_hash.bas`. All eight upstream `SQLITE_DEBUG` assertions are
restored, including the debug-only hash-entry count helper. Release and debug
objects compile. A C
differential harness agrees across all three FTS5 detail modes with 700 terms
per mode, exercising hash-table growth, deletes, exact lookups, and sorted
scans. The FTS5 table-creation smoke passes; full-suite results are summarized
at the top of this file.

`ext/fts5/fts5_storage.c` contributes all 37 translated routine bodies in
`sqlite3_bulk_fts5_storage.bas`. All 25 upstream assertions are restored as
debug checks. Release, debug, and FTS5-disabled unit compiles pass.

`ext/fts5/fts5_config.c` contributes all 21 C2FB bodies plus a manual
`fts5ConfigParseSpecial()` implementation for its special-option table.
Release, debug, and FTS5-disabled unit compiles pass. The 2026-10-20 checkpoint
below records restoration of all upstream configuration assertions.

`ext/fts5/fts5_main.c` contributes 100 C2FB bodies in
`sqlite3_bulk_fts5_main.bas`. Manual ports provide `fts5Init()`, the module
callback table, `fts5FreeCursorComponents()`, `fts5SorterNext()`,
`fts5CursorFirstSorted()`, `fts5CsrPoslist()`, `fts5ApiInvoke()`, and the
extension API table callbacks. Release, debug, and FTS5-disabled feature
builds pass. Table creation and insert/implicit-commit smokes pass. C2FB now
supplies `sqlite3Fts5ExprClonePhrase()` for xQueryPhrase, but query and cursor
runtime coverage remains limited by the generated parser. A parser-linked smoke
has exercised prefix and token-data queries through the ported callbacks.

`ext/fts5/fts5_aux.c` contributes 15 C2FB bodies plus a manual auxiliary
registration routine for `snippet`, `highlight`, `bm25`, and `fts5_get_locale`.
The callback typedefs C2FB omitted are supplied locally; the unit compiles in
release, debug, and FTS5-disabled profiles.

`ext/fts5/fts5_vocab.c` contributes 19 C2FB bodies plus a manual
`sqlite3Fts5VocabInit()` module registration routine. Its unit compiles in
release, debug, and FTS5-disabled profiles.

`ext/fts5/fts5_expr.c` contributes 82 C2FB bodies in
`sqlite3_bulk_fts5_expr.bas`. Later batches added column-set parsing, copying,
merging, filtering, position-list cleanup, expression allocation, near matching,
tokenization, phrase cloning, switch dispatch, phrase-to-AND conversion, and
parser-node creation. It compiles in release, debug, and FTS5-disabled profiles.
The current C2FB release-profile pass translates all expression source routines.
The generated Lemon query parser is integrated in
`sqlite3_bulk_fts5_parser.bas`.

`ext/fts5/fts5_index.c` contributes 198 C2FB bodies: the initial 193 plus five
token-data index helpers. Manual ports also provide `fts5StructureMakeWritable()`,
`fts5IndexOptimizeStruct()`, `sqlite3Fts5IndexReinit()`, `Fts5Colset` layout,
document-index EOF, column-set lookup, position-list filtering, and iterator
output-selection in `sqlite3_bulk_fts5_index.bas`. Release, debug, and
FTS5-disabled unit builds pass. The FreeBASIC debug port now preserves 76
upstream assertions. These include the four invariants in
`sqlite3Fts5IndexOptimize()`, seven checks in `fts5IndexMergeLevel()`, eight
in `fts5FlushOneHash()`, 16 segment-writer checks across initialization, term
append, leaf flush, and doclist-index handling, three iterator-construction
checks in `fts5MultiIterNew()`, five in `sqlite3Fts5IndexQuery()`, and the
`bEof` checks in both `fts5DlidxLvlNext()` and `fts5DlidxLvlPrev()`, plus
`iLvl` bounds checks in `fts5DlidxIterNextR()` and `fts5DlidxIterPrevR()`. Its debug
`TEST_NOIDX` path now forces scans of the main index and honors the
`bPrefixIndex` toggle. Other index assertion sites remain under audit.

`ext/fts5/fts5_tokenize.c` contributes all 35 C2FB candidate bodies and a
manual `sqlite3Fts5TokenizerInit()` that registers `unicode61`, `ascii`,
`trigram`, and v2 `porter`. All seven active source assertions are restored.
`ext/fts5/fts5_unicode2.c` contributes all six routines and its generated
Unicode tables; differential checks match the C reference across U+0000 to
U+10FFFF, all three diacritic modes, category parsing, and ASCII maps.
Tokenizer and Unicode units compile in release, debug, and FTS5-disabled
profiles.

Release and debug `SQLITE_ENABLE_FTS5` shared-library builds link without
unresolved parser symbols. The unchanged test adapter ran all 148 upstream
FTS5 scripts against the FreeBASIC engine; current results are summarized at
the top of this file. Prefix and xInstToken queries pass through the FreeBASIC
expression and index routines, including `detail=column` and `tokendata=1`
paths. A GDB breakpoint confirms insert/commit reaches `fts5FlushOneHash()`
through `fts5IndexFlush()` and `sqlite3Fts5IndexSync()`.


## C2FB generated-record binding (2026-10-19)

C2FB body conversion now matches an existing `c2fb_<CRecord>` FreeBASIC
layout to its C record tag when a corresponding field is present in both
models. This reuses the supplied FreeBASIC storage and leaves any unmatched
fields unsupported. A regression case covers a flexible-array record with no
explicit `--type-map`; it now translates and compiles on both FreeBASIC
backends. C2FB also uses the generated tail accessor for an existing
`c2fb_` record when its flexible-array placeholder is present. Re-running the
FTS5 main source now emits candidates for `fts5SorterNext()` and
`fts5CsrPoslist()` through `c2fb_Fts5Sorter_aIdx_tail_ptr()`. Cursor cleanup
`memset()` expressions and some parser assertions and callback calls remain
C2FB gaps. Pointer subscripting now retains its pointee record type, which
let C2FB translate `fts5FlushOneHash()` from `fts5_index.c`; that body is now
integrated and reaches the FTS5 index sync path. Explicit mappings for
`Fts5Buffer`, `Fts5Iter`, and `Fts5TokenDataIter` let the source-unit pass emit
the five remaining token-data index helpers. C2FB also consumes the empty
statement after a braced `case` body; a new regression compiles and runs this
upstream C form with native and GCC backends.

C2FB now finds a local declaration's top-level initializer before tokenizing
its declarator. Large local initializers no longer consume the 256-token type
buffer: the converter now translates the 126-element automatic and 406-element
static arrays used by `fts3_unicode2.c`. A regression compiles and exercises
both array forms.

The complete C2FB regression suite passes 11,154 C/FreeBASIC behavior
comparisons on both native and GCC backends. It accepts 166 candidates and
continues to report 36 intentionally unsupported functions.


## MEMDEBUG allocator runtime checkpoint (2026-10-20)

The current-source native library was rebuilt with `SQLITE_DEBUG` and
`SQLITE_MEMDEBUG`, then linked into the unchanged C `testfixture`. The
upstream `test/malloc.test` passes 19,154/19,154, `test/malloc3.test`
passes 7,447/7,447, and `test/malloc4.test` passes 15/15. Each run reports
zero errors and no remaining SQLite allocations. The malloc tests exercise
repeated allocation failures, guard and padding checks, reallocations,
allocation titles and counts, and the allocator dump path.

The unchanged `test/altercol.test` also passes 256/256 with
`--malloctrace=1 --backtrace=4`; the trace report contains resolved C test
support and FreeBASIC allocation frames. This host lacks `eu-addr2line`, which
the upstream trace-report writer invokes, so the run used a temporary adapter
under `/tmp` that resolves live-process addresses with GNU `addr2line`. No
upstream test file or project source was changed for that adapter.

A temporary Tcl probe explicitly called `sqlite3_memdebug_log sync` while
allocations were live. The callback replay returned 11 allocation groups, and
SQLite memory usage returned to zero after `sqlite3_shutdown()`. These
MEMDEBUG results are focused coverage and have not yet been reconciled into
the distinct-label ledger.


## ICU SQL extension and UTF-16 profile (2026-10-20)

The optional `ext/icu/icu.c` integration now has FreeBASIC implementations of
all 11 routines compiled in `SQLITE_CORE` mode. They provide ICU-backed
`LIKE`, `REGEXP`, `upper()`/`lower()`, locale collation loading and comparison,
and their cleanup and error paths. `sqlite3IcuInit()` is registered in the
built-in initializer list when `SQLITE_ENABLE_ICU` or
`SQLITE_ENABLE_ICU_COLLATIONS` is enabled. The loadable-extension wrapper
`sqlite3_icu_init()` is guarded by upstream `!SQLITE_CORE` and is outside this
built-in profile.

C2FB's ICU header pass now generates 19 ABI declarations from the installed
ICU headers, including the version-suffixed regex, case-mapping, and collation
APIs used by this extension and the FTS3 ICU tokenizer. The debug combined
feature library builds with UTF-16 enabled. The unchanged `icu.test` passes
263/263, `like.test` passes 128/128, `utf16align.test` passes 7/7, and
`mallocK.test` passes 3,910/3,910, all with no tracked SQLite allocations.


## Combined-feature repair checkpoint (2026-10-20)

The unchanged `fts4min.test` exposed a min/max planner mismatch: aggregate
analysis had changed the copied rowid expression from `TK_COLUMN` to
`TK_AGG_COLUMN` before the virtual-table planner received it. The min/max order
copy now restores its source-column metadata, and `fts4min.test` passes 7/7.
Opt-in WHERE tracing prints virtual-table planner inputs and outputs when the
WHERE trace flag is set.

The `sqlite_stmt` module now measures `SQLITE_STMTSTATUS_MEMUSED` through the
count-only VDBE destructor path. This avoids treating array slices inside the
shared VDBE arenas as allocator bases. The unchanged `stmtvtab1.test` passes
8/8, and its statement memory values are below the 5,000-byte test threshold.

The FTS5 debug index port now checks four optimize invariants around flush,
structure reads, contentless deletes, and the optimized segment list, seven
segment-merge invariants, eight hash-flush invariants, and five query invariants.
The unchanged `fts5optimize.test` (49/49), `fts5merge.test` (48/48),
`fts5integrity.test` (67/67), `fts5integrity2.test` (6/6), `fts5fault1.test`
(41,890/41,890), `fts5prefix.test` (355/355), `fts5prefix2.test` (30/30), and
`fts5config.test` (71/71) pass in the refreshed UTF-16 ICU no-sync debug build:
42,516 invocations, zero errors, and no tracked leaks. These are targeted
reruns of suite scripts, not additional distinct-label counts. The previously
recorded full suite predates these debug-only changes.

The debug-only `Fts5Config.bPrefixIndex` field now appears at the C-compatible
trailing offset in all ten FTS5 config layouts. Configuration defaults it to
enabled, and the debug `prefix-index` special INSERT can toggle it. A direct Tcl
probe toggles prefix indexes off and on, verifies identical `alph*` rows, and
restores prefix indexing before running `integrity-check`. The C and FreeBASIC
debug fixtures return the same rows. The debug and release FTS5 index, config,
and main modules compile with the conditional field in place.

The large-token corruption case found an undersized float-format capacity for
large `%E` precision. The capacity calculation now accounts for the exponent
marker, sign, digits, and terminating NUL. The C fixture and FreeBASIC port
produce the same 3.84 MB output, and `fts3corrupt6.test` passes 12/12.

The Unix VFS now honors the test fixture's `SQLITE_NO_SYNC` setting by
validating file descriptors with `fstat()` while skipping disk barriers. Sync
counters and injected failure paths remain active. The no-sync debug profile
passes `sync.test` 5/5, `sync2.test` 22/22, `ioerr.test` 4,589/4,589,
`sqllimits1.test` 3,122/3,122, and `stmtvtab1.test` 8/8.
The same no-sync feature set built with FBC's GCC backend passes a focused
10,658-invocation run covering those VFS tests, min/max planning, stmtvtab,
expression handling, printf, FTS3 corruption, and allocation failure.

On the rebuilt UTF-16 debug profile, focused unchanged suites pass 6,435/6,435:
`fts4min.test` 7/7, `stmtvtab1.test` 8/8, `expr.test` 661/661, `icu.test`
263/263, `like.test` 128/128, `utf16align.test` 7/7, `mallocK.test` 3,910/3,910,
`printf.test` 1,439/1,439, and `fts3corrupt6.test` 12/12. They report no tracked
SQLite allocations.

The first combined-feature full-suite run stopped at its one-hour process
timeout after 1,016 of 1,516 jobs. At that point it had recorded 1,135,440
non-error invocations and 17 errors across seven test files. That run used the
earlier DSO, before the focused fixes above.

The ICU-enabled profile exercises the conditional ICU path in `e_fts3.test`
and replaces the built-in LIKE function. The e_fts3 script creates an ICU
`names` table but later checks that the schema is empty after dropping only the
non-ICU tables. Its `sqllimits1` pattern-length assertion targets the built-in
LIKE function; the test's own comment notes that replacement functions bypass
this runtime limit. The matched native C ICU fixture reproduces the four
`e_fts3.test` errors and the `sqllimits1-15.2` failure. The no-ICU C reference
passes `sqllimits1.test` 3,122/3,122. The matched native C ICU fixture also
returns success for `fts5bigtok2-1.1`, which expects out of memory; this
assertion fails in both engines on this host.

The first no-ICU full run used a sync-enabled library while its C fixture was
compiled with `SQLITE_NO_SYNC`; it was stopped after 333 jobs to correct that
profile mismatch. The matched UTF-16 no-sync full run completed all 1,516 jobs
in 24:17. It recorded 1,893,079 invocations: 1,893,078 passed and one failed,
`fts5bigtok2-1.1`, which expected out of memory but succeeded. The local C
reference fixture reproduces the same result. The run passed `e_fts3.test`
107,074/107,074 and `sqllimits1.test` 3,122/3,122. ICU remains covered by the
focused ICU test run above.

The earlier matched UTF-16 ICU no-sync run recorded 1,899,111 invocations and
seven errors, including a run-dependent thread-fixture failure. The fixture was
rebuilt with `TCL_THREADS=1`; eight isolated `thread004.test` runs then passed
3/3 each. The full run below uses that corrected adapter.

`sqlite3PagerMemUsed()` now estimates cache use from the C layouts. The Unix VFS
provides a `UnixFileCLayout` size record for this calculation, while the live
FreeBASIC `UnixFile` keeps its additional locking state. The estimate also
accounts for SQLite's packed filename and Pager back-pointer and excludes the
FreeBASIC-only `MemPage.aiOvflSize` bookkeeping bytes. The unchanged
`dbstatus.test` passes 154/154; `btree01.test` passes 215/215,
`btree02.test` 3/3, and `btreefault.test` 510/510, all without tracked leaks.

The matched UTF-16 ICU no-sync full run with the corrected adapter and
C-compatible cache estimate completed all 1,516 jobs in 24:17. It recorded
1,899,044 invocations: 1,899,038 passed and six errors across three jobs:
`e_fts3.test` (four), `sqllimits1.test` (one), and `fts5bigtok2.test` (one).
The matched native C ICU fixture reproduces all three failure signatures.
`dbstatus.test` and the thread test pass in this run.

The all-feature GCC-backend UTF-16 no-ICU no-sync run also completed all 1,516
jobs, in 23:47. It recorded 1,893,169 invocations: 1,893,168 passed and one
`fts5bigtok2.test` OOM-expectation failure, which also occurs with the native C
fixture. The unchanged `dbstatus.test` passes 154/154 on GCC; the targeted
`btree01.test`, `btree02.test`, and `btreefault.test` suites pass 215/215,
3/3, and 510/510 respectively, with no tracked leaks.

The all-feature GCC-backend UTF-16 ICU no-sync run completed all 1,516 jobs in
24:23. It recorded 1,899,237 invocations: 1,899,231 passed and six errors in
`e_fts3.test` (four), `sqllimits1.test` (one), and `fts5bigtok2.test` (one),
matching the native ICU run and local C reference. `dbstatus.test` passed
154/154 and `thread004.test` passed 3/3.

At this earlier checkpoint, the CSV inventory included all 125 upstream
`src/*.c` translation units with no duplicate source entries, and the routine
index marked 3,243 of 3,263 functions as having FreeBASIC bodies. The remaining
20 rows were subsequently completed; see “Final 20 indexed function bodies”
below. Body presence is not a claim of behavioral parity.

## C2FB initialization-bitfield mapping and CREATE TABLE refresh (2026-10-20)

C2FB's SQLite layout map now binds `sqlite3InitInfo.orphanTrigger`,
`imposterTable`, and `reopenMemdb` to the packed `SqliteDbInitInfo.flags` word.
A focused C-versus-FreeBASIC fixture verifies reads and writes for all three
fields, including the two-bit `imposterTable` field. A fresh `src/build.c`
translation emits `sqlite3StartTable`; that body is integrated in
`sqlite3_bulk_start_table.bas` and compiles with the module's existing ABI
interfaces. The complete default library and an all-feature debug library
both build.

Using the all-feature debug library and unchanged upstream Tcl scripts,
`minmax.test` through `minmax4.test` pass 273/273 invocations. `table.test`,
`alter.test`, `altertab.test`, and `altercol.test` pass 616/616. These checks
exercise the refreshed table-creation path and the corrected min/max debug
flag handling.

The default build also exposed `EP_NoReduce` being used outside its
`SQLITE_DEBUG` guard and cleared from `Expr.flags`. It is a debug-only VVA bit,
stored in `Expr.vvaFlags`; the SELECT path now clears that field only in debug
builds. No FreeBASIC compiler source was changed.

After these source changes, the updated all-feature debug no-sync library
completed the full unchanged Tcl suite: all 1,516 jobs in 28:21, with
1,899,592 invocations and six errors. The errors remain in `e_fts3.test`
(four), `sqllimits1.test` (one), and `fts5bigtok2.test` (one), the same
failure signatures reproduced by the matched C reference. The compile-option
sets match the earlier full run; invocation totals vary as fault-injection
jobs exercise different allocation-failure points.

The refreshed GCC-backend all-feature debug library also completed all 1,516
jobs, in 49:36, with 1,899,595 invocations and six errors. The same three jobs
failed with the same per-job counts: `e_fts3.test` (four), `sqllimits1.test`
(one), and `fts5bigtok2.test` (one). The focused `minmax.test` through
`minmax4.test`, `table.test`, `alter.test`, `altertab.test`, and `altercol.test`
pass 889/889 on both native and GCC FreeBASIC.

## Windows public API export audit (2026-10-20)

The all-feature Windows audit compared the generated FreeBASIC C API
declarations with the Win32 and Win64 DLLs and import libraries. Thirty-four
public API definitions had FreeBASIC bodies but were missing `Export`; those
definitions now carry the export attribute. The rebuilt Win32 and Win64
production DLLs and import libraries each provide 305 of 306 names in
`sqlite3_api_declarations.bi`. The only absent name is
`sqlite3_activate_cerod`, whose optional codec integration has no
implementation source in this checkout. Both targets build successfully with
the all-feature production profile.

A separate `sqlite3session.h` audit found 59 implemented Session and changeset
API functions that also lacked Windows exports. They are now exported from
both target DLLs and import libraries. The unchanged upstream
`test/c/changeblob1.c`, which calls `sqlite3changegroup_change_blob()`, links
and passes under Wine on Win32 and Win64.

The all-feature Win32 build exposed target-width conversions in the FTS5
flexible-array allocation expressions. C2FB now casts a tail address directly
to `c2fb_size_t`, which matches the FreeBASIC target's pointer width. The
flexible-array regression check passes, and its generated candidate compiles
for Win32 and Linux. The FTS5 debug alignment check and transient-destructor
sentinel in column-type generation now use the SQLite pointer-width helpers;
the complete all-feature Win32 production DLL builds.
The previous full Tcl totals predate these ABI and target-width edits. The
updated retest is recorded below. The Windows Tcl suite remains unverified.

## Full Tcl retest after ABI and target-width fixes (2026-10-20)

The updated all-feature ICU/no-sync library completed all 1,516 unchanged Tcl
test jobs in 59:31. It recorded 1,899,266 invocations: 1,899,260 passed and
six errors in `e_fts3.test` (four), `sqllimits1.test` (one), and
`fts5bigtok2.test` (one). The local C reference records the same failure
pattern; fault-injection indices vary between engines. This run uses the
SQLite API export and pointer-width fixes then present. The later Session API
export additions were separately built on both Windows targets and exercised
by `test/c/changeblob1.c`. The full console and test logs are in
`build/full-feature-debug-icu-nosync/full-run-post-winexports-20261020/`.

The refreshed GCC-backend all-feature library also completed all 1,516 jobs,
in 52:13, with 1,899,423 invocations: 1,899,417 passed and six errors in the
same three tests. This build includes the Session API exports added after the
native run. Its logs are in
`build/full-feature-debug-icu-nosync-gcc/full-run-post-session-api-20261020/`.

## Windows VFS syscall override audit (2026-10-20)

The new C API probe in `fb_src/tests/win_syscall_api.c` links against the
all-feature Win32 and Win64 DLLs and passes under Wine 10 on both targets. It
walks the VFS syscall list to its terminator, checks for duplicate entries and
the `ReadFile` entry, verifies named lookup and unknown-name results, installs
and restores a named override, and resets all overrides. It then wraps
`ReadFile`, opens a file-backed database, reads the expected row, and confirms
that the wrapper received actual database I/O. On a fresh connection it also
injects one `ReadFile` failure with `ERROR_READ_FAULT` and verifies SQLite
returns the extended `SQLITE_IOERR_READ` result before deleting the scratch
file.

This verifies the Windows VFS version-3 set/get/next callbacks and the
`ReadFile` success and error paths on both Windows architectures. The full
upstream Tcl suite has not been run on Windows, and native Windows execution
remains unverified. The probe returns zero on success and uses distinct
nonzero exit codes for failed checks; run it with the matching DLL in a
writable scratch directory.

## Seeded SQL differential probe (2026-10-20)

The C probe in `fb_src/tests/sqlite_random_diff.c` links the local C reference
archive and loads the FreeBASIC shared library into a separate glibc loader
namespace with `dlmopen()`, preventing C symbols from interposing on the port.
It verifies that both report SQLite 3.54.0, initializes equivalent in-memory
tables with integer boundaries, NULL, text, real, and BLOB values, then
generates seeded SELECT expressions with optional predicates, ordering, and
limits. For each query it compares return codes, row counts, and a 64-bit hash
of the text values returned by `sqlite3_exec()`.

Compile and run it from the repository root with:

```sh
gcc -std=c99 -O2 -Wall -Wextra -I . \
  fb_src/tests/sqlite_random_diff.c \
  fb_src/build/c-reference-icu-nosync/libsqlite3.a \
  $(pkg-config --cflags --libs icu-i18n) -ldl -lm -lpthread \
  -o /tmp/sqlite_random_diff
/tmp/sqlite_random_diff fb_src/build/libsqlite3-fb.so 50000
```

All 50,000 generated queries match between the two libraries. This bounded
differential probe supplements the unchanged upstream suite; it does not
cover transaction, file-format, or extension behavior by itself.

After the parser-profile repairs, the same C host was run against the rebuilt
default debug library with 100,000 generated queries. All 100,000 matched the
local C reference. Run the existing probe with:

```sh
/tmp/sqlite_random_diff \
  fb_src/build/cte-guard-default-debug-20261021/libsqlite3-fb-cte-debug.so \
  100000
```

The run output is saved in
`fb_src/build/cte-guard-default-debug-20261021/sqlite_random_diff-100k.log`.

## Loadable-extension OOM differential (2026-10-20)

The C probe in `fb_src/tests/loadext_oom_sweep.c` wraps the allocator through
`SQLITE_CONFIG_MALLOC`, disables connection lookaside, and injects both
transient and persistent failures. It sweeps the loader allocations used by
`sqlite3_load_extension()` and the registry allocations used by
`sqlite3_auto_extension()`. The C reference and FreeBASIC library each recover
from every injected failure, leave the connection usable, close cleanly, and
return SQLite memory usage to its baseline. The unchanged upstream
`src/test_loadext.c` extension supplies the dynamic entry point.

The loader allocation sequence has 12 failure points in both C and FreeBASIC;
every injected point returns an error, and the next point loads the extension
successfully. `PRAGMA function_list` also reports all three encodings of the
extension's `half()` and `sqlite3_status()` overloads after registration.
Automatic-extension registration has seven failure points in each engine.
The transient sweeps reject seven registrations total, and the persistent
sweeps reject 28 attempts total; each new connection invokes only the
initializers that registered successfully.

Build the C reference shared library, upstream extension, and probe from the
repository root:

```sh
gcc -shared -o /tmp/libsqlite3-c-reference.so \
  -Wl,--whole-archive fb_src/build/c-reference-icu-nosync/libsqlite3.a \
  -Wl,--no-whole-archive $(pkg-config --libs icu-i18n) -ldl -lm -lpthread
gcc -shared -fPIC -I . -Isrc src/test_loadext.c -o /tmp/libtestloadext.so
gcc -std=c99 -O2 -Wall -Wextra -I . \
  fb_src/tests/loadext_oom_sweep.c -ldl -o /tmp/loadext_oom_sweep
```

Run the same probe separately against each engine:

```sh
/tmp/loadext_oom_sweep /tmp/libsqlite3-c-reference.so /tmp/libtestloadext.so
/tmp/loadext_oom_sweep fb_src/build/libsqlite3-fb.so /tmp/libtestloadext.so
```

## Full Tcl retest after application-function hash parity (2026-10-20)

After moving application-defined functions to the per-connection `aFunc` Hash
and matching SQLite's combined `FuncDef` plus trailing name allocation, the
all-feature ICU/no-sync debug library was rebuilt and run through the unchanged
C test fixture and Tcl scripts. All 1,516 jobs completed with 1,895,644 test
invocations: 1,895,638 passed and six errors across three jobs.

The errors were the same ones seen with the C reference:

- `test/e_fts3.test`: four OOM-sweep result mismatches. C reproduces the same
  four results, with different allocation-failure indices.
- `test/sqllimits1.test`: `sqllimits1-15.2`, the LIKE/GLOB pattern limit
  expectation. The C reference produces the same result.
- `ext/fts5/test/fts5bigtok2.test`: `fts5bigtok2-1.1`, which expects an OOM
  result but succeeds. The C reference produces the same result.

The full run used `/dev/shm` for its working directory because the workspace
volume and `/tmp` quota were nearly full. The completed runner database, log,
build log, and three focused C-reference logs are stored in
`fb_src/build/full-feature-debug-icu-nosync-cstatus/full-run-post-afunc-20261020/`.

## Application-function registry Win32 and Win64 verification (2026-10-20)

After the per-connection `aFunc` change, the feature-enabled non-ICU production
library rebuilt for Win32 and Win64. The C host in
`fb_src/tests/function_registry_api.c` passes against the native C reference
and native FreeBASIC library, then passes under Wine against both Windows DLLs.
It checks mixed-case names, arity overloads, UTF-8/UTF-16LE/UTF-16BE registry
entries, UTF-16LE lookup, function replacement and removal, and callback
destruction when definitions are replaced, removed, and the connection closes.

The Win32 and Win64 DLLs, import libraries, C host executables, build logs, and
Wine results are stored in `fb_src/build/windows-function-registry/`. The full
upstream Tcl suite is still unverified on Windows.

For the Win64 import-library step, `PATH` must resolve `as` to the x86-64
MinGW assembler used by `win64-dlltool`. If it resolves to the Linux host
assembler, import-library generation fails on the PE RVA relocations after
the FreeBASIC DLL itself has linked.

## FTS5 configuration assertions (2026-10-20)

Restored all 13 `assert()` checks from `ext/fts5/fts5_config.c` in
`sqlite3_bulk_fts5_config.bas`. Each check is guarded by `SQLITE_DEBUG` and
reports through `sqlite3DebugAssert()`. The debug all-feature build and the
all-feature release build both pass.

The unchanged `fts5config.test` passes 71/71 and `fts5detail.test` passes
65/65 in the debug profile, with no tracked allocations left by either run.
The unchanged FTS5 test group completes all 148 jobs and 224,355 invocations:
224,354 pass, with one expected-out-of-memory mismatch in
`fts5bigtok2.test`, which is also present with the C reference. No FTS5
configuration assertion failed. Runner logs and the build logs are stored in
`fb_src/build/full-feature-debug-icu-nosync-cstatus/fts5-config-asserts-retest-20261020/`.

## FTS5 iterator assertions (2026-10-20)

Restored nine upstream iterator invariants under `SQLITE_DEBUG`. The doclist
iterator checks require `bEof==0` in `fts5DlidxLvlNext()` and
`fts5DlidxLvlPrev()`, and `iLvl<pIter->nLvl` in `fts5DlidxIterNextR()` and
`fts5DlidxIterPrevR()`. Reverse segment iteration checks the reverse and
one-term flags, requires no pending leaf, and verifies the leaf pointer is
empty before loading the final page. The all-feature debug and release builds
both succeed. The unchanged `fts5dlidx.test` passes 454/454. The final FTS5
group completes all 148 jobs with 224,441 invocations: 224,440 pass and the
single `fts5bigtok2` expected-OOM mismatch also seen with C. No restored FTS5
assertion failed. Logs are saved in
`fb_src/build/full-feature-debug-icu-nosync-cstatus/fts5-index-assert-final-retest-20261020/`.


## FTS5 segment-writer invariants (2026-10-20)

Restored 16 upstream checks across segment-writer initialization, term
appending, leaf flushes, B-tree flushes, doclist-index append/clear, and writer
finish. These supplement the `fts5FlushOneHash()` buffer bound added above.
At this writer checkpoint, the module had 73 `SQLITE_DEBUG` checks. Both all-feature debug
and release libraries build. The unchanged FTS5 group completes all 148 jobs
with 224,427 invocations; 224,426 pass. The only failure is
`fts5bigtok2-1.1`, which expects an OOM result but returns success. The local C
reference produces the same result. No FTS5 debug assertion failed, and the
failed test reports no outstanding allocations. Build and runner logs are in
`fb_src/build/fts5-writer-assert-retest-20261020/`.


## FTS5 multi-iterator construction assertions (2026-10-20)

Restored three upstream checks in `fts5MultiIterNew()`: allocation failure
must set an index error, the initialized segment-iterator count must equal
`nSeg`, and the output must be non-NULL unless an error occurred. All three
checks are guarded by `SQLITE_DEBUG`. The index module now has 76 restored
debug assertions. The all-feature debug and release builds pass. The unchanged
FTS5 group completes all 148 jobs with 224,305 invocations; 224,304 pass. Its
sole failure is `fts5bigtok2-1.1`, which expects OOM but returns success, the
same result produced by the C reference. No FTS5 assertion failed, and the
failed test reports no outstanding allocations. Build and runner logs are in
`fb_src/build/fts5-iter-invariants-retest-20261020/`; the C reference log is
`fb_src/build/full-feature-debug-icu-nosync-cstatus/full-run-post-afunc-20261020/c-reference-fts5bigtok2.log`.


## SELECT transformation differential (2026-10-20)

The C API host `fb_src/tests/sqlite_select_transform_diff.c` compares the
FreeBASIC release library with the local C reference in an isolated loader
namespace. Its 24 queries cover derived and compound SELECTs, recursive CTEs,
windowed subqueries, LEFT/RIGHT/FULL joins, USING and NATURAL joins, grouped
aggregates, VALUES CTEs, and INTERSECT/EXCEPT. Two queries force materialized
compound CTEs with NULL, numeric, and TEXT-affinity arms in both affinity
conflict directions. Every query returned successfully with matching row
counts and result hashes. It also runs a 384-case matrix of materialized
compound SELECT arms containing NULLs, numeric/text/blob literals, functions,
concatenations, and typed table columns. All generated cases match. The upstream
test scripts remain unchanged.

On 2026-10-21, the same host compared the rebuilt default debug library with
the C reference after the parser-profile guard changes. All 24 curated queries
and all 384 generated affinity cases still match. Output is saved in
`fb_src/build/cte-guard-default-debug-20261021/sqlite_select_transform_diff.log`.

Those affinity cases exposed a real mismatch in `sqlite3SubqueryColumnTypes()`:
when choosing the affinity of a compound result column, the port repeatedly
collected datatype flags from the leftmost expression. It now collects the
flags from each current compound arm, matching upstream. Before the fix, the
port evaluated `q.x=1` as true for the text value `1`, and `q.x='1'` as true
for an integer value, while the C reference returned false in both cases.
After the fix, all 24 curated queries and all 384 generated affinity cases
match. The unchanged `select%` and `with%` Tcl groups also pass 38,666 and
2,728 invocations.


Build and run it from the repository root:

```sh
gcc -std=c99 -O2 -Wall -Wextra -I . \
  fb_src/tests/sqlite_select_transform_diff.c \
  fb_src/build/c-reference-icu-nosync/libsqlite3.a \
  $(pkg-config --cflags --libs icu-i18n) -ldl -lm -lpthread \
  -o /tmp/sqlite_select_transform_diff
/tmp/sqlite_select_transform_diff \
  fb_src/build/subquery-column-affinity-retest-20261020/libsqlite3-fb-allfeatures-release.so
```

The probe source, pre-fix mismatches, and C/FreeBASIC row values are stored in
`fb_src/build/select-transform-diff-20261020/`. The post-fix output, including
the generated matrix result, and the `select%`/`with%` runner logs are in
`fb_src/build/subquery-column-affinity-retest-20261020/`.


## Full all-feature suite after subquery affinity repair (2026-10-20)

The unchanged Tcl suite completed all 1,516 jobs with 1,895,332 invocations;
1,895,326 passed and six failed across three jobs. `test/e_fts3.test` had four
OOM-sweep result mismatches, `test/sqllimits1.test` had the LIKE/GLOB pattern
limit case `sqllimits1-15.2`, and `fts5bigtok2.test` had its expected-OOM
mismatch. The local C reference reproduces these failure families; allocator
failure indices vary between builds. These are the same baseline cases seen in
the earlier full run.

This run used the repaired all-feature debug library and the unchanged upstream
test scripts. The five debug-only preconditions added afterward were exercised
by the metadata-enabled `select%` and `with%` runs recorded below. The full run
used `/dev/shm` because the workspace filesystem had insufficient free space.
The copied runner output, detailed test log, and runner database are stored in
`fb_src/build/full-feature-post-subquery-affinity-final-20261020/`; the C
reference logs are in
`fb_src/build/full-feature-debug-icu-nosync-cstatus/full-run-post-afunc-20261020/`.


## Column-metadata differential after affinity repair (2026-10-20)

The C host `fb_src/tests/sqlite_select_metadata_diff.c` loads a C reference and
a FreeBASIC library with `SQLITE_ENABLE_COLUMN_METADATA` in isolated loader
namespaces. It compares column names, declared types, database/table/origin
names, runtime types, and values across nine queries using tables, views,
derived tables, a limited subquery, materialized CTEs, compound-affinity
conflicts, expressions, and nested views. All nine queries match. The manual
routine also restores five upstream preconditions under `SQLITE_DEBUG`: the
SELECT is resolved, result-column counts agree unless parsing already failed,
default affinity is valid, and collated transient results have no index.

The all-feature debug metadata build passes the unchanged `select%` group
38,666/38,666 and `with%` group 2,842/2,842 without assertion failures. Build
and test logs are stored in
`fb_src/build/full-feature-debug-columnmeta-20261020/`.

Build the C reference, FreeBASIC profile, and probe from the repository root:

```sh
gcc -O2 -fPIC -shared -DSQLITE_THREADSAFE=1 \
  -DSQLITE_ENABLE_COLUMN_METADATA=1 -I . sqlite3.c \
  -ldl -lm -lpthread \
  -o fb_src/build/columnmeta-subquery-affinity-20261020/libsqlite3-c-columnmeta.so
make -C fb_src all THREADSAFE=1 \
  TARGET=build/columnmeta-subquery-affinity-20261020/libsqlite3-fb-columnmeta.so \
  FB_DEFINE_FLAGS='-d SQLITE_ENABLE_COLUMN_METADATA=1'
gcc -std=c99 -O2 -Wall -Wextra -DSQLITE_ENABLE_COLUMN_METADATA=1 -I . \
  fb_src/tests/sqlite_select_metadata_diff.c -ldl \
  -o fb_src/build/columnmeta-subquery-affinity-20261020/sqlite_select_metadata_diff
fb_src/build/columnmeta-subquery-affinity-20261020/sqlite_select_metadata_diff \
  fb_src/build/columnmeta-subquery-affinity-20261020/libsqlite3-c-columnmeta.so \
  fb_src/build/columnmeta-subquery-affinity-20261020/libsqlite3-fb-columnmeta.so
```

The probe and its output are stored in
`fb_src/build/columnmeta-subquery-affinity-20261020/`.


## WHERE-code debug invariants (2026-10-21)

`sqlite3_bulk_wherecode_one_loop.bas` now restores upstream debug assertions
that had been omitted from the translated WHERE-code routines. The IN-loop
path checks its expression and terms and rejects multi-OR planner state. The
equality-term path checks its selected term and destination register. The
index equality path checks its loop type, index, affinity storage, skip-scan
address, term pointers, and deferred allocation-failure state. Bloom-filter
pull-down checks its prerequisite mask, indexed-loop shape, and bloomability.
These checks use the shared `sqlite3DebugAssertCheck()` helper and compile only
under `SQLITE_DEBUG`.

The all-feature ICU, column-metadata, UTF-16, no-sync debug library rebuilt
successfully. The unchanged WHERE tests pass 11,374/11,374 across 28 jobs.
Bloom-filter coverage also passes: `joinD.test` 1,171/1,171,
`joinE.test` 37/37, and `bloom1.test` 28/28. None of the restored assertions
fail. The build output and test-runner logs are in
`fb_src/build/wherecode-assert-retest-20261021/`.

The production all-feature release library also passes the isolated C API
SELECT differential: all 24 curated queries and 384 generated compound-
affinity cases match the local C reference. Its build and result log are in
`fb_src/build/wherecode-production-release-20261021/`.

After the parser guard and manual equality-term rewrite, the rebuilt production
release library again matches all 24 curated SELECTs and 384 affinity cases.
The same revision also passes the eight-case indexed-IN C API host natively;
logs are `select-transform-diff-after-omitguard.log` and
`linux_where_index_api-after-omitguard.log` in the production-release build
directory.

The full unchanged Tcl suite then completed all 1,516 jobs in 45:26 with
1,932,106 invocations; 1,932,100 passed and six failed in the same three
known groups reproduced by the local C reference: four `e_fts3` OOM mismatches,
one `sqllimits1-15.2` LIKE/GLOB limit mismatch, and one FTS5 expected-OOM
mismatch. None of the restored debug assertions failed. The test fixture was
launched through the wrapper that preserves SQLite's 1,024-file-descriptor
test limit; `misc7.test` completed in 6,756 ms. Runner output, detailed test
log, and database are stored in
`fb_src/build/full-feature-post-wherecode-assert-20261021/`.

The updated Win32 and Win64 all-feature debug DLLs also build. The C API host
`fb_src/tests/win_where_index_api.c` passes eight indexed IN-query cases under
Wine on both targets. It covers leading-column lists, an `IN (SELECT)` loop,
two-column row-value IN on a composite index, equality-prefix IN, descending
index order, rowid IN, and NULL-list handling. Build logs and host results are
stored in `fb_src/build/wherecode-win32-debug-20261021/` and
`fb_src/build/wherecode-win64-debug-fixed-20261021/`.

The Win32 and Win64 production release DLLs, built with `SQLITE_DEBUG`
disabled, also pass the same eight cases under Wine. Their build logs and
probe results are in `fb_src/build/wherecode-win32-release-20261021/` and
`fb_src/build/wherecode-win64-release-20261021/`.


## `SQLITE_OMIT_SUBQUERY` parser guard (2026-10-21)

The first `SQLITE_OMIT_SUBQUERY` build exposed two unguarded calls to
`sqlite3PExprAddSelect()` in the FreeBASIC `YYRULE_EXPR_IN_LIST` action. The
upstream Lemon grammar removes the IN productions under this option, so the
FreeBASIC action now uses the same guard. The equality-term caller also guards
its `codeINTerm()` declaration and call, avoiding an unresolved symbol when
IN code generation is omitted.

Both the `SQLITE_DEBUG` and production-release `SQLITE_OMIT_SUBQUERY`
libraries build and load without unresolved shared-library symbols. A 2,000-
query seeded C API differential passes against the C reference in both
profiles; its generator uses scalar expressions without subqueries. The C API
host `fb_src/tests/sqlite_omit_subquery_api.c` confirms that scalar SELECT
works while IN-list, scalar-subquery, and derived-table syntax are rejected in
both profiles. The FROM-subquery and `paren_exprlist` reduction cases now also
follow the `SQLITE_OMIT_SUBQUERY` grammar guards, and the updated host passes in
both debug and production-release profiles.
The rebuilt default all-feature debug library also passes unchanged
`in.test` (127/127) and `in2.test` (2,000/2,000), with no tracked allocations
left. Build and probe results are in
`fb_src/build/omit-subquery-debug-20261021/`,
`fb_src/build/omit-subquery-release-20261021/`, and
`fb_src/build/omitguard-default-tests-20261021/`.

The full Tcl-suite result above predates this parser-guard and equality-term
rewrite. Current default-profile coverage is the C differential plus the
unchanged `in.test` and `in2.test`; a new full-suite run has not been done yet.
The saved Windows DLL probes also predate this rewrite. Their temporary FBC and
MinGW prefixes in `/tmp` were removed before a rebuild could be completed, so
the latest source has not been reverified on Windows.


## `SQLITE_OMIT_CTE` parser guard (2026-10-21)

An optional-profile audit found that the static Lemon tables still contain the
CTE rules, and the FreeBASIC semantic dispatcher was applying those reductions
even when `SQLITE_OMIT_CTE` was set. The CTE reduction cases now follow the
guards in `src/parse.y`. In the omit profile, scalar `SELECT` remains available
while ordinary and recursive CTE statements return `SQLITE_ERROR`.

The production `SQLITE_OMIT_CTE` library builds and loads without unresolved
symbols. The C API host `fb_src/tests/sqlite_omit_cte_api.c` passes. A debug
default-profile library also builds and continues to execute ordinary,
recursive, and materialized CTEs with the expected results. Build outputs and
probe results are in `fb_src/build/omit-cte-parser-audit-20261021/` and
`fb_src/build/cte-guard-default-debug-20261021/`.


## `SQLITE_OMIT_COMPOUND_SELECT` parser guard (2026-10-21)

The static Lemon tables also retain compound-SELECT rules when
`SQLITE_OMIT_COMPOUND_SELECT` is set. Before this fix, the FreeBASIC semantic
dispatcher still reduced UNION, INTERSECT, and EXCEPT statements in that
profile. The compound-operator and compound-SELECT reductions now use the
matching `src/parse.y` guard.

The production omit-profile library builds without unresolved symbols. The C
API host `fb_src/tests/sqlite_omit_compound_select_api.c` confirms that single
SELECT works and UNION, UNION ALL, INTERSECT, and EXCEPT return
`SQLITE_ERROR`. The rebuilt debug default profile still returns the expected
rows for those operators and for a recursive CTE. Build and probe results are
in `fb_src/build/omit-compound-parser-audit-20261021/` and
`fb_src/build/cte-guard-default-debug-20261021/`.


## `SQLITE_OMIT_CAST` parser guard (2026-10-21)

The static Lemon tables still contain the CAST rule when
`SQLITE_OMIT_CAST` is set. The FreeBASIC semantic dispatcher now guards that
reduction as `src/parse.y` does. The production omit-profile library builds
without unresolved symbols. The C API host
`fb_src/tests/sqlite_omit_cast_api.c` confirms scalar SELECT works and CAST
syntax returns `SQLITE_ERROR`; the default debug profile still evaluates
`CAST(1 AS TEXT)` to `1`. Build and probe results are in
`fb_src/build/omit-cast-parser-audit-20261021/` and
`fb_src/build/cte-guard-default-debug-20261021/`.

A combined build with all four omission options enabled also loads without
unresolved symbols. Its C API probe confirms that `SELECT 1` works while CAST,
IN, scalar and FROM subqueries, compound SELECT, and CTE syntax are rejected.
The build is in `fb_src/build/omit-parser-combined-20261021/`.


## `SQLITE_OMIT_EXPLAIN` parser guard (2026-10-21)

The static Lemon tables retain the EXPLAIN reductions when
`SQLITE_OMIT_EXPLAIN` is set. The semantic dispatcher now guards both EXPLAIN
forms to match `src/parse.y`. The production omit-profile library builds
without unresolved symbols. The C API host
`fb_src/tests/sqlite_omit_explain_api.c` confirms ordinary SELECT works while
EXPLAIN and EXPLAIN QUERY PLAN return `SQLITE_ERROR`. Build and probe results
are in `fb_src/build/omit-explain-parser-audit-20261021/`.


## `SQLITE_OMIT_TEMPDB` parser guard (2026-10-21)

The static Lemon tables retain the TEMP modifier reduction when
`SQLITE_OMIT_TEMPDB` is set. The FreeBASIC semantic dispatcher now guards that
reduction to match `src/parse.y`. The production omit-profile library builds
without unresolved symbols. The C API host
`fb_src/tests/sqlite_omit_tempdb_api.c` confirms main-database tables remain
available while `CREATE TEMP TABLE` returns `SQLITE_ERROR`; the default debug
profile still creates temporary tables. Build and probe results are in
`fb_src/build/omit-tempdb-parser-audit-20261021/`.


## Combined omitted-parser profile (2026-10-21)

The combined profile enables `SQLITE_OMIT_CTE`,
`SQLITE_OMIT_COMPOUND_SELECT`, `SQLITE_OMIT_SUBQUERY`, `SQLITE_OMIT_CAST`,
`SQLITE_OMIT_GENERATED_COLUMNS`, `SQLITE_OMIT_EXPLAIN`,
`SQLITE_OMIT_TEMPDB`, `SQLITE_OMIT_PRAGMA`,
`SQLITE_OMIT_ANALYZE`, `SQLITE_OMIT_REINDEX`, `SQLITE_OMIT_VIEW`,
`SQLITE_OMIT_TRIGGER`, and `SQLITE_OMIT_ATTACH`. Its FreeBASIC library links
without unresolved symbols. The C API host
`fb_src/tests/sqlite_omit_parser_features_api.c` confirms that scalar SELECT
and main-table creation work while the omitted commands and syntax return
`SQLITE_ERROR`, including generated-column declarations.

The initial combined link exposed two update/delete calls to
`sqlite3FkActions()`. Upstream defines that helper as a no-op when triggers are
omitted; the FreeBASIC call sites now use the same guard. The default debug
library still handles PRAGMA, ANALYZE, REINDEX, ATTACH, TEMP tables, views,
triggers, EXPLAIN, CAST, subqueries, compound SELECT, and CTE queries. Build and
probe results are in
`fb_src/build/omit-parser-extended-combined-20261021/` and
`fb_src/build/cte-guard-default-debug-20261021/`.

The same omitted-profile host checks VACUUM. Upstream guards VACUUM when either
`SQLITE_OMIT_VACUUM` or `SQLITE_OMIT_ATTACH` is set; this combined profile sets
`SQLITE_OMIT_ATTACH`. The default debug profile successfully runs VACUUM on a
file-backed database.


## `SQLITE_OMIT_GENERATED_COLUMNS` parser guard (2026-10-21)

The static Lemon tables retain generated-column reductions when
`SQLITE_OMIT_GENERATED_COLUMNS` is set. The semantic dispatcher now guards both
reductions to match `src/parse.y`. The production omit-profile library builds
without unresolved symbols. The C API host
`fb_src/tests/sqlite_omit_generated_columns_api.c` confirms ordinary table
creation works while VIRTUAL and STORED generated-column declarations return
`SQLITE_ERROR`. The default debug profile still evaluates a stored generated
column to `3` after inserting `2` into its source column. Build and probe
results are in
`fb_src/build/omit-generated-parser-audit-20261021/` and
`fb_src/build/cte-guard-default-debug-20261021/`.


## `SQLITE_OMIT_VACUUM` build profile (2026-10-21)

The VACUUM parser reductions now follow upstream's combined
`!SQLITE_OMIT_VACUUM && !SQLITE_OMIT_ATTACH` condition. The FreeBASIC Makefile
also excludes `sqlite3_bulk_vacuum.bas` under `SQLITE_OMIT_VACUUM`; that module
references `sqlite3BtreeCopyFile`, which upstream removes in the same profile.
The release library links without unresolved symbols, and the C API host
`fb_src/tests/sqlite_omit_vacuum_api.c` confirms SELECT and ordinary table
creation work while VACUUM returns `SQLITE_ERROR`. The default debug profile
successfully runs VACUUM on a file-backed database. Build and probe results are
in `fb_src/build/omit-vacuum-parser-audit-20261021/`.


## Final 20 indexed function bodies (2026-10-21)

All 3,263 rows in `PORTING_FUNCTIONS.csv` now have `FB body present` status,
including the 20 rows that had been listed as out of scope or disabled. The
11 test and debug helpers are represented under their SQLite build flags.
Eight diagnostic or unused callback bodies are off by default, matching
upstream; the optional `SQLITE3_FB_COMPILE_DISABLED_BODIES` define compiles
them for syntax validation. The historical `sqlite3VdbeSerialType` body is
covered by the active FreeBASIC serial-type implementation.

The default library build and a compile with `SQLITE_TEST`, `SQLITE_DEBUG`,
`SQLITE_VDBE_COVERAGE`, and `SQLITE_ENABLE_MEMSYS5` both succeed. The separate
`SQLITE3_FB_COMPILE_DISABLED_BODIES` compile also succeeds. The repeatable
source audit `python3 fb_src/tools/check_function_body_coverage.py` matches
every indexed C name to a FreeBASIC `Function` or `Sub` definition, or to its C
ABI `Alias`, across the `.bas` and included `.bi` source units: 3,263 matched,
zero unmatched. `make -C fb_src -j2` succeeds. This establishes 100% coverage
of indexed function bodies; runtime parity remains a separate measure.


## Initialization allocator probe and builtin registration (2026-10-21)

The startup path now registers built-in SQL functions inside
`sqlite3_initialize()`, before cache and VFS setup, as upstream does. The C-only
smoke host `fb_src/tests/sqlite_test_helpers_smoke.c` checks that `length()` is
already in the builtin table when initialization returns. It also runs
`sqlite3UtfSelfTest()`, the page-cache stats hook, and the memsys5 dump.

`sqlite3OsInit()` now performs the upstream 10-byte `sqlite3_malloc()` probe
before host VFS registration. The smoke host uses a 96-byte memsys5 heap that
can allocate the recursive initialization mutex but cannot satisfy the probe;
both C and FreeBASIC return `SQLITE_NOMEM`. With a 2 MiB heap, C and FreeBASIC
report identical memsys5 allocation totals and all 27 freelist size rows.

After rebuilding the default library, `sqlite_select_transform_diff.c` matches
all 24 curated queries and 384 compound-affinity cases, and
`sqlite_random_diff.c` matches 100,000 seeded scalar queries. Tcl 8.6.17
development files are now installed, and the unchanged upstream C test support
runs against the FreeBASIC shared library through `testfixture_fb_sync`.
Focused tests pass `init.test` 45/45, `mutex2.test` 14/14, `func.test`
15,031/15,031, `pcache2.test` 7/7, `mem5.test` 5/5, `lookaside.test` 21/21,
and `shared6.test` 40/40.

The focused tests exposed C helper reads of FreeBASIC-private state. The
repeatable builder `python3 fb_src/tools/build_testfixture_fb_compat.py` makes
temporary C support copies that call `sqlite3TestVdbeUsesStatementJournal`,
`sqlite3TestConnectionBtree`, `sqlite3TestConnectionDatabaseCount`,
`sqlite3TestConnectionEncoding`, `sqlite3TestConnectionMallocFailed`,
`sqlite3TestBtreeDatabase`, and `sqlite3TestCursorBtree`, plus the public
`sqlite3_db_mutex()` API. The B-tree test helper now opens its database through
`sqlite3_open_v2()` and keeps the opaque B-tree handle paired with its owning
connection. This avoids passing a C-allocated fake `sqlite3` record or reading
the FreeBASIC cursor layout from C. Optional `--c-define` flags align C test
capability gates such as ICU and unlock-notify with the FreeBASIC profile.
Upstream C sources and Tcl tests remain unchanged. With the final fixture,
`test/types.test` passes 56/56, `test/cache.test` 190/190,
`test/fordelete.test` 20/20, `test/enc2.test` 90/90,
`test/pager1.test` 1,373/1,373, `test/vtabH.test` 23/23, and
`ext/rtree/rtree1.test` 299/299; all finish with no tracked SQLite allocations
remaining. Focused logs are saved in
`fb_src/build/testfixture-c-compat-sources/focused-runs/`.

The compatibility builder accepts `--c-define` so the C fixture can advertise
features enabled by the FreeBASIC library. The ICU profile was built with
`--c-define SQLITE_ENABLE_ICU=1 --c-define SQLITE_ENABLE_UNLOCK_NOTIFY=1`; this
keeps ICU-gated test selection in sync with the runtime.

A full unchanged Tcl suite pass and retest completed in
`/tmp/sqlite-fb-full-compat-20261021/`: 1,514 of 1,516 jobs have zero errors,
with 1,889,760 invocations on those jobs. Two cases remain in error out of
1,892,885 total invocations. `fts5bigtok2.test` expects OOM in a stress case;
the same case fails on the C reference fixture. `sqllimits1-15.2` uses ICU's
replacement `like()` function, whose upstream C implementation enforces the
compile-time pattern bound rather than the per-connection limit. A C host using
upstream `ext/icu/icu.c` returns a match for a 1,002-byte pattern with the
runtime limit set to 1,000, consistent with the test's note that an override
bypasses the built-in LIKE limit. The default C fixture without ICU passes the
whole `sqllimits1.test`.

The host initially had a soft `RLIMIT_NOFILE` of 524,288, making
`misc7.test`'s descriptor-exhaustion loop unnecessarily large. The test runner
and its workers were capped at 1,024. The corrected FreeBASIC fixture passes
`misc7.test` with 1,195 cases and the C reference passes 1,198, both without
errors. The earlier `enc2.test`, `pager1.test`, `vtabH.test`, `cache.test`,
`types.test`, and `misc7.test` fixture records were cleared by focused reruns
or the final retest. Focused logs are in
`fb_src/build/testfixture-c-compat-sources/focused-runs/`, and the FTS5
comparison is in `/tmp/sqlite-fb-fts5bigtok2-compare-20261021/`.


## UPDATE and DELETE ORDER BY/LIMIT (2026-10-21)

The FreeBASIC Lemon regeneration now passes `SQLITE_UDL_CAPABLE_PARSER`, so its
tables include the UPDATE/DELETE ORDER BY/LIMIT productions in every profile.
`sqlite3_parser_semantics.bas` maps those generated rules to their expanded
right-hand-side stack slots. With `SQLITE_ENABLE_UPDATE_DELETE_LIMIT`, the
UPDATE code uses `sqlite3LimitWhere` for ordinary updates and carries ordering,
limit, and target-key grouping through UPDATE FROM source selection. The
grouped SELECT path accepts `SRT_Upfrom`, and cleanup releases the transferred
clauses. The unchanged `upfrom2.test` passes 65/65 on the feature-enabled
FreeBASIC fixture with no tracked leaks; its log is saved as
`upfrom2.test-final9.log` in the focused-runs directory.

`sqlite3_compileoption_used()` and `PRAGMA compile_options` now report
`ENABLE_UPDATE_DELETE_LIMIT` when the feature is compiled in; the next11
fixture's pragma probe confirms the option is present.

Using the same feature-enabled fixture, the unchanged `update.test` passes
142/142, `update2.test` 35/35, `delete.test` 68/68, `upfrom2.test` 65/65, and
`upfromfault.test` 2,357/2,357. All 2,667 invocations pass with no tracked
SQLite allocations remaining. The logs are in
`fb_src/build/udl-feature-regression-20261021/`.

An out-of-tree native C fixture built with `--update-limit` confirms
`SQLITE_ENABLE_UPDATE_DELETE_LIMIT` in `PRAGMA compile_options`. The same five
scripts pass 2,339 C invocations, also without leaks. Every case label matches
for `update.test`, `update2.test`, `delete.test`, and `upfrom2.test`; all 2,028
C `upfromfault.test` labels are present in the FreeBASIC run, which passes 328
additional fault-injection cases. C logs are in
`fb_src/build/native-c-udl-reference-20261021/udl-focused/`.

The first native C reference attempt under
`/tmp/sqlite-fb-full-udl-20261021/` was interrupted after its `sessionbig.test`
scratch directory reached 3.4 GB and six jobs reported disk I/O errors. This
matches the host's earlier `/tmp` quota failure, so those results are
incomplete and are not treated as SQLite failures. Its testrunner database and
log remain available for diagnosis. A clean native C reference run has been
restarted on the workspace filesystem in
`fb_src/build/full-c-reference-udl-20261021/`. This checked-in C fixture is a
default-feature build; `PRAGMA compile_options` confirms that
`SQLITE_ENABLE_UPDATE_DELETE_LIMIT` is disabled. This run was stopped after
512 clean jobs to prioritize the patched FreeBASIC run; its database and log
remain in that directory. The focused C reference below covers the UDL-enabled
path.

A matched full FreeBASIC suite using the pre-fix DSO was stopped in
`fb_src/build/full-udl-fb-20261021/`, using `testfixture_fb_compat_final9`.
It stopped after 295 clean jobs, with five failed jobs and four workers
active. Two aborts (`statfault.test`, `mallocB.test`) are fixed by the
scan-status OOM guard; `notnullfault.test` also passes in the patched fixture.
The `e_fts3.test` errors match the ICU-enabled C reference, and `like.test`
passes on focused rerun. Its partial database and log are retained.

The first post-fix full run used next11 and was stopped after 54 clean jobs
when a compile-option audit found additional feature flags that needed to be
reported. Its database and log remain in `fb_src/build/full-udl-fb-next11/`.

The first next12 full-suite attempt in
`fb_src/build/full-udl-fb-next12-20261021/` was invalid: two orchestrators
shared one `testrunner.db` and the same worker directories. It ended with 88
clean and 75 failed jobs; the overlapping results are not treated as engine
failures. The database and log are retained.

A single clean next12 suite is now running in
`fb_src/build/full-udl-fb-next12-clean-20261021/`. It uses
`testfixture_fb_compat_next12`, linked to the DSO with ICU, FTS3/4/5, R-Tree,
GeoPoly, Session, statement virtual tables, strict subtype, UDL, and the
scan-status OOM fix. Both `TMPDIR` and `SQLITE_TMPDIR` point to workspace
storage, and the runner uses a 1,024 file-descriptor limit. Its current counts
and output are in that directory's `testrunner.db` and `testrunner.log`.

The first full-run `like.test` job exceeded its 1,000 ms wildcard-performance
limit at 3,090 ms under competing test load. A direct rerun with the same
FreeBASIC fixture passes 128/128, with `like-14.1` at 57 ms and no tracked
leaks; its log is in `fb_src/build/fb-pattern-timing-20261021/`.


## Public C API export audit (2026-10-21)

The repeatable checker `python3 fb_src/tools/check_public_api_exports.py`
compares C ABI names in `sqlite3_api_declarations.bi` with a shared library's
dynamic symbol table. The all-feature Linux library at
`fb_src/build/public-api-audit-native/libsqlite3-fb-allfeatures.so` exports
302 of the 306 declared aliases. The four expected Linux omissions are
`sqlite3_activate_cerod`, which belongs to the optional CEROD extension, and
`sqlite3_win32_set_directory`, `sqlite3_win32_set_directory8`, and
`sqlite3_win32_set_directory16`. The checker passes when those profile
omissions are explicitly allowed; the separate Windows export audit covers
the Windows-only API.


## Scan-status handling after persistent OOM (2026-10-21)

`test/statfault.test` aborted in `sqlite3WhereAddScanStatus` during
`statfault-1-oom-persistent.163`. The assertion checked the coroutine opcode
and range even though allocation failure had left the VDBE program incomplete;
upstream suppresses those invariants when `db->mallocFailed` is set. The
FreeBASIC path now follows that guard and returns safely if opcode lookup has
no instruction to inspect.

The GDB trace is saved at
`fb_src/build/statfault-debug-20261021/statfault.gdb.log`. A rebuilt debug,
test, DBSTAT, and scan-status fixture passes `statfault.test` 1,440/1,440 with
no tracked allocations remaining. The native C reference passes 1,298/1,298;
all C case labels are present in the FreeBASIC run, which exercises 142
additional allocation-failure cases. The retest log is in
`fb_src/build/statfault-retest-next10/statfault.test.log`.
The unchanged `scanstatus.test` and `scanstatus2.test` also pass 63/63 and
24/24 with no tracked allocations remaining.

The patched FreeBASIC fixture also completes the ICU-enabled `e_fts3.test`
fault sweep without aborting: it reports four `sqlite_master` cleanup
expectation errors out of 118,934 invocations, matching the four error shapes
in the native ICU C run (95,447 invocations). Both runs free all tracked
allocations; the difference in case counts comes from their allocation-fault
schedules.

The same OOM guard also prevents the abort in `mallocB.test`. The patched
fixture passes 1,759/1,759 with no tracked leaks; native C passes 1,581/1,581.
Every C case label is covered, plus 178 additional FreeBASIC fault-injection
cases. The log is in `fb_src/build/oom-regression-next10/mallocB/`.
The unchanged `notnullfault.test` passes 612/612 with no tracked leaks in the
same patched fixture; its log is in
`fb_src/build/oom-regression-next10/notnullfault/`.


## Compile-option parity and strict subtypes (2026-10-21)

The feature-option table now reports FTS4/5, GeoPoly, ICU, Session, NO_SYNC,
UPDATE/DELETE LIMIT, and strict-subtype flags when their build macros are set.
The next12 `PRAGMA compile_options` probe returns the same 63 entries as the
native C UDL/ICU profile apart from the compiler name, host-specific C options,
and the profile differences for column metadata, scan status, and unlock
notify.

With `SQLITE_STRICT_SUBTYPE=1`, `sqlite3_result_subtype()` now rejects a
callback that did not register `SQLITE_RESULT_SUBTYPE`, using SQLite's misuse
error. A C extension probe verifies both the rejected callback and a flagged
callback that returns subtype 66. The unchanged `subtype1.test` passes 34/34
and `func.test` passes 15,030/15,030 with no tracked allocations remaining.
Probe logs are in `fb_src/build/strict-subtype-next12-tests/`.


## Collation and expression-index coverage (2026-10-21)

The unchanged `collate1.test` through `collate9.test`, `collateA.test`,
`collateB.test`, and `indexexpr1.test` through `indexexpr3.test` pass all
892 FreeBASIC invocations and all 826 native C invocations with no tracked
allocations remaining. Every C case label is present in the FreeBASIC logs;
the FreeBASIC run adds 66 allocation-failure cases in `collate1.test`.
Results are in `fb_src/build/collation-next12-20261021/` and
`fb_src/build/c-udl-collation-retest-20261021/`.

## Compact expression duplication and source-less column metadata (2026-10-21)

`sqlite3ExprDup(..., EXPRDUP_REDUCE)` now stores the upstream compact layouts.
Token-only nodes end before `pLeft`; common nodes end before `iTable`; left/right
expression trees and their inline token strings share an aligned SQLite-owned
buffer. Child records carry `EP_Static`, and token-only cleanup does not touch
fields beyond its allocated prefix. Explicitly full-size, outer-join, window,
subroutine, and debug `EP_NoReduce` expressions retain the full layout.

The source-less SELECT path now calls `sqlite3GenerateColumnNames()`. This
restores the output metadata pass for scalar subqueries and fixes the three
column-origin failures in `capi2.test`.

An isolated `SQLITE_DEBUG`/`SQLITE_TEST` FreeBASIC library and compatibility
fixture passed `capi2.test` 145/145. The compact-expression regression set
passed 30,539 unchanged upstream invocations across default, view, ALTER,
trigger, SELECT/subquery, schema/index/ALTER/expression/window fault tests.
All tracked SQLite allocations were freed. Logs are under
`fb_src/build/capi2-metadata-fix/compact-regressions/` and
`fb_src/build/capi2-metadata-fix/capi2.test.log`.

At 2026-10-21 19:42 UTC, that older full run had completed 678 of 1,516 jobs,
with 832 ready and four running. Its remaining recorded failures were three
`capi2.test` origin-name cases (fixed and retested above) and the four
ICU-tokenizer `e_fts3.test` expectation mismatches that also occur on the C
reference. The run's `wherefault.test` passed 6,322 invocations. The full
compact-profile `wherefault.test` attempt exceeded its 900-second harness
timeout while other CPU-heavy jobs were active. Its nested-query OOM section
was later isolated and passed; the two `do_malloc_test` stress sections remain
unverified in the compact profile.

The next12 full-suite runner was interrupted at 803 clean jobs. Its database
and log remain in `fb_src/build/full-udl-fb-next12-clean-20261021/`; it had
three capi2 origin-name failures (fixed and retested above) and four C-shared
ICU-tokenizer expectation mismatches in `e_fts3.test`.

The corrected full-feature library and Tcl fixture are built in
`fb_src/build/full-udl-fb-next13/`. The unchanged metadata-enabled
`capi2.test` passes 145/145 with no tracked leaks. The nested-query OOM portion
of `wherefault.test`, selected with `--match=wherefault-3*`, passes 201,400
runner invocations with no leaks. A clean next13 full suite is now running in
`fb_src/build/full-udl-fb-next13-clean-20261021/` with
`testfixture_fb_compat_next13`; its initial snapshot had six completed jobs,
1,506 ready jobs, four running workers, and no failures.
