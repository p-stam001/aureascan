import 'package:aureascan_app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
        displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary, height: 1.2),
        headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.black),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
        headlineSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black, height: 1.5),
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: AppColors.textSecondary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary, height: 1.5),
        bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.textSecondary, height: 1.6),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white, height: 1.3),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white, height: 1.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    );
  }
} 