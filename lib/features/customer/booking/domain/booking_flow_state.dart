import 'dart:typed_data';

import 'package:flutter/material.dart';

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

  bool get isServiceable => serviceAreaStatus == 'serviceable';
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
    required this.selectedServiceIds,
    required this.customerNotes,
    required this.photoDrafts,
    required this.preferredDate,
    required this.preferredTimeWindow,
    required this.paymentStatus,
    required this.acceptedPolicy,
    required this.submittedAppointmentId,
  });

  final String householdId;
  final String householdName;
  final List<BookingAddressOption> addresses;
  final List<BookingHouseholdMemberOption> householdMembers;
  final List<BookingServiceOption> services;
  final String? selectedAddressId;
  final Set<String> selectedMemberIds;
  final Set<String> selectedServiceIds;
  final String customerNotes;
  final List<BookingPhotoDraft> photoDrafts;
  final DateTime? preferredDate;
  final String? preferredTimeWindow;
  final String paymentStatus;
  final bool acceptedPolicy;
  final String? submittedAppointmentId;

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
      selectedServiceIds: <String>{},
      customerNotes: '',
      photoDrafts: const <BookingPhotoDraft>[],
      preferredDate: null,
      preferredTimeWindow: null,
      paymentStatus: 'not_started',
      acceptedPolicy: false,
      submittedAppointmentId: null,
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

  List<BookingHouseholdMemberOption> get selectedMembers {
    return householdMembers
        .where((member) => selectedMemberIds.contains(member.id))
        .toList(growable: false);
  }

  List<BookingServiceOption> get selectedServices {
    return services
        .where((service) => selectedServiceIds.contains(service.id))
        .toList(growable: false);
  }

  int get estimatedTotalCents {
    return selectedServices.fold<int>(
      0,
      (total, service) => total + service.basePriceCents,
    );
  }

  int get estimatedDurationMinutes {
    return selectedServices.fold<int>(
      0,
      (total, service) => total + service.durationMinutes,
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
    Set<String>? selectedServiceIds,
    String? customerNotes,
    List<BookingPhotoDraft>? photoDrafts,
    DateTime? preferredDate,
    bool clearPreferredDate = false,
    String? preferredTimeWindow,
    bool clearPreferredTimeWindow = false,
    String? paymentStatus,
    bool? acceptedPolicy,
    String? submittedAppointmentId,
    bool clearSubmittedAppointmentId = false,
  }) {
    return BookingFlowState(
      householdId: householdId ?? this.householdId,
      householdName: householdName ?? this.householdName,
      addresses: addresses ?? this.addresses,
      householdMembers: householdMembers ?? this.householdMembers,
      services: services ?? this.services,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      selectedServiceIds: selectedServiceIds ?? this.selectedServiceIds,
      customerNotes: customerNotes ?? this.customerNotes,
      photoDrafts: photoDrafts ?? this.photoDrafts,
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
    );
  }
}