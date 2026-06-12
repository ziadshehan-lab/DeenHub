import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة مواقيت الصلاة: ستعرض المواقيت اليومية من PrayerRepository.
class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.prayer)),
      body: const PlaceholderContent(icon: Icons.schedule),
    );
  }
}
