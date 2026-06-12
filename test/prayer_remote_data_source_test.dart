import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:deenhub/data/datasources/remote_prayer_data_source.dart';
import 'package:deenhub/services/api_client.dart';

/// التحقق من تحليل استجابة AlAdhan الرسمية (بصيغتها الفعلية الموثقة).
void main() {
  Map<String, dynamic> fixture() => {
        'code': 200,
        'status': 'OK',
        'data': {
          'timings': {
            'Fajr': '04:10',
            'Sunrise': '05:38 (+03)', // قد تُلحق المنطقة الزمنية
            'Dhuhr': '12:21',
            'Asr': '15:40',
            'Maghrib': '19:03',
            'Isha': '20:33',
          },
          'date': {
            'gregorian': {'date': '12-06-2026'},
            'hijri': {
              'day': '26',
              'weekday': {'ar': 'الجمعة'},
              'month': {'ar': 'ذوالحجة'},
              'year': '1447',
            },
          },
          'meta': {
            'method': {'id': 4, 'name': 'Umm Al-Qura University, Makkah'},
          },
        },
      };

  test('parses the six prayer times, hijri date and method', () async {
    late Uri requested;
    final source = RemotePrayerDataSource(
      client: ApiClient(
        baseUrl: 'https://api.aladhan.com/v1',
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode(fixture()),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );

    final times = await source.fetchPrayerTimes(
      date: DateTime(2026, 6, 12),
      latitude: 21.4225,
      longitude: 39.8262,
      methodId: 4,
    );

    // الطلب الصحيح: التاريخ بالمسار والإحداثيات والطريقة بالمعاملات
    expect(requested.path, '/v1/timings/12-06-2026');
    expect(requested.queryParameters['latitude'], '21.4225');
    expect(requested.queryParameters['method'], '4');

    // المواقيت الستة في يوم الطلب
    expect(times.fajr, DateTime(2026, 6, 12, 4, 10));
    expect(times.sunrise, DateTime(2026, 6, 12, 5, 38)); // اللاحقة أُهملت
    expect(times.dhuhr, DateTime(2026, 6, 12, 12, 21));
    expect(times.asr, DateTime(2026, 6, 12, 15, 40));
    expect(times.maghrib, DateTime(2026, 6, 12, 19, 3));
    expect(times.isha, DateTime(2026, 6, 12, 20, 33));

    // التاريخ الهجري بالعربية وبأرقام مشرقية
    expect(times.hijriDate, 'الجمعة ٢٦ ذوالحجة ١٤٤٧هـ');

    expect(times.methodId, 4);
    expect(times.methodName, contains('Umm Al-Qura'));
    expect(times.source.sourceName, contains('AlAdhan'));
    expect(times.source.sourceUrl, 'https://aladhan.com');

    // التسلسل (toJson/fromJson) سليم للذاكرة الدائمة
    final roundTripped = times.toJson();
    expect(roundTripped['fajr'], times.fajr.toIso8601String());
    expect(roundTripped['hijriDate'], times.hijriDate);
  });
}
