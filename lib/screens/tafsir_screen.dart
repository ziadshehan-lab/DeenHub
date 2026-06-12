import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة التفسير: ستعرض كتب التفسير المتاحة من TafsirRepository.
class TafsirScreen extends StatelessWidget {
  const TafsirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tafsir)),
      body: const PlaceholderContent(icon: Icons.auto_stories),
    );
  }
}
