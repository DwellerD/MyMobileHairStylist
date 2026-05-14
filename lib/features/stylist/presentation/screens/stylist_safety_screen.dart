import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/stylist_providers.dart';

/// Stylist safety dashboard for quick access to recent alerts and operational context.
class StylistSafetyScreen extends ConsumerWidget {
  const StylistSafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safetyAsync = ref.watch(stylistSafetyEventsProvider);
    final todayAsync = ref.watch(stylistTodayAppointmentsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const AppScreenHeader(
          title: 'Safety',
          subtitle: 'Recent SOS placeholders, current-day visits, and the safety operating picture for the stylist.',
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Field safety posture', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              todayAsync.when(
                data: (appointments) => Text(
                  appointments.isEmpty
                      ? 'No visits are assigned today.'
                      : '${appointments.length} assigned visit${appointments.length == 1 ? '' : 's'} today. Open any appointment detail to check in, check out, or trigger the SOS placeholder.',
                ),
                loading: () => const Text('Loading today\'s safety context...'),
                error: (error, _) => Text(
                  error.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        safetyAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return EmptyState(
                title: 'No safety events',
                description: 'SOS placeholders and future safety workflow events will appear here after a stylist records them.',
                icon: Icons.verified_user_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () => ref.invalidate(stylistSafetyEventsProvider),
              );
            }

            return Column(
              children: events
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        onTap: event.appointmentId == null
                            ? null
                            : () => context.go('/stylist/appointments/${event.appointmentId}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${event.customerFirstName} · ${_titleCase(event.eventType)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text('Status: ${_titleCase(event.status)}'),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(event.details),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(_formatSafetyDate(event.createdAt)),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            title: 'Could not load safety events',
            description: error.toString().replaceFirst('Exception: ', ''),
            icon: Icons.warning_amber_outlined,
            actionLabel: 'Retry',
            onActionPressed: () => ref.invalidate(stylistSafetyEventsProvider),
          ),
        ),
      ],
    );
  }
}

String _formatSafetyDate(DateTime value) {
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