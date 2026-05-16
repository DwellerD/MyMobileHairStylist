import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_user_role.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_scaffold_shell.dart';
import '../providers/auth_providers.dart';

/// Placeholder login screen.
///
/// This is now wired to Supabase email/password login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    this.experience = LoginExperience.customer,
    super.key,
  });

  const LoginScreen.stylist({super.key})
      : experience = LoginExperience.stylist;

  const LoginScreen.admin({super.key})
      : experience = LoginExperience.admin;

  final LoginExperience experience;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _roleErrorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = ref.watch(supabaseConfiguredProvider);
    final actionState = ref.watch(authActionControllerProvider);
    final title = switch (widget.experience) {
      LoginExperience.customer => 'Log in',
      LoginExperience.stylist => 'Stylist login',
      LoginExperience.admin => 'Admin portal',
    };
    final subtitle = switch (widget.experience) {
      LoginExperience.customer =>
        'Access your booking, stylist, or admin experience.',
      LoginExperience.stylist =>
        'Approved stylists can access schedule, appointment, safety, and profile tools here.',
      LoginExperience.admin =>
        'Internal operations login for reviewing applications, bookings, and staff access.',
    };

    return AppScaffoldShell(
      title: title,
      subtitle: subtitle,
      body: Form(
        key: _formKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isConfigured) ...[
            Text(
              'Supabase is not configured yet. Add the required dart-define values before testing login.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required.';
              }

              return null;
            },
          ),
          if (actionState.hasError || _roleErrorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _roleErrorMessage ?? actionState.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            onPressed: actionState.isLoading || !isConfigured
                ? null
                : _submit,
            label: 'Continue',
          ),
          if (widget.experience == LoginExperience.customer) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Need an account? Sign up'),
            ),
          ] else if (widget.experience == LoginExperience.stylist) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go('/stylist/apply'),
              child: const Text('Need stylist access? Apply here'),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go('/stylist/portal'),
              child: const Text('Back to stylist portal'),
            ),
          ],
        ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _roleErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref.read(authActionControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    final appUser = await ref.refresh(currentAppUserProvider.future);
    if (!mounted) {
      return;
    }

    final allowedRoles = switch (widget.experience) {
      LoginExperience.customer => null,
      LoginExperience.stylist => <AppUserRole>{AppUserRole.stylist},
      LoginExperience.admin => <AppUserRole>{
        AppUserRole.admin,
        AppUserRole.corporateAdmin,
      },
    };

    if (allowedRoles != null &&
        (appUser == null || appUser.role == null || !allowedRoles.contains(appUser.role))) {
      await ref.read(authActionControllerProvider.notifier).signOut();
      if (!mounted) {
        return;
      }

      setState(() {
        _roleErrorMessage = switch (widget.experience) {
          LoginExperience.customer => 'This account could not be loaded.',
          LoginExperience.stylist =>
            'This account does not have stylist access yet. Apply in the stylist portal if you have not been approved.',
          LoginExperience.admin =>
            'This account does not have admin access.',
        };
      });
      return;
    }

    if (appUser?.supportedHomeLocation != null) {
      context.go(appUser!.supportedHomeLocation!);
      return;
    }

    context.go('/role-gate');
  }
}

enum LoginExperience {
  customer,
  stylist,
  admin,
}