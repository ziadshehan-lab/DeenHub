import 'package:flutter_test/flutter_test.dart';

import 'package:deenhub/core/utils/arabic_text.dart';
import 'package:deenhub/data/datasources/hadith_data_source.dart';
import 'package:deenhub/data/datasources/local_hadith_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalHadithDataSource dataSource;

  setUp(() {
    dataSource = LocalHadithDataSource();
  });

  test('fetchBooks returns the encyclopedia root sections with source info',
      () async {
    final books = await dataSource.fetchBooks();

    expect(books.length, greaterThanOrEqualTo(7));
    expect(books.map((b) => b.title), contains('العقيدة'));
    expect(books.map((b) => b.title), contains('الحديث وعلومه'));
    for (final book in books) {
      expect(book.hadithCount, isNotNull);
      expect(book.source.sourceName, contains('HadeethEnc'));
      expect(book.source.sourceUrl, isNotNull);
    }
  });

  test('fetchChapters returns chapters for locally bundled books', () async {
    final chapters = await dataSource.fetchChapters('2');

    expect(chapters.map((c) => c.title), contains('مصطلح الحديث'));
    expect(chapters.every((c) => c.bookId == '2'), isTrue);

    // كتاب غير مضمَّن محلياً
    expect(
      () => dataSource.fetchChapters('4'),
      throwsA(isA<HadithUnavailableException>()),
    );
  });

  test('fetchHadiths paginates and fetchHadith returns full attribution',
      () async {
    final page1 = await dataSource.fetchHadiths('43', pageSize: 3);
    expect(page1, hasLength(3));
    final page2 = await dataSource.fetchHadiths('43', page: 2, pageSize: 3);
    expect(page2, hasLength(1)); // 4 أحاديث في الباب

    final hadith = await dataSource.fetchHadith('66512');
    // المقارنة بعد التبسيط لتجنب حساسية التشكيل
    expect(normalizeArabic(hadith.textArabic),
        contains('بني الاسلام علي خمس'));
    expect(normalizeArabic(hadith.narrator ?? ''), contains('عبد الله'));
    expect(hadith.grade, isNotNull);
    expect(hadith.attribution, isNotNull);
    expect(hadith.sourceName, contains('HadeethEnc'));
    expect(hadith.sourceUrl, contains('hadeethenc.com'));
    expect(hadith.reference, isNotEmpty);

    expect(
      () => dataSource.fetchHadith('999999'),
      throwsA(isA<HadithUnavailableException>()),
    );
  });

  test('searchHadiths matches text, title and narrator ignoring diacritics',
      () async {
    // نص حديث «بني الإسلام على خمس» — بحث دون تشكيل
    final byText = await dataSource.searchHadiths('بني الاسلام على خمس');
    expect(byText.map((r) => r.hadithId), contains('66512'));

    // بحث باسم الراوي
    final byNarrator = await dataSource.searchHadiths('عبد الله بن عمر');
    expect(byNarrator, isNotEmpty);

    // كل نتيجة تحمل إسناداً
    for (final result in byText) {
      expect(result.source.sourceName, isNotEmpty);
    }

    expect(await dataSource.searchHadiths('   '), isEmpty);
  });
}
