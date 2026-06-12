/// النصوص العربية المستخدمة في واجهة التطبيق.
///
/// نصوص الواجهة فقط — المحتوى الإسلامي نفسه (آيات، أحاديث، أذكار...)
/// لا يُكتب هنا أبداً، بل يُحمَّل من مصادر البيانات الرسمية.
class AppStrings {
  AppStrings._();

  static const String appName = 'دين هب';

  // التنقل الرئيسي
  static const String home = 'الرئيسية';
  static const String quran = 'القرآن الكريم';
  static const String tafsir = 'التفسير';
  static const String hadith = 'الحديث الشريف';
  static const String prayer = 'مواقيت الصلاة';
  static const String qibla = 'اتجاه القبلة';
  static const String adhkar = 'الأذكار';
  static const String tasbih = 'المسبحة';
  static const String namesOfAllah = 'أسماء الله الحسنى';
  static const String library = 'المكتبة الإسلامية';
  static const String search = 'البحث';
  static const String favorites = 'المفضلة';
  static const String settings = 'الإعدادات';
  static const String surahDetail = 'تفاصيل السورة';
  static const String hadithDetail = 'تفاصيل الحديث';

  // عام
  static const String comingSoon =
      'سيتم تحميل المحتوى من المصادر الإسلامية الرسمية';
  static const String noContentYet = 'لا يوجد محتوى بعد';
  static const String sourceLabel = 'المصدر';
  static const String referenceLabel = 'المرجع';
  static const String scholarLabel = 'العالِم / المؤلف';
  static const String lastUpdatedLabel = 'آخر تحديث';

  // الإعدادات
  static const String darkMode = 'الوضع الداكن';
  static const String lightMode = 'الوضع الفاتح';
  static const String systemMode = 'حسب النظام';
  static const String theme = 'المظهر';
  static const String fontSize = 'حجم الخط';
  static const String about = 'عن التطبيق';

  // المسبحة
  static const String tasbihCount = 'عدد التسبيحات';
  static const String reset = 'إعادة تعيين';

  // القرآن الكريم
  static const String surahLabel = 'سورة';
  static const String ayahLabel = 'الآية';
  static const String ayatLabel = 'آيات';
  static const String juzLabel = 'الجزء';
  static const String pageLabel = 'الصفحة';
  static const String continueReading = 'متابعة القراءة';
  static const String lastReadLabel = 'آخر قراءة';
  static const String searchInQuran = 'ابحث في القرآن الكريم...';
  static const String noResults = 'لا توجد نتائج';
  static const String copyAyah = 'نسخ الآية';
  static const String shareAyah = 'مشاركة الآية';
  static const String ayahCopied = 'تم نسخ الآية';
  static const String addToFavorites = 'إضافة إلى المفضلة';
  static const String removeFromFavorites = 'إزالة من المفضلة';
  static const String setAsLastRead = 'تحديد كموضع القراءة';
  static const String lastReadSaved = 'تم حفظ موضع القراءة';
  static const String favoriteAyahs = 'الآيات المفضلة';
  static const String noFavoritesYet =
      'لا توجد عناصر مفضلة بعد — اضغط على آية لإضافتها';
  static const String loadError = 'تعذر تحميل المحتوى';
  static const String retry = 'إعادة المحاولة';
}
