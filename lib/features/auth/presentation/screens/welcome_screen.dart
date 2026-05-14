import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_scaffold_shell.dart';
import '../../../../shared/widgets/service_card.dart';

/// First screen shown to unauthenticated users.
///
/// In the real product this will become the polished marketing-style entry
/// point before users log in or create an account.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfigured = ref.watch(supabaseConfiguredProvider);

    return AppScaffoldShell(
      title: 'Premium in-home hair care',
      subtitle: AppConstants.appTagline,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Book luxury salon services for yourself or the whole household, with space for customer, stylist, and admin workflows in one app.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            onPressed: () => context.go('/login'),
            label: 'Log in',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            onPressed: () => context.go('/signup'),
            label: 'Create account',
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const AppSectionHeader(
            title: 'Popular mobile services',
            subtitle: 'A calm, premium booking flow will build on these core services.',
          ),
          const SizedBox(height: AppSpacing.md),
          const ServiceCard(
            title: 'Signature blowout',
            description: 'In-home styling with a polished finish for events or everyday luxury.',
            durationLabel: '60 min',
            priceLabel: 'MVP mock',
            badgeLabel: 'Popular',
          ),
          const SizedBox(height: AppSpacing.sm),
          const ServiceCard(
            title: 'Family appointment block',
            description: 'Bundle appointments for multiple family members in a single home visit.',
            durationLabel: 'Flexible',
            priceLabel: 'MVP mock',
            badgeLabel: 'Family',
          ),
          if (!isConfigured) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(
              title: 'Developer shortcut',
              subtitle: AppConstants.mockAuthNote,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              onPressed: () => context.go('/role-gate'),
              label: 'Open role switcher',
              icon: Icons.admin_panel_settings_outlined,
            ),
          ],
        ],
      ),
    );
  }
}