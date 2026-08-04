// Quran.com v4 API client для переводов Корана (translations).
//
// Спринт 2.6 (Round 8): добавлен как часть миграции с alquran.cloud
// на Quran.com. У нас уже был QuranComApi (для ректоров) и
// QuranComTafsirApi (для тафсиров); теперь — QuranComTranslationApi.
//
// Endpoints (verified 2026-07-23 curl):
//   GET /resources/translations?language=<L>    → list 126 translations
//   GET /quran/translations/{id}?verse_key={N:V} → text для одного аята
//   GET /quran/translations/{id}?chapter_number={N} → весь сура (bulk)
//
// Каждый translation имеет: id (= resource_id), name, author_name,
// language_name, slug ("quran.ru.kuliev"), translated_name (locale-specific).

import 'package:dio/dio.dart';

class QuranComTranslationDto {
  QuranComTranslationDto({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
    required this.slug,
    this.translatedName,
  });

  /// Quran.com resource_id (= auto-increment в локальной БД).
  final int id;

  /// Оригинальное название (часто арабское для Arabic-тафсиров).
  final String name;

  /// Автор оригинала (English transliteration).
  final String authorName;

  /// 'arabic' / 'russian' / 'english' / 'urdu' / etc.
  final String languageName;

  /// Unique slug: "quran.ru.kuliev", "ru-ministry-of-awqaf", etc.
  final String slug;

  /// Локализованное название (если запрашивали с ?language=X).
  /// Null если translationName == name (default English).
  final String? translatedName;

  factory QuranComTranslationDto.fromJson(Map<String, dynamic> j) {
    return QuranComTranslationDto(
      id: (j['id'] as num).toInt(),
      name: (j['name'] as String?) ?? '',
      authorName: (j['author_name'] as String?) ?? '',
      languageName: (j['language_name'] as String?) ?? '',
      slug: (j['slug'] as String?) ?? '',
      translatedName: (j['translated_name'] is Map)
          ? ((j['translated_name'] as Map)['name'] as String?)
          : null,
    );
  }

  /// Локализованное display name с fallback'ом на оригинал.
  String displayName(String? locale) {
    if (translatedName != null && translatedName!.isNotEmpty) {
      return translatedName!;
    }
    return name;
  }
}

class QuranComVerseTranslationDto {
  QuranComVerseTranslationDto({
    required this.translationId,
    required this.verseKey,
    required this.text,
  });

  final int translationId;
  final String verseKey; // "N:V"
  final String text;

  factory QuranComVerseTranslationDto.fromJson(
    Map<String, dynamic> j, {
    required int translationId,
    required String verseKey,
  }) {
    return QuranComVerseTranslationDto(
      translationId: translationId,
      verseKey: verseKey,
      text: (j['text'] as String?) ?? '',
    );
  }
}

/// Dio client для Quran.com translations.
///
/// Default Dio: 20s connect, 60s receive (по аналогии с
/// QuranComTafsirApi — на медленных сетях 30KB ответы могут идти 15-25s).
class QuranComTranslationApi {
  QuranComTranslationApi({Dio? dio})
      : _dio = dio ??
            (Dio()
              ..options.connectTimeout = const Duration(seconds: 20)
              ..options.receiveTimeout = const Duration(seconds: 60)
              ..options.headers = const {
                'Accept': 'application/json',
                'User-Agent': 'quran_app/1.0.0',
              });

  final Dio _dio;

  static const _base = 'https://api.quran.com/api/v4';

  /// Список translations, отфильтрованный по language_name.
  /// Возвращает весь список (~126 для language='en', ~3 для 'ru').
  Future<List<QuranComTranslationDto>> fetchTranslations({
    String language = 'ru',
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_base/resources/translations',
      queryParameters: {'language': language},
    );
    final list = (r.data?['translations'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(QuranComTranslationDto.fromJson)
        .toList(growable: false);
  }

  /// Один translation для конкретного аята.
  /// `verseKey` = "N:V" (1-indexed surah:ayah).
  Future<QuranComVerseTranslationDto?> fetchByAyah({
    required int translationId,
    required String verseKey,
  }) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '$_base/quran/translations/$translationId',
        queryParameters: {'verse_key': verseKey},
      );
      final obj = r.data?['translation'] as Map<String, dynamic>?;
      if (obj == null) return null;
      return QuranComVerseTranslationDto.fromJson(
        obj,
        translationId: translationId,
        verseKey: verseKey,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Bulk fetch всей суры. Возвращает `Map<ayahNumber (1-indexed), text>`.
  ///
  /// **Round 8 (2026-07-25)**: Quran.com v4 API response shape для
  /// `/quran/translations/{id}?chapter_number={N}`:
  /// ```json
  /// {
  ///   "translations": [
  ///     {"resource_id":78, "text":"..."},  // = аят N
  ///     {"resource_id":78, "text":"..."},  // = аят N+1
  ///     ...
  ///   ],
  ///   "meta": {...}
  /// }
  /// ```
  /// НЕТ поля `verse_key`! `ayah_number` определяется по индексу
  /// в массиве (0 → аят 1, 1 → аят 2, и т.д.).
  ///
  /// Для Аль-Фатиха (7 аятов) — массив из 7 элементов.
  /// Для Аль-Бакара (286 аятов) — массив из 286 элементов.
  ///
  /// Используется в `QuranTranslationSyncService._fetchAllSurahs`
  /// для 114 запросов (по одному на суру).
  Future<Map<int, String>> fetchByChapter({
    required int translationId,
    required int chapterNumber,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_base/quran/translations/$translationId',
      queryParameters: {'chapter_number': chapterNumber},
    );
    // Round 8 fix (2026-07-25): response shape — `translations: [...]`
    // (array), а не `translation: {verses: ...}` (как у tafsir).
    final translations = r.data?['translations'] as List?;
    if (translations == null) return const {};
    final result = <int, String>{};
    for (var i = 0; i < translations.length; i++) {
      final item = translations[i] as Map<String, dynamic>?;
      final text = item?['text'] as String?;
      if (text != null) result[i + 1] = text; // i+1 = ayah_number
    }
    return result;
  }
}
