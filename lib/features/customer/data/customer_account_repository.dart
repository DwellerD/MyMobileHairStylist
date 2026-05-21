import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/app_user.dart';
import '../domain/customer_account_summary.dart';

final customerAccountRepositoryProvider = Provider<CustomerAccountRepository>((ref) {
  return CustomerAccountRepository(ref.watch(supabaseClientProvider));
});

class CustomerAccountRepository {
  CustomerAccountRepository(this._client);

  final SupabaseClient? _client;

  Future<CustomerAccountSummary> loadAccountSummary({
    required AppUser appUser,
  }) async {
    final customerProfile = await _requireClient()
        .from('customer_profiles')
        .select('preferred_contact_method, market_id')
        .eq('user_profile_id', appUser.profileId)
        .maybeSingle();

    final marketName = await _loadMarketName(
      customerProfile?['market_id'] as String? ?? appUser.defaultMarketId,
    );

    final households = await _requireClient()
        .from('households')
        .select('id, name')
        .eq('created_by_user_profile_id', appUser.profileId)
        .order('created_at');

    final householdRows = (households as List<dynamic>).cast<Map<String, dynamic>>();
    final householdIds = householdRows.map((row) => row['id'] as String).toList(growable: false);

    List<Map<String, dynamic>> memberRows = const <Map<String, dynamic>>[];
    List<Map<String, dynamic>> addressRows = const <Map<String, dynamic>>[];
    if (householdIds.isNotEmpty) {
      memberRows = ((await _requireClient()
                  .from('household_members')
                  .select(
                    'id, household_id, first_name, last_name, relationship_to_household, general_notes, sensory_notes, hair_notes',
                  )
                  .inFilter('household_id', householdIds)
                  .order('created_at'))
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

      addressRows = ((await _requireClient()
                  .from('addresses')
                  .select('id, household_id')
                  .inFilter('household_id', householdIds)) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }

    final policyRows = await _requireClient()
        .from('policy_acceptances')
        .select('id')
        .eq('user_profile_id', appUser.profileId);

    return CustomerAccountSummary(
      displayName: appUser.displayName,
      email: appUser.email,
      marketName: marketName,
      primaryHouseholdName: householdRows.isEmpty ? null : householdRows.first['name'] as String,
      primaryHouseholdId: householdRows.isEmpty ? null : householdRows.first['id'] as String,
      householdCount: householdRows.length,
      householdMemberCount: memberRows.length,
      addressCount: addressRows.length,
      policyAcceptanceCount: (policyRows as List<dynamic>).length,
      preferredContactMethod: customerProfile?['preferred_contact_method'] as String?,
      householdMembers: memberRows
          .map(
            (row) => CustomerHouseholdMemberSummary(
              id: row['id'] as String,
              name: _joinName(
                row['first_name'] as String?,
                row['last_name'] as String?,
              ),
              relationshipLabel: _relationshipLabel(
                row['relationship_to_household'] as String? ?? 'other',
              ),
              detail: _memberDetail(row),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<String?> _loadMarketName(String? marketId) async {
    if (marketId == null) {
      return null;
    }

    final market = await _requireClient()
        .from('markets')
        .select('name')
        .eq('id', marketId)
        .maybeSingle();

    return market?['name'] as String?;
  }

  String _joinName(String? firstName, String? lastName) {
    final parts = <String>[
      if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
    ];

    if (parts.isEmpty) {
      return 'Household member';
    }

    return parts.join(' ');
  }

  String _relationshipLabel(String rawValue) {
    switch (rawValue) {
      case 'self':
        return 'Self';
      case 'spouse_partner':
        return 'Spouse or partner';
      case 'child':
        return 'Child';
      default:
        return 'Household member';
    }
  }

  String _memberDetail(Map<String, dynamic> row) {
    final hairNotes = (row['hair_notes'] as String?)?.trim();
    if (hairNotes != null && hairNotes.isNotEmpty) {
      return 'Hair notes: $hairNotes';
    }

    final sensoryNotes = (row['sensory_notes'] as String?)?.trim();
    if (sensoryNotes != null && sensoryNotes.isNotEmpty) {
      return 'Sensory notes: $sensoryNotes';
    }

    final generalNotes = (row['general_notes'] as String?)?.trim();
    if (generalNotes != null && generalNotes.isNotEmpty) {
      return 'General notes: $generalNotes';
    }

    return _relationshipLabel(row['relationship_to_household'] as String? ?? 'other');
  }

  Future<void> updateHouseholdMember({
    required String memberId,
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? generalNotes,
    String? sensoryNotes,
    String? hairNotes,
  }) async {
    await _requireClient().from('household_members').update({
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      if (generalNotes != null) 'general_notes': generalNotes,
      if (sensoryNotes != null) 'sensory_notes': sensoryNotes,
      if (hairNotes != null) 'hair_notes': hairNotes,
    }).eq('id', memberId);
  }

  Future<void> createHouseholdMember({
    required String householdId,
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? generalNotes,
    String? sensoryNotes,
    String? hairNotes,
  }) async {
    await _requireClient().from('household_members').insert({
      'household_id': householdId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      if (generalNotes != null) 'general_notes': generalNotes,
      if (sensoryNotes != null) 'sensory_notes': sensoryNotes,
      if (hairNotes != null) 'hair_notes': hairNotes,
    });
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured yet. Add credentials to continue.');
    }

    return client;
  }
}