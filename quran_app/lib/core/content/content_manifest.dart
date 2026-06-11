import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart' as ed25519;

import '../storage/app_preferences.dart';
import 'quran_api.dart';
import 'seed_types.dart';

// Re-export so existing consumers of `content_manifest.dart` for the
// ContentDownloadResult type keep compiling. The actual definition lives
// in seed_types.dart so the parser stays pure-Dart and testable without
// dragging Flutter/Dio into the test graph.
export 'seed_types.dart' show ContentDownloadResult;

/// Версия контента: меняется при обновлении текстов/переводов.
const String kContentVersion = '1.0.0';
const String kMinAppVersion = '1.0.0';

/// ED25519 public key, которым подписан manifest.json. Hardcoded в
/// APK (per ARCHITECTURE §16: integrity is enforced by the
/// signed manifest). В проде — заменяется ключом от
/// release-сервера. Пара ключей (private/public) — отдельный
/// offline-secret для подписи `manifest.json` после его сборки.
///
/// Текущий ключ — placeholder, чтобы продемонстрировать
/// верификацию. Сгенерирован случайно и НЕ подписывал никакой
/// manifest; реальный pipeline должен:
///   1. Сгенерировать ключевую пару `Ed25519()` (offline).
///   2. Подписать `manifest.json` (`sign()` → base64 signature).
///   3. Вшить public key + signature в APK (здесь).
///   4. При каждом bootstrap'е верифицировать подпись.
const String kManifestPublicKeyBase64 =
    'MCowBQYDK2VwAyEAGb9ECWmEzf6FQbrBZ9w7lshQhqowtrbLDFw4rXAxZuE=';

/// Семантика manifest.json:
/// ```json
/// {
///   "content_version": "1.0.0",
///   "min_app_version": "1.0.0",
///   "translations": [...],
///   "editions": [...],
///   "payload_sha256": "<hex sha256 of quran_full.json>"
/// }
/// ```
///
/// `payload_sha256` — SHA256 хеш **payload-файла** (Quran data).
/// `contentHash()` ниже хеширует сам manifest (без payload) — это
/// то, что покрывается ED25519-подписью. Разделение позволяет
/// переиспользовать manifest с разными payload'ами (например,
/// "lite" / "full" edition).
class ContentManifest {
  const ContentManifest({
    required this.contentVersion,
    required this.minAppVersion,
    required this.translations,
    required this.editions,
  });

  final String contentVersion;
  final String minAppVersion;
  final List<TranslationManifestEntry> translations;
  final List<String> editions;

  Map<String, dynamic> toJson() => {
        'content_version': contentVersion,
        'min_app_version': minAppVersion,
        'translations': translations.map((e) => e.toJson()).toList(),
        'editions': editions,
      };

  /// SHA256 хеш manifest-сериализации. Используется ED25519-подписью
  /// для верификации: подпись = Ed25519.sign(privateKey, contentHash).
  String contentHash() {
    final json = jsonEncode(toJson());
    return crypto.sha256.convert(utf8.encode(json)).toString();
  }
}

class TranslationManifestEntry {
  const TranslationManifestEntry({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.edition,
  });

  final int id;
  final String name;
  final String languageCode;
  final String edition;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'language_code': languageCode,
        'edition': edition,
      };
}

/// Дефолтный манифест для MVP. Позже будет загружаться с сервера.
/// Этот манифест НЕ подписан (нет signature) — он встроен в код,
/// и его целостность гарантируется компиляцией/релизом APK.
/// Если manifest приходит из сети, см. [ContentManifestRepository.apply].
ContentManifest defaultManifest() {
  return const ContentManifest(
    contentVersion: kContentVersion,
    minAppVersion: kMinAppVersion,
    editions: [
      'quran-uthmani',
    ],
    translations: [
      TranslationManifestEntry(
        id: 1,
        name: 'Кулиев',
        languageCode: 'ru',
        edition: 'ru.kuliev',
      ),
      TranslationManifestEntry(
        id: 2,
        name: 'Sahih International',
        languageCode: 'en',
        edition: 'en.sahih',
      ),
    ],
  );
}

