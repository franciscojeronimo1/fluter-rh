import 'package:flutter/material.dart';

import '../screens/subscription_screen.dart';

/// Exibe diálogo de upgrade quando o recurso requer plano Premium.
/// Oferece opções de voltar ou ir para a tela de assinatura.
void showUpgradeDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Plano Premium'),
      content: const Text(
        'Este recurso requer assinatura Premium. Faça upgrade para acessar.',
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pop();
          },
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
          },
          child: const Text('Ver plano'),
        ),
      ],
    ),
  );
}
