import '../../models/dhikr.dart';

/// واجهة مصدر بيانات الأذكار وأسماء الله الحسنى.
///
/// التطبيقات المستقبلية: HTTP API، ملفات JSON محلية، SQLite، ذاكرة مؤقتة.
abstract class AdhkarDataSource {
  /// جلب تصنيفات الأذكار (صباح، مساء، نوم...).
  Future<List<DhikrCategory>> fetchCategories();

  /// جلب أذكار تصنيف محدد.
  Future<List<Dhikr>> fetchAdhkar(String categoryId);

  /// جلب أسماء الله الحسنى.
  Future<List<AllahName>> fetchNamesOfAllah();
}
