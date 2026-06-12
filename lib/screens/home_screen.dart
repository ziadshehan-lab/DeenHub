import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../widgets/feature_card.dart';

/// الشاشة الرئيسية: شبكة أقسام التطبيق.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<({String title, IconData icon, String route})> _features =
      [
    (title: AppStrings.quran, icon: Icons.menu_book, route: AppRoutes.quran),
    (
      title: AppStrings.tafsir,
      icon: Icons.auto_stories,
      route: AppRoutes.tafsir
    ),
    (title: AppStrings.hadith, icon: Icons.history_edu, route: AppRoutes.hadith),
    (title: AppStrings.prayer, icon: Icons.schedule, route: AppRoutes.prayer),
    (title: AppStrings.qibla, icon: Icons.explore, route: AppRoutes.qibla),
    (
      title: AppStrings.adhkar,
      icon: Icons.self_improvement,
      route: AppRoutes.adhkar
    ),
    (
      title: AppStrings.tasbih,
      icon: Icons.radio_button_checked,
      route: AppRoutes.tasbih
    ),
    (
      title: AppStrings.namesOfAllah,
      icon: Icons.star_border,
      route: AppRoutes.namesOfAllah
    ),
    (
      title: AppStrings.library,
      icon: Icons.local_library,
      route: AppRoutes.library
    ),
    (title: AppStrings.search, icon: Icons.search, route: AppRoutes.search),
    (
      title: AppStrings.favorites,
      icon: Icons.favorite_border,
      route: AppRoutes.favorites
    ),
    (
      title: AppStrings.settings,
      icon: Icons.settings,
      route: AppRoutes.settings
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: AppStrings.search,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.settings,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _features.length,
        itemBuilder: (context, index) {
          final feature = _features[index];
          return FeatureCard(
            title: feature.title,
            icon: feature.icon,
            routeName: feature.route,
          );
        },
      ),
    );
  }
}
