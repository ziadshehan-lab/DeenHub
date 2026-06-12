import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إشارة مرجعية لصفحة تفسير (كتاب + سورة + آية).
class TafsirBookmark {
  const TafsirBookmark({
    required this.editionId,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final String editionId;
  final int surahNumber;
  final int ayahNumber;

  String get id => '$editionId:$surahNumber:$ayahNumber';

  static TafsirBookmark? tryParse(String id) {
    final parts = id.split(':');
    if (parts.length != 3) return null;
    final surah = int.tryParse(parts[1]);
    final ayah = int.tryParse(parts[2]);
    if (surah == null || ayah == null) return null;
    return TafsirBookmark(
      editionId: parts[0],
      surahNumber: surah,
      ayahNumber: ayah,
    );
  }
}

/// مزوّد التفسير: الإشارات المرجعية لصفحات التفسير مع حفظها محلياً.
class TafsirProvider extends ChangeNotifier {
  static const String _prefKeyBookmarks = 'tafsir_bookmarks';

  final List<TafsirBookmark> _bookmarks = [];

  List<TafsirBookmark> get bookmarks => List.unmodifiable(_bookmarks);

  bool isBookmarked(String bookmarkId) =>
      _bookmarks.any((b) => b.id == bookmarkId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefKeyBookmarks) ?? [];
    _bookmarks
      ..clear()
      ..addAll(stored.map(TafsirBookmark.tryParse).whereType<TafsirBookmark>());
    notifyListeners();
  }

  Future<void> toggleBookmark(TafsirBookmark bookmark) async {
    final existing = _bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (existing >= 0) {
      _bookmarks.removeAt(existing);
    } else {
      _bookmarks.insert(0, bookmark); // الأحدث أولاً
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefKeyBookmarks,
      _bookmarks.map((b) => b.id).toList(),
    );
  }
}
