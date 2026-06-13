import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_personalization.dart';
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
    final selectedPreset = ref.watch(themePresetProvider);

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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalization',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose your app color theme. Changes apply instantly and stay saved on this device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final preset in AppThemePreset.values) ...[
                    _ThemePresetTile(
                      preset: preset,
                      isSelected: preset == selectedPreset,
                      onTap: () => ref
                          .read(themePresetProvider.notifier)
                          .setPreset(preset),
                    ),
                    if (preset != AppThemePreset.values.last)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
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

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 1.4 : 1,
          ),
          color: isSelected
              ? colorScheme.secondaryContainer.withValues(alpha: 0.45)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [preset.previewPrimary, preset.previewAccent],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color:
                  isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}