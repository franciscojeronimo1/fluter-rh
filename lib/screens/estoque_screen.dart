import 'package:flutter/material.dart';

import '../components/components.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/stock.dart';
import '../services/auth_service.dart';
import '../services/stock_service.dart';
import 'produtos_screen.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final _authService = AuthService();
  final _stockService = StockService();

  TotalValueResponse? _totalValue;
  LowStockResponse? _lowStock;
  CurrentStockResponse? _currentStock;
  DailyUsageResponse? _dailyUsage;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _todayParam {
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
      final results = await Future.wait([
        _stockService.getTotalValue(token),
        _stockService.getLowStock(token, limit: 20),
        _stockService.getCurrentStock(token, limit: 500),
        _stockService.getDailyUsage(token, _todayParam),
      ]);

      if (mounted) {
        setState(() {
          _totalValue = results[0] as TotalValueResponse?;
          _lowStock = results[1] as LowStockResponse?;
          _currentStock = results[2] as CurrentStockResponse?;
          _dailyUsage = results[3] as DailyUsageResponse?;
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

  int get _totalProducts =>
      _currentStock?.pagination.total ?? _totalValue?.totalProducts ?? 0;

  int get _lowStockCount =>
      _lowStock?.pagination.total ?? _lowStock?.products.length ?? 0;

  int get _usageToday {
    final list = _dailyUsage?.products ?? [];
    return list.fold<int>(0, (s, p) => s + p.totalQuantity);
  }

  String get _totalValueFormatted {
    if (_totalValue == null) return '—';
    final v = _totalValue!.totalValue;
    if (v.isEmpty || v == '0') return 'R\$ 0,00';
    final num? n = double.tryParse(v);
    if (n == null) return 'R\$ —';
    return 'R\$ ${n.toStringAsFixed(2).replaceFirst('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Controle de Estoque',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && _totalValue == null && _lowStock == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Gerencie produtos, entradas e saídas',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: AppTheme.spacingXl),
                    _SummaryCards(
                      totalValueFormatted: _totalValueFormatted,
                      totalProducts: _totalProducts,
                      totalValueProductsWithStock: _totalValue?.productsWithStock ?? _totalProducts,
                      lowStockCount: _lowStockCount,
                      usageToday: _usageToday,
                    ),
                    const SizedBox(height: AppTheme.spacing2xl),
                    _LowStockSection(lowStock: _lowStock),
                    const SizedBox(height: AppTheme.spacingLg),
                    ShortcutCard(
                      title: 'Produtos',
                      subtitle: 'Listar, criar e editar produtos',
                      icon: Icons.inventory,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProdutosScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.totalValueFormatted,
    required this.totalProducts,
    required this.totalValueProductsWithStock,
    required this.lowStockCount,
    required this.usageToday,
  });

  final String totalValueFormatted;
  final int totalProducts;
  final int totalValueProductsWithStock;
  final int lowStockCount;
  final int usageToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Valor Total',
                value: totalValueFormatted,
                subtitle: '$totalValueProductsWithStock produtos com valor',
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: SummaryCard(
                title: 'Total de Produtos',
                value: '$totalProducts',
                subtitle: 'Itens no estoque',
                icon: Icons.inventory,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Estoque Baixo',
                value: '$lowStockCount',
                subtitle: 'Produtos abaixo do mínimo',
                icon: Icons.warning_amber_rounded,
                highlight: lowStockCount > 0,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: SummaryCard(
                title: 'Uso Hoje',
                value: '$usageToday',
                subtitle: 'Itens utilizados hoje',
                icon: Icons.today,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LowStockSection extends StatelessWidget {
  const _LowStockSection({this.lowStock});

  final LowStockResponse? lowStock;

  @override
  Widget build(BuildContext context) {
    final products = lowStock?.products ?? [];
    final total = lowStock?.pagination.total ?? products.length;

    if (total == 0) {
      return const EmptyState(
        message: 'Nenhum produto com estoque baixo',
        icon: Icons.check_circle_outline,
      );
    }

    final toShow = products.take(5).toList();
    final rest = total - toShow.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Produtos com Estoque Baixo'),
        const SizedBox(height: AppTheme.spacingMd),
        AppCard(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          borderColor: AppColors.lowStockAlert.withValues(alpha: 0.5),
          child: Column(
            children: [
              ...toShow.map((p) => LowStockItem(product: p)),
              if (rest > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                  child: Text(
                    '+$rest produto(s) com estoque baixo',
                    style: AppTheme.caption,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
