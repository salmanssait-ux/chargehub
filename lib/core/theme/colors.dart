import 'package:flutter/material.dart';

/// Centralized color palette for ChargeHub.
///
/// Every color used in the application should come from here.
/// Avoid using Colors.blue, Colors.green, etc. directly in widgets.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
}