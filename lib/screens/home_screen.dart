import 'package:flutter/material.dart';

import '../components/components.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import 'estoque_screen.dart';
import 'ponto_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  User? _user;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await _authService.getStoredUser();
    final isPremium = await _authService.isPremium;
    if (mounted) {
      setState(() {
        _user = user;
        _isPremium = isPremium;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) widget.onLogout?.call();
  }

  void _navigateToPremiumScreen(Widget screen) {
    if (!_isPremium) {
      _showUpgradeDialog();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plano Premium'),
        content: const Text(
          'Este recurso requer assinatura Premium. Faça upgrade para acessar Ponto, Estoque, Produtos e mais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ).then((_) => _load());
            },
            child: const Text('Ver plano'),
          ),
        ],
      ),
    );
  }

  String get _perfilLabel =>
      _user?.role == 'ADMIN' ? 'Administrador' : 'Colaborador';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Sistema CGS',
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 20, color: Colors.white),
            label: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bem-vindo, ${_user?.name ?? 'Usuário'}!',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Sistema de gestão empresarial',
              style: AppTheme.body.copyWith(color: AppColors.textSecondary),
            ),
            if (!_isPremium)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                child: Text(
                  'Plano Gratuito • Faça upgrade para desbloquear recursos',
                  style: AppTheme.caption.copyWith(color: AppColors.primary),
                ),
              ),
            const SizedBox(height: AppTheme.spacing2xl),
            const SectionTitle(title: 'Atalhos'),
            const SizedBox(height: AppTheme.spacingMd),
            ShortcutCard(
              title: 'Bater Ponto',
              subtitle: _isPremium ? 'Registrar entrada e saída' : 'Requer Premium',
              icon: Icons.schedule,
              onTap: () => _navigateToPremiumScreen(const PontoScreen()),
            ),
            const SizedBox(height: 10),
            ShortcutCard(
              title: 'Estoque',
              subtitle: _isPremium ? 'Controle de produtos e estoque baixo' : 'Requer Premium',
              icon: Icons.inventory_2_outlined,
              onTap: () => _navigateToPremiumScreen(const EstoqueScreen()),
            ),
            const SizedBox(height: 10),
            ShortcutCard(
              title: 'Assinatura',
              subtitle: _isPremium ? 'Plano Premium ativo' : 'Ver plano e fazer upgrade',
              icon: Icons.workspace_premium,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ).then((_) => _load()),
            ),
            const SizedBox(height: 10),
            const ShortcutCard(
              title: 'Colaboradores',
              subtitle: 'Em breve',
              icon: Icons.people_outline,
            ),
            const SizedBox(height: 10),
            const ShortcutCard(
              title: 'Administração',
              subtitle: 'Em breve',
              icon: Icons.settings_outlined,
            ),
            const SizedBox(height: AppTheme.spacing3xl),
            const SectionTitle(title: 'Informações da Conta'),
            const SizedBox(height: AppTheme.spacingMd),
            _AccountCard(user: _user, perfilLabel: _perfilLabel),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({this.user, required this.perfilLabel});

  final User? user;
  final String perfilLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountRow(label: 'Nome', value: user?.name ?? '—'),
          const SizedBox(height: AppTheme.spacingMd),
          _AccountRow(label: 'Email', value: user?.email ?? '—'),
          const SizedBox(height: AppTheme.spacingMd),
          _AccountRow(label: 'Perfil', value: perfilLabel),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
