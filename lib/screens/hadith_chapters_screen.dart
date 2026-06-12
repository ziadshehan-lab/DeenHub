import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/hadith_repository.dart';
import '../models/hadith_models.dart';
import 'hadith_list_screen.dart';

/// وسيطات شاشة أبواب كتاب الحديث.
class HadithChaptersArgs {
  const HadithChaptersArgs({required this.bookId, this.bookTitle});

  final String bookId;
  final String? bookTitle;
}

/// شاشة أبواب كتاب حديث محدد.
class HadithChaptersScreen extends StatefulWidget {
  const HadithChaptersScreen({super.key, this.args});

  final HadithChaptersArgs? args;

  @override
  State<HadithChaptersScreen> createState() => _HadithChaptersScreenState();
}

class _HadithChaptersScreenState extends State<HadithChaptersScreen> {
  late Future<List<HadithChapterModel>> _chaptersFuture;

  String get _bookId => widget.args?.bookId ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _chaptersFuture = context.read<HadithRepository>().getChapters(_bookId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args?.bookTitle ?? AppStrings.hadithChapters),
      ),
      body: FutureBuilder<List<HadithChapterModel>>(
        future: _chaptersFuture,
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
          final chapters = snapshot.data!;
          if (chapters.isEmpty) {
            return const Center(child: Text(AppStrings.noContentYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chapters.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    toArabicDigits(index + 1),
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(chapter.title),
                subtitle: chapter.hadithCount == null
                    ? null
                    : Text(
                        '${toArabicDigits(chapter.hadithCount!)} ${AppStrings.hadithsCountSuffix}',
                      ),
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.hadithList,
                  arguments: HadithListArgs(
                    chapterId: chapter.id,
                    chapterTitle: chapter.title,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
