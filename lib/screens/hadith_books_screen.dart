import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/utils/arabic_numbers.dart';
import '../providers/hadith_provider.dart';
import 'hadith_chapters_screen.dart';
import 'hadith_detail_screen.dart';

/// شاشة كتب الحديث: أقسام المصدر مع بطاقة متابعة آخر حديث مقروء.
class HadithBooksScreen extends StatelessWidget {
  const HadithBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HadithProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.hadith),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: AppStrings.searchInHadith,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.hadithSearch),
          ),
        ],
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, HadithProvider provider) {
    if (provider.isLoadingBooks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.booksError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.booksError!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.loadBooks,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    final lastRead = provider.lastRead;
    final books = provider.books;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (lastRead != null)
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.bookmark, color: colorScheme.primary),
              title: const Text(AppStrings.continueReading),
              subtitle: Text(
                lastRead.title ??
                    '${AppStrings.hadithLabel} ${lastRead.hadithId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.hadithDetail,
                arguments: HadithDetailArgs(hadithId: lastRead.hadithId),
              ),
            ),
          ),
        for (final book in books)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.menu_book,
                  size: 20, color: colorScheme.onPrimaryContainer),
            ),
            title: Text(book.title),
            subtitle: book.hadithCount == null
                ? null
                : Text(
                    '${toArabicDigits(book.hadithCount!)} ${AppStrings.hadithsCountSuffix}',
                  ),
            trailing: const Icon(Icons.arrow_back_ios_new, size: 14),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.hadithChapters,
              arguments: HadithChaptersArgs(
                bookId: book.id,
                bookTitle: book.title,
              ),
            ),
          ),
      ],
    );
  }
}
