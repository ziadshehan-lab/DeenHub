import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:deenhub/data/datasources/adhkar_data_source.dart';
import 'package:deenhub/data/datasources/remote_adhkar_data_source.dart';
import 'package:deenhub/data/repositories/adhkar_repository_impl.dart';
import 'package:deenhub/models/content_source.dart';
import 'package:deenhub/models/dhikr.dart';
import 'package:deenhub/services/api_client.dart';

void main() {
  group('RemoteAdhkarDataSource (hisnmuslim.com + AlAdhan)', () {
    test('fetchAdhkar parses Hisn chapters with BOM-prefixed responses',
        () async {
      // الموقع الرسمي يسبق استجاباته بعلامة BOM — كما وثقنا
      final source = RemoteAdhkarDataSource(
        hisnClient: ApiClient(
          baseUrl: 'https://www.hisnmuslim.com/api/ar',
          client: MockClient((request) async {
            expect(request.url.path, '/api/ar/1.json');
            final body = '﻿${jsonEncode({
                  'أذكار الاستيقاظ من النوم': [
                    {
                      'ID': 1,
                      'ARABIC_TEXT': 'الحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا',
                      'REPEAT': 1,
                      'AUDIO': 'x.mp3',
                    },
                    {
                      'ID': 2,
                      'ARABIC_TEXT': 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ',
                      'REPEAT': 3,
                      'AUDIO': 'y.mp3',
                    },
                  ]
                })}';
            return http.Response.bytes(
              utf8.encode(body),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );

      final adhkar = await source.fetchAdhkar('wake');
      expect(adhkar, hasLength(2));
      expect(adhkar.first.id, '1-1');
      expect(adhkar.first.text, contains('الحَمْدُ لِلَّهِ'));
      expect(adhkar.first.chapterTitle, 'أذكار الاستيقاظ من النوم');
      expect(adhkar.last.repeat, 3);
      expect(adhkar.first.sourceName, contains('حصن المسلم'));
      expect(adhkar.first.source.authorOrScholar, contains('القحطاني'));
    });

    test('fetchNamesOfAllah parses the AlAdhan response', () async {
      final source = RemoteAdhkarDataSource(
        namesClient: ApiClient(
          baseUrl: 'https://api.aladhan.com/v1',
          client: MockClient((request) async {
            expect(request.url.path, '/v1/asmaAlHusna');
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'name': 'الرَّحْمَنُ',
                    'transliteration': 'Ar Rahmaan',
                    'number': 1,
                    'en': {'meaning': 'The Beneficent'},
                  }
                ]
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );

      final names = await source.fetchNamesOfAllah();
      expect(names.single.name, 'الرَّحْمَنُ');
      expect(names.single.transliteration, 'Ar Rahmaan');
      expect(names.single.meaning, 'The Beneficent');
      expect(names.single.source.sourceUrl, 'https://aladhan.com');
    });

    test('unknown category throws AdhkarUnavailableException', () {
      final source = RemoteAdhkarDataSource(
        hisnClient: ApiClient(
          baseUrl: 'https://www.hisnmuslim.com/api/ar',
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );
      expect(
        () => source.fetchAdhkar('unknown'),
        throwsA(isA<AdhkarUnavailableException>()),
      );
    });
  });

  group('AdhkarRepositoryImpl', () {
    test('serves from local first without touching the remote', () async {
      final local = _FakeAdhkarSource();
      final remote = _FakeAdhkarSource();

      final repo = AdhkarRepositoryImpl(local: local, remote: remote);
      final categories = await repo.getCategories();
      expect(categories, hasLength(1));
      expect(local.categoryCalls, 1);
      expect(remote.categoryCalls, 0);
    });

    test('falls back to remote when local fails', () async {
      final local = _FakeAdhkarSource(fail: true);
      final remote = _FakeAdhkarSource();

      final repo = AdhkarRepositoryImpl(local: local, remote: remote);
      final adhkar = await repo.getAdhkar('wake');
      expect(adhkar, hasLength(1));
      expect(remote.adhkarCalls, 1);
    });

    test('getDhikr and getName resolve favorites by id', () async {
      final repo = AdhkarRepositoryImpl(local: _FakeAdhkarSource());

      final dhikr = await repo.getDhikr('1-1');
      expect(dhikr.text, contains('الحمد'));
      expect(
        () => repo.getDhikr('missing'),
        throwsA(isA<AdhkarUnavailableException>()),
      );

      final name = await repo.getName(1);
      expect(name.name, 'الرَّحْمَنُ');
      expect(
        () => repo.getName(500),
        throwsA(isA<AdhkarUnavailableException>()),
      );
    });

    test('searchNames matches Arabic, transliteration and meaning',
        () async {
      final repo = AdhkarRepositoryImpl(local: _FakeAdhkarSource());

      expect(await repo.searchNames('الرحمن'), hasLength(1));
      expect(await repo.searchNames('rahmaan'), hasLength(1));
      expect(await repo.searchNames('beneficent'), hasLength(1));
      expect(await repo.searchNames('xyz'), isEmpty);
      // استعلام فارغ يعيد القائمة كاملة
      expect(await repo.searchNames('  '), hasLength(1));
    });
  });
}

class _FakeAdhkarSource implements AdhkarDataSource {
  _FakeAdhkarSource({this.fail = false});

  final bool fail;
  int categoryCalls = 0;
  int adhkarCalls = 0;

  ContentSource get _source => ContentSource(
        sourceName: 'مصدر اختباري',
        reference: 'test',
        lastUpdated: DateTime(2026),
      );

  void _maybeFail() {
    if (fail) throw const AdhkarUnavailableException('فشل محلي');
  }

  @override
  Future<List<DhikrCategoryModel>> fetchCategories() async {
    categoryCalls++;
    _maybeFail();
    return [
      DhikrCategoryModel(id: 'wake', title: 'الاستيقاظ', source: _source),
    ];
  }

  @override
  Future<List<DhikrModel>> fetchAdhkar(String categoryId) async {
    adhkarCalls++;
    _maybeFail();
    return [
      DhikrModel(
        id: '1-1',
        categoryId: categoryId,
        text: 'الحمد لله',
        source: _source,
      ),
    ];
  }

  @override
  Future<List<DhikrModel>> searchAdhkar(String query) async {
    _maybeFail();
    return [];
  }

  @override
  Future<List<AllahNameModel>> fetchNamesOfAllah() async {
    _maybeFail();
    return [
      AllahNameModel(
        number: 1,
        name: 'الرَّحْمَنُ',
        transliteration: 'Ar Rahmaan',
        meaning: 'The Beneficent',
        source: _source,
      ),
    ];
  }
}
