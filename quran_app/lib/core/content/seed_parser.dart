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
  ///   "surahs": [
  ///     { "id": 1, "name_ar": ..., "name_en": ..., "name_transliteration": ...,
  ///       "revelation_type": ..., "ayah_count": 7, "ayahs": [
  ///         { "number": 1, "numberInSurah": 1, "text": "..." },
  ///         ...
  ///       ] },
  ///     ...
  ///   ],
  ///   "translators": [ { "id": 1, "name": ..., "language_code": ..., "source": ... }, ... ],
  ///   "translations": [ { "ayah_id": 1, "translator_id": 1, "language_code": ..., "text": ... }, ... ]
  /// }
  /// ```
  static ContentDownloadResult parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final rawSurahs = (json['surahs'] as List).cast<Map<String, dynamic>>();
    final translators = (json['translators'] as List)
        .cast<Map<String, dynamic>>();
    final translations = (json['translations'] as List)
        .cast<Map<String, dynamic>>();

    final surahs = rawSurahs.map(_surahToDownloadFormat).toList();
    final ayahs = _explodeAyahs(rawSurahs);

    return ContentDownloadResult(
      surahs: surahs,
      translators: translators,
      translations: translations,
      ayahs: ayahs,
    );
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
