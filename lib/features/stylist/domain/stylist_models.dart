/// Lightweight profile model used by the stylist-facing operational screens.
class StylistProfileSummary {
  const StylistProfileSummary({
    required this.id,
    required this.marketId,
    required this.territoryId,
    required this.displayName,
    required this.bio,
    required this.specialties,
    required this.isAcceptingBookings,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  final String id;
  final String? marketId;
  final String? territoryId;
  final String displayName;
  final String? bio;
  final List<String> specialties;
  final bool isAcceptingBookings;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
}

/// Compact appointment record rendered on the stylist home and schedule screens.
class StylistAppointmentSummary {
  const StylistAppointmentSummary({
    required this.id,
    required this.customerFirstName,
    required this.cityOrArea,
    required this.serviceSummary,
    required this.status,
    required this.checkInStatus,
    required this.startsAt,
    required this.addressSummary,
    required this.estimatedDurationMinutes,
  });

  final String id;
  final String customerFirstName;
  final String cityOrArea;
  final String serviceSummary;
  final String status;
  final String checkInStatus;
  final DateTime startsAt;
  final String addressSummary;
  final int estimatedDurationMinutes;
}

/// Local unassigned booking request available for a stylist to claim.
class ClaimableAppointmentSummary {
  const ClaimableAppointmentSummary({
    required this.id,
    required this.customerFirstName,
    required this.cityOrArea,
    required this.serviceSummary,
    required this.status,
    required this.startsAt,
    required this.addressSummary,
    required this.estimatedDurationMinutes,
    required this.requestedStylist,
  });

  final String id;
  final String customerFirstName;
  final String cityOrArea;
  final String serviceSummary;
  final String status;
  final DateTime startsAt;
  final String addressSummary;
  final int estimatedDurationMinutes;
  final bool requestedStylist;
}

/// Participant details shown on the stylist detail screen.
class StylistAppointmentParticipant {
  const StylistAppointmentParticipant({
    required this.name,
    required this.generalNotes,
    required this.sensoryNotes,
    required this.hairNotes,
  });

  final String name;
  final String? generalNotes;
  final String? sensoryNotes;
  final String? hairNotes;
}

/// Service line snapshot used on the appointment detail screen.
class StylistAppointmentServiceLine {
  const StylistAppointmentServiceLine({
    required this.name,
    required this.quantity,
    required this.durationMinutes,
    required this.lineNotes,
  });

  final String name;
  final int quantity;
  final int durationMinutes;
  final String? lineNotes;
}

/// Internal note visible to staff only.
class StylistInternalNote {
  const StylistInternalNote({
    required this.id,
    required this.noteType,
    required this.noteBody,
    required this.createdAt,
  });

  final String id;
  final String noteType;
  final String noteBody;
  final DateTime createdAt;
}

/// Photo metadata used in the stylist detail screen.
class StylistAppointmentPhoto {
  const StylistAppointmentPhoto({
    required this.id,
    required this.photoType,
    required this.caption,
    required this.storagePath,
    required this.createdAt,
  });

  final String id;
  final String photoType;
  final String? caption;
  final String storagePath;
  final DateTime createdAt;

  String get fileName => storagePath.split('/').last;
}

/// Check-in or check-out event recorded for an appointment.
class StylistCheckInEvent {
  const StylistCheckInEvent({
    required this.id,
    required this.eventType,
    required this.status,
    required this.recordedAt,
    required this.eventNotes,
  });

  final String id;
  final String eventType;
  final String status;
  final DateTime recordedAt;
  final String? eventNotes;
}

/// Full appointment detail used by the operational appointment screen.
class StylistAppointmentDetail {
  const StylistAppointmentDetail({
    required this.id,
    required this.status,
    required this.customerFirstName,
    required this.dateTime,
    required this.address,
    required this.accessNotes,
    required this.customerNotes,
    required this.estimatedDurationMinutes,
    required this.participants,
    required this.services,
    required this.photos,
    required this.internalNotes,
    required this.checkInEvents,
    required this.marketId,
    required this.territoryId,
    required this.assignedStylistProfileId,
  });

  final String id;
  final String status;
  final String customerFirstName;
  final DateTime dateTime;
  final String address;
  final String? accessNotes;
  final String? customerNotes;
  final int estimatedDurationMinutes;
  final List<StylistAppointmentParticipant> participants;
  final List<StylistAppointmentServiceLine> services;
  final List<StylistAppointmentPhoto> photos;
  final List<StylistInternalNote> internalNotes;
  final List<StylistCheckInEvent> checkInEvents;
  final String? marketId;
  final String? territoryId;
  final String? assignedStylistProfileId;

  String get checkInStatus {
    final hasCheckOut = checkInEvents.any((event) => event.eventType == 'check_out');
    if (hasCheckOut) {
      return 'Checked out';
    }

    final hasCheckIn = checkInEvents.any((event) => event.eventType == 'check_in');
    if (hasCheckIn) {
      return 'Checked in';
    }

    return 'Not started';
  }

  bool get canCheckIn => checkInEvents.every((event) => event.eventType != 'check_in');

  bool get canCheckOut {
    final hasCheckIn = checkInEvents.any((event) => event.eventType == 'check_in');
    final hasCheckOut = checkInEvents.any((event) => event.eventType == 'check_out');
    return hasCheckIn && !hasCheckOut;
  }

  bool get canMarkComplete => status != 'completed';

  String get servicesSummary {
    if (services.isEmpty) {
      return 'Services to be confirmed';
    }

    return services.map((service) => service.name).join(', ');
  }

  String get sensoryNotesSummary {
    final notes = participants
        .map((participant) => participant.sensoryNotes)
        .whereType<String>()
        .map((note) => note.trim())
        .where((note) => note.isNotEmpty)
        .toList(growable: false);

    if (notes.isEmpty) {
      return 'No sensory notes provided.';
    }

    return notes.join(' | ');
  }
}

/// Safety feed item shown on the safety tab.
class StylistSafetyEventSummary {
  const StylistSafetyEventSummary({
    required this.id,
    required this.appointmentId,
    required this.customerFirstName,
    required this.eventType,
    required this.status,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String? appointmentId;
  final String customerFirstName;
  final String eventType;
  final String status;
  final String details;
  final DateTime createdAt;
}