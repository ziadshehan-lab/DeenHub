import '../../core/utils/html_text.dart';
import '../../models/content_source.dart';
import '../../models/tafsir_models.dart';
import '../../services/api_client.dart';
import 'tafsir_data_source.dart';

/// مصدر بيانات تفسير عبر واجهة AlQuran Cloud الرسمية — يوفر تفسير
/// الجلالين بالعربية (غير المتاح لدى Quran.com).
///
/// التوثيق: https://alquran.cloud/api
class AlQuranCloudTafsirDataSource implements TafsirDataSource {
  AlQuranCloudTafsirDataSource({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: _baseUrl);

  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const String _sourceUrl = 'https://alquran.cloud';

  /// ربط المعرّفات الداخلية الموحّدة بمعرّفات الإصدارات لدى المصدر.
  static const Map<String, String> _remoteEditions = {
    'jalalayn': 'ar.jalalayn',
  };

  static const Map<String, ({String name, String scholar})> _editionMeta = {
    'jalalayn': (
      name: 'تفسير الجلالين',
      scholar: 'جلال الدين المحلي وجلال الدين السيوطي',
    ),
  };

  final ApiClient _client;

  @override
  bool supportsEdition(String editionId) =>
      _remoteEditions.containsKey(editionId);

  @override
  Future<List<TafsirEditionModel>> fetchEditions() async {
    final json = await _client.getJson(
      '/edition',
      queryParameters: {'type': 'tafsir', 'language': 'ar'},
    ) as Map<String, dynamic>;
    final editions = (json['data'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['identifier'] as String)
        .toSet();

    final source = ContentSource(
      sourceName: 'AlQuran Cloud — سجل كتب التفسير',
      reference: '/edition?type=tafsir',
      sourceUrl: _sourceUrl,
      lastUpdated: DateTime.now(),
    );

    return _editionMeta.entries.map((entry) {
      final remoteEditionId = _remoteEditions[entry.key]!;
      return TafsirEditionModel(
        id: entry.key,
        nameArabic: entry.value.name,
        scholar: entry.value.scholar,
        available: editions.contains(remoteEditionId),
        source: source,
      );
    }).toList();
  }

  @override
  Future<TafsirModel> fetchTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final remoteEdition = _remoteEditions[editionId];
    final meta = _editionMeta[editionId];
    if (remoteEdition == null || meta == null) {
      throw TafsirUnavailableException(
        'التفسير "$editionId" غير متاح من AlQuran Cloud',
      );
    }

    final verseKey = '$surahNumber:$ayahNumber';
    final json = await _client.getJson('/ayah/$verseKey/$remoteEdition')
        as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final text = stripHtml(data['text'] as String? ?? '');
    if (text.isEmpty) {
      throw TafsirUnavailableException(
        'لا يوجد نص تفسير للآية $verseKey في ${meta.name}',
      );
    }

    return TafsirModel(
      editionId: editionId,
      editionName: meta.name,
      scholar: meta.scholar,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      text: text,
      source: ContentSource(
        sourceName: '${meta.name} (عبر AlQuran Cloud)',
        authorOrScholar: meta.scholar,
        reference: '$remoteEdition — $verseKey',
        sourceUrl: _sourceUrl,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<TafsirModel>> searchTafsir(String query) {
    throw const TafsirUnavailableException(
      'البحث النصي غير متاح من AlQuran Cloud',
    );
  }

  void dispose() => _client.dispose();
}
