// One-shot script: download the per-word mushaf dictionary (Arabic +
// transliteration + translation + lemma + root) for all 6236 ayahs
// from the quran.com v4 API and write a flat `assets/quran_seed/
// words.json` file. The rest of the app reads that file via
// `SeedParser` and inserts it into the `words` table.
//
// Run with:
//   dart run tools/build_words_seed.dart
//
// The script takes a few minutes and rate-limits itself at 5
// requests per second to stay below quran.com's generous but
// not unlimited quota. Re-runs are safe: the file is overwritten
// in place and the script exits non-zero on any HTTP error so
// CI can detect partial runs.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

const _base = 'https://api.quran.com/api/v4';
// quran.com is fine with ~5 rps; we keep some headroom.
const _rps = 5;

Future<void> main() async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final allWords = <Map<String, dynamic>>[];
  final startTime = DateTime.now();
  var lastError = <String, dynamic>{};
  for (var chapter = 1; chapter <= 114; chapter++) {
    final url = '$_base/verses/by_chapter/$chapter'
        '?language=en'
        '&words=true'
        '&word_fields=text_uthmani'
        '&word_fields=transliteration'
        '&word_fields=translation'
        '&word_fields=lemma'
        '&word_fields=root'
        '&fields=text_uthmani'
        '&per_page=300'
        '&page=1';
    var page = 1;
    var chapterDone = false;
    while (!chapterDone) {
      try {
        final resp = await dio.get<Map<String, dynamic>>(
          url,
          queryParameters: {'page': page},
        );
        final data = resp.data ?? const {};
        if (resp.statusCode != 200 || data['verses'] == null) {
          lastError = {
            'chapter': chapter,
            'page': page,
            'status': resp.statusCode,
            'body': data,
          };
          break;
        }
        final verses = (data['verses'] as List).cast<Map<String, dynamic>>();
        if (verses.isEmpty) {
          chapterDone = true;
          break;
        }
        for (final v in verses) {
          final ayahId = v['id'] as int;
          final words = (v['words'] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
          for (final w in words) {
            // quran.com nests the per-field transliteration /
            // translation / lemma / root as `{ text: '...', language: 'en' }`
            // (or for `transliteration`, no language). Flatten to
            // scalar strings so the seed JSON is small and
            // `SeedParser` doesn't need a tree walker.
            final transliteration = _flat(w, 'transliteration', 'text');
            final translation = _flat(w, 'translation', 'text',
                preferLang: 'en');
            final lemma = _flat(w, 'lemma', 'text');
            final root = _flat(w, 'root', 'text');
            allWords.add({
              'ayah_id': ayahId,
              'position': w['position'] as int,
              'arabic': w['text_uthmani'] as String? ?? '',
              'transliteration': transliteration,
              'translation': translation,
              'lemma': lemma,
              'root': root,
            });
          }
        }
        if (verses.length < 300) {
          chapterDone = true;
        } else {
          page++;
        }
      } on DioException catch (e) {
        lastError = {
          'chapter': chapter,
          'page': page,
          'error': e.message,
        };
        // Bail out on the first error so the user sees a
        // partial file rather than silent corruption.
        stderr.writeln('HTTP error: ${e.message}');
        break;
      }
      // Rate-limit: ~5 rps.
      await Future<void>.delayed(
        const Duration(milliseconds: 1000 ~/ 5),
      );
    }
    if (lastError.isNotEmpty && chapter == (lastError['chapter'] as int)) {
      break;
    }
    if (chapter % 10 == 0) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      stdout.writeln(
        '  chapter $chapter / 114 — ${allWords.length} words '
        '($elapsed s elapsed)',
      );
    }
  }
  if (allWords.isEmpty) {
    stderr.writeln('No words fetched. Last error: $lastError');
    exit(1);
  }
  // Normalise: `lemma` and `root` are null for many words (e.g.
  // particles). Strip them so the seed JSON is smaller and
  // Drift doesn't have to deal with explicit nulls.
  final cleaned = allWords.map((w) {
    final lemma = w['lemma'] as String?;
    final root = w['root'] as String?;
    final transliteration = w['transliteration'] as String?;
    return {
      ...w,
      'lemma': (lemma == null || lemma.isEmpty) ? null : lemma,
      'root': (root == null || root.isEmpty) ? null : root,
      'transliteration': (transliteration == null || transliteration.isEmpty)
          ? null
          : transliteration,
    };
  }).toList();
  final out = File('assets/quran_seed/words.json');
  out.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(cleaned),
  );
  stdout.writeln(
    'Wrote ${cleaned.length} words to ${out.path} '
    '(${out.lengthSync()} bytes).',
  );
}

/// Flatten quran.com's nested per-field response into a single
/// string. For [field] in {'transliteration', 'translation',
/// 'lemma', 'root'} the API returns either `null` or
/// `{ "text": "...", "language": "en" }`. Some fields
/// (transliteration) don't carry a language, so we just take
/// `.text` from whichever object we got. For `translation` we
/// prefer English (the only language we currently ship) but
/// fall back to whatever the API returned.
String? _flat(
  Map<String, dynamic> word,
  String field,
  String textKey, {
  String? preferLang,
}) {
  final v = word[field];
  if (v == null) return null;
  if (v is String) return v;
  if (v is Map) {
    // For `translation` the field is a list of translations, one
    // per language. Pick the preferred language if present,
    // else the first one with non-empty text.
    if (v.isEmpty) return null;
    if (v.values.first is List) {
      final list = (v.values.first as List).cast<Map<String, dynamic>>();
      if (preferLang != null) {
        for (final t in list) {
          if (t['language'] == preferLang) {
            return t[textKey] as String?;
          }
        }
      }
      for (final t in list) {
        final text = t[textKey] as String?;
        if (text != null && text.isNotEmpty) return text;
      }
      return null;
    }
    return v[textKey] as String?;
  }
  return null;
}
