import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rasael_orders/app.dart';
import 'package:rasael_orders/core/di/injector.dart';

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

    expect(find.text('نسخة تجريبية'), findsOneWidget);
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
  });
}
