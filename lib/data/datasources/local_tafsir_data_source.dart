import '../../core/utils/arabic_text.dart';
import '../../models/content_source.dart';
import '../../models/tafsir_models.dart';
import '../../services/asset_data_loader.dart';
import 'tafsir_data_source.dart';

/// مصدر بيانات التفسير المحلي — يقرأ سجل الكتب وعينات نصوص التفسير من
/// ملفات JSON مضمَّنة مع التطبيق (lib/assets_data/tafsir).
///
/// يعمل احتياطياً عند انقطاع الاتصال؛ السور المتوفرة محلياً لكل كتاب
/// معلنة في حقل `localSurahs` بسجل الكتب، ويُرمى
/// [TafsirUnavailableException] لما عداها.
class LocalTafsirDataSource implements TafsirDataSource {
  LocalTafsirDataSource({AssetDataLoader? loader})
      : _loader = loader ?? const AssetDataLoader();

  final AssetDataLoader _loader;

  List<TafsirEditionModel>? _editions;
  final Map<String, Map<int, String>> _textCache = {};
  final Map<String, ContentSource> _surahSources = {};

  @override
  bool supportsEdition(String editionId) => true; // السجل يحوي كل الكتب

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

  Future<TafsirEditionModel> _requireEdition(String editionId) async {
    final editions = await fetchEditions();
    final edition = editions.where((e) => e.id == editionId).firstOrNull;
    if (edition == null) {
      throw TafsirUnavailableException('كتاب تفسير غير معروف: $editionId');
    }
    return edition;
  }

  /// تحميل نصوص سورة لكتاب محدد إلى الذاكرة (مرة واحدة).
  Future<Map<int, String>> _loadSurahTexts(
    TafsirEditionModel edition,
    int surahNumber,
  ) async {
    final cacheKey = '${edition.id}/$surahNumber';
    final cached = _textCache[cacheKey];
    if (cached != null) return cached;

    if (!edition.localSurahs.contains(surahNumber)) {
      throw TafsirUnavailableException(
        '${edition.nameArabic} غير متاح دون اتصال للسورة $surahNumber',
      );
    }
    final json = await _loader.loadJson(
      'tafsir/${edition.id}/surah_$surahNumber.json',
    ) as Map<String, dynamic>;
    final entries = json['entries'] as List<dynamic>;
    final texts = {
      for (final e in entries)
        (e as Map<String, dynamic>)['ayahNumber'] as int: e['text'] as String,
    };
    _textCache[cacheKey] = texts;
    _surahSources[cacheKey] =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    return texts;
  }

  @override
  Future<TafsirModel> fetchTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final edition = await _requireEdition(editionId);
    final texts = await _loadSurahTexts(edition, surahNumber);
    final text = texts[ayahNumber];
    if (text == null) {
      throw TafsirUnavailableException(
        'لا يوجد نص محلي للآية $surahNumber:$ayahNumber في ${edition.nameArabic}',
      );
    }
    return _buildModel(edition, surahNumber, ayahNumber, text);
  }

  @override
  Future<List<TafsirModel>> searchTafsir(String query) async {
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.isEmpty) return const [];

    final results = <TafsirModel>[];
    final editions = await fetchEditions();
    for (final edition in editions) {
      for (final surahNumber in edition.localSurahs) {
        final texts = await _loadSurahTexts(edition, surahNumber);
        for (final entry in texts.entries) {
          if (normalizeArabic(entry.value).contains(normalizedQuery)) {
            results.add(
              _buildModel(edition, surahNumber, entry.key, entry.value),
            );
            if (results.length >= 50) return results;
          }
        }
      }
    }
    return results;
  }

  TafsirModel _buildModel(
    TafsirEditionModel edition,
    int surahNumber,
    int ayahNumber,
    String text,
  ) {
    return TafsirModel(
      editionId: edition.id,
      editionName: edition.nameArabic,
      scholar: edition.scholar,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      text: text,
      source: _surahSources['${edition.id}/$surahNumber']!,
    );
  }
}
