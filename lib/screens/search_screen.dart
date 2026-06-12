import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../models/content_source.dart';
import '../models/hadith_models.dart';
import '../models/search_result_model.dart';
import '../providers/search_provider.dart';
import '../widgets/placeholder_content.dart';
import 'adhkar_list_screen.dart';
import 'book_detail_screen.dart';
import 'hadith_detail_screen.dart';
import 'surah_detail_screen.dart';
import 'tafsir_detail_screen.dart';

/// شاشة البحث الموحد: تبحث في القرآن والتفسير والحديث والأذكار
/// والأسماء الحسنى والمكتبة، مع مرشحات الأنواع وتجميع النتائج
/// وسجل عمليات البحث الأخيرة.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const Map<SearchResultType, String> typeTitles = {
    SearchResultType.quran: AppStrings.quran,
    SearchResultType.tafsir: AppStrings.tafsir,
    SearchResultType.hadith: AppStrings.hadith,
    SearchResultType.adhkar: AppStrings.adhkar,
    SearchResultType.names: AppStrings.namesOfAllah,
    SearchResultType.library: AppStrings.library,
  };

  static const Map<SearchResultType, IconData> typeIcons = {
    SearchResultType.quran: Icons.menu_book,
    SearchResultType.tafsir: Icons.auto_stories,
    SearchResultType.hadith: Icons.format_quote,
    SearchResultType.adhkar: Icons.self_improvement,
    SearchResultType.names: Icons.star_border,
    SearchResultType.library: Icons.local_library,
  };

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SearchProvider>().loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      context.read<SearchProvider>().search(query);
    });
  }

  void _submit(String query) {
    _debounce?.cancel();
    context.read<SearchProvider>().search(query);
  }

  /// توجيه النتيجة إلى شاشتها الصحيحة ببناء وسيطاتها من metadata.
  void _openResult(SearchResultModel result) {
    final meta = result.metadata;
    final Object? arguments = switch (result.type) {
      SearchResultType.quran => SurahDetailArgs(
          surahNumber: int.parse(meta['surahNumber']!),
          surahName: meta['surahName'],
          initialAyah: int.tryParse(meta['ayahNumber'] ?? ''),
        ),
      SearchResultType.tafsir => TafsirDetailArgs(
          surahNumber: int.parse(meta['surahNumber']!),
          ayahNumber: int.parse(meta['ayahNumber']!),
          surahName: meta['surahName'],
          initialEditionId: meta['editionId'],
        ),
      SearchResultType.hadith => meta['hadithId'] != null
          ? HadithDetailArgs(hadithId: meta['hadithId'])
          : HadithDetailArgs(
              inlineHadith: HadithModel(
                id: result.id,
                textArabic: meta['text'] ?? result.snippet,
                narrator: meta['narrator'],
                grade: meta['grade'],
                attribution: meta['bookName'],
                source: ContentSource(
                  sourceName: result.sourceName,
                  reference: result.reference,
                  lastUpdated: DateTime.now(),
                ),
              ),
            ),
      SearchResultType.adhkar => AdhkarListArgs(
          categoryId: meta['categoryId']!,
          categoryTitle: meta['categoryTitle'],
        ),
      SearchResultType.names => null,
      SearchResultType.library =>
        BookDetailArgs(bookId: meta['bookId']!),
    };
    Navigator.of(context).pushNamed(result.route, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: _submit,
              decoration: InputDecoration(
                hintText: AppStrings.searchEverywhere,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _submit('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          _buildFilterChips(provider),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(SearchProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: const Text(AppStrings.allFilter),
              selected: provider.filters.isEmpty,
              onSelected: (_) =>
                  context.read<SearchProvider>().clearFilters(),
            ),
          ),
          for (final type in SearchResultType.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                avatar: Icon(SearchScreen.typeIcons[type], size: 16),
                label: Text(SearchScreen.typeTitles[type]!),
                selected: provider.filters.contains(type),
                onSelected: (_) =>
                    context.read<SearchProvider>().toggleFilter(type),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.read<SearchProvider>().search(provider.query),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    if (!provider.hasSearched) {
      return _buildRecentSearches(provider);
    }
    if (provider.isEmpty) {
      return const PlaceholderContent(
        icon: Icons.search_off,
        message: AppStrings.noResults,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final type in SearchResultType.values)
          if (provider.results.containsKey(type)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(SearchScreen.typeIcons[type],
                      size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    SearchScreen.typeTitles[type]!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            for (final result in provider.results[type]!)
              ListTile(
                title: Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.primary),
                ),
                subtitle: Text(
                  result.snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.6),
                ),
                onTap: () => _openResult(result),
              ),
            const Divider(height: 1),
          ],
      ],
    );
  }

  Widget _buildRecentSearches(SearchProvider provider) {
    if (provider.recentSearches.isEmpty) {
      return const PlaceholderContent(
        icon: Icons.search,
        message: AppStrings.searchEverywhere,
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                AppStrings.recentSearches,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.read<SearchProvider>().clearHistory(),
                child: const Text(AppStrings.clearHistory),
              ),
            ],
          ),
        ),
        for (final query in provider.recentSearches)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(query),
            onTap: () {
              _controller.text = query;
              _submit(query);
            },
          ),
      ],
    );
  }
}
