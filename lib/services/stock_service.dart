import 'dart:convert';

import 'package:fluter_rh/core/api_client.dart';
import 'package:fluter_rh/models/stock.dart';

class StockService {
  StockService({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /stock/total-value — pode não existir em todos os backends
  Future<TotalValueResponse?> getTotalValue(String token) async {
    try {
      final res = await _client.get('/stock/total-value', token: token);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return TotalValueResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// GET /stock/low-stock
  Future<LowStockResponse?> getLowStock(String token, {int page = 1, int limit = 20}) async {
    final res = await _client.get(
      '/stock/low-stock?page=$page&limit=$limit',
      token: token,
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return LowStockResponse.fromJson(data);
  }

  /// GET /stock/current — para contagem total de produtos
  Future<CurrentStockResponse?> getCurrentStock(
    String token, {
    String? category,
    int page = 1,
    int limit = 100,
  }) async {
    var path = '/stock/current?page=$page&limit=$limit';
    if (category != null && category.isNotEmpty) {
      path += '&category=$category';
    }
    final res = await _client.get(path, token: token);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return CurrentStockResponse.fromJson(data);
  }

  /// GET /stock/daily-usage?date=YYYY-MM-DD — pode não existir em todos os backends
  Future<DailyUsageResponse?> getDailyUsage(String token, String date) async {
    try {
      final res = await _client.get('/stock/daily-usage?date=$date', token: token);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return DailyUsageResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
