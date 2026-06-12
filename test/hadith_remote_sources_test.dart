import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:deenhub/data/datasources/dorar_hadith_data_source.dart';
import 'package:deenhub/data/datasources/hadith_data_source.dart';
import 'package:deenhub/data/datasources/remote_hadith_data_source.dart';
import 'package:deenhub/data/datasources/sunnah_com_hadith_data_source.dart';
import 'package:deenhub/services/api_client.dart';

http.Response _json(Object body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// التحقق من كل مصدر حديث بعيد: تحليل الاستجابات بصيغها الحقيقية
/// الموثقة، الإسناد الكامل — دون شبكة فعلية.
void main() {
  group('RemoteHadithDataSource (HadeethEnc.com)', () {
    RemoteHadithDataSource buildSource(MockClient client) {
      return RemoteHadithDataSource(
        client: ApiClient(
          baseUrl: 'https://hadeethenc.com/api/v1',
          client: client,
        ),
      );
    }

    test('fetchBooks parses root categories', () async {
      final source = buildSource(MockClient((request) async {
        expect(request.url.path, '/api/v1/categories/roots/');
        expect(request.url.queryParameters['language'], 'ar');
        return _json([
          {'id': '2', 'title': 'الحديث وعلومه', 'hadeeths_count': '16',
              'parent_id': null},
          {'id': '3', 'title': 'العقيدة', 'hadeeths_count': '725',
              'parent_id': null},
        ]);
      }));

      final books = await source.fetchBooks();
      expect(books, hasLength(2));
      expect(books.first.title, 'الحديث وعلومه');
      expect(books.first.hadithCount, 16);
      expect(books.first.source.sourceUrl, 'https://hadeethenc.com');
    });

    test('fetchChapters filters the category tree by parent', () async {
      final source = buildSource(MockClient((request) async {
        return _json([
          {'id': '43', 'title': 'مصطلح الحديث', 'hadeeths_count': '4',
              'parent_id': '2'},
          {'id': '59', 'title': 'الإيمان بالله', 'hadeeths_count': '120',
              'parent_id': '3'},
        ]);
      }));

      final chapters = await source.fetchChapters('2');
      expect(chapters, hasLength(1));
      expect(chapters.first.title, 'مصطلح الحديث');
      expect(chapters.first.bookId, '2');
    });

    test('fetchHadith merges Arabic and English with full attribution',
        () async {
      final source = buildSource(MockClient((request) async {
        final lang = request.url.queryParameters['language'];
        expect(request.url.path, '/api/v1/hadeeths/one/');
        if (lang == 'ar') {
          return _json({
            'id': '2962',
            'title': 'أول ما يقضى بين الناس',
            'hadeeth': 'نص الحديث العربي',
            'hadeeth_intro': 'عَنْ عَبْدِ اللهِ بنِ مَسْعُودٍ رضي الله عنه قَالَ:',
            'attribution': 'متفق عليه',
            'grade': 'صحيح',
            'explanation': 'الشرح...',
            'translations': ['ar', 'en'],
            'reference': 'صحيح البخاري (6864)',
          });
        }
        return _json({'id': '2962', 'hadeeth': 'English hadith text'});
      }));

      final hadith = await source.fetchHadith('2962');
      expect(hadith.textArabic, 'نص الحديث العربي');
      expect(hadith.textEnglish, 'English hadith text');
      // الراوي مستخرج من المقدمة دون «قَالَ:» الختامية
      expect(hadith.narrator, 'عَنْ عَبْدِ اللهِ بنِ مَسْعُودٍ رضي الله عنه');
      expect(hadith.attribution, 'متفق عليه');
      expect(hadith.grade, 'صحيح');
      expect(hadith.reference, 'صحيح البخاري (6864)');
      expect(hadith.sourceUrl,
          'https://hadeethenc.com/ar/browse/hadith/2962');
    });

    test('search is unavailable from HadeethEnc', () {
      final source = buildSource(MockClient((_) async => _json({})));
      expect(
        () => source.searchHadiths('x'),
        throwsA(isA<HadithUnavailableException>()),
      );
    });
  });

  group('SunnahComHadithDataSource', () {
    test('without API key: not configured and throws', () {
      final source = SunnahComHadithDataSource(
        client: ApiClient(
          baseUrl: 'https://api.sunnah.com/v1',
          client: MockClient((_) async {
            fail('يجب ألا يُرسل طلب دون مفتاح');
          }),
        ),
        apiKey: '',
      );
      expect(source.isConfigured, isFalse);
      expect(
        () => source.fetchBooks(),
        throwsA(isA<HadithUnavailableException>()),
      );
    });

    test('with API key: parses collections and hadith with grades',
        () async {
      final source = SunnahComHadithDataSource(
        apiKey: 'test-key',
        client: ApiClient(
          baseUrl: 'https://api.sunnah.com/v1',
          client: MockClient((request) async {
            expect(request.headers['X-API-Key'], 'test-key');
            if (request.url.path == '/v1/collections') {
              return _json({
                'data': [
                  {
                    'name': 'bukhari',
                    'totalAvailableHadith': 7277,
                    'collection': [
                      {'lang': 'en', 'title': 'Sahih al-Bukhari'},
                      {'lang': 'ar', 'title': 'صحيح البخاري'},
                    ],
                  }
                ]
              });
            }
            // /v1/collections/bukhari/hadiths/1
            return _json({
              'hadithNumber': '1',
              'hadith': [
                {
                  'lang': 'en',
                  'chapterTitle': 'Narrated Umar bin Al-Khattab',
                  'body': '<p>Actions are by intentions.</p>',
                  'grades': [
                    {'graded_by': '', 'grade': 'Sahih'}
                  ],
                },
                {
                  'lang': 'ar',
                  'body': '<p>إنما الأعمال بالنيات</p>',
                  'grades': [],
                },
              ],
            });
          }),
        ),
      );

      expect(source.isConfigured, isTrue);
      final books = await source.fetchBooks();
      expect(books.single.id, 'bukhari');
      expect(books.single.title, 'صحيح البخاري');
      expect(books.single.titleEnglish, 'Sahih al-Bukhari');
      expect(books.single.hadithCount, 7277);

      final hadith = await source.fetchHadith('bukhari@1');
      expect(hadith.textArabic, 'إنما الأعمال بالنيات');
      expect(hadith.textEnglish, 'Actions are by intentions.');
      expect(hadith.grade, 'Sahih');
      expect(hadith.sourceName, 'Sunnah.com');
      expect(hadith.sourceUrl, 'https://sunnah.com/bukhari:1');
    });
  });

  group('DorarHadithDataSource (dorar.net)', () {
    test('parseResults extracts text, narrator, muhaddith, book and grade',
        () {
      // الصيغة الفعلية لنتائج dorar_api.json كما توثقها الدرر السنية
      const html = '<div class="hadith">'
          'إنما الأعمالُ بالنياتِ وإنما لكلِّ امرئٍ ما نوى'
          '</div><div class="hadith-info">'
          'الراوي: <a href="">عمر بن الخطاب</a> | '
          'المحدث: <a href="">البخاري</a> | '
          'المصدر: <a href="">صحيح البخاري</a>\n'
          'الصفحة أو الرقم: 1 | '
          'خلاصة حكم المحدث: [صحيح]</div>';

      final results = DorarHadithDataSource.parseResults(html);
      expect(results, hasLength(1));
      final result = results.single;
      expect(result.text, contains('إنما الأعمالُ بالنياتِ'));
      expect(result.narrator, 'عمر بن الخطاب');
      expect(result.muhaddith, 'البخاري');
      expect(result.bookName, 'صحيح البخاري');
      expect(result.hadithNumber, '1');
      expect(result.grade, '[صحيح]');
      expect(result.source.sourceName, contains('الدرر السنية'));
      expect(result.source.sourceUrl, contains('dorar.net'));
    });

    test('searchHadiths calls dorar_api.json and parses the payload',
        () async {
      final source = DorarHadithDataSource(
        client: ApiClient(
          baseUrl: 'https://dorar.net',
          client: MockClient((request) async {
            expect(request.url.path, '/dorar_api.json');
            expect(request.url.queryParameters['skey'], 'النيات');
            return _json({
              'ahadith': {
                'result': '<div class="hadith">حديث النية</div>'
                    '<div class="hadith-info">الراوي: عمر | المحدث: مسلم | '
                    'المصدر: صحيح مسلم\nالصفحة أو الرقم: 1907 | '
                    'خلاصة حكم المحدث: صحيح</div>',
              }
            });
          }),
        ),
      );

      final results = await source.searchHadiths('النيات');
      expect(results, hasLength(1));
      expect(results.single.grade, 'صحيح');
      expect(results.single.toInlineHadith().textArabic, 'حديث النية');
    });

    test('browsing is unavailable from Dorar', () {
      final source = DorarHadithDataSource(
        client: ApiClient(
            baseUrl: 'https://dorar.net',
            client: MockClient((_) async => _json({}))),
      );
      expect(() => source.fetchBooks(),
          throwsA(isA<HadithUnavailableException>()));
      expect(() => source.fetchHadith('1'),
          throwsA(isA<HadithUnavailableException>()));
    });
  });
}
