import '../../models/content_source.dart';
import '../../models/hadith_models.dart';
import '../../services/api_client.dart';
import 'hadith_data_source.dart';

/// مصدر بيانات الحديث البعيد — يعتمد واجهة موسوعة الأحاديث النبوية
/// الرسمية (HadeethEnc.com): تصفح الأقسام والأبواب، النص العربي
/// والإنجليزي، العزو، الدرجة، والشرح.
///
/// التوثيق: https://hadeethenc.com/ar/home/api
class RemoteHadithDataSource implements HadithDataSource {
  RemoteHadithDataSource({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: _baseUrl);

  static const String _baseUrl = 'https://hadeethenc.com/api/v1';
  static const String _sourceName =
      'موسوعة الأحاديث النبوية — HadeethEnc.com';
  static const String _sourceUrl = 'https://hadeethenc.com';

  final ApiClient _client;

  // شجرة التصنيفات كاملة — تُجلب مرة واحدة لاستخراج أبواب أي كتاب.
  List<dynamic>? _allCategories;

  ContentSource _sourceInfo(String reference) => ContentSource(
        sourceName: _sourceName,
        reference: reference,
        sourceUrl: _sourceUrl,
        lastUpdated: DateTime.now(),
      );

  @override
  bool get isConfigured => true;

  @override
  Future<List<HadithBookModel>> fetchBooks() async {
    final json = await _client.getJson(
      '/categories/roots/',
      queryParameters: {'language': 'ar'},
    ) as List<dynamic>;
    final source = _sourceInfo('/categories/roots');
    return json.map((c) {
      final category = c as Map<String, dynamic>;
      return HadithBookModel(
        id: category['id'] as String,
        title: category['title'] as String,
        hadithCount:
            int.tryParse(category['hadeeths_count'] as String? ?? ''),
        source: source,
      );
    }).toList();
  }

  @override
  Future<List<HadithChapterModel>> fetchChapters(String bookId) async {
    _allCategories ??= await _client.getJson(
      '/categories/list/',
      queryParameters: {'language': 'ar'},
    ) as List<dynamic>;
    final source = _sourceInfo('/categories/list');
    return _allCategories!
        .cast<Map<String, dynamic>>()
        .where((c) => c['parent_id'] == bookId)
        .map((c) => HadithChapterModel(
              id: c['id'] as String,
              bookId: bookId,
              title: c['title'] as String,
              hadithCount:
                  int.tryParse(c['hadeeths_count'] as String? ?? ''),
              source: source,
            ))
        .toList();
  }

  @override
  Future<List<HadithModel>> fetchHadiths(
    String chapterId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _client.getJson(
      '/hadeeths/list/',
      queryParameters: {
        'language': 'ar',
        'category_id': chapterId,
        'page': '$page',
        'per_page': '$pageSize',
      },
    ) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;
    return data.map((h) {
      final item = h as Map<String, dynamic>;
      final id = item['id'] as String;
      return HadithModel(
        id: id,
        chapterId: chapterId,
        title: item['title'] as String?,
        textArabic: item['title'] as String? ?? '',
        source: _sourceInfo('حديث رقم $id'),
      );
    }).toList();
  }

  @override
  Future<HadithModel> fetchHadith(String hadithId) async {
    final ar = await _client.getJson(
      '/hadeeths/one/',
      queryParameters: {'language': 'ar', 'id': hadithId},
    ) as Map<String, dynamic>;

    // النص الإنجليزي إن كان متوفراً ضمن ترجمات الحديث
    String? english;
    final translations =
        (ar['translations'] as List<dynamic>? ?? const []).cast<String>();
    if (translations.contains('en')) {
      try {
        final en = await _client.getJson(
          '/hadeeths/one/',
          queryParameters: {'language': 'en', 'id': hadithId},
        ) as Map<String, dynamic>;
        english = en['hadeeth'] as String?;
      } catch (_) {
        // الترجمة تحسين اختياري — لا تُفشل الجلب
      }
    }

    final reference = ar['reference'] as String?;
    return HadithModel(
      id: hadithId,
      title: ar['title'] as String?,
      textArabic: ar['hadeeth'] as String,
      textEnglish: english,
      narrator: _narratorFromIntro(ar['hadeeth_intro'] as String?),
      attribution: ar['attribution'] as String?,
      grade: ar['grade'] as String?,
      explanation: ar['explanation'] as String?,
      source: ContentSource(
        sourceName: _sourceName,
        reference: reference == null || reference.isEmpty
            ? 'حديث رقم $hadithId'
            : reference,
        sourceUrl: '$_sourceUrl/ar/browse/hadith/$hadithId',
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// استخراج الراوي من مقدمة الحديث («عَنْ فلان رضي الله عنه قَالَ:»).
  static String? _narratorFromIntro(String? intro) {
    if (intro == null || intro.trim().isEmpty) return null;
    return intro
        .replaceAll(RegExp(r'[،,]?\s*قَالَ[تْ]?\s*:?\s*$'), '')
        .trim();
  }

  @override
  Future<List<HadithSearchResultModel>> searchHadiths(String query) {
    throw const HadithUnavailableException(
      'البحث النصي غير متاح من موسوعة الأحاديث النبوية',
    );
  }

  void dispose() => _client.dispose();
}
