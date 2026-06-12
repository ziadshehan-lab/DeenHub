import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/alquran_cloud_tafsir_data_source.dart';
import 'data/datasources/local_quran_data_source.dart';
import 'data/datasources/local_tafsir_data_source.dart';
import 'data/datasources/remote_quran_data_source.dart';
import 'data/datasources/remote_tafsir_data_source.dart';
import 'data/repositories/quran_repository.dart';
import 'data/repositories/quran_repository_impl.dart';
import 'data/repositories/tafsir_repository.dart';
import 'data/repositories/tafsir_repository_impl.dart';
import 'providers/favorites_provider.dart';
import 'providers/quran_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tafsir_provider.dart';
import 'services/cache_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeenHubApp());
}

class DeenHubApp extends StatelessWidget {
  const DeenHubApp({super.key, this.quranRepository, this.tafsirRepository});

  /// مستودعات بديلة — تُستخدم في الاختبارات لحقن مصادر وهمية أو محلية فقط.
  final QuranRepository? quranRepository;
  final TafsirRepository? tafsirRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
        Provider<QuranRepository>(
          create: (_) =>
              quranRepository ??
              QuranRepositoryImpl(
                remote: RemoteQuranDataSource(),
                local: LocalQuranDataSource(),
              ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              QuranProvider(repository: context.read<QuranRepository>())
                ..init(),
        ),
        Provider<TafsirRepository>(
          create: (_) =>
              tafsirRepository ??
              TafsirRepositoryImpl(
                remotes: [
                  RemoteTafsirDataSource(),
                  AlQuranCloudTafsirDataSource(),
                ],
                local: LocalTafsirDataSource(),
                cache: SharedPrefsCacheService(),
              ),
        ),
        ChangeNotifierProvider(create: (_) => TafsirProvider()..load()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,

            // اللغة العربية والاتجاه من اليمين إلى اليسار
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },

            initialRoute: AppRoutes.home,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
