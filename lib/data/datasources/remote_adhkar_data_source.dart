import '../../models/content_source.dart';
import '../../models/dhikr.dart';
import '../../services/api_client.dart';
import 'adhkar_data_source.dart';

/// مصدر بيانات الأذكار البعيد:
/// - الأذكار من الموقع الرسمي لكتاب حصن المسلم (hisnmuslim.com)
/// - أسماء الله الحسنى من واجهة AlAdhan الرسمية
class RemoteAdhkarDataSource implements AdhkarDataSource {
  RemoteAdhkarDataSource({ApiClient? hisnClient, ApiClient? namesClient})
      : _hisn = hisnClient ?? ApiClient(baseUrl: _hisnBaseUrl),
        _names = namesClient ?? ApiClient(baseUrl: _namesBaseUrl);

  static const String _hisnBaseUrl = 'https://www.hisnmuslim.com/api/ar';
  static const String _namesBaseUrl = 'https://api.aladhan.com/v1';
  static const String _hisnSourceName =
      'حصن المسلم — سعيد بن علي بن وهف القحطاني (الموقع الرسمي)';
  static const String _hisnScholar = 'سعيد بن علي بن وهف القحطاني';
  static const String _hisnUrl = 'https://www.hisnmuslim.com';

  /// تصنيفات التطبيق التسعة وأبواب حصن المسلم المكوِّنة لكل منها.
  static const List<({String id, String title, List<int> chapters})>
      categoryMap = [
    (id: 'morning-evening', title: 'أذكار الصباح والمساء', chapters: [27]),
    (id: 'sleep', title: 'أذكار النوم', chapters: [28]),
    (id: 'wake', title: 'أذكار الاستيقاظ من النوم', chapters: [1]),
    (id: 'prayer', title: 'الأذكار بعد السلام من الصلاة', chapters: [25]),
    (id: 'travel', title: 'أذكار السفر', chapters: [96, 102, 105]),
    (id: 'mosque', title: 'أذكار المسجد', chapters: [12, 13, 14]),
    (id: 'food', title: 'أذكار الطعام والشراب', chapters: [69, 70, 71]),
    (id: 'istighfar', title: 'الاستغفار والتوبة', chapters: [129]),
    (
      id: 'tasbih',
      title: 'فضل التسبيح والتحميد والتهليل والتكبير',
      chapters: [130]
    ),
  ];

  final ApiClient _hisn;
  final ApiClient _names;

  ContentSource _hisnSource(String reference) => ContentSource(
        sourceName: _hisnSourceName,
        authorOrScholar: _hisnScholar,
        reference: reference,
        sourceUrl: _hisnUrl,
        lastUpdated: DateTime.now(),
      );

  @override
  Future<List<DhikrCategoryModel>> fetchCategories() async {
    // التحقق من توفر المصدر ثم إعادة التصنيفات المعتمدة
    await _hisn.getJson('/husn_ar.json');
    final source = _hisnSource('husn_ar.json');
    return categoryMap
        .map((c) => DhikrCategoryModel(
              id: c.id,
              title: c.title,
              source: source,
            ))
        .toList();
  }

  @override
  Future<List<DhikrModel>> fetchAdhkar(String categoryId) async {
    final category =
        categoryMap.where((c) => c.id == categoryId).firstOrNull;
    if (category == null) {
      throw AdhkarUnavailableException('تصنيف غير معروف: $categoryId');
    }

    final adhkar = <DhikrModel>[];
    for (final chapter in category.chapters) {
      final json =
          await _hisn.getJson('/$chapter.json') as Map<String, dynamic>;
      final chapterTitle = json.keys.first;
      final items = json[chapterTitle] as List<dynamic>;
      for (final i in items) {
        final item = i as Map<String, dynamic>;
        final text = (item['ARABIC_TEXT'] as String? ?? '').trim();
        if (text.isEmpty) continue;
        final itemId = item['ID'];
        adhkar.add(DhikrModel(
          id: '$chapter-$itemId',
          categoryId: categoryId,
          text: text,
          repeat: int.tryParse('${item['REPEAT'] ?? 1}') ?? 1,
          chapterTitle: chapterTitle,
          source: _hisnSource('$chapterTitle — ذكر رقم $itemId'),
        ));
      }
    }
    return adhkar;
  }

  @override
  Future<List<DhikrModel>> searchAdhkar(String query) {
    throw const AdhkarUnavailableException(
      'البحث النصي غير متاح من المصدر البعيد — يتم محلياً',
    );
  }

  @override
  Future<List<AllahNameModel>> fetchNamesOfAllah() async {
    final json =
        await _names.getJson('/asmaAlHusna') as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;
    final source = ContentSource(
      sourceName: 'AlAdhan API — أسماء الله الحسنى',
      reference: '/v1/asmaAlHusna',
      sourceUrl: 'https://aladhan.com',
      lastUpdated: DateTime.now(),
    );
    return data.map((n) {
      final name = n as Map<String, dynamic>;
      return AllahNameModel(
        number: name['number'] as int,
        name: name['name'] as String,
        transliteration: name['transliteration'] as String?,
        meaning:
            (name['en'] as Map<String, dynamic>?)?['meaning'] as String?,
        source: source,
      );
    }).toList();
  }

  void dispose() {
    _hisn.dispose();
    _names.dispose();
  }
}
