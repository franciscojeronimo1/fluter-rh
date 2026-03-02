/// Exceção lançada quando o plano FREE tenta acessar recurso PREMIUM.
class SubscriptionRequiredException implements Exception {
  SubscriptionRequiredException();

  @override
  String toString() =>
      'Assinatura Premium necessária. Faça upgrade para acessar este recurso.';
}
