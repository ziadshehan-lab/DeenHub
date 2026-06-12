import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة اتجاه القبلة: ستعرض البوصلة بالاعتماد على PrayerRepository
/// وحساسات الجهاز.
class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.qibla)),
      body: const PlaceholderContent(icon: Icons.explore),
    );
  }
}
