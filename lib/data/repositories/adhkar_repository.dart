import '../../models/dhikr.dart';

/// واجهة مستودع الأذكار وأسماء الله الحسنى — تنسّق بين مصادر البيانات
/// وتطبّق سياسة التخزين المؤقت.
abstract class AdhkarRepository {
  Future<List<DhikrCategory>> getCategories();

  Future<List<Dhikr>> getAdhkar(String categoryId);

  Future<List<AllahName>> getNamesOfAllah();
}
