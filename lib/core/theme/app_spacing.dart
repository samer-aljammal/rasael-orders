/// 4pt spacing scale. See docs/DESIGN.md §5.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  /// Horizontal inset of every screen.
  static const double screen = 20;

  /// Gap between sections on a screen.
  static const double section = 28;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

abstract final class AppSizes {
  static const double minTouchTarget = 44;
  static const double buttonHeight = 52;

  /// Content never stretches wider than this on the web build.
  static const double maxContentWidth = 720;

  /// At or above this width the layout gains a side panel.
  static const double wideBreakpoint = 900;
}
