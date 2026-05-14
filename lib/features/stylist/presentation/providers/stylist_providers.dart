import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/stylist_repository.dart';
import '../../domain/stylist_models.dart';

/// Loads the signed-in stylist's profile row.
final currentStylistProfileProvider = FutureProvider<StylistProfileSummary>((ref) async {
  final appUser = await _requireAppUser(ref);
  final repository = ref.watch(stylistRepositoryProvider);
  return repository.getCurrentStylistProfile(appUser: appUser);
});

/// Today's assigned appointments for the stylist home screen.
final stylistTodayAppointmentsProvider = FutureProvider<List<StylistAppointmentSummary>>((ref) async {
  final repository = ref.watch(stylistRepositoryProvider);
  final stylistProfile = await ref.watch(currentStylistProfileProvider.future);
  return repository.getTodayAppointments(stylistProfile: stylistProfile);
});

/// Broader schedule list for the schedule tab.
final stylistScheduleAppointmentsProvider = FutureProvider<List<StylistAppointmentSummary>>((ref) async {
  final repository = ref.watch(stylistRepositoryProvider);
  final stylistProfile = await ref.watch(currentStylistProfileProvider.future);
  return repository.getScheduleAppointments(stylistProfile: stylistProfile);
});

/// Detail provider for one appointment selected by the stylist.
final stylistAppointmentDetailProvider = FutureProvider.family<StylistAppointmentDetail, String>((ref, appointmentId) async {
  final repository = ref.watch(stylistRepositoryProvider);
  return repository.getAppointmentDetail(appointmentId: appointmentId);
});

/// Recent safety events created by the current stylist.
final stylistSafetyEventsProvider = FutureProvider<List<StylistSafetyEventSummary>>((ref) async {
  final repository = ref.watch(stylistRepositoryProvider);
  final stylistProfile = await ref.watch(currentStylistProfileProvider.future);
  return repository.getRecentSafetyEvents(stylistProfile: stylistProfile);
});

/// Handles operational stylist actions and refreshes dependent providers.
final stylistActionControllerProvider =
    AsyncNotifierProvider<StylistActionController, void>(StylistActionController.new);

class StylistActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createCheckIn({
    required String appointmentId,
    String? note,
  }) async {
    await _runAction(() async {
      final appUser = await _requireAppUser(ref);
      final stylistProfile = await ref.read(currentStylistProfileProvider.future);
      await ref.read(stylistRepositoryProvider).createCheckIn(
            appointmentId: appointmentId,
            appUser: appUser,
            stylistProfile: stylistProfile,
            note: note,
          );
      _refreshAppointmentSlices(ref, appointmentId);
    });
  }

  Future<void> createCheckOut({
    required String appointmentId,
    String? note,
  }) async {
    await _runAction(() async {
      final stylistProfile = await ref.read(currentStylistProfileProvider.future);
      await ref.read(stylistRepositoryProvider).createCheckOut(
            appointmentId: appointmentId,
            stylistProfile: stylistProfile,
            note: note,
          );
      _refreshAppointmentSlices(ref, appointmentId);
    });
  }

  Future<void> markAppointmentComplete({required String appointmentId}) async {
    await _runAction(() async {
      await ref.read(stylistRepositoryProvider).markAppointmentComplete(
            appointmentId: appointmentId,
          );
      _refreshAppointmentSlices(ref, appointmentId);
    });
  }

  Future<void> addInternalNote({
    required String appointmentId,
    required String noteBody,
  }) async {
    await _runAction(() async {
      final appUser = await _requireAppUser(ref);
      await ref.read(stylistRepositoryProvider).addInternalNote(
            appointmentId: appointmentId,
            appUser: appUser,
            noteBody: noteBody,
          );
      _refreshAppointmentSlices(ref, appointmentId);
    });
  }

  Future<void> triggerSafetyEvent({required String appointmentId}) async {
    await _runAction(() async {
      final appUser = await _requireAppUser(ref);
      final stylistProfile = await ref.read(currentStylistProfileProvider.future);
      await ref.read(stylistRepositoryProvider).triggerSafetyEvent(
            appointmentId: appointmentId,
            appUser: appUser,
            stylistProfile: stylistProfile,
          );
      _refreshAppointmentSlices(ref, appointmentId);
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

void _refreshAppointmentSlices(Ref ref, String appointmentId) {
  ref.invalidate(stylistTodayAppointmentsProvider);
  ref.invalidate(stylistScheduleAppointmentsProvider);
  ref.invalidate(stylistAppointmentDetailProvider(appointmentId));
  ref.invalidate(stylistSafetyEventsProvider);
}