import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Cliente HTTP para comunicação com o backend.
/// Requisições autenticadas usam o header Authorization: Bearer {token}.
class ApiClient {
  ApiClient({this.baseUrl = kBaseUrl});

  final String baseUrl;

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
    final uri = Uri.parse('$baseUrl$path');
    final headers = token != null ? headersWithAuth(token) : _jsonHeaders;
    return http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> get(String path, {String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = token != null ? headersWithAuth(token) : _jsonHeaders;
    return http.get(uri, headers: headers);
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return http.put(
      uri,
      headers: headersWithAuth(token),
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
