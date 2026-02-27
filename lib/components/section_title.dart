import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Título de seção reutilizável.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTheme.sectionTitle);
  }
}
