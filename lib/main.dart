import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/payments/stripe_config.dart';
import 'core/supabase/supabase_client_provider.dart';

/// Starts the Flutter application inside a [ProviderScope] so Riverpod
/// providers can be read anywhere in the widget tree.
///
/// Supabase uses `--dart-define` values so secrets are never hardcoded into the
/// repository. If the values are missing, the app still boots and shows a clear
/// configuration message in the auth flow.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final stripeSupportedPlatform =
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  if (stripeSupportedPlatform && StripeConfig.isConfigured) {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  }

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const ProviderScope(child: HairSalonApp()));
}
