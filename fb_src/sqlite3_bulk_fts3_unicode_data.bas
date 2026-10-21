/'
** 2012-05-25
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
******************************************************************************
'/
/'
    Project: SQLite FreeBASIC port

    File: sqlite3_bulk_fts3_unicode_data.bas

    Purpose:

        Port the generated Unicode tables and helpers from
        ext/fts3/fts3_unicode2.c.

    Responsibilities:

        - Classify Unicode letters and numbers through packed range tables.
        - Fold case and remove configured diacritics.
        - Preserve the generated upstream tables as compile-time constants.

    This file intentionally does NOT contain:

        - UTF-8 token iteration or tokenizer configuration.
        - Test support.
'/

#lang "fb"
#if (defined(SQLITE_ENABLE_FTS3) OrElse defined(SQLITE_ENABLE_FTS4)) AndAlso _
    Not defined(SQLITE_OMIT_VIRTUALTABLE)
#include once "sqlite3_types.bi"
#include once "sqlite3_fts3_unicode_types.bi"
#include once "sqlite3_debug_assert.bi"
#if Not defined(SQLITE_DISABLE_FTS3_UNICODE)


/' ------------------------------------------------------------------------- '/
/' C ABI type aliases used by translated routine bodies                      '/
/' ------------------------------------------------------------------------- '/

#ifndef __C2FB_BODY_C_ABI_TYPES__
#define __C2FB_BODY_C_ABI_TYPES__

#ifndef __C2FB_ABI_TYPE_C_INT__
#define __C2FB_ABI_TYPE_C_INT__
Type c2fb_c_int As SQLITE_C_INT
#endif
#ifndef __C2FB_ABI_TYPE_C_UINT__
#define __C2FB_ABI_TYPE_C_UINT__
Type c2fb_c_uint As SQLITE_C_UINT
#endif
#ifndef __C2FB_ABI_TYPE_C_LONG__
#define __C2FB_ABI_TYPE_C_LONG__
Type c2fb_c_long As SQLITE_C_LONG
#endif
#ifndef __C2FB_ABI_TYPE_C_ULONG__
#define __C2FB_ABI_TYPE_C_ULONG__
Type c2fb_c_ulong As SQLITE_C_ULONG
#endif
#ifndef __C2FB_ABI_TYPE_INT64__
#define __C2FB_ABI_TYPE_INT64__
Type c2fb_int64 As sqlite3_int64
#endif
#ifndef __C2FB_ABI_TYPE_UINT64__
#define __C2FB_ABI_TYPE_UINT64__
Type c2fb_uint64 As sqlite3_uint64
#endif
#ifndef __C2FB_ABI_TYPE_SIZE_T__
#define __C2FB_ABI_TYPE_SIZE_T__
Type c2fb_size_t As SQLITE_SIZE_T
#endif
#endif


