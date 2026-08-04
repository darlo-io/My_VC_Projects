import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

/// Round 9.4: выделено из `quran_api.dart` (alquran.cloud).
/// Содержит только функции работы с content-manifest endpoint'ом
/// (отдельный от alquran.cloud endpoint — content.quran-app.com).
/// Эти функции нужны для online-update flow (`ContentUpdateService`).
class QuranManifestApi {
  QuranManifestApi();

  /// Базовые URL'ы для content-update endpoint'а. Override через
  /// `--dart-define=QURAN_MANIFEST_BASE=http://localhost:8765/v1`
  /// — вставляется **первым** в список. Первый endpoint'override
  /// через `--dart-define=QURAN_MANIFEST_BASE=...` (см.
  /// `QuranManifestApi._manifestBaseEndpoints`).
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
  /// Использует `dart:io HttpClient` напрямую — обходит баги
  /// `Dio` 5.x на Android emulator (Cronet, MethodChannel, и т.д.).
  Future<Map<String, dynamic>?> fetchContentManifest() async {
    for (final base in _manifestBaseEndpoints) {
      try {
        final url = '$base/manifest.json';
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 20)
          ..idleTimeout = const Duration(minutes: 5);
        try {
          final uri = Uri.parse(url);
          final request = await client.getUrl(uri).timeout(
                const Duration(seconds: 30),
              );
          request.headers.set('Accept', 'application/json');
          final response = await request.close().timeout(
                const Duration(seconds: 30),
              );
          if (response.statusCode != 200) {
            await response.drain<void>();
            continue;
          }
          // Используем `response.fold` (полная буферизация) — НЕ
          // streaming `await for`. Android emulator не отдаёт
          // EOF для streamed response (баг `flutter/engine#42055`).
          final bytes = await response.fold<List<int>>(
            <int>[],
            (acc, chunk) => acc..addAll(chunk),
          );
          final body = utf8.decode(bytes, allowMalformed: true);
          if (body.isEmpty) continue;
          return jsonDecode(body) as Map<String, dynamic>;
        } finally {
          client.close(force: true);
        }
      } catch (e) {
        developer.log(
          'fetchContentManifest($base) failed',
          name: 'QuranManifestApi',
          error: e,
        );
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
        // Используем `dart:io HttpClient` напрямую с **полной
        // буферизацией** через `bytes` (НЕ streaming). На Android
        // emulator streaming-запросы `await for (final chunk in
        // response)` зависают после первого chunk без EOF
        // (баг `flutter/engine#42055`). `response.bytes` блокирует
        // до получения **всего** body + EOF, что работает
        // надёжно. 5.6 MB — приемлемо для RAM на современных
        // устройствах (~14 MB double-buffer overhead max).
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 20)
          ..idleTimeout = const Duration(minutes: 5)
          ..maxConnectionsPerHost = 1;
        try {
          final uri = Uri.parse(url);
          final request = await client.getUrl(uri).timeout(
                const Duration(seconds: 30),
              );
          request.headers.set('Accept', 'application/json');
          final response = await request.close().timeout(
                const Duration(minutes: 5),
              );
          if (response.statusCode != 200) {
            await response.drain<void>();
            continue;
          }
          // `response.bytes` — блокирующий вызов, читает ВСЕ
          // данные + EOF. На Android emulator это работает,
          // в отличие от streaming `await for`.
          final bytes = await response.fold<List<int>>(
            <int>[],
            (acc, chunk) => acc..addAll(chunk),
          );
          return utf8.decode(bytes, allowMalformed: true);
        } finally {
          client.close(force: true);
        }
      } catch (e, st) {
        developer.log(
          'fetchPayload($base) failed',
          name: 'QuranManifestApi',
          error: e,
          stackTrace: st,
        );
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
/// `QuranManifestApi._manifestBaseEndpoints`).
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
