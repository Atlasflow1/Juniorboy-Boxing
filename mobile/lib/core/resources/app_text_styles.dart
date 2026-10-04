import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './app_sizes.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle title = GoogleFonts.oswald(
    fontSize: AppSizes.font28,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );
  static TextStyle section = GoogleFonts.oswald(
    fontSize: AppSizes.font22,
    fontWeight: FontWeight.w600,
  );
  static TextStyle label = GoogleFonts.roboto(
    fontSize: AppSizes.font11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.red,
  );
}
