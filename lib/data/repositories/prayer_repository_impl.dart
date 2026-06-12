import 'dart:async';

import '../../models/prayer_times.dart';
import '../../services/qibla_service.dart';
import '../datasources/local_prayer_cache_data_source.dart';
import '../datasources/prayer_data_source.dart';
import 'prayer_repository.dart';

/// تطبيق مستودع المواقيت: بعيد أولاً (AlAdhan) مع حفظ كل نجاح في
/// الذاكرة الدائمة؛ وعند انقطاع الاتصال تُعاد آخر مواقيت محفوظة
/// موسومة بـ fromCache (وبـ isStale إن كانت ليوم سابق).
/// اتجاه القبلة يُحسب محلياً عبر [QiblaService].
class PrayerRepositoryImpl implements PrayerRepository {
  PrayerRepositoryImpl({
    required PrayerDataSource remote,
    required LocalPrayerCacheDataSource cache,
    QiblaService qiblaService = const QiblaService(),
    this.remoteTimeout = const Duration(seconds: 10),
  })  : _remote = remote,
        _cache = cache,
        _qibla = qiblaService;

  final PrayerDataSource _remote;
  final LocalPrayerCacheDataSource _cache;
  final QiblaService _qibla;
  final Duration remoteTimeout;

  @override
  Future<PrayerTimesResult> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? methodId,
  }) async {
    try {
      final times = await _remote
          .fetchPrayerTimes(
            date: date,
            latitude: latitude,
            longitude: longitude,
            methodId: methodId,
          )
          .timeout(remoteTimeout);
      await _cache.savePrayerTimes(times);
      return PrayerTimesResult(
        times: times,
        fromCache: false,
        isStale: false,
      );
    } catch (_) {
      final cached = await _cache.fetchLatest(
        latitude: latitude,
        longitude: longitude,
        methodId: methodId,
      );
      if (cached == null) {
        throw const PrayerUnavailableException(
          'تعذر جلب المواقيت ولا توجد مواقيت محفوظة — '
          'تحقق من الاتصال بالإنترنت',
        );
      }
      final requestedDay = DateTime(date.year, date.month, date.day);
      return PrayerTimesResult(
        times: cached,
        fromCache: true,
        isStale: cached.date != requestedDay,
      );
    }
  }

  @override
  QiblaDirection getQiblaDirection({
    required double latitude,
    required double longitude,
  }) {
    return _qibla.directionFrom(latitude: latitude, longitude: longitude);
  }
}
