import 'content_source.dart';

/// تصنيف أذكار (الصباح والمساء، النوم، السفر...).
class DhikrCategoryModel extends ContentItem {
  const DhikrCategoryModel({
    required this.id,
    required this.title,
    this.dhikrCount,
    required super.source,
  });

  final String id;
  final String title;
  final int? dhikrCount;
}

/// ذكر واحد من حصن المسلم مع عدد التكرار والإسناد.
class DhikrModel extends ContentItem {
  const DhikrModel({
    required this.id,
    required this.categoryId,
    required this.text,
    this.repeat = 1,
    this.chapterTitle,
    required super.source,
  });

  /// معرّف فريد بصيغة `رقم الباب-رقم الذكر` (مثل `27-76`).
  final String id;
  final String categoryId;
  final String text;

  /// عدد مرات التكرار المسنون.
  final int repeat;

  /// عنوان الباب في الكتاب (للإسناد).
  final String? chapterTitle;

  String get sourceName => source.sourceName;
  String? get sourceUrl => source.sourceUrl;
  String get reference => source.reference;

  /// معرّف الذكر في المفضلة.
  String get favoriteId => 'dhikr:$id';
}

/// اسم من أسماء الله الحسنى.
class AllahNameModel extends ContentItem {
  const AllahNameModel({
    required this.number,
    required this.name,
    this.transliteration,
    this.meaning,
    this.explanation,
    required super.source,
  });

  final int number;
  final String name;

  /// النطق بالحروف اللاتينية.
  final String? transliteration;

  /// المعنى (كما يوفره المصدر — بالإنجليزية حالياً).
  final String? meaning;

  /// شرح موجز إن وفّره مصدر معتمد (يبقى فارغاً حتى اعتماد مصدر عربي).
  final String? explanation;

  /// معرّف الاسم في المفضلة.
  String get favoriteId => 'name:$number';
}
