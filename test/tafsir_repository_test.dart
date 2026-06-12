import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/data/datasources/tafsir_data_source.dart';
import 'package:deenhub/data/repositories/tafsir_repository_impl.dart';
import 'package:deenhub/models/content_source.dart';
import 'package:deenhub/models/tafsir_models.dart';
import 'package:deenhub/services/cache_service.dart';

TafsirModel _model(String editionId, {String text = 'نص التفسير'}) {
  return TafsirModel(
    editionId: editionId,
    editionName: 'كتاب $editionId',
    scholar: 'العالِم',
    surahNumber: 112,
    ayahNumber: 1,
    text: text,
    source: ContentSource(
      sourceName: 'مصدر $editionId',
      reference: '$editionId — 112:1',
      sourceUrl: 'https://example.com',
      lastUpdated: DateTime(2026),
    ),
  );
}

/// مصدر وهمي قابل للتهيئة: يخدم كتباً محددة وقد يفشل بخطأ شبكة.
class FakeTafsirSource implements TafsirDataSource {
  FakeTafsirSource({
    required this.editions,
    this.failWithNetworkError = false,
  });

  final Set<String> editions;
  bool failWithNetworkError;
  int fetchCalls = 0;

  @override
  bool supportsEdition(String editionId) => editions.contains(editionId);

  @override
  Future<List<TafsirEditionModel>> fetchEditions() async => [];

  @override
  Future<TafsirModel> fetchTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    fetchCalls++;
    if (failWithNetworkError) {
      throw Exception('network down');
    }
    if (!editions.contains(editionId)) {
      throw TafsirUnavailableException('غير مدعوم: $editionId');
    }
    return _model(editionId);
  }

  @override
  Future<List<TafsirModel>> searchTafsir(String query) async {
    return [_model(editions.first, text: 'نتيجة بحث عن $query')];
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fetches from the first remote that supports the edition', () async {
    final quranCom = FakeTafsirSource(editions: {'saadi'});
    final alQuranCloud = FakeTafsirSource(editions: {'jalalayn'});
    final local = FakeTafsirSource(editions: {});

    final repo = TafsirRepositoryImpl(
      remotes: [quranCom, alQuranCloud],
      local: local,
    );

    final jalalayn = await repo.getTafsir(
        editionId: 'jalalayn', surahNumber: 112, ayahNumber: 1);
    expect(jalalayn.editionId, 'jalalayn');
    // مصدر Quran.com تخطّى الكتاب غير المدعوم دون طلب
    expect(quranCom.fetchCalls, 0);
    expect(alQuranCloud.fetchCalls, 1);
  });

  test('falls back to local on network failure', () async {
    final remote =
        FakeTafsirSource(editions: {'saadi'}, failWithNetworkError: true);
    final local = FakeTafsirSource(editions: {'saadi'});

    final repo = TafsirRepositoryImpl(remotes: [remote], local: local);
    final tafsir = await repo.getTafsir(
        editionId: 'saadi', surahNumber: 112, ayahNumber: 1);
    expect(tafsir.editionId, 'saadi');
    expect(local.fetchCalls, 1);
  });

  test('writes remote results to persistent cache and reads them offline',
      () async {
    final cache = SharedPrefsCacheService();
    final remote = FakeTafsirSource(editions: {'tabari'});
    final local = FakeTafsirSource(editions: {});

    final repo1 = TafsirRepositoryImpl(
        remotes: [remote], local: local, cache: cache);
    await repo1.getTafsir(
        editionId: 'tabari', surahNumber: 112, ayahNumber: 1);
    expect(remote.fetchCalls, 1);

    // جلسة جديدة، الشبكة مقطوعة: يُقرأ من الذاكرة الدائمة
    remote.failWithNetworkError = true;
    final repo2 = TafsirRepositoryImpl(
        remotes: [remote], local: local, cache: cache);
    final cached = await repo2.getTafsir(
        editionId: 'tabari', surahNumber: 112, ayahNumber: 1);
    expect(cached.text, 'نص التفسير');
    expect(cached.sourceName, 'مصدر tabari');
    expect(remote.fetchCalls, 1); // لم يُرسل طلب جديد
  });

  test('throws TafsirUnavailableException when nothing can serve', () {
    final remote = FakeTafsirSource(editions: {'saadi'});
    final local = FakeTafsirSource(editions: {});

    final repo = TafsirRepositoryImpl(remotes: [remote], local: local);
    expect(
      () => repo.getTafsir(
          editionId: 'jalalayn', surahNumber: 50, ayahNumber: 1),
      throwsA(isA<TafsirUnavailableException>()),
    );
  });

  test('searchTafsir delegates to the local corpus', () async {
    final local = FakeTafsirSource(editions: {'saadi'});
    final repo = TafsirRepositoryImpl(local: local);

    final results = await repo.searchTafsir('الرحمن');
    expect(results, hasLength(1));
    expect(results.first.text, contains('الرحمن'));
    expect(await repo.searchTafsir('  '), isEmpty);
  });
}
