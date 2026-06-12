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
  Future<dynamic> loadJson(String relativePath) async {
    final raw = await rootBundle
        .loadString('${AppConstants.assetsDataPath}/$relativePath');
    return jsonDecode(raw);
  }
}
