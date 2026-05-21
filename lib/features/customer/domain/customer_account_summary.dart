class CustomerAccountSummary {
  const CustomerAccountSummary({
    required this.displayName,
    required this.email,
    required this.marketName,
    required this.primaryHouseholdName,
    required this.primaryHouseholdId,
    required this.householdCount,
    required this.householdMemberCount,
    required this.addressCount,
    required this.policyAcceptanceCount,
    required this.preferredContactMethod,
    required this.householdMembers,
  });

  final String displayName;
  final String email;
  final String? marketName;
  final String? primaryHouseholdName;
  final String? primaryHouseholdId;
  final int householdCount;
  final int householdMemberCount;
  final int addressCount;
  final int policyAcceptanceCount;
  final String? preferredContactMethod;
  final List<CustomerHouseholdMemberSummary> householdMembers;
}

class CustomerHouseholdMemberSummary {
  const CustomerHouseholdMemberSummary({
    required this.id,
    required this.name,
    required this.relationshipLabel,
    required this.detail,
  });

  final String id;
  final String name;
  final String relationshipLabel;
  final String detail;
}