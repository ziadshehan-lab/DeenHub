import 'dart:async';

import '../../core/utils/arabic_text.dart';
import '../../models/dhikr.dart';
import '../datasources/adhkar_data_source.dart';
import 'adhkar_repository.dart';

/// تطبيق مستودع الأذكار: **محلي أولاً** — المحتوى الكامل مضمَّن مع
/// التطبيق (من المصادر الرسمية نفسها) وهو ثابت، فيعمل كل شيء دون
/// اتصال فوراً؛ المصدر البعيد احتياط عند تعذر القراءة المحلية.
class AdhkarRepositoryImpl implements AdhkarRepository {
  AdhkarRepositoryImpl({
    required AdhkarDataSource local,
    AdhkarDataSource? remote,
    this.remoteTimeout = const Duration(seconds: 8),
  })  : _local = local,
        _remote = remote;

  final AdhkarDataSource _local;
  final AdhkarDataSource? _remote;
  final Duration remoteTimeout;

  final Map<String, List<DhikrModel>> _adhkarCache = {};
  List<DhikrCategoryModel>? _categoriesCache;
  List<AllahNameModel>? _namesCache;

  Future<T> _localFirst<T>(
    Future<T> Function(AdhkarDataSource source) operation,
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
  Future<List<DhikrCategoryModel>> getCategories() async {
    final cached = _categoriesCache;
    if (cached != null) return cached;
    final categories = await _localFirst((s) => s.fetchCategories());
    _categoriesCache = categories;
    return categories;
  }

  @override
  Future<List<DhikrModel>> getAdhkar(String categoryId) async {
    final cached = _adhkarCache[categoryId];
    if (cached != null) return cached;
    final adhkar = await _localFirst((s) => s.fetchAdhkar(categoryId));
    _adhkarCache[categoryId] = adhkar;
    return adhkar;
  }

  @override
  Future<DhikrModel> getDhikr(String dhikrId) async {
    for (final category in await getCategories()) {
      final adhkar = await getAdhkar(category.id);
      for (final dhikr in adhkar) {
        if (dhikr.id == dhikrId) return dhikr;
      }
    }
    throw AdhkarUnavailableException('ذكر غير موجود: $dhikrId');
  }

  @override
  Future<List<DhikrModel>> searchAdhkar(String query) {
    if (query.trim().isEmpty) return Future.value(const []);
    return _local.searchAdhkar(query);
  }

  @override
  Future<List<AllahNameModel>> getNamesOfAllah() async {
    final cached = _namesCache;
    if (cached != null) return cached;
    final names = await _localFirst((s) => s.fetchNamesOfAllah());
    _namesCache = names;
    return names;
  }

  @override
  Future<AllahNameModel> getName(int number) async {
    final names = await getNamesOfAllah();
    final name = names.where((n) => n.number == number).firstOrNull;
    if (name == null) {
      throw AdhkarUnavailableException('اسم غير موجود: $number');
    }
    return name;
  }

  @override
  Future<List<AllahNameModel>> searchNames(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getNamesOfAllah();

    final normalizedQuery = normalizeArabic(trimmed);
    final lowerQuery = trimmed.toLowerCase();
    final names = await getNamesOfAllah();
    return names.where((n) {
      if (normalizeArabic(n.name).contains(normalizedQuery)) return true;
      final transliteration = n.transliteration?.toLowerCase() ?? '';
      final meaning = n.meaning?.toLowerCase() ?? '';
      return transliteration.contains(lowerQuery) ||
          meaning.contains(lowerQuery);
    }).toList();
  }
}
