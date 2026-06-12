import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/constants/calculation_methods.dart';
import '../providers/prayer_provider.dart';

/// إعدادات الصلاة: طريقة الحساب وتفعيل تذكيرات كل صلاة.
class PrayerSettingsScreen extends StatelessWidget {
  const PrayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.prayerSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.calculationMethodLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final method in calculationMethods)
            RadioListTile<int>(
              title: Text(method.nameArabic),
              value: method.id,
              groupValue: provider.methodId,
              onChanged: (id) =>
                  context.read<PrayerProvider>().setMethod(id!),
            ),
          const Divider(height: 32),
          Text(
            AppStrings.prayerNotifications,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.notificationsNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final prayer in PrayerProvider.notifiablePrayers)
            SwitchListTile(
              title: Text(AppStrings.prayerNames[prayer] ?? prayer),
              value: provider.notificationToggles[prayer] ?? false,
              onChanged: (_) =>
                  context.read<PrayerProvider>().toggleNotification(prayer),
            ),
        ],
      ),
    );
  }
}
