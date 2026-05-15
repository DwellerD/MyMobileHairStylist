import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';
import '../../domain/booking_flow_state.dart';

/// Final review screen before the booking request is submitted to Supabase.
class BookingReviewScreen extends ConsumerWidget {
  const BookingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedWindow = findBookingTimeWindow(bookingState.preferredTimeWindow);

    return BookingStepScaffold(
      stepNumber: 8,
      totalSteps: 8,
      title: 'Review your request',
      subtitle:
          'This request will be saved in Supabase, then reviewed by admin before a stylist is confirmed.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back to payment',
      onSecondaryPressed: () => context.go('/customer/book/payment'),
      primaryLabel: 'Submit booking request',
      primaryIcon: Icons.send_outlined,
      onPrimaryPressed: bookingState.acceptedPolicy
          ? () async {
              await ref
                  .read(bookingFlowControllerProvider.notifier)
                  .submitBookingRequest();

              if (!context.mounted) {
                return;
              }

              final latestState = ref.read(bookingFlowControllerProvider).valueOrNull;
              if (latestState?.submittedAppointmentId != null) {
                context.go('/customer/book/submitted');
              }
            }
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
                ...bookingState.selectedServices.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(
                      '${service.name} • ${service.durationMinutes} min • ${service.priceLabel}',
                    ),
                  ),
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
                  'Preferred timing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  bookingState.preferredDate == null
                      ? 'No date selected'
                      : '${bookingState.preferredDate!.month}/${bookingState.preferredDate!.day}/${bookingState.preferredDate!.year}',
                ),
                if (selectedWindow != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(selectedWindow.label),
                ],
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
                  'Payment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Status: ${bookingState.paymentStatus == 'not_started' ? 'Continue without payment for MVP' : bookingState.paymentStatus}',
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(AppConstants.bookingPaymentDisclaimer),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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