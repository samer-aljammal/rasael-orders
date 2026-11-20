import 'package:flutter/material.dart';

/// Rasael Orders colour tokens. Rationale in docs/DESIGN.md §3.
///
/// Read through `context.colors`; feature code never hardcodes a hex value.
/// [dueToday] and [late] are the whole attention vocabulary and must not be
/// used decoratively. [seal] belongs to the brand mark only.
@immutable
class RasaelColors extends ThemeExtension<RasaelColors> {
  const RasaelColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceInverse,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.inkInverse,
    required this.inkInverseSecondary,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.seal,
    required this.dueToday,
    required this.dueTodaySubtle,
    required this.late,
    required this.lateSubtle,
    required this.skeleton,
    required this.scrim,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;

  /// The single hero block on a screen.
  final Color surfaceInverse;
  final Color border;
  final Color borderStrong;

  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;

  /// Text on [surfaceInverse].
  final Color inkInverse;
  final Color inkInverseSecondary;

  /// Wine in light, dusty rose in dark.
  final Color accent;
  final Color onAccent;
  final Color accentSubtle;

  /// The pink heart seal from the Rasael logo. Brand mark only.
  final Color seal;

  final Color dueToday;
  final Color dueTodaySubtle;
  final Color late;
  final Color lateSubtle;

  final Color skeleton;
  final Color scrim;

  static const light = RasaelColors(
    background: Color(0xFFF7F2EA),
    surface: Color(0xFFFFFCF7),
    surfaceAlt: Color(0xFFEFE8DD),
    surfaceInverse: Color(0xFF2A1A1E),
    border: Color(0xFFE6DDD0),
    borderStrong: Color(0xFFCDBFAE),
    ink: Color(0xFF21161A),
    inkSecondary: Color(0xFF5E5157),
    inkTertiary: Color(0xFF776A6E),
    inkInverse: Color(0xFFF7F2EA),
    inkInverseSecondary: Color(0xFFBFB0AE),
    accent: Color(0xFF561A27),
    onAccent: Color(0xFFFFF8F0),
    accentSubtle: Color(0xFFF1E1E2),
    seal: Color(0xFFF07C8C),
    dueToday: Color(0xFF8A5A00),
    dueTodaySubtle: Color(0xFFF6EBD3),
    late: Color(0xFFB4400F),
    lateSubtle: Color(0xFFF8E4D8),
    skeleton: Color(0xFFEDE6DB),
    scrim: Color(0x6621161A),
  );

  static const dark = RasaelColors(
    background: Color(0xFF141011),
    surface: Color(0xFF1C1618),
    surfaceAlt: Color(0xFF251E20),
    // In dark mode the hero is an *elevated* surface, so it doesn't glow.
    surfaceInverse: Color(0xFF2C2225),
    border: Color(0xFF31282B),
    borderStrong: Color(0xFF4A3F42),
    ink: Color(0xFFF4EDE6),
    inkSecondary: Color(0xFFB9ADA8),
    inkTertiary: Color(0xFF958985),
    inkInverse: Color(0xFFF4EDE6),
    inkInverseSecondary: Color(0xFFB9ADA8),
    accent: Color(0xFFE8919C),
    onAccent: Color(0xFF2A0F15),
    accentSubtle: Color(0xFF3A2227),
    seal: Color(0xFFF07C8C),
    dueToday: Color(0xFFD9A84E),
    dueTodaySubtle: Color(0xFF2C2414),
    late: Color(0xFFEE8A5F),
    lateSubtle: Color(0xFF2E1C14),
    skeleton: Color(0xFF251E20),
    scrim: Color(0x99000000),
  );

  @override
  RasaelColors copyWith() => this;

  @override
  RasaelColors lerp(ThemeExtension<RasaelColors>? other, double t) {
    if (other is! RasaelColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return RasaelColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      surfaceInverse: l(surfaceInverse, other.surfaceInverse),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      ink: l(ink, other.ink),
      inkSecondary: l(inkSecondary, other.inkSecondary),
      inkTertiary: l(inkTertiary, other.inkTertiary),
      inkInverse: l(inkInverse, other.inkInverse),
      inkInverseSecondary: l(inkInverseSecondary, other.inkInverseSecondary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSubtle: l(accentSubtle, other.accentSubtle),
      seal: l(seal, other.seal),
      dueToday: l(dueToday, other.dueToday),
      dueTodaySubtle: l(dueTodaySubtle, other.dueTodaySubtle),
      late: l(late, other.late),
      lateSubtle: l(lateSubtle, other.lateSubtle),
      skeleton: l(skeleton, other.skeleton),
      scrim: l(scrim, other.scrim),
    );
  }
}

extension RasaelColorsX on BuildContext {
  RasaelColors get colors => Theme.of(this).extension<RasaelColors>()!;
}
