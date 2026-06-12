import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/data/datasources/local_hadith_data_source.dart';
import 'package:deenhub/data/datasources/local_quran_data_source.dart';
import 'package:deenhub/data/datasources/local_tafsir_data_source.dart';
import 'package:deenhub/data/repositories/hadith_repository_impl.dart';
import 'package:deenhub/data/repositories/quran_repository_impl.dart';
import 'package:deenhub/data/repositories/tafsir_repository_impl.dart';
import 'package:deenhub/main.dart';

/// اختبارات سير عمل الحديث بالمصادر المحلية فقط (دون شبكة).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() => DeenHubApp(
        quranRepository: QuranRepositoryImpl(local: LocalQuranDataSource()),
        tafsirRepository:
            TafsirRepositoryImpl(local: LocalTafsirDataSource()),
        hadithRepository:
            HadithRepositoryImpl(local: LocalHadithDataSource()),
      );

  Future<void> openHadithBooks(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.hadith).first);
    await tester.pumpAndSettle();
  }

  /// مقتطف من نص الحديث ٦٦٥١٢ مأخوذ من البيانات المضمَّنة نفسها
  /// لتجنب حساسية ترتيب علامات التشكيل في النص المكتوب يدوياً.
  Future<String> hadithTextNeedle() async {
    final hadith = await LocalHadithDataSource().fetchHadith('66512');
    return hadith.textArabic.substring(0, 20);
  }

  Future<void> openFirstAqeedahHadith(WidgetTester tester) async {
    await openHadithBooks(tester);
    await tester.tap(find.text('العقيدة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإيمان بالله عز وجل'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('بني الإسلام على خمس'));
    await tester.pumpAndSettle();
  }

  testWidgets('browse books, chapters and hadith list', (tester) async {
    await openHadithBooks(tester);

    // كتب الموسوعة معروضة
    expect(find.text('العقيدة'), findsOneWidget);
    expect(find.text('الحديث وعلومه'), findsOneWidget);

    // فتح كتاب → الأبواب
    await tester.tap(find.text('الحديث وعلومه'));
    await tester.pumpAndSettle();
    expect(find.text('مصطلح الحديث'), findsOneWidget);

    // فتح باب → قائمة الأحاديث
    await tester.tap(find.text('مصطلح الحديث'));
    await tester.pumpAndSettle();
    expect(find.textContaining('المسلسل بقراءة سورة الصف'), findsOneWidget);
  });

  testWidgets('hadith detail shows text, grade and full attribution',
      (tester) async {
    await openFirstAqeedahHadith(tester);

    // العنوان والنص العربي والدرجة والعزو
    expect(find.text('بني الإسلام على خمس'), findsOneWidget);
    expect(find.textContaining(await hadithTextNeedle()), findsWidgets);
    expect(find.text('صحيح'), findsWidgets);
    expect(find.textContaining('رواه البخاري'), findsWidgets);

    // الراوي
    expect(find.textContaining(AppStrings.narratorLabel), findsOneWidget);

    // بطاقة الإسناد أسفل الصفحة: المصدر، رقم الحديث، المرجع، الرابط
    await tester.scrollUntilVisible(
      find.textContaining('HadeethEnc'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('HadeethEnc'), findsOneWidget);
    expect(find.textContaining('66512'), findsWidgets);
    expect(find.textContaining('hadeethenc.com'), findsOneWidget);
  });

  testWidgets('favorite and last read persist locally', (tester) async {
    await openFirstAqeedahHadith(tester);

    await tester.tap(find.byTooltip(AppStrings.addToFavorites));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorites'), contains('hadith:66512'));
    // آخر حديث مقروء حُفظ تلقائياً عند الفتح
    expect(prefs.getString('hadith_last_read_id'), '66512');

    // العودة إلى شاشة الكتب: بطاقة متابعة القراءة ظاهرة
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.continueReading), findsOneWidget);
  });

  testWidgets('search finds hadiths by text and narrator in Arabic',
      (tester) async {
    await openHadithBooks(tester);

    await tester.tap(find.byTooltip(AppStrings.searchInHadith));
    await tester.pumpAndSettle();

    // بحث بنص الحديث دون تشكيل
    await tester.enterText(find.byType(TextField), 'بني الاسلام على خمس');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    final needle = await hadithTextNeedle();
    expect(find.textContaining(needle), findsWidgets);

    // فتح النتيجة → التفاصيل بالإسناد
    await tester.tap(find.textContaining(needle).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('HadeethEnc'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('HadeethEnc'), findsOneWidget);
  });

  testWidgets('favorites screen shows favorited hadith', (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['hadith:66512'],
    });
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.favorites));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.favoriteHadiths), findsOneWidget);
    expect(find.textContaining(await hadithTextNeedle()), findsOneWidget);
  });
}
