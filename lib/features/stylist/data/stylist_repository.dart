import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/app_user.dart';
import '../domain/stylist_models.dart';

/// Repository provider for stylist-specific reads and writes.
final stylistRepositoryProvider = Provider<StylistRepository>((ref) {
  return StylistRepository(ref.watch(supabaseClientProvider));
});

/// Encapsulates all stylist-facing Supabase access away from widgets.
class StylistRepository {
  StylistRepository(this._client);

  final SupabaseClient? _client;

  Future<StylistProfileSummary> getCurrentStylistProfile({
    required AppUser appUser,
  }) async {
    final response = await _requireClient()
        .from('stylist_profiles')
        .select(
          'id, market_id, territory_id, bio, specialties, is_accepting_bookings, emergency_contact_name, emergency_contact_phone',
        )
        .eq('user_profile_id', appUser.profileId)
        .maybeSingle();

    if (response == null) {
      throw Exception('No stylist profile is linked to this account yet.');
    }

    return StylistProfileSummary(
      id: response['id'] as String,
      marketId: response['market_id'] as String?,
      territoryId: response['territory_id'] as String?,
      displayName: appUser.displayName,
      bio: response['bio'] as String?,
      specialties: ((response['specialties'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(growable: false),
      isAcceptingBookings: (response['is_accepting_bookings'] as bool?) ?? true,
      emergencyContactName: response['emergency_contact_name'] as String?,
      emergencyContactPhone: response['emergency_contact_phone'] as String?,
    );
  }

  Future<List<StylistAppointmentSummary>> getTodayAppointments({
    required StylistProfileSummary stylistProfile,
  }) async {
    final appointments = await _loadAssignedAppointments(stylistProfileId: stylistProfile.id);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return appointments
        .where((appointment) =>
            !appointment.startsAt.isBefore(startOfDay) &&
            appointment.startsAt.isBefore(endOfDay))
        .toList(growable: false);
  }

  Future<List<StylistAppointmentSummary>> getScheduleAppointments({
    required StylistProfileSummary stylistProfile,
  }) async {
    return _loadAssignedAppointments(stylistProfileId: stylistProfile.id);
  }

  Future<List<ClaimableAppointmentSummary>> getClaimableAppointments({
    required StylistProfileSummary stylistProfile,
  }) async {
    if (stylistProfile.marketId == null) {
      return const <ClaimableAppointmentSummary>[];
    }

    final response = await _requireClient().from('appointments').select('''
id,
status,
requested_start_at,
scheduled_start_at,
estimated_duration_minutes,
territory_id,
requested_stylist_profile_id,
address:addresses!appointments_address_id_fkey(line1, city, state, postal_code),
customer_profile:customer_profiles!appointments_customer_profile_id_fkey(
  user_profile:user_profiles!customer_profiles_user_profile_id_fkey(first_name)
),
appointment_services(quantity, service:services(name, duration_minutes))
''').eq('market_id', stylistProfile.marketId!).isFilter(
          'assigned_stylist_profile_id',
          null,
        ).inFilter('status', <String>['requested', 'approved']);

    return (response as List<dynamic>)
        .map((dynamic row) => row as Map<String, dynamic>)
        .where((row) {
          final territoryId = row['territory_id'] as String?;
          final requestedStylistProfileId =
              row['requested_stylist_profile_id'] as String?;
          final matchesTerritory = territoryId == null ||
              stylistProfile.territoryId == null ||
              territoryId == stylistProfile.territoryId;
          final matchesRequest = requestedStylistProfileId == null ||
              requestedStylistProfileId == stylistProfile.id;
          return matchesTerritory && matchesRequest;
        })
        .map(_mapClaimableAppointmentSummary)
        .toList(growable: false)
      ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
  }

  Future<void> claimAppointmentRequest({
    required String appointmentId,
  }) async {
    await _requireClient().rpc(
      'claim_appointment_request',
      params: <String, dynamic>{
        'p_appointment_id': appointmentId,
      },
    );
  }

  Future<void> acceptAssignedAppointment({
    required String appointmentId,
  }) async {
    await _requireClient().rpc(
      'stylist_respond_to_assigned_appointment',
      params: <String, dynamic>{
        'p_appointment_id': appointmentId,
        'p_response': 'accept',
      },
    );
  }

  Future<void> declineAssignedAppointment({
    required String appointmentId,
  }) async {
    await _requireClient().rpc(
      'stylist_respond_to_assigned_appointment',
      params: <String, dynamic>{
        'p_appointment_id': appointmentId,
        'p_response': 'decline',
      },
    );
  }

  Future<StylistAppointmentDetail> getAppointmentDetail({
    required String appointmentId,
  }) async {
    final response = await _requireClient().from('appointments').select('''
id,
market_id,
territory_id,
assigned_stylist_profile_id,
status,
requested_start_at,
scheduled_start_at,
estimated_duration_minutes,
customer_notes,
address:addresses!appointments_address_id_fkey(line1, city, state, postal_code, access_notes),
customer_profile:customer_profiles!appointments_customer_profile_id_fkey(
  user_profile:user_profiles!customer_profiles_user_profile_id_fkey(first_name)
),
appointment_participants(
  participant_notes,
  sensory_notes_snapshot,
  household_member:household_members(first_name, last_name, general_notes, sensory_notes, hair_notes)
),
appointment_services(
  quantity,
  duration_snapshot_minutes,
  line_notes,
  service:services(name, duration_minutes)
),
appointment_photos(id, photo_type, caption, storage_path, created_at),
internal_notes(id, note_type, note_body, created_at),
check_ins(id, event_type, status, check_in_at, check_out_at, created_at, event_notes)
''').eq('id', appointmentId).single();

    final address = response['address'] as Map<String, dynamic>?;
    final customerProfile = response['customer_profile'] as Map<String, dynamic>?;
    final userProfile = customerProfile?['user_profile'] as Map<String, dynamic>?;
    final participants = ((response['appointment_participants'] as List<dynamic>?) ?? const <dynamic>[])
        .map(_mapParticipant)
        .toList(growable: false);
    final services = ((response['appointment_services'] as List<dynamic>?) ?? const <dynamic>[])
        .map(_mapServiceLine)
        .toList(growable: false);
    final photos = ((response['appointment_photos'] as List<dynamic>?) ?? const <dynamic>[])
        .map(_mapPhoto)
        .toList(growable: false);
    final internalNotes = ((response['internal_notes'] as List<dynamic>?) ?? const <dynamic>[])
        .map(_mapInternalNote)
        .toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final checkInEvents = ((response['check_ins'] as List<dynamic>?) ?? const <dynamic>[])
        .map(_mapCheckInEvent)
        .toList(growable: false)
      ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));

    return StylistAppointmentDetail(
      id: response['id'] as String,
      status: response['status'] as String,
      customerFirstName: (userProfile?['first_name'] as String?)?.trim().isNotEmpty == true
          ? userProfile!['first_name'] as String
          : 'Customer',
      dateTime: _parseDateTime(
        response['scheduled_start_at'] as String? ?? response['requested_start_at'] as String,
      ),
      address: _formatAddress(
        line1: address?['line1'] as String?,
        city: address?['city'] as String?,
        state: address?['state'] as String?,
        postalCode: address?['postal_code'] as String?,
      ),
      accessNotes: address?['access_notes'] as String?,
      customerNotes: response['customer_notes'] as String?,
      estimatedDurationMinutes: (response['estimated_duration_minutes'] as int?) ??
          services.fold<int>(0, (total, service) => total + service.durationMinutes),
      participants: participants,
      services: services,
      photos: photos,
      internalNotes: internalNotes,
      checkInEvents: checkInEvents,
      marketId: response['market_id'] as String?,
      territoryId: response['territory_id'] as String?,
      assignedStylistProfileId: response['assigned_stylist_profile_id'] as String?,
    );
  }

  Future<List<StylistSafetyEventSummary>> getRecentSafetyEvents({
    required StylistProfileSummary stylistProfile,
  }) async {
    final response = await _requireClient().from('safety_events').select('''
id,
appointment_id,
event_type,
status,
details,
created_at,
appointment:appointments!safety_events_appointment_id_fkey(
  customer_profile:customer_profiles!appointments_customer_profile_id_fkey(
    user_profile:user_profiles!customer_profiles_user_profile_id_fkey(first_name)
  )
)
''').eq('stylist_profile_id', stylistProfile.id).order('created_at', ascending: false).limit(10);

    return (response as List<dynamic>)
        .map((dynamic row) {
          final appointment = row['appointment'] as Map<String, dynamic>?;
          final customerProfile = appointment?['customer_profile'] as Map<String, dynamic>?;
          final userProfile = customerProfile?['user_profile'] as Map<String, dynamic>?;

          return StylistSafetyEventSummary(
            id: row['id'] as String,
            appointmentId: row['appointment_id'] as String?,
            customerFirstName: (userProfile?['first_name'] as String?)?.trim().isNotEmpty == true
                ? userProfile!['first_name'] as String
                : 'Customer',
            eventType: row['event_type'] as String,
            status: row['status'] as String,
            details: row['details'] as String,
            createdAt: _parseDateTime(row['created_at'] as String),
          );
        })
        .toList(growable: false);
  }

  Future<void> createCheckIn({
    required String appointmentId,
    required AppUser appUser,
    required StylistProfileSummary stylistProfile,
    String? note,
  }) async {
    final appointmentScope = await _loadAppointmentScope(appointmentId);
    await _requireClient().from('check_ins').insert({
      'appointment_id': appointmentId,
      'market_id': appointmentScope.marketId,
      'territory_id': appointmentScope.territoryId,
      'assigned_stylist_profile_id': stylistProfile.id,
      'event_type': 'check_in',
      'status': 'checked_in',
      'check_in_at': DateTime.now().toIso8601String(),
      'event_notes': _nullableText(note),
      'check_in_notes': _nullableText(note),
    });

    await _requireClient().from('appointments').update({
      'status': 'in_progress',
    }).eq('id', appointmentId);
  }

  Future<void> createCheckOut({
    required String appointmentId,
    required StylistProfileSummary stylistProfile,
    String? note,
  }) async {
    final appointmentScope = await _loadAppointmentScope(appointmentId);
    await _requireClient().from('check_ins').insert({
      'appointment_id': appointmentId,
      'market_id': appointmentScope.marketId,
      'territory_id': appointmentScope.territoryId,
      'assigned_stylist_profile_id': stylistProfile.id,
      'event_type': 'check_out',
      'status': 'checked_out',
      'check_out_at': DateTime.now().toIso8601String(),
      'event_notes': _nullableText(note),
      'check_out_notes': _nullableText(note),
    });
  }

  Future<void> markAppointmentComplete({
    required String appointmentId,
  }) async {
    await _requireClient().from('appointments').update({
      'status': 'completed',
      'scheduled_end_at': DateTime.now().toIso8601String(),
    }).eq('id', appointmentId);
  }

  Future<void> addInternalNote({
    required String appointmentId,
    required AppUser appUser,
    required String noteBody,
  }) async {
    final appointmentScope = await _loadAppointmentScope(appointmentId);
    await _requireClient().from('internal_notes').insert({
      'appointment_id': appointmentId,
      'market_id': appointmentScope.marketId,
      'territory_id': appointmentScope.territoryId,
      'author_user_profile_id': appUser.profileId,
      'note_type': 'service',
      'note_body': noteBody.trim(),
      'is_admin_only': false,
    });
  }

  Future<void> triggerSafetyEvent({
    required String appointmentId,
    required AppUser appUser,
    required StylistProfileSummary stylistProfile,
  }) async {
    final appointmentScope = await _loadAppointmentScope(appointmentId);

    // TODO: Capture GPS coordinates and device context when mobile permissions
    // are available so admins receive a precise field-safety breadcrumb.
    // TODO: Trigger push notifications to scoped admins and the on-call safety
    // contact when the production alerting pipeline is in place.
    // TODO: Escalate confirmed SOS events into a formal emergency workflow with
    // acknowledgement tracking and post-incident resolution steps.
    await _requireClient().from('safety_events').insert({
      'appointment_id': appointmentId,
      'market_id': appointmentScope.marketId,
      'territory_id': appointmentScope.territoryId,
      'stylist_profile_id': stylistProfile.id,
      'reported_by_user_profile_id': appUser.profileId,
      'event_type': 'sos_placeholder',
      'status': 'open',
      'severity': 5,
      'details': 'Stylist triggered the MVP SOS placeholder from the mobile app.',
    });
  }

  Future<List<StylistAppointmentSummary>> _loadAssignedAppointments({
    required String stylistProfileId,
  }) async {
    final response = await _requireClient().from('appointments').select('''
id,
status,
requested_start_at,
scheduled_start_at,
estimated_duration_minutes,
address:addresses!appointments_address_id_fkey(line1, city, state, postal_code),
customer_profile:customer_profiles!appointments_customer_profile_id_fkey(
  user_profile:user_profiles!customer_profiles_user_profile_id_fkey(first_name)
),
appointment_services(quantity, service:services(name, duration_minutes)),
check_ins(event_type, created_at)
''').eq('assigned_stylist_profile_id', stylistProfileId);

    final appointments = (response as List<dynamic>)
        .map((dynamic row) => _mapAppointmentSummary(row as Map<String, dynamic>))
        .toList(growable: false)
      ..sort((left, right) => left.startsAt.compareTo(right.startsAt));

    return appointments;
  }

  Future<_AppointmentScope> _loadAppointmentScope(String appointmentId) async {
    final response = await _requireClient()
        .from('appointments')
        .select('market_id, territory_id')
        .eq('id', appointmentId)
        .single();

    return _AppointmentScope(
      marketId: response['market_id'] as String?,
      territoryId: response['territory_id'] as String?,
    );
  }

  StylistAppointmentSummary _mapAppointmentSummary(Map<String, dynamic> row) {
    final address = row['address'] as Map<String, dynamic>?;
    final customerProfile = row['customer_profile'] as Map<String, dynamic>?;
    final userProfile = customerProfile?['user_profile'] as Map<String, dynamic>?;
    final serviceRows = (row['appointment_services'] as List<dynamic>? ?? const <dynamic>[]);
    final checkInRows = (row['check_ins'] as List<dynamic>? ?? const <dynamic>[]);
    final startsAt = _parseDateTime(
      row['scheduled_start_at'] as String? ?? row['requested_start_at'] as String,
    );

    return StylistAppointmentSummary(
      id: row['id'] as String,
      customerFirstName: (userProfile?['first_name'] as String?)?.trim().isNotEmpty == true
          ? userProfile!['first_name'] as String
          : 'Customer',
      cityOrArea: (address?['city'] as String?)?.trim().isNotEmpty == true
          ? address!['city'] as String
          : 'Area not set',
      serviceSummary: _serviceSummaryFromRows(serviceRows),
      status: row['status'] as String,
      checkInStatus: _checkInStatusFromRows(checkInRows),
      startsAt: startsAt,
      addressSummary: _formatAddress(
        line1: address?['line1'] as String?,
        city: address?['city'] as String?,
        state: address?['state'] as String?,
        postalCode: address?['postal_code'] as String?,
      ),
      estimatedDurationMinutes: (row['estimated_duration_minutes'] as int?) ??
          _estimatedDurationFromRows(serviceRows),
    );
  }

  ClaimableAppointmentSummary _mapClaimableAppointmentSummary(
    Map<String, dynamic> row,
  ) {
    final address = row['address'] as Map<String, dynamic>?;
    final customerProfile = row['customer_profile'] as Map<String, dynamic>?;
    final userProfile = customerProfile?['user_profile'] as Map<String, dynamic>?;
    final serviceRows =
        (row['appointment_services'] as List<dynamic>? ?? const <dynamic>[]);
    final startsAt = _parseDateTime(
      row['scheduled_start_at'] as String? ?? row['requested_start_at'] as String,
    );

    return ClaimableAppointmentSummary(
      id: row['id'] as String,
      customerFirstName: (userProfile?['first_name'] as String?)?.trim().isNotEmpty ==
              true
          ? userProfile!['first_name'] as String
          : 'Customer',
      cityOrArea: (address?['city'] as String?)?.trim().isNotEmpty == true
          ? address!['city'] as String
          : 'Area not set',
      serviceSummary: _serviceSummaryFromRows(serviceRows),
      status: row['status'] as String,
      startsAt: startsAt,
      addressSummary: _formatAddress(
        line1: address?['line1'] as String?,
        city: address?['city'] as String?,
        state: address?['state'] as String?,
        postalCode: address?['postal_code'] as String?,
      ),
      estimatedDurationMinutes: (row['estimated_duration_minutes'] as int?) ??
          _estimatedDurationFromRows(serviceRows),
      requestedStylist: row['requested_stylist_profile_id'] != null,
    );
  }

  StylistAppointmentParticipant _mapParticipant(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    final householdMember = row['household_member'] as Map<String, dynamic>?;
    final firstName = (householdMember?['first_name'] as String?) ?? 'Household';
    final lastName = householdMember?['last_name'] as String?;
    return StylistAppointmentParticipant(
      name: [firstName, if (lastName != null && lastName.trim().isNotEmpty) lastName.trim()].join(' '),
      generalNotes: (row['participant_notes'] as String?) ?? householdMember?['general_notes'] as String?,
      sensoryNotes: (row['sensory_notes_snapshot'] as String?) ?? householdMember?['sensory_notes'] as String?,
      hairNotes: householdMember?['hair_notes'] as String?,
    );
  }

  StylistAppointmentServiceLine _mapServiceLine(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    final service = row['service'] as Map<String, dynamic>?;
    return StylistAppointmentServiceLine(
      name: (service?['name'] as String?) ?? 'Service',
      quantity: (row['quantity'] as int?) ?? 1,
      durationMinutes: (row['duration_snapshot_minutes'] as int?) ??
          ((service?['duration_minutes'] as int?) ?? 0),
      lineNotes: row['line_notes'] as String?,
    );
  }

  StylistAppointmentPhoto _mapPhoto(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    return StylistAppointmentPhoto(
      id: row['id'] as String,
      photoType: row['photo_type'] as String,
      caption: row['caption'] as String?,
      storagePath: row['storage_path'] as String,
      createdAt: _parseDateTime(row['created_at'] as String),
    );
  }

  StylistInternalNote _mapInternalNote(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    return StylistInternalNote(
      id: row['id'] as String,
      noteType: row['note_type'] as String,
      noteBody: row['note_body'] as String,
      createdAt: _parseDateTime(row['created_at'] as String),
    );
  }

  StylistCheckInEvent _mapCheckInEvent(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    final recordedAt = row['check_in_at'] as String? ??
        row['check_out_at'] as String? ??
        row['created_at'] as String;
    return StylistCheckInEvent(
      id: row['id'] as String,
      eventType: row['event_type'] as String,
      status: row['status'] as String,
      recordedAt: _parseDateTime(recordedAt),
      eventNotes: row['event_notes'] as String?,
    );
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw Exception(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY before testing stylist flows.',
      );
    }

    return _client;
  }

