import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF5F2FB);
  static const Color surface = Color(0xFFEDE9F6);
  static const Color surfaceVariant = Color(0xFFE5E1F0);

  static const Color primary = Color(0xFF62698F);
  static const Color primaryDark = Color(0xFF515876);

  static const Color text = Color(0xFF25242B);
  static const Color secondaryText = Color(0xFF6F6D78);
  static const Color outline = Color(0xFFC9C5D3);

  static final ThemeData light = ThemeData(
    useMaterial3: true,

    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,

      primaryContainer: Color(0xFFDCD9EA),
      onPrimaryContainer: Color(0xFF292B3B),

      secondary: Color(0xFF747A9F),
      onSecondary: Colors.white,

      secondaryContainer: Color(0xFFE0DDEC),
      onSecondaryContainer: Color(0xFF30313E),

      surface: background,
      onSurface: text,

      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceVariant,
      surfaceContainerHighest: Color(0xFFDCD8E7),

      outline: outline,
      outlineVariant: Color(0xFFD9D5E2),

      error: Color(0xFFB85C63),
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: background,

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(16),
        ),
        side: BorderSide(
          color: outline.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: outline,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: outline,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),

      labelStyle: TextStyle(
        color: secondaryText,
      ),

      hintStyle: TextStyle(
        color: secondaryText,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(
          color: outline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: outline,
      thickness: 1,
    ),
  );
}