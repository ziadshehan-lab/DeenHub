import 'package:geolocator/geolocator.dart';

/// إحداثيات موقع المستخدم.
class UserLocation {
  const UserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// واجهة خدمة الموقع — تُحقن نسخة وهمية في الاختبارات.
abstract class LocationService {
  /// محاولة الحصول على الموقع الحالي؛ تعيد null عند رفض الإذن أو
  /// تعطل خدمة الموقع (فتنتقل الواجهة للاختيار اليدوي للمدينة).
  Future<UserLocation?> tryGetCurrentLocation();
}

/// التطبيق الفعلي عبر حزمة geolocator.
class GeolocatorLocationService implements LocationService {
  @override
  Future<UserLocation?> tryGetCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // أي فشل في تحديد الموقع → الاختيار اليدوي
      return null;
    }
  }
}
