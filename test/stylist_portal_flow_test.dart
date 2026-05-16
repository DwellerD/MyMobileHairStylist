import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_hair_salon/core/theme/app_theme.dart';
import 'package:mobile_hair_salon/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile_hair_salon/features/stylist/presentation/screens/stylist_application_screen.dart';
import 'package:mobile_hair_salon/features/stylist/presentation/screens/stylist_portal_screen.dart';

void main() {
  testWidgets('stylist portal routes to the application screen', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/stylist/portal',
      routes: [
        GoRoute(
          path: '/stylist/portal',
          builder: (context, state) => const StylistPortalScreen(),
        ),
        GoRoute(
          path: '/stylist/apply',
          builder: (context, state) => const Scaffold(body: Text('apply screen')),
        ),
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const Scaffold(body: Text('admin login')),
        ),
        GoRoute(
          path: '/stylist/login',
          builder: (context, state) => const Scaffold(body: Text('stylist login')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply as a stylist'));
    await tester.pumpAndSettle();

    expect(find.text('apply screen'), findsOneWidget);
  });

  testWidgets('stylist application shows account fields when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionProvider.overrideWith((ref) => null),
          currentAppUserProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StylistApplicationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account details'), findsOneWidget);
    expect(find.text('Create account and apply'), findsOneWidget);
    expect(find.text('Already approved? Log in as stylist'), findsOneWidget);
  });
}