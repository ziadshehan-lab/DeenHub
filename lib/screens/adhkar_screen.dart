import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/adhkar_repository.dart';
import '../models/dhikr.dart';
import '../providers/adhkar_provider.dart';
import '../widgets/dhikr_card.dart';
import 'adhkar_list_screen.dart';

/// شاشة الأذكار: بحث في كل الأذكار + تصنيفات حصن المسلم التسعة.
class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<DhikrModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdhkarProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _search(query));
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
          await context.read<AdhkarRepository>().searchAdhkar(query);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdhkarProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adhkar)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: AppStrings.searchInAdhkar,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(AdhkarProvider provider) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasSearched) {
      if (_results.isEmpty) {
        return const Center(child: Text(AppStrings.noResults));
      }
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final dhikr in _results) DhikrCard(dhikr: dhikr),
        ],
      );
    }

    if (provider.isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.categoriesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.categoriesError!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.loadCategories,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.self_improvement,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(category.title),
          subtitle: category.dhikrCount == null
              ? null
              : Text(
                  '${toArabicDigits(category.dhikrCount!)} ${AppStrings.dhikrCountSuffix}',
                ),
          trailing: const Icon(Icons.arrow_back_ios_new, size: 14),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.adhkarList,
            arguments: AdhkarListArgs(
              categoryId: category.id,
              categoryTitle: category.title,
            ),
          ),
        );
      },
    );
  }
}
