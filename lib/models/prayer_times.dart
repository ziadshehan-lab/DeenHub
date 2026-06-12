import 'content_source.dart';

/// مواقيت الصلاة ليوم محدد في موقع محدد، مع التاريخ الهجري إن وفّره
/// المصدر.
class PrayerTimesModel extends ContentItem {
  const PrayerTimesModel({
    required this.date,
    this.hijriDate,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.methodId,
    this.methodName,
    required this.latitude,
    required this.longitude,
    required super.source,
  });

  final DateTime date;

  /// التاريخ الهجري منسقاً بالعربية (مثل: الجمعة ٢٦ ذوالحجة ١٤٤٧هـ).
  final String? hijriDate;

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// معرّف طريقة الحساب لدى المصدر (أم القرى = 4...).
  final int? methodId;

  /// اسم طريقة الحساب كما يعيده المصدر.
  final String? methodName;

  final double latitude;
  final double longitude;

  /// المواقيت الستة بترتيبها مع مفاتيحها الثابتة.
  List<(String key, DateTime time)> get orderedTimes => [
        ('fajr', fajr),
        ('sunrise', sunrise),
        ('dhuhr', dhuhr),
        ('asr', asr),
        ('maghrib', maghrib),
        ('isha', isha),
      ];

  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    return PrayerTimesModel(
      date: DateTime.parse(json['date'] as String),
      hijriDate: json['hijriDate'] as String?,
      fajr: DateTime.parse(json['fajr'] as String),
      sunrise: DateTime.parse(json['sunrise'] as String),
      dhuhr: DateTime.parse(json['dhuhr'] as String),
      asr: DateTime.parse(json['asr'] as String),
      maghrib: DateTime.parse(json['maghrib'] as String),
      isha: DateTime.parse(json['isha'] as String),
      methodId: json['methodId'] as int?,
      methodName: json['methodName'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      source:
          ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'hijriDate': hijriDate,
        'fajr': fajr.toIso8601String(),
        'sunrise': sunrise.toIso8601String(),
        'dhuhr': dhuhr.toIso8601String(),
        'asr': asr.toIso8601String(),
        'maghrib': maghrib.toIso8601String(),
        'isha': isha.toIso8601String(),
        'methodId': methodId,
        'methodName': methodName,
        'latitude': latitude,
        'longitude': longitude,
        'source': source.toJson(),
      };
}

/// اتجاه القبلة من موقع محدد.
class QiblaDirection extends ContentItem {
  const QiblaDirection({
    required this.latitude,
    required this.longitude,
    required this.directionDegrees,
    required this.distanceKm,
    required super.source,
  });

  final double latitude;
  final double longitude;

  /// الاتجاه بالدرجات من الشمال الحقيقي (مع عقارب الساعة).
  final double directionDegrees;

  /// المسافة إلى الكعبة المشرفة بالكيلومترات.
  final double distanceKm;
}
