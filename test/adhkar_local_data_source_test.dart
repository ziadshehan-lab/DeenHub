import 'package:flutter_test/flutter_test.dart';

import 'package:deenhub/core/utils/arabic_text.dart';
import 'package:deenhub/data/datasources/adhkar_data_source.dart';
import 'package:deenhub/data/datasources/local_adhkar_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAdhkarDataSource dataSource;

  setUp(() {
    dataSource = LocalAdhkarDataSource();
  });

  test('fetchCategories returns the nine required categories', () async {
    final categories = await dataSource.fetchCategories();

    expect(categories.map((c) => c.id), [
      'morning-evening',
      'sleep',
      'wake',
      'prayer',
      'travel',
      'mosque',
      'food',
      'istighfar',
      'tasbih',
    ]);
    for (final category in categories) {
      expect(category.dhikrCount, greaterThan(0));
      expect(category.source.sourceName, contains('حصن المسلم'));
      expect(category.source.authorOrScholar, contains('القحطاني'));
    }
  });

  test('fetchAdhkar returns dhikr with text, repeat and attribution',
      () async {
    final wake = await dataSource.fetchAdhkar('wake');
    expect(wake, isNotEmpty);
    final first = wake.first;
    expect(first.id, '1-1');
    // المقارنة بعد التبسيط لتجنب حساسية ترتيب علامات التشكيل
    expect(normalizeArabic(first.text), contains('الحمد لله الذي احيانا'));
    expect(first.repeat, 1);
    expect(first.sourceName, contains('حصن المسلم'));
    expect(first.reference, contains('ذكر رقم'));
    expect(first.sourceUrl, contains('hisnmuslim.com'));

    // ذكر بتكرار مسنون أكبر من مرة
    final morning = await dataSource.fetchAdhkar('morning-evening');
    expect(morning.any((d) => d.repeat > 1), isTrue);

    expect(
      () => dataSource.fetchAdhkar('unknown'),
      throwsA(isA<AdhkarUnavailableException>()),
    );
  });

  test('searchAdhkar matches text and chapter ignoring diacritics',
      () async {
    // نص ذكر الاستيقاظ دون تشكيل
    final byText = await dataSource.searchAdhkar('الحمد لله الذي احيانا');
    expect(byText, isNotEmpty);
    expect(byText.first.categoryId, 'wake');

    // بعنوان الباب
    final byChapter = await dataSource.searchAdhkar('دخول المسجد');
    expect(byChapter, isNotEmpty);
    expect(byChapter.first.categoryId, 'mosque');

    expect(await dataSource.searchAdhkar('  '), isEmpty);
  });

  test('fetchNamesOfAllah returns the 99 names with full fields', () async {
    final names = await dataSource.fetchNamesOfAllah();

    expect(names, hasLength(99));
    final first = names.first;
    expect(first.number, 1);
    expect(first.name, 'الرَّحْمَنُ');
    expect(first.transliteration, 'Ar Rahmaan');
    expect(first.meaning, 'The Beneficent');
    expect(first.source.sourceName, contains('AlAdhan'));
    // الأرقام متسلسلة ١-٩٩
    expect(names.last.number, 99);
  });
}
