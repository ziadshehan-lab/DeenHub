import '../../core/constants/app_constants.dart';
import '../../core/utils/html_text.dart';
import '../../models/content_source.dart';
import '../../models/hadith_models.dart';
import '../../services/api_client.dart';
import 'hadith_data_source.dart';

/// مصدر بيانات الحديث عبر واجهة Sunnah.com الرسمية — المجموعات
/// الكلاسيكية (صحيح البخاري، صحيح مسلم...).
///
/// يتطلب مفتاح API يُطلب من فريق Sunnah.com
/// (https://sunnah.api-docs.io)؛ يُهيأ في [AppConstants.sunnahComApiKey]
/// ويتفعل المصدر تلقائياً عند توفره.
///
/// معرّفات هذا المصدر مركبة:
/// - الكتاب: اسم المجموعة (`bukhari`)
/// - الباب: `collection/bookNumber` (مثل `bukhari/1`)
/// - الحديث: `collection@hadithNumber` (مثل `bukhari@1`)
class SunnahComHadithDataSource implements HadithDataSource {
  SunnahComHadithDataSource({ApiClient? client, String? apiKey})
      : _client = client ?? ApiClient(baseUrl: _baseUrl),
        _apiKey = apiKey ?? AppConstants.sunnahComApiKey;

  static const String _baseUrl = 'https://api.sunnah.com/v1';
  static const String _sourceName = 'Sunnah.com';
  static const String _sourceUrl = 'https://sunnah.com';

  final ApiClient _client;
  final String _apiKey;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  Map<String, String> get _headers => {'X-API-Key': _apiKey};

  void _requireKey() {
    if (!isConfigured) {
      throw const HadithUnavailableException(
        'واجهة Sunnah.com تتطلب مفتاح API — لم يُهيأ بعد',
      );
    }
  }

  ContentSource _sourceInfo(String reference, {String? url}) =>
      ContentSource(
        sourceName: _sourceName,
        reference: reference,
        sourceUrl: url ?? _sourceUrl,
        lastUpdated: DateTime.now(),
      );

  /// نص الحديث بلغة محددة من مصفوفة `hadith` في الاستجابة.
  static Map<String, dynamic>? _languageEntry(
    List<dynamic> hadithLangs,
    String lang,
  ) {
    for (final h in hadithLangs) {
      final entry = h as Map<String, dynamic>;
      if ((entry['lang'] as String?) == lang) return entry;
    }
    return null;
  }

  @override
  Future<List<HadithBookModel>> fetchBooks() async {
    _requireKey();
    final json = await _client.getJson(
      '/collections',
      queryParameters: {'limit': '50'},
      headers: _headers,
    ) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;
    return data.map((c) {
      final collection = c as Map<String, dynamic>;
      final name = collection['name'] as String;
      final titles = collection['collection'] as List<dynamic>;
      final arabic = _languageEntry(titles, 'ar');
      final english = _languageEntry(titles, 'en');
      return HadithBookModel(
        id: name,
        title: (arabic?['title'] as String?) ??
            (english?['title'] as String?) ??
            name,
        titleEnglish: english?['title'] as String?,
        hadithCount: collection['totalAvailableHadith'] as int?,
        source: _sourceInfo('/collections/$name',
            url: '$_sourceUrl/$name'),
      );
    }).toList();
  }

  @override
  Future<List<HadithChapterModel>> fetchChapters(String bookId) async {
    _requireKey();
    final json = await _client.getJson(
      '/collections/$bookId/books',
      queryParameters: {'limit': '100'},
      headers: _headers,
    ) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;
    return data.map((b) {
      final book = b as Map<String, dynamic>;
      final bookNumber = book['bookNumber'] as String;
      final titles = book['book'] as List<dynamic>;
      final arabic = _languageEntry(titles, 'ar');
      final english = _languageEntry(titles, 'en');
      return HadithChapterModel(
        id: '$bookId/$bookNumber',
        bookId: bookId,
        title: (arabic?['name'] as String?) ??
            (english?['name'] as String?) ??
            bookNumber,
        hadithCount: book['numberOfHadith'] as int?,
        source: _sourceInfo('/collections/$bookId/books/$bookNumber',
            url: '$_sourceUrl/$bookId/$bookNumber'),
      );
    }).toList();
  }

  @override
  Future<List<HadithModel>> fetchHadiths(
    String chapterId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    _requireKey();
    final parts = chapterId.split('/');
    if (parts.length != 2) {
      throw HadithUnavailableException('معرّف باب غير صالح: $chapterId');
    }
    final json = await _client.getJson(
      '/collections/${parts[0]}/books/${parts[1]}/hadiths',
      queryParameters: {'limit': '$pageSize', 'page': '$page'},
      headers: _headers,
    ) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>;
    return data
        .map((h) => _hadithFromJson(h as Map<String, dynamic>, parts[0],
            chapterId: chapterId))
        .toList();
  }

  @override
  Future<HadithModel> fetchHadith(String hadithId) async {
    _requireKey();
    final parts = hadithId.split('@');
    if (parts.length != 2) {
      throw HadithUnavailableException('معرّف حديث غير صالح: $hadithId');
    }
    final json = await _client.getJson(
      '/collections/${parts[0]}/hadiths/${parts[1]}',
      headers: _headers,
    ) as Map<String, dynamic>;
    return _hadithFromJson(json, parts[0]);
  }

  HadithModel _hadithFromJson(
    Map<String, dynamic> json,
    String collection, {
    String? chapterId,
  }) {
    final hadithNumber = json['hadithNumber'].toString();
    final langs = json['hadith'] as List<dynamic>;
    final arabic = _languageEntry(langs, 'ar');
    final english = _languageEntry(langs, 'en');
    // درجة الحديث من أول قائمة درجات غير فارغة (عربية ثم إنجليزية)
    List<dynamic>? gradesOf(Map<String, dynamic>? entry) {
      final grades = entry?['grades'] as List<dynamic>?;
      return grades == null || grades.isEmpty ? null : grades;
    }

    final grades = gradesOf(arabic) ?? gradesOf(english);
    final grade = grades == null
        ? null
        : (grades.first as Map<String, dynamic>)['grade'] as String?;

    return HadithModel(
      id: '$collection@$hadithNumber',
      bookId: collection,
      chapterId: chapterId,
      textArabic: stripHtml(arabic?['body'] as String? ?? ''),
      textEnglish: english?['body'] == null
          ? null
          : stripHtml(english!['body'] as String),
      narrator: english?['chapterTitle'] as String?,
      attribution: collection,
      grade: grade,
      source: _sourceInfo(
        '$collection $hadithNumber',
        url: '$_sourceUrl/$collection:$hadithNumber',
      ),
    );
  }

  @override
  Future<List<HadithSearchResultModel>> searchHadiths(String query) {
    throw const HadithUnavailableException(
      'البحث النصي غير متاح من واجهة Sunnah.com',
    );
  }

  void dispose() => _client.dispose();
}
