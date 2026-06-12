import '../../models/prayer_times.dart';

/// نتيجة جلب المواقيت: المواقيت + هل جاءت من الذاكرة المحفوظة
/// (لعرض تنبيه عند انقطاع الاتصال) وهل هي ليوم سابق.
class PrayerTimesResult {
  const PrayerTimesResult({
    required this.times,
    required this.fromCache,
    required this.isStale,
  });

  final PrayerTimesModel times;

  /// جاءت من الذاكرة المحفوظة بدل المصدر البعيد.
  final bool fromCache;

  /// المواقيت المحفوظة ليوم غير اليوم المطلوب.
  final bool isStale;
}

/// واجهة مستودع مواقيت الصلاة واتجاه القبلة.
abstract class PrayerRepository {
  /// مواقيت يوم محدد: المصدر البعيد أولاً، وعند الفشل آخر مواقيت
  /// محفوظة مع وسم fromCache.
  Future<PrayerTimesResult> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? methodId,
  });

  /// اتجاه القبلة — يُحسب محلياً ويعمل دون اتصال.
  QiblaDirection getQiblaDirection({
    required double latitude,
    required double longitude,
  });
}
