import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/utils/arabic_numbers.dart';
import '../core/utils/arabic_text.dart';
import '../data/datasources/tafsir_data_source.dart';
import '../data/repositories/tafsir_repository.dart';
import '../models/tafsir_models.dart';
import '../providers/favorites_provider.dart';
import '../providers/tafsir_provider.dart';

/// وسيطات شاشة تفسير الآية.
class TafsirDetailArgs {
  const TafsirDetailArgs({
    required this.surahNumber,
    required this.ayahNumber,
    this.surahName,
    this.initialEditionId,
  });

  final int surahNumber;
  final int ayahNumber;
  final String? surahName;

  /// كتاب تفسير يُفتح مباشرة (من إشارة مرجعية أو نتيجة بحث).
  final String? initialEditionId;
}

/// شاشة تفسير آية: تبديل فوري بين كتب التفسير (تُجلب كلها مسبقاً
/// بالتوازي)، بحث داخل النص مع إبراز، إشارة مرجعية، ومقطع مفضل،
/// مع بطاقة إسناد كاملة.
class TafsirDetailScreen extends StatefulWidget {
  const TafsirDetailScreen({super.key, this.args});

  final TafsirDetailArgs? args;

  @override
  State<TafsirDetailScreen> createState() => _TafsirDetailScreenState();
}

