import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user_role.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/admin/presentation/screens/admin_appointments_screen.dart';
import '../../features/admin/presentation/screens/admin_appointment_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_customers_screen.dart';
import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/admin/presentation/screens/admin_services_screen.dart';
import '../../features/admin/presentation/screens/admin_stylists_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_gate_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/customer/booking/presentation/screens/address_check_screen.dart';
import '../../features/customer/booking/presentation/screens/booking_notes_screen.dart';
import '../../features/customer/booking/presentation/screens/booking_payment_placeholder_screen.dart';
import '../../features/customer/booking/presentation/screens/booking_photo_upload_screen.dart';
import '../../features/customer/booking/presentation/screens/booking_review_screen.dart';
import '../../features/customer/booking/presentation/screens/booking_submitted_screen.dart';
import '../../features/customer/booking/presentation/screens/household_member_selection_screen.dart';
import '../../features/customer/booking/presentation/screens/preferred_time_screen.dart';
import '../../features/customer/booking/presentation/screens/service_selection_screen.dart';
import '../../features/customer/presentation/screens/customer_appointments_screen.dart';
import '../../features/customer/presentation/screens/customer_home_screen.dart';
import '../../features/customer/presentation/screens/customer_profile_screen.dart';
import '../../features/customer/presentation/screens/family_screen.dart';
import '../../features/stylist/presentation/screens/stylist_earnings_screen.dart';
import '../../features/stylist/presentation/screens/stylist_appointment_detail_screen.dart';
import '../../features/stylist/presentation/screens/stylist_application_screen.dart';
import '../../features/stylist/presentation/screens/stylist_home_screen.dart';
import '../../features/stylist/presentation/screens/stylist_portal_screen.dart';
import '../../features/stylist/presentation/screens/stylist_profile_screen.dart';
import '../../features/stylist/presentation/screens/stylist_safety_screen.dart';
import '../../features/stylist/presentation/screens/stylist_schedule_screen.dart';
import '../../shared/widgets/role_shell.dart';

/// Exposes the configured router through Riverpod.
///
/// The router is rebuilt whenever auth session or current app user state changes.
/// This keeps navigation aligned with Supabase login state and database-backed
/// role lookup.
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(currentSessionProvider);
  final appUserAsync = ref.watch(currentAppUserProvider);
  final appUser = appUserAsync.valueOrNull;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;
      final isWelcome = location == '/';
      final isStylistPortal = location == '/stylist/portal';
      final isStylistLogin = location == '/stylist/login';
      final isAdminLogin = location == '/admin/login';
      final isStylistApply = location == '/stylist/apply';
      final isPublicRoute =
          isWelcome ||
          location == '/login' ||
          location == '/signup' ||
          isStylistPortal ||
          isStylistLogin ||
          isAdminLogin ||
          isStylistApply;
      final isRoleGate = location == '/role-gate';

      if (session == null) {
        if (isPublicRoute) {
          return null;
        }

        return '/login';
      }

      if (isStylistApply) {
        return null;
      }

      if (isPublicRoute) {
        return '/role-gate';
      }

      if (appUserAsync.isLoading) {
        return isRoleGate ? null : '/role-gate';
      }

      if (appUser == null || !appUser.hasSupportedRole) {
        return isRoleGate ? null : '/role-gate';
      }

      if (isRoleGate) {
        return appUser.supportedHomeLocation;
      }

      switch (appUser.role!) {
        case AppUserRole.customer:
          if (!location.startsWith('/customer')) {
            return appUser.supportedHomeLocation;
          }
          break;
        case AppUserRole.stylist:
          if (!location.startsWith('/stylist')) {
            return appUser.supportedHomeLocation;
          }
          break;
        case AppUserRole.admin:
          if (!location.startsWith('/admin')) {
            return appUser.supportedHomeLocation;
          }
          break;
        case AppUserRole.corporateAdmin:
          if (!location.startsWith('/admin')) {
            return appUser.supportedHomeLocation;
          }
          break;
        case AppUserRole.franchisee:
          return '/role-gate';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/stylist/portal',
        builder: (context, state) => const StylistPortalScreen(),
      ),
      GoRoute(
        path: '/stylist/login',
        builder: (context, state) => const LoginScreen.stylist(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const LoginScreen.admin(),
      ),
      GoRoute(
        path: '/stylist/apply',
        builder: (context, state) => const StylistApplicationScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/role-gate',
        builder: (context, state) => const RoleGateScreen(),
      ),
      GoRoute(
        path: '/stylist/appointments/:appointmentId',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId']!;
          return StylistAppointmentDetailScreen(appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: '/admin/appointments/:appointmentId',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId']!;
          return AdminAppointmentDetailScreen(appointmentId: appointmentId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RoleShell.customer(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/home',
                builder: (context, state) => const CustomerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/book',
                builder: (context, state) => const AddressCheckScreen(),
                routes: [
                  GoRoute(
                    path: 'household-members',
                    builder: (context, state) =>
                        const HouseholdMemberSelectionScreen(),
                  ),
                  GoRoute(
                    path: 'services',
                    builder: (context, state) => const ServiceSelectionScreen(),
                  ),
                  GoRoute(
                    path: 'notes',
                    builder: (context, state) => const BookingNotesScreen(),
                  ),
                  GoRoute(
                    path: 'photos',
                    builder: (context, state) =>
                        const BookingPhotoUploadScreen(),
                  ),
                  GoRoute(
                    path: 'time',
                    builder: (context, state) => const PreferredTimeScreen(),
                  ),
                  GoRoute(
                    path: 'payment',
                    builder: (context, state) =>
                        const BookingPaymentPlaceholderScreen(),
                  ),
                  GoRoute(
                    path: 'review',
                    builder: (context, state) => const BookingReviewScreen(),
                  ),
                  GoRoute(
                    path: 'submitted',
                    builder: (context, state) => const BookingSubmittedScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/appointments',
                builder: (context, state) => const CustomerAppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/family',
                builder: (context, state) => const FamilyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/profile',
                builder: (context, state) => const CustomerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RoleShell.stylist(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist/home',
                builder: (context, state) => const StylistHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist/schedule',
                builder: (context, state) => const StylistScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist/safety',
                builder: (context, state) => const StylistSafetyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist/earnings',
                builder: (context, state) => const StylistEarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stylist/profile',
                builder: (context, state) => const StylistProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RoleShell.admin(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/home',
                builder: (context, state) => const AdminHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/appointments',
                builder: (context, state) => const AdminAppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/customers',
                builder: (context, state) => const AdminCustomersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/stylists',
                builder: (context, state) => const AdminStylistsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/services',
                builder: (context, state) => const AdminServicesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});