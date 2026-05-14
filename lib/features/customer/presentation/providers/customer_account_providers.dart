import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/customer_account_repository.dart';
import '../../domain/customer_account_summary.dart';

final customerAccountSummaryProvider = FutureProvider<CustomerAccountSummary>((ref) async {
  final appUser = await ref.watch(currentAppUserProvider.future);
  if (appUser == null) {
    throw Exception('Please sign in again to load your customer account.');
  }

  final repository = ref.watch(customerAccountRepositoryProvider);
  return repository.loadAccountSummary(appUser: appUser);
});