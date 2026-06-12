import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/data/datasources/local_quran_data_source.dart';
import 'package:deenhub/data/repositories/quran_repository_impl.dart';
import 'package:deenhub/main.dart';

/// اختبارات سير عمل وحدة القرآن باستخدام المصدر المحلي فقط
/// (دون أي طلبات شبكة).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() => DeenHubApp(
        quranRepository: QuranRepositoryImpl(local: LocalQuranDataSource()),
      );

  Future<void> openQuranScreen(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.quran).first);
    await tester.pumpAndSettle();
  }

  testWidgets('Quran screen lists all surahs', (tester) async {
    await openQuranScreen(tester);

    expect(find.textContaining('ٱلْفَاتِحَةِ'), findsOneWidget);
    expect(find.text('Al-Faatiha'), findsOneWidget);
    // عدد الآيات والمكان معروضان
    expect(find.textContaining('مكية'), findsWidgets);
  });

  testWidgets('opening a surah shows its ayahs with basmala header',
      (tester) async {
    await openQuranScreen(tester);

    // فتح سورة الإخلاص (التمرير إليها ثم النقر)
    await tester.scrollUntilVisible(
      find.text('Al-Ikhlaas'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Al-Ikhlaas'));
    await tester.pumpAndSettle();

    // البسملة في الرأس + أول آية ظاهرة (الآية ١ والآية ٤ تنتهيان بـ"أحد")
    expect(find.textContaining('بِسْمِ'), findsWidgets);
    expect(find.textContaining('قُلْ هُوَ'), findsOneWidget);
    expect(find.textContaining('أَحَدٌ'), findsWidgets);
  });

  testWidgets('tapping an ayah allows favoriting it and saving last read',
      (tester) async {
    await openQuranScreen(tester);

    await tester.scrollUntilVisible(
      find.text('Al-Ikhlaas'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Al-Ikhlaas'));
    await tester.pumpAndSettle();

    // فتح ورقة إجراءات أول آية
    await tester.tap(find.textContaining('قُلْ هُوَ'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.addToFavorites), findsOneWidget);

    // إضافة إلى المفضلة
    await tester.tap(find.text(AppStrings.addToFavorites));
    await tester.pumpAndSettle();

    // تحديد موضع القراءة
    await tester.tap(find.textContaining('قُلْ هُوَ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.setAsLastRead));
    await tester.pumpAndSettle();

    // العودة إلى قائمة السور: بطاقة متابعة القراءة ظاهرة أعلى القائمة
    // (pageBack لا يجد زر الرجوع لأن تلميحه معرّب، والقائمة ما تزال
    // عند موضع التمرير السابق فنمرر إلى الأعلى)
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.continueReading),
      -600,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.continueReading), findsOneWidget);

    // المفضلة محفوظة في التخزين المحلي
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorites'), contains('ayah:112:1'));
    expect(prefs.getInt('quran_last_read_surah'), 112);
    expect(prefs.getInt('quran_last_read_ayah'), 1);
  });

  testWidgets('favorites screen shows favorited ayah', (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['ayah:112:1'],
    });
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.favorites));
    await tester.pumpAndSettle();

    expect(find.textContaining('أَحَدٌ'), findsOneWidget);
  });

  testWidgets('search finds ayahs without diacritics', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'قل هو الله احد');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.textContaining('أَحَدٌ'), findsWidgets);
  });
}
