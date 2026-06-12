import '../../core/utils/html_text.dart';
import '../../models/content_source.dart';
import '../../models/tafsir_models.dart';
import '../../services/api_client.dart';
import 'tafsir_data_source.dart';

/// مصدر بيانات التفسير البعيد — يعتمد واجهة Quran.com الرسمية (v4).
///
/// التوثيق: https://api-docs.quran.com
class RemoteTafsirDataSource implements TafsirDataSource {
  RemoteTafsirDataSource({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: _baseUrl);

  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static const String _sourceUrl = 'https://quran.com';

  /// ربط المعرّفات الداخلية الموحّدة بمعرّفات الكتب لدى Quran.com.
  /// (الجلالين غير متاح بالعربية لدى هذا المصدر بعد.)
  static const Map<String, int> _remoteIds = {
    'saadi': 91,
    'ibn-kathir': 14,
    'tabari': 15,
    'qurtubi': 90,
  };

  /// أسماء الكتب والمؤلفين بالعربية حسب المعرّف الموحّد — بيانات وصفية
  /// للسجل، أما نص التفسير فيُجلب دائماً من المصدر.
  static const Map<String, ({String name, String scholar})> _editionMeta = {
    'saadi': (
      name: 'تفسير السعدي',
      scholar: 'عبد الرحمن بن ناصر السعدي',
    ),
    'ibn-kathir': (
      name: 'تفسير ابن كثير',
      scholar: 'إسماعيل بن عمر بن كثير',
    ),
    'tabari': (
      name: 'تفسير الطبري',
      scholar: 'محمد بن جرير الطبري',
    ),
    'qurtubi': (
      name: 'تفسير القرطبي',
      scholar: 'محمد بن أحمد القرطبي',
    ),
  };

  final ApiClient _client;

  @override
  bool supportsEdition(String editionId) =>
      _remoteIds.containsKey(editionId);

  @override
  Future<List<TafsirModel>> searchTafsir(String query) {
    throw const TafsirUnavailableException(
      'البحث النصي في التفسير غير متاح من Quran.com',
    );
  }

  @override
  Future<List<TafsirEditionModel>> fetchEditions() async {
    final json = await _client.getJson('/resources/tafsirs')
        as Map<String, dynamic>;
    final tafsirs = json['tafsirs'] as List<dynamic>;

    // معرّفات الكتب العربية المتاحة فعلياً لدى المصدر الآن
    final availableRemoteIds = tafsirs
        .map((t) => (t as Map<String, dynamic>)['id'] as int)
        .toSet();

    final source = ContentSource(
      sourceName: 'Quran.com — سجل كتب التفسير',
      reference: '/resources/tafsirs',
      sourceUrl: _sourceUrl,
      lastUpdated: DateTime.now(),
    );

    return _editionMeta.entries.map((entry) {
      final remoteId = _remoteIds[entry.key];
      return TafsirEditionModel(
        id: entry.key,
        remoteId: remoteId,
        nameArabic: entry.value.name,
        scholar: entry.value.scholar,
        available:
            remoteId != null && availableRemoteIds.contains(remoteId),
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
    final remoteId = _remoteIds[editionId];
    final meta = _editionMeta[editionId];
    if (remoteId == null || meta == null) {
      throw TafsirUnavailableException(
        'التفسير "$editionId" غير متاح من المصدر البعيد',
      );
    }

    final verseKey = '$surahNumber:$ayahNumber';
    final json = await _client.getJson('/tafsirs/$remoteId/by_ayah/$verseKey')
        as Map<String, dynamic>;
    final tafsir = json['tafsir'] as Map<String, dynamic>;
    final text = stripHtml(tafsir['text'] as String? ?? '');
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
        sourceName: '${meta.name} (عبر Quran.com)',
        authorOrScholar: meta.scholar,
        reference: '${tafsir['slug'] ?? remoteId} — $verseKey',
        sourceUrl: _sourceUrl,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void dispose() => _client.dispose();
}
