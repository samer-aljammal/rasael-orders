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
  });
}
