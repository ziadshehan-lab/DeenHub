import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/routing/app_routes.dart';
import '../core/utils/arabic_numbers.dart';
import '../data/repositories/prayer_repository.dart';
import '../providers/prayer_provider.dart';

/// شاشة اتجاه القبلة: قرص بوصلة يُظهر الاتجاه المحسوب محلياً من موقع
/// المستخدم نحو الكعبة، مع الدرجة والمسافة والإرشادات (عند غياب
/// بوصلة في الجهاز تكفي الزاوية المعروضة مع بوصلة خارجية).
class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final coords = provider.coordinates;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.qibla)),
      body: coords == null
          ? _buildNoLocation(context, provider)
          : _buildCompass(context, provider, coords),
    );
  }

  Widget _buildNoLocation(BuildContext context, PrayerProvider provider) {
    if (!provider.needsManualLocation) {
      // تحديد الموقع ما يزال جارياً
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.locateFirst,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.schedule),
              label: const Text(AppStrings.openPrayerScreen),
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.prayer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass(
    BuildContext context,
    PrayerProvider provider,
    ({double latitude, double longitude}) coords,
  ) {
    final qibla = context.read<PrayerRepository>().getQiblaDirection(
          latitude: coords.latitude,
          longitude: coords.longitude,
        );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final degrees = qibla.directionDegrees;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (provider.locationLabel != null)
          Text(
            provider.locationLabel!,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
        const SizedBox(height: 24),
        // قرص البوصلة مع سهم القبلة
        Center(
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 3,
                    ),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ),
                // علامة الشمال
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'ش',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // سهم القبلة مُداراً بزاوية الاتجاه (مع عقارب الساعة من الشمال)
                Transform.rotate(
                  angle: degrees * math.pi / 180,
                  child: Icon(
                    Icons.navigation,
                    size: 120,
                    color: colorScheme.primary,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text('🕋', style: textTheme.headlineSmall),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${toArabicDigitsInText(degrees.toStringAsFixed(1))}°',
          textAlign: TextAlign.center,
          style: textTheme.displaySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          AppStrings.qiblaDegreesLabel,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.distanceToKaaba}: '
          '${toArabicDigitsInText(qibla.distanceKm.round().toString())} ${AppStrings.kmUnit}',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(AppStrings.qiblaInstructions),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.sourceLabel}: ${qibla.source.sourceName}',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
      ],
    );
  }
}
