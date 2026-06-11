import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show ValueNotifier;

import 'content_bootstrapper.dart';
import 'content_manifest.dart';
import 'quran_api.dart';

/// Состояние процесса проверки content-обновлений.
enum ContentUpdateStage {
  idle,
  fetchingManifest,
  verifying,
  downloadingPayload,
  applying,
  completed,
  failed,
  notModified,
}

class ContentUpdateState {
  const ContentUpdateState({
    required this.stage,
    this.message,
    this.oldVersion,
    this.newVersion,
  });

  final ContentUpdateStage stage;
  final String? message;
  final String? oldVersion;
  final String? newVersion;

  bool get isRunning =>
      stage == ContentUpdateStage.fetchingManifest ||
      stage == ContentUpdateStage.verifying ||
      stage == ContentUpdateStage.downloadingPayload ||
      stage == ContentUpdateStage.applying;

  static const idle = ContentUpdateState(stage: ContentUpdateStage.idle);
}

/// Pipeline обновления контента (ARCHITECTURE §15):
///
/// 1. **Fetch manifest** через [QuranApi.fetchContentManifest] с
///    fallback'ом по [quranManifestFallbackEndpoints].
/// 2. **SHA256 verify** — для `contentVersion == appliedVersion`
///    → no-op (manifest не менялся). Для новой версии — скачиваем
///    payload и считаем SHA256, сверяем с `payload_sha256`.
/// 3. **ED25519 verify** — `ManifestSignatureVerifier.verify` —
///    `contentHash()` manifest'а должен подписываться публичным
///    ключом из [kManifestPublicKeyBase64].
/// 4. **min_app_version** — `appVersion >= manifest.minAppVersion`,
///    иначе throw (юзер должен обновить приложение).
/// 5. **Apply** — `manifestRepository.applyNetworkManifest(…)`
///    — единый метод, который либо применяет (с прохождением
///    всех проверок), либо rollback'ит + throws.
///
/// При любом провале шага 2-4 — rollback, `ContentUpdateState`
/// переходит в `failed`, пользователь видит SnackBar с описанием.
///
/// **Workmanager integration** — `checkAndApply` вызывается из
/// `BackgroundContentCheckWorker` раз в сутки (см.
/// `workmanager_callback_dispatcher.dart`).
class ContentUpdateService {
  ContentUpdateService({
    required this.api,
    required this.manifestRepository,
    required this.appVersion,
  });

  final QuranApi api;
  final ContentManifestRepository manifestRepository;
  final String appVersion;

  /// Notifier для UI. `_BootstrapScreen` подписывается и
  /// показывает SnackBar/баннер при `completed` или `failed`.
  final ValueNotifier<ContentUpdateState> state =
      ValueNotifier(ContentUpdateState.idle);

