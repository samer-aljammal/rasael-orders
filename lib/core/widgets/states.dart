import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A slow breathing pulse for skeletons. Still under reduced motion.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    ),
    child: widget.child,
  );
}

/// The shape of the home screen while orders load, so nothing jumps when
/// they arrive.
class OrdersSkeleton extends StatelessWidget {
  const OrdersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c.skeleton,
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
      ),
    );

    return Semantics(
      label: 'عم نجيب الطلبات',
      child: _Pulse(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            0,
          ),
          children: [
            Align(alignment: AlignmentDirectional.centerStart, child: bar(150, 26)),
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: AlignmentDirectional.centerStart, child: bar(110, 14)),
            const SizedBox(height: AppSpacing.xl),
            Container(
              height: 196,
              decoration: BoxDecoration(
                color: c.skeleton,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            Align(alignment: AlignmentDirectional.centerStart, child: bar(120, 14)),
            for (var i = 0; i < 5; i++) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(children: [bar(140, 16), const Spacer(), bar(64, 16)]),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [bar(100, 12), const Spacer(), bar(52, 12)]),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xl,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.subtitle.copyWith(color: c.ink)),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppType.body.copyWith(color: c.inkSecondary)),
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 32, color: c.inkTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, AppSizes.minTouchTarget),
              ),
              child: const Text('جرّب كمان مرة'),
            ),
          ],
        ),
      ),
    );
  }
}
