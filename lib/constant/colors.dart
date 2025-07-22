import 'package:flutter/material.dart';

class AppColors {
  // --- Brand & Primary Colors ---
  /// Main brand color: soft green (fresh, natural, food-related)
  static const Color primary = Color(0xFFACCF9F);

  /// Accent: soft yellow (egg yolk, grain, warmth)
  static const Color secondary = Color(0xFFF1F2F1);

  // --- Backgrounds & Surfaces ---
  static const Color background = Color(0xFFF8F8F6); // Off-white background
  static const Color card = Color(0xFFF2F3EF); // Light neutral card

  // --- Text Colors ---
  static const Color text = Color(0xFF2D3A2E); // Dark muted text
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(
    0xFF262626,
  ); // Baccarat Black (for true black)

  // --- Greys & Borders ---
  static const Color darkGrey = Color(0xFF525151);
  static const Color lightGrey = Color.fromARGB(
    255,
    116,
    114,
    114,
  ); // Use muted color for "light grey"
  static const Color border = Color(0xFFE0E3DD); // Subtle border

  // --- Status Colors ---
  static const Color error = Color(0xFFE6B8B7); // Muted error
  static const Color success = Color(0xFFB7D6B0); // Muted success
  static const Color muted = Color(0xFFBFC8BC); // Muted/disabled
}
