import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/data/datasources/local_quran_data_source.dart';
import 'package:deenhub/data/datasources/local_tafsir_data_source.dart';
import 'package:deenhub/data/repositories/quran_repository_impl.dart';
import 'package:deenhub/data/repositories/tafsir_repository_impl.dart';
import 'package:deenhub/main.dart';

/// اختبار سير عمل التفسير من ورقة إجراءات الآية، بالمصادر المحلية فقط.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() => DeenHubApp(
        quranRepository: QuranRepositoryImpl(local: LocalQuranDataSource()),
        tafsirRepository:
            TafsirRepositoryImpl(local: LocalTafsirDataSource()),
      );

  testWidgets('view tafsir from ayah actions sheet shows text and attribution',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // فتح سورة الإخلاص
    await tester.tap(find.text(AppStrings.quran).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Al-Ikhlaas'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Al-Ikhlaas'));
    await tester.pumpAndSettle();

    // ورقة إجراءات أول آية → عرض التفسير
    await tester.tap(find.textContaining('قُلْ هُوَ'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.viewTafsir), findsOneWidget);
    await tester.tap(find.text(AppStrings.viewTafsir));
    await tester.pumpAndSettle();

    // نص تفسير السعدي للآية ١١٢:١ ظاهر (من البيانات المحلية)
    expect(find.textContaining('الأحدية'), findsOneWidget);

    // الإسناد: الكتاب، العالِم، المصدر، المرجع
    expect(find.textContaining('تفسير السعدي'), findsWidgets);
    expect(find.textContaining('عبد الرحمن بن ناصر السعدي'), findsOneWidget);
    expect(find.textContaining('quran.com'), findsOneWidget);
    expect(find.textContaining('ar-tafseer-al-saddi'), findsOneWidget);

    // كتب التفسير الخمسة معروضة كخيارات، والجلالين معطّل بوسم «قريباً»
    expect(find.textContaining('تفسير ابن كثير'), findsOneWidget);
    expect(find.textContaining('تفسير الطبري'), findsOneWidget);
    expect(find.textContaining('تفسير القرطبي'), findsOneWidget);
    expect(
      find.textContaining(AppStrings.tafsirComingSoon),
      findsOneWidget,
    );
  });

  testWidgets('tafsir screen lists supported editions from data source',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tafsir));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.availableEditions), findsOneWidget);
    expect(find.text('تفسير السعدي'), findsOneWidget);
    expect(find.text('تفسير الجلالين'), findsOneWidget);
    expect(find.textContaining('عبد الرحمن بن ناصر السعدي'), findsOneWidget);
  });
}
