import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_hair_salon/core/scheduling/appointment_rules.dart';

void main() {
  group('overlapsBlockedHours', () {
    test('returns true for an early-morning range', () {
      final start = DateTime(2026, 6, 12, 5, 0);
      final end = DateTime(2026, 6, 12, 7, 0);

      expect(overlapsBlockedHours(start, end), isTrue);
    });

    test('returns false for a daytime range', () {
      final start = DateTime(2026, 6, 12, 9, 0);
      final end = DateTime(2026, 6, 12, 15, 0);

      expect(overlapsBlockedHours(start, end), isFalse);
    });
  });

  group('timeRangesOverlap', () {
    test('detects overlap', () {
      final hasOverlap = timeRangesOverlap(
        startA: DateTime(2026, 6, 12, 9, 0),
        endA: DateTime(2026, 6, 12, 10, 0),
        startB: DateTime(2026, 6, 12, 9, 30),
        endB: DateTime(2026, 6, 12, 10, 30),
      );

      expect(hasOverlap, isTrue);
    });

    test('does not overlap when ranges touch at boundary', () {
      final hasOverlap = timeRangesOverlap(
        startA: DateTime(2026, 6, 12, 9, 0),
        endA: DateTime(2026, 6, 12, 10, 0),
        startB: DateTime(2026, 6, 12, 10, 0),
        endB: DateTime(2026, 6, 12, 11, 0),
      );

      expect(hasOverlap, isFalse);
    });
  });
}
