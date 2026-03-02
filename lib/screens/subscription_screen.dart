import 'package:flutter/material.dart';

import '../components/components.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/subscription.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _authService = AuthService();
  final _subscriptionService = SubscriptionService();

  Subscription? _subscription;
  bool _loading = true;
  String? _error;

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
      final subscription = await _subscriptionService.getSubscription(token);
      await _authService.refreshSubscription();
      if (mounted) {
        setState(() {
          _subscription = subscription;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assinatura'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      ErrorBanner(message: _error!),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],
                    if (_subscription != null) ...[
                      AppCard(
                        padding: const EdgeInsets.all(AppTheme.spacingXl),
                        borderColor: _subscription!.isPremium
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : null,
                        child: Column(
                          children: [
                            Icon(
                              _subscription!.isPremium
                                  ? Icons.workspace_premium
                                  : Icons.card_giftcard,
                              size: 48,
                              color: _subscription!.isPremium
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Text(
                              _subscription!.planLabel,
                              style: AppTheme.heading2,
                            ),
                            const SizedBox(height: AppTheme.spacingXs),
                            Text(
                              'Status: ${_subscription!.status}',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      if (!_subscription!.isPremium) ...[
                        Text(
                          'Faça upgrade para Premium e desbloqueie:',
                          style: AppTheme.body,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        _FeatureItem(
                          icon: Icons.schedule,
                          text: 'Bater ponto',
                        ),
                        _FeatureItem(
                          icon: Icons.inventory_2,
                          text: 'Produtos e estoque',
                        ),
                        _FeatureItem(
                          icon: Icons.category,
                          text: 'Categorias',
                        ),
                        _FeatureItem(
                          icon: Icons.people,
                          text: 'Colaboradores',
                        ),
                        const SizedBox(height: AppTheme.spacing2xl),
                        FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Área de pagamento em breve. Entre em contato para upgrade.',
                                ),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingLg,
                            ),
                          ),
                          child: const Text('Fazer upgrade para Premium'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: AppTheme.spacingMd),
          Text(text, style: AppTheme.body),
        ],
      ),
    );
  }
}
