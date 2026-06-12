import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/quran_repository.dart';
import '../models/quran_models.dart';
import '../providers/quran_provider.dart';
import '../widgets/placeholder_content.dart';
import 'surah_detail_screen.dart';

/// شاشة البحث في القرآن الكريم.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<AyahModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results =
          await context.read<QuranRepository>().searchAyahs(trimmed);
      if (!mounted) return;
      setState(() {
        _results = results;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _hasSearched = true;
        _isSearching = false;
      });
    }
  }

  String _surahName(BuildContext context, int surahNumber) {
    final surahs = context.read<QuranProvider>().surahs;
    for (final surah in surahs) {
      if (surah.number == surahNumber) return surah.nameArabic;
    }
    return '${AppStrings.surahLabel} ${toArabicDigits(surahNumber)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: AppStrings.searchInQuran,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return const PlaceholderContent(
        icon: Icons.search,
        message: AppStrings.searchInQuran,
      );
    }
    if (_results.isEmpty) {
      return const PlaceholderContent(
        icon: Icons.search_off,
        message: AppStrings.noResults,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ayah = _results[index];
        final surahName = _surahName(context, ayah.surahNumber);
        return ListTile(
          title: Text(
            ayah.textArabic,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.quranTextStyle(context, fontSize: 18)
                .copyWith(height: 1.8),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$surahName — ${AppStrings.ayahLabel} ${toArabicDigits(ayah.ayahNumber)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.surahDetail,
            arguments: SurahDetailArgs(
              surahNumber: ayah.surahNumber,
              surahName: surahName,
              initialAyah: ayah.ayahNumber,
            ),
          ),
        );
      },
    );
  }
}
