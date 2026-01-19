import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const String fontFamily = 'Inter'; // Assuming Inter is available or default

  static TextStyle get headlineLarge => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get titleLarge => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );
}
