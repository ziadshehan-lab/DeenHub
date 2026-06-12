import 'content_source.dart';

/// تصنيف في المكتبة الإسلامية (عقيدة، فقه، سيرة...).
class LibraryCategory {
  const LibraryCategory({required this.id, required this.nameArabic});

  final String id;
  final String nameArabic;

  factory LibraryCategory.fromJson(Map<String, dynamic> json) {
    return LibraryCategory(
      id: json['id'] as String,
      nameArabic: json['nameArabic'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nameArabic': nameArabic};
}

/// كتاب في المكتبة الإسلامية.
class LibraryBook extends ContentItem {
  const LibraryBook({
    required this.id,
    required this.title,
    required this.categoryId,
    this.description,
    required super.source,
  });

  final String id;
  final String title;
  final String categoryId;
  final String? description;

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    return LibraryBook(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryId: json['categoryId'] as String,
      description: json['description'] as String?,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'description': description,
        'source': source.toJson(),
      };
}
