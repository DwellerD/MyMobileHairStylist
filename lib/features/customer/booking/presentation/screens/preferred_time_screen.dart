import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../domain/booking_flow_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Step where the customer chooses a preferred day and arrival window.
class PreferredTimeScreen extends ConsumerWidget {
  const PreferredTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BookingStepScaffold(
      stepNumber: 6,
      totalSteps: 8,
      title: 'Choose your preferred timing',
      subtitle:
          'This is still a request. The admin team will confirm the exact day, arrival time, and assigned stylist after review.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back to photos',
      onSecondaryPressed: () => context.go('/customer/book/photos'),
        primaryLabel: 'Continue to payment',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: bookingState.preferredDate != null &&
              bookingState.preferredTimeWindow != null
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
                  'Preferred date',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  bookingState.preferredDate == null
                      ? 'No date selected yet'
                      : '${bookingState.preferredDate!.month}/${bookingState.preferredDate!.day}/${bookingState.preferredDate!.year}',
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final today = DateTime.now();
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: today.add(const Duration(days: 2)),
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 120)),
                    );

                    if (selectedDate == null) {
                      return;
                    }

                    ref
                        .read(bookingFlowControllerProvider.notifier)
                        .setPreferredDate(selectedDate);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Select date'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text(
            'Preferred arrival window',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...bookingTimeWindowOptions.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => ref
                    .read(bookingFlowControllerProvider.notifier)
                    .setPreferredTimeWindow(option.key),
                child: Row(
                  children: [
                    Icon(
                      bookingState.preferredTimeWindow == option.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: bookingState.preferredTimeWindow == option.key
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(option.description),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}