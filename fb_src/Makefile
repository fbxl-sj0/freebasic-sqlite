# SQLite FreeBASIC port build rules
#
# Build only the FreeBASIC source in this directory. The main SQLite build
# does not include this tree until the port has enough API coverage to link
# existing clients.

.DEFAULT_GOAL := all

FBC ?= fbc
CC ?= cc
WIN_SEH_CC ?= clang
WIN_SEH_DLLTOOL ?= llvm-dlltool
WIN_SEH_LINKER ?= lld-link
WIN_SEH_OBJCOPY ?= i686-w64-mingw32-objcopy
WIN_SEH_TEST_LD ?= i686-w64-mingw32-ld
WIN_SEH_TEST_DIR ?= build/wal-seh-bridge-win32-smoke
WIN_SEH_TEST_LIBS ?= $(shell i686-w64-mingw32-gcc -print-file-name=libkernel32.a) $(shell i686-w64-mingw32-gcc -print-file-name=libmsvcrt.a)
WIN_SEH_FAULT_CC ?= i686-w64-mingw32-gcc
WIN_SEH_FAULT_DIR ?= build/wal-seh-fault-win32-smoke
WIN_SEH_FAULT_CC64 ?= clang
WIN_SEH_FAULT_LINKER64 ?= lld-link
WIN_SEH_FAULT_DIR64 ?= build/wal-seh-fault-win64-smoke
WIN_SEH_FAULT_DLL ?= $(TARGET)
WIN_SEH_FAULT_DLL_IMPORT ?= $(dir $(WIN_SEH_FAULT_DLL))lib$(notdir $(basename $(WIN_SEH_FAULT_DLL))).dll.a
WIN_SEH_WINE ?= wine
WIN_SEH_SMOKE_DIR ?= build/wal-seh-bridge-smoke
RTREE_LAYOUT_WIN32_CC ?= i686-w64-mingw32-gcc
RTREE_LAYOUT_WIN32_DIR ?= build/rtree-matcharg-layout-win32
# The generated PRAGMA index includes names conditional on SQLITE_OS_WIN.
PRAGMA_WIN_CC ?= i686-w64-mingw32-gcc
PRAGMA_WIN_CANDIDATE_DIR ?= build/pragma-win-candidates
WALKER_LAYOUT_WIN32_DIR ?= build/walker-layout-win32
PYTHON ?= python3
LLVM_NM ?= llvm-nm
PKG_CONFIG ?= pkg-config
THREADSAFE ?= 1
FB_OS ?= unix
FB_TARGET ?= win64
WINDOWS_C99_MATH ?= 1
FEATURE_DEFINES ?=
BODY_TYPE_MAPS ?=
BODY_OPTIONS ?=
C2FB_BODY_OPTIONS = $(BODY_TYPE_MAPS) $(BODY_OPTIONS)
FB_DEFINE_FLAGS ?=
WIN_VFS_DLL ?= $(TARGET)
ICU_MAJOR ?= $(shell $(PKG_CONFIG) --modversion icu-i18n 2>/dev/null | sed 's/\..*//')
ICU_CFLAGS ?= $(shell $(PKG_CONFIG) --cflags icu-i18n 2>/dev/null)
ICU_LINK_FLAGS ?= $(shell $(PKG_CONFIG) --libs icu-i18n 2>/dev/null | sed 's/-l\([^ ]*\)/-l \1/g')
C2FB ?= ../fb_tools/c2fb/build/c2fb
MEMDEBUG_BACKTRACE_FLAGS ?= $(if $(shell getconf GNU_LIBC_VERSION 2>/dev/null),-d SQLITE3_FB_GLIBC_BACKTRACE=1)
FB_PLATFORM_DEFINE_FLAGS =
WIN_SEH_OBJECTS =
WIN_SEH_POST_LINK =
OS_KV_OPTIONAL ?= 0
INCLUDE_EXISTING ?= 0
ifeq ($(THREADSAFE),0)
THREAD_FLAGS =
else
THREAD_FLAGS = -mt
endif
GEN_DIR = build/generated
CODEGEN = $(GEN_DIR)/sqlite_codegen
CANDIDATE_DIR ?= build/candidates
LOOSE_CANDIDATE_DIR ?= build/candidates-loose
SOURCES = sqlite3_metadata.bas sqlite3_compile_options.bas sqlite3_complete.bas sqlite3_tokenize.bas sqlite3_parser_tables.bas sqlite3_parser_driver.bas sqlite3_parser_semantics.bas sqlite3_parser_cleanup.bas sqlite3_prepare.bas sqlite3_exec.bas sqlite3_pragma.bas sqlite3_table.bas sqlite3_expr.bas sqlite3_cte.bas sqlite3_walker.bas sqlite3_window.bas sqlite3_delete_helpers.bas sqlite3_values.bas sqlite3_affinity.bas sqlite3_functions.bas sqlite3_json_string.bas sqlite3_json_values.bas sqlite3_json_hex.bas sqlite3_json_parse_state.bas sqlite3_json_text_scan.bas sqlite3_json_labels.bas sqlite3_json_blob.bas sqlite3_json_payload.bas sqlite3_json_validate.bas sqlite3_json_text_parse.bas sqlite3_json_parse_arg.bas sqlite3_json_return.bas sqlite3_json_valid.bas sqlite3_json_query.bas sqlite3_json_blob_text.bas sqlite3_select.bas sqlite3_select_constant_propagation.bas sqlite3_build.bas sqlite3_transaction.bas sqlite3_alter.bas sqlite3_insert.bas sqlite3_analyze.bas sqlite3_initialize.bas sqlite3_config.bas sqlite3_log.bas sqlite3_collation.bas sqlite3_connection.bas sqlite3_busy.bas sqlite3_interrupt.bas sqlite3_filename.bas sqlite3_uri.bas sqlite3_schema.bas sqlite3_shadow_tables.bas sqlite3_trigger_helpers.bas sqlite3_limit.bas sqlite3_db_status.bas sqlite3_memory.bas sqlite3_mutex.bas sqlite3_random.bas sqlite3_threads.bas sqlite3_btmutex.bas sqlite3_fault.bas sqlite3_status.bas sqlite3_db_memory.bas sqlite3_rowset.bas sqlite3_numeric.bas sqlite3_column.bas sqlite3_util_numeric.bas sqlite3_where_helpers.bas sqlite3_varint.bas sqlite3_fp.bas sqlite3_printf.bas sqlite3_vdbe_affinity.bas sqlite3_vdbe_compare.bas sqlite3_vdbe_serial.bas sqlite3_vdbe_record.bas sqlite3_vdbe_mem_text.bas sqlite3_vdbe_api.bas sqlite3_vdbe_mem.bas sqlite3_result.bas sqlite3_vdbe_core.bas sqlite3_vdbe_cursor.bas sqlite3_vdbe_exec.bas sqlite3_vdbe_trace.bas sqlite3_vdbe_stmt.bas sqlite3_utf.bas sqlite3_string_compare.bas sqlite3_string_utils.bas sqlite3_straccum.bas sqlite3_bitvec.bas sqlite3_hash.bas sqlite3_errors.bas sqlite3_pcache.bas sqlite3_os.bas sqlite3_os_unix.bas sqlite3_memjournal.bas sqlite3_memdb.bas sqlite3_pager.bas sqlite3_wal.bas sqlite3_btree.bas sqlite3_backup.bas
SOURCES += sqlite3_date_helpers.bas
SOURCES += sqlite3_session_simple_api.bas
SOURCES += sqlite3_db_config.bas
SOURCES += sqlite3_error_names.bas
SOURCES += sqlite3_test_control.bas
SOURCES += sqlite3_c2fb_intrinsics.bas
SOURCES += sqlite3_btree_integrity_helpers.bas
SOURCES += sqlite3_upsert.bas
SOURCES += sqlite3_date_modifier.bas
SOURCES += sqlite3_date_sqlfunc.bas
SOURCES += sqlite3_snapshot.bas
SOURCES += sqlite3_notify.bas
SOURCES += sqlite3_builtin_extensions.bas
SOURCES += sqlite3_hooks.bas
SOURCES += sqlite3_where_scan.bas
SOURCES += sqlite3_where_clause.bas
SOURCES += sqlite3_window_names.bas
SOURCES += sqlite3_iotrace.bas
SOURCES += sqlite3_vdbe_explain.bas sqlite3_treeview.bas sqlite3_opcode_names.bas
SOURCES += sqlite3_json_optional_callbacks.bas
SOURCES += sqlite3_vdbesort_init.bas
SOURCES += sqlite3_vdbesort_debug.bas
SOURCES += sqlite3_vdbe_normalize.bas
SOURCES += sqlite3_vtab_config.bas
SOURCES += sqlite3_vtab_overload.bas
SOURCES += sqlite3_vtab_omit_stubs.bas
SOURCES += sqlite3_memsys5.bas
SOURCES += sqlite3_memsys3.bas
SOURCES += sqlite3_memdebug.bas
SOURCES += sqlite3_debug_assert.bas
# C2FB-generated engine batches that passed per-procedure and grouped compiles.
SOURCES += sqlite3_pragma_data.bas sqlite3_pragma_helpers.bas sqlite3_pragma_debug.bas
SOURCES += sqlite3_std_types.bas
SOURCES += $(wildcard sqlite3_bulk*.bas)

