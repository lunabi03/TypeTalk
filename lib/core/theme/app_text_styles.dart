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

  // 호환성을 위한 별칭들
  static TextStyle get heading1 => h1;
  static TextStyle get heading2 => h2;
  static TextStyle get heading3 => h3;
  static TextStyle get body1 => body;
  static TextStyle get body2 => caption;
  
  // 추가 스타일 정의
  static TextStyle get titleMedium => GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.roboto(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.roboto(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodySmall => GoogleFonts.roboto(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.roboto(
    fontSize: 18,
    color: AppColors.textPrimary,
  );
}