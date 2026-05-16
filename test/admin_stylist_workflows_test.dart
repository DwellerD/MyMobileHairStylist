import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_hair_salon/core/models/app_user_role.dart';
import 'package:mobile_hair_salon/core/theme/app_theme.dart';
import 'package:mobile_hair_salon/features/admin/data/admin_repository.dart';
import 'package:mobile_hair_salon/features/admin/domain/admin_models.dart';
import 'package:mobile_hair_salon/features/admin/presentation/providers/admin_providers.dart';
import 'package:mobile_hair_salon/features/admin/presentation/screens/admin_stylists_screen.dart';
import 'package:mobile_hair_salon/features/auth/domain/app_user.dart';
import 'package:mobile_hair_salon/features/auth/presentation/providers/auth_providers.dart';

void main() {
  testWidgets('admin can approve a pending stylist application', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repository),
          currentAppUserProvider.overrideWith(
            (ref) async => _adminUser(role: AppUserRole.admin),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AdminStylistsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending applications'), findsOneWidget);
    expect(find.text('Jordan Styles'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(repository.approvedApplicationId, 'application-1');
  });

  test('grant admin access action calls repository', () async {
    final repository = _FakeAdminRepository();
    final container = ProviderContainer(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(adminActionControllerProvider.notifier).grantAdminAccess(
          userProfileId: 'user-2',
          role: 'admin',
          marketId: 'market-1',
          territoryId: 'territory-1',
          makePrimary: true,
        );

    expect(repository.grantRequest, isNotNull);
    expect(repository.grantRequest!.userProfileId, 'user-2');
    expect(repository.grantRequest!.role, 'admin');
    expect(repository.grantRequest!.marketId, 'market-1');
    expect(repository.grantRequest!.territoryId, 'territory-1');
    expect(repository.grantRequest!.makePrimary, isTrue);
  });
}

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository() : super(null);

  String? approvedApplicationId;
  String? rejectedApplicationId;
  _GrantAdminAccessRequest? grantRequest;

  @override
  Future<List<AdminStylistSummary>> loadStylists() async {
    return const [
      AdminStylistSummary(
        id: 'stylist-1',
        name: 'Taylor Artist',
        marketName: 'Phoenix',
        territoryName: 'East Valley',
        status: 'active',
        specialties: ['Bridal', 'Color'],
        isAcceptingBookings: true,
        assignedAppointmentCount: 2,
      ),
    ];
  }

  @override
  Future<List<AdminStylistApplicationSummary>> loadStylistApplications() async {
    return [
      AdminStylistApplicationSummary(
        id: 'application-1',
        applicantName: 'Jordan Styles',
        email: 'jordan@example.com',
        phone: '555-1200',
        city: 'Mesa',
        stateCode: 'AZ',
        status: 'pending',
        marketName: 'Phoenix',
        territoryName: 'East Valley',
        specialties: const ['Balayage', 'Cuts'],
        yearsExperience: 6,
        submittedAt: DateTime(2026, 5, 16),
        reviewerNotes: null,
      ),
    ];
  }

  @override
  Future<List<AdminUserAccessSummary>> loadUserAccessDirectory() async {
    return const [
      AdminUserAccessSummary(
        userProfileId: 'user-1',
        name: 'Pat Admin',
        email: 'pat@example.com',
        roles: [
          AdminUserRoleAssignment(
            id: 'role-1',
            role: 'admin',
            status: 'active',
            isPrimary: true,
            marketName: 'Phoenix',
            territoryName: 'East Valley',
          ),
        ],
      ),
      AdminUserAccessSummary(
        userProfileId: 'user-2',
        name: 'Jamie Ops',
        email: 'jamie@example.com',
        roles: [],
      ),
    ];
  }

  @override
  Future<List<AdminScopeOption>> loadMarketOptions() async {
    return const [
      AdminScopeOption(id: 'market-1', name: 'Phoenix'),
    ];
  }

  @override
  Future<List<AdminScopeOption>> loadTerritoryOptions({String? marketId}) async {
    return const [
      AdminScopeOption(id: 'territory-1', name: 'East Valley'),
    ];
  }

  @override
  Future<void> approveStylistApplication({
    required String applicationId,
    String? territoryId,
    String? reviewerNotes,
  }) async {
    approvedApplicationId = applicationId;
  }

  @override
  Future<void> rejectStylistApplication({
    required String applicationId,
    String? reviewerNotes,
  }) async {
    rejectedApplicationId = applicationId;
  }

  @override
  Future<void> grantAdminAccess({
    required String userProfileId,
    required String role,
    String? marketId,
    String? territoryId,
    required bool makePrimary,
  }) async {
    grantRequest = _GrantAdminAccessRequest(
      userProfileId: userProfileId,
      role: role,
      marketId: marketId,
      territoryId: territoryId,
      makePrimary: makePrimary,
    );
  }
}

class _GrantAdminAccessRequest {
  const _GrantAdminAccessRequest({
    required this.userProfileId,
    required this.role,
    required this.marketId,
    required this.territoryId,
    required this.makePrimary,
  });

  final String userProfileId;
  final String role;
  final String? marketId;
  final String? territoryId;
  final bool makePrimary;
}

AppUser _adminUser({required AppUserRole role}) {
  return AppUser(
    profileId: 'admin-profile',
    authUserId: 'auth-admin',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    defaultMarketId: 'market-1',
    defaultTerritoryId: 'territory-1',
    role: role,
  );
}