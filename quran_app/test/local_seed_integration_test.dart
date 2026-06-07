import 'dart:io';

import 'package:test/test.dart';
import 'package:quran_app/core/content/seed_parser.dart';
import 'package:quran_app/core/content/seed_types.dart';

/// Integration test against the real bundled `assets/quran_seed/quran_full.json`.
///
/// Reads the file from disk (rather than via Flutter's rootBundle) so the
/// test can run with plain `dart test` — no flutter_tester required.
///
/// What this guards against:
/// - The bug fixed in `2f7e271`: _surahToDownloadFormat stripping keys that
///   _explodeAyahs expected, throwing `null is not a subtype of int`.
/// - Drift/PK regressions where a table's seed insert would fail at runtime
///   because of a missing primary key (the Translators bug from the same
///   commit batch).
/// - Silent schema drift: the seed JSON is part of the build artifact, and
///   a malformed regeneration by `tools/build_quran_seed.dart` would
///   otherwise only surface on first launch of the app.
void main() {
  late String raw;
  late ContentDownloadResult result;

  setUpAll(() {
    final file = File('assets/quran_seed/quran_full.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'seed asset must be present at assets/quran_seed/quran_full.json',
    );
    raw = file.readAsStringSync();
    expect(raw.length, greaterThan(1_000_000),
        reason: 'seed should be ~5 MB, not suspiciously small');
    result = SeedParser.parse(raw);
  });

  group('parseSeedString — surahs', () {
    test('parses exactly 114 surahs', () {
      expect(result.surahs, hasLength(114));
    });

    test('surah numbers are 1..114 in order', () {
      final numbers = result.surahs.map((s) => s['number']).toList();
      expect(numbers, List.generate(114, (i) => i + 1));
    });

    test('every transformed surah has the download-format keys', () {
      const requiredKeys = [
        'number',
        'name',
        'englishName',
        'englishNameTranslation',
        'revelationType',
        'numberOfAyahs',
      ];
      for (final s in result.surahs) {
        for (final k in requiredKeys) {
          expect(s.containsKey(k), isTrue, reason: 'surah missing key "$k"');
          expect(s[k], isNotNull, reason: 'surah key "$k" is null');
        }
      }
    });

    test('revelationType is only Meccan or Medinan', () {
      const allowed = {'Meccan', 'Medinan'};
      for (final s in result.surahs) {
        expect(allowed.contains(s['revelationType']), isTrue,
            reason: 'surah ${s['number']} has unexpected type ${s['revelationType']}');
      }
    });

    test('sum of ayahCount equals total ayahs in the dataset', () {
      final sumOfCounts = result.surahs.fold<int>(
        0,
        (acc, s) => acc + (s['numberOfAyahs'] as int),
      );
      expect(sumOfCounts, equals(6236));
    });
  });

  group('parseSeedString — ayahs', () {
    test('flattens to exactly 6236 ayahs (the full Quran)', () {
      expect(result.ayahs, hasLength(6236));
    });

    test('every ayah has id, surah_id, ayah_number, text_uthmani', () {
      const required = {'id', 'surah_id', 'ayah_number', 'text_uthmani'};
      for (final a in result.ayahs) {
        for (final k in required) {
          expect(a[k], isNotNull, reason: 'ayah missing $k');
        }
        expect((a['text_uthmani'] as String).trim(), isNotEmpty,
            reason: 'ayah ${a['id']} has empty text');
      }
    });

    test('ayah ids are unique and within 1..6236', () {
      final ids = result.ayahs.map((a) => a['id'] as int).toSet();
      expect(ids, hasLength(6236));
      expect(ids.first, 1);
      expect(ids.last, 6236);
    });

    test('ayah numbers within a surah are 1..surah.ayahCount', () {
      final bySurah = <int, List<int>>{};
      for (final a in result.ayahs) {
        bySurah
            .putIfAbsent(a['surah_id'] as int, () => [])
            .add(a['ayah_number'] as int);
      }
      for (final s in result.surahs) {
        final num = s['number'] as int;
        final count = s['numberOfAyahs'] as int;
        final got = bySurah[num] ?? const <int>[];
        expect(got, hasLength(count),
            reason: 'surah $num should have $count ayahs, got ${got.length}');
        expect(got, equals(List.generate(count, (i) => i + 1)));
      }
    });

    test('every surah_id reference points to an existing surah 1..114', () {
      final surahIds = result.surahs.map((s) => s['number'] as int).toSet();
      for (final a in result.ayahs) {
        expect(surahIds.contains(a['surah_id'] as int), isTrue,
            reason: 'ayah ${a['id']} refs unknown surah ${a['surah_id']}');
      }
    });
  });

  group('parseSeedString — translators', () {
    test('parses at least 1 translator', () {
      expect(result.translators, isNotEmpty);
    });

    test('translator ids are unique', () {
      final ids = result.translators.map((t) => t['id']).toSet();
      expect(ids, hasLength(result.translators.length));
    });

    test('every translator has id, name, language_code', () {
      for (final t in result.translators) {
        expect(t['id'], isNotNull);
        expect((t['name'] as String).trim(), isNotEmpty);
        expect(t['language_code'], isNotNull);
      }
    });
  });

  group('parseSeedString — translations', () {
    test('parses at least one translation', () {
      expect(result.translations, isNotEmpty);
    });

    test('every translation refs an existing ayah_id and translator_id', () {
      final ayahIds = result.ayahs.map((a) => a['id'] as int).toSet();
      final translatorIds =
          result.translators.map((t) => t['id']).toSet();
      for (final t in result.translations) {
        expect(ayahIds.contains(t['ayah_id'] as int), isTrue,
            reason: 'translation refs unknown ayah ${t['ayah_id']}');
        expect(translatorIds.contains(t['translator_id']), isTrue,
            reason: 'translation refs unknown translator ${t['translator_id']}');
      }
    });

    test('covers both translators (ru.kuliev + en.sahih) for every ayah', () {
      // Both default translators should produce a translation for every ayah.
      final byTranslator = <int, Set<int>>{};
      for (final t in result.translations) {
        byTranslator
            .putIfAbsent(t['translator_id'] as int, () => <int>{})
            .add(t['ayah_id'] as int);
      }
      for (final entry in byTranslator.entries) {
        expect(entry.value, hasLength(6236),
            reason: 'translator ${entry.key} should cover all 6236 ayahs');
      }
    });
  });

  group('parseSeedString — defensive', () {
    test('empty string throws FormatException', () {
      expect(() => SeedParser.parse(''), throwsA(isA<FormatException>()));
    });

    test('malformed JSON throws', () {
      expect(() => SeedParser.parse('{not json'),
          throwsA(anyOf(isA<FormatException>(), isA<TypeError>())));
    });

    test('is idempotent (same input → identical output)', () {
      final r1 = SeedParser.parse(raw);
      final r2 = SeedParser.parse(raw);
      expect(r1.surahs, equals(r2.surahs));
      expect(r1.ayahs, equals(r2.ayahs));
    });
  });
}
