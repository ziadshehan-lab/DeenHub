import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة المكتبة الإسلامية: ستعرض التصنيفات والكتب من LibraryRepository.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.library)),
      body: const PlaceholderContent(icon: Icons.local_library),
    );
  }
}
