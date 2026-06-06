import '../networking/api_client.dart';

/// API Quran (alquran.cloud v1) — публичное API с возможностью
/// получать текст, переводы и тафсиры.
class QuranApi {
  QuranApi(this._client);

  final ApiClient _client;
  static const _base = 'https://api.alquran.cloud/v1';

  /// Загрузить список сур (114 сур с метаданными).
  Future<List<Map<String, dynamic>>> fetchSurahs() async {
    final data = await _client.getJson('$_base/surah');
    final list = (data['surahs'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Загрузить полную суру в нужном издании (edition).
  /// Editions:
  ///   - `quran-uthmani` — текст Усмани
  ///   - `ar.alafasy` — арабский с аудио
  ///   - `en.sahih` — английский Sahih International
  ///   - `ru.kuliev` — русский Кулиев
  ///   - `ar.muyassar` — тафсир на арабском
  Future<Map<String, dynamic>> fetchSurahEdition({
    required int surahNumber,
    required String edition,
  }) async {
    return _client.getJson('$_base/surah/$surahNumber/$edition');
  }
}
