import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';
import '../providers/admin_providers.dart';

/// Admin stylist directory screen.
class AdminStylistsScreen extends ConsumerWidget {
  const AdminStylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stylistsAsync = ref.watch(adminStylistsProvider);

    return stylistsAsync.when(
      data: (stylists) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Stylists',
              subtitle: 'Mobile staffing directory for assignments now, with room to grow into onboarding and approval workflows later.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (stylists.isEmpty)
              EmptyState(
                title: 'No stylists found',
                description: 'Stylist profiles will appear here after admin provisioning.',
                icon: Icons.content_cut_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () => ref.invalidate(adminStylistsProvider),
              )
            else
              ...stylists.map(
                (stylist) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _StylistTile(
                    name: stylist.name,
                    detail:
                        '${stylist.status} · ${stylist.marketName ?? 'No market'}${stylist.territoryName != null ? ' · ${stylist.territoryName}' : ''} · ${stylist.assignedAppointmentCount} assigned appointment(s)',
                    specialties: stylist.specialties,
                    isAcceptingBookings: stylist.isAcceptingBookings,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: EmptyState(
          title: 'Could not load stylists',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.person_off_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(adminStylistsProvider),
        ),
      ),
    );
  }
}

class _StylistTile extends StatelessWidget {
  const _StylistTile({
    required this.name,
    required this.detail,
    required this.specialties,
    required this.isAcceptingBookings,
  });

  final String name;
  final String detail;
  final List<String> specialties;
  final bool isAcceptingBookings;

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
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  specialties.isEmpty ? 'No specialties listed' : specialties.join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isAcceptingBookings ? 'Accepting bookings' : 'Not accepting bookings',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}