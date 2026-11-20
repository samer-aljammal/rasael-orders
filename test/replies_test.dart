import 'package:flutter_test/flutter_test.dart';
import 'package:rasael_orders/features/orders/domain/gift_kind.dart';
import 'package:rasael_orders/features/orders/domain/order.dart';
import 'package:rasael_orders/features/orders/domain/order_status.dart';
import 'package:rasael_orders/features/replies/data/default_replies.dart';
import 'package:rasael_orders/features/replies/data/demo_reply_repository.dart';
import 'package:rasael_orders/features/replies/domain/reply_template.dart';

void main() {
  final at = DateTime(2026, 11, 20);
  Order order({String? link, String? to = 'يقين', int price = 1000}) => Order(
    id: 'x',
    code: 'R-K3F9A',
    kind: GiftKind.letter,
    packageName: 'الأكثر طلباً',
    priceSyp: price,
    status: OrderStatus.paid,
    customerName: 'حمودة',
    recipientName: to,
    pageUrl: link,
    createdAt: at,
    updatedAt: at,
  );

  ReplyTemplate t(String body, [OrderStatus? stage]) =>
      ReplyTemplate(id: body, title: 't', body: body, stage: stage);

  test('prices are written the way the customer messages write them', () {
    expect(ReplyFill.price(1000), '١٬٠٠٠ ل.س');
    expect(ReplyFill.price(1500), '١٬٥٠٠ ل.س');
    expect(ReplyFill.price(500), '٥٠٠ ل.س');
    expect(ReplyFill.price(35000), '٣٥٬٠٠٠ ل.س');
  });

  test('fills names, price, link and code', () {
    final f = ReplyFill.fill(
      t('هاد رابط رسالة {لمين}:\n{الرابط}\nبتحوّل {السعر} · {الكود}'),
      order(link: 'https://rasaelstudio.github.io/yaqeen-1102/'),
    );
    expect(f.complete, isTrue);
    expect(
      f.text,
      'هاد رابط رسالة يقين:\nhttps://rasaelstudio.github.io/yaqeen-1102/\n'
      'بتحوّل ١٬٠٠٠ ل.س · R-K3F9A',
    );
  });

  test('a missing link stays a visible gap and is reported', () {
    final f = ReplyFill.fill(t('{الرابط}'), order());
    expect(f.complete, isFalse);
    expect(f.missing, [ReplyField.link]);
    expect(f.text, '[رابط الصفحة]');
  });

  test('stage replies come first, general ones after', () {
    final list = ReplyFill.forStage([
      t('general'),
      t('delivered', OrderStatus.delivered),
      t('paid', OrderStatus.paid),
    ], OrderStatus.paid);
    expect(list.map((x) => x.body), ['paid', 'general']);
  });

  test('every pipeline stage has a default reply', () {
    final stages = defaultReplies.map((r) => r.$2).toSet();
    for (final s in OrderStatus.pipeline) {
      expect(stages, contains(s), reason: s.label);
    }
  });

  test('default replies only use blanks the app knows how to fill', () {
    final known = ReplyField.values.map((f) => f.token).toSet();
    for (final (title, _, body) in defaultReplies) {
      for (final m in RegExp(r'\{[^}]+\}').allMatches(body)) {
        expect(known, contains(m[0]), reason: title);
      }
    }
  });

  test('demo replies can be added, edited and deleted', () async {
    final repo = DemoReplyRepository();
    final start = await repo.watch().first;
    await repo.add(title: 'جديد', body: 'نص', stage: OrderStatus.newOrder);
    var now = await repo.watch().first;
    expect(now.length, start.length + 1);
    final added = now.last;
    await repo.update(added.copyWith(body: 'نص معدّل'));
    now = await repo.watch().first;
    expect(now.last.body, 'نص معدّل');
    await repo.delete(added.id);
    expect((await repo.watch().first).length, start.length);
  });
}
