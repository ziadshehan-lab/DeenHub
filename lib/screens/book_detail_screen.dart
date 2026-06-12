import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_strings.dart';
import '../data/repositories/library_repository.dart';
import '../models/library_book.dart';
import '../providers/favorites_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/book_card.dart' show formatBookForSharing;

/// وسيطات شاشة تفاصيل الكتاب.
class BookDetailArgs {
  const BookDetailArgs({required this.bookId});

  final String bookId;
}

/// شاشة تفاصيل الكتاب: العنوان والمؤلف والتصنيف والوصف والمصدر
/// والرابط الموثق، مع المفضلة والنسخ والمشاركة وحفظ آخر كتاب مفتوح.
class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, this.args});

  final BookDetailArgs? args;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  LibraryBookModel? _book;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookId = widget.args?.bookId;
    if (bookId == null) {
      setState(() {
        _isLoading = false;
        _error = AppStrings.loadError;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final book = await context.read<LibraryRepository>().getBook(bookId);
      if (!mounted) return;
      setState(() {
        _book = book;
        _isLoading = false;
      });
      // حفظ آخر كتاب مفتوح تلقائياً
      context
          .read<LibraryProvider>()
          .setLastRead(bookId: book.id, title: book.title);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AppStrings.loadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = book != null && favorites.isFavorite(book.favoriteId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.library),
        actions: [
          if (book != null) ...[
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              tooltip: isFavorite
                  ? AppStrings.removeFromFavorites
                  : AppStrings.addToFavorites,
              onPressed: () =>
                  context.read<FavoritesProvider>().toggle(book.favoriteId),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: AppStrings.copyBookInfo,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(
                  ClipboardData(text: formatBookForSharing(book)),
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text(AppStrings.bookInfoCopied)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: AppStrings.shareBook,
              onPressed: () => Share.share(formatBookForSharing(book)),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    final book = _book!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categoryTitle = context
            .read<LibraryProvider>()
            .categories
            .where((c) => c.id == book.categoryId)
            .firstOrNull
            ?.title ??
        book.categoryId;

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(book.title, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.authorLabel}: ${book.author}',
          style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
        ),
        if (book.description != null) ...[
          const SizedBox(height: 16),
          Text(
            book.description!,
            style: textTheme.bodyLarge?.copyWith(height: 1.8),
          ),
        ],
        const SizedBox(height: 24),
        // بطاقة الإسناد: المصدر والمؤلف والمرجع والرابط
        Card(
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                row(Icons.verified_outlined, AppStrings.sourceLabel,
                    book.sourceName),
                row(Icons.person, AppStrings.authorLabel, book.author),
                row(Icons.category_outlined, AppStrings.categoryLabel,
                    categoryTitle),
                row(Icons.link, AppStrings.bookLinkLabel, book.url),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.openSourceNote,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
      ],
    );
  }
}