# The default VFS is Unix. Windows builds use the separately ported Win32 VFS
# and must not compile the Unix VFS or its source-specific C2FB shards.
ifeq ($(FB_OS),windows)
# Keep Win32 inline assembly in the syntax supported by the current gas backend.
FB_TARGET_FLAGS ?= -target $(FB_TARGET) -asm intel
FB_PLATFORM_DEFINE_FLAGS = -d SQLITE_OS_WIN
# MinGW provides the C99 math functions SQLite enables for non-MSVC builds.
# Set WINDOWS_C99_MATH=0 when using a Windows CRT that does not provide them.
ifneq ($(findstring SQLITE_ENABLE_MATH_FUNCTIONS,$(FB_DEFINE_FLAGS)),)
ifeq ($(WINDOWS_C99_MATH),1)
ifeq ($(findstring SQLITE_HAVE_C99_MATH_FUNCS,$(FB_DEFINE_FLAGS)),)
FB_PLATFORM_DEFINE_FLAGS += -d SQLITE_HAVE_C99_MATH_FUNCS=1
endif
endif
endif
FB_LINK_FLAGS ?= -l mingw32 -l mingwex -l msvcrt -l kernel32 -l user32 -l advapi32
MEMDEBUG_BACKTRACE_FLAGS :=
TARGET ?= build/sqlite3-fb-$(FB_TARGET).dll
UNIX_ONLY_SOURCES = sqlite3_os_unix.bas $(wildcard sqlite3_bulk*os_unix*.bas) $(wildcard sqlite3_bulk*mutex_unix*.bas)
SOURCES := $(filter-out $(UNIX_ONLY_SOURCES),$(SOURCES))

# FreeBASIC has no structured-exception syntax. Keep only the lexical Windows
# SEH frame in a compiler-specific bridge; WAL handling remains in FreeBASIC.
ifneq ($(findstring SQLITE_USE_SEH,$(FB_DEFINE_FLAGS)),)
WIN_SEH_OBJECTS = build/$(FB_TARGET)/sqlite3_win_seh_bridge.o
ifeq ($(FB_TARGET),win64)
WIN_SEH_CLANG_TARGET ?= x86_64-w64-windows-gnu
else ifeq ($(FB_TARGET),win32)
WIN_SEH_CLANG_TARGET ?= i686-pc-windows-msvc
# MinGW ld.bfd leaves Clang's x86 SEH metadata at RVA 0. Wine rejects that PE
# image; x86 chained SEH still works without this unused auxiliary section.
WIN_SEH_POST_LINK = $(WIN_SEH_OBJCOPY) --remove-section=.sxdata $@
else
$(error SQLITE_USE_SEH requires FB_TARGET=win32 or win64)
endif
FB_LINK_FLAGS += -l ntdll

$(WIN_SEH_OBJECTS): sqlite3_win_seh_bridge.c sqlite3_win_seh_bridge.h
	mkdir -p $(dir $@)
	$(WIN_SEH_CC) --target=$(WIN_SEH_CLANG_TARGET) -fms-extensions -O2 -c $< -o $@
endif
else ifeq ($(FB_OS),unix)
FB_TARGET_FLAGS ?=
FB_LINK_FLAGS ?= -Wl --version-script,sqlite3.map
TARGET ?= build/libsqlite3-fb.so
else
$(error FB_OS must be unix or windows)
endif

# SQLite omits both the memory VFS and the serialize/deserialize APIs together.
ifneq ($(findstring SQLITE_OMIT_DESERIALIZE,$(FB_DEFINE_FLAGS)),)
SOURCES := $(filter-out sqlite3_memdb.bas sqlite3_bulk_memdb_serialization.bas sqlite3_bulk36_memdb.bas sqlite3_bulk39_memdb.bas,$(SOURCES))
endif

# sqlite3_blob_* and its cursor helper code are omitted with vdbeblob.c.
ifneq ($(findstring SQLITE_OMIT_INCRBLOB,$(FB_DEFINE_FLAGS)),)
SOURCES := $(filter-out sqlite3_bulk_vdbeblob.bas,$(SOURCES))
endif

