import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'app_card.dart';
import 'app_screen_header.dart';
import 'app_section_header.dart';

/// Simple reusable placeholder content for the tab screens.
///
/// Keeping placeholders consistent makes it easier to swap each screen from mock
/// content to real feature widgets one by one later.
class PlaceholderScreenContent extends StatelessWidget {
  const PlaceholderScreenContent({
    required this.title,
    required this.description,
    required this.highlights,
    super.key,
  });

  final String title;
  final String description;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppScreenHeader(title: title, subtitle: description),
          const SizedBox(height: AppSpacing.sectionGap),
          const AppSectionHeader(
            title: 'Planned content',
            subtitle: 'These placeholders now use the shared design system.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in highlights) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(Icons.check_circle_outline, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(item)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}