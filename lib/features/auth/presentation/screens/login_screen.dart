import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_scaffold_shell.dart';
import '../providers/auth_providers.dart';

/// Placeholder login screen.
///
/// This is now wired to Supabase email/password login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

    return AppScaffoldShell(
      title: 'Log in',
      subtitle: 'Access your booking, stylist, or admin experience.',
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
          if (actionState.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              actionState.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            onPressed: actionState.isLoading || !isConfigured
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    await ref.read(authActionControllerProvider.notifier).signIn(
                          email: _emailController.text,
                          password: _passwordController.text,
                        );
                  },
            label: 'Continue',
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.go('/signup'),
            child: const Text('Need an account? Sign up'),
          ),
        ],
        ),
      ),
    );
  }
}