# Vacuum support depends on sqlite3BtreeCopyFile, which upstream omits with
# SQLITE_OMIT_VACUUM. Keep the translated vacuum implementation out as well.
ifneq ($(findstring SQLITE_OMIT_VACUUM,$(FB_DEFINE_FLAGS)),)
SOURCES := $(filter-out sqlite3_bulk_vacuum.bas,$(SOURCES))
endif

# The upstream vtab.c implementation and vtab-only C2FB shards are absent
# when SQLite is built without virtual-table support.
VIRTUALTABLE_SOURCES = $(wildcard sqlite3_bulk*vtab*.bas)
ifneq ($(findstring SQLITE_OMIT_VIRTUALTABLE,$(FB_DEFINE_FLAGS)),)
SOURCES := $(filter-out sqlite3_vtab_config.bas sqlite3_vtab_overload.bas $(VIRTUALTABLE_SOURCES),$(SOURCES))
endif

# Windows VFS helpers are preprocessed out of Unix builds.
SOURCES += sqlite3_os_win_helpers.bas sqlite3_os_win_memory.bas
ifeq ($(OS_KV_OPTIONAL),1)
SOURCES += sqlite3_os_kv_optional.bas
endif
GENERATED_HEADERS = sqlite3_tokens.bi sqlite3_keyword_data.bi sqlite3_character_classes.bi sqlite3_global_data.bi sqlite3_parser_tables.bi sqlite3_parser_rule_ids.bi sqlite3_opcodes.bi sqlite3_api_constants.bi sqlite3_fp10_tables.bi sqlite3_api_declarations.bi sqlite3_internal_api_declarations.bi sqlite3_extension_api_table.bi sqlite3_pragma_data.bi sqlite3_std_types.bi

ifneq ($(findstring SQLITE_ENABLE_ICU,$(FB_DEFINE_FLAGS)),)
SOURCES += sqlite3_ext_icu.bas
ifeq ($(strip $(ICU_MAJOR)),)
$(error SQLITE_ENABLE_ICU requires ICU headers and pkg-config, or an explicit ICU_MAJOR)
endif
GENERATED_HEADERS += $(GEN_DIR)/sqlite3_icu_api.bi
ICU_C2FB_OPTIONS = \
	--emit-source=*sqlite3_icu_api.h \
	--type-map=UBreakIterator=Any \
	--type-map=UBreakIteratorType=Long \
	--type-map=UCollationResult=Long \
	--type-map=UCollationStrength=Long \
	--type-map=UCollator=Any \
	--type-map=UParseError=Any \
	--type-map=URegularExpression=Any \
	--type-map=UChar=UShort \
	--type-map=UChar32=Long \
	--type-map=UErrorCode=Long \
	--type-map=UBool=Byte \
	--type-map=int32_t=Long \
	--type-map=uint32_t=ULong \
	--rename-proc=ubrk_open_$(ICU_MAJOR)=icuUbrkOpen \
	--rename-proc=ubrk_close_$(ICU_MAJOR)=icuUbrkClose \
	--rename-proc=ubrk_current_$(ICU_MAJOR)=icuUbrkCurrent \
	--rename-proc=ubrk_next_$(ICU_MAJOR)=icuUbrkNext \
	--rename-proc=ubrk_first_$(ICU_MAJOR)=icuUbrkFirst \
	--rename-proc=ucol_close_$(ICU_MAJOR)=icuUColClose \
	--rename-proc=ucol_open_$(ICU_MAJOR)=icuUColOpen \
	--rename-proc=ucol_setStrength_$(ICU_MAJOR)=icuUColSetStrength \
	--rename-proc=ucol_strcoll_$(ICU_MAJOR)=icuUColStrcoll \
	--rename-proc=u_errorName_$(ICU_MAJOR)=icuUErrorName \
	--rename-proc=u_foldCase_$(ICU_MAJOR)=icuUFoldCase \
	--rename-proc=u_isspace_$(ICU_MAJOR)=icuUIsSpace \
	--rename-proc=uregex_close_$(ICU_MAJOR)=icuURegexClose \
	--rename-proc=uregex_matches_$(ICU_MAJOR)=icuURegexMatches \
	--rename-proc=uregex_open_$(ICU_MAJOR)=icuURegexOpen \
	--rename-proc=uregex_setText_$(ICU_MAJOR)=icuURegexSetText \
	--rename-proc=u_strToLower_$(ICU_MAJOR)=icuUToLower \
	--rename-proc=u_strToUpper_$(ICU_MAJOR)=icuUToUpper \
	--rename-proc=u_strToUTF8_$(ICU_MAJOR)=icuUToUtf8
ICU_VERSION_STAMP = $(GEN_DIR)/sqlite3_icu_version_$(ICU_MAJOR)
$(TARGET): sqlite3_ext_icu.bas $(GEN_DIR)/sqlite3_icu_api.bi
endif

ifneq ($(findstring SQLITE_ENABLE_STMTVTAB,$(FB_DEFINE_FLAGS)),)
SOURCES += sqlite3_ext_stmtvtab.bas
endif

# The RBU implementation is an optional extension, not part of the default
# SQLite core build. Include its FreeBASIC module only when enabled explicitly.
ifneq ($(findstring SQLITE_ENABLE_RBU,$(FB_DEFINE_FLAGS)),)
SOURCES += sqlite3_rbu.bas
$(TARGET): sqlite3_rbu.bas sqlite3_rbu_types.bi
endif

.PHONY: all clean check-interrupt audit-core-source-inventory audit-function-bodies audit-extension-function-bodies audit-rbu-function-bodies audit-extension-api-table check-wal-seh-bridge-wine check-wal-seh-bridge-win32-wine check-win32-wal-seh-fault-wine check-win64-wal-seh-fault-wine check-win-vfs-callback-abi check-rtree-matcharg-layout check-rtree-matcharg-layout-win32-wine check-walker-layout check-walker-layout-win32-wine regen-generated regen-api-declarations reconcile-function-status regen-extension-api-table regen-pragma-data bulk-candidates bulk-candidate-files bulk-candidate-files-loose check-bulk-candidates bulk-candidates-loose check-bulk-candidate-files-loose

check-win-vfs-callback-abi:
	$(PYTHON) tools/check_win_vfs_callback_abi.py --dll "$(WIN_VFS_DLL)" --nm "$(LLVM_NM)"

