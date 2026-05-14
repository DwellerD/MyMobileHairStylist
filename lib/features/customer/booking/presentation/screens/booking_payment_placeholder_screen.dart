import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';
import '../../domain/booking_flow_state.dart';

/// Temporary booking payment step reserved for the future Stripe Payment Sheet.
class BookingPaymentPlaceholderScreen extends ConsumerWidget {
  const BookingPaymentPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BookingStepScaffold(
      stepNumber: 7,
      totalSteps: 8,
      title: 'Payment placeholder',
      subtitle:
          'This step reserves the future Stripe deposit experience without processing any live payments in the MVP.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back to preferred time',
      onSecondaryPressed: () => context.go('/customer/book/time'),
      primaryLabel: 'Continue without payment for MVP',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: () {
        ref.read(bookingFlowControllerProvider.notifier).setPaymentStatus('not_started');
        context.go('/customer/book/review');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planned Stripe deposit step',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Estimated booking total: ${bookingState.estimatedTotalCents == 0 ? 'Custom quote during review' : formatPriceCents(bookingState.estimatedTotalCents)}',
                ),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Future behavior: show a deposit amount after a server-side PaymentIntent is created.',
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
                  'Payment status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_paymentStatusLabel(bookingState.paymentStatus)),
                const SizedBox(height: AppSpacing.md),
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
                  'Safe implementation notes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'The app must never create PaymentIntents directly or embed Stripe secret keys.',
                ),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Use a Supabase Edge Function to create PaymentIntents server-side and return only the client secret needed for Stripe Payment Sheet.',
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
                  'Developer TODOs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                // TODO: Replace this placeholder card with Stripe Payment Sheet
                // after a server-side Edge Function returns a client secret.
                // TODO: Persist Stripe customer ids and PaymentIntent ids in safe
                // backend-managed references only, never in client-side secrets.
                // TODO: Support deposit capture here first, then separate flows
                // for remaining balance, tip collection, refunds, and fees.
                const Text('Stripe Payment Sheet will be mounted in this screen later.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _paymentStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pending placeholder';
    case 'authorized':
      return 'Authorized placeholder';
    case 'captured':
      return 'Captured placeholder';
    case 'refunded':
      return 'Refunded placeholder';
    case 'failed':
      return 'Failed placeholder';
    case 'not_started':
    default:
      return 'Not started in MVP';
  }
}