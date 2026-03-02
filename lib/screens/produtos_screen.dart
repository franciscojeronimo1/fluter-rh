import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/components.dart';
import '../core/api_exceptions.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import 'produto_form_screen.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final _authService = AuthService();
  final _productService = ProductService();
  final _categoryService = CategoryService();

  List<Product> _products = [];
  List<Category> _categories = [];
  ProductPaginationInfo? _pagination;
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _filterCategory;
  bool _includeInactive = false;
  int _page = 1;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _load();
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
        _categoryService.list(token),
        _productService.list(
          token,
          category: _filterCategory,
          includeInactive: _includeInactive,
          page: _page,
          limit: _limit,
        ),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          final response = results[1] as ProductsResponse;
          _products = response.products;
          _pagination = response.pagination;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is SubscriptionRequiredException) {
          showUpgradeDialog(context);
          return;
        }
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) {
      final matchName = p.name.toLowerCase().contains(q);
      final matchCode = (p.code ?? '').toLowerCase().contains(q);
      final matchSku = (p.sku ?? '').toLowerCase().contains(q);
      return matchName || matchCode || matchSku;
    }).toList();
  }

  String _formatBRL(String? value) {
    if (value == null || value.isEmpty) return '—';
    final n = double.tryParse(value);
    if (n == null) return '—';
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(n);
  }

  void _navigateToNew() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProdutoFormScreen(categories: _categories),
      ),
    );
    if (result == true && mounted) _load();
  }

  void _navigateToEdit(Product product) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProdutoFormScreen(
          product: product,
          categories: _categories,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text(
          'Deseja excluir "${product.name}"? O produto será marcado como inativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final token = await _authService.getToken();
              if (token == null) return;
              try {
                await _productService.delete(token, product.id);
                if (mounted) _load();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.lowStockAlert),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Produtos',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _loading ? null : _navigateToNew,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _FiltersBar(
            categories: _categories,
            filterCategory: _filterCategory,
            includeInactive: _includeInactive,
            onCategoryChanged: (v) {
              setState(() {
                _filterCategory = v;
                _page = 1;
              });
              _load();
            },
            onIncludeInactiveChanged: (v) {
              setState(() {
                _includeInactive = v;
                _page = 1;
              });
              _load();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
            child: TextField(
              decoration: AppTheme.inputDecoration(
                hintText: 'Buscar por nome, código ou SKU',
                prefixIcon: Icons.search,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Expanded(
            child: _loading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _buildContent(filtered),
                  ),
          ),
          if (_pagination != null && _pagination!.totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildContent(List<Product> filtered) {
    if (_error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: ErrorBanner(message: _error!),
      );
    }

    if (filtered.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: EmptyState(
          message: _searchQuery.isEmpty
              ? 'Nenhum produto encontrado'
              : 'Nenhum produto corresponde à busca',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _ProductCard(
        product: filtered[i],
        formatBRL: _formatBRL,
        onEdit: () => _navigateToEdit(filtered[i]),
        onDelete: () => _confirmDelete(filtered[i]),
      ),
    );
  }

  void _showPagePicker() {
    final p = _pagination!;
    final controller = TextEditingController(text: '${p.page}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ir para página'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digite o número da página (1 a ${p.totalPages})',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: controller,
              decoration: AppTheme.inputDecoration(
                hintText: 'Página',
                prefixIcon: Icons.numbers,
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= p.totalPages) {
                Navigator.of(ctx).pop();
                setState(() => _page = page);
                _load();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Digite um número entre 1 e ${p.totalPages}'),
                  ),
                );
              }
            },
            child: const Text('Ir'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final p = _pagination!;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: p.hasPrev ? () { setState(() => _page--); _load(); } : null,
          ),
          GestureDetector(
            onTap: _showPagePicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Text(
                'Página ${p.page} de ${p.totalPages}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: p.hasNext ? () { setState(() => _page++); _load(); } : null,
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.categories,
    required this.filterCategory,
    required this.includeInactive,
    required this.onCategoryChanged,
    required this.onIncludeInactiveChanged,
  });

  final List<Category> categories;
  final String? filterCategory;
  final bool includeInactive;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool> onIncludeInactiveChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      color: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String?>(
            initialValue: filterCategory,
            decoration: AppTheme.inputDecoration(
              hintText: 'Todas as categorias',
              prefixIcon: Icons.category,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas as categorias')),
              ...categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
            ],
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          CheckboxListTile(
            value: includeInactive,
            onChanged: (v) => onIncludeInactiveChanged(v ?? false),
            title: Text('Incluir inativos', style: AppTheme.bodySmall),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.formatBRL,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String Function(String?) formatBRL;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      borderColor: product.isLowStock ? AppColors.lowStockAlert.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTheme.bodyLarge),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Cód: ${product.code ?? "—"} • Cat: ${product.category ?? "—"}',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              if (product.isLowStock)
                Icon(Icons.warning_amber_rounded, color: AppColors.lowStockAlert, size: 24),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          const Divider(height: AppTheme.spacingLg),
          Row(
            children: [
              _InfoChip(label: 'Estoque', value: '${product.currentStock}', isAlert: product.isLowStock),
              const SizedBox(width: AppTheme.spacingMd),
              _InfoChip(label: 'Mín', value: '${product.minStock}'),
              const SizedBox(width: AppTheme.spacingMd),
              _InfoChip(label: 'Un', value: product.unit),
              const Spacer(),
              _InfoChip(label: 'Custo', value: formatBRL(product.costPrice)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            product.active ? 'Ativo' : 'Inativo',
            style: AppTheme.captionSmall.copyWith(
              color: product.active ? Colors.green : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, this.isAlert = false});

  final String label;
  final String value;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.captionSmall),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isAlert ? AppColors.lowStockAlert : null,
          ),
        ),
      ],
    );
  }
}