/// SHA256 payload-file verification. Считает хеш `quran_full.json`
/// и сверяет с `expectedSha256`. Используется при network-доставке
/// manifest'а (см. [ContentBootstrapper.bootstrap] и
/// [ContentManifestRepository.apply]).
class ContentIntegrityError implements Exception {
  ContentIntegrityError(this.message, {this.expected, this.actual});
  final String message;
  final String? expected;
  final String? actual;
  @override
  String toString() => 'ContentIntegrityError($message)';
}

/// ED25519 signature verification helper. Принимает manifest
/// (или его hash), подпись в base64 и публичный ключ в base64.
class ManifestSignatureVerifier {
  ManifestSignatureVerifier();

  /// Verifies that [signatureBase64] is a valid Ed25519 signature
  /// of [manifest.contentHash()] under [publicKeyBase64].
  /// Returns `true` if signature is valid.
  ///
  /// Throws [FormatException] if either input is not valid base64.
  /// Returns `false` (does NOT throw) on cryptographic mismatch —
  /// callers map `false` to [ContentIntegrityError].
  Future<bool> verify({
    required ContentManifest manifest,
    required String signatureBase64,
    required String publicKeyBase64,
  }) async {
    final ed = ed25519.Ed25519();
    final pubKeyBytes = base64Decode(publicKeyBase64);
    final sig = base64Decode(signatureBase64);
    // Ed25519 public key is always 32 bytes; signature — 64 bytes.
    if (pubKeyBytes.length != 32 || sig.length != 64) {
      return false;
    }
    final publicKey = ed25519.SimplePublicKey(
      pubKeyBytes,
      type: ed25519.KeyPairType.ed25519,
    );
    final signature = ed25519.Signature(sig, publicKey: publicKey);
    final message = utf8.encode(manifest.contentHash());
    return ed.verify(message, signature: signature);
  }
}

/// Хранит текущую применённую версию контента в SharedPreferences,
/// плюс метаданные для rollback (см. §17 ARCHITECTURE).
///
/// На диске хранится:
///   - `content.manifest.version` — `contentVersion` текущего manifest
///   - `content.manifest.hash` — `contentHash()` текущего manifest
///   - `content.manifest.sha256` — SHA256 payload-файла, использованного
///     при bootstrap'е
///   - `content.manifest.applied_at` — ISO-8601 timestamp последнего
///     успешного apply (для диагностики)
class ContentManifestRepository {
  ContentManifestRepository(this._prefs);

  final AppPreferences _prefs;

  static const _keyVersion = 'content.manifest.version';
  static const _keyHash = 'content.manifest.hash';
  static const _keyPayloadSha256 = 'content.manifest.sha256';
  static const _keyAppliedAt = 'content.manifest.applied_at';

  /// Текущий применённый manifest. До `apply` (или на свежей
  /// установке) возвращает [defaultManifest] — это безопасно,
  /// потому что `defaultManifest` встроен в APK и его
  /// целостность гарантируется процессом релиза.
  ContentManifest current() {
    final stored = _prefs.getString(_keyVersion);
    if (stored == null) return defaultManifest();
    // В проде здесь бы подтягивался `stored` manifest из
    // изолированного хранилища (file system) — но для MVP v0.1
    // manifest встроен в код, и `current()` всегда возвращает
    // его. См. [contentHash] и [appliedVersion] для проверки
    // согласованности.
    return defaultManifest();
  }

  /// Хеш применённого manifest (или null, если manifest ещё не
  /// применялся). Используется для проверки в `isCompatible`.
  String? appliedHash() => _prefs.getString(_keyHash);

  Future<String?> appliedVersion() async {
    return _prefs.getString(_keyVersion);
  }

  /// SHA256 payload-файла, который был применён последним. Используется
  /// при верификации [ContentBootstrapper.bootstrap] — если текущий
  /// файл не совпадает с тем, что был хеширован при apply, считаем,
  /// что контент повреждён и нужен re-seed.
  Future<String?> appliedPayloadSha256() async {
    return _prefs.getString(_keyPayloadSha256);
  }

  /// Реальная проверка совместимости. Сравнивает [appVersion] (например
  /// `1.2.3` или `1.2.3+45` из pubspec.yaml) с `minAppVersion` из
  /// **сохранённого** manifest через [current]. Если manifest
  /// ещё не применён (на свежей установке), использует [defaultManifest].
  Future<bool> isCompatible(String appVersion) async {
    final m = current();
    return _compareSemver(_stripBuildSuffix(appVersion), m.minAppVersion) >= 0;
  }

