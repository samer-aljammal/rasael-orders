import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/money.dart';
import '../../../core/widgets/states.dart';
import '../domain/order.dart';
import '../domain/order_search.dart';
import '../domain/order_status.dart';
import 'orders_cubit.dart';
import 'widgets/order_line.dart';

/// Every order ever, newest first, grouped by month like a ledger, with a
/// search that understands how Arabic names actually get typed.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _search = TextEditingController();
  OrderStatus? _status;

  /// Filter order: all, then the pipeline, then cancelled at the end.
  static const _filters = <OrderStatus?>[
    null,
    ...OrderStatus.pipeline,
    OrderStatus.cancelled,
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('السجل'),
        titleSpacing: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) => switch (state) {
              OrdersLoading() => const OrdersSkeleton(),
              OrdersError(:final message) => ErrorPanel(
                message: message,
                onRetry: context.read<OrdersCubit>().retry,
              ),
              OrdersLoaded() => _body(context, state, c),
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, OrdersLoaded state, RasaelColors c) {
    final query = _search.text;
    final shown = OrderSearch.filter(state.orders, status: _status, query: query);
    final groups = OrderSearch.byMonth(shown);
    // Counts follow the search, so the chips say what each filter would show.
    final searched = OrderSearch.filter(state.orders, query: query);
    int count(OrderStatus? s) =>
        s == null ? searched.length : searched.where((o) => o.status == s).length;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'دوّر باسم، رقم، أو كود',
                fillColor: c.surfaceAlt,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'امسح',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(_search.clear),
                      ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.sm,
              ),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final s = _filters[i];
                return ChoicePill(
                  label: s?.label ?? 'الكل',
                  trailing: Fmt.number(count(s)),
                  selected: _status == s,
                  onTap: () => setState(() => _status = s),
                );
              },
            ),
          ),
        ),
        if (groups.isEmpty)
          SliverToBoxAdapter(
            child: EmptyPanel(
              title: query.isEmpty ? 'ما في طلبات هون' : 'ما لقينا شي',
              body: query.isEmpty
                  ? 'لما تمشي الطلبات بالمراحل، بتلاقيها هون.'
                  : 'جرّب جزء من الاسم، أو آخر كم رقم من الموبايل.',
            ),
          ),
        for (final g in groups) ...[
          SliverToBoxAdapter(child: _MonthHeader(group: g, now: state.now)),
          SliverList.separated(
            itemCount: g.orders.length,
            separatorBuilder: (_, _) => Divider(
              indent: AppSpacing.screen,
              endIndent: AppSpacing.screen,
              color: c.border,
            ),
            itemBuilder: (context, i) => OrderLine(
              order: g.orders[i],
              now: state.now,
              showDate: true,
              onTap: () => _open(context, g.orders[i], state.now),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }

  void _open(BuildContext context, Order order, DateTime now) =>
      context.push(Routes.order(order.id));
}

/// «تشرين الثاني · 14 طلب ........ 18,500 ل.س»
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.group, required this.now});

  final MonthGroup group;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = group.orders.length;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderStrong)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Fmt.month(group.month, now: now),
                    style: AppType.subtitle.copyWith(color: c.ink),
                  ),
                  TextSpan(
                    text: '   ${switch (n) {
                      1 => 'طلب واحد',
                      2 => 'طلبين',
                      <= 10 => '${Fmt.number(n)} طلبات',
                      _ => '${Fmt.number(n)} طلب',
                    }}',
                    style: AppType.caption.copyWith(color: c.inkTertiary),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (group.earnedSyp > 0)
            Tooltip(
              message: 'المدفوع والمسلَّم بس',
              child: Money(
                group.earnedSyp,
                style: AppType.numeric.copyWith(color: c.inkSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
