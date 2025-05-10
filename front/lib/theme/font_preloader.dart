import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Service responsible for preloading critical fonts to avoid text flickering
class FontPreloader {
  /// List of fonts used in the application that should be preloaded
  static const List<String> _fontsToPreload = [
    'Poppins', // Primary font
    'Montserrat', // Heading font
    'Roboto', // Button font
  ];

  /// List of font weights to preload for each font
  static const List<FontWeight> _weightsToPreload = [
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ];

  /// Preload all critical fonts to avoid text flickering during app startup
  static Future<void> preloadFonts() async {
    // Show debug message
    debugPrint('Preloading fonts...');

    // Load multiple font families with multiple weights
    final futures = <Future>[];

    for (final fontFamily in _fontsToPreload) {
      for (final weight in _weightsToPreload) {
        // Create a TextStyle with the font and weight
        final style = GoogleFonts.getFont(
          fontFamily,
          fontWeight: weight,
        );

        // Get the FontLoader and load it
        final loader = FontLoader(style.fontFamily!);
        final future = GoogleFonts.pendingFonts();
        futures.add(future);
      }
    }

    // Wait for all fonts to be loaded
    await Future.wait(futures);

    debugPrint('Fonts preloaded successfully');
  }
}
