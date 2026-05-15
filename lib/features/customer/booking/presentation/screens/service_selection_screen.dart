import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../domain/booking_service_catalog.dart';
import '../../domain/booking_flow_state.dart';
import '../providers/booking_flow_controller.dart';
import '../widgets/booking_step_scaffold.dart';

/// Step where customers choose the services they want included in the request.
class ServiceSelectionScreen extends ConsumerStatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  ConsumerState<ServiceSelectionScreen> createState() =>
      _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends ConsumerState<ServiceSelectionScreen> {
  BookingServiceCategory _selectedCategory = BookingServiceCategory.women;

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingFlowControllerProvider);
    final bookingState = bookingAsync.valueOrNull;

    if (bookingState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final servicesByCategory = <BookingServiceCategory, List<BookingServiceOption>>{
      for (final category in BookingServiceCategory.values)
        category: bookingState.services
            .where((service) => _categorizeService(service) == category)
            .toList(growable: false)
          ..sort(_compareServicesWithinCategory),
    };
    final activeServices = servicesByCategory[_selectedCategory] ?? const [];
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return BookingStepScaffold(
      stepNumber: 3,
      totalSteps: 8,
      title: 'Choose your service',
      subtitle:
          'Select the service you would like to book. The visuals now match the mobile direction more closely while still using the real booking state and navigation.',
      errorMessage: bookingErrorMessage(bookingAsync),
      isBusy: bookingAsync.isLoading,
      secondaryLabel: 'Back to household',
      onSecondaryPressed: () => context.go('/customer/book/household-members'),
      primaryLabel: 'Continue to notes',
      primaryIcon: Icons.arrow_forward,
      onPrimaryPressed: bookingState.selectedServiceIds.isNotEmpty
          ? () => context.go('/customer/book/notes')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bookingState.services.isEmpty)
            const EmptyState(
              title: 'No services are published yet',
              description:
                  'Run the seed migration or add services in Supabase so customers can request appointments.',
              icon: Icons.content_cut_outlined,
            )
          else ...[
            TextButton.icon(
              onPressed: () => context.go('/customer/book/household-members'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to household'),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFBF8), Color(0xFFF1E4D9)],
                ),
                border: Border.all(color: const Color(0xFFE7D8CB)),
              ),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 22 : 16),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ServiceHeroCopy(category: _selectedCategory),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _ServiceHeroVisual(category: _selectedCategory),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ServiceHeroCopy(category: _selectedCategory),
                          const SizedBox(height: 16),
                          _ServiceHeroVisual(category: _selectedCategory),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE7D8CB)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in BookingServiceCategory.values)
                    _CategoryChip(
                      label: category.label,
                      isSelected: _selectedCategory == category,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _selectedCategory.label,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (activeServices.isEmpty)
              AppCard(
                child: Text(
                  'No ${_selectedCategory.label.toLowerCase()} services are currently available. Try another category or publish more services.',
                ),
              )
            else
              Column(
                children: activeServices
                    .map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ServiceListCard(
                          service: service,
                          isSelected: bookingState.selectedServiceIds.contains(service.id),
                          onTap: () => ref
                              .read(bookingFlowControllerProvider.notifier)
                              .toggleService(service.id),
                          category: _selectedCategory,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackSummary = constraints.maxWidth < 720;

              final summaryDetails = bookingState.selectedServiceIds.isEmpty
                  ? _SupportPrompt(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Select a service or continue to notes if you want to describe what you need.',
                            ),
                          ),
                        );
                      },
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected services',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...bookingState.selectedServices.map(
                          (service) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${service.name} • ${service.durationMinutes} min • ${service.priceLabel}',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );

              final estimateCard = Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EFE6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starting estimate',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bookingState.selectedServiceIds.isEmpty
                          ? 'Choose'
                          : '${bookingState.estimatedDurationMinutes} min',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      bookingState.selectedServiceIds.isEmpty
                          ? 'Starting at -'
                          : bookingState.estimatedTotalCents == 0
                              ? 'Custom quote'
                              : 'Total ${formatPriceCents(bookingState.estimatedTotalCents)}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE7D8CB)),
                ),
                child: stackSummary
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          summaryDetails,
                          const SizedBox(height: 16),
                          estimateCard,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: summaryDetails),
                          const SizedBox(width: 18),
                          estimateCard,
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

BookingServiceCategory _categorizeService(BookingServiceOption service) {
  final name = service.name.toLowerCase();
  final exactCategory = bookingServiceCategoryByName[name];
  if (exactCategory != null) {
    return exactCategory;
  }

  if (name.contains('highlight') ||
      name.contains('balayage') ||
      name.contains('root retouch') ||
      name.contains('all over color') ||
      name.contains('color correction')) {
    return BookingServiceCategory.hairColor;
  }

  if (name.contains('bridal') ||
      name.contains('wedding') ||
      name.contains('bridesmaid') ||
      name.contains('flower girl') ||
      name.contains('updo') ||
      name.contains('hollywood waves') ||
      name.contains('event hair')) {
    return BookingServiceCategory.specialEventWedding;
  }

  if (name.contains('kid') || name.contains('child') || name.contains('youth')) {
    return BookingServiceCategory.kids;
  }
  if (name.contains('men') ||
      name.contains('beard') ||
      name.contains('fade') ||
      name.contains('taper') ||
      name.contains('undercut')) {
    return BookingServiceCategory.men;
  }
  if (name.contains('toner') ||
      name.contains('gloss') ||
      name.contains('conditioning') ||
      name.contains('massage') ||
      name.contains('hot tool') ||
      name.contains('tinsel') ||
      name.contains('extension blend') ||
      name.contains('extra styling') ||
      name.contains('treatment')) {
    return BookingServiceCategory.addOns;
  }

  return BookingServiceCategory.women;
}