  DateTime _parseDateTime(String value) => DateTime.parse(value).toLocal();

  String _formatAddress({
    required String? line1,
    required String? city,
    required String? state,
    required String? postalCode,
  }) {
    final parts = <String>[
      if (line1 != null && line1.trim().isNotEmpty) line1.trim(),
      [
        if (city != null && city.trim().isNotEmpty) city.trim(),
        if (state != null && state.trim().isNotEmpty) state.trim(),
      ].join(', ').replaceAll(RegExp(r'^, |, $'), ''),
      if (postalCode != null && postalCode.trim().isNotEmpty) postalCode.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);

    return parts.join(' ');
  }

  String _serviceSummaryFromRows(List<dynamic> serviceRows) {
    if (serviceRows.isEmpty) {
      return 'Services pending review';
    }

    return serviceRows
        .take(2)
        .map((dynamic raw) {
          final row = raw as Map<String, dynamic>;
          final service = row['service'] as Map<String, dynamic>?;
          return (service?['name'] as String?) ?? 'Service';
        })
        .join(', ');
  }

  int _estimatedDurationFromRows(List<dynamic> serviceRows) {
    return serviceRows.fold<int>(0, (total, dynamic raw) {
      final row = raw as Map<String, dynamic>;
      final service = row['service'] as Map<String, dynamic>?;
      return total + ((service?['duration_minutes'] as int?) ?? 0);
    });
  }

  String _checkInStatusFromRows(List<dynamic> rows) {
    final hasCheckOut = rows.any((dynamic raw) {
      final row = raw as Map<String, dynamic>;
      return row['event_type'] == 'check_out';
    });
    if (hasCheckOut) {
      return 'Checked out';
    }

    final hasCheckIn = rows.any((dynamic raw) {
      final row = raw as Map<String, dynamic>;
      return row['event_type'] == 'check_in';
    });
    if (hasCheckIn) {
      return 'Checked in';
    }

    return 'Not started';
  }

  String? _nullableText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }
}

class _AppointmentScope {
  const _AppointmentScope({
    required this.marketId,
    required this.territoryId,
  });

  final String? marketId;
  final String? territoryId;
}