import '../../../../core/constants/app_constants.dart';

String normalizeServiceAreaPostalCode(String postalCode) {
  final digitsOnly = postalCode.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.length >= 5) {
    return digitsOnly.substring(0, 5);
  }

  return postalCode.trim();
}

String resolveServiceAreaStatus({
  required String postalCode,
  String? storedStatus,
}) {
  final normalizedPostalCode = normalizeServiceAreaPostalCode(postalCode);
  if (normalizedPostalCode.length == 5) {
    return AppConstants.supportedServiceZipCodes.contains(normalizedPostalCode)
        ? 'serviceable'
        : 'out_of_area';
  }

  final trimmedStoredStatus = storedStatus?.trim();
  if (trimmedStoredStatus != null && trimmedStoredStatus.isNotEmpty) {
    return trimmedStoredStatus;
  }

  return 'pending_review';
}