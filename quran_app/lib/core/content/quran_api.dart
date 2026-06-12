import 'dart:convert';

import 'package:http/http.dart' as http;

import '../networking/api_client.dart';

/// API Quran (alquran.cloud v1) — публичное API с возможностью
/// получать текст, переводы и тафсиры.
class QuranApi {
  QuranApi(this._client);

  final ApiClient _client;
  static const _base = 'https://api.alquran.cloud/v1';

  /// Базовые URL'ы для content-update endpoint'а (отдельный от
  /// alquran.cloud). Override через
  /// `--dart-define=QURAN_MANIFEST_BASE=http://localhost:8765/v1`
  /// — вставляется **первым** в список. Используется
  /// `String.fromEnvironment` (compile-time const) + manual
  /// list-concat, чтобы override был первым в порядке fallback.
  ///
  /// Имя env var **без пробелов** (`QURAN_MANIFEST_BASE`) — иначе
  /// PowerShell и dart-define не парсят.
  static const _manifestBaseOverride = String.fromEnvironment(
    'QURAN_MANIFEST_BASE',
    defaultValue: '',
  );

  /// Список endpoint'ов для content-manifest. Первый — primary
  /// (override через `--dart-define=QURAN_MANIFEST_BASE` или
  /// встроенный `https://content.quran-app.com/v1`). Остальные —
  /// fallback'и (см. [quranManifestFallbackEndpoints]).
  static final List<String> _manifestBaseEndpoints = [
    if (_manifestBaseOverride.isNotEmpty) _manifestBaseOverride,
    ...quranManifestFallbackEndpoints,
  ];

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
    for (final base in _manifestBaseEndpoints) {
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
    for (final base in _manifestBaseEndpoints) {
      try {
        final url = '$base/payloads/quran-$contentVersion.json';
        // Используем `package:http` напрямую — НЕ `Dio`.
        //
        // Почему: `Dio` 5.x на Android emulator для больших body
        // (5+ MB) надёжно **не работает**:
        //   - `Dio.raw.get<String>` — OutOfMemoryError при конвертации
        //     UTF-8 → Java String через MethodChannel
        //   - `Dio.raw.get<List<int>>` с `ResponseType.bytes` —
        //     response зависает на `close()` без отправки запроса
        //   - `Dio.get<ResponseBody>` с `ResponseType.stream` —
        //     молча падает без видимой ошибки (dynamic cast fail)
        //
        // `package:http` идёт через `dart:io HttpClient` напрямую
        // (без MethodChannel) — работает на Android emulator.
        final uri = Uri.parse(url);
        // `package:http` (как и Dio) не отдаёт stream напрямую в
        // `bodyBytes` — он буферизует всё в `Uint8List`. Для 5 MB
        // это ОК (RAM должно хватить; на старых устройствах
        // можно переписать на streamed `http.Client.send`).
        final response = await http
            .get(
              uri,
              headers: const {'Accept': 'application/json'},
            )
            .timeout(const Duration(minutes: 5));
        if (response.statusCode != 200) {
          continue;
        }
        return utf8.decode(response.bodyBytes, allowMalformed: true);
      } catch (e) {
        // Last-resort log: не пробрасываем — caller (ContentUpdateService)
        // увидит NetworkException и запишет в state.
        // ignore: avoid_print
        print('fetchPayload($base) failed: $e');
        continue;
      }
    }
    throw NetworkException('All payload endpoints failed');
  }
}

/// Fallback endpoint'ы для content manifest'а. Primary
/// по умолчанию — `https://content.quran-app.com/v1`; в проде
/// убедитесь, что домен резолвится. Backup — GitHub Pages
/// (статический manifest.json, можно деплоить через
/// `gh-pages` branch). Первый endpoint'override через
/// `--dart-define=QURAN_MANIFEST_BASE=...` (см.
/// `QuranApi._manifestBaseEndpoints`).
const quranManifestFallbackEndpoints = <String>[
  // Primary (default)
  'https://content.quran-app.com/v1',
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
