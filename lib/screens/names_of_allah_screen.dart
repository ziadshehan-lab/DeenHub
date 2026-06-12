import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/arabic_numbers.dart';
import '../core/utils/arabic_text.dart';
import '../models/dhikr.dart';
import '../providers/adhkar_provider.dart';
import '../providers/favorites_provider.dart';

/// شاشة أسماء الله الحسنى: شبكة الأسماء التسعة والتسعين مع البحث
/// والمفضلة وورقة تفاصيل (النطق والمعنى والإسناد).
class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdhkarProvider>().loadNames();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AllahNameModel> _filtered(List<AllahNameModel> names) {
    final query = _query.trim();
    if (query.isEmpty) return names;
    // مطابقة عربية تتجاهل التشكيل + مطابقة لاتينية للنطق والمعنى
    final normalized = normalizeArabic(query);
    final lower = query.toLowerCase();
    return names.where((n) {
      return normalizeArabic(n.name).contains(normalized) ||
          (n.transliteration?.toLowerCase().contains(lower) ?? false) ||
          (n.meaning?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  void _showNameSheet(AllahNameModel name) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final isFavorite = sheetContext
            .watch<FavoritesProvider>()
            .isFavorite(name.favoriteId);
        final textTheme = Theme.of(sheetContext).textTheme;
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name.name,
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    fontFamily: AppTheme.quranFontFamily,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (name.transliteration != null)
                  Text(
                    '${AppStrings.transliterationLabel}: ${name.transliteration}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                if (name.meaning != null)
                  Text(
                    '${AppStrings.meaningLabel}: ${name.meaning}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                if (name.explanation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${AppStrings.explanationLabel2}: ${name.explanation}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text(isFavorite
                      ? AppStrings.removeFromFavorites
                      : AppStrings.addToFavorites),
                  onPressed: () => sheetContext
                      .read<FavoritesProvider>()
                      .toggle(name.favoriteId),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.sourceLabel}: ${name.source.sourceName}'
                  ' — ${AppStrings.nameNumberLabel} ${toArabicDigits(name.number)}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdhkarProvider>();
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.namesOfAllah)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: AppStrings.searchInNames,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildGrid(provider, favorites)),
        ],
      ),
    );
  }

  Widget _buildGrid(AdhkarProvider provider, FavoritesProvider favorites) {
    if (provider.isLoadingNames) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.namesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.namesError!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.loadNames,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    final names = _filtered(provider.names);
    if (names.isEmpty) {
      return const Center(child: Text(AppStrings.noResults));
    }
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: names.length,
      itemBuilder: (context, index) {
        final name = names[index];
        final isFavorite = favorites.isFavorite(name.favoriteId);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showNameSheet(name),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.quranFontFamily,
                            fontSize: 22,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (name.transliteration != null)
                          Text(
                            name.transliteration!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colorScheme.outline),
                          ),
                      ],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 4,
                  start: 4,
                  child: Text(
                    toArabicDigits(name.number),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ),
                if (isFavorite)
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: Icon(Icons.favorite,
                        size: 14, color: colorScheme.error),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
