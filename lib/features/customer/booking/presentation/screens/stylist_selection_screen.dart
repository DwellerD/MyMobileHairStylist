import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../data/availability_repository.dart';
import '../../domain/availability_slot.dart';
import '../../domain/booking_flow_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Step 4 of 5 — customer chooses "Any Available Stylist" or a specific
/// stylist that is truly available for the selected date/time slot.
class StylistSelectionScreen extends ConsumerWidget {
  const StylistSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);

    return bookingAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Something went wrong: $e')),
      ),
      data: (bookingState) {
        final marketId = bookingState.marketId;
        final selectedSlotStartAt = bookingState.selectedSlotStartAt;

        if (marketId == null) {
          return const Scaffold(
            body: Center(child: Text('Unable to determine market.')),
          );
        }

        if (selectedSlotStartAt == null) {
          return BookingStepScaffold(
            displayStep: 4,
            stepNumber: 4,
            totalSteps: 6,
            title: 'Choose your stylist',
            subtitle: 'Select a date and time first, then pick your stylist preference.',
            primaryLabel: 'Back to date and time',
            onPrimaryPressed: () => context.go('/customer/book/time'),
            secondaryLabel: 'Back',
            onSecondaryPressed: () => context.go('/customer/book/time'),
            child: const EmptyState(
              title: 'Pick a time first',
              description: 'Choose your appointment date and time before selecting a stylist.',
              icon: Icons.schedule_outlined,
            ),
          );
        }

        return _StylistSelectionBody(
          selectedSlotStartAt: selectedSlotStartAt,
          durationMinutes: bookingState.estimatedDurationMinutes,
          marketId: marketId,
          territoryId: bookingState.territoryId,
          stylistPreferenceType: bookingState.stylistPreferenceType,
          requestedStylistId: bookingState.requestedStylistId,
        );
      },
    );
  }
}

class _StylistSelectionBody extends ConsumerWidget {
  const _StylistSelectionBody({
    required this.selectedSlotStartAt,
    required this.durationMinutes,
    required this.marketId,
    required this.territoryId,
    required this.stylistPreferenceType,
    this.requestedStylistId,
  });

  final DateTime selectedSlotStartAt;
  final int durationMinutes;
  final String marketId;
  final String? territoryId;
  final String stylistPreferenceType;
  final String? requestedStylistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stylistsAsync = ref.watch(
      _stylistsForSelectedSlotProvider(
        _StylistSlotQuery(
          selectedSlotStartAt: selectedSlotStartAt,
          durationMinutes: durationMinutes,
          marketId: marketId,
          territoryId: territoryId,
        ),
      ),
    );
    final hasAvailableStylists = stylistsAsync.valueOrNull?.isNotEmpty == true;

    return BookingStepScaffold(
      displayStep: 4,
      stepNumber: 4,
      totalSteps: 6,
      title: 'Choose your stylist',
      subtitle: 'Pick any available stylist or request a specific stylist for this appointment.',
      primaryLabel: hasAvailableStylists
          ? 'Continue with any available stylist'
          : 'Choose another time',
      onPrimaryPressed: hasAvailableStylists
          ? () {
              ref
                  .read(bookingFlowControllerProvider.notifier)
                  .setRequestedStylist(stylistId: null, stylistName: null);
              context.go('/customer/book/details');
            }
          : null,
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.go('/customer/book/time'),
      child: stylistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Could not load stylists',
          description: e.toString(),
          icon: Icons.warning_amber_rounded,
        ),
        data: (stylists) {
          if (stylists.isEmpty) {
            return const EmptyState(
              title: 'No stylists are available',
              description:
                  'No stylists are available for this appointment time. Please choose another time.',
              icon: Icons.person_search_outlined,
            );
          }

          final anySelected =
              stylistPreferenceType == StylistPreferenceType.any ||
              requestedStylistId == null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Any Available Stylist',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (anySelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Book with the first available stylist for this appointment.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              ref
                                  .read(bookingFlowControllerProvider.notifier)
                                  .setRequestedStylist(
                                    stylistId: null,
                                    stylistName: null,
                                  );
                              context.go('/customer/book/details');
                            },
                            child: const Text('Choose Any Available Stylist'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Available stylists',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 900;
                  if (isDesktop) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: stylists.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.45,
                      ),
                      itemBuilder: (context, index) => _StylistCard(
                        stylist: stylists[index],
                        isSelected: stylists[index].id == requestedStylistId,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: stylists.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _StylistCard(
                      stylist: stylists[index],
                      isSelected: stylists[index].id == requestedStylistId,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StylistCard extends ConsumerWidget {
  const _StylistCard({
    required this.stylist,
    required this.isSelected,
  });

  final BookableStylist stylist;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bio = stylist.bio?.trim();
    final initials = stylist.displayName.isNotEmpty
      ? stylist.displayName.substring(0, 1).toUpperCase()
      : '?';

    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    stylist.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Specialties: ${stylist.specialtiesSummary}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (stylist.yearsExperience != null) ...[
              SizedBox(height: AppSpacing.xxs),
              Text(
                '${stylist.yearsExperience} year${stylist.yearsExperience == 1 ? '' : 's'} experience',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (bio != null && bio.isNotEmpty) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                bio,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(bookingFlowControllerProvider.notifier).setRequestedStylist(
                        stylistId: stylist.id,
                        stylistName: stylist.displayName,
                      );
                  context.go('/customer/book/details');
                },
                child: Text('Book with ${stylist.displayName}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scoped provider ─────────────────────────────────────────────────────────

class _StylistSlotQuery {
  const _StylistSlotQuery({
    required this.selectedSlotStartAt,
    required this.durationMinutes,
    required this.marketId,
    this.territoryId,
  });

  final DateTime selectedSlotStartAt;
  final int durationMinutes;
  final String marketId;
  final String? territoryId;

  @override
  bool operator ==(Object other) =>
      other is _StylistSlotQuery &&
      other.selectedSlotStartAt == selectedSlotStartAt &&
      other.durationMinutes == durationMinutes &&
      other.marketId == marketId &&
      other.territoryId == territoryId;

  @override
  int get hashCode => Object.hash(
        selectedSlotStartAt,
        durationMinutes,
        marketId,
        territoryId,
      );
}

final _stylistsForSelectedSlotProvider = FutureProvider.autoDispose
    .family<List<BookableStylist>, _StylistSlotQuery>((ref, query) async {
  return ref.watch(availabilityRepositoryProvider).loadStylistsAvailableForSlot(
        slotStartAt: query.selectedSlotStartAt,
        durationMinutes: query.durationMinutes,
        marketId: query.marketId,
        territoryId: query.territoryId,
      );
});
