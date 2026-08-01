/// Spacing and radius scale. Using a fixed scale (instead of arbitrary
/// magic numbers scattered across widgets) is what makes the "everything
/// must breathe" premium feel consistent from screen to screen.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}
