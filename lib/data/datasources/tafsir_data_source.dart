import '../../models/tafsir_entry.dart';

/// واجهة مصدر بيانات التفسير.
///
/// التطبيقات المستقبلية: HTTP API، ملفات JSON محلية، SQLite، ذاكرة مؤقتة.
abstract class TafsirDataSource {
  /// جلب قائمة كتب التفسير المتاحة.
  Future<List<TafsirEdition>> fetchEditions();

  /// جلب تفسير آية محددة من كتاب تفسير محدد.
  Future<TafsirEntry> fetchTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  });

  /// جلب تفسير سورة كاملة من كتاب تفسير محدد.
  Future<List<TafsirEntry>> fetchSurahTafsir({
    required String editionId,
    required int surahNumber,
  });
}
