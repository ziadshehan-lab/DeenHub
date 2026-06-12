# DeenHub — دين هب

تطبيق إسلامي شامل باللغة العربية (RTL) مبني بـ Flutter و Material 3، مع دعم الوضع الداكن.

## المبدأ المعماري الأساسي

**لا يُكتب أي محتوى إسلامي داخل واجهة المستخدم مباشرة.**

كل وحدة محتوى (قرآن، تفسير، حديث، مكتبة، أذكار، مواقيت) تمر عبر طبقات:

```
UI (Screens) → Repository (interface) → DataSource (interface)
                                          ├── Remote (HTTP API)
                                          ├── Asset (JSON محلي)
                                          ├── SQLite
                                          └── Cache
```

وكل عنصر محتوى يحمل معلومات الإسناد عبر `ContentSource`:
`sourceName` · `authorOrScholar` · `reference` · `sourceUrl` · `lastUpdated`

## هيكل المشروع

```
lib/
├── core/            # السمات، الثوابت، التوجيه (Routing)
├── models/          # نماذج البيانات مع معلومات الإسناد
├── data/
│   ├── datasources/ # واجهات مصادر البيانات المجردة (6)
│   └── repositories/# واجهات المستودعات (6)
├── services/        # ApiClient (HTTP) · CacheService · AssetDataLoader
├── screens/         # شاشات التطبيق (15)
├── widgets/         # مكونات واجهة مشتركة
├── providers/       # إدارة الحالة (الإعدادات، المفضلة)
└── assets_data/     # ملفات JSON للمحتوى المحلي
```

### واجهات مصادر البيانات والمستودعات

| الوحدة | DataSource | Repository |
|---|---|---|
| القرآن | `QuranDataSource` | `QuranRepository` |
| التفسير | `TafsirDataSource` | `TafsirRepository` |
| الحديث | `HadithDataSource` | `HadithRepository` |
| المكتبة | `LibraryDataSource` | `LibraryRepository` |
| الأذكار | `AdhkarDataSource` | `AdhkarRepository` |
| الصلاة | `PrayerDataSource` | `PrayerRepository` |

## الشاشات

الرئيسية · القرآن · تفاصيل السورة · التفسير · الحديث · تفاصيل الحديث · مواقيت الصلاة · اتجاه القبلة · الأذكار · المسبحة · أسماء الله الحسنى · المكتبة · البحث · المفضلة · الإعدادات

## التشغيل

```bash
flutter pub get
flutter run
```

## الاختبارات والتحقق

```bash
flutter analyze
flutter test
flutter build web
```

## وحدة القرآن الكريم (مكتملة)

أول وحدة مطبَّقة بالكامل وفق المعمارية:

- **`RemoteQuranDataSource`** — واجهة Quran.com الرسمية (v4): قائمة السور،
  الآيات (نص عثماني مع الجزء والصفحة)، والبحث.
- **`LocalQuranDataSource`** — النص العثماني الكامل (مشروع Tanzil، رواية
  حفص) مضمَّن كملفات JSON في `lib/assets_data/quran/` فيعمل التطبيق
  دون اتصال، مع بحث عربي يتجاهل التشكيل وعلامات المصحف.
- **`QuranRepositoryImpl`** — يفضّل المصدر البعيد مع مهلة، ويعود تلقائياً
  إلى المصدر المحلي عند انقطاع الاتصال، مع ذاكرة مؤقتة داخل الجلسة.

الميزات: قائمة السور · قراءة السورة بخط أميري مع البسملة · البحث
(بعيد/محلي) · مفضلة الآيات · حفظ موضع آخر قراءة · نسخ ومشاركة الآية
مع الإسناد الكامل للمصدر.

## المراحل التالية

تطبيق بقية الوحدات (التفسير، الحديث، المكتبة، الأذكار، المواقيت) بنفس
نمط وحدة القرآن: مصدر بعيد رسمي + مصدر محلي + مستودع منسِّق.
