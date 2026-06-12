import 'dart:async';

import 'package:dio/dio.dart';

/// Цепочка CDN-источников для аудио-сур (§12 ARCHITECTURE).
///
/// Пробуем источники по порядку; первый успешный HTTP 200
/// (с непустым `Content-Length`) выигрывает. Если все источники
/// вернули 404 / 5xx / network error — бросаем [AllSourcesFailed]
/// с массивом последних ошибок (для диагностики).
///
/// Каждый источник — это `{ id, name, urlTemplate }`. URL-template
/// может быть:
///   - `{surah}` placeholder — подставляется через `replaceAll`
///     с padLeft(3, '0'). Пример: `https://x.com/{surah}.mp3`.
///   - без placeholder — для статических URL (CDN, который
///     использует `/reciter/surah/...` в path).
///
/// По умолчанию [defaultAudioSourceChain] содержит 2 источника:
///   1. `primary` — islamic.network Quran audio CDN
///   2. `backup`  — Islamic network HTTPS mirror
///
/// Источники — это просто метаданные. Загрузка идёт через
/// переданный [Dio] (см. [AudioCache] / [AudioPlayerController]).
class AudioSource {
  const AudioSource({
    required this.id,
    required this.name,
    required this.urlTemplate,
  });
  final String id;
  final String name;

  /// Шаблон URL с placeholder `{surah}`. Пример:
  /// `https://cdn.example.com/audio/{surah}.mp3`
  final String urlTemplate;

  String resolveUrl(int surahNumber) {
    return urlTemplate.replaceAll(
      '{surah}',
      surahNumber.toString().padLeft(3, '0'),
    );
  }
}

/// Цепочка источников. Содержит упорядоченный список [sources]
/// и опциональный `perSourceTimeout` (на случай зависших
/// серверов — не ждать 30 секунд каждый).
class AudioSourceChain {
  AudioSourceChain({
    required this.sources,
    this.perSourceTimeout = const Duration(seconds: 10),
  }) : assert(sources.isNotEmpty, 'AudioSourceChain requires >=1 source');

  final List<AudioSource> sources;
  final Duration perSourceTimeout;

  /// URL первого источника. Используется для "tried URL" в
  /// `AudioPlayerState.error`, чтобы UI мог показать, какой
  /// именно URL не сработал.
  AudioSource get first => sources.first;

  /// Сгенерировать полный URL для конкретного источника в цепочке.
  /// `index` бросает `RangeError` если >= sources.length.
  String urlAt(int index, int surahNumber) =>
      sources[index].resolveUrl(surahNumber);
}

/// Итог попытки по одному источнику: либо удалось (с URL и
/// размером), либо провалилось (с исключением).
class SourceAttempt {
  const SourceAttempt.failed({
    required this.source,
    required this.error,
  })  : size = null;
  const SourceAttempt.success({
    required this.source,
    required this.size,
  }) : error = null;

  final AudioSource source;
  final Object? error;
  final int? size;

  bool get ok => error == null;
}

/// Финальная ошибка, когда ВСЕ источники провалились. Содержит
/// список [attempts] — для логирования/диагностики.
class AllSourcesFailed implements Exception {
  AllSourcesFailed(this.attempts, this.reciterId, this.surahId);
  final List<SourceAttempt> attempts;
  final String reciterId;
  final int surahId;

  /// Самая «интересная» ошибка для показа пользователю: предпочитаем
  /// 404 (файл не найден на этом CDN), 5xx (CDN сломан), timeout,
  /// и только в конце — generic network error.
  String get primaryError {
    for (final a in attempts) {
      final err = a.error;
      if (err is DioException) {
        if (err.response?.statusCode == 404) {
          return '404 not found on ${a.source.name}';
        }
      }
    }
    for (final a in attempts) {
      final err = a.error;
      if (err is DioException) {
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout) {
          return '${a.source.name}: timeout';
        }
      }
    }
    for (final a in attempts) {
      final err = a.error;
      if (err is DioException) {
        final code = err.response?.statusCode;
        if (code != null && code >= 500) {
          return '$code server error on ${a.source.name}';
        }
      }
    }
    return attempts.first.error?.toString() ?? 'Unknown error';
  }

  @override
  String toString() =>
      'AllSourcesFailed(reciter=$reciterId, surah=$surahId, attempts=${attempts.length})';
}

/// Резолвер URL через цепочку источников. Использует [Dio]
/// для HEAD-запросов (быстрее, чем полный download — нам нужен
/// только статус + Content-Length).
///
/// HEAD на 1 MB MP3 — это 1 сетевой round-trip; для 2 источников
/// в худшем случае — 2 round-trip'а. После того как [resolve]
/// вернёт рабочий `source` и `url`, [AudioCache.getOrDownload]
/// вызовет `dio.download` (уже с найденным URL).
class AudioSourceResolver {
  AudioSourceResolver({
    required this.dio,
    required this.chain,
  });

