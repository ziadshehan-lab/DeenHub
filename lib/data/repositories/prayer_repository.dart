import '../../models/prayer_times.dart';

/// واجهة مستودع مواقيت الصلاة واتجاه القبلة — تنسّق بين مصادر البيانات
/// وتطبّق سياسة التخزين المؤقت.
abstract class PrayerRepository {
  Future<PrayerTimes> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String? calculationMethod,
  });

  Future<List<PrayerTimes>> getMonthlyPrayerTimes({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    String? calculationMethod,
  });

  Future<QiblaDirection> getQiblaDirection({
    required double latitude,
    required double longitude,
  });
}
