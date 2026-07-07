import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';

/// DNS-over-HTTPS resolver — обход captive portals и подменённого
/// системного DNS. Работает по Cloudflare-style JSON API
/// (`GET <url>?name=<host>&type=A`). Поддерживает любые публичные
/// DoH-провайдеры.
///
/// Использование:
///   final resolver = DohResolver(dio: Dio(), endpoint: 'https://1.1.1.1/dns-query');
///   final addr = await resolver.resolve('cdn.islamic.network');
///
/// См. master-plan §4.2 и hotfix round 4 (`audio source unavailable`
/// из-за `gateway.alparslan.bahriya.net` captive-bastion).
class DohResolver {
  DohResolver({required this.dio, required this.endpoint, this.timeout = const Duration(seconds: 5)});

  final Dio dio;
  final String endpoint;
  final Duration timeout;

  /// Резолвит `host` (IPv4 `A`-запись). Возвращает `InternetAddress`
  /// при успехе; `null` если DoH не ответил или вернул пустой `Answer`.
  ///
  /// Поддерживает JSON ответ в двух форматах:
  ///   1. Cloudflare: `{"Status": 0, "Answer": [{"data": "1.2.3.4"}]}`.
  ///   2. Google:     `{"Status": 0, "Answer": [{"data": "1.2.3.4\nA\n..."}]}`.
  Future<InternetAddress?> resolve(String host) async {
    try {
      // Заменяем любой query string в endpoint, добавляем `name` и `type`.
      final base =
          endpoint.contains('?') ? endpoint.substring(0, endpoint.indexOf('?')) : endpoint;
      final urlWithQuery = '$base?name=${Uri.encodeComponent(host)}&type=A';
      final resp = await dio.get<dynamic>(
        urlWithQuery,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: timeout,
          receiveTimeout: timeout,
          headers: {'Accept': 'application/dns-json'},
          // Не валидируем на 4xx — обрабатываем ниже.
          validateStatus: (s) => s != null && s < 600,
        ),
      );
      final statusCode = resp.statusCode ?? 0;
      if (statusCode >= 400) return null;
      final body = resp.data;
      Map<String, dynamic> json;
      if (body is Map) {
        json = body.cast<String, dynamic>();
      } else if (body is String && body.isNotEmpty) {
        json = jsonDecode(body) as Map<String, dynamic>;
      } else {
        return null;
      }
      final answer = json['Answer'];
      if (answer is! List || answer.isEmpty) return null;
      for (final entry in answer) {
        if (entry is! Map) continue;
        final data = entry['data'];
        if (data is! String) continue;
        // Google-формат: "1.2.3.4\nA\n..." — берём только IP.
        final ip = data.split('\n').first.trim();
        final parsed = InternetAddress.tryParse(ip);
        if (parsed != null && parsed.type == InternetAddressType.IPv4) {
          return parsed;
        }
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }
}
