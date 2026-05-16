import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/app_user.dart';
import '../domain/admin_models.dart';

/// Exposes the admin repository through Riverpod.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

/// Centralizes all admin-facing Supabase data access.
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient? _client;

  Future<AdminDashboardSummary> loadDashboardSummary() async {
    final appointments = await _loadAppointments();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayAppointments = appointments
        .where((appointment) =>
            !appointment.startsAt.isBefore(startOfDay) &&
            appointment.startsAt.isBefore(endOfDay))
        .toList(growable: false);

    final pendingBookingRequests = appointments
        .where((appointment) => appointment.status == 'requested')
        .length;

    final checkInAlerts = todayAppointments
        .where((appointment) =>
            appointment.checkInStatus == 'Not started' &&
            appointment.startsAt.isBefore(now))
        .map(
          (appointment) => AdminAlertSummary(
            title: 'Check-in alert',
            description:
                '${appointment.customerFirstName} has a past-due appointment without a recorded check-in.',
            appointmentId: appointment.id,
          ),
        )
        .toList(growable: false);

    final recentSafetyEvents = await _loadSafetyEvents(limit: 5);
    final revenuePlaceholderCents = appointments
        .where((appointment) => appointment.status == 'completed')
        .fold<int>(0, (sum, appointment) => sum + (appointment.estimatedTotalCents ?? 0));

    return AdminDashboardSummary(
      pendingBookingRequests: pendingBookingRequests,
      todayAppointments: todayAppointments,
      checkInAlerts: checkInAlerts,
      recentSafetyEvents: recentSafetyEvents,
      revenuePlaceholderCents: revenuePlaceholderCents,
    );
  }

  Future<List<AdminAppointmentSummary>> loadAppointments() {
    return _loadAppointments();
  }

  Future<AdminAppointmentDetail> loadAppointmentDetail(String appointmentId) async {
    final response = await _requireClient().from('appointments').select('''
id,
status,
preferred_date,
preferred_time_window,
estimated_total_cents,
customer_notes,
assigned_stylist_profile_id,
address:addresses!appointments_address_id_fkey(line1, city, state, postal_code, access_notes),
customer_profile:customer_profiles!appointments_customer_profile_id_fkey(
  user_profile:user_profiles!customer_profiles_user_profile_id_fkey(first_name, last_name)
),
assigned_stylist:stylist_profiles!appointments_assigned_stylist_profile_id_fkey(
  user_profile:user_profiles!stylist_profiles_user_profile_id_fkey(first_name, last_name)
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
check_ins(id, event_type, status, check_in_at, check_out_at, created_at, event_notes),
internal_notes(
  id,
  note_type,
  note_body,
  created_at,
  author:user_profiles!internal_notes_author_user_profile_id_fkey(first_name, last_name)
),
safety_events(id, appointment_id, event_type, status, details, created_at)
''').eq('id', appointmentId).single();

    final availableStylists = await loadStylistOptions();
    final address = response['address'] as Map<String, dynamic>?;
    final customerProfile = response['customer_profile'] as Map<String, dynamic>?;
    final customerUserProfile = customerProfile?['user_profile'] as Map<String, dynamic>?;
    final assignedStylist = response['assigned_stylist'] as Map<String, dynamic>?;
    final assignedStylistUser = assignedStylist?['user_profile'] as Map<String, dynamic>?;

    return AdminAppointmentDetail(
      id: response['id'] as String,
      status: response['status'] as String,
      customerName: _joinName(
        customerUserProfile?['first_name'] as String?,
        customerUserProfile?['last_name'] as String?,
      ),
      address: _formatAddress(
        line1: address?['line1'] as String?,
        city: address?['city'] as String?,
        state: address?['state'] as String?,
        postalCode: address?['postal_code'] as String?,
      ),
      participants: ((response['appointment_participants'] as List<dynamic>?) ?? const <dynamic>[])
          .map(_mapParticipant)
          .toList(growable: false),
      services: ((response['appointment_services'] as List<dynamic>?) ?? const <dynamic>[])
          .map(_mapServiceLine)
          .toList(growable: false),
      notes: [
        if ((response['customer_notes'] as String?)?.trim().isNotEmpty == true)
          response['customer_notes'] as String,
        if ((address?['access_notes'] as String?)?.trim().isNotEmpty == true)
          'Access notes: ${address!['access_notes'] as String}',
      ].join('\n\n').trim().isEmpty
          ? null
          : [
              if ((response['customer_notes'] as String?)?.trim().isNotEmpty == true)
                response['customer_notes'] as String,
              if ((address?['access_notes'] as String?)?.trim().isNotEmpty == true)
                'Access notes: ${address!['access_notes'] as String}',
            ].join('\n\n'),
      photos: ((response['appointment_photos'] as List<dynamic>?) ?? const <dynamic>[])
          .map(_mapPhoto)
          .toList(growable: false),
      preferredDate: response['preferred_date'] as String?,
      preferredTimeWindow: response['preferred_time_window'] as String?,
      estimatedTotalCents: response['estimated_total_cents'] as int?,
      assignedStylistName: _joinName(
        assignedStylistUser?['first_name'] as String?,
        assignedStylistUser?['last_name'] as String?,
      ),
      checkInEvents: ((response['check_ins'] as List<dynamic>?) ?? const <dynamic>[])
          .map(_mapCheckInEvent)
          .toList(growable: false)
        ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt)),
      internalNotes: ((response['internal_notes'] as List<dynamic>?) ?? const <dynamic>[])
          .map(_mapInternalNote)
          .toList(growable: false)
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt)),
      safetyEvents: ((response['safety_events'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic raw) => _mapSafetyEvent(
              raw as Map<String, dynamic>,
              customerName: _joinName(
                customerUserProfile?['first_name'] as String?,
                customerUserProfile?['last_name'] as String?,
              ),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt)),
      availableStylists: availableStylists,
    );
  }

  Future<List<AdminCustomerSummary>> loadCustomers() async {
    final customerProfiles = await _requireClient().from('customer_profiles').select('''
id,
status,
user_profile_id,
user_profile:user_profiles!customer_profiles_user_profile_id_fkey(first_name, last_name, email)
''');
    final households = await _requireClient().from('households').select('id, name, created_by_user_profile_id');
    final appointments = await _requireClient().from('appointments').select('id, customer_profile_id');

    final householdsByUserProfileId = <String, List<String>>{};
    for (final dynamic raw in (households as List<dynamic>)) {
      final row = raw as Map<String, dynamic>;
      final key = row['created_by_user_profile_id'] as String;
      householdsByUserProfileId.putIfAbsent(key, () => <String>[]).add(row['name'] as String);
    }

    final appointmentCountByCustomerProfileId = <String, int>{};
    for (final dynamic raw in (appointments as List<dynamic>)) {
      final row = raw as Map<String, dynamic>;
      final key = row['customer_profile_id'] as String;
      appointmentCountByCustomerProfileId.update(key, (count) => count + 1, ifAbsent: () => 1);
    }

    return (customerProfiles as List<dynamic>)
        .map((dynamic raw) {
          final row = raw as Map<String, dynamic>;
          final userProfile = row['user_profile'] as Map<String, dynamic>?;
          final userProfileId = row['user_profile_id'] as String;
          return AdminCustomerSummary(
            id: row['id'] as String,
            name: _joinName(
              userProfile?['first_name'] as String?,
              userProfile?['last_name'] as String?,
            ),
            email: (userProfile?['email'] as String?) ?? 'No email',
            status: row['status'] as String,
            householdNames: householdsByUserProfileId[userProfileId] ?? const <String>[],
            appointmentCount: appointmentCountByCustomerProfileId[row['id'] as String] ?? 0,
          );
        })
        .toList(growable: false);
  }

  Future<List<AdminStylistSummary>> loadStylists() async {
    final stylists = await _requireClient().from('stylist_profiles').select('''
id,
status,
market_id,
territory_id,
specialties,
is_accepting_bookings,
user_profile:user_profiles!stylist_profiles_user_profile_id_fkey(first_name, last_name)
''');
    final markets = await _requireClient().from('markets').select('id, name');
    final territories = await _requireClient().from('territories').select('id, name');
    final appointments = await _requireClient().from('appointments').select('id, assigned_stylist_profile_id');

    final marketNames = <String, String>{
      for (final dynamic raw in (markets as List<dynamic>))
        (raw as Map<String, dynamic>)['id'] as String: raw['name'] as String,
    };
    final territoryNames = <String, String>{
      for (final dynamic raw in (territories as List<dynamic>))
        (raw as Map<String, dynamic>)['id'] as String: raw['name'] as String,
    };
    final assignedCounts = <String, int>{};
    for (final dynamic raw in (appointments as List<dynamic>)) {
      final row = raw as Map<String, dynamic>;
      final stylistId = row['assigned_stylist_profile_id'] as String?;
      if (stylistId == null) {
        continue;
      }

      assignedCounts.update(stylistId, (count) => count + 1, ifAbsent: () => 1);
    }

    return (stylists as List<dynamic>)
        .map((dynamic raw) {
          final row = raw as Map<String, dynamic>;
          final userProfile = row['user_profile'] as Map<String, dynamic>?;
          return AdminStylistSummary(
            id: row['id'] as String,
            name: _joinName(
              userProfile?['first_name'] as String?,
              userProfile?['last_name'] as String?,
            ),
            status: row['status'] as String,
            marketName: marketNames[row['market_id'] as String? ?? ''],
            territoryName: territoryNames[row['territory_id'] as String? ?? ''],
            specialties: ((row['specialties'] as List<dynamic>?) ?? const <dynamic>[])
                .map((dynamic value) => value.toString())
                .toList(growable: false),
            isAcceptingBookings: (row['is_accepting_bookings'] as bool?) ?? true,
            assignedAppointmentCount: assignedCounts[row['id'] as String] ?? 0,
          );
        })
        .toList(growable: false);
  }

  Future<List<AdminStylistApplicationSummary>> loadStylistApplications() async {
    final applications = await _requireClient().from('stylist_applications').select('''
id,
status,
phone,
city,
state,
years_experience,
specialties,
reviewer_notes,
created_at,
market_id,
territory_id,
user_profile:user_profiles!stylist_applications_user_profile_id_fkey(first_name, last_name, email)
''').order('created_at', ascending: false);
    final markets = await _requireClient().from('markets').select('id, name');
    final territories = await _requireClient().from('territories').select('id, name');

    final marketNames = <String, String>{
      for (final dynamic raw in (markets as List<dynamic>))
        (raw as Map<String, dynamic>)['id'] as String: raw['name'] as String,
    };
    final territoryNames = <String, String>{
      for (final dynamic raw in (territories as List<dynamic>))
        (raw as Map<String, dynamic>)['id'] as String: raw['name'] as String,
    };

    return (applications as List<dynamic>)
        .map((dynamic raw) {
          final row = raw as Map<String, dynamic>;
          final userProfile = row['user_profile'] as Map<String, dynamic>?;
          return AdminStylistApplicationSummary(
            id: row['id'] as String,
            applicantName: _joinName(
              userProfile?['first_name'] as String?,
              userProfile?['last_name'] as String?,
            ),
            email: (userProfile?['email'] as String?) ?? 'No email',
            phone: row['phone'] as String?,
            city: row['city'] as String?,
            stateCode: row['state'] as String?,
            status: row['status'] as String,
            marketName: marketNames[row['market_id'] as String? ?? ''],
            territoryName: territoryNames[row['territory_id'] as String? ?? ''],
            specialties: ((row['specialties'] as List<dynamic>?) ?? const <dynamic>[])
                .map((dynamic value) => value.toString())
                .toList(growable: false),
            yearsExperience: row['years_experience'] as int?,
            submittedAt: _parseDateTime(row['created_at'] as String),
            reviewerNotes: row['reviewer_notes'] as String?,
          );
        })
        .toList(growable: false);
  }

  Future<List<AdminUserAccessSummary>> loadUserAccessDirectory() async {
    final markets = await _requireClient().from('markets').select('id, name');
    final territories = await _requireClient().from('territories').select('id, name');
    final userProfiles = await _requireClient().from('user_profiles').select('''
id,
email,
first_name,
last_name,
user_roles(id, role, status, is_primary, market_id, territory_id)
''');

    final marketNames = <String, String>{
      for (final dynamic raw in (markets as List<dynamic>))
        (raw as Map<String, dynamic>)['id'] as String: raw['name'] as String,
    };
    final territoryNames = <String, String>{
      for (final dynamic raw in (territories as List<dynamic>))
        (raw as Map<String, dynamic>)['id'] as String: raw['name'] as String,
    };

    final users = (userProfiles as List<dynamic>)
        .map((dynamic raw) {
          final row = raw as Map<String, dynamic>;
          final roles = ((row['user_roles'] as List<dynamic>?) ?? const <dynamic>[])
              .map((dynamic rawRole) {
                final roleRow = rawRole as Map<String, dynamic>;
                return AdminUserRoleAssignment(
                  id: roleRow['id'] as String,
                  role: roleRow['role'] as String,
                  status: roleRow['status'] as String,
                  isPrimary: (roleRow['is_primary'] as bool?) ?? false,
                  marketName: marketNames[roleRow['market_id'] as String? ?? ''],
                  territoryName:
                      territoryNames[roleRow['territory_id'] as String? ?? ''],
                );
              })
              .toList(growable: false)
            ..sort((left, right) => left.role.compareTo(right.role));

          return AdminUserAccessSummary(
            userProfileId: row['id'] as String,
            name: _joinName(
              row['first_name'] as String?,
              row['last_name'] as String?,
            ),
            email: row['email'] as String,
            roles: roles,
          );
        })
        .toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));

    return users;
  }

  Future<List<AdminScopeOption>> loadMarketOptions() async {
    final response = await _requireClient().from('markets').select('id, name').order('name');
    return (response as List<dynamic>)
        .map(
          (dynamic raw) => AdminScopeOption(
            id: (raw as Map<String, dynamic>)['id'] as String,
            name: raw['name'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<List<AdminScopeOption>> loadTerritoryOptions({String? marketId}) async {
    final response = marketId == null
        ? await _requireClient().from('territories').select('id, name').order('name')
        : await _requireClient()
            .from('territories')
            .select('id, name')
            .eq('market_id', marketId)
            .order('name');
    return (response as List<dynamic>)
        .map(
          (dynamic raw) => AdminScopeOption(
            id: (raw as Map<String, dynamic>)['id'] as String,
            name: raw['name'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<List<AdminServiceCategoryGroup>> loadServiceCategoriesWithServices() async {
    final categories = await _requireClient()
        .from('service_categories')
        .select('id, name, description, sort_order')
        .order('sort_order');
    final services = await _requireClient()
        .from('services')
        .select('id, service_category_id, name, description, duration_minutes, base_price_cents, status')
        .order('name');

    final servicesByCategory = <String, List<AdminServiceSummary>>{};
    for (final dynamic raw in (services as List<dynamic>)) {
      final row = raw as Map<String, dynamic>;
      final service = AdminServiceSummary(
        id: row['id'] as String,
        serviceCategoryId: row['service_category_id'] as String,
        name: row['name'] as String,
        description: row['description'] as String?,
        durationMinutes: row['duration_minutes'] as int,
        basePriceCents: row['base_price_cents'] as int?,
        status: row['status'] as String,
      );
      servicesByCategory.putIfAbsent(service.serviceCategoryId, () => <AdminServiceSummary>[]).add(service);
    }

    return (categories as List<dynamic>)
        .map((dynamic raw) {
          final row = raw as Map<String, dynamic>;
          return AdminServiceCategoryGroup(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String?,
            services: servicesByCategory[row['id'] as String] ?? const <AdminServiceSummary>[],
          );
        })
        .toList(growable: false);
  }

  Future<List<AdminStylistOption>> loadStylistOptions() async {
    final response = await _requireClient().from('stylist_profiles').select('''
id,
user_profile:user_profiles!stylist_profiles_user_profile_id_fkey(first_name, last_name)
''');

    return (response as List<dynamic>)
        .map((dynamic raw) {
          final row = raw as Map<String, dynamic>;
          final userProfile = row['user_profile'] as Map<String, dynamic>?;
          return AdminStylistOption(
            id: row['id'] as String,
            name: _joinName(
              userProfile?['first_name'] as String?,
              userProfile?['last_name'] as String?,
            ),
          );
        })
        .toList(growable: false);
  }

  Future<void> approveAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId: appointmentId, status: 'approved');
  }

  Future<void> declineAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId: appointmentId, status: 'declined');
  }

  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    await _requireClient().from('appointments').update({
      'status': status,
    }).eq('id', appointmentId);

    // TODO: Narrow appointment status mutation policies so only admins can edit
    // approval and assignment lifecycle fields in production.
  }

  Future<void> assignStylist({
    required String appointmentId,
    required String stylistProfileId,
  }) async {
    await _requireClient().from('appointments').update({
      'assigned_stylist_profile_id': stylistProfileId,
      'status': 'assigned',
    }).eq('id', appointmentId);
  }

  Future<void> upsertService({
    required AppUser appUser,
    required String? serviceId,
    required String serviceCategoryId,
    required String name,
    required String description,
    required int durationMinutes,
    required int? basePriceCents,
    required String status,
  }) async {
    final payload = <String, dynamic>{
      'service_category_id': serviceCategoryId,
      'market_id': appUser.defaultMarketId,
      'territory_id': appUser.defaultTerritoryId,
      'name': name.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'duration_minutes': durationMinutes,
      'base_price_cents': basePriceCents,
      'status': status,
      'allows_multiple_participants': false,
      'is_mobile_service': true,
    };

    if (serviceId == null) {
      await _requireClient().from('services').insert(payload);
      return;
    }

    await _requireClient().from('services').update(payload).eq('id', serviceId);
  }

  Future<void> toggleServiceStatus({
    required String serviceId,
    required bool enable,
  }) async {
    await _requireClient().from('services').update({
      'status': enable ? 'active' : 'inactive',
    }).eq('id', serviceId);
  }

  Future<void> approveStylistApplication({
    required String applicationId,
    String? territoryId,
    String? reviewerNotes,
  }) async {
    await _requireClient().rpc(
      'approve_stylist_application',
      params: <String, dynamic>{
        'p_application_id': applicationId,
        'p_territory_id': territoryId,
        'p_reviewer_notes': reviewerNotes?.trim().isEmpty == true
            ? null
            : reviewerNotes?.trim(),
      },
    );
  }

  Future<void> rejectStylistApplication({
    required String applicationId,
    String? reviewerNotes,
  }) async {
    await _requireClient().rpc(
      'reject_stylist_application',
      params: <String, dynamic>{
        'p_application_id': applicationId,
        'p_reviewer_notes': reviewerNotes?.trim().isEmpty == true
            ? null
            : reviewerNotes?.trim(),
      },
    );
  }

  Future<void> grantAdminAccess({
    required String userProfileId,
    required String role,
    String? marketId,
    String? territoryId,
    required bool makePrimary,
  }) async {
    await _requireClient().rpc(
      'grant_admin_access',
      params: <String, dynamic>{
        'p_target_user_profile_id': userProfileId,
        'p_role': role,
        'p_market_id': marketId,
        'p_territory_id': territoryId,
        'p_make_primary': makePrimary,
      },
    );
  }

  Future<List<AdminAppointmentSummary>> _loadAppointments() async {
    final response = await _requireClient().from('appointments').select('''
id,
status,
preferred_date,
preferred_time_window,
estimated_total_cents,
requested_start_at,
scheduled_start_at,
address:addresses!appointments_address_id_fkey(line1, city, state, postal_code),
customer_profile:customer_profiles!appointments_customer_profile_id_fkey(
  user_profile:user_profiles!customer_profiles_user_profile_id_fkey(first_name, last_name)
),
assigned_stylist:stylist_profiles!appointments_assigned_stylist_profile_id_fkey(
  user_profile:user_profiles!stylist_profiles_user_profile_id_fkey(first_name, last_name)
),
appointment_services(service:services(name)),
check_ins(event_type)
''');

    final appointments = (response as List<dynamic>)
        .map((dynamic raw) => _mapAppointmentSummary(raw as Map<String, dynamic>))
        .toList(growable: false)
      ..sort((left, right) => left.startsAt.compareTo(right.startsAt));

    return appointments;
  }

  Future<List<AdminSafetyEventSummary>> _loadSafetyEvents({required int limit}) async {
    final response = await _requireClient().from('safety_events').select('''
id,
appointment_id,
event_type,
status,
details,
created_at,
appointment:appointments!safety_events_appointment_id_fkey(
  customer_profile:customer_profiles!appointments_customer_profile_id_fkey(
    user_profile:user_profiles!customer_profiles_user_profile_id_fkey(first_name, last_name)
  )
)
''').order('created_at', ascending: false).limit(limit);

    return (response as List<dynamic>)
        .map((dynamic raw) {
          final row = raw as Map<String, dynamic>;
          final appointment = row['appointment'] as Map<String, dynamic>?;
          final customerProfile = appointment?['customer_profile'] as Map<String, dynamic>?;
          final userProfile = customerProfile?['user_profile'] as Map<String, dynamic>?;
          return _mapSafetyEvent(
            row,
            customerName: _joinName(
              userProfile?['first_name'] as String?,
              userProfile?['last_name'] as String?,
            ),
          );
        })
        .toList(growable: false);
  }

  AdminAppointmentSummary _mapAppointmentSummary(Map<String, dynamic> row) {
    final address = row['address'] as Map<String, dynamic>?;
    final customerProfile = row['customer_profile'] as Map<String, dynamic>?;
    final customerUser = customerProfile?['user_profile'] as Map<String, dynamic>?;
    final assignedStylist = row['assigned_stylist'] as Map<String, dynamic>?;
    final assignedStylistUser = assignedStylist?['user_profile'] as Map<String, dynamic>?;
    final startsAt = _parseDateTime(
      row['scheduled_start_at'] as String? ?? row['requested_start_at'] as String,
    );

    return AdminAppointmentSummary(
      id: row['id'] as String,
      customerName: _joinName(
        customerUser?['first_name'] as String?,
        customerUser?['last_name'] as String?,
      ),
      customerFirstName: (customerUser?['first_name'] as String?)?.trim().isNotEmpty == true
          ? customerUser!['first_name'] as String
          : 'Customer',
      cityOrArea: (address?['city'] as String?) ?? 'Area not set',
      serviceSummary: ((row['appointment_services'] as List<dynamic>?) ?? const <dynamic>[])
          .take(2)
          .map((dynamic rawService) {
            final serviceRow = rawService as Map<String, dynamic>;
            final service = serviceRow['service'] as Map<String, dynamic>?;
            return (service?['name'] as String?) ?? 'Service';
          })
          .join(', '),
      status: row['status'] as String,
      checkInStatus: _checkInStatus((row['check_ins'] as List<dynamic>?) ?? const <dynamic>[]),
      preferredDateLabel: row['preferred_date'] as String?,
      preferredTimeWindow: row['preferred_time_window'] as String?,
      estimatedTotalCents: row['estimated_total_cents'] as int?,
      startsAt: startsAt,
      addressSummary: _formatAddress(
        line1: address?['line1'] as String?,
        city: address?['city'] as String?,
        state: address?['state'] as String?,
        postalCode: address?['postal_code'] as String?,
      ),
      assignedStylistName: _joinName(
        assignedStylistUser?['first_name'] as String?,
        assignedStylistUser?['last_name'] as String?,
      ),
    );
  }

  AdminAppointmentParticipant _mapParticipant(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    final householdMember = row['household_member'] as Map<String, dynamic>?;
    return AdminAppointmentParticipant(
      name: _joinName(
        householdMember?['first_name'] as String?,
        householdMember?['last_name'] as String?,
      ),
      generalNotes: (row['participant_notes'] as String?) ?? householdMember?['general_notes'] as String?,
      sensoryNotes: (row['sensory_notes_snapshot'] as String?) ?? householdMember?['sensory_notes'] as String?,
      hairNotes: householdMember?['hair_notes'] as String?,
    );
  }

  AdminAppointmentServiceLine _mapServiceLine(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    final service = row['service'] as Map<String, dynamic>?;
    return AdminAppointmentServiceLine(
      name: (service?['name'] as String?) ?? 'Service',
      quantity: (row['quantity'] as int?) ?? 1,
      durationMinutes: (row['duration_snapshot_minutes'] as int?) ??
          ((service?['duration_minutes'] as int?) ?? 0),
      lineNotes: row['line_notes'] as String?,
    );
  }

  AdminAppointmentPhoto _mapPhoto(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    return AdminAppointmentPhoto(
      id: row['id'] as String,
      photoType: row['photo_type'] as String,
      caption: row['caption'] as String?,
      storagePath: row['storage_path'] as String,
      createdAt: _parseDateTime(row['created_at'] as String),
    );
  }

  AdminCheckInEvent _mapCheckInEvent(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    final recordedAt = row['check_in_at'] as String? ??
        row['check_out_at'] as String? ??
        row['created_at'] as String;
    return AdminCheckInEvent(
      id: row['id'] as String,
      eventType: row['event_type'] as String,
      status: row['status'] as String,
      recordedAt: _parseDateTime(recordedAt),
      eventNotes: row['event_notes'] as String?,
    );
  }

  AdminInternalNote _mapInternalNote(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    final author = row['author'] as Map<String, dynamic>?;
    return AdminInternalNote(
      id: row['id'] as String,
      noteType: row['note_type'] as String,
      noteBody: row['note_body'] as String,
      createdAt: _parseDateTime(row['created_at'] as String),
      authorName: _joinName(author?['first_name'] as String?, author?['last_name'] as String?),
    );
  }

  AdminSafetyEventSummary _mapSafetyEvent(
    Map<String, dynamic> row, {
    required String customerName,
  }) {
    return AdminSafetyEventSummary(
      id: row['id'] as String,
      appointmentId: row['appointment_id'] as String?,
      customerName: customerName,
      eventType: row['event_type'] as String,
      status: row['status'] as String,
      details: row['details'] as String,
      createdAt: _parseDateTime(row['created_at'] as String),
    );
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw Exception(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY before testing admin flows.',
      );
    }

    return _client;
  }

  DateTime _parseDateTime(String value) => DateTime.parse(value).toLocal();

  String _joinName(String? firstName, String? lastName) {
    final parts = <String>[
      if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
    ];

    if (parts.isEmpty) {
      return 'Unknown';
    }

    return parts.join(' ');
  }

  String _formatAddress({
    required String? line1,
    required String? city,
    required String? state,
    required String? postalCode,
  }) {
    return <String>[
      if (line1 != null && line1.trim().isNotEmpty) line1.trim(),
      [
        if (city != null && city.trim().isNotEmpty) city.trim(),
        if (state != null && state.trim().isNotEmpty) state.trim(),
      ].join(', ').replaceAll(RegExp(r'^, |, $'), ''),
      if (postalCode != null && postalCode.trim().isNotEmpty) postalCode.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
  }

  String _checkInStatus(List<dynamic> rows) {
    final hasCheckOut = rows.any((dynamic raw) => (raw as Map<String, dynamic>)['event_type'] == 'check_out');
    if (hasCheckOut) {
      return 'Checked out';
    }

    final hasCheckIn = rows.any((dynamic raw) => (raw as Map<String, dynamic>)['event_type'] == 'check_in');
    if (hasCheckIn) {
      return 'Checked in';
    }

    return 'Not started';
  }
}