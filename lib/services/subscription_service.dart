import 'dart:convert';

import 'package:fluter_rh/core/api_client.dart';
import 'package:fluter_rh/models/subscription.dart';

class SubscriptionService {
  SubscriptionService({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// GET /subscription — retorna plano atual, status e isPremium
  Future<Subscription> getSubscription(String token) async {
    final res = await _client.get('/subscription', token: token);
    if (res.statusCode != 200) {
      throw Exception('Erro ao carregar assinatura');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Subscription.fromJson(data);
  }
}
