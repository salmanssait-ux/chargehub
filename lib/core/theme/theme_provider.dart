import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum ChargeHubTheme {
  lavender,
  midnight,
  eco,
  sunset,
}

class ThemeNotifier extends StateNotifier<ChargeHubTheme> {
  ThemeNotifier(
    this._prefs,
    ChargeHubTheme initialTheme,
  ) : super(initialTheme);

  final SharedPreferences _prefs;

  static const String _themeKey = 'chargehub_theme';

  Future<void> setTheme(ChargeHubTheme theme) async {
    state = theme;

    await _prefs.setString(
      _themeKey,
      theme.name,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ChargeHubTheme>(
  (ref) => throw UnimplementedError(),
);

class ChargeHubThemes {
  static ThemeData getTheme(
      ChargeHubTheme theme,
      ) {
    switch (theme) {
      case ChargeHubTheme.lavender:
        return _lavender();

      case ChargeHubTheme.midnight:
        return _midnight();

      case ChargeHubTheme.eco:
        return _eco();

      case ChargeHubTheme.sunset:
        return _sunset();
    }
  }

  static ThemeData _lavender() {
    return _createTheme(
      background: const Color(0xFFF5F2FB),
      surface: const Color(0xFFEDE9F6),
      surfaceVariant: const Color(0xFFE5E1F0),
      primary: const Color(0xFF62698F),
      primaryContainer: const Color(0xFFDCD9EA),
      text: const Color(0xFF25242B),
      secondaryText: const Color(0xFF6F6D78),
      outline: const Color(0xFFC9C5D3),
      secondary: const Color(0xFF747A9F),
      dark: false,
    );
  }

  static ThemeData _midnight() {
    return _createTheme(
      background: const Color(0xFF151722),
      surface: const Color(0xFF202231),
      surfaceVariant: const Color(0xFF292B3D),
      primary: const Color(0xFF9B8AFB),
      primaryContainer: const Color(0xFF373251),
      text: const Color(0xFFF1F0F7),
      secondaryText: const Color(0xFFAAA8B8),
      outline: const Color(0xFF45475A),
      secondary: const Color(0xFF78A6D8),
      dark: true,
    );
  }

  static ThemeData _eco() {
    return _createTheme(
      background: const Color(0xFFF1F7F1),
      surface: const Color(0xFFE3EFE3),
      surfaceVariant: const Color(0xFFD7E7D8),
      primary: const Color(0xFF4E7A59),
      primaryContainer: const Color(0xFFCFE1D1),
      text: const Color(0xFF202820),
      secondaryText: const Color(0xFF657066),
      outline: const Color(0xFFB7C9B9),
      secondary: const Color(0xFF6E8F61),
      dark: false,
    );
  }

  static ThemeData _sunset() {
    return _createTheme(
      background: const Color(0xFFFBF3EF),
      surface: const Color(0xFFF2E4DE),
      surfaceVariant: const Color(0xFFEBD8D0),
      primary: const Color(0xFFB86F62),
      primaryContainer: const Color(0xFFE9C8BF),
      text: const Color(0xFF2B2422),
      secondaryText: const Color(0xFF776A66),
      outline: const Color(0xFFD2BDB6),
      secondary: const Color(0xFFC58A58),
      dark: false,
    );
  }

  static ThemeData _createTheme({
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color primary,
    required Color primaryContainer,
    required Color text,
    required Color secondaryText,
    required Color outline,
    required Color secondary,
    required bool dark,
  }) {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme(
        brightness:
        dark ? Brightness.dark : Brightness.light,

        primary: primary,
        onPrimary:
        dark ? Colors.black : Colors.white,

        primaryContainer: primaryContainer,
        onPrimaryContainer: text,

        secondary: secondary,
        onSecondary:
        dark ? Colors.black : Colors.white,

        secondaryContainer: surfaceVariant,
        onSecondaryContainer: text,

        surface: background,
        onSurface: text,

        surfaceContainerLowest: background,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: surfaceVariant,
        surfaceContainerHighest: surfaceVariant,

        outline: outline,
        outlineVariant:
        outline.withValues(alpha: 0.65),

        error: const Color(0xFFC95C65),
        onError: Colors.white,

        inverseSurface: text,
        onInverseSurface: background,

        inversePrimary: primary,

        scrim: Colors.black,
      ),

      scaffoldBackgroundColor: background,

      appBarTheme: AppBarTheme(
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
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: outline.withValues(alpha: 0.45),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: outline,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: outline,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
          foregroundColor:
          dark ? Colors.black : Colors.white,
          minimumSize:
          const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme:
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize:
          const Size.fromHeight(52),
          side: BorderSide(
            color: outline,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
      ),
    );
  }
}