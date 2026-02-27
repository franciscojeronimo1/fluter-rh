import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/stock.dart';

/// Item da lista de produtos com estoque baixo.
class LowStockItem extends StatelessWidget {
  const LowStockItem({super.key, required this.product});

  final LowStockProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Atual: ${product.currentStock} ${product.unit}  ·  Mín: ${product.minStock} ${product.unit}',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.lowStockAlert.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${product.deficit}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.lowStockAlert,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
