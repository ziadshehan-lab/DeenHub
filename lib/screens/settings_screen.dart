import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../providers/settings_provider.dart';

/// شاشة الإعدادات: اختيار المظهر (فاتح/داكن/النظام) وحجم الخط.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.theme,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          RadioListTile<ThemeMode>(
            title: const Text(AppStrings.systemMode),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (mode) =>
                context.read<SettingsProvider>().setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text(AppStrings.lightMode),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (mode) =>
                context.read<SettingsProvider>().setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text(AppStrings.darkMode),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (mode) =>
                context.read<SettingsProvider>().setThemeMode(mode!),
          ),
          const Divider(height: 32),
          Text(
            AppStrings.fontSize,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: settings.fontScale,
            min: 0.8,
            max: 1.6,
            divisions: 8,
            label: settings.fontScale.toStringAsFixed(1),
            onChanged: (value) =>
                context.read<SettingsProvider>().setFontScale(value),
          ),
        ],
      ),
    );
  }
}
