import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/data/datasources/local_library_data_source.dart';
import 'package:deenhub/data/repositories/library_repository_impl.dart';
import 'package:deenhub/main.dart';
import 'package:deenhub/providers/library_provider.dart';

/// اختبارات سير عمل المكتبة بالفهرس المضمَّن (دون شبكة).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() => DeenHubApp(
        libraryRepository:
            LibraryRepositoryImpl(local: LocalLibraryDataSource()),
      );

  Future<void> openLibrary(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.library).first);
    await tester.pumpAndSettle();
  }

  testWidgets('library home shows categories and sources', (tester) async {
    await openLibrary(tester);

    expect(find.text(AppStrings.libraryCategories), findsOneWidget);
    expect(find.text('التفسير'), findsOneWidget);
    expect(find.text('الحديث'), findsOneWidget);
    expect(find.text('العقيدة'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('المكتبة الشاملة'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.librarySources), findsOneWidget);
    expect(find.text('المكتبة الشاملة'), findsOneWidget);
  });

  testWidgets('category opens its book list, book opens detail with '
      'attribution, favorite and last read persist', (tester) async {
    await openLibrary(tester);

    await tester.tap(find.text('الحديث'));
    await tester.pumpAndSettle();
    expect(find.textContaining('صحيح البخاري'), findsOneWidget);

    await tester.tap(find.textContaining('صحيح البخاري'));
    await tester.pumpAndSettle();

    // التفاصيل: المؤلف والمصدر والرابط الموثق والوصف
    expect(find.textContaining('البخاري'), findsWidgets);
    expect(find.textContaining('shamela.ws/book/1681'), findsOneWidget);
    expect(find.textContaining('المكتبة الشاملة'), findsOneWidget);
    expect(find.text(AppStrings.openSourceNote), findsOneWidget);

    // المفضلة وآخر كتاب مفتوح
    await tester.tap(find.byTooltip(AppStrings.addToFavorites));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorites'), contains('book:sahih-bukhari'));
    expect(prefs.getString(LibraryProvider.prefKeyLastReadId),
        'sahih-bukhari');

    // العودة للرئيسية: بطاقة متابعة التصفح ظاهرة
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.continueBrowsing), findsOneWidget);
  });

  testWidgets('book info copy shows confirmation', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await openLibrary(tester);
    await tester.tap(find.text('التفسير'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ابن كثير').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(AppStrings.copyBookInfo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.bookInfoCopied), findsOneWidget);
  });

  testWidgets('source tile opens its book list', (tester) async {
    await openLibrary(tester);

    await tester.scrollUntilVisible(
      find.text('الدرر السنية'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('الدرر السنية'));
    await tester.pumpAndSettle();

    // كل موسوعات الدرر في القائمة
    expect(find.textContaining('الموسوعة العقدية'), findsOneWidget);
    expect(find.textContaining('الموسوعة الحديثية'), findsOneWidget);
  });

  testWidgets('library search finds books by author', (tester) async {
    await openLibrary(tester);

    await tester.enterText(find.byType(TextField), 'ابن الاثير');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.textContaining('الكامل في التاريخ'), findsOneWidget);
  });

  testWidgets('favorites screen shows favorited book', (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['book:sahih-muslim'],
    });
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.favorites));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.favoriteBooks), findsOneWidget);
    expect(find.textContaining('صحيح مسلم'), findsOneWidget);
  });
}
