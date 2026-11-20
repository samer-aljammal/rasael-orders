import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/attention_badge.dart';
import '../../../../core/widgets/motion.dart';
import '../../domain/order.dart';

/// The one loud element on the home screen: what needs doing now.
///
/// When nothing needs attention it says so plainly and shows the open count
/// instead, rather than rendering an empty shell.
class AttentionHero extends StatelessWidget {
  const AttentionHero({
    super.key,
    required this.urgent,
    required this.openCount,
    required this.now,
    this.onOpen,
  });

  final List<Order> urgent;
  final int openCount;
  final DateTime now;
  final ValueChanged<Order>? onOpen;

  static const _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final calm = urgent.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceInverse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            calm ? 'كل شي ماشي' : 'بحاجة انتباهك',
            style: AppType.label.copyWith(color: c.inkInverseSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedNumber(
                value: (calm ? openCount : urgent.length).toDouble(),
                format: Fmt.number,
                animateFromZero: true,
                style: AppType.display.copyWith(color: c.inkInverse),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  calm ? _openNoun(openCount) : 'من أصل ${_openCounted(openCount)}',
                  style: AppType.body.copyWith(color: c.inkInverseSecondary),
                ),
              ),
            ],
          ),
          if (!calm) ...[
            const SizedBox(height: AppSpacing.md),
            for (final (i, o) in urgent.take(_maxLines).indexed) ...[
              if (i > 0)
                Divider(color: c.inkInverse.withValues(alpha: 0.10), height: 1),
              _UrgentLine(order: o, now: now, onTap: onOpen),
            ],
            if (urgent.length > _maxLines)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '+ ${urgent.length - _maxLines} كمان',
                  style: AppType.caption.copyWith(color: c.inkInverseSecondary),
                ),
              ),
          ] else
            const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  /// The noun after a big figure: «8 | طلبات مفتوحة». Arabic counts take a
  /// plural from 3 to 10 and a singular from 11 up.
  static String _openNoun(int n) => switch (n) {
    1 => 'طلب مفتوح',
    2 => 'طلبين مفتوحين',
    >= 3 && <= 10 => 'طلبات مفتوحة',
    _ => 'طلب مفتوح',
  };

  /// The same, inside a sentence: «من أصل 8 طلبات مفتوحة».
  static String _openCounted(int n) => switch (n) {
    1 => 'طلب واحد مفتوح',
    2 => 'طلبين مفتوحين',
    _ => '${Fmt.number(n)} ${_openNoun(n)}',
  };
}

class _UrgentLine extends StatelessWidget {
  const _UrgentLine({required this.order, required this.now, this.onTap});

  final Order order;
  final DateTime now;
  final ValueChanged<Order>? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final attention = order.attentionAt(now)!;
    return Pressable(
      onTap: onTap == null ? null : () => onTap!(order),
      scale: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: order.headline,
                      style: AppType.subtitle.copyWith(color: c.inkInverse),
                    ),
                    TextSpan(
                      text: '   ${order.kind.label}',
                      style: AppType.caption.copyWith(
                        color: c.inkInverseSecondary,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AttentionBadge(attention, onInverse: true),
          ],
        ),
      ),
    );
  }
}
