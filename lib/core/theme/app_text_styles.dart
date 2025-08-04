import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:typetalk/core/theme/app_colors.dart';

class AppTextStyles {
  static TextStyle h1 = GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle h2 = GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle h3 = GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.roboto(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle caption = GoogleFonts.roboto(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static TextStyle small = GoogleFonts.roboto(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static TextStyle button = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}