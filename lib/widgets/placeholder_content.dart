import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';

/// محتوى مؤقت يُعرض في الشاشات قبل ربطها بمصادر البيانات الرسمية.
class PlaceholderContent extends StatelessWidget {
  const PlaceholderContent({
    super.key,
    required this.icon,
    this.message = AppStrings.comingSoon,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
