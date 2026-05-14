import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';
import '../providers/admin_providers.dart';

/// Admin customer directory screen.
class AdminCustomersScreen extends ConsumerWidget {
  const AdminCustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(adminCustomersProvider);

    return customersAsync.when(
      data: (customers) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Customers',
              subtitle: 'The business owns the relationship, so customer households and appointment history stay visible to admins.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (customers.isEmpty)
              EmptyState(
                title: 'No customers found',
                description: 'Customer profiles will appear here after signup or admin provisioning.',
                icon: Icons.groups_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () => ref.invalidate(adminCustomersProvider),
              )
            else
              ...customers.map(
                (customer) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _DirectoryTile(
                    name: customer.name,
                    detail:
                        '${customer.householdNames.isEmpty ? 'No households yet' : customer.householdNames.join(', ')} · ${customer.appointmentCount} appointment(s) · Internal notes placeholder',
                    email: customer.email,
                    status: customer.status,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: EmptyState(
          title: 'Could not load customers',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.person_off_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(adminCustomersProvider),
        ),
      ),
    );
  }
}

class _DirectoryTile extends StatelessWidget {
  const _DirectoryTile({
    required this.name,
    required this.detail,
    required this.email,
    required this.status,
  });

  final String name;
  final String detail;
  final String email;
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ProfileAvatarPlaceholder(name: name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(email, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text('Status: $status', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}