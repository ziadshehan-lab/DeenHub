import 'package:flutter/foundation.dart';

import '../models/prayer_times.dart';

/// واجهة خدمة تذكيرات الصلاة المحلية.
///
/// التطبيقات:
/// - [LocalPrayerNotificationService]: إشعارات فعلية على أندرويد و iOS
///   عبر flutter_local_notifications بجدولة آمنة زمنياً
/// - [NoopPrayerNotificationService]: للويب والاختبارات
abstract class PrayerNotificationService {
  /// طلب أذونات الإشعارات عند الحاجة (أندرويد 13+ و iOS).
  /// تعيد false إذا رفض المستخدم.
  Future<bool> ensurePermissions();

  /// جدولة تذكيرات اليوم وفق المواقيت ومفاتيح التفعيل
  /// (المفاتيح: fajr, dhuhr, asr, maghrib, isha).
  Future<void> scheduleForTimes(
    PrayerTimesModel times,
    Map<String, bool> enabledPrayers,
  );

  /// إلغاء كل التذكيرات المجدولة.
  Future<void> cancelAll();
}

/// تطبيق صوري: يُستخدم على الويب وفي الاختبارات.
class NoopPrayerNotificationService implements PrayerNotificationService {
  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> scheduleForTimes(
    PrayerTimesModel times,
    Map<String, bool> enabledPrayers,
  ) async {
    final enabled = enabledPrayers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    debugPrint('PrayerNotifications(noop): schedule for '
        '${times.date.toIso8601String().substring(0, 10)} -> $enabled');
  }

  @override
  Future<void> cancelAll() async {
    debugPrint('PrayerNotifications(noop): cancelAll');
  }
}
