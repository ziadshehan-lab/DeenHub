import 'package:flutter/foundation.dart';

import '../models/prayer_times.dart';

/// واجهة خدمة تذكيرات الصلاة المحلية.
///
/// البنية جاهزة: المستودع/المزوّد يستدعي [scheduleForTimes] بعد كل
/// تحميل ناجح للمواقيت مع مفاتيح التفعيل لكل صلاة. التطبيق الفعلي
/// عبر flutter_local_notifications يتطلب إعداداً خاصاً لكل منصة
/// (قنوات أندرويد، أذونات iOS) ويُضاف لاحقاً دون تغيير هذه الواجهة.
abstract class PrayerNotificationService {
  /// جدولة تذكيرات اليوم وفق المواقيت ومفاتيح التفعيل
  /// (المفاتيح: fajr, dhuhr, asr, maghrib, isha).
  Future<void> scheduleForTimes(
    PrayerTimesModel times,
    Map<String, bool> enabledPrayers,
  );

  /// إلغاء كل التذكيرات المجدولة.
  Future<void> cancelAll();
}

/// تطبيق صوري: يسجل الجدولة في وضع التطوير فقط — يُستبدل بتطبيق
/// منصات فعلي لاحقاً.
class NoopPrayerNotificationService implements PrayerNotificationService {
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
