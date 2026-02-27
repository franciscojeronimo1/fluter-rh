import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Cliente HTTP para comunicação com o backend.
/// Requisições autenticadas usam o header Authorization: Bearer {token}.
class ApiClient {
  ApiClient({
    this.baseUrl = kBaseUrl,
    this.basePath = kBasePath,
  });

  final String baseUrl;
  final String basePath;

  String _buildUri(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final pathNorm = path.startsWith('/') ? path : '/$path';
    final pathBase = basePath.isEmpty ? '' : (basePath.startsWith('/') ? basePath : '/$basePath');
    return '$base$pathBase$pathNorm';
  }

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> headersWithAuth(String token) => {
        ..._jsonHeaders,
        'Authorization': 'Bearer $token',
      };

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse(_buildUri(path));
    final headers = token != null ? headersWithAuth(token) : _jsonHeaders;
    // POST sem body: envia '{}' — evita 500 em backends que esperam JSON parseável
    final bodyStr = body != null ? jsonEncode(body) : '{}';
    return http.post(uri, headers: headers, body: bodyStr);
  }

  Future<http.Response> get(String path, {String? token}) async {
    final uri = Uri.parse(_buildUri(path));
    final headers = token != null ? headersWithAuth(token) : _jsonHeaders;
    return http.get(uri, headers: headers);
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    required String token,
  }) async {
    final uri = Uri.parse(_buildUri(path));
    return http.put(
      uri,
      headers: headersWithAuth(token),
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
