import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة الأذكار: ستعرض تصنيفات الأذكار من AdhkarRepository.
class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adhkar)),
      body: const PlaceholderContent(icon: Icons.self_improvement),
    );
  }
}
