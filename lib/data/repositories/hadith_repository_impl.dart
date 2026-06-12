import 'dart:async';

import '../../models/hadith_models.dart';
import '../../services/cache_service.dart';
import '../datasources/hadith_data_source.dart';
import 'hadith_repository.dart';

/// تطبيق مستودع الحديث.
///
/// سياسة الجلب (التفصيل): ذاكرة الجلسة ← الذاكرة الدائمة (دون اتصال) ←
/// المصادر البعيدة بترتيب الأولوية (تُتخطى غير المهيأة، مثل Sunnah.com
/// دون مفتاح) مع كتابة الناتج في الذاكرتين ← الملفات المحلية المضمَّنة.
///
/// البحث: مصادر البحث البعيدة بالترتيب (الدرر السنية أولاً) ثم
/// البحث المحلي دون اتصال.
class HadithRepositoryImpl implements HadithRepository {
  HadithRepositoryImpl({
    List<HadithDataSource> remotes = const [],
    List<HadithDataSource> searchRemotes = const [],
    required HadithDataSource local,
    CacheService? cache,
    this.remoteTimeout = const Duration(seconds: 8),
    this.cacheTtl = const Duration(days: 30),
  })  : _remotes = remotes,
        _searchRemotes = searchRemotes,
        _local = local,
        _cache = cache;

  final List<HadithDataSource> _remotes;
  final List<HadithDataSource> _searchRemotes;
  final HadithDataSource _local;
  final CacheService? _cache;
  final Duration remoteTimeout;
  final Duration cacheTtl;

  List<HadithBookModel>? _booksCache;
  final Map<String, List<HadithChapterModel>> _chaptersCache = {};
  final Map<String, List<HadithModel>> _listCache = {};
  final Map<String, HadithModel> _hadithCache = {};

  /// تنفيذ عملية على المصادر البعيدة بالترتيب ثم المحلي.
  Future<T> _remoteFirst<T>(
    Future<T> Function(HadithDataSource source) operation,
  ) async {
    for (final remote in _remotes) {
      if (!remote.isConfigured) continue;
      try {
        return await operation(remote).timeout(remoteTimeout);
      } catch (_) {
        continue; // غير مدعوم أو خطأ شبكة — جرّب التالي
      }
    }
    return operation(_local);
  }

  @override
  Future<List<HadithBookModel>> getBooks() async {
    final cached = _booksCache;
    if (cached != null) return cached;
    final books = await _remoteFirst((s) => s.fetchBooks());
    _booksCache = books;
    return books;
  }

  @override
  Future<List<HadithChapterModel>> getChapters(String bookId) async {
    final cached = _chaptersCache[bookId];
    if (cached != null) return cached;
    final chapters = await _remoteFirst((s) => s.fetchChapters(bookId));
    _chaptersCache[bookId] = chapters;
    return chapters;
  }

  @override
  Future<List<HadithModel>> getHadiths(
    String chapterId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final key = '$chapterId/$page/$pageSize';
    final cached = _listCache[key];
    if (cached != null) return cached;
    final hadiths = await _remoteFirst(
      (s) => s.fetchHadiths(chapterId, page: page, pageSize: pageSize),
    );
    _listCache[key] = hadiths;
    return hadiths;
  }

  @override
  Future<HadithModel> getHadith(String hadithId) async {
    final inMemory = _hadithCache[hadithId];
    if (inMemory != null) return inMemory;

    // الذاكرة الدائمة — قراءة ما سبق فتحه دون اتصال
    final cache = _cache;
    final persistentKey = 'hadith_$hadithId';
    if (cache != null) {
      try {
        final stored = await cache.read(persistentKey);
        if (stored != null) {
          final hadith =
              HadithModel.fromJson((stored as Map).cast<String, dynamic>());
          _hadithCache[hadithId] = hadith;
          return hadith;
        }
      } catch (_) {
        // ذاكرة تالفة — تجاهل وتابع الجلب
      }
    }

    for (final remote in _remotes) {
      if (!remote.isConfigured) continue;
      try {
        final hadith =
            await remote.fetchHadith(hadithId).timeout(remoteTimeout);
        _hadithCache[hadithId] = hadith;
        await cache?.write(persistentKey, hadith.toJson(), ttl: cacheTtl);
        return hadith;
      } catch (_) {
        continue;
      }
    }

    try {
      final hadith = await _local.fetchHadith(hadithId);
      _hadithCache[hadithId] = hadith;
      return hadith;
    } on HadithUnavailableException {
      throw const HadithUnavailableException(
        'الحديث غير متاح حالياً — تحقق من الاتصال بالإنترنت',
      );
    }
  }

  @override
  Future<List<HadithSearchResultModel>> searchHadiths(String query) async {
    if (query.trim().isEmpty) return const [];

    for (final remote in _searchRemotes) {
      if (!remote.isConfigured) continue;
      try {
        final results =
            await remote.searchHadiths(query).timeout(remoteTimeout);
        if (results.isNotEmpty) return results;
      } catch (_) {
        continue;
      }
    }
    // البحث المحلي دون اتصال
    return _local.searchHadiths(query);
  }
}
