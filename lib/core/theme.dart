import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color darkBackground = Color(0xFF121212);
  static const Color surfaceGrey = Color(0xFF1E1E1E);
  static const Color accentGrey = Color(0xFF2C2C2C);

  static TextStyle get displayLarge => const TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: 'Roboto Mono',
  );

  static TextStyle get displayMedium => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get bodyLarge =>
      const TextStyle(fontSize: 18, color: Colors.white);

  static TextStyle get bodyMedium =>
      const TextStyle(fontSize: 16, color: Colors.grey);
}
