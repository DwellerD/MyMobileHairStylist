import '../../../core/models/app_user_role.dart';

/// Application-level authenticated user model.
///
/// This wraps the raw profile and role data from Supabase into one object that
/// routing and screens can reason about safely.
class AppUser {
  const AppUser({
    required this.profileId,
    required this.authUserId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.defaultMarketId,
    required this.defaultTerritoryId,
    required this.role,
  });

  final String profileId;
  final String authUserId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? defaultMarketId;
  final String? defaultTerritoryId;
  final AppUserRole? role;

  String get displayName {
    final parts = <String>[
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];

    if (parts.isEmpty) {
      return email;
    }

    return parts.join(' ');
  }

  bool get hasSupportedRole => role?.isSupportedInApp ?? false;

  String? get supportedHomeLocation => role?.homeLocation;

  factory AppUser.fromSupabase({
    required Map<String, dynamic> profile,
    required String? roleValue,
  }) {
    return AppUser(
      profileId: profile['id'] as String,
      authUserId: profile['auth_user_id'] as String,
      email: profile['email'] as String,
      firstName: profile['first_name'] as String?,
      lastName: profile['last_name'] as String?,
      defaultMarketId: profile['default_market_id'] as String?,
      defaultTerritoryId: profile['default_territory_id'] as String?,
      role: AppUserRoleParsing.fromDatabase(roleValue),
    );
  }
}