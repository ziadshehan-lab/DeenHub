import '../../models/quran_models.dart';

/// واجهة مصدر بيانات القرآن الكريم.
///
/// التطبيقات الحالية:
/// - [RemoteQuranDataSource] عبر واجهة Quran.com الرسمية (HTTP)
/// - [LocalQuranDataSource] من ملفات JSON مضمَّنة مع التطبيق
abstract class QuranDataSource {
  /// جلب قائمة جميع السور.
  Future<List<SurahModel>> fetchSurahs();

  /// جلب بيانات سورة واحدة برقمها.
  Future<SurahModel> fetchSurah(int surahNumber);

  /// جلب آيات سورة محددة.
  Future<List<AyahModel>> fetchAyahs(int surahNumber);

  /// البحث في نصوص الآيات.
  Future<List<AyahModel>> searchAyahs(String query);

  /// نص البسملة (يُعرض في رأس كل سورة عدا الفاتحة والتوبة).
  Future<String> fetchBasmala();
}