# Compare the upstream C and production FreeBASIC R-Tree flexible-tail offsets.
check-rtree-matcharg-layout:
	mkdir -p build/rtree-matcharg-layout
	$(CC) -std=c99 -ffunction-sections -fdata-sections -I.. -I../src \
		-I../ext/rtree tests/rtree_matcharg_layout_reference.c \
		-Wl,--gc-sections -o build/rtree-matcharg-layout/reference
	$(FBC) -w all -i . tests/rtree_matcharg_layout.bas \
		-x build/rtree-matcharg-layout/freebasic
	build/rtree-matcharg-layout/reference > build/rtree-matcharg-layout/c-offset.txt
	build/rtree-matcharg-layout/freebasic > build/rtree-matcharg-layout/fb-offset.txt
	cmp build/rtree-matcharg-layout/c-offset.txt build/rtree-matcharg-layout/fb-offset.txt

# Compare the Win32 record offset through the production FreeBASIC type and SQLite amalgamation.
check-rtree-matcharg-layout-win32-wine:
	mkdir -p $(RTREE_LAYOUT_WIN32_DIR)
	$(RTREE_LAYOUT_WIN32_CC) -std=c99 -O0 -ffunction-sections -fdata-sections \
		tests/rtree_matcharg_layout_amalgamation_reference.c \
		-Wl,--gc-sections -o $(RTREE_LAYOUT_WIN32_DIR)/reference.exe
	$(FBC) -target i686-w64-mingw32 -gen gcc -w all -i . \
		tests/rtree_matcharg_layout.bas -x $(RTREE_LAYOUT_WIN32_DIR)/freebasic.exe
	WINEDEBUG=-all $(WIN_SEH_WINE) $(RTREE_LAYOUT_WIN32_DIR)/reference.exe \
		> $(RTREE_LAYOUT_WIN32_DIR)/c-offset.txt
	WINEDEBUG=-all $(WIN_SEH_WINE) $(RTREE_LAYOUT_WIN32_DIR)/freebasic.exe \
		> $(RTREE_LAYOUT_WIN32_DIR)/fb-offset.txt
	cmp $(RTREE_LAYOUT_WIN32_DIR)/c-offset.txt $(RTREE_LAYOUT_WIN32_DIR)/fb-offset.txt

# Compare the upstream Walker callback and union layout with the port's type.
check-walker-layout:
	mkdir -p build/walker-layout
	$(CC) -std=c99 -ffunction-sections -fdata-sections \
		tests/walker_layout_reference.c -Wl,--gc-sections \
		-o build/walker-layout/reference
	$(FBC) -w all -i . tests/walker_layout.bas \
		-x build/walker-layout/freebasic
	build/walker-layout/reference > build/walker-layout/c-layout.txt
	build/walker-layout/freebasic > build/walker-layout/fb-layout.txt
	cmp build/walker-layout/c-layout.txt build/walker-layout/fb-layout.txt

# Compare the same Walker ABI layout in the Win32 target under Wine.
check-walker-layout-win32-wine:
	mkdir -p $(WALKER_LAYOUT_WIN32_DIR)
	$(RTREE_LAYOUT_WIN32_CC) -std=c99 -O0 -ffunction-sections -fdata-sections \
		tests/walker_layout_reference.c -Wl,--gc-sections \
		-o $(WALKER_LAYOUT_WIN32_DIR)/reference.exe
	$(FBC) -target i686-w64-mingw32 -gen gcc -w all -i . \
		tests/walker_layout.bas -x $(WALKER_LAYOUT_WIN32_DIR)/freebasic.exe
	WINEDEBUG=-all $(WIN_SEH_WINE) $(WALKER_LAYOUT_WIN32_DIR)/reference.exe \
		> $(WALKER_LAYOUT_WIN32_DIR)/c-layout.txt
	WINEDEBUG=-all $(WIN_SEH_WINE) $(WALKER_LAYOUT_WIN32_DIR)/freebasic.exe \
		> $(WALKER_LAYOUT_WIN32_DIR)/fb-layout.txt
	cmp $(WALKER_LAYOUT_WIN32_DIR)/c-layout.txt $(WALKER_LAYOUT_WIN32_DIR)/fb-layout.txt

all: $(TARGET)

$(TARGET): $(SOURCES) $(WIN_SEH_OBJECTS) sqlite3_opcode_names.bas $(GENERATED_HEADERS) sqlite3_constants.bi sqlite3_types.bi sqlite3_mutex.bi sqlite3_status.bi sqlite3_db_types.bi sqlite3_stat4_types.bi sqlite3_percentile_types.bi sqlite3_parser_types.bi sqlite3_parser_token.bi sqlite3_expr_types.bi sqlite3_walker.bi sqlite3_window_state.bi sqlite3_fkey_types.bi sqlite3_schema_types.bi sqlite3_where_types.bi sqlite3_resolve_types.bi sqlite3_agginfo_types.bi sqlite3_walk_contexts.bi sqlite3_hash_types.bi sqlite3_bitvec.bi sqlite3_rowset.bi sqlite3_numeric.bi sqlite3_util_numeric.bi sqlite3_varint.bi sqlite3_fp.bi sqlite3_fault.bi sqlite3_vdbe_affinity.bi sqlite3_vdbe_compare.bi sqlite3_vdbe_serial.bi sqlite3_vdbe_record.bi sqlite3_vdbe_api.bi sqlite3_vdbe_mem_text.bi sqlite3_vdbe_mem_types.bi sqlite3_vdbe_core.bi sqlite3_vdbe_cursor.bi sqlite3_treeview_types.bi sqlite3_vdbesort_types.bi sqlite3_dbstat_types.bi sqlite3_result.bi sqlite3_straccum.bi sqlite3_json_string.bi sqlite3_json_values.bi sqlite3_json_parse.bi sqlite3_json_query.bi sqlite3_json_vtab_types.bi sqlite3_pcache.bi sqlite3_pcache1_types.bi sqlite3_vfs.bi sqlite3_os_kv_types.bi sqlite3_memjournal.bi sqlite3_memdb.bi sqlite3_pager.bi sqlite3_btree.bi sqlite3_integrity_types.bi sqlite3_insert_helpers.bi sqlite3_backup_types.bi sqlite3_memory_methods.bi sqlite3_date_types.bi sqlite3_vtab_types.bi sqlite3_carray_types.bi sqlite3_bytecode_vtab_types.bi sqlite3_pragma_types.bi sqlite3_pragma_helpers.bi sqlite3_std_types.bi sqlite3_collation.bi sqlite3.map
	mkdir -p $(dir $@)
	$(FBC) $(FB_TARGET_FLAGS) $(THREAD_FLAGS) -dll -d SQLITE_THREADSAFE=$(THREADSAFE) $(FB_PLATFORM_DEFINE_FLAGS) $(FB_DEFINE_FLAGS) \
		$(MEMDEBUG_BACKTRACE_FLAGS) \
		$(FB_LINK_FLAGS) -x $@ $(SOURCES) $(WIN_SEH_OBJECTS) $(if $(findstring SQLITE_ENABLE_ICU,$(FB_DEFINE_FLAGS)),$(ICU_LINK_FLAGS))
	$(WIN_SEH_POST_LINK)

