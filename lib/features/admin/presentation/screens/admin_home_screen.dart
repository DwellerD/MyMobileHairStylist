import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_appointment_tile.dart';
import '../widgets/admin_metric_card.dart';
import '../widgets/admin_quick_link_card.dart';

/// Admin dashboard with booking queue, safety signals, and quick links.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardSummaryProvider);

    return dashboardAsync.when(
      data: (summary) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Dashboard',
              subtitle:
                  'Mobile-first operations now, with tiles and sections that can later expand into a desktop admin workspace.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                AdminMetricCard(
                  title: 'Pending requests',
                  value: summary.pendingBookingRequests.toString(),
                  icon: Icons.pending_actions_outlined,
                  helperText: 'Bookings waiting for approval or assignment',
                  iconColor: AppColors.warning,
                ),
                AdminMetricCard(
                  title: 'Today\'s appointments',
                  value: summary.todayAppointments.length.toString(),
                  icon: Icons.today_outlined,
                  helperText: 'Assigned, confirmed, and in-progress visits today',
                ),
                AdminMetricCard(
                  title: 'Check-in alerts',
                  value: summary.checkInAlerts.length.toString(),
                  icon: Icons.notification_important_outlined,
                  helperText: 'Past-due visits without a recorded check-in',
                  iconColor: AppColors.danger,
                ),
                AdminMetricCard(
                  title: 'Revenue placeholder',
                  value: formatMoneyCents(summary.revenuePlaceholderCents),
                  icon: Icons.payments_outlined,
                  helperText: 'Completed appointment estimate total for MVP visibility',
                  iconColor: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(
              title: 'Quick links',
              subtitle: 'Fast entry points for the admin jobs that matter most on mobile.',
            ),
            const SizedBox(height: AppSpacing.md),
            AdminQuickLinkCard(
              title: 'Review booking queue',
              subtitle: 'Open requested appointments and assign stylists.',
              icon: Icons.calendar_view_day_outlined,
              onTap: () => context.go('/admin/appointments'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AdminQuickLinkCard(
              title: 'Check customer directory',
              subtitle: 'See households and appointment history placeholders.',
              icon: Icons.groups_outlined,
              onTap: () => context.go('/admin/customers'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AdminQuickLinkCard(
              title: 'Manage service catalog',
              subtitle: 'Create, edit, and enable or disable services.',
              icon: Icons.design_services_outlined,
              onTap: () => context.go('/admin/services'),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(title: 'Today\'s appointments'),
            const SizedBox(height: AppSpacing.md),
            if (summary.todayAppointments.isEmpty)
              const EmptyState(
                title: 'No appointments today',
                description: 'Confirmed and assigned appointments for today will appear here for quick operational review.',
                icon: Icons.event_available_outlined,
              )
            else
              ...summary.todayAppointments
                  .take(3)
                  .map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AdminAppointmentTile(
                        appointment: appointment,
                        onOpen: () => context.go('/admin/appointments/${appointment.id}'),
                        onApprove: appointment.status == 'requested'
                            ? () => ref
                                .read(adminActionControllerProvider.notifier)
                                .approveAppointment(appointment.id)
                            : null,
                        onDecline: appointment.status == 'requested'
                            ? () => ref
                                .read(adminActionControllerProvider.notifier)
                                .declineAppointment(appointment.id)
                            : null,
                      ),
                    ),
                  ),
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(title: 'Check-in / check-out alerts'),
            const SizedBox(height: AppSpacing.md),
            if (summary.checkInAlerts.isEmpty)
              const AppCard(
                child: Text('No active check-in alerts.'),
              )
            else
              ...summary.checkInAlerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: () => context.go('/admin/appointments/${alert.appointmentId}'),
                    backgroundColor: AppColors.surfaceAlt,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(alert.description),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(title: 'Recent safety events'),
            const SizedBox(height: AppSpacing.md),
            if (summary.recentSafetyEvents.isEmpty)
              const AppCard(
                child: Text('No recent safety events.'),
              )
            else
              ...summary.recentSafetyEvents.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: event.appointmentId == null
                        ? null
                        : () => context.go('/admin/appointments/${event.appointmentId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.customerName} · ${titleCase(event.eventType)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text('Status: ${titleCase(event.status)}'),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(event.details),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(formatDateTime(event.createdAt)),
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
          title: 'Could not load the dashboard',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.dashboard_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(adminDashboardSummaryProvider),
        ),
      ),
    );
  }
}