import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';

/// Household and family member management placeholder.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const AppScreenHeader(
          title: 'Family',
          subtitle: 'This area will manage household members and service notes for each person.',
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const AppSectionHeader(
          title: 'Household members',
          subtitle: 'Avatar placeholders are reusable across profiles and lists.',
        ),
        const SizedBox(height: AppSpacing.md),
        _FamilyMemberTile(
          name: 'Lena Carter',
          detail: 'Primary profile · Color and cut preferences',
        ),
        const SizedBox(height: AppSpacing.sm),
        _FamilyMemberTile(
          name: 'Noah Carter',
          detail: 'Child profile · Sensory-friendly notes saved',
        ),
      ],
    );
  }
}

class _FamilyMemberTile extends StatelessWidget {
  const _FamilyMemberTile({required this.name, required this.detail});

  final String name;
  final String detail;

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
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}