import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/attention_badge.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/order.dart';
import '../../domain/order_status.dart';

/// Quick look at an order with the one action that moves it forward.
///
/// A stand-in until the full order screen lands; the pipeline strip and
/// the single verb button are the parts that carry over.
class StageSheet extends StatelessWidget {
  const StageSheet({
    super.key,
    required this.order,
    required this.now,
    required this.onAdvance,
  });

  final Order order;
  final DateTime now;
  final Future<void> Function() onAdvance;

  static Future<void> show(
    BuildContext context, {
    required Order order,
    required DateTime now,
    required Future<void> Function() onAdvance,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => StageSheet(order: order, now: now, onAdvance: onAdvance),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final attention = order.attentionAt(now);
    final action = order.status.nextAction;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  Fmt.ltr(order.code),
                  style: AppType.numeric.copyWith(
                    color: c.inkTertiary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (attention != null) AttentionBadge(attention),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(order.headline, style: AppType.title.copyWith(color: c.ink)),
            Text(
              '${order.kind.label} · ${order.packageName} · ${Fmt.syp(order.priceSyp)}',
              style: AppType.label.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Pipeline(current: order.status),
            const SizedBox(height: AppSpacing.sm),
            Text(
              order.status.hint,
              style: AppType.caption.copyWith(color: c.inkTertiary),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (action != null)
              PrimaryButton(
                label: action,
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onAdvance();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Five stages as a ruled strip: done stages in ink, the current one in
/// the accent with its name, the rest as hairlines.
class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.current});

  final OrderStatus current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stages = OrderStatus.pipeline;
    final at = stages.indexOf(current);

    return Semantics(
      label: 'المرحلة ${at + 1} من ${stages.length}: ${current.label}',
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
                    duration: const Duration(milliseconds: 240),
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
                    textAlign: TextAlign.start,
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
