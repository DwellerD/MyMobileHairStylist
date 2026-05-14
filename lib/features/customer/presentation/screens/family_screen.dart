import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';
import '../../domain/customer_account_summary.dart';
import '../providers/customer_account_providers.dart';

/// Customer household members and notes.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(customerAccountSummaryProvider);

    return accountAsync.when(
      data: (account) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            AppScreenHeader(
              title: 'Family',
              subtitle: account.primaryHouseholdName == null
                  ? 'Your household members will appear here after your first booking setup.'
                  : 'Manage notes and member context for ${account.primaryHouseholdName}.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.primaryHouseholdName ?? 'No household yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${account.householdCount} household${account.householdCount == 1 ? '' : 's'} · ${account.householdMemberCount} member${account.householdMemberCount == 1 ? '' : 's'} · ${account.addressCount} address${account.addressCount == 1 ? '' : 'es'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(
              title: 'Household members',
              subtitle: 'These profiles now come from your Supabase household records.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (account.householdMembers.isEmpty)
              const EmptyState(
                title: 'No household members yet',
                description: 'Start a booking and add family members to build your reusable household list.',
                icon: Icons.groups_outlined,
              )
            else
              ...account.householdMembers.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FamilyMemberTile(
                    name: member.name,
                    detail: member.detail,
                    relationshipLabel: member.relationshipLabel,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: EmptyState(
            title: 'Could not load your household',
            description: error.toString().replaceFirst('Exception: ', ''),
            icon: Icons.group_off_outlined,
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(customerAccountSummaryProvider),
          ),
        ),
      ),
    );
  }
}

class _FamilyMemberTile extends StatelessWidget {
  const _FamilyMemberTile({
    required this.name,
    required this.detail,
    required this.relationshipLabel,
  });

  final String name;
  final String detail;
  final String relationshipLabel;

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
                Text(relationshipLabel, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}