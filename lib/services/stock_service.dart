import 'dart:convert';

import 'package:fluter_rh/core/api_client.dart';
import 'package:fluter_rh/core/api_exceptions.dart';
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
    } catch (e) {
      if (e is SubscriptionRequiredException) rethrow;
      return null;
    }
  }

  /// GET /stock/low-stock
  Future<LowStockResponse?> getLowStock(String token, {int page = 1, int limit = 20}) async {
    try {
      final res = await _client.get(
        '/stock/low-stock?page=$page&limit=$limit',
        token: token,
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return LowStockResponse.fromJson(data);
    } catch (e) {
      if (e is SubscriptionRequiredException) rethrow;
      return null;
    }
  }

  /// GET /stock/current — para contagem total de produtos
  Future<CurrentStockResponse?> getCurrentStock(
    String token, {
    String? category,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      var path = '/stock/current?page=$page&limit=$limit';
      if (category != null && category.isNotEmpty) {
        path += '&category=$category';
      }
      final res = await _client.get(path, token: token);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CurrentStockResponse.fromJson(data);
    } catch (e) {
      if (e is SubscriptionRequiredException) rethrow;
      return null;
    }
  }

  /// GET /stock/daily-usage?date=YYYY-MM-DD — pode não existir em todos os backends
  Future<DailyUsageResponse?> getDailyUsage(String token, String date) async {
    try {
      final res = await _client.get('/stock/daily-usage?date=$date', token: token);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return DailyUsageResponse.fromJson(data);
    } catch (e) {
      if (e is SubscriptionRequiredException) rethrow;
      return null;
    }
  }

  /// POST /stock/entries — registrar entrada (compra/recebimento)
  Future<void> createEntry(
    String token, {
    required String productId,
    required int quantity,
    required double unitPrice,
    String? supplierName,
    String? supplierDoc,
    String? invoiceNumber,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
    if (supplierName != null && supplierName.isNotEmpty) body['supplierName'] = supplierName;
    if (supplierDoc != null && supplierDoc.isNotEmpty) body['supplierDoc'] = supplierDoc;
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) body['invoiceNumber'] = invoiceNumber;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final res = await _client.post('/stock/entries', body: body, token: token);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Erro ao registrar entrada');
    }
  }

  /// POST /stock/exits — registrar saída (uso/consumo)
  Future<void> createExit(
    String token, {
    required String productId,
    required int quantity,
    double? unitPrice,
    String? projectName,
    String? clientName,
    String? serviceType,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
    };
    if (unitPrice != null && unitPrice > 0) body['unitPrice'] = unitPrice;
    if (projectName != null && projectName.isNotEmpty) body['projectName'] = projectName;
    if (clientName != null && clientName.isNotEmpty) body['clientName'] = clientName;
    if (serviceType != null && serviceType.isNotEmpty) body['serviceType'] = serviceType;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final res = await _client.post('/stock/exits', body: body, token: token);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Erro ao registrar saída');
    }
  }
}
