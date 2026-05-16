import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_models.dart';

/// Loads admin dashboard summary metrics and recent operational activity.
final adminDashboardSummaryProvider = FutureProvider<AdminDashboardSummary>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadDashboardSummary();
});

/// Loads the appointment operations queue.
final adminAppointmentsProvider = FutureProvider<List<AdminAppointmentSummary>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadAppointments();
});

/// Loads detailed appointment data for review and assignment.
final adminAppointmentDetailProvider = FutureProvider.family<AdminAppointmentDetail, String>((ref, appointmentId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadAppointmentDetail(appointmentId);
});

/// Loads customer directory data.
final adminCustomersProvider = FutureProvider<List<AdminCustomerSummary>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadCustomers();
});

/// Loads stylist directory data.
final adminStylistsProvider = FutureProvider<List<AdminStylistSummary>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadStylists();
});

final adminStylistApplicationsProvider =
    FutureProvider<List<AdminStylistApplicationSummary>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadStylistApplications();
});

final adminUserAccessDirectoryProvider =
    FutureProvider<List<AdminUserAccessSummary>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadUserAccessDirectory();
});

final adminMarketOptionsProvider =
    FutureProvider<List<AdminScopeOption>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadMarketOptions();
});

final adminTerritoryOptionsProvider =
    FutureProvider.family<List<AdminScopeOption>, String?>((ref, marketId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadTerritoryOptions(marketId: marketId);
});

/// Loads service categories and service records for admin management.
final adminServiceCatalogProvider = FutureProvider<List<AdminServiceCategoryGroup>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.loadServiceCategoriesWithServices();
});

/// Handles booking review and service management actions.
final adminActionControllerProvider =
    AsyncNotifierProvider<AdminActionController, void>(AdminActionController.new);

class AdminActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> approveAppointment(String appointmentId) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).approveAppointment(appointmentId);
      _refreshAppointments(ref, appointmentId);
    });
  }

  Future<void> declineAppointment(String appointmentId) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).declineAppointment(appointmentId);
      _refreshAppointments(ref, appointmentId);
    });
  }

  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).updateAppointmentStatus(
            appointmentId: appointmentId,
            status: status,
          );
      _refreshAppointments(ref, appointmentId);
    });
  }

  Future<void> assignStylist({
    required String appointmentId,
    required String stylistProfileId,
  }) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).assignStylist(
            appointmentId: appointmentId,
            stylistProfileId: stylistProfileId,
          );
      _refreshAppointments(ref, appointmentId);
    });
  }

  Future<void> approveStylistApplication({
    required String applicationId,
    String? territoryId,
    String? reviewerNotes,
  }) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).approveStylistApplication(
            applicationId: applicationId,
            territoryId: territoryId,
            reviewerNotes: reviewerNotes,
          );
      _refreshStaff(ref);
    });
  }

  Future<void> rejectStylistApplication({
    required String applicationId,
    String? reviewerNotes,
  }) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).rejectStylistApplication(
            applicationId: applicationId,
            reviewerNotes: reviewerNotes,
          );
      _refreshStaff(ref);
    });
  }

  Future<void> grantAdminAccess({
    required String userProfileId,
    required String role,
    String? marketId,
    String? territoryId,
    required bool makePrimary,
  }) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).grantAdminAccess(
            userProfileId: userProfileId,
            role: role,
            marketId: marketId,
            territoryId: territoryId,
            makePrimary: makePrimary,
          );
      _refreshStaff(ref);
    });
  }

  Future<void> saveService({
    required String? serviceId,
    required String serviceCategoryId,
    required String name,
    required String description,
    required int durationMinutes,
    required int? basePriceCents,
    required String status,
  }) async {
    await _runAction(() async {
      final appUser = await _requireAppUser(ref);
      await ref.read(adminRepositoryProvider).upsertService(
            appUser: appUser,
            serviceId: serviceId,
            serviceCategoryId: serviceCategoryId,
            name: name,
            description: description,
            durationMinutes: durationMinutes,
            basePriceCents: basePriceCents,
            status: status,
          );
      ref.invalidate(adminServiceCatalogProvider);
    });
  }

  Future<void> toggleServiceStatus({
    required String serviceId,
    required bool enable,
  }) async {
    await _runAction(() async {
      await ref.read(adminRepositoryProvider).toggleServiceStatus(
            serviceId: serviceId,
            enable: enable,
          );
      ref.invalidate(adminServiceCatalogProvider);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(action);
    state = nextState;

    if (nextState.hasError) {
      throw nextState.error!;
    }
  }
}

Future<AppUser> _requireAppUser(Ref ref) async {
  final appUser = await ref.read(currentAppUserProvider.future);
  if (appUser == null) {
    throw Exception('Please sign in again to continue.');
  }

  return appUser;
}

void _refreshAppointments(Ref ref, String appointmentId) {
  ref.invalidate(adminDashboardSummaryProvider);
  ref.invalidate(adminAppointmentsProvider);
  ref.invalidate(adminAppointmentDetailProvider(appointmentId));
  ref.invalidate(adminCustomersProvider);
  ref.invalidate(adminStylistsProvider);
}

void _refreshStaff(Ref ref) {
  ref.invalidate(adminDashboardSummaryProvider);
  ref.invalidate(adminStylistsProvider);
  ref.invalidate(adminStylistApplicationsProvider);
  ref.invalidate(adminUserAccessDirectoryProvider);
}