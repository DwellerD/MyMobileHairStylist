class StylistApplication {
  const StylistApplication({
    required this.id,
    required this.userProfileId,
    required this.applicantName,
    required this.email,
    required this.phone,
    required this.city,
    required this.stateCode,
    required this.licenseNumber,
    required this.yearsExperience,
    required this.specialties,
    required this.portfolioUrl,
    required this.motivation,
    required this.status,
    required this.marketId,
    required this.territoryId,
    required this.createdAt,
    required this.reviewedAt,
    required this.reviewerNotes,
  });

  final String id;
  final String userProfileId;
  final String applicantName;
  final String email;
  final String? phone;
  final String? city;
  final String? stateCode;
  final String? licenseNumber;
  final int? yearsExperience;
  final List<String> specialties;
  final String? portfolioUrl;
  final String? motivation;
  final String status;
  final String? marketId;
  final String? territoryId;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewerNotes;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}