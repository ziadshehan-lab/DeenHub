import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/data/repositories/prayer_repository.dart';
import 'package:deenhub/models/content_source.dart';
import 'package:deenhub/models/prayer_times.dart';
import 'package:deenhub/providers/prayer_provider.dart';
import 'package:deenhub/services/location_service.dart';
import 'package:deenhub/services/prayer_notification_service.dart';
import 'package:deenhub/services/qibla_service.dart';

PrayerTimesModel _times() {
  final now = DateTime.now();
  DateTime at(int h) => DateTime(now.year, now.month, now.day, h);
  return PrayerTimesModel(
    date: DateTime(now.year, now.month, now.day),
    fajr: at(4),
    sunrise: at(5),
    dhuhr: at(12),
    asr: at(15),
    maghrib: at(19),
    isha: at(20),
    latitude: 21.4,
    longitude: 39.8,
    source: ContentSource(
      sourceName: 'AlAdhan',
      reference: 'test',
      lastUpdated: DateTime(2026),
    ),
  );
}

class _FakeRepo implements PrayerRepository {
  @override
  Future<PrayerTimesResult> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? methodId,
  }) async =>
      PrayerTimesResult(times: _times(), fromCache: false, isStale: false);

  @override
  QiblaDirection getQiblaDirection({
    required double latitude,
    required double longitude,
  }) =>
      const QiblaService().directionFrom(latitude: 0, longitude: 0);
}

class _FakeLocation implements LocationService {
  @override
  Future<UserLocation?> tryGetCurrentLocation() async =>
      const UserLocation(latitude: 21.4, longitude: 39.8);
}

/// خدمة إشعارات وهمية تسجل الجدولة وتحاكي رفض الإذن.
class _FakeNotifications implements PrayerNotificationService {
  _FakeNotifications({this.granted = true});

  bool granted;
  int permissionRequests = 0;
  final List<Map<String, bool>> scheduledToggles = [];
  int cancelCalls = 0;

  @override
  Future<bool> ensurePermissions() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<void> scheduleForTimes(
    PrayerTimesModel times,
    Map<String, bool> enabledPrayers,
  ) async {
    scheduledToggles.add(Map.of(enabledPrayers));
  }

  @override
  Future<void> cancelAll() async => cancelCalls++;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PrayerProvider buildProvider(_FakeNotifications notifications) {
    return PrayerProvider(
      repository: _FakeRepo(),
      locationService: _FakeLocation(),
      notificationService: notifications,
    );
  }

  test('schedules after every successful timings load', () async {
    final notifications = _FakeNotifications();
    final provider = buildProvider(notifications);

    await provider.init();
    expect(notifications.scheduledToggles, hasLength(1));

    await provider.loadPrayerTimes();
    expect(notifications.scheduledToggles, hasLength(2));
  });

  test('enabling a prayer requests permission then reschedules with it on',
      () async {
    final notifications = _FakeNotifications();
    final provider = buildProvider(notifications);
    await provider.init();

    final granted = await provider.toggleNotification('fajr');
    expect(granted, isTrue);
    expect(notifications.permissionRequests, 1);
    expect(provider.notificationToggles['fajr'], isTrue);
    expect(notifications.scheduledToggles.last['fajr'], isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('prayer_notify_fajr'), isTrue);

    // التعطيل لا يطلب إذناً ويعيد الجدولة بالمفتاح مطفأ
    await provider.toggleNotification('fajr');
    expect(notifications.permissionRequests, 1);
    expect(notifications.scheduledToggles.last['fajr'], isFalse);
  });

  test('denied permission keeps the toggle off and persists nothing',
      () async {
    final notifications = _FakeNotifications(granted: false);
    final provider = buildProvider(notifications);
    await provider.init();
    final schedulesBefore = notifications.scheduledToggles.length;

    final granted = await provider.toggleNotification('maghrib');
    expect(granted, isFalse);
    expect(provider.notificationToggles['maghrib'], isFalse);
    expect(notifications.scheduledToggles, hasLength(schedulesBefore));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('prayer_notify_maghrib'), isNull);
  });
}
