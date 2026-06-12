import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:quran_app/features/audio/data/audio_source_chain.dart';

/// Unit tests for the AudioSourceResolver / AudioSourceChain (§12
/// ARCHITECTURE). These run via plain `dart test` (no flutter_tester)
/// and lock in the fallback-chain behavior.
///
/// We replace `Dio.httpClientAdapter` with a deterministic in-memory
/// fake — no real network, no flakiness. The fake records the requests
/// it sees, so tests can assert on call counts and URLs.
void main() {
  group('AudioSource.resolveUrl', () {
    test('replaces {surah} with zero-padded 3-digit number', () {
      const src = AudioSource(
        id: 'p',
        name: 'P',
        urlTemplate: 'https://cdn.example.com/{surah}.mp3',
      );
      expect(src.resolveUrl(1), 'https://cdn.example.com/001.mp3');
      expect(src.resolveUrl(114), 'https://cdn.example.com/114.mp3');
      expect(src.resolveUrl(7), 'https://cdn.example.com/007.mp3');
    });

    test('no placeholder → URL returned unchanged', () {
      const src = AudioSource(
        id: 'p',
        name: 'P',
        urlTemplate: 'https://static.example.com/reciter/audio.mp3',
      );
      expect(src.resolveUrl(1), 'https://static.example.com/reciter/audio.mp3');
      expect(src.resolveUrl(114), 'https://static.example.com/reciter/audio.mp3');
    });

    test('replaces ALL occurrences of {surah}', () {
      const src = AudioSource(
        id: 'p',
        name: 'P',
        urlTemplate: 'https://cdn/{surah}/quran/{surah}.mp3',
      );
      expect(src.resolveUrl(5), 'https://cdn/005/quran/005.mp3');
    });
  });

  group('AudioSourceChain', () {
    test('asserts at least one source', () {
      expect(
        () => AudioSourceChain(sources: const []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('urlAt throws RangeError for out-of-bounds index', () {
      final chain = defaultAudioSourceChain();
      expect(() => chain.urlAt(99, 1), throwsA(isA<RangeError>()));
    });

    test('default chain has 2 sources (primary + backup)', () {
      final chain = defaultAudioSourceChain();
      expect(chain.sources.length, 2);
      expect(chain.sources[0].id, 'primary');
      expect(chain.sources[1].id, 'backup');
    });

    test('urlAt(0, 1) → first source URL with surah=001', () {
      final chain = defaultAudioSourceChain();
      final url = chain.urlAt(0, 1);
      expect(url, contains('001'));
      expect(url, startsWith('https://'));
    });
  });

  group('AudioSourceResolver.resolve', () {
    late List<RequestOptions> requests;

    /// Build a Dio with a fake adapter that:
    /// - records each request (URL, method)
    /// - returns a stub response based on the URL substring
    Dio buildDio({
      required Map<String, _Stub> stubs,
      Duration delay = Duration.zero,
    }) {
      requests = [];
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 1),
          receiveTimeout: const Duration(seconds: 1),
        ),
      );
      dio.httpClientAdapter = _FakeAdapter(
        onRequest: (opts) {
          requests.add(opts);
        },
        stubs: stubs,
        delay: delay,
      );
      return dio;
    }

    test('first source 200 → returns it without probing second', () async {
      final dio = buildDio(stubs: {
        'islamic.network': _Stub(
          statusCode: 200,
          headers: {'content-length': ['1024']},
        ),
      });
      final resolver = AudioSourceResolver(
        dio: dio,
        chain: defaultAudioSourceChain(),
      );
      final r = await resolver.resolve(reciterId: 'ar.alafasy', surahId: 1);
      expect(r.source.id, 'primary');
      expect(r.url, contains('islamic.network'));
      // Only the first source was probed.
      expect(requests.length, 1);
    });

    test('first 404 → falls back to second (200)', () async {
      final dio = buildDio(stubs: {
        'islamic.network': _Stub(statusCode: 404),
        'everyayah.com': _Stub(
          statusCode: 200,
          headers: {'content-length': ['2048']},
        ),
      });
      final resolver = AudioSourceResolver(
        dio: dio,
        chain: defaultAudioSourceChain(),
      );
      final r = await resolver.resolve(reciterId: 'ar.alafasy', surahId: 5);
      expect(r.source.id, 'backup');
      expect(requests.length, 2);
    });

    test('first 405 → tries Range GET on same source, then 200', () async {
      final dio = buildDio(stubs: {
        'islamic.network': _Stub(
          statusCode: 405,
          // The Range GET should succeed; 206 Partial Content with
          // Content-Range header indicates a real working source.
          followUpStatusCode: 206,
          followUpHeaders: {'content-range': ['bytes 0-0/4096']},
        ),
      });
      final resolver = AudioSourceResolver(
        dio: dio,
        chain: defaultAudioSourceChain(),
      );
      final r = await resolver.resolve(reciterId: 'ar.alafasy', surahId: 1);
      expect(r.source.id, 'primary');
      // HEAD (405) + GET with Range (206) = 2 requests on same source
      expect(requests.length, 2);
    });

    test('all sources fail → throws AllSourcesFailed with attempts', () async {
      final dio = buildDio(stubs: {
        'islamic.network': _Stub(statusCode: 500),
        'everyayah.com': _Stub(statusCode: 404),
      });
      final resolver = AudioSourceResolver(
        dio: dio,
        chain: defaultAudioSourceChain(),
      );
      try {
        await resolver.resolve(reciterId: 'ar.alafasy', surahId: 1);
        fail('expected AllSourcesFailed');
      } on AllSourcesFailed catch (e) {
        expect(e.attempts.length, 2);
        expect(e.reciterId, 'ar.alafasy');
        expect(e.surahId, 1);
      }
    });

    test('first source throws (network) → falls back to second', () async {
      final dio = buildDio(stubs: {
        'islamic.network': _Stub(
          statusCode: 0,
          throwNetworkError: true,
        ),
        'everyayah.com': _Stub(
          statusCode: 200,
          headers: {'content-length': ['512']},
        ),
      });
      final resolver = AudioSourceResolver(
        dio: dio,
        chain: defaultAudioSourceChain(),
      );
      final r = await resolver.resolve(reciterId: 'ar.alafasy', surahId: 1);
      expect(r.source.id, 'backup');
      expect(requests.length, 2);
    });

    test('200 with empty Content-Length is treated as failure', () async {
      // Some servers return 200 without Content-Length (chunked
      // transfer). Resolver should treat that as ambiguous and try
      // the next source.
      final dio = buildDio(stubs: {
        'islamic.network': _Stub(
          statusCode: 200,
          headers: {}, // no content-length
        ),
        'everyayah.com': _Stub(
          statusCode: 200,
          headers: {'content-length': ['256']},
        ),
      });
      final resolver = AudioSourceResolver(
        dio: dio,
        chain: defaultAudioSourceChain(),
      );
      final r = await resolver.resolve(reciterId: 'ar.alafasy', surahId: 1);
      expect(r.source.id, 'backup');
    });
  });

  group('AllSourcesFailed.primaryError', () {
    test('prefers 404 message when present', () {
      final attempts = [
        SourceAttempt.failed(
          source: const AudioSource(
            id: 'a',
            name: 'A',
            urlTemplate: 'x',
          ),
          error: DioException(
            requestOptions: RequestOptions(path: 'x'),
            response: Response(
              requestOptions: RequestOptions(path: 'x'),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
        SourceAttempt.failed(
          source: const AudioSource(
            id: 'b',
            name: 'B',
            urlTemplate: 'y',
          ),
          error: DioException(
            requestOptions: RequestOptions(path: 'y'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      ];
      final e = AllSourcesFailed(attempts, 'r1', 1);
      expect(e.primaryError, '404 not found on A');
    });

    test('falls back to timeout message when no 404', () {
      final attempts = [
        SourceAttempt.failed(
          source: const AudioSource(
            id: 'a',
            name: 'A',
            urlTemplate: 'x',
          ),
          error: DioException(
            requestOptions: RequestOptions(path: 'x'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        SourceAttempt.failed(
          source: const AudioSource(
            id: 'b',
            name: 'B',
            urlTemplate: 'y',
          ),
          error: DioException(
            requestOptions: RequestOptions(path: 'y'),
            response: Response(
              requestOptions: RequestOptions(path: 'y'),
              statusCode: 503,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ];
      final e = AllSourcesFailed(attempts, 'r1', 1);
      expect(e.primaryError, 'A: timeout');
    });

    test('falls back to 5xx when no 404/timeout', () {
      final attempts = [
        SourceAttempt.failed(
          source: const AudioSource(
            id: 'a',
            name: 'A',
            urlTemplate: 'x',
          ),
          error: DioException(
            requestOptions: RequestOptions(path: 'x'),
            response: Response(
              requestOptions: RequestOptions(path: 'x'),
              statusCode: 502,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ];
      final e = AllSourcesFailed(attempts, 'r1', 1);
      expect(e.primaryError, '502 server error on A');
    });

    test('toString() includes reciter/surah/attempts count', () {
      final e = AllSourcesFailed(const [], 'ar.alafasy', 42);
      expect(
        e.toString(),
        'AllSourcesFailed(reciter=ar.alafasy, surah=42, attempts=0)',
      );
    });
  });
}

/// Stub describing how the fake adapter should respond for URLs
/// matching a given substring.
class _Stub {
  _Stub({
    this.statusCode = 404,
    this.headers = const {},
    this.followUpStatusCode,
    this.followUpHeaders = const {},
    this.throwNetworkError = false,
  });

  /// Response code for the first request (typically HEAD).
  final int statusCode;
  final Map<String, List<String>> headers;

  /// If the first request returns 405/403, a follow-up Range GET
  /// is made; these fields describe its response.
  final int? followUpStatusCode;
  final Map<String, List<String>> followUpHeaders;

  /// If true, throw a DioException(network error) instead of
  /// returning a response.
  final bool throwNetworkError;
}

/// In-memory `HttpClientAdapter` that returns stubbed responses
/// based on URL substrings. No real network IO.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({
    required this.onRequest,
    required this.stubs,
    this.delay = Duration.zero,
  });

  final void Function(RequestOptions options) onRequest;
  final Map<String, _Stub> stubs;
  final Duration delay;

  /// Tracks which keys have been "consumed" — once a stub fires,
  /// subsequent requests to the same substring will reuse the
  /// follow-up response (for HEAD→GET Range flow).
  final Map<String, bool> _used = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final uri = options.uri.toString();
    for (final entry in stubs.entries) {
      if (uri.contains(entry.key)) {
        final stub = entry.value;
        if (stub.throwNetworkError) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'simulated network error',
          );
        }
        final isFirst = !(_used[entry.key] ?? false);
        _used[entry.key] = true;
        if (isFirst) {
          return _buildBody(stub.statusCode, stub.headers);
        }
        // Follow-up for HEAD→Range GET
        return _buildBody(
          stub.followUpStatusCode ?? stub.statusCode,
          stub.followUpHeaders.isNotEmpty
              ? stub.followUpHeaders
              : stub.headers,
        );
      }
    }
    // No stub matched — return 404
    return _buildBody(404, const {});
  }

  ResponseBody _buildBody(int status, Map<String, List<String>> headers) {
    return ResponseBody.fromString(
      '',
      status,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}
