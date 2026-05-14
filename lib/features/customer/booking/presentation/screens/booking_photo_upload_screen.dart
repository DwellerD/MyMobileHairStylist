import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../domain/booking_flow_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Optional photo upload step for inspiration or hair-context images.
class BookingPhotoUploadScreen extends ConsumerWidget {
  const BookingPhotoUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BookingStepScaffold(
      stepNumber: 5,
      totalSteps: 7,
      title: 'Add reference photos',
      subtitle:
          'Photos are optional, but they help admin and stylists prepare for color work, hair goals, or sensory-aware planning.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back to notes',
      onSecondaryPressed: () => context.go('/customer/book/notes'),
      primaryLabel: 'Continue to preferred time',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: () => context.go('/customer/book/time'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            onPressed: bookingAsync.isLoading
                ? null
                : () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      type: FileType.image,
                      withData: true,
                    );

                    if (result == null) {
                      return;
                    }

                    final drafts = result.files
                        .where((file) => file.bytes != null)
                        .map(
                          (file) => BookingPhotoDraft(
                            fileName: file.name,
                            bytes: file.bytes!,
                          ),
                        )
                        .toList(growable: false);

                    if (drafts.isEmpty) {
                      return;
                    }

                    ref
                        .read(bookingFlowControllerProvider.notifier)
                        .addPhotoDrafts(drafts);
                  },
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Choose images'),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (bookingState.photoDrafts.isEmpty)
            const EmptyState(
              title: 'No photos added',
              description:
                  'You can skip this step if the booking does not need visual context.',
              icon: Icons.image_outlined,
            )
          else
            Column(
              children: bookingState.photoDrafts
                  .map(
                    (photo) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(photo.fileName)),
                            IconButton(
                              onPressed: () => ref
                                  .read(bookingFlowControllerProvider.notifier)
                                  .removePhotoDraft(photo.fileName),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}