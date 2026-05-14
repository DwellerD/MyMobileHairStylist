import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'app_card.dart';
import 'app_screen_header.dart';

/// Reusable wrapper for simple full-screen pages outside the bottom-nav shells.
///
/// This keeps the auth screens visually consistent and avoids repeating the same
/// mobile-first padding and spacing everywhere.
class AppScaffoldShell extends StatelessWidget {
  const AppScaffoldShell({
    required this.title,
    required this.subtitle,
    required this.body,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppScreenHeader(title: title, subtitle: subtitle),
              const SizedBox(height: AppSpacing.sectionGap),
              AppCard(child: body),
            ],
          ),
        ),
      ),
    );
  }
}