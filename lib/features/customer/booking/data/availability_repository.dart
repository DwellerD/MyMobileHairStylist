import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/scheduling/appointment_rules.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../domain/availability_slot.dart';

/// Provides the availability repository for customer-facing booking queries.
final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  return AvailabilityRepository(ref.watch(supabaseClientProvider));
});

/// Loads stylists and computes open time slots that customers can book.
///
/// This repository is intentionally separated from [BookingRepository] so
/// the availability logic stays isolated and testable without the full booking
/// flow state.
class AvailabilityRepository {
  AvailabilityRepository(this._client);

  final SupabaseClient? _client;

  // ─── 15-minute travel placeholder ───────────────────────────────────────
  // Real travel-time calculation (e.g. Google Routes API) should replace this
  // constant buffer in a future milestone. The buffer is applied after every
  // existing appointment so the slot generator never double-books a stylist.
  static const int _travelBufferMinutes = 15;

  // ─── Slot granularity ────────────────────────────────────────────────────
  // Slots are offered every 30 minutes within an available block. Tightening
  // this to 15 minutes provides more choice but creates more short gaps; it
  // can be made configurable per market in a later release.
  static const int _slotIntervalMinutes = 30;

  /// Returns all active stylists in [marketId] who are accepting bookings.
  ///
  /// When [requestedStylistId] is provided, only that one stylist is returned
  /// (after verifying they are active and accepting). This supports the "book
  /// with a specific stylist" flow without duplicating query logic.
  Future<List<BookableStylist>> loadBookableStylists({
    required String marketId,
    String? territoryId,
    String? requestedStylistId,
  }) async {
    var selectBuilder = _requireClient()
        .from('stylist_profiles')
        .select('''
id,
bio,
specialties,
is_accepting_bookings,
status,
user_profile:user_profiles!stylist_profiles_user_profile_id_fkey(first_name, last_name)
''')
        .eq('market_id', marketId)
        .eq('status', 'active')
        .eq('is_accepting_bookings', true);

    if (territoryId != null) {
      selectBuilder = selectBuilder.or(
        'territory_id.is.null,territory_id.eq.$territoryId',
      );
    }

    final response = requestedStylistId != null
        ? await selectBuilder.eq('id', requestedStylistId)
        : await selectBuilder;

    return (response as List<dynamic>)
        .map((dynamic row) => _mapStylist(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Calculates available time slots for a given date and service duration.
  ///
  /// The algorithm:
  /// 1. Load all bookable stylists in the market (or just the requested one).
  /// 2. For each stylist load their "available" blocks that touch [date].
  /// 3. For each stylist load their existing non-cancelled appointments on [date].
  /// 4. Run [calculateSlotsForStylist] from the domain layer.
  /// 5. Combine and sort all slots across stylists.
  ///
  /// Returns an empty list when no stylists have availability on that date.
  Future<List<AvailableTimeSlot>> getAvailableSlots({
    required DateTime date,
    required int durationMinutes,
    required String marketId,
    String? territoryId,
    String? requestedStylistId,
  }) async {
    final stylists = await loadBookableStylists(
      marketId: marketId,
      territoryId: territoryId,
      requestedStylistId: requestedStylistId,
    );

    if (stylists.isEmpty) {
      return const [];
    }

    // Build date range for the day (local time, converted to UTC for queries).
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final allSlots = <AvailableTimeSlot>[];

    for (final stylist in stylists) {
      final blocks = await _loadAvailableBlocks(
        stylistProfileId: stylist.id,
        dayStart: dayStart,
        dayEnd: dayEnd,
      );

      if (blocks.isEmpty) {
        continue;
      }

      final bookedWindows = await _loadBookedWindows(
        stylistProfileId: stylist.id,
        dayStart: dayStart,
        dayEnd: dayEnd,
      );

      final slots = calculateSlotsForStylist(
        availableBlocks: blocks,
        bookedWindows: bookedWindows,
        durationMinutes: durationMinutes,
        stylistId: stylist.id,
        stylistName: stylist.displayName,
        slotIntervalMinutes: _slotIntervalMinutes,
        travelBufferMinutes: _travelBufferMinutes,
      ).where((slot) {
        return !overlapsBlockedHours(slot.startAt, slot.endAt);
      }).toList(growable: false);

      allSlots.addAll(slots);
    }

    allSlots.sort((a, b) => a.startAt.compareTo(b.startAt));
    return allSlots;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<({DateTime start, DateTime end})>> _loadAvailableBlocks({
    required String stylistProfileId,
    required DateTime dayStart,
    required DateTime dayEnd,
  }) async {
    final response = await _requireClient()
        .from('availability_blocks')
        .select('start_at, end_at')
        .eq('stylist_profile_id', stylistProfileId)
        .eq('block_type', 'available')
        // Overlap: block starts before day end AND block ends after day start.
        .lt('start_at', dayEnd.toUtc().toIso8601String())
        .gt('end_at', dayStart.toUtc().toIso8601String());

    return (response as List<dynamic>).map((dynamic raw) {
      final row = raw as Map<String, dynamic>;
      // Clamp to day boundaries so blocks spanning midnight don't produce
      // slots on the wrong day.
      final blockStart =
          DateTime.parse(row['start_at'] as String).toLocal();
      final blockEnd =
          DateTime.parse(row['end_at'] as String).toLocal();
      final clampedStart =
          blockStart.isBefore(dayStart) ? dayStart : blockStart;
      final clampedEnd = blockEnd.isAfter(dayEnd) ? dayEnd : blockEnd;
      return (start: clampedStart, end: clampedEnd);
    }).toList(growable: false);
  }

  Future<List<({DateTime start, DateTime end})>> _loadBookedWindows({
    required String stylistProfileId,
    required DateTime dayStart,
    required DateTime dayEnd,
  }) async {
    final response = await _requireClient()
        .from('appointments')
        .select('scheduled_start_at, requested_start_at, estimated_duration_minutes, appointment_services(duration_snapshot_minutes, service:services(duration_minutes))')
        .eq('assigned_stylist_profile_id', stylistProfileId)
        .not('status', 'in', '(cancelled,declined,declined_by_stylist)')
        .gte('requested_start_at', dayStart.toUtc().toIso8601String())
        .lt('requested_start_at', dayEnd.toUtc().toIso8601String());

    return (response as List<dynamic>).map((dynamic raw) {
      final row = raw as Map<String, dynamic>;
      final startStr = row['scheduled_start_at'] as String? ??
          row['requested_start_at'] as String;
      final start = DateTime.parse(startStr).toLocal();

      // Use estimated_duration_minutes or sum service durations.
      int durationMinutes = (row['estimated_duration_minutes'] as int?) ?? 0;
      if (durationMinutes == 0) {
        final services =
            (row['appointment_services'] as List<dynamic>?) ?? const [];
        durationMinutes = services.fold<int>(0, (total, dynamic svc) {
          final s = svc as Map<String, dynamic>;
          return total +
              ((s['duration_snapshot_minutes'] as int?) ??
                  ((s['service'] as Map<String, dynamic>?)?['duration_minutes']
                          as int?) ??
                  60);
        });
        if (durationMinutes == 0) {
          durationMinutes = 60; // safe fallback
        }
      }

      final end = start.add(Duration(minutes: durationMinutes));
      return (start: start, end: end);
    }).where((window) {
      // Keep only windows that actually fall within this day.
      return window.start.isBefore(dayEnd) &&
          window.end.isAfter(dayStart);
    }).toList(growable: false);
  }

  BookableStylist _mapStylist(Map<String, dynamic> row) {
    final userProfile = row['user_profile'] as Map<String, dynamic>?;
    final firstName = (userProfile?['first_name'] as String?)?.trim() ?? '';
    final lastName = (userProfile?['last_name'] as String?)?.trim() ?? '';
    final displayName = [firstName, if (lastName.isNotEmpty) lastName]
        .join(' ')
        .trim();

    return BookableStylist(
      id: row['id'] as String,
      displayName: displayName.isEmpty ? 'Stylist' : displayName,
      bio: row['bio'] as String?,
      specialties: ((row['specialties'] as List<dynamic>?) ?? const [])
          .map((dynamic v) => v.toString())
          .toList(growable: false),
    );
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw Exception(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY before testing availability.',
      );
    }
    return _client;
  }
}
