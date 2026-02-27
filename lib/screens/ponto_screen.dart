import 'package:flutter/material.dart';

import '../components/components.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/time_record.dart';
import '../services/auth_service.dart';
import '../services/time_records_service.dart';

class PontoScreen extends StatefulWidget {
  const PontoScreen({super.key});

  @override
  State<PontoScreen> createState() => _PontoScreenState();
}

class _PontoScreenState extends State<PontoScreen> {
  final _authService = AuthService();
  final _timeService = TimeRecordsService();

  TimeSummary? _summary;
  List<TimeRecord> _records = [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  String _today = '';

  @override
  void initState() {
    super.initState();
    _setToday();
    _load();
  }

  void _setToday() {
    final now = DateTime.now();
    _today =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String get _dateParam {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final token = await _authService.getToken();
    if (token == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await _timeService.getSummary(token, date: _dateParam);
      final listRes = await _timeService.getRecords(token, date: _dateParam);
      if (mounted) {
        setState(() {
          _summary = summary ?? _summary;
          _records = listRes?.records ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _start() async {
    final token = await _authService.getToken();
    if (token == null) return;

    setState(() {
      _actionLoading = true;
      _error = null;
    });

    try {
      await _timeService.start(token);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _stop() async {
    final token = await _authService.getToken();
    if (token == null) return;

    setState(() {
      _actionLoading = true;
      _error = null;
    });

    try {
      await _timeService.stop(token);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  bool get _isStarted => _summary?.status == 'started';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Bater Ponto',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && _summary == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_today, style: AppTheme.body.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppTheme.spacingLg),
                    StatusCard(
                      label: _isStarted ? 'Trabalhando' : 'Parado',
                      icon: _isStarted ? Icons.play_circle_filled : Icons.pause_circle_outline,
                      active: _isStarted,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: AppTheme.spacing2xl),
                    _ActionButtons(
                      isStarted: _isStarted,
                      actionLoading: _actionLoading,
                      onStart: _start,
                      onStop: _stop,
                    ),
                    const SizedBox(height: AppTheme.spacing2xl),
                    _SummaryCard(summary: _summary),
                    const SizedBox(height: AppTheme.spacing2xl),
                    const SectionTitle(title: 'Histórico do dia'),
                    const SizedBox(height: AppTheme.spacingSm),
                    _RecordsList(records: _records),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isStarted,
    required this.actionLoading,
    required this.onStart,
    required this.onStop,
  });

  final bool isStarted;
  final bool actionLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: actionLoading || isStarted ? null : onStart,
            icon: actionLoading && !isStarted
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Iniciar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: actionLoading || !isStarted ? null : onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Encerrar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({this.summary});

  final TimeSummary? summary;

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = summary?.totalHours ?? '0:00';
    final totalMinutes = summary?.totalMinutes ?? 0;
    final periods = summary?.periods ?? [];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumo do dia', style: AppTheme.sectionTitle),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            totalHours,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text('$totalMinutes minutos', style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
          if (periods.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingLg),
            const Divider(),
            const SizedBox(height: AppTheme.spacingSm),
            ...periods.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${p.start} – ${p.stop}  ·  ${_formatMinutes(p.minutes)}',
                    style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _RecordsList extends StatelessWidget {
  const _RecordsList({required this.records});

  final List<TimeRecord> records;

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const EmptyState(message: 'Nenhum registro hoje', icon: Icons.schedule);
    }

    return Column(
      children: records.map((r) {
        final isStart = r.type == 'START';
        final time = _formatTimestamp(r.timestamp);
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                isStart ? Icons.login : Icons.logout,
                color: isStart ? Colors.green.shade700 : Colors.orange.shade700,
                size: 22,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStart ? 'Entrada' : 'Saída',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      time,
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
