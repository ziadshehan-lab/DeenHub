import '../../models/prayer_times.dart';

/// واجهة مصدر بيانات مواقيت الصلاة.
///
/// التطبيقات الحالية:
/// - [RemotePrayerDataSource] عبر واجهة AlAdhan الرسمية (HTTP)
/// - [LocalPrayerCacheDataSource] من الذاكرة الدائمة (آخر مواقيت ناجحة)
abstract class PrayerDataSource {
  /// جلب مواقيت الصلاة ليوم محدد في موقع محدد بطريقة حساب محددة.
  Future<PrayerTimesModel> fetchPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? methodId,
  });
}

/// يُرمى عندما تكون المواقيت غير متاحة من هذا المصدر.
class PrayerUnavailableException implements Exception {
  const PrayerUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'PrayerUnavailableException: $message';
}
