import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../resources/app_colors.dart';
import '../resources/app_sizes.dart';
import '../resources/app_text_styles.dart';

ThemeData buildTheme({Color background = AppColors.background}) {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.dark(
      primary: AppColors.red,
      surface: AppColors.card,
    ),
    textTheme: GoogleFonts.robotoTextTheme(base.textTheme).copyWith(
      headlineMedium: AppTextStyles.title,
      titleLarge: AppTextStyles.section,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: AppColors.white,
      surfaceTintColor: AppColors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        textStyle: const TextStyle(
          fontSize: AppSizes.font16,
          fontWeight: FontWeight.bold,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, AppSizes.outlinedButtonHeight),
        side: const BorderSide(color: AppColors.white),
        shape: const StadiumBorder(),
      ),
    ),
    dividerColor: AppColors.border,
  );
}
