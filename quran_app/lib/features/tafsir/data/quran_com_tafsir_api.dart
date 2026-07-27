// Quran.com Tafsir API v4 client (Sprint 2).
//
// Выделен в отдельный класс из [QuranComApi], чтобы UI-слой мог
// инжектить только tafsir-часть, не таская за собой audio/verse
// endpoints. Реализация переиспользует DTO `QuranComTafsirSourceDto`
// и `QuranComTafsirVerseDto` из [QuranComApi] — формат ответов
// идентичен (см. комментарии к этим классам в `quran_com_api.dart`).
//
// Endpoints (verified 2026-07-13):
//   - GET /api/v4/resources/tafsirs?language=ru
//   - GET /api/v4/tafsirs/{id}/by_ayah/{verseKey}  (verseKey = "N:V")

import 'package:dio/dio.dart';

import '../../audio/data/quran_com_api.dart';

class QuranComTafsirApi {
  QuranComTafsirApi({Dio? dio})
      : _dio = dio ??
            (Dio()
              // 2026-07-17: на сетях с медленным uplink (curl test
              // показал 24KB за 10s на c1316607) 12s receive timeout
              // отваливался до конца ответа. Tafsir text — 30-50KB,
              // загрузка занимает 15-25s. Увеличил до 60s + 20s
              // connect (DNS на плохих сетях).
              ..options.connectTimeout = const Duration(seconds: 20)
              ..options.receiveTimeout = const Duration(seconds: 60)
              ..options.headers = const {
                'Accept': 'application/json',
                'User-Agent': 'quran_app/1.0.0',
              });

  final Dio _dio;

  static const _basePrimary = 'https://api.quran.com/api/v4';

  /// Список источников тафсиров с переводами имён.
  /// `language` — UI-язык для `translated_name.name` ('ru', 'en', 'ar').
  Future<List<QuranComTafsirSourceDto>> fetchSources({
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

  /// Тафсир для одного аята.
  /// `verseKey` = "N:V" (surah:ayah, 1-indexed). Возвращает null
  /// при 404 (аят не покрыт этим тафсиром).
  ///
  /// **ВАЖНО**: response key — `tafsir` (singular), не `tafsirs`.
  /// Endpoints `/by_chapter` и `/resources/tafsirs` — plural.
  /// (Bug в Sprint 2.5: читали `['tafsirs']` и получали null.)
  Future<QuranComTafsirVerseDto?> fetchByAyah({
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
}
