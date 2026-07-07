import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'doh_resolver.dart';

/// `HttpClientAdapter` для Dio, который при включённом
/// [DohResolver] перехватывает исходящий запрос и подменяет
/// hostname на IP-адрес, полученный через DNS-over-HTTPS.
///
/// Использование:
/// ```dart
/// final dio = Dio();
/// if (useCustomDns) {
///   dio.httpClientAdapter = DnsAwareAdapter(
///     inner: IOHttpClientAdapter(),
///     resolver: DohResolver(dio: Dio(), endpoint: '...'),
///   );
/// }
/// ```
///
/// Почему `HttpClientAdapter`, а не `Interceptor`:
/// `RequestOptions.uri` в Dio 5.x — getter, и `Interceptor.onRequest`
/// позволяет патчить только `path` напрямую (это String,
/// безопасный к мутации), но нельзя ставить `Host:` заголовок
/// до формирования TCP-соединения адаптером. Здесь же мы
/// проксируем в `inner.fetch(...)` с подменой `path` + заголовков.
class DnsAwareAdapter implements HttpClientAdapter {
  DnsAwareAdapter({required this.inner, required this.resolver});

  final HttpClientAdapter inner;
  final DohResolver resolver;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;

    if (uri.host.isEmpty ||
        uri.scheme != 'https' ||
        _isIpLiteral(uri.host)) {
      return inner.fetch(options, requestStream, cancelFuture);
    }

    final ip = await resolver.resolve(uri.host);
    if (ip == null) {
      // DNS bypass не сработал — fallback на обычный системный DNS.
      return inner.fetch(options, requestStream, cancelFuture);
    }

    // Подменяем `options.path` на полный URL с IP-формой.
    // Поле `path: String` в Dio 5.x — mutable setter, и
    // `IOHttpClientAdapter` использует именно его для HTTP.
    final ipUri = Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: ip.address,
      port: uri.hasPort ? uri.port : 443,
      path: uri.path,
      query: uri.query.isEmpty ? null : uri.query,
    );
    options.path = ipUri.toString();

    // Добавляем оригинальный Host: в headers — `IOHttpClientAdapter`
    // использует его для TLS-SNI и Host header.
    options.headers['Host'] = uri.host;
    return inner.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    inner.close(force: force);
  }

  static bool _isIpLiteral(String host) {
    final parts = host.split('.');
    if (parts.length == 4) {
      return parts.every((p) {
        final v = int.tryParse(p);
        return v != null && v >= 0 && v <= 255;
      });
    }
    return InternetAddress.tryParse(host) != null;
  }
}
