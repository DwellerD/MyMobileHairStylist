import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/service_card.dart';

/// Customer booking placeholder.
///
/// This will become the multi-step booking flow with services, family members,
/// address selection, notes, and photo upload.
class BookAppointmentScreen extends StatelessWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppScreenHeader(
          title: 'Book appointment',
          subtitle: 'The MVP booking flow will stay calm and guided, one decision at a time.',
        ),
        SizedBox(height: AppSpacing.sectionGap),
        AppSectionHeader(
          title: 'Choose a service',
          subtitle: 'Mock cards for the first pass of the service catalog.',
        ),
        SizedBox(height: AppSpacing.md),
        ServiceCard(
          title: 'Blowout and style',
          description: 'An in-home finish with smooth styling and a polished look.',
          durationLabel: '60 min',
          priceLabel: 'Mock pricing',
        ),
        SizedBox(height: AppSpacing.sm),
        ServiceCard(
          title: 'Men’s haircut and beard trim',
          description: 'A clean, premium grooming visit at home.',
          durationLabel: '50 min',
          priceLabel: 'Mock pricing',
        ),
        SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next in this flow', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Add family members, confirm address, upload reference photos, and request a preferred time.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppPrimaryButton(
          label: 'Continue booking',
          icon: Icons.arrow_forward_outlined,
          onPressed: null,
        ),
      ],
    );
  }
}