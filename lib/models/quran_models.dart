import 'content_source.dart';

/// معلومات مصدر المحتوى القرآني (النص، الرواية، جهة الإصدار).
class QuranSourceInfo extends ContentSource {
  const QuranSourceInfo({
    required super.sourceName,
    super.authorOrScholar,
    required super.reference,
    super.sourceUrl,
    required super.lastUpdated,
  });

  factory QuranSourceInfo.fromJson(Map<String, dynamic> json) {
    return QuranSourceInfo(
      sourceName: json['sourceName'] as String,
      authorOrScholar: json['authorOrScholar'] as String?,
      reference: json['reference'] as String,
      sourceUrl: json['sourceUrl'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// بيانات سورة من القرآن الكريم.
class SurahModel extends ContentItem {
  const SurahModel({
    required this.number,
    required this.nameArabic,
    this.nameTransliteration,
    required this.ayahCount,
    required this.revelationPlace,
    required QuranSourceInfo super.source,
  });

  final int number;
  final String nameArabic;
  final String? nameTransliteration;
  final int ayahCount;

  /// مكية أو مدنية.
  final String revelationPlace;

  QuranSourceInfo get quranSource => source as QuranSourceInfo;

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] as int,
      nameArabic: json['nameArabic'] as String,
      nameTransliteration: json['nameTransliteration'] as String?,
      ayahCount: json['ayahCount'] as int,
      revelationPlace: json['revelationPlace'] as String,
      source:
          QuranSourceInfo.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'nameArabic': nameArabic,
        'nameTransliteration': nameTransliteration,
        'ayahCount': ayahCount,
        'revelationPlace': revelationPlace,
        'source': source.toJson(),
      };
}

/// آية من القرآن الكريم مع موضعها ومصدرها.
class AyahModel extends ContentItem {
  const AyahModel({
    required this.surahNumber,
    required this.ayahNumber,
    required this.textArabic,
    this.juz,
    this.page,
    required QuranSourceInfo super.source,
  });

  final int surahNumber;
  final int ayahNumber;
  final String textArabic;
  final int? juz;
  final int? page;

  QuranSourceInfo get quranSource => source as QuranSourceInfo;

  /// اسم المصدر — متاح مباشرة على مستوى الآية.
  String get sourceName => source.sourceName;

  /// رابط المصدر — متاح مباشرة على مستوى الآية.
  String? get sourceUrl => source.sourceUrl;

  /// مفتاح الآية بصيغة `سورة:آية` مثل `2:255`.
  String get verseKey => '$surahNumber:$ayahNumber';

  /// معرّف الآية في المفضلة.
  String get favoriteId => 'ayah:$surahNumber:$ayahNumber';

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      textArabic: json['textArabic'] as String,
      juz: json['juz'] as int?,
      page: json['page'] as int?,
      source:
          QuranSourceInfo.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'textArabic': textArabic,
        'juz': juz,
        'page': page,
        'source': source.toJson(),
      };
}
