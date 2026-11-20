import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'motion.dart';

/// One option in a group of choices. Selection uses the accent (the one
/// non-attention colour allowed to carry meaning), with a tick so it never
/// depends on colour alone.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Secondary text after the label, e.g. a price.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget - 4),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? c.accentSubtle : c.surface,
            border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: AppMotion.quick,
                curve: AppMotion.standard,
                child: selected
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSpacing.xs + 2,
                        ),
                        child: Icon(Icons.check_rounded, size: 16, color: c.accent),
                      )
                    : const SizedBox.shrink(),
              ),
              Text(
                label,
                style: AppType.label.copyWith(
                  color: selected ? c.accent : c.ink,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  trailing!,
                  style: AppType.numeric.copyWith(
                    fontSize: 13,
                    color: selected ? c.accent : c.inkTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
