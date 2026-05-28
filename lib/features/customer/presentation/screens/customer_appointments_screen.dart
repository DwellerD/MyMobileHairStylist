import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/appointment_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/customer_appointment_summary.dart';
import '../providers/customer_appointments_providers.dart';

/// Customer appointment history and upcoming bookings.
class CustomerAppointmentsScreen extends ConsumerWidget {
  const CustomerAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(customerAppointmentsProvider);

    return appointmentsAsync.when(
      data: (appointments) {
        final now = DateTime.now();
        final upcoming = appointments
            .where((appointment) => !appointment.startsAt.isBefore(now))
            .toList(growable: false);
        final history = appointments
            .where((appointment) => appointment.startsAt.isBefore(now))
            .toList(growable: false)
          ..sort((left, right) => right.startsAt.compareTo(left.startsAt));

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Appointments',
              subtitle: 'Keep upcoming visits and recent household bookings in one clear timeline.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (appointments.isEmpty)
              EmptyState(
                title: 'No bookings yet',
                description: 'Submitted requests and confirmed visits will appear here once you create your first household booking.',
                icon: Icons.calendar_month_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () => ref.invalidate(customerAppointmentsProvider),
              )
            else ...[
              const AppSectionHeader(title: 'Upcoming'),
              const SizedBox(height: AppSpacing.md),
              if (upcoming.isEmpty)
                const EmptyState(
                  title: 'No upcoming visits',
                  description: 'New booking requests will appear here after they are submitted.',
                  icon: Icons.event_available_outlined,
                )
              else
                ...upcoming.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CustomerAppointmentCard(appointment: appointment),
                  ),
                ),
              const SizedBox(height: AppSpacing.sectionGap),
              const AppSectionHeader(title: 'Recent'),
              const SizedBox(height: AppSpacing.md),
              if (history.isEmpty)
                const EmptyState(
                  title: 'No recent visits',
                  description: 'Completed and past household bookings will appear here after your first appointment date passes.',
                  icon: Icons.history_outlined,
                )
              else
                ...history.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CustomerAppointmentCard(appointment: appointment),
                  ),
                ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: EmptyState(
          title: 'Could not load your appointments',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.event_busy_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(customerAppointmentsProvider),
        ),
      ),
    );
  }
}

class _CustomerAppointmentCard extends StatelessWidget {
  const _CustomerAppointmentCard({required this.appointment});

  final CustomerAppointmentSummary appointment;

  @override
  Widget build(BuildContext context) {
    return AppointmentCard(
      title: appointment.serviceSummary,
      subtitle: 'For ${appointment.participantSummary}',
      timeLabel: _formatDateTime(appointment.startsAt),
      statusLabel: _titleCase(appointment.status),
      statusColor: _statusColor(appointment.status),
      address: appointment.addressSummary,
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return AppColors.success;
    case 'pending_stylist_confirmation':
      return AppColors.warning;
    case 'pending_assignment':
      return AppColors.warning;
    case 'approved':
    case 'confirmed':
      return AppColors.info;
    case 'declined_by_stylist':
      return AppColors.warning;
    case 'declined':
    case 'cancelled':
      return AppColors.danger;
    case 'requested':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

String _formatDateTime(DateTime value) {
  const weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';

  return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} ${value.day} at $hour:$minute $suffix';
}

String _titleCase(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}