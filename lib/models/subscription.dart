/// Resposta do endpoint GET /subscription
class Subscription {
  Subscription({
    required this.plan,
    required this.status,
    required this.isPremium,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      plan: json['plan'] as String? ?? 'FREE',
      status: json['status'] as String? ?? 'ACTIVE',
      isPremium: (json['isPremium'] ?? json['is_premium'] as bool?) ?? false,
    );
  }

  final String plan;
  final String status;
  final bool isPremium;

  String get planLabel => plan == 'PREMIUM' ? 'Premium' : 'Gratuito';
}
