import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';

/// Customer profile and settings placeholder.
class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const AppScreenHeader(
          title: 'Profile',
          subtitle: 'Personal details, household preferences, and policy acknowledgements will live here.',
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          child: Row(
            children: [
              const ProfileAvatarPlaceholder(name: 'Maya Carter', size: 64),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maya Carter', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('maya@example.com', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const EmptyState(
          title: 'Preferences coming next',
          description: 'This placeholder will later show saved policies, communication settings, and member preferences.',
          icon: Icons.settings_outlined,
        ),
      ],
    );
  }
}