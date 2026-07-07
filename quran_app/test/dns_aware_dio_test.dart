import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/networking/dns_aware_dio.dart';
import 'package:quran_app/core/networking/doh_resolver.dart';

/// Тесты для `DnsAwareAdapter`: убеждаемся, что DoH-bypass
/// правильно подменяет `options.path` на IP-форму и добавляет
/// заголовок `Host:` с оригинальным именем хоста.
void main() {
  group('DnsAwareAdapter.fetch', () {
    test('DoH resolves host → inner sees IP in path + Host header',
        () async {
      final inner = _RecordingAdapter();
      final adapter = DnsAwareAdapter(
        inner: inner,
        resolver: _StubResolver(
          map: {'cdn.example.com': InternetAddress('1.2.3.4')},
        ),
      );

      final opts = RequestOptions(path: 'https://cdn.example.com/audio.mp3');
      await adapter.fetch(opts, null, null);

      expect(inner.captured, isNotNull);
      // `path` подменён на IP-форму.
      expect(opts.path, contains('1.2.3.4'));
      expect(opts.path, isNot(contains('cdn.example.com')));
      // Host header проставлен оригинальным именем.
      expect(opts.headers['Host'], 'cdn.example.com');
    });

    test('DoH returns null → adapter forwards unchanged (system-DNS fallback)',
        () async {
      final inner = _RecordingAdapter();
      final adapter = DnsAwareAdapter(
        inner: inner,
        resolver: _StubResolver(map: const {}),
      );

      final opts = RequestOptions(path: 'https://hijacked.example/audio.mp3');
      await adapter.fetch(opts, null, null);

      expect(opts.path, contains('hijacked.example'));
      expect(opts.headers.containsKey('Host'), isFalse,
          reason: 'no Host override when DoH недоступен');
    });

    test('IP-literal URL → bypassed (no DoH call)', () async {
      final inner = _RecordingAdapter();
      final resolver = _StubResolver(map: const {}); // would 404 if called
      final adapter = DnsAwareAdapter(
        inner: inner,
        resolver: resolver,
      );

      final opts = RequestOptions(path: 'https://8.8.8.8/audio.mp3');
      await adapter.fetch(opts, null, null);

      expect(opts.path, contains('8.8.8.8'));
      expect(resolver.callCount, 0,
          reason: 'DoH не должен вызываться для IP-литералов');
    });

    test('Non-https scheme (http://) → bypassed', () async {
      final inner = _RecordingAdapter();
      final resolver = _StubResolver(map: const {});
      final adapter = DnsAwareAdapter(
        inner: inner,
        resolver: resolver,
      );

      final opts = RequestOptions(path: 'http://plain.example/audio.mp3');
      await adapter.fetch(opts, null, null);

      expect(opts.path, contains('plain.example'));
      expect(resolver.callCount, 0);
    });
  });
}

class _StubResolver implements DohResolver {
  _StubResolver({required this.map});

  final Map<String, InternetAddress> map;
  int callCount = 0;

  @override
  Dio get dio => throw UnsupportedError('not used in stub');
  @override
  String get endpoint => 'https://stub.doh';
  @override
  Duration get timeout => Duration.zero;

  @override
  Future<InternetAddress?> resolve(String host) async {
    callCount++;
    return map[host];
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString('OK', 200);
  }

  @override
  void close({bool force = false}) {}
}
