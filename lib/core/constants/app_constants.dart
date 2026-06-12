/// إعدادات وثوابت عامة للتطبيق.
class AppConstants {
  AppConstants._();

  /// عناوين واجهات برمجة التطبيقات الرسمية — تُستخدم لاحقاً في مصادر
  /// البيانات البعيدة (Remote Data Sources). تُترك قابلة للتهيئة حتى يتم
  /// اعتماد المصادر الرسمية النهائية.
  static const String quranApiBaseUrl = '';
  static const String hadithApiBaseUrl = '';
  static const String prayerApiBaseUrl = '';

  /// مفتاح واجهة Sunnah.com الرسمية — يُطلب من فريق Sunnah.com.
  /// عند تهيئته يتفعل مصدر المجموعات الكلاسيكية تلقائياً.
  static const String sunnahComApiKey = '';

  /// مسار ملفات البيانات المحلية (JSON) داخل التطبيق.
  static const String assetsDataPath = 'lib/assets_data';

  /// مفاتيح التخزين المحلي.
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyFontScale = 'font_scale';
  static const String prefKeyFavorites = 'favorites';
  static const String prefKeyTasbihCount = 'tasbih_count';

  /// مدة صلاحية الذاكرة المؤقتة الافتراضية.
  static const Duration defaultCacheTtl = Duration(hours: 24);
}
