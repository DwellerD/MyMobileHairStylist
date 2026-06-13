import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// First screen shown to unauthenticated users.
///
/// In the real product this will become the polished marketing-style entry
/// point before users log in or create an account.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _servicesKey = GlobalKey();

  Future<void> _scrollToSection(GlobalKey key) async {
    final sectionContext = key.currentContext;
    if (sectionContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      sectionContext,
      duration: Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 760;
    final maxContentWidth = isDesktop ? 1320.0 : 1100.0;
    final pagePadding = width >= 900 ? 28.0 : 16.0;

    final headlineStyle = GoogleFonts.cormorantGaramond(
      fontSize: isDesktop ? 70 : isTablet ? 58 : 42,
      height: 0.95,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.4,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.showcaseGradientStart,
              AppColors.showcaseGradientMid,
              AppColors.showcaseGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.showcasePanel,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.showcaseBorderWarm),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.showcaseShadowSoft,
                        blurRadius: 32,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 34 : 20,
                          isDesktop ? 26 : 18,
                          isDesktop ? 34 : 20,
                          0,
                        ),
                        child: _TopBar(
                          isDesktop: isDesktop,
                          onServicesTap: () => _scrollToSection(_servicesKey),
                          onBookNowTap: () => context.go('/signup'),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 34 : 20,
                          18,
                          isDesktop ? 34 : 20,
                          20,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.showcaseSurfaceBase, AppColors.showcaseGradientSoftEnd],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isDesktop ? 34 : 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Flex(
                                  direction:
                                      isDesktop ? Axis.horizontal : Axis.vertical,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isDesktop)
                                      Expanded(
                                        flex: 11,
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 28),
                                          child: _HeroCopy(
                                            headlineStyle: headlineStyle,
                                            isTablet: isTablet,
                                            onBookNow: () => context.go('/signup'),
                                            onViewServices: () => _scrollToSection(_servicesKey),
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 24),
                                        child: _HeroCopy(
                                          headlineStyle: headlineStyle,
                                          isTablet: isTablet,
                                          onBookNow: () => context.go('/signup'),
                                          onViewServices: () => _scrollToSection(_servicesKey),
                                        ),
                                      ),
                                    if (isDesktop)
                                      Expanded(
                                        flex: 10,
                                        child: _HeroVisual(isTablet: isTablet),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                  ],
                                ),
                                if (isDesktop) ...[SizedBox(height: 24),
                                  Container(
                                    key: _servicesKey,
                                    padding: EdgeInsets.all(isDesktop ? 24 : 18),
                                    decoration: BoxDecoration(
                                      color: AppColors.showcaseGlass,
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: AppColors.showcaseBorderLight,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _LandingSection(
                                          eyebrow: 'How it works',
                                          title: 'Simple booking in three steps.',
                                          child: _HowItWorksSimple(),
                                        ),
                                        SizedBox(height: 20),
                                        _LandingSection(
                                          eyebrow: 'Services',
                                          title: 'Book for any location and occasion.',
                                          child: _ServiceCategoryTeaser(),
                                        ),
                                        SizedBox(height: 20),
                                        _FinalBookingCta(),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isDesktop,
    required this.onServicesTap,
    required this.onBookNowTap,
  });

  final bool isDesktop;
  final VoidCallback onServicesTap;
  final VoidCallback onBookNowTap;

  @override
  Widget build(BuildContext context) {
    final bookNowButton = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 180),
      child: FilledButton(
        onPressed: onBookNowTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onPrimary,
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        ),
        child: Text('BOOK NOW'),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _BrandLockup(isCompact: !isDesktop)),
        if (isDesktop)
          Wrap(
            spacing: 4,
            children: [
              _HeaderLink(label: 'SERVICES', onTap: onServicesTap),
              _HeaderLink(label: 'BOOKING', onTap: onBookNowTap),
            ],
          ), SizedBox(width: 14),
        Flexible(
          fit: FlexFit.loose,
          child: Align(
            alignment: Alignment.centerRight,
            child: bookNowButton,
          ),
        ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 110 : 130,
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          alignment: Alignment.topLeft,
        ),
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _MutedPill extends StatelessWidget {
  const _MutedPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.showcaseCardSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.showcaseBorderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent), SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.showcaseSurfaceIvory,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.showcaseBorderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary), SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isTablet ? 430 : 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.showcaseGradientWarmStart, AppColors.showcaseGradientWarmEnd],
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 1.0,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String step;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            step,
            style: GoogleFonts.parisienne(
              fontSize: 38,
              color: AppColors.showcaseAccentSoft,
            ),
          ), SizedBox(height: 6),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.showcaseCardWarm,
              border: Border.all(color: AppColors.showcaseBorderMuted),
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ), SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.textPrimary,
            ),
          ), SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingSection extends StatelessWidget {
  const _LandingSection({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            color: AppColors.accent,
          ),
        ), SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.05,
            color: AppColors.textPrimary,
          ),
        ), SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _HowItWorksSimple extends StatelessWidget {
  const _HowItWorksSimple();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final cards = [
      _HowStepCard(
        step: '01',
        title: 'Choose your service',
        body: 'Select the haircut, styling, color, or event service you need.',
      ),
      _HowStepCard(
        step: '02',
        title: 'Pick your date and location',
        body: 'Choose from available appointment times and tell us where to come.',
      ),
      _HowStepCard(
        step: '03',
        title: 'We confirm the appointment',
        body: 'Your request is reviewed and confirmed before your stylist arrives.',
      ),
    ];

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 14),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i < cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HowStepCard extends StatelessWidget {
  const _HowStepCard({
    required this.step,
    required this.title,
    required this.body,
  });

  final String step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.showcaseSurfaceBase,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.showcaseBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: GoogleFonts.manrope(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ), SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ), SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCategoryTeaser extends StatelessWidget {
  const _ServiceCategoryTeaser();

  @override
  Widget build(BuildContext context) {
    const categories = [
      'Women',
      'Men',
      'Kids',
      'Hair Color',
      'Add-ons',
      'Wedding / Special Events',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final category in categories)
          ActionChip(
            onPressed: () => context.go('/signup'),
            label: Text(category),
            backgroundColor: AppColors.showcaseSurfaceIvory,
            side: BorderSide(color: AppColors.showcaseBorderLight),
            labelStyle: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}

class _FinalBookingCta extends StatelessWidget {
  const _FinalBookingCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.showcaseSurfaceHighlight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.showcaseBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to book your appointment?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ), SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/signup'),
              child: Text('Start Booking'),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _PrepBoard extends StatelessWidget {
  const _PrepBoard({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        color: AppColors.showcaseSurfaceHighlight,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.showcaseBorderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.showcaseShadowSubtle,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                const Expanded(
                  child: _UploadPanel(
                    title: '1. Upload photos of your hair',
                    subtitle: 'Add clear photos in natural light.',
                    footer: [
                      _MiniTag(label: 'Front'),
                      _MiniTag(label: 'Back'),
                      _MiniTag(label: 'Left side'),
                      _MiniTag(label: 'Right side'),
                    ],
                  ),
                )
              else
                const _UploadPanel(
                  title: '1. Upload photos of your hair',
                  subtitle: 'Add clear photos in natural light.',
                  footer: [
                    _MiniTag(label: 'Front'),
                    _MiniTag(label: 'Back'),
                    _MiniTag(label: 'Left side'),
                    _MiniTag(label: 'Right side'),
                  ],
                ),
              SizedBox(width: isDesktop ? 18 : 0, height: isDesktop ? 0 : 18),
              if (isDesktop)
                const Expanded(
                  child: _UploadPanel(
                    title: '2. Add inspiration photos',
                    subtitle: 'Upload styles, cuts, or colours you love.',
                    footer: [
                      _ReferenceThumb(tone: Color(0xFF8B664E)),
                      _ReferenceThumb(tone: Color(0xFFAA7A5B)),
                      _ReferenceThumb(tone: Color(0xFF6B5344)),
                      _ReferenceThumb(tone: Color(0xFFB48B6A)),
                    ],
                  ),
                )
              else
                const _UploadPanel(
                  title: '2. Add inspiration photos',
                  subtitle: 'Upload styles, cuts, or colours you love.',
                  footer: [
                    _ReferenceThumb(tone: Color(0xFF8B664E)),
                    _ReferenceThumb(tone: Color(0xFFAA7A5B)),
                    _ReferenceThumb(tone: Color(0xFF6B5344)),
                    _ReferenceThumb(tone: Color(0xFFB48B6A)),
                  ],
                ),
            ],
          ), SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '3. Tell me more',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ), SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'The more details you share, the better I can tailor your look.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ), SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _FieldMock(label: 'What are you looking to do?', hint: 'Select an option'),
              _FieldMock(label: 'What do you love about your hair?', hint: 'e.g. length, colour, texture...'),
              _FieldMock(label: 'What would you like to change?', hint: 'e.g. lighter, softer, more layers...'),
              _FieldMock(label: 'Any dislikes or things to avoid?', hint: 'e.g. brassy tones, too short, bulk...'),
              _FieldMock(label: 'Any other notes for me?', hint: 'Share anything else I should know...'),
            ],
          ), SizedBox(height: 22),
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            children: [
              if (isDesktop)
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.showcaseChipBackground,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.showcaseChipBorder),
                          ),
                          child: Icon(Icons.favorite_border, color: AppColors.accent),
                        ), SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your comfort, your style',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ), SizedBox(height: 4),
                              Text(
                                'This helps me prepare everything I need so you get the best in-home salon experience.',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.showcaseChipBackground,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.showcaseChipBorder),
                        ),
                        child: Icon(Icons.favorite_border, color: AppColors.accent),
                      ), SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your comfort, your style',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ), SizedBox(height: 4),
                            Text(
                              'This helps me prepare everything I need so you get the best in-home salon experience.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(width: isDesktop ? 18 : 0, height: isDesktop ? 0 : 18),
              if (isDesktop)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/signup'),
                    icon: Icon(Icons.favorite),
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text('SUBMIT MY PHOTOS & DETAILS'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.showcaseDarkSurface,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () => context.go('/signup'),
                  icon: Icon(Icons.favorite),
                  label: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text('SUBMIT MY PHOTOS & DETAILS'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.showcaseDarkSurface,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({
    required this.title,
    required this.subtitle,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.showcaseBorderPale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ), SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
          ), SizedBox(height: 14),
          Container(
            height: 146,
            decoration: BoxDecoration(
              color: AppColors.showcaseSurfaceBase,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.showcaseBorderPaleAlt,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 34, color: AppColors.accent), SizedBox(height: 10),
                  Text(
                    'DRAG & DROP YOUR PHOTOS HERE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ), SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: Text('CHOOSE FILES'),
                  ),
                ],
              ),
            ),
          ), SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: footer),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.showcaseSurfaceBaseAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.showcaseBorderPaleSoft),
      ),
      child: Column(
        children: [
          Icon(Icons.face_retouching_natural_outlined, color: AppColors.textMuted), SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceThumb extends StatelessWidget {
  const _ReferenceThumb({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tone, AppColors.showcaseGradientMist],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 64,
          height: 76,
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.showcaseCanvasWarm,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
              bottom: Radius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldMock extends StatelessWidget {
  const _FieldMock({required this.label, required this.hint});

  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ), SizedBox(height: 8),
          Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.showcaseSurfaceBaseAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.showcaseBorderPaleSoftAlt),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _GalleryStrip extends StatelessWidget {
  const _GalleryStrip({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.showcaseSurfaceBaseAlt,
            AppColors.showcaseGradientCream,
          ],
        ),
        border: Border.all(color: AppColors.showcaseBorderLight),
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            const Expanded(
              flex: 7,
              child: _GalleryCards(),
            )
          else
            const _GalleryCards(),
          SizedBox(width: isDesktop ? 22 : 0, height: isDesktop ? 0 : 22),
          if (isDesktop)
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.showcaseSurfaceBaseAlt,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visual direction',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ), SizedBox(height: 10),
                    Text(
                      'Because I could not directly extract the original screenshot assets, this version uses soft illustration-style placeholders and warm tonal blocks that can be swapped for real brand photos later.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textSecondary,
                      ),
                    ), SizedBox(height: 18), _BulletPoint(text: 'Warm ivory, sand, blush, cocoa, and soft black remain the anchor colors.'), _BulletPoint(text: 'Typography leans editorial with a serif headline and script accent.'), _BulletPoint(text: 'Cards and mock fields are intentionally quiet so future photography can take over.'),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.showcaseSurfaceBaseAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visual direction',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ), SizedBox(height: 10),
                  Text(
                    'Because I could not directly extract the original screenshot assets, this version uses soft illustration-style placeholders and warm tonal blocks that can be swapped for real brand photos later.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ), SizedBox(height: 18), _BulletPoint(text: 'Warm ivory, sand, blush, cocoa, and soft black remain the anchor colors.'), _BulletPoint(text: 'Typography leans editorial with a serif headline and script accent.'), _BulletPoint(text: 'Cards and mock fields are intentionally quiet so future photography can take over.'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.headlineStyle,
    required this.isTablet,
    required this.onBookNow,
    required this.onViewServices,
  });

  final TextStyle headlineStyle;
  final bool isTablet;
  final VoidCallback onBookNow;
  final VoidCallback onViewServices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_MutedPill(
          icon: Icons.home_outlined,
          label: 'In-home hair appointments',
        ), SizedBox(height: 22),
        Text('Hair appointments\nat your home.', style: headlineStyle), SizedBox(height: 14),
        Text(
          'Professional hair services brought directly to your home, hotel, workplace, or event location.',
          style: GoogleFonts.manrope(
            fontSize: isTablet ? 18 : 16,
            height: 1.65,
            color: AppColors.textSecondary,
          ),
        ), SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onBookNow,
              icon: Icon(Icons.calendar_month_outlined),
              label: Text('Book an Appointment'),
            ),
            OutlinedButton.icon(
              onPressed: onViewServices,
              icon: Icon(Icons.design_services_outlined),
              label: Text('View Services'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: Icon(Icons.login),
              label: Text('Log In'),
            ),
          ],
        ), SizedBox(height: 14),
        TextButton.icon(
          onPressed: () => context.go('/stylist/portal'),
          icon: Icon(Icons.content_cut_outlined),
          label: Text('Stylist Portal'),
        ), SizedBox(height: 10), Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(label: 'In-home appointments', icon: Icons.home_outlined),
            _StatPill(label: 'Professional stylists', icon: Icons.verified_outlined),
            _StatPill(label: 'Simple booking', icon: Icons.check_circle_outline),
          ],
        ),
      ],
    );
  }
}

