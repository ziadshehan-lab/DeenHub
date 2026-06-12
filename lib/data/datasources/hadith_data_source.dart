import '../../models/hadith_models.dart';

/// واجهة مصدر بيانات الحديث الشريف.
///
/// التطبيقات الحالية:
/// - [RemoteHadithDataSource] عبر واجهة موسوعة الأحاديث النبوية الرسمية
///   (HadeethEnc.com) — التصفح والنصوص بالعربية والإنجليزية
/// - [SunnahComHadithDataSource] عبر واجهة Sunnah.com الرسمية —
///   المجموعات الكلاسيكية (يتطلب مفتاح API)
/// - [DorarHadithDataSource] عبر واجهة الدرر السنية (dorar.net) —
///   البحث مع درجة الحديث والمحدِّث
/// - [LocalHadithDataSource] من ملفات JSON مضمَّنة مع التطبيق
abstract class HadithDataSource {
  /// هل هذا المصدر مهيأ وقابل للاستخدام (مثلاً: مفتاح API متوفر).
  bool get isConfigured => true;

  /// جلب كتب/أقسام الحديث.
  Future<List<HadithBookModel>> fetchBooks();

  /// جلب أبواب كتاب محدد.
  Future<List<HadithChapterModel>> fetchChapters(String bookId);

  /// جلب أحاديث باب محدد (عناوين/مقتطفات) مع دعم الصفحات.
  Future<List<HadithModel>> fetchHadiths(
    String chapterId, {
    int page = 1,
    int pageSize = 20,
  });

  /// جلب حديث واحد كاملاً بمعرّفه.
  Future<HadithModel> fetchHadith(String hadithId);

  /// البحث في الأحاديث.
  Future<List<HadithSearchResultModel>> searchHadiths(String query);
}

/// يُرمى عندما يكون المطلوب غير متاح من هذا المصدر (غير مدعوم،
/// مفتاح API مفقود، أو لا توجد بيانات محلية).
class HadithUnavailableException implements Exception {
  const HadithUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'HadithUnavailableException: $message';
}
