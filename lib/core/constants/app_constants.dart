/// Central place for app-wide strings and values that are reused.
///
/// Keeping these in one file makes it easier to rename labels later and avoids
/// scattering magic strings throughout the codebase.
abstract final class AppConstants {
  static const String appName = 'Mobile Hair Salon';
  static const String appTagline = 'Luxury hair services, delivered to your door.';
  static const String mockAuthNote =
      'Development mode is using a temporary mock role provider instead of real authentication.';

  /// ZIP codes enabled for the first launch market.
  ///
  /// This keeps service-area validation simple for the MVP while still allowing
  /// the booking flow to feel real. Later this can move fully into territories
  /// and server-side coverage logic.
  static const List<String> supportedServiceZipCodes = <String>[
    '84003',
    '84004',
    '84005',
    '84013',
    '84042',
    '84043',
    '84045',
    '84057',
    '84058',
    '84059',
    '84062',
    '84601',
    '84602',
    '84603',
    '84604',
    '84606',
    '84626',
    '84633',
    '84651',
    '84653',
    '84655',
    '84660',
    '84663',
    '84664',
  ];

  /// Version string written into policy acceptance rows during booking.
  static const String bookingPolicyVersion = 'mvp-2026-05';

  /// Short customer-facing summary shown before a booking request is submitted.
  static const String inHomeBookingPolicySummary =
      'By submitting a request, you confirm someone can let the stylist in, pets will be secured when needed, and changes may require admin approval under the cancellation policy.';

    /// Customer-facing copy for the temporary payment step.
    static const String bookingPaymentDisclaimer =
      'Payment is not processed in this MVP build. Your request will still be submitted for admin review, and a future Stripe Payment Sheet will collect deposits securely without exposing secret keys in the app.';

    /// Planned future payment provider for booking deposits and service balances.
    static const String plannedPaymentProvider = 'stripe';
}