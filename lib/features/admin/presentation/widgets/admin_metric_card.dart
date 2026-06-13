import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';

/// Reusable metric tile for the admin dashboard.
class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.helperText,
    this.iconColor,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? helperText;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? AppColors.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: resolvedIconColor),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          if (helperText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(helperText!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}