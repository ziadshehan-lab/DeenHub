import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deenhub/core/routing/app_routes.dart';
import 'package:deenhub/data/datasources/local_adhkar_data_source.dart';
import 'package:deenhub/data/datasources/local_hadith_data_source.dart';
import 'package:deenhub/data/datasources/local_library_data_source.dart';
import 'package:deenhub/data/datasources/local_quran_data_source.dart';
import 'package:deenhub/data/datasources/local_tafsir_data_source.dart';
import 'package:deenhub/data/repositories/adhkar_repository_impl.dart';
import 'package:deenhub/data/repositories/hadith_repository_impl.dart';
import 'package:deenhub/data/repositories/library_repository_impl.dart';
import 'package:deenhub/data/repositories/quran_repository.dart';
import 'package:deenhub/data/repositories/quran_repository_impl.dart';
import 'package:deenhub/data/repositories/tafsir_repository_impl.dart';
import 'package:deenhub/models/quran_models.dart';
import 'package:deenhub/models/search_result_model.dart';
import 'package:deenhub/providers/search_provider.dart';
import 'package:deenhub/services/unified_search_service.dart';

UnifiedSearchService buildService({QuranRepository? quran}) {
  return UnifiedSearchService(
    quranRepository:
        quran ?? QuranRepositoryImpl(local: LocalQuranDataSource()),
    tafsirRepository: TafsirRepositoryImpl(local: LocalTafsirDataSource()),
    hadithRepository: HadithRepositoryImpl(local: LocalHadithDataSource()),
    adhkarRepository: AdhkarRepositoryImpl(local: LocalAdhkarDataSource()),
    libraryRepository:
        LibraryRepositoryImpl(local: LocalLibraryDataSource()),
  );
}

/// مستودع قرآن معطل — لاختبار عزل أخطاء الوحدات.
class _BrokenQuranRepository implements QuranRepository {
  @override
  Future<List<AyahModel>> getAyahs(int surahNumber) =>
      throw Exception('down');
  @override
  Future<AyahModel> getAyah(int surahNumber, int ayahNumber) =>
      throw Exception('down');
  @override
  Future<String> getBasmala() => throw Exception('down');
  @override
  Future<SurahModel> getSurah(int surahNumber) => throw Exception('down');
  @override
  Future<List<SurahModel>> getSurahs() => throw Exception('down');
  @override
  Future<List<AyahModel>> searchAyahs(String query) =>
      throw Exception('down');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnifiedSearchService', () {
    late UnifiedSearchService service;

    setUp(() {
      service = buildService();
    });

    test('finds Quran ayahs with navigation metadata', () async {
      final results = await service.search('قل هو الله احد');

      final quran = results[SearchResultType.quran]!;
      expect(quran, isNotEmpty);
      expect(quran.first.route, AppRoutes.surahDetail);
      expect(quran.first.metadata['surahNumber'], '112');
      expect(quran.first.title, contains('الآية'));
      expect(quran.first.sourceName, isNotEmpty);
    });

    test('finds tafsir passages', () async {
      final results = await service.search('الاحدية');

      final tafsir = results[SearchResultType.tafsir]!;
      expect(tafsir.first.route, AppRoutes.tafsirDetail);
      expect(tafsir.first.metadata['editionId'], 'saadi');
      expect(tafsir.first.metadata['surahNumber'], '112');
    });

    test('finds hadiths by text with id metadata', () async {
      final results = await service.search('بني الاسلام على خمس');

      final hadith = results[SearchResultType.hadith]!;
      expect(hadith.first.route, AppRoutes.hadithDetail);
      expect(hadith.first.metadata['hadithId'], '66512');
    });

    test('finds adhkar routed to their category', () async {
      final results = await service.search('الحمد لله الذي احيانا');

      final adhkar = results[SearchResultType.adhkar]!;
      expect(adhkar.first.route, AppRoutes.adhkarList);
      expect(adhkar.first.metadata['categoryId'], 'wake');
      expect(adhkar.first.sourceName, contains('حصن المسلم'));
    });

    test('finds Names of Allah by transliteration', () async {
      final results = await service.search('rahmaan');

      final names = results[SearchResultType.names]!;
      expect(names.single.metadata['number'], '1');
      expect(names.single.route, AppRoutes.namesOfAllah);
    });

    test('finds library books by author', () async {
      final results = await service.search('ابن الاثير');

      final books = results[SearchResultType.library]!;
      expect(books.single.metadata['bookId'], 'kamil-tarikh');
      expect(books.single.route, AppRoutes.libraryBook);
    });

    test('type filters restrict the searched modules', () async {
      final results = await service
          .search('البخاري', types: {SearchResultType.library});

      expect(results.keys, [SearchResultType.library]);
      expect(
        results[SearchResultType.library]!.map((r) => r.id),
        contains('sahih-bukhari'),
      );
    });

    test('a failing module does not break the others', () async {
      final broken = buildService(quran: _BrokenQuranRepository());
      final results = await broken.search('البخاري');

      expect(results.containsKey(SearchResultType.quran), isFalse);
      expect(results[SearchResultType.library], isNotEmpty);
    });

    test('empty query returns nothing', () async {
      expect(await service.search('   '), isEmpty);
    });
  });

  group('SearchProvider recent searches', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves, dedupes and caps recent searches; clearHistory wipes',
        () async {
      final provider = SearchProvider(service: buildService());

      await provider.search('البخاري');
      await provider.search('الرحمن');
      await provider.search('البخاري'); // تكرار — يصعد للمقدمة
      expect(provider.recentSearches, ['البخاري', 'الرحمن']);

      for (var i = 0; i < SearchProvider.maxRecent + 3; i++) {
        await provider.search('استعلام $i');
      }
      expect(provider.recentSearches, hasLength(SearchProvider.maxRecent));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(SearchProvider.prefKeyRecent),
          hasLength(SearchProvider.maxRecent));

      await provider.clearHistory();
      expect(provider.recentSearches, isEmpty);
      expect(prefs.getStringList(SearchProvider.prefKeyRecent), isNull);
    });
  });
}
