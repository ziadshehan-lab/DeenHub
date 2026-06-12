import 'content_source.dart';

/// تعريف بكتاب تفسير متاح (ابن كثير، الطبري، السعدي...).
class TafsirEdition extends ContentItem {
  const TafsirEdition({
    required this.id,
    required this.nameArabic,
    required super.source,
  });

  final String id;
  final String nameArabic;

  factory TafsirEdition.fromJson(Map<String, dynamic> json) {
    return TafsirEdition(
      id: json['id'] as String,
      nameArabic: json['nameArabic'] as String,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameArabic': nameArabic,
        'source': source.toJson(),
      };
}

/// نص تفسير آية محددة من كتاب تفسير محدد.
class TafsirEntry extends ContentItem {
  const TafsirEntry({
    required this.editionId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    required super.source,
  });

  final String editionId;
  final int surahNumber;
  final int ayahNumber;
  final String text;

  factory TafsirEntry.fromJson(Map<String, dynamic> json) {
    return TafsirEntry(
      editionId: json['editionId'] as String,
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      text: json['text'] as String,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'editionId': editionId,
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'text': text,
        'source': source.toJson(),
      };
}
