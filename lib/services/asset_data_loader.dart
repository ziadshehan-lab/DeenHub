import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/constants/app_constants.dart';

/// محمّل ملفات البيانات المحلية (JSON) من مجلد lib/assets_data.
///
/// تستخدمه مصادر البيانات المحلية (Asset Data Sources) لقراءة المحتوى
/// الإسلامي المضمَّن مع التطبيق.
class AssetDataLoader {
  const AssetDataLoader();

  /// قراءة ملف JSON بمساره النسبي داخل مجلد البيانات.
  ///
  /// مثال: `loadJson('quran/surahs.json')`.
  ///
  /// يُفك ترميز UTF-8 هنا مباشرة بدل `loadString` التي تنقل فك ترميز
  /// الملفات الكبيرة إلى Isolate منفصل — وهو ما يعلّق اختبارات الواجهة.
  Future<dynamic> loadJson(String relativePath) async {
    final data = await rootBundle
        .load('${AppConstants.assetsDataPath}/$relativePath');
    final raw = utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return jsonDecode(raw);
  }
}
