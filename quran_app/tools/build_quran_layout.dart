// One-shot script: regenerate `lib/core/data/quran_layout.dart` from
// `kJuzStarts` in `lib/core/data/juz_mapping.dart`.
//
// This is an APPROXIMATION of the canonical Madinah Mushaf page
// and hizb layout. We don't have a 6236-row dataset in-tree (the
// official tanzil.net / quran.com source lives outside this repo),
// so this script derives page/hizb from the juz boundaries we
// DO have. The numbers it emits are *not* the canonical mushaf
// numbers — see the comment on `QuranLayoutEntry` for the exact
// approximation rules.
//
// Regenerate with:
//   dart run tools/build_quran_layout.dart
import 'dart:io';

import '../lib/core/data/juz_mapping.dart';

void main() {
  // Cumulative ayah count at each juz boundary, in mushaf reading
  // order. We compute it by walking the canonical surah ayahCount
  // list (sourced from the same seed JSON the rest of the app
  // uses).
  const surahAyahCounts = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, // 1-10
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,   // 11-20
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,     // 21-30
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,        // 31-40
    54, 53, 89, 59, 37, 35, 38, 29, 45, 60,         // 41-50
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14,         // 51-60
    7, 21, 100, 11, 110, 98, 66, 52, 52, 44,        // 61-70
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,         // 71-80
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,         // 81-90
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,              // 91-100
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,                  // 101-110
    5, 4, 5, 6,                                   // 111-114
  ];
  assert(surahAyahCounts.length == 114);
  const totalAyahs = 6236;

  // Compute cumulative ayah offset at the start of each surah.
  final surahStartAyahIndex = <int>[]; // 0-based
  var sum = 0;
  for (final n in surahAyahCounts) {
    surahStartAyahIndex.add(sum);
    sum += n;
  }
  assert(sum == totalAyahs);

  /// Convert a (surah, ayah) to a 0-based global ayah index.
  int toGlobalAyahIndex(int surahId, int ayahNumber) {
    // 1-based ids; 0-based output.
    return surahStartAyahIndex[surahId - 1] + (ayahNumber - 1);
  }

  // Compute (surah, ayah) ranges for each Juz, expressed in
  // 0-based global ayah indices. The last Juz (Juz 30) ends at
  // the last ayah of the Quran.
  final juzStartGlobal = <int>[];
  final juzEndGlobal = <int>[];
  for (var i = 0; i < kJuzStarts.length; i++) {
    final s = kJuzStarts[i];
    juzStartGlobal.add(toGlobalAyahIndex(s.surahId, s.ayahNumber));
    if (i + 1 < kJuzStarts.length) {
      final next = kJuzStarts[i + 1];
      juzEndGlobal.add(toGlobalAyahIndex(next.surahId, next.ayahNumber) - 1);
    } else {
      juzEndGlobal.add(totalAyahs - 1);
    }
  }
  assert(juzStartGlobal.length == 30);
  assert(juzEndGlobal.length == 30);

  // Approximation rules:
  //   - hizb 2k - 1  -> start of Juz k.
  //   - hizb 2k      -> midpoint of Juz k (0-based global index).
  //   - page         -> 20 pages per Juz, evenly spaced.
  // Each Juz = 20 pages is the standard mushaf average (some Juz's
  // are 21 pages and others 19, but the median is 20).
  const pagesPerJuz = 20;
  const hizbsPerJuz = 2;

  // Build the 6236-row table.
  final entries = <String>[];
  for (var i = 0; i < totalAyahs; i++) {
    // Which Juz contains this global ayah index? Juz boundaries
    // are inclusive on both ends per the mushaf layout.
    var juzNumber = 1;
    for (var j = 0; j < 30; j++) {
      if (i >= juzStartGlobal[j] && i <= juzEndGlobal[j]) {
        juzNumber = j + 1;
        break;
      }
    }
    final juzStart = juzStartGlobal[juzNumber - 1];
    final juzEnd = juzEndGlobal[juzNumber - 1];
    final juzLen = juzEnd - juzStart + 1;
    final within = i - juzStart;

    // Hizb: even-hizb midpoint is at 50% of the Juz.
    final isFirstHalf = within * 2 < juzLen;
    final hizbNumber = (juzNumber - 1) * hizbsPerJuz + (isFirstHalf ? 1 : 2);

    // Page: 20 pages per Juz, evenly distributed. The first
    // ayah of the Juz maps to the first page of that Juz
    // (so e.g. Juz 1 page 1 == page 1 of the mushaf).
    final pagesOffset = pagesPerJuz == 1 || juzLen == 1
        ? 0
        : (within * pagesPerJuz / juzLen).floor().clamp(0, pagesPerJuz - 1);
    final pageNumber = (juzNumber - 1) * pagesPerJuz + pagesOffset + 1;

    entries.add(
      '    QuranLayoutEntry(surahId: ${_surahOf(i, surahStartAyahIndex)}, '
      'ayahNumber: ${_ayahOf(i, surahStartAyahIndex)}, '
      'page: $pageNumber, juz: $juzNumber, hizb: $hizbNumber)',
    );
  }

  final buf = StringBuffer()
    ..writeln(
      '// GENERATED FILE — do not edit by hand.',
    )
    ..writeln(
      '// Regenerate with: dart run tools/build_quran_layout.dart',
    )
    ..writeln(
      '//',
    )
    ..writeln(
      '// APPROXIMATION: page and hizb values are derived from',
    )
    ..writeln(
      '// [kJuzStarts] and the per-surah ayahCount table in the',
    )
    ..writeln(
      '// generator. The Mushaf page/hizb layout is not perfectly',
    )
    ..writeln(
      '// uniform across Juzs (some are 19 pages, some 21), so the',
    )
    ..writeln(
      '// numbers here are an even-spacing approximation. The juz',
    )
    ..writeln(
      '// column is exact (see [kJuzStarts] in juz_mapping.dart).',
    )
    ..writeln(
      '// When the seed grows a real 6236-row mushaf-layout dataset,',
    )
    ..writeln(
      '// swap this file out and keep the same [QuranLayoutEntry]',
    )
    ..writeln(
      '// API.',
    )
    ..writeln(
      '//',
    )
    ..writeln(
      '// Coverage check: the entries list must contain exactly one',
    )
    ..writeln(
      "// row per (surah, ayah) pair. The script asserts the count",
    )
    ..writeln(
      '// at build time.',
    )
    ..writeln()
    ..writeln('import \'../database/tables.dart\';')
    ..writeln()
    ..writeln(
      '/// Per-ayah mushaf-layout metadata for the entire Quran.',
    )
    ..writeln(
      '/// Carries the page, juz, and hizb each ayah belongs to in',
    )
    ..writeln(
      '/// the Madinah Mushaf. The juz column is exact; the page',
    )
    ..writeln(
      '/// and hizb columns are an approximation (see file header).',
    )
    ..writeln(
      'class QuranLayoutEntry {',
    )
    ..writeln(
      '  const QuranLayoutEntry({',
    )
    ..writeln(
      '    required this.surahId,',
    )
    ..writeln(
      '    required this.ayahNumber,',
    )
    ..writeln(
      '    required this.page,',
    )
    ..writeln(
      '    required this.juz,',
    )
    ..writeln(
      '    required this.hizb,',
    )
    ..writeln('  });')
    ..writeln()
    ..writeln('  final int surahId;')
    ..writeln('  final int ayahNumber;')
    ..writeln('  final int page;')
    ..writeln('  final int juz;')
    ..writeln('  final int hizb;')
    ..writeln('}')
    ..writeln()
    ..writeln(
      '/// All 6236 ayahs in canonical mushaf order. Indexed',
    )
    ..writeln(
      '/// positionally — [QuranLayoutEntry] at index `i` describes',
    )
    ..writeln(
      '/// the ayah with global mushaf ordinal `i + 1` (0-based).',
    )
    ..writeln('const kQuranLayout = <QuranLayoutEntry>[')
    ..writeln(entries.join(',\n'))
    ..writeln('];');

  final out = File('lib/core/data/quran_layout.dart');
  out.writeAsStringSync(buf.toString());
  stdout.writeln(
    'Wrote ${entries.length} entries to ${out.path} '
    '(${out.lengthSync()} bytes).',
  );
  // Quick sanity check on the first / middle / last entries.
  stdout.writeln('First:  ${entries.first}');
  stdout.writeln('Mid:    ${entries[entries.length ~/ 2]}');
  stdout.writeln('Last:   ${entries.last}');
}

int _surahOf(int globalIndex, List<int> surahStartAyahIndex) {
  for (var i = surahStartAyahIndex.length - 1; i >= 0; i--) {
    if (globalIndex >= surahStartAyahIndex[i]) return i + 1;
  }
  return 1;
}

int _ayahOf(int globalIndex, List<int> surahStartAyahIndex) {
  final surahId = _surahOf(globalIndex, surahStartAyahIndex);
  return globalIndex - surahStartAyahIndex[surahId - 1] + 1;
}
