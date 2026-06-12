import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/adhkar_repository.dart';
import '../data/repositories/hadith_repository.dart';
import '../data/repositories/quran_repository.dart';
import '../data/repositories/tafsir_repository.dart';
import '../models/dhikr.dart';
import '../models/hadith_models.dart';
import '../models/quran_models.dart';
import '../models/tafsir_models.dart';
import '../providers/favorites_provider.dart';
import '../widgets/dhikr_card.dart';
import '../widgets/placeholder_content.dart';
import 'hadith_detail_screen.dart';
import 'surah_detail_screen.dart';
import 'tafsir_detail_screen.dart';

/// شاشة المفضلة: الآيات ومقاطع التفسير المفضلة المحفوظة محلياً.
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

  /// تحويل معرّفات `tafsir:كتاب:س:آ` إلى مواضع مقاطع تفسير مرتبة.
  List<({String edition, int surah, int ayah})> _tafsirPositions(
      Set<String> ids) {
    final positions = <({String edition, int surah, int ayah})>[];
    for (final id in ids) {
      final parts = id.split(':');
      if (parts.length == 4 && parts[0] == 'tafsir') {
        final surah = int.tryParse(parts[2]);
        final ayah = int.tryParse(parts[3]);
        if (surah != null && ayah != null) {
          positions.add((edition: parts[1], surah: surah, ayah: ayah));
        }
      }
    }
    positions.sort((a, b) => a.surah != b.surah
        ? a.surah.compareTo(b.surah)
        : a.ayah.compareTo(b.ayah));
    return positions;
  }

  /// معرّفات الأحاديث المفضلة `hadith:معرّف`.
  List<String> _hadithIds(Set<String> ids) {
    final hadithIds = <String>[];
    for (final id in ids) {
      final parts = id.split(':');
      if (parts.length == 2 && parts[0] == 'hadith') {
        hadithIds.add(parts[1]);
      }
    }
    hadithIds.sort();
    return hadithIds;
  }

  /// معرّفات الأذكار المفضلة `dhikr:معرّف`.
  List<String> _dhikrIds(Set<String> ids) {
    final result = <String>[];
    for (final id in ids) {
      final parts = id.split(':');
      if (parts.length == 2 && parts[0] == 'dhikr') result.add(parts[1]);
    }
    result.sort();
    return result;
  }

  /// أرقام الأسماء الحسنى المفضلة `name:رقم`.
  List<int> _nameNumbers(Set<String> ids) {
    final result = <int>[];
    for (final id in ids) {
      final parts = id.split(':');
      if (parts.length == 2 && parts[0] == 'name') {
        final number = int.tryParse(parts[1]);
        if (number != null) result.add(number);
      }
    }
    result.sort();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final ayahs = _ayahPositions(favorites.favoriteIds);
    final tafsirs = _tafsirPositions(favorites.favoriteIds);
    final hadiths = _hadithIds(favorites.favoriteIds);
    final adhkar = _dhikrIds(favorites.favoriteIds);
    final names = _nameNumbers(favorites.favoriteIds);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.favorites)),
      body: ayahs.isEmpty &&
              tafsirs.isEmpty &&
              hadiths.isEmpty &&
              adhkar.isEmpty &&
              names.isEmpty
          ? const PlaceholderContent(
              icon: Icons.favorite_border,
              message: AppStrings.noFavoritesYet,
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (ayahs.isNotEmpty) ...[
                  _SectionHeader(title: AppStrings.favoriteAyahs),
                  for (final position in ayahs)
                    _FavoriteAyahTile(
                      surahNumber: position.surah,
                      ayahNumber: position.ayah,
                    ),
                ],
                if (tafsirs.isNotEmpty) ...[
                  _SectionHeader(title: AppStrings.tafsirFavorites),
                  for (final position in tafsirs)
                    _FavoriteTafsirTile(
                      editionId: position.edition,
                      surahNumber: position.surah,
                      ayahNumber: position.ayah,
                    ),
                ],
                if (hadiths.isNotEmpty) ...[
                  _SectionHeader(title: AppStrings.favoriteHadiths),
                  for (final hadithId in hadiths)
                    _FavoriteHadithTile(hadithId: hadithId),
                ],
                if (adhkar.isNotEmpty) ...[
                  _SectionHeader(title: AppStrings.favoriteAdhkar),
                  for (final dhikrId in adhkar)
                    _FavoriteDhikrTile(dhikrId: dhikrId),
                ],
                if (names.isNotEmpty) ...[
                  _SectionHeader(title: AppStrings.favoriteNames),
                  for (final number in names)
                    _FavoriteNameTile(number: number),
                ],
              ],
            ),
    );
  }
}

