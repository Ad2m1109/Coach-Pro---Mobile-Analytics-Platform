import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF50C878); // Emerald Green
  static const Color primaryDark = Color(0xFF3DA65F);
  static const Color primaryLight = Color(0xFF76D794);

  // Secondary Colors
  static const Color secondary = Color(0xFFE94560); // Crimson Red
  static const Color secondaryDark = Color(0xFFC1324B);
  static const Color secondaryLight = Color(0xFFEE6A7F);

  // Neutral Colors (Light Theme)
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color onBackgroundLight = Color(0xFF1A1A1A);
  static const Color onSurfaceLight = Color(0xFF1A1A1A);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color textGreyLight = Color(0xFF757575);

  // Neutral Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF00122D);
  static const Color surfaceDark = Color(0xFF001630);
  static const Color onBackgroundDark = Colors.white;
  static const Color onSurfaceDark = Colors.white;
  static const Color greyDark = Color(0xFF2C3E50);
  static const Color textGreyDark = Color(0xFFA9A9A9);

  // Functional Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFBC02D);
  static const Color info = Color(0xFF1976D2);

  // Sports-specific Colors
  static const Color goalkeeperYellow = Color(0xFFFFB300);
  static const Color goalkeeperOrange = Color(0xFFFF8C00);
  static const Color teamA = Color(0xFF2196F3);
  static const Color teamB = Color(0xFFFF5722);
  static const Color goalGreen = Color(0xFF4CAF50);
  static const Color cardYellow = Color(0xFFFFC107);
  static const Color cardRed = Color(0xFFF44336);
  static const Color substitutionBlue = Color(0xFF2196F3);
  static const Color statusPending = Colors.grey;
  static const Color statusProcessing = Color(0xFF2196F3);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusFailed = Color(0xFFF44336);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);

  static Color getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return goalGreen;
      case 'yellow_card':
        return cardYellow;
      case 'red_card':
        return cardRed;
      case 'substitution':
        return substitutionBlue;
      default:
        return textGreyLight;
    }
  }

  static Color getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return goalGreen;
      case 'yellow_card':
        return cardYellow;
      case 'red_card':
        return cardRed;
      case 'substitution':
        return substitutionBlue;
      default:
        return textGreyLight;
    }
  }

  static IconData getEventIconData(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return Icons.sports_soccer;
      case 'yellow_card':
        return Icons.square;
      case 'red_card':
        return Icons.square;
      case 'substitution':
        return Icons.swap_horiz;
      default:
        return Icons.event_note;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return statusPending;
      case 'PROCESSING':
        return statusProcessing;
      case 'COMPLETED':
        return statusCompleted;
      case 'FAILED':
        return statusFailed;
      default:
        return statusPending;
    }
  }
}
