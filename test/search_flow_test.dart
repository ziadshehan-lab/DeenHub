import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/data/datasources/local_adhkar_data_source.dart';
import 'package:deenhub/data/datasources/local_hadith_data_source.dart';
import 'package:deenhub/data/datasources/local_library_data_source.dart';
import 'package:deenhub/data/datasources/local_quran_data_source.dart';
import 'package:deenhub/data/datasources/local_tafsir_data_source.dart';
import 'package:deenhub/data/repositories/adhkar_repository_impl.dart';
import 'package:deenhub/data/repositories/hadith_repository_impl.dart';
import 'package:deenhub/data/repositories/library_repository_impl.dart';
import 'package:deenhub/data/repositories/quran_repository_impl.dart';
import 'package:deenhub/data/repositories/tafsir_repository_impl.dart';
import 'package:deenhub/main.dart';
import 'package:deenhub/providers/search_provider.dart';

/// اختبارات شاشة البحث الموحد بالمصادر المحلية فقط.
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
        adhkarRepository:
            AdhkarRepositoryImpl(local: LocalAdhkarDataSource()),
        libraryRepository:
            LibraryRepositoryImpl(local: LocalLibraryDataSource()),
      );

  Future<void> openSearch(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.search).first);
    await tester.pumpAndSettle();
  }

  testWidgets('grouped results across modules and navigation to Quran',
      (tester) async {
    await openSearch(tester);

    await tester.enterText(find.byType(TextField), 'قل هو الله احد');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // ترويسة قسم القرآن تظهر مرتين: شريحة المرشح + عنوان المجموعة
    expect(find.text(AppStrings.quran), findsNWidgets(2));
    expect(find.textContaining('سُورَةُ'), findsWidgets);

    // فتح النتيجة → شاشة السورة
    await tester.tap(find.textContaining('الآية').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('قُلْ هُوَ'), findsWidgets);
  });

  testWidgets('type filter restricts results to the selected module',
      (tester) async {
    await openSearch(tester);

    // تفعيل مرشح المكتبة فقط ثم البحث
    await tester.tap(find.text(AppStrings.library));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'البخاري');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.textContaining('صحيح البخاري'), findsWidgets);
    // لا ترويسة لقسم القرآن (تبقى الشريحة وحدها)
    expect(find.text(AppStrings.quran), findsOneWidget);
  });

  testWidgets('recent searches are saved, reusable and clearable',
      (tester) async {
    await openSearch(tester);

    await tester.enterText(find.byType(TextField), 'ابن الاثير');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.textContaining('الكامل في التاريخ'), findsWidgets);

    // مسح الحقل يعيد عرض سجل البحث
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.recentSearches), findsOneWidget);
    expect(find.text('ابن الاثير'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(SearchProvider.prefKeyRecent),
        contains('ابن الاثير'));

    // مسح السجل
    await tester.tap(find.text(AppStrings.clearHistory));
    await tester.pumpAndSettle();
    expect(find.text('ابن الاثير'), findsNothing);
    expect(prefs.getStringList(SearchProvider.prefKeyRecent), isNull);
  });

  testWidgets('empty state when nothing matches', (tester) async {
    await openSearch(tester);

    await tester.enterText(
        find.byType(TextField), 'كلمةغيرموجودةإطلاقاً');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noResults), findsOneWidget);
  });

  testWidgets('library result opens book detail', (tester) async {
    await openSearch(tester);

    await tester.enterText(find.byType(TextField), 'ابن الاثير');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('الكامل في التاريخ').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('shamela.ws/book/21712'), findsOneWidget);
  });
}
