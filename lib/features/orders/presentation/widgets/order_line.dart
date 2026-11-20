import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/attention_badge.dart';
import '../../../../core/widgets/money.dart';
import '../../domain/order.dart';

/// One order as a ledger line: names and price on top, what it is and where
/// it stands underneath. No card, no icon tile; hairlines separate rows.
class OrderLine extends StatelessWidget {
  const OrderLine({
    super.key,
    required this.order,
    required this.now,
    this.onTap,
  });

  final Order order;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final attention = order.attentionAt(now);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.md + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.headline,
                    style: AppType.subtitle.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Money(order.priceSyp),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.kind.label}  ·  ${Fmt.ltr(order.code)}',
                    style: AppType.caption.copyWith(color: c.inkTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (attention != null)
                  AttentionBadge(attention)
                else
                  Text(
                    order.status.label,
                    style: AppType.caption.copyWith(color: c.inkSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
