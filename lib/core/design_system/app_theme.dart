import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.onSurfaceLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.onSurfaceLight),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.onSurfaceLight),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.onSurfaceLight),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.onSurfaceLight),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.onSurfaceLight),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.onSurfaceLight),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceLight),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textGreyLight),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.onSurfaceLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textGreyLight),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textGreyLight.withOpacity(0.6)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.onSurfaceDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.onSurfaceDark),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.onSurfaceDark),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.onSurfaceDark),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.onSurfaceDark),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.onSurfaceDark),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.onSurfaceDark),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceDark),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textGreyDark),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.onSurfaceDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          borderSide: const BorderSide(color: AppColors.greyDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          borderSide: const BorderSide(color: AppColors.greyDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textGreyDark),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textGreyDark.withOpacity(0.6)),
      ),
    );
  }
}
