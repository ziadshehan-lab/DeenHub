import 'content_source.dart';

/// تصنيف أذكار (أذكار الصباح، أذكار المساء، أذكار النوم...).
class DhikrCategory {
  const DhikrCategory({required this.id, required this.nameArabic});

  final String id;
  final String nameArabic;

  factory DhikrCategory.fromJson(Map<String, dynamic> json) {
    return DhikrCategory(
      id: json['id'] as String,
      nameArabic: json['nameArabic'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nameArabic': nameArabic};
}

/// ذكر واحد مع عدد مرات التكرار المسنون.
class Dhikr extends ContentItem {
  const Dhikr({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.repeatCount,
    this.virtue,
    required super.source,
  });

  final String id;
  final String categoryId;
  final String text;
  final int repeatCount;

  /// فضل الذكر إن وُجد.
  final String? virtue;

  factory Dhikr.fromJson(Map<String, dynamic> json) {
    return Dhikr(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      text: json['text'] as String,
      repeatCount: json['repeatCount'] as int,
      virtue: json['virtue'] as String?,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'text': text,
        'repeatCount': repeatCount,
        'virtue': virtue,
        'source': source.toJson(),
      };
}

/// اسم من أسماء الله الحسنى مع شرحه.
class AllahName extends ContentItem {
  const AllahName({
    required this.number,
    required this.name,
    this.meaning,
    required super.source,
  });

  final int number;
  final String name;
  final String? meaning;

  factory AllahName.fromJson(Map<String, dynamic> json) {
    return AllahName(
      number: json['number'] as int,
      name: json['name'] as String,
      meaning: json['meaning'] as String?,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'name': name,
        'meaning': meaning,
        'source': source.toJson(),
      };
}