class _GalleryCards extends StatelessWidget {
  const _GalleryCards();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _GalleryPhotoCard(title: 'Soft layers', tone: Color(0xFFB18767)),
        _GalleryPhotoCard(title: 'Warm dimension', tone: Color(0xFF7C624C)),
        _GalleryPhotoCard(title: 'Lived-in blonde', tone: Color(0xFFC4A07B)),
        _GalleryPhotoCard(title: 'Elegant upstyle', tone: Color(0xFF8A6856)),
      ],
    );
  }
}

class _GalleryPhotoCard extends StatelessWidget {
  const _GalleryPhotoCard({required this.title, required this.tone});

  final String title;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 214,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tone, AppColors.showcaseGradientGalleryEnd],
              ),
            ),
            child: Center(
              child: Container(
                width: 118,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.showcaseCanvasWarmSoft,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(60),
                    bottom: Radius.circular(24),
                  ),
                ),
              ),
            ),
          ), SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ), SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AboutBand extends StatelessWidget {
  const _AboutBand({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.showcaseBorderLight),
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips for the best photos',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ), SizedBox(height: 12), _BulletPoint(text: 'Use natural lighting and avoid harsh overhead shadows.'), _BulletPoint(text: 'Keep filters off so colour and texture stay accurate.'), _BulletPoint(text: 'Show your hair down and include recent salon work when possible.'),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips for the best photos',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ), SizedBox(height: 12), _BulletPoint(text: 'Use natural lighting and avoid harsh overhead shadows.'), _BulletPoint(text: 'Keep filters off so colour and texture stay accurate.'), _BulletPoint(text: 'Show your hair down and include recent salon work when possible.'),
              ],
            ),
          
          SizedBox(width: isDesktop ? 22 : 0, height: isDesktop ? 0 : 22),
          if (isDesktop)
            Expanded(
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.showcaseGradientPhotoStart, AppColors.showcaseGradientPhotoEnd],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 28,
                      bottom: 22,
                      child: Container(
                        width: 110,
                        height: 126,
                        decoration: BoxDecoration(
                          color: AppColors.showcaseAccentBronze,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(54),
                            bottom: Radius.circular(26),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 28,
                      bottom: 18,
                      child: Transform.rotate(
                        angle: -0.16,
                        child: Container(
                          width: 82,
                          height: 126,
                          decoration: BoxDecoration(
                            color: AppColors.showcaseDarkSurfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.onPrimary, width: 5),
                          ),
                          child: Center(
                            child: Icon(Icons.photo_camera_front_outlined, color: AppColors.onPrimaryMuted),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.showcaseGradientPhotoStart, AppColors.showcaseGradientPhotoEnd],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 28,
                    bottom: 22,
                    child: Container(
                      width: 110,
                      height: 126,
                      decoration: BoxDecoration(
                        color: AppColors.showcaseAccentBronze,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(54),
                          bottom: Radius.circular(26),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 28,
                    bottom: 18,
                    child: Transform.rotate(
                      angle: -0.16,
                      child: Container(
                        width: 82,
                        height: 126,
                        decoration: BoxDecoration(
                          color: AppColors.showcaseDarkSurfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.onPrimary, width: 5),
                        ),
                        child: Center(
                          child: Icon(Icons.photo_camera_front_outlined, color: AppColors.onPrimaryMuted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(width: isDesktop ? 22 : 0, height: isDesktop ? 0 : 22),
          if (isDesktop)
            Expanded(
              child: Container(
                padding: EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.showcaseSurfaceRose,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Text('Questions?'),
                      ],
                    ), SizedBox(height: 12),
                    Text(
                      'I’m here to help. Send a message anytime and I can guide you on what photos or notes will give the best result.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        height: 1.7,
                        color: AppColors.textSecondary,
                      ),
                    ), SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.go('/signup'),
                      icon: Icon(Icons.send_outlined),
                      label: Text('Message us'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.showcaseSurfaceRose,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary),
                      SizedBox(width: 10),
                      Text('Questions?'),
                    ],
                  ), SizedBox(height: 12),
                  Text(
                    'I’m here to help. Send a message anytime and I can guide you on what photos or notes will give the best result.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ), SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => context.go('/signup'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: Text('CONTACT ME'),
                  ),
                ],
              ),
            ),
          
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FooterBand extends StatelessWidget {
  const _FooterBand({
    required this.isConfigured,
    required this.onCreateAccountTap,
    required this.onDeveloperTap,
  });

  final bool isConfigured;
  final VoidCallback onCreateAccountTap;
  final VoidCallback? onDeveloperTap;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beautiful hair, wherever you are.',
          style: GoogleFonts.parisienne(
            fontSize: 34,
            color: AppColors.primary,
          ),
        ), SizedBox(height: 10),
        Text(
          AppConstants.appTagline,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        if (!isConfigured) ...[SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onDeveloperTap,
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: Text('OPEN ROLE SWITCHER'),
          ), SizedBox(height: 8),
          Text(
            AppConstants.mockAuthNote,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );

    final cta = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 320),
      child: FilledButton(
        onPressed: onCreateAccountTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        ),
        child: Text('BOOK YOUR APPOINTMENT'),
      ),
    );

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.showcaseSurfaceFooter,
        borderRadius: BorderRadius.circular(24),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details), SizedBox(width: 18),
                cta,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details, SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: cta,
                ),
              ],
            ),
    );
  }
}