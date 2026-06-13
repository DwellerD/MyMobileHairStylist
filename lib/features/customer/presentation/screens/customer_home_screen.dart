import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

Color _themePrimary(BuildContext context) =>
  Theme.of(context).colorScheme.primary;
Color _themeAccent(BuildContext context) =>
  Theme.of(context).colorScheme.secondary;
Color _themeOnPrimary(BuildContext context) =>
  Theme.of(context).colorScheme.onPrimary;
Color _themeTextPrimary(BuildContext context) =>
  Theme.of(context).colorScheme.onSurface;
Color _themeTextSecondary(BuildContext context) =>
  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);
Color _themeTextMuted(BuildContext context) =>
  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);
Color _themeBorder(BuildContext context) =>
  Theme.of(context).colorScheme.outline;
Color _themeSurface(BuildContext context) =>
  Theme.of(context).colorScheme.surface;
Color _themeSurfaceAlt(BuildContext context) =>
  Theme.of(context).colorScheme.secondaryContainer;
Color _themeSurfaceSoft(BuildContext context) =>
  Color.lerp(_themeSurface(context), _themeSurfaceAlt(context), 0.55) ??
  _themeSurfaceAlt(context);
Color _themeSurfaceBase(BuildContext context) =>
  Color.lerp(_themeSurface(context), Colors.white, 0.08) ??
  _themeSurface(context);
Color _themeSurfaceWarm(BuildContext context) =>
  Color.lerp(_themeSurface(context), _themeSurfaceAlt(context), 0.38) ??
  _themeSurfaceAlt(context);
Color _themeGradientGalleryEnd(BuildContext context) =>
  Color.lerp(_themeSurfaceAlt(context), _themeSurface(context), 0.3) ??
  _themeSurfaceAlt(context);

/// Customer-facing marketing home screen.
///
/// Mobile-first, conversion-focused layout. All CTA buttons navigate
/// into the existing booking flow via [context.go('/customer/book')].
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        _HeroSection(),
        _HowItWorksSection(),
        _FeaturedServicesSection(),
        _MobileServiceNoteSection(),
        _TrustSection(),
        _FinalCtaSection(),
        _Footer(),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionWrapper extends StatelessWidget {
  const _SectionWrapper({
    required this.child,
    this.color,
    this.padding,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 980 ? 64.0 : 24.0;

    return Container(
      color: color ?? Theme.of(context).colorScheme.surface,
      width: double.infinity,
      padding: padding ??
          EdgeInsets.symmetric(horizontal: hPad, vertical: 56),
      child: child,
    );
  }
}

class _MaxWidth extends StatelessWidget {
  const _MaxWidth({required this.child, this.max = 1060});

  final Widget child;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}

class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
        color: _themeAccent(context),
      ),
    );
  }
}

