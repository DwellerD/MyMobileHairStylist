import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/payments/stripe_config.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../data/booking_payment_repository.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';
import '../../domain/booking_flow_state.dart';

/// Booking payment step that can use a server-created Stripe PaymentIntent.
class BookingPaymentPlaceholderScreen extends ConsumerStatefulWidget {
  const BookingPaymentPlaceholderScreen({super.key});

  @override
  ConsumerState<BookingPaymentPlaceholderScreen> createState() =>
      _BookingPaymentPlaceholderScreenState();
}

class _BookingPaymentPlaceholderScreenState
    extends ConsumerState<BookingPaymentPlaceholderScreen> {
  bool _isProcessing = false;
  String? _localError;

  bool _supportsLivePayment(BookingFlowState state) {
    return !kIsWeb &&
        StripeConfig.isConfigured &&
        state.estimatedTotalCents > 0;
  }

  Future<void> _handlePrimaryPressed(BookingFlowState bookingState) async {
    final controller = ref.read(bookingFlowControllerProvider.notifier);
    final supportsLivePayment = _supportsLivePayment(bookingState);

    if (bookingState.submittedAppointmentId != null &&
        (!supportsLivePayment ||
            bookingState.paymentStatus == 'authorized' ||
            bookingState.paymentStatus == 'captured')) {
      context.go('/customer/book/submitted');
      return;
    }

    setState(() {
      _isProcessing = true;
      _localError = null;
    });

    try {
      final appointmentId = await controller.ensureSubmittedAppointmentId();
      final refreshedState = ref.read(bookingFlowControllerProvider).valueOrNull;
      if (refreshedState == null) {
        throw Exception('Booking details are still loading.');
      }

      if (!supportsLivePayment) {
        controller.setPaymentStatus('not_started');
        if (!mounted) {
          return;
        }
        context.go('/customer/book/submitted');
        return;
      }

      controller.setPaymentStatus('pending');
      final paymentIntent = await ref.read(bookingPaymentRepositoryProvider).createPaymentIntent(
            appointmentId: appointmentId,
            amountCents: refreshedState.estimatedTotalCents,
          );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent.clientSecret,
          merchantDisplayName: 'My Mobile Hair Stylist',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      controller.setPaymentStatus('authorized');
      if (!mounted) {
        return;
      }
      context.go('/customer/book/submitted');
    } on StripeException catch (error) {
      controller.setPaymentStatus('failed');
      setState(() {
        _localError = error.error.localizedMessage ?? 'Unable to complete the Stripe payment step.';
      });
    } catch (error) {
      ref.read(bookingFlowControllerProvider.notifier).setPaymentStatus('failed');
      setState(() {
        _localError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final supportsLivePayment = _supportsLivePayment(bookingState);
    final hasSubmittedRequest = bookingState.submittedAppointmentId != null;
    final isPaid = bookingState.paymentStatus == 'authorized' ||
        bookingState.paymentStatus == 'captured';

    return BookingStepScaffold(
      displayStep: 5,
      showProgress: false,
      stepNumber: 5,
      totalSteps: 5,
      title: 'Secure deposit',
      subtitle:
          supportsLivePayment
              ? 'Your booking request will be created first, then the app will open Stripe Payment Sheet using a server-created PaymentIntent.'
              : 'This build can still submit the booking request safely, but live Stripe deposit collection is only available when a mobile build has STRIPE_PUBLISHABLE_KEY configured and a priced booking total.',
      errorMessage: _localError ?? bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading || _isProcessing,
      secondaryLabel: hasSubmittedRequest ? 'View submitted request' : 'Back to review',
      onSecondaryPressed: hasSubmittedRequest
          ? () => context.go('/customer/book/submitted')
          : () => context.go('/customer/book/review'),
      primaryLabel: isPaid
          ? 'View submitted request'
          : supportsLivePayment
              ? (hasSubmittedRequest ? 'Pay deposit now' : 'Submit request & pay deposit')
              : (hasSubmittedRequest ? 'View submitted request' : 'Submit request'),
      primaryIcon: isPaid ? Icons.check_circle_outline : Icons.lock_outline,
      onPrimaryPressed: () => _handlePrimaryPressed(bookingState),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Estimated booking total: ${bookingState.estimatedTotalCents == 0 ? 'Custom quote during review' : formatPriceCents(bookingState.estimatedTotalCents)}',
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  supportsLivePayment
                      ? 'The deposit request is created server-side and only the client secret reaches the app.'
                      : 'Live deposit collection is currently unavailable in this build, so the app will safely submit the request without launching Payment Sheet.',
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
                if (bookingState.submittedAppointmentId != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('Booking reference: ${bookingState.submittedAppointmentId}'),
                ],
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
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  !StripeConfig.isConfigured
                      ? 'Missing STRIPE_PUBLISHABLE_KEY in this app build.'
                      : kIsWeb
                          ? 'Stripe Payment Sheet is not launched from the web build.'
                          : 'Stripe client configuration is present for a mobile build.',
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
                  'Current behavior',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasSubmittedRequest
                      ? 'The booking request has already been created. You can retry payment or continue to the submitted state.'
                      : 'The primary action creates the booking request first so the payment function can attach the PaymentIntent to a real appointment record.',
                ),
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
      return 'Payment intent created';
    case 'authorized':
      return 'Deposit authorized';
    case 'captured':
      return 'Deposit captured';
    case 'refunded':
      return 'Deposit refunded';
    case 'failed':
      return 'Payment failed or was canceled';
    case 'not_started':
    default:
      return 'Not started';
  }
}