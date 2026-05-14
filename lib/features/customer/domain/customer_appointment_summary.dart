class CustomerAppointmentSummary {
  const CustomerAppointmentSummary({
    required this.id,
    required this.status,
    required this.startsAt,
    required this.addressSummary,
    required this.serviceSummary,
    required this.participantSummary,
  });

  final String id;
  final String status;
  final DateTime startsAt;
  final String addressSummary;
  final String serviceSummary;
  final String participantSummary;

  bool get isUpcoming => startsAt.isAfter(DateTime.now());
}