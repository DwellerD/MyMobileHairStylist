import 'package:flutter/material.dart';

/// Central color tokens for the entire application.
///
/// The palette is intentionally calm and warm so the brand feels premium,
/// trustworthy, and family-friendly without becoming overly decorative.
abstract final class AppColors {
  static const Color background = Color(0xFFF5F1F2);
  static const Color surface = Color(0xFFFDFCFC);
  static const Color surfaceAlt = Color(0xFFECE2E3);
  static const Color border = Color(0xFFD8CACC);
  static const Color borderStrong = Color(0xFFC5B2B5);

  static const Color primary = Color(0xFFA3787D);
  static const Color primaryPressed = Color(0xFF8D676C);
  static const Color accent = Color(0xFFC3A7AB);

  static const Color textPrimary = Color(0xFF463B3D);
  static const Color textSecondary = Color(0xFF766A6D);
  static const Color textMuted = Color(0xFF9A8F92);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryMuted = Colors.white70;

  static const Color success = Color(0xFF7F9685);
  static const Color warning = Color(0xFFB6977A);
  static const Color danger = Color(0xFFBA7E84);
  static const Color info = Color(0xFF9B929A);

  // Showcase and decorative neutrals reused across customer/auth views.
  static const Color showcaseGradientStart = Color(0xFFF6EEE6);
  static const Color showcaseGradientMid = Color(0xFFF4E8DE);
  static const Color showcaseGradientEnd = Color(0xFFF8F3ED);
  static const Color showcasePanel = Color(0xFFFDF8F2);
  static const Color showcaseCardSoft = Color(0xFFF6ECE3);
  static const Color showcaseCardWarm = Color(0xFFF8EFE7);
  static const Color showcaseSurfaceWarm = Color(0xFFF9F3ED);
  static const Color showcaseSurfaceSoft = Color(0xFFF7EDE4);
  static const Color showcaseSurfaceAlt = Color(0xFFF0E6DE);
  static const Color showcaseSurfaceIvory = Color(0xFFFFFAF5);
  static const Color showcaseSurfaceBase = Color(0xFFFFFBF7);
  static const Color showcaseSurfaceBaseAlt = Color(0xFFFFFBF8);
  static const Color showcaseSurfaceHighlight = Color(0xFFFFFCF8);
  static const Color showcaseSurfaceRose = Color(0xFFFBF3EB);
  static const Color showcaseSurfaceFooter = Color(0xFFF5E9DE);
  static const Color showcaseBorderWarm = Color(0xFFEADACB);
  static const Color showcaseBorderSoft = Color(0xFFE8D6C8);
  static const Color showcaseBorderMuted = Color(0xFFE4D4C7);
  static const Color showcaseBorderLight = Color(0xFFE7D8CB);
  static const Color showcaseBorderPale = Color(0xFFE9DDD1);
  static const Color showcaseBorderPaleAlt = Color(0xFFE1D1C5);
  static const Color showcaseBorderPaleSoft = Color(0xFFE8DACE);
  static const Color showcaseBorderPaleSoftAlt = Color(0xFFE8D9CB);
  static const Color showcaseChipBackground = Color(0xFFFAF1E9);
  static const Color showcaseChipBorder = Color(0xFFD8BCAB);
  static const Color showcaseAccentSoft = Color(0xFFD6B2A2);
  static const Color showcaseAccentBronze = Color(0xFFC79C79);
  static const Color showcaseDarkSurface = Color(0xFF232125);
  static const Color showcaseDarkSurfaceAlt = Color(0xFF27252A);
  static const Color showcaseGradientWarmStart = Color(0xFFF9F2EA);
  static const Color showcaseGradientWarmEnd = Color(0xFFE9D8CA);
  static const Color showcaseGradientSoftEnd = Color(0xFFF1E5DB);
  static const Color showcaseGradientCream = Color(0xFFF1E4D8);
  static const Color showcaseGradientPhotoStart = Color(0xFFF1E2D6);
  static const Color showcaseGradientPhotoEnd = Color(0xFFF9F4ED);
  static const Color showcaseGradientMist = Color(0xFFF2E8DD);
  static const Color showcaseGradientGalleryEnd = Color(0xFFF3E8DE);
  static const Color showcaseCanvasWarm = Color(0xFFF7F2EC);
  static const Color showcaseCanvasWarmSoft = Color(0xFFF8F4EE);
  static const Color showcaseGlass = Color(0xCCFFFDF9);
  static const Color showcaseShadowSoft = Color(0x11000000);
  static const Color showcaseShadowSubtle = Color(0x0A000000);
}