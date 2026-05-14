import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_screen_header.dart';
import '../../../../../shared/widgets/app_secondary_button.dart';

/// Shared layout wrapper used across each booking step screen.
class BookingStepScaffold extends StatelessWidget {
  const BookingStepScaffold({
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.primaryIcon,
    this.isBusy = false,
    this.errorMessage,
    this.showProgress = true,
    super.key,
  });

  final int stepNumber;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData? primaryIcon;
  final bool isBusy;
  final String? errorMessage;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        if (showProgress) ...[
          AppCard(
            backgroundColor: AppColors.surfaceAlt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $stepNumber of $totalSteps',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: stepNumber / totalSteps,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: AppColors.border,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        AppScreenHeader(
          title: title,
          subtitle: subtitle,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            backgroundColor: AppColors.surfaceAlt,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        child,
        const SizedBox(height: AppSpacing.sectionGap),
        if (secondaryLabel != null) ...[
          AppSecondaryButton(
            label: secondaryLabel!,
            onPressed: isBusy ? null : onSecondaryPressed,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppPrimaryButton(
          label: isBusy ? 'Working...' : primaryLabel,
          icon: primaryIcon,
          onPressed: isBusy ? null : onPrimaryPressed,
        ),
      ],
    );
  }
}

/// Normalizes AsyncValue errors so screens can show a small inline message.
String? bookingErrorMessage(AsyncValue<dynamic> asyncValue) {
  if (!asyncValue.hasError) {
    return null;
  }

  return asyncValue.asError!.error.toString().replaceFirst('Exception: ', '');
}