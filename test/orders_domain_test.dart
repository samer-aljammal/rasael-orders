import 'package:flutter_test/flutter_test.dart';
import 'package:rasael_orders/core/utils/formatters.dart';
import 'package:rasael_orders/features/orders/data/demo_order_repository.dart';
import 'package:rasael_orders/features/orders/data/order_row.dart';
import 'package:rasael_orders/features/orders/domain/gift_kind.dart';
import 'package:rasael_orders/features/orders/domain/order.dart';
import 'package:rasael_orders/features/orders/domain/order_status.dart';

void main() {
  final now = DateTime(2026, 11, 20, 15);

  Order order({
    OrderStatus status = OrderStatus.inProgress,
    DateTime? deadline,
    DateTime? previewSentAt,
  }) => Order(
    id: 'x',
    code: 'R-TEST1',
    kind: GiftKind.letter,
    packageName: 'الأكثر طلباً',
    priceSyp: 1000,
    status: status,
    customerName: 'لين',
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now.subtract(const Duration(days: 1)),
    deadline: deadline,
    previewSentAt: previewSentAt,
  );

  group('attention', () {
    test('a passed deadline is late', () {
      final o = order(deadline: now.subtract(const Duration(minutes: 1)));
      expect(o.attentionAt(now), Attention.late);
    });

    test('a deadline later today is due today', () {
      final o = order(deadline: DateTime(2026, 11, 20, 22));
      expect(o.attentionAt(now), Attention.dueToday);
    });

    test('a deadline tomorrow needs nothing', () {
      final o = order(deadline: DateTime(2026, 11, 21, 9));
      expect(o.attentionAt(now), isNull);
    });

    test('an unpaid preview older than 48h needs a follow-up', () {
      final o = order(
        status: OrderStatus.previewSent,
        previewSentAt: now.subtract(const Duration(hours: 49)),
      );
      expect(o.attentionAt(now), Attention.followUp);
    });

    test('a fresh unpaid preview needs nothing', () {
      final o = order(
        status: OrderStatus.previewSent,
        previewSentAt: now.subtract(const Duration(hours: 3)),
      );
      expect(o.attentionAt(now), isNull);
    });

    test('delivered and cancelled orders are never late', () {
      final past = now.subtract(const Duration(days: 2));
      expect(
        order(status: OrderStatus.delivered, deadline: past).attentionAt(now),
        isNull,
      );
      expect(
        order(status: OrderStatus.cancelled, deadline: past).attentionAt(now),
        isNull,
      );
    });
  });

  group('pipeline', () {
    test('runs new → in progress → preview → paid → delivered', () {
      final visited = <OrderStatus>[];
      OrderStatus? s = OrderStatus.newOrder;
      while (s != null) {
        visited.add(s);
        s = s.next;
      }
      expect(visited, OrderStatus.pipeline);
    });

    test('every stage with a next stage has a verb for it', () {
      for (final s in OrderStatus.values) {
        expect(s.next == null, s.nextAction == null, reason: s.name);
      }
    });

    test('movedTo stamps the same timestamps as the database trigger', () {
      final at = now;
      final o = order().movedTo(OrderStatus.previewSent, at);
      expect(o.previewSentAt, at);
      final paid = o.movedTo(OrderStatus.paid, at.add(const Duration(hours: 1)));
      expect(paid.paidAt, at.add(const Duration(hours: 1)));
      expect(paid.previewSentAt, at, reason: 'earlier stamps are kept');
    });
  });

  group('database row', () {
    test('round-trips every writable column', () {
      final o = Order(
        id: 'id-1',
        code: 'R-K3F9A',
        kind: GiftKind.wedding,
        packageName: 'مميز',
        priceSyp: 3500,
        status: OrderStatus.newOrder,
        customerName: 'أم سامر',
        customerWhatsapp: '963900000123',
        senderName: 'سامر',
        recipientName: 'لمى',
        deadline: DateTime.utc(2026, 11, 22, 18).toLocal(),
        details: const [OrderDetail('الصالة', 'صالة الياسمين، دمشق')],
        hasPhotos: true,
        createdAt: now,
        updatedAt: now,
      );
      final row = {
        ...OrderRow.toInsert(o),
        'id': 'id-1',
        'created_at': now.toUtc().toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
      };
      final back = OrderRow.fromRow(row);
      expect(back.code, o.code);
      expect(back.kind, GiftKind.wedding);
      expect(back.priceSyp, 3500);
      expect(back.deadline, o.deadline);
      expect(back.details, o.details);
      expect(back.hasPhotos, isTrue);
      expect(back.headline, 'سامر ← لمى');
    });

    test('unknown kinds fall back to other instead of crashing', () {
      expect(GiftKind.fromId('valentine'), GiftKind.other);
    });
  });

  group('demo repository', () {
    test('moving an order re-emits the list with the new stage', () async {
      final repo = DemoOrderRepository(clock: () => now);
      final emissions = repo.watchOrders();
      final first = await emissions.first;
      final target = first.firstWhere((o) => o.status == OrderStatus.newOrder);

      final next = repo.watchOrders().skip(1).first;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await repo.moveTo(target.id, OrderStatus.inProgress);
      final updated = (await next).firstWhere((o) => o.id == target.id);
      expect(updated.status, OrderStatus.inProgress);
    });

    test('seeds no real-looking phone numbers', () async {
      final orders = await DemoOrderRepository(clock: () => now)
          .watchOrders()
          .first;
      for (final o in orders) {
        expect(o.customerWhatsapp, startsWith('963900000'));
      }
    });
  });

  test('order codes stay left-to-right inside Arabic text', () {
    final s = Fmt.ltr('R-K3F9A');
    expect(s.codeUnitAt(0), 0x2066);
    expect(s.codeUnitAt(s.length - 1), 0x2069);
    expect(Fmt.syp(1500), '1,500 ل.س');
  });
}
