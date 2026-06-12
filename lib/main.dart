import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_quran_data_source.dart';
import 'data/datasources/remote_quran_data_source.dart';
import 'data/repositories/quran_repository.dart';
import 'data/repositories/quran_repository_impl.dart';
import 'providers/favorites_provider.dart';
import 'providers/quran_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeenHubApp());
}

class DeenHubApp extends StatelessWidget {
  const DeenHubApp({super.key, this.quranRepository});

  /// مستودع قرآن بديل — يُستخدم في الاختبارات لحقن مصادر وهمية أو محلية فقط.
  final QuranRepository? quranRepository;

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
