import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/library_repository.dart';
import '../models/library_book.dart';
import '../widgets/book_card.dart';

/// وسيطات شاشة تصنيف المكتبة.
class CategoryScreenArgs {
  const CategoryScreenArgs({required this.categoryId, this.categoryTitle});

  final String categoryId;
  final String? categoryTitle;
}

/// شاشة تصنيف: كتب التصنيف المحدد بفهرسها وروابطها الموثقة.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, this.args});

  final CategoryScreenArgs? args;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<LibraryBookModel>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _booksFuture = context
        .read<LibraryRepository>()
        .getBooks(widget.args?.categoryId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args?.categoryTitle ?? AppStrings.library),
      ),
      body: FutureBuilder<List<LibraryBookModel>>(
        future: _booksFuture,
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
                    onPressed: () => setState(_load),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }
          final books = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${toArabicDigits(books.length)} ${AppStrings.booksCountSuffix}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
              for (final book in books) BookCard(book: book),
            ],
          );
        },
      ),
    );
  }
}
