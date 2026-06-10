import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart' show rootBundle;

import 'seed_parser.dart';
import 'seed_types.dart';

/// Локальный seed-датасет: все 114 сур Корана (Uthmani + ru.kuliev +
/// en.sahih), зашитые в APK как `assets/quran_seed/quran_full.json`.
///
/// Обеспечивает offline-first первый запуск приложения (ARCHITECTURE §2):
/// - Нет зависимости от сети
/// - ~5 МБ JSON, парсится за ~100 ms
/// - API остаётся резервным каналом для будущих обновлений контента
///   (см. `ContentDownloader.downloadAll`)
///
/// Парсинг делегирован [SeedParser] — pure-Dart функция, тестируемая
/// через `dart test` без flutter_tester.
class LocalSeedService {
  LocalSeedService({this.assetPath = 'assets/quran_seed/quran_full.json'});

  final String assetPath;

  ContentDownloadResult? _cached;
  Future<ContentDownloadResult>? _inflight;

  /// Прочитать bundle и вернуть данные в формате, совместимом с
  /// [ContentDownloader.downloadAll].
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
    _cached = SeedParser.parse(raw);
    return _cached!;
  }
}
