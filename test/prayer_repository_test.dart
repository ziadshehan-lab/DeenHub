import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/data/datasources/local_prayer_cache_data_source.dart';
import 'package:deenhub/data/datasources/prayer_data_source.dart';
import 'package:deenhub/data/repositories/prayer_repository_impl.dart';
import 'package:deenhub/models/content_source.dart';
import 'package:deenhub/models/prayer_times.dart';
import 'package:deenhub/services/cache_service.dart';

PrayerTimesModel _times(DateTime date) {
  DateTime at(int h, int m) =>
      DateTime(date.year, date.month, date.day, h, m);
  return PrayerTimesModel(
    date: DateTime(date.year, date.month, date.day),
    hijriDate: 'الجمعة ٢٦ ذوالحجة ١٤٤٧هـ',
    fajr: at(4, 10),
    sunrise: at(5, 38),
    dhuhr: at(12, 21),
    asr: at(15, 40),
    maghrib: at(19, 3),
    isha: at(20, 33),
    methodId: 4,
    methodName: 'Umm Al-Qura',
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

class FakeRemotePrayerSource implements PrayerDataSource {
  FakeRemotePrayerSource({this.failWithNetworkError = false});

  bool failWithNetworkError;
  int calls = 0;

  @override
  Future<PrayerTimesModel> fetchPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? methodId,
  }) async {
    calls++;
    if (failWithNetworkError) throw Exception('network down');
    return _times(date);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PrayerRepositoryImpl buildRepo(FakeRemotePrayerSource remote) {
    return PrayerRepositoryImpl(
      remote: remote,
      cache: LocalPrayerCacheDataSource(cache: SharedPrefsCacheService()),
    );
  }

  test('remote success is returned fresh and saved to cache', () async {
    final remote = FakeRemotePrayerSource();
    final repo = buildRepo(remote);

    final result = await repo.getPrayerTimes(
      date: DateTime(2026, 6, 12),
      latitude: 21.4225,
      longitude: 39.8262,
      methodId: 4,
    );
    expect(result.fromCache, isFalse);
    expect(result.times.fajr.hour, 4);

    // انقطاع الشبكة: تُعاد المواقيت المحفوظة موسومة fromCache
    remote.failWithNetworkError = true;
    final cached = await repo.getPrayerTimes(
      date: DateTime(2026, 6, 12),
      latitude: 21.4225,
      longitude: 39.8262,
      methodId: 4,
    );
    expect(cached.fromCache, isTrue);
    expect(cached.isStale, isFalse); // اليوم نفسه
    expect(cached.times.isha.hour, 20);
    expect(cached.times.hijriDate, isNotNull);
  });

  test('cached times from a previous day are flagged stale', () async {
    final remote = FakeRemotePrayerSource();
    final repo = buildRepo(remote);

    await repo.getPrayerTimes(
      date: DateTime(2026, 6, 11),
      latitude: 21.4225,
      longitude: 39.8262,
      methodId: 4,
    );
    remote.failWithNetworkError = true;
    final result = await repo.getPrayerTimes(
      date: DateTime(2026, 6, 12),
      latitude: 21.4225,
      longitude: 39.8262,
      methodId: 4,
    );
    expect(result.fromCache, isTrue);
    expect(result.isStale, isTrue);
  });

  test('no network and no cache throws PrayerUnavailableException', () {
    final repo = buildRepo(FakeRemotePrayerSource(failWithNetworkError: true));
    expect(
      () => repo.getPrayerTimes(
        date: DateTime(2026, 6, 12),
        latitude: 30.0,
        longitude: 31.0,
        methodId: 4,
      ),
      throwsA(isA<PrayerUnavailableException>()),
    );
  });

  test('cache is keyed per location and method', () async {
    final remote = FakeRemotePrayerSource();
    final repo = buildRepo(remote);
    await repo.getPrayerTimes(
      date: DateTime(2026, 6, 12),
      latitude: 21.4225,
      longitude: 39.8262,
      methodId: 4,
    );

    remote.failWithNetworkError = true;
    // موقع آخر لا يملك ذاكرة محفوظة
    expect(
      () => repo.getPrayerTimes(
        date: DateTime(2026, 6, 12),
        latitude: 30.0444,
        longitude: 31.2357,
        methodId: 4,
      ),
      throwsA(isA<PrayerUnavailableException>()),
    );
    // الطريقة الأخرى كذلك
    expect(
      () => repo.getPrayerTimes(
        date: DateTime(2026, 6, 12),
        latitude: 21.4225,
        longitude: 39.8262,
        methodId: 3,
      ),
      throwsA(isA<PrayerUnavailableException>()),
    );
  });

  test('qibla direction is computed locally (offline)', () {
    final repo = buildRepo(FakeRemotePrayerSource(failWithNetworkError: true));
    final qibla =
        repo.getQiblaDirection(latitude: 30.0444, longitude: 31.2357);
    expect(qibla.directionDegrees, closeTo(136.14, 0.1));
  });
}
