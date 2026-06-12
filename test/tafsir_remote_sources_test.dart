import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:deenhub/data/datasources/alquran_cloud_tafsir_data_source.dart';
import 'package:deenhub/data/datasources/remote_tafsir_data_source.dart';
import 'package:deenhub/data/datasources/tafsir_data_source.dart';
import 'package:deenhub/services/api_client.dart';

/// التحقق من كل مصدر تفسير بعيد: تحليل الاستجابات (بصيغها الحقيقية
/// الموثقة)، الإسناد الكامل، وتنظيف HTML — دون شبكة فعلية.
void main() {
  group('RemoteTafsirDataSource (Quran.com)', () {
    // الصيغة الفعلية لاستجابة /tafsirs/{id}/by_ayah/{key} كما وثقناها
    // من الواجهة الرسمية
    http.Response tafsirResponse(int resourceId, String slug) {
      return http.Response(
        jsonEncode({
          'tafsir': {
            'resource_id': resourceId,
            'resource_name': 'x',
            'slug': slug,
            'verses': {
              '112:1': {'id': 6222}
            },
            'text':
                '<p>أي <span class="arabic">{ قُلْ }</span> قولًا&nbsp;جازمًا</p>',
          }
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    RemoteTafsirDataSource buildSource(MockClient client) {
      return RemoteTafsirDataSource(
        client: ApiClient(
          baseUrl: 'https://api.quran.com/api/v4',
          client: client,
        ),
      );
    }

    test('supports exactly the four Quran.com editions', () {
      final source = buildSource(MockClient((_) async {
        return http.Response('{}', 200);
      }));
      expect(source.supportsEdition('saadi'), isTrue);
      expect(source.supportsEdition('ibn-kathir'), isTrue);
      expect(source.supportsEdition('tabari'), isTrue);
      expect(source.supportsEdition('qurtubi'), isTrue);
      expect(source.supportsEdition('jalalayn'), isFalse);
    });

    test('fetchTafsir parses every supported edition with attribution',
        () async {
      const expectedRemoteIds = {
        'saadi': 91,
        'ibn-kathir': 14,
        'tabari': 15,
        'qurtubi': 90,
      };
      final requestedPaths = <String>[];
      final source = buildSource(MockClient((request) async {
        requestedPaths.add(request.url.path);
        // المسار: /api/v4/tafsirs/{id}/by_ayah/{key}
        final id = int.parse(request.url.pathSegments[3]);
        return tafsirResponse(id, 'slug-$id');
      }));

      for (final entry in expectedRemoteIds.entries) {
        final tafsir = await source.fetchTafsir(
          editionId: entry.key,
          surahNumber: 112,
          ayahNumber: 1,
        );
        // المعرّف البعيد الصحيح لكل كتاب
        expect(
          requestedPaths.last,
          '/api/v4/tafsirs/${entry.value}/by_ayah/112:1',
        );
        // تنظيف HTML وفك الكيانات
        expect(tafsir.text, 'أي { قُلْ } قولًا جازمًا');
        // الإسناد الكامل
        expect(tafsir.editionName, isNotEmpty);
        expect(tafsir.scholar, isNotNull);
        expect(tafsir.sourceName, contains('Quran.com'));
        expect(tafsir.sourceUrl, 'https://quran.com');
        expect(tafsir.reference, contains('112:1'));
        expect(tafsir.surahNumber, 112);
        expect(tafsir.ayahNumber, 1);
      }
    });

    test('fetchEditions maps availability from the live registry', () async {
      final source = buildSource(MockClient((request) async {
        expect(request.url.path, '/api/v4/resources/tafsirs');
        return http.Response(
          jsonEncode({
            'tafsirs': [
              {'id': 14},
              {'id': 15},
              {'id': 90},
              {'id': 91},
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }));

      final editions = await source.fetchEditions();
      expect(editions, hasLength(4));
      expect(editions.every((e) => e.available), isTrue);
      expect(editions.every((e) => e.scholar.isNotEmpty), isTrue);
    });

    test('unsupported edition throws TafsirUnavailableException', () {
      final source = buildSource(MockClient((_) async {
        fail('يجب ألا يُرسل طلب لكتاب غير مدعوم');
      }));
      expect(
        () => source.fetchTafsir(
          editionId: 'jalalayn',
          surahNumber: 1,
          ayahNumber: 1,
        ),
        throwsA(isA<TafsirUnavailableException>()),
      );
    });
  });

  group('AlQuranCloudTafsirDataSource (Jalalayn)', () {
    AlQuranCloudTafsirDataSource buildSource(MockClient client) {
      return AlQuranCloudTafsirDataSource(
        client: ApiClient(
          baseUrl: 'https://api.alquran.cloud/v1',
          client: client,
        ),
      );
    }

    test('supports jalalayn only', () {
      final source = buildSource(MockClient((_) async {
        return http.Response('{}', 200);
      }));
      expect(source.supportsEdition('jalalayn'), isTrue);
      expect(source.supportsEdition('saadi'), isFalse);
    });

    test('fetchTafsir parses ar.jalalayn with attribution', () async {
      // الصيغة الفعلية لاستجابة /ayah/{key}/{edition} كما وثقناها
      final source = buildSource(MockClient((request) async {
        expect(request.url.path, '/v1/ayah/112:1/ar.jalalayn');
        return http.Response(
          jsonEncode({
            'code': 200,
            'status': 'OK',
            'data': {
              'number': 6222,
              'text':
                  'سئل النبي صلى الله عليه وسلم عن ربه فنزل: «قل هو الله أحد».',
              'edition': {
                'identifier': 'ar.jalalayn',
                'name': 'تفسير الجلالين',
              },
              'surah': {'number': 112},
              'numberInSurah': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }));

      final tafsir = await source.fetchTafsir(
        editionId: 'jalalayn',
        surahNumber: 112,
        ayahNumber: 1,
      );
      expect(tafsir.text, contains('قل هو الله أحد'));
      expect(tafsir.editionName, 'تفسير الجلالين');
      expect(tafsir.scholar, contains('جلال الدين'));
      expect(tafsir.sourceName, contains('AlQuran Cloud'));
      expect(tafsir.sourceUrl, 'https://alquran.cloud');
      expect(tafsir.reference, 'ar.jalalayn — 112:1');
    });

    test('unsupported edition throws TafsirUnavailableException', () {
      final source = buildSource(MockClient((_) async {
        fail('يجب ألا يُرسل طلب لكتاب غير مدعوم');
      }));
      expect(
        () => source.fetchTafsir(
          editionId: 'tabari',
          surahNumber: 1,
          ayahNumber: 1,
        ),
        throwsA(isA<TafsirUnavailableException>()),
      );
    });
  });
}
