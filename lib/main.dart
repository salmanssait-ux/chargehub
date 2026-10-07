import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/providers/common_providers.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabasePublishableKey =
      dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ??
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ??
      '';
  SupabaseClient? supabaseClient;
  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    supabaseClient = Supabase.instance.client;
  }

  final prefs = await SharedPreferences.getInstance();

  final savedThemeName = prefs.getString('chargehub_theme');

  ChargeHubTheme initialTheme = ChargeHubTheme.lavender;

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
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(supabaseClient),
        themeProvider.overrideWith((ref) => ThemeNotifier(prefs, initialTheme)),
      ],
      child: const ChargeHubApp(),
    ),
  );
}
