import '../../core/utils/arabic_text.dart';
import '../../models/content_source.dart';
import '../../models/library_book.dart';
import '../../services/asset_data_loader.dart';
import 'library_data_source.dart';

/// مصدر المكتبة المحلي — فهرس مضمَّن (lib/assets_data/library) يضم
/// التصنيفات الثمانية والمصادر الثمانية وكتباً بروابط تم التحقق منها
/// إلى صفحاتها الرسمية. يعمل بالكامل دون اتصال.
class LocalLibraryDataSource implements LibraryDataSource {
  LocalLibraryDataSource({AssetDataLoader? loader})
      : _loader = loader ?? const AssetDataLoader();

  final AssetDataLoader _loader;

  List<LibraryCategoryModel>? _categories;
  List<LibrarySourceModel>? _sources;
  List<LibraryBookModel>? _books;

  Future<void> _ensureLoaded() async {
    if (_books != null) return;

    final json = await _loader.loadJson('library/catalog.json')
        as Map<String, dynamic>;
    final catalogSource =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);

    _categories = (json['categories'] as List<dynamic>)
        .map((c) => LibraryCategoryModel(
              id: (c as Map<String, dynamic>)['id'] as String,
              title: c['title'] as String,
            ))
        .toList();

    final sources = (json['sources'] as List<dynamic>)
        .map((s) => LibrarySourceModel.fromJson(s as Map<String, dynamic>))
        .toList();
    _sources = sources;
    final sourcesById = {for (final s in sources) s.id: s};

    _books = (json['books'] as List<dynamic>).map((b) {
      final book = b as Map<String, dynamic>;
      final sourceId = book['sourceId'] as String;
      final hostSource = sourcesById[sourceId];
      return LibraryBookModel(
        id: book['id'] as String,
        title: book['title'] as String,
        author: book['author'] as String,
        categoryId: book['categoryId'] as String,
        sourceId: sourceId,
        sourceName: hostSource?.name ?? sourceId,
        description: book['description'] as String?,
        url: book['url'] as String,
        source: ContentSource(
          sourceName: hostSource?.name ?? sourceId,
          authorOrScholar: book['author'] as String,
          reference: book['title'] as String,
          sourceUrl: book['url'] as String,
          lastUpdated: catalogSource.lastUpdated,
        ),
      );
    }).toList();
  }

  @override
  Future<List<LibraryCategoryModel>> fetchCategories() async {
    await _ensureLoaded();
    return _categories!;
  }

  @override
  Future<List<LibrarySourceModel>> fetchSources() async {
    await _ensureLoaded();
    return _sources!;
  }

  @override
  Future<List<LibraryBookModel>> fetchBooks(String categoryId) async {
    await _ensureLoaded();
    final books =
        _books!.where((b) => b.categoryId == categoryId).toList();
    if (books.isEmpty) {
      throw LibraryUnavailableException('تصنيف غير معروف: $categoryId');
    }
    return books;
  }

  @override
  Future<LibraryBookModel> fetchBook(String bookId) async {
    await _ensureLoaded();
    final book = _books!.where((b) => b.id == bookId).firstOrNull;
    if (book == null) {
      throw LibraryUnavailableException('كتاب غير موجود: $bookId');
    }
    return book;
  }

  @override
  Future<List<LibraryBookModel>> searchBooks(String query) async {
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.isEmpty) return const [];
    await _ensureLoaded();

    bool matches(String? value) =>
        value != null && normalizeArabic(value).contains(normalizedQuery);

    return _books!
        .where((b) =>
            matches(b.title) ||
            matches(b.author) ||
            matches(b.description) ||
            matches(b.sourceName))
        .toList();
  }
}
