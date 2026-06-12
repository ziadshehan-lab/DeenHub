import 'dart:async';

import '../../models/tafsir_models.dart';
import '../datasources/tafsir_data_source.dart';
import 'tafsir_repository.dart';

/// تطبيق مستودع التفسير: نص التفسير يُطلب من المصدر البعيد أولاً
/// (واجهة Quran.com الرسمية) مع العودة للمصدر المحلي عند الفشل.
///
/// سجل الكتب يُقرأ من السجل المحلي المضمَّن لأنه القائمة المعتمدة
/// الكاملة (تشمل الكتب التي لم تتوفر مصادرها بعد مثل الجلالين)،
/// ويُستكمل من المصدر البعيد عند غيابه.
class TafsirRepositoryImpl implements TafsirRepository {
  TafsirRepositoryImpl({
    TafsirDataSource? remote,
    required TafsirDataSource local,
    this.remoteTimeout = const Duration(seconds: 8),
  })  : _remote = remote,
        _local = local;

  final TafsirDataSource? _remote;
  final TafsirDataSource _local;
  final Duration remoteTimeout;

  List<TafsirEditionModel>? _editionsCache;
  final Map<String, TafsirModel> _tafsirCache = {};

  @override
  Future<List<TafsirEditionModel>> getEditions() async {
    final cached = _editionsCache;
    if (cached != null) return cached;

    List<TafsirEditionModel> editions;
    try {
      editions = await _local.fetchEditions();
    } catch (_) {
      final remote = _remote;
      if (remote == null) rethrow;
      editions = await remote.fetchEditions().timeout(remoteTimeout);
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
    final cacheKey = '$editionId/$surahNumber:$ayahNumber';
    final cached = _tafsirCache[cacheKey];
    if (cached != null) return cached;

    TafsirModel tafsir;
    final remote = _remote;
    if (remote != null) {
      try {
        tafsir = await remote
            .fetchTafsir(
              editionId: editionId,
              surahNumber: surahNumber,
              ayahNumber: ayahNumber,
            )
            .timeout(remoteTimeout);
      } on TafsirUnavailableException {
        rethrow; // الكتاب غير مدعوم أصلاً — لا معنى لمحاولة المحلي بعيداً عن الانقطاع
      } catch (_) {
        // انقطاع اتصال أو خطأ شبكة: محاولة المصدر المحلي
        tafsir = await _local.fetchTafsir(
          editionId: editionId,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        );
      }
    } else {
      tafsir = await _local.fetchTafsir(
        editionId: editionId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
    }
    _tafsirCache[cacheKey] = tafsir;
    return tafsir;
  }
}
