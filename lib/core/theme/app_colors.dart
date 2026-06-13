import 'package:flutter/material.dart';

import 'theme_personalization.dart';

/// Central color tokens for the entire application.
///
/// The palette is intentionally calm and warm so the brand feels premium,
/// trustworthy, and family-friendly without becoming overly decorative.
abstract final class AppColors {
  static AppThemePreset _activePreset = AppThemePreset.sageGarden;

  static void usePreset(AppThemePreset preset) {
    _activePreset = preset;
  }

  static ThemePalette get _palette => appThemePaletteFor(_activePreset);

  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get surfaceAlt => _palette.surfaceAlt;
  static Color get border => _palette.border;
  static Color get borderStrong => _palette.borderStrong;

  static Color get primary => _palette.primary;
  static Color get primaryPressed => _shade(_palette.primary, 0.14);
  static Color get accent => _palette.accent;

  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textMuted => _palette.textMuted;
  static Color get onPrimary => _palette.onPrimary;
  static Color get onPrimaryMuted => _withOpacity(_palette.onPrimary, 0.7);

  static Color get success => _palette.success;
  static Color get warning => _palette.warning;
  static Color get danger => _palette.danger;
  static Color get info => _palette.info;

  // Showcase and decorative neutrals reused across customer/auth views.
  static Color get showcaseGradientStart => _tint(background, 0.45);
  static Color get showcaseGradientMid => _tint(surfaceAlt, 0.34);
  static Color get showcaseGradientEnd => _tint(surface, 0.5);
  static Color get showcasePanel => _tint(surface, 0.16);
  static Color get showcaseCardSoft => _tint(surfaceAlt, 0.12);
  static Color get showcaseCardWarm => _tint(surfaceAlt, 0.18);
  static Color get showcaseSurfaceWarm => _tint(surfaceAlt, 0.26);
  static Color get showcaseSurfaceSoft => _tint(surfaceAlt, 0.2);
  static Color get showcaseSurfaceAlt => _tint(surfaceAlt, 0.08);
  static Color get showcaseSurfaceIvory => _tint(surface, 0.2);
  static Color get showcaseSurfaceBase => _tint(surface, 0.08);
  static Color get showcaseSurfaceBaseAlt => _tint(surface, 0.14);
  static Color get showcaseSurfaceHighlight => _tint(surface, 0.24);
  static Color get showcaseSurfaceRose => _tint(surfaceAlt, 0.22);
  static Color get showcaseSurfaceFooter => _shade(surfaceAlt, 0.05);
  static Color get showcaseBorderWarm => _tint(border, 0.06);
  static Color get showcaseBorderSoft => _tint(border, 0.03);
  static Color get showcaseBorderMuted => border;
  static Color get showcaseBorderLight => _tint(border, 0.1);
  static Color get showcaseBorderPale => _tint(border, 0.12);
  static Color get showcaseBorderPaleAlt => _shade(border, 0.03);
  static Color get showcaseBorderPaleSoft => _tint(border, 0.08);
  static Color get showcaseBorderPaleSoftAlt => _shade(border, 0.02);
  static Color get showcaseChipBackground => _tint(surfaceAlt, 0.3);
  static Color get showcaseChipBorder => _shade(accent, 0.14);
  static Color get showcaseAccentSoft => _tint(accent, 0.12);
  static Color get showcaseAccentBronze => _shade(accent, 0.22);
  static Color get showcaseDarkSurface => _shade(textPrimary, 0.44);
  static Color get showcaseDarkSurfaceAlt => _shade(textPrimary, 0.34);
  static Color get showcaseGradientWarmStart => _tint(surface, 0.2);
  static Color get showcaseGradientWarmEnd => _tint(surfaceAlt, 0.18);
  static Color get showcaseGradientSoftEnd => _tint(surfaceAlt, 0.14);
  static Color get showcaseGradientCream => _tint(surfaceAlt, 0.16);
  static Color get showcaseGradientPhotoStart => _tint(surfaceAlt, 0.14);
  static Color get showcaseGradientPhotoEnd => _tint(surface, 0.18);
  static Color get showcaseGradientMist => _tint(surfaceAlt, 0.12);
  static Color get showcaseGradientGalleryEnd => _tint(surfaceAlt, 0.1);
  static Color get showcaseCanvasWarm => _tint(surfaceAlt, 0.24);
  static Color get showcaseCanvasWarmSoft => _tint(surfaceAlt, 0.3);
  static Color get showcaseGlass => _withOpacity(_tint(surface, 0.2), 0.78);
  static Color get showcaseShadowSoft => _withOpacity(Colors.black, 0.07);
  static Color get showcaseShadowSubtle => _withOpacity(Colors.black, 0.04);

  static Color _tint(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  static Color _shade(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }

  static Color _withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}
