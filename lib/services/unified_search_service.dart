import 'dart:async';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/adhkar_repository.dart';
import '../data/repositories/hadith_repository.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/quran_repository.dart';
import '../data/repositories/tafsir_repository.dart';
import '../models/search_result_model.dart';

/// خدمة البحث الموحد: تبحث في كل وحدات المحتوى بالتوازي (القرآن،
/// التفسير، الحديث، الأذكار، الأسماء الحسنى، المكتبة) مع عزل أخطاء
/// كل وحدة — فشل وحدة لا يُسقط بقية النتائج.
///
/// (مواقيت الصلاة والقبلة بيانات محسوبة لا نص يُبحث فيه.)
class UnifiedSearchService {
  UnifiedSearchService({
    required this.quranRepository,
    required this.tafsirRepository,
    required this.hadithRepository,
    required this.adhkarRepository,
    required this.libraryRepository,
    this.perModuleLimit = 10,
  });

  final QuranRepository quranRepository;
  final TafsirRepository tafsirRepository;
  final HadithRepository hadithRepository;
  final AdhkarRepository adhkarRepository;
  final LibraryRepository libraryRepository;

  /// الحد الأقصى للنتائج المعروضة لكل وحدة.
  final int perModuleLimit;

  Map<int, String>? _surahNames;

