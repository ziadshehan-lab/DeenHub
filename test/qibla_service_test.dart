import 'package:flutter_test/flutter_test.dart';

import 'package:deenhub/services/qibla_service.dart';

/// التحقق من حساب اتجاه القبلة مقابل قيم مرجعية
/// (قيمة القاهرة مطابقة لواجهة AlAdhan الرسمية /v1/qibla: 136.137°).
void main() {
  const service = QiblaService();

  test('bearing matches AlAdhan reference for Cairo', () {
    expect(
      service.bearingToKaaba(latitude: 30.0444, longitude: 31.2357),
      closeTo(136.14, 0.1),
    );
  });

  test('bearing is correct across hemispheres', () {
    // جاكرتا (جنوب شرق) → شمال غرب
    expect(
      service.bearingToKaaba(latitude: -6.2088, longitude: 106.8456),
      closeTo(295.15, 0.2),
    );
    // نيويورك (غرب) → شمال شرق
    expect(
      service.bearingToKaaba(latitude: 40.7128, longitude: -74.006),
      closeTo(58.48, 0.2),
    );
    // إسطنبول → جنوب شرق
    expect(
      service.bearingToKaaba(latitude: 41.0082, longitude: 28.9784),
      closeTo(151.62, 0.2),
    );
  });

  test('distance to Kaaba is correct', () {
    // المدينة المنورة ≈ ٣٣٩ كم
    expect(
      service.distanceToKaabaKm(latitude: 24.4672, longitude: 39.6111),
      closeTo(339, 3),
    );
    // عند الكعبة نفسها ≈ صفر
    expect(
      service.distanceToKaabaKm(
        latitude: QiblaService.kaabaLatitude,
        longitude: QiblaService.kaabaLongitude,
      ),
      closeTo(0, 0.01),
    );
  });

  test('directionFrom returns a fully attributed QiblaDirection', () {
    final direction =
        service.directionFrom(latitude: 30.0444, longitude: 31.2357);
    expect(direction.directionDegrees, closeTo(136.14, 0.1));
    expect(direction.distanceKm, closeTo(1287, 5));
    expect(direction.source.sourceName, contains('الكعبة'));
  });
}
