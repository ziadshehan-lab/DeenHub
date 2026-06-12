import 'dart:math' as math;

import '../models/content_source.dart';
import '../models/prayer_times.dart';

/// خدمة حساب اتجاه القبلة محلياً: زاوية الدائرة العظمى من موقع
/// المستخدم نحو الكعبة المشرفة، مع المسافة — تعمل دون اتصال.
///
/// (تم التحقق من النتائج مقابل واجهة AlAdhan الرسمية /v1/qibla.)
class QiblaService {
  const QiblaService();

  /// إحداثيات الكعبة المشرفة.
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  static const double _earthRadiusKm = 6371.0;

  double _toRadians(double degrees) => degrees * math.pi / 180;

  /// اتجاه القبلة بالدرجات من الشمال الحقيقي (0-360 مع عقارب الساعة).
  double bearingToKaaba({
    required double latitude,
    required double longitude,
  }) {
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLng = _toRadians(kaabaLongitude - longitude);

    final y = math.sin(deltaLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// المسافة إلى الكعبة بالكيلومترات (صيغة هافرساين).
  double distanceToKaabaKm({
    required double latitude,
    required double longitude,
  }) {
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLat = _toRadians(kaabaLatitude - latitude);
    final deltaLng = _toRadians(kaabaLongitude - longitude);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLng / 2), 2);
    return _earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  QiblaDirection directionFrom({
    required double latitude,
    required double longitude,
  }) {
    return QiblaDirection(
      latitude: latitude,
      longitude: longitude,
      directionDegrees:
          bearingToKaaba(latitude: latitude, longitude: longitude),
      distanceKm:
          distanceToKaabaKm(latitude: latitude, longitude: longitude),
      source: ContentSource(
        sourceName:
            'حساب فلكي محلي — زاوية الدائرة العظمى نحو الكعبة المشرفة',
        reference:
            'من ($latitude، $longitude) إلى ($kaabaLatitude، $kaabaLongitude)',
        sourceUrl: 'https://aladhan.com/qibla',
        lastUpdated: DateTime.now(),
      ),
    );
  }
}
