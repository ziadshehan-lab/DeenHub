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

  // التفسير
  static const String viewTafsir = 'عرض التفسير';
  static const String tafsirOfAyah = 'تفسير الآية';
  static const String tafsirBook = 'كتاب التفسير';
  static const String tafsirUnavailable = 'هذا التفسير غير متاح حالياً';
  static const String tafsirComingSoon = 'قريباً';
  static const String tafsirHint =
      'افتح أي سورة ثم اضغط على آية واختر «عرض التفسير»';
  static const String availableEditions = 'كتب التفسير المعتمدة';
  static const String searchInTafsirText = 'ابحث داخل نص التفسير...';
  static const String searchInTafsirCorpus =
      'ابحث في نصوص التفسير المحفوظة...';
  static const String tafsirBookmarks = 'إشارات التفسير المرجعية';
  static const String addTafsirBookmark = 'إضافة إشارة مرجعية';
  static const String removeTafsirBookmark = 'إزالة الإشارة المرجعية';
  static const String tafsirFavorites = 'مقاطع التفسير المفضلة';
  static const String matchesFound = 'نتيجة';
  static const String noMatchesInText = 'لا توجد مطابقات في النص';

  // الحديث الشريف
  static const String hadithBooks = 'كتب الحديث';
  static const String hadithChapters = 'الأبواب';
  static const String hadithLabel = 'حديث';
  static const String hadithsCountSuffix = 'حديثاً';
  static const String narratorLabel = 'الراوي';
  static const String muhaddithLabel = 'المحدِّث';
  static const String gradeLabel = 'الدرجة';
  static const String attributionLabel = 'العزو';
  static const String hadithNumberLabel = 'رقم الحديث';
  static const String explanationLabel = 'شرح الحديث';
  static const String englishTranslation = 'الترجمة الإنجليزية';
  static const String searchInHadith = 'ابحث في الأحاديث الشريفة...';
  static const String copyHadith = 'نسخ الحديث';
  static const String shareHadith = 'مشاركة الحديث';
  static const String hadithCopied = 'تم نسخ الحديث';
  static const String favoriteHadiths = 'الأحاديث المفضلة';
  static const String bookLabel = 'الكتاب';

  // مواقيت الصلاة والقبلة
  static const Map<String, String> prayerNames = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };
  static const String nextPrayerLabel = 'الصلاة التالية';
  static const String remainingLabel = 'المتبقي';
  static const String chooseCity = 'اختر مدينتك';
  static const String chooseCityHint =
      'تعذر تحديد موقعك تلقائياً — اختر مدينتك لعرض المواقيت';
  static const String useMyLocation = 'استخدام موقعي الحالي';
  static const String changeLocation = 'تغيير الموقع';
  static const String cachedTimesWarning =
      'تعذر الاتصال — تُعرض آخر مواقيت محفوظة';
  static const String staleTimesWarning = 'وهي ليوم سابق';
  static const String calculationMethodLabel = 'طريقة الحساب';
  static const String prayerSettings = 'إعدادات الصلاة';
  static const String prayerNotifications = 'تذكيرات الصلاة';
  static const String notificationsNote =
      'يصلك إشعار بصوت عند دخول وقت كل صلاة مفعَّلة، ويُعاد جدولتها '
      'يومياً وتُحدَّث تلقائياً مع كل تحميل للمواقيت.';
  static const String notificationsPermissionDenied =
      'لم يُمنح إذن الإشعارات — فعِّله من إعدادات النظام لتصلك التذكيرات';
  static const String qiblaDegreesLabel = 'درجة من الشمال الحقيقي';
  static const String distanceToKaaba = 'المسافة إلى الكعبة المشرفة';
  static const String kmUnit = 'كم';
  static const String qiblaInstructions =
      'وجّه السهم نحو الاتجاه المبيّن. إن لم تتوفر بوصلة في جهازك، '
      'استخدم بوصلة خارجية وحدد الزاوية المعروضة بالدرجات من الشمال '
      'الحقيقي باتجاه عقارب الساعة.';
  static const String locateFirst =
      'حدد موقعك أو مدينتك أولاً من شاشة مواقيت الصلاة';
  static const String openPrayerScreen = 'فتح مواقيت الصلاة';

  // الأذكار وأسماء الله الحسنى
  static const String searchInAdhkar = 'ابحث في الأذكار...';
  static const String repeatLabel = 'التكرار';
  static const String onceLabel = 'مرة واحدة';
  static const String copyDhikr = 'نسخ الذكر';
  static const String shareDhikr = 'مشاركة الذكر';
  static const String dhikrCopied = 'تم نسخ الذكر';
  static const String favoriteAdhkar = 'الأذكار المفضلة';
  static const String dhikrCountSuffix = 'ذكراً';
  static const String searchInNames = 'ابحث في الأسماء الحسنى...';
  static const String transliterationLabel = 'النطق';
  static const String meaningLabel = 'المعنى';
  static const String explanationLabel2 = 'الشرح';
  static const String favoriteNames = 'الأسماء الحسنى المفضلة';
  static const String nameNumberLabel = 'الاسم رقم';

  // المكتبة الإسلامية
  static const String searchInLibrary = 'ابحث في فهرس المكتبة...';
  static const String libraryCategories = 'التصنيفات';
  static const String librarySources = 'المصادر المعتمدة';
  static const String authorLabel = 'المؤلف';
  static const String categoryLabel = 'التصنيف';
  static const String bookLinkLabel = 'رابط الكتاب';
  static const String copyBookInfo = 'نسخ بيانات الكتاب';
  static const String shareBook = 'مشاركة الكتاب';
  static const String bookInfoCopied = 'تم نسخ بيانات الكتاب';
  static const String favoriteBooks = 'الكتب المفضلة';
  static const String continueBrowsing = 'متابعة التصفح';
  static const String booksCountSuffix = 'كتاباً وموسوعة';
  static const String openSourceNote =
      'يُفتح الكتاب على موقع مصدره الرسمي عبر الرابط أعلاه';

  // البحث الموحد
  static const String searchEverywhere = 'ابحث في كل أقسام التطبيق...';
  static const String recentSearches = 'عمليات البحث الأخيرة';
  static const String clearHistory = 'مسح السجل';
  static const String allFilter = 'الكل';
  static const String searchError = 'تعذر إتمام البحث';
}
