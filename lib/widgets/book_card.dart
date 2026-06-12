import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../models/library_book.dart';
import '../providers/favorites_provider.dart';
import '../screens/book_detail_screen.dart';

/// نص بيانات الكتاب للنسخ والمشاركة مع الإسناد الكامل.
String formatBookForSharing(LibraryBookModel book) {
  final buffer = StringBuffer()
    ..writeln(book.title)
    ..writeln('${AppStrings.authorLabel}: ${book.author}')
    ..writeln('${AppStrings.sourceLabel}: ${book.sourceName}')
    ..write('${AppStrings.bookLinkLabel}: ${book.url}');
  return buffer.toString();
}

/// بطاقة كتاب في قوائم المكتبة والبحث والمفضلة.
class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book});

  final LibraryBookModel book;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFavorite =
        context.watch<FavoritesProvider>().isFavorite(book.favoriteId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.menu_book,
              size: 20, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${book.author} • ${book.sourceName}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colorScheme.primary),
        ),
        trailing: isFavorite
            ? Icon(Icons.favorite, size: 16, color: colorScheme.error)
            : null,
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.libraryBook,
          arguments: BookDetailArgs(bookId: book.id),
        ),
      ),
    );
  }
}
