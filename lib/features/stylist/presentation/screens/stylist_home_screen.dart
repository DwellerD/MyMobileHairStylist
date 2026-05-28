import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/stylist_models.dart';
import '../providers/stylist_providers.dart';

/// Stylist dashboard showing today's assigned appointments.
class StylistHomeScreen extends ConsumerWidget {
  const StylistHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(stylistTodayAppointmentsProvider);
    final claimableAsync = ref.watch(stylistClaimableAppointmentsProvider);

    return todayAsync.when(
      data: (appointments) {
        return claimableAsync.when(
          data: (claimableAppointments) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Today',
              subtitle: 'Assigned appointments, live visit status, and safety-first operational context.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appointments.length} visit${appointments.length == 1 ? '' : 's'} scheduled',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          appointments.isEmpty
                              ? 'No assigned appointments for today.'
                              : 'First arrival starts at ${_formatTime(appointments.first.startsAt)}.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.directions_car_outlined),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${claimableAppointments.length} local request${claimableAppointments.length == 1 ? '' : 's'} available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          claimableAppointments.isEmpty
                              ? 'No unassigned local requests match your territory right now.'
                              : 'Claim a local request below to move it into your working schedule.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications_active_outlined),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (claimableAppointments.isNotEmpty) ...[
              Text(
                'Local requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...claimableAppointments.map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ClaimableAppointmentCard(appointment: appointment),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            if (appointments.isEmpty)
              EmptyState(
                title: 'Nothing assigned for today',
                description: 'Assigned visits will appear here once admin confirms the appointment and stylist assignment.',
                icon: Icons.event_available_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () {
                  ref.invalidate(stylistTodayAppointmentsProvider);
                  ref.invalidate(stylistClaimableAppointmentsProvider);
                },
              )
            else
              ...appointments.map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _StylistAppointmentCard(appointment: appointment),
                ),
              ),
          ],
        );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: EmptyState(
              title: 'Could not load local requests',
              description: error.toString().replaceFirst('Exception: ', ''),
              icon: Icons.notifications_off_outlined,
              actionLabel: 'Retry',
              onActionPressed: () => ref.invalidate(stylistClaimableAppointmentsProvider),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: EmptyState(
          title: 'Could not load today\'s appointments',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.event_busy_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(stylistTodayAppointmentsProvider),
        ),
      ),
    );
  }
}

class _ClaimableAppointmentCard extends ConsumerWidget {
  const _ClaimableAppointmentCard({required this.appointment});

  final ClaimableAppointmentSummary appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(stylistActionControllerProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.customerFirstName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (appointment.requestedStylist)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Requested you',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${_formatTime(appointment.startsAt)} · ${appointment.cityOrArea}'),
          const SizedBox(height: AppSpacing.xxs),
          Text(appointment.serviceSummary),
          const SizedBox(height: AppSpacing.xxs),
          Text('${appointment.estimatedDurationMinutes} min · ${appointment.addressSummary}'),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: actionState.isLoading
                ? null
                : () async {
                    try {
                      await ref
                          .read(stylistActionControllerProvider.notifier)
                          .claimAppointmentRequest(appointmentId: appointment.id);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment claimed.')),
                      );
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This request could not be claimed.'),
                        ),
                      );
                    }
                  },
            child: const Text('Claim request'),
          ),
        ],
      ),
    );
  }
}

class _StylistAppointmentCard extends StatelessWidget {
  const _StylistAppointmentCard({required this.appointment});

  final StylistAppointmentSummary appointment;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/stylist/appointments/${appointment.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.customerFirstName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(appointment.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _titleCase(appointment.status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _statusColor(appointment.status),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${_formatTime(appointment.startsAt)} · ${appointment.cityOrArea}'),
          const SizedBox(height: AppSpacing.xxs),
          Text(appointment.serviceSummary),
          const SizedBox(height: AppSpacing.xxs),
          Text('Check-in status: ${appointment.checkInStatus}'),
          const SizedBox(height: AppSpacing.xxs),
          Text('${appointment.estimatedDurationMinutes} min · ${appointment.addressSummary}'),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return AppColors.success;
    case 'confirmed':
      return AppColors.info;
    case 'pending_stylist_confirmation':
      return AppColors.warning;
    case 'in_progress':
      return AppColors.info;
    case 'requested':
    case 'approved':
    case 'pending_assignment':
      return AppColors.warning;
    case 'declined_by_stylist':
      return AppColors.danger;
    default:
      return AppColors.primary;
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _titleCase(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}