import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_screen_header.dart';
import '../../../../../shared/widgets/app_secondary_button.dart';
import '../providers/booking_flow_controller.dart';

/// Success state shown after a booking request has been written to Supabase.
class BookingSubmittedScreen extends ConsumerWidget {
  const BookingSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingFlowControllerProvider).valueOrNull;
    final appointmentId = bookingState?.submittedAppointmentId;
    final paymentStatus = bookingState?.paymentStatus ?? 'not_started';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const AppScreenHeader(
          title: 'Request submitted',
          subtitle:
              'Your appointment request has been saved. Admin will review availability, confirm scope, and follow up with the final schedule.',
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking reference',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(appointmentId ?? 'No request ID available yet'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deposit status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(_submittedPaymentStatusLabel(paymentStatus)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppSecondaryButton(
          label: 'View appointments',
          onPressed: () => context.go('/customer/appointments'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppPrimaryButton(
          label: 'Start another request',
          icon: Icons.refresh_outlined,
          onPressed: () async {
            await ref.read(bookingFlowControllerProvider.notifier).resetFlow();
            if (!context.mounted) {
              return;
            }

            context.go('/customer/book');
          },
        ),
      ],
    );
  }
}

String _submittedPaymentStatusLabel(String status) {
  switch (status) {
    case 'authorized':
      return 'Your deposit was authorized successfully.';
    case 'captured':
      return 'Your deposit has been captured.';
    case 'pending':
      return 'A payment intent was created and is waiting for completion.';
    case 'failed':
      return 'The payment step did not complete. Your request was still saved.';
    case 'refunded':
      return 'The recorded deposit was refunded.';
    case 'not_started':
    default:
      return 'No live deposit was collected in this session.';
  }
}