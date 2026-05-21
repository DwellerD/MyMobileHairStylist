/// One availability or unavailability block for a stylist's schedule.
///
/// Mirrors the `availability_blocks` table in Supabase.
class AvailabilityBlock {
  const AvailabilityBlock({
    required this.id,
    required this.stylistProfileId,
    required this.blockType,
    required this.startAt,
    required this.endAt,
    required this.notes,
    required this.marketId,
    required this.territoryId,
  });

  final String id;
  final String stylistProfileId;

  /// One of: 'available', 'unavailable', 'time_off', 'appointment_hold'.
  final String blockType;

  final DateTime startAt;
  final DateTime endAt;
  final String? notes;
  final String? marketId;
  final String? territoryId;

  bool get isAvailable => blockType == 'available';
  bool get isUnavailable => blockType == 'unavailable' || blockType == 'time_off';
  bool get isAppointmentHold => blockType == 'appointment_hold';

  Duration get duration => endAt.difference(startAt);
  int get durationMinutes => duration.inMinutes;

  String get typeLabel {
    switch (blockType) {
      case 'available':
        return 'Available';
      case 'unavailable':
        return 'Unavailable';
      case 'time_off':
        return 'Time off';
      case 'appointment_hold':
        return 'Appointment hold';
      default:
        return blockType;
    }
  }

  /// Short time range label: "9:00 AM – 12:00 PM".
  String get timeRangeLabel {
    return '${_formatTime(startAt)} – ${_formatTime(endAt)}';
  }

  /// Date label: "Mon, May 21".
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
    final dayName = days[(startAt.weekday - 1) % 7];
    return '$dayName, ${months[startAt.month]} ${startAt.day}';
  }
}

String _formatTime(DateTime dt) {
  final hour =
      dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final suffix = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