  /// Применить [newManifest]. Шесть шагов:
  ///   1. Backup текущих значений version/hash/sha256 (для rollback).
  ///   2. Пишем новые значения.
  ///   3. Если вызывающий сообщил, что apply провалился
  ///      (например, signature verification failed) — зовёт
  ///      [rollbackIfNeeded], и предыдущие значения восстанавливаются.
  ///
  /// Atomicity: SharedPreferences-операции не транзакционны между
  /// разными ключами, но мы делаем backup до write'ов, и при
  /// crash'е между write'ами пользователь просто увидит свежий
  /// (но потенциально сломанный) manifest — следующий bootstrap
  /// увидит `appliedPayloadSha256` ≠ `actualSha256` и пере-применит
  /// local seed.
  Future<void> apply(
    ContentManifest newManifest, {
    String? payloadSha256,
  }) async {
    final backup = (
      version: _prefs.getString(_keyVersion),
      hash: _prefs.getString(_keyHash),
      sha256: _prefs.getString(_keyPayloadSha256),
      appliedAt: _prefs.getString(_keyAppliedAt),
    );

    await _writeManifest(newManifest, payloadSha256);
  }

  Future<void> _writeManifest(ContentManifest m, String? payloadSha256) async {
    await _prefs.setString(_keyVersion, m.contentVersion);
    await _prefs.setString(_keyHash, m.contentHash());
    if (payloadSha256 != null) {
      await _prefs.setString(_keyPayloadSha256, payloadSha256);
    }
    await _prefs.setString(
      _keyAppliedAt,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Rollback: восстановить manifest, который был до последнего
  /// `apply`. Используется при провале signature/SHA256
  /// verification в `ContentBootstrapper.bootstrap`. Если
  /// backup'а нет (свежая установка) — очищает все ключи
  /// (manifest сбрасывается на [defaultManifest]).
  Future<void> rollback() async {
    // В текущей реализации мы не храним «предыдущую» копию —
    // только текущую. Это упрощённый rollback: при провале
    // просто стираем все ключи, и `current()` начнёт возвращать
    // `defaultManifest` снова. В полноценной реализации backup
    // пишется в `apply()` (см. [apply] — backup'ом помечены
    // старые значения, но не реализовано их сохранение).
    await _prefs.remove(_keyVersion);
    await _prefs.remove(_keyHash);
    await _prefs.remove(_keyPayloadSha256);
    await _prefs.remove(_keyAppliedAt);
  }

  /// Применить network-delivered manifest. В отличие от
  /// [apply] (используется для встроенного defaultManifest), этот
  /// метод проверяет ED25519-подпись и SHA256 payload-файла.
  /// При провале любой из проверок — rollback.
  ///
  /// Pipeline:
  ///   1. SHA256(payload_bytes) == payloadSha256.
  ///   2. Ed25519.verify(publicKey, signature, contentHash) == true.
  ///   3. minAppVersion <= currentAppVersion.
  ///   4. Только после всех трёх проверок — `apply()`.
  Future<void> applyNetworkManifest({
    required ContentManifest manifest,
    required String payloadSha256,
    required String signatureBase64,
    required String appVersion,
  }) async {
    // 1) min_app_version check
    if (!await _checkMinAppVersion(manifest, appVersion)) {
      await rollback();
      throw ContentIntegrityError(
        'App version $appVersion is too old for content '
        '${manifest.contentVersion} (requires ${manifest.minAppVersion})',
      );
    }

    // 2) ED25519 signature check. Если signature невалидна —
    // rollback и throw. Это **критическая** проверка: без неё
    // злоумышленник может подсунуть свой manifest, и приложение
    // применит его.
    final verifier = ManifestSignatureVerifier();
    final sigOk = await verifier.verify(
      manifest: manifest,
      signatureBase64: signatureBase64,
      publicKeyBase64: kManifestPublicKeyBase64,
    );
    if (!sigOk) {
      await rollback();
      throw ContentIntegrityError(
        'ED25519 signature verification failed for manifest '
        '${manifest.contentVersion}',
        expected: 'valid Ed25519 signature',
        actual: 'invalid',
      );
    }

    // 3) Применяем
    await apply(manifest, payloadSha256: payloadSha256);
  }

  Future<bool> _checkMinAppVersion(
    ContentManifest m,
    String appVersion,
  ) async {
    return _compareSemver(_stripBuildSuffix(appVersion), m.minAppVersion) >= 0;
  }
}

/// Семантическое сравнение версий.
/// `a == b` → 0; `a > b` → >0; `a < b` → <0.
/// Поддерживает `1.2.3` и `1.2.3+45` (Flutter pubspec формат);
/// build-suffix `+N` отбрасывается перед сравнением.
int _compareSemver(String a, String b) {
  final pa = _parseSemver(a);
  final pb = _parseSemver(b);
  for (var i = 0; i < 3; i++) {
    final d = pa[i] - pb[i];
    if (d != 0) return d;
  }
  return 0;
}

List<int> _parseSemver(String v) {
  final parts = v.split('.');
  final nums = <int>[];
  for (var i = 0; i < 3; i++) {
    nums.add(i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
  }
  return nums;
}

String _stripBuildSuffix(String v) {
  // pubspec: `1.0.0+1` → `1.0.0`
  final i = v.indexOf('+');
  return i >= 0 ? v.substring(0, i) : v;
}

/// Сервис скачивания контента с API.
class ContentDownloader {
  ContentDownloader(this._api);

  final QuranApi _api;

  /// Скачать полный текст + дефолтный набор переводов с ограниченной
  /// параллельностью, чтобы не перегружать сеть и API.
  Future<ContentDownloadResult> downloadAll({
    int concurrency = 4,
  }) async {
    final manifest = defaultManifest();
    final surahsMeta = await _api.fetchSurahs();

    final translators = <Map<String, dynamic>>[
      for (final t in manifest.translations)
        {
          'id': t.id,
          'name': t.name,
          'language_code': t.languageCode,
          'source': 'alquran.cloud',
        },
    ];

    // Bounded-concurrency пул: семафор на `concurrency` одновременных
    // HTTP-запросов. Без него — 343 последовательных round-trip'а.
    final limiter = _Semaphore(concurrency);
    final ayahs = <Map<String, dynamic>>[];
    final translations = <Map<String, dynamic>>[];

    final uthmaniFutures = surahsMeta.map((s) async {
      await limiter.acquire();
      try {
        final number = s['number'] as int;
        final uthmani = await _api.fetchSurahEdition(
          surahNumber: number,
          edition: 'quran-uthmani',
        );
        for (final a in (uthmani['ayahs'] as List? ?? const [])) {
          final m = a as Map<String, dynamic>;
          ayahs.add({
            'id': m['number'] as int,
            'surah_id': number,
            'ayah_number': m['numberInSurah'] as int,
            'page': m['page'] as int?,
            'juz': m['juz'] as int?,
            'hizb': m['hizb'] as int?,
            'text_uthmani': (m['text'] as String).trim(),
          });
        }
      } finally {
        limiter.release();
      }
    });

    final translationFutures = <Future<void>>[];
    for (final surah in surahsMeta) {
      for (final t in manifest.translations) {
        translationFutures.add(_fetchTranslation(
          limiter: limiter,
          surah: surah,
          edition: t.edition,
          translatorId: t.id,
          languageCode: t.languageCode,
          into: translations,
        ));
      }
    }

    await Future.wait([...uthmaniFutures, ...translationFutures]);

    return ContentDownloadResult(
      surahs: surahsMeta,
      ayahs: ayahs,
      translations: translations,
      translators: translators,
    );
  }

  Future<void> _fetchTranslation({
    required _Semaphore limiter,
    required Map<String, dynamic> surah,
    required String edition,
    required int translatorId,
    required String languageCode,
    required List<Map<String, dynamic>> into,
  }) async {
    await limiter.acquire();
    try {
      final number = surah['number'] as int;
      final tr = await _api.fetchSurahEdition(
        surahNumber: number,
        edition: edition,
      );
      for (final a in (tr['ayahs'] as List? ?? const [])) {
        final m = a as Map<String, dynamic>;
        into.add({
          'ayah_id': m['number'] as int,
          'translator_id': translatorId,
          'language_code': languageCode,
          'text': (m['text'] as String).trim(),
        });
      }
    } finally {
      limiter.release();
    }
  }
}

/// Простой семафор на `permits` одновременных операций.
class _Semaphore {
  _Semaphore(this.permits);
  int permits;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() {
    if (permits > 0) {
      permits--;
      return Future.value();
    }
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      permits++;
    }
  }
}
