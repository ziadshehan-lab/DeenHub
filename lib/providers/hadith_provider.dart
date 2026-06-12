import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/hadith_repository.dart';
import '../models/hadith_models.dart';

/// موضع آخر حديث مفتوح.
class LastReadHadith {
  const LastReadHadith({required this.hadithId, this.title});

  final String hadithId;
  final String? title;
}

/// مزوّد الحديث: حالة قائمة الكتب وموضع آخر قراءة.
class HadithProvider extends ChangeNotifier {
  HadithProvider({required this.repository});

  static const String _prefKeyLastReadId = 'hadith_last_read_id';
  static const String _prefKeyLastReadTitle = 'hadith_last_read_title';

  final HadithRepository repository;

  List<HadithBookModel> _books = [];
  bool _isLoadingBooks = false;
  String? _booksError;
  LastReadHadith? _lastRead;

  List<HadithBookModel> get books => _books;
  bool get isLoadingBooks => _isLoadingBooks;
  String? get booksError => _booksError;
  LastReadHadith? get lastRead => _lastRead;

  Future<void> init() async {
    await Future.wait([loadBooks(), _loadLastRead()]);
  }

  Future<void> loadBooks() async {
    if (_books.isNotEmpty || _isLoadingBooks) return;
    _isLoadingBooks = true;
    _booksError = null;
    notifyListeners();
    try {
      _books = await repository.getBooks();
    } catch (_) {
      _booksError = 'تعذر تحميل كتب الحديث';
    } finally {
      _isLoadingBooks = false;
      notifyListeners();
    }
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKeyLastReadId);
    if (id != null) {
      _lastRead = LastReadHadith(
        hadithId: id,
        title: prefs.getString(_prefKeyLastReadTitle),
      );
      notifyListeners();
    }
  }

  /// حفظ آخر حديث مفتوح (يُستدعى تلقائياً عند فتح أي حديث).
  Future<void> setLastRead({required String hadithId, String? title}) async {
    _lastRead = LastReadHadith(hadithId: hadithId, title: title);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastReadId, hadithId);
    if (title != null) {
      await prefs.setString(_prefKeyLastReadTitle, title);
    }
  }
}
