import 'dart:convert';

import 'package:fluter_rh/core/api_client.dart';
import 'package:fluter_rh/models/time_record.dart';

class TimeRecordsService {
  TimeRecordsService({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// POST /time-records/start
  Future<TimeRecord?> start(String token) async {
    final res = await _client.post('/time-records/start', token: token);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Erro ao iniciar ponto');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return TimeRecord.fromJson(data);
  }

  /// POST /time-records/stop — retorna { summary, ... }
  Future<Map<String, dynamic>?> stop(String token) async {
    final res = await _client.post('/time-records/stop', token: token);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Erro ao encerrar ponto');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// GET /time-records/summary?date=YYYY-MM-DD
  Future<TimeSummary?> getSummary(String token, {String? date}) async {
    final path = date != null
        ? '/time-records/summary?date=$date'
        : '/time-records/summary';
    final res = await _client.get(path, token: token);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final summary = data['summary'];
    if (summary == null) return null;
    return TimeSummary.fromJson(summary as Map<String, dynamic>);
  }

  /// GET /time-records?date=YYYY-MM-DD
  Future<TimeRecordsListResponse?> getRecords(String token, {String? date}) async {
    final path = date != null ? '/time-records?date=$date' : '/time-records';
    final res = await _client.get(path, token: token);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final recordsList = data['records'] as List<dynamic>?;
    final summary = data['summary'];
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
}

class TimeRecordsListResponse {
  TimeRecordsListResponse({required this.records, this.summary});

  final List<TimeRecord> records;
  final TimeSummary? summary;
}
