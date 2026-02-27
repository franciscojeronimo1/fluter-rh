import 'dart:convert';

import 'package:fluter_rh/core/api_client.dart';
import 'package:fluter_rh/models/product.dart';

class ProductService {
  ProductService({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  String _buildQuery({
    String? category,
    bool? includeInactive,
    int? page,
    int? limit,
  }) {
    final params = <String>[];
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    if (includeInactive == true) {
      params.add('includeInactive=true');
    }
    if (page != null) params.add('page=$page');
    if (limit != null) params.add('limit=$limit');
    return params.isEmpty ? '' : '?${params.join('&')}';
  }

  /// GET /products
  Future<ProductsResponse> list(
    String token, {
    String? category,
    bool includeInactive = false,
    int page = 1,
    int limit = 20,
  }) async {
    final query = _buildQuery(
      category: category,
      includeInactive: includeInactive,
      page: page,
      limit: limit,
    );
    final res = await _client.get('/products$query', token: token);
    if (res.statusCode != 200) {
      throw Exception('Erro ao listar produtos');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return ProductsResponse.fromJson(data);
  }

  /// GET /products/:id
  Future<Product> getById(String token, String id) async {
    final res = await _client.get('/products/$id', token: token);
    if (res.statusCode != 200) {
      throw Exception('Produto não encontrado');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  /// POST /products
  Future<Product> create(
    String token, {
    required String name,
    String? code,
    String? sku,
    String? category,
    int minStock = 0,
    String unit = 'UN',
    double? costPrice,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'minStock': minStock,
      'unit': unit,
    };
    if (code != null && code.isNotEmpty) body['code'] = code;
    if (sku != null && sku.isNotEmpty) body['sku'] = sku;
    if (category != null && category.isNotEmpty) body['category'] = category;
    if (costPrice != null && costPrice >= 0) body['costPrice'] = costPrice;

    final res = await _client.post('/products', body: body, token: token);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Erro ao criar produto');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  /// PUT /products/:id
  Future<Product> update(
    String token,
    String id, {
    String? name,
    String? code,
    String? sku,
    String? category,
    int? minStock,
    String? unit,
    double? costPrice,
    bool? active,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (code != null) body['code'] = code;
    if (sku != null) body['sku'] = sku;
    if (category != null) body['category'] = category;
    if (minStock != null) body['minStock'] = minStock;
    if (unit != null) body['unit'] = unit;
    if (costPrice != null) body['costPrice'] = costPrice;
    if (active != null) body['active'] = active;

    final res = await _client.put('/products/$id', body: body, token: token);
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Erro ao atualizar produto');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  /// DELETE /products/:id (soft delete - marca como inativo)
  Future<void> delete(String token, String id) async {
    final res = await _client.delete('/products/$id', token: token);
    if (res.statusCode != 200 && res.statusCode != 204) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Erro ao excluir produto');
    }
  }
}
