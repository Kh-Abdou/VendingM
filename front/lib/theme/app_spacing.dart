import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Standardized spacing values for consistent layout throughout the app
class AppSpacing {
  // Basic spacing values
  static double get xs => 4.r;
  static double get sm => 8.r;
  static double get md => 16.r;
  static double get lg => 24.r;
  static double get xl => 32.r;
  static double get xxl => 48.r;

  // Spacing for specific UI elements
  static double get cardPadding => 16.r;
  static double get listItemSpacing => 12.r;
  static double get sectionSpacing => 32.r;
  static double get inputFieldPadding => 16.r;

  // Border radius values
  static double get buttonRadius => 15.r;
  static double get cardRadius => 20.r;
  static double get dialogRadius => 12.r;
  static double get chipRadius => 8.r;
  static double get imageRadius => 16.r; // Added for image containers
  static double get codeRadius => 8.r; // Added for code blocks

  // Helper padding methods
  static EdgeInsets get paddingXS => EdgeInsets.all(xs);
  static EdgeInsets get paddingSM => EdgeInsets.all(sm);
  static EdgeInsets get paddingMD => EdgeInsets.all(md);
  static EdgeInsets get paddingLG => EdgeInsets.all(lg);

  // Horizontal padding values
  static EdgeInsets get paddingHorizontalSM =>
      EdgeInsets.symmetric(horizontal: sm);
  static EdgeInsets get paddingHorizontalMD =>
      EdgeInsets.symmetric(horizontal: md);
  static EdgeInsets get paddingHorizontalLG =>
      EdgeInsets.symmetric(horizontal: lg);

  // Vertical padding values
  static EdgeInsets get paddingVerticalSM => EdgeInsets.symmetric(vertical: sm);
  static EdgeInsets get paddingVerticalMD => EdgeInsets.symmetric(vertical: md);
  static EdgeInsets get paddingVerticalLG => EdgeInsets.symmetric(vertical: lg);

  // Screen padding for safe layout
  static EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: md,
        vertical: sm,
      );

  // Dialog content padding
  static EdgeInsets get dialogPadding => EdgeInsets.all(md);

  // Input field internal padding
  static EdgeInsets get inputPadding => EdgeInsets.symmetric(
        vertical: md,
        horizontal: md,
      );

  // Form field vertical spacing
  static double get formFieldSpacing => 16.h;

  // Button height
  static double get buttonHeight => 48.h;

  // App bar height
  static double get appBarHeight => 56.h;

  // Bottom navigation height
  static double get bottomNavHeight => 60.h;

  // Card elevation
  static double get cardElevation => 4;
}
