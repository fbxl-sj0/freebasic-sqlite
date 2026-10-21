# SQLite FreeBASIC port build rules
#
# Build only the FreeBASIC source in this directory. The main SQLite build
# does not include this tree until the port has enough API coverage to link
# existing clients.

FBC ?= fbc
CC ?= cc
PYTHON ?= python3
PKG_CONFIG ?= pkg-config
THREADSAFE ?= 1
FB_OS ?= unix
FB_TARGET ?= win64
FEATURE_DEFINES ?=
BODY_TYPE_MAPS ?=
BODY_OPTIONS ?=
C2FB_BODY_OPTIONS = $(BODY_TYPE_MAPS) $(BODY_OPTIONS)
FB_DEFINE_FLAGS ?=
ICU_MAJOR ?= $(shell $(PKG_CONFIG) --modversion icu-i18n 2>/dev/null | sed 's/\..*//')
ICU_CFLAGS ?= $(shell $(PKG_CONFIG) --cflags icu-i18n 2>/dev/null)
ICU_LINK_FLAGS ?= $(shell $(PKG_CONFIG) --libs icu-i18n 2>/dev/null | sed 's/-l\([^ ]*\)/-l \1/g')
C2FB ?= ../fb_tools/c2fb/build/c2fb
MEMDEBUG_BACKTRACE_FLAGS ?= $(if $(shell getconf GNU_LIBC_VERSION 2>/dev/null),-d SQLITE3_FB_GLIBC_BACKTRACE=1)
FB_PLATFORM_DEFINE_FLAGS =
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
FB_TARGET_FLAGS ?= -target $(FB_TARGET) -asm att
FB_PLATFORM_DEFINE_FLAGS = -d SQLITE_OS_WIN
FB_LINK_FLAGS ?= -l mingw32 -l mingwex -l msvcrt -l kernel32 -l user32 -l advapi32
MEMDEBUG_BACKTRACE_FLAGS :=
TARGET ?= build/sqlite3-fb-$(FB_TARGET).dll
UNIX_ONLY_SOURCES = sqlite3_os_unix.bas $(wildcard sqlite3_bulk*os_unix*.bas) $(wildcard sqlite3_bulk*mutex_unix*.bas)
SOURCES := $(filter-out $(UNIX_ONLY_SOURCES),$(SOURCES))
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

.PHONY: all clean check-interrupt regen-generated regen-api-declarations reconcile-function-status regen-extension-api-table regen-pragma-data bulk-candidates bulk-candidate-files bulk-candidate-files-loose check-bulk-candidates bulk-candidates-loose check-bulk-candidates-loose check-bulk-candidate-files-loose

all: $(TARGET)

$(TARGET): $(SOURCES) sqlite3_opcode_names.bas $(GENERATED_HEADERS) sqlite3_constants.bi sqlite3_types.bi sqlite3_mutex.bi sqlite3_status.bi sqlite3_db_types.bi sqlite3_stat4_types.bi sqlite3_percentile_types.bi sqlite3_parser_types.bi sqlite3_parser_token.bi sqlite3_expr_types.bi sqlite3_walker.bi sqlite3_window_state.bi sqlite3_fkey_types.bi sqlite3_schema_types.bi sqlite3_where_types.bi sqlite3_resolve_types.bi sqlite3_agginfo_types.bi sqlite3_walk_contexts.bi sqlite3_hash_types.bi sqlite3_bitvec.bi sqlite3_rowset.bi sqlite3_numeric.bi sqlite3_util_numeric.bi sqlite3_varint.bi sqlite3_fp.bi sqlite3_fault.bi sqlite3_vdbe_affinity.bi sqlite3_vdbe_compare.bi sqlite3_vdbe_serial.bi sqlite3_vdbe_record.bi sqlite3_vdbe_api.bi sqlite3_vdbe_mem_text.bi sqlite3_vdbe_mem_types.bi sqlite3_vdbe_core.bi sqlite3_vdbe_cursor.bi sqlite3_treeview_types.bi sqlite3_vdbesort_types.bi sqlite3_dbstat_types.bi sqlite3_result.bi sqlite3_straccum.bi sqlite3_json_string.bi sqlite3_json_values.bi sqlite3_json_parse.bi sqlite3_json_query.bi sqlite3_json_vtab_types.bi sqlite3_pcache.bi sqlite3_pcache1_types.bi sqlite3_vfs.bi sqlite3_os_kv_types.bi sqlite3_memjournal.bi sqlite3_memdb.bi sqlite3_pager.bi sqlite3_btree.bi sqlite3_integrity_types.bi sqlite3_insert_helpers.bi sqlite3_backup_types.bi sqlite3_memory_methods.bi sqlite3_date_types.bi sqlite3_vtab_types.bi sqlite3_carray_types.bi sqlite3_bytecode_vtab_types.bi sqlite3_pragma_types.bi sqlite3_pragma_helpers.bi sqlite3_std_types.bi sqlite3_collation.bi sqlite3.map
	mkdir -p $(dir $@)
	$(FBC) $(FB_TARGET_FLAGS) $(THREAD_FLAGS) -dll -d SQLITE_THREADSAFE=$(THREADSAFE) $(FB_PLATFORM_DEFINE_FLAGS) $(FB_DEFINE_FLAGS) \
		$(MEMDEBUG_BACKTRACE_FLAGS) \
		$(FB_LINK_FLAGS) -x $@ $(SOURCES) $(if $(findstring SQLITE_ENABLE_ICU,$(FB_DEFINE_FLAGS)),$(ICU_LINK_FLAGS))

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
	$(CODEGEN) pragma-table $(LOOSE_CANDIDATE_DIR)/.c2fb_preprocessed/pragma.i \
		sqlite3_pragma_data.bi sqlite3_pragma_data.bas
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
