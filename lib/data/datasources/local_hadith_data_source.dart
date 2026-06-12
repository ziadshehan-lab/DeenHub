import '../../core/utils/arabic_text.dart';
import '../../models/content_source.dart';
import '../../models/hadith_models.dart';
import '../../services/asset_data_loader.dart';
import 'hadith_data_source.dart';

/// مصدر بيانات الحديث المحلي — يقرأ عينة حقيقية من موسوعة الأحاديث
/// النبوية مضمَّنة كملفات JSON (lib/assets_data/hadith) فيعمل التصفح
/// والبحث دون اتصال.
///
/// الكتب المتوفرة محلياً معلنة في `localBooks` بملف books.json،
/// ويُرمى [HadithUnavailableException] لما عداها.
class LocalHadithDataSource implements HadithDataSource {
  LocalHadithDataSource({AssetDataLoader? loader})
      : _loader = loader ?? const AssetDataLoader();

  final AssetDataLoader _loader;

  List<HadithBookModel>? _books;
  List<String> _localBookIds = [];
  final Map<String, List<HadithChapterModel>> _chaptersByBook = {};
  final Map<String, List<HadithModel>> _hadithsByChapter = {};

  @override
  bool get isConfigured => true;

  @override
  Future<List<HadithBookModel>> fetchBooks() async {
    if (_books != null) return _books!;

    final json =
        await _loader.loadJson('hadith/books.json') as Map<String, dynamic>;
    final source =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    _localBookIds =
        (json['localBooks'] as List<dynamic>).cast<String>();
    _books = (json['books'] as List<dynamic>)
        .map((b) => HadithBookModel.fromJson(
              b as Map<String, dynamic>,
              source: source,
            ))
        .toList();
    return _books!;
  }

  @override
  Future<List<HadithChapterModel>> fetchChapters(String bookId) async {
    await fetchBooks();
    final cached = _chaptersByBook[bookId];
    if (cached != null) return cached;

    if (!_localBookIds.contains(bookId)) {
      throw HadithUnavailableException(
        'أبواب هذا الكتاب غير متاحة دون اتصال: $bookId',
      );
    }
    final json = await _loader.loadJson('hadith/chapters_$bookId.json')
        as Map<String, dynamic>;
    final source =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    final chapters = (json['chapters'] as List<dynamic>)
        .map((c) => HadithChapterModel.fromJson(
              c as Map<String, dynamic>,
              bookId: bookId,
              source: source,
            ))
        .toList();
    _chaptersByBook[bookId] = chapters;
    return chapters;
  }

  Future<List<HadithModel>> _loadChapterHadiths(String chapterId) async {
    final cached = _hadithsByChapter[chapterId];
    if (cached != null) return cached;

    final Map<String, dynamic> json;
    try {
      json = await _loader.loadJson('hadith/hadiths_$chapterId.json')
          as Map<String, dynamic>;
    } catch (_) {
      throw HadithUnavailableException(
        'أحاديث هذا الباب غير متاحة دون اتصال: $chapterId',
      );
    }
    final source =
        ContentSource.fromJson(json['source'] as Map<String, dynamic>);
    final hadiths = (json['hadiths'] as List<dynamic>).map((h) {
      final item = h as Map<String, dynamic>;
      final reference = item['reference'] as String?;
      final id = item['id'] as String;
      return HadithModel(
        id: id,
        chapterId: chapterId,
        title: item['title'] as String?,
        textArabic: item['textArabic'] as String,
        textEnglish: item['textEnglish'] as String?,
        narrator: item['narrator'] as String?,
        attribution: item['attribution'] as String?,
        grade: item['grade'] as String?,
        explanation: item['explanation'] as String?,
        source: ContentSource(
          sourceName: source.sourceName,
          reference: reference == null || reference.isEmpty
              ? 'حديث رقم $id'
              : reference,
          sourceUrl: '${source.sourceUrl}/ar/browse/hadith/$id',
          lastUpdated: source.lastUpdated,
        ),
      );
    }).toList();
    _hadithsByChapter[chapterId] = hadiths;
    return hadiths;
  }

  @override
  Future<List<HadithModel>> fetchHadiths(
    String chapterId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final all = await _loadChapterHadiths(chapterId);
    final start = (page - 1) * pageSize;
    if (start >= all.length) return const [];
    return all.sublist(
        start, (start + pageSize).clamp(0, all.length));
  }

  @override
  Future<HadithModel> fetchHadith(String hadithId) async {
    // الأحاديث المحلية موزعة على ملفات الأبواب — ابحث فيها كلها
    for (final chapterId in await _localChapterIds()) {
      final hadiths = await _loadChapterHadiths(chapterId);
      for (final hadith in hadiths) {
        if (hadith.id == hadithId) return hadith;
      }
    }
    throw HadithUnavailableException(
      'الحديث غير متاح دون اتصال: $hadithId',
    );
  }

  Future<List<String>> _localChapterIds() async {
    await fetchBooks();
    final ids = <String>[];
    for (final bookId in _localBookIds) {
      final chapters = await fetchChapters(bookId);
      ids.addAll(chapters.map((c) => c.id));
    }
    return ids;
  }

  @override
  Future<List<HadithSearchResultModel>> searchHadiths(String query) async {
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.isEmpty) return const [];

    final results = <HadithSearchResultModel>[];
    bool matches(String? value) =>
        value != null && normalizeArabic(value).contains(normalizedQuery);

    // البحث في الأبواب بأسمائها، وفي الأحاديث بنصها وعنوانها وراويها
    await fetchBooks();
    for (final bookId in _localBookIds) {
      final chapters = await fetchChapters(bookId);
      for (final chapter in chapters) {
        final hadiths = await _loadChapterHadiths(chapter.id);
        final chapterMatches = matches(chapter.title);
        for (final hadith in hadiths) {
          if (chapterMatches ||
              matches(hadith.textArabic) ||
              matches(hadith.title) ||
              matches(hadith.narrator)) {
            results.add(HadithSearchResultModel(
              hadithId: hadith.id,
              text: hadith.textArabic,
              narrator: hadith.narrator,
              grade: hadith.grade,
              bookName: hadith.attribution,
              source: hadith.source,
            ));
            if (results.length >= 50) return results;
          }
        }
      }
    }
    return results;
  }
}
