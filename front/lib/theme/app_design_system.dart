/// Main entry point for the app's design system and theme
///
/// This file exports all theme components and provides methods for preloading
/// fonts and initializing the theme system.
library app_design_system;

import 'package:flutter/material.dart';
import 'package:lessvsfull/theme/font_preloader.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';
export 'app_theme.dart';
export 'font_preloader.dart';

/// A unified theme for the application that provides access to all theme components
class AppDesignSystem {
  /// Initialize the design system
  ///
  /// This method should be called before the app starts to preload fonts and prepare the theme
  static Future<void> initialize() async {
    // Import font_preloader here to avoid circular dependency
    // when the file is exported above
    await FontPreloader.preloadFonts();
  }
}
