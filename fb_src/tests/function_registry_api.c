/*
    Project: SQLite FreeBASIC port
    -----------------------------

    File: function_registry_api.c

    Purpose:

        Exercise the public application-function API and per-connection
        function overload registry through SQLite's C ABI.

    Responsibilities:

        • register mixed-case function names and arity overloads
        • verify UTF-8, UTF-16LE, and UTF-16BE registry entries
        • check encoding-aware function lookup and callback results
        • verify replacement, removal, and xDestroy lifecycle behavior

    This file intentionally does NOT contain:

        • SQLite engine implementation
        • a FreeBASIC translation of the upstream test suite
*/

#include "sqlite3.h"

#include <stdio.h>
#include <string.h>

typedef struct UserFunctionData UserFunctionData;
struct UserFunctionData {
    int offset;
    int destroyCount;
};

static void destroyUserFunction(void *applicationData) {
    UserFunctionData *data = (UserFunctionData *)applicationData;
    if (data != NULL) {
        data->destroyCount++;
    }
}

static void addOne(sqlite3_context *context, int argumentCount,
                   sqlite3_value **arguments) {
    UserFunctionData *data =
        (UserFunctionData *)sqlite3_user_data(context);

    if (data == NULL || argumentCount != 1) {
        sqlite3_result_error(context, "invalid addOne callback state", -1);
        return;
    }
    sqlite3_result_int64(context,
                         sqlite3_value_int64(arguments[0]) + data->offset);
}

static void addTwo(sqlite3_context *context, int argumentCount,
                   sqlite3_value **arguments) {
    UserFunctionData *data =
        (UserFunctionData *)sqlite3_user_data(context);

    if (data == NULL || argumentCount != 2) {
        sqlite3_result_error(context, "invalid addTwo callback state", -1);
        return;
    }
    sqlite3_result_int64(context,
                         sqlite3_value_int64(arguments[0]) +
                         sqlite3_value_int64(arguments[1]) + data->offset);
}

static int reportFailure(const char *operation, int resultCode,
                         sqlite3 *database) {
    fprintf(stderr, "%s failed: %d (%s)\n", operation, resultCode,
            database != NULL ? sqlite3_errmsg(database) : "no database");
    return 1;
}

static int registerFunction(sqlite3 *database, const char *name,
                            int argumentCount, int textEncoding,
                            UserFunctionData *data, void (*function)(
                                sqlite3_context *, int, sqlite3_value **)) {
    int resultCode = sqlite3_create_function_v2(
        database, name, argumentCount, textEncoding, data, function,
        NULL, NULL, destroyUserFunction);

    if (resultCode != SQLITE_OK) {
        return reportFailure("sqlite3_create_function_v2", resultCode,
                             database);
    }
    return 0;
}

static int checkFunctionEncodings(sqlite3 *database, int utf8Expected,
                                  int utf16leExpected, int utf16beExpected) {
    sqlite3_stmt *statement = NULL;
    int resultCode = sqlite3_prepare_v2(database, "PRAGMA function_list", -1,
                                        &statement, NULL);
    int utf8Count = 0;
    int utf16leCount = 0;
    int utf16beCount = 0;

    if (resultCode != SQLITE_OK) {
        return reportFailure("prepare PRAGMA function_list", resultCode,
                             database);
    }

    while ((resultCode = sqlite3_step(statement)) == SQLITE_ROW) {
        const unsigned char *name = sqlite3_column_text(statement, 0);
        const unsigned char *encoding = sqlite3_column_text(statement, 3);
        int isBuiltin = sqlite3_column_int(statement, 1);
        int argumentCount = sqlite3_column_int(statement, 4);

        if (isBuiltin != 0 || argumentCount != 1 || name == NULL ||
            strcmp((const char *)name, "mixed") != 0 || encoding == NULL) {
            continue;
        }
        if (strcmp((const char *)encoding, "utf8") == 0) {
            utf8Count++;
        } else if (strcmp((const char *)encoding, "utf16le") == 0) {
            utf16leCount++;
        } else if (strcmp((const char *)encoding, "utf16be") == 0) {
            utf16beCount++;
        }
    }

    if (resultCode != SQLITE_DONE) {
        sqlite3_finalize(statement);
        return reportFailure("step PRAGMA function_list", resultCode,
                             database);
    }
    resultCode = sqlite3_finalize(statement);
    if (resultCode != SQLITE_OK) {
        return reportFailure("finalize PRAGMA function_list", resultCode,
                             database);
    }

    if (utf8Count != utf8Expected || utf16leCount != utf16leExpected ||
        utf16beCount != utf16beExpected) {
        fprintf(stderr,
                "function_list encodings: UTF-8=%d UTF-16LE=%d UTF-16BE=%d; "
                "expected %d, %d, %d\n",
                utf8Count, utf16leCount, utf16beCount,
                utf8Expected, utf16leExpected, utf16beExpected);
        return 1;
    }
    return 0;
}

