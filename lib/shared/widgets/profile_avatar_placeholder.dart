import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Reusable avatar placeholder for customer, stylist, and admin profile areas.
class ProfileAvatarPlaceholder extends StatelessWidget {
  const ProfileAvatarPlaceholder({
    this.name,
    this.icon = Icons.person_outline,
    this.size = AppSpacing.avatarSize,
    super.key,
  });

  final String? name;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: initials == null
          ? Icon(icon, color: AppColors.primary, size: size * 0.42)
          : Text(
              initials,
              style: Theme.of(context).textTheme.titleLarge,
            ),
    );
  }

  String? _initialsFromName(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) {
      return null;
    }

    final parts = rawName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return null;
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}