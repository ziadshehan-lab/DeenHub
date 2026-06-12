import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/main.dart';

/// اختبار حفظ عدّاد المسبحة واستئنافه بين الجلسات.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openTasbih(WidgetTester tester) async {
    await tester.pumpWidget(const DeenHubApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tasbih));
    await tester.pumpAndSettle();
  }

  testWidgets('tasbih count persists and is restored across sessions',
      (tester) async {
    await openTasbih(tester);
    expect(find.text('٠'), findsOneWidget);

    // ثلاث تسبيحات
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('٣'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('tasbih_count'), 3);

    // «جلسة جديدة»: يستأنف العدّاد من القيمة المحفوظة
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const DeenHubApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tasbih));
    await tester.pumpAndSettle();
    expect(find.text('٣'), findsOneWidget);

    // إعادة التعيين تُحفظ أيضاً
    await tester.tap(find.byTooltip(AppStrings.reset));
    await tester.pumpAndSettle();
    expect(find.text('٠'), findsOneWidget);
    expect(prefs.getInt('tasbih_count'), 0);
  });
}
