import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'motion.dart';

/// The wine button. A spring press instead of a ripple, and a busy state
/// that keeps the button's size so the layout never shifts.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !busy;
    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        height: AppSizes.buttonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled || busy ? c.accent : c.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.quick,
          child: busy
              ? SizedBox(
                  key: const ValueKey('busy'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.onAccent,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: AppType.subtitle.copyWith(
                    color: enabled ? c.onAccent : c.inkTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}
