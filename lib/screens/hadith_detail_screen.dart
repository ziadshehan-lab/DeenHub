import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// وسيطات شاشة تفاصيل الحديث.
class HadithDetailArgs {
  const HadithDetailArgs({
    required this.collectionId,
    required this.hadithId,
  });

  final String collectionId;
  final String hadithId;
}

/// شاشة تفاصيل الحديث: ستعرض نص الحديث وإسناده من HadithRepository.
class HadithDetailScreen extends StatelessWidget {
  const HadithDetailScreen({super.key, this.args});

  final HadithDetailArgs? args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.hadithDetail)),
      body: const PlaceholderContent(icon: Icons.history_edu),
    );
  }
}
