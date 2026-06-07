import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'content_manifest.dart';

/// Локальный seed-датасет: все 114 сур Корана (Uthmani + ru.kuliev +
/// en.sahih), зашитые в APK как `assets/quran_seed/quran_full.json`.
///
/// Обеспечивает offline-first первый запуск приложения (ARCHITECTURE §2):
/// - Нет зависимости от сети
/// - ~5 МБ JSON, парсится за ~100 ms
/// - API остаётся резервным каналом для будущих обновлений контента
///   (см. `ContentDownloader.downloadAll`)
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
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final surahs = (json['surahs'] as List)
        .cast<Map<String, dynamic>>()
        .map(_surahToDownloadFormat)
        .toList();
    final translators = (json['translators'] as List)
        .cast<Map<String, dynamic>>();
    final translations = (json['translations'] as List)
        .cast<Map<String, dynamic>>();

    _cached = ContentDownloadResult(
      surahs: surahs,
      translators: translators,
      translations: translations,
      ayahs: _explodeAyahs(surahs),
    );
    return _cached!;
  }

  /// JSON хранит аяты вложенно в `surah.ayahs: [{number, numberInSurah, text}]`.
  /// Чтобы не менять [ContentDownloader] / [ContentBootstrapper], разворачиваем
  /// в плоский список — тот же формат, что и API.
  List<Map<String, dynamic>> _explodeAyahs(
    List<Map<String, dynamic>> surahs,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final s in surahs) {
      final surahId = s['id'] as int;
      for (final a in (s['ayahs'] as List).cast<Map<String, dynamic>>()) {
        out.add({
          'id': a['number'] as int,
          'surah_id': surahId,
          'ayah_number': a['numberInSurah'] as int,
          'text_uthmani': a['text'] as String,
        });
      }
    }
    return out;
  }

  Map<String, dynamic> _surahToDownloadFormat(Map<String, dynamic> s) {
    return {
      'number': s['id'],
      'name': s['name_ar'],
      'englishName': s['name_en'],
      'englishNameTranslation': s['name_transliteration'],
      'revelationType': s['revelation_type'],
      'numberOfAyahs': s['ayah_count'],
    };
  }
}
