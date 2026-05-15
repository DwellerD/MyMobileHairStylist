import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
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
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFCF8),
                  Color(0xFFF7EEE6),
                ],
              ),
              border: Border.all(color: const Color(0xFFE7D8CB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isWide ? 28 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BookingHero(
                    title: title,
                    subtitle: subtitle,
                    stepNumber: stepNumber,
                    totalSteps: totalSteps,
                    showProgress: showProgress,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6EC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE8D5C3)),
                      ),
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
                    const SizedBox(height: AppSpacing.sectionGap),
                  ],
                  child,
                  const SizedBox(height: AppSpacing.sectionGap),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE7D8CB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        const SizedBox(height: AppSpacing.sm),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stackNotice = constraints.maxWidth < 360;

                            if (stackNotice) {
                              return Column(
                                children: [
                                  const Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Your booking information is safe and secure.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Your booking information is safe and secure.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingHero extends StatelessWidget {
  const _BookingHero({
    required this.title,
    required this.subtitle,
    required this.stepNumber,
    required this.totalSteps,
    required this.showProgress,
  });

  final String title;
  final String subtitle;
  final int stepNumber;
  final int totalSteps;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return Container(
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF8), Color(0xFFF1E4D9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            const _BookingTopNav()
          else
            const _BookingBrandCompact(),
          const SizedBox(height: 20),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BookingHeroCopy(
                    title: title,
                    subtitle: subtitle,
                    stepNumber: stepNumber,
                    totalSteps: totalSteps,
                    showProgress: showProgress,
                  ),
                ),
                const SizedBox(width: 24),
                const Expanded(child: _BookingHeroVisual()),
              ],
            )
          else ...[
            _BookingHeroCopy(
              title: title,
              subtitle: subtitle,
              stepNumber: stepNumber,
              totalSteps: totalSteps,
              showProgress: showProgress,
            ),
            const SizedBox(height: 18),
            const _BookingHeroVisual(),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xCCFFFDF9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7D8CB)),
            ),
            child: Column(
              children: [
                Text(
                  'Book in',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(42, -10),
                  child: Text(
                    'easy steps',
                    style: GoogleFonts.parisienne(
                      fontSize: 36,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _BookingProgressRow(
                  stepNumber: stepNumber,
                  totalSteps: totalSteps,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTopNav extends StatelessWidget {
  const _BookingTopNav();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _BookingBrandCompact()),
        ...const [
          _BookingNavItem(label: 'HOME'),
          _BookingNavItem(label: 'SERVICES'),
          _BookingNavItem(label: 'ABOUT'),
          _BookingNavItem(label: 'GALLERY'),
          _BookingNavItem(label: 'BOOKING', isActive: true),
          _BookingNavItem(label: 'CONTACT'),
        ],
        const SizedBox(width: 16),
        FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF232125),
            disabledBackgroundColor: const Color(0xFF232125),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
          child: const Text('BOOK NOW'),
        ),
      ],
    );
  }
}

class _BookingBrandCompact extends StatelessWidget {
  const _BookingBrandCompact();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'My',
          style: GoogleFonts.parisienne(
            fontSize: 28,
            color: AppColors.accent,
          ),
        ),
        Text(
          'MOBILE',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'HAIR STYLIST',
          style: GoogleFonts.manrope(
            fontSize: 10,
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _BookingNavItem extends StatelessWidget {
  const _BookingNavItem({required this.label, this.isActive = false});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: isActive ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 42,
            child: Divider(
              color: isActive ? const Color(0xFFE7CDBB) : Colors.transparent,
              thickness: 2,
              height: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingHeroCopy extends StatelessWidget {
  const _BookingHeroCopy({
    required this.title,
    required this.subtitle,
    required this.stepNumber,
    required this.totalSteps,
    required this.showProgress,
  });

  final String title;
  final String subtitle;
  final int stepNumber;
  final int totalSteps;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BOOK YOUR',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Appointment',
          style: GoogleFonts.cormorantGaramond(
            fontSize: isWide ? 62 : 48,
            height: 0.95,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 180,
          height: 1,
          color: const Color(0xFFD9C7B8),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 15,
            height: 1.7,
            color: AppColors.textSecondary,
          ),
        ),
        if (showProgress) ...[
          const SizedBox(height: 18),
          Text(
            'Current step: $stepNumber of $totalSteps',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _HeroFeature(icon: Icons.home_outlined, label: 'I come to you'),
            _HeroFeature(icon: Icons.schedule_outlined, label: 'Save time'),
            _HeroFeature(icon: Icons.spa_outlined, label: 'Premium service'),
          ],
        ),
      ],
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingHeroVisual extends StatelessWidget {
  const _BookingHeroVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F0E8), Color(0xFFEAD9CB)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 14,
            child: SizedBox(
              width: 170,
              height: 90,
              child: Stack(
                children: List.generate(6, (index) {
                  return Positioned(
                    left: index * 24,
                    top: index.isEven ? 10 : 0,
                    child: Transform.rotate(
                      angle: 0.45,
                      child: Container(
                        width: 20,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF889474),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 54,
            child: Container(
              width: 76,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFE7DACB),
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
          Positioned(
            left: 26,
            bottom: 44,
            child: Container(
              width: 46,
              height: 108,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 102,
            bottom: 30,
            child: Container(
              width: 214,
              height: 158,
              decoration: BoxDecoration(
                color: const Color(0xFF1F1E22),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'My',
                      style: GoogleFonts.parisienne(
                        fontSize: 28,
                        color: const Color(0xFFD8B4A4),
                      ),
                    ),
                    Text(
                      'MOBILE',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 32,
                        color: const Color(0xFFE4CCBD),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'HAIR STYLIST',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        color: const Color(0xFFD8B4A4),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 88,
            bottom: 14,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 90,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2827),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            left: 186,
            bottom: 16,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 72,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A4B33),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 14,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                width: 84,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C4C35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingProgressRow extends StatelessWidget {
  const _BookingProgressRow({
    required this.stepNumber,
    required this.totalSteps,
  });

  final int stepNumber;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final clampedStep = stepNumber.clamp(1, totalSteps);
    final checkpoints = [
      ('Choose service', clampedStep >= 1),
      ('Pick a time', clampedStep >= 5),
      ('Your details', clampedStep >= totalSteps),
    ];

    return Row(
      children: [
        for (var index = 0; index < checkpoints.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checkpoints[index].$2
                        ? const Color(0xFF232125)
                        : const Color(0xFFF3ECE5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: checkpoints[index].$2
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  checkpoints[index].$1.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (index < checkpoints.length - 1)
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFE1D3C7),
                margin: const EdgeInsets.only(bottom: 36),
              ),
            ),
        ],
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