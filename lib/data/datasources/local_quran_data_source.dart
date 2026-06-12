import '../../core/utils/arabic_text.dart';
import '../../models/quran_models.dart';
import '../../services/asset_data_loader.dart';
import 'quran_data_source.dart';

/// مصدر بيانات القرآن المحلي — يقرأ النص العثماني الكامل من ملفات JSON
/// مضمَّنة مع التطبيق (lib/assets_data/quran)، فيعمل التطبيق دون اتصال.
class LocalQuranDataSource implements QuranDataSource {
  LocalQuranDataSource({AssetDataLoader? loader})
      : _loader = loader ?? const AssetDataLoader();

  final AssetDataLoader _loader;

  // ذاكرة مؤقتة داخل الجلسة لتجنب إعادة قراءة الملفات وتحليلها.
  List<SurahModel>? _surahs;
  String? _basmala;
  final Map<int, List<AyahModel>> _ayahsBySurah = {};

  @override
  Future<String> fetchBasmala() async {
    if (_basmala == null) await fetchSurahs();
    return _basmala!;
  }

  @override
  Future<List<SurahModel>> fetchSurahs() async {
    if (_surahs != null) return _surahs!;

    final json = await _loader.loadJson('quran/surahs.json')
        as Map<String, dynamic>;
    _basmala = json['basmala'] as String;
    final source =
        QuranSourceInfo.fromJson(json['source'] as Map<String, dynamic>);
    final list = json['surahs'] as List<dynamic>;
    _surahs = list.map((s) {
      final surah = s as Map<String, dynamic>;
      return SurahModel(
        number: surah['number'] as int,
        nameArabic: surah['nameArabic'] as String,
        nameTransliteration: surah['nameTransliteration'] as String?,
        ayahCount: surah['ayahCount'] as int,
        revelationPlace: surah['revelationPlace'] as String,
        source: source,
      );
    }).toList();
    return _surahs!;
  }

  @override
  Future<SurahModel> fetchSurah(int surahNumber) async {
    final surahs = await fetchSurahs();
    return surahs.firstWhere(
      (s) => s.number == surahNumber,
      orElse: () =>
          throw ArgumentError('رقم سورة غير صالح: $surahNumber'),
    );
  }

  @override
  Future<List<AyahModel>> fetchAyahs(int surahNumber) async {
    final cached = _ayahsBySurah[surahNumber];
    if (cached != null) return cached;

    final json = await _loader.loadJson('quran/surah_$surahNumber.json')
        as Map<String, dynamic>;
    final source =
        QuranSourceInfo.fromJson(json['source'] as Map<String, dynamic>);
    final list = json['ayahs'] as List<dynamic>;
    final ayahs = list.map((a) {
      final ayah = a as Map<String, dynamic>;
      return AyahModel(
        surahNumber: surahNumber,
        ayahNumber: ayah['ayahNumber'] as int,
        textArabic: ayah['textArabic'] as String,
        juz: ayah['juz'] as int?,
        page: ayah['page'] as int?,
        source: source,
      );
    }).toList();
    _ayahsBySurah[surahNumber] = ayahs;
    return ayahs;
  }

  @override
  Future<List<AyahModel>> searchAyahs(String query) async {
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.isEmpty) return [];

    final results = <AyahModel>[];
    final surahs = await fetchSurahs();
    for (final surah in surahs) {
      final ayahs = await fetchAyahs(surah.number);
      for (final ayah in ayahs) {
        if (normalizeArabic(ayah.textArabic).contains(normalizedQuery)) {
          results.add(ayah);
          if (results.length >= 100) return results;
        }
      }
    }
    return results;
  }

}
