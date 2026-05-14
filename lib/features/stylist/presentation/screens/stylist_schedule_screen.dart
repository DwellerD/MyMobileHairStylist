import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/stylist_providers.dart';

/// Upcoming appointment schedule for the current stylist.
class StylistScheduleScreen extends ConsumerWidget {
  const StylistScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(stylistScheduleAppointmentsProvider);

    return scheduleAsync.when(
      data: (appointments) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Schedule',
              subtitle: 'All assigned appointments, ordered by arrival time for field operations.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (appointments.isEmpty)
              EmptyState(
                title: 'No assigned appointments yet',
                description: 'Once appointments are assigned to this stylist, they will appear here with service and safety context.',
                icon: Icons.schedule_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () => ref.invalidate(stylistScheduleAppointmentsProvider),
              )
            else
              ...appointments.map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: () => context.go('/stylist/appointments/${appointment.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.customerFirstName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text('${_formatScheduleDate(appointment.startsAt)} · ${appointment.cityOrArea}'),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(appointment.serviceSummary),
                        const SizedBox(height: AppSpacing.xxs),
                        Text('Status: ${_titleCase(appointment.status)}'),
                        const SizedBox(height: AppSpacing.xxs),
                        Text('Check-in: ${appointment.checkInStatus}'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: EmptyState(
          title: 'Could not load the schedule',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.event_busy_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(stylistScheduleAppointmentsProvider),
        ),
      ),
    );
  }
}

String _formatScheduleDate(DateTime value) {
  final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.month}/${value.day} at $hour:$minute $suffix';
}

String _titleCase(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}