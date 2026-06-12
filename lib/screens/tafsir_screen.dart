import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/tafsir_repository.dart';
import '../models/tafsir_models.dart';
import '../providers/tafsir_provider.dart';
import 'tafsir_detail_screen.dart';

/// شاشة التفسير: الإشارات المرجعية، البحث في نصوص التفسير المحفوظة،
/// وسجل كتب التفسير المعتمدة — كل البيانات من TafsirRepository.
class TafsirScreen extends StatefulWidget {
  const TafsirScreen({super.key});

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  late Future<List<TafsirEditionModel>> _editionsFuture;
  List<TafsirModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _editionsFuture = context.read<TafsirRepository>().getEditions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results =
          await context.read<TafsirRepository>().searchTafsir(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _hasSearched = true;
        _isSearching = false;
      });
    }
  }

  void _openTafsir({
    required String editionId,
    required int surahNumber,
    required int ayahNumber,
  }) {
    Navigator.of(context).pushNamed(
      AppRoutes.tafsirDetail,
      arguments: TafsirDetailArgs(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        initialEditionId: editionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bookmarks = context.watch<TafsirProvider>().bookmarks;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tafsir)),
      body: FutureBuilder<List<TafsirEditionModel>>(
        future: _editionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(AppStrings.loadError),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() {
                      _editionsFuture =
                          context.read<TafsirRepository>().getEditions();
                    }),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }
          final editions = snapshot.data!;
          final editionNames = {
            for (final e in editions) e.id: e.nameArabic,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onQueryChanged,
                onSubmitted: _search,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchInTafsirCorpus,
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_hasSearched) ...[
                const SizedBox(height: 8),
                if (_searchResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text(AppStrings.noResults)),
                  )
                else
                  for (final result in _searchResults)
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.manage_search,
                            color: colorScheme.primary),
                        title: Text(
                          result.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${result.editionName} — '
                          '${AppStrings.surahLabel} ${toArabicDigits(result.surahNumber)}'
                          '، ${AppStrings.ayahLabel} ${toArabicDigits(result.ayahNumber)}',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        onTap: () => _openTafsir(
                          editionId: result.editionId,
                          surahNumber: result.surahNumber,
                          ayahNumber: result.ayahNumber,
                        ),
                      ),
                    ),
              ],
              if (bookmarks.isNotEmpty && !_hasSearched) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.tafsirBookmarks,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final bookmark in bookmarks)
                  Card(
                    child: ListTile(
                      leading:
                          Icon(Icons.bookmark, color: colorScheme.primary),
                      title: Text(
                        editionNames[bookmark.editionId] ??
                            bookmark.editionId,
                      ),
                      subtitle: Text(
                        '${AppStrings.surahLabel} ${toArabicDigits(bookmark.surahNumber)}'
                        '، ${AppStrings.ayahLabel} ${toArabicDigits(bookmark.ayahNumber)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: AppStrings.removeTafsirBookmark,
                        onPressed: () => context
                            .read<TafsirProvider>()
                            .toggleBookmark(bookmark),
                      ),
                      onTap: () => _openTafsir(
                        editionId: bookmark.editionId,
                        surahNumber: bookmark.surahNumber,
                        ayahNumber: bookmark.ayahNumber,
                      ),
                    ),
                  ),
              ],
              if (!_hasSearched) ...[
                const SizedBox(height: 16),
                Card(
                  color: colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Expanded(child: Text(AppStrings.tafsirHint)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.availableEditions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final edition in editions)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.auto_stories,
                        color: edition.available
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                      title: Text(edition.nameArabic),
                      subtitle: Text(
                        [
                          if (edition.fullName != null) edition.fullName!,
                          edition.scholar,
                        ].join('\n'),
                      ),
                      isThreeLine: edition.fullName != null,
                      trailing: edition.available
                          ? null
                          : Chip(
                              label:
                                  const Text(AppStrings.tafsirComingSoon),
                              visualDensity: VisualDensity.compact,
                            ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
