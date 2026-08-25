import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart' show rootBundle;

import '../search/arabic_normalizer.dart';
import 'seed_parser.dart';
import 'seed_types.dart';

/// Локальный seed-датасет: все 114 сур Корана (Uthmani + ru.kuliev +
/// en.sahih), зашитые в APK как `assets/quran_seed/quran_full.json`.
///
/// Обеспечивает offline-first первый запуск приложения (ARCHITECTURE §2):
/// - Нет зависимости от сети
/// - ~5 МБ JSON
/// - Сеть остаётся резервным каналом обновлений контента
///   (см. `ContentUpdateService.checkAndApply`)
///
/// Парсинг делегирован [SeedParser] и выполняется в фоновом изоляте
/// ([Isolate.run]): jsonDecode 5 МБ + нормализация ~6236 аятов +
/// SHA256 на UI-изоляте замораживали спиннер бутстрапа на первый
/// запуск. Результат (и хеш raw-JSON) кешируется.
class LocalSeedService {
  LocalSeedService({this.assetPath = 'assets/quran_seed/quran_full.json'});

  final String assetPath;

  ContentDownloadResult? _cached;
  String? _cachedSha256;
  Future<ContentDownloadResult>? _inflight;

  /// SHA256 hex-хеш raw seed-JSON. Доступен после завершения [load];
  /// бутстраппер пишет его в manifest вместо повторного чтения и
  /// хеширования актива на UI-потоке.
  String get rawSha256 {
    final v = _cachedSha256;
    if (v == null) {
      throw StateError('LocalSeedService.load() has not completed yet');
    }
    return v;
  }

  /// Прочитать bundle и вернуть распарсенный датасет.
  ///
  /// Если предыдущая попытка упала, [_inflight] сбрасывается, и
  /// следующий вызов пробует заново. Без этого retry-кнопка на
  /// bootstrap-экране была бы бесполезна — `load()` возвращал бы
  /// залипший `Future.error` до конца сессии.
  Future<ContentDownloadResult> load() {
    if (_cached != null) return Future.value(_cached);
    final inflight = _inflight;
    if (inflight != null) {
      // Проверяем, не залипла ли прошлая попытка в error. `Future`
      // нельзя напрямую «распечатать» на ошибки, но мы можем
      // использовать `inflight.then(...)` чтобы отследить результат
      // асинхронно. На первом успешном `load()` флаг снимется
      // сам через `_cached`.
      inflight.then((_) {}, onError: (Object e, StackTrace st) {
        developer.log(
          'localSeed.load() failed once; resetting _inflight for retry',
          name: 'LocalSeedService',
          error: e,
          stackTrace: st,
        );
        if (identical(_inflight, inflight)) {
          _inflight = null;
        }
      });
      return inflight;
    }
    return _inflight = _doLoad();
  }

  Future<ContentDownloadResult> _doLoad() async {
    final raw = await rootBundle.loadString(assetPath);
    final (result, sha256hex) = await Isolate.run(() {
      final parsed = SeedParser.parse(raw);
      // Предвычисляем text_normalized здесь же, в изоляте:
      // регэксп-нормализация ~6236 аятов не должна гонять regex-цикл
      // по UI-потоку. Бутстраппер вставляет готовое значение.
      for (final a in parsed.ayahs) {
        a['text_normalized'] =
            ArabicNormalizer.normalize(a['text_uthmani'] as String);
      }
      final hash = crypto.sha256.convert(utf8.encode(raw)).toString();
      return (parsed, hash);
    });
    _cached = result;
    _cachedSha256 = sha256hex;
    return result;
  }
}
