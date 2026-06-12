import '../../models/tafsir_entry.dart';

/// واجهة مستودع التفسير — تنسّق بين مصادر بيانات التفسير
/// وتطبّق سياسة التخزين المؤقت.
abstract class TafsirRepository {
  Future<List<TafsirEdition>> getEditions();

  Future<TafsirEntry> getTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  });

  Future<List<TafsirEntry>> getSurahTafsir({
    required String editionId,
    required int surahNumber,
  });
}
