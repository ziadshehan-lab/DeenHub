import '../../models/library_book.dart';

/// واجهة مستودع المكتبة الإسلامية — تنسّق بين مصادر بيانات المكتبة
/// وتطبّق سياسة التخزين المؤقت.
abstract class LibraryRepository {
  Future<List<LibraryCategory>> getCategories();

  Future<List<LibraryBook>> getBooks(String categoryId);

  Future<LibraryBook> getBook(String bookId);

  Future<List<LibraryBook>> searchBooks(String query);
}
