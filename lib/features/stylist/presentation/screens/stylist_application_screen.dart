import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_scaffold_shell.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../domain/stylist_application.dart';
import '../providers/stylist_application_providers.dart';

class StylistApplicationScreen extends ConsumerStatefulWidget {
  const StylistApplicationScreen({super.key});

  @override
  ConsumerState<StylistApplicationScreen> createState() =>
      _StylistApplicationScreenState();
}

class _StylistApplicationScreenState
    extends ConsumerState<StylistApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _licenseController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _motivationController = TextEditingController();

  String? _localError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _licenseController.dispose();
    _yearsExperienceController.dispose();
    _specialtiesController.dispose();
    _portfolioController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final appUserAsync = ref.watch(currentAppUserProvider);
    final applicationAsync = ref.watch(currentStylistApplicationProvider);
    final authActionState = ref.watch(authActionControllerProvider);
    final applicationActionState =
        ref.watch(stylistApplicationActionControllerProvider);
    final isBusy = authActionState.isLoading || applicationActionState.isLoading;

    return AppScaffoldShell(
      title: 'Apply as a stylist',
      subtitle:
          'Create your account, share your specialties, and submit your application for admin review.',
      body: appUserAsync.when(
        data: (appUser) {
          final application = applicationAsync.valueOrNull;
          if (appUser != null && application != null) {
            return _ApplicationStatusView(application: application);
          }

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (session == null) ...[
                  const Text(
                    'Account details',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (value) => _required(value, 'First name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (value) => _required(value, 'Last name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => _required(value, 'Email'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required.';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                ] else ...[
                  Text(
                    'Applying as ${appUser?.displayName ?? 'your account'} (${appUser?.email ?? ''})',
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                ],
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) => _required(value, 'Phone number'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (value) => _required(value, 'City'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                  validator: (value) => _required(value, 'State'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(labelText: 'License number'),
                  validator: (value) => _required(value, 'License number'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _yearsExperienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Years of experience'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _specialtiesController,
                  decoration: const InputDecoration(
                    labelText: 'Specialties',
                    hintText: 'Comma-separated, e.g. balayage, bridal, kids',
                  ),
                  validator: (value) => _required(value, 'At least one specialty'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _portfolioController,
                  decoration: const InputDecoration(
                    labelText: 'Portfolio URL',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _motivationController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Tell us about your experience and why you want to join',
                  ),
                  validator: (value) => _required(value, 'A short application note'),
                ),
                if (_localError != null || authActionState.hasError || applicationActionState.hasError) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _localError ??
                        authActionState.error?.toString() ??
                        applicationActionState.error.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: session == null ? 'Create account and apply' : 'Submit application',
                  onPressed: isBusy ? null : _submit,
                ),
                if (session == null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen.stylist(),
                      ),
                    ),
                    child: const Text('Already approved? Log in as stylist'),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _localError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (ref.read(currentSessionProvider) == null) {
      await ref.read(authActionControllerProvider.notifier).signUpCustomer(
            email: _emailController.text,
            password: _passwordController.text,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
          );

      final appUser = await ref.refresh(currentAppUserProvider.future);
      if (appUser == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _localError =
              'Your account was created, but your application could not continue yet. Please log in and try again.';
        });
        return;
      }
    }

    await ref.read(stylistApplicationActionControllerProvider.notifier).submitApplication(
          phone: _phoneController.text,
          city: _cityController.text,
          stateCode: _stateController.text,
          licenseNumber: _licenseController.text,
          yearsExperience: int.tryParse(_yearsExperienceController.text.trim()),
          specialties: _specialtiesController.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false),
          portfolioUrl: _portfolioController.text,
          motivation: _motivationController.text,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your stylist application has been submitted.'),
      ),
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }

    return null;
  }
}

class _ApplicationStatusView extends StatelessWidget {
  const _ApplicationStatusView({required this.application});

  final StylistApplication application;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (application.status) {
      'pending' => 'Pending review',
      'approved' => 'Approved',
      'rejected' => 'Needs attention',
      _ => application.status,
    };

    final statusCopy = switch (application.status) {
      'pending' => 'Your application is under review. An admin will activate stylist access after approval.',
      'approved' => 'Your application has been approved. Use the stylist login if your account has already been activated.',
      'rejected' => 'Your application was reviewed, but more information is needed before activation.',
      _ => 'Your application is on file.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(statusLabel, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(statusCopy),
        const SizedBox(height: AppSpacing.sectionGap),
        Text('Submitted by: ${application.applicantName}'),
        const SizedBox(height: AppSpacing.xxs),
        Text('Email: ${application.email}'),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          application.specialties.isEmpty
              ? 'No specialties listed'
              : 'Specialties: ${application.specialties.join(', ')}',
        ),
        if (application.reviewerNotes?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Reviewer notes: ${application.reviewerNotes}',
          ),
        ],
      ],
    );
  }
}