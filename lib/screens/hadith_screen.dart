import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة الحديث الشريف: ستعرض مجموعات الأحاديث من HadithRepository.
class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.hadith)),
      body: const PlaceholderContent(icon: Icons.history_edu),
    );
  }
}
