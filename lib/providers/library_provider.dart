import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/library_repository.dart';
import '../models/library_book.dart';

/// آخر كتاب مفتوح.
class LastReadBook {
  const LastReadBook({required this.bookId, this.title});

  final String bookId;
  final String? title;
}

/// مزوّد المكتبة: التصنيفات والمصادر وآخر كتاب مفتوح (محفوظ محلياً).
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({required this.repository});

  static const String prefKeyLastReadId = 'library_last_read_book';
  static const String prefKeyLastReadTitle = 'library_last_read_title';

  final LibraryRepository repository;

  List<LibraryCategoryModel> _categories = [];
  List<LibrarySourceModel> _sources = [];
  bool _isLoading = false;
  String? _error;
  LastReadBook? _lastRead;

  List<LibraryCategoryModel> get categories => _categories;
  List<LibrarySourceModel> get sources => _sources;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LastReadBook? get lastRead => _lastRead;

  Future<void> init() async {
    await Future.wait([load(), _loadLastRead()]);
  }

  Future<void> load() async {
    if (_categories.isNotEmpty || _isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        repository.getCategories(),
        repository.getSources(),
      ]);
      _categories = results[0] as List<LibraryCategoryModel>;
      _sources = results[1] as List<LibrarySourceModel>;
    } catch (_) {
      _error = 'تعذر تحميل فهرس المكتبة';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(prefKeyLastReadId);
    if (id != null) {
      _lastRead = LastReadBook(
        bookId: id,
        title: prefs.getString(prefKeyLastReadTitle),
      );
      notifyListeners();
    }
  }

  /// حفظ آخر كتاب مفتوح (يُستدعى تلقائياً من شاشة تفاصيل الكتاب).
  Future<void> setLastRead({required String bookId, String? title}) async {
    _lastRead = LastReadBook(bookId: bookId, title: title);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyLastReadId, bookId);
    if (title != null) {
      await prefs.setString(prefKeyLastReadTitle, title);
    }
  }
}
