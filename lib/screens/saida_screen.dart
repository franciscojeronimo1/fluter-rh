import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/app_card.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/stock_service.dart';

class SaidaScreen extends StatefulWidget {
  const SaidaScreen({super.key});

  @override
  State<SaidaScreen> createState() => _SaidaScreenState();
}

class _SaidaScreenState extends State<SaidaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _productService = ProductService();
  final _stockService = StockService();

  List<Product> _products = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _quantityController.addListener(_onQuantityOrPriceChanged);
    _unitPriceController.addListener(_onQuantityOrPriceChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityOrPriceChanged);
    _unitPriceController.removeListener(_onQuantityOrPriceChanged);
    _quantityController.dispose();
    _unitPriceController.dispose();
    _projectNameController.dispose();
    _clientNameController.dispose();
    _serviceTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onQuantityOrPriceChanged() => setState(() {});

  double? get _totalVenda {
    final p = double.tryParse(_unitPriceController.text.replaceAll(',', '.'));
    if (p == null || p <= 0) return null;
    final q = int.tryParse(_quantityController.text) ?? 0;
    return q * p;
  }

  Future<void> _loadProducts() async {
    final token = await _authService.getToken();
    if (token == null) return;

    setState(() => _loading = true);
    try {
      var page = 1;
      final all = <Product>[];
      while (true) {
        final res = await _productService.list(
          token,
          includeInactive: false,
          page: page,
          limit: 100,
        );
        all.addAll(res.products.where((p) => p.currentStock > 0));
        if (!res.pagination.hasNext) break;
        page++;
      }
      if (mounted) {
        setState(() {
          _products = all;
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_selectedProduct == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecione um produto')),
      );
      return;
    }

    final token = await _authService.getToken();
    if (token == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text.replaceAll(',', '.'));

    if (quantity <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Quantidade deve ser maior que zero')),
      );
      return;
    }

    if (quantity > _selectedProduct!.currentStock) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Quantidade não pode ser maior que o estoque disponível (${_selectedProduct!.currentStock})',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _stockService.createExit(
        token,
        productId: _selectedProduct!.id,
        quantity: quantity,
        unitPrice: unitPrice != null && unitPrice > 0 ? unitPrice : null,
        projectName: _projectNameController.text.trim().isEmpty
            ? null
            : _projectNameController.text.trim(),
        clientName: _clientNameController.text.trim().isEmpty
            ? null
            : _clientNameController.text.trim(),
        serviceType: _serviceTypeController.text.trim().isEmpty
            ? null
            : _serviceTypeController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Saída registrada com sucesso')),
        );
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Saída'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.lowStockAlert.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Text(_error!, style: TextStyle(color: AppColors.lowStockAlert)),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],
                    if (_products.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppTheme.spacing2xl),
                        child: Text(
                          'Nenhum produto com estoque disponível. Registre entradas antes de registrar saídas.',
                          textAlign: TextAlign.center,
                          style: AppTheme.body,
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<Product>(
                        initialValue: _selectedProduct,
                        isExpanded: true,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Produto *',
                          prefixIcon: Icons.inventory_2,
                        ),
                        items: _products
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    '${p.name} - Estoque: ${p.currentStock} ${p.unit}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedProduct = v),
                        validator: (v) => v == null ? 'Selecione um produto' : null,
                      ),
                      if (_selectedProduct != null) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        AppCard(
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          borderColor: _selectedProduct!.isLowStock
                              ? AppColors.lowStockAlert.withValues(alpha: 0.5)
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.inventory,
                                    size: 20,
                                    color: _selectedProduct!.isLowStock
                                        ? AppColors.lowStockAlert
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  Text(
                                    'Estoque disponível: ${_selectedProduct!.currentStock} ${_selectedProduct!.unit}',
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _selectedProduct!.isLowStock
                                          ? AppColors.lowStockAlert
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedProduct!.isLowStock) ...[
                                const SizedBox(height: AppTheme.spacingSm),
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 18, color: AppColors.lowStockAlert),
                                    const SizedBox(width: AppTheme.spacingSm),
                                    Text(
                                      'Estoque abaixo do mínimo (${_selectedProduct!.minStock})',
                                      style: AppTheme.captionSmall.copyWith(
                                        color: AppColors.lowStockAlert,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _quantityController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Quantidade *',
                          prefixIcon: Icons.numbers,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Quantidade deve ser maior que zero';
                          if (_selectedProduct != null && n > _selectedProduct!.currentStock) {
                            return 'Máximo: ${_selectedProduct!.currentStock}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _unitPriceController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Preço unitário (R\$) - opcional',
                          prefixIcon: Icons.attach_money,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      if (_totalVenda != null) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total da venda', style: AppTheme.bodyLarge),
                              Text(
                                NumberFormat.currency(
                                  locale: 'pt_BR',
                                  symbol: 'R\$',
                                ).format(_totalVenda),
                                style: AppTheme.heading4.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'Informações adicionais (opcional)',
                        style: AppTheme.sectionTitle,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _projectNameController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Nome do projeto',
                          prefixIcon: Icons.folder,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Nome do cliente',
                          prefixIcon: Icons.person,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _serviceTypeController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Tipo de serviço',
                          prefixIcon: Icons.build,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _notesController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Observações',
                          prefixIcon: Icons.notes,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppTheme.spacing2xl),
                      FilledButton(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Registrar saída'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
