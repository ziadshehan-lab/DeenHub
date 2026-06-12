import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/data/datasources/local_adhkar_data_source.dart';
import 'package:deenhub/data/repositories/adhkar_repository_impl.dart';
import 'package:deenhub/main.dart';

/// اختبارات سير عمل الأذكار والأسماء الحسنى بالمصادر المحلية فقط.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() => DeenHubApp(
        adhkarRepository:
            AdhkarRepositoryImpl(local: LocalAdhkarDataSource()),
      );

  /// مقتطفات من البيانات المضمَّنة نفسها — تجنباً لحساسية ترتيب
  /// علامات التشكيل في النصوص المكتوبة يدوياً.
  Future<String> wakeDhikrNeedle() async {
    final adhkar = await LocalAdhkarDataSource().fetchAdhkar('wake');
    return adhkar.first.text.substring(0, 25);
  }

  Future<List<String>> firstTwoNames() async {
    final names = await LocalAdhkarDataSource().fetchNamesOfAllah();
    return [names[0].name, names[1].name];
  }

  Future<void> openAdhkar(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.adhkar).first);
    await tester.pumpAndSettle();
  }

  testWidgets('adhkar screen lists the nine categories and opens one',
      (tester) async {
    await openAdhkar(tester);

    expect(find.text('أذكار الصباح والمساء'), findsOneWidget);
    expect(find.text('أذكار النوم'), findsOneWidget);
    expect(find.text('أذكار الاستيقاظ من النوم'), findsOneWidget);

    // فتح أذكار الاستيقاظ: النص والإسناد والتكرار
    await tester.tap(find.text('أذكار الاستيقاظ من النوم'));
    await tester.pumpAndSettle();
    expect(find.textContaining(await wakeDhikrNeedle()), findsOneWidget);
    expect(find.textContaining('حصن المسلم'), findsWidgets);
    expect(find.text(AppStrings.onceLabel), findsWidgets);
  });

  testWidgets('dhikr copy shows confirmation and favorite persists',
      (tester) async {
    // قناة الحافظة لا معالج لها في بيئة الاختبار — نسجل معالجاً صورياً
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await openAdhkar(tester);
    await tester.tap(find.text('أذكار الاستيقاظ من النوم'));
    await tester.pumpAndSettle();

    // نسخ أول ذكر — pumpAndSettle يتجاوز عمر SnackBar فنضخ إطارات فقط
    await tester.tap(find.byTooltip(AppStrings.copyDhikr).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.dhikrCopied), findsOneWidget);

    // إضافة إلى المفضلة
    await tester.tap(find.byTooltip(AppStrings.addToFavorites).first);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorites'), contains('dhikr:1-1'));
  });

  testWidgets('adhkar search finds dhikr without diacritics',
      (tester) async {
    await openAdhkar(tester);

    await tester.enterText(
        find.byType(TextField), 'الحمد لله الذي احيانا');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.textContaining(await wakeDhikrNeedle()), findsOneWidget);
  });

  testWidgets('names screen lists 99 names with search and favorites',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.namesOfAllah));
    await tester.pumpAndSettle();

    final names = await firstTwoNames();
    // الاسم الأول ظاهر مع نطقه
    expect(find.text(names[0]), findsOneWidget);
    expect(find.text('Ar Rahmaan'), findsOneWidget);

    // البحث (دون تشكيل) يقلص الشبكة
    await tester.enterText(find.byType(TextField), 'الرحيم');
    await tester.pumpAndSettle();
    expect(find.text(names[1]), findsOneWidget);
    expect(find.text(names[0]), findsNothing);

    // فتح ورقة الاسم: النطق والمعنى والمصدر، ثم المفضلة
    await tester.tap(find.text(names[1]));
    await tester.pumpAndSettle();
    expect(find.textContaining(AppStrings.transliterationLabel),
        findsOneWidget);
    expect(find.textContaining(AppStrings.meaningLabel), findsOneWidget);
    expect(find.textContaining('AlAdhan'), findsOneWidget);

    await tester.tap(find.text(AppStrings.addToFavorites));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorites'), contains('name:2'));
  });

  testWidgets('favorites screen shows dhikr and name sections',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['dhikr:1-1', 'name:1'],
    });
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.favorites));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.favoriteAdhkar), findsOneWidget);
    expect(find.textContaining(await wakeDhikrNeedle()), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AppStrings.favoriteNames),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text((await firstTwoNames())[0]), findsOneWidget);
  });
}
