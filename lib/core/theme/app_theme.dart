import 'package:flutter/material.dart';

/// سمات التطبيق (Material 3) — وضع فاتح وداكن بألوان مستوحاة من
/// الطابع الإسلامي (أخضر زمردي وذهبي).
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF0E7C5A); // أخضر زمردي
  static const Color _goldAccent = Color(0xFFC9A227); // ذهبي

  /// خط عربي محسّن لعرض النص القرآني.
  static const String quranFontFamily = 'Amiri';

  /// نمط نص القراءة القرآنية: خط أميري بمسافة أسطر مريحة.
  static TextStyle quranTextStyle(BuildContext context, {double? fontSize}) {
    return TextStyle(
      fontFamily: quranFontFamily,
      fontSize: fontSize ?? 24,
      height: 2.0,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ).copyWith(tertiary: _goldAccent);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.primaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