ifneq ($(findstring SQLITE_ENABLE_ICU,$(FB_DEFINE_FLAGS)),)
$(C2FB):
	$(MAKE) -C ../fb_tools/c2fb converter FBC="$(FBC)" TARGET=build/c2fb

$(ICU_VERSION_STAMP):
	mkdir -p $(GEN_DIR)
	touch $@

$(GEN_DIR)/sqlite3_icu_api.bi: sqlite3_icu_api.h $(ICU_VERSION_STAMP) $(C2FB) ../fb_tools/c2fb/c2fb.bas $(wildcard ../fb_tools/c2fb/c2fb_*.bi)
	mkdir -p $(GEN_DIR)
	$(C2FB) generic-header $< $@ $(CC) $(ICU_C2FB_OPTIONS) $(ICU_CFLAGS)
endif

# The process-wide directory globals are declared through this shared include.
$(TARGET): sqlite3_process_globals.bi sqlite3_os_test.bi sqlite3_mutex_windows.bi sqlite3_os_win_types.bi

$(TARGET): sqlite3_os_unix_types.bi

$(TARGET): sqlite3_vdbe_test.bi

$(TARGET): sqlite3_os_win_syscall_types.bi sqlite3_os_win_syscall_dispatch.bi sqlite3_os_win_syscall_table.bi

$(TARGET): sqlite3_win_exception_types.bi

$(TARGET): sqlite3_memdb_types.bi

$(TARGET): sqlite3_memsys3_types.bi

$(TARGET): sqlite3_dbpage_types.bi

$(TARGET): sqlite3_bulk_feature_dbpage.bas

$(TARGET): sqlite3_bulk_rtree.bas sqlite3_rtree_types.bi sqlite3_geopoly_body.bi sqlite3_geopoly_types.bi sqlite3_bulk_fts5_varint.bas sqlite3_fts5_varint_types.bi sqlite3_bulk_fts5_buffer.bas sqlite3_fts5_buffer_types.bi sqlite3_bulk_fts5_hash.bas sqlite3_fts5_hash_types.bi sqlite3_bulk_fts5_storage.bas sqlite3_fts5_storage_types.bi sqlite3_bulk_fts5_config.bas sqlite3_fts5_config_types.bi sqlite3_bulk_fts5_main.bas sqlite3_fts5_main_types.bi sqlite3_bulk_fts5_expr.bas sqlite3_bulk_fts5_expr_test.bas sqlite3_fts5_expr_types.bi sqlite3_bulk_fts5_aux.bas sqlite3_fts5_aux_types.bi sqlite3_bulk_fts5_vocab.bas sqlite3_fts5_vocab_types.bi sqlite3_fts5_module_types.bi sqlite3_bulk_fts5_index.bas sqlite3_fts5_index_types.bi sqlite3_bulk_fts5_unicode2.bas sqlite3_fts5_unicode2_types.bi sqlite3_bulk_fts5_tokenize.bas sqlite3_fts5_tokenize_types.bi sqlite3_bulk_fts5_parser.bas sqlite3_debug_assert.bi

$(TARGET): sqlite3_iotrace.bi

$(TARGET): sqlite3_sqllog.bi

$(TARGET): sqlite3_bulk_fts3_hash.bas sqlite3_fts3_hash_types.bi

$(TARGET): sqlite3_bulk_fts3_unicode_data.bas sqlite3_fts3_unicode_types.bi

$(TARGET): sqlite3_bulk_fts3_unicode.bas sqlite3_fts3_unicode_types.bi sqlite3_fts3_tokenizer_types.bi

$(TARGET): sqlite3_bulk_fts3_porter.bas sqlite3_bulk_fts3_tokenizer1.bas sqlite3_fts3_tokenizer_types.bi

$(TARGET): sqlite3_bulk_fts3_tokenize_vtab.bas sqlite3_bulk_fts3_hash.bas sqlite3_fts3_hash_types.bi sqlite3_fts3_tokenizer_types.bi sqlite3_vtab_types.bi

ifneq ($(findstring SQLITE_ENABLE_ICU,$(FB_DEFINE_FLAGS)),)
$(TARGET): sqlite3_bulk_fts3_icu.bas $(GEN_DIR)/sqlite3_icu_api.bi
endif

$(TARGET): sqlite3_bulk_fts3_tokenizer_registry.bas sqlite3_fts3_tokenizer_types.bi sqlite3_vtab_types.bi sqlite3_vdbe_mem_types.bi sqlite3_db_types.bi sqlite3_fts3_hash_types.bi

$(TARGET): sqlite3_bulk_fts3_matchinfo_free.bas sqlite3_fts3_snippet_types.bi sqlite3_debug_assert.bi

$(TARGET): sqlite3_bulk_fts3_segreader_free.bas sqlite3_fts3_write_types.bi

$(TARGET): sqlite3_bulk_fts3_segreader_finish.bas sqlite3_fts3_write_types.bi

$(TARGET): sqlite3_bulk_fts3_deferred_tokens.bas sqlite3_fts3_write_types.bi sqlite3_fts3_expr_types.bi

$(TARGET): sqlite3_bulk_fts3_segreader_new.bas sqlite3_fts3_write_types.bi

$(TARGET): sqlite3_bulk_fts3_segreader_pending.bas sqlite3_fts3_write_types.bi sqlite3_fts3_hash_types.bi

$(TARGET): sqlite3_bulk_fts3_read_block.bas sqlite3_fts3_write_types.bi

$(TARGET): sqlite3_bulk_fts3_prepare_stmt.bas sqlite3_fts3_write_types.bi

$(TARGET): sqlite3_bulk_fts3_statement_cache.bas sqlite3_fts3_write_types.bi

$(TARGET): sqlite3_bulk_fts3_expr_free.bas sqlite3_fts3_expr_types.bi sqlite3_fts3_write_types.bi sqlite3_debug_assert.bi

$(TARGET): sqlite3_bulk_fts3_expr_iterate.bas sqlite3_fts3_expr_types.bi sqlite3_debug_assert.bi

$(TARGET): sqlite3_bulk_fts3_expr_helpers.bas sqlite3_fts3_tokenizer_types.bi sqlite3_debug_assert.bi

$(TARGET): sqlite3_bulk_fts3_expr_parse.bas sqlite3_fts3_expr_types.bi sqlite3_fts3_tokenizer_types.bi sqlite3_fts3_hash_types.bi sqlite3_debug_assert.bi sqlite3_api_declarations.bi