/' Generated Unicode tables from ext/fts3/fts3_unicode2.c. '/
Private Dim Shared As Const c2fb_c_uint fts3UnicodeIsalnumRanges(0 To 405) = { _
    &H00000030ULL, &H0000E807ULL, &H00016C06ULL, &H0001EC2FULL, &H0002AC07ULL, &H0002D001ULL, &H0002D803ULL, &H0002EC01ULL, &H0002FC01ULL, &H00035C01ULL, &H0003DC01ULL, &H000B0804ULL, _
    &H000B480EULL, &H000B9407ULL, &H000BB401ULL, &H000BBC81ULL, &H000DD401ULL, &H000DF801ULL, &H000E1002ULL, &H000E1C01ULL, &H000FD801ULL, &H00120808ULL, &H00156806ULL, &H00162402ULL, _
    &H00163C01ULL, &H00164437ULL, &H0017CC02ULL, &H00180005ULL, &H00181816ULL, &H00187802ULL, &H00192C15ULL, &H0019A804ULL, &H0019C001ULL, &H001B5001ULL, &H001B580FULL, &H001B9C07ULL, _
    &H001BF402ULL, &H001C000EULL, &H001C3C01ULL, &H001C4401ULL, &H001CC01BULL, &H001E980BULL, &H001FAC09ULL, &H001FD804ULL, &H00205804ULL, &H00206C09ULL, &H00209403ULL, &H0020A405ULL, _
    &H0020C00FULL, &H00216403ULL, &H00217801ULL, &H0023901BULL, &H00240004ULL, &H0024E803ULL, &H0024F812ULL, &H00254407ULL, &H00258804ULL, &H0025C001ULL, &H00260403ULL, &H0026F001ULL, _
    &H0026F807ULL, &H00271C02ULL, &H00272C03ULL, &H00275C01ULL, &H00278802ULL, &H0027C802ULL, &H0027E802ULL, &H00280403ULL, &H0028F001ULL, &H0028F805ULL, &H00291C02ULL, &H00292C03ULL, _
    &H00294401ULL, &H0029C002ULL, &H0029D401ULL, &H002A0403ULL, &H002AF001ULL, &H002AF808ULL, &H002B1C03ULL, &H002B2C03ULL, &H002B8802ULL, &H002BC002ULL, &H002C0403ULL, &H002CF001ULL, _
    &H002CF807ULL, &H002D1C02ULL, &H002D2C03ULL, &H002D5802ULL, &H002D8802ULL, &H002DC001ULL, &H002E0801ULL, &H002EF805ULL, &H002F1803ULL, &H002F2804ULL, &H002F5C01ULL, &H002FCC08ULL, _
    &H00300403ULL, &H0030F807ULL, &H00311803ULL, &H00312804ULL, &H00315402ULL, &H00318802ULL, &H0031FC01ULL, &H00320802ULL, &H0032F001ULL, &H0032F807ULL, &H00331803ULL, &H00332804ULL, _
    &H00335402ULL, &H00338802ULL, &H00340802ULL, &H0034F807ULL, &H00351803ULL, &H00352804ULL, &H00355C01ULL, &H00358802ULL, &H0035E401ULL, &H00360802ULL, &H00372801ULL, &H00373C06ULL, _
    &H00375801ULL, &H00376008ULL, &H0037C803ULL, &H0038C401ULL, &H0038D007ULL, &H0038FC01ULL, &H00391C09ULL, &H00396802ULL, &H003AC401ULL, &H003AD006ULL, &H003AEC02ULL, &H003B2006ULL, _
    &H003C041FULL, &H003CD00CULL, &H003DC417ULL, &H003E340BULL, &H003E6424ULL, &H003EF80FULL, &H003F380DULL, &H0040AC14ULL, &H00412806ULL, &H00415804ULL, &H00417803ULL, &H00418803ULL, _
    &H00419C07ULL, &H0041C404ULL, &H0042080CULL, &H00423C01ULL, &H00426806ULL, &H0043EC01ULL, &H004D740CULL, &H004E400AULL, &H00500001ULL, &H0059B402ULL, &H005A0001ULL, &H005A6C02ULL, _
    &H005BAC03ULL, &H005C4803ULL, &H005CC805ULL, &H005D4802ULL, &H005DC802ULL, &H005ED023ULL, &H005F6004ULL, &H005F7401ULL, &H0060000FULL, &H0062A401ULL, &H0064800CULL, &H0064C00CULL, _
    &H00650001ULL, &H00651002ULL, &H0066C011ULL, &H00672002ULL, &H00677822ULL, &H00685C05ULL, &H00687802ULL, &H0069540AULL, &H0069801DULL, &H0069FC01ULL, &H006A8007ULL, &H006AA006ULL, _
    &H006C0005ULL, &H006CD011ULL, &H006D6823ULL, &H006E0003ULL, &H006E840DULL, &H006F980EULL, &H006FF004ULL, &H00709014ULL, &H0070EC05ULL, &H0071F802ULL, &H00730008ULL, &H00734019ULL, _
    &H0073B401ULL, &H0073C803ULL, &H00770027ULL, &H0077F004ULL, &H007EF401ULL, &H007EFC03ULL, &H007F3403ULL, &H007F7403ULL, &H007FB403ULL, &H007FF402ULL, &H00800065ULL, &H0081A806ULL, _
    &H0081E805ULL, &H00822805ULL, &H0082801AULL, &H00834021ULL, &H00840002ULL, &H00840C04ULL, &H00842002ULL, &H00845001ULL, &H00845803ULL, &H00847806ULL, &H00849401ULL, &H00849C01ULL, _
    &H0084A401ULL, &H0084B801ULL, &H0084E802ULL, &H00850005ULL, &H00852804ULL, &H00853C01ULL, &H00864264ULL, &H00900027ULL, &H0091000BULL, &H0092704EULL, &H00940200ULL, &H009C0475ULL, _
    &H009E53B9ULL, &H00AD400AULL, &H00B39406ULL, &H00B3BC03ULL, &H00B3E404ULL, &H00B3F802ULL, &H00B5C001ULL, &H00B5FC01ULL, &H00B7804FULL, &H00B8C00CULL, &H00BA001AULL, &H00BA6C59ULL, _
    &H00BC00D6ULL, &H00BFC00CULL, &H00C00005ULL, &H00C02019ULL, &H00C0A807ULL, &H00C0D802ULL, &H00C0F403ULL, &H00C26404ULL, &H00C28001ULL, &H00C3EC01ULL, &H00C64002ULL, &H00C6580AULL, _
    &H00C70024ULL, &H00C8001FULL, &H00C8A81EULL, &H00C94001ULL, &H00C98020ULL, &H00CA2827ULL, &H00CB003FULL, &H00CC0100ULL, &H01370040ULL, &H02924037ULL, &H0293F802ULL, &H02983403ULL, _
    &H0299BC10ULL, &H029A7C01ULL, &H029BC008ULL, &H029C0017ULL, &H029C8002ULL, &H029E2402ULL, &H02A00801ULL, &H02A01801ULL, &H02A02C01ULL, &H02A08C09ULL, &H02A0D804ULL, &H02A1D004ULL, _
    &H02A20002ULL, &H02A2D011ULL, &H02A33802ULL, &H02A38012ULL, &H02A3E003ULL, &H02A4980AULL, &H02A51C0DULL, &H02A57C01ULL, &H02A60004ULL, &H02A6CC1BULL, &H02A77802ULL, &H02A8A40EULL, _
    &H02A90C01ULL, &H02A93002ULL, &H02A97004ULL, &H02A9DC03ULL, &H02A9EC01ULL, &H02AAC001ULL, &H02AAC803ULL, &H02AADC02ULL, &H02AAF802ULL, &H02AB0401ULL, &H02AB7802ULL, &H02ABAC07ULL, _
    &H02ABD402ULL, &H02AF8C0BULL, &H03600001ULL, &H036DFC02ULL, &H036FFC02ULL, &H037FFC01ULL, &H03EC7801ULL, &H03ECA401ULL, &H03EEC810ULL, &H03F4F802ULL, &H03F7F002ULL, &H03F8001AULL, _
    &H03F88007ULL, &H03F8C023ULL, &H03F95013ULL, &H03F9A004ULL, &H03FBFC01ULL, &H03FC040FULL, &H03FC6807ULL, &H03FCEC06ULL, &H03FD6C0BULL, &H03FF8007ULL, &H03FFA007ULL, &H03FFE405ULL, _
    &H04040003ULL, &H0404DC09ULL, &H0405E411ULL, &H0406400CULL, &H0407402EULL, &H040E7C01ULL, &H040F4001ULL, &H04215C01ULL, &H04247C01ULL, &H0424FC01ULL, &H04280403ULL, &H04281402ULL, _
    &H04283004ULL, &H0428E003ULL, &H0428FC01ULL, &H04294009ULL, &H0429FC01ULL, &H042CE407ULL, &H04400003ULL, &H0440E016ULL, &H04420003ULL, &H0442C012ULL, &H04440003ULL, &H04449C0EULL, _
    &H04450004ULL, &H04460003ULL, &H0446CC0EULL, &H04471404ULL, &H045AAC0DULL, &H0491C004ULL, &H05BD442EULL, &H05BE3C04ULL, &H074000F6ULL, &H07440027ULL, &H0744A4B5ULL, &H07480046ULL, _
    &H074C0057ULL, &H075B0401ULL, &H075B6C01ULL, &H075BEC01ULL, &H075C5401ULL, &H075CD401ULL, &H075D3C01ULL, &H075DBC01ULL, &H075E2401ULL, &H075EA401ULL, &H075F0C01ULL, &H07BBC002ULL, _
    &H07C0002CULL, &H07C0C064ULL, &H07C2800FULL, &H07C2C40EULL, &H07C3040FULL, &H07C3440FULL, &H07C4401FULL, &H07C4C03CULL, &H07C5C02BULL, &H07C7981DULL, &H07C8402BULL, &H07C90009ULL, _
    &H07C94002ULL, &H07CC0021ULL, &H07CCC006ULL, &H07CCDC46ULL, &H07CE0014ULL, &H07CE8025ULL, &H07CF1805ULL, &H07CF8011ULL, &H07D0003FULL, &H07D10001ULL, &H07D108B6ULL, &H07D3E404ULL, _
    &H07D4003EULL, &H07D50004ULL, &H07D54018ULL, &H07D7EC46ULL, &H07D9140BULL, &H07DA0046ULL, &H07DC0074ULL, &H38000401ULL, &H38008060ULL, &H380400F0ULL _
}
Private Dim Shared As Const c2fb_c_uint fts3UnicodeAsciiMask(0 To 3) = { _
    &HFFFFFFFFULL, &HFC00FFFFULL, &HF8000001ULL, &HF8000001ULL _
}
Private Dim Shared As Const UShort fts3UnicodeRemoveDia(0 To 125) = { _
    0, 1797, 1848, 1859, 1891, 1928, 1940, 1995, 2024, 2040, 2060, 2110, _
    2168, 2206, 2264, 2286, 2344, 2383, 2472, 2488, 2516, 2596, 2668, 2732, _
    2782, 2842, 2894, 2954, 2984, 3000, 3028, 3336, 3456, 3696, 3712, 3728, _
    3744, 3766, 3832, 3896, 3912, 3928, 3944, 3968, 4008, 4040, 4056, 4106, _
    4138, 4170, 4202, 4234, 4266, 4296, 4312, 4344, 4408, 4424, 4442, 4472, _
    4488, 4504, 6148, 6198, 6264, 6280, 6360, 6429, 6505, 6529, 61448, 61468, _
    61512, 61534, 61592, 61610, 61642, 61672, 61688, 61704, 61726, 61784, 61800, 61816, _
    61836, 61880, 61896, 61914, 61948, 61998, 62062, 62122, 62154, 62184, 62200, 62218, _
    62252, 62302, 62364, 62410, 62442, 62478, 62536, 62554, 62584, 62604, 62640, 62648, _
    62656, 62664, 62730, 62766, 62830, 62890, 62924, 62974, 63032, 63050, 63082, 63118, _
    63182, 63242, 63274, 63310, 63368, 63390 _
}
Private Dim Shared As Const UByte fts3UnicodeRemoveChar(0 To 125) = { _
    &H00, &H61, &H63, &H65, &H69, &H6E, &H6F, &H75, &H79, &H79, &H61, &H63, _
    &H64, &H65, &H65, &H67, &H68, &H69, &H6A, &H6B, &H6C, &H6E, &H6F, &H72, _
    &H73, &H74, &H75, &H75, &H77, &H79, &H7A, &H6F, &H75, &H61, &H69, &H6F, _
    &H75, &HF5, &HE1, &H67, &H6B, &H6F, &HEF, &H6A, &H67, &H6E, &HE1, &H61, _
    &H65, &H69, &H6F, &H72, &H75, &H73, &H74, &H68, &H61, &H65, &HEF, &H6F, _
    &HEF, &H79, &H00, &H00, &H00, &H00, &H00, &H00, &H00, &H00, &H61, &H62, _
    &HE3, &H64, &H64, &HE5, &H65, &HE5, &H66, &H67, &H68, &H68, &H69, &HE9, _
    &H6B, &H6C, &HEC, &H6C, &H6D, &H6E, &HEF, &H70, &H72, &HF2, &H72, &H73, _
    &HF3, &H74, &H75, &HF5, &H76, &H77, &H77, &H78, &H79, &H7A, &H68, &H74, _
    &H77, &H79, &H61, &HE1, &HE1, &HE1, &H65, &HE5, &HE5, &H69, &H6F, &HEF, _
    &HEF, &HEF, &H75, &HF5, &HF5, &H79 _
}
Private Dim Shared As Const UShort fts3UnicodeFoldCode(0 To 162) = { _
    65, 181, 192, 216, 256, 306, 313, 330, 376, 377, 383, 385, _
    386, 390, 391, 393, 395, 398, 399, 400, 401, 403, 404, 406, _
    407, 408, 412, 413, 415, 416, 422, 423, 425, 428, 430, 431, _
    433, 435, 439, 440, 444, 452, 453, 455, 456, 458, 459, 478, _
    497, 498, 502, 503, 504, 544, 546, 570, 571, 573, 574, 577, _
    579, 580, 581, 582, 837, 880, 886, 902, 904, 908, 910, 913, _
    931, 962, 975, 976, 977, 981, 982, 984, 1008, 1009, 1012, 1013, _
    1015, 1017, 1018, 1021, 1024, 1040, 1120, 1162, 1216, 1217, 1232, 1329, _
    4256, 4295, 4301, 7680, 7835, 7838, 7840, 7944, 7960, 7976, 7992, 8008, _
    8025, 8040, 8072, 8088, 8104, 8120, 8122, 8124, 8126, 8136, 8140, 8152, _
    8154, 8168, 8170, 8172, 8184, 8186, 8188, 8486, 8490, 8491, 8498, 8544, _
    8579, 9398, 11264, 11360, 11362, 11363, 11364, 11367, 11373, 11374, 11375, 11376, _
    11378, 11381, 11390, 11392, 11499, 11506, 42560, 42624, 42786, 42802, 42873, 42877, _
    42878, 42891, 42893, 42896, 42912, 42922, 65313 _
}
Private Dim Shared As Const UByte fts3UnicodeFoldFlags(0 To 162) = { _
    14, 64, 14, 14, 1, 1, 1, 1, 116, 1, 104, 50, _
    1, 44, 0, 42, 0, 32, 38, 40, 0, 42, 46, 52, _
    48, 0, 52, 54, 56, 1, 60, 0, 60, 0, 60, 0, _
    58, 1, 62, 0, 0, 2, 0, 2, 0, 2, 1, 1, _
    2, 1, 122, 134, 1, 110, 1, 70, 0, 108, 68, 0, _
    106, 28, 30, 1, 36, 1, 0, 18, 16, 26, 24, 14, _
    14, 0, 4, 140, 142, 146, 144, 1, 136, 138, 130, 128, _
    0, 152, 0, 110, 34, 14, 1, 1, 6, 1, 1, 22, _
    66, 66, 66, 1, 132, 96, 1, 150, 150, 150, 150, 150, _
    151, 150, 150, 150, 150, 150, 126, 148, 100, 124, 148, 150, _
    120, 150, 118, 152, 112, 114, 148, 98, 92, 94, 12, 8, _
    0, 10, 22, 0, 88, 102, 90, 1, 84, 86, 80, 82, _
    0, 0, 78, 1, 1, 0, 1, 1, 1, 1, 1, 76, _
    1, 0, 74, 1, 1, 72, 14 _
}
Private Dim Shared As Const UByte fts3UnicodeFoldRange(0 To 162) = { _
    26, 1, 23, 7, 48, 6, 16, 46, 1, 6, 1, 1, _
    4, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, _
    1, 1, 1, 1, 1, 6, 1, 1, 1, 1, 1, 1, _
    2, 4, 1, 1, 1, 1, 1, 1, 1, 1, 18, 18, _
    1, 4, 1, 1, 40, 1, 18, 1, 1, 1, 1, 1, _
    1, 1, 1, 10, 1, 4, 1, 1, 3, 1, 2, 17, _
    9, 1, 1, 1, 1, 1, 1, 24, 1, 1, 1, 1, _
    1, 1, 1, 3, 16, 32, 34, 54, 1, 14, 88, 38, _
    38, 1, 1, 150, 1, 1, 96, 8, 6, 8, 8, 6, _
    8, 8, 8, 8, 8, 2, 2, 1, 1, 4, 1, 2, _
    2, 2, 2, 1, 2, 2, 1, 1, 1, 1, 1, 16, _
    1, 26, 47, 1, 1, 1, 1, 6, 1, 1, 1, 1, _
    1, 1, 2, 100, 4, 1, 46, 24, 14, 62, 4, 1, _
    10, 1, 1, 4, 10, 1, 26 _
}
Private Dim Shared As Const UShort fts3UnicodeFoldOffset(0 To 76) = { _
    1, 2, 8, 15, 16, 26, 28, 32, 37, 38, 40, 48, _
    63, 64, 69, 71, 79, 80, 116, 202, 203, 205, 206, 207, _
    209, 210, 211, 213, 214, 217, 218, 219, 775, 7264, 10792, 10795, _
    23228, 23256, 30204, 54721, 54753, 54754, 54756, 54787, 54793, 54809, 57153, 57274, _
    57921, 58019, 58363, 61722, 65268, 65341, 65373, 65406, 65408, 65410, 65415, 65424, _
    65436, 65439, 65450, 65462, 65472, 65476, 65478, 65480, 65482, 65488, 65506, 65511, _
    65514, 65521, 65527, 65528, 65529 _
}

