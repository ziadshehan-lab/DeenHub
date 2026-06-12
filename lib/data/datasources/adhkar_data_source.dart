import '../../models/dhikr.dart';

/// واجهة مصدر بيانات الأذكار وأسماء الله الحسنى.
///
/// التطبيقات الحالية:
/// - [RemoteAdhkarDataSource]: الأذكار من الموقع الرسمي لحصن المسلم،
///   والأسماء الحسنى من واجهة AlAdhan
/// - [LocalAdhkarDataSource]: المحتوى الكامل مضمَّن مع التطبيق
///   (تسعة تصنيفات و٩٩ اسماً) — يعمل دون اتصال
abstract class AdhkarDataSource {
  /// جلب تصنيفات الأذكار.
  Future<List<DhikrCategoryModel>> fetchCategories();

  /// جلب أذكار تصنيف محدد.
  Future<List<DhikrModel>> fetchAdhkar(String categoryId);

  /// البحث في نصوص الأذكار وأبوابها.
  Future<List<DhikrModel>> searchAdhkar(String query);

  /// جلب أسماء الله الحسنى.
  Future<List<AllahNameModel>> fetchNamesOfAllah();
}

/// يُرمى عندما يكون المحتوى غير متاح من هذا المصدر.
class AdhkarUnavailableException implements Exception {
  const AdhkarUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'AdhkarUnavailableException: $message';
}
