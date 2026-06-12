import 'package:flutter_test/flutter_test.dart';

import 'package:deenhub/core/utils/html_text.dart';
import 'package:deenhub/data/datasources/local_tafsir_data_source.dart';
import 'package:deenhub/data/datasources/tafsir_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalTafsirDataSource dataSource;

  setUp(() {
    dataSource = LocalTafsirDataSource();
  });

  test('fetchEditions returns the five supported editions, all available',
      () async {
    final editions = await dataSource.fetchEditions();

    expect(editions.map((e) => e.id),
        ['saadi', 'ibn-kathir', 'tabari', 'qurtubi', 'jalalayn']);
    // الخمسة كلها متاحة: أربعة عبر Quran.com والجلالين عبر AlQuran Cloud
    expect(editions.every((e) => e.available), isTrue);
    final jalalayn = editions.last;
    expect(jalalayn.remoteId, isNull); // ليس لدى Quran.com
    // السعدي يملك بيانات محلية معلنة في السجل
    expect(editions.first.localSurahs, [1, 112, 113, 114]);
    for (final edition in editions) {
      expect(edition.scholar, isNotEmpty);
      expect(edition.nameArabic, isNotEmpty);
    }
  });

  test('searchTafsir finds passages in the offline corpus ignoring '
      'diacritics', () async {
    // «الأحدية» وردت في تفسير السعدي للآية ١١٢:١ — نبحث دون تشكيل
    final results = await dataSource.searchTafsir('الاحدية');

    expect(results, isNotEmpty);
    final hit = results.first;
    expect(hit.editionId, 'saadi');
    expect(hit.surahNumber, 112);
    expect(hit.ayahNumber, 1);
    expect(hit.sourceName, isNotEmpty);
  });

  test('fetchTafsir returns Saadi text with full attribution', () async {
    final tafsir = await dataSource.fetchTafsir(
      editionId: 'saadi',
      surahNumber: 112,
      ayahNumber: 1,
    );

    expect(tafsir.text, isNotEmpty);
    expect(tafsir.text, isNot(contains('<'))); // لا HTML
    expect(tafsir.editionName, 'تفسير السعدي');
    expect(tafsir.scholar, contains('السعدي'));
    expect(tafsir.sourceName, isNotEmpty);
    expect(tafsir.reference, isNotEmpty);
    expect(tafsir.sourceUrl, isNotNull);
  });

  test('fetchTafsir throws TafsirUnavailableException for missing data',
      () async {
    // سورة غير مضمَّنة محلياً
    expect(
      () => dataSource.fetchTafsir(
        editionId: 'saadi',
        surahNumber: 50,
        ayahNumber: 1,
      ),
      throwsA(isA<TafsirUnavailableException>()),
    );
    // كتاب غير معروف
    expect(
      () => dataSource.fetchTafsir(
        editionId: 'unknown',
        surahNumber: 1,
        ayahNumber: 1,
      ),
      throwsA(isA<TafsirUnavailableException>()),
    );
  });

  test('stripHtml removes tags and decodes entities', () {
    expect(
      stripHtml('<p>أي <span class="x">{ قُلْ }</span> قولًا&nbsp;جازمًا</p>'),
      'أي { قُلْ } قولًا جازمًا',
    );
    expect(stripHtml('سطر<br>جديد'), 'سطر\nجديد');
    expect(stripHtml('&laquo;نص&raquo; &amp; آخر'), '«نص» & آخر');
  });
}
