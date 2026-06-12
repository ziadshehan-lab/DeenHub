import '../../models/dhikr.dart';

/// واجهة مستودع الأذكار وأسماء الله الحسنى.
abstract class AdhkarRepository {
  Future<List<DhikrCategoryModel>> getCategories();

  Future<List<DhikrModel>> getAdhkar(String categoryId);

  /// جلب ذكر واحد بمعرّفه (لعرض المفضلة).
  Future<DhikrModel> getDhikr(String dhikrId);

  /// البحث في نصوص الأذكار وأبوابها وتصنيفاتها (عربي يتجاهل التشكيل).
  Future<List<DhikrModel>> searchAdhkar(String query);

  Future<List<AllahNameModel>> getNamesOfAllah();

  /// جلب اسم واحد برقمه (لعرض المفضلة).
  Future<AllahNameModel> getName(int number);

  /// البحث في الأسماء الحسنى (بالاسم أو النطق أو المعنى).
  Future<List<AllahNameModel>> searchNames(String query);
}
