import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_appointment_tile.dart';

/// Detailed admin review screen for one appointment.
class AdminAppointmentDetailScreen extends ConsumerStatefulWidget {
  const AdminAppointmentDetailScreen({
    required this.appointmentId,
    super.key,
  });

  final String appointmentId;

  @override
  ConsumerState<AdminAppointmentDetailScreen> createState() =>
      _AdminAppointmentDetailScreenState();
}

class _AdminAppointmentDetailScreenState
    extends ConsumerState<AdminAppointmentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminAppointmentDetailProvider(widget.appointmentId));
    final actionState = ref.watch(adminActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking review')),
      body: detailAsync.when(
        data: (detail) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              AppScreenHeader(
                title: detail.customerName,
                subtitle:
                    'Operational booking review for mobile today, with a clear path toward a future desktop dashboard layout.',
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  FilledButton(
                    onPressed: actionState.isLoading
                        ? null
                        : () => _runAction(
                              () => ref
                                  .read(adminActionControllerProvider.notifier)
                                  .approveAppointment(widget.appointmentId),
                            ),
                    child: const Text('Approve'),
                  ),
                  FilledButton.tonal(
                    onPressed: actionState.isLoading
                        ? null
                        : () => _runAction(
                              () => ref
                                  .read(adminActionControllerProvider.notifier)
                                  .declineAppointment(widget.appointmentId),
                            ),
                    child: const Text('Decline'),
                  ),
                  AppSecondaryButton(
                    label: 'Assign stylist',
                    onPressed: actionState.isLoading ? null : () => _showAssignStylistSheet(detail),
                  ),
                  AppSecondaryButton(
                    label: 'Edit status',
                    onPressed: actionState.isLoading ? null : () => _showStatusSheet(detail.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _DetailCard(
                title: 'Booking overview',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Status', value: titleCase(detail.status)),
                    _DetailRow(label: 'Address', value: detail.address),
                    _DetailRow(label: 'Preferred date', value: detail.preferredDate ?? 'No preferred date provided'),
                    _DetailRow(label: 'Preferred window', value: detail.preferredTimeWindow ?? 'No preferred time window provided'),
                    _DetailRow(label: 'Estimated total', value: formatMoneyCents(detail.estimatedTotalCents)),
                    _DetailRow(label: 'Assigned stylist', value: detail.assignedStylistName ?? 'Unassigned'),
                    _DetailRow(
                      label: 'Stylist preference',
                      value: detail.stylistPreferenceType == 'specific'
                          ? 'Specific stylist requested'
                          : 'Any Available Stylist',
                    ),
                    if (detail.requestedStylistName != null)
                      _DetailRow(label: 'Requested stylist', value: detail.requestedStylistName!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailCard(
                title: 'Household members',
                child: detail.participants.isEmpty
                    ? const Text('No participants attached to this appointment.')
                    : Column(
                        children: detail.participants
                            .map(
                              (participant) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(participant.name, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text('General notes: ${participant.generalNotes ?? 'None'}'),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text('Sensory notes: ${participant.sensoryNotes ?? 'None'}'),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text('Hair notes: ${participant.hairNotes ?? 'None'}'),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailCard(
                title: 'Services',
                child: detail.services.isEmpty
                    ? const Text('No services attached yet.')
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
                                      style: Theme.of(context).textTheme.titleMedium,
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
              _DetailCard(
                title: 'Notes',
                child: Text(detail.notes ?? 'No customer or access notes provided.'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailCard(
                title: 'Photos',
                child: detail.photos.isEmpty
                    ? const Text('No photos uploaded.')
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
                                          Text(photo.caption ?? photo.fileName),
                                          const SizedBox(height: AppSpacing.xxs),
                                          Text('${titleCase(photo.photoType)} · ${formatDateTime(photo.createdAt)}'),
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
              _DetailCard(
                title: 'Check-in history',
                child: detail.checkInEvents.isEmpty
                    ? const Text('No check-in events recorded.')
                    : Column(
                        children: detail.checkInEvents
                            .map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${titleCase(event.eventType)} · ${formatDateTime(event.recordedAt)}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(event.eventNotes ?? 'No event notes recorded.'),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailCard(
                title: 'Internal notes',
                child: detail.internalNotes.isEmpty
                    ? const Text('No internal notes recorded.')
                    : Column(
                        children: detail.internalNotes
                            .map(
                              (note) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${note.authorName} · ${titleCase(note.noteType)} · ${formatDateTime(note.createdAt)}',
                                      style: Theme.of(context).textTheme.titleMedium,
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
              _DetailCard(
                title: 'Safety events',
                child: detail.safetyEvents.isEmpty
                    ? const Text('No safety events recorded.')
                    : Column(
                        children: detail.safetyEvents
                            .map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${titleCase(event.eventType)} · ${titleCase(event.status)}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(event.details),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(formatDateTime(event.createdAt)),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailCard(
                title: 'Dispatch history',
                child: detail.dispatchEvents.isEmpty
                    ? const Text('No dispatch events recorded yet.')
                    : Column(
                        children: detail.dispatchEvents
                            .map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${titleCase(event.eventType)} · ${formatDateTime(event.createdAt)}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text('Actor: ${event.actorName ?? 'System'}'),
                                    if (event.previousStatus != null || event.nextStatus != null)
                                      Text(
                                        'Status: ${event.previousStatus ?? 'None'} -> ${event.nextStatus ?? 'None'}',
                                      ),
                                    if (event.previousStylistName != null || event.nextStylistName != null)
                                      Text(
                                        'Stylist: ${event.previousStylistName ?? 'Unassigned'} -> ${event.nextStylistName ?? 'Unassigned'}',
                                      ),
                                    if (event.notes?.trim().isNotEmpty == true)
                                      Text(event.notes!),
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
            title: 'Could not load booking details',
            description: error.toString().replaceFirst('Exception: ', ''),
            icon: Icons.event_busy_outlined,
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(
              adminAppointmentDetailProvider(widget.appointmentId),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAssignStylistSheet(AdminAppointmentDetail detail) async {
    if (detail.availableStylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No stylists are available for this appointment time.'),
        ),
      );
      return;
    }

    final stylistId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final requestedIsStillAvailable = detail.requestedStylistId != null &&
            detail.availableStylists.any(
              (stylist) => stylist.id == detail.requestedStylistId,
            );

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              if (detail.requestedStylistName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    requestedIsStillAvailable
                        ? 'Customer requested: ${detail.requestedStylistName}'
                        : 'Requested stylist is no longer available. Please assign another available stylist.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ...detail.availableStylists.map(
                (stylist) => ListTile(
                  title: Text(stylist.name),
                  subtitle: stylist.isRequested
                      ? const Text('Customer requested this stylist')
                      : null,
                  trailing: stylist.isRequested
                      ? const Icon(Icons.star_border_rounded)
                      : null,
                  onTap: () => Navigator.of(context).pop(stylist.id),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (stylistId == null) {
      return;
    }

    await _runAction(
      () => ref.read(adminActionControllerProvider.notifier).assignStylist(
            appointmentId: widget.appointmentId,
            stylistProfileId: stylistId,
          ),
    );
  }

  Future<void> _showStatusSheet(String currentStatus) async {
    final selectedStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: adminAppointmentStatuses
                .map(
                  (status) => ListTile(
                    title: Text(titleCase(status)),
                    trailing: status == currentStatus ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.of(context).pop(status),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );

    if (selectedStatus == null) {
      return;
    }

    await _runAction(
      () => ref.read(adminActionControllerProvider.notifier).updateAppointmentStatus(
            appointmentId: widget.appointmentId,
            status: selectedStatus,
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
        const SnackBar(content: Text('The admin action could not be completed.')),
      );
    }
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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