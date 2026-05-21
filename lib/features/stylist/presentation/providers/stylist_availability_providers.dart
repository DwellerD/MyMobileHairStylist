import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/stylist_availability_repository.dart';
import '../../domain/availability_models.dart';
import 'stylist_providers.dart';

// ─── Date range ──────────────────────────────────────────────────────────────

/// Convenience type for passing a week range to the provider family.
typedef WeekOf = DateTime;

/// Availability blocks for the stylist for the week that contains [weekOf].
///
/// [weekOf] is normalised to Monday 00:00 local time before querying, so any
/// date within the target week produces the same result.
final stylistAvailabilityBlocksProvider =
    FutureProvider.autoDispose.family<List<AvailabilityBlock>, WeekOf>(
        (ref, weekOf) async {
  final profile = await ref.watch(currentStylistProfileProvider.future);

  final monday = weekOf.subtract(
    Duration(days: (weekOf.weekday - 1) % 7),
  );
  final rangeStart = DateTime(monday.year, monday.month, monday.day);
  final rangeEnd = rangeStart.add(const Duration(days: 7));

  return ref.watch(stylistAvailabilityRepositoryProvider).loadAvailabilityBlocks(
        stylistProfileId: profile.id,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
});

// ─── Mutation controller ─────────────────────────────────────────────────────

/// State is void — callers invalidate [stylistAvailabilityBlocksProvider] after
/// mutations to force a fresh fetch.
class StylistAvailabilityController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createBlock({
    required String blockType,
    required DateTime startAt,
    required DateTime endAt,
    String? notes,
  }) async {
    final appUser = await ref.read(currentAppUserProvider.future);
    if (appUser == null) {
      throw Exception('Not signed in.');
    }
    final profile = await ref.read(currentStylistProfileProvider.future);

    state = const AsyncLoading<void>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(stylistAvailabilityRepositoryProvider).createAvailabilityBlock(
            appUser: appUser,
            stylistProfile: profile,
            blockType: blockType,
            startAt: startAt,
            endAt: endAt,
            notes: notes,
          );
      ref.invalidate(stylistAvailabilityBlocksProvider);
    });
  }

  Future<void> updateBlock({
    required String blockId,
    required String blockType,
    required DateTime startAt,
    required DateTime endAt,
    String? notes,
  }) async {
    state = const AsyncLoading<void>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(stylistAvailabilityRepositoryProvider).updateAvailabilityBlock(
            blockId: blockId,
            blockType: blockType,
            startAt: startAt,
            endAt: endAt,
            notes: notes,
          );
      ref.invalidate(stylistAvailabilityBlocksProvider);
    });
  }

  Future<void> deleteBlock({required String blockId}) async {
    state = const AsyncLoading<void>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(stylistAvailabilityRepositoryProvider).deleteAvailabilityBlock(
            blockId: blockId,
          );
      ref.invalidate(stylistAvailabilityBlocksProvider);
    });
  }
}

final stylistAvailabilityControllerProvider =
    AutoDisposeAsyncNotifierProvider<StylistAvailabilityController, void>(
  StylistAvailabilityController.new,
);
