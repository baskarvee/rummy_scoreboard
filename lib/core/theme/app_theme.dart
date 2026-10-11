import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFF1565C0);
  static const Color _bg = Color(0xFFF0F4FF);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _inkSoft = Color(0xFF5A6080);
  static const Color _outline = Color(0xFFDDE3F0);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Score colors
  static const Color scorePositive = Color(0xFF2E7D32);
  static const Color scoreNegative = Color(0xFFC62828);
  static const Color scoreNeutral = Color(0xFF78909C);

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE1ECF8),
      onPrimaryContainer: Color(0xFF003087),
      secondary: _inkSoft,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE1ECF8),
      onSecondaryContainer: Color(0xFF003087),
      tertiary: _primary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE1ECF8),
      onTertiaryContainer: Color(0xFF003087),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surface: _bg,
      onSurface: _ink,
      onSurfaceVariant: _inkSoft,
      surfaceContainerHighest: _card,
      surfaceContainerHigh: _card,
      surfaceContainer: _card,
      surfaceContainerLow: Color(0xFFF8FAFF),
      surfaceContainerLowest: Colors.white,
      outline: _outline,
      outlineVariant: Color(0xFFEEF2FA),
      inverseSurface: _ink,
      onInverseSurface: _bg,
      inversePrimary: Color(0xFF90CAF9),
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        color: _card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: _inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _outline),
    );
  }

  // Gradient header decoration
  static BoxDecoration get headerDecoration => const BoxDecoration(
        gradient: headerGradient,
      );

  // Player avatar colors — cycling palette
  static const List<Color> avatarColors = [
    Color(0xFF1565C0), // blue
    Color(0xFF6A1B9A), // purple
    Color(0xFF2E7D32), // green
    Color(0xFFE65100), // orange
    Color(0xFFC62828), // red
    Color(0xFF00838F), // teal
    Color(0xFFAD1457), // pink
    Color(0xFF4527A0), // deep purple
    Color(0xFF558B2F), // light green
    Color(0xFF4E342E), // brown
  ];

  static Color avatarColor(int index) => avatarColors[index % avatarColors.length];
}
