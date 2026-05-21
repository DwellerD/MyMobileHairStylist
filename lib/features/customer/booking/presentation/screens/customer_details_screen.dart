import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../domain/booking_flow_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Step 4 of 5 — captures the service address, contact phone number, and any
/// access / arrival notes (gate codes, parking instructions, etc.).
class CustomerDetailsScreen extends ConsumerStatefulWidget {
  const CustomerDetailsScreen({super.key});

  @override
  ConsumerState<CustomerDetailsScreen> createState() =>
      _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState
    extends ConsumerState<CustomerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  // Form for adding a new address inline
  bool _showAddressForm = false;
  final _addressFormKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    _labelController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Sync text fields from state if they have changed externally
    if (_phoneController.text.isEmpty &&
        (bookingState.customerPhone ?? '').isNotEmpty) {
      _phoneController.text = bookingState.customerPhone!;
    }
    if (_notesController.text.isEmpty &&
        bookingState.customerNotes.isNotEmpty) {
      _notesController.text = bookingState.customerNotes;
    }

    final canContinue = bookingState.selectedAddressId != null &&
        _phoneController.text.trim().length >= 7;

    return BookingStepScaffold(
      displayStep: 4,
      stepNumber: 4,
      totalSteps: 5,
      title: 'Your details',
      subtitle:
          'Confirm the service address and share how we can reach you on the day.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.go('/customer/book/time'),
      primaryLabel: 'Review & confirm',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: canContinue
          ? () {
              ref
                  .read(bookingFlowControllerProvider.notifier)
                  .setPhone(_phoneController.text);
              ref
                  .read(bookingFlowControllerProvider.notifier)
                  .setNotes(_notesController.text);
              context.go('/customer/book/review');
            }
          : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Address selection ──────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service address',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (bookingState.addresses.isEmpty)
                    const Text(
                      'No saved addresses. Add one below.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Column(
                      children: bookingState.addresses.map((address) {
                        final isSelected =
                            bookingState.selectedAddressId == address.id;
                        return RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: address.id,
                          groupValue: bookingState.selectedAddressId,
                          onChanged: (id) {
                            if (id != null) {
                              ref
                                  .read(
                                    bookingFlowControllerProvider.notifier,
                                  )
                                  .selectAddress(id);
                            }
                          },
                          title: Text(
                            address.label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(address.shortAddress),
                          activeColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  // Toggle inline add-address form
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showAddressForm = !_showAddressForm),
                    child: Row(
                      children: [
                        Icon(
                          _showAddressForm
                              ? Icons.remove_circle_outline
                              : Icons.add_circle_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showAddressForm
                              ? 'Cancel new address'
                              : 'Add a new address',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showAddressForm) ...[
                    const SizedBox(height: AppSpacing.md),
                    Form(
                      key: _addressFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _labelController,
                            decoration: const InputDecoration(
                              labelText: 'Label (e.g. Home, Work)',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Add a label.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _line1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Street address',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Add street address.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Add city.'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextFormField(
                                  controller: _stateController,
                                  decoration: const InputDecoration(
                                    labelText: 'State',
                                    hintText: 'AZ',
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  validator: (v) =>
                                      v == null || v.trim().length != 2
                                          ? '2-letter'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextFormField(
                                  controller: _zipController,
                                  decoration: const InputDecoration(
                                    labelText: 'ZIP',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      v == null || v.trim().length < 5
                                          ? '5 digits'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.tonalIcon(
                            onPressed: bookingAsync.isLoading
                                ? null
                                : () async {
                                    if (!_addressFormKey.currentState!
                                        .validate()) return;
                                    await ref
                                        .read(
                                          bookingFlowControllerProvider
                                              .notifier,
                                        )
                                        .createAddress(
                                          label: _labelController.text,
                                          line1: _line1Controller.text,
                                          city: _cityController.text,
                                          stateCode: _stateController.text,
                                          postalCode: _zipController.text,
                                        );
                                    if (mounted) {
                                      setState(() {
                                        _showAddressForm = false;
                                        _labelController.clear();
                                        _line1Controller.clear();
                                        _cityController.clear();
                                        _stateController.clear();
                                        _zipController.clear();
                                      });
                                    }
                                  },
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Save address'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Phone number ───────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact phone',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'We\'ll use this to reach you on the day of the appointment. '
                    'Not shared outside the booking team.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number *',
                      hintText: '(555) 123-4567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Access / arrival notes ─────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Access notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Optional — gate code, parking instructions, entry details, or anything else to help the stylist arrive smoothly.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'e.g. "Gate code 1234, park in driveway"',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
