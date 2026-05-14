import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Optional note capture step for appointment-specific context.
class BookingNotesScreen extends ConsumerStatefulWidget {
  const BookingNotesScreen({super.key});

  @override
  ConsumerState<BookingNotesScreen> createState() => _BookingNotesScreenState();
}

class _BookingNotesScreenState extends ConsumerState<BookingNotesScreen> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notesController.text != bookingState.customerNotes) {
      _notesController.text = bookingState.customerNotes;
      _notesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _notesController.text.length),
      );
    }

    return BookingStepScaffold(
      stepNumber: 4,
      totalSteps: 7,
      title: 'Add visit notes',
      subtitle:
          'Share anything helpful for the in-home visit, such as parking, entry instructions, or desired outcome notes.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back to services',
      onSecondaryPressed: () => context.go('/customer/book/services'),
      primaryLabel: 'Continue to photos',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: () {
        ref
            .read(bookingFlowControllerProvider.notifier)
            .setNotes(_notesController.text);
        context.go('/customer/book/photos');
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Examples: gate code, quiet entry requested, bring extra towels, or goals for the visit.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Add details for the admin or assigned stylist...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}