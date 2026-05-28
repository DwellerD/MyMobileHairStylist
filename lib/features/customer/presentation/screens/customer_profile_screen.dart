import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';
import '../providers/customer_account_providers.dart';

/// Customer profile and lightweight account summary.
class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(customerAccountSummaryProvider);
    final authActionState = ref.watch(authActionControllerProvider);

    return accountAsync.when(
      data: (account) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Profile',
              subtitle: 'Personal details, household readiness, and policy acknowledgements tied to your live account.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              child: Row(
                children: [
                  ProfileAvatarPlaceholder(name: account.displayName, size: 64),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.displayName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(account.email, style: Theme.of(context).textTheme.bodyMedium),
                        if (account.marketName != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text('Market: ${account.marketName!}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account summary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  Text('Preferred contact: ${account.preferredContactMethod ?? 'Not set yet'}'),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Households: ${account.householdCount}'),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Household members: ${account.householdMemberCount}'),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Saved addresses: ${account.addressCount}'),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Accepted policies on file: ${account.policyAcceptanceCount}'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const EmptyState(
              title: 'Preferences coming next',
              description: 'Communication settings and richer household preferences can now build on your live profile instead of mock data.',
              icon: Icons.settings_outlined,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            FilledButton.tonalIcon(
              onPressed: authActionState.isLoading
                  ? null
                  : () async {
                      await ref.read(authActionControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Log out'),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: EmptyState(
            title: 'Could not load your profile',
            description: error.toString().replaceFirst('Exception: ', ''),
            icon: Icons.person_off_outlined,
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(customerAccountSummaryProvider),
          ),
        ),
      ),
    );
  }
}