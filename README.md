# FreeBASIC SQLite

A FreeBASIC implementation of SQLite 3.54.0, with the upstream SQLite tests
and additional port regression tests.

The engine sources are in [`fb_src/`](fb_src/). The C and Tcl test support
remains available so the original SQLite test scripts can run against the
FreeBASIC library. This repository includes the SQLite source snapshot used
for the port, its build tools, and its tests.

## Build

Install FreeBASIC, a C compiler, GNU Make, Python 3, and Tcl development files.
The default build produces a Unix shared library:

```sh
make -C fb_src FB_DEFINE_FLAGS='-d SQLITE_STRICT_SUBTYPE=0'
```

The library is written to `fb_src/build/libsqlite3-fb.so`. This snapshot needs
an explicit value for `SQLITE_STRICT_SUBTYPE` with the installed FreeBASIC
compiler; zero selects the ordinary release behavior. Generated FreeBASIC
includes are checked in, so this build does not require C2FB.

See [`fb_src/README.md`](fb_src/README.md) for optional features, Windows
builds, test profiles, and the porting ledger. Source coverage is tracked
separately from runtime parity; the ledger records outstanding test failures
and test-support limitations.

## Tests

Audit the indexed function bodies and run the interrupt regression:

```sh
python3 fb_src/tools/check_function_body_coverage.py
make -C fb_src check-interrupt FBC='fbc -d SQLITE_STRICT_SUBTYPE=0'
```

The port's C API probes and differential tests are in
[`fb_src/tests/`](fb_src/tests/). The original Tcl tests are in [`test/`](test/)
and the extension test directories under [`ext/`](ext/).

To build upstream C test support for the FreeBASIC engine, configure the
SQLite build first:

```sh
./configure --dev
python3 fb_src/tools/build_testfixture_fb_compat.py --help
```

The fixture builder takes a FreeBASIC test-profile library through `--library`.
Its default is `fb_src/build/libsqlite3-fb-testfixture-config-sync.so`. Build
that profile with matching C and FreeBASIC feature definitions as documented
in the porting ledger. The ordinary release library is not a substitute for
the fixture's test configuration. Upstream build and test instructions are
preserved in [`README.upstream.md`](README.upstream.md).

## C2FB

The [C2FB translator](https://github.com/fbxl-sj0/c2fb) is maintained separately
and is not included here.
Translated SQLite engine code and its runtime helpers are part of this port.
The SQLite-specific generator in [`fb_tools/sqlite_codegen/`](fb_tools/sqlite_codegen/)
is also included.

The existing translation and regeneration targets expect a separate C2FB
checkout at `fb_tools/c2fb/`. That directory is ignored by Git. ICU builds
also use C2FB to generate declarations for the installed ICU version.

```sh
git clone https://github.com/fbxl-sj0/c2fb.git fb_tools/c2fb
make -C fb_tools/c2fb converter
```

## Upstream source

The SQLite baseline is Git revision
`64c2f58d739e7ca1633a7b7fbe7e5bf053f29ef5` from
<https://github.com/sqlite/sqlite>. Its Fossil source identifier is
`ac6ac0c22d98878cdf6042b5801cf5b5dc98c7b48077360d24a70b876921b428`.
This repository starts with a source snapshot and does not copy the upstream
Git history. SQLite's public-domain notice and source blessings are preserved.
See [`LICENSE.md`](LICENSE.md).

<!-- end of README.md -->
