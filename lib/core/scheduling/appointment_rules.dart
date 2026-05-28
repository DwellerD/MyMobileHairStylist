/// Shared appointment scheduling rules used across customer, admin, and stylist
/// flows.
const int blockedHoursStartHour = 0;
const int blockedHoursEndHour = 6;

const String blockedAvailabilityMessage =
    'Availability cannot be set during blocked hours.';

bool timeRangesOverlap({
  required DateTime startA,
  required DateTime endA,
  required DateTime startB,
  required DateTime endB,
}) {
  return startA.isBefore(endB) && endA.isAfter(startB);
}

bool rangeIsContained({
  required DateTime outerStart,
  required DateTime outerEnd,
  required DateTime innerStart,
  required DateTime innerEnd,
}) {
  return (innerStart.isAtSameMomentAs(outerStart) ||
          innerStart.isAfter(outerStart)) &&
      (innerEnd.isAtSameMomentAs(outerEnd) || innerEnd.isBefore(outerEnd));
}

/// Returns true when [startAt]..[endAt] overlaps blocked hours (12:00 AM-6:00 AM)
/// on any day that the range touches.
bool overlapsBlockedHours(DateTime startAt, DateTime endAt) {
  if (!endAt.isAfter(startAt)) {
    return false;
  }

  var cursor = DateTime(startAt.year, startAt.month, startAt.day);
  final lastDay = DateTime(endAt.year, endAt.month, endAt.day);

  while (!cursor.isAfter(lastDay)) {
    final blockedStart = DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
      blockedHoursStartHour,
    );
    final blockedEnd = DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
      blockedHoursEndHour,
    );

    if (timeRangesOverlap(
      startA: startAt,
      endA: endAt,
      startB: blockedStart,
      endB: blockedEnd,
    )) {
      return true;
    }

    cursor = cursor.add(const Duration(days: 1));
  }

  return false;
}
