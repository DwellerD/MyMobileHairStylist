import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
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
  final _bookingKey = GlobalKey();
  final _galleryKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _contactKey = GlobalKey();

  Future<void> _scrollToSection(GlobalKey key) async {
    final sectionContext = key.currentContext;
    if (sectionContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = ref.watch(supabaseConfiguredProvider);
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

    final scriptStyle = GoogleFonts.parisienne(
      fontSize: isDesktop ? 74 : isTablet ? 62 : 46,
      height: 0.95,
      color: AppColors.accent,
      fontWeight: FontWeight.w400,
    );

    final sectionTitleStyle = GoogleFonts.cormorantGaramond(
      fontSize: isDesktop ? 34 : 28,
      fontWeight: FontWeight.w600,
      height: 1.05,
      color: AppColors.textPrimary,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6EEE6),
              Color(0xFFF4E8DE),
              Color(0xFFF8F3ED),
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
                    color: const Color(0xFFFDF8F2),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFEADACB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
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
                          isDesktop: isTablet,
                          onServicesTap: () => _scrollToSection(_servicesKey),
                          onBookingTap: () => _scrollToSection(_bookingKey),
                          onGalleryTap: () => _scrollToSection(_galleryKey),
                          onAboutTap: () => _scrollToSection(_aboutKey),
                          onContactTap: () => _scrollToSection(_contactKey),
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
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFFBF7), Color(0xFFF1E5DB)],
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
                                    Expanded(
                                      flex: isDesktop ? 11 : 0,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: isDesktop ? 28 : 0,
                                          bottom: isDesktop ? 0 : 24,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _MutedPill(
                                              icon: Icons.favorite_border,
                                              label:
                                                  'Luxury in-home hair care for modern households',
                                            ),
                                            const SizedBox(height: 22),
                                            Text('HELP YOUR', style: headlineStyle),
                                            Transform.translate(
                                              offset: const Offset(0, -8),
                                              child: Text(
                                                'Stylist Prepare',
                                                style: scriptStyle,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'The more detail you share, the better I can understand your hair goals and create a plan before I arrive. This home page mirrors that calm, elevated prep experience.',
                                              style: GoogleFonts.manrope(
                                                fontSize: isTablet ? 18 : 16,
                                                height: 1.65,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 26),
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 12,
                                              children: [
                                                FilledButton.icon(
                                                  onPressed: () =>
                                                      _scrollToSection(_bookingKey),
                                                  icon: const Icon(Icons.photo_camera_outlined),
                                                  label: const Text('Start The Prep'),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () => context.go('/login'),
                                                  icon: const Icon(Icons.login),
                                                  label: const Text('Log In'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 26),
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 12,
                                              children: const [
                                                _StatPill(
                                                  label: 'Private photo upload',
                                                  icon: Icons.lock_outline,
                                                ),
                                                _StatPill(
                                                  label: 'Tailored consultation',
                                                  icon: Icons.chat_bubble_outline,
                                                ),
                                                _StatPill(
                                                  label: 'Prepared before arrival',
                                                  icon: Icons.event_available_outlined,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: isDesktop ? 10 : 0,
                                      child: _HeroVisual(isTablet: isTablet),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  key: _servicesKey,
                                  padding: EdgeInsets.all(isDesktop ? 24 : 18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xCCFFFDF9),
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: const Color(0xFFE7D8CB),
                                    ),
                                  ),
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.spaceBetween,
                                    children: const [
                                      _StepCard(
                                        step: '01',
                                        icon: Icons.photo_camera_outlined,
                                        title: 'Upload your hair',
                                        description:
                                            'Share clear photos from the front, back, and sides.',
                                      ),
                                      _StepCard(
                                        step: '02',
                                        icon: Icons.favorite_border,
                                        title: 'Add inspiration',
                                        description:
                                            'Show styles, cuts, or colours you love.',
                                      ),
                                      _StepCard(
                                        step: '03',
                                        icon: Icons.mode_comment_outlined,
                                        title: 'Tell me more',
                                        description:
                                            'Include likes, dislikes, goals, and any notes.',
                                      ),
                                      _StepCard(
                                        step: '04',
                                        icon: Icons.event_note_outlined,
                                        title: 'Arrive prepared',
                                        description:
                                            'I review everything before your appointment.',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        key: _bookingKey,
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 34 : 20,
                          0,
                          isDesktop ? 34 : 20,
                          26,
                        ),
                        child: _LandingSection(
                          title: 'A booking prep board that feels calm, personal, and high-touch.',
                          eyebrow: 'Booking preview',
                          child: _PrepBoard(isDesktop: isTablet),
                        ),
                      ),
                      Padding(
                        key: _galleryKey,
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 34 : 20,
                          0,
                          isDesktop ? 34 : 20,
                          26,
                        ),
                        child: _LandingSection(
                          title: 'Reference imagery can stay warm, polished, and human.',
                          eyebrow: 'Gallery mood',
                          titleStyle: sectionTitleStyle,
                          child: _GalleryStrip(isDesktop: isTablet),
                        ),
                      ),
                      Padding(
                        key: _aboutKey,
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 34 : 20,
                          0,
                          isDesktop ? 34 : 20,
                          26,
                        ),
                        child: _AboutBand(isDesktop: isTablet),
                      ),
                      Padding(
                        key: _contactKey,
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 34 : 20,
                          0,
                          isDesktop ? 34 : 20,
                          isDesktop ? 34 : 24,
                        ),
                        child: _FooterBand(
                          isConfigured: isConfigured,
                          onCreateAccountTap: () => context.go('/signup'),
                          onDeveloperTap: isConfigured
                              ? null
                              : () => context.go('/role-gate'),
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
    required this.onBookingTap,
    required this.onGalleryTap,
    required this.onAboutTap,
    required this.onContactTap,
    required this.onBookNowTap,
  });

  final bool isDesktop;
  final VoidCallback onServicesTap;
  final VoidCallback onBookingTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onAboutTap;
  final VoidCallback onContactTap;
  final VoidCallback onBookNowTap;

  @override
  Widget build(BuildContext context) {
    final bookNowButton = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: FilledButton(
        onPressed: onBookNowTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        ),
        child: const Text('BOOK NOW'),
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
              _HeaderLink(label: 'BOOKING', onTap: onBookingTap),
              _HeaderLink(label: 'GALLERY', onTap: onGalleryTap),
              _HeaderLink(label: 'ABOUT', onTap: onAboutTap),
              _HeaderLink(label: 'CONTACT', onTap: onContactTap),
            ],
          ),
        const SizedBox(width: 14),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'My',
          style: GoogleFonts.parisienne(
            fontSize: isCompact ? 28 : 34,
            color: AppColors.accent,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.home_work_outlined,
                    size: isCompact ? 20 : 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextSpan(
                text: 'MOBILE',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: isCompact ? 34 : 42,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Text(
          'HAIR STYLIST',
          style: GoogleFonts.manrope(
            fontSize: isCompact ? 11 : 12,
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6ECE3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8D6C8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7D8CB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F2EA), Color(0xFFE9D8CA)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 34,
            left: 34,
            child: _PlantIllustration(isLarge: isTablet),
          ),
          const Positioned(
            top: 22,
            right: 22,
            child: _MirrorAccent(),
          ),
          Positioned(
            right: isTablet ? 26 : 12,
            bottom: 24,
            child: _BagIllustration(isLarge: isTablet),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Row(
              children: const [
                _ToolAccent(width: 82),
                SizedBox(width: 10),
                _ToolAccent(width: 58),
                SizedBox(width: 10),
                _ToolAccent(width: 98),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantIllustration extends StatelessWidget {
  const _PlantIllustration({required this.isLarge});

  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isLarge ? 200 : 150,
      height: isLarge ? 240 : 180,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: isLarge ? 84 : 62,
            height: isLarge ? 132 : 92,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5EE),
              borderRadius: BorderRadius.circular(46),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
          ...List.generate(8, (index) {
            final left = index.isEven ? 60.0 + index * 10 : 24.0 + index * 10;
            final top = index.isEven ? 14.0 + index * 8 : 26.0 + index * 8;
            return Positioned(
              left: left,
              top: top,
              child: Transform.rotate(
                angle: index.isEven ? -0.55 : 0.55,
                child: Container(
                  width: isLarge ? 12 : 9,
                  height: isLarge ? 52 : 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF708A5F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MirrorAccent extends StatelessWidget {
  const _MirrorAccent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD6B497), width: 6),
        gradient: const RadialGradient(
          colors: [Color(0xFFFEFBF6), Color(0xFFE8DED3)],
        ),
      ),
    );
  }
}

class _BagIllustration extends StatelessWidget {
  const _BagIllustration({required this.isLarge});

  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final width = isLarge ? 280.0 : 200.0;
    final height = isLarge ? 212.0 : 156.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF222124),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14,
            left: 34,
            right: 34,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF444247), width: 3),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'My',
                  style: GoogleFonts.parisienne(
                    fontSize: isLarge ? 34 : 26,
                    color: const Color(0xFFD5B2A5),
                  ),
                ),
                Text(
                  'MOBILE',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isLarge ? 42 : 30,
                    color: const Color(0xFFE2C8B9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'HAIR STYLIST',
                  style: GoogleFonts.manrope(
                    fontSize: isLarge ? 11 : 9,
                    color: const Color(0xFFD5B2A5),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolAccent extends StatelessWidget {
  const _ToolAccent({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.22,
      child: Container(
        width: width,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFF43352F),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

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
              color: const Color(0xFFD6B2A2),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF8EFE7),
              border: Border.all(color: const Color(0xFFE4D4C7)),
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
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
    this.titleStyle,
  });

  final String eyebrow;
  final String title;
  final Widget child;
  final TextStyle? titleStyle;

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
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: titleStyle ?? GoogleFonts.cormorantGaramond(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.05,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _PrepBoard extends StatelessWidget {
  const _PrepBoard({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7D8CB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
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
              Expanded(
                child: _UploadPanel(
                  title: '1. Upload photos of your hair',
                  subtitle: 'Add clear photos in natural light.',
                  footer: const [
                    _MiniTag(label: 'Front'),
                    _MiniTag(label: 'Back'),
                    _MiniTag(label: 'Left side'),
                    _MiniTag(label: 'Right side'),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 18 : 0, height: isDesktop ? 0 : 18),
              Expanded(
                child: _UploadPanel(
                  title: '2. Add inspiration photos',
                  subtitle: 'Upload styles, cuts, or colours you love.',
                  footer: const [
                    _ReferenceThumb(tone: Color(0xFF8B664E)),
                    _ReferenceThumb(tone: Color(0xFFAA7A5B)),
                    _ReferenceThumb(tone: Color(0xFF6B5344)),
                    _ReferenceThumb(tone: Color(0xFFB48B6A)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
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
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'The more details you share, the better I can tailor your look.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const [
              _FieldMock(label: 'What are you looking to do?', hint: 'Select an option'),
              _FieldMock(label: 'What do you love about your hair?', hint: 'e.g. length, colour, texture...'),
              _FieldMock(label: 'What would you like to change?', hint: 'e.g. lighter, softer, more layers...'),
              _FieldMock(label: 'Any dislikes or things to avoid?', hint: 'e.g. brassy tones, too short, bulk...'),
              _FieldMock(label: 'Any other notes for me?', hint: 'Share anything else I should know...'),
            ],
          ),
          const SizedBox(height: 22),
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF1E9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD8BCAB)),
                        ),
                        child: const Icon(Icons.favorite_border, color: AppColors.accent),
                      ),
                      const SizedBox(width: 14),
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
                            ),
                            const SizedBox(height: 4),
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
              ),
              SizedBox(width: isDesktop ? 18 : 0, height: isDesktop ? 0 : 18),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/signup'),
                  icon: const Icon(Icons.favorite),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text('SUBMIT MY PHOTOS & DETAILS'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF232125),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DDD1)),
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
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Container(
            height: 146,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE1D1C5),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 34, color: AppColors.accent),
                  const SizedBox(height: 10),
                  Text(
                    'DRAG & DROP YOUR PHOTOS HERE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('CHOOSE FILES'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DACE)),
      ),
      child: Column(
        children: [
          const Icon(Icons.face_retouching_natural_outlined, color: AppColors.textMuted),
          const SizedBox(height: 6),
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
          colors: [tone, const Color(0xFFF2E8DD)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 64,
          height: 76,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F2EC),
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
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8D9CB)),
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

class _GalleryStrip extends StatelessWidget {
  const _GalleryStrip({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF8), Color(0xFFF1E4D8)],
        ),
        border: Border.all(color: const Color(0xFFE7D8CB)),
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isDesktop ? 7 : 0,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: const [
                _GalleryPhotoCard(title: 'Soft layers', tone: Color(0xFFB18767)),
                _GalleryPhotoCard(title: 'Warm dimension', tone: Color(0xFF7C624C)),
                _GalleryPhotoCard(title: 'Lived-in blonde', tone: Color(0xFFC4A07B)),
                _GalleryPhotoCard(title: 'Elegant upstyle', tone: Color(0xFF8A6856)),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 22 : 0, height: isDesktop ? 0 : 22),
          Expanded(
            flex: isDesktop ? 4 : 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF8),
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
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Because I could not directly extract the original screenshot assets, this version uses soft illustration-style placeholders and warm tonal blocks that can be swapped for real brand photos later.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _BulletPoint(text: 'Warm ivory, sand, blush, cocoa, and soft black remain the anchor colors.'),
                  const _BulletPoint(text: 'Typography leans editorial with a serif headline and script accent.'),
                  const _BulletPoint(text: 'Cards and mock fields are intentionally quiet so future photography can take over.'),
                ],
              ),
            ),
          ),
        ],
      ),
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
                colors: [tone, const Color(0xFFF3E8DE)],
              ),
            ),
            child: Center(
              child: Container(
                width: 118,
                height: 150,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F4EE),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(60),
                    bottom: Radius.circular(24),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
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

class _AboutBand extends StatelessWidget {
  const _AboutBand({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7D8CB)),
      ),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                ),
                const SizedBox(height: 12),
                const _BulletPoint(text: 'Use natural lighting and avoid harsh overhead shadows.'),
                const _BulletPoint(text: 'Keep filters off so colour and texture stay accurate.'),
                const _BulletPoint(text: 'Show your hair down and include recent salon work when possible.'),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 22 : 0, height: isDesktop ? 0 : 22),
          Expanded(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFF1E2D6), Color(0xFFF9F4ED)],
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFC79C79),
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
                          color: const Color(0xFF27252A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 5),
                        ),
                        child: const Center(
                          child: Icon(Icons.photo_camera_front_outlined, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 22 : 0, height: isDesktop ? 0 : 22),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF3EB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary),
                      SizedBox(width: 10),
                      Text('Questions?'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'I’m here to help. Send a message anytime and I can guide you on what photos or notes will give the best result.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => context.go('/signup'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('CONTACT ME'),
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
        ),
        const SizedBox(height: 10),
        Text(
          AppConstants.appTagline,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        if (!isConfigured) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onDeveloperTap,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('OPEN ROLE SWITCHER'),
          ),
          const SizedBox(height: 8),
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
      constraints: const BoxConstraints(maxWidth: 320),
      child: FilledButton(
        onPressed: onCreateAccountTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        ),
        child: const Text('BOOK YOUR APPOINTMENT'),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9DE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                const SizedBox(width: 18),
                cta,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: cta,
                ),
              ],
            ),
    );
  }
}