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

## المرحلة الحالية

المرحلة الأولى: هيكل المشروع، التنقل، السمات، دعم RTL، الشاشات الأولية،
وواجهات مصادر البيانات والمستودعات. المراحل التالية ستضيف تطبيقات
(implementations) لمصادر البيانات من المصادر الإسلامية الرسمية.