/// ذكر مفضل — يُعرض ببطاقة الذكر الكاملة بعد جلبه من المستودع.
class _FavoriteDhikrTile extends StatelessWidget {
  const _FavoriteDhikrTile({required this.dhikrId});

  final String dhikrId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DhikrModel>(
      future: context.read<AdhkarRepository>().getDhikr(dhikrId),
      builder: (context, snapshot) {
        final dhikr = snapshot.data;
        if (dhikr == null) {
          return ListTile(
            leading: const Icon(Icons.self_improvement),
            title: snapshot.hasError
                ? const Text(AppStrings.loadError)
                : const Text('...'),
          );
        }
        return DhikrCard(dhikr: dhikr);
      },
    );
  }
}

/// اسم من الأسماء الحسنى في المفضلة.
class _FavoriteNameTile extends StatelessWidget {
  const _FavoriteNameTile({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AllahNameModel>(
      future: context.read<AdhkarRepository>().getName(number),
      builder: (context, snapshot) {
        final name = snapshot.data;
        return ListTile(
          leading: Icon(
            Icons.star_border,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(name?.name ??
              (snapshot.hasError ? AppStrings.loadError : '...')),
          subtitle: name?.meaning == null
              ? null
              : Text('${name!.transliteration ?? ''} — ${name.meaning}'),
          trailing: IconButton(
            icon: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: AppStrings.removeFromFavorites,
            onPressed: () =>
                context.read<FavoritesProvider>().toggle('name:$number'),
          ),
        );
      },
    );
  }
}

/// حديث مفضل: يجلب النص عبر HadithRepository ويعرض مقتطفاً منه.
class _FavoriteHadithTile extends StatelessWidget {
  const _FavoriteHadithTile({required this.hadithId});

  final String hadithId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HadithModel>(
      future: context.read<HadithRepository>().getHadith(hadithId),
      builder: (context, snapshot) {
        final hadith = snapshot.data;
        return ListTile(
          leading: Icon(
            Icons.format_quote,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            hadith?.textArabic ??
                (snapshot.hasError ? AppStrings.loadError : '...'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: hadith == null
              ? Text('${AppStrings.hadithLabel} $hadithId')
              : Text(
                  [
                    if (hadith.attribution != null) hadith.attribution!,
                    if (hadith.grade != null) hadith.grade!,
                  ].join(' • '),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
          trailing: IconButton(
            icon: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: AppStrings.removeFromFavorites,
            onPressed: () =>
                context.read<FavoritesProvider>().toggle('hadith:$hadithId'),
          ),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.hadithDetail,
            arguments: HadithDetailArgs(hadithId: hadithId),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// مقطع تفسير مفضل: يجلب النص عبر TafsirRepository (من الذاكرة الدائمة
/// أو المصادر) ويعرض مقتطفاً منه.
class _FavoriteTafsirTile extends StatelessWidget {
  const _FavoriteTafsirTile({
    required this.editionId,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final String editionId;
  final int surahNumber;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) {
    final reference =
        '${AppStrings.surahLabel} ${toArabicDigits(surahNumber)}'
        '، ${AppStrings.ayahLabel} ${toArabicDigits(ayahNumber)}';

    return FutureBuilder<TafsirModel>(
      future: context.read<TafsirRepository>().getTafsir(
            editionId: editionId,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
          ),
      builder: (context, snapshot) {
        final tafsir = snapshot.data;
        return ListTile(
          leading: Icon(
            Icons.auto_stories,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            tafsir?.text ?? (snapshot.hasError ? AppStrings.loadError : '...'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${tafsir?.editionName ?? editionId} — $reference',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: AppStrings.removeFromFavorites,
            onPressed: () => context
                .read<FavoritesProvider>()
                .toggle('tafsir:$editionId:$surahNumber:$ayahNumber'),
          ),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.tafsirDetail,
            arguments: TafsirDetailArgs(
              surahNumber: surahNumber,
              ayahNumber: ayahNumber,
              initialEditionId: editionId,
            ),
          ),
        );
      },
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
