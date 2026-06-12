import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app starts on home screen in RTL', (tester) async {
    await tester.pumpWidget(const DeenHubApp());
    await tester.pumpAndSettle();

    // عنوان التطبيق ظاهر في الشاشة الرئيسية
    expect(find.text(AppStrings.appName), findsOneWidget);

    // الاتجاه من اليمين إلى اليسار مفعّل
    final context = tester.element(find.text(AppStrings.appName));
    expect(Directionality.of(context), TextDirection.rtl);

    // أقسام رئيسية ظاهرة
    expect(find.text(AppStrings.quran), findsOneWidget);
    expect(find.text(AppStrings.adhkar), findsOneWidget);
  });
}
