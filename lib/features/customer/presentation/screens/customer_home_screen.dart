import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_screen_header.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/appointment_card.dart';
import '../../../../shared/widgets/service_card.dart';

/// Customer dashboard placeholder.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        const AppScreenHeader(
          title: 'Welcome back',
          subtitle: 'Book polished in-home services and keep family appointments organized in one place.',
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppPrimaryButton(
          label: 'Start a new booking',
          icon: Icons.calendar_month_outlined,
          onPressed: () => context.go('/customer/book'),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const AppSectionHeader(
          title: 'Featured services',
          subtitle: 'These now match the seeded catalog used by the real request flow.',
        ),
        const SizedBox(height: AppSpacing.md),
        const ServiceCard(
          title: 'Luxury women’s haircut',
          description: 'A polished in-home cut with consultation and finishing style included.',
          durationLabel: '75 min',
          priceLabel: 'From \$120',
          badgeLabel: 'Most booked',
        ),
        const SizedBox(height: AppSpacing.sm),
        const ServiceCard(
          title: 'Sensory-friendly kids haircut',
          description: 'A gentle appointment block designed for calmer, child-centered visits.',
          durationLabel: '45 min',
          priceLabel: 'From \$55',
          badgeLabel: 'Family',
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const AppSectionHeader(
          title: 'Upcoming appointment',
          subtitle: 'Use the appointments tab to track submitted requests, approvals, and past household visits.',
        ),
        const SizedBox(height: AppSpacing.md),
        const AppointmentCard(
          title: 'Family appointment block',
          subtitle: 'Lena and Noah',
          timeLabel: 'Saturday, May 24 at 10:00 AM',
          statusLabel: 'Requested',
          statusColor: AppColors.warning,
          address: 'Mock address on file for your household',
          actionLabel: 'View details',
        ),
      ],
    );
  }
}