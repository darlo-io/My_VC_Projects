import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// MP3Quran.net API v3 client.
///
/// Документация: <https://www.mp3quran.net/ru/api>.
///
/// Назначение — разово подтянуть список чтецов/мoshaf'ов и
/// кешировать их в локальную БД (см. [Reciters.mp3quranId]). На
/// каждый запуск приложения API не дёргаем — клиент вызывается
/// из [Mp3QuranRepository.syncFromApi] либо по запросу
/// пользователя, либо при первом запуске.
///
/// Endpoints, которые используем:
///   * `GET /api/v3/reciters?language=ar|eng|...` — список чтецов
///   * `GET /api/v3/ayat_timing/reads` — список чтецов с timing'ом
///   * `GET /api/v3/ayat_timing?surah=N&read=M` — тайминги аятов для
///     подсветки слов во время проигрывания (Phase 3)
///
/// Rate-limit policy не задокументирована у mp3quran.net явно, держим
/// ≤10 req/s (по аналогии с AlQuran Cloud / Islamic Network).
class Mp3QuranApi {
  Mp3QuranApi({Dio? dio})
      : _dio = dio ??
            (Dio()
              ..options.connectTimeout = const Duration(seconds: 8)
              ..options.receiveTimeout = const Duration(seconds: 12)
              ..options.headers = const {'Accept': 'application/json'});

  final Dio _dio;

  // Используем `www.` — `https://mp3quran.net/api/...` возвращает 301
  // на `https://www.mp3quran.net/...`, и `dio` по умолчанию **не**
  // следует за redirect'ами. Без `www.` клиент падает в
  // `FormatException` при попытке распарсить HTML-301 как JSON.
  static const _base = 'https://www.mp3quran.net/api/v3';

