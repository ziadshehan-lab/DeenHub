import 'content_source.dart';

/// بيانات سورة من القرآن الكريم.
class Surah extends ContentItem {
  const Surah({
    required this.number,
    required this.nameArabic,
    this.nameTransliteration,
    required this.ayahCount,
    required this.revelationPlace,
    required super.source,
  });

  final int number;
  final String nameArabic;
  final String? nameTransliteration;
  final int ayahCount;

  /// مكية أو مدنية.
  final String revelationPlace;

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      nameArabic: json['nameArabic'] as String,
      nameTransliteration: json['nameTransliteration'] as String?,
      ayahCount: json['ayahCount'] as int,
      revelationPlace: json['revelationPlace'] as String,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
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

/// آية من القرآن الكريم.
class Ayah extends ContentItem {
  const Ayah({
    required this.surahNumber,
    required this.numberInSurah,
    required this.text,
    this.juz,
    this.page,
    required super.source,
  });

  final int surahNumber;
  final int numberInSurah;
  final String text;
  final int? juz;
  final int? page;

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      surahNumber: json['surahNumber'] as int,
      numberInSurah: json['numberInSurah'] as int,
      text: json['text'] as String,
      juz: json['juz'] as int?,
      page: json['page'] as int?,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'numberInSurah': numberInSurah,
        'text': text,
        'juz': juz,
        'page': page,
        'source': source.toJson(),
      };
}
