/// نوع نتيجة البحث الموحد — يحدد القسم والتجميع والتوجيه.
enum SearchResultType { quran, tafsir, hadith, adhkar, names, library }

/// نتيجة بحث موحدة من أي وحدة محتوى، تحمل ما يلزم للعرض والتوجيه
/// إلى الشاشة الصحيحة.
class SearchResultModel {
  const SearchResultModel({
    required this.id,
    required this.title,
    required this.snippet,
    required this.type,
    required this.sourceName,
    required this.reference,
    required this.route,
    this.metadata = const {},
  });

  /// معرّف فريد ضمن نوعه.
  final String id;

  /// عنوان النتيجة (اسم السورة، كتاب التفسير، عنوان الكتاب...).
  final String title;

  /// مقتطف النص المطابق.
  final String snippet;

  final SearchResultType type;

  /// اسم المصدر للإسناد.
  final String sourceName;

  /// المرجع (سورة:آية، رقم الحديث...).
  final String reference;

  /// اسم المسار الذي تفتح فيه النتيجة.
  final String route;

  /// بيانات إضافية لبناء وسيطات الشاشة الهدف.
  final Map<String, String> metadata;
}
