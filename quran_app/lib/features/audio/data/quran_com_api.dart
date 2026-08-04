// Quran.com API v4 client.
//
// Sprint 1.5: миграция с mp3quran.net на Quran.com.
//
// Преимущества перед mp3quran:
//   - Официальный API (partnership с KFGQPC), structured metadata
//   - Per-verse audio files (вместо per-surah) — better seek precision
//   - Translation API (Sprint 2)
//   - Tafsir API (Sprint 2)
//   - Multi-language UI
//   - No rate-limit (verified 2026-07-13)
//
// Design: parallel API alongside Mp3QuranApi — fallback to mp3quran
// if Quran.com fails. Cutover in Phase 3 (Sprint 1.5d).
//
// Endpoints (verified):
//   - GET /api/v4/resources/recitations?language=ru → reciter list
//   - GET /api/v4/recitations/{id}/by_chapter/{chapter} → audio files
//   - GET /api/v4/chapters/{id}?language=ru → chapter info
//   - GET /api/v4/quran/verses/uthmani?verse_key=N:V → verse text
//
// Audio CDN base: https://verses.quran.com/{reciter_path}/mp3/{NNN}.mp3
//   где NNN — 6-значный (3 для суры + 3 для аята, 1-indexed).

import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class QuranComApi {
  QuranComApi({Dio? dio})
      : _dio = dio ??
            (Dio()
              ..options.connectTimeout = const Duration(seconds: 8)
              ..options.receiveTimeout = const Duration(seconds: 12)
              ..options.headers = const {
                'Accept': 'application/json',
                'User-Agent': 'quran_app/1.0.0',
              });

  final Dio _dio;

  /// Quran.com имеет 2 mirror'а:
  ///   - `api.quran.com` (canonical)
  ///   - `api.qurancdn.com` (CDN-fallback, иногда быстрее)
  /// Оба возвращают одинаковый контент, просто разная инфраструктура.
  static const _basePrimary = 'https://api.quran.com/api/v4';
  static const _audioCdn = 'https://verses.quran.com';

  /// Список ректоров с переводами имён.
  ///
  /// `language` ∈ {'ru', 'en', 'ar', ...}. Ответ содержит
  /// `translated_name.name` на указанном языке, fallback на 'en'.
  /// `style` (Murattal, Mujawwad, etc.) — null если не указан.
  Future<List<QuranComRecitationDto>> fetchRecitations({
    String language = 'ru',
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_basePrimary/resources/recitations',
      queryParameters: {'language': language},
    );
    final list = (r.data?['recitations'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(QuranComRecitationDto.fromJson)
        .toList(growable: false);
  }

  /// Multi-locale fetch: дёргает `/recitations?language=<l>` для каждого
  /// языка, объединяет результаты. Возвращает `Map<id, Recitation>` с
  /// заполненным `nameByLocale`.
  ///
  /// Используется при initial sync чтобы одной операцией сохранить
  /// nameAr / nameEn / nameRu в БД.
  Future<Map<int, QuranComRecitationDto>> fetchRecitationsMultiLocale({
    List<String> languages = const ['ar', 'en', 'ru'],
  }) async {
    final results = await Future.wait(
      languages.map((lang) async {
        try {
          final dtos = await fetchRecitations(language: lang);
          return MapEntry(lang, dtos);
        } catch (e) {
          developer.log(
            'quran_com fetchRecitations(language=$lang) failed: $e',
            name: 'quran_com',
          );
          return MapEntry(lang, <QuranComRecitationDto>[]);
        }
      }),
    );

    // Сливаем: canonical DTO берём из первого успешного locale,
    // namesByLocale собираем из всех.
    final canonicalById = <int, QuranComRecitationDto>{};
    final namesByReciter = <int, Map<String, String>>{};
    for (final entry in results) {
      final lang = entry.key;
      for (final d in entry.value) {
        if (!namesByReciter.containsKey(d.id)) {
          canonicalById[d.id] = d;
        }
        final names = namesByReciter.putIfAbsent(d.id, () => {});
        if (d.translatedName.isNotEmpty) names[lang] = d.translatedName;
      }
    }
    final merged = <int, QuranComRecitationDto>{};
    canonicalById.forEach((id, d) {
      merged[id] = QuranComRecitationDto(
        id: d.id,
        name: d.name,
        style: d.style,
        path: d.path,
        translatedName: d.translatedName,
        nameByLocale: namesByReciter[id] ?? const {},
      );
    });
    return merged;
  }

  /// Audio URLs для всех аятов конкретной суры для конкретного ректора.
  ///
  /// Возвращает `List<{verseKey, url}>` где `verseKey = "1:1"` (chapter:verse).
  /// URL — relative (e.g. "Alafasy/mp3/001001.mp3"); prepend
  /// [audioCdnBase] для полного URL.
  Future<List<QuranComAudioFile>> fetchChapterAudio({
    required int recitationId,
    required int chapterId,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_basePrimary/recitations/$recitationId/by_chapter/$chapterId',
    );
    final list = (r.data?['audio_files'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(QuranComAudioFile.fromJson)
        .toList(growable: false);
  }

  /// Метаданные суры: name_simple, name_arabic, verses_count,
  /// bismillah_pre, translated_name.
  Future<QuranComChapterDto?> fetchChapter({
    required int chapterId,
    String language = 'ru',
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_basePrimary/chapters/$chapterId',
      queryParameters: {'language': language},
    );
    final ch = r.data?['chapter'] as Map<String, dynamic>?;
    return ch == null ? null : QuranComChapterDto.fromJson(ch);
  }

  /// Uthmani-текст аята (или списка аятов через `verse_key=1:1,1:2,...`).
  Future<List<QuranComVerseDto>> fetchVerses(List<String> verseKeys) async {
    if (verseKeys.isEmpty) return const [];
    final r = await _dio.get<Map<String, dynamic>>(
      '$_basePrimary/quran/verses/uthmani',
      queryParameters: {'verse_key': verseKeys.join(',')},
    );
    final list = (r.data?['verses'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(QuranComVerseDto.fromJson)
        .toList(growable: false);
  }

  // ─── Tafsir (Sprint 2.2) ─────────────────────────────────────────

  /// Список доступных тафсиров с переводами имён.
  /// `language` — UI-язык для translated_name (если API поддерживает).
  /// Endpoint: `/resources/tafsirs?language=ru`.
  Future<List<QuranComTafsirSourceDto>> fetchTafsirs({
    String language = 'ru',
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_basePrimary/resources/tafsirs',
      queryParameters: {'language': language},
    );
    final list = (r.data?['tafsirs'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(QuranComTafsirSourceDto.fromJson)
        .toList(growable: false);
  }

  /// Тафсир для одного аята (Sprint 2 — primary use case в UI).
  /// Endpoint: `/tafsirs/{tafsirId}/by_ayah/{verseKey}`.
  /// Возвращает [QuranComTafsirVerseDto] с HTML-разметкой в `text`.
  /// null если 404 (например, аят не покрыт этим тафсиром).
  ///
  /// **ВАЖНО**: response key — `tafsir` (singular), не `tafsirs`.
  /// Подтверждено curl'ом 2026-07-17: `/tafsirs/14/by_ayah/1:1` →
  /// `{"tafsir": {...}}`. Endpoints `/by_chapter` и `/resources/tafsirs`
  /// возвращают `tafsirs` (plural). Bug в Sprint 2.5: код читал
  /// `['tafsirs']` и получал `null` всегда.
  Future<QuranComTafsirVerseDto?> fetchTafsirByAyah({
    required int tafsirId,
    required String verseKey,
  }) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '$_basePrimary/tafsirs/$tafsirId/by_ayah/$verseKey',
      );
      final obj = r.data?['tafsir'] as Map<String, dynamic>?;
      if (obj == null) return null;
      return QuranComTafsirVerseDto.fromJson(obj);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Тафсир для целой суры (paginated).
  /// Endpoint: `/tafsirs/{tafsirId}/by_chapter/{chapterId}`.
  /// Возвращает список аятов. `pagination` показывает next_page.
  /// В Sprint 2 UI не используется (per-ayah fetch быстрее);
  /// оставлено для batch-префетча (Phase 2 — кэш на месяц).
  Future<List<QuranComTafsirVerseDto>> fetchTafsirByChapter({
    required int tafsirId,
    required int chapterId,
    int page = 1,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_basePrimary/tafsirs/$tafsirId/by_chapter/$chapterId',
      queryParameters: {'page': page},
    );
    final list = (r.data?['tafsirs'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(QuranComTafsirVerseDto.fromJson)
        .toList(growable: false);
  }

  /// Round 9: список всех 114 сур с метаданными.
  /// Используется при cold install (lazy) или при wipe DB.
  Future<List<QuranComSurahDto>> fetchChapters() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_basePrimary/chapters',
      queryParameters: {'language': 'en'},
    );
    final chapters = (r.data?['chapters'] as List?) ?? const [];
    return chapters
        .cast<Map<String, dynamic>>()
        .map(QuranComSurahDto.fromJson)
        .toList(growable: false);
  }

  /// Round 9: metadata аятов суры — page/juz/hizb для каждого аята.
  /// Используется для ленивой подгрузки метаданных аятов в БД.
  ///
  /// Возвращает `Map<verseKey, {page, juz, hizb}>`.
  Future<Map<String, Map<String, int>>> fetchAyahMetadataByChapter({
    required int chapterNumber,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_basePrimary/verses/by_chapter/$chapterNumber',
    );
    final verses = (r.data?['verses'] as List?) ?? const [];
    final result = <String, Map<String, int>>{};
    for (final v in verses.cast<Map<String, dynamic>>()) {
      final key = v['verse_key'] as String?;
      if (key == null) continue;
      result[key] = {
        'page': (v['page_number'] as num?)?.toInt() ?? 0,
        'juz': (v['juz_number'] as num?)?.toInt() ?? 0,
        'hizb': (v['hizb_number'] as num?)?.toInt() ?? 0,
      };
    }
    return result;
  }

  /// Round 9: bulk fetch аятов одной суры (Arabic + simple text параллельно).
  /// Делает 2 HTTP запроса параллельно (uthmani + uithmani_simple),
  /// затем мержит результаты по verse_key. Возвращает Map<verseKey,
  /// QuranComAyahDto> (verseKey = "1:1").
  ///
  /// Используется для lazy load при cold install и при wipe DB.
  Future<Map<String, QuranComAyahDto>> fetchVersesByChapter({
    required int chapterNumber,
  }) async {
    final uthmaniF = _dio.get<Map<String, dynamic>>(
      '$_basePrimary/quran/verses/uthmani',
      queryParameters: {'chapter_number': chapterNumber},
    );
    final simpleF = _dio.get<Map<String, dynamic>>(
      '$_basePrimary/quran/verses/uthmani_simple',
      queryParameters: {'chapter_number': chapterNumber},
    );
    final results = await Future.wait([uthmaniF, simpleF]);

    final uthmaniVerses = (results[0].data?['verses'] as List?) ?? const [];
    final simpleVerses = (results[1].data?['verses'] as List?) ?? const [];

    final simpleMap = <String, String>{};
    for (final v in simpleVerses.cast<Map<String, dynamic>>()) {
      final key = v['verse_key'] as String?;
      final text = v['text_uthmani_simple'] as String?;
      if (key != null && text != null) simpleMap[key] = text;
    }

    final result = <String, QuranComAyahDto>{};
    for (final v in uthmaniVerses.cast<Map<String, dynamic>>()) {
      final key = v['verse_key'] as String?;
      if (key == null) continue;
      result[key] = QuranComAyahDto.fromJson(
        v,
        textUthmani: v['text_uthmani'] as String?,
        textUthmaniSimple: simpleMap[key],
      );
    }
    return result;
  }
}

/// Один ректор c Quran.com (формат API v4).
class QuranComRecitationDto {
  QuranComRecitationDto({
    required this.id,
    required this.name,
    this.style,
    this.path,
    this.translatedName = '',
    this.nameByLocale = const {},
  });

  factory QuranComRecitationDto.fromJson(Map<String, dynamic> j) {
    final tn = j['translated_name'] as Map<String, dynamic>?;
    return QuranComRecitationDto(
      id: (j['id'] as num).toInt(),
      name: (j['reciter_name'] as String?) ?? '',
      style: j['style'] as String?,
      // `path` — sub-folder на CDN вида "Alafasy", "Husary" и т.д.
      // Используется в [audioFileUrl]:
      //   https://verses.quran.com/{path}/mp3/{sssnnn}.mp3
      path: j['path'] as String?,
      translatedName: tn?['name'] as String? ?? '',
    );
  }

  /// Canonical id Quran.com (используется в /recitations/{id}/by_chapter/N).
  final int id;
  final String name;

  /// 'Murattal' / 'Mujawwad' / 'Muallim' / 'Khalaf' — может быть null
  /// (для рива'ат без явного стиля).
  final String? style;

  /// Sub-folder на CDN (см. комментарий в конструкторе).
  final String? path;

  /// Переведённое имя на запрошенном языке (e.g. 'Махмуд Халиль Аль-Хусари').
  final String translatedName;

  /// Заполняется в [QuranComApi.fetchRecitationsMultiLocale].
  final Map<String, String> nameByLocale;
}

/// Один аудио-файл (ayah) с CDN-путём.
class QuranComAudioFile {
  QuranComAudioFile({required this.verseKey, required this.relativePath});

  factory QuranComAudioFile.fromJson(Map<String, dynamic> j) {
    return QuranComAudioFile(
      verseKey: j['verse_key'] as String,
      relativePath: j['url'] as String,
    );
  }

  /// "1:1" (chapter:verse) — для индексации в БД.
  final String verseKey;

  /// "Alafasy/mp3/001001.mp3" — relative path на CDN.
  final String relativePath;

  /// Собираем полный URL. Использует [QuranComApi._audioCdn] — общий
  /// CDN-база для всех recitation'ов.
  String get fullUrl => '${QuranComApi._audioCdn}/$relativePath';
}

/// Метаданные суры.
class QuranComChapterDto {
  QuranComChapterDto({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
    required this.bismillahPre,
    required this.translatedName,
  });

  factory QuranComChapterDto.fromJson(Map<String, dynamic> j) {
    final tn = j['translated_name'] as Map<String, dynamic>?;
    return QuranComChapterDto(
      id: (j['id'] as num).toInt(),
      nameSimple: (j['name_simple'] as String?) ?? '',
      nameArabic: (j['name_arabic'] as String?) ?? '',
      versesCount: (j['verses_count'] as num?)?.toInt() ?? 0,
      bismillahPre: (j['bismillah_pre'] as bool?) ?? false,
      translatedName: tn?['name'] as String? ?? '',
    );
  }

  final int id;
  final String nameSimple;
  final String nameArabic;
  final int versesCount;
  final bool bismillahPre;
  final String translatedName;
}

/// Текст аята (Uthmani).
class QuranComVerseDto {
  QuranComVerseDto({required this.id, required this.verseKey, required this.textUthmani});

  factory QuranComVerseDto.fromJson(Map<String, dynamic> j) {
    return QuranComVerseDto(
      id: (j['id'] as num).toInt(),
      verseKey: j['verse_key'] as String,
      textUthmani: (j['text_uthmani'] as String?) ?? '',
    );
  }

  final int id;
  final String verseKey;
  final String textUthmani;
}

/// === Tafsir (Sprint 2.2) ============================================
//
// Структура ответов `/tafsirs/{id}/by_ayah/{verseKey}` и
// `/tafsirs/{id}/by_chapter/{chapter}` идентична. Внутри — массив
// аятов с полем `text` (HTML с inline-тегами, например <span class="blue">).
// `verse_key` — обязательно. `resource_id` — id тафсира (= id из
// `/resources/tafsirs`). `language_id` — внутренний id языка Quran.com.

/// Один тафсир (элемент списка `/resources/tafsirs`).
class QuranComTafsirSourceDto {
  QuranComTafsirSourceDto({
    required this.id,
    required this.name,
    required this.authorName,
    required this.slug,
    required this.languageName,
    required this.translatedName,
  });

  factory QuranComTafsirSourceDto.fromJson(Map<String, dynamic> j) {
    final tn = j['translated_name'] as Map<String, dynamic>?;
    return QuranComTafsirSourceDto(
      id: (j['id'] as num).toInt(),
      name: (j['name'] as String?) ?? '',
      authorName: (j['author_name'] as String?) ?? '',
      slug: (j['slug'] as String?) ?? '',
      languageName: (j['language_name'] as String?) ?? '',
      translatedName: tn?['name'] as String? ?? '',
    );
  }

  /// Quran.com tafsir id. Используется в `/tafsirs/{id}/by_ayah/...`.
  final int id;
  final String name;
  final String authorName;

  /// Например: "ar-tafsir-ibn-kathir", "ru-tafseer-al-saddi".
  final String slug;

  /// Язык оригинала тафсира ("arabic", "english", "russian", "urdu"...).
  final String languageName;

  /// Переведённое название (если API поддерживает `translated_name`).
  final String translatedName;
}

/// Один аят с тафсиром (из `/by_ayah` и `/by_chapter`).
class QuranComTafsirVerseDto {
  QuranComTafsirVerseDto({
    required this.resourceId,
    required this.verseKey,
    required this.languageId,
    required this.text,
    this.id,
  });

  factory QuranComTafsirVerseDto.fromJson(Map<String, dynamic> j) {
    // **Round 6 bugfix (2026-07-22)**: response `/by_ayah/{key}` НЕ
    // содержит поле `id` на верхнем уровне (только `resource_id`,
    // `language_id`, `text`, `verses: { "1:1": {"id": 1} }` — id
    // каждого verse лежит ВНУТРИ verses map). Раньше код делал
    // `(j['id'] as num).toInt()` → падал с
    // `type 'Null' is not a subtype of type 'num'` на каждом
    // /by_ayah запросе. Делаем id nullable + null-aware cast.
    //
    // Сейчас `id` не используется в UI (только `text`), но
    // оставляем поле nullable на будущее — для by_chapter endpoint,
    // где response содержит список verse'ов с их `id`.
    return QuranComTafsirVerseDto(
      id: (j['id'] as num?)?.toInt(),
      resourceId: (j['resource_id'] as num).toInt(),
      // `verse_key` тоже может отсутствовать в by_ayah response (там
      // есть только `verses` map). Делаем nullable.
      verseKey: j['verse_key'] as String? ?? '',
      languageId: (j['language_id'] as num?)?.toInt() ?? 0,
      text: (j['text'] as String?) ?? '',
    );
  }

  /// `quran_com_reciters.id`-like: локальный id записи (auto-increment
  /// в БД), не путать с `resource_id` (= id тафсира из API).
  /// Nullable — `/by_ayah/{key}` response НЕ содержит этого поля
  /// (только `/by_chapter/{chapter}` возвращает список verse'ов
  /// с `id` каждого).
  final int? id;
  final int resourceId;
  final String verseKey;
  final int languageId;

  /// HTML-разметка с inline-тегами (<p>, <span class="...">). Для
  /// рендеринга в Flutter: парсить через `flutter_html` или strip
  /// tags простым regex `r'<[^>]+>'` (Sprint 2.5 — minimal rendering).
  final String text;
}

/// Round 9 (2026-07-25): DTOs для миграции с alquran.cloud на
/// Quran.com — Arabic text + chapters metadata.

class QuranComSurahDto {
  QuranComSurahDto({
    required this.id,
    required this.revelationPlace,
    required this.revelationOrder,
    required this.bismillahPre,
    required this.nameSimple,
    required this.nameComplex,
    required this.nameArabic,
    required this.versesCount,
    required this.pages,
  });

  final int id;
  final String revelationPlace;
  final int revelationOrder;
  final bool bismillahPre;
  final String nameSimple;
  final String nameComplex;
  final String nameArabic;
  final int versesCount;
  final List<int> pages;

  factory QuranComSurahDto.fromJson(Map<String, dynamic> j) {
    return QuranComSurahDto(
      id: (j['id'] as num).toInt(),
      revelationPlace: (j['revelation_place'] as String?) ?? 'makkah',
      revelationOrder: (j['revelation_order'] as num).toInt(),
      bismillahPre: (j['bismillah_pre'] as bool?) ?? false,
      nameSimple: (j['name_simple'] as String?) ?? '',
      nameComplex: (j['name_complex'] as String?) ?? '',
      nameArabic: (j['name_arabic'] as String?) ?? '',
      versesCount: (j['verses_count'] as num).toInt(),
      pages: (j['pages'] as List?)?.cast<int>() ?? [0, 0],
    );
  }
}

class QuranComAyahDto {
  QuranComAyahDto({
    required this.id,
    required this.verseKey,
    required this.textUthmani,
    required this.textUthmaniSimple,
  });

  final int id;
  final String verseKey;
  final String textUthmani;
  final String textUthmaniSimple;

  factory QuranComAyahDto.fromJson(
    Map<String, dynamic> j, {
    String? textUthmani,
    String? textUthmaniSimple,
  }) {
    return QuranComAyahDto(
      id: (j['id'] as num).toInt(),
      verseKey: (j['verse_key'] as String?) ?? '',
      textUthmani: textUthmani ?? (j['text_uthmani'] as String?) ?? '',
      textUthmaniSimple: textUthmaniSimple ??
          (j['text_uthmani_simple'] as String?) ??
          (j['text_imlaei'] as String?) ??
          '',
    );
  }
}

