import '../../models/quran_models.dart';

/// واجهة مستودع القرآن الكريم.
///
/// المستودع هو الطبقة التي تتعامل معها واجهة المستخدم؛ وهو المسؤول عن
/// التنسيق بين مصادر البيانات (بعيد / أصول محلية / ذاكرة مؤقتة)
/// دون أن تعرف الواجهة شيئاً عن التفاصيل.
abstract class QuranRepository {
  Future<List<SurahModel>> getSurahs();

  Future<SurahModel> getSurah(int surahNumber);

  Future<List<AyahModel>> getAyahs(int surahNumber);

  /// جلب آية واحدة محددة.
  Future<AyahModel> getAyah(int surahNumber, int ayahNumber);

  Future<List<AyahModel>> searchAyahs(String query);

  /// نص البسملة (يُعرض في رأس كل سورة عدا الفاتحة والتوبة).
  Future<String> getBasmala();
}
