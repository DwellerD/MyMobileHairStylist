import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';

/// Repository responsible for all Supabase auth and profile queries.
///
/// Widgets should never talk to Supabase directly. They ask providers, and the
/// providers delegate all remote work to this repository.
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Session? get currentSession => _client?.auth.currentSession;

  /// Emits the current session first, then future auth state changes.
  Stream<Session?> authStateChanges() async* {
    yield currentSession;

    if (_client == null) {
      return;
    }

    yield* _client.auth.onAuthStateChange.map((event) => event.session);
  }

  /// Signs a user in with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();

    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw AuthRepositoryException(_friendlyAuthMessage(error.message));
    } catch (_) {
      throw const AuthRepositoryException(
        'We could not log you in right now. Please try again.',
      );
    }
  }

  /// Signs a new customer up.
  ///
  /// The companion SQL migration creates `user_profiles`, `user_roles`, and
  /// `customer_profiles` rows automatically when a new auth user is created.
  Future<void> signUpCustomer({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final client = _requireClient();
    final defaultMarketId = await _fetchDefaultMarketId();

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'default_market_id': defaultMarketId,
        },
      );

      if (response.user == null) {
        throw const AuthRepositoryException(
          'Your account could not be created. Please try again.',
        );
      }

      // If a session exists immediately, confirm the profile rows are readable.
      if (response.session != null) {
        final appUser = await getCurrentAppUser();

        if (appUser == null) {
          throw const AuthRepositoryException(
            'Your account was created, but we could not finish setting up your profile. Please contact support.',
          );
        }
      }
    } on AuthRepositoryException {
      rethrow;
    } on AuthException catch (error) {
      throw AuthRepositoryException(_friendlyAuthMessage(error.message));
    } catch (_) {
      throw const AuthRepositoryException(
        'We could not create your account right now. Please try again.',
      );
    }
  }

  /// Signs the current user out of the app.
  Future<void> signOut() async {
    final client = _requireClient();

    try {
      await client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthRepositoryException(_friendlyAuthMessage(error.message));
    } catch (_) {
      throw const AuthRepositoryException(
        'We could not log you out right now. Please try again.',
      );
    }
  }

  /// Fetches the current authenticated app user profile and primary role.
  Future<AppUser?> getCurrentAppUser() async {
    final client = _requireClient();
    final authUser = client.auth.currentUser;

    if (authUser == null) {
      return null;
    }

    try {
      final profile = await client
          .from('user_profiles')
          .select(
            'id, auth_user_id, email, first_name, last_name, default_market_id, default_territory_id',
          )
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (profile == null) {
        return null;
      }

      final roles = await client
          .from('user_roles')
          .select('role, is_primary')
          .eq('user_profile_id', profile['id'] as String)
          .eq('status', 'active')
          .order('is_primary', ascending: false)
          .limit(1);

      final roleValue = roles.isEmpty ? null : roles.first['role'] as String?;

      return AppUser.fromSupabase(
        profile: profile,
        roleValue: roleValue,
      );
    } on PostgrestException catch (_) {
      throw const AuthRepositoryException(
        'We could not load your profile. Please try again.',
      );
    }
  }

  Future<String> _fetchDefaultMarketId() async {
    final client = _requireClient();

    final rows = await client
        .from('markets')
        .select('id, status')
        .inFilter('status', <String>['active', 'launching'])
        .order('created_at')
        .limit(1);

    if (rows.isEmpty) {
      throw const AuthRepositoryException(
        'This app is not ready for signup yet because no market has been configured.',
      );
    }

    return rows.first['id'] as String;
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw const AuthRepositoryException(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY to your Flutter run configuration.',
      );
    }

    return _client;
  }

  String _friendlyAuthMessage(String originalMessage) {
    if (originalMessage.toLowerCase().contains('invalid login credentials')) {
      return 'The email or password is incorrect.';
    }

    if (originalMessage.toLowerCase().contains('user already registered')) {
      return 'An account with that email already exists.';
    }

    return originalMessage;
  }
}

/// Human-readable exception surfaced back to the UI.
class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}