import 'package:flutter/foundation.dart';

import '../data/repositories/adhkar_repository.dart';
import '../models/dhikr.dart';

/// مزوّد الأذكار والأسماء الحسنى: حالة التصنيفات وقائمة الأسماء.
class AdhkarProvider extends ChangeNotifier {
  AdhkarProvider({required this.repository});

  final AdhkarRepository repository;

  List<DhikrCategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  List<AllahNameModel> _names = [];
  bool _isLoadingNames = false;
  String? _namesError;

  List<DhikrCategoryModel> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;

  List<AllahNameModel> get names => _names;
  bool get isLoadingNames => _isLoadingNames;
  String? get namesError => _namesError;

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty || _isLoadingCategories) return;
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();
    try {
      _categories = await repository.getCategories();
    } catch (_) {
      _categoriesError = 'تعذر تحميل تصنيفات الأذكار';
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadNames() async {
    if (_names.isNotEmpty || _isLoadingNames) return;
    _isLoadingNames = true;
    _namesError = null;
    notifyListeners();
    try {
      _names = await repository.getNamesOfAllah();
    } catch (_) {
      _namesError = 'تعذر تحميل الأسماء الحسنى';
    } finally {
      _isLoadingNames = false;
      notifyListeners();
    }
  }
}
