import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/auth_repository.dart';
import '../../domain/app_user.dart';

/// Provides the auth repository so widgets stay free of Supabase details.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

/// Streams the current session and all future auth state changes.
///
/// The router watches this provider so navigation updates automatically after
/// sign-in and sign-out.
final authSessionProvider = StreamProvider<Session?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

/// Exposes the latest known session value in a synchronous-friendly way.
final currentSessionProvider = Provider<Session?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final streamedSession = ref.watch(authSessionProvider).valueOrNull;
  return streamedSession ?? repository.currentSession;
});

/// Loads the current authenticated app user profile and role.
///
/// This provider is the bridge between Supabase auth and role-based routing.
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final session = ref.watch(currentSessionProvider);

  if (session == null) {
    return null;
  }

  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentAppUser();
});

/// Handles sign-in, sign-up, and sign-out actions with loading and error state.
final authActionControllerProvider =
    AsyncNotifierProvider<AuthActionController, void>(AuthActionController.new);

class AuthActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Signs the user in and refreshes profile-dependent providers.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.signIn(email: email, password: password);
      ref.invalidate(currentAppUserProvider);
    });
  }

  /// Creates a default customer account.
  Future<void> signUpCustomer({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final repository = ref.read(authRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.signUpCustomer(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      ref.invalidate(currentAppUserProvider);
    });
  }

  /// Ends the current session.
  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.signOut();
      ref.invalidate(currentAppUserProvider);
    });
  }
}