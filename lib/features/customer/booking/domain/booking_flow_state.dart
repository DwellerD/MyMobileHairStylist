import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'service_area_validation.dart';

/// Simple address option used throughout the booking request flow.
class BookingAddressOption {
  const BookingAddressOption({
    required this.id,
    required this.marketId,
    required this.territoryId,
    required this.label,
    required this.line1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.serviceAreaStatus,
  });

  final String id;
  final String? marketId;
  final String? territoryId;
  final String label;
  final String line1;
  final String city;
  final String state;
  final String postalCode;
  final String serviceAreaStatus;

  String get shortAddress => '$line1, $city, $state $postalCode';

  bool get isServiceable =>
      resolveServiceAreaStatus(
        postalCode: postalCode,
        storedStatus: serviceAreaStatus,
      ) ==
      'serviceable';
}

/// Household member option available for family or individual appointments.
class BookingHouseholdMemberOption {
  const BookingHouseholdMemberOption({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.generalNotes,
    required this.sensoryNotes,
    required this.hairNotes,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? generalNotes;
  final String? sensoryNotes;
  final String? hairNotes;

  String get displayName {
    final parts = <String>[
      firstName.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];

    return parts.join(' ');
  }

  String get summaryLabel {
    if (dateOfBirth == null) {
      return 'No birthday added yet';
    }

    return 'Born ${dateOfBirth!.month}/${dateOfBirth!.day}/${dateOfBirth!.year}';
  }
}

/// Service option surfaced to customers while building a request.
class BookingServiceOption {
  const BookingServiceOption({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.basePriceCents,
    required this.allowsMultipleParticipants,
  });

  final String id;
  final String name;
  final String? description;
  final int durationMinutes;
  final int basePriceCents;
  final bool allowsMultipleParticipants;

  String get priceLabel => formatPriceCents(basePriceCents);
}

/// Local photo draft kept in memory until the booking request is submitted.
class BookingPhotoDraft {
  const BookingPhotoDraft({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

/// A single service item in the booking request, with optional member
/// assignment, per-service notes, and inspiration photos.
class BookingServiceItem {
  const BookingServiceItem({
    required this.id,
    required this.service,
    this.assignedMemberId,
    this.notes = '',
    this.photos = const [],
  });

  /// Locally-unique identifier (not persisted until booking is submitted).
  final String id;
  final BookingServiceOption service;

  /// Which household member this service is for, or null for "unspecified".
  final String? assignedMemberId;

  /// Service-specific notes (e.g. "just a trim", "please style after cut").
  final String notes;

  /// Inspiration / reference photos for this specific service.
  final List<BookingPhotoDraft> photos;

  BookingServiceItem copyWith({
    String? assignedMemberId,
    bool clearAssignedMember = false,
    String? notes,
    List<BookingPhotoDraft>? photos,
  }) {
    return BookingServiceItem(
      id: id,
      service: service,
      assignedMemberId: clearAssignedMember
          ? null
          : (assignedMemberId ?? this.assignedMemberId),
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }
}

/// Human-friendly time window shown to customers and persisted as text.
class BookingTimeWindowOption {
  const BookingTimeWindowOption({
    required this.key,
    required this.label,
    required this.description,
    required this.startTime,
    required this.endTime,
  });

  final String key;
  final String label;
  final String description;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
}

const List<BookingTimeWindowOption> bookingTimeWindowOptions =
    <BookingTimeWindowOption>[
  BookingTimeWindowOption(
    key: 'morning',
    label: 'Morning',
    description: 'Best for before-school or work-from-home visits.',
    startTime: TimeOfDay(hour: 9, minute: 0),
    endTime: TimeOfDay(hour: 12, minute: 0),
  ),
  BookingTimeWindowOption(
    key: 'midday',
    label: 'Midday',
    description: 'A balanced window for flexible home appointments.',
    startTime: TimeOfDay(hour: 12, minute: 0),
    endTime: TimeOfDay(hour: 15, minute: 0),
  ),
  BookingTimeWindowOption(
    key: 'afternoon',
    label: 'Afternoon',
    description: 'Ideal when everyone is home after school or work.',
    startTime: TimeOfDay(hour: 15, minute: 0),
    endTime: TimeOfDay(hour: 18, minute: 0),
  ),
];

BookingTimeWindowOption? findBookingTimeWindow(String? key) {
  if (key == null) {
    return null;
  }

  for (final option in bookingTimeWindowOptions) {
    if (option.key == key) {
      return option;
    }
  }

  return null;
}

String formatPriceCents(int cents) {
  final dollars = cents / 100;
  final digits = cents % 100 == 0 ? 0 : 2;
  return '\$${dollars.toStringAsFixed(digits)}';
}

/// Immutable booking request state shared across the step-by-step flow.
class BookingFlowState {
  const BookingFlowState({
    required this.householdId,
    required this.householdName,
    required this.addresses,
    required this.householdMembers,
    required this.services,
    required this.selectedAddressId,
    required this.selectedMemberIds,
    required this.serviceItems,
    required this.customerNotes,
    required this.preferredDate,
    required this.preferredTimeWindow,
    required this.paymentStatus,
    required this.acceptedPolicy,
    required this.submittedAppointmentId,
    this.customerPhone,
    this.requestedStylistId,
    this.requestedStylistName,
    this.selectedSlotStartAt,
  });

  final String householdId;
  final String householdName;
  final List<BookingAddressOption> addresses;
  final List<BookingHouseholdMemberOption> householdMembers;
  final List<BookingServiceOption> services;
  final String? selectedAddressId;
  final Set<String> selectedMemberIds;

  /// Services added to this booking request, each with optional member
  /// assignment, notes, and per-service photos.
  final List<BookingServiceItem> serviceItems;

  final String customerNotes;

  /// Customer contact phone number for in-home appointment logistics.
  final String? customerPhone;

  final DateTime? preferredDate;
  final String? preferredTimeWindow;
  final String paymentStatus;
  final bool acceptedPolicy;
  final String? submittedAppointmentId;

  /// Stylist the customer explicitly requested during booking.
  /// Null means "no preference" — any available qualified stylist may be assigned.
  final String? requestedStylistId;

  /// Display name of the requested stylist, stored for review screen display.
  final String? requestedStylistName;

  /// The specific slot start time the customer selected in the slot picker.
  /// When set, this overrides the generic preferredDate + preferredTimeWindow.
  final DateTime? selectedSlotStartAt;

  factory BookingFlowState.seeded({
    required String householdId,
    required String householdName,
    required List<BookingAddressOption> addresses,
    required List<BookingHouseholdMemberOption> householdMembers,
    required List<BookingServiceOption> services,
  }) {
    final serviceableAddress = addresses.cast<BookingAddressOption?>().firstWhere(
          (address) => address?.isServiceable ?? false,
          orElse: () => addresses.isEmpty ? null : addresses.first,
        );

    return BookingFlowState(
      householdId: householdId,
      householdName: householdName,
      addresses: addresses,
      householdMembers: householdMembers,
      services: services,
      selectedAddressId: serviceableAddress?.id,
      selectedMemberIds: <String>{},
      serviceItems: const <BookingServiceItem>[],
      customerNotes: '',
      customerPhone: null,
      preferredDate: null,
      preferredTimeWindow: null,
      paymentStatus: 'not_started',
      acceptedPolicy: false,
      submittedAppointmentId: null,
      requestedStylistId: null,
      requestedStylistName: null,
      selectedSlotStartAt: null,
    );
  }

  BookingAddressOption? get selectedAddress {
    if (selectedAddressId == null) {
      return null;
    }

    for (final address in addresses) {
      if (address.id == selectedAddressId) {
        return address;
      }
    }

    return null;
  }

  /// Convenience getter for the market ID of the selected address.
  String? get marketId => selectedAddress?.marketId;

  List<BookingHouseholdMemberOption> get selectedMembers {
    return householdMembers
        .where((member) => selectedMemberIds.contains(member.id))
        .toList(growable: false);
  }

  /// Unique service IDs from all service items, derived from [serviceItems].
  Set<String> get selectedServiceIds =>
      serviceItems.map((item) => item.service.id).toSet();

  /// Ordered list of services from [serviceItems].
  List<BookingServiceOption> get selectedServices =>
      serviceItems.map((item) => item.service).toList(growable: false);

  /// All reference photos across all service items.
  List<BookingPhotoDraft> get photoDrafts =>
      serviceItems.expand((item) => item.photos).toList(growable: false);

  int get estimatedTotalCents {
    return serviceItems.fold<int>(
      0,
      (total, item) => total + item.service.basePriceCents,
    );
  }

  int get estimatedDurationMinutes {
    return serviceItems.fold<int>(
      0,
      (total, item) => total + item.service.durationMinutes,
    );
  }

  BookingFlowState copyWith({
    String? householdId,
    String? householdName,
    List<BookingAddressOption>? addresses,
    List<BookingHouseholdMemberOption>? householdMembers,
    List<BookingServiceOption>? services,
    String? selectedAddressId,
    Set<String>? selectedMemberIds,
    List<BookingServiceItem>? serviceItems,
    String? customerNotes,
    String? customerPhone,
    bool clearCustomerPhone = false,
    DateTime? preferredDate,
    bool clearPreferredDate = false,
    String? preferredTimeWindow,
    bool clearPreferredTimeWindow = false,
    String? paymentStatus,
    bool? acceptedPolicy,
    String? submittedAppointmentId,
    bool clearSubmittedAppointmentId = false,
    String? requestedStylistId,
    bool clearRequestedStylist = false,
    String? requestedStylistName,
    DateTime? selectedSlotStartAt,
    bool clearSelectedSlot = false,
  }) {
    return BookingFlowState(
      householdId: householdId ?? this.householdId,
      householdName: householdName ?? this.householdName,
      addresses: addresses ?? this.addresses,
      householdMembers: householdMembers ?? this.householdMembers,
      services: services ?? this.services,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      serviceItems: serviceItems ?? this.serviceItems,
      customerNotes: customerNotes ?? this.customerNotes,
      customerPhone: clearCustomerPhone
          ? null
          : (customerPhone ?? this.customerPhone),
      preferredDate:
          clearPreferredDate ? null : (preferredDate ?? this.preferredDate),
      preferredTimeWindow: clearPreferredTimeWindow
          ? null
          : (preferredTimeWindow ?? this.preferredTimeWindow),
      paymentStatus: paymentStatus ?? this.paymentStatus,
      acceptedPolicy: acceptedPolicy ?? this.acceptedPolicy,
      submittedAppointmentId: clearSubmittedAppointmentId
          ? null
          : (submittedAppointmentId ?? this.submittedAppointmentId),
      requestedStylistId: clearRequestedStylist
          ? null
          : (requestedStylistId ?? this.requestedStylistId),
      requestedStylistName: clearRequestedStylist
          ? null
          : (requestedStylistName ?? this.requestedStylistName),
      selectedSlotStartAt: clearSelectedSlot
          ? null
          : (selectedSlotStartAt ?? this.selectedSlotStartAt),
    );
  }
}