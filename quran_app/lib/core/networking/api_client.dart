import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 30),
                responseType: ResponseType.json,
              ),
            );

  final Dio _dio;

  Dio get raw => _dio;

  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(url, queryParameters: query);
    final data = res.data;
    if (data == null) {
      throw const ApiException('Empty response');
    }
    if (data['code'] == 200 && data['data'] != null) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw ApiException('Unexpected payload: $data');
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => 'ApiException: $message';
}
