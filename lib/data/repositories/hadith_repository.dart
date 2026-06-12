import '../../models/hadith_models.dart';

/// واجهة مستودع الحديث الشريف — تنسّق بين مصادر البيانات
/// وتطبّق سياسة التخزين المؤقت.
abstract class HadithRepository {
  Future<List<HadithBookModel>> getBooks();

  Future<List<HadithChapterModel>> getChapters(String bookId);

  Future<List<HadithModel>> getHadiths(
    String chapterId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<HadithModel> getHadith(String hadithId);

  Future<List<HadithSearchResultModel>> searchHadiths(String query);
}