$(TARGET): sqlite3_bulk_fts3_core.bas fts3_candidates/sqlite3_fts3_core_api.bi sqlite3_fts3_write_types.bi sqlite3_fts3_expr_types.bi sqlite3_fts3_hash_types.bi sqlite3_fts3_tokenizer_types.bi sqlite3_vtab_types.bi sqlite3_db_types.bi

$(TARGET): sqlite3_bulk_fts3_write.bas fts3_candidates/sqlite3_fts3_write_api.bi sqlite3_fts3_write_types.bi sqlite3_fts3_expr_types.bi sqlite3_fts3_hash_types.bi sqlite3_fts3_tokenizer_types.bi sqlite3_vtab_types.bi sqlite3_db_types.bi

$(TARGET): sqlite3_bulk_fts3_aux.bas sqlite3_fts3_write_types.bi sqlite3_vtab_types.bi sqlite3_db_types.bi sqlite3_vdbe_mem_types.bi

$(TARGET): sqlite3_bulk_fts3_snippet.bas sqlite3_fts3_snippet_types.bi fts3_candidates/sqlite3_fts3_snippet_api.bi fts3_candidates/sqlite3_fts3_core_api.bi sqlite3_fts3_expr_types.bi sqlite3_fts3_write_types.bi

$(TARGET): sqlite3_bulk_fts3_core_helpers.bas sqlite3_fts3_write_types.bi sqlite3_api_declarations.bi

$(TARGET): sqlite3_bulk_fts3_pending_list.bas sqlite3_fts3_write_types.bi sqlite3_api_declarations.bi

$(TARGET): sqlite3_bulk_fts3_primitives.bas sqlite3_types.bi sqlite3_constants.bi

$(TARGET): sqlite3_bulk_session.bas sqlite3_bulk_session_changeset.bas sqlite3_vdbe_record.bi sqlite3_varint.bi sqlite3_session_api.bi sqlite3_session_types.bi

$(TARGET): sqlite3_session_simple_api.bas sqlite3_session_types.bi

regen-generated:
	mkdir -p $(GEN_DIR)
	$(CC) -O2 -o $(GEN_DIR)/lemon ../tool/lemon.c
	# Keep runtime-disabled UPDATE/DELETE LIMIT syntax in the grammar so the
	# parser can report the same feature-disabled error as SQLite's C parser.
	$(GEN_DIR)/lemon -q -d$(abspath $(GEN_DIR)) \
		-DSQLITE_UDL_CAPABLE_PARSER \
		-T$(abspath ../tool/lempar.c) $(abspath ../src/parse.y)
	$(CC) -O2 -o $(GEN_DIR)/mkkeywordhash ../tool/mkkeywordhash.c
	cd $(GEN_DIR) && ./mkkeywordhash > keywordhash.h
	$(FBC) -w all -x $(CODEGEN) ../fb_tools/sqlite_codegen/sqlite_codegen.bas
	$(CODEGEN) tokens $(GEN_DIR)/parse.h sqlite3_tokens.bi
	$(CODEGEN) keywords $(GEN_DIR)/keywordhash.h sqlite3_keyword_data.bi
	$(CODEGEN) classes ../src/tokenize.c sqlite3_character_classes.bi
	$(CODEGEN) global-data ../src/global.c sqlite3_global_data.bi
	$(CODEGEN) parser-tables $(GEN_DIR)/parse.c sqlite3_parser_tables.bi
	$(CODEGEN) parser-rule-ids $(GEN_DIR)/parse.c sqlite3_parser_rule_ids.bi \
		sqlite3_parser_semantics.bas PORTING_PARSER_RULES.csv
	cat $(GEN_DIR)/parse.h ../src/vdbe.c | tclsh ../tool/mkopcodeh.tcl > $(GEN_DIR)/opcodes.h
	$(CODEGEN) opcodes $(GEN_DIR)/opcodes.h sqlite3_opcodes.bi
	$(CODEGEN) opcode-names $(GEN_DIR)/opcodes.h sqlite3_opcode_names.bas

regen-api-declarations:
	$(MAKE) -C ../fb_tools/c2fb FBC='$(FBC)' converter
	../fb_tools/c2fb/build/c2fb ../src/sqlite.h.in sqlite3_api_declarations.bi
	../fb_tools/c2fb/build/c2fb defines ../src/sqlite.h.in sqlite3_api_constants.bi
	../fb_tools/c2fb/build/c2fb fp-tables ../src/util.c sqlite3_fp10_tables.bi
	../fb_tools/c2fb/build/c2fb ../src/sqliteInt.h sqlite3_internal_api_declarations.bi

reconcile-function-status:
	$(MAKE) -C ../fb_tools/c2fb FBC='$(FBC)' converter
	../fb_tools/c2fb/build/c2fb reconcile-functions PORTING_FUNCTIONS.csv .

# Check every indexed C definition and compile debug/test plus upstream-disabled
# bodies in a separate audit library. The validation define only exposes
# bodies SQLite disables with false or debug-gated preprocessor conditions.
audit-core-source-inventory:
	$(PYTHON) tools/check_core_source_inventory.py

audit-function-bodies: audit-core-source-inventory audit-extension-api-table
	$(PYTHON) tools/check_function_body_coverage.py
	$(MAKE) FBC='$(FBC)' THREADSAFE='$(THREADSAFE)' FB_OS=unix \
		TARGET=build/function-body-audit/libsqlite3-fb-body-audit.so \
		FB_DEFINE_FLAGS='-d SQLITE_DEBUG -d SQLITE_TEST -d SQLITE3_FB_COMPILE_DISABLED_BODIES' all

audit-extension-function-bodies:
	$(PYTHON) tools/check_function_body_coverage.py PORTING_EXTENSION_FUNCTIONS.csv

audit-rbu-function-bodies:
	$(PYTHON) tools/check_function_body_coverage.py PORTING_RBU_FUNCTIONS.csv

audit-extension-api-table:
	$(PYTHON) tools/check_extension_api_table_coverage.py

