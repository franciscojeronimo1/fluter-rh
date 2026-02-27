import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:fluter_rh/core/api_client.dart';
import 'package:fluter_rh/models/time_record.dart';

class TimeRecordsService {
  TimeRecordsService({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// POST /time-records/start
  Future<TimeRecord?> start(String token) async {
    final res = await _client.post('/time-records/start', token: token);
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromResponse(res);
    }
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return TimeRecord.fromJson(data);
    } catch (e) {
      final snippet = res.body.length > 100 ? '${res.body.substring(0, 100)}...' : res.body;
      throw Exception('Resposta inválida do servidor: $snippet');
    }
  }

  /// POST /time-records/stop — retorna { summary, ... }
  Future<Map<String, dynamic>?> stop(String token) async {
    final res = await _client.post('/time-records/stop', token: token);
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throwFromResponse(res);
    }
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Resposta inválida do servidor');
    }
  }

  /// GET /time-records/summary?date=YYYY-MM-DD
  /// Lança [Exception] em 4xx/5xx para exibir erro na UI.
  Future<TimeSummary?> getSummary(String token, {String? date}) async {
    final path = date != null
        ? '/time-records/summary?date=$date'
        : '/time-records/summary';
    final res = await _client.get(path, token: token);
    if (res.statusCode != 200) {
      _throwFromResponse(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final summary = data?['summary'];
    if (summary == null) return null;
    return TimeSummary.fromJson(summary as Map<String, dynamic>);
  }

  /// GET /time-records?date=YYYY-MM-DD
  /// Lança [Exception] em 4xx/5xx para exibir erro na UI.
  Future<TimeRecordsListResponse?> getRecords(String token, {String? date}) async {
    final path = date != null ? '/time-records?date=$date' : '/time-records';
    final res = await _client.get(path, token: token);
    if (res.statusCode != 200) {
      _throwFromResponse(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final recordsList = data?['records'] as List<dynamic>?;
    final summary = data?['summary'];
    return TimeRecordsListResponse(
      records: recordsList
              ?.map((e) => TimeRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: summary != null
          ? TimeSummary.fromJson(summary as Map<String, dynamic>)
          : null,
    );
  }

  void _throwFromResponse(http.Response res) {
    if (kDebugMode) {
      debugPrint('[API] Erro ${res.statusCode}: ${res.request?.url}');
      debugPrint('[API] Body: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
    }
    String msg;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      // Prefer 'message' (regra de negócio) sobre 'error' (genérico)
      msg = body?['message'] as String? ??
          body?['error'] as String? ??
          'Erro ${res.statusCode}: ${res.body.isNotEmpty ? res.body : "Resposta vazia"}';
    } catch (_) {
      msg = 'Erro ${res.statusCode}: ${res.body.isNotEmpty ? res.body : "Resposta vazia"}';
    }
    throw Exception(msg);
  }
}

class TimeRecordsListResponse {
  TimeRecordsListResponse({required this.records, this.summary});

  final List<TimeRecord> records;
  final TimeSummary? summary;
}
