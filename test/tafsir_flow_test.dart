import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/data/datasources/local_quran_data_source.dart';
import 'package:deenhub/data/datasources/local_tafsir_data_source.dart';
import 'package:deenhub/data/repositories/quran_repository_impl.dart';
import 'package:deenhub/data/repositories/tafsir_repository_impl.dart';
import 'package:deenhub/main.dart';

/// اختبارات سير عمل التفسير بالمصادر المحلية فقط (دون شبكة).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() => DeenHubApp(
        quranRepository: QuranRepositoryImpl(local: LocalQuranDataSource()),
        tafsirRepository:
            TafsirRepositoryImpl(local: LocalTafsirDataSource()),
      );

  Future<void> openTafsirOfIkhlas1(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.quran).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Al-Ikhlaas'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Al-Ikhlaas'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('قُلْ هُوَ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.viewTafsir));
    await tester.pumpAndSettle();
  }

  testWidgets('view tafsir shows text, attribution and all five editions',
      (tester) async {
    await openTafsirOfIkhlas1(tester);

    // نص تفسير السعدي للآية ١١٢:١ (من البيانات المحلية)
    expect(find.textContaining('الأحدية'), findsOneWidget);

    // الإسناد: الكتاب، العالِم، المصدر، المرجع
    expect(find.textContaining('تفسير السعدي'), findsWidgets);
    expect(find.textContaining('عبد الرحمن بن ناصر السعدي'), findsOneWidget);
    expect(find.textContaining('quran.com'), findsOneWidget);
    expect(find.textContaining('ar-tafseer-al-saddi'), findsOneWidget);

    // كتب التفسير الخمسة كلها خيارات مفعّلة (الجلالين عبر AlQuran Cloud)
    expect(find.textContaining('تفسير ابن كثير'), findsOneWidget);
    expect(find.textContaining('تفسير الطبري'), findsOneWidget);
    expect(find.textContaining('تفسير القرطبي'), findsOneWidget);
    expect(find.textContaining('تفسير الجلالين'), findsOneWidget);
    expect(find.textContaining(AppStrings.tafsirComingSoon), findsNothing);
  });

  testWidgets('in-text search highlights matches ignoring diacritics',
      (tester) async {
    await openTafsirOfIkhlas1(tester);

    await tester.tap(find.byTooltip(AppStrings.searchInTafsirText));
    await tester.pumpAndSettle();

    // البحث دون تشكيل عن كلمة وردت مشكَّلة في النص
    await tester.enterText(find.byType(TextField), 'الاحدية');
    await tester.pumpAndSettle();

    expect(find.textContaining(AppStrings.matchesFound), findsOneWidget);

    // كلمة غير موجودة
    await tester.enterText(find.byType(TextField), 'كلمة غير موجودة إطلاقاً');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noMatchesInText), findsOneWidget);
  });

  testWidgets('bookmark and favorite a tafsir page persist locally',
      (tester) async {
    await openTafsirOfIkhlas1(tester);

    await tester.tap(find.byTooltip(AppStrings.addTafsirBookmark));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.addToFavorites));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('tafsir_bookmarks'), contains('saadi:112:1'));
    expect(prefs.getStringList('favorites'), contains('tafsir:saadi:112:1'));

    // الأيقونات تعكس الحالة
    expect(find.byTooltip(AppStrings.removeTafsirBookmark), findsOneWidget);
    expect(find.byTooltip(AppStrings.removeFromFavorites), findsOneWidget);
  });

  testWidgets('tafsir screen lists bookmarks and opens them', (tester) async {
    SharedPreferences.setMockInitialValues({
      'tafsir_bookmarks': ['saadi:112:1'],
    });
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tafsir));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tafsirBookmarks), findsOneWidget);
    expect(find.text('تفسير السعدي'), findsWidgets);

    // فتح الإشارة المرجعية يقود إلى صفحة التفسير نفسها
    await tester.tap(find.text('تفسير السعدي').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('الأحدية'), findsOneWidget);
  });

  testWidgets('favorites screen shows favorited tafsir passage',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['tafsir:saadi:112:1'],
    });
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.favorites));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tafsirFavorites), findsOneWidget);
    expect(find.textContaining('الأحدية'), findsOneWidget);
  });

  testWidgets('corpus search in tafsir screen finds and opens passages',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tafsir));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'الاحدية');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // نتيجة من تفسير السعدي للآية ١١٢:١
    expect(find.textContaining('الأحدية'), findsOneWidget);

    await tester.tap(find.textContaining('الأحدية'));
    await tester.pumpAndSettle();
    expect(find.textContaining('عبد الرحمن بن ناصر السعدي'), findsOneWidget);
  });

  testWidgets('tafsir screen lists supported editions from data source',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tafsir));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.availableEditions), findsOneWidget);
    expect(find.text('تفسير السعدي'), findsOneWidget);
    expect(find.textContaining('عبد الرحمن بن ناصر السعدي'), findsOneWidget);
    // الجلالين أسفل القائمة — تمرير إليه
    await tester.scrollUntilVisible(
      find.text('تفسير الجلالين'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('تفسير الجلالين'), findsOneWidget);
    // لا كتب معلَّقة بعد توصيل الجلالين بمصدر AlQuran Cloud
    expect(find.text(AppStrings.tafsirComingSoon), findsNothing);
  });
}
