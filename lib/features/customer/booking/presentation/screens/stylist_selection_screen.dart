import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../data/availability_repository.dart';
import '../../domain/availability_slot.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Step 6 of 9 — lets the customer express a preference for a specific stylist.
///
/// This step is optional. Tapping "No preference" skips to the next step.
/// The company brand always leads; individual stylist profiles are kept brief.
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

        if (marketId == null) {
          return const Scaffold(
            body: Center(child: Text('Unable to determine market.')),
          );
        }

        return _StylistSelectionBody(
          marketId: marketId,
          territoryId: bookingState.territoryId,
          requestedStylistId: bookingState.requestedStylistId,
        );
      },
    );
  }
}

class _StylistSelectionBody extends ConsumerWidget {
  const _StylistSelectionBody({
    required this.marketId,
    required this.territoryId,
    this.requestedStylistId,
  });

  final String marketId;
  final String? territoryId;
  final String? requestedStylistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stylistsAsync = ref.watch(
      _bookableStylistsProvider((marketId: marketId, territoryId: territoryId)),
    );

    return BookingStepScaffold(
      stepNumber: 6,
      totalSteps: 9,
      title: 'Choose a preferred stylist',
      subtitle: 'This is optional — skip if you have no preference.',
      primaryLabel: 'No preference, continue',
      onPrimaryPressed: () {
        ref
            .read(bookingFlowControllerProvider.notifier)
            .setRequestedStylist(stylistId: null, stylistName: null);
        context.go('/customer/book/time');
      },
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.go('/customer/book/photos'),
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
              title: 'No stylists available',
              description:
                  'No stylists are available in your area right now. Tap continue to let us assign someone.',
              icon: Icons.person_search_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stylists.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final stylist = stylists[index];
              final isSelected = stylist.id == requestedStylistId;

              return AppCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref
                        .read(bookingFlowControllerProvider.notifier)
                        .setRequestedStylist(
                          stylistId: stylist.id,
                          stylistName: stylist.displayName,
                        );
                    context.go('/customer/book/time');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            stylist.displayName.isNotEmpty
                                ? stylist.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stylist.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stylist.specialtiesSummary,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              if (stylist.bio != null &&
                                  stylist.bio!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  stylist.bio!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Scoped provider ─────────────────────────────────────────────────────────

final _bookableStylistsProvider = FutureProvider.autoDispose
    .family<List<BookableStylist>, ({String marketId, String? territoryId})>((ref, query) async {
  return ref.watch(availabilityRepositoryProvider).loadBookableStylists(
        marketId: query.marketId,
        territoryId: query.territoryId,
      );
});
