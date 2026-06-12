import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../data/repositories/library_repository.dart';
import '../models/library_book.dart';
import '../widgets/book_card.dart';

/// وسيطات شاشة قائمة كتب (لمصدر محدد).
class BookListArgs {
  const BookListArgs({required this.title, required this.sourceId});

  final String title;
  final String sourceId;
}

/// شاشة قائمة كتب مصدر معتمد محدد (الشاملة، الدرر...).
class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key, this.args});

  final BookListArgs? args;

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  late Future<List<LibraryBookModel>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _booksFuture = context
        .read<LibraryRepository>()
        .getBooksBySource(widget.args?.sourceId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args?.title ?? AppStrings.library),
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
          if (books.isEmpty) {
            return const Center(child: Text(AppStrings.noContentYet));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [for (final book in books) BookCard(book: book)],
          );
        },
      ),
    );
  }
}
