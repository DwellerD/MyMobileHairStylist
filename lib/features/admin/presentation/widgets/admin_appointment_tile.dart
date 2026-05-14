import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/admin_models.dart';

/// Reusable appointment tile used across the admin dashboard and bookings list.
class AdminAppointmentTile extends StatelessWidget {
  const AdminAppointmentTile({
    required this.appointment,
    required this.onOpen,
    this.onApprove,
    this.onDecline,
    this.onAssign,
    this.onEditStatus,
    super.key,
  });

  final AdminAppointmentSummary appointment;
  final VoidCallback onOpen;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onAssign;
  final VoidCallback? onEditStatus;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.customerName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  titleCase(appointment.status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${formatDateTime(appointment.startsAt)} · ${appointment.cityOrArea}'),
          const SizedBox(height: AppSpacing.xxs),
          Text(appointment.serviceSummary.isEmpty ? 'Services pending review' : appointment.serviceSummary),
          const SizedBox(height: AppSpacing.xxs),
          Text('Check-in: ${appointment.checkInStatus}'),
          const SizedBox(height: AppSpacing.xxs),
          Text('Assigned stylist: ${appointment.assignedStylistName ?? 'Unassigned'}'),
          const SizedBox(height: AppSpacing.xxs),
          Text('Estimate: ${formatMoneyCents(appointment.estimatedTotalCents)}'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              TextButton(onPressed: onOpen, child: const Text('View details')),
              if (onApprove != null)
                TextButton(onPressed: onApprove, child: const Text('Approve')),
              if (onDecline != null)
                TextButton(onPressed: onDecline, child: const Text('Decline')),
              if (onAssign != null)
                TextButton(onPressed: onAssign, child: const Text('Assign stylist')),
              if (onEditStatus != null)
                TextButton(onPressed: onEditStatus, child: const Text('Edit status')),
            ],
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return AppColors.success;
    case 'declined':
    case 'cancelled':
      return AppColors.danger;
    case 'requested':
    case 'approved':
      return AppColors.warning;
    default:
      return AppColors.info;
  }
}

String titleCase(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String formatDateTime(DateTime value) {
  final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.month}/${value.day}/${value.year} at $hour:$minute $suffix';
}