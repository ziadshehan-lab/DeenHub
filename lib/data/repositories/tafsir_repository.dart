import '../../models/tafsir_models.dart';

/// واجهة مستودع التفسير — تنسّق بين مصادر بيانات التفسير
/// وتطبّق سياسة التخزين المؤقت.
abstract class TafsirRepository {
  /// قائمة كتب التفسير المعتمدة (مع حالة توفر كل كتاب).
  Future<List<TafsirEditionModel>> getEditions();

  /// تفسير آية محددة من كتاب تفسير محدد.
  Future<TafsirModel> getTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  });
}
