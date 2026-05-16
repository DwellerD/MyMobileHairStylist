import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_scaffold_shell.dart';

class StylistPortalScreen extends StatelessWidget {
  const StylistPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffoldShell(
      title: 'Stylist portal',
      subtitle:
          'Approved stylists can log in here. New stylists can apply and wait for admin review before their operational access is activated.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            label: 'Stylist login',
            onPressed: () => context.go('/stylist/login'),
            icon: Icons.content_cut_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: 'Apply as a stylist',
            onPressed: () => context.go('/stylist/apply'),
            icon: Icons.assignment_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Admin access',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'For internal use only. Area admins and super admins should use the admin portal login.',
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/admin/login'),
              child: const Text('Admin portal'),
            ),
          ),
        ],
      ),
    );
  }
}