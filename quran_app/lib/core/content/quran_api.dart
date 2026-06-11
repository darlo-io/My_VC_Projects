import '../networking/api_client.dart';

/// API Quran (alquran.cloud v1) — публичное API с возможностью
/// получать текст, переводы и тафсиры.
class QuranApi {
  QuranApi(this._client);

  final ApiClient _client;
  static const _base = 'https://api.alquran.cloud/v1';

  /// Базовый URL для content-update endpoint'а (отдельный от
  /// alquran.cloud). На MVP v0.1 — фиктивный; в проде заменяется
  /// на `https://content.quran-app.com/v1/`.
  ///
  /// Поддерживает fallback через `quranManifestFallbackEndpoints`
  /// (см. [quranManifestFallbackEndpoints]) — если primary
  /// endpoint возвращает 404/5xx, пробуем backup'ы.
  static const _manifestBase =
      String.fromEnvironment('QURAN_MANIFEST_BASE',
          defaultValue: 'https://content.quran-app.com/v1');

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

  /// Скачать подписанный content manifest. Перебирает
  /// [quranManifestFallbackEndpoints] пока не получит
  /// `2xx` с непустым телом. Возвращает `null`, если все
  /// endpoint'ы провалились (для graceful offline mode).
  ///
  /// Формат manifest'а (см. ARCHITECTURE §15):
  /// ```json
  /// {
  ///   "content_version": "1.1.0",
  ///   "min_app_version": "1.0.0",
  ///   "payload_sha256": "<hex>",
  ///   "signature": "<base64 ed25519>",
  ///   "translations": [...],
  ///   "editions": ["quran-uthmani"]
  /// }
  /// ```
  ///
  /// Бросает [NetworkException] при отсутствии сети (через
  /// [ApiClient.getJson]). Caller (ContentUpdateService) ловит
  /// и интерпретирует как `no update available`.
  Future<Map<String, dynamic>?> fetchContentManifest() async {
    for (final base in quranManifestFallbackEndpoints) {
      try {
        final url = '$base/manifest.json';
        final data = await _client.getJson(url);
        if (data.isEmpty) continue;
        return data;
      } catch (_) {
        // Fallback к следующему endpoint'у
        continue;
      }
    }
    return null;
  }

  /// Скачать payload (`quran_full.json`) — бандл со всеми сурами
  /// + переводами. Используется, когда manifest указывает
  /// `contentVersion > appliedVersion`.
  ///
  /// [expectedSha256] — SHA256, который мы только что проверили
  /// по manifest'у. Если хеш скачанного файла не совпадёт —
  /// throw [NetworkException] (caller откатит manifest).
  Future<String> fetchPayload({
    required String contentVersion,
    required String expectedSha256,
  }) async {
    for (final base in quranManifestFallbackEndpoints) {
      try {
        final url = '$base/payloads/quran-$contentVersion.json';
        // Используем `Dio` напрямую (raw GET) — нам нужен
        // полный body как String для SHA256, а не JSON-парсинг.
        final resp = await _client.raw.get<String>(url);
        if (resp.statusCode == 200 && resp.data != null) {
          return resp.data!;
        }
      } catch (_) {
        continue;
      }
    }
    throw NetworkException('All payload endpoints failed');
  }
}

/// Fallback endpoint'ы для content manifest'а. Primary
/// закомментирован (фиктивный URL); в проде раскомментировать
/// `https://content.quran-app.com` или указать через
/// `--dart-define=QURAN_MANIFEST_BASE=https://...`.
const quranManifestFallbackEndpoints = <String>[
  // Primary
  // 'https://content.quran-app.com/v1',
  // Backup: GitHub Pages
  'https://quran-app.github.io/content/v1',
];

/// Тип сетевого исключения (используется для graceful
/// offline-mode). Сейчас — простой type-tag для [ApiClient].
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}
