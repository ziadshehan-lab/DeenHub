import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة أسماء الله الحسنى: ستعرض الأسماء وشرحها من AdhkarRepository.
class NamesOfAllahScreen extends StatelessWidget {
  const NamesOfAllahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.namesOfAllah)),
      body: const PlaceholderContent(icon: Icons.star_border),
    );
  }
}
