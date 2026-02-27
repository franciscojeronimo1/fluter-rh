/// Registro de ponto (entrada ou saída)
class TimeRecord {
  TimeRecord({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.user,
  });

  factory TimeRecord.fromJson(Map<String, dynamic> json) {
    return TimeRecord(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      user: TimeRecordUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  final String id;
  final String type; // "START" | "STOP"
  final String timestamp;
  final TimeRecordUser user;
}

class TimeRecordUser {
  TimeRecordUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory TimeRecordUser.fromJson(Map<String, dynamic> json) {
    return TimeRecordUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String email;
}

/// Período (entrada–saída).
/// [stop] pode ser vazio quando o período ainda está em andamento.
class TimePeriod {
  TimePeriod({
    required this.start,
    required this.stop,
    required this.minutes,
  });

  factory TimePeriod.fromJson(Map<String, dynamic> json) {
    return TimePeriod(
      start: json['start'] as String? ?? '',
      stop: json['stop']?.toString() ?? '', // null quando em andamento
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  final String start; // "HH:mm"
  final String stop; // "HH:mm" ou "" quando em andamento
  final int minutes;
}

/// Resumo do dia
class TimeSummary {
  TimeSummary({
    required this.date,
    required this.periods,
    required this.totalMinutes,
    required this.totalHours,
    required this.status,
  });

  factory TimeSummary.fromJson(Map<String, dynamic> json) {
    final periodsList = json['periods'] as List<dynamic>?;
    return TimeSummary(
      date: json['date'] as String? ?? '',
      periods: periodsList
              ?.map((e) => TimePeriod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ??
          (json['total_minutes'] as num?)?.toInt() ?? 0,
      totalHours: (json['totalHours'] ?? json['total_hours']) as String? ?? '0:00',
      status: json['status'] as String? ?? 'stopped',
    );
  }

  final String date; // "YYYY-MM-DD"
  final List<TimePeriod> periods;
  final int totalMinutes;
  final String totalHours;
  final String status; // "started" | "stopped"
}
