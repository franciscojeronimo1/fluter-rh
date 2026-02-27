import 'dart:convert';

import 'package:fluter_rh/core/api_client.dart';
import 'package:fluter_rh/models/category.dart';

class CategoryService {
  CategoryService({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /categories
  Future<List<Category>> list(String token) async {
    final res = await _client.get('/categories', token: token);
    if (res.statusCode != 200) {
      throw Exception('Erro ao listar categorias');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['categories'] as List<dynamic>? ?? [];
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /categories
  Future<Category> create(String token, {required String name}) async {
    final res = await _client.post(
      '/categories',
      body: {'name': name},
      token: token,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Erro ao criar categoria');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Category.fromJson(data['category'] as Map<String, dynamic>);
  }

  /// PUT /categories/:id
  Future<Category> update(String token, String id, {required String name}) async {
    final res = await _client.put(
      '/categories/$id',
      body: {'name': name},
      token: token,
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Erro ao atualizar categoria');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Category.fromJson(data['category'] as Map<String, dynamic>);
  }

  /// DELETE /categories/:id
  Future<void> delete(String token, String id) async {
    final res = await _client.delete('/categories/$id', token: token);
    if (res.statusCode != 200 && res.statusCode != 204) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Erro ao excluir categoria');
    }
  }
}
