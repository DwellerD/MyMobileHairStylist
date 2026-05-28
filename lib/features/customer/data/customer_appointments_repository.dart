import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/app_user.dart';
import '../domain/customer_appointment_summary.dart';

final customerAppointmentsRepositoryProvider = Provider<CustomerAppointmentsRepository>((ref) {
  return CustomerAppointmentsRepository(ref.watch(supabaseClientProvider));
});

class CustomerAppointmentsRepository {
  CustomerAppointmentsRepository(this._client);

  final SupabaseClient? _client;

  Future<List<CustomerAppointmentSummary>> loadAppointments({
    required AppUser appUser,
  }) async {
    final customerProfile = await _requireClient()
        .from('customer_profiles')
        .select('id')
        .eq('user_profile_id', appUser.profileId)
        .maybeSingle();

    if (customerProfile == null) {
      return const <CustomerAppointmentSummary>[];
    }

    final response = await _requireClient().from('appointments').select('''
id,
status,
requested_start_at,
scheduled_start_at,
address:addresses!appointments_address_id_fkey(line1, city, state, postal_code),
appointment_participants(
  household_member:household_members(first_name, last_name)
),
appointment_services(
  service:services(name)
)
''').eq('customer_profile_id', customerProfile['id'] as String);

    final appointments = (response as List<dynamic>)
        .map(
          (dynamic raw) => _mapAppointment(raw as Map<String, dynamic>),
        )
        .toList(growable: false);

    appointments.sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return appointments;
  }

  CustomerAppointmentSummary _mapAppointment(Map<String, dynamic> row) {
    final address = row['address'] as Map<String, dynamic>?;
    final participantRows = (row['appointment_participants'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final serviceRows =
        (row['appointment_services'] as List<dynamic>? ?? const <dynamic>[]).cast<Map<String, dynamic>>();

    final participantNames = participantRows
        .map((participant) {
          final householdMember = participant['household_member'] as Map<String, dynamic>?;
          final firstName = (householdMember?['first_name'] as String?)?.trim();
          final lastName = (householdMember?['last_name'] as String?)?.trim();
          return [
            if (firstName != null && firstName.isNotEmpty) firstName,
            if (lastName != null && lastName.isNotEmpty) lastName,
          ].join(' ');
        })
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final serviceNames = serviceRows
        .map((serviceLine) {
          final service = serviceLine['service'] as Map<String, dynamic>?;
          return (service?['name'] as String?)?.trim() ?? '';
        })
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return CustomerAppointmentSummary(
      id: row['id'] as String,
      status: row['status'] as String? ?? 'pending_assignment',
      startsAt: DateTime.parse(
        (row['scheduled_start_at'] as String?) ?? (row['requested_start_at'] as String),
      ),
      addressSummary: _formatAddress(
        line1: address?['line1'] as String?,
        city: address?['city'] as String?,
        state: address?['state'] as String?,
        postalCode: address?['postal_code'] as String?,
      ),
      serviceSummary: serviceNames.isEmpty ? 'Services to be confirmed' : serviceNames.join(', '),
      participantSummary:
          participantNames.isEmpty ? 'Household appointment' : participantNames.join(', '),
    );
  }

  String _formatAddress({
    required String? line1,
    required String? city,
    required String? state,
    required String? postalCode,
  }) {
    final segments = <String>[
      if (line1 != null && line1.trim().isNotEmpty) line1.trim(),
      [
        if (city != null && city.trim().isNotEmpty) city.trim(),
        if (state != null && state.trim().isNotEmpty) state.trim(),
      ].join(', ').trim(),
      if (postalCode != null && postalCode.trim().isNotEmpty) postalCode.trim(),
    ].where((segment) => segment.isNotEmpty).toList(growable: false);

    return segments.isEmpty ? 'Address pending review' : segments.join(' ');
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured yet. Add credentials to continue.');
    }

    return client;
  }
}