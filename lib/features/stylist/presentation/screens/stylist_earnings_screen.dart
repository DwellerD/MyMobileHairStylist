import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/empty_state.dart';

/// Stylist earnings placeholder.
class StylistEarningsScreen extends StatelessWidget {
  const StylistEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const AppScreenHeader(
          title: 'Earnings',
          subtitle: 'Payout summaries and tips will be added after booking operations are stable.',
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This week', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text('Placeholder for shifts, completed appointments, and payout totals.', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const EmptyState(
          title: 'Payout data not connected yet',
          description: 'Stripe and earnings calculations will be wired in after the core booking and completion flows.',
          icon: Icons.payments_outlined,
        ),
      ],
    );
  }
}