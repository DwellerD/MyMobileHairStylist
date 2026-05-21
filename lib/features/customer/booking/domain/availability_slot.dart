/// A stylist that can be shown to customers in the booking flow.
///
/// Only active, accepting stylists in the customer's market are surfaced here.
/// This is intentionally minimal — the company brand leads, not the stylist.
class BookableStylist {
  const BookableStylist({
    required this.id,
    required this.displayName,
    required this.bio,
    required this.specialties,
  });

  final String id;
  final String displayName;
  final String? bio;
  final List<String> specialties;

  String get specialtiesSummary {
    if (specialties.isEmpty) {
      return 'Full-service stylist';
    }
    return specialties.take(3).join(', ');
  }
}

/// A concrete available appointment time slot that a customer can request.
///
/// Slots are derived by comparing stylist availability blocks against existing
/// appointments. A 15-minute travel buffer is applied after each appointment
/// before a new slot can begin.
class AvailableTimeSlot {
  const AvailableTimeSlot({
    required this.startAt,
    required this.endAt,
    required this.stylistId,
    required this.stylistName,
  });

  final DateTime startAt;
  final DateTime endAt;
  final String stylistId;
  final String stylistName;

  /// Duration between start and end.
  Duration get duration => endAt.difference(startAt);

  int get durationMinutes => duration.inMinutes;

  /// Short label shown on the time picker: "10:30 AM – 11:30 AM".
  String get timeLabel {
    return '${_formatTime(startAt)} – ${_formatTime(endAt)}';
  }

  /// Day label shown above a group of slots: "Thu, May 22".
  String get dateLabel {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // weekday: 1 = Monday … 7 = Sunday
    final dayName = days[(startAt.weekday - 1) % 7];
    return '$dayName, ${months[startAt.month]} ${startAt.day}';
  }

  @override
  bool operator ==(Object other) {
    if (other is! AvailableTimeSlot) {
      return false;
    }
    return startAt == other.startAt && stylistId == other.stylistId;
  }

  @override
  int get hashCode => Object.hash(startAt, stylistId);
}

// ──────────────────────────────────────────────────────────────────────────────
// Availability Calculation
// ──────────────────────────────────────────────────────────────────────────────

/// One stylist's "available" window loaded from the DB.
class _AvailBlock {
  const _AvailBlock({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

/// One booked appointment that occupies stylist time.
class _BookedWindow {
  const _BookedWindow({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

/// Calculates open time slots for a stylist on a given day.
///
/// [availableBlocks] - the stylist's "available" availability_block rows.
/// [bookedWindows]   - existing appointments (any non-cancelled status).
/// [durationMinutes] - total service time the customer needs.
/// [stylistId]       - included in each returned slot.
/// [stylistName]     - included in each returned slot for display.
/// [slotIntervalMinutes] - how often to generate candidate slots (default: 30).
/// [travelBufferMinutes] - gap added after each appointment (default: 15).
///
/// Returns a sorted list of non-overlapping slots that fit within available
/// windows and don't conflict with existing bookings.
List<AvailableTimeSlot> calculateSlotsForStylist({
  required List<({DateTime start, DateTime end})> availableBlocks,
  required List<({DateTime start, DateTime end})> bookedWindows,
  required int durationMinutes,
  required String stylistId,
  required String stylistName,
  int slotIntervalMinutes = 30,
  int travelBufferMinutes = 15,
}) {
  final results = <AvailableTimeSlot>[];

  for (final block in availableBlocks) {
    var candidate = block.start;

    while (candidate
        .add(Duration(minutes: durationMinutes))
        .isBefore(block.end) ||
        candidate
            .add(Duration(minutes: durationMinutes))
            .isAtSameMomentAs(block.end)) {
      final candidateEnd = candidate.add(Duration(minutes: durationMinutes));

      // Check overlap with all booked windows (including travel buffer).
      final overlaps = bookedWindows.any((booked) {
        final bufferedBookedEnd =
            booked.end.add(Duration(minutes: travelBufferMinutes));
        // Slot overlaps if it starts before the buffered end and ends after start.
        return candidate.isBefore(bufferedBookedEnd) &&
            candidateEnd.isAfter(booked.start);
      });

      if (!overlaps) {
        results.add(AvailableTimeSlot(
          startAt: candidate,
          endAt: candidateEnd,
          stylistId: stylistId,
          stylistName: stylistName,
        ));
      }

      candidate = candidate.add(Duration(minutes: slotIntervalMinutes));
    }
  }

  results.sort((a, b) => a.startAt.compareTo(b.startAt));
  return results;
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final hour = dt.hour == 0
      ? 12
      : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final suffix = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
