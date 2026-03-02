import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exceptions.dart';

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

  void _checkSubscriptionRequired(http.Response res) {
    if (res.statusCode == 403) {
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        if (body?['code'] == 'SUBSCRIPTION_REQUIRED') {
          throw SubscriptionRequiredException();
        }
      } catch (e) {
        if (e is SubscriptionRequiredException) rethrow;
      }
    }
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse(_buildUri(path));
    final headers = token != null ? headersWithAuth(token) : _jsonHeaders;
    // POST sem body: envia '{}' — evita 500 em backends que esperam JSON parseável
    final bodyStr = body != null ? jsonEncode(body) : '{}';
    final res = await http.post(uri, headers: headers, body: bodyStr);
    _checkSubscriptionRequired(res);
    return res;
  }

  Future<http.Response> get(String path, {String? token}) async {
    final uri = Uri.parse(_buildUri(path));
    final headers = token != null ? headersWithAuth(token) : _jsonHeaders;
    final res = await http.get(uri, headers: headers);
    _checkSubscriptionRequired(res);
    return res;
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    required String token,
  }) async {
    final uri = Uri.parse(_buildUri(path));
    final res = await http.put(
      uri,
      headers: headersWithAuth(token),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkSubscriptionRequired(res);
    return res;
  }

  Future<http.Response> delete(String path, {required String token}) async {
    final uri = Uri.parse(_buildUri(path));
    final res = await http.delete(uri, headers: headersWithAuth(token));
    _checkSubscriptionRequired(res);
    return res;
  }
}