# Compile the Windows-only callback boundary and execute a minimal FreeBASIC
# callback harness under Wine. This does not build or stand in for SQLite tests.
check-wal-seh-bridge-wine:
	mkdir -p $(WIN_SEH_SMOKE_DIR)
	$(FBC) -r -gen gcc -target win64 -asm att -i . -d SQLITE_OS_WIN \
		-o $(WIN_SEH_SMOKE_DIR)/sqlite_win_seh_bridge_smoke.c \
		tests/sqlite_win_seh_bridge_smoke.bas
	$(WIN_SEH_CC) --target=x86_64-w64-windows-gnu -fms-extensions -O2 -c \
		sqlite3_win_seh_bridge.c -o $(WIN_SEH_SMOKE_DIR)/sqlite3_win_seh_bridge.o
	$(WIN_SEH_CC) --target=x86_64-w64-windows-gnu -fms-extensions -O2 -c \
		$(WIN_SEH_SMOKE_DIR)/sqlite_win_seh_bridge_smoke.c \
		-o $(WIN_SEH_SMOKE_DIR)/sqlite_win_seh_bridge_smoke.o
	$(WIN_SEH_DLLTOOL) -m i386:x86-64 -d tests/wal_seh_ntdll.def \
		-l $(WIN_SEH_SMOKE_DIR)/ntdll.lib
	$(WIN_SEH_DLLTOOL) -m i386:x86-64 -d tests/wal_seh_kernel32.def \
		-l $(WIN_SEH_SMOKE_DIR)/kernel32.lib
	$(WIN_SEH_DLLTOOL) -m i386:x86-64 -d tests/wal_seh_msvcrt.def \
		-l $(WIN_SEH_SMOKE_DIR)/msvcrt.lib
	$(WIN_SEH_LINKER) /subsystem:console /entry:entry /nodefaultlib /machine:x64 \
		/out:$(WIN_SEH_SMOKE_DIR)/sqlite_win_seh_bridge_smoke.exe \
		$(WIN_SEH_SMOKE_DIR)/sqlite_win_seh_bridge_smoke.o \
		$(WIN_SEH_SMOKE_DIR)/sqlite3_win_seh_bridge.o \
		$(WIN_SEH_SMOKE_DIR)/ntdll.lib $(WIN_SEH_SMOKE_DIR)/kernel32.lib \
		$(WIN_SEH_SMOKE_DIR)/msvcrt.lib
	WINEDEBUG=-all $(WIN_SEH_WINE) $(WIN_SEH_SMOKE_DIR)/sqlite_win_seh_bridge_smoke.exe

# Exercise x86 SEH after removing the orphan .sxdata section emitted by ld.bfd.
check-wal-seh-bridge-win32-wine:
	mkdir -p $(WIN_SEH_TEST_DIR)
	$(FBC) -r -gen gcc -target i686-w64-mingw32 -asm intel -i . -d SQLITE_OS_WIN \
		-o $(WIN_SEH_TEST_DIR)/sqlite_win_seh_bridge_smoke.c \
		tests/sqlite_win_seh_bridge_smoke.bas
	$(WIN_SEH_CC) --target=i686-pc-windows-msvc -fms-extensions -O2 -c \
		sqlite3_win_seh_bridge.c -o $(WIN_SEH_TEST_DIR)/sqlite3_win_seh_bridge.o
	$(WIN_SEH_CC) --target=i686-pc-windows-msvc -fms-extensions -O2 -c \
		$(WIN_SEH_TEST_DIR)/sqlite_win_seh_bridge_smoke.c \
		-o $(WIN_SEH_TEST_DIR)/sqlite_win_seh_bridge_smoke.o
	$(WIN_SEH_TEST_LD) -m i386pe --subsystem console --entry _entry \
		-o $(WIN_SEH_TEST_DIR)/sqlite_win_seh_bridge_smoke.exe \
		$(WIN_SEH_TEST_DIR)/sqlite_win_seh_bridge_smoke.o \
		$(WIN_SEH_TEST_DIR)/sqlite3_win_seh_bridge.o $(WIN_SEH_TEST_LIBS)
	$(WIN_SEH_OBJCOPY) --remove-section=.sxdata \
		$(WIN_SEH_TEST_DIR)/sqlite_win_seh_bridge_smoke.exe
	WINEDEBUG=-all $(WIN_SEH_WINE) \
		$(WIN_SEH_TEST_DIR)/sqlite_win_seh_bridge_smoke.exe

ifneq ($(filter check-win32-wal-seh-fault-wine,$(MAKECMDGOALS)),)
ifneq ($(FB_OS),windows)
$(error check-win32-wal-seh-fault-wine requires FB_OS=windows)
endif
ifneq ($(FB_TARGET),win32)
$(error check-win32-wal-seh-fault-wine requires FB_TARGET=win32)
endif
ifeq ($(findstring SQLITE_USE_SEH,$(FB_DEFINE_FLAGS)),)
$(error check-win32-wal-seh-fault-wine requires -d SQLITE_USE_SEH in FB_DEFINE_FLAGS)
endif
endif

# Inject upstream fault point 650 through a real Win32 SQLite WAL operation.
check-win32-wal-seh-fault-wine: $(TARGET)
	mkdir -p $(WIN_SEH_FAULT_DIR)
	$(WIN_SEH_FAULT_CC) -std=c89 -Wall -Wextra -Werror -DSQLITE_TEST -I.. \
		tests/sqlite_windows_wal_seh_fault_smoke.c \
		-L$(dir $(TARGET)) -l$(notdir $(basename $(TARGET))) \
		-o $(WIN_SEH_FAULT_DIR)/sqlite_windows_wal_seh_fault_smoke.exe
	cp $(TARGET) $(WIN_SEH_FAULT_DIR)/
	cd $(WIN_SEH_FAULT_DIR) && WINEDEBUG=-all $(WIN_SEH_WINE) \
		./sqlite_windows_wal_seh_fault_smoke.exe
	cd $(WIN_SEH_FAULT_DIR) && WINEDEBUG=-all $(WIN_SEH_WINE) \
		./sqlite_windows_wal_seh_fault_smoke.exe

ifneq ($(filter check-win64-wal-seh-fault-wine,$(MAKECMDGOALS)),)
ifneq ($(FB_OS),windows)
$(error check-win64-wal-seh-fault-wine requires FB_OS=windows)
endif
ifneq ($(FB_TARGET),win64)
$(error check-win64-wal-seh-fault-wine requires FB_TARGET=win64)
endif
ifeq ($(findstring SQLITE_USE_SEH,$(FB_DEFINE_FLAGS)),)
$(error check-win64-wal-seh-fault-wine requires -d SQLITE_USE_SEH in FB_DEFINE_FLAGS)
endif
endif

