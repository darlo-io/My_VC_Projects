import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

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

/// Хранит текущую применённую версию контента в SharedPreferences.
class ContentManifestRepository {
  ContentManifestRepository(this._prefs);

  final AppPreferences _prefs;

  static const _keyVersion = 'content.manifest.version';
  static const _keyHash = 'content.manifest.hash';

  /// Синхронно отдаёт манифест по сохранённой версии (для горячего пути
  /// router-redirect, где async недопустим).
  ContentManifest current() => defaultManifest();

  Future<String?> appliedVersion() async {
    return _prefs.getString(_keyVersion);
  }

  Future<bool> isCompatible(String appVersion) async {
    final m = current();
    return _compareSemver(appVersion, m.minAppVersion) >= 0;
  }

  Future<void> apply(ContentManifest m) async {
    await _prefs.setString(_keyVersion, m.contentVersion);
    await _prefs.setString(_keyHash, m.contentHash());
  }
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

/// Простое сравнение semver: a vs b. Возвращает
///   >0 если a > b, <0 если a < b, 0 если равны.
/// Неполные версии трактует как 0.
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
