import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة المفضلة: ستعرض العناصر المحفوظة عبر FavoritesProvider.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.favorites)),
      body: const PlaceholderContent(
        icon: Icons.favorite_border,
        message: AppStrings.noContentYet,
      ),
    );
  }
}
