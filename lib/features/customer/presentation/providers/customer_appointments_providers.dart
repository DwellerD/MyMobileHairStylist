import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/customer_appointments_repository.dart';
import '../../domain/customer_appointment_summary.dart';

final customerAppointmentsProvider = FutureProvider<List<CustomerAppointmentSummary>>((ref) async {
  final appUser = await ref.watch(currentAppUserProvider.future);
  if (appUser == null) {
    return const <CustomerAppointmentSummary>[];
  }

  final repository = ref.watch(customerAppointmentsRepositoryProvider);
  return repository.loadAppointments(appUser: appUser);
});