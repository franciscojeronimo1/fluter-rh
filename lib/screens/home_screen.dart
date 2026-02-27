import 'package:flutter/material.dart';

import '../components/components.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import 'estoque_screen.dart';
import 'ponto_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getStoredUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) widget.onLogout?.call();
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
            const SizedBox(height: AppTheme.spacing2xl),
            const SectionTitle(title: 'Atalhos'),
            const SizedBox(height: AppTheme.spacingMd),
            ShortcutCard(
              title: 'Bater Ponto',
              subtitle: 'Registrar entrada e saída',
              icon: Icons.schedule,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PontoScreen()),
              ),
            ),
            const SizedBox(height: 10),
            ShortcutCard(
              title: 'Estoque',
              subtitle: 'Controle de produtos e estoque baixo',
              icon: Icons.inventory_2_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EstoqueScreen()),
              ),
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
