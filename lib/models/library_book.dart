import 'content_source.dart';

/// تصنيف في المكتبة الإسلامية (تفسير، حديث، عقيدة...).
class LibraryCategoryModel {
  const LibraryCategoryModel({required this.id, required this.title});

  final String id;
  final String title;
}

/// مصدر معتمد في المكتبة (الشاملة، الدرر السنية، إسلام ويب...).
class LibrarySourceModel {
  const LibrarySourceModel({
    required this.id,
    required this.name,
    required this.url,
    this.description,
  });

  final String id;
  final String name;
  final String url;
  final String? description;

  factory LibrarySourceModel.fromJson(Map<String, dynamic> json) {
    return LibrarySourceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
    );
  }
}

/// كتاب/موسوعة في فهرس المكتبة مع رابط موثق إلى مصدره الرسمي.
class LibraryBookModel extends ContentItem {
  const LibraryBookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.categoryId,
    required this.sourceId,
    required this.sourceName,
    this.description,
    required this.url,
    required super.source,
  });

  final String id;
  final String title;
  final String author;
  final String categoryId;

  /// معرّف المصدر المستضيف (shamela، dorar...).
  final String sourceId;

  /// اسم المصدر المستضيف للعرض.
  final String sourceName;

  final String? description;

  /// رابط الكتاب لدى المصدر الرسمي.
  final String url;

  /// معرّف الكتاب في المفضلة.
  String get favoriteId => 'book:$id';
}
