import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_card.dart';

/// Reusable appointment summary card.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    required this.title,
    required this.timeLabel,
    required this.statusLabel,
    required this.address,
    this.subtitle,
    this.actionLabel,
    this.onActionPressed,
    this.statusColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String timeLabel;
  final String statusLabel;
  final String address;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final resolvedStatusColor = statusColor ?? AppColors.info;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: resolvedStatusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: resolvedStatusColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(timeLabel, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.location_on_outlined, size: 18),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(address, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}