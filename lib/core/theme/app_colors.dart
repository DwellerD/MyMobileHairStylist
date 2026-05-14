import 'package:flutter/material.dart';

/// Central color tokens for the entire application.
///
/// The palette is intentionally calm and warm so the brand feels premium,
/// trustworthy, and family-friendly without becoming overly decorative.
abstract final class AppColors {
  static const Color background = Color(0xFFF8F2EA);
  static const Color surface = Color(0xFFFFFCF8);
  static const Color surfaceAlt = Color(0xFFF4EADF);
  static const Color border = Color(0xFFE6D8CA);
  static const Color borderStrong = Color(0xFFD4C1AF);

  static const Color primary = Color(0xFF7B5D52);
  static const Color primaryPressed = Color(0xFF6A4F45);
  static const Color accent = Color(0xFFCFA79F);

  static const Color textPrimary = Color(0xFF2D2623);
  static const Color textSecondary = Color(0xFF6B625C);
  static const Color textMuted = Color(0xFF8B8178);
  static const Color onPrimary = Colors.white;

  static const Color success = Color(0xFF5D8A74);
  static const Color warning = Color(0xFFB58A4C);
  static const Color danger = Color(0xFFB96F6B);
  static const Color info = Color(0xFF7F8FA5);
}