import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/data/datasources/hadith_data_source.dart';
import 'package:deenhub/data/repositories/hadith_repository_impl.dart';
import 'package:deenhub/models/content_source.dart';
import 'package:deenhub/models/hadith_models.dart';
import 'package:deenhub/services/cache_service.dart';

HadithModel _hadith(String id, {String text = 'نص الحديث'}) {
  return HadithModel(
    id: id,
    textArabic: text,
    grade: 'صحيح',
    attribution: 'متفق عليه',
    source: ContentSource(
      sourceName: 'مصدر اختباري',
      reference: 'حديث $id',
      sourceUrl: 'https://example.com',
      lastUpdated: DateTime(2026),
    ),
  );
}

/// مصدر وهمي قابل للتهيئة.
class FakeHadithSource implements HadithDataSource {
  FakeHadithSource({
    this.configured = true,
    this.failWithNetworkError = false,
    this.searchResults = const [],
  });

  @override
  bool get isConfigured => configured;

  bool configured;
  bool failWithNetworkError;
  List<HadithSearchResultModel> searchResults;
  int bookCalls = 0;
  int hadithCalls = 0;
  int searchCalls = 0;

  void _maybeFail() {
    if (failWithNetworkError) throw Exception('network down');
  }

  @override
  Future<List<HadithBookModel>> fetchBooks() async {
    bookCalls++;
    _maybeFail();
    return [
      HadithBookModel(
          id: 'b1', title: 'كتاب', source: _hadith('x').source),
    ];
  }

  @override
  Future<List<HadithChapterModel>> fetchChapters(String bookId) async {
    _maybeFail();
    return [
      HadithChapterModel(
          id: 'c1', bookId: bookId, title: 'باب',
          source: _hadith('x').source),
    ];
  }

  @override
  Future<List<HadithModel>> fetchHadiths(
    String chapterId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    _maybeFail();
    return [_hadith('h1')];
  }

  @override
  Future<HadithModel> fetchHadith(String hadithId) async {
    hadithCalls++;
    _maybeFail();
    return _hadith(hadithId);
  }

  @override
  Future<List<HadithSearchResultModel>> searchHadiths(String query) async {
    searchCalls++;
    _maybeFail();
    if (searchResults.isEmpty) {
      throw const HadithUnavailableException('لا بحث هنا');
    }
    return searchResults;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('skips unconfigured remotes (Sunnah.com without key)', () async {
    final sunnah = FakeHadithSource(configured: false);
    final hadeethEnc = FakeHadithSource();
    final local = FakeHadithSource();

    final repo = HadithRepositoryImpl(
      remotes: [sunnah, hadeethEnc],
      local: local,
    );

    await repo.getBooks();
    expect(sunnah.bookCalls, 0);
    expect(hadeethEnc.bookCalls, 1);
    expect(local.bookCalls, 0);
  });

  test('falls back to local when remotes fail', () async {
    final remote = FakeHadithSource(failWithNetworkError: true);
    final local = FakeHadithSource();

    final repo = HadithRepositoryImpl(remotes: [remote], local: local);
    final books = await repo.getBooks();
    expect(books, hasLength(1));
    expect(local.bookCalls, 1);
  });

  test('caches opened hadith persistently and serves it offline', () async {
    final cache = SharedPrefsCacheService();
    final remote = FakeHadithSource();
    final local = FakeHadithSource(failWithNetworkError: true);

    final repo1 = HadithRepositoryImpl(
        remotes: [remote], local: local, cache: cache);
    final fetched = await repo1.getHadith('2962');
    expect(fetched.grade, 'صحيح');
    expect(remote.hadithCalls, 1);

    // جلسة جديدة والشبكة مقطوعة: يُقرأ الحديث من الذاكرة الدائمة
    remote.failWithNetworkError = true;
    final repo2 = HadithRepositoryImpl(
        remotes: [remote], local: local, cache: cache);
    final cached = await repo2.getHadith('2962');
    expect(cached.textArabic, 'نص الحديث');
    expect(cached.attribution, 'متفق عليه');
    expect(remote.hadithCalls, 1); // لم يُرسل طلب جديد
  });

  test('search prefers remote (Dorar) then falls back to local', () async {
    final dorar = FakeHadithSource(searchResults: [
      HadithSearchResultModel(
        text: 'نتيجة الدرر',
        grade: 'صحيح',
        source: _hadith('x').source,
      ),
    ]);
    final local = FakeHadithSource(searchResults: [
      HadithSearchResultModel(
        hadithId: 'l1',
        text: 'نتيجة محلية',
        source: _hadith('x').source,
      ),
    ]);

    final repo = HadithRepositoryImpl(
      searchRemotes: [dorar],
      local: local,
    );
    final remoteResults = await repo.searchHadiths('النيات');
    expect(remoteResults.single.text, 'نتيجة الدرر');
    expect(local.searchCalls, 0);

    // انقطاع الدرر → البحث المحلي
    dorar.failWithNetworkError = true;
    final localResults = await repo.searchHadiths('النيات');
    expect(localResults.single.text, 'نتيجة محلية');

    expect(await repo.searchHadiths('  '), isEmpty);
  });

  test('throws HadithUnavailableException when nothing can serve', () {
    final local = FakeHadithSource(failWithNetworkError: false);
    final repo = HadithRepositoryImpl(
      local: _UnavailableLocal(),
    );
    expect(
      () => repo.getHadith('missing'),
      throwsA(isA<HadithUnavailableException>()),
    );
    expect(local.hadithCalls, 0);
  });
}

class _UnavailableLocal extends FakeHadithSource {
  @override
  Future<HadithModel> fetchHadith(String hadithId) async {
    throw const HadithUnavailableException('غير متاح');
  }
}
