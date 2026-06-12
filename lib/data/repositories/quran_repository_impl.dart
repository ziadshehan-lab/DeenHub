import '../../models/quran_models.dart';
import '../datasources/quran_data_source.dart';
import 'quran_repository.dart';

/// تطبيق مستودع القرآن: يفضّل المصدر البعيد (واجهة Quran.com الرسمية)
/// ويعود تلقائياً إلى المصدر المحلي المضمَّن عند انقطاع الاتصال أو فشل
/// الطلب، مع ذاكرة مؤقتة داخل الجلسة لقائمة السور والآيات.
class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({
    QuranDataSource? remote,
    required QuranDataSource local,
    this.remoteTimeout = const Duration(seconds: 6),
  })  : _remote = remote,
        _local = local;

  final QuranDataSource? _remote;
  final QuranDataSource _local;
  final Duration remoteTimeout;

  List<SurahModel>? _surahsCache;
  final Map<int, List<AyahModel>> _ayahsCache = {};

  /// تنفيذ العملية من المصدر البعيد مع مهلة، والعودة للمحلي عند الفشل.
  Future<T> _remoteFirst<T>(
    Future<T> Function(QuranDataSource source) operation,
  ) async {
    final remote = _remote;
    if (remote != null) {
      try {
        return await operation(remote).timeout(remoteTimeout);
      } catch (_) {
        // تجاهل الخطأ والعودة إلى المصدر المحلي.
      }
    }
    return operation(_local);
  }

  @override
  Future<List<SurahModel>> getSurahs() async {
    final cached = _surahsCache;
    if (cached != null) return cached;
    final surahs = await _remoteFirst((s) => s.fetchSurahs());
    _surahsCache = surahs;
    return surahs;
  }

  @override
  Future<SurahModel> getSurah(int surahNumber) async {
    final surahs = await getSurahs();
    return surahs.firstWhere((s) => s.number == surahNumber);
  }

  @override
  Future<List<AyahModel>> getAyahs(int surahNumber) async {
    final cached = _ayahsCache[surahNumber];
    if (cached != null) return cached;
    final ayahs = await _remoteFirst((s) => s.fetchAyahs(surahNumber));
    _ayahsCache[surahNumber] = ayahs;
    return ayahs;
  }

  @override
  Future<AyahModel> getAyah(int surahNumber, int ayahNumber) async {
    final ayahs = await getAyahs(surahNumber);
    return ayahs.firstWhere((a) => a.ayahNumber == ayahNumber);
  }

  @override
  Future<List<AyahModel>> searchAyahs(String query) {
    if (query.trim().isEmpty) return Future.value(const []);
    return _remoteFirst((s) => s.searchAyahs(query));
  }

  @override
  Future<String> getBasmala() {
    // البسملة ثابتة ومتوفرة محلياً دائماً — لا حاجة لطلب بعيد.
    return _local.fetchBasmala();
  }
}
