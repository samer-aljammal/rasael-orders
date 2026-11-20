import 'package:flutter/widgets.dart';

/// Type roles. See docs/DESIGN.md §4.
///
/// No style here sets `letterSpacing` on purpose: tracking breaks the joins
/// between Arabic letters. Body text runs at 1.6 so diacritics and deep
/// descenders (ي، ج، ع) are never clipped.
abstract final class AppFonts {
  static const String text = 'Plex';
  static const String brand = 'Messiri';
}

abstract final class AppType {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.15,
    fontFeatures: _tabular,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle title = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Section headers. Arabic has no uppercase, so weight and colour do the
  /// work an English overline would.
  static const TextStyle section = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Prices, counts, order codes: anything read as data.
  static const TextStyle numeric = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFeatures: _tabular,
  );

  /// The «رسائل» wordmark. El Messiri is a variable font, so weight is set
  /// on the axis rather than by picking a file.
  static TextStyle wordmark(double size) => TextStyle(
    fontFamily: AppFonts.brand,
    fontSize: size,
    height: 1.2,
    fontVariations: const [FontVariation('wght', 600)],
  );
}
