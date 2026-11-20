import 'package:flutter/material.dart';

import '../../features/orders/domain/order.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The only coloured label in the app. Always words plus colour, never
/// colour alone (docs/DESIGN.md §2).
class AttentionBadge extends StatelessWidget {
  const AttentionBadge(this.attention, {super.key, this.onInverse = false});

  final Attention attention;

  /// Drawn on the dark hero block, where the subtle fills would vanish.
  final bool onInverse;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (attention) {
      Attention.late => (c.late, c.lateSubtle),
      Attention.dueToday || Attention.followUp => (c.dueToday, c.dueTodaySubtle),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: onInverse ? fg.withValues(alpha: 0.18) : bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: onInverse ? Color.lerp(fg, Colors.white, 0.35) : fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            attention.label,
            style: AppType.caption.copyWith(
              color: onInverse ? Color.lerp(fg, Colors.white, 0.35) : fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
