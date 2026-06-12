import 'package:flutter_test/flutter_test.dart';

import 'package:deenhub/data/datasources/local_quran_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalQuranDataSource dataSource;

  setUp(() {
    dataSource = LocalQuranDataSource();
  });

  test('fetchSurahs returns all 114 surahs with source info', () async {
    final surahs = await dataSource.fetchSurahs();

    expect(surahs, hasLength(114));
    expect(surahs.first.number, 1);
    expect(surahs.first.ayahCount, 7);
    expect(surahs.first.revelationPlace, 'مكية');
    expect(surahs.first.source.sourceName, isNotEmpty);
    expect(surahs.first.source.sourceUrl, isNotNull);
  });

  test('fetchAyahs returns ayahs with position and source fields', () async {
    final ayahs = await dataSource.fetchAyahs(1);

    expect(ayahs, hasLength(7));
    final first = ayahs.first;
    expect(first.surahNumber, 1);
    expect(first.ayahNumber, 1);
    expect(first.textArabic, isNotEmpty);
    expect(first.juz, 1);
    expect(first.page, 1);
    expect(first.sourceName, isNotEmpty);
    expect(first.sourceUrl, isNotNull);
  });

  test('basmala is stripped from first ayah of surah 2 but kept in surah 1',
      () async {
    final basmala = await dataSource.fetchBasmala();
    final fatiha = await dataSource.fetchAyahs(1);
    final baqarah = await dataSource.fetchAyahs(2);

    expect(basmala, contains('بِسْمِ'));
    expect(fatiha.first.textArabic, basmala);
    expect(baqarah.first.textArabic, isNot(contains('بِسْمِ')));
    expect(baqarah, hasLength(286));
  });

  test('searchAyahs finds ayahs regardless of diacritics', () async {
    // البحث بدون تشكيل يجب أن يطابق النص المشكَّل
    final results = await dataSource.searchAyahs('قل هو الله احد');

    expect(results, isNotEmpty);
    expect(
      results.any((a) => a.surahNumber == 112 && a.ayahNumber == 1),
      isTrue,
    );
  });

  test('normalizeArabic strips diacritics and unifies letter forms', () {
    expect(
      LocalQuranDataSource.normalizeArabic('قُلْ هُوَ ٱللَّهُ أَحَدٌ'),
      'قل هو الله احد',
    );
  });
}