  final Dio dio;
  final AudioSourceChain chain;

  /// Перебирает источники в порядке [chain.sources]. Первый
  /// успешный HEAD (HTTP 200/206 с непустым `Content-Length`)
  /// выигрывает. Бросает [AllSourcesFailed], если все провалились.
  Future<({AudioSource source, String url})> resolve({
    required String reciterId,
    required int surahId,
  }) async {
    final attempts = <SourceAttempt>[];
    for (var i = 0; i < chain.sources.length; i++) {
      final source = chain.sources[i];
      final url = chain.urlAt(i, surahId);
      try {
        final size = await _probeSize(url);
        if (size != null && size > 0) {
          return (source: source, url: url);
        }
        attempts.add(SourceAttempt.failed(
          source: source,
          error: 'HEAD returned non-2xx or empty body',
        ));
      } catch (e) {
        attempts.add(SourceAttempt.failed(source: source, error: e));
      }
    }
    throw AllSourcesFailed(attempts, reciterId, surahId);
  }

  /// HEAD-запрос с таймаутом. Возвращает `Content-Length` если
  /// сервер ответил 2xx с непустым размером; `null` иначе.
  ///
  /// Некоторые CDN отвечают 405 на HEAD; в таком случае
  /// пробуем GET с `Range: bytes=0-0` (читаем 1 байт).
  Future<int?> _probeSize(String url) async {
    try {
      final resp = await dio.head<dynamic>(
        url,
        options: Options(
          // `ResponseType.stream` — критично: для пустого HEAD-ответа
          // `FusedTransformer.transformResponse` иначе выкидывает
          // `DioExceptionType.unknown` (см. dio#1512). Нам не нужен
          // body — только headers и status.
          responseType: ResponseType.stream,
          // Не бросаем на 4xx/5xx — обрабатываем fallback сами.
          validateStatus: (s) => s != null && s < 600,
          sendTimeout: chain.perSourceTimeout,
          receiveTimeout: chain.perSourceTimeout,
        ),
      );
      final code = resp.statusCode ?? 0;
      if (code == 405 || code == 403) {
        return _getSizeViaRange(url);
      }
      if (code >= 200 && code < 300) {
        return _contentLength(resp);
      }
      return null;
    } on DioException catch (_) {
      // Любая Dio-ошибка (network, timeout, transform) — трактуем
      // как failure этого источника; переходим к следующему.
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _getSizeViaRange(String url) async {
    try {
      final resp = await dio.get<dynamic>(
        url,
        options: Options(
          // `Range: bytes=0-0` — читаем 1 байт вместо всего MP3.
          // Этого достаточно чтобы убедиться, что URL рабочий
          // (200 или 206 Partial Content) и достать `Content-Range`
          // для общего размера файла.
          headers: {'Range': 'bytes=0-0'},
          // `stream` вместо `plain` — обход Dio 5.9 bug c пустым
          // body в transformer'е.
          responseType: ResponseType.stream,
          validateStatus: (s) => s != null && s < 400,
          sendTimeout: chain.perSourceTimeout,
          receiveTimeout: chain.perSourceTimeout,
        ),
      );
      final code = resp.statusCode ?? 0;
      if (code != 200 && code != 206) return null;
      // `Content-Range: bytes 0-0/1234567` — последнее число это total size.
      final range = resp.headers.value('content-range') ??
          resp.headers.value('Content-Range');
      if (range != null) {
        final m = RegExp(r'/(\d+)$').firstMatch(range);
        if (m != null) return int.tryParse(m.group(1)!);
      }
      // Fallback: `Content-Length` самой range-выдачи (1 байт).
      return _contentLength(resp);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  int? _contentLength(Response<dynamic> resp) {
    // `dio` парсит `Content-Length` в `headers` либо как
    // `content-length` (lower-case) либо `Content-Length` —
    // зависит от платформы. Берём case-insensitive.
    final headers = resp.headers;
    for (final name in ['content-length', 'Content-Length']) {
      final v = headers.value(name);
      if (v != null) {
        return int.tryParse(v);
      }
    }
    return null;
  }
}

/// Default source chain (2 источника, как в §12 ARCHITECTURE).
/// Override через `audioSourceChainProvider`, если хочется
/// кастомный набор (например, для тестов).
AudioSourceChain defaultAudioSourceChain() {
  return AudioSourceChain(sources: const [
    AudioSource(
      id: 'primary',
      name: 'Islamic.network',
      urlTemplate: 'https://cdn.islamic.network/quran/audio-surah/{surah}.mp3',
    ),
    AudioSource(
      id: 'backup',
      name: 'EveryAyah.com',
      urlTemplate: 'https://everyayah.com/data/{surah}.mp3',
    ),
  ]);
}
