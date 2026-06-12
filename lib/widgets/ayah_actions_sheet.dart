import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/utils/arabic_numbers.dart';
import '../models/quran_models.dart';
import '../providers/favorites_provider.dart';
import '../providers/quran_provider.dart';
import '../screens/tafsir_detail_screen.dart';

/// نص الآية مهيأ للنسخ والمشاركة مع الإسناد الكامل للمصدر.
String formatAyahForSharing(AyahModel ayah, {String? surahName}) {
  final reference = surahName != null
      ? '$surahName — ${AppStrings.ayahLabel} ${toArabicDigits(ayah.ayahNumber)}'
      : '${ayah.surahNumber}:${ayah.ayahNumber}';
  final buffer = StringBuffer()
    ..writeln('﴿${ayah.textArabic}﴾')
    ..writeln('[$reference]')
    ..write('${AppStrings.sourceLabel}: ${ayah.sourceName}');
  if (ayah.sourceUrl != null) {
    buffer.write(' — ${ayah.sourceUrl}');
  }
  return buffer.toString();
}

/// عرض ورقة إجراءات الآية: مفضلة، نسخ، مشاركة، تحديد موضع القراءة.
Future<void> showAyahActionsSheet(
  BuildContext context, {
  required AyahModel ayah,
  String? surahName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final favorites = sheetContext.watch<FavoritesProvider>();
      final isFavorite = favorites.isFavorite(ayah.favoriteId);
      final messenger = ScaffoldMessenger.of(context);

      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  '${AppStrings.surahLabel} ${surahName ?? toArabicDigits(ayah.surahNumber)} — '
                  '${AppStrings.ayahLabel} ${toArabicDigits(ayah.ayahNumber)}',
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
                subtitle: Text(
                  '${AppStrings.sourceLabel}: ${ayah.sourceName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.auto_stories),
                title: const Text(AppStrings.viewTafsir),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushNamed(
                    AppRoutes.tafsirDetail,
                    arguments: TafsirDetailArgs(
                      surahNumber: ayah.surahNumber,
                      ayahNumber: ayah.ayahNumber,
                      surahName: surahName,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Theme.of(sheetContext).colorScheme.error
                      : null,
                ),
                title: Text(
                  isFavorite
                      ? AppStrings.removeFromFavorites
                      : AppStrings.addToFavorites,
                ),
                onTap: () {
                  sheetContext.read<FavoritesProvider>().toggle(
                    ayah.favoriteId,
                  );
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text(AppStrings.copyAyah),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: formatAyahForSharing(ayah, surahName: surahName),
                    ),
                  );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  messenger.showSnackBar(
                    const SnackBar(content: Text(AppStrings.ayahCopied)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text(AppStrings.shareAyah),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Share.share(formatAyahForSharing(ayah, surahName: surahName));
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: const Text(AppStrings.setAsLastRead),
                onTap: () {
                  sheetContext.read<QuranProvider>().setLastRead(
                    surahNumber: ayah.surahNumber,
                    ayahNumber: ayah.ayahNumber,
                    surahName: surahName,
                  );
                  Navigator.of(sheetContext).pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text(AppStrings.lastReadSaved)),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
