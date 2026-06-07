// Одноразовый скрипт: качает все 114 сур Корана с api.alquran.cloud
// (текст Усмани + переводы ru.kuliev + en.sahih) и пишет в
// assets/quran_seed/quran_full.json.
//
// Запуск (с dev-машины с интернетом):
//   dart run tools/build_quran_seed.dart
//
// Размер итогового JSON ~2-3 МБ. Бандлим в APK — приложение работает
// полностью офлайн после первой установки.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

const String _base = 'https://api.alquran.cloud/v1';
const List<_Edition> _editions = [
  _Edition(id: 1, name: 'Кулиев', languageCode: 'ru', edition: 'ru.kuliev'),
  _Edition(
    id: 2,
    name: 'Sahih International',
    languageCode: 'en',
    edition: 'en.sahih',
  ),
];

class _Edition {
  const _Edition({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.edition,
  });
  final int id;
  final String name;
  final String languageCode;
  final String edition;
}

Future<void> main() async {
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 20)));

  print('Fetching surah metadata…');
  final surahsMeta = await _fetchSurahsMeta(dio);
  print('  ${surahsMeta.length} surahs.');

  final out = <String, dynamic>{
    'version': '1.0.0',
    'surahs': <Map<String, dynamic>>[],
    'translators': <Map<String, dynamic>>[],
    'translations': <Map<String, dynamic>>[],
  };
  for (final t in _editions) {
    (out['translators'] as List).add({
      'id': t.id,
      'name': t.name,
      'language_code': t.languageCode,
      'source': 'alquran.cloud',
    });
  }

  // Bounded-concurrency: 2 параллельных запроса (API rate-limits).
  final limiter = _Semaphore(2);

  // 1) Uthmani + переводы — каждый ayah несёт global id в поле `number`.
  //    Сохраняем {globalId -> inSurahNumber, text} для каждой суры.
  print('Fetching uthmani text…');
  final uthmaniByNumber = <int, List<Map<String, dynamic>>>{};
  await _runInParallel(
    items: List.generate(surahsMeta.length, (i) => i),
    concurrency: 2,
    task: (i) async {
      final s = surahsMeta[i];
      final n = s['number'] as int;
      await limiter.acquire();
      try {
        final res = await _fetchSurahEdition(dio, n, 'quran-uthmani');
        final ayahs = (res['ayahs'] as List).cast<Map<String, dynamic>>();
        uthmaniByNumber[n] = ayahs
            .map((a) => {
                  'number': a['number'] as int,
                  'numberInSurah': a['numberInSurah'] as int,
                  'text': (a['text'] as String).trim(),
                })
            .toList();
      } finally {
        limiter.release();
      }
    },
  );

  // 2) Переводы
  print('Fetching translations…');
  final translationsByEdition = <int, Map<int, List<Map<String, dynamic>>>>{};
  for (final t in _editions) {
    print('  ${t.edition}…');
    final map = <int, List<Map<String, dynamic>>>{};
    await _runInParallel(
      items: List.generate(surahsMeta.length, (i) => i),
      concurrency: 2,
      task: (i) async {
        final s = surahsMeta[i];
        final n = s['number'] as int;
        await limiter.acquire();
        try {
          final res = await _fetchSurahEdition(dio, n, t.edition);
          final ayahs = (res['ayahs'] as List).cast<Map<String, dynamic>>();
          map[n] = ayahs
              .map((a) => {
                    'number': a['number'] as int,
                    'numberInSurah': a['numberInSurah'] as int,
                    'text': (a['text'] as String).trim(),
                  })
              .toList();
        } finally {
          limiter.release();
        }
      },
    );
    translationsByEdition[t.id] = map;
  }

  // 3) Сборка surahs + translations
  for (final s in surahsMeta) {
    final n = s['number'] as int;
    final ayahs = uthmaniByNumber[n] ?? const <Map<String, dynamic>>[];
    out['surahs'].add({
      'id': n,
      'name_ar': s['name'],
      'name_en': s['englishName'],
      'name_transliteration': s['englishNameTranslation'],
      'revelation_type': s['revelationType'],
      'ayah_count': s['numberOfAyahs'],
      'order_in_mushaf': n,
      'ayahs': ayahs,
    });
    for (final t in _editions) {
      final ayahList = translationsByEdition[t.id]?[n] ?? const [];
      for (final a in ayahList) {
        out['translations'].add({
          'ayah_id': a['number'],
          'translator_id': t.id,
          'language_code': t.languageCode,
          'text': a['text'],
        });
      }
    }
  }

  final outPath = 'assets/quran_seed/quran_full.json';
  final file = File(outPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  final sizeMb = (file.lengthSync() / 1024 / 1024).toStringAsFixed(2);
  print('Wrote $outPath (${sizeMb} MB)');
}

Future<List<Map<String, dynamic>>> _fetchSurahsMeta(Dio dio) async {
  final res = await dio.get<Map<String, dynamic>>('$_base/surah');
  final data = res.data!;
  if (data['code'] != 200) {
    throw Exception('Meta fetch failed: ${data['data']}');
  }
  return (data['data'] as List).cast<Map<String, dynamic>>();
}

Future<Map<String, dynamic>> _fetchSurahEdition(
  Dio dio,
  int surah,
  String edition,
) async {
  // Ретрай с экспоненциальным backoff для 429/5xx.
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '$_base/surah/$surah/$edition',
      );
      final data = res.data!;
      if (data['code'] != 200) {
        throw Exception('Edition fetch failed: $surah/$edition');
      }
      return data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final isLast = attempt == 4;
      final retryable = e.response?.statusCode == 429 ||
          e.response?.statusCode == 502 ||
          e.response?.statusCode == 503 ||
          e.type == DioExceptionType.connectionError;
      if (!retryable || isLast) rethrow;
      final delay = Duration(milliseconds: 500 * (1 << attempt));
      print('  retry $surah/$edition in ${delay.inMilliseconds}ms '
          '(status ${e.response?.statusCode})');
      await Future<void>.delayed(delay);
    }
  }
  throw Exception('Unreachable');
}

Future<void> _runInParallel<T>({
  required List<T> items,
  required int concurrency,
  required Future<void> Function(T) task,
}) async {
  final queue = List<T>.from(items);
  final active = <Future<void>>[];
  while (queue.isNotEmpty || active.isNotEmpty) {
    while (active.length < concurrency && queue.isNotEmpty) {
      final t = queue.removeAt(0);
      active.add(task(t));
    }
    if (active.isNotEmpty) {
      await Future.wait(active);
      active.clear();
    }
  }
}

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