class _HeadingText extends StatelessWidget {
  const _HeadingText(this.text, {this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.cormorantGaramond(
        fontSize: wide ? 48 : 36,
        height: 1.08,
        fontWeight: FontWeight.w600,
        color: _themeTextPrimary(context),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text, {this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.manrope(
        fontSize: 15,
        height: 1.75,
        color: _themeTextSecondary(context),
      ),
    );
  }
}

class _BookNowButton extends StatelessWidget {
  const _BookNowButton({required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => context.go('/customer/book'),
      style: FilledButton.styleFrom(
        backgroundColor: _themePrimary(context),
        foregroundColor: _themeOnPrimary(context),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 36 : 24,
          vertical: large ? 18 : 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: GoogleFonts.manrope(
          fontSize: large ? 16 : 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      child: Text(label),
    );
  }
}

class _OutlinedLinkButton extends StatelessWidget {
  const _OutlinedLinkButton({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.go(route),
      style: OutlinedButton.styleFrom(
        foregroundColor: _themePrimary(context),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: _themeBorder(context), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}

// ─── 1. Hero section ──────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 780;

    return _SectionWrapper(
      color: _themeSurfaceBase(context),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width >= 980 ? 64 : 24,
        vertical: 72,
      ),
      child: _MaxWidth(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(flex: 5, child: _HeroCopy()),
                  const SizedBox(width: 48),
                  Expanded(flex: 4, child: _HeroVisual()),
                ],
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroCopy(),
                  SizedBox(height: 40),
                  _HeroVisual(),
                ],
              ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 780;

    return Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _themeSurfaceSoft(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _themeBorder(context)),
          ),
          child: Text(
            'In-home hair appointments',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _themeTextSecondary(context),
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Hair appointments\nat your home.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: wide ? 58 : 44,
            height: 1.05,
            fontWeight: FontWeight.w600,
            color: _themeTextPrimary(context),
          ),
        ),
        const SizedBox(height: 18),
        _BodyText(
          'Professional hair services brought directly to your home, hotel, workplace, or event location.',
          center: !wide,
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _BookNowButton(label: 'Book an Appointment', large: true),
            _OutlinedLinkButton(
              label: 'View Services',
              route: '/customer/appointments',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );
  }
}

// ─── 3. How it works ──────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = [
    (
      icon: Icons.spa_outlined,
      number: '01',
      title: 'Choose your service',
      body:
          'Pick the appointment type that fits your needs from our menu of professional hair services.',
    ),
    (
      icon: Icons.home_outlined,
      number: '02',
      title: 'Select your location',
      body:
          "Tell us where you'd like your stylist to come \u2014 home, hotel, workplace, or event venue.",
    ),
    (
      icon: Icons.favorite_border,
      number: '03',
      title: 'Relax at home',
      body:
          'Your stylist arrives with everything needed for a full salon-quality experience.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return _SectionWrapper(
      color: _themeSurface(context),
      child: _MaxWidth(
        child: Column(
          children: [
            const _EyebrowLabel('How it works'),
            const SizedBox(height: 12),
            _HeadingText('Three easy steps.', center: true),
            const SizedBox(height: 40),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _steps
                    .map((s) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: _StepCard(
                              icon: s.icon,
                              number: s.number,
                              title: s.title,
                              body: s.body,
                            ),
                          ),
                        ))
                    .toList(),
              )
            else
              Column(
                children: _steps
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StepCard(
                            icon: s.icon,
                            number: s.number,
                            title: s.title,
                            body: s.body,
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.number,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _themeSurfaceBase(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _themeBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _themeSurfaceSoft(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _themePrimary(context), size: 20),
              ),
              const Spacer(),
              Text(
                number,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: _themeBorder(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _themeTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.65,
              color: _themeTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 4. Featured services ─────────────────────────────────────────────────────

class _FeaturedServicesSection extends StatelessWidget {
  const _FeaturedServicesSection();

  static const _services = [
    (
      title: 'Haircut & Style',
      price: r'From $85',
      description:
          'A precision cut tailored to your face shape, hair type, and lifestyle goals.',
      icon: Icons.content_cut_outlined,
    ),
    (
      title: 'Blowout',
      price: r'From $75',
      description:
          'Smooth, polished blowout for events, special occasions, or everyday luxury.',
      icon: Icons.air_outlined,
    ),
    (
      title: 'Formal Styling',
      price: r'From $95',
      description:
          'Elegant updo and finishing styles for galas, dinners, or any formal event.',
      icon: Icons.auto_awesome_outlined,
    ),
    (
      title: 'Bridal / Event Hair',
      price: r'From $150',
      description:
          'Full bridal or event preparation \u2014 trials available, on-location services included.',
      icon: Icons.favorite_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return _SectionWrapper(
      color: _themeSurfaceWarm(context),
      child: _MaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _EyebrowLabel('What we offer'),
            const SizedBox(height: 12),
            const _HeadingText('Featured services.'),
            const SizedBox(height: 8),
            _BodyText(
              'A few of our most popular in-home appointments. Start booking to see the full menu.',
            ),
            const SizedBox(height: 36),
            if (width >= 640)
              _TwoColGrid(
                children: _services
                    .map((s) => _ServiceCard(
                          title: s.title,
                          price: s.price,
                          description: s.description,
                          icon: s.icon,
                        ))
                    .toList(),
              )
            else
              Column(
                children: _services
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ServiceCard(
                            title: s.title,
                            price: s.price,
                            description: s.description,
                            icon: s.icon,
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TwoColGrid extends StatelessWidget {
  const _TwoColGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: 16),
            Expanded(
              child: i + 1 < children.length
                  ? children[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < children.length) rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.price,
    required this.description,
    required this.icon,
  });

  final String title;
  final String price;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _themeSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _themeBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _themeSurfaceAlt(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _themePrimary(context), size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _themeSurfaceSoft(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  price,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _themePrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _themeTextPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.6,
              color: _themeTextSecondary(context),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/customer/book'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _themePrimary(context),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(color: _themeBorder(context)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Book This'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 5. Mobile service note ───────────────────────────────────────────────────

class _MobileServiceNoteSection extends StatelessWidget {
  const _MobileServiceNoteSection();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      color: _themeSurface(context),
      child: _MaxWidth(
        max: 720,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _themeSurfaceSoft(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.directions_car_outlined,
                color: _themePrimary(context),
                size: 26,
              ),
            ),
            const SizedBox(height: 20),
            _HeadingText('We come to you.', center: true),
            const SizedBox(height: 14),
            _BodyText(
              'My Mobile Hair Stylist comes to you, making it easier to get salon-quality hair services without leaving your home.',
              center: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: _themeSurfaceBase(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _themeBorder(context)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: _themeTextMuted(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Travel fees and final availability may vary by location and will be confirmed before your appointment.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        height: 1.55,
                        color: _themeTextSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 6. Trust section ────────────────────────────────────────────────────────

class _TrustSection extends StatelessWidget {
  const _TrustSection();

  static const _points = [
    (
      icon: Icons.verified_outlined,
      title: 'Professional hair services',
      body:
          'Experienced stylists delivering skilled, personalized results every visit.',
    ),
    (
      icon: Icons.home_outlined,
      title: 'Convenient in-home appointments',
      body:
          'Skip the commute. Your appointment comes to wherever you are most comfortable.',
    ),
    (
      icon: Icons.clean_hands_outlined,
      title: 'Clean tools and quality products',
      body:
          'Every appointment uses sanitized tools and professional-grade products.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return _SectionWrapper(
      color: _themeSurfaceWarm(context),
      child: _MaxWidth(
        child: Column(
          children: [
            const _EyebrowLabel('Why choose us'),
            const SizedBox(height: 12),
            _HeadingText('Built around your comfort.', center: true),
            const SizedBox(height: 40),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _points
                    .map(
                      (p) => Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          child: _TrustPoint(
                            icon: p.icon,
                            title: p.title,
                            body: p.body,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Column(
                children: _points
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _TrustPoint(
                          icon: p.icon,
                          title: p.title,
                          body: p.body,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _themeSurfaceAlt(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: _themePrimary(context), size: 22),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _themeTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            height: 1.65,
            color: _themeTextSecondary(context),
          ),
        ),
      ],
    );
  }
}

// ─── 7. Final CTA ─────────────────────────────────────────────────────────────

class _FinalCtaSection extends StatelessWidget {
  const _FinalCtaSection();

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      color: _themeSurface(context),
      child: _MaxWidth(
        max: 680,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _themeSurfaceBase(context),
                _themeGradientGalleryEnd(context),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _themeBorder(context)),
          ),
          child: Column(
            children: [
              _HeadingText(
                'Ready to book your appointment?',
                center: true,
              ),
              const SizedBox(height: 16),
              _BodyText(
                "Request your preferred service, date, time, and location. We'll confirm availability and details before your appointment.",
                center: true,
              ),
              const SizedBox(height: 32),
              _BookNowButton(label: 'Start Booking', large: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _themeTextPrimary(context),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: Text(
          '\u00A9 ${DateTime.now().year} My Mobile Hair Stylist. All rights reserved.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
