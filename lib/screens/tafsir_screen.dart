import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../data/repositories/tafsir_repository.dart';
import '../models/tafsir_models.dart';

/// شاشة التفسير: تعرض سجل كتب التفسير المعتمدة من TafsirRepository،
/// مع إرشاد المستخدم لفتح التفسير من أي آية.
class TafsirScreen extends StatefulWidget {
  const TafsirScreen({super.key});

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  late Future<List<TafsirEditionModel>> _editionsFuture;

  @override
  void initState() {
    super.initState();
    _editionsFuture = context.read<TafsirRepository>().getEditions();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tafsir)),
      body: FutureBuilder<List<TafsirEditionModel>>(
        future: _editionsFuture,
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
                    onPressed: () => setState(() {
                      _editionsFuture =
                          context.read<TafsirRepository>().getEditions();
                    }),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }
          final editions = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: colorScheme.primaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 12),
                      Expanded(child: Text(AppStrings.tafsirHint)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.availableEditions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final edition in editions)
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.auto_stories,
                      color: edition.available
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                    title: Text(edition.nameArabic),
                    subtitle: Text(
                      [
                        if (edition.fullName != null) edition.fullName!,
                        edition.scholar,
                      ].join('\n'),
                    ),
                    isThreeLine: edition.fullName != null,
                    trailing: edition.available
                        ? null
                        : Chip(
                            label: const Text(AppStrings.tafsirComingSoon),
                            visualDensity: VisualDensity.compact,
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
