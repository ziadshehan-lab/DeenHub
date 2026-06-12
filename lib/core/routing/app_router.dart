import 'package:flutter/material.dart';

import '../../screens/adhkar_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/hadith_books_screen.dart';
import '../../screens/hadith_chapters_screen.dart';
import '../../screens/hadith_detail_screen.dart';
import '../../screens/hadith_list_screen.dart';
import '../../screens/hadith_search_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/library_screen.dart';
import '../../screens/names_of_allah_screen.dart';
import '../../screens/prayer_screen.dart';
import '../../screens/prayer_settings_screen.dart';
import '../../screens/qibla_screen.dart';
import '../../screens/quran_screen.dart';
import '../../screens/search_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/surah_detail_screen.dart';
import '../../screens/tafsir_detail_screen.dart';
import '../../screens/tafsir_screen.dart';
import '../../screens/tasbih_screen.dart';
import 'app_routes.dart';

/// موجّه التطبيق: يحوّل أسماء المسارات إلى شاشات.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget screen = switch (settings.name) {
      AppRoutes.home => const HomeScreen(),
      AppRoutes.quran => const QuranScreen(),
      AppRoutes.surahDetail =>
        SurahDetailScreen(args: settings.arguments as SurahDetailArgs?),
      AppRoutes.tafsir => const TafsirScreen(),
      AppRoutes.tafsirDetail =>
        TafsirDetailScreen(args: settings.arguments as TafsirDetailArgs?),
      AppRoutes.hadith => const HadithBooksScreen(),
      AppRoutes.hadithChapters => HadithChaptersScreen(
          args: settings.arguments as HadithChaptersArgs?),
      AppRoutes.hadithList =>
        HadithListScreen(args: settings.arguments as HadithListArgs?),
      AppRoutes.hadithDetail =>
        HadithDetailScreen(args: settings.arguments as HadithDetailArgs?),
      AppRoutes.hadithSearch => const HadithSearchScreen(),
      AppRoutes.prayer => const PrayerScreen(),
      AppRoutes.prayerSettings => const PrayerSettingsScreen(),
      AppRoutes.qibla => const QiblaScreen(),
      AppRoutes.adhkar => const AdhkarScreen(),
      AppRoutes.tasbih => const TasbihScreen(),
      AppRoutes.namesOfAllah => const NamesOfAllahScreen(),
      AppRoutes.library => const LibraryScreen(),
      AppRoutes.search => const SearchScreen(),
      AppRoutes.favorites => const FavoritesScreen(),
      AppRoutes.settings => const SettingsScreen(),
      _ => const HomeScreen(),
    };

    return MaterialPageRoute(settings: settings, builder: (_) => screen);
  }
}
