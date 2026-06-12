import '../../core/utils/arabic_text.dart';
import '../../models/content_source.dart';
import '../../models/dhikr.dart';
import '../../services/asset_data_loader.dart';
import 'adhkar_data_source.dart';

/// مصدر الأذكار والأسماء الحسنى المحلي — المحتوى الكامل مضمَّن مع
/// التطبيق (من المصادر الرسمية نفسها) فيعمل كل شيء دون اتصال:
/// تسعة تصنيفات من حصن المسلم و٩٩ اسماً من واجهة AlAdhan.
class LocalAdhkarDataSource implements AdhkarDataSource {
  LocalAdhkarDataSource({AssetDataLoader? loader})
      : _loader = loader ?? const AssetDataLoader();

  final AssetDataLoader _loader;

  List<DhikrCategoryModel>? _categories;
  final Map<String, List<DhikrModel>> _adhkarByCategory = {};
  List<AllahNameModel>? _names;

  @override
  Future<List<DhikrCategoryModel>> fetchCategories() async {
    if (_categories != null) return _categories!;

    final json = await _loader.loadJson('adhkar/categories.json')
        as Map<String, dynamic>;
    final source =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    _categories = (json['categories'] as List<dynamic>).map((c) {
      final category = c as Map<String, dynamic>;
      return DhikrCategoryModel(
        id: category['id'] as String,
        title: category['title'] as String,
        dhikrCount: category['dhikrCount'] as int?,
        source: source,
      );
    }).toList();
    return _categories!;
  }

  @override
  Future<List<DhikrModel>> fetchAdhkar(String categoryId) async {
    final cached = _adhkarByCategory[categoryId];
    if (cached != null) return cached;

    final Map<String, dynamic> json;
    try {
      json = await _loader.loadJson('adhkar/category_$categoryId.json')
          as Map<String, dynamic>;
    } catch (_) {
      throw AdhkarUnavailableException(
        'لا توجد أذكار محلية للتصنيف: $categoryId',
      );
    }
    final source =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    final adhkar = (json['adhkar'] as List<dynamic>).map((d) {
      final item = d as Map<String, dynamic>;
      final chapterTitle = item['chapterTitle'] as String?;
      return DhikrModel(
        id: item['id'] as String,
        categoryId: categoryId,
        text: item['text'] as String,
        repeat: item['repeat'] as int? ?? 1,
        chapterTitle: chapterTitle,
        source: ContentSource(
          sourceName: source.sourceName,
          authorOrScholar: source.authorOrScholar,
          reference:
              '${chapterTitle ?? ''} — ذكر رقم ${item['hisnItemId']}',
          sourceUrl: source.sourceUrl,
          lastUpdated: source.lastUpdated,
        ),
      );
    }).toList();
    _adhkarByCategory[categoryId] = adhkar;
    return adhkar;
  }

  @override
  Future<List<DhikrModel>> searchAdhkar(String query) async {
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.isEmpty) return const [];

    bool matches(String? value) =>
        value != null && normalizeArabic(value).contains(normalizedQuery);

    final results = <DhikrModel>[];
    for (final category in await fetchCategories()) {
      final adhkar = await fetchAdhkar(category.id);
      final categoryMatches = matches(category.title);
      for (final dhikr in adhkar) {
        if (categoryMatches ||
            matches(dhikr.text) ||
            matches(dhikr.chapterTitle)) {
          results.add(dhikr);
          if (results.length >= 50) return results;
        }
      }
    }
    return results;
  }

  @override
  Future<List<AllahNameModel>> fetchNamesOfAllah() async {
    if (_names != null) return _names!;

    final json = await _loader.loadJson('adhkar/names.json')
        as Map<String, dynamic>;
    final source =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    _names = (json['names'] as List<dynamic>).map((n) {
      final name = n as Map<String, dynamic>;
      return AllahNameModel(
        number: name['number'] as int,
        name: name['name'] as String,
        transliteration: name['transliteration'] as String?,
        meaning: name['meaning'] as String?,
        explanation: name['explanation'] as String?,
        source: source,
      );
    }).toList();
    return _names!;
  }
}
