import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rasael_orders/app.dart';
import 'package:rasael_orders/core/di/injector.dart';
import 'package:rasael_orders/core/widgets/primary_button.dart';
import 'package:rasael_orders/features/orders/presentation/order_screen.dart';

/// Runs without SUPABASE_* defines, which is the public demo build.
void main() {
  setUpAll(configureDependencies);

  testWidgets('no backend: sign-in offers only the demo, and it opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const RasaelOrdersApp());
    await tester.pumpAndSettle();

    expect(find.text('دفتر الطلبات'), findsOneWidget);
    expect(find.text('الإيميل'), findsNothing);
    expect(Directionality.of(tester.element(find.text('دفتر الطلبات'))),
        TextDirection.rtl);

    await tester.tap(find.text('افتح النسخة التجريبية'));
    await tester.pumpAndSettle();

    expect(find.text('تجربة'), findsOneWidget);
    expect(find.text('الطلبات المفتوحة'), findsOneWidget);
    expect(find.text('بحاجة انتباهك'), findsOneWidget);

    // Quick add: name, recipient, save. Lands at the top of the open list.
    await tester.tap(find.text('طلب جديد'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'اسم الزبون'),
      'وسام',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'لمين الهدية؟'),
      'هيا',
    );
    await tester.tap(find.text('عيد ميلاد'));
    await tester.pump();
    final save = find.textContaining('ضيف الطلب');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('وسام ← هيا'), findsWidgets);

    // History: the new order is there and search narrows to it.
    await tester.tap(find.textContaining('السجل'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'هيا');
    await tester.pumpAndSettle();
    expect(find.text('وسام ← هيا'), findsOneWidget);
    expect(find.text('كرم ← جود'), findsNothing);

    // Order screen: walk the new order to paid, choosing the payment method.
    await tester.tap(find.text('وسام ← هيا'));
    await tester.pumpAndSettle();
    expect(find.text('الزبون'), findsOneWidget);
    for (final step in ['بلّش الشغل', 'أرسلت المعاينة']) {
      await tester.tap(find.text(step));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('وصل الدفع'));
    await tester.pumpAndSettle();
    expect(find.text('كيف دفع؟'), findsOneWidget);
    await tester.tap(find.text('سيريتل كاش'));
    await tester.pump();
    // The sheet's confirm button sits above the screen's own bottom button.
    await tester.tap(find.widgetWithText(PrimaryButton, 'وصل الدفع').last);
    await tester.pumpAndSettle();
    expect(find.text('سلّمت الرابط'), findsOneWidget);

    // At «paid» the link reply is offered, filled with her name, and warns
    // that the page link is still missing.
    expect(find.text('الرابط بعد الدفع'), findsOneWidget);
    expect(find.textContaining('هاد رابط رسالة هيا'), findsOneWidget);
    expect(find.text('ناقص: رابط الصفحة'), findsOneWidget);

    // The timeline at the bottom records how they paid.
    final orderScroll = find
        .descendant(
          of: find.byType(OrderScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('وصل الدفع · سيريتل كاش'),
      300,
      scrollable: orderScroll,
    );
    expect(find.text('وصل الدفع · سيريتل كاش'), findsOneWidget);
  });
}
