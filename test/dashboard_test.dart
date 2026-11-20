import 'package:flutter_test/flutter_test.dart';
import 'package:rasael_orders/features/dashboard/domain/business_stats.dart';
import 'package:rasael_orders/features/orders/domain/gift_kind.dart';
import 'package:rasael_orders/features/orders/domain/order.dart';
import 'package:rasael_orders/features/orders/domain/order_source.dart';
import 'package:rasael_orders/features/orders/domain/order_status.dart';

void main() {
  final now = DateTime(2026, 11, 20, 12);
  var n = 0;

  Order o(
    int price,
    OrderStatus status, {
    DateTime? paid,
    OrderSource? source = OrderSource.instagram,
    GiftKind kind = GiftKind.letter,
  }) {
    n++;
    final created = paid ?? now;
    return Order(
      id: '$n',
      code: 'R-T000$n',
      kind: kind,
      packageName: 'p',
      priceSyp: price,
      status: status,
      customerName: 'c',
      source: source,
      createdAt: created,
      updatedAt: created,
      paidAt: paid,
    );
  }

  test('income counts only paid money, in the month it was paid', () {
    final s = BusinessStats.compute([
      o(1500, OrderStatus.delivered, paid: DateTime(2026, 11, 3)),
      o(1000, OrderStatus.paid, paid: DateTime(2026, 11, 10)),
      o(1000, OrderStatus.delivered, paid: DateTime(2026, 10, 29)),
      o(1500, OrderStatus.previewSent),
      o(1000, OrderStatus.cancelled),
      o(1000, OrderStatus.newOrder),
    ], now);

    expect(s.thisMonth.syp, 2500);
    expect(s.thisMonth.orders, 2);
    expect(s.lastMonth.syp, 1000);
    expect(s.totalSyp, 3500);
    expect(s.paidCount, 3);
    expect(s.averageSyp, 1167);
    expect(s.awaitingSyp, 1500);
    expect(s.awaitingCount, 1);
  });

  test('six months shown, oldest first, empty months kept', () {
    final s = BusinessStats.compute([
      o(1000, OrderStatus.delivered, paid: DateTime(2026, 11, 1)),
    ], now);
    expect(s.months.length, 6);
    expect(s.months.first.month, DateTime(2026, 6));
    expect(s.months.last.month, DateTime(2026, 11));
    expect(s.months.where((m) => m.syp == 0).length, 5);
  });

  test('months roll over the year boundary', () {
    final s = BusinessStats.compute(const [], DateTime(2027, 2, 1));
    expect(s.months.first.month, DateTime(2026, 9));
    expect(s.lastMonth.month, DateTime(2027, 1));
  });

  test('channels and kinds are ranked, unknown channel kept apart', () {
    final s = BusinessStats.compute([
      o(1000, OrderStatus.delivered, paid: now),
      o(1000, OrderStatus.delivered, paid: now),
      o(1000, OrderStatus.delivered, paid: now, source: OrderSource.whatsapp),
      o(1000, OrderStatus.delivered, paid: now, source: null, kind: GiftKind.sorry),
    ], now);
    expect(s.bySource.first, (OrderSource.instagram, 2));
    expect(s.bySource.map((e) => e.$1), contains(null));
    expect(s.byKind.first, (GiftKind.letter, 3));
  });

  test('no orders means an empty dashboard, not a page of zeros', () {
    expect(BusinessStats.compute(const [], now).isEmpty, isTrue);
  });
}
