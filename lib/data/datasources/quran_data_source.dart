import '../../models/surah.dart';

/// واجهة مصدر بيانات القرآن الكريم.
///
/// التطبيقات المستقبلية الممكنة:
/// - مصدر بعيد عبر HTTP من واجهة برمجة رسمية (RemoteQuranDataSource)
/// - مصدر محلي من ملفات JSON داخل التطبيق (AssetQuranDataSource)
/// - مصدر قاعدة بيانات SQLite (SqliteQuranDataSource)
/// - مصدر ذاكرة مؤقتة (CachedQuranDataSource)
abstract class QuranDataSource {
  /// جلب قائمة جميع السور.
  Future<List<Surah>> fetchSurahs();

  /// جلب بيانات سورة واحدة برقمها.
  Future<Surah> fetchSurah(int surahNumber);

  /// جلب آيات سورة محددة.
  Future<List<Ayah>> fetchAyahs(int surahNumber);

  /// البحث في نصوص الآيات.
  Future<List<Ayah>> searchAyahs(String query);
}
