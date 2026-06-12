import '../../models/tafsir_models.dart';

/// واجهة مصدر بيانات التفسير.
///
/// التطبيقات الحالية:
/// - [RemoteTafsirDataSource] عبر واجهة Quran.com الرسمية (HTTP):
///   السعدي، ابن كثير، الطبري، القرطبي
/// - [AlQuranCloudTafsirDataSource] عبر واجهة AlQuran Cloud (HTTP):
///   الجلالين
/// - [LocalTafsirDataSource] من ملفات JSON مضمَّنة مع التطبيق
abstract class TafsirDataSource {
  /// جلب قائمة كتب التفسير المعتمدة.
  Future<List<TafsirEditionModel>> fetchEditions();

  /// هل يدعم هذا المصدر الكتاب المحدد (دون طلب شبكة).
  bool supportsEdition(String editionId);

  /// جلب تفسير آية محددة من كتاب تفسير محدد.
  Future<TafsirModel> fetchTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  });

  /// البحث في نصوص التفسير المتاحة لدى هذا المصدر.
  /// المصادر البعيدة لا توفر بحثاً نصياً حالياً وترمي
  /// [TafsirUnavailableException].
  Future<List<TafsirModel>> searchTafsir(String query);
}

/// يُرمى عندما يكون التفسير المطلوب غير متاح من هذا المصدر
/// (كتاب غير مدعوم، أو لا توجد بيانات محلية للسورة المطلوبة).
class TafsirUnavailableException implements Exception {
  const TafsirUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'TafsirUnavailableException: $message';
}
