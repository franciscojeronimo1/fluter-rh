import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';

/// Card de resumo com ícone, valor e subtítulo (estoque, dashboard).
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.highlight = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final valueColor = highlight ? AppColors.lowStockAlert : AppColors.textPrimary;
    final iconColor = highlight ? AppColors.lowStockAlert : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: highlight ? AppColors.lowStockAlert : AppColors.border,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(
            subtitle,
            style: AppTheme.captionSmall,
          ),
        ],
      ),
    );
  }
}
