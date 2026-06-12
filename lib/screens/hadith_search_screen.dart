import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../data/repositories/hadith_repository.dart';
import '../models/hadith_models.dart';
import '../widgets/placeholder_content.dart';
import 'hadith_detail_screen.dart';

/// شاشة البحث في الأحاديث: نص الحديث، الراوي، الكتاب، والباب —
/// عبر مصادر البحث (الدرر السنية) مع بحث محلي دون اتصال.
class HadithSearchScreen extends StatefulWidget {
  const HadithSearchScreen({super.key});

  @override
  State<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends State<HadithSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<HadithSearchResultModel> _results = [];
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
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results =
          await context.read<HadithRepository>().searchHadiths(query);
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

  void _openResult(HadithSearchResultModel result) {
    Navigator.of(context).pushNamed(
      AppRoutes.hadithDetail,
      arguments: result.hadithId != null
          ? HadithDetailArgs(hadithId: result.hadithId)
          : HadithDetailArgs(inlineHadith: result.toInlineHadith()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.searchInHadith)),
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
                hintText: AppStrings.searchInHadith,
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
        message: AppStrings.searchInHadith,
      );
    }
    if (_results.isEmpty) {
      return const PlaceholderContent(
        icon: Icons.search_off,
        message: AppStrings.noResults,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _results[index];
        final details = [
          if (result.narrator != null)
            '${AppStrings.narratorLabel}: ${result.narrator}',
          if (result.bookName != null)
            '${AppStrings.bookLabel}: ${result.bookName}',
          if (result.grade != null)
            '${AppStrings.gradeLabel}: ${result.grade}',
        ].join(' • ');
        return ListTile(
          title: Text(
            result.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.7),
          ),
          subtitle: details.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    details,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
          onTap: () => _openResult(result),
        );
      },
    );
  }
}
