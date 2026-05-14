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