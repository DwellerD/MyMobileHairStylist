import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Customer dashboard placeholder.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBF7), Color(0xFFF1E4D9)],
            ),
            border: Border.all(color: const Color(0xFFE7D8CB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isWide ? 28 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _WarmPill(
                      icon: Icons.favorite_border,
                      label: 'Premium in-home hair care',
                    ),
                    _WarmPill(
                      icon: Icons.lock_outline,
                      label: 'Private prep flow',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: _HeroCopy(),
                        ),
                      ),
                      const Expanded(child: _HeroScene()),
                    ],
                  )
                else
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCopy(),
                      SizedBox(height: 20),
                      _HeroScene(),
                    ],
                  ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xCCFFFDF9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7D8CB)),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    children: const [
                      _ProcessTile(
                        step: '01',
                        icon: Icons.photo_camera_outlined,
                        title: 'Upload your hair',
                        description: 'Share clear front, back, and side photos.',
                      ),
                      _ProcessTile(
                        step: '02',
                        icon: Icons.favorite_border,
                        title: 'Add inspiration',
                        description: 'Show styles, cuts, or colour references.',
                      ),
                      _ProcessTile(
                        step: '03',
                        icon: Icons.chat_bubble_outline,
                        title: 'Tell me more',
                        description: 'Include your goals, likes, and dislikes.',
                      ),
                      _ProcessTile(
                        step: '04',
                        icon: Icons.event_available_outlined,
                        title: 'I come prepared',
                        description: 'Everything gets reviewed before arrival.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _SectionFrame(
          eyebrow: 'Booking preview',
          title: 'A prep board built around your photos, inspiration, and notes.',
          child: _BookingPreview(isWide: isWide),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _SectionFrame(
          eyebrow: 'Featured services',
          title: 'Popular services still match the seeded booking flow.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _ServiceSpotlight(
                title: 'Luxury women\'s haircut',
                duration: '75 min',
                price: 'From \$120',
                description: 'A polished in-home cut with consultation and finishing style included.',
                tone: Color(0xFFBE9678),
              ),
              _ServiceSpotlight(
                title: 'Signature blowout',
                duration: '60 min',
                price: 'From \$95',
                description: 'Smooth styling and finishing for events or everyday luxury.',
                tone: Color(0xFF8C6A58),
              ),
              _ServiceSpotlight(
                title: 'Kids haircut',
                duration: '45 min',
                price: 'From \$55',
                description: 'A gentler appointment block for calm, child-centered visits.',
                tone: Color(0xFFD2B094),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _SectionFrame(
          eyebrow: 'Upcoming appointment',
          title: 'Track your next visit without leaving the home screen.',
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7D8CB)),
            ),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(child: _UpcomingAppointmentSummary()),
                      SizedBox(width: 18),
                      Expanded(child: _UpcomingAppointmentSidebar()),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UpcomingAppointmentSummary(),
                      SizedBox(height: 18),
                      _UpcomingAppointmentSidebar(),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _WarmPill extends StatelessWidget {
  const _WarmPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EDE4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5D5C8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7D8CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroScene extends StatelessWidget {
  const _HeroScene();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8EFE7), Color(0xFFE9D8CA)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: 26, left: 24, child: _MiniPlant()),
          Positioned(
            right: 18,
            top: 18,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD8B89C), width: 6),
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFFBF6), Color(0xFFEDE2D7)],
                ),
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 20,
            child: Container(
              width: 208,
              height: 154,
              decoration: BoxDecoration(
                color: const Color(0xFF202024),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 28,
                    offset: Offset(0, 16),
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
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE4CCBD),
                      ),
                    ),
                    Text(
                      'HAIR STYLIST',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: const Color(0xFFD8B4A4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Row(
              children: const [
                _ToolStrip(width: 78),
                SizedBox(width: 10),
                _ToolStrip(width: 54),
                SizedBox(width: 10),
                _ToolStrip(width: 96),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HELP YOUR',
          style: GoogleFonts.cormorantGaramond(
            fontSize: isWide ? 58 : 42,
            height: 0.95,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -6),
          child: Text(
            'Stylist Prepare',
            style: GoogleFonts.parisienne(
              fontSize: isWide ? 64 : 46,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The more detail you share, the better I can understand your goals before your appointment. This home screen now follows that same calm, polished prep-board look.',
          style: GoogleFonts.manrope(
            fontSize: 15,
            height: 1.7,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/customer/book'),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Start A New Booking'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/customer/appointments'),
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('View Appointments'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _MetricChip(label: 'Photo upload', value: '4 angles'),
            _MetricChip(label: 'Consult notes', value: 'Personalized'),
            _MetricChip(label: 'Household booking', value: 'Family ready'),
          ],
        ),
      ],
    );
  }
}

class _MiniPlant extends StatelessWidget {
  const _MiniPlant();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 180,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 62,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5EE),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          ...List.generate(7, (index) {
            return Positioned(
              left: index.isEven ? 24 + index * 10 : 50 + index * 6,
              top: 16 + index * 8,
              child: Transform.rotate(
                angle: index.isEven ? -0.5 : 0.5,
                child: Container(
                  width: 10,
                  height: 42,
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

class _ToolStrip extends StatelessWidget {
  const _ToolStrip({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.22,
      child: Container(
        width: width,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFF453730),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ProcessTile extends StatelessWidget {
  const _ProcessTile({
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
      width: 220,
      child: Column(
        children: [
          Text(
            step,
            style: GoogleFonts.parisienne(
              fontSize: 36,
              color: const Color(0xFFD4B19E),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 58,
            height: 58,
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
              letterSpacing: 0.6,
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

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
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
            letterSpacing: 2.3,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            height: 1.05,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _BookingPreview extends StatelessWidget {
  const _BookingPreview({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7D8CB)),
      ),
      child: Column(
        children: [
          Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _UploadCard(
                  title: 'Upload photos of your hair',
                  subtitle: 'Add clear photos in natural light.',
                  footer: const [
                    _MiniShot(label: 'Front'),
                    _MiniShot(label: 'Back'),
                    _MiniShot(label: 'Left'),
                    _MiniShot(label: 'Right'),
                  ],
                ),
              ),
              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
              Expanded(
                child: _UploadCard(
                  title: 'Add inspiration photos',
                  subtitle: 'Upload any styles, cuts, or colours you love.',
                  footer: const [
                    _RefTile(tone: Color(0xFF886851)),
                    _RefTile(tone: Color(0xFFB28768)),
                    _RefTile(tone: Color(0xFF6B5142)),
                    _RefTile(tone: Color(0xFFCAA27E)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const [
              _MockInput(label: 'What are you looking to do?', hint: 'Select an option'),
              _MockInput(label: 'What do you love about your hair?', hint: 'e.g. length, colour, texture...'),
              _MockInput(label: 'What would you like to change?', hint: 'e.g. lighter, softer, more layers...'),
              _MockInput(label: 'Any dislikes or things to avoid?', hint: 'e.g. brassy tones, too short, bulk...'),
              _MockInput(label: 'Any other notes for me?', hint: 'Share anything else I should know...'),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7D8CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 12,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3D3C6)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 30, color: AppColors.accent),
                  const SizedBox(height: 10),
                  Text(
                    'DRAG & DROP YOUR PHOTOS HERE',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => context.go('/customer/book'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

class _MiniShot extends StatelessWidget {
  const _MiniShot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7D8CB)),
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

class _RefTile extends StatelessWidget {
  const _RefTile({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tone, const Color(0xFFF2E6DA)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 54,
          height: 66,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F2EC),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
              bottom: Radius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _MockInput extends StatelessWidget {
  const _MockInput({required this.label, required this.hint});

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
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7D8CB)),
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

class _ServiceSpotlight extends StatelessWidget {
  const _ServiceSpotlight({
    required this.title,
    required this.duration,
    required this.price,
    required this.description,
    required this.tone,
  });

  final String title;
  final String duration;
  final String price;
  final String description;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7D8CB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tone, const Color(0xFFF2E8DD)],
                ),
              ),
              child: Center(
                child: Container(
                  width: 92,
                  height: 118,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F4EE),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(50),
                      bottom: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.manrope(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  duration,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  price,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingAppointmentSummary extends StatelessWidget {
  const _UpcomingAppointmentSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7E8D7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'REQUESTED',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Family appointment block',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lena and Noah',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        const _InfoLine(icon: Icons.schedule_outlined, text: 'Saturday, May 24 at 10:00 AM'),
        const SizedBox(height: 10),
        const _InfoLine(icon: Icons.home_outlined, text: 'Mock address on file for your household'),
        const SizedBox(height: 10),
        const _InfoLine(icon: Icons.design_services_outlined, text: 'Consultation, haircut, and finishing style'),
      ],
    );
  }
}

class _UpcomingAppointmentSidebar extends StatelessWidget {
  const _UpcomingAppointmentSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EFE6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready before arrival',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your uploaded photos, inspiration, and notes stay together so the stylist can review the full plan before the visit starts.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.65,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.go('/customer/appointments'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Open Appointments'),
          ),
        ],
      ),
    );
  }
}