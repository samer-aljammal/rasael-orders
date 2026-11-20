import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rasael_orders/features/orders/data/demo_order_repository.dart';
import 'package:rasael_orders/features/orders/data/order_row.dart';
import 'package:rasael_orders/features/orders/domain/gift_kind.dart';
import 'package:rasael_orders/features/orders/domain/order.dart';
import 'package:rasael_orders/features/orders/domain/order_input.dart';
import 'package:rasael_orders/features/orders/domain/order_repository.dart';
import 'package:rasael_orders/features/orders/domain/order_search.dart';
import 'package:rasael_orders/features/orders/domain/order_source.dart';
import 'package:rasael_orders/features/orders/domain/order_status.dart';

void main() {
  final now = DateTime(2026, 11, 20, 15);

  Order order(
    String name, {
    DateTime? at,
    OrderStatus status = OrderStatus.delivered,
    String? phone,
    int price = 1000,
  }) => Order(
    id: name,
    code: 'R-${name.hashCode.abs().toRadixString(36).toUpperCase().padRight(5, '0').substring(0, 5)}',
    kind: GiftKind.letter,
    packageName: 'الأكثر طلباً',
    priceSyp: price,
    status: status,
    customerName: name,
    customerWhatsapp: phone,
    createdAt: at ?? now,
    updatedAt: at ?? now,
  );

  group('order input', () {
    test('codes look like the order form\'s', () {
      final code = OrderInput.newCode(random: Random(1));
      expect(code, matches(RegExp(r'^R-[A-Z0-9]{5}$')));
    });

    test('Syrian numbers get the country code, however they are typed', () {
      expect(OrderInput.whatsapp('0933 123 456'), '963933123456');
      expect(OrderInput.whatsapp('+963 933-123-456'), '963933123456');
      expect(OrderInput.whatsapp('00963933123456'), '963933123456');
      expect(OrderInput.whatsapp('٠٩٣٣١٢٣٤٥٦'), '963933123456');
      expect(OrderInput.whatsapp('49 151 2345 6789'), '4915123456789');
      expect(OrderInput.whatsapp('123'), isNull);
    });

    test('Instagram handles come out bare and lower-case', () {
      expect(OrderInput.instagram('@Rasael.Studio'), 'rasael.studio');
      expect(
        OrderInput.instagram('https://www.instagram.com/rasael.studio/'),
        'rasael.studio',
      );
      expect(OrderInput.instagram('not a handle!'), isNull);
    });

    test('packages follow the live price list', () {
      expect(OrderInput.packagesFor(GiftKind.letter).first.price, 1000);
      expect(OrderInput.packagesFor(GiftKind.wrapped).single.price, 1500);
      expect(
        OrderInput.packagesFor(GiftKind.wedding).map((p) => p.price),
        [1000, 2000, 3500],
      );
    });
  });

  group('search', () {
    test('ignores hamza, taa marbuta and diacritics', () {
      final o = order('فاطمة أحمد');
      expect(OrderSearch.matches(o, 'فاطمه'), isTrue);
      expect(OrderSearch.matches(o, 'احمد'), isTrue);
      expect(OrderSearch.matches(o, 'فَاطِمَة'), isTrue);
      expect(OrderSearch.matches(o, 'سارة'), isFalse);
    });

    test('finds a phone number from its local form', () {
      final o = order('لين', phone: '963933123456');
      expect(OrderSearch.matches(o, '0933 123'), isTrue);
      expect(OrderSearch.matches(o, '0944'), isFalse);
    });

    test('filters by stage and by query together', () {
      final list = [
        order('لين', status: OrderStatus.newOrder),
        order('لينا'),
        order('سامي'),
      ];
      expect(OrderSearch.filter(list, query: 'لين').length, 2);
      expect(
        OrderSearch.filter(list, query: 'لين', status: OrderStatus.delivered)
            .single
            .customerName,
        'لينا',
      );
    });

    test('groups by month, newest first, and counts only paid money', () {
      final groups = OrderSearch.byMonth([
        order('a', at: DateTime(2026, 10, 30)),
        order('b', at: DateTime(2026, 11, 3), price: 1500),
        order('c', at: DateTime(2026, 11, 9), status: OrderStatus.previewSent),
        order('d', at: DateTime(2026, 11, 1), status: OrderStatus.cancelled),
      ]);
      expect(groups.map((g) => g.month.month), [11, 10]);
      expect(groups.first.orders.map((o) => o.customerName), ['c', 'b', 'd']);
      expect(groups.first.earnedSyp, 1500);
    });
  });

  group('creating orders', () {
    OrderDraft draft(String code) => OrderDraft(
      code: code,
      kind: GiftKind.birthday,
      packageName: 'الأكثر طلباً',
      priceSyp: 1000,
      customerName: 'تيم',
      recipientName: 'ريم',
      source: OrderSource.instagram,
      customerInstagram: 'tim.example',
    );

    test('a new order starts at «new» and shows up in the list', () async {
      final repo = DemoOrderRepository(clock: () => now);
      final saved = await repo.create(draft('R-ABCDE'));
      expect(saved.status, OrderStatus.newOrder);
      expect(saved.source, OrderSource.instagram);
      final list = await repo.watchOrders().first;
      expect(list.first.code, 'R-ABCDE');
    });

    test('a taken code is refused', () async {
      final repo = DemoOrderRepository(clock: () => now);
      await repo.create(draft('R-ABCDE'));
      expect(
        () => repo.create(draft('R-ABCDE')),
        throwsA(isA<DuplicateOrderCode>()),
      );
    });

    test('the insert row carries only what the client may set', () {
      final row = OrderRow.fromDraft(draft('R-ABCDE'));
      expect(row['source'], 'instagram');
      expect(row['status'], 'new');
      expect(row.containsKey('owner_id'), isFalse);
      expect(row.containsKey('created_at'), isFalse);
    });
  });
}
