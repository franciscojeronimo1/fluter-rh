import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';

/// Card base reutilizável com sombra e bordas arredondadas.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.highlight = false,
    this.elevation = 2,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final bool highlight;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.lowStockAlert : (borderColor ?? AppColors.border);

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}
