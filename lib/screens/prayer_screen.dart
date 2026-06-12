import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/utils/arabic_numbers.dart';
import '../models/city_model.dart';
import '../providers/prayer_provider.dart';

/// شاشة مواقيت الصلاة: التاريخ الميلادي والهجري، الصلاة التالية مع
/// عدّاد تنازلي، المواقيت الستة، اختيار الموقع يدوياً عند تعذر تحديده.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // عدّاد تنازلي حي للصلاة التالية
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _showCityPicker(BuildContext context) {
    final provider = context.read<PrayerProvider>();
    provider.loadCities();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final cities = sheetContext.watch<PrayerProvider>().cities;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            child: _CityList(
              cities: cities,
              onUseMyLocation: () {
                Navigator.of(sheetContext).pop();
                provider.useCurrentLocation();
              },
              onCitySelected: (city) {
                Navigator.of(sheetContext).pop();
                provider.selectCity(city);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.prayer),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: AppStrings.qibla,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.qibla),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: AppStrings.prayerSettings,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.prayerSettings),
          ),
        ],
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, PrayerProvider provider) {
    // لا موقع: واجهة الاختيار اليدوي للمدينة
    if (provider.needsManualLocation && provider.coordinates == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  AppStrings.chooseCity,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.chooseCityHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _CityList(
              cities: provider.cities,
              onUseMyLocation: provider.useCurrentLocation,
              onCitySelected: provider.selectCity,
            ),
          ),
        ],
      );
    }

    if (provider.isLoading || provider.result == null) {
      if (provider.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.error!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: provider.loadPrayerTimes,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final result = provider.result!;
    final times = result.times;
    final now = DateTime.now();
    final next = PrayerProvider.nextPrayerAfter(times, now);
    final remaining = next.time.difference(now);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String countdown() {
      final h = remaining.inHours.toString().padLeft(2, '0');
      final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
      final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      return toArabicDigitsInText('$h:$m:$s');
    }

    final gregorian = toArabicDigitsInText(
      '${times.date.year}/${times.date.month.toString().padLeft(2, '0')}'
      '/${times.date.day.toString().padLeft(2, '0')}',
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (result.fromCache)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.cachedTimesWarning}'
                    '${result.isStale ? ' (${AppStrings.staleTimesWarning})' : ''}',
                    style:
                        TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        // بطاقة التاريخ والموقع
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 18, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        provider.locationLabel ?? '',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showCityPicker(context),
                      child: const Text(AppStrings.changeLocation),
                    ),
                  ],
                ),
                if (times.hijriDate != null)
                  Text(times.hijriDate!, style: textTheme.bodyLarge),
                Text(
                  gregorian,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                if (times.methodName != null)
                  Text(
                    '${AppStrings.calculationMethodLabel}: ${times.methodName}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // بطاقة الصلاة التالية مع العدّاد
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  AppStrings.nextPrayerLabel,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppStrings.prayerNames[next.key]} — ${arabicTime(next.time)}',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppStrings.remainingLabel}: ${countdown()}',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // المواقيت الستة
        for (final (key, time) in times.orderedTimes)
          Card(
            color: key == next.key ? colorScheme.secondaryContainer : null,
            child: ListTile(
              leading: Icon(
                switch (key) {
                  'fajr' => Icons.dark_mode_outlined,
                  'sunrise' => Icons.wb_twilight,
                  'dhuhr' => Icons.light_mode_outlined,
                  'asr' => Icons.wb_sunny_outlined,
                  'maghrib' => Icons.nights_stay_outlined,
                  _ => Icons.bedtime_outlined,
                },
                color: colorScheme.primary,
              ),
              title: Text(AppStrings.prayerNames[key] ?? key),
              trailing: Text(
                arabicTime(time),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.sourceLabel}: ${times.source.sourceName}',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// قائمة المدن مع خيار استخدام الموقع الحالي.
class _CityList extends StatelessWidget {
  const _CityList({
    required this.cities,
    required this.onUseMyLocation,
    required this.onCitySelected,
  });

  final List<CityModel> cities;
  final VoidCallback onUseMyLocation;
  final ValueChanged<CityModel> onCitySelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: Icon(
            Icons.my_location,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text(AppStrings.useMyLocation),
          onTap: onUseMyLocation,
        ),
        const Divider(height: 1),
        for (final city in cities)
          ListTile(
            leading: const Icon(Icons.location_city_outlined),
            title: Text(city.nameArabic),
            subtitle: Text(city.country),
            onTap: () => onCitySelected(city),
          ),
      ],
    );
  }
}
