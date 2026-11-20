import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

/// Spring-driven press feedback for any tappable surface.
///
/// The child sinks to [AppMotion.pressedScale] on touch-down and springs back
/// on release. Because a spring drives it, a tap released mid-press reverses
/// from its current velocity instead of snapping.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.scale = AppMotion.pressedScale,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _springTo(double target, SpringDescription spring) {
    if (AppMotion.reduced(context)) {
      _press.value = target;
      return;
    }
    _press.animateWith(
      SpringSimulation(spring, _press.value, target, _press.velocity),
    );
  }

  void _down(TapDownDetails _) => _springTo(1, AppMotion.pressSpring);
  void _up([Object? _]) => _springTo(0, AppMotion.settleSpring);

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_interactive) return widget.child;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _up,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                _up();
                widget.onLongPress!();
              },
        child: AnimatedBuilder(
          animation: _press,
          child: widget.child,
          builder: (context, child) => Transform.scale(
            scale: 1 - (1 - widget.scale) * _press.value,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts its child into place once, when first built.
///
/// Consecutive siblings take increasing [index] values to stagger.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = AppMotion.enterOffset,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.enterDuration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  static const _maxStaggeredIndex = 8;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    final steps = widget.index.clamp(0, _maxStaggeredIndex);
    Future<void>.delayed(AppMotion.stagger * steps, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// A number that rolls from its previous value to the new one.
class AnimatedNumber extends StatefulWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.animateFromZero = false,
    this.duration = const Duration(milliseconds: 700),
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final bool animateFromZero;
  final Duration duration;

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber> {
  late double _from = widget.animateFromZero ? 0 : widget.value;

  @override
  void didUpdateWidget(AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _from = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? widget.value : _from, end: widget.value),
      duration: reduced ? Duration.zero : widget.duration,
      curve: Curves.easeOutQuart,
      builder: (context, value, _) => Text(
        widget.format(value),
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
