/// معلومات إسناد المحتوى — كل عنصر محتوى إسلامي في التطبيق يجب أن
/// يحمل هذه المعلومات لضمان الموثوقية والرجوع إلى المصدر الأصلي.
class ContentSource {
  const ContentSource({
    required this.sourceName,
    this.authorOrScholar,
    required this.reference,
    this.sourceUrl,
    required this.lastUpdated,
  });

  /// اسم المصدر الرسمي (مثال: مجمع الملك فهد، صحيح البخاري...).
  final String sourceName;

  /// العالِم أو المؤلف إن وُجد.
  final String? authorOrScholar;

  /// المرجع الدقيق (رقم الآية، رقم الحديث، الصفحة...).
  final String reference;

  /// رابط المصدر الرسمي إن وُجد.
  final String? sourceUrl;

  /// تاريخ آخر تحديث للمحتوى.
  final DateTime lastUpdated;

  factory ContentSource.fromJson(Map<String, dynamic> json) {
    return ContentSource(
      sourceName: json['sourceName'] as String,
      authorOrScholar: json['authorOrScholar'] as String?,
      reference: json['reference'] as String,
      sourceUrl: json['sourceUrl'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceName': sourceName,
        'authorOrScholar': authorOrScholar,
        'reference': reference,
        'sourceUrl': sourceUrl,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

/// أساس مشترك لكل عناصر المحتوى الإسلامي: يضمن وجود معلومات الإسناد.
abstract class ContentItem {
  const ContentItem({required this.source});

  /// معلومات المصدر والإسناد.
  final ContentSource source;
}
