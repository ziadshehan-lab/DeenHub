import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// واجهة خدمة التخزين المؤقت المحلي — تستخدمها المستودعات لتخزين
/// استجابات JSON مع تاريخ انتهاء الصلاحية.
abstract class CacheService {
  Future<dynamic> read(String key);

  Future<void> write(
    String key,
    dynamic jsonValue, {
    Duration ttl = AppConstants.defaultCacheTtl,
  });

  Future<void> remove(String key);

  Future<void> clear();
}

/// تطبيق خدمة التخزين المؤقت اعتماداً على SharedPreferences.
/// يمكن لاحقاً استبداله بتطبيق يعتمد SQLite للبيانات الكبيرة.
class SharedPrefsCacheService implements CacheService {
  static const String _prefix = 'cache_';

  @override
  Future<dynamic> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;

    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    final expiresAt = DateTime.parse(envelope['expiresAt'] as String);
    if (DateTime.now().isAfter(expiresAt)) {
      await prefs.remove('$_prefix$key');
      return null;
    }
    return envelope['value'];
  }

  @override
  Future<void> write(
    String key,
    dynamic jsonValue, {
    Duration ttl = AppConstants.defaultCacheTtl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final envelope = jsonEncode({
      'expiresAt': DateTime.now().add(ttl).toIso8601String(),
      'value': jsonValue,
    });
    await prefs.setString('$_prefix$key', envelope);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
