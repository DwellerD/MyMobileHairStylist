/// Shared spacing tokens used to keep layouts visually consistent.
///
/// Using these values instead of ad-hoc numbers makes the UI easier to evolve
/// and keeps whitespace deliberate across screens.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const double pagePadding = 20;
  static const double cardPadding = 18;
  static const double sectionGap = 24;
  static const double cardRadius = 24;
  static const double controlRadius = 18;
  static const double avatarSize = 52;
}