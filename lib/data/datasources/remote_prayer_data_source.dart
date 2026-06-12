import '../../core/utils/arabic_numbers.dart';
import '../../models/content_source.dart';
import '../../models/prayer_times.dart';
import '../../services/api_client.dart';
import 'prayer_data_source.dart';

/// مصدر مواقيت الصلاة البعيد — يعتمد واجهة AlAdhan الرسمية.
///
/// التوثيق: https://aladhan.com/prayer-times-api
class RemotePrayerDataSource implements PrayerDataSource {
  RemotePrayerDataSource({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: _baseUrl);

  static const String _baseUrl = 'https://api.aladhan.com/v1';
  static const String _sourceName = 'AlAdhan API — مواقيت الصلاة';
  static const String _sourceUrl = 'https://aladhan.com';

  final ApiClient _client;

  @override
  Future<PrayerTimesModel> fetchPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    int? methodId,
  }) async {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dateSegment = '$dd-$mm-${date.year}';

    final json = await _client.getJson(
      '/timings/$dateSegment',
      queryParameters: {
        'latitude': '$latitude',
        'longitude': '$longitude',
        if (methodId != null) 'method': '$methodId',
      },
    ) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final timings = data['timings'] as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>;
    final method = meta['method'] as Map<String, dynamic>?;

    DateTime timeOf(String key) => _parseTime(timings[key] as String, date);

    return PrayerTimesModel(
      date: DateTime(date.year, date.month, date.day),
      hijriDate: _formatHijri(data['date'] as Map<String, dynamic>?),
      fajr: timeOf('Fajr'),
      sunrise: timeOf('Sunrise'),
      dhuhr: timeOf('Dhuhr'),
      asr: timeOf('Asr'),
      maghrib: timeOf('Maghrib'),
      isha: timeOf('Isha'),
      methodId: methodId ?? method?['id'] as int?,
      methodName: method?['name'] as String?,
      latitude: latitude,
      longitude: longitude,
      source: ContentSource(
        sourceName: _sourceName,
        reference: 'timings/$dateSegment @($latitude، $longitude)'
            '${methodId != null ? ' method=$methodId' : ''}',
        sourceUrl: _sourceUrl,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// تحويل وقت بصيغة "04:10" (وقد يلحق به مثل " (+03)") إلى DateTime
  /// في يوم الطلب.
  static DateTime _parseTime(String raw, DateTime date) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw.trim());
    if (match == null) {
      throw PrayerUnavailableException('صيغة وقت غير مفهومة: $raw');
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  /// تنسيق التاريخ الهجري: «الجمعة ٢٦ ذوالحجة ١٤٤٧هـ».
  static String? _formatHijri(Map<String, dynamic>? dateJson) {
    final hijri = dateJson?['hijri'] as Map<String, dynamic>?;
    if (hijri == null) return null;
    final weekday =
        (hijri['weekday'] as Map<String, dynamic>?)?['ar'] as String?;
    final day = hijri['day'] as String?;
    final month = (hijri['month'] as Map<String, dynamic>?)?['ar'] as String?;
    final year = hijri['year'] as String?;
    if (day == null || month == null || year == null) return null;
    final formatted =
        '${weekday != null ? '$weekday ' : ''}$day $month $yearهـ';
    return toArabicDigitsInText(formatted);
  }

  void dispose() => _client.dispose();
}
