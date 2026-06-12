import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/datasources/tafsir_data_source.dart';
import '../data/repositories/tafsir_repository.dart';
import '../models/tafsir_models.dart';

/// وسيطات شاشة تفسير الآية.
class TafsirDetailArgs {
  const TafsirDetailArgs({
    required this.surahNumber,
    required this.ayahNumber,
    this.surahName,
  });

  final int surahNumber;
  final int ayahNumber;
  final String? surahName;
}

/// شاشة تفسير آية: اختيار كتاب التفسير وعرض النص مع الإسناد الكامل
/// (الكتاب، العالِم، المصدر، المرجع، الرابط).
class TafsirDetailScreen extends StatefulWidget {
  const TafsirDetailScreen({super.key, this.args});

  final TafsirDetailArgs? args;

  @override
  State<TafsirDetailScreen> createState() => _TafsirDetailScreenState();
}

class _TafsirDetailScreenState extends State<TafsirDetailScreen> {
  List<TafsirEditionModel> _editions = [];
  String? _selectedEditionId;
  TafsirModel? _tafsir;
  bool _isLoading = true;
  String? _error;

  int get _surahNumber => widget.args?.surahNumber ?? 1;
  int get _ayahNumber => widget.args?.ayahNumber ?? 1;

  @override
  void initState() {
    super.initState();
    _loadEditions();
  }

  Future<void> _loadEditions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final editions =
          await context.read<TafsirRepository>().getEditions();
      if (!mounted) return;
      final firstAvailable =
          editions.where((e) => e.available).firstOrNull;
      setState(() => _editions = editions);
      if (firstAvailable != null) {
        await _selectEdition(firstAvailable.id);
      } else {
        setState(() {
          _isLoading = false;
          _error = AppStrings.tafsirUnavailable;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AppStrings.loadError;
      });
    }
  }

  Future<void> _selectEdition(String editionId) async {
    setState(() {
      _selectedEditionId = editionId;
      _isLoading = true;
      _error = null;
      _tafsir = null;
    });
    try {
      final tafsir = await context.read<TafsirRepository>().getTafsir(
            editionId: editionId,
            surahNumber: _surahNumber,
            ayahNumber: _ayahNumber,
          );
      if (!mounted) return;
      setState(() {
        _tafsir = tafsir;
        _isLoading = false;
      });
    } on TafsirUnavailableException catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final surahLabel = widget.args?.surahName ??
        '${AppStrings.surahLabel} ${toArabicDigits(_surahNumber)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.tafsirOfAyah} ${toArabicDigits(_ayahNumber)} — $surahLabel',
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_editions.isNotEmpty) _buildEditionSelector(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildEditionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final edition in _editions)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(
                  edition.available
                      ? edition.nameArabic
                      : '${edition.nameArabic} (${AppStrings.tafsirComingSoon})',
                ),
                selected: edition.id == _selectedEditionId,
                onSelected: edition.available
                    ? (_) => _selectEdition(edition.id)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final editionId = _selectedEditionId;
                  if (editionId != null) {
                    _selectEdition(editionId);
                  } else {
                    _loadEditions();
                  }
                },
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }
    final tafsir = _tafsir;
    if (tafsir == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tafsir.text,
          style: textTheme.bodyLarge?.copyWith(height: 1.9, fontSize: 17),
        ),
        const SizedBox(height: 24),
        _AttributionCard(tafsir: tafsir),
      ],
    );
  }
}

/// بطاقة الإسناد: الكتاب، العالِم، المصدر، المرجع، الرابط.
class _AttributionCard extends StatelessWidget {
  const _AttributionCard({required this.tafsir});

  final TafsirModel tafsir;

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
            row(Icons.menu_book, AppStrings.tafsirBook, tafsir.editionName),
            if (tafsir.scholar != null)
              row(Icons.person, AppStrings.scholarLabel, tafsir.scholar!),
            row(Icons.verified_outlined, AppStrings.sourceLabel,
                tafsir.sourceName),
            row(Icons.bookmark_outline, AppStrings.referenceLabel,
                tafsir.reference),
            if (tafsir.sourceUrl != null)
              row(Icons.link, AppStrings.sourceLabel, tafsir.sourceUrl!),
          ],
        ),
      ),
    );
  }
}
