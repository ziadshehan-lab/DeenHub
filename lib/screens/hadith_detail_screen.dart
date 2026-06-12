import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../data/datasources/hadith_data_source.dart';
import '../data/repositories/hadith_repository.dart';
import '../models/hadith_models.dart';
import '../providers/favorites_provider.dart';
import '../providers/hadith_provider.dart';

/// وسيطات شاشة تفاصيل الحديث: إما معرّف يُجلب به الحديث من المستودع،
/// أو نموذج كامل للعرض المباشر (نتائج بحث الدرر السنية).
class HadithDetailArgs {
  const HadithDetailArgs({this.hadithId, this.inlineHadith});

  final String? hadithId;
  final HadithModel? inlineHadith;
}

/// شاشة تفاصيل الحديث: النص العربي (والإنجليزي إن توفر)، الراوي،
/// الدرجة، الشرح، بطاقة الإسناد الكاملة، وإجراءات النسخ والمشاركة
/// والمفضلة، مع حفظ آخر حديث مقروء تلقائياً.
class HadithDetailScreen extends StatefulWidget {
  const HadithDetailScreen({super.key, this.args});

  final HadithDetailArgs? args;

  @override
  State<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends State<HadithDetailScreen> {
  HadithModel? _hadith;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final inline = widget.args?.inlineHadith;
    if (inline != null) {
      setState(() {
        _hadith = inline;
        _isLoading = false;
      });
      return;
    }
    final hadithId = widget.args?.hadithId;
    if (hadithId == null) {
      setState(() {
        _isLoading = false;
        _error = AppStrings.loadError;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hadith =
          await context.read<HadithRepository>().getHadith(hadithId);
      if (!mounted) return;
      setState(() {
        _hadith = hadith;
        _isLoading = false;
      });
      // حفظ آخر حديث مقروء تلقائياً
      context.read<HadithProvider>().setLastRead(
            hadithId: hadith.id,
            title: hadith.title ?? hadith.textArabic,
          );
    } on HadithUnavailableException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AppStrings.loadError;
      });
    }
  }

  String _shareText(HadithModel hadith) {
    final buffer = StringBuffer()..writeln(hadith.textArabic);
    if (hadith.narrator != null) {
      buffer.writeln('${AppStrings.narratorLabel}: ${hadith.narrator}');
    }
    if (hadith.attribution != null) {
      buffer.writeln('${AppStrings.attributionLabel}: ${hadith.attribution}');
    }
    if (hadith.grade != null) {
      buffer.writeln('${AppStrings.gradeLabel}: ${hadith.grade}');
    }
    buffer.write('${AppStrings.sourceLabel}: ${hadith.sourceName}');
    if (hadith.sourceUrl != null) {
      buffer.write(' — ${hadith.sourceUrl}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final hadith = _hadith;
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite =
        hadith != null && favorites.isFavorite(hadith.favoriteId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.hadithDetail),
        actions: [
          if (hadith != null) ...[
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              tooltip: isFavorite
                  ? AppStrings.removeFromFavorites
                  : AppStrings.addToFavorites,
              onPressed: () => context
                  .read<FavoritesProvider>()
                  .toggle(hadith.favoriteId),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: AppStrings.copyHadith,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(
                  ClipboardData(text: _shareText(hadith)),
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text(AppStrings.hadithCopied)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: AppStrings.shareHadith,
              onPressed: () => Share.share(_shareText(hadith)),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }
    final hadith = _hadith!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hadith.title != null) ...[
          Text(hadith.title!, style: textTheme.titleMedium),
          const SizedBox(height: 12),
        ],
        Text(
          hadith.textArabic,
          style: const TextStyle(
            fontFamily: AppTheme.quranFontFamily,
            fontSize: 20,
            height: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (hadith.grade != null)
              Chip(
                avatar: Icon(Icons.verified,
                    size: 18, color: colorScheme.primary),
                label: Text(hadith.grade!),
              ),
            if (hadith.attribution != null)
              Chip(
                avatar: Icon(Icons.menu_book,
                    size: 18, color: colorScheme.primary),
                label: Text(hadith.attribution!),
              ),
          ],
        ),
        if (hadith.narrator != null) ...[
          const SizedBox(height: 12),
          Text(
            '${AppStrings.narratorLabel}: ${hadith.narrator}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (hadith.textEnglish != null) ...[
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text(AppStrings.englishTranslation),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  hadith.textEnglish!,
                  style: textTheme.bodyMedium?.copyWith(height: 1.7),
                ),
              ),
            ],
          ),
        ],
        if (hadith.explanation != null) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text(AppStrings.explanationLabel),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Text(
                hadith.explanation!,
                style: textTheme.bodyMedium?.copyWith(height: 1.8),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _AttributionCard(hadith: hadith),
      ],
    );
  }
}

/// بطاقة الإسناد: المصدر، الكتاب/العزو، رقم الحديث، الدرجة، الرابط.
class _AttributionCard extends StatelessWidget {
  const _AttributionCard({required this.hadith});

  final HadithModel hadith;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget row(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(text: value, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(Icons.verified_outlined, AppStrings.sourceLabel,
                hadith.sourceName),
            if (hadith.attribution != null)
              row(Icons.menu_book, AppStrings.bookLabel, hadith.attribution!),
            row(Icons.tag, AppStrings.hadithNumberLabel, hadith.id),
            if (hadith.grade != null)
              row(Icons.fact_check_outlined, AppStrings.gradeLabel,
                  hadith.grade!),
            row(Icons.bookmark_outline, AppStrings.referenceLabel,
                hadith.reference),
            if (hadith.sourceUrl != null)
              row(Icons.link, AppStrings.sourceLabel, hadith.sourceUrl!),
          ],
        ),
      ),
    );
  }
}