  /// Запустить проверку обновлений. Идемпотентно — повторный
  /// вызов во время running-стадии no-op.
  Future<void> checkAndApply() async {
    if (state.value.isRunning) return;
    state.value = const ContentUpdateState(stage: ContentUpdateStage.fetchingManifest);

    try {
      // 1) Fetch manifest
      final manifestJson = await api.fetchContentManifest();
      if (manifestJson == null) {
        // No network — нет обновлений.
        state.value = const ContentUpdateState(
          stage: ContentUpdateStage.notModified,
          message: 'offline',
        );
        return;
      }

      // Парсим manifest в DTO
      final remoteManifest = _parseManifest(manifestJson);
      final currentVersion = await manifestRepository.appliedVersion();
      state.value = ContentUpdateState(
        stage: ContentUpdateStage.verifying,
        oldVersion: currentVersion,
        newVersion: remoteManifest.contentVersion,
        message: currentVersion,
      );

      // 2) Skip, если версия не менялась (или downgrade)
      if (currentVersion != null &&
          _compareSemver(remoteManifest.contentVersion, currentVersion) <= 0) {
        state.value = const ContentUpdateState(
          stage: ContentUpdateStage.notModified,
        );
        return;
      }

      // 3) SHA256 verify payload (если указан)
      String? actualPayloadSha;
      if (remoteManifest.payloadSha256 != null) {
        state.value = const ContentUpdateState(
          stage: ContentUpdateStage.downloadingPayload,
        );
        final raw = await api.fetchPayload(
          contentVersion: remoteManifest.contentVersion,
          expectedSha256: remoteManifest.payloadSha256!,
        );
        actualPayloadSha =
            crypto.sha256.convert(utf8.encode(raw)).toString();
        if (actualPayloadSha != remoteManifest.payloadSha256) {
          throw ContentIntegrityError(
            'Payload SHA256 mismatch for ${remoteManifest.contentVersion}',
            expected: remoteManifest.payloadSha256,
            actual: actualPayloadSha,
          );
        }
      }

      // 4) ED25519 verify + min_app_version + apply — всё
      // внутри `manifestRepository.applyNetworkManifest`, с
      // автоматическим rollback при failure.
      state.value = const ContentUpdateState(
        stage: ContentUpdateStage.applying,
      );
      await manifestRepository.applyNetworkManifest(
        manifest: _buildContentManifest(remoteManifest),
        // Если manifest не содержит `payload_sha256` (например,
        // при metadata-only-обновлении), передаём пустую строку —
        // SHA256-верификация payload'а не выполняется, но
        // ED25519 + min_app_version всё равно работают.
        payloadSha256: actualPayloadSha ?? '',
        signatureBase64: remoteManifest.signatureBase64,
        appVersion: appVersion,
      );

      state.value = ContentUpdateState(
        stage: ContentUpdateStage.completed,
        oldVersion: currentVersion,
        newVersion: remoteManifest.contentVersion,
      );
      developer.log(
        'Content updated $currentVersion → ${remoteManifest.contentVersion}',
        name: 'ContentUpdateService',
      );
    } on ContentIntegrityError catch (e) {
      developer.log('Integrity check failed: $e', name: 'ContentUpdateService');
      state.value = ContentUpdateState(
        stage: ContentUpdateStage.failed,
        message: 'integrity: ${e.message}',
      );
    } catch (e, st) {
      developer.log('Update failed', name: 'ContentUpdateService', error: e, stackTrace: st);
      state.value = ContentUpdateState(
        stage: ContentUpdateStage.failed,
        message: '$e',
      );
    }
  }

  // ===== Parsing helpers =====

  _RemoteManifest _parseManifest(Map<String, dynamic> json) {
    return _RemoteManifest(
      contentVersion: (json['content_version'] as String?) ?? '0.0.0',
      minAppVersion: (json['min_app_version'] as String?) ?? '0.0.0',
      payloadSha256: json['payload_sha256'] as String?,
      signatureBase64: (json['signature'] as String?) ?? '',
      translations: (json['translations'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [],
      editions: (json['editions'] as List?)?.cast<String>() ??
          const ['quran-uthmani'],
    );
  }

  ContentManifest _buildContentManifest(_RemoteManifest rm) {
    return ContentManifest(
      contentVersion: rm.contentVersion,
      minAppVersion: rm.minAppVersion,
      editions: rm.editions,
      translations: rm.translations
          .map(
            (t) => TranslationManifestEntry(
              id: (t['id'] as int?) ?? 0,
              name: (t['name'] as String?) ?? '',
              languageCode: (t['language_code'] as String?) ?? '',
              edition: (t['edition'] as String?) ?? '',
            ),
          )
          .toList(),
    );
  }
}

/// DTO для remote manifest'а (отдельный от [ContentManifest],
/// потому что remote содержит signature + payload_sha256,
/// которых нет в локальном defaultManifest).
class _RemoteManifest {
  const _RemoteManifest({
    required this.contentVersion,
    required this.minAppVersion,
    required this.payloadSha256,
    required this.signatureBase64,
    required this.translations,
    required this.editions,
  });

  final String contentVersion;
  final String minAppVersion;
  final String? payloadSha256;
  final String signatureBase64;
  final List<Map<String, dynamic>> translations;
  final List<String> editions;
}

int _compareSemver(String a, String b) {
  List<int> parse(String v) {
    final parts = v.split('.');
    final nums = <int>[];
    for (var i = 0; i < 3; i++) {
      nums.add(i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
    }
    return nums;
  }

  final pa = parse(a);
  final pb = parse(b);
  for (var i = 0; i < 3; i++) {
    final d = pa[i] - pb[i];
    if (d != 0) return d;
  }
  return 0;
}
