import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// First booking step where a customer confirms or adds a service address.
class AddressCheckScreen extends ConsumerStatefulWidget {
  const AddressCheckScreen({super.key});

  @override
  ConsumerState<AddressCheckScreen> createState() => _AddressCheckScreenState();
}

class _AddressCheckScreenState extends ConsumerState<AddressCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      if (bookingAsync.hasError) {
        return Center(
          child: FilledButton(
            onPressed: () => ref
                .read(bookingFlowControllerProvider.notifier)
                .retryLoad(),
            child: const Text('Retry booking setup'),
          ),
        );
      }

      return const Center(child: CircularProgressIndicator());
    }

    final selectedAddress = bookingState.selectedAddress;
    final isBusy = bookingAsync.isLoading;
    final isSelectedAddressServiceable = selectedAddress?.isServiceable ?? false;

    return BookingStepScaffold(
      stepNumber: 1,
      totalSteps: 7,
      title: 'Confirm your service address',
      subtitle:
          'Choose a saved address or add a new one. The MVP launch checks ZIP code coverage before we accept the request.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: isBusy,
      primaryLabel: 'Continue to household',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: isSelectedAddressServiceable
          ? () => context.go('/customer/book/household-members')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bookingState.addresses.isEmpty)
            const EmptyState(
              title: 'No address on file yet',
              description:
                  'Add the home address where you want the stylist to arrive. We will confirm launch-area support instantly for the MVP.',
              icon: Icons.home_work_outlined,
            )
          else
            Column(
              children: bookingState.addresses
                  .map(
                    (address) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        backgroundColor: bookingState.selectedAddressId == address.id
                            ? AppColors.surfaceAlt
                            : null,
                        onTap: () => ref
                            .read(bookingFlowControllerProvider.notifier)
                            .selectAddress(address.id),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              bookingState.selectedAddressId == address.id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: bookingState.selectedAddressId == address.id
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address.label,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(address.shortAddress),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    address.isServiceable
                                        ? 'Within the current launch area'
                                        : 'Outside the current launch area',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: address.isServiceable
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          if (selectedAddress != null && !selectedAddress.isServiceable) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              backgroundColor: AppColors.surfaceAlt,
              child: Text(
                'That ZIP code is not in the current launch list. Supported ZIPs: ${AppConstants.supportedServiceZipCodes.join(', ')}',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add another address',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Address label',
                      hintText: 'Home, Grandma\'s house, Condo',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Add a label.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _line1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Street address',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Add the street address.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Add the city.' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'State'),
                          validator: (value) {
                            final normalized = value?.trim() ?? '';
                            if (normalized.length != 2) {
                              return 'Use a 2-letter state.';
                            }

                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _postalCodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ZIP code'),
                          validator: (value) {
                            final normalized = value?.trim() ?? '';
                            if (normalized.length != 5) {
                              return 'Use a 5-digit ZIP.';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Current launch ZIPs: ${AppConstants.supportedServiceZipCodes.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonalIcon(
                    onPressed: isBusy
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            await ref
                                .read(bookingFlowControllerProvider.notifier)
                                .createAddress(
                                  label: _labelController.text,
                                  line1: _line1Controller.text,
                                  city: _cityController.text,
                                  stateCode: _stateController.text,
                                  postalCode: _postalCodeController.text,
                                );

                            if (!mounted) {
                              return;
                            }

                            _labelController.clear();
                            _line1Controller.clear();
                            _cityController.clear();
                            _stateController.clear();
                            _postalCodeController.clear();
                          },
                    icon: const Icon(Icons.add_home_outlined),
                    label: const Text('Save address'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}