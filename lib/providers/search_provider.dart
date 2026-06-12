import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/search_result_model.dart';
import '../services/unified_search_service.dart';

/// مزوّد البحث الموحد: الاستعلام، مرشحات الأنواع، النتائج المجمعة،
/// وسجل عمليات البحث الأخيرة (محفوظ محلياً).
class SearchProvider extends ChangeNotifier {
  SearchProvider({required this.service});

  static const String prefKeyRecent = 'recent_searches';
  static const int maxRecent = 10;

  final UnifiedSearchService service;

  String _query = '';
  Map<SearchResultType, List<SearchResultModel>> _results = {};
  final Set<SearchResultType> _filters = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  List<String> _recentSearches = [];

  String get query => _query;
  Map<SearchResultType, List<SearchResultModel>> get results => _results;

  /// المرشحات الفعالة (فارغة = كل الأنواع).
  Set<SearchResultType> get filters => Set.unmodifiable(_filters);
  bool get isLoading => _isLoading;
  bool get hasSearched => _hasSearched;
  String? get error => _error;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  bool get isEmpty =>
      _hasSearched && !_isLoading && _error == null && _results.isEmpty;

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches = prefs.getStringList(prefKeyRecent) ?? [];
    notifyListeners();
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    _query = trimmed;
    if (trimmed.isEmpty) {
      _results = {};
      _hasSearched = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _results = await service.search(trimmed, types: _filters);
      _hasSearched = true;
      await _saveRecent(trimmed);
    } catch (_) {
      _results = {};
      _hasSearched = true;
      _error = 'تعذر إتمام البحث';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تبديل مرشح نوع، ثم إعادة البحث إن وُجد استعلام.
  Future<void> toggleFilter(SearchResultType type) async {
    if (!_filters.remove(type)) {
      _filters.add(type);
    }
    notifyListeners();
    if (_query.isNotEmpty) await search(_query);
  }

  /// مسح كل المرشحات (= الكل).
  Future<void> clearFilters() async {
    if (_filters.isEmpty) return;
    _filters.clear();
    notifyListeners();
    if (_query.isNotEmpty) await search(_query);
  }

  Future<void> _saveRecent(String query) async {
    _recentSearches
      ..remove(query)
      ..insert(0, query);
    if (_recentSearches.length > maxRecent) {
      _recentSearches = _recentSearches.sublist(0, maxRecent);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(prefKeyRecent, _recentSearches);
  }

  Future<void> clearHistory() async {
    _recentSearches = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKeyRecent);
  }
}
