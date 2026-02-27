import 'package:flutter/material.dart';

import '../components/components.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess});

  final VoidCallback onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LoginHeader(),
                const SizedBox(height: AppTheme.spacing4xl),
                _LoginForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                  errorMessage: _errorMessage,
                  isLoading: _isLoading,
                  onSubmit: _submit,
                ),
                const SizedBox(height: 48),
                Text(
                  '© 2026 Sistema CGS. Todos os direitos reservados.',
                  style: AppTheme.captionSmall.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.business_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Text('Sistema CGS', style: AppTheme.heading1),
        const SizedBox(height: 6),
        Text(
          'Gerencie sua empresa de forma profissional',
          style: AppTheme.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    this.errorMessage,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(AppTheme.spacing4xl),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadowLarge,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entrar na sua conta', style: AppTheme.heading3),
            const SizedBox(height: 6),
            Text(
              'Digite suas credenciais para acessar o sistema',
              style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacing3xl),
            Text('Email', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: AppTheme.inputDecoration(
                hintText: 'seu@email.com',
                prefixIcon: Icons.mail_outline,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o email';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text('Senha', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: AppTheme.inputDecoration(
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a senha';
                return null;
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              ErrorBanner(message: errorMessage!),
            ],
            const SizedBox(height: AppTheme.spacing3xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: isLoading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Center(
              child: Text(
                'Sistema de gestão empresarial',
                style: AppTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
