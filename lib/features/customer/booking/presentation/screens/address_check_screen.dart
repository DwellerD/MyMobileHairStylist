import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Could not load booking setup',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      bookingAsync.error.toString().replaceFirst('Exception: ', ''),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => ref
                          .read(bookingFlowControllerProvider.notifier)
                          .retryLoad(),
                      child: const Text('Retry booking setup'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return const Center(child: CircularProgressIndicator());
    }

    final selectedAddress = bookingState.selectedAddress;
    final isBusy = bookingAsync.isLoading;
    final isSelectedAddressServiceable = selectedAddress?.isServiceable ?? false;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return BookingStepScaffold(
      stepNumber: 1,
      totalSteps: 9,
      title: 'Choose your service address',
      subtitle:
          'Choose a saved address or add a new one. We check ZIP coverage first so your in-home appointment starts with the right location details.',
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.showcaseSurfaceHighlight,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.showcaseBorderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _AddressSelectionPanel(
                          bookingState: bookingState,
                          onSelectAddress: (addressId) => ref
                              .read(bookingFlowControllerProvider.notifier)
                              .selectAddress(addressId),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _AddressFormPanel(
                          formKey: _formKey,
                          labelController: _labelController,
                          line1Controller: _line1Controller,
                          cityController: _cityController,
                          stateController: _stateController,
                          postalCodeController: _postalCodeController,
                          isBusy: isBusy,
                          onSave: () async {
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
                        ),
                      ),
                    ],
                  )
                else ...[
                  _AddressSelectionPanel(
                    bookingState: bookingState,
                    onSelectAddress: (addressId) => ref
                        .read(bookingFlowControllerProvider.notifier)
                        .selectAddress(addressId),
                  ),
                  const SizedBox(height: 18),
                  _AddressFormPanel(
                    formKey: _formKey,
                    labelController: _labelController,
                    line1Controller: _line1Controller,
                    cityController: _cityController,
                    stateController: _stateController,
                    postalCodeController: _postalCodeController,
                    isBusy: isBusy,
                    onSave: () async {
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
                  ),
                ],
              ],
            ),
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
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.showcaseSurfaceBase,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.showcaseBorderLight),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackCards = constraints.maxWidth < 760;

                if (stackCards) {
                  return const Column(
                    children: [
                      _BookingSupportCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'Questions?',
                        description:
                            'Send me a message and I can help you choose the best setup for your visit.',
                      ),
                      SizedBox(height: 12),
                      _BookingSupportCard(
                        icon: Icons.event_available_outlined,
                        title: 'Easy booking',
                        description:
                            'Move through the booking steps online and adjust later if needed.',
                      ),
                      SizedBox(height: 12),
                      _BookingSupportCard(
                        icon: Icons.favorite_border,
                        title: 'Love your hair',
                        description:
                            'Relax and enjoy a professional in-home salon experience.',
                      ),
                    ],
                  );
                }

                return const Row(
                  children: [
                    Expanded(
                      child: _BookingSupportCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'Questions?',
                        description:
                            'Send me a message and I can help you choose the best setup for your visit.',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _BookingSupportCard(
                        icon: Icons.event_available_outlined,
                        title: 'Easy booking',
                        description:
                            'Move through the booking steps online and adjust later if needed.',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _BookingSupportCard(
                        icon: Icons.favorite_border,
                        title: 'Love your hair',
                        description:
                            'Relax and enjoy a professional in-home salon experience.',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSelectionPanel extends StatelessWidget {
  const _AddressSelectionPanel({
    required this.bookingState,
    required this.onSelectAddress,
  });

  final dynamic bookingState;
  final ValueChanged<String> onSelectAddress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Choose a saved address',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select where you want the stylist to arrive.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (bookingState.addresses.isEmpty)
          const EmptyState(
            title: 'No address on file yet',
            description:
                'Add the home address where you want the stylist to arrive. Coverage is checked instantly for the current launch area.',
            icon: Icons.home_work_outlined,
          )
        else
          Column(
            children: bookingState.addresses
                .map<Widget>(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      backgroundColor: bookingState.selectedAddressId == address.id
                          ? AppColors.showcaseSurfaceSoft
                          : null,
                      onTap: () => onSelectAddress(address.id),
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
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(address.shortAddress),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  address.isServiceable
                                      ? 'Within the current launch area'
                                      : 'Outside the current launch area',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
      ],
    );
  }
}

class _AddressFormPanel extends StatelessWidget {
  const _AddressFormPanel({
    required this.formKey,
    required this.labelController,
    required this.line1Controller,
    required this.cityController,
    required this.stateController,
    required this.postalCodeController,
    required this.isBusy,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController labelController;
  final TextEditingController line1Controller;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final bool isBusy;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.showcaseSurfaceBase,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.showcaseBorderLight),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2. Add a new address',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a label and ZIP code so we can confirm service coverage.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Address label',
                hintText: 'Home, Grandma\'s house, Condo',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Add a label.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: line1Controller,
              decoration: const InputDecoration(
                labelText: 'Street address',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Add the street address.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Add the city.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: stateController,
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
                    controller: postalCodeController,
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
              onPressed: isBusy ? null : onSave,
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Save address'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSupportCard extends StatelessWidget {
  const _BookingSupportCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.showcaseSurfaceHighlight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.showcaseBorderMuted),
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}