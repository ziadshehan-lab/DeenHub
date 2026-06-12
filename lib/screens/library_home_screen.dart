import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../data/repositories/library_repository.dart';
import '../models/library_book.dart';
import '../providers/library_provider.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';
import 'book_list_screen.dart';
import 'category_screen.dart';

/// شاشة المكتبة الرئيسية: البحث، متابعة التصفح، التصنيفات الثمانية،
/// وسجل المصادر المعتمدة.
class LibraryHomeScreen extends StatefulWidget {
  const LibraryHomeScreen({super.key});

  @override
  State<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends State<LibraryHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<LibraryBookModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LibraryProvider>().init();
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
          await context.read<LibraryRepository>().searchBooks(query);
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
    final provider = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.library)),
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
                hintText: AppStrings.searchInLibrary,
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

  Widget _buildBody(LibraryProvider provider) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasSearched) {
      if (_results.isEmpty) {
        return const Center(child: Text(AppStrings.noResults));
      }
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [for (final book in _results) BookCard(book: book)],
      );
    }

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
              onPressed: provider.load,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final lastRead = provider.lastRead;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (lastRead != null)
          Card(
            color: colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.bookmark, color: colorScheme.primary),
              title: const Text(AppStrings.continueBrowsing),
              subtitle: Text(
                lastRead.title ?? lastRead.bookId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.libraryBook,
                arguments: BookDetailArgs(bookId: lastRead.bookId),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          AppStrings.libraryCategories,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
          ),
          itemCount: provider.categories.length,
          itemBuilder: (context, index) {
            final category = provider.categories[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.libraryCategory,
                  arguments: CategoryScreenArgs(
                    categoryId: category.id,
                    categoryTitle: category.title,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      category.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.librarySources,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final source in provider.sources)
          Card(
            child: ListTile(
              leading: Icon(Icons.public, color: colorScheme.primary),
              title: Text(source.name),
              subtitle: source.description == null
                  ? null
                  : Text(
                      source.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 14),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.libraryBooks,
                arguments: BookListArgs(
                  title: source.name,
                  sourceId: source.id,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
