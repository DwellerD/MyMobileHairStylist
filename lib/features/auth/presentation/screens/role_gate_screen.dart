import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_user_role.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_scaffold_shell.dart';
import '../../domain/app_user.dart';
import '../providers/auth_providers.dart';

/// Handles post-auth profile loading and role resolution.
///
/// If a user has no supported role yet, this screen explains why instead of
/// dropping them into a broken route.
class RoleGateScreen extends ConsumerWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfigured = ref.watch(supabaseConfiguredProvider);
    final session = ref.watch(currentSessionProvider);
    final appUserAsync = ref.watch(currentAppUserProvider);

    return AppScaffoldShell(
      title: 'Checking your account',
      subtitle: 'This screen loads the current session, profile, and app role before routing you forward.',
      body: !isConfigured
          ? _RoleGateMessage(
              title: 'Supabase is not configured',
              description: 'Run the app with SUPABASE_URL and SUPABASE_ANON_KEY so authentication and profile lookup can start.',
              primaryLabel: 'Back to welcome',
              onPrimaryPressed: () => context.go('/'),
            )
          : session == null
              ? _RoleGateMessage(
                  title: 'You are not logged in',
                  description: 'Sign in or create an account before entering the booking experience.',
                  primaryLabel: 'Go to login',
                  onPrimaryPressed: () => context.go('/login'),
                  secondaryLabel: 'Create account',
                  onSecondaryPressed: () => context.go('/signup'),
                )
              : appUserAsync.when(
                  data: (appUser) {
                    if (appUser == null) {
                      return _RoleGateMessage(
                        title: 'Profile setup is incomplete',
                        description: 'Your session exists, but your app profile was not found. This usually means the signup bootstrap migration has not been applied.',
                        primaryLabel: 'Refresh profile',
                        onPrimaryPressed: () => ref.invalidate(currentAppUserProvider),
                        secondaryLabel: 'Log out',
                        onSecondaryPressed: () async {
                          await ref.read(authActionControllerProvider.notifier).signOut();
                        },
                      );
                    }

                    if (!appUser.hasSupportedRole) {
                      return _RoleGateMessage(
                        title: 'Role not supported in this app yet',
                        description: _unsupportedRoleMessage(appUser),
                        primaryLabel: 'Log out',
                        onPrimaryPressed: () async {
                          await ref.read(authActionControllerProvider.notifier).signOut();
                        },
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome, ${appUser.displayName}.',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Your ${appUser.role?.label ?? 'account'} experience is ready. Routing will continue automatically.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        AppPrimaryButton(
                          label: 'Continue',
                          onPressed: () => context.go(appUser.supportedHomeLocation!),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => _RoleGateMessage(
                    title: 'We could not load your role',
                    description: error.toString(),
                    primaryLabel: 'Retry',
                    onPrimaryPressed: () => ref.invalidate(currentAppUserProvider),
                    secondaryLabel: 'Log out',
                    onSecondaryPressed: () async {
                      await ref.read(authActionControllerProvider.notifier).signOut();
                    },
                  ),
                ),
    );
  }

  String _unsupportedRoleMessage(AppUser appUser) {
    return 'Your account role is ${appUser.role?.label ?? 'unknown'}. Customer, stylist, admin, and corporate admin routes are ready now. Franchise-specific workflows can be added later.';
  }
}

class _RoleGateMessage extends StatelessWidget {
  const _RoleGateMessage({
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sectionGap),
        AppPrimaryButton(
          label: primaryLabel,
          onPressed: onPrimaryPressed,
        ),
        if (secondaryLabel != null && onSecondaryPressed != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: secondaryLabel!,
            onPressed: onSecondaryPressed,
          ),
        ],
      ],
    );
  }
}