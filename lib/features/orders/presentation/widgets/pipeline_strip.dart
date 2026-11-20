import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/order_status.dart';

/// The five stages as a ruled strip: done stages in ink, the current one
/// thicker and in the accent with its name, the rest as hairlines.
/// A cancelled order shows every segment as a hairline.
class PipelineStrip extends StatelessWidget {
  const PipelineStrip({super.key, required this.current});

  final OrderStatus current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const stages = OrderStatus.pipeline;
    final at = stages.indexOf(current);

    return Semantics(
      label: at < 0
          ? current.label
          : 'المرحلة ${at + 1} من ${stages.length}: ${current.label}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.move,
                    curve: AppMotion.standard,
                    height: i == at ? 4 : 2,
                    decoration: BoxDecoration(
                      color: i < at
                          ? c.ink
                          : i == at
                          ? c.accent
                          : c.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < stages.length; i++)
                Expanded(
                  child: Text(
                    stages[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppType.caption.copyWith(
                      fontSize: 11,
                      color: i == at
                          ? c.accent
                          : i < at
                          ? c.inkSecondary
                          : c.inkTertiary,
                      fontWeight: i == at ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
