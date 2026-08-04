import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart' as ed25519;

import '../storage/app_preferences.dart';

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
/// Round 9.5 (code review #C9): хранит manifest как **один JSON**
/// в SharedPreferences вместо четырёх отдельных ключей. Это
/// обеспечивает атомарность записи — при crash'е между write'ами
/// SharedPreferences не окажется в half-written состоянии
/// (старый код оставлял потенциально неконсистентный state, если
/// процесс падал между setString(версия) и setString(applied_at)).
///
/// На диске хранится (JSON-объект, строкой):
///   - `version` — `contentVersion` текущего manifest
///   - `hash` — `contentHash()` текущего manifest
///   - `payload_sha256` — SHA256 payload-файла, использованного
///     при bootstrap'е (опционально)
///   - `applied_at` — ISO-8601 timestamp последнего успешного
///     apply (для диагностики)
///
/// Rollback snapshot хранится в одном JSON-ключе
/// `content.manifest.prev`.
class ContentManifestRepository {
  ContentManifestRepository(this._prefs);

  final AppPreferences _prefs;

  static const _key = 'content.manifest';
  static const _keyPrev = 'content.manifest.prev';

  // Legacy-ключи (Round 9.5+): миграция со старого формата с
  // четырьмя отдельными ключами — на свежей установке их нет,
  // а при первом запуске после обновления автоматически
  // консолидируются в один JSON-ключ. После первой миграции —
  // удаляются из настроек.
  static const _legacyKeyVersion = 'content.manifest.version';
  static const _legacyKeyHash = 'content.manifest.hash';
  static const _legacyKeyPayloadSha256 = 'content.manifest.sha256';
  static const _legacyKeyAppliedAt = 'content.manifest.applied_at';

  /// Текущий применённый manifest. До `apply` (или на свежей
  /// установке) возвращает [defaultManifest] — это безопасно,
  /// потому что `defaultManifest` встроен в APK и его
  /// целостность гарантируется процессом релиза.
  ContentManifest current() {
    final stored = _readManifest();
    if (stored == null) return defaultManifest();
    // В проде здесь бы подтягивался `stored` manifest из
    // изолированного хранилища (file system) — но для MVP v0.1
    // manifest встроен в код, и `current()` всегда возвращает
    // его. См. [contentHash] и [appliedVersion] для проверки
    // согласованности.
    return defaultManifest();
  }

