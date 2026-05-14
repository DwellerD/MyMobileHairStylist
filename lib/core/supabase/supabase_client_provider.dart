import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Compile-time Supabase configuration.
///
/// Values are read from Flutter `--dart-define` flags so no secrets are stored
/// in the repository.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

/// Tells the UI and repositories whether Supabase has been configured.
final supabaseConfiguredProvider = Provider<bool>((ref) {
  return SupabaseConfig.isConfigured;
});

/// Exposes the initialized Supabase client when configuration exists.
///
/// A nullable client keeps the app bootable in local development even before
/// environment variables are provided.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseConfig.isConfigured) {
    return null;
  }

  return Supabase.instance.client;
});