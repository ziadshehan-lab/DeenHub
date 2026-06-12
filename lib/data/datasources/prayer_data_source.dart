import '../../models/prayer_times.dart';

/// واجهة مصدر بيانات مواقيت الصلاة واتجاه القبلة.
///
/// التطبيقات المستقبلية: HTTP API (مثل واجهات المواقيت الرسمية)،
/// حساب محلي، ذاكرة مؤقتة.
abstract class PrayerDataSource {
  /// جلب مواقيت الصلاة ليوم محدد في موقع محدد.
  Future<PrayerTimes> fetchPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String? calculationMethod,
  });

  /// جلب مواقيت الصلاة لشهر كامل.
  Future<List<PrayerTimes>> fetchMonthlyPrayerTimes({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    String? calculationMethod,
  });

  /// جلب اتجاه القبلة من موقع محدد.
  Future<QiblaDirection> fetchQiblaDirection({
    required double latitude,
    required double longitude,
  });
}
