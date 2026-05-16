import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/stylist_application_repository.dart';
import '../../domain/stylist_application.dart';

final currentStylistApplicationProvider =
    FutureProvider<StylistApplication?>((ref) async {
  final appUser = await ref.watch(currentAppUserProvider.future);
  if (appUser == null) {
    return null;
  }

  return ref
      .watch(stylistApplicationRepositoryProvider)
      .getCurrentApplication(appUser: appUser);
});

final stylistApplicationActionControllerProvider = AsyncNotifierProvider<
    StylistApplicationActionController, void>(
  StylistApplicationActionController.new,
);

class StylistApplicationActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submitApplication({
    required String phone,
    required String city,
    required String stateCode,
    required String licenseNumber,
    required int? yearsExperience,
    required List<String> specialties,
    required String? portfolioUrl,
    required String motivation,
  }) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      final appUser = await _requireAppUser(ref);
      await ref.read(stylistApplicationRepositoryProvider).submitApplication(
            appUser: appUser,
            phone: phone,
            city: city,
            stateCode: stateCode,
            licenseNumber: licenseNumber,
            yearsExperience: yearsExperience,
            specialties: specialties,
            portfolioUrl: portfolioUrl,
            motivation: motivation,
          );
      ref.invalidate(currentStylistApplicationProvider);
    });
    state = nextState;

    if (nextState.hasError) {
      throw nextState.error!;
    }
  }
}

Future<AppUser> _requireAppUser(Ref ref) async {
  final appUser = await ref.read(currentAppUserProvider.future);
  if (appUser == null) {
    throw Exception('Please sign in again to continue your application.');
  }

  return appUser;
}