import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/calculation_methods.dart';
import '../data/repositories/prayer_repository.dart';
import '../models/city_model.dart';
import '../models/prayer_times.dart';
import '../services/asset_data_loader.dart';
import '../services/location_service.dart';
import '../services/prayer_notification_service.dart';

/// الصلاة التالية مع وقتها.
class NextPrayer {
  const NextPrayer({required this.key, required this.time});

  final String key;
  final DateTime time;
}

/// مزوّد مواقيت الصلاة: الموقع (GPS أو مدينة محفوظة)، طريقة الحساب،
/// المواقيت، تفعيل التذكيرات — مع حفظ كل التفضيلات محلياً.
class PrayerProvider extends ChangeNotifier {
  PrayerProvider({
    required this.repository,
    required this.locationService,
    PrayerNotificationService? notificationService,
    AssetDataLoader assetLoader = const AssetDataLoader(),
  })  : _notifications =
            notificationService ?? NoopPrayerNotificationService(),
        _assetLoader = assetLoader;

  static const String prefKeyCity = 'prayer_city';
  static const String prefKeyMethod = 'prayer_method';
  static const String prefKeyNotifyPrefix = 'prayer_notify_';

  /// الصلوات القابلة للتذكير (الشروق ليس صلاة).
  static const List<String> notifiablePrayers = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  final PrayerRepository repository;
  final LocationService locationService;
  final PrayerNotificationService _notifications;
  final AssetDataLoader _assetLoader;

  CityModel? _city;
  UserLocation? _gpsLocation;
  int _methodId = defaultCalculationMethod.id;
  final Map<String, bool> _notificationToggles = {
    for (final p in notifiablePrayers) p: false,
  };

  PrayerTimesResult? _result;
  bool _isLoading = false;
  String? _error;
  bool _needsManualLocation = false;
  List<CityModel> _cities = [];

  CityModel? get city => _city;
  int get methodId => _methodId;
  Map<String, bool> get notificationToggles =>
      Map.unmodifiable(_notificationToggles);
  PrayerTimesResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// لا موقع متاحاً: تُعرض واجهة اختيار المدينة يدوياً.
  bool get needsManualLocation => _needsManualLocation;
  List<CityModel> get cities => _cities;

  /// الإحداثيات الفعالة: المدينة المختارة أولاً ثم موقع GPS.
  ({double latitude, double longitude})? get coordinates {
    final city = _city;
    if (city != null) {
      return (latitude: city.latitude, longitude: city.longitude);
    }
    final gps = _gpsLocation;
    if (gps != null) {
      return (latitude: gps.latitude, longitude: gps.longitude);
    }
    return null;
  }

  /// اسم الموقع المعروض.
  String? get locationLabel =>
      _city?.nameArabic ?? (_gpsLocation != null ? 'موقعي الحالي' : null);

  Future<void> init() async {
    await _loadPrefs();
    if (_city != null) {
      await loadPrayerTimes();
      return;
    }
    await useCurrentLocation();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cityJson = prefs.getString(prefKeyCity);
    if (cityJson != null) {
      try {
        _city = CityModel.fromJson(
            jsonDecode(cityJson) as Map<String, dynamic>);
      } catch (_) {
        _city = null;
      }
    }
    _methodId = prefs.getInt(prefKeyMethod) ?? defaultCalculationMethod.id;
    for (final prayer in notifiablePrayers) {
      _notificationToggles[prayer] =
          prefs.getBool('$prefKeyNotifyPrefix$prayer') ?? false;
    }
    notifyListeners();
  }

  /// تحميل قائمة المدن للاختيار اليدوي (من البيانات المضمَّنة).
  Future<void> loadCities() async {
    if (_cities.isNotEmpty) return;
    final json =
        await _assetLoader.loadJson('prayer/cities.json') as Map<String, dynamic>;
    _cities = (json['cities'] as List<dynamic>)
        .map((c) => CityModel.fromJson(c as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  /// محاولة استخدام الموقع الحالي؛ عند الرفض تُعرض واجهة اختيار المدينة.
  Future<void> useCurrentLocation() async {
    final location = await locationService.tryGetCurrentLocation();
    if (location == null) {
      _needsManualLocation = true;
      await loadCities();
      notifyListeners();
      return;
    }
    _gpsLocation = location;
    _city = null;
    _needsManualLocation = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKeyCity);
    await loadPrayerTimes();
  }

  /// اختيار مدينة يدوياً وحفظها.
  Future<void> selectCity(CityModel city) async {
    _city = city;
    _needsManualLocation = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyCity, jsonEncode(city.toJson()));
    await loadPrayerTimes();
  }

  Future<void> setMethod(int methodId) async {
    _methodId = methodId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefKeyMethod, methodId);
    await loadPrayerTimes();
  }

  /// تفعيل/تعطيل تذكير صلاة. عند التفعيل تُطلب أذونات الإشعارات أولاً؛
  /// تعيد false إذا رُفضت (ولا يتغير المفتاح).
  Future<bool> toggleNotification(String prayer) async {
    final enabling = !(_notificationToggles[prayer] ?? false);
    if (enabling && !await _notifications.ensurePermissions()) {
      return false;
    }
    _notificationToggles[prayer] = enabling;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$prefKeyNotifyPrefix$prayer', enabling);
    final times = _result?.times;
    if (times != null) {
      await _notifications.scheduleForTimes(times, _notificationToggles);
    }
    return true;
  }

  Future<void> loadPrayerTimes() async {
    final coords = coordinates;
    if (coords == null) {
      _needsManualLocation = true;
      await loadCities();
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _result = await repository.getPrayerTimes(
        date: DateTime.now(),
        latitude: coords.latitude,
        longitude: coords.longitude,
        methodId: _methodId,
      );
      await _notifications.scheduleForTimes(
        _result!.times,
        _notificationToggles,
      );
    } catch (_) {
      _error = 'تعذر تحميل مواقيت الصلاة';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// الصلاة التالية بعد اللحظة المعطاة (الشروق ليس صلاة لكنه يُعرض؛
  /// يُحتسب ضمن التسلسل). إن انقضت كل المواقيت فالتالي فجر الغد
  /// (تقديراً بوقت فجر اليوم + يوم).
  static NextPrayer nextPrayerAfter(PrayerTimesModel times, DateTime now) {
    for (final (key, time) in times.orderedTimes) {
      if (key == 'sunrise') continue;
      if (time.isAfter(now)) return NextPrayer(key: key, time: time);
    }
    return NextPrayer(
      key: 'fajr',
      time: times.fajr.add(const Duration(days: 1)),
    );
  }
}
