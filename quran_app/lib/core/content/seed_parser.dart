import 'dart:convert';

import 'seed_types.dart';

/// Чистый парсер seed-JSON без зависимостей от Flutter SDK.
///
/// Используется [LocalSeedService.load] внутри runtime и тестируется
/// напрямую через `dart test` (без flutter_tester).
///
/// Идемпотентен: повторный вызов с тем же аргументом даёт идентичный
/// результат. Не мутирует входные данные.
class SeedParser {
  SeedParser._();

  /// Разбирает JSON-строку seed'а в [ContentDownloadResult].
  ///
  /// Ожидаемая структура JSON:
  /// ```
  /// {
  ///   "surahs": [...],
  ///   "translators": [...],
  ///   "translations": [...],
  ///   "words": [...] // optional, present after `tools/build_words_seed.dart` runs
  /// }
  /// ```
  static ContentDownloadResult parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final rawSurahs = (json['surahs'] as List).cast<Map<String, dynamic>>();
    final translators = (json['translators'] as List)
        .cast<Map<String, dynamic>>();
    final translations = (json['translations'] as List)
        .cast<Map<String, dynamic>>();
    final words = _parseWords(json);

    final surahs = rawSurahs.map(_surahToDownloadFormat).toList();
    final ayahs = _explodeAyahs(rawSurahs);

    return ContentDownloadResult(
      surahs: surahs,
      translators: translators,
      translations: translations,
      ayahs: ayahs,
      words: words,
    );
  }

  /// Extract the optional `words` block. Returns an empty list if
  /// the key is missing (pre-words-seed run) or if the entry is
  /// malformed (we drop the bad row rather than failing the whole
  /// seed).
  static List<Map<String, dynamic>> _parseWords(Map<String, dynamic> json) {
    final raw = json['words'];
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in raw.cast<dynamic>()) {
      if (item is! Map) continue;
      final m = item.cast<String, dynamic>();
      final ayahId = m['ayah_id'];
      final position = m['position'];
      final arabic = m['arabic'];
      if (ayahId is! int || position is! int || arabic is! String) {
        continue;
      }
      out.add({
        'ayah_id': ayahId,
        'position': position,
        'arabic': arabic,
        'translation': m['translation'],
        'lemma': m['lemma'],
        'root': m['root'],
      });
    }
    return out;
  }

  /// JSON хранит аяты вложенно в `surah.ayahs: [{number, numberInSurah, text}]`.
  /// Чтобы не менять [ContentDownloader] / [ContentBootstrapper], разворачиваем
  /// в плоский список — тот же формат, что и API.
  ///
  /// Принимает **исходный** список (с ключами `id` и `ayahs`), а не
  /// трансформированный через [_surahToDownloadFormat] (где этих ключей нет).
  static List<Map<String, dynamic>> _explodeAyahs(
    List<Map<String, dynamic>> surahs,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final s in surahs) {
      final surahId = s['id'] as int;
      for (final a in (s['ayahs'] as List).cast<Map<String, dynamic>>()) {
        out.add({
          'id': a['number'] as int,
          'surah_id': surahId,
          'ayah_number': a['numberInSurah'] as int,
          'text_uthmani': a['text'] as String,
        });
      }
    }
    return out;
  }

  static Map<String, dynamic> _surahToDownloadFormat(Map<String, dynamic> s) {
    return {
      'number': s['id'],
      'name': s['name_ar'],
      'englishName': s['name_en'],
      'englishNameTranslation': s['name_transliteration'],
      'revelationType': s['revelation_type'],
      'numberOfAyahs': s['ayah_count'],
    };
  }
}