/' ------------------------------------------------------------------------- '/
/' Unicode classification and folding                                       '/
/' ------------------------------------------------------------------------- '/

/'
    The diacritic table stores the packed lower-case codepoint key. Its
    companion byte uses the high bit to mark folds that require complex
    diacritic removal. The arrays are private and never change at runtime.
'/
Private Function remove_diacritic ( _
    ByVal codepoint As c2fb_c_int, _
    ByVal complexMode As c2fb_c_int _
) As c2fb_c_int
    Dim key As c2fb_c_uint
    Dim resultIndex As c2fb_c_int
    Dim highIndex As c2fb_c_int
    Dim lowIndex As c2fb_c_int
    Dim testIndex As c2fb_c_int

    key = (Cast(c2fb_c_uint, codepoint) Shl 3) Or Cast(c2fb_c_uint, 7)
    resultIndex = 0
    highIndex = UBound(fts3UnicodeRemoveDia)
    lowIndex = 0

    While highIndex >= lowIndex
        testIndex = (highIndex + lowIndex) \ 2
        If key >= fts3UnicodeRemoveDia(testIndex) Then
            resultIndex = testIndex
            lowIndex = testIndex + 1
        Else
            highIndex = testIndex - 1
        End If
    Wend

#ifdef SQLITE_DEBUG
    ASSERT(key >= fts3UnicodeRemoveDia(resultIndex))
