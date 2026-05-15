import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../auth/domain/app_user.dart';
import '../domain/booking_flow_state.dart';
import '../domain/service_area_validation.dart';

/// Exposes the booking repository for the customer request flow.
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(supabaseClientProvider));
});

/// Small repository that owns all booking-specific Supabase reads and writes.
class BookingRepository {
  BookingRepository(this._client);

  final SupabaseClient? _client;

  Future<BookingFlowState> loadInitialState({required AppUser appUser}) async {
    final household = await _getOrCreateHousehold(appUser);

    final addressesResponse = await _requireClient()
        .from('addresses')
        .select(
          'id, market_id, territory_id, label, line1, city, state, postal_code, service_area_status',
        )
        .eq('household_id', household.id)
        .order('created_at');

    final membersResponse = await _requireClient()
        .from('household_members')
        .select(
          'id, first_name, last_name, date_of_birth, general_notes, sensory_notes, hair_notes',
        )
        .eq('household_id', household.id)
        .order('created_at');

    final servicesResponse = await _requireClient()
        .from('services')
        .select(
          'id, name, description, duration_minutes, base_price_cents, allows_multiple_participants',
        )
        .eq('status', 'active')
        .or('market_id.eq.${appUser.defaultMarketId},market_id.is.null')
        .order('name');

    return BookingFlowState.seeded(
      householdId: household.id,
      householdName: household.name,
      addresses: (addressesResponse as List<dynamic>)
          .map(
            (dynamic row) {
              final rawPostalCode = row['postal_code'] as String;
              return BookingAddressOption(
                id: row['id'] as String,
                marketId: row['market_id'] as String?,
                territoryId: row['territory_id'] as String?,
                label: (row['label'] as String?)?.trim().isNotEmpty == true
                    ? row['label'] as String
                    : 'Saved address',
                line1: row['line1'] as String,
                city: row['city'] as String,
                state: row['state'] as String,
                postalCode: normalizeServiceAreaPostalCode(rawPostalCode),
                serviceAreaStatus: resolveServiceAreaStatus(
                  postalCode: rawPostalCode,
                  storedStatus: row['service_area_status'] as String?,
                ),
              );
            },
          )
          .toList(growable: false),
      householdMembers: (membersResponse as List<dynamic>)
          .map(
            (dynamic row) => BookingHouseholdMemberOption(
              id: row['id'] as String,
              firstName: row['first_name'] as String,
              lastName: row['last_name'] as String?,
              dateOfBirth: row['date_of_birth'] == null
                  ? null
                  : DateTime.tryParse(row['date_of_birth'] as String),
              generalNotes: row['general_notes'] as String?,
              sensoryNotes: row['sensory_notes'] as String?,
              hairNotes: row['hair_notes'] as String?,
            ),
          )
          .toList(growable: false),
      services: (servicesResponse as List<dynamic>)
          .map(
            (dynamic row) => BookingServiceOption(
              id: row['id'] as String,
              name: row['name'] as String,
              description: row['description'] as String?,
              durationMinutes: (row['duration_minutes'] as int?) ?? 0,
              basePriceCents: (row['base_price_cents'] as int?) ?? 0,
              allowsMultipleParticipants:
                  (row['allows_multiple_participants'] as bool?) ?? false,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<BookingAddressOption> createAddress({
    required AppUser appUser,
    required String householdId,
    required String label,
    required String line1,
    required String city,
    required String state,
    required String postalCode,
  }) async {
    final normalizedZip = normalizeServiceAreaPostalCode(postalCode);
    final addressResponse = await _requireClient()
        .from('addresses')
        .insert({
          'household_id': householdId,
          'market_id': appUser.defaultMarketId,
          'territory_id': appUser.defaultTerritoryId,
          'label': label.trim(),
          'line1': line1.trim(),
          'city': city.trim(),
          'state': state.trim().toUpperCase(),
          'postal_code': normalizedZip,
          'service_area_status': resolveServiceAreaStatus(postalCode: normalizedZip),
        })
        .select(
          'id, market_id, territory_id, label, line1, city, state, postal_code, service_area_status',
        )
        .single();

    return BookingAddressOption(
      id: addressResponse['id'] as String,
      marketId: addressResponse['market_id'] as String?,
      territoryId: addressResponse['territory_id'] as String?,
      label: addressResponse['label'] as String,
      line1: addressResponse['line1'] as String,
      city: addressResponse['city'] as String,
      state: addressResponse['state'] as String,
      postalCode: normalizeServiceAreaPostalCode(addressResponse['postal_code'] as String),
      serviceAreaStatus: resolveServiceAreaStatus(
        postalCode: addressResponse['postal_code'] as String,
        storedStatus: addressResponse['service_area_status'] as String?,
      ),
    );
  }

  Future<BookingHouseholdMemberOption> createHouseholdMember({
    required String householdId,
    required String firstName,
    required String? lastName,
    required DateTime? dateOfBirth,
    required String? generalNotes,
    required String? sensoryNotes,
    required String? hairNotes,
  }) async {
    final response = await _requireClient()
        .from('household_members')
        .insert({
          'household_id': householdId,
          'first_name': firstName.trim(),
          'last_name': lastName?.trim(),
          'date_of_birth': dateOfBirth?.toIso8601String().substring(0, 10),
          'general_notes': _nullableText(generalNotes),
          'sensory_notes': _nullableText(sensoryNotes),
          'hair_notes': _nullableText(hairNotes),
          'relationship_to_household': 'other',
        })
        .select(
          'id, first_name, last_name, date_of_birth, general_notes, sensory_notes, hair_notes',
        )
        .single();

    return BookingHouseholdMemberOption(
      id: response['id'] as String,
      firstName: response['first_name'] as String,
      lastName: response['last_name'] as String?,
      dateOfBirth: response['date_of_birth'] == null
          ? null
          : DateTime.tryParse(response['date_of_birth'] as String),
      generalNotes: response['general_notes'] as String?,
      sensoryNotes: response['sensory_notes'] as String?,
      hairNotes: response['hair_notes'] as String?,
    );
  }

  Future<String> submitBookingRequest({
    required AppUser appUser,
    required BookingFlowState bookingState,
  }) async {
    final address = bookingState.selectedAddress;
    if (address == null) {
      throw Exception('Choose a serviceable address before submitting.');
    }

    if (!address.isServiceable) {
      throw Exception('This address is outside the current launch area.');
    }

    if (bookingState.selectedMembers.isEmpty) {
      throw Exception('Choose at least one household member for this request.');
    }

    if (bookingState.selectedServices.isEmpty) {
      throw Exception('Choose at least one service before submitting.');
    }

    if (bookingState.preferredDate == null ||
        bookingState.preferredTimeWindow == null) {
      throw Exception('Choose a preferred date and arrival window first.');
    }

    if (bookingState.paymentStatus != 'not_started') {
      throw Exception('This MVP payment step should remain in placeholder mode only.');
    }

    final customerProfileId = await _loadCustomerProfileId(appUser.profileId);
    final requestedWindow = _windowBounds(
      bookingState.preferredDate!,
      bookingState.preferredTimeWindow!,
    );

    final appointment = await _requireClient()
        .from('appointments')
        .insert({
          'market_id': address.marketId ?? appUser.defaultMarketId,
          'territory_id': address.territoryId ?? appUser.defaultTerritoryId,
          'customer_profile_id': customerProfileId,
          'household_id': bookingState.householdId,
          'address_id': address.id,
          'requested_by_user_profile_id': appUser.profileId,
          'status': 'requested',
          'requested_start_at': requestedWindow.start.toIso8601String(),
          'requested_end_at': requestedWindow.end.toIso8601String(),
          'preferred_date': bookingState.preferredDate!.toIso8601String().substring(0, 10),
          'preferred_time_window': bookingState.preferredTimeWindow,
          'estimated_total_cents': bookingState.estimatedTotalCents,
          'estimated_duration_minutes': bookingState.estimatedDurationMinutes,
          'customer_notes': _nullableText(bookingState.customerNotes),
          'source': 'mobile_app',
        })
        .select('id, market_id, territory_id')
        .single();

    final appointmentId = appointment['id'] as String;
    final marketId = appointment['market_id'] as String?;
    final territoryId = appointment['territory_id'] as String?;

    final participantRows = await _requireClient()
        .from('appointment_participants')
        .insert(
          bookingState.selectedMembers
              .map(
                (member) => <String, dynamic>{
                  'appointment_id': appointmentId,
                  'household_member_id': member.id,
                  'status': 'requested',
                },
              )
              .toList(growable: false),
        )
        .select('id, household_member_id');

    final participantIdByMemberId = <String, String>{
      for (final dynamic row in (participantRows as List<dynamic>))
        row['household_member_id'] as String: row['id'] as String,
    };

    final singleParticipantId = bookingState.selectedMembers.length == 1
        ? participantIdByMemberId[bookingState.selectedMembers.first.id]
        : null;

    await _requireClient().from('appointment_services').insert(
          bookingState.selectedServices
              .map(
                (service) => <String, dynamic>{
                  'appointment_id': appointmentId,
                  'appointment_participant_id': singleParticipantId,
                  'service_id': service.id,
                  'quantity': 1,
                  'duration_snapshot_minutes': service.durationMinutes,
                  'price_snapshot_cents': service.basePriceCents,
                  'line_notes': bookingState.selectedMembers.length > 1
                      ? 'Submitted as a family request. Admin will confirm participant-to-service matching.'
                      : null,
                },
              )
              .toList(growable: false),
        );

    await _requireClient().from('policy_acceptances').insert([
      {
        'user_profile_id': appUser.profileId,
        'market_id': marketId,
        'territory_id': territoryId,
        'policy_type': 'cancellation',
        'policy_version': AppConstants.bookingPolicyVersion,
        'accepted_at': DateTime.now().toIso8601String(),
      },
      {
        'user_profile_id': appUser.profileId,
        'market_id': marketId,
        'territory_id': territoryId,
        'policy_type': 'safety',
        'policy_version': AppConstants.bookingPolicyVersion,
        'accepted_at': DateTime.now().toIso8601String(),
      },
    ]);

    for (final photo in bookingState.photoDrafts) {
      final sanitizedFileName = photo.fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final objectPath =
          '${appUser.authUserId}/$appointmentId/${DateTime.now().microsecondsSinceEpoch}_$sanitizedFileName';

      await _requireClient().storage
          .from('appointment-photos')
          .uploadBinary(objectPath, photo.bytes);

      await _requireClient().from('appointment_photos').insert({
        'appointment_id': appointmentId,
        'market_id': marketId,
        'territory_id': territoryId,
        'uploaded_by_user_profile_id': appUser.profileId,
        'photo_type': 'reference',
        'storage_bucket': 'appointment-photos',
        'storage_path': objectPath,
        'caption': 'Customer uploaded reference photo',
      });
    }

    // TODO: Replace the placeholder payment flow with a server-created Stripe
    // PaymentIntent. The mobile app should only receive a client secret from a
    // trusted backend function and should never see Stripe secret keys.
    // TODO: After a real PaymentIntent is created server-side, present Stripe
    // Payment Sheet from the dedicated payment step instead of continuing with
    // the current MVP bypass behavior.
    // TODO: Generate signed image URLs from a trusted backend function for
    // admins and assigned stylists instead of widening Storage read policies.

    return appointmentId;
  }

  Future<_HouseholdRecord> _getOrCreateHousehold(AppUser appUser) async {
    final existingHouseholds = await _requireClient()
        .from('households')
        .select('id, name')
        .eq('created_by_user_profile_id', appUser.profileId)
        .order('created_at')
        .limit(1);

    if ((existingHouseholds as List<dynamic>).isNotEmpty) {
      final household = existingHouseholds.first;
      return _HouseholdRecord(
        id: household['id'] as String,
        name: household['name'] as String,
      );
    }

    final createdHousehold = await _requireClient()
        .rpc(
          'provision_customer_household',
          params: {
            'target_user_profile_id': appUser.profileId,
            'target_market_id': appUser.defaultMarketId,
            'target_territory_id': appUser.defaultTerritoryId,
            'requested_household_name': '${appUser.displayName} Household',
          },
        )
        .single();

    return _HouseholdRecord(
      id: createdHousehold['household_id'] as String,
      name: createdHousehold['household_name'] as String,
    );
  }

  Future<String> _loadCustomerProfileId(String userProfileId) async {
    final response = await _requireClient()
        .from('customer_profiles')
        .select('id')
        .eq('user_profile_id', userProfileId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Your customer profile is still being prepared. Try again in a moment.');
    }

    return response['id'] as String;
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw Exception(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY before testing bookings.',
      );
    }

    return _client;
  }

  String? _nullableText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  _RequestedWindow _windowBounds(DateTime date, String timeWindowKey) {
    final window = findBookingTimeWindow(timeWindowKey);
    if (window == null) {
      throw Exception('Choose a valid arrival window.');
    }

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      window.startTime.hour,
      window.startTime.minute,
    );
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      window.endTime.hour,
      window.endTime.minute,
    );

    return _RequestedWindow(start: start, end: end);
  }
}

class _HouseholdRecord {
  const _HouseholdRecord({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class _RequestedWindow {
  const _RequestedWindow({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}