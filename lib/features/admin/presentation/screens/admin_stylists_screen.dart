import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user_role.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/profile_avatar_placeholder.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/admin_models.dart';
import '../providers/admin_providers.dart';

/// Admin stylist directory screen.
class AdminStylistsScreen extends ConsumerWidget {
  const AdminStylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stylistsAsync = ref.watch(adminStylistsProvider);
    final applicationsAsync = ref.watch(adminStylistApplicationsProvider);
    final appUser = ref.watch(currentAppUserProvider).valueOrNull;
    final isCorporateAdmin = appUser?.role == AppUserRole.corporateAdmin;

    return stylistsAsync.when(
      data: (stylists) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppScreenHeader(
              title: 'Stylists',
              subtitle: 'Review stylist applications, activate approved stylists, and manage operational access.',
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const _SectionTitle(
              title: 'Pending applications',
              subtitle: 'Approve or reject new stylist applicants before their operational access is activated.',
            ),
            const SizedBox(height: AppSpacing.md),
            applicationsAsync.when(
              data: (applications) {
                if (applications.isEmpty) {
                  return const AppCard(
                    child: Text('No stylist applications are waiting for review.'),
                  );
                }

                return Column(
                  children: applications
                      .map(
                        (application) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ApplicationTile(application: application),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppCard(child: Text(error.toString())),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const _SectionTitle(
              title: 'Active stylists',
              subtitle: 'Current stylist roster with scope and appointment assignment visibility.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (stylists.isEmpty)
              EmptyState(
                title: 'No stylists found',
                description: 'Stylist profiles will appear here after admin provisioning.',
                icon: Icons.content_cut_outlined,
                actionLabel: 'Refresh',
                onActionPressed: () => ref.invalidate(adminStylistsProvider),
              )
            else
              ...stylists.map(
                (stylist) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _StylistTile(
                    name: stylist.name,
                    detail:
                        '${stylist.status} · ${stylist.marketName ?? 'No market'}${stylist.territoryName != null ? ' · ${stylist.territoryName}' : ''} · ${stylist.assignedAppointmentCount} assigned appointment(s)',
                    specialties: stylist.specialties,
                    isAcceptingBookings: stylist.isAcceptingBookings,
                  ),
                ),
              ),
            if (isCorporateAdmin) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              const _SectionTitle(
                title: 'Admin access',
                subtitle: 'Grant scoped admin access or promote trusted operators to super admin access.',
              ),
              const SizedBox(height: AppSpacing.md),
              const _AdminAccessManager(),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: EmptyState(
          title: 'Could not load stylists',
          description: error.toString().replaceFirst('Exception: ', ''),
          icon: Icons.person_off_outlined,
          actionLabel: 'Retry',
          onActionPressed: () => ref.invalidate(adminStylistsProvider),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ApplicationTile extends ConsumerWidget {
  const _ApplicationTile({required this.application});

  final AdminStylistApplicationSummary application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(adminActionControllerProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(application.applicantName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(application.email),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${application.status} · ${application.marketName ?? 'No market'}${application.territoryName != null ? ' · ${application.territoryName}' : ''}',
          ),
          if (application.phone?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('Phone: ${application.phone}'),
          ],
          if (application.city?.trim().isNotEmpty == true ||
              application.stateCode?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Location: ${[
                if (application.city?.trim().isNotEmpty == true) application.city,
                if (application.stateCode?.trim().isNotEmpty == true) application.stateCode,
              ].join(', ')}',
            ),
          ],
          if (application.specialties.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('Specialties: ${application.specialties.join(' · ')}'),
          ],
          if (application.yearsExperience != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('Experience: ${application.yearsExperience} year(s)'),
          ],
          if (application.reviewerNotes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('Reviewer notes: ${application.reviewerNotes}'),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: actionState.isLoading || application.status != 'pending'
                      ? null
                      : () => ref
                          .read(adminActionControllerProvider.notifier)
                          .approveStylistApplication(applicationId: application.id),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: actionState.isLoading || application.status != 'pending'
                      ? null
                      : () => ref
                          .read(adminActionControllerProvider.notifier)
                          .rejectStylistApplication(applicationId: application.id),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAccessManager extends ConsumerStatefulWidget {
  const _AdminAccessManager();

  @override
  ConsumerState<_AdminAccessManager> createState() => _AdminAccessManagerState();
}

class _AdminAccessManagerState extends ConsumerState<_AdminAccessManager> {
  String? _selectedUserProfileId;
  String _selectedRole = 'admin';
  String? _selectedMarketId;
  String? _selectedTerritoryId;
  bool _makePrimary = true;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUserAccessDirectoryProvider);
    final marketsAsync = ref.watch(adminMarketOptionsProvider);
    final territoriesAsync = ref.watch(adminTerritoryOptionsProvider(_selectedMarketId));
    final actionState = ref.watch(adminActionControllerProvider);

    return usersAsync.when(
      data: (users) {
        final currentAdmins = users
            .where(
              (user) => user.roles.any(
                (role) => role.role == 'admin' || role.role == 'corporate_admin',
              ),
            )
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentAdmins.isEmpty)
              const AppCard(child: Text('No admin users have been activated yet.'))
            else
              ...currentAdmins.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(user.email),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          user.roles
                              .where(
                                (role) => role.role == 'admin' || role.role == 'corporate_admin',
                              )
                              .map(
                                (role) =>
                                    '${role.role}${role.marketName != null ? ' · ${role.marketName}' : ''}${role.territoryName != null ? ' · ${role.territoryName}' : ''}${role.isPrimary ? ' · primary' : ''}',
                              )
                              .join(' | '),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Grant admin access',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _selectedUserProfileId,
                    items: users
                        .map(
                          (user) => DropdownMenuItem<String>(
                            value: user.userProfileId,
                            child: Text('${user.name} · ${user.email}'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserProfileId = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'User'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'admin',
                        child: Text('Area admin'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'corporate_admin',
                        child: Text('Super admin'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedRole = value;
                        if (_selectedRole == 'corporate_admin') {
                          _selectedMarketId = null;
                          _selectedTerritoryId = null;
                        }
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Access level'),
                  ),
                  if (_selectedRole == 'admin') ...[
                    const SizedBox(height: AppSpacing.sm),
                    marketsAsync.when(
                      data: (markets) => DropdownButtonFormField<String>(
                        value: _selectedMarketId,
                        items: markets
                            .map(
                              (market) => DropdownMenuItem<String>(
                                value: market.id,
                                child: Text(market.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() {
                            _selectedMarketId = value;
                            _selectedTerritoryId = null;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Market'),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text(error.toString()),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    territoriesAsync.when(
                      data: (territories) => DropdownButtonFormField<String>(
                        value: _selectedTerritoryId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All territories in market'),
                          ),
                          ...territories.map(
                            (territory) => DropdownMenuItem<String>(
                              value: territory.id,
                              child: Text(territory.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTerritoryId = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Territory'),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text(error.toString()),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    value: _makePrimary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _makePrimary = value ?? true;
                      });
                    },
                    title: const Text('Make this the user\'s primary app access'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: actionState.isLoading || !_canSubmit
                        ? null
                        : () => ref
                            .read(adminActionControllerProvider.notifier)
                            .grantAdminAccess(
                              userProfileId: _selectedUserProfileId!,
                              role: _selectedRole,
                              marketId: _selectedRole == 'admin' ? _selectedMarketId : null,
                              territoryId:
                                  _selectedRole == 'admin' ? _selectedTerritoryId : null,
                              makePrimary: _makePrimary,
                            ),
                    child: const Text('Grant access'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppCard(child: Text(error.toString())),
    );
  }

  bool get _canSubmit {
    if (_selectedUserProfileId == null) {
      return false;
    }
    if (_selectedRole == 'admin' && _selectedMarketId == null) {
      return false;
    }

    return true;
  }
}

class _StylistTile extends StatelessWidget {
  const _StylistTile({
    required this.name,
    required this.detail,
    required this.specialties,
    required this.isAcceptingBookings,
  });

  final String name;
  final String detail;
  final List<String> specialties;
  final bool isAcceptingBookings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ProfileAvatarPlaceholder(name: name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  specialties.isEmpty ? 'No specialties listed' : specialties.join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isAcceptingBookings ? 'Accepting bookings' : 'Not accepting bookings',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}