import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root application widget.
///
/// This file connects the app theme and the router configuration.
/// Later, the Supabase session state can also be observed here to decide when
/// the app should rebuild around auth changes.
class HairSalonApp extends ConsumerWidget {
  const HairSalonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Mobile Hair Salon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}