#endif
    If complexMode = 0 AndAlso _
        (fts3UnicodeRemoveChar(resultIndex) And &H80) <> 0 Then
        Return codepoint
    End If

    If codepoint > ((fts3UnicodeRemoveDia(resultIndex) Shr 3) + _
        (fts3UnicodeRemoveDia(resultIndex) And 7)) Then
        Return codepoint
    End If

    Return Cast(c2fb_c_int, fts3UnicodeRemoveChar(resultIndex) And &H7F)
End Function

/'
    Search the sorted exclusion ranges. A codepoint outside every range is
    classified as a letter or number, matching the generated SQLite table.
'/
Function sqlite3FtsUnicodeIsalnum CDecl Alias "sqlite3FtsUnicodeIsalnum" ( _
    ByVal codepoint As c2fb_c_int _
) As c2fb_c_int
    Dim unsignedCodepoint As c2fb_c_uint
    Dim key As c2fb_c_uint
    Dim rangeIndex As c2fb_c_int
    Dim highIndex As c2fb_c_int
    Dim lowIndex As c2fb_c_int
    Dim testIndex As c2fb_c_int
    Dim rangeEnd As c2fb_c_uint
    Dim asciiBit As c2fb_c_uint

    unsignedCodepoint = Cast(c2fb_c_uint, codepoint)
    If unsignedCodepoint < 128 Then
        rangeIndex = Cast(c2fb_c_int, unsignedCodepoint Shr 5)
        asciiBit = Cast(c2fb_c_uint, 1) Shl (unsignedCodepoint And &H1F)
        If (fts3UnicodeAsciiMask(rangeIndex) And asciiBit) = 0 Then
            Return 1
        End If
        Return 0
    End If

    If unsignedCodepoint < 4194304 Then
        key = (unsignedCodepoint Shl 10) Or Cast(c2fb_c_uint, &H3FF)
        rangeIndex = 0
        highIndex = UBound(fts3UnicodeIsalnumRanges)
        lowIndex = 0

        While highIndex >= lowIndex
            testIndex = (highIndex + lowIndex) \ 2
            If key >= fts3UnicodeIsalnumRanges(testIndex) Then
                rangeIndex = testIndex
                lowIndex = testIndex + 1
            Else
                highIndex = testIndex - 1
            End If
        Wend

