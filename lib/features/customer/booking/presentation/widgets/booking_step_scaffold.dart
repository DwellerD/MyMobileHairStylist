import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // used by bookingErrorMessage helper
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

// ── Brand colour for the booking flow ──────────────────────────────────────
Color get _kPrimary => AppColors.primary;
Color get _kHeroBg => AppColors.showcaseSurfaceSoft;
Color get _kDivider => AppColors.showcaseBorderPale;
Color get _kTextDark => AppColors.textPrimary;
Color get _kTextMid => AppColors.textSecondary;
Color get _kPlaceholder => AppColors.showcaseSurfaceAlt;

// ── Public error-message helper used by booking screens ────────────────────
String? bookingErrorMessage(AsyncValue<dynamic> asyncValue) {
  if (!asyncValue.hasError) return null;
  return asyncValue.asError!.error.toString().replaceFirst('Exception: ', '');
}

// ─────────────────────────────────────────────────────────────────────────────
/// Shared scaffold used by every booking-flow step.
///
/// [displayStep] drives the 6-segment visual stepper:
///   1 = Who   2 = Services   3 = Date & Time   4 = Stylist
///   5 = Details   6 = Review
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
      backgroundColor: AppColors.onPrimary,
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
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 120),
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
      backgroundColor: AppColors.onPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new,
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
        preferredSize: Size.fromHeight(1),
        child: Container(height: 1, color: _kDivider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking progress stepper
// ─────────────────────────────────────────────────────────────────────────────
class _BookingStepper extends StatelessWidget {
  const _BookingStepper({required this.displayStep});

  final int displayStep;

  static const _steps = [
    (Icons.people_outline,             'Who'),
    (Icons.content_cut,                'Services'),
    (Icons.calendar_today_outlined,    'Date/Time'),
    (Icons.person_outline,             'Stylist'),
    (Icons.home_outlined,              'Details'),
    (Icons.check_circle_outline,       'Review'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.onPrimary,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                  padding: EdgeInsets.only(top: 17),
                  child: Container(
                    height: 2,
                    color: i < displayStep - 1
                        ? _kPrimary
                        : AppColors.border,
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
        (isActive || isCompleted) ? _kPrimary : AppColors.onPrimary;
    final Color borderColor =
        (isActive || isCompleted) ? _kPrimary : AppColors.border;
    final Color iconColor =
        (isActive || isCompleted) ? AppColors.onPrimary : AppColors.textMuted;
    final Color labelColor =
        isActive ? _kPrimary : AppColors.textMuted;

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
                  ? Icon(Icons.check, color: AppColors.onPrimary, size: 16)
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary,
                  ),
                  child: Center(
                    child: Text(
                      '$stepIndex',
                      style: GoogleFonts.manrope(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimary),
                    ),
                  ),
                ),
              ),
          ],
        ), SizedBox(height: 5),
        SizedBox(
          width: 48,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 8,
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                ), SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
                    height: 1.2,
                  ),
                ), SizedBox(height: 6),
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
          ), SizedBox(width: 14), _HeroImagePlaceholders(),
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Row(
          children: [Icon(Icons.error_outline,
                color: _kPrimary, size: 20), SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textPrimary),
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
        backgroundColor: enabled ? _kPrimary : AppColors.borderStrong,
        disabledBackgroundColor: AppColors.borderStrong,
        foregroundColor: AppColors.onPrimary,
        disabledForegroundColor: AppColors.onPrimary,
        minimumSize: Size.fromHeight(52),
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
          ), SizedBox(width: 8),
          if (!isBusy)
            Icon(Icons.arrow_forward, size: 20, color: AppColors.onPrimary),
          if (isBusy)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimary,
              ),
            ),
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
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
                    ), SizedBox(width: 8),
                    Expanded(child: primaryButton),
                  ],
                )
              : primaryButton,
        ),
      ),
    );
  }
}