# Run the same injected WAL fault through the Win64 DLL import library.
check-win64-wal-seh-fault-wine:
	test -f "$(WIN_SEH_FAULT_DLL)" && test -f "$(WIN_SEH_FAULT_DLL_IMPORT)"
	mkdir -p $(WIN_SEH_FAULT_DIR64)
	$(WIN_SEH_FAULT_CC64) --target=x86_64-pc-windows-msvc -fms-extensions \
		-O2 -DSQLITE_TEST -I.. -c tests/sqlite_windows_wal_seh_fault_smoke.c \
		-o $(WIN_SEH_FAULT_DIR64)/sqlite_windows_wal_seh_fault_smoke.obj
	$(WIN_SEH_DLLTOOL) -m i386:x86-64 -d tests/wal_seh_kernel32.def \
		-l $(WIN_SEH_FAULT_DIR64)/kernel32.lib
	$(WIN_SEH_FAULT_LINKER64) /machine:x64 /subsystem:console /entry:start \
		/nodefaultlib /out:$(WIN_SEH_FAULT_DIR64)/sqlite_windows_wal_seh_fault_smoke.exe \
		$(WIN_SEH_FAULT_DIR64)/sqlite_windows_wal_seh_fault_smoke.obj \
		$(WIN_SEH_FAULT_DIR64)/kernel32.lib $(WIN_SEH_FAULT_DLL_IMPORT)
	cp $(WIN_SEH_FAULT_DLL) $(WIN_SEH_FAULT_DIR64)/
	cd $(WIN_SEH_FAULT_DIR64) && WINEDEBUG=-all $(WIN_SEH_WINE) \
		./sqlite_windows_wal_seh_fault_smoke.exe
	cd $(WIN_SEH_FAULT_DIR64) && WINEDEBUG=-all $(WIN_SEH_WINE) \
		./sqlite_windows_wal_seh_fault_smoke.exe

bulk-candidates: regen-generated
	rm -rf "$(CANDIDATE_DIR)"
	mkdir -p "$(CANDIDATE_DIR)"
	$(MAKE) -C ../fb_tools/c2fb FBC='$(FBC)' converter
	../fb_tools/c2fb/build/c2fb translate-preprocessed-tree ../src $(GEN_DIR) '$(CANDIDATE_DIR)' . '$(CC)' '$(THREADSAFE)' 0 '$(FEATURE_DEFINES)' '$(INCLUDE_EXISTING)' $(C2FB_BODY_OPTIONS)
	../fb_tools/c2fb/build/c2fb reconcile-functions PORTING_FUNCTIONS.csv .
	../fb_tools/c2fb/build/c2fb api-routines $(CANDIDATE_DIR)/.c2fb_preprocessed/loadext.i PORTING_FUNCTIONS.csv sqlite3_bulk_loadext.bas sqlite3_extension_api_table.bi

bulk-candidate-files: regen-generated
	rm -rf "$(CANDIDATE_DIR)"
	mkdir -p "$(CANDIDATE_DIR)"
	$(MAKE) -C ../fb_tools/c2fb FBC='$(FBC)' converter
	../fb_tools/c2fb/build/c2fb translate-preprocessed-files ../src $(GEN_DIR) '$(CANDIDATE_DIR)' . '$(CC)' '$(THREADSAFE)' 0 '$(FEATURE_DEFINES)' '$(INCLUDE_EXISTING)' '$(SOURCE_FILES)' $(C2FB_BODY_OPTIONS)
	../fb_tools/c2fb/build/c2fb reconcile-functions PORTING_FUNCTIONS.csv .

bulk-candidate-files-loose: regen-generated
	rm -rf "$(LOOSE_CANDIDATE_DIR)"
	mkdir -p "$(LOOSE_CANDIDATE_DIR)"
	$(MAKE) -C ../fb_tools/c2fb FBC='$(FBC)' converter
	../fb_tools/c2fb/build/c2fb translate-preprocessed-files ../src $(GEN_DIR) '$(LOOSE_CANDIDATE_DIR)' . '$(CC)' '$(THREADSAFE)' 1 '$(FEATURE_DEFINES)' '$(INCLUDE_EXISTING)' '$(SOURCE_FILES)' $(C2FB_BODY_OPTIONS)
	../fb_tools/c2fb/build/c2fb reconcile-functions PORTING_FUNCTIONS.csv .

check-bulk-candidates: bulk-candidates
	$(MAKE) -C ../fb_tools/c2fb check-candidates FBC='$(FBC)' THREADSAFE='$(THREADSAFE)' \
		CANDIDATE_DIR='$(abspath $(CANDIDATE_DIR))' FB_SOURCE_DIR='$(abspath .)'

bulk-candidates-loose: regen-generated
	rm -rf "$(LOOSE_CANDIDATE_DIR)"
	mkdir -p "$(LOOSE_CANDIDATE_DIR)"
	$(MAKE) -C ../fb_tools/c2fb FBC='$(FBC)' converter
	../fb_tools/c2fb/build/c2fb translate-preprocessed-tree ../src $(GEN_DIR) \
		'$(LOOSE_CANDIDATE_DIR)' . '$(CC)' '$(THREADSAFE)' 1 '$(FEATURE_DEFINES)' '$(INCLUDE_EXISTING)' $(C2FB_BODY_OPTIONS)
	../fb_tools/c2fb/build/c2fb translate-preprocessed-files ../src $(GEN_DIR) \
		'$(PRAGMA_WIN_CANDIDATE_DIR)' . '$(PRAGMA_WIN_CC)' '$(THREADSAFE)' 1 \
		'$(FEATURE_DEFINES)' '$(INCLUDE_EXISTING)' 'pragma.c' $(C2FB_BODY_OPTIONS)
	$(CODEGEN) pragma-table $(LOOSE_CANDIDATE_DIR)/.c2fb_preprocessed/pragma.i \
		sqlite3_pragma_data.bi sqlite3_pragma_data.bas \
		$(PRAGMA_WIN_CANDIDATE_DIR)/.c2fb_preprocessed/pragma.i
	../fb_tools/c2fb/build/c2fb reconcile-functions PORTING_FUNCTIONS.csv .
	../fb_tools/c2fb/build/c2fb api-routines $(LOOSE_CANDIDATE_DIR)/.c2fb_preprocessed/loadext.i PORTING_FUNCTIONS.csv sqlite3_bulk_loadext.bas sqlite3_extension_api_table.bi

regen-extension-api-table: bulk-candidates-loose

regen-pragma-data: bulk-candidates-loose

check-bulk-candidates-loose: bulk-candidates-loose
	$(MAKE) -C ../fb_tools/c2fb check-candidates FBC='$(FBC)' THREADSAFE='$(THREADSAFE)' \
		CANDIDATE_DIR='$(abspath $(LOOSE_CANDIDATE_DIR))' FB_SOURCE_DIR='$(abspath .)'

check-bulk-candidate-files-loose: bulk-candidate-files-loose
	$(MAKE) -C ../fb_tools/c2fb check-candidates FBC='$(FBC)' THREADSAFE='$(THREADSAFE)' \
		CANDIDATE_DIR='$(abspath $(LOOSE_CANDIDATE_DIR))' FB_SOURCE_DIR='$(abspath .)'

check-interrupt:
	$(PYTHON) tests/test_interrupt_progress.py --fbc '$(FBC)' --make '$(MAKE)' \
		--threadsafe '$(THREADSAFE)'

clean:
	rm -rf build

# end of fb_src/Makefile
