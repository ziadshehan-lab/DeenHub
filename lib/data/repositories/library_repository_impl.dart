import 'dart:async';

import '../../models/library_book.dart';
import '../datasources/library_data_source.dart';
import 'library_repository.dart';

/// تطبيق مستودع المكتبة: **محلي أولاً** — الفهرس مضمَّن بالكامل
/// (روابط موثقة إلى المصادر الرسمية) فيعمل دون اتصال؛ مصدر بعيد
/// اختياري احتياطاً للمستقبل، مع ذاكرة مؤقتة داخل الجلسة.
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({
    required LibraryDataSource local,
    LibraryDataSource? remote,
    this.remoteTimeout = const Duration(seconds: 8),
  })  : _local = local,
        _remote = remote;

  final LibraryDataSource _local;
  final LibraryDataSource? _remote;
  final Duration remoteTimeout;

  List<LibraryCategoryModel>? _categoriesCache;
  List<LibrarySourceModel>? _sourcesCache;
  final Map<String, List<LibraryBookModel>> _booksCache = {};

  Future<T> _localFirst<T>(
    Future<T> Function(LibraryDataSource source) operation,
  ) async {
    try {
      return await operation(_local);
    } catch (_) {
      final remote = _remote;
      if (remote == null) rethrow;
      return operation(remote).timeout(remoteTimeout);
    }
  }

  @override
  Future<List<LibraryCategoryModel>> getCategories() async {
    final cached = _categoriesCache;
    if (cached != null) return cached;
    final categories = await _localFirst((s) => s.fetchCategories());
    _categoriesCache = categories;
    return categories;
  }

  @override
  Future<List<LibrarySourceModel>> getSources() async {
    final cached = _sourcesCache;
    if (cached != null) return cached;
    final sources = await _localFirst((s) => s.fetchSources());
    _sourcesCache = sources;
    return sources;
  }

  @override
  Future<List<LibraryBookModel>> getBooks(String categoryId) async {
    final cached = _booksCache[categoryId];
    if (cached != null) return cached;
    final books = await _localFirst((s) => s.fetchBooks(categoryId));
    _booksCache[categoryId] = books;
    return books;
  }

  @override
  Future<List<LibraryBookModel>> getBooksBySource(String sourceId) async {
    final all = <LibraryBookModel>[];
    for (final category in await getCategories()) {
      final books = await getBooks(category.id);
      all.addAll(books.where((b) => b.sourceId == sourceId));
    }
    return all;
  }

  @override
  Future<LibraryBookModel> getBook(String bookId) {
    return _localFirst((s) => s.fetchBook(bookId));
  }

  @override
  Future<List<LibraryBookModel>> searchBooks(String query) {
    if (query.trim().isEmpty) return Future.value(const []);
    return _local.searchBooks(query);
  }
}
