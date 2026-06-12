import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/quran_repository.dart';
import '../models/quran_models.dart';
import '../providers/favorites_provider.dart';
import '../widgets/placeholder_content.dart';
import 'surah_detail_screen.dart';

/// شاشة المفضلة: تعرض الآيات المفضلة المحفوظة محلياً.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  /// تحويل معرّفات المفضلة `ayah:س:آ` إلى مواضع آيات مرتبة.
  List<({int surah, int ayah})> _ayahPositions(Set<String> ids) {
    final positions = <({int surah, int ayah})>[];
    for (final id in ids) {
      final parts = id.split(':');
      if (parts.length == 3 && parts[0] == 'ayah') {
        final surah = int.tryParse(parts[1]);
        final ayah = int.tryParse(parts[2]);
        if (surah != null && ayah != null) {
          positions.add((surah: surah, ayah: ayah));
        }
      }
    }
    positions.sort((a, b) => a.surah != b.surah
        ? a.surah.compareTo(b.surah)
        : a.ayah.compareTo(b.ayah));
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final positions = _ayahPositions(favorites.favoriteIds);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.favorites)),
      body: positions.isEmpty
          ? const PlaceholderContent(
              icon: Icons.favorite_border,
              message: AppStrings.noFavoritesYet,
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: positions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final position = positions[index];
                return _FavoriteAyahTile(
                  surahNumber: position.surah,
                  ayahNumber: position.ayah,
                );
              },
            ),
    );
  }
}

class _FavoriteAyahTile extends StatelessWidget {
  const _FavoriteAyahTile({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<QuranRepository>();

    return FutureBuilder<(AyahModel, SurahModel)>(
      future: () async {
        final results = await Future.wait<dynamic>([
          repository.getAyah(surahNumber, ayahNumber),
          repository.getSurah(surahNumber),
        ]);
        return (results[0] as AyahModel, results[1] as SurahModel);
      }(),
      builder: (context, snapshot) {
        final reference =
            '${AppStrings.ayahLabel} ${toArabicDigits(ayahNumber)}';
        if (!snapshot.hasData) {
          return ListTile(
            title: snapshot.hasError
                ? const Text(AppStrings.loadError)
                : const LinearProgressIndicator(),
            subtitle: Text(
              '${AppStrings.surahLabel} ${toArabicDigits(surahNumber)} — $reference',
            ),
          );
        }
        final (ayah, surah) = snapshot.data!;
        return ListTile(
          title: Text(
            ayah.textArabic,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.quranTextStyle(context, fontSize: 18)
                .copyWith(height: 1.8),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${surah.nameArabic} — $reference',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: AppStrings.removeFromFavorites,
            onPressed: () =>
                context.read<FavoritesProvider>().toggle(ayah.favoriteId),
          ),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.surahDetail,
            arguments: SurahDetailArgs(
              surahNumber: surahNumber,
              surahName: surah.nameArabic,
              initialAyah: ayahNumber,
            ),
          ),
        );
      },
    );
  }
}
