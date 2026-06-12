import 'content_source.dart';

/// مواقيت الصلاة ليوم محدد في موقع محدد.
class PrayerTimes extends ContentItem {
  const PrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.calculationMethod,
    required super.source,
  });

  final DateTime date;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// طريقة الحساب المعتمدة (أم القرى، رابطة العالم الإسلامي...).
  final String? calculationMethod;

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    return PrayerTimes(
      date: DateTime.parse(json['date'] as String),
      fajr: DateTime.parse(json['fajr'] as String),
      sunrise: DateTime.parse(json['sunrise'] as String),
      dhuhr: DateTime.parse(json['dhuhr'] as String),
      asr: DateTime.parse(json['asr'] as String),
      maghrib: DateTime.parse(json['maghrib'] as String),
      isha: DateTime.parse(json['isha'] as String),
      calculationMethod: json['calculationMethod'] as String?,
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'fajr': fajr.toIso8601String(),
        'sunrise': sunrise.toIso8601String(),
        'dhuhr': dhuhr.toIso8601String(),
        'asr': asr.toIso8601String(),
        'maghrib': maghrib.toIso8601String(),
        'isha': isha.toIso8601String(),
        'calculationMethod': calculationMethod,
        'source': source.toJson(),
      };
}

/// اتجاه القبلة من موقع محدد.
class QiblaDirection extends ContentItem {
  const QiblaDirection({
    required this.latitude,
    required this.longitude,
    required this.directionDegrees,
    required super.source,
  });

  final double latitude;
  final double longitude;

  /// الاتجاه بالدرجات من الشمال الحقيقي.
  final double directionDegrees;

  factory QiblaDirection.fromJson(Map<String, dynamic> json) {
    return QiblaDirection(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      directionDegrees: (json['directionDegrees'] as num).toDouble(),
      source: ContentSource.fromJson(json['source'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'directionDegrees': directionDegrees,
        'source': source.toJson(),
      };
}
