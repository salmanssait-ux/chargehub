import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: '.env',
  );

  final prefs = await SharedPreferences.getInstance();

  final savedThemeName = prefs.getString(
    'chargehub_theme',
  );

  ChargeHubTheme initialTheme =
      ChargeHubTheme.lavender;

  if (savedThemeName != null) {
    for (final theme in ChargeHubTheme.values) {
      if (theme.name == savedThemeName) {
        initialTheme = theme;
        break;
      }
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith(
          (ref) => ThemeNotifier(
            prefs,
            initialTheme,
          ),
        ),
      ],
      child: const ChargeHubApp(),
    ),
  );
}