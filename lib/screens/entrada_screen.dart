import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/components.dart';
import '../core/api_exceptions.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/stock_service.dart';

class EntradaScreen extends StatefulWidget {
  const EntradaScreen({super.key});

  @override
  State<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends State<EntradaScreen> {
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
  final _supplierNameController = TextEditingController();
  final _supplierDocController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
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
    _supplierNameController.dispose();
    _supplierDocController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onQuantityOrPriceChanged() => setState(() {});

  double get _total {
    final q = int.tryParse(_quantityController.text) ?? 0;
    final p = double.tryParse(_unitPriceController.text.replaceAll(',', '.')) ?? 0;
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
        all.addAll(res.products);
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
        if (e is SubscriptionRequiredException) {
          setState(() => _loading = false);
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
    final unitPrice = double.tryParse(_unitPriceController.text.replaceAll(',', '.')) ?? 0;

    if (quantity <= 0 || unitPrice <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Quantidade e preço devem ser maiores que zero')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _stockService.createEntry(
        token,
        productId: _selectedProduct!.id,
        quantity: quantity,
        unitPrice: unitPrice,
        supplierName: _supplierNameController.text.trim().isEmpty
            ? null
            : _supplierNameController.text.trim(),
        supplierDoc: _supplierDocController.text.trim().isEmpty
            ? null
            : _supplierDocController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim().isEmpty
            ? null
            : _invoiceNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Entrada registrada com sucesso')),
        );
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        if (e is SubscriptionRequiredException) {
          showUpgradeDialog(context);
          return;
        }
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
        title: const Text('Registrar Entrada'),
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
                          'Nenhum produto cadastrado. Cadastre produtos antes de registrar entradas.',
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
                                    p.code != null && p.code!.isNotEmpty
                                        ? '${p.name} (${p.code})'
                                        : p.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedProduct = v),
                        validator: (v) => v == null ? 'Selecione um produto' : null,
                      ),
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
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _unitPriceController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Preço unitário (R\$) *',
                          prefixIcon: Icons.attach_money,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                          if (n == null || n <= 0) return 'Preço deve ser maior que zero';
                          return null;
                        },
                      ),
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
                            Text('Total', style: AppTheme.bodyLarge),
                            Text(
                              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(_total),
                              style: AppTheme.heading4.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'Dados do fornecedor (opcional)',
                        style: AppTheme.sectionTitle,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _supplierNameController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Nome do fornecedor',
                          prefixIcon: Icons.business,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _supplierDocController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'CNPJ/CPF do fornecedor',
                          prefixIcon: Icons.badge,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      TextFormField(
                        controller: _invoiceNumberController,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Nº Nota Fiscal',
                          prefixIcon: Icons.receipt_long,
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
                            : const Text('Registrar entrada'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
