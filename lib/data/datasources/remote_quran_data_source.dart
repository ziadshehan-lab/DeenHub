import '../../models/quran_models.dart';
import '../../services/api_client.dart';
import 'quran_data_source.dart';

/// مصدر بيانات القرآن البعيد — يعتمد واجهة Quran.com الرسمية (v4).
///
/// التوثيق: https://api-docs.quran.com
class RemoteQuranDataSource implements QuranDataSource {
  RemoteQuranDataSource({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: _baseUrl);

  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static const String _sourceName = 'Quran.com — النص العثماني';
  static const String _sourceUrl = 'https://quran.com';

  final ApiClient _client;

  QuranSourceInfo _sourceInfo(String reference) => QuranSourceInfo(
        sourceName: _sourceName,
        reference: reference,
        sourceUrl: _sourceUrl,
        lastUpdated: DateTime.now(),
      );

  SurahModel _surahFromChapter(Map<String, dynamic> chapter) {
    final number = chapter['id'] as int;
    return SurahModel(
      number: number,
      nameArabic: chapter['name_arabic'] as String,
      nameTransliteration: chapter['name_simple'] as String?,
      ayahCount: chapter['verses_count'] as int,
      revelationPlace:
          (chapter['revelation_place'] as String) == 'makkah' ? 'مكية' : 'مدنية',
      source: _sourceInfo('chapter $number'),
    );
  }

  @override
  Future<List<SurahModel>> fetchSurahs() async {
    final json = await _client.getJson(
      '/chapters',
      queryParameters: {'language': 'ar'},
    ) as Map<String, dynamic>;
    final chapters = json['chapters'] as List<dynamic>;
    return chapters
        .map((c) => _surahFromChapter(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SurahModel> fetchSurah(int surahNumber) async {
    final json = await _client.getJson(
      '/chapters/$surahNumber',
      queryParameters: {'language': 'ar'},
    ) as Map<String, dynamic>;
    return _surahFromChapter(json['chapter'] as Map<String, dynamic>);
  }

  @override
  Future<List<AyahModel>> fetchAyahs(int surahNumber) async {
    final ayahs = <AyahModel>[];
    var page = 1;
    int? totalPages;
    do {
      final json = await _client.getJson(
        '/verses/by_chapter/$surahNumber',
        queryParameters: {
          'language': 'ar',
          'words': 'false',
          'fields': 'text_uthmani,juz_number,page_number',
          'per_page': '50',
          'page': '$page',
        },
      ) as Map<String, dynamic>;
      final verses = json['verses'] as List<dynamic>;
      for (final v in verses) {
        final verse = v as Map<String, dynamic>;
        final ayahNumber = verse['verse_number'] as int;
        ayahs.add(AyahModel(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          textArabic: (verse['text_uthmani'] as String).trim(),
          juz: verse['juz_number'] as int?,
          page: verse['page_number'] as int?,
          source: _sourceInfo('$surahNumber:$ayahNumber'),
        ));
      }
      final pagination = json['pagination'] as Map<String, dynamic>;
      totalPages = pagination['total_pages'] as int;
      page++;
    } while (page <= totalPages);
    return ayahs;
  }

  @override
  Future<String> fetchBasmala() async {
    // البسملة هي الآية الأولى من سورة الفاتحة.
    final json = await _client.getJson(
      '/verses/by_key/1:1',
      queryParameters: {'words': 'false', 'fields': 'text_uthmani'},
    ) as Map<String, dynamic>;
    final verse = json['verse'] as Map<String, dynamic>;
    return (verse['text_uthmani'] as String).trim();
  }

  @override
  Future<List<AyahModel>> searchAyahs(String query) async {
    final json = await _client.getJson(
      '/search',
      queryParameters: {'q': query, 'size': '50'},
    ) as Map<String, dynamic>;
    final search = json['search'] as Map<String, dynamic>;
    final results = search['results'] as List<dynamic>;
    return results.map((r) {
      final result = r as Map<String, dynamic>;
      final verseKey = result['verse_key'] as String;
      final parts = verseKey.split(':');
      return AyahModel(
        surahNumber: int.parse(parts[0]),
        ayahNumber: int.parse(parts[1]),
        textArabic: (result['text'] as String).trim(),
        source: _sourceInfo(verseKey),
      );
    }).toList();
  }

  void dispose() => _client.dispose();
}
