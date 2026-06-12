import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/app_strings.dart';
import '../core/utils/arabic_numbers.dart';
import '../models/prayer_times.dart';
import 'prayer_notification_service.dart';

/// تذكيرات الصلاة الفعلية على أندرويد و iOS عبر
/// flutter_local_notifications:
///
/// - جدولة آمنة زمنياً: TZDateTime بالمنطقة الزمنية الفعلية للجهاز
/// - تكرار يومي تلقائي (matchDateTimeComponents.time) — وتُحدَّث
///   الأوقات بدقة عند كل تحميل جديد للمواقيت لأن المزوّد يعيد
///   الجدولة بعد كل نجاح
/// - صوت الإشعار الافتراضي عبر قناة أندرويد عالية الأهمية و iOS
/// - معالجة أذونات أندرويد 13+ و iOS
class LocalPrayerNotificationService implements PrayerNotificationService {
  LocalPrayerNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'prayer_reminders';
  static const String _channelName = 'تذكيرات الصلاة';
  static const String _channelDescription =
      'إشعارات عند دخول وقت كل صلاة';

  /// معرّف إشعار ثابت لكل صلاة (لإلغاء/استبدال الجدولة بدقة).
  static const Map<String, int> notificationIds = {
    'fajr': 101,
    'dhuhr': 102,
    'asr': 103,
    'maghrib': 104,
    'isha': 105,
  };

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    try {
      tz_data.initializeTimeZones();
      try {
        // المنطقة الزمنية الفعلية للجهاز — جوهر السلامة الزمنية
        final localTimezone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localTimezone));
      } catch (_) {
        // يبقى الافتراضي (UTC) — أفضل من الفشل الكامل
      }

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
      return true;
    } on MissingPluginException {
      return false; // بيئة بلا منصة (اختبارات) — تجاهل بهدوء
    } catch (e) {
      debugPrint('PrayerNotifications: init failed: $e');
      return false;
    }
  }

  @override
  Future<bool> ensurePermissions() async {
    if (!await _ensureInitialized()) {
      // بيئة بلا منصة: لا أذونات تُطلب أصلاً
      return true;
    }
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            true;
      }
      return true;
    } catch (e) {
      debugPrint('PrayerNotifications: permission request failed: $e');
      return false;
    }
  }

  @override
  Future<void> scheduleForTimes(
    PrayerTimesModel times,
    Map<String, bool> enabledPrayers,
  ) async {
    if (!await _ensureInitialized()) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true, // صوت الإشعار الافتراضي
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    final prayerTimes = {
      'fajr': times.fajr,
      'dhuhr': times.dhuhr,
      'asr': times.asr,
      'maghrib': times.maghrib,
      'isha': times.isha,
    };

    for (final entry in prayerTimes.entries) {
      final id = notificationIds[entry.key]!;
      try {
        await _plugin.cancel(id); // استبدال الجدولة السابقة دائماً
        if (!(enabledPrayers[entry.key] ?? false)) continue;

        var scheduled = tz.TZDateTime.from(entry.value, tz.local);
        // إن مضى وقت اليوم فالموعد الأول غداً بالوقت نفسه
        if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        final prayerName = AppStrings.prayerNames[entry.key] ?? entry.key;

        await _plugin.zonedSchedule(
          id,
          'حان وقت صلاة $prayerName',
          '$prayerName — ${arabicTime(entry.value)}',
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          // تكرار يومي تلقائي بالوقت نفسه حتى تصل مواقيت أدق
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint(
            'PrayerNotifications: schedule ${entry.key} failed: $e');
      }
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!await _ensureInitialized()) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('PrayerNotifications: cancelAll failed: $e');
    }
  }
}