#ifdef SQLITE_DEBUG
        ASSERT(fts3UnicodeIsalnumRanges(0) < key)
        ASSERT(key >= fts3UnicodeIsalnumRanges(rangeIndex))
#endif
        rangeEnd = (fts3UnicodeIsalnumRanges(rangeIndex) Shr 10) + _
            (fts3UnicodeIsalnumRanges(rangeIndex) And &H3FF)
        If unsignedCodepoint >= rangeEnd Then Return 1
        Return 0
    End If

    Return 1
End Function

Function sqlite3FtsUnicodeIsdiacritic CDecl Alias "sqlite3FtsUnicodeIsdiacritic" ( _
    ByVal codepoint As c2fb_c_int _
) As c2fb_c_int
    Dim mask0 As c2fb_c_uint = &H08029FDFULL
    Dim mask1 As c2fb_c_uint = &H000361F8ULL
    Dim bitMask As c2fb_c_uint

    If codepoint < 768 OrElse codepoint > 817 Then Return 0

    If codepoint < 800 Then
        bitMask = Cast(c2fb_c_uint, 1) Shl (codepoint - 768)
        Return Cast(c2fb_c_int, mask0 And bitMask)
    End If

    bitMask = Cast(c2fb_c_uint, 1) Shl (codepoint - 800)
    Return Cast(c2fb_c_int, mask1 And bitMask)
