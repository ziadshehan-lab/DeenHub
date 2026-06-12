import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة القرآن الكريم: ستعرض قائمة السور من QuranRepository.
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.quran)),
      body: const PlaceholderContent(icon: Icons.menu_book),
    );
  }
}
