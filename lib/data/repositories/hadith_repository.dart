import '../../models/hadith.dart';

/// واجهة مستودع الحديث الشريف — تنسّق بين مصادر بيانات الحديث
/// وتطبّق سياسة التخزين المؤقت.
abstract class HadithRepository {
  Future<List<HadithCollection>> getCollections();

  Future<List<Hadith>> getHadiths(
    String collectionId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<Hadith> getHadith(String collectionId, String hadithId);

  Future<List<Hadith>> searchHadiths(String query);
}
