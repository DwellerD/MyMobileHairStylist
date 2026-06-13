import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ThemePalette {
  const ThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onPrimary,
    required this.danger,
    required this.warning,
    required this.success,
    required this.info,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color onPrimary;
  final Color danger;
  final Color warning;
  final Color success;
  final Color info;
}

/// Curated color presets available in customer preferences.
enum AppThemePreset {
  sageGarden,
  blushPink,
  coastalBlue,
  terracotta,
  champagneGold,
}

extension AppThemePresetMeta on AppThemePreset {
  String get storageKey => switch (this) {
        AppThemePreset.sageGarden => 'sageGarden',
        AppThemePreset.blushPink => 'blushPink',
        AppThemePreset.coastalBlue => 'coastalBlue',
        AppThemePreset.terracotta => 'terracotta',
        AppThemePreset.champagneGold => 'champagneGold',
      };

  String get label => switch (this) {
        AppThemePreset.sageGarden => 'Sage Garden',
        AppThemePreset.blushPink => 'Blush Pink',
        AppThemePreset.coastalBlue => 'Coastal Blue',
        AppThemePreset.terracotta => 'Terracotta',
        AppThemePreset.champagneGold => 'Champagne Gold',
      };

  String get description => switch (this) {
        AppThemePreset.sageGarden => 'Calm and natural with modern sage accents.',
        AppThemePreset.blushPink => 'Soft rosy tones with a premium boutique feel.',
        AppThemePreset.coastalBlue => 'Clean ocean-inspired palette with crisp contrast.',
        AppThemePreset.terracotta => 'Warm earthy clay tones with rich depth.',
        AppThemePreset.champagneGold => 'Elegant neutral base with polished golden warmth.',
      };

  Color get previewPrimary => switch (this) {
        AppThemePreset.sageGarden => const Color(0xFF6F8A78),
        AppThemePreset.blushPink => const Color(0xFFB98496),
        AppThemePreset.coastalBlue => const Color(0xFF5F8195),
        AppThemePreset.terracotta => const Color(0xFFA96E57),
        AppThemePreset.champagneGold => const Color(0xFFA78C5D),
      };

  Color get previewAccent => switch (this) {
        AppThemePreset.sageGarden => const Color(0xFF9CB9A1),
        AppThemePreset.blushPink => const Color(0xFFD8AFC1),
        AppThemePreset.coastalBlue => const Color(0xFF93B4C7),
        AppThemePreset.terracotta => const Color(0xFFD2A38D),
        AppThemePreset.champagneGold => const Color(0xFFD7C292),
      };
}

AppThemePreset appThemePresetFromStorage(String? raw) {
  for (final preset in AppThemePreset.values) {
    if (preset.storageKey == raw) {
      return preset;
    }
  }
  return AppThemePreset.sageGarden;
}

class ThemePresetController extends StateNotifier<AppThemePreset> {
  ThemePresetController() : super(AppThemePreset.sageGarden) {
    _restore();
  }

  static const _storageKey = 'app_theme_preset';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_storageKey);
    state = appThemePresetFromStorage(savedValue);
  }

  Future<void> setPreset(AppThemePreset preset) async {
    if (preset == state) {
      return;
    }

    state = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, preset.storageKey);
  }
}

final themePresetProvider =
    StateNotifierProvider<ThemePresetController, AppThemePreset>(
  (ref) => ThemePresetController(),
);

ThemePalette appThemePaletteFor(AppThemePreset preset) {
  return switch (preset) {
    AppThemePreset.sageGarden => const ThemePalette(
        background: Color(0xFFF2F5F1),
        surface: Color(0xFFFBFDFB),
        surfaceAlt: Color(0xFFE7EEE8),
        border: Color(0xFFC7D4C8),
        borderStrong: Color(0xFFAABDAE),
        primary: Color(0xFF6F8A78),
        accent: Color(0xFF9CB9A1),
        textPrimary: Color(0xFF2F3E34),
        textSecondary: Color(0xFF526458),
        textMuted: Color(0xFF7B8C80),
        onPrimary: Colors.white,
        danger: Color(0xFFB57C7C),
        warning: Color(0xFFB19C72),
        success: Color(0xFF6F8A78),
        info: Color(0xFF7A8F86),
      ),
    AppThemePreset.blushPink => const ThemePalette(
        background: Color(0xFFF9F3F6),
        surface: Color(0xFFFFFCFD),
        surfaceAlt: Color(0xFFF3E6EC),
        border: Color(0xFFE6CFD8),
        borderStrong: Color(0xFFCFB0BC),
        primary: Color(0xFFB98496),
        accent: Color(0xFFD8AFC1),
        textPrimary: Color(0xFF4A303A),
        textSecondary: Color(0xFF765964),
        textMuted: Color(0xFF9A7E88),
        onPrimary: Colors.white,
        danger: Color(0xFFB46C79),
        warning: Color(0xFFC09A7A),
        success: Color(0xFF8A9D8E),
        info: Color(0xFF8B7E95),
      ),
    AppThemePreset.coastalBlue => const ThemePalette(
        background: Color(0xFFF1F6FA),
        surface: Color(0xFFFCFEFF),
        surfaceAlt: Color(0xFFE4EEF5),
        border: Color(0xFFC5D7E4),
        borderStrong: Color(0xFFA9C1D3),
        primary: Color(0xFF5F8195),
        accent: Color(0xFF93B4C7),
        textPrimary: Color(0xFF2B3C47),
        textSecondary: Color(0xFF4B6474),
        textMuted: Color(0xFF728A99),
        onPrimary: Colors.white,
        danger: Color(0xFFAF7070),
        warning: Color(0xFFB3A27A),
        success: Color(0xFF6E8FA2),
        info: Color(0xFF7D8CA6),
      ),
    AppThemePreset.terracotta => const ThemePalette(
        background: Color(0xFFFAF3EF),
        surface: Color(0xFFFFFCFA),
        surfaceAlt: Color(0xFFF2E3DB),
        border: Color(0xFFE0C7BA),
        borderStrong: Color(0xFFCBAA9A),
        primary: Color(0xFFA96E57),
        accent: Color(0xFFD2A38D),
        textPrimary: Color(0xFF4A3329),
        textSecondary: Color(0xFF735445),
        textMuted: Color(0xFF977867),
        onPrimary: Colors.white,
        danger: Color(0xFFAF6863),
        warning: Color(0xFFB79667),
        success: Color(0xFF8E8A74),
        info: Color(0xFF9A7D6D),
      ),
    AppThemePreset.champagneGold => const ThemePalette(
        background: Color(0xFFF9F6EE),
        surface: Color(0xFFFFFDF8),
        surfaceAlt: Color(0xFFF1EAD8),
        border: Color(0xFFE0D4B8),
        borderStrong: Color(0xFFCAB991),
        primary: Color(0xFFA78C5D),
        accent: Color(0xFFD7C292),
        textPrimary: Color(0xFF473C28),
        textSecondary: Color(0xFF6B5C3D),
        textMuted: Color(0xFF92815F),
        onPrimary: Colors.white,
        danger: Color(0xFFB38266),
        warning: Color(0xFFB49A6F),
        success: Color(0xFF8A9070),
        info: Color(0xFF8D836D),
      ),
  };
}
