import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Standardized text styles for the entire application
class AppTextStyles {
  // Heading styles with Montserrat
  static TextStyle get h1 => GoogleFonts.montserrat(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h2 => GoogleFonts.montserrat(
        fontSize: 26.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.montserrat(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h4 => GoogleFonts.montserrat(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h5 => GoogleFonts.montserrat(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // Body text styles with Poppins
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // Caption and supplementary text
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // Button text styles with Roboto
  static TextStyle get buttonLarge => GoogleFonts.roboto(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnPrimary,
        height: 1.2,
      );

  static TextStyle get buttonMedium => GoogleFonts.roboto(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnPrimary,
        height: 1.2,
      );

  static TextStyle get buttonSmall => GoogleFonts.roboto(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnPrimary,
        height: 1.2,
      );

  // Special text styles
  static TextStyle get price => GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get balanceText => GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.success,
        height: 1.2,
      );

  // Additional styles needed by the app
  static TextStyle get subtitle => GoogleFonts.poppins(
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get priceText => GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get code => GoogleFonts.sourceCodePro(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.4,
        letterSpacing: 0.5,
      );

  static TextStyle get codeText => GoogleFonts.sourceCodePro(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.4,
        letterSpacing: 0.5,
      );

  // Helper methods to modify text styles
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size.sp);
  }
}
