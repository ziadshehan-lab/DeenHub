import 'content_source.dart';

/// كتاب/قسم رئيسي في مصدر الحديث (مثل أقسام موسوعة الأحاديث النبوية،
/// أو مجموعات سنة دوت كوم مثل صحيح البخاري).
class HadithBookModel extends ContentItem {
  const HadithBookModel({
    required this.id,
    required this.title,
    this.titleEnglish,
    this.hadithCount,
    required super.source,
  });

  final String id;
  final String title;
  final String? titleEnglish;
  final int? hadithCount;

  factory HadithBookModel.fromJson(
    Map<String, dynamic> json, {
    required ContentSource source,
  }) {
    return HadithBookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      titleEnglish: json['titleEnglish'] as String?,
      hadithCount: json['hadithCount'] as int?,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleEnglish': titleEnglish,
        'hadithCount': hadithCount,
      };
}

/// باب/فصل داخل كتاب حديث.
class HadithChapterModel extends ContentItem {
  const HadithChapterModel({
    required this.id,
    required this.bookId,
    required this.title,
    this.hadithCount,
    required super.source,
  });

  final String id;
  final String bookId;
  final String title;
  final int? hadithCount;

  factory HadithChapterModel.fromJson(
    Map<String, dynamic> json, {
    required String bookId,
    required ContentSource source,
  }) {
    return HadithChapterModel(
      id: json['id'] as String,
      bookId: bookId,
      title: json['title'] as String,
      hadithCount: json['hadithCount'] as int?,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hadithCount': hadithCount,
      };
}

/// حديث شريف بنصه العربي (والإنجليزي إن توفر) مع الإسناد الكامل.
class HadithModel extends ContentItem {
  const HadithModel({
    required this.id,
    this.bookId,
    this.chapterId,
    this.title,
    required this.textArabic,
    this.textEnglish,
    this.narrator,
    this.attribution,
    this.grade,
    this.explanation,
    required super.source,
  });

  final String id;
  final String? bookId;
  final String? chapterId;

  /// عنوان مختصر للحديث إن وفّره المصدر.
  final String? title;

  final String textArabic;
  final String? textEnglish;

  /// الراوي.
  final String? narrator;

  /// عزو الحديث (متفق عليه، رواه البخاري...).
  final String? attribution;

  /// درجة الحديث (صحيح، حسن، ضعيف...).
  final String? grade;

  /// شرح الحديث إن وفّره المصدر.
  final String? explanation;

  String get sourceName => source.sourceName;
  String? get sourceUrl => source.sourceUrl;
  String get reference => source.reference;

  /// معرّف الحديث في المفضلة.
  String get favoriteId => 'hadith:$id';

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    return HadithModel(
      id: json['id'] as String,
      bookId: json['bookId'] as String?,
      chapterId: json['chapterId'] as String?,
      title: json['title'] as String?,
      textArabic: json['textArabic'] as String,
      textEnglish: json['textEnglish'] as String?,
      narrator: json['narrator'] as String?,
      attribution: json['attribution'] as String?,
      grade: json['grade'] as String?,
      explanation: json['explanation'] as String?,
      source:
          ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'chapterId': chapterId,
        'title': title,
        'textArabic': textArabic,
        'textEnglish': textEnglish,
        'narrator': narrator,
        'attribution': attribution,
        'grade': grade,
        'explanation': explanation,
        'source': source.toJson(),
      };
}

/// نتيجة بحث في الحديث: قد تحمل معرّفاً قابلاً للفتح من المصدر نفسه،
/// أو نصاً كاملاً جاهزاً للعرض (كنتائج البحث من الدرر السنية).
class HadithSearchResultModel extends ContentItem {
  const HadithSearchResultModel({
    this.hadithId,
    required this.text,
    this.narrator,
    this.grade,
    this.bookName,
    this.muhaddith,
    this.hadithNumber,
    required super.source,
  });

  /// معرّف الحديث لدى المصدر إن وُجد (يُفتح به التفصيل).
  final String? hadithId;

  final String text;
  final String? narrator;
  final String? grade;

  /// اسم الكتاب/المصدر الحديثي (صحيح البخاري...).
  final String? bookName;

  /// المحدِّث الحاكم على الحديث (في نتائج الدرر السنية).
  final String? muhaddith;

  final String? hadithNumber;

  /// نموذج حديث كامل للعرض المباشر عندما لا يتوفر معرّف.
  HadithModel toInlineHadith() {
    return HadithModel(
      id: hadithId ?? 'search-result',
      textArabic: text,
      narrator: narrator,
      attribution: bookName,
      grade: grade,
      source: source,
    );
  }
}
