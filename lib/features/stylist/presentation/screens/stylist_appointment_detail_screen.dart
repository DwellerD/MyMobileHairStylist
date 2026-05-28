import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/stylist_providers.dart';

/// Operational detail screen for one assigned appointment.
class StylistAppointmentDetailScreen extends ConsumerStatefulWidget {
  const StylistAppointmentDetailScreen({
    required this.appointmentId,
    super.key,
  });

  final String appointmentId;

  @override
  ConsumerState<StylistAppointmentDetailScreen> createState() =>
      _StylistAppointmentDetailScreenState();
}

class _StylistAppointmentDetailScreenState
    extends ConsumerState<StylistAppointmentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(stylistAppointmentDetailProvider(widget.appointmentId));
    final actionState = ref.watch(stylistActionControllerProvider);
    final actionError = actionState.hasError
        ? actionState.asError!.error.toString().replaceFirst('Exception: ', '')
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment details')),
      body: detailAsync.when(
        data: (detail) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppScreenHeader(
                title: detail.customerFirstName,
                subtitle: 'Safety-focused visit details and operational actions for this appointment.',
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (actionError != null) ...[
                AppCard(
                  backgroundColor: AppColors.surfaceAlt,
                  child: Text(actionError),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LabelValueRow(label: 'Date and time', value: _formatDateTime(detail.dateTime)),
                    _LabelValueRow(label: 'Status', value: _titleCase(detail.status)),
                    _LabelValueRow(label: 'Check-in status', value: detail.checkInStatus),
                    _LabelValueRow(label: 'Address', value: detail.address),
                    _LabelValueRow(
                      label: 'Parking / access notes',
                      value: detail.accessNotes?.trim().isNotEmpty == true
                          ? detail.accessNotes!
                          : 'No access notes provided.',
                    ),
                    _LabelValueRow(
                      label: 'Estimated duration',
                      value: '${detail.estimatedDurationMinutes} min',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (detail.status == 'pending_stylist_confirmation') ...[
                AppPrimaryButton(
                  label: actionState.isLoading ? 'Working...' : 'Accept Appointment',
                  icon: Icons.check_circle_outline,
                  onPressed: actionState.isLoading
                      ? null
                      : () => _runAction(
                            () => ref
                                .read(stylistActionControllerProvider.notifier)
                                .acceptAssignedAppointment(
                                  appointmentId: widget.appointmentId,
                                ),
                          ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSecondaryButton(
                  label: 'Decline Appointment',
                  icon: Icons.cancel_outlined,
                  onPressed: actionState.isLoading
                      ? null
                      : () => _runAction(
                            () => ref
                                .read(stylistActionControllerProvider.notifier)
                                .declineAssignedAppointment(
                                  appointmentId: widget.appointmentId,
                                ),
                          ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppSecondaryButton(
                label: 'Navigation placeholder',
                icon: Icons.navigation_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigation integration will connect here next.')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppPrimaryButton(
                label: actionState.isLoading ? 'Working...' : 'Check In',
                icon: Icons.login_outlined,
                onPressed: !detail.canCheckIn || actionState.isLoading
                    ? null
                    : () => _runAction(
                          () => ref
                              .read(stylistActionControllerProvider.notifier)
                              .createCheckIn(appointmentId: widget.appointmentId),
                        ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppPrimaryButton(
                label: actionState.isLoading ? 'Working...' : 'Check Out',
                icon: Icons.logout_outlined,
                onPressed: !detail.canCheckOut || actionState.isLoading
                    ? null
                    : () => _runAction(
                          () => ref
                              .read(stylistActionControllerProvider.notifier)
                              .createCheckOut(appointmentId: widget.appointmentId),
                        ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppPrimaryButton(
                label: actionState.isLoading ? 'Working...' : 'Mark Complete',
                icon: Icons.check_circle_outline,
                onPressed: !detail.canMarkComplete || actionState.isLoading
                    ? null
                    : () => _runAction(
                          () => ref
                              .read(stylistActionControllerProvider.notifier)
                              .markAppointmentComplete(appointmentId: widget.appointmentId),
                        ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'Add Internal Note',
                icon: Icons.note_add_outlined,
                onPressed: actionState.isLoading ? null : _showAddInternalNoteDialog,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: 'SOS / Safety Event',
                icon: Icons.warning_amber_outlined,
                onPressed: actionState.isLoading ? null : _confirmSafetyEvent,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _SectionCard(
                title: 'Household members receiving services',
                child: detail.participants.isEmpty
                    ? const Text('No participants attached yet.')
                    : Column(
                        children: detail.participants
                            .map(
                              (participant) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      participant.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      participant.generalNotes?.trim().isNotEmpty == true
                                          ? participant.generalNotes!
                                          : 'No participant-specific notes.',
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Sensory notes: ${participant.sensoryNotes?.trim().isNotEmpty == true ? participant.sensoryNotes! : 'None provided'}',
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Hair notes: ${participant.hairNotes?.trim().isNotEmpty == true ? participant.hairNotes! : 'None provided'}',
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                title: 'Services',
                child: detail.services.isEmpty
                    ? const Text('No service lines attached yet.')
                    : Column(
                        children: detail.services
                            .map(
                              (service) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${service.name} x${service.quantity}',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text('${service.durationMinutes} min'),
                                    if (service.lineNotes?.trim().isNotEmpty == true) ...[
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(service.lineNotes!),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                title: 'Customer notes',
                child: Text(
                  detail.customerNotes?.trim().isNotEmpty == true
                      ? detail.customerNotes!
                      : 'No customer notes provided.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                title: 'Sensory notes',
                child: Text(detail.sensoryNotesSummary),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                title: 'Uploaded reference photos',
                child: detail.photos.isEmpty
                    ? const Text('No reference photos uploaded.')
                    : Column(
                        children: detail.photos
                            .map(
                              (photo) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.image_outlined),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            photo.caption?.trim().isNotEmpty == true
                                                ? photo.caption!
                                                : photo.fileName,
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: AppSpacing.xxs),
                                          Text('${_titleCase(photo.photoType)} · ${_formatDateTime(photo.createdAt)}'),
                                          const SizedBox(height: AppSpacing.xxs),
                                          Text(photo.storagePath),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                title: 'Internal notes',
                child: detail.internalNotes.isEmpty
                    ? const Text('No internal notes recorded yet.')
                    : Column(
                        children: detail.internalNotes
                            .map(
                              (note) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_titleCase(note.noteType)} · ${_formatDateTime(note.createdAt)}',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(note.noteBody),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                title: 'Check-in history',
                child: detail.checkInEvents.isEmpty
                    ? const Text('No check-in activity recorded yet.')
                    : Column(
                        children: detail.checkInEvents
                            .map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_titleCase(event.eventType.replaceAll('_', ' '))} · ${_formatDateTime(event.recordedAt)}',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(event.eventNotes?.trim().isNotEmpty == true
                                        ? event.eventNotes!
                                        : 'No event notes recorded.'),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: EmptyState(
            title: 'Could not load appointment details',
            description: error.toString().replaceFirst('Exception: ', ''),
            icon: Icons.event_busy_outlined,
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(
              stylistAppointmentDetailProvider(widget.appointmentId),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddInternalNoteDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add internal note'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add staff-only notes about the visit, safety, or service execution.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (value == null || value.trim().isEmpty || !mounted) {
      return;
    }

    await _runAction(
      () => ref.read(stylistActionControllerProvider.notifier).addInternalNote(
            appointmentId: widget.appointmentId,
            noteBody: value,
          ),
    );
  }

  Future<void> _confirmSafetyEvent() async {
    final shouldTrigger = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trigger SOS placeholder'),
          content: const Text(
            'This creates a placeholder safety event for the assigned appointment so admins can see the alert path end to end.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Trigger'),
            ),
          ],
        );
      },
    );

    if (shouldTrigger != true || !mounted) {
      return;
    }

    await _runAction(
      () => ref.read(stylistActionControllerProvider.notifier).triggerSafetyEvent(
            appointmentId: widget.appointmentId,
          ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment updated.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The action could not be completed.')),
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(value),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.month}/${value.day}/${value.year} at $hour:$minute $suffix';
}

String _titleCase(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}