import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/quran_repository.dart';
import '../models/quran_models.dart';
import '../providers/favorites_provider.dart';
import '../providers/quran_provider.dart';
import '../widgets/ayah_actions_sheet.dart';

/// وسيطات شاشة تفاصيل السورة.
class SurahDetailArgs {
  const SurahDetailArgs({
    required this.surahNumber,
    this.surahName,
    this.initialAyah,
  });

  final int surahNumber;
  final String? surahName;

  /// رقم آية للانتقال إليها مباشرة عند الفتح.
  final int? initialAyah;
}

/// شاشة قراءة السورة: وضع قراءة نظيف بخط أميري مع إجراءات لكل آية
/// (مفضلة، نسخ، مشاركة، تحديد موضع القراءة).
class SurahDetailScreen extends StatefulWidget {
  const SurahDetailScreen({super.key, this.args});

  final SurahDetailArgs? args;

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final ItemScrollController _scrollController = ItemScrollController();

  SurahModel? _surah;
  List<AyahModel> _ayahs = [];
  String? _basmala;
  bool _isLoading = true;
  String? _error;

  int get _surahNumber => widget.args?.surahNumber ?? 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = context.read<QuranRepository>();
      final results = await Future.wait([
        repository.getSurah(_surahNumber),
        repository.getAyahs(_surahNumber),
        repository.getBasmala(),
      ]);
      if (!mounted) return;
      setState(() {
        _surah = results[0] as SurahModel;
        _ayahs = results[1] as List<AyahModel>;
        _basmala = results[2] as String;
        _isLoading = false;
      });
      _updateLastReadOnOpen();
      _jumpToInitialAyah();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AppStrings.loadError;
      });
    }
  }

  /// عند فتح السورة يُحدَّث موضع آخر قراءة إلى بدايتها، مع الإبقاء على
  /// الآية المحفوظة إذا كانت ضمن السورة نفسها.
  void _updateLastReadOnOpen() {
    final provider = context.read<QuranProvider>();
    final current = provider.lastRead;
    final keepAyah = current != null && current.surahNumber == _surahNumber
        ? current.ayahNumber
        : 1;
    provider.setLastRead(
      surahNumber: _surahNumber,
      ayahNumber: widget.args?.initialAyah ?? keepAyah,
      surahName: _surah?.nameArabic ?? widget.args?.surahName,
    );
  }

  void _jumpToInitialAyah() {
    final initialAyah = widget.args?.initialAyah;
    if (initialAyah == null || initialAyah <= 1) return;
    final index = _ayahs.indexWhere((a) => a.ayahNumber == initialAyah);
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.isAttached) {
        // +1 لتجاوز عنصر الرأس (البسملة ومعلومات السورة)
        _scrollController.jumpTo(index: index + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _surah?.nameArabic ??
        widget.args?.surahName ??
        AppStrings.surahDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontFamily: AppTheme.quranFontFamily),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _ayahs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader();
        return _AyahTile(
          ayah: _ayahs[index - 1],
          surahName: _surah?.nameArabic,
        );
      },
    );
  }

  Widget _buildHeader() {
    final surah = _surah;
    final colorScheme = Theme.of(context).colorScheme;
    final showBasmala =
        _basmala != null && _surahNumber != 1 && _surahNumber != 9;

    return Column(
      children: [
        if (surah != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${surah.revelationPlace} • ${toArabicDigits(surah.ayahCount)} ${AppStrings.ayatLabel}'
              '${_ayahs.isNotEmpty && _ayahs.first.juz != null ? ' • ${AppStrings.juzLabel} ${toArabicDigits(_ayahs.first.juz!)}' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
          ),
        if (showBasmala)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _basmala!,
              textAlign: TextAlign.center,
              style: AppTheme.quranTextStyle(context, fontSize: 26)
                  .copyWith(color: colorScheme.primary),
            ),
          ),
        const Divider(),
      ],
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({required this.ayah, this.surahName});

  final AyahModel ayah;
  final String? surahName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFavorite =
        context.watch<FavoritesProvider>().isFavorite(ayah.favoriteId);
    final lastRead = context.watch<QuranProvider>().lastRead;
    final isLastRead = lastRead != null &&
        lastRead.surahNumber == ayah.surahNumber &&
        lastRead.ayahNumber == ayah.ayahNumber;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          showAyahActionsSheet(context, ayah: ayah, surahName: surahName),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: isLastRead
            ? BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: ayah.textArabic),
                  TextSpan(
                    text: ' ${ayahNumberOrnament(ayah.ayahNumber)}',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ],
              ),
              style: AppTheme.quranTextStyle(context),
            ),
            if (isFavorite || isLastRead)
              Row(
                children: [
                  if (isLastRead)
                    Icon(Icons.bookmark,
                        size: 16, color: colorScheme.primary),
                  if (isFavorite)
                    Icon(Icons.favorite,
                        size: 16, color: colorScheme.error),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
