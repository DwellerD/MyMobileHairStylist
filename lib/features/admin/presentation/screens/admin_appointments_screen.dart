import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_appointment_tile.dart';

/// Admin booking queue and lifecycle operations screen.
class AdminAppointmentsScreen extends ConsumerStatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  ConsumerState<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends ConsumerState<AdminAppointmentsScreen> {
  String _selectedStatus = 'requested';

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(adminAppointmentsProvider);

    return appointmentsAsync.when(
      data: (appointments) {
        final filteredAppointments = appointments
            .where((appointment) => appointment.status == _selectedStatus)
            .toList(growable: false);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Bookings',
              subtitle: 'Review requests, assign stylists, and move appointments through the operational status lifecycle.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: adminAppointmentStatuses
                    .map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(titleCase(status)),
                          selected: _selectedStatus == status,
                          onSelected: (_) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (filteredAppointments.isEmpty)
              EmptyState(
                title: 'No ${titleCase(_selectedStatus)} appointments',
                description: 'This filter is ready, but no appointments match it right now.',
                icon: Icons.filter_alt_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () => ref.invalidate(adminAppointmentsProvider),
              )
            else
              ...filteredAppointments.map(
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
                    onAssign: () => _showAssignStylistSheet(appointment.id),
                    onEditStatus: () => _showStatusSheet(appointment.id, appointment.status),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: EmptyState(
          title: 'Could not load bookings',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.event_busy_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(adminAppointmentsProvider),
        ),
      ),
    );
  }

  Future<void> _showAssignStylistSheet(String appointmentId) async {
    final options = await ref.read(adminRepositoryProvider).loadStylistOptions();
    if (!mounted) {
      return;
    }

    final stylistId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: options
                .map(
                  (stylist) => ListTile(
                    title: Text(stylist.name),
                    onTap: () => Navigator.of(context).pop(stylist.id),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );

    if (stylistId == null) {
      return;
    }

    await ref.read(adminActionControllerProvider.notifier).assignStylist(
          appointmentId: appointmentId,
          stylistProfileId: stylistId,
        );
  }

  Future<void> _showStatusSheet(String appointmentId, String currentStatus) async {
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

    await ref.read(adminActionControllerProvider.notifier).updateAppointmentStatus(
          appointmentId: appointmentId,
          status: selectedStatus,
        );
  }
}