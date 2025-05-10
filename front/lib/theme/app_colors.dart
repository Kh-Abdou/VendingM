import 'package:flutter/material.dart';

/// App color palette defines all colors used throughout the application
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6B2FEB);
  static const Color primaryLight = Color(0xFF9E76F2);
  static const Color primaryDark = Color(0xFF512DA8);

  // Secondary colors
  static const Color secondary = Color(0xFF9C27B0);
  static const Color secondaryLight = Color(0xFFCE93D8);
  static const Color secondaryDark = Color(0xFF7B1FA2);

  // Neutral colors
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color background =
      Color(0xFFF8F9FA); // Added for background color
  static const Color backgroundDark =
      Color(0xFF121212); // Added for dark background
  static const Color onPrimary =
      Color(0xFFFFFFFF); // Added for text on primary color

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2D2D2D);
  static const Color surfaceVariant =
      Color(0xFFF0F0F0); // New surface variant color

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE0E0E0);

  // Card and elevated element colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D2D);
  static const Color shadowLight = Color(0x1A000000); // 10% opacity black
  static const Color shadowDark = Color(0x40000000); // 25% opacity black
}
