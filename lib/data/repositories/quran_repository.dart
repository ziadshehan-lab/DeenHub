import '../../models/surah.dart';

/// واجهة مستودع القرآن الكريم.
///
/// المستودع هو الطبقة التي تتعامل معها واجهة المستخدم؛ وهو المسؤول عن
/// التنسيق بين مصادر البيانات (بعيد / أصول محلية / SQLite / ذاكرة مؤقتة)
/// وتطبيق سياسة التخزين المؤقت دون أن تعرف الواجهة شيئاً عن التفاصيل.
abstract class QuranRepository {
  Future<List<Surah>> getSurahs();

  Future<Surah> getSurah(int surahNumber);

  Future<List<Ayah>> getAyahs(int surahNumber);

  Future<List<Ayah>> searchAyahs(String query);
}
