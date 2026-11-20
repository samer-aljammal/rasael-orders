import 'package:flutter/widgets.dart';

/// Motion tokens, shared in spirit with Drivio. See docs/DESIGN.md §5.
///
/// Ease-out for arrivals, springs for anything the finger touches, short
/// durations, entrances that play once, and everything optional under the
/// OS "remove animations" setting ([AppMotion.reduced]).
abstract final class AppMotion {
  /// Material 3 emphasized decelerate. Arrivals.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Material 3 emphasized accelerate. Exits; shorter than entrances.
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Material 3 standard. Movement between two resting states.
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  static const Duration press = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration move = Duration(milliseconds: 320);
  static const Duration enterDuration = Duration(milliseconds: 420);
  static const Duration stagger = Duration(milliseconds: 45);

  /// Press-down: fast, fully damped.
  static final SpringDescription pressSpring =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 160),
      );

  /// Release and selection: a whisper of overshoot.
  static final SpringDescription settleSpring =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 380),
        bounce: 0.12,
      );

  static const double enterOffset = 14;
  static const double pressedScale = 0.97;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
