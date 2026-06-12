import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../data/repositories/hadith_repository.dart';
import '../models/hadith_models.dart';
import 'hadith_detail_screen.dart';

/// وسيطات شاشة قائمة أحاديث باب.
class HadithListArgs {
  const HadithListArgs({required this.chapterId, this.chapterTitle});

  final String chapterId;
  final String? chapterTitle;
}

/// شاشة أحاديث باب محدد مع تحميل الصفحات تباعاً.
class HadithListScreen extends StatefulWidget {
  const HadithListScreen({super.key, this.args});

  final HadithListArgs? args;

  static const int pageSize = 20;

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  final List<HadithModel> _hadiths = [];
  int _nextPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  String get _chapterId => widget.args?.chapterId ?? '';

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await context.read<HadithRepository>().getHadiths(
            _chapterId,
            page: _nextPage,
            pageSize: HadithListScreen.pageSize,
          );
      if (!mounted) return;
      setState(() {
        _hadiths.addAll(page);
        _hasMore = page.length >= HadithListScreen.pageSize;
        _nextPage++;
        _isLoading = false;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args?.chapterTitle ?? AppStrings.hadith),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hadiths.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hadiths.isEmpty && _error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadMore,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    if (_hadiths.isEmpty) {
      return const Center(child: Text(AppStrings.noContentYet));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 300) _loadMore();
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _hadiths.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _hadiths.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final hadith = _hadiths[index];
          return ListTile(
            leading: Icon(
              Icons.format_quote,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              hadith.title ?? hadith.textArabic,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.hadithDetail,
              arguments: HadithDetailArgs(hadithId: hadith.id),
            ),
          );
        },
      ),
    );
  }
}
