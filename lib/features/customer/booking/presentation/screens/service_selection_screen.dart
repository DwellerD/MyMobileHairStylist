import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../domain/booking_flow_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Step where customers choose the services they want included in the request.
class ServiceSelectionScreen extends ConsumerWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BookingStepScaffold(
      stepNumber: 3,
      totalSteps: 7,
      title: 'Choose your services',
      subtitle:
          'Pick one or more services for this request. We store the starting estimate now and let admin confirm the final scope later.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back to household',
      onSecondaryPressed: () => context.go('/customer/book/household-members'),
      primaryLabel: 'Continue to notes',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: bookingState.selectedServiceIds.isNotEmpty
          ? () => context.go('/customer/book/notes')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bookingState.services.isEmpty)
            const EmptyState(
              title: 'No services are published yet',
              description:
                  'Run the seed migration or add services in Supabase so customers can request appointments.',
              icon: Icons.content_cut_outlined,
            )
          else
            Column(
              children: bookingState.services
                  .map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        onTap: () => ref
                            .read(bookingFlowControllerProvider.notifier)
                            .toggleService(service.id),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: bookingState.selectedServiceIds.contains(service.id),
                              onChanged: (_) => ref
                                  .read(bookingFlowControllerProvider.notifier)
                                  .toggleService(service.id),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    service.description ??
                                        'Premium in-home salon care with final scheduling confirmed by admin.',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      Text('${service.durationMinutes} min'),
                                      const Spacer(),
                                      Text(
                                        service.priceLabel,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Starting estimate for this request',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  bookingState.selectedServiceIds.isEmpty
                      ? 'Choose services'
                      : '${bookingState.estimatedDurationMinutes} min • ${bookingState.estimatedTotalCents == 0 ? 'Custom quote' : formatPriceCents(bookingState.estimatedTotalCents)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (bookingState.selectedServiceIds.isNotEmpty)
            AppCard(
              child: Text(
                'Estimated starting total: ${bookingState.estimatedTotalCents == 0 ? 'Custom quote during review' : formatPriceCents(bookingState.estimatedTotalCents)}',
              ),
            ),
        ],
      ),
    );
  }
}