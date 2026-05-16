/// Shared appointment statuses used across admin list filtering and editing.
const List<String> adminAppointmentStatuses = <String>[
  'requested',
  'approved',
  'assigned',
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
  'declined',
];

/// Compact appointment summary used by the admin dashboard and bookings list.
class AdminAppointmentSummary {
  const AdminAppointmentSummary({
    required this.id,
    required this.customerName,
    required this.customerFirstName,
    required this.cityOrArea,
    required this.serviceSummary,
    required this.status,
    required this.checkInStatus,
    required this.preferredDateLabel,
    required this.preferredTimeWindow,
    required this.estimatedTotalCents,
    required this.startsAt,
    required this.addressSummary,
    required this.assignedStylistName,
  });

  final String id;
  final String customerName;
  final String customerFirstName;
  final String cityOrArea;
  final String serviceSummary;
  final String status;
  final String checkInStatus;
  final String? preferredDateLabel;
  final String? preferredTimeWindow;
  final int? estimatedTotalCents;
  final DateTime startsAt;
  final String addressSummary;
  final String? assignedStylistName;
}

/// Dashboard-level summary model for admin operational metrics.
class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.pendingBookingRequests,
    required this.todayAppointments,
    required this.checkInAlerts,
    required this.recentSafetyEvents,
    required this.revenuePlaceholderCents,
  });

  final int pendingBookingRequests;
  final List<AdminAppointmentSummary> todayAppointments;
  final List<AdminAlertSummary> checkInAlerts;
  final List<AdminSafetyEventSummary> recentSafetyEvents;
  final int revenuePlaceholderCents;
}

/// Dashboard or operational alert item.
class AdminAlertSummary {
  const AdminAlertSummary({
    required this.title,
    required this.description,
    required this.appointmentId,
  });

  final String title;
  final String description;
  final String appointmentId;
}

/// Staff-visible safety event summary for dashboards and detail views.
class AdminSafetyEventSummary {
  const AdminSafetyEventSummary({
    required this.id,
    required this.appointmentId,
    required this.customerName,
    required this.eventType,
    required this.status,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String? appointmentId;
  final String customerName;
  final String eventType;
  final String status;
  final String details;
  final DateTime createdAt;
}

/// Customer directory row for admin management.
class AdminCustomerSummary {
  const AdminCustomerSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.householdNames,
    required this.appointmentCount,
  });

  final String id;
  final String name;
  final String email;
  final String status;
  final List<String> householdNames;
  final int appointmentCount;
}

/// Stylist directory row for admin review and assignment.
class AdminStylistSummary {
  const AdminStylistSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.marketName,
    required this.territoryName,
    required this.specialties,
    required this.isAcceptingBookings,
    required this.assignedAppointmentCount,
  });

  final String id;
  final String name;
  final String status;
  final String? marketName;
  final String? territoryName;
  final List<String> specialties;
  final bool isAcceptingBookings;
  final int assignedAppointmentCount;
}

class AdminStylistApplicationSummary {
  const AdminStylistApplicationSummary({
    required this.id,
    required this.applicantName,
    required this.email,
    required this.phone,
    required this.city,
    required this.stateCode,
    required this.status,
    required this.marketName,
    required this.territoryName,
    required this.specialties,
    required this.yearsExperience,
    required this.submittedAt,
    required this.reviewerNotes,
  });

  final String id;
  final String applicantName;
  final String email;
  final String? phone;
  final String? city;
  final String? stateCode;
  final String status;
  final String? marketName;
  final String? territoryName;
  final List<String> specialties;
  final int? yearsExperience;
  final DateTime submittedAt;
  final String? reviewerNotes;
}

class AdminUserAccessSummary {
  const AdminUserAccessSummary({
    required this.userProfileId,
    required this.name,
    required this.email,
    required this.roles,
  });

  final String userProfileId;
  final String name;
  final String email;
  final List<AdminUserRoleAssignment> roles;
}

class AdminUserRoleAssignment {
  const AdminUserRoleAssignment({
    required this.id,
    required this.role,
    required this.status,
    required this.isPrimary,
    required this.marketName,
    required this.territoryName,
  });

  final String id;
  final String role;
  final String status;
  final bool isPrimary;
  final String? marketName;
  final String? territoryName;
}

class AdminScopeOption {
  const AdminScopeOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

/// Service category plus the services beneath it.
class AdminServiceCategoryGroup {
  const AdminServiceCategoryGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.services,
  });

  final String id;
  final String name;
  final String? description;
  final List<AdminServiceSummary> services;
}

/// Editable service summary for admin service management.
class AdminServiceSummary {
  const AdminServiceSummary({
    required this.id,
    required this.serviceCategoryId,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.basePriceCents,
    required this.status,
  });

  final String id;
  final String serviceCategoryId;
  final String name;
  final String? description;
  final int durationMinutes;
  final int? basePriceCents;
  final String status;
}

/// Selectable stylist option used when assigning appointments.
class AdminStylistOption {
  const AdminStylistOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

/// Internal note displayed on the admin appointment detail screen.
class AdminInternalNote {
  const AdminInternalNote({
    required this.id,
    required this.noteType,
    required this.noteBody,
    required this.createdAt,
    required this.authorName,
  });

  final String id;
  final String noteType;
  final String noteBody;
  final DateTime createdAt;
  final String authorName;
}

/// Photo metadata surfaced to admins.
class AdminAppointmentPhoto {
  const AdminAppointmentPhoto({
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

/// Check-in history item for admin review.
class AdminCheckInEvent {
  const AdminCheckInEvent({
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

/// Household member details on the admin appointment screen.
class AdminAppointmentParticipant {
  const AdminAppointmentParticipant({
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

/// Service line details on the admin appointment screen.
class AdminAppointmentServiceLine {
  const AdminAppointmentServiceLine({
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

/// Full admin appointment detail model.
class AdminAppointmentDetail {
  const AdminAppointmentDetail({
    required this.id,
    required this.status,
    required this.customerName,
    required this.address,
    required this.participants,
    required this.services,
    required this.notes,
    required this.photos,
    required this.preferredDate,
    required this.preferredTimeWindow,
    required this.estimatedTotalCents,
    required this.assignedStylistName,
    required this.checkInEvents,
    required this.internalNotes,
    required this.safetyEvents,
    required this.availableStylists,
  });

  final String id;
  final String status;
  final String customerName;
  final String address;
  final List<AdminAppointmentParticipant> participants;
  final List<AdminAppointmentServiceLine> services;
  final String? notes;
  final List<AdminAppointmentPhoto> photos;
  final String? preferredDate;
  final String? preferredTimeWindow;
  final int? estimatedTotalCents;
  final String? assignedStylistName;
  final List<AdminCheckInEvent> checkInEvents;
  final List<AdminInternalNote> internalNotes;
  final List<AdminSafetyEventSummary> safetyEvents;
  final List<AdminStylistOption> availableStylists;
}

String formatMoneyCents(int? cents) {
  if (cents == null) {
    return 'TBD';
  }

  final dollars = cents / 100;
  return '\$${dollars.toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
}