End Function

Function sqlite3FtsUnicodeFold CDecl Alias "sqlite3FtsUnicodeFold" ( _
    ByVal codepoint As c2fb_c_int, _
    ByVal removeDiacriticMode As c2fb_c_int _
) As c2fb_c_int
    Dim result As c2fb_c_int = codepoint
    Dim highIndex As c2fb_c_int
    Dim lowIndex As c2fb_c_int
    Dim resultIndex As c2fb_c_int
    Dim testIndex As c2fb_c_int
    Dim compareValue As c2fb_c_int
    Dim tableCodepoint As c2fb_c_int
    Dim tableFlags As c2fb_c_int
    Dim tableRange As c2fb_c_int
    Dim tableOffset As c2fb_c_int
    Dim complexMode As c2fb_c_int

    If codepoint < 128 Then
        If codepoint >= Asc("A") AndAlso codepoint <= Asc("Z") Then
            result = codepoint + (Asc("a") - Asc("A"))
        End If
    ElseIf codepoint < 65536 Then
#ifdef SQLITE_DEBUG
        ASSERT(codepoint > fts3UnicodeFoldCode(0))
#endif
        highIndex = UBound(fts3UnicodeFoldCode)
        lowIndex = 0
        resultIndex = -1

        While highIndex >= lowIndex
            testIndex = (highIndex + lowIndex) \ 2
            compareValue = codepoint - fts3UnicodeFoldCode(testIndex)
            If compareValue >= 0 Then
                resultIndex = testIndex
                lowIndex = testIndex + 1
            Else
                highIndex = testIndex - 1
            End If
        Wend

#ifdef SQLITE_DEBUG
        ASSERT(resultIndex >= 0)
        ASSERT(codepoint >= fts3UnicodeFoldCode(resultIndex))
#endif
        tableCodepoint = fts3UnicodeFoldCode(resultIndex)
        tableFlags = fts3UnicodeFoldFlags(resultIndex)
        tableRange = fts3UnicodeFoldRange(resultIndex)
        If codepoint < tableCodepoint + tableRange AndAlso _
            ((1 And tableFlags And (tableCodepoint Xor codepoint)) = 0) Then
            tableOffset = fts3UnicodeFoldOffset(tableFlags Shr 1)
            result = (codepoint + tableOffset) And &HFFFF
#ifdef SQLITE_DEBUG
            ASSERT(result > 0)
#endif
        End If

        If removeDiacriticMode <> 0 Then
            complexMode = 0
            If removeDiacriticMode = 2 Then complexMode = 1
            result = remove_diacritic(result, complexMode)
        End If
    ElseIf codepoint >= 66560 AndAlso codepoint < 66600 Then
        result = codepoint + 40
    End If

    Return result
End Function
#endif
#endif

/' end of sqlite3_bulk_fts3_unicode_data.bas '/
