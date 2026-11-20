import '../../orders/domain/gift_kind.dart';
import '../../orders/domain/order.dart';
import '../../orders/domain/order_source.dart';
import '../../orders/domain/order_status.dart';

/// One month of income.
class MonthIncome {
  const MonthIncome(this.month, this.syp, this.orders);

  /// First day of the month.
  final DateTime month;
  final int syp;
  final int orders;
}

/// The numbers the dashboard shows, computed from the order list alone.
///
/// "Income" means money actually received: orders that reached paid or
/// delivered, counted in the month they were paid. Previews nobody paid
/// for and cancelled orders never count.
class BusinessStats {
  const BusinessStats._({
    required this.thisMonth,
    required this.lastMonth,
    required this.totalSyp,
    required this.paidCount,
    required this.awaitingSyp,
    required this.awaitingCount,
    required this.months,
    required this.bySource,
    required this.byKind,
  });

  final MonthIncome thisMonth;
  final MonthIncome lastMonth;
  final int totalSyp;
  final int paidCount;

  /// Previews sent and not yet paid: money that may still come in.
  final int awaitingSyp;
  final int awaitingCount;

  /// The last [monthsShown] months, oldest first, empty months included so
  /// the chart's spacing is honest.
  final List<MonthIncome> months;

  /// Paid orders per channel, most first. Null = not recorded.
  final List<(OrderSource?, int)> bySource;

  /// Paid orders per kind, most first.
  final List<(GiftKind, int)> byKind;

  static const monthsShown = 6;

  int get averageSyp => paidCount == 0 ? 0 : (totalSyp / paidCount).round();

  bool get isEmpty => paidCount == 0 && awaitingCount == 0;

  static bool _isPaid(Order o) =>
      o.status == OrderStatus.paid || o.status == OrderStatus.delivered;

  /// When the money arrived. Falls back to the creation date for paid
  /// orders that never had a payment time recorded.
  static DateTime _paidOn(Order o) => o.paidAt ?? o.createdAt;

  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  factory BusinessStats.compute(List<Order> orders, DateTime now) {
    final paid = orders.where(_isPaid).toList();
    final awaiting = orders
        .where((o) => o.status == OrderStatus.previewSent)
        .toList();

    MonthIncome monthFor(DateTime m) {
      final inMonth = paid.where((o) => _monthOf(_paidOn(o)) == m);
      return MonthIncome(
        m,
        inMonth.fold(0, (s, o) => s + o.priceSyp),
        inMonth.length,
      );
    }

    final current = _monthOf(now);
    final months = [
      for (var i = monthsShown - 1; i >= 0; i--)
        monthFor(DateTime(current.year, current.month - i)),
    ];

    List<(T, int)> countBy<T>(T Function(Order) key) {
      final counts = <T, int>{};
      for (final o in paid) {
        counts.update(key(o), (n) => n + 1, ifAbsent: () => 1);
      }
      return counts.entries.map((e) => (e.key, e.value)).toList()
        ..sort((a, b) => b.$2.compareTo(a.$2));
    }

    return BusinessStats._(
      thisMonth: months.last,
      lastMonth: months[months.length - 2],
      totalSyp: paid.fold(0, (s, o) => s + o.priceSyp),
      paidCount: paid.length,
      awaitingSyp: awaiting.fold(0, (s, o) => s + o.priceSyp),
      awaitingCount: awaiting.length,
      months: months,
      bySource: countBy((o) => o.source),
      byKind: countBy((o) => o.kind),
    );
  }
}
