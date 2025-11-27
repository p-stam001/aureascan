import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFDBB251);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color boderGray = Color(0xFFE5E7EB);
  static const Color gold = Color(0xFFDAB251);
  static const Color background = Color(0xFFFFFFFF);

  static const Gradient splashGradient = LinearGradient(
    colors: [
      Color(0xFFDAB251),
      Color(0xFFD1A94B),
      Color(0xFFC39A3E),
      Color(0xFFAE842F),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFFDBB251),
      Color(0xFFAB802A),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
} 