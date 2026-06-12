import 'dart:convert';

import 'package:http/http.dart' as http;

/// خطأ في طلب الشبكة.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// عميل HTTP خفيف جاهز لاستخدامه من مصادر البيانات البعيدة.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// طلب GET يعيد جسم الاستجابة بعد فك ترميز JSON.
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: queryParameters);
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'فشل الطلب: ${response.reasonPhrase ?? response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void dispose() => _client.close();
}
