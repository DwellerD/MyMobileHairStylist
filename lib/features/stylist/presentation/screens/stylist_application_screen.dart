import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/app_user_role.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_scaffold_shell.dart';
import '../../../auth/data/auth_repository.dart';
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
  static const _draftStorageKey = 'stylist_application_draft_v1';

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
  bool _draftWasRestored = false;
  bool _draftRestoreChecked = false;
  bool _autoSubmitTriggered = false;
  bool _isRefreshingStatus = false;
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
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

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDraft = prefs.getString(_draftStorageKey);
    _draftRestoreChecked = true;
    if (rawDraft == null || rawDraft.isEmpty) {
      return;
    }

    final draft = jsonDecode(rawDraft) as Map<String, dynamic>;
    _firstNameController.text = (draft['firstName'] as String?) ?? '';
    _lastNameController.text = (draft['lastName'] as String?) ?? '';
    _emailController.text = (draft['email'] as String?) ?? '';
    _phoneController.text = (draft['phone'] as String?) ?? '';
    _cityController.text = (draft['city'] as String?) ?? '';
    _stateController.text = (draft['stateCode'] as String?) ?? '';
    _licenseController.text = (draft['licenseNumber'] as String?) ?? '';
    _yearsExperienceController.text =
        (draft['yearsExperience'] as String?) ?? '';
    _specialtiesController.text = (draft['specialties'] as String?) ?? '';
    _portfolioController.text = (draft['portfolioUrl'] as String?) ?? '';
    _motivationController.text = (draft['motivation'] as String?) ?? '';
    _draftWasRestored = true;

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('We restored your saved stylist application draft.'),
      ),
    );
  }

  Future<void> _persistDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = <String, String>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'city': _cityController.text.trim(),
      'stateCode': _stateController.text.trim(),
      'licenseNumber': _licenseController.text.trim(),
      'yearsExperience': _yearsExperienceController.text.trim(),
      'specialties': _specialtiesController.text.trim(),
      'portfolioUrl': _portfolioController.text.trim(),
      'motivation': _motivationController.text.trim(),
    };
    await prefs.setString(_draftStorageKey, jsonEncode(draft));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftStorageKey);
    _draftWasRestored = false;
    _autoSubmitTriggered = false;
  }

  void _configureStatusRefresh({required bool shouldPoll}) {
    if (!shouldPoll) {
      _statusRefreshTimer?.cancel();
      _statusRefreshTimer = null;
      return;
    }

    _statusRefreshTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshApplicationStatus(),
    );
  }

  Future<void> _refreshApplicationStatus() async {
    if (_isRefreshingStatus) {
      return;
    }

    _isRefreshingStatus = true;
    ref.invalidate(currentAppUserProvider);
    ref.invalidate(currentStylistApplicationProvider);

    try {
      await ref.read(currentAppUserProvider.future);
      await ref.read(currentStylistApplicationProvider.future);
    } catch (_) {
      // Keep the last visible state and try again on the next refresh cycle.
    } finally {
      _isRefreshingStatus = false;
    }
  }

  void _maybeAutoSubmitRestoredDraft({
    required bool hasSession,
    required bool hasAppUser,
    required bool applicationResolved,
    required bool hasApplication,
    required bool isBusy,
  }) {
    if (!hasSession || !hasAppUser || !applicationResolved || hasApplication) {
      return;
    }

    if (!_draftRestoreChecked || !_draftWasRestored || _autoSubmitTriggered || isBusy) {
      return;
    }

    _autoSubmitTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      try {
        await _submit();
      } catch (_) {
        _autoSubmitTriggered = false;
      }
    });
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
          _configureStatusRefresh(
            shouldPoll:
                session != null &&
                appUser != null &&
                application?.status == 'pending',
          );

          if (appUser?.role == AppUserRole.stylist) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go('/stylist/home');
              }
            });
            return const SizedBox.shrink();
          }

          _maybeAutoSubmitRestoredDraft(
            hasSession: session != null,
            hasAppUser: appUser != null,
            applicationResolved: !applicationAsync.isLoading && !applicationAsync.hasError,
            hasApplication: application != null,
            isBusy: isBusy,
          );

          if (appUser != null && application != null) {
            return _ApplicationStatusView(
              application: application,
              onRefresh: _refreshApplicationStatus,
            );
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

    await _persistDraft();

    if (ref.read(currentSessionProvider) == null) {
      try {
        await _authenticateApplicant();
      } catch (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _localError = error.toString();
        });
        return;
      }

      ref.invalidate(currentAppUserProvider);
      final appUser = await ref.read(authRepositoryProvider).getCurrentAppUser();
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

    try {
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
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _localError = error.toString();
      });
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your stylist application has been submitted.'),
      ),
    );

    await _clearDraft();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }

    return null;
  }

  Future<void> _authenticateApplicant() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      await ref.read(authActionControllerProvider.notifier).signIn(
            email: email,
            password: password,
          );
      return;
    } catch (error) {
      final message = error.toString();
      if (message != 'The email or password is incorrect.') {
        rethrow;
      }
    }

    try {
      final signUpOutcome = await ref.read(authActionControllerProvider.notifier).signUpCustomer(
            email: email,
            password: password,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            additionalData: <String, dynamic>{
              'pending_stylist_application': true,
              'stylist_phone': _phoneController.text.trim(),
              'stylist_city': _cityController.text.trim(),
              'stylist_state': _stateController.text.trim().toUpperCase(),
              'stylist_license_number': _licenseController.text.trim(),
              'stylist_years_experience': int.tryParse(
                _yearsExperienceController.text.trim(),
              ),
              'stylist_specialties': _specialtiesController.text
                  .split(',')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList(growable: false),
              'stylist_portfolio_url': _portfolioController.text.trim(),
              'stylist_motivation': _motivationController.text.trim(),
            },
          );

      if (signUpOutcome == SignUpOutcome.confirmationRequired) {
        throw const AuthRepositoryException(
          'Your account was created, but email confirmation is required before we can submit your stylist application. Check your email, confirm the account, then sign in and submit the application.',
        );
      }
    } catch (error) {
      final message = error.toString();
      if (message == 'An account with that email already exists.') {
        throw const AuthRepositoryException(
          'This email already has an account. Log in with the existing password, then submit the stylist application.',
        );
      }
      rethrow;
    }
  }
}

class _ApplicationStatusView extends StatelessWidget {
  const _ApplicationStatusView({
    required this.application,
    required this.onRefresh,
  });

  final StylistApplication application;
  final Future<void> Function() onRefresh;

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
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: onRefresh,
          child: const Text('Refresh application status'),
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