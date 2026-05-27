import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // used by bookingErrorMessage helper
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand colour for the booking flow ──────────────────────────────────────
const Color _kPrimary   = Color(0xFF8B3838);
const Color _kHeroBg    = Color(0xFFF5EDE4);
const Color _kDivider   = Color(0xFFEEE8E2);
const Color _kTextDark  = Color(0xFF1A1212);
const Color _kTextMid   = Color(0xFF6B6260);
const Color _kPlaceholder = Color(0xFFDDD6CE);

// ── Public error-message helper used by booking screens ────────────────────
String? bookingErrorMessage(AsyncValue<dynamic> asyncValue) {
  if (!asyncValue.hasError) return null;
  return asyncValue.asError!.error.toString().replaceFirst('Exception: ', '');
}

// ─────────────────────────────────────────────────────────────────────────────
/// Shared scaffold used by every booking-flow step.
///
/// [displayStep] drives the 5-segment visual stepper:
///   1 = Who   2 = Services   3 = Date & Time   4 = Details   5 = Review
// ─────────────────────────────────────────────────────────────────────────────
class BookingStepScaffold extends StatelessWidget {
  const BookingStepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.heroWidget,
    this.displayStep = 1,
    // legacy params kept for compatibility with existing step screens
    this.stepNumber = 1,
    this.totalSteps = 9,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.primaryIcon,
    this.isBusy = false,
    this.errorMessage,
    this.showProgress = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? heroWidget;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final int displayStep;
  final int stepNumber;
  final int totalSteps;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData? primaryIcon;
  final bool isBusy;
  final String? errorMessage;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showProgress) _BookingStepper(displayStep: displayStep),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _BookingHeroStrip(
                  title: title,
                  subtitle: subtitle,
                  displayStep: displayStep,
                  heroWidget: heroWidget,
                ),
                if (errorMessage != null) _ErrorBanner(message: errorMessage!),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ContinueBar(
        label: primaryLabel,
        onPressed: isBusy ? null : onPrimaryPressed,
        isBusy: isBusy,
        secondaryLabel: secondaryLabel,
        onSecondaryPressed: onSecondaryPressed,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 20, color: _kTextDark),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/customer/home'),
      ),
      centerTitle: true,
      title: Text(
        'Book Appointment',
        style: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _kTextDark,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kDivider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4-step progress stepper
// ─────────────────────────────────────────────────────────────────────────────
class _BookingStepper extends StatelessWidget {
  const _BookingStepper({required this.displayStep});

  final int displayStep;

  static const _steps = [
    (Icons.people_outline,             'Who'),
    (Icons.content_cut,                'Services'),
    (Icons.calendar_today_outlined,    'Date & Time'),
    (Icons.home_outlined,              'Details'),
    (Icons.check_circle_outline,       'Review'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            _StepItem(
              icon: _steps[i].$1,
              label: _steps[i].$2,
              stepIndex: i + 1,
              isActive: i == displayStep - 1,
              isCompleted: i < displayStep - 1,
            ),
            if (i < _steps.length - 1)
              Expanded(
                child: Padding(
                  // 17 = half of 34px circle, aligns line to circle centre
                  padding: const EdgeInsets.only(top: 17),
                  child: Container(
                    height: 2,
                    color: i < displayStep - 1
                        ? _kPrimary
                        : const Color(0xFFE2DAD4),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.icon,
    required this.label,
    required this.stepIndex,
    required this.isActive,
    required this.isCompleted,
  });

  final IconData icon;
  final String label;
  final int stepIndex;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final Color circleColor =
        (isActive || isCompleted) ? _kPrimary : Colors.white;
    final Color borderColor =
        (isActive || isCompleted) ? _kPrimary : const Color(0xFFD0C8C0);
    final Color iconColor =
        (isActive || isCompleted) ? Colors.white : const Color(0xFFB0A8A0);
    final Color labelColor =
        isActive ? _kPrimary : const Color(0xFFB0A8A0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Icon(icon, color: iconColor, size: 16),
              ),
            ),
            if (isActive)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary,
                  ),
                  child: Center(
                    child: Text(
                      '$stepIndex',
                      style: GoogleFonts.manrope(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              color: labelColor,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero strip
// ─────────────────────────────────────────────────────────────────────────────
class _BookingHeroStrip extends StatelessWidget {
  const _BookingHeroStrip({
    required this.title,
    required this.subtitle,
    required this.displayStep,
    this.heroWidget,
  });

  final String title;
  final String subtitle;
  final int displayStep;
  final Widget? heroWidget;

  @override
  Widget build(BuildContext context) {
    if (heroWidget != null) {
      return heroWidget!;
    }
    return Container(
      color: _kHeroBg,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'STEP $displayStep OF 5',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: _kTextMid,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const _HeroImagePlaceholders(),
        ],
      ),
    );
  }
}

/// Right-side placeholder area for booking step artwork.
class _HeroImagePlaceholders extends StatelessWidget {
  const _HeroImagePlaceholders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 110,
      decoration: BoxDecoration(
        color: _kPlaceholder,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEECCCC)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: _kPrimary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: const Color(0xFF6B2020)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky bottom CONTINUE bar
// ─────────────────────────────────────────────────────────────────────────────
class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.label,
    required this.onPressed,
    required this.isBusy,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final primaryButton = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: enabled ? _kPrimary : const Color(0xFFCEC9C5),
        disabledBackgroundColor: const Color(0xFFCEC9C5),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            child: Text(
              isBusy ? 'Working...' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          if (!isBusy)
            const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
          if (isBusy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kDivider)),
        ),
        child: SizedBox(
          height: 52,
          child: secondaryLabel != null
              ? Row(
                  children: [
                    TextButton(
                      onPressed: onSecondaryPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: _kTextMid,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(secondaryLabel!),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: primaryButton),
                  ],
                )
              : primaryButton,
        ),
      ),
    );
  }
}

