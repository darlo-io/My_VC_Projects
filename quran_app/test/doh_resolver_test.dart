import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/networking/doh_resolver.dart';

/// Детерминированные тесты для [DohResolver].
/// Не требуют сети: заменяем `Dio.httpClientAdapter` на [_FakeAdapter].
void main() {
  group('DohResolver.resolve', () {
    test('Cloudflare-style JSON → InternetAddress', () async {
      final fake = _FakeAdapter(
        // Cloudflare returns {"Status":0,"Answer":[{"data":"1.2.3.4"}]}.
        responseBody: jsonEncode({
          'Status': 0,
          'Answer': [
            {'name': 'cdn.example.com.', 'data': '1.2.3.4'},
          ],
        }),
      );
      final dio = Dio()..httpClientAdapter = fake;
      final resolver = DohResolver(
        dio: dio,
        endpoint: 'https://1.1.1.1/dns-query',
      );

      final ip = await resolver.resolve('cdn.example.com');
      expect(ip, isNotNull);
      expect(ip!.address, '1.2.3.4');
      expect(fake.lastPath, contains('name=cdn.example.com'));
      expect(fake.lastPath, contains('type=A'));
    });

    test('Google-style JSON (data with newline) → first line (IP only)',
        () async {
      final fake = _FakeAdapter(
        responseBody: jsonEncode({
          'Status': 0,
          'Answer': [
            {
              'name': 'google.com.',
              'data': '142.250.190.46\nA\n3600',
              'TTL': 3600,
            },
          ],
        }),
      );
      final dio = Dio()..httpClientAdapter = fake;
      final resolver = DohResolver(
        dio: dio,
        endpoint: 'https://dns.google/resolve',
      );

      final ip = await resolver.resolve('google.com');
      expect(ip, isNotNull);
      expect(ip!.address, '142.250.190.46');
    });

    test('empty Answer → null', () async {
      final fake = _FakeAdapter(
        responseBody: jsonEncode({'Status': 0, 'Answer': const <dynamic>[]}),
      );
      final dio = Dio()..httpClientAdapter = fake;
      final resolver = DohResolver(
        dio: dio,
        endpoint: 'https://1.1.1.1/dns-query',
      );

      final ip = await resolver.resolve('nxdomain.example');
      expect(ip, isNull);
    });

    test('5xx HTTP → null (no exception leaked)', () async {
      final fake = _FakeAdapter(
        statusCode: 503,
        responseBody: '',
      );
      final dio = Dio()..httpClientAdapter = fake;
      final resolver = DohResolver(
        dio: dio,
        endpoint: 'https://1.1.1.1/dns-query',
      );

      final ip = await resolver.resolve('blocked.example');
      expect(ip, isNull);
    });

    test('malformed JSON → null (graceful fallback)', () async {
      final fake = _FakeAdapter(
        statusCode: 200,
        responseBody: '{not json',
      );
      final dio = Dio()..httpClientAdapter = fake;
      final resolver = DohResolver(
        dio: dio,
        endpoint: 'https://1.1.1.1/dns-query',
      );

      final ip = await resolver.resolve('bad.example');
      expect(ip, isNull);
    });

    test('timeouts propagate as null (resolver.connectionTimeout)', () async {
      final fake = _FakeAdapter(
        delay: const Duration(milliseconds: 200),
        responseBody: jsonEncode({
          'Status': 0,
          'Answer': [
            {'name': 'slow.example.', 'data': '8.8.8.8'},
          ],
        }),
      );
      final dio = Dio()..httpClientAdapter = fake;
      final resolver = DohResolver(
        dio: dio,
        endpoint: 'https://1.1.1.1/dns-query',
        timeout: const Duration(milliseconds: 50),
      );

      final ip = await resolver.resolve('slow.example');
      expect(ip, isNull, reason: 'timeout should produce null, not exception');
    });
  });
}

/// Records requests, returns canned response. Used by all DoH tests.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({
    this.statusCode = 200,
    required this.responseBody,
    this.delay = Duration.zero,
  });

  final int statusCode;
  final String responseBody;
  final Duration delay;
  String? lastPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {'Content-Type': ['application/dns-json']},
    );
  }

  @override
  void close({bool force = false}) {}
}
