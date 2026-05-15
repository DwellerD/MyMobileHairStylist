import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Step where the customer chooses who the appointment is for.
class HouseholdMemberSelectionScreen extends ConsumerStatefulWidget {
  const HouseholdMemberSelectionScreen({super.key});

  @override
  ConsumerState<HouseholdMemberSelectionScreen> createState() =>
      _HouseholdMemberSelectionScreenState();
}

class _HouseholdMemberSelectionScreenState
    extends ConsumerState<HouseholdMemberSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _sensoryNotesController = TextEditingController();
  final _hairNotesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _notesController.dispose();
    _sensoryNotesController.dispose();
    _hairNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isBusy = bookingAsync.isLoading;

    return BookingStepScaffold(
      stepNumber: 2,
      totalSteps: 8,
      title: 'Who is this appointment for?',
      subtitle:
          'Select one or more household members. You can also add a new child, partner, or family member now.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: isBusy,
      secondaryLabel: 'Back to address',
      onSecondaryPressed: () => context.go('/customer/book'),
      primaryLabel: 'Continue to services',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: bookingState.selectedMemberIds.isNotEmpty
          ? () => context.go('/customer/book/services')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bookingState.householdMembers.isEmpty)
            const EmptyState(
              title: 'No household members yet',
              description:
                  'Add the person receiving the service so your request can be reviewed cleanly by admin staff.',
              icon: Icons.people_outline,
            )
          else
            Column(
              children: bookingState.householdMembers
                  .map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        backgroundColor: bookingState.selectedMemberIds.contains(member.id)
                            ? AppColors.surfaceAlt
                            : null,
                        onTap: () => ref
                            .read(bookingFlowControllerProvider.notifier)
                            .toggleMember(member.id),
                        child: Row(
                          children: [
                            Checkbox(
                              value: bookingState.selectedMemberIds.contains(member.id),
                              onChanged: (_) => ref
                                  .read(bookingFlowControllerProvider.notifier)
                                  .toggleMember(member.id),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.displayName,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(member.summaryLabel),
                                  if ((member.sensoryNotes ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text('Sensory notes: ${member.sensoryNotes}'),
                                  ],
                                  if ((member.hairNotes ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text('Hair notes: ${member.hairNotes}'),
                                  ],
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add household member',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Add a name.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'Birthdate (optional)',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'General notes',
                      hintText: 'Any notes the team should know before the visit.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _sensoryNotesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Sensory notes',
                      hintText: 'Noise, pacing, or comfort preferences.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _hairNotesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Hair notes',
                      hintText: 'Texture, past cut, styling issues, or goals.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonalIcon(
                    onPressed: isBusy
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            final nameParts = _nameController.text.trim().split(RegExp(r'\s+'));
                            final firstName = nameParts.first;
                            final lastName = nameParts.length > 1
                                ? nameParts.sublist(1).join(' ')
                                : null;

                            await ref
                                .read(bookingFlowControllerProvider.notifier)
                                .createHouseholdMember(
                                  firstName: firstName,
                                  lastName: lastName,
                                  dateOfBirth: _parseBirthDate(_birthDateController.text),
                                  generalNotes: _notesController.text,
                                  sensoryNotes: _sensoryNotesController.text,
                                  hairNotes: _hairNotesController.text,
                                );

                            if (!mounted) {
                              return;
                            }

                            _nameController.clear();
                            _birthDateController.clear();
                            _notesController.clear();
                            _sensoryNotesController.clear();
                            _hairNotesController.clear();
                          },
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Save household member'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseBirthDate(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.trim());
  }
}