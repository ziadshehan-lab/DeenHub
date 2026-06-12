import '../../models/library_book.dart';

/// واجهة مستودع المكتبة الإسلامية.
abstract class LibraryRepository {
  Future<List<LibraryCategoryModel>> getCategories();

  Future<List<LibrarySourceModel>> getSources();

  Future<List<LibraryBookModel>> getBooks(String categoryId);

  /// كتب مصدر محدد (الشاملة، الدرر...).
  Future<List<LibraryBookModel>> getBooksBySource(String sourceId);

  Future<LibraryBookModel> getBook(String bookId);

  /// بحث عربي يتجاهل التشكيل في العناوين والمؤلفين والأوصاف.
  Future<List<LibraryBookModel>> searchBooks(String query);
}
