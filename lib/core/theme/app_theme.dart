import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'theme_personalization.dart';
import 'app_text_styles.dart';

/// Defines the global application theme.
///
/// The theme is deliberately light and polished so every screen inherits the
/// core brand language without each widget restating colors and spacing.
abstract final class AppTheme {
  static ThemeData get lightTheme => lightThemeFor(AppThemePreset.sageGarden);

  static ThemeData lightThemeFor(AppThemePreset preset) {
    final palette = appThemePaletteFor(preset);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.light,
      primary: palette.primary,
      secondary: palette.accent,
      surface: palette.surface,
      error: palette.danger,
    ).copyWith(
      onPrimary: palette.onPrimary,
      onSurface: palette.textPrimary,
      outline: palette.border,
      secondaryContainer: palette.surfaceAlt,
    );

    final textTheme = AppTextStyles.textTheme.copyWith(
      displaySmall: AppTextStyles.display.copyWith(color: palette.textPrimary),
      headlineMedium: AppTextStyles.headline.copyWith(color: palette.textPrimary),
      titleLarge: AppTextStyles.title.copyWith(color: palette.textPrimary),
      bodyLarge: AppTextStyles.body.copyWith(color: palette.textPrimary),
      bodyMedium: AppTextStyles.bodyMuted.copyWith(color: palette.textSecondary),
      labelLarge: AppTextStyles.label.copyWith(color: palette.textSecondary),
      bodySmall: AppTextStyles.caption.copyWith(color: palette.textMuted),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: palette.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide(color: palette.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        labelStyle: AppTextStyles.bodyMuted.copyWith(color: palette.textSecondary),
        hintStyle: AppTextStyles.bodyMuted.copyWith(color: palette.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: palette.danger, width: 1.2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textMuted,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        showUnselectedLabels: true,
      ),
      dividerColor: palette.border,
      iconTheme: IconThemeData(color: palette.textSecondary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
      ),
    );
  }
}