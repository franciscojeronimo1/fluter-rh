import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';

class ProdutoFormScreen extends StatefulWidget {
  const ProdutoFormScreen({
    super.key,
    this.product,
    required this.categories,
  });

  final Product? product;
  final List<Category> categories;

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _productService = ProductService();
  final _categoryService = CategoryService();

  late List<Category> _categories;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _skuController = TextEditingController();
  final _minStockController = TextEditingController(text: '0');
  final _unitController = TextEditingController(text: 'UN');
  final _costPriceController = TextEditingController();
  String? _selectedCategory;
  bool _active = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _codeController.text = p.code ?? '';
      _skuController.text = p.sku ?? '';
      _minStockController.text = '${p.minStock}';
      _unitController.text = p.unit;
      _costPriceController.text = p.costPrice ?? '';
      _selectedCategory = p.category;
      _active = p.active;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _skuController.dispose();
    _minStockController.dispose();
    _unitController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  void _showNewCategoryDialog() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(
          controller: nameController,
          decoration: AppTheme.inputDecoration(
            hintText: 'Nome da categoria',
            prefixIcon: Icons.category,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final token = await _authService.getToken();
      if (token == null) return;
      try {
        final cat = await _categoryService.create(token, name: result);
        if (mounted) {
          setState(() {
            _categories = [..._categories, cat];
            _selectedCategory = cat.name;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final token = await _authService.getToken();
    if (token == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final code = _codeController.text.trim();
      final sku = _skuController.text.trim();
      final category = _selectedCategory?.isEmpty == true ? null : _selectedCategory;
      final minStock = int.tryParse(_minStockController.text) ?? 0;
      final unit = _unitController.text.trim().isEmpty ? 'UN' : _unitController.text.trim();
      final costPrice = double.tryParse(_costPriceController.text.replaceAll(',', '.'));

      if (_isEditing) {
        await _productService.update(
          token,
          widget.product!.id,
          name: name,
          code: code.isEmpty ? null : code,
          sku: sku.isEmpty ? null : sku,
          category: category,
          minStock: minStock,
          unit: unit,
          costPrice: costPrice,
          active: _active,
        );
      } else {
        await _productService.create(
          token,
          name: name,
          code: code.isEmpty ? null : code,
          sku: sku.isEmpty ? null : sku,
          category: category,
          minStock: minStock,
          unit: unit,
          costPrice: costPrice != null && costPrice >= 0 ? costPrice : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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
        title: Text(_isEditing ? 'Editar produto' : 'Novo produto'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
              TextFormField(
                controller: _nameController,
                decoration: AppTheme.inputDecoration(
                  hintText: 'Nome *',
                  prefixIcon: Icons.inventory_2,
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Nome é obrigatório' : null,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _codeController,
                decoration: AppTheme.inputDecoration(
                  hintText: 'Código',
                  prefixIcon: Icons.tag,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _skuController,
                decoration: AppTheme.inputDecoration(
                  hintText: 'SKU',
                  prefixIcon: Icons.qr_code,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedCategory?.isEmpty == true ? null : _selectedCategory,
                      decoration: AppTheme.inputDecoration(
                        hintText: 'Categoria',
                        prefixIcon: Icons.category,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                        ..._categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
                        if (_isEditing &&
                            widget.product!.category != null &&
                            widget.product!.category!.isNotEmpty &&
                            !_categories.any((c) => c.name == widget.product!.category))
                          DropdownMenuItem(
                            value: widget.product!.category,
                            child: Text(widget.product!.category!),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _showNewCategoryDialog,
                    tooltip: 'Nova categoria',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: AppTheme.inputDecoration(
                        hintText: 'Estoque mínimo',
                        prefixIcon: Icons.warning_amber,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n != null && n < 0) return 'Deve ser >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: AppTheme.inputDecoration(
                        hintText: 'Unidade *',
                        prefixIcon: Icons.straighten,
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Unidade é obrigatória' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _costPriceController,
                decoration: AppTheme.inputDecoration(
                  hintText: 'Preço de custo',
                  prefixIcon: Icons.attach_money,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n != null && n < 0) return 'Deve ser >= 0';
                  return null;
                },
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppTheme.spacingMd),
                _InfoReadOnly(
                  label: 'Estoque atual',
                  value: '${widget.product!.currentStock} ${widget.product!.unit}',
                ),
                if (widget.product!.averageCost != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  _InfoReadOnly(
                    label: 'Custo médio',
                    value: _formatBRL(widget.product!.averageCost),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingLg),
                CheckboxListTile(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v ?? true),
                  title: const Text('Produto ativo'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: AppTheme.spacing2xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Salvar' : 'Criar produto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBRL(String? value) {
    if (value == null || value.isEmpty) return '—';
    final n = double.tryParse(value);
    if (n == null) return '—';
    return 'R\$ ${n.toStringAsFixed(2).replaceFirst('.', ',')}';
  }
}

class _InfoReadOnly extends StatelessWidget {
  const _InfoReadOnly({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: AppTheme.caption),
        ),
        Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
