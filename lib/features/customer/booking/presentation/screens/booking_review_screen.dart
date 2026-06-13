import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';
import '../../domain/booking_flow_state.dart';

/// Final review screen before the booking request is created and paid for.
class BookingReviewScreen extends ConsumerWidget {
  const BookingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BookingStepScaffold(
      displayStep: 6,
      stepNumber: 6,
      totalSteps: 6,
      title: 'Review your request',
      subtitle:
          'Confirm the request details, then continue to the secure deposit step.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back to details',
      onSecondaryPressed: () => context.go('/customer/book/details'),
      primaryLabel: 'Continue to payment',
      primaryIcon: Icons.lock_outline,
      onPrimaryPressed: bookingState.acceptedPolicy
          ? () => context.go('/customer/book/payment')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(bookingState.selectedAddress?.shortAddress ?? 'No address selected'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Household members',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                ...bookingState.selectedMembers.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(member.displayName),
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
                Text(
                  'Services',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                ...bookingState.serviceItems.map(
                  (item) {
                    final memberLabel = item.assignedMemberId != null
                        ? bookingState.householdMembers
                            .firstWhere(
                              (member) => member.id == item.assignedMemberId,
                              orElse: () => bookingState.householdMembers.first,
                            )
                            .displayName
                        : null;
                    final itemSummary = [
                      '${item.service.name} • ${item.service.durationMinutes} min • ${item.service.priceLabel}',
                      if (memberLabel != null) 'For: $memberLabel',
                      if (item.notes.isNotEmpty) item.notes,
                    ].join('\n');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                      child: Text(itemSummary),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Estimated starting total: ${bookingState.estimatedTotalCents == 0 ? 'Custom quote during admin review' : formatPriceCents(bookingState.estimatedTotalCents)}',
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text('Estimated duration: ${bookingState.estimatedDurationMinutes} min'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment time',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (bookingState.selectedSlotStartAt != null)
                  Text(
                    '${bookingState.preferredDate!.month}/${bookingState.preferredDate!.day}/${bookingState.preferredDate!.year}  •  ${bookingState.preferredTimeWindow}',
                  )
                else
                  Text(
                    bookingState.preferredDate == null
                        ? 'No date selected'
                        : '${bookingState.preferredDate!.month}/${bookingState.preferredDate!.day}/${bookingState.preferredDate!.year}',
                  ),
                const SizedBox(height: AppSpacing.xxs),
                if (bookingState.stylistPreferenceType == StylistPreferenceType.specific &&
                    bookingState.requestedStylistName != null)
                  Text('Preferred stylist: ${bookingState.requestedStylistName}')
                else
                  const Text('Stylist preference: Any Available Stylist'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (bookingState.customerNotes.trim().isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(bookingState.customerNotes),
                ],
              ),
            ),
          if (bookingState.customerNotes.trim().isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          if (bookingState.customerPhone != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Phone: ${bookingState.customerPhone}'),
                ],
              ),
            ),
          if (bookingState.customerPhone != null)
            const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reference photos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  bookingState.photoDrafts.isEmpty
                      ? 'No photos added'
                      : '${bookingState.photoDrafts.length} photo(s) ready to upload on submit',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you submit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(AppConstants.inHomeBookingPolicySummary),
                const SizedBox(height: AppSpacing.md),
                Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: bookingState.acceptedPolicy,
                    onChanged: (value) => ref
                        .read(bookingFlowControllerProvider.notifier)
                        .setPolicyAccepted(value ?? false),
                    title: const Text(
                      'I accept the in-home service and cancellation policy for this request.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}