import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/arabic_numbers.dart';
import '../providers/quran_provider.dart';
import 'surah_detail_screen.dart';

/// شاشة القرآن الكريم: قائمة السور مع بطاقة متابعة القراءة.
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.quran),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: AppStrings.search,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.search),
          ),
        ],
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, QuranProvider provider) {
    if (provider.isLoadingSurahs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.surahsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.surahsError!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.loadSurahs,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    final lastRead = provider.lastRead;
    final surahs = provider.surahs;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: surahs.length + (lastRead != null ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        if (lastRead != null && index == 0) {
          return _LastReadCard(lastRead: lastRead);
        }
        final surah = surahs[index - (lastRead != null ? 1 : 0)];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              toArabicDigits(surah.number),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            surah.nameArabic,
            style: const TextStyle(
              fontFamily: AppTheme.quranFontFamily,
              fontSize: 20,
            ),
          ),
          subtitle: Text(
            '${surah.revelationPlace} • ${toArabicDigits(surah.ayahCount)} ${AppStrings.ayatLabel}',
          ),
          trailing: surah.nameTransliteration != null
              ? Text(
                  surah.nameTransliteration!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                )
              : null,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.surahDetail,
            arguments: SurahDetailArgs(
              surahNumber: surah.number,
              surahName: surah.nameArabic,
            ),
          ),
        );
      },
    );
  }
}

class _LastReadCard extends StatelessWidget {
  const _LastReadCard({required this.lastRead});

  final LastReadPosition lastRead;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.bookmark, color: colorScheme.primary),
        title: const Text(AppStrings.continueReading),
        subtitle: Text(
          '${lastRead.surahName ?? '${AppStrings.surahLabel} ${toArabicDigits(lastRead.surahNumber)}'}'
          ' — ${AppStrings.ayahLabel} ${toArabicDigits(lastRead.ayahNumber)}',
        ),
        trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.surahDetail,
          arguments: SurahDetailArgs(
            surahNumber: lastRead.surahNumber,
            surahName: lastRead.surahName,
            initialAyah: lastRead.ayahNumber,
          ),
        ),
      ),
    );
  }
}
