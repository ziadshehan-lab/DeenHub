import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/arabic_numbers.dart';

/// شاشة المسبحة الإلكترونية: عدّاد تسبيح محفوظ محلياً يستأنف من
/// آخر قيمة بعد إغلاق التطبيق.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(AppConstants.prefKeyTasbihCount) ?? 0;
    if (mounted && saved != _count) {
      setState(() => _count = saved);
    }
  }

  Future<void> _setCount(int value) async {
    setState(() => _count = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefKeyTasbihCount, value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tasbih),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.reset,
            onPressed: () => _setCount(0),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.tasbihCount,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              toArabicDigits(_count),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 160,
              height: 160,
              child: FilledButton(
                style: FilledButton.styleFrom(shape: const CircleBorder()),
                onPressed: () => _setCount(_count + 1),
                child: const Icon(Icons.fingerprint, size: 64),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
