import '../../models/content_source.dart';
import '../../models/tafsir_models.dart';
import '../../services/asset_data_loader.dart';
import 'tafsir_data_source.dart';

/// مصدر بيانات التفسير المحلي — يقرأ سجل الكتب وعينات نصوص التفسير من
/// ملفات JSON مضمَّنة مع التطبيق (lib/assets_data/tafsir).
///
/// يعمل احتياطياً عند انقطاع الاتصال؛ النصوص المتاحة محلياً محدودة
/// بالسور المضمَّنة، ويُرمى [TafsirUnavailableException] لما عداها.
class LocalTafsirDataSource implements TafsirDataSource {
  LocalTafsirDataSource({AssetDataLoader? loader})
      : _loader = loader ?? const AssetDataLoader();

  final AssetDataLoader _loader;

  List<TafsirEditionModel>? _editions;
  final Map<String, Map<int, String>> _textCache = {};

  @override
  Future<List<TafsirEditionModel>> fetchEditions() async {
    if (_editions != null) return _editions!;

    final json = await _loader.loadJson('tafsir/editions.json')
        as Map<String, dynamic>;
    final source =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    final list = json['editions'] as List<dynamic>;
    _editions = list
        .map((e) => TafsirEditionModel.fromJson(
              e as Map<String, dynamic>,
              source: source,
            ))
        .toList();
    return _editions!;
  }

  @override
  Future<TafsirModel> fetchTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final editions = await fetchEditions();
    final edition = editions.where((e) => e.id == editionId).firstOrNull;
    if (edition == null) {
      throw TafsirUnavailableException(
        'كتاب تفسير غير معروف: $editionId',
      );
    }

    final cacheKey = '$editionId/$surahNumber';
    var surahTexts = _textCache[cacheKey];
    if (surahTexts == null) {
      final Map<String, dynamic> json;
      try {
        json = await _loader.loadJson(
          'tafsir/$editionId/surah_$surahNumber.json',
        ) as Map<String, dynamic>;
      } catch (_) {
        throw TafsirUnavailableException(
          '${edition.nameArabic} غير متاح دون اتصال للسورة $surahNumber',
        );
      }
      final entries = json['entries'] as List<dynamic>;
      surahTexts = {
        for (final e in entries)
          (e as Map<String, dynamic>)['ayahNumber'] as int:
              e['text'] as String,
      };
      _textCache[cacheKey] = surahTexts;
      _surahSources[cacheKey] =
          ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    }

    final text = surahTexts[ayahNumber];
    if (text == null) {
      throw TafsirUnavailableException(
        'لا يوجد نص محلي للآية $surahNumber:$ayahNumber في ${edition.nameArabic}',
      );
    }

    return TafsirModel(
      editionId: editionId,
      editionName: edition.nameArabic,
      scholar: edition.scholar,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      text: text,
      source: _surahSources[cacheKey]!,
    );
  }

  final Map<String, ContentSource> _surahSources = {};
}