  /// Возвращает список ректоров для указанного языка.
  /// `language` ∈ {'ar','eng','fr','ru','de','es','tr', ...}.
  Future<List<Mp3QuranReciterDto>> fetchReciters({String language = 'ar'}) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_base/reciters',
      queryParameters: {'language': language},
    );
    final list = (r.data?['reciters'] as List?) ?? const [];
    return list
        .map((j) => Mp3QuranReciterDto.fromJson(j as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Multi-locale fetch: дёргает `/reciters?language=<l>` для каждого
  /// языка из [languages], объединяет результаты в карту по
  /// `reciter.id`. Используется при [RecitersSyncService.syncFromApi]
  /// чтобы одной операцией сохранить nameAr/nameEn/nameRu в БД.
  ///
  /// Параллельные запросы (через [Future.wait]) — три реквеста по
  /// ~100 KB JSON отрабатывают за ~2-3 секунды при нормальной сети.
  Future<Map<int, Mp3QuranReciterDto>> fetchRecitersMultiLocale({
    List<String> languages = const ['ar', 'eng', 'ru'],
  }) async {
    final results = await Future.wait(
      languages.map((lang) async {
        try {
          final dtos = await fetchReciters(language: lang);
          return MapEntry(lang, dtos);
        } catch (e) {
          // Частичный успех: если, скажем, русский недоступен, не
          // роняем весь sync — запишем имеющиеся локали в БД.
          developer.log(
            'mp3quran fetchReciters(language=$lang) failed: $e',
            name: 'mp3quran',
          );
          return MapEntry(lang, <Mp3QuranReciterDto>[]);
        }
      }),
    );

    // Сливаем по id. Берём последний успешный DTO как «canonical»
    // (с неё берём mp3quranId/Server/Moshaf), и параллельно собираем
    // `nameAr/nameEn/nameRu` в отдельную мапу.
    final canonicalById = <int, Mp3QuranReciterDto>{};
    final namesByReciter = <int, Map<String, String>>{};
    for (final entry in results) {
      final lang = entry.key;
      for (final d in entry.value) {
        canonicalById[d.id] = d;
        final names = namesByReciter.putIfAbsent(d.id, () => {});
        if (d.name.isNotEmpty) names[lang] = d.name;
      }
    }
    final merged = <int, Mp3QuranReciterDto>{};
    canonicalById.forEach((id, d) {
      merged[id] = Mp3QuranReciterDto(
        id: d.id,
        name: d.name,
        letter: d.letter,
        date: d.date,
        moshafs: d.moshafs,
        nameByLocale: namesByReciter[id] ?? const {},
      );
    });
    return merged;
  }

  /// Список чтецов с таймингами аятов (для word-level highlighting).
  Future<List<Mp3QuranTimedReadDto>> fetchTimedReads() async {
    final r = await _dio.get<List<dynamic>>('$_base/ayat_timing/reads');
    return (r.data ?? const [])
        .map((j) => Mp3QuranTimedReadDto.fromJson(j as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Тайминги аятов для конкретной суры и чтеца.
  /// `readId` — id из [Mp3QuranTimedReadDto].
  Future<List<Mp3QuranAyahTiming>> fetchAyahTiming({
    required int surah,
    required int readId,
  }) async {
    final r = await _dio.get<List<dynamic>>(
      '$_base/ayat_timing',
      queryParameters: {'surah': surah, 'read': readId},
    );
    return (r.data ?? const [])
        .map((j) => Mp3QuranAyahTiming.fromJson(j as Map<String, dynamic>))
        .toList(growable: false);
  }
}

/// Один ректор c MP3Quran.net (формат API v3).
///
/// `moshaf` содержит несколько «мусхафов» (вариантов чтения) —
/// для одного ректора это могут быть разные рива'аты (Hafs/Warsh/Qalon)
/// или стили (мураддаль/му'аллим/му'джаввад). На старте
/// [Mp3QuranRepository] выбирает первый Hafs-мусхаф.
class Mp3QuranReciterDto {
  Mp3QuranReciterDto({
    required this.id,
    required this.name,
    this.letter,
    this.date,
    required this.moshafs,
    this.nameByLocale = const {},
  });

  factory Mp3QuranReciterDto.fromJson(Map<String, dynamic> j) {
    final moshafs = (j['moshaf'] as List?)
            ?.map((m) => Mp3QuranMoshafDto.fromJson(m as Map<String, dynamic>))
            .toList(growable: false) ??
        const [];
    final langCode = (j['language'] as String?) ??
        ((j['name'] is String) ? _guessLangFromName(j['name'] as String) : 'ar');
    return Mp3QuranReciterDto(
      id: (j['id'] as num).toInt(),
      name: (j['name'] as String?) ?? '',
      letter: j['letter'] as String?,
      date: j['date'] as String?,
      moshafs: moshafs,
      nameByLocale: {langCode: (j['name'] as String?) ?? ''},
    );
  }

  final int id;
  final String name;
  final String? letter;
  final String? date;
  final List<Mp3QuranMoshafDto> moshafs;

  /// Карта `languageCode → name` для объединённого результата из
  /// [Mp3QuranApi.fetchRecitersMultiLocale]. Заполняется при merge.
  final Map<String, String> nameByLocale;

  /// Возвращает первый мусхаф, у которого имя содержит [substring]
  /// (case-insensitive), или `null` если такого нет.
  Mp3QuranMoshafDto? firstMoshafWhere(bool Function(Mp3QuranMoshafDto) test) {
    for (final m in moshafs) {
      if (test(m)) return m;
    }
    return null;
  }

  static String _guessLangFromName(String s) {
    // Арабский диапазон Unicode: U+0600..U+06FF.
    if (s.runes.any((r) => r >= 0x0600 && r <= 0x06FF)) return 'ar';
    // Кириллица (русский): U+0400..U+04FF.
    if (s.runes.any((r) => r >= 0x0400 && r <= 0x04FF)) return 'ru';
    return 'eng';
  }
}

class Mp3QuranMoshafDto {
  Mp3QuranMoshafDto({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  factory Mp3QuranMoshafDto.fromJson(Map<String, dynamic> j) {
    return Mp3QuranMoshafDto(
      id: (j['id'] as num).toInt(),
      name: (j['name'] as String?) ?? '',
      server: (j['server'] as String?) ?? '',
      surahTotal: (j['surah_total'] as num?)?.toInt() ?? 114,
      moshafType: (j['moshaf_type'] as num?)?.toInt() ?? 0,
      surahList: _parseSurahList(j['surah_list'] as String?),
    );
  }

  final int id;
  final String name;
  /// Базовый URL вида `https://server8.mp3quran.net/afs/`.
  /// Конкретный файл сур — `${server}${NNN}.mp3` (1-based, 3-digit pad).
  final String server;
  final int surahTotal;
  final int moshafType;
  /// Список id сур, для которых есть запись. `null` = все 114.
  final List<int>? surahList;

  /// True если у этого мусхафа есть запись для данной суры
  /// (1..114). Учитывает [surahList] если он задан.
  bool hasSurah(int surahNumber) {
    if (surahList == null) return true; // сервер не ограничил
    return surahList!.contains(surahNumber);
  }

  static List<int>? _parseSurahList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final out = <int>[];
    for (final part in raw.split(',')) {
      final t = part.trim();
      if (t.isEmpty) continue;
      final n = int.tryParse(t);
      if (n != null) out.add(n);
    }
    return out.isEmpty ? null : out;
  }
}

/// Ректор с таймингами аятов (из `/ayat_timing/reads`).
class Mp3QuranTimedReadDto {
  Mp3QuranTimedReadDto({
    required this.id,
    required this.name,
    required this.rewaya,
    required this.folderUrl,
    required this.soarCount,
  });

  factory Mp3QuranTimedReadDto.fromJson(Map<String, dynamic> j) {
    return Mp3QuranTimedReadDto(
      id: (j['id'] as num).toInt(),
      name: (j['name'] as String?) ?? '',
      rewaya: (j['rewaya'] as String?) ?? '',
      folderUrl: (j['folder_url'] as String?) ?? '',
      soarCount: (j['soar_count'] as num?)?.toInt() ?? 114,
    );
  }

  final int id;
  final String name;
  final String rewaya;
  /// Базовый URL для аудио-сур (per-surah файлы).
  final String folderUrl;
  final int soarCount;
}

/// Один тайминг аята (из `/ayat_timing`).
class Mp3QuranAyahTiming {
  Mp3QuranAyahTiming({
    required this.ayah,
    required this.startTimeMs,
    required this.endTimeMs,
    this.polygon,
    this.x,
    this.y,
    this.page,
  });

  factory Mp3QuranAyahTiming.fromJson(Map<String, dynamic> j) {
    return Mp3QuranAyahTiming(
      ayah: (j['ayah'] as num?)?.toInt() ?? 0,
      startTimeMs: (j['start_time'] as num?)?.toInt() ?? 0,
      endTimeMs: (j['end_time'] as num?)?.toInt() ?? 0,
      polygon: j['polygon'] as String?,
      x: j['x'] as String?,
      y: j['y'] as String?,
      page: j['page'] as String?,
    );
  }

  final int ayah;
  final int startTimeMs;
  final int endTimeMs;
  final String? polygon;
  final String? x;
  final String? y;
  final String? page;
}