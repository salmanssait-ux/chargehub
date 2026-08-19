import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';
import '../features/auth/presentation/pages/loading_page.dart';

class ChargeHubApp extends ConsumerWidget {
  const ChargeHubApp({super.key});

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final selectedTheme =
    ref.watch(themeProvider);

    return MaterialApp(
      title: 'ChargeHub',
      debugShowCheckedModeBanner: false,

      theme: ChargeHubThemes.getTheme(
        selectedTheme,
      ),

      home: const LoadingPage(),
    );
  }
}