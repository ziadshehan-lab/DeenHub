import '../../models/library_book.dart';

/// واجهة مصدر بيانات المكتبة الإسلامية.
///
/// التطبيق الحالي: [LocalLibraryDataSource] — فهرس مضمَّن بروابط
/// موثقة إلى المصادر الرسمية (الشاملة، الدرر، إسلام ويب...) لأن هذه
/// المصادر لا توفر واجهات JSON عامة؛ الواجهة جاهزة لمصدر بعيد لاحقاً.
abstract class LibraryDataSource {
  /// جلب تصنيفات المكتبة الثمانية.
  Future<List<LibraryCategoryModel>> fetchCategories();

  /// جلب سجل المصادر المعتمدة.
  Future<List<LibrarySourceModel>> fetchSources();

  /// جلب كتب تصنيف محدد.
  Future<List<LibraryBookModel>> fetchBooks(String categoryId);

  /// جلب كتاب واحد بمعرّفه.
  Future<LibraryBookModel> fetchBook(String bookId);

  /// البحث في العناوين والمؤلفين والأوصاف.
  Future<List<LibraryBookModel>> searchBooks(String query);
}

/// يُرمى عندما يكون المحتوى غير متاح من هذا المصدر.
class LibraryUnavailableException implements Exception {
  const LibraryUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'LibraryUnavailableException: $message';
}
