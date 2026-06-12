import 'content_source.dart';

/// مجموعة أحاديث (صحيح البخاري، صحيح مسلم...).
class HadithCollection extends ContentItem {
  const HadithCollection({
    required this.id,
    required this.nameArabic,
    required this.hadithCount,
    required super.source,
  });

  final String id;
  final String nameArabic;
  final int hadithCount;

  factory HadithCollection.fromJson(Map<String, dynamic> json) {
    return HadithCollection(
      id: json['id'] as String,
      nameArabic: json['nameArabic'] as String,
      hadithCount: json['hadithCount'] as int,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameArabic': nameArabic,
        'hadithCount': hadithCount,
        'source': source.toJson(),
      };
}

/// حديث شريف واحد.
class Hadith extends ContentItem {
  const Hadith({
    required this.id,
    required this.collectionId,
    required this.text,
    this.narrator,
    this.grade,
    this.chapter,
    required super.source,
  });

  final String id;
  final String collectionId;
  final String text;

  /// الراوي.
  final String? narrator;

  /// درجة الحديث (صحيح، حسن...).
  final String? grade;

  /// الباب أو الكتاب داخل المجموعة.
  final String? chapter;

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as String,
      collectionId: json['collectionId'] as String,
      text: json['text'] as String,
      narrator: json['narrator'] as String?,
      grade: json['grade'] as String?,
      chapter: json['chapter'] as String?,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collectionId': collectionId,
        'text': text,
        'narrator': narrator,
        'grade': grade,
        'chapter': chapter,
        'source': source.toJson(),
      };
}
