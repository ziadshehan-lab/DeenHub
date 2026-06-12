import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/constants/app_strings.dart';
import 'package:deenhub/data/repositories/prayer_repository.dart';
import 'package:deenhub/main.dart';
import 'package:deenhub/models/content_source.dart';
import 'package:deenhub/models/prayer_times.dart';
import 'package:deenhub/providers/prayer_provider.dart';
import 'package:deenhub/services/location_service.dart';
import 'package:deenhub/services/qibla_service.dart';

PrayerTimesModel _todayTimes() {
  final now = DateTime.now();
  DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
  return PrayerTimesModel(
    date: DateTime(now.year, now.month, now.day),
    hijriDate: 'الجمعة ٢٦ ذوالحجة ١٤٤٧هـ',
    fajr: at(4, 10),
    sunrise: at(5, 38),
    dhuhr: at(12, 21),
    asr: at(15, 40),
    maghrib: at(19, 3),
    isha: at(20, 33),
    methodId: 4,
    methodName: 'Umm Al-Qura University, Makkah',
    latitude: 21.4225,
    longitude: 39.8262,
    source: ContentSource(
      sourceName: 'AlAdhan API — مواقيت الصلاة',
      reference: 'test',
      sourceUrl: 'https://aladhan.com',
      lastUpdated: DateTime(2026),
    ),
  );
}

class FakePrayerRepository implements PrayerRepository {
  FakePrayerRepository({this.fromCache = false, this.isStale = false});

  final bool fromCache;
  final bool isStale;
  int? lastMethodId;

  @override
  Future<PrayerTimesResult> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? methodId,
  }) async {
    lastMethodId = methodId;
    return PrayerTimesResult(
      times: _todayTimes(),
      fromCache: fromCache,
      isStale: isStale,
    );
  }

  @override
  QiblaDirection getQiblaDirection({
    required double latitude,
    required double longitude,
  }) {
    return const QiblaService()
        .directionFrom(latitude: latitude, longitude: longitude);
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService(this.location);

  final UserLocation? location;

  @override
  Future<UserLocation?> tryGetCurrentLocation() async => location;
}

/// pumpAndSettle لا يصلح مع عدّاد الثواني الحي في شاشة المواقيت —
/// نضخ إطارات محددة بدلاً منه.
Future<void> pumpFrames(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp({
    FakePrayerRepository? repository,
    UserLocation? gpsLocation,
  }) {
    return DeenHubApp(
      prayerRepository: repository ?? FakePrayerRepository(),
      locationService: FakeLocationService(gpsLocation),
    );
  }

  group('PrayerProvider.nextPrayerAfter', () {
    test('returns the next prayer of the day, skipping sunrise', () {
      final times = _todayTimes();
      final now = times.date;

      final beforeFajr =
          PrayerProvider.nextPrayerAfter(times, now.add(const Duration(hours: 3)));
      expect(beforeFajr.key, 'fajr');

      // بعد الفجر وقبل الظهر: التالي الظهر وليس الشروق
      final midMorning =
          PrayerProvider.nextPrayerAfter(times, now.add(const Duration(hours: 6)));
      expect(midMorning.key, 'dhuhr');

      final afternoon = PrayerProvider.nextPrayerAfter(
          times, now.add(const Duration(hours: 13)));
      expect(afternoon.key, 'asr');
    });

    test('after isha the next prayer is tomorrow fajr', () {
      final times = _todayTimes();
      final lateNight = times.date.add(const Duration(hours: 22));
      final next = PrayerProvider.nextPrayerAfter(times, lateNight);
      expect(next.key, 'fajr');
      expect(next.time.day, times.fajr.add(const Duration(days: 1)).day);
    });
  });

  testWidgets(
      'denied location shows manual city UI, selecting a city loads times',
      (tester) async {
    await tester.pumpWidget(buildApp(gpsLocation: null));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.prayer).first);
    await pumpFrames(tester);

    // واجهة الاختيار اليدوي للمدينة (الإذن مرفوض)
    expect(find.text(AppStrings.chooseCity), findsOneWidget);
    expect(find.text(AppStrings.useMyLocation), findsOneWidget);

    await tester.tap(find.text('مكة المكرمة'));
    await pumpFrames(tester);

    // التواريخ والصلاة التالية وأول المواقيت
    expect(find.text(AppStrings.nextPrayerLabel), findsOneWidget);
    expect(find.text('الفجر'), findsWidgets);
    expect(find.text('الجمعة ٢٦ ذوالحجة ١٤٤٧هـ'), findsOneWidget);
    expect(find.textContaining(AppStrings.remainingLabel), findsOneWidget);
    // لا تحذير ذاكرة محفوظة
    expect(find.textContaining(AppStrings.cachedTimesWarning), findsNothing);

    // بقية المواقيت الستة أسفل القائمة
    await tester.scrollUntilVisible(
      find.text('العشاء'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('العشاء'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);

    // المدينة حُفظت محلياً
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PrayerProvider.prefKeyCity), contains('مكة'));
  });

  testWidgets('cached times show an offline warning', (tester) async {
    await tester.pumpWidget(buildApp(
      repository: FakePrayerRepository(fromCache: true, isStale: true),
      gpsLocation: const UserLocation(latitude: 21.4225, longitude: 39.8262),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.prayer).first);
    await pumpFrames(tester);

    expect(find.textContaining(AppStrings.cachedTimesWarning), findsOneWidget);
    expect(find.textContaining(AppStrings.staleTimesWarning), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('المغرب'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('المغرب'), findsOneWidget);
  });

  testWidgets('qibla screen shows degrees, distance and instructions',
      (tester) async {
    await tester.pumpWidget(buildApp(
      // القاهرة → ١٣٦٫١°
      gpsLocation: const UserLocation(latitude: 30.0444, longitude: 31.2357),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.qibla).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('١٣٦'), findsOneWidget);
    expect(find.text(AppStrings.qiblaDegreesLabel), findsOneWidget);
    expect(find.textContaining(AppStrings.kmUnit), findsOneWidget);
    expect(find.text(AppStrings.qiblaInstructions), findsOneWidget);
  });

  testWidgets('qibla screen guides to set a location when none available',
      (tester) async {
    await tester.pumpWidget(buildApp(gpsLocation: null));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.qibla).first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.locateFirst), findsOneWidget);
    expect(find.text(AppStrings.openPrayerScreen), findsOneWidget);
  });

  testWidgets('settings: calculation method and notification toggles persist',
      (tester) async {
    final repository = FakePrayerRepository();
    await tester.pumpWidget(buildApp(
      repository: repository,
      gpsLocation: const UserLocation(latitude: 21.4225, longitude: 39.8262),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.prayer).first);
    await pumpFrames(tester);
    await tester.tap(find.byTooltip(AppStrings.prayerSettings));
    await pumpFrames(tester);

    // تغيير طريقة الحساب إلى رابطة العالم الإسلامي
    await tester.tap(find.text('رابطة العالم الإسلامي'));
    await pumpFrames(tester);
    // تفعيل تذكير الفجر
    await tester.tap(find.text('الفجر'));
    await pumpFrames(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(PrayerProvider.prefKeyMethod), 3);
    expect(prefs.getBool('prayer_notify_fajr'), isTrue);
    // إعادة التحميل تمت بالطريقة الجديدة
    expect(repository.lastMethodId, 3);
  });
}
