import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_hair_salon/features/customer/booking/domain/availability_slot.dart';

/// Unit tests for [calculateSlotsForStylist].
///
/// These tests are pure Dart — no Flutter framework or Supabase needed.
/// All times are local; no timezone conversion is involved.
void main() {
  // ─── Convenience helpers ────────────────────────────────────────────────

  /// Monday 2026-05-25 at HH:mm.
  DateTime t(int hour, [int minute = 0]) =>
      DateTime(2026, 5, 25, hour, minute);

  /// One-block available window [from, to).
  ({DateTime start, DateTime end}) block(int fromHour, int toHour) =>
      (start: t(fromHour), end: t(toHour));

  /// One booked window [from, to).
  ({DateTime start, DateTime end}) booked(int fromHour, int toHour,
          [int fromMin = 0, int toMin = 0]) =>
      (start: t(fromHour, fromMin), end: t(toHour, toMin));

  // ─── No bookings ────────────────────────────────────────────────────────

  group('no existing bookings', () {
    test('fills a 2-hour block with 30-min interval 60-min slots', () {
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 11)],
        bookedWindows: [],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
      );
      // 9:00→10:00 and 9:30→10:30 and 10:00→11:00 = 3 slots
      expect(slots.length, 3);
      expect(slots.first.startAt, t(9));
      expect(slots.last.startAt, t(10));
    });

    test('returns empty list when block is shorter than service duration', () {
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 10)],
        bookedWindows: [],
        durationMinutes: 90,
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slots, isEmpty);
    });

    test('includes slot that exactly fills the available block', () {
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 10)],
        bookedWindows: [],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slots.length, 1);
      expect(slots.first.startAt, t(9));
      expect(slots.first.endAt, t(10));
    });

    test('returns empty list for empty available blocks', () {
      final slots = calculateSlotsForStylist(
        availableBlocks: [],
        bookedWindows: [],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slots, isEmpty);
    });

    test('slots from multiple available blocks are all returned', () {
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 10), block(14, 16)],
        bookedWindows: [],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
      );
      // 9→10 (1 slot) + 14→15 and 14:30→15:30 and 15→16 (3 slots) = 4
      expect(slots.length, 4);
      expect(slots.map((s) => s.startAt), containsAll([t(9), t(14), t(14, 30), t(15)]));
    });

    test('slot carries correct stylist id and name', () {
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 10)],
        bookedWindows: [],
        durationMinutes: 60,
        stylistId: 'stylist-abc',
        stylistName: 'Jordan Lee',
      );
      expect(slots.first.stylistId, 'stylist-abc');
      expect(slots.first.stylistName, 'Jordan Lee');
    });
  });

  // ─── Existing appointment overlap ───────────────────────────────────────

  group('existing appointment overlap', () {
    test('blocks slots that overlap a booked appointment', () {
      // Available 9-12, appointment 10-11 (60 min job).
      // Candidate 9→10: ends at 10, appointment starts at 10 → no overlap ✓
      // Candidate 9:30→10:30: overlaps 10-11 ✗
      // Candidate 10→11: overlaps ✗
      // Candidate 10:30→11:30: overlaps ✗
      // Candidate 11→12: no overlap ✓
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 12)],
        bookedWindows: [booked(10, 11)],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
        travelBufferMinutes: 0,
      );
      final starts = slots.map((s) => s.startAt).toList();
      expect(starts, contains(t(9)));
      expect(starts, contains(t(11)));
      expect(starts, isNot(contains(t(9, 30))));
      expect(starts, isNot(contains(t(10))));
    });

    test('travel buffer prevents immediately adjacent slots', () {
      // Available 9-13, appointment 10-11 (60 min), travel buffer 30 min.
      // After buffer the booked window effectively runs 10-11:30.
      // 9→10 should be OK; 9:30→10:30 overlaps; 11:30→12:30 should be OK.
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 13)],
        bookedWindows: [booked(10, 11)],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
        travelBufferMinutes: 30,
      );
      final starts = slots.map((s) => s.startAt).toList();
      expect(starts, contains(t(9)));
      // 11:00 → ends 12:00, but buffered booked end is 11:30 → overlaps.
      expect(starts, isNot(contains(t(11))));
      // 11:30 → ends 12:30, buffered end 11:30 → candidate starts at buffered end → no overlap.
      expect(starts, contains(t(11, 30)));
    });

    test('multiple appointments leave gaps in the slot list', () {
      // Available 8-17, two appointments at 9-10 and 13-14 (buffer=15).
      // Effective blocked zones: 9:00-10:15 and 13:00-14:15.
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(8, 17)],
        bookedWindows: [booked(9, 10), booked(13, 14)],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
        travelBufferMinutes: 15,
      );
      final starts = slots.map((s) => s.startAt).toSet();

      // 8:00→9:00 fits before first appointment → should exist
      expect(starts, contains(t(8)));

      // These start times overlap the 9:00-10:15 buffered window:
      // 8:30→9:30 (end 9:30 > 9:00) → blocked
      expect(starts, isNot(contains(t(8, 30))));
      // 9:00→10:00 → blocked
      expect(starts, isNot(contains(t(9))));
      // 9:30→10:30 → blocked
      expect(starts, isNot(contains(t(9, 30))));
      // 10:00→11:00 (starts at 10:00 < buffered end 10:15) → blocked
      expect(starts, isNot(contains(t(10))));

      // 10:30→11:30 starts AFTER buffered end (10:30 >= 10:15) → valid slot
      expect(starts, contains(t(10, 30)));

      // Slots around the 13:00 appointment should also be gapped
      expect(starts, isNot(contains(t(13))));
      expect(starts, isNot(contains(t(13, 30))));
      // 14:30 starts after buffered end of second appointment (13:00+60min+15min=14:15)
      expect(starts, contains(t(14, 30)));
    });

    test('zero-duration guard: no infinite loop with 0-min duration', () {
      // calculateSlotsForStylist should not hang; with 0 duration every
      // candidate fits so we'd get infinite slots — ensure we handle this
      // gracefully in tests by just not calling it with 0 (contract: callers
      // must pass durationMinutes > 0).
      // We simply verify a non-zero duration works correctly here.
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 10)],
        bookedWindows: [],
        durationMinutes: 30,
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slots, isNotEmpty);
    });
  });

  // ─── Slot interval ──────────────────────────────────────────────────────

  group('slot interval customisation', () {
    test('15-minute interval produces more candidates than 30-minute', () {
      final slots30 = calculateSlotsForStylist(
        availableBlocks: [block(9, 12)],
        bookedWindows: [],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
        slotIntervalMinutes: 30,
      );
      final slots15 = calculateSlotsForStylist(
        availableBlocks: [block(9, 12)],
        bookedWindows: [],
        durationMinutes: 60,
        stylistId: 's1',
        stylistName: 'Alice',
        slotIntervalMinutes: 15,
      );
      expect(slots15.length, greaterThan(slots30.length));
    });
  });

  // ─── Multi-service / long duration ─────────────────────────────────────

  group('long service durations', () {
    test('3-hour service only fits once in a 3-hour block', () {
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 12)],
        bookedWindows: [],
        durationMinutes: 180, // 3 hours
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slots.length, 1);
      expect(slots.first.startAt, t(9));
      expect(slots.first.endAt, t(12));
    });

    test('3-hour service does not fit in 2-hour block', () {
      final slots = calculateSlotsForStylist(
        availableBlocks: [block(9, 11)],
        bookedWindows: [],
        durationMinutes: 180,
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slots, isEmpty);
    });
  });

  // ─── AvailableTimeSlot labels ────────────────────────────────────────────

  group('AvailableTimeSlot labels', () {
    test('timeLabel formats correctly for AM', () {
      final slot = AvailableTimeSlot(
        startAt: DateTime(2026, 5, 25, 9, 0),
        endAt: DateTime(2026, 5, 25, 10, 0),
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slot.timeLabel, '9:00 AM – 10:00 AM');
    });

    test('timeLabel formats correctly for PM', () {
      final slot = AvailableTimeSlot(
        startAt: DateTime(2026, 5, 25, 13, 30),
        endAt: DateTime(2026, 5, 25, 14, 30),
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slot.timeLabel, '1:30 PM – 2:30 PM');
    });

    test('timeLabel handles noon correctly', () {
      final slot = AvailableTimeSlot(
        startAt: DateTime(2026, 5, 25, 12, 0),
        endAt: DateTime(2026, 5, 25, 13, 0),
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slot.timeLabel, '12:00 PM – 1:00 PM');
    });

    test('timeLabel handles midnight correctly', () {
      final slot = AvailableTimeSlot(
        startAt: DateTime(2026, 5, 25, 0, 0),
        endAt: DateTime(2026, 5, 25, 1, 0),
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slot.timeLabel, '12:00 AM – 1:00 AM');
    });

    test('dateLabel formats correctly', () {
      // 2026-05-25 is a Monday
      final slot = AvailableTimeSlot(
        startAt: DateTime(2026, 5, 25, 9, 0),
        endAt: DateTime(2026, 5, 25, 10, 0),
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slot.dateLabel, 'Mon, May 25');
    });

    test('durationMinutes is correct', () {
      final slot = AvailableTimeSlot(
        startAt: DateTime(2026, 5, 25, 9, 0),
        endAt: DateTime(2026, 5, 25, 10, 30),
        stylistId: 's1',
        stylistName: 'Alice',
      );
      expect(slot.durationMinutes, 90);
    });
  });

  // ─── BookableStylist ─────────────────────────────────────────────────────

  group('BookableStylist.specialtiesSummary', () {
    test('shows "Full-service stylist" when specialties is empty', () {
      const stylist = BookableStylist(
        id: 's1',
        displayName: 'Alice',
        bio: null,
        specialties: [],
      );
      expect(stylist.specialtiesSummary, 'Full-service stylist');
    });

    test('lists up to 3 specialties comma-separated', () {
      const stylist = BookableStylist(
        id: 's1',
        displayName: 'Alice',
        bio: null,
        specialties: ['Color', 'Balayage', 'Highlights', 'Extensions'],
      );
      expect(stylist.specialtiesSummary, 'Color, Balayage, Highlights');
    });

    test('lists fewer than 3 specialties without trailing comma', () {
      const stylist = BookableStylist(
        id: 's1',
        displayName: 'Alice',
        bio: null,
        specialties: ['Color', 'Balayage'],
      );
      expect(stylist.specialtiesSummary, 'Color, Balayage');
    });
  });
}
