import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/app_user.dart';
import '../domain/stylist_application.dart';

final stylistApplicationRepositoryProvider =
    Provider<StylistApplicationRepository>((ref) {
  return StylistApplicationRepository(ref.watch(supabaseClientProvider));
});

class StylistApplicationRepository {
  StylistApplicationRepository(this._client);

  final SupabaseClient? _client;

  Future<StylistApplication?> getCurrentApplication({
    required AppUser appUser,
  }) async {
    final response = await _requireClient()
        .from('stylist_applications')
        .select(
          'id, user_profile_id, phone, city, state, license_number, years_experience, specialties, portfolio_url, motivation, status, market_id, territory_id, created_at, reviewed_at, reviewer_notes',
        )
        .eq('user_profile_id', appUser.profileId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _mapApplication(
      response,
      applicantName: appUser.displayName,
      email: appUser.email,
    );
  }

  Future<StylistApplication> submitApplication({
    required AppUser appUser,
    required String phone,
    required String city,
    required String stateCode,
    required String licenseNumber,
    required int? yearsExperience,
    required List<String> specialties,
    required String? portfolioUrl,
    required String motivation,
  }) async {
    final response = await _requireClient()
        .from('stylist_applications')
        .insert({
          'user_profile_id': appUser.profileId,
          'market_id': appUser.defaultMarketId,
          'territory_id': appUser.defaultTerritoryId,
          'phone': _nullableText(phone),
          'city': _nullableText(city),
          'state': _nullableText(stateCode)?.toUpperCase(),
          'license_number': _nullableText(licenseNumber),
          'years_experience': yearsExperience,
          'specialties': specialties,
          'portfolio_url': _nullableText(portfolioUrl),
          'motivation': motivation.trim(),
        })
        .select(
          'id, user_profile_id, phone, city, state, license_number, years_experience, specialties, portfolio_url, motivation, status, market_id, territory_id, created_at, reviewed_at, reviewer_notes',
        )
        .single();

    return _mapApplication(
      response,
      applicantName: appUser.displayName,
      email: appUser.email,
    );
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw Exception('Supabase is not configured.');
    }

    return _client;
  }

  StylistApplication _mapApplication(
    Map<String, dynamic> row, {
    required String applicantName,
    required String email,
  }) {
    return StylistApplication(
      id: row['id'] as String,
      userProfileId: row['user_profile_id'] as String,
      applicantName: applicantName,
      email: email,
      phone: row['phone'] as String?,
      city: row['city'] as String?,
      stateCode: row['state'] as String?,
      licenseNumber: row['license_number'] as String?,
      yearsExperience: row['years_experience'] as int?,
      specialties: ((row['specialties'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(growable: false),
      portfolioUrl: row['portfolio_url'] as String?,
      motivation: row['motivation'] as String?,
      status: row['status'] as String,
      marketId: row['market_id'] as String?,
      territoryId: row['territory_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      reviewedAt: row['reviewed_at'] == null
          ? null
          : DateTime.parse(row['reviewed_at'] as String),
      reviewerNotes: row['reviewer_notes'] as String?,
    );
  }

  String? _nullableText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}