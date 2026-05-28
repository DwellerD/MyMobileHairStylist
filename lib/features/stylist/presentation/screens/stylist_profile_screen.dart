import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/stylist_providers.dart';

/// Stylist profile summary for operational identity and safety contacts.
class StylistProfileScreen extends ConsumerWidget {
  const StylistProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final stylistProfileAsync = ref.watch(currentStylistProfileProvider);
    final authActionState = ref.watch(authActionControllerProvider);

    return stylistProfileAsync.when(
      data: (stylistProfile) {
        final displayName = appUserAsync.valueOrNull?.displayName ?? stylistProfile.displayName;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Profile',
              subtitle: 'Professional identity, specialties, and emergency contact details for field work.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              child: Row(
                children: [
                  ProfileAvatarPlaceholder(name: displayName, size: 64),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          stylistProfile.specialties.isEmpty
                              ? 'Specialties not added yet'
                              : stylistProfile.specialties.join(' · '),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Availability status', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(stylistProfile.isAcceptingBookings ? 'Accepting bookings' : 'Not accepting bookings'),
                  const SizedBox(height: AppSpacing.md),
                  Text('Bio', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(stylistProfile.bio?.trim().isNotEmpty == true
                      ? stylistProfile.bio!
                      : 'No stylist bio has been added yet.'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency contact', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(stylistProfile.emergencyContactName?.trim().isNotEmpty == true
                      ? stylistProfile.emergencyContactName!
                      : 'No emergency contact name on file.'),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(stylistProfile.emergencyContactPhone?.trim().isNotEmpty == true
                      ? stylistProfile.emergencyContactPhone!
                      : 'No emergency contact phone on file.'),
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
        child: EmptyState(
          title: 'Could not load the stylist profile',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.person_off_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(currentStylistProfileProvider),
        ),
      ),
    );
  }
}