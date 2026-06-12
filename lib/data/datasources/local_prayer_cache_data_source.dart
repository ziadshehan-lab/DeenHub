import '../../models/prayer_times.dart';
import '../../services/cache_service.dart';
import 'prayer_data_source.dart';

/// مصدر مواقيت الصلاة المحلي — يخزن آخر مواقيت ناجحة لكل
/// (موقع، طريقة حساب) في الذاكرة الدائمة ويعيدها دون اتصال.
class LocalPrayerCacheDataSource implements PrayerDataSource {
  LocalPrayerCacheDataSource({required CacheService cache}) : _cache = cache;

  final CacheService _cache;

  /// مفتاح الموقع مقرّباً — يكفي تقريب درجتين عشريتين (~1 كم).
  static String cacheKey(double latitude, double longitude, int? methodId) {
    final lat = latitude.toStringAsFixed(2);
    final lng = longitude.toStringAsFixed(2);
    return 'prayer_times_${lat}_${lng}_${methodId ?? 'default'}';
  }

  /// حفظ آخر مواقيت ناجحة (تُستدعى من المستودع بعد كل جلب بعيد ناجح).
  Future<void> savePrayerTimes(PrayerTimesModel times) async {
    await _cache.write(
      cacheKey(times.latitude, times.longitude, times.methodId),
      times.toJson(),
      ttl: const Duration(days: 40),
    );
  }

  /// آخر مواقيت محفوظة لهذا الموقع والطريقة أياً كان يومها —
  /// تعيد null إن لم يوجد شيء.
  Future<PrayerTimesModel?> fetchLatest({
    required double latitude,
    required double longitude,
    int? methodId,
  }) async {
    final stored = await _cache.read(cacheKey(latitude, longitude, methodId));
    if (stored == null) return null;
    try {
      return PrayerTimesModel.fromJson(
          (stored as Map).cast<String, dynamic>());
    } catch (_) {
      return null; // بيانات تالفة
    }
  }

  @override
  Future<PrayerTimesModel> fetchPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? methodId,
  }) async {
    final stored = await fetchLatest(
      latitude: latitude,
      longitude: longitude,
      methodId: methodId,
    );
    if (stored == null) {
      throw const PrayerUnavailableException(
        'لا توجد مواقيت محفوظة لهذا الموقع',
      );
    }
    return stored;
  }
}
