/*
    Project: SQLite FreeBASIC port

    File: sqlite3_icu_api.h

    Purpose:

        Give C2FB a version-aware declaration set for the ICU APIs used by
        the FreeBASIC FTS3 tokenizer and SQLite ICU extension.

    Responsibilities:

        - Include ICU's public headers so exported names receive ICU's ABI
          version suffix during preprocessing.
        - Declare only the ICU calls used by the FreeBASIC ICU modules.

    This file intentionally does NOT contain:

        - Tokenizer or SQL extension behavior, state, or memory ownership.
        - ICU implementation code or declarations for unused ICU APIs.
*/

#include <unicode/ubrk.h>
#include <unicode/uchar.h>
#include <unicode/ucol.h>
#include <unicode/uregex.h>
#include <unicode/ustring.h>
#include <unicode/utypes.h>

extern UBreakIterator *ubrk_open(
    UBreakIteratorType type,
    const char *locale,
    const UChar *text,
    int32_t textLength,
    UErrorCode *status
);
extern void ubrk_close(UBreakIterator *iterator);
extern int32_t ubrk_current(const UBreakIterator *iterator);
extern int32_t ubrk_next(UBreakIterator *iterator);
extern int32_t ubrk_first(UBreakIterator *iterator);

extern UChar32 u_foldCase(UChar32 character, uint32_t options);
extern UBool u_isspace(UChar32 character);
extern char *u_strToUTF8(
    char *destination,
    int32_t capacity,
    int32_t *pLength,
    const UChar *source,
    int32_t sourceLength,
    UErrorCode *status
);

extern const char *u_errorName(UErrorCode status);
extern URegularExpression *uregex_open(
    const UChar *pattern,
    int32_t patternLength,
    uint32_t flags,
    UParseError *parseError,
    UErrorCode *status
);
extern void uregex_close(URegularExpression *regexp);
extern void uregex_setText(
    URegularExpression *regexp,
    const UChar *text,
    int32_t textLength,
    UErrorCode *status
);
extern UBool uregex_matches(
    URegularExpression *regexp,
    int32_t startIndex,
    UErrorCode *status
);
extern int32_t u_strToUpper(
    UChar *destination,
    int32_t destinationCapacity,
    const UChar *source,
    int32_t sourceLength,
    const char *locale,
    UErrorCode *status
);
extern int32_t u_strToLower(
    UChar *destination,
    int32_t destinationCapacity,
    const UChar *source,
    int32_t sourceLength,
    const char *locale,
    UErrorCode *status
);
extern UCollator *ucol_open(const char *locale, UErrorCode *status);
extern void ucol_close(UCollator *collator);
extern UCollationResult ucol_strcoll(
    const UCollator *collator,
    const UChar *left,
    int32_t leftLength,
    const UChar *right,
    int32_t rightLength
);
extern void ucol_setStrength(UCollator *collator, UCollationStrength strength);

/* end of sqlite3_icu_api.h */