  /// البحث في الوحدات المحددة (أو كلها إن كانت [types] فارغة)،
  /// وإعادة النتائج مجمعةً بالنوع.
  Future<Map<SearchResultType, List<SearchResultModel>>> search(
    String query, {
    Set<SearchResultType> types = const {},
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const {};

    bool wanted(SearchResultType type) =>
        types.isEmpty || types.contains(type);

    final searches = <SearchResultType, Future<List<SearchResultModel>>>{
      if (wanted(SearchResultType.quran)) ...{
        SearchResultType.quran: _searchQuran(trimmed),
      },
      if (wanted(SearchResultType.tafsir)) ...{
        SearchResultType.tafsir: _searchTafsir(trimmed),
      },
      if (wanted(SearchResultType.hadith)) ...{
        SearchResultType.hadith: _searchHadith(trimmed),
      },
      if (wanted(SearchResultType.adhkar)) ...{
        SearchResultType.adhkar: _searchAdhkar(trimmed),
      },
      if (wanted(SearchResultType.names)) ...{
        SearchResultType.names: _searchNames(trimmed),
      },
      if (wanted(SearchResultType.library)) ...{
        SearchResultType.library: _searchLibrary(trimmed),
      },
    };

    final grouped = <SearchResultType, List<SearchResultModel>>{};
    await Future.wait(searches.entries.map((entry) async {
      try {
        final results = await entry.value;
        if (results.isNotEmpty) {
          grouped[entry.key] = results.take(perModuleLimit).toList();
        }
      } catch (_) {
        // عزل الفشل: وحدة معطلة لا تمنع بقية النتائج
      }
    }));
    return grouped;
  }

  Future<String> _surahName(int number) async {
    if (_surahNames == null) {
      try {
        final surahs = await quranRepository.getSurahs();
        _surahNames = {for (final s in surahs) s.number: s.nameArabic};
      } catch (_) {
        _surahNames = {};
      }
    }
    return _surahNames![number] ??
        '${AppStrings.surahLabel} ${toArabicDigits(number)}';
  }

  Future<List<SearchResultModel>> _searchQuran(String query) async {
    final ayahs = await quranRepository.searchAyahs(query);
    final results = <SearchResultModel>[];
    for (final ayah in ayahs.take(perModuleLimit)) {
      final surahName = await _surahName(ayah.surahNumber);
      results.add(SearchResultModel(
        id: ayah.verseKey,
        title:
            '$surahName — ${AppStrings.ayahLabel} ${toArabicDigits(ayah.ayahNumber)}',
        snippet: ayah.textArabic,
        type: SearchResultType.quran,
        sourceName: ayah.sourceName,
        reference: ayah.verseKey,
        route: AppRoutes.surahDetail,
        metadata: {
          'surahNumber': '${ayah.surahNumber}',
          'ayahNumber': '${ayah.ayahNumber}',
          'surahName': surahName,
        },
      ));
    }
    return results;
  }

  Future<List<SearchResultModel>> _searchTafsir(String query) async {
    final entries = await tafsirRepository.searchTafsir(query);
    final results = <SearchResultModel>[];
    for (final tafsir in entries.take(perModuleLimit)) {
      final surahName = await _surahName(tafsir.surahNumber);
      results.add(SearchResultModel(
        id: '${tafsir.editionId}/${tafsir.surahNumber}:${tafsir.ayahNumber}',
        title:
            '${tafsir.editionName} — $surahName ${toArabicDigits(tafsir.ayahNumber)}',
        snippet: tafsir.text,
        type: SearchResultType.tafsir,
        sourceName: tafsir.sourceName,
        reference: tafsir.reference,
        route: AppRoutes.tafsirDetail,
        metadata: {
          'editionId': tafsir.editionId,
          'surahNumber': '${tafsir.surahNumber}',
          'ayahNumber': '${tafsir.ayahNumber}',
          'surahName': surahName,
        },
      ));
    }
    return results;
  }

  Future<List<SearchResultModel>> _searchHadith(String query) async {
    final hadiths = await hadithRepository.searchHadiths(query);
    return hadiths.take(perModuleLimit).map((result) {
      final details = [
        if (result.narrator != null)
          '${AppStrings.narratorLabel}: ${result.narrator}',
        if (result.grade != null)
          '${AppStrings.gradeLabel}: ${result.grade}',
      ].join(' • ');
      return SearchResultModel(
        id: result.hadithId ?? result.text.hashCode.toString(),
        title: details.isEmpty ? AppStrings.hadithLabel : details,
        snippet: result.text,
        type: SearchResultType.hadith,
        sourceName: result.source.sourceName,
        reference: result.bookName ?? result.source.reference,
        route: AppRoutes.hadithDetail,
        metadata: {
          if (result.hadithId != null) 'hadithId': result.hadithId!,
          'text': result.text,
          if (result.narrator != null) 'narrator': result.narrator!,
          if (result.grade != null) 'grade': result.grade!,
          if (result.bookName != null) 'bookName': result.bookName!,
        },
      );
    }).toList();
  }

  Future<List<SearchResultModel>> _searchAdhkar(String query) async {
    final adhkar = await adhkarRepository.searchAdhkar(query);
    final categories = await adhkarRepository.getCategories();
    final titles = {for (final c in categories) c.id: c.title};
    return adhkar.take(perModuleLimit).map((dhikr) {
      return SearchResultModel(
        id: dhikr.id,
        title: dhikr.chapterTitle ?? titles[dhikr.categoryId] ?? '',
        snippet: dhikr.text,
        type: SearchResultType.adhkar,
        sourceName: dhikr.sourceName,
        reference: dhikr.reference,
        route: AppRoutes.adhkarList,
        metadata: {
          'categoryId': dhikr.categoryId,
          'categoryTitle': titles[dhikr.categoryId] ?? '',
        },
      );
    }).toList();
  }

  Future<List<SearchResultModel>> _searchNames(String query) async {
    final names = await adhkarRepository.searchNames(query);
    // استعلام فارغ يعيد القائمة كلها — لا يعنينا في البحث الموحد
    if (names.length == 99) return const [];
    return names.take(perModuleLimit).map((name) {
      return SearchResultModel(
        id: 'name-${name.number}',
        title: name.name,
        snippet: [
          if (name.transliteration != null) name.transliteration!,
          if (name.meaning != null) name.meaning!,
        ].join(' — '),
        type: SearchResultType.names,
        sourceName: name.source.sourceName,
        reference:
            '${AppStrings.nameNumberLabel} ${toArabicDigits(name.number)}',
        route: AppRoutes.namesOfAllah,
        metadata: {'number': '${name.number}'},
      );
    }).toList();
  }

  Future<List<SearchResultModel>> _searchLibrary(String query) async {
    final books = await libraryRepository.searchBooks(query);
    return books.take(perModuleLimit).map((book) {
      return SearchResultModel(
        id: book.id,
        title: book.title,
        snippet: [
          book.author,
          if (book.description != null) book.description!,
        ].join(' — '),
        type: SearchResultType.library,
        sourceName: book.sourceName,
        reference: book.url,
        route: AppRoutes.libraryBook,
        metadata: {'bookId': book.id},
      );
    }).toList();
  }
}
