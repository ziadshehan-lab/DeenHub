import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/quran_repository.dart';
import '../models/quran_models.dart';

/// موضع آخر قراءة (سورة وآية).
class LastReadPosition {
  const LastReadPosition({
    required this.surahNumber,
    required this.ayahNumber,
    this.surahName,
  });

  final int surahNumber;
  final int ayahNumber;
  final String? surahName;
}

/// مزوّد القرآن: حالة قائمة السور والبحث وموضع آخر قراءة.
class QuranProvider extends ChangeNotifier {
  QuranProvider({required this.repository});

  static const String _prefKeyLastReadSurah = 'quran_last_read_surah';
  static const String _prefKeyLastReadAyah = 'quran_last_read_ayah';
  static const String _prefKeyLastReadSurahName = 'quran_last_read_surah_name';

  final QuranRepository repository;

  List<SurahModel> _surahs = [];
  bool _isLoadingSurahs = false;
  String? _surahsError;
  LastReadPosition? _lastRead;

  List<SurahModel> get surahs => _surahs;
  bool get isLoadingSurahs => _isLoadingSurahs;
  String? get surahsError => _surahsError;
  LastReadPosition? get lastRead => _lastRead;

  /// تحميل قائمة السور وموضع آخر قراءة.
  Future<void> init() async {
    await Future.wait([loadSurahs(), _loadLastRead()]);
  }

  Future<void> loadSurahs() async {
    if (_surahs.isNotEmpty || _isLoadingSurahs) return;
    _isLoadingSurahs = true;
    _surahsError = null;
    notifyListeners();
    try {
      _surahs = await repository.getSurahs();
    } catch (e) {
      _surahsError = 'تعذر تحميل قائمة السور';
    } finally {
      _isLoadingSurahs = false;
      notifyListeners();
    }
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt(_prefKeyLastReadSurah);
    final ayah = prefs.getInt(_prefKeyLastReadAyah);
    if (surah != null && ayah != null) {
      _lastRead = LastReadPosition(
        surahNumber: surah,
        ayahNumber: ayah,
        surahName: prefs.getString(_prefKeyLastReadSurahName),
      );
      notifyListeners();
    }
  }

  /// حفظ موضع آخر قراءة.
  Future<void> setLastRead({
    required int surahNumber,
    required int ayahNumber,
    String? surahName,
  }) async {
    _lastRead = LastReadPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
    );
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyLastReadSurah, surahNumber);
    await prefs.setInt(_prefKeyLastReadAyah, ayahNumber);
    if (surahName != null) {
      await prefs.setString(_prefKeyLastReadSurahName, surahName);
    }
  }
}