static int checkResults(sqlite3 *database, const char *sql,
                        sqlite3_int64 expectedFirst,
                        sqlite3_int64 expectedSecond, int checkSecond) {
    sqlite3_stmt *statement = NULL;
    int resultCode = sqlite3_prepare_v2(database, sql, -1, &statement, NULL);

    if (resultCode != SQLITE_OK) {
        return reportFailure("prepare function query", resultCode, database);
    }
    resultCode = sqlite3_step(statement);
    if (resultCode != SQLITE_ROW) {
        sqlite3_finalize(statement);
        return reportFailure("step function query", resultCode, database);
    }

    if (sqlite3_column_int64(statement, 0) != expectedFirst ||
        (checkSecond &&
         sqlite3_column_int64(statement, 1) != expectedSecond)) {
        fprintf(stderr, "unexpected function results for: %s\n", sql);
        sqlite3_finalize(statement);
        return 1;
    }

    resultCode = sqlite3_step(statement);
    if (resultCode != SQLITE_DONE) {
        sqlite3_finalize(statement);
        return reportFailure("finish function query", resultCode, database);
    }
    resultCode = sqlite3_finalize(statement);
    if (resultCode != SQLITE_OK) {
        return reportFailure("finalize function query", resultCode,
                             database);
    }
    return 0;
}

static int testUtf8Registry(void) {
    sqlite3 *database = NULL;
    UserFunctionData utf8Initial = {10, 0};
    UserFunctionData utf8Replacement = {30, 0};
    UserFunctionData utf16le = {100, 0};
    UserFunctionData utf16be = {200, 0};
    UserFunctionData twoArguments = {20, 0};
    int resultCode;
    int failed = 0;

    resultCode = sqlite3_open(":memory:", &database);
    if (resultCode != SQLITE_OK) {
        return reportFailure("open UTF-8 database", resultCode, database);
    }

    failed |= registerFunction(database, "MiXeD", 1, SQLITE_UTF8,
                               &utf8Initial, addOne);
    failed |= registerFunction(database, "mixed", 1, SQLITE_UTF16LE,
                               &utf16le, addOne);
    failed |= registerFunction(database, "mixed", 1, SQLITE_UTF16BE,
                               &utf16be, addOne);
    failed |= registerFunction(database, "MIXED", 2, SQLITE_UTF8,
                               &twoArguments, addTwo);
    if (failed) {
        sqlite3_close(database);
        return 1;
    }

    failed |= checkFunctionEncodings(database, 1, 1, 1);
    failed |= checkResults(database, "SELECT MIXED(7), mixed(2,3)",
                           17, 25, 1);
    if (failed) {
        sqlite3_close(database);
        return 1;
    }

    resultCode = sqlite3_create_function_v2(
        database, "mixed", 1, SQLITE_UTF8, &utf8Replacement, addOne,
        NULL, NULL, destroyUserFunction);
    if (resultCode != SQLITE_OK) {
        sqlite3_close(database);
        return reportFailure("replace UTF-8 overload", resultCode, database);
    }
    if (utf8Initial.destroyCount != 1) {
        fprintf(stderr, "replaced UTF-8 callback destructor was not called\n");
        sqlite3_close(database);
        return 1;
    }

    failed |= checkResults(database, "SELECT mixed(7)", 37, 0, 0);
    if (failed) {
        sqlite3_close(database);
        return 1;
    }

    resultCode = sqlite3_create_function_v2(
        database, "MIXED", 1, SQLITE_UTF16BE, NULL, NULL,
        NULL, NULL, NULL);
    if (resultCode != SQLITE_OK) {
        sqlite3_close(database);
        return reportFailure("remove UTF-16BE overload", resultCode,
                             database);
    }
    if (utf16be.destroyCount != 1) {
        fprintf(stderr, "removed UTF-16BE callback destructor was not called\n");
        sqlite3_close(database);
        return 1;
    }
    failed |= checkFunctionEncodings(database, 1, 1, 0);

    resultCode = sqlite3_close(database);
    if (resultCode != SQLITE_OK) {
        return reportFailure("close UTF-8 database", resultCode, database);
    }
    if (utf8Replacement.destroyCount != 1 || utf16le.destroyCount != 1 ||
        twoArguments.destroyCount != 1) {
        fprintf(stderr, "connection close did not destroy all callbacks\n");
        return 1;
    }
    return failed;
}

static int testUtf16Lookup(void) {
    sqlite3 *database = NULL;
    UserFunctionData utf8 = {10, 0};
    UserFunctionData utf16le = {100, 0};
    int resultCode;
    int failed = 0;

    resultCode = sqlite3_open(":memory:", &database);
    if (resultCode != SQLITE_OK) {
        return reportFailure("open UTF-16 database", resultCode, database);
    }
    resultCode = sqlite3_exec(database, "PRAGMA encoding='UTF-16le'",
                              NULL, NULL, NULL);
    if (resultCode != SQLITE_OK) {
        sqlite3_close(database);
        return reportFailure("set UTF-16LE database encoding", resultCode,
                             database);
    }

    failed |= registerFunction(database, "MiXeD", 1, SQLITE_UTF8,
                               &utf8, addOne);
    failed |= registerFunction(database, "mixed", 1, SQLITE_UTF16LE,
                               &utf16le, addOne);
    if (failed) {
        sqlite3_close(database);
        return 1;
    }

    failed |= checkFunctionEncodings(database, 1, 1, 0);
    failed |= checkResults(database, "SELECT mixed(7)", 107, 0, 0);
    resultCode = sqlite3_close(database);
    if (resultCode != SQLITE_OK) {
        return reportFailure("close UTF-16 database", resultCode, database);
    }
    if (utf8.destroyCount != 1 || utf16le.destroyCount != 1) {
        fprintf(stderr, "UTF-16 connection close missed a callback destructor\n");
        return 1;
    }
    return failed;
}

int main(void) {
    if (testUtf8Registry() != 0 || testUtf16Lookup() != 0) {
        return 1;
    }
    puts("PASS: function overload lookup, encodings, replacement, and cleanup");
    return 0;
}

/* end of function_registry_api.c */