class _TafsirDetailScreenState extends State<TafsirDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<TafsirEditionModel> _editions = [];
  final Map<String, TafsirModel> _loaded = {};
  final Map<String, String> _editionErrors = {};
  final Set<String> _loading = {};

  String? _selectedEditionId;
  String? _editionsError;
  bool _searchVisible = false;
  String _searchQuery = '';

  int get _surahNumber => widget.args?.surahNumber ?? 1;
  int get _ayahNumber => widget.args?.ayahNumber ?? 1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _editionsError = null);
    try {
      final editions =
          await context.read<TafsirRepository>().getEditions();
      if (!mounted) return;
      final available = editions.where((e) => e.available).toList();
      final initial = widget.args?.initialEditionId;
      setState(() {
        _editions = editions;
        _selectedEditionId = available.any((e) => e.id == initial)
            ? initial
            : available.firstOrNull?.id;
      });
      if (available.isEmpty) {
        setState(() => _editionsError = AppStrings.tafsirUnavailable);
        return;
      }
      // جلب كل الكتب المتاحة بالتوازي ليكون التبديل بينها فورياً
      for (final edition in available) {
        _fetchEdition(edition.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _editionsError = AppStrings.loadError);
    }
  }

  Future<void> _fetchEdition(String editionId) async {
    if (_loaded.containsKey(editionId) || _loading.contains(editionId)) {
      return;
    }
    setState(() {
      _loading.add(editionId);
      _editionErrors.remove(editionId);
    });
    try {
      final tafsir = await context.read<TafsirRepository>().getTafsir(
            editionId: editionId,
            surahNumber: _surahNumber,
            ayahNumber: _ayahNumber,
          );
      if (!mounted) return;
      setState(() {
        _loaded[editionId] = tafsir;
        _loading.remove(editionId);
      });
    } on TafsirUnavailableException catch (e) {
      if (!mounted) return;
      setState(() {
        _editionErrors[editionId] = e.message;
        _loading.remove(editionId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _editionErrors[editionId] = AppStrings.loadError;
        _loading.remove(editionId);
      });
    }
  }

  TafsirModel? get _selectedTafsir =>
      _selectedEditionId == null ? null : _loaded[_selectedEditionId];

  @override
  Widget build(BuildContext context) {
    final surahLabel = widget.args?.surahName ??
        '${AppStrings.surahLabel} ${toArabicDigits(_surahNumber)}';
    final tafsir = _selectedTafsir;
    final favorites = context.watch<FavoritesProvider>();
    final tafsirProvider = context.watch<TafsirProvider>();
    final isFavorite =
        tafsir != null && favorites.isFavorite(tafsir.favoriteId);
    final isBookmarked =
        tafsir != null && tafsirProvider.isBookmarked(tafsir.bookmarkId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.tafsirOfAyah} ${toArabicDigits(_ayahNumber)} — $surahLabel',
        ),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.search_off : Icons.search),
            tooltip: AppStrings.searchInTafsirText,
            onPressed: () => setState(() {
              _searchVisible = !_searchVisible;
              if (!_searchVisible) {
                _searchQuery = '';
                _searchController.clear();
              }
            }),
          ),
          if (tafsir != null) ...[
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              ),
              tooltip: isBookmarked
                  ? AppStrings.removeTafsirBookmark
                  : AppStrings.addTafsirBookmark,
              onPressed: () =>
                  context.read<TafsirProvider>().toggleBookmark(
                        TafsirBookmark(
                          editionId: tafsir.editionId,
                          surahNumber: tafsir.surahNumber,
                          ayahNumber: tafsir.ayahNumber,
                        ),
                      ),
            ),
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              tooltip: isFavorite
                  ? AppStrings.removeFromFavorites
                  : AppStrings.addToFavorites,
              onPressed: () => context
                  .read<FavoritesProvider>()
                  .toggle(tafsir.favoriteId),
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_editions.isNotEmpty) _buildEditionSelector(),
          if (_searchVisible) _buildSearchField(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildEditionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final edition in _editions)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                avatar: _loading.contains(edition.id)
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                label: Text(
                  edition.available
                      ? edition.nameArabic
                      : '${edition.nameArabic} (${AppStrings.tafsirComingSoon})',
                ),
                selected: edition.id == _selectedEditionId,
                onSelected: edition.available
                    ? (_) {
                        setState(() => _selectedEditionId = edition.id);
                        _fetchEdition(edition.id);
                      }
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final tafsir = _selectedTafsir;
    final matchCount = tafsir == null || _searchQuery.isEmpty
        ? null
        : findArabicMatches(tafsir.text, _searchQuery).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: AppStrings.searchInTafsirText,
          prefixIcon: const Icon(Icons.manage_search),
          isDense: true,
          suffixText: matchCount == null
              ? null
              : matchCount == 0
                  ? AppStrings.noMatchesInText
                  : '${toArabicDigits(matchCount)} ${AppStrings.matchesFound}',
        ),
      ),
    );
  }

  Widget _buildContent() {
    final editionsError = _editionsError;
    if (editionsError != null) {
      return _ErrorRetry(message: editionsError, onRetry: _init);
    }
    final selectedId = _selectedEditionId;
    if (selectedId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final editionError = _editionErrors[selectedId];
    if (editionError != null) {
      return _ErrorRetry(
        message: editionError,
        onRetry: () => _fetchEdition(selectedId),
      );
    }
    final tafsir = _loaded[selectedId];
    if (tafsir == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final textTheme = Theme.of(context).textTheme;
    final baseStyle =
        textTheme.bodyLarge?.copyWith(height: 1.9, fontSize: 17);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _searchQuery.isEmpty
            ? Text(tafsir.text, style: baseStyle)
            : _HighlightedText(
                text: tafsir.text,
                query: _searchQuery,
                style: baseStyle,
              ),
        const SizedBox(height: 24),
        _AttributionCard(tafsir: tafsir),
      ],
    );
  }
}

/// نص مع إبراز مواضع تطابق البحث (مع تجاهل التشكيل).
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
  });

  final String text;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final ranges = findArabicMatches(text, query);
    if (ranges.isEmpty) return Text(text, style: style);

    final highlight = TextStyle(
      backgroundColor:
          Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.35),
      fontWeight: FontWeight.bold,
    );
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: highlight,
      ));
      cursor = range.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(TextSpan(children: spans), style: style);
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الإسناد: الكتاب، العالِم، المصدر، المرجع، الرابط.
class _AttributionCard extends StatelessWidget {
  const _AttributionCard({required this.tafsir});

  final TafsirModel tafsir;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget row(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(text: value, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(Icons.menu_book, AppStrings.tafsirBook, tafsir.editionName),
            if (tafsir.scholar != null)
              row(Icons.person, AppStrings.scholarLabel, tafsir.scholar!),
            row(Icons.verified_outlined, AppStrings.sourceLabel,
                tafsir.sourceName),
            row(Icons.bookmark_outline, AppStrings.referenceLabel,
                tafsir.reference),
            if (tafsir.sourceUrl != null)
              row(Icons.link, AppStrings.sourceLabel, tafsir.sourceUrl!),
          ],
        ),
      ),
    );
  }
}
