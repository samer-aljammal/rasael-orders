import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/states.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../domain/order.dart';
import 'orders_cubit.dart';
import 'widgets/attention_hero.dart';
import 'widgets/order_line.dart';
import 'widgets/stage_sheet.dart';

/// Home: what needs attention, then every open order.
///
/// Day 1 of the build. Stage tabs, search and the full order screen arrive
/// with the pipeline work; this screen already runs on live data.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, this.onResetDemo});

  final VoidCallback? onResetDemo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) => switch (state) {
                OrdersLoading() => const _Frame(child: OrdersSkeleton()),
                OrdersError(:final message) => _Frame(
                  child: ErrorPanel(
                    message: message,
                    onRetry: context.read<OrdersCubit>().retry,
                  ),
                ),
                OrdersLoaded() => _Loaded(state, onResetDemo: onResetDemo),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _TopBar(),
      Expanded(child: child),
    ],
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onResetDemo});
  final VoidCallback? onResetDemo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.select((AuthCubit a) => a.state.user);
    final demo = user?.isDemo ?? false;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Wordmark(size: 20),
          const Spacer(),
          if (demo)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: c.borderStrong),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'نسخة تجريبية',
                style: AppType.caption.copyWith(color: c.inkSecondary),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'القائمة',
            icon: Icon(Icons.more_horiz_rounded, color: c.inkSecondary),
            position: PopupMenuPosition.under,
            onSelected: (v) => switch (v) {
              'reset' => onResetDemo?.call(),
              _ => context.read<AuthCubit>().signOut(),
            },
            itemBuilder: (_) => [
              if (demo && onResetDemo != null)
                const PopupMenuItem(
                  value: 'reset',
                  child: Text('رجّع الطلبات التجريبية'),
                ),
              PopupMenuItem(
                value: 'out',
                child: Text(demo ? 'اطلع من التجربة' : 'تسجيل الخروج'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded(this.state, {this.onResetDemo});

  final OrdersLoaded state;
  final VoidCallback? onResetDemo;

  void _openStage(BuildContext context, Order order) {
    final cubit = context.read<OrdersCubit>();
    StageSheet.show(
      context,
      order: order,
      now: state.now,
      onAdvance: () async {
        await cubit.moveForward(order);
        HapticFeedback.lightImpact();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final urgent = state.needsAttention;
    final open = state.open;
    final deliveredThisWeek = state.orders
        .where(
          (o) =>
              o.deliveredAt != null &&
              state.now.difference(o.deliveredAt!) < const Duration(days: 7),
        )
        .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _TopBar(onResetDemo: onResetDemo)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            0,
          ),
          sliver: SliverList.list(
            children: [
              Reveal(
                child: Text(
                  _greeting(state.now),
                  style: AppType.headline.copyWith(color: c.ink),
                ),
              ),
              Reveal(
                index: 1,
                child: Text(
                  _date(state.now),
                  style: AppType.label.copyWith(color: c.inkTertiary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Reveal(
                index: 2,
                child: AttentionHero(
                  urgent: urgent,
                  openCount: open.length,
                  now: state.now,
                  onOpen: (o) => _openStage(context, o),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              Reveal(
                index: 3,
                child: Row(
                  children: [
                    Text(
                      'الطلبات المفتوحة',
                      style: AppType.section.copyWith(color: c.inkSecondary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Fmt.number(open.length),
                      style: AppType.section.copyWith(
                        color: c.inkTertiary,
                        fontFeatures: AppType.numeric.fontFeatures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
        if (open.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyPanel(
              title: 'ما في ولا طلب مفتوح',
              body:
                  'لما يوصل طلب جديد عالواتساب، الصقه هون وبيطلع بأول القائمة.',
            ),
          )
        else
          SliverList.separated(
            itemCount: open.length,
            separatorBuilder: (_, _) => Divider(
              indent: AppSpacing.screen,
              endIndent: AppSpacing.screen,
              color: c.border,
            ),
            itemBuilder: (context, i) => Reveal(
              index: 4 + i,
              child: OrderLine(
                order: open[i],
                now: state.now,
                onTap: () => _openStage(context, open[i]),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xl,
            AppSpacing.screen,
            AppSpacing.xxxl,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              deliveredThisWeek.isEmpty
                  ? 'ما في طلبات مسلّمة هالأسبوع لسا.'
                  : 'سلّمت ${Fmt.number(deliveredThisWeek.length)} هالأسبوع'
                        ' بـ ${Fmt.syp(deliveredThisWeek.fold<int>(0, (s, o) => s + o.priceSyp))}.',
              style: AppType.label.copyWith(color: c.inkTertiary),
            ),
          ),
        ),
      ],
    );
  }

  static String _greeting(DateTime now) =>
      now.hour < 12 ? 'صباح الخير' : 'مسا الخير';

  static const _days = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد', //
  ];

  static String _date(DateTime now) =>
      '${_days[now.weekday - 1]}، ${Fmt.dayMonth(now)}';
}
