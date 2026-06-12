import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// مزوّد المفضلة: يحفظ معرّفات العناصر المفضلة (آية، حديث، ذكر، كتاب)
/// بصيغة `نوع:معرّف` مثل `hadith:bukhari-1`.
class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteIds
      ..clear()
      ..addAll(prefs.getStringList(AppConstants.prefKeyFavorites) ?? []);
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (!_favoriteIds.remove(id)) {
      _favoriteIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.prefKeyFavorites,
      _favoriteIds.toList(),
    );
  }
}
