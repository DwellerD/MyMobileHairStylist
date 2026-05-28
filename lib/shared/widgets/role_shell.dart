import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

/// Shared scaffold for each role's bottom navigation experience.
///
/// go_router creates a separate navigation shell for customer, stylist, and
/// admin tabs. This widget only handles layout, tab labels, and development role
/// switching while the actual route content is rendered as [navigationShell].
class RoleShell extends ConsumerWidget {
  const RoleShell._({
    required this.role,
    required this.navigationShell,
  });

  factory RoleShell.customer({required StatefulNavigationShell navigationShell}) {
    return RoleShell._(
      role: AppUserRole.customer,
      navigationShell: navigationShell,
    );
  }

  factory RoleShell.stylist({required StatefulNavigationShell navigationShell}) {
    return RoleShell._(
      role: AppUserRole.stylist,
      navigationShell: navigationShell,
    );
  }

  factory RoleShell.admin({required StatefulNavigationShell navigationShell}) {
    return RoleShell._(
      role: AppUserRole.admin,
      navigationShell: navigationShell,
    );
  }

  final AppUserRole role;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _configForRole(role);
    final authActionState = ref.watch(authActionControllerProvider);
    final showTopBar = role == AppUserRole.admin;

    return Scaffold(
      appBar: showTopBar
          ? AppBar(
              title: Text(config.title),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextButton(
                    onPressed: authActionState.isLoading
                        ? null
                        : () async {
                            await ref.read(authActionControllerProvider.notifier).signOut();

                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                    child: const Text('Log out'),
                  ),
                ),
              ],
            )
          : null,
      body: showTopBar
          ? navigationShell
          : SafeArea(
              top: true,
              bottom: false,
              child: navigationShell,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: [
          for (final item in config.items)
            BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
        ],
      ),
      floatingActionButton: () {
        if (role != AppUserRole.customer) return null;
        final currentPath = GoRouterState.of(context).uri.path;
        if (currentPath.startsWith('/customer/book')) return null;
        return FloatingActionButton.extended(
          onPressed: () => context.go('/customer/book'),
          label: const Text('Book now'),
          icon: const Icon(Icons.calendar_month_outlined),
        );
      }(),
    );
  }
}

class _RoleShellConfig {
  const _RoleShellConfig({required this.title, required this.items});

  final String title;
  final List<_RoleNavItem> items;
}

class _RoleNavItem {
  const _RoleNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

_RoleShellConfig _configForRole(AppUserRole role) {
  switch (role) {
    case AppUserRole.customer:
      return const _RoleShellConfig(
        title: 'Customer',
        items: [
          _RoleNavItem(label: 'Home', icon: Icons.home_outlined),
          _RoleNavItem(label: 'Book', icon: Icons.calendar_month_outlined),
          _RoleNavItem(label: 'Appointments', icon: Icons.event_note_outlined),
          _RoleNavItem(label: 'Family', icon: Icons.people_outline),
          _RoleNavItem(label: 'Profile', icon: Icons.person_outline),
        ],
      );
    case AppUserRole.stylist:
      return const _RoleShellConfig(
        title: 'Stylist',
        items: [
          _RoleNavItem(label: 'Today', icon: Icons.today_outlined),
          _RoleNavItem(label: 'Schedule', icon: Icons.schedule_outlined),
          _RoleNavItem(label: 'Safety', icon: Icons.shield_outlined),
          _RoleNavItem(label: 'Earnings', icon: Icons.payments_outlined),
          _RoleNavItem(label: 'Profile', icon: Icons.person_outline),
        ],
      );
    case AppUserRole.admin:
      return const _RoleShellConfig(
        title: 'Admin',
        items: [
          _RoleNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
          _RoleNavItem(label: 'Bookings', icon: Icons.calendar_view_day_outlined),
          _RoleNavItem(label: 'Customers', icon: Icons.groups_outlined),
          _RoleNavItem(label: 'Stylists', icon: Icons.content_cut_outlined),
          _RoleNavItem(label: 'Services', icon: Icons.design_services_outlined),
        ],
      );
    case AppUserRole.franchisee:
    case AppUserRole.corporateAdmin:
      return const _RoleShellConfig(
        title: 'Admin',
        items: [
          _RoleNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
          _RoleNavItem(label: 'Bookings', icon: Icons.calendar_view_day_outlined),
          _RoleNavItem(label: 'Customers', icon: Icons.groups_outlined),
          _RoleNavItem(label: 'Stylists', icon: Icons.content_cut_outlined),
          _RoleNavItem(label: 'Services', icon: Icons.design_services_outlined),
        ],
      );
  }
}