int _compareServicesWithinCategory(
  BookingServiceOption left,
  BookingServiceOption right,
) {
  final category = _categorizeService(left);
  final order = bookingServiceNamesByCategory[category] ?? const <String>[];
  final leftIndex = order.indexOf(left.name);
  final rightIndex = order.indexOf(right.name);

  if (leftIndex != -1 && rightIndex != -1) {
    return leftIndex.compareTo(rightIndex);
  }
  if (leftIndex != -1) {
    return -1;
  }
  if (rightIndex != -1) {
    return 1;
  }

  return left.name.compareTo(right.name);
}

class _ServiceHeroCopy extends StatelessWidget {
  const _ServiceHeroCopy({required this.category});

  final BookingServiceCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haircut & Styling',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _heroSubtitleForCategory(category),
          style: GoogleFonts.manrope(
            fontSize: 15,
            height: 1.7,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        const Icon(Icons.favorite_border, color: AppColors.accent),
      ],
    );
  }
}

String _heroSubtitleForCategory(BookingServiceCategory category) {
  switch (category) {
    case BookingServiceCategory.women:
      return 'Women\'s haircut and styling services tailored for shape, movement, and polished in-home finishes.';
    case BookingServiceCategory.hairColor:
      return 'Dimension, brightness, root coverage, and corrective color services requested through the booking flow.';
    case BookingServiceCategory.men:
      return 'Men\'s grooming, fades, beard cleanup, and scalp care delivered at home.';
    case BookingServiceCategory.kids:
      return 'Kid-friendly haircut options, first-haircut moments, and simple finishing styles.';
    case BookingServiceCategory.addOns:
      return 'Treatments and finishing upgrades that pair with your core haircut, color, or event service.';
    case BookingServiceCategory.specialEventWedding:
      return 'Wedding-day styling, bridal previews, glam waves, and formal event hair for groups or individual appointments.';
  }
}

class _ServiceHeroVisual extends StatelessWidget {
  const _ServiceHeroVisual({required this.category});

  final BookingServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final tones = _heroTones(category);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tones.$1, tones.$2],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: 18, right: 24, child: _MiniLeafSprig()),
          Positioned(
            left: 16,
            bottom: 18,
            child: Row(
              children: const [
                _HeroTool(width: 66),
                SizedBox(width: 8),
                _HeroTool(width: 48),
                SizedBox(width: 8),
                _HeroTool(width: 74),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 22,
            child: Container(
              width: 76,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFE8DACB),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Positioned(
            left: 26,
            bottom: 26,
            child: Container(
              width: 82,
              height: 122,
              decoration: BoxDecoration(
                color: const Color(0xFF1D1C20),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: 20,
            child: Container(
              width: 160,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F0E7),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 124,
                height: 162,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tones.$3, const Color(0xFFF7F1EA)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(62),
                    bottom: Radius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

(Color, Color, Color) _heroTones(BookingServiceCategory category) {
  switch (category) {
    case BookingServiceCategory.women:
      return (const Color(0xFFF8EEE6), const Color(0xFFE9D6CA), const Color(0xFF9C745C));
    case BookingServiceCategory.hairColor:
      return (const Color(0xFFF7EFE8), const Color(0xFFE9D7C7), const Color(0xFF8B5E3C));
    case BookingServiceCategory.men:
      return (const Color(0xFFF2ECE6), const Color(0xFFE1D1C6), const Color(0xFF4A372D));
    case BookingServiceCategory.kids:
      return (const Color(0xFFF7EEE7), const Color(0xFFECDCD0), const Color(0xFFC69463));
    case BookingServiceCategory.addOns:
      return (const Color(0xFFF5EDE6), const Color(0xFFE8D7CA), const Color(0xFF7B6254));
    case BookingServiceCategory.specialEventWedding:
      return (const Color(0xFFF8F1EA), const Color(0xFFEADBCF), const Color(0xFFAE7F67));
  }
}

class _MiniLeafSprig extends StatelessWidget {
  const _MiniLeafSprig();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 60,
      child: Stack(
        children: List.generate(5, (index) {
          return Positioned(
            left: index * 18,
            top: index.isEven ? 10 : 0,
            child: Transform.rotate(
              angle: 0.55,
              child: Container(
                width: 16,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF859370),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HeroTool extends StatelessWidget {
  const _HeroTool({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.18,
      child: Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFF43352F),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : const Color(0xFFFFFBF8),
        foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      child: Text(label),
    );
  }
}

class _ServiceListCard extends StatelessWidget {
  const _ServiceListCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
    required this.category,
  });

  final BookingServiceOption service;
  final bool isSelected;
  final VoidCallback onTap;
  final BookingServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final tones = _heroTones(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF6EF) : const Color(0xFFFFFCF9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.accent : const Color(0xFFE7D8CB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tones.$3, const Color(0xFFF4E9DE)],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 86,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F2EC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                        bottom: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.chevron_right,
                          color: isSelected ? AppColors.accent : AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description ??
                          'Professional in-home hair service tailored to your household.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        Text(
                          '${service.durationMinutes} min',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '|',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFFD4C1AF),
                          ),
                        ),
                        Text(
                          'Starting at ${service.priceLabel}',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportPrompt extends StatelessWidget {
  const _SupportPrompt({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 700;

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4D4C7)),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _SupportPromptCopy()),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message Us'),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE4D4C7)),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            const Expanded(child: _SupportPromptCopy()),
            const SizedBox(width: 14),
            Flexible(
              child: OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message Us'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SupportPromptCopy extends StatelessWidget {
  const _SupportPromptCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not sure what to book?',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Our stylists are here to help you choose the best fit.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}