import '../../core/utils/html_text.dart';
import '../../models/content_source.dart';
import '../../models/hadith_models.dart';
import '../../services/api_client.dart';
import 'hadith_data_source.dart';

/// مصدر بحث الحديث عبر واجهة الدرر السنية الرسمية (dorar.net):
/// نتائج بحث عربية مع الراوي والمحدِّث والمصدر ودرجة الحكم.
///
/// التوثيق: https://dorar.net/article/466
class DorarHadithDataSource implements HadithDataSource {
  DorarHadithDataSource({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: _baseUrl);

  static const String _baseUrl = 'https://dorar.net';
  static const String _sourceName = 'الدرر السنية — الموسوعة الحديثية';
  static const String _sourceUrl = 'https://dorar.net/hadith';

  final ApiClient _client;

  @override
  bool get isConfigured => true;

  @override
  Future<List<HadithSearchResultModel>> searchHadiths(String query) async {
    final json = await _client.getJson(
      '/dorar_api.json',
      queryParameters: {'skey': query},
    ) as Map<String, dynamic>;
    final ahadith = json['ahadith'] as Map<String, dynamic>;
    final html = ahadith['result'] as String? ?? '';
    return parseResults(html);
  }

  /// تحليل نتائج الدرر: كتل HTML تحوي نص الحديث ثم سطر معلومات بصيغة
  /// «الراوي: X | المحدث: Y | المصدر: Z | الصفحة أو الرقم: N |
  /// خلاصة حكم المحدث: صحيح».
  static List<HadithSearchResultModel> parseResults(String html) {
    final source = ContentSource(
      sourceName: _sourceName,
      reference: 'dorar_api.json',
      sourceUrl: _sourceUrl,
      lastUpdated: DateTime.now(),
    );

    final results = <HadithSearchResultModel>[];
    // كل نتيجة: <div class="hadith">النص</div> يتبعها كتلة معلومات
    final blocks = stripHtml(html)
        .split(RegExp(r'\n?\s*الراوي\s*:'))
        .where((b) => b.trim().isNotEmpty)
        .toList();
    if (blocks.length < 2) return results;

    String? field(String text, String name) {
      final match = RegExp('$name\\s*:\\s*([^|\\n]+)').firstMatch(text);
      return match?.group(1)?.trim();
    }

    for (var i = 1; i < blocks.length; i++) {
      final text = blocks[i - 1]
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      // نص الحديث هو آخر سطر قبل سطر «الراوي»
      if (text.isEmpty) continue;
      final info = 'الراوي: ${blocks[i]}';
      results.add(HadithSearchResultModel(
        text: text.last.trim(),
        narrator: field(info, 'الراوي'),
        muhaddith: field(info, 'المحدث'),
        bookName: field(info, 'المصدر'),
        hadithNumber: field(info, 'الصفحة أو الرقم'),
        grade: field(info, 'خلاصة حكم المحدث'),
        source: source,
      ));
    }
    return results;
  }

  @override
  Future<List<HadithBookModel>> fetchBooks() {
    throw const HadithUnavailableException(
      'تصفح الكتب غير متاح من واجهة الدرر السنية',
    );
  }

  @override
  Future<List<HadithChapterModel>> fetchChapters(String bookId) {
    throw const HadithUnavailableException(
      'تصفح الأبواب غير متاح من واجهة الدرر السنية',
    );
  }

  @override
  Future<List<HadithModel>> fetchHadiths(
    String chapterId, {
    int page = 1,
    int pageSize = 20,
  }) {
    throw const HadithUnavailableException(
      'قوائم الأحاديث غير متاحة من واجهة الدرر السنية',
    );
  }

  @override
  Future<HadithModel> fetchHadith(String hadithId) {
    throw const HadithUnavailableException(
      'جلب حديث بمعرّفه غير متاح من واجهة الدرر السنية',
    );
  }

  void dispose() => _client.dispose();
}
