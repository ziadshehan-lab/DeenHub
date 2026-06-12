import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// وسيطات شاشة تفاصيل السورة.
class SurahDetailArgs {
  const SurahDetailArgs({required this.surahNumber, this.surahName});

  final int surahNumber;
  final String? surahName;
}

/// شاشة تفاصيل السورة: ستعرض آيات السورة من QuranRepository.
class SurahDetailScreen extends StatelessWidget {
  const SurahDetailScreen({super.key, this.args});

  final SurahDetailArgs? args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(args?.surahName ?? AppStrings.surahDetail),
      ),
      body: const PlaceholderContent(icon: Icons.menu_book),
    );
  }
}
