import '../../models/hadith.dart';

/// واجهة مصدر بيانات الحديث الشريف.
///
/// التطبيقات المستقبلية: HTTP API، ملفات JSON محلية، SQLite، ذاكرة مؤقتة.
abstract class HadithDataSource {
  /// جلب قائمة مجموعات الأحاديث (البخاري، مسلم...).
  Future<List<HadithCollection>> fetchCollections();

  /// جلب أحاديث مجموعة محددة مع دعم الصفحات.
  Future<List<Hadith>> fetchHadiths(
    String collectionId, {
    int page = 1,
    int pageSize = 20,
  });

  /// جلب حديث واحد بمعرّفه.
  Future<Hadith> fetchHadith(String collectionId, String hadithId);

  /// البحث في نصوص الأحاديث.
  Future<List<Hadith>> searchHadiths(String query);
}
