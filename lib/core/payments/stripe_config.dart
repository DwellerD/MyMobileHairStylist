abstract final class StripeConfig {
  static const String publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  static bool get isConfigured => publishableKey.isNotEmpty;
}