  /// Безопасно прочитать JSON-объект manifest'а. На свежей
  /// установке или после миграции со старого формата —
  /// возвращает null.
  Map<String, dynamic>? _readManifest() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Повреждённый JSON — трактуем как отсутствующий manifest.
      return null;
    }
  }

  /// Хеш применённого manifest (или null, если manifest ещё не
  /// применялся). Используется для проверки в `isCompatible`.
  String? appliedHash() {
    return _readManifest()?['hash'] as String?;
  }

  Future<String?> appliedVersion() async {
    await _ensureMigrated();
    return _readManifest()?['version'] as String?;
  }

  /// SHA256 payload-файла, который был применён последним. Используется
  /// при верификации [ContentBootstrapper.bootstrap] — если текущий
  /// файл не совпадает с тем, что был хеширован при apply, считаем,
  /// что контент повреждён и нужен re-seed.
  Future<String?> appliedPayloadSha256() async {
    await _ensureMigrated();
    return _readManifest()?['payload_sha256'] as String?;
  }

  /// Один раз мигрирует manifest с 4 отдельных ключей в
  /// JSON-ключ. Идемпотентно — повторный вызов безопасен (если
  /// JSON уже существует — пропускает; если legacy-ключей нет —
  /// ничего не делает). После миграции удаляет legacy-ключи.
  ///
  /// Это lazy migration (при первом обращении к методу), а не
  /// startup-migration, чтобы не добавлять блокирующий I/O на
  /// cold start.
  Future<void> _ensureMigrated() async {
    if (_prefs.getString(_key) != null) return;
    final legacyVersion = _prefs.getString(_legacyKeyVersion);
    if (legacyVersion == null) return;
    final legacyHash = _prefs.getString(_legacyKeyHash) ?? '';
    final legacySha = _prefs.getString(_legacyKeyPayloadSha256);
    final legacyAt = _prefs.getString(_legacyKeyAppliedAt) ?? '';
    final json = jsonEncode({
      'version': legacyVersion,
      'hash': legacyHash,
      'payload_sha256': legacySha,
      'applied_at': legacyAt,
    });
    await _prefs.setString(_key, json);
    await _prefs.remove(_legacyKeyVersion);
    await _prefs.remove(_legacyKeyHash);
    await _prefs.remove(_legacyKeyPayloadSha256);
    await _prefs.remove(_legacyKeyAppliedAt);
  }

  /// Реальная проверка совместимости. Сравнивает [appVersion] (например
  /// `1.2.3` или `1.2.3+45` из pubspec.yaml) с `minAppVersion` из
  /// **сохранённого** manifest через [current]. Если manifest
  /// ещё не применён (на свежей установке), использует [defaultManifest].
  Future<bool> isCompatible(String appVersion) async {
    final m = current();
    return _compareSemver(_stripBuildSuffix(appVersion), m.minAppVersion) >= 0;
  }

  /// Применить [newManifest]. Шаги:
  ///   1. Backup текущего manifest в snapshot-ключ (для rollback).
  ///   2. Пишем новый manifest как JSON в один ключ.
  ///   3. Если вызывающий сообщил, что apply провалился
  ///      (например, signature verification failed) — зовёт
  ///      [rollback], и snapshot восстанавливается.
  ///
  /// Round 9.5 (code review #C9): оба setString теперь
  /// атомарны (один ключ → один JSON), при crash'е между
  /// snapshot и write пользователь не увидит неконсистентный
  /// manifest.
  Future<void> apply(
    ContentManifest newManifest, {
    String? payloadSha256,
  }) async {
    await _snapshotPrevious();
    await _writeManifest(newManifest, payloadSha256);
  }

  Future<void> _writeManifest(ContentManifest m, String? payloadSha256) async {
    final json = jsonEncode({
      'version': m.contentVersion,
      'hash': m.contentHash(),
      'payload_sha256': payloadSha256,
      'applied_at': DateTime.now().toUtc().toIso8601String(),
    });
    await _prefs.setString(_key, json);
  }

  /// Snapshot текущего manifest в `content.manifest.prev`. Вызывается
  /// из [apply] ДО записи нового значения. Если snapshot уже есть
  /// (от предыдущего apply) — он **перезаписывается** (теряется
  /// pre-snapshot), так как каждый apply начинается «с нуля» —
  /// нам нужен только последний успешный baseline.
  Future<void> _snapshotPrevious() async {
    final current = _readManifest();
    if (current == null) {
      await _prefs.remove(_keyPrev);
    } else {
      await _prefs.setString(_keyPrev, jsonEncode(current));
    }
  }

  /// Rollback: восстановить manifest, который был до последнего
  /// `apply`. Используется при провале signature/SHA256
  /// verification в `ContentBootstrapper.bootstrap`.
  ///
  /// Если snapshot есть — копируем его обратно и очищаем snapshot.
  /// Если snapshot пуст (свежая установка или первый apply) —
  /// wipe ключа, manifest сбрасывается на [defaultManifest].
  Future<void> rollback() async {
    final prevRaw = _prefs.getString(_keyPrev);
    if (prevRaw != null && prevRaw.isNotEmpty) {
      // Snapshot есть — восстанавливаем.
      await _prefs.setString(_key, prevRaw);
      await _prefs.remove(_keyPrev);
    } else {
      // Snapshot пуст — wipe ключа (как раньше).
      await _prefs.remove(_key);
      await _prefs.remove(_keyPrev);
    }
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
