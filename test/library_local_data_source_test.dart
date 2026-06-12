import 'package:flutter_test/flutter_test.dart';

import 'package:deenhub/data/datasources/library_data_source.dart';
import 'package:deenhub/data/datasources/local_library_data_source.dart';
import 'package:deenhub/data/repositories/library_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalLibraryDataSource dataSource;

  setUp(() {
    dataSource = LocalLibraryDataSource();
  });

  test('fetchCategories returns the eight required categories', () async {
    final categories = await dataSource.fetchCategories();

    expect(categories.map((c) => c.id), [
      'tafsir',
      'hadith',
      'aqeedah',
      'fiqh',
      'seerah',
      'history',
      'arabic',
      'tazkiyah',
    ]);
  });

  test('fetchSources returns the eight approved source providers',
      () async {
    final sources = await dataSource.fetchSources();

    expect(sources.map((s) => s.id), [
      'shamela',
      'dorar',
      'islamweb',
      'islamqa',
      'binbaz',
      'ibnuthaymeen',
      'alukah',
      'azhar',
    ]);
    for (final source in sources) {
      expect(source.name, isNotEmpty);
      expect(source.url, startsWith('https://'));
    }
  });

  test('every category has books with full metadata and attribution',
      () async {
    for (final category in await dataSource.fetchCategories()) {
      final books = await dataSource.fetchBooks(category.id);
      expect(books, isNotEmpty,
          reason: 'لا كتب في تصنيف ${category.id}');
      for (final book in books) {
        expect(book.title, isNotEmpty);
        expect(book.author, isNotEmpty);
        expect(book.url, startsWith('https://'));
        expect(book.sourceName, isNotEmpty);
        expect(book.source.sourceUrl, book.url);
        expect(book.source.authorOrScholar, book.author);
      }
    }
    expect(
      () => dataSource.fetchBooks('unknown'),
      throwsA(isA<LibraryUnavailableException>()),
    );
  });

  test('fetchBook resolves by id with verified Shamela link', () async {
    final book = await dataSource.fetchBook('sahih-bukhari');
    expect(book.title, contains('صحيح البخاري'));
    expect(book.url, 'https://shamela.ws/book/1681'); // رابط تم التحقق منه
    expect(book.sourceName, contains('الشاملة'));

    expect(
      () => dataSource.fetchBook('missing'),
      throwsA(isA<LibraryUnavailableException>()),
    );
  });

  test('searchBooks matches title, author and source ignoring diacritics',
      () async {
    final byTitle = await dataSource.searchBooks('صحيح البخاري');
    expect(byTitle.map((b) => b.id), contains('sahih-bukhari'));

    final byAuthor = await dataSource.searchBooks('ابن كثير');
    expect(byAuthor.map((b) => b.id), contains('tafsir-ibn-kathir'));

    final bySource = await dataSource.searchBooks('الدرر السنية');
    expect(bySource.length, greaterThanOrEqualTo(5));

    expect(await dataSource.searchBooks('  '), isEmpty);
  });

  test('repository: session cache, getBooksBySource and empty search',
      () async {
    final repo = LibraryRepositoryImpl(local: dataSource);

    final shamelaBooks = await repo.getBooksBySource('shamela');
    expect(shamelaBooks, isNotEmpty);
    expect(shamelaBooks.every((b) => b.sourceId == 'shamela'), isTrue);

    final book = await repo.getBook('kamil-tarikh');
    expect(book.categoryId, 'history');

    expect(await repo.searchBooks('   '), isEmpty);
  });
}
