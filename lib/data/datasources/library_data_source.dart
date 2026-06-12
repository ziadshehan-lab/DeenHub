import '../../models/library_book.dart';

/// واجهة مصدر بيانات المكتبة الإسلامية.
///
/// التطبيقات المستقبلية: HTTP API، ملفات JSON محلية، SQLite، ذاكرة مؤقتة.
abstract class LibraryDataSource {
  /// جلب تصنيفات المكتبة (عقيدة، فقه، سيرة...).
  Future<List<LibraryCategory>> fetchCategories();

  /// جلب كتب تصنيف محدد.
  Future<List<LibraryBook>> fetchBooks(String categoryId);

  /// جلب كتاب واحد بمعرّفه.
  Future<LibraryBook> fetchBook(String bookId);

  /// البحث في عناوين الكتب وأوصافها.
  Future<List<LibraryBook>> searchBooks(String query);
}
