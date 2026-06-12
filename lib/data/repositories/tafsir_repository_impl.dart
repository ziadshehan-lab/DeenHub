import 'dart:async';

import '../../models/tafsir_models.dart';
import '../../services/cache_service.dart';
import '../datasources/tafsir_data_source.dart';
import 'tafsir_repository.dart';

/// تطبيق مستودع التفسير.
///
/// سياسة جلب النص:
/// 1. الذاكرة المؤقتة داخل الجلسة
/// 2. الذاكرة المؤقتة الدائمة (دون اتصال) إن وُجدت
/// 3. المصادر البعيدة بالترتيب (كل مصدر يخدم كتبه فقط) مع مهلة،
///    ويُكتب الناتج في الذاكرتين
/// 4. الملفات المحلية المضمَّنة
///
/// سجل الكتب يُقرأ من السجل المحلي المضمَّن لأنه القائمة المعتمدة الكاملة.
class TafsirRepositoryImpl implements TafsirRepository {
  TafsirRepositoryImpl({
    List<TafsirDataSource> remotes = const [],
    required TafsirDataSource local,
    CacheService? cache,
    this.remoteTimeout = const Duration(seconds: 8),
    this.cacheTtl = const Duration(days: 30),
  })  : _remotes = remotes,
        _local = local,
        _cache = cache;

  final List<TafsirDataSource> _remotes;
  final TafsirDataSource _local;
  final CacheService? _cache;
  final Duration remoteTimeout;
  final Duration cacheTtl;

  List<TafsirEditionModel>? _editionsCache;
  final Map<String, TafsirModel> _memoryCache = {};

  String _cacheKey(String editionId, int surah, int ayah) =>
      'tafsir_${editionId}_${surah}_$ayah';

  @override
  Future<List<TafsirEditionModel>> getEditions() async {
    final cached = _editionsCache;
    if (cached != null) return cached;

    List<TafsirEditionModel>? editions;
    try {
      editions = await _local.fetchEditions();
    } catch (_) {
      for (final remote in _remotes) {
        try {
          editions = await remote.fetchEditions().timeout(remoteTimeout);
          break;
        } catch (_) {
          continue;
        }
      }
    }
    if (editions == null) {
      throw const TafsirUnavailableException('تعذر تحميل سجل كتب التفسير');
    }
    _editionsCache = editions;
    return editions;
  }

  @override
  Future<TafsirModel> getTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final memoryKey = '$editionId/$surahNumber:$ayahNumber';
    final inMemory = _memoryCache[memoryKey];
    if (inMemory != null) return inMemory;

    // الذاكرة الدائمة — تتيح القراءة دون اتصال لما سبق تحميله
    final cache = _cache;
    final persistentKey = _cacheKey(editionId, surahNumber, ayahNumber);
    if (cache != null) {
      try {
        final stored = await cache.read(persistentKey);
        if (stored != null) {
          final tafsir =
              TafsirModel.fromJson((stored as Map).cast<String, dynamic>());
          _memoryCache[memoryKey] = tafsir;
          return tafsir;
        }
      } catch (_) {
        // ذاكرة تالفة — تجاهل وتابع الجلب
      }
    }

    TafsirUnavailableException? unavailable;
    for (final remote in _remotes) {
      if (!remote.supportsEdition(editionId)) continue;
      try {
        final tafsir = await remote
            .fetchTafsir(
              editionId: editionId,
              surahNumber: surahNumber,
              ayahNumber: ayahNumber,
            )
            .timeout(remoteTimeout);
        _memoryCache[memoryKey] = tafsir;
        await cache?.write(persistentKey, tafsir.toJson(), ttl: cacheTtl);
        return tafsir;
      } on TafsirUnavailableException catch (e) {
        unavailable = e;
      } catch (_) {
        // خطأ شبكة — جرّب المصدر التالي ثم المحلي
      }
    }

    try {
      final tafsir = await _local.fetchTafsir(
        editionId: editionId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
      _memoryCache[memoryKey] = tafsir;
      return tafsir;
    } on TafsirUnavailableException {
      // إن كان أحد المصادر البعيدة قد رفض الطلب لعدم دعم الكتاب،
      // فرسالته أدق من رسالة غياب الملفات المحلية
      throw unavailable ??
          TafsirUnavailableException(
            'التفسير غير متاح حالياً للآية $surahNumber:$ayahNumber — '
            'تحقق من الاتصال بالإنترنت',
          );
    }
  }

  @override
  Future<List<TafsirModel>> searchTafsir(String query) async {
    if (query.trim().isEmpty) return const [];
    // البحث النصي متاح حالياً عبر النصوص المضمَّنة محلياً فقط؛
    // المصادر البعيدة لا توفر بحثاً في التفسير
    return _local.searchTafsir(query);
  }
}
