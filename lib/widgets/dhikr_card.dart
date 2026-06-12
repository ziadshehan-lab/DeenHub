import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/arabic_numbers.dart';
import '../models/dhikr.dart';
import '../providers/favorites_provider.dart';

/// نص الذكر مهيأ للنسخ والمشاركة مع الإسناد الكامل.
String formatDhikrForSharing(DhikrModel dhikr) {
  final buffer = StringBuffer()..writeln(dhikr.text);
  if (dhikr.repeat > 1) {
    buffer.writeln(
        '${AppStrings.repeatLabel}: ${toArabicDigits(dhikr.repeat)}');
  }
  buffer.write('${AppStrings.sourceLabel}: ${dhikr.sourceName}'
      ' — ${dhikr.reference}');
  if (dhikr.sourceUrl != null) {
    buffer.write(' — ${dhikr.sourceUrl}');
  }
  return buffer.toString();
}

/// بطاقة ذكر: النص، شارة التكرار، الإسناد، وأزرار النسخ والمشاركة
/// والمفضلة — تُستخدم في القوائم والبحث والمفضلة.
class DhikrCard extends StatelessWidget {
  const DhikrCard({super.key, required this.dhikr});

  final DhikrModel dhikr;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isFavorite =
        context.watch<FavoritesProvider>().isFavorite(dhikr.favoriteId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dhikr.text,
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 18,
                height: 1.9,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(Icons.repeat,
                      size: 16, color: colorScheme.primary),
                  label: Text(
                    dhikr.repeat > 1
                        ? '${AppStrings.repeatLabel}: ${toArabicDigits(dhikr.repeat)}'
                        : AppStrings.onceLabel,
                    style: textTheme.bodySmall,
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? colorScheme.error : null,
                  ),
                  tooltip: isFavorite
                      ? AppStrings.removeFromFavorites
                      : AppStrings.addToFavorites,
                  onPressed: () => context
                      .read<FavoritesProvider>()
                      .toggle(dhikr.favoriteId),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: AppStrings.copyDhikr,
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      ClipboardData(text: formatDhikrForSharing(dhikr)),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text(AppStrings.dhikrCopied)),
                    );
                  },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.share, size: 20),
                  tooltip: AppStrings.shareDhikr,
                  onPressed: () =>
                      Share.share(formatDhikrForSharing(dhikr)),
                ),
              ],
            ),
            Text(
              '${dhikr.sourceName} — ${dhikr.reference}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
