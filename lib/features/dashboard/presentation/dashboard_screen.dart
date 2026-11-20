import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/states.dart';
import '../../orders/presentation/orders_cubit.dart';
import '../domain/business_stats.dart';

/// How the business is doing, in the order the owner asks it:
/// how much this month → in total → over time → from where → for what.
///
/// One hero (this month's income). Every chart is titled with the question
/// it answers. One colour: the accent marks the current month and the bars;
/// everything else is ink or gray.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأرقام'), titleSpacing: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) => switch (state) {
              OrdersLoading() => const Center(child: CircularProgressIndicator()),
              OrdersError(:final message) => ErrorPanel(
                message: message,
                onRetry: context.read<OrdersCubit>().retry,
              ),
              OrdersLoaded() => _Body(
                BusinessStats.compute(state.orders, state.now),
                state.now,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.s, this.now);

  final BusinessStats s;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (s.isEmpty) {
      return const EmptyPanel(
        title: 'لسا ما في أرقام',
        body: 'أول ما يندفع أول طلب، بتبيّن هون المصاري ومن وين عم يجو الزباين.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xxxl,
      ),
      children: [
        Reveal(child: _Hero(s: s)),
        const SizedBox(height: AppSpacing.md),
        Reveal(
          index: 1,
          child: Row(
            children: [
              Expanded(
                child: _Tile(label: 'كل الدخل', value: Fmt.number(s.totalSyp), unit: 'ل.س'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Tile(label: 'طلبات مدفوعة', value: Fmt.number(s.paidCount)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Tile(
                  label: 'متوسط الطلب',
                  value: Fmt.number(s.averageSyp),
                  unit: 'ل.س',
                ),
              ),
            ],
          ),
        ),
        if (s.awaitingCount > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Reveal(
            index: 2,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.awaitingCount == 1
                          ? 'معاينة وحدة بانتظار الدفع'
                          : '${Fmt.number(s.awaitingCount)} معاينات بانتظار الدفع',
                      style: AppType.label.copyWith(color: c.inkSecondary),
                    ),
                  ),
                  Text(
                    Fmt.syp(s.awaitingSyp),
                    style: AppType.numeric.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.section),
        Reveal(
          index: 3,
          child: _Card(
            title: 'كم دخّلت كل شهر؟',
            note: 'الشهر الحالي بلون، والباقي رمادي.',
            child: _MonthColumns(months: s.months),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Reveal(
          index: 4,
          child: _Card(
            title: 'من وين بيجو الزباين؟',
            note: 'عدد الطلبات المدفوعة من كل مكان.',
            child: _MeterList(
              rows: [
                for (final (src, n) in s.bySource)
                  (src?.label ?? 'مو مسجّل', n),
              ],
              total: s.paidCount,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Reveal(
          index: 5,
          child: _Card(
            title: 'شو أكتر شي بينطلب؟',
            child: _MeterList(
              rows: [for (final (k, n) in s.byKind) (k.label, n)],
              total: s.paidCount,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'الدخل = الطلبات اللي اندفعت بس، محسوبة بالشهر اللي اندفعت فيه.',
          style: AppType.caption.copyWith(color: c.inkTertiary),
        ),
      ],
    );
  }
}

/// This month's income: the one loud number on the screen.
class _Hero extends StatelessWidget {
  const _Hero({required this.s});
  final BusinessStats s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = s.thisMonth;
    final last = s.lastMonth;
    final diff = now.syp - last.syp;

    final String compare;
    if (last.syp == 0 && now.syp == 0) {
      compare = 'ما في دخل هالشهر لسا.';
    } else if (last.syp == 0) {
      compare = 'ما كان في دخل ب${Fmt.month(last.month)}.';
    } else if (diff == 0) {
      compare = 'متل ${Fmt.month(last.month)} بالظبط.';
    } else {
      // Last month's own figure is on the chart below; repeating it here in
      // brackets scrambled the RTL line (a number then a bracket).
      compare =
          '${diff > 0 ? 'أكتر' : 'أقل'} بـ ${Fmt.syp(diff.abs())} من ${Fmt.month(last.month)}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: c.surfaceInverse,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'دخلك ب${Fmt.month(now.month)}',
            style: AppType.label.copyWith(color: c.inkInverseSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedNumber(
                value: now.syp.toDouble(),
                format: Fmt.number,
                animateFromZero: true,
                // Proportional figures for a big standalone number.
                style: AppType.display.copyWith(
                  color: c.inkInverse,
                  fontSize: 48,
                  fontFeatures: const [],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ل.س',
                style: AppType.title.copyWith(color: c.inkInverseSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${now.orders == 1 ? 'طلب واحد' : '${Fmt.number(now.orders)} طلبات'} · $compare',
            style: AppType.label.copyWith(color: c.inkInverseSecondary),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption.copyWith(color: c.inkTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppType.title.copyWith(color: c.ink)),
                if (unit != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit!,
                    style: AppType.caption.copyWith(color: c.inkTertiary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.note});

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppType.subtitle.copyWith(color: c.ink)),
          if (note != null)
            Text(note!, style: AppType.caption.copyWith(color: c.inkTertiary)),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

/// Income per month as columns, oldest at the reading start. The current
/// month is the accent; earlier months are gray context. Values sit on the
/// caps; tapping a column says the full month, total and order count.
class _MonthColumns extends StatelessWidget {
  const _MonthColumns({required this.months});

  final List<MonthIncome> months;

  static const _plot = 132.0;

  static const _short = [
    'ك٢', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران', //
    'تموز', 'آب', 'أيلول', 'ت١', 'ت٢', 'ك١',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final max = months.fold(0, (m, x) => x.syp > m ? x.syp : m);
    final reduced = AppMotion.reduced(context);

    return Semantics(
      label: [
        for (final m in months)
          '${Fmt.month(m.month)}: ${Fmt.syp(m.syp)}',
      ].join('، '),
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: _plot + 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, m) in months.indexed)
                  Expanded(
                    child: Tooltip(
                      triggerMode: TooltipTriggerMode.tap,
                      message:
                          '${Fmt.month(m.month)}: ${Fmt.syp(m.syp)} · ${Fmt.number(m.orders)} طلب',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (m.syp > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _compact(m.syp),
                                style: AppType.caption.copyWith(
                                  fontSize: 11,
                                  color: i == months.length - 1
                                      ? c.ink
                                      : c.inkTertiary,
                                  fontFeatures: AppType.numeric.fontFeatures,
                                ),
                              ),
                            ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: reduced ? 1 : 0,
                              end: 1,
                            ),
                            duration: const Duration(milliseconds: 650),
                            curve: AppMotion.enter,
                            builder: (context, t, _) => Container(
                              width: 22,
                              height: max == 0
                                  ? 0
                                  : (m.syp / max) * _plot * t,
                              decoration: BoxDecoration(
                                color: i == months.length - 1
                                    ? c.accent
                                    : c.inkTertiary.withValues(alpha: 0.35),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: c.border),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final (i, m) in months.indexed)
                Expanded(
                  child: Text(
                    _short[m.month.month - 1],
                    textAlign: TextAlign.center,
                    style: AppType.caption.copyWith(
                      fontSize: 11,
                      color: i == months.length - 1 ? c.ink : c.inkTertiary,
                      fontWeight: i == months.length - 1
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 10,500 → 10.5K; small values stay whole.
  static String _compact(int v) {
    if (v < 10000) return Fmt.number(v);
    final k = v / 1000;
    return '${k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}K';
  }
}

/// Name, bar, count: one row per part, largest first, bars on one baseline.
/// The track is a lighter step of the bar's own colour.
class _MeterList extends StatelessWidget {
  const _MeterList({required this.rows, required this.total});

  final List<(String, int)> rows;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);
    if (rows.isEmpty) {
      return Text(
        'لسا ما في طلبات مدفوعة.',
        style: AppType.label.copyWith(color: c.inkTertiary),
      );
    }
    return Column(
      children: [
        for (final (i, (name, n)) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Semantics(
            label: '$name: ${Fmt.number(n)} من ${Fmt.number(total)}',
            excludeSemantics: true,
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.label.copyWith(color: c.ink),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      height: 8,
                      color: c.accentSubtle,
                      alignment: AlignmentDirectional.centerStart,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: reduced ? 1 : 0, end: 1),
                        duration: const Duration(milliseconds: 650),
                        curve: AppMotion.enter,
                        builder: (context, t, _) => FractionallySizedBox(
                          widthFactor: total == 0 ? 0 : (n / total) * t,
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    '${Fmt.number(n)}  ·  ${(n * 100 / total).round()}%',
                    textAlign: TextAlign.end,
                    style: AppType.caption.copyWith(
                      color: c.inkSecondary,
                      fontFeatures: AppType.numeric.fontFeatures,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
