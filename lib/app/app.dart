import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import '../features/home/presentation/pages/home_page.dart';

class ChargeHubApp extends StatelessWidget {
  const ChargeHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChargeHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}