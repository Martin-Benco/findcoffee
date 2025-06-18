import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.bold20,   // najväčší tučný nadpis
      headlineMedium: AppTextStyles.bold12,  // stredný tučný nadpis
      headlineSmall: AppTextStyles.bold8,    // najmenší tučný nadpis
      titleMedium: AppTextStyles.regular20,  // veľký regular text
      bodyMedium: AppTextStyles.regular12,   // bežný text
      labelSmall: AppTextStyles.regular8,    // malý text
    ),
    // ... ďalšie nastavenia podľa potreby
  );
} 