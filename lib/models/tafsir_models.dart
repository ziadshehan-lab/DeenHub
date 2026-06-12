import 'content_source.dart';

/// كتاب تفسير معتمد في التطبيق (السعدي، ابن كثير، الطبري، القرطبي،
/// الجلالين...).
class TafsirEditionModel extends ContentItem {
  const TafsirEditionModel({
    required this.id,
    this.remoteId,
    required this.nameArabic,
    this.fullName,
    required this.scholar,
    required this.available,
    this.localSurahs = const [],
    required super.source,
  });

  /// المعرّف الداخلي الموحّد (مثل `saadi`).
  final String id;

  /// معرّف الكتاب لدى المصدر البعيد (Quran.com) إن كان متاحاً.
  final int? remoteId;

  final String nameArabic;

  /// الاسم الكامل للكتاب (مثل «تيسير الكريم الرحمن في تفسير كلام المنان»).
  final String? fullName;

  /// العالِم المؤلف.
  final String scholar;

  /// هل نص هذا التفسير متاح حالياً من المصادر المتصلة.
  final bool available;

  /// أرقام السور المتوفر نصها محلياً (دون اتصال) لهذا الكتاب.
  final List<int> localSurahs;

  factory TafsirEditionModel.fromJson(
    Map<String, dynamic> json, {
    required ContentSource source,
  }) {
    return TafsirEditionModel(
      id: json['id'] as String,
      remoteId: json['remoteId'] as int?,
      nameArabic: json['nameArabic'] as String,
      fullName: json['fullName'] as String?,
      scholar: json['scholar'] as String,
      available: json['available'] as bool,
      localSurahs: (json['localSurahs'] as List<dynamic>? ?? const [])
          .cast<int>(),
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'remoteId': remoteId,
        'nameArabic': nameArabic,
        'fullName': fullName,
        'scholar': scholar,
        'available': available,
        'localSurahs': localSurahs,
      };
}

/// نص تفسير آية محددة من كتاب تفسير محدد، مع الإسناد الكامل للمصدر.
class TafsirModel extends ContentItem {
  const TafsirModel({
    required this.editionId,
    required this.editionName,
    this.scholar,
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    required super.source,
  });

  final String editionId;

  /// اسم كتاب التفسير.
  final String editionName;

  /// العالِم المؤلف إن وُجد.
  final String? scholar;

  final int surahNumber;
  final int ayahNumber;

  /// نص التفسير (نص خالص دون HTML).
  final String text;

  String get sourceName => source.sourceName;
  String? get sourceUrl => source.sourceUrl;
  String get reference => source.reference;

  /// معرّف المقطع في المفضلة.
  String get favoriteId => 'tafsir:$editionId:$surahNumber:$ayahNumber';

  /// معرّف الإشارة المرجعية.
  String get bookmarkId => '$editionId:$surahNumber:$ayahNumber';

  factory TafsirModel.fromJson(Map<String, dynamic> json) {
    return TafsirModel(
      editionId: json['editionId'] as String,
      editionName: json['editionName'] as String,
      scholar: json['scholar'] as String?,
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      text: json['text'] as String,
      source:
          ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'editionId': editionId,
        'editionName': editionName,
        'scholar': scholar,
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'text': text,
        'source': source.toJson(),
      };
}
