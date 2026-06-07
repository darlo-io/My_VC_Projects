import 'dart:async';

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
  Future<ContentDownloadResult> load() {
    if (_cached != null) return Future.value(_cached);
    return _inflight ??= _doLoad();
  }

  Future<ContentDownloadResult> _doLoad() async {
    final raw = await rootBundle.loadString(assetPath);
    _cached = SeedParser.parse(raw);
    return _cached!;
